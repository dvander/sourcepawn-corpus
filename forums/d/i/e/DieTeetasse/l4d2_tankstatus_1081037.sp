#include <sourcemod>
#pragma semicolon 1

#define HUD_INTERVAL 0.5
#define PLUGIN_VERSION "1.0.2"

/*
History:
#######################
v1.0.3:
 - no panel anymore (slot buttons were disabled)
 - fixed health at death

v1.0.2:
 - fixed tank frustration bug

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
new TankHealthOld = 0;

//plugin start
//#######################
public OnPluginStart()
{
	HookEvent("tank_spawn", Tank_Spawn_Event);
	HookEvent("tank_frustrated", Tank_Frustrated_Event);
	HookEvent("player_death", Player_Death_Event);
	HookEvent("round_end", Round_End_Event);
}


//events
//#######################
public Action:Tank_Spawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankClient = GetClientOfUserId(GetEventInt(event, "userid"));
	TankAlive = true;
	TankHealthOld = 10000;
	
	ShowHUD();
	CreateTimer(HUD_INTERVAL, HUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:Tank_Frustrated_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankClient = GetClientOfUserId(GetEventInt(event, "userid"));
	TankAlive = true;
	
	PrintToChatAll("Frustrated!");
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
	if (!TankAlive) return Plugin_Stop;
	if (!IsPlayerAlive(TankClient)) return Plugin_Continue;
	
	new health = GetEntProp(TankClient, Prop_Send, "m_iHealth");
	if (health > TankHealthOld)
	{
		ShowHUD(true);
		return Plugin_Stop;
	}
	TankHealthOld = health;
	
	ShowHUD();
	return Plugin_Continue;
}

//private function
//#######################
ShowHUD(bool:isdead = false)
{
	if (TankClient == -1 || !TankAlive) return;
	if (!IsClientInGame(TankClient)) return;
	if (!IsPlayerAlive(TankClient)) return;
	
	new String:text[128];
	
	if (IsFakeClient(TankClient)) text = "Tank Info:\nPlayer: AI";
	else Format(text, sizeof(text), "Tank Info:\nPlayer: %N", TankClient);

	if (isdead) PrintHintTextToAll("%s\nHealth: dead", text);
	else PrintHintTextToAll("%s\nHealth: %d", text, GetEntProp(TankClient, Prop_Send, "m_iHealth"));
}  


public HUDHandler(Handle:menu, MenuAction:action, param1, param2)
{
}