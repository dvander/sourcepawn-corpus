#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Alpha props",
	author = "Alienmario",
	description = "Makes held props transcluent",
	version = "1.0",
}

public OnPluginStart(){
	HookEntityOutput("prop_physics", "OnPlayerPickup", pickup);
	HookEntityOutput("prop_physics_multiplayer", "OnPlayerPickup", pickup);
	HookEntityOutput("prop_physics_respawnable", "OnPlayerPickup", pickup);
	HookEntityOutput("prop_physics_override", "OnPlayerPickup", pickup);
	
	HookEntityOutput("prop_physics", "OnPhysGunDrop", drop);
	HookEntityOutput("prop_physics_multiplayer", "OnPhysGunDrop", drop);
	HookEntityOutput("prop_physics_respawnable", "OnPhysGunDrop", drop);
	HookEntityOutput("prop_physics_override", "OnPhysGunDrop", drop);
}

public pickup(const String:output[], caller, activator, Float:delay){
	SetEntityRenderMode(caller, RENDER_TRANSALPHA);
	SetVariantInt (120);
	AcceptEntityInput(caller, "alpha");
}

public drop(const String:output[], caller, activator, Float:delay){
	SetVariantInt (255);
	AcceptEntityInput(caller, "alpha");
}