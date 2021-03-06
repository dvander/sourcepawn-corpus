/************************************************************************
*************************************************************************
Simple TF2 Class Notifier
Description:
 *			Notifies players on the same team when a class is to low or to high
 *			Only notifies players on the appropriate class (other classes if low, target class if high)
 *			Ability to change warning displays (player/team)
 *			Ability to change warning mode(chat/center/hint)
 *			Ability to set min player threshold
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

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
$Id: simple-chatcolors.sp 99 2010-01-09 09:15:27Z antithasys $
$Author: antithasys $
$Revision: 99 $
$Date: 2010-01-09 03:15:27 -0600 (Sat, 09 Jan 2010) $
$LastChangedBy: antithasys $
$LastChangedDate: 2010-01-09 03:15:27 -0600 (Sat, 09 Jan 2010) $
$URL: https://sm-simple-plugins.googlecode.com/svn/trunk/Simple%20Chat%20Colors/addons/sourcemod/scripting/simple-chatcolors.sp $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

#define MAX_STRING_LEN 64
#define MAXCLASSES 10
#define TEAM_RED 2
#define TEAM_BLUE 3
#define MODE_PLAYER 1
#define MODE_TEAM 2
#define MSGMODE_CHAT 1
#define MSGMODE_CENTER 2
#define MSGMODE_HINT 3

new Handle:clsnote_enabled = INVALID_HANDLE,
	Handle:clsnote_threshold = INVALID_HANDLE,
	Handle:clsnote_warningads = INVALID_HANDLE,
	Handle:clsnote_warningmode = INVALID_HANDLE,
	Handle:clsnote_warning_repeat_time = INVALID_HANDLE,
	Handle:clsnote_debug = INVALID_HANDLE,
	Handle:g_hHighLimits[4][MAXCLASSES],
	Handle:g_hLowLimits[4][MAXCLASSES],
	Handle:g_hClassTimers[4][MAXCLASSES],
	g_iPlayerLastClass[MAXPLAYERS + 1],
	g_iThreshold,
	g_iWarningAds,
	g_iMessageMode,
	Float:g_fCycleTime,
	bool:g_bDebug = false,
	bool:g_bIsEnabled = false;

new String:TFClassStrings[MAXCLASSES][10] = {"Unknown",
									"Scout",
									"Sniper",
									"Soldier",
									"Demoman",
									"Medic",
									"Heavy",
									"Pyro",
									"Spy",
									"Engineer"};

public Plugin:myinfo =
{
	name = "Simple TF2 Class Notifier",
	author = "Simple Plugins",
	description = "Notifies players on the same team when a class is to low or to high",
	version = PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
}

public OnPluginStart()
{
	CreateConVar("clsnote_version", PLUGIN_VERSION, "Class Notifier", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	clsnote_enabled = CreateConVar("clsnote_enabled", "1", "Enables/Disables Class Notifier", _, true, 0.0, true, 1.0);
	clsnote_threshold = CreateConVar("clsnote_threshold", "20", "Player threshold to start notifications");
	clsnote_warningads = CreateConVar("clsnote_warningads", "2", "1 = Player | 2 = Team", _, true, 1.0, true, 2.0);
	clsnote_warningmode = CreateConVar("clsnote_warningmode", "3", "1 = Chat | 2 = Center | 3 = Hint", _, true, 1.0, true, 3.0);
	clsnote_warning_repeat_time = CreateConVar("clsnote_warning_repeat_time", "300.0", "Warning ad repeat time: 60.0 = 1 min ads");	
	clsnote_debug = CreateConVar("clsnote_debug", "0", "Enables/Disables debug mode");
	g_hHighLimits[2][1] = CreateConVar("clsnote_highlimit_red_scouts", "6", "Upper limit for Red scouts in TF2.");
	g_hHighLimits[2][2] = CreateConVar("clsnote_highlimit_red_snipers", "6", "Upper limit for Red snipers in TF2.");
	g_hHighLimits[2][3] = CreateConVar("clsnote_highlimit_red_soldiers", "6", "Upper limit for Red soldiers in TF2.");
	g_hHighLimits[2][4] = CreateConVar("clsnote_highlimit_red_demomen", "6", "Upper limit for Red demomen in TF2.");
	g_hHighLimits[2][5] = CreateConVar("clsnote_highlimit_red_medics", "6", "Upper limit for Red medics in TF2.");
	g_hHighLimits[2][6] = CreateConVar("clsnote_highlimit_red_heavies", "6", "Upper limit for Red heavies in TF2.");
	g_hHighLimits[2][7] = CreateConVar("clsnote_highlimit_red_pyros", "6", "Upper limit for Red pyros in TF2.");
	g_hHighLimits[2][8] = CreateConVar("clsnote_highlimit_red_spies", "6", "Upper limit for Red spies in TF2.");
	g_hHighLimits[2][9] = CreateConVar("clsnote_highlimit_red_engineers", "6", "Upper limit for Red engineers in TF2.");
	g_hHighLimits[3][1] = CreateConVar("clsnote_highlimit_blu_scouts", "6", "Upper limit for Blu scouts in TF2.");
	g_hHighLimits[3][2] = CreateConVar("clsnote_highlimit_blu_snipers", "6", "Upper limit for Blu snipers in TF2.");
	g_hHighLimits[3][3] = CreateConVar("clsnote_highlimit_blu_soldiers", "6", "Upper limit for Blu soldiers in TF2.");
	g_hHighLimits[3][4] = CreateConVar("clsnote_highlimit_blu_demomen", "6", "Upper limit for Blu demomen in TF2.");
	g_hHighLimits[3][5] = CreateConVar("clsnote_highlimit_blu_medics", "6", "Upper limit for Blu medics in TF2.");
	g_hHighLimits[3][6] = CreateConVar("clsnote_highlimit_blu_heavies", "6", "Upper limit for Blu heavies in TF2.");
	g_hHighLimits[3][7] = CreateConVar("clsnote_highlimit_blu_pyros", "6", "Upper limit for Blu pyros in TF2.");
	g_hHighLimits[3][8] = CreateConVar("clsnote_highlimit_blu_spies", "6", "Upper limit for Blu spies in TF2.");
	g_hHighLimits[3][9] = CreateConVar("clsnote_highlimit_blu_engineers", "6", "Upper limit for Blu engineers in TF2.");
	g_hLowLimits[2][1] = CreateConVar("clsnote_lowlimit_red_scouts", "0", "Lower limit for Red scouts in TF2.");
	g_hLowLimits[2][2] = CreateConVar("clsnote_lowlimit_red_snipers", "0", "Lower limit for Red snipers in TF2.");
	g_hLowLimits[2][3] = CreateConVar("clsnote_lowlimit_red_soldiers", "0", "Lower limit for Red soldiers in TF2.");
	g_hLowLimits[2][4] = CreateConVar("clsnote_lowlimit_red_demomen", "0", "Lower limit for Red demomen in TF2.");
	g_hLowLimits[2][5] = CreateConVar("clsnote_lowlimit_red_medics", "0", "Lower limit for Red medics in TF2.");
	g_hLowLimits[2][6] = CreateConVar("clsnote_lowlimit_red_heavies", "0", "Lower limit for Red heavies in TF2.");
	g_hLowLimits[2][7] = CreateConVar("clsnote_lowlimit_red_pyros", "0", "Lower limit for Red pyros in TF2.");
	g_hLowLimits[2][8] = CreateConVar("clsnote_lowlimit_red_spies", "0", "Lower limit for Red spies in TF2.");
	g_hLowLimits[2][9] = CreateConVar("clsnote_lowlimit_red_engineers", "0", "Lower limit for Red engineers in TF2.");
	g_hLowLimits[3][1] = CreateConVar("clsnote_lowlimit_blu_scouts", "0", "Lower limit for Blu scouts in TF2.");
	g_hLowLimits[3][2] = CreateConVar("clsnote_lowlimit_blu_snipers", "0", "Lower limit for Blu snipers in TF2.");
	g_hLowLimits[3][3] = CreateConVar("clsnote_lowlimit_blu_soldiers", "0", "Lower limit for Blu soldiers in TF2.");
	g_hLowLimits[3][4] = CreateConVar("clsnote_lowlimit_blu_demomen", "0", "Lower limit for Blu demomen in TF2.");
	g_hLowLimits[3][5] = CreateConVar("clsnote_lowlimit_blu_medics", "0", "Lower limit for Blu medics in TF2.");
	g_hLowLimits[3][6] = CreateConVar("clsnote_lowlimit_blu_heavies", "0", "Lower limit for Blu heavies in TF2.");
	g_hLowLimits[3][7] = CreateConVar("clsnote_lowlimit_blu_pyros", "0", "Lower limit for Blu pyros in TF2.");
	g_hLowLimits[3][8] = CreateConVar("clsnote_lowlimit_blu_spies", "0", "Lower limit for Blu spies in TF2.");
	g_hLowLimits[3][9] = CreateConVar("clsnote_lowlimit_blu_engineers", "0", "Lower limit for Blu engineers in TF2.");
	HookConVarChange(clsnote_enabled, ConVarSettingsChanged);
	HookConVarChange(clsnote_threshold, ConVarSettingsChanged);
	HookConVarChange(clsnote_warningads, ConVarSettingsChanged);
	HookConVarChange(clsnote_warningmode, ConVarSettingsChanged);
	HookConVarChange(clsnote_warning_repeat_time, ConVarSettingsChanged);
	HookConVarChange(clsnote_debug, ConVarSettingsChanged);
	RegAdminCmd("sm_checkclasses", Command_CheckClasses, ADMFLAG_GENERIC, "Check all the classes against the limits");
	if (!HookEventEx("player_changeclass", HookChangeClass, EventHookMode_Post)) 
	{
		SetFailState("Could not hook an event.");
		return;
	}
	AutoExecConfig(true, "plugin.classnotifier");
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(clsnote_enabled);
	g_bDebug = GetConVarBool(clsnote_debug);
	g_iThreshold = GetConVarInt(clsnote_threshold);
	g_iWarningAds = GetConVarInt(clsnote_warningads);
	g_iMessageMode = GetConVarInt(clsnote_warningmode);
	g_fCycleTime = GetConVarFloat(clsnote_warning_repeat_time);
	if (g_bIsEnabled)
	{
		LogAction(0, -1, "[CLSNOTE] Class notifier is loaded and enabled.");
	} 
	else
	{
		LogAction(0, -1, "[CLSNOTE] Class notifier is loaded and disabled.");
	}
}

public OnClientDisconnect_Post(client)
{
	g_iPlayerLastClass[client] = 0;
	
	/**
	If we dropped below the threshold then stop the notifications
	*/
	if (GetClientCount() < g_iThreshold)
	{
		CleanUp();
	}
}

public OnMapEnd()
{
	CleanUp();
}

/**
Commands
*/
public Action:Command_CheckClasses(client, args)
{
	CleanUp();
	LoadUpClasses();
	CheckAllClasses();
	ReplyToCommand(client, "Classes checked");
	return Plugin_Handled;
}

public Action:HookChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient    		= GetClientOfUserId(GetEventInt(event, "userid")),
			iNewClass   	= GetEventInt(event, "class"),
			iTeam       	= GetClientTeam(iClient);
	
	/**
	If they dont have a class because of map load or late load, make old class current class
	**/
	if (g_iPlayerLastClass[iClient] == 0)
	{
		g_iPlayerLastClass[iClient] = iNewClass;
	}
	
	if (g_bIsEnabled 
		&& iClient != 0
		&& GetClientCount() >= g_iThreshold) 
	{
		/**
		We are enabled and should process the class, but lets let the event finish so we delay the check
		**/
		new Handle:hProcessPack;
		CreateDataTimer(0.2, Timer_ProcessClass, hProcessPack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(hProcessPack, iClient);
		WritePackCell(hProcessPack, iTeam);
		WritePackCell(hProcessPack, g_iPlayerLastClass[iClient]);
		WritePackCell(hProcessPack, iNewClass);
		g_iPlayerLastClass[iClient] = iNewClass;
	} 
	else
	{
		/**
		We shouldn't process the class but we still need to track the class of the client
		**/
		g_iPlayerLastClass[iClient] = iNewClass;
	}
	return Plugin_Continue;
}

public Action:Timer_ProcessClass(Handle:timer, any:pack)
{
	ResetPack(pack);
	new iClient		= ReadPackCell(pack),
			iTeam 		= ReadPackCell(pack),
			iOldClass	= ReadPackCell(pack),
			iNewClass	= ReadPackCell(pack);
	
	ProcessClass(iClient, iTeam, iOldClass, iNewClass);
	
	return Plugin_Handled;
}

public Action:Timer_LastMan(Handle:timer, any:pack)
{
	ResetPack(pack);
	new	iClient	= ReadPackCell(pack),
			iClass	= ReadPackCell(pack),
			iTeam 	= GetClientTeam(iClient);
	decl String:sLevel[5];
	ReadPackString(pack, sLevel, sizeof(sLevel));
	new bool:bClassLow = IsLow(iTeam, iClass);
	new bool:bClassHigh = IsHigh(iTeam, iClass);
	
	if (!bClassLow && !bClassHigh) 
	{
		return Plugin_Handled;
	}
	
	ProcessClassWarnings(iClient, iTeam, iClass, sLevel);
	return Plugin_Handled;
}

public Action:Timer_WarningAdFirstRun(Handle:timer, any:pack)
{
	ResetPack(pack);
	new	iTeam	= ReadPackCell(pack),
		iClass	= ReadPackCell(pack);
	decl String:sLevel[5];
	ReadPackString(pack, sLevel, sizeof(sLevel));
	new bool:bClassLow = IsLow(iTeam, iClass);
	new bool:bClassHigh = IsHigh(iTeam, iClass);
	
	if (!bClassLow && !bClassHigh) 
	{
		g_hClassTimers[iTeam][iClass] = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	ProcessClassWarnings(0, iTeam, iClass, sLevel);
	return Plugin_Handled;
}

public Action:Timer_WarningAd(Handle:timer, any:pack)
{
	ResetPack(pack);
	new	iTeam	= ReadPackCell(pack),
		iClass	= ReadPackCell(pack);
	decl String:sLevel[5];
	ReadPackString(pack, sLevel, sizeof(sLevel));
	new bool:bClassLow = IsLow(iTeam, iClass);
	new bool:bClassHigh = IsHigh(iTeam, iClass);
	
	if (!bClassLow && !bClassHigh) 
	{
		g_hClassTimers[iTeam][iClass] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	ProcessClassWarnings(0, iTeam, iClass, sLevel);
	return Plugin_Continue;
}

public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == clsnote_enabled) {
		if (StringToInt(newValue) == 0) {
			g_bIsEnabled = false;
			LogAction(0, -1, "[CLSNOTE] Class notifier is loaded and disabled.");
		} else {
			CleanUp();
			LoadUpClasses();
			CheckAllClasses();
			g_bIsEnabled = true;
			LogAction(0, -1, "[CLSNOTE] Class notifier is loaded and enabled.");
		}
	} else if (convar == clsnote_warning_repeat_time) {
		g_fCycleTime = StringToFloat(newValue);
	} else if (convar == clsnote_warningads) {
		g_iWarningAds = StringToInt(newValue);
	} else if (convar == clsnote_warningmode) {
		g_iMessageMode = StringToInt(newValue);
	} else if (convar == clsnote_threshold) {
		g_iThreshold = StringToInt(newValue);
	} else if (convar == clsnote_debug) {
		if (StringToInt(newValue) == 0)
			g_bDebug = false;
		else
			g_bDebug = true;
	}
}		

stock LoadUpClasses()
{

	/**
	Load up all the current classes of the players
	**/
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i))
		{
			g_iPlayerLastClass[i] = _:TF2_GetPlayerClass(i);
		}
	}
	if (g_bDebug)
	{
		PrintToChatAll("Loaded up all the current classes");
	}
}

stock CheckAllClasses()
{
	
	new iAddCycleTime = 5;
	for (new i = 1; i < MAXCLASSES; i++) 
	{
		ProcessClass(0, TEAM_RED, i, i, FloatAdd(g_fCycleTime, float(iAddCycleTime)));
		ProcessClass(0, TEAM_BLUE, i, i, FloatAdd(g_fCycleTime, float(iAddCycleTime)));
		iAddCycleTime += 5;
	}
	if (g_bDebug)
	{
		PrintToChatAll("Checking all the current classes");
	}
}

stock ProcessClass(iClient, iTeam, iOldClass, iNewClass, Float:fCycleTime = 0.0)
{
	new bool:bOldClassLow = IsLow(iTeam, iOldClass);
	new bool:bNewClassLow = IsLow(iTeam, iNewClass);
	new bool:bNewClassHigh = IsHigh(iTeam, iNewClass);
	
	if (g_bDebug)
	{
		PrintToChatAll("%s Class Low:%b", TFClassStrings[iOldClass], bOldClassLow);
		PrintToChatAll("%s Class Low:%b", TFClassStrings[iNewClass], bNewClassLow);
		PrintToChatAll("%s Class High:%b", TFClassStrings[iNewClass], bNewClassHigh);
	}
	
	if (fCycleTime == 0.0)
	{
		fCycleTime = g_fCycleTime;
	}
	
	/**
	If the old class is low, display the warnings and start the timers based on warning mode
	**/
	if (bOldClassLow) 
	{
		decl String:sLevel[5];
		Format(sLevel, sizeof(sLevel), "low");
		switch (g_iWarningAds)
		{
			case MODE_TEAM:
			{
				if (g_hClassTimers[iTeam][iOldClass] == INVALID_HANDLE) 
				{
					new Handle:hAd1Pack;
					CreateDataTimer(2.0, Timer_WarningAdFirstRun, hAd1Pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(hAd1Pack, iTeam);
					WritePackCell(hAd1Pack, iOldClass);
					WritePackString(hAd1Pack, sLevel);
					new Handle:hAd2Pack;
					g_hClassTimers[iTeam][iOldClass] = CreateDataTimer(fCycleTime, Timer_WarningAd, hAd2Pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(hAd2Pack, iTeam);
					WritePackCell(hAd2Pack, iOldClass);
					WritePackString(hAd2Pack, sLevel);
				}
			}
			case MODE_PLAYER:
			{
				if (!bNewClassLow) 
				{
					new Handle:hPlayerPack;
					CreateDataTimer(2.0, Timer_LastMan, hPlayerPack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(hPlayerPack, iClient);
					WritePackCell(hPlayerPack, iOldClass);
					WritePackString(hPlayerPack, sLevel);
				}
			}
		}
	}
	
	/**
	If the new class is high or low, display the warnings and start the timers based on warning mode
	**/
	if (bNewClassHigh || bNewClassLow) 
	{
		decl String:sLevel[5];
		if (bNewClassHigh)
			Format(sLevel, sizeof(sLevel), "high");
		else
			Format(sLevel, sizeof(sLevel), "low");
		switch (g_iWarningAds)
		{
			case MODE_TEAM:
			{
				if (g_hClassTimers[iTeam][iNewClass] == INVALID_HANDLE) 
				{
					new Handle:hAd1Pack;
					CreateDataTimer(2.0, Timer_WarningAdFirstRun, hAd1Pack, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(hAd1Pack, iTeam);
					WritePackCell(hAd1Pack, iNewClass);
					WritePackString(hAd1Pack, sLevel);
					new Handle:hAd2Pack;
					g_hClassTimers[iTeam][iNewClass] = CreateDataTimer(fCycleTime, Timer_WarningAd, hAd2Pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(hAd2Pack, iTeam);
					WritePackCell(hAd2Pack, iNewClass);
					WritePackString(hAd2Pack, sLevel);
				}
			} 
			case MODE_PLAYER:
			{
				new Handle:hPlayerPack;
				CreateDataTimer(2.0, Timer_LastMan, hPlayerPack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(hPlayerPack, iClient);
				WritePackCell(hPlayerPack, iNewClass);
				WritePackString(hPlayerPack, sLevel);
			}
		}
	}
	
	/**
	If the new class isn't high or low cancel any timers
	**/
	if (!bNewClassLow && !bNewClassHigh) 
	{
		if (g_hClassTimers[iTeam][iNewClass] != INVALID_HANDLE) 
		{
			CloseHandle(g_hClassTimers[iTeam][iNewClass]);
			g_hClassTimers[iTeam][iNewClass] = INVALID_HANDLE;
		}
	}
}

stock ProcessClassWarnings(iClient, iTeam, iClass, const String:sLevel[])
{
	switch (g_iWarningAds)
	{
		case MODE_PLAYER:
		{
			if (iClient > 0 && IsClientInGame(iClient)) {
				PrintTheMessage(iClient, iTeam, iClass, sLevel);
			}
		}
		case MODE_TEAM:
		{
			for (new i = 1; i <= MaxClients; i++) {
				if (StrEqual(sLevel, "low", false)) {
					if (IsClientInGame(i) && GetClientTeam(i) == iTeam && _:TF2_GetPlayerClass(i) != iClass) {
						PrintTheMessage(i, iTeam, iClass, sLevel);
					}
				} else {
					if (IsClientInGame(i) && GetClientTeam(i) == iTeam && _:TF2_GetPlayerClass(i) == iClass) {
						PrintTheMessage(i, iTeam, iClass, sLevel);
					}
				}
			}
		}
	}
	return;
}

stock PrintTheMessage(iClient, iTeam, iClass, const String:sLevel[])
{
	new iClassCount = GetClassCount(iClass, iTeam);
	switch (g_iMessageMode)
	{
		case MSGMODE_CHAT:
		{
			PrintToChat(iClient, "\x01\x04[CLASSES] \x01Your team is \x04%s\x01 on \x01\x04%ss\x01 and has \x01\x04%i\x01. PLEASE \x01\x04use your brain \x01and consider \x01\x04switching \x01to a \x01\x04different class!", sLevel, TFClassStrings[iClass], iClassCount);
		}
		case MSGMODE_CENTER:
		{
			PrintCenterText(iClient, "Your team is [%s] on [%s] and has [%i] Consider switching!", sLevel, TFClassStrings[iClass], iClassCount);
		}
		case MSGMODE_HINT:
		{
			PrintHintText(iClient, "Your team is [%s] on [%s] and has [%i] Consider switching!", sLevel, TFClassStrings[iClass], iClassCount);
		}
	}
}

stock GetClassCount(iClass, iTeam)
{
	new iCount = 0;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) 
		&& GetClientTeam(i) == iTeam 
		&& _:TF2_GetPlayerClass(i) == iClass) {
			iCount++;
		}
	}
	return iCount;
}

stock CleanUp()
{
	for (new i = 0; i < MAXCLASSES; i++) {
		if (g_hClassTimers[TEAM_RED][i] != INVALID_HANDLE) {
			CloseHandle(g_hClassTimers[TEAM_RED][i]);
		}
		g_hClassTimers[TEAM_RED][i] = INVALID_HANDLE;
		if (g_hClassTimers[TEAM_BLUE][i] != INVALID_HANDLE) {
			CloseHandle(g_hClassTimers[TEAM_BLUE][i]);
		}
		g_hClassTimers[TEAM_BLUE][i] = INVALID_HANDLE;
	}
}

stock bool:IsLow(iTeam, iClass) 
{
	if (iTeam > 1 && iClass > 0) {
		new iClassCount = GetClassCount(iClass, iTeam);
		new iLimit = GetConVarInt(g_hLowLimits[iTeam][iClass]);
		if (iLimit > 0 && iClassCount < iLimit) {
			return true;
		}
	}
	return false;
}

stock bool:IsHigh(iTeam, iClass) 
{
	if (iTeam > 1 && iClass > 0) {
		new iClassCount = GetClassCount(iClass, iTeam);
		new iLimit = GetConVarInt(g_hHighLimits[iTeam][iClass]);
		if (iLimit > 0 && iClassCount >= iLimit) {
			return true;
		}
	}
	return false;
}