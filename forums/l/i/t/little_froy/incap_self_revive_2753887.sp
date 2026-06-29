#define PLUGIN_VERSION	"1.22"
#define PLUGIN_NAME		"Incapped Health Regeneration And Self Revive"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define SOUND_HEARTBEAT	"player/heartbeatloop.wav"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=333666"
};

enum Incapacitaed_Type
{
	Incapacitated_Type_Down = 0,
	Incapacitated_Type_Ledge
};

enum Wait_Type
{
	Wait_Type_Regen = 0,
	Wait_Type_Revive_Delay
};

ConVar C_survivor_incap_decay_rate;

ConVar C_buffer_decay_rate;
ConVar C_revived_health;
ConVar C_incap_max_count;
ConVar C_down_regen_wait_time;
ConVar C_down_regen_repeat_interval;
ConVar C_down_revive_delay;
ConVar C_down_max_health;
ConVar C_down_default_health;
ConVar C_down_regen_health;
ConVar C_down_interrupt_on_hurt;
ConVar C_ledge_regen_wait_time;
ConVar C_ledge_regen_repeat_interval;
ConVar C_ledge_revive_delay;
ConVar C_ledge_max_health;
ConVar C_ledge_default_health;
ConVar C_ledge_regen_health;
ConVar C_ledge_interrupt_on_hurt;
ConVar C_ledge_health_decay;

float O_buffer_decay_rate;
int O_revived_health;
int O_incap_max_count;
float O_down_regen_wait_time;
float O_down_regen_repeat_interval;
float O_down_revive_delay;
int O_down_max_health;
int O_down_default_health;
int O_down_regen_health;
bool O_down_interrupt_on_hurt;
float O_ledge_regen_wait_time;
float O_ledge_regen_repeat_interval;
float O_ledge_revive_delay;
int O_ledge_max_health;
int O_ledge_default_health;
int O_ledge_regen_health;
bool O_ledge_interrupt_on_hurt;
int O_ledge_health_decay;

Handle H_down_regen_start[MAXPLAYERS+1];
Handle H_down_regen_repeat[MAXPLAYERS+1];
Handle H_down_revive_delay[MAXPLAYERS+1];
Handle H_ledge_regen_start[MAXPLAYERS+1];
Handle H_ledge_regen_repeat[MAXPLAYERS+1];
Handle H_ledge_revive_delay[MAXPLAYERS+1];
float Wait_start_time[MAXPLAYERS+1];
float Wait_left_time[MAXPLAYERS+1];
int Health_true[MAXPLAYERS+1];
float Health_buffer[MAXPLAYERS+1];
bool Heartbeat[MAXPLAYERS+1];
bool Backing[MAXPLAYERS+1];
int Going_die[MAXPLAYERS+1];

public void OnMapStart()
{
	PrecacheSound(SOUND_HEARTBEAT, true);
}

void cheat_health(int client) 
{
	int userflags = GetUserFlagBits(client);
	int cmdflags = GetCommandFlags("give");
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags("give", cmdflags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give health");
	SetCommandFlags("give", cmdflags);
	if(IsClientConnected(client))
	{
		SetUserFlagBits(client, userflags);
	}
}

bool is_survivor_hanging(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_survivor_down(int client)
{
	return !is_survivor_alright(client) && !is_survivor_hanging(client);
}

bool is_survivor_falling(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isFallingFromLedge");
}

float get_temp_health(int client)
{
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * O_buffer_decay_rate;
	return buffer < 0.0 ? 0.0 : buffer;
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

int get_revived_count(int client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");    
}

void set_revived_count(int client, int count)
{
	SetEntProp(client, Prop_Send, "m_currentReviveCount", count);    
}

void set_revive_owner(int client, int owner)
{
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", owner);    
}

void set_thirdstrike(int client, int thirdstrike)
{
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", thirdstrike);
}

bool is_survivor_on_thirdstrike(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

int get_going_todie(int client)
{
	return GetEntProp(client, Prop_Send, "m_isGoingToDie");
}

void set_going_todie(int client, int going)
{
	SetEntProp(client, Prop_Send, "m_isGoingToDie", going);
}

void data_trans(int client, int prev)
{
	Backing[client] = Backing[prev];
	Health_true[client] = Health_true[prev];
	Health_buffer[client] = Health_buffer[prev];
	Going_die[client] = Going_die[prev];
}

bool is_survivor_pinned_less(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 
		|| GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0
		|| GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0
		|| GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0;
}

bool is_someone_alright()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
		{
			return true;
		}
	}
	return false;
}

void start_heartbeat(int client)
{
	if(!Heartbeat[client] && !IsFakeClient(client))
	{
		StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
		EmitSoundToClient(client, SOUND_HEARTBEAT, _, SNDCHAN_STATIC);
		Heartbeat[client] = true;
	}
}

void end_heartbeat(int client)
{
	if(Heartbeat[client])
	{
		StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
		Heartbeat[client] = false;
	}
}

Action timer_down_regen_start(Handle timer, any client)
{
	if(!is_someone_alright() || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_down(client) || is_survivor_pinned_less(client))
	{
		H_down_regen_start[client] = null;
		return Plugin_Stop;
	}
	int health = GetClientHealth(client);
	if(health >= O_down_max_health)
	{
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_down_revive_delay;
		H_down_revive_delay[client] = CreateTimer(O_down_revive_delay, timer_down_revive_delay, client);
	}
	else if(health + O_down_regen_health < O_down_max_health)
	{
		SetEntityHealth(client, health + O_down_regen_health);
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_down_regen_repeat_interval;
		H_down_regen_repeat[client] = CreateTimer(O_down_regen_repeat_interval, timer_down_regen_repeat, client, TIMER_REPEAT);
	}
	else
	{
		SetEntityHealth(client, O_down_max_health);
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_down_revive_delay;
		H_down_revive_delay[client] = CreateTimer(O_down_revive_delay, timer_down_revive_delay, client);
	}
	H_down_regen_start[client] = null;
	return Plugin_Stop;
}

Action timer_down_regen_repeat(Handle timer, any client)
{
	if(!is_someone_alright() || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_down(client) || is_survivor_pinned_less(client))
	{
		H_down_regen_repeat[client] = null;
		return Plugin_Stop;
	}
	int health = GetClientHealth(client);
	if(health >= O_down_max_health)
	{
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_down_revive_delay;
		H_down_revive_delay[client] = CreateTimer(O_down_revive_delay, timer_down_revive_delay, client);
		H_down_regen_repeat[client] = null;
		return Plugin_Stop;
	}
	else if(health + O_down_regen_health < O_down_max_health)
	{
		SetEntityHealth(client, health + O_down_regen_health);
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_down_regen_repeat_interval;
		return Plugin_Continue;
	}
	else
	{
		SetEntityHealth(client, O_down_max_health);
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_down_revive_delay;
		H_down_revive_delay[client] = CreateTimer(O_down_revive_delay, timer_down_revive_delay, client);
		H_down_regen_repeat[client] = null;
		return Plugin_Stop;
	}
}

Action timer_down_revive_delay(Handle timer, any client)
{
	if(!is_someone_alright() || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_down(client) || GetClientHealth(client) < O_down_max_health || is_survivor_pinned_less(client))
	{
		H_down_revive_delay[client] = null;
		return Plugin_Stop;
	}
	int revived = get_revived_count(client);
	cheat_health(client);
	set_revive_owner(client, -1);
	SetEntityHealth(client, 1);
	set_temp_health(client, float(O_revived_health));
	set_revived_count(client, ++revived);
	set_going_todie(client, 1);
	if(revived >= O_incap_max_count)
	{
		set_thirdstrike(client, 1);
		if(Heartbeat[client])
		{
			StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
			EmitSoundToClient(client, SOUND_HEARTBEAT, _, SNDCHAN_STATIC);
		}
	}
	H_down_revive_delay[client] = null;
	return Plugin_Stop;
}

Action timer_ledge_regen_start(Handle timer, any client)
{
	if(!is_someone_alright() || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_hanging(client))
	{
		H_ledge_regen_start[client] = null;
		return Plugin_Stop;
	}
	int health = GetClientHealth(client);
	if(health >= O_ledge_max_health)
	{
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_ledge_revive_delay;
		H_ledge_revive_delay[client] = CreateTimer(O_ledge_revive_delay, timer_ledge_revive_delay, client);	
	}
	else if(health + O_ledge_regen_health < O_ledge_max_health)
	{
		SetEntityHealth(client, health + O_ledge_regen_health);
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_ledge_regen_repeat_interval;	
		H_ledge_regen_repeat[client] = CreateTimer(O_ledge_regen_repeat_interval, timer_ledge_regen_repeat, client, TIMER_REPEAT);	
	}
	else
	{
		SetEntityHealth(client, O_ledge_max_health);
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_ledge_revive_delay;
		H_ledge_revive_delay[client] = CreateTimer(O_ledge_revive_delay, timer_ledge_revive_delay, client);
	}
	H_ledge_regen_start[client] = null;
	return Plugin_Stop;
}

Action timer_ledge_regen_repeat(Handle timer, any client)
{
	if(!is_someone_alright() || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_hanging(client))
	{
		H_ledge_regen_repeat[client] = null;
		return Plugin_Stop;
	}
	int health = GetClientHealth(client);
	if(health >= O_ledge_max_health)
	{
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_ledge_revive_delay;
		H_ledge_revive_delay[client] = CreateTimer(O_ledge_revive_delay, timer_ledge_revive_delay, client);
		H_ledge_regen_repeat[client] = null;
		return Plugin_Stop;
	}
	else if(health + O_ledge_regen_health < O_ledge_max_health)
	{
		SetEntityHealth(client, health + O_ledge_regen_health);
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_ledge_regen_repeat_interval;
		return Plugin_Continue;
	}
	else
	{
		SetEntityHealth(client, O_ledge_max_health);
		Wait_start_time[client] = GetGameTime();
		Wait_left_time[client] = O_ledge_revive_delay;
		H_ledge_revive_delay[client] = CreateTimer(O_ledge_revive_delay, timer_ledge_revive_delay, client);
		H_ledge_regen_repeat[client] = null;
		return Plugin_Stop;
	}
}

Action timer_ledge_revive_delay(Handle timer, any client)
{
	if(!is_someone_alright() || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_hanging(client) || GetClientHealth(client) < O_ledge_max_health)
	{
		H_ledge_revive_delay[client] = null;
		return Plugin_Stop;
	}
	int revived = get_revived_count(client);
	cheat_health(client);
	set_revive_owner(client, -1);
	set_revived_count(client, revived);
	if(revived >= O_incap_max_count)
	{
		set_thirdstrike(client, 1);
		if(Heartbeat[client])
		{
			StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
			EmitSoundToClient(client, SOUND_HEARTBEAT, _, SNDCHAN_STATIC);
		}
	}
	H_ledge_revive_delay[client] = null;
	return Plugin_Stop;
}

void end_wait(int client, Incapacitaed_Type type)
{
	switch(type)
	{
		case Incapacitated_Type_Ledge:
		{
			delete H_ledge_regen_start[client];
			delete H_ledge_regen_repeat[client];
			delete H_ledge_revive_delay[client];
		}
		case Incapacitated_Type_Down:
		{
			delete H_down_regen_start[client];
			delete H_down_regen_repeat[client];
			delete H_down_revive_delay[client];
		}
	}
}

void reset_player(int client)
{
	Backing[client] = false;
	Health_true[client] = 0;
	Health_buffer[client] = 0.0;
	Going_die[client] = 0;
	end_wait(client, Incapacitated_Type_Ledge);
	end_wait(client, Incapacitated_Type_Down);
}

float get_halfway_time(int client)
{	
	float halfway_time = Wait_left_time[client] - (GetGameTime() - Wait_start_time[client]);
	return halfway_time < 0.1 ? 0.1 : halfway_time;
}

void start_wait(int client, Incapacitaed_Type incap_type, Wait_Type wait_type, float time)
{
	end_wait(client, incap_type);
	Wait_start_time[client] = GetGameTime();
	Wait_left_time[client] = time;
	switch(incap_type)
	{
		case Incapacitated_Type_Ledge:
		{
			switch(wait_type)
			{
				case Wait_Type_Regen:
				{
					H_ledge_regen_start[client] = CreateTimer(time, timer_ledge_regen_start, client);
				}
				case Wait_Type_Revive_Delay:
				{
					H_ledge_revive_delay[client] = CreateTimer(time, timer_ledge_revive_delay, client);
				}
			}
		}
		case Incapacitated_Type_Down:
		{
			switch(wait_type)
			{
				case Wait_Type_Regen:
				{
					H_down_regen_start[client] = CreateTimer(time, timer_down_regen_start, client);
				}
				case Wait_Type_Revive_Delay:
				{
					H_down_revive_delay[client] = CreateTimer(time, timer_down_revive_delay, client);
				}
			}
		}
	}
}

public void OnGameFrame()
{
	bool someone_alright = is_someone_alright();
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
			{
				if(is_survivor_on_thirdstrike(client))
				{
					start_heartbeat(client);
				}
				else
				{
					end_heartbeat(client);
				}
				if(is_survivor_alright(client))
				{
					if(Backing[client])
					{
						if(is_survivor_falling(client))
						{
							Health_true[client] = 1;
							Health_buffer[client] = 0.0;
							Going_die[client] = 1;
						}
						else
						{
							if(O_ledge_health_decay > 0)
							{
								if(Health_true[client] > 1)
								{
									int left = Health_true[client] - O_ledge_health_decay;
									if(left < 1)
									{
										Health_true[client] = 1;
										Going_die[client] = 1;
										Health_buffer[client] += float(left);
									}
									else
									{
										Health_true[client] -= O_ledge_health_decay;
									}	
								}
								else
								{
									Health_buffer[client] -= float(O_ledge_health_decay);
									Going_die[client] = 1;
								}
								if(Health_buffer[client] < 0.0)
								{
									Health_buffer[client] = 0.0;
								}
							}
						}
						SetEntityHealth(client, Health_true[client]);
						set_temp_health(client, Health_buffer[client]);
						set_going_todie(client, Going_die[client]);
						Backing[client] = false;
					}
					else
					{
						Health_true[client] = GetClientHealth(client);
						Health_buffer[client] = get_temp_health(client);
						Going_die[client] = get_going_todie(client);
					}
					end_wait(client, Incapacitated_Type_Ledge);
					end_wait(client, Incapacitated_Type_Down);
				}
				else if(is_survivor_hanging(client))
				{
					if(someone_alright)
					{
						if(GetClientHealth(client) < O_ledge_max_health)
						{
							if(!H_ledge_regen_start[client] && !H_ledge_regen_repeat[client])
							{
								start_wait(client, Incapacitated_Type_Ledge, Wait_Type_Regen, O_ledge_regen_wait_time);
							}
						}
						else if(!H_ledge_revive_delay[client])
						{
							start_wait(client, Incapacitated_Type_Ledge, Wait_Type_Revive_Delay, O_ledge_revive_delay);
						}
					}
					else
					{
						end_wait(client, Incapacitated_Type_Ledge);
					}
					end_wait(client, Incapacitated_Type_Down);
				}
				else if(is_survivor_down(client))
				{
					if(someone_alright)
					{
						if(GetClientHealth(client) < O_down_max_health)
						{
							if((!H_down_regen_start[client] && !H_down_regen_repeat[client]) || is_survivor_pinned_less(client))
							{
								start_wait(client, Incapacitated_Type_Down, Wait_Type_Regen, O_down_regen_wait_time);
							}
						}
						else if(!H_down_revive_delay[client] || is_survivor_pinned_less(client))
						{
							start_wait(client, Incapacitated_Type_Down, Wait_Type_Revive_Delay, O_down_revive_delay);
						}
					}
					else
					{
						end_wait(client, Incapacitated_Type_Down);
					}
					end_wait(client, Incapacitated_Type_Ledge);
				}
			}
			else
			{
				reset_player(client);
				end_heartbeat(client);
			}
		}
		else
		{
			reset_player(client);
			Heartbeat[client] = false;
		}
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		reset_player(client);
		if(IsClientInGame(client))
		{
			end_heartbeat(client);
		}
		Heartbeat[client] = false;
	}
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!is_someone_alright())
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && event.GetInt("dmg_health") > 0)
	{
		if(is_survivor_hanging(client))
		{
			if(O_ledge_interrupt_on_hurt)
			{
				if(GetClientHealth(client) < O_ledge_max_health)
				{
					start_wait(client, Incapacitated_Type_Ledge, Wait_Type_Regen, O_ledge_regen_wait_time);
				}
				else
				{
					start_wait(client, Incapacitated_Type_Ledge, Wait_Type_Revive_Delay, O_ledge_revive_delay);
				}
			}
		}
		else if(is_survivor_down(client))
		{
			if(O_down_interrupt_on_hurt)
			{
				if(GetClientHealth(client) < O_down_max_health)
				{
					start_wait(client, Incapacitated_Type_Down, Wait_Type_Regen, O_down_regen_wait_time);
				}
				else
				{
					start_wait(client, Incapacitated_Type_Down, Wait_Type_Revive_Delay, O_down_revive_delay);
				}
			}
		}
	}
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	int prev = GetClientOfUserId(event.GetInt("player"));
    if(client != 0 && GetClientTeam(client) == 2 && prev != 0)
    {
        data_trans(client, prev);
		if(!is_someone_alright())
		{
			return;
		}
		if(IsPlayerAlive(client))
		{
			if(is_survivor_hanging(client))
			{
				if(H_ledge_regen_start[prev] || H_ledge_regen_repeat[prev])
				{
					start_wait(client, Incapacitated_Type_Ledge, Wait_Type_Regen, get_halfway_time(prev));
				}
				else if(H_ledge_revive_delay[prev])
				{
					start_wait(client, Incapacitated_Type_Ledge, Wait_Type_Revive_Delay, get_halfway_time(prev));
				}
			}
			else if(is_survivor_down(client))
			{
				if(H_down_regen_start[prev] || H_down_regen_repeat[prev])
				{
					start_wait(client, Incapacitated_Type_Down, Wait_Type_Regen, get_halfway_time(prev));
				}
				else if(H_down_revive_delay[prev])
				{
					start_wait(client, Incapacitated_Type_Down, Wait_Type_Revive_Delay, get_halfway_time(prev));
				}
			}
		}
    }
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int prev = GetClientOfUserId(event.GetInt("bot"));
    if(client != 0 && GetClientTeam(client) == 2 && prev != 0)
    {
        data_trans(client, prev);
		if(!is_someone_alright)
		{
			return;
		}
		if(IsPlayerAlive(client))
		{
			if(is_survivor_hanging(client))
			{
				if(H_ledge_regen_start[prev] || H_ledge_regen_repeat[prev])
				{
					start_wait(client, Incapacitated_Type_Ledge, Wait_Type_Regen, get_halfway_time(prev));
				}
				else if(H_ledge_revive_delay[prev])
				{
					start_wait(client, Incapacitated_Type_Ledge, Wait_Type_Revive_Delay, get_halfway_time(prev));
				}
			}
			else if(is_survivor_down(client))
			{
				if(H_down_regen_start[prev] || H_down_regen_repeat[prev])
				{
					start_wait(client, Incapacitated_Type_Down, Wait_Type_Regen, get_halfway_time(prev));
				}
				else if(H_down_revive_delay[prev])
				{
					start_wait(client, Incapacitated_Type_Down, Wait_Type_Revive_Delay, get_halfway_time(prev));
				}
			}
		}
    }
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_down(client))
	{
		SetEntityHealth(client, O_down_default_health);
		set_temp_health(client, 0.0);
		Backing[client] = false;
		Health_true[client] = 0;
		Health_buffer[client] = 0.0;
		Going_die[client] = 0;
	}
}

void event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_hanging(client))
	{
		SetEntityHealth(client, O_ledge_default_health);
		set_temp_health(client, 0.0);
		Backing[client] = true;
	}
}

void get_cvars()
{
	C_survivor_incap_decay_rate.IntValue = 0;

	O_buffer_decay_rate = C_buffer_decay_rate.FloatValue;
	O_revived_health = C_revived_health.IntValue;
	O_incap_max_count = C_incap_max_count.IntValue;
	O_down_regen_wait_time = C_down_regen_wait_time.FloatValue;
	O_down_regen_repeat_interval = C_down_regen_repeat_interval.FloatValue;
	O_down_revive_delay = C_down_revive_delay.FloatValue;
	O_down_max_health = C_down_max_health.IntValue;
	O_down_default_health = C_down_default_health.IntValue;
	O_down_regen_health = C_down_regen_health.IntValue;
	O_down_interrupt_on_hurt = C_down_interrupt_on_hurt.BoolValue;
	O_ledge_regen_wait_time = C_ledge_regen_wait_time.FloatValue;
	O_ledge_regen_repeat_interval = C_ledge_regen_repeat_interval.FloatValue;
	O_ledge_revive_delay = C_ledge_revive_delay.FloatValue;
	O_ledge_max_health = C_ledge_max_health.IntValue;
	O_ledge_default_health = C_ledge_default_health.IntValue;
	O_ledge_regen_health = C_ledge_regen_health.IntValue;
	O_ledge_interrupt_on_hurt = C_ledge_interrupt_on_hurt.BoolValue;
	O_ledge_health_decay = C_ledge_health_decay.IntValue;

	if(O_revived_health < 1)
	{
		O_revived_health = 1;
	}
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

any native_IncapSelfRevive_IsWaitingForRestoreHealthFromLedgeRevived(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
	{
		ThrowNativeError(0, "client index %d is out of bound", client);
	}
	return Backing[client];
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IncapSelfRevive_IsWaitingForRestoreHealthFromLedgeRevived", native_IncapSelfRevive_IsWaitingForRestoreHealthFromLedgeRevived);
    RegPluginLibrary("incap_self_revive");
    return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("round_start", event_round_start);
	HookEvent("player_hurt", event_player_hurt);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);

	C_survivor_incap_decay_rate = FindConVar("survivor_incap_decay_rate");

	C_buffer_decay_rate = FindConVar("pain_pills_decay_rate");
	C_revived_health = FindConVar("survivor_revive_health");
	C_incap_max_count = FindConVar("survivor_max_incapacitated_count");
	C_down_regen_wait_time = CreateConVar("incap_self_revive_down_wait_time", "2.0", "after the conflict, how long need to wait to regen when down", _, true, 0.1);
	C_down_regen_repeat_interval = CreateConVar("incap_self_revive_down_repeat_interval", "1.0", "after the wait, the repeat interval of regen when down", _, true, 0.1);
	C_down_revive_delay = CreateConVar("incap_self_revive_down_revive_delay", "1.0", "revive delay after health reaches the max when down", _, true, 0.1);
	C_down_max_health = FindConVar("survivor_incap_health");
	C_down_default_health = CreateConVar("incap_self_revive_down_default_health", "240", "default health when been down", _, true, 1.0);
	C_down_regen_health = CreateConVar("incap_self_revive_down_regen_health", "5", "how many health regen once when down", _, true, 1.0);
	C_down_interrupt_on_hurt = CreateConVar("incap_self_revive_down_interrupt_on_hurt", "1", "1 = enable, 0 = disable. interrupt regen on hurt when down?");
	C_ledge_regen_wait_time = CreateConVar("incap_self_revive_ledge_wait_time", "2.0", "after the conflict, how long need to wait to regen when ledge", _, true, 0.1);
	C_ledge_regen_repeat_interval = CreateConVar("incap_self_revive_ledge_repeat_interval", "1.0", "after the wait, the repeat interval of regen when ledge", _, true, 0.1);
	C_ledge_revive_delay = CreateConVar("incap_self_revive_ledge_revive_delay", "1.0", "revive delay after health reaches the max when ledge", _, true, 0.1);
	C_ledge_max_health = FindConVar("survivor_ledge_grab_health");
	C_ledge_default_health = CreateConVar("incap_self_revive_ledge_default_health", "240", "default health when been ledge", _, true, 1.0);
	C_ledge_regen_health = CreateConVar("incap_self_revive_ledge_regen_health", "5", "how many health regen once when ledge", _, true, 1.0);
	C_ledge_interrupt_on_hurt = CreateConVar("incap_self_revive_ledge_interrupt_on_hurt", "1", "1 = enable, 0 = disable. interrupt regen on hurt when ledge?");
	C_ledge_health_decay = CreateConVar("incap_self_revive_ledge_health_decay", "10", "how many health will decay after revived from ledge", _, true, 0.0);

	CreateConVar("incap_self_revive_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

	C_survivor_incap_decay_rate.AddChangeHook(convar_changed);

	C_buffer_decay_rate.AddChangeHook(convar_changed);
	C_revived_health.AddChangeHook(convar_changed);
	C_incap_max_count.AddChangeHook(convar_changed);
	C_down_regen_wait_time.AddChangeHook(convar_changed);
	C_down_regen_repeat_interval.AddChangeHook(convar_changed);
	C_down_revive_delay.AddChangeHook(convar_changed);
	C_down_max_health.AddChangeHook(convar_changed);
	C_down_default_health.AddChangeHook(convar_changed);
	C_down_regen_health.AddChangeHook(convar_changed);
	C_down_interrupt_on_hurt.AddChangeHook(convar_changed);
	C_ledge_regen_wait_time.AddChangeHook(convar_changed);
	C_ledge_regen_repeat_interval.AddChangeHook(convar_changed);
	C_ledge_revive_delay.AddChangeHook(convar_changed);
	C_ledge_max_health.AddChangeHook(convar_changed);
	C_ledge_default_health.AddChangeHook(convar_changed);
	C_ledge_regen_health.AddChangeHook(convar_changed);
	C_ledge_interrupt_on_hurt.AddChangeHook(convar_changed);
	C_ledge_health_decay.AddChangeHook(convar_changed);

	AutoExecConfig(true, "incap_self_revive");
}
