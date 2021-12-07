#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hosties>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hVersion = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Hosties: Slayed Weapon Remover",
    author = "Jason Bourne & Kolapsicle",
    description = "Removes weapons of players slayed by an admin.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2160631"
};

public OnPluginStart()
{
    AddCommandListener(Command_RemoveWeapon, "sm_slay");

    g_hVersion = CreateConVar("sm_rmweapon_version", PLUGIN_VERSION, "Current Slayed Weapon Remover version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    SetConVarString(g_hVersion, PLUGIN_VERSION);
}

public Action:Command_RemoveWeapon(client, const String:command[], argc)
{
    if (argc < 1)
    {
        return Plugin_Handled;
    }

    decl String:arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        return Plugin_Handled;
    }

    for (new i = 0; i < target_count; i++)
    {
        StripAllWeapons(target_list[i]);
    }

    return Plugin_Handled;
}
