
#define L4DPLAYERS 32 //updated because larger servers are becoming common
#define PLUGIN_VERSION "1.4.3"
#define CVAR_FLAGS FCVAR_PLUGIN
#define TICKS 10

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "L4D Ledge Release",
	author = "AltPluzF4, maintained by Madcap",
	description = "Allow players who are hanging form a ledge to let go.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

new Buttons[L4DPLAYERS];
new Health[L4DPLAYERS];
new Float:HangTime[L4DPLAYERS];
new Handle:ClientTimer[L4DPLAYERS];
new bool:IgnoreCrouch[L4DPLAYERS];

new Handle:minHang;
new Handle:dropDmg;
new Handle:ledgeMsg;

public OnPluginStart()
{
	new x;
	for (x = 0; x < L4DPLAYERS; x++)
	{
		Buttons[x] = 0;
		Health[x] = 100;
		HangTime[x] = 0.0;
		ClientTimer[x] = INVALID_HANDLE;
		IgnoreCrouch[x] = false;
	}
	
	minHang  = CreateConVar("ledge_min_hang_time", "3.0", "Minimal time a player must hang from a ledge before dropping.", CVAR_FLAGS, true, 0.0);
	dropDmg  = CreateConVar("ledge_drop_damage",   "2", "Amount of damage given to player who drops from a ledge.", CVAR_FLAGS, true, 0.0);
	ledgeMsg = CreateConVar("ledge_message",       "If you'd like to let go of this ledge press your CROUCH key.", "Message displayed to players when they begin hanging form a ledge.", CVAR_FLAGS);
	
	AutoExecConfig(true, "sm_plugin_ledge_release");
	
	HookEvent("player_ledge_grab", EventGrabLedge);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Pre);
	
	new clients = GetClientCount(); //Reload mid-game support
	for (x = 1; x <= clients; x++)
	{
		if (IsValidEntity(x) && IsClientInGame(x))
		{
			new team = GetClientTeam(x);
			if (team == 2)
				ClientTimer[x] = CreateTimer(1.0/TICKS, PlayerTimer, x, TIMER_REPEAT);
		}
	}
}

public Action:EventRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for (new x = 0; x < L4DPLAYERS; x++)
	{
		if (ClientTimer[x] != INVALID_HANDLE)
		{
			CloseHandle(ClientTimer[x]);
			ClientTimer[x] = INVALID_HANDLE;
		}
		Buttons[x] = 0;
		Health[x] = 100;
		HangTime[x] = 0.0;
		IgnoreCrouch[x] = false;
	}
}

public Action:PlayerTimer(Handle:timer, any:client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client))
	{
		IgnoreCrouch[client] = false;
		ClientTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new buttons = GetClientButtons(client);
	new bIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	new bHang = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	if (bIncap && bHang)
	{
		if ((Buttons[client] & IN_DUCK) && !(buttons & IN_DUCK) && !IgnoreCrouch[client]) // Duck released, not ignoring
		{
			new rescuer = GetEntProp(client, Prop_Send, "m_reviveOwner");
			if (rescuer > 0)
			{
				PrintToChat(client, "You cannot let go while being rescued.");
			}
			else
			{
				if (HangTime[client] < GetGameTime())
					OnPlayerDrop(client);
				else
					PrintToChat(client, "You must hang for at least %.2f seconds before letting go.", GetConVarFloat(minHang));
			}	
		}
		else if ((Buttons[client] & IN_DUCK) && !(buttons & IN_DUCK) && IgnoreCrouch[client]) // Duck released, ignoring
		{
			IgnoreCrouch[client] = false;
		}
	}
	else if (!bIncap)
	{
		Health[client] = GetClientHealth(client);
		HangTime[client] = GetGameTime() + GetConVarFloat(minHang);
		if (buttons & IN_DUCK)
			IgnoreCrouch[client] = true; //If we are crouched before we begin to hang, ignore the first release
		else
			IgnoreCrouch[client] = false;
	}
	
	Buttons[client] = buttons;
	
	return Plugin_Continue;
}

public Action:EventPlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client < L4DPLAYERS)
	{
		if (ClientTimer[client] != INVALID_HANDLE)
		{
			CloseHandle(ClientTimer[client]);
			ClientTimer[client] = INVALID_HANDLE;
		}
		IgnoreCrouch[client] = false;
	}
}

public Action:EventPlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client < L4DPLAYERS)
	{
		new team = GetClientTeam(client);
		if (team == 2)
		{
			if (ClientTimer[client] != INVALID_HANDLE)
				CloseHandle(ClientTimer[client]);
			
			IgnoreCrouch[client] = false;
			ClientTimer[client] = CreateTimer(1.0/TICKS, PlayerTimer, client, TIMER_REPEAT);
		}
	}
}

public Action:EventGrabLedge(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:msg[256];
	GetConVarString(ledgeMsg, msg, sizeof(msg));
	if (client > 0 && client < L4DPLAYERS && strlen(msg) > 0)
	{
		PrintToChat(client, msg);
	}
}

OnPlayerDrop(client)
{
	new bHanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	new bIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	if (bHanging && bIncap)
	{
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
		if (Health[client]-GetConVarInt(dropDmg)>0)
			SetEntityHealth(client, Health[client] - GetConVarInt(dropDmg));
		else
			SetEntityHealth(client, 1);
		
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangTwoHands");
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangOneHand");
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFingers");
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangAboutToFall");
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFalling");
	}
}

