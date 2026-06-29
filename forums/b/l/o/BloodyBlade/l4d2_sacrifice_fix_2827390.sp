#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

/*=====================
        * Tag *
=======================*/
#define FS "[Sacrifice Fix]"
#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D2] Sacrifice Bug Fix",
	author = "raziEiL [disawar1]",
	description = "Sacrifice Bug Fix for survival mode",
	version = PLUGIN_VERSION,
	url = "www.27days-support.at.ua"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

/*=====================
	* PLUGIN START! *
=======================*/
public void OnPluginStart()
{		
	CreateConVar("sacrifice_fix_version", PLUGIN_VERSION, "Sacrifice Bug Fix plugin version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	//RegConsoleCmd("fx", CmdFix);
}

public void OnMapStart()
{
	ValidMode();
}

/*Action CmdFix(int client, int args)
{
	ValidMode();
	return Plugin_Handled;
}*/

void ValidMode()
{
	char mode[32], map[64];
	FindConVar("mp_gamemode").GetString(mode, sizeof(mode));
	if (StrEqual(mode, "survival", false))
	{
		LogMessage("%s Valid mode \"%s\"", FS, mode);
		GetCurrentMap(map, sizeof(map));
		if (StrEqual(map, "c7m1_docks", false) || StrEqual(map, "c7m3_port", false))
		{
			LogMessage("%s Valid map \"%s\"", FS, map);
			FindConVar("mp_restartgame").SetInt(1);
			LogMessage("%s Bug is fixed!", FS);
		}
		else LogMessage("%s Invalid map \"%s\"", FS, map);
	}
	else LogMessage("%s Invalid mode \"%s\"", FS, mode);
}
