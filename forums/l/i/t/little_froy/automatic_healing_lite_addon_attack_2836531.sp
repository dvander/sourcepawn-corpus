#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <automatic_healing_lite>
#include <left4dhooks>

#define INTERRUPT_PRIMARY_ATTACK		(1 << 0)
#define INTERRUPT_SHOVE					(1 << 1)

public Plugin myinfo =
{
	name = "Automatic Healing Lite Addon Interrupt Healing On Attack",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=350951"
};

enum CHAINSAW_STATE
{
    CHAINSAW_STATE_INACTIVE = 0,
    CHAINSAW_STATE_STARTUP = 1,
    CHAINSAW_STATE_IDLE	= 2,
    CHAINSAW_STATE_ACTIVE =	3
};

int Offset_m_iState;

ConVar C_enable;
int O_enable;

bool Started;

public void AutomaticHealingLite_OnGameStart()
{
	Started = true;
}

public void AutomaticHealingLite_OnGameEnd()
{
	Started = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!Started || !(O_enable & INTERRUPT_PRIMARY_ATTACK))
	{
		return;
	}
	if(entity < 1)
	{
		return;
	}
	if(strcmp(classname, "molotov_projectile") == 0 || strcmp(classname, "pipe_bomb_projectile") == 0 || strcmp(classname, "vomitjar_projectile") == 0) 
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_projectile);
	}
}

void OnSpawnPost_projectile(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		AutomaticHealingLite_WaitToHeal(client);
	}
}

public void L4D_OnSwingStart(int client, int weapon)
{
	if(!Started || !(O_enable & INTERRUPT_SHOVE))
	{
		return;
	}
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		AutomaticHealingLite_WaitToHeal(client);
	}
}

void event_weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started || !(O_enable & INTERRUPT_PRIMARY_ATTACK))
	{
		return;
	}
	int weaponid = event.GetInt("weaponid");
	switch(weaponid)
	{
		case 15, 23, 13, 14, 25, 16, 17, 18, 27, 28, 29:
		{
			return;
		}
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		if(weaponid == 20)
		{
			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(active == -1)
			{
				return;
			}
			char class_name[64];
			GetEntityClassname(active, class_name, sizeof(class_name));
			if(strcmp(class_name, "weapon_chainsaw") != 0)
			{
				return;
			}
			if(view_as<CHAINSAW_STATE>(GetEntData(active, Offset_m_iState)) < CHAINSAW_STATE_IDLE)
			{
				return;
			}
		}
		AutomaticHealingLite_WaitToHeal(client);
	}
}

void get_all_cvars()
{
	O_enable = C_enable.IntValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_enable)
	{
		O_enable = C_enable.IntValue;
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
	Offset_m_iState = FindSendPropInfo("CChainsaw", "m_bHitting") - 4;

	HookEvent("weapon_fire", event_weapon_fire);

	C_enable = CreateConVar("automatic_healing_lite_addon_attack_enable", "3", "which type of attack will interrupt healing? 1 = primary attack, 2 = shove. add numbers together");
	C_enable.AddChangeHook(convar_changed);
	CreateConVar("automatic_healing_lite_addon_attack_version", PLUGIN_VERSION, "version of Automatic Healing Lite Addon Interrupt Healing On Attack", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, "automatic_healing_lite_addon_attack");
	get_all_cvars();

	Started = AutomaticHealingLite_HasGameStart();
}
