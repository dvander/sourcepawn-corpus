/* This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/> */

#pragma dynamic 131072

#include <sourcemod>
#include <SteamWorks>

public Plugin myinfo = {
  name = "TF2 Workshop Map Collection Support",
  author = "Alexander Hill(Breadpudding)",
  description = "A simple plugin that implements tf_workshop_map_collection and tf_workshop_mapcycle_collection",
  version = "2018.12.19-1",
  url = "https://github.com/cbpudding/tf_workshop_map_collection"
}

public void OnPluginStart() { // A brave new world(My first time using SourcePawn)
  RegServerCmd("tf_workshop_map_collection", Map_Collection);
	RegServerCmd("tf_workshop_mapcycle_collection", Mapcycle_Collection);
}

public Handle Form_Collection_Request(int argc) {
	char[] apiurl = "https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/?format=vdf";
	char arg[128];
	char argv[256];
	Handle req;
	if(argc == 1) {
		GetCmdArgString(argv, sizeof(argv)); // Get the collection ID from the console
		GetCmdArg(1, arg, sizeof(arg));
		req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, apiurl); // Create the request
		SteamWorks_SetHTTPRequestGetOrPostParameter(req, "collectioncount", "1");
		SteamWorks_SetHTTPRequestGetOrPostParameter(req, "publishedfileids[0]", arg); // Why the [0]? Blame Valve.
	}
	return req;
}

public Action Map_Collection(int argc) {
	Handle req = Form_Collection_Request(argc); // Form the request for the collection
  SteamWorks_SetHTTPCallbacks(req, Handle_Sync_Response); // Sets the callback for when the request is complete
  SteamWorks_SendHTTPRequest(req); // Actually send the request and hope for the best
}

public Action Mapcycle_Collection(int argc) {
	Handle req = Form_Collection_Request(argc); // Form the request
	SteamWorks_SetHTTPCallbacks(req, Handle_Mapcycle_Response); // Set the callback
	SteamWorks_SendHTTPRequest(req); // Send the request
}

public void Handle_Sync_Response(Handle req, bool fail, bool success, EHTTPStatusCode code) {
  if(!fail && success && code == k_EHTTPStatusCode200OK) {
    SteamWorks_GetHTTPResponseBodyCallback(req, Load_Maps_From_Collection);
  } else {
    PrintToServer("Unable to get collection data: Error contacting Steam.");
  }
}

public void Handle_Mapcycle_Response(Handle req, bool fail, bool success, EHTTPStatusCode code) {
	if(!fail && success && code == k_EHTTPStatusCode200OK) {
		SteamWorks_GetHTTPResponseBodyCallback(req, Load_Mapcycle_From_Collection);
	} else {
		PrintToServer("Unable to get collection data: Error contacting Steam.");
	}
}

public void Load_Maps_From_Collection(const char[] data) {
  char value[16]; // For later use
	KeyValues vdf = new KeyValues("response"); // For interpreting the VDF data
	vdf.ImportFromString(data, "response"); // Load the data from the response body
	vdf.JumpToKey("collectiondetails"); // Navigate to the list of maps
	vdf.JumpToKey("0");
	vdf.JumpToKey("children");
	if(!vdf.GotoFirstSubKey()) {
		PrintToServer("An error occured when parsing the response from Steam.");
	} else {
		do { // Iterate through the collection
			vdf.GetString("filetype", value, sizeof(value)); // Make sure the item is a map
			if(StrEqual(value, "0")) {
				vdf.GetString("publishedfileid", value, sizeof(value)); // Add the map to the workshop sync
				ServerCommand("tf_workshop_map_sync %s", value);
			}
		} while(vdf.GotoNextKey());
	}
	delete vdf;
}

public void Load_Mapcycle_From_Collection(const char[] data) {
	File mapcycle; // The mapcycle to write to
	char value[16]; // For later use
	mapcycle = OpenFile("cfg/mapcycle_workshop.txt", "w"); // Create the file or overwrite it if it exists
	if(mapcycle == null) {
		PrintToServer("Unable to open mapcycle_workshop.txt");
	} else {
		KeyValues vdf = new KeyValues("response"); // For interpreting the VDF data
		vdf.ImportFromString(data, "response"); // Interpret the response
		vdf.JumpToKey("collectiondetails"); // Navigate to the list
		vdf.JumpToKey("0");
		vdf.JumpToKey("children");
		if(!vdf.GotoFirstSubKey()) {
			PrintToServer("An error occured when parsing the response from Steam.");
		} else {
			do { // Iterate through the collection
				vdf.GetString("filetype", value, sizeof(value)); // Is this a map?
				if(StrEqual(value, "0")) {
					vdf.GetString("publishedfileid", value, sizeof(value)); // Add to mapcycle_workshop.txt
					mapcycle.WriteLine("workshop/%s", value);
				}
			} while(vdf.GotoNextKey());
			mapcycle.Close();
			PrintToServer("The mapcycle has been saved as mapcycle_workshop.txt");
		}
	}
}
