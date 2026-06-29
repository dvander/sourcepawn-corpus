
#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = 
{
  name = "show all executed commands",
  author = "seather",
  description = "debug plugin, displays on the server console all commands sent by everyone",
  version = "0.0.1",
  url = "http://www.sourcemod.net/"
}; 


public OnPluginStart()
{
	HookAll(1);

	CreateTimer(0.5, TimerHook);
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
		
	} while (FindNextConCommand(cvar, name, sizeof(name), isCommand, flags));
	
	//useless statistic
	PrintToServer("[show command] Number of hooked commands: %d", commandCount);

	CloseHandle(cvar);
}

//hooked in OnPluginStart
public Action:Command_All(client, args)
{
	decl String:cmdname[128];
	GetCmdArg(0, cmdname, sizeof(cmdname));
	decl String:argstr[128];
	GetCmdArgString(argstr, sizeof(argstr));
	
	PrintToServer("[show method 1] <%i> %s %s", client, cmdname, argstr);
	
	return Plugin_Continue;
}

//hooked in OnPluginStart with server hook
public Action:Command_SV(args)
{
	decl String:cmdname[128];
	GetCmdArg(0, cmdname, sizeof(cmdname));
	decl String:argstr[128];
	GetCmdArgString(argstr, sizeof(argstr));
	
	PrintToServer("[show method 4] <-> %s %s", cmdname, argstr);
	
	return Plugin_Continue;
}

//hooked after timer
public Action:Command_All2(client, args)
{
	decl String:cmdname[128];
	GetCmdArg(0, cmdname, sizeof(cmdname));
	decl String:argstr[128];
	GetCmdArgString(argstr, sizeof(argstr));
	
	PrintToServer("[show method 3] <%i> %s %s", client, cmdname, argstr);
	
	return Plugin_Continue;
}



//forwarded from else where
//http://wiki.alliedmods.net/Commands_(SourceMod_Scripting)#Client-Only_Commands
public Action:OnClientCommand(client, args)
{
	decl String:cmdname[128];
	GetCmdArg(0, cmdname, sizeof(cmdname));
	decl String:argstr[128];
	GetCmdArgString(argstr, sizeof(argstr));
	
	PrintToServer("[show method 2] <%i> %s %s", client, cmdname, argstr);

	return Plugin_Continue;
}

