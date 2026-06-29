#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SPECIAL_SHOT_TARGET_COMMON  (1 << 0)
#define SPECIAL_SHOT_TARGET_WITCH   (1 << 1)
#define SPECIAL_SHOT_TARGET_SMOKER  (1 << 2)
#define SPECIAL_SHOT_TARGET_BOOMER  (1 << 3)
#define SPECIAL_SHOT_TARGET_HUNTER  (1 << 4)
#define SPECIAL_SHOT_TARGET_SPITTER (1 << 5)
#define SPECIAL_SHOT_TARGET_JOCKEY  (1 << 6)
#define SPECIAL_SHOT_TARGET_CHARGER (1 << 7)
#define SPECIAL_SHOT_TARGET_TANK    (1 << 8)

public Plugin myinfo =
{
	name = "Special Shot Dual Pistol",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=348957"
};

ConVar C_burn_count;
int O_burn_count;
ConVar C_burn_targets;
int O_burn_targets;
ConVar C_blast_count;
int O_blast_count;
ConVar C_blast_targets;
int O_blast_targets;

int Attack_count[MAXPLAYERS+1];

public void OnEntityCreated(int entity, const char[] classname)
{
    if(entity < 1)
    {
        return;
    }
    if(strcmp(classname, "infected") == 0)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_common);
    }
    else if(strcmp(classname, "witch") == 0)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_witch);
    }
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_dual_pistol(int weapon)
{
    char class_name[64];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    return strcmp(class_name, "weapon_pistol") == 0 && GetEntProp(weapon, Prop_Send, "m_isDualWielding");
}

Action OnTakeDamage_client(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(weapon != -1 && is_dual_pistol(weapon) && GetClientTeam(victim) == 3 && IsPlayerAlive(victim) && is_player_alright(victim) && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
    {
        int target_bit = 0;
        switch(GetEntProp(victim, Prop_Send, "m_zombieClass"))
        {
            case 1:
            {
                target_bit = SPECIAL_SHOT_TARGET_SMOKER;
            }
            case 2:
            {
                target_bit = SPECIAL_SHOT_TARGET_BOOMER;
            }
            case 3:
            {
                target_bit = SPECIAL_SHOT_TARGET_HUNTER;
            }
            case 4:
            {
                target_bit = SPECIAL_SHOT_TARGET_SPITTER;
            }
            case 5:
            {
                target_bit = SPECIAL_SHOT_TARGET_JOCKEY;
            }
            case 6:
            {
                target_bit = SPECIAL_SHOT_TARGET_CHARGER;
            }
            case 8:
            {
                target_bit = SPECIAL_SHOT_TARGET_TANK;
            }
            default:
            {
                return Plugin_Continue;
            }
        }
        int type = get_shot_type(attacker, target_bit);
        if(type != 0)
        {
            damagetype |= type;
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

Action OnTakeDamage_common(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(weapon != -1 && is_dual_pistol(weapon) && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
    {
        int type = get_shot_type(attacker, SPECIAL_SHOT_TARGET_COMMON);
        if(type != 0)
        {
            damagetype |= type;
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

Action OnTakeDamage_witch(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(weapon != -1 && is_dual_pistol(weapon) && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
    {
        int type = get_shot_type(attacker, SPECIAL_SHOT_TARGET_WITCH);
        if(type != 0)
        {
            damagetype |= type;
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_client);
}

int get_shot_type(int client, int target_bit)
{
    if(Attack_count[client] == 0)
    {
        return 0;
    }
    int type = 0;
    if(O_burn_count > 0 && Attack_count[client] % O_burn_count == 0 && O_burn_targets & target_bit)
    {
        type |= DMG_BURN;
    }
    if(O_blast_count > 0 && Attack_count[client] % O_blast_count == 0 && O_blast_targets & target_bit)
    {
        type |= DMG_BLAST;
    }
    return type;
}

void reset_player(int client)
{
    Attack_count[client] = 0;
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client);
}

void reset_all()
{
	for(int client = 1; client <= MaxClients; client++)
	{
        if(IsClientInGame(client))
        {
		    reset_player(client);
        }
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	reset_all();
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

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		char weapon_name[64];
        event.GetString("weapon", weapon_name, sizeof(weapon_name));
        if(strcmp(weapon_name, "pistol") == 0)
        {
            Attack_count[client]++;
        }
	}
}

void data_trans(int client, int prev)
{
    Attack_count[client] = Attack_count[prev];
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
    O_burn_count = C_burn_count.IntValue;
    O_burn_targets = C_burn_targets.IntValue;
    O_blast_count = C_blast_count.IntValue;
    O_blast_targets = C_blast_targets.IntValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_burn_count)
    {
        O_burn_count = C_burn_count.IntValue;
    }
    else if(convar == C_burn_targets)
    {
        O_burn_targets = C_burn_targets.IntValue;
    }
    else if(convar == C_blast_count)
    {
        O_blast_count = C_blast_count.IntValue;
    }
    else if(convar == C_blast_targets)
    {
        O_blast_targets = C_blast_targets.IntValue;
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
    HookEvent("weapon_fire", event_weapon_fire);
	HookEvent("round_start", event_round_start);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_burn_count = CreateConVar("special_shot_dual_pistol_burn_count", "2", "attack count to attach burn effect. 0 or lower = disable");
    C_burn_count.AddChangeHook(convar_changed);
    C_burn_targets = CreateConVar("special_shot_dual_pistol_burn_targets", "509", "burn targets. 1 = common, 2 = witch, 4 = smoker, 8 = boomer, 16 = hunter, 32 = spitter, 64 = jockey, 128 = charger, 256 = tank. add numbers together");
    C_burn_targets.AddChangeHook(convar_changed);
    C_blast_count = CreateConVar("special_shot_dual_pistol_blast_count", "0", "attack count to attach blast effect. 0 or lower = disable");
    C_blast_count.AddChangeHook(convar_changed);
    C_blast_targets = CreateConVar("special_shot_dual_pistol_blast_targets", "511", "blast targets. 1 = common, 2 = witch, 4 = smoker, 8 = boomer, 16 = hunter, 32 = spitter, 64 = jockey, 128 = charger, 256 = tank. add numbers together");
    C_blast_targets.AddChangeHook(convar_changed);
    CreateConVar("special_shot_dual_pistol_version", PLUGIN_VERSION, "version of Special Shot Dual Pistol", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "special_shot_dual_pistol");
    get_all_cvars();

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
    }
    int entity = -1;
    while((entity = FindEntityByClassname(entity, "infected")) != -1)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_common);
    }
    while((entity = FindEntityByClassname(entity, "witch")) != -1)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_witch);
    }
}
