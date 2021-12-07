#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Change TF2 class",
	author = "GachL",
	description = "Changes the class of a player in TF2",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

public OnPluginStart()
{
	CreateConVar("sm_changeclass_version", PLUGIN_VERSION, "Change class version", FCVAR_PLUGIN|FCVAR_PROTECTED);
	new String:sMod[64];
	GetGameFolderName(sMod, sizeof(sMod));
	if (!StrEqual(sMod,"tf",false))
	{
		PrintToServer("[SM] Can not run Change TF2 class on this mod (%s). TF2 required!", sMod);
		return;
	}
	RegAdminCmd("sm_changeclass", Command_ChangeClass, ADMFLAG_KICK, "Change the class of a player in TF2");
}

public Action:Command_ChangeClass(client, args)
{
	new String:sUserId[32];
	new String:sTargetClass[32];
	if (!GetCmdArg(1, sUserId, sizeof(sUserId)))
	{
		PrintToChat(client, "Usage: sm_changeclass <userid> <classname>");
		return Plugin_Handled;
	}
	if (!GetCmdArg(2, sTargetClass, sizeof(sTargetClass)))
	{
		PrintToChat(client, "Usage: sm_changeclass <userid> <classname>");
		return Plugin_Handled;
	}
	
	new iUserId = StringToInt(sUserId);
	
	new target = GetClientOfUserId(iUserId);
	if (target < 1)
	{
		PrintToChat(client, "That user does not exist!");
		return Plugin_Handled;
	}
	if (!IsClientConnected(target))
	{
		PrintToChat(client, "That user does not exist!");
		return Plugin_Handled;
	}
	
	TF2_SetPlayerClass(target, TF2_GetClass(sTargetClass), true, true);
	TF2_RespawnPlayer(target);

	return Plugin_Handled;
}
