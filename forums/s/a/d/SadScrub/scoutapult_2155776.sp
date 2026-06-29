#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

// Default values

#define TAUNT_DURATION 4.0
#define MOVECOLLIDE_FLY_BOUNCE 1
#define MOVECOLLIDE_DEFAULT 0
#define CHEERSOUND "player/pl_impact_stun_range.wav"

// Variables

new bool:g_Taunting[MAXPLAYERS+1] = false;
new bool:g_Confirming[MAXPLAYERS+1] = false;
new bool:isEnabled;
new Float:VelocityVectors[MAXPLAYERS+1][3]; // Velocity vectors, stored in initiator's slot
new Float:VelocityMult[3];
new off_MtCollide; // Movetype_Collide offset

// ConVar handles

new Handle:g_Enabled, Handle:g_FWD, Handle:g_RIGHT, Handle:g_UP, Handle:g_WAIT;

public Plugin:myinfo = 
{
	name = "Scout-a-Pult",
	author = "SadScrub & [SM] Striker",
	description = "Launch teammates into the air as Scout",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=242659/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_scoutapult", Cmd_Catapult, "Launch team-mates far away"); // Main command
	
	// Calculating collision offset
	
	off_MtCollide = FindSendPropOffs("CBaseEntity", "movecollide");
	if (off_MtCollide == -1)
		LogToGame("[Scout-a-Pult] ERROR: Couldn't find the offset for MoveCollide");
		
	// Precaching the Cheer sound
	
	PrecacheSound(CHEERSOUND, true);
	
	// Creating ConVars
	
	g_Enabled = CreateConVar("sm_scoutapult_enabled", "1", "Enables/disables plugin");
	g_FWD = CreateConVar("sm_scoutapult_fwd", "1500.0", "Forward velocity multiplier");
	g_RIGHT = CreateConVar("sm_scoutapult_right", "1000.0", "Right velocity multiplier");
	g_UP = CreateConVar("sm_scoutapult_up", "2500.0", "Up velocity multiplier");
	g_WAIT = CreateConVar("sm_scoutapult_wait", "12.0", "Wait time for initiation");
	
	isEnabled = GetConVarBool(g_Enabled);
	VelocityMult[0] = GetConVarFloat(g_FWD);
	VelocityMult[1] = GetConVarFloat(g_RIGHT);
	VelocityMult[2] = GetConVarFloat(g_UP);
	
	// Hooking ConVar changes
	
	HookConVarChange(g_Enabled, OnCvarChange);
	HookConVarChange(g_FWD, OnCvarChange);
	HookConVarChange(g_RIGHT, OnCvarChange);
	HookConVarChange(g_UP, OnCvarChange);
	HookConVarChange(g_WAIT, OnCvarChange);
	
	// Hooking events
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

// All ConVar changes are controlled with this one function

public OnCvarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == g_Enabled)
		isEnabled = GetConVarBool(g_Enabled);
		
	if (cvar == g_FWD)
		VelocityMult[0] = GetConVarFloat(g_FWD);
		
	if (cvar == g_RIGHT)
		VelocityMult[1] = GetConVarFloat(g_RIGHT);
		
	if (cvar == g_UP)
		VelocityMult[2] = GetConVarFloat(g_UP);
}

// Main function, mainly checks stuff and calls Taunt_Initiate and Taunt_Confirm

public Action:Cmd_Catapult(client, args)
{
	if (!isEnabled)
		return Plugin_Handled;
	
	if ( (client > 0) && IsClientInGame(client) && IsPlayerAlive(client) ) // Checking if player is alive and in-game
	{
		if (GetClientTeam(client) < 2) // If teamless or Spectator
		{
			PrintToChat(client, "[Scout-a-Pult] May only use on RED/BLU");
			return Plugin_Handled;
		}
		
		if (TF2_GetPlayerClass(client) == TFClass_Scout) // Scouts initiate the taunt
		{
			Taunt_Initiate(client);
		}
		else // Others Do Nothing
		{
			PrintToChat(client, "[Scout-a-Pult] You are not a scout!");
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(condition == TFCond_Taunting)
	{
		if(GetClientTeam(client) > 1)
		{
			decl Float:ClientPos[3];
			decl Float:TargetPos[3];
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(g_Taunting[i] && i != client)
				{
					GetClientAbsOrigin(client, ClientPos);
					GetClientAbsOrigin(i, TargetPos);
					
					new Float:Distance = GetVectorDistance(ClientPos, TargetPos, false);
					
					if(Distance <= 80.0)
					{
						if (FloatAbs( ClientPos[2] - TargetPos[2] ) > 20)
						{
							PrintToChat(client, "[Scout-a-Pult] Target is too high/low.");
							PrintToChat(i, "[Scout-a-Pult] Attempt failed. Too high/low.");
							return;
						}
						else if(IsInCone(i, client, 45.0))
						{
							Taunt_Confirm(client, i);
							return;
						}
						else
						{
							PrintToChat(client, "[Scout-a-Pult] You're not in front!");
							return;
						}
					}
				}
			}
		}
	}
}

bool:IsInCone(client, target, Float:fov = 45.0)
{
	new Float:Output;
	decl Float:ang[3];
	decl Float:vec[3];
	decl Float:targetPos[3];
	
	GetEntPropVector( client, Prop_Data, "m_angRotation", ang );
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", vec );
	GetEntPropVector( target, Prop_Send, "m_vecOrigin", targetPos );
    
	decl Float:fwd[3];
	GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
	vec[0] = targetPos[0] - vec[0];
	vec[1] = targetPos[1] - vec[1];
	vec[2] = 0.0;
	fwd[2] = 0.0;
	NormalizeVector(fwd, fwd);
	ScaleVector(vec, 1/SquareRoot(vec[0]*vec[0]+vec[1]*vec[1]+vec[2]*vec[2]));
	
	Output = ArcCosine(vec[0]*fwd[0]+vec[1]*fwd[1]+vec[2]*fwd[2]);
    
	new Float:Angle = RadToDeg(Output);
	
	if(Angle <= fov)
	{
		return true;
	}
	else
	{
		return false;
	}
}

// Initiating function

public Taunt_Initiate(client)
{
	if ( !(GetEntityFlags(client) & (FL_ONGROUND | FL_INWATER) ) )
	{
		PrintToChat(client, "[Scout-a-Pult] You're not on the ground");
		return;
	}
	else
	{			
		if( TF2_IsPlayerInCondition(client, TFCond_Dazed) && g_Taunting[client] ) // If this is called while Scout is in pre-handshake mode, disrupt
		{
			TF2_RemoveCondition(client, TFCond_Dazed);
			PrintToChat(client, "[Scout-a-Pult] Taunt initiation disrupted");
		}
		else // Initiate
		{
			// Checking if Scout has a Sandman/Atomizer
			
			new weapon = GetPlayerWeaponSlot(client, 2);
			weapon = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			
			if ( (weapon != 44) && (weapon != 450) )
			{
				PrintToChat(client, "[Scout-a-Pult] You must have a Sandman or Atomizer equipped");
				return;
			}
			
			// Setting up the angle vector
			
			new Float:eyeAngles[3];
			GetClientEyeAngles(client, eyeAngles);
		
			if (eyeAngles[0] > -9)
			{
				PrintToChat(client, "[Scout-a-Pult] Pitch not high enough.");
				return;
			}
			
			// Preparing angle vector
			
			eyeAngles[0] *= -1.0;
			eyeAngles[0] = DegToRad(eyeAngles[0]);
			eyeAngles[1] = DegToRad(eyeAngles[1]);
			
			// Filling up the velocity vector with data
	
			VelocityVectors[client][0] = VelocityMult[0] * Cosine(eyeAngles[0]) * Cosine(eyeAngles[1]);
			VelocityVectors[client][1] = VelocityMult[1] * Cosine(eyeAngles[0]) * Sine(eyeAngles[1]);
			VelocityVectors[client][2] = VelocityMult[2] * Sine(eyeAngles[0]);
		
			PrintToChat(client, "[Scout-a-Pult] Initiating taunt");
			g_Taunting[client] = true;
			
			TF2_StunPlayer(client, GetConVarFloat(g_WAIT), 0.0, 34, 0); // 34 - BONKSTUCK (1 << 1) and NOSOUNDOREFFECT (1 << 5) together
			TF2_AddCondition(client, TFCond_InHealRadius, GetConVarFloat(g_WAIT), 0); // Amputator healing circle, visual alert
			
			FakeClientCommand(client, "voicemenu 0 3"); // Move it up!
		}
	}
}

// Confirming function

public Taunt_Confirm(client, target)
{
	if( GetClientTeam(client) != GetClientTeam(target) )
	{
		PrintToChat(client, "[Scout-a-Pult] Target must be on your team");
		return;
	}
	
	if ( !(GetEntityFlags(client) & FL_ONGROUND) )
	{
		PrintToChat(client, "[Scout-a-Pult] You're not on the ground");
		return;
	}
	
	// Setting the confirmer's taunt toggle to true
	
	PrintToChat(client, "[Scout-a-Pult] Taunt confirmed. Off you go!");
	PrintToChat(target, "[Scout-a-Pult] Taunt confirmed.");
	g_Confirming[client] = true;
	
	// Immobilizing player-future projectile
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	// Setting up the Scout for taunting
	
	TF2_RemoveCondition(target, TFCond_InHealRadius);
	TF2_RemoveCondition(target, TFCond_Dazed);
	
	// Getting eyeAngles
	
	new Float:eyeAngles[3];
	GetClientEyeAngles(client, eyeAngles);
	eyeAngles[1] += 180;
	
	// Equip melee for Scout, force taunt
	
	new melee = GetPlayerWeaponSlot(target, 2);
	SetEntPropEnt(target, Prop_Send, "m_hActiveWeapon", melee);
	TeleportEntity(target, NULL_VECTOR, eyeAngles, NULL_VECTOR);
	SetEntityMoveType(target, MOVETYPE_NONE);
	FakeClientCommand(target, "taunt");
	
	// Timer for the taunt duration
	
	new Handle:pack;
	CreateDataTimer(TAUNT_DURATION, LaunchPlayer, pack, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(pack, client);
	WritePackCell(pack, target);
}

// Data timer function, actual launching takes place here

public Action:LaunchPlayer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new target = ReadPackCell(pack);
	
	SetEntityMoveType(target, MOVETYPE_WALK); // Scout can walk again
	
	new Float:pos[3], Float:ang[3];
	GetClientEyePosition(target, pos);
	GetClientEyeAngles(target, ang);
	
	if ( (g_Confirming[client]) && (g_Taunting[target]) && (GetEntityMoveType(client) == MOVETYPE_NONE) )
	{
		SetEntityMoveType(client, MOVETYPE_FLYGRAVITY);
		SetEntData(client, off_MtCollide, MOVECOLLIDE_FLY_BOUNCE);
		EmitSoundToAll(CHEERSOUND, target, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos, ang, true, 0.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, VelocityVectors[target]);
	
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntData(client, off_MtCollide, MOVECOLLIDE_DEFAULT);
	}
	
	g_Confirming[client] = false;
	g_Taunting[target] = false;
}

// Function for checking conditions on death/disconnect

public CheckPlayerStates(client)
{
	g_Taunting[client] = false;
	g_Confirming[client] = false;
}

// Checking conditions on death, setting proper movetypes to other parties involved

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CheckPlayerStates(client);
}

// Same thing as Event_PlayerDeath, essentially

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CheckPlayerStates(client);
}

// Watching for cases where Stun was removed if a person was mid-taunt

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if((g_Taunting[client]) && (condition == TFCond_Dazed))
	{
		if(TF2_IsPlayerInCondition(client, TFCond_InHealRadius))
		{
			TF2_RemoveCondition(client, TFCond_InHealRadius);
			
			PrintToChat(client, "[Scout-a-Pult] Taunt Wait mode cancelled.");
			g_Taunting[client] = false;
		}
	}
}