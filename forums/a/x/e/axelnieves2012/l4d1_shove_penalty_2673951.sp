#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

public Plugin myinfo = 
{
	name = "L4D1 Shove Penalty on Coop",
	author = "Axel Juan Nieves",
	description = "Allows shoving fatigue on co-op.",
	version = PLUGIN_VERSION,
	url = ""
}

Handle hPenalty; 
Handle hMaxPenalty; 
Handle hMinPenalty;
float g_fLastShoveTime[MAXPLAYERS+1];
float g_fNextShoveTime[MAXPLAYERS+1];
int g_swings[MAXPLAYERS+1];
Handle g_timers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle gun_swing_interval;

public void OnPluginStart()
{
	
	hPenalty = CreateConVar("z_gun_swing_coop_penalty_enabled", "1", "Enables/Disables this plugin", 0);
	hMaxPenalty = CreateConVar("z_gun_swing_coop_max_penalty", "8", "**The number of swings before the maximum punch/melee/shove fatigue delay is set in (coop).", 0);
	hMinPenalty = CreateConVar("z_gun_swing_coop_min_penalty", "5", "**The number of swings before the minimum punch/melee/shove fatigue delay is set in (coop).", 0);
	gun_swing_interval = FindConVar("z_gun_swing_interval");
	

	AutoExecConfig(true, "l4d1_shove_penalty_on_coop");
	
	HookEvent("player_death", shove_reset, EventHookMode_Post);
	HookEvent("player_spawn", shove_reset, EventHookMode_Post);
	
	AddNormalSoundHook(view_as<NormalSHook>(HookSound_Callback));
}

//This hook will be useful for our purpose because there are no events fired when player shoves. 
public Action HookSound_Callback(int Clients[64], int &NumClients, char StrSample[PLATFORM_MAX_PATH], int &client)
{
	//check if playing on coop mode...
	char gamemode[16];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode))
	if ( StrEqual(gamemode, "coop", false)==false )
	{
		SetFailState("Plugin supports coop mode only.");
		return Plugin_Continue;
	}
	
	if ( !GetConVarBool(hPenalty) )
		return Plugin_Continue;
	
	//Shove detected...
	if ( StrContains(StrSample, "player/survivor/swing/Swish_WeaponSwing_Swipe")!=0 ) 
		return Plugin_Continue;
	
	if ( !IsValidClientInGame(client) )
		return Plugin_Continue;
	
	float gametime = GetGameTime();
	int min = GetConVarInt(hMinPenalty)-1;
	int max = GetConVarInt(hMaxPenalty)-1;
	
	//Here we will increment player's shoving counter (before reaching minimun penalty)...
	if ( g_swings[client]<min )
	{
		g_fNextShoveTime[client] = gametime + GetConVarFloat(gun_swing_interval)*1.75;
		if ( gametime-g_fLastShoveTime[client] < g_fNextShoveTime[client] )
		{
			if ( g_swings[client] < max)
			{
				g_swings[client]++;
				//PrintToChatAll("+1 Swings: %i", g_swings[client])
			}
		}
	}
	else //Here we increment it slowly, due to penalty...
	{
		g_fNextShoveTime[client] = gametime + (g_swings[client] * 2.0) / max;
		if ( gametime-g_fLastShoveTime[client] < GetConVarFloat(gun_swing_interval)*2.0 )
		{
			if ( g_swings[client] < max)
			{
				g_swings[client]++;
				//PrintToChatAll("+1 (penalty) Swings: %i", g_swings[client])
			}
		}
	}
	
	//we need to create a timer to decrement player's shove counter...
	if ( g_timers[client]==INVALID_HANDLE )
		g_timers[client] = CreateTimer(0.1, decrease_swings, client, TIMER_REPEAT);
	
	//check min shove limit and add penalty...
	if ( g_swings[client] >= min)
	{
		SetEntPropFloat( client, Prop_Send, "m_flNextShoveTime", g_fNextShoveTime[client]);
		SetEntProp(client, Prop_Send, "m_iShovePenalty", g_swings[client]);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iShovePenalty", 0);
	}
	
	g_fLastShoveTime[client] = gametime;
	return Plugin_Continue;
}

public Action decrease_swings(Handle timer, int client)
{
	if ( !IsValidClientInGame(client) || g_swings[client]==0 )
	{
		g_fLastShoveTime[client] = 0.0;
		g_fNextShoveTime[client] = 0.0;
		g_swings[client] = 0;
		if ( g_timers[client] )
			KillTimer(g_timers[client]);
		g_timers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	float gametime = GetGameTime();
	int min = GetConVarInt(hMinPenalty)-1;
	int max = GetConVarInt(hMaxPenalty)-1;
	
	if ( g_swings[client]<min )
	{
		if ( gametime >= g_fNextShoveTime[client] )
		{
			if ( g_swings[client]>0 )
			{
				g_swings[client]--;
				g_fNextShoveTime[client] = gametime + GetConVarFloat(gun_swing_interval)*1.75;
				//PrintToChatAll("-1 (quick) Swings: %i", g_swings[client]);
			}
		}
	}
	else
	{
		if ( gametime >= g_fNextShoveTime[client] )
		{
			if ( g_swings[client]>0 )
			{
				g_swings[client]--;
				g_fNextShoveTime[client] = gametime + (g_swings[client] * 2.0) / max;
				//PrintToChatAll("-1 (slooow) Swings: %i", g_swings[client])
			}
		}
	}
	return Plugin_Continue;
}

public Action shove_reset(Handle event, char[] event_name, bool dontBroadcast)
{
	int client  = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsValidClientInGame(client) )
		return Plugin_Continue;
	
	g_swings[client] = 0;
	g_fLastShoveTime[client] = 0.0;
	g_fNextShoveTime[client] = 0.0;
	if ( g_timers[client] )
		KillTimer(g_timers[client]);
	g_timers[client] = INVALID_HANDLE;
	
	return Plugin_Continue;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}