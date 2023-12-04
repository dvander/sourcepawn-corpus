#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION	"1.6"
#define PLUGIN_NAME     "Set Weapon Clip To Empty When Reloading"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340324"
};

static const char Original_configs[][PLATFORM_MAX_PATH] = 
{
    "\"empty_clip_when_reloading\"",
    "{",
    "\t\"weapon_rifle\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_rifle_ak47\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_rifle_desert\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_rifle_sg552\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_smg\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_smg_silenced\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_smg_mp5\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_hunting_rifle\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_sniper_military\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_sniper_scout\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_sniper_awp\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_rifle_m60\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_grenade_launcher\"",
    "\t{",
    "\t\t\"enable\"\t\t\"1\"",
    "\t}",
    "\t\"weapon_pistol\"",
    "\t{",
    "\t\t\"enable\"\t\t\"0\"",
    "\t}",
    "\t\"weapon_pistol_magnum\"",
    "\t{",
    "\t\t\"enable\"\t\t\"0\"",
    "\t}",
    "}"
};

ArrayList Enabled_weapons;

void check_configs()
{
    Enabled_weapons.Clear();
    static char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/empty_clip_when_reloading.cfg");
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
    KeyValues kv = new KeyValues("empty_clip_when_reloading");
    kv.ImportFromFile(path);
    if(kv.GotoFirstSubKey())
    {
        do
        {
            static char key[PLATFORM_MAX_PATH];
            if(kv.GetSectionName(key, sizeof(key)) && kv.GetNum("enable", 0))
            {
                Enabled_weapons.PushString(key);
            }
        }
        while(kv.GotoNextKey());
    }
    delete kv;
}

public Action cmd_reload(int args)
{
    check_configs();
    return Plugin_Handled;
}

public void event_weapon_reload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
        int active_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
        if(active_weapon == -1 || !GetEntProp(active_weapon, Prop_Data, "m_bInReload") || GetEntProp(active_weapon, Prop_Data, "m_iClip1") == 0)
        {
            return;    
        }
        static char class_name[PLATFORM_MAX_PATH];
        GetEntityClassname(active_weapon, class_name, sizeof(class_name));
        if(Enabled_weapons.FindString(class_name) != -1)
        {
            SetEntProp(active_weapon, Prop_Data, "m_iClip1", 0);
        }
	}
}

public void OnPluginStart()
{
    Enabled_weapons = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

    check_configs();

    RegServerCmd("empty_clip_when_reloading_reload", cmd_reload, "reload config data from file");

    HookEvent("weapon_reload", event_weapon_reload);

	CreateConVar("empty_clip_when_reloading_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
}