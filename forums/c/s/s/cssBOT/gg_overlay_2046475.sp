/*	
GunGame Overlays - Displays overlay decals at end of a gungame.
=========================================================
Commands:
	sm_overlay	Admin command to test display the overlays.

Credits:
	dataviruset - Overlay Idea from his roundend-overlay-css.
	DJ Tsunami - AddFolderToDownloadsTable
	
Changelog:
	v1.0	First version.
	v1.1	Rewrote.  Add admin console cmd sm_overlay so we can test overlays.  Add individual team overlay functionality. 

Todo:
	Add options for overlays on round_start.
	Add options for overlays for winner and loser.
**/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <gungame>
//#include <morecolors>

#define PLUGIN_VERSION			"1.1"
#define PLUGIN_DESCRIPTION	"Displays overlay decals at end of a gungame."
//#define PLUGIN_PREFIX 			"{aqua}[UGz {ugzorange}GG Overlays{aqua}]"

new String:g_iOverlayT[PLATFORM_MAX_PATH];
new String:g_iOverlayCT[PLATFORM_MAX_PATH];
new String:g_iOverlaySpec[PLATFORM_MAX_PATH];
new String:g_iOverlayPath[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
    name = "GunGame Overlays",
    author = "BOT",
    description =  PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = "http://www.unifiedgamerz.net/"
};

public OnPluginStart()
{
//No need for hooking convar changes as overlays need to be precached on map start so we won't be switching during game.
	new Handle:hRandom;
	hRandom = CreateConVar("gg_overlay_folder", "materials/overlays/ug", "Folder of overlays to download");
	GetConVarString(hRandom, g_iOverlayPath, sizeof(g_iOverlayPath));
	
	hRandom = CreateConVar("gg_overlay_t", "overlays/ug/s2x", "What overlay to display for T's.");
	GetConVarString(hRandom, g_iOverlayT, sizeof(g_iOverlayT));
	
	hRandom = CreateConVar("gg_overlay_ct", "overlays/ug/s2x", "What overlay to display for CT's.");
	GetConVarString(hRandom, g_iOverlayCT, sizeof(g_iOverlayCT));
	
	hRandom = CreateConVar("gg_overlay_spec", "overlays/ug/s2x", "What overlay to display for spectators.");
	GetConVarString(hRandom, g_iOverlaySpec, sizeof(g_iOverlaySpec));
	
	CloseHandle(hRandom); 
	
 // Hook events
//    HookEvent("round_start", Event_RoundStart);

	RegAdminCmd("sm_overlay",		DisplayOverlay,	ADMFLAG_RESERVATION,	"Admin command to test display the overlays.");
	
	AutoExecConfig(true, "gg_overlay");
}

public Action: DisplayOverlay(client, args)
{
	DisplayOverlayToClient(client);
	return Plugin_Handled;
}

public OnMapStart()
{
	PrecacheDecal(g_iOverlayCT, true);
	PrecacheDecal(g_iOverlayT, true);
	AddFolderToDownloadsTable(g_iOverlayPath);
}

public GG_OnWinner(winner, const String:Weapon[], victim)
{
	for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && !IsFakeClient(client))				//API: IsClientInGame(client) True if player has entered the game, false otherwise. && NOT a BOT.
			{
				DisplayOverlayToClient(client);
			}
		}
}

DisplayOverlayToClient(client)
{
	new _Team = GetClientTeam(client);

	if (_Team == 0 || _Team == 1)	//No Team OR Spectator Team
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", g_iOverlaySpec);
	}
 	else if (_Team == 2) 				//T's
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", g_iOverlayT);
	}
	else if (_Team == 3)				//CT's
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", g_iOverlayCT);
	}
}

/*
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    DisplayOverlayToAll();
}
*/

/* AddFolderToDownloadsTable by DJ Tsunami - Sticky Nades 1.0
 * */
stock AddFolderToDownloadsTable(const String:sDirectory[])
{
	decl String:sFile[64], String:sPath[512];
	new FileType:iType, Handle:hDir = OpenDirectory(sDirectory);
	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iType))     
	{
		if(iType == FileType_File)
		{
			Format(sPath, sizeof(sPath), "%s/%s", sDirectory, sFile);
			AddFileToDownloadsTable(sPath);
		}
	}
}