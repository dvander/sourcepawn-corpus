#define PLUGIN_VERSION	"1.0"
#define PLUGIN_NAME     "Melee Damage To Tank"
#define PLUGIN_PREFIX   "melee_damage_to_tank"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar C_damage_melee;
float O_damage_melee;
ConVar C_damage_chainsaw;
float O_damage_chainsaw;

bool Late_load;

Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(weapon != -1 && damage >= 1.0 && GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(victim) && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2)
	{
        char class_name[64];
        GetEntityClassname(weapon, class_name, sizeof(class_name));
        if(strcmp(class_name, "weapon_melee") == 0)
        {
            damage *= O_damage_melee;
            if(damage < 1.0)
            {
                damage = 1.0;
            }
            return Plugin_Changed;
        }
        else if(strcmp(class_name, "weapon_chainsaw") == 0)
        {
            damage *= O_damage_chainsaw;
            if(damage < 1.0)
            {
                damage = 1.0;
            }
            return Plugin_Changed;
        }
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void get_all_cvars()
{
    O_damage_melee = C_damage_melee.FloatValue;
    O_damage_chainsaw = C_damage_chainsaw.FloatValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_damage_melee)
    {
        O_damage_melee = C_damage_melee.FloatValue;
    }
    else if(convar == C_damage_chainsaw)
    {
        O_damage_chainsaw = C_damage_chainsaw.FloatValue;
    } 
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    Late_load = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    C_damage_melee = CreateConVar(PLUGIN_PREFIX ... "_melee", "0.4", "damage scale to tank by melee. at least keep 1.0 damage", _, true, 0.0);
    C_damage_melee.AddChangeHook(convar_changed);
    C_damage_chainsaw = CreateConVar(PLUGIN_PREFIX ... "_chainsaw", "0.4", "damage scale to tank by melee. at least keep 1.0 damage", _, true, 0.0);
    C_damage_chainsaw.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, PLUGIN_PREFIX);
    get_all_cvars();

    if(Late_load)
    {
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				OnClientPutInServer(client);
			}
		}
    }
}