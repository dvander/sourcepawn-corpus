#include <sourcemod>

//new Handle:logFile = INVALID_HANDLE
new String:logPath[80]

public Plugin:myinfo = 
{
	name = "Show all executed commands",
	author = "seather, TESLA-X4",
	description = "Debugging plugin that logs all commands sent by all clients",
	version = "1.0.3",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookAll(1);
	
	CreateTimer(0.5, TimerHook);
	ManageFile()
	LogToFile(logPath, "");
	LogToFile(logPath, "-------- [The server may have crashed or been restarted prior to this point] --------");
	LogToFile(logPath, "");
}

public OnMapStart()
{
	ManageFile()
	decl String:currentMap[64];
	GetCurrentMap(currentMap, 64);
	LogToFile(logPath, "");
	LogToFile(logPath, "-------- Mapchange to %s --------", currentMap);
	LogToFile(logPath, "");
}

/*
public OnMapEnd()
{
	CloseHandle(logFile)
}
*/

public ManageFile()
{
	decl String:date[9]
	FormatTime(date, sizeof(date), "%Y%m%d", GetTime())
	Format(logPath, sizeof(logPath), "addons/sourcemod/logs/execcmds_%s.log", date)
	//PrintToServer("logPath: %s", logPath)
	//PrintToServer("date: %s", date)
	//if (!FileExists(logPath))
	//{
		// create it
		
		// http://www.cplusplus.com/reference/clibrary/cstdio/fopen/
		//logFile = OpenFile(logPath, "w");
		//OpenFile(logPath, "w");
	//}
}

public Action:TimerHook(Handle:timer) //, any:client
{
	HookAll(2);
}

HookAll(mode)
{
	decl String:name[64];
	new Handle:cvar, bool:isCommand, flags;
	new commandCount = 0;
	
	//Fetch first command
	cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags);
	if (cvar == INVALID_HANDLE)
	{
		SetFailState("Could not load cvar list");
	}
	
	//Process + get more loop
	do
	{
		//get rid of cvars
		if (!isCommand)
		{
			continue;
		}
		commandCount++;
		
		//PrintToServer("[show command] hook: %s", name);
		
		//Hook Command
		if(mode == 1) {
			RegConsoleCmd(name, Command_All);
			RegServerCmd(name, Command_SV);
		}
		if(mode == 2)
			RegConsoleCmd(name, Command_All2);
		
	}
	while (FindNextConCommand(cvar, name, sizeof(name), isCommand, flags));
	
	//useless statistic
	PrintToServer("[show command] Number of hooked commands: %d", commandCount);

	CloseHandle(cvar);
}

//hooked in OnPluginStart
public Action:Command_All(client, args)
{
	if (client > 0)
	{
		decl String:cmdname[128];
		GetCmdArg(0, cmdname, sizeof(cmdname));
		decl String:argstr[128];
		GetCmdArgString(argstr, sizeof(argstr));
		
		decl String:steamid[64];
		decl String:ip[32];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		GetClientIP(client, ip, sizeof(ip));
		
		//PrintToServer("[show method 1] <%i> %s %s", client, cmdname, argstr);
		//LogToFile("addons/sourcemod/logs/executedcommands.log", "[show method 1] <%i> %s %s", client, cmdname, argstr);
		LogToFile(logPath, "[show method 1] \"%N<%s><%s>\" ran \"%s %s\"", client, steamid, ip, cmdname, argstr);
	}
	return Plugin_Continue;
}

//hooked in OnPluginStart with server hook
public Action:Command_SV(args)
{
	decl String:cmdname[128];
	GetCmdArg(0, cmdname, sizeof(cmdname));
	decl String:argstr[128];
	GetCmdArgString(argstr, sizeof(argstr));
	
	//PrintToServer("[show method 4] <-> %s %s", cmdname, argstr);
	//LogToFile("addons/sourcemod/logs/executedcommands.log", "[show method 4] <-> %s %s", cmdname, argstr);
	LogToFile(logPath, "[show method 4] <-> %s %s", cmdname, argstr);
	
	return Plugin_Continue;
}

//hooked after timer
public Action:Command_All2(client, args)
{
	if (client > 0)
	{
		decl String:cmdname[128];
		GetCmdArg(0, cmdname, sizeof(cmdname));
		decl String:argstr[128];
		GetCmdArgString(argstr, sizeof(argstr));
		
		decl String:steamid[64];
		decl String:ip[32];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		GetClientIP(client, ip, sizeof(ip));
		
		//PrintToServer("[show method 3] <%i> %s %s", client, cmdname, argstr);
		//LogToFile("addons/sourcemod/logs/executedcommands.log", "[show method 3] <%i> %s %s", client, cmdname, argstr);
		LogToFile(logPath, "[show method 3] \"%N<%s><%s>\" ran \"%s %s\"", client, steamid, ip, cmdname, argstr);
	}
	return Plugin_Continue;
}

//forwarded from elsewhere
//http://wiki.alliedmods.net/Commands_(SourceMod_Scripting)#Client-Only_Commands
public Action:OnClientCommand(client, args)
{
	if (client > 0)
	{
		decl String:cmdname[128];
		GetCmdArg(0, cmdname, sizeof(cmdname));
		decl String:argstr[128];
		GetCmdArgString(argstr, sizeof(argstr));
		
		decl String:steamid[64];
		decl String:ip[32];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		GetClientIP(client, ip, sizeof(ip));
		
		//PrintToServer("[show method 2] <%i> %s %s", client, cmdname, argstr);
		//LogToFile("addons/sourcemod/logs/executedcommands.log", "[show method 2] <%i> %s %s", client, cmdname, argstr);
		LogToFile(logPath, "[show method 2] \"%N<%s><%s>\" ran \"%s %s\"", client, steamid, ip, cmdname, argstr);
	}
	return Plugin_Continue;
}
