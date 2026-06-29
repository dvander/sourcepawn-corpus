/*
* [L4D] Fire Immunity Specials
* 
* Plugin Description:
* ==============================
* This Left 4 Dead 1 plugin allows special infected (boomer, hunter, and smoker)
* to have immunity from fire damage.
* 
* Convars:
* ==============================
* l4d_fireimmunityspecials_version
*   Fire Immunity Specials plugin version.
* 
* l4d_fis_enable
*   1: Enables the Fire Immunity Specials plugin.
* 
* l4d_fis_coop
*   1: Enables fire immunity in coop game mode.
* l4d_fis_survival
*   1: Enables fire immunity in survival game mode.
* l4d_fis_versus
*   1: Enables fire immunity in versus game mode.
* 
* l4d_fis_boomer
*   1: Enables fire immunity for boomers.
* l4d_fis_hunter
*   1: Enables fire immunity for hunters.
* l4d_fis_smoker
*   1: Enables fire immunity for smokers.
* 
* Configuration:
* ==============================
* Upon first run the l4d_fire_immunity_specials.cfg will be created under cfg/sourcemod.
* 
* Changelog:
* ==============================
* Legend:
*  + Added
*  - Removed
*  ~ Fixed or changed
* 
* Version 0.9.0 (2017.06.14)
* + Cvars supporting boomer, hunter, and smoker fire immunity
* + Cvars supporting individual game modes
* 
*/

// Preprocessor
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	  "0.9.0"
#define FIRE_DAMAGE_MASK  8
#define CVAR_FLAGS        FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED

/*
* Exposes plugin information.
*/
public Plugin myinfo =
{
                  
    name = "[L4D] Fire Immunity Specials",
    author = "Baz Newt",
    description = "Allows special infected to have immunity to fire damage.",
    version = PLUGIN_VERSION,
    url = "N/A"
};

bool g_bPluginIsEnabled;

bool g_bBoomerImmunity;
bool g_bHunterImmunity;
bool g_bSmokerImmunity;

// Can enable the plugin overall before any disabling convars are accounted
ConVar g_cvEnable;

// Can disable immunity for a special infected
ConVar g_cvBoomerEnable;
ConVar g_cvHunterEnable;
ConVar g_cvSmokerEnable;

// Can disable immunity for a game mode
ConVar g_cvCoopEnable;
ConVar g_cvSurvivalEnable;
ConVar g_cvVersusEnable;

/*
* Called once in the lifetime of the plugin.
*/
public void OnPluginStart()
{
    // Create convars
    CreateConVar("l4d_fireimmunityspecials_version", PLUGIN_VERSION,
	    "Fire Immunity Specials plugin version.", CVAR_FLAGS);

    g_cvEnable = CreateConVar("l4d_fis_enable", "1",
        "1: Enables the Fire Immunity Specials Infected plugin.", CVAR_FLAGS);

    g_cvBoomerEnable = CreateConVar("l4d_fis_boomer", "1",
        "1: Enables fire immunity for boomers.", CVAR_FLAGS);
    g_cvHunterEnable = CreateConVar("l4d_fis_hunter", "1",
        "1: Enables fire immunity for hunters.", CVAR_FLAGS);
    g_cvSmokerEnable = CreateConVar("l4d_fis_smoker", "1",
        "1: Enables fire immunity for smokers.", CVAR_FLAGS);

    g_cvCoopEnable = CreateConVar("l4d_fis_coop", "1",
        "1: Enables fire immunities in coop game mode.", CVAR_FLAGS);
    g_cvSurvivalEnable = CreateConVar("l4d_fis_survival", "1",
        "1: Enables fire immunities in survival game mode.", CVAR_FLAGS);
    g_cvVersusEnable = CreateConVar("l4d_fis_versus", "1",
        "1: Enables fire immunities in versus game mode.", CVAR_FLAGS);
    
	// Hook events
    HookEvent("player_hurt", Event_PlayerHurt);
    g_cvEnable.AddChangeHook(ConVarChange);
    g_cvCoopEnable.AddChangeHook(ConVarChange);
    g_cvSurvivalEnable.AddChangeHook(ConVarChange);
    g_cvVersusEnable.AddChangeHook(ConVarChange);
    g_cvBoomerEnable.AddChangeHook(ConVarChange);
    g_cvHunterEnable.AddChangeHook(ConVarChange);
    g_cvSmokerEnable.AddChangeHook(ConVarChange);

    AutoExecConfig(true, "l4d_fire_immunity_specials");
}

/*
* Handle player_hurt event to negate fire damage.
*/
public void Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
    int victim;
    int dmgType;
    char model[128];
    bool bFireImmunity;

    // Nobody is immune ever
    if(!g_bPluginIsEnabled)
    { return; }

    victim = GetClientOfUserId(GetEventInt(event, "userid"));

    // [TODO]: Do I need these conditions? What happens without them?
    if ((victim==0) || (!IsClientConnected(victim)) || (!IsClientInGame(victim))) 
    { return; }

    dmgType = GetEventInt(event,"type");

    // Check fire damage bit is on
    if((dmgType & FIRE_DAMAGE_MASK) != 8)
    { return; }

    GetClientModel(victim, model, sizeof(model));

    // Is it a special infected which concerns us?
    bFireImmunity = (StrContains(model, "boomer", false)!=-1 && g_bBoomerImmunity)
            || (StrContains(model, "hunter", false)!=-1 && g_bHunterImmunity)
            || (StrContains(model, "smoker", false)!=-1 && g_bSmokerImmunity);

    // Extinguish the burn victim
    if (bFireImmunity)
    {
        ExtinguishEntity(victim);
        int CurHealth = GetClientHealth(victim);
        int DmgDone = GetEventInt(event,"dmg_health");
        SetEntityHealth(victim,(CurHealth + DmgDone));
    }
}

/*
* Handle a convar change.
*/
public void ConVarChange(Handle convar, const char[] oldValue,
const char[] newValue)
{
    CheckDependencies();
}

/*
* Handle a map change.
*/
public void OnMapStart()
{
    CheckDependencies();
}

/*
* Determines if the plugin is enabled based on convar values
*/
void CheckDependencies()
{
    ConVar cvGameMode;
    char currGameMode[128];
    bool bCoopImmunity;
    bool bSurvivalImmunity;
    bool bVersusImmunity;

    g_bPluginIsEnabled = false;

    // Is plugin explicitly disabled?
    if (!GetConVarBool(g_cvEnable))
    { return; }

    cvGameMode = FindConVar("mp_gamemode");
    cvGameMode.GetString(currGameMode, 128);

    bCoopImmunity = GetConVarBool(g_cvCoopEnable);
    bSurvivalImmunity = GetConVarBool(g_cvSurvivalEnable);
    bVersusImmunity = GetConVarBool(g_cvVersusEnable);

    // If the current mode has immunity disabled then the plugin is disabled
    if (StrContains(currGameMode, "coop", false) != -1 && !bCoopImmunity)
    { return; }
    else if(StrContains(currGameMode, "survival", false) != -1 && !bSurvivalImmunity)
    { return; }
    else if(StrContains(currGameMode, "versus", false) != -1 && !bVersusImmunity)
    { return; }

    g_bBoomerImmunity = GetConVarBool(g_cvBoomerEnable);
    g_bHunterImmunity = GetConVarBool(g_cvHunterEnable);
    g_bSmokerImmunity = GetConVarBool(g_cvSmokerEnable);

    // If all specials are immune then the plugin is disabled
    if(!g_bBoomerImmunity && !g_bHunterImmunity && !g_bSmokerImmunity)
    { return; }

    // We're a go
    g_bPluginIsEnabled = true;
}