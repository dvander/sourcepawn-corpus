#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "MrSquid"
#define PLUGIN_VERSION "1.0.1"
#define RED 2
#define BLUE 3
#define SPECTATE 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Change Team",
	author = PLUGIN_AUTHOR,
	description = "Change team of a player or block a player from changing teams.",
	version = PLUGIN_VERSION,
	url = ""
};

int blocked[MAXPLAYERS];
int blocked_team[MAXPLAYERS];
bool override = false;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_changeteam", Command_changeTeam, ADMFLAG_SLAY, "Change the team of target");
	RegAdminCmd("sm_changeteam_block", Command_changeTeamDisabled, ADMFLAG_SLAY, "Disable team changing for target");
	HookEvent("player_team", Event_playerTeam, EventHookMode_Pre);
	
	
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		blocked[i] = -1;
	}
}

public Action Command_changeTeamDisabled(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_changeteam_block <#userid|name> <0|1>");
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
	bool disable;
	
	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int num = StringToInt(arg2, 10);
	if (num == 0)
	{
		disable = false;
	}
	else if (num == 1)
	{
		disable = true;
	}
	else
	{
		ReplyToCommand(client, "Usage: sm_changeteam_block <#userid|name> <0|1>");
		return Plugin_Handled;
	}
	
	//get targets
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (!CanUserTarget(client, target_list[i]))
		{
			ReplyToCommand(client, "[SM] You cannot target this player.");
			return Plugin_Handled;
		}
	 
	 	for (int c = 0; c < MAXPLAYERS; c++)
		{
			if (blocked[c] != -1)
			{
				if (GetClientUserId(target_list[i]) == blocked[c] && disable == true)
				{
					// client is already blocked
					ReplyToCommand(client, "[SM] Changing teams disabled for %s.", target_name);
					return Plugin_Handled;
				}
				else if (GetClientUserId(target_list[i]) == blocked[c] && disable == false)
				{
					// unblock the blocked client
					blocked[c] = -1;
					ReplyToCommand(client, "[SM] Changing teams enabled for %s.", target_name);
					return Plugin_Handled;
				}
			}
		}
		
		for (int c = 0; c < MAXPLAYERS; c++)
		{
			if (-1 == blocked[c] && disable == true)
			{
				// block the client
				blocked[c] = GetClientUserId(target_list[i]);
				blocked_team[c] = GetClientTeam(target_list[i]);
				ReplyToCommand(client, "[SM] Changing teams disabled for %s.", target_name);
				return Plugin_Handled;
			}
			else if (-1 == blocked[c] && disable == false)
			{
				// client is already unblocked
				ReplyToCommand(client, "[SM] Changing teams enabled for %s.", target_name);
				return Plugin_Handled;
			}
		}
	}
	
 
	return Plugin_Handled;
}

public Action Command_changeTeam(int client, int args)
{
	override = true;
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_changeteam <#userid|name> [team]");
		override = false;
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
 
	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if (strcmp(arg2, "red", true) != 0 && strcmp(arg2, "blue", true) != 0 && strcmp(arg2, "spectate", true) != 0)
	{
		ReplyToCommand(client, "[SM] Invalid team specified.");
		override = false;
		return Plugin_Handled;
	}
	
	//get targets
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		override = false;
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (!CanUserTarget(client, target_list[i]))
		{
			ReplyToCommand(client, "[SM] You cannot target this player.");
			override = false;
			return Plugin_Handled;
		}
		
		for (int c = 0; c < MAXPLAYERS; c++)
		{
			int teamID;
			if (strcmp(arg2, "red", true) == 0)
			{
				teamID = RED;
			}
			else if (strcmp(arg2, "blue", true) == 0)
			{
				teamID = BLUE;
			}
			else if (strcmp(arg2, "spectate", true) == 0)
			{
				teamID = SPECTATE;
			}
			
			if (blocked[c] != -1)
			{
				if (GetClientUserId(target_list[i]) == blocked[c])
				{
					blocked_team[c] = teamID;
				}
			}
			
			ChangeClientTeam(target_list[i], teamID);
		}
	 
		char name[MAX_NAME_LENGTH];
	 
		GetClientName(target_list[i], name, sizeof(name));
		ReplyToCommand(client, "[SM] %s has been changed to team: %s", name, arg2);
		PrintToChat(target_list[i], "[SM] ADMIN: changed your team to: %s", arg2);
	}
	
	return Plugin_Handled;
}

// intercept and block client jointeam command if required
public Action OnClientCommand(int client, int args)
{
	char cmd[16];
 
	/* Get the argument */
	GetCmdArg(0, cmd, sizeof(cmd));
	
	if (strcmp(cmd, "jointeam", true) == 0)
	{
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (blocked[i] != -1)
			{
				if (client == GetClientOfUserId(blocked[i]) && override == false)
				{
					PrintToChat(client, "[SM] You are not currently allowed to change teams.");
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

// hook when client has changed teams
public Action Event_playerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		if (blocked[i] != -1)
		{
			if (client == GetClientOfUserId(blocked[i]) && override == false)
			{
				PrintToChat(client, "[SM] You are not currently allowed to change teams.");
				CreateTimer(1.5, Timer_rejoin, i);
				return Plugin_Handled;
			}
		}
	}
	override = false;
	return Plugin_Continue;
}
public Action Timer_rejoin(Handle timer, int index)
{
	char team[30];
	if (blocked_team[index] == RED)
	{
		strcopy(team, sizeof(team), "red");
	}
	else if (blocked_team[index] == BLUE)
	{
		strcopy(team, sizeof(team), "blue");
	}
	else if (blocked_team[index] == SPECTATE)
	{
		strcopy(team, sizeof(team), "spectate");
	}
	
	char cmd[99];
	Format(cmd, sizeof(cmd), "sm_changeteam #%d %s", blocked[index], team);
	ServerCommand(cmd);
}