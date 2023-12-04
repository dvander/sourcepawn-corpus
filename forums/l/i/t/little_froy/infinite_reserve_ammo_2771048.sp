#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"2.0"
#define PLUGIN_NAME     "Infinite Reserve Ammo"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336301"
};

static const char Original_configs[][PLATFORM_MAX_PATH] = 
{
    "\"infinite_reserve_ammo\"",
    "{",
    "\t\"weapon_rifle\"",
    "\t{",
    "\t\t\"max\"\t\t\"30\"",
    "\t}",
    "\t\"weapon_rifle_ak47\"",
    "\t{",
    "\t\t\"max\"\t\t\"24\"",
    "\t}",
    "\t\"weapon_rifle_desert\"",
    "\t{",
    "\t\t\"max\"\t\t\"36\"",
    "\t}",
    "\t\"weapon_rifle_sg552\"",
    "\t{",
    "\t\t\"max\"\t\t\"30\"",
    "\t}",
    "\t\"weapon_autoshotgun\"",
    "\t{",
    "\t\t\"max\"\t\t\"6\"",
    "\t}",
    "\t\"weapon_shotgun_spas\"",
    "\t{",
    "\t\t\"max\"\t\t\"6\"",
    "\t}",
    "\t\"weapon_pumpshotgun\"",
    "\t{",
    "\t\t\"max\"\t\t\"5\"",
    "\t}",
    "\t\"weapon_shotgun_chrome\"",
    "\t{",
    "\t\t\"max\"\t\t\"5\"",
    "\t}",
    "\t\"weapon_smg\"",
    "\t{",
    "\t\t\"max\"\t\t\"30\"",
    "\t}",
    "\t\"weapon_smg_silenced\"",
    "\t{",
    "\t\t\"max\"\t\t\"30\"",
    "\t}",
    "\t\"weapon_smg_mp5\"",
    "\t{",
    "\t\t\"max\"\t\t\"30\"",
    "\t}",
    "\t\"weapon_hunting_rifle\"",
    "\t{",
    "\t\t\"max\"\t\t\"9\"",
    "\t}",
    "\t\"weapon_sniper_military\"",
    "\t{",
    "\t\t\"max\"\t\t\"18\"",
    "\t}",
    "\t\"weapon_sniper_scout\"",
    "\t{",
    "\t\t\"max\"\t\t\"9\"",
    "\t}",
    "\t\"weapon_sniper_awp\"",
    "\t{",
    "\t\t\"max\"\t\t\"12\"",
    "\t}",
    "\t\"weapon_rifle_m60\"",
    "\t{",
    "\t\t\"max\"\t\t\"30\"",
    "\t}",
    "\t\"weapon_grenade_launcher\"",
    "\t{",
    "\t\t\"max\"\t\t\"1\"",
    "\t}",
    "}"
};

ConVar C_Optimize_for_listen_server_host;

bool O_Optimize_for_listen_server_host;

StringMap Enabled_weapons;

bool Dedicated_server;
int Listen_server_host;
bool Late_load;

bool is_reloading(int weapon)
{
    return GetEntProp(weapon, Prop_Data, "m_bInReload") != 0;
}

bool is_about_to_reload(int weapon)
{
    return GetEntPropFloat(weapon, Prop_Send, "m_reloadQueuedStartTime") > 0.0;
}

int get_active_weapon(int client)
{
    return GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
}

int get_clip(int weapon)
{
    return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

int get_ammo_type(int weapon)
{
    return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}

int get_reserve_ammo(int client, int ammo_type)
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, ammo_type);
}

void set_reserve_ammo(int client, int ammo_type, int count)
{
    SetEntProp(client, Prop_Data, "m_iAmmo", count, _, ammo_type);
}

int get_config_ammo_max(int weapon)
{
    static char class_name[PLATFORM_MAX_PATH];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    int max = -1;
    if(!Enabled_weapons.GetValue(class_name, max))
    {
        return -1;
    }
    return max;
}

public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
        {
            int primary = GetPlayerWeaponSlot(client, 0);
            if(primary == -1)
            {
                continue;
            }
            int ammo_type = get_ammo_type(primary);
            if(ammo_type == -1)
            {
                continue;
            }
            int max = get_config_ammo_max(primary);
            if(max == -1)
            {
                continue;
            }
            int clip = get_clip(primary);
            int reserve_ammo = get_reserve_ammo(client, ammo_type);
            if(!Dedicated_server && O_Optimize_for_listen_server_host && !IsFakeClient(client) && client == Listen_server_host)
            {
                int active = get_active_weapon(client);
                if(clip + reserve_ammo < max && (clip == 0 || (active == primary && GetClientButtons(client) & IN_RELOAD)))
                {
                    set_reserve_ammo(client, ammo_type, max - clip);
                }
                else if(clip > 0 && reserve_ammo > 0 && clip + reserve_ammo <= max && ((!is_reloading(primary) && !is_about_to_reload(primary)) || active != primary))
                {
                    set_reserve_ammo(client, ammo_type, 0);
                }
            }
            else if(clip + reserve_ammo < max)
            {
                set_reserve_ammo(client, ammo_type, max - clip);
            }
        }
    }
}

public void OnClientPutInServer(int client)
{
    if(Dedicated_server || IsFakeClient(client))
    {
        return;
    }
    static char ip[4];
    GetClientIP(client, ip, sizeof(ip));
    if(ip[0] == 'l' || strcmp(ip, "127") == 0)
    {
        Listen_server_host = client;
    }
}

public void OnClientDisconnect(int client)
{
    if(Listen_server_host == client)
    {
        Listen_server_host = 0;
    }
}

void check_configs()
{
    Enabled_weapons.Clear();
    static char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/infinite_reserve_ammo.cfg");
    if(!FileExists(path))
    {
        File fl = OpenFile(path, "w");
        if(fl)
        {
            int size = sizeof(Original_configs);
            for(int i = 0; i < size; i++)
            {
                fl.WriteLine(Original_configs[i]);
            }
        }
        delete fl;
    }
    KeyValues kv = new KeyValues("infinite_reserve_ammo");
    kv.ImportFromFile(path);
    if(kv.GotoFirstSubKey())
    {
        do
        {
            static char key[PLATFORM_MAX_PATH];
            if(kv.GetSectionName(key, sizeof(key)))
            {
                int max = kv.GetNum("max", -1);
                if(max > 0)
                {
                    Enabled_weapons.SetValue(key, max);
                }
            }
        }
        while(kv.GotoNextKey());
    }
    delete kv;
}

public Action cmd_reload(int args)
{
    check_configs();
    return Plugin_Continue;
}

public void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
    if(Dedicated_server || !O_Optimize_for_listen_server_host)
    {
        return;
    }
	int client = GetClientOfUserId(event.GetInt("player"));
	int prev = GetClientOfUserId(event.GetInt("bot"));
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsFakeClient(client) && client == Listen_server_host && IsPlayerAlive(client) && prev > 0 && prev <= MaxClients)
	{
        int primary = GetPlayerWeaponSlot(client, 0);
        if(primary == -1)
        {
            return;
        }
        int ammo_type = get_ammo_type(primary);
        if(ammo_type == -1)
        {
            return;
        }
        int max = get_config_ammo_max(primary);
        if(max == -1)
        {
            return;
        }
        int clip = get_clip(primary);
        int reserve_ammo = get_reserve_ammo(client, ammo_type);
        if(clip > 0 && reserve_ammo > 0 && clip + reserve_ammo <= max && ((!is_reloading(primary) && !is_about_to_reload(primary)) || get_active_weapon(client) != primary))
        {
            set_reserve_ammo(client, ammo_type, 0);
        }
	}
}

void get_cvars()
{
	O_Optimize_for_listen_server_host = C_Optimize_for_listen_server_host.BoolValue;
}

public void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    Late_load = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    Enabled_weapons = new StringMap();

    Dedicated_server = IsDedicatedServer();

    check_configs();

    RegServerCmd("infinite_reserve_ammo_reload", cmd_reload, "reload config data from file");

    HookEvent("bot_player_replace", event_bot_player_replace);

    C_Optimize_for_listen_server_host = CreateConVar("infinite_reserve_ammo_optimize_for_listen_server_host", "1", "1 = enable, 0 = disable. only generate ammo for listen server host when try to reload?");

    CreateConVar("infinite_reserve_ammo_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

    C_Optimize_for_listen_server_host.AddChangeHook(convar_changed);

    AutoExecConfig(true, "infinite_reserve_ammo");

    if(Late_load)
    {
        for(int client = 1; client <= MaxClients; client++)
        {
            if(IsClientInGame(client))
            {
                OnClientPutInServer(client);
            }
        }
    }
}