/*******************************************************/
/*** MapCron plugin v 1.2                            ***/
/***                                                 ***/
/*** A mapspecific timemanager for delayed command   ***/
/*** execution every map start and every             ***/
/*** playerconnection.                               ***/
/***                                                 ***/
/*** Author: SSH (stillsetzhut@web.de)               ***/
/*******************************************************/
/*

------------------
    sm_mapcron_version                          - MapCron version.

    sm_mapcron_add <seconds> <command>          - Add delayed command.
    sm_mapcron_del <id>                         - Delete task by id.
    sm_mapcron_clear                            - Delete all tasks.
    sm_mapcron_list                             - List all current tasks.
    sm_mapcron_restart                          - Restart all timers for tasks.

Requirements
------------
    Counter-Strike: Source
    SourceMod 1.2.0

Changelog
---------
	v 1.2 RC 28/08/12:
		improved clientcheck

	v 1.1 beta 27/08/12:
		add clientcheck and servermessages

	v 1.0 beta 25/08/12:
		First run, add OnClinentConnected and OnClientDisconnected

Credits
-------
Original script by Otstrel.ru Team

*/

#include <sourcemod>

#pragma semicolon 1

#define MAX_TASKS 20
#define MAX_TASK_LEN 100

#define PLUGIN_VERSION "1.2 RC"

/*public Plugin:myinfo =
 *{
 *   name = "GameCron",
 *   author = "Otstrel.ru Team",
 *   description = "Simple crontab for delayed command execution every map start.",
 *   version = PLUGIN_VERSION,
 *   url = "http://otstrel.ru"
 *};
 */

public Plugin:myinfo = {
    name = "MapCron",
    author = "SSH",
    description = "A mapspecific timemanager for delayed command execution every map start and every playerconnection.",
    version = PLUGIN_VERSION,
    url = "http://server.burningheart.name"
};

new Float:g_fTimerDelay[MAX_TASKS];
new String:g_sTimerCommand[MAX_TASKS][MAX_TASK_LEN];
new Handle:g_hTimer[MAX_TASKS];

new Handle:mp_restartgame = INVALID_HANDLE;

public OnPluginStart() {
    new Handle:Cvar_Version = CreateConVar("sm_mapcron_version", PLUGIN_VERSION, "MapCron Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    /* Just to make sure they it updates the convar version if they just had the plugin reload on map change */
    SetConVarString(Cvar_Version, PLUGIN_VERSION);

    ClearTasks();

    RegAdminCmd ("sm_mapcron_add", Command_Add, ADMFLAG_ROOT, "sm_mapcron_add time command - Add delayed command.");
    RegAdminCmd ("sm_mapcron_del", Command_Del, ADMFLAG_ROOT, "sm_mapcron_del id - Delete task by id.");
    RegAdminCmd ("sm_mapcron_clear", Command_Clear, ADMFLAG_ROOT, "sm_mapcron_clear - Delete all tasks.");
    RegAdminCmd ("sm_mapcron_list", Command_List, ADMFLAG_ROOT, "sm_mapcron_list - List all current tasks.");
    RegAdminCmd ("sm_mapcron_restart", Command_Restart, ADMFLAG_ROOT, "sm_mapcron_restart - Restart all timers for tasks.");

    mp_restartgame = FindConVar("mp_restartgame");
    if ( mp_restartgame != INVALID_HANDLE ) {
        HookConVarChange(mp_restartgame, Restart_Handler);
    }
}

public Restart_Handler(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if ( (convar == mp_restartgame) && (GetConVarInt(mp_restartgame) == 0) ) {
        RestartTimer();
    }
}

public OnPluginEnd() {
    ClearTasks();
}

public OnMapStart() {
    RestartTimer();
}

public OnClientConnected(client) {
	new bool:bTvEnabled = IsSourceTvEnabled();
	if ( ( GetClientCount(false) == 0 && !bTvEnabled ) || ( GetClientCount(false) == 1 && bTvEnabled ) ) {
	    PrintToServer("[MapCron] %s", "No clients ingame and no clients connecting");
	}
	if ( GetClientCount(false) == 1 && !bTvEnabled ) {
		RestartTimer();
		PrintToServer("[MapCron] %s", "A client is on the server, MapCron restarts");
	}
}

public OnClientDisconnect_Post(client) {
	new bool:bTvEnabled = IsSourceTvEnabled();
	if ( ( GetClientCount(false) == 0 && !bTvEnabled ) || ( GetClientCount(false) == 1 && bTvEnabled ) ) {
    	PrintToServer("[MapCron] %s", "All clients have leave the server, nothing to do");
	}
}

public RestartTimer() {
    for (new i = 0; i < MAX_TASKS; i++) {
        if ( g_hTimer[i] && ( g_hTimer[i] != INVALID_HANDLE) ) {
            CloseHandle(g_hTimer[i]);
            g_hTimer[i] = INVALID_HANDLE;
        }
        if (g_fTimerDelay[i] > 0) {
            g_hTimer[i] = CreateTimer(g_fTimerDelay[i], Timer_ExecuteTask, i);
        }
    }
}

public ClearTasks() {
    for (new i = 0; i < MAX_TASKS; i++) {
        if ( g_hTimer[i] && ( g_hTimer[i] != INVALID_HANDLE) ) {
            CloseHandle(g_hTimer[i]);
            g_hTimer[i] = INVALID_HANDLE;
        }
        g_sTimerCommand[i] = "";
        g_fTimerDelay[i] = 0.0;
    }
}

public Action:Timer_ExecuteTask(Handle:timer, any:taskId) {
    g_hTimer[taskId] = INVALID_HANDLE;
    ServerCommand(g_sTimerCommand[taskId]);
    return Plugin_Continue;
}

public Action:Command_Clear(client, args) {
    ClearTasks();
    ReplyToCommand (client, "[MapCron] All tasks deleted.");
    return Plugin_Handled;
}

public Action:Command_Del(client, args) {
    decl String:buffer[MAX_TASK_LEN] = "";
    if (args == 1)     {
        GetCmdArg (1, buffer, sizeof(buffer));
        new iId = StringToInt(buffer);
        if (DelTask(iId)) {
            ReplyToCommand (client, "[MapCron] Cron task %i deleted successfully.", iId);
        }
        else {
            ReplyToCommand (client, "[MapCron] Can not find task.");
        }
    }
    else {
        ReplyToCommand (client, "[MapCron] sm_mapcron_del - Invalid usage.");
        ReplyToCommand (client, "[MapCron] Usage: sm_mapcron_del id");
    }
    return Plugin_Handled;
}

public Action:Command_List(client, args) {
    ReplyToCommand (client, "[MapCron] All tasks list:");
    for (new i = 0; i < MAX_TASKS; i++) {
        if (g_fTimerDelay[i] > 0) {
            ReplyToCommand (client, "%i\t%f\t%s",i,g_fTimerDelay[i],g_sTimerCommand[i]);
        }
    }
    return Plugin_Handled;
}

public Action:Command_Restart(client, args) {
    RestartTimer();
    ReplyToCommand (client, "[MapCron] Restarted.");
    return Plugin_Handled;
}

public Action:Command_Add(client, args) {
    decl String:buffer[MAX_TASK_LEN] = "";
    if (args == 2) {
        GetCmdArg (1, buffer, sizeof(buffer));
        new Float:fDelay = StringToFloat(buffer);
        GetCmdArg (2, buffer, sizeof(buffer));
        if (strcmp(buffer,"")!=0) {
            if (AddTask(fDelay,buffer)) {
                ReplyToCommand (client, "[MapCron] Cron task \"%s\" added successfully.", buffer);
            }
            else {
                ReplyToCommand (client, "[MapCron] Task list is full.");
            }
        }
    }
    else {
        ReplyToCommand (client, "[MapCron] sm_mapcron_add - Invalid usage.");
        ReplyToCommand (client, "[MapCron] Usage: sm_mapcron_add time \"command\"");
    }
    return Plugin_Handled;
}

public bool:AddTask(Float:fDelay, const String:sCommand[MAX_TASK_LEN]) {
	for (new i = 0; i < MAX_TASKS; i++) {
        if (g_fTimerDelay[i] <= 0) {
            g_fTimerDelay[i] = fDelay;
            g_sTimerCommand[i] = sCommand;
            g_hTimer[i] = CreateTimer(g_fTimerDelay[i], Timer_ExecuteTask, i);
            return true;
        }
    }
    return false;
}

public bool:DelTask(iId) {
    if (iId < 0 || iId > MAX_TASKS) {
        return false;
    }
    if ( g_fTimerDelay[iId] <= 0 ) {
        return false;
    }
    g_fTimerDelay[iId] = 0.0;
    g_sTimerCommand[iId] = "";
    if ( g_hTimer[iId] && ( g_hTimer[iId] != INVALID_HANDLE) ) {
        CloseHandle(g_hTimer[iId]);
        g_hTimer[iId] = INVALID_HANDLE;
    }
    return true;
}

bool:IsSourceTvEnabled() {
	new bool:bTvEnabled = false;
	new iClientCount = GetClientCount(false);
	if (iClientCount != 0) {
		new Handle:hConVar = FindConVar("tv_enable");
		new bool:bTvEnable;
		if (hConVar != INVALID_HANDLE) {
			bTvEnable = GetConVarBool(hConVar);
		}
		if (bTvEnable) {
			bTvEnabled = true;
		}
		else {
			hConVar = FindConVar("tv_name");
			new String:sTvName[32];
			if (hConVar != INVALID_HANDLE) {
				GetConVarString(hConVar, sTvName, sizeof(sTvName));
			}

			for (new i=1; i <= iClientCount; i++) {
        		new String:sClientName[32];
        		if (IsClientInGame(i)) {
					GetClientName(i, sClientName, sizeof(sClientName));
          			if (StrEqual(sTvName, sClientName)) {
          				bTvEnabled = true;
						break;
					}
				}
			}
    	}
	}
    return bTvEnabled;
}