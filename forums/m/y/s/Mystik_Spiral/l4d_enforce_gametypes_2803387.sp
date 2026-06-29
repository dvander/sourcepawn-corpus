/*
  
[COLOR=Silver].[/COLOR]
[B][COLOR=Red]Enforce Gametypes[/COLOR][/B] (l4d_enforce_gametypes) by [COLOR=Green][I][B]Mystik Spiral[/B][/I][/COLOR]


[B]Objective:[/B]  

[LIST]
[*]Prevent client using mm_dedicated_force_servers to override sv_gametypes on server.
[*]Reject client connection if mp_gamemode set by lobby reservation is not included in sv_gametypes.
[/LIST]  

[B]Description and options:[/B]  

My server has sv_gametypes set to "coop,realism,nightmaredifficulty", but I was seeing other active game modes, like "versus", "survival", and "scavenge".  I discovered that clients were setting mm_dedicated_force_servers to my server IP address and port, then connecting from lobby.  When a client sets mm_dedicated_force_servers (in the client console), it overrides the value for sv_gametypes in the server and allows connections for any mp_gamemode.  This simple plugin checks the value of mp_gamemode (set during lobby reservation) and compares it to the values in sv_gametypes... if there is no match the client connection is rejected.  

Please be aware this will block all mutations that are not listed in sv_gametypes, even if the base gamemode for the mutation is listed.  

This plugin does not have any configurable console variables, though it does read the values for the Valve console variables [URL="https://developer.valvesoftware.com/wiki/List_of_L4D2_Cvars"]sv_gametypes[/URL] and [URL="https://developer.valvesoftware.com/wiki/List_of_L4D2_Cvars"]mp_gamemode[/URL].  

Please ensure these two Valve console variables are explicitly set in the server.cfg file the way you want them:  

[URL="https://developer.valvesoftware.com/wiki/List_of_L4D2_Cvars"]sv_hibernate_when_empty[/URL]
[URL="https://developer.valvesoftware.com/wiki/List_of_L4D2_Cvars"]sb_all_bot_game[/URL]  


[B]Notes:[/B]  

This plugin does not kick clients, it starts before that and rejects connection to the server for non-matching gamemodes.  

[IMG]https://urg-l4d2.s3.amazonaws.com/rejected.jpg[/IMG]  

If sv_gametypes is not set in your server.cfg file, it should default to:
coop,realism,survival,versus,scavenge,dash,holdout,shootzones  

I do not plan to add any new features, but if you find any bugs, please let me know and I will do my best to correct them.  I have only tested this with L4D2, but I expect it should also work with L4D1.  It will probably work with any game that uses sv_gametypes and mp_gamemode.  


[B]Credits:[/B]  

Game modes on/off/tog code: Silvers
Reminder that mp_gamemode may be set in server.cfg: Mika Misori
Reminder that L4D1/2 map names are different: Ja-Forces  

Want to contribute code enhancements?
Create a pull request using this GitHub repository: [URL]https://github.com/Mystik-Spiral/l4d_enforce_gametypes[/URL]  

Plugin discussion: [URL]https://forums.alliedmods.net/showthread.php?t=329035[/URL]  


[B]Changelog:[/B]  

[CODE]
26-Jun-2023 v1.4
- Fixed compatibility issue with L4D1

19-Jun-2023 v1.3
- Fixed issue if mp_gamemode was defined in server.cfg

08-May-2023 v1.2
- Reject connections if changelevel is already in progress to reset the mp_gamemode.

02-May-2023 v1.1
- On reject, changelevel to set an allowed mp_gamemode (uses first entry in sv_gametypes).

25-Apr-2023 v1.0
- Initial release.
[/CODE]


[B]Installation:[/B]  

Place the l4d_enforce_gametypes.smx file in the SourceMod "plugins" directory.
[COLOR=Silver].[/COLOR]
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D & L4D2] Enforce Gametypes"
#define PLUGIN_AUTHOR                 "Mystik Spiral"
#define PLUGIN_DESCRIPTION            "Enforce sv_gametypes"
#define PLUGIN_VERSION                "1.4"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=342570"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Global Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bChgLvlFlg = false;
char g_sAllowedGameType[32];

/****************************************************************************************************/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2)
	{
		g_bL4D2 = true;
		return APLRes_Success;
	}
	if ( test == Engine_Left4Dead )
	{
		g_bL4D2 = false;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
	return APLRes_SilentFailure;
}

/****************************************************************************************************/

public void OnPluginStart()
{
	CreateConVar("EnforceGameTypes_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
}

/****************************************************************************************************/

public void OnMapStart()
{
	// Assign variables
	char sGameMode[32], sGameTypes[1024], sGameType[32][32];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	GetConVarString(FindConVar("sv_gametypes"), sGameTypes, sizeof(sGameTypes));
	ExplodeString(sGameTypes, ",", sGameType, sizeof sGameType, sizeof sGameType[]);
	g_sAllowedGameType = sGameType[0];
		
	// Loop through game type values from sv_gametypes
	for (int iNdex = 0; iNdex < 32; iNdex++)
	{
		TrimString(sGameType[iNdex]);
		// mp_gamemode matches one of the values in sv_gametypes, allow connection
		if (strcmp(sGameType[iNdex], sGameMode, false) == 0)
		{
			g_bChgLvlFlg = false;
			break;
		}
		// mp_gamemode does not match any value in sv_gametypes, reject connection
		if (strlen(sGameType[iNdex]) == 0)
		{
			// If changelevel flag not already set, then changelevel to reset mp_gamemode
			if (!g_bChgLvlFlg)
			{
				g_bChgLvlFlg = true;
				CreateTimer(1.0, ChangeLevel);
			}
		}
	}
}

/****************************************************************************************************/

public bool OnClientConnect(int client, char[] rejectmsg, int maxlength)
{
	// Ignore bot connections
	if (IsFakeClient(client))
	{
		return true;
	}
	// Reject connections if changelevel is already in progress to reset the mp_gamemode
	if (g_bChgLvlFlg)
	{
		// Before rejecting, temporarily turn off hibernation so changelevel completes
		// These ConVars should be reset to the desired values in server.cfg
		ServerCommand("sm_cvar sv_hibernate_when_empty 0; sm_cvar sb_all_bot_game 1");
		strcopy(rejectmsg, maxlength, "Server does not support this gamemode");
		return false;
	}
	return true;
}

/****************************************************************************************************/

public Action ChangeLevel(Handle timer)
{
	// Change to allowed game mode and map that supports all game modes
	ServerCommand("sm_cvar mp_gamemode %s", g_sAllowedGameType);
	if (g_bL4D2)
	{
		ServerCommand("changelevel c8m5_rooftop");
		return Plugin_Continue;
	}
	ServerCommand("changelevel l4d_hospital05_rooftop");
	return Plugin_Continue;
}

/****************************************************************************************************/
