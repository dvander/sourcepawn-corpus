#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"

public Plugin:myinfo =
{
	name		= "Change Weapon Size",
	author	  	= "Master Xykon",
	description = "Change the size of weapons.",
	version	 	= VERSION,
	url		 	= ""
};

public OnPluginStart()
{
	CreateConVar("sm_weaponsize_version", VERSION, "Change the Size of Weapons", FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_weaponsize", WeaponSize);
	RegConsoleCmd("sm_ws", WeaponSize);
}

public Action:WeaponSize(client, args)
{
	if(!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[WeaponSize] You must be alive");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		new String:cmdName[22];
		GetCmdArg(0, cmdName, sizeof(cmdName));
		ReplyToCommand(client, "[WeaponSize] Usage: %s #", cmdName);
		return Plugin_Handled;
	}
	
	new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new String:cmdArg[22];
	GetCmdArg(1, cmdArg, sizeof(cmdArg));
	new Float:fArg = StringToFloat(cmdArg);
	SetEntPropFloat(ClientWeapon, Prop_Send, "m_flModelScale", fArg);
	
	return Plugin_Handled;
}