/* C4forAll
* 
* 	DESCRIPTION
* 		This plugins will give all Terrorists a C4.  Any Terrorist can plant the C4.  If a Terrorist
* 		tries to drop the C4, it will be blocked.  If a Terrorist dies, the C4 will be destroyed.
* 
* 		Once a bomb is planted, all C4 will be stripped and destroyed so they cannot plant another
* 		C4.
* 
* 		Game acts as normal once bomb is planted - CTs win if bomb is defused.
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Release
* 
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define 	PLUGIN_VERSION 		"0.0.1.0"

new bool:g_bEnabled;
new bool:g_bVIPOnly;
new bool:g_bDebug;
new bool:g_bBombPlanted;

new bool:g_bPlayerIsVIP[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo = 
{
	name = "C4 For All Ts",
	author = "TnTSCS aka ClarkKent",
	description = "Gives all Ts a C4 to plant",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_c4forall_version", PLUGIN_VERSION, 
	"Version of 'C4 For All'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_c4forall_enabled", "1", 
	"Is plugin enabled?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	g_bEnabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_c4forall_vip", "0", 
	"Should plugins only give VIP players C4?  If so, you can override default admin flag of \"o\" with the command \"allow_c4forall\"\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0)), OnVIPChanged);
	g_bVIPOnly = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_c4forall_debug", "0", 
	"Print some debug information to sourcemod log file?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0)), OnDebugChanged);
	g_bDebug = GetConVarBool(hRandom);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	AutoExecConfig(true);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late && g_bEnabled)
	{
		if (g_bDebug)
		{
			LogMessage("Plugin was loaded late");
		}
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPostAdminCheck(i);
				OnClientConnected(i);
				
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					GivePlayerC4(i);
				}
			}
		}
	}
	
	return APLRes_Success;
}

public OnClientConnected(client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public OnClientPostAdminCheck(client)
{
	g_bPlayerIsVIP[client] = CheckCommandAccess(client, "allow_c4forall", ADMFLAG_CUSTOM1);
	
	if (g_bDebug)
	{
		LogMessage("%L %s VIP access", client, (g_bPlayerIsVIP[client] ? "has" : "does not have"));
	}
}

public Action:OnWeaponDrop(client, weapon)
{
	if (g_bBombPlanted)
	{
		return Plugin_Continue;
	}
	
	new String:g_sWeaponName[80];
	
	if (weapon > MaxClients && GetClientTeam(client) == CS_TEAM_T && GetEntityClassname(weapon, g_sWeaponName, sizeof(g_sWeaponName)))
	{
		if (StrEqual("weapon_c4", g_sWeaponName, false))
		{
			if (g_bDebug)
			{
				LogMessage("%L tried to drop their C4 - entity [%i]", client, weapon);
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bBombPlanted = true;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bDebug)
	{
		LogMessage("The bomb was planted by %L- stripping C4 from all alive Terrorists", client);
	}
	
	CreateTimer(0.3, Timer_StripC4, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new healthRemaining = GetEventInt(event, "health");
	
	if (GetClientTeam(client) == CS_TEAM_T && healthRemaining <= 0)
	{
		new c4ent = GetC4Entity(client);
		
		if (g_bDebug)
		{
			LogMessage("%L was killed, they %s", client, (c4ent == -1 ? "do not have C4" : "do have C4, removing it"));
		}
		
		if (c4ent != INVALID_ENT_REFERENCE)
		{
			RemovePlayerItem(client, c4ent);
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bBombPlanted = false;
	CreateTimer(0.5, Timer_GiveC4, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_GiveC4(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			GivePlayerC4(i);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_StripC4(Handle:timer)
{
	StripAllC4();
	
	return Plugin_Continue;
}

GivePlayerC4(client)
{
	if (!g_bVIPOnly || (g_bVIPOnly && g_bPlayerIsVIP[client]))
	{
		if (g_bDebug)
		{
			LogMessage("%L %s", client, (GetC4Entity(client) == -1 ? "does not have C4 - giving to player" : "already has C4"));
		}
		
		if (GetC4Entity(client) == INVALID_ENT_REFERENCE)
		{
			GivePlayerItem(client, "weapon_c4");
		}
	}
}

StripAllC4()
{
	new ent;
	
	if (g_bDebug)
	{
		LogMessage("Stripping C4 from all alive Terrorists");
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			ent = GetC4Entity(i);
			
			if (ent != INVALID_ENT_REFERENCE)
			{
				if (g_bDebug)
				{
					LogMessage("%L has C4 [%i] - stripping it from player.", i, ent);
				}
				
				RemovePlayerItem(i, ent);
			}
		}
	}
}

/**
 * Check if player has C4
 * 
 * @param	client	Client index
 * @return	Entity index of C4 or -1 if player does not have C4
 * 
 */
GetC4Entity(client)
{
	return GetPlayerWeaponSlot(client, CS_SLOT_C4);
}

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StrEqual(newVal, "1"))
	{
		HookEvent("bomb_planted", Event_BombPlanted);
		HookEvent("player_hurt", Event_PlayerHurt);
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
		
		if (g_bDebug)
		{
			LogMessage("c4forall plugin changed from disabled to enabled");
		}
	}
	else
	{
		UnhookEvent("bomb_planted", Event_BombPlanted);
		UnhookEvent("player_hurt", Event_PlayerHurt);
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
		
		if (g_bDebug)
		{
			LogMessage("c4forall plugin changed from enabled to disabled");
		}
	}
	
	g_bEnabled = GetConVarBool(cvar);
	
	if (g_bDebug)
	{
		LogMessage("sm_c4forall_enabled changed from %s", (g_bEnabled ? "false to true" : "true to false"));
	}
}

public OnVIPChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bVIPOnly = GetConVarBool(cvar);
	
	if (g_bDebug)
	{
		LogMessage("sm_c4forall_vip changed from %s", (g_bVIPOnly ? "false to true" : "true to false"));
	}
}

public OnDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bDebug = GetConVarBool(cvar);
	
	LogMessage("sm_c4forall_debug changed from %s", (g_bDebug ? "false to true" : "true to false"));
}