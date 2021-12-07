#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <psyrtd>

#undef REQUIRE_EXTENSIONS
#undef AUTOLOAD_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS

#define PLUGIN_NAME "psyRTD Core"
#define PLUGIN_VERSION "1.0.1"

#define MSGTAG "\x01[\x04RTD\x01] \x03"

#define EFFECTSIZE 69

enum rtdEffect
{
	effectId,
	Handle:effectParent,
	Function:effectStartFunc,
	Function:effectEndFunc,
	Float:effectDuration,
	String:effectName[64]
};

enum rtdWaitMode
{
	WaitMode_All,
	WaitMode_Player
};

enum C_EndFunc
{
	Handle:CEFPlugin,
	Function:CEFFunc
};

// Cvars
new Handle:g_cvarGoodChance = INVALID_HANDLE;
new Handle:g_cvarWaitTime = INVALID_HANDLE;
new Handle:g_cvarWaitMode = INVALID_HANDLE;
new Handle:g_cvarWaitPenalty = INVALID_HANDLE;
new Handle:g_cvarAllowUnusable = INVALID_HANDLE;
new Handle:g_cvarAdminFlag = INVALID_HANDLE;
new Handle:g_cvarEnabled = INVALID_HANDLE;

new bool:g_bEnabled = true;

// Effect tracking
new g_iEffectId = 0;
new g_iEffectIdxMax[2] = { -1, ... };
new Handle:g_hEffects[2] = { INVALID_HANDLE, ... };
new Handle:g_hEffectTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

// Options
new Float:g_fGoodChance = 0.5;
new Float:g_fWaitTime = 120.0;
new rtdWaitMode:g_psyWaitMode = WaitMode_All;
new bool:g_bWaitPenalty = false;
new bool:g_bAllowUnusable = false;
new g_iAdminBit = 0;

// Client tracking
new Float:g_fLastRTD = 0.0;
new Float:g_fLastClientRTD[MAXPLAYERS+1] = { 0.0, ... };
new Handle:g_ClientEndFunc[MAXPLAYERS+1][C_EndFunc];


// Globals for aux natives
new psyRTDGame:g_psyGame = psyRTDGame_Unknown;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "psyduck",
	description = "RTD Controller",
	version = PLUGIN_VERSION,
	url = "http://www.nicholashastings.com"
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("psyrtd");
	
	CreateNative("psyRTD_RegisterEffect", Native_RegisterEffect);
	CreateNative("psyRTD_RegisterTimedEffect", Native_RegisterTimedEffect);
	CreateNative("psyRTD_ChangeEffectDuration", Native_ChangeEffectDuration);
	CreateNative("psyRTD_UnregisterEffect", Native_UnregisterEffect);
	CreateNative("psyRTD_UnregisterAllEffects", Native_UnregisterAllEffects);
	CreateNative("psyRTD_GetGame", Native_GetGame);
	CreateNative("psyRTD_PrintToChat", Native_PrintToChat);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	DetectGame();
	
	g_hEffects[psyRTDEffectType_Bad] = CreateArray(EFFECTSIZE);
	g_hEffects[psyRTDEffectType_Good] = CreateArray(EFFECTSIZE);
	
	CreateConVar("psyrtd_version", PLUGIN_VERSION, "RTD Controller", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvarEnabled = CreateConVar("psyrtd_enabled", "1", "Enable or disable psyRTD", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(g_cvarEnabled);
	g_cvarGoodChance = CreateConVar("psyrtd_goodchance", "0.5",
		"Decimal chance to roll a good effect versus a bad effect (between 0.0 and 1.0, default 0.5)",
		FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarWaitTime = CreateConVar("psyrtd_waittime", "120",
		"Time that must be waited between subsequent dice rolls (in seconds)",
		FCVAR_PLUGIN, true, 0.0);
	g_cvarWaitMode = CreateConVar("psyrtd_waitmode", "0",
		"Wait Mode. 0 (default) - Applies to whole server. 1 - Applies to each player individually.",
		FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarWaitPenalty = CreateConVar("psyrtd_waitpenalty", "0",
		"Reset wait timer if rtd is called again too soon. 0 (default) - Disabled. 1 - Enabled. Not recommended for wait mode 0.",
		FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarAllowUnusable = CreateConVar("psyrtd_allowunusable", "0",
		"Allow wasted rolls (no auto re-roll when rolling effect not applicable to current class/team)",
		FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvarAdminFlag = CreateConVar("psyrtd_adminflag", "",
		"Admin flag required to be able to use rtd (ex. \"b\") Default \"\" (none)",
		FCVAR_PLUGIN);
		
	// TODO: read cvar vals here to account for late load
	
	HookConVarChange(g_cvarEnabled, CvarEnabled);
	HookConVarChange(g_cvarGoodChance, CvarGoodChance);
	HookConVarChange(g_cvarWaitTime, CvarWaitTime);
	HookConVarChange(g_cvarWaitMode, CvarWaitMode);
	HookConVarChange(g_cvarWaitPenalty, CvarWaitPenalty);
	HookConVarChange(g_cvarAllowUnusable, CvarAllowUnusable);
	HookConVarChange(g_cvarAdminFlag, CvarAdminFlag);
	
	RegConsoleCmd("say", CommandSay);
	RegConsoleCmd("say2", CommandSay);  // for Insurgency
	RegConsoleCmd("say_team", CommandSay);
	
	RegConsoleCmd("rtd", CommandRTD);
	
	HookEvent("player_death", OnPlayerDeathEvent);
	
	AutoExecConfig(true, "psyrtd");
}

public bool:OnClientConnect(client)
{
	g_fLastClientRTD[client] = 0.0;
	return true;
}

public Action:CommandSay(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	
	decl String:szMessage[192];
	GetCmdArgString(szMessage, sizeof(szMessage));
	StripQuotes(szMessage);
	if (StrEqual(szMessage, "rtd"))
	{
		DoRTD(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:CommandRTD(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Handled;
	}
	
	DoRTD(client);
	return Plugin_Handled;
}

public DoRTD(client)
{
	if (!ClientCanRTD(client))
	{
		return;
	}
	
	new type = psyRTDEffectType_Bad;
	if (g_fGoodChance >= GetURandomFloat())
	{
		type = psyRTDEffectType_Good;
	}	
	
	new Handle: hBlockedEffects = INVALID_HANDLE;
	new iBlockedEffectsCnt = 0;
	decl String:szEffectName[64];
	
	new psyRTDAction:result = psyRTD_Reroll;
	
	decl effect[rtdEffect];
	for(;;)
	{
		if (iBlockedEffectsCnt == g_iEffectIdxMax[type]+1)
		{
			// No effect left
			if (hBlockedEffects != INVALID_HANDLE)
			{
				CloseHandle(hBlockedEffects);
			}
			// print no effect left message?
			return;
		}
		
		new iEffectId = GetRandomInt(0, g_iEffectIdxMax[type]);
		GetArrayArray(g_hEffects[type], iEffectId, effect, sizeof(effect));
		
		new bool:skip = false;
		if (hBlockedEffects != INVALID_HANDLE)
		{
			new eid = effect[effectId];
			for (new i = 0; i <= iBlockedEffectsCnt; i++)
			{
				if (eid == GetArrayCell(hBlockedEffects, i))
				{
					skip = true;
					break;
				}
			}
			if (skip)
			{
				continue;
			}
		}
		
		Call_StartFunction(effect[effectParent], effect[effectStartFunc]);
		Call_PushCell(client);
		Call_Finish(result);
		
		if (result == psyRTD_Continue)
		{
			if (hBlockedEffects != INVALID_HANDLE)
			{
				CloseHandle(hBlockedEffects);
			}
			strcopy(szEffectName, sizeof(szEffectName), effect[effectName]);
			break;
		}
		
		if (result == psyRTD_NotApplicable && g_bAllowUnusable)
		{
			// effect doesn't apply to player but allow-unusable is set
			// their roll is wasted. clean up and get out
			if (hBlockedEffects != INVALID_HANDLE)
			{
				CloseHandle(hBlockedEffects);
			}
			return;
		}
		
		// either explicit reroll (continue in loop) or n/a but unusables aren't allow (also reroll)
		
		if (hBlockedEffects == INVALID_HANDLE)
		{
			hBlockedEffects = CreateArray();
		}
		PushArrayCell(hBlockedEffects, effect[effectId]);
		iBlockedEffectsCnt++;
	}
	PrintToChatAll("%s%N rolled \"\x01%s\"\x01  %s", MSGTAG, client, szEffectName, (type == psyRTDEffectType_Bad)?"D:":":D");
	g_fLastRTD = GetEngineTime();
	g_fLastClientRTD[client] = GetEngineTime();
	new Float:duration = effect[effectDuration];
	if (duration > 0.0)
	{
		g_ClientEndFunc[client][CEFFunc] = effect[effectEndFunc];
		g_ClientEndFunc[client][CEFPlugin] = effect[effectParent];
		g_hEffectTimers[client] = CreateTimer(duration, OnEffectTimerEnd, GetClientUserId(client));
	}
}

public OnPlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_psyGame == psyRTDGame_TF && (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) == TF_DEATHFLAG_DEADRINGER)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0 || !IsClientInGame(client) || client > MAXPLAYERS)
	{
		// bad client
		return;
	}
	
	// is client in effect?  if so, kill it
	if (g_hEffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hEffectTimers[client]);
		OnEffectEnd(client, psyRTDEndReason_PlayerDied);
	}
}

public Action:OnEffectTimerEnd(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		// this should never be reached. if client disconnect, timer would have been closed
		OnEffectEnd(client, psyRTDEndReason_Unknown);
		return Plugin_Stop;
	}
	
	OnEffectEnd(client, psyRTDEndReason_TimeExpired);
	return Plugin_Stop;
}

public OnClientDisconnect(client)
{
	if (g_hEffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hEffectTimers[client]);
		OnEffectEnd(client, psyRTDEndReason_PlayerLeft);
	}
}

OnEffectEnd(client, psyRTDEffectEndReason:reason)
{
	if (g_ClientEndFunc[client][CEFFunc] == INVALID_FUNCTION)
	{
		return;
	}
	
	Call_StartFunction(g_ClientEndFunc[client][CEFPlugin], g_ClientEndFunc[client][CEFFunc]);
	Call_PushCell(client);
	Call_PushCell(reason);
	Call_Finish();
	
	g_ClientEndFunc[client][CEFPlugin] = INVALID_HANDLE;
	g_ClientEndFunc[client][CEFFunc] = INVALID_FUNCTION;
	g_hEffectTimers[client] = INVALID_HANDLE;
}

bool:ClientCanRTD(client)
{
	if (client < 1 || !IsClientInGame(client))
	{
		return false;
	}
	
	if (g_iAdminBit > 0 && !(GetUserFlagBits(client) & g_iAdminBit))
	{
		PrintToChat(client, "%sYou do not have permission to roll the dice.", MSGTAG);
		return false;
	}
	
	if (!IsPlayerAlive(client))
	{	
		PrintToChat(client, "%sYou must be alive to roll the dice.", MSGTAG);
		return false;
	}
	
	if (g_hEffectTimers[client] != INVALID_HANDLE)
	{
		PrintToChat(client, "%sYou must wait for your current RTD effect to wear off to roll the dice.", MSGTAG);
		return false;
	}
	
	switch(g_psyWaitMode)
	{
		case WaitMode_All:
		{
			new Float:fTimeCurrent = GetEngineTime();
			new Float:fTimeWaited = fTimeCurrent - g_fLastRTD;
			if (g_fWaitTime > fTimeWaited)
			{
				PrintToChat(client, "%sYou tried to reroll too soon. You must wait %d seconds between rolls. (%ds remaining)", MSGTAG, RoundFloat(g_fWaitTime), RoundFloat(g_fWaitTime-fTimeWaited));
				if (g_bWaitPenalty)
				{
					g_fLastRTD = GetEngineTime();
					PrintToChatAll("%s%N was greedy and reset the rtd timer for all.", MSGTAG, client);
				}
				
				return false;
			}
		}
		case WaitMode_Player:
		{
			new Float:fTime = GetEngineTime();
			if (g_fWaitTime > (fTime - g_fLastClientRTD[client]))
			{
				PrintToChat(client, "%sYou tried to reroll too soon. You must wait %d seconds between rolls.", MSGTAG, RoundFloat(g_fWaitTime));
				if (g_bWaitPenalty)
				{
					g_fLastClientRTD[client] = GetEngineTime();
					PrintToChat(client, "%sYour rtd timer was reset for being greedy :3", MSGTAG, RoundFloat(g_fWaitTime));
				}
			
				return false;
			}
		}
	}
	
	return true;
}

public Native_RegisterEffect(Handle:hPlugin, iNumParams)
{
	// RegisterPsyRTDEffect(psyRTDEffectType:effectType, const String:effectName[], psyRTDEffectCallback:func)
	new type = GetNativeCell(1);
	decl effect[rtdEffect];
	effect[effectId] = g_iEffectId++;
	effect[effectDuration] = 0.0;
	GetNativeString(2, effect[effectName], sizeof(effect[effectName]));
	//effect[effectFwd] = CreateForward(ET_Single, Param_Cell);
	effect[effectStartFunc] = GetNativeCell(3);
	effect[effectParent] = hPlugin;
	
//	if (!AddToForward(effect[effectFwd], hPlugin, GetNativeCell(3)))
//	{
		//decl String:szCallerName[PLATFORM_MAX_PATH];
		//GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
		//ThrowError("Failed to add forward from %s", szCallerName);
	//}
	
	PushArrayArray(g_hEffects[type], effect);
	g_iEffectIdxMax[type]++;
}

public Native_RegisterTimedEffect(Handle:hPlugin, iNumParams)
{
	// RegisterPsyRTDEffect(psyRTDEffectType:effectType, const String:effectName[], psyRTDEffectCallback:func)
	new type = GetNativeCell(1);
	decl effect[rtdEffect];
	effect[effectId] = g_iEffectId++;
	effect[effectDuration] = GetNativeCell(3);
	if (effect[effectDuration] < 0.9)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Cannot register a timed effect with duration less than 1 second.");
		return;
	}
	GetNativeString(2, effect[effectName], sizeof(effect[effectName]));
	//effect[effectFwd] = CreateForward(ET_Single, Param_Cell);
	//effect[effectKillFwd] = CreateForward(ET_Ignore);
	effect[effectStartFunc] = GetNativeCell(4);
	effect[effectEndFunc] = GetNativeCell(5);
	effect[effectParent] = hPlugin;
	
	/*
	if (!AddToForward(effect[effectFwd], hPlugin, GetNativeCell(4)))
	{
		decl String:szCallerName[PLATFORM_MAX_PATH];
		GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
		ThrowError("Failed to add start forward from %s", szCallerName);
	}
	
	if (!AddToForward(effect[effectKillFwd], hPlugin, GetNativeCell(5)))
	{
		decl String:szCallerName[PLATFORM_MAX_PATH];
		GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
		ThrowError("Failed to add end forward from %s", szCallerName);
	}
	*/
	
	PushArrayArray(g_hEffects[type], effect);
	g_iEffectIdxMax[type]++;
}

public Native_ChangeEffectDuration(Handle:hPlugin, iNumParams)
{
	new iRTDEffectId = GetNativeCell(1);
	new type = GetNativeCell(2);
	
	if (g_iEffectIdxMax[type] == -1)
	{
		return;
	}
	
	for (new i = 0; i <= g_iEffectIdxMax[type]; i++)
	{
		decl effect[rtdEffect];
		GetArrayArray(g_hEffects[type], i, effect, sizeof(effect));
		if (effect[effectId] == iRTDEffectId)
		{
			if (effect[effectDuration] < 0.9)
			{
				ThrowNativeError(SP_ERROR_NATIVE, "Cannot change duration on a non-timed effect");
				return;
			}
			effect[effectDuration] = GetNativeCell(3);
			SetArrayArray(g_hEffects[type], i, effect);
			return;
		}
	}
}

public Native_UnregisterEffect(Handle:hPlugin, iNumParams)
{
	new iRTDEffectId = GetNativeCell(1);
	new type = GetNativeCell(2);
	
	if (g_iEffectIdxMax[type] > -1)
	{
		for (new i = 0; i <= g_iEffectIdxMax[type]; i++)
		{
			decl effect[rtdEffect];
			GetArrayArray(g_hEffects[type], i, effect, sizeof(effect));
			if (effect[effectId] == iRTDEffectId)
			{
				if (effect[effectEndFunc] != INVALID_FUNCTION)
				{
					for (new j = 0; j <= MAXPLAYERS; j++)
					{
						if (g_ClientEndFunc[j][CEFFunc] == effect[effectEndFunc])
						{
							g_ClientEndFunc[j][CEFPlugin] = INVALID_HANDLE;
							g_ClientEndFunc[j][CEFFunc] = INVALID_FUNCTION;
						}
					}
				}
				RemoveFromArray(g_hEffects[type], iRTDEffectId);
				g_iEffectIdxMax[type]--;
				return;
			}
		}
	}
}

public Native_UnregisterAllEffects(Handle:hPlugin, iNumParams)
{
	for (new i = 0; i <= g_iEffectIdxMax[psyRTDEffectType_Bad]; i++)
	{
		decl effect[rtdEffect];
		GetArrayArray(g_hEffects[psyRTDEffectType_Bad], i, effect, sizeof(effect));
		if (effect[effectParent] == hPlugin)
		{
			if (effect[effectEndFunc] != INVALID_FUNCTION)
			{
				for (new j = 0; j <= MAXPLAYERS; j++)
				{
					if (g_ClientEndFunc[j][CEFFunc] == effect[effectEndFunc])
					{
						g_ClientEndFunc[j][CEFPlugin] = INVALID_HANDLE;
						g_ClientEndFunc[j][CEFFunc] = INVALID_FUNCTION;
					}
				}
			}
			RemoveFromArray(g_hEffects[psyRTDEffectType_Bad], i);
			g_iEffectIdxMax[psyRTDEffectType_Bad]--;
		}
	}
	for (new i = 0; i <= g_iEffectIdxMax[psyRTDEffectType_Good]; i++)
	{
		decl effect[rtdEffect];
		GetArrayArray(g_hEffects[psyRTDEffectType_Good], i, effect, sizeof(effect));
		if (effect[effectParent] == hPlugin)
		{
			if (effect[effectEndFunc] != INVALID_FUNCTION)
			{
				for (new j = 0; j <= MAXPLAYERS; j++)
				{
					if (g_ClientEndFunc[j][CEFFunc] == effect[effectEndFunc])
					{
						g_ClientEndFunc[j][CEFPlugin] = INVALID_HANDLE;
						g_ClientEndFunc[j][CEFFunc] = INVALID_FUNCTION;
					}
				}
			}
			RemoveFromArray(g_hEffects[psyRTDEffectType_Good], i);
			g_iEffectIdxMax[psyRTDEffectType_Good]--;
		}
	}
}

public Native_GetGame(Handle:hPlugin, iNumParams)
{
	return g_psyGame;
}

public Native_PrintToChat(Handle:hPlugin, iNumParams)
{
	decl String:message[192], written;
	FormatNativeString(0, 2, 3, sizeof(message), written, message);
	PrintToChat(GetNativeCell(1), "%s%s", MSGTAG, message);
}

DetectGame()
{
	// Adapted from HLX:CE ingame plugin :3
	if (g_psyGame == psyRTDGame_Unknown)
	{
		new String: szGameDesc[64];
		GetGameDescription(szGameDesc, 64, true);
		
		if (GuessSDKVersion() == SOURCE_SDK_DARKMESSIAH)
		{
			g_psyGame = psyRTDGame_DM;
		}
		else if (StrContains(szGameDesc, "Counter-Strike", false) != -1)
		{
			g_psyGame = psyRTDGame_CSS;
		}
		else if (StrContains(szGameDesc, "Day of Defeat", false) != -1)
		{
			g_psyGame = psyRTDGame_DODS;
		}
		else if (StrContains(szGameDesc, "Half-Life 2 Deathmatch", false) != -1)
		{
			g_psyGame = psyRTDGame_HL2MP;
		}
		else if (StrContains(szGameDesc, "Team Fortress", false) != -1)
		{
			g_psyGame = psyRTDGame_TF;
		}
		else if (StrContains(szGameDesc, "L4D", false) != -1 || StrContains(szGameDesc, "Left 4 D", false) != -1)
		{
			g_psyGame = (GuessSDKVersion() >= SOURCE_SDK_LEFT4DEAD) ? psyRTDGame_L4D : psyRTDGame_L4D2;
		}
		else if (StrContains(szGameDesc, "Insurgency", false) != -1)
		{
			g_psyGame = psyRTDGame_INSMOD;
		}
		else if (StrContains(szGameDesc, "Fortress Forever", false) != -1)
		{
			g_psyGame = psyRTDGame_FF;
		}
		else if (StrContains(szGameDesc, "ZPS", false) != -1)
		{
			g_psyGame = psyRTDGame_ZPS;
		}
		else if (StrContains(szGameDesc, "Age of Chivalry", false) != -1)
		{
			g_psyGame = psyRTDGame_AOC;
		}
		// game could not detected, try further
		if (g_psyGame == psyRTDGame_Unknown)
		{
			new String: szGameDir[64];
			GetGameFolderName(szGameDir, 64);
			
			if (StrContains(szGameDir, "cstrike", false) != -1)
			{
				g_psyGame = psyRTDGame_CSS;
			}
			else if (StrContains(szGameDir, "dod", false) != -1)
			{
				g_psyGame = psyRTDGame_DODS;
			}
			else if (StrContains(szGameDir, "hl2mp", false) != -1 || StrContains(szGameDir, "hl2ctf", false) != -1)
			{
				g_psyGame = psyRTDGame_HL2MP;
			}
			else if (StrContains(szGameDir, "fistful_of_frags", false) != -1)
			{
				g_psyGame = psyRTDGame_FOF;
			}
			else if (StrContains(szGameDir, "tf", false) != -1)
			{
				g_psyGame = psyRTDGame_TF;
			}
			else if (StrContains(szGameDir, "left4dead", false) != -1)
			{
				g_psyGame = (GuessSDKVersion() == SOURCE_SDK_LEFT4DEAD) ? psyRTDGame_L4D : psyRTDGame_L4D2;
			}
			else if (StrContains(szGameDir, "insurgency", false) != -1)
			{
				g_psyGame = psyRTDGame_INSMOD;
			}
			else if (StrContains(szGameDir, "FortressForever", false) != -1)
			{
				g_psyGame = psyRTDGame_FF;
			}
			else if (StrContains(szGameDir, "zps", false) != -1)
			{
				g_psyGame = psyRTDGame_ZPS;
			}
			else if (StrContains(szGameDir, "ageofchivalry", false) != -1)
			{
				g_psyGame = psyRTDGame_AOC;
			}
			else if (StrContains(szGameDir, "gesource", false) != -1)
			{
				g_psyGame = psyRTDGame_GES;
			}
		}
	}
}

public CvarEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = GetConVarBool(g_cvarEnabled);
}

public CvarGoodChance(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fGoodChance = GetConVarFloat(g_cvarGoodChance);
}

public CvarWaitTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fWaitTime = GetConVarFloat(g_cvarWaitTime);
}

public CvarWaitMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_psyWaitMode = rtdWaitMode:GetConVarInt(g_cvarWaitMode);
}

public CvarWaitPenalty(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bWaitPenalty = GetConVarBool(g_cvarWaitPenalty);
}

public CvarAllowUnusable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bAllowUnusable = GetConVarBool(g_cvarAllowUnusable);
}

public CvarAdminFlag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new AdminFlag:flag;
	if (FindFlagByChar(newValue[0], flag))
	{
		g_iAdminBit = FlagToBit(flag);
		return;
	}

	g_iAdminBit = 0;
}