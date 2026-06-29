#define PLUGIN_VERSION  "1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "SI Enhance Tank",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351214"
};

ConVar C_damage_multiple;
float O_damage_multiple;

ArrayList Bombs;

static const char No_damage_entites[][64] = 
{
    "infected",
    "witch",
    "weapon_gascan",
    "weapon_propanetank",
    "weapon_fireworkcrate",
    "weapon_oxygentank",
    "physics_prop",
    "prop_physics",
    "prop_fuel_barrel"
};

public void OnEntityCreated(int entity, const char[] classname)
{
    if(entity < 1)
    {
        return;
    }
    for(int i = 0; i < sizeof(No_damage_entites); i++)
    {
        if(strcmp(classname, No_damage_entites[i]) == 0)
        {
            SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_ent);
            return;
        }
    }
}

public void OnEntityDestroyed(int entity)
{
    if(entity < 1)
    {
        return;
    }
    int index = Bombs.FindValue(EntIndexToEntRef(entity));
    if(index != -1)
    {
        Bombs.Erase(index);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_client);
}

Action OnTakeDamage_client(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(inflictor != -1 && Bombs.FindValue(EntIndexToEntRef(inflictor)) != -1)
	{
        int team = GetClientTeam(victim);
        if(team == 3)
        {
            damage = 0.0;
            return Plugin_Handled;
        }
        else if(team == 2 && damage >= 1.0)
        {
            damage *= O_damage_multiple;
            if(damage < 1.0)
            {
                damage = 1.0;
            }
            return Plugin_Changed;
        }
	}
	return Plugin_Continue;
}

Action OnTakeDamage_ent(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(inflictor != -1 && Bombs.FindValue(EntIndexToEntRef(inflictor)) != -1)
	{
        damage = 0.0;
        return Plugin_Handled;
	}
	return Plugin_Continue;
}

void check_hurt(Event event)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if(attacker > 0 && attacker != client && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8)
        {
            char weapon[64];
            event.GetString("weapon", weapon, sizeof(weapon));
            if(strcmp(weapon, "tank_rock") == 0)
            {
                float pos[3];
                GetClientAbsOrigin(client, pos);
                int entity = L4D_PipeBombPrj(attacker, pos, view_as<float>({0.0, 0.0, 0.0}));
                if(IsValidEntity(entity))
                {
                    Bombs.Push(EntIndexToEntRef(entity));
                    L4D_DetonateProjectile(entity);
                }
            }
        }
	}
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
    check_hurt(event);
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
    check_hurt(event);
}

void get_all_cvars()
{
	O_damage_multiple = C_damage_multiple.FloatValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_damage_multiple)
	{
		O_damage_multiple = C_damage_multiple.FloatValue;
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
    return APLRes_Success;
}

public void OnPluginStart()
{
    Bombs = new ArrayList();

	HookEvent("player_hurt", event_player_hurt);
	HookEvent("player_incapacitated", event_player_incapacitated);

    C_damage_multiple = CreateConVar("si_enhance_tank_damage_multiple", "0.25", "blast damage multiple to survivors. at least keep 1.0 damage", _, true, 0.0);
    C_damage_multiple.AddChangeHook(convar_changed);
    CreateConVar("si_enhance_tank_version", PLUGIN_VERSION, "version of SI Enhance Tank", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "si_enhance_tank");
	get_all_cvars();

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
    }
    for(int i = 0; i < sizeof(No_damage_entites); i++)
    {
        int entity = -1;
        while((entity = FindEntityByClassname(entity, No_damage_entites[i])) != -1)
        {
            SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_ent);
        }
    }
}
