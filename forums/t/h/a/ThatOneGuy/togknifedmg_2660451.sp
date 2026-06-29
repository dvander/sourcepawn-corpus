/*

*/

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.1"
#define LoopValidPlayers(%1)						for(int %1 = 1; %1 <= MaxClients; %1++)		if(IsValidClient(%1))
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required

ConVar g_cRegDmgLeft = null;
ConVar g_cRegDmgRight = null;
ConVar g_cBackDmgLeft = null;
ConVar g_cBackDmgRight = null;
ConVar g_cTakeKnifeDmgCooldown = null;
ConVar g_cGiveKnifeDmgCooldown = null;

int ga_iGiveDmgEvntTime[MAXPLAYERS + 1] = {0, ...};
int ga_iTakeDmgEvntTime[MAXPLAYERS + 1] = {0, ...};

bool g_bLateLoad = false;

public Plugin myinfo =
{
	name = "TOG Knife Damage",
	author = "That One Guy",
	description = "Allows controlling how much knife damage is done and allows for cooldowns before a second knife.",
	version = PLUGIN_VERSION,
	url = "https://www.togcoding.com/togcoding/index.php"
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max)
{
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togknifedmg");
	AutoExecConfig_CreateConVar("togknifedmg_version", PLUGIN_VERSION, "TOG Knife Damage - version number.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cRegDmgLeft = AutoExecConfig_CreateConVar("togknifedmg_reg_left", "-1", "-1 = no change, else this value overrides the damage done by a regular left-click knife hit.", FCVAR_NONE, true, -1.0);
	
	g_cRegDmgRight = AutoExecConfig_CreateConVar("togknifedmg_reg_right", "-1", "-1 = no change, else this value overrides the damage done by a regular right-click knife hit.", FCVAR_NONE, true, -1.0);
	
	g_cBackDmgLeft = AutoExecConfig_CreateConVar("togknifedmg_back_left", "-1", "-1 = no change, else this value overrides the damage done by a left-click back stab.", FCVAR_NONE, true, -1.0);
	
	g_cBackDmgRight = AutoExecConfig_CreateConVar("togknifedmg_back_right", "-1", "-1 = no change, else this value overrides the damage done by a right-click back stab.", FCVAR_NONE, true, -1.0);
	
	g_cTakeKnifeDmgCooldown = AutoExecConfig_CreateConVar("togknifedmg_cooldown_take", "0", "0 = no cooldown, else this is the number of seconds after taking knife damage that knife damage is blocked for.", FCVAR_NONE, true, 0.0);
	
	g_cGiveKnifeDmgCooldown = AutoExecConfig_CreateConVar("togknifedmg_cooldown_give", "0", "0 = no cooldown, else this is the number of seconds after giving knife damage before you can knife again.", FCVAR_NONE, true, 0.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnConfigsExecuted()
{
	if(g_bLateLoad)
	{
		LoopValidPlayers(i)
		{
			OnClientPutInServer(i);
		}
	}
}

void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	ga_iGiveDmgEvntTime[client] = 0;
	ga_iTakeDmgEvntTime[client] = 0;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	ga_iGiveDmgEvntTime[client] = 0;
	ga_iTakeDmgEvntTime[client] = 0;
}

public Action Event_OnTakeDamage(int victim, int &attacker, int &inflictor, float &fDamage, int &damagetype, int &weapon, float a_fDmgForce[3], float a_fDmgPosition[3])
{
	char sClassname[64];
	GetEdictClassname(inflictor, sClassname, sizeof(sClassname));
	if(StrContains(sClassname, "knife") == -1)
	{
		return Plugin_Continue;
	}
	
	if(!IsValidClient(victim) || !IsValidClient(attacker))
	{
		return Plugin_Continue;
	}
	
	if(ga_iTakeDmgEvntTime[victim])
	{
		PrintToChat(attacker, "%N is on a cooldown from knife damage and cannot be knifed for %i more seconds.", victim, GetTime() - ga_iTakeDmgEvntTime[victim]);
		fDamage = 0.0;
		return Plugin_Changed;
	}
	
	if(ga_iGiveDmgEvntTime[attacker])
	{
		PrintToChat(attacker, "You are on a cooldown from giving knife damage for %i more seconds.", GetTime() - ga_iGiveDmgEvntTime[attacker]);
		fDamage = 0.0;
		return Plugin_Changed;
	}
	
	bool bDmgChanged = false;
	int iButtons = GetClientButtons(attacker);
	if(iButtons & IN_ATTACK2)		//if right click
	{
		if(fDamage <= 65)	//front attack [https://counterstrike.fandom.com/wiki/Knife]
		{
			if(g_cRegDmgRight.IntValue >= 0)
			{
				fDamage = g_cRegDmgRight.FloatValue;
				bDmgChanged = true;
			}
		}
		else	//back attack
		{
			if(g_cBackDmgRight.IntValue >= 0)
			{
				fDamage = g_cBackDmgRight.FloatValue;
				bDmgChanged = true;
			}
		}
	}
	else	//left click
	{
		if(fDamage <= 40)	//front attack
		{
			if(g_cRegDmgLeft.IntValue >= 0)
			{
				fDamage = g_cRegDmgLeft.FloatValue;
				bDmgChanged = true;
			}
		}
		else	//back attack
		{
			if(g_cBackDmgLeft.IntValue >= 0)
			{
				fDamage = g_cBackDmgLeft.FloatValue;
				bDmgChanged = true;
			}
		}
	}
	
	if(g_cGiveKnifeDmgCooldown.FloatValue)
	{
		ga_iGiveDmgEvntTime[attacker] = GetTime();
		CreateTimer(g_cGiveKnifeDmgCooldown.FloatValue, TimerCB_GiveDmg, GetClientUserId(attacker));
	}
	
	if(g_cTakeKnifeDmgCooldown.FloatValue)
	{
		ga_iTakeDmgEvntTime[victim] = GetTime();
		CreateTimer(g_cTakeKnifeDmgCooldown.FloatValue, TimerCB_TakeDmg, GetClientUserId(attacker));
	}
	
	if(bDmgChanged)
	{
		return Plugin_Changed;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action TimerCB_GiveDmg(Handle hTimer, any iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if(IsValidClient(client))
	{
		ga_iGiveDmgEvntTime[client] = 0;
	}
	return Plugin_Continue;
}

public Action TimerCB_TakeDmg(Handle hTimer, any iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if(!IsValidClient(client))
	{
		ga_iTakeDmgEvntTime[client] = 0;
	}
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	return true;
}

stock void Log(char[] sPath, const char[] sMsg, any ...)		//TOG logging function - path is relative to logs folder.
{
	char sLogFilePath[PLATFORM_MAX_PATH], sFormattedMsg[1500];
	BuildPath(Path_SM, sLogFilePath, sizeof(sLogFilePath), "logs/%s", sPath);
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 3);
	LogToFileEx(sLogFilePath, "%s", sFormattedMsg);
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*
	1.0.0
		* Initial creation.
	1.0.1
		* Edit so that "no change" is -1 for the dmg CVars. Previously, it was 0 for no change, but 0 should be allowed to null out dmg. Minor edit to CVar names to ensure new cache of CVars.
		* Changed OnTakeDmg event from checking if weapon class equals weapon_knife to just checking if it contains "knife". Likely has no effect, but edited in case it didnt include "weapon_" in the classname (I forget which function does that).
*/