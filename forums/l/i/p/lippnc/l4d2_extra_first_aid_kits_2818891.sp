/************************************************
* Plugin name: L4D2 Extra First Aid Kits
* Plugin authors: DDRKhat, Marcus101RR, Merudo, Foxhound27, Senip, RainyDagger, Shao
* Modded by Sherriff Huckleberry
* Based upon:
* - [L4D(2)] SuperVersus [1.5.4] by DDRKhat
* - https://forums.alliedmods.net/showthread.php?p=2704058#post2704058
************************************************/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1;
#pragma newdecls required; 

#define PLUGIN_VERSION "1.0"
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2

char gameMode[16];
char gameName[16];

ConVar ExtraFirstAid;
ConVar FinaleExtraFirstAid;
ConVar SurvivalExtraFirstAid;

Handle MedkitTimer = null;
Handle BotsUpdateTimer = null;

bool MedkitsGiven = false;
bool RoundStarted = false;

public Plugin myinfo =
{
	name        = "L4D2 Extra First Aid Kits",
	author      = "DDRKhat modded by Huck",
	description = "Spawns extra first aid kits when 5+ players",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?t=346536"
}

public void OnPluginStart()
{
	GetGameFolderName(gameName, sizeof(gameName));

	CreateConVar("sm_extrafirstaidkits_version", PLUGIN_VERSION, "L4D2 Extra First Aid Kits", FCVAR_DONTRECORD);
	
	ExtraFirstAid = CreateConVar("l4d2_extra_first_aid", "1", "Allow extra medkits for 5+ players. (0=Disabled, 1=Enabled)", 0, true, 0.0, true, 1.0);
	FinaleExtraFirstAid = CreateConVar("l4d2_finale_extra_first_aid", "1", "Allow extra medkits when the finale is activated. (0=Disabled, 1=Enabled)", 0, true, 0.0, true, 1.0);
	SurvivalExtraFirstAid = CreateConVar("l4d2_survival_extra_first_aid", "1", "Allow extra medkits in Survival 5+ players at round start. (0=Disabled, 1=Enabled)", 0, true, 0.0, true, 1.0);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("finale_start", Event_FinaleStart, EventHookMode_Post);
	HookEvent("survival_round_start", Event_SurvivalStart, EventHookMode_Post);

	AutoExecConfig(true, "l4d2_extra_first_aids");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){MarkNativeAsOptional("L4D_LobbyUnreserve"); return APLRes_Success;}

public void OnMapEnd()
{
	GameEnd();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	GameEnd();
}

void GameEnd()
{
	delete MedkitTimer;
	delete BotsUpdateTimer;
	
	RoundStarted = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	MedkitsGiven = false;
	RoundStarted = true;
}

public Action Timer_SpawnExtraMedKit(Handle hTimer)
{
	MedkitTimer = null;

	int client = GetAnyAliveSurvivor();
	int amount = GetSurvivorTeam() - 4;
	
	if(amount > 0 && client > 0)
	{
		for(int i = 1; i <= amount; i++)
		{
			CheatCommand(client, "give", "first_aid_kit", "");
		}
	}
	return Plugin_Handled;
}

public void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if(FinaleExtraFirstAid.BoolValue && !StrEqual(gameMode, "survival, mutation15"))
	{
		int client = GetAnyAliveSurvivor();
		int amount = GetSurvivorTeam() - 4;

		if(amount > 0 && client > 0)
		{
			for(int i = 1; i <= amount; i++)
			{
				CheatCommand(client, "give", "first_aid_kit", "");
			}
		}
	}
}

public void Event_SurvivalStart(Event event, const char[] name, bool dontBroadcast)
{
	if(SurvivalExtraFirstAid.BoolValue)
	{
		int client = GetAnyAliveSurvivor();
		int amount = GetSurvivorTeam() - 4;

		if(amount > 0 && client > 0)
		{
			for(int i = 1; i <= amount; i++)
			{
				CheatCommand(client, "give", "first_aid_kit", "");
			}
		}
	}
}

void CheatCommand(int client, const char[] command, const char[] argument1, const char[] argument2)
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

public void Event_FinaleVehicleLeaving(Handle event, const char[] name, bool dontBroadcast)
{
	int ExtraPlayer = 0;
	int edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index != -1)
	{
		float pos[3];
		GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (ExtraPlayer < 4)
			{
				ExtraPlayer = ExtraPlayer + 1;
				continue;
			}
			if (!IsClientConnected(i)) continue;
			if (!IsClientInGame(i)) continue;
			if (GetClientTeam(i) != TEAM_SURVIVOR) continue;
			
			int survivorPosition = CreateEntityByName("info_survivor_position");
			DispatchSpawn(survivorPosition);
			TeleportEntity(survivorPosition, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (GetClientTeam(client) == TEAM_SURVIVOR)
	{
		delete BotsUpdateTimer;
		BotsUpdateTimer = CreateTimer(2.0, Timer_BotsUpdate);
	}
}

public void OnClientDisconnect(int client)
{
	if(RoundStarted)
	{
		delete BotsUpdateTimer;
		BotsUpdateTimer = CreateTimer(1.0, Timer_BotsUpdate);
	}
}

public Action Timer_BotsUpdate(Handle hTimer)
{
	BotsUpdateTimer = null;

	if (AreAllInGame() == true)
	{
		SpawnCheck();

		if (MedkitTimer == null && !MedkitsGiven && ExtraFirstAid.BoolValue && !StrEqual(gameMode, "survival, mutation15"))
		{
			MedkitsGiven = true;
			MedkitTimer = CreateTimer(2.0, Timer_SpawnExtraMedKit);
		}
	}
	else
	{
		BotsUpdateTimer = CreateTimer(1.0, Timer_BotsUpdate); 
	}
	return Plugin_Handled;
}

void SpawnCheck()
{
	if(RoundStarted != true)  return; 
}

bool AreAllInGame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			if (!IsClientInGame(i)) return false;
		}
	}
	return true;
}

int GetIdlePlayer(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && IsPlayerAlive(bot) && IsFakeClient(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR)
			{
				return client;
			}
		}
	}
	return 0;
}

int GetTeamPlayers(int team, bool includeBots)
{
	int players = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if(IsFakeClient(i) && !includeBots && !GetIdlePlayer(i))
				continue;
			players++;
		}
	}
	return players;
}

int GetSurvivorTeam()
{
	return GetTeamPlayers(TEAM_SURVIVOR, true);
}

bool IsBotValid(int client)
{
	if(client > 0 && IsClientInGame(client) && IsFakeClient(client) && !GetIdlePlayer(client) && !IsClientInKickQueue(client))
	{
		return true;
	}
	return false;
}

stock int CountBots(int team)
{
	int num = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsBotValid(i) && GetClientTeam(i) == team)
					num++;
	}
	return num;
}

int GetAnyAliveSurvivor()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientInKickQueue(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
		{
			return i;
		}
	}
	return -1;
}

stock int TotalSurvivors()
{
	int l = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVOR)) l++;
		}
	}
	return l;
}