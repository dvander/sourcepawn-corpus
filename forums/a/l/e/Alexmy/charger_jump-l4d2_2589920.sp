#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define PLUGIN_VERSION "2.0"

#define ZOMBIECLASS_CHARGER 6

new Handle:cvarInertiaVault;
new Handle:cvarInertiaVaultPower;
new Handle:cvarInertiaVaultDelay;

new Handle:PluginStartTimer = INVALID_HANDLE;

new bool:isCharging[MAXPLAYERS+1] = false;
new bool:buttondelay[MAXPLAYERS+1] = false;
new bool:isInertiaVault = false;

new Float:ivWait;
new Handle:JumpTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new timerElapsed = 0;

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
	cvarInertiaVaultPower = CreateConVar("charger_jump-l4d2_inertiavaultpower", "425.0", "Inertia Vault Value Applied To Charger Jump", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarInertiaVaultDelay = CreateConVar("charger_jump-l4d2_inertiavaultdelay", "11.0", "Delay Before Inertia Vault Kicks In", FCVAR_NOTIFY, true, 0.0, false, _);
	
	HookEvent("charger_charge_start", OnChargerChargeStart);
	HookEvent("charger_carry_start", OnChargerCarryStart);
	HookEvent("charger_charge_end", OnChargerClear);
	HookEvent("charger_carry_end", OnChargerClear);
	HookEvent("charger_killed", OnChargerClear);
	
	ivWait = GetConVarFloat(cvarInertiaVaultDelay);
	
	AutoExecConfig(true, "charger_jump-l4d2");
	if (PluginStartTimer == INVALID_HANDLE)
	{
		PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
	}
}

public Action:OnPluginStart_Delayed(Handle:timer)
{	
	if (GetConVarInt(cvarInertiaVault))
	{
		isInertiaVault = true;
	}
	
	if (PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Action:OnChargerChargeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new charging = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidCharger(charging) && !IsFakeClient(charging))
	{
		isCharging[charging] = true;
		buttondelay[charging] = false;
	}
}

public Action:OnChargerCarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new carrying = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidCharger(carrying) && !IsFakeClient(carrying))
	{
		SetEntPropFloat(carrying, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(carrying, Prop_Send, "m_flProgressBarDuration", ivWait);
		
		if (JumpTimer[carrying] != INVALID_HANDLE)
		{
			delete(JumpTimer[carrying]);
			JumpTimer[carrying] = INVALID_HANDLE;
		}
		JumpTimer[carrying] = CreateTimer(ivWait, CloseJumpHandle, carrying, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:OnChargerClear(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidCharger(attacker) && !IsFakeClient(attacker))
	{
		SetEntPropFloat(attacker, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(attacker, Prop_Send, "m_flProgressBarDuration", 0.0);
		
		isCharging[attacker] = false;
		
		if (buttondelay[attacker])
		{
			buttondelay[attacker] = false;
			
			new target = GetClientOfUserId(GetEventInt(event, "victim"));
			if (IsValidClient(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target) && !IsPlayerOnGround(target))
			{
				new Float:power = GetConVarFloat(cvarInertiaVaultPower);
				
				decl Float:vec[3];
				vec[0] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[0]");
				vec[1] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[1]");
				vec[2] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[2]") + (power * 3);
				
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vec);
				
				new Handle:releaseFix = CreateDataPack();
				WritePackCell(releaseFix, GetClientUserId(attacker));
				WritePackCell(releaseFix, GetClientUserId(target));
				CreateTimer(1.0, CheckForReleases, releaseFix, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
			}
		}
		
	}
}

public Action:CheckForReleases(Handle:timer, Handle:releaseFix)
{
	ResetPack(releaseFix);
	
	new charger = GetClientOfUserId(ReadPackCell(releaseFix));
	new survivor = GetClientOfUserId(ReadPackCell(releaseFix));
	if (!IsValidCharger(charger) || IsFakeClient(charger) || !IsValidClient(survivor) || GetClientTeam(survivor) != 2 || IsPlayerAlive(survivor))
	{
		if (timerElapsed < 5)
		{
			timerElapsed += 1;
			return Plugin_Continue;
		}
		else
		{
			timerElapsed = 0;
			return Plugin_Stop;
		}
	}
	
	new Handle:OnPlayerDeath = CreateEvent("player_death", true);
	SetEventInt(OnPlayerDeath, "userid", GetClientUserId(survivor));
	SetEventInt(OnPlayerDeath, "attacker", GetClientUserId(charger));
	FireEvent(OnPlayerDeath, false);
	
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_JUMP) && IsValidCharger(client) && !IsFakeClient(client) && isCharging[client])
	{
		if (isInertiaVault && buttondelay[client] && IsPlayerOnGround(client))
		{
			new Float:power = GetConVarFloat(cvarInertiaVaultPower);
			
			decl Float:vec[3];
			vec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			vec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			vec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]") + power;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
		}
	}
}

public Action:CloseJumpHandle(Handle:timer, any:carrying)
{
	buttondelay[carrying] = true;
	PrintHintText(carrying, "You Can Jump Now!");
	JumpTimer[carrying] = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public OnMapEnd()
{
	timerElapsed = 0;
	for (new client=1; client<=MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			isCharging[client] = false;
			buttondelay[client] = false;
			
			if (JumpTimer[client] != INVALID_HANDLE)
			{
				KillTimer(JumpTimer[client]);
				JumpTimer[client] = INVALID_HANDLE;
			}
		}
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}
	
	return true;
}

stock bool:IsPlayerOnGround(client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND)
	{
		return true;
	}
	
	return false;
}

stock bool:IsValidCharger(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_CHARGER)
		{
			return true;
		}
	}
	
	return false;
}

