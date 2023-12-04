#define PLUGIN_VERSION 		"1.2"

/*=======================================================================================
	Change Log:

1.2 (26-Oct-2021)
	- Optimizations and code clean up.

1.1 (17-Mar-2019) - by Aya Supay
	- Added game mode check
	- Added versus map support
	- Added list of models
	- Removed pilot entity
	
1.0 (29-Jan-2019)
	- Initial release.

=======================================================================================

	Credits:

	- Joshe Gatito (Aya Supay)
	for request and helicopter attachment points dump & subsequent updates
	
=======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define DEBUG 1

char g_sModels[][PLATFORM_MAX_PATH] = {
	"models/props_vehicles/train_engine_military.mdl",
	"models/props_vehicles/racecar_damaged.mdl",
	"models/props_vehicles/boat_fishing02.mdl",
	"models/props_vehicles/boat_fishing.mdl",
	"models/props_vehicles/car_white.mdl",
	"models/props_vehicles/taxi_city.mdl",
};

ConVar g_hCvarEnable;
ConVar g_hCvarPilot;

int g_iEntRefCar;
int GameMode;

bool g_bAllowed;

public Plugin myinfo =
{
	name = "[L4D1] Helicopter model changer",
	author = "Alex Dragokas & Joshe Gatito",
	description = "Hospital helicopter model changer",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
}

public void OnPluginStart()
{
	GameCheck();
	
	g_hCvarEnable 	= CreateConVar("l4d_heli_modelchanger_enable", 			"1", 	"Enable Plugin? 0 - No, 1 - Yes.", CVAR_FLAGS );
	g_hCvarPilot 	= CreateConVar("l4d_heli_modelchanger_remove_pilot", 	"1", 	"Remove pilot? 0 - No, 1 - Yes.", CVAR_FLAGS );
	
	CreateConVar(			"l4d_heli_modelchanger_version",		PLUGIN_VERSION,	"Plugin version.", 	FCVAR_DONTRECORD | CVAR_FLAGS);
	AutoExecConfig(true,	"l4d_heli_modelchanger");
	
	HookEvent("round_start_post_nav",	Event_RoundStartPostNav,	EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,				EventHookMode_PostNoCopy);
	
	#if DEBUG
	RegAdminCmd("sm_heli", 		Command_CallHeli,		ADMFLAG_ROOT,		"Instantly call a helicopter");
	#endif
}

void GameCheck()
{
	char GameName[16];
	FindConVar("mp_gamemode").GetString(GameName, sizeof(GameName));
	
	if( strcmp(GameName, "survival", false) == 0 )
		GameMode = 3;
	else if( strcmp(GameName, "versus", false) == 0 )
		GameMode = 2;
	else if( strcmp(GameName, "coop", false) == 0 )
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
}

#if DEBUG
public Action Command_CallHeli(int client, int args)
{
	int relay = GetHeliRelay();
	if( relay != -1 ) {
		PrintToChatAll("Helicopter relay is triggered.");
		AcceptEntityInput( relay, "Trigger" );
	}
	int heli = GetEntityByName("prop_dynamic", "helicopter_animated");
	if( heli != -1 )
	{
		AcceptEntityInput(heli, "Enable");
		SetVariantString( "landing" );
		AcceptEntityInput(heli, "SetAnimation");
	}
	return Plugin_Handled;
}
#endif

public void OnMapStart()
{
	g_bAllowed = IsAllowedMap();
	
	if( g_bAllowed )
	{
		for( int i = 0; i < 6; i++ )
		{
			PrecacheModel(g_sModels[i], true);
		}
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_iEntRefCar = 0;
}

public void OnMapEnd()
{
	g_iEntRefCar = 0;
}

public Action Event_RoundStartPostNav(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bAllowed )
	{
		int relay = GetHeliRelay();
		if( relay != -1 ) {
			HookSingleEntityOutput(relay, "OnTrigger", OnHeliTrigger, false); // allow multiple
		}
	}
}

bool IsAllowedMap()
{
	if( g_hCvarEnable.IntValue )
	{
		char sMap[32];
		GetCurrentMap(sMap, sizeof(sMap));
		if( GameMode == 2 || strcmp(sMap, "l4d_hospital05_rooftop", false) == 0 || strcmp(sMap, "l4d_vs_hospital05_rooftop", false) == 0 ) {
			return true;
		}
	}
	return false;
}

public void OnHeliTrigger(const char[] output, int caller, int activator, float delay)
{
	//RequestFrame(onNextFrame);
	ReplaceHeliByCar();
}

public void onNextFrame(any na)
{
	ReplaceHeliByCar();
}

int GetHeliRelay() {
	return GetEntityByName("logic_relay", "helicopter_land_relay");
}

void ReplaceHeliByCar()
{
	int brush = GetEntityByName("func_brush", "helicopter_platform_brush");
	if( brush != -1 ) {
		SetEntitySolid(brush, false);
	}
	
	int heli = GetEntityByName("prop_dynamic", "helicopter_animated");
	if( heli != -1 ) {
		AcceptEntityInput(heli, "DisableCollision");
		//AcceptEntityInput(heli, "TurnOff"); // can't do this way. He is reenabling himself
		SetEntProp(heli, Prop_Send, "m_nRenderMode", 1);
		SetVariantInt(0);
		AcceptEntityInput(heli, "Alpha");
		
		float pos[3], ang[3];

		ang[0] = 0.0;
		ang[1] = 180.0;
		ang[2] = 0.0;
		
		// "SetParentAttachment" use relative offset
		pos[0] = -14.0;
		pos[1] = 45.0;
		pos[2] = -5.0;
		
		int car = CreateCar();
		/*
		// origin and vector can only be set here if you use "SetParentAttachmentMaintainOffset",
		//GetEntPropVector(heli, Prop_Data, "m_vecOrigin", pos);
		//player1_point
		pos[0] += 400.0;
		pos[1] += 200.0;
		pos[2] -= 20.0;
		//After "SetParent"
		//AcceptEntityInput(car, "SetParentAttachmentMaintainOffset"); // do not use it !!! (because it will be placed inaccurately)
		*/

		SetVariantEntity( heli );
		AcceptEntityInput( car, "SetParent");
		
		SetVariantString( "player4_point" );
		AcceptEntityInput(car, "SetParentAttachment");
		
		TeleportEntity(car, pos, ang, NULL_VECTOR);
		
		//GetEntPropVector(car, Prop_Data, "m_vecOrigin", pos);
	}
	
	if( g_hCvarPilot.IntValue )
	{	
		int pilot = GetEntityByName("prop_dynamic", "wink");
		if( pilot != -1 )
		{
			if( GetEntProp(pilot, Prop_Data, "m_iHammerID") == 3999702 )
			{                  
				if( IsValidEdict(pilot) ) RemoveEdict(pilot); 
			}			
		}
	}
}

int CreateCar()
{
	int entity;
	if( g_iEntRefCar != 0 && (entity = EntRefToEntIndex(g_iEntRefCar)) != INVALID_ENT_REFERENCE )
	{
		AcceptEntityInput(entity, "Kill");
	}
	
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 ) {
		DispatchKeyValue(entity, "targetname", "my_car");
		DispatchKeyValue(entity, "spawnflags", "0");
		DispatchKeyValue(entity, "solid", "6");
		// SET MODEL
		DispatchKeyValue(entity, "model", g_sModels[GetRandomInt(0, sizeof(g_sModels) - 1)] );
		DispatchSpawn(entity);
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
		AcceptEntityInput(entity, "TurnOn", entity, entity);

		/*
		SetVariantString("OnUser1 !self:Kill::5.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		*/
		
		g_iEntRefCar = EntIndexToEntRef(entity);
	}
	return entity;
}

stock int GetEntityByName(char[] sClass, char[] sName = "")
{
	int entity;
	char targetname[64];
	while( (entity = FindEntityByClassname(entity, sClass)) != -1 )
	{
		if( sName[0] == 0 )
		{
			return entity;
		}
		else {
			GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
		
			if( strcmp(targetname, sName, false) == 0 )
				return entity;
		}
	}
	return -1;
}

stock void SetEntitySolid(int entity, bool doSolid)
{
	#define FSOLID_NOT_SOLID 	0x0004
	#define SOLID_NONE 			0
	#define SOLID_VPHYSICS		6
	
	int m_nSolidType	= GetEntProp(entity, Prop_Data, "m_nSolidType", 1);
	int m_usSolidFlags	= GetEntProp(entity, Prop_Data, "m_usSolidFlags", 2);
	
	if( doSolid ) {
		if( m_nSolidType == 0 )
			SetEntProp(entity, Prop_Send,	"m_nSolidType",		SOLID_VPHYSICS,	1);
			
		if( m_usSolidFlags & FSOLID_NOT_SOLID )
			SetEntProp(entity, Prop_Send,	"m_usSolidFlags", 	m_usSolidFlags & ~FSOLID_NOT_SOLID,	2);
	}
	else {
		if( m_nSolidType != 0 )
			SetEntProp(entity, Prop_Send,	"m_nSolidType",		SOLID_NONE,	1);
			
		if( m_usSolidFlags & FSOLID_NOT_SOLID == 0 )
			SetEntProp(entity, Prop_Send,	"m_usSolidFlags", 	m_usSolidFlags | FSOLID_NOT_SOLID,	2);
	}
}