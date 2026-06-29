#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#pragma semicolon 1

/*=====================
        * Tag *
=======================*/
#define FS		  "[Sacrifice Fix]"

public Plugin:myinfo =
{
	name = "[L4D2] Sacrifice Bug Fix",
	author = "raziEiL [disawar1]",
	description = "Sacrifice Bug Fix for survival mode",
	version = PLUGIN_VERSION,
	url = "www.27days-support.at.ua"
}

/*=====================
	* PLUGIN START! *
=======================*/
public OnPluginStart()
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead2", false)) 
		SetFailState("Plugin only supports Left4Dead 2.");
		
	CreateConVar("sacrifice_fix_version", PLUGIN_VERSION, "Sacrifice Bug Fix plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//RegConsoleCmd("fx", CmdFix);
}

public OnMapStart()
{
	ValidMode();
}

public Action:CmdFix(client, args)
{
	ValidMode();
}

public ValidMode()
{
	decl String:mode[32];
	new	Handle:g_Mode=FindConVar("mp_gamemode");
	GetConVarString(g_Mode, mode, sizeof(mode));
	
	if (strcmp(mode, "survival") == 0){
		LogMessage("%s Valid mode \"%s\"", FS, mode);
		ValidMap();
	}
	else LogMessage("%s Invalid mode \"%s\"", FS, mode);
}

public ValidMap()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	if (strcmp(map, "c7m1_docks") == 0 ||
		strcmp(map, "c7m3_port") == 0)
	{
		LogMessage("%s Valid map \"%s\"", FS, map);
		new Handle:g_Rest=FindConVar("mp_restartgame");
		SetConVarInt(g_Rest, 1);
		LogMessage("%s Bug is fixed!", FS);
	}
	else LogMessage("%s Invalid map \"%s\"", FS, map);
}