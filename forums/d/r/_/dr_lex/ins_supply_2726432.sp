/**
 * [INS] Supply Point Manager
 *
 * This plugin will set the supply points (tokens) for players on connect to server.
 * Will determine and give highest possible supply to player, based on settings completed.
 *
 * 0.3 = Fixed translations.
 * 0.2 = "ALPHA" Added Join and Rejoin cvars
 * 0.1 = Initial build. CVar and Token testing
*/

#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

ConVar g_S_Enabled;
ConVar g_S_Base_Points;
ConVar g_S_Rejoin;
ConVar g_S_Join;

char sMap[64];

public Plugin myinfo =
{
  name = "[INS] Supply Point Manager",
  author = "GiZZoR (modified version: dr_lex)",
  description = "Set player supply points",
  version = "0.3",
  url = "https://github.com/GiZZoR/ins-sm-plugins"
};

public void OnPluginStart()
{
	// Hook to start of round, for storing players Supply
	HookEvent("round_start", S_RoundStarted);

	// Hook (& Command) to explicitly set a player's supply points. Applies _before_ player spawns in world.
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	RegAdminCmd("sm_supply", Command_Supply, ADMFLAG_BAN, "Sets the supply points of a target");

	// "Boolean": sm_supply_enabled; Enable/disable plugin. Default: 1 (Enabled)
	g_S_Enabled = CreateConVar("sm_supply_enabled" , "1", "Sets whether the plugin is enabled", FCVAR_NONE, true, 0.0, true, 1.0);

	// "Int": sm_supply_base; Number of supply points to give players. Default: 12
	g_S_Base_Points = CreateConVar("sm_supply_base" , "12", "Base / Starting supply points", FCVAR_NOTIFY);

	// "Boolean": sm_supply_restore; Enable/disable restoring player's gained supply points. Default: 1 (Enabled)
	g_S_Rejoin = CreateConVar("sm_supply_restore", "1", "Restore points gained by player on reconnect", FCVAR_NONE, true, 0.0, true, 1.0);

	// "Int": sm_supply_join; Enable/disable setting supply points for new players. Default: 0 (Disabled)
	// Options:
	// 0 - Disabled (Default)
	// 1 - Give new player base supply as set in sm_supply_base. Note: You may want to set this per game mode in server_<mode>.cfg
	// 2 - Give new player the same supply as lowest member in team (Useful for multiple rounds of coop play)
	// 3 - Give new player the team average of supply points (sum all players supply points divided by players)
	g_S_Join = CreateConVar("sm_supply_join", "0", "0 - Disabled; 1 - sm_supply_base; 2 - Team Lowest; 3 - Team Average", FCVAR_NONE, true, 0.0, true, 3.0);
	LoadTranslations("common.phrases");
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));
}

public Action Command_Supply(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_supply <#userid|name>");
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	char arg2[11];
	char Name[128];

	int target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, target_name, sizeof(target_name), tn_is_ml);
	if (target_count <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if (args == 1)
	{
		for (int i = 0; i < target_count; i++)
		{
			int Tokens = GetEntProp(target_list[i], Prop_Send, "m_nRecievedTokens");
			GetClientName(target_list[i], Name, sizeof(Name));
			ReplyToCommand(client,"%s has %i supply points",Name, Tokens);
		}
		return Plugin_Handled;
	}

	GetCmdArg(2, arg2, sizeof(arg2));
	int supply = StringToInt(arg2);
	for (int i=0; i<target_count; ++i)
	{
		GetClientName(target_list[i], Name, sizeof(Name));
		SetEntProp(target_list[i], Prop_Send, "m_nRecievedTokens", supply);
		ReplyToCommand(client,"Setting supply for %s to %i",Name, supply);
	}
	return Plugin_Handled;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (g_S_Enabled.IntValue == 0)
	{
		return Plugin_Handled;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	int currentTokens = GetEntProp(client, Prop_Send, "m_nRecievedTokens");
	int newTokens = 0;

	char SteamID[64];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT" ,false) == true)
	{
		return Plugin_Handled;
	}

	int team = event.GetInt("team");
	
	if (g_S_Rejoin.IntValue == 1)
	{
		KeyValues hGM = new KeyValues(sMap);
		if (hGM.JumpToKey(SteamID, false) == true)
		{
			newTokens = hGM.GetNum("supply", 10);
		}
		delete hGM;
	}

	if (g_S_Join.IntValue > 0)
	{
		if (g_S_Join.IntValue == 1)
		{
			newTokens = g_S_Base_Points.IntValue;
		}
		if (g_S_Join.IntValue == 2)
		{
			newTokens = TeamLowestSupply(team, client);
		}
		if (g_S_Join.IntValue == 3)
		{
			newTokens = TeamAverageSupply(team, client);
		}
	}
	if (newTokens > currentTokens)
	{
		SetEntProp(client, Prop_Send, "m_nRecievedTokens", newTokens);
	}
	return Plugin_Handled;
}

public Action S_RoundStarted(Event event, const char[] name, bool dontBroadcast)
{
	for (int S_Client_Loop = 1; S_Client_Loop <= MaxClients; S_Client_Loop++)
	{
		if (IsClientConnected(S_Client_Loop) && IsClientInGame(S_Client_Loop))
		{
			char S_Round_SteamID[64];
			GetClientAuthId(S_Client_Loop, AuthId_Steam2, S_Round_SteamID, sizeof(S_Round_SteamID));

			if (StrEqual(S_Round_SteamID, "BOT", false) == false)
			{
				int team = GetClientTeam(S_Client_Loop);
				int supply = GetEntProp(S_Client_Loop, Prop_Send, "m_nRecievedTokens");
				
				KeyValues hGM = new KeyValues(sMap);
				if (hGM.JumpToKey(S_Round_SteamID, true) == true)
				{
					hGM.SetNum("team", team);
					hGM.SetNum("supply", supply);
				}
				hGM.Rewind();
				delete hGM;
			}
		}
	}
}

int TeamAverageSupply(int team, int player)
{
	float TeamSupplyTotal = 0.0;
	int PlayerSupply = GetEntProp(player, Prop_Send, "m_nRecievedTokens");
	int PlayerCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			int S_Client_Loop_Team = GetClientTeam(i);
			if (S_Client_Loop_Team == team)
			{
				if (player != i)
				{
					int supply = GetEntProp(i, Prop_Send, "m_nRecievedTokens");
					TeamSupplyTotal = TeamSupplyTotal + float(supply);
					PlayerCount++;
				}
			}
		}
	}

	if (PlayerCount == 0)
	{
		return PlayerSupply;
	}

	float TeamAverage = TeamSupplyTotal / PlayerCount;
	return RoundToFloor(TeamAverage);
}

int TeamLowestSupply(int team, int player)
{
	int TeamLowest = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			int loop_team = GetClientTeam(i);
			if (loop_team == team)
			{
				if (player != i)
				{
					int supply = GetEntProp(i, Prop_Send, "m_nRecievedTokens");
					if (TeamLowest == 0)
					{
						TeamLowest = supply;
					}
					else if (supply < TeamLowest)
					{
						TeamLowest = supply;
					}
				}
			}
		}
	}
	return TeamLowest;
}