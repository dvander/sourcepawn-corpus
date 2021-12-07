#pragma semicolon 1

#include <sourcemod>
#include <tf2>

#define PLUGIN_VERSION "2.0.0"

new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarPhrase = INVALID_HANDLE;
new Handle:cvarX = INVALID_HANDLE;
new Handle:cvarY = INVALID_HANDLE;
new Handle:cvarSpawntime = INVALID_HANDLE;
new Handle:cvarEffect = INVALID_HANDLE;
new Handle:cvarHoldtime = INVALID_HANDLE;
new Handle:cvarRed = INVALID_HANDLE;
new Handle:cvarGreen = INVALID_HANDLE;
new Handle:cvarBlue = INVALID_HANDLE;
new Handle:cvarAlpha = INVALID_HANDLE;
new Handle:cvarTeamcolor = INVALID_HANDLE;
new Handle:cvarVersion = INVALID_HANDLE;
new Handle:ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:hHudText = INVALID_HANDLE;

new String:shudtext[128];
new red;
new green;
new blue;
new alpha;
new effect;
new Float:t;
new Float:x;
new Float:y;
new Float:z;

public Plugin:myinfo = 
{
	name = "Server Logo",
	author = "ReFlexPoison",
	description = "Add a custom hud text logo to all player's screens.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1664292"
}

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_logo_version", PLUGIN_VERSION, "Version of Server Logo", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	
	cvarEnabled = CreateConVar("sm_logo_enabled", "1", "Enable Server Logo\n1=Enabled\n0=Disabled", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarPhrase = CreateConVar("sm_logo_phrase", "Server Logo", "Phrase to Display", FCVAR_NONE);
	cvarX = CreateConVar("sm_logo_xvalue", "0.18", "X Position Value\n-1 = Center", FCVAR_NONE, true, -1.0, true, 1.0);
	cvarY = CreateConVar("sm_logo_yvalue", "0.9", "Y Position Value\n-1 = Center", FCVAR_NONE, true, -1.0, true, 1.0);
	cvarSpawntime = CreateConVar("sm_logo_spawntime", "2", "Time After Spawn to Show Phrase", FCVAR_NONE, true, 1.0, true, 60.0);
	cvarEffect = CreateConVar("sm_logo_effect", "0", "Text/Logo Effect\n0 = Fade In\n1 = Fade In/Out \n2 = Type", FCVAR_NONE, true, 0.0, true, 2.0);
	cvarHoldtime = CreateConVar("sm_logo_holdtime", "-1", "How Long to Show Phrase\n0 = Infinite", FCVAR_NONE, true, 0.0);
	cvarRed = CreateConVar("sm_logo_red", "255", "Red Color Value", FCVAR_NONE, true, 0.0, true, 255.0);
	cvarGreen = CreateConVar("sm_logo_green", "255", "Green Color Value", FCVAR_NONE, true, 0.0, true, 255.0);
	cvarBlue = CreateConVar("sm_logo_blue", "255", "Blue Color Value", FCVAR_NONE, true, 0.0, true, 255.0);
	cvarAlpha = CreateConVar("sm_logo_alpha", "255", "Alpha Transparency Color Value", FCVAR_NONE, true, 0.0, true, 255.0);
	cvarTeamcolor = CreateConVar("sm_logo_teamcolor", "0", "Team Colors Enabled\n1 = Enabled\n0 = Disabled", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookConVarChange(cvarVersion, CVarChange);
	HookConVarChange(cvarPhrase, CVarChange);
	HookConVarChange(cvarX, CVarChange);
	HookConVarChange(cvarY, CVarChange);
	HookConVarChange(cvarSpawntime, CVarChange);
	HookConVarChange(cvarEffect, CVarChange);
	HookConVarChange(cvarHoldtime, CVarChange);
	HookConVarChange(cvarRed, CVarChange);
	HookConVarChange(cvarGreen, CVarChange);
	HookConVarChange(cvarBlue, CVarChange);
	HookConVarChange(cvarAlpha, CVarChange);
	HookConVarChange(cvarTeamcolor, CVarChange);
	
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	HookEvent("player_team", event_player_team);
	
	AutoExecConfig(true, "plugin.serverlogo");
}

public OnConfigsExecuted()
{
	GetConVarString(cvarPhrase, shudtext, sizeof(shudtext));
	x = GetConVarFloat(cvarX);
	y = GetConVarFloat(cvarY);
	z = GetConVarFloat(cvarSpawntime);
	effect = GetConVarInt(cvarEffect);
	t = GetConVarFloat(cvarHoldtime);
	red = GetConVarInt(cvarRed);
	green = GetConVarInt(cvarGreen);
	blue = GetConVarInt(cvarBlue);
	alpha = GetConVarInt(cvarAlpha);
}

////////////////
//CVar CHANGES//
////////////////

public CVarChange(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == cvarPhrase)
	{
		GetConVarString(convar, shudtext, sizeof(shudtext));
	}
	else
	if(convar == cvarX)
	{
		x = GetConVarFloat(convar);
	}
	else
	if(convar == cvarY)
	{
		y = GetConVarFloat(convar);
	}
	else
	if(convar == cvarSpawntime)
	{
		z = GetConVarFloat(convar);
	}
	else
	if(convar == cvarEffect)
	{
		effect = GetConVarInt(convar);
	}
	else
	if(convar == cvarHoldtime)
	{
		t = GetConVarFloat(convar);
	}
	else
	if(convar == cvarRed)
	{
		red = GetConVarInt(convar);
	}
	else
	if(convar == cvarGreen)
	{
		green = GetConVarInt(convar);
	}
	else
	if(convar == cvarBlue)
	{
		blue = GetConVarInt(convar);
	}
	else
	if(convar == cvarAlpha)
	{
		alpha = GetConVarInt(convar);
	}
	else
	if(convar == cvarVersion)
	{
		SetConVarString(cvarVersion, PLUGIN_VERSION);
	}
}

//////////
//EVENTS//
//////////

public event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(cvarEnabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!IsFakeClient(client))
		{
			ClearTimer(ClientTimer[client]);
		}
		ClientTimer[client] = CreateTimer(z, Timer_HudSync, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		ClearSyncHud(client, hHudText);
		ClearTimer(ClientTimer[client]);
	}
}

public event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		if(GetClientTeam(client) != _:TFTeam_Blue || GetClientTeam(client) != _:TFTeam_Red)
		{
			ClearTimer(ClientTimer[client]);
			ClientTimer[client] = CreateTimer(z, Timer_HudSync, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnClientDisconnect(client)
{
	if(IsValidClient(client))
	{
		ClearTimer(ClientTimer[client]);
	}
}

///////////
//ACTIONS//
///////////

public Action:Timer_HudSync(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	hHudText = CreateHudSynchronizer();
	if(GetConVarBool(cvarTeamcolor))
	{
		new team = GetClientTeam(client);
		switch(team)
		{
			case 1: 
			{
				if(GetConVarFloat(cvarHoldtime) >= 0 && GetConVarFloat(cvarHoldtime) < 1)
				{
					SetHudTextParams(x, y, 604800.0, 255, 255, 255, alpha, effect);
				}
				else
				{
					SetHudTextParams(x, y, t, 255, 255, 255, alpha, effect);
				}
			}
			case 2:
			{
				if(GetConVarFloat(cvarHoldtime) >= 0 && GetConVarFloat(cvarHoldtime) < 1)
				{
					SetHudTextParams(x, y, 604800.0, 255, 0, 0, alpha, effect);
				}
				else
				{
					SetHudTextParams(x, y, t, 255, 0, 0, alpha, effect);
				}
			}
			case 3:
			{
				if(GetConVarFloat(cvarHoldtime) >= 0 && GetConVarFloat(cvarHoldtime) < 1)
				{
					SetHudTextParams(x, y, 604800.0, 0, 0, 255, alpha, effect);
				}
				else
				{
					SetHudTextParams(x, y, t, 0, 0, 255, alpha, effect);
				}
			}
		}
	}
	else
	{
		if(GetConVarFloat(cvarHoldtime) >= 0 && GetConVarFloat(cvarHoldtime) < 1)
		{
			SetHudTextParams(x, y, 604800.0, red, green, blue, alpha, effect);
		}
		else
		{
			SetHudTextParams(x, y, t, red, green, blue, alpha, effect);
		}
	}
	ShowSyncHudText(client, hHudText, shudtext);
}

//////////
//STOCKS//
//////////

stock ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}	 
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if(client <= 0 || client > MaxClients)
	{
		return false;
	}
	if(!IsClientInGame(client))
	{
		return false;
	}
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}