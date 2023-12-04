#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
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
/*
public void OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
	    if (IsClientInGame(i))
	    {
	       SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
	    }
	} 
}

public void OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public Action Stealth_SetTransmit(int client, int other)
{
	if(client == other) // If client for which you try to settransmit is you then be visible to yourself
		return Plugin_Continue; // Due to return Plugin_Continue plugin stops here and keeps you visible
	if (!IsPlayerAlive(client) || !IsPlayerAlive(other))
	{
		PrintToConsoleAll("%i v %i", client,other);
		return Plugin_Continue;
	}
	bool isBotZombie = ZR_IsClientZombie(client);
	bool isTargetZombie = ZR_IsClientZombie(other);
	if (isBotZombie!=isTargetZombie)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Hook_SetTransmit(int entity, int client) {
    if (IsFakeClient(client) && HasEntProp(entity, Prop_Data, "m_iTeamNum") && entity != client) {


        return (ZM_TEAMS(client) == ZM_TEAMS(entity)) ? Plugin_Handled : Plugin_Continue;

    }

    return Plugin_Continue;

}


int ZM_TEAMS(int client) {

    return ZR_IsClientZombie(client) ? 1 : 0;

}*/

public Action OnShouldBotAttackPlayer(int bot, int player, bool &result)
{
	if (!IsPlayerAlive(player) || !IsPlayerAlive(bot))
	{
		return Plugin_Continue;
	}
	bool isBotZombie = ZR_IsClientZombie(bot);
	bool isTargetZombie = ZR_IsClientZombie(player);
	if (isBotZombie != isTargetZombie)
	{
		if (!result)
		{
			result = true;
		}
		return Plugin_Changed;
	}
	/*int teamNum = GetEntProp(bot, Prop_Send, "m_iTeamNum", CS_TEAM_T);
	int teamNum2 = GetEntProp(player, Prop_Send, "m_iTeamNum", CS_TEAM_T);
	char player1Name[64];
	GetClientName(bot, player1Name, 64);
	char player2Name[64];
	GetClientName(player, player2Name, 64);
	PrintToConsoleAll("%s (%i) wants to attack %s (%i)", player1Name, teamNum,player2Name,teamNum2);*/
	result = false;
	return Plugin_Changed;
}

/*
public Action OnShouldBotAttackPlayer(int bot, int player, bool & result) {

    char mdl_A[PLATFORM_MAX_PATH], mdl_B[PLATFORM_MAX_PATH];

    GetClientModel(bot, mdl_A, sizeof mdl_A);
    GetClientModel(player, mdl_B, sizeof mdl_B);

    result = (strcmp(mdl_A, mdl_B) == 0) ? false:true;

    return Plugin_Changed;
}*/