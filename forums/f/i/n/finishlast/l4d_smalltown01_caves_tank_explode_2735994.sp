#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_sound>
//#pragma newdecls required
#define PARTICLE_BOMB2		"gas_explosion_main"

int ent_plate_trigger;

public void OnPluginStart()
{
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}


public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_smalltown01_caves", false) || StrEqual(sMap, "l4d_vs_smalltown01_caves", false))
	{
	PrecacheModel("models/props_street/traffic_plate_01.mdl",true);	

	float pos[3], ang[3];


	ent_plate_trigger = CreateEntityByName("prop_dynamic"); 
 
	pos[0] = -12355.642578;
	pos[1] = -12298.7;
	pos[2] = -64.0;
	ang[1] = 50.0;

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
if(other>=0){

if(GetClientTeam(other) == 2)
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
	vPos[0] = -12478.235352;
	vPos[1] = -11380.708008;
	vPos[2] = 64.0;

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





