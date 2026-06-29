#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar hNoDeathCheck, hPluginEnabled;
bool bPluginOn = false;

public Plugin myinfo = 
{
	name = "Magic Defibrillator",
	author = "BloodyBlade",
	description = "Auto defibrillate if player has defibrillator.",
	version = PLUGIN_VERSION,
	url = "http://bloodsiworld.ru/"
}

public void OnPluginStart() 
{
	CreateConVar("l4d2_magic_defibrillator_version", PLUGIN_VERSION, "L4D2 Magic Defibrillator plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hNoDeathCheck = FindConVar("director_no_death_check");
	hPluginEnabled = CreateConVar("l4d2_magic_defibrillator_enabled", "1", "Enable/Disable the plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d2_magic_defibrillator");
	hPluginEnabled.AddChangeHook(ConVarPluginOnChanged);
}

public void OnConfigsExecuted() 
{
	ConVarPluginOnChanged(null, "", "");
}

void ConVarPluginOnChanged(ConVar cvar, char[] OldValue, char[] NewValue)
{
	bPluginOn = hPluginEnabled.BoolValue;
}

public void L4D_OnDeathDroppedWeapons(int client, int weapons[6])
{
	if(bPluginOn && client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		char slotName[64];
		GetEntityClassname(weapons[3], slotName, sizeof(slotName));
		if (StrEqual(slotName, "weapon_defibrillator", false))
		{
			hNoDeathCheck.BoolValue = true;
			RemoveEntity(weapons[3]);
			L4D2_DefibByDeadBody(client, client, false);
			hNoDeathCheck.BoolValue = false;
		}
	}
}
