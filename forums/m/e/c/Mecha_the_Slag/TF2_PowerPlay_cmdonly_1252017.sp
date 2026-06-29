#pragma semicolon 1                  // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <adminmenu>

#define PLUGIN_NAME             "[TF2] PowerPlay (CMD only)"
#define PLUGIN_AUTHOR           "Mecha the Slag"
#define PLUGIN_VERSION          "1.2"
#define PLUGIN_CONTACT          "www.mechaware.net/"

new bool:g_PowerPlay[MAXPLAYERS+1] = false;

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{
    decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf")) SetFailState("This plugin is TF2 only.");

    RegAdminCmd("sm_powerplay", Command_PowerPlay, ADMFLAG_SLAY, "sm_powerplay <#userid|name> [0/1]");
    CreateConVar("powerplay_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY);
    HookEvent("player_spawn", Player_Spawn, EventHookMode_PostNoCopy);
}

public Action:Command_PowerPlay(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_powerplay <#userid|name> [0/1]");
        return Plugin_Handled;
    }

    decl String:arg[65];
    GetCmdArg(1, arg, sizeof(arg));
    decl String:arg2[65];
    new bool:arg2_bool = false;
    if (args >= 2) {
        GetCmdArg(2, arg2, sizeof(arg2));
        if (StringToInt(arg2) > 0) arg2_bool = true;
    }

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
        if (IsClientInGame(client) && IsPlayerAlive(client)) ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for (new i = 0; i < target_count; i++) {
        new target = target_list[i];
        if (IsClientInGame(target) && IsPlayerAlive(target)) {
            if (args >= 2) g_PowerPlay[target] = arg2_bool;
            else g_PowerPlay[target] = (!g_PowerPlay[target]);
            GivePowerPlay(client, target);
        }
    }

    if (tn_is_ml)
    {
        ShowActivity2(client, "[SM] ", "Toggled powerplay on target", target_name);
    }
    else
    {
        ShowActivity2(client, "[SM] ", "Toggled powerplay on target", "_s", target_name);
    }

    return Plugin_Handled;
}

GivePowerPlay(client, target)
{
    if (g_PowerPlay[target])
    {
        TF2_SetPlayerPowerPlay(target, true);
        LogAction(client, target, "\"%L\" gave PowerPlay to \"%L\"", client, target);
    }
    else
    {
        TF2_SetPlayerPowerPlay(target, false);
        LogAction(client, target, "\"%L\" removed PowerPlay on \"%L\"", client, target);
    }
}

public Action:Player_Spawn(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    g_PowerPlay[client] = false;
}
