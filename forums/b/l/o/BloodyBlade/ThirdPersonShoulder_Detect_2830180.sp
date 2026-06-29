#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5.3"

public Plugin myinfo =
{
	name = "ThirdPersonShoulder_Detect",
	author = "MasterMind420 & Lux",
	description = "Detects thirdpersonshoulder command for other plugins to use",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2529779"
};

static bool bHooked = false;
static bool bVersus = false;
static bool bThirdPerson[MAXPLAYERS + 1] = {false, ...};
static bool bThirdPersonFix[MAXPLAYERS + 1] = {false, ...};
static ConVar hThirdPersonShoulder_Detect_On, hCvar_GameMode;
GlobalForward g_hOnThirdPersonChanged;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hOnThirdPersonChanged = new GlobalForward("TP_OnThirdPersonChanged", ET_Event, Param_Cell, Param_Cell);
	RegPluginLibrary("ThirdPersonShoulder_Detect");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("ThirdPersonShoulder_Detect_Version", PLUGIN_VERSION, "Version Of Plugin", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hThirdPersonShoulder_Detect_On = CreateConVar("third_person_shoulder_detect_on", "1.0", "Plugin on/off", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);

	hThirdPersonShoulder_Detect_On.AddChangeHook(eConvarPluginOnChanged);
	hCvar_GameMode = FindConVar("mp_gamemode");
	hCvar_GameMode.AddChangeHook(eConvarChanged);

	AutoExecConfig(true, "ThirdPersonShoulder_Detect");

	CreateTimer(0.25, tThirdPersonCheck, INVALID_HANDLE, TIMER_REPEAT);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void eConvarPluginOnChanged(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	IsAllowed();
}

void eConvarChanged(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void IsAllowed()
{
	bool bPluginOn = hThirdPersonShoulder_Detect_On.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		CvarsChanged();
		HookEvent("player_team", ePlayerEvent);
		HookEvent("player_death", ePlayerEvent);
		HookEvent("survivor_rescued", ePlayerEvent);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("player_team", ePlayerEvent);
		UnhookEvent("player_death", ePlayerEvent);
		UnhookEvent("survivor_rescued", ePlayerEvent);
	}
}

void CvarsChanged()
{
	char sGamemode[7];
	hCvar_GameMode.GetString(sGamemode, sizeof(sGamemode));

	static bool bWasVersus;
	bVersus = StrEqual("versus", sGamemode, false);
	if(bVersus)
	{
		for(int i = 1; i <= MaxClients; i++)
			if(__IsValidClient(i))
				TP_PushForwardToPlugins(i, true, false);
		bWasVersus = true;
	}
	else
	{
		if(bWasVersus)
			for(int i = 1; i <= MaxClients; i++)
				if(__IsValidClient(i))
					TP_PushForwardToPlugins(i);
				
		bWasVersus = false;
	}
}

Action tThirdPersonCheck(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(__IsValidClient(i) && !IsFakeClient(i))
		{
			QueryClientConVar(i, "c_thirdpersonshoulder", QueryClientConVarCallback);
		}
	}
	return Plugin_Continue;
}

void QueryClientConVarCallback(QueryCookie sCookie, int iClient, ConVarQueryResult sResult, const char[] sCvarName, const char[] sCvarValue)
{
	static bool bLastVal;
	bLastVal = bThirdPerson[iClient];

	//THIRDPERSON
	if(!StrEqual(sCvarValue, "0"))
	{
		if(bThirdPersonFix[iClient])
		{
			bThirdPerson[iClient] = false;
		}
		else
			bThirdPerson[iClient] = true;
	}
	else //FIRSTPERSON
	{
		if(IsClientInGame(iClient))
		{
			if(IsPlayerAlive(iClient))// just incase tps gets toggled while dead.
			{
				bThirdPersonFix[iClient] = false;
			}
			bThirdPerson[iClient] = false;
		}
	}

	if(bLastVal != bThirdPerson[iClient])
	{
		if(bVersus)
		{
			TP_PushForwardToPlugins(iClient, true, false);
			return;
		}
		TP_PushForwardToPlugins(iClient);
	}
}

static void TP_PushForwardToPlugins(int iClient, bool bOverride=false, bool bIsThirdPerson=false)
{
	Call_StartForward(g_hOnThirdPersonChanged);
	Call_PushCell(iClient);
	if(bOverride)
	{
		Call_PushCell(bIsThirdPerson);
	}
	else
	{
		Call_PushCell(bThirdPerson[iClient]);
	}
	Call_Finish();
}

void ePlayerEvent(Event hEvent, const char[] sMame, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(__IsValidClient(iClient) && !IsFakeClient(iClient))
	{
		bThirdPersonFix[iClient] = true;
	}
}

public void OnClientPutInServer(int iClient)
{
	if(iClient > 0)
	{
		if(!IsFakeClient(iClient))
		{
			TP_PushForwardToPlugins(iClient, true, false);
		}
		bThirdPersonFix[iClient] = true;
	}
}

public void OnClientDisconnect(int iClient)
{
	if(iClient > 0)
	{
		bThirdPersonFix[iClient] = false;
		bThirdPerson[iClient] = false;
	}
}

static bool __IsValidClient(int iClient)
{
	return iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient);
}
