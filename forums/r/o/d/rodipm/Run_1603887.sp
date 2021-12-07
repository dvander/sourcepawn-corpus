#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Run!",
	author = "rodipm",
	description = "This plugin allows you to run for determinated time pressing both SHIF+E",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}
	
#define CHECK buttons & IN_SPEED && buttons & IN_USE && IsPlayerAlive(client)
#define CHECKNOT buttons & IN_DUCK && buttons & IN_SPEED && buttons & IN_USE && IsPlayerAlive(client)

new Handle:TimerSlow[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TimerRecover[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TimerCheckTime[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:cvar_speed = INVALID_HANDLE;
new Handle:cvar_slow = INVALID_HANDLE;
new Handle:cvar_time = INVALID_HANDLE;
new Handle:cvar_recover = INVALID_HANDLE;

new bool:running[MAXPLAYERS+1];
new bool:canrun[MAXPLAYERS+1];

new Float:TimeLeft[MAXPLAYERS+1];

public OnPluginStart()
{
	cvar_speed = CreateConVar("run_speed", "1.5", "Sets the speed of run (normal is 1.0)", 0, true, 1.0);
	cvar_slow = CreateConVar("run_slowdown", "0.2", "Sets the slowdown rate (for smoothest stop), can't be higher than 'run_speed'", 0, true, 0.1);
	cvar_time = CreateConVar("run_time", "10.0", "Sets how many time a player can run. 0 - For disable", 0, true, 0.0);
	cvar_recover = CreateConVar("run_recover", "5.0", "Sets how many time the player will have to wait after using all of his 'run_time'", 0, true, 0.0);
	
	SetVars();
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(canrun[client])
	{
		//This if can be a little cnfuse, but everything it checks is if the player is holding both SHIFT(speed) and E(use) and NOT holding CTRL(duck) and check if is pressing one of the buttons W A S D or just one, or two... If is pressing CTRL won't speed up
		if((CHECKNOT && buttons & IN_FORWARD) || (CHECKNOT &&  buttons & IN_BACK) || (CHECKNOT && buttons & IN_MOVELEFT) || (CHECKNOT && buttons & IN_MOVERIGHT))
		{
			if(rpm_GetClientSpeed(client) != 1.0)
				TimerSlow[client] = CreateTimer(0.1, Slowdown, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}
		// This is almost the same as first but only work if not holding CTRL(because we don't want it to work while ducking
		if((CHECK && buttons & IN_FORWARD) || (CHECK &&  buttons & IN_BACK) || (CHECK && buttons & IN_MOVELEFT) || (CHECK && buttons & IN_MOVERIGHT))
		{
			// Another check for ducking, for if you press SHIFT + E and at least CTRL
			if(buttons & IN_DUCK)
				return Plugin_Continue;
			
			if(!running[client])
			{
				running[client] = true;
				if(GetConVarFloat(cvar_time) != 0.0 && TimerCheckTime[client] == INVALID_HANDLE)
					TimerCheckTime[client] = CreateTimer(1.0, CheckTime, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
				
			rpm_SetClientSpeed(client, GetConVarFloat(cvar_speed));
			
			//i deleted the IN_SPEED bit button for not slow down before speed sets (It just like 'ignoring' you're pressing SHIFT). This make the slowdown smoother.
			buttons &= ~IN_SPEED;
		}
		else
		{
			if(running[client])
				running[client] = false;
				
			if(rpm_GetClientSpeed(client) != 1.0)
			{
				TimerSlow[client] = CreateTimer(0.1, Slowdown, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Slowdown(Handle:timer, any:client)
{
	if(client && IsClientConnected(client) && IsClientInGame(client))
	{
		new Float:cspeed = rpm_GetClientSpeed(client);
		
		if(cspeed > 1.0)
		{
			rpm_SetClientSpeed(client, cspeed-GetConVarFloat(cvar_slow));
		}
		else if(cspeed <= 1.0)
		{
			rpm_SetClientSpeed(client, 1.0);
			KillTimer(timer);
			TimerSlow[client] = INVALID_HANDLE;
			return;
		}
	}
}

public Action:CheckTime(Handle:timer, any:client)
{
	if(running[client])
	{
		if(TimeLeft[client] > 0.0)
		{
			TimeLeft[client] -= 1.0;
			new iTimeLeft = RoundFloat(TimeLeft[client]);
			PrintHintText(client, "Run Time Left: %i", iTimeLeft);
		}
		else if(TimeLeft[client] == 0.0)
		{
			canrun[client] = false;
			running[client] = false;
			KillTimer(timer);
			TimerCheckTime[client] = INVALID_HANDLE;
			TimerRecover[client] = CreateTimer(GetConVarFloat(cvar_recover), Recover, client);
			TimerSlow[client] = CreateTimer(0.1, Slowdown, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			PrintToChat(client, "\x04[Run!\x03 By.:RpM\x04]\x03 Your run time is over!");
		}
	}
	else
	{
		KillTimer(timer);
		TimerCheckTime[client] = INVALID_HANDLE;		
	}
}

public Action:Recover(Handle:timer, any:client)
{
	TimeLeft[client] = GetConVarFloat(cvar_time);
	canrun[client] = true;
	running[client] = false;
	PrintToChat(client, "\x04[Run!\x03 By.:RpM\x04]\x03 You can run again!");
}

stock SetVars()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			running[i] = false;
			canrun[i] = true;
			
			if(GetConVarFloat(cvar_time) != 0.0)
				TimeLeft[i] = GetConVarFloat(cvar_time);
				
			TimerCheckTime[i] = INVALID_HANDLE;
			TimerSlow[i] = INVALID_HANDLE;
			TimerRecover[i] = INVALID_HANDLE;
		}
	}
}

// From RpMlib :D
stock rpm_SetClientSpeed(client, Float:ammount)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", ammount);
}

stock Float:rpm_GetClientSpeed(client)
{
	new SpeedOffGet = FindSendPropInfo("CBasePlayer","m_flLaggedMovementValue")
	return GetEntDataFloat(client, SpeedOffGet);
}