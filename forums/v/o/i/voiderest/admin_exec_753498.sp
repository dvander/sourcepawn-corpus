#include <sourcemod>
#pragma semicolon 1
#define VERSION "0.9"

public Plugin:myinfo = {
	name = "Admin Exec",
	author = "Voiderest",
	description = "Runs a cfg while bypassing sv_cheats.",
	version = VERSION,
	url = "N/A"
}

public OnPluginStart() {
	RegAdminCmd("admin_exec", cmdAdminExec, ADMFLAG_CONFIG, "Runs a cfg while bypassing sv_cheats");
}

public Action:cmdAdminExec(client, args)
{
	new String:arg1[32];
	new String:buffer[46];
	new String:path[PLATFORM_MAX_PATH];

	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));
	
	Format(buffer, sizeof(buffer), "../../cfg/%s.cfg", arg1);
	
	BuildPath(Path_SM, path, sizeof(path), buffer);
	
	if (!FileExists(path))
	{
		return Plugin_Continue;
	}
	new Handle:file = OpenFile(path, "r");
	while (!IsEndOfFile(file))
	{
		new String:line[512];
		if (!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}
		parseline(line);
	}
	CloseHandle(file);
	
	return Plugin_Continue;
}

parseline(String:line[])
{
	//PrintToServer("line: %s",line);
	new String:print[512];
	
	TrimString(line);
	if (strlen(line) == 0 || (line[0] == '/' && line[1] == '/'))
	{
		return;
	}
	
	new bool:quote=false;
	for (new i = 0; i < strlen(line); i++)
	{
		if (line[i] == '"')
		{
			quote=!quote;
		}
		if (i==0 && line[i] == ';')
		{
			line[i]=' ';
		}
		if (line[i] == '/' && line[i+1] == '/')
		{
			TrimString(print);
			break;
		}
		if (line[i] == ';' && !quote)
		{
			TrimString(print);
			if (strlen(print) == 0)
			{
				return;
			}
			ServerCommand("sm_cvar %s",print);
			ReplaceString(line, strlen(line), print, "");
			parseline(line);
			return;
		}
		print[i]=line[i];
		//PrintToServer("%d: %s",i,print);
		//PrintToServer("debug: %c - %c",line[i],print[i]);
	}
	
	TrimString(print);
	if (strlen(print) == 0)
	{
		return;
	}
	ServerCommand("sm_cvar %s",print);
}
