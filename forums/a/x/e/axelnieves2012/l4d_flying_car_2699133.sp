#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.2 BETA 1"
#define MODEL_CAR1			"models/props_vehicles/taxi_cab.mdl"
#define MODEL_CAR2			"models/props_vehicles/car_white.mdl"
#define MODEL_CAR3			"models/props_vehicles/police_car.mdl"
//#define MODEL_CAR4			"models/props_vehicles/cara_82hatchback.mdl" //*
//#define MODEL_CAR5			"models/props_vehicles/cara_84sedan.mdl" //*
//#define MODEL_CAR6			"models/props_vehicles/cara_95sedan.mdl"
#define MODEL_GLASS			"models/props_vehicles/police_car_glass.mdl"
#define MODEL_PROPANE 	"models/props_junk/propanecanister001a.mdl"
#define MODEL_LIGHTBAR 	"models/props_vehicles/police_car_lightbar.mdl.mdl"

Handle l4d_flying_car_color;
Handle l4d_flying_car_enable;
//Handle l4d_flying_car_enable_modes;
Handle l4d_flying_car_explode;
Handle l4d_flying_car_ignite;
Handle l4d_flying_car_model;
Handle l4d_flying_car_random_color;
Handle l4d_flying_car_random_model;
int g_iCar = INVALID_ENT_REFERENCE;
int g_iExplosion = INVALID_ENT_REFERENCE;
int g_iFlame = INVALID_ENT_REFERENCE;
int g_iPilot = INVALID_ENT_REFERENCE;
int g_iProbability;

public Plugin myinfo =
{
	name = "L4D No Mercy Flying Car",
	author = "Axel Juan Nieves",
	description = "Replaces getaway chopper by flying car.",
	version = PLUGIN_VERSION,
}

public void OnMapStart()
{
	PrecacheModel(MODEL_CAR1);
	PrecacheModel(MODEL_CAR2);
	PrecacheModel(MODEL_CAR3);
	PrecacheModel(MODEL_GLASS);
	PrecacheModel(MODEL_PROPANE);
	PrecacheModel(MODEL_LIGHTBAR);
}

public void OnPluginStart()
{
	CreateConVar("l4d_flying_car_version", PLUGIN_VERSION, "", 0|FCVAR_DONTRECORD);
	l4d_flying_car_color = CreateConVar("l4d_flying_car_color", "", "Custom color (rgb), leave black to use default color", 0);
	l4d_flying_car_enable = CreateConVar("l4d_flying_car_enable", "1", "Enable/Disable this plugin. 0:disable, 1:enable", 0);
	//l4d_flying_car_enable_modes = CreateConVar("l4d_flying_car_enable_modes", "3", "Run this plugin on these gamemodes. 1:coop, 2:versus", 0, true, 1.0, true, 3.0);
	l4d_flying_car_explode = CreateConVar("l4d_flying_car_explode", "1", "Explode car? 0:disable, 1:enable", 0);
	l4d_flying_car_ignite = CreateConVar("l4d_flying_car_ignite", "1", "Ignite car on leaving? 0:disable, 1:enable", 0);
	l4d_flying_car_model = CreateConVar("l4d_flying_car_model", "3", "Car model (1:taxi, 2:normal, 3:police car)", 0, true, 1.0, true,  3.0);
	l4d_flying_car_random_color = CreateConVar("l4d_flying_car_random_color", "0", "Choose color randomly instead using custom one? 0:disable, 1:enable", 0);
	l4d_flying_car_random_model = CreateConVar("l4d_flying_car_random_model", "0", "Choose model randomly instead using custom one? 0:disable, 1:enable", 0);
	
	AutoExecConfig(true, "l4d_flying_car");
	HookEvent("round_freeze_end", event_roundfreeze_end, EventHookMode_PostNoCopy);
	//RegConsoleCmd("sm_2", test2, "test");
}

/*public Action test2(int client, int args)
{
	CreateLightbar(client);
}*/

public void event_roundfreeze_end(Event event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d_flying_car_enable) )
		return;
	
	//check map:
	char buffer[32];
	GetCurrentMap(buffer, sizeof(buffer));
	if ( strcmp(buffer, "l4d_hospital05_rooftop")==0 ){}
	else if ( strcmp(buffer, "l4d_vs_hospital05_rooftop")==0 ){}
	else if ( strcmp(buffer, "c8m5_rooftop")==0 ){}
	else return;
	
	HookEvent("finale_escape_start", event_finale_escape_start, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_ready", event_finale_vehicle_ready, EventHookMode_PostNoCopy);
	
	//Remove delay on finale radio button (just for testing)...
	int entity = INVALID_ENT_REFERENCE;
	while ( (entity = FindEntityByClassname(entity, "func_button"))!=INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if ( StrEqual(buffer, "radio_button", false) )
		{
			SetVariantString("OnPressed radio_template:ForceSpawn::2.0:1");
			AcceptEntityInput(entity, "AddOutput");			
			SetVariantString("OnPressed radio_game_event:GenerateGameEvent::2.0:1");
			AcceptEntityInput(entity, "AddOutput");
			
			SetVariantString("OnPressed pilot_radio_setup_lcs:Cancel::2.0:1");
			AcceptEntityInput(entity, "AddOutput");			
		}
	}
}

public void event_finale_escape_start(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d_flying_car_enable) )
	{
		UnhookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
		return;
	}
	
	char modelname[256];
	char rgb[16];
	
	//creating a car without glasses:
	int car = CreateEntityByName("prop_dynamic");
	if ( !IsValidEntity(car) )
		return;
	
	g_iCar = EntIndexToEntRef(car);
	
	if ( GetConVarBool(l4d_flying_car_random_model) )
	{
		switch(GetRandomInt(1, 3))
		{
			case 1: SetEntityModel(car, MODEL_CAR1);
			case 2: SetEntityModel(car, MODEL_CAR2);
			case 3: SetEntityModel(car, MODEL_CAR3);
		}
	}
	else
	{
		switch( GetConVarInt(l4d_flying_car_model) )
		{
			case 1: SetEntityModel(car, MODEL_CAR1);
			case 2: SetEntityModel(car, MODEL_CAR2);
			case 3: SetEntityModel(car, MODEL_CAR3);
		}
	}
	
	//creating glasses:
	int glass = CreateEntityByName("prop_dynamic");
	if ( !IsValidEntity(glass) )
		return;
	SetEntityModel(glass, MODEL_GLASS);
	
	//bugfix: glasses fading...
	DispatchKeyValue(glass, "fadescale", "0");
	DispatchKeyValue(glass, "fademindist", "9999999");
	DispatchKeyValue(glass, "fademaxdist", "-1");
	
	//get custom rgb color...
	GetConVarString(l4d_flying_car_color, rgb, sizeof(rgb));
	TrimString(rgb);
	
	//scan all entities...
	int EntityCount = GetEntityCount();
	for (int entity = 1; entity <= EntityCount; entity++)
	{
		if (!IsValidEntity(entity))
			continue;
		
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		
		if ( StrContains(modelname, ".mdl", false)<0 )
			continue;
		
		if ( StrContains(modelname, "pilot", false)>=0 ) 
		{
			g_iPilot = EntIndexToEntRef(entity); //make pilot's entity global
			SetEntityRenderMode(entity, RENDER_NONE); //make pilot invisible
			
			//attach car and window glasses to pilot...
			SetVariantString("!activator");
			AcceptEntityInput(car, "SetParent", entity);
			SetVariantString("!activator");
			AcceptEntityInput(glass, "SetParent", entity);
			
			//bugfix: car fading...
			DispatchKeyValue(car, "fadescale", "0");
			DispatchKeyValue(car, "fademindist", "9999999");
			DispatchKeyValue(car, "fademaxdist", "-1");
			
			//check random color...
			if ( GetConVarBool(l4d_flying_car_random_color) )
			{
				switch(GetRandomInt(2, 8))
				{
					case 1: SetEntityRenderColor(car, 0, 0, 0, 255); //black
					case 2: SetEntityRenderColor(car, 255, 255, 255, 255); //white
					case 3: SetEntityRenderColor(car, 255, 0, 0, 255); //red
					case 4: SetEntityRenderColor(car, 0, 255, 0, 255); //green
					case 5: SetEntityRenderColor(car, 0, 0, 255, 255); //blue
					case 6: SetEntityRenderColor(car, 255, 0, 255, 255); //purple
					case 7: SetEntityRenderColor(car, 255, 255, 0, 255); //yellow
					case 8: SetEntityRenderColor(car, 0, 255, 255, 200); //lightblue
				}
			}
			//check custom color...
			else if ( strlen(rgb)>=5 )
			{
				DispatchKeyValue(car, "rendercolor", rgb);
			}
		}
		//remove helicopter's headlights...
		else if ( StrContains(modelname, "searchlight_small_01", false)>=0 ) 
		{
			RemoveEntity(entity);
		}
		//make helicopter invisible...
		else if ( StrContains(modelname, "heli", false)>=0 ) 
		{
			SetEntityRenderMode(entity, RENDER_NONE);
		}
	}
	//correct position and angles:
	TeleportEntity(car, view_as<float>({-110.0, 0.0, -75.0}), view_as<float>({0.0, 270.0, 0.0}), NULL_VECTOR);
	TeleportEntity(glass, view_as<float>({-110.0, 0.0, -75.0}), view_as<float>({0.0, 270.0, 0.0}), NULL_VECTOR);
	
	if ( GetConVarInt(l4d_flying_car_model)==3 )
		CreateLightbar();
	
	//Preparing explosions...
	if ( GetConVarBool(l4d_flying_car_explode) )
	{
		g_iProbability = 5;
		CreateTimer(0.5, RandomExplosions, _, TIMER_REPEAT);
	}
	
	//Ignite car before it arrives...
	if ( GetConVarBool(l4d_flying_car_ignite) )
	{
		int particle = CreateEntityByName("info_particle_system");
		if ( !IsValidEdict(particle) ) return;
		g_iFlame = EntIndexToEntRef(particle); //make it global
		DispatchKeyValue(particle, "effect_name", "env_fire_medium");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", car);
		TeleportEntity(particle, view_as<float>({50.0, 0.0, 15.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
	}
}
public void event_finale_vehicle_ready(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d_flying_car_enable) )
	{
		UnhookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
		return;
	}
	
	//reduce explosions at this point...
	g_iProbability = 20;
	
	//extinguish car at this point...
	if ( GetConVarBool(l4d_flying_car_ignite) )
	{
		int particle = EntRefToEntIndex(g_iFlame);
		if ( !IsValidEdict(particle) )
			return;
		
		AcceptEntityInput(particle, "stop");
	}
}

public void event_finale_vehicle_leaving(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d_flying_car_enable) )
		return;
	
	int car = EntRefToEntIndex(g_iCar);
	if ( !IsValidEntity(car) )
	{
		return;
	}
	
	//re-ignite car...
	int particle = EntRefToEntIndex(g_iFlame);
	if ( IsValidEdict(particle) )
		AcceptEntityInput(particle, "start");
	
	//explode car more frequentrly...
	if ( GetConVarBool(l4d_flying_car_explode) )
	{
		g_iProbability = 3;
	}
}

public Action RandomExplosions(Handle timer)
{
	if ( !GetConVarBool(l4d_flying_car_enable) )
		return Plugin_Stop;
	
	if ( !GetConVarBool(l4d_flying_car_explode) )
		return Plugin_Stop;
	
	int car = EntRefToEntIndex(g_iCar);
	if ( !IsValidEntity(car) )
	{
		LogError("Invalid car entity. Timer stopped!");
		return Plugin_Stop;
	}
	
	//------------------------------------------------------
	//If everything above went ok............................
	
	//check if already exploded...
	int explosion = EntRefToEntIndex(g_iExplosion);
	if ( !IsValidEntity(explosion) )
	{
		//create a new explosion...
		explosion = CreateEntityByName("prop_physics");
		if ( !IsValidEntity(explosion) )
		{
			LogError("Fatal error creating explosion entity! Timer will continue!");
			return Plugin_Continue;
		}
		g_iExplosion = EntIndexToEntRef(explosion); //make it global
		DispatchKeyValue(explosion, "physdamagescale", "0.0");
		DispatchKeyValue(explosion, "model", MODEL_PROPANE);
		DispatchSpawn(explosion); //spawn a propane tank
		SetEntityRenderMode(explosion, RENDER_NONE); //make propane tank invisible
		SetVariantString("!activator");
		AcceptEntityInput(explosion, "SetParent", car);
		TeleportEntity(explosion, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
		SetEntityMoveType(explosion, MOVETYPE_VPHYSICS);
	}
	
	//check probabilities....
	if ( GetRandomInt(1, g_iProbability)==1 )
	{
		AcceptEntityInput(explosion, "Break"); //detonate propane tank
		AcceptEntityInput(explosion, "ClearParent"); //remove references before killing entity
		RemoveEntity(explosion);//remove it from world
		g_iExplosion = INVALID_ENT_REFERENCE;
	}
	return Plugin_Continue;
}

stock void CreateLightbar(/*int client=0*/)
{
	int lightbar = CreateEntityByName("prop_dynamic");
	int car = EntRefToEntIndex(g_iPilot);
	if ( !IsValidEntity(lightbar) )
		return;
	/*
	//debugging:
	if ( client>0 && client<=MAXPLAYERS )
	{
		car = client;
		PrintToChatAll("CREATING BAR");
	}*/
	
	if ( !IsValidEntity(car) )
		return;
		
	//this is a light bar without lights...
	SetEntityModel(lightbar, MODEL_LIGHTBAR);
	SetVariantString("!activator");
	AcceptEntityInput(lightbar, "SetParent", car);
	TeleportEntity(lightbar, view_as<float>({-110.0, 0.0, -75.0}), view_as<float>({0.0, 270.0, 0.0}), NULL_VECTOR);
	DispatchKeyValue(lightbar, "targetname", "police_lights");
	DispatchKeyValue(lightbar, "fadescale", "0");
	DispatchKeyValue(lightbar, "fademindist", "9999999");
	DispatchKeyValue(lightbar, "fademaxdist", "-1");
	DispatchKeyValue(lightbar, "skin", "1");
	
	//these are blue lights...
	int light_blue = CreateEntityByName("light_dynamic");
	if ( !IsValidEntity(light_blue) )
		return;
	DispatchKeyValue(light_blue, "targetname", "light_blue");
	DispatchKeyValue(light_blue, "_light", "0 15 147");
	DispatchKeyValue(light_blue, "brightness", "1");
	DispatchKeyValueFloat(light_blue, "spotlight_radius", 700.0);
	DispatchKeyValueFloat(light_blue, "distance", 2000.0);
	DispatchKeyValue(light_blue, "style", "4");
	DispatchSpawn(light_blue);
	ActivateEntity(light_blue);
	AcceptEntityInput(light_blue, "TurnOff");
	SetVariantString("!activator");
	AcceptEntityInput(light_blue, "SetParent", lightbar);
	TeleportEntity(light_blue, view_as<float>({0.0, 0.0, 100.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
	//Loop...
	SetVariantString("OnUser1 !self:TurnOn::0.0:-1");
	AcceptEntityInput(light_blue, "AddOutput");
	SetVariantString("OnUser2 !self:TurnOff::0.0:-1");
	AcceptEntityInput(light_blue, "AddOutput");
	SetVariantString("OnUser1 !self:FireUser2::0.4:-1");
	AcceptEntityInput(light_blue, "AddOutput");
	SetVariantString("OnUser2 !self:FireUser1::0.4:-1");
	AcceptEntityInput(light_blue, "AddOutput");
	AcceptEntityInput(light_blue, "FireUser1");
	
	
	//these are red lights...
	int light_red = CreateEntityByName("light_dynamic");
	if ( !IsValidEntity(light_red) )
		return;
	DispatchKeyValue(light_red, "targetname", "light_red");
	DispatchKeyValue(light_red, "_light", "149 0 0");
	DispatchKeyValue(light_red, "brightness", "1");
	DispatchKeyValueFloat(light_red, "spotlight_radius", 700.0);
	DispatchKeyValueFloat(light_red, "distance", 2000.0);
	DispatchKeyValue(light_red, "style", "4");
	DispatchSpawn(light_red);
	ActivateEntity(light_red);
	AcceptEntityInput(light_red, "TurnOff");
	SetVariantString("!activator");
	AcceptEntityInput(light_red, "SetParent", lightbar);
	TeleportEntity(light_red, view_as<float>({0.0, 0.0, 100.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
	//Loop...
	SetVariantString("OnUser1 !self:TurnOff::0.0:-1");
	AcceptEntityInput(light_red, "AddOutput");
	SetVariantString("OnUser2 !self:TurnOn::0.0:-1");
	AcceptEntityInput(light_red, "AddOutput");
	SetVariantString("OnUser1 !self:FireUser2::0.4:-1");
	AcceptEntityInput(light_red, "AddOutput");
	SetVariantString("OnUser2 !self:FireUser1::0.3:-1");
	AcceptEntityInput(light_red, "AddOutput");
	AcceptEntityInput(light_red, "FireUser1");
}