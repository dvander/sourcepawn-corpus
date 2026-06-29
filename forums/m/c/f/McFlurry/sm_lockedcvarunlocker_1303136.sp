#include <sourcemod>

public Plugin:myinfo =
{
	name = "Locked Cvar Unlocker",
	author = "bl4nk(Small edit by McFlurry)",
	description = "lists locked cvars",
	version = "1.0.1",
	url = "http://forums.alliedmods.net/"
};

public OnMapStart()
{
	decl String:name[64];
	new Handle:cvar, bool:isCommand, flags;
	cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags);
	if (cvar == INVALID_HANDLE)
	{
		return;
	}	
	do
	{
		if(isCommand || !(flags & FCVAR_LAUNCHER))
		{
			continue;
		}
		SetCommandFlags(name, flags & ~FCVAR_LAUNCHER);
	} while(FindNextConCommand(cvar, name, sizeof(name), isCommand, flags));
	{
		SetCommandFlags(name, flags & ~FCVAR_LAUNCHER);
	}	
	CloseHandle(cvar);
} 