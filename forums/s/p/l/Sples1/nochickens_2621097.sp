#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

Handle SlayTimer;
bool TickerState = false;

public Plugin myinfo = 
{
	name = "[CSGO] ChickenSlayer", 
	author = "Entity", 
	description = "Blocks the chickens", 
	version = "0.1.1"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public Action OnRoundStart(Event event, char[] name, bool dontBroadcast)
{
	SlayTimer = CreateTimer(1.0, Timer_ChickenSlayer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	TickerState = true;
} 

public Action Timer_ChickenSlayer(Handle timer)
{
	char chicken = -1;
	while ((chicken = FindEntityByClassname(chicken, "chicken")) != -1)
	if (IsValidEdict(chicken))
	{
		AcceptEntityInput(chicken, "Deactivate");
		AcceptEntityInput(chicken, "Kill");
	}
}

public Action OnRoundEnd(Event event, char[] name, bool dontBroadcast)
{
	if (TickerState == true)
	{
		KillTimer(SlayTimer);
		TickerState = false;
	}
}