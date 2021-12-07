#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#include <nextmap>
#tryinclude <basecomm>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.2.3"

// ====[ HANDLES | CVARS ]=====================================================

//  __  __      _
// |  \/  |_  _| |_ ___
// | |\/| | || |  _/ -_)
// |_|  |_|\_,_|\__`___|
//

new Handle:g_hArrayVoteMuteClientIdentity;

//  ___
// | _ ) __ _ _ _
// | _ \/ _` | ' `
// |___/\__,_|_||_|
//

new Handle:g_hCvarVoteBanSB;
new Handle:g_hArrayVoteBanClientUserIds;
new Handle:g_hArrayVoteBanClientCurrentUserId;
new Handle:g_hArrayVoteBanClientIdentity;
new Handle:g_hArrayVoteBanClientNames;
new Handle:g_hArrayVoteBanClientTeam;
new Handle:g_hArrayVoteBanReasons;
new Handle:g_hArrayVoteBanFor[MAXPLAYERS + 1];
new Handle:g_hArrayVoteBanForReason[MAXPLAYERS + 1];

//  __  __
// |  \/  |__ _ _ __
// | |\/| / _` | '_ `
// |_|  |_`__,_| .__/
//

new Handle:g_hCvarVoteMapTimeLimit;
new Handle:g_hArrayVoteMapLastMaps;
new Handle:g_hArrayVoteMapList;
new Handle:g_hArrayVotedForMap[MAXPLAYERS + 1];

// ====[ VARIABLES ]===========================================================
new g_iStartTime;
new bool:g_bImmune[MAXPLAYERS + 1];
new String:g_strConfigFile[255];
new bool:g_bChatTriggers;
new g_iVoteImmunity;

//  _  ___    _
// | |/ (_)__| |__
// | ' <| / _| / /
// |_|\_`_`__|_`_`
//

new bool:g_bVoteKickEnabled;
new Float:g_flVoteKickRatio;
new g_iVoteKickMinimum;
new g_iVoteKickDelay;
new g_iVoteKickLimit;
new g_iVoteKickLast[MAXPLAYERS + 1];
new g_iVoteKickInterval;
new bool:g_bVoteKickTeam;
new g_iVoteKickCount[MAXPLAYERS + 1];
new bool:g_bVoteKickFor[MAXPLAYERS + 1][MAXPLAYERS + 1];

//  ___
// | _ ) __ _ _ _
// | _ \/ _` | ' `
// |___/\__,_|_||_|
//

new bool:g_bVoteBanEnabled;
new Float:g_flVoteBanRatio;
new g_iVoteBanMinimum;
new g_iVoteBanDelay;
new g_iVoteBanLimit;
new g_iVoteBanInterval;
new g_iVoteBanLast[MAXPLAYERS + 1];
new bool:g_bVoteBanTeam;
new g_iVoteBanTime;
new String:g_strVoteBanReasons[256];
new g_iVoteBanCount[MAXPLAYERS + 1];
new g_iVoteBanClients[MAXPLAYERS + 1] = {-1, ...};

//  __  __
// |  \/  |__ _ _ __
// | |\/| / _` | '_ `
// |_|  |_`__,_| .__/
//

new bool:g_bVoteMapEnabled;
new Float:g_flVoteMapRatio;
new g_iVoteMapMinimum;
new g_iVoteMapDelay;
new g_iVoteMapLimit;
new g_iVoteMapInterval;
new g_iVoteMapLast[MAXPLAYERS + 1];
new g_iVoteMapLastMaps;
new g_iVoteMapExtendTime;
new g_iVoteMapMaxExtends;
new bool:g_bVoteMapMode;
new g_iVoteMapCount[MAXPLAYERS + 1];
new g_iVoteMapListSerial = -1;
new g_iVoteMapCurrent;

//  __  __      _
// |  \/  |_  _| |_ ___
// | |\/| | || |  _/ -_)
// |_|  |_|\_,_|\__`___|
//

new bool:g_bVoteMuteEnabled;
new Float:g_flVoteMuteRatio;
new g_iVoteMuteMinimum;
new g_iVoteMuteDelay;
new g_iVoteMuteLimit;
new g_iVoteMuteInterval;
new g_iVoteMuteLast[MAXPLAYERS + 1];
new bool:g_bVoteMuteTeam;
new g_iVoteMuteCount[MAXPLAYERS + 1];
new bool:g_bVoteMuteFor[MAXPLAYERS + 1][MAXPLAYERS + 1];
new bool:g_bVoteMuteMuted[MAXPLAYERS + 1];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Players Votes Redux",
	author = "ReFlexPoison",
	description = "Votekick, Voteban, Votemap, & Votemute (Redux)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	LoadTranslations("playersvotes.phrases");

	CreateConVar("sm_playersvotes_redux_version", PLUGIN_VERSION, "Players Votes Redux Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/playersvotes.cfg");

	RegAdminCmd("sm_votemenu", Command_ChooseVote, 0, "Open voting menu");
	RegAdminCmd("sm_playersvotes_reload", Command_Reload, ADMFLAG_ROOT, "Reload playersvotes config");

	if(g_hArrayVoteMapList == INVALID_HANDLE)
		g_hArrayVoteMapList = CreateArray(33);

	if(g_hArrayVoteMapLastMaps == INVALID_HANDLE)
		g_hArrayVoteMapLastMaps = CreateArray(33);

	if(g_hArrayVoteBanClientUserIds == INVALID_HANDLE)
		g_hArrayVoteBanClientUserIds = CreateArray();

	if(g_hArrayVoteBanClientCurrentUserId == INVALID_HANDLE)
		g_hArrayVoteBanClientCurrentUserId = CreateArray();

	if(g_hArrayVoteBanClientTeam == INVALID_HANDLE)
		g_hArrayVoteBanClientTeam = CreateArray();

	if(g_hArrayVoteBanClientIdentity == INVALID_HANDLE)
		g_hArrayVoteBanClientIdentity = CreateArray(33);

	if(g_hArrayVoteBanClientNames == INVALID_HANDLE)
		g_hArrayVoteBanClientNames = CreateArray(33);

	if(g_hArrayVoteBanReasons == INVALID_HANDLE)
		g_hArrayVoteBanReasons = CreateArray(33);

	if(g_hArrayVoteMuteClientIdentity == INVALID_HANDLE)
		g_hArrayVoteMuteClientIdentity = CreateArray(33);

	for(new i = 0; i <= MAXPLAYERS; ++i)
	{
		if(g_hArrayVotedForMap[i] == INVALID_HANDLE)
			g_hArrayVotedForMap[i] = CreateArray();

		if(g_hArrayVoteBanFor[i] == INVALID_HANDLE)
			g_hArrayVoteBanFor[i] = CreateArray();

		if(g_hArrayVoteBanForReason[i] == INVALID_HANDLE)
			g_hArrayVoteBanForReason[i] = CreateArray();
	}
}

public OnConfigsExecuted()
{
	Config_Load();

	ReadMapList(g_hArrayVoteMapList, g_iVoteMapListSerial, "playersvotes", MAPLIST_FLAG_CLEARARRAY | MAPLIST_FLAG_MAPSFOLDER);
	PlayersVotes_ResetMapVotes();

	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));

	g_iVoteMapCurrent = -1;

	decl String:strMapListEntry[65];
	for(new i = 0; i < GetArraySize(g_hArrayVoteMapList); i++)
	{
		GetArrayString(g_hArrayVoteMapList, i, strMapListEntry, sizeof(strMapListEntry));
		if(StrEqual(strMapListEntry, strMap, false))
			g_iVoteMapCurrent = i;
	}
}

public OnMapStart()
{
	g_iStartTime = GetTime();

	g_hCvarVoteMapTimeLimit = FindConVar("mp_timelimit");
	g_hCvarVoteBanSB = FindConVar("sb_version");

	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));

	PushArrayString(g_hArrayVoteMapLastMaps, strMap);
	if(GetArraySize(g_hArrayVoteMapLastMaps) > 64)
		RemoveFromArray(g_hArrayVoteMapLastMaps, 0);

	PlayersVotes_ResetKickVotes();
	PlayersVotes_ResetBanVotes();
	PlayersVotes_ResetMapVotes();
	PlayersVotes_ResetMuteVotes();

	for(new i = 0; i <= MAXPLAYERS; ++i)
	{
		g_iVoteKickCount[i] = 0;
		g_iVoteBanCount[i] = 0;
		g_iVoteMapCount[i] = 0;
		g_iVoteMuteCount[i] = 0;
		g_iVoteBanClients[i] = -1;
		g_bVoteMuteMuted[i] = false;
	}

	ClearArray(g_hArrayVoteMuteClientIdentity);
}

public OnClientDisconnect(iClient)
{
	g_bImmune[iClient] = false;
	g_iVoteKickLast[iClient] = 0;
	g_iVoteBanLast[iClient] = 0;
	g_iVoteMapLast[iClient] = 0;
	g_iVoteMuteLast[iClient] = 0;
	g_iVoteKickCount[iClient] = 0;
	g_iVoteBanCount[iClient] = 0;
	g_iVoteMapCount[iClient] = 0;
	g_iVoteMuteCount[iClient] = 0;
	g_iVoteBanClients[iClient] = -1;

	for(new i = 0; i <= MAXPLAYERS; i++)
	{
		g_bVoteKickFor[iClient][i] = false;
		g_bVoteKickFor[i][iClient] = false;
		g_bVoteMuteFor[iClient][i] = false;
		g_bVoteMuteFor[i][iClient] = false;
	}

	new iBanVotes = GetArraySize(g_hArrayVoteBanFor[iClient]);
	for(new i = 0; i < iBanVotes; ++i)
	{
		new iTarget = GetArrayCell(g_hArrayVoteBanFor[iClient], i);
		if(PlayersVotes_GetBanVotesForTarget(iTarget) == 1)
		{
			PlayersVotes_RemoveBanVotesFromTarget(iTarget);
			--i;
			--iBanVotes;
		}
	}

	ClearArray(g_hArrayVoteBanFor[iClient]);
	ClearArray(g_hArrayVoteBanForReason[iClient]);

	PlayersVotes_ResetClientMapVotes(iClient);

	if(g_bVoteMuteMuted[iClient] && !(GetClientListeningFlags(iClient) & VOICE_MUTED))
	{
		decl String:strClientAuth[33];
		PlayersVotes_GetIdentity(iClient, strClientAuth, sizeof(strClientAuth));

		new iRemoveMuteIndex = PlayersVotes_MatchIdentity(g_hArrayVoteMuteClientIdentity, strClientAuth);
		if(iRemoveMuteIndex != -1)
			RemoveFromArray(g_hArrayVoteMuteClientIdentity, iRemoveMuteIndex);
	}

	g_bVoteMuteMuted[iClient] = false;
}

public OnClientConnected(iClient)
{
	decl String:strIp[33];
	GetClientIP(iClient, strIp, sizeof(strIp));

	g_iVoteBanClients[iClient] = PlayersVotes_MatchIdentity(g_hArrayVoteBanClientIdentity, strIp);

	if(PlayersVotes_MatchIdentity(g_hArrayVoteMuteClientIdentity, strIp) != -1)
		g_bVoteMuteMuted[iClient] = true;

	new iBanTarget = g_iVoteBanClients[iClient];
	if(iBanTarget != -1)
	{
		decl String:strClientName[33];
		GetClientName(iClient, strClientName, sizeof(strClientName));

		decl String:strStoredName[33];
		GetArrayString(g_hArrayVoteBanClientNames, iBanTarget, strStoredName, sizeof(strStoredName));

		if(!StrEqual(strClientName, strStoredName))
		{
			PrintToChatAll("[SM] Bans: %s changed name to %s!", strStoredName, strClientName);
			SetArrayString(g_hArrayVoteBanClientNames, iBanTarget, strClientName);
		}

		SetArrayCell(g_hArrayVoteBanClientCurrentUserId, iBanTarget, GetClientUserId(iClient));
	}
}

public OnClientAuthorized(iClient, const String:strAuth[])
{
	if(PlayersVotes_MatchIdentity(g_hArrayVoteMuteClientIdentity, strAuth) != -1)
		g_bVoteMuteMuted[iClient] = true;

	new iBanTarget = g_iVoteBanClients[iClient];
	if(iBanTarget != -1)
	{
		if(PlayersVotes_IsValidAuth(strAuth))
			SetArrayString(g_hArrayVoteBanClientIdentity, iBanTarget, strAuth);
	}
	else
	{
		g_iVoteBanClients[iClient] = PlayersVotes_MatchIdentity(g_hArrayVoteBanClientIdentity, strAuth);
		iBanTarget = g_iVoteBanClients[iClient];
	}

	if(iBanTarget != -1)
	{
		decl String:strClientName[33];
		GetClientName(iClient, strClientName, sizeof(strClientName));

		decl String:strStoredName[33];
		GetArrayString(g_hArrayVoteBanClientNames, iBanTarget, strStoredName, sizeof(strStoredName));

		if(!StrEqual(strClientName, strStoredName))
		{
			PrintToChatAll("[SM] Bans: %s changed name to %s!", strStoredName, strClientName);
			SetArrayString(g_hArrayVoteBanClientNames, iBanTarget, strClientName);
		}

		SetArrayCell(g_hArrayVoteBanClientCurrentUserId, iBanTarget, GetClientUserId(iClient));
	}
}

public OnClientPostAdminCheck(iClient)
{
	if(g_bVoteMuteMuted[iClient])
		PlayersVotes_MutePlayer(iClient);

	if(g_iVoteImmunity > -1)
	{
		new AdminId:idTargetAdmin = GetUserAdmin(iClient);
		if(idTargetAdmin != INVALID_ADMIN_ID || CheckCommandAccess(iClient, "playersvotes_immunity", ADMFLAG_GENERIC))
		{
			if(GetAdminImmunityLevel(idTargetAdmin) >= g_iVoteImmunity)
				g_bImmune[iClient] = true;
		}
	}
}

// ====[ COMMANDS ]============================================================
public Action:Command_ChooseVote(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	Menu_ChooseVote(iClient);
	return Plugin_Handled;
}

public Action:Command_Reload(iClient, iArgs)
{
	Config_Load();
	ReplyToCommand(iClient, "[SM] Config 'playersvotes.cfg' reloaded");
	return Plugin_Handled;
}

public Action:OnClientSayCommand(iClient, const String:strCommand[], const String:sArgs[])
{
	if(!IsValidClient(iClient) || !g_bChatTriggers)
		return Plugin_Continue;

	decl String:strText[255];
	strcopy(strText, sizeof(strText), sArgs);
	StripQuotes(strText);

	new AdminId:idAdmin = GetUserAdmin(iClient);
	if(idAdmin == INVALID_ADMIN_ID)
	{
		ReplaceString(strText, sizeof(strText), "!", "");
		ReplaceString(strText, sizeof(strText), "/", "");
	}

	if(StrEqual(strText, "votekick", false))
		Menu_DisplayKickVote(iClient);
	else if(StrEqual(strText, "voteban", false))
		Menu_DisplayBanVote(iClient);
	else if(StrEqual(strText, "votemap", false))
		Menu_DisplayMapVote(iClient);
	else if(StrEqual(strText, "votemute", false))
		Menu_DisplayMuteVote(iClient);
	return Plugin_Continue;
}

// ====[ MENUS ]===============================================================
public Menu_ChooseVote(iClient)
{
	new bool:bCanceling = CheckCommandAccess(iClient, "playersvotes_canceling", ADMFLAG_GENERIC);
	if(!bCanceling && !g_bVoteKickEnabled && !g_bVoteBanEnabled && !g_bVoteMapEnabled && !g_bVoteMuteEnabled)
	{
		PrintToChat(iClient, "[SM] %t.", "all disabled votes");
		return;
	}

	new Handle:hMenu = CreateMenu(MenuHandler_ChooseVote);
	SetMenuTitle(hMenu, "%t:", "Voting Menu");

	decl String:strBuffer[56];
	if(g_bVoteKickEnabled && CheckCommandAccess(iClient, "playersvotes_kick", 0))
	{
		Format(strBuffer, sizeof(strBuffer), "%t", "Kick");
		AddMenuItem(hMenu, "Kick", strBuffer);
	}

	if(g_bVoteBanEnabled && CheckCommandAccess(iClient, "playersvotes_ban", 0))
	{
		Format(strBuffer, sizeof(strBuffer), "%t", "Ban");
		AddMenuItem(hMenu, "Ban", strBuffer);
	}

	if(g_bVoteMapEnabled && CheckCommandAccess(iClient, "playersvotes_map", 0))
	{
		Format(strBuffer, sizeof(strBuffer), "%t", "Map");
		AddMenuItem(hMenu, "Map", strBuffer);
	}

	if(g_bVoteMuteEnabled && CheckCommandAccess(iClient, "playersvotes_mute", 0))
	{
		Format(strBuffer, sizeof(strBuffer), "%t", "Mute");
		AddMenuItem(hMenu, "Mute", strBuffer);
	}

	if(bCanceling)
	{
		Format(strBuffer, sizeof(strBuffer), "%t", "Settings");
		AddMenuItem(hMenu, "Settings", strBuffer);
	}

	DisplayMenu(hMenu, iClient, 30);
}

public MenuHandler_ChooseVote(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		if(StrEqual(strInfo, "Kick"))
			Menu_DisplayKickVote(iParam1);
		else if(StrEqual(strInfo, "Ban"))
			Menu_DisplayBanVote(iParam1);
		if(StrEqual(strInfo, "Map"))
			Menu_DisplayMapVote(iParam1);
		if(StrEqual(strInfo, "Mute"))
			Menu_DisplayMuteVote(iParam1);
		if(StrEqual(strInfo, "Settings"))
			Menu_Settings(iParam1);
	}
}

public Menu_Settings(iClient)
{
	new Handle:hMenu = CreateMenu(MenuHandler_Settings);

	SetMenuTitle(hMenu, "%t:", "Settings");
	SetMenuExitBackButton(hMenu, true);

	decl String:strBuffer[56];
	if(CheckCommandAccess(iClient, "playersvotes_canceling", ADMFLAG_GENERIC))
	{
		Format(strBuffer, sizeof(strBuffer), "%t", "cancel map votes");
		AddMenuItem(hMenu, "CancelMap", strBuffer);

		Format(strBuffer, sizeof(strBuffer), "%t", "cancel ban votes");
		AddMenuItem(hMenu, "CancelBan", strBuffer);

		Format(strBuffer, sizeof(strBuffer), "%t", "cancel mute votes");
		AddMenuItem(hMenu, "CancelMute", strBuffer);

		Format(strBuffer, sizeof(strBuffer), "%t", "cancel kick votes");
		AddMenuItem(hMenu, "CancelKick", strBuffer);
	}

	DisplayMenu(hMenu, iClient, 30);
}

public MenuHandler_Settings(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel && iParam2 == MenuCancel_ExitBack)
	{
		if(iParam2 == MenuCancel_ExitBack)
			Menu_ChooseVote(iParam1);
	}
	else if(iAction == MenuAction_Select)
	{
		decl String:strInfo[16];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		if(StrEqual(strInfo, "CancelBan"))
		{
			PlayersVotes_ResetBanVotes();
			ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Ban");
		}
		else if(StrEqual(strInfo, "CancelMap"))
		{
			PlayersVotes_ResetMapVotes();
			ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Map");
		}
		else if(StrEqual(strInfo, "CancelMute"))
		{
			PlayersVotes_ResetMuteVotes();
			ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Mute");
		}
		else if(StrEqual(strInfo, "CancelKick"))
		{
			PlayersVotes_ResetKickVotes();
			ShowActivity2(iParam1, "[SM] ", "%t.", "canceled votes", "Kick");
		}
	}
}

//  _  ___    _
// | |/ (_)__| |__
// | ' <| / _| / /
// |_|\_`_`__|_`_`
//

public Menu_DisplayKickVote(iClient)
{
	if(!g_bVoteKickEnabled)
		return;

	if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_kick", 0))
	{
		ReplyToCommand(iClient, "[SM] %t.", "No Access");
		return;
	}

	if(g_iVoteKickLimit != 0 && g_iVoteKickLimit <= g_iVoteKickCount[iClient])
	{
		PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteKickLimit, "Votekick");
		return;
	}

	new iTime = GetTime();
	new iFromLast = iTime - g_iVoteKickLast[iClient];
	if(iFromLast < g_iVoteKickInterval)
	{
		PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteKickInterval - iFromLast);
		return;
	}

	new iFromStart = iTime - g_iStartTime;
	if(iFromStart < g_iVoteKickDelay)
	{
		PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteKickDelay - iFromStart);
		return;
	}

	g_iVoteKickLast[iClient] = iTime;

	new Handle:hMenu = CreateMenu(MenuHandler_DisplayKickVote);
	if(g_iVoteKickLimit > 0)
		SetMenuTitle(hMenu, "%t: %t", "Votekick", "votes remaining", g_iVoteKickLimit - g_iVoteKickCount[iClient]);
	else
		SetMenuTitle(hMenu, "%t:", "Votekick");
	SetMenuExitBackButton(hMenu, true);

	decl String:strName[MAX_NAME_LENGTH + 12];
	decl String:strClient[8];

	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsFakeClient(i))
			continue;

		if(g_bVoteKickTeam && GetClientTeam(iClient) != GetClientTeam(i))
			continue;

		if(i == iClient || g_bImmune[i])
			continue;

		new iVotes = PlayersVotes_GetKickVotesForTarget(i);
		new iRequired = PlayersVotes_GetRequiredKickVotes(iClient);

		IntToString(i, strClient, sizeof(strClient));
		Format(strName, sizeof(strName), "%N [%d/%d]", i, iVotes, iRequired);

		if(iVotes > 0)
		{
			if(i == 1)
				AddMenuItem(hMenu, strClient, strName);
			else
				InsertMenuItem(hMenu, 0, strClient, strName);
		}
		else
			AddMenuItem(hMenu, strClient, strName);
	}

	DisplayMenu(hMenu, iClient, 30);
}

public MenuHandler_DisplayKickVote(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel)
	{
		if(iParam2 == MenuCancel_ExitBack)
			Menu_ChooseVote(iParam1);
	}
	else if(iAction == MenuAction_Select)
	{
		decl String:strInfo[8];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		new iTarget = StringToInt(strInfo);
		if(IsValidClient(iTarget) && !IsFakeClient(iTarget))
		{
			g_bVoteKickFor[iParam1][iTarget] = true;
			g_iVoteKickCount[iParam1] += 1;
			PlayersVotes_CheckKickVotes(iParam1, iTarget);
		}
	}
}

//  ___
// | _ ) __ _ _ _
// | _ \/ _` | ' `
// |___/\__,_|_||_|
//

public Menu_DisplayBanVote(iClient)
{
	if(!g_bVoteBanEnabled)
		return;

	if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_ban", 0))
	{
		ReplyToCommand(iClient, "[SM] %t.", "No Access");
		return;
	}

	if(g_iVoteBanLimit != 0 && g_iVoteBanLimit <= g_iVoteBanCount[iClient])
	{
		PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteBanLimit, "Voteban");
		return;
	}

	new iTime = GetTime();
	new iFromLast = iTime - g_iVoteBanLast[iClient];
	if(iFromLast < g_iVoteBanInterval)
	{
		PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteBanInterval - iFromLast);
		return;
	}

	new iFromStart = iTime - g_iStartTime;
	if(iFromStart < g_iVoteBanDelay)
	{
		PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteBanDelay - iFromStart);
		return;
	}

	g_iVoteBanLast[iClient] = GetTime();

	new Handle:hMenu = CreateMenu(MenuHandler_DisplayBanVote);
	if(g_iVoteBanLimit > 0)
		SetMenuTitle(hMenu, "%t: %t", "Voteban", "votes remaining", g_iVoteBanLimit - g_iVoteBanCount[iClient]);
	else
		SetMenuTitle(hMenu, "%t:", "Voteban");
	SetMenuExitBackButton(hMenu, true);

	decl String:strName[72];
	decl String:strUserId[8];

	new iRequired = PlayersVotes_GetRequiredBanVotes(iClient);
	for(new i = 0; i < GetArraySize(g_hArrayVoteBanClientNames); ++i)
	{
		new iTarget = GetClientOfUserId(GetArrayCell(g_hArrayVoteBanClientCurrentUserId, i));
		new bool:bShowTarget;
		if(g_bVoteBanTeam)
		{
			new iTeam = GetClientTeam(iClient);
			if(iTarget != 0)
			{
				if(iTeam == GetClientTeam(iTarget))
					bShowTarget = true;
			}

			if(GetArrayCell(g_hArrayVoteBanClientTeam, i) == iTeam)
				bShowTarget = true;
		}
		else
			bShowTarget = true;

		if(bShowTarget)
		{
			decl String:strBanName[33];

			GetArrayString(g_hArrayVoteBanClientNames, i, strBanName, sizeof(strBanName));

			IntToString(GetArrayCell(g_hArrayVoteBanClientUserIds, i), strUserId, sizeof(strUserId));
			Format(strName, sizeof(strName), "%s [%d/%d]", strBanName, PlayersVotes_GetBanVotesForTarget(i), iRequired);

			AddMenuItem(hMenu, strUserId, strName);
		}
	}

	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsFakeClient(i))
			continue;

		if(g_iVoteBanClients[i] != -1)
			continue;

		if(g_bVoteBanTeam && GetClientTeam(iClient) != GetClientTeam(i))
			continue;

		if(i == iClient || g_bImmune[i])
			continue;

		IntToString(GetClientUserId(i), strUserId, sizeof(strUserId));
		Format(strName, sizeof(strName), "%N [0/%d]", i, iRequired);

		AddMenuItem(hMenu, strUserId, strName);
	}

	DisplayMenu(hMenu, iClient, 30);
}

public MenuHandler_DisplayBanVote(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel)
	{
		if(iParam2 == MenuCancel_ExitBack)
			Menu_ChooseVote(iParam1);
	}
	else if(iAction == MenuAction_Select)
	{
		decl String:strInfo[8];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		new iTarget = StringToInt(strInfo);
		if(GetArraySize(g_hArrayVoteBanReasons) > 0)
			Menu_BanReason(iParam1, iTarget);
		else
			PlayersVotes_ProcessBanVote(iParam1, iTarget, -1);
	}
}

public Menu_BanReason(iClient, iTarget)
{
	new iNumReasons = GetArraySize(g_hArrayVoteBanReasons);
	if(iNumReasons <= 0)
	{
		PlayersVotes_ProcessBanVote(iClient, iTarget, -1);
		return;
	}

	new Handle:hMenu = CreateMenu(MenuHandler_BanReason);

	decl String:strTitle[32];
	Format(strTitle, sizeof(strTitle), "%t:", "ban reasons");
	SetMenuTitle(hMenu, strTitle);

	decl String:strTarget[8];
	Format(strTarget, sizeof(strTarget), "%d", iTarget);

	decl String:strReason[33];
	for(new i = 0; i < iNumReasons; ++i)
	{
		GetArrayString(g_hArrayVoteBanReasons, i, strReason, sizeof(strReason));
		AddMenuItem(hMenu, strTarget, strReason);
	}

	DisplayMenu(hMenu, iClient, 30);
}

public MenuHandler_BanReason(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Select)
	{
		decl String:strInfo[8];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		new iTarget = StringToInt(strInfo);
		PlayersVotes_ProcessBanVote(iParam1, iTarget, iParam2);
	}
}

//  __  __
// |  \/  |__ _ _ __
// | |\/| / _` | '_ `
// |_|  |_`__,_| .__/
//

public Menu_DisplayMapVote(iClient)
{
	if(!g_bVoteMapEnabled)
		return;

	if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_map", 0))
	{
		ReplyToCommand(iClient, "[SM] %t.", "No Access");
		return;
	}

	new iTime = GetTime();
	if(g_iVoteMapLimit != 0 && g_iVoteMapLimit <= g_iVoteMapCount[iClient])
	{
		PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteMapLimit, "Votemap");
		return;
	}

	new iFromLast = iTime - g_iVoteMapLast[iClient];
	if(iFromLast < g_iVoteMapInterval)
	{
		PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteMapInterval - iFromLast);
		return;
	}

	new iFromStart = iTime - g_iStartTime;
	if(iFromStart < g_iVoteMapDelay)
	{
		PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteMapDelay - iFromStart);
		return;
	}

	g_iVoteMapLast[iClient] = iTime;

	new Handle:hMenu = CreateMenu(MenuHandler_DisplayMapVote);
	if(g_iVoteMapLimit > 0)
		SetMenuTitle(hMenu, "%t: %t", "Votemap", "votes remaining", g_iVoteMapLimit - g_iVoteMapCount[iClient]);
	else
		SetMenuTitle(hMenu, "%t:", "Votemap");
	SetMenuExitBackButton(hMenu, true);

	decl String:strMap[65];
	decl String:strClient[8];

	new bool:bExtendAdded;
	for(new i = 0; i < GetArraySize(g_hArrayVoteMapList); i++)
	{
		GetArrayString(g_hArrayVoteMapList, i, strMap, sizeof(strMap));
		if(IsMapValid(strMap))
		{
			if (StrContains(strMap, "workshop", false) != -1)
			{
				Format(strMap, sizeof(strMap), strMap[19]);
			}
			if(g_iVoteMapCurrent == i && g_iVoteMapMaxExtends != 0 && g_iVoteMapExtendTime > 0)
			{
				new iVotes = PlayersVotes_GetMapVotesForTarget(i);
				new iRequired = PlayersVotes_GetRequiredMapVotes(iClient);

				IntToString(i, strClient, sizeof(strClient));
				Format(strMap, sizeof(strMap), "%t [%d/%d]", "extend map by", g_iVoteMapExtendTime, iVotes, iRequired);

				if(g_iVoteMapCurrent == 0)
					AddMenuItem(hMenu, strClient, strMap);
				else
					InsertMenuItem(hMenu, 0, strClient, strMap);

				bExtendAdded = true;
			}
			else if(!PlayersVotes_IsLastPlayed(strMap))
			{
				new iVotes = PlayersVotes_GetMapVotesForTarget(i);
				new iRequired = PlayersVotes_GetRequiredMapVotes(iClient);

				IntToString(i, strClient, sizeof(strClient));
				Format(strMap, sizeof(strMap), "%s [%d/%d]", strMap, iVotes, iRequired);

				if(iVotes > 0)
				{
					if(bExtendAdded)
						InsertMenuItem(hMenu, 1, strClient, strMap);
					else if(i == 0)
						AddMenuItem(hMenu, strClient, strMap);
					else
						InsertMenuItem(hMenu, 0, strClient, strMap);
				}
				else
					AddMenuItem(hMenu, strClient, strMap);
			}
		}
	}

	DisplayMenu(hMenu, iClient, 30);
}

public MenuHandler_DisplayMapVote(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel)
	{
		if(iParam2 == MenuCancel_ExitBack)
			Menu_ChooseVote(iParam1);
	}
	else if(iAction == MenuAction_Select)
	{
		decl String:strInfo[8];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		new iTarget = StringToInt(strInfo);
		PlayersVotes_ResetClientMapVotes(iParam1);
		SetArrayCell(g_hArrayVotedForMap[iParam1], iTarget, 1);
		g_iVoteMapCount[iParam1] += 1;
		PlayersVotes_CheckMapVotes(iParam1, iTarget);
	}
}

//  __  __      _
// |  \/  |_  _| |_ ___
// | |\/| | || |  _/ -_)
// |_|  |_|\_,_|\__`___|
//

public Menu_DisplayMuteVote(iClient)
{
	if(!g_bVoteMuteEnabled)
		return;

	if(!CheckCommandAccess(iClient, "sm_votemenu", 0) || !CheckCommandAccess(iClient, "playersvotes_mute", 0))
	{
		ReplyToCommand(iClient, "[SM] %t.", "No Access");
		return;
	}

	if(g_iVoteMuteLimit != 0 && g_iVoteMuteLimit <= g_iVoteMuteCount[iClient])
	{
		PrintToChat(iClient, "[SM] %t.", "votes spent", g_iVoteMuteLimit, "Votemute");
		return;
	}

	new iTime = GetTime();
	new iFromLast = iTime - g_iVoteMuteLast[iClient];
	if(iFromLast < g_iVoteMuteInterval)
	{
		PrintToChat(iClient, "[SM] %t.", "voting not allowed again", g_iVoteMuteInterval - iFromLast);
		return;
	}

	new iFromStart = iTime - g_iStartTime;
	if(iFromStart < g_iVoteMuteDelay)
	{
		PrintToChat(iClient, "[SM] %t.", "voting not allowed", g_iVoteMuteDelay - iFromStart);
		return;
	}

	g_iVoteMuteLast[iClient] = iTime;

	new Handle:hMenu = CreateMenu(MenuHandler_DisplayMuteVote);
	if(g_iVoteMuteLimit > 0)
		SetMenuTitle(hMenu, "%t: %t", "Votemute", "votes remaining", g_iVoteMuteLimit - g_iVoteMuteCount[iClient]);
	else
		SetMenuTitle(hMenu, "%t:", "Votemute");
	SetMenuExitBackButton(hMenu, true);

	decl String:strName[72];
	decl String:strClient[8];

	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsFakeClient(i))
			continue;

		if(g_bVoteMuteTeam && GetClientTeam(iClient) != GetClientTeam(i))
			continue;

		if(i == iClient || g_bImmune[i] || g_bVoteMuteMuted[iClient])
			continue;

		new iVotes = PlayersVotes_GetMuteVotesForTarget(i);
		new iRequired = PlayersVotes_GetRequiredMuteVotes(iClient);

		IntToString(i, strClient, sizeof(strClient));
		Format(strName, sizeof(strName), "%N [%d/%d]", i, iVotes, iRequired);

		if(iVotes > 0)
		{
			if(i == 1)
				AddMenuItem(hMenu, strClient, strName);
			else
				InsertMenuItem(hMenu, 0, strClient, strName);
		}
		else
			AddMenuItem(hMenu, strClient, strName);
	}

	DisplayMenu(hMenu, iClient, 30);
}

public MenuHandler_DisplayMuteVote(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
	{
		CloseHandle(hMenu);
		return;
	}

	if(iAction == MenuAction_Cancel)
	{
		if(iParam2 == MenuCancel_ExitBack)
			Menu_ChooseVote(iParam1);
	}
	else if(iAction == MenuAction_Select)
	{
		decl String:strInfo[8];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));

		new iTarget = StringToInt(strInfo);
		if(IsValidClient(iTarget) && !IsFakeClient(iTarget))
		{
			g_bVoteMuteFor[iParam1][iTarget] = true;
			g_iVoteMuteCount[iParam1] += 1;
			PlayersVotes_CheckMuteVotes(iParam1, iTarget);
		}
	}
}

// ====[ FUNCTIONS ]===========================================================
public Config_Load()
{
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Configuration file %s not found!", g_strConfigFile);
		return;
	}

	new Handle:hKeyValues = CreateKeyValues("playersvotes");
	if(!FileToKeyValues(hKeyValues, g_strConfigFile))
	{
		SetFailState("Configuration file %s not found!", g_strConfigFile);
		return;
	}

	g_bChatTriggers = bool:KvGetNum(hKeyValues, "chattriggers", 1);
	g_iVoteImmunity = KvGetNum(hKeyValues, "immunity", 0);

	if(KvGotoFirstSubKey(hKeyValues))
	{
		decl String:strSection[32];
		do
		{
			KvGetSectionName(hKeyValues, strSection, sizeof(strSection));

			if(StrEqual(strSection, "kick"))
			{
				g_bVoteKickEnabled = bool:KvGetNum(hKeyValues, "enabled", 1);
				PrintToServer("%i", g_bVoteKickEnabled);
				g_flVoteKickRatio = KvGetFloat(hKeyValues, "ratio", 0.6);
				g_iVoteKickMinimum = KvGetNum(hKeyValues, "minimum", 4);
				g_iVoteKickDelay = KvGetNum(hKeyValues, "delay", 1);
				g_iVoteKickLimit = KvGetNum(hKeyValues, "limit", 0);
				g_iVoteKickInterval = KvGetNum(hKeyValues, "interval", 0);
				g_bVoteKickTeam = bool:KvGetNum(hKeyValues, "team", 0);
			}
			else if(StrEqual(strSection, "ban"))
			{
				g_bVoteBanEnabled = bool:KvGetNum(hKeyValues, "enabled", 1);
				g_flVoteBanRatio = KvGetFloat(hKeyValues, "ratio", 0.8);
				g_iVoteBanMinimum = KvGetNum(hKeyValues, "minimum", 4);
				g_iVoteBanDelay = KvGetNum(hKeyValues, "delay", 1);
				g_iVoteBanLimit = KvGetNum(hKeyValues, "limit", 0);
				g_iVoteBanInterval = KvGetNum(hKeyValues, "interval", 0);
				g_bVoteBanTeam = bool:KvGetNum(hKeyValues, "team", 0);
				g_iVoteBanTime = KvGetNum(hKeyValues, "time", 30);
				KvGetString(hKeyValues, "reasons", g_strVoteBanReasons, sizeof(g_strVoteBanReasons));

				ClearArray(g_hArrayVoteBanReasons);

				decl String:strBanReasonList[256];
				strcopy(strBanReasonList, sizeof(strBanReasonList), g_strVoteBanReasons);
				StrCat(strBanReasonList, sizeof(strBanReasonList), ";");

				new iBanReasonOffset;
				decl String:strBanReason[33];
				for(new i = SplitString(strBanReasonList, ";", strBanReason, sizeof(strBanReason)); i != -1; i = SplitString(strBanReasonList[iBanReasonOffset], ";", strBanReason, sizeof(strBanReason)))
				{
					iBanReasonOffset += i;
					TrimString(strBanReason);
					if(!StrEqual(strBanReason, ""))
						PushArrayString(g_hArrayVoteBanReasons, strBanReason);
				}
			}
			else if(StrEqual(strSection, "map"))
			{
				g_bVoteMapEnabled = bool:KvGetNum(hKeyValues, "enabled", 1);
				g_flVoteMapRatio = KvGetFloat(hKeyValues, "ratio", 0.6);
				g_iVoteMapMinimum = KvGetNum(hKeyValues, "minimum", 4);
				g_iVoteMapDelay = KvGetNum(hKeyValues, "delay", 1);
				g_iVoteMapLimit = KvGetNum(hKeyValues, "limit", 0);
				g_iVoteMapInterval = KvGetNum(hKeyValues, "interval", 0);
				g_iVoteMapLastMaps = KvGetNum(hKeyValues, "lastmaps", 4);
				g_iVoteMapExtendTime = KvGetNum(hKeyValues, "extendtime", 20);
				g_iVoteMapMaxExtends = KvGetNum(hKeyValues, "maxextends", 1);
				g_bVoteMapMode = bool:KvGetNum(hKeyValues, "mode", 1);
			}
			else if(StrEqual(strSection, "mute"))
			{
				g_bVoteMuteEnabled = bool:KvGetNum(hKeyValues, "enabled", 1);
				g_flVoteMuteRatio = KvGetFloat(hKeyValues, "ratio", 0.6);
				g_iVoteMuteMinimum = KvGetNum(hKeyValues, "minimum", 4);
				g_iVoteMuteDelay = KvGetNum(hKeyValues, "delay", 1);
				g_iVoteMuteLimit = KvGetNum(hKeyValues, "limit", 0);
				g_iVoteMuteInterval = KvGetNum(hKeyValues, "interval", 0);
				g_bVoteMuteTeam = bool:KvGetNum(hKeyValues, "team", 0);
			}
		}
		while(KvGotoNextKey(hKeyValues));
	}
	CloseHandle(hKeyValues);
}

//  _  ___    _
// | |/ (_)__| |__
// | ' <| / _| / /
// |_|\_`_`__|_`_`
//

public PlayersVotes_ResetKickVotes()
{
	for(new iClient = 0; iClient <= MAXPLAYERS; ++iClient)
	{
		for(new iTarget = 0; iTarget <= MAXPLAYERS; ++iTarget)
			g_bVoteKickFor[iClient][iTarget] = false;
	}
}

public PlayersVotes_CheckKickVotes(iVoter, iTarget)
{
	new iVotesRequired = PlayersVotes_GetRequiredKickVotes(iVoter);
	new iVotes = PlayersVotes_GetKickVotesForTarget(iTarget);

	decl String:strVoterName[65];
	GetClientName(iVoter, strVoterName, sizeof(strVoterName));

	decl String:strTargetName[65];
	GetClientName(iTarget, strTargetName, sizeof(strTargetName));

	PrintToChatAll("[SM] %t.", "voted to kick", strVoterName, strTargetName);

	if(iVotes < iVotesRequired)
	{
		PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
		return;
	}

	PrintToChatAll("[SM] %t.", "kicked by vote", strTargetName);
	LogAction(-1, iTarget, "Vote kick successful, kicked \"%L\" (iReason \"voted by players\")", iTarget);
	ServerCommand("kickid %d %t", GetClientUserId(iTarget), "kicked by users");
}

public PlayersVotes_GetRequiredKickVotes(iVoter)
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsFakeClient(i))
			continue;

		if(g_bVoteKickTeam && GetClientTeam(i) != GetClientTeam(iVoter))
			continue;

		iCount++;
	}

	new iRequired = RoundToCeil(float(iCount) * g_flVoteKickRatio);
	if(iRequired < g_iVoteKickMinimum)
		iRequired = g_iVoteKickMinimum;

	return iRequired;
}

public PlayersVotes_GetKickVotesForTarget(iTarget)
{
	new iVotes;
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(g_bVoteKickFor[i][iTarget])
			iVotes++;
	}
	return iVotes;
}

//  ___
// | _ ) __ _ _ _
// | _ \/ _` | ' `
// |___/\__,_|_||_|
//

public PlayersVotes_ResetBanVotes()
{
	ClearArray(g_hArrayVoteBanClientUserIds);
	ClearArray(g_hArrayVoteBanClientCurrentUserId);
	ClearArray(g_hArrayVoteBanClientTeam);
	ClearArray(g_hArrayVoteBanClientIdentity);
	ClearArray(g_hArrayVoteBanClientNames);
	for(new iClient = 0; iClient <= MAXPLAYERS; ++iClient)
	{
		ClearArray(g_hArrayVoteBanFor[iClient]);
		ClearArray(g_hArrayVoteBanForReason[iClient]);
		g_iVoteBanClients[iClient] = -1;
	}
}

public PlayersVotes_RemoveBanVotesFromTarget(iTarget)
{
	RemoveFromArray(g_hArrayVoteBanClientUserIds, iTarget);
	RemoveFromArray(g_hArrayVoteBanClientCurrentUserId, iTarget);
	RemoveFromArray(g_hArrayVoteBanClientTeam, iTarget);
	RemoveFromArray(g_hArrayVoteBanClientIdentity, iTarget);
	RemoveFromArray(g_hArrayVoteBanClientNames, iTarget);
	for(new i = 1; i <= MAXPLAYERS; ++i)
	{
		new iVoteToRemove = -1;
		for(new j = 0; j < GetArraySize(g_hArrayVoteBanFor[i]); ++j)
		{
			new iVote = GetArrayCell(g_hArrayVoteBanFor[i], j);
			if(iVote == iTarget)
				iVoteToRemove = j;
			else if(iVote > iTarget)
				SetArrayCell(g_hArrayVoteBanFor[i], j, iVote - 1);
		}
		if(iVoteToRemove != -1)
		{
			RemoveFromArray(g_hArrayVoteBanFor[i], iVoteToRemove);
			RemoveFromArray(g_hArrayVoteBanForReason[i], iVoteToRemove);
		}
		if(g_iVoteBanClients[i] == iTarget)
			g_iVoteBanClients[i] = -1;
		else if(g_iVoteBanClients[i] > iTarget)
			--g_iVoteBanClients[i];
	}
}

public PlayersVotes_CheckBanVotes(iVoter, iTarget)
{
	new iVotesRequired = PlayersVotes_GetRequiredBanVotes(iVoter);
	new iVotes = PlayersVotes_GetBanVotesForTarget(iTarget);

	decl String:strVoterName[65];
	GetClientName(iVoter, strVoterName, sizeof(strVoterName));

	decl String:strTargetName[65];
	GetArrayString(g_hArrayVoteBanClientNames, iTarget, strTargetName, sizeof(strTargetName));

	PrintToChatAll("[SM] %t.", "voted to ban", strVoterName, strTargetName);

	if(iVotes < iVotesRequired)
	{
		PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
		return;
	}

	new iUserId = GetArrayCell(g_hArrayVoteBanClientCurrentUserId, iTarget);
	new iClientId = GetClientOfUserId(iUserId);

	new iBanFlags = BANFLAG_AUTHID;
	decl String:strIdentity[33];
	GetArrayString(g_hArrayVoteBanClientIdentity, iTarget, strIdentity, sizeof(strIdentity));
	if(strncmp(strIdentity, "STEAM", 5) != 0)
		iBanFlags = BANFLAG_IP;

	new iReason = PlayersVotes_GetBanReason(iTarget);
	decl String:strVoteReason[33];
	decl String:strReason[100];
	if(iReason > -1)
	{
		GetArrayString(g_hArrayVoteBanReasons, iReason, strVoteReason, sizeof(strVoteReason));
		PrintToChatAll("[SM] %t (\x05%s\x01).", "banned by vote", strTargetName, strVoteReason);
		if(iClientId > 0)
			Format(strReason, sizeof(strReason), "%t (%s)", "banned by users", strVoteReason);
		else
			Format(strReason, sizeof(strReason), "(%s) %t (%s)", strTargetName, "banned by users", strVoteReason);
	}
	else
	{
		strcopy(strVoteReason, sizeof(strVoteReason), "unspecified");
		PrintToChatAll("[SM] %t.", "banned by vote", strTargetName);
		if(iClientId > 0)
			Format(strReason, sizeof(strReason), "%t", "banned by users");
		else
			Format(strReason, sizeof(strReason), "(%s) %t", strTargetName, "banned by users");
	}

	LogAction(-1, -1, "Vote ban successful, banned \"%s\" (iReason \"%s\")", strTargetName, strVoteReason);

	if(g_hCvarVoteBanSB == INVALID_HANDLE)
		BanIdentity(strIdentity, g_iVoteBanTime, iBanFlags, strReason, "players vote");
	else
	{
		if(iClientId > 0)
			ServerCommand("sm_ban #%d %d \"%s\"", iUserId, g_iVoteBanTime, strReason);
		else if(iBanFlags == BANFLAG_AUTHID)
			ServerCommand("sm_addban %d %s \"%s\"", g_iVoteBanTime, strIdentity, strReason);
		else
			ServerCommand("sm_banip %s %d \"%s\"", strIdentity, g_iVoteBanTime, strReason);
	}

	if(iBanFlags == BANFLAG_AUTHID)
		ServerCommand("kickid %d %s", iUserId, strReason);

	PlayersVotes_RemoveBanVotesFromTarget(iTarget);
}

public PlayersVotes_GetRequiredBanVotes(iVoter)
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsFakeClient(i))
			continue;

		if(g_bVoteBanTeam && GetClientTeam(i) != GetClientTeam(iVoter))
			continue;

		iCount++;
	}

	new iRequired = RoundToCeil(float(iCount) * g_flVoteBanRatio);
	if(iRequired < g_iVoteBanMinimum)
		iRequired = g_iVoteBanMinimum;

	return iRequired;
}

public PlayersVotes_GetBanVotesForTarget(iTarget)
{
	new iVotes;
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		new iBanVotes = GetArraySize(g_hArrayVoteBanFor[i]);
		for(new j = 0; j < iBanVotes; ++j)
		{
			if(GetArrayCell(g_hArrayVoteBanFor[i], j) == iTarget)
				iVotes++;
		}
	}
	return iVotes;
}

public PlayersVotes_ProcessBanVote(iVoter, iTarget, iReason)
{
	new iTargetIndex = FindValueInArray(g_hArrayVoteBanClientUserIds, iTarget);
	if(iTargetIndex == -1)
	{
		new iClient = GetClientOfUserId(iTarget);
		if(IsValidClient(iClient) && !IsFakeClient(iClient))
		{
			decl String:strClientName[MAX_NAME_LENGTH];
			GetClientName(iClient, strClientName, sizeof(strClientName));

			decl String:strClientAuth[24];
			PlayersVotes_GetIdentity(iClient, strClientAuth, sizeof(strClientAuth));

			PushArrayCell(g_hArrayVoteBanClientUserIds, iTarget);
			PushArrayString(g_hArrayVoteBanClientNames, strClientName);
			PushArrayString(g_hArrayVoteBanClientIdentity, strClientAuth);
			PushArrayCell(g_hArrayVoteBanClientCurrentUserId, iTarget);
			PushArrayCell(g_hArrayVoteBanClientTeam, GetClientTeam(iClient));

			g_iVoteBanClients[iClient] = GetArraySize(g_hArrayVoteBanClientNames) - 1;
			iTargetIndex = g_iVoteBanClients[iClient];
		}
	}

	if(iTargetIndex != -1)
	{
		new bool:bDuplicateVote;
		for(new i = 0; i < GetArraySize(g_hArrayVoteBanFor[iVoter]); ++i)
		{
			if(GetArrayCell(g_hArrayVoteBanFor[iVoter], i) == iTargetIndex)
				bDuplicateVote = true;
		}

		if(!bDuplicateVote)
		{
			PushArrayCell(g_hArrayVoteBanFor[iVoter], iTargetIndex);
			PushArrayCell(g_hArrayVoteBanForReason[iVoter], iReason);
		}

		g_iVoteBanCount[iVoter] += 1;
		PlayersVotes_CheckBanVotes(iVoter, iTargetIndex);
	}
}

public PlayersVotes_GetBanReason(iTarget)
{
	if(GetArraySize(g_hArrayVoteBanReasons) <= 0)
		return -1;

	new Handle:hReasonTally = CreateArray(1, GetArraySize(g_hArrayVoteBanReasons));

	for(new i = 0; i < GetArraySize(hReasonTally); ++i)
		SetArrayCell(hReasonTally, i, 0);

	new iTargetIndex;
	for(new i = 1; i <= MAXPLAYERS; ++i)
	{
		iTargetIndex = FindValueInArray(g_hArrayVoteBanFor[i], iTarget);
		if(iTargetIndex >= 0)
		{
			new iReason = GetArrayCell(g_hArrayVoteBanForReason[i], iTargetIndex);
			new iCount = GetArrayCell(hReasonTally, iReason);
			SetArrayCell(hReasonTally, iReason, iCount + 1);
		}
	}

	new iFinalReason = -1;
	new iFinalReasonCount;
	for(new i = 0; i < GetArraySize(hReasonTally); ++i)
	{
		if(iFinalReasonCount < GetArrayCell(hReasonTally, i))
		{
			iFinalReasonCount = GetArrayCell(hReasonTally, i);
			iFinalReason = i;
		}
	}

	CloseHandle(hReasonTally);
	return iFinalReason;
}

//  __  __
// |  \/  |__ _ _ __
// | |\/| / _` | '_ `
// |_|  |_`__,_| .__/
//             |_|

public PlayersVotes_ResetMapVotes()
{
	new iMapCount = GetArraySize(g_hArrayVoteMapList);
	for(new iClient = 0; iClient <= MAXPLAYERS; ++iClient)
	{
		ResizeArray(g_hArrayVotedForMap[iClient], iMapCount);
		PlayersVotes_ResetClientMapVotes(iClient);
	}
}

public PlayersVotes_CheckMapVotes(iVoter, iTarget)
{
	new iVotesRequired = PlayersVotes_GetRequiredMapVotes(iVoter);
	new iVotes = PlayersVotes_GetMapVotesForTarget(iTarget);

	decl String:strVoterName[65];
	GetClientName(iVoter, strVoterName, sizeof(strVoterName));

	decl String:strMap[32];
	GetArrayString(g_hArrayVoteMapList, iTarget, strMap, sizeof(strMap));
	if(!IsMapValid(strMap))
		return;

	if(g_iVoteMapCurrent == iTarget && g_iVoteMapMaxExtends != 0 && g_iVoteMapExtendTime > 0)
	{
		PrintToChatAll("[SM] %t.", "voted for extend", strVoterName, g_iVoteMapExtendTime);

		if(iVotes < iVotesRequired)
		{
			PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
			return;
		}

		PrintToChatAll("[SM] %t.", "map extend by vote", g_iVoteMapExtendTime);
		LogAction(-1, -1, "Extending map to due to players vote.");
		SetConVarFloat(g_hCvarVoteMapTimeLimit, GetConVarFloat(g_hCvarVoteMapTimeLimit) + g_iVoteMapExtendTime);

		if(g_iVoteMapMaxExtends > 0)
			g_iVoteMapMaxExtends =- 1;

		PlayersVotes_ResetMapVotes();
	}
	else
	{
		if(g_bVoteMapMode)
			PrintToChatAll("[SM] %t.", "voted for map", strVoterName, strMap);
		else
			PrintToChatAll("[SM] %t.", "voted for nextmap", strVoterName, strMap);

		if(iVotes < iVotesRequired)
		{
			PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
			return;
		}

		if(g_bVoteMapMode)
		{
			PrintToChatAll("[SM] %t.", "map change by vote", strMap);
			LogAction(-1, -1, "Changing map to %s due to players vote.", strMap);
			ServerCommand("sm_map \"%s\"", strMap);
		}
		else
		{
			PrintToChatAll("[SM] %t.", "nextmap change by vote", strMap);
			if(SetNextMap(strMap))
				LogAction(-1, -1, "Setting nextmap to %s due to players vote.", strMap);
			else
				LogAction(-1, -1, "ERROR: Failed to set nextmap to %s", strMap);

			PlayersVotes_ResetMapVotes();
		}
	}
}

public PlayersVotes_GetRequiredMapVotes(iVoter)
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsFakeClient(i))
			continue;

		iCount++;
	}

	new iRequired = RoundToCeil(float(iCount) * g_flVoteMapRatio);
	if(iRequired < g_iVoteMapMinimum)
		iRequired = g_iVoteMapMinimum;

	return iRequired;
}

public PlayersVotes_GetMapVotesForTarget(iTarget)
{
	new iVotes;
	for(new i = 1; i <= MAXPLAYERS; ++i)
		iVotes += GetArrayCell(g_hArrayVotedForMap[i], iTarget);
	return iVotes;
}

public PlayersVotes_ResetClientMapVotes(iClient)
{
	for(new iTarget = 0; iTarget < GetArraySize(g_hArrayVotedForMap[iClient]); ++iTarget)
		SetArrayCell(g_hArrayVotedForMap[iClient], iTarget, 0);
}

public PlayersVotes_IsLastPlayed(const String:strMap[])
{
	new iEndOfLastMapList = GetArraySize(g_hArrayVoteMapLastMaps);
	new iOldestMapToCheck = iEndOfLastMapList - g_iVoteMapLastMaps;
	if(iOldestMapToCheck < 0)
		iOldestMapToCheck = 0;

	decl String:strMap2[64];
	for(new i = iOldestMapToCheck; i < iEndOfLastMapList; ++i)
	{
		GetArrayString(g_hArrayVoteMapLastMaps, i, strMap2, sizeof(strMap2));
		if(StrEqual(strMap2, strMap, false))
			return true;
	}

	return false;
}

//  __  __      _
// |  \/  |_  _| |_ ___
// | |\/| | || |  _/ -_)
// |_|  |_|\_,_|\__`___|
//

public PlayersVotes_ResetMuteVotes()
{
	for(new iClient = 0; iClient <= MAXPLAYERS; ++iClient)
	{
		for(new iTarget = 0; iTarget <= MAXPLAYERS; ++iTarget)
			g_bVoteMuteFor[iClient][iTarget] = false;
	}
}

public PlayersVotes_CheckMuteVotes(iVoter, iTarget)
{
	new iVotesRequired = PlayersVotes_GetRequiredMuteVotes(iVoter);
	new iVotes = PlayersVotes_GetMuteVotesForTarget(iTarget);

	decl String:strVoterName[65];
	GetClientName(iVoter, strVoterName, sizeof(strVoterName));

	decl String:strTargetName[65];
	GetClientName(iTarget, strTargetName, sizeof(strTargetName));

	PrintToChatAll("[SM] %t.", "voted to mute", strVoterName, strTargetName);

	if(iVotes < iVotesRequired)
	{
		PrintToChatAll("[SM] %t.", "votes required", iVotes, iVotesRequired);
		return;
	}

	PrintToChatAll("[SM] %t.", "muted by vote", strTargetName);
	LogAction(-1, iTarget, "Vote mute successful, muted \"%L\" (iReason \"voted by players\")", iTarget);
	g_bVoteMuteMuted[iTarget] = true;
	decl String:strClientAuth[33];
	PlayersVotes_GetIdentity(iTarget, strClientAuth, sizeof(strClientAuth));
	PushArrayString(g_hArrayVoteMuteClientIdentity, strClientAuth);
	PlayersVotes_MutePlayer(iTarget);
}

public PlayersVotes_GetRequiredMuteVotes(iVoter)
{
	new iCount;
	for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
	{
		if(IsFakeClient(i))
			continue;

		if(g_bVoteMuteTeam && GetClientTeam(i) != GetClientTeam(iVoter))
			continue;

		iCount++;
	}

	new iRequired = RoundToCeil(float(iCount) * g_flVoteMuteRatio);
	if(iRequired < g_iVoteMuteMinimum)
		iRequired = g_iVoteMuteMinimum;

	return iRequired;
}

public PlayersVotes_GetMuteVotesForTarget(iTarget)
{
	new iVotes;
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(g_bVoteMuteFor[i][iTarget])
			iVotes++;
	}
	return iVotes;
}

public PlayersVotes_MutePlayer(iClient)
{
	#if defined _basecomm_included
		BaseComm_SetClientMute(iClient, true);
	#else
		SetClientListeningFlags(iClient, VOICE_MUTED);
	#endif
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}

stock bool:PlayersVotes_IsValidAuth(const String:strClientAuth[])
{
	return (strcmp(strClientAuth, "STEAM_ID_LAN", false) != 0) && (strcmp(strClientAuth, "STEAM_ID_PENDING", false) != 0);
}

stock PlayersVotes_MatchIdentity(const Handle:hIdentityArray, const String:strIdentity[])
{
	decl String:strStoredIdentity[33];
	for(new i = 0; i < GetArraySize(hIdentityArray); ++i)
	{
		GetArrayString(hIdentityArray, i, strStoredIdentity, sizeof(strStoredIdentity));
		if(strcmp(strIdentity, strStoredIdentity, false) == 0)
			return i;
	}
	return -1;
}

stock bool:PlayersVotes_GetIdentity(iClient, String:strClientIdentity[], iClientIdentitySize)
{
	GetClientAuthString(iClient, strClientIdentity, iClientIdentitySize);
	if(!IsClientAuthorized(iClient) || !PlayersVotes_IsValidAuth(strClientIdentity))
	{
		GetClientIP(iClient, strClientIdentity, iClientIdentitySize);
		return false;
	}
	return true;
}