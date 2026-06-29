
#define L4DPLAYERS 32 //updated because larger servers are becoming common
#define PLUGIN_VERSION "1.4.3"
#define CVAR_FLAGS FCVAR_NONE
#define TICKS 10

#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "L4D Ledge Release",
	author = "AltPluzF4, maintained by Madcap",
	description = "Allow players who are hanging form a ledge to let go.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

int Buttons[L4DPLAYERS];
int Health[L4DPLAYERS];
float HangTime[L4DPLAYERS];
Handle ClientTimer[L4DPLAYERS];
bool IgnoreCrouch[L4DPLAYERS];

ConVar minHang;
ConVar dropDmg;
ConVar ledgeMsg;
ConVar playerConut;
ConVar ChatOrHint;

public void OnPluginStart()
{
	int x;
	for (x = 0; x < L4DPLAYERS; x++)
	{
		Buttons[x] = 0;
		Health[x] = 100;
		HangTime[x] = 0.0;
		ClientTimer[x] = null;
		IgnoreCrouch[x] = false;
	}
	
	minHang  = CreateConVar("ledge_min_hang_time", "3.0", "Minimal time a player must hang from a ledge before dropping.", 0, true, 0.0);
	dropDmg  = CreateConVar("ledge_drop_damage",   "2", "Amount of damage given to player who drops from a ledge.", CVAR_FLAGS, true, 0.0);
	ledgeMsg = CreateConVar("ledge_message",       "If you'd like to let go of this ledge press your CROUCH key.", "Message displayed to players when they begin hanging form a ledge.");
	playerConut  = CreateConVar("player_conut",   "1", "0:disable the check of server player number, 1:enable it", 0, true, 0.0, true, 1.0);
	ChatOrHint = CreateConVar("AdvertChatOrHint", "1", "Advert chat or hint text [1 = Chat | 0 = Hint Text]", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sm_plugin_ledge_release");
	
	HookEvent("player_ledge_grab", EventGrabLedge);
	HookEvent("revive_success", EventReviveSuccess);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Pre);
	
	int clients = GetClientCount(); //Reload mid-game support
	for (x = 1; x <= clients; x++)
	{
		if (IsValidEntity(x) && IsClientInGame(x))
		{
			int team = GetClientTeam(x);
			if (team == 2)
				ClientTimer[x] = CreateTimer(1.0/TICKS, PlayerTimer, x, TIMER_REPEAT);
		}
	}
}

public Action EventRoundEnd(Event event, char[] event_name, bool dontBroadcast)
{
	for (int x = 0; x < L4DPLAYERS; x++)
	{
		if (ClientTimer[x] != null)
		{
			CloseHandle(ClientTimer[x]);
			ClientTimer[x] = null;
		}
		Buttons[x] = 0;
		Health[x] = 100;
		HangTime[x] = 0.0;
		IgnoreCrouch[x] = false;
	}
}

public Action PlayerTimer(Handle timer, any client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client))
	{
		IgnoreCrouch[client] = false;
		ClientTimer[client] = null;
		return Plugin_Stop;
	}
	
	int buttons = GetClientButtons(client);
	int bIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	int bHang = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	if (bIncap && bHang)
	{
		if ((Buttons[client] & IN_DUCK) && !(buttons & IN_DUCK) && !IgnoreCrouch[client]) // Duck released, not ignoring
		{
			int rescuer = GetEntProp(client, Prop_Send, "m_reviveOwner");
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

public Action EventReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangTwoHands");
    FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangOneHand");
    FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFingers");
    FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangAboutToFall");
    FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFalling");
}

public Action EventPlayerDeath(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
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

public Action EventPlayerSpawn(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client < L4DPLAYERS)
	{
		int team = GetClientTeam(client);
		if (team == 2)
		{
			if (ClientTimer[client] != INVALID_HANDLE)
				CloseHandle(ClientTimer[client]);
			
			IgnoreCrouch[client] = false;
			ClientTimer[client] = CreateTimer(1.0/TICKS, PlayerTimer, client, TIMER_REPEAT);
		}
	}
}

public Action EventGrabLedge(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char msg[256];
	GetConVarString(ledgeMsg, msg, sizeof(msg));
	if (client > 0 && client < L4DPLAYERS && strlen(msg) > 0)
	{
		if(GetConVarInt(ChatOrHint) == 1)
		{
			PrintToChat(client, msg);
		}
		else
		{
			PrintHintText(client, msg);
		}
	}
}

void OnPlayerDrop(int client)
{
	int bHanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	int bIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	int iTotalSurvivors = TotalSurvivors();
	if (bHanging && bIncap)
	{
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
		if (Health[client]-GetConVarInt(dropDmg)>0)
			SetEntityHealth(client, Health[client] - GetConVarInt(dropDmg));
		else
			SetEntityHealth(client, 1);

		switch(GetConVarInt(playerConut))
		{
			case 0:
			{
				ChangeClientTeam(client, 0);
			}
			case 1:
			{
				if(iTotalSurvivors >= 2)
					ChangeClientTeam(client, 0);
			}
		}
	}
}

stock int TotalSurvivors() //only the total players
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
				count++;
		}
	}
	return count;
}
