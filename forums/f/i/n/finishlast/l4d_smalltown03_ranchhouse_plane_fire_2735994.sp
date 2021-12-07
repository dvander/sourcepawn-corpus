#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_sound>
//#pragma newdecls required
Handle g_timer = INVALID_HANDLE;
int ent_plane;
int ent_plane_wing;
int ent_plate_trigger;
int ent_plane_fire;
int ent_plane_touch_fire;
int ent_licht1;
//int onetime = 0;
#define PARTICLE_BOMB1		"gas_explosion_pump"
#define PARTICLE_BOMB2		"gas_explosion_main"


public void OnPluginStart()
{
	//RegConsoleCmd("sm_test1", Command_Test);
		/* Clean up timers */
	if (g_timer != INVALID_HANDLE) {
		delete(g_timer);
		g_timer = INVALID_HANDLE;
	} 
	//HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
	//HookEvent("round_start", event_round_start, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", 			player_left_start_area,	EventHookMode_PostNoCopy);

}

public void OnMapEnd()
{
	/* Clean up timers */
	if (g_timer != INVALID_HANDLE) {
		delete(g_timer);
		g_timer = INVALID_HANDLE;
	}  
}


public void player_left_start_area(Event event, const char[] name, bool dontBroadcast)
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_vs_smalltown03_ranchhouse", false) || StrEqual(sMap, "l4d_smalltown03_ranchhouse", false))
	{
	//if(onetime == 0)
	//{
	//g_timer = CreateTimer(4.0, flicker, _, TIMER_REPEAT);
    	CreateTimer(4.0, planecrash); 
	//onetime=1;
	//}
	}
}




public Action planecrash(Handle timer)
{

	PrecacheModel("models/props_vehicles/airplane_piperwreck.mdl",true);
	PrecacheModel("models/props_vehicles/airplane_piperwing.mdl",true);
	PrecacheModel("models/props_street/traffic_plate_01.mdl",true);


	float pos[3], ang[3], dir[3];


	ent_plate_trigger = CreateEntityByName("prop_dynamic"); 
 
	pos[0] = -12263.0; 
	pos[1] = -5498.0;
	pos[2] = 90.0;


	DispatchKeyValue(ent_plate_trigger, "model", "models/props_street/traffic_plate_01.mdl");
	//DispatchKeyValue(ent_plate_trigger, "spawnflags", "264");
	DispatchKeyValue(ent_plate_trigger, "solid", "6");
	DispatchKeyValue(ent_plate_trigger, "disableshadows", "0");

	DispatchSpawn(ent_plate_trigger);
	TeleportEntity(ent_plate_trigger, pos, ang, NULL_VECTOR);
	SDKHook(ent_plate_trigger, SDKHook_Touch, OnTouch);


	
	pos[0] = -8004.0; 
	pos[1] = -8148.0;
	pos[2] = 1122.0;

	ang[0] = 0.0; 
	ang[1] = 140.0;
	ang[2] = 0.0;

	dir[0] = 0.0; 
	dir[1] = 0.0;
	dir[2] = 0.0;

	float pos1[3], ang1[3], dir1[3];
	
	pos1[0] = -8050.0; 
	pos1[1] = -8248.0;
	pos1[2] = 1122.0;

	ang1[0] = 0.0; 
	ang1[1] = 140.0;
	ang1[2] = 0.0;

	dir1[0] = 0.0; 
	dir1[1] = 0.0;
	dir1[2] = 0.0;




	//pos[2] -= 25.0;
	ent_plane = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_plane, "model", "models/props_vehicles/airplane_piperwreck.mdl");
	//DispatchKeyValue(ent_plane, "spawnflags", "264");
	DispatchKeyValue(ent_plane, "solid", "6");
	DispatchKeyValue(ent_plane, "disableshadows", "0");

	DispatchSpawn(ent_plane);
	TeleportEntity(ent_plane, pos, ang, NULL_VECTOR);


	ent_plane_wing = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_plane_wing, "model", "models/props_vehicles/airplane_piperwing.mdl");
	//DispatchKeyValue(ent_plane_wing, "spawnflags", "264");
	DispatchKeyValue(ent_plane_wing, "solid", "6");
	DispatchKeyValue(ent_plane_wing, "disableshadows", "0");

	DispatchSpawn(ent_plane_wing);

	TeleportEntity(ent_plane_wing, pos1, ang1, NULL_VECTOR);


// ent_plane_fire
	

	//new Float:pos[3];
	//GetClientAbsOrigin(client,pos);
	ent_plane_fire = CreateEntityByName("env_fire");

	//SetEntPropEnt(ent_plane_fire, Prop_Send, "m_hOwnerEntity", client);
	DispatchKeyValue(ent_plane_fire, "firesize", "520");
	DispatchKeyValue(ent_plane_fire, "health", "10");
	DispatchKeyValue(ent_plane_fire, "firetype", "Normal");
	DispatchKeyValue(ent_plane_fire, "damagescale", "0.0");
	DispatchKeyValue(ent_plane_fire, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_plane_fire, "DispatchEffect");
	DispatchSpawn(ent_plane_fire);
	TeleportEntity(ent_plane_fire, pos, ang, NULL_VECTOR);
	AcceptEntityInput(ent_plane_fire, "StartFire");
	SetVariantString("!activator");
	//AcceptEntityInput(ent_plane_fire, "SetParent", client);












	ent_licht1 = CreateEntityByName("beam_spotlight");
	DispatchKeyValue(ent_licht1, "spotlightwidth", "102");
	DispatchKeyValue(ent_licht1, "spotlightlength", "1024");
	DispatchKeyValue(ent_licht1, "spawnflags", "3");
	DispatchKeyValue(ent_licht1, "rendercolor", "255 234 193");
	DispatchKeyValue(ent_licht1, "renderamt", "255");
	DispatchKeyValue(ent_licht1, "maxspeed", "100");
	DispatchKeyValue(ent_licht1, "HDRColorScale", ".7");
	DispatchKeyValue(ent_licht1, "fadescale", "1");
	DispatchKeyValue(ent_licht1, "fademindist", "-1");


	DispatchSpawn(ent_licht1);
	TeleportEntity(ent_licht1, pos, ang, NULL_VECTOR);
	
	Command_Play("ambient\\overhead\\plane2.wav");
		
	//Command_Play("vehicles\\airboat\\fan_blade_fullthrottle_loop1.wav");

	//Command_Play("ambient\\generator\\generator_stop.wav");
	//Command_Play("ambient\\generator\\generator_stop.wav");

	g_timer = CreateTimer(0.01, planemove, _, TIMER_REPEAT);
	
}

public Action planemove(Handle timer)
{
	// Create a global variable visible only in the local scope (this function).
	static int numlift = 0;
	static int soundloop = 0;
	//static int numsound = 0;
	float pos[3], ang[3], dir[3];
	float pos1[3], ang1[3], dir1[3];

	GetEntPropVector(ent_plane, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent_plane, Prop_Send, "m_angRotation", ang);
	GetEntPropVector(ent_plane_wing, Prop_Data, "m_vecAbsOrigin", pos1);
	GetEntPropVector(ent_plane_wing, Prop_Send, "m_angRotation", ang1);

	pos[0] -= 100.0;
	pos[1] += 100.0;
	pos[2] -= 26.0;
	ang[2] += 5;

	dir[0] = 0.0;
	dir[1] = 0.0;
	dir[2] = 0.0;

	pos1[0] -= 100.0;
	pos1[1] += 115.0;
	pos1[2] -= 26.0;
	ang1[0] += 4;
	ang1[1] += 6;
	ang1[2] += 7;

	dir1[0] = 0.0;
	dir1[1] = 0.0;
	dir1[2] = 0.0;


	if (soundloop == 2)
	{
	Command_Play("vehicles\\v8\\van_stop1.wav");
	soundloop = 0;
	}

	
	if (numlift == 26) 
	{
	Command_Play("player\\boomer\\explode\\explo_medium_09.wav");
	}

	if (numlift == 28) 
	{
	//float pos1[3], ang1[3], dir1[3];
	//pos1[0] = -10669.516602; 
	//pos1[1] = -5512.180176;
	//pos1[2] = 407.411591;

	//ang1[0] = 0.0; 
	//ang1[1] = 140.0;
	//ang1[2] = 0.0;

	//dir1[0] = 0.0; 
	//dir1[1] = 0.0;
	//dir1[2] = 0.0;


	//ent_plane_touch_fire = CreateEntityByName("env_fire");

	//SetEntPropEnt(ent_plane_touch_fire, Prop_Send, "m_hOwnerEntity", client);
	//DispatchKeyValue(ent_plane_touch_fire, "firesize", "520");
	//DispatchKeyValue(ent_plane_touch_fire, "health", "10");
	//DispatchKeyValue(ent_plane_touch_fire, "firetype", "Normal");
	//DispatchKeyValue(ent_plane_touch_fire, "damagescale", "0.0");
	//DispatchKeyValue(ent_plane_touch_fire, "spawnflags", "256");
	//SetVariantString("WaterSurfaceExplosion");
	//AcceptEntityInput(ent_plane_touch_fire, "DispatchEffect");
	//DispatchSpawn(ent_plane_touch_fire);
	//TeleportEntity(ent_plane_touch_fire, pos1, ang1, NULL_VECTOR);
	//AcceptEntityInput(ent_plane_touch_fire, "StartFire");
	//SetVariantString("!activator");
	//AcceptEntityInput(ent_plane_touch_fire, "SetParent", client);


	float vPos1[3];
	vPos1[0] = -10669.516602; 
	vPos1[1] = -5512.180176;
	vPos1[2] = 405.411591;
	int entity1;
	entity1 = CreateEntityByName("info_particle_system");
	if( entity1 != -1 )
	{
		//int random = GetRandomInt(1, 4);
		//if( random == 1 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB1);
		//else if( random == 2 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB2);
		//else if( random == 3 )
			//DispatchKeyValue(entity, "effect_name", PARTICLE_BOMB3);
		//else if( random == 4 )
		DispatchKeyValue(entity1, "effect_name", PARTICLE_BOMB1);

		DispatchSpawn(entity1);
		ActivateEntity(entity1);
		AcceptEntityInput(entity1, "start");

		TeleportEntity(entity1, vPos1, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity1, "AddOutput");
		AcceptEntityInput(entity1, "FireUser1");
	}


	ent_plane_touch_fire = CreateEntityByName("env_fire");

	//SetEntPropEnt(ent_plane_touch_fire, Prop_Send, "m_hOwnerEntity", client);
	DispatchKeyValue(ent_plane_touch_fire, "firesize", "1020");
	DispatchKeyValue(ent_plane_touch_fire, "health", "10");
	DispatchKeyValue(ent_plane_touch_fire, "firetype", "Normal");
	DispatchKeyValue(ent_plane_touch_fire, "damagescale", "0.0");
	DispatchKeyValue(ent_plane_touch_fire, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_plane_touch_fire, "DispatchEffect");
	DispatchSpawn(ent_plane_touch_fire);
	TeleportEntity(ent_plane_touch_fire, vPos1, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent_plane_touch_fire, "StartFire");
	SetVariantString("!activator");
	//AcceptEntityInput(ent_plane_touch_fire, "SetParent", client);


	}


	











	if (numlift >= 40) 
	{
		numlift = 0;
		//Command_Play("ambient\\machines\\floodgate_stop1.wav");
		Command_Play("ambient\\machines\\floodgate_stop1.wav");
		//Command_Play("ambient\\explosions\\explode_1.wav");
		Command_Play("ambient\\explosions\\explode_1.wav");
		pos[2] -= 56.0;
		pos1[2] -= 56.0;
		pos1[0] = -12026.0;
		pos1[1] = -4245.0;



		TeleportEntity(ent_plane, pos, ang, dir);
		TeleportEntity(ent_plane_wing, pos1, ang1, dir1);
    		TeleportEntity(ent_plane_fire, pos, ang, dir);
    		TeleportEntity(ent_licht1, pos, ang, dir);

		



		float vPos[3];
		vPos[0] = -11997.823242;
		vPos[1] = -4256.227539;
		vPos[2] = -38.843689;

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
		vPos[2] = 338.843689;
		int entity3;
		entity3 = CreateEntityByName("info_particle_system");
		if( entity3 != -1 )
		{
			//int random = GetRandomInt(1, 4);
			//if( random == 1 )
				//DispatchKeyValue(entity3, "effect_name", PARTICLE_BOMB1);
			//else if( random == 2 )
				//DispatchKeyValue(entity3, "effect_name", PARTICLE_BOMB2);
			//else if( random == 3 )
				//DispatchKeyValue(entity3, "effect_name", PARTICLE_BOMB3);
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





		

		return Plugin_Stop;
	}
 
    	TeleportEntity(ent_plane, pos, ang, dir);
    	TeleportEntity(ent_plane_wing, pos1, ang1, dir1);
    	TeleportEntity(ent_plane_fire, pos, ang, dir);
    	TeleportEntity(ent_licht1, pos, ang, dir);

	numlift++;
	soundloop++;
	//numsound++;
	return Plugin_Continue;

}










//*******
public Action boom(Handle timer)
{


	float vPos[3];
	vPos[0] = -12254.972656;
	vPos[1] = -3901.465576;
	vPos[2] = 100.570099;

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
	Command_Play("ambient\\explosions\\explode_1.wav");

	return Plugin_Continue;

}








//******


public void OnTouch(int client, int other)
{
if(other>=0){

if(GetClientTeam(other) == 2)
{
CreateTimer(2.0, boom);
//PrintToChatAll ("touched");
SDKUnhook(ent_plate_trigger, SDKHook_Touch, OnTouch);
}

}
}




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





