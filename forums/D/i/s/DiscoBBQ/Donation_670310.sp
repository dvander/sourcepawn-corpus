//Donations v1.1 by Pinkfairie:

//Include:
#include <sourcemod>

//Terminate:
#pragma semicolon 1

//Global:
static MaxClients;

//SQL:
static String:Error[64];
static Handle:Database = INVALID_HANDLE;

//Config:
static Handle:Config;
static String:ConfigPath[128];

//Loads:
static SwapTeam;
static ColouredChat;
static ReservedSlots;
static String:SwapCmd[255];
static String:WelcomeMsg[255];

//Client:
static bool:IsDonator[33];

//Toggle Team:
ToggleTeam(Client)
{

	//Declare:
	decl Team;
	
	//Initialize:
	Team = GetClientTeam(Client);

	//Red/Blue:
	if(Team == 2 || Team == 3)
	{

		//Toggle:
		if(Team == 2)
			ChangeClientTeam(Client, 3);
		else
			ChangeClientTeam(Client, 2);

	}
	else
	{

		//Print:
		PrintToChat(Client, "[SM] You must be on red or blue to swap teams");
	}
}

//Integer Loading:
LoadInteger(Handle:Vault, const String:Key[32], const String:SaveKey[255], DefaultValue)
{

	//Declare:
	decl Variable;

	//Jump:
	KvJumpToKey(Vault, Key, false);

	//Money:
	Variable = KvGetNum(Vault, SaveKey, DefaultValue);

	//Rewind:
	KvRewind(Vault);

	//Return:
	return Variable;
}

//String Loading:
LoadString(Handle:Vault, const String:Key[32], const String:SaveKey[255], const String:DefaultValue[255], String:Reference[255])
{

	//Jump:
	KvJumpToKey(Vault, Key, false);
	
	//Load:
	KvGetString(Vault, SaveKey, Reference, 255, DefaultValue);

	//Rewind:
	KvRewind(Vault);
}

//Configure:
Configure()
{

	//Integers:
	SwapTeam = LoadInteger(Config, "Donation", "Swap Team", 1);
	ColouredChat = LoadInteger(Config, "Donation", "Coloured Chat", 1);
	ReservedSlots = LoadInteger(Config, "Donation", "Reserved Slots", 2);

	//String:
	LoadString(Config, "Donation", "Swap Command", "/swapteam", SwapCmd);
	LoadString(Config, "Donation", "Welcome Message", "Thank you for donating, please enjoy your privileges", WelcomeMsg);
}

//Create Table:
CreateTable()
{

	//Declare:
	decl bool:Success;

	//Check:
	if(Database == INVALID_HANDLE)
	{

		//Print:
		PrintToServer("[SM] Could not connect to SQL");
	}
	else
	{

		//Send:
		Success = SQL_FastQuery(Database, "CREATE TABLE IF NOT EXISTS `mysql_donations` (`steamid` varchar(64) NOT NULL)");

		//Error:
		if(!Success)
		{

			//Retrieve:
			SQL_GetError(Database, Error, sizeof(Error));

			//Print:
			PrintToServer("[SM] Could not create table, Error: %s", Error);
		}
	}
}

//Connection:
public OnClientPostAdminCheck(Client)
{

	//Declare:
	decl Reserved;
	decl Handle:FindQuery;
	decl String:AuthId[64], String:SteamId[64];

	//Initialize:
	Reserved = ReservedSlots;
	GetClientAuthString(Client, SteamId, sizeof(SteamId)); 

	//Check:
	if(Database == INVALID_HANDLE)
	{

		//Print:
		PrintToServer("[SM] Could not connect to SQL");
	}
	else
	{

		//Initialize:
		FindQuery = SQL_Query(Database, "SELECT steamid FROM mysql_donations");

		//Check:
		if(FindQuery == INVALID_HANDLE)
		{

			//Print:
			PrintToServer("[SM] Could not query SQL, Error: %s", Error);
		}
		else
		{

			//Fetch:
			while(SQL_FetchRow(FindQuery))
			{

				//Fetch:
				SQL_FetchString(FindQuery, 0, AuthId, sizeof(AuthId));

				//Check:
				if(StrEqual(AuthId, SteamId, false))
				{

					//Send:
					IsDonator[Client] = true;

					//Print:
					PrintToChat(Client, "[SM] %s", WelcomeMsg);
				}
			}
		}
	}

	//Reservations:
	if(Reserved > 0)
	{

		//Declare:
		decl Clients, Limit;

		//Initialize:
		Limit = MaxClients - Reserved;
		Clients = GetClientCount(false);

		//Errors:
		if(Clients <= Limit || IsFakeClient(Client) || IsDonator[Client])
			return;

		//Otherwise, Kick:
		CreateTimer(0.1, OnTimedKick, Client);
	}

	//Close:
	CloseHandle(FindQuery);
}

//Kick:
public Action:OnTimedKick(Handle:Timer, any:Client)
{

	//Invalid:
	if(!Client || !IsClientInGame(Client))
		return Plugin_Handled;

	//Kick:
	KickClient(Client, "Kicked due to slot reservation");
	
	//Return:
	return Plugin_Handled;
}

//Add Donator:
public Action:CommandListDonators(Client, Arguments)
{

	//Declare:
	decl Handle:FindQuery;
	decl String:AuthId[64];

	//Check:
	if(Database == INVALID_HANDLE)
	{

		//Print:
		PrintToServer("[SM] Could not connect to SQL");
	}
	else
	{
	
		//Initialize:
		FindQuery = SQL_Query(Database, "SELECT steamid FROM mysql_donations");

		//Check:
		if(FindQuery == INVALID_HANDLE)
		{

			//Print:
			PrintToServer("[SM] Could not query SQL");
		}
		else
		{

			//Print:
			PrintToConsole(Client, "-Donators:");

			//Fetch:
			while(SQL_FetchRow(FindQuery))
			{

				//Fetch:
				SQL_FetchString(FindQuery, 0, AuthId, sizeof(AuthId));

				//Print:
				PrintToConsole(Client, "--%s", AuthId);
			}
		}
	}
}

//Add Donator:
public Action:CommandAddDonator(Client, Arguments)
{

	//Arguments:
	if(Arguments < 1)
	{

		//Print:
		PrintToConsole(Client, "[SM] Usage: sm_donator <Steam Id>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl String:AuthId[64];

	//Initialize:
	GetCmdArg(1, AuthId, sizeof(AuthId));

	//Format:
	if(StrContains(AuthId, "steam", false) == -1)
	{

		//Print:
		PrintToConsole(Client, "[SM] Usage: sm_donator <Steam Id>");

		//Return:
		return Plugin_Handled;
	}

	//Quotes:
	if(StrEqual(AuthId, "STEAM_0", false))
	{

		//Print:
		PrintToConsole(Client, "[SM] Usage: Please wrap quotation marks around the SteamID");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl bool:Success;
	decl String:Query[255];

	//Check:
	if(Database == INVALID_HANDLE)
	{

		//Print:
		PrintToConsole(Client, "[SM] Could not connect to SQL");

		//Return:
		return Plugin_Handled;
	}
	else
	{

		//Format:
		Format(Query, sizeof(Query),
 "REPLACE INTO mysql_donations (steamid) VALUES ('%s')", AuthId);

		//Run:
		Success = SQL_FastQuery(Database, Query);

		//Successfully Executed:
		if(Success)
		{

			//Print:
			PrintToConsole(Client, "[SM] Added %s into mysql_donations", AuthId);
		}
		else
		{
	
			//Error:
			SQL_GetError(Database, Error, sizeof(Error));

			//Print:
			PrintToConsole(Client, "[SM] Error: %s", Error);
		}
	}

	//Return:
	return Plugin_Handled;
}

//Add Donator:
public Action:CommandRemoveDonator(Client, Arguments)
{

	//Arguments:
	if(Arguments < 1)
	{

		//Print:
		PrintToConsole(Client, "[SM] Usage: sm_removedonator <Steam Id>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl String:AuthId[64];

	//Initialize:
	GetCmdArg(1, AuthId, sizeof(AuthId));

	//Format:
	if(StrContains(AuthId, "steam", false) == -1)
	{

		//Print:
		PrintToConsole(Client, "[SM] Usage: sm_removedonator <Steam Id>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl bool:Success;
	decl String:Query[255];

	//Check:
	if(Database == INVALID_HANDLE)
	{

		//Print:
		PrintToConsole(Client, "[SM] Could not connect to SQL");

		//Return:
		return Plugin_Handled;
	}
	else
	{

		//Format:
		Format(Query, sizeof(Query),
 "DELETE FROM mysql_donations WHERE steamid = '%s'", AuthId);

		//Run:
		Success = SQL_FastQuery(Database, Query);

		//Successfully Executed:
		if(Success)
		{

			//Print:
			PrintToConsole(Client, "[SM] Removed %s from mysql_donations", AuthId);
		}
		else
		{
	
			//Error:
			SQL_GetError(Database, Error, sizeof(Error));

			//Print:
			PrintToConsole(Client, "[SM] Error: %s", Error);
		}
	}

	//Return:
	return Plugin_Handled;
}

//Team Balance:
public Action:EventBalance(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Client;

	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "player"));

	//Stop:
	if(IsDonator[Client])
		return Plugin_Handled;

	//Continue:
	return Plugin_Continue;
}

//Handle Say:
public Action:HandleSay(Client, Args)
{

	//Verify:
	if(Client == 0 || !IsDonator[Client] || ColouredChat != 1)
		return Plugin_Continue;

	//Declare:
	decl MaxPlayers;
	decl String:Arg[255], String:ChatMsg[255], String:ClientName[32];

	//Initialize:
	MaxPlayers = GetMaxClients();
	GetClientName(Client, ClientName, sizeof(ClientName));
	GetCmdArgString(Arg, sizeof(Arg));

	//Clean:
	StripQuotes(Arg);
	TrimString(Arg);

	//Swap Team:
	if(SwapTeam == 1)
		if(StrContains(Arg, SwapCmd, false) == 0)
		{

			//Toggle:
			ToggleTeam(Client);

			//Return:
			return Plugin_Handled;
		}

	//Preconcieved Commands:
	if(Arg[0] == '/' || Arg[0] == '!')
		return Plugin_Continue;

	//Format:
	Format(ChatMsg, 255, "\x01\x05%s \x01:  \x04%s", ClientName, Arg);

	//Print:
	for(new X = 1; X <= MaxPlayers; X++)
		if(IsClientConnected(X))
			if(IsPlayerAlive(Client) == IsPlayerAlive(X))
				PrintToChat(X, ChatMsg);

	//Return:
	return Plugin_Handled;
}

//Handle Say:
public Action:HandleSayTeam(Client, Args)
{

	//Verify:
	if(Client == 0 || !IsDonator[Client] || ColouredChat != 1)
		return Plugin_Continue;

	//Declare:
	decl Team, MaxPlayers;
	decl String:Arg[255], String:ChatMsg[255], String:ClientName[32];

	//Initialize:
	MaxPlayers = GetMaxClients();
	Team = GetClientTeam(Client);
	GetClientName(Client, ClientName, sizeof(ClientName));
	GetCmdArgString(Arg, sizeof(Arg));

	//Clean:
	StripQuotes(Arg);
	TrimString(Arg);

	//Preconcieved Commands:
	if(Arg[0] == '/' || Arg[0] == '!')
		return Plugin_Continue;

	//Format:
	Format(ChatMsg, 255, "\x01(TEAM) \x05%s \x01:  \x04%s", ClientName, Arg);

	//Print:
	for(new X = 1; X <= MaxPlayers; X++)
		if(IsClientConnected(X))
			if(Team == GetClientTeam(X))
				PrintToChat(X, ChatMsg);

	//Return:
	return Plugin_Handled;
}

//Information:
public Plugin:myinfo = 
{

	//Initialize:
	name = "Donation",
	author = "Pinkfairie",
	description = "Multiple Donation commands",
	version = "1.0",
	url = "hiimjoemaley@hotmail.com"
};

//Map Start:
public OnMapStart()
{

	//Initialize:
	MaxClients = GetMaxClients();

	//SQL Handle:
	if(Database != INVALID_HANDLE)
		CloseHandle(Database);

	//Load:
	Database = SQL_Connect("default", true, Error, sizeof(Error));

	//Configure:
	Configure();

	//Create:
	CreateTable();
}

//Initialization:
public OnPluginStart()
{

	//Register:
	PrintToServer("[SM] Donation recognition v1.1 by Pinkfairie loaded Successfully!");

	//Events:
	HookEvent("teamplay_teambalanced_player", EventBalance, EventHookMode_Pre);

	//Commands:
	RegConsoleCmd("say", HandleSay);
	RegConsoleCmd("say_team", HandleSayTeam);

	//Admin Commands:
	RegAdminCmd("sm_donator", CommandAddDonator, ADMFLAG_CUSTOM6, "<Steam Id> - Grants donation status to the SteamID");
	RegAdminCmd("sm_removedonator", CommandRemoveDonator, ADMFLAG_CUSTOM6, "<Steam Id> - Removes donation status from SteamID");
	RegAdminCmd("sm_listdonators", CommandListDonators, ADMFLAG_CUSTOM1, "- Lists the SteamIDs of all the donators");

	//Build:
	BuildPath(Path_SM, ConfigPath, 128, "data/donation_config.txt");

	//Config:
	Config = CreateKeyValues("Config");
	if(!FileToKeyValues(Config, ConfigPath))
		PrintToServer("[SM] ERROR: Missing file or incorrectly formated, '%s'", ConfigPath);

	//Tracking:
	CreateConVar("donationsbase_version", "1.0", "Base Donations Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
