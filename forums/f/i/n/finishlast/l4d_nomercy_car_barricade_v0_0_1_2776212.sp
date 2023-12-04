/****************************************************************************************************
* Plugin     : L4D - No Mercy car barricade crescendo
* Version    : 0.0.1
* Game       : Left 4 Dead
* Author     : Finishlast
*
* Testers    : Myself 
* Website    : https://forums.alliedmods.net/showthread.php?p=2776212
* Purpose    : This plugin creates a block crescendo at the end of the nomercy subway map
* Based on code from:
* https://forums.alliedmods.net/showthread.php?t=328013 Bacardi Freight lift button
* And snippets I forgot where I found them back in the day, sorry, if you recognize any please tell me.
****************************************************************************************************/
public Plugin myinfo =
{
    name = "L4D - No Mercy car barricade crescendo",
    author = "finishlast",
    description = "Block crescendo at the end of the no mercy subway map",
    version = "0.0.1",
    url = ""
}

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

Handle g_timer = INVALID_HANDLE;

int ent_dynamic_block1;
int ent_dynamic_block2;
int ent_dynamic_block3;

int dynamic_prop;
int dynamic_prop_button;
int dynamic_prop_fence;
int dynamic_prop_fence2;
int dynamic_prop_battery;
int dynamic_prop_cable;
int numlift = 0;
float bigger=1.0;
#define PARTICLE_BOMB1		"gas_explosion_pump"


public void OnPluginStart()
{
	PrecacheModel("models/props_vehicles/racecar_damaged.mdl");
	PrecacheModel("models/props_interiors/makeshift_stove_battery.mdl");
	PrecacheModel("models/props_street/barricade_door_01_damaged.mdl");
	PrecacheModel("models/props_street/barricade_door_01.mdl");
	PrecacheModel("models/props_street/police_barricade3.mdl");
	PrecacheModel("models/props_street/police_barricade2.mdl");
	PrecacheModel("models/props_lab/freightelevatorbutton.mdl");
 	PrecacheSound("animation/garage_outro.wav");
  	PrecacheSound("ambient/explosions/explode_1.wav");

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
	numlift = 0;
	bigger=1.0;
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_vs_hospital02_subway", false)  || StrEqual(sMap, "l4d_hospital02_subway", false) || StrEqual(sMap, "c8m2_subway", false))
	{

 	float pos[3], ang[3], fwd[3]; 

	pos[0] = 7820.0;
	pos[1] = 4855.0;
	pos[2] = 35.0;

	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 90.0;

	GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR); 
	ScaleVector(fwd, 100.0); 
	AddVectors(fwd, pos, fwd); 

	char origin[100]; 
	Format(origin, sizeof(origin), "%0.1f %0.1f %0.1f", fwd[0], fwd[1], fwd[2]); 

	// Flip 180 
	float output[3]; 
	MakeVectorFromPoints(fwd, pos, output); 
	GetVectorAngles(output, ang); 
	ang[0] = 0.0; 
	char targetname[100]; 
  	int tick = GetGameTickCount(); 
	Format(targetname, sizeof(targetname), "@glow_%i", tick); 

	CreateModel(fwd, ang, origin, targetname); 
	CreateButton(fwd, ang, origin, targetname); 

	pos[0] = 7954.0;
	pos[1] = 4936.0;
	pos[2] = 5.0;
	ang[0] = 0.0;
	ang[1] = 277.0;
	ang[2] = 0.0;

	ent_dynamic_block1 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_dynamic_block1, "model", "models/props_vehicles/racecar_damaged.mdl");
	DispatchKeyValue(ent_dynamic_block1, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block1, "solid", "6");
	DispatchSpawn(ent_dynamic_block1);
	TeleportEntity(ent_dynamic_block1, pos, ang, NULL_VECTOR);

	pos[0] = 7923.0;
	pos[1] = 4850.0;
	pos[2] = 15.0;
	ang[0] = 0.0;
	ang[1] = 270.0;
	ang[2] = 90.0;


	dynamic_prop_battery = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(dynamic_prop_battery, "model", "models/props_interiors/makeshift_stove_battery.mdl");
	DispatchKeyValue(dynamic_prop_battery, "disableshadows", "1");
	DispatchKeyValue(dynamic_prop_battery, "solid", "6");
	DispatchSpawn(dynamic_prop_battery);
	TeleportEntity(dynamic_prop_battery, pos, ang, NULL_VECTOR);


	pos[0] = 7916.0;
	pos[1] = 4856.0;
	pos[2] = 10.0;
	ang[0] = -90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;


	dynamic_prop_cable = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(dynamic_prop_cable, "model", "models/props_wasteland/prison_switchbox001a.mdl");
	DispatchKeyValue(dynamic_prop_cable, "disableshadows", "1");
	DispatchKeyValue(dynamic_prop_cable, "solid", "6");
	DispatchSpawn(dynamic_prop_cable);
	TeleportEntity(dynamic_prop_cable, pos, ang, NULL_VECTOR);

	pos[0] = 8632.0;
	pos[1] = 4760.0;
	pos[2] = 10.0;
	ang[0] = 0.0;
	ang[1] = 180.0;
	ang[2] = 0.0;

	dynamic_prop_fence = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(dynamic_prop_fence, "model", "models/props_street/police_barricade3.mdl");
	DispatchKeyValue(dynamic_prop_fence, "disableshadows", "1");
	DispatchKeyValue(dynamic_prop_fence, "solid", "6");
	DispatchSpawn(dynamic_prop_fence);
	TeleportEntity(dynamic_prop_fence, pos, ang, NULL_VECTOR);
	SDKHook(dynamic_prop_fence, SDKHook_Touch, OnTouch);

	pos[0] = 8632.0;
	pos[1] = 5420.0;
	pos[2] = 10.0;
	ang[0] = 0.0;
	ang[1] = 180.0;
	ang[2] = 0.0;

	dynamic_prop_fence2 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(dynamic_prop_fence2, "model", "models/props_street/police_barricade2.mdl");
	DispatchKeyValue(dynamic_prop_fence2, "disableshadows", "1");
	DispatchKeyValue(dynamic_prop_fence2, "solid", "6");
	DispatchSpawn(dynamic_prop_fence2);
	TeleportEntity(dynamic_prop_fence2, pos, ang, NULL_VECTOR);
	SDKHook(dynamic_prop_fence2, SDKHook_Touch, OnTouch);

	pos[0] = 8632.0;
	pos[1] = 5120.0;
	pos[2] = 10.0;
	ang[0] = 0.0;
	ang[1] = 180.0;
	ang[2] = 0.0;

	ent_dynamic_block2 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_dynamic_block2, "model", "models/props_street/barricade_door_01.mdl");
	DispatchKeyValue(ent_dynamic_block2, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block2, "solid", "6");
	DispatchSpawn(ent_dynamic_block2);
	TeleportEntity(ent_dynamic_block2, pos, ang, NULL_VECTOR);
	SDKHook(ent_dynamic_block2, SDKHook_Touch, OnTouch);

	HookSingleEntityOutput(dynamic_prop_button, "OnPressed", OnPressed);
	}
}


// Create dynamic model 
void CreateModel(const float fwd[3], const float ang[3], const char[] origin, const char[] targetname) 
{ 

     
	dynamic_prop = CreateEntityByName("prop_dynamic"); 
     
	if(dynamic_prop == -1) return; 

	DispatchKeyValue(dynamic_prop, "origin", origin); 
	DispatchKeyValue(dynamic_prop, "targetname", targetname); // important for func_button glow entity 

	DispatchKeyValue(dynamic_prop, "model", "models/props_mill/freightelevatorbutton02.mdl"); 
	//DispatchKeyValue(dynamic_prop, "model", "models/props_industrial/brickpallets_break09.mdl"); 
	DispatchKeyValue(dynamic_prop, "spawnflags", "0"); 
	/* 
	16 = Break on Touch 
	32 = Break on Pressure 
	64 = Use Hitboxes for Renderbox 
	256 = Start with collision disabled 
	*/ 

	DispatchSpawn(dynamic_prop); 
     
	TeleportEntity(dynamic_prop, fwd, ang, NULL_VECTOR); 
} 



void CreateButton(const float fwd[3], const float ang[3], const char[] origin, const char[] targetname) 
{ 

	dynamic_prop_button = CreateEntityByName("func_button"); 
     
	if(dynamic_prop_button == -1) return; 
     
	DispatchKeyValue(dynamic_prop_button, "origin", origin); // important or button start flying to 0, 0, 0 coordinates after press 
	DispatchKeyValue(dynamic_prop_button, "glow", targetname); 

	DispatchKeyValue(dynamic_prop_button, "wait", "-1");    // Default 3 sec, -1 stay. Glowing stop when button OnIn 
	DispatchKeyValue(dynamic_prop_button, "spawnflags", "1025"); // Don't move + Use Activates 
	/* 
	1 = Don't move 
	32 = Toggle 
	256 = Touch Activates 
	512 = Damage Activates 
	1024 = Use Activates 
	2048 = Starts Locked 
	4096 = Sparks 
	*/ 

	DispatchSpawn(dynamic_prop_button); 
	ActivateEntity(dynamic_prop_button); 
     
	TeleportEntity(dynamic_prop_button, fwd, ang, NULL_VECTOR); 
	//SetEntityModel(dynamic_prop_button, "models/props_industrial/brickpallets_break09.mdl");
	SetEntityModel(dynamic_prop_button, "models/props_mill/freightelevatorbutton02.mdl"); 

	float vMins[3] = {-30.0, -30.0, 0.0}, vMaxs[3] = {30.0, 30.0, 200.0}; 
	SetEntPropVector(dynamic_prop_button, Prop_Send, "m_vecMins", vMins); 
	SetEntPropVector(dynamic_prop_button, Prop_Send, "m_vecMaxs", vMaxs); 
     

	// This disable entity error 
	// ERROR:  Can't draw studio model models/props_lab/freightelevatorbutton.mdl because CBaseButton is not derived from C_BaseAnimating 

	int enteffects = GetEntProp(dynamic_prop_button, Prop_Send, "m_fEffects"); 
	enteffects |= 32; 
	SetEntProp(dynamic_prop_button, Prop_Send, "m_fEffects", enteffects); 
}  


public void OnPressed(const char[] output, int caller, int activator, float delay)
{
	//AcceptEntityInput(dynamic_prop_button, "Kill");
	//EmitSoundToAll(SOUND, ent_dynamic_block1);
	Command_Play("animation\\garage_outro.wav");
	Command_Play("animation\\garage_outro.wav");

	char command[] = "director_force_panic_event";
	char flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(activator, command);
	SetCommandFlags(command, flags);

	// Remove glow entity from func_button
	SetEntProp(dynamic_prop_button, Prop_Send, "m_glowEntity", -1); 
	g_timer = CreateTimer(0.1, gate, _, TIMER_REPEAT);
	
}

public Action gate(Handle timer)
{
	// Create a global variable visible only in the local scope (this function).
	float pos[3], ang[3], dir[3],posbarricade[3], angbarricade[3];
	GetEntPropVector(ent_dynamic_block1, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent_dynamic_block1, Prop_Send, "m_angRotation", ang);
	pos[0] += bigger;
	dir[0] = 0.0;

	if (numlift <= 35) 
	{
	pos[1] += 3.0;
	}
	else
	{
	pos[1] += 7.0;
	}

	dir[1] = 0.0;
	dir[2] = 0.0;


	if (numlift ==30)
{

	posbarricade[0] = 8632.0;
	posbarricade[1] = 5120.0;
	posbarricade[2] = 10.0;
	angbarricade[0] = 0.0;
	angbarricade[1] = 180.0;
	angbarricade[2] = 0.0;


	Command_Play("ambient\\explosions\\explode_1.wav");
	int entity1;
	entity1 = CreateEntityByName("info_particle_system");
	if( entity1 != -1 )
	{
		DispatchKeyValue(entity1, "effect_name", PARTICLE_BOMB1);

		DispatchSpawn(entity1);
		ActivateEntity(entity1);
		AcceptEntityInput(entity1, "start");

		TeleportEntity(entity1, posbarricade, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity1, "AddOutput");
		AcceptEntityInput(entity1, "FireUser1");
	}
	
	AcceptEntityInput(ent_dynamic_block2, "Kill");
	ent_dynamic_block3 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_dynamic_block3, "model", "models/props_street/barricade_door_01_damaged.mdl");
	DispatchKeyValue(ent_dynamic_block3, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block3, "solid", "6");
	DispatchSpawn(ent_dynamic_block3);
	TeleportEntity(ent_dynamic_block3, posbarricade, angbarricade, NULL_VECTOR);
}

    	TeleportEntity(ent_dynamic_block1, pos, ang, dir);

	
	if (numlift >= 71) 
	{
		numlift = 0;
		bigger = 1.0;
		SetConVarInt(FindConVar("sb_unstick"), 1);
		pos[2] += 10;
		TeleportEntity(ent_dynamic_block1, pos, ang, dir);
		int entity2;
		entity2 = CreateEntityByName("info_particle_system");
		if( entity2 != -1 )
		{
		DispatchKeyValue(entity2, "effect_name", PARTICLE_BOMB1);

		DispatchSpawn(entity2);
		ActivateEntity(entity2);
		AcceptEntityInput(entity2, "start");

		TeleportEntity(entity2, pos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity2, "AddOutput");
		AcceptEntityInput(entity2, "FireUser1");
		}
		
		pos[2] += 50.0;
		int ent_plane_touch_fire = CreateEntityByName("env_fire");
		DispatchKeyValue(ent_plane_touch_fire, "firesize", "100");
		DispatchKeyValue(ent_plane_touch_fire, "health", "1000");
		DispatchKeyValue(ent_plane_touch_fire, "firetype", "Normal");
		DispatchKeyValue(ent_plane_touch_fire, "damagescale", "0.0");
		DispatchKeyValue(ent_plane_touch_fire, "spawnflags", "256");
		SetVariantString("WaterSurfaceExplosion");
		AcceptEntityInput(ent_plane_touch_fire, "DispatchEffect");
		DispatchSpawn(ent_plane_touch_fire);
		TeleportEntity(ent_plane_touch_fire, pos , NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent_plane_touch_fire, "StartFire");
		SetVariantString("!activator");
	
		Command_Play("ambient\\explosions\\explode_1.wav");
		g_timer = null;
		return Plugin_Stop;
	}
 
    	TeleportEntity(ent_dynamic_block1, pos, ang, dir);


	bigger+=1.0;
	numlift++;
	return Plugin_Continue;
}

public Action Command_Play(const char[] arguments)
{

	for(int i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);

	}  
}

public void OnTouch(int client, int other)
{
	if(other>=0 && other <= MaxClients)
	{
		if(IsClientInGame(other) && IsFakeClient(other) && GetClientTeam(other) == 2)
		{
			SetConVarInt(FindConVar("sb_unstick"), 0);
			SDKUnhook(ent_dynamic_block1, SDKHook_Touch, OnTouch);
			SDKUnhook(dynamic_prop_fence, SDKHook_Touch, OnTouch);
			SDKUnhook(dynamic_prop_fence2, SDKHook_Touch, OnTouch);
		}
	}
}
