#define PLUGIN_VERSION	"1.3"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define REMOVE_BLOODSTAIN_INCAP (1 << 0)
#define REMOVE_BLOODSTAIN_DEATH (1 << 1)

public Plugin myinfo =
{
	name = "Remove Survivor Bloodstain",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=345915"
};

ConVar C_enable;
int O_enable;

int Stridx_ParticleEffect = INVALID_STRING_INDEX;
int Stridx_blood_incapacitated = INVALID_STRING_INDEX;
int Stridx_blood_bleedout = INVALID_STRING_INDEX;

public void OnMapStart()
{
    int table_EffectDispatch = FindStringTable("EffectDispatch");
    if(table_EffectDispatch != INVALID_STRING_TABLE)
    {
        Stridx_ParticleEffect = FindStringIndex(table_EffectDispatch, "ParticleEffect");
    }
    int table_ParticleEffectNames = FindStringTable("ParticleEffectNames");
    if(table_ParticleEffectNames != INVALID_STRING_TABLE)
    {
        Stridx_blood_incapacitated = FindStringIndex(table_ParticleEffectNames, "blood_incapacitated");
        Stridx_blood_bleedout = FindStringIndex(table_ParticleEffectNames, "blood_bleedout");
    }
}

public void OnMapEnd()
{
    Stridx_ParticleEffect = INVALID_STRING_INDEX;
    Stridx_blood_incapacitated = INVALID_STRING_INDEX;
    Stridx_blood_bleedout = INVALID_STRING_INDEX;
}

Action OnEffectDispatch(const char[] te_name, const int[] Players, int numClients, float delay)
{
    if(O_enable == 0)
    {
        return Plugin_Continue;
    }
    if(TE_ReadNum("m_iEffectName") != Stridx_ParticleEffect)
    {
        return Plugin_Continue;
    }
    int idx = TE_ReadNum("m_nHitBox");
    if(O_enable & REMOVE_BLOODSTAIN_INCAP && idx == Stridx_blood_incapacitated)
    {
        return Plugin_Handled;
    }
    if(O_enable & REMOVE_BLOODSTAIN_DEATH && idx == Stridx_blood_bleedout)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void get_all_cvars()
{
    O_enable = C_enable.IntValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_enable)
	{
		O_enable = C_enable.IntValue;
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
    C_enable = CreateConVar("remove_survivor_bloodstain_enable", "3", "1 = remove incap bloodstain, 2 = remove death bloodstain. add numbers together");
    C_enable.AddChangeHook(convar_changed);
    CreateConVar("remove_survivor_bloodstain_version", PLUGIN_VERSION, "version of Remove Survivor Bloodstain", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "remove_survivor_bloodstain");
    get_all_cvars();

    AddTempEntHook("EffectDispatch", OnEffectDispatch);
}
