#pragma semicolon 1

#include <sourcemod>

new bool:BlockSpawn;
new bool:BlockPlayers;

public Plugin:myinfo = 
{
	name = "No Special Infected",
	author = "MaTi",
	description = "Removes all special infected.",
	version = "1.1",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_remove_si", Command_RemoveAllSI, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_no_si", Command_DisableSI, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_no_players_si", Command_BlockPlayers, ADMFLAG_CUSTOM1);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("witch_spawn", Event_WitchSpawn, EventHookMode_Post);
}

public Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(GetClientTeam(client) == 3 && BlockSpawn == true)
	{
		if(IsFakeClient(client))
		{
			KickClient(client, "No Special Infected Allowed");
		}
		else if(BlockPlayers == true)
		{
			KickClient(client, "No Special Infected Allowed");
		}
	}
}

public Event_WitchSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new witch = GetEventInt(event,"witchid");
	
	if(BlockSpawn == true)
	{
		RemoveEdict(witch);
	}
}

public Action:Command_RemoveAllSI(client, args)
{
	new entcount = GetEntityCount();
	decl String:ModelName[128];
	for (new i=1;i<=entcount;i++)
	{
		if(IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", ModelName, 128);
			if(StrContains(ModelName, "infected", true) != -1)
			{
				if(StrContains(ModelName, "witch.mdl", true) != -1)
				{
					RemoveEdict(i);
				}
				else if(StrContains(ModelName, "hulk.mdl", true) != -1 ||
				StrContains(ModelName, "spitter.mdl", true) != -1 ||
				StrContains(ModelName, "smoker.mdl", true) != -1 ||
				StrContains(ModelName, "hunter.mdl", true) != -1 ||
				StrContains(ModelName, "jockey.mdl", true) != -1 ||
				StrContains(ModelName, "charger.mdl", true) != -1 ||
				StrContains(ModelName, "boomer.mdl", true) != -1)
				{
					if(IsFakeClient(client))
					{
						KickClient(i, "Kicked all special infected");
					}
					else if(BlockPlayers == true)
					{
						KickClient(i, "Kicked all special infected");
					}
				}
			}
		}
	}
	PrintToChatAll("[SM] All special infected have been removed.");
	return Plugin_Handled;
}

public Action:Command_DisableSI(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_no_si <1|0>");
		return Plugin_Handled;
	}
	new String:cmd[10];
	GetCmdArg(1, cmd, sizeof(cmd));
	new cmd2 = StringToInt(cmd);
	
	if(cmd2 == 0)
	{
		PrintToChatAll("[SM] Special infected spawn has been enabled.");
		BlockSpawn = false;
	}
	else if(cmd2 == 1)
	{
		PrintToChatAll("[SM] Special infected spawn has been disabled.");
		BlockSpawn = true;
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_no_si <1|0>");
	}
	return Plugin_Handled;
}

public Action:Command_BlockPlayers(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_no_players_si <1|0>");
		return Plugin_Handled;
	}
	new String:cmd[10];
	GetCmdArg(1, cmd, sizeof(cmd));
	new cmd2 = StringToInt(cmd);
	
	if(cmd2 == 0)
	{
		PrintToChatAll("[SM] Players are now allowed to spawn as infected.");
		BlockPlayers = false;
	}
	else if(cmd2 == 1)
	{
		PrintToChatAll("[SM] Players are no longer allowed to spawn as infected.");
		BlockPlayers = true;
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_no_players_si <1|0>");
	}
	return Plugin_Handled;
}
