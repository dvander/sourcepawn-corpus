#pragma semicolon 1
#include <sourcemod>

new g_delay[MAXPLAYERS+1];
new bool:g_bIsTimed[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name        = "[TF2] Timer",
	author      = "Pelipoika",
	description = "Toggleabble countdown timer",
	version     = "0.0.0",
	url         = "google.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_timer", Command_TakeTime, 0);
}

public OnClientPostAdminCheck(client)
{
	g_bIsTimed[client] = false;
}

public Action:Command_TakeTime(client, args)
{	
	if(g_bIsTimed[client])
	{
		SetHudTextParams(-1.0, 0.99, 5.0, 255, 0, 0, 200);
		ShowHudText(client, -1, "Time %i", g_delay[client]);
		g_delay[client] = 0;
		g_bIsTimed[client] = false;
		PrintToChat(client, "Timer: Off");
	}
	else
	{
		g_bIsTimed[client] = true;
		Delay(client);
		PrintToChat(client, "Timer: On");
	}
	return Plugin_Handled;
}

public Delay(client)
{
	CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Delay(Handle:timer, any:client)
{
	g_delay[client]++;
	if (g_delay[client] && g_bIsTimed[client])
	{
		SetHudTextParams(-1.0, 0.99, 1.0, 0, 255, 0, 200);
		ShowHudText(client, -1, "Time %i", g_delay[client]);
		CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Handled;
}