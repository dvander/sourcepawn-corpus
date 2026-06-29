#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required


#define Plugin_Version "2.0"
#define CHAT_TAGS "\x04[AutoTakeOver]\x03"


static Handle hCvar_EnableMe = INVALID_HANDLE;
static bool bEnableMe = true;

static Handle hCvar_VsTakeOverMethod = INVALID_HANDLE;
static bool bVsTakeOverMethod = false;

static bool bTakeOverInprogress = false;
static bool bAwaitingBotTakeover[MAXPLAYERS+1] = false;

static bool bCoop = true;
static Handle hCvar_GameMode = INVALID_HANDLE;


public Plugin myinfo =
{
	name = "[L4D/L4D2]AutoTakeOver",
	author = "Lux",
	description = "AutoTakesOver a bot UponDeath/OnBotSpawn",
	version = Plugin_Version,
	url = "https://forums.alliedmods.net/showthread.php?p=2494319#post2494319"
};

public void OnPluginStart()
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if(!StrEqual(sGameName, "left4dead") && !StrEqual(sGameName, "left4dead2"))
		SetFailState("This plugin only runs on Left 4 Dead and Left 4 Dead 2!");
	
	hCvar_GameMode = FindConVar("mp_gamemode");
	if(hCvar_GameMode == INVALID_HANDLE)
		SetFailState("Unable to find convar mp_gamemode");
	
	CreateConVar("auto_take_over", Plugin_Version, "Plugin_Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);
	hCvar_EnableMe = CreateConVar("ato_enabled", "1", "[1/0 = ENABLED/DISABLED]", FCVAR_NOTIFY);
	hCvar_VsTakeOverMethod = CreateConVar("ato_versus_take_over_method", "0", "[1/0 = ENABLED/DISABLED] In survival or coop you will skip idle state", FCVAR_NOTIFY);
	
	HookEvent("player_death", ePlayerDeath);
	HookEvent("player_team", eTeamChange);
	HookEvent("round_end", eRoundEndStart);
	HookEvent("round_start", eRoundEndStart);
	HookEvent("player_spawn", ePlayerSpawn);
	
	HookConVarChange(hCvar_EnableMe, eConvarChanged);
	HookConVarChange(hCvar_VsTakeOverMethod, eConvarChanged);
	HookConVarChange(hCvar_GameMode, eConvarChanged);
	
	CvarsChanged();
	AutoExecConfig(true, "_auto_take_over");
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	bEnableMe = GetConVarInt(hCvar_EnableMe) > 0;
	bVsTakeOverMethod = GetConVarInt(hCvar_VsTakeOverMethod) > 0;
	
	char sGameMode[13];
	GetConVarString(hCvar_GameMode, sGameMode, sizeof(sGameMode));
	if(!StrEqual(sGameMode, "coop", false) && !StrEqual(sGameMode, "survival", false) && !StrEqual(sGameMode, "realism", false))
		bCoop = false;
	else
		bCoop = true;
}

public void OnClientPutInServer(int iClient)
{
	if(!IsFakeClient(iClient))
		bAwaitingBotTakeover[iClient] = true;
}

public void ePlayerDeath(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if(!bEnableMe)
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || IsFakeClient(iClient))
		return;
	
	if(GetClientTeam(iClient) != 2 || IsPlayerAlive(iClient))
		return;
	
	bAwaitingBotTakeover[iClient] = true;
	
	CreateTimer(0.5, TakeOverBot, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
}

public void eTeamChange(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if(bTakeOverInprogress)
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsClientInGame(iClient) || IsFakeClient(iClient))
		return;
	
	switch(GetClientTeam(iClient))
	{
		case 3:
		{
			bAwaitingBotTakeover[iClient] = false;
		}
		case 2:
		{
			if(IsPlayerAlive(iClient))
			{
				bAwaitingBotTakeover[iClient] = false;
				return;
			}
		}
		case 1:
		{
			bAwaitingBotTakeover[iClient] = false;
		}
	}
}
//playerspawn is triggered even when someone changes team and a survivor bot is spawned
public void ePlayerSpawn(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1 || !IsClientInGame(iClient) || !IsFakeClient(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	//check if any survivors are waiting for a takeover and clean up any bools that are incorrect
	static int i;
	for(i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != 2 || IsPlayerAlive(i))
		{
			bAwaitingBotTakeover[i] = false;
			continue;
		}
			
		if(bAwaitingBotTakeover[i])
		{
			iClient = i;
			break;
		}
	}
	
	if(iClient < 1)
		return;
	
	CreateTimer(0.5, TakeOverBot, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
}

public void eRoundEndStart(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
		bAwaitingBotTakeover[i] = false;
}

public void OnClientDisconnect(int iClient)
{
	bAwaitingBotTakeover[iClient] = false;
}

public Action TakeOverBot(Handle hTimer, any iUserID)
{
	static int iClient;
	iClient = GetClientOfUserId(iUserID);
	
	if(iClient < 1 || !IsClientInGame(iClient) || GetClientTeam(iClient) != 2 || IsFakeClient(iClient) || IsPlayerAlive(iClient))
	{
		bAwaitingBotTakeover[iClient] = false;
		return Plugin_Stop;
	}
	
	static int iPotentialBot;
	iPotentialBot = CheckAvailableSurvivorBot();
	
	if(iPotentialBot < 1)
	{
		PrintToChat(iClient, "%sNo Available Bots\n Awaiting Free Bot For \x04Hostle TakeOver", CHAT_TAGS);
		return Plugin_Stop;
	}
	
	bTakeOverInprogress = true;//this bool is to stop any code from being run on eChangeTeam hook on the stack to save cpu and any unintended bad effects
	
	
	if(bVsTakeOverMethod || !bCoop)
	{
		if(TakeControl(iClient, iPotentialBot))
			bAwaitingBotTakeover[iClient] = false;
	}
	else
		IdleRandomBot(iClient);
	
	bTakeOverInprogress = false;
	
	return Plugin_Stop;
}

static int CheckAvailableSurvivorBot()
{
	static int i;
	for(i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsFakeClient(i))
			if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
				if(!HasIdlePlayer(i))
					return i;
	
	return -1;
}

static bool HasIdlePlayer(int iBot)
{
	if(!IsClientInGame(iBot) || GetClientTeam(iBot) != 2 || !IsPlayerAlive(iBot))
		return false;
	
	static char sNetClass[12];
	GetEntityNetClass(iBot, sNetClass, sizeof(sNetClass));
	
	if(IsFakeClient(iBot) && strcmp(sNetClass, "SurvivorBot") == 0)
	{
		static int iClient;
		iClient = GetClientOfUserId(GetEntProp(iBot, Prop_Send, "m_humanSpectatorUserID"));
		if(iClient > 0 && IsClientInGame(iClient) && GetClientTeam(iClient) == 1)
			return true;
	}
	return false;
}

// not good idea to use in sameframe of death use request frame(Targeting is not always 100% not sure why)
static bool TakeControl(int iClient, int iTarget)
{
	static char sCommand[]="sb_takecontrol";
	
	ChangeClientTeam(iClient, 1);
	FakeClientCommand(iClient, "spec_target %i", GetClientUserId(iTarget));
	FakeClientCommand(iClient, "spec_mode 7");
	
	static int iFlags;
	iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	
	FakeClientCommand(iClient, sCommand);
	
	SetCommandFlags(sCommand, iFlags);
	
	return IsPlayerAlive(iClient);
}

// if your going to use this i recommend using a 0.5 sec delay from death else takeover sometimes fails
//only idles in coop gamemodes
static void IdleRandomBot(int iClient)
{
	ChangeClientTeam(iClient, 1);
	FakeClientCommand(iClient,"jointeam 2");
}
