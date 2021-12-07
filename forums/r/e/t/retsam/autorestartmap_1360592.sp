/***************************************************************************************** 
* AutoRestartMap (ANY)
* Author(s): retsam
* Date: 10/1/2010
* File: autorestartmap.sp
* Description: Manages automatically restarting map based on hour of day or timer.
******************************************************************************************
* 
*
* 0.3 - Condensed timers together into one. 
*
* 0.2 - Added cvar to change method of restarting maps to either SDKcall 'EndMultiplayerGame' or servercommand 'changelevel'.
*     - Added endgame gamedata file to use so SDKcall is not OS dependent. 
*     - Added sound notification files.
*     - Added more printtoserver and logging messages.
*     - Added cvar to specify which hour of the day to execute timer.     
*     - Fixed problem using the mapstart forward and changed to configsexecuted forward. Forgot we wouldnt have the cvar values yet under mapstart.     
*     - Added cvar for mode to change between timer by hour of day or by timed duration.
*     - Added gamemod check to begin to make plugin supported by all mods.     
*     - Re-added cvar back for timer duration for mode1.
*     - If calculated hour difference is less than 6 hours, plugin will set timer for the next day. This avoids doing too fast of resets after a recent mapchange.     
*
* 0.1	- Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.3"

#define SOUND_ATTN "vo/announcer_attention.wav"
#define SOUND_TENSEC "vo/announcer_ends_10sec.wav"

enum e_SupportedMods
{
	GameType_Other,
	GameType_TF
};

new Handle:g_hEndGame = INVALID_HANDLE;
new Handle:g_hNotifyTimer = INVALID_HANDLE;
new Handle:g_hCountDownTimer = INVALID_HANDLE;
new Handle:Cvar_CM_Enabled = INVALID_HANDLE;
new Handle:Cvar_CM_Hour = INVALID_HANDLE;
new Handle:Cvar_CM_NotifyTime = INVALID_HANDLE;
new Handle:Cvar_CM_Mode = INVALID_HANDLE;
new Handle:Cvar_CM_Timer = INVALID_HANDLE;
new Handle:Cvar_CM_Method = INVALID_HANDLE;

new g_cvarNotifyTime;
new g_cvarHourSet;
new g_cvarChangeMethod;
new g_TimerCountdown = 0;
new e_SupportedMods:g_CurrentMod;

new Float:g_fChangemapTime;

new bool:g_bIsEnabled = true;
new bool:g_bMapHasSetup = false;

public Plugin:myinfo = 
{
	name = "AutoRestartMap",
	author = "retsam",
	description = "Manages automatically restarting map based on hour of day or timer.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=144237"
}

public OnPluginStart()
{
	g_CurrentMod = GetCurrentMod();
	if(g_CurrentMod == GameType_TF)
	{
		PrepareSDKCalls();
	}

	CreateConVar("sm_autorestartmap_version", PLUGIN_VERSION, "Version of AutoRestartMap", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_CM_Enabled = CreateConVar("sm_autorestartmap_enabled", "1", "Enable restartmap plugin?(1/0 = yes/no)");
	Cvar_CM_Mode = CreateConVar("sm_autorestartmap_mode", "0", "Mode for restartmap plugin. (0=hour of day, 1=timer based)", _, true, 0.0, true, 1.0);
	Cvar_CM_Hour = CreateConVar("sm_autorestartmap_hour", "5", "Set the hour of day in military time(24-hour clock) to reset the map. (5 = 05:00[5AM], 17 = 17:00[5PM])", _, true, 1.0, true, 24.0);
	Cvar_CM_Timer = CreateConVar("sm_autorestartmap_timer", "43200.0", "Amount of time in seconds to set for map reset timer. (43200 = 12 hours)");
	Cvar_CM_NotifyTime = CreateConVar("sm_autorestartmap_notifytime", "120.0", "Amount of time in seconds remaining to send a public notification message about map change. (120.0 = 2 minutes)", _, true, 30.0, true, 1000.0);
	Cvar_CM_Method = CreateConVar("sm_autorestartmap_changemethod", "0", "Method used to end/change the map. (0=changelevel, 1=SDKcall EndMultiplayerGame(TF2 only))", _, true, 0.0, true, 1.0);

	HookConVarChange(Cvar_CM_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_CM_Hour, Cvars_Changed);
	HookConVarChange(Cvar_CM_NotifyTime, Cvars_Changed);
	HookConVarChange(Cvar_CM_Method, Cvars_Changed);

	AutoExecConfig(true, "plugin.autorestartmap");
}

PrepareSDKCalls()
{
	new Handle:hConf = LoadGameConfigFile("endgame");
	if(hConf == INVALID_HANDLE)
	{
		SetFailState("Could not find or read: gamedata/endgame.txt");
		CloseHandle(hConf);
		return;
	}
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "EndMultiplayerGame");
	g_hEndGame = EndPrepSDKCall();
	if(g_hEndGame == INVALID_HANDLE)
	{
		SetFailState("Failed to setup SDKCall.");
		CloseHandle(hConf);
		return;
	}

	CloseHandle(hConf);
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_CM_Enabled);
	g_cvarHourSet = GetConVarInt(Cvar_CM_Hour);
	g_cvarNotifyTime = GetConVarInt(Cvar_CM_NotifyTime);
	g_cvarChangeMethod = GetConVarInt(Cvar_CM_Method);
	new cvarMode = GetConVarInt(Cvar_CM_Mode);
	new cvarTimelimit = GetConVarInt(FindConVar("mp_timelimit"));
	//PrintToServer("[AUTORESTARTMAP] mp_timelimit cvar value is: %i", cvarTimelimit);

	if(g_bIsEnabled)
	{
		if(!g_bMapHasSetup || cvarTimelimit == 0)
		{
			g_TimerCountdown = 0;
			g_fChangemapTime = 0.0;
			ResetTimers();

			if(cvarMode == 0)
			{
				new hour, calcDiff;

				hour = getHour();
				//PrintToServer("[AUTORESTARTMAP] Hour is: %i", hour);
				calcDiff = getHourDifference(hour);
				//PrintToServer("[AUTORESTARTMAP] Hour Difference between cvar is: %i", calcDiff);
				g_fChangemapTime = (calcDiff * 3600.0);
			}
			else
			{
				g_fChangemapTime = GetConVarFloat(Cvar_CM_Timer);
			}

			PrintToServer("[AUTORESTARTMAP] Map will restart in: %f seconds.", g_fChangemapTime);
			
			new Float:fWarnTime;
			fWarnTime = (g_fChangemapTime - g_cvarNotifyTime);
			PrintToServer("[AUTORESTARTMAP] Warning notification will exec in: %f seconds.", fWarnTime);
			g_hNotifyTimer = CreateTimer(fWarnTime, Timer_NotifyTime);
		}
		else
		{
			PrintToServer("[AUTORESTARTMAP] **Disabled: Map has rounds or mp_timelimit not set to 0.**");
		}
	}
}

public OnMapStart()
{
	if(g_CurrentMod == GameType_TF)
	{
		PrecacheSound(SOUND_ATTN, true);
		PrecacheSound(SOUND_TENSEC, true);
	}

	Check_MapRoundTimer();
}

public OnMapEnd()
{
	if(g_bIsEnabled)
	{
		ResetTimers();
	}
}

public Action:Timer_NotifyTime(Handle:timer)
{
	if(g_CurrentMod == GameType_TF)
	{
		EmitSoundToAll(SOUND_ATTN);
	}
	
	PrintToServer("[AUTORESTARTMAP] **Map timelimit reached and will automatically restart in: %d seconds**", g_cvarNotifyTime);
	PrintCenterTextAll("Map restart in %d seconds!", g_cvarNotifyTime);
	
	PrintToChatAll("\x01-----------------------------------------------\x01");
	PrintToChatAll("\x01ATTN! Map timelimit reached and will automatically restart in: \x03%d seconds\x01", g_cvarNotifyTime);
	PrintToChatAll("\x01-----------------------------------------------\x01");
	
	g_TimerCountdown = g_cvarNotifyTime;
	g_hCountDownTimer = CreateTimer(1.0, Timer_RepeatCountDown, _, TIMER_REPEAT);
	
	g_hNotifyTimer = INVALID_HANDLE;
}

public Action:Timer_RepeatCountDown(Handle:timer)
{
	g_TimerCountdown--;
	//PrintToChatAll("\x01g_timercountdown = %d", g_TimerCountdown);
	if(g_TimerCountdown > 1 && g_TimerCountdown < 31)
	{
    if(g_TimerCountdown == 20)
    {
      PrintToServer("[AUTORESTARTMAP] **Map restarting in 20 seconds!**");
    }
    else if(g_TimerCountdown == 10)
		{
			if(g_CurrentMod == GameType_TF)
			{
				EmitSoundToAll(SOUND_TENSEC);
			}
			PrintToServer("[AUTORESTARTMAP] **Map restarting in 10 seconds!**");
		}
    
    PrintCenterTextAll("Map restart in: %d", g_TimerCountdown);
    PrintToChatAll("\x01Map restart in: %d..", g_TimerCountdown);
	}
	else if(g_TimerCountdown == 1)
	{
		PrintCenterTextAll("Map restarting...");
		PrintToChatAll("\x01Map restarting...");
	} 
	else if(g_TimerCountdown == 0)
  {
    LogMessage("[AUTORESTARTMAP] Restarting map due to %f second timelimit reached!", g_fChangemapTime);
    CreateTimer(0.1, Timer_AutoChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
    g_hCountDownTimer = INVALID_HANDLE;
    return Plugin_Stop;
  }

	return Plugin_Continue;
}

public Action:Timer_AutoChangeMap(Handle:timer)
{
	if(g_cvarChangeMethod == 1 && g_CurrentMod == GameType_TF)
	{
		SDKCall(g_hEndGame);
	}
	else
	{
		decl String:sNextmap[128];
		GetNextMap(sNextmap, sizeof(sNextmap));
		//LogMessage("[AUTORESTARTMAP] Nextmap is: %s", sNextmap);
		if(!StrEqual(sNextmap,"", false))
		{
			ServerCommand("changelevel %s", sNextmap);
		}
		else
		{
			decl String:sCurrentMap[128];
			GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
			
			PrintToServer("[AUTORESTARTMAP] **Nextmap NOT detected: restarting current map!**");
			ServerCommand("changelevel %s", sCurrentMap);
		}
	}
}

public ResetTimers()
{
	if(g_hNotifyTimer != INVALID_HANDLE)
	{
		CloseHandle(g_hNotifyTimer);
		g_hNotifyTimer = INVALID_HANDLE;
	}

	if(g_hCountDownTimer != INVALID_HANDLE)
	{
		CloseHandle(g_hCountDownTimer);
		g_hCountDownTimer = INVALID_HANDLE;
	}
}

stock Check_MapRoundTimer()
{
	new iTimerEnt = FindEntityByClassname(-1, "team_round_timer");
	if(iTimerEnt != -1)
	{
		g_bMapHasSetup = true;
    //LogMessage("[AUTORESTARTMAP] MAP HAS ROUNDS!");
	}
	else
	{
    g_bMapHasSetup = false;
    //LogMessage("[AUTORESTARTMAP] MAP DOES NOT HAVE ROUNDS!");
  }
}

stock getHour()
{
	decl String:sHour[3];

	FormatTime(sHour, sizeof(sHour), "%H");
	return StringToInt(sHour);
}

stock getHourDifference(hour)
{
  new timeDiff;
  timeDiff = (24 - hour) + g_cvarHourSet;
  
  if(timeDiff < 6)
  {
    timeDiff += 24;
  }
  
  return timeDiff;
}

/*
stock getWeekDay()
{
	decl String:sWeekday[3];

	FormatTime (sWeekday, sizeof (sWeekday), "%w");
	return StringToInt(sWeekday);
}
*/

stock e_SupportedMods:GetCurrentMod()
{
  new String:sGameType[64];
  GetGameFolderName(sGameType, sizeof(sGameType));
  
  if(StrEqual(sGameType, "tf", false))
  {
    return GameType_TF;
  }
  
  return GameType_Other;
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_CM_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
			ResetTimers();
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_CM_NotifyTime)
	{
		g_cvarNotifyTime = StringToInt(newValue);
	}
	else if(convar == Cvar_CM_Hour)
	{
		g_cvarHourSet = StringToInt(newValue);
	}
	else if(convar == Cvar_CM_Method)
	{
		g_cvarChangeMethod = StringToInt(newValue);
	}
}