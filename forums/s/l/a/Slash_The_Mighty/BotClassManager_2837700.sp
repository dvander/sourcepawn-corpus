#include <sourcemod>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "3.08"

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

// --- HARDCODED BOT CLASS LIMITS ---
// Index: [Team][Class]
// Team Indexes: TF_TEAM_RED (2), TF_TEAM_BLU (3)
// Class Indexes (from defines above): TF_CLASS_SCOUT (1), TF_CLASS_SNIPER (2), ..., TF_CLASS_SPY (8), TF_CLASS_ENGINEER (9)
// Value: -1 = No Limit, N = Max N bots of that class per team
int g_iHardcodedLimits[4][10] =
{
	// Team 0 (unused) , Class 0 (UNKNOWN)
	{0,  0, 0, 0, 0, 0, 0, 0, 0, 0},
	// Team 1 (Spectator/Unassigned)
	{0,  0, 0, 0, 0, 0, 0, 0, 0, 0},
	// Team 2 (RED Team)
	{0, // Class 0 (TF_CLASS_UNKNOWN - unused)
	-1, // TF_CLASS_SCOUT (1) - No Limit
	3,  // TF_CLASS_SNIPER (2) - Max 3
	3,  // TF_CLASS_SOLDIER (3) - Max 3
	3,  // TF_CLASS_DEMOMAN (4) - Max 3
	3,  // TF_CLASS_MEDIC (5) - Max 3
	-1, // TF_CLASS_HEAVY (6) - No Limit
	3,  // TF_CLASS_PYRO (7) - Max 3
	3,  // TF_CLASS_SPY (8) - Max 3
	3   // TF_CLASS_ENGINEER (9) - Max 3
	},
	// Team 3 (BLU Team)
	{0, // Class 0 (TF_CLASS_UNKNOWN - unused)
	-1, // TF_CLASS_SCOUT (1) - No Limit
	3,  // TF_CLASS_SNIPER (2) - Max 3
	3,  // TF_CLASS_SOLDIER (3) - Max 3
	3,  // TF_CLASS_DEMOMAN (4) - Max 3
	3,  // TF_CLASS_MEDIC (5) - Max 3
	-1, // TF_CLASS_HEAVY (6) - No Limit
	3,  // TF_CLASS_PYRO (7) - Max 3
	3,  // TF_CLASS_SPY (8) - Max 3
	3   // TF_CLASS_ENGINEER (9) - Max 3
	}
};
// --- END HARDCODED BOT CLASS LIMITS ---

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
	g_hCvEnabled = CreateConVar("sm_crb_enabled", "1", "Enables/disables restricting classes for bots");

	// Removed all CreateConVar calls for individual class limits as they are now hardcoded

	// Removed: AutoExecConfig(true, "Class_Restrictions_For_Bots");
	HookEvent("player_spawn", Event_PlayerSpawn);
	SetConVarString(hCvVersion, PLUGIN_VERSION);
}
//built in class limit needs to be disabled
public void OnConfigsExecuted()
{
	SetConVarInt(FindConVar("tf_classlimit"), 0);
	SetConVarString(FindConVar("tf_bot_force_class"), "");
	SetConVarInt(FindConVar("tf_bot_reevaluate_class_in_spawnroom"), 0);
	SetConVarInt(FindConVar("tf_bot_spawn_use_preset_roster"), 0); // Hardcoded this essential CVar
	char mapName[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	// Removed: ServerCommand("exec \"sourcemod/Class_Restrictions_For_Bots/%s.cfg\"", mapName);
}
//there is no space, so the server admins set up the cvars incorrectly. have to change them otherwise bots will try to join teams and crash the server
void NoSpace()
{
	LogError("There is not enough space for another bot! Fix your class limits for bots!");
	// Removed the lines that referenced g_hCvLimits here, as they are no longer ConVars
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
		classlimit = g_iHardcodedLimits[iTeam][i]; // Uses hardcoded array

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

	int iLimit = g_iHardcodedLimits[iTeam][iClass]; // Uses hardcoded array

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