/**
 * Copyright (C) 2013 Reiko1231 aka Regent
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "New Flash Color",
	author = "Regent",
	description = "allows change blinding color of flashbang",
	version = PLUGIN_VERSION,
	url = ""
};

// https://wiki.alliedmods.net/User_Messages
#define FFADE_IN            0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT           0x0002        // Fade out (not in)
#define FFADE_MODULATE      0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT       0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE         0x0010        // Purges all other fades, replacing them with this one
// end of https://wiki.alliedmods.net/User_Messages

// convars
new Handle:	g_hConVar_sNewFlashColor = INVALID_HANDLE;
new 		g_iNewFlashColor[3];
new bool:	g_bRandomColor;
new Handle:	g_hConVar_bPluginEnabled = INVALID_HANDLE;
new	bool:	g_bPluginEnabled;

// offsets
new 		g_iOffset_flFlashMaxAlpha,
			g_iOffset_flFlashDuration;
			
// vars
new Handle:	g_hFlashTimer[MAXPLAYERS+1];

public OnPluginStart()
{
	// find offsets
	g_iOffset_flFlashMaxAlpha 	= GetSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	g_iOffset_flFlashDuration 	= GetSendPropOffs("CCSPlayer", "m_flFlashDuration");
	
	// create convars of plugin
	CreateConVar("sm_newflashcolor_version", PLUGIN_VERSION, "version of plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	g_hConVar_sNewFlashColor = CreateConVar("sm_newflashcolor_color", "255 0 0", "new blinding RGB color of flashbang. leave it blank for random colors in each blind event", FCVAR_PLUGIN);
	HookConVarChange(g_hConVar_sNewFlashColor, OnConVarChange);
	g_hConVar_bPluginEnabled = CreateConVar("sm_newflashcolor_enabled", "1", "enabled plugin (1) or not (0)", FCVAR_PLUGIN);
	HookConVarChange(g_hConVar_bPluginEnabled, OnConVarChange);
	
	// hook events
	HookEvent("player_blind", Ev_PlayerBlind);
	HookEvent("player_spawn", Ev_PlayerSpawn);
}

public OnClientPutInServer(iClient)
{
	g_hFlashTimer[iClient] = INVALID_HANDLE;
}

public OnClientDisconnect_Post(iClient)
{
	CancelTimer(g_hFlashTimer[iClient]);
	g_hFlashTimer[iClient] = INVALID_HANDLE;
}

CancelTimer(&Handle:hTimer)
{
	if ( hTimer != INVALID_HANDLE )
	{
		KillTimer(hTimer);
	}
}

public OnConfigsExecuted()
{
	g_bPluginEnabled = GetConVarBool(g_hConVar_bPluginEnabled);
	GetNewFlashColor();
}

public OnConVarChange(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	if ( hConVar == g_hConVar_sNewFlashColor )
	{
		GetNewFlashColor();
	}
	else if ( hConVar == g_hConVar_bPluginEnabled )
	{
		g_bPluginEnabled = GetConVarBool(g_hConVar_bPluginEnabled);
	}
}

GetNewFlashColor()
{
	// find first and last pos of space, then:
	// red part will be everything from start to first space pos
	// green part is everything between first and second space pos
	// blue part is everything else
	decl String:sBuffer[12], String:sPart[4];
	GetConVarString(g_hConVar_sNewFlashColor, sBuffer, sizeof(sBuffer));
	new iFirstSpace = FindCharInString(sBuffer, ' ', false) + 1;
	new iLastSpace  = FindCharInString(sBuffer, ' ', true) + 1;
	
	if ( iFirstSpace == -1 || iFirstSpace == iLastSpace )
	{
		g_bRandomColor = true;
	}
	else
	{
		strcopy(sPart, iFirstSpace, sBuffer);
		g_iNewFlashColor[0] = StringToInt(sPart);
		strcopy(sPart, iLastSpace - iFirstSpace, sBuffer[iFirstSpace]);
		g_iNewFlashColor[1] = StringToInt(sPart);
		strcopy(sPart, strlen(sBuffer) - iLastSpace + 1, sBuffer[iLastSpace]);
		g_iNewFlashColor[2] = StringToInt(sPart);
		g_bRandomColor = false;
	}
}

GetSendPropOffs(const String:sClass[], const String:sProp[])
{
	new iOffset = FindSendPropOffs(sClass, sProp);
	if ( iOffset == - 1 )
	{
		SetFailState("Offset %s::%s not found", sClass, sProp);
		return -1;
	}
	return iOffset;
}

public Ev_PlayerBlind(Handle:hEvent, const String:sEvName[], bool:bSilent)
{
	if ( g_bPluginEnabled )
	{
		new iClient 	= GetClientOfUserId(GetEventInt(hEvent, "userid")),
			iAlpha		= RoundToNearest(GetEntDataFloat(iClient, g_iOffset_flFlashMaxAlpha)),
			iDuration 	= RoundToNearest(GetEntDataFloat(iClient, g_iOffset_flFlashDuration)) * 1000;
		
		// remove classic flash
		SetEntDataFloat(iClient, g_iOffset_flFlashMaxAlpha, 0.5);
		
		// if random, get new color
		if ( g_bRandomColor )
		{
			g_iNewFlashColor[0] = GetRandomInt(1, 255);
			g_iNewFlashColor[1] = GetRandomInt(1, 255);
			g_iNewFlashColor[2] = GetRandomInt(1, 255);
		}
		
		// fade client. hud will be hidden by game
		PerformFade(iClient, iDuration, g_iNewFlashColor, iAlpha);
		CancelTimer(g_hFlashTimer[iClient]);
		g_hFlashTimer[iClient] = CreateTimer(float(iDuration), Timer_FlashEnded, iClient);
	}
}

// https://wiki.alliedmods.net/User_Messages
PerformFade(iClient, iDuration, const iColor[3], iAlpha) 
{
	new iFullBlindDuration = iDuration / 4;
	new Handle:hFadeClient = StartMessageOne("Fade", iClient);
	BfWriteShort(hFadeClient, iDuration - iFullBlindDuration);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration
	BfWriteShort(hFadeClient, iFullBlindDuration);				// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration until reset (fade & hold)
	BfWriteShort(hFadeClient, (FFADE_PURGE|FFADE_IN)); 			// fade type (in / out)
	BfWriteByte(hFadeClient, iColor[0]);						// fade red
	BfWriteByte(hFadeClient, iColor[1]);						// fade green
	BfWriteByte(hFadeClient, iColor[2]);						// fade blue
	BfWriteByte(hFadeClient, iAlpha);							// fade alpha
	EndMessage();
}
// end of https://wiki.alliedmods.net/User_Messages

public Action:Timer_FlashEnded(Handle:hTimer, any:iClient)
{
	g_hFlashTimer[iClient] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Ev_PlayerSpawn(Handle:hEvent, const String:sEvName[], bool:bSilent)
{
	if ( g_bPluginEnabled )
	{
		// fade message will lasts until new one will be created or last one will be finished
		// so, if player was blinded and new round begun, existed fade will continue
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if ( g_hFlashTimer[iClient] != INVALID_HANDLE )
		{
			// replace current fade with new blank fade
			PerformFade(iClient, 0, {0, 0, 0}, 0);
			CancelTimer(g_hFlashTimer[iClient]);
			g_hFlashTimer[iClient] = INVALID_HANDLE;
		}
	}
}