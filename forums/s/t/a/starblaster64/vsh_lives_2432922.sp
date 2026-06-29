#pragma semicolon 1

//#define DEBUG //For debugging, duh

#define PLUGIN_AUTHOR "Starblaster64"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <tf2_stocks>
#include <morecolors>
#include <saxtonhale>
//#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[VSH] Lives",
	author = PLUGIN_AUTHOR,
	description = "Adds a lives system to VSH.",
	version = PLUGIN_VERSION,
	url = ""
};

////Begin Global Vars


//ConVars
ConVar cvarVersion, cvarEnabled;
ConVar cvarLives, cvarLivesDamage, cvarLivesMax, cvarRespawnDelay, cvarRespawnBlock, cvarRespawnLastman;

//Bools
static bool g_bIsEnabled;
static bool g_bRespawnBlock, g_bRespawnLastman;

//Ints
static int g_iLives, g_iLivesDamage, g_iLivesMax;
static int iLives[MAXPLAYERS + 1];
static int iLivesGained[MAXPLAYERS + 1];
static int iDamage[MAXPLAYERS + 1];
static int iHale;

//Floats
static float g_flRespawnDelay;

//Handles
//static Handle LivesHUD;


////End Global Vars



public void OnPluginStart()
{
	#if defined DEBUG
	LogMessage("[DEBUG]===VSH Lives Initializing - v%s===", PLUGIN_VERSION);
	#endif
	
	//Create ConVars
	cvarVersion = CreateConVar("vsh_lives_version", PLUGIN_VERSION, "Plugin version. Don't touch this.", FCVAR_NOTIFY);
	cvarEnabled = CreateConVar("vsh_lives_enabled", "1.0", "Enables/Disables the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarLives = CreateConVar("vsh_lives_base", "0.0", "Sets base number of extra lives per round.", FCVAR_NOTIFY, true, 0.0);
	cvarLivesDamage = CreateConVar("vsh_lives_damage", "2048.0", ">0 to enable gaining 1 extra life per this much damage.", FCVAR_NOTIFY, true, 0.0);
	cvarLivesMax = CreateConVar("vsh_lives_max", "1.0", "Maximum number of extra lives you can gain per round.", FCVAR_NOTIFY, true, 0.0);
	cvarRespawnDelay = CreateConVar("vsh_lives_respawn_delay", "5.0", "Sets the delay (in seconds) between dying and respawning.", FCVAR_NOTIFY, true, 0.0);
	cvarRespawnBlock = CreateConVar("vsh_lives_respawn_block", "1.0", "Blocks players from spawning if they have 0 lives left. (Fixes latespawns, but probably breaks other plugins that respawn players)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRespawnLastman = CreateConVar("vsh_lives_respawn_lastman", "1.0", "Whether the LastManStanding should respawn instantly if he has lives left.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "vsh-lives"); //Generate config file in cfg/sourcemod
	
	//Hook ConVar changes so they can be changed mid-game through console
	HookConVarChange(cvarEnabled, CvarChange);
	HookConVarChange(cvarVersion, CvarChange);
	HookConVarChange(cvarLives, CvarChange);
	HookConVarChange(cvarLivesDamage, CvarChange);
	HookConVarChange(cvarLivesMax, CvarChange);
	HookConVarChange(cvarRespawnDelay, CvarChange);
	HookConVarChange(cvarRespawnBlock, CvarChange);
	HookConVarChange(cvarRespawnLastman, CvarChange);
	
	//Create Admin/Console Commands
	//RegAdminCmd("sm_hale_respawn", Command_Respawn, ADMFLAG_KICK, "Respawns a player even if they have no lives left.");
	RegConsoleCmd("sm_hale_lives", Command_ShowLives, "Displays lives left in chat for client.");
	RegConsoleCmd("sm_lives", Command_ShowLives, "Displays lives left in chat for client.");
	//RegConsoleCmd("sm_hale_showlives", Command_LivesHud, "Toggles lives HUD for client.");
	
	//Create HUD synchronizers
	//LivesHUD = CreateHudSynchronizer();
	
	//Hook Events for stuff
	HookEvent("player_death", event_player_death, EventHookMode_Pre); //Fired when someone dies
	HookEvent("player_spawn", event_player_spawn); //Fired when someone spawns
	HookEvent("player_hurt", event_player_hurt); //Fired when someone gets hurt
	HookEvent("teamplay_round_start", event_round_start); //Fired when the round starts
	HookEvent("arena_round_start", event_arena_start); //Fired just after you can start moving in Arena mode
	HookEvent("teamplay_round_win", event_round_end); //Fired when a round ends
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		iLives[iClient] = -1;
		iLivesGained[iClient] = 0;
		iDamage[iClient] = 0;
	}
}

public void OnConfigsExecuted()
{
	//Out-of-date config checker taken from VSH.
	char szOldVersion[64];
	GetConVarString(cvarVersion, szOldVersion, sizeof(szOldVersion));
	if (!StrEqual(szOldVersion, PLUGIN_VERSION, false)) LogError("[VSH Lives] Warning!: your config may be outdated. Back up your tf/cfg/sourcemod/vsh-lives.cfg file and delete it, and this plugin will generate a new one that you can then modify to your original values.");
	SetConVarString(FindConVar("vsh_lives_version"), PLUGIN_VERSION);

	////Get ConVar values
	//Bools
	g_bIsEnabled = GetConVarBool(cvarEnabled);
	g_bRespawnBlock = GetConVarBool(cvarRespawnBlock);
	g_bRespawnLastman = GetConVarBool(cvarRespawnLastman);
	//Ints
	g_iLives = GetConVarInt(cvarLives);
	g_iLivesDamage = GetConVarInt(cvarLivesDamage);
	g_iLivesMax = GetConVarInt(cvarLivesMax);
	//Floats
	g_flRespawnDelay = GetConVarFloat(cvarRespawnDelay);
}

public void OnClientPostAdminCheck(int iClient)
{
	iLives[iClient] = -1;
	iLivesGained[iClient] = 0;
	iDamage[iClient] = 0;
}

public OnClientDisconnect(int iClient) //Remove stuff when clients disconnect
{
	iLives[iClient] = -1;
	iLivesGained[iClient] = 0;
	iDamage[iClient] = 0;
}

public void CvarChange(Handle convar, const char[] oldValue, const char[] newValue) //Check for CVAR changes mid-round.
{
	if (convar == cvarVersion)
		SetConVarString(convar, PLUGIN_VERSION);
	else if (convar == cvarEnabled)
		g_bIsEnabled = GetConVarBool(convar);
	else if (convar == cvarLives)
		g_iLives = GetConVarInt(convar);
	else if (convar == cvarLivesDamage)
		g_iLivesDamage = GetConVarInt(convar);
	else if (convar == cvarLivesMax)
		g_iLivesMax = GetConVarInt(convar);
	else if (convar == cvarRespawnDelay)
		g_flRespawnDelay = GetConVarFloat(convar);
	else if (convar == cvarRespawnBlock)
		g_bRespawnBlock = GetConVarBool(convar);
	else if (convar == cvarRespawnLastman)
		g_bRespawnLastman = GetConVarBool(convar);
}

public Action event_round_start(Handle event, const char[] name, bool dontBroadcast)
{
	if (!CheckActive()) //Check if plugin and VSH are active on round start
		return Plugin_Continue;
	
	iHale = GetClientOfUserId(VSH_GetSaxtonHaleUserId());
	#if defined DEBUG
	PrintToChatAll("Hale: %N", iHale);
	#endif
	
	return Plugin_Continue;
}

public Action event_arena_start(Handle event, const char[] name, bool dontBroadcast)
{
	if (!CheckActive()) //Check if plugin and VSH are active on round start
		return Plugin_Continue;
	
	iHale = GetClientOfUserId(VSH_GetSaxtonHaleUserId());
	#if defined DEBUG
	PrintToChatAll("Hale: %N", iHale);
	#endif
	if (!IsValidClient(iHale)) //Check if Hale is valid
		return Plugin_Continue;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsValidClient(iClient))
			return Plugin_Continue;
		if (!IsClientParticipating(iClient) || !IsPlayerAlive(iClient))
		{
			iLives[iClient] = -1;
			return Plugin_Continue;
		}
		iLives[iClient] = g_iLives;
		iLivesGained[iClient] = 0;
		iDamage[iClient] = 0;
		
		int iLivesCanGain = g_iLivesMax - iLivesGained[iClient];
		CPrintToChat(iClient, "{olive}[VSH] {default}Lives left for this round: {unique}%i{olive} | {default}Extra lives you can gain this round through damage: {unique}%i{default}.", iLives[iClient], iLivesCanGain);
	}
	
	return Plugin_Continue;
}

public Action event_player_hurt(Handle event, const char[] name, bool dontBroadcast)
{
	if (!CheckActive() || VSH_GetRoundState() != VSHRState_Active || !g_iLivesDamage)
		return Plugin_Continue;
	
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int iDamageDealt = GetEventInt(event, "damageamount");
	
	if (iClient != iHale || iAttacker == iHale || !IsValidClient(iClient) || !IsValidClient(iAttacker))
		return Plugin_Continue;
	
	iDamage[iAttacker] += iDamageDealt;
	
	#if defined DEBUG
	PrintToChatAll("[DEBUG] %N's damage count: %i", iAttacker, iDamage[iAttacker]);
	#endif
	
	if (iDamage[iAttacker] >= g_iLivesDamage)
	{
		if (g_iLivesMax - iLivesGained[iAttacker] < 1)
		{
			iDamage[iAttacker] = 0;
			return Plugin_Continue;
		}
		iDamage[iAttacker] -= g_iLivesDamage;
		iLives[iAttacker]++;
		iLivesGained[iAttacker]++;
		CPrintToChat(iAttacker, "{olive}[VSH] {default}You just gained an extra life! {unique}%i{default} lives left this round.", iLives[iAttacker]);
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action event_player_death(Handle event, const char[] name, bool dontBroadcast)
{
	if (!CheckActive() || VSH_GetRoundState() != VSHRState_Active)
		return Plugin_Continue;
	
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	int iDeathFlags = GetEventInt(event, "death_flags");
	
	if (iClient == iHale || iDeathFlags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;
	
	int Hippies = 0; //Players who are fighting against Hale and are alive
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (i != iHale && IsClientParticipating(i) && IsPlayerAlive(i))
				Hippies++;
		}
	}
	
	if (iLives[iClient] > 0 && g_flRespawnDelay && Hippies > 1)
	{
		CreateTimer(g_flRespawnDelay, Timer_RespawnPlayer, iClient, TIMER_FLAG_NO_MAPCHANGE);
		CPrintToChat(iClient, "{olive}[VSH] {default}Respawning in {unique}%.2f{default} seconds...", g_flRespawnDelay);
		return Plugin_Continue;
	}
	else if (iLives[iClient] > 0 && (!g_flRespawnDelay || g_bRespawnLastman))
	{
		RequestFrame(Frame_RespawnPlayer, iClient);
		CPrintToChat(iClient, "{olive}[VSH] {default}Respawning in... {unique}NOW{default}!");
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action event_player_spawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (!CheckActive() || VSH_GetRoundState() != VSHRState_Active)
		return Plugin_Continue;

	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(iClient) || iClient == iHale)
		return Plugin_Continue;
	
	#if defined DEBUG
	PrintToChatAll("Player %N spawned", iClient);
	#endif
	if (iLives[iClient] < 1 && g_bRespawnBlock)
	{
		ForcePlayerSuicide(iClient); //Prevent players from spawning mid-round if they have no lives
		CPrintToChatEx(iClient, iClient, "{olive}[VSH] {teamcolor} No latespawns allowed{default}!");
		#if defined DEBUG
		PrintToChatAll("Player %N blocked", iClient);
		#endif
	}
	
	return Plugin_Continue;
}

public Action event_round_end(Handle event, const char[] name, bool dontBroadcast)
{
	if (!CheckActive())
		return Plugin_Continue;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		iLives[iClient] = -1;
		iLivesGained[iClient] = 0;
		iDamage[iClient] = 0;
	}
	
	return Plugin_Continue;
}

public Action Timer_RespawnPlayer(Handle hTimer, int iClient)
{
	if (!CheckActive() || VSH_GetRoundState() != VSHRState_Active)
		return Plugin_Continue;
	if (!IsValidClient(iClient) || IsPlayerAlive(iClient) || !IsClientParticipating(iClient))
		return Plugin_Continue;
	
	if (iLives[iClient] > 0)
	{
		TF2_RespawnPlayer(iClient);
		iLives[iClient] -= 1;
	}
	
	CPrintToChat(iClient, "{olive}[VSH] {default}You have {unique}%i{default} lives left!", iLives[iClient]);
	
	return Plugin_Continue;
}

public void Frame_RespawnPlayer(int iClient)
{
	if (!CheckActive() || VSH_GetRoundState() != VSHRState_Active)
		return;
	if (!IsValidClient(iClient) || IsPlayerAlive(iClient) || !IsClientParticipating(iClient))
		return;
	
	TF2_RespawnPlayer(iClient);
	if (iLives[iClient] > 0)
		iLives[iClient] -= 1;
	
	CPrintToChat(iClient, "{olive}[VSH] {default}You have {unique}%i{default} lives left!", iLives[iClient]);
}

public Action Command_ShowLives(iClient, iArgs)
{
	if (!IsValidClient(iClient) || VSH_GetRoundState() != VSHRState_Active)
		return Plugin_Handled;
	
	int iLivesCanGain = g_iLivesMax - iLivesGained[iClient];
	
	CPrintToChat(iClient, "{olive}[VSH] {default}Lives left for this round: {unique}%i{olive} | {default}Extra lives you can gain this round through damage: {unique}%i{default}.", iLives[iClient], iLivesCanGain);
	
	return Plugin_Handled;
}

stock CheckEnabled() //Check if the current map will play VSH
{
	if (VSH_IsSaxtonHaleModeMap() && g_bIsEnabled)
		return true;
	else
		return false;
}
stock CheckActive() //Check if the current round is VSH
{
	if (VSH_IsSaxtonHaleModeEnabled() && g_bIsEnabled)
		return true;
	else
		return false;
}

//Taken from Vs. Saxton Hale
stock bool IsValidClient(int iClient)
{
	return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

stock bool IsClientParticipating(iClient)
{
	if (IsSpectator(iClient) || IsReplayClient(iClient))
	{
		return false;
	}
	
	if (GetEntProp(iClient, Prop_Send, "m_bIsCoaching")) 
	{
		return false;
	}
	
	if (TF2_GetPlayerClass(iClient) == TFClass_Unknown)
	{
		return false;
	}
	
	return true;
}

stock bool IsSpectator(iClient)
{
	return GetEntityTeamNum(iClient) <= view_as<int>(TFTeam_Spectator);
}

stock bool IsReplayClient(iClient)
{
	return IsClientReplay(iClient) || IsClientSourceTV(iClient);
}

stock GetEntityTeamNum(iEnt)
{
	return GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
}
