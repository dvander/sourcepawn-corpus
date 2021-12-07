/**
 * =============================================================================
 * SourceMod MySQL Advertisements 
 * (c)2009 DJ Tsunami - http://www.tsunami-productions.nl
 * (c)2009 <eVa>Dog - http://www.theville.org
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <morecolors>
#include <game_text_tf>


#define PLUGIN_VERSION "1.2.200"
#define CVAR_DISABLED "OFF"
#define CVAR_ENABLED  "ON"

new Handle:hAdminMenu = INVALID_HANDLE
new Handle:hDatabase = INVALID_HANDLE
new Handle:hTimer = INVALID_HANDLE
new Handle:hInterval = INVALID_HANDLE
new Handle:g_hCenterAd[MAXPLAYERS + 1]

new bool:g_bTickrate = true

new Float:g_fTime

new g_iFrames = 0
new g_iTickrate
new g_AdCount
new g_Current

static String:g_sTColors[13][12] = {"{WHITE}",       "{RED}",        "{GREEN}",   "{BLUE}",    "{YELLOW}",    "{PURPLE}",    "{CYAN}",      "{ORANGE}",    "{PINK}",      "{OLIVE}",     "{LIME}",      "{VIOLET}",    "{LIGHTBLUE}"};
static g_iSColors[4]             = {1, 3, 3, 4};
static g_iTColors[13][3]         = {{255, 255, 255}, {255, 0, 0},    {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 128, 0}, {255, 0, 128}, {128, 255, 0}, {0, 255, 128}, {128, 0, 255}, {0, 128, 255}};

new String:GameName[64]

new String:g_type[1024][2]
new String:g_text[1024][192]
new String:g_flags[1024][27]
new String:g_game[1024][64]

public Plugin:myinfo =
{
	name = "Advertisements from Database",
	author = "Updated by Pfsm999-Kasador",
	description = "Reads server ads from a common database",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_adsmysql_version", PLUGIN_VERSION, " Adverts from DB Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	RegAdminCmd("sm_reloadads", Admin_ReloadAds, ADMFLAG_CONVARS, " - reloads the ads ")
	
	hInterval = CreateConVar("sm_adsmysql_interval", "45", "Amount of seconds between advertisements")
	HookConVarChange(hInterval, ConVarChange_Interval)
	
	GetGameFolderName(GameName, sizeof(GameName))
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
		
	SQL_TConnect(DBConnect, "admintools")
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error)
		PrintToServer("AdsMYSQL - Unable to connect to database")
		return
	}
	
	hDatabase = hndl
	PrintToServer("AdsMYSQL - Connected Successfully to Database")
	LogAction(0, 0, "AdsMYSQL - Connected Successfully to Database")
}

public OnMapStart()
{
	g_Current = 0
	CreateTimer(10.0, SetupAds, _)
}

public Action:SetupAds(Handle:timer, any:timedelay)
{
	new String:query[1024]
	
	
	Format(query, sizeof(query), "SELECT * FROM adsmysql ORDER BY id;")
	SQL_TQuery(hDatabase, ParseAds, query, _, DBPrio_High)
	
	hTimer = CreateTimer(GetConVarInt(hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
}

public ParseAds(Handle:owner, Handle:hQuery, const String:error[], any:client)
{
	g_AdCount = 0
	
	if(hQuery != INVALID_HANDLE)
	{
		if(SQL_GetRowCount(hQuery) > 0)
		{			
			PrintToConsole(client, "[AdsMYSQL] %i rows found", SQL_GetRowCount(hQuery))
			while(SQL_FetchRow(hQuery))
			{
				SQL_FetchString(hQuery, 1, g_type[g_AdCount], 2)
				SQL_FetchString(hQuery, 2, g_text[g_AdCount], 192)
				SQL_FetchString(hQuery, 3, g_flags[g_AdCount], 27)
				SQL_FetchString(hQuery, 4, g_game[g_AdCount], 64)
				
				PrintToConsole(client, "[AdsMYSQL] Ad %i found in database: %s, %s, %s, %s", g_AdCount, g_type[g_AdCount], g_text[g_AdCount], g_flags[g_AdCount], g_game[g_AdCount])
				
				g_AdCount++
			}
		}
		CloseHandle(hQuery)
		
		if (client > 0)
			PrintToChat(client, "[SM] Reloaded ads")
	}
	else
	{
		LogToGame("[SM] Query failed! %s", error)
	}
}

public Action:Timer_DisplayAds(Handle:timer) 
{
	decl AdminFlag:fFlagList[16], String:sBuffer[256], String:sFlags[27], String:sText[192], String:sType[2], String:sGame[64]
	
	if (g_Current == g_AdCount) 
	{
		g_Current = 0
	}
	
	//For debugging purposes
	//PrintToServer("[AdsMYSQL] Ad %i/%i: %s, %s, %s, %s", g_Current, g_AdCount, g_type[g_Current], g_text[g_Current], g_flags[g_Current], g_game[g_Current])
	
	sType = g_type[g_Current]
	sText = g_text[g_Current]
	sFlags = g_flags[g_Current]
	sGame = g_game[g_Current]
	
	g_Current++
	
	if (StrEqual(sGame, GameName) || StrEqual(sGame, "All"))
	{
	
		new bool:bAdmins = StrEqual(sFlags, ""), bool:bFlags = !StrEqual(sFlags, "none")
		if (bFlags) 
		{
			FlagBitsToArray(ReadFlagString(sFlags), fFlagList, sizeof(fFlagList))
		}
		
		if (StrContains(sText, "{TICKRATE}")   != -1) 
		{
			IntToString(g_iTickrate, sBuffer, sizeof(sBuffer))
			ReplaceString(sText, sizeof(sText), "{TICKRATE}",   sBuffer)
		}
		
		if (StrContains(sText, "{CURRENTMAP}") != -1) 
		{
			GetCurrentMap(sBuffer, sizeof(sBuffer))
			ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer)
		}
		
		if (StrContains(sText, "{DATE}")       != -1) 
		{
			FormatTime(sBuffer, sizeof(sBuffer), "%d/%m/%Y")
			ReplaceString(sText, sizeof(sText), "{DATE}",       sBuffer)
		}
		
		if (StrContains(sText, "{TIME}")       != -1) 
		{
			FormatTime(sBuffer, sizeof(sBuffer), "%I:%M:%S%p") 
			ReplaceString(sText, sizeof(sText), "{TIME}",       sBuffer)
		}
		
		if (StrContains(sText, "{TIME24}")     != -1) 
		{
			FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S")
			ReplaceString(sText, sizeof(sText), "{TIME24}",     sBuffer)
		}
		
		if (StrContains(sText, "{TIMELEFT}")   != -1) 
		{
			new iMins, iSecs, iTimeLeft
			
			if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0) 
			{
				iMins = iTimeLeft / 60
				iSecs = iTimeLeft % 60
			}
			
			Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs)
			ReplaceString(sText, sizeof(sText), "{TIMELEFT}",   sBuffer)
		}
		
		if (StrContains(sText, "\\n")          != -1) 
		{
			Format(sBuffer, sizeof(sBuffer), "%c", 13)
			ReplaceString(sText, sizeof(sText), "\\n",          sBuffer)
		}
		
		new iStart = StrContains(sText, "{BOOL:")
		while (iStart != -1) 
		{
			new iEnd = StrContains(sText[iStart + 6], "}")
			
			if (iEnd != -1) 
			{
				decl String:sConVar[64], String:sName[64]
				
				strcopy(sConVar, iEnd + 1, sText[iStart + 6])
				Format(sName, sizeof(sName), "{BOOL:%s}", sConVar)
				
				new Handle:hConVar = FindConVar(sConVar)
				if (hConVar != INVALID_HANDLE) 
				{
					ReplaceString(sText, sizeof(sText), sName, GetConVarBool(hConVar) ? CVAR_ENABLED : CVAR_DISABLED)
				}
			}
			
			new iStart2 = StrContains(sText[iStart + 1], "{BOOL:") + iStart + 1
			if (iStart == iStart2) 
			{
				break
			} 
			else 
			{
				iStart = iStart2
			}
		}
		
		iStart = StrContains(sText, "{")
		while (iStart != -1) 
		{
			new iEnd = StrContains(sText[iStart + 1], "}")
			
			if (iEnd != -1) 
			{
				decl String:sConVar[64], String:sName[64]
				
				strcopy(sConVar, iEnd + 1, sText[iStart + 1])
				Format(sName, sizeof(sName), "{%s}", sConVar)
				
				new Handle:hConVar = FindConVar(sConVar)
				if (hConVar != INVALID_HANDLE) 
				{
					GetConVarString(hConVar, sBuffer, sizeof(sBuffer))
					ReplaceString(sText, sizeof(sText), sName, sBuffer)
				}
			}
			
			new iStart2 = StrContains(sText[iStart + 1], "{") + iStart + 1
			if (iStart == iStart2) 
			{
				break
			} 
			else 
			{
				iStart = iStart2
			}
		}
		
		if (StrContains(sType, "C") != -1) 
		{
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i) &&
						((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
						 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
												 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
				{
					PrintCenterText(i, sText)
					
					new Handle:hCenterAd
					g_hCenterAd[i] = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT)
					WritePackCell(hCenterAd,   i)
					WritePackString(hCenterAd, sText)
				}
			}
		}
		
		if (StrContains(sType, "H") != -1) 
		{
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i) &&
						((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
						 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
												 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
				{
					PrintHintText(i, sText)
				}
			}
		}
		
		if (StrContains(sType, "M") != -1) 
		{
			new Handle:hPl = CreatePanel()
			DrawPanelText(hPl, sText)
			SetPanelCurrentKey(hPl, 10)
			
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i) &&
						((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
						 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
												 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
				{
					SendPanelToClient(hPl, i, Handler_DoNothing, 10)
				}
			}
			
			CloseHandle(hPl)
		}
		
		if (StrContains(sType, "T") != -1) 
		{
			/* REPLACE OLD CODE FOR A NEW CODE WITH SOME .... Personalsation :)
			decl String:sColor[16]
			new iColor = -1, iPos = BreakString(sText, sColor, sizeof(sColor))
			
			for (new i = 0; i < sizeof(g_sTColors); i++) 
			{
				if (StrEqual(sColor, g_sTColors[i])) 
				{
					iColor = i
				}
			}
			
			if (iColor == -1) 
			{
				iPos     = 0
				iColor   = 0
			}
			
			new Handle:hKv = CreateKeyValues("Stuff", "title", sText[iPos])
			KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], g_iTColors[iColor][2], 255)
			KvSetNum(hKv,   "level", 1)
			KvSetNum(hKv,   "time",  10)
			
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i) &&
						((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
						 bAdmins && (GetUserFlagBits(i) & ADMFLAG_GENERIC ||
												 GetUserFlagBits(i) & ADMFLAG_ROOT))) 
				{
					CreateDialog(i, hKv, DialogType_Msg)
				}
			}
			CloseHandle(hKv)
			*/
			new paramT[4][32];
			ExplodeString(sFlags,";", paramT, 4, 31, false );
			PrintTFText(sText,StringToInt(paramT[0]),StringToInt(paramT[1]),StringToFloat(paramT[2]),paramT[3]);
		}
		
		if (StrContains(sType, "S") != -1) 
		{
			for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					
					if (StrEqual(GameName, "tf") || StrEqual(GameName, "cstrike"))
					{
						if(bFlags)
							CPrintToChat(i, "{ghostwhite}-------------------{community}Informations / Advertisements{ghostwhite}--------------------");
						CPrintToChat(i, "%s", sText);
						if(bFlags)
							CPrintToChat(i, "{ghostwhite}-------------------------------------------------------------------------");
					}
					else
					{
						CPrintToChat(i, "{ghostwhite}-------------------{community}Informations / Advertisements{ghostwhite}--------------------");
						PrintToChat(i, sText);
						CPrintToChat(i, "{ghostwhite}-------------------------------------------------------------------------");
					}	
				}
			}
			
		}
	}
}

bool:HasFlag(iClient, AdminFlag:fFlagList[16]) 
{
	new iFlags = GetUserFlagBits(iClient)
	if (iFlags & ADMFLAG_ROOT) 
	{
		return true
	} 
	else 
	{
		for (new i = 0; i < sizeof(fFlagList); i++) 
		{
			if (iFlags & FlagToBit(fFlagList[i])) 
			{
				return true
			}
		}
		
		return false
	}
}

public Action:Timer_CenterAd(Handle:timer, Handle:pack) 
{
	decl String:sText[256]
	static iCount = 0
	
	ResetPack(pack)
	new iClient = ReadPackCell(pack)
	ReadPackString(pack, sText, sizeof(sText))
	
	if (IsClientInGame(iClient) && ++iCount < 5) 
	{
		PrintCenterText(iClient, sText)
		
		return Plugin_Continue
	} 
	else 
	{
		iCount = 0
		g_hCenterAd[iClient] = INVALID_HANDLE
		
		return Plugin_Stop
	}
}

SayText2(to, const String:message[]) 
{
	new Handle:hBf = StartMessageOne("SayText2", to)
	
	if (hBf != INVALID_HANDLE) 
	{
		BfWriteByte(hBf,   to)
		BfWriteByte(hBf,   true)
		BfWriteString(hBf, message)
		
		EndMessage()
	}
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) 
{
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	if (hTimer != INVALID_HANDLE) 
	{
		KillTimer(hTimer)
	}
	
	hTimer = CreateTimer(GetConVarInt(hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
}

public Action:Admin_ReloadAds(client, args)
{
	new String:query[1024]
	
	Format(query, sizeof(query), "SELECT * FROM adsmysql ORDER BY id;")
	SQL_TQuery(hDatabase, ParseAds, query, client, DBPrio_High)
	
	return Plugin_Handled
}

public OnGameFrame() 
{
	if (g_bTickrate) 
	{
		g_iFrames++;
		
		new Float:fTime = GetEngineTime();
		if (fTime >= g_fTime) 
		{
			if (g_iFrames == g_iTickrate) 
			{
				g_bTickrate = false;
			} else 
			{
				g_iTickrate = g_iFrames;
				g_iFrames   = 0;    
				g_fTime     = fTime + 1.0;
			}
		}
	}
}

// ############################################################################
// Admin Menus
// ############################################################################

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS)

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_reloadads",
			TopMenuObject_Item,
			AdminMenu_ReloadAds,
			player_commands,
			"sm_reloadads",
			ADMFLAG_CONVARS)	
	}
}

public AdminMenu_ReloadAds(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Reload Ads")
	}
	else if (action == TopMenuAction_SelectOption)
	{
		new String:query[1024]
	
		Format(query, sizeof(query), "SELECT * FROM adsmysql ORDER BY id;")
		SQL_TQuery(hDatabase, ParseAds, query, param, DBPrio_High)
	}
}