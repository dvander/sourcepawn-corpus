#include <colors>
#include <cstrike>
#include <sdktools_functions>

new	Handle:tb_interval,
	Handle:tb_immune,
	Handle:tb_limit,
	Handle:ThinkTimer

public Plugin:myinfo =
{
	name        = "[CS:S/CS:GO] Simply Team Balancer",
	author      = "Root",
	description = "Keep the teams balanced (with CSDM support)",
	version     = "1.0",
	url         = "http://dodsplugins.com/"
}

public OnPluginStart()
{
	tb_interval = CreateConVar("sm_teambalancer_interval",      "5", "Determines interval between checks\nSet to 0 to disable plugin", FCVAR_PLUGIN, true, 0.0)
	tb_immune   = CreateConVar("sm_teambalancer_immune_admins", "1", "Whether or not immune admins from being balanced",               FCVAR_PLUGIN, true, 0.0, true, 1.0)
	tb_limit    = CreateConVar("sm_teambalancer_limitteams",    "2", "How uneven the teams can get before getting balanced",           FCVAR_PLUGIN, true, 1.0, true, 32.0)

	HookConVarChange(tb_interval, OnConVarChange)
	AutoExecConfig(true, "team_balancer")
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (ThinkTimer)
	{
		CloseHandle(ThinkTimer)

		if (StringToFloat(newValue) > 0.0)
			ThinkTimer = CreateTimer(StringToFloat(newValue), Timer_TeamBalance, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT)
	}
}

public OnMapStart()
{
	if (GetConVarFloat(tb_interval) > 0.0)
		ThinkTimer = CreateTimer(GetConVarFloat(tb_interval), Timer_TeamBalance, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT)
}

public Action:Timer_TeamBalance(Handle:timer)
{
	new T_Count    = GetTeamClientCount(CS_TEAM_T)
	new CT_Count   = GetTeamClientCount(CS_TEAM_CT)
	new limitteams = GetConVarInt(tb_limit)

	new clients[MaxClients], client, numTers, numCTs, randomT, randomCT
	for (client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (GetConVarBool(tb_immune) && GetUserAdmin(client) != INVALID_ADMIN_ID) continue

			if (!IsPlayerAlive(client))
			{
				switch (GetClientTeam(client))
				{
					case CS_TEAM_T:
					{
						clients[numTers++] = client
						randomT = clients[Math_GetRandomInt(0, numTers - 1)]
					}
					case CS_TEAM_CT:
					{
						clients[numCTs++] = client
						randomCT = clients[Math_GetRandomInt(0, numCTs - 1)]
					}
				}
			}

			if ((T_Count > CT_Count) && ((T_Count - CT_Count) >= limitteams))
			{
				if (randomT)
				{
					CS_SwitchTeam(randomT, CS_TEAM_CT)
					CPrintToChat(randomT,  "{blue}[TB]{darkred} You've been switched to \nCounter-Terrorists {darkred}team for balance.")
					break
				}
			}
			else if ((CT_Count > T_Count) && ((CT_Count - T_Count) >= limitteams))
			{
				if (randomCT)
				{
					CS_SwitchTeam(randomCT, CS_TEAM_T)
					CPrintToChat(randomCT,  "{blue}[TB]{darkred} You've been switched to {orange}Terrorists {darkred}team for balance.")
					break
				}
			}
		}
	}
}

Math_GetRandomInt(min, max)
{
	return RoundToNearest(GetURandomFloat() * float(max - min) + float(min))
}