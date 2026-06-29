/** [CS:S/CS:GO] CT Bans - Max Bans
 * Copyright (C) 2017 by databomb
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
 *
 */

#define PLUGIN_VERSION "1.0.0"

#define TEMP_CTBAN_COMMAND "sm_tctban"
#define TEMP_CTBAN_ADMIN_LEVEL ADMFLAG_CHAT
 
#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <adminmenu>
#include <cstrike>
#include <ctban>

#pragma semicolon 1
#pragma newdecls required

char g_sChatBanner[MAX_CHAT_BANNER_LENGTH];
Handle gH_Cvar_MaxBans_Time = INVALID_HANDLE;
Handle gH_Cvar_Force_Reason = INVALID_HANDLE;
Handle gH_DArray_Reasons = INVALID_HANDLE;
Handle gH_KV_BanLengths = INVALID_HANDLE;
EngineVersion g_EngineVersion = Engine_Unknown;

public Plugin myinfo =
{
	name = "CT Ban - Max Bans",
	author = "databomb",
	description = "Allows lesser admins to CT Ban up to a certain maximum time.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=166080"
};

public void OnPluginStart()
{
	CreateConVar("sm_ctban_maxbans_version", PLUGIN_VERSION, "CT Ban Max Bans Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gH_Cvar_MaxBans_Time = CreateConVar("sm_ctban_maxbans_time", "120", "Specifies the maximum number of minutes for a temporary CT Ban.", FCVAR_NONE);
	
	RegAdminCmd(TEMP_CTBAN_COMMAND, Command_TempCTBan, TEMP_CTBAN_ADMIN_LEVEL, "sm_tctban <player> <time> <optional: reason> - Temp Bans a player from being a CT.");
	
	g_EngineVersion = GetEngineVersion();
	SetCTBanChatBanner(g_EngineVersion, g_sChatBanner);
	
	LoadTranslations("ctban.phrases");
	LoadTranslations("common.phrases");
	
	gH_DArray_Reasons = CreateArray(FIELD_REASON_MAXLENGTH);
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("ctban"))
	{
		SetFailState("CT Bans plugin required. Visit: https://forums.alliedmods.net/showthread.php?t=166080");
	}
	
	gH_Cvar_Force_Reason = FindConVar("sm_ctban_force_reason");
}

public void OnConfigsExecuted()
{
	ParseCTBanReasonsFile(gH_DArray_Reasons);
	
	gH_KV_BanLengths = ParseCTBanLengthsFile(gH_KV_BanLengths);
}


public Action Command_TempCTBan(int iClient, int iArgs)
{
	if (!iClient && (iArgs < (GetConVarBool(gH_Cvar_Force_Reason) ? CTBAN_ARG_REASON : CTBAN_ARG_TIME)))
	{
		if (GetConVarBool(gH_Cvar_Force_Reason))
		{
			ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_tctban <player> <time> <reason>");
		}
		else
		{
			ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_tctban <player> <time> <optional:reason>");
		}
		
		return Plugin_Handled;
	}
	
	if (!iArgs)
	{
		DisplayTCTBanPlayerMenu(iClient);
		return Plugin_Handled;
	}
	
	char sTarget[MAX_NAME_LENGTH];
	GetCmdArg(CTBAN_ARG_PLAYER, sTarget, sizeof(sTarget));
	
	char sClientName[MAX_TARGET_LENGTH];
	int aiTargetList[MAXPLAYERS];
	int iTargetCount;
	bool b_tn_is_ml;
	iTargetCount = ProcessTargetString(sTarget, iClient, aiTargetList, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, sClientName, sizeof(sClientName), b_tn_is_ml);
	
	// target count 0 or less is an error condition
	if (iTargetCount < ONE)
	{
		ReplyToTargetError(iClient, iTargetCount);
	}
	else
	{
		int iTarget = aiTargetList[ZERO];
		
		if(iTarget && IsClientInGame(iTarget))
		{
			if (CTBan_IsClientBanned(iTarget))
			{
				ReplyToCommand(iClient, g_sChatBanner, "Already CT Banned", iTarget);
			}
			else
			{
				if (iArgs == CTBAN_ARG_PLAYER)
				{
					int iTargetUserId = GetClientUserId(iTarget);
					DisplayTCTBanTimeMenu(iClient, iTargetUserId);
					return Plugin_Handled;
				}
				
				char sBanTime[MAX_TIME_ARG_LENGTH];
				GetCmdArg(CTBAN_ARG_TIME, sBanTime, sizeof(sBanTime));
				int iBanTime = StringToInt(sBanTime);
				
				if (iBanTime <= 0 || iBanTime > GetConVarInt(gH_Cvar_MaxBans_Time))
				{
					ReplyToCommand(iClient, g_sChatBanner, "Invalid Amount");
					return Plugin_Handled;
				}
				
				if (GetConVarBool(gH_Cvar_Force_Reason) && iArgs == CTBAN_ARG_TIME)
				{
					int iTargetUserId = GetClientUserId(iTarget);
					DisplayTCTBanReasonMenu(iClient, iTargetUserId, iBanTime);
					return Plugin_Handled;
				}
				
				char sReasonStr[FIELD_REASON_MAXLENGTH];
				char sArgPart[FIELD_REASON_MAXLENGTH];
				for (int iArg = CTBAN_ARG_REASON; iArg <= iArgs; iArg++)
				{
					GetCmdArg(iArg, sArgPart, sizeof(sArgPart));
					Format(sReasonStr, sizeof(sReasonStr), "%s %s", sReasonStr, sArgPart);	
				}
				// Remove the space at the beginning
				TrimString(sReasonStr);
				
				if (GetConVarBool(gH_Cvar_Force_Reason) && !strlen(sReasonStr))
				{
					ReplyToCommand(iClient, g_sChatBanner, "Reason Required");
				}
				else
				{
					CTBan_Client(iTarget, iBanTime, iClient, sReasonStr);
				}
			}
		}				
	}
	
	return Plugin_Handled;
}

void DisplayTCTBanPlayerMenu(int iClient)
{
	Handle hMenu = CreateMenu(MenuHandler_TCTBanPlayerList);
	
	SetMenuTitle(hMenu, "%T", "CT Ban Menu Title", iClient);
	SetMenuExitBackButton(hMenu, true);
	
	int iCount = ZERO;
	char sUserId[MAX_USERID_LENGTH];
	char sName[MAX_NAME_LENGTH];
	
	// filter away those with current CTBans
	for (int iIndex = 1; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			if (!CTBan_IsClientBanned(iIndex))
			{
				IntToString(GetClientUserId(iIndex), sUserId, sizeof(sUserId));
				GetClientName(iIndex, sName, sizeof(sName));
				
				AddMenuItem(hMenu, sUserId, sName);
				
				iCount++;
			}
		}
	}
	
	if (!iCount)
	{
		PrintToChat(iClient, g_sChatBanner, "No Targets");
	}
	
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_TCTBanPlayerList(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);
		int iTarget = GetClientOfUserId(iTargetUserId);

		if (!iTarget || !IsClientInGame(iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Player no longer available");
		}
		else if (!CanUserTarget(iClient, iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Unable to target");
		}
		else if (CTBan_IsClientBanned(iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Already CT Banned", iTarget);
		}
		else
		{
			DisplayTCTBanTimeMenu(iClient, iTargetUserId);
		}
	}
}

void DisplayTCTBanTimeMenu(int iClient, int iTargetUserId)
{
	Handle hMenu = CreateMenu(MenuHandler_TCTBanTimeList);

	SetMenuTitle(hMenu, "%T", "CT Ban Length Menu", iClient, GetClientOfUserId(iTargetUserId));
	SetMenuExitBackButton(hMenu, true);

	char sUserId[MAX_USERID_LENGTH];
	IntToString(iTargetUserId, sUserId, sizeof(sUserId));
	AddMenuItem(hMenu, sUserId, "", ITEMDRAW_IGNORE);
	
	int iMaxBanLength = GetConVarInt(gH_Cvar_MaxBans_Time);
	
	if (gH_KV_BanLengths != INVALID_HANDLE)
	{
		char sBanDuration[MAX_TIME_ARG_LENGTH];
		char sDurationDescription[MAX_TIME_INFO_STR_LENGTH];
		
		KvGotoFirstSubKey(gH_KV_BanLengths, false);
		do
		{
			KvGetSectionName(gH_KV_BanLengths, sBanDuration, sizeof(sBanDuration));
			KvGetString(gH_KV_BanLengths, NULL_STRING, sDurationDescription, sizeof(sDurationDescription));
			
			int iBanLength = StringToInt(sBanDuration);
			
			if (iBanLength > 0 && iBanLength < iMaxBanLength)
			{
				AddMenuItem(hMenu, sBanDuration, sDurationDescription);
			}
		}
		while (KvGotoNextKey(gH_KV_BanLengths, false));
		
		KvRewind(gH_KV_BanLengths);
	}
	else
	{
		if (iMaxBanLength >= 5)
		{
			AddMenuItem(hMenu, "5", "5 Minutes");
		}
		if (iMaxBanLength >= 10)
		{
			AddMenuItem(hMenu, "10", "10 Minutes");
		}
		if (iMaxBanLength >= 30)
		{
			AddMenuItem(hMenu, "30", "30 Minutes");
		}
		if (iMaxBanLength >= 60)
		{
			AddMenuItem(hMenu, "60", "1 Hour");
		}
		if (iMaxBanLength >= 90)
		{
			AddMenuItem(hMenu, "90", "1 Hour 30 Minutes");
		}
		if (iMaxBanLength >= 120)
		{
			AddMenuItem(hMenu, "120", "2 Hours");
		}
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_TCTBanTimeList(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, MENUCHOICE_USERID, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);
		
		char sTimeInMinutes[MAX_TIME_ARG_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sTimeInMinutes, sizeof(sTimeInMinutes));
		int iMinutesToBan = StringToInt(sTimeInMinutes);
		
		DisplayTCTBanReasonMenu(iClient, iTargetUserId, iMinutesToBan);
	}
}

void DisplayTCTBanReasonMenu(int iClient, int iTargetUserId, int iMinutesToBan)
{
	Handle hMenu = CreateMenu(MenuHandler_TCTBanReasonList);

	SetMenuTitle(hMenu, "%T", "CT Ban Reason Menu", iClient, GetClientOfUserId(iTargetUserId));
	SetMenuExitBackButton(hMenu, true);
	
	char sTargetUserId[MAX_USERID_LENGTH];
	IntToString(iTargetUserId, sTargetUserId, sizeof(sTargetUserId));
	AddMenuItem(hMenu, sTargetUserId, "", ITEMDRAW_IGNORE);
	
	char sTimeInMinutes[MAX_TIME_ARG_LENGTH];
	IntToString(iMinutesToBan, sTimeInMinutes, sizeof(sTimeInMinutes));
	AddMenuItem(hMenu, sTimeInMinutes, "", ITEMDRAW_IGNORE);
	
	int iNumManualReasons = GetArraySize(gH_DArray_Reasons);
	
	char sMenuReason[FIELD_REASON_MAXLENGTH];
	char sMenuInt[MAX_MENU_INT_CHOICE_LENGTH];
	
	if (iNumManualReasons > ZERO)
	{
		for (int iLineNumber = ZERO; iLineNumber < iNumManualReasons; iLineNumber++)
		{
			GetArrayString(gH_DArray_Reasons, iLineNumber, sMenuReason, sizeof(sMenuReason));
			IntToString(iLineNumber, sMenuInt, sizeof(sMenuInt));
			AddMenuItem(hMenu, sMenuInt, sMenuReason);
		}
	}
	else
	{
		// Only display 6 reasons in CS:GO by default to avoid pagination
		// Freekill Massacre is a redundant reason with Freekilling "CT Ban Reason 5"
		if (g_EngineVersion != Engine_CSGO)
		{
			Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 1", iClient);
			AddMenuItem(hMenu, "1", sMenuReason);
		}
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 2", iClient);
		AddMenuItem(hMenu, "2", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 3", iClient);
		AddMenuItem(hMenu, "3", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 4", iClient);
		AddMenuItem(hMenu, "4", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 5", iClient);
		AddMenuItem(hMenu, "5", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 6", iClient);
		AddMenuItem(hMenu, "6", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 7", iClient);
		AddMenuItem(hMenu, "7", sMenuReason);
	}
	
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_TCTBanReasonList(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, MENUCHOICE_USERID, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);
		
		char sTimeInMinutes[MAX_TIME_ARG_LENGTH];
		GetMenuItem(hMenu, MENUCHOICE_TIME, sTimeInMinutes, sizeof(sTimeInMinutes));
		int iMinutesToBan = StringToInt(sTimeInMinutes);
		
		char sBanChoice[MAX_REASON_MENU_CHOICE_LENGTH];
		char sReason[FIELD_REASON_MAXLENGTH];
		GetMenuItem(hMenu, iMenuChoice, sBanChoice, sizeof(sBanChoice), _, sReason, sizeof(sReason));
		
		int iTarget = GetClientOfUserId(iTargetUserId);
		
		if (!CTBan_IsClientBanned(iTarget))
		{
			CTBan_Client(iTarget, iMinutesToBan, iClient, sReason);
		}
		else
		{
			PrintToChat(iClient, g_sChatBanner, "Already CT Banned", iTarget);
		}
	}
}