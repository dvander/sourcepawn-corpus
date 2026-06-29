#define PLUGIN_VERSION	"1.8"
#define PLUGIN_NAME		"Weapon Give No Auto Switch"
#define PLUGIN_PREFIX	"weapon_give_no_auto_switch"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
forward void GearTransfer_OnWeaponGive(int client, int target, int item);
forward void GearTransfer_OnWeaponGrab(int client, int target, int item);
forward void GearTransfer_OnWeaponSwap(int client, int target, int itemGiven, int itemTaken);

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=341173"
};

Action on_weapon_switch(int client, int weapon)
{
	SDKUnhook(client, SDKHook_WeaponSwitch, on_weapon_switch);
	return Plugin_Handled;
}

void unhook_weapon_switch(int client, int item)
{
	char class_name[PLATFORM_MAX_PATH];
	GetEntityClassname(item, class_name, sizeof(class_name));
	if(strcmp(class_name, "weapon_pain_pills") == 0 || strcmp(class_name, "weapon_adrenaline") == 0)
	{
		SDKUnhook(client, SDKHook_WeaponSwitch, on_weapon_switch);
	}	
}

public void GearTransfer_OnWeaponGive(int client, int target, int item)
{
	unhook_weapon_switch(target, item);
}

public void GearTransfer_OnWeaponGrab(int client, int target, int item)
{
	unhook_weapon_switch(client, item);
}

public void GearTransfer_OnWeaponSwap(int client, int target, int itemGiven, int itemTaken)
{
	unhook_weapon_switch(client, itemTaken);
	unhook_weapon_switch(target, itemGiven);
}

void event_weapon_given(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
        switch(event.GetInt("weapon"))
        {
            case 15, 23:
                SDKHook(client, SDKHook_WeaponSwitch, on_weapon_switch);
        }
	}
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_WeaponSwitch, on_weapon_switch);
	}
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
		if(IsClientInGame(client))
		{
			SDKUnhook(client, SDKHook_WeaponSwitch, on_weapon_switch);
		}
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_WeaponSwitch, on_weapon_switch);
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

    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);    
}