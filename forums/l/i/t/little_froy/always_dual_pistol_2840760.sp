#define PLUGIN_VERSION	"1.4"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define LITTLE_FROY_INTEGER_MAX	0x7FFFFFFF

public Plugin myinfo =
{
	name = "Always Dual Pistol",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351839"
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

ConVar C_exclude_incap;
bool O_exclude_incap;

int G_give_id = -1;
int Give_id[MAXPLAYERS+1] = {-1, ...};

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity < 1)
	{
		return;
	}
	if(strcmp(classname, "weapon_pistol") == 0 || strcmp(classname, "weapon_pistol_spawn") == 0)
	{
		SDKHook(entity, SDKHook_Use, OnUse_weapon_pistol);
	}
	else if(strcmp(classname, "weapon_spawn") == 0)
	{
		SDKHook(entity, SDKHook_Use, OnUse_weapon_spawn);
	}
}

Action OnUse_weapon_pistol(int entity, int activator, int caller, UseType type, float value)
{
	if(activator > 0 && activator <= MaxClients && IsClientInGame(activator) && GetClientTeam(activator) == 2 && has_single_pistol(activator) != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action OnUse_weapon_spawn(int entity, int activator, int caller, UseType type, float value)
{
	if(GetEntProp(entity, Prop_Data, "m_weaponID") == 1 && activator > 0 && activator <= MaxClients && IsClientInGame(activator) && GetClientTeam(activator) == 2 && has_single_pistol(activator) != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool is_player_hanging(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_player_down(int client)
{
	return !is_player_alright(client) && !is_player_hanging(client);
}

void reset_player(int client)
{
    Give_id[client] = -1;
}

int has_single_pistol(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 1);
	if(weapon == -1)
	{
		return -1;
	}
	char class_name[64];
	GetEntityClassname(weapon, class_name, sizeof(class_name));
	if(strcmp(class_name, "weapon_pistol") == 0 && !GetEntProp(weapon, Prop_Send, "m_hasDualWeapons"))
	{
		return weapon;
	}
    return -1;
}

void give_pistol(int client)
{
	int weapon = has_single_pistol(client);
	if(weapon == -1)
	{
		return;
	}
	char prev[64];
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
	GivePlayerItem(client, "weapon_pistol");
	if(prev[0] != '\0')
	{
		FakeClientCommand(client, "use %s", prev);
	}
}

void next_frame(int id)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(id == Give_id[client])
        {
            reset_player(client);
            if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
            {
				give_pistol(client);
            }
        }
    }
}

void start_check(int client)
{
	G_give_id++;
	if(G_give_id == LITTLE_FROY_INTEGER_MAX)
	{
		G_give_id = 0;
	}
	Give_id[client] = G_give_id;
	RequestFrame(next_frame, G_give_id);
}

void OnWeaponEquipPost(int client, int weapon)
{
    if(weapon == -1 || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || (O_exclude_incap && is_player_down(client)))
    {
        return;
    }
    char class_name[64];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    if(strcmp(class_name, "weapon_pistol") == 0)
    {
		start_check(client);
    }
}

Action OnWeaponDrop(int client, int weapon)
{
    if(weapon == -1)
    {
        return Plugin_Continue;
    }
    char class_name[64];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    if(strcmp(class_name, "weapon_pistol") == 0)
    {
		reset_player(client);
        SetEntProp(weapon, Prop_Send, "m_isDualWielding", 0);
        SetEntProp(weapon, Prop_Send, "m_hasDualWeapons", 0);
    }
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
    SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public void OnClientDisconnect_Post(int client)
{
    reset_player(client);
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		if(IsFakeClient(client) && event.GetInt("team") == 1 && event.GetInt("oldteam") == 2)
		{
			return;
		}
		reset_player(client);
	}
}

void data_trans(int client, int prev)
{
	Give_id[client] = Give_id[prev];
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
	O_exclude_incap = C_exclude_incap.BoolValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_exclude_incap)
	{
		O_exclude_incap = C_exclude_incap.BoolValue;
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
    HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_exclude_incap = CreateConVar("always_dual_pistol_exclude_incap", "1", "1 = enable, 0 = disable. exclude incapacitated? commonly used by when you be incapacitated with a melee");
    C_exclude_incap.AddChangeHook(convar_changed);
	CreateConVar("always_dual_pistol_version", PLUGIN_VERSION, "version of Always Dual Pistol", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "always_dual_pistol");
	get_all_cvars();

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "weapon_pistol")) != -1)
	{
		SDKHook(entity, SDKHook_Use, OnUse_weapon_pistol);
	}
	while((entity = FindEntityByClassname(entity, "weapon_pistol_spawn")) != -1)
	{
		SDKHook(entity, SDKHook_Use, OnUse_weapon_pistol);
	}
	while((entity = FindEntityByClassname(entity, "weapon_spawn")) != -1)
	{
		SDKHook(entity, SDKHook_Use, OnUse_weapon_spawn);
	}
}
