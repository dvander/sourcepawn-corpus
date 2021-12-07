#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "L4D Velocity Pounce",
	author = " AtomicStryker",
	description = "Pounce Damage equals Velocity",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("l4d_velocitypounce_version", PLUGIN_VERSION, " L4D Velocity Pounce Plugin Version ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("ability_use", Event_PounceStart);
	HookEvent("lunge_pounce", Event_PounceFinish, EventHookMode_Pre);
}

new bool:TrackPlayerSpeed[MAXPLAYERS+1] = false;
new Float:CurrentSpeed[MAXPLAYERS+1][3];
new Float:PastSpeed[MAXPLAYERS+1][3];

new Handle:PlayerTracker[MAXPLAYERS+1] = INVALID_HANDLE;

new EverySecondFrame;

public OnGameFrame()
{
	if (!IsServerProcessing()) return;
	
	if (EverySecondFrame < 2)
	{
		EverySecondFrame++;
		return;
	}
	EverySecondFrame = 1;
	
	for (new i=1; i <= GetMaxClients(); i++)
	{
		if (TrackPlayerSpeed[i] && IsClientInGame(i))
		{
			PastSpeed[i][0] = CurrentSpeed[i][0];
			PastSpeed[i][1] = CurrentSpeed[i][1];
			PastSpeed[i][2] = CurrentSpeed[i][2];
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", CurrentSpeed[i]);
		}
	}
}

public Event_PounceStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (PlayerTracker[hunter] != INVALID_HANDLE)
	{
		KillTimer(PlayerTracker[hunter]);
		PlayerTracker[hunter] = INVALID_HANDLE;
	}
	
	TrackPlayerSpeed[hunter] = true;
	PlayerTracker[hunter] = CreateTimer(10.0, StopTracking, hunter);
	
	SetConVarInt(FindConVar("z_hunter_max_pounce_bonus_damage"), 0);
}

public Action:StopTracking(Handle:timer, any:client)
{
	TrackPlayerSpeed[client] = false;
	if (PlayerTracker[client] != INVALID_HANDLE)
		PlayerTracker[client] = INVALID_HANDLE;
}

public Action:Event_PounceFinish(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!attacker || !victim) return Plugin_Continue;
	
	if (PlayerTracker[attacker] != INVALID_HANDLE)
	{
		KillTimer(PlayerTracker[attacker]);
		PlayerTracker[attacker] = INVALID_HANDLE;
	}
	
	new velocity = RoundToNearest(GetVectorLength(PastSpeed[attacker]));
	
	//this function by eyeonus, "math geek"
	new Float:damage = ((float(velocity)*4)/75)-30;
	if (damage < 0)
	{
		damage = 0.0;
		return Plugin_Continue;
	}
	
	new hardhp = GetClientHealth(victim) + 2;
	
	if (damage < hardhp || IsPlayerIncapped(victim))
	{
		SetEntityHealth(victim, hardhp - RoundToNearest(damage));
	}
	
	else
	{
		new Float:temphp = GetEntPropFloat(victim, Prop_Send, "m_healthBuffer") +2.0;
		if (damage < temphp)
		{
			SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", FloatSub(temphp,damage));
		}
	}
	
	PrintToChatAll("\x04%N\x01 pounced \x04%N\x01 with \x03%i\x01 speed, for \x03%f\x01 damage", attacker, victim, velocity, damage);
	
	new max = GetConVarInt(FindConVar("z_pounce_damage_range_max"));
	new min = GetConVarInt(FindConVar("z_pounce_damage_range_min"));
	
	new distance = ((((velocity * 4) / 75) - 31) * (max - min)) + min;
	
	SetEventInt(event, "distance", distance);
	return Plugin_Changed;
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
