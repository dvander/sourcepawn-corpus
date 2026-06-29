#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "v1.01"

public Plugin myinfo =
{
	name = "Random Über",
	author = "JugadorXEI",
	description = "Gives player a random über (or another condition) instead of/alongside their random crit.",
	version = PLUGIN_VERSION,
	url =  "https://github.com/JugadorXEI",
}

ConVar g_PluginEnable; // Convar that enables the plugin.
ConVar g_ConditionSelection; // Convar that determines the condition used.
ConVar g_ConditionDuration; // Convar that determines the duration of the condition.
ConVar g_ConditionAllowCrit; // Convar that allows if the crit should go through or not.
ConVar g_ConditionAllowCritDuringCond; // Convar that allows if the player should get crits during their condition.

public void OnPluginStart()
{
	// The commands!
	g_PluginEnable = CreateConVar("sm_randomuber_enable", "1", "Enables or disables the plugin. 1 = enables, 0 = disables.");
	g_ConditionSelection = CreateConVar("sm_randomuber_condition", "5", "The condition that is applied to the player who gets a random crit. 5 is the übercharge condition, you can see the rest here: https://wiki.teamfortress.com/wiki/Cheats#addcond");
	g_ConditionDuration = CreateConVar("sm_randomuber_duration", "3.0", "The duration of which the condition will be on the player until it expires. Some conditions may crash the game or actually last indefinitely regardless of duration, so be careful!");
	g_ConditionAllowCrit = CreateConVar("sm_randomuber_allowcrit", "0", "Should a crit happen alongside the condition added or not? 1 = yes, 0 = no.");
	g_ConditionAllowCritDuringCond = CreateConVar("sm_randomuber_allowcritduringcond", "0", "Should a crit happen if the player is already under the effects of the condition? 1 = yes, 0 = no.");
	
	// We tell the server owner about it.
	PrintToServer("Random Über (version %s) is enabled!", PLUGIN_VERSION);
}

public Action TF2_CalcIsAttackCritical(int iClient, int iWeapon, char[] cWeaponname, bool &bResult)
{	
	// If the plugin is enabled.
	if (g_PluginEnable.BoolValue)
	{
		// Is the client valid, alive, and got a crit?
		if (IsValidClient(iClient) && IsPlayerAlive(iClient) && bResult == true)
		{	
			// Is the client under forced crits?
			if (TF2_IsPlayerCritBuffed(iClient)) return Plugin_Continue;
			
			// Is the client, as a demoman, getting crits through charge?
			if (TF2_GetPlayerClass(iClient) == TFClass_DemoMan &&
			GetEntPropFloat(iClient, Prop_Send, "m_flChargeMeter") <= 5.0 &&
			iWeapon == GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee)) return Plugin_Continue;
			
			// Is the client getting crits through the Gunslinger?
			if (StrContains(cWeaponname, "robot_arm", false) != -1) return Plugin_Continue;
			
			// Is the client getting backstabs (which are also crits)?
			if (StrContains(cWeaponname, "knife", false) != -1) return Plugin_Continue;
			
			// If the player is not under the condition specified by the plugin.
			if (!TF2_IsPlayerInCondition(iClient, view_as<TFCond>(g_ConditionSelection.IntValue)))
			{
				// ...then we give them said condition and such duration.
				TF2_AddCondition(iClient, view_as<TFCond>(g_ConditionSelection.IntValue),
				g_ConditionDuration.FloatValue);
			}
			// We'll allow the crit to happen during the condition if the server owner wants.
			else if (TF2_IsPlayerInCondition(iClient,
			view_as<TFCond>(g_ConditionSelection.IntValue)) && bResult == true)
			{
				bResult = g_ConditionAllowCritDuringCond.BoolValue;
				return Plugin_Changed;
			}
			
			// Do we want the crit to happen alongside the condition?
			bResult = g_ConditionAllowCrit.BoolValue;
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

// By FlaminSarge, from: https://forums.alliedmods.net/showthread.php?p=1672809
stock bool TF2_IsPlayerCritBuffed(int iClient)
{
	return (TF2_IsPlayerInCondition(iClient, TFCond_Kritzkrieged)
			|| TF2_IsPlayerInCondition(iClient, TFCond_HalloweenCritCandy)
			|| TF2_IsPlayerInCondition(iClient, TFCond_CritCanteen)
			|| TF2_IsPlayerInCondition(iClient, TFCond_CritDemoCharge)
			|| TF2_IsPlayerInCondition(iClient, TFCond_CritOnFirstBlood)
			|| TF2_IsPlayerInCondition(iClient, TFCond_CritOnWin)
			|| TF2_IsPlayerInCondition(iClient, TFCond_CritOnFlagCapture)
			|| TF2_IsPlayerInCondition(iClient, TFCond_CritOnKill)
			|| TF2_IsPlayerInCondition(iClient, TFCond_CritMmmph));
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}