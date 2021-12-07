
#pragma semicolon 1
#include <sourcemod>

//based on "cvar unlocker" by "bail"
public Plugin:myinfo = 
{
  name = "less sv cheats",
  author = "seather",
  description = "Blocks sv_cheats commands, allows sv_cheats client cvars",
  version = "0.0.1",
  url = "http://www.sourcemod.net/"
}; 

new Handle:sm_lesscheats = INVALID_HANDLE;

public OnPluginStart()
{

	sm_lesscheats = CreateConVar("sm_lesscheats", "1", "Blocks sv_cheats commands, allows sv_cheats client cvars", 0, true, 0.0, true, 1.0);

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
		//get rid of cvars and non cheats
		if (!isCommand || !(flags & FCVAR_CHEAT))
		{
			continue;
		}
		commandCount++;
		
		//PrintToServer("blocking cheat command %s", name);
		//LogMessage("blocking cheat command %s", name);
		
		//Hook Command
		RegConsoleCmd(name, Command_Block);
		
	} while (FindNextConCommand(cvar, name, sizeof(name), isCommand, flags));
	
	//useless statistic
	PrintToServer("[less sv cheats] Number of blocked cheat commands: %d", commandCount);

	CloseHandle(cvar);
}


public Action:Command_Block(client, args)
{
	if(GetConVarInt(sm_lesscheats) == 0)
	{
		//Do not Block
		PrintToConsole(client,"[LC] Not Blocked.");
		return Plugin_Continue;
	}
	
	//Block command
	PrintToConsole(client,"[LC] Cheat Blocked.");
	return Plugin_Handled;
}

