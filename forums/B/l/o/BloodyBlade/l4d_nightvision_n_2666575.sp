/* Plugin Template generated by Pawn Studio */
#pragma newdecls required
#include <sourcemod>

ConVar TimerNVision;
Handle TimerOnOff = null;

public Plugin myinfo = 
{
	name = "Night Vision",
	author = "Pan Xiaohai & Mr. Zero",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public void OnPluginStart()
{
	TimerNVision = CreateConVar("TimerNVision", "30.0", "Number of seconds before night vision is switched on / off.", 0, true, 0.0);
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(!TimerOnOff)
    {
		TimerOnOff = CreateTimer(GetConVarFloat(TimerNVision), TimerUpdate, _, TIMER_REPEAT);
	}
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if(TimerOnOff)
    {
		KillTimer(TimerOnOff);
		TimerOnOff = null;
	}
}

public Action TimerUpdate(Handle timer, int client)
{
	SwitchNightVision(client);
}

void SwitchNightVision(int client)
{
	int d = GetEntProp(client, Prop_Send, "m_bNightVisionOn");
	if(d == 0)
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1); 
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
	}
}
