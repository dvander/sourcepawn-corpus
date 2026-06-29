#include <sourcemod>
#include <liquidHelpers>
#include <left4dhooks>

#define PLUGIN_VERSION		"1.0"
#define PLUGIN_NAME         "charger_scaling"
#define PLUGIN_NAME_FULL	"[L4D2] Set charger damage per difficulty"
#define PLUGIN_DESCRIPTION	"Allows easy set of charger damage per difficulty"
#define PLUGIN_AUTHOR		"liquidplasma"
#define PLUGIN_LINK			""

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar IncapMult;       float ChargerIncapMult;

ConVar PoundEasy;       int PoundDamageEasy;
ConVar ChargeEasy;      int ChargeDamageEasy;

ConVar PoundNormal;     int PoundDamageNormal;
ConVar ChargeNormal;    int ChargeDamageNormal;

ConVar PoundAdvanced;   int PoundDamageAdvanced;
ConVar ChargeAdvanced;  int ChargeDamageAdvanced;

ConVar PoundExpert;     int PoundDamageExpert;
ConVar ChargeExpert;    int ChargeDamageExpert;

ConVar
    Pound,
    Charge;

public void OnPluginStart()
{
    IncapMult =         CreateConVar("z_charger_incap_mult", "3.0", "Damage multiplier when victim is incapacitated while getting pummelled by a charger", FCVAR_NOTIFY, true, 0.0, true, 4096.0);

    PoundEasy =         CreateConVar(PLUGIN_NAME ... "_pound_easy", "8", "Pound damage for the charger on easy difficulty", FCVAR_NOTIFY);
    ChargeEasy =        CreateConVar(PLUGIN_NAME ... "_charge_easy", "5", "Impact damage of charge on easy difficulty", FCVAR_NOTIFY);
    PoundNormal =       CreateConVar(PLUGIN_NAME ... "_pound_normal", "15", "Pound damage for the charger on normal difficulty", FCVAR_NOTIFY);
    ChargeNormal =      CreateConVar(PLUGIN_NAME ... "_charge_normal", "10", "Impact damage of charge on normal difficulty", FCVAR_NOTIFY);
    PoundAdvanced =     CreateConVar(PLUGIN_NAME ... "_pound_advanced", "22", "Pound damage for the charger on advanced difficulty", FCVAR_NOTIFY);
    ChargeAdvanced =    CreateConVar(PLUGIN_NAME ... "_charge_advanced", "15", "Impact damage of charge on advanced difficulty", FCVAR_NOTIFY);
    PoundExpert =       CreateConVar(PLUGIN_NAME ... "_pound_expert", "30", "Pound damage for the charger on expert difficulty", FCVAR_NOTIFY);
    ChargeExpert =      CreateConVar(PLUGIN_NAME ... "_charge_expert", "20", "Impact damage of charge on expert difficulty", FCVAR_NOTIFY);

    IncapMult.AddChangeHook(ChangedConvar);

    PoundEasy.AddChangeHook(ChangedConvar);
    PoundNormal.AddChangeHook(ChangedConvar);
    PoundAdvanced.AddChangeHook(ChangedConvar);
    PoundExpert.AddChangeHook(ChangedConvar);

    ChargeEasy.AddChangeHook(ChangedConvar);
    ChargeNormal.AddChangeHook(ChangedConvar);
    ChargeAdvanced.AddChangeHook(ChangedConvar);
    ChargeExpert.AddChangeHook(ChangedConvar);

    AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);
    ConvarRead();

    Charge = FindConVar("z_charge_max_damage");
    Pound = FindConVar("z_charger_pound_dmg");
    HookEvent("difficulty_changed", ChangedDifficulty,  EventHookMode_Post);
    BuffCharger();
}


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void ConvarRead()
{
    PoundDamageEasy = PoundEasy.IntValue;
    PoundDamageNormal = PoundNormal.IntValue;
    PoundDamageAdvanced = PoundAdvanced.IntValue;
    PoundDamageExpert = PoundExpert.IntValue;

    ChargeDamageEasy = ChargeEasy.IntValue;
    ChargeDamageNormal = ChargeNormal.IntValue;
    ChargeDamageAdvanced = ChargeAdvanced.IntValue;
    ChargeDamageExpert = ChargeExpert.IntValue;

    ChargerIncapMult = IncapMult.FloatValue;
}

public void ChangedConvar(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ConvarRead();
}

public void ChangedDifficulty(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    BuffCharger();
}

void SetConvars(int pound, int charge)
{
    SetConVarInt(Pound, pound);
    SetConVarInt(Charge, charge);
}

void BuffCharger()
{
    switch (GetDifficulty())
    {
        case INVALID_DIFFICULTY:
            SetFailState("Invalid difficulty detected");

        case EASY:
            SetConvars(PoundDamageEasy, ChargeDamageEasy);

        case NORMAL:
            SetConvars(PoundDamageNormal, ChargeDamageNormal);

        case ADVANCED:
            SetConvars(PoundDamageAdvanced, ChargeDamageAdvanced);

        case EXPERT:
            SetConvars(PoundDamageExpert, ChargeDamageExpert);
    }
}

bool InflictorCheck(int inflictor, int attacker)
{
    if (IsValidClient(inflictor) && attacker == inflictor)
        return true;

    return false;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!InflictorCheck(inflictor, attacker))
        return Plugin_Continue;
    else if (IsCharger(attacker) && IsClientInGame(victim) && OnSurvivorTeam(victim) && L4D_IsPlayerIncapacitated(victim) && L4D_GetVictimCharger(attacker) == victim)
    {
        damage = damage * ChargerIncapMult;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}