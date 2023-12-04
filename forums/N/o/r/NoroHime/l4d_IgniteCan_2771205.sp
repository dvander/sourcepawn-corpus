#define PLUGIN_VERSION "1.2"
#define CVAR_FLAGS FCVAR_NOTIFY

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

char MODEL_GASCAN[] = "models/props_junk/gascan001a.mdl";
char MODEL_OXYGEN[] = "models/props_equipment/oxygentank01.mdl";
char MODEL_PROPANE[] = "models/props_junk/propanecanister001a.mdl";
char MODEL_FIREWORKS[] = "models/props_junk/explosive_box001.mdl";

int IDX_GASCAN = -1;
int IDX_OXYGEN = -1;
int IDX_PROPANE = -1;
int IDX_FIREWORKS = -1;
int g_iIgniter;

ConVar hPluginEnable;
ConVar hIgniteGascan;
ConVar hIgniteOxygen;
ConVar hIgnitePropane;
ConVar hIgniteFireworks;

bool g_bLeft4Dead2;
bool g_bEnabled;
bool g_bIgniteGascan;
bool g_bIgniteOxygen;
bool g_bIgnitePropane;
bool g_bIgniteFireworks;

bool g_bDoIgnite;

/*
	ChangeLog:

	1.0 (10-Dec-2019)
	 - First release.
	 
	1.1 (24-Apr-2021) by Marttt
	 - Fixed support for L4D2 to ignite gascan.
	 - Added support for igniting: fireworks crate.
	 - Added ConVar "l4d_ignitecan_enable" - Enable plugin (1 - Yes, 0 - No)
	 - Added ConVar "l4d_ignitecan_gascan" - Enable gascan to ignite (1 - Yes, 0 - No)
	 - Added ConVar "l4d_ignitecan_oxygen" - Enable oxygen to ignite (1 - Yes, 0 - No)
	 - Added ConVar "l4d_ignitecan_propane" - Enable propane to ignite (1 - Yes, 0 - No)
	 - Added ConVar "l4d_ignitecan_fireworkscrate" - Enable fireworks to ignite (1 - Yes, 0 - No)
	 - Added other safe checks.
	
	1.2 (04-Nov-2021)
	 - Added igniter index to AcceptEntityInput to be able to track who ignited the canister.
	
*/

public Plugin myinfo =
{
	name = "[L4D] Ignite Canister",
	author = "Dragokas & Marttt (Idea by AlexMy)",
	description = "Ignite canister during the throw by pressing R + Fire (throw)",
	version = PLUGIN_VERSION,
	url = "www.dragokas.com"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead2 ) {
		g_bLeft4Dead2 = true;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_ignitecan_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);

	hPluginEnable 		= CreateConVar("l4d_ignitecan_enable", 	"1", "Enable plugin (1 - Yes, 0 - No)", CVAR_FLAGS, true, 0.0, true, 1.0);
	hIgniteGascan 		= CreateConVar("l4d_ignitecan_gascan", 	"1", "Enable gascan to ignite (1 - Yes, 0 - No)", CVAR_FLAGS, true, 0.0, true, 1.0);
	hIgniteOxygen 		= CreateConVar("l4d_ignitecan_oxygen", 	"1", "Enable oxygen to ignite (1 - Yes, 0 - No)", CVAR_FLAGS, true, 0.0, true, 1.0);
	hIgnitePropane 		= CreateConVar("l4d_ignitecan_propane", "1", "Enable propane to ignite (1 - Yes, 0 - No)", CVAR_FLAGS, true, 0.0, true, 1.0);
	if( g_bLeft4Dead2 ) {
		hIgniteFireworks = CreateConVar("l4d_ignitecan_fireworkscrate", "1", "Enable fireworks to ignite (1 - Yes, 0 - No)", CVAR_FLAGS, true, 0.0, true, 1.0);
	}

	GetCvars();

	hPluginEnable.AddChangeHook(OnCvarChanged);
	hIgniteGascan.AddChangeHook(OnCvarChanged);
	hIgniteOxygen.AddChangeHook(OnCvarChanged);
	hIgnitePropane.AddChangeHook(OnCvarChanged);

	if( g_bLeft4Dead2 ) {
		hIgniteFireworks.AddChangeHook(OnCvarChanged);
	}
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = hPluginEnable.BoolValue;
	g_bIgniteGascan = hIgniteGascan.BoolValue;
	g_bIgniteOxygen = hIgniteOxygen.BoolValue;
	g_bIgnitePropane = hIgnitePropane.BoolValue;

	if( g_bLeft4Dead2 )
	{
		g_bIgniteFireworks = hIgniteFireworks.BoolValue;
		InitHook();
	}
}

void InitHook()
{
	static bool bHooked;

	if( g_bEnabled ) {
		if( !bHooked ) {
			HookEvent("weapon_drop", Event_OnWeaponDrop);
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("weapon_drop", Event_OnWeaponDrop);
			bHooked = false;
		}
	}
}

public void OnMapStart()
{
	static char sName[PLATFORM_MAX_PATH];

	int iTable = FindStringTable("modelprecache");

	int fMax = ( g_bLeft4Dead2 ? 4 : 3 );

	if( iTable != INVALID_STRING_TABLE )
	{
		int iNum = GetStringTableNumStrings(iTable);
		int f;

		for( int i = 0; i < iNum; i++ )
		{
			ReadStringTable(iTable, i, sName, sizeof(sName));

			if( strcmp(sName, MODEL_GASCAN) == 0 )
			{
				IDX_GASCAN = i;
				++f;
			}
			else if( strcmp(sName, MODEL_OXYGEN) == 0 )
			{
				IDX_OXYGEN = i;
				++f;
			}
			else if( strcmp(sName, MODEL_PROPANE) == 0 )
			{
				IDX_PROPANE = i;
				++f;
			}
			else if( g_bLeft4Dead2 && strcmp(sName, MODEL_FIREWORKS) == 0 )
			{
				IDX_FIREWORKS = i;
				++f;
			}

			if( f == fMax )
				break;
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if( g_bEnabled && (buttons & IN_RELOAD) && (buttons & IN_ATTACK) && client && !IsFakeClient(client) )
	{
		static char classname[32];
		int Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		{
			if( Weapon > 0 && IsValidEntity(Weapon) && GetEdictClassname(Weapon, classname, sizeof(classname)) )
			{
				if ( strcmp(classname, "weapon_gascan") == 0 )
				{
					if ( g_bIgniteGascan ) {
						g_bDoIgnite = true;
						g_iIgniter = client;
					}
				}
				else if ( strcmp(classname, "weapon_oxygentank") == 0 )
				{
					if ( g_bIgniteOxygen ) {
						g_bDoIgnite = true;
						g_iIgniter = client;
					}
				}
				else if ( strcmp(classname, "weapon_propanetank") == 0 )
				{
					if ( g_bIgnitePropane ) {
						g_bDoIgnite = true;
						g_iIgniter = client;
					}
				}
				else if ( g_bLeft4Dead2 && strcmp(classname, "weapon_fireworkcrate") == 0 )
				{
					if ( g_bIgniteFireworks ) {
						g_bDoIgnite = true;
						g_iIgniter = client;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public void Event_OnWeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_bDoIgnite )
		return;

	int entity = event.GetInt("propid");

	static char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));

	if( strcmp(classname, "weapon_gascan") == 0 )
	{
		g_bDoIgnite = false;
		g_bDoIgnite = false;
		AcceptEntityInput(entity, "Ignite", g_iIgniter, g_iIgniter);
		BreakExplosive(entity, g_iIgniter, 2.0);
	}
}

Handle BreakExplosive(int entity, int client, float timer) {
	DataPack data = CreateDataPack();
	data.WriteCell(entity);
	data.WriteCell(client);
	return CreateTimer(timer, Timer_Break, data);
}

public Action Timer_Break(Handle timer, DataPack data) {
	data.Reset();
	int entity = data.ReadCell(),
		igniter = data.ReadCell();

	SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", igniter);
	SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
	AcceptEntityInput(entity, "Break", igniter, igniter);
	return Plugin_Stop;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( !g_bDoIgnite )
		return;

	if( strcmp(classname, "physics_prop") == 0 ) // not "prop_physics" !!!
	{
		SDKHook(entity, SDKHook_SpawnPost, Hook_EntitySpawnPost);
	}
}

public voidw Hook_EntitySpawnPost(int iEntRef)
{
	if( iEntRef && iEntRef != INVALID_ENT_REFERENCE && IsValidEntity(iEntRef) )
	{
		int iModel = GetEntProp(iEntRef, Prop_Data, "m_nModelIndex");

		if( iModel == IDX_GASCAN || iModel == IDX_OXYGEN || iModel == IDX_PROPANE || iModel == IDX_FIREWORKS )
		{
			g_bDoIgnite = false;
			AcceptEntityInput(iEntRef, "Ignite", g_iIgniter, g_iIgniter);
			BreakExplosive(iEntRef, g_iIgniter, 2.0);
		}
	}
}
