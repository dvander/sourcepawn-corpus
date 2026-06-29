#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "BETA 1.1.0"
#define CAR1			"models/props_vehicles/taxi_cab.mdl"
#define CAR2			"models/props_vehicles/car_white.mdl"
//#define CAR3			"models/props_vehicles/cara_95sedan.mdl"
//#define CAR4			"models/props_vehicles/cara_82hatchback.mdl" //*
//#define CAR5			"models/props_vehicles/cara_84sedan.mdl" //*

#define GLASS			"models/props_vehicles/police_car_glass.mdl"
#define MODEL_PROPANE 	"models/props_junk/propanecanister001a.mdl"

Handle l4d1_flying_car_enable;
Handle l4d1_flying_car_random_color;
Handle l4d1_flying_car_random_model;
/*Handle l4d1_flying_car_r;
Handle l4d1_flying_car_g;
Handle l4d1_flying_car_b;
Handle l4d1_flying_car_model;*/
int car = INVALID_ENT_REFERENCE;

public Plugin myinfo =
{
	name = "L4D1 No Mercy Flying Car",
	author = "Axel Juan Nieves",
	description = "Replaces getaway chopper by flying car.",
	version = PLUGIN_VERSION,
}

public void OnMapStart()
{
	PrecacheModel(CAR1);
	PrecacheModel(CAR2);
	PrecacheModel(GLASS);
	PrecacheModel(MODEL_PROPANE);
}

public void OnPluginStart()
{	
	CreateConVar("l4d1_flying_car_version", PLUGIN_VERSION, "", 0|FCVAR_DONTRECORD);
	l4d1_flying_car_enable = CreateConVar("l4d1_flying_car_enable", "1", "Enable/Disable this plugin. 0:disable, 1:enable", 0);
	l4d1_flying_car_random_color = CreateConVar("l4d1_flying_car_random_color", "1", "Choose color randomly? 0:disable, 1:enable", 0);
	l4d1_flying_car_random_model = CreateConVar("l4d1_flying_car_random_model", "0", "Choose model randomly? 0:disable, 1:enable", 0);
	
	//AutoExecConfig(true, "l4d1_flying_car");
	HookEvent("finale_escape_start", event_finale_escape_start, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("sm_1", test1, "test");
}

public Action test1(int client, int args)
{
	char modelname[256];
	char classname2[255];
	float pos[3];
	
	int EntityCount = GetEntityCount();
	for (int entity = 1; entity <= EntityCount; entity++)
	{
		if (!IsValidEntity(entity))
			continue;
		
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		GetEdictClassname(entity, classname2, sizeof(classname2));
		if ( StrContains(modelname, "taxi_cab", false)<0 )
			continue;
		
		/*if (StrContains(modelname, "taxi_cab", false)<0) 
			continue;*/
		
		//GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		int offset = FindDataMapInfo(entity, "m_vecOrigin");
		GetEntDataVector(entity, offset, pos);
		PrintToChatAll("FOUND! X(%f), Y(%f)", pos[0], pos[1]);
		break;
	}
}

public Action event_finale_escape_start(Handle event, const char[] name, bool dontBroadcast)
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	if ( !StrEqual(map, "l4d_hospital05_rooftop", false) )
		return Plugin_Continue;
	
	if ( !GetConVarBool(l4d1_flying_car_enable) )
		return Plugin_Continue;
	
	char modelname[256];
	char classname2[255];
	
	//creating a car without glasses:
	car = CreateEntityByName("prop_dynamic");
	if ( !IsValidEntity(car) )
		return Plugin_Continue;
	
	if ( GetConVarBool(l4d1_flying_car_random_model) )
	{
		switch(GetRandomInt(1, 2))
		{
			case 1: SetEntityModel(car, CAR1);
			case 2: SetEntityModel(car, CAR2);
		}
	}
	else
		SetEntityModel(car, CAR1);
	
	//creating glasses:
	int glass = CreateEntityByName("prop_dynamic");
	if ( !IsValidEntity(glass) )
		return Plugin_Continue;
	SetEntityModel(glass, GLASS);
	DispatchKeyValue(glass, "fadescale", "0");
	DispatchKeyValue(glass, "fademindist", "9999999");
	DispatchKeyValue(glass, "fademaxdist", "-1");
	
	int EntityCount = GetEntityCount();
	for (int entity = 1; entity <= EntityCount; entity++)
	{
		if (!IsValidEntity(entity))
			continue;
		
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		GetEdictClassname(entity, classname2, sizeof(classname2));
		
		if ( StrContains(modelname, ".mdl", false)<0 )
			continue;
		
		if (StrContains(modelname, "pilot", false)>=0) 
		{
			SetEntityRenderMode(entity, RENDER_NONE); //make pilot invisible
			
			SetVariantString("!activator");
			AcceptEntityInput(car, "SetParent", entity); //attach car to pilot
			
			SetVariantString("!activator");
			AcceptEntityInput(glass, "SetParent", entity); //attach windows to pilot
			DispatchKeyValue(car, "fadescale", "0");
			DispatchKeyValue(car, "fademindist", "9999999");
			DispatchKeyValue(car, "fademaxdist", "-1");
			//SetEntPropString(car, Prop_Data, "m_iName", "flyingcar");
			if ( GetConVarBool(l4d1_flying_car_random_color) )
			{
				switch(GetRandomInt(2, 8))
				{
					//case 1: SetEntityRenderColor(car, 0, 0, 0, 255); //black
					case 2: SetEntityRenderColor(car, 255, 255, 255, 255); //white
					case 3: SetEntityRenderColor(car, 255, 0, 0, 255); //red
					case 4: SetEntityRenderColor(car, 0, 255, 0, 255); //green
					case 5: SetEntityRenderColor(car, 0, 0, 255, 255); //blue
					case 6: SetEntityRenderColor(car, 255, 0, 255, 255); //purple
					case 7: SetEntityRenderColor(car, 255, 255, 0, 255); //yellow
					case 8: SetEntityRenderColor(car, 0, 255, 255, 200); //lightblue
				}
			}
		}
		else if (StrContains(modelname, "searchlight_small_01", false)>=0) 
		{
			RemoveEntity(entity); //remove helicopter's lights
			//AcceptEntityInput(entity, "ClearParent");
			//SetVariantString("!activator");
			//AcceptEntityInput(entity, "SetParent", car);
			//TeleportEntity(entity, view_as<float>({0.0, -20.0, -30.0}), view_as<float>({0.0, 0.0, 345.0}), NULL_VECTOR);
			//SetEntityRenderMode(entity, RENDER_NONE); //make headlights invisible, but keep lights visible
		}
		else if (StrContains(modelname, "heli", false)>=0) 
		{
			SetEntityRenderMode(entity, RENDER_NONE); //make helicopter invisible
		}
	}
	//correct position and angles:
	TeleportEntity(car, view_as<float>({-110.0, 0.0, -75.0}), view_as<float>({0.0, 270.0, 0.0}), NULL_VECTOR);
	TeleportEntity(glass, view_as<float>({-110.0, 0.0, -75.0}), view_as<float>({0.0, 270.0, 0.0}), NULL_VECTOR);
	
	
	return Plugin_Continue;
}

public Action event_finale_vehicle_leaving(Handle event, const char[] name, bool dontBroadcast)
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	if ( !StrEqual(map, "l4d_hospital05_rooftop", false) )
		return Plugin_Continue;
	
	if ( !GetConVarBool(l4d1_flying_car_enable) )
		return Plugin_Continue;
	
	int particle = CreateEntityByName("info_particle_system");
	if ( !IsValidEdict(particle) )
		return Plugin_Continue;
	
	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", "flyingcar");
	DispatchKeyValue(particle, "effect_name", "env_fire_medium");
	DispatchSpawn(particle);
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", car);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	
	return Plugin_Continue;
}