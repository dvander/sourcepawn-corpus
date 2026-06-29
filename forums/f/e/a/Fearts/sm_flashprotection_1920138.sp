#pragma semicolon 1
#include <sdkhooks>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Flash Protection",
	author = "TheAvengers2, thetwistedpanda, GoD-Tony, Bacardi",
	description = "Anti-TeamFlash, NoDeafen, Anti-NoFlash, Flash Duration Bug Fix",
	version = "0.0.7",
	url = "http://sourcemod.com/"
}

#define IS_CLIENT(%1)	(1 <= %1 <= MaxClients)

#define CS_TEAM_SPECTATOR 1
#define CS_TEAM_T 2

// Fade UserMessage bits
#define FFADE_IN		0x0001	// Just here so we don't pass 0 into the function
#define FFADE_OUT		0x0002	// Fade out (not in)
#define FFADE_MODULATE	0x0004	// Modulate (don't blend)
#define FFADE_STAYOUT	0x0008	// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE		0x0010	// Purges all other fades, replacing them with this one

enum {
	OBS_MODE_NONE = 0,	// not in spectator mode
	OBS_MODE_DEATHCAM,	// special mode for death cam animation
	OBS_MODE_FREEZECAM,	// zooms to a target, and freeze-frames on them
	OBS_MODE_FIXED,		// view from a fixed camera position
	OBS_MODE_IN_EYE,	// follow a player in first person view
	OBS_MODE_CHASE,		// follow a player in third person view
	OBS_MODE_ROAMING,	// free roaming
};

enum {
	FLASH_OWNER = 0,
	FLASH_TEAM
};

// Flash variables
new Handle:g_hFlashThrowers = INVALID_HANDLE;

new g_iFlashVictim[MAXPLAYERS + 1];
new g_iVictimCount = 0;
new bool:g_bFlashedEnemy;

new Float:g_fFlashAlpha[MAXPLAYERS + 1];
new Float:g_fFlashDuration[MAXPLAYERS + 1];
new Float:g_fFlashLeft[MAXPLAYERS + 1];

new Float:g_fFlashedUntil[MAXPLAYERS+1];
new bool:g_bFlashHooked = false; 

// thetwistedpanda - Anti Team Flash (http://forums.alliedmods.net/showthread.php?t=139505)
// GoD-Tony - SMAC Anti-NoFlash (http://hg.nicholashastings.com/smac/)
// Bacardi - Flash Duration Bug Fix (http://forums.alliedmods.net/showthread.php?t=173450)
// Bacardi - No Deafening (http://forums.alliedmods.net/showpost.php?p=1493651&postcount=13)

public OnPluginStart()
{
	HookEvent("flashbang_detonate", Event_FlashbangDetonate, EventHookMode_Post);
	HookEvent("player_blind", Event_PrePlayerBlind, EventHookMode_Pre);
	HookEvent("player_blind", Event_PostPlayerBlind, EventHookMode_Post);

	g_hFlashThrowers = CreateArray(2);
}

public OnPluginEnd()
{
	ClearArray(g_hFlashThrowers);
}

public OnMapEnd()
{
	ClearArray(g_hFlashThrowers);
	g_iVictimCount = 0;
	g_bFlashedEnemy = false;
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client) && g_bFlashHooked)
	{
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public OnClientDisconnect(client)
{
	g_fFlashedUntil[client] = 0.0;
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
	decl iFlashData[2];
	new iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (IS_CLIENT(iOwner) && IsClientInGame(iOwner))
	{
		iFlashData[FLASH_OWNER] = GetClientUserId(iOwner);
		iFlashData[FLASH_TEAM] = GetClientTeam(iOwner);
		PushArrayArray(g_hFlashThrowers, iFlashData);
	}
	else
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public Event_PrePlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")), Float:fGameTime = GetGameTime();
	
	g_fFlashAlpha[client] = GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha");
	g_fFlashDuration[client] = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
	g_fFlashLeft[client] = (g_fFlashedUntil[client] && g_fFlashedUntil[client] > fGameTime) ? (g_fFlashedUntil[client] - fGameTime) + 2.5 : 0.0;
}

public Event_PostPlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetArraySize(g_hFlashThrowers) && IS_CLIENT(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		decl iFlashData[2];
		GetArrayArray(g_hFlashThrowers, 0, iFlashData);
		new team = GetClientTeam(client);
		new target = client;
		
		if (IsClientObserver(client))
		{
			if (GetClientObserverMode(client) == OBS_MODE_IN_EYE)
			{
				target = GetClientObserverTarget(client);
				
				if (IS_CLIENT(target) && IsClientInGame(target) && !IsClientObserver(target) && !IsFakeClient(target))
				{
					SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", GetEntPropFloat(target, Prop_Send, "m_flFlashMaxAlpha"));
					SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", GetEntPropFloat(target, Prop_Send, "m_flFlashDuration"));
				}
			}
			team = -1;
		}
		
		if (target == GetClientOfUserId(iFlashData[FLASH_OWNER]))
		{
			SetupAntiFlash(client);
		}
		else
		{
			if (team > CS_TEAM_SPECTATOR && team != iFlashData[FLASH_TEAM] && GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha") >= 255.0)
			{
				g_bFlashedEnemy = true;
			}
			g_iFlashVictim[g_iVictimCount++] = GetClientUserId(client);
		}
	}
}

public Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetArraySize(g_hFlashThrowers))
	{
		if (g_iVictimCount > 0)
		{
			decl String:sOutputMessage[192];
			if (g_bFlashedEnemy)
			{
				decl iFlashData[2];
				GetArrayArray(g_hFlashThrowers, 0, iFlashData);
				new iOwner = GetClientOfUserId(iFlashData[FLASH_OWNER]);
				
				if (IS_CLIENT(iOwner) && IsClientInGame(iOwner))
				{
					decl String:sOwnerAuth[30];
					if (!GetClientAuthString(iOwner, sOwnerAuth, sizeof(sOwnerAuth)))
						sOwnerAuth[0] = '\0';
						
					FormatEx(sOutputMessage, sizeof(sOutputMessage), "\x04[FD] %s%N \x04(\x01%s\x04) has flashed you.", ((iFlashData[FLASH_TEAM] == CS_TEAM_T) ? "\x07FF4040" : "\x0799CCFF"), iOwner, sOwnerAuth);
				}
				else
				{
					sOutputMessage[0] = '\0';
				}
			}
			
			decl iClient;
			for (new i = 0; i < g_iVictimCount; i++)
			{
				iClient = GetClientOfUserId(g_iFlashVictim[i]);
				
				if (!IS_CLIENT(iClient) || !IsClientInGame(iClient))
					continue;
					
				if (g_bFlashedEnemy)
				{
					SetupAntiFlash(iClient);
					if (sOutputMessage[0] != '\0')
					{
						PrintToChat(iClient, sOutputMessage);
					}
				}
				else
				{
					if (g_fFlashLeft[iClient])
					{
						SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", g_fFlashAlpha[iClient]);
						SetEntPropFloat(iClient, Prop_Send, "m_flFlashDuration", g_fFlashLeft[iClient]);
						SetupAntiFlash(iClient);
					}
					else
					{
						ClientCommand(iClient, "dsp_player 0");
						SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);
						SetEntPropFloat(iClient, Prop_Send, "m_flFlashDuration", 0.0);
						g_fFlashedUntil[iClient] = 0.0;
						
						PrintToChat(iClient, "\x04[FD] \x01Teamflash was nullified.");
					}
				}
			}
		}
		
		g_iVictimCount = 0;
		g_bFlashedEnemy = false;
		RemoveFromArray(g_hFlashThrowers, 0);
	}
}

SetupAntiFlash(client)
{
	// Bacardi - Flash Bug Fix
	new Float:duration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
	if (duration == g_fFlashDuration[client])
	{
		duration = GetRandomFloat(duration + 0.01, duration + 0.1);
		SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", duration);
	}
	
	// GoD-Tony - SMAC Anti-NoFlash
	if (GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha") < 255.0)
		return;

	g_fFlashedUntil[client] = (duration > 2.9) ? (GetGameTime() + duration - 2.9) : (GetGameTime() + duration * 0.1);
	SendMsgFadeUser(client, RoundToNearest(duration * 1000.0), USERMSG_BLOCKHOOKS);
	
	if (!g_bFlashHooked)
	{
		AntiFlash_HookAll();
	}
	
	CreateTimer(duration, Timer_FlashEnded);
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

public Action:Hook_SetTransmit(entity, client)
{
	/* Don't send client data to players that are fully blind. */
	if (g_fFlashedUntil[client])
	{
		if (g_fFlashedUntil[client] > GetGameTime())
			return (entity == client) ? Plugin_Continue : Plugin_Handled;
		
		// Fade out the flash.
		SendMsgFadeUser(client, 0, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
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

SendMsgFadeUser(client, duration, flags)
{
	static UserMsg:msgFadeUser = INVALID_MESSAGE_ID;
	
	if (msgFadeUser == INVALID_MESSAGE_ID)
		msgFadeUser = GetUserMessageId("Fade");
	
	decl players[1];
	players[0] = client;
	
	new Handle:bf = StartMessageEx(msgFadeUser, players, 1, flags);
	BfWriteShort(bf, (duration > 0) ? duration : 50); // duration
	BfWriteShort(bf, (duration > 0) ? 1000 : 0); // hold time
	BfWriteShort(bf, FFADE_IN|FFADE_PURGE);
	BfWriteByte(bf, 255); // r
	BfWriteByte(bf, 255); // g
	BfWriteByte(bf, 255); // b
	BfWriteByte(bf, 255); // a
	
	EndMessage();
}

stock GetClientObserverMode(client)
{
	static offset = -1;
	
	if (offset == -1 && (offset = FindSendPropOffs("CBasePlayer", "m_iObserverMode")) == -1)
	{
		return OBS_MODE_NONE;
	}
	
	return GetEntData(client, offset);
}

stock GetClientObserverTarget(client)
{
	static offset = -1;
	
	if (offset == -1 && (offset = FindSendPropOffs("CBasePlayer", "m_hObserverTarget")) == -1)
	{
		return -1;
	}
	
	return GetEntDataEnt2(client, offset);
}