#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	 "1.00"

new Handle:sm_death_overlay 			 = INVALID_HANDLE;
new Handle:sm_death_overlay_time		 = INVALID_HANDLE;
new Handle:sm_death_overlay_version		 = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Death overlay",
	author = "dataviruset",
	description = "Display an overlay decal to a player when he dies",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Hook events
	HookEvent("player_death", Event_PlayerDeath);

	// Create convars
	sm_death_overlay = CreateConVar("sm_death_overlay", "overlays/death_overlay", "What overlay to display to a player when he dies, relative to the materials-folder: path - path to overlay material without file extension (set downloading and precaching in addons/sourcemod/configs/overlay_downloads.ini)");
	sm_death_overlay_time = CreateConVar("sm_death_overlay_time", "3.0", "How long the death overlay will be displayed to a player: float value - time in seconds", _, true, 0.5);
	sm_death_overlay_version = CreateConVar("sm_death_overlay_version", PLUGIN_VERSION, "Death overlay plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookConVarChange(sm_death_overlay_version, VersionChange);
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

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	decl String:overlaypath[PLATFORM_MAX_PATH];

	GetConVarString(sm_death_overlay, overlaypath, sizeof(overlaypath));
	ShowOverlayToClient(client, overlaypath);
	CreateTimer(GetConVarFloat(sm_death_overlay_time), Timer_RemoveOverlay, client);
}

ShowOverlayToClient(client, const String:overlaypath[])
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

public Action:Timer_RemoveOverlay(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
		ShowOverlayToClient(client, "");

	return Plugin_Stop;
}