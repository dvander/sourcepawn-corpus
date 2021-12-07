#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar g_cvJumpBlockedTicks;

public void OnPluginStart()
{
	g_cvJumpBlockedTicks = CreateConVar("sm_jump_blocked_ticks", "1", "Ticks/frames after landing before you are able to jump.", _, true, 0.0);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3])
{
	Action iReturn = Plugin_Continue;
	static bool bOnGround[MAXPLAYERS + 1] = {true, ...};
	static bool bReleasedJump[MAXPLAYERS + 1] = {true, ...};
	static int iPassedTicks[MAXPLAYERS + 1] = {-1, ...};

	if(!IsPlayerAlive(client) || IsFakeClient(client))
		return iReturn;

	if(g_cvJumpBlockedTicks.IntValue > iPassedTicks[client] > -1)
	{
		iPassedTicks[client]++;

		if(buttons & IN_JUMP)
		{
			buttons &= ~IN_JUMP;
			iReturn = Plugin_Changed;
		}
	}
	else if(iPassedTicks[client] == g_cvJumpBlockedTicks.IntValue)
	{
		iPassedTicks[client] = -1;
		bReleasedJump[client] = false;
	}

	if(iPassedTicks[client] == -1 && !bReleasedJump[client])
	{

		if(!(buttons & IN_JUMP))
			bReleasedJump[client] = true;

		if(!bReleasedJump[client])
		{
			buttons &= ~IN_JUMP;
			iReturn = Plugin_Changed;
		}
	}

	bool bPreviouslyOnGround = bOnGround[client];

	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
		bOnGround[client] = false;
	else
		bOnGround[client] = true;

	if(bOnGround[client] && !bPreviouslyOnGround)
		iPassedTicks[client] = 0;

	return iReturn;
}