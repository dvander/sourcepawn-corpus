#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

int    TimerUpdate;
char   file[PLATFORM_MAX_PATH], id_player[32];
Handle count = null;

public Plugin myinfo = 
{
	name = "[L4D] Team Restarts Server.",
	author = "AlexMy",
	description = "",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?p=2548680#post2548680"
};

public void OnPluginStart()
{
	LoadTranslations("l4d_restart.phrases");
	
	count = CreateConVar("l4d_restart_time", "11", "Через сколько секунд сервер перезагрузится", FCVAR_NOTIFY);
	
	RegAdminCmd("sm_restart", sm_restart, ADMFLAG_GENERIC);
	RegAdminCmd("sm_rst",     sm_restart, ADMFLAG_GENERIC);
}
public Action sm_restart(int client, int args)
{
	if(client)
	{
		TimerUpdate = GetConVarInt(count);
		CreateTimer(1.0, timer_start, _, TIMER_REPEAT);
		GetClientName(client, id_player, sizeof(id_player));
		BuildPath(Path_SM, file, sizeof(file), "logs/restart_server.log");
		LogToFileEx(file, "Admin %s rebooted the server", id_player);
		PrintToChat(client, "%t", "admin_warning", id_player);
	}
	return Plugin_Handled;
}
public Action timer_start(Handle timer)
{
	TimerUpdate --;
	if(TimerUpdate > 0)
	{
		PrintHintTextToAll("%t", "countdown_timer", TimerUpdate);
		return Plugin_Continue;
	}
	CreateTimer(0.5, restart_server, _, PrintHintTextToAll("%t", "warning_restart"));
	return Plugin_Stop;
}
public Action restart_server(Handle timer)
{
	ServerCommand("exit");
	return Plugin_Stop;
}