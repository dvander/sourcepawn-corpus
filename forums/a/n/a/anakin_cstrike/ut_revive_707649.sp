#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "Ultimate Revive",
	author = "anakin_cstrike",
	description = "Revive with x hp, armor",
	version = "1.0",
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_revive", revive_cmd, ADMFLAG_KICK);
}

public Action:revive_cmd(client, args)
{
	new String:arg[32], String:arg2[4], String:arg3[4];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	
	new hp, armor;
	new target = FindTarget(client, arg);
	
	if(target == -1)
		return Plugin_Handled;
	if(IsPlayerAlive(target))
	{
		ReplyToCommand(client, "Player is allready alive!");
		return Plugin_Handled;
	}
	
	if(args < 2) { hp = 100; armor = 0; }
	else if(args == 3) { hp = StringToInt(arg2); armor = 0; }
	else { hp = StringToInt(arg2); armor = StringToInt(arg3); }
	
	new String: name[32], String: namet[32];
	GetClientName(client, name, sizeof(name));
	GetClientName(target, namet, sizeof(namet));
	
	CS_RespawnPlayer(target);
	SetEntityHealth(target, hp);
	SetEntityArmor(target, armor);
	
	ReplyToCommand(client, "You have revive '%s'",namet);
	PrintToChatAll("Admin %s: Revive player '%s' with %i hp and %i armor",name, name, hp, armor);
	
	return Plugin_Handled;
}

// thanks SAMURAI
stock SetEntityArmor(index, ammount)
{
	return SetEntProp(index, Prop_Data, "m_ArmorValue", ammount);
}