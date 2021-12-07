#define VERSION "1.0"
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "cp configs",
	author = "Goerge",
	description = "Executes configs based on cp attack/defend or push type",
	version = VERSION,
	url = "http://www.fpsbanana.com"
};

public OnPluginStart()
{
	CreateConVar("cpconfig_version", VERSION, "CP Config Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnConfigsExecuted()
{
	new iEnt = -1, String:mapname[32], bool:attackPoint = false;
	GetCurrentMap(mapname, sizeof(mapname));
	if (strncmp(mapname, "cp_", 3, false) == 0)
	{
		decl String:path[120];
		new iTeam;
		while ((iEnt = FindEntityByClassname(iEnt, "team_control_point")) != -1)
		{
			iTeam = GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
			/**
			* If there is a blu CP or a neutral CP, then it's not an attack/defend map
			*
			**/
			if (iTeam != 2)
			{
				attackPoint = true;
				BuildPath(Path_SM, path, sizeof(path), "configs/mapscfg/cp_push.cfg");
				break;
			}
		}
		if (!attackPoint)
			BuildPath(Path_SM, path, sizeof(path), "configs/mapscfg/cp_attackdefend.cfg");
		if(FileExists(path))
			readFile(path);
	}
}

readFile(const String:file[])
{
	new Handle:hConfig = OpenFile(file, "r");
	new String:command[128];
	if(hConfig == INVALID_HANDLE)	
		return;
	while(!IsEndOfFile(hConfig) && ReadFileLine(hConfig, command, sizeof(command)))	
		ServerCommand("%s", command);
	CloseHandle(hConfig);
}
