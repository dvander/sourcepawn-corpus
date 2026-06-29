#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "tv_record demoname fix",
	author = "otstrel.ru team",
	description = "",
	version = "0.1",
	url = "http://otstrel.ru/"
};
 
new Handle:g_cvar_demoname_format;

public OnPluginStart()
{
	g_cvar_demoname_format=CreateConVar("sm_tvrecord_format", "%Y%m%d-%H%M-%map-%name", "See FormatTime for date/time syntax, use placeholders %map for mapname and %name for user-supplied demoname", FCVAR_PLUGIN|FCVAR_NOTIFY);

	RegAdminCmd("tv_record", Command_TvRecord, ADMFLAG_RCON);
}

new bool:g_bInTvRecord=false;

public Action:Command_TvRecord(client, args)
{
	if(g_bInTvRecord || args<1)
	{
		g_bInTvRecord=false;
		return Plugin_Continue;
	}
	
	g_bInTvRecord=true;

	decl String:demoname[128];
	GetCmdArg(1, demoname, sizeof(demoname));

	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	
	decl String:fmt[512];
	GetConVarString(g_cvar_demoname_format, fmt, sizeof(fmt));
	
	ReplaceString(fmt, sizeof(fmt), "%name", demoname, false);
	ReplaceString(fmt, sizeof(fmt), "%map", mapname, false);

	decl String:name[512];
	FormatTime(name, sizeof(name), fmt);

	ServerCommand("tv_record %s", name); 
	
	return Plugin_Handled;
}
