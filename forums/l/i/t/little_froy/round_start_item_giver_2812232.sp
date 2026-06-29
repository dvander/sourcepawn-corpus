#define PLUGIN_VERSION	"4.10"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <little_froy_utils>

#define LITTLE_FROY_INTEGER_MAX	0x7FFFFFFF

#define ROUND_START_ITEM_DISTINCT_IF_SAME	1
#define ROUND_START_ITEM_DISTINCT_IF_EXIST	2

public Plugin myinfo =
{
	name = "Round Start Item Giver",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340158"
};

ConVar C_items[5];
ArrayList O_items[5];
ConVar C_distinct[5];
int O_distinct[5];
ConVar C_delay;
float O_delay;

int G_give_id = -1;
int Give_id[MAXPLAYERS+1] = {-1, ...};
Handle H_give[MAXPLAYERS+1];
bool First_time[MAXPLAYERS+1];
ArrayList Used_timer;

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
}

bool get_target_item(int client, int i, char buffer[64])
{
	if(O_items[i].Length == 0)
	{
		return false;
	}
	if(O_distinct[i] == 0)
	{
		O_items[i].GetString(GetRandomInt(0, O_items[i].Length - 1), buffer, sizeof(buffer));
		return true;
	}
	int weapon = GetPlayerWeaponSlot(client, i);
	if(weapon == -1)
	{
		O_items[i].GetString(GetRandomInt(0, O_items[i].Length - 1), buffer, sizeof(buffer));
		return true;
	}
	if(O_distinct[i] == ROUND_START_ITEM_DISTINCT_IF_EXIST)
	{
		return false;
	}
	char temp[64];
	char name_equiped[64];
	O_items[i].GetString(GetRandomInt(0, O_items[i].Length - 1), temp, sizeof(temp));
	GetEntityClassname(weapon, name_equiped, sizeof(name_equiped));
	if(strcmp(name_equiped, temp) == 0)
	{
		return false;
	}
	else
	{
		strcopy(buffer, sizeof(buffer), temp);
		return true;
	}
}

void give_items(int client)
{
	for(int i = 0; i < 5; i++)
	{
		char item[64];
		if(get_target_item(client, i, item))
		{
			GivePlayerItem(client, item);
		}
	}
}

void reset_player(int client, bool first_time)
{
	First_time[client] = first_time;
	Give_id[client] = -1;
	H_give[client] = null;
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client, true);
}

void check_give(int client)
{
	if(First_time[client] && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		First_time[client] = false;
		give_items(client);
	}
}

void next_frame(int id)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(id == Give_id[client])
		{
			Give_id[client] = -1;
			check_give(client);
		}
	}
}

void timer_give(Handle timer)
{
    int idx = Used_timer.FindValue(timer);
    if(idx != -1)
    {
        Used_timer.Erase(idx);
    }
	for(int client = 1; client <= MaxClients; client++)
	{
		if(timer == H_give[client])
		{
			H_give[client] = null;
			check_give(client);
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
			G_give_id++;
			if(G_give_id == LITTLE_FROY_INTEGER_MAX)
			{
				G_give_id = 0;
			}
			Give_id[client] = G_give_id;
			RequestFrame(next_frame, G_give_id);
		}
		else
		{
			for(int i = 0; i < Used_timer.Length; i++)
			{
				Handle timer = Used_timer.Get(i);
				bool got = false;
				for(int j = 1; j <= MaxClients; j++)
				{
					if(timer == H_give[j])
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
			H_give[client] = CreateTimer(O_delay, timer_give);
			Used_timer.Push(H_give[client]);
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
			reset_player(client, false);
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
	Give_id[client] = Give_id[prev];
	H_give[client] = H_give[prev];
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

void get_all_cvars()
{
	char buffer[2048];
	for(int i = 0; i < 5; i++)
	{
		O_items[i].Clear();
		C_items[i].GetString(buffer, sizeof(buffer));
		if(buffer[0] != '\0')
		{
			explode_string_to_list(buffer, ",", O_items[i], 64, StringExplodeType_String);
		}
		O_distinct[i] = C_distinct[i].IntValue;
	}
	O_delay = C_delay.FloatValue;
}

void get_single_cvar(ConVar convar)
{
	for(int i = 0; i < 5; i++)
	{
		if(convar == C_items[i])
		{
			O_items[i].Clear();
			char buffer[2048];
			C_items[i].GetString(buffer, sizeof(buffer));
			if(buffer[0] != '\0')
			{
				explode_string_to_list(buffer, ",", O_items[i], 64, StringExplodeType_String);
			}
			return;
		}
		if(convar == C_distinct[i])
		{
			O_distinct[i] = C_distinct[i].IntValue;
			return;
		}
	}
	if(convar == C_delay)
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
	for(int i = 0; i < 5; i++)
	{
		O_items[i] = new ArrayList(ByteCountToCells(64));
	}

	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	C_items[0] = CreateConVar("round_start_item_giver_items0", "", "give one of these items for slot0, split up with \",\". leave empty to disable");
	C_items[0].AddChangeHook(convar_changed);
	C_items[1] = CreateConVar("round_start_item_giver_items1", "", "give one of these items for slot1, split up with \",\". leave empty to disable");
	C_items[1].AddChangeHook(convar_changed);
	C_items[2] = CreateConVar("round_start_item_giver_items2", "", "give one of these items for slot2, split up with \",\". leave empty to disable");
	C_items[2].AddChangeHook(convar_changed);
	C_items[3] = CreateConVar("round_start_item_giver_items3", "weapon_first_aid_kit", "give one of these items for slot3, split up with \",\". leave empty to disable");
	C_items[3].AddChangeHook(convar_changed);
	C_items[4] = CreateConVar("round_start_item_giver_items4", "weapon_pain_pills", "give one of these items for slot4, split up with \",\". leave empty to disable");
	C_items[4].AddChangeHook(convar_changed);
	C_distinct[0] = CreateConVar("round_start_item_giver_distinct0", "0", "items distinct for slot0, 0 = disable, 1 = ignore if the slot already has the same item, 2 = ignore if the slot already has any item", _, true, 0.0, true, 2.0);
	C_distinct[0].AddChangeHook(convar_changed);
	C_distinct[1] = CreateConVar("round_start_item_giver_distinct1", "0", "items distinct for slot1, 0 = disable, 1 = ignore if the slot already has the same item, 2 = ignore if the slot already has any item", _, true, 0.0, true, 2.0);
	C_distinct[1].AddChangeHook(convar_changed);
	C_distinct[2] = CreateConVar("round_start_item_giver_distinct2", "0", "items distinct for slot2, 0 = disable, 1 = ignore if the slot already has the same item, 2 = ignore if the slot already has any item", _, true, 0.0, true, 2.0);
	C_distinct[2].AddChangeHook(convar_changed);
	C_distinct[3] = CreateConVar("round_start_item_giver_distinct3", "1", "items distinct for slot3, 0 = disable, 1 = ignore if the slot already has the same item, 2 = ignore if the slot already has any item", _, true, 0.0, true, 2.0);
	C_distinct[3].AddChangeHook(convar_changed);
	C_distinct[4] = CreateConVar("round_start_item_giver_distinct4", "1", "items distinct for slot4, 0 = disable, 1 = ignore if the slot already has the same item, 2 = ignore if the slot already has any item", _, true, 0.0, true, 2.0);
	C_distinct[4].AddChangeHook(convar_changed);
	C_delay = CreateConVar("round_start_item_giver_delay", "-1.0", "delay to give item. lower than 0.1 = only delay 1 frame");
	C_delay.AddChangeHook(convar_changed);
	CreateConVar("round_start_item_giver_version", PLUGIN_VERSION, "version of Round Start Item Giver", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "round_start_item_giver");
	get_all_cvars();
	
	for(int client = 1; client <= MAXPLAYERS; client++)
	{
		if(client > MaxClients || !IsClientInGame(client))
		{
			First_time[client] = true;
		}
	}
}
