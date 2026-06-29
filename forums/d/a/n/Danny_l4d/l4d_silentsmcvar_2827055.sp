/* Includes */
#include <sourcemod>

/* Plugin Information */
public Plugin:myinfo = 
{
	name		= "Silent sm_cvar",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Allows rcon to change any convar without triggering show activity.",
	version		= "1.1.0",
	url		= "mrzerodk@gmail.com"
}

/* Plugin Functions */
public OnPluginStart()
{
	LoadTranslations("common.phrases")
	LoadTranslations("plugin.basecommands")
	
	RegAdminCmd("sm_silentcvar", Command_SilentCvar, ADMFLAG_ROOT, "sm_silentcvar <cvar> <value>")
	RegAdminCmd("sm_silentresetcvar", Command_SilentResetCvar, ADMFLAG_ROOT, "sm_silentresetcvar <cvar>")
}

public Action:Command_SilentCvar(client, args)
{
	if (client != 0)
	{
		return Plugin_Handled
	}
	
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_silentcvar <cvar> <value>")
		return Plugin_Handled
	}
	
	decl String:cvarname[64]
	GetCmdArg(1, cvarname, sizeof(cvarname))
	
	new Handle:hndl = FindConVar(cvarname)
	if (hndl == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] %t", "Unable to find cvar", cvarname)
		return Plugin_Handled
	}
	
	decl String:value[255]
	GetCmdArg(2, value, sizeof(value))
	
	SetConVarString(hndl, value)
	return Plugin_Handled
}

public Action:Command_SilentResetCvar(client, args)
{
	if (client != 0)
	{
		return Plugin_Handled
	}
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_silentresetcvar <cvar>")

		return Plugin_Handled
	}

	decl String:cvarname[64]
	GetCmdArg(1, cvarname, sizeof(cvarname))
	
	new Handle:hndl = FindConVar(cvarname)
	if (hndl == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] %t", "Unable to find cvar", cvarname)
		return Plugin_Handled
	}

	ResetConVar(hndl)

	return Plugin_Handled
}