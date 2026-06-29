#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>

new bool:g_boss_is_afk;
new bool:g_boss_companion_is_afk;
new bool:g_afk_check_enabled;
new g_boss;
new g_boss_companion;
new Handle:g_cv_boss_afk_time = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Freak Fortress 2: AFK Boss Slayer",
	author = "frog",
	version = "1.0.2",
}

public OnPluginStart()
{
	g_cv_boss_afk_time = CreateConVar("sm_boss_afk_time", "15.0", "Amount of time (seconds) the Boss can be AFK for at the start of a round.", 0, true, 1.0, false, _);
	
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_afk_check_enabled = false;
	if (FF2_IsFF2Enabled())
	{
		new userid = FF2_GetBossUserId(0);
		new userid_companion = FF2_GetBossUserId(1);
		g_boss_is_afk = true;
		if (userid_companion == -1)
		{
			g_boss_companion_is_afk = false;
		}
		else
		{
			g_boss_companion_is_afk = true;
		}
		g_afk_check_enabled = true;
		g_boss = GetClientOfUserId(userid);
		g_boss_companion = GetClientOfUserId(userid_companion);
		CreateTimer(GetConVarFloat(g_cv_boss_afk_time), Timer_SlayAFK);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!g_afk_check_enabled)
	{
		return Plugin_Continue;
	}
	if (client == g_boss)
	{
		if (g_boss_is_afk && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)) {
			g_boss_is_afk = false;
		}
	} 
	else if (client == g_boss_companion)
	{
		if (g_boss_companion_is_afk && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT ||buttons & IN_MOVERIGHT)) {
			g_boss_companion_is_afk = false;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_SlayAFK(Handle:timer)
{
	if (g_boss_is_afk)
	{
		if (IsClientConnected(g_boss))
		{
			if (IsPlayerAlive(g_boss) && GetClientTeam(g_boss) == FF2_GetBossTeam())
			{
				ForcePlayerSuicide(g_boss);
				PrintToChatAll("[FF2] The Boss was slain for being AFK");
			}
		}
	}
	if (g_boss_companion_is_afk)
	{
		if (IsClientConnected(g_boss_companion))
		{
			if (IsPlayerAlive(g_boss_companion) && GetClientTeam(g_boss_companion) == FF2_GetBossTeam())
			{
				ForcePlayerSuicide(g_boss_companion);
				PrintToChatAll("[FF2] The Bosses companion was slain for being AFK");
			}
		}
	}
	g_afk_check_enabled = false;
}
