#include<sourcemod>
#include<sdktools>
#include<tf2_stocks>

public Plugin:myinfo =
{
	name = "TF2 Anti-Intel Spam",
	author = "SleepKiller",
	description = "Stops players from being able to spam \"We have taken the enemy intelligence.\"",
	version = "1.0",
	url = ""
};

#define SOUND_TIMERID_1 66
#define SOUND_TIMERID_2 67

static Handle:g_hTimeOut;
static Handle:g_hTimeOutSound;

static g_iTimeOut = 3;
static g_iTimeOutSound = 3;

public OnPluginStart ()
{
	CreateConVar("antiintelspam_version", "1.0", "The version of TF2 Anti-Intel Spam.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hTimeOut = CreateConVar("antiintelspam_timeout", "3", 
	"The amount of time in seconds that a player must wait before the fact that they have picked up or dropped the intel will be rebroadcast to the other players.",
	FCVAR_PLUGIN,
	true,
	0.0);

	g_hTimeOutSound = CreateConVar("antiintelspam_soundtimeout", "3", 
	"The amount of time in seconds that the plugin will delay the announcer from, well announcing that the intel has been picked up or dropped.",
	FCVAR_PLUGIN,
	true,
	0.0);

	AutoExecConfig(true, "tf2anti-intelspam");
	
	g_iTimeOut = GetConVarInt(g_hTimeOut);
	g_iTimeOutSound = GetConVarInt(g_hTimeOutSound);
	
	HookEvent("teamplay_flag_event", Event_IntelPickedUp, EventHookMode_Pre);
	
	AddNormalSoundHook(SoundHook);

	HookConVarChange(g_hTimeOut, CVar_Timeout_Changed);
	HookConVarChange(g_hTimeOutSound, CVar_TimeoutSound_Changed);
}

public CVar_Timeout_Changed (Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iTimeOut = StringToInt(newVal);
}

public CVar_TimeoutSound_Changed (Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iTimeOutSound = StringToInt(newVal);
}

public OnClientDisconnect (client)
{
	CloseClientTimer(client);
}

public Action:Event_IntelPickedUp (Handle:event,  const String:name[], bool:dontBroadcast)
{
	//Fetch the client who triggered the event.
	new iClient = GetEventInt(event, "player");
	
	//Make sure the client is valid.
	if (! IsClientInGame(iClient))
	{
		return Plugin_Continue;
	}
	
	new iEventType = GetEventInt(event, "eventtype");

	//Make sure this is a pickup or drop event, otherwise we do nothing.
	if (iEventType != TF_FLAGEVENT_PICKEDUP || iEventType == TF_FLAGEVENT_DROPPED)
	{
		return Plugin_Continue;
	}
	
	//See if we've made a timer for this client yet.
	if (! GetClientTimerCreated(iClient))
	{
		CreateClientTimer(iClient);
		
		return Plugin_Continue;
	}

	//If we have made a timer for the client we should check it against the timeout time.
	if (GetClientTimerElapsedSeconds(iClient) < g_iTimeOut)
	{
		return Plugin_Handled;
	}
	else
	{
		//If the timeout period has indeed passed we simply reset the timer and return Plugin_Continue.
		ResetClientTimer(iClient);
		
		return Plugin_Continue;
	}
}

public Action:SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{

	if (StrContains(sample, "intel_enemydropped") != -1 ||
		StrContains(sample, "intel_enemystolen") != -1)
	{
		//See if we've made a timer for this yet.
		if (! GetClientTimerCreated(SOUND_TIMERID_1))
		{
			CreateClientTimer(SOUND_TIMERID_1);
		
			return Plugin_Continue;
		}

		
		if (GetClientTimerElapsedSeconds(SOUND_TIMERID_1) < g_iTimeOutSound)
		{
			return Plugin_Handled;
		}
		else
		{
			ResetClientTimer(SOUND_TIMERID_1);
		
			return Plugin_Continue;
		}
	}
	
	if (StrContains(sample, "intel_teamdropped") != -1 ||
		StrContains(sample, "intel_teamstolen") != -1)
	{
		//See if we've made a timer for this yet.
		if (! GetClientTimerCreated(SOUND_TIMERID_2))
		{
			CreateClientTimer(SOUND_TIMERID_2);
		
			return Plugin_Continue;
		}
		
		if (GetClientTimerElapsedSeconds(SOUND_TIMERID_2) < g_iTimeOutSound)
		{
			return Plugin_Handled;
		}
		else
		{
			ResetClientTimer(SOUND_TIMERID_2);
		
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}

//The +3 is so we can store the timers for the sounds in the array as well.
static g_Timers[MAXPLAYERS + 3];

CreateClientTimer (iClient)
{
	g_Timers[iClient] = GetTime();
}

CloseClientTimer (iClient)
{
	g_Timers[iClient] = 0;
}

//Okay you caught me, ResetClientTimer is exactly the same as CreateClientTimer. It just makes for clearer code in my opinion.
ResetClientTimer (iClient)
{
	g_Timers[iClient] = GetTime();
}

bool:GetClientTimerCreated (iClient)
{
	if (g_Timers[iClient] == 0)
	{
		return false;
	}
	else
	{
		return true;
	}
}

GetClientTimerElapsedSeconds (iClient)
{
	if (g_Timers[iClient] == 0)
	{
		ThrowError("Attempt to fetch time from non-existent timer.");
	}

	return GetTime() - g_Timers[iClient];
}