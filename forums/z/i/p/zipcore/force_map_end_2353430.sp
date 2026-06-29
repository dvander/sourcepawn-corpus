#include <sourcemod>
#include <cstrike>
#include <multicolors>

public Plugin myinfo = 
{
	name = "Force Map End",
	author = "Zipcore, 1NutWunDeR",
	description = "",
	version = "1.1",
	url = "www.zipcore.net"
}

public void OnMapStart()
{
	CreateTimer(1.0, CheckRemainingTime, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckRemainingTime(Handle timer)
{
	Handle hTmp;	
	hTmp = FindConVar("mp_timelimit");
	int iTimeLimit = GetConVarInt(hTmp);			
	if (hTmp != INVALID_HANDLE)
		CloseHandle(hTmp);	
	if (iTimeLimit > 0)
	{
		int timeleft;
		GetMapTimeLeft(timeleft);
		
		switch(timeleft)
		{
			case 1800: 	CPrintToChatAll("{lightred}Timeleft: 30 minutes");
			case 1200: 	CPrintToChatAll("{lightred}Timeleft: 20 minutes");
			case 600: 	CPrintToChatAll("{lightred}Timeleft: 10 minutes");
			case 300: 	CPrintToChatAll("{lightred}Timeleft: 5 minutes");
			case 120: 	CPrintToChatAll("{lightred}Timeleft: 2 minutes");
			case 60: 	CPrintToChatAll("{lightred}Timeleft: 60 seconds");
			case 30: 	CPrintToChatAll("{lightred}Timeleft: 30 seconds");
			case 15: 	CPrintToChatAll("{lightred}Timeleft: 15 seconds");
			case -1: 	CPrintToChatAll("{lightred}Timeleft: 3..");
			case -2: 	CPrintToChatAll("{lightred}Timeleft: 2..");
			case -3: 	CPrintToChatAll("{lightred}Timeleft: 1..");
		}
		
		if(timeleft < -3)
			CS_TerminateRound(0.0, CSRoundEnd_Draw, true);
	}
	
	return Plugin_Continue;
}

public Action CS_OnTerminateRound(float &fDelay, CSRoundEndReason &iReason)
{
	return Plugin_Continue;
}