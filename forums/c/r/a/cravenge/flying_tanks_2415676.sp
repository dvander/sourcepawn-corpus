#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new bool:FinaleStarted = false;
new bool:IsCurrentFlying[MAXPLAYERS+1] = false;

public Plugin:myinfo = 
{
	name = "Flying Tanks",
	author = "Pan Xiaohai, cravenge",
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
	hFlyingTanksChanceJump = CreateConVar("flying_tanks_chance_jump", "75", "Chance Of Tanks To Fly After Jumping");
	hFlyingTanksChancePunch = CreateConVar("flying_tanks_chance_punch", "10", "Chance Of Tanks To Fly After Punching");
	hFlyingTanksChanceThrow = CreateConVar("flying_tanks_chance_throw", "15", "Chance Of Tanks To Fly After Throwing");
	hFlyingTanksHeight = CreateConVar("flying_tanks_height", "800", "Maximum Height For Flying Tanks");
	
	AutoExecConfig(true, "flying_tanks"); 
 
	HookEvent("round_start", OnResetVariables);
	HookEvent("round_end", OnResetVariables);
	HookEvent("finale_win", OnResetVariables);
	HookEvent("mission_lost", OnResetVariables);
	HookEvent("map_transition", OnResetVariables);
	
	HookEvent("finale_start", OnFinaleStart);
	
	HookEvent("ability_use", OnAbilityUse);
	HookEvent("weapon_fire", OnWeaponFire);
	HookEvent("player_jump", OnPlayerJump);
	
	HookEvent("player_death", OnPlayerDeath);
}

public Action:OnResetVariables(Handle:event, const String:name[], bool:dontBroadcast)
{
	FinaleStarted = false;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		IsCurrentFlying[client] = false;
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
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 8 || !IsPlayerAlive(client))
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
		
		CreateTimer(3.0, ApplyFlyingTanks, client);
		CreateTimer(10.5, RemoveFlyingAbility, client);
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
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 8 || !IsPlayerAlive(client) || IsCurrentFlying[client] || !IsPlayerOnGround(client))
	{
		return;
	}
	
	new Float:jumpchance = GetRandomFloat(0.0, 100.0);
	if(jumpchance > GetConVarFloat(hFlyingTanksChanceJump))
	{
		return;
	}
	
	CreateTimer(0.5, ApplyFlyingTanks, client);
	CreateTimer(7.0, RemoveFlyingAbility, client);
}

public Action:OnPlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(FinaleStarted)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 8 || !IsCurrentFlying[client] || IsPlayerOnGround(client))
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
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client) && (!IsCurrentFlying[client] || IsPlayerOnGround(client))) 
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
			
			CreateTimer(3.0, ApplyFlyingTanks, client);
			CreateTimer(10.5, RemoveFlyingAbility, client);
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
	SetEntityGravity(client, 0.25);
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

