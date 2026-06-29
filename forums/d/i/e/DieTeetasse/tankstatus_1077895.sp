#include <sourcemod>
#pragma semicolon 1

#define HUD_INTERVAL 2.0
#define PLUGIN_VERSION "1.0.1"

/*
History:
#######################

v1.0.1:
 - added round end check
 - admins will get a hinttext, clients a panel

v1.0.0:
 - initial
*/

//plugin info
//#######################
public Plugin:myinfo =
{
	name = "Tank status",
	author = "Die Teetasse",
	description = "Shows tank status to everbody",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=117431"
};

//global definitions
//#######################
new bool:TankAlive = false;
new TankClient = -1;

//plugin start
//#######################
public OnPluginStart()
{
	HookEvent("tank_spawn", Tank_Spawn_Event);
	HookEvent("player_death", Player_Death_Event);
	HookEvent("round_end", Round_End_Event);
}


//events
//#######################
public Action:Tank_Spawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankClient = GetClientOfUserId(GetEventInt(event, "userid"));
	TankAlive = true;

	CreateTimer(HUD_INTERVAL, HUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:Player_Death_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == TankClient)
	{
		TankClient = -1;
		TankAlive = false;
	}
}

public Action:Round_End_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankClient = -1;
	TankAlive = false;
}

//timer
//#######################
public Action:HUD_Timer(Handle:timer)
{	
	if(!TankAlive) return Plugin_Stop;

	ShowHUD();
	return Plugin_Continue;
}

//private function
//#######################
ShowHUD()
{
	if (TankClient == -1 || !TankAlive) return;
	if (!IsClientInGame(TankClient)) return;
	if (!IsPlayerAlive(TankClient)) return;

	new String:text[128];
	new Handle:HUD = CreatePanel();

	DrawPanelText(HUD, "Tank Info:");
	DrawPanelText(HUD, "##################");

	if (IsFakeClient(TankClient)) text = "Player: AI";
	else Format(text, sizeof(text), "Player: %N", TankClient);

	DrawPanelText(HUD, text);

	new health = GetEntProp(TankClient, Prop_Send, "m_iHealth");
	Format(text, sizeof(text), "Health: %d", health);

	DrawPanelText(HUD, text);

	for(new client = 1; client < MaxClients+1; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (IsFakeClient(client)) continue;
		if (client == TankClient) continue;

		/* client or admin?
		client => panel
		admin => hinttext */

		if (GetUserFlagBits(client) == 0) SendPanelToClient(HUD, client, HUDHandler, 3);
		else
		{
			if (IsFakeClient(TankClient)) text = "Player: AI";
			else Format(text, sizeof(text), "Player: %N", TankClient);
		
			PrintHintText(client, "%s\nHealth: %d", text, health);
		}	
	}
}  


public HUDHandler(Handle:menu, MenuAction:action, param1, param2)
{
}