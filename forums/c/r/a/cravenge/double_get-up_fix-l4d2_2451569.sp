#include <sourcemod>
#include <sdkhooks>
#include <l4d2_direct>
#pragma semicolon 1

public Plugin:myinfo =
{
    name = "[L4D2] Double Get-Up Fix",
    author = "Darkid",
    description = "Fixes Get-Ups Being Doubled.",
    version = "3.6",
    url = "https://github.com/jbzdarkid/Double-Getup"
};

new Handle:rockPunchFix;

enum PlayerState
{
    UPRIGHT = 0,
    INCAPPED,
    SMOKED,
    JOCKEYED,
    HUNTER_GETUP,
    INSTACHARGED,
    CHARGED,
    CHARGER_GETUP,
    MULTI_CHARGED,
    TANK_ROCK_GETUP,
    TANK_PUNCH_FLY,
    TANK_PUNCH_GETUP,
    TANK_PUNCH_FIX,
    TANK_PUNCH_JOCKEY_FIX,
};

new pendingGetups[MAXPLAYERS+1] = 0;
new bool:interrupt[MAXPLAYERS+1] = false;
new currentSequence[MAXPLAYERS+1] = 0;
new PlayerState:playerState[MAXPLAYERS+1] = PlayerState:UPRIGHT;

public OnPluginStart()
{
    rockPunchFix = CreateConVar("double_get-up_fix-l4d2_rockpunch", "1", "Enable/Disable Rock Punch Fix", FCVAR_NOTIFY);
	
    HookEvent("round_start", OnRoundStart);
    HookEvent("tongue_grab", OnTongueGrab);
    HookEvent("jockey_ride", OnJockeyRide);
    HookEvent("jockey_ride_end", OnJockeyRideEnd);
    HookEvent("tongue_release", OnTongueRelease);
    HookEvent("pounce_stopped", OnPounceStopped);
    HookEvent("charger_impact", OnChargerImpact);
    HookEvent("charger_carry_end", OnChargerCarryEnd);
    HookEvent("charger_pummel_start", OnChargerPummelStart);
    HookEvent("charger_pummel_end", OnChargerPummelEnd);
    HookEvent("player_incapacitated", OnPlayerIncapacitated);
    HookEvent("revive_success", OnReviveSuccess);
	HookEvent("player_hurt", OnPlayerHurt);
}

public bool:isGettingUp(any:survivor)
{
	switch (playerState[survivor])
	{
		case (PlayerState:HUNTER_GETUP): return true;
		case (PlayerState:CHARGER_GETUP): return true;
		case (PlayerState:MULTI_CHARGED): return true;
		case (PlayerState:TANK_PUNCH_GETUP): return true;
		case (PlayerState:TANK_ROCK_GETUP): return true;
	}
	
	return false;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			playerState[i] = PlayerState:UPRIGHT;
		}
	}
}

public Action:OnTongueGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:HUNTER_GETUP)
	{
		interrupt[client] = true;
	}
}

public Action:OnJockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	playerState[client] = PlayerState:JOCKEYED;
}

public Action:OnJockeyRideEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:JOCKEYED)
	{
		playerState[client] = PlayerState:UPRIGHT;
	}
}

public Action:OnTongueRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:INCAPPED)
	{
		return;
	}
	
	playerState[client] = PlayerState:UPRIGHT;
	_CancelGetup(client);
}

public Action:OnPounceStopped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:INCAPPED)
	{
		return;
	}
	
	if (isGettingUp(client))
	{
		pendingGetups[client]++;
		return;
	}
	
	playerState[client] = PlayerState:HUNTER_GETUP;
	_GetupTimer(client);
}

public Action:OnChargerImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:INCAPPED)
	{
		return;
	}
	
	playerState[client] = PlayerState:MULTI_CHARGED;
}

public Action:OnChargerCarryEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:INCAPPED)
	{
		pendingGetups[client]++;
	}
	
	playerState[client] = PlayerState:INSTACHARGED;
}

public Action:OnChargerPummelStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:INCAPPED)
	{
		return;
	}
	
	playerState[client] = PlayerState:CHARGED;
}

public Action:OnChargerPummelEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:INCAPPED)
	{
		return;
	}
	
	playerState[client] = PlayerState:CHARGER_GETUP;
	_GetupTimer(client);
}

public Action:OnPlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	if (playerState[client] == PlayerState:INSTACHARGED)
	{
		pendingGetups[client]++;
	}
	
	playerState[client] = PlayerState:INCAPPED;
}

public Action:OnReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	
	playerState[client] = PlayerState:UPRIGHT;
	_CancelGetup(client);
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || !IsPlayerAlive(victim))
	{
		return Plugin_Continue;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsTank(attacker))
	{
		decl String:pWeapon[32];
		GetEventString(event, "weapon", pWeapon, 32);
		if (StrEqual(pWeapon, "tank_claw", true))
		{
			if (playerState[victim] == PlayerState:CHARGER_GETUP)
			{
				interrupt[victim] = true;
			}
			else if (playerState[victim] == PlayerState:MULTI_CHARGED)
			{
				pendingGetups[victim]++;
			}
			
			if (playerState[victim] == PlayerState:TANK_ROCK_GETUP && GetConVarBool(rockPunchFix))
			{
				playerState[victim] = PlayerState:TANK_PUNCH_FIX;
			}
			else if (playerState[victim] == PlayerState:JOCKEYED)
			{
				playerState[victim] = PlayerState:TANK_PUNCH_JOCKEY_FIX;
				_TankLandTimer(victim);
			}
			else
			{
				playerState[victim] = PlayerState:TANK_PUNCH_FLY;
				_TankLandTimer(victim);
			}
		}
		else if (StrEqual(pWeapon, "tank_rock", true))
		{
			if (playerState[victim] == PlayerState:CHARGER_GETUP)
			{
				interrupt[victim] = true;
			}
			else if (playerState[victim] == PlayerState:MULTI_CHARGED)
			{
				pendingGetups[victim]++;
			}
			
			playerState[victim] = PlayerState:TANK_ROCK_GETUP;
			_GetupTimer(victim);
		}
	}
	
	return Plugin_Continue;
}

_TankLandTimer(client)
{
	CreateTimer(0.04, TankLandTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TankLandTimer(Handle:timer, any:client)
{
	new tankFlyAnim = RetrieveAnimData(client);
	if (tankFlyAnim == 0)
	{
		return Plugin_Stop;
	}
	
	if (GetEntProp(client, Prop_Send, "m_nSequence") == tankFlyAnim || GetEntProp(client, Prop_Send, "m_nSequence") == tankFlyAnim + 1)
	{
		return Plugin_Continue;
	}
	
	if (playerState[client] == PlayerState:TANK_PUNCH_JOCKEY_FIX)
	{
		if (GetEntProp(client, Prop_Send, "m_nSequence") == tankFlyAnim + 2)
		{
			return Plugin_Continue;
		}
		
		L4D2Direct_DoAnimationEvent(client, 96);
	}
	
	if (playerState[client] == PlayerState:TANK_PUNCH_FLY)
	{
		playerState[client] = PlayerState:TANK_PUNCH_GETUP;
	}
	
	_GetupTimer(client);
	return Plugin_Stop;
}

_GetupTimer(client)
{
	CreateTimer(0.04, GetupTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:GetupTimer(Handle:timer, any:client)
{
	if (currentSequence[client] == 0)
	{
		currentSequence[client] = GetEntProp(client, Prop_Send, "m_nSequence");
		pendingGetups[client]++;
		return Plugin_Continue;
	}
	else if (interrupt[client])
	{
		interrupt[client] = false;
		return Plugin_Stop;
	}
	
	if (currentSequence[client] == GetEntProp(client, Prop_Send, "m_nSequence"))
	{
		return Plugin_Continue;
	}
	else if (playerState[client] == PlayerState:TANK_PUNCH_FIX)
	{
		L4D2Direct_DoAnimationEvent(client, 96);
		playerState[client] = PlayerState:TANK_PUNCH_GETUP;
		currentSequence[client] = 0;
		_TankLandTimer(client);
		return Plugin_Stop;
	}
	else
	{
		playerState[client] = PlayerState:UPRIGHT;
		pendingGetups[client]--;
		
		_CancelGetup(client);
		return Plugin_Stop;
	}
}

_CancelGetup(client)
{
	CreateTimer(0.04, CancelGetup, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CancelGetup(Handle:timer, any:client)
{
	if (pendingGetups[client] <= 0)
	{
		pendingGetups[client] = 0;
		currentSequence[client] = 0;
		return Plugin_Stop;
	}
	
	pendingGetups[client]--;
	SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0);
	
	return Plugin_Continue;
}

stock RetrieveAnimData(client)
{
	new animPlayed = 0;
	
	decl String:currentModel[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", currentModel, 64);
	if (strcmp(currentModel, "models/survivors/survivor_coach.mdl") == 0 || strcmp(currentModel, "models/survivors/survivor_gambler.mdl") == 0)
	{
		animPlayed = 628;
	}
	else if (strcmp(currentModel, "models/survivors/survivor_producer.mdl") == 0)
	{
		animPlayed = 636;
	}
	else if (strcmp(currentModel, "models/survivors/survivor_mechanic.mdl") == 0)
	{
		animPlayed = 633;
	}
	else if (strcmp(currentModel, "models/survivors/survivor_manager.mdl") == 0 || strcmp(currentModel, "models/survivors/survivor_namvet.mdl") == 0)
	{
		animPlayed = 536;
	}
	else if (strcmp(currentModel, "models/survivors/survivor_teenangst.mdl") == 0)
	{
		animPlayed = 545;
	}
	else if(strcmp(currentModel, "models/survivors/survivor_biker.mdl") == 0)
	{
		animPlayed = 539;
	}
	
	return animPlayed;
}

bool:IsTank(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client));
}

