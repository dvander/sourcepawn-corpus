#include <sourcemod>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "3.04"

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

public Plugin myinfo =
{
	name        = "Class Restrictions for Humans",
	author      = "luki1412",
	description = "Restrict classes in TF2 for human players.",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/member.php?u=43109"
}

bool g_bLateLoad;
ConVar g_hCvEnabled;
ConVar g_hCvFlags;
ConVar g_hCvImmunity;
ConVar g_hCvClassMenu;
ConVar g_hCvSounds;
ConVar g_hCvLimits[4][10];
char g_sSounds[10][24] = {"", "vo/scout_no03.mp3",   "vo/sniper_no04.mp3", "vo/soldier_no01.mp3",
	"vo/demoman_no03.mp3", "vo/medic_no03.mp3",  "vo/heavy_no02.mp3",
"vo/pyro_no01.mp3",    "vo/spy_no02.mp3",    "vo/engineer_no03.mp3"};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if (GetEngineVersion() != Engine_TF2) 
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar hCvVersion = CreateConVar("sm_crh_version", PLUGIN_VERSION, "TF2 Class Restrictions for Humans version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvEnabled                                = CreateConVar("sm_crh_enabled",       "1",  "Enables/disables restricting classes in TF2 for Human players", FCVAR_NOTIFY);
	g_hCvFlags                                  = CreateConVar("sm_crh_flags",         "b",   "Admin flag/s for immunity to restricting classes. If multiple flags are provided, one validated flag is enough to be immune.");
	g_hCvImmunity                               = CreateConVar("sm_crh_immunity",      "0",  "Enables/disables admins being immune to restricting classes");
	g_hCvClassMenu                              = CreateConVar("sm_crh_classmenu",     "0",  "Enables/disables the class menu popping up when you pick the wrong class");
	g_hCvSounds                                 = CreateConVar("sm_crh_sounds",        "0",  "Enables/disables the Nope sound when you pick the wrong class");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_DEMOMAN]  = CreateConVar("sm_crh_blu_demomen",   "-1", "Limits BLU human demomen");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_ENGINEER] = CreateConVar("sm_crh_blu_engineers", "-1", "Limits BLU human engineers");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_HEAVY]    = CreateConVar("sm_crh_blu_heavies",   "-1", "Limits BLU human heavies");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_MEDIC]    = CreateConVar("sm_crh_blu_medics",    "-1", "Limits BLU human medics");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_PYRO]     = CreateConVar("sm_crh_blu_pyros",     "-1", "Limits BLU human pyros");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SCOUT]    = CreateConVar("sm_crh_blu_scouts",    "-1", "Limits BLU human scouts");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SNIPER]   = CreateConVar("sm_crh_blu_snipers",   "-1", "Limits BLU human snipers");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SOLDIER]  = CreateConVar("sm_crh_blu_soldiers",  "-1", "Limits BLU human soldiers");
	g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SPY]      = CreateConVar("sm_crh_blu_spies",     "-1", "Limits BLU human spies");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_DEMOMAN]  = CreateConVar("sm_crh_red_demomen",   "-1", "Limits RED human demomen");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_ENGINEER] = CreateConVar("sm_crh_red_engineers", "-1", "Limits RED human engineers");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_HEAVY]    = CreateConVar("sm_crh_red_heavies",   "-1", "Limits RED human heavies");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_MEDIC]    = CreateConVar("sm_crh_red_medics",    "-1", "Limits RED human medics");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_PYRO]     = CreateConVar("sm_crh_red_pyros",     "-1", "Limits RED human pyros");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_SCOUT]    = CreateConVar("sm_crh_red_scouts",    "-1", "Limits RED human scouts");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_SNIPER]   = CreateConVar("sm_crh_red_snipers",   "-1", "Limits RED human snipers");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_SOLDIER]  = CreateConVar("sm_crh_red_soldiers",  "-1", "Limits RED human soldiers");
	g_hCvLimits[TF_TEAM_RED][TF_CLASS_SPY]      = CreateConVar("sm_crh_red_spies",     "-1", "Limits RED human spies");	
	
	AutoExecConfig(true, "Class_Restrictions_For_Humans");
	if (g_bLateLoad)
	{
		OnConfigsExecuted();
	}

	HookEvent("player_spawn", Event_PlayerSpawn);
	SetConVarString(hCvVersion, PLUGIN_VERSION);
}
//built in class limit needs to be disabled
public void OnConfigsExecuted() 
{
	SetConVarInt(FindConVar("tf_classlimit"), 0);
	char mapName[PLATFORM_MAX_PATH];
	GetCurrentMap(mapName, sizeof(mapName));
	ServerCommand("exec \"sourcemod/Class_Restrictions_For_Humans/%s.cfg\"", mapName);
}
//there is no space, so the server admins set up the cvars incorrectly. lets warn them through logs
void NoSpace()
{
	LogError("There is not enough space for another human!");
	LogError("Setting BLU and RED scouts limit for humans to unlimited. Fix your class limits for humans!");
	SetConVarInt( g_hCvLimits[TF_TEAM_BLU][TF_CLASS_SCOUT], -1, false, false );
	SetConVarInt( g_hCvLimits[TF_TEAM_RED][TF_CLASS_SCOUT], -1, false, false );
}
//player spawned, lets do stuff
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(!GetConVarBool(g_hCvEnabled))
	{
		return;
	}

	int iUser = GetEventInt(event, "userid");
	int iClient = GetClientOfUserId(iUser);

	if(GetConVarBool(g_hCvImmunity) && IsImmune(iClient))
	{
		return;
	}
	
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
						if(IsPlayerAlive(iClient)) 
						{
							SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
							ChangeClientTeam(iClient, TF_TEAM_BLU);
							SetEntProp(iClient, Prop_Send, "m_lifeState", 0);
						}
						else
						{
							ChangeClientTeam(iClient, TF_TEAM_BLU);
						}
						
						PrintCenterText(iClient, "The RED team is full! Changing your team to BLU.");
						int i = SelectFreeClass(GetClientTeam(iClient));
				
						if(i == 0)
						{
							ChangeClientTeam(iClient, 1);
							PrintCenterText(iClient, "All classes are full on RED and BLU! Moving you to spectator!");
							return;
						}
						
						TF2_SetPlayerClass(iClient, view_as<TFClassType>(i), _, true);
						
						if(IsPlayerAlive(iClient)) 
						{
							RequestFrame(RespawnPlayer, iUser);
						}
						
						return;
					}
					else
					{
						NoSpace();
						int i = SelectFreeClass(GetClientTeam(iClient));

						if(i == 0)
						{
							ChangeClientTeam(iClient, 1);
							PrintCenterText(iClient, "All classes are full on RED and BLU! Moving you to spectator!");
							return;
						}
						
						TF2_SetPlayerClass(iClient, view_as<TFClassType>(i), _, true);
						
						if(IsPlayerAlive(iClient)) 
						{
							RequestFrame(RespawnPlayer, iUser);
						}
						
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
						if(IsPlayerAlive(iClient)) 
						{
							SetEntProp(iClient, Prop_Send, "m_lifeState", 2);
							ChangeClientTeam(iClient, TF_TEAM_RED);
							SetEntProp(iClient, Prop_Send, "m_lifeState", 0);
						}
						else
						{
							ChangeClientTeam(iClient, TF_TEAM_RED);
						}
						
						PrintCenterText(iClient, "The BLU team is full! Changing your team to RED.");
						int i = SelectFreeClass(GetClientTeam(iClient));
				
						if(i == 0)
						{
							ChangeClientTeam(iClient, 1);
							PrintCenterText(iClient, "All classes are full on RED and BLU! Moving you to spectator!");
							return;
						}
						
						TF2_SetPlayerClass(iClient, view_as<TFClassType>(i), _, true);
						
						if(IsPlayerAlive(iClient)) 
						{
							RequestFrame(RespawnPlayer, iUser);
						}
						
						return;
					}
					else
					{
						NoSpace();
						int i = SelectFreeClass(GetClientTeam(iClient));
				
						if(i == 0)
						{
							ChangeClientTeam(iClient, 1);
							PrintCenterText(iClient, "All classes are full on RED and BLU! Moving you to spectator!");
							return;
						}
						
						TF2_SetPlayerClass(iClient, view_as<TFClassType>(i), _, true);
						
						if(IsPlayerAlive(iClient)) 
						{
							RequestFrame(RespawnPlayer, iUser);
						}
						
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
			if(GetConVarInt(g_hCvClassMenu) == 1)
			{
				ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
			}
			
			if(GetConVarInt(g_hCvSounds) == 1)
			{
				EmitSoundToClient(iClient, g_sSounds[iClass]);
			}
			
			PrintCenterText(iClient, "The class you picked is full! Selecting a random free class.");
			
			int i = SelectFreeClass(GetClientTeam(iClient));
	
			if(i == 0)
			{
				ChangeClientTeam(iClient, 1);
				PrintCenterText(iClient, "All classes are full on RED and BLU! Moving you to spectator!");
				return;
			}
			
			TF2_SetPlayerClass(iClient, view_as<TFClassType>(i), _, true);
			
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
//how many players do have on a team
int GetHumanClientsCount(int iTeam) 
{
	int clients = 0;
	
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsPlayerHereLoop(i)) 
		{
			if(GetClientTeam(i) == iTeam)
			{
				clients++;
			}
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
		int HumansCount = GetHumanClientsCount(iTeam);
		
		if(total >= HumansCount)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
}
//is class on that team full
bool IsFull(int iTeam, int iClass)
{
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
	
	if(iCount > iLimit)
	{
		return true;
	}
	else
	{
		return false;
	}
}
//is the player an admin?
bool IsImmune(int iClient)
{
	char sFlags[12];
	GetConVarString(g_hCvFlags, sFlags, sizeof(sFlags));
	
	return !StrEqual(sFlags, "") && GetUserFlagBits(iClient) & (ReadFlagString(sFlags)|ADMFLAG_ROOT);
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
//custom get random int within range function
int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}
//basic check for players
bool IsPlayerHereLoop(int client)
{
	return (IsClientInGame(client) && !IsFakeClient(client));
}