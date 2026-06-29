#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar cv_BileDamageOn, cv_BileDamageOnVomited, cv_BileDamageNotVomited;
bool bHooked = false, bVomited[MAXPLAYERS + 1] = {false, ...};
float fBileDamageOnVomited = 0.0, fBileDamageNotVomited = 0.0;

public Plugin myinfo = 
{
	name = "[L4D] Biled Tank Damage",
	author = "pa4H(Rewritten by BloodyBlade)", 
	description = "Allows you to change the damage to the tank when it is vomited and not vomited", 
	version = PLUGIN_VERSION, 
	url = "https://t.me/pa4H232"
}

public void OnPluginStart()
{
	CreateConVar("l4d_biled_tank_damage_plugin_version", PLUGIN_VERSION, "Biled Tank Damage plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	cv_BileDamageOn = CreateConVar("l4d_biled_tank_damage_enable", "1.0", "Plugin enable/disable", CVAR_FLAGS);
	cv_BileDamageOnVomited = CreateConVar("l4d_biled_tank_damage_vomited", "20.0", "0.0 = No changes. Damage from zombies when the tank is vomited", CVAR_FLAGS);
	cv_BileDamageNotVomited = CreateConVar("l4d_biled_tank_damage_not_vomited", "20.0", "0.0 = No changes. Damage from zombies when the tank is not vomited", CVAR_FLAGS);

	cv_BileDamageOn.AddChangeHook(ConVarAllowChanged);
	cv_BileDamageOnVomited.AddChangeHook(ConVarsChanged);
	cv_BileDamageNotVomited.AddChangeHook(ConVarsChanged);

	AutoExecConfig(true, "l4d_BiledTankDamage");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarAllowChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    fBileDamageOnVomited = cv_BileDamageOnVomited.FloatValue;
    fBileDamageNotVomited = cv_BileDamageNotVomited.FloatValue;
}

void IsAllowed()
{
	bool bPluginOn = cv_BileDamageOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("player_now_it", EventNowVomit);
		HookEvent("player_no_longer_it", EventNoLongerVomit);
		HookEvent("player_death", EventNoLongerVomit);
		HookEvent("round_start", EventRound);
		HookEvent("round_end", EventRound);
		HookEvent("mission_lost", EventRound);
		HookEvent("map_transition", EventRound);
	}
	else
	{
		bHooked = false;
		UnhookEvent("player_now_it", EventNowVomit);
		UnhookEvent("player_no_longer_it", EventNoLongerVomit);
		UnhookEvent("player_death", EventNoLongerVomit);
		UnhookEvent("round_start", EventRound);
		UnhookEvent("round_end", EventRound);
		UnhookEvent("mission_lost", EventRound);
		UnhookEvent("map_transition", EventRound);
	}
}

public void OnClientPutInServer(int client)
{
	if(bHooked && client > 0)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (bHooked && IsCommonInfected(attacker) && IsValidTank(victim) && IsPlayerAlive(victim))
	{
		switch(bVomited[victim])
		{
			case false: // Commons continue to hit Tank after the vomit screen
			{
				if(fBileDamageNotVomited > 0.0)
				{
					damage = fBileDamageNotVomited;
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
			case true: // Bilejar is active (Tank's screen is vomited)
			{
				if(fBileDamageOnVomited > 0.0)
				{
					damage = fBileDamageOnVomited;
					return Plugin_Changed;
				}
				else
				{
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

void EventRound(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
	    if(IsValidTank(i))
	    {
	        bVomited[i] = false;
	    }
	}
}

void EventNowVomit(Event event, const char[] name, bool dontBroadcast)
{
	int iUserId = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidTank(iUserId))
	{
		bVomited[iUserId] = true;
	}
}

void EventNoLongerVomit(Event event, const char[] name, bool dontBroadcast)
{
	int iUserId = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidTank(iUserId))
	{
		bVomited[iUserId] = false;
	}
}

stock bool IsValidTank(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

stock bool IsCommonInfected(int iEntity)
{
    if(iEntity > 0 && iEntity <= 2048 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        char strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "infected");
    }
    return false;
}
