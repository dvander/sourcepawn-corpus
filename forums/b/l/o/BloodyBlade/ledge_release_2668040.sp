#define PLUGIN_VERSION "1.4.3"
#define CVAR_FLAGS FCVAR_NOTIFY
#define TICKS 10

#pragma semicolon 1
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

int Buttons[MAXPLAYERS + 1] = {0, ...}, Health[MAXPLAYERS + 1] = {0, ...}, iDropDmg = 0, iPlayerConut = 0;
float HangTime[MAXPLAYERS + 1] = {0.0, ...}, fMinHang = 0.0;
Handle ClientTimer[MAXPLAYERS + 1] = {null, ...};
bool IgnoreCrouch[MAXPLAYERS + 1] = {false, ...}, bHooked = false, bChatOrHint = false;
ConVar LedgePluginOn, minHang, dropDmg, ledgeMsg, playerConut, ChatOrHint;
char Msg[256];

public void OnPluginStart()
{
	int x;
	for (x = 0; x <= MaxClients; x++)
	{
		Buttons[x] = 0;
		Health[x] = 100;
		HangTime[x] = 0.0;
		ClientTimer[x] = null;
		IgnoreCrouch[x] = false;
	}

	LedgePluginOn = CreateConVar("player_conut",   "1", "Plugin On/Off", CVAR_FLAGS, true, 0.0, true, 1.0);
	minHang  = CreateConVar("ledge_min_hang_time", "3.0", "Minimal time a player must hang from a ledge before dropping.", CVAR_FLAGS, true, 0.0, true, 60.0);
	dropDmg  = CreateConVar("ledge_drop_damage",   "2", "Amount of damage given to player who drops from a ledge.", CVAR_FLAGS, true, 0.0, true, 350.0);
	ledgeMsg = CreateConVar("ledge_message",       "If you'd like to let go of this ledge press your CROUCH key.", "Message displayed to players when they begin hanging form a ledge.", CVAR_FLAGS);
	playerConut  = CreateConVar("player_conut",   "1", "0:disable the check of server player number, 1:enable it", CVAR_FLAGS, true, 0.0, true, 1.0);
	ChatOrHint = CreateConVar("AdvertChatOrHint", "1", "Advert chat or hint text [1 = Chat | 0 = Hint Text]", CVAR_FLAGS, true, 0.0, true, 1.0);

	LedgePluginOn.AddChangeHook(ConVarPluginOnChanged);
	minHang.AddChangeHook(ConVarsChanged);
	dropDmg.AddChangeHook(ConVarsChanged);
	ledgeMsg.AddChangeHook(ConVarsChanged);
	playerConut.AddChangeHook(ConVarsChanged);
	ChatOrHint.AddChangeHook(ConVarsChanged);

	AutoExecConfig(true, "sm_plugin_ledge_release");

	for (x = 1; x <= GetClientCount(); x++)
	{
		if (IsValidEntity(x) && IsClientInGame(x) && GetClientTeam(x) == 2)
		{
				ClientTimer[x] = CreateTimer(1.0 / TICKS, PlayerTimer, x, TIMER_REPEAT);
		}
	}
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    GetCvars();
}

void IsAllowed()
{
    bool bPluginOn = LedgePluginOn.BoolValue;
    if(bPluginOn && !bHooked)
    {
    	bHooked = true;
    	GetCvars();
    	HookEvent("player_ledge_grab", EventGrabLedge);
    	HookEvent("revive_success", EventReviveSuccess);
    	HookEvent("player_spawn", EventPlayerSpawn);
    	HookEvent("player_death", EventPlayerDeath);
    	HookEvent("round_end", EventRoundEnd, EventHookMode_Pre);
    }
    else if(!bPluginOn && bHooked)
    {
        bHooked = false;
        UnhookEvent("player_ledge_grab", EventGrabLedge);
        UnhookEvent("revive_success", EventReviveSuccess);
        UnhookEvent("player_spawn", EventPlayerSpawn);
        UnhookEvent("player_death", EventPlayerDeath);
        UnhookEvent("round_end", EventRoundEnd, EventHookMode_Pre);
    	for (int x = 0; x <= MaxClients; x++)
    	{
    		if(IsClientInGame(x))
    		{
    			if (ClientTimer[x] != null)
    			{
    				delete ClientTimer[x];
    			}
    			Buttons[x] = 0;
    			Health[x] = 100;
    			HangTime[x] = 0.0;
    			IgnoreCrouch[x] = false;
    		}
    	}
    }
}

void GetCvars()
{
    fMinHang = minHang.FloatValue;
    bChatOrHint = ChatOrHint.BoolValue;
    iDropDmg = dropDmg.IntValue;
    iPlayerConut = playerConut.IntValue;
    ledgeMsg.GetString(Msg, sizeof(Msg));
}

Action EventRoundEnd(Event event, char[] event_name, bool dontBroadcast)
{
	for (int x = 0; x <= MaxClients; x++)
	{
		if(IsClientInGame(x))
		{
			if (ClientTimer[x] != null)
			{
				delete ClientTimer[x];
			}
			Buttons[x] = 0;
			Health[x] = 100;
			HangTime[x] = 0.0;
			IgnoreCrouch[x] = false;
		}
	}
}

Action PlayerTimer(Handle timer, any client)
{
	if (!IsSurvivor(client))
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
					PrintToChat(client, "You must hang for at least %.2f seconds before letting go.", fMinHang);
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
		HangTime[client] = GetGameTime() + fMinHang;
		if (buttons & IN_DUCK)
			IgnoreCrouch[client] = true; //If we are crouched before we begin to hang, ignore the first release
		else
			IgnoreCrouch[client] = false;
	}

	Buttons[client] = buttons;

	return Plugin_Continue;
}

Action EventReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsSurvivor(client))
    {
    	FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangTwoHands");
    	FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangOneHand");
    	FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFingers");
    	FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangAboutToFall");
    	FakeClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFalling");
    }
    return Plugin_Continue;
}

Action EventPlayerDeath(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsSurvivor(client))
	{
		if (ClientTimer[client] != null)
		{
			delete ClientTimer[client];
		}
		IgnoreCrouch[client] = false;
	}
	return Plugin_Continue;
}

Action EventPlayerSpawn(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsSurvivor(client))
	{
		if (ClientTimer[client] != null)
		{
			delete ClientTimer[client];
		}
		IgnoreCrouch[client] = false;
		ClientTimer[client] = CreateTimer(1.0 / TICKS, PlayerTimer, client, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

Action EventGrabLedge(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsSurvivor(client) && strlen(Msg) > 0)
	{
		if(bChatOrHint)
		{
			PrintToChat(client, Msg);
		}
		else
		{
			PrintHintText(client, Msg);
		}
	}
	return Plugin_Continue;
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
		if ((Health[client] - iDropDmg) > 0)
			SetEntityHealth(client, Health[client] - iDropDmg);
		else
			SetEntityHealth(client, 1);

		switch(iPlayerConut)
		{
			case 0:
			{
				ChangeClientTeam(client, 0);
			}
			case 1:
			{
				if(iTotalSurvivors >= 2)
				{
					ChangeClientTeam(client, 0);
				}
			}
		}
	}
}

bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock int TotalSurvivors() //only the total players
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
			{
				count++;
			}
		}
	}
	return count;
}
