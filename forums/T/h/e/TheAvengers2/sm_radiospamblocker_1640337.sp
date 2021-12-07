#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.2"
#define MAX_SAMPLES 8
#define MINIMUM_SAMPLE_VARIATION 2

public Plugin:myinfo = 
{
	name = "Radio Spam Blocker",
	author = "TheAvengers2",
	description = "Blocks Radio Spammers",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.com/"
}

#define IS_VALID_PLAYER(%1)	IsFakeClient(%1) || !IsPlayerAlive(%1) || GetClientTeam(%1) < 2

new Handle:g_hPlayerBlocks = INVALID_HANDLE;

new Handle:g_hMaxAvgSampleDuration = INVALID_HANDLE;
new Handle:g_hMaxBlocks = INVALID_HANDLE;
new Handle:g_hLogRadioBlocks = INVALID_HANDLE;

new g_iSamples[MAXPLAYERS+1][MAX_SAMPLES+1];
new g_iNextSampleIndex[MAXPLAYERS+1];

new bool:g_bCheckSamples[MAXPLAYERS+1];

new g_iTimesBlocked[MAXPLAYERS+1];
new g_iRadioBlockType[MAXPLAYERS+1]; // 0 = No Block, 1 = Round Block, 2 = Map Block

new bool:g_bWarnedOnce[MAXPLAYERS+1];

new String:g_sLogPath[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	g_hMaxAvgSampleDuration = CreateConVar("sm_radio_max_avg_duration", "3.0", "The maximum average duration between radio messages that will still trigger a block.", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	g_hMaxBlocks = CreateConVar("sm_radio_max_blocks", "3.0", "The maximum times a user can be blocked before being permanently blocked until map change. (0 = Never perm block)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_hLogRadioBlocks = CreateConVar("sm_radio_log_blocks", "1.0", "Log users blocked for spamming radio.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_hPlayerBlocks = CreateTrie();
	
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/RadioSpamBlocker.log");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	decl String:sGame[64];
	GetGameFolderName(sGame, sizeof(sGame)); 
	
	if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
	{
		AddCommandListener(Command_RadioMessage, "coverme");
		AddCommandListener(Command_RadioMessage, "enemydown");
		AddCommandListener(Command_RadioMessage, "enemyspot");
		AddCommandListener(Command_RadioMessage, "fallback");
		AddCommandListener(Command_RadioMessage, "followme");
		AddCommandListener(Command_RadioMessage, "getinpos");
		AddCommandListener(Command_RadioMessage, "getout");
		AddCommandListener(Command_RadioMessage, "go");
		AddCommandListener(Command_RadioMessage, "holdpos");
		AddCommandListener(Command_RadioMessage, "inposition");
		AddCommandListener(Command_RadioMessage, "needbackup");
		AddCommandListener(Command_RadioMessage, "negative");
		AddCommandListener(Command_RadioMessage, "regroup");
		AddCommandListener(Command_RadioMessage, "report");
		AddCommandListener(Command_RadioMessage, "reportingin");
		AddCommandListener(Command_RadioMessage, "roger");
		AddCommandListener(Command_RadioMessage, "sectorclear");
		AddCommandListener(Command_RadioMessage, "sticktog");
		AddCommandListener(Command_RadioMessage, "stormfront");
		AddCommandListener(Command_RadioMessage, "takepoint");
		AddCommandListener(Command_RadioMessage, "takingfire");
	}
	/* else if (StrEqual(sGame, "dod"))
	{
		AddCommandListener(Command_RadioMessage, "voice_areaclear");
		AddCommandListener(Command_RadioMessage, "voice_attack");
		AddCommandListener(Command_RadioMessage, "voice_backup");
		AddCommandListener(Command_RadioMessage, "voice_bazookaspotted");
		AddCommandListener(Command_RadioMessage, "voice_ceasefire");
		AddCommandListener(Command_RadioMessage, "voice_cover");
		AddCommandListener(Command_RadioMessage, "voice_coverflanks");
		AddCommandListener(Command_RadioMessage, "voice_displace");
		AddCommandListener(Command_RadioMessage, "voice_dropweapons");
		AddCommandListener(Command_RadioMessage, "voice_enemyahead");
		AddCommandListener(Command_RadioMessage, "voice_enemybehind");
		AddCommandListener(Command_RadioMessage, "voice_fallback");
		AddCommandListener(Command_RadioMessage, "voice_fireinhole");
		AddCommandListener(Command_RadioMessage, "voice_fireleft");
		AddCommandListener(Command_RadioMessage, "voice_fireright");
		AddCommandListener(Command_RadioMessage, "voice_gogogo");
		AddCommandListener(Command_RadioMessage, "voice_grenade");
		AddCommandListener(Command_RadioMessage, "voice_hold");
		AddCommandListener(Command_RadioMessage, "voice_left");
		AddCommandListener(Command_RadioMessage, "voice_medic");
		AddCommandListener(Command_RadioMessage, "voice_mgahead");
		AddCommandListener(Command_RadioMessage, "voice_moveupmg");
		AddCommandListener(Command_RadioMessage, "voice_needammo");
		AddCommandListener(Command_RadioMessage, "voice_negative");
		AddCommandListener(Command_RadioMessage, "voice_niceshot");
		AddCommandListener(Command_RadioMessage, "voice_right");
		AddCommandListener(Command_RadioMessage, "voice_sniper");
		AddCommandListener(Command_RadioMessage, "voice_sticktogether");
		AddCommandListener(Command_RadioMessage, "voice_takeammo");
		AddCommandListener(Command_RadioMessage, "voice_thanks");
		AddCommandListener(Command_RadioMessage, "voice_usebazooka");
		AddCommandListener(Command_RadioMessage, "voice_usegrens");
		AddCommandListener(Command_RadioMessage, "voice_usesmoke");
		AddCommandListener(Command_RadioMessage, "voice_wegothim");
		AddCommandListener(Command_RadioMessage, "voice_wtf");
		AddCommandListener(Command_RadioMessage, "voice_yessir");
	}*/
}

public OnMapEnd()
{
	ClearTrie(g_hPlayerBlocks);
	
	for(new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			ClearSampleData(i);
			g_iTimesBlocked[i] = 0;
			g_iRadioBlockType[i] = 0;
			g_bWarnedOnce[i] = false;
		}
	}
}

public OnClientAuthorized(client, const String:sAuthID[])
{
	new f_iTemp;
	if (GetTrieValue(g_hPlayerBlocks, sAuthID, f_iTemp))
	{
		if (f_iTemp >= GetConVarInt(g_hMaxBlocks) && GetConVarInt(g_hMaxBlocks) != 0)
		{
			g_iRadioBlockType[client] = 2;
		}
		else
		{
			g_iTimesBlocked[client] = f_iTemp;
		}
	}
}

public OnClientDisconnect(client)
{
	ClearSampleData(client);
	g_iTimesBlocked[client] = 0;
	g_iRadioBlockType[client] = 0;
	g_bWarnedOnce[client] = false;
}

public Action:Command_RadioMessage(client, const String:command[], args)
{
	if (!client || g_iRadioBlockType[client] > 0 || IS_VALID_PLAYER(client))
		return Plugin_Handled;
	
	new iPrevSampleIndex = g_iNextSampleIndex[client];
	
	g_iSamples[client][(g_iNextSampleIndex[client]++)] = GetTime();
	
	// reset index so it loops around & enable sample checking after first pass
	if (g_iNextSampleIndex[client] >= MAX_SAMPLES)
	{
		g_iNextSampleIndex[client] = 0;
		g_bCheckSamples[client] = true;
	}
	
	if (g_bCheckSamples[client])
	{
		new iIterationCounter = 0, iSampleValue = 0, iSampleLow = 0, iSampleHigh = 0, iSampleAverage = g_iSamples[client][iPrevSampleIndex] - g_iSamples[client][g_iNextSampleIndex[client]];
		
		// 1st Method (check whether user is spamming lots of radio commands w/ semicolon)
		if (iSampleAverage <= 0)
		{
			decl String:sBuffer[4];
			strcopy(sBuffer, sizeof(sBuffer), "[1]");
			RadioSpamDetected(client, sBuffer);
			return Plugin_Handled;
		}
		
		// 2nd Method (check the average duration between radio commands)
		if (float(iSampleAverage) / float(MAX_SAMPLES-1) <= GetConVarFloat(g_hMaxAvgSampleDuration))
		{
			decl String:sBuffer[32];
			FormatEx(sBuffer, sizeof(sBuffer), "Avg: %f [2]", float(iSampleAverage) / float(MAX_SAMPLES-1));
			RadioSpamDetected(client, sBuffer);
			return Plugin_Handled;
		}
		
		// 3rd Method (check the variation between samples)
		while (iIterationCounter < MAX_SAMPLES-1)
		{
			if (iPrevSampleIndex == 0)
			{
				iSampleValue = g_iSamples[client][iPrevSampleIndex] - g_iSamples[client][MAX_SAMPLES-1];
				iPrevSampleIndex = MAX_SAMPLES-1;
			}
			else
			{
				iSampleValue = g_iSamples[client][iPrevSampleIndex] - g_iSamples[client][iPrevSampleIndex-1];
				iPrevSampleIndex--;
			}
			
			if (iIterationCounter == 0)
			{
				iSampleLow = iSampleValue;
				iSampleHigh = iSampleValue;
			}
			else
			{
				if (iSampleHigh < iSampleValue)
					iSampleHigh = iSampleValue;
			
				if (iSampleLow > iSampleValue)
					iSampleLow = iSampleValue;
			}
			iIterationCounter++;
		}
		
		if (iSampleHigh - iSampleLow <= MINIMUM_SAMPLE_VARIATION)
		{
			decl String:sBuffer[64];
			FormatEx(sBuffer, sizeof(sBuffer), "Avg: %f, Low: %i, High: %i [3]", float(iSampleAverage) / float(MAX_SAMPLES-1), iSampleLow, iSampleHigh);
			RadioSpamDetected(client, sBuffer);
			return Plugin_Handled;
		}
	}
	else if (iPrevSampleIndex > 0 && !g_bWarnedOnce[client])
	{
		if (g_iSamples[client][iPrevSampleIndex] - g_iSamples[client][iPrevSampleIndex-1] <= 1) {
			PrintToChat(client, "\x04Don't spam radio commands!");
			g_bWarnedOnce[client] = true;
		}
	}

	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_iRadioBlockType[client] == 1)
		g_iRadioBlockType[client] = 0;
	
	return Plugin_Continue;
}

ClearSampleData(client)
{
	g_iNextSampleIndex[client] = 0;
	g_bCheckSamples[client] = false;
	
	for(new j=0; j<=MAX_SAMPLES; j++)
		g_iSamples[client][j] = -1;
}

RadioSpamDetected(client, const String:sBuffer[])
{
	decl String:f_sName[33], String:f_sAuthID[64], String:f_sIP[24];
	GetClientName(client, f_sName, sizeof(f_sName));
	GetClientAuthString(client, f_sAuthID, sizeof(f_sAuthID));
	GetClientIP(client, f_sIP, sizeof(f_sIP));
	
	if (g_iTimesBlocked[client]++ >= GetConVarInt(g_hMaxBlocks) && GetConVarInt(g_hMaxBlocks) != 0)
	{
		g_iRadioBlockType[client] = 2;
		if (GetConVarBool(g_hLogRadioBlocks))
			LogToFileEx(g_sLogPath, "[RadioSpamBlocker] %s [ID: %s | IP: %s] was blocked until map change. (%s)", f_sName, f_sAuthID, f_sIP, sBuffer);
		PrintToChat(client, "\x04Your radio command priviledges have been suspended for spamming. \x05They will be re-enabled on map change.");
	}
	else
	{
		g_iRadioBlockType[client] = 1;
		if (GetConVarBool(g_hLogRadioBlocks))
			LogToFileEx(g_sLogPath, "[RadioSpamBlocker] %s [ID: %s | IP: %s] was blocked until respawn. (%i/%i: %s)", f_sName, f_sAuthID, f_sIP, g_iTimesBlocked[client], GetConVarInt(g_hMaxBlocks), sBuffer);
		PrintToChat(client, "\x04Your radio command priviledges have been suspended for spamming. \x05They will be re-enabled on player respawn.");
	}
	SetTrieValue(g_hPlayerBlocks, f_sAuthID, g_iTimesBlocked[client]);
	ClearSampleData(client);
}