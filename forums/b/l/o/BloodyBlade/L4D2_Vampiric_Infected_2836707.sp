#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define L4D2 Vampiric Infected
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8
#define STRING_LENGHT 56

public Plugin myinfo = 
{
    name = "[L4D2] Vampiric Infected",
    author = "Mortiegama",
    description = "Allows for special infected to regenerate health by attacking.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2104669#post2104669"
}

PluginData plugin;

enum struct PluginCvars
{
    ConVar cvarVampiricCommon;
    ConVar cvarVampiricCommonAmount;
    ConVar cvarVampiricCommonCooldown;
    ConVar cvarVampiricCommonReduction;

    void Init()
    {
        CreateConVar("l4d_vim_version", PLUGIN_VERSION, "Destructive Hunter Version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
        this.cvarVampiricCommon = CreateConVar("l4d_vim_vampiriccommon", "1", "Enables the ability for Special Infected to attack common infected to regain health. (Def 1)", CVAR_FLAGS, true, 0.0, false, _);
        this.cvarVampiricCommonAmount  = CreateConVar("l4d_vim_vampiriccommonamount", "5", "Amount of HP the Special Infected will receive each time it attacks a common infected. (Def 5)", CVAR_FLAGS, true, 0.0, false, _);
        this.cvarVampiricCommonCooldown  = CreateConVar("l4d_vim_vampiriccommoncooldown", "0.5", "Cooldown period between vampiric hits. (Def 0.5)", CVAR_FLAGS, true, 0.0, false, _);
        this.cvarVampiricCommonReduction  = CreateConVar("l4d_vim_vampiriccommonreduction", "0.3", "Percent to reduce damage done to common infected while feeding. (Def 0.3)", CVAR_FLAGS, true, 0.0, false, _);

        this.cvarVampiricCommon.AddChangeHook(OnConVarsChanged);
        this.cvarVampiricCommonAmount.AddChangeHook(OnConVarsChanged);
        this.cvarVampiricCommonCooldown.AddChangeHook(OnConVarsChanged);
        this.cvarVampiricCommonReduction.AddChangeHook(OnConVarsChanged);

        AutoExecConfig(true, "plugin.L4D2.VampiricInfected");
    }
}

enum struct PluginData
{
    PluginCvars cvars;
    bool bVampiricCommonPluginEnable;
    int iBoomerHealth;
    int iChargerHealth;
    int iHunterHealth;
    int iJockeyHealth;
    int iSmokerHealth;
    int iSpitterHealth;
    int iHPRegen;
    int iMaxHP;
    int iHP;
    float fDamageMod;
    float fCooldown;
    float cooldownVampiricCommon[MAXPLAYERS + 1];

    void Init()
    {
        this.cvars.Init();
    }

    void GetCvarValues()
    {
        this.bVampiricCommonPluginEnable = this.cvars.cvarVampiricCommon.BoolValue;
        this.iBoomerHealth = FindConVar("z_exploding_health").IntValue;		
        this.iChargerHealth = FindConVar("z_charger_health").IntValue;		
        this.iHunterHealth = FindConVar("z_hunter_health").IntValue;
        this.iJockeyHealth = FindConVar("z_jockey_health").IntValue;
        this.iSmokerHealth = FindConVar("z_gas_health").IntValue;
        this.iSpitterHealth = FindConVar("z_spitter_health").IntValue;
        this.iHPRegen = this.cvars.cvarVampiricCommonAmount.IntValue;
        this.fCooldown = this.cvars.cvarVampiricCommonCooldown.FloatValue;
        this.fDamageMod = this.cvars.cvarVampiricCommonReduction.FloatValue;
    }
}

public void OnPluginStart()
{
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.GetCvarValues();
}

void OnConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	plugin.GetCvarValues();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(plugin.bVampiricCommonPluginEnable)
    {
        if(entity > 0 && entity > MaxClients && entity <= 2048 && IsValidEntity(entity) && IsValidEdict(entity))
        {
            if (StrEqual(classname, "infected", false))
            {
                SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
    }
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (plugin.bVampiricCommonPluginEnable)
    {
        if(IsValidClient(attacker) && IsVampiricCommonReady(attacker))
        {
            if (IsValidEdict(victim))
            {	
                if (FloatCompare(plugin.fDamageMod, 1.0) != 0)
                {
                    damage = damage * plugin.fDamageMod;
                }
                
                int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
                plugin.iHP = GetClientHealth(attacker);

                switch (class)  
                {	
                    case ZOMBIECLASS_BOOMER:
                    {
                        plugin.iMaxHP = plugin.iBoomerHealth;
                    }
                    case ZOMBIECLASS_CHARGER:
                    {
                        plugin.iMaxHP = plugin.iChargerHealth;
                    }
                    case ZOMBIECLASS_JOCKEY:
                    {
                        plugin.iMaxHP = plugin.iJockeyHealth;
                    }
                    case ZOMBIECLASS_HUNTER:
                    {
                        plugin.iMaxHP = plugin.iHunterHealth;
                    }
                    case ZOMBIECLASS_SMOKER:
                    {
                        plugin.iMaxHP = plugin.iSmokerHealth;
                    }
                    case ZOMBIECLASS_SPITTER:
                    {
                        plugin.iMaxHP = plugin.iSpitterHealth;
                    }
                }

                if ((plugin.iHPRegen + plugin.iHP) <= plugin.iMaxHP)
                {
                    SetEntProp(attacker, Prop_Send, "m_iHealth", plugin.iHPRegen + plugin.iHP, 1);
                }
                else if (plugin.iHP < plugin.iMaxHP && plugin.iMaxHP < (plugin.iHPRegen + plugin.iHP))
                {
                    SetEntProp(attacker, Prop_Send, "m_iHealth", plugin.iMaxHP, 1);
                }

                plugin.cooldownVampiricCommon[attacker] = GetEngineTime();
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3;
}

bool IsVampiricCommonReady(int client)
{
	return (GetEngineTime() - plugin.cooldownVampiricCommon[client]) > plugin.fCooldown;
}