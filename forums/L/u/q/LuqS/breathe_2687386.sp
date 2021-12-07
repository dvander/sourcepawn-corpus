#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define NUMBER_OF_SOUNDS 3
#define MAX_FILE_NAME_LENGTH 64

int g_iVolumes[] =  { SNDLEVEL_RUSTLE, SNDLEVEL_WHISPER, SNDLEVEL_LIBRARY, SNDLEVEL_FRIDGE, SNDLEVEL_HOME, SNDLEVEL_CONVO, SNDLEVEL_DRYER, SNDLEVEL_DISHWASHER };

char g_cWalkingSounds[NUMBER_OF_SOUNDS][MAX_FILE_NAME_LENGTH];
char g_cRunningSounds[NUMBER_OF_SOUNDS][MAX_FILE_NAME_LENGTH];

ConVar g_cvAreBotsBreathing;
ConVar g_cvWhoShouldBreathe;

ConVar g_cvWalkingBreatheSound;
ConVar g_cvRunningBreatheSound;
ConVar g_cvHoldBreathe;

ConVar g_cvVolume;


public Plugin myinfo = 
{
	name 		= "[CS:GO] Breathe",
	author 		= "Original plugin from thecount, Rewritten by Natanel 'LuqS'",
	description = "simulating the breathing of the players allowing other players to hear it like in real life.",
	version 	= "v1.22",
	url 		= "https://steamcommunity.com/id/LuqSGood/"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
	
	g_cvAreBotsBreathing 	= CreateConVar("breathe_are_bots_breathing"	, "1"	, "Whether to make bots breathe or not.");
	g_cvWhoShouldBreathe	= CreateConVar("breathe_who_should_breathe"	, "0"	, "0 - Both teams, 1 - Only Terrorists, 2 - Only Counter-Terrorists");
	
	g_cvWalkingBreatheSound	= CreateConVar("breathe_walking_sound"	, "0"	, "0 - walking0.mp3, 1 - walking1.mp3, 2 - walking2.mp3, 3 - random sound");
	g_cvRunningBreatheSound	= CreateConVar("breathe_running_sound"	, "0"	, "0 - running0.mp3, 1 - running1.mp3, 2 - running2.mp3, 3 - ramdom sound");
	g_cvHoldBreathe			= CreateConVar("breathe_hold_mode"		, "m"	, "r - When not running, m - When not moving, c - On crouch");
	
	g_cvVolume				= CreateConVar("breathe_volume"		, "5"	, "Breathe Volume (0-7)");
	
	for(int iCurrentClient = 1; iCurrentClient <= MaxClients; iCurrentClient++)
		if(IsValidClient(iCurrentClient, g_cvAreBotsBreathing.BoolValue))
			OnClientAuthorized(iCurrentClient, "");
}

public void OnMapStart()
{
	PrecacheAndAddToTable();
}

stock void PrecacheAndAddToTable()
{
	char cSoundWalking[MAX_FILE_NAME_LENGTH], cSoundRunning[MAX_FILE_NAME_LENGTH];
	
	for (int iCurrentSound = 0; iCurrentSound < NUMBER_OF_SOUNDS; iCurrentSound++)
	{
		Format(g_cWalkingSounds[iCurrentSound], MAX_FILE_NAME_LENGTH, "walking%d.mp3", iCurrentSound);
		Format(g_cRunningSounds[iCurrentSound], MAX_FILE_NAME_LENGTH, "running%d.mp3", iCurrentSound);
		PrecacheSound(g_cWalkingSounds[iCurrentSound], true);
		PrecacheSound(g_cRunningSounds[iCurrentSound], true);
		
		Format(cSoundWalking, MAX_FILE_NAME_LENGTH, "sound/%s", g_cWalkingSounds[iCurrentSound]);
		Format(cSoundRunning, MAX_FILE_NAME_LENGTH, "sound/%s", g_cRunningSounds[iCurrentSound]);
		AddFileToDownloadsTable(cSoundWalking);
		AddFileToDownloadsTable(cSoundRunning);
	}
}	

public void OnClientAuthorized(int client)
{
	CreateTimer(3.0, Timer_Breathe, GetClientUserId(client), TIMER_REPEAT);
}

public Action Timer_Breathe(Handle timer, any userId)
{
	// GET CLIENT-ID //
	int client = GetClientOfUserId(userId);
	
	// STOP WHEN PLAYER DISCONNECT //
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return Plugin_Stop;
	
	// SKIP WHEN PLAYER IS NOT SUPPOSED TO MAKE SOUND //
	if(!IsValidClient(client, g_cvAreBotsBreathing.BoolValue, false))
		return Plugin_Continue;
	
	// GET CLIENT-VELOCITY //
	float fVectors[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVectors);
	
	// CHECK IF CLIENT WALKING / CROUCHING //
	bool isPlayerWalking = (GetClientButtons(client) & IN_SPEED) && (GetClientButtons(client) & IN_SPEED);
	bool isPlayerCrouching 	= (GetClientButtons(client) & IN_DUCK) && (GetClientButtons(client) & IN_DUCK);
	
	// SKIP IF CLIENT SHOULD HOLD BREATHE / SHOULD NOT MAKE BREATH SOUND //
	if (IsPlayerHoldingBreathe(client, fVectors, isPlayerWalking, isPlayerCrouching))
		return Plugin_Continue;
	
	// PLAY TO CLIENTS //
	PlaySoundToPlayers(client, isPlayerWalking || GetVectorLength(fVectors) == 0);
	
	// CONTINUE TIMER //
	return Plugin_Continue;
}

stock bool IsPlayerHoldingBreathe(int client, float fVectors[3], bool isPlayerWalking, bool isPlayerCrouching)
{
	int cvarBreathing = GetConVarInt(g_cvWhoShouldBreathe);
	
	// GET HOLD-BREATH KEYS //
	char cHoldBreathKeys[6];
	GetConVarString(g_cvHoldBreathe, cHoldBreathKeys, sizeof(cHoldBreathKeys));
	
	if(!(cvarBreathing == 0 ? true : (cvarBreathing == 1 ? GetClientTeam(client) == CS_TEAM_T : GetClientTeam(client) == CS_TEAM_CT)) ||
		(StrContains(cHoldBreathKeys, "m", false) != -1 && GetVectorLength(fVectors) == 0.0) ||
		(StrContains(cHoldBreathKeys, "c", false) != -1 && isPlayerCrouching) ||
		(StrContains(cHoldBreathKeys, "r", false) != -1 && isPlayerWalking))
		return true;
	return false;
}

stock int GetSoundIndexes(ConVar cvSoundCvar, int iNumOfSounds)
{
	return cvSoundCvar.IntValue == 3 ? GetRandomInt(0, iNumOfSounds - 1) : cvSoundCvar.IntValue;
}

stock void PlaySoundToPlayers(int iClientToPlayFrom, bool bPlayWalkingSound)
{
	for(int iCurrentClient = 1; iCurrentClient <= MaxClients; iCurrentClient++)
		if(IsValidClient(iCurrentClient) && iCurrentClient != iClientToPlayFrom)
			if(bPlayWalkingSound)
				EmitSoundToClient(iCurrentClient, g_cWalkingSounds[GetSoundIndexes(g_cvWalkingBreatheSound, sizeof(g_cWalkingSounds))], iClientToPlayFrom, SNDCHAN_AUTO, g_iVolumes[GetConVarInt(g_cvVolume)]);
			else	
				EmitSoundToClient(iCurrentClient, g_cRunningSounds[GetSoundIndexes(g_cvRunningBreatheSound, sizeof(g_cRunningSounds))], iClientToPlayFrom, SNDCHAN_AUTO, g_iVolumes[GetConVarInt(g_cvVolume)]);
}

// Checking if the sent client is valid based of the parmeters sent and other other functions.
stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client) || (IsFakeClient(client) && !bAllowBots) || (!bAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}