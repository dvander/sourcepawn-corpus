#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dukehacks>

#define PLUGIN_VERSION "0.0.1.9"

public Plugin:myinfo = 
{
	name = "Balloon",
	author = "L. Duke",
	description = "drop jump pads",
	version = PLUGIN_VERSION,
	url = "www.lduke.com"
}

#define MDL_BALLOON "models/player/gibs/gibs_balloon.mdl"

#define SND_DROP "weapons/grenade_throw.wav"

new Float:gNextDrop[65];

new Handle:cvDelay = INVALID_HANDLE;
new Handle:cvLife = INVALID_HANDLE;
new Handle:cvModel = INVALID_HANDLE;
new Handle:cvVSpeed = INVALID_HANDLE;
new Handle:cvHSpeed = INVALID_HANDLE;
new Handle:cvHMult = INVALID_HANDLE;
new Handle:cvDamage = INVALID_HANDLE;
new Handle:cvRadius = INVALID_HANDLE;

new String:model[256];

public OnPluginStart()
{
	CreateConVar("sm_balloon_version", PLUGIN_VERSION, "jumppad version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvModel =CreateConVar("sm_balloon_mdl", MDL_BALLOON, "balloon model name");
	cvDelay = CreateConVar("sm_balloon_delay", "30.0", "how often players can release a balloon (in seconds)");
	cvLife = CreateConVar("sm_balloon_life", "5.0", "how long before balloon explodes (in seconds)");
	cvVSpeed = CreateConVar("sm_balloon_vspeed", "80.0", "vertical speed of balloon");
	cvHSpeed = CreateConVar("sm_balloon_hspeed", "300.0", "initial horizontal speed of balloon");
	cvHMult = CreateConVar("sm_balloon_hspeedmult", "0.98", "drag multiplier (1.0 to not slow down horizontal speed");
	cvDamage = CreateConVar("sm_balloon_damage", "100.0", "damage dealt on explosion");
	cvRadius = CreateConVar("sm_balloon_radius", "256", "radius of explosion");
	
	RegConsoleCmd("sm_balloon", Command_Balloon);
}

public OnMapStart()
{
	// precache files
	PrecacheSound(SND_DROP, true);
	
	// initialize next drop times
	new i;
	for (i=0;i<65;i++)
	{
		gNextDrop[i] = -1000.0;
	}
}

public OnConfigsExecuted()
{
	GetConVarString(cvModel, model, sizeof(model));
	PrecacheModel(model, true);
}


public Action:Command_Balloon(client, args) 
{
	// check when last jumppad dropped
	new Float:time = GetEngineTime();
	if (time<gNextDrop[client])
	{
		PrintCenterText(client, "You must wait %d seconds.", RoundToCeil(gNextDrop[client]-time));
		return Plugin_Handled;
	}
	
	// set next time allowed
	gNextDrop[client] = time + GetConVarFloat(cvDelay);
	
	// set position, angles, and speed for jumppad prop
	new Float:vspeed = GetConVarFloat(cvVSpeed);
	new Float:hspeed = GetConVarFloat(cvHSpeed);
	new Float:startpt[3];
	GetClientEyePosition(client, startpt);
	new Float:angle[3];
	new Float:speed[3];
	new Float:playerspeed[3];
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
	startpt[0] += 48.0 * Cosine(0.0174532925 * angle[1]);
	startpt[1] += 48.0 * Sine(0.0174532925 * angle[1]);
	speed[0]*=vspeed; speed[1]*=hspeed; speed[2]=hspeed;
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
	AddVectors(speed, playerspeed, speed);
	
	// create the balloon
	new entity = CreateEntityByName("prop_physics_override");
	if (IsValidEntity(entity))
	{
		new String:tmp[256];
		
		SetEntityModel(entity, model);
		
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);
		SetEntProp(entity, Prop_Data, "m_usSolidFlags", 28);
		SetEntProp(entity, Prop_Data, "m_nSolidType", 6);
		
		DispatchSpawn(entity);
		
		TeleportEntity(entity, startpt, NULL_VECTOR, speed);
		dhHookEntity(entity, EHK_VPhysicsUpdate, ThinkHook);
		
		// setup explosion
		SetEntPropEnt(entity, Prop_Data, "m_hLastAttacker", client);
		
		// send "kill" event to the event queue
		new String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:break::%f:1", GetConVarFloat(cvLife));
		SetVariantString(addoutput);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		
		GetConVarString(cvRadius, tmp, sizeof(tmp));
		DispatchKeyValue(entity, "ExplodeRadius", tmp);
		GetConVarString(cvDamage, tmp, sizeof(tmp));
		DispatchKeyValue(entity, "ExplodeDamage", tmp);
		Format(tmp, sizeof(tmp), "!self,Break,,0,-1");
		DispatchKeyValue(entity, "OnHealthChanged", tmp);
		Format(tmp, sizeof(tmp), "!self,Kill,,0,-1");
		DispatchKeyValue(entity, "OnBreak", tmp);
		
		// play sound 
		EmitSoundToAll(SND_DROP, client);
	}
	
	// Return Plugin_Handled so no "invalid command" message
	// appears in the console.
	return Plugin_Handled;
	
}

// entity is thinking
public Action:ThinkHook(entity)
{

	// Calculate and apply a new velocity to the player.
	new Float:speed[3];
	new Float:drag = GetConVarFloat(cvHMult);
	GetEntPropVector(entity, Prop_Data, "m_vecVelocity", speed);
	speed[0]*=drag;
	speed[1]*=drag;
	speed[2] = GetConVarFloat(cvVSpeed);
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, speed);
	
	return Plugin_Continue;
}

