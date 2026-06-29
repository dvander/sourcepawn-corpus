#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#pragma newdecls required

public Plugin myinfo =
{
	name		=	"Anti-Double Engineer Swing",
	author		=	"Batfoxkid",
	description	=	"Quick patch of double Engineer swings",
	version		=	"1.0"
};

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		float gameTime = GetGameTime();
		static float delay[36];
		if(buttons & IN_ATTACK)
			delay[client] = gameTime+0.25;

		if((buttons & IN_ATTACK2) && delay[client]>gameTime)
		{
			buttons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}