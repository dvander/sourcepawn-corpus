#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <autoupdate>


#define PL_VERSION "1.0.4" 
#define MAX_PLAYERS 256

new Handle:cAswSkill;
new Handle:WelcomeTimers[MAX_PLAYERS+1];

//Info for the plugin
public Plugin:myinfo = 
{
	name = "Skill Change Alerter",
	author = "DaveC524",
	description = "Prints out new skill level when changed",
	version = PL_VERSION,
	url = "http://davec524.mooo.com"
}

//Initialization of handle and hooking
public OnPluginStart()
{
	cAswSkill = Handle:FindConVar("asw_skill");
	HookConVarChange(Handle:cAswSkill, ConVarChanged:SkillChanged);
}

//Needed to allow autoupdating
public OnAllPluginsLoaded() 
{
    if(LibraryExists("pluginautoupdate")) 
	{
        // only register myself if the autoupdater is loaded
        // AutoUpdate_AddPlugin(const String:url[], const String:file[], const String:version[])
        AutoUpdate_AddPlugin("davec524.mooo.com", "/misc/SOURCEMODplugins/getdifficulty/plugins.xml", PL_VERSION);
    }
}

//Needed to allow autoupdating
public OnPluginEnd() 
{
    if(LibraryExists("pluginautoupdate")) 
	{
        // I don't need updating anymore
        // AutoUpdate_RemovePlugin(Handle:plugin=INVALID_HANDLE) - don't specifiy plugin to remove calling plugin
        AutoUpdate_RemovePlugin();
    }
}

//Upon client put in the server, a timer is made that later uses WelcomePlayer()
public OnClientPutInServer(client)
{
	WelcomeTimers[client] = CreateTimer(15.0, WelcomePlayer, client);
}

//Closes timer if one exists upon client disconnect
public OnClientDisconnect(client)
{
	if (WelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(WelcomeTimers[client]);
		WelcomeTimers[client] = INVALID_HANDLE;
	}
}

//Prints the difficulty to a player, and closes the timer
public Action:WelcomePlayer(Handle:timer, any:client)
{
	PrintDifficulty(client);
	WelcomeTimers[client] = INVALID_HANDLE;
}

//Using the data grabbed from GetSkill(), a player is reminded to the current skill level
public PrintDifficulty(client)
{
	new skill = GetSkill();
	switch (skill)
	{
		case 1:
			PrintToChat(client, "The server is set to Easy.");
		case 2:
			PrintToChat(client, "The server is set to Normal.");
		case 3:
			PrintToChat(client, "This server is set to Hard.");
		case 4:
			PrintToChat(client, "This server is set to Insane.");
		default:
			PrintToServer("Something broke.");
	}
}

//This function closes all timers to prevent chat redundancy as well as calling PrintDiffAll()
public SkillChanged()
{
	//Kill all timers to prevent redundancy
	for(new i = 0; i <= MAX_PLAYERS ; i++)
	{
		if(WelcomeTimers[i] != INVALID_HANDLE)
		{
			KillTimer(WelcomeTimers[i]);
			WelcomeTimers[i] = INVALID_HANDLE;
		}
	}
	
	//Print difficulty change to all
	PrintDiffAll();
}

//Using the data grabbed from GetSkill(), every player is alerted to the new skill level
public PrintDiffAll()
{
	new skill = GetSkill();
	switch (skill)
	{
		case 1:
			PrintToChatAll("The server is now on Easy.");
		case 2:
			PrintToChatAll("The server is now on Normal.");
		case 3:
			PrintToChatAll("This server is now on Hard.");
		case 4:
			PrintToChatAll("This server is now on Insane.");
		default:
			PrintToServer("Something broke.");
	}
}
	
//Returns the current skill level as an integer; 1=Easy, 2=Normal, 3=Hard, 4=Insane
public GetSkill()
{
	new skill = GetConVarInt(Handle:cAswSkill);
	return skill;
}