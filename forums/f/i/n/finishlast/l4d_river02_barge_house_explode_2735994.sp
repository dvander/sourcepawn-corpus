#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_sound>
//#pragma newdecls required


#define PARTICLE_BOMB2		"gas_explosion_pump"

int ent_plate_trigger;


public void OnPluginStart()
{
	PrecacheModel("models/props_street/traffic_plate_01.mdl",true);
	PrecacheSound("ambient/explosions/explode_1.wav");
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}


public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_river02_barge", false))
	{

	float pos[3], ang[3];


	ent_plate_trigger = CreateEntityByName("prop_dynamic"); 
 
	pos[0] = -5451.076660;
	pos[1] = -344.263275;
	pos[2] = 81.3;
	ang[1] = 80.0;

	DispatchKeyValue(ent_plate_trigger, "model", "models/props_street/traffic_plate_01.mdl");
	//DispatchKeyValue(ent_plate_trigger, "spawnflags", "264");
	DispatchKeyValue(ent_plate_trigger, "solid", "6");
	DispatchKeyValue(ent_plate_trigger, "disableshadows", "1");

	DispatchSpawn(ent_plate_trigger);
	TeleportEntity(ent_plate_trigger, pos, ang, NULL_VECTOR);
	SDKHook(ent_plate_trigger, SDKHook_Touch, OnTouch);


	}
}


public void OnTouch(int client, int other)
{
if(other>=0 && other <= MaxClients){

if(IsClientInGame(other) && GetClientTeam(other) == 2)
{
CreateTimer(2.0, boom);
//PrintToChatAll ("touched");
SDKUnhook(ent_plate_trigger, SDKHook_Touch, OnTouch);

}
}
}


//*******
public Action boom(Handle timer)
{


	float vPos[3];
	vPos[0] = -6937.863281;
	vPos[1] = 385.675507;
	vPos[2] = 254.031250;

	int entity;
	entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		//int random = GetRandomInt(1, 4);
		//if( random == 1 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
		//else if( random == 2 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
		//else if( random == 3 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
		//else if( random == 4 )
		DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);

		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}

	int ent_window = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_window, "firesize", "1020");
	DispatchKeyValue(ent_window, "health", "300");
	DispatchKeyValue(ent_window, "firetype", "Normal");
	DispatchKeyValue(ent_window, "damagescale", "0.0");
	DispatchKeyValue(ent_window, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_window, "DispatchEffect");
	DispatchSpawn(ent_window);
	TeleportEntity(ent_window, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent_window, "StartFire");
	SetVariantString("!activator");


	vPos[0] = -6711.858887;
	vPos[1] = 385.675507;
	vPos[2] = 254.031250;
	int entity2;
	entity2 = CreateEntityByName("info_particle_system");
	if( entity2 != -1 )
	{
		//int random = GetRandomInt(1, 4);
		//if( random == 1 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
		//else if( random == 2 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
		//else if( random == 3 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
		//else if( random == 4 )
		DispatchKeyValue(entity2, "effect_name", PARTICLE_BOMB2);

		DispatchSpawn(entity2);
		ActivateEntity(entity2);
		AcceptEntityInput(entity2, "start");

		TeleportEntity(entity2, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity2, "AddOutput");
		AcceptEntityInput(entity2, "FireUser1");
	}
	int ent_window2 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_window2, "firesize", "1020");
	DispatchKeyValue(ent_window2, "health", "300");
	DispatchKeyValue(ent_window2, "firetype", "Normal");
	DispatchKeyValue(ent_window2, "damagescale", "0.0");
	DispatchKeyValue(ent_window2, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_window2, "DispatchEffect");
	DispatchSpawn(ent_window2);
	TeleportEntity(ent_window2, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent_window2, "StartFire");
	SetVariantString("!activator");


	vPos[0] = -6534.123535;
	vPos[1] = 518.767334;
	vPos[2] = 254.031250;
	int entity3;
	entity3 = CreateEntityByName("info_particle_system");
	if( entity3 != -1 )
	{
		//int random = GetRandomInt(1, 4);
		//if( random == 1 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
		//else if( random == 2 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
		//else if( random == 3 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
		//else if( random == 4 )
		DispatchKeyValue(entity3, "effect_name", PARTICLE_BOMB2);

		DispatchSpawn(entity3);
		ActivateEntity(entity3);
		AcceptEntityInput(entity3, "start");

		TeleportEntity(entity3, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity3, "AddOutput");
		AcceptEntityInput(entity3, "FireUser1");
	}

	int ent_window3 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_window3, "firesize", "1020");
	DispatchKeyValue(ent_window3, "health", "300");
	DispatchKeyValue(ent_window3, "firetype", "Normal");
	DispatchKeyValue(ent_window3, "damagescale", "0.0");
	DispatchKeyValue(ent_window3, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_window3, "DispatchEffect");
	DispatchSpawn(ent_window3);
	TeleportEntity(ent_window3, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent_window3, "StartFire");
	SetVariantString("!activator");


	vPos[0] = -6536.073242;
	vPos[1] = 774.836914;
	vPos[2] = 254.031250;
	int entity4;
	entity4 = CreateEntityByName("info_particle_system");
	if( entity4 != -1 )
	{
		//int random = GetRandomInt(1, 4);
		//if( random == 1 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
		//else if( random == 2 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
		//else if( random == 3 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
		//else if( random == 4 )
		DispatchKeyValue(entity4, "effect_name", PARTICLE_BOMB2);

		DispatchSpawn(entity4);
		ActivateEntity(entity4);
		AcceptEntityInput(entity4, "start");

		TeleportEntity(entity4, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity4, "AddOutput");
		AcceptEntityInput(entity4, "FireUser1");
	}

	int ent_window4 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_window4, "firesize", "1020");
	DispatchKeyValue(ent_window4, "health", "300");
	DispatchKeyValue(ent_window4, "firetype", "Normal");
	DispatchKeyValue(ent_window4, "damagescale", "0.0");
	DispatchKeyValue(ent_window4, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_window4, "DispatchEffect");
	DispatchSpawn(ent_window4);
	TeleportEntity(ent_window4, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent_window4, "StartFire");
	SetVariantString("!activator");


	vPos[0] = -6539.391113;
	vPos[1] = 920.954834;
	vPos[2] = 254.031250;
	int entity5;
	entity5 = CreateEntityByName("info_particle_system");
	if( entity5 != -1 )
	{
		//int random = GetRandomInt(1, 4);
		//if( random == 1 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
		//else if( random == 2 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
		//else if( random == 3 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
		//else if( random == 4 )
		DispatchKeyValue(entity5, "effect_name", PARTICLE_BOMB2);

		DispatchSpawn(entity5);
		ActivateEntity(entity5);
		AcceptEntityInput(entity5, "start");

		TeleportEntity(entity5, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity5, "AddOutput");
		AcceptEntityInput(entity5, "FireUser1");
	}

	int ent_window5 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_window5, "firesize", "1020");
	DispatchKeyValue(ent_window5, "health", "300");
	DispatchKeyValue(ent_window5, "firetype", "Normal");
	DispatchKeyValue(ent_window5, "damagescale", "0.0");
	DispatchKeyValue(ent_window5, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_window5, "DispatchEffect");
	DispatchSpawn(ent_window5);
	TeleportEntity(ent_window5, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent_window5, "StartFire");
	SetVariantString("!activator");


	vPos[0] = -6540.100586;
	vPos[1] = 1254.385254;
	vPos[2] = 254.031250;
	int entity6;
	entity6 = CreateEntityByName("info_particle_system");
	if( entity6 != -1 )
	{
		//int random = GetRandomInt(1, 4);
		//if( random == 1 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
		//else if( random == 2 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
		//else if( random == 3 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
		//else if( random == 4 )
		DispatchKeyValue(entity6, "effect_name", PARTICLE_BOMB2);

		DispatchSpawn(entity6);
		ActivateEntity(entity6);
		AcceptEntityInput(entity6, "start");

		TeleportEntity(entity6, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity6, "AddOutput");
		AcceptEntityInput(entity6, "FireUser1");
	}

	int ent_window6 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_window6, "firesize", "1020");
	DispatchKeyValue(ent_window6, "health", "300");
	DispatchKeyValue(ent_window6, "firetype", "Normal");
	DispatchKeyValue(ent_window6, "damagescale", "0.0");
	DispatchKeyValue(ent_window6, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_window6, "DispatchEffect");
	DispatchSpawn(ent_window6);
	TeleportEntity(ent_window6, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent_window6, "StartFire");
	SetVariantString("!activator");

	vPos[0] = -6536.012695;
	vPos[1] = 1397.650391;
	vPos[2] = 254.031250;
	int entity7;
	entity7 = CreateEntityByName("info_particle_system");
	if( entity7 != -1 )
	{
		//int random = GetRandomInt(1, 4);
		//if( random == 1 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
		//else if( random == 2 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
		//else if( random == 3 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
		//else if( random == 4 )
		DispatchKeyValue(entity7, "effect_name", PARTICLE_BOMB2);

		DispatchSpawn(entity7);
		ActivateEntity(entity7);
		AcceptEntityInput(entity7, "start");

		TeleportEntity(entity7, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity7, "AddOutput");
		AcceptEntityInput(entity7, "FireUser1");
	}

	int ent_window7 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_window7, "firesize", "1020");
	DispatchKeyValue(ent_window7, "health", "300");
	DispatchKeyValue(ent_window7, "firetype", "Normal");
	DispatchKeyValue(ent_window7, "damagescale", "0.0");
	DispatchKeyValue(ent_window7, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_window7, "DispatchEffect");
	DispatchSpawn(ent_window7);
	TeleportEntity(ent_window7, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent_window7, "StartFire");
	SetVariantString("!activator");




	Command_Play("ambient\\explosions\\explode_1.wav");

	return Plugin_Continue;

}








//******






public Action:Command_Play(const String:arguments [])
{

	for(new i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);
		//PrintToChatAll("*************************2*****************************");

	}  
	//return Plugin_Handled;
}





