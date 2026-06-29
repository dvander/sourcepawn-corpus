#define PLUGIN_VERSION	"1.5"
#define PLUGIN_NAME		"Automatic Healing Addon Interrupt Healing On Attack"
#define PLUGIN_PREFIX	"automatic_healing_addon_attack"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <automatic_healing>

#define INTERRUPT_PRIMARY_ATTACK		(1 << 0)
#define INTERRUPT_SHOVE					(1 << 1)

#define SOUND_CHAINSAW_DEPLOYING	")weapons/chainsaw/chainsaw_start_0"
#define SOUND_CHAINSAW_DEPLOY_DONE	")weapons/chainsaw/chainsaw_idle_lp_01.wav"
#define SOUND_SHOVE					")player/survivor/swing/swish_weaponswing_swipe"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=342782"
};

ConVar C_enable;
int O_enable;

int Strlen_shove;
int Strlen_deploying_chainsaw;

bool Late_load;

bool Deploying_chainsaw[MAXPLAYERS+1];

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

public void OnClientDisconnect_Post(int client)
{
	Deploying_chainsaw[client] = true;
}

void on_weapon_switch_post(int client, int weapon)
{
	if(weapon == -1)
	{
		return;
	}
	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != weapon)
	{
		Deploying_chainsaw[client] = true;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, on_weapon_switch_post);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!(O_enable & INTERRUPT_PRIMARY_ATTACK))
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
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
	{
		AutomaticHealing_WaitToHeal(client);
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MAXPLAYERS; client++)
	{
		Deploying_chainsaw[client] = true;
	}
}

void event_weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_enable & INTERRUPT_PRIMARY_ATTACK))
	{
		return;
	}
	int weaponid = event.GetInt("weaponid");
	switch(weaponid)
	{
		case 15, 23, 13, 14, 25, 16, 17, 18, 27, 28, 29:
			return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && (weaponid != 20 || !Deploying_chainsaw[client]) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
	{
		AutomaticHealing_WaitToHeal(client);
	}
}

Action on_sound_shove(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if(!(O_enable & INTERRUPT_SHOVE))
	{
		return Plugin_Continue;
	}
	if(channel == SNDCHAN_ITEM && entity > 0 && entity <= MaxClients && IsClientInGame(entity) && GetClientTeam(entity) == 2 && IsPlayerAlive(entity) && is_survivor_alright(entity) && strncmp(sample, SOUND_SHOVE, Strlen_shove, false) == 0)
	{
		AutomaticHealing_WaitToHeal(entity);
	}
	return Plugin_Continue;
}

Action on_sound_chainsaw(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
    if(entity > MaxClients)
    {
        char class_name[PLATFORM_MAX_PATH];
        GetEntityClassname(entity, class_name, sizeof(class_name));
        if(strcmp(class_name, "weapon_chainsaw") == 0)
        {
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner > 0 && owner <= MaxClients && IsClientInGame(owner) && GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon") == entity)
			{
				if(channel == SNDCHAN_WEAPON && strncmp(sample, SOUND_CHAINSAW_DEPLOYING, Strlen_deploying_chainsaw, false) == 0)
				{
					Deploying_chainsaw[owner] = true;
				}
				else if(channel == SNDCHAN_ITEM && strcmp(sample, SOUND_CHAINSAW_DEPLOY_DONE, false) == 0)
				{
					Deploying_chainsaw[owner] = false;
				}
			}
		}
    }
	return Plugin_Continue;
}

void get_cvars()
{
	O_enable = C_enable.IntValue;
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
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
	Strlen_shove = strlen(SOUND_SHOVE);
	Strlen_deploying_chainsaw = strlen(SOUND_CHAINSAW_DEPLOYING);

	AddNormalSoundHook(on_sound_shove);
	AddNormalSoundHook(on_sound_chainsaw);

	HookEvent("round_start", event_round_start);
	HookEvent("weapon_fire", event_weapon_fire);

	C_enable = CreateConVar(PLUGIN_PREFIX ... "_enable", "3", "which type of attack will interrupt healing? 1 = primary attack, 2 = shove. add numbers together", _, true, 0.0, true, 3.0);
	C_enable.AddChangeHook(convar_changed);
	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, PLUGIN_PREFIX);
	get_cvars();

    if(Late_load)
    {
        for(int client = 1; client <= MAXPLAYERS; client++)
        {
			if(client <= MaxClients && IsClientInGame(client))
			{
				OnClientPutInServer(client);
				int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(active != -1)
				{
					char class_name[PLATFORM_MAX_PATH];
					GetEntityClassname(active, class_name, sizeof(class_name));
					if(strcmp(class_name, "weapon_chainsaw") != 0)
					{
						Deploying_chainsaw[client] = true;
					}
				}
			}
			else
			{
				Deploying_chainsaw[client] = true;
			}
        }
    }
}