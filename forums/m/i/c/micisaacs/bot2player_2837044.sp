/****************************************
 * Bot2Player
 * -------------------------
 * Allows players to control bots after they've died with the key "use" (usually "E")
 * -------------------------
 ****************************************/

#include <sourcemod>
#include <cstrike>
#include <smlib>
#include <sm_logger>

#pragma semicolon			1

#define PLUGIN_NAME 		"Bot2Player"
#define PLUGIN_AUTHOR 		"MeroWinger"
#define PLUGIN_DESCRIPTION 	"Allows players to control bots after they've died (forked from Bot2Player (public) by Bittersweet)"
#define PLUGIN_VERSION 		"2024.01.27.10.30"

// Debug: 1= Enable, 0 = Disable
#define _DEBUG 				0

//SM-Logger
char LOG_TAGS[][] = {"CORE", "WARNING"}; // <- adds new tag here (channel names)
// Bitwise values definitions
enum sm_log_enum
{
	SML_CORE = 1,
	SML_WARN,
	// <- adds new bit here
}

ConVar cvar_b2pEnabled;
ConVar cvar_BotTakeOverRoundEndTeleport;
ConVar cvar_RoundRestartDelay;
ConVar cvar_BotTakeOverStartingCost;
ConVar cvar_BotTakeOverCostIncrement;

//These are default values, actually set from bot2player.cfg file
bool b2pEnabled;
bool BotTakeOverRoundEndTeleport;
int BotTakeOverStartingCost;
int BotTakeOverCostIncrement;

bool bHideDeath[MAXPLAYERS + 1] = {false, ...};

int ClientSpecClient[MAXPLAYERS + 1] = {0, ...};
int ClientTookover[MAXPLAYERS + 1] = {0, ...};
int WrongTeamWarning[MAXPLAYERS + 1] = {0, ...};
int TeleportWarning[MAXPLAYERS + 1] = {0, ...};
int BotTakeverCost[MAXPLAYERS + 1] = {0, ...};
int Nades[MAXPLAYERS + 1][3];

float RoundRestartDelay = 0.0;
float WeaponStripDelay = 0.0;
float WeaponStripOffset = 0.3;

int iTargetActiveWeapon;
char iTargetActiveWeaponName[32];
int iTargetWeapon[5];
int iTargetClip[5];
int iTargetAmmo[5];
int g_offObserverTarget;
int g_iAccount = -1;
int gameround = 1;

public Plugin myinfo =
{
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version     = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	SMLoggerInit(LOG_TAGS, sizeof(LOG_TAGS), SML_CORE|SML_WARN, SML_FILE); // setup logger
	PrintToServer("[%s %s] - Loaded", PLUGIN_NAME, PLUGIN_VERSION);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	g_offObserverTarget = FindSendPropInfo("CBasePlayer", "m_hObserverTarget");
	if(g_offObserverTarget == -1)
	{
		SetFailState("Expected to find the offset to m_hObserverTarget, couldn't.");
	}
	AddCommandListener(NewTarget, "spec_next");
	AddCommandListener(NewTarget, "spec_prev");
	CreateConVar("sm_bot2player_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_b2pEnabled = CreateConVar("sm_bot2player_enabled", "1", "Enable the plugin?", FCVAR_NONE , true, 0.0, true, 1.0);
	cvar_BotTakeOverRoundEndTeleport = CreateConVar("sm_bot2player_RoundEndTeleport", "0", "Enable teleporting on round end?", FCVAR_NONE , true, 0.0, true, 1.0);
	cvar_BotTakeOverStartingCost = CreateConVar("sm_bot2player_price", "1000", "Starting cost to take over a BOT (resets each map)");
	cvar_BotTakeOverCostIncrement = CreateConVar("sm_bot2player_increase", "250", "Amount to raise price each time a player takes over a BOT");
	if (cvar_b2pEnabled == INVALID_HANDLE) 
	{
		char FailReason[256];
		Format(FailReason, sizeof(FailReason), "[%s] - cvar_b2pEnabled returned INVALID_HANDLE", PLUGIN_NAME);
		RaiseError(FailReason);
	}
	if (cvar_BotTakeOverRoundEndTeleport == INVALID_HANDLE) 
	{
		char FailReason[256];
		Format(FailReason, sizeof(FailReason), "[%s] - cvar_BotTakeOverRoundEndTeleport INVALID_HANDLE", PLUGIN_NAME);
		RaiseError(FailReason);
	}
	cvar_RoundRestartDelay = FindConVar("mp_round_restart_delay"); 
	if (cvar_RoundRestartDelay == INVALID_HANDLE)
	{
		char FailReason[256];
		Format(FailReason, sizeof(FailReason), "[%s] - cvar_RoundRestartDelay returned INVALID_HANDLE", PLUGIN_NAME);
		RaiseError(FailReason);
	}
	AutoExecConfig(true);
}
public void OnConfigsExecuted()
{
	//based on 5.0 second mp_round_restart_delay:  4.6 just a hair early, 5.0 too late - 4.7 seems good - use mp_round_restart_delay - 0.3
	RoundRestartDelay = GetConVarFloat(cvar_RoundRestartDelay);
	WeaponStripDelay = RoundRestartDelay - WeaponStripOffset;
	b2pEnabled = GetConVarBool(cvar_b2pEnabled);
	BotTakeOverRoundEndTeleport = GetConVarBool(cvar_BotTakeOverRoundEndTeleport);
	BotTakeOverStartingCost = GetConVarInt(cvar_BotTakeOverStartingCost);
	BotTakeOverCostIncrement = GetConVarInt(cvar_BotTakeOverCostIncrement);
	HookConVarChange(cvar_b2pEnabled, cvar_b2pEnabledChange);
	HookConVarChange(cvar_BotTakeOverRoundEndTeleport, cvar_RoundEndTeleportChange);
	HookConVarChange(cvar_RoundRestartDelay, cvar_RoundRestartDelayChange);
	HookConVarChange(cvar_BotTakeOverStartingCost, cvar_StartCostChange);
	HookConVarChange(cvar_BotTakeOverCostIncrement, cvar_CostIncreaseChange);
}
public cvar_b2pEnabledChange(Handle convar, const char[] oldValue, const char[] newValue)
{	
	b2pEnabled = GetConVarBool(cvar_b2pEnabled);
}
public cvar_RoundEndTeleportChange(Handle convar, const char[] oldValue, const char[] newValue)
{	
	BotTakeOverRoundEndTeleport = GetConVarBool(cvar_BotTakeOverRoundEndTeleport);
}
public cvar_RoundRestartDelayChange(Handle convar, const char[] oldValue, const char[] newValue)
{	
	RoundRestartDelay = GetConVarFloat(cvar_RoundRestartDelay);
	WeaponStripDelay = RoundRestartDelay - WeaponStripOffset;
}
public cvar_StartCostChange(Handle convar, const char[] oldValue, const char[] newValue)
{	
	BotTakeOverStartingCost = GetConVarInt(cvar_BotTakeOverStartingCost);
}
public cvar_CostIncreaseChange(Handle convar, const char[] oldValue, const char[] newValue)
{	
	BotTakeOverCostIncrement = GetConVarInt(cvar_BotTakeOverCostIncrement);
}
public void OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		BotTakeverCost[i] = BotTakeOverStartingCost;
		TeleportWarning[i] = 0;
	}	
	gameround = 1;
}
public void Event_RoundStart(Event eventRoundStart, const char[] name, bool dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		ClientSpecClient[i] = 0;
		WrongTeamWarning[i] = 0;
	}
}
public void Event_RoundEnd(Event eventRoundEnd, const char[] name, bool dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		ClientSpecClient[i] = 0;
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientObserver(i) && ClientTookover[i])
		{
			if (IsClientConnected(i) && BotTakeOverRoundEndTeleport)
			{
				PrintCenterText(i, "Since you took over a BOT this last round, you get teleported");
				TeleportWarning[i] = 1;
				float iTargetOrigin[3];
				iTargetOrigin[0] = 0.0;
				iTargetOrigin[1] = 0.0;
				iTargetOrigin[2] = 0.0;
				NormalizeVector(iTargetOrigin, iTargetOrigin);
				TeleportEntity(i, iTargetOrigin, NULL_VECTOR, NULL_VECTOR);
			}
			CreateTimer(WeaponStripDelay, StripWeapons, GetClientUserId(i));
		}
		ClientTookover[i] = 0;
		WrongTeamWarning[i] = 0;
	}
	gameround++;
}
public Action OnPlayerRunCmd(iClient, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	if (!IsClientConnected(iClient) || !(buttons & IN_USE) || IsPlayerAlive(iClient) || !b2pEnabled || !IsClientObserver(iClient)) 
		return Plugin_Continue;
	int iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
	int ClientCash = GetMoney(iClient);
	if (IsValidClient(iTarget) && IsFakeClient(iTarget) && GetClientTeam(iClient) == GetClientTeam(iTarget) && ClientCash >= BotTakeverCost[iClient])
	{
		//Get all of BOTs stats
		float iTargetOrigin[3];
		float iTargetAngles[3];
		GetClientAbsOrigin(iTarget, iTargetOrigin);
		GetClientAbsAngles(iTarget, iTargetAngles);
		int iTargetHealth = GetClientHealth(iTarget);
		int iTargetArmor = GetClientArmor(iTarget);
		int iTargetHasHelmet = GetEntProp(iTarget, Prop_Send, "m_bHasHelmet");
		iTargetActiveWeapon = Client_GetActiveWeapon(iTarget);
		for (int i = 0; i <= 1; i++)
		{
			iTargetWeapon[i] = Client_GetWeaponBySlot(iTarget, i);
			if (iTargetWeapon[i] > -1) 
			{
				Client_SetActiveWeapon(iTarget, iTargetWeapon[i]);
				Client_GetActiveWeaponName(iTarget, iTargetActiveWeaponName, sizeof(iTargetActiveWeaponName));
				iTargetClip[i] = Weapon_GetPrimaryClip(iTargetWeapon[i]);
				Client_GetWeaponPlayerAmmo(iTarget, iTargetActiveWeaponName, iTargetAmmo[i]);
				//addon
				#if _DEBUG
				char b_iTargetWeaponName[20];
				char b_iTargetName[64];
				GetClientName(iTarget, b_iTargetName, sizeof(b_iTargetName));
				Format(b_iTargetWeaponName, sizeof(b_iTargetWeaponName), "%s", iTargetActiveWeaponName);
				SMLogTag(SML_CORE, "TargetInit | iTargetName: %s; iTargetWeaponName: %s; ", b_iTargetName, b_iTargetWeaponName);
				#endif
				//addon end
			}
			else
			{
				iTargetClip[i] = 0;
				iTargetAmmo[i] = 0;
			}
		}
		//Check if target is alive one last time - fix for Known issue# 2
		if (!IsClientConnected(iTarget) || !IsValidClient(iTarget) || !IsPlayerAlive(iTarget))
		{
			PrintHintText(iClient, "The BOT you tried to take over is no longer available for take over");
			return Plugin_Continue;
		}
		//Set all of humans stats, but not weapons
		CreateTimer(0.01, Give_iTargetWeaponsTo_iClient, iClient);
		Client_SetArmor(iClient, iTargetArmor);
		SetEntProp(iClient, Prop_Send, "m_bHasHelmet", iTargetHasHelmet ? 1 : 0);
		GetAllClientGrenades(iTarget);
		//CreateTimer(0.05, Give_iTargetWeaponsTo_iClient, iClient)
		//Take control
		bHideDeath[iTarget] = true;
		ClientTookover[iClient] = 1;
		ClientSpecClient[iClient] = 0;
		ClientCash = ClientCash - BotTakeverCost[iClient];
		SetMoney(iClient, ClientCash);
		BotTakeverCost[iClient] = BotTakeverCost[iClient] + BotTakeOverCostIncrement;
		//check for last player on team alive
		int MyTeam = GetClientTeam(iClient);
		int TeamMatesAlive = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i) || i == iClient) 
				continue;
			if (IsClientInGame(iClient) && IsClientInGame(i) && IsPlayerAlive(i) && MyTeam == GetClientTeam(i))
			{
				TeamMatesAlive++;
			}
		}
		Handle NoEndRoundHandle = FindConVar("mp_ignore_round_win_conditions");
		if (TeamMatesAlive == 1)
		{
			SetConVarInt(NoEndRoundHandle, 1);
		}
		ForcePlayerSuicide(iTarget);
		CS_RespawnPlayer(iClient);
		SetEntityHealth(iClient, iTargetHealth);
		TeleportEntity(iClient, iTargetOrigin, iTargetAngles, NULL_VECTOR);
		SetConVarInt(NoEndRoundHandle, 0);
		PrintToChatAll("%N took control of %N", iClient, iTarget);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public GetAllClientGrenades(client)
{
	Nades[client][0] = 0;
	Nades[client][1] = 0;
	Nades[client][2] = 0;
	int offsNades = FindDataMapInfo(client, "m_iAmmo") + (11 * 4);
	int granadesnr = GetEntData(client, offsNades);
	int lastgranadesnr = 0;
	if (granadesnr > lastgranadesnr)
	{
		// HE Nades
		Nades[client][0] = granadesnr;
		lastgranadesnr = granadesnr;
	}
	offsNades += 4;
	granadesnr += GetEntData(client, offsNades);
	if (granadesnr > lastgranadesnr)
	{
		// Flashbangs
		Nades[client][1] = granadesnr - lastgranadesnr;
		lastgranadesnr = granadesnr;
	}
	offsNades += 4;
	granadesnr += GetEntData(client, offsNades);
	if (granadesnr > lastgranadesnr)
	{
		// Smoke Nades
		Nades[client][2] = granadesnr - lastgranadesnr;
		lastgranadesnr = granadesnr;
	}
	return granadesnr;
}
public OnClientPostAdminCheck(client)
{
	BotTakeverCost[client] = BotTakeOverStartingCost;
	ClientSpecClient[client] = 0;
	ClientTookover[client] = 0;
	WrongTeamWarning[client] = 0;
}
public Action StripWeapons(Handle timer, any UserID)
{
	int client = GetClientOfUserId(UserID);
	if (client && IsClientInGame(client))
	{
	Client_RemoveAllWeapons(client);
	Client_GiveWeapon(client, "weapon_knife", true);
	}
	return Plugin_Continue;
}
public Action NewTarget(iClient, const char[] cmd, args)
{
	int iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
	if (!b2pEnabled || !IsValidClient(iTarget) || !IsClientObserver(iClient)) 
		return Plugin_Continue;
	CreateTimer(0.1, DisplayTakeOverMessage, iClient);
	return Plugin_Continue;
}
public Action DisplayTakeOverMessage(Handle timer, any iClient)
{
	if (!b2pEnabled || !IsClientConnected(iClient)) 
		return Plugin_Continue;
	int ClientTeam = 0;
	if (IsClientInGame(iClient)) 
		ClientTeam = GetClientTeam(iClient);
	if (ClientTeam < 2) 
		return Plugin_Continue;
	int iTarget = -1;
	iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
	if (iTarget == -1) 
		return Plugin_Continue;
	char BOTName[64];
	GetClientName(iTarget, BOTName, sizeof(BOTName));
	if (!IsValidClient(iTarget) || !IsClientObserver(iClient)) 
		return Plugin_Continue;
	ClientSpecClient[iClient] = iTarget;
	int ClientCash = GetMoney(iClient);
	if (ClientCash >= BotTakeverCost[iClient])
	{
		if (IsFakeClient(iTarget))
		{
			if (ClientTeam == GetClientTeam(iTarget))
			{
				if (ClientCash >= BotTakeverCost[iClient])
				{
					PrintHintText(iClient, "For $%i - Press the Use key [default E] to take control of %s", BotTakeverCost[iClient], BOTName);
					return Plugin_Continue;
				}
				else
				{
					PrintHintText(iClient, "You need $%i to take over any BOTs (the price increases each time you do)", BotTakeverCost[iClient]);
					return Plugin_Continue;
				}
			}
			else
			{
				PrintHintText(iClient, "You can't take over BOTs that aren't on your team");
				return Plugin_Continue;
			}
		}
		else
		{
			PrintHintText(iClient, "Spectate a BOT if you want to take over a BOT");
		}
	}
	else
	{
		PrintHintText(iClient, "You need $%i to take over any BOTs (the price increases each time you do)", BotTakeverCost[iClient]);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public Action Event_PlayerDeath(Handle EventPlayerDeath, const char[] name, bool dontBroadcast)
{
	if (!b2pEnabled) 
		return Plugin_Continue;
	int iClient = GetClientOfUserId(GetEventInt(EventPlayerDeath, "userid"));
	if (!IsClientConnected(iClient)) 
		return Plugin_Continue;
	if (!IsFakeClient(iClient)) CreateTimer(6.75, DisplayTakeOverMessage, iClient);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i < GetClientCount(true))
		{
			int ClientCash = GetMoney(i);
			if (IsClientConnected(iClient) && IsClientConnected(i) && IsClientInGame(i) && IsClientObserver(i) && ClientSpecClient[i] == iClient && ClientCash >= BotTakeverCost[i])
			{
				PrintHintText(i, "%N died - You can't control dead BOTs", iClient);
				ClientSpecClient[i] = 0;
			}
		}
	}
	if (!bHideDeath[iClient]) 
		return Plugin_Continue;
	CreateTimer(0.2, tDestroyRagdoll, iClient);
	return Plugin_Handled; // Disable the killfeed notification for takeovers
}
public Action tDestroyRagdoll(Handle timer, any iClient)
{
	int iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
	bHideDeath[iClient] = false;
	if (iRagdoll < 0) 
		return Plugin_Continue;
	AcceptEntityInput(iRagdoll, "kill");
	return Plugin_Continue;
}
public Action Give_iTargetWeaponsTo_iClient(Handle timer, any iClient)
{
	for (int i = 0; i <= 1; i++)
	{
		if (iTargetWeapon[i] != INVALID_ENT_REFERENCE)
		{
			Client_EquipWeapon(iClient, iTargetWeapon[i], false);
			Client_SetActiveWeapon(iClient, iTargetWeapon[i]);
			Client_GetActiveWeaponName(iClient, iTargetActiveWeaponName, sizeof(iTargetActiveWeaponName));
			Client_SetWeaponClipAmmo(iClient, iTargetActiveWeaponName, iTargetClip[i]);
			Client_SetWeaponPlayerAmmo(iClient, iTargetActiveWeaponName, iTargetAmmo[i]);
			//addon
			#if _DEBUG
			char b_iClientName[64];
			char b_iTargetWeaponName[20];
			GetClientName(iClient, b_iClientName, sizeof(b_iClientName));
			//Format(b_iClient, sizeof(b_iClient), "%d", iClient);
			Format(b_iTargetWeaponName, sizeof(b_iTargetWeaponName), "%s", iTargetActiveWeaponName);
			SMLogTag(SML_CORE, "SourceInit | iClientName: %s; iTargetWeaponName: %s; ", b_iClientName, b_iTargetWeaponName);
			#endif
			//addon end
		}
		Client_SetActiveWeapon(iClient, iTargetActiveWeapon);
	}
	if (Nades[iClient][0] > 0) 
		Client_GiveWeapon(iClient, "weapon_hegrenade", false);
	if (Nades[iClient][1] > 0) 
		Client_GiveWeapon(iClient, "weapon_flashbang", false);
	if (Nades[iClient][1] > 1) 
		Client_GiveWeapon(iClient, "weapon_flashbang", false);
	if (Nades[iClient][2] > 0) 
		Client_GiveWeapon(iClient, "weapon_smokegrenade", false);
	return Plugin_Continue;
}

stock FindRagdollClosestToEntity(int iEntity, float fLimit)
{
	int iSearch = -1;
	int iReturn = -1;
	float fLowest = -1.0;
	float fVectorDist;
	float fEntityPos[3];
	float fRagdollPos[3];
	if (!IsValidEntity(iEntity)) 
		return iReturn;
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityPos);
	while ((iSearch = FindEntityByClassname(iSearch, "tf_ragdoll")) != -1)
	{
		GetEntPropVector(iSearch, Prop_Send, "m_vecRagdollOrigin", fRagdollPos);
		fVectorDist = GetVectorDistance(fEntityPos, fRagdollPos);
		if (fVectorDist < fLimit && (fVectorDist < fLowest || fLowest == -1.0))
		{
			fLowest = fVectorDist;
			iReturn = iSearch;
		}
	}
	return iReturn;
}
stock bool IsValidClient(iClient) 
{
	if (iClient <= 0 ||	iClient > MaxClients ||	!IsClientInGame(iClient)) 
		return false;
	return true;
}
public int GetMoney(client)
{
	if (!IsClientConnected(client) || !IsClientInGame(client)) 
		return 0;
	if (g_iAccount != -1)
	{
		return GetEntData(client, g_iAccount);
	}
	else
	{
		return 0;
	}
}
public void SetMoney(client, amount)
{
	if (!IsClientConnected(client) || !IsClientInGame(client)) 
		return;
	if (g_iAccount != -1)
	{
		SetEntData(client, g_iAccount, amount);
	}
}
public void RaiseError(char[] FailReason)
{
	SMLogTag(SML_CORE, "[%s] - Fatal Error: %s", PLUGIN_NAME, FailReason);
	SetFailState("[%s] - Fatal Error: %s", PLUGIN_NAME, FailReason);
	LogError("[%s] - Fatal Error: %s", PLUGIN_NAME, FailReason);
}
public void Event_RoundFreezeEnd(Event eventRoundFreezeEnd, const char[] name, bool dontBroadcast)
{
	//This entire routine is for debugging only
	SMLogTag(SML_CORE, "Round %i -----------------------------------------------------------------------", gameround);
	PrintToServer("Round %i -----------------------------------------------------------------------", gameround);
	for (new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsClientObserver(i)) 
			continue;
		new TempWeapon[5];
		for (new ii = 0; ii <= 4; ii++)
		{
			TempWeapon[ii] = Client_GetWeaponBySlot(i, ii);
			if (TempWeapon[ii] > -1) 
			{
				char Weapon[32];
				GetEdictClassname(TempWeapon[ii], Weapon, sizeof(Weapon));
				if (ii == 3)
				{
					new tnades = GetAllClientGrenades(i);
					if (tnades)
					{
						SMLogTag(SML_CORE, "Nade report for %N:", i);
						if (Nades[i][0]) SMLogTag(SML_CORE, "%i HE Nades", Nades[i][0]);
						if (Nades[i][1]) SMLogTag(SML_CORE, "%i Flash Nades", Nades[i][1]);
						if (Nades[i][2]) SMLogTag(SML_CORE, "%i Smoke Nades", Nades[i][2]);
						SMLogTag(SML_CORE, "Line 114 - Total = %i", tnades);
					}
				}
			}
		}
	}
}
//End of