#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_NAME 	"Free For All"
#define PLUGIN_VERSION 	"1.0.4"

#define FFA_CONDITION(%1,%2) (1 <= %1 <= MaxClients && 1 <= %2 <= MaxClients && %1 != %2 && GetClientTeam(%1) == GetClientTeam(%2))

new Handle:g_hFreeForAll = INVALID_HANDLE;
new Handle:g_hFriendlyFire = INVALID_HANDLE;

new bool:g_bFreeForAll = false;
new g_iAccount = -1;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Get points for killing your teammates",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	if ((g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount")) == -1)
		SetFailState("Failed to find CCSPlayer::m_iAccount offset");
	
	CreateConVar("sm_freeforall_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hFreeForAll = CreateConVar("sm_freeforall", "1", "Toggle Free For All gameplay", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hFriendlyFire = FindConVar("mp_friendlyfire");
	
	OnFFAChange(g_hFreeForAll, "", "");
	HookConVarChange(g_hFreeForAll, OnFFAChange);
}

public OnConfigsExecuted()
{
	if (g_bFreeForAll)
		SetConVarBool(g_hFriendlyFire, true);
}

public OnClientPutInServer(client)
{
	if (g_bFreeForAll)
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	/* Make friendly fire damage the same as real damage. */ 
	if (FFA_CONDITION(victim, attacker) && inflictor == attacker)
	{
		damage /= 0.35;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action:Hook_TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	/* Block team-attack messages from being shown to players. */ 
	decl String:message[256];
	BfReadString(bf, message, sizeof(message));

	if (StrContains(message, "teammate_attack") != -1)
		return Plugin_Handled;

	if (StrContains(message, "Killed_Teammate") != -1)
		return Plugin_Handled;
		
	return Plugin_Continue;
}

public Action:Hook_HintText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	/* Block team-attack "tutorial" messages from being shown to players. */ 
	decl String:message[256];
	BfReadString(bf, message, sizeof(message));
	
	if (StrContains(message, "spotted_a_friend") != -1)
		return Plugin_Handled;

	if (StrContains(message, "careful_around_teammates") != -1)
		return Plugin_Handled;
	
	if (StrContains(message, "try_not_to_injure_teammates") != -1)
		return Plugin_Handled;
		
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Properly increase the player's score and cash if it was a teamkill. */
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (FFA_CONDITION(victim, attacker))
	{
		SetEntProp(attacker, Prop_Data, "m_iFrags", GetClientFrags(attacker) + 2);
		SetEntData(attacker, g_iAccount, GetEntData(attacker, g_iAccount) + 3600);
	}
	
	return Plugin_Continue;
}

public OnFFAChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:bNewValue = GetConVarBool(convar);
	
	if (bNewValue && !g_bFreeForAll)
		FFA_Enable();
	else if (!bNewValue && g_bFreeForAll)
		FFA_Disable();
}

FFA_Enable()
{
	g_bFreeForAll = true;
	
	SetConVarBool(g_hFriendlyFire, true);
	HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true);
	HookUserMessage(GetUserMessageId("HintText"), Hook_HintText, true);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

FFA_Disable()
{
	g_bFreeForAll = false;
	
	UnhookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true);
	UnhookUserMessage(GetUserMessageId("HintText"), Hook_HintText, true);
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}
