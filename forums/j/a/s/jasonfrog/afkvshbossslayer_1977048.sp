#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <saxtonhale>

new bool:g_hale_is_afk;
new bool:g_afk_check_enabled;
new g_hale_userid;
new Handle:g_cv_hale_afk_time = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "AFK VSH Boss Slayer",
	author = "frog",
	version = "1.0.2",
}

public OnPluginStart()
{
	g_cv_hale_afk_time = CreateConVar("sm_hale_afk_time", "15.0", "Amount of time (seconds) the Boss can be AFK for at the start of a round.", 0, true, 1.0, false, _);
	
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_afk_check_enabled = false;
	if (VSH_IsSaxtonHaleModeEnabled())
	{
		new userid = VSH_GetSaxtonHaleUserId();
		if (userid != -1)
		{
			g_hale_userid = GetClientOfUserId(userid);
			if (!IsFakeClient(g_hale_userid))
			{
				g_hale_is_afk = true;
				g_afk_check_enabled = true;
				CreateTimer(GetConVarFloat(g_cv_hale_afk_time), Timer_SlayAFK);
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!g_afk_check_enabled)
	{
		return Plugin_Continue;
	}
	if (client == g_hale_userid)
	{
		if (g_hale_is_afk && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT ||buttons & IN_MOVERIGHT))
		{
			g_hale_is_afk = false;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_SlayAFK(Handle:timer)
{
	if (g_hale_is_afk)
	{
		if (IsPlayerAlive(g_hale_userid) && IsClientConnected(g_hale_userid) && GetClientTeam(g_hale_userid) == VSH_GetSaxtonHaleTeam())
		{
			ForcePlayerSuicide(g_hale_userid);
			PrintToChatAll("The Boss was slain for being AFK after %d seconds.",RoundFloat(GetConVarFloat(g_cv_hale_afk_time)));
		}
	}
	g_afk_check_enabled = false;
}
