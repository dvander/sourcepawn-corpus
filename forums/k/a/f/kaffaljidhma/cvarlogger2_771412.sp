#include <sourcemod>

public Plugin:myinfo =
{
  name = "cvar logger 2",
  author = "not bl4nk",
  description = "logs cvars and flags",
  version = "1.0.0",
  url = "http://forums.alliedmods.net/"
};


public OnPluginStart()
{
    RegAdminCmd("sm_logcvarsflags", Command_ListCvars, ADMFLAG_CHEATS);
}

public Action:Command_ListCvars(client, args)
{
    decl String:name[64], String:description[255], String:flag[64];
    new Handle:cvar, Handle:value, bool:isCommand, flags;
    //new counter = 1;
    cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags, description, sizeof(description));
    if (cvar == INVALID_HANDLE)
    {
        PrintToConsole(client, "Could not load cvar list");
        return Plugin_Handled;
    }
    do
    {
	value = FindConVar(name);
	/*
	LogToFileEx("name.txt", "%i: %s", counter, name);
	if(isCommand) {
		LogToFileEx("value.txt", "%i: cmd", counter);
	} else {
		LogToFileEx("value.txt", "%i: %f", counter, GetConVarFloat(value));
	}
	LogToFileEx("description.txt", "%i: %s", counter, description);
	*/
	
	flag = "";
	if(flags&FCVAR_CHEAT){flag="cheat ";}
	if(flags&FCVAR_NOTIFY){StrCat(flag, sizeof(flag), "notify ");}
	if(flags&FCVAR_PLUGIN){StrCat(flag, sizeof(flag), "plugin ");} 
	TrimString(flag);
	
	// the $ is to make it easier to parse out that crappy timestamp easily
	ReplaceString(description, sizeof(description), "\n", " ");
	ReplaceString(description, sizeof(description), "\t", " ");
	//ReplaceString(description, sizeof(description), "\"","")
	/*
	if(isCommand) {
		LogToFileEx("milo.txt", "$<command value=\"cmd\">%s</command><desc>%s</desc>", name, description);
	} else {
		LogToFileEx("milo.txt", "$<command value=\"%f\">%s</command><desc>%s</desc>", GetConVarFloat(value), name, description);
	}
	*/
	if(isCommand) {
		LogToFileEx("milo.txt", "$'%s'$cmd$'%s'$'%s'", name, flag, description);
	} else {
		LogToFileEx("milo.txt", "$'%s'$%f$'%s'$'%s'", name, GetConVarFloat(value), flag, description);
	}
	//counter++;
    } while (FindNextConCommand(cvar, name, sizeof(name), isCommand, flags, description, sizeof(description)));

    CloseHandle(cvar);
    return Plugin_Handled;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
