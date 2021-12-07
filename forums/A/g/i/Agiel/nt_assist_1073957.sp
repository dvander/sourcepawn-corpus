/**************************************************************
--------------------------------------------------------------
 NEOTOKYO° Assist

 Plugin licensed under the GPLv3
 
 Coded by Agiel.
--------------------------------------------------------------

Changelog

	1.0.0
		* Initial release
	1.0.1
		* Added log message for HLX:CE support etc.
		
**************************************************************/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION	"1.0.1"

public Plugin:myinfo =
{
    name = "NEOTOKYO° Assist",
    author = "Agiel",
    description = "Adds kill assist points to NEOTOKYO°",
    version = PLUGIN_VERSION,
    url = ""
};

new Handle:convar_nt_assist_enabled = INVALID_HANDLE;
new Handle:convar_nt_assist_version = INVALID_HANDLE;
new Handle:convar_nt_assist_damage = INVALID_HANDLE;
new Handle:convar_nt_assist_half = INVALID_HANDLE;
new Handle:convar_nt_assist_notifications = INVALID_HANDLE;
new g_damageDone[MAXPLAYERS+1][MAXPLAYERS+1];
new g_playerHealth[MAXPLAYERS+1];
new bool:g_assistGiven[MAXPLAYERS+1];

public OnPluginStart()
{
	convar_nt_assist_enabled = CreateConVar("sm_nt_assist_enabled", "1", "Enables or Disables assist points.", 0, true, 0.0, true, 1.0);
	convar_nt_assist_damage = CreateConVar("sm_nt_assist_damage", "50", "How much damage needed to grant an assist point.", 0, true, 1.0, true, 99.0);
	convar_nt_assist_half = CreateConVar("sm_nt_assist_half", "0", "Whether an assist should be worth a half point or a full point.", 0, true, 0.0, true, 1.0);
	convar_nt_assist_notifications = CreateConVar("sm_nt_assist_notifications", "1", "Whether the clients should be notified by a chat message when they receive assist points.", 0, true, 0.0, true, 1.0);
	convar_nt_assist_version = CreateConVar("sm_nt_assist_version", PLUGIN_VERSION, "NEOTOKYO° Assist.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true);
	SetConVarString(convar_nt_assist_version, PLUGIN_VERSION, true, true);
	
	HookEvent("game_round_start", Event_Round_Start);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_hurt", Event_Player_Hurt);
	
	HookConVarChange(convar_nt_assist_half, Event_Half_Change);
}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new maxClients = GetMaxClients();
	for(new i = 0; i <= maxClients; i++)
	{
		g_playerHealth[i] = 100;
		for(new j = 0; j <= maxClients; j++)
			g_damageDone[i][j] = 0;
	}		
}

public Event_Half_Change(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) == 0)
	{
		for (new i = 0; i <= MAXPLAYERS; i++)
			g_assistGiven[i] = false;
	}
}

public Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(convar_nt_assist_enabled))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new health = GetEventInt(event, "health");
		// Calculate damage done.
		new damage = g_playerHealth[victim] - health;
		// Update health array.
		g_playerHealth[victim] = health;
		
		//PrintToServer("Damage: %d. Health: %d", damage, health);
		
		if (IsValidClient(attacker))
		{
			// Update total damage.
			g_damageDone[attacker][victim] += damage;
			//PrintToServer("Total damage by %N to %N: %d.", attacker, victim, g_damageDone[attacker][victim]);
		}
	}
}

public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(convar_nt_assist_enabled))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		// Find the player who made the most damage.
		new assist = 0;
		new maxDamage = GetConVarInt(convar_nt_assist_damage);
		
		new maxClients = GetMaxClients();
		for (new i = 0; i <= maxClients; i++)
		{
			// Don't care about players on the same team or the killer.
			if (IsValidClient(i) && (i != attacker) && (GetClientTeam(i) != GetClientTeam(victim)) && (g_damageDone[i][victim] > maxDamage))
			{
				maxDamage = g_damageDone[i][victim];
				assist = i;
			}
		}
		
		//PrintToServer("[nt-assist-debug] Assist given to %N.", assist);
		
		if (IsValidClient(assist))
		{
			//PrintToServer("[nt-assist] Assist point given to %N for dealing %d damage to %N.", assist, g_damageDone[assist][victim], victim);
			
			// Log stuff for HLX:CE etc.
			new assistUserId = GetClientUserId(assist);
			new String:assistSteamId[64];
			GetClientAuthString(assist, assistSteamId, 64);
			new String:assistTeam[18];
			GetTeamName(GetClientTeam(assist), assistTeam, sizeof(assistTeam));
			LogToGame("\"%N<%d><%s><%s>\" triggered \"kill_assist\"", assist, assistUserId, assistSteamId, assistTeam);
			
			// Only give half a point?
			if (GetConVarBool(convar_nt_assist_half))
			{
				if (GetConVarBool(convar_nt_assist_notifications))
					PrintToChat(assist, "[nt-assist] You gained half a point for dealing %d damage to %N.", g_damageDone[assist][victim], victim);
				// Keep track of half points by using a bool array.
				g_assistGiven[assist] = !g_assistGiven[assist];
			}
			else if (GetConVarBool(convar_nt_assist_notifications))
			{
				PrintToChat(assist, "[nt-assist] You gained one point for dealing %d damage to %N.", g_damageDone[assist][victim], victim);
			}
			
			// If nt_assist_half is 0 this will always return true.
			if (!g_assistGiven[assist])
			{
				new assist_xp = GetXP(assist);
				assist_xp++;
				SetXP(assist, assist_xp);
				SetRank(assist, assist_xp);
			}
		}
	}
}

stock SetXP(client, xp)
{
	SetEntProp(client, Prop_Data, "m_iFrags", xp);
	return 1;
}

stock SetRank(client, xp)
{
	new rank;
	if(xp <= -1)
		rank = 0;
	else if(xp >= 0 && xp <= 3)
		rank = 1;
	else if(xp >= 4 && xp <= 9)
		rank = 2;
	else if(xp >= 10 && xp <= 19)
		rank = 3;
	else if(xp >= 20)
		rank = 4;

	SetEntProp(client, Prop_Send, "m_iRank", rank);
	return 1;
}

stock GetXP(client)
{
	return GetClientFrags(client);
}

bool:IsValidClient(client){
	
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}