#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	 "1.02"

new Handle:sm_roundend_overlay_red 			 = INVALID_HANDLE;
new Handle:sm_roundend_overlay_blue 		 = INVALID_HANDLE;
new Handle:sm_roundend_overlay_version		 = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Round end overlay",
	author = "dataviruset",
	description = "Display an overlay decal on round_end",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Hook events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundWin);

	// Create convars
	sm_roundend_overlay_red = CreateConVar("sm_roundend_overlay_red", "overlays/red_win", "What overlay to display if RED team wins, relative to the materials-folder: path - path to overlay material without file extension (set downloading and precaching in addons/sourcemod/configs/overlay_downloads.ini)");
	sm_roundend_overlay_blue = CreateConVar("sm_roundend_overlay_blue", "overlays/blue_win", "What overlay to display if BLUE team wins, relative to the materials-folder: path - path to overlay material without file extension (set downloading and precaching in addons/sourcemod/configs/overlay_downloads.ini)");
	sm_roundend_overlay_version = CreateConVar("sm_roundend_overlay_version", PLUGIN_VERSION, "Round end overlay plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookConVarChange(sm_roundend_overlay_version, VersionChange);
}

public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public OnMapStart()
{
	decl String:file[256];
	BuildPath(Path_SM, file, 255, "configs/overlay_downloads.ini");
	new Handle:fileh = OpenFile(file, "r");
	if (fileh != INVALID_HANDLE)
	{
		decl String:buffer[256];
		decl String:buffer_full[PLATFORM_MAX_PATH];

		while(ReadFileLine(fileh, buffer, sizeof(buffer)))
		{
			TrimString(buffer);
			if ( (StrContains(buffer, "//") == -1) && (!StrEqual(buffer, "")) )
			{
				PrintToServer("Reading overlay_downloads line :: %s", buffer);
				Format(buffer_full, sizeof(buffer_full), "materials/%s", buffer);
				if (FileExists(buffer_full))
				{
					PrintToServer("Precaching %s", buffer);
					PrecacheDecal(buffer, true);
					AddFileToDownloadsTable(buffer_full);
					PrintToServer("Adding %s to downloads table", buffer_full);
				}
				else
				{
					PrintToServer("File does not exist! %s", buffer_full);
				}
			}
		}

	}

}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winner_team = GetEventInt(event, "team");
	decl String:overlaypath[PLATFORM_MAX_PATH];

	if (winner_team == 1)
	{
		GetConVarString(sm_roundend_overlay_red, overlaypath, sizeof(overlaypath));
		ShowOverlayToAll(overlaypath);
	}
	else if (winner_team == 2)
	{
		GetConVarString(sm_roundend_overlay_blue, overlaypath, sizeof(overlaypath));
		ShowOverlayToAll(overlaypath);
	}
}

ShowOverlayToClient(client, const String:overlaypath[])
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

ShowOverlayToAll(const String:overlaypath[])
{
	// x = client index.
	for (new x = 1; x <= MaxClients; x++)
	{
		// If client isn't in-game, then stop.
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			ShowOverlayToClient(x, overlaypath);
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ShowOverlayToAll("");
}