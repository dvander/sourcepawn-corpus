#pragma dynamic 131072 //reserve 128kb for the stack

#include <sourcemod>
#include <socket>
#include <adminmenu>
#include <csteamid>

new Handle:wishlistkv = INVALID_HANDLE;
new Handle:offerkv = INVALID_HANDLE;
new Handle:socket = INVALID_HANDLE;
new Handle:hFile = INVALID_HANDLE;
new Handle:offerFile = INVALID_HANDLE;
new globalclient;

new String:steamid64[18];

new bool:lockout;

public Plugin:myinfo = {
	name = "TF2TP Wishlist Viewer",
	author = "Luigi Thirty",
	description = "Allows users to view TF2TP wishlists.",
	version = "1.0.0",
	url = "http://tradingpost.dynamitealley.com"
};
 
public OnPluginStart() {
	lockout = false;

	PrintToServer("Wishlist plugin started...");
	//wishlistkv = CreateKeyValues("WishlistItems");

	RegConsoleCmd("sm_wishlistid", Command_Wishlistid, "steamid to get the wishlist of.");
	RegConsoleCmd("sm_wishmenu", Command_Wishmenu, "Draw a menu of all users."); //identical v
	RegConsoleCmd("sm_wishlist", Command_Wishmenu, "Draw a menu of all users."); //identical ^

}

public OnSocketConnected(Handle:socket, any:arg) {
	// socket is connected, send the http request
	PrintToServer("*** Connected to TF2TP.")
	decl String:requestStr[500];
	Format(requestStr, sizeof(requestStr), "GET /api/wishlistItems.php?profileIds=%s HTTP/1.1\r\nHost: tf2tp.com\r\nConnection: close\r\n\r\n", steamid64)
	PrintToServer("*** Sending request for wishlist.")
	SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	PrintToServer("*** Writing chunk...")
	new String:theContent[65535];
	new String:theNew[65535];
	new isHeader;

	isHeader = StrContains(receiveData, "WishlistItems", true);

	if(isHeader != -1){ //if the data does not contain WishlistItems, it is not a header
		strcopy(theContent, sizeof(theContent), receiveData);

		SplitString(theContent, "\"Wishlist", theNew, sizeof(theNew));
		ReplaceString(theContent, sizeof(theContent), theNew, "");
		WriteFileString(hFile, theContent, false);
	} else {
		WriteFileString(hFile, receiveData, false);
	}
}

public OnSocketDisconnected(Handle:socket, any:hFile) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here
	PrintToServer("Wishlist downloaded, closing connection...")
	CloseHandle(socket);
	CloseHandle(hFile);

	// convert it into a keyvalue handle
	FileToKeyValues(wishlistkv, "wishlist.vdf");
	if(wishlistkv != INVALID_HANDLE){
		new bool:wishlistValid = wishlistIsValid(wishlistkv, steamid64);
		if(wishlistValid){
			wishlistGetItems(wishlistkv, steamid64);
		}
	} else {
		LogError("wishlist.vdf is not a valid VDF! Aborting.")
		PrintHintText(globalclient, "Internal error has been logged.");
	}
	PrintToServer("Done!");
	CloseHandle(wishlistkv);
	lockout = false;
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(hFile);
	CloseHandle(socket);
}

public Action:Command_Wishlistid(client, args){

	new String:full[256];

	if(args < 1){
		PrintToConsole(client, "Usage: sm_wishlist <steamid>");
		return Plugin_Handled;
	}

	if(lockout == true){
		PrintHintText(client, "Another user is currently getting a wishlist. Please try again in a few seconds.")
		return Plugin_Handled;
	}

	GetCmdArgString(full, sizeof(full));

	DoWishlist(client, full);

	return Plugin_Handled

}

public DoWishlist(const client, String:steamid[]){

	lockout = true;
	globalclient = client;	
	wishlistkv = CreateKeyValues("WishlistItems");
	new String:arg[128];
	new intsteamid64;


	if(!SteamIDToCSteamID(steamid, steamid64, 256)){
		LogError("Failed to get 64-bit ID for %s", steamid64);
	}

	PrintToServer("Retrieving wishlist for %s (%s)", steamid, steamid64);

	// create a new tcp socket
        socket = SocketCreate(SOCKET_TCP, OnSocketError);
        // open a file handle for writing the result
        hFile = OpenFile("wishlist.vdf", "w+");
        // pass the file handle to the callbacks
        SocketSetArg(socket, hFile);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "tf2tp.com", 80);

}

public bool:wishlistIsValid(Handle:kv, String:steamid[]){
	new itemNumber = 0;
	new String:strItemNumber[10];
	if(!KvJumpToKey(kv, steamid64)){
		PrintToServer("No wishlist found for profile %s.", steamid);
		PrintHintText(globalclient, "No TF2TP wishlist found for profile %s.", steamid);
		return false; //couldn't find a matching user
	} else {
		IntToString(itemNumber, strItemNumber, sizeof(strItemNumber));
		if(KvJumpToKey(kv, strItemNumber))
		{
			return true;
		} else {
			LogError("No items found in wishlist for profile %s.", steamid);
			PrintHintText(globalclient, "No items found in TF2TP wishlist for profile %s.", steamid);
			return false;
		}
	}
}

public wishlistGetItems(Handle:kv, String:steamid[]){
	new String:outputString[512] = "Wants: "
	new String:itemname[128];
	new itemNumber = 0;
	new String:strItemNumber[10];
	new bool:moreItems = true;

	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Items on Wishlist");

	KvRewind(kv); //make sure we're at the top of the tree

	//if we're here, then the wishlist is valid
	if(!KvJumpToKey(kv, steamid)){
		LogError("No wishlist found for profile %s.", steamid);
	}
	while(moreItems == true){
		IntToString(itemNumber, strItemNumber, sizeof(strItemNumber));

		if(KvJumpToKey(kv, strItemNumber)){
			PrintToServer("Getting item #%s", strItemNumber);
			KvGetString(kv, "name", itemname, sizeof(itemname));
			PrintToServer("Item %s: %s", strItemNumber, itemname);
			DrawPanelItem(panel, itemname); //add it to our panel
			StrCat(outputString, 512, itemname);
			itemNumber = itemNumber + 1;
			KvGoBack(kv) //go back a level
			StrCat(outputString, 512, ", ");
		} else {
			PrintToServer("No more items!");
			moreItems = false;
		}
	}
	//PrintHintText(globalclient, "%s", outputString);
	SendPanelToClient(panel, globalclient, WishlistMenuHandler, 20);

	CloseHandle(panel);
}

public WishlistMenuHandler(Handle:menu, MenuAction:action, param1, param2){
	if (action == MenuAction_Select){
	//do nothing, these are fake items
	}

	if (action == MenuAction_Cancel){
	// do nothing
	}

}

public Action:Command_Wishmenu(client, args){
	new Handle:wishmenu = CreateMenu(MenuHandler_Wishmenu);

	SetMenuTitle(wishmenu, "Get TF2TP.com Wishlist of Player");
	AddTargetsToMenu(wishmenu, 0, true, false);

	DisplayMenu(wishmenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Wishmenu(Handle:wishmenu, MenuAction:action, param1, param2){
	PrintToChat(param1, "Please wait a few seconds for the wishlist to appear once the user is selected.");
	new String:clientid[32];
	if (action == MenuAction_End){
	//do nothing
	} else if (action == MenuAction_Cancel){
	//do nothing
	} else if (action == MenuAction_Select){
                decl String:info[32];
                new userid, target;

                GetMenuItem(wishmenu, param2, info, sizeof(info));
                userid = StringToInt(info);

                if ((target = GetClientOfUserId(userid)) == 0)
                {
                        PrintToChat(param1, "[SM] %t", "Player no longer available");
                }
                else
                {
                        new String:name[32];
                        GetClientName(target, name, sizeof(name));

			//do a thing
			GetClientAuthString(target, clientid, 32);
			Perform_Wishmenu(param1, clientid);
                }
	}
}

public Perform_Wishmenu(client, String:targetsteamid[]){
        if(lockout == true){
                PrintHintText(client, "Another user is currently getting a wishlist. Please try again in a few seconds.")
        } else {

		DoWishlist(client, targetsteamid);
	}
}

