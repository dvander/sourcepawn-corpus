#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define TAG " \x04[Freerun] \x01"

bool gB_Freerun = false;
bool gB_Expiration = false;

ConVar gCV_Enabled = null;
ConVar gCV_Time = null;
ConVar gCV_Heal = null;

int gI_Round = -1;

public Plugin myinfo =
{
	name = "[CS:GO] Freerun",
	author = "LenHard",
	description = "Deaths could activiate this command, to let the runners finish and knife to the death.",
	version = "1.1",
	url = "http://steamcommunity.com/id/TheOfficalLenHard/"
};


/*===============================================================================================================================*/
/********************************************************* [ONLOADS] *************************************************************/
/*===============================================================================================================================*/


public void OnPluginStart()
{  
	gCV_Enabled = CreateConVar("lh_freerun", "1", "Enable the plugin? (Yes = 1 | No = 0)", FCVAR_NOTIFY);
	gCV_Time = CreateConVar("lh_freerun_expire", "20.0", "Time in seconds till the Freerun time usage expires (From the start of the round).", FCVAR_NOTIFY);
	gCV_Heal = CreateConVar("lh_freerun_heal", "25", "Amount of health the death recieves for a kill in freerun. (0 = Disable)", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "lh_freerun");

	RegConsoleCmd("sm_freerun", Cmd_Freerun, "Triggers Freerun.");
	RegConsoleCmd("sm_free", Cmd_Freerun, "Triggers Freerun.");
	RegConsoleCmd("sm_fr", Cmd_Freerun, "Triggers Freerun.");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void OnMapStart()
{
	gI_Round = -1;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponDecideUse);	
}


/*===============================================================================================================================*/
/********************************************************* [SDKHOOKS] ************************************************************/
/*===============================================================================================================================*/


public Action OnPlayerRunCmd(int client, int &buttons)
{		
	if (gCV_Enabled.BoolValue && gB_Freerun && IsValidClient(client, false, false) && GetClientTeam(client) == 2 && buttons & IN_USE)
	{
		PrintCenterText(client, "You can't use traps on a <font color='#FF0000'>freerun</font>!");
		buttons &= ~IN_USE;
	}
}

public Action OnWeaponDecideUse(int client, int iWeapon)
{
	if (gCV_Enabled.BoolValue && gB_Freerun && IsValidClient(client, false, false) && IsValidEdict(iWeapon))
	{
		char[] sWeapon = new char[MAX_NAME_LENGTH];
		GetEdictClassname(iWeapon, sWeapon, MAX_NAME_LENGTH);
		
		if (!(StrEqual(sWeapon, "weapon_knife", false)))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}


/*===============================================================================================================================*/
/********************************************************* [EVENTS] **************************************************************/
/*===============================================================================================================================*/


public Action Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{	
	if (gCV_Enabled.BoolValue)
	{	
		gI_Round++;
		
		gB_Expiration = false;
		gB_Freerun = false;
		
		CreateTimer(gCV_Time.FloatValue, Timer_Freerun, gI_Round, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{	
	if (gCV_Enabled.BoolValue)
	{
		int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
		int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
			
		if (gB_Freerun && IsValidClient(iVictim) && IsValidClient(iAttacker))
		{
			if (GetClientTeam(iAttacker) == 2 && GetClientTeam(iVictim) == 3)
			{
				SetEntProp(iAttacker, Prop_Send, "m_iHealth", GetClientHealth(iAttacker) + gCV_Heal.IntValue);
			}
		}
	}
}


/*===============================================================================================================================*/
/********************************************************* [COMMANDS] ************************************************************/
/*===============================================================================================================================*/


public Action Cmd_Freerun(int client, int args)
{
	if (IsValidClient(client))
	{	
		if (!gCV_Enabled.BoolValue)
		{
			PrintToChat(client, "%sThis command is disabled!", TAG);
			return Plugin_Handled;
		}
	
		if (!IsPlayerAlive(client))
		{
			PrintToChat(client, "%sYou must be alive to use this command!", TAG);
			return Plugin_Handled;
		}	
		
		if (GetClientTeam(client) != 2)
		{
			PrintToChat(client, "%sYou must be the \x07Death \x01to use this command!", TAG);
			return Plugin_Handled;
		}
		
		if (gB_Freerun)
		{
			PrintToChat(client, "%sFreerun is already in progress!", TAG);
			return Plugin_Handled;
		}
		
		if (gB_Expiration)
		{
			PrintToChat(client, "%sThe freerun usage time has expired!", TAG);
			return Plugin_Handled;
		}
		
		gB_Freerun = true;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i, false, false))
			{
				RemoveAllWeapons(i, "weapon_knife");
			}
		}
	
		for (int i = 0; i < 2; i++) PrintToChatAll("%s\x07%N \x01chose to make it a \x06Freerun\x01!", TAG, client);
	}
	return Plugin_Handled;
}


/*===============================================================================================================================*/
/********************************************************* [TIMERS] **************************************************************/
/*===============================================================================================================================*/


public Action Timer_Freerun(Handle hTimer, int iRound)
{
	if (iRound == gI_Round)
		gB_Expiration = true;
}


/*===============================================================================================================================*/
/********************************************************* [STOCKS] **************************************************************/
/*===============================================================================================================================*/


stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots)|| (!bAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}

stock void RemoveAllWeapons(int client, char[] sException = "")
{
	for (int i = 0; i <= 6; i++)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		
		if (IsValidEdict(iWeapon))
		{
			RemovePlayerItem(client, iWeapon);
			RemoveEdict(iWeapon);
		}
	}	
	
	if (StrContains(sException, "weapon_", false) != -1) GivePlayerItem(client, sException);
}