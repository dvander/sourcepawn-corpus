#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

int 
	g_iChargeVictim[MAXPLAYERS+1] = {-1, ...},
	g_iChargeAttacker[MAXPLAYERS+1] = {-1, ...};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	HookEvent("charger_killed", Event_ChargerKilled);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		g_iChargeVictim[i] = -1;
		g_iChargeAttacker[i] = -1;
		
		if (IsClientInGame(i))
		{
			// ~ CDirector::RestartScenario()
			// ~ CDirector::Restart()
			// ~ ForEachTerrorPlayer<RestartCleanup>()
			// ~ CTerrorPlayer::CleanupPlayerState()
			// ~ CTerrorPlayer::OnCarryEnded( (bClearBoth = true), (bSkipPummel = false), (bIsAttacker = true) )
			// ~ CTerrorPlayer::QueuePummelVictim( m_carryVictim.Get(), -1.0 )
			// CTerrorPlayer::UpdatePound()
			SetEntPropEnt(i, Prop_Send, "m_pummelVictim", -1);
			SetEntPropEnt(i, Prop_Send, "m_pummelAttacker", -1);
			
			// perhaps unnecessary
			L4D2_SetQueuedPummelStartTime(i, -1.0);
			L4D2_SetQueuedPummelVictim(i, -1);
			L4D2_SetQueuedPummelAttacker(i, -1);
		}
	}
}

// Clear arrays if the victim dies to slams
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	int attacker = g_iChargeAttacker[client];
	if (attacker == -1)
		return;
	
	g_iChargeVictim[attacker] = -1;
	g_iChargeAttacker[client] = -1;
}

// Calls if charger has started pummelling.
void Event_ChargerPummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client)
		return;
	
	int victimId = event.GetInt("victim");
	int victim = GetClientOfUserId(victimId);
	if (!victim || !IsClientInGame(victim))
		return;
	
	// Normal processes don't need special care
	g_iChargeVictim[client] = -1;
	g_iChargeAttacker[victim] = -1;
}

// Calls if charger has slammed and before pummel, or simply is cleared before slam. 
void Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	int victim = g_iChargeVictim[client];
	if (victim == -1)
		return;
	
	g_iChargeVictim[client] = -1;
	g_iChargeAttacker[victim] = -1;
}

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(GetClientOfUserId(event.GetInt("bot")), GetClientOfUserId(event.GetInt("player")));
}

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(GetClientOfUserId(event.GetInt("player")), GetClientOfUserId(event.GetInt("bot")));
}

void HandlePlayerReplace(int replacer, int replacee)
{
	if (!replacer || !IsClientInGame(replacer))
		return;
	
	if (!replacee)
		replacee = -1;
	
	if (GetClientTeam(replacer) == 3)
	{
		if (g_iChargeVictim[replacee] != -1)
		{
			g_iChargeVictim[replacer] = g_iChargeVictim[replacee];
			g_iChargeAttacker[g_iChargeVictim[replacee]] = replacer;
			g_iChargeVictim[replacee] = -1;

			if (L4D2_IsInQueuedPummel(replacee))
			{
				float flQueuedPummelTime = L4D2_GetQueuedPummelStartTime(replacee);
				L4D2_SetQueuedPummelStartTime(replacer, flQueuedPummelTime);
				L4D2_SetQueuedPummelAttacker(g_iChargeVictim[replacer], replacer);
				L4D2_SetQueuedPummelVictim(replacer, g_iChargeVictim[replacer]);

				L4D2_SetQueuedPummelStartTime(replacee, -1.0);
				L4D2_SetQueuedPummelVictim(replacee, -1);
			}
		}
	}
	else
	{
		if (g_iChargeAttacker[replacee] != -1)
		{
			g_iChargeAttacker[replacer] = g_iChargeAttacker[replacee];
			g_iChargeVictim[g_iChargeAttacker[replacee]] = replacer;
			g_iChargeAttacker[replacee] = -1;
		}
	}
}

public void L4D2_OnStartCarryingVictim_Post(int victim, int attacker)
{
	if (!victim || !IsClientInGame(victim))
		return;
	
	if (!IsPlayerAlive(victim))
		return;
	
	g_iChargeVictim[attacker] = victim;
	g_iChargeAttacker[victim] = attacker;
}

public void L4D2_OnSlammedSurvivor_Post(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	if (!victim || !IsClientInGame(victim))
		return;
	
	if (!IsPlayerAlive(victim))
		return;
	
	g_iChargeVictim[attacker] = victim;
	g_iChargeAttacker[victim] = attacker;
	
	if (!IsPlayerAlive(attacker)) // compatibility with competitive 1v1
	{
		Event event = CreateEvent("charger_killed");
		event.SetInt("userid", GetClientUserId(attacker));
		
		Event_ChargerKilled(event, "charger_killed", false);
		
		event.Cancel();
	}
}