/****************************************************************************************************
* Plugin     : L4D - Sacrifice boat crescendo
* Version    : 0.0.1
* Game       : Left 4 Dead
* Author     : Finishlast
*
* Testers    : Myself 
* Website    : https://forums.alliedmods.net/showthread.php?p=2776594
* Purpose    : This plugin creates a floating boat, a trigger plate, fire & explosion, panic event and make it sink.
****************************************************************************************************/
public Plugin myinfo =
{
    name = "L4D - Sacrifice boat crescendo",
    author = "finishlast",
    description = "Fire & Boat & Explosion, you get the idea.",
    version = "0.0.1",
    url = ""
}


#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_sound>
#pragma newdecls required
#define PARTICLE_BOMB2		"gas_explosion_main"
Handle g_timer = INVALID_HANDLE;
int ent_plate_trigger;
int ent_boat;
int ent_fire1;
int ent_fire2;
int ent_fire3;
int ent_fire4;
int ent_fire5;
int ent_fire6;
int ent_fire7;
int ent_fire8;
int ent_fire9;
int ent_fire10;
int ent_fire11;
int numlift;

public void OnPluginStart()
{
	PrecacheSound("ambient/explosions/explode_1.wav");
	PrecacheModel("models/props_street/traffic_plate_01.mdl");
	PrecacheModel("models/props_vehicles/boat_fishing02.mdl");

	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
	HookEvent("round_end", event_round_end, EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
delete g_timer;
}

public void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
delete g_timer;
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
        /* Clean up timers */
	if (g_timer != INVALID_HANDLE) {
		KillTimer(g_timer);
		g_timer = INVALID_HANDLE;
	}  
	numlift = 0;

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_river01_docks", false) || StrEqual(sMap, "c7m1_docks", false))
	{

	float vPos[3],vAng[3];


	ent_plate_trigger = CreateEntityByName("prop_dynamic"); 
 
	vPos[0] = 7991.0;
	vPos[1] =  -150.0;
	vPos[2] =  0.0;
	vAng[1] = 90.0;

	DispatchKeyValue(ent_plate_trigger, "model", "models/props_street/traffic_plate_01.mdl");
	DispatchKeyValue(ent_plate_trigger, "solid", "6");
	DispatchKeyValue(ent_plate_trigger, "disableshadows", "1");

	DispatchSpawn(ent_plate_trigger);
	TeleportEntity(ent_plate_trigger, vPos, vAng, NULL_VECTOR);
	SDKHook(ent_plate_trigger, SDKHook_Touch, OnTouch);

	ent_boat = CreateEntityByName("prop_dynamic"); 
 
	vPos[0] = 8356.0;
	vPos[1] = -1114.0;
	vPos[2] =  132.0;
	vAng[1] = 170.0;

	DispatchKeyValue(ent_boat, "model", "models/props_vehicles/boat_fishing02.mdl");
	DispatchKeyValue(ent_boat, "solid", "6");
	DispatchKeyValue(ent_boat, "disableshadows", "1");
	DispatchKeyValue(ent_boat, "DefaultAnim", "Layer_IdleMotion");
	DispatchKeyValue(ent_boat, "disableshadows", "1");

	DispatchSpawn(ent_boat);
	TeleportEntity(ent_boat,  vPos, vAng, NULL_VECTOR);
	
	vPos[0] = 8446.0;
	vPos[1] = -1126.0;
	vPos[2] = -40.0;

	ent_fire1 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire1, "firesize", "1020");
	DispatchKeyValue(ent_fire1, "health", "30000");
	DispatchKeyValue(ent_fire1, "firetype", "Normal");
	DispatchKeyValue(ent_fire1, "damagescale", "0.0");
	DispatchKeyValue(ent_fire1, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire1, "DispatchEffect");
	DispatchSpawn(ent_fire1);
	AcceptEntityInput(ent_fire1, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire1, vPos, NULL_VECTOR, NULL_VECTOR);

	vPos[0] = 8562.0;
	vPos[1] = -1060.0;
	vPos[2] = -40.0;

	ent_fire2 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire2, "firesize", "1020");
	DispatchKeyValue(ent_fire2, "health", "30000");
	DispatchKeyValue(ent_fire2, "firetype", "Normal");
	DispatchKeyValue(ent_fire2, "damagescale", "0.0");
	DispatchKeyValue(ent_fire2, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire2, "DispatchEffect");
	DispatchSpawn(ent_fire2);
	AcceptEntityInput(ent_fire2, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire2, vPos, NULL_VECTOR, NULL_VECTOR);


	vPos[0] = 8446.0;
	vPos[1] = -1126.0;
	vPos[2] = 0.0;

	ent_fire3 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire3, "firesize", "1020");
	DispatchKeyValue(ent_fire3, "health", "30000");
	DispatchKeyValue(ent_fire3, "firetype", "Normal");
	DispatchKeyValue(ent_fire3, "damagescale", "0.0");
	DispatchKeyValue(ent_fire3, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire3, "DispatchEffect");
	DispatchSpawn(ent_fire3);
	AcceptEntityInput(ent_fire3, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire3, vPos, NULL_VECTOR, NULL_VECTOR);


	vPos[0] = 8144.0;
	vPos[1] = -1076.0;
	vPos[2] = 147.0;

	ent_fire4 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire4, "firesize", "2020");
	DispatchKeyValue(ent_fire4, "health", "30000");
	DispatchKeyValue(ent_fire4, "firetype", "Normal");
	DispatchKeyValue(ent_fire4, "damagescale", "0.0");
	DispatchKeyValue(ent_fire4, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire4, "DispatchEffect");
	DispatchSpawn(ent_fire4);
	AcceptEntityInput(ent_fire4, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire4, vPos, NULL_VECTOR, NULL_VECTOR);


	vPos[0] = 7949.0;
	vPos[1] = -1042.0;
	vPos[2] = -20.0;

	ent_fire5 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire5, "firesize", "1020");
	DispatchKeyValue(ent_fire5, "health", "30000");
	DispatchKeyValue(ent_fire5, "firetype", "Normal");
	DispatchKeyValue(ent_fire5, "damagescale", "0.0");
	DispatchKeyValue(ent_fire5, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire5, "DispatchEffect");
	DispatchSpawn(ent_fire5);
	AcceptEntityInput(ent_fire5, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire5, vPos, NULL_VECTOR, NULL_VECTOR);


	vPos[0] = 8309.0;
	vPos[1] = -1099.0;
	vPos[2] = -20.0;

	ent_fire6 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire6, "firesize", "1020");
	DispatchKeyValue(ent_fire6, "health", "30000");
	DispatchKeyValue(ent_fire6, "firetype", "Normal");
	DispatchKeyValue(ent_fire6, "damagescale", "0.0");
	DispatchKeyValue(ent_fire6, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire6, "DispatchEffect");
	DispatchSpawn(ent_fire6);
	AcceptEntityInput(ent_fire6, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire6, vPos, NULL_VECTOR, NULL_VECTOR);


	vPos[0] = 8153.0;
	vPos[1] = -983.0;
	vPos[2] = -20.0;

	ent_fire7 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire7, "firesize", "1020");
	DispatchKeyValue(ent_fire7, "health", "30000");
	DispatchKeyValue(ent_fire7, "firetype", "Normal");
	DispatchKeyValue(ent_fire7, "damagescale", "0.0");
	DispatchKeyValue(ent_fire7, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire7, "DispatchEffect");
	DispatchSpawn(ent_fire7);
	AcceptEntityInput(ent_fire7, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire7, vPos, NULL_VECTOR, NULL_VECTOR);


	vPos[0] = 8697.0;
	vPos[1] = -1100.0;
	vPos[2] = -40.0;

	ent_fire8 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire8, "firesize", "1020");
	DispatchKeyValue(ent_fire8, "health", "30000");
	DispatchKeyValue(ent_fire8, "firetype", "Normal");
	DispatchKeyValue(ent_fire8, "damagescale", "0.0");
	DispatchKeyValue(ent_fire8, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire8, "DispatchEffect");
	DispatchSpawn(ent_fire8);
	AcceptEntityInput(ent_fire8, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire8, vPos, NULL_VECTOR, NULL_VECTOR);

	vPos[0] = 8377.0;
	vPos[1] = -1011.0;
	vPos[2] = -40.0;

	ent_fire9 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire9, "firesize", "1020");
	DispatchKeyValue(ent_fire9, "health", "30000");
	DispatchKeyValue(ent_fire9, "firetype", "Normal");
	DispatchKeyValue(ent_fire9, "damagescale", "0.0");
	DispatchKeyValue(ent_fire9, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire9, "DispatchEffect");
	DispatchSpawn(ent_fire9);
	AcceptEntityInput(ent_fire9, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire9, vPos, NULL_VECTOR, NULL_VECTOR);

	vPos[0] = 8619.0;
	vPos[1] = -1207.0;
	vPos[2] = -40.0;

	ent_fire10 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire10, "firesize", "1020");
	DispatchKeyValue(ent_fire10, "health", "30000");
	DispatchKeyValue(ent_fire10, "firetype", "Normal");
	DispatchKeyValue(ent_fire10, "damagescale", "0.0");
	DispatchKeyValue(ent_fire10, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire10, "DispatchEffect");
	DispatchSpawn(ent_fire10);
	AcceptEntityInput(ent_fire10, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire10, vPos, NULL_VECTOR, NULL_VECTOR);

	vPos[0] = 8804.0;
	vPos[1] = -1199.0;
	vPos[2] = -40.0;

	ent_fire11 = CreateEntityByName("env_fire");
	DispatchKeyValue(ent_fire11, "firesize", "1020");
	DispatchKeyValue(ent_fire11, "health", "30000");
	DispatchKeyValue(ent_fire11, "firetype", "Normal");
	DispatchKeyValue(ent_fire11, "damagescale", "0.0");
	DispatchKeyValue(ent_fire11, "spawnflags", "256");
	SetVariantString("WaterSurfaceExplosion");
	AcceptEntityInput(ent_fire11, "DispatchEffect");
	DispatchSpawn(ent_fire11);
	AcceptEntityInput(ent_fire11, "StartFire");
	SetVariantString("!activator");
	TeleportEntity(ent_fire11, vPos, NULL_VECTOR, NULL_VECTOR);

	}

}


public void OnTouch(int client, int other)
{
	if(other>=0 && other <= MaxClients)
	{

	if(IsClientInGame(other) && GetClientTeam(other) == 2)
	{
	SDKUnhook(ent_plate_trigger, SDKHook_Touch, OnTouch);
	char command[] = "director_force_panic_event";
	char flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(other, command);
	SetCommandFlags(command, flags);

	CreateTimer(0.5, boom);
	}

	}
}


//*******
public Action boom(Handle timer)
{


	float vPos[3];
	vPos[0] = 8573.0;
	vPos[1] = -1143.0;
	vPos[2] = -40.0;

	int entity;
	entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
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
	g_timer = CreateTimer(0.1, gate, _, TIMER_REPEAT);
	return Plugin_Continue;

}

//******
public Action gate(Handle timer)
{
	// Create a global variable visible only in the local scope (this function).
	float vPos[3], vAng[3], vDir[3];

	vDir[0] = 0.0;
	vDir[1] = 0.0;
	vDir[2] = 0.0;
	
	GetEntPropVector(ent_boat, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_boat, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	vAng[0] -= 0.1;
	TeleportEntity(ent_boat, vPos, vAng, vDir);

	GetEntPropVector(ent_fire1, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire1, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire1, vPos, vAng, vDir);

	GetEntPropVector(ent_fire2, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire2, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire2, vPos, vAng, vDir);

	GetEntPropVector(ent_fire3, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire3, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire3, vPos, vAng, vDir);

	GetEntPropVector(ent_fire4, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire4, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire4, vPos, vAng, vDir);

	GetEntPropVector(ent_fire5, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire5, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire5, vPos, vAng, vDir);

	GetEntPropVector(ent_fire6, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire6, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire6, vPos, vAng, vDir);

	GetEntPropVector(ent_fire7, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire7, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire7, vPos, vAng, vDir);

	GetEntPropVector(ent_fire8, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire8, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire8, vPos, vAng, vDir);

	GetEntPropVector(ent_fire9, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire9, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire9, vPos, vAng, vDir);

	GetEntPropVector(ent_fire10, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire10, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire10, vPos, vAng, vDir);

	GetEntPropVector(ent_fire11, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_fire11, Prop_Send, "m_angRotation", vAng);
	vPos[2] -= 1.0;
	TeleportEntity(ent_fire11, vPos, vAng, vDir);
  
	if (numlift >= 770) 
	{
		numlift = 0;
		g_timer = null;
		return Plugin_Stop;
	}
	numlift++;
	return Plugin_Continue;
}

//******

public Action Command_Play(const char[] arguments)
{

	for(int i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);

	}  
}





