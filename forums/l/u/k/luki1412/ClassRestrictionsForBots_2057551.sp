#include <sourcemod>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "3.09"

#define TF_CLASS_DEMOMAN		4
#define TF_CLASS_ENGINEER		9
#define TF_CLASS_HEAVY			6
#define TF_CLASS_MEDIC			5
#define TF_CLASS_PYRO			7
#define TF_CLASS_SCOUT			1
#define TF_CLASS_SNIPER			2
#define TF_CLASS_SOLDIER		3
#define TF_CLASS_SPY			8
#define TF_CLASS_UNKNOWN		0

#define TF_TEAM_BLU				3
#define TF_TEAM_RED				2
#define TF_TEAM_SPC				1

public Plugin myinfo =
{
	name        = "Class Restrictions for Bots",
	author      = "luki1412",
	description = "Restrict classes in TF2 for bots.",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/member.php?u=43109"
}

ConVar g_hCvEnabled;
ConVar g_hCvLimits[4][10];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar hCvVersion = CreateConVar("sm_crb_version", PLUGIN_VERSION, "TF2 Class Restrictions for Bots version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvEnabled                                = CreateConVar("sm_crb_enabled",       "1",  "Enables/disables restricting classes for bots");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_DEMOMAN]  = CreateConVar("sm_crb_blu_demomen",   "-1", "Limits BLU bot demomen");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_ENGINEER] = CreateConVar("sm_crb_blu_engineers", "-1", "Limits BLU bot engineers");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_HEAVY]    = CreateConVar("sm_crb_blu_heavies",   "-1", "Limits BLU bot heavies");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_MEDIC]    = CreateConVar("sm_crb_blu_medics",    "-1", "Limits BLU bot medics");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_PYRO]     = CreateConVar("sm_crb_blu_pyros",     "-1", "Limits BLU bot pyros");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SCOUT]    = CreateConVar("sm_crb_blu_scouts",    "-1", "Limits BLU bot scouts");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SNIPER]   = CreateConVar("sm_crb_blu_snipers",   "-1", "Limits BLU bot snipers");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SOLDIER]  = CreateConVar("sm_crb_blu_soldiers",  "-1", "Limits BLU bot soldiers");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SPY]      = CreateConVar("sm_crb_blu_spies",     "-1", "Limits BLU bot spies");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_DEMOMAN]  = CreateConVar("sm_crb_red_demomen",   "-1", "Limits RED bot demomen");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_ENGINEER] = CreateConVar("sm_crb_red_engineers", "-1", "Limits RED bot engineers");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_HEAVY]    = CreateConVar("sm_crb_red_heavies",   "-1", "Limits RED bot heavies");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_MEDIC]    = CreateConVar("sm_crb_red_medics",    "-1", "Limits RED bot medics");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_PYRO]     = CreateConVar("sm_crb_red_pyros",     "-1", "Limits RED bot pyros");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_SCOUT]    = CreateConVar("sm_crb_red_scouts",    "-1", "Limits RED bot scouts");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_SNIPER]   = CreateConVar("sm_crb_red_snipers",   "-1", "Limits RED bot snipers");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_SOLDIER]  = CreateConVar("sm_crb_red_soldiers",  "-1", "Limits RED bot soldiers");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_SPY]      = CreateConVar("sm_crb_red_spies",     "-1", "Limits RED bot spies");
	RegAdminCmd("sm_crb_list_limits", Command_List, ADMFLAG_CONFIG, "Lists current bot limits in the console");
	AutoExecConfig(true, "Class_Restrictions_For_Bots");
	HookEvent("player_spawn", Event_PlayerSpawn);
	SetConVarString(hCvVersion, PLUGIN_VERSION);
}
//built in class limit needs to be disabled
public void OnConfigsExecuted()
{
	SetConVarInt(FindConVar("tf_classlimit"), 0);
	SetConVarString(FindConVar("tf_bot_force_class"), "");
	SetConVarInt(FindConVar("tf_bot_reevaluate_class_in_spawnroom"), 0);
	char mapName[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	ServerCommand("exec \"sourcemod/Class_Restrictions_For_Bots/%s.cfg\"", mapName);
}
//there is no space, so the server admins set up the cvars incorrectly. have to change them otherwise bots will try to join teams and crash the server
void NoSpace()
{
	LogError("There is not enough space for another bot! Setting BLU and RED spies limit for bots to unlimited to avoid a crash. Fix your class limits for bots!");
	SetConVarInt( g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SPY], -1, false, false );
	SetConVarInt( g_hCvLimits[TF_TEAM_RED][TF_CLASS_SPY], -1, false, false );
}
//list current limits in the console
public Action Command_List(int client, int args)
{
	if(GetConVarBool(g_hCvEnabled) && (client == 0 || IsClientConnected(client)))
	{
		if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
		{
			PrintToChat(client, "[CRB] See console for output");
		}

		char output[1048];
		FormatEx(output, sizeof(output), "\
-----------------------------------\n\
Current Class Restrictions for Bots\n\
-\n\
Limit for BLU bot scouts is    %i\n\
Limit for BLU bot soldiers is  %i\n\
Limit for BLU bot pyros is     %i\n\
Limit for BLU bot demomen is   %i\n\
Limit for BLU bot heavies is   %i\n\
Limit for BLU bot engineers is %i\n\
Limit for BLU bot medics is    %i\n\
Limit for BLU bot snipers is   %i\n\
Limit for BLU bot spies is     %i\n\
-\n\
Limit for RED bot scouts is    %i\n\
Limit for RED bot soldiers is  %i\n\
Limit for RED bot pyros is     %i\n\
Limit for RED bot demomen is   %i\n\
Limit for RED bot heavies is   %i\n\
Limit for RED bot engineers is %i\n\
Limit for RED bot medics is    %i\n\
Limit for RED bot snipers is   %i\n\
Limit for RED bot spies is     %i\n\
-----------------------------------",
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SCOUT]),
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SOLDIER]),
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_PYRO]),
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_DEMOMAN]),
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_HEAVY]),
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_ENGINEER]),
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_MEDIC]),
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SNIPER]),
		GetConVarInt(g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SPY]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_SCOUT]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_SOLDIER]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_PYRO]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_DEMOMAN]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_HEAVY]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_ENGINEER]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_MEDIC]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_SNIPER]),
		GetConVarInt(g_hCvLimits[TF_TEAM_RED][TF_CLASS_SPY]));
		PrintToConsole(client, output);
	}

	return Plugin_Handled;
}
//player spawned event
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarBool(g_hCvEnabled))
	{
		return;
	}

	int iUser = GetEventInt(event, "userid");
	int iClient = GetClientOfUserId(iUser);

	if(IsPlayerHereLoop(iClient))
	{
		int iTeam = GetEventInt(event, "team");

		switch (iTeam)
		{
			case TF_TEAM_RED:
			{
				if(IsThereEnoughSpace(TF_TEAM_RED) == false)
				{
					if(IsThereEnoughSpace(TF_TEAM_BLU) == true)
					{
						int iFreeClass = SelectFreeClass(TF_TEAM_BLU);
						TF2_SetPlayerClass(iClient, view_as<TFClassType>(iFreeClass), _, true);

						if(iFreeClass == 0)
						{
							ChangeClientTeam(iClient, TF_TEAM_SPC);
							return;
						}
						else if(IsPlayerAlive(iClient))
						{
							SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
							ChangeClientTeam(iClient, TF_TEAM_BLU);
							SetEntProp(iClient, Prop_Send, "m_lifeState", 0);
						}
						else
						{
							ChangeClientTeam(iClient, TF_TEAM_BLU);
						}

						if(IsPlayerAlive(iClient))
						{
							RequestFrame(RespawnPlayer, iUser);
						}

						return;
					}
					else
					{
						NoSpace();
						ChangeClientTeam(iClient, TF_TEAM_SPC);
						TF2_SetPlayerClass(iClient, view_as<TFClassType>(TF_CLASS_UNKNOWN), _, true);
						return;
					}
				}
			}
			case TF_TEAM_BLU:
			{
				if(IsThereEnoughSpace(TF_TEAM_BLU) == false)
				{
					if(IsThereEnoughSpace(TF_TEAM_RED) == true)
					{
						int iFreeClass = SelectFreeClass(TF_TEAM_RED);
						TF2_SetPlayerClass(iClient, view_as<TFClassType>(iFreeClass), _, true);

						if(iFreeClass == 0)
						{
							ChangeClientTeam(iClient, TF_TEAM_SPC);
							return;
						}
						else if(IsPlayerAlive(iClient))
						{
							SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
							ChangeClientTeam(iClient, TF_TEAM_RED);
							SetEntProp(iClient, Prop_Send, "m_lifeState", 0);
						}
						else
						{
							ChangeClientTeam(iClient, TF_TEAM_RED);
						}

						if(IsPlayerAlive(iClient))
						{
							RequestFrame(RespawnPlayer, iUser);
						}

						return;
					}
					else
					{
						NoSpace();
						ChangeClientTeam(iClient, TF_TEAM_SPC);
						TF2_SetPlayerClass(iClient, view_as<TFClassType>(TF_CLASS_UNKNOWN), _, true);
						return;
					}
				}
			}
			default:
			{
				return;
			}
		}

		int iClass = GetEventInt(event, "class");

		if(IsFull(iTeam, iClass))
		{
			int iFreeClass = SelectFreeClass(iTeam);
			TF2_SetPlayerClass(iClient, view_as<TFClassType>(iFreeClass), _, true);

			if(iFreeClass == 0)
			{
				ChangeClientTeam(iClient, TF_TEAM_SPC);
				return;
			}

			if(IsPlayerAlive(iClient))
			{
				RequestFrame(RespawnPlayer, iUser);
			}

			return;
		}
	}
}
//respawn player callback
void RespawnPlayer(int iUser)
{
	int iClient = GetClientOfUserId(iUser);

	if(iClient && IsPlayerHereLoop(iClient))
	{
		TF2_RespawnPlayer(iClient);
	}
}
//how many players do we have on a team
int GetBotClientsCount(int iTeam)
{
	int clients = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayerHereLoop(i) && (GetClientTeam(i) == iTeam))
		{
			clients++;
		}
	}

	return clients;
}
//is there even enough space for the player on the team
bool IsThereEnoughSpace(int iTeam)
{
	int total = 0, classlimit = 0;

	for(int i = 1; i <= 9; i++)
	{
		classlimit = GetConVarInt(g_hCvLimits[iTeam][i]);

		if(classlimit != -1)
		{
			total += classlimit;
		}
		else
		{
			total = -1;
			break;
		}
	}

	if(total == -1)
	{
		return true;
	}
	else if(total == 0)
	{
		return false;
	}
	else
	{
		return total >= GetBotClientsCount(iTeam);
	}
}
//is class on that team full
bool IsFull(int iTeam, int iClass)
{
	if(iClass == 0)
	{
		return true;		
	}

	int iLimit = GetConVarInt(g_hCvLimits[iTeam][iClass]);

	if(iLimit == -1)
	{
		return false;
	}
	else if(iLimit == 0)
	{
		return true;
	}

	int iCount = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayerHereLoop(i) && GetClientTeam(i) == iTeam && view_as<int>(TF2_GetPlayerClass(i)) == iClass)
		{
			iCount++;
		}
	}

	return iCount > iLimit;
}
//select a free class for the player
int SelectFreeClass(int iTeam)
{
	int x = 0;
	int classes[9] = {0, ...};

	for(int i = 1; i <= 9; i++)
	{
		if(!IsFull(iTeam, i))
		{
			classes[x] = i;
			x++;
		}
	}

	if(classes[0] == 0)
	{
		return 0;
	}

	if(x == 1)
	{
		return classes[0];
	}

	x--;
	return classes[GetRandomUInt(0,x)];
}
//custom function to get random int within range
int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}
//basic check for players
bool IsPlayerHereLoop(int client)
{
	return IsClientInGame(client) && IsFakeClient(client);
}