#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION	"1.3"
#define PLUGIN_NAME		"NoDamage"

bool g_bLateLoad, g_bEnabled;
ConVar g_hEnabled;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Thomas Ross, fixes by Grey83 & Cruze",
	description = "Stops damage from being taken",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_nodamage_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_nodamage_enabled", "1", "1 = Plugin enabled, 0 = Disabled", FCVAR_SPONLY, true, 0.0, true, 1.0);

	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_bEnabled = g_hEnabled.BoolValue;

	if(g_bLateLoad && g_bEnabled)
	{	
		LateLoadConnect();
		g_bLateLoad = false;
	}
}

public int OnSettingsChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if(StrEqual(oldVal, newVal))
	{
		return;
	}
	
	g_bEnabled = !!StringToInt(newVal);

	if (g_bEnabled)
	{
		LateLoadConnect();
	}
	else
	{
		LateLoadDisconnect();
	}
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

 public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

public Action Event_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom) 
{ 
	if (g_bEnabled)
	{
		if(victim > 0 && victim <= MaxClients && damagetype == 1)
		{
			damage = 0.0;
			//float sPos[3];
			//GetClientAbsOrigin(victim, sPos);
			damagePosition[0] = 65536.0;
			damagePosition[1] = 65536.0;
			damagePosition[2] = 65536.0;
			//damagePosition = sPos;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

void LateLoadConnect()
{
	for(int client = 1; client <= MaxClients; client++) if(IsClientInGame(client))
	{
		OnClientPostAdminCheck(client);
	}
}

void LateLoadDisconnect()
{
	for(int client = 1; client <= MaxClients; client++) if(IsClientInGame(client))
	{
		OnClientDisconnect(client);
	}
}