/**
* TF2 Ladders SourceMod Plugin v1.0 (07/20/2012)
* 
* Change Log:
*  1.0 - 07/20/2012 
*   Initial Release
*
* Author:
*  Moosehead (Monospace Software LLC)
* 
* Credit To:
*  Wall Walking v1.1 by Pinkfairie
*  Ladders v1.0 by noodleboy347
* 
* Description:
*  Enables vertical ladders for Team Fortress 2, without the use of
*  func_ladder, which is not available.
*
* Demo:
*  http://youtu.be/CMcqyhNWyiw
* 
* Commands:
*  None
* 
* CVARs:
*  None
* 
* Dependencies:
*  SDK Hooks - http://forums.alliedmods.net/showthread.php?t=106748
*
* Install:
*  Install SDK Hooks
*  Place tf2ladders.smx in tf/addons/sourcemod/plugins
* 
* Usage:
*  To create a ladder you must create a trigger_multiple entity where the name
*  property contains the string "ladder".
* 
*  In Valve Hammer, create a 1 unit deep brush, preferably with the
*  "toolsinvisibleladder" texture.  Right click it, select "Tie to Entity". 
*  Select the class "trigger_multiple", click Apply.  Double click the "Name"
*  property, type "ladder", click Apply.  You should now be able to navigate
*  the ladder vertically with this plugin enabled.
*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#define SOUND_STEP	"player/footsteps/concrete4.wav"
new bool:soundCooldown[MAXPLAYERS+1];
new onLadder[MAXPLAYERS+1];
new Float:lastZ[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "TF2 Ladders",
	author = "Monospace Software LLC",
	description = "Enables vertical ladders for TF2",
	version = "1.0",
	url = "http://www.monospacesoftware.com"
}
public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEntityOutput("trigger_multiple", "OnStartTouch", StartTouchTrigger);
	HookEntityOutput("trigger_multiple", "OnEndTouch", EndTouchTrigger);
}
public OnMapStart()
{
	//LogMessage("Map Start");
	PrecacheSound(SOUND_STEP, true);
}
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	//LogMessage("Client %i: Spawn", client);

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	onLadder[client] = 0;
}
public StartTouchTrigger(const String:name[], caller, activator, Float:delay)
{
	decl String:entityName[32];
	GetEntPropString(caller, Prop_Data, "m_iName", entityName, sizeof(entityName));
	
	if(StrContains(entityName, "ladder") != -1) {
		// Occasionally I get 2 StartTouchTrigger events before an EndTouchTrigger when 
		// 2 ladders are placed close together.  The onLadder accumulator works around this. 
		if (++onLadder[activator] == 1) {
			//LogMessage("Client %i: StartTouch %i", activator, onLadder[activator]);
			MountLadder(activator);
		}
	}
}

public EndTouchTrigger(const String:name[], caller, activator, Float:delay)
{
	decl String:entityName[32];
	GetEntPropString(caller, Prop_Data, "m_iName", entityName, sizeof(entityName));

	if(StrContains(entityName, "ladder") != -1) {
		// Occasionally I get 2 StartTouchTrigger events before an EndTouchTrigger when 
		// 2 ladders are placed close together.  The onLadder accumulator works around this. 
		if (--onLadder[activator] <= 0) {
			//LogMessage("Client %i: EndTouch %i", activator, onLadder[activator]);
			DismountLadder(activator);
		}
	}
}

MountLadder(client)
{
	//LogMessage("Client %i: MountLadder", client);
	//SetEntityMoveType(client, MOVETYPE_NONE);
	//SetEntityMoveType(client, MOVETYPE_FLY);
	//SetEntPropFloat(client, Prop_Data, "m_flFriction", 0.001);
	SetEntityGravity(client, 0.001);

	SDKHook(client, SDKHook_PreThink, MoveOnLadder);
}

DismountLadder(client)
{
	//LogMessage("Client %i: DismountLadder", client);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropFloat(client, Prop_Data, "m_flFriction", 1.0);
	SetEntityGravity(client, 1.0);
	SDKUnhook(client, SDKHook_PreThink, MoveOnLadder);
}

PlayClimbSound(client)
{
	if(soundCooldown[client])
		return;
	EmitSoundToClient(client, SOUND_STEP);

	soundCooldown[client] = true;
	CreateTimer(0.35, Timer_Cooldown, client);
}
public Action:Timer_Cooldown(Handle:timer, any:client)
{
	soundCooldown[client] = false;
}
public MoveOnLadder(client)
{
	new Float:speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	decl buttons;
	buttons = GetClientButtons(client);
	decl Float:origin[3];
	GetClientAbsOrigin(client, origin);
	
	new bool:movingUp = (origin[2] > lastZ[client]);
	lastZ[client] = origin[2];

	decl Float:angles[3];
	GetClientEyeAngles(client, angles);
	decl Float:velocity[3];

	if(buttons & IN_FORWARD || buttons & IN_JUMP) {
		velocity[0] = speed * Cosine(DegToRad(angles[1]));
		velocity[1] = speed * Sine(DegToRad(angles[1]));
		velocity[2] = -1 * speed * Sine(DegToRad(angles[0]));
		
		// Soldier and heavy do not achieve the required velocity to get off the 
		// ground.  The calculation below provides a boost when necessary.
		if (!movingUp && angles[0] < -25.0 && velocity[2] > 0 && velocity[2] < 250.0) {
			//LogMessage("Client %i: BOOST", client);
			// is friction on different surfaces an issue?
			velocity[2] = 251.0;
		}
		
		//LogMessage("Client %i: Forward %f %f", client, angles[0], velocity[2]);
		PlayClimbSound(client);
	} else if(buttons & IN_MOVELEFT) {
		velocity[0] = speed * Cosine(DegToRad(angles[1] + 45));
		velocity[1] = speed * Sine(DegToRad(angles[1] + 45));
		velocity[2] = -1 * speed * Sine(DegToRad(angles[0]));
		
		//LogMessage("Client %i: Left", client);
		PlayClimbSound(client);
	} else if(buttons & IN_MOVERIGHT) {
		velocity[0] = speed * Cosine(DegToRad(angles[1] - 45));
		velocity[1] = speed * Sine(DegToRad(angles[1] - 45));
		velocity[2] = -1 * speed * Sine(DegToRad(angles[0]));
		
		//LogMessage("Client %i: Right", client);
		PlayClimbSound(client);
	} else if(buttons & IN_BACK) {
		velocity[0] = -1 * speed * Cosine(DegToRad(angles[1]));
		velocity[1] = -1 * speed * Sine(DegToRad(angles[1]));
		velocity[2] = speed * Sine(DegToRad(angles[0]));
		//LogMessage("Client %i: Backwards", client);
		PlayClimbSound(client);
	} else {
		velocity[0] = 0.0;
		velocity[1] = 0.0;
		velocity[2] = 0.0;
	
		//LogMessage("Client %i: Hold", client);
	}
	
	TeleportEntity(client, origin, NULL_VECTOR, velocity);
}