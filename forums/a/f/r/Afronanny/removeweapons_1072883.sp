#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "Weapon Stripper",
	author = "Afronanny",
	description = "Strip A Player of all weapons",
	version = "1.0",
	url = "http://afronanny.com"
}

public OnPluginStart()
{
	
	RegAdminCmd("sm_stripweapons", Command_StripWeapons, ADMFLAG_SLAY);
	
}

public Action:Command_StripWeapons(client, args)
{
	decl String:arg1[128];
	new target;
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_stripweapons <player>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	target = FindTarget(client, arg1);
	
	if (IsClientInGame(target) && IsPlayerAlive(target))
	{
		TF2_RemoveAllWeapons(target);
	} else {
		ReplyToCommand(client, "[SM] Player is not in-game or is not alive.");
		return Plugin_Handled;
	}
	
	decl String:targetname[128];
	GetClientName(target, targetname, sizeof(targetname));
	
	ReplyToCommand(client, "[SM] Removed all of %s's weapons", targetname);
	return Plugin_Handled;
}
	

