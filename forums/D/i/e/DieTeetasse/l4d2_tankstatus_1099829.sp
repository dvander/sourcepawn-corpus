#include <sourcemod>
#pragma semicolon 1

#define HUD_INTERVAL 0.5
#define PLUGIN_VERSION "1.0.5"
#define TANKCLASS_L4D2 8
#define TEAM_INFECTED 3

/*
History:
########################
v1.0.5:
 - fixed tank health over 32000hp displayed negative
 - fixed info disappearing by tank health over 32000hp
 
v1.0.4:
 - changed system

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
new TankClient = -1;
new TankHealthDefault = 6000;
new TankHealthOld = 0;

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
	TankHealthDefault = RoundFloat(1.5 * GetConVarFloat(FindConVar("z_tank_health")));
	TankHealthOld = TankHealthDefault;

	UpdateHUD();
	ShowHUD();
	CreateTimer(HUD_INTERVAL, HUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:Player_Death_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetClientOfUserId(GetEventInt(event, "userid")) == TankClient) TankClient = -1;
}

public Action:Round_End_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankClient = -1;
}

//timer
//#######################
public Action:HUD_Timer(Handle:timer)
{	
	new bool:stop = UpdateHUD();
	
	if (stop)
	{
		ShowHUD(true);
		return Plugin_Stop;
	}
	
	ShowHUD();
	return Plugin_Continue;
}

//private functions
//#######################
bool:UpdateHUD()
{
	//check if events detected roundend/death
	if (TankClient == -1 && TankHealthOld < TankHealthDefault) return true;

	TankClient = -1;

	for (new i = 1; i < MaxClients +1; i++)
	{
		//ingame?
		if (!IsClientInGame(i)) continue;
		//infected?
		if (GetClientTeam(i) != TEAM_INFECTED) continue;
		//alive?
		if (!IsPlayerAlive(i)) continue;
		//tank?
		if (GetEntProp(i, Prop_Send, "m_zombieClass") != TANKCLASS_L4D2) continue;
	
		TankClient = i;	
		break;
	}
	
	if (TankClient == -1) return true;
	
	new health = GetClientHealth(TankClient);
	if (health > TankHealthOld) return true;
	TankHealthOld = health;
	
	return false;
}

ShowHUD(bool:isdead = false)
{
	if (TankClient == -1) return;
	if (!IsClientInGame(TankClient)) return;
	if (!IsPlayerAlive(TankClient)) return;
	
	new String:text[128];
	
	if (IsFakeClient(TankClient)) text = "Tank Info:\nPlayer: AI";
	else Format(text, sizeof(text), "Tank Info:\nPlayer: %N", TankClient);

	if (isdead) PrintHintTextToAll("%s\nHealth: dead", text);
	else PrintHintTextToAll("%s\nHealth: %d", text, GetClientHealth(TankClient));
}  

public HUDHandler(Handle:menu, MenuAction:action, param1, param2)
{
}