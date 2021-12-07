/**
 * vim: set ai et ts=4 sw=4 :
 * File: amp_node.sp
 * Description: Combination of The Amplifier and The Repair Node!
 * Author: -=|JFH|=-Naris (Murray Wilson)
 * Amplifier Author: Eggman
 * Repair Node Authors: Geel9, Murphy7 and Benjamuffin
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define MAXENTITIES 2048

#define PLUGIN_VERSION "4.3"

#define DispenserModel  "models/buildables/dispenser"
#define DispenserModel2 "models/buildables/dispenser_lvl"

#define RepairNodeModel "models/buildables/repair_level"

#define AmplifierModel  "models/buildables/amplifier_test/amplifier"
#define AmplifierTex    "materials/models/buildables/amplifier_test/amplifier"
#define AMPgib          "models/buildables/amplifier_test/gibs/amp_gib"

#define BeamModel       "materials/sprites/laser.vmt"
#define HaloModel       "materials/sprites/halo01.vmt"

new g_BeamSprite;
new g_HaloSprite;

new bool:DontAsk[MAXPLAYERS+1]       = { false, ... };
new bool:NearAmplifier[MAXPLAYERS+1] = { false, ... };
new EngiAssists[MAXPLAYERS+1]        = { 0, ... };
new Revenges[MAXPLAYERS+1]           = { 0, ... };				//for Engineers with Frontier Justice
new GetPar[MAXPLAYERS+1]             = { INVALID_ENT_REFERENCE, ... };

new Handle:cvarAmplifierUpgradable = INVALID_HANDLE;
new Handle:cvarAmplifierEnabled = INVALID_HANDLE;
new Handle:cvarAmplifierPercent = INVALID_HANDLE;
new Handle:cvarAmplifierRange[4] = { INVALID_HANDLE, ... };
new Handle:cvarAmplifierMetal = INVALID_HANDLE;
new Handle:cvarRegeneration = INVALID_HANDLE;
new Handle:cvarSpawnMenu = INVALID_HANDLE;
new Handle:cvarCondition = INVALID_HANDLE;
new Handle:cvarMetalMax = INVALID_HANDLE;
new Handle:cvarParticle = INVALID_HANDLE;
new Handle:cvarWallBlock = INVALID_HANDLE;
new Handle:cvarMiniCritToSG = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;

new Handle:cvarRepairNodeEnabled = INVALID_HANDLE;
new Handle:cvarRepairNodePercent = INVALID_HANDLE;
new Handle:cvarRepairNodeRockets = INVALID_HANDLE;
new Handle:cvarRepairNodeRange[4] = { INVALID_HANDLE, ... };
new Handle:cvarRepairNodeRegen[4] = { INVALID_HANDLE, ... };
new Handle:cvarRepairNodeShells[4] = { INVALID_HANDLE, ... };
new Handle:cvarRepairNodeMetal = INVALID_HANDLE;
new Handle:cvarTeam = INVALID_HANDLE;
new Handle:cvarMini = INVALID_HANDLE;

new Handle:fwdOnAmplify = INVALID_HANDLE;

new bool:SpawnMenu = false;
new bool:AmplifierEnabled = true;
new bool:AmplifierUpgradable = true;
new bool:RepairNodeEnabled = true;
new DefaultRockets = 2;
new DefaultRegen[4] = { 0, 15, 20, 30 };
new DefaultShells[4] = { 0, 0, 5, 10 };
new TFCond:DefaultCondition = TFCond_Kritzkrieged;
new Float:DefaultAmplifierRange[4] = { 0.0, 100.0, 200.0, 300.0 };
new Float:DefaultRepairNodeRange[4] = { 0.0, 300.0, 400.0, 500.0 };
new bool:RepairNodeMetal = true;
new bool:DefaultTeam = false;
new bool:DefaultMini = false;
new bool:ShowParticle = true;
new bool:MiniCritToSG = true;
new bool:WallBlock = false;
new RepairNodePercent = 100;
new AmplifierPercent = 100;
new AmplifierMetal = 5;

new MetalRegeneration = 10;
new MetalMax = 400;

new bool:NativeControl = false;
new bool:NativeAmplifier[MAXPLAYERS+1];
new bool:NativeRepairNode[MAXPLAYERS+1];
new TFCond:NativeCondition[MAXPLAYERS+1];
new Float:NativeAmplifierRange[MAXPLAYERS+1][4];
new Float:NativeRepairNodeRange[MAXPLAYERS+1][4];
new NativeRepairNodePercent[MAXPLAYERS+1];
new NativeAmplifierPercent[MAXPLAYERS+1];
new NativeRegen[MAXPLAYERS+1][4];
new NativeShells[MAXPLAYERS+1][4];
new NativeRockets[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "amp_node",
	author = "-=|JFH|=-Naris, Eggman, Geel9, Murphy7 and Benjamuffin ",
	description = "Allows players to build The Amplifier and The Repair Node",
	version = PLUGIN_VERSION,
};

/**
 * Colored Chat Functions
 */
#tryinclude <colors>

/**
 * Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included

    #define TF2_IsPlayerDisguised(%1) TF2_IsPlayerInCondition(%1,TFCond_Disguised)
    #define TF2_IsPlayerCloaked(%1)   TF2_IsPlayerInCondition(%1,TFCond_Cloaked)

#endif

/**
 * Functions to return infomation about TF2 objects.
 */
#tryinclude <tf2_objects>
#if !defined _tf2_objects_included
    enum TFExtObjectType
    {
        TFExtObject_Unknown = -1,
        TFExtObject_CartDispenser = 0,
        TFExtObject_Dispenser = 0,
        TFExtObject_Teleporter = 1,
        TFExtObject_Sentry = 2,
        TFExtObject_Sapper = 3,
        TFExtObject_TeleporterEntry,
        TFExtObject_TeleporterExit,
        TFExtObject_MiniSentry,
        TFExtObject_Amplifier,
        TFExtObject_RepairNode
    };

    stock const String:TF2_ObjectClassNames[TFExtObjectType][] =
    {
        "obj_dispenser",
        "obj_teleporter",
        "obj_sentrygun",
        "obj_sapper",
        "obj_teleporter", // _entrance
        "obj_teleporter", // _exit
        "obj_sentrygun",  // minisentry
        "obj_dispenser",  // amplifier
        "obj_dispenser"   // repair_node
    };

    stock const String:TF2_ObjectNames[TFExtObjectType][] =
    {
        "Dispenser",
        "Teleporter",
        "Sentry Gun",
        "Sapper",
        "Teleporter Entrance",
        "Teleporter Exit",
        "Mini Sentry Gun",
        "Amplifier",
        "Repair Node"
    };

    // Max Sentry Ammo for Level:         mini,   1,   2,   3, max
    stock const TF2_MaxSentryShells[]  = { 150, 100, 120, 144, 255 };
    stock const TF2_MaxSentryRockets[] = {   0,   0,   0,  20,  64 };
#endif

/**
 * Description: Manage precaching resources.
 */
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
    stock SetupModel(const String:model[], &index=0, bool:download=false,
                     bool:precache=false, bool:preload=false)
    {
        if (download && FileExists(model))
            AddFileToDownloadsTable(model);

        if (precache)
            index = PrecacheModel(model,preload);
        else
            index = 0;
    }

    stock PrepareModel(const String:model[], &index=0, bool:preload=true)
    {
        if (index <= 0)
            index = PrecacheModel(model,preload);

        return index;
    }
#endif

new TFExtObjectType:BuildingType[MAXENTITIES] = { TFExtObject_Unknown, ... };
new Float:BuildingRange[MAXENTITIES][4];
new bool:BuildingOn[MAXENTITIES]=false;
new BuildingPercent[MAXENTITIES];
new BuildingRef[MAXENTITIES]                  = { INVALID_ENT_REFERENCE, ... };

new bool:ConditionApplied[MAXENTITIES][MAXPLAYERS+1];
new TFCond:AmplifierCondition[MAXENTITIES];

new RepairNodeProp[MAXENTITIES]               = { INVALID_ENT_REFERENCE, ... };
new RepairNodeTarget[MAXENTITIES]             = { INVALID_ENT_REFERENCE, ... };
new RepairNodeRockets[MAXENTITIES];
new RepairNodeRegen[MAXENTITIES][4];
new RepairNodeShells[MAXENTITIES][4];
new RepairNodeParticle[MAXENTITIES][2];
new bool:RepairNodeTeam[MAXENTITIES];
new bool:RepairNodeMini[MAXENTITIES];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Natives
	CreateNative("ControlAmpNode",Native_ControlAmpNode);
	CreateNative("SetBuildingType",Native_SetBuildingType);
	CreateNative("SetAmplifier",Native_SetAmplifier);
	CreateNative("SetRepairNode",Native_SetRepairNode);
	CreateNative("CountConvertedBuildings",Native_CountConvertedBuildings);
	CreateNative("ConvertToAmplifier",Native_ConvertToAmplifier);
	CreateNative("ConvertToRepairNode",Native_ConvertToRepairNode);

	fwdOnAmplify=CreateGlobalForward("OnAmplify",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

	RegPluginLibrary("amp_node");
	return APLRes_Success;
}

public OnPluginStart()
{
    // Initialize RepairNodeParticle[][] array
    for (new i= 0; i < sizeof(RepairNodeParticle); i++)
    {
        for (new j = 0; j < sizeof(RepairNodeParticle[]); j++)
            RepairNodeParticle[i][j] = INVALID_ENT_REFERENCE;
    }

    CreateConVar("ampnode_version", PLUGIN_VERSION, "The Amplifier Version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

    cvarAnnounce = CreateConVar("ampnode_announce", "1", "Announce usage instructions (1=yes,0=no)");
    cvarSpawnMenu = CreateConVar("ampnode_spawn_menu", "0", "Display selection menu when engineers spawn?", FCVAR_PLUGIN);
    cvarRegeneration = CreateConVar("ampnode_regeneration", "10.0", "Amount of metal to regenerate per second.", FCVAR_PLUGIN);
    cvarMetalMax = CreateConVar("ampnode_max", "400.0", "Maximum amount of metal an amplifier or repair node can hold.", FCVAR_PLUGIN);

    cvarAmplifierEnabled = CreateConVar("amplifier_enable", "1", "Enable the amplifier? (1=yes,0=no)", FCVAR_NOTIFY);
    cvarAmplifierPercent = CreateConVar("amplifier_percent", "100.0", "Percent chance of the amplifier applying the condition.", FCVAR_PLUGIN, true, 0.0, true, 100.0);
    cvarParticle = CreateConVar("amplifier_particle", "1", "Enable the Buffed Particle? (1=yes,0=no)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvarMiniCritToSG = CreateConVar("amplifier_sg_wrangler_mini_crit", "1", "Controlled (by Wrangler) SentryGun will get mini-crits, if engineer near AMP", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvarAmplifierUpgradable = CreateConVar("amplifier_upgradable", "1", "Allow the amplifier to be upgraded? (1=yes,0=no)", FCVAR_NOTIFY);
    cvarWallBlock = CreateConVar("amplifier_wallblock", "0", "Teammates can (0) or can not (1) get crits through walls, players, props etc", FCVAR_PLUGIN, true, 0.0, true, 1.0);

    cvarCondition = CreateConVar("amplifier_condition", "16", "Condition that The amplifier dispenses (11=full crits, 16=mini crits, etc...).", FCVAR_PLUGIN);
    cvarAmplifierRange[1] = CreateConVar("amplifier_range_1", "100.0", "Distance the amplifier works at level 1.", FCVAR_PLUGIN);
    cvarAmplifierRange[2] = CreateConVar("amplifier_range_2", "200.0", "Distance the amplifier works at level 2.", FCVAR_PLUGIN);
    cvarAmplifierRange[3] = CreateConVar("amplifier_range_3", "300.0", "Distance the amplifier works at level 3.", FCVAR_PLUGIN);
    cvarAmplifierMetal = CreateConVar("amplifier_metal", "5.0", "Amount of metal to use to apply a condition to a player (per second).", FCVAR_PLUGIN);

    cvarRepairNodeEnabled = CreateConVar("repair_node_enable", "1", "Enable the repair node? (1=yes,0=no)", FCVAR_NOTIFY);
    cvarRepairNodePercent = CreateConVar("repair_node_percent", "100.0", "Percent chance of the repair node repairing something.", FCVAR_PLUGIN, true, 0.0, true, 100.0);
    cvarRepairNodeMetal = CreateConVar("repair_node_metal", "1", "Repair nodes use metal? (1=yes,0=no)", FCVAR_NOTIFY);
    cvarTeam = CreateConVar("repair_node_team", "0", "Allow repair nodes to teammates buildings? (1=yes,0=no)", FCVAR_NOTIFY);
    cvarMini = CreateConVar("repair_node_mini", "0", "Allow repair nodes to repair mini sentries? (1=yes,0=no)", FCVAR_NOTIFY);

    cvarRepairNodeRange[1] = CreateConVar("repair_node_range_1", "300.0", "How far away the Repair Node will heal a building at level 1.", FCVAR_PLUGIN|FCVAR_NOTIFY);
    cvarRepairNodeRange[2] = CreateConVar("repair_node_range_2", "400.0", "How far away the Repair Node will heal a building at level 2.", FCVAR_NOTIFY);
    cvarRepairNodeRange[3] = CreateConVar("repair_node_range_3", "500.0", "How far away the Repair Node will heal a building at level 3.", FCVAR_NOTIFY);

    cvarRepairNodeRegen[1] = CreateConVar("repair_node_regen_1", "15", "How much the Repair Node will heal a building, per 2 seconds, at level 1.", FCVAR_PLUGIN|FCVAR_NOTIFY);
    cvarRepairNodeRegen[2] = CreateConVar("repair_node_regen_2", "25", "How much the Repair Node will heal a building, per 2 seconds, at level 2.", FCVAR_NOTIFY);
    cvarRepairNodeRegen[3] = CreateConVar("repair_node_regen_3", "35", "How much the Repair Node will heal a building, per 2 seconds, at level 3.", FCVAR_NOTIFY);

    cvarRepairNodeShells[1] = CreateConVar("repair_node_ammo_1", "0", "How much ammo the Repair Node will replenish, per 2 seconds, at level 1.", FCVAR_PLUGIN|FCVAR_NOTIFY);
    cvarRepairNodeShells[2] = CreateConVar("repair_node_ammo_2", "5", "How much ammo the Repair Node will replenish, per 2 seconds, at level 2.", FCVAR_NOTIFY);
    cvarRepairNodeShells[3] = CreateConVar("repair_node_ammo_3", "10", "How much ammo the Repair Node will replenish, per 2 seconds, at level 3.", FCVAR_NOTIFY);

    cvarRepairNodeRockets = CreateConVar("repair_node_rockets", "2", "How many rockets the Repair Node will replenish, per 2 seconds, at level 3.", FCVAR_NOTIFY);

    HookEvent("player_builtobject", Event_Build);
    HookEvent("player_upgradedobject", Event_Upgrade);
    HookEvent("player_sapped_object", Event_Sapped);
    HookEvent("object_destroyed", Event_Remove);
    HookEvent("object_removed", Event_Remove);

    CreateTimer(1.0, BuildingTimer, _, TIMER_REPEAT);
    //HookEvent("teamplay_round_start", event_RoundStart);
    HookEvent("player_spawn", Event_player_spawn);
    //HookEntityOutput("obj_dispenser", "OnObjectHealthChanged", objectHealthChanged);

    RegConsoleCmd("amplifier",  CallPanel, "Select 2nd engineer's building ");
    RegConsoleCmd("amp",        CallPanel, "Select 2nd engineer's building ");
    RegConsoleCmd("sel",        CallPanel, "Select 2nd engineer's building ");
    RegConsoleCmd("amp_help",   HelpPanel, "Show info Amplifier");

    LoadTranslations("amp_node");
    HookEvent("player_death", event_player_death);

    HookConVarChange(cvarAmplifierEnabled, CvarChange);
    HookConVarChange(cvarAmplifierPercent, CvarChange);

    HookConVarChange(cvarAmplifierRange[1], CvarChange);
    HookConVarChange(cvarAmplifierRange[2], CvarChange);
    HookConVarChange(cvarAmplifierRange[3], CvarChange);

    HookConVarChange(cvarAmplifierUpgradable, CvarChange);
    HookConVarChange(cvarAmplifierMetal, CvarChange);
    HookConVarChange(cvarRegeneration, CvarChange);
    HookConVarChange(cvarMiniCritToSG, CvarChange);
    HookConVarChange(cvarWallBlock, CvarChange);
    HookConVarChange(cvarSpawnMenu, CvarChange);
    HookConVarChange(cvarCondition, CvarChange);
    HookConVarChange(cvarParticle, CvarChange);
    HookConVarChange(cvarMetalMax, CvarChange);

    HookConVarChange(cvarRepairNodeEnabled, CvarChange);
    HookConVarChange(cvarRepairNodePercent, CvarChange);
    HookConVarChange(cvarRepairNodeMetal, CvarChange);
    HookConVarChange(cvarTeam, CvarChange);
    HookConVarChange(cvarMini, CvarChange);

    HookConVarChange(cvarRepairNodeRange[1], CvarChange);
    HookConVarChange(cvarRepairNodeRange[2], CvarChange);
    HookConVarChange(cvarRepairNodeRange[3], CvarChange);

    HookConVarChange(cvarRepairNodeRegen[1], CvarChange);
    HookConVarChange(cvarRepairNodeRegen[2], CvarChange);
    HookConVarChange(cvarRepairNodeRegen[3], CvarChange);

    HookConVarChange(cvarRepairNodeShells[1], CvarChange);
    HookConVarChange(cvarRepairNodeShells[2], CvarChange);
    HookConVarChange(cvarRepairNodeShells[3], CvarChange);

    HookConVarChange(cvarRepairNodeRockets, CvarChange);

    AutoExecConfig(true, "plugin.amp_node");
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == cvarRepairNodeEnabled)
        RepairNodeEnabled = bool:StringToInt(newValue);
    else if (convar == cvarRepairNodePercent)
        RepairNodePercent = StringToInt(newValue);
    else if (convar == cvarAmplifierEnabled)
        AmplifierEnabled = bool:StringToInt(newValue);
    else if (convar == cvarAmplifierPercent)
        AmplifierPercent = StringToInt(newValue);
    else if (convar == cvarAmplifierMetal)
        AmplifierMetal = StringToInt(newValue);
    else if (convar == cvarRepairNodeMetal)
        RepairNodeMetal = bool:StringToInt(newValue);
    else if (convar == cvarTeam)
        DefaultTeam = bool:StringToInt(newValue);
    else if (convar == cvarMini)
        DefaultMini = bool:StringToInt(newValue);
    else if (convar == cvarMetalMax)
        MetalMax = StringToInt(newValue);
    else if (convar == cvarRegeneration)
        MetalRegeneration = StringToInt(newValue);
    else if (convar == cvarCondition)
        DefaultCondition = TFCond:StringToInt(newValue);
    else if (convar == cvarAmplifierUpgradable)
        AmplifierUpgradable = bool:StringToInt(newValue);
    else if (convar == cvarMiniCritToSG)
        MiniCritToSG = bool:StringToInt(newValue);
    else if (convar == cvarParticle)
        ShowParticle = bool:StringToInt(newValue);
    else if (convar == cvarWallBlock)
        WallBlock = bool:StringToInt(newValue);
    else if (convar == cvarSpawnMenu)
        SpawnMenu = bool:StringToInt(newValue);
    else if (convar == cvarAmplifierRange[1])
        DefaultAmplifierRange[1] = StringToFloat(newValue);
    else if (convar == cvarAmplifierRange[2])
        DefaultAmplifierRange[2] = StringToFloat(newValue);
    else if (convar == cvarAmplifierRange[3])
        DefaultAmplifierRange[3] = StringToFloat(newValue);
    else if (convar == cvarRepairNodeRange[1])
        DefaultRepairNodeRange[1] = StringToFloat(newValue);
    else if (convar == cvarRepairNodeRange[2])
        DefaultRepairNodeRange[2] = StringToFloat(newValue);
    else if (convar == cvarRepairNodeRange[3])
        DefaultRepairNodeRange[3] = StringToFloat(newValue);
    else if (convar == cvarRepairNodeRegen[1])
        DefaultRegen[1] = StringToInt(newValue);
    else if (convar == cvarRepairNodeRegen[2])
        DefaultRegen[2] = StringToInt(newValue);
    else if (convar == cvarRepairNodeRegen[3])
        DefaultRegen[3] = StringToInt(newValue);
    else if (convar == cvarRepairNodeShells[1])
        DefaultShells[1] = StringToInt(newValue);
    else if (convar == cvarRepairNodeShells[2])
        DefaultShells[2] = StringToInt(newValue);
    else if (convar == cvarRepairNodeShells[3])
        DefaultShells[3] = StringToInt(newValue);
    else if (convar == cvarRepairNodeRockets)
        DefaultRockets = StringToInt(newValue);
}

public OnConfigsExecuted()
{
    AmplifierEnabled = GetConVarBool(cvarAmplifierEnabled);
    AmplifierPercent = GetConVarInt(cvarAmplifierPercent);
    AmplifierMetal = GetConVarInt(cvarAmplifierMetal);

    AmplifierUpgradable = GetConVarBool(cvarAmplifierUpgradable);
    DefaultCondition = TFCond:GetConVarInt(cvarCondition);
    MiniCritToSG = GetConVarBool(cvarMiniCritToSG);
    ShowParticle = GetConVarBool(cvarParticle);
    WallBlock = GetConVarBool(cvarWallBlock);
    SpawnMenu = GetConVarBool(cvarSpawnMenu);

    MetalRegeneration = GetConVarInt(cvarRegeneration);
    MetalMax = GetConVarInt(cvarMetalMax);

    RepairNodeEnabled = GetConVarBool(cvarRepairNodeEnabled);
    RepairNodePercent = GetConVarInt(cvarRepairNodePercent);
    RepairNodeMetal = GetConVarBool(cvarRepairNodeMetal);
    DefaultTeam = GetConVarBool(cvarTeam);
    DefaultMini = GetConVarBool(cvarMini);

    DefaultAmplifierRange[1] = GetConVarFloat(cvarAmplifierRange[1]);
    DefaultAmplifierRange[2] = GetConVarFloat(cvarAmplifierRange[2]);
    DefaultAmplifierRange[3] = GetConVarFloat(cvarAmplifierRange[3]);

    DefaultRepairNodeRange[1] = GetConVarFloat(cvarRepairNodeRange[1]);
    DefaultRepairNodeRange[2] = GetConVarFloat(cvarRepairNodeRange[2]);
    DefaultRepairNodeRange[3] = GetConVarFloat(cvarRepairNodeRange[3]);

    DefaultRegen[1] = GetConVarInt(cvarRepairNodeRegen[1]);
    DefaultRegen[2] = GetConVarInt(cvarRepairNodeRegen[2]);
    DefaultRegen[3] = GetConVarInt(cvarRepairNodeRegen[3]);

    DefaultShells[1] = GetConVarInt(cvarRepairNodeShells[1]);
    DefaultShells[2] = GetConVarInt(cvarRepairNodeShells[2]);
    DefaultShells[3] = GetConVarInt(cvarRepairNodeShells[3]);

    DefaultRockets = GetConVarInt(cvarRepairNodeRockets);

    if (!NativeControl && !GetConVarBool(cvarAnnounce))
    {
        CreateTimer(250.0, Timer_Announce, _,
                    TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

public OnMapStart()
{
    static String:extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
    static String:extensionsb[][] = {".vtf", ".vmt"};
    new String:strLine[256];

    // Download the Amplifier & Gib Models
    for (new i=0; i < sizeof(extensions); i++)
    {
        Format(strLine,sizeof(strLine),"%s%s",AmplifierModel,extensions[i]);
        AddFileToDownloadsTable(strLine);
        for (new j=1; j <=8; j++)
        {
            Format(strLine,sizeof(strLine),"%s%i%s",AMPgib,j,extensions[i]);
            AddFileToDownloadsTable(strLine);
        }
    }

    // Download the Amplifier Materials
    for (new i=0; i < sizeof(extensionsb); i++)
    {
        Format(strLine,sizeof(strLine),"%s%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_blue%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_anim%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_anim_blue%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_anim2%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_anim2_blue%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_holo%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_bolt%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_holo_blue%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
        Format(strLine,sizeof(strLine),"%s_radar%s",AmplifierTex,extensionsb[i]);
        AddFileToDownloadsTable(strLine);
    }

    // Download the Repair Node Materials
    AddFileToDownloadsTable("materials/models/buildables/repair/repair_blue.vmt");
    AddFileToDownloadsTable("materials/models/buildables/repair/repair_blue.vtf");
    AddFileToDownloadsTable("materials/models/buildables/repair/repair_red.vmt");
    AddFileToDownloadsTable("materials/models/buildables/repair/repair_red.vtf");

    //Precache the Amplifier Model
    Format(strLine,sizeof(strLine),"%s.mdl",AmplifierModel);
    SetupModel(strLine, .precache=true);

    // Precache the Amplifier Gib Models
    for (new i=1; i <=8; i++)
    {
        Format(strLine,sizeof(strLine),"%s%d.mdl",AMPgib, i);
        SetupModel(strLine, .precache=true);
    }

    // Precache the Repair Node Models (for each level)
    for (new i=1; i <=3; i++)
    {
        Format(strLine,sizeof(strLine),"%s%d.mdl",RepairNodeModel, i);
        SetupModel(strLine, .precache=true);
    }

    // Setup some models for effects
    SetupModel(BeamModel, g_BeamSprite);
    SetupModel(HaloModel, g_HaloSprite);
}

public OnClientAuthorized(client, const String:auth[])
{
    static const Float:UseDefaultRange[4] = { -1.0, -1.0, -1.0, -1.0 };
    static const UseDefaultValues[4]      = { -1,   -1,   -1,   -1 };

    BuildingType[client]=TFExtObject_Unknown;
    DontAsk[client]=false;

    NativeAmplifierRange[client] = UseDefaultRange;
    NativeAmplifierPercent[client] = -1;

    NativeRepairNodeRange[client] = UseDefaultRange;
    NativeShells[client] = UseDefaultValues;
    NativeRegen[client] = UseDefaultValues;
    NativeRockets[client] = -1;
    NativeRepairNodePercent[client] = -1;
    RepairNodeTeam[client] = bool:-1;
    RepairNodeMini[client] = bool:-1;
}

public Action:Timer_Announce(Handle:hTimer)
{
	if (NativeControl || GetConVarBool(cvarAnnounce))
		return Plugin_Stop;
	else
	{
        #if defined(_colors_included)
		    CPrintToChatAll("%t", "Announce1");
		    CPrintToChatAll("%t", "Announce2");
		    CPrintToChatAll("%t", "Announce3");
		    CPrintToChatAll("%t", "Announce4");
        #else
		    PrintToChatAll("%t", "NoColor1");
		    PrintToChatAll("%t", "NoColor2");
		    PrintToChatAll("%t", "NoColor3");
		    PrintToChatAll("%t", "NoColor4");
        #endif
		return Plugin_Continue;
	}
}

//Show Panel to Engineer on spawn.
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!NativeControl && SpawnMenu)
	{
		new client=GetClientOfUserId(GetEventInt(event, "userid"));
		if (!DontAsk[client])
			AmpPanel(client);		
	}
	return Plugin_Continue;
}

public AmpHelpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
		return;   
}
  
public Action:HelpPanel(client, Args)
{
    new String:s[256];
    new Handle:panel = CreatePanel();

    Format(s,sizeof(s),"%t","Help1");
    SetPanelTitle(panel, s);

    Format(s,sizeof(s),"%t","Help2");
    DrawPanelText(panel, s);

    Format(s,sizeof(s),"%t","Help3");
    DrawPanelText(panel, s);

    Format(s,sizeof(s),"%t","Help4");
    DrawPanelText(panel, s);

    Format(s,sizeof(s),"%t","Help5");
    DrawPanelText(panel, s);

    Format(s,sizeof(s),"%t","Help6");
    DrawPanelText(panel, s);

    DrawPanelItem(panel, "Close Menu");  
    SendPanelToClient(panel, client, AmpHelpPanelH, 16);
    CloseHandle(panel);
}

//Show Panel to Enginner on command
public Action:CallPanel(client, Args)
{
	if (!NativeControl)
		AmpPanel(client);

	return Plugin_Continue;
}

//Panel's procedure
public AmpPanel(client)
{		
    if (NativeControl || TF2_GetPlayerClass(client) != TFClass_Engineer)
        return;

    new bool:ampEnabled;
    new bool:rnEnabled;
    if (NativeControl)
    {
        ampEnabled = NativeAmplifier[client];
        rnEnabled = NativeRepairNode[client];
    }
    else
    {
        ampEnabled = AmplifierEnabled;
        rnEnabled = RepairNodeEnabled;
    }

    new String:str[256];
    new Handle:panel = CreatePanel();

    Format(str,sizeof(str),"%t","Select2ndBuilding");
    SetPanelTitle(panel, str);

    Format(str,sizeof(str),"%t","Dispenser");
    DrawPanelItem(panel, str);

    Format(str,sizeof(str),"%t","Amplifier"); 
    DrawPanelItem(panel, str, ampEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(str,sizeof(str),"%t","RepairNode"); 
    DrawPanelItem(panel, str, rnEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(str,sizeof(str),"%t","DispenserDontAsk"); 
    DrawPanelItem(panel, str);

    Format(str,sizeof(str),"%t","AmplifierDontAsk"); 
    DrawPanelItem(panel, str, ampEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(str,sizeof(str),"%t","RepairNodeDontAsk"); 
    DrawPanelItem(panel, str, rnEnabled ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    SendPanelToClient(panel, client, AmpPanelH, 20);
    CloseHandle(panel); 
}

//Panel's Handle Procedure
public AmpPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				BuildingType[param1]=TFExtObject_Dispenser;
				DontAsk[param1]=false;
			}
			case 2:
			{
                if (NativeControl ? NativeAmplifier[param1] : AmplifierEnabled)
                {
                    BuildingType[param1]=TFExtObject_Amplifier;
                    DontAsk[param1]=false;
                }
            }
            case 3:
            {
                if (NativeControl ? NativeRepairNode[param1] : RepairNodeEnabled)
                {
                    BuildingType[param1]=TFExtObject_RepairNode;
                    DontAsk[param1]=false;
                }
            }
            case 4:
            {
                BuildingType[param1]=TFExtObject_Dispenser;
                DontAsk[param1]=true;

                #if defined(_colors_included)
                    CPrintToChat(param1,"%t", "Announce1");
                #else
                    PrintToChat(param1,"%t", "NoColor1");
                #endif
            }
            case 5:
            {
                if (NativeControl ? NativeAmplifier[param1] : AmplifierEnabled)
                {
                    BuildingType[param1]=TFExtObject_Amplifier;
                    DontAsk[param1]=true;

                    #if defined(_colors_included)
                        CPrintToChat(param1,"%t", "Announce1");
                    #else
                        PrintToChat(param1,"%t", "NoColor1");
                    #endif
                }
            }
            case 6:
            {
                if (NativeControl ? NativeRepairNode[param1] : RepairNodeEnabled)
                {
                    BuildingType[param1]=TFExtObject_RepairNode;
                    DontAsk[param1]=true;

                    #if defined(_colors_included)
                        CPrintToChat(param1,"%t", "Announce1");
                    #else
                        PrintToChat(param1,"%t", "NoColor1");
                    #endif
                }
            }
        }
    }
}

//Main timer:
//--Detect players near (or not) Amplifiers.
//--Spawn (Remove) crit effects on players. 
//--Disable Amplifiers when they dying
//--WAVES
public Action:BuildingTimer(Handle:hTimer)
{
    new Float:Pos[3];
    new Float:BuildingPos[3];
    new TFTeam:clientTeam;
    new TFTeam:team;
    new i,client;
    new maxEntities = GetMaxEntities();
    for(client=1;client<=MaxClients;client++)
    {
        if (IsClientInGame(client)) 
        {
            NearAmplifier[client]=false;
            if (IsPlayerAlive(client) && IsValidEdict(client)) 
            {
                GetEntPropVector(client, Prop_Send, "m_vecOrigin", Pos);  //Get player's position
                clientTeam=TFTeam:GetClientTeam(client);

                //Check all Entities/Buildings
                for(i=MaxClients+1;i<maxEntities;i++)
                {
                    //If Building Exists, is Active and is not Sapped
                    new ent = EntRefToEntIndex(BuildingRef[i]);
                    if (ent > 0 && BuildingOn[ent] && BuildingType[ent] == TFExtObject_Amplifier &&
                        !GetEntProp(ent, Prop_Send, "m_bHasSapper"))
                    {
                        // Check Metal
                        new metal = GetEntProp(ent, Prop_Send, "m_iAmmoMetal");
                        if (metal < AmplifierMetal && AmplifierMetal > 0)
                            continue;

                        // Check Percent Chance
                        new percent = BuildingPercent[ent];
                        if (percent >= 0 && percent < 100 && (ConditionApplied[ent][client] || GetRandomInt(1,100) > percent))
                            continue;

                        new bool:enableParticle;
                        new TFCond:Condition = AmplifierCondition[ent];
                        switch (Condition)
                        {
                            case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed,
                                 TFCond_DemoBuff, TFCond_DefenseBuffed, TFCond_Charging,
                                 TFCond_CritCola, TFCond_RegenBuffed:
                            {
                                enableParticle = (ShowParticle &&
                                                  Condition != TFCond_Buffed &&
                                                  Condition != TFCond_DefenseBuffed &&
                                                  Condition != TFCond_RegenBuffed);

                                team = TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum");
                            }
                            case TFCond_Slowed, TFCond_Zoomed, TFCond_TeleportedGlow, TFCond_Taunting,
                                 TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated, TFCond_Disguised,
                                 TFCond_Cloaked, TFCond_Bleeding, TFCond_Milked, TFCond_MarkedForDeath:
                            {
                                enableParticle = false;
                                team = (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum") == TFTeam_Red)
                                       ? TFTeam_Blue : TFTeam_Red;
                            }
                            default:
                            {
                                enableParticle = false;
                                team = TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum");
                            }
                        }

                        //Spy can use enemies' Amplifier
                        if ((TF2_GetPlayerClass(client) == TFClass_Spy) &&
                            TF2_IsPlayerDisguised(client) &&
                            !TF2_IsPlayerCloaked(client))
                        {
                            team=clientTeam;
                        }

                        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", BuildingPos);

                        new level = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");

                        if (clientTeam==team &&
                            GetVectorDistance(Pos,BuildingPos) <= BuildingRange[ent][level] &&
                            (!WallBlock || TraceTargetIndex(ent, client, BuildingPos, Pos)))
                        {
                            new Action:res = Plugin_Continue;
                            new builder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");

                            Call_StartForward(fwdOnAmplify);
                            Call_PushCell(builder);
                            Call_PushCell(client);
                            Call_PushCell(Condition);
                            Call_Finish(res);

                            if (res != Plugin_Continue)
                                continue;

                            //If player in Amplifier's distance and on Amplifier's team
                            if (enableParticle)
                            {
                                //If Crit Effect does NOT Exist
                                new particle = EntRefToEntIndex(GetPar[client]);
                                if (particle <= 0 || !IsValidEntity(particle))
                                {
                                    //Create Buffed Effect
                                    if (team==TFTeam_Red)
                                        AttachParticle(client,"soldierbuff_red_buffed",particle);
                                    else
                                        AttachParticle(client,"soldierbuff_blue_buffed",particle);
                                    GetPar[client] = EntIndexToEntRef(particle);
                                }
                            }

                            new String:weapon[64];
                            GetClientWeapon(client, weapon, sizeof(weapon));

                            //Set condition to player
                            switch (Condition)
                            {
                                case TFCond_Slowed:
                                {
                                    if (builder > 0)
                                    {
                                        TF2_StunPlayer(client, 1.0, 0.25, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT,
                                                       builder);
                                    }
                                }
                                case TFCond_Zoomed:
                                {
                                    if (builder > 0)
                                    {
                                        TF2_StunPlayer(client, 1.0, 0.50, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT,
                                                       builder);
                                    }
                                }
                                case TFCond_Bonked:
                                {
                                    if (builder > 0)
                                        TF2_StunPlayer(client, 1.0, 0.75, TF_STUNFLAGS_LOSERSTATE, builder);
                                }
                                case TFCond_Dazed:
                                {
                                    if (builder > 0)
                                        TF2_StunPlayer(client, 1.0, 0.0, TF_STUNFLAGS_NORMALBONK, builder);
                                }
                                case TFCond_Bleeding:
                                {
                                    if (builder > 0)
                                        TF2_MakeBleed(client, builder, 1.0);
                                }
                                case TFCond_OnFire:
                                {
                                    if (builder > 0)
                                        TF2_IgnitePlayer(client, builder);
                                }
                                case TFCond_Kritzkrieged:
                                {
                                    if (TF2_GetPlayerClass(client) == TFClass_Engineer)
                                    {
                                        if (MiniCritToSG &&
                                            StrEqual(weapon, "tf_weapon_laser_pointer"))
                                        {
                                            TF2_AddCondition(client, TFCond_Buffed, 2.0);							
                                        }
                                        else if (StrEqual(weapon, "tf_weapon_sentry_revenge"))
                                        {
                                            //Engineer with Frontier Justice
                                            if (Revenges[client]==0)
                                                Revenges[client]=GetEntProp(client, Prop_Send, "m_iRevengeCrits")+2;
                                            SetEntProp(client, Prop_Send, "m_iRevengeCrits", Revenges[client]);
                                        }
                                    }
                                }
                                case TFCond_Taunting:
                                {
                                    FakeClientCommand(client, "taunt");
                                }
                                case TFCond_Disguised, TFCond_Cloaked:
                                {
                                    TF2_RemoveCondition(client, Condition);
                                }
                                default:
                                {
                                    TF2_AddCondition(client, Condition, 1.0);
                                }
                            }

                            ConditionApplied[ent][client]=true;
                            NearAmplifier[client]=true;

                            if (AmplifierMetal > 0)
                            {
                                metal -= AmplifierMetal;
                                SetEntProp(ent, Prop_Send, "m_iAmmoMetal", metal);
                            }
                            break;
                        } 
                    }

                    // Only remove conditions that were set by the amplifier
                    if (ent > 0 && !NearAmplifier[client] && ConditionApplied[ent][client])
                    {
                        ConditionApplied[ent][client]=false;
                        TF2_RemoveCondition(client, AmplifierCondition[ent]);
                        new String:weapon[64];
                        GetClientWeapon(client, weapon, sizeof(weapon));

                        if (MiniCritToSG && AmplifierCondition[ent] != TFCond_Buffed &&
                            TF2_GetPlayerClass(client) == TFClass_Engineer &&
                            StrEqual(weapon, "tf_weapon_laser_pointer"))
                        {
                            TF2_RemoveCondition(client, TFCond_Buffed);							
                        
                            if (Revenges[client] > 2)
                                SetEntProp(client, Prop_Send, "m_iRevengeCrits", Revenges[client]-2);
                            else
                                SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);

                            Revenges[client]=0;
                        }
                    }
                }
            }

            //if Amplifiers on distance not found or client is dead
            if ((i==maxEntities) || !IsPlayerAlive(client))
            {
                //if player has crit effect - delete it
                new particle = EntRefToEntIndex(GetPar[client]);
                if (particle > 0 && IsValidEntity(particle))
                {
                    AcceptEntityInput(particle, "kill");
                }
                GetPar[client] = INVALID_ENT_REFERENCE;
            }
        }
    }

    //Check all Entities
    for(i=MaxClients+1;i<maxEntities;i++)
    {
        new ref = BuildingRef[i];
        if (ref != INVALID_ENT_REFERENCE)
        {
            new ent = EntRefToEntIndex(ref);
            if (ent > 0 && IsValidEntity(ent))
            {
                if (BuildingOn[ent] && !GetEntProp(ent, Prop_Send, "m_bHasSapper"))
                {
                    new metal;
                    if (MetalRegeneration > 0)
                    {
                        metal = GetEntProp(ent, Prop_Send, "m_iAmmoMetal") + MetalRegeneration;
                        if (metal <= MetalMax)
                            SetEntProp(ent, Prop_Send, "m_iAmmoMetal", metal);
                    }
                    else
                        metal = 255;

                    new level = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");

                    if (BuildingType[ent] == TFExtObject_Amplifier)
                    {
                        //Brute force heal bug fix
                        if (GetEntProp(ent, Prop_Send, "m_bDisabled") == 0)
                            SetEntProp(ent, Prop_Send, "m_bDisabled", 1);

                        if (!AmplifierUpgradable)
                        {
                            new upgradeMetal = GetEntProp(ent, Prop_Send, "m_iUpgradeMetal");
                            if (upgradeMetal > 0)
                            {
                                SetEntProp(ent, Prop_Send, "m_iUpgradeMetal",0);
                                metal += upgradeMetal*(MetalMax/200);
                                if (metal <= MetalMax)
                                    SetEntProp(ent, Prop_Send, "m_iAmmoMetal", metal);
                            }
                        }

                        if (metal < AmplifierMetal)
                            continue;

                        //Amplifier's waves
                        new beamColor[4];
                        switch (AmplifierCondition[ent])
                        {
                            case TFCond_Slowed, TFCond_Zoomed, TFCond_TeleportedGlow, TFCond_Taunting,
                                 TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated, TFCond_Disguised,
                                 TFCond_Cloaked, TFCond_Bleeding, TFCond_Milked, TFCond_MarkedForDeath:
                            {
                                beamColor = {255, 255, 75, 255}; // Yellow
                            }
                            //case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed,
                            //     TFCond_DemoBuff, TFCond_DefenseBuffed, TFCond_Charging,
                            //     TFCond_CritCola, TFCond_RegenBuffed:
                            default:
                            {
                                if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
                                    beamColor = {255, 75, 75, 255}; // Red
                                else
                                    beamColor = {75, 75, 255, 255}; // Blue
                            }
                        }

                        if (metal < 255)
                            beamColor[3] = metal;

                        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
                        Pos[2]+=90;

                        PrepareModel(BeamModel, g_BeamSprite);
                        PrepareModel(HaloModel, g_HaloSprite);
                        TE_SetupBeamRingPoint(Pos, 10.0, BuildingRange[ent][level]+100.1, g_BeamSprite, g_HaloSprite,
                                              0, 15, 3.0, 5.0, 0.0, beamColor, 3, 0);
                        TE_SendToAll();
                    }
                    else if (BuildingType[ent] == TFExtObject_RepairNode)
                    {
                        // Check Metal
                        if (RepairNodeMetal && metal < RepairNodeRegen[ent][level])
                            continue;

                        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
                        client = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
                        if (client > 0)
                        {
                            new obj = -1;
                            new minMetal = RepairNodeRegen[ent][level];
                            while ((!RepairNodeMetal || metal >= minMetal) &&
                                    (obj = FindEntityByClassname(obj, "obj_sentrygun")) != -1)
                            {
                                CheckObject(client, ent, obj, Pos, level, metal, true);
                            }

                            while ((!RepairNodeMetal || metal >= minMetal) &&
                                    (obj = FindEntityByClassname(obj, "obj_teleporter")) != -1)
                            {
                                CheckObject(client, ent, obj, Pos, level, metal, false);
                            }

                            while ((!RepairNodeMetal || metal >= minMetal) &&
                                    (obj = FindEntityByClassname(obj, "obj_dispenser")) != -1)
                            {
                                CheckObject(client, ent, obj, Pos, level, metal, false);
                            }
                        }
                    }
                }
            }
            else
            {
                // The building is no longer valid (was destroyed)
                if (BuildingType[i] == TFExtObject_Amplifier)
                {
                    // Remove any lingering amplifier conditions
                    for(client=1;client<=MaxClients;client++)
                    {
                        if (ConditionApplied[i][client])
                        {
                            ConditionApplied[i][client]=false;
                            if (IsClientInGame(client) && IsPlayerAlive(client)) 
                                TF2_RemoveCondition(client, AmplifierCondition[i]);
                        }
                    }
                }
                else if (BuildingType[i] == TFExtObject_RepairNode)
                {
                    // Remove any healing beams
                    for(new obj=MaxClients+1;obj<maxEntities;obj++)
                    {
                        if (EntRefToEntIndex(RepairNodeTarget[obj]) == i)
                            RemoveRepairParticles(obj);
                    }
                }
                BuildingType[i] = TFExtObject_Unknown;
                BuildingRef[i] = INVALID_ENT_REFERENCE;
            }
        }
    }
    return Plugin_Continue;
}

CheckObject(client, ent, obj, Float:Pos[3], level, &metal, bool:isSentry)
{
    if (obj != ent)
    {
        if (NativeControl)
        {
            if (RepairNodeTeam[ent])
            {
                if (GetEntProp(obj, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
                    return;
            }
            else
            {
                if (GetEntPropEnt(obj, Prop_Send, "m_hBuilder") != client)
                    return;
            }

            if (RepairNodeMini[ent] &&
                GetEntProp(obj, Prop_Send, "m_bMiniBuilding"))
            {
                return;
            }
        }
        else
        {
            if (DefaultTeam)
            {
                if (GetEntProp(ent, Prop_Send, "m_iTeamNum") != GetClientTeam(client))
                    return;
            }
            else
            {
                if (GetEntPropEnt(obj, Prop_Send, "m_hBuilder") != client)
                    return;
            }

            if (DefaultMini &&
                GetEntProp(obj, Prop_Send, "m_bMiniBuilding"))
            {
                return;
            }
        }

        new Float:BuildingPos[3];
        GetEntPropVector(obj, Prop_Send, "m_vecOrigin", BuildingPos);

        if (GetVectorDistance(Pos,BuildingPos) <= BuildingRange[ent][level] &&
            TraceTargetIndex(ent, obj, BuildingPos, Pos))
        {
            // Check Percent Chance (if any)
            new percent = BuildingPercent[ent];
            if (percent >= 0 && percent < 100 && GetRandomInt(1,100) > percent)
                return;

            if (RepairNodeParticle[obj][0] == INVALID_ENT_REFERENCE)
            {
                new pref = RepairNodeProp[ent];
                new prop = EntRefToEntIndex(pref);
                if (prop <= 0)
                {
                    // Make an invisible dispenser prop to attach the heal beam to
                    // since the repair node doesn't have any attachment points :(

                    prop = CreateEntityByName("prop_dynamic");
                    if (prop > 0 && IsValidEdict(prop))
                    {
                        new String:pName[128]; // Dispenser Prop
                        Format(pName, sizeof(pName), "target%i", prop);
                        DispatchKeyValue(prop, "targetname", pName);
                        DispatchKeyValue(prop, "model", "models/buildables/dispenser.mdl");
                        DispatchSpawn(prop);

                        //DispatchKeyValue(prop, "rendermode", "10");
                        SetEntityRenderMode(prop, RENDER_NONE);

                        new Float:angles[3];
                        GetEntPropVector(ent, Prop_Send, "m_angRotation", angles);
                        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
                        TeleportEntity(prop, Pos, angles, NULL_VECTOR);
                        //DispatchKeyValueVector(prop, "origin", Pos);

                        new String:rName[128]; // Repair Node
                        Format(rName, sizeof(rName), "target%i", ent);
                        DispatchKeyValue(ent, "targetname", rName);
                        DispatchKeyValue(prop, "parentname", rName);

                        SetVariantString(rName);
                        AcceptEntityInput(prop, "SetParent");

                        RepairNodeProp[ent] = EntIndexToEntRef(prop);
                    }
                    else
                        LogError("Unable to create prop_dynamic for repair node %d", ent);
                }

                new p, p2;
                if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
                {
#if 1
                    AttachRepairParticle(obj, "medicgun_beam_red", ent, Pos, prop, p, p2);
#else
                    p = CreateParticle("medicgun_beam_red", 0.0, prop, Attach, "build_point_0",
                                       .target=obj, .targetBone="build_point_0", .target_particle=p2);
#endif                                       
                }
                else                                                
                {
#if 1
                    AttachRepairParticle(obj, "medicgun_beam_blue", ent, Pos, prop, p, p2);
#else
                    p = CreateParticle("medicgun_beam_blue", 0.0, prop, Attach, "build_point_0",
                                       .target=obj, .targetBone="build_point_0", .target_particle=p2);
#endif                                       
                }

                RepairNodeParticle[obj][0] = EntIndexToEntRef(p);
                RepairNodeParticle[obj][1] = EntIndexToEntRef(p2);
                RepairNodeTarget[obj] = EntIndexToEntRef(ent);
            }

            new regen = RepairNodeRegen[ent][level];
            if (regen > 0 && metal > 0)
            {
                new max = GetEntProp(obj, Prop_Send, "m_iMaxHealth");
                new health = GetEntProp(obj, Prop_Send, "m_iHealth");
                if (health + regen > max)
                    regen = max - health;

                if (regen > metal)
                    regen = metal;

                if (regen > 0)
                {
                    SetEntityHealth(obj, health+regen);
                    metal -= regen;
                }
            }

            if (isSentry)
            {
                new shells = RepairNodeShells[ent][level];
                if (shells > 0 && metal > 0)
                {
                    new maxAmmo = TF2_MaxSentryShells[level];
                    new ammo = GetEntProp(obj, Prop_Send, "m_iAmmoShells");
                    if (ammo + shells > maxAmmo)
                        shells = maxAmmo - ammo;

                    if (shells > metal)
                        shells = metal;

                    if (shells > 0)
                    {
                        SetEntProp(obj, Prop_Send, "m_iAmmoShells", ammo+shells);
                        metal -= shells;
                    }
                }

                new maxRockets = TF2_MaxSentryRockets[level];
                if (maxRockets > 0)
                {
                    new amt = RepairNodeRockets[ent];
                    if (amt > 0 && metal > 0)
                    {
                        new rockets = GetEntProp(obj, Prop_Send, "m_iAmmoRockets");
                        if (rockets + amt > maxRockets)
                            amt = maxRockets - rockets;

                        if (amt > metal)
                            amt = metal;

                        if (amt > 0)
                        {
                            SetEntProp(obj, Prop_Send, "m_iAmmoRockets", rockets+amt);
                            metal -= amt;
                        }
                    }
                }
            }
        }
        else
        {
            // Remove healing beams (if any)
            if (EntRefToEntIndex(RepairNodeTarget[obj]) == ent)
                RemoveRepairParticles(obj);
        }
    }
}

stock AttachRepairParticle(obj, String:particleType[], ent, const Float:Pos[3], prop,
                           &particle, &particle2)
{
    //This is used to attach a particle that has two control points
    //such as the medic gun beam. One originates from the medic
    //and the other to its healer

    //This particle is attached to the source player
    //This will be visible
    particle  = CreateEntityByName("info_particle_system");
    if (particle > 0 && IsValidEdict(particle))
    {
        //Name the particle (this particle is attached to the source player)
        new String:particleName[128];
        Format(particleName, sizeof(particleName), "TF2particle%i", particle);
        DispatchKeyValue(particle, "targetname", particleName);

        //Tell it what effect name it is then spawn it so we can use it
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);

        //Name the destination, usually another player
        new String:cpName[128];
        Format(cpName, sizeof(cpName), "target%i", ent);
        DispatchKeyValue(ent, "targetname", cpName);

        //--------------------------------------

        new String:dName[128];
        Format(dName, sizeof(dName), "target%i", prop);

        //Parent the source particle to the source player
        DispatchKeyValue(particle, "parentname", dName);
        SetVariantString(dName);
        AcceptEntityInput(particle, "SetParent");

        //Attach the source particle to the "flag" (stomach area)
        SetVariantString("build_point_0");
        AcceptEntityInput(particle, "SetParentAttachment");

        //This particle is attached to the destination player
        //This will not be visibile, we only need it so the source particle
        //is attached in the apropriate place
        particle2 = CreateEntityByName("info_particle_system");
        if (particle2 > 0 && IsValidEdict(particle2))
        {
            //Give the destination particle a unique name
            new String:cp2Name[128];
            Format(cp2Name, sizeof(cp2Name), "TF2particle%i", particle2);
            DispatchKeyValue(particle2, "targetname", cp2Name);
            DispatchKeyValueVector(particle2, "origin", Pos);

            //Name the originating source, usually the player
            new String:tName[128];
            Format(tName, sizeof(tName), "target%i", obj);
            DispatchKeyValue(obj, "targetname", tName);

            //Attach the destination particle to the destined player
            DispatchKeyValue(particle2, "parentname", tName);

            SetVariantString(tName);
            AcceptEntityInput(particle2, "SetParent");
            SetVariantString("build_point_0");
            AcceptEntityInput(particle2, "SetParentAttachment");

            //-----------------------------------------------

            //Here's where we "join" the two particles
            //Join the source particle to the destination particle
            DispatchKeyValue(particle, "cpoint1", cp2Name);

            ActivateEntity(particle);
            AcceptEntityInput(particle, "start");
        }
    }
}

RemoveRepairParticles(obj)
{
    RepairNodeTarget[obj] = INVALID_ENT_REFERENCE;
    for (new i=0; i < sizeof(RepairNodeParticle[]); i++)
    {
        DeleteParticle(RepairNodeParticle[obj][i]);
    }
}

//Add scores for engi for assist by Amplifier
public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new Float:Pos[3];
	//new Float:BuildingPos[3];
	new Victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (NearAmplifier[Attacker] || NearAmplifier[Victim])
	{
		new maxEntities = GetMaxEntities();
		for(new i=MaxClients+1;i<maxEntities;i++)
		{
			new ent = EntRefToEntIndex(BuildingRef[i]);
			if (ent > 0 && BuildingOn[ent] && Attacker != i &&
                !GetEntProp(ent, Prop_Send, "m_bHasSapper"))
			{
				new bool:assist;
				switch (AmplifierCondition[ent])
				{
					case TFCond_Slowed, TFCond_Zoomed, TFCond_TeleportedGlow, TFCond_Taunting,
					     TFCond_Bonked, TFCond_Dazed, TFCond_OnFire, TFCond_Jarated, TFCond_Disguised,
                         TFCond_Cloaked, TFCond_Bleeding, TFCond_Milked, TFCond_MarkedForDeath:
					{
						assist = ConditionApplied[ent][Victim];
					}
					default:
						assist = ConditionApplied[ent][Attacker];
				}

				if (assist)
				{
					new builder = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
					if (builder > 0)
					{
						EngiAssists[builder]++;
						if (EngiAssists[builder]>=4)
						{
							new Handle:aevent = CreateEvent("player_escort_score", true) ;
							SetEventInt(aevent, "player", builder);
							SetEventInt(aevent, "points", 1);
							FireEvent(aevent);
							EngiAssists[builder]=0;
						}
					}
					break;
				}
			}
		}
	}
	return Plugin_Continue;
}


//Detect destruction or removal of buildings
public Action:Event_Remove(Handle:event, const String:name[], bool:dontBroadcast)
{
    new ent = GetEventInt(event, "index");
    if (ent > 0)
    {
        RemoveRepairParticles(ent);

        if (BuildingType[ent] == TFExtObject_Amplifier)
        {
            // Remove any lingering amplifier conditions
            for(new client=1;client<=MaxClients;client++)
            {
                if (ConditionApplied[ent][client])
                {
                    ConditionApplied[ent][client]=false;
                    if (IsClientInGame(client) && IsPlayerAlive(client)) 
                        TF2_RemoveCondition(client, AmplifierCondition[ent]);
                }
            }
        }
        else if (BuildingType[ent] == TFExtObject_RepairNode)
        {
            // Remove any healing beams
            new maxEntities = GetMaxEntities();
            for(new obj=MaxClients+1;obj<maxEntities;obj++)
            {
                if (EntRefToEntIndex(RepairNodeTarget[obj]) == ent)
                    RemoveRepairParticles(obj);
            }

            // Then kill the dispenser prop
            new prop = EntRefToEntIndex(RepairNodeProp[ent]);
            if (prop > 0 && IsValidEntity(prop))
            {
                AcceptEntityInput(prop, "kill");
            }
            RepairNodeProp[ent] = INVALID_ENT_REFERENCE;
        }

        BuildingType[ent] = TFExtObject_Unknown;
        BuildingRef[ent] = INVALID_ENT_REFERENCE;
    }
    return Plugin_Continue;
}

//Detect upgrading of buildings
public Action:Event_Upgrade(Handle:event, const String:name[], bool:dontBroadcast)
{
    new ent = GetEventInt(event, "index");
    if (ent > 0 && IsValidEntity(ent))
    {
        if (BuildingType[ent] == TFExtObject_Amplifier||
            BuildingType[ent] == TFExtObject_RepairNode)
        {
            new particle;
            if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
                AttachParticle(ent,"teleported_red",particle); //Create Effect of TP
            else
                AttachParticle(ent,"teleported_blue",particle); //Create Effect of TP

            CreateTimer(0.1, FixModel, EntIndexToEntRef(ent));
        }
    }

    return Plugin_Continue;
}

//Spa sappin' mah Amplifier!!!!11
public Action:Event_Sapped(Handle:event, const String:name[], bool:dontBroadcast)
{
    new ent = GetEventInt(event, "object");
    if (ent > 0 && IsValidEntity(ent))
    {
        if (BuildingType[ent] == TFExtObject_Amplifier||
            BuildingType[ent] == TFExtObject_RepairNode)
        {
            // Set the model back to the dispenser model so the sapper is visible
            new level = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
            if (level <= 1)
                SetEntityModel(ent,DispenserModel);
            else
            {
                decl String:modelname[128];
                Format(modelname,sizeof(modelname),"%s%d%s",DispenserModel2,level,".mdl");
                SetEntityModel(ent,modelname);
            }

            CreateTimer(0.1, CheckSapper, EntIndexToEntRef(ent),
                        TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }

    return Plugin_Continue;
}

public Action:CheckSapper(Handle:hTimer,any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent))
    {
        if (GetEntProp(ent, Prop_Send, "m_bHasSapper"))
            return Plugin_Continue;
        else
        {
            CreateTimer(0.1, FixModel, EntIndexToEntRef(ent));
        }
    }		
    return Plugin_Stop;
}

public Action:FixModel(Handle:hTimer,any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent))
    {
        // Ensure the Amplifier or Repair Node hasn't been enabled
        SetEntProp(ent, Prop_Send, "m_bDisabled", 1);

        decl String:modelname[128];
        if (BuildingType[ent] == TFExtObject_Amplifier)
        {
            Format(modelname,sizeof(modelname),"%s%s",AmplifierModel,".mdl");
            SetEntityModel(ent,modelname);
        }
        else if (BuildingType[ent] == TFExtObject_RepairNode)
        {
            // If there's a prop, make sure it stays invisible.
            new prop = EntRefToEntIndex(RepairNodeProp[ent]);
            if (prop > 0 && IsValidEdict(prop))
            {
                //DispatchKeyValue(prop, "rendermode", "10");
                SetEntityRenderMode(prop, RENDER_NONE);
            }

            new level = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
            Format(modelname,sizeof(modelname),"%s%d%s",RepairNodeModel,level,".mdl");
            SetEntityModel(ent,modelname);
        }
    }
    return Plugin_Stop;
}

public Action:Activate(Handle:hTimer,any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent))
    {
        new particle;
        if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
            AttachParticle(ent,"teleported_red",particle); //Create Effect of TP
        else
            AttachParticle(ent,"teleported_blue",particle); //Create Effect of TP

        CreateTimer(0.1, FixModel, ref);
    }
    return Plugin_Stop;
}

//Detect building of, err, buildings
public Action:Event_Build(Handle:event, const String:name[], bool:dontBroadcast)
{
    new ent = GetEventInt(event, "index");
    CheckDisp(ent, GetClientOfUserId(GetEventInt(event, "userid")), false);
    return Plugin_Continue;
}

//if building is dispenser
CheckDisp(ent, client, bool:force)
{
    new TFExtObjectType:type = BuildingType[ent];
    if (type == TFExtObject_Amplifier ||
        type == TFExtObject_RepairNode)
    {
        new ref = EntIndexToEntRef(ent);
        CreateTimer(0.1, FixModel, ref);

        new level = GetEntProp(ent, Prop_Send, "m_iHighestUpgradeLevel");
        CreateTimer((level > 2) ? 11.4 : 10.4, Activate, ref);
    }
    else if (client > 0 && BuildingType[client] != TFExtObject_Dispenser)
    {
        new String:classname[64];
        GetEdictClassname(ent, classname, sizeof(classname));
        if (StrEqual(classname, "obj_dispenser"))
        {
            type = BuildingType[ent] = BuildingType[client];

            BuildingOn[ent] = false;

            new bool:ampEnabled;
            new bool:rnEnabled;
            if (NativeControl)
            {
                ampEnabled = NativeAmplifier[client];
                rnEnabled = NativeRepairNode[client];
            }
            else
            {
                ampEnabled = AmplifierEnabled;
                rnEnabled = RepairNodeEnabled;
            }

            if (type == TFExtObject_Amplifier &&
                (force || (ampEnabled && DontAsk[client])))
            {
                if (NativeControl)
                {
                    ConvertToAmplifier(ent, NativeAmplifierPercent[client],
                                       NativeAmplifierRange[client],
                                       NativeCondition[client],
                                       4.0, DispCheckStage1);
                }
                else
                {
                    ConvertToAmplifier(ent, AmplifierPercent,
                                       DefaultAmplifierRange,
                                       DefaultCondition, 4.0,
                                       DispCheckStage1);
                }
            }
            else if (type == TFExtObject_RepairNode &&
                     (force || (rnEnabled && DontAsk[client])))
            {
                if (NativeControl)
                {
                    ConvertToRepairNode(ent, NativeRepairNodePercent[client], NativeRepairNodeRange[client],
                                        NativeRegen[client], NativeShells[client], NativeRockets[client],
                                        RepairNodeTeam[client], RepairNodeMini[client],
                                        4.0, DispCheckStage1);
                }
                else
                {
                    ConvertToRepairNode(ent, RepairNodePercent, DefaultRepairNodeRange,
                                        DefaultRegen, DefaultShells, DefaultRockets,
                                        DefaultTeam, DefaultMini, 4.0, DispCheckStage1);
                }
            }
            else if (ampEnabled || rnEnabled)
            {
                // Display a menu for the engineer to pick what to build
                new ref = EntIndexToEntRef(ent);
                new String:str[256], String:info[64];
                new Handle:menu = CreateMenu(BuildMenu);
                SetMenuTitle(menu, "%t","Build");

                Format(info,sizeof(info),"%d,1", ref);
                Format(str,sizeof(str),"%t","Dispenser");
                AddMenuItem(menu, info, str);

                Format(info,sizeof(info),"%d,2", ref);
                Format(str,sizeof(str),"%t","Amplifier"); 
                AddMenuItem(menu, info, str, (NativeControl ? NativeAmplifier[client] : AmplifierEnabled)
                                             ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

                Format(info,sizeof(info),"%d,3", ref);
                Format(str,sizeof(str),"%t","RepairNode"); 
                AddMenuItem(menu, info, str, (NativeControl ? NativeRepairNode[client] : RepairNodeEnabled)
                                             ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

                DisplayMenu(menu, client, 10);
            }
        }
    }
}

ConvertToAmplifier(ent, percent, const Float:range[4], TFCond:condition,
                   Float:delay, Timer:stageFunc, flags=0)
{
    new ref = BuildingRef[ent] = EntIndexToEntRef(ent);

    AmplifierCondition[ent] = condition;
    BuildingPercent[ent] = (percent < 0) ? AmplifierPercent : percent;
    BuildingType[ent] = TFExtObject_Amplifier;

    if (range[0] < 0.0)
        BuildingRange[ent] = DefaultAmplifierRange;
    else
        BuildingRange[ent] = range;

    decl String:modelname[128];
    Format(modelname,sizeof(modelname),"%s%s",AmplifierModel,".mdl");

    SetEntityModel(ent,modelname);
    SetEntProp(ent, Prop_Send, "m_nSkin", GetEntProp(ent, Prop_Send, "m_nSkin")+2);
    SetEntProp(ent, Prop_Send, "m_bDisabled", 1);

    CreateTimer(delay, stageFunc, ref, flags);
}

ConvertToRepairNode(ent, percent, const Float:range[4], const regen[4],
                    const shells[4], rockets, team, mini,
                    Float:delay, Timer:stageFunc, flags=0)
{
    new ref = BuildingRef[ent] = EntIndexToEntRef(ent);

    RepairNodeTeam[ent]  = (team < 0) ? DefaultTeam : bool:team;
    RepairNodeMini[ent]  = (mini < 0) ? DefaultMini : bool:mini;
    BuildingPercent[ent] = (percent < 0) ? RepairNodePercent : percent;
    BuildingType[ent] = TFExtObject_RepairNode;

    if (range[0] < 0.0)
        BuildingRange[ent] = DefaultRepairNodeRange;
    else        
        BuildingRange[ent] = range;

    if (regen[0] < 0)
        RepairNodeRegen[ent] = DefaultRegen;
    else
        RepairNodeRegen[ent] = regen;

    if (shells[0] < 0)
        RepairNodeShells[ent] = DefaultShells;
    else
        RepairNodeShells[ent] = shells;

    if (rockets < 0)
        RepairNodeRockets[ent] = DefaultRockets;
    else
        RepairNodeRockets[ent] = rockets;

    decl String:modelname[128];
    new level = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
    Format(modelname,sizeof(modelname),"%s%d%s",RepairNodeModel,level,".mdl");

    SetEntityModel(ent,modelname);
    SetEntProp(ent, Prop_Send, "m_bDisabled", 1);

    CreateTimer(delay, stageFunc, ref, flags);
}

public BuildMenu(Handle:menu,MenuAction:action,client,selection)
{
    if (action == MenuAction_Select)
    {
        decl String:Selection[2][32];
        decl String:SelectionInfo[64];
        GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo));
        ExplodeString(SelectionInfo,",",Selection,sizeof(Selection), sizeof(Selection[]));

        new ref = StringToInt(Selection[0]);
        new ent = EntRefToEntIndex(ref);
        if (ent > 0 && IsValidEntity(ent))
        {
            switch(StringToInt(Selection[1]))
            {
                case 2:
                {
                    if (NativeControl ? NativeAmplifier[client] : AmplifierEnabled)
                    {
                        if (NativeControl)
                        {
                            ConvertToAmplifier(ent, NativeAmplifierPercent[client],
                                               NativeAmplifierRange[client],
                                               NativeCondition[client],
                                               0.1, DispCheckStage2,
                                               TIMER_REPEAT);
                        }
                        else
                        {
                            ConvertToAmplifier(ent, AmplifierPercent,
                                               DefaultAmplifierRange,
                                               DefaultCondition, 0.1,
                                               DispCheckStage2,
                                               TIMER_REPEAT);
                        }
                    }
                    else
                    {
                        BuildingType[ent] = TFExtObject_Dispenser;
                    }
                }
                case 3:
                {
                    if (NativeControl ? NativeRepairNode[client] : RepairNodeEnabled)
                    {
                        if (NativeControl)
                        {
                            ConvertToRepairNode(ent, NativeRepairNodePercent[client],
                                                NativeRepairNodeRange[client], NativeRegen[client],
                                                NativeShells[client], NativeRockets[client],
                                                RepairNodeTeam[client], RepairNodeMini[client],
                                                0.1, DispCheckStage2, TIMER_REPEAT);
                        }
                        else
                        {
                            ConvertToRepairNode(ent, RepairNodePercent, DefaultRepairNodeRange,
                                                DefaultRegen, DefaultShells, DefaultRockets,
                                                DefaultTeam, DefaultMini, 0.1, DispCheckStage2,
                                                TIMER_REPEAT);
                        }
                    }
                    else
                    {
                        BuildingType[ent] = TFExtObject_Dispenser;
                    }
                }
                default:
                {
                    BuildingType[ent] = TFExtObject_Dispenser;
                }
            }
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}


//Wait 3 seconds before check model to change
public Action:DispCheckStage1(Handle:hTimer,any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0)
    {
        CreateTimer(0.1, DispCheckStage2, ref,
                    TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }

    return Plugin_Stop;
}

//Change model if it's not Amplifier's model
public Action:DispCheckStage2(Handle:hTimer,any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0 && IsValidEntity(ent))
    {
        if (GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") < 1.0)
            return Plugin_Continue;

        BuildingOn[ent]=true;

        decl String:modelname[128];
        if (BuildingType[ent] == TFExtObject_Amplifier)
        {
            Format(modelname,sizeof(modelname),"%s%s",AmplifierModel,".mdl");
            SetEntityModel(ent,modelname);
            //SetEntProp(ent, Prop_Send, "m_iUpgradeLevel", 3);
            SetEntProp(ent, Prop_Send, "m_nSkin", GetEntProp(ent, Prop_Send, "m_nSkin")-2);
        }
        else if (BuildingType[ent] == TFExtObject_RepairNode)
        {
            new level = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
            Format(modelname,sizeof(modelname),"%s%d%s",RepairNodeModel,level,".mdl");
            SetEntityModel(ent,modelname);
        }

        //KillTimer(hTimer);

        new particle;
        if (TFTeam:GetEntProp(ent, Prop_Send, "m_iTeamNum")==TFTeam_Red)
            AttachParticle(ent,"teleported_red",particle); //Create Effect of TP
        else
            AttachParticle(ent,"teleported_blue",particle); //Create Effect of TP

        CreateTimer(2.0, RemoveEntityTimer, EntIndexToEntRef(particle));
    }
    return Plugin_Stop;
}

//Wait for kill teleport effect
public Action:RemoveEntityTimer(Handle:hTimer,any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent > 0 && IsValidEntity(ent))
        AcceptEntityInput(ent, "kill");

	return Plugin_Stop;
}

//Create Crit Particle
AttachParticle(ent, String:particleType[],&particle)
{
    particle = CreateEntityByName("info_particle_system");
    if (particle > 0 && IsValidEdict(particle))
    {
        new String:tName[128];
        new Float:pos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

        Format(tName, sizeof(tName), "target%i", ent);
        DispatchKeyValue(ent, "targetname", tName);

        DispatchKeyValue(particle, "targetname", "TF2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        //SetVariantString("none");
        //AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
    }
}

stock CleanString(String:strBuffer[])
{
	// Cleanup any illegal characters
	new Length = strlen(strBuffer);
	for (new i=0; i<Length; i++)
	{
		switch(strBuffer[i])
		{
			case '\r': strBuffer[i] = ' ';
			case '\n': strBuffer[i] = ' ';
			case '\t': strBuffer[i] = ' ';
		}
	}

	// Trim string
	TrimString(strBuffer);
}

/**
 * Description: Native Interface
 */

public Native_ControlAmpNode(Handle:plugin,numParams)
{
	NativeControl = GetNativeCell(1);
}

public Native_SetBuildingType(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	BuildingType[client] = TFExtObjectType:GetNativeCell(2);
}

public Native_SetAmplifier(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);

    new TFCond:condition = TFCond:GetNativeCell(2);
    NativeCondition[client] = (condition < TFCond_Slowed) ? DefaultCondition : condition;

    new Float:range[4];
    GetNativeArray(3, range, sizeof(range));
    if (range[0] < 0.0)
        NativeAmplifierRange[client] = DefaultAmplifierRange;
    else
        NativeAmplifierRange[client] = range;

    new percent = GetNativeCell(4);
    NativeAmplifierPercent[client] = (percent < 0) ? AmplifierPercent : percent;

    NativeAmplifier[client] = bool:GetNativeCell(5);

    if (GetNativeCell(6))
        BuildingType[client] = TFExtObject_Amplifier;
}

public Native_SetRepairNode(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);

    new Float:range[4];
    GetNativeArray(2, range, sizeof(range));
    if (range[0] < 0.0)
        NativeRepairNodeRange[client] = DefaultRepairNodeRange;
    else        
        NativeRepairNodeRange[client] = range;

    new rate[4];
    GetNativeArray(3, rate, sizeof(rate));
    if (rate[0] < 0)
        NativeRegen[client] = DefaultRegen;
    else
        NativeRegen[client] = rate;

    GetNativeArray(4, rate, sizeof(rate));
    if (rate[0] < 0)
        NativeShells[client] = DefaultShells;
    else
        NativeShells[client] = rate;

    new rockets = GetNativeCell(5);
    NativeRockets[client] = (rockets < 0) ? DefaultRockets : rockets;

    new team = GetNativeCell(6);
    RepairNodeTeam[client] = (team < 0) ? DefaultTeam : bool:team;

    new mini = GetNativeCell(7);
    RepairNodeMini[client] = (mini < 0) ? DefaultMini : bool:mini;

    new percent = GetNativeCell(8);
    NativeRepairNodePercent[client] = (percent < 0) ? RepairNodePercent : percent;

    NativeRepairNode[client] = bool:GetNativeCell(9);

    if (GetNativeCell(10))
        BuildingType[client] = TFExtObject_RepairNode;
}

public Native_CountConvertedBuildings(Handle:plugin,numParams)
{
    new count = 0;
    new client = GetNativeCell(1);
    new TFExtObjectType:type = GetNativeCell(2);
    new maxEntities = GetMaxEntities();
    for (new i=MaxClients+1;i<maxEntities;i++)
    {
        if (BuildingType[i] == type)
        {
            new ampent = EntRefToEntIndex(BuildingRef[i]);
            if (ampent > 0)
            {
                if (GetEntPropEnt(ampent, Prop_Send, "m_hBuilder") == client)
                    count++;
            }
        }
    }
    return count;
}

public Native_ConvertToAmplifier(Handle:plugin,numParams)
{
    new ent = GetNativeCell(1);
    if (ent > 0 && IsValidEntity(ent))
    {
        new client = GetNativeCell(2);
        new TFCond:condition = TFCond:GetNativeCell(3);

        new Float:range[4];
        GetNativeArray(4, range, sizeof(range));

        new percent = GetNativeCell(5);

        if (BuildingType[ent] != TFExtObject_Amplifier)
        {
            if (condition < TFCond_Slowed)
                condition = NativeCondition[client];

            if (percent < 0)
                percent = NativeAmplifierPercent[client];

            if (range[0] < 0.0)
                range = NativeAmplifierRange[client];

            ConvertToAmplifier(ent, percent, range, condition,
                               0.1, DispCheckStage2, TIMER_REPEAT);
        }
        else
        {
            if (condition >= TFCond_Slowed)
                AmplifierCondition[ent] = condition;

            if (percent >= 0)
                BuildingPercent[ent] = percent;

            if (range[0] >= 0.0)
                BuildingRange[ent] = range;
        }
    }
}

public Native_ConvertToRepairNode(Handle:plugin,numParams)
{
    new ent = GetNativeCell(1);
    if (ent > 0 && IsValidEntity(ent))
    {
        new client = GetNativeCell(2);

        new Float:range[4];
        GetNativeArray(3, range, sizeof(range));

        new regen[4];
        GetNativeArray(4, regen, sizeof(regen));

        new shells[4];
        GetNativeArray(5, shells, sizeof(shells));

        new rockets = GetNativeCell(6);
        new team = GetNativeCell(7);
        new mini = GetNativeCell(8);
        new percent = GetNativeCell(9);

        if (BuildingType[ent] != TFExtObject_RepairNode)
        {
            if (percent < 0)
                percent = NativeRepairNodePercent[client];

            if (team < 0)
                team = RepairNodeTeam[client];

            if (mini < 0)
                mini = RepairNodeMini[client];

            if (range[0] < 0.0)
                range = NativeRepairNodeRange[client];

            if (regen[0] < 0)
                regen = NativeRegen[client];

            if (shells[0] < 0)
                shells = NativeShells[client];

            if (rockets < 0)
                rockets = NativeRockets[client];

            ConvertToRepairNode(ent, percent, range, regen, shells, rockets,
                                team, mini, 0.1, DispCheckStage2, TIMER_REPEAT);
        }
        else
        {
            if (percent >= 0)
                BuildingPercent[ent] = percent;

            if (team >= 0)
                RepairNodeTeam[ent] = bool:team;

            if (mini >= 0)
                RepairNodeMini[ent] = bool:mini;

            if (range[0] >= 0.0)
                BuildingRange[ent] = range;

            if (regen[0] >= 0)
                RepairNodeRegen[ent] = regen;

            if (shells[0] >= 0)
                RepairNodeShells[ent] = shells;

            if (rockets >= 0)
                RepairNodeRockets[ent] = rockets;
        }
    }
}

/**
 * Description: Ray Trace functions and variables
 */
#tryinclude <raytrace>
#if !defined _raytrace_included
    stock bool:TraceTargetIndex(client, target, Float:clientLoc[3], Float:targetLoc[3])
    {
        targetLoc[2] += 50.0; // Adjust trace position of target
        TR_TraceRayFilter(clientLoc, targetLoc, MASK_SOLID,
                          RayType_EndPoint, TraceRayDontHitSelf,
                          client);

        return (!TR_DidHit() || TR_GetEntityIndex() == target);
    }

    /***************
     *Trace Filters*
    ****************/

    public bool:TraceRayDontHitSelf(entity, mask, any:data)
    {
        return (entity != data); // Check if the TraceRay hit the owning entity.
    }
#endif

/**
 * Description: Functions to show TF2 particles
 */
#tryinclude <particle>
#if !defined _particle_included
    stock DeleteParticle(&particleRef)
    {
        if (particleRef != INVALID_ENT_REFERENCE)
        {
            new particle = EntRefToEntIndex(particleRef);
            if (particle > 0 && IsValidEntity(particle))
                AcceptEntityInput(particle, "kill");

            particleRef = INVALID_ENT_REFERENCE;
        }
    }
#endif

/**
 *  Native Interface to ztf2grab (gravgun)
 */
#undef REQUIRE_PLUGIN
#tryinclude "ztf2grab"
#if defined _ztf2grab_included
    public Action:OnPickupObject(client, builder, ent)
    {
        if (BuildingRef[ent] != INVALID_ENT_REFERENCE && EntRefToEntIndex(BuildingRef[ent]) == ent)
        {
            switch (AmplifierCondition[ent])
            {
                case TFCond_Ubercharged, TFCond_Kritzkrieged, TFCond_Buffed:
                    return Plugin_Stop;
            }
        }
        return Plugin_Continue;
    }
#endif

