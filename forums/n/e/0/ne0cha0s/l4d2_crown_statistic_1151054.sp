#include <sourcemod>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define DATA_FILENAME "witch_crown_database.txt"
#define PLUGIN_VERSION "1.0.0"

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
new String:datafilepath[PLATFORM_MAX_PATH];

//pluginstart
//#######################
public OnPluginStart()
{
	// Requires that plugin will only work on Left 4 Dead or Left 4 Dead 2
    decl String:game_name[64];
    GetGameFolderName(game_name, sizeof(game_name));
    if (!StrEqual(game_name, "left4dead", false) 
      && !StrEqual(game_name, "left4dead2", false))
    {
        SetFailState("This plugin will only work on Left 4 Dead or Left 4 Dead 2.");
    }
	//cvars
	CreateConVar("l4d2_crownstat_version", PLUGIN_VERSION, "Witch crown statistic version", CVAR_FLAGS|FCVAR_DONTRECORD);
	
	//create console commands
	RegConsoleCmd("sm_crowns_own", Command_Crowns_Own);
	RegConsoleCmd("sm_crowns_top", Command_Crowns_Top);
	
	//hook console commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("teamsay", Command_Say);

	//hook event
	HookEvent("witch_killed", Event_Witch_Killed);
	
	//build path to database
	BuildPath(Path_SM, datafilepath, sizeof(datafilepath), "../../cfg/%s", DATA_FILENAME);
}	

//witch killed event
//#######################
public Action:Event_Witch_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	//crown?
	if (!GetEventBool(event, "oneshot")) return Plugin_Continue;
	
	//get clientid, name and auth
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
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
	PrintToChat(client, "You have crowned a total of  %d witches in this server", crowns);
	
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
		PrintToChat(client, "No crown data found.");
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
	if (crowns < 1) PrintToChat(client, "You have not yet crowned a witch in this server");
	else PrintToChat(client, "You have %d crown(s)", crowns);
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
	SetPanelTitle(TopCrownPanel, "Top 5 Crowners:");
	DrawPanelText(TopCrownPanel, "_________________");
	
	new String:text[64];
	
	//add 5 best to panel
	if (count > 5) count = 5;
	for (new i = 0; i < count; i++)
	{
		Format(text, sizeof(text), "%s: %d", names[crowns[i][0]], crowns[i][1]);
		DrawPanelText(TopCrownPanel, text);
	}
	
	//add total crowns
	DrawPanelText(TopCrownPanel, "_________________");
	Format(text, sizeof(text), "There have been a total of %d crowns in this server", totalcrowns);
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