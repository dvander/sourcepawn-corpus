#include <sourcemod>
#include <cstrike>

new bool:g_bAllowRoundEnd = false;

public Plugin:myinfo = 
{
	name = "Force Map End",
	author = "Zipcore, 1NutWunDeR",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	CreateTimer(1.0, CheckRemainingTime, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:CheckRemainingTime(Handle:timer)
{
	new Handle:hTmp;	
	hTmp = FindConVar("mp_timelimit");
	new iTimeLimit = GetConVarInt(hTmp);			
	if (hTmp != INVALID_HANDLE)
		CloseHandle(hTmp);	
	if (iTimeLimit > 0)
	{
		new timeleft;
		GetMapTimeLeft(timeleft);
		
		switch(timeleft)
		{
			case 1800: PrintToChatAll("Time Remaining: 30 minutes");
			case 1200: PrintToChatAll("Time Remaining: 20 minutes");
			case 600: PrintToChatAll("Time Remaining: 10 minutes");
			case 300: PrintToChatAll("Time Remaining: 5 minutes");
			case 120: PrintToChatAll("Time Remaining: 2 minutes");
			case 60: PrintToChatAll("Time Remaining: 60 seconds");
			case 30: PrintToChatAll("Time Remaining: 30 seconds");
			case 15: PrintToChatAll("Time Remaining: 15 seconds");
			case -1: PrintToChatAll("3..");
			case -2: PrintToChatAll("2..");
			case -3: PrintToChatAll("1..");
		}
		
		if(timeleft < -3 && !g_bAllowRoundEnd)
		{
			g_bAllowRoundEnd = true;
			CS_TerminateRound(0.5, CSRoundEnd_TerroristWin, true);
		}
	}
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	g_bAllowRoundEnd = false;
	return Plugin_Continue;
}