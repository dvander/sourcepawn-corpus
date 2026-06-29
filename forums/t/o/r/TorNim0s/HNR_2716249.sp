#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_AUTHOR "TorNim0s"
#define PLUGIN_VERSION "1.0"

#define MIN_PLAYERS 2
#define PREFIX " \x04[HNR]\x01"
#define Hint_Header "HIT_N_RUN"

ConVar g_HnrEnabled;
bool g_bHNREnabled;

int g_nCurrentInfected;
int Time_Count = 20;

int g_BeamSprite = -1;
int g_HaloSprite = -1;

bool g_nBeacon = false;

#pragma newdecls required

char g_sEndRoundSounds[][] =  { "hitnrun/winsound1.mp3", "hitnrun/winsound2.mp3", "hitnrun/winsound3.mp3", "hitnrun/winsound4.mp3", "hitnrun/winsound5.mp3" };

Handle g_hInfectedTimer = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Hit_N_Run", 
	author = PLUGIN_AUTHOR, 
	description = "Hit And Run mod for CS:GO", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	g_HnrEnabled = CreateConVar("sm_hnr_enabled", "1", "on/off - Enables and disables the Hit_N_Run plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookConVarChange(g_HnrEnabled, OnCvarChange);
	
	UpdateAllConvars();
	
	HookEvent("round_start", Round_Start);
}

public void OnMapStart() {
	
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	
	PrecacheAllSounds();
}

void PrecacheAllSounds() {
	PrecacheSound("hitnrun/clock_sound.mp3");
	PrecacheSound("hitnrun/infected2.wav");
	PrecacheSound("hitnrun/loser.wav");
	PrecacheSound("hitnrun/winsound1.mp3");
	PrecacheSound("hitnrun/winsound2.mp3");
	PrecacheSound("hitnrun/winsound3.mp3");
	PrecacheSound("hitnrun/winsound4.mp3");
	PrecacheSound("hitnrun/winsound5.mp3");
	
	LoadDirOfSound("sound/hitnrun");
}

void UpdateAllConvars() {
	g_bHNREnabled = GetConVarBool(g_HnrEnabled);
}

void LoadDirOfSound(char[] dirofmodels) {
	char path[PLATFORM_MAX_PATH];
	FileType type;
	char FileAfter[PLATFORM_MAX_PATH];
	Handle dir = OpenDirectory(dirofmodels);
	if (dir == INVALID_HANDLE) {
		delete dir;
		return;
	}
	while (ReadDirEntry(dir, path, sizeof(path), type)) {
		FormatEx(FileAfter, sizeof(FileAfter), "%s/%s", dirofmodels, path);
		if (type == FileType_File)
		{
			AddFileToDownloadsTable(FileAfter);
		}
		else if (type == FileType_Directory && !StrEqual(path, ".") && !StrEqual(path, ".."))
		{
			LoadDirOfSound(FileAfter);
		}
	}
	delete dir;
}

public void OnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	if (convar == g_HnrEnabled) {
		g_bHNREnabled = GetConVarBool(g_HnrEnabled);
		CreateTimer(2.0, RestartServer);
		
		PrintToChatAll("%s the game is set to %s", PREFIX, g_bHNREnabled ? "Enabled":"Disabled");
	}
}

void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action Round_Start(Event event, const char[] name, bool dontBroadcast) {
	
	if (!g_bHNREnabled) {
		return Plugin_Continue;
	}
	
	for (int nCurrentPlayer = 1; nCurrentPlayer <= MaxClients; nCurrentPlayer++)
	{
		if (IsClientInGame(nCurrentPlayer))
		{
			OnClientPutInServer(nCurrentPlayer);
		}
	}
	
	if (g_hInfectedTimer != INVALID_HANDLE) {
		KillTimer(g_hInfectedTimer);
		Time_Count = 20;
		g_hInfectedTimer = INVALID_HANDLE;
	}
	
	if (GetClientCount() >= MIN_PLAYERS) {
		for (int nCurrentPlayer = 1; nCurrentPlayer <= MaxClients; nCurrentPlayer++)
		{
			if (IsClientInGame(nCurrentPlayer) && IsPlayerAlive(nCurrentPlayer))
			{
				int g_nWeapon = -1;
				
				LoadPanel(nCurrentPlayer);
				
				if (GetClientTeam(nCurrentPlayer) == CS_TEAM_T) {
					disarmTarget(nCurrentPlayer);
					GivePlayerItem(nCurrentPlayer, "weapon_knife");
					g_nWeapon = GivePlayerItem(nCurrentPlayer, "weapon_ssg08");
					SetEntData(g_nWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 1000);
				}
				
				else if (GetClientTeam(nCurrentPlayer) == CS_TEAM_CT) {
					ChangeClientTeam(nCurrentPlayer, CS_TEAM_T);
					CS_RespawnPlayer(nCurrentPlayer);
					disarmTarget(nCurrentPlayer);
					GivePlayerItem(nCurrentPlayer, "weapon_knife");
					g_nWeapon = GivePlayerItem(nCurrentPlayer, "weapon_ssg08");
					SetEntData(g_nWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), 1000);
				}
			}
		}
		
		g_hInfectedTimer = CreateTimer(1.0, Get_Infected, Time_Count, TIMER_REPEAT);
	}
	else
	{
		PrintToChatAll("%s - Not enough player, Checking again in 5 sec", PREFIX, g_nCurrentInfected);
		CreateTimer(5.0, CheckPlayer, INVALID_HANDLE, TIMER_REPEAT);
	}
	
	return Plugin_Continue;
}

public Action Get_Infected(Handle timer, int counter)
{
	if (Time_Count == 20)
	{
		g_nCurrentInfected = getRandomAlivePlayer();
		if (g_nCurrentInfected == -1)
		{
			for (int nCurrentPlayer = 1; nCurrentPlayer <= MaxClients; nCurrentPlayer++)
			{
				if (IsClientInGame(nCurrentPlayer) && IsPlayerAlive(nCurrentPlayer))
				{
					PrintToChatAll("%s - \x07%N\x01 is the winner", PREFIX, nCurrentPlayer);
					PrintHintTextToAll("%N is the winner!", nCurrentPlayer);
					PrintToChatAll("%s - New Game will start in 5 sec", PREFIX);
					CreateTimer(5.0, RestartServer);
					g_nBeacon = true;
					CreateTimer(0.25, Beacon_Timer, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					
					int nWinSoundIndex = GetRandomInt(0, sizeof(g_sEndRoundSounds));
					
					EmitSoundToAll(g_sEndRoundSounds[nWinSoundIndex], _, SNDCHAN_STATIC, _, _, 0.3);
					
					g_hInfectedTimer = INVALID_HANDLE;
					
					return Plugin_Stop;
				}
			}
		}
		
		else
		{
			PrintToChat(g_nCurrentInfected, "%s - you are the infected!", PREFIX);
			PrintToChatAll("%s - \x07%N\x01 is the new infected!", PREFIX, g_nCurrentInfected);
			SetEntityRenderMode(g_nCurrentInfected, RENDER_TRANSALPHA);
			SetEntityRenderColor(g_nCurrentInfected, GetRandomInt(1, 255), GetRandomInt(1, 255), GetRandomInt(1, 255));
			
			EmitSoundToClient(g_nCurrentInfected, "hitnrun/infected2.wav", _, SNDCHAN_STATIC);
		}
		
		EmitSoundToAll("hitnrun/clock_sound.mp3", _, SNDCHAN_STATIC, _, _, 0.3);
	}
	
	else if (Time_Count == 0)
	{
		if (IsClientInGame(g_nCurrentInfected) && IsPlayerAlive(g_nCurrentInfected))
		{
			PrintToChatAll("%s - The infected %N has died", PREFIX, g_nCurrentInfected);
			SetEntityRenderMode(g_nCurrentInfected, RENDER_NORMAL);
			SetEntityRenderColor(g_nCurrentInfected);
			ForcePlayerSuicide(g_nCurrentInfected);
			
			EmitSoundToClient(g_nCurrentInfected, "hitnrun/loser.wav", _, SNDCHAN_STATIC);
		}
		Time_Count = 20;
		return Plugin_Continue;
	}
	
	else
	{
		if (g_nCurrentInfected <= 0) {
			g_hInfectedTimer = INVALID_HANDLE;
			
			Time_Count = 20;
			
			return Plugin_Stop;
		}
		
		if (IsClientInGame(g_nCurrentInfected) && IsPlayerAlive(g_nCurrentInfected))
		{
			for (int nCurrentPlayer = 1; nCurrentPlayer <= MaxClients; nCurrentPlayer++)
			{
				if (IsClientConnected(nCurrentPlayer) && IsClientInGame(nCurrentPlayer))
				{
					PrintHintText(nCurrentPlayer, "<font face=''><font color='#b32730'>%s</font>\n<font color='#5e81ac'>Infected:</font> %N\n<font color='#5e81ac'>Time Left:</font> %d", Hint_Header, g_nCurrentInfected, Time_Count);
				}
			}
		}
		else {
			PrintToChatAll("%s - \x04The infected\x01 has \x02disconnected\x01", PREFIX, g_nCurrentInfected);
			Time_Count = 1;
		}
	}
	
	Time_Count--;
	return Plugin_Continue;
}

int getRandomAlivePlayer() {
	int alivePlayers[MAXPLAYERS + 1];
	int alivePlayersCount = 0;
	int randomPlayer;
	int selectedPlayer;
	
	for (int nCurrentPlayer = 1; nCurrentPlayer <= MaxClients; nCurrentPlayer++) {
		
		if (IsClientInGame(nCurrentPlayer) && IsPlayerAlive(nCurrentPlayer)) {
			
			alivePlayersCount++;
			alivePlayers[alivePlayersCount] = nCurrentPlayer;
		}
	}
	
	if (alivePlayersCount <= 1) {
		selectedPlayer = -1;
	} else {
		
		randomPlayer = GetRandomInt(1, alivePlayersCount);
		selectedPlayer = alivePlayers[randomPlayer];
	}
	
	
	return (selectedPlayer);
}

void LoadPanel(int nPlayerIndex)
{
	if (!IsClientConnected(nPlayerIndex) || !IsClientInGame(nPlayerIndex))
		return;
	
	SetHudTextParams(-1.0, 0.3, 0.9, 148, 146, 176, 255, 0, 6.0, 0.1, 0.2);
}

public Action RestartServer(Handle timer) {
	ServerCommand("mp_restartgame 1");
	g_nBeacon = false;
}

public Action CheckPlayer(Handle timer)
{
	if (GetClientCount() >= MIN_PLAYERS)
	{
		PrintToChatAll("%s - The game will now \x04start\x01", PREFIX);
		ServerCommand("mp_restartgame 1");
		return Plugin_Stop;
	}
	
	KillTimer(timer);
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (attacker == g_nCurrentInfected && victim != g_nCurrentInfected)
	{
		g_nCurrentInfected = victim;
		
		PrintToChatAll("%s - \x07%N\x01 has infected \x07%N\x01.", PREFIX, attacker, victim);
		
		SetEntityRenderMode(attacker, RENDER_NORMAL);
		SetEntityRenderColor(attacker);
		
		SetEntityRenderMode(victim, RENDER_TRANSALPHA);
		SetEntityRenderColor(victim, GetRandomInt(1, 255), GetRandomInt(1, 255), GetRandomInt(1, 255));
		
		for (int nCurrentPlayer = 1; nCurrentPlayer <= MaxClients; nCurrentPlayer++) {
			if (IsClientConnected(nCurrentPlayer) && IsClientInGame(nCurrentPlayer)) {
				PrintHintText(nCurrentPlayer, "<font face=''>%s\n<font color='#FF0000'>Infected:</font> %N\n<font color='#FF0000'>Time Left:</font> %d", Hint_Header, g_nCurrentInfected, Time_Count);
			}
		}
		
		EmitSoundToClient(victim, "hitnrun/infected2.wav");
	}
}

public Action OnWeaponCanUse(int client, int weapon) {
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, 32);
	if (!(StrEqual(sWeapon, "weapon_knife") || StrEqual(sWeapon, "weapon_ssg08"))) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void disarmTarget(int target)
{
	for (int currentWeapon = 0; currentWeapon <= 5; currentWeapon++)
	{
		int targetWeapon = GetPlayerWeaponSlot(target, currentWeapon);
		if (IsValidEntity(targetWeapon))
			RemovePlayerItem(target, targetWeapon);
	}
}

public Action Beacon_Timer(Handle timer)
{
	int Color[4];
	if (g_nBeacon) {
		
		Color[0] = GetRandomInt(1, 255);
		Color[1] = GetRandomInt(1, 255);
		Color[2] = GetRandomInt(1, 255);
		Color[3] = 255;
		for (int nCurrentPlayer = 1; nCurrentPlayer <= MaxClients; nCurrentPlayer++)
		{
			if (IsClientConnected(nCurrentPlayer) && IsPlayerAlive(nCurrentPlayer))
			{
				float vec[3];
				GetClientAbsOrigin(nCurrentPlayer, vec);
				vec[2] += 10;
				TE_SetupBeamRingPoint(vec, 10.0, 50.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, Color, 10, 0);
				TE_SendToAll();
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
