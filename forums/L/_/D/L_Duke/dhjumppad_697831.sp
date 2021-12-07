#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dukehacks>

#define PLUGIN_VERSION "0.0.1.5"

public Plugin:myinfo = 
{
	name = "Jump Pad",
	author = "L. Duke",
	description = "drop jump pads",
	version = PLUGIN_VERSION,
	url = "www.lduke.com"
}

#define MDL_JUMP "models/props_combine/combine_mine01.mdl"

#define SND_DROP "weapons/grenade_throw.wav"
#define SND_JUMP "weapons/airboat/airboat_gun_energy1.wav"

new Float:gnSpeed = 300.0;

new Float:gNextDrop[65];

new Handle:cvDelay = INVALID_HANDLE;
new Handle:cvLife = INVALID_HANDLE;
new Handle:cvVSpeed = INVALID_HANDLE;
new Handle:cvHSpeed = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_jp_version", PLUGIN_VERSION, "jumppad version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvDelay = CreateConVar("sm_jp_delay", "15.0", "how often players can drop a jump pad (in seconds)");
	cvLife = CreateConVar("sm_jp_life", "30.0", "time before unused jumppads are removed (in seconds)");
	cvVSpeed = CreateConVar("sm_jp_vspeed", "800.0", "vertical speed to apply to player on jump");
	cvHSpeed = CreateConVar("sm_jp_hmult", "1.5", "horizontal speed multiplier to apply to player on jump");
	RegConsoleCmd("sm_jumppad", Command_JumpPad);
}

public OnMapStart()
{
	// precache files
	PrecacheModel(MDL_JUMP, true);
	PrecacheSound(SND_DROP, true);
	PrecacheSound(SND_JUMP, true);
	
	// initialize next drop times
	new i;
	for (i=0;i<65;i++)
	{
		gNextDrop[i] = -1000.0;
	}
}

public Action:Command_JumpPad(client, args) 
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
	new Float:startpt[3];
	GetClientEyePosition(client, startpt);
	new Float:angle[3];
	new Float:speed[3];
	new Float:playerspeed[3];
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
	startpt[0] += 48.0 * Cosine(0.0174532925 * angle[1]);
	startpt[1] += 48.0 * Sine(0.0174532925 * angle[1]);
	speed[2]+=0.2;
	speed[0]*=gnSpeed; speed[1]*=gnSpeed; speed[2]*=gnSpeed;
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
	AddVectors(speed, playerspeed, speed);
	
	// create the jumppad
	new entity = CreateEntityByName("prop_physics_override");
	if (IsValidEntity(entity))
	{
		SetEntityModel(entity, MDL_JUMP);
		
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);
		SetEntProp(entity, Prop_Data, "m_usSolidFlags", 28);
		SetEntProp(entity, Prop_Data, "m_nSolidType", 6);
		
		DispatchSpawn(entity);
		
		TeleportEntity(entity, startpt, NULL_VECTOR, speed);
		dhHookEntity(entity, EHK_Touch, TouchHook);
		
		// send "kill" event to the event queue
		new String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", GetConVarFloat(cvLife));
		SetVariantString(addoutput);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		
		// play sound 
		EmitSoundToAll(SND_DROP, client);
	}
	
	// Return Plugin_Handled so no "invalid command" message
	// appears in the console.
	return Plugin_Handled;
	
}

// entity has been touched
public Action:TouchHook(entity, other)
{

	// check if other (touching) entity is a player
	if (other>0 && other<=GetMaxClients())
	{
		// Since we don't remove the entity in its own hook,
		// we must use a work around so TouchHook doesn't get
		// called again.  The server binary does not consider
		// entites touching if one entity "owns" the other.
		// This workaround allows us to delay the deletion
		// of the entity without TouchHook getting called
		// again.
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", other);
		
		// Adding velocity to the player at this time will 
		// not work. We need to wait until the current frame
		// is completed.
		CreateTimer(0.01, DoJump, other);
		
		// DO NOT RemoveEdict(entity) IN THE EDICT'S HOOK!
		// Remove the edict on the next frame to avoid a crash.
		CreateTimer(0.01, DestroyEntity, entity);
	}
	
	// Block the touch function (limits "stutter" from touching??).
	// (Return Plugin_Continue to allow Touch to run as usual.)
	return Plugin_Handled;
}

public Action:DestroyEntity(Handle:timer, any:entity)
{
	RemoveEdict(entity);
}

public Action:DoJump(Handle:timer, any:other)
{
	// get convar settings
	new Float:vspeed = GetConVarFloat(cvVSpeed);
	new Float:hspeed = GetConVarFloat(cvHSpeed);
	
	// Calculate and apply a new velocity to the player.
	new Float:speed[3];
	GetEntPropVector(other, Prop_Data, "m_vecVelocity", speed);
	speed[0] *= hspeed;
	speed[1] *= hspeed;
	speed[2] = vspeed;
	TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, speed);
	
	// play sound 
	EmitSoundToAll(SND_JUMP, other);
}