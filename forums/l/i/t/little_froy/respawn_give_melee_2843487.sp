#define PLUGIN_VERSION	"1.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <little_froy_utils>

public Plugin myinfo =
{
	name = "Respawn Give Melee",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352457"
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

ConVar C_enable_rescue;
bool O_enable_rescue;
ConVar C_enable_defib;
bool O_enable_defib;
ConVar C_melee_filter;
ArrayList O_melee_filter;
ConVar C_remove_previous;
bool O_remove_previous;

ArrayList Melees;
ArrayList Melee_to_give;

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

void give_melee(int client)
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
		if(O_remove_previous)
		{
			RemovePlayerItem(client, weapon);
			RemoveEntity(weapon);
		}
	}
	char name[64];
	Melee_to_give.GetString(GetRandomInt(0, Melee_to_give.Length - 1), name, sizeof(name));
	GivePlayerItem(client, name);
	if(prev[0] != '\0')
	{
		FakeClientCommand(client, "use %s", prev);
	}
}

void check_give(int client)
{
    if(Melee_to_give && Melee_to_give.Length > 0 && client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client))
    {
        give_melee(client);
    }
}

void event_survivor_rescued(Event event, const char[] name, bool dontBroadcast)
{
    if(!O_enable_rescue)
    {
        return;
    }
    check_give(GetClientOfUserId(event.GetInt("victim")));
}

void event_defibrillator_used(Event event, const char[] name, bool dontBroadcast)
{
    if(!O_enable_defib)
    {
        return;
    }
    check_give(GetClientOfUserId(event.GetInt("subject")));
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
    O_enable_rescue = C_enable_rescue.BoolValue;
    O_enable_defib = C_enable_defib.BoolValue;
	O_melee_filter.Clear();
	char buffer[2048];
	C_melee_filter.GetString(buffer, sizeof(buffer));
	if(buffer[0] != '\0')
	{
		explode_string_to_list(buffer, ",", O_melee_filter, 64, StringExplodeType_String);
	}
	O_remove_previous = C_remove_previous.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_enable_rescue)
    {
        O_enable_rescue = C_enable_rescue.BoolValue;
    }
    else if(convar == C_enable_defib)
    {
        O_enable_defib = C_enable_defib.BoolValue;
    }
	else if(convar == C_melee_filter)
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
	else if(convar == C_remove_previous)
	{
		O_remove_previous = C_remove_previous.BoolValue;
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
	Melees = new ArrayList(ByteCountToCells(64));
	O_melee_filter = new ArrayList(ByteCountToCells(64));

    HookEvent("defibrillator_used", event_defibrillator_used);
    HookEvent("survivor_rescued", event_survivor_rescued);

    C_enable_rescue = CreateConVar("respawn_give_melee_enable_rescue", "1", "1 = enable, 0 = disable. enable give melee on rescue?");
    C_enable_rescue.AddChangeHook(convar_changed);
    C_enable_defib = CreateConVar("respawn_give_melee_enable_defib", "1", "1 = enable, 0 = disable. enable give melee on defib?");
    C_enable_defib.AddChangeHook(convar_changed);
	C_melee_filter = CreateConVar("respawn_give_melee_filter", "pitchfork", "filter these melees. split up with \",\"");
	C_melee_filter.AddChangeHook(convar_changed);
	C_remove_previous = CreateConVar("respawn_give_melee_remove_previous", "0", "1 = enable, 0 = disable. remove previous secondary weapon?");
	C_remove_previous.AddChangeHook(convar_changed);
	CreateConVar("respawn_give_melee_version", PLUGIN_VERSION, "version of Respawn Give Melee", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "respawn_give_melee");
    get_all_cvars();
}