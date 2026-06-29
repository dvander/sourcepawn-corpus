#define PATH	"jump_avoid_3.4"

#define LEFT					(1)
#define BACK					(2)
#define RIGHT					(3)

#pragma tabsize 0
#include <sourcemod>
#include <sdktools>

ConVar C_maxtimes = null;
ConVar C_regencd = null;
ConVar C_distance = null;

int O_maxtimes = 0;
float O_regencd = 0.0;
float O_distance = 0.0;

int Avoid_used_times[MAXPLAYERS+1] = {0, ...};

Handle H_timer_avoid_regen[MAXPLAYERS+1] = {null, ...};

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}
public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}
public bool IsPlayerAlright(int client)
{
	return !(IsPlayerFalling(client) || IsPlayerFallen(client));
}

public bool IsValidSurvivor(int client)
{
	if(client >= 1 && client <= MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) == 2)
			{
				return true;
			}
		}
	}
	return false;
}


public Action Timer_avoid_regen(Handle timer, int client)
{
    if(!IsValidSurvivor(client))
	{
		H_timer_avoid_regen[client] = null;
		return Plugin_Stop;		
	}
    if(IsFakeClient(client) || !IsPlayerAlive(client))
	{
		H_timer_avoid_regen[client] = null;
		return Plugin_Stop;		
	}
	if(Avoid_used_times[client] == 0)
	{
		H_timer_avoid_regen[client] = null;
		return Plugin_Stop;
	}
	if(Avoid_used_times[client] <= O_maxtimes)
	{
		Avoid_used_times[client]--;
		PrintToChat(client, "%d/%d, Stamina regon|精力恢复", Avoid_used_times[client], O_maxtimes);
	}
	if(Avoid_used_times[client] == 0)
	{
		H_timer_avoid_regen[client] = null;
		return Plugin_Stop;
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(IsValidSurvivor(client))
	{
		if(!IsFakeClient(client) && IsPlayerAlive(client) && IsPlayerAlright(client))
		{
			if(buttons & IN_JUMP)
			{
				int flags = GetEntityFlags(client);
				if(flags & FL_ONGROUND)
				{
					if(buttons & IN_FORWARD)
					{
						return Plugin_Continue;
					}
					if(buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_BACK)
					{
						if(Avoid_used_times[client] == O_maxtimes)
						{
							PrintToChat(client, "No Stamina!|精力不足！");
							return Plugin_Continue;
						}
						if(Avoid_used_times[client] < O_maxtimes)
						{
							Avoding(client);
							return Plugin_Continue;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public void Avoding_doing(int client, int DIRC)
{
	float ang[3];
	float vec[3];
	float vel[3];
	GetClientEyeAngles(client, ang);
	if(DIRC == LEFT || DIRC == RIGHT)
	{
		GetAngleVectors(ang, NULL_VECTOR, vec, NULL_VECTOR);
	}
	if(DIRC == BACK)
	{
		GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
	}
	NormalizeVector(vec, vec);
	if(DIRC == LEFT || DIRC == BACK)
	{
		ScaleVector(vec, -O_distance);
	}
	if(DIRC == RIGHT)
	{
		ScaleVector(vec, O_distance);
	}
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vel);
	AddVectors(vel, vec, vel);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	Avoid_used_times[client]++;
	KillTheTimer(client);
	H_timer_avoid_regen[client] = CreateTimer(O_regencd, Timer_avoid_regen, client, TIMER_REPEAT);
	PrintToChat(client, "Stamina Used|精力已用 %d/%d", Avoid_used_times[client], O_maxtimes);
}

public void Avoding(int client)
{
	int buttons = GetClientButtons(client);
	if(buttons & IN_BACK)
	{
		if(buttons & IN_MOVELEFT)
		{
			return;
		}
		if(buttons & IN_MOVERIGHT)
		{
			return;
		}
		Avoding_doing(client, BACK);
		return;
	}
	if(buttons & IN_MOVELEFT)
	{
		if(buttons & IN_BACK)
		{
			return;
		}
		if(buttons & IN_MOVERIGHT)
		{
			return;
		}
		Avoding_doing(client, LEFT);
		return;
	}
	if(buttons & IN_MOVERIGHT)
	{
		if(buttons & IN_BACK)
		{
			return;
		}
		if(buttons & IN_MOVELEFT)
		{
			return;
		}
		Avoding_doing(client, RIGHT);
		return;
	}
}

public void KillTheTimer(int client)
{
    if(H_timer_avoid_regen[client] != null)
    {
        KillTimer(H_timer_avoid_regen[client]);
        H_timer_avoid_regen[client] = null;
    }   
}

public void ResetAll()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		Avoid_used_times[client] = 0;
		KillTheTimer(client);
	}
}

public void Evnet_round(Event event, const char[] name, bool dontBroadcast)
{
	ResetAll();
}

public void Event_player_bot(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "player"));
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
    if(IsValidSurvivor(bot))
    {
        Avoid_used_times[player] = O_maxtimes;
        Avoid_used_times[bot] = O_maxtimes;
		KillTheTimer(player);
		KillTheTimer(bot);
    }
}

public void Event_bot_player(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
    int player = GetClientOfUserId(GetEventInt(event, "player"));
    if(IsValidSurvivor(player))
    {
        Avoid_used_times[player] = O_maxtimes;
        Avoid_used_times[bot] = O_maxtimes;
		KillTheTimer(player);
		KillTheTimer(bot);
		H_timer_avoid_regen[player] = CreateTimer(O_regencd, Timer_avoid_regen, player, TIMER_REPEAT);
    }
}

public void Internal_changed()
{
	O_maxtimes = GetConVarInt(C_maxtimes);
	O_regencd = GetConVarFloat(C_regencd);
	O_distance = GetConVarFloat(C_distance);
}

public void ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Internal_changed();
}

public void OnConfigsExecuted()
{
	Internal_changed();
}

public void OnPluginStart()
{
    HookEvent("player_bot_replace", Event_player_bot);
    HookEvent("bot_player_replace", Event_bot_player);
    HookEvent("round_start", Evnet_round);
	C_maxtimes = CreateConVar("avoid_max", "2", "avoid max used times", FCVAR_SPONLY, true, 1.0);
    C_regencd = CreateConVar("avoid_regen", "8.0", "how long time, avoid times reduce once", FCVAR_SPONLY, true, 0.1);
    C_distance = CreateConVar("avoid_distance", "160", "how far you can jump avoid", FCVAR_SPONLY, true, 10.0);
	C_maxtimes.AddChangeHook(ConvarChanged);
	C_regencd.AddChangeHook(ConvarChanged);
    C_distance.AddChangeHook(ConvarChanged);
	AutoExecConfig(true, PATH);
}