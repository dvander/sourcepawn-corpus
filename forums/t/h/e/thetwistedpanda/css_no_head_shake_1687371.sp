#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.1"

new Handle:g_hFriendly = INVALID_HANDLE;
new Handle:g_hEnemy = INVALID_HANDLE;

new bool:g_bLateLoad, bool:g_bFriendly, bool:g_bEnemy;
new g_iTeam[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "CSS No Head Shake",
	author = "Twisted|Panda",
	description = "Provides a method for disabling the shaking effect upon being shot in the head.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("css_no_head_shake_version", PLUGIN_VERSION, "CSS No Head Shake: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hFriendly = CreateConVar("css_no_head_shake_team", "1", "If enabled, a client's screen will not shake after being shot in the head by a teammate. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hFriendly, OnSettingsChange);
	g_hEnemy = CreateConVar("css_no_head_shake_enemy", "1", "If enabled, a client's screen will not shake after being shot in the head by an enemy. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnemy, OnSettingsChange);
	AutoExecConfig(true, "css_no_head_shake");

	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	
	g_bFriendly = GetConVarBool(g_hFriendly);
	g_bEnemy = GetConVarBool(g_hEnemy);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hFriendly)
		g_bFriendly = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hEnemy)
		g_bEnemy = StringToInt(newvalue) ? true : false;		
}

public OnConfigsExecuted()
{
	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iTeam[i] = GetClientTeam(i);
				SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
			}
		}

		g_bLateLoad = false;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public OnClientDisconnect(client)
{
	g_iTeam[client] = 0;
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(attacker > 0 && attacker <= MaxClients && victim > 0 && victim <= MaxClients)
	{
		if(g_iTeam[victim] == g_iTeam[attacker])
		{
			if(g_bFriendly)
			{
				SetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", NULL_VECTOR);
				SetEntPropVector(victim, Prop_Send, "m_vecPunchAngleVel", NULL_VECTOR);
			}
		}
		else
		{
			if(g_bEnemy)
			{
				SetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", NULL_VECTOR);
				SetEntPropVector(victim, Prop_Send, "m_vecPunchAngleVel", NULL_VECTOR);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client <= 0 || !IsClientInGame(client))
		return Plugin_Continue;
		
	g_iTeam[client] = GetEventInt(event, "team");
	return Plugin_Continue;
}
