#define PLUGIN_VERSION	"2.3"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <little_froy_utils>

#define LITTLE_FROY_INTEGER_MAX	0x7FFFFFFF

public Plugin myinfo =
{
	name = "Level Start Melee",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351687"
};

static const char Hold_items[][64] = 
{
	"weapon_propanetank",
    "weapon_fireworkcrate",
    "weapon_gascan",
    "weapon_oxygentank",
    "weapon_cola_bottles",
    "weapon_gnome"
};

bool Got_config;

ConVar C_melee_filter;
ArrayList O_melee_filter;
ConVar C_glow_type;
int O_glow_type;
ConVar C_glow_range;
int O_glow_range;
ConVar C_glow_range_min;
int O_glow_range_min;
ConVar C_glow_color;
int O_glow_color[3];
ConVar C_glow_flash;
bool O_glow_flash;
ConVar C_bot_no_drop;
bool O_bot_no_drop;
ConVar C_delay;
float O_delay;

ArrayList Melees;
ArrayList Melee_to_give;
ArrayList Glow_melees;

int G_spawn_id = -1;
int Spawn_id[MAXPLAYERS+1] = {-1, ...};
bool First_time[MAXPLAYERS+1];
Handle H_spawn[MAXPLAYERS+1];
ArrayList Used_timer;

public void OnMapStart()
{
	int table = FindStringTable("meleeweapons");
	if(table != INVALID_STRING_TABLE)
	{
		int num = GetStringTableNumStrings(table);
		for(int i = 0; i < num; i++)
		{
			char name[64];
			ReadStringTable(table, i, name, sizeof(name));
			Melees.PushString(name);
		}
	}
	if(Got_config)
	{
		filter_melee();
	}
}

public void OnMapEnd()
{
	Melees.Clear();
	delete Melee_to_give;
	Glow_melees.Clear();
}

public void OnEntityDestroyed(int entity)
{
	if(entity < 1)
	{
		return;
	}
	int idx = Glow_melees.FindValue(EntIndexToEntRef(entity));
	if(idx != -1)
	{
		Glow_melees.Erase(idx);
	}
}

void filter_melee()
{
	delete Melee_to_give;
	Melee_to_give = Melees.Clone();
	for(int i = 0; i < O_melee_filter.Length; i++)
	{
		char name[64];
		O_melee_filter.GetString(i, name, sizeof(name));
		int index = -1;
		while((index = Melee_to_give.FindString(name)) != -1)
		{
			Melee_to_give.Erase(index);
		}
	}
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

void set_glow(int entity, int type = 0, const int color[3] = {0, 0, 0}, int range = 0, int range_min = 0, bool flash = false)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", type);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", color[0] + color[1] * 256 + color[2] * 65536);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", range_min);
    SetEntProp(entity, Prop_Send, "m_bFlashing", flash ? 1 : 0);
}

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
}

void reset_player(int client, bool first_time)
{
	First_time[client] = first_time;
	Spawn_id[client] = -1;
	H_spawn[client] = null;
}

void OnWeaponEquipPost(int client, int weapon)
{
    if(weapon == -1)
    {
        return;
    }
	int idx = Glow_melees.FindValue(EntIndexToEntRef(weapon));
	if(idx != -1)
	{
		Glow_melees.Erase(idx);
		set_glow(weapon);
	}
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client, true);
}

void spawn_melee(int client)
{
	char prev[64];
	int weapon = GetPlayerWeaponSlot(client, 1);
	if(weapon != -1)
	{
		int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(active != -1 && active != weapon)
		{
			char now[64];
			GetEntityClassname(active, now, sizeof(now));
			bool hold = false;
			for(int i = 0; i < sizeof(Hold_items); i++)
			{
				if(strcmp(now, Hold_items[i]) == 0)
				{
					hold = true;
					int last = GetEntPropEnt(client, Prop_Send, "m_hLastWeapon");
					if(last != -1 && last != weapon)
					{
						GetEntityClassname(last, prev, sizeof(prev));
					}
					break;
				}
			}
			if(!hold)
			{
				strcopy(prev, sizeof(prev), now);
			}
		}
	}
	char name[64];
	Melee_to_give.GetString(GetRandomInt(0, Melee_to_give.Length - 1), name, sizeof(name));
	if(O_bot_no_drop && IsFakeClient(client) && get_idled_of_bot(client) < 1 && is_player_alright(client))
	{
		GivePlayerItem(client, name);
	}
	else
	{
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon);
		}
		int item = GivePlayerItem(client, name);
		if(item != -1)
		{
			SDKHooks_DropWeapon(client, item, .vecVelocity = view_as<float>({0.0, 0.0, 0.0}));
			if(O_glow_type > 0)
			{
				Glow_melees.Push(EntIndexToEntRef(item));
				set_glow(item, O_glow_type, O_glow_color, O_glow_range, O_glow_range_min, O_glow_flash);
			}
		}
		if(weapon != -1)
		{
			EquipPlayerWeapon(client, weapon);
		}
	}
	if(prev[0] != '\0')
	{
		FakeClientCommand(client, "use %s", prev);
	}
}

void check_spawn(int client)
{
	if(First_time[client] && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		First_time[client] = false;
		if(Melee_to_give && Melee_to_give.Length > 0)
		{
			spawn_melee(client);
		}
	}
}

void next_frame(int id)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(id == Spawn_id[client])
		{
			Spawn_id[client] = -1;
			check_spawn(client);
		}
	}
}

void timer_spawn(Handle timer)
{
    int idx = Used_timer.FindValue(timer);
    if(idx != -1)
    {
        Used_timer.Erase(idx);
    }
	for(int client = 1; client <= MaxClients; client++)
	{
		if(timer == H_spawn[client])
		{
			H_spawn[client] = null;
			check_spawn(client);
		}
	}
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		if(O_delay < 0.1)
		{
			G_spawn_id++;
			if(G_spawn_id == LITTLE_FROY_INTEGER_MAX)
			{
				G_spawn_id = 0;
			}
			Spawn_id[client] = G_spawn_id;
			RequestFrame(next_frame, G_spawn_id);
		}
		else
		{
			for(int i = 0; i < Used_timer.Length; i++)
			{
				Handle timer = Used_timer.Get(i);
				bool got = false;
				for(int j = 1; j <= MaxClients; j++)
				{
					if(timer == H_spawn[j])
					{
						got = true;
						break;
					}
				}
				if(!got)
				{
					Used_timer.Erase(i--);
					delete timer;
				}
			}
			H_spawn[client] = CreateTimer(O_delay, timer_spawn);
			Used_timer.Push(H_spawn[client]);
		}
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client, false);
		int idled = get_idled_of_bot(client);
		if(idled > 0 && IsClientInGame(idled))
		{
			reset_player(idled, false);
		}
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MAXPLAYERS; client++)
	{
		First_time[client] = true;
	}
}

void data_trans(int client, int prev)
{
	First_time[client] = First_time[prev];
	Spawn_id[client] = Spawn_id[prev];
	H_spawn[client] = H_spawn[prev];
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(client > 0 && IsClientInGame(client))
	{
		int prev = GetClientOfUserId(event.GetInt("player"));
		if(prev > 0 && IsClientInGame(prev))
		{
			data_trans(client, prev);
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0 && IsClientInGame(client))
	{
		int prev = GetClientOfUserId(event.GetInt("bot"));
		if(prev > 0 && IsClientInGame(prev))
		{
			data_trans(client, prev);
		}
	}
}

public void OnConfigsExecuted()
{
	if(Got_config)
	{
		return;
	}
	Got_config = true;
	filter_melee();
}

void get_all_cvars()
{
	O_melee_filter.Clear();
	char buffer[2048];
	C_melee_filter.GetString(buffer, sizeof(buffer));
	if(buffer[0] != '\0')
	{
		explode_string_to_list(buffer, ",", O_melee_filter, 64, StringExplodeType_String);
	}
	O_glow_type = C_glow_type.IntValue;
	O_glow_range = C_glow_range.IntValue;
	O_glow_range_min = C_glow_range_min.IntValue;
	char str_color[12];
	C_glow_color.GetString(str_color, sizeof(str_color));
	explode_string_to_cell_array(str_color, " ", O_glow_color, sizeof(O_glow_color), 4, StringExplodeType_Int);
	O_glow_flash = C_glow_flash.BoolValue;
	O_bot_no_drop = C_bot_no_drop.BoolValue;
	O_delay = C_delay.FloatValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_melee_filter)
	{
		O_melee_filter.Clear();
		char buffer[2048];
		C_melee_filter.GetString(buffer, sizeof(buffer));
		if(buffer[0] != '\0')
		{
			explode_string_to_list(buffer, ",", O_melee_filter, 64, StringExplodeType_String);
		}
		if(Got_config)
		{
			filter_melee();
		}
	}
	else if(convar == C_glow_type)
	{
		O_glow_type = C_glow_type.IntValue;
	}
	else if(convar == C_glow_range)
	{
		O_glow_range = C_glow_range.IntValue;
	}
	else if(convar == C_glow_range_min)
	{
		O_glow_range_min = C_glow_range_min.IntValue;
	}
	else if(convar == C_glow_color)
	{
        char str_color[12];
        C_glow_color.GetString(str_color, sizeof(str_color));
        explode_string_to_cell_array(str_color, " ", O_glow_color, sizeof(O_glow_color), 4, StringExplodeType_Int);
	}
	else if(convar == C_glow_flash)
	{
		O_glow_flash = C_glow_flash.BoolValue;
	}
	else if(convar == C_bot_no_drop)
	{
		O_bot_no_drop = C_bot_no_drop.BoolValue;
	}
	else if(convar == C_delay)
	{
		O_delay = C_delay.FloatValue;
	}
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
	Used_timer = new ArrayList();
	Melees = new ArrayList(ByteCountToCells(64));
	O_melee_filter = new ArrayList(ByteCountToCells(64));
	Glow_melees = new ArrayList();

	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	C_melee_filter = CreateConVar("level_start_melee_filter", "pitchfork", "filter these melees. split up with \",\"");
	C_melee_filter.AddChangeHook(convar_changed);
	C_glow_type = CreateConVar("level_start_melee_glow_type", "2", "glow type. 0 = disable, 2 = visible only, 3 = through wall");
	C_glow_type.AddChangeHook(convar_changed);
	C_glow_range = CreateConVar("level_start_melee_glow_range", "600", "max visible range of glow. 0 = infinite", _, true, 0.0);
	C_glow_range.AddChangeHook(convar_changed);
	C_glow_range_min = CreateConVar("level_start_melee_glow_range_min", "0", "min range far away to visible the glow, 0 = no limit", _, true, 0.0);
	C_glow_range_min.AddChangeHook(convar_changed);
	C_glow_color = CreateConVar("level_start_melee_glow_color", "77 102 255", "glow color. split up with space");
	C_glow_color.AddChangeHook(convar_changed);
	C_glow_flash = CreateConVar("level_start_melee_glow_flash", "0", "1 = enable, 0 = disable. would the glow flash?");
	C_glow_flash.AddChangeHook(convar_changed);
	C_bot_no_drop = CreateConVar("level_start_melee_bot_no_drop", "0", "1 = enable, 0 = disable. bot won't drop given melee?(for increased \"sb_max_team_melee_weapons\")");
	C_bot_no_drop.AddChangeHook(convar_changed);
	C_delay = CreateConVar("level_start_melee_delay", "-1.0", "delay to spawn melee. lower than 0.1 = only delay 1 frame");
	C_delay.AddChangeHook(convar_changed);
	CreateConVar("level_start_melee_version", PLUGIN_VERSION, "version of Level Start Melee", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "level_start_melee");
    get_all_cvars();

	for(int client = 1; client <= MAXPLAYERS; client++)
	{
		if(client > MaxClients || !IsClientInGame(client))
		{
			First_time[client] = true;
		}
		else
		{
			OnClientPutInServer(client);
		}
	}
}