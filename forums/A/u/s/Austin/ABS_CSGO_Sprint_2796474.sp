#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required
/******************************************************************************************************
	Description
		A Sprint command for CSGO with optional slowdown, cooldown and feedback messages and sounds.

	Feature list
		Implements a speed boost for a configurable amount of time.
		Optional slowdown time after the speed boots is used
		Configurable cooldown time
		Optional feedback messages
		Optional feedback sounds

	CVAR/Commands
		sm_abs_sprint
			The command to bind to a key to activate sprint.
			For example in the console type
			bind "q" "sm_abs_sprint"
			Use whatever free key you have or want for sprint instead of the "q" key in this example

		sm_abs_sprint_enabled
			Sprint Enabled = 1 or Disabled = 0

		sm_abs_sprint_duration
			Time in seconds speed boost will last
			Default = 6

		sm_abs_sprint_speed
			Speed boost amount
			Default = 1.50 times as fast

		sm_abs_sprint_slowdown_enabled;
			Sprint Slowdown Enabled = 1 or Disabled = 0
			When enabled player speed is slower than normal for a period of time after using sprint

		sm_abs_sprint_slowdown_duration;
			Time in seconds slowdown will last
			Default = 8
			If slowdown is enabled then the the time you have to wait before using sprint agin is:
			sm_abs_sprint_slowdown_duration +  sm_abs_sprint_cooldown_duration

		sm_abs_sprint_slowdown_speed;
			Speed slowdown amount
			Default = 0.75 times as fast

		sm_abs_sprint_cooldown_duration
			Time in seconds to wait before using the speed boost again
			Default = 30

		sm_abs_sprint_showMessages
			Sprint Messages Enabled = 1 or Disabled = 0
			Colored messages will be shown for Sprint/Slowdown/Cooldown - Start/End

		sm_abs_sprint_playSounds
			Sprint Sounds Enabled = 1 or Disabled = 0
			Sounds will be Played for Sprint/Slowdown/Cooldown - Start/End

		sm_abs_sprint_soundVolume
			Sprint Sounds Volume 0 to 50
			Default = 30
			Sets how loud the sounds will be

	Installation instructions
		Click the get plugin link below
		Put the ABS_CSGO_Sprint.smx file into your SourceMod plugins folder.

	Plans
		I implemented about everything I could think of for this but will consider
		adding "good" new ideas for it.
		The plugin is well tested but will fix any bugs if found.

	Credits
		The scripting techniques in this plugin came from the CSS version.
		Credit goes to St00ne / (and bacardi Of Course!)
		https://forums.alliedmods.net/showthread.php?t=209935&highlight=sprint
		Thank You!

	Changes from the original CSS version.
		1)	Bug fix. At least for running under CSGO the original CSS plugin would crash if there was a
				map change while one of the timers were running, either in sprint or in cooldown timer.

		2)	Enabling sprint with the use key has been removed since most of
				the time you don't want to also enable sprint with use.

		3)	Added an optional slowdown feature where you move slower for a period of time after using sprint.

		4)	Added features to optionally show messages and play sounds for the sprint states of
				Sprint/Slowdown/Cooldown - Start/End
				
	Changelog
		2023-01-04			
				v1.0 Released
				v1.1 Released - Updated to newdecls required

tabs = 2 spaces for this source code
******************************************************************************************************/

#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name				= "Sprint For CSGO",
	author			= "Austin",
	description	= "Implements a sprint command for CSGO.",
	version			= PLUGIN_VERSION,
	url					= "https://forums.alliedmods.net/showthread.php?p=2796474#post2796474"
};

Handle h_timers[MAXPLAYERS+1];

ConVar	abs_sprint_enabled;
ConVar	abs_sprint_duration;
ConVar	abs_sprint_speed;
ConVar	abs_sprint_cooldown_duration;

ConVar	abs_sprint_slowdown_enabled;
ConVar	abs_sprint_slowdown_duration;
ConVar	abs_sprint_slowdown_speed;

ConVar	abs_sprint_showMessages;
ConVar	abs_sprint_playSounds;
ConVar	abs_sprint_soundVolume;

char sprintStart[50]				= "buttons/blip1.wav";
char sprintEnd[50]					= "buttons/blip1.wav";
char sprintInCoolDown[50]		= "buttons/weapon_cant_buy.wav";
char sprintCoolDownEnd[50]	= "buttons/bell1.wav";

char message[MAXPLAYERS+1][100];

//-----------------------------------------------------------------------------
//	OnPluginStart()
//-----------------------------------------------------------------------------
public void OnPluginStart()
{
	RegConsoleCmd("sm_abs_sprint", CmdStartSprint);

	abs_sprint_enabled						= CreateConVar("sm_abs_sprint_enabled",						"1",		"Sprint Enabled/Disabled 1/0",									FCVAR_NONE, true, 0.0);
	abs_sprint_duration						= CreateConVar("sm_abs_sprint_duration",					"6",		"Sprint Duration in seconds. Default = 7",			FCVAR_NONE, true, 0.0);
	abs_sprint_speed							= CreateConVar("sm_abs_sprint_speed",							"1.5",	"Sprint Speed ratio. Default = 1.5",						FCVAR_NONE, true, 0.0);
	abs_sprint_cooldown_duration	= CreateConVar("sm_abs_sprint_cooldown_duration",	"30",		"Sprint Cooldown time in seconds. Default= 35",	FCVAR_NONE, true, 0.0);

	abs_sprint_slowdown_enabled		= CreateConVar("sm_abs_sprint_slowdown_enabled",	"1",		"Sprint Slowdown Enabled/Disabled 1/0",							FCVAR_NONE, true, 0.0);
	abs_sprint_slowdown_duration	= CreateConVar("sm_abs_sprint_slowdown_duration",	"8",		"Sprint Slowdown Duration in seconds. Default = 5",	FCVAR_NONE, true, 0.0);
	abs_sprint_slowdown_speed			= CreateConVar("sm_abs_sprint_slowdown_speed",		"0.75",	"Sprint Slowdown Speed ratio. Default = 0.75",			FCVAR_NONE, true, 0.0);

	abs_sprint_showMessages	= CreateConVar("sm_abs_sprint_showMessages",	"1",		"Sprint Messages Enabled/Disabled 1/0",			FCVAR_NONE, true, 0.0);
	abs_sprint_playSounds		= CreateConVar("sm_abs_sprint_playSounds",		"1",		"Sprint Sounds Enabled/Disabled 1/0",				FCVAR_NONE, true, 0.0);
	abs_sprint_soundVolume	= CreateConVar("sm_abs_sprint_soundVolume",		"30",		"Sprint Sounds Volume 0 to 50. Default 30",	FCVAR_NONE, true, 0.0, true, 50.0);

	HookEventEx("player_spawn",	player_spawn);
	HookEventEx("player_team",	player_team);
	HookEventEx("player_death",	player_death);
	HookEventEx("round_end",Event_RoundEnd,EventHookMode_Post);
	
	if(abs_sprint_showMessages.BoolValue)
	{
		PrintToServer("ABS_CSGO_Sprint Loaded");
		PrintToChatAll("ABS_CSGO_Sprint Loaded");
	}
}

//-----------------------------------------------------------------------------
//	OnMapStart()
//	Cache the sounds we are going to be using
//-----------------------------------------------------------------------------
public void OnMapStart()
{
	PrecacheSound(sprintStart);
	PrecacheSound(sprintEnd);
	PrecacheSound(sprintInCoolDown);
	PrecacheSound(sprintCoolDownEnd);
}

//-----------------------------------------------------------------------------
//	Cmd_StartSprint()
//	Handle the Start Sprint command
//-----------------------------------------------------------------------------
public Action CmdStartSprint(int client, int args)
{
	// ignore sprint command if plugin is disabled or invalid client
	if(!abs_sprint_enabled.BoolValue || client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client) || IsClientReplay(client) || IsClientSourceTV(client))
		return Plugin_Handled;

	// ignore sprint command if we are still in the cooldown or slowdown period
	if(h_timers[client] != INVALID_HANDLE)
	{
		GiveFeedback(client, message[client], sprintInCoolDown);
		return Plugin_Handled;
	}

	// we are not in cooldown or slowdown, boost speed and set a timer to end it
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", abs_sprint_speed.FloatValue);
	h_timers[client] = CreateTimer(abs_sprint_duration.FloatValue, SprintEnded, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	message[client] = "\x10Sprint \x02Still in Sprint";
	GiveFeedback(client,"\x10Sprint \x04Start", sprintStart);

	return Plugin_Handled;
}

//-----------------------------------------------------------------------------
//	SprintEnded()
//	Handle the end of the sprint time
//-----------------------------------------------------------------------------
public Action SprintEnded(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	h_timers[client] = INVALID_HANDLE;
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		// reset the player's speed back to normal
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);

		if(abs_sprint_slowdown_enabled.BoolValue)
		{
			// slowdown is enabled so set the slowdown speed and a timer to end it
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", abs_sprint_slowdown_speed.FloatValue);
			h_timers[client] = CreateTimer(abs_sprint_slowdown_duration.FloatValue, SprintSlowdownEnded, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
			message[client] = "\x10Sprint \x02Still in Slowdown";
			GiveFeedback(client,"\x10Sprint \x04Slowdown Start", sprintStart);
		}
		// start the cooldown time
		else
		{
			h_timers[client] = CreateTimer(abs_sprint_cooldown_duration.FloatValue, SprintCooldownEnded, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
			message[client] = "\x10Sprint \x02Still in Cooldown";
			GiveFeedback(client,"\x10Sprint \x02End", sprintEnd);
		}
	}
}

//-----------------------------------------------------------------------------
//	SprintSlowdownEnded()
//	Handle the end of the sprint slowdown time
//-----------------------------------------------------------------------------
public Action SprintSlowdownEnded(Handle timer, any serial)
{
	// the slowdown time has ended, set speed back to default and set the cooldown timer
	int client = GetClientFromSerial(serial);
	h_timers[client] = INVALID_HANDLE;
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		// reset the player's speed back to normal
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		// start the cooldown timer
		h_timers[client] = CreateTimer(abs_sprint_cooldown_duration.FloatValue, SprintCooldownEnded, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		message[client] = "\x10Sprint \x02Still in Cooldown";
		GiveFeedback(client,"\x10Sprint \x0CSlow Down Over", sprintCoolDownEnd);
	}
}

//-----------------------------------------------------------------------------
//	SprintCooldownEnded()
//	Handle the end of the sprint cooldown time
//-----------------------------------------------------------------------------
public Action SprintCooldownEnded(Handle timer, any serial)
{
	// the cooldown time has ended, let the user know they can use sprint again
	int client = GetClientFromSerial(serial);
	h_timers[client] = INVALID_HANDLE;
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
		if(IsPlayerAlive(client))
			GiveFeedback(client,"\x10Sprint \x0CCool Down Over", sprintCoolDownEnd);
}

//-----------------------------------------------------------------------------
//	GiveFeedback()
//-----------------------------------------------------------------------------
public void GiveFeedback(int client, char[] msg, char[] snd)
{
	if(abs_sprint_showMessages.BoolValue)
		PrintToChat(client,msg);
	if(abs_sprint_playSounds.BoolValue)
		EmitSoundToClient(client, snd, SOUND_FROM_PLAYER, SNDCHAN_AUTO, abs_sprint_soundVolume.IntValue, SND_CHANGEVOL, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

//-----------------------------------------------------------------------------
//	We have to reset any timers that may be running when any of these things
//	happen to a player otherwise we will get a timer handle error
//	and the plugin will crash and stop working until it is reloaded again
//	and we have to also reset the players speed back to normal
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	ResetTimers(client);
}

//-----------------------------------------------------------------------------
public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	ResetTimers(client);
}

//-----------------------------------------------------------------------------
public void player_team(Event event, const char[] name, bool dontBroadcast)
{
	int  client = GetClientOfUserId(GetEventInt(event, "userid"));
	ResetTimers(client);
}

//-----------------------------------------------------------------------------
public void OnClientDisconnect(int client)
{
	ResetTimers(client);
}

//-----------------------------------------------------------------------------
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i<= MaxClients;i++)
		ResetTimers(i);
}

//-----------------------------------------------------------------------------
//	ResetTimers()
//-----------------------------------------------------------------------------
public void ResetTimers(int client)
{
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		message[client] = "";
		// reset any running timers to avoid a plugin crash
		if(h_timers[client] != INVALID_HANDLE)
		{
			// Rest the players speed back to normal
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
			KillTimer(h_timers[client]);
			h_timers[client] = INVALID_HANDLE;
		}
	}
}
