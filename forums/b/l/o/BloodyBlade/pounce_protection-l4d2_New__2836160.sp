#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"
#define PLUGIN_AUTHOR "dcx2, cravenge"
#define PLUGIN_NAME "[L4D2] Pounce Protection"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Allows jockeys and smokers to protect their pin from other infected by pressing crouch",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1973444"
};

bool bL4D2 = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine == Engine_Left4Dead)
	{
		bL4D2 = false;
	}
	else if (engine == Engine_Left4Dead2)
    {
		bL4D2 = true;
	}
	else
	{
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
	ConVar ppEnable;
	ConVar ppSmokerDamage;
	ConVar ppSmokerDamageIncap;

	void Init()
	{
		CreateConVar("pounce_protection_version", PLUGIN_VERSION, "Pounce Protection Version", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.ppEnable = CreateConVar("pounce_protection_enable", "1", "Enable/Disable Plugin", CVAR_FLAGS);
		this.ppSmokerDamage = CreateConVar("pounce_protection_smoker_damage", "10.0", "Damage Dealt To Smoker Protected Victims", CVAR_FLAGS);
		this.ppSmokerDamageIncap = CreateConVar("pounce_protection_smoker_damage_incap", "20.0", "Damage Dealt To Smoker Protected Incapacitated Victims", CVAR_FLAGS);

		this.ppEnable.AddChangeHook(Event_PluginOnConVarChanged);
		this.ppSmokerDamage.AddChangeHook(Event_ConVarsChanged);
		this.ppSmokerDamageIncap.AddChangeHook(Event_ConVarsChanged);

		AutoExecConfig(true, "pounce_protection");
	}
}

/****************************************************************************************************/

enum struct PluginData
{
	PluginCvars cvars;
	bool bPluginOn;
	bool bHooked;
	int g_ProtectPin[MAXPLAYERS + 1];
	float fSmokerDamage;
	float fSmokerDamageIncap;

	void Init()
	{
		this.cvars.Init();
	}

	void GetCvarValues()
	{
		this.fSmokerDamage = this.cvars.ppSmokerDamage.FloatValue;
		this.fSmokerDamageIncap = this.cvars.ppSmokerDamageIncap.FloatValue;
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.ppEnable.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			if(bL4D2)
			{
				HookEvent("jockey_ride", OnEnableProtection);
				HookEvent("jockey_ride_end", OnDisableProtection);
			}
			HookEvent("tongue_grab", OnEnableProtection);
			HookEvent("tongue_release", OnDisableProtection);
			HookEvent("player_bot_replace", OnProtectionCheck);
			HookEvent("bot_player_replace", OnProtectionCheck);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			if(bL4D2)
			{
				UnhookEvent("jockey_ride", OnEnableProtection);
				UnhookEvent("jockey_ride_end", OnDisableProtection);
			}
			UnhookEvent("tongue_grab", OnEnableProtection);
			UnhookEvent("tongue_release", OnDisableProtection);
			UnhookEvent("player_bot_replace", OnProtectionCheck);
			UnhookEvent("bot_player_replace", OnProtectionCheck);
		}
	}
}

/****************************************************************************************************/

public void OnPluginStart()
{
    plugin.Init();
}

public void OnConfigsExecuted()
{
    plugin.IsAllowed();
}

void Event_PluginOnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    plugin.IsAllowed();
}

void Event_ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    plugin.GetCvarValues();
}

public void OnClientPutInServer(int client)
{
	if(plugin.bHooked && client > 0)
	{
		SDKHook(client, SDKHook_OnTakeDamage, ProtectedDamageFix);
	}
}

Action OnEnableProtection(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (attacker > 0 && victim > 0)
	{
		plugin.g_ProtectPin[attacker] = victim;
		SetEntPropEnt(victim, Prop_Send, "m_pounceAttacker", attacker);
		if (StrEqual(name, "jockey_ride"))
		{
			SetEntityMoveType(attacker, MOVETYPE_ISOMETRIC);
		}
	}
	return Plugin_Continue;
}

Action OnDisableProtection(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (attacker > 0 && victim > 0)
	{	
		plugin.g_ProtectPin[attacker] = 0;
		SetEntPropEnt(victim, Prop_Send, "m_pounceAttacker", -1);
		SetEntPropEnt(attacker, Prop_Send, "m_pounceVictim", -1);
		if (StrEqual(name, "jockey_ride_end"))
		{
			SetEntityMoveType(attacker, MOVETYPE_CUSTOM);
		}
	}
	return Plugin_Continue;
}

Action OnProtectionCheck(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (GetActualAttacker(bot) > 0)
	{
		plugin.g_ProtectPin[GetActualAttacker(bot)] = 0;
		SetEntPropEnt(bot, Prop_Send, "m_pounceAttacker", -1);
		SetEntPropEnt(GetActualAttacker(bot), Prop_Send, "m_pounceVictim", -1);

		int player = GetClientOfUserId(event.GetInt("player"));
		if (player > 0 && IsClientInGame(player) && !IsFakeClient(player) && GetActualAttacker(player) > 0)
		{
			plugin.g_ProtectPin[GetActualAttacker(player)] = 0;
			SetEntPropEnt(player, Prop_Send, "m_pounceAttacker", -1);
			SetEntPropEnt(GetActualAttacker(player), Prop_Send, "m_pounceVictim", -1);
		}
	}
	return Plugin_Continue;
}

Action ProtectedDamageFix(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (plugin.bHooked && IsSurvivor(victim) && IsInfected(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 1)
	{
		damage = IsIncapacitated(victim) ? plugin.fSmokerDamageIncap : plugin.fSmokerDamage;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

int GetActualAttacker(int victim)
{
	int attacker = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && plugin.g_ProtectPin[i] == victim) 
		{
			attacker = i;
			break;
		}
	}
	return attacker;
}

stock bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}

stock bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}
