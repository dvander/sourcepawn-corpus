#define PLUGIN_VERSION	"1.13"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
forward void GearTransfer_OnWeaponGive(int client, int target, int item);
forward void GearTransfer_OnWeaponGrab(int client, int target, int item);
forward void GearTransfer_OnWeaponSwap(int client, int target, int itemGiven, int itemTaken);

public Plugin myinfo =
{
	name = "Weapon Give No Auto Switch",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=341173"
};

bool Given[MAXPLAYERS+1];

void reset_player(int client)
{
	Given[client] = false;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client);
}

Action OnWeaponSwitch(int client, int weapon)
{
	if(Given[client])
	{
		reset_player(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void remove_given_mark(int client, int item)
{
	if(!Given[client])
	{
		return;
	}
	char class_name[64];
	GetEntityClassname(item, class_name, sizeof(class_name));
	if(strcmp(class_name, "weapon_pain_pills") == 0 || strcmp(class_name, "weapon_adrenaline") == 0)
	{
		reset_player(client);
	}	
}

public void GearTransfer_OnWeaponGive(int client, int target, int item)
{
	remove_given_mark(target, item);
}

public void GearTransfer_OnWeaponGrab(int client, int target, int item)
{
	if(target > 0)
	{
		remove_given_mark(client, item);
	}
}

public void GearTransfer_OnWeaponSwap(int client, int target, int itemGiven, int itemTaken)
{
	remove_given_mark(client, itemTaken);
	remove_given_mark(target, itemGiven);
}

void event_weapon_given(Event event, const char[] name, bool dontBroadcast)
{
	int id = event.GetInt("weapon");
	if(id != 15 && id != 23)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && !Given[client] && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		Given[client] = true;
	}
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
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
		reset_player(client);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
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
    HookEvent("weapon_given", event_weapon_given);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);

    CreateConVar("weapon_give_no_auto_switch_version", PLUGIN_VERSION, "version of Weapon Give No Auto Switch", FCVAR_NOTIFY | FCVAR_DONTRECORD); 

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	} 
}
