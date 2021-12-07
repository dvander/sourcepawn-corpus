#define PLUGIN_AUTHOR "CaveJohnson__"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

//global variables
char g_sConfigDictionary[PLATFORM_MAX_PATH];
char g_sUsernames[MAXPLAYERS][256];

public Plugin myinfo = 
{
	name = "Name Checker",
	author = PLUGIN_AUTHOR,
	description = "Checks player's usernames when they join the server against a dictionary",
	version = PLUGIN_VERSION,
	url = "http://coldcommunity.com"
};

public void OnPluginStart()
{
	//get the directory
	char sDirectory[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sDirectory, PLATFORM_MAX_PATH, "data/NameChecker");
	if(!DirExists(sDirectory, false))
	{
		CreateDirectory(sDirectory, 511);
	}
	
	//get the path to the config file
	BuildPath(Path_SM, g_sConfigDictionary, PLATFORM_MAX_PATH, "data/NameChecker/dictionary.txt");
	
	if(!FileExists(g_sConfigDictionary, false))
	{
		File f = OpenFile(g_sConfigDictionary, "w", false);
		f.Close();
	}
	
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Post);
}

public void OnPluginEnd()
{
	//just some cleanup going on here
	UnhookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Post);
}

public void OnClientPostAdminCheck(int Client)
{
	//ignore this if they are admin
	if(CheckCommandAccess(Client, "sm_admin", ADMFLAG_GENERIC))
		return;
	
	int numInfractions = CheckUsername(Client);
	
	if(numInfractions == 0)
		LogMessage("[NameChecker] %N joined the game with zero detected profanities in their username.", Client);
	else
		LogMessage("[NameChecker] %N joined the game with %i detected profanities in their username.", Client, numInfractions);
}

public int CheckUsername(int Client)
{
	char username[256];
	if(!GetClientName(Client, username, sizeof(username)))
	{
		LogError("[NameChecker] Failed to get client username for some reason.");
		return 0;
	}
	
	File file = OpenFile(g_sConfigDictionary, "r", false, NULL_STRING);
	char word[64];
	int numInfractions = 0;
	while(file.ReadLine(word, sizeof(word)))
	{
		numInfractions += ReplaceString(username, sizeof(username), word, "***", false);
	}
	file.Close();
	
	if(numInfractions > 0)
		SetClientName(Client, username);
	
	//this will be used to check when a player changes their username via steam
	//when they die since changing your username in most cases kills you in game
	strcopy(g_sUsernames[Client], 256, username);
	
	return numInfractions;
}

public Action Event_OnPlayerDeath(Event hEvent, const char[] sName, bool bBroadcast)
{
	int Client = GetClientOfUserId(hEvent.GetInt("userid")); //Dead Guy
	
	//ignore this if they are admin
	if(CheckCommandAccess(Client, "sm_admin", ADMFLAG_GENERIC))
		return Plugin_Continue;
	
	//this is in case a player's username changes, since players usually die and respawn when they
	//change their username. Even if a username change doesn't kill them immediately, their name
	//will be corrected the next time they die.
	char username[256];
	GetClientName(Client, username, sizeof(username));
	if(!StrEqual(username, g_sUsernames[Client], false))
	{
		//user may have changed their name
		int numInfractions = CheckUsername(Client);
		if(numInfractions > 0)
			LogMessage("[NameChecker] %N changed their username to a name with %i infractions.", Client, numInfractions);
	}
	
	return Plugin_Continue;
}