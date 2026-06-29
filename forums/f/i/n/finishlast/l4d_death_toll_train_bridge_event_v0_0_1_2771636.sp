/****************************************************************************************************
* Plugin     : L4D - Death Toll Train Bridge Event
* Version    : 0.0.1
* Game       : Left 4 Dead
* Author     : Finishlast
*
* Testers    : Myself 
* Website    : https://forums.alliedmods.net/showthread.php?p=2771636
* Purpose    : This plugin creates a train bridge and an explosion event
* Code snippets: 
* I forgot where I found them back in the day, sorry, if you recognize any please tell me.
* Based on code from:
* Silvers, Marttt and many others
****************************************************************************************************/


#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_sound>
#pragma newdecls required
#define PARTICLE_BOMB2		"gas_explosion_main"

int ent_plate_trigger;
int ent_dynamic_block;
int ent_dynamic_block1;
int ent_dynamic_block2;
int ent_dynamic_block3;
int ent_dynamic_block4;
int ent_dynamic_block5;
int ent_dynamic_block6;
int ent_dynamic_block7;
int ent_dynamic_block8;
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
int ent_dynamic_block45;
int ent_dynamic_block46;
int ent_dynamic_block47;
int ent_dynamic_block48;
int ent_dynamic_block49;
int ent_dynamic_block50;
int ent_dynamic_block51;


public void OnPluginStart()
{
	PrecacheModel("models/props_street/traffic_plate_01.mdl");
	PrecacheModel("models/props_vehicles/train_enginecar.mdl");
	PrecacheModel("models/props_vehicles/train_flatcar.mdl");
	PrecacheModel("models/props_vehicles/humvee_glass.mdl");
	PrecacheModel("models/props_vehicles/humvee.mdl");
	PrecacheModel("models/props_vehicles/army_truck.mdl");
	PrecacheModel("models/props_vehicles/train_orecar.mdl");
	PrecacheModel("models/props_vehicles/m119howitzer_static_01.mdl");
	PrecacheModel("models/props_unique/ltrain_rail_straight.mdl");
	PrecacheModel("models/props_pipes/concrete_pipe001a.mdl");
	PrecacheModel("models/props_trainstation/light_signal001a.mdl");
	PrecacheModel("models/props_vehicles/deliveryvan_armored.mdl");

	PrecacheSound("animation/farm05_train_bridge_crash.wav");
	PrecacheSound("ambient/explosions/explode_1.wav");
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}


public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_vs_smalltown01_caves", false) || StrEqual(sMap, "l4d_smalltown01_caves", false) || StrEqual(sMap, "c10m1_caves", false))

	{


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


	pos[0] = -11453.0;
	pos[1] = -11742.0;
	pos[2] = 644.0;
	ang[0] = 0.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block = CreateEntityByName("info_particle_system");

	DispatchKeyValue(ent_dynamic_block, "effect_name", "railroad_light_blink3");
	DispatchKeyValue(ent_dynamic_block, "start_active", "1");
	DispatchSpawn(ent_dynamic_block);
	ActivateEntity(ent_dynamic_block);
	SetVariantString("!activator");
	TeleportEntity(ent_dynamic_block, pos, ang, NULL_VECTOR);


	pos[0] = -12193.0;
	pos[1] = -11466.0;
	pos[2] = 296.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block1 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block1, "model", "models/props_vehicles/train_enginecar.mdl");
	DispatchKeyValue(ent_dynamic_block1, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block1, "solid", "6");
	DispatchSpawn(ent_dynamic_block1);
	TeleportEntity(ent_dynamic_block1, pos, ang, NULL_VECTOR);

	pos[0] = -12840.0;
	pos[1] = -11466.0;
	pos[2] = 296.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block2 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block2, "model", "models/props_vehicles/train_flatcar.mdl");
	DispatchKeyValue(ent_dynamic_block2, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block2, "solid", "6");
	DispatchSpawn(ent_dynamic_block2);
	TeleportEntity(ent_dynamic_block2, pos, ang, NULL_VECTOR);

	pos[0] = -13437.0;
	pos[1] = -11466.0;
	pos[2] = 296.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block3 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block3, "model", "models/props_vehicles/train_flatcar.mdl");
	DispatchKeyValue(ent_dynamic_block3, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block3, "solid", "6");
	DispatchSpawn(ent_dynamic_block3);
	TeleportEntity(ent_dynamic_block3, pos, ang, NULL_VECTOR);

	pos[0] = -13560.0;
	pos[1] = -11466.0;
	pos[2] = 345.0;
	ang[0] = -5.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block4 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block4, "model", "models/props_vehicles/m119howitzer_static_01.mdl");
	DispatchKeyValue(ent_dynamic_block4, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block4, "solid", "6");
	DispatchSpawn(ent_dynamic_block4);
	TeleportEntity(ent_dynamic_block4, pos, ang, NULL_VECTOR);

	pos[0] = -13300.0;
	pos[1] = -11466.0;
	pos[2] = 345.0;
	ang[0] = -5.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block5 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block5, "model", "models/props_vehicles/m119howitzer_static_01.mdl");
	DispatchKeyValue(ent_dynamic_block5, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block5, "solid", "6");
	DispatchSpawn(ent_dynamic_block5);
	TeleportEntity(ent_dynamic_block5, pos, ang, NULL_VECTOR);

	pos[0] = -14500.0;
	pos[1] = -11466.0;
	pos[2] = 345.0;
	ang[0] = 0.0;
	ang[1] = 270.0;
	ang[2] = 0.0;


	ent_dynamic_block6 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block6, "model", "models/props_vehicles/humvee_glass.mdl");
	DispatchKeyValue(ent_dynamic_block6, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block6, "solid", "6");
	DispatchSpawn(ent_dynamic_block6);
	TeleportEntity(ent_dynamic_block6, pos, ang, NULL_VECTOR);

	pos[0] = -14735.0;
	pos[1] = -11466.0;
	pos[2] = 345.0;
	ang[0] = 0.0;
	ang[1] = 270.0;
	ang[2] = 0.0;


	ent_dynamic_block7 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block7, "model", "models/props_vehicles/humvee_glass.mdl");
	DispatchKeyValue(ent_dynamic_block7, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block7, "solid", "6");
	DispatchSpawn(ent_dynamic_block7);
	TeleportEntity(ent_dynamic_block7, pos, ang, NULL_VECTOR);

	pos[0] = -14500.0;
	pos[1] = -11466.0;
	pos[2] = 345.0;
	ang[0] = 0.0;
	ang[1] = 270.0;
	ang[2] = 0.0;


	ent_dynamic_block8 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block8, "model", "models/props_vehicles/humvee.mdl");
	DispatchKeyValue(ent_dynamic_block8, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block8, "solid", "6");
	DispatchSpawn(ent_dynamic_block8);
	TeleportEntity(ent_dynamic_block8, pos, ang, NULL_VECTOR);

	pos[0] = -14735.0;
	pos[1] = -11466.0;
	pos[2] = 345.0;
	ang[0] = 0.0;
	ang[1] = 270.0;
	ang[2] = 0.0;


	ent_dynamic_block9 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block9, "model", "models/props_vehicles/humvee.mdl");
	DispatchKeyValue(ent_dynamic_block9, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block9, "solid", "6");
	DispatchSpawn(ent_dynamic_block9);
	TeleportEntity(ent_dynamic_block9, pos, ang, NULL_VECTOR);



	pos[0] = -12840.0;
	pos[1] = -11466.0;
	pos[2] = 345.0;
	ang[0] = 0.0;
	ang[1] = 270.0;
	ang[2] = 0.0;


	ent_dynamic_block10 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block10, "model", "models/props_vehicles/army_truck.mdl");
	DispatchKeyValue(ent_dynamic_block10, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block10, "solid", "6");
	DispatchSpawn(ent_dynamic_block10);
	TeleportEntity(ent_dynamic_block10, pos, ang, NULL_VECTOR);

	pos[0] = -15220.0;
	pos[1] = -11466.0;
	pos[2] = 296.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block11 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block11, "model", "models/props_vehicles/train_orecar.mdl");
	DispatchKeyValue(ent_dynamic_block11, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block11, "solid", "6");
	DispatchSpawn(ent_dynamic_block11);
	TeleportEntity(ent_dynamic_block11, pos, ang, NULL_VECTOR);




	pos[0] = -14625.0;
	pos[1] = -11466.0;
	pos[2] = 296.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block12 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block12, "model", "models/props_vehicles/train_flatcar.mdl");
	DispatchKeyValue(ent_dynamic_block12, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block12, "solid", "6");
	DispatchSpawn(ent_dynamic_block12);
	TeleportEntity(ent_dynamic_block12, pos, ang, NULL_VECTOR);


	pos[0] = -14035.0;
	pos[1] = -11466.0;
	pos[2] = 296.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block13 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block13, "model", "models/props_vehicles/train_flatcar.mdl");
	DispatchKeyValue(ent_dynamic_block13, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block13, "solid", "6");
	DispatchSpawn(ent_dynamic_block13);
	TeleportEntity(ent_dynamic_block13, pos, ang, NULL_VECTOR);

	pos[0] = -14065.0;
	pos[1] = -11466.0;
	pos[2] = 345.0;
	ang[0] = 0.0;
	ang[1] = 270.0;
	ang[2] = 0.0;


	ent_dynamic_block51 = CreateEntityByName("prop_physics_override"); 
 	DispatchKeyValue(ent_dynamic_block51, "model", "models/props_vehicles/army_truck.mdl");
	DispatchKeyValue(ent_dynamic_block51, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block51, "solid", "6");
	DispatchSpawn(ent_dynamic_block51);
	TeleportEntity(ent_dynamic_block51, pos, ang, NULL_VECTOR);

	pos[0] = -10000.0;
	pos[1] = -12846.0;
	pos[2] = 396.0;
	ang[0] = 0.0;
	ang[1] = 90.0;
	ang[2] = 0.0;


	ent_dynamic_block14 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block14, "model", "models/props_unique/ltrain_rail_straight.mdl");
	DispatchKeyValue(ent_dynamic_block14, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block14, "solid", "6");
	DispatchSpawn(ent_dynamic_block14);
	TeleportEntity(ent_dynamic_block14, pos, ang, NULL_VECTOR);


	pos[0] = -10490.0;
	pos[1] = -11846.0;
	pos[2] = 290.0;
	ang[0] = -10.0;
	ang[1] = -50.0;
	ang[2] = 0.0;


	ent_dynamic_block15 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block15, "model", "models/props_unique/ltrain_rail_straight.mdl");
	DispatchKeyValue(ent_dynamic_block15, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block15, "solid", "6");
	DispatchSpawn(ent_dynamic_block15);
	TeleportEntity(ent_dynamic_block15, pos, ang, NULL_VECTOR);


	pos[0] = -9542.0;
	pos[1] = -11366.0;
	pos[2] = 200.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block16 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block16, "model", "models/props_unique/ltrain_rail_straight.mdl");
	DispatchKeyValue(ent_dynamic_block16, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block16, "solid", "6");
	DispatchSpawn(ent_dynamic_block16);
	TeleportEntity(ent_dynamic_block16, pos, ang, NULL_VECTOR);

	pos[0] = -10828.0;
	pos[1] = -11366.0;
	pos[2] = 200.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block17 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block17, "model", "models/props_unique/ltrain_rail_straight.mdl");
	DispatchKeyValue(ent_dynamic_block17, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block17, "solid", "6");
	DispatchSpawn(ent_dynamic_block17);
	TeleportEntity(ent_dynamic_block17, pos, ang, NULL_VECTOR);

	pos[0] = -12114.0;
	pos[1] = -11366.0;
	pos[2] = 200.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block18 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block18, "model", "models/props_unique/ltrain_rail_straight.mdl");
	DispatchKeyValue(ent_dynamic_block18, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block18, "solid", "6");
	DispatchSpawn(ent_dynamic_block18);
	TeleportEntity(ent_dynamic_block18, pos, ang, NULL_VECTOR);

	pos[0] = -13400.0;
	pos[1] = -11366.0;
	pos[2] = 200.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block19 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block19, "model", "models/props_unique/ltrain_rail_straight.mdl");
	DispatchKeyValue(ent_dynamic_block19, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block19, "solid", "6");
	DispatchSpawn(ent_dynamic_block19);
	TeleportEntity(ent_dynamic_block19, pos, ang, NULL_VECTOR);

	pos[0] = -14686.0;
	pos[1] = -11366.0;
	pos[2] = 200.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block20 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block20, "model", "models/props_unique/ltrain_rail_straight.mdl");
	DispatchKeyValue(ent_dynamic_block20, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block20, "solid", "6");
	DispatchSpawn(ent_dynamic_block20);
	TeleportEntity(ent_dynamic_block20, pos, ang, NULL_VECTOR);

	pos[0] = -15972.0;
	pos[1] = -11366.0;
	pos[2] = 200.0;
	ang[0] = 0.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block21 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block21, "model", "models/props_unique/ltrain_rail_straight.mdl");
	DispatchKeyValue(ent_dynamic_block21, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block21, "solid", "6");
	DispatchSpawn(ent_dynamic_block21);
	TeleportEntity(ent_dynamic_block21, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11466.0;
	pos[2] = 197.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block22 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block22, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block22, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block22, "solid", "6");
	DispatchSpawn(ent_dynamic_block22);
	TeleportEntity(ent_dynamic_block22, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11466.0;
	pos[2] = 90.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block23 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block23, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block23, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block23, "solid", "6");
	DispatchSpawn(ent_dynamic_block23);
	TeleportEntity(ent_dynamic_block23, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11466.0;
	pos[2] = -17.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block24 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block24, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block24, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block24, "solid", "6");
	DispatchSpawn(ent_dynamic_block24);
	TeleportEntity(ent_dynamic_block24, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11466.0;
	pos[2] = -124.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block25 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block25, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block25, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block25, "solid", "6");
	DispatchSpawn(ent_dynamic_block25);
	TeleportEntity(ent_dynamic_block25, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11466.0;
	pos[2] = -231.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block26 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block26, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block26, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block26, "solid", "6");
	DispatchSpawn(ent_dynamic_block26);
	TeleportEntity(ent_dynamic_block26, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11466.0;
	pos[2] = -338.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block27 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block27, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block27, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block27, "solid", "6");
	DispatchSpawn(ent_dynamic_block27);
	TeleportEntity(ent_dynamic_block27, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11466.0;
	pos[2] = -445.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block28 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block28, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block28, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block28, "solid", "6");
	DispatchSpawn(ent_dynamic_block28);
	TeleportEntity(ent_dynamic_block28, pos, ang, NULL_VECTOR);

//2

	pos[0] = -11470.0;
	pos[1] = -11265.0;
	pos[2] = 197.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block29 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block29, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block29, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block29, "solid", "6");
	DispatchSpawn(ent_dynamic_block29);
	TeleportEntity(ent_dynamic_block29, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11265.0;
	pos[2] = 90.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block30 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block30, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block30, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block30, "solid", "6");
	DispatchSpawn(ent_dynamic_block30);
	TeleportEntity(ent_dynamic_block30, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11265.0;
	pos[2] = -17.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block31 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block31, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block31, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block31, "solid", "6");
	DispatchSpawn(ent_dynamic_block31);
	TeleportEntity(ent_dynamic_block31, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11265.0;
	pos[2] = -124.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block32 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block32, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block32, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block32, "solid", "6");
	DispatchSpawn(ent_dynamic_block32);
	TeleportEntity(ent_dynamic_block32, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11265.0;
	pos[2] = -231.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block33 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block33, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block33, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block33, "solid", "6");
	DispatchSpawn(ent_dynamic_block33);
	TeleportEntity(ent_dynamic_block33, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11265.0;
	pos[2] = -338.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block34 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block34, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block34, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block34, "solid", "6");
	DispatchSpawn(ent_dynamic_block34);
	TeleportEntity(ent_dynamic_block34, pos, ang, NULL_VECTOR);

	pos[0] = -11470.0;
	pos[1] = -11265.0;
	pos[2] = -445.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block35 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block35, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block35, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block35, "solid", "6");
	DispatchSpawn(ent_dynamic_block35);
	TeleportEntity(ent_dynamic_block35, pos, ang, NULL_VECTOR);

//next
	pos[0] = -13128.0;
	pos[1] = -11466.0;
	pos[2] = 197.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block36 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block36, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block36, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block36, "solid", "6");
	DispatchSpawn(ent_dynamic_block36);
	TeleportEntity(ent_dynamic_block36, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11466.0;
	pos[2] = 90.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block37 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block37, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block37, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block37, "solid", "6");
	DispatchSpawn(ent_dynamic_block37);
	TeleportEntity(ent_dynamic_block37, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11466.0;
	pos[2] = -17.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block38 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block38, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block38, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block38, "solid", "6");
	DispatchSpawn(ent_dynamic_block38);
	TeleportEntity(ent_dynamic_block38, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11466.0;
	pos[2] = -124.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block39 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block39, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block39, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block39, "solid", "6");
	DispatchSpawn(ent_dynamic_block39);
	TeleportEntity(ent_dynamic_block39, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11466.0;
	pos[2] = -231.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block40 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block40, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block40, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block40, "solid", "6");
	DispatchSpawn(ent_dynamic_block40);
	TeleportEntity(ent_dynamic_block40, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11466.0;
	pos[2] = -338.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block41 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block41, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block41, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block41, "solid", "6");
	DispatchSpawn(ent_dynamic_block41);
	TeleportEntity(ent_dynamic_block41, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11466.0;
	pos[2] = -445.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block42 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block42, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block42, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block42, "solid", "6");
	DispatchSpawn(ent_dynamic_block42);
	TeleportEntity(ent_dynamic_block42, pos, ang, NULL_VECTOR);

//2

	pos[0] = -13128.0;
	pos[1] = -11265.0;
	pos[2] = 197.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block43 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block43, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block43, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block43, "solid", "6");
	DispatchSpawn(ent_dynamic_block43);
	TeleportEntity(ent_dynamic_block43, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11265.0;
	pos[2] = 90.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block44 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block44, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block44, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block44, "solid", "6");
	DispatchSpawn(ent_dynamic_block44);
	TeleportEntity(ent_dynamic_block44, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11265.0;
	pos[2] = -17.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block45 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block45, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block45, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block45, "solid", "6");
	DispatchSpawn(ent_dynamic_block45);
	TeleportEntity(ent_dynamic_block45, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11265.0;
	pos[2] = -124.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block46 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block46, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block46, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block46, "solid", "6");
	DispatchSpawn(ent_dynamic_block46);
	TeleportEntity(ent_dynamic_block46, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11265.0;
	pos[2] = -231.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block47 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block47, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block47, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block47, "solid", "6");
	DispatchSpawn(ent_dynamic_block47);
	TeleportEntity(ent_dynamic_block47, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11265.0;
	pos[2] = -338.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block48 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block48, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block48, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block48, "solid", "6");
	DispatchSpawn(ent_dynamic_block48);
	TeleportEntity(ent_dynamic_block48, pos, ang, NULL_VECTOR);

	pos[0] = -13128.0;
	pos[1] = -11265.0;
	pos[2] = -445.0;
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;


	ent_dynamic_block49 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block49, "model", "models/props_pipes/concrete_pipe001a.mdl");
	DispatchKeyValue(ent_dynamic_block49, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block49, "solid", "6");
	DispatchSpawn(ent_dynamic_block49);
	TeleportEntity(ent_dynamic_block49, pos, ang, NULL_VECTOR);

	pos[0] = -11423.0;
	pos[1] = -11745.0;
	pos[2] = 555.0;
	ang[0] = 0.0;
	ang[1] = 90.0;
	ang[2] = 0.0;

	ent_dynamic_block50 = CreateEntityByName("prop_dynamic"); 
 	DispatchKeyValue(ent_dynamic_block50, "model", "models/props_trainstation/light_signal001a.mdl");
	DispatchKeyValue(ent_dynamic_block50, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block50, "solid", "6");
	DispatchSpawn(ent_dynamic_block50);
	TeleportEntity(ent_dynamic_block50, pos, ang, NULL_VECTOR);


	}
}





public void OnTouch(int client, int other)
{
if(other>=0 && other <= MaxClients){

if(IsClientInGame(other) && GetClientTeam(other) == 2 && !IsFakeClient(other))
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
	CreateTimer(0.1, boom2);
	return Plugin_Continue;

}

public Action boom2(Handle timer)
{
	Command_Play("animation\\farm05_train_bridge_crash.wav");

	float pos[3],ang[3],dir[3];

	GetEntPropVector(ent_dynamic_block1, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent_dynamic_block1, Prop_Send, "m_angRotation", ang);
	AcceptEntityInput(ent_dynamic_block1, "Kill");

	//pos[0] = -12193.0;
	//pos[1] = -11466.0;
	//pos[2] = 296.0;
	//ang[0] = 0.0;
	ang[1] -= 20.0;
	//ang[2] = 0.0;
	dir[0] -= 100;
	dir[1] -= 240.0;
	//dir[2] = 0.0;

	ent_dynamic_block1 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block1, "model", "models/props_vehicles/train_enginecar.mdl");
	DispatchKeyValue(ent_dynamic_block1, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block1, "solid", "1");
	//SetVariantString("OnUser1 !self:Kill::60:-1");
	//AcceptEntityInput(ent_dynamic_block1, "AddOutput");
	//AcceptEntityInput(ent_dynamic_block1, "FireUser1");
	DispatchSpawn(ent_dynamic_block1);
	TeleportEntity(ent_dynamic_block1, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block1, pos, ang, dir);

	CreateTimer(0.3, boom3);
	

	return Plugin_Continue;

}
public Action boom3(Handle timer)
{
	float pos[3],ang[3],dir[3];

	
	GetEntPropVector(ent_dynamic_block2, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent_dynamic_block2, Prop_Send, "m_angRotation", ang);
	AcceptEntityInput(ent_dynamic_block2, "Kill");
	//pos[0] = -12840.0;
	//pos[1] = -11466.0;
	//pos[2] = 296.0;
	//ang[0] = 0.0;
	ang[1] -= 1.0;
	//ang[2] += 2.0;
	//dir[0] = pos[0];
	dir[1] -= 200.0;
	//dir[2] = 0.0;

	ent_dynamic_block2 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block2, "model", "models/props_vehicles/train_flatcar.mdl");
	DispatchKeyValue(ent_dynamic_block2, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block2, "solid", "1");
	//SetVariantString("OnUser1 !self:Kill::60:-1");
	//AcceptEntityInput(ent_dynamic_block2, "AddOutput");
	//AcceptEntityInput(ent_dynamic_block2, "FireUser1");
	DispatchSpawn(ent_dynamic_block2);
	TeleportEntity(ent_dynamic_block2, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block2, pos, ang, dir);
	CreateTimer(0.3, boom4);
	return Plugin_Continue;

}

public Action boom4(Handle timer)
{
	Command_Play("animation\\farm05_train_bridge_crash.wav");
	float pos[3],ang[3],dir[3];

	
	GetEntPropVector(ent_dynamic_block3, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent_dynamic_block3, Prop_Send, "m_angRotation", ang);
	AcceptEntityInput(ent_dynamic_block3, "Kill");
	//pos[0] = -12840.0;
	//pos[1] = -11466.0;
	//pos[2] = 296.0;
	//ang[0] = 0.0;
	ang[1] -= 1.0;
	//ang[2] += 2.0;
	//dir[0] = pos[0];
	dir[1] -= 230.0;
	//dir[2] = 10.0;

	ent_dynamic_block3 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block3, "model", "models/props_vehicles/train_flatcar.mdl");
	DispatchKeyValue(ent_dynamic_block3, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block3, "solid", "1");
	//SetVariantString("OnUser1 !self:Kill::60:-1");
	//AcceptEntityInput(ent_dynamic_block3, "AddOutput");
	//AcceptEntityInput(ent_dynamic_block3, "FireUser1");
	DispatchSpawn(ent_dynamic_block3);
	TeleportEntity(ent_dynamic_block3, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block3, pos, ang, dir);

	CreateTimer(0.3, boom5);
	return Plugin_Continue;

}
public Action boom5(Handle timer)
{
	float pos[3],ang[3],dir[3];

	
	GetEntPropVector(ent_dynamic_block13, Prop_Data, "m_vecAbsOrigin", pos);
	GetEntPropVector(ent_dynamic_block13, Prop_Send, "m_angRotation", ang);
	AcceptEntityInput(ent_dynamic_block13, "Kill");
	//pos[0] = -12840.0;
	//pos[1] = -11466.0;
	//pos[2] = 296.0;
	//ang[0] = 0.0;
	ang[1] -= 3.0;
	//ang[2] += 2.0;
	//dir[0] = pos[0];
	dir[1] -= 290.0;
	dir[2] = 0.0;

	ent_dynamic_block13 = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(ent_dynamic_block13, "model", "models/props_vehicles/train_flatcar.mdl");
	DispatchKeyValue(ent_dynamic_block13, "disableshadows", "1");
	DispatchKeyValue(ent_dynamic_block13, "solid", "1");
	//SetVariantString("OnUser1 !self:Kill::60:-1");
	//AcceptEntityInput(ent_dynamic_block13, "AddOutput");
	//AcceptEntityInput(ent_dynamic_block13, "FireUser1");
	DispatchSpawn(ent_dynamic_block13);
	TeleportEntity(ent_dynamic_block13, pos, ang, NULL_VECTOR);
	TeleportEntity(ent_dynamic_block13, pos, ang, dir);
	CreateTimer(3.0, changevDir);
	return Plugin_Continue;

}


public Action changevDir(Handle timer)
{
	Command_Play("animation\\farm05_train_bridge_crash.wav");
	float vPos[3], vAng[3], vDir[3];
	vDir[0] = 0.0;
	vDir[1] = 0.0;
	vDir[2] = 0.0;

	GetEntPropVector(ent_dynamic_block1, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_dynamic_block1, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_dynamic_block1, vPos, vAng, vDir);

	GetEntPropVector(ent_dynamic_block2, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_dynamic_block2, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_dynamic_block2, vPos, vAng, vDir);

	GetEntPropVector(ent_dynamic_block3, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_dynamic_block3, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_dynamic_block3, vPos, vAng, vDir);

	GetEntPropVector(ent_dynamic_block13, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(ent_dynamic_block13, Prop_Send, "m_angRotation", vAng);
	TeleportEntity(ent_dynamic_block13, vPos, vAng, vDir);

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





