
#define L4DPLAYERS 10 //0 invalid, 8 players + 1 for fun?
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_PLUGIN

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
new bool:BeingRescued[L4DPLAYERS];
new Handle:minHang;
new Handle:dropDmg;
new Handle:ledgeMsg;

public OnPluginStart()
{
	for (new x = 0; x < L4DPLAYERS; x++)
	{
		Buttons[x] = 0;
		Health[x] = 100;
		HangTime[x] = 0.0;
		BeingRescued[x] = false;
	}
	
	minHang  = CreateConVar("ledge_min_hang_time", "0.0", "Minimal time a player must hang from a ledge before dropping.", CVAR_FLAGS, true, 0.0);
	dropDmg  = CreateConVar("ledge_drop_damage",   "2", "Amount of damage given to player who drops from a ledge.", CVAR_FLAGS, true, 0.0);
	ledgeMsg = CreateConVar("ledge_message",       "If you'd like to let go of this ledge press your CROUCH key.", "", CVAR_FLAGS);
	
	AutoExecConfig(true, "sm_plugin_ledge_release");
	
	HookEvent("player_ledge_grab", EventGrabLedge);
	HookEvent("revive_begin", EventReviveBegin);
	HookEvent("revive_success", EventReviveEnd);
	HookEvent("revive_end", EventReviveEnd);
}

public Action:EventGrabLedge(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:msg[256];
	GetConVarString(ledgeMsg, msg, sizeof(msg));
	if (client > -1 && client < L4DPLAYERS && strlen(msg) > 0)
	{
		PrintToChat(client, msg);
	}
}

public Action:EventReviveBegin(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	new bHanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	new bIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	if (bHanging && bIncap)
		BeingRescued[client] = true;
}

public Action:EventReviveEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (BeingRescued[client]==true)
		BeingRescued[client] = false;
}

public OnGameFrame()
{
	for (new client = 1; client < L4DPLAYERS; client++)
	{
		if (IsValidEntity(client) &&  IsClientInGame(client))
		{
			new b = GetClientButtons(client);
			new bIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
			if (bIncap)
			{
				new bHang = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
				if (bHang && (Buttons[client] & IN_DUCK) && !(b & IN_DUCK)) // Duck was pressed last frame but not this frame
				{
					if (BeingRescued[client])
					{
						PrintToChat(client, "You cannot let go while being rescued.");
					}
					else
					{
						if ((HangTime[client] - GetGameTime()) <= 0)
							OnPlayerDrop(client);
						else
							PrintToChat(client, "You must hang for at least %.2f seconds before letting go.", GetConVarFloat(minHang));
					}	
				}
			}
			else
			{
				Health[client] = GetClientHealth(client);
				HangTime[client] = GetGameTime() + GetConVarFloat(minHang);
				BeingRescued[client] = false;
			}
			
			Buttons[client] = b; //Set "old" buttons
		}
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
		SetEntityHealth(client, Health[client] - GetConVarInt(dropDmg));
		
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangTwoHands");
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangOneHand");
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFingers");
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangAboutToFall");
		ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFalling");
	}
}