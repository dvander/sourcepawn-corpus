#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <bhopstats>

ConVar g_cvMaxJumpsPerJump;
int g_iJumps[MAXPLAYERS + 1];

public void OnPluginStart()
{
	g_cvMaxJumpsPerJump = CreateConVar("sm_max_jumps_per_jump", "4", "Maximum jumps per jump before being slayed.", _, true, 1.0);
}

public void Bunnyhop_OnJumpPressed(int client, bool onground)
{
	g_iJumps[client]++;
}

public void Bunnyhop_OnTouchGround(int client)
{
	if(g_iJumps[client] > g_cvMaxJumpsPerJump.IntValue)
		ForcePlayerSuicide(client);

	g_iJumps[client] = 0;
}