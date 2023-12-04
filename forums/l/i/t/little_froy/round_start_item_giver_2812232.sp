#define PLUGIN_VERSION	"2.1"
#define PLUGIN_NAME		"Round Start Item Giver"
#define PLUGIN_PREFIX	"round_start_item_giver"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340158"
};

bool Late_load;

KeyValues Slot_and_weapon;

char Data_path[PLATFORM_MAX_PATH];

bool First_time[MAXPLAYERS+1];

void give_items(int client)
{
	static const char slots[5][16] = {"slot0", "slot1", "slot2", "slot3", "slot4"};
	for(int i = 0; i < 5; i++)
	{
		Slot_and_weapon.Rewind();
		if(Slot_and_weapon.JumpToKey(slots[i]) && Slot_and_weapon.GetNum("enable", 0))
		{
			char item[PLATFORM_MAX_PATH];
			Slot_and_weapon.GetString("class_name", item, sizeof(item));
			bool should_give = false;
			if(!Slot_and_weapon.GetNum("distinct", 0))
			{
				should_give = true;
			}
			else
			{
				int weapon = GetPlayerWeaponSlot(client, i);
				if(weapon == -1)
				{
					should_give = true;
				}
				else
				{
					char class_name[PLATFORM_MAX_PATH];
					GetEntityClassname(weapon, class_name, sizeof(class_name));
					if(strcmp(class_name, item) != 0)
					{
						should_give = true;
					}
				}
			}
			if(should_give)
			{
				GivePlayerItem(client, item);
			}
		}
	}
}

public void OnClientDisconnect_Post(int client)
{
	First_time[client] = true;
}

void next_frame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client != 0 && First_time[client] && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		First_time[client] = false;
		give_items(client);
	}
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(next_frame, event.GetInt("userid"));
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		if(IsFakeClient(client) && event.GetInt("team") == 1 && event.GetInt("oldteam") == 2)
		{
			return;
		}
		First_time[client] = true;
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		First_time[client] = false;
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
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("player"));
		if(prev != 0)
		{
			data_trans(client, prev);
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("bot"));
		if(prev != 0)
		{
			data_trans(client, prev);
		}
	}
}

void load_items()
{
	delete Slot_and_weapon;
	Slot_and_weapon = new KeyValues(PLUGIN_PREFIX);
    if(FileExists(Data_path))
    {
		Slot_and_weapon.ImportFromFile(Data_path);
    }
}

Action cmd_reload(int client, int argc)
{
	load_items();
	return Plugin_Handled;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    Late_load = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
	BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/%s.cfg", PLUGIN_PREFIX);

    load_items();

    RegAdminCmd("sm_" ... PLUGIN_PREFIX ... "_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");

	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	if(Late_load)
	{
		for(int client = 1; client <= MAXPLAYERS; client++)
		{
			if(client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
			{
				First_time[client] = true;
			}
		}
	}
}