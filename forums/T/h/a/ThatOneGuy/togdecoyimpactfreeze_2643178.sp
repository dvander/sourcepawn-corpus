/*
	
*/

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0"
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or http://www.togcoding.com/showthread.php?p=1862459
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required

#define LoopValidPlayers(%1)		for(int %1 = 1; %1 <= MaxClients; %1++)	if(IsValidClient(%1))
#define FREEZE_NOT_SET -1

ConVar g_cFreezeDuration = null;
int ga_iFreezeValidation[MAXPLAYERS + 1] = {FREEZE_NOT_SET, ...};
int g_iRoundNum = 1;

public Plugin myinfo =
{
	name = "TOG Decoy Impact Freeze",
	author = "That One Guy",
	description = "Freezes victims that are hit directly with decoys.",
	version = PLUGIN_VERSION,
	url = "http://www.togcoding.com"
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togdecoyimpactfreeze");
	AutoExecConfig_CreateConVar("tdif_version", PLUGIN_VERSION, "TOG Decoy Impact Freeze: Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cFreezeDuration = AutoExecConfig_CreateConVar("tdif_duration", "5.0", "Time to freeze victim for (0 = disabled).", _, true, 0.0);
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsValidClient(i, true))
		{
			SDKHook(i, SDKHook_OnTakeDamage, Event_OnTakeDamage);
		}
	}
}

public Action Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	g_iRoundNum++;
	LoopValidPlayers(i)
	{
		ga_iFreezeValidation[i] = FREEZE_NOT_SET;
		SetEntityMoveType(i, MOVETYPE_WALK);
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client) 
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	ga_iFreezeValidation[client] = FREEZE_NOT_SET;
}

public void OnClientDisconnect(int client)
{
	ga_iFreezeValidation[client] = FREEZE_NOT_SET;
}

public Action Event_OnTakeDamage(int victim, int &attacker, int &inflictor, float &fDamage, int &iDamageType, int &iWeapon, float a_fDmgForce[3], float a_fDmgPosition[3])
{
	if(IsValidClient(attacker, true) && IsValidClient(victim, true))
	{
		char sWeaponName[32];
		GetEdictClassname(inflictor, sWeaponName, sizeof(sWeaponName));
		if(StrEqual(sWeaponName, "weapon_decoy", false) || StrEqual(sWeaponName, "decoy_projectile", false))
		{
			if(g_cFreezeDuration.FloatValue)
			{
				PrintToChatAll("%N has frozen %N with a decoy for %i seconds!", attacker, victim, g_cFreezeDuration.IntValue);
				FreezePlayer(victim);
			}
		}
	}
	return Plugin_Continue;
}

void FreezePlayer(int client)
{
	SetEntityMoveType(client, MOVETYPE_NONE);
	ga_iFreezeValidation[client] = g_iRoundNum;
	CreateTimer(g_cFreezeDuration.FloatValue, TimerCB_Unfreeze, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerCB_Unfreeze(Handle hTimer, any iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if(IsValidClient(client, true))
	{
		if(ga_iFreezeValidation[client] == g_iRoundNum)		//prevent unfreeze from triggering in next rnd if rnd ends fast
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			ga_iFreezeValidation[client] = FREEZE_NOT_SET;
			PrintToChat(client, "You can now move again!");
		}
	}
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || (!IsPlayerAlive(client) && !bAllowDead))
	{
		return false;
	}
	return true;
}

stock void Log(char[] sPath, const char[] sMsg, any ...)	//TOG logging function - path is relative to logs folder.
{
	char sLogFilePath[PLATFORM_MAX_PATH], sFormattedMsg[1500];
	BuildPath(Path_SM, sLogFilePath, sizeof(sLogFilePath), "logs/%s", sPath);
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 3);
	LogToFileEx(sLogFilePath, "%s", sFormattedMsg);
}

/*
CHANGELOG:
	1.0.0
		*	Initial creation.
*/