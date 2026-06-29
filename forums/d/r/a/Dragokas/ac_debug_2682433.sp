#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "Debugging",
	description = "",
	author = "Aircraft(diller110)",
	version = "1.0",
	url = ""
};

// Modified by Dragokas
/*
	Commands:
	
	 - sm_debug - Start / stop debug tracing
	 
	Logfile:
	
	 - addons/sourcemod/logs/debug_<TIME>.txt

*/

char path[PLATFORM_MAX_PATH];
ConVar ConVar_LogFile;

public void OnPluginStart()
{
	RegAdminCmd("sm_debug", Cmd_Debug, ADMFLAG_ROOT, "Start / stop debug tracing");
	BuildPath(Path_SM, path, sizeof(path), "logs/debug_");
	ConVar_LogFile = FindConVar("con_logfile");
}

public Action Cmd_Debug(int client, int args)
{
	static bool start;
	
	if (!start)
	{
		PrintToChat(client, "\x04[DEBUG]\x05 Starting debug... Do something.");
		ServerCommand("sm prof start");
		ServerExecute();
		
	}
	else
	{
		char origpath[256];
		char newpath[512];
		ConVar_LogFile.GetString(origpath, sizeof(origpath));
		Format(newpath, sizeof(newpath), "%s%d.txt", path, GetTime());
		ServerCommand("sm prof stop; con_logfile \"%s\"; sm prof dump vprof; con_logfile \"%s\";", newpath, origpath);
		ServerExecute();
		PrintToChat(client, "\x04[DEBUG]\x05 Results are saved to: %s", newpath);
	}
	start = !start;
	return Plugin_Handled;
}
