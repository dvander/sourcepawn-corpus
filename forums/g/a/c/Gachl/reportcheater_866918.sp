#include <sourcemod>

#define PLUGIN_VERSION "1.0.3"

public Plugin:myinfo = 
{
	name = "Report a cheater",
	author = "GachL",
	description = "Report a cheater",
	version = PLUGIN_VERSION,
	url = "http://bloogisgood.org"
}

new Handle:cvRecordTime = INVALID_HANDLE;
new Handle:cvRecordRounds = INVALID_HANDLE;
new Handle:cvRecordWaitTime = INVALID_HANDLE;
new Handle:cvRunCmd = INVALID_HANDLE;
new iLastReport = 0;
new bool:bIsRecording = false;
new iRecordingUser = -1;
new iRoundPassed = 0;

public OnPluginStart()
{
	RegConsoleCmd("sm_cheater", cCheat);
	HookEvent("player_disconnect", ePlayerDisconnect);
	HookEvent("round_end", eRoundEnd);
	HookEvent("game_end", eGameEnd);
	
	cvRecordTime = CreateConVar("sm_cheater_time", "300.0", "Max. time to record in seconds.", FCVAR_PLUGIN);
	cvRecordRounds = CreateConVar("sm_cheater_rounds", "3", "Max. rounds to record.", FCVAR_PLUGIN);
	cvRecordWaitTime = CreateConVar("sm_cheater_wait", "300.0", "Time to wait between two records in seconds.", FCVAR_PLUGIN);
	cvRunCmd = CreateConVar("sm_cheater_runcmd", "status", "Command to run when demo starts.", FCVAR_PLUGIN);
	CreateConVar("sm_cheat_version", PLUGIN_VERSION, "Cheat plugin version", FCVAR_PLUGIN | FCVAR_PROTECTED | FCVAR_NOTIFY);
}

public Action:cCheat(client, args)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;
	
	if ((iLastReport > GetTime() - GetConVarInt(cvRecordWaitTime)) || bIsRecording)
	{
		PrintToChat(client, "At the moment, you can't report a cheater!");
		return;
	}
	new Handle:hCheaterMenu = CreateMenu(cCheaterMenu);
	for (new i = 1; i <= GetClientCount(); i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (i == client))
			continue;
		new String:sName[256], String:sInfo[32];
		GetClientName(i, sName, sizeof(sName));
		IntToString(i, sInfo, sizeof(sInfo));
		AddMenuItem(hCheaterMenu, sInfo, sName);
	}
	DisplayMenu(hCheaterMenu, client, 20);
}

public cCheaterMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:sInfo[32]
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo))
		new target = StringToInt(sInfo);
		if (!IsClientInGame(param1) || IsFakeClient(param1))
			return; // Player left the game because he's a noob. Aaaahw!
		StartDemo(target);
		PrintToChat(param1, "Thank you for reporting the cheater!");
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

public ePlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!bIsRecording)
		return;
	new hUserHimself;
	hUserHimself = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (iRecordingUser == hUserHimself)
	{
		StopDemo();
	}
}

public eRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!bIsRecording)
		return;
	iRoundPassed++;
	if (iRoundPassed < GetConVarInt(cvRecordRounds))
		return;
	StopDemo();
	iRoundPassed = 0;
}

public eGameEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!bIsRecording)
		return;
	StopDemo();
}

public StopDemo()
{
	if (!bIsRecording)
		return;
	PrintToServer("Stopping demo recording to report a cheater!");
	bIsRecording = false;
	iLastReport = GetTime();
	ServerCommand("tv_stoprecord");
}

public StartDemo(client)
{
	if (bIsRecording)
		return;
	PrintToServer("Starting demo recording to report a cheater!");
	iRoundPassed = 0;
	new String:sSteamId[32];
	GetClientAuthString(client, sSteamId, sizeof(sSteamId));
	bIsRecording = true;
	iRecordingUser = client;
	ServerCommand("tv_record cheater_%i_%s", GetTime(), sSteamId);
	new String:sRunCmd[256];
	GetConVarString(cvRunCmd, sRunCmd, sizeof(sRunCmd));
	ServerCommand(sRunCmd);
	CreateTimer(GetConVarFloat(cvRecordTime), cStopDemoTimer);
}

public Action:cStopDemoTimer(Handle:timer)
{
	if (!bIsRecording)
		return;
	StopDemo();
}
