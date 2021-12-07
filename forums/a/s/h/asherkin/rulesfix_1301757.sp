#pragma semicolon 1

#include <sourcemod>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

public Plugin:myinfo = {
	name        = "RulesFix",
	author      = "Asher Baker (asherkin)",
	description = "Fixes the broken A2S_RULES implementation.",
	version     = "1.0",
	url         = "http://limetech.org/"
};

public Steam_FullyLoaded()
{
	RegAdminCmd("sm_fix", Command_FixRules, ADMFLAG_ROOT);
	FixDemRules();
}

public Action:Command_FixRules(client, args)
{
	FixDemRules();
}

public FixDemRules()
{
	Steam_ClearRules();
	
	decl String:name[64], String:value[256];
	new Handle:cvariter, bool:isCommand, flags;
	new Handle:cvar;

	cvariter = FindFirstConCommand(name, sizeof(name), isCommand, flags);
	if (cvariter == INVALID_HANDLE)
	{
		SetFailState("Could not load cvariter list");
		return;
	}

	do
	{
		if (isCommand || !(flags & FCVAR_NOTIFY))
		{
			continue;
		}
		
		cvar = FindConVar(name);
		GetConVarString(cvar, value, 256);
		
		if (!(flags & FCVAR_PROTECTED))
		{
			Steam_SetRule(name, value);
		} else {
			if (StrEqual(value, "", false))
			{
				Steam_SetRule(name, "0");
			} else {
				Steam_SetRule(name, "1");
			}
		}
		
		CloseHandle(cvar);
	} while (FindNextConCommand(cvariter, name, sizeof(name), isCommand, flags));

	CloseHandle(cvariter);
}