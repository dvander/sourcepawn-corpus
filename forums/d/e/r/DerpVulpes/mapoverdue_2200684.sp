/*
 *	Map Overdue - forces stalemate or sudden death if the map runs for too long
 *  Code to force a stalemate taken from DarthNinja's [TF2] Force End Round plugin https://forums.alliedmods.net/showthread.php?p=1756067
 */
 
#include <sourcemod>
#include <sdktools>

#define __VERSION__ "1.0"
 
new Handle:overdueEnabled = INVALID_HANDLE;
new Handle:overdueTimer = INVALID_HANDLE;
new Handle:overdueWarning = INVALID_HANDLE;
new Handle:overdueStalemate = INVALID_HANDLE;
new String:roundOutput[14] = "stalemate";
new suddendeathTime = 240;

public Plugin:myinfo = 
{
	name = "OverdueCounter",
	author = "DerpVulpes",
	description = "Forces stalemate if the map is still running way after the timelimit",
	version = __VERSION__,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_mapoverdue_version", __VERSION__, "Map Overdue plugin version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	overdueEnabled = CreateConVar("sm_mapoverdue_enabled", "1", "Enable mapoverdue plugin", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	overdueWarning = CreateConVar("sm_mapoverdue_warning", "0", "After the timelimit when to start warning about the overdue. Negative value will trigger the warnings before timelimit", _, false);
	overdueStalemate = CreateConVar("sm_mapoverdue_stalemate", "5", "After the timelimit when to force the stalemate", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, false);
	HookConVarChange(FindConVar("mp_stalemate_timelimit"), OnStalemateTimeChange);
	HookConVarChange(FindConVar("mp_stalemate_enable"), OnRoundOutcomeChanged);
	HookConVarChange(overdueEnabled, OnOverduePluginEnabled);
	HookConVarChange(overdueStalemate, OnOverduePluginEnabled);
	HookConVarChange(overdueWarning, OnOverduePluginEnabled);
	
	suddendeathTime = GetConVarInt(FindConVar("mp_stalemate_timelimit")) + 1;
	if(GetConVarInt(FindConVar("mp_stalemate_enable")) == 1)
	{
		roundOutput = "sudden death";
	}
	else
	{
		roundOutput = "stalemate";
	}
	
	AutoExecConfig();

	ForceTimer();
}

public OnMapStart()
{
	PrecacheSound("vo/announcer_ends_1sec.wav");
	PrecacheSound("vo/announcer_ends_2sec.wav");
	PrecacheSound("vo/announcer_ends_3sec.wav");
	PrecacheSound("vo/announcer_ends_4sec.wav");
	PrecacheSound("vo/announcer_ends_5sec.wav");
	PrecacheSound("vo/announcer_ends_6sec.wav");
	PrecacheSound("vo/announcer_ends_7sec.wav");
	PrecacheSound("vo/announcer_ends_8sec.wav");
	PrecacheSound("vo/announcer_ends_9sec.wav");
	PrecacheSound("vo/announcer_ends_10sec.wav");
	PrecacheSound("vo/announcer_ends_20sec.wav");
	PrecacheSound("vo/announcer_ends_30sec.wav");
	PrecacheSound("vo/announcer_ends_60sec.wav");
	PrecacheSound("vo/announcer_ends_2min.wav");
	PrecacheSound("vo/announcer_ends_5min.wav");
}

public OnMapEnd()
{
	KillTimer(overdueTimer);
	overdueTimer = INVALID_HANDLE;
}

public OnStalemateTimeChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	suddendeathTime = StringToInt(newVal) + 1;
}

public OnRoundOutcomeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(StringToInt(newVal) == 1)
	{
		roundOutput = "sudden death";
	}
	else
	{
		roundOutput = "stalemate";
	}
}

public OnOverduePluginEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ForceTimer();
}

public OnMapTimeLeftChanged()
{
	ForceTimer();
}

public ForceTimer()
{
	if (overdueTimer != INVALID_HANDLE)
	{
		TriggerTimer(overdueTimer);
	}
	else
	{
		PrintToServer("OverdueTimer set to %d sec.", 1);
		overdueTimer = CreateTimer(1.0, checkMapTime);
	}
}

public Action:checkMapTime(Handle:timer)
{
	overdueTimer = INVALID_HANDLE;
	if (GetConVarBool(overdueEnabled) == false)
	{
		PrintToServer("OverdueTimer is disabled");
		return Plugin_Handled;
	}
	new overdueCount;
	new time;
	new timerDelay = 60;
	GetMapTimeLimit(time);
	if (time == 0)
	{
		PrintToServer("Timelimit not set for current map. OverdueTimer is disabled");
		return Plugin_Handled;
	}
	
	GetMapTimeLeft(time);
	PrintToServer("Timeleft for current map: %d sec", time);

	//overdueCount = RoundToFloor(float(-time) / 60.0);
	overdueCount = -time;
		
	
	if ((overdueCount) >= (GetConVarInt(overdueStalemate) * 60 + suddendeathTime))
	{
		if (GameRules_GetRoundState() == RoundState_RoundRunning)
		{
			PrintToServer("Slaying alive players to prevent an overtime");
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i))
				{
					ForcePlayerSuicide(i);
				}
			} 
		}
		else
		{
			PrintToServer("Game is outside the normal round mode. Waiting...");
		}
	}
	else if ((overdueCount) >= (GetConVarInt(overdueStalemate)) * 60)
	{
		if (GameRules_GetRoundState() == RoundState_RoundRunning)
		{
			PrintToServer("Forcing %s", roundOutput);
			PrintHintTextToAll("This map is an overdue!\nForcing %s NOW!", roundOutput);
			PrintCenterTextAll("Forcing %s NOW!", roundOutput);
			new iEnt = -1;
			iEnt = FindEntityByClassname(iEnt, "game_round_win");
			
			if (iEnt < 1)
			{
				iEnt = CreateEntityByName("game_round_win");
				if (IsValidEntity(iEnt))
					DispatchSpawn(iEnt);
				else
				{
					PrintToServer("ERROR: Can't force stalemate", roundOutput);
				}
			}

			SetVariantInt(0);
			AcceptEntityInput(iEnt, "SetTeam");
			AcceptEntityInput(iEnt, "RoundWin");
			
			timerDelay = suddendeathTime;
		}
		else
		{
			PrintToServer("Game is outside the normal round mode. Waiting...");
		}
	}
	else if ((overdueCount) >= GetConVarInt(overdueWarning) * 60)
	{
		if (GameRules_GetRoundState() == RoundState_RoundRunning)
		{
			new minLeft = RoundFloat(float(GetConVarInt(overdueStalemate) * 60 - overdueCount) / 60.0);
			if (minLeft <= 1)
			{
				new secLeft = time + GetConVarInt(overdueStalemate) * 60;
				PrintHintTextToAll("This map is an overdue!\nForcing %s in %d sec...", roundOutput, secLeft);
				PrintCenterTextAll("Forcing %s in %d sec...", roundOutput, secLeft);
				new String:path[35];
				new String:soundName[28];
				Format(soundName, sizeof(soundName), "vo/announcer_ends_%dsec.wav", secLeft);
				Format(path, sizeof(path), "sound/%s", soundName);
				if (FileExists(path, true) && IsSoundPrecached(soundName))
				{
					EmitSoundToAll(soundName);
				}
				timerDelay = 1;
			}
			else
			{
				PrintHintTextToAll("This map is an overdue! Forcing %s in %d minutes...", roundOutput, minLeft);
				PrintToServer("Forcing %s in %d minutes...", roundOutput, minLeft);
				new String:path[35];
				new String:soundName[28];
				Format(soundName, sizeof(soundName), "vo/announcer_ends_%dmin.wav", minLeft);
				Format(path, sizeof(path), "sound/%s", soundName);
				if (FileExists(path, true) && IsSoundPrecached(soundName))
				{
					EmitSoundToAll(soundName);
				}
				if (time > 0)
					timerDelay = time % 60;
				else
					timerDelay = 60 - (overdueCount % 60);
					
				if (timerDelay < 30)
				{
					timerDelay += 60;
				}
			}
		}
		else
		{
			PrintToServer("Game is outside the normal round mode. Waiting...");
		}
	}
	else
	{
		timerDelay = time + (GetConVarInt(overdueWarning) * 60);
	}
	
	PrintToServer("Overdue count %d", overdueCount);
		
	if (timerDelay <= 0)
	{
		timerDelay = 60;
	}
	PrintToServer("OverdueTimer set to %d seconds", timerDelay);
	overdueTimer = CreateTimer(float(timerDelay), checkMapTime);
	
	return Plugin_Handled
}
