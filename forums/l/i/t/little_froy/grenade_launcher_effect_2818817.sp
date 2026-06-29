#define PLUGIN_VERSION	"1.4"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Grenade Launcher Effect",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=346513"
};

static const char Grenade_particles[][64] = 
{
    "weapon_grenadelauncher",
    "weapon_grenadelauncher_dirt",
    "weapon_grenadelauncher_backup",
    "weapon_grenadelauncher_water"
};

ConVar C_add;
bool O_add;
ConVar C_model;
char O_model[PLATFORM_MAX_PATH];
ConVar C_scale;
float O_scale;
ConVar C_radius;
int O_radius;
ConVar C_magnitude;
int O_magnitude;
ConVar C_material_type;
int O_material_type;

bool Map_started;
int Model;
bool Got_config;

int Stridx_ParticleEffect = INVALID_STRING_INDEX;
int Stridx_weapon_grenadelauncher[sizeof(Grenade_particles)] = {INVALID_STRING_INDEX, ...};

public void OnMapStart()
{
    Map_started = true;
    if(Got_config)
    {
        Model = PrecacheModel(O_model, true);
    }
    int table_EffectDispatch = FindStringTable("EffectDispatch");
    if(table_EffectDispatch != INVALID_STRING_TABLE)
    {
        Stridx_ParticleEffect = FindStringIndex(table_EffectDispatch, "ParticleEffect");
    }
    int table_particle = FindStringTable("ParticleEffectNames");
    if(table_particle != INVALID_STRING_TABLE)
    {
        for(int i = 0; i < sizeof(Stridx_weapon_grenadelauncher); i++)
        {
            Stridx_weapon_grenadelauncher[i] = FindStringIndex(table_particle, Grenade_particles[i]);
        }
    }
}

public void OnMapEnd()
{
    Map_started = false;
    for(int i = 0; i < sizeof(Stridx_weapon_grenadelauncher); i++)
    {
        Stridx_weapon_grenadelauncher[i] = INVALID_STRING_INDEX;
    }
}

stock void next_frame(DataPack dp)
{
    if(!Map_started)
    {
        delete dp;
        return;
    }
    dp.Reset();
    float pos[3];
    for(int i = 0; i < 3; i++)
    {
        pos[i] = dp.ReadFloat();
    }
    delete dp;
    TE_SetupExplosion(pos, Model, O_scale, 0, 0, O_radius, O_magnitude, view_as<float>({0.0, 0.0, 0.0}), O_material_type);
    TE_SendToAll();
}

Action on_te_EffectDispatch(const char[] te_name, const int[] Players, int numClients, float delay)
{
    if(TE_ReadNum("m_iEffectName") != Stridx_ParticleEffect)
    {
        return Plugin_Continue;
    }
    int idx = TE_ReadNum("m_nHitBox");
    for(int i = 0; i < sizeof(Stridx_weapon_grenadelauncher); i++)
    {
        if(idx == Stridx_weapon_grenadelauncher[i])
        {
            if(O_add && Got_config)
            {
                DataPack dp = new DataPack();
                dp.WriteFloat(TE_ReadFloat("m_vOrigin.x"));
                dp.WriteFloat(TE_ReadFloat("m_vOrigin.y"));
                dp.WriteFloat(TE_ReadFloat("m_vOrigin.z"));
                RequestFrame(next_frame, dp);
            }
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public void OnConfigsExecuted()
{
    if(Got_config)
    {
        return;
    }
    Got_config = true;
    Model = PrecacheModel(O_model, true);
}

void get_all_cvars()
{
    O_add = C_add.BoolValue;
    C_model.GetString(O_model, sizeof(O_model));
    O_scale = C_scale.FloatValue;
    O_radius = C_radius.IntValue;
    O_magnitude = C_magnitude.IntValue;
    O_material_type = C_material_type.IntValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_add)
    {
        O_add = C_add.BoolValue;
    }
    else if(convar == C_model)
    {
        C_model.GetString(O_model, sizeof(O_model));
        if(Got_config)
        {
            if(Map_started)
            {
                Model = PrecacheModel(O_model, true);
            }
        }
    }
    else if(convar == C_scale)
    {
        O_scale = C_scale.FloatValue;
    }
    else if(convar == C_radius)
    {
        O_radius = C_radius.IntValue;
    }
    else if(convar == C_magnitude)
    {
        O_magnitude = C_magnitude.IntValue;
    }
    else if(convar == C_material_type)
    {
        O_material_type = C_material_type.IntValue;
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
    C_add = CreateConVar("grenade_launcher_effect_add", "1", "1 = enable, 0 = disable. add a custom effect after blocked?");
    C_add.AddChangeHook(convar_changed);
    C_model = CreateConVar("grenade_launcher_effect_model", "materials/editor/env_explosion.vmt", "model of effect");
    C_model.AddChangeHook(convar_changed);
    C_scale = CreateConVar("grenade_launcher_effect_scale", "1.0", "scale of effect");
    C_scale.AddChangeHook(convar_changed);
    C_radius = CreateConVar("grenade_launcher_effect_radius", "400", "radius of effect");
    C_radius.AddChangeHook(convar_changed);
    C_magnitude = CreateConVar("grenade_launcher_effect_magnitude", "0", "magnitude of effect");
    C_magnitude.AddChangeHook(convar_changed);
    C_material_type = CreateConVar("grenade_launcher_effect_material_type", "0", "material type of effect");
    C_material_type.AddChangeHook(convar_changed);
    CreateConVar("grenade_launcher_effect_version", PLUGIN_VERSION, "version of Grenade Launcher Effect", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "grenade_launcher_effect");
    get_all_cvars();

    AddTempEntHook("EffectDispatch", on_te_EffectDispatch);
}
