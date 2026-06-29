#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#define PLUGIN_VERSION "1.4.4.7"


new Handle:defaultTime;
new Handle:playerTime;
new Handle:allowSelfstun;

public Plugin:myinfo =
{
	name = "[TF2] Stunmod",
	author = "DarthNinja",
	description = "Stun, scare, and bonk players!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{	
	RegAdminCmd("sm_stun", Cmd_Stun, ADMFLAG_SLAY, "Use 'endround' type stun on a player");
	RegAdminCmd("sm_gstun", Cmd_GhostStun, ADMFLAG_SLAY, "Use 'ghost' type stun on a player");
	RegAdminCmd("sm_scare", Cmd_GhostStun, ADMFLAG_SLAY, "Use 'ghost' type stun on a player");
	RegAdminCmd("sm_ghost", Cmd_GhostStun, ADMFLAG_SLAY, "Use 'ghost' type stun on a player");
	RegAdminCmd("sm_bonk", Cmd_Bonk, ADMFLAG_SLAY, "Use 'Bonk!' type stun on a player");
		
	RegConsoleCmd("sm_stunme", Cmd_StunMe, "Stuns you!");
	RegConsoleCmd("sm_gstunme", Cmd_GhostStunMe, "Ghost-stuns you!");
	RegConsoleCmd("sm_scareme", Cmd_GhostStunMe, "Ghost-stuns you!");
	RegConsoleCmd("sm_ghostme", Cmd_GhostStunMe, "Ghost-stuns you!");
	RegConsoleCmd("sm_bonkme", Cmd_BonkMe, "Bonks you!");
	
	CreateConVar("sm_stunmod_version", PLUGIN_VERSION, "Stunmod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	allowSelfstun = CreateConVar("sm_stunmod_selfstun", "0", "Allow players to stun themselves? 1/0", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	defaultTime = CreateConVar("sm_stunmod_cmd_timer", "5","Number of seconds to stun a player for if not specified.");
	playerTime = CreateConVar("sm_stunmod_player_timer", "5","Number of seconds for a player to stun themselves.");
	
	LoadTranslations("common.phrases");
}

public Action:Cmd_Stun(client, args)
{
	if (args != 1 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_stun <target> [duration]");
		return Plugin_Handled;
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float:duration = 0.0;
	if (args == 2)
	{
		GetCmdArg(2, buffer, sizeof(buffer));
		duration = StringToFloat(buffer);
	}
	else
		 duration = GetConVarFloat(defaultTime);
	
	for (new i = 0; i < target_count; i ++)
	{
		//TF2_StunPlayer(target_list[i], duration, _, 96, 0);
		TF2_StunPlayer(target_list[i], duration, _, TF_STUNFLAGS_LOSERSTATE, 0);
		LogAction(client, target_list[i], "\"%L\" stunned \"%L\" ", client, target_list[i]);
	}
	ShowActivity2(client, "[SM] ","Stunned '%s'.", target_name);
	return Plugin_Handled;
}

public Action:Cmd_GhostStun(client, args)
{
	if (args != 1 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_gstun <target> [duration]");
		return Plugin_Handled;
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float:duration = 0.0;
	if (args == 2)
	{
		GetCmdArg(2, buffer, sizeof(buffer));
		duration = StringToFloat(buffer);
	}
	else
		 duration = GetConVarFloat(defaultTime);
	
	for (new i = 0; i < target_count; i ++)
	{
		TF2_StunPlayer(target_list[i], duration, _, TF_STUNFLAGS_GHOSTSCARE, 0);
		LogAction(client, target_list[i], "\"%L\" ghost-stunned \"%L\" ", client, target_list[i]);
	}
	ShowActivity2(client, "[SM] ","Ghost-Stunned '%s'.", target_name);
	return Plugin_Handled;
}

public Action:Cmd_Bonk(client, args)
{
	if (args < 1 || args > 3)
	{
		ReplyToCommand(client, "Usage: sm_bonk <target> [duration] [bonk type]");
		return Plugin_Handled;
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float:duration = 0.0;
	if (args > 1)
	{
		GetCmdArg(2, buffer, sizeof(buffer));
		duration = StringToFloat(buffer);
	}
	else
		 duration = GetConVarFloat(defaultTime);
	
	new StunFlag = TF_STUNFLAGS_BIGBONK;
	if (args > 2)
	{
		GetCmdArg(3, buffer, sizeof(buffer));		
		switch (StringToInt(buffer))
		{
			case 1:
				StunFlag = TF_STUNFLAGS_SMALLBONK;
			case 2:
				StunFlag = TF_STUNFLAGS_NORMALBONK;
			case 3:
				StunFlag = TF_STUNFLAGS_BIGBONK;
			default:
				StunFlag = TF_STUNFLAGS_BIGBONK;
		}
	}
	
	for (new i = 0; i < target_count; i ++)
	{
		TF2_StunPlayer(target_list[i], duration, 0.0, StunFlag, 0);
		LogAction(client, target_list[i], "\"%L\" bonked \"%L\" ", client, target_list[i]);
	}
	ShowActivity2(client, "[SM] ","Bonked '%s'.", target_name);
	return Plugin_Handled;
}

public Action:Cmd_StunMe(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_stunme [duration]");
		return Plugin_Handled;
	}
	if (!GetConVarBool(allowSelfstun))
	{
		ReplyToCommand(client, "This command is disabled!");
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You are dead! Not big surprise.");
		return Plugin_Handled;
	}
	
	new Float:duration = 0.0;
	decl String:buffer[64];
	if (args == 1)
	{
		GetCmdArg(1, buffer, sizeof(buffer));
		duration = StringToFloat(buffer);
	}
	else
		 duration = GetConVarFloat(playerTime);
	
	TF2_StunPlayer(client, duration, _, TF_STUNFLAGS_LOSERSTATE, 0);
	LogAction(client, client, "\"%L\" self-stunned \"%L\" ", client, client);
	ShowActivity2(client, "[SM] ","'%N' Stunned himself!", client);
	
	return Plugin_Handled;
}

public Action:Cmd_GhostStunMe(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_gstunme [duration]");
		return Plugin_Handled;
	}
	if (!GetConVarBool(allowSelfstun))
	{
		ReplyToCommand(client, "This command is disabled!");
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You are dead! Not big surprise.");
		return Plugin_Handled;
	}
	
	new Float:duration = 0.0;
	decl String:buffer[64];
	if (args == 1)
	{
		GetCmdArg(1, buffer, sizeof(buffer));
		duration = StringToFloat(buffer);
	}
	else
		 duration = GetConVarFloat(playerTime);
	
	TF2_StunPlayer(client, duration, _, TF_STUNFLAGS_GHOSTSCARE, 0);
	LogAction(client, client, "\"%L\" self ghost stunned \"%L\" ", client, client);
	ShowActivity2(client, "[SM] ","'%N' Ghost Stunned himself!", client);
	
	return Plugin_Handled;
}

public Action:Cmd_BonkMe(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "Usage: sm_bonkme [duration]");
		return Plugin_Handled;
	}
	if (!GetConVarBool(allowSelfstun))
	{
		ReplyToCommand(client, "This command is disabled!");
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You are dead! Not big surprise.");
		return Plugin_Handled;
	}
	new Float:duration = 0.0;
	decl String:buffer[64];
	if (args == 1)
	{
		GetCmdArg(1, buffer, sizeof(buffer));
		duration = StringToFloat(buffer);
	}
	else
		 duration = GetConVarFloat(playerTime);
	
	TF2_StunPlayer(client, duration, 0.0, TF_STUNFLAGS_BIGBONK, 0);
	LogAction(client, client, "\"%L\" self-bonked \"%L\" ", client, client);
	ShowActivity2(client, "[SM] ","'%N' Bonked himself!", client);

	return Plugin_Handled;
}