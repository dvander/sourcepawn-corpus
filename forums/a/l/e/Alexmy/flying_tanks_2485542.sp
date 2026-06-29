#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new bool:FinaleStarted = false;
new bool:IsCurrentFlying[MAXPLAYERS+1] = false;

public Plugin:myinfo = 
{
	name = "[L4D] Flying Tanks",
	author = "Pan Xiaohai, cravenge, edited by AlexMy",
	description = "Make Tanks Fly To The Sky.",
	version = "1.2",
	url = ""
};

new Handle:hFlyingTanksChanceJump;
new Handle:hFlyingTanksChancePunch;
new Handle:hFlyingTanksChanceThrow;
new Handle:hFlyingTanksHeight;
 
public OnPluginStart()
{
	hFlyingTanksChanceJump = CreateConVar("flying_tanks_chance_jump", "10.0", "Chance Of Tanks To Fly After Jumping", 0, true, 0.0, true, 100.0);
	hFlyingTanksChancePunch = CreateConVar("flying_tanks_chance_punch", "75.0", "Chance Of Tanks To Fly After Punching", 0, true, 0.0, true, 100.0);
	hFlyingTanksChanceThrow = CreateConVar("flying_tanks_chance_throw", "10.0", "Chance Of Tanks To Fly After Throwing", 0, true, 0.0, true, 100.0);
	hFlyingTanksHeight = CreateConVar("flying_tanks_height", "500", "The maximum jump height.");
	
	AutoExecConfig(true, "flying_tanks"); 
 
	HookEvent("round_start", OnResetVariables);
	HookEvent("round_end", OnResetVariables, EventHookMode_Pre);
	HookEvent("finale_win", OnResetVariables, EventHookMode_Pre);
	HookEvent("mission_lost", OnResetVariables, EventHookMode_Pre);
	HookEvent("map_transition", OnResetVariables, EventHookMode_Pre);
	
	HookEvent("finale_start", OnFinaleStart);
	
	HookEvent("ability_use", OnAbilityUse);
	HookEvent("weapon_fire", OnWeaponFire);
	HookEvent("player_jump", OnPlayerJump);
	
	HookEvent("player_death", OnPlayerDeath);
}

public Action:OnResetVariables(Handle:event, const String:name[], bool:dontBroadcast)
{
	FinaleStarted = false;
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			IsCurrentFlying[i] = false;
		}
	}
}

public Action:OnFinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	FinaleStarted = true;
}

public Action:OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(FinaleStarted)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 5 || !IsPlayerAlive(client))
	{
		return;
	}
	
	if(!IsCurrentFlying[client] && IsPlayerOnGround(client))
	{
		new Float:punchchance = GetRandomFloat(0.0, 100.0);
		if(punchchance > GetConVarFloat(hFlyingTanksChancePunch))
		{
			return;
		}
		CreateTimer(3.0, ApplyFlyingTanks, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(10.5, RemoveFlyingAbility, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		SetEntityGravity(client, 1.0);
		IsCurrentFlying[client] = false;
	}
	return;
}

public Action:OnPlayerJump(Handle:event, const String:strName[], bool:DontBroadcast)
{
	if(FinaleStarted)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 5 || !IsPlayerAlive(client) || IsCurrentFlying[client] || !IsPlayerOnGround(client))
	{
		return;
	}
	
	new Float:jumpchance = GetRandomFloat(0.0, 100.0);
	if(jumpchance > GetConVarFloat(hFlyingTanksChanceJump))
	{
		return;
	}
	CreateTimer(0.5, ApplyFlyingTanks, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(7.0, RemoveFlyingAbility, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:OnPlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(FinaleStarted)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 5 || !IsCurrentFlying[client] || IsPlayerOnGround(client))
	{
		return;
	}
	
	SetEntityGravity(client, 1.0);
	IsCurrentFlying[client] = false;
}

public Action:OnAbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(FinaleStarted)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 5 && IsPlayerAlive(client) && (!IsCurrentFlying[client] || IsPlayerOnGround(client))) 
	{
		decl String:s[32];	
		GetEventString(event, "ability", s, 32);
		if(StrEqual(s, "ability_throw", true))
		{
			new Float:throwchance = GetRandomFloat(0.0, 100.0); 
			if(throwchance > GetConVarFloat(hFlyingTanksChanceThrow))
			{ 
				return;
			}
			CreateTimer(3.0, ApplyFlyingTanks, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(10.5, RemoveFlyingAbility, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:ApplyFlyingTanks(Handle:timer, any:client)
{
	if(!IsValidEntity(client))
	{
		return Plugin_Stop;
	}
	
	new Float:flyvec[3];
	new Float:height = GetConVarFloat(hFlyingTanksHeight);
	flyvec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	flyvec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	flyvec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]") + height;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, flyvec);
	//SetEntityGravity(client, 0.25);
	IsCurrentFlying[client] = true;
	
	return Plugin_Stop;
}

public Action:RemoveFlyingAbility(Handle:timer, any:client)
{
	if(!IsValidEntity(client))
	{
		return Plugin_Stop;
	}
	SetEntityGravity(client, 1.0);
	IsCurrentFlying[client] = false;
	
	return Plugin_Stop;
}

public OnMapStart()
{
	FinaleStarted = false;
	
	for (new tanks=1; tanks<=MaxClients; tanks++)
	{
		if(IsClientInGame(tanks))
		{
			IsCurrentFlying[tanks] = false;
		}
	}
}

public OnMapEnd()
{
	FinaleStarted = false;
	
	for (new tanks=1; tanks<=MaxClients; tanks++)
	{
		if(IsClientInGame(tanks))
		{
			IsCurrentFlying[tanks] = false;
		}
	}
}

public IsPlayerOnGround(client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND)
	{
		return true;
	}
	else
	{
		return false;
	}
}