#include <sourcemod>

public Plugin:myinfo =
{
  name = "locked cvar lister",
  author = "bl4nk",
  description = "lists locked cvars",
  version = "1.0.0",
  url = "http://forums.alliedmods.net/"
};

#if !defined FCVAR_DEVELOPMENTONLY
#define FCVAR_DEVELOPMENTONLY    (1<<1)
#endif

public OnPluginStart()
{
    RegAdminCmd("sm_llcvars", Command_ListCvars, ADMFLAG_CHEATS);
}

public Action:Command_ListCvars(client, args)
{
    decl String:name[64];
    decl String:desc[1024];
    decl String:val[64];
    new Handle:cvar, bool:isCommand, flags;

    cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags, desc, sizeof(desc));
    if (cvar == INVALID_HANDLE)
    {
        PrintToConsole(client, "Could not load cvar list");
        return Plugin_Handled;
    }

    do
    {
        if (isCommand || !(flags & FCVAR_DEVELOPMENTONLY))
        {
            continue;
        }

        GetConVarString(FindConVar(name), val, sizeof(val));

        if (strlen(desc) > 0) PrintToConsole(client, "%s (%s): %s", name, val, desc);
	else PrintToConsole(client, "%s (%s)", name, val);

    } while (FindNextConCommand(cvar, name, sizeof(name), isCommand, flags, desc, sizeof(desc)));

    CloseHandle(cvar);
    return Plugin_Handled;
}  
