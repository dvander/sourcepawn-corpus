#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define DEFAULT_COMMON 30
#define DEFAULT_MIN 10
#define DEFAULT_MAX 30
#define DEFAULT_MOB 50

bool ignoreChangehook;
ConVar z_common_limit;
ConVar z_mob_spawn_max_size;
ConVar z_mob_spawn_min_size;
ConVar z_mega_mob_size;

int leeway_common;
int leeway_min;
int leeway_max;
int leeway_mob;

public Plugin myinfo = 
{
	name = "[L4D2] Lock Common Infected CVars",
	author = "Addie, Tabun, Xbye",
	description = "Prevents campaigns of increasing common related cvars via ConVar and director scripts.",
	version = "0.4",
	// url = ""
}

public void OnPluginStart() 
{
    ignoreChangehook = false;

    z_common_limit = FindConVar("z_common_limit");
    z_mob_spawn_min_size = FindConVar("z_mob_spawn_min_size");
    z_mob_spawn_max_size = FindConVar("z_mob_spawn_max_size");
    z_mega_mob_size = FindConVar("z_mega_mob_size");

    z_common_limit.AddChangeHook(OnCommonLimit);
    z_mob_spawn_min_size.AddChangeHook(OnMinMob);
    z_mob_spawn_max_size.AddChangeHook(OnMaxMob);
    z_mega_mob_size.AddChangeHook(OnMegaMob);

    RegAdminCmd("sm_set_common_limit", Cmd_SetCommonLimit, ADMFLAG_GENERIC);

    leeway_common = 0 + DEFAULT_COMMON;
    leeway_min = 20 + DEFAULT_MIN;
    leeway_max = 30 + DEFAULT_MAX;
    leeway_mob = 10 + DEFAULT_MOB;
}
Action Cmd_SetCommonLimit(int client, int args)
{
    ignoreChangehook = true;
    z_common_limit.IntValue = GetCmdArgInt(1);
    ignoreChangehook = false;

    return Plugin_Handled;
}
void OnCommonLimit(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (ignoreChangehook || StringToInt(newValue) < leeway_common)
        return;
    convar.IntValue = leeway_common;
}

void OnMinMob(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (ignoreChangehook || StringToInt(newValue) < leeway_min)
        return;
    convar.IntValue = leeway_min;
}

void OnMaxMob(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (ignoreChangehook || StringToInt(newValue) < leeway_max)
        return;
    convar.IntValue = leeway_max;
}

void OnMegaMob(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (ignoreChangehook || StringToInt(newValue) < leeway_mob)
        return;
    convar.IntValue = leeway_mob;
}

// From Tabun's scripts
public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
    if (strcmp(key, "CommonLimit") == 0) {
        if (retVal >= leeway_common) {
            retVal = leeway_common;
            return Plugin_Handled;
        }
    }
    else if(strcmp(key, "MobMinSize") == 0)
    {
        if (retVal >= leeway_min)
        {
            retVal = leeway_min;
            return Plugin_Handled;
        }
    }
    else if(strcmp(key, "MobMaxSize") == 0)
    {
        if (retVal >= leeway_max)
        {
            retVal = leeway_max;
            return Plugin_Handled;
        }
    }
    else if(strcmp(key, "MegaMobSize") == 0)
    {
        if (retVal >= leeway_mob)
        {
            retVal = leeway_mob;
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}