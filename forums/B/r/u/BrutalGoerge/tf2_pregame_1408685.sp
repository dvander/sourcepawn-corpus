/************************************************************************
*************************************************************************
Waiting For Players
Description:
	Friendlyfire during waiting for players
*************************************************************************
*************************************************************************

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: tf2_pregame.sp 163 2012-08-20 09:08:31Z brutalgoergectf@gmail.com $
$Author: brutalgoergectf@gmail.com $
$Revision: 163 $
$Date: 2012-08-20 03:08:31 -0600 (Mon, 20 Aug 2012) $
$LastChangedBy: brutalgoergectf@gmail.com $
$LastChangedDate: 2012-08-20 03:08:31 -0600 (Mon, 20 Aug 2012) $
$URL: https://tf2tmng.googlecode.com/svn/trunk/pre_game/scripting/tf2_pregame.sp $
$Copyright: (c) Tf2Tmng 2009-2011$
*************************************************************************
*************************************************************************
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>

#define MINI_CRIT 0
#define FULL_CRIT 1
#define NO_CRIT 2

//new g_Crits;
//new g_iMelee;
new bool:g_bPreGame;
new bool:g_bBlockLog;

new g_iFrags[MAXPLAYERS+1];

#define PL_VERSION "1.0.7"

new Handle:g_hVarTime = INVALID_HANDLE;
new Handle:g_hVarStats = INVALID_HANDLE;
new Handle:g_hCookie_ClientMenu = INVALID_HANDLE;
new Handle:g_hVarDoors = INVALID_HANDLE,
	Handle:g_hVarCrits = INVALID_HANDLE,
	Handle:g_hVarMelee = INVALID_HANDLE;
new g_iTimeLeft;

new g_iMenuSettings[MAXPLAYERS+1];

/*
enum e_RoundState
{
	newMap,
	preGame,
	normal,
	lateLoad
};*/

enum e_Door
{
	dontTouch,
	open,
	close,
	randomDoor
};

enum e_Crits
{
	noCrit,
	miniCrit,
	fullCrit,
	randomCrit
};

enum e_Melee
{
	allowAll,
	meleeOnly,
	randomMelee
};

//new e_RoundState:g_RoundState;
new e_Crits:g_Crits;
bool g_bMelee;

public Plugin:myinfo = 
{
	name = "[TF2] Pregame Slaughter",
	author = "Goerge",
	description = "Funtimes for pregame round",
	version = PL_VERSION,
	url = "http://tf2tmng.googlecode.com/"
};

/*
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		g_RoundState = lateLoad;
	}
	return APLRes_Success;
}*/

public OnClientConnected(client)
{
	g_iFrags[client] = 0;
}

public OnPluginStart()
{
	//HookEvent("teamplay_round_start", 		Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	AddGameLogHook(LogHook);
	g_hVarTime = CreateConVar("tf2_pregame_timelimit", "50", "time in seconds that pregame lasts", FCVAR_PLUGIN, true, 10.0, false);
	g_hVarStats = CreateConVar("tf2_pregame_stats", "1", "Track the number of kills people get during", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hVarDoors = CreateConVar("tf2_pregame_doors", "3", "1 = open all map doors.\n2 = close and lock all map doors.\n3 = random.\n0=Do not mess with doors",
								FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hVarCrits = CreateConVar("tf2_pregame_crits", "3", "0 = no crits.\n1 = Mini Crits\n2 = Full crits.\n3 = random.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hVarMelee	= CreateConVar("tf2_pregame_melee", "2", "0 = allow all weapons.\n1 = Melee only.\n2 = random", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	CreateConVar("sm_pregame_slaughter_version", PL_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hCookie_ClientMenu = RegClientCookie("tf2_pregame_menu", "enables the winners menu on a per-client basis", CookieAccess_Public);
	SetCookieMenuItem(CookieMenu_Handler, g_hCookie_ClientMenu, "TF2 Pregame");
	AutoExecConfig();	
}

public CookieMenu_Handler(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		//don't think we need to do anything
	}
	else
	{
		new Handle:hMenu = CreateMenu(Menu_CookieSettings);
		SetMenuTitle(hMenu, "TF2 Pregame Winner Menu (Current Setting)");
		if (g_iMenuSettings[client] != -1)
			AddMenuItem(hMenu, "enable", "Enabled/Disable (Enabled)");		
		else
			AddMenuItem(hMenu, "enable", "Enabled/Disable (Disabled)");
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}

public Menu_CookieSettings(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsEnable);
			SetMenuTitle(hMenu, "Enable/Disable Winners Menu");
			
			if (g_iMenuSettings[client] != -1)
			{
				AddMenuItem(hMenu, "enable", "Enable (Set)");
				AddMenuItem(hMenu, "disable", "Disable");
			}
			else
			{
				AddMenuItem(hMenu, "enable", "Enabled");
				AddMenuItem(hMenu, "disable", "Disable (Set)");
			}
			
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_CookieSettingsEnable(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			SetClientCookie(client, g_hCookie_ClientMenu, "1");
			g_iMenuSettings[client] = 1;
			PrintToChat(client, "[SM] Pregame winner menu ENABLED");
		}
		else
		{
			SetClientCookie(client, g_hCookie_ClientMenu, "-1");
			g_iMenuSettings[client] = -1;
			PrintToChat(client, "[SM] Pregame winner menu DISABLED");
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public OnConfigsExecuted()
{
	SetConVarInt(FindConVar("mp_waitingforplayers_time"), GetConVarInt(g_hVarTime));
}

public OnClientCookiesCached(client)
{
	if (IsClientConnected(client) && !IsFakeClient(client))
	{
		decl String:sCookieSetting[3];
		GetClientCookie(client, g_hCookie_ClientMenu, sCookieSetting, sizeof(sCookieSetting));
		g_iMenuSettings[client] = StringToInt(sCookieSetting);
	}
}

public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bPreGame)
	{
		g_bBlockLog = true;
	}
	return Plugin_Continue;
}

public Action:LogHook(const String:message[])
{
	if (g_bBlockLog)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bBlockLog = false;
	if (g_bPreGame)
	{
		new iUserId = GetEventInt(event, "userid");
		new iClient = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (iClient && GetConVarBool(g_hVarStats))
		{
			g_iFrags[iClient]++;
			if (!IsFakeClient(iClient))
			{
				PrintHintText(iClient, "TeamKills: %i", g_iFrags[iClient]);
			}
		}
		CreateTimer(0.3, Timer_Spawn, iUserId);
	}
}

public Action:Timer_Spawn(Handle:timer, any:userid)
{
	if (g_bPreGame)
	{
		new client = GetClientOfUserId(userid);
		if (client)
		{
			TF2_RespawnPlayer(client);
		}
	}
	return Plugin_Handled;
}

/*
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	switch (g_RoundState)
	{
		case newMap:
		{
			g_RoundState = preGame;
		}
		case preGame:
		{
			g_RoundState = normal;
		}
		case lateLoad:
		{
			g_RoundState = normal;
		}
	}
	if (g_RoundState == preGame)
	{
		StartPreGame();
	}
	else StopPreGame();
}*/

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bPreGame)
	{
		CreateTimer(0.1, Timer_Cond, GetEventInt(event, "userid"));
	}
}

public Action:Timer_Cond(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client && IsPlayerAlive(client))
	{
		if (g_bPreGame)
		{
			if (g_bMelee)
			{
				RemoveWeapons(client);
			}
			else
			{
				RemoveFlameMedi(client);
			}
		}
		CreateTimer(0.1, Timer_SetCond, GetClientUserId(client));
	}
	return Plugin_Handled;
}

public Action:Timer_SetCond(Handle:timer, any:id)
{
	new client = GetClientOfUserId(id);
	if (g_bPreGame && client && IsPlayerAlive(client))
	{
		TF2_AddCondition(client, TFCond_InHealRadius, GetConVarFloat(g_hVarTime));
		if (g_Crits == noCrit)
			return Plugin_Handled;
		if (g_Crits == fullCrit)
		{
			TF2_AddCondition(client, TFCond_Kritzkrieged, GetConVarFloat(g_hVarTime));
		}
		else
			TF2_AddCondition(client, TFCond_Buffed, GetConVarFloat(g_hVarTime));
	}
	return Plugin_Handled;
}

stock RemoveFlameMedi(client)
{
	new TFClassType:iClass = TF2_GetPlayerClass(client),
		iWeapon = -1;
	if (iClass == TFClass_Pyro)
	{	
		iWeapon = GetPlayerWeaponSlot(client, 0);
		if (iWeapon != -1)
		{
			TF2_RemoveWeaponSlot(client, 0);
		}
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 1));
	}
	if (iClass == TFClass_Medic)
	{
		iWeapon = GetPlayerWeaponSlot(client, 1);
		if (iWeapon != -1)
		{
			TF2_RemoveWeaponSlot(client, 1);
		}
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 0));
	}
}

stock RemoveWeapons(client)
{
	for (new i; i < 5; i++)
	{
		if (i != 2)
		{
			if (GetPlayerWeaponSlot(client, i))
			{
				TF2_RemoveWeaponSlot(client, i);
			}
		}
	}
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
}

stock StartPreGame()
{
	g_bPreGame = true;
	SetConVarBool(FindConVar("mp_friendlyfire"), true);
	SetConVarBool(FindConVar("tf_avoidteammates"), false);
	ModifyLockers("disable");
	RespawnAll();
	g_iTimeLeft = GetConVarInt(g_hVarTime);
	CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
	
	char lock[32];
	char openClose[32];
	bool bLock;
	SetGlobalCrits();
	SetGlobalMelee();
	switch (e_Door:GetConVarInt(g_hVarDoors))
	{
		case dontTouch:
		{
			return;
		}
		case open:
		{
			bLock = false;
			//Format(lock, sizeof(lock), "unlock");
			//Format(openClose, sizeof(openClose), "open");
		}
		case close:
		{
			bLock = true;
			//Format(lock, sizeof(lock), "lock");
			//Format(openClose, sizeof(openClose), "close");
		}
		case randomDoor:
		{
			switch (GetRandomInt(1,3))
			{
				case 1:
				{
					bLock = false;
				}
				case 2:
				{
					bLock = true;
				}
				case 3:
				{
					return;
				}
			}
		}
	}
	if (bLock)
	{
		Format(lock, sizeof(lock), "lock");
		Format(openClose, sizeof(openClose), "close");
	}
	else
	{
		Format(lock, sizeof(lock), "unlock");
		Format(openClose, sizeof(openClose), "open");
	}
	ModifyDoors(lock, openClose);
}

SetGlobalMelee()
{
	switch (e_Melee:GetConVarInt(g_hVarMelee))
	{
		case meleeOnly:
		{
			g_bMelee = true;
		}
		case randomMelee:
		{
			if (GetRandomInt(0,1))
			{
				g_bMelee = true;
			}
			else
				g_bMelee = false;
		}
		case allowAll:
		{
			g_bMelee = false;
		}
	}
}

SetGlobalCrits()
{
	switch (e_Crits:GetConVarInt(g_hVarCrits))
	{
		case miniCrit:
		{
			g_Crits = miniCrit;
			//TF2_AddCondition(client, TFCond_Buffed, GetConVarFloat(g_hVarTime));
		}
		case fullCrit:
		{
			g_Crits = fullCrit;
			//TF2_AddCondition(client, TFCond_Kritzkrieged, GetConVarFloat(g_hVarTime));
		}
		case noCrit:
		{
			g_Crits = noCrit;
		}
		case randomCrit:
		{
			switch (GetRandomInt(1,3))
			{
				case 1:
				{
					g_Crits = miniCrit;
				}
				case 2:
				{
					g_Crits = fullCrit;
				}
				case 3:
				{
					g_Crits = noCrit;
				}
			}
		}
	}
}

ModifyDoors(const char[] lock, const char[] openOrClose)
{
	new ent = MAXPLAYERS+1;
	while((ent = FindEntityByClassname(ent, "func_door"))!=-1) 
	{
		if (IsValidEdict(ent))
		{
			AcceptEntityInput(ent, lock, -1);
			AcceptEntityInput(ent, openOrClose, -1);
		}
	}
	
	ent = MAXPLAYERS+1;
	while((ent = FindEntityByClassname(ent, "prop_dynamic"))!=-1) 
	{
		if (IsValidEdict(ent))
		{
			new String:tName[64];
			GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
			if ((StrContains(tName,"door",false)!=-1) || (StrContains(tName,"gate",false)!=-1))
			{
				AcceptEntityInput(ent, lock, -1);
				AcceptEntityInput(ent, openOrClose, -1);
			}
		}
	}
}

public Action:Timer_CountDown(Handle:timer)
{
	g_iTimeLeft--;
	if (g_iTimeLeft == 0)
	{
		return Plugin_Stop;
	}
	else
		return Plugin_Continue;
}

stock RespawnAll()
{
	for (new i=1; i<= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && TF2_GetPlayerClass(i) != TFClass_Unknown)
		{
			TF2_RespawnPlayer(i);
		}
	}
}

stock StopPreGame()
{
	if (g_bPreGame)
	{
		CreateTimer(1.0, Timer_RemoveEffects);
		g_bPreGame = false;
		SetConVarBool(FindConVar("mp_friendlyfire"), false);
		SetConVarBool(FindConVar("tf_avoidteammates"), true);
		ModifyLockers("enable");
		if (GetConVarBool(g_hVarStats) && GetTeamClientCount(2) > 2 && GetTeamClientCount(3) > 2)
		{
			CreateTimer(0.5, Timer_Winners);
		}
		/**
		AddNotify("mp_friendlyfire");
		AddNotify("sv_tags");
		AddNotify("tf_avoidteammates");
		*/
	}
}

public Action:Timer_RemoveEffects(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			TF2_RemoveCondition(i, TFCond_Buffed);
			TF2_RemoveCondition(i, TFCond_Kritzkrieged);
			TF2_RemoveCondition(i, TFCond_InHealRadius);
		}
	}
}
			
public Action:Timer_Winners(Handle:timer)
{
	new iRedScores[MaxClients][2],
		iBluScores[MaxClients][2],
		iRedCount,
		iBluCount;
	for (new i = 1; i<= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				iRedScores[iRedCount][0] = i;
				iRedScores[iRedCount++][1] = g_iFrags[i];
			}
			if (GetClientTeam(i) == 3)
			{
				iBluScores[iBluCount][0] = i;
				iBluScores[iBluCount++][1] = g_iFrags[i];
			}
		}
	}
	if (iRedCount && iBluCount)
	{
		decl String:sNameBuffer[MAX_NAME_LENGTH+1];
		decl String:sBuffer[255];
		SortCustom2D(iRedScores, iRedCount, SortIntsDesc);
		SortCustom2D(iBluScores, iBluCount, SortIntsDesc);
		new Handle:hMenu = CreatePanel();
		DrawPanelText(hMenu, "Red Team Winners\n");
		for (new i; i < 3; i++)
		{
			if (IsClientInGame(iRedScores[i][0]))
			{
				GetClientName(iRedScores[i][0], sNameBuffer, sizeof(sNameBuffer));
				Format(sBuffer, sizeof(sBuffer), "%i  '%i' Frags: %s", i+1, iRedScores[i][1], sNameBuffer);
				DrawPanelText(hMenu, sBuffer);
			}
		}
		DrawPanelText(hMenu, "-----------------");
		DrawPanelText(hMenu, "Blue Team Winners\n");
		for (new i; i < 3; i++)
		{
			if (IsClientInGame(iBluScores[i][0]))
			{
				GetClientName(iBluScores[i][0], sNameBuffer, sizeof(sNameBuffer));
				Format(sBuffer, sizeof(sBuffer), "%i  '%i' Frags: %s", i+1, iBluScores[i][1], sNameBuffer);
				DrawPanelText(hMenu, sBuffer);
			}
		}
		DrawPanelItem(hMenu, "exit");
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i) && g_iMenuSettings[i] != -1)
			{
				SendPanelToClient(hMenu, i, Panel_Callback, 20);
			}
		}
	}
	return Plugin_Handled;
}

public Panel_Callback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public SortIntsDesc(x[], y[], array[][], Handle:data)		// this sorts everything in the info array descending
{
    if (x[1] > y[1]) 
		return -1;
    else if (x[1] < y[1]) 
		return 1;    
    return 0;
}

public OnMapStart()
{
	StripNotify("mp_friendlyfire");
	StripNotify("sv_tags");
	StripNotify("tf_avoidteammates");
	/*if (g_RoundState != lateLoad)
	{
		g_RoundState = newMap;
	}
	else
	{
		g_RoundState = normal;
	}
	g_bPreGame = false;*/
}

public TF2_OnWaitingForPlayersStart()
{
	StartPreGame();
}

public TF2_OnWaitingForPlayersEnd()
{
	StopPreGame();
}

stock StripNotify(const String:setting[])
{
	new Handle:hVar, iFlags;
	hVar = FindConVar(setting);
	if (hVar != INVALID_HANDLE)
	{
		iFlags = GetConVarFlags(hVar);
		if (iFlags & FCVAR_NOTIFY)
		{
			SetConVarFlags(hVar, iFlags &~FCVAR_NOTIFY);
		}
	}
}

stock AddNotify(const String:setting[])
{
	new Handle:hVar, iFlags;
	hVar = FindConVar(setting);
	if (hVar != INVALID_HANDLE)
	{
		iFlags = GetConVarFlags(hVar);
		if (!(iFlags & FCVAR_NOTIFY))
		{
			SetConVarFlags(hVar, iFlags |FCVAR_NOTIFY);
		}
	}
}

stock ModifyLockers(const String:input[]) 
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "func_regenerate")) != -1) 
	{
		AcceptEntityInput(iEnt, input);
	}
}