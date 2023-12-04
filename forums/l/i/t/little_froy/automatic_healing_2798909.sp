#define PLUGIN_VERSION	"3.1"
#define PLUGIN_NAME		"Automatic Healing"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define	INTERRUPT_HURT					(1 << 0)
#define INTERRUPT_PRIMARY_ATTACK		(1 << 1)
#define INTERRUPT_SHOVE					(1 << 2)
#define INTERRUPT_STAGGERED				(1 << 3)
#define INTERRUPT_PINNED				(1 << 4)
#define INTERRUPT_STRIKED_FLY			(1 << 5)
#define INTERRUPT_STANDING_UP			(1 << 6)
#define INTERRUPT_FALLING_FROM_LEDGE	(1 << 7)

#define MEDICINE_PILLS		(1 << 0)
#define MEDICINE_ADRENALINE	(1 << 1)
#define MEDICINE_MEDKIT		(1 << 2)

#define SOUND_SHOVE		")player/survivor/swing/swish_weaponswing_swipe"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336073"
};

enum Survivor_Status_Check
{
	Survivor_Status_Striked_Fly = 0,
	Survivor_Status_Standing_Up,
}

ConVar C_buffer_decay_rate;
ConVar C_pain_pills_health_value;
ConVar C_adrenaline_health_buffer;
ConVar C_interrupt;
ConVar C_wait_time;
ConVar C_health;
ConVar C_max;
ConVar C_repeat_interval;
ConVar C_survivor_max_health;
ConVar C_medicine;

float O_buffer_decay_rate;
float O_pain_pills_health_value;
float O_adrenaline_health_buffer;
int O_interrupt;
float O_wait_time;
float O_health;
float O_max;
float O_repeat_interval;
float O_survivor_max_health;
int O_medicine;

float O_max_round_to_floor;

int Strlen_shove;

float Wait_start_time[MAXPLAYERS+1];
float Wait_left_time[MAXPLAYERS+1];
bool First[MAXPLAYERS+1];
Handle H_waiting_start[MAXPLAYERS+1];
Handle H_waiting_repeat[MAXPLAYERS+1];

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_survivor_pinned(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 
		|| GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0
		|| GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0
		|| GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0
		|| GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0;
}

bool is_get_staggered(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0;
}

bool is_survivor_falling(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isFallingFromLedge");
}

bool is_survivor_in_status(char model_at_29, int sequence, Survivor_Status_Check type)
{
	switch(model_at_29)
	{
		case 'b'://nick
		{
			switch(type)
			{
				case Survivor_Status_Striked_Fly:
				{
					switch(sequence)
					{
						case 661, 669, 629:
							return true;
					}
				}
				case Survivor_Status_Standing_Up:
				{
					switch(sequence)
					{
						case 667, 671, 672, 627, 630, 620, 680:
							return true;
					}
				}
			}
		}
		case 'd'://rochelle
		{
			switch(type)
			{
				case Survivor_Status_Striked_Fly:
				{
					switch(sequence)
					{
						case 668, 676, 637:
							return true;
					}
				}
				case Survivor_Status_Standing_Up:
				{
					switch(sequence)
					{
						case 674, 678, 679, 635, 638, 629, 687:
							return true;
					}
				}
			}
		}
		case 'c'://coach
		{
			switch(type)
			{
				case Survivor_Status_Striked_Fly:
				{
					switch(sequence)
					{
						case 650, 658, 629:
							return true;
					}
				}
				case Survivor_Status_Standing_Up:
				{
					switch(sequence)
					{
						case 656, 660, 661, 627, 630, 621, 669:
							return true;
					}
				}
			}
		}
		case 'h'://ellis
		{
			switch(type)
			{
				case Survivor_Status_Striked_Fly:
				{
					switch(sequence)
					{
						case 665, 673, 634:
							return true;
					}
				}
				case Survivor_Status_Standing_Up:
				{
					switch(sequence)
					{
						case 671, 675, 676, 632, 635, 625, 684:
							return true;
					}
				}
			}
		}
		case 'v'://bill
		{
			switch(type)
			{
				case Survivor_Status_Striked_Fly:
				{
					switch(sequence)
					{
						case 753, 761, 537:
							return true;
					}
				}
				case Survivor_Status_Standing_Up:
				{
					switch(sequence)
					{
						case 759, 763, 764, 535, 538, 528, 772:
							return true;
					}
				}
			}
		}
		case 'n'://zoey
		{
			switch(type)
			{
				case Survivor_Status_Striked_Fly:
				{
					switch(sequence)
					{
						case 813, 821, 546:
							return true;
					}
				}
				case Survivor_Status_Standing_Up:
				{
					switch(sequence)
					{
						case 819, 823, 824, 544, 547, 537, 809:
							return true;
					}
				}
			}
		}
		case 'e'://francis
		{
			switch(type)
			{
				case Survivor_Status_Striked_Fly:
				{
					switch(sequence)
					{
						case 756, 764, 540:
							return true;
					}
				}
				case Survivor_Status_Standing_Up:
				{
					switch(sequence)
					{
						case 762, 766, 767, 538, 541, 531, 775:
							return true;
					}
				}
			}
		}
		case 'a'://louis
		{
			switch(type)
			{
				case Survivor_Status_Striked_Fly:
				{
					switch(sequence)
					{
						case 753, 761, 537:
							return true;
					}
				}
				case Survivor_Status_Standing_Up:
				{
					switch(sequence)
					{
						case 759, 763, 764, 535, 538, 528, 772:
							return true;
					}
				}
			}
		}
	}
	return false;
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

Action timer_heal_wait_start(Handle timer, any client)
{
	if(!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_alright(client))
	{
		H_waiting_start[client] = null;
		return Plugin_Stop;
	}
	float health = float(GetClientHealth(client));
	float buffer = get_temp_health(client);
	float all = health + buffer;
	if(all < O_max_round_to_floor)
	{
		if(all + O_health < O_max_round_to_floor)
		{
			set_temp_health(client, buffer + O_health);
			Wait_start_time[client] = GetGameTime();
			Wait_left_time[client] = O_repeat_interval;
			H_waiting_repeat[client] = CreateTimer(O_repeat_interval, timer_heal_wait_repeat, client, TIMER_REPEAT);
		}
		else
		{
			set_temp_health(client, O_max - health);
		}
	}
	else if(all < O_max)
	{
		set_temp_health(client, O_max - health);
	}
	H_waiting_start[client] = null;
	return Plugin_Stop;
}
			
Action timer_heal_wait_repeat(Handle timer, any client)
{
	if(!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_alright(client))
	{
		H_waiting_repeat[client] = null;
		return Plugin_Stop;
	}
	float health = float(GetClientHealth(client));
	float buffer = get_temp_health(client);
	float all = health + buffer;
	if(all < O_max_round_to_floor)
	{
		if(all + O_health < O_max_round_to_floor)
		{
			set_temp_health(client, buffer + O_health);
			Wait_start_time[client] = GetGameTime();
			Wait_left_time[client] = O_repeat_interval;
			return Plugin_Continue;
		}
		else
		{
			set_temp_health(client, O_max - health);
		}
	}
	else if(all < O_max)
	{
		set_temp_health(client, O_max - health);
	}
	H_waiting_repeat[client] = null;
	return Plugin_Stop;
}

void end_heal(int client)
{
	delete H_waiting_start[client];
	delete H_waiting_repeat[client];
}

float get_halfway_time(int client)
{
	float halfway_time = Wait_left_time[client] - (GetGameTime() - Wait_start_time[client]);
	return halfway_time < 0.1 ? 0.1 : halfway_time;
}

bool lower_than_heal_max(int client)
{
	return float(GetClientHealth(client)) + get_temp_health(client) < O_max_round_to_floor;
}

void wait_to_heal(int client, float time)
{
	end_heal(client);
	Wait_start_time[client] = GetGameTime();
	Wait_left_time[client] = time;
	H_waiting_start[client] = CreateTimer(time, timer_heal_wait_start, client);
}

public void OnGameFrame()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			int team = GetClientTeam(client);
			if(team == 2)
			{
				if(IsPlayerAlive(client) && is_survivor_alright(client))
				{
					if(First[client])
					{
						end_heal(client);
						float health = float(GetClientHealth(client));
						if(health + get_temp_health(client) < O_max)
						{
							set_temp_health(client, O_max - health);
						}
						First[client] = false;
					}
					else
					{
						float health = float(GetClientHealth(client));
						float all = health + get_temp_health(client);
						if(all < O_max_round_to_floor)
						{
							bool restart = false;
							if(!H_waiting_start[client] && !H_waiting_repeat[client])
							{
								restart = true;
							}
							else if(O_interrupt & INTERRUPT_STAGGERED && is_get_staggered(client))
							{
								restart = true;
							}
							else if(O_interrupt & INTERRUPT_PINNED && is_survivor_pinned(client))
							{
								restart = true;
							}
							else if(O_interrupt & INTERRUPT_FALLING_FROM_LEDGE && is_survivor_falling(client))
							{
								restart = true;
							}
							else if(O_interrupt & INTERRUPT_STRIKED_FLY || O_interrupt & INTERRUPT_STANDING_UP)
							{
								static char model[PLATFORM_MAX_PATH];
								if(GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model)) > 29)
								{
									int sequence = GetEntProp(client, Prop_Send, "m_nSequence");
									if(O_interrupt & INTERRUPT_STRIKED_FLY && is_survivor_in_status(model[29], sequence, Survivor_Status_Striked_Fly))
									{
										restart = true;
									}
									else if(O_interrupt & INTERRUPT_STANDING_UP && is_survivor_in_status(model[29], sequence, Survivor_Status_Standing_Up))
									{
										restart = true;
									}
								}
							}
							if(restart)
							{
								wait_to_heal(client, O_wait_time);
							}
						}
						else
						{
							end_heal(client);
							if(all < O_max)
							{
								set_temp_health(client, O_max - health);
							}
						}
					}
				}
				else
				{
					end_heal(client);
					First[client] = false;
				}
			}
			else
			{
				end_heal(client);
				if(team != 0)
				{
					First[client] = false;
				}
			}
		}
		else
		{
			end_heal(client);
			First[client] = true;
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!(O_interrupt & INTERRUPT_PRIMARY_ATTACK))
	{
		return;
	}
	if(strcmp(classname, "molotov_projectile") == 0 || strcmp(classname, "pipe_bomb_projectile") == 0 || strcmp(classname, "vomitjar_projectile") == 0) 
	{
		SDKHook(entity, SDKHook_SpawnPost, on_spawn_post_projectile);
	}
}

void on_spawn_post_projectile(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client > 0 && client <= MaxClients && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client))
	{
		wait_to_heal(client, O_wait_time);
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		end_heal(client);
		First[client] = true;
	}
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_interrupt & INTERRUPT_HURT))
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client) && event.GetInt("dmg_health") > 0)
	{
		wait_to_heal(client, O_wait_time);
	}
}

void event_weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_interrupt & INTERRUPT_PRIMARY_ATTACK))
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client))
	{
		switch(event.GetInt("weaponid"))
		{
			case 15, 23, 13, 14, 25, 16, 17, 18, 27, 28, 29:
				return;
		}
		wait_to_heal(client, O_wait_time);
	}
}

void event_pills_used(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_medicine & MEDICINE_PILLS))
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		float expected = O_max + O_pain_pills_health_value;
		if(expected > O_survivor_max_health)
		{
			expected = O_survivor_max_health;
		}
		float health = float(GetClientHealth(client));
		if(health + get_temp_health(client) < expected)
		{
			set_temp_health(client, expected - health);
		}
    }
}

void event_adrenaline_used(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_medicine & MEDICINE_ADRENALINE))
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		float expected = O_max + O_adrenaline_health_buffer;
		if(expected > O_survivor_max_health)
		{
			expected = O_survivor_max_health;
		}
		float health = float(GetClientHealth(client));
		if(health + get_temp_health(client) < expected)
		{
			set_temp_health(client, expected - health);
		}
    }
}

void event_heal_success(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_medicine & MEDICINE_MEDKIT))
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("subject"));
    if(client != 0 && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		float health = float(GetClientHealth(client));
		if(health + get_temp_health(client) < O_max)
		{
			set_temp_health(client, O_max - health);
		}
    }
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	int prev = GetClientOfUserId(event.GetInt("player"));
	if(client != 0 && GetClientTeam(client) == 2 && prev != 0)
	{
		First[client] = First[prev];
		if(IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client) && (H_waiting_start[prev] || H_waiting_repeat[prev]))
		{
			wait_to_heal(client, get_halfway_time(prev));
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int prev = GetClientOfUserId(event.GetInt("bot"));
	if(client != 0 && GetClientTeam(client) == 2 && prev != 0)
	{
		First[client] = First[prev];
		if(IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client) && (H_waiting_start[prev] || H_waiting_repeat[prev]))
		{
			wait_to_heal(client, get_halfway_time(prev));
		}
	}
}

Action on_sound_shove(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if(!(O_interrupt & INTERRUPT_SHOVE))
	{
		return Plugin_Continue;
	}
	if(entity > 0 && entity <= MaxClients && GetClientTeam(entity) == 2 && IsPlayerAlive(entity) && is_survivor_alright(entity) && lower_than_heal_max(entity) && channel == SNDCHAN_ITEM && strncmp(sample, SOUND_SHOVE, Strlen_shove, false) == 0)
	{
		wait_to_heal(entity, O_wait_time);
	}
	return Plugin_Continue;
}

void get_cvars()
{
	O_buffer_decay_rate = C_buffer_decay_rate.FloatValue;
	O_pain_pills_health_value = C_pain_pills_health_value.FloatValue;
	O_adrenaline_health_buffer = C_adrenaline_health_buffer.FloatValue;
	O_interrupt = C_interrupt.IntValue;
	O_wait_time = C_wait_time.FloatValue;
	O_health = C_health.FloatValue;
	O_max = C_max.FloatValue;
	O_repeat_interval = C_repeat_interval.FloatValue;
	O_survivor_max_health = C_survivor_max_health.FloatValue;
	O_medicine = C_medicine.IntValue;

	O_max_round_to_floor = float(RoundToFloor(O_max));
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

public void OnPluginStart()
{
	Strlen_shove = strlen(SOUND_SHOVE);

	AddNormalSoundHook(on_sound_shove);

	HookEvent("round_start", event_round_start);
	HookEvent("player_hurt", event_player_hurt);
	HookEvent("weapon_fire", event_weapon_fire);
    HookEvent("pills_used", event_pills_used);
    HookEvent("adrenaline_used", event_adrenaline_used);
	HookEvent("heal_success", event_heal_success);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	C_buffer_decay_rate = FindConVar("pain_pills_decay_rate");
	C_pain_pills_health_value = FindConVar("pain_pills_health_value");
	C_adrenaline_health_buffer = FindConVar("adrenaline_health_buffer");
	C_interrupt = CreateConVar("automatic_healing_interrupt", "249", "which case(s) will interrupt healing? 1 = get hurt, 2 = primary attack, 4 = shove, 8 = get staggered, 16 = pinned by special infected, 32 = striked fly, 64 = standing up, 128 = falling from ledge. add numbers together", _, true, 0.0, true, 255.0);
	C_wait_time = CreateConVar("automatic_healing_wait_time", "5.0", "how long time need to wait after interruption to start healing", _, true, 0.1);
	C_health = CreateConVar("automatic_healing_health", "1.0", "how many health buffer heal once", _, true, 0.1);
	C_repeat_interval = CreateConVar("automatic_healing_repeat_interval", "0.1", "repeat interval after healing start", _, true, 0.1);
	C_max = CreateConVar("automatic_healing_max", "30.2", "max health of healing", _, true, 1.1);
	C_survivor_max_health = CreateConVar("automatic_healing_survivor_max_health", "100.0", "when \"automatic_healing_medicine\" works, health buffer more than this value will be removed", _, true, 1.0);
	C_medicine = CreateConVar("automatic_healing_medicine", "7", "0 = disable, 1 = pain pills will start healing from \"automatic_healing_max\", 2 = adrenaline will start healing from \"automatic_healing_max\", 4 = after using first aid kit, instantly heal to \"automatic_healing_max\". add numbers together", _, true, 0.0, true, 7.0);

	CreateConVar("automatic_healing_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

	C_buffer_decay_rate.AddChangeHook(convar_changed);
	C_pain_pills_health_value.AddChangeHook(convar_changed);
	C_adrenaline_health_buffer.AddChangeHook(convar_changed);
	C_interrupt.AddChangeHook(convar_changed);
	C_wait_time.AddChangeHook(convar_changed);
	C_health.AddChangeHook(convar_changed);
	C_repeat_interval.AddChangeHook(convar_changed);
	C_max.AddChangeHook(convar_changed);
	C_survivor_max_health.AddChangeHook(convar_changed);
	C_medicine.AddChangeHook(convar_changed);

	AutoExecConfig(true, "automatic_healing");
}