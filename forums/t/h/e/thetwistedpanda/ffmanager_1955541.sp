/*
	- Replaced OnTakeDamage with TraceAttack to allow the plugin to properly function.
	- Fixed a minor bug with client array not being reset on disconnect.
	- Replaced command sm_toggleff with command sm_dealff
	- Added command sm_takeff, which allows client to be toggled for taking friendly fire damage.
	- Added late loading support.
	- Added version cvar sm_friendlyfire_version for tracking.
	- Added Logging/ShowActivity2 phrases (translations? bah!)
*/

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION		"0.1.3"
//Plugin ConVars
new Handle:g_hFriendlyFire;
new Handle:g_hFriendlyFireForAll;

new bool:g_bGettingShot[MAXPLAYERS + 1];
new bool:g_bDoingShooting[MAXPLAYERS + 1];

new bool:g_bLateLoad;
new bool:g_bOrigFriendlyFire;
new bool:g_bFriendlyFire;
new bool:g_bFriendlyFireForAll;

public Plugin:myinfo = 
{
	name = "[SM] FriendlyFire Manager",
	author = "Afronanny, Panda",
	description = "Allows management of Friendly Fire status for admins.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmodders.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_friendlyfire_version", PLUGIN_VERSION, "[SM] FriendlyFire Manager: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hFriendlyFire = FindConVar("mp_friendlyfire");
	if(g_hFriendlyFire == INVALID_HANDLE)
		SetFailState("Derp. Required cvar mp_friendlyfire doesn't exist.");
	HookConVarChange(g_hFriendlyFire, OnSettingsChanged);
		
	g_hFriendlyFireForAll = CreateConVar("sm_friendlyfire_enabledforall", "0", "Enables Friendly Fire for all players, effectively disabling this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hFriendlyFireForAll, OnSettingsChanged);	
	
	RegAdminCmd("sm_dealff", Command_ToggleDealFriendlyFire, ADMFLAG_SLAY, "Toggles Friendly Fire status on target string, allowing affected players to damage other players.");
	RegAdminCmd("sm_takeff", Command_ToggleTakeFriendlyFire, ADMFLAG_SLAY, "Toggles Take Friendly Fire status on target string, allowing affected players to be damaged by other players.");
	
	g_bFriendlyFire = true;
	g_bOrigFriendlyFire = GetConVarBool(g_hFriendlyFire);
	SetConVarBool(g_hFriendlyFire, true);
}

public OnPluginEnd()
{
	SetConVarBool(g_hFriendlyFire, g_bOrigFriendlyFire);
}

public OnConfigsExecuted()
{
	if(g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
			}
		}

		g_bLateLoad = false;
	}
}

public OnClientDisonnect(client)
{
	g_bDoingShooting[client] = false;
	g_bGettingShot[client] = false;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public Action:Command_ToggleDealFriendlyFire(client, args)
{
	if (g_bFriendlyFire)
	{
		decl String:sPattern[64], String:sBuffer[64];
		GetCmdArg(1, sPattern, sizeof(sPattern));
		new iTargets[64], bool:bMb;
		new iCount = ProcessTargetString(sPattern, client, iTargets, sizeof(iTargets), COMMAND_FILTER_CONNECTED, sBuffer, sizeof(sBuffer), bMb);
		for (new i = 0; i < iCount; i++)
		{
			if (IsClientInGame(iTargets[i]))
			{
				g_bDoingShooting[iTargets[i]] = !(g_bDoingShooting[iTargets[i]]);
				LogAction(client, i, "%L set deal friendly fire damage on %N to %s.", client, iTargets[i], g_bDoingShooting[iTargets[i]] ? "on" : "off");
				ShowActivity2(client, "[SM] ", "Set deal friendly fire damage on %N to %s.", iTargets[i], g_bDoingShooting[iTargets[i]] ? "on" : "off");
			}
		}
	} 
	else
		ReplyToCommand(client, "[SM] FriendlyFire Manager is currently disabled.");
	
	return Plugin_Handled;
}

public Action:Command_ToggleTakeFriendlyFire(client, args)
{
	if (g_bFriendlyFire)
	{
		decl String:sPattern[64], String:sBuffer[64];
		GetCmdArg(1, sPattern, sizeof(sPattern));
		new iTargets[64], bool:bMb;
		new iCount = ProcessTargetString(sPattern, client, iTargets, sizeof(iTargets), COMMAND_FILTER_CONNECTED, sBuffer, sizeof(sBuffer), bMb);
		for (new i = 0; i < iCount; i++)
		{
			if (IsClientInGame(iTargets[i]))
			{
				g_bGettingShot[iTargets[i]] = !(g_bGettingShot[iTargets[i]]);
				LogAction(client, i, "%L set take friendly fire damage on %N to %s.", client, iTargets[i], g_bGettingShot[iTargets[i]] ? "on" : "off");
				ShowActivity2(client, "[SM] ", "Set take friendly fire damage on %N to %s.", iTargets[i], g_bGettingShot[iTargets[i]] ? "on" : "off");
			}
		}
	} 
	else
		ReplyToCommand(client, "[SM] FriendlyFire Manager is currently disabled.");
	
	return Plugin_Handled;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(!g_bFriendlyFire || g_bFriendlyFireForAll)
		return Plugin_Continue;
	else if(victim <= 0 || attacker <= 0 || victim > MaxClients || attacker > MaxClients)
		return Plugin_Continue;
	else if(GetClientTeam(victim) != GetClientTeam(attacker) || g_bGettingShot[victim] || g_bDoingShooting[attacker])
		return Plugin_Continue;
	else 
	{
		damage = 0.0;
		return Plugin_Changed;
	}
}

public OnSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bFriendlyFire = GetConVarBool(g_hFriendlyFire);
	g_bFriendlyFireForAll = GetConVarBool(g_hFriendlyFireForAll);
}