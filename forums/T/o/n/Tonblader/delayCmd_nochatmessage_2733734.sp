#pragma semicolon 1
#define CONVAR_PREFIX "sm_delaycmd"
#define DEFAULT_UPDATE_SETTING "2"
#define UPD_LIBFUNC
#define UPDATE_URL "http://ddhoward.com/sourcemod/updater/delayCmd/delayCmd.txt"
#include <ddhoward_updater>
#pragma newdecls required
#include <adminmenu>

public Plugin myinfo = {
    name = "[Any] Delay Command",
    author = "Derek D. Howard (ddhoward), based off an original plugin by DarthNinja",
    description = "Takes a command, and runs it later.",
    version = "18.0725.0",
    url = "https://forums.alliedmods.net/showthread.php?t=309101"
}

ArrayList g_alTimers[MAXPLAYERS+1];

public void OnPluginStart() {
	RegAdminCmd("sm_delaycmd", sm_delaycmd, ADMFLAG_GENERIC);
	RegAdminCmd("sm_delaycmd_list", sm_delaycmd_list, ADMFLAG_GENERIC);
	RegAdminCmd("sm_delaycmd_cancel", sm_delaycmd_cancel, ADMFLAG_GENERIC);
	RegAdminCmd("sm_delaycmd_rcon", sm_delaycmd_rcon, ADMFLAG_RCON);

	g_alTimers[0] = new ArrayList(2);
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientConnected(iClient)) {
			g_alTimers[iClient] = new ArrayList(2);
		}
	}
}

public void OnClientConnected(int iClient) {
	g_alTimers[iClient] = new ArrayList(2);
}

public void OnClientDisconnect(int iClient) {
	if (g_alTimers[iClient].Length > 0) {
		LogAction(iClient, -1, "%L disconnected, cancelling %i delayed command(s).", iClient, g_alTimers[iClient].Length);
		for (int iIndex; iIndex < g_alTimers[iClient].Length; iIndex++) {
			CloseHandle(view_as<Handle>(g_alTimers[iClient].Get(iIndex)));
		}
	}
	delete g_alTimers[iClient];
}

public Action sm_delaycmd(int iClient, int iNumArgs) {
	if (iClient == 0) {
		sm_delaycmd_rcon(iClient, iNumArgs);
		return Plugin_Handled;
	}

	if (iNumArgs < 2) {
		ReplyToCommand(iClient, "[SM] Usage: sm_delaycmd [time in seconds] [command to run]");
		return Plugin_Handled;	
	}

	char sCommand[255];
	char sTime[9]; //maximum value of 99999999 seconds, over three years
	GetCmdArgString(sCommand, sizeof(sCommand));

	int iCmdBegins = BreakString(sCommand, sTime, sizeof(sTime));
	if (iCmdBegins == -1) {
		ReplyToCommand(iClient, "[DelayCmd] No command specified.");
		return Plugin_Handled;
	}
	int iDuration = StringToInt(sTime);
	if (iDuration <= 0) {
		ReplyToCommand(iClient, "[DelayCmd] Invalid time specified.");
		return Plugin_Handled;
	}
	
	Format(sCommand, sizeof(sCommand), "%s", sCommand[iCmdBegins]);
	DataPack dpPack;
	Handle hTimer = CreateDataTimer(float(iDuration), Timer_DelayCmd, dpPack);
	int iNewIndex = g_alTimers[iClient].Push(hTimer);
	g_alTimers[iClient].Set(iNewIndex, dpPack, 1);
	dpPack.WriteString(sCommand);
	dpPack.WriteCell(GetClientUserId(iClient));
	dpPack.WriteCell(iDuration);
	dpPack.WriteCell(GetTime());

	//ShowActivity2(iClient, "[DelayCmd] ", "Running \"%s\" in %i seconds", sCommand, iDuration);
	LogAction(iClient, -1, "%L used DelayCmd to schedule \"%s\" in %i seconds. (Handle: %i)", iClient, sCommand, iDuration, hTimer);
	
	return Plugin_Handled;
}

public Action Timer_DelayCmd(Handle hTimer, DataPack dpPack) {
	dpPack.Reset();
	char sCommand[255];
	dpPack.ReadString(sCommand, sizeof(sCommand));
	int iUserId = dpPack.ReadCell();
	int iClient = GetClientOfUserId(iUserId);
	int iDuration = dpPack.ReadCell();
	int iIndex = g_alTimers[iClient].FindValue(hTimer);
	
	if (iClient == 0 || iIndex == -1) {
		return Plugin_Stop; //no idea how we'd even get here, but better safe than sorry
	}
	
	LogAction(iClient, -1, "%L used DelayCmd %i seconds ago to execute \"%s\" (Handle: %i)", iClient, iDuration, sCommand, hTimer);
	//ShowActivity2(iClient, "[DelayCmd] ", "Running \"%s\", queued %i seconds ago.", sCommand, iDuration);
	FakeClientCommandEx(iClient, "%s", sCommand);
	g_alTimers[iClient].Erase(iIndex);
	return Plugin_Stop;
}

public Action sm_delaycmd_list(int iClient, int iNumArgs) {
	if (!CheckCommandAccess(iClient, "sm_delaycmd_viewothers", ADMFLAG_GENERIC, true)) {
		if (g_alTimers[iClient].Length == 0) {
			ReplyToCommand(iClient, "[DelayCmd] You have no pending commands.");
		}
		else {
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
				ReplyToCommand(iClient, "[DelayCmd] See console for output.");
			}
			for (int iArrayIndex; iArrayIndex < g_alTimers[iClient].Length; iArrayIndex++) {
				DataPack dpPack = g_alTimers[iClient].Get(iArrayIndex, 1);
				dpPack.Reset();
				char sCommand[255];
				dpPack.ReadString(sCommand, sizeof(sCommand));
				dpPack.ReadCell(); //don't need userID here
				int iDuration = dpPack.ReadCell();
				int iTimeSince = GetTime() - dpPack.ReadCell();
				int iTimeLeft = iDuration - iTimeSince;
				int iHandle = g_alTimers[iClient].Get(iArrayIndex);
				PrintToConsole(iClient, "[DelayCmd] Queued \"%s\" %i seconds ago, should run in %i seconds. (Handle: %i)",
					sCommand, iTimeSince, iTimeLeft, iHandle);
			}
		}
		return Plugin_Handled;
	}
		
	char sArgstring[MAX_NAME_LENGTH];
	GetCmdArgString(sArgstring, sizeof(sArgstring));
	StripQuotes(sArgstring);
	
	char sTargetName[2];
	int[] iaTargetList = new int[MaxClients+1];
	bool bTNisML;
	int target_count = ProcessTargetString(sArgstring, iClient, iaTargetList, MaxClients, 0, sTargetName, sizeof(sTargetName), bTNisML);
	
	if (target_count <= 0) {
		if (iClient == 0) {
			if (iNumArgs == 0 || StrEqual(sArgstring, "@me", true)) {
				PrintPendingRCON(iClient);
			}
			else {
				ReplyToTargetError(iClient, target_count);
			}
		}
		else {
			if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
				ReplyToCommand(iClient, "[DelayCmd] Please see the menu to select a player, or try again.");
			}
			SendPlayerList(iClient);
		}
		return Plugin_Handled;
	}
	
	if (StrEqual(sArgstring, "@all", true) && CheckCommandAccess(iClient, "sm_delaycmd_rcon", ADMFLAG_RCON, true)) {
		target_count++;
	}
	
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
		ReplyToCommand(iClient, "[DelayCmd] See console for output.");
	}

	for (int iTargetIndex; iTargetIndex < target_count; iTargetIndex++) {
		int iTarget = iaTargetList[iTargetIndex];
		PrintToServer("printing target %i to %i", iTarget, iClient);
		if (iTarget == 0) {
			PrintPendingRCON(iClient);
			continue;
		}
		for (int iArrayIndex; iArrayIndex < g_alTimers[iTarget].Length; iArrayIndex++) {
			DataPack dpPack = g_alTimers[iTarget].Get(iArrayIndex, 1);
			dpPack.Reset();
			char sCommand[255];
			dpPack.ReadString(sCommand, sizeof(sCommand));
			dpPack.ReadCell(); //don't need userID here
			int iDuration = dpPack.ReadCell();
			int iTimeSince = GetTime() - dpPack.ReadCell();
			int iTimeLeft = iDuration - iTimeSince;
			int iHandle = g_alTimers[iTarget].Get(iArrayIndex);
			ReplySource rsSource = GetCmdReplySource();
			SetCmdReplySource(SM_REPLY_TO_CONSOLE);
			ReplyToCommand(iClient, "[DelayCmd] %N queued \"%s\" %i seconds ago, should run in %i seconds. (Handle: %i)",
				iTarget, sCommand, iTimeSince, iTimeLeft, iHandle);
			SetCmdReplySource(rsSource);
		}
	}
	return Plugin_Handled;
}

void SendPlayerList(int iClient) {
	Menu menu = new Menu(MenuHandler_PlayerList);
	//menu.ExitBackButton = true;
	if (CheckCommandAccess(iClient, "sm_delaycmd_rcon", ADMFLAG_RCON)) {
		menu.AddItem("0", "CONSOLE");
	}
	AddTargetsToMenu(menu, iClient);
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_PlayerList(Menu menu, MenuAction action, int iClient, int iParam) {
	if (action == MenuAction_Select) {
		char sUserID[6];
		menu.GetItem(iParam, sUserID, sizeof(sUserID));
		PrintToChat(iClient, "[DelayCmd] See console for output.");
		if (StrEqual(sUserID, "0")) {
			PrintPendingRCON(iClient);
		}
		else {
			FakeClientCommandEx(iClient, "sm_delaycmd_list #%s", sUserID);
		}
	}

	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

void PrintPendingRCON(int iClient) {
	for (int iArrayIndex; iArrayIndex < g_alTimers[0].Length; iArrayIndex++) {
		DataPack dpPack = g_alTimers[0].Get(iArrayIndex, 1);
		dpPack.Reset();
		char sCommand[255];
		dpPack.ReadString(sCommand, sizeof(sCommand));
		int iUserId = dpPack.ReadCell();
		int iCreator = GetClientOfUserId(iUserId);
		int iDuration = dpPack.ReadCell();
		int iQueued = dpPack.ReadCell();
		int iTimeSince = GetTime() - iQueued;
		int iTimeLeft = iDuration - iTimeSince;
		int iHandle = g_alTimers[0].Get(iArrayIndex);

		ReplySource rsSource = GetCmdReplySource();
		SetCmdReplySource(SM_REPLY_TO_CONSOLE);
		if (iUserId != 0 && iCreator != 0) {
			ReplyToCommand(iClient, "[DelayCmd] %N queued \"%s\" %i seconds ago, should run via RCON in %i seconds. (Handle: %i)",
				iCreator, sCommand, iTimeSince, iTimeLeft, iHandle);
		}
		else {
			char sLogText[MAX_NAME_LENGTH];
			dpPack.ReadString(sLogText, sizeof(sLogText));
			ReplyToCommand(iClient, "[DelayCmd] %s queued \"%s\" %i seconds ago, should run via RCON in %i seconds. (Handle: %i)",
				sLogText, sCommand, iTimeSince, iTimeLeft, iHandle);
		}
		SetCmdReplySource(rsSource);
	}

}

public Action sm_delaycmd_cancel(int iClient, int iArgs) {

	if (iArgs != 1) {
		ReplyToCommand(iClient, "Usage: sm_delaycmd_cancel [handle]");
		return Plugin_Handled;
	}

	char sHandle[13];
	GetCmdArg(1, sHandle, sizeof(sHandle));

	Handle hTimer = view_as<Handle>(StringToInt(sHandle));
	int iTarget; int iIndex = -1;
	for (; iTarget <= MaxClients; iTarget++) {
		PrintToServer("%i", iTarget);
		if (g_alTimers[iTarget] != null) {
			iIndex = g_alTimers[iTarget].FindValue(hTimer);
			if (iIndex != -1) break;
		}
	}
	if (iIndex == -1
	|| (iTarget == 0 && !CheckCommandAccess(iClient, "sm_delaycmd_rcon", ADMFLAG_RCON, true))
	|| (iClient != iTarget && !CheckCommandAccess(iClient, "sm_delaycmd_cancelothers", ADMFLAG_GENERIC, true))
	|| !CanUserTarget(iClient, iTarget)) {
		ReplyToCommand(iClient, "[DelayCmd] Invalid handle specified.");
		return Plugin_Handled;
	}

	DataPack dpPack = g_alTimers[iTarget].Get(iIndex, 1);
	dpPack.Reset();
	char sCommand[255];
	dpPack.ReadString(sCommand, sizeof(sCommand));

	if (iTarget != 0) {
		dpPack.ReadCell();
		dpPack.ReadCell();
		int iQueued = dpPack.ReadCell();
		int iTimeSince = GetTime() - iQueued;

		if (iClient == iTarget) {
			LogAction(iClient, iTarget, "%L cancelled \"%s\", queued %i seconds ago. (Handle: %i)",
				iClient, sCommand, iTimeSince, hTimer);
			//ShowActivity2(iClient, "[DelayCmd] ", "Cancelled \"%s\", queued %i seconds ago.", sCommand, iTimeSince);
		}
		else {
			LogAction(iClient, iTarget, "%L cancelled \"%s\", queued by %L %i seconds ago. (Handle: %i)",
				iClient, sCommand, iTarget, iTimeSince, hTimer);
			//ShowActivity2(iClient, "[DelayCmd] ", "Cancelled \"%s\", queued by %N %i seconds ago.", sCommand, iTarget, iTimeSince);
		}
	}
	else {
		int iUserId = dpPack.ReadCell();
		int iCreator = GetClientOfUserId(iUserId);
		dpPack.ReadCell(); //duration not needed
		int iTimeSince = GetTime() - dpPack.ReadCell();
		
		if (iUserId == 0 || iCreator != 0) {
			//creator is a player and is still on server, or is console
			LogAction(iClient, iCreator, "%L cancelled \"%s\", which was queued for rcon by %L %i seconds ago. (Handle: %i)",
				iClient, sCommand, iCreator, iTimeSince, hTimer);
			//ShowActivity2(iClient, "[DelayCmd] ", "Cancelled \"%s\", queued for rcon by %N %i seconds ago.", sCommand, iCreator, iTimeSince);
		}
		else {
			char sLogText[256];
			dpPack.ReadString(sLogText, sizeof(sLogText));

			LogAction(iClient, iCreator, "%L cancelled \"%s\", queued for rcon by %s %i seconds ago. (Handle: %i)",
				iClient, sCommand, sLogText, iTimeSince, hTimer);
			//ShowActivity2(iClient, "[DelayCmd] ", "Cancelled \"%s\", queued for rcon by %s %i seconds ago.", sCommand, sLogText, iTimeSince);
		}
	}

	CloseHandle(hTimer);
	g_alTimers[iTarget].Erase(iIndex);
	return Plugin_Handled;
}

public Action sm_delaycmd_rcon(int iClient, int iNumArgs) {

	if (iNumArgs < 2) {
		ReplyToCommand(iClient, "[SM] Usage: sm_delaycmd_rcon [time in seconds] [command to run]");
		return Plugin_Handled;	
	}

	char sCommand[255];
	char sTime[9]; //maximum value of 99999999 seconds, over three years
	GetCmdArgString(sCommand, sizeof(sCommand));

	int iCmdBegins = BreakString(sCommand, sTime, sizeof(sTime));
	if (iCmdBegins == -1) {
		ReplyToCommand(iClient, "[DelayCmd] No command specified.");
		return Plugin_Handled;
	}
	int iDuration = StringToInt(sTime);
	if (iDuration <= 0) {
		ReplyToCommand(iClient, "[DelayCmd] Invalid time specified.");
		return Plugin_Handled;
	}

	Format(sCommand, sizeof(sCommand), "%s", sCommand[iCmdBegins]);
	char sLogText[256];
	int iUserId;
	FormatEx(sLogText, sizeof(sLogText), "%L", iClient);
	if (iClient != 0) {
		iUserId = GetClientUserId(iClient);
	}

	DataPack dpPack;
	Handle hTimer = CreateDataTimer(float(iDuration), Timer_DelayRconCmd, dpPack);
	int iNewIndex = g_alTimers[0].Push(hTimer);
	g_alTimers[0].Set(iNewIndex, dpPack, 1);
	dpPack.WriteString(sCommand);
	dpPack.WriteCell(iUserId);
	dpPack.WriteCell(iDuration);
	dpPack.WriteCell(GetTime());
	dpPack.WriteString(sLogText);
	
	//ShowActivity2(iClient, "[DelayCmd] ", "Running \"%s\" in %i seconds%s", sCommand, iDuration, (iClient == 0) ? "" : " via rcon");
	LogAction(iClient, -1, "%L used DelayCmdRcon to schedule command \"%s\" in %i seconds. (Handle: %i)", iClient, sCommand, iDuration, hTimer);
	
	return Plugin_Handled;
}

public Action Timer_DelayRconCmd(Handle hTimer, DataPack dpPack) {
	dpPack.Reset();
	char sCommand[255];
	dpPack.ReadString(sCommand, sizeof(sCommand));
	int iUserId = dpPack.ReadCell();
	int iClient = GetClientOfUserId(iUserId);
	int iDuration = dpPack.ReadCell();
	dpPack.ReadCell();
	
	if (iClient == 0 && iUserId != 0) {
		char sLogText[256];
		dpPack.ReadString(sLogText, sizeof(sLogText));
		LogAction(-1, -1, "%s used DelayCmd %i seconds ago to execute \"%s\" via RCON (Handle: %i)", sLogText, iDuration, sCommand, hTimer);
		//ShowActivity2(0, "[DelayCmd] ", "Running \"%s\", queued %i seconds ago by %s.", sCommand, iDuration, sLogText);
	}
	else {
		LogAction(iClient, -1, "%L used DelayCmd %i seconds ago to execute \"%s\" (Handle: %i)", iClient, iDuration, sCommand, hTimer);
		//ShowActivity2(iClient, "[DelayCmd] ", "Running \"%s\" via rcon, queued %i seconds ago.", sCommand, iDuration);
	}

	ServerCommand("%s", sCommand);
	g_alTimers[0].Erase(g_alTimers[0].FindValue(hTimer));	
	return Plugin_Stop;
}