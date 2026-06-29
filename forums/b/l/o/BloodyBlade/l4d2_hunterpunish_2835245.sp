#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY
 
public Plugin myinfo =
{
	name = "Hunter Punch Punish",
	author = "Rain_orel(edit. by BloodyBlade)",
	description = "Punishes n00b hunters",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

ConVar hHunterPunchPunishEnabled, hKillHunterEnabled, hHealth, hIgniteTime;
bool bIsAllowed = false;
float fIgniteTime = 0.0;
int iKillHunterEnabled = 0, iHealth = 0;

public void OnPluginStart()
{
	CreateConVar("hpp_hunterpunish_version", PLUGIN_VERSION, "Hunter Punch Punish plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hHunterPunchPunishEnabled = CreateConVar("hpp_hunterpunish_on", "1", "0 - disable the plugin, 1 - enable the plugin", CVAR_FLAGS);
	hKillHunterEnabled = CreateConVar("hpp_hunterpunish", "1", "Hunter punish type: 0 - don't punish, 1- kill, 2 - ignite", CVAR_FLAGS);
	hHealth = CreateConVar("hpp_givehealth", "5", "How much health must be given to survivor.", CVAR_FLAGS);
	hIgniteTime = CreateConVar("hpp_ignitetime", "30", "Number of seconds to set hunter on fire if fire punish is enabled.", CVAR_FLAGS);

	AutoExecConfig(true, "hpp_hunterpunish");

	hHunterPunchPunishEnabled.AddChangeHook(OnConVarPluginOnChanged);
	hKillHunterEnabled.AddChangeHook(OnConVarsChanged);
	hHealth.AddChangeHook(OnConVarsChanged);
	hIgniteTime.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	iKillHunterEnabled = hKillHunterEnabled.IntValue;
	iHealth = hHealth.IntValue;
	fIgniteTime = hIgniteTime.FloatValue;
}

void IsAllowed()
{
	bool bPluginOn = hHunterPunchPunishEnabled.BoolValue;
	if(!bIsAllowed && bPluginOn)
	{
		bIsAllowed = true;
		OnConVarsChanged(null, "", "");
		HookEvent("hunter_punched", Event_HunterPunched);	
	}
	else if(bIsAllowed && !bPluginOn)
	{
		bIsAllowed = false;
		UnhookEvent("hunter_punched", Event_HunterPunched);
	}
}

void Event_HunterPunched(Event event, const char[] name, bool dontBroadcast)
{
   int survivor = GetClientOfUserId(event.GetInt("userid"));
   int hunter = GetClientOfUserId(event.GetInt("hunteruserid"));

   if(IsValidSurv(survivor) && IsValidInf(survivor))
   {
	   if(event.GetBool("islunging"))
	   {
			switch(iKillHunterEnabled)
			{
				case 1:
				{
					int AttackerHealth = GetClientHealth(hunter);
					DealDamage(hunter, AttackerHealth, survivor, DMG_BULLET, "weapon_sniper_awp");
					DealDamage(hunter, AttackerHealth, survivor, DMG_BULLET, "weapon_sniper_awp");
				}
				case 2:
				{
					IgniteEntity(hunter, fIgniteTime);
				}
			}
			int health = GetClientHealth(survivor);
			SetEntityHealth(survivor, health + iHealth);
		}
	}
}

void DealDamage(int victim, int damage, int attacker = 0, int dmg_type = DMG_GENERIC, char[] weapon = "")
{
	if(IsValidInf(victim))
	{
		char dmg_str[16];
		IntToString(damage, dmg_str, 16);
		char dmg_type_str[32];
		IntToString(dmg_type, dmg_type_str, 32);
		int pointHurt = CreateEntityByName("point_hurt");
		if (pointHurt)
		{
			DispatchKeyValue(victim, "targetname", "hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
			DispatchKeyValue(pointHurt, "Damage", dmg_str);
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);

			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt, "classname", weapon);
			}

			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", (attacker > 0) ? attacker : -1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "hurtme");
			RemoveEdict(pointHurt);
		}
	}
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}

bool IsValidSurv(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

bool IsValidInf(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3;
}
