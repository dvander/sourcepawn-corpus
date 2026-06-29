#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"1.1"

#include <sourcemod>
#include <geoip> // v.2
#include <tz>

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
    name = "[ANY] Days to New Year",
    author = "Dragokas",
    description = "Show days elapsed to the New Year",
    version = PLUGIN_VERSION,
    url = "https://github.com/dragokas"
}

/*
	Required:
	 - GeoIP v2 by Accelerator
	 https://forums.alliedmods.net/showthread.php?t=311477
	 
	 - TimeZone API by Accelerator
	 https://forums.alliedmods.net/showthread.php?t=311533

	Note: this plugin is client's local time aware.
	
	Warning: after installing GeoIP v2,
	you should recompile ALL plugins that used original geoip include,
	otherwise you'll receive very unusual server behaviour.
*/

bool g_bRepeatAdvert;
bool g_bLeft4Dead;
bool g_bFirstConnect[MAXPLAYERS+1] = {true, ...};

int g_iQuery[MAXPLAYERS+1];

ConVar g_ConVarOnJoinDelay;
ConVar g_ConVarOnJoin;
ConVar g_ConVarOnRoundStart;
ConVar g_ConVarOnFinaleWin;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead || test == Engine_Left4Dead2)
	{
		g_bLeft4Dead = true;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("days_to_new_year.phrases");
	
	CreateConVar("sm_newyear_days_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
	
	g_ConVarOnJoinDelay = 	CreateConVar("sm_newyear_days_delay", 			"17", 	"How many seconds to wait to display message after trigger raised", CVAR_FLAGS);
	
	g_ConVarOnJoin = 		CreateConVar("sm_newyear_days_onjoin", 			"1", 	"Show message on client join first time (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_ConVarOnRoundStart = 	CreateConVar("sm_newyear_days_onroundstart", 	"0", 	"Show message on round start (1 - Yes, 0 - No)", CVAR_FLAGS);
	
	// Left 4 dead only
	if ( g_bLeft4Dead )
	{
		g_ConVarOnFinaleWin = 	CreateConVar("sm_newyear_days_onfinalewin", 	"1", 	"Show message when team wins the finale (1 - Yes, 0 - No)", CVAR_FLAGS);
	}
	
	AutoExecConfig(true, "sm_days_to_newyear");
	
	HookEvent("round_start",				Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("player_disconnect",			Event_PlayerDisconnect,	EventHookMode_PostNoCopy);
	HookEventEx("finale_escape_start",		Event_EscapeStart,		EventHookMode_PostNoCopy);
	HookEventEx("finale_vehicle_leaving",	Event_EscapeFinish,		EventHookMode_PostNoCopy);	
	
	RegConsoleCmd("sm_days", CmdDays, "Show days / hours / minutes / seconds elapsed to New Year");
}

Action CmdDays(int client, int args)
{
	GetLocalTime(client);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bFirstConnect[client] = true;
}

public void OnClientPutInServer(int client)
{
	if (g_ConVarOnJoin.BoolValue && g_bFirstConnect[client]) 
	{
		if (client && !IsFakeClient(client)) 
		{
			g_bFirstConnect[client] = false;
			CreateTimer(g_ConVarOnJoinDelay.FloatValue, Timer_GetLocalTime, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRepeatAdvert = false;
	
	if (g_ConVarOnRoundStart.BoolValue)
	{
		CreateTimer(g_ConVarOnJoinDelay.FloatValue, Timer_GetLocalTimeAll, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_EscapeFinish(Event event, const char[] name, bool dontBroadcast)
{
	g_bRepeatAdvert = false;
}

public void Event_EscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_ConVarOnFinaleWin.BoolValue)
	{
		g_bRepeatAdvert = true;
		GetLocalTimeAll();
	}
}

Action Timer_GetLocalTime(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if (client && IsClientInGame(client))
	{
		GetLocalTime(client);
	}
}

Action Timer_GetLocalTimeAll(Handle timer)
{
	GetLocalTimeAll();
}

void GetLocalTimeAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			GetLocalTime(i);
		}
	}
}

void GetLocalTime(int client)
{
	static char sIP[32];
	GetClientIP(client, sIP, sizeof(sIP));
	
	if (GeoipTimezone(sIP, sIP, sizeof(sIP))) // Get timezone and rewrite sTemp variable
	{
		g_iQuery[client] = TZ_GetTime(sIP);
	}
}

public void TZ_OnQueryFinished(int iQueryNum, int iRetValue)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (iQueryNum == g_iQuery[i])
		{
			if (IsClientInGame(i))
			{
				ShowAdvert(i, iRetValue);
			}
			break;
		}
	}
}

void ShowAdvert(int client, int iLocalTime)
{
	int iLeft = CalcElapsed(iLocalTime);
	
	DataPack dp = new DataPack();
	dp.WriteCell(GetClientUserId(client));
	dp.WriteCell(iLeft);
	
	CreateTimer(1.0, Timer_ShowAdvert, dp, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
}

Action Timer_ShowAdvert( Handle timer, DataPack dp )
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	DataPackPos DpSecPos = dp.Position;
	int iLeft = dp.ReadCell();
	int D, H, M, S;
	
	SplitSeconds(iLeft, D, H, M, S);
	
	if (client && IsClientInGame(client))
	{
		PrintHintText(client, "%t", "Elapsed", D, H, M, S); // "%i d. %i h. %i m. %i s.\nto go until the New Year"
	}
	if (iLeft != 0)
	{
		iLeft--;
	}
	dp.Position = DpSecPos;
	dp.WriteCell(iLeft); // minus 1 sec. (overwrite)
	return g_bRepeatAdvert ? Plugin_Continue : Plugin_Stop;
}

int CalcElapsed(int iLocalTime)
{
	static char sY[8], sD[8], sH[8], sM[8], sS[8];
	int Y, D, H, M, S;
	int iUnix = iLocalTime;
	FormatTime(sY, 8, "%Y", iUnix);
	FormatTime(sD, 8, "%j", iUnix);
	FormatTime(sH, 8, "%H", iUnix);
	FormatTime(sM, 8, "%M", iUnix);
	FormatTime(sS, 8, "%S", iUnix);
	Y = StringToInt(sY);
	D = StringToInt(sD);
	H = StringToInt(sH);
	M = StringToInt(sM);
	S = StringToInt(sS);
	
	iUnix -= S + M * 60 + H * 3600 + (D - 1) * 24 * 3600;
	iUnix += (IsLeapYear(Y) ? 366 : 365) * 24 * 3600;
	
	return iUnix - iLocalTime;
}

void SplitSeconds(int iUnix, int &D, int &H, int &M, int &S)
{
	D = iUnix / 86400;
	iUnix -= D * 86400;
	H = iUnix / 3600;
	iUnix -= H * 3600;
	M = iUnix / 60;
	S = iUnix - M * 60;
}

bool IsLeapYear(int iYear)
{
	return (iYear % 4 == 0) && ((iYear % 100 != 0) || (iYear % 400 == 0));
}