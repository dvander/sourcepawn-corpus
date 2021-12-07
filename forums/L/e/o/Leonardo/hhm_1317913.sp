#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <colors>

#define PLUGIN_VERSION "1.2.0"
//#define DEBUG

new Handle:g_Enable;
new Handle:g_Duration;
new Handle:g_Togglemsg;
new Handle:g_MinHits;
new g_CurrentHits[MAXPLAYERS+1][MAXPLAYERS+1];
new Float:g_HitsDelay[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Humiliating Holy Mackerel",
	author = "Leonardo",
	description = "Respawn humiliated players",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("hhm_version", PLUGIN_VERSION, "Humiliating Holy Mackerel version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Enable = CreateConVar("hhm_enable", "1", "Enable/disable plugin");
	g_Duration = CreateConVar("hhm_duration", "5.0", "Time before player will be respawned");
	g_Togglemsg = CreateConVar("hhm_togglemsg", "1", "Turn on/off messages about humiliation");
	g_MinHits = CreateConVar("hhm_minhits", "5", "Minimal hits for enable timer", 0, true, 1.0);
	
	HookEvent("fish_notice", Event_FishNotice);
	HookEvent("player_death", Event_PlayerDeath);
	
	for(new iVictim = 1; iVictim <= MaxClients; iVictim++)
		for(new iAttacker = 1; iAttacker <= MaxClients; iAttacker++)
		{
			g_CurrentHits[iVictim][iAttacker] = 0;
			g_HitsDelay[iVictim][iAttacker] = 0.0;
		}
}

public OnGameFrame()
{
	for(new iVictim = 1; iVictim <= MaxClients; iVictim++)
		for(new iAttacker = 1; iAttacker <= MaxClients; iAttacker++)
			if( CheckElapsedTime(iVictim, iAttacker, 12.5) )
				g_CurrentHits[iVictim][iAttacker] = 0;
}

public OnMapStart()
{
	for(new iVictim = 1; iVictim <= MaxClients; iVictim++)
		for(new iAttacker = 1; iAttacker <= MaxClients; iAttacker++)
		{
			g_CurrentHits[iVictim][iAttacker] = 0;
			g_HitsDelay[iVictim][iAttacker] = 0.0;
		}
}

public Action:Event_FishNotice(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	if(!GetConVarBool(g_Enable)) return Plugin_Continue;
	
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iVictim) || !IsValidClient(iAttacker)) return Plugin_Continue;
	
	if(GetClientTeam(iVictim)<=1) return Plugin_Continue;
	
	if(GetEventBool(hEvent,"silent_kill")) return Plugin_Continue; // lolwut?
	
	if(GetEventInt(hEvent,"customkill") == TF_CUSTOM_FISH_KILL) return Plugin_Continue;
	
	g_CurrentHits[iVictim][iAttacker]++;
	if( g_CurrentHits[iVictim][iAttacker] >= GetConVarInt(g_MinHits) )
	{
		decl Handle:hData;
		CreateDataTimer(GetConVarFloat(g_Duration), KickingFromFight, hData);
		WritePackCell(hData, iVictim);
		WritePackCell(hData, iAttacker);
	}
	
	if( CheckElapsedTime(iVictim, iAttacker, 12.5) )
		SaveKeyTime(iVictim, iAttacker);
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iVictim) || !IsValidClient(iAttacker)) return Plugin_Continue;
	
	if( GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER ) return Plugin_Continue;
	
	if( GetEventInt(hEvent, "customkill") == TF_CUSTOM_FISH_KILL ) return Plugin_Continue;
	
	g_CurrentHits[iVictim][iAttacker] = 0;
	
	return Plugin_Continue;
}

public Action:KickingFromFight(Handle:hTimer, Handle:hData)
{
	ResetPack(hData);
	new iVictim = ReadPackCell(hData);
	new iAttacker = ReadPackCell(hData);
	if( IsValidClient(iVictim) && IsValidClient(iAttacker) )
	{
		g_CurrentHits[iVictim][iAttacker] = 0;
		if(IsPlayerAlive(iVictim))
		{
			new iCondFlags = TF2_GetPlayerConditionFlags(iVictim);
			if(!(iCondFlags & TF_CONDFLAG_UBERCHARGED) && !(iCondFlags & TF_CONDFLAG_BONKED) && !(iCondFlags & TF_CONDFLAG_DEADRINGERED))
			{
				if(GetConVarBool(g_Togglemsg))
					CPrintToChatAllEx(iVictim, "\x01* \x03%N\x01 humiliated by Holy Mackerel", iVictim);
#if !defined DEBUG
				TF2_RespawnPlayer(iVictim);
#endif
			}
		}
	}
}

stock bool:IsValidClient(any:iClient, bool:idOnly=false)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	if (!idOnly) return IsClientInGame(iClient);
	return true;
}

stock SaveKeyTime(any:iClient1, any:iClient2)
	if( IsValidClient(iClient1, true) && IsValidClient(iClient2, true) )
		g_HitsDelay[iClient1][iClient2] = GetGameTime();

stock bool:CheckElapsedTime(any:iClient1, any:iClient2, Float:fTime)
{
	if( IsValidClient(iClient1, true) && IsValidClient(iClient2, true) )
		if( (GetGameTime() - g_HitsDelay[iClient1][iClient2]) >= fTime )
			return true;
	return false;
}