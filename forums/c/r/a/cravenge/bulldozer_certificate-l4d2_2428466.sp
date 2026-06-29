#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.1"
#pragma semicolon 1

static const Float:UNINCAP_TIME_ON_IMPACT = 1.0;
static const Float:CHARGE_CHECKING_INTERVAL = 0.4;
static const Float:CHARGER_COLLISION_RADIUS = 150.0;
static const Float:HEALTH_SET_DELAY = 0.3;

static const String:ENTPROP_HANGING_FROM_LEDGE[] = "m_isHangingFromLedge";
static const String:ENTPROP_FALLING_FROM_LEDGE[] = "m_isFallingFromLedge";

static Handle:ReinCapTimerArray[MAXPLAYERS+1] = INVALID_HANDLE;
static bool:KillChargerTimer = false;
static bool:AlreadyCarrying = false;
static bool:HasMadeImpact = false;
static IncappedHealth[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = "[L4D2] Bulldozer Certificate",
	author = "AtomicStryker",
	description = "Lets Chargers Hit Incapacitated Survivors.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=109797"
};

public OnPluginStart()
{
	CreateConVar("bulldozer_certificate-l4d2_version", PLUGIN_VERSION, "Bulldozer Certificate", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("charger_charge_start", OnChargerChargeStart);
	HookEvent("charger_carry_start", OnChargerCarryStart);
	HookEvent("charger_carry_end", OnChargerCarryEnd);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("charger_charge_end", OnChargerChargeEnd);
	HookEvent("charger_killed", OnChargerChargeEnd);	
	HookEvent("round_end", OnChargerChargeEnd);
}

public Action:OnChargerChargeStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client))
	{
		return;
	}
	
	HasMadeImpact = false;
	KillChargerTimer = false;
	TriggerTimer(CreateTimer(CHARGE_CHECKING_INTERVAL, BC_CheckForIncapped, client, TIMER_REPEAT), true);
}

public Action:OnChargerCarryStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	AlreadyCarrying = true;
}

public Action:OnChargerCarryEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	AlreadyCarrying = false;
}

public Action:OnPlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client))
	{
		return;
	}
	
	if(GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6)
	{
		new target = GetClientOfUserId(GetEventInt(event, "victim"));
		if(IsValidClient(target) && GetClientTeam(target) == 2 && IsPlayerIncapped(target))
		{
			if (ReinCapTimerArray[target] != INVALID_HANDLE)
			{
				CloseHandle(ReinCapTimerArray[target]);
				ReinCapTimerArray[target] = INVALID_HANDLE;
			}
			ReinCapTimerArray[target] = CreateTimer(UNINCAP_TIME_ON_IMPACT * 2, BC_Reincap, target);
		}
	}
	
	HasMadeImpact = true;
	AlreadyCarrying = false;
	KillChargerTimer = true;
	CreateTimer(UNINCAP_TIME_ON_IMPACT, BC_WipeHealthArray);
}

public Action:OnChargerChargeEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	HasMadeImpact = true;
	AlreadyCarrying = false;
	KillChargerTimer = true;
	CreateTimer(UNINCAP_TIME_ON_IMPACT, BC_WipeHealthArray);
}

public OnMapEnd()
{
	HasMadeImpact = false;
	KillChargerTimer = false;
	AlreadyCarrying = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		ReinCapTimerArray[i] = INVALID_HANDLE;
	}
}

public Action:BC_CheckForIncapped(Handle:timer, any:client)
{
	if (!IsValidClient(client) || KillChargerTimer || HasMadeImpact)
	{
		KillChargerTimer = false;
		return Plugin_Stop;
	}
	
	decl Float:targetpos[3], Float:chargerpos[3];
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if (target == client || !IsValidClient(target) || !IsPlayerIncapped(target) || GetEntProp(target, Prop_Send, ENTPROP_HANGING_FROM_LEDGE) || GetEntProp(target, Prop_Send, ENTPROP_FALLING_FROM_LEDGE) || AlreadyCarrying)
		{
			continue;
		}
		
		GetClientAbsOrigin(target, targetpos);
		GetClientAbsOrigin(client, chargerpos);
		
		if (GetVectorDistance(targetpos, chargerpos) < CHARGER_COLLISION_RADIUS)
		{
			if (IncappedHealth[target] == -1)
			{
				IncappedHealth[target] = GetClientHealth(target);
			}
			SetEntProp(target, Prop_Send, "m_isIncapacitated", false);
			ReinCapTimerArray[target] = CreateTimer(UNINCAP_TIME_ON_IMPACT + 1.0, BC_Reincap, target);
		}
	}
	
	return Plugin_Continue;
}

public Action:BC_Reincap(Handle:timer, any:client)
{
	ReinCapTimerArray[client] = INVALID_HANDLE;
	
	if (!IsValidEntity(client))
	{
		return Plugin_Stop;
	}
	
	SetEntProp(client, Prop_Send, "m_isIncapacitated", true);
	
	CreateTimer(HEALTH_SET_DELAY, BC_SetHealthDelayed, client);
	
	return Plugin_Stop;
}

public Action:BC_SetHealthDelayed(Handle:timer, any:client)
{
	if (IsValidEntity(client) && IncappedHealth[client] > 1 && IsPlayerIncapped(client))
	{
		SetEntityHealth(client, IncappedHealth[client]);
	}
	
	return Plugin_Stop;
}

public Action:BC_WipeHealthArray(Handle:timer, any:client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		IncappedHealth[i] = -1;
	}
	
	return Plugin_Stop;
}

public IsValidClient(client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return false;
	}
	
	return true;
}

stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	else
	{
		return false;
	}
}

