#include <sourcemod>

public Plugin:myinfo = 
{
  name = "cvar unlocker",
  author = "bail",
  description = "cvar unlocker",
  version = "1.0.0.0",
  url = "http://www.sourcemod.net/"
}; 

#if !defined FCVAR_DEVELOPMENTONLY
#define FCVAR_DEVELOPMENTONLY	(1<<1)
#endif

public OnPluginStart()
{
	decl String:name[64];
	new Handle:cvar, bool:isCommand, flags, Handle:convar;
	
	cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags);
	if (cvar == INVALID_HANDLE)
	{
		SetFailState("Could not load cvar list");
	}
	
	do
	{
		if (isCommand || !(flags & FCVAR_DEVELOPMENTONLY))
		{
			continue;
		}
		convar = FindConVar(name);
		flags &= ~FCVAR_DEVELOPMENTONLY;
		flags &= ~FCVAR_CHEAT;
		SetConVarFlags(convar, flags);
		PrintToServer("setting convar %s to %d", name, flags);
	} while (FindNextConCommand(cvar, name, sizeof(name), isCommand, flags));
	
	CloseHandle(cvar);
}