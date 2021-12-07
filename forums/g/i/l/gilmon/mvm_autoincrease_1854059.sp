#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

new bool:isMvMEndless = false;
new bool:isTimerStart = false;
new Float:timerDelay;
new Float:multiplier;
new hour = 0;
new min = 0;
new sec = 0;

// Plugin definitions
public Plugin:myinfo = 
{
	name = "[TF2]Endless Mode Increase",
	author = "Kirisame",
	description = "endless plus madness!",
	version = PLUGIN_VERSION,
	url = "moetouhou.net"
};

public OnPluginStart()
{
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("mvm_begin_wave", Event_MVMStart);

	timerDelay = GetRandomFloat(600.0, 750.0);
}

public Action:AddAmmo(client, args)
{
	CheatCommand(client, "givecurrentammo");
	return Plugin_Handled;
}

public Event_MVMStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isMvMEndless = true;
	isTimerStart = true;
	AutoInc();
	CreateTimer(1.0, CountTime, _, TIMER_REPEAT);
	hour = 0;
	min = 0;
	sec = 0;
	multiplier = 1.0;
	ServerCommand("sm_cvar tf_populator_health_multiplier 1.0");
}

public Action:CountTime(Handle:timer)
{
	if(isTimerStart)
	{
		sec++;
		if(sec > 59)
		{
			sec = 0;
			min++;
		}
		if(min > 59)
		{
			min = 0;
			hour++;
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	isMvMEndless = false;
	isTimerStart = false;
	PrintToChatAll("\n\n\x05Game is End!\x04 All Players survive time:\x03       %d:%d:%d\x01\n\n", hour, min, sec);
	hour = 0;
	min = 0;
	sec = 0;
}

public AutoInc()
{
	if(isMvMEndless)
	{
		CreateTimer(2 * timerDelay, DoInc);
	}
}

public Action:DoInc(Handle:timer)
{
	ServerCommand("sm_cvar tf_populator_health_multiplier %f", multiplier);
	multiplier += 0.3;
	CreateTimer(timerDelay, DoInc);
	return Plugin_Handled;
}