#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define PLUGIN_VERSION "1.11"

#define ZOMBIECLASS_CHARGER 6

new Handle:cvarInertiaVault;
new Handle:cvarInertiaVaultTime = INVALID_HANDLE; // For delay
new Handle:cvarInertiaVaultPower;
new cjJump; // For delay

new Handle:PluginStartTimer = INVALID_HANDLE;
new Handle:hJumpTimer = INVALID_HANDLE;

new bool:isCharging[MAXPLAYERS+1] = false;
new bool:buttondelay[MAXPLAYERS+1] = false;
new bool:isInertiaVault = false;

public Plugin:myinfo = 
{
    name = "[L4D2] Charger Jump",
    author = "Mortiegama",
    description = "Allows Chargers To Jump While Charging.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2116076#post2116076"
};

public OnPluginStart()
{
	CreateConVar("charger_jump-l4d2_version", PLUGIN_VERSION, "Charger Jump Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarInertiaVault = CreateConVar("charger_jump-l4d2_inertiavault", "1", "Enable/Disable Plugin", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarInertiaVaultTime = CreateConVar("charger_jump-l4d2_inertiavaulttime", "15", "Time Before Inertia Vault Applies", FCVAR_NOTIFY);
	cvarInertiaVaultPower = CreateConVar("charger_jump-l4d2_inertiavaultpower", "425.0", "Inertia Vault Value Applied To Charger Jump", FCVAR_NOTIFY, true, 0.0, false, _);
	
	HookEvent("charger_charge_start", OnChargerChargeStart);
	HookEvent("charger_carry_start", OnChargerCarryStart);
	HookEvent("player_death", OnChargerCarryEnd);
	HookEvent("charger_pummel_start", OnChargerCarryEnd);
	HookEvent("charger_carry_end", OnChargerCarryEnd);
	HookEvent("charger_killed", OnChargerCarryEnd);
	HookEvent("charger_charge_end", OnChargerCarryEnd);
	
	AutoExecConfig(true, "charger_jump-l4d2");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
	
	cjJump = GetConVarInt(cvarInertiaVaultTime);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{	
	if (GetConVarInt(cvarInertiaVault))
	{
		isInertiaVault = true;
	}
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public OnChargerChargeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidCharger(client))
	{
		isCharging[client] = true;
		buttondelay[client] = false;
	}
}

public OnChargerCarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidCharger(client))
	{
		// Display progress bar as a delay notifier for players.
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 15.0);
		// Added time delay before a player controlled charger can jump
		// and notify him/her.
		CreateTimer(17.0, JumpDelayTimer, client);
		if(hJumpTimer == INVALID_HANDLE)
		{
			hJumpTimer = CreateTimer(1.0, TimerDelayJump, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			TimerDelayJump(hJumpTimer, client);
		}
	}
}

public OnChargerCarryEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidCharger(client))
	{
		// Remove the bar if player dies or completed the delay but failed to jump.
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		isCharging[client] = false;
		buttondelay[client] = false;
	}
	
	// Add this if you want your victim to fly to their deaths instead of
	// being put down safely. Remove if you don't want to.
	new target = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsValidClient(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target) && !IsPlayerOnGround(target))
	{
		new Float:vec[3];
		new Float:power = GetConVarFloat(cvarInertiaVaultPower);
		vec[0] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[0]");
		vec[1] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[1]");
		vec[2] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[2]") + (power * 3);
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vec);
	}
	
	if(hJumpTimer != INVALID_HANDLE)
	{
		CloseHandle(hJumpTimer);
		hJumpTimer = INVALID_HANDLE;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_JUMP && IsValidCharger(client) && isCharging[client])
	{
		if(isInertiaVault && buttondelay[client] && IsPlayerOnGround(client))
		{
			new Float:vec[3];
			new Float:power = GetConVarFloat(cvarInertiaVaultPower);
			vec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			vec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			vec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]") + power;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
		}
	}
}

public Action:TimerDelayJump(Handle:timer, any:client)
{
	if(timer == hJumpTimer)
	{
		if(cjJump > 0)
		{
			// Notify the player when he/she can jump.
			PrintHintText(client, "Super Jump In %d Seconds!", cjJump);
			cjJump--;
			return Plugin_Continue;
		}
		
		// If timer ends, notify player that he/she can jump.
		PrintHintText(client, "You Can Jump Now!");
	}
	
	return Plugin_Stop;
}

public Action:JumpDelayTimer(Handle:timer, any:client)
{
	// Disable jump if delay already gone and will
	// re-enable if player spawns as a charger again.
	buttondelay[client] = true;
	
	if(hJumpTimer != INVALID_HANDLE)
	{
		CloseHandle(hJumpTimer);
		hJumpTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public OnMapEnd()
{
    for (new client=1; client<=MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			isCharging[client] = false;
			buttondelay[client] = false;
		}
	}
}

public IsValidClient(client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}
	
	return true;
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

public IsValidCharger(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_CHARGER)
		{
			return true;
		}
		
		return false;
	}
	
	return false;
}

