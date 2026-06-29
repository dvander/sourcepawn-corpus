#define PLUGIN_VERSION	"2.3"

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
	name = "Special Shot",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=348957"
};

StringMap Burn_count;
StringMap Blast_count;
StringMap Burn_targets;
StringMap Blast_targets;
int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];

char Data_path[PLATFORM_MAX_PATH];

StringMap Weapon_name_and_attack_count[MAXPLAYERS+1];

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

Action OnTakeDamage_client(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(weapon != -1 && GetClientTeam(victim) == 3 && IsPlayerAlive(victim) && is_player_alright(victim) && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
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
        int type = get_shot_type(attacker, weapon, target_bit);
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
    if(weapon != -1 && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
    {
        int type = get_shot_type(attacker, weapon, SPECIAL_SHOT_TARGET_COMMON);
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
    if(weapon != -1 && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
    {
        int type = get_shot_type(attacker, weapon, SPECIAL_SHOT_TARGET_WITCH);
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

int get_shot_type(int client, int weapon, int target_bit)
{
    char class_name[64];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    int count = 0;
    if(!Weapon_name_and_attack_count[client].GetValue(class_name[7], count))
    {
        return 0;
    }
    int type = 0;
    int burn_attack_count = 0;
    int blast_attack_count = 0;
    if(Burn_count.GetValue(class_name[7], burn_attack_count) && count % burn_attack_count == 0)
    {
        int burn_targets = 0;
        if(Burn_targets.GetValue(class_name[7], burn_targets) && burn_targets & target_bit)
        {
            type |= DMG_BURN;
        }
    }
    if(Blast_count.GetValue(class_name[7], blast_attack_count) && count % blast_attack_count == 0)
    {
        int blast_targets = 0;
        if(Blast_targets.GetValue(class_name[7], blast_targets) && blast_targets & target_bit)
        {
            type |= DMG_BLAST;
        }
    }
    return type;
}

void reset_player(int client)
{
    Weapon_name_and_attack_count[client].Clear();
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
        int count = 0;
        Weapon_name_and_attack_count[client].GetValue(weapon_name, count);
        Weapon_name_and_attack_count[client].SetValue(weapon_name, ++count);
	}
}

void data_trans(int client, int prev)
{
    delete Weapon_name_and_attack_count[client];
    Weapon_name_and_attack_count[client] = Weapon_name_and_attack_count[prev].Clone();
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

SMCResult OnEnterSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	Current_section_level++;
	if(Current_section_level == 2)
	{
        strcopy(Current_section_name, sizeof(Current_section_name), name);
	}
    return SMCParse_Continue;
}

SMCResult OnLeaveSection(SMCParser smc)
{
    Current_section_level--;
    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if(Current_section_level == 2)
	{
        if(strcmp(key, "blast_attack_count") == 0)
        {
            int count = StringToInt(value);
            if(count > 0)
            {
                Blast_count.SetValue(Current_section_name, count);
            }
        }
        else if(strcmp(key, "blast_targets") == 0)
        {
            int targets = StringToInt(value);
            if(targets > 0)
            {
                Blast_targets.SetValue(Current_section_name, targets);
            }
        }
        else if(strcmp(key, "burn_attack_count") == 0)
        {
            int count = StringToInt(value);
            if(count > 0)
            {
                Burn_count.SetValue(Current_section_name, count);
            }
        }
        else if(strcmp(key, "burn_targets") == 0)
        {
            int targets = StringToInt(value);
            if(targets > 0)
            {
                Burn_targets.SetValue(Current_section_name, targets);
            }
        }
	}
    return SMCParse_Continue;
}

void check_configs()
{
    Burn_count.Clear();
    Burn_targets.Clear();
    Blast_count.Clear();
    Blast_targets.Clear();
    Current_section_level = 0;
    Current_section_name[0] = '\0';
    SMCParser parser = new SMCParser();
    parser.OnEnterSection = OnEnterSection;
    parser.OnLeaveSection = OnLeaveSection;
    parser.OnKeyValue = OnKeyValue;
    parser.ParseFile(Data_path);
    delete parser;
}

Action cmd_reload(int client, int args)
{
    check_configs();
    reset_all();
    return Plugin_Handled;
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
    Burn_count = new StringMap();
    Blast_count = new StringMap();
    Burn_targets = new StringMap();
    Blast_targets = new StringMap();
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        Weapon_name_and_attack_count[i] = new StringMap();
    }

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/special_shot.cfg");

    HookEvent("weapon_fire", event_weapon_fire);
	HookEvent("round_start", event_round_start);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    CreateConVar("special_shot_version", PLUGIN_VERSION, "version of Special Shot", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    check_configs();

    RegAdminCmd("sm_special_shot_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");

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
