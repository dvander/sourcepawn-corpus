#pragma semicolon 1
#include <sdkhooks>

#define IS_CLIENT(%1)	(1 <= %1 <= MaxClients)

#define CS_TEAM_SPECTATOR 1
#define CS_TEAM_T 2
#define PLUGIN_VERSION "0.0.5"

// Fade UserMessage bits
#define FFADE_IN		0x0001	// Just here so we don't pass 0 into the function
#define FFADE_OUT		0x0002	// Fade out (not in)
#define FFADE_MODULATE	0x0004	// Modulate (don't blend)
#define FFADE_STAYOUT	0x0008	// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE		0x0010	// Purges all other fades, replacing them with this one

// PropOffsets
new g_iFlashDuration = -1;
new g_iFlashAlpha = -1;

new bool:g_bLateLoad;

// Flash variables
new Handle:g_hFlashThrowers = INVALID_HANDLE;

new g_iFlashVictim[MAXPLAYERS + 1];
new g_iVictimCount = -1;
new bool:g_bFlashedEnemy;

new Float:g_fFlashAlpha[MAXPLAYERS + 1];
new Float:g_fFlashDuration[MAXPLAYERS + 1];
new Float:g_fFlashLeft[MAXPLAYERS + 1];

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];

new Float:g_fFlashedUntil[MAXPLAYERS+1];
new bool:g_bFlashHooked = false; 

new String:g_sOutputMessage[192];

public Plugin:myinfo = 
{
	name = "Flash Protection",
	author = "TheAvengers2, thetwistedpanda, GoD-Tony, Bacardi",
	description = "Anti-TeamFlash, NoDeafen, Anti-NoFlash, Flash Duration Bug Fix",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.com/"
}

// thetwistedpanda - Anti Team Flash (http://forums.alliedmods.net/showthread.php?t=139505)
// GoD-Tony - SMAC Anti-NoFlash (http://hg.nicholashastings.com/smac/)
// Bacardi - Flash Duration Bug Fix (http://forums.alliedmods.net/showthread.php?t=173450)
// Bacardi - No Deafening (http://forums.alliedmods.net/showpost.php?p=1493651&postcount=13)

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	if ((g_iFlashDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration")) == -1)
		SetFailState("Failed to find \"m_flFlashDuration\".");

	if ((g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha")) == -1)
		SetFailState("Failed to find \"m_flFlashMaxAlpha\".");

	HookEvent("flashbang_detonate", Event_OnFlashExplode, EventHookMode_Post);
	HookEvent("player_blind", Event_PreFlashPlayer, EventHookMode_Pre);
	HookEvent("player_blind", Event_OnFlashPlayer, EventHookMode_Post);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);

	g_hFlashThrowers = CreateArray(2);
}

public OnPluginEnd()
{
	ClearArray(g_hFlashThrowers);
}

public OnConfigsExecuted()
{
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				g_iTeam[i] = GetClientTeam(i);
				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
			}
		}
		
		g_bLateLoad = false;
	}
}

public OnMapEnd()
{
	ClearArray(g_hFlashThrowers);
	g_iVictimCount = -1;
	g_bFlashedEnemy = false;
}

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
		return;

	if (g_bFlashHooked)
	{
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public OnClientDisconnect(client)
{
	g_fFlashedUntil[client] = 0.0;
	g_iTeam[client] = 0;
	g_bAlive[client] = false;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "flashbang_projectile"))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}

public OnEntitySpawned(entity)
{
	decl _iData[2];
	_iData[0] = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	_iData[1] = (_iData[0] > 0) ? g_iTeam[_iData[0]] : 0;
	
	PushArrayArray(g_hFlashThrowers, _iData);
}

public Event_OnFlashExplode(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetArraySize(g_hFlashThrowers))
	{
		if (g_iVictimCount != -1)
		{
			decl iVictim;
			for (new i = 0; i <= g_iVictimCount; ++i)
			{
				iVictim = g_iFlashVictim[i];
				if (!IsClientInGame(iVictim))
					continue;
					
				if (g_bFlashedEnemy)
				{
					if (g_sOutputMessage[0] != '\0')
					{
						PrintToChat(iVictim, g_sOutputMessage);
					}
				}
				else
				{
					if (g_fFlashLeft[iVictim])
					{
						SetEntDataFloat(iVictim, g_iFlashAlpha, g_fFlashAlpha[iVictim]);
						SetEntDataFloat(iVictim, g_iFlashDuration, g_fFlashLeft[iVictim]);
					
						SetupAntiFlash(iVictim);
					}
					else
					{
						SetEntDataFloat(iVictim, g_iFlashAlpha, 0.5);
						SetEntDataFloat(iVictim, g_iFlashDuration, 0.0);
						ClientCommand(iVictim, "dsp_player 0");
						SendMsgFadeUser(iVictim, 0);
						g_fFlashedUntil[iVictim] = 0.0;
						PrintToChat(iVictim, "\x04[FD] \x01Teamflash was nullified.");
					}
				}
			}
		}
		RemoveFromArray(g_hFlashThrowers, 0);
	}
	
	g_iVictimCount = -1;
	g_bFlashedEnemy = false;
	g_sOutputMessage[0] = '\0';
}

public Event_PreFlashPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")), Float:fGameTime = GetGameTime();
	
	g_fFlashAlpha[client] = GetEntDataFloat(client, g_iFlashAlpha);
	g_fFlashDuration[client] = GetEntDataFloat(client, g_iFlashDuration);
	g_fFlashLeft[client] = (g_fFlashedUntil[client] && g_fFlashedUntil[client] > fGameTime) ? (g_fFlashedUntil[client] - fGameTime) + 2.5 : 0.0;
}

public Event_OnFlashPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_CLIENT(client) && IsClientInGame(client))
	{
		if (GetArraySize(g_hFlashThrowers))
		{
			if (g_bAlive[client] && g_iTeam[client] > CS_TEAM_SPECTATOR)
			{
				decl _iData[2];
				GetArrayArray(g_hFlashThrowers, 0, _iData);
				
				// build standard output message
				if (g_sOutputMessage[0] == '\0' && IsClientInGame(_iData[0]))
				{
					decl String:sOwnerName[32], String:sOwnerAuth[30];
					GetClientName(_iData[0], sOwnerName, sizeof(sOwnerName));
					GetClientAuthString(_iData[0], sOwnerAuth, sizeof(sOwnerAuth));
					FormatEx(g_sOutputMessage, sizeof(g_sOutputMessage), "\x04[FD] %s%s \x04(\x01%s\x04) has flashed you.", ((_iData[1] == CS_TEAM_T) ? "\x07FF4040" : "\x0799CCFF"), sOwnerName, sOwnerAuth);
				}
			
				if (g_iTeam[client] == _iData[1])
				{
					if (client != _iData[0])
						g_iFlashVictim[(++g_iVictimCount)] = client;
				}
				else
				{
					if (SetupAntiFlash(client))
					{
						g_bFlashedEnemy = true;
						
						if (g_sOutputMessage[0] != '\0')
						{
							PrintToChat(client, g_sOutputMessage);
						}
					}
						
					return;
				}
			}
		}
		
		SetupAntiFlash(client);
	}
}

bool:SetupAntiFlash(client)
{
	// Bacardi - Flash Bug Fix
	new Float:duration = GetEntDataFloat(client, g_iFlashDuration);
	if (duration == g_fFlashDuration[client])
	{
		duration = GetRandomFloat(duration + 0.01, duration + 0.1);
		SetEntDataFloat(client, g_iFlashDuration, duration);
	}
	
	// GoD-Tony - SMAC Anti-NoFlash
	new Float:alpha = GetEntDataFloat(client, g_iFlashAlpha);
	if (alpha < 255.0)
		return false;

	g_fFlashedUntil[client] = (duration > 2.9) ? (GetGameTime() + duration - 2.9) : (GetGameTime() + duration * 0.1);
	SendMsgFadeUser(client, RoundToNearest(duration * 1000.0));
	
	if (!g_bFlashHooked)
	{
		AntiFlash_HookAll();
	}
	
	CreateTimer(duration, Timer_FlashEnded);
	return true;
}

public Action:Timer_FlashEnded(Handle:timer)
{
	/* Check if there are any other flashes being processed. Otherwise, we can unhook. */
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_fFlashedUntil[i])
		{
			return Plugin_Stop;
		}
	}
	
	if (g_bFlashHooked)
	{
		AntiFlash_UnhookAll();
	}
	
	return Plugin_Stop;
}

public Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_CLIENT(client) && IsClientInGame(client))
	{
		g_iTeam[client] = GetEventInt(event, "team");
		if (g_iTeam[client] <= CS_TEAM_SPECTATOR)
		{
			g_bAlive[client] = false;
		}
	}
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_CLIENT(client) && IsClientInGame(client) && g_iTeam[client] > CS_TEAM_SPECTATOR)
	{
		g_bAlive[client] = true;
	}
}

public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_CLIENT(client) && IsClientInGame(client))
	{
		g_bAlive[client] = false;
	}
}

public Action:Hook_SetTransmit(entity, client)
{
	/* Don't send client data to players that are fully blind. */
	if (g_fFlashedUntil[client])
	{
		if (g_fFlashedUntil[client] > GetGameTime())
			return (entity == client) ? Plugin_Continue : Plugin_Handled;
		
		// Fade out the flash.
		SendMsgFadeUser(client, 0);
		g_fFlashedUntil[client] = 0.0;
	}
	
	return Plugin_Continue;
}

AntiFlash_HookAll()
{
	g_bFlashHooked = true;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
}

AntiFlash_UnhookAll()
{
	g_bFlashHooked = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
}

SendMsgFadeUser(client, duration)
{
	static UserMsg:msgFadeUser = INVALID_MESSAGE_ID;
	
	if (msgFadeUser == INVALID_MESSAGE_ID)
		msgFadeUser = GetUserMessageId("Fade");
	
	decl players[1];
	players[0] = client;
	
	new Handle:bf = StartMessageEx(msgFadeUser, players, 1);
	BfWriteShort(bf, (duration > 0) ? duration : 50); // duration
	BfWriteShort(bf, (duration > 0) ? 1000 : 0); // hold time
	BfWriteShort(bf, FFADE_IN|FFADE_PURGE);
	BfWriteByte(bf, 255); // r
	BfWriteByte(bf, 255); // g
	BfWriteByte(bf, 255); // b
	BfWriteByte(bf, 255); // a
	
	EndMessage();
}