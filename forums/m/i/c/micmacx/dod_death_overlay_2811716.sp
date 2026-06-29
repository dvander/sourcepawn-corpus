/*
// Fully inspired by FeurSturm dod_nostalgic_death
// and dataviruset for round end overlay donwloading and precache snippet
// Thanks to them !
// :)
// vintage
// V 1.0:
// original plugin (request by LeTaz)
// Overlay too long (stay from death to respawn)
// V 1.1:
// added auto cfg config for overlay model and a timer duration to display the overlay
// V 1.2:
// added overlay when player alive, like this you can put your team name or other, for me it's for make halloween theme, santa theme...
*/
// Includes
#include <sourcemod>
#include <sdktools>

// Constantes
#define PLUGIN_NAME    "DoD Death Overlay"
#define PLUGIN_VERSION	 "1.2"
#define DOD_MAXPLAYERS 33

new Handle:DeathOverlay = INVALID_HANDLE, 
Handle:Cvar_Overlay = INVALID_HANDLE, 
Handle:DeathOverlay_enable = INVALID_HANDLE, 
Handle:Cvar_Overlay_enable = INVALID_HANDLE, 
Handle:g_TimeDeathOverlay = INVALID_HANDLE, 
Handle:DeathOverlayTimer[DOD_MAXPLAYERS + 1] = INVALID_HANDLE;
//Infos
public Plugin:myinfo = 
{
	name = PLUGIN_NAME, 
	author = "vintage, Modif Micmacx", 
	description = "Display an overlay on death", 
	version = PLUGIN_VERSION, 
	url = "https://dodsplugins.mtxserv.fr/viewtopic.php?f=6&t=110"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_deathoverlay_version", PLUGIN_VERSION, "DoD Death Overlay Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	DeathOverlay = CreateConVar("sm_dod_deathoverlay", "decals/death_overlay/deathoverlay1", "death overlay to display, relative to materials folder without file extension (set download and precache in sourcemod/configs/dod_death_overlay_download.ini)", FCVAR_REPLICATED|FCVAR_NOTIFY)
	DeathOverlay_enable = CreateConVar("sm_dod_deathoverlay_enable", "1", "0 : disable, 1 : enable Death Overlay", FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_Overlay = CreateConVar("sm_dod_overlay", "decals/death_overlay/overlay1", "overlay to display, relative to materials folder without file extension (set download and precache in sourcemod/configs/dod_death_overlay_download.ini)", FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_Overlay_enable = CreateConVar("sm_dod_overlay_enable", "0", "0 : disable, 1 : enable Overlay", FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_TimeDeathOverlay = CreateConVar("sm_dod_deathoverlaytime", "2.0", "How many seconds to display deathoverlay", FCVAR_REPLICATED|FCVAR_NOTIFY, true, 1.0, true, 5.0)
	
	HookEventEx("player_death", OnPlayerDeath, EventHookMode_Post)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	
	AutoExecConfig(true, "dod_deathoverlay", "dod_deathoverlay")
}

public OnMapStart()
{
	decl String:file[256];
	BuildPath(Path_SM, file, 255, "configs/dod_death_overlay_download.ini");
	new Handle:fileh = OpenFile(file, "r");
	if (fileh != INVALID_HANDLE)
	{
		decl String:buffer[256];
		decl String:buffer_full[PLATFORM_MAX_PATH];
		
		while (ReadFileLine(fileh, buffer, sizeof(buffer)))
		{
			TrimString(buffer);
			if ((StrContains(buffer, "//") == -1) && (!StrEqual(buffer, "")))
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

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		ClientCommand(client, "r_screenoverlay 0")
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (IsValidClient(client))
	{
		if(GetConVarBool(Cvar_Overlay_enable))
		{
			decl String:overlaypath[PLATFORM_MAX_PATH]
			GetConVarString(Cvar_Overlay, overlaypath, sizeof(overlaypath))
			ShowDeathOverlayToClient(client, overlaypath)
		}
		else
		{
			ClientCommand(client, "r_screenoverlay 0")
		}
	}
	return Plugin_Continue
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:deathoverlaypath[PLATFORM_MAX_PATH]
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (IsValidClient(client))
	{
		if(GetConVarBool(DeathOverlay_enable))
		{
			GetConVarString(DeathOverlay, deathoverlaypath, sizeof(deathoverlaypath))
			ShowDeathOverlayToClient(client, deathoverlaypath)
			GetConVarInt(g_TimeDeathOverlay)
			DeathOverlayTimer[client] = CreateTimer(GetConVarFloat(g_TimeDeathOverlay), DontShowOverlayToClient, client, TIMER_FLAG_NO_MAPCHANGE)
		}
		return Plugin_Continue
	}
	else
	{
		return Plugin_Stop
	}
//	return Plugin_Continue
}


public Action:ShowDeathOverlayToClient(client, const String:overlaypath[])
{
	if (IsValidClient(client))
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath)
		return Plugin_Continue
	}
	else
	{
		return Plugin_Stop
	}
//	return Plugin_Continue
}

public Action:DontShowOverlayToClient(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		if(GetConVarBool(Cvar_Overlay_enable))
		{
			decl String:overlaypath[PLATFORM_MAX_PATH]
			GetConVarString(Cvar_Overlay, overlaypath, sizeof(overlaypath))
			ShowDeathOverlayToClient(client, overlaypath)
		}
		else
		{
			ClientCommand(client, "r_screenoverlay 0")
		}
		DeathOverlayTimer[client] = INVALID_HANDLE
		return Plugin_Continue
	}
	else
	{
		DeathOverlayTimer[client] = INVALID_HANDLE
		return Plugin_Stop
	}
//	return Plugin_Continue
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		return true;
	}else{
		return false;
	}
}
