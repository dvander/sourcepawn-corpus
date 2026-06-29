#include <sourcemod>
#include <sdktools>

#define MaxClients 24
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_PLUGIN
#define TICKS 10

public Plugin:myinfo = 
{
	name = "Release you hand",
	author = "NiceT",
	description = "Allow players release hand when they are hanging.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

new Buttons[MaxClients];
new Health[MaxClients];
new Float:HangTime[MaxClients];
new Handle:ClientTimer[MaxClients];
new bool:IgnoreHold[MaxClients];


new Handle:minHang;
new Handle:dropDmg;
new Handle:CrouchJump;

public OnPluginStart()
{
	new x;
	for(x = 0; x < MaxClients; x++)
	{
		Buttons[x] = 0;
		Health[x] = 100;
		HangTime[x] = 0.0;
		ClientTimer[x] = INVALID_HANDLE;
		IgnoreHold[x] = false;
	}
	
	minHang 	= CreateConVar("min_Hang_time", "3.0", "the min time you need hold", CVAR_FLAGS, true, 0.0);
	dropDmg 	= CreateConVar("drop_damage", "10.0", "damage when you drop", CVAR_FLAGS, true, 10.0);
	CrouchJump  = CreateConVar("the mode of release", "0", "[0] = hold crouch, [1] = hold jump", CVAR_FLAGS);
	
	AutoExecConfig(true, "release_hand");
	
	HookEvent("player_ledge_grab", EventRelease);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Pre);
	
	new clients = GetClientCount();
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
	for(new i = 0; i < MaxClients; i++)
	{
		if(ClientTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(ClientTimer[i]);
			ClientTimer[i] = INVALID_HANDLE;
		}
		Buttons[i] = 0;
		Health[i] = 100;
		HangTime[i] = 0.0;
		IgnoreHold[i] = false;
	}
}

public Action:PlayerTimer(Handle:timer, any:client)
{
	if(!IsValidEntity(client) || !IsClientInGame(client))
	{
		IgnoreHold[client] = false;
		ClientTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new buttons = GetClientButtons(client);
	new bIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	new bHang = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	new hold_mode = GetConVarInt(CrouchJump);
	if(bIncap && bHang)
	{
		if(hold_mode == 0)
		{
			if((Buttons[client] & IN_DUCK) && !(buttons & IN_DUCK) && !IgnoreHold[client])
			{
				new rescuer = GetEntProp(client, Prop_Send, "m_reviveOwner");
				if(rescuer > 0)
				{
					PrintCenterText(client, "You can't release hand when you been rescued!");
				}
				else
				{
					if(HangTime[client] < GetGameTime())
						OnPlayerDrop(client);
					else
						PrintCenterText(client, "You must hold at least %.2f seconds to release", GetConVarFloat(minHang));
				}	
			}
			else if((Buttons[client] & IN_DUCK) && IgnoreHold[client])
			{
				IgnoreHold[client] = false;
			}
		}
		else if(hold_mode == 1)
		{
			if((Buttons[client] & IN_JUMP) && !(buttons & IN_JUMP) && !IgnoreHold[client])
			{
				new rescuer = GetEntProp(client, Prop_Send, "m_reviveOwner");
				if(rescuer > 0)
				{
					PrintCenterText(client, "You can't release hand when you been rescued!");
				}
				else
				{
					if(HangTime[client] < GetGameTime())
						OnPlayerDrop(client);
					else
						PrintCenterText(client, "You must hold at least %.2f seconds to release", GetConVarFloat(minHang));
				}
			}
			else if((Buttons[client] & IN_JUMP) && IgnoreHold[client])
			{
				IgnoreHold[client] = false;
			}		
		}
	}
	else if(!bIncap)
	{
		Health[client] = GetClientHealth(client);
		HangTime[client] = GetGameTime() + GetConVarFloat(minHang);
		if(hold_mode == 0)
		{
			if (buttons & IN_DUCK)
				IgnoreHold[client] = true; //If we are crouched before we begin to hang, ignore the first release
			else
				IgnoreHold[client] = false;
		}
		else if(hold_mode == 1)
		{
			if (buttons & IN_JUMP)
				IgnoreHold[client] = true; //If we are jump before we begin to hang, ignore the first release
			else
				IgnoreHold[client] = false;
		}
	}
	
	Buttons[client] = buttons;
	
	return Plugin_Continue;
}

public Action:EventPlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0 && client < MaxClients)
	{
		if(ClientTimer[client] != INVALID_HANDLE)
		{
			CloseHandle(ClientTimer[client]);
			ClientTimer[client] = INVALID_HANDLE;
		}
		IgnoreHold[client] = false;
	}
}

public Action:EventPlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client < MaxClients)
	{
		new team = GetClientTeam(client);
		if (team == 2)
		{
			if (ClientTimer[client] != INVALID_HANDLE)
				CloseHandle(ClientTimer[client]);
			
			IgnoreHold[client] = false;
			ClientTimer[client] = CreateTimer(1.0/TICKS, PlayerTimer, client, TIMER_REPEAT);
		}
	}
}
	
public Action:EventRelease(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new hold_mode = GetConVarInt(CrouchJump);
	if(hold_mode == 0)
		PrintCenterText(client, "If you want let it go just hold crouch");
	else if(hold_mode == 1)
		PrintCenterText(client, "If you want let it go just hold jump");
}

OnPlayerDrop(client)
{
	new bHanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	new bIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	if(bHanging && bIncap)
	{
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
		if(Health[client] - GetConVarInt(dropDmg) > 0)
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







































































