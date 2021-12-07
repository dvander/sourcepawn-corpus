#include <sourcemod>
#include <sdktools>

#define NAME "ND Squad Management"
#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo =
{
	name = NAME,
	author = "Player 1",
	description = "Allows admins to remove players from their squad. CMDs: sm_squadkick <player> | sm_squadunban <player>",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=185856"
};

//this array will hold the temporary bans
new SquadBans[MAXPLAYERS+1] = {-1,...};

public OnPluginStart() 
{
	CreateConVar("sm_nd_squad_management_version", PLUGIN_VERSION, NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_squadkick", Command_SquadKick, ADMFLAG_KICK, "Kicks and temporarily bans the target from current squad.");
	RegAdminCmd("sm_squadunban", Command_SquadUnban, ADMFLAG_KICK, "Removes a player's squad ban.");
	
	AddCommandListener(CommandListener:CMD_JoinSquad, "joinsquad");
	
	LoadTranslations("common.phrases");
	
}

public Action:Command_SquadKick(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_squadkick <player>");
		return Plugin_Handled;
	}

	decl String:arg1[64]
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		return Plugin_Handled;
	}

	new i_Squad = GetEntProp(target, Prop_Send, "m_iSquad");
	
	if (i_Squad == -1)
	{
		ReplyToCommand(client, "[SM] %N is not in a squad.",target);
		return Plugin_Handled;
	}
	
	SquadBans[target] = i_Squad;
	FakeClientCommand(target, "leavesquad");
	
	ReplyToCommand(client, "[SM] Kicked %N from squad.", target);
	PrintToChat(target, "[SM] You have been kicked from your squad.");
	LogMessage("Admin %N squad kicked %N", client, target);
	return Plugin_Handled;
}

public Action:Command_SquadUnban(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_squadunban <player>");
		return Plugin_Handled;
	}

	decl String:arg1[64]
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	if (SquadBans[target] == -1)
	{
		ReplyToCommand(client, "[SM] %N is not banned from any squad.",target);
		return Plugin_Handled;
	}
	
	SquadBans[target] = -1;	//remove the ban
	
	PrintToChat(target, "[SM] Your squad ban has been removed.");
	ReplyToCommand(client, "[SM] Removed squad ban on %N",target);
	LogMessage("Admin %N removed squad ban on %N", client, target);

	return Plugin_Handled;
}
	
public Action:CMD_JoinSquad(client, args)
{
	if (SquadBans[client] > -1)
	{
		decl String:CommandArg[16];
		GetCmdArg(1, CommandArg, sizeof(CommandArg));
		new arg = StringToInt(CommandArg);
		
		if (arg == SquadBans[client])
		{
			switch (SquadBans[client])
			{
				case 0:
				PrintToChat(client, "[SM] You are temporarily banned from Alpha squad.");
				case 1:
				PrintToChat(client, "[SM] You are temporarily banned from Bravo squad.");
				case 2:
				PrintToChat(client, "[SM] You are temporarily banned from Charlie squad.");
				case 3:
				PrintToChat(client, "[SM] You are temporarily banned from Delta squad.");
			}
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	else
	{
		return Plugin_Continue;
	}
}

//remove temp bans
public OnClientDisconnect(client)
{
	SquadBans[client] = -1
}
public OnMapEnd()
{
	for (new i = 1; i <= 33; i++)
	{
		SquadBans[i] = -1
	}
}