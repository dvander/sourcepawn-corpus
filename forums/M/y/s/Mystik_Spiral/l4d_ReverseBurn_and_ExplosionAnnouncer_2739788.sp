/*

ReverseBurn and ExplosionAnnouncer (l4d_ReverseBurn_and_ExplosionAnnouncer) by Mystik Spiral
  
Smart reverse of burn damage from explodables (gascans, fireworks, etc.) if the victim is burned instantly and continuously.  
It was created to help mitigate the damage by griefers attempting to kill/incap their teammates by burning them.  
  
Reverses the following explodable burn types:  
Gas can, barricade gas can, fuel barrel, gas pump, and fireworks crate.  
  
Announces the following explosion types:  
Gas can, barricade gas can, fuel barrel, gas pump, fireworks crate, propane tank, and oxygen tank.  
  
  
Features:  
  
- Burn damage is reversed only if victim(s) are burned instantly (within 0.75 second of ignition) and continuously (takes burn damage more than once per second).  
- If player runs into fire more than 0.75 seconds after ignition, burn damage is treated normally.  
- When burn damage is reversed, during each burn cycle (approximately 6x per second):  
  - Attacker takes 70% damage for each instantly/continuously burned victim  
  - Standing burn victims lose 1PermHP which is converted to 2TempHP as incentive to move out of the fire quickly.  
  - Before ignition, any players already incapped or with only 1TotalHP do not take any burn damage.  
- Bots do not take burn damage but do move out of the fire as quickly as possible.  
- Griefers cannot kill or incap a victim by burning them (victims still take some damage as stated above).  
- In all other scenarios, burn damage behaves normally.  
- Option to reverse burn/blast damage if attacker is an admin.  [RBaTA_admin, default: 0/false]  
- Option to reverse blast/explosion damage.  [RBaTA_blast, default: 1/true]  
  - If both RBaEA and RBaTA plugins are loaded, RBaEA takes precedence to avoid both plugins reversing blast/explosion damage.  
- Option to ban attacker (griefer) that disconnects during reverse burn. [RBaTA_banburndisconnect, default: 1/true]  
- Option to set ban duration in minutes. [RBaTA_banduration, default: 2880 (2 days)]  
  
  
Common Scenarios:  
  
- Griefer attempts to kill the whole team by burning them.  
Usual end result: Griefer takes 210% damage (70% per victim x 3 victims) plus possible additional self-damage and everyone else takes relatively minor damage.  
  
- Player starts fire (which does not burn anyone within 0.75 seconds) and griefer runs into it.  
Usual end result: Griefer takes normal damage and player that started the fire takes no damage.  
  
  
Suggestion:  
  
To minimize griefer impact, use the ReverseBurn and ExplosionAnnouncer plugin along with...  
  
ReverseBurn and ThrowableAnnouncer (l4d_ReverseBurn_and_ThrowableAnnouncer)  
- Smart reverse of burn damage from throwables, like molotovs.  
- Option to reverse blast damage, like pipe bombs.  
  
Reverse Friendly-Fire (l4d_reverse_ff)  
- Reverse friendly-fire weapon damage.  Attacker takes damage, victim does not.  
  
When these three plugins are combined, griefers will usually get frustrated and leave since they cannot damage anyone other than themselves.  
Although griefers will take significant damage, other players may not notice any difference in game play (except laughing at stupid griefer fails).  
  
  
Credits:  

This plugin began life as **[Explosion Announcer](https://forums.alliedmods.net/showthread.php?t=328006)** by Marttt.  The original plugin kept track of explodable entities, when they were exploded, and announced who did it. I hooked on to that announcement to track whether that explodable (gascan, fireworks, etc.) instantly burned any other players, and if so, to ensure the attacker took the vast majority of the damage. If no other players are instantly burned, then burn damage is treated normally.  
  
  
Want to contribute code enhancements?  
Create a pull request using this GitHub repository:  
https://github.com/Mystik-Spiral/l4d_ReverseBurn_and_ExplosionAnnouncer  
  
Plugin discussion: https://forums.alliedmods.net/showthread.php?t=331164  

*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D & L4D2] ReverseBurn and ExplosionAnnouncer"
#define PLUGIN_AUTHOR                 "Mystik Spiral"
#define PLUGIN_DESCRIPTION            "Reverses damage when victim burned instantly and continuously"
#define PLUGIN_VERSION                "1.2.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=331164"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_ReverseBurn_and_ExplosionAnnouncer"			//MS
#define TRANSLATION_FILENAME          "l4d_ReverseBurn_and_ExplosionAnnouncer.phrases"	//MS

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_WEAPON_GASCAN       "weapon_gascan"
#define CLASSNAME_PROP_FUEL_BARREL    "prop_fuel_barrel"

#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"
#define MODEL_FUEL_BARREL             "models/props_industrial/barrel_fuel.mdl"
#define MODEL_PROPANECANISTER         "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGENTANK              "models/props_equipment/oxygentank01.mdl"
#define MODEL_BARRICADE_GASCAN        "models/props_unique/wooden_barricade_gascans.mdl"
#define MODEL_GAS_PUMP                "models/props_equipment/gas_pump_nodebris.mdl"
#define MODEL_FIREWORKS_CRATE         "models/props_junk/explosive_box001.mdl"

#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define TYPE_NONE                     0
#define TYPE_GASCAN                   1
#define TYPE_FUEL_BARREL              2
#define TYPE_PROPANECANISTER          3
#define TYPE_OXYGENTANK               4
#define TYPE_BARRICADE_GASCAN         5
#define TYPE_GAS_PUMP                 6
#define TYPE_FIREWORKS_CRATE          7

#define MAX_TYPES                     7

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_SpamProtection;
static ConVar g_hCvar_SpamTypeCheck;
static ConVar g_hCvar_Team;
static ConVar g_hCvar_Self;
static ConVar g_hCvar_Gascan;
static ConVar g_hCvar_FuelBarrel;
static ConVar g_hCvar_PropaneCanister;
static ConVar g_hCvar_OxygenTank;
static ConVar g_hCvar_BarricadeGascan;
static ConVar g_hCvar_GasPump;
static ConVar g_hCvar_FireworksCrate;
static ConVar g_hCvar_PillsDecayRate;				//MS
static ConVar g_hCvar_BanBurnDisconnect;			//MS
static ConVar g_hCvar_BanDuration;					//MS
static ConVar g_hCvar_Admin;						//MS
static ConVar g_hCvar_Blast;						//MS

// ====================================================================================================
// Handles
// ====================================================================================================
Handle g_hBeginBurn[MAXPLAYERS + 1];				//MS
Handle g_hFinishBurn[MAXPLAYERS + 1];				//MS

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool g_bL4D2;
static bool g_bConfigLoaded;
static bool g_bEventsHooked;
static bool g_bCvar_Enabled;
static bool g_bCvar_SpamProtection;
static bool g_bCvar_SpamTypeCheck;
static bool g_bCvar_Team;
static bool g_bCvar_Self;
static bool g_bCvar_Gascan;
static bool g_bCvar_FuelBarrel;
static bool g_bCvar_PropaneCanister;
static bool g_bCvar_OxygenTank;
static bool g_bCvar_BarricadeGascan;
static bool g_bCvar_GasPump;
static bool g_bCvar_FireworksCrate;
static bool g_bCvar_BanBurnDisconnect;				//MS
static bool g_bFirstBurn[MAXPLAYERS + 1];			//MS
static bool g_bReverseBurnAtk[MAXPLAYERS + 1];		//MS
static bool g_bReverseBurnVic[MAXPLAYERS + 1];		//MS
static bool g_bBothRBPlugins;						//MS
static bool g_bAllReversePlugins;					//MS
static bool g_bReverseFFPlugin;						//MS
static bool g_bCvar_Admin;							//MS
static bool g_bCvar_Blast;							//MS

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int g_iModel_Gascan = -1;
static int g_iModel_FuelBarrel = -1;
static int g_iModel_PropaneCanister = -1;
static int g_iModel_OxygenTank = -1;
static int g_iModel_BarricadeGascan = -1;
static int g_iModel_GasPump = -1;
static int g_iModel_FireworksCrate = -1;
static int g_iCvar_Team;
static int g_iCvar_BanDuration;						//MS
static int g_iBurnVictim[MAXPLAYERS + 1];			//MS
static int g_iBurnToggle[MAXPLAYERS + 1];			//MS

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float g_fCvar_SpamProtection;
static float gc_fLastChatOccurrence[MAXPLAYERS+1][MAX_TYPES+1];
static float g_fLastRevBurnTime[MAXPLAYERS + 1];	//MS
static float g_fPillsDecayRate;						//MS
static float g_fLastBlastMsg[MAXPLAYERS + 1];		//MS

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static int ge_iType[MAXENTITIES+1];
static int ge_iLastAttacker[MAXENTITIES+1];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    LoadPluginTranslations();
    
    //MS (ConVar names)

    CreateConVar("RBaEA_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled            = CreateConVar("RBaEA_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Admin              = CreateConVar("RBaEA_admin", "0", "Reverse burn/blast when attacker is an admin.\n0 = Do not reverse burn/blast damage for admins, 1 = Reverse burn/blast damage for admins", CVAR_FLAGS, true, 0.0, true, 1.0);					//MS
    g_hCvar_Blast              = CreateConVar("RBaEA_blast", "1", "Reverse blast damage (propane/oxygen tank, gas pump).\n0 = Do not reverse blast damage, 1 = Reverse blast damage", CVAR_FLAGS, true, 0.0, true, 1.0);	//MS
    g_hCvar_BanBurnDisconnect  = CreateConVar("RBaEA_banburndisconnect", "1", "Ban attacker that disconnects during reverse burn.\n0 = Do not ban, 1 = Ban", CVAR_FLAGS, true, 0.0, true, 1.0);								//MS
    g_hCvar_BanDuration        = CreateConVar("RBaEA_banduration", "2880", "Ban duration in minutes. (0 = Permanent, Default 2880 = 2 days)", CVAR_FLAGS);																	//MS
    g_hCvar_SpamProtection     = CreateConVar("RBaEA_spam_protection", "3.0", "Delay in seconds to output to the chat the message from the same client again.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SpamTypeCheck      = CreateConVar("RBaEA_spam_type_check", "1", "Whether the plugin should apply chat spam protection by entity type.\nExample: \"gascans\" and \"propane canisters\" are of different types.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Team               = CreateConVar("RBaEA_team", "1", "Which teams should the message be transmitted to.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_Self               = CreateConVar("RBaEA_self", "1", "Should the message be transmitted to those who exploded it.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Gascan             = CreateConVar("RBaEA_gascan", "1", "Output to the chat every time someone explodes (last hit) a gascan.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_FuelBarrel         = CreateConVar("RBaEA_fuelbarrel", "1", "Output to the chat every time someone explodes (last hit) a fuel barrel.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PropaneCanister    = CreateConVar("RBaEA_propanecanister", "1", "Output to the chat every time someone explodes (last hit) a propane canister.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_OxygenTank         = CreateConVar("RBaEA_oxygentank", "1", "Output to the chat every time someone explodes (last hit) a oxygen tank.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BarricadeGascan    = CreateConVar("RBaEA_barricadegascan", "1", "Output to the chat every time someone explodes (last hit) a barricade with gascans.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GasPump            = CreateConVar("RBaEA_gaspump", "1", "Output to the chat every time someone explodes (last hit) a gas pump.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    if (g_bL4D2)
        g_hCvar_FireworksCrate = CreateConVar("RBaEA_fireworkscrate", "1", "Output to the chat every time someone explodes (last hit) a fireworks crate.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        
    g_hCvar_PillsDecayRate = FindConVar("pain_pills_decay_rate");	//MS
    
    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Admin.AddChangeHook(Event_ConVarChanged);				//MS
    g_hCvar_Blast.AddChangeHook(Event_ConVarChanged);				//MS
    g_hCvar_BanBurnDisconnect.AddChangeHook(Event_ConVarChanged);	//MS
    g_hCvar_BanDuration.AddChangeHook(Event_ConVarChanged);			//MS
    g_hCvar_SpamProtection.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpamTypeCheck.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Self.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Gascan.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FuelBarrel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PropaneCanister.AddChangeHook(Event_ConVarChanged);
    g_hCvar_OxygenTank.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BarricadeGascan.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GasPump.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
        g_hCvar_FireworksCrate.AddChangeHook(Event_ConVarChanged);
        
    g_hCvar_PillsDecayRate.AddChangeHook(Event_ConVarChanged);		//MS

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);
    
    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_explosion_announcer", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

public void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iModel_Gascan = PrecacheModel(MODEL_GASCAN, true);
    g_iModel_FuelBarrel = PrecacheModel(MODEL_FUEL_BARREL, true);
    g_iModel_PropaneCanister = PrecacheModel(MODEL_PROPANECANISTER, true);
    g_iModel_OxygenTank = PrecacheModel(MODEL_OXYGENTANK, true);
    g_iModel_BarricadeGascan = PrecacheModel(MODEL_BARRICADE_GASCAN, true);
    g_iModel_GasPump = PrecacheModel(MODEL_GAS_PUMP, true);
    if (g_bL4D2)
        g_iModel_FireworksCrate = PrecacheModel(MODEL_FIREWORKS_CRATE, true);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void Event_ConVarChanged(Handle convar, const char[] sOldValue, const char[] sNewValue)
{
    GetCvars();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_SpamProtection = g_hCvar_SpamProtection.FloatValue;
    g_bCvar_SpamProtection = (g_fCvar_SpamProtection > 0.0);
    g_bCvar_SpamTypeCheck = g_hCvar_SpamTypeCheck.BoolValue;
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_bCvar_Team = (g_iCvar_Team > 0);
    g_bCvar_Self = g_hCvar_Self.BoolValue;
    g_bCvar_Gascan = g_hCvar_Gascan.BoolValue;
    g_bCvar_FuelBarrel = g_hCvar_FuelBarrel.BoolValue;
    g_bCvar_PropaneCanister = g_hCvar_PropaneCanister.BoolValue;
    g_bCvar_OxygenTank = g_hCvar_OxygenTank.BoolValue;
    g_bCvar_BarricadeGascan = g_hCvar_BarricadeGascan.BoolValue;
    g_bCvar_GasPump = g_hCvar_GasPump.BoolValue;
    if (g_bL4D2)
        g_bCvar_FireworksCrate = g_hCvar_FireworksCrate.BoolValue;
    g_fPillsDecayRate = g_hCvar_PillsDecayRate.FloatValue;				//MS
    g_bCvar_Admin = g_hCvar_Admin.BoolValue;							//MS
    g_bCvar_Blast = g_hCvar_Blast.BoolValue;							//MS
    g_bCvar_BanBurnDisconnect = g_hCvar_BanBurnDisconnect.BoolValue;	//MS
    g_iCvar_BanDuration = g_hCvar_BanDuration.IntValue;					//MS
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("break_prop", Event_BreakProp);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("break_prop", Event_BreakProp);

        return;
    }
}

/****************************************************************************************************/

public void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_Enabled)
        return;

    if (!g_bCvar_Team)
        return;

    int entity = event.GetInt("entindex");

    int type = ge_iType[entity];

    if (type == TYPE_NONE)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        client = GetClientOfUserId(ge_iLastAttacker[entity]);

    if (!IsValidClient(client))
        return;

    OutputMessage(client, type);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
	for (int type = TYPE_NONE; type <= MAX_TYPES; type++)
	{
		gc_fLastChatOccurrence[client][type] = 0.0;
	}
	
	if (g_bReverseBurnAtk[client] && g_bCvar_BanBurnDisconnect)										//MS
	{																								//MS
		//ban attacker for disconnecting during reverse burn										//MS
		char BanMsg[50];																			//MS
		Format(BanMsg, sizeof(BanMsg), "%t", "BurnGriefer", client);								//MS
		BanClient(client, g_iCvar_BanDuration, BANFLAG_AUTO, "BurnGriefer", BanMsg, _, client);		//MS
	}																								//MS
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    if (g_bL4D2)
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, CLASSNAME_WEAPON_GASCAN)) != INVALID_ENT_REFERENCE)
        {
            SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
            HookSingleEntityOutput(entity, "OnKilled", OnKilled, true);
        }
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_PROP_FUEL_BARREL)) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_physics*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }
    
    for (int client = 1; client <= MaxClients; client++)	//MS
	{														//MS
		if (IsClientInGame(client))							//MS
			OnClientPutInServer(client);					//MS
	}														//MS
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    OnSpawnPost(entity);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    ge_iType[entity] = TYPE_NONE;
    ge_iLastAttacker[entity] = 0;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    switch (classname[0])
    {
        case 'w':
        {
            if (!g_bL4D2)
                return;

            if (StrEqual(classname, CLASSNAME_WEAPON_GASCAN))
            {
                ge_iType[entity] = TYPE_GASCAN;
                SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
                HookSingleEntityOutput(entity, "OnKilled", OnKilled, true);
                return;
            }
        }
        case 'p':
        {
            if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            {
                SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
                return;
            }
        }
    }
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    int modelIndex = GetEntProp(entity, Prop_Send, "m_nModelIndex");

    if (modelIndex == g_iModel_Gascan)
    {
        ge_iType[entity] = TYPE_GASCAN;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_FuelBarrel)
    {
        ge_iType[entity] = TYPE_FUEL_BARREL;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_PropaneCanister)
    {
        ge_iType[entity] = TYPE_PROPANECANISTER;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_OxygenTank)
    {
        ge_iType[entity] = TYPE_OXYGENTANK;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_BarricadeGascan)
    {
        ge_iType[entity] = TYPE_BARRICADE_GASCAN;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_GasPump)
    {
        ge_iType[entity] = TYPE_GAS_PUMP;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (!g_bL4D2)
        return;

    if (modelIndex == g_iModel_FireworksCrate)
    {
        ge_iType[entity] = TYPE_FIREWORKS_CRATE;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (IsValidClient(attacker))
        ge_iLastAttacker[victim] = GetClientUserId(attacker);

    return Plugin_Continue;
}

/****************************************************************************************************/

public void OnKilled(const char[] output, int caller, int activator, float delay)
{
	if (!g_bCvar_Enabled)
		return;

	if (!g_bCvar_Team)
		return;

	int type = ge_iType[caller];

	if (type == TYPE_NONE)
		return;

	if (IsValidClient(activator))
		ge_iLastAttacker[caller] = GetClientUserId(activator);

	if (ge_iLastAttacker[caller] == 0)
		return;

	int client = GetClientOfUserId(ge_iLastAttacker[caller]);

	if (!IsValidClient(client))
		return;

	OutputMessage(client, type);
}

/****************************************************************************************************/

public void OutputMessage(int attacker, int type)
{
    if ((!g_bFirstBurn[attacker]) && !(type == TYPE_PROPANECANISTER || type == TYPE_OXYGENTANK))	//MS
    {																								//MS
        g_bFirstBurn[attacker] = true;																//MS
        g_hBeginBurn[attacker] = CreateTimer(0.75, BeginBurnTimer, attacker);						//MS
    }																								//MS
	
    if (g_bCvar_SpamProtection)
    {
        if (g_bCvar_SpamTypeCheck)
        {
            if (GetGameTime() - gc_fLastChatOccurrence[attacker][type] < g_fCvar_SpamProtection)
                return;

            gc_fLastChatOccurrence[attacker][type] = GetGameTime();
        }
        else
        {
            if (GetGameTime() - gc_fLastChatOccurrence[attacker][TYPE_NONE] < g_fCvar_SpamProtection)
                return;

            gc_fLastChatOccurrence[attacker][TYPE_NONE] = GetGameTime();
        }
    }

    switch (type)
    {
        case TYPE_GASCAN:
        {
            if (!g_bCvar_Gascan)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (attacker == client)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                CPrintToChat(client, "%T", "Exploded a gascan", client, attacker);
            }
        }

        case TYPE_FUEL_BARREL:
        {
            if (!g_bCvar_FuelBarrel)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (attacker == client)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                CPrintToChat(client, "%T", "Exploded a fuel barrel", client, attacker);
            }
        }

        case TYPE_PROPANECANISTER:
        {
            if (!g_bCvar_PropaneCanister)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (attacker == client)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                CPrintToChat(client, "%T", "Exploded a propane canister", client, attacker);
            }
        }

        case TYPE_OXYGENTANK:
        {
            if (!g_bCvar_OxygenTank)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (attacker == client)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                CPrintToChat(client, "%T", "Exploded an oxygen tank", client, attacker);
            }
        }

        case TYPE_BARRICADE_GASCAN:
        {
            if (!g_bCvar_BarricadeGascan)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (attacker == client)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                CPrintToChat(client, "%T", "Exploded a barricade with gascans", client, attacker);
            }
        }

        case TYPE_GAS_PUMP:
        {
            if (!g_bCvar_GasPump)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (attacker == client)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                CPrintToChat(client, "%T", "Exploded a gas pump", client, attacker);
            }
        }

        case TYPE_FIREWORKS_CRATE:
        {
            if (!g_bCvar_FireworksCrate)
                return;

            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                if (attacker == client)
                {
                    if (!g_bCvar_Self)
                        continue;
                }
                else
                {
                    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
                        continue;
                }

                CPrintToChat(client, "%T", "Exploded a fireworks crate", client, attacker);
            }
        }
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_explosion_announcer) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_explosion_announcer_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_explosion_announcer_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_spam_protection : %.2f (%s)", g_fCvar_SpamProtection, g_bCvar_SpamProtection ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_spam_type_check : %b (%s)", g_bCvar_SpamTypeCheck, g_bCvar_SpamTypeCheck ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_team : %i (%s)", g_iCvar_Team, g_bCvar_Team ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_self : %b (%s)", g_bCvar_Self, g_bCvar_Self ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_gascan : %b (%s)", g_bCvar_Gascan, g_bCvar_Gascan ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_fuelbarrel : %b (%s)", g_bCvar_FuelBarrel, g_bCvar_FuelBarrel ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_propanecanister : %b (%s)", g_bCvar_PropaneCanister, g_bCvar_PropaneCanister ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_oxygentank : %b (%s)", g_bCvar_OxygenTank, g_bCvar_OxygenTank ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_barricadegascan : %b (%s)", g_bCvar_BarricadeGascan, g_bCvar_BarricadeGascan ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_gaspump : %b (%s)", g_bCvar_GasPump, g_bCvar_GasPump ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_explosion_announcer_fireworkscrate : %b (%s)", g_bCvar_FireworksCrate, g_bCvar_FireworksCrate ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Validates if is a valid entity index (between MaxClients+1 and 2048).
 *
 * @param entity        Entity index.
 * @return              True if entity index is valid, false otherwise.
 */
bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}

/****************************************************************************************************/

/**
 * Returns the team flag from a team.
 *
 * @param team          Team index.
 * @return              Team flag.
 */
int GetTeamFlag(int team)
{
    switch (team)
    {
        case TEAM_SURVIVOR:
            return FLAG_TEAM_SURVIVOR;
        case TEAM_INFECTED:
            return FLAG_TEAM_INFECTED;
        case TEAM_SPECTATOR:
            return FLAG_TEAM_SPECTATOR;
        case TEAM_HOLDOUT:
            return FLAG_TEAM_HOLDOUT;
        default:
            return FLAG_TEAM_NONE;
    }
}

// ====================================================================================================
// colors.inc replacement (Thanks to Silvers)
// ====================================================================================================
/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 * @return              No return.
 *
 * On error/Errors:     If the client is not connected an error will be thrown.
 */
public void CPrintToChat(int client, char[] message, any ...)
{
    static char buffer[512];
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{white}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "\x04");
    ReplaceString(buffer, sizeof(buffer), "{green}", "\x04"); // Actually orange in L4D1/L4D2, but replicating colors.inc behaviour
    ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");

    PrintToChat(client, buffer);
}

/****************************************************************************************************/
// Reverse Burn additional functions by Mystik Spiral
/****************************************************************************************************/

public void OnAllPluginsLoaded()
{
	if (FindConVar("l4d_explosion_announcer_version") != null)
	{
		SetFailState("The \"l4d_ReverseBurn_and_ExplosionAnnouncer\" plugin cannot be used with the \"l4d_explosion_announcer\" plugin, use only one of these plugins, not both");
	}
	if (FindConVar("RBaTA_version") != null)
	{
		g_bBothRBPlugins = true;
		if (FindConVar("reverseff_version"))
		{
			g_bAllReversePlugins = true;
		}
	}
	if (FindConVar("reverseff_version"))
	{
		g_bReverseFFPlugin = true;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_Player);
}

public Action OnTakeDamage_Player(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	//check valid victim and attacker and not self damage
	if (IsValidClientAndInGameAndSurvivor(victim) && IsValidClientAndInGameAndSurvivor(attacker) && victim != attacker)
	{
		//PrintToServer("PlyrDmg - Vic: %i %N, Atk: %i %N, FrstBurn: %b, RvsBurnAtk: %b, RvsBurnVic: %b, Dmg: %f", victim, victim, attacker, attacker, g_bFirstBurn[attacker], g_bReverseBurnAtk[attacker], g_bReverseBurnVic[victim], damage);
		//check for burn damage
		if (damagetype & DMG_BURN)
		{
			//check if burnable ignited in the last 0.75 seconds by the current attacker
			if (g_bFirstBurn[attacker])
			{
				//set burn victim id to the attacker id
				g_iBurnVictim[victim] = attacker;
				//no damage dealt during first 0.75 seconds of burn
				return Plugin_Handled;
			}
			float fGameTime = GetGameTime();
			//was victim damage last reversed more than a second ago
			if ((fGameTime - g_fLastRevBurnTime[victim] > 1.0) && (g_fLastRevBurnTime[victim] != 0))
			{
				//if victim not burned in last second then handle normal, not reversed
				g_bReverseBurnVic[victim] = false;
			}
			if ((IsClientAdmin(attacker) && !g_bCvar_Admin) || (IsIncendiaryAmmo(weapon, attacker, inflictor, damagetype) && g_bReverseFFPlugin))
			{
				//if attacker is admin and RBaEA_admin set to false, or...
				//if weapon is using incendiary ammo and ReverseFF plugin is loaded, do not reverse burn
				g_bReverseBurnAtk[attacker] = false;
			}
			//probably not needed, but if human attacker disconnects, do not burn bot that takes over
			if  (IsFakeClient(attacker))
			{
				return Plugin_Handled;
			}
			//if both attacker and victim reverse burn flags are true then reverse burn
			if (g_bReverseBurnAtk[attacker] && g_bReverseBurnVic[victim])
			{
				//set the percent amount of damage for attacker and victim
				float fAttackerDamage = damage * 0.7;
				int iVictimPermHealth = GetClientHealth(victim);
				int iVictimTempHealth = GetClientTempHealth(victim);
				int iVictimTotalHealth = iVictimPermHealth + iVictimTempHealth;
				//PrintToServer("Vic: %N, Perm: %i, Temp: %i, Totl: %i", victim, iVictimPermHealth, iVictimTempHealth, iVictimTotalHealth);
				//do not burn victim if incapped or with only 1 health
				if ((IsClientIncapped(victim)) || (iVictimTotalHealth < 2))
				{
					SDKHooks_TakeDamage(victim, inflictor, attacker, 0.0, damagetype, weapon, damageForce, damagePosition);
					SDKHooks_TakeDamage(attacker, inflictor, attacker, fAttackerDamage, damagetype, weapon, damageForce, damagePosition);
					g_fLastRevBurnTime[victim] = GetGameTime();
					return Plugin_Handled;
				}
				//give standing bot victim 1 health then burn them for 1 health so they move out of fire
				if  (IsFakeClient(victim))
				{
					SetEntityHealth(victim, iVictimPermHealth + 1);
					SDKHooks_TakeDamage(victim, inflictor, attacker, 1.0, damagetype, weapon, damageForce, damagePosition);
					SDKHooks_TakeDamage(attacker, inflictor, attacker, fAttackerDamage, damagetype, weapon, damageForce, damagePosition);
					g_fLastRevBurnTime[victim] = GetGameTime();
					return Plugin_Handled;
				}
				//inflict actual damage to burn victim only once every four calls from OnTakeDamage
				if (g_iBurnToggle[victim] < 1)
				{
					//as incentive for standing victims to get out of the fire quickly...
					//if >1 PermHP remove 1PermHP and add 2TempHP, otherwise if >1 TempHP remove 1TempHP
					if (iVictimPermHealth > 1)
					{
						SetEntityHealth(victim, iVictimPermHealth - 1);
						if (iVictimPermHealth < 99 && iVictimTempHealth < 99 && iVictimTotalHealth < 100)
						{
							SetClientTempHealth(victim, iVictimTempHealth + 2);
						}
						else
						{
							SetClientTempHealth(victim, iVictimTempHealth + 1);
						}
					}
					else if (iVictimTempHealth > 1)
					{
						SetClientTempHealth(victim, iVictimTempHealth - 1);
					}
					SDKHooks_TakeDamage(victim, inflictor, attacker, 0.0, damagetype, weapon, damageForce, damagePosition);
					SDKHooks_TakeDamage(attacker, inflictor, attacker, fAttackerDamage, damagetype, weapon, damageForce, damagePosition);
					g_fLastRevBurnTime[victim] = GetGameTime();
				}
				g_iBurnToggle[victim] += 1;
				if (g_iBurnToggle[victim] > 3)
				{
					g_iBurnToggle[victim] = 0;
				}
				return Plugin_Handled;
			}
			if (IsFakeClient(victim))
			{
				//even if burn damage is not being reversed do not burn stupid bots
				//give bots 1 health then damage them for 1 health so they move out of fire
				int iVictimPermHealth = GetClientHealth(victim);
				SetEntityHealth(victim, iVictimPermHealth + 1);
				SDKHooks_TakeDamage(victim, inflictor, attacker, 1.0, damagetype, weapon, damageForce, damagePosition);
				return Plugin_Handled;
			}
		}
		//if damage is of type blast (explosion)
		if (damagetype & DMG_BLAST && g_bCvar_Blast)
		{
			char sInflictorClass[64];
			if (inflictor > MaxClients)
			{
				GetEdictClassname(inflictor, sInflictorClass, sizeof(sInflictorClass));
			}
			//is weapon grenade launcher
			bool bWeaponGL = IsWeaponGrenadeLauncher(sInflictorClass);
			//PrintToServer("Blast - Vic: %N, Atk: %N, Inf: %s", victim, attacker, inflictor);
			if ((IsClientAdmin(attacker) && !g_bCvar_Admin) || (bWeaponGL && g_bReverseFFPlugin) || (IsExplosiveAmmo(weapon, attacker, inflictor, damagetype) && g_bReverseFFPlugin))
			{
				//if attacker is admin and RBaEA_admin is false, or...
				//if weapon is grenade launcher and ReverseFF plugin is loaded, or...
				//if weapon is using explosive ammo and ReverseFF plugin is loaded, do not reverse explosion damage
				return Plugin_Handled;
			}
			//reverse blast damage
			SDKHooks_TakeDamage(attacker, inflictor, victim, damage, damagetype, weapon, damageForce, damagePosition);
			//prevent spamming reverse blast messages...one message max every quarter second
			if ((g_fLastBlastMsg[attacker] == 0) || (GetGameTime() - g_fLastBlastMsg[attacker] > 0.25))
			{
				CPrintToChat(attacker, "%T", "ReverseBlast", attacker);
				g_fLastBlastMsg[attacker] = GetGameTime();
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action BeginBurnTimer(Handle timer, int client)
{
	//loop through all clients to see if OnTakeDamage_Player function marked any burn victims in the first second
	for (int iVictim = 1; iVictim <= MaxClients; iVictim++)
	{
		//if victim was burned in the first second the value is the attacker
		if (g_iBurnVictim[iVictim] > 0)
		{
			int iAttacker = g_iBurnVictim[iVictim];
			//turn on reverse burn flags for the attacker and victim
			g_bReverseBurnAtk[iAttacker] = true;
			g_bReverseBurnVic[iVictim] = true;
			//pack both the attacker and victim so it can be passed to FinishBurnTimer
			DataPack pack;
			g_hFinishBurn[iAttacker] = CreateDataTimer(15.25, FinishBurnTimer, pack);
			pack.WriteCell(iAttacker);
			pack.WriteCell(iVictim);
			//clear the burn victim set by OnTakeDamage_Player
			g_iBurnVictim[iVictim] = 0;
			//clear the time burn damage was last reversed for victim
			g_fLastRevBurnTime[iVictim] = 0.0;
		}
	}
	//clear flag that indicates first 0.75 seconds of burnable being ignited
	g_bFirstBurn[client] = false;
	//clear handle for this timer
	g_hBeginBurn[client] = null;
}

public Action FinishBurnTimer(Handle timer, DataPack pack)
{
	int iAttacker;
	int iVictim;
	pack.Reset();
	iAttacker = pack.ReadCell();
	iVictim = pack.ReadCell();
	//to prevent message spam wait until fire is out to display message to attacker
	if (IsValidClientAndInGameAndSurvivor(iAttacker) && g_bReverseBurnAtk[iAttacker])
	{
		if (IsValidClientAndInGameAndSurvivor(iVictim))
		{
			if (g_bBothRBPlugins)
			{
				char sPluginName[13] = "[ReverseBurn]";
				CPrintToChat(iAttacker, "%T", "BurnVictimName", iAttacker, sPluginName, iVictim);
			}
			else
			{
				char sPluginName[7] = "[RBaEA]";
				CPrintToChat(iAttacker, "%T", "BurnVictimName", iAttacker, sPluginName, iVictim);
			}
		}
		else
		{
			if (g_bBothRBPlugins)
			{
				char sPluginName[13] = "[ReverseBurn]";
				CPrintToChat(iAttacker, "%T", "BurnTeammate", iAttacker, sPluginName);
			}
			else
			{
				char sPluginName[7] = "[RBaEA]";
				CPrintToChat(iAttacker, "%T", "BurnTeammate", iAttacker, sPluginName);
			}
		}
	}
	//fire is out so clear reverse burn flags for attacker and victim and clear timer handle
	g_bReverseBurnAtk[iAttacker] = false;
	g_bReverseBurnVic[iVictim] = false;
	g_hFinishBurn[iAttacker] = null;
}

stock bool IsValidClientAndInGameAndSurvivor(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsClientIncapped(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}

int GetClientTempHealth(int client)
{
	int iTempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fPillsDecayRate));
	return iTempHealth < 0 ? 0 : iTempHealth;
}

public void SetClientTempHealth(int client, int iTempHealth)
{
	float fTempHealth = iTempHealth * 1.0;
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fTempHealth);
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(16.0, AnnouncePlugin, client);
}

public Action AnnouncePlugin(Handle timer, int client)
{
	//if all 3 plugins loaded, do not announce anything (announced in l4d_reverse_ff)
	//if both ReverseBurn plugins loaded, announce burn damage
	//if only RBaEA loaded, announce only explodable burn damage
	if (IsClientInGame(client) && g_bCvar_Enabled)
	{
		if (g_bBothRBPlugins && !g_bAllReversePlugins)
		{
			CPrintToChat(client, "%T", "AnnounceBoth", client);
		}
		else if (!g_bAllReversePlugins)
		{
			CPrintToChat(client, "%T", "Announce", client);
		}
	}
}

stock bool IsClientAdmin(int client)
{
    return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}

stock bool IsWeaponGrenadeLauncher(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "grenade_launcher_projectile"));
}

stock bool IsExplosiveAmmo(int weapon, int attacker, int inflictor, int damagetype)
{
	//damage from gun with explosive ammo
	if ((weapon > 0 && attacker == inflictor) && (damagetype & DMG_BLAST))
	{
		return true;
	}
	return false;
}

stock bool IsIncendiaryAmmo(int weapon, int attacker, int inflictor, int damagetype)
{
	//damage from gun with incendiary ammo
	if ((weapon > 0 && attacker == inflictor) && (damagetype & DMG_BURN))
	{
		return true;
	}
	return false;
}

/****************************************************************************************************/
