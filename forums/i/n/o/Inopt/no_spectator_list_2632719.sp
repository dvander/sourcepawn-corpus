#pragma semicolon 1

#define PLUGIN_VERSION "0.2.1"

#include <sourcemod>
#include <sdktools_functions>
#include "../sendproxy"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "No spectator list",
	author = "CurT",
	description = "Prevents for cheats to get info about spectating players",
	version = PLUGIN_VERSION,
	url = "https://SourceGames.RU"
};

enum
{
	CVAR_SHOULDHIDEADMINS,
	CVAR_SHOULDHIDE,
	CVAR_ADMINFLAG,
	MAXCVARS
};

bool g_bLate;
bool g_bShouldHideOnlyAdmins = false;
bool g_bShouldHideInfo = false;

ConVar g_hCVars[MAXCVARS] =  { null, ... };

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] cError, int iLen)
{
	g_bLate = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCVars[CVAR_SHOULDHIDEADMINS] = CreateConVar("sm_speclist_hideadminsonly", "0", "Should plugin hide spectating admins?", FCVAR_DONTRECORD /*Don't transmit this cvar to clients*/);
	g_hCVars[CVAR_SHOULDHIDE] = CreateConVar("sm_speclist_shouldhide", "1", "Should plugin hide info about spectators?", FCVAR_DONTRECORD);
	g_hCVars[CVAR_ADMINFLAG] = CreateConVar("sm_speclist_admflag", "b", "What flag to use to check client admin?", FCVAR_DONTRECORD);
	
	HookEvent("player_team", Event_OnPlayerChangeTeam, EventHookMode_Pre);
	
	RegPluginLibrary("NoSpecList_v" ... PLUGIN_VERSION); // probably will be useful for somebody?
}

public void OnConfigsExecuted()
{
	g_bShouldHideOnlyAdmins = g_hCVars[CVAR_SHOULDHIDEADMINS].BoolValue;
	g_hCVars[CVAR_SHOULDHIDEADMINS].AddChangeHook(CVCCB_OnShouldHideAdminsCVarStateChanged);
	
	g_bShouldHideInfo = g_hCVars[CVAR_SHOULDHIDE].BoolValue;
	g_hCVars[CVAR_SHOULDHIDE].AddChangeHook(CVCCB_OnShouldHideCVarStateChanged);
	
	if (g_bLate && g_bShouldHideInfo)
		for (int iClients = 1; iClients <= MaxClients; iClients++)
			if (IsClientInGame(iClients))
				SetupHooks(iClients);
	
	EngineVersion iVersion = GetEngineVersion();
	int iPlayerResource = -1;
	switch (iVersion)
	{
		case Engine_TF2: iPlayerResource = FindEntityByClassname(-1, "tf_player_manager");
		case Engine_CSGO: iPlayerResource = FindEntityByClassname(-1, "cs_player_manager");
		default: LogError("Seems like this plugin runned in unsupported game. Some functional may work incorrect!");
	}
	if (iPlayerResource != -1)
		for (int iClients = 1; iClients <= MaxClients; iClients++)
			SendProxy_HookArrayProp(iPlayerResource, "m_bConnected", iClients, Prop_Int, SendProxy_OnConnectedStatusSends);
	if (iVersion == Engine_TF2 && iPlayerResource != -1)
		for (int iClients = 1; iClients <= MaxClients; iClients++)
			SendProxy_HookArrayProp(iPlayerResource, "m_bArenaSpectator", iClients, Prop_Int, SendProxy_OnConnectedStatusSends);
}

public void OnClientPostAdminCheck(int iClient)
{
	if (g_bShouldHideInfo)
		SetupHooks(iClient);
}

public void OnClientDisconnect(int iClient)
{
	DestroyHooks(iClient);
}

public Action SendProxy_OnSpectatorSends(int iEntity, const char[] cPropName, int &iValue, int iElement, int iClient)
{
	if (iEntity == iClient)
		return Plugin_Continue;
	if (iValue && GetClientTeam(iEntity) < 2)
	{
		iValue = -1;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action SendProxy_OnConnectedStatusSends(int iEntity, const char[] cPropName, int &iValue, int iElement, int iClient)
{
	if (!g_bShouldHideInfo)
		return Plugin_Continue;
	if (iElement == iClient)
		return Plugin_Continue;
	//if (!IsValidClient(iElement)) //P.S. iClient is always valid, we do not need to check it, but iElement may be invalid client, and we need to check it
	if (!IsClientInGame(iElement))
		return Plugin_Continue;
	if ((g_bShouldHideOnlyAdmins ? IsClientAdmin(iElement) : true) && GetClientTeam(iElement) < 2)
	{
		iValue = 0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void CVCCB_OnShouldHideAdminsCVarStateChanged(ConVar hCVar, const char[] cOldValue, const char[] cNewValue)
{
	g_bShouldHideOnlyAdmins = !!StringToInt(cNewValue);
}

public void CVCCB_OnShouldHideCVarStateChanged(ConVar hCVar, const char[] cOldValue, const char[] cNewValue)
{
	g_bShouldHideInfo = !!StringToInt(cNewValue);
	for (int iClients = 1; iClients <= MaxClients; iClients++)
		if (IsClientInGame(iClients))
			g_bShouldHideInfo ? SetupHooks(iClients) : DestroyHooks(iClients);
}

public Action Event_OnPlayerChangeTeam(Event hEvent, const char[] cName, bool dDontBroadCast)
{
	if (!g_bShouldHideInfo)
		return Plugin_Continue;
	
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (g_bShouldHideOnlyAdmins ? IsClientAdmin(iClient) : true)
	{
		hEvent.BroadcastDisabled = true;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

//statics

void SetupHooks(int iClient)
{
	if (HasEntProp(iClient, Prop_Send, "m_hObserverTarget") && !SendProxy_IsHooked(iClient, "m_hObserverTarget"))
		SendProxy_Hook(iClient, "m_hObserverTarget", Prop_Int, SendProxy_OnSpectatorSends);
	if (HasEntProp(iClient, Prop_Send, "m_iObserverMode") && !SendProxy_IsHooked(iClient, "m_iObserverMode"))
		SendProxy_Hook(iClient, "m_iObserverMode", Prop_Int, SendProxy_OnSpectatorSends); //this not a mistake, we will use SendProxy_OnSpectatorSends callback for m_iObserverMode too
}

void DestroyHooks(int iClient)
{
	if (SendProxy_IsHooked(iClient, "m_hObserverTarget"))
		SendProxy_Unhook(iClient, "m_hObserverTarget", SendProxy_OnSpectatorSends);
	if (SendProxy_IsHooked(iClient, "m_iObserverMode"))
		SendProxy_Unhook(iClient, "m_iObserverMode", SendProxy_OnSpectatorSends);
}

stock bool IsValidClient(int iClient)
{	
	if (iClient <= 0 || iClient > MaxClients)
		return false;
	if (!IsClientInGame(iClient) || !IsClientConnected(iClient))
		return false;
	if (IsClientSourceTV(iClient) || IsClientReplay(iClient))
		return false;
	return true;
}

stock bool IsClientAdmin(int iClient)
{
	char cBuf[2]; //I know it should be a multiple of 4 bytes (cell_t == 4) and will be alignment, but for better readability array size will be equal to 2 in the code
	g_hCVars[CVAR_ADMINFLAG].GetString(cBuf, 2);
	if (!cBuf[0])
		return false;
	if (GetUserFlagBits(iClient) & ReadFlagString(cBuf))
		return true;
	return false;
}