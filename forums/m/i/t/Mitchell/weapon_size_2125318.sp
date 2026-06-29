#include <sourcemod>
#include <sdktools>
#include <regex>

#define VERSION "1.0.1d"

new Handle:g_FloatRegex;

public Plugin:myinfo =
{
	name		= "Change Weapon Size",
	author	  	= "Master Xykon, Mitch",
	description = "Change the size of weapons.",
	version	 	= VERSION,
	url		 	= ""
};

public OnPluginStart()
{
	CreateConVar("sm_weaponsize_version", VERSION, "Change the Size of Weapons", FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_weaponsize", WeaponSize);
	RegConsoleCmd("sm_ws", WeaponSize);
	//Checks to see if string is: an int, negative int, only one period, if negative then only one dash
	g_FloatRegex = CompileRegex("^[-+]?([0-9]+\\.[0-9]+|[0-9]+)");
}

public Action:WeaponSize(client, args)
{
	if(client <= 0)
		return Plugin_Handled;
	if(!IsClientInGame(client))
		return Plugin_Handled;
		
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[WeaponSize] You must be alive to use this command");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		new String:cmdName[22];
		GetCmdArg(0, cmdName, sizeof(cmdName));
		ReplyToCommand(client, "[WeaponSize] Usage: %s #", cmdName);
		return Plugin_Handled;
	}
	else
	{
		new String:cmdArg[22];
		GetCmdArg(1, cmdArg, sizeof(cmdArg));
		new RegexError:ret = REGEX_ERROR_NONE;
		MatchRegex(g_FloatRegex, cmdArg, ret);
		if(ret != REGEX_ERROR_NONE)
		{
			ReplyToCommand(client, "[WeaponSize] Invalid size input");
			return Plugin_Handled;
		}
		new Float:fArg = StringToFloat(cmdArg);
		if(fArg == 0.0)
		{
			ReplyToCommand(client, "[WeaponSize] Must be not be 0!");
			return Plugin_Handled;
		}
		new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEntity(ClientWeapon))
		{
			ReplyToCommand(client, "[WeaponSize] Unable to find active weapon.");
			return Plugin_Handled;
		}
		SetEntPropFloat(ClientWeapon, Prop_Send, "m_flModelScale", fArg);
	}
	return Plugin_Handled;
}