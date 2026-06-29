#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "JPLAYS"
#define PLUGIN_VERSION "1.00"

#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <autoexecconfig>

bool isvotedmode = false;
bool cantvote = false;
bool votestoped = false;
bool modeffa = false;
bool modetvt = false;

ConVar gConVar_Gamemodes_Players;

public Plugin myinfo = 
{
	name = "CSurf Gamemodes", 
	author = PLUGIN_AUTHOR, 
	description = "CSurf Gamemodes Vote and System between FFA and Team VS Team", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/jplayss"
};

int ffa = 0;
int tvt = 0;

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	RegAdminCmd("sm_gamemode", command_vote, ADMFLAG_GENERIC);
	RegAdminCmd("sm_cancelgm", command_stopvote, ADMFLAG_BAN);
	RegAdminCmd("sm_ffa", command_ffa, ADMFLAG_BAN);
	RegAdminCmd("sm_tvt", command_tvt, ADMFLAG_BAN);
	
	AutoExecConfig_SetFile("csurf_gamemodes");
	
	gConVar_Gamemodes_Players = AutoExecConfig_CreateConVar("gm_change_players", "14", "Number of Players For the Gamemode to Change");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public Action command_ffa(int client, int args)
{
	CPrintToChatAll("%t", "Admin FFA", client);
	ServerCommand("mp_teammates_are_enemies 1");
	return Plugin_Handled;
}

public Action command_tvt(int client, int args)
{
	CPrintToChatAll("%t", "Admin TVT", client);
	ServerCommand("mp_teammates_are_enemies 0");
	return Plugin_Handled;
}

public Action command_stopvote(int client, int args)
{
	if (!votestoped)
	{
		CPrintToChatAll("%t", "Admin Cancel", client);
		votestoped = true;
		CreateTimer(60.0, autochoose);
	}
	if (votestoped)
	{
		CPrintToChat(client, "%t", "Already Stopped");
	}
}

public Action OnRoundStart(Event event, const char[] name, bool dbc)
{
	if (!isvotedmode)
	{
		int PlayerCount = GetClientCount(true) - 1;
		if (PlayerCount >= gConVar_Gamemodes_Players.IntValue)
		{
			CPrintToChatAll("%t", "TVT Players", PlayerCount);
			ServerCommand("mp_teammates_are_enemies 0");
		}
		else
		{
			CPrintToChatAll("%t", "FFA Players", PlayerCount);
			ServerCommand("mp_teammates_are_enemies 1");
		}
	}
	if (modeffa)
	{
		CPrintToChatAll("%t", "Current FFA");
		ServerCommand("mp_teammates_are_enemies 1");
	}
	else if (modetvt)
	{
		CPrintToChatAll("%t", "Current TVT");
		ServerCommand("mp_teammates_are_enemies 0");
	}
}

public Action command_vote(int client, int args)
{
	votestoped = false;
	Menu votemenu = new Menu(mVoteMenu);
	votemenu.SetTitle("%t", "Choose Gamemode");
	votemenu.AddItem("ffa", "FFA");
	votemenu.AddItem("tvt", "Team vs Team");
	votemenu.AddItem("", "", ITEMDRAW_SPACER);
	votemenu.AddItem("stopvote", "[ADMIN] Cancel Vote", IsADMIN(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	if (!cantvote)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				votemenu.Display(i, 20);
			}
			
		}
		cantvote = true;
		CreateTimer(300.0, CantVote);
		CreateTimer(25.0, VoteCount);
	}
	else if (cantvote)
	{
		CPrintToChat(client, "%t", "Cant Vote");
	}
}
public Action VoteCount(Handle timer)
{
	if (!votestoped)
	{
		if (ffa > tvt)
		{
			isvotedmode = true;
			ffa = 0;
			tvt = 0;
			CPrintToChatAll("%t", "Will FFA");
			modeffa = true;
			
		}
		if (ffa < tvt)
		{
			modetvt = true;
			isvotedmode = true;
			ffa = 0;
			tvt = 0;
			CPrintToChatAll("%t", "Will TVT");
			ServerCommand("mp_teammates_are_enemies 0");
		}
	}
	else if (votestoped)
	{
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action CantVote(Handle timer)
{
	cantvote = false;
}

public int mVoteMenu(Menu votemenu, MenuAction onclick, int client, int args)
{
	switch (onclick)
	{
		case MenuAction_Select:
		{
			char id[32];
			votemenu.GetItem(args, id, sizeof(id));
			
			if (StrEqual(id, "ffa"))
			{
				CPrintToChat(client, "%t", "Vote FFA");
				ffa += 1;
			}
			else if (StrEqual(id, "tvt"))
			{
				CPrintToChat(client, "%t", "Vote TVT");
				tvt += 1;
			}
			else if (StrEqual(id, "stopvote"))
			{
				CPrintToChatAll("%t", "Admin Canceled", client);
				if (!votestoped)
				{
					votestoped = true;
					CreateTimer(60.0, autochoose);
				}
				if (votestoped)
				{
					CPrintToChat(client, "%t", "Already Stopped");
				}
			}
		}
		
	}
}

stock bool IsValidClient(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client))
	{
		return true;
	}
	
	return false;
}

public Action autochoose(Handle timer)
{
	isvotedmode = false;
}

stock bool IsADMIN(int client)
{
	return CheckCommandAccess(client, "", ADMFLAG_BAN);
} 