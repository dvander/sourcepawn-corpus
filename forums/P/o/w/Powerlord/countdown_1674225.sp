#pragma semicolon 1

#include <sourcemod>
#include <sdktools_sound>

#define SOUND_60 "vo/announcer_dec_missionbegins60s06.wav"
#define SOUND_30 "vo/announcer_dec_missionbegins30s01.wav"
#define SOUND_10 "vo/announcer_dec_missionbegins10s01.wav"
#define SOUND_5 "vo/announcer_begins_5sec.wav"
#define SOUND_4 "vo/announcer_begins_4sec.wav"
#define SOUND_3 "vo/announcer_begins_3sec.wav"
#define SOUND_2 "vo/announcer_begins_2sec.wav"
#define SOUND_1 "vo/announcer_begins_1sec.wav"

#define SOUND_END "common/warning.wav"

#define VERSION "1.0"

new bool:g_bIsTF2 = false;
new Handle:g_currentCounter = INVALID_HANDLE;

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_Time = INVALID_HANDLE;
new Handle:g_Cvar_Location = INVALID_HANDLE;
new Handle:g_Cvar_Speak = INVALID_HANDLE;

// Chat isn't currently supported for this plugin
enum TimerLocation
{
	TimerLocation_Hint = 0,
	TimerLocation_Center = 1,
	TimerLocation_Chat = 2,
}

public Plugin:myinfo = 
{
	name = "Countdown",
	author = "Powerlord",
	description = "Countdown from a user-specified value to 0 when a command is issued.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=180890"
}

public OnPluginStart()
{
	decl String:game[64];
	GetGameFolderName(game, sizeof(game));
	
	g_bIsTF2 = StrEqual(game, "tf");
	
	CreateConVar("countdown_version", VERSION, "Countdown version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("countdown_enabled", "1", "Enable Countdown plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_Time = CreateConVar("countdown_time", "5", "Seconds to count down when command is issued", FCVAR_NONE, true, 5.0, true, 60.0);
	g_Cvar_Location = CreateConVar("countdown_location", "0", "Location for the timer text. 0 is HintBox, 1 is Center text.  Defaults to HintBox.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_Speak = CreateConVar("countdown_speak", "1", "If game is TF2, have the Announcer count down.", FCVAR_NONE, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_start", StartCmd, "Start a countdown");
	RegConsoleCmd("sm_stop", StopCmd, "Stop a countdown");
	
	AutoExecConfig(true, "countdown");
}

public OnMapStart()
{
	if (g_bIsTF2)
	{
		PrecacheSound(SOUND_60);
		PrecacheSound(SOUND_30);
		PrecacheSound(SOUND_10);
		PrecacheSound(SOUND_5);
		PrecacheSound(SOUND_4);
		PrecacheSound(SOUND_3);
		PrecacheSound(SOUND_2);
		PrecacheSound(SOUND_1);
	}
	g_currentCounter = INVALID_HANDLE;
}

public Action:StartCmd(client, args)
{
	if (!g_Cvar_Enabled)
	{
		return Plugin_Continue;
	}
	
	if (g_currentCounter != INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	
	g_currentCounter = CreateTimer(1.0, CountdownTimer, GetConVarInt(g_Cvar_Time), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public Action:StopCmd(client, args)
{
	if (g_currentCounter != INVALID_HANDLE)
	{
		// Prevent race conditions
		new Handle:timer = g_currentCounter;
		g_currentCounter = INVALID_HANDLE;
		KillTimer(timer);
	}
	return Plugin_Handled;	
}

public Action:CountdownTimer(Handle:timer, any:timerMaxTime)
{
	static timePassed;
	
	new timeRemaining = timerMaxTime - timePassed;


	new TimerLocation:timerLocation = TimerLocation:GetConVarInt(g_Cvar_Location);
	switch (timerLocation)
	{
		case TimerLocation_Hint:
		{
			PrintHintTextToAll("%d", timeRemaining);
		}
		
		case TimerLocation_Center:
		{
			PrintCenterTextAll("%d", timeRemaining);
		}
	}
	
	if (g_bIsTF2 && GetConVarBool(g_Cvar_Speak))
	{
		switch(timeRemaining)
		{
			case 1:
			{
				EmitSoundToAll(SOUND_1);
			}

			case 2:
			{
				EmitSoundToAll(SOUND_2);
			}
			
			case 3:
			{
				EmitSoundToAll(SOUND_3);
			}
			
			case 4:
			{
				EmitSoundToAll(SOUND_4);
			}
			
			case 5:
			{
				EmitSoundToAll(SOUND_5);
			}
			
			case 10:
			{
				EmitSoundToAll(SOUND_10);
			}
			
			case 30:
			{
				EmitSoundToAll(SOUND_30);
			}
			
			case 60:
			{
				EmitSoundToAll(SOUND_60);
			}
		}
	}
	
	if (timePassed++ >= timerMaxTime)
	{
		g_currentCounter = INVALID_HANDLE;

		timePassed = 0;
		
		if (g_bIsTF2)
		{
			EmitSoundToAll(SOUND_END);
		}
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
