#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D] Fryendly Fire Mirror",
	author = "BloodyBlade",
	description = "Mirror damage when dealing damage to your team members.",
	version = PLUGIN_VERSION,
	url = "http://bloodsiworld.ru/"
};

ConVar g_hEnabled;
bool bHooked = false;

public void OnPluginStart()
{
	CreateConVar("l4d_ff_mirror_version", PLUGIN_VERSION, "[L4D] Fryendly Fire Mirror plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("l4d_ff_mirror_enabled", "1", "Enable/Disable plugin.", CVAR_FLAGS);
	AutoExecConfig(true, "l4d_ff_mirror");
	g_hEnabled.AddChangeHook(OnConVarPluginOnChange);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = g_hEnabled.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("player_hurt", Event_PlayerHurt);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_hurt", Event_PlayerHurt);
	}
}
 
void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsValidClient(victim) && IsValidClient(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
	{
		int iDmgHealth = event.GetInt("dmg_health");
		if(iDmgHealth > 0)
		{
			char dmg_str[16], dmg_type_str[32];
			IntToString(event.GetInt("dmg_health"), dmg_str, 16);
			IntToString(0, dmg_type_str, 32);
			int pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				DispatchKeyValue(victim, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", dmg_str);
				DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", -1);
				DispatchKeyValue(pointHurt, "classname", "point_hurt");
				DispatchKeyValue(victim, "targetname", "hurtme");
				RemoveEdict(pointHurt);
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}
