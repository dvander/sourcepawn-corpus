/*
// ====================================================================================================
Based completely on Marts 
[L4D1 & L4D2] Tank Car Smash [v1.0.1 | 09-November-2021]
https://forums.alliedmods.net/showthread.php?t=335105

// ====================================================================================================

Change Log:
1.0.6 (02-August-2022)
	extra check for models/props_vehicles/generator (in hospital map after elevator)
1.0.5 (22-April-2022)
	set rendercolor to 0 0 0 for the purple parts in l4d2 as workaround
1.0.4 (09-January-2022)
	extra check for models/props_vehicles/train // custom maps as physics override
1.0.3 (10-December-2021)
	extra check for models/props_vehicles/airport_baggage_cart2.mdl
1.0.2 (1-December-2021)
	auto cleanup of entity mess
1.0.1 (20-November-2021)
	cvar chance added
	vertical movement added
1.0.0 (16-November-2021)
    - Initial release.
// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1] Boatstyle cars"
#define PLUGIN_AUTHOR                 "Finishlast"
#define PLUGIN_DESCRIPTION            "Tank punch will have a default chance of 5% to completely smash the car."
#define PLUGIN_VERSION                "1.0.6"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?p=2764719"

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
#define CONFIG_FILENAME               "l4d_boatstyle_cars"

// ====================================================================================================
// Defines
// ====================================================================================================

#define SOUND_GLASS_SHEET_BREAK1			"physics/glass/glass_sheet_break1.wav"
#define SOUND_GLASS_SHEET_BREAK2			"physics/glass/glass_sheet_break2.wav"
#define SOUND_GLASS_SHEET_BREAK3			"physics/glass/glass_sheet_break3.wav"
#define CAR_PARTS1							"models/props_vehicles/tire001c_car.mdl"
#define CAR_PARTS3							"models/props_unique/subwaycarexterior01_enddoor01_damaged01.mdl"
#define CAR_PARTS4							"models/props_unique/subwaycarexterior01_enddoor01_damaged02.mdl"
#define CAR_PARTS5							"models/props_unique/subwaycarexterior01_enddoor01_damaged03.mdl"
#define CAR_PARTS6							"models/props_unique/subwaycarexterior01_enddoor01_damaged04.mdl"
#define CAR_PARTS7							"models/props_unique/subwaycarexterior01_enddoor01_damaged05.mdl"
#define CAR_PARTS8							"models/props_unique/subwaycarexterior01_sidedoor01_damaged_01.mdl"
#define CAR_PARTS9							"models/props_unique/subwaycarexterior01_sidedoor01_damaged_02.mdl"
#define CAR_PARTS10							"models/props_unique/subwaycarexterior01_sidedoor01_damaged_03.mdl"
#define CAR_PARTS11							"models/props_unique/subwaycarexterior01_sidedoor01_damaged_04.mdl"
#define CAR_PARTS12							"models/props_vehicles/helicopter_crashed_chunk04.mdl"
#define CAR_PARTS15							"models/props_vehicles/helicopter_crashed_chunk07.mdl"
#define CAR_PARTS56							"models/props_vehicles/helicopter_crashed_chunk08.mdl"

#define TEAM_INFECTED                 3
#define L4D1_ZOMBIECLASS_TANK         5
#define L4D2_ZOMBIECLASS_TANK         8
#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_DeleteChilds;
static ConVar g_hCvar_GlassSound;
static ConVar g_hCvar_DestroyChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_DeleteChilds;
static bool   g_bCvar_GlassSound;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iTankClass;
static int    g_iCvar_DestroyChance;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static bool   ge_bOnTakeDamagePostHooked[MAXENTITIES+1];
//tires
int ent_carpart1;
int ent_carpart1b;
int ent_carpart1c;
int ent_carpart1d;
//metal junk
int ent_carpart3;
int ent_carpart4;
int ent_carpart5;
int ent_carpart6;
int ent_carpart7;
int ent_carpart8;
int ent_carpart9;
int ent_carpart10;
int ent_carpart11;
int ent_carpart12;
int ent_carpart13;
int ent_carpart14;
int ent_carpart15;
int ent_carpart16;
int ent_carpart17;
int ent_carpart18;
int ent_carpart19;
int ent_carpart20;
int ent_carpart21;
int ent_carpart22;
int ent_carpart23;
int ent_carpart24;
int ent_carpart25;
int ent_carpart26;
int ent_carpart27;
int ent_carpart28;
//chairs
int ent_carpart56;
int ent_carpart56b;
int ent_carpart56c;
int ent_carpart56d;
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
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_tank_car_smash_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled      = CreateConVar("l4d_boatstyle_cars_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DestroyChance = CreateConVar("l4d_boatstyle_cars_DestroyChance", 		"5", 	"Percent chance a tank punch can detroy a car. 1-100", CVAR_FLAGS);
    g_hCvar_DeleteChilds = CreateConVar("l4d_boatstyle_cars_delete_childs", "1", "Delete attached entities (child) from the car.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GlassSound   = CreateConVar("l4d_boatstyle_cars_glass_sound", "1", "Emit a random breaking glass sound on car hit (only once).\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DestroyChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeleteChilds.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlassSound.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_boatlike_cars", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
PrecacheModel(CAR_PARTS1, true);
PrecacheModel(CAR_PARTS3, true);
PrecacheModel(CAR_PARTS4, true);
PrecacheModel(CAR_PARTS5, true);
PrecacheModel(CAR_PARTS6, true);
PrecacheModel(CAR_PARTS7, true);
PrecacheModel(CAR_PARTS8, true);
PrecacheModel(CAR_PARTS9, true);
PrecacheModel(CAR_PARTS10, true);
PrecacheModel(CAR_PARTS11, true);
PrecacheModel(CAR_PARTS12, true);
PrecacheModel(CAR_PARTS15, true);
PrecacheModel(CAR_PARTS56, true);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    PrecacheSounds();

    LateLoad();
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    PrecacheSounds();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_DeleteChilds = g_hCvar_DeleteChilds.BoolValue;
    g_bCvar_GlassSound = g_hCvar_GlassSound.BoolValue;
    g_iCvar_DestroyChance = g_hCvar_DestroyChance.IntValue;
}

/****************************************************************************************************/

void PrecacheSounds()
{
    if (g_bCvar_Enabled && g_bCvar_GlassSound)
    {
        PrecacheSound(SOUND_GLASS_SHEET_BREAK1);
        PrecacheSound(SOUND_GLASS_SHEET_BREAK2);
        PrecacheSound(SOUND_GLASS_SHEET_BREAK3);
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
            RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEntityIndex(entity))
        return;

    ge_bOnTakeDamagePostHooked[entity] = false;

}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'p')
        return;

    if (!HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
        return;

    SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
	if (ge_bOnTakeDamagePostHooked[entity])
		return;

	char modelname[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
	StringToLowerCase(modelname);

	

//boat model for some reason shows with \ instead of / ?!?  I set string contains now to check for boat / I couldn't get strcmp to work 
	if(strncmp(modelname, "models/props_vehicles", 21) == 0 && StrContains(modelname, "boat", false) == -1 && strncmp(modelname, "models/props_vehicles/generator", 31) != 0 && strncmp(modelname, "models/props_vehicles/airport", 29) != 0 && strncmp(modelname, "models/props_vehicles/train", 27) != 0 && strncmp(modelname, "models/props_vehicles/heli", 26) != 0  && strncmp(modelname, "models/props_vehicles/carp", 26) != 0 && strncmp(modelname, "models/props_vehicles/tire", 26) != 0)
	{

		ge_bOnTakeDamagePostHooked[entity] = true;
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		return;
	}
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

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	float vPos[3], vAng[3], vDir[3], vPosTemp[3], vDirTemp[3];


	char sWeapon[PLATFORM_MAX_PATH];

	if (!g_bCvar_Enabled)
		return;

	if (!IsValidClient(attacker))
		return;

	if (GetClientTeam(attacker) != TEAM_INFECTED)
		return;

	if (GetZombieClass(attacker) != g_iTankClass)
		return;
	
	GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));
	if(strncmp(sWeapon, "tank_r", 6) == 0)
		return;

	int tempchance=GetRandomInt(1, 100);

	if(tempchance <= g_iCvar_DestroyChance)
	{
			PrintToChatAll("[SM] Tank smashed the car!");
		}
	else
		{
			return;
	}
	
	SDKUnhook(victim, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

	if (g_bCvar_DeleteChilds)
	{
		int entity = INVALID_ENT_REFERENCE;
		while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
		{
			if (HasEntProp(entity, Prop_Send, "moveparent") && victim == GetEntPropEnt(entity, Prop_Send, "moveparent"))
			AcceptEntityInput(entity, "Kill");
		}
	}

	if (g_bCvar_GlassSound)
	{
		switch (GetRandomInt(1,3))
		{
			case 1: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK1, victim);
			case 2: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK2, victim);
			case 3: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK3, victim);
		}
	}

	GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(victim, Prop_Send, "m_angRotation", vAng);

	AcceptEntityInput(victim, "Kill");
//** spawn lots of car parts
//tires
	ent_carpart1 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart1, "model", CAR_PARTS1);
	DispatchKeyValue(ent_carpart1, "solid", "0");
	DispatchKeyValue(ent_carpart1, "disableshadows", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart1, "AddOutput");
	AcceptEntityInput(ent_carpart1, "FireUser1"); 
	DispatchSpawn(ent_carpart1);

	ent_carpart1b = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart1b, "model", CAR_PARTS1);
	DispatchKeyValue(ent_carpart1b, "solid", "0");
	DispatchKeyValue(ent_carpart1b, "disableshadows", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart1b, "AddOutput");
	AcceptEntityInput(ent_carpart1b, "FireUser1"); 
	DispatchSpawn(ent_carpart1b);

	ent_carpart1c = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart1c, "model", CAR_PARTS1);
	DispatchKeyValue(ent_carpart1c, "solid", "0");
	DispatchKeyValue(ent_carpart1c, "disableshadows", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart1c, "AddOutput");
	AcceptEntityInput(ent_carpart1c, "FireUser1"); 
	DispatchSpawn(ent_carpart1c);

	ent_carpart1d = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart1d, "model", CAR_PARTS1);
	DispatchKeyValue(ent_carpart1d, "solid", "0");
	DispatchKeyValue(ent_carpart1d, "disableshadows", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart1d, "AddOutput");
	AcceptEntityInput(ent_carpart1d, "FireUser1"); 
	DispatchSpawn(ent_carpart1d);

//chairs

	ent_carpart56 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart56, "model", CAR_PARTS56);
	DispatchKeyValue(ent_carpart56, "solid", "0");
	DispatchKeyValue(ent_carpart56, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart56, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart56, "AddOutput");
	AcceptEntityInput(ent_carpart56, "FireUser1");
	DispatchSpawn(ent_carpart56);

	ent_carpart56b = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart56b, "model", CAR_PARTS56);
	DispatchKeyValue(ent_carpart56b, "solid", "0");
	DispatchKeyValue(ent_carpart56b, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart56b, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart56b, "AddOutput");
	AcceptEntityInput(ent_carpart56b, "FireUser1");

	DispatchSpawn(ent_carpart56b);

	ent_carpart56c = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart56c, "model", CAR_PARTS56);
	DispatchKeyValue(ent_carpart56c, "solid", "0");
	DispatchKeyValue(ent_carpart56c, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart56c, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart56c, "AddOutput");
	AcceptEntityInput(ent_carpart56c, "FireUser1");
	DispatchSpawn(ent_carpart56c);

	ent_carpart56d = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart56d, "model", CAR_PARTS56);
	DispatchKeyValue(ent_carpart56d, "solid", "0");
	DispatchKeyValue(ent_carpart56d, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart56d, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart56d, "AddOutput");
	AcceptEntityInput(ent_carpart56d, "FireUser1");
	DispatchSpawn(ent_carpart56d);
//junk

	ent_carpart3 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart3, "model", CAR_PARTS3);
	DispatchKeyValue(ent_carpart3, "solid", "0");
	DispatchKeyValue(ent_carpart3, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart3, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart3, "AddOutput");
	AcceptEntityInput(ent_carpart3, "FireUser1");
	DispatchSpawn(ent_carpart3);

	ent_carpart4 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart4, "model", CAR_PARTS4);
	DispatchKeyValue(ent_carpart4, "solid", "0");
	DispatchKeyValue(ent_carpart4, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart4, "rendercolor", "0 0 0");
	}

	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart4, "AddOutput");
	AcceptEntityInput(ent_carpart4, "FireUser1");
	DispatchSpawn(ent_carpart4);

	ent_carpart5 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart5, "model", CAR_PARTS5);
	DispatchKeyValue(ent_carpart5, "solid", "0");
	DispatchKeyValue(ent_carpart5, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart5, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart5, "AddOutput");
	AcceptEntityInput(ent_carpart5, "FireUser1");
	DispatchSpawn(ent_carpart5);

	ent_carpart6 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart6, "model", CAR_PARTS6);
	DispatchKeyValue(ent_carpart6, "solid", "0");
	DispatchKeyValue(ent_carpart6, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart6, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart6, "AddOutput");
	AcceptEntityInput(ent_carpart6, "FireUser1");
	DispatchSpawn(ent_carpart6);

	ent_carpart7 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart7, "model", CAR_PARTS7);
	DispatchKeyValue(ent_carpart7, "solid", "0");
	DispatchKeyValue(ent_carpart7, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart7, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart7, "AddOutput");
	AcceptEntityInput(ent_carpart7, "FireUser1");
	DispatchSpawn(ent_carpart7);

	ent_carpart8 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart8, "model", CAR_PARTS8);
	DispatchKeyValue(ent_carpart8, "solid", "0");
	DispatchKeyValue(ent_carpart8, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart8, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart8, "AddOutput");
	AcceptEntityInput(ent_carpart8, "FireUser1");
	DispatchSpawn(ent_carpart8);

	ent_carpart9 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart9, "model", CAR_PARTS9);
	DispatchKeyValue(ent_carpart9, "solid", "0");
	DispatchKeyValue(ent_carpart9, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart9, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart9, "AddOutput");
	AcceptEntityInput(ent_carpart9, "FireUser1");
	DispatchSpawn(ent_carpart9);

	ent_carpart10 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart10, "model", CAR_PARTS10);
	DispatchKeyValue(ent_carpart10, "solid", "0");
	DispatchKeyValue(ent_carpart10, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart10, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart10, "AddOutput");
	AcceptEntityInput(ent_carpart10, "FireUser1");
	DispatchSpawn(ent_carpart10);

	ent_carpart11 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart11, "model", CAR_PARTS11);
	DispatchKeyValue(ent_carpart11, "solid", "0");
	DispatchKeyValue(ent_carpart11, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart11, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart11, "AddOutput");
	AcceptEntityInput(ent_carpart11, "FireUser1");
	DispatchSpawn(ent_carpart11);

	ent_carpart12 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart12, "model", CAR_PARTS12);
	DispatchKeyValue(ent_carpart12, "solid", "0");
	DispatchKeyValue(ent_carpart12, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart12, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart12, "AddOutput");
	AcceptEntityInput(ent_carpart12, "FireUser1");
	DispatchSpawn(ent_carpart12);

	ent_carpart13 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart13, "model", CAR_PARTS6);
	DispatchKeyValue(ent_carpart13, "solid", "0");
	DispatchKeyValue(ent_carpart13, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart13, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart13, "AddOutput");
	AcceptEntityInput(ent_carpart13, "FireUser1");
	DispatchSpawn(ent_carpart13);

	ent_carpart14 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart14, "model", CAR_PARTS3);
	DispatchKeyValue(ent_carpart14, "solid", "0");
	DispatchKeyValue(ent_carpart14, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart14, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart14, "AddOutput");
	AcceptEntityInput(ent_carpart14, "FireUser1");
	DispatchSpawn(ent_carpart14);

	ent_carpart15 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart15, "model", CAR_PARTS4);
	DispatchKeyValue(ent_carpart15, "solid", "0");
	DispatchKeyValue(ent_carpart15, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart15, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart15, "AddOutput");
	AcceptEntityInput(ent_carpart15, "FireUser1");
	DispatchSpawn(ent_carpart15);

	ent_carpart16 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart16, "model", CAR_PARTS5);
	DispatchKeyValue(ent_carpart16, "solid", "0");
	DispatchKeyValue(ent_carpart16, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart16, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart16, "AddOutput");
	AcceptEntityInput(ent_carpart16, "FireUser1");
	DispatchSpawn(ent_carpart16);

	ent_carpart17 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart17, "model", CAR_PARTS6);
	DispatchKeyValue(ent_carpart17, "solid", "0");
	DispatchKeyValue(ent_carpart17, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart17, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart17, "AddOutput");
	AcceptEntityInput(ent_carpart17, "FireUser1");
	DispatchSpawn(ent_carpart17);

	ent_carpart18 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart18, "model", CAR_PARTS7);
	DispatchKeyValue(ent_carpart18, "solid", "0");
	DispatchKeyValue(ent_carpart18, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart18, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart18, "AddOutput");
	AcceptEntityInput(ent_carpart18, "FireUser1");
	DispatchSpawn(ent_carpart18);

	ent_carpart19 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart19, "model", CAR_PARTS8);
	DispatchKeyValue(ent_carpart19, "solid", "0");
	DispatchKeyValue(ent_carpart19, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart19, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart19, "AddOutput");
	AcceptEntityInput(ent_carpart19, "FireUser1");
	DispatchSpawn(ent_carpart19);

	ent_carpart20 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart20, "model", CAR_PARTS9);
	DispatchKeyValue(ent_carpart20, "solid", "0");
	DispatchKeyValue(ent_carpart20, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart20, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart20, "AddOutput");
	AcceptEntityInput(ent_carpart20, "FireUser1");
	DispatchSpawn(ent_carpart20);

	ent_carpart21 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart21, "model", CAR_PARTS10);
	DispatchKeyValue(ent_carpart21, "solid", "0");
	DispatchKeyValue(ent_carpart21, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart21, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart21, "AddOutput");
	AcceptEntityInput(ent_carpart21, "FireUser1");
	DispatchSpawn(ent_carpart21);

	ent_carpart22 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart22, "model", CAR_PARTS11);
	DispatchKeyValue(ent_carpart22, "solid", "0");
	DispatchKeyValue(ent_carpart22, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart22, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart22, "AddOutput");
	AcceptEntityInput(ent_carpart22, "FireUser1");
	DispatchSpawn(ent_carpart22);

	ent_carpart23 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart23, "model", CAR_PARTS12);
	DispatchKeyValue(ent_carpart23, "solid", "0");
	DispatchKeyValue(ent_carpart23, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart23, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart23, "AddOutput");
	AcceptEntityInput(ent_carpart23, "FireUser1");
	DispatchSpawn(ent_carpart23);

	ent_carpart24 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart24, "model", CAR_PARTS6);
	DispatchKeyValue(ent_carpart24, "solid", "0");
	DispatchKeyValue(ent_carpart24, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart24, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart24, "AddOutput");
	AcceptEntityInput(ent_carpart24, "FireUser1");
	DispatchSpawn(ent_carpart24);

	ent_carpart25 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart25, "model", CAR_PARTS4);
	DispatchKeyValue(ent_carpart25, "solid", "0");
	DispatchKeyValue(ent_carpart25, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart25, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart25, "AddOutput");
	AcceptEntityInput(ent_carpart25, "FireUser1");
	DispatchSpawn(ent_carpart25);

	ent_carpart26 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart26, "model", CAR_PARTS4);
	DispatchKeyValue(ent_carpart26, "solid", "0");
	DispatchKeyValue(ent_carpart26, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart26, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart26, "AddOutput");
	AcceptEntityInput(ent_carpart26, "FireUser1");
	DispatchSpawn(ent_carpart26);

	ent_carpart27 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart27, "model", CAR_PARTS9);
	DispatchKeyValue(ent_carpart27, "solid", "0");
	DispatchKeyValue(ent_carpart27, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart27, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart27, "AddOutput");
	AcceptEntityInput(ent_carpart27, "FireUser1");
	DispatchSpawn(ent_carpart27);

	ent_carpart28 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_carpart28, "model", CAR_PARTS9);
	DispatchKeyValue(ent_carpart28, "solid", "0");
	DispatchKeyValue(ent_carpart28, "disableshadows", "1");
	if(g_iTankClass==8)
	{
		DispatchKeyValue(ent_carpart28, "rendercolor", "0 0 0");
	}
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_carpart28, "AddOutput");
	AcceptEntityInput(ent_carpart28, "FireUser1");
	DispatchSpawn(ent_carpart28);

//**

	vPos[2] += 50;

	GetClientEyePosition(attacker, vPos);
	GetClientEyeAngles(attacker, vAng);
	//PrintToChatAll("The ang float: %-.2f", vAng[1]); 

	if(vAng[1] >= -160.0 && vAng[1] <= -145.0 ){
	vDir[1] = -400.0;
	vDir[0] = -400.0;
	//PrintToChatAll(" -- 145  ? --");
	}
	else if(vAng[1] >= -144.0 && vAng[1] <= -54.0 ){
	vDir[1] = -400.0;
	vDir[0] = 0.0;
	//PrintToChatAll(" -- 90  ? --");
	}
	else if(vAng[1] >= -45.0 && vAng[1] <= -21.0 ){
	vDir[1] = -400.0;
	vDir[0] = 400.0;
	//PrintToChatAll(" -- 45  ? --");
	}
	else if(vAng[1] >= -20.0 && vAng[1] <= 20.0 ){
	vDir[1] = 0.0;
	vDir[0] = 400.0;
	//PrintToChatAll(" -- 0  ? --");
	}
       	else if(vAng[1] >= 21.0 && vAng[1] <= 69.0 ){
	vDir[1] = 400.0;
	vDir[0] = 400.0;
	//PrintToChatAll(" -- 45  ? --");
	}	
	else if(vAng[1] >= 70.0 && vAng[1] <= 110.0 ){
	vDir[1] = 400.0;
	vDir[0] = 0.0;
	//PrintToChatAll(" -- -90  ? --");
	}
	else if(vAng[1] >= 111.0 && vAng[1] <= 160.0 ){
	vDir[1] = 400.0;
	vDir[0] = -400.0;
	//PrintToChatAll(" -- -145  ? --");
	}
	else if((vAng[1] <= -161.0 && vAng[1] >= -179.0)||(vAng[1] <= 180.0 && vAng[1] >= 161.0)){
	vDir[1] = 0.0;
	vDir[0] = -400.0;
	//PrintToChatAll(" -- 180  ? --");
	}

	vPos[0] += 164 * Cosine(DegToRad(vAng[1])); 
	vPos[1] += 164 * Sine(DegToRad(vAng[1]));
	vDir[2] = 0.0;

	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vPosTemp[2]=vPos[2];

	vDirTemp[0]=vDir[0];
	vDirTemp[1]=vDir[1];
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);

	TeleportEntity(ent_carpart1, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart1b, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart1c, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart1d, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart56, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart56b, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart56c, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart56d, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart3, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart4, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart5, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart6, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart7, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart8, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart9, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart10, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart11, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart12, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart13, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart14, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart15, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart16, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart17, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart18, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart19, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart20, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart21, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart22, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart23, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart24, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart25, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart26, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart27, vPosTemp, vAng, vDirTemp);
	vPosTemp[0]=vPos[0]+GetRandomInt(1, 100);
	vPosTemp[1]=vPos[1]+GetRandomInt(1, 100);
	vDirTemp[2]=vDir[2]+GetRandomInt(1, 400);
	TeleportEntity(ent_carpart28, vPosTemp, vAng, vDirTemp);

	CreateTimer(1.5, changevDir);

}


public Action changevDir(Handle timer)
{
	float vPos[3], vAng[3], vDir[3];
	vDir[0] = 0.0;
	vDir[1] = 0.0;
	vDir[2] = 0.0;

	GetEntPropVector(ent_carpart1, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart1, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart1, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart1b, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart1b, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart1b, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart1c, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart1c, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart1c, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart1d, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart1d, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart1d, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart56, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart56, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart56, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart56b, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart56b, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart56b, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart56c, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart56c, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart56c, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart56d, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart56d, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart56d, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart3, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart3, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart3, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart4, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart4, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart4, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart5, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart5, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart5, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart6, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart6, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart6, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart7, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart7, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart7, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart8, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart8, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart8, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart9, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart9, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart9, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart10, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart10, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart10, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart11, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart11, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart11, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart12, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart12, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart12, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart13, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart13, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart13, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart13, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart13, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart13, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart14, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart14, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart14, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart15, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart15, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart15, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart16, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart16, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart16, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart17, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart17, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart17, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart18, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart18, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart18, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart19, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart19, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart19, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart20, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart20, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart20, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart21, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart21, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart21, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart22, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart22, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart22, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart23, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart23, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart23, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart24, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart24, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart24, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart24, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart24, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart24, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart25, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart25, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart25, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart26, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart26, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart26, vPos, vAng, vDir);

	GetEntPropVector(ent_carpart27, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart27, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart27, vPos, vAng, vDir);
	
	GetEntPropVector(ent_carpart28, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_carpart28, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_carpart28, vPos, vAng, vDir);


}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d_tank_car_smash) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_boatstyle_cars_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_boatstyle_cars_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_boatstyle_cars_delete_childs : %b (%s)", g_bCvar_DeleteChilds, g_bCvar_DeleteChilds ? "true" : "false");
    PrintToConsole(client, "l4d_boatstyle_cars_glass_sound : %b (%s)", g_bCvar_GlassSound, g_bCvar_GlassSound ? "true" : "false");
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
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client     Client index.
 * @return L4D1      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/****************************************************************************************************/

/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}