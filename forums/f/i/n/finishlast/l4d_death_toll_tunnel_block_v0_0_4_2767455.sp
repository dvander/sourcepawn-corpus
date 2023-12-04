/****************************************************************************************************
* Plugin     : L4D - Death Toll tunnel block crescendo
* Version    : 0.0.4
* Game       : Left 4 Dead
* Author     : Finishlast
*
* Testers    : Myself 
* Website    : www.l4d.com
* Purpose    : This plugin blocks the tunnel at death toll chapter 1 and sets up a mini crescendo
* Credits:
* Based on code from:
* https://forums.alliedmods.net/showthread.php?t=328013 Bacardi Freight lift button
* And snippets I forgot where I found them back in the day, sorry, if you recognize any please tell me.
* Silvers tons of help in scripting forum https://forums.alliedmods.net/showthread.php?t=335750
* Earendil for TIMER_FLAG_NO_MAPCHANGE & timer interval
* Marttt for the invalid index checks
* azalty for clearing up g_timer mistake 
* JLmelenchon for reporting stuck tank
* Dominatez & replay_84 reporting crash
* ZBzibing for providing error about crash cbaseentity & Silvers for saying I should convert index to ref
****************************************************************************************************/
public Plugin myinfo =
{
    name = "L4D - Death Toll tunnel block crescendo",
    author = "finishlast",
    description = "Block the tunnel at death toll chapter 1 and set up a mini crescendo",
    version = "0.0.4",
    url = "https://forums.alliedmods.net/showthread.php?p=2767455"
}

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

#define TEAM_INFECTED 3
#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8

static bool g_bAliveTank;

int activatortmp;
Handle g_timer = INVALID_HANDLE;
float Teleport_tank1[3] = { -13136.0, -10296.0, 211.0 };
float Teleport_tank2[3] = { -11442.0, -10605.0, 573.0 };
float Teleport_tank3[3] = { -11477.0, -12105.0, 630.0 };

float Teleport_Entrance1[3] = { -12573.0, -9913.0, 30.0 };

int ent_dynamic_block1;
int ent_dynamic_block2;
int ent_dynamic_block3;
int ent_dynamic_block4;
int ent_dynamic_block5;
int ent_dynamic_block6;
int ent_dynamic_block9;
int ent_dynamic_block10;
int ent_dynamic_block11;
int ent_dynamic_block12;
int ent_dynamic_block13;
int ent_dynamic_block14;
int ent_dynamic_block15;
int ent_dynamic_block16;
int ent_dynamic_block17;
int ent_dynamic_block18;
int ent_dynamic_block19;
int ent_dynamic_block20;
int ent_dynamic_block21;
int ent_dynamic_block22;
int ent_dynamic_block23;
int ent_dynamic_block24;
int ent_dynamic_block25;
int ent_dynamic_block26;
int ent_dynamic_block27;
int ent_dynamic_block28;
int ent_dynamic_block29;
int ent_dynamic_block30;
int ent_dynamic_block31;
int ent_dynamic_block32;
int ent_dynamic_block33;
int ent_dynamic_block34;
int ent_dynamic_block35;
int ent_dynamic_block36;
int ent_dynamic_block37;
int ent_dynamic_block38;
int ent_dynamic_block39;
int ent_dynamic_block40;
int ent_dynamic_block41;
int ent_dynamic_block42;
int ent_dynamic_block43;
int ent_dynamic_block44;

int dynamic_prop;
int dynamic_prop_button;
int numlift = 0;

#define PARTICLE_BOMB1		"gas_explosion_main"

public void OnPluginStart()
{
	PrecacheModel("models/props_industrial/barrel_fuel.mdl",true);
	PrecacheModel("models/props_interiors/makeshift_stove_battery.mdl",true);
	PrecacheModel("models/props_street/barricade_door_01_damaged.mdl",true);
	PrecacheModel("models/props_wasteland/prison_switchbox001a.mdl",true);
	PrecacheModel("models/props_debris/concrete_debris256barricade001a.mdl",true);
	PrecacheModel("models/props_debris/concrete_debris256pile001a.mdl",true);
	PrecacheModel("models/props_debris/concrete_debris128pile001b.mdl",true);
	PrecacheModel("models/props_debris/concrete_wall01a.mdl",true);
	PrecacheModel("models/props_debris/concrete_section128wall001a.mdl",true);
	PrecacheModel("models/props_interiors/concretepiller01_dm01_1.mdl",true);
	PrecacheModel("models/props_interiors/concretepiller01_dm01_2.mdl",true);
	PrecacheModel("models/props_mill/freightelevatorbutton02.mdl",true);
 	PrecacheSound("ambient/explosions/explode_1.wav");
	PrecacheSound("buttons/blip2.wav");
 	PrecacheSound("buttons/button11.wav");
 	PrecacheSound("buttons/button4.wav");
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
	HookEvent("round_end", event_round_end, EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
delete g_timer;
numlift = 0;
g_bAliveTank=false;

}

public void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
delete g_timer;
numlift = 0;
g_bAliveTank=false;

}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	numlift = 0;
	g_bAliveTank=false;

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_vs_smalltown01_caves", false) || StrEqual(sMap, "l4d_smalltown01_caves", false) || StrEqual(sMap, "c10m1_caves", false))
	{

 	float pos[3], ang[3], fwd[3]; 

	pos[0] = -12230.0;
	pos[1] = -9781.0;
	pos[2] = -21.0;

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

	pos[0] = -12315.0;
	pos[1] = -9781.0;
	pos[2] = -50.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;


	ent_dynamic_block1 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block1, "model", "models/props_industrial/barrel_fuel.mdl");
	DispatchKeyValue(ent_dynamic_block1, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block1, "solid", "6");
	DispatchSpawn(ent_dynamic_block1);
	TeleportEntity(ent_dynamic_block1, pos, ang, NULL_VECTOR);
	ent_dynamic_block1 = EntIndexToEntRef(ent_dynamic_block1);

	pos[0] = -12330.0;
	pos[1] = -9781.0;
	pos[2] = -27.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block2 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block2, "model", "models/props_industrial/barrel_fuel.mdl");
	DispatchKeyValue(ent_dynamic_block2, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block2, "solid", "6");
	DispatchSpawn(ent_dynamic_block2);
	TeleportEntity(ent_dynamic_block2, pos, ang, NULL_VECTOR);
	ent_dynamic_block2 = EntIndexToEntRef(ent_dynamic_block2);


	pos[0] = -12345.0;
	pos[1] = -9781.0;
	pos[2] = -50.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block3 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block3, "model", "models/props_industrial/barrel_fuel.mdl");
	DispatchKeyValue(ent_dynamic_block3, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block3, "solid", "6");
	DispatchSpawn(ent_dynamic_block3);
	TeleportEntity(ent_dynamic_block3, pos, ang, NULL_VECTOR);
	ent_dynamic_block3 = EntIndexToEntRef(ent_dynamic_block3);


	pos[0] = -12362.0;
	pos[1] = -9781.0;
	pos[2] = -27.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block4 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block4, "model", "models/props_industrial/barrel_fuel.mdl");
	DispatchKeyValue(ent_dynamic_block4, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block4, "solid", "6");
	DispatchSpawn(ent_dynamic_block4);
	TeleportEntity(ent_dynamic_block4, pos, ang, NULL_VECTOR);
	ent_dynamic_block4 = EntIndexToEntRef(ent_dynamic_block4);


	pos[0] = -12381.0;
	pos[1] = -9781.0;
	pos[2] = -48.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block5 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block5, "model", "models/props_industrial/barrel_fuel.mdl");
	DispatchKeyValue(ent_dynamic_block5, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block5, "solid", "6");
	DispatchSpawn(ent_dynamic_block5);
	TeleportEntity(ent_dynamic_block5, pos, ang, NULL_VECTOR);
	ent_dynamic_block5 = EntIndexToEntRef(ent_dynamic_block5);

	pos[0] = -12410.0;
	pos[1] = -9781.0;
	pos[2] = -50.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block6 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block6, "model", "models/props_industrial/barrel_fuel.mdl");
	DispatchKeyValue(ent_dynamic_block6, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block6, "solid", "6");
	DispatchSpawn(ent_dynamic_block6);
	TeleportEntity(ent_dynamic_block6, pos, ang, NULL_VECTOR);
	ent_dynamic_block6 = EntIndexToEntRef(ent_dynamic_block6);


	pos[0] = -12250.0 ;
	pos[1] = -9781.0;
	pos[2] = -62.0;
	ang[0] = 270.0;
	ang[1] = 90.0;
	ang[2] = 90.0;

	ent_dynamic_block10 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block10, "model", "models/props_wasteland/prison_switchbox001a.mdl");
	DispatchKeyValue(ent_dynamic_block10, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block10, "solid", "6");
	DispatchSpawn(ent_dynamic_block10);
	TeleportEntity(ent_dynamic_block10, pos, ang, NULL_VECTOR);
	ent_dynamic_block10 = EntIndexToEntRef(ent_dynamic_block10);

	pos[0] = -12150.0 ;
	pos[1] = -9781.0;
	pos[2] = -62.0;
	ang[0] = 270.0;
	ang[1] = 90.0;
	ang[2] = 90.0;

	ent_dynamic_block11 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block11, "model", "models/props_wasteland/prison_switchbox001a.mdl");
	DispatchKeyValue(ent_dynamic_block11, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block11, "solid", "6");
	DispatchSpawn(ent_dynamic_block11);
	TeleportEntity(ent_dynamic_block11, pos, ang, NULL_VECTOR);
	ent_dynamic_block11 = EntIndexToEntRef(ent_dynamic_block11);


	pos[0] = -12205.0;
	pos[1] = -9770.0;
	pos[2] = -73.0;
	ang[0] = 0.0;
	ang[1] = 5.0;
	ang[2] = 90.0;

	ent_dynamic_block9 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block9, "model", "models/props_interiors/makeshift_stove_battery.mdl");
	DispatchKeyValue(ent_dynamic_block9, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block9, "solid", "6");
	DispatchSpawn(ent_dynamic_block9);
	TeleportEntity(ent_dynamic_block9, pos, ang, NULL_VECTOR);
	ent_dynamic_block9 = EntIndexToEntRef(ent_dynamic_block9);


	pos[0] = -12215.0;
	pos[1] = -9751.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block12 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block12, "model", "models/props_debris/concrete_debris256barricade001a.mdl");
	DispatchKeyValue(ent_dynamic_block12, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block12, "solid", "6");
	DispatchSpawn(ent_dynamic_block12);
	TeleportEntity(ent_dynamic_block12, pos, ang, NULL_VECTOR);
	SDKHook(ent_dynamic_block12, SDKHook_Touch, OnTouch);
	ent_dynamic_block12 = EntIndexToEntRef(ent_dynamic_block12);

	pos[0] = -12350.0;
	pos[1] = -9751.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block13 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block13, "model", "models/props_debris/concrete_debris256barricade001a.mdl");
	DispatchKeyValue(ent_dynamic_block13, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block13, "solid", "6");
	DispatchSpawn(ent_dynamic_block13);
	TeleportEntity(ent_dynamic_block13, pos, ang, NULL_VECTOR);
	SDKHook(ent_dynamic_block13, SDKHook_Touch, OnTouch);
	ent_dynamic_block13 = EntIndexToEntRef(ent_dynamic_block13);

	pos[0] = -12515.0;
	pos[1] = -9751.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block14 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block14, "model", "models/props_debris/concrete_debris256barricade001a.mdl");
	DispatchKeyValue(ent_dynamic_block14, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block14, "solid", "6");
	DispatchSpawn(ent_dynamic_block14);
	TeleportEntity(ent_dynamic_block14, pos, ang, NULL_VECTOR);
	SDKHook(ent_dynamic_block14, SDKHook_Touch, OnTouch);
	ent_dynamic_block14 = EntIndexToEntRef(ent_dynamic_block14);

	pos[0] = -12215.0;
	pos[1] = -9751.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block15 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block15, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block15, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block15, "solid", "6");
	DispatchSpawn(ent_dynamic_block15);
	TeleportEntity(ent_dynamic_block15, pos, ang, NULL_VECTOR);
	ent_dynamic_block15 = EntIndexToEntRef(ent_dynamic_block15);
	pos[0] = -12350.0;
	pos[1] = -9751.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block16 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block16, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block16, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block16, "solid", "6");
	DispatchSpawn(ent_dynamic_block16);
	TeleportEntity(ent_dynamic_block16, pos, ang, NULL_VECTOR);
	ent_dynamic_block16 = EntIndexToEntRef(ent_dynamic_block16);
	pos[0] = -12515.0;
	pos[1] = -9751.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block17 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block17, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block17, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block17, "solid", "6");
	DispatchSpawn(ent_dynamic_block17);
	TeleportEntity(ent_dynamic_block17, pos, ang, NULL_VECTOR);
	ent_dynamic_block17 = EntIndexToEntRef(ent_dynamic_block17);

	pos[0] = -12515.0;
	pos[1] = -9751.0;
	pos[2] = 150.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block18 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block18, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block18, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block18, "solid", "6");
	DispatchSpawn(ent_dynamic_block18);
	TeleportEntity(ent_dynamic_block18, pos, ang, NULL_VECTOR);
	ent_dynamic_block18 = EntIndexToEntRef(ent_dynamic_block18);

	pos[0] = -12350.0;
	pos[1] = -9751.0;
	pos[2] = 150.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block19 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block19, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block19, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block19, "solid", "6");
	DispatchSpawn(ent_dynamic_block19);
	TeleportEntity(ent_dynamic_block19, pos, ang, NULL_VECTOR);
	ent_dynamic_block19 = EntIndexToEntRef(ent_dynamic_block19);

	pos[0] = -12515.0;
	pos[1] = -9751.0;
	pos[2] = 150.0;
	ang[0] = 90.0;
	ang[1] = 270.0;
	ang[2] = 0.0;

	ent_dynamic_block20 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_dynamic_block20, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block20, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block20, "solid", "6");
	DispatchSpawn(ent_dynamic_block20);
	TeleportEntity(ent_dynamic_block20, pos, ang, NULL_VECTOR);
	ent_dynamic_block20 = EntIndexToEntRef(ent_dynamic_block20);

	pos[0] = -12215.0;
	pos[1] = -9701.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block21 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block21, "model", "models/props_debris/concrete_debris256barricade001a.mdl");
	DispatchKeyValue(ent_dynamic_block21, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block21, "solid", "6");
	DispatchSpawn(ent_dynamic_block21);
	TeleportEntity(ent_dynamic_block21, pos, ang, NULL_VECTOR);
	ent_dynamic_block21 = EntIndexToEntRef(ent_dynamic_block21);

	pos[0] = -12350.0;
	pos[1] = -9701.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block22 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block22, "model", "models/props_debris/concrete_debris256barricade001a.mdl");
	DispatchKeyValue(ent_dynamic_block22, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block22, "solid", "6");
	DispatchSpawn(ent_dynamic_block22);
	TeleportEntity(ent_dynamic_block22, pos, ang, NULL_VECTOR);
	ent_dynamic_block22 = EntIndexToEntRef(ent_dynamic_block22);

	pos[0] = -12515.0;
	pos[1] = -9701.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block23 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block23, "model", "models/props_debris/concrete_debris256barricade001a.mdl");
	DispatchKeyValue(ent_dynamic_block23, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block23, "solid", "6");
	DispatchSpawn(ent_dynamic_block23);
	TeleportEntity(ent_dynamic_block23, pos, ang, NULL_VECTOR);
	ent_dynamic_block23 = EntIndexToEntRef(ent_dynamic_block23);

	pos[0] = -12215.0;
	pos[1] = -9701.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block24 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_dynamic_block24, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block24, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block24, "solid", "6");
	DispatchSpawn(ent_dynamic_block24);
	TeleportEntity(ent_dynamic_block24, pos, ang, NULL_VECTOR);
	ent_dynamic_block24 = EntIndexToEntRef(ent_dynamic_block24);

	pos[0] = -12350.0;
	pos[1] = -9701.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block25 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block25, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block25, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block25, "solid", "6");
	DispatchSpawn(ent_dynamic_block25);
	TeleportEntity(ent_dynamic_block25, pos, ang, NULL_VECTOR);
	ent_dynamic_block25 = EntIndexToEntRef(ent_dynamic_block25);

	pos[0] = -12515.0;
	pos[1] = -9701.0;
	pos[2] = 0.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block26 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block26, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block26, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block26, "solid", "6");
	DispatchSpawn(ent_dynamic_block26);
	TeleportEntity(ent_dynamic_block26, pos, ang, NULL_VECTOR);
	ent_dynamic_block26 = EntIndexToEntRef(ent_dynamic_block26);

	pos[0] = -12515.0;
	pos[1] = -9701.0;
	pos[2] = 150.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block27 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block27, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block27, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block27, "solid", "6");
	DispatchSpawn(ent_dynamic_block27);
	TeleportEntity(ent_dynamic_block27, pos, ang, NULL_VECTOR);
	ent_dynamic_block27 = EntIndexToEntRef(ent_dynamic_block27);

	pos[0] = -12350.0;
	pos[1] = -9701.0;
	pos[2] = 150.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block28 = CreateEntityByName("prop_dynamic"); 
 
	DispatchKeyValue(ent_dynamic_block28, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block28, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block28, "solid", "6");
	DispatchSpawn(ent_dynamic_block28);
	TeleportEntity(ent_dynamic_block28, pos, ang, NULL_VECTOR);
	ent_dynamic_block28 = EntIndexToEntRef(ent_dynamic_block28);

	pos[0] = -12515.0;
	pos[1] = -9701.0;
	pos[2] = 150.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block29 = CreateEntityByName("prop_dynamic"); 
	DispatchKeyValue(ent_dynamic_block29, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block29, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block29, "solid", "6");
	DispatchSpawn(ent_dynamic_block29);
	TeleportEntity(ent_dynamic_block29, pos, ang, NULL_VECTOR);
	ent_dynamic_block29 = EntIndexToEntRef(ent_dynamic_block29);
	HookSingleEntityOutput(dynamic_prop_button, "OnPressed", OnPressed);
	}
}


public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
char sMap[64];
GetCurrentMap(sMap, sizeof(sMap));
if (StrEqual(sMap, "l4d_vs_smalltown01_caves", false) || StrEqual(sMap, "l4d_smalltown01_caves", false) || StrEqual(sMap, "c10m1_caves", false))
	{
 	
	if (numlift==0 && g_bAliveTank==false){ 
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		//PrintToChatAll("[SM] Teleport tank.");	
		CreateTimer(0.2, teleport, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	g_bAliveTank = true;
	}
}

public Action teleport(Handle timer,int client)
{
		//PrintToChatAll("[SM] Teleport tank.");
		int random = GetRandomInt(1,3);
		//PrintToChatAll("A random number is %d", random);

		switch(random)
		{
     		case 1:
     		{
           	TeleportEntity(client, Teleport_tank1, NULL_VECTOR, NULL_VECTOR);
     		}
     		case 2:
     		{
           	TeleportEntity(client, Teleport_tank2, NULL_VECTOR, NULL_VECTOR);
     		}
     		case 3:
     		{
          	 TeleportEntity(client, Teleport_tank3, NULL_VECTOR, NULL_VECTOR);
     		}
		}
		return Plugin_Continue;
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
	Command_Play("buttons\\button4.wav");
	// Remove glow entity from func_button
	SetEntProp(dynamic_prop_button, Prop_Send, "m_glowEntity", -1); 
	g_timer = CreateTimer(0.01, gate, _, TIMER_REPEAT);
	activatortmp = activator;	
}

public Action gate(Handle timer)
{
	// Create a global variable visible only in the local scope (this function).
	float pos[3],ang[3],dir[3],posbarricade[3], angbarricade[3];
	

	if (numlift ==10){
		PrintToChatAll("Detonation in 9");	
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==20){
		PrintToChatAll("Detonation in 8");	
		Command_Play("buttons\\blip2.wav");
	}

	if (numlift ==30){
		PrintToChatAll("Detonation in 7");	
		Command_Play("buttons\\blip2.wav");
	}

	if (numlift ==40){
		PrintToChatAll("Detonation in 6");	
		Command_Play("buttons\\blip2.wav");
	}

	if (numlift ==50){
		PrintToChatAll("Detonation in 5");	
		Command_Play("buttons\\blip2.wav");
	}

	if (numlift ==60){
		PrintToChatAll("Detonation in 4");	
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==65){
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==70){
		PrintToChatAll("Detonation in 3");	
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==75){
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==80){
		PrintToChatAll("Detonation in 2");	
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==85){
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==90){
		PrintToChatAll("Detonation in 1");	
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==93){
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==95){
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==97){
		Command_Play("buttons\\blip2.wav");
	}
	if (numlift ==99){
		Command_Play("buttons\\button11.wav");
	}

	if (numlift ==101)
	{
	PrintToChatAll("!BANG!");	
	SetConVarInt(FindConVar("sb_unstick"), 1);
	posbarricade[0] = -12345.0;
	posbarricade[1] = -9781.0;
	posbarricade[2] = -65.0;
	angbarricade[0] = 0.0;
	angbarricade[1] = 0.0;
	angbarricade[2] = 0.0;

	Command_Play("ambient\\explosions\\explode_1.wav");
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

	ent_dynamic_block1 = EntRefToEntIndex(ent_dynamic_block1);

	if (ent_dynamic_block1 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block1, "Kill");
	}

	ent_dynamic_block2 = EntRefToEntIndex(ent_dynamic_block2);

	if (ent_dynamic_block2 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block2, "Kill");
	}

	ent_dynamic_block3 = EntRefToEntIndex(ent_dynamic_block3);

	if (ent_dynamic_block3 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block3, "Kill");
	}

	ent_dynamic_block4 = EntRefToEntIndex(ent_dynamic_block4);

	if (ent_dynamic_block4 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block4, "Kill");
	}

	ent_dynamic_block5 = EntRefToEntIndex(ent_dynamic_block5);

	if (ent_dynamic_block5 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block5, "Kill");
	}

	ent_dynamic_block6 = EntRefToEntIndex(ent_dynamic_block6);

	if (ent_dynamic_block6 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block6, "Kill");
	}

	ent_dynamic_block9 = EntRefToEntIndex(ent_dynamic_block9);

	if (ent_dynamic_block9 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block9, "Kill");
	}

	ent_dynamic_block10 = EntRefToEntIndex(ent_dynamic_block10);

	if (ent_dynamic_block10 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block10, "Kill");
	}

	ent_dynamic_block11 = EntRefToEntIndex(ent_dynamic_block11);

	if (ent_dynamic_block11 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block11, "Kill");
	}

	ent_dynamic_block12 = EntRefToEntIndex(ent_dynamic_block12);

	if (ent_dynamic_block12 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block12, "Kill");
	}

	ent_dynamic_block13 = EntRefToEntIndex(ent_dynamic_block13);

	if (ent_dynamic_block13 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block13, "Kill");
	}

	ent_dynamic_block14 = EntRefToEntIndex(ent_dynamic_block14);

	if (ent_dynamic_block14 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block14, "Kill");
	}

	ent_dynamic_block15 = EntRefToEntIndex(ent_dynamic_block15);

	if (ent_dynamic_block15 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block15, "Kill");
	}

	ent_dynamic_block16 = EntRefToEntIndex(ent_dynamic_block16);

	if (ent_dynamic_block16 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block16, "Kill");
	}

	ent_dynamic_block17 = EntRefToEntIndex(ent_dynamic_block17);

	if (ent_dynamic_block17 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block17, "Kill");
	}

	ent_dynamic_block18 = EntRefToEntIndex(ent_dynamic_block18);

	if (ent_dynamic_block18 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block18, "Kill");
	}

	ent_dynamic_block19 = EntRefToEntIndex(ent_dynamic_block19);

	if (ent_dynamic_block19 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block19, "Kill");
	}

	ent_dynamic_block20 = EntRefToEntIndex(ent_dynamic_block20);

	if (ent_dynamic_block20 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block20, "Kill");
	}

	ent_dynamic_block21 = EntRefToEntIndex(ent_dynamic_block21);

	if (ent_dynamic_block21 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block21, "Kill");
	}

	ent_dynamic_block22 = EntRefToEntIndex(ent_dynamic_block22);

	if (ent_dynamic_block22 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block22, "Kill");
	}

	ent_dynamic_block23 = EntRefToEntIndex(ent_dynamic_block23);

	if (ent_dynamic_block23 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block23, "Kill");
	}

	ent_dynamic_block24 = EntRefToEntIndex(ent_dynamic_block24);

	if (ent_dynamic_block24 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block24, "Kill");
	}

	ent_dynamic_block25 = EntRefToEntIndex(ent_dynamic_block25);

	if (ent_dynamic_block25 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block25, "Kill");
	}

	ent_dynamic_block26 = EntRefToEntIndex(ent_dynamic_block26);

	if (ent_dynamic_block26 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block26, "Kill");
	}

	ent_dynamic_block27 = EntRefToEntIndex(ent_dynamic_block27);

	if (ent_dynamic_block27 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block27, "Kill");
	}

	ent_dynamic_block28 = EntRefToEntIndex(ent_dynamic_block28);

	if (ent_dynamic_block28 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block28, "Kill");
	}

	ent_dynamic_block29 = EntRefToEntIndex(ent_dynamic_block29);

	if (ent_dynamic_block29 != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent_dynamic_block29, "Kill");
	}

	pos[0] = -12345.0;
	pos[1] = -9828.0;
	pos[2] = -54.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;

	ent_dynamic_block30 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block30, "model", "models/props_debris/concrete_debris128pile001b.mdl");
	DispatchKeyValue(ent_dynamic_block30, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block30, "solid", "1");
	DispatchSpawn(ent_dynamic_block30);
	TeleportEntity(ent_dynamic_block30, pos, ang, NULL_VECTOR);

	pos[0] = -12215.0;
	pos[1] = -9830.0;
	pos[2] = -54.0;
	ang[0] = 0.0;
	ang[1] = 30.0;
	ang[2] = 0.0;

	ent_dynamic_block31 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block31, "model", "models/props_debris/concrete_debris256pile001a.mdl");
	DispatchKeyValue(ent_dynamic_block31, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block31, "solid", "1");
	DispatchSpawn(ent_dynamic_block31);
	TeleportEntity(ent_dynamic_block31, pos, ang, NULL_VECTOR);

	pos[0] = -12483.0;
	pos[1] = -9806.0;
	pos[2] = -54.0;
	ang[0] = 0.0;
	ang[1] = 100.0;
	ang[2] = 0.0;

	ent_dynamic_block32 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block32, "model", "models/props_debris/concrete_debris128pile001b.mdl");
	DispatchKeyValue(ent_dynamic_block32, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block32, "solid", "1");
	DispatchSpawn(ent_dynamic_block32);
	TeleportEntity(ent_dynamic_block32, pos, ang, NULL_VECTOR);

	pos[0] = -12515.0;
	pos[1] = -9701.0;
	pos[2] = 50.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;
	dir[0] = 0.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 160.0;

	ent_dynamic_block33 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block33, "model", "models/props_debris/concrete_wall01a.mdl");
	DispatchKeyValue(ent_dynamic_block33, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block33, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block33, "AddOutput");
	AcceptEntityInput(ent_dynamic_block33, "FireUser1");
	DispatchSpawn(ent_dynamic_block33);
	TeleportEntity(ent_dynamic_block33, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block33, pos, ang, dir);
	ent_dynamic_block33 = EntIndexToEntRef(ent_dynamic_block33);

	pos[0] = -12215.0;
	pos[1] = -9701.0;
	pos[2] = 80.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;
	dir[0] = 0.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 166.0;

	ent_dynamic_block34 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block34, "model", "models/props_debris/concrete_section128wall001a.mdl");
	DispatchKeyValue(ent_dynamic_block34, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block34, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block34, "AddOutput");
	AcceptEntityInput(ent_dynamic_block34, "FireUser1");
	DispatchSpawn(ent_dynamic_block34);
	TeleportEntity(ent_dynamic_block34, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block34, pos, ang, dir);
	ent_dynamic_block34 = EntIndexToEntRef(ent_dynamic_block34);

	pos[0] = -12215.0;
	pos[1] = -9701.0;
	pos[2] = 50.0;
	ang[0] = 90.0;
	ang[1] = 90.0;
	ang[2] = 0.0;
	dir[0] = pos[2]+ 20.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 100.0;

	ent_dynamic_block35 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block35, "model", "models/props_interiors/concretepiller01_dm01_1.mdl");
	DispatchKeyValue(ent_dynamic_block35, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block35, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block35, "AddOutput");
	AcceptEntityInput(ent_dynamic_block35, "FireUser1");
	DispatchSpawn(ent_dynamic_block35);
	TeleportEntity(ent_dynamic_block35, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block35, pos, ang, dir);
	ent_dynamic_block35 = EntIndexToEntRef(ent_dynamic_block35);

	pos[0] = -12555.0;
	pos[1] = -9701.0;
	pos[2] = 70.0;
	ang[0] = 50.0;
	ang[1] = 60.0;
	ang[2] = 70.0;
	dir[0] = 0.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 160.0;

	ent_dynamic_block36 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block36, "model", "models/props_debris/concrete_wall01a.mdl");
	DispatchKeyValue(ent_dynamic_block36, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block36, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block36, "AddOutput");
	AcceptEntityInput(ent_dynamic_block36, "FireUser1");
	DispatchSpawn(ent_dynamic_block36);
	TeleportEntity(ent_dynamic_block36, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block36, pos, ang, dir);
	ent_dynamic_block36 = EntIndexToEntRef(ent_dynamic_block36);

	pos[0] = -12315.0;
	pos[1] = -9701.0;
	pos[2] = 60.0;
	ang[0] = 50.0;
	ang[1] = 70.0;
	ang[2] = 0.0;
	dir[0] = 0.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 166.0;

	ent_dynamic_block37 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block37, "model", "models/props_interiors/concretepiller01_dm01_2.mdl");
	DispatchKeyValue(ent_dynamic_block37, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block37, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block37, "AddOutput");
	AcceptEntityInput(ent_dynamic_block37, "FireUser1");
	DispatchSpawn(ent_dynamic_block37);
	TeleportEntity(ent_dynamic_block37, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block37, pos, ang, dir);
	ent_dynamic_block37 = EntIndexToEntRef(ent_dynamic_block37);

	pos[0] = -12115.0;
	pos[1] = -9701.0;
	pos[2] = 60.0;
	ang[0] = 40.0;
	ang[1] = 30.0;
	ang[2] = 0.0;
	dir[0] = pos[0] + 20.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 100.0;

	ent_dynamic_block38 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block38, "model", "models/props_interiors/concretepiller01_dm01_1.mdl");
	DispatchKeyValue(ent_dynamic_block38, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block38, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block38, "AddOutput");
	AcceptEntityInput(ent_dynamic_block38, "FireUser1");
	DispatchSpawn(ent_dynamic_block38);
	TeleportEntity(ent_dynamic_block38, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block38, pos, ang, dir);
	ent_dynamic_block38 = EntIndexToEntRef(ent_dynamic_block38);

	pos[0] = -12485.0;
	pos[1] = -9701.0;
	pos[2] = 70.0;
	ang[0] = 50.0;
	ang[1] = 60.0;
	ang[2] = 70.0;
	dir[0] = 0.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 160.0;

	ent_dynamic_block39 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block39, "model", "models/props_debris/concrete_wall01a.mdl");
	DispatchKeyValue(ent_dynamic_block39, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block39, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block39, "AddOutput");
	AcceptEntityInput(ent_dynamic_block39, "FireUser1");
	DispatchSpawn(ent_dynamic_block39);
	TeleportEntity(ent_dynamic_block39, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block39, pos, ang, dir);
	ent_dynamic_block39 = EntIndexToEntRef(ent_dynamic_block39);

	pos[0] = -12385.0;
	pos[1] = -9701.0;
	pos[2] = 60.0;
	ang[0] = 40.0;
	ang[1] = 70.0;
	ang[2] = 0.0;
	dir[0] = pos[0] + 20.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 156.0;

	ent_dynamic_block40 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block40, "model", "models/props_interiors/concretepiller01_dm01_2.mdl");
	DispatchKeyValue(ent_dynamic_block40, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block40, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block40, "AddOutput");
	AcceptEntityInput(ent_dynamic_block40, "FireUser1");
	DispatchSpawn(ent_dynamic_block40);
	TeleportEntity(ent_dynamic_block40, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block40, pos, ang, dir);
	ent_dynamic_block40 = EntIndexToEntRef(ent_dynamic_block40);

	pos[0] = -12155.0;
	pos[1] = -9701.0;
	pos[2] = 60.0;
	ang[0] = 100.0;
	ang[1] = 30.0;
	ang[2] = 0.0;
	dir[0] = pos[0] + 20.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 120.0;

	ent_dynamic_block41 = CreateEntityByName("prop_physics_override"); 
 
	DispatchKeyValue(ent_dynamic_block41, "model", "models/props_interiors/concretepiller01_dm01_1.mdl");
	DispatchKeyValue(ent_dynamic_block41, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block41, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block41, "AddOutput");
	AcceptEntityInput(ent_dynamic_block41, "FireUser1");
	DispatchSpawn(ent_dynamic_block41);
	TeleportEntity(ent_dynamic_block41, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block41, pos, ang, dir);
	ent_dynamic_block41 = EntIndexToEntRef(ent_dynamic_block41);


	pos[0] = -12485.0;
	pos[1] = -9701.0;
	pos[2] = 70.0;
	ang[0] = 50.0;
	ang[1] = 60.0;
	ang[2] = 70.0;
	dir[0] = pos[0] - 20.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 160.0;

	ent_dynamic_block42 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block42, "model", "models/props_interiors/concretepiller01_dm01_1.mdl");
	DispatchKeyValue(ent_dynamic_block42, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block42, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block42, "AddOutput");
	AcceptEntityInput(ent_dynamic_block42, "FireUser1");
	DispatchSpawn(ent_dynamic_block42);
	TeleportEntity(ent_dynamic_block42, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block42, pos, ang, dir);
	ent_dynamic_block42 = EntIndexToEntRef(ent_dynamic_block42);

	pos[0] = -12385.0;
	pos[1] = -9701.0;
	pos[2] = 60.0;
	ang[0] = 40.0;
	ang[1] = 70.0;
	ang[2] = 0.0;
	dir[0] = pos[0] - 20.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 116.0;

	ent_dynamic_block43 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block43, "model", "models/props_interiors/concretepiller01_dm01_2.mdl");
	DispatchKeyValue(ent_dynamic_block43, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block43, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block43, "AddOutput");
	AcceptEntityInput(ent_dynamic_block43, "FireUser1");
	DispatchSpawn(ent_dynamic_block43);
	TeleportEntity(ent_dynamic_block43, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block43, pos, ang, dir);
	ent_dynamic_block43 = EntIndexToEntRef(ent_dynamic_block43);

	pos[0] = -12155.0;
	pos[1] = -9701.0;
	pos[2] = 60.0;
	ang[0] = 100.0;
	ang[1] = 30.0;
	ang[2] = 0.0;
	dir[0] = pos[0] - 20.0;
	dir[1] = pos[1] - 390.0;
	dir[2] = 140.0;

	ent_dynamic_block44 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block44, "model", "models/props_interiors/concretepiller01_dm01_1.mdl");
	DispatchKeyValue(ent_dynamic_block44, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block44, "solid", "1");
	SetVariantString("OnUser1 !self:Kill::10:-1");
	AcceptEntityInput(ent_dynamic_block44, "AddOutput");
	AcceptEntityInput(ent_dynamic_block44, "FireUser1");
	DispatchSpawn(ent_dynamic_block44);
	TeleportEntity(ent_dynamic_block44, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block44, pos, ang, dir);
	ent_dynamic_block44 = EntIndexToEntRef(ent_dynamic_block44);

	CreateTimer(1.5, changevDir);
	panicevent(activatortmp);
	for(int Client = 1; Client <= MaxClients; Client++)
 	{
  		if(IsClientInGame(Client) && IsPlayerAlive(Client))
  		{
   			float Client_Origin[3], Distance1;
   			GetClientAbsOrigin(Client, Client_Origin);
   			Distance1 = GetVectorDistance(Client_Origin, Teleport_Entrance1);
   			if(Distance1 <= 500 && GetClientTeam(Client) == 2)
			{
				ForcePlayerSuicide(Client);	
			}
		}
	}
	g_timer = null;
	return Plugin_Stop;    
	}
	numlift++;
	return Plugin_Continue;
}

public Action changevDir(Handle timer)
{
	float vPos[3], vAng[3], vDir[3];
	vDir[0] = 0.0;
	vDir[1] = 0.0;
	vDir[2] = 0.0;

	ent_dynamic_block33 = EntRefToEntIndex(ent_dynamic_block33);

	if (ent_dynamic_block33 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block33, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block33, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block33, vPos, vAng, vDir);
	}

	ent_dynamic_block34 = EntRefToEntIndex(ent_dynamic_block34);

	if (ent_dynamic_block34 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block34, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block34, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block34, vPos, vAng, vDir);
	}

	ent_dynamic_block35 = EntRefToEntIndex(ent_dynamic_block35);

	if (ent_dynamic_block35 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block35, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block35, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block35, vPos, vAng, vDir);
	}


	ent_dynamic_block36 = EntRefToEntIndex(ent_dynamic_block36);

	if (ent_dynamic_block36 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block36, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block36, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block36, vPos, vAng, vDir);
	}

	ent_dynamic_block37 = EntRefToEntIndex(ent_dynamic_block37);

	if (ent_dynamic_block37 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block37, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block37, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block37, vPos, vAng, vDir);
	}


	ent_dynamic_block38 = EntRefToEntIndex(ent_dynamic_block38);

	if (ent_dynamic_block38 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block38, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block38, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block38, vPos, vAng, vDir);
	}

	ent_dynamic_block39 = EntRefToEntIndex(ent_dynamic_block39);

	if (ent_dynamic_block39 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block39, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block39, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block39, vPos, vAng, vDir);
	}

	ent_dynamic_block40 = EntRefToEntIndex(ent_dynamic_block40);

	if (ent_dynamic_block40 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block40, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block40, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block40, vPos, vAng, vDir);
	}

	ent_dynamic_block41 = EntRefToEntIndex(ent_dynamic_block41);

	if (ent_dynamic_block41 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block41, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block41, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block41, vPos, vAng, vDir);
	}

	ent_dynamic_block42 = EntRefToEntIndex(ent_dynamic_block42);

	if (ent_dynamic_block42 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block42, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block42, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block42, vPos, vAng, vDir);
	}

	ent_dynamic_block43 = EntRefToEntIndex(ent_dynamic_block43);

	if (ent_dynamic_block43 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block43, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block43, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block43, vPos, vAng, vDir);
	}

	ent_dynamic_block44 = EntRefToEntIndex(ent_dynamic_block44);

	if (ent_dynamic_block44 != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(ent_dynamic_block44, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(ent_dynamic_block44, Prop_Send, "m_angRotation", vAng);
		TeleportEntity(ent_dynamic_block44, vPos, vAng, vDir);
	}

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
	return Plugin_Continue;
}


public void panicevent(int doit)
{
	char command[] = "director_force_panic_event";
	char flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(doit, command);
	SetCommandFlags(command, flags);
}

public void OnTouch(int client, int other)
{

if(other > 0 && other <= MaxClients){
	if(IsClientInGame(other) && IsFakeClient(other) && GetClientTeam(other) == 2)
	{
		SetConVarInt(FindConVar("sb_unstick"), 0);
		ent_dynamic_block12 = EntRefToEntIndex(ent_dynamic_block12);

		if (ent_dynamic_block12 != INVALID_ENT_REFERENCE)
		{
			SDKUnhook(ent_dynamic_block12, SDKHook_Touch, OnTouch);
		}
		ent_dynamic_block13 = EntRefToEntIndex(ent_dynamic_block13);

		if (ent_dynamic_block13 != INVALID_ENT_REFERENCE)
		{
			SDKUnhook(ent_dynamic_block13, SDKHook_Touch, OnTouch);
		}
		ent_dynamic_block14 = EntRefToEntIndex(ent_dynamic_block14);

		if (ent_dynamic_block14 != INVALID_ENT_REFERENCE)
		{
			SDKUnhook(ent_dynamic_block14, SDKHook_Touch, OnTouch);
		}
		ent_dynamic_block12 = EntIndexToEntRef(ent_dynamic_block12);
		ent_dynamic_block13 = EntIndexToEntRef(ent_dynamic_block13);
		ent_dynamic_block14 = EntIndexToEntRef(ent_dynamic_block14);
	}

	}
}
	