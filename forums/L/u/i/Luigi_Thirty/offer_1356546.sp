#pragma dynamic 131072 //reserve 128kb for the stack

#include <sourcemod>
#include <socket>
#include <adminmenu>
#include <csteamid>

new Handle:offerskv = INVALID_HANDLE;
new Handle:socket = INVALID_HANDLE;
new Handle:hFile = INVALID_HANDLE;
new globalclient;

new String:steamid64[18];

new bool:lockout;

public Plugin:myinfo = {
	name = "TF2TP Offer Viewer",
	author = "Luigi Thirty",
	description = "Allows users to view TF2TP offers.",
	version = "1.0.0",
	url = "http://tradingpost.dynamitealley.com"
};
 
public OnPluginStart() {
	lockout = false;

	PrintToServer("Offers plugin started...");

	RegConsoleCmd("sm_offersid", Command_Offersid, "steamid to get the offers of.");
	RegConsoleCmd("sm_offers", Command_Offers, "Get the tf2tp offers of a user."); //identical v
	RegConsoleCmd("sm_offers", Command_Offers, "Get the tf2tp offers of a user."); //identical ^

}

public OnSocketConnected(Handle:socket, any:arg) {
	// socket is connected, send the http request
	PrintToServer("*** Connected to TF2TP.")
	decl String:requestStr[500];
	Format(requestStr, sizeof(requestStr), "GET /api/tradeItems.php?profileIds=%s HTTP/1.1\r\nHost: tf2tp.com\r\nConnection: close\r\n\r\n", steamid64)
	PrintToServer("*** Sending request for offers.")
	SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	PrintToServer("*** Writing chunk...")
	new String:theContent[65535];
	new String:theNew[65535];
	new isHeader;

	isHeader = StrContains(receiveData, "TradeItems", true);

	if(isHeader != -1){ //if the data does not contain TradeItems, it is not a header
		strcopy(theContent, sizeof(theContent), receiveData);

		SplitString(theContent, "\"Trade", theNew, sizeof(theNew));
		ReplaceString(theContent, sizeof(theContent), theNew, "");
		WriteFileString(hFile, theContent, false);
	} else {
		WriteFileString(hFile, receiveData, false);
	}
}

public OnSocketDisconnected(Handle:socket, any:hFile) {
	PrintToServer("Offers downloaded, closing connection...")
	CloseHandle(socket);
	CloseHandle(hFile);

	
	// convert it into a keyvalue handle
	FileToKeyValues(offerskv, "offers.vdf");
	if(offerskv != INVALID_HANDLE){
		new bool:offerlistValid = offerlistIsValid(offerskv, steamid64);
		if(offerlistValid){
			offerlistGetItems(offerskv, steamid64);
		}
	} else {
		LogError("offers.vdf is not a valid VDF! Aborting.")
		PrintHintText(globalclient, "Internal error has been logged.");
	}
	PrintToServer("Done!");
	CloseHandle(offerskv);
	lockout = false;
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(hFile);
	CloseHandle(socket);
}

public Action:Command_Offersid(client, args){

	new String:full[256];

	if(args < 1){
		PrintToConsole(client, "Usage: sm_offersid <steamid>");
		return Plugin_Handled;
	}

	if(lockout == true){
		PrintHintText(client, "Another user is currently getting an offer list. Please try again in a few seconds.")
		return Plugin_Handled;
	}

	GetCmdArgString(full, sizeof(full));

	DoOffers(client, full);

	return Plugin_Handled

}

public DoOffers(const client, String:steamid[]){

	lockout = true;
	globalclient = client;	
	offerskv = CreateKeyValues("TradeItems");
	new String:arg[128];
	new intsteamid64;


	if(!SteamIDToCSteamID(steamid, steamid64, 256)){
		LogError("Failed to get 64-bit ID for %s", steamid64);
	}

	PrintToServer("Retrieving offer list for %s (%s)", steamid, steamid64);

	// create a new tcp socket
        socket = SocketCreate(SOCKET_TCP, OnSocketError);
        // open a file handle for writing the result
        hFile = OpenFile("offers.vdf", "w+");
        // pass the file handle to the callbacks
        SocketSetArg(socket, hFile);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "tf2tp.com", 80);

}

public bool:offerlistIsValid(Handle:kv, String:steamid[]){
	new itemNumber = 0;
	new String:strItemNumber[10];
	if(!KvJumpToKey(kv, steamid64)){
		PrintToServer("No offers found for profile %s.", steamid);
		PrintHintText(globalclient, "No TF2TP offers found for profile %s.", steamid);
		return false; //couldn't find a matching user
	} else {
		IntToString(itemNumber, strItemNumber, sizeof(strItemNumber));
		if(KvJumpToKey(kv, strItemNumber))
		{
			return true;
		} else {
			LogError("No items found in offers for profile %s.", steamid);
			PrintHintText(globalclient, "No items found in TF2TP offers for profile %s.", steamid);
			return false;
		}
	}
}

public offerlistGetItems(Handle:kv, String:steamid[]){
	new String:outputString[512] = "Offering: "
	new String:itemname[128];
	new itemNumber = 0;
	new String:strItemNumber[10];
	new bool:moreItems = true;

	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Items Offered");

	KvRewind(kv); //make sure we're at the top of the tree

	//if we're here, then the offer list is valid
	if(!KvJumpToKey(kv, steamid)){
		LogError("No offerlist found for profile %s.", steamid);
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
	//PrintHintText(globalclient, "%s", outputString); //uncomment for debug information
	SendPanelToClient(panel, globalclient, OfferlistMenuHandler, 20);

	CloseHandle(panel);
}

public OfferlistMenuHandler(Handle:menu, MenuAction:action, param1, param2){
	if (action == MenuAction_Select){
	//do nothing, these are fake items
	}

	if (action == MenuAction_Cancel){
	// do nothing
	}

}

public Action:Command_Offers(client, args){
	new Handle:offermenu = CreateMenu(MenuHandler_Offermenu);

	SetMenuTitle(offermenu, "Get TF2TP.com Offers From Player");
	AddTargetsToMenu(offermenu, 0, true, false);

	DisplayMenu(offermenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Offermenu(Handle:Offermenu, MenuAction:action, param1, param2){
	PrintToChat(param1, "Please wait a few seconds for the offers to appear once the user is selected.");
	new String:clientid[32];
	if (action == MenuAction_End){
	//do nothing
	} else if (action == MenuAction_Cancel){
	//do nothing
	} else if (action == MenuAction_Select){
                decl String:info[32];
                new userid, target;

                GetMenuItem(Offermenu, param2, info, sizeof(info));
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
			Perform_Offermenu(param1, clientid);
                }
	}
}

public Perform_Offermenu(client, String:targetsteamid[]){
        if(lockout == true){
                PrintHintText(client, "Another user is currently getting offered items. Please try again in a few seconds.")
        } else {
		DoOffers(client, targetsteamid);
	}
}

