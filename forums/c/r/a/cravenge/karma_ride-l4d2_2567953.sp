/*
 * [L4D2] Karma Ride plugin. A SourceMod plugin for Left 4 Dead 2.
 *	===========================================================================
 *	Copyright (C) 2018-2019 John Mark "cravenge" Moreno.  All rights reserved.
 *	===========================================================================
 *	
 *	The source code in this file is originally made by me, inspired by
 *	AtomicStryker's [L4D2] Karma Charge plugin.
 *	
 *	I strictly prohibit the unauthorized tweaking/modification, and/or
 *	redistribution of this plugin under the same and/or different names
 *	but there are exceptions.
 *
 *	If you have any suggestions on improving the plugin's functionality,
 *	please do not hesitate to send a private message to my AlliedModders
 *	profile. For feedbacks/improvements, you can either post them in the
 *	thread or notify me through PM.
 *
 *	------------------------------- Changelog ---------------------------------
 *	Version 1.2 (August 6, 2019)
 *	+ Code optimization.
 *	+ Made it so that the ledge blocker will not work if [L4D2] Jockey
 *    jump plugin regardless of the convar being enabled.
 *
 *	Version 1.1 (December 25, 2017)
 *	+ Check for [L4D2] Jockey jump plugin if installed in order for the
 *	  karma to register properly.
 *
 *	Version 1.0 (December 24, 2017)
 *
 *	X Initial release.
 *	? Add check for false detections like the bugs in [L4D2] Karma Charge
 *	  plugin by AtomicStryker.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

ConVar krEnable, krNoLedgeHang, krHeightCheck, krSlowMoDuration, krSlowMoType, cvarJockeyJump;
int iSlowMoType;
bool bEnabled, bNoLedgeHang, bIsRiding[MAXPLAYERS+1];
float fHeightCheck, fSlowMoDuration;
Handle hKRTime[MAXPLAYERS+1] = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evRetVal = GetEngineVersion();
	if (evRetVal == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	
	strcopy(error, err_max, "[KR] Plugin Supports L4D2 Only!");
	return APLRes_SilentFailure;
}

#define JJP_CONVAR FindConVar("l4d2_jockeyjump_version")

public Plugin myinfo =
{
	name = "[L4D2] Karma Ride",
	author = "cravenge",
	description = "Show Players That Jockeys Aren't To Be Underestimated.",
	version = "1.2",
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	CreateConVar("karma_ride-l4d2_version", "1.2", "Karma Ride Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	krEnable = CreateConVar("karma_ride-l4d2_enable", "1", "Enable/Disable Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	krNoLedgeHang = CreateConVar("karma_ride-l4d2_no_ledge_hang", "1", "Enable/Disable No Ledge Hang During Jockey Rides", FCVAR_NOTIFY|FCVAR_SPONLY);
	krHeightCheck = CreateConVar("karma_ride-l4d2_height_check", "425.0", "Fall Height To Check And Consider As Karma Ride", FCVAR_NOTIFY|FCVAR_SPONLY);
	krSlowMoDuration = CreateConVar("karma_ride-l4d2_slowmo_duration", "5.0", "Duration Of Slow Motion During Karma Rides", FCVAR_NOTIFY|FCVAR_SPONLY);
	krSlowMoType = CreateConVar("karma_ride-l4d2_slowmo_type", "1", "Slow Motion Type: 0=Whole Server, 1=Just Jockey And Victim", FCVAR_NOTIFY|FCVAR_SPONLY);
	
	iSlowMoType = krSlowMoType.IntValue;
	
	bEnabled = krEnable.BoolValue;
	bNoLedgeHang = krNoLedgeHang.BoolValue;
	
	fHeightCheck = krHeightCheck.FloatValue;
	fSlowMoDuration = krSlowMoDuration.FloatValue;
	
	krEnable.AddChangeHook(OnKRCVarsChanged);
	krNoLedgeHang.AddChangeHook(OnKRCVarsChanged);
	krHeightCheck.AddChangeHook(OnKRCVarsChanged);
	krSlowMoDuration.AddChangeHook(OnKRCVarsChanged);
	krSlowMoType.AddChangeHook(OnKRCVarsChanged);
	
	AutoExecConfig(true, "karma_ride-l4d2");
	
	HookEvent("jockey_ride", OnJockeyRide);
	HookEvent("jockey_ride_end", OnJockeyRideEnd);
	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("finale_win", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
}

public void OnKRCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	iSlowMoType = krSlowMoType.IntValue;
	
	bEnabled = krEnable.BoolValue;
	bNoLedgeHang = krNoLedgeHang.BoolValue;
	
	fHeightCheck = krHeightCheck.FloatValue;
	fSlowMoDuration = krSlowMoDuration.FloatValue;
}

public void OnAllPluginsLoaded()
{
	cvarJockeyJump = JJP_CONVAR;
}

public void OnMapStart()
{
	if (!IsSoundPrecached("level/loud/climber.wav"))
	{
		PrecacheSound("level/loud/climber.wav", true);
	}
}

public void OnJockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int rider = GetClientOfUserId(event.GetInt("userid"));
	if (rider)
	{
		if (bIsRiding[rider])
		{
			return;
		}
		
		bIsRiding[rider] = true;
		
		if (bNoLedgeHang)
		{
			if (cvarJockeyJump != null)
			{
				return;
			}
			
			int ridden = GetClientOfUserId(event.GetInt("victim"));
			if (!IsSurvivor(ridden))
			{
				if (!IsPlayerAlive(ridden))
				{
					return;
				}
				
				AcceptEntityInput(ridden, "DisableLedgeHang");
			}
		}
	}
}

public void OnJockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	int rider = GetClientOfUserId(event.GetInt("userid"));
	if (rider)
	{
		if (!bIsRiding[rider])
		{
			return;
		}
		
		bIsRiding[rider] = false;
		
		if (bNoLedgeHang)
		{
			if (cvarJockeyJump != null)
			{
				return;
			}
			
			int ridden = GetClientOfUserId(event.GetInt("victim"));
			if (!IsSurvivor(ridden))
			{
				if (!IsPlayerAlive(ridden))
				{
					return;
				}
				AcceptEntityInput(ridden, "EnableLedgeHang");
			}
		}
	}
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (!bEnabled)
	{
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			bIsRiding[i] = false;
			
			if (hKRTime[i] != null)
			{
				KillTimer(hKRTime[i]);
				hKRTime[i] = null;
			}
		}
	}
}

public void OnMapEnd()
{
	if (!bEnabled)
	{
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			bIsRiding[i] = false;
			
			if (hKRTime[i] != null)
			{
				KillTimer(hKRTime[i]);
				hKRTime[i] = null;
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vec[3], float angles[3], int &weapon)
{
	if (!bEnabled || !IsJockey(client))
	{
		return Plugin_Continue;
	}
	
	if ((cvarJockeyJump == null) ? (bIsRiding[client] && (((buttons & IN_JUMP) && !IsFakeClient(client)) || IsFakeClient(client))) : bIsRiding[client])
	{
		int iJockeyVictim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
		if (!IsSurvivor(iJockeyVictim) || !IsPlayerAlive(iJockeyVictim) || !(GetEntProp(iJockeyVictim, Prop_Send, "m_fFlags") & FL_ONGROUND))
		{
			return Plugin_Continue;
		}
		
		if (hKRTime[client] != null)
		{
			KillTimer(hKRTime[client]);
			hKRTime[client] = null;
		}
		hKRTime[client] = CreateTimer(0.4, QualifyKarmaRide, GetClientUserId(client), TIMER_REPEAT);
	}
	
	return Plugin_Continue;
}

public Action QualifyKarmaRide(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsJockey(client) || !IsPlayerAlive(client))
	{
		if (hKRTime[client] != null)
		{
			KillTimer(hKRTime[client]);
			hKRTime[client] = null;
		}
		return Plugin_Stop;
	}
	
	if (hKRTime[client] == null)
	{
		return Plugin_Stop;
	}
	
	int iJockeyVictim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
	if (!IsSurvivor(iJockeyVictim) || !IsPlayerAlive(iJockeyVictim))
	{
		if (hKRTime[client] != null)
		{
			KillTimer(hKRTime[client]);
			hKRTime[client] = null;
		}
		return Plugin_Stop;
	}
	
	if (GetEntProp(iJockeyVictim, Prop_Send, "m_fFlags") & FL_ONGROUND)
	{
		return Plugin_Continue;
	}
	
	float fRideHeight = MeasureHeightDistance(iJockeyVictim);
	if (fRideHeight >= fHeightCheck)
	{
		EmitSoundToAll("level/loud/climber.wav", client);
		
		switch (iSlowMoType)
		{
			case 0:
			{
				int iTimeEnt = CreateEntityByName("func_timescale");
				
				DispatchKeyValue(iTimeEnt, "desiredTimescale", "0.2");
				DispatchKeyValue(iTimeEnt, "acceleration", "2.0");
				DispatchKeyValue(iTimeEnt, "minBlendRate", "1.0");
				DispatchKeyValue(iTimeEnt, "blendDeltaMultiplier", "2.0");
				
				DispatchSpawn(iTimeEnt);
				AcceptEntityInput(iTimeEnt, "Start");
				
				CreateTimer(fSlowMoDuration, RevertTime, iTimeEnt);
			}
			case 1:
			{
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.2);
				SetEntPropFloat(iJockeyVictim, Prop_Send, "m_flLaggedMovementValue", 0.2);
				
				DataPack dpKarmaRide = new DataPack();
				dpKarmaRide.WriteCell(GetClientUserId(client));
				dpKarmaRide.WriteCell(GetClientUserId(iJockeyVictim));
				CreateTimer(fSlowMoDuration, RevertSpeed, dpKarmaRide, TIMER_DATA_HNDL_CLOSE);
			}
		}
		
		PrintToChatAll("\x05[\x04KR\x05] \x03%N\x01 Karma Ridden \x03%N\x01!", client, iJockeyVictim);
		
		if (hKRTime[client] != null)
		{
			KillTimer(hKRTime[client]);
			hKRTime[client] = null;
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action RevertTime(Handle timer, any entity)
{
	if (!IsValidEdict(entity))
	{
		return Plugin_Stop;
	}
	
	AcceptEntityInput(entity, "Stop");
	AcceptEntityInput(entity, "Kill");
	RemoveEdict(entity);
	
	return Plugin_Stop;
}

public Action RevertSpeed(Handle timer, Handle dpKarmaRide)
{
	ResetPack(dpKarmaRide);
	
	int rider = GetClientOfUserId(ReadPackCell(dpKarmaRide));
	int ridden = GetClientOfUserId(ReadPackCell(dpKarmaRide));
	
	if (IsValidClient(rider))
	{
		SetEntPropFloat(rider, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}
	
	if (IsValidClient(ridden))
	{
		SetEntPropFloat(ridden, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}
	
	return Plugin_Stop;
}

float MeasureHeightDistance(int client)
{
	float fPos[3], fDirAngle[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
	fDirAngle[0] = 90.0; fDirAngle[1] = 0.0; fDirAngle[2] = 0.0;
	
	Handle hTrace = TR_TraceRayFilterEx(fPos, fDirAngle, MASK_SHOT, RayType_Infinite, NonEntityFilter);
	if (!TR_DidHit(hTrace))
	{
		delete hTrace;
		return 0.0;
	}
	
	float fTraceEnd[3];
	TR_GetEndPosition(fTraceEnd, hTrace);
	
	delete hTrace;
	return GetVectorDistance(fPos, fTraceEnd, false);
}

public bool NonEntityFilter(int entity, int contentsMask, any data)
{
	return (entity && IsValidEntity(entity));
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsSurvivor(int client)
{
	return (IsValidClient(client) && GetClientTeam(client) == 2);
}

stock bool IsJockey(int client)
{
	return (IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 5);
}

