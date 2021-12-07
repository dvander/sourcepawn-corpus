#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

// Defines //
#define MAX_COMMANDS 32
#define MAX_COMMAND_LENGTH 32

#define COMMAND_INDEX 0
#define COOLDOWN_INDEX 1

#define CLIENT_BLOCKED 

// ConVars //
ConVar g_cvEnabled;

// Config Path //
char g_sFilePath[PLATFORM_MAX_PATH];

// Commands and Cooldowns //
char g_sCommands[MAX_COMMANDS][MAX_COMMAND_LENGTH];
int g_iCommandsCooldowns[MAX_COMMANDS];

// User Timers //
bool g_bIsPlayerBlocked[MAXPLAYERS + 1][MAX_COMMANDS];
int g_iClientTimes[MAXPLAYERS + 1][MAX_COMMANDS];

public Plugin myinfo = 
{
	name = "Command Anti Spammer",
	author = "Natanel \"LuqS\"",
	description = "Protects the server from command spam attacks",
	version = "1.0",
	url = "https://steamcommunity.com/id/LuqSGood/"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
	
	g_cvEnabled = CreateConVar("cas_enabled", "1", "Whether the 'Command Anti Spammer' Plugin is enabled");
	
	CreateDirectory("addons/sourcemod/configs/CAS", 3);
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "configs/CAS/Commands.txt");
}

public void OnMapStart()
{
	if(!OpenConfigFile())
		PrintToServer("[CAS] Failed to open Config file!");
}

stock bool OpenConfigFile()
{
	Handle hFile = OpenFile(g_sFilePath, "a+");
	
	if(hFile == INVALID_HANDLE)
		return false;
		
	char sCommandAndCooldown[2][MAX_COMMAND_LENGTH];
	
	for (int iLine = 0; (!IsEndOfFile(hFile) && ReadFileLine(hFile, sCommandAndCooldown[0], sizeof(sCommandAndCooldown[]))); iLine++)
	{
		//PrintToServer("[CAS] sCommandAndCooldown = %s", sCommandAndCooldown[0]);
		
		ExplodeString(sCommandAndCooldown[0], " ", sCommandAndCooldown, sizeof(sCommandAndCooldown), sizeof(sCommandAndCooldown[]));
		//PrintToServer("[CAS] Exploded String: %s | %d", sCommandAndCooldown[0], StringToInt(sCommandAndCooldown[1]));
		g_sCommands[iLine] = sCommandAndCooldown[0];
		g_iCommandsCooldowns[iLine] = StringToInt(sCommandAndCooldown[1]);
	}
	return true;
}

public Action OnClientCommand(int client, int args)
{
	//PrintToChatAll("OnClientCommand");
	if(!IsValidClient(client) || !g_cvEnabled.BoolValue)
		return Plugin_Continue;
		
	char sCommand[16];
	GetCmdArg(0, sCommand, sizeof(sCommand));

	for (int i = 0; i < MAX_COMMANDS; i++)
	{
		//PrintToChatAll("COMMAND - %s | CHECK - %s", sCommand, g_sCommands[i]);
		if(StrEqual(sCommand, g_sCommands[i], false))
			return CheckCooldown(client, i);
	}
		
	
	return Plugin_Continue;
}

stock Action CheckCooldown(int client, int iCommandIndex)
{
	//PrintToChatAll("CheckCooldown %d", iCommandIndex);
	if(g_bIsPlayerBlocked[client][iCommandIndex])
	{
		if((GetTime() - g_iClientTimes[client][iCommandIndex]) > g_iCommandsCooldowns[iCommandIndex])
			g_bIsPlayerBlocked[client][iCommandIndex] = false;
		else
		{
			PrintToChat(client, " \x04[CAS] \x02 You cannot use this command at the minute! (Cooldown: %d Seconds left)", (g_iCommandsCooldowns[iCommandIndex] - (GetTime() - g_iClientTimes[client][iCommandIndex])));
			return Plugin_Stop;
		}
	}
	else
	{
		g_iClientTimes[client][iCommandIndex] = GetTime();
		g_bIsPlayerBlocked[client][iCommandIndex] = true;
	}
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	for (int iCommand = 0; iCommand < MAX_COMMANDS; iCommand++)
		g_iClientTimes[client][iCommand] = -1;
}

bool IsValidClient(int client)
{
	if (!(0 < client <= MaxClients)) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}