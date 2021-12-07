#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_PREFIX 	"\x01[\x04WitchCrownStats\x01]"

#define DATA_FILENAME	 "witch_crown_database.txt"

#define DELAY_SHOW_MESSAGE 	20.0

#define PLUGIN_VERSION 	"1.4"

new Handle:c_iWelcomeMsg;
new String:datafilepath[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name			 = "Witch Crown Stats",
	author			 = "Die Teetasse, rewritten by Cookie!",
	description		 = "Stats about witch crowns on the server.",
	version 		 = PLUGIN_VERSION,
	url 			 = "http://forums.alliedmods.net/showthread.php?t=123433"
}

public OnPluginStart(){
	c_iWelcomeMsg = CreateConVar("crownstats_welcomemsg", "1", "Shows the info message when player connects.");
	
	RegConsoleCmd("sm_crowned", Command_Crowns_Own, "Shows your own crown stats.");
	RegConsoleCmd("sm_topcrowners", Command_Crowns_Top, "Shows top crowners on the servers.");
	RegAdminCmd("sm_crowns_reset_all", Command_Reset_All, ADMFLAG_ROOT, "Only Root: Resets the whole crown database.");
	RegAdminCmd("sm_crowns_reset_one", Command_Reset_One, ADMFLAG_ROOT, "Only Root: Resets crown stats of one player. Parameter: Steam_id");
	
	HookEvent("witch_killed", Event_Witch_Killed);
	
	BuildPath(Path_SM, datafilepath, sizeof(datafilepath), "../../cfg/%s", DATA_FILENAME);
}	

public OnClientPostAdminCheck(client){
	if(GetConVarInt(c_iWelcomeMsg))
		CreateTimer(DELAY_SHOW_MESSAGE, PrintWitchMessage, GetClientUserId(client));
}

public Action:PrintWitchMessage(Handle:timer, any:userid){
	new client = GetClientOfUserId(userid);
	
	if(client && IsClientConnected(client) && IsClientInGame(client)) 
		PrintToChat(client, "%s Type \x05!crowned \x01to see how many witches you already crowned or \x05!topcrowners \x01to see the top crowners!", PLUGIN_PREFIX);
}

public Action:Event_Witch_Killed(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && !IsFakeClient(client) && IsClientConnected(client) && IsClientInGame(client)){
		if(!GetEventBool(event, "oneshot")){
			PrintToChat(client, "%s You killed the witch, but didn't \x05crown \x01her!", PLUGIN_PREFIX);
			return Plugin_Continue;
		}
		
		new String:clientname[MAX_NAME_LENGTH];
		GetClientName(client, clientname, sizeof(clientname));
		new String:clientauth[32];
		GetClientAuthId(client, AuthId_Steam2, clientauth, sizeof(clientauth));	
		
		new Handle:Data = CreateKeyValues("crowndata"); 
		new count, crowns;
		
		FileToKeyValues(Data, datafilepath);
			
		KvJumpToKey(Data, "data", true);
			
		if(!KvJumpToKey(Data, clientauth))
		{
			KvGoBack(Data);
			KvJumpToKey(Data, "info", true);
				
			count = KvGetNum(Data, "count", 0);
			count++;
				
			KvSetNum(Data, "count", count);
			KvGoBack(Data);
				
			KvJumpToKey(Data, "data", true);
			KvJumpToKey(Data, clientauth, true);
		}
				
		crowns = KvGetNum(Data, "crowns", 0);
		crowns++;
			
		KvSetNum(Data, "crowns", crowns);	
		KvSetString(Data, "name", clientname);
			
		KvRewind(Data);
		KeyValuesToFile(Data, datafilepath);
			
		CloseHandle(Data);
		
		if(client && !IsFakeClient(client) && IsClientConnected(client) && IsClientInGame(client)){
			PrintToChat(client, "%s You \x05crowned \x01a witch, total witches crowned: \x03%d\x01.", PLUGIN_PREFIX, crowns);
		}
		Command_Crowns_Top(client, 1);
	}
	
	return Plugin_Continue;
}

public Action:Command_Crowns_Own(client, args){
	new Handle:Data = CreateKeyValues("crowndata"); 
	new crowns;
	
	if(!FileToKeyValues(Data, datafilepath)){
		PrintToChat(client, "%s No data found.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	new String:auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	
	KvJumpToKey(Data, "data");
	KvJumpToKey(Data, auth);
	crowns = KvGetNum(Data, "crowns", 0);
	
	CloseHandle(Data);
	
	if(crowns < 1) 
		PrintToChat(client, "%s You haven't crowned a witch yet!", PLUGIN_PREFIX);
	else 
		PrintToChat(client, "%s You crowned \x05%d \x01witches!", PLUGIN_PREFIX, crowns);

	return Plugin_Handled;
}

public Action:Command_Crowns_Top(client, args){
	new Handle:Data = CreateKeyValues("crowndata"); 
	new count;
	
	if(!FileToKeyValues(Data, datafilepath)){
		PrintToChat(client, "%s No data found.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	KvJumpToKey(Data, "info");
	
	count = KvGetNum(Data, "count", 0);
	
	if(count == 0){
		PrintToChat(client, "%s No witches crowned on the server yet.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	else{
		new String:names[count][MAX_NAME_LENGTH];
		new crowns[count];
		new totalcrowns = 0; 
		
		KvGoBack(Data);
		KvJumpToKey(Data, "data");
		KvGotoFirstSubKey(Data);
		
		for(new i = 0; i < count; i++){
			KvGetString(Data, "name", names[i], MAX_NAME_LENGTH, "Unnamed");
			if(StrContains(names[i], "witch tank", false) == -1){
				crowns[i] = KvGetNum(Data, "crowns", 0);
				totalcrowns += crowns[i];
			}
			else{
				crowns[i] = 0;
			}
			KvGotoNextKey(Data);
		}
		CloseHandle(Data);
		
		new String:SwapNames[MAX_NAME_LENGTH];
		new SwapData;
		for(new i = 0; i < (count - 1); i++){
			for(new j = 0; j < (count - i - 1); j++){
				if(crowns[j] < crowns[j+1]) {
					strcopy(SwapNames, MAX_NAME_LENGTH, names[j]);
					SwapData = crowns[j];
					
					strcopy(names[j], MAX_NAME_LENGTH, names[j+1]);
					crowns[j] = crowns[j+1];
					
					strcopy(names[j+1], MAX_NAME_LENGTH, SwapNames);
					crowns[j+1] = SwapData;
				}
			}
		}
		
		new Handle:TopCrownPanel = CreatePanel();
		SetPanelTitle(TopCrownPanel, "	 Top Crowners on the server");
		DrawPanelText(TopCrownPanel, "-==-==-==-==-==- -==- -==- -==-==-==-==-==-");
		
		new String:text[64];
		
		if(count > 5) 
			count = 5;
		for(new i = 0; i < count; i++){
			if(crowns[i] > 1)
				Format(text, sizeof(text), "%d. %s crowned %d witches.", i+1, names[i], crowns[i]);
			else
				Format(text, sizeof(text), "%d. %s crowned 1 witch.", i+1, names[i]);
			
			DrawPanelText(TopCrownPanel, text);
		}

		DrawPanelText(TopCrownPanel, "-==-==-==-==-==- -==- -==- -==-==-==-==-==-");
		Format(text, sizeof(text), "Total number of crowned witches: %d.", totalcrowns);
		DrawPanelText(TopCrownPanel, text);
	
		SendPanelToClient(TopCrownPanel, client, TopCrownPanelHandler, 15);
		
		CloseHandle(TopCrownPanel);	
	}
	
	return Plugin_Handled;
}

public TopCrownPanelHandler(Handle:menu, MenuAction:action, param1, param2){
	decl String:g_sTemp[256];
	
	if(action == MenuAction_Cancel){
		if(param1 && IsClientConnected(param1) && IsClientInGame(param1)){
			Format(g_sTemp, sizeof(g_sTemp), "%s Type \x05!topcrowners \x01to see the top list again.", PLUGIN_PREFIX);
			PrintToChat(param1, g_sTemp); 
		}
	}
}

public Action:Command_Reset_All(client, args){
	new Handle:Data = CreateKeyValues("crowndata"); 
	
	if(!FileToKeyValues(Data, datafilepath)){
		PrintToChat(client, "%s No data found.", PLUGIN_PREFIX);
		return;
	}
	
	KvJumpToKey(Data, "data");
	KvGotoFirstSubKey(Data);

	do{
		KvSetNum(Data, "crowns", 0);
	}
	while(KvGotoNextKey(Data));
	
	KvRewind(Data);
	KeyValuesToFile(Data, datafilepath);
		
	CloseHandle(Data);	
	
	PrintToChat(client, "%s The database was successfully reseted!", PLUGIN_PREFIX);
}

public Action:Command_Reset_One(client, args){
	if(args < 1) 
		return;

	decl String:auth[32];
	GetCmdArg(1, auth, sizeof(auth));

	new Handle:Data = CreateKeyValues("crowndata"); 
	
	if(!FileToKeyValues(Data, datafilepath)){
		PrintToChat(client, "%s No data found.", PLUGIN_PREFIX);
		return;
	}
	
	KvJumpToKey(Data, "data");
	
	if(!KvJumpToKey(Data, auth)){
		PrintToChat(client, "%s SteamID '\x05%s\x01' was not found in the databse.", PLUGIN_PREFIX, auth);
		return;
	}
	
	KvSetNum(Data, "crowns", 0);
	
	KvRewind(Data);
	KeyValuesToFile(Data, datafilepath);
		
	CloseHandle(Data);	
	
	PrintToChat(client, "%s Reseted crown stats for SteamID '\x05%s\x01'!", PLUGIN_PREFIX, auth);
}