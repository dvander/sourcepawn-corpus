/*Pragmas*/
#pragma semicolon 1
#pragma newdecls required

/* Includes */
#include <sourcemod>

/* Plugin Information */
public Plugin myinfo = 
{
	name		= "Silent sm_cvar",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Allows rcon to change any convar without triggering show activity.",
	version		= "1.1.0",
	url		= "mrzerodk@gmail.com"
}

/* Plugin Functions */
public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");

	RegAdminCmd("sm_silentcvar", Command_SilentCvar, ADMFLAG_ROOT, "sm_silentcvar <cvar> <value>");
	RegAdminCmd("sm_silentresetcvar", Command_SilentResetCvar, ADMFLAG_ROOT, "sm_silentresetcvar <cvar>");
}

Action Command_SilentCvar(int client, int args)
{
	if (client != 0)
	{
		return Plugin_Handled;
	}

	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_silentcvar <cvar> <value>");
		return Plugin_Handled;
	}

	char cvarname[64];
	GetCmdArg(1, cvarname, sizeof(cvarname));
	ConVar hndl = FindConVar(cvarname);
	if (hndl == null)
	{
		ReplyToCommand(client, "[SM] %t", "Unable to find cvar", cvarname);
		return Plugin_Handled;
	}

	char value[255];
	GetCmdArg(2, value, sizeof(value));
	hndl.SetString(value);
	return Plugin_Handled;
}

Action Command_SilentResetCvar(int client, int args)
{
	if (client != 0)
	{
		return Plugin_Handled;
	}

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_silentresetcvar <cvar>");
		return Plugin_Handled;
	}

	char cvarname[64];
	GetCmdArg(1, cvarname, sizeof(cvarname));
	ConVar hndl = FindConVar(cvarname);
	if (hndl == null)
	{
		ReplyToCommand(client, "[SM] %t", "Unable to find cvar", cvarname);
		return Plugin_Handled;
	}

	hndl.RestoreDefault();

	return Plugin_Handled;
}
