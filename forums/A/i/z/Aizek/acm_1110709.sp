#pragma semicolon 1
#include <sourcemod>

new g_1 = 0;
new g_2 = 0;
new Float:g_time = 0.0;
new Handle:timer_1 = INVALID_HANDLE; 
new Handle:timer_2 = INVALID_HANDLE;
new Handle:g_Cvar_Timelimit = INVALID_HANDLE;
new Handle:new_map;

public Plugin:myinfo =
{
	name = "Auto change map",
	author = "MOPO3KO",
	description = "Change the map if there are no players on the server and time limit is reached or number of players too small",
	version = "2.0",
	url = "http://forums.alliedmods.net/showthread.php?t=120696"
}

public OnPluginStart()
{
        RegAdminCmd("sm_acm_idlechange", CMD_1, ADMFLAG_GENERIC, "Change map if server is idle (no clients) and time limit is reached. on/off default off");
        RegAdminCmd("sm_acm_minplayers", CMD_2, ADMFLAG_GENERIC, "Minimum players before server will be load the next map. Work only if one player on server or more... default 0 - disabled");
	new_map = CreateConVar("sm_acm_nextmap","","Name of the map for change without .bsp, if blank - used nextmap cvar", FCVAR_PLUGIN);
        g_Cvar_Timelimit = FindConVar("mp_timelimit");
        AutoExecConfig(false, "acm");
}

public Action:CMD_1(client, args)
{
    if(args > 0) {
        decl String:str[16];
        GetCmdArg(1, str, sizeof(str));
        g_1 = strncmp(str,"on",2) ? 0 : 1; 
        if(timer_1 != INVALID_HANDLE) {
            KillTimer(timer_1); 
            timer_1 = INVALID_HANDLE;
        }
        if(g_1 == 0) return Plugin_Handled;
        if(!IsServerProcessing()) g_time = GetEngineTime();
        else g_time = 0.0;
        timer_1 = CreateTimer(60.0,fun_1,INVALID_HANDLE,TIMER_REPEAT);
    }
    else ReplyToCommand(client, "\"sm_acm_idlechange\" is \"%s\"   on/off default off\n - Change map if server is idle (no clients) and time limit is reached", g_1 ? "on" : "off");

    return Plugin_Handled;
}

public Action:CMD_2(client, args)
{
    if(args > 0) {
        decl String:str[16];
        GetCmdArg(1, str, sizeof(str));
        g_2 = StringToInt(str);
        if(timer_2 != INVALID_HANDLE) {
            KillTimer(timer_2); 
            timer_2 = INVALID_HANDLE;
        }
        if(g_2 < 0 || g_2 > GetMaxClients()) g_2 = 0; 
        if(g_2 == 0) return Plugin_Handled;
        timer_2 = CreateTimer(60.0,fun_2,INVALID_HANDLE,TIMER_REPEAT);
    }
    else ReplyToCommand(client, "\"sm_acm_minplayers\" = \"%d\"   default 0 - disabled\n - Minimum players before server will be load the next map.\n   Work only if one player on server or more...", g_2);

    return Plugin_Handled;
}

public Action:fun_1(Handle:timer) 
{
    new tf;
    if(GetConVarInt(g_Cvar_Timelimit)) {
        if(!IsServerProcessing()) {
            if(g_time+GetConVarInt(g_Cvar_Timelimit)*60.0 < GetEngineTime()) {
                g_time = GetEngineTime();
                pl_action();
            }
        }
        else {
            g_time = 0.0;
            if(GetRealClientCount(false) == 0 && GetMapTimeLeft(tf) && tf <= 0) pl_action();
        }
    }
}

public Action:fun_2(Handle:timer) 
{
    new tf = GetRealClientCount(false);
    if(tf > 0 && tf <= g_2)  pl_action();
}

pl_action()
{
    new String:str[128];
    new i;
    GetConVarString(new_map, str, sizeof(str));
    if(str[0] != 0) i = IsMapValid(str);
    else i = GetNextMap(str, sizeof(str)); 
    if(i) ServerCommand("changelevel %s",str);
    else PrintToServer("[ACM] Map \"%s\" is not valid.",str);
}

stock GetRealClientCount( bool:inGameOnly = true ) {
    new clients = 0;
    for( new i = 1; i <= GetMaxClients(); i++ ) {
        if( ( ( inGameOnly ) ? IsClientInGame( i ) : IsClientConnected( i ) ) && !IsFakeClient( i ) ) {
            clients++;
        }         
    }
    return clients;
}