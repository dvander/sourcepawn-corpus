#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define PLUGIN_VERSION "1.2.0"


static int iLastAction[MAXPLAYERS+1];
static Handle hCvar_CheckSpec = INVALID_HANDLE;
static bool bCheckSpec = false;
static Handle hCvar_AfkTime = INVALID_HANDLE;
static int iAfkTime = 420;
static Handle hCvar_KickOnFull = INVALID_HANDLE;
static bool bKickOnFull = true;
static Handle hCvar_AdminManageType = INVALID_HANDLE;
static int iAdminManageType = 0;
static Handle hCvar_AdminCmdAccess = INVALID_HANDLE;
static char sAdminCmdAccessString[256];

static Handle hCvar_VisibleMaxPlayers = INVALID_HANDLE;
static int iMaxVisiblePlayers = -1;


static bool bL4D = false;// only tested on l4d but should work on other games

public Plugin myinfo =
{
	name = "[Any]AutoKickAFK When ServerFull",
	author = "Lux",
	description = "Auto kicks a player who is afk when the server is full",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2569852"
};

public void OnPluginStart()
{
	EngineVersion EngineVer = GetEngineVersion();
	if(EngineVer == Engine_Left4Dead2 || EngineVer == Engine_Left4Dead)
		bL4D = true;
	
	hCvar_VisibleMaxPlayers = FindConVar("sv_visiblemaxplayers");
	if(hCvar_VisibleMaxPlayers != INVALID_HANDLE)
		HookConVarChange(hCvar_VisibleMaxPlayers, eConvarChanged);
	
	CreateConVar("konfull_AutoKickWhenFull_version", PLUGIN_VERSION, "AutoKickWhenFull plugin version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	hCvar_CheckSpec = CreateConVar("konfull_check_spec_for_movement", "0", "check spec team like players for movement [0 = consider spec as AFK! 1 = check as player]", FCVAR_NOTIFY);
	HookConVarChange(hCvar_CheckSpec, eConvarChanged);
	hCvar_AfkTime = CreateConVar("konfull_afk_time", "420", "(Seconds)afk time before they will get kicked", FCVAR_NOTIFY, true, 1.0);
	HookConVarChange(hCvar_AfkTime, eConvarChanged);
	hCvar_KickOnFull = CreateConVar("konfull_kick_on_full", "1", "Should we only kick when server is full [1 = true 0 = false]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(hCvar_KickOnFull, eConvarChanged);
	hCvar_AdminManageType = CreateConVar("konfull_admin_manage_type", "0", "How should admins be treated, [0 = Do nothing 1 = Move to spec 2 = kick them]", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	HookConVarChange(hCvar_AdminManageType, eConvarChanged);
	hCvar_AdminCmdAccess = CreateConVar("konfull_admin_access_cmd", "sm_ban", "This is admin immunity command (if empty will use adminflag ADMFLAG_BAN \"d\") Note: can be used for any command not just admin commands", FCVAR_NOTIFY);
	HookConVarChange(hCvar_AdminCmdAccess, eConvarChanged);
	
	AutoExecConfig(true, "_AutoKickWhenFull");
	CvarsChanged();
	
	CreateTimer(1.0, AutoKick, INVALID_HANDLE, TIMER_REPEAT);
}

public Action AutoKick(Handle hTimer)
{
	if(!IsServerFull() && bKickOnFull)
		return Plugin_Continue;
	
	static float fNow;
	fNow = GetEngineTime();
	
	static int i;
	for(i = 1; i <= MaxClients;i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		static bool bAdmin;
		bAdmin = CheckCommandAccess(i, sAdminCmdAccessString, ADMFLAG_BAN, false);
		if(iAdminManageType < 1 && bAdmin)
			continue;
		
		if(GetClientTeam(i) < 1)
			continue;
		
		if(iLastAction[i] < fNow - iAfkTime)
		{
			if(bAdmin && iAdminManageType == 1)
			{
				if(GetClientTeam(i) > 1)
					ChangeClientTeam(i, 1);
			}
			else
				KickClient(i, "Kicked for being AFK!");
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	static int iLastValues[MAXPLAYERS+1][3];
	
	if(IsFakeClient(iClient))
		return Plugin_Continue;
	
	if(!bCheckSpec)
		if(!CheckCommandAccess(iClient, sAdminCmdAccessString, ADMFLAG_BAN, false) || iAdminManageType > 1)
			if(GetClientTeam(iClient) == 1)
				return Plugin_Continue;
	
	if(bL4D)
	{
		if(IsMouseValsValid(iClient))
		{
			if(iLastValues[iClient][0] == iButtons && iLastValues[iClient][1] == iMouse[0] && iLastValues[iClient][2] == iMouse[1])
				return Plugin_Continue;
		}
		else if(iLastValues[iClient][0] == iButtons)
			return Plugin_Continue;
	}
	else
	{
		if(iLastValues[iClient][0] == iButtons && iLastValues[iClient][1] == iMouse[0] && iLastValues[iClient][2] == iMouse[1])
			return Plugin_Continue;
	}
	
	iLastAction[iClient] = RoundFloat(GetEngineTime());
	iLastValues[iClient][0] =  iButtons;
	iLastValues[iClient][1] =  iMouse[0];
	iLastValues[iClient][2] =  iMouse[1];
	
	return Plugin_Continue;
}

static bool IsMouseValsValid(int iClient)
{
	if(GetEntProp(iClient, Prop_Send, "m_iObserverMode") != 4)
		return true;
	
	static int iTarget;
	iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
	if(iTarget < 1 || iTarget > MaxClients)
		return true;
		
	if(!IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		return true;
	
	if(!GetEntProp(iTarget, Prop_Send, "m_isIncapacitated", 1))
		return true;
	
	return false;
}


public void OnClientPutInServer(int client)
{
	SetClientTime(client);
}

public void OnClientAuthorized(int client, const char[] auth)
{
	SetClientTime(client);
}

void SetClientTime(int client)
{
	iLastAction[client] = RoundFloat(GetEngineTime());
}


static bool IsServerFull()
{
	static int iCount;
	iCount = 0;
	static int i;
	for(i = 1; i <= MaxClients; i++) 
	{
		if(!IsClientConnected(i) || IsFakeClient(i))
			continue;
		
		iCount++;
	}
	
	if(iMaxVisiblePlayers < 1)
		return (GetMaxHumanPlayers() <= iCount);
	return (iMaxVisiblePlayers <= iCount);
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	bCheckSpec = GetConVarInt(hCvar_CheckSpec) > 0;
	iAfkTime = GetConVarInt(hCvar_AfkTime);
	
	if(hCvar_VisibleMaxPlayers != INVALID_HANDLE)
		iMaxVisiblePlayers = GetConVarInt(hCvar_VisibleMaxPlayers);
	
	bKickOnFull = GetConVarInt(hCvar_KickOnFull) > 0;
	iAdminManageType = GetConVarInt(hCvar_AdminManageType);
	GetConVarString(hCvar_AdminCmdAccess, sAdminCmdAccessString, sizeof(sAdminCmdAccessString));
}