#include <sourcemod>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define HUD_INTERVAL 1.0
#define PLUGIN_VERSION "1.0.6"
#define TANKCLASS_L4D2 8
#define TEAM_INFECTED 3
#define TEAM_SURVIVOR 2

/*
History:
########################
v1.0.6:
 - added cvar version
 - added cvar for enabling and team selection
 - added frustration output plus cvar for enabling and team selection
 - added fire and bile status
 - disabled output for tank
 
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
	description = "Shows tank status (health, fire, bile, rage)",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=117431"
};

//global definitions
//#######################
new TankClient = -1;
new TankHealthDefault = 6000;
new TankHealthOld = 0;
new bool:TankIt = false;
new Handle:CvarEnable;
new Handle:CvarFrustration;

//plugin start
//#######################
public OnPluginStart()
{
	CreateConVar("l4d2_tankstatus_version", PLUGIN_VERSION, "Tankstatus version", CVAR_FLAGS|FCVAR_DONTRECORD);
	CvarEnable = CreateConVar("l4d2_tankstatus_enable", "2", "Tankstatus - enable status display (0 = disabled, 1 = only inf, 2 = inf + spec, 3 = all)", CVAR_FLAGS);
	CvarFrustration = CreateConVar("l4d2_tankstatus_enable_frustration", "1", "Tankstatus - enable frustration add (0 = disabled, 1 = only inf, 2 = inf + spec, 3 = all)", CVAR_FLAGS);

	HookEvent("tank_spawn", Tank_Spawn_Event);
	HookEvent("player_death", Player_Death_Event);
	HookEvent("round_end", Round_End_Event);
	HookEvent("player_now_it", Player_It_Event);
	HookEvent("player_no_longer_it", Player_Not_It_Event);
}

//events
//#######################
public Action:Tank_Spawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(CvarEnable) == 0) return Plugin_Continue;

	TankHealthDefault = RoundFloat(1.5 * GetConVarFloat(FindConVar("z_tank_health")));
	TankHealthOld = TankHealthDefault;
	TankIt = false;

	UpdateHUD();
	ShowHUD();
	CreateTimer(HUD_INTERVAL, HUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
	
	return Plugin_Continue;
}

public Action:Player_Death_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetClientOfUserId(GetEventInt(event, "userid")) == TankClient) TankClient = -1;
	
	return Plugin_Continue;
}

public Action:Round_End_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankClient = -1;
	
	return Plugin_Continue;
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
	
	new String:text[256];
	new String:frusttext[256];
	new String:temptext[64];
	
	if (IsFakeClient(TankClient)) text = "Tank: AI\n";
	else Format(text, sizeof(text), "Tank: %N\n", TankClient);
	
	if (isdead) temptext = "Health: dead";
	else
	{
		new bool:fire = false;
		//check fire status
		if(GetEntityFlags(TankClient) & FL_ONFIRE) fire = true;
		
		if (TankIt && fire) Format(temptext, sizeof(temptext), "Health: %d hp (OnFire, InBile)", GetClientHealth(TankClient));
		else if(TankIt) Format(temptext, sizeof(temptext), "Health: %d hp (InBile)", GetClientHealth(TankClient));
		else if(fire) Format(temptext, sizeof(temptext), "Health: %d hp (OnFire)", GetClientHealth(TankClient));
		else Format(temptext, sizeof(temptext), "Health: %d hp", GetClientHealth(TankClient));
	}
	
	StrCat(text, sizeof(text), temptext);
	temptext = "";
	
	new displaymode = GetConVarInt(CvarEnable);
	new frustmode = GetConVarInt(CvarFrustration);	
	
	//frust
	if (frustmode > 0)
	{
		if (!isdead)
		{
			if (IsFakeClient(TankClient)) temptext = "\nControl: --";
			else Format(temptext, sizeof(temptext), "\nControl: %d percent", 100 - GetEntProp(TankClient, Prop_Send, "m_frustration"));
		}
		
		Format(frusttext, sizeof(frusttext), "%s%s", text, temptext);
		temptext = "";
	}
	
	for (new i = 1; i < MaxClients +1; i++)
	{
		//ingame?
		if (!IsClientInGame(i)) continue;	
		//human?
		if (IsFakeClient(i)) continue;	
		//tank?
		if (i == TankClient) continue;
			
		new team = GetClientTeam(i);
		//infected
		if (team == TEAM_INFECTED)
		{
			if(frustmode > 0) PrintHintText(i, frusttext);
			else PrintHintText(i, text);
		}
		//survivor
		else if (team == TEAM_SURVIVOR && displaymode > 2)
		{
			if (frustmode > 2) PrintHintText(i, frusttext);
			else PrintHintText(i, text);
		}
		//spectators
		else if (displaymode > 1)
		{
			if (frustmode > 1) PrintHintText(i, frusttext);
			else PrintHintText(i, text);			
		}
	}
}  

public HUDHandler(Handle:menu, MenuAction:action, param1, param2)
{
}