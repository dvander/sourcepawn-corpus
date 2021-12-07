/*
 * ====================
 *     Extend Map
 *   File: extend.sp
 *   Author: MOPO3KO
 * ==================== 
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

new Handle:g_Cvar_Maxrounds = INVALID_HANDLE;
new Handle:g_Cvar_Fraglimit = INVALID_HANDLE;
new Handle:g_Cvar_Winlimit  = INVALID_HANDLE;
new Handle:g_Cvar_Timelimit = INVALID_HANDLE;
new Handle:g_Cvar_Capture   = INVALID_HANDLE;
new g_Extends = -3;
new u_Extends =  3;
new old_round = -1;
new old_frag  = -1;
new old_win   = -1;
new old_time  = -1;
new old_capt  = -1;

public Plugin:myinfo =
{
    name        = "Extend Map",
    author      = "MOPO3KO",
    description = "Admin or voting can extend a map",
    version     = PLUGIN_VERSION,
    url         = "http://forums.alliedmods.net/showthread.php?t=98456"
};

public OnPluginStart()
{
    CreateConVar("sm_extend_version", PLUGIN_VERSION, "Extend Map version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    RegAdminCmd("sm_extend_round",    ExtendRound,    ADMFLAG_GENERIC, "Add the additional rounds to mp_maxrounds");
    RegAdminCmd("sm_extend_frag",     ExtendFrag,     ADMFLAG_GENERIC, "Add the additional frag limit to mp_fraglimit");
    RegAdminCmd("sm_extend_win",      ExtendWin,      ADMFLAG_GENERIC, "Add the additional win limit to mp_winlimit");
    RegAdminCmd("sm_extend_time",     ExtendTime,     ADMFLAG_GENERIC, "Add the additional time to mp_timelimit");
    RegAdminCmd("sm_extend_capture",  ExtendCapt,     ADMFLAG_GENERIC, "Add the additional flag captures to tf_flag_caps_per_round");
    RegAdminCmd("sm_extend_max",      ExtendMax,      ADMFLAG_GENERIC, "Set the maximum extensions per map. -1: disable plugin, 0: infinity, default 3");
    RegAdminCmd("sm_extend_roundtime",ExtendRoundTime,ADMFLAG_GENERIC, "Add the additional time to team round timer");
    g_Cvar_Maxrounds = FindConVar("mp_maxrounds");
    g_Cvar_Fraglimit = FindConVar("mp_fraglimit");
    g_Cvar_Winlimit  = FindConVar("mp_winlimit");
    g_Cvar_Timelimit = FindConVar("mp_timelimit");
    g_Cvar_Capture   = FindConVar("tf_flag_caps_per_round");
}

public OnPluginEnd()
{
    if(old_round!=-1) {SetConVarInt(g_Cvar_Maxrounds,old_round);old_round = -1;}
    if(old_frag !=-1) {SetConVarInt(g_Cvar_Fraglimit,old_frag); old_frag  = -1;}
    if(old_win  !=-1) {SetConVarInt(g_Cvar_Winlimit, old_win);  old_win   = -1;}
    if(old_time !=-1) {SetConVarInt(g_Cvar_Timelimit,old_time); old_time  = -1;}
    if(old_capt !=-1) {SetConVarInt(g_Cvar_Capture,  old_capt); old_capt  = -1;}
}

public Action:ExtendMax(client, args)
{
    if(args < 1) {
        ReplyToCommand(client, "\"sm_extend_max\" = \"%d\" ( \"-1\" disabled, \"0\" infinity, def. \"3\" )\n - maximum extensions per map\n Remains \"%d\" extends on this map",u_Extends,g_Extends);
        return Plugin_Handled;
    }
    decl String:str[16];
    GetCmdArg(1, str, sizeof(str));
    u_Extends = StringToInt(str);
    if(u_Extends < -1) u_Extends = -1;
    if(g_Extends !=-3) {
        if(!u_Extends)
            g_Extends = -2;
        else
            g_Extends = u_Extends;
    }
    return Plugin_Handled;
}

public OnConfigsExecuted()
{
    g_Extends = u_Extends;
    if(!g_Extends) g_Extends = -2;
    if(g_Cvar_Maxrounds!=INVALID_HANDLE) old_round = GetConVarInt(g_Cvar_Maxrounds);
    if(g_Cvar_Fraglimit!=INVALID_HANDLE) old_frag  = GetConVarInt(g_Cvar_Fraglimit);
    if(g_Cvar_Winlimit !=INVALID_HANDLE) old_win   = GetConVarInt(g_Cvar_Winlimit);
    if(g_Cvar_Timelimit!=INVALID_HANDLE) old_time  = GetConVarInt(g_Cvar_Timelimit);
    if(g_Cvar_Capture  !=INVALID_HANDLE) old_capt  = GetConVarInt(g_Cvar_Capture);
}

public OnMapEnd()
{
    g_Extends = -3;
    OnPluginEnd();
}

pl_Action(client, args, num)
{
    if(args < 1) {
        switch (num) {
            case 1 : {ReplyToCommand(client, "[SM] Usage: sm_extend_round <extend round>");}
            case 2 : {ReplyToCommand(client, "[SM] Usage: sm_extend_frag <extend frag limit>");}
            case 3 : {ReplyToCommand(client, "[SM] Usage: sm_extend_win <extend win limit>");}
            case 4 : {ReplyToCommand(client, "[SM] Usage: sm_extend_time <extend time>");}
            case 5 : {ReplyToCommand(client, "[SM] Usage: sm_extend_capture <extend flag capture>");}
            case 6 : {ReplyToCommand(client, "[SM] Usage: sm_extend_roundtime <extend time>");}
        }
        return;
    }

    switch (g_Extends) {
        case -3 : {ReplyToCommand(client, "[SM] Game not started.");}
        case -2 : {g_Extends = -2;}
        case -1 : {
            ReplyToCommand(client, "[SM] sm_extend_max = -1. Plugin disabled.");
            return;
        }
        case 0  : {
            ReplyToCommand(client, "[SM] Max extend limit reached.");
            return;
        }
        default : {g_Extends--;}
    }

    decl String:str[16];
    GetCmdArg(1, str, sizeof(str));
    new pl_arg = StringToInt(str);
    if(pl_arg < 0) return;

    switch (num) {
        case 1 : {SetConVarInt(g_Cvar_Maxrounds,pl_arg+GetConVarInt(g_Cvar_Maxrounds));}
        case 2 : {SetConVarInt(g_Cvar_Fraglimit,pl_arg+GetConVarInt(g_Cvar_Fraglimit));}
        case 3 : {SetConVarInt(g_Cvar_Winlimit, pl_arg+GetConVarInt(g_Cvar_Winlimit));}
        case 4 : {SetConVarInt(g_Cvar_Timelimit,pl_arg+GetConVarInt(g_Cvar_Timelimit));}
        case 5 : {SetConVarInt(g_Cvar_Capture,  pl_arg+GetConVarInt(g_Cvar_Capture));}
        case 6 : {
            new Entity = FindEntityByClassname(-1, "team_round_timer");
            if (Entity > -1) {
                SetVariantInt(pl_arg);
                AcceptEntityInput(Entity, "AddTime");
                GetCurrentMap(str, sizeof(str));
                if (strncmp(str, "koth_", 5) == 0) {
                   Entity = FindEntityByClassname(Entity, "team_round_timer");
                   if (Entity > -1) {
                       SetVariantInt(pl_arg);
                       AcceptEntityInput(Entity, "AddTime");
                   }
                }
            }
        }
    }
}

public Action:ExtendRound(client, args)
{
    if(g_Cvar_Maxrounds!=INVALID_HANDLE) pl_Action(client, args, 1);
    return Plugin_Handled;
}

public Action:ExtendFrag(client, args)
{
    if(g_Cvar_Fraglimit!=INVALID_HANDLE) pl_Action(client, args, 2);
    return Plugin_Handled;
}

public Action:ExtendWin(client, args)
{
    if(g_Cvar_Winlimit !=INVALID_HANDLE) pl_Action(client, args, 3);
    return Plugin_Handled;
}

public Action:ExtendTime(client, args)
{
    if(g_Cvar_Timelimit!=INVALID_HANDLE) pl_Action(client, args, 4);
    return Plugin_Handled;
}

public Action:ExtendCapt(client, args)
{
    if(g_Cvar_Capture  !=INVALID_HANDLE) pl_Action(client, args, 5);
    return Plugin_Handled;
}

public Action:ExtendRoundTime(client, args)
{
    pl_Action(client, args, 6);
    return Plugin_Handled;
}
