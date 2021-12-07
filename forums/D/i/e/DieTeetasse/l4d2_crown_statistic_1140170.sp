#include <sourcemod>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define DATA_FILENAME "witch_crown_database.txt"
#define PLUGIN_VERSION "1.0.2"

/*
plugin history
#######################
v1.0.2:
- added l4d1 support
- added 2 admin commands to reset one client or all data
- added command decriptions 
- changed messages text
- added cvar for join notification

v1.0.1:
- added join notification
- added fail crown message

v1.0.0:
- initial
*/

//plugin info
//#######################
public Plugin:myinfo =
{
	name = "Witch crown statistic",
	author = "Die Teetasse",
	description = "Adding a statistic of witch crowns",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123433"
};

//global definitions
//#######################
new Handle:cvar_welcomemsg;
new String:datafilepath[PLATFORM_MAX_PATH];

//pluginstart
//#######################
public OnPluginStart()
{
	//L4D2 check
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead") == -1) SetFailState("Witch crown statistic will only work with Left 4 Dead 1 or 2!");

	//cvars
	CreateConVar("l4d2_crownstat_version", PLUGIN_VERSION, "Witch crown statistic version", CVAR_FLAGS|FCVAR_DONTRECORD);
	cvar_welcomemsg = CreateConVar("l4d2_crownstat_welcomemsg", "1", "Witch crown statistic - welcome message enable/disable", CVAR_FLAGS);
	
	//create console commands
	RegConsoleCmd("sm_crowns_own", Command_Crowns_Own, "Shows your own crown count.");
	RegConsoleCmd("sm_crowns_top", Command_Crowns_Top, "Shows the top 5 crowners.");
	RegAdminCmd("sm_crowns_reset_all", Command_Reset_All, ADMFLAG_BAN, "Only Admins: Reset the whole crown database.");
	RegAdminCmd("sm_crowns_reset_one", Command_Reset_One, ADMFLAG_BAN, "Only Admins: Reset the crowns of one client. Parameter: Steam_id");
	
	//hook console commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("teamsay", Command_Say);

	//hook event
	HookEvent("witch_killed", Event_Witch_Killed);
	
	//build path to database
	BuildPath(Path_SM, datafilepath, sizeof(datafilepath), "../../cfg/%s", DATA_FILENAME);
}	

//connect message timer
//#######################
public OnClientPutInServer(client)
{
	if (GetConVarBool(cvar_welcomemsg)) CreateTimer(10.0, PrintWitchMessage, client);
}

//print message
//#######################
public Action:PrintWitchMessage(Handle:timer, any:client)
{
	if (IsClientInGame(client)) PrintToChat(client, "[SM] You can type !crowned to see how many witches you already crowned on this server or !topcrowners to see the top 5!");
}

//witch killed event
//#######################
public Action:Event_Witch_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	//crown?
	if (!GetEventBool(event, "oneshot"))
	{
		//miss message
		PrintToChat(client, "[SM] You killed the witch, but did not crown her!");
		return Plugin_Continue;
	}
	
	//get name and auth	
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	new String:clientauth[32];
	GetClientAuthString(client, clientauth, sizeof(clientauth));	
	
	//create crowndata
	new Handle:Data = CreateKeyValues("crowndata"); 
	new count, crowns;
	
	//load data from file
	FileToKeyValues(Data, datafilepath);
		
	//search data or create it
	KvJumpToKey(Data, "data", true);
		
	//user in list?
	if(!KvJumpToKey(Data, clientauth))
	{
		//add to count 1 or create the count
		KvGoBack(Data);
		KvJumpToKey(Data, "info", true);
			
		count = KvGetNum(Data, "count", 0);
		count++;
			
		KvSetNum(Data, "count", count);
		KvGoBack(Data);
			
		//add auth key
		KvJumpToKey(Data, "data", true);
		KvJumpToKey(Data, clientauth, true);
	}
			
	//get crown number
	crowns = KvGetNum(Data, "crowns", 0);
	crowns++;
		
	//set crowns and name
	KvSetNum(Data, "crowns", crowns);	
	KvSetString(Data, "name", clientname);
		
	//save it
	KvRewind(Data);
	KeyValuesToFile(Data, datafilepath);
		
	CloseHandle(Data);
	
	//print a message
	PrintToChat(client, "[SM] You crowned a witch and got a total of %d witches on this server!", crowns);
	
	return Plugin_Continue;
}

//say commands for printing
//#######################
public Action:Command_Say(client, args)
{
	if (args < 1)
	{
		return Plugin_Continue;
	}
	
	decl String:text[15];
	GetCmdArg(1, text, sizeof(text));
	
	if (StrContains(text, "!crowned") == 0)
	{
		PrintCrownsToClient(client);
		return Plugin_Handled;
	}
	else if (StrContains(text, "!topcrowners") == 0)
	{
		PrintTopCrownersToClient(client);
		return Plugin_Handled;
	}	
	
	return Plugin_Continue;
}	

//console commands for printing
//#######################
public Action:Command_Crowns_Own(client, args)
{
	PrintCrownsToClient(client);
	return Plugin_Continue;
}

public Action:Command_Crowns_Top(client, args)
{
	PrintTopCrownersToClient(client);
	return Plugin_Continue;
}

//print functions
//#######################
PrintCrownsToClient(client)
{
	new Handle:Data = CreateKeyValues("crowndata"); 
	new crowns;
	
	if (!FileToKeyValues(Data, datafilepath))
	{
		PrintToChat(client, "[SM] No data found.");
		return;
	}
	
	//get auth
	new String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	//search auth
	KvJumpToKey(Data, "data");
	KvJumpToKey(Data, auth);
	crowns = KvGetNum(Data, "crowns", 0);
	
	CloseHandle(Data);
	
	//print message
	if (crowns < 1) PrintToChat(client, "[SM] You didn't crown a witch yet on this server!");
	else PrintToChat(client, "[SM] You crowned %d witches in this server!", crowns);
}

PrintTopCrownersToClient(client)
{
	new Handle:Data = CreateKeyValues("crowndata"); 
	new count;
	
	if (!FileToKeyValues(Data, datafilepath))
	{
		PrintToChat(client, "[SM] No data found.");
		return;
	}
	
	KvJumpToKey(Data, "info");
	
	//get count
	count = KvGetNum(Data, "count", 0);
	new String:names[count][MAX_NAME_LENGTH];
	new crowns[count][2];
	new totalcrowns = 0; 
	
	KvGoBack(Data);
	KvJumpToKey(Data, "data");
	KvGotoFirstSubKey(Data);
	
	//save name and crowns in 2 different arrays (association via i)
	for (new i = 0; i < count; i++)
	{
		KvGetString(Data, "name", names[i], MAX_NAME_LENGTH, "Unnamed");
		crowns[i][0] = i;
		crowns[i][1] = KvGetNum(Data, "crowns", 0);
		totalcrowns += crowns[i][1];
		KvGotoNextKey(Data);
	}
	
	//sort crowns
	SortCustom2D(crowns, count, Sort_Function);
	
	//create panel
	new Handle:TopCrownPanel = CreatePanel();
	SetPanelTitle(TopCrownPanel, "Top 5 Crowner:");
	DrawPanelText(TopCrownPanel, "#################");
	
	new String:text[64];
	
	//add 5 best to panel
	if (count > 5) count = 5;
	for (new i = 0; i < count; i++)
	{
		Format(text, sizeof(text), "%s: %d", names[crowns[i][0]], crowns[i][1]);
		DrawPanelText(TopCrownPanel, text);
	}
	
	//add total crowns
	DrawPanelText(TopCrownPanel, "#################");
	Format(text, sizeof(text), "There have been a total of %d crowns on this server!", totalcrowns);
	DrawPanelText(TopCrownPanel, text);
	
	//send panel
	SendPanelToClient(TopCrownPanel, client, TopCrownPanelHandler, 8);
	
	CloseHandle(TopCrownPanel);	
	CloseHandle(Data);
}

public Sort_Function(array1[], array2[], const completearray[][], Handle:hndl)
{
	//sort function for our crown array
	if (array1[1] > array2[1]) return -1;
	if (array1[1] == array2[1]) return 0;
	return 1;
}

public TopCrownPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	//nothing to do
}

//admin commands
//#######################
public Action:Command_Reset_All(client, args)
{
	new Handle:Data = CreateKeyValues("crowndata"); 
	
	if (!FileToKeyValues(Data, datafilepath))
	{
		PrintToChat(client, "[SM] No data found.");
		return;
	}
	
	KvJumpToKey(Data, "data");
	KvGotoFirstSubKey(Data);

	//set all crowns to 0
	do
	{
		KvSetNum(Data, "crowns", 0);
	}
	while(KvGotoNextKey(Data));
	
	//save it
	KvRewind(Data);
	KeyValuesToFile(Data, datafilepath);
		
	CloseHandle(Data);	
	
	//print a message
	PrintToChat(client, "[SM] The database got successfully reset!");
}

public Action:Command_Reset_One(client, args)
{
	//params?
	if (args < 1) return;

	//get param
	decl String:auth[32];
	GetCmdArg(1, auth, sizeof(auth));

	//db
	new Handle:Data = CreateKeyValues("crowndata"); 
	
	if (!FileToKeyValues(Data, datafilepath))
	{
		PrintToChat(client, "[SM] No data found.");
		return;
	}
	
	KvJumpToKey(Data, "data");
	
	if(!KvJumpToKey(Data, auth))
	{
		PrintToChat(client, "[SM] Client with steam_id '%s' not found.", auth);
		return;
	}
	
	//reset
	KvSetNum(Data, "crowns", 0);
	
	//save it
	KvRewind(Data);
	KeyValuesToFile(Data, datafilepath);
		
	CloseHandle(Data);	
	
	//print a message
	PrintToChat(client, "[SM] Client with steam_id '%s' reset!", auth);
}