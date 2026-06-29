#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS FCVAR_NOTIFY
#define DATA_FILENAME "witch_crown_database.txt"
#define PLUGIN_VERSION "1.0.0"

//plugin info
//#######################
public Plugin myinfo =
{
	name = "Witch crown statistic",
	author = "Die Teetasse",
	description = "Adding a statistic of witch crowns",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=123433"
};

//global definitions
//#######################
char datafilepath[PLATFORM_MAX_PATH];
ConVar hPluginOn;
bool bPluginOn = false, bHooked = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2 game.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

//pluginstart
//#######################
public void OnPluginStart()
{
	//cvars
	CreateConVar("l4d2_crownstat_version", PLUGIN_VERSION, "Witch crown statistic version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("l4d2_crownstat_on", "1", "Plugin on/off", CVAR_FLAGS);
	hPluginOn.AddChangeHook(ConVarPluginOnChanged);
	AutoExecConfig(true, "l4d2_crownstat");

	//create console commands
	RegConsoleCmd("sm_crowns_own", Command_Crowns_Own);
	RegConsoleCmd("sm_crowns_top", Command_Crowns_Top);
	//hook console commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("teamsay", Command_Say);

	//build path to database
	BuildPath(Path_SM, datafilepath, sizeof(datafilepath), "../../cfg/%s", DATA_FILENAME);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarPluginOnChanged(ConVar hVariable, const char[] strOldValue, const char[] strNewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bPluginOn = hPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		HookEvent("witch_killed", Event_Witch_Killed);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("witch_killed", Event_Witch_Killed);
	}
}

//witch killed event
//#######################
Action Event_Witch_Killed(Event event, const char[] name, bool dontBroadcast)
{
	//crown?
	if (event.GetBool("oneshot"))
	{
		//get clientid, name and auth
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(client > 0)
		{
			char clientname[MAX_NAME_LENGTH], clientauth[32];
			GetClientName(client, clientname, sizeof(clientname));
			GetClientAuthId(client, AuthId_Steam2, clientauth, sizeof(clientauth));	

			//create crowndata
			KeyValues Data = new KeyValues("crowndata"); 
			int count = 0, crowns = 0;

			//load data from file
			Data.ImportFromFile(datafilepath);
			//search data or create it
			Data.JumpToKey("data", true);

			//user in list?
			if(!Data.JumpToKey(clientauth))
			{
				//add to count 1 or create the count
				Data.GoBack();
				Data.JumpToKey("info", true);

				count = Data.GetNum("count", 0);
				count++;

				Data.SetNum("count", count);
				Data.GoBack();
					
				//add auth key
				Data.JumpToKey("data", true);
				Data.JumpToKey(clientauth, true);
			}

			//get crown number
			crowns = Data.GetNum("crowns", 0);
			crowns++;

			//set crowns and name
			Data.SetNum("crowns", crowns);	
			Data.SetString("name", clientname);

			//save it
			Data.Rewind();
			Data.ExportToFile(datafilepath);
			delete Data;

			//print a message
			PrintToChat(client, "You have crowned a total of  %d witches in this server", crowns);
		}
	}
	return Plugin_Continue;
}

//say commands for printing
//#######################
Action Command_Say(int client, int args)
{
	if (client > 0 && args > 0)
	{
		char text[15];
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
	}
	return Plugin_Continue;
}	

//console commands for printing
//#######################
Action Command_Crowns_Own(int client, int args)
{
	if(client > 0)
	{
		PrintCrownsToClient(client);
	}
	return Plugin_Handled;
}

Action Command_Crowns_Top(int client, int args)
{
	if(client > 0)
	{
		PrintTopCrownersToClient(client);
	}
	return Plugin_Handled;
}

//print functions
//#######################
void PrintCrownsToClient(int client)
{
	KeyValues Data = new KeyValues("crowndata"); 
	int crowns = 0;

	if (!FileToKeyValues(Data, datafilepath))
	{
		PrintToChat(client, "No crown data found.");
		return;
	}
	
	//get auth
	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

	//search auth
	Data.JumpToKey("data");
	Data.JumpToKey(auth);
	crowns = Data.GetNum("crowns", 0);
	delete Data;
	
	//print message
	if (crowns < 1) PrintToChat(client, "You have not yet crowned a witch in this server");
	else PrintToChat(client, "You have %d crown(s)", crowns);
}

void PrintTopCrownersToClient(int client)
{
	KeyValues Data = new KeyValues("crowndata"); 
	int count = 0;

	if (!Data.ImportFromFile(datafilepath))
	{
		PrintToChat(client, "[SM] No data found.");
		return;
	}
	
	Data.JumpToKey("info");
	
	//get count
	count = Data.GetNum("count", 0);
	char[][] names = new char[count][MAX_NAME_LENGTH];
	int[][] crowns = new int[count][2];
	int totalcrowns = 0; 

	Data.GoBack();
	Data.JumpToKey("data");
	Data.GotoFirstSubKey();
	
	//save name and crowns in 2 different arrays (association via i)
	for (int i = 0; i < count; i++)
	{
		Data.GetString("name", names[i], MAX_NAME_LENGTH, "Unnamed");
		crowns[i][0] = i;
		crowns[i][1] = Data.GetNum("crowns", 0);
		totalcrowns += crowns[i][1];
		Data.GotoNextKey();
	}

	//sort crowns
	SortCustom2D(crowns, count, Sort_Function);

	//create panel
	Panel TopCrownPanel = new Panel();
	TopCrownPanel.SetTitle("Top 5 Crowners:");
	TopCrownPanel.DrawText("_________________");

	char text[64];

	//add 5 best to panel
	if (count > 5) count = 5;
	for (int i = 0; i < count; i++)
	{
		Format(text, sizeof(text), "%s: %d", names[crowns[i][0]], crowns[i][1]);
		TopCrownPanel.DrawText(text);
	}

	//add total crowns
	TopCrownPanel.DrawText("_________________");
	Format(text, sizeof(text), "There have been a total of %d crowns in this server", totalcrowns);
	TopCrownPanel.DrawText(text);

	//send panel
	TopCrownPanel.Send(client, TopCrownPanelHandler, 8);

	TopCrownPanel.Close();
	delete Data;
}

int Sort_Function(int[] array1, int[] array2, const int[][] completearray, Handle hndl)
{
	//sort function for our crown array
	if (array1[1] > array2[1]) return -1;
	if (array1[1] == array2[1]) return 0;
	return 1;
}

int TopCrownPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}
