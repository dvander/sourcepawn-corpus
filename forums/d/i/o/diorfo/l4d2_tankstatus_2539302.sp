#include <sourcemod>
#pragma semicolon 1

#define HUD_INTERVAL 2.0
#define PLUGIN_VERSION "1.0.2.1"

/*
History:
#######################


v1.0.2.1:
 - updated to versus mod (only infected can see the tank status)
 - modified to all players can only see panel
 - solved minor bugs
 
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
	author = "Die Teetasse, modified by diorfo",
	description = "Shows tank status to team",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=117431"
};

//global definitions
//#######################
new bool:TankAlive = false;
new bool:TankIt = false;
new TankClient = -1;

//plugin start
//#######################
public OnPluginStart()
{
	HookEvent("tank_spawn", Tank_Spawn_Event);
	HookEvent("tank_frustrated", Tank_Frustrated_Event);
	HookEvent("player_death", Player_Death_Event);
	HookEvent("round_end", Round_End_Event);
	HookEvent("player_now_it", Player_It_Event);
	HookEvent("player_no_longer_it", Player_Not_It_Event);
	HookEvent("round_start", Round_Start_Event);	
}


//events
//#######################
public Action:Tank_Spawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankClient = GetClientOfUserId(GetEventInt(event, "userid"));
	TankAlive = true;	

	CreateTimer(HUD_INTERVAL, HUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:Tank_Frustrated_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankClient = GetClientOfUserId(GetEventInt(event, "userid"));
	TankAlive = true;
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

public Action:Player_It_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetClientOfUserId(GetEventInt(event, "userid")) == TankClient) TankIt = true;
	
	return Plugin_Continue;
}

public Action:Player_Not_It_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetClientOfUserId(GetEventInt(event, "userid")) == TankClient) TankIt = false;
	
	return Plugin_Continue;
}

public Action:Round_Start_Event(Handle:event, const String:name[], bool:dontBroadcast)
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

	new String:text[1024];
	new Handle:HUD = CreatePanel();

	DrawPanelText(HUD, "Tank Info:");
	DrawPanelText(HUD, "##################");
	
	if (IsFakeClient(TankClient)) text = "Player: BOT";
	else Format(text, sizeof(text), "Player: %N", TankClient);
	
	DrawPanelText(HUD, text);
	
	
	new bool:fire = false;
	//check fire status
	if(GetEntityFlags(TankClient) & FL_ONFIRE) fire = true;		
		
	if (TankIt && fire) Format(text, sizeof(text), "Health: %d (OnFire, InBile)", GetClientHealth(TankClient));
	else if(TankIt) Format(text, sizeof(text), "Health: %d (InBile)", GetClientHealth(TankClient));
	else if(fire) Format(text, sizeof(text), "Health: %d (OnFire)", GetClientHealth(TankClient));
	else Format(text, sizeof(text), "Health: %d", GetClientHealth(TankClient));	
	
	DrawPanelText(HUD, text);
	
	if (GetEntityFlags(TankClient) & FL_ONFIRE) text = "Control: 100";
	else Format(text, sizeof(text), "Control: %d", 100 - GetEntProp(TankClient, Prop_Send, "m_frustration"));
	
	DrawPanelText(HUD, text);

	for(new client = 1; client < MaxClients+1; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (IsFakeClient(client)) continue;
		if (client == TankClient) continue;
		if (GetClientTeam(client) != 3) continue;

		SendPanelToClient(HUD, client, HUDHandler, 3);			
	}
}  

public HUDHandler(Handle:menu, MenuAction:action, param1, param2)
{
}