#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <sendproxy>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_NAME 	"Radar Config"
#define PLUGIN_VERSION 	"1.2.0"

#define UPDATE_URL	"http://godtony.mooo.com/radarconfig/radarconfig.txt"

new Handle:g_hRadarConfig = INVALID_HANDLE;

new bool:g_bFlashHooked, bool:g_bRadarHooked;
new g_iShowAll, g_iPlayerManager = -1;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Hide or Show all players on the radar",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1471473"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SendProxy_HookArrayProp");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_radarconfig_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hRadarConfig = CreateConVar("sm_radarconfig", "1", "Determines radar functionality. (0 = Default behaviour, 1 = Disable radar, 2 = Show all players, 3 = Hide enemies)", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hRadarConfig, OnRadarModeChange);
	
	// Updater.
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnMapStart()
{
	g_iPlayerManager = FindEntityByClassname(0, "cs_player_manager");
	
	OnRadarModeChange(g_hRadarConfig, "", "");
}

public OnMapEnd()
{
	if (g_bRadarHooked)
		Unhook_Radar();
	
	if (g_bFlashHooked)
		Unhook_Flash();
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && GetClientTeam(client) > 1)
	{
		Client_HideRadar(client);
	}
}

public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (client && GetClientTeam(client) > 1)
	{
		new Float:fDuration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
		CreateTimer(fDuration, Timer_FlashEnd, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_FlashEnd(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (client && GetClientTeam(client) > 1)
	{
		Client_HideRadar(client);
	}
		
	return Plugin_Stop;
}

public Action:Hook_PlayerManager(entity, const String:propname[], &iValue, element)
{
	if (!g_bRadarHooked)
		return Plugin_Continue;
	
	iValue = g_iShowAll;
	return Plugin_Changed;
}

public OnRadarModeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iRadarMode = GetConVarInt(convar);

	switch (iRadarMode)
	{
		case 0: // Default radar behaviour
		{
			if (g_bRadarHooked)
				Unhook_Radar();
			
			if (g_bFlashHooked)
				Unhook_Flash();
		}
		
		case 1: // Disable radar for all
		{
			if (g_bRadarHooked)
				Unhook_Radar();
			
			if (!g_bFlashHooked)
				Hook_Flash();
		}
		
		case 2, 3: // Show all players on radar || Hide enemies even if nearby
		{
			if (!g_bRadarHooked)
				Hook_Radar();
			
			if (g_bFlashHooked)
				Unhook_Flash();
			
			g_iShowAll = (iRadarMode == 2) ? 1 : 0;
		}
	}
}

Hook_Radar()
{
	g_bRadarHooked = true;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		SendProxy_HookArrayProp(g_iPlayerManager, "m_bPlayerSpotted", i, Prop_Int, Hook_PlayerManager);
	}
}

Unhook_Radar()
{
	g_bRadarHooked = false;
	
	// SendProxy_UnhookArrayProp does not exist yet!
}

Hook_Flash()
{
	g_bFlashHooked = true;
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			Client_HideRadar(i);
		}
	}
}

Unhook_Flash()
{
	g_bFlashHooked = false;
	
	UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			Client_ShowRadar(i);
		}
	}
}

Client_HideRadar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}

Client_ShowRadar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.5);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}
