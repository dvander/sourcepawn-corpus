#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <botattackcontrol>
#include <zombiereloaded>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "Bots for ZM",
	author = "Nikooo777",
	description = "Bots that are not retarded",
	version = PLUGIN_VERSION,
	url = "https://forum.elite-hunterz.com/"
};

public Action OnShouldBotAttackPlayer(int bot, int player, bool &result)
{
	if (!IsPlayerAlive(player) || !IsPlayerAlive(bot))
	{
		return Plugin_Continue;
	}
	bool isBotZombie = ZR_IsClientZombie(bot);
	bool isTargetZombie = ZR_IsClientZombie(player);
	if (isBotZombie != isTargetZombie) {
		if (!result){
			result = true;
		}

		return Plugin_Changed;
	}

	int teamNum = GetEntProp(bot, Prop_Send, "m_iTeamNum", CS_TEAM_T);
	int teamNum2 = GetEntProp(player, Prop_Send, "m_iTeamNum", CS_TEAM_T);
	char player1Name[64];
	GetClientName(bot, player1Name, 64);
	char player2Name[64];
	GetClientName(player, player2Name, 64);
	PrintToConsoleAll("%s (%i) wants to attack %s (%i)", player1Name, teamNum,player2Name,teamNum2);
	result = false;
	return Plugin_Changed;
}