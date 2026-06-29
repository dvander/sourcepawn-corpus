/*
	"rage_alt_fire_disable"		
	{
		"alt_fire_disable"	"1"				// 0 - false, 1 - true
		
		"plugin_name"	"ff2r_altfire"		// this subplugin name
	}
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>
#include <tf2items>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME     "Freak Fortress 2 Rewrite: Alt Fire Disable Subplugin"
#define PLUGIN_AUTHOR   "fral"
#define PLUGIN_DESC     "Disables alt-fire for bosses based on config"

#define MAJOR_REVISION  "1"
#define MINOR_REVISION  "0"
#define STABLE_REVISION "1"
#define PLUGIN_VERSION  MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL ""

#define MAXTF2PLAYERS 36

public Plugin myinfo = 
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESC,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL,
};

bool g_bAltFireDisabled[MAXTF2PLAYERS + 1];

public void OnPluginStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (!IsValidClient(client)) return;

    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
}

public void OnPluginEnd()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        g_bAltFireDisabled[client] = false;
    }
}

public Action OnWeaponEquip(int client, int weapon)
{
    if (!IsValidEntity(weapon))
        return Plugin_Continue;

    BossData boss = FF2R_GetBossData(client);
    if (!boss)
        return Plugin_Continue;

    AbilityData ability = boss.GetAbility("rage_alt_fire_disable");
    if (!ability.IsMyPlugin())
        return Plugin_Continue;

    if (ability.GetInt("alt_fire_disable", 0) == 1)
    {
		static char weaponClass[64];
        GetEdictClassname(weapon, weaponClass, sizeof(weaponClass));
		if (StrEqual(weaponClass, "tf_weapon_fists"))
		{
			g_bAltFireDisabled[client] = true;
		}
    }

    return Plugin_Continue;
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(buttons & IN_ATTACK2 && g_bAltFireDisabled[client])
	{
		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		SetEntPropFloat(activeWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 9999.0);
	}
} 

public void FF2R_OnBossRemoved(int client)
{
    if (!IsValidClient(client)) return;

    g_bAltFireDisabled[client] = false;
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
    if (client <= 0 || client > MaxClients)
        return false;

    if (!IsClientInGame(client) || !IsClientConnected(client))
        return false;

    if (GetEntProp(client, Prop_Send, "m_bIsCoaching"))
        return false;

    if (replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
        return false;

    return true;
}