#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Diam0ndz"
#define PLUGIN_VERSION "0.1.5"
#define PREFIX " \x01[\x0bDeathrun\x01]\x0b"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <autoexecconfig>
//#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;

ConVar deathrunVersion;
ConVar freerunEnabledCV;
ConVar freerunCooldownCV;
ConVar addTPerCtCV;
ConVar tRounds;
ConVar autoCtRespawn;
ConVar queueSystem;

int freerunCooldown = 0;
bool isFreerun;

int queue[MAXPLAYERS + 1];

int numberOfTs;
int tRoundCount = 0;

public Plugin myinfo = 
{
	name = "Diam0ndz' Deathrun",
	author = PLUGIN_AUTHOR,
	description = "The most customizable Deathrun plugin for CS:GO",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/diam0ndz"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	AutoExecConfig_SetCreateDirectory(true);
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("deathrun");
	
	deathrunVersion = AutoExecConfig_CreateConVar("dr_version", PLUGIN_VERSION, "Diam0ndz' Deathrun Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	freerunEnabledCV = AutoExecConfig_CreateConVar("dr_freerunenabled", "1", "Sets whether Ts may activate a freerun", FCVAR_PROTECTED);
	freerunCooldownCV = AutoExecConfig_CreateConVar("dr_freeruncooldown", "3", "Amount of rounds a T has to wait before calling another freerun", FCVAR_PROTECTED);
	addTPerCtCV = AutoExecConfig_CreateConVar("dr_addtperct", "15", "For each number of additional CTs, we add one more T", FCVAR_PROTECTED);
	tRounds = AutoExecConfig_CreateConVar("dr_trounds", "3", "Number of rounds a T has to spend before getting switched back to CT", FCVAR_PROTECTED);
	autoCtRespawn = AutoExecConfig_CreateConVar("dr_autoctrespawn", "1", "Sets whether CTs should respawn if there are no Ts", FCVAR_PROTECTED);
	queueSystem = AutoExecConfig_CreateConVar("dr_queuesystem", "1", "Sets whether the queue system should be used", FCVAR_PROTECTED);
	deathrunVersion.SetString(PLUGIN_VERSION);
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	RegConsoleCmd("sm_freerun", Command_Freerun, "Calls a freerun");
	RegConsoleCmd("sm_queue", Command_Queue, "Joins the queue to become a T or checks your position in the queue");
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	AddCommandListener(Console_Kill, "explode");
	AddCommandListener(Console_Kill, "kill");
	AddCommandListener(Console_JoinTeam, "jointeam");
}

public void OnMapStart()
{
	PrintToChatAll("%s This server is running Diam0ndz' Deathrun! V%s", PREFIX, PLUGIN_VERSION);
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client)) queue[client] = 0;
}

public void OnClientDisconnect(int client)
{
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(queue[i] >= queue[client] && i != client)
		{
			queue[i]--;
			PrintToChat(client, "%s You were moved up to position %i in the queue.", PREFIX, queue[i]);
		}
	}
	queue[client] = 0;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(tRoundCount >= tRounds.IntValue)
	{
		UpdateTCount();
		tRoundCount = 0;
	}
	tRoundCount++;
	if(freerunCooldown > 0)
	{
		freerunCooldown--;
	}
	if(isFreerun)
	{
		isFreerun = false;
		freerunCooldown = freerunCooldownCV.IntValue;
	}
}

public Action Command_Queue(int client, int args)
{
	if(!IsValidClient(client))
	{
		PrintToChat(client, "%s You are not a valid client.", PREFIX);
		return Plugin_Handled;
	}
	
	if(!queueSystem.BoolValue)
	{
		PrintToChat(client, "%s The queue system is currently disabled.", PREFIX);
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		PrintToChat(client, "%s You are already on T.", PREFIX);
		return Plugin_Handled;
	}
	
	if(queue[client] > 0)
	{
		PrintToChat(client, "%s You are position %i in the queue.", PREFIX, queue[client]);
		return Plugin_Handled;
	}
	
	int positionToBeIn = 0;
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(queue[i] >= positionToBeIn)
		{
			positionToBeIn = queue[i] + 1;
		}
	}
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(i == client)
		{
			queue[i] = positionToBeIn;
		}
	}
	PrintToChat(client, "%s You are now position %i in the queue.", PREFIX, positionToBeIn);
	return Plugin_Handled;
}

public Action Command_Freerun(int client, int args)
{
	if(!IsValidClient(client))
	{
		PrintToChat(client, "%s You are not a valid client.", PREFIX);
		return Plugin_Handled;
	}
	
	if(!freerunEnabledCV.BoolValue)
	{
		PrintToChat(client, "%s Freerun is currently disabled.", PREFIX);
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s You are on the wrong team to call a freerun.", PREFIX);
		return Plugin_Handled;
	}
	
	if(isFreerun)
	{
		PrintToChat(client, "%s There is a Freerun already in progress.", PREFIX);
		return Plugin_Handled;
	}
	
	if (freerunCooldown > 0)
	{
		PrintToChat(client, "%s You need to wait %i more rounds before calling a Freerun.", PREFIX, freerunCooldown);
		return Plugin_Handled;
	}
	ActivateFreerun();
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(autoCtRespawn.BoolValue)
	{
		if(GetTeamClientCount(CS_TEAM_T) <= 0)
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));
			CreateTimer(2.5, TimerRespawn, client);
		}
	}
}

public Action TimerRespawn(Handle timer, int client)
{
	CS_RespawnPlayer(client);
}

public Action Console_Kill(int client, const char[] command, int args)
{
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		PrintToChat(client, "%s Nice try! ;)", PREFIX);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Console_JoinTeam(int client, const char[] command, int args)
{
	char argString[32];  
	GetCmdArg(1, argString, sizeof(argString));
	int arg = StringToInt(argString);
	
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		if(GetTeamClientCount(CS_TEAM_CT) > 1)
		{
			PrintToChat(client, "%s You cannot switch off of T at this time.", PREFIX);
			return Plugin_Handled;
		}
	}
	if(arg == CS_TEAM_T)
	{
		if(GetTeamClientCount(CS_TEAM_T) > 0)
		{
			PrintToChat(client, "%s There is already a player on T.", PREFIX);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void ActivateFreerun()
{
	PrintToChatAll("%s A Freerun has been initiated!", PREFIX);
	isFreerun = true;
}

public void UpdateTCount()
{	
	bool playerInQueue;
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(queue[i] > 0)
		{
			playerInQueue = true;
			break;
		}
	}
	
	int numberOfClients = GetTeamClientCount(CS_TEAM_CT) + GetTeamClientCount(CS_TEAM_T);
	numberOfTs = numberOfClients / addTPerCtCV.IntValue;
	for (int i = 0; i <= GetTeamClientCount(CS_TEAM_T); i++)
	{
		int switchBack = GetRandomPlayerFromTeam(CS_TEAM_T);
		CS_SwitchTeam(switchBack, CS_TEAM_CT);
		PrintToChat(switchBack, "%s You were switched to CT.", PREFIX);
	}
	for (int i = 0; i <= numberOfTs; i++)
	{
		if(playerInQueue)
		{
			for (int k = 0; k < MAXPLAYERS + 1; k++)
			{
				if(queue[k] == 1)
				{
					CS_SwitchTeam(k, CS_TEAM_T);
					PrintToChat(k, "%s It's your turn to become the T! Kill as many CTs as you can while they run the course. You can activate a Freerun with !freerun.", PREFIX);
					queue[k] = 0;
					for (int l = 0; l < MAXPLAYERS + 1; l++)
					{
						if(queue[l] > 1)
						{
							queue[l]--;
							PrintToChat(l, "%s You are position %i in the queue.", PREFIX, queue[l]);
						}
					}
				}
			}
		}
		else
		{
			int toSwitch = GetRandomPlayerFromTeam(CS_TEAM_CT);
			CS_SwitchTeam(toSwitch, CS_TEAM_T);
			PrintToChat(toSwitch, "%s It's your turn to become the T! Kill as many CTs as you can while they run the course. You can activate a Freerun with !freerun.", PREFIX);
		}
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	if(isFreerun)
	{
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			if(buttons & IN_USE)
			{
				buttons &= ~IN_USE;
			}
		}
	}
}

stock int GetRandomPlayerFromTeam(int team) //Get a random player from a specific team
{
    int[] clients = new int[MaxClients + 1];
    int clientCount;
    for (int i = 1; i <= MaxClients; i++)
    if (IsClientInGame(i) && (GetClientTeam(i) == team))
        clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}

stock bool IsValidClient(int client) //Checks for making sure we are a valid client
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (IsFakeClient(client)) return false;
	if (IsClientSourceTV(client))return false;
	return IsClientInGame(client);
}