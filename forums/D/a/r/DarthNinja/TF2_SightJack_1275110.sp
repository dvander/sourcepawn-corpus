#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.5"

public Plugin:myinfo = {
    name = "[TF2] Sight Jacker (Spectate)",
    author = "DarthNinja",
    description = "A rudimentary sight-jacker",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
};

 
public OnPluginStart()
{

	/* Check Game */
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(StrEqual(game, "tf"))
	{
		LogMessage("Sight-Jacker Active.");
	}
	else
	{
		SetFailState("Team Fortress 2 Only.");
	}

	CreateConVar("sm_sightjacker_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	RegAdminCmd("sm_sightjack", Cmd_Jax, ADMFLAG_BAN);
	RegAdminCmd("sm_unjack", Cmd_UnJax, ADMFLAG_BAN);
	RegAdminCmd("sm_tauntjack", Cmd_Stun, ADMFLAG_BAN);
	
	LoadTranslations("common.phrases");
}

public Action:Cmd_Stun(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_tauntjack <duration> - Stuns you so you can sight-jack in thirdperson view");
		return Plugin_Handled;
	}

	decl String:buffer[64];
	new Float:duration = 0.0;
	GetCmdArg(1, buffer, sizeof(buffer));
	duration = StringToFloat(buffer);
	TF2_StunPlayer(client, duration, _, 96, 0);
	return Plugin_Handled;
}


public Action:Cmd_Jax(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_sightjack <target> <slot>");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	GetCmdArg(1,arg1,sizeof(arg1));
	new  target = FindTarget(client, arg1);
	new String:arg2[32];
	GetCmdArg(2,arg2,sizeof(arg2));
	new slot = StringToInt(arg2);
	
	new weaponEnt = GetPlayerWeaponSlot(target, slot)
	
	if(IsValidEntity(weaponEnt))
	{
		//Set view
		//SetClientViewEntity(client,target)
		SetClientViewEntity(client, weaponEnt)
		LogAction(client, target, "[SJ] %L started sight-jacking %L.", client, target);
	}
	return Plugin_Handled;
}

public Action:Cmd_UnJax(client, args)
{
	if (args != 0)
	{
		ReplyToCommand(client, "Usage: sm_unjack - Returns your view to normal");
		return Plugin_Handled;
	}
	
	//Set view
	TF2_StunPlayer(client, 0.0, _, 96, 0);
	SetClientViewEntity(client,client)
	LogAction(client, -1, "[SJ] %L stopped sight-jacking.", client);
	
	return Plugin_Handled;
}
