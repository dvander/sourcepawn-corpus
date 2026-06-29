#define PLUGIN_VERSION  "1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define MODEL_FIRE_BOX	"models/props_junk/explosive_box001.mdl"

public Plugin myinfo =
{
	name = "SI Enhance Charger Fire",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351214"
};

ConVar C_damage_multiple;
float O_damage_multiple;

bool Last_attack[MAXPLAYERS+1];
int Last_fire[MAXPLAYERS+1] = {-1, ...};

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

public void OnMapStart()
{
    PrecacheModel(MODEL_FIRE_BOX, true);
}

public void OnClientDisconnect_Post(int client)
{
    reset_player(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(entity < 1)
    {
        return;
    }
    if(strcmp(classname, "fire_cracker_blast") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
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

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_client);
}

void OnSpawnPost(int entity)
{
    int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    if(owner > 0 && owner <= MaxClients && Last_attack[owner])
    {
        Last_attack[owner] = false;
        Last_fire[owner] = EntIndexToEntRef(entity);
    }
}

bool is_charger_fire(int inflictor)
{
    if(inflictor == -1)
    {
        return false;
    }
    int ref = EntIndexToEntRef(inflictor);
    for(int i = 1; i <= MaxClients; i++)
    {
        if(ref == Last_fire[i])
        {
            return true;
        }
    }
    return false;
}

Action OnTakeDamage_client(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(is_charger_fire(inflictor))
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
	if(is_charger_fire(inflictor))
	{
        damage = 0.0;
        return Plugin_Handled;
	}
	return Plugin_Continue;
}

void remove_ref(int& ref)
{
    if(ref == -1)
    {
        return;
    }
    int entity = EntRefToEntIndex(ref);
    ref = -1;
    if(entity != -1)
    {
        RemoveEntity(entity);
    }
}

void reset_player(int client)
{
    Last_attack[client] = false;
    remove_ref(Last_fire[client]);
}

void reset_all()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            reset_player(client);
        }
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
        reset_player(client);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
        reset_player(client);
	}
}

void event_charger_pummel_start(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client))
	{
        remove_ref(Last_fire[client]);
        int entity = CreateEntityByName("prop_physics");
        if(entity != -1)
        {
            float pos[3];
            GetClientAbsOrigin(client, pos);
            DispatchKeyValue(entity, "model", MODEL_FIRE_BOX); 
            TeleportEntity(entity, pos);
            DispatchSpawn(entity);
            SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
            SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
            Last_attack[client] = true;
            AcceptEntityInput(entity, "Break");
            Last_attack[client] = false;
        }
	}
}

void event_charger_pummel_end(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
        reset_player(client);
	}
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
    HookEvent("round_start", event_round_start);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
    HookEvent("charger_pummel_start", event_charger_pummel_start);
    HookEvent("charger_pummel_end", event_charger_pummel_end);

    C_damage_multiple = CreateConVar("si_enhance_charger_fire_damage_multiple", "1.0", "burn damage multiple to survivors. at least keep 1.0 damage", _, true, 0.0);
    C_damage_multiple.AddChangeHook(convar_changed);
    CreateConVar("si_enhance_charger_fire_version", PLUGIN_VERSION, "version of SI Enhance Charger Fire", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "si_enhance_charger_fire");
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
