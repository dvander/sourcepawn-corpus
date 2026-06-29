//SourcePawn

#pragma semicolon 1
#pragma dynamic 131072

#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VER "3.29.71"
#define MAXCLIENTS 32

#define FLOOD_DELAY 4.0
#define ARRAY_SIZE 128
#define TOP_SIZE 100
#define DIR_FILEPATH "gamedata/lb_das.txt"

new bool:g_bIsPlayerStarted[MAXCLIENTS + 1];
new Float:g_fTime[MAXCLIENTS + 1];
new bool:g_bIsFair[MAXCLIENTS + 1];
new Float:g_fAntiFloodTime[MAXCLIENTS + 1];
new Handle:g_hDataPack[MAXCLIENTS + 1] = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Dead Air Surf Tools",
	author = "noa1mbot",
	description = "SourceMod tools for Dead Air Surf.",
	version = PLUGIN_VER,
	url = "http://steamcommunity.com/sharedfiles/filedetails/?id=526792721"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_tp", Cmd_DAS_Teleport);
	RegConsoleCmd("sm_mode", Cmd_DAS_Mode);
	RegConsoleCmd("sm_js", Cmd_JoinSurvivor);
	RegConsoleCmd("sm_take", Cmd_JoinBot);
	RegConsoleCmd("sm_help", Cmd_Help);
	RegConsoleCmd("sm_top", Cmd_Leaderboard);

	HookEvent("bot_player_replace", OnGameEvent);
	HookEvent("player_first_spawn", OnGameEvent);
	HookEvent("player_disconnect", OnGameEvent);
	HookEntityOutput("trigger_multiple", "OnStartTouch", OnEntityOutput);
	
	CreateTimer(5.0, TimerNotifications, 0, TIMER_REPEAT);
	CreateTimer(60.0, TimerNotifications, 1, TIMER_REPEAT);
	CreateTimer(600.0, TimerNotifications, 2, TIMER_REPEAT);
}

public Action:TimerNotifications(Handle:timer, any:data)
{
	if (data == 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && IsPlayerStuck(i))
			{
				decl String:sParams[32];
				Format(sParams, sizeof(sParams), "DAS_Teleport(%d)", i);
				SetVariantString(sParams);
				AcceptEntityInput(i, "RunScriptCode");
			}
		}
	}
	else if (data == 1)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) != 2)
			{
				CPrintToChat(i, "[SM] Type {blue}!js{default} to join survivors team or {blue}!take{default} to take a bot.");
			}	
		}
	}
	else if (data == 2)
	{
		CPrintToChatAll("[SM] Type {green}!help{default} to show more info in console.");
	}
	return Plugin_Continue;
}

//========================================================================================================================
//Hooks
//========================================================================================================================

public OnMapStart()
{
	new entity;
	decl String:sEntName[64];
	while ((entity = FindEntityByClassname(entity, "logic_script")) > 0)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", sEntName, sizeof(sEntName));
		if (StrEqual(sEntName, "ent_das_vscripts"))
		{
			SetVariantString("g_bIsSourceMod = true");
			AcceptEntityInput(entity, "RunScriptCode");
			PrintToServer("[DAS] Initialization 'g_bIsSourceMod' variable from VScripts.");
			return;
		}
	}
}

public OnGameEvent(Handle:event, const String:name[], bool:none)
{
	if (StrEqual(name, "bot_player_replace"))
	{
		new client = GetClientOfUserId(GetEventInt(event, "player"));
		if (g_bIsPlayerStarted[client] && g_bIsFair[client])
		{
			g_bIsFair[client] = false;
		}
	}
	else if (StrEqual(name, "player_first_spawn"))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!IsFakeClient(client))
		{
			PrintToChat(client, "Dead Air Surf v%s\n[SM] Open the console to read the description.", PLUGIN_VER);
			PrintToConsole(client, "\nThis map is made out of props and included into c11m5. For fun races. Dead Air Surf requires the bunnyhop scripts.");
			PrintToConsole(client, "Add the binds below to your console for convenience.\n");
			PrintToConsole(client, "Commands:\n!tp — Teleport to start.\n!s — Join spectators team.\n!js — Join survivors team.\n!mode — Start race.\n!take — Take a bot from picker.\n!top — Show the Leaderboard.");
			PrintToConsole(client, "\nVisit the website for more info about SourceMod plugin: https://forums.alliedmods.net/showthread.php?t=272400");
			PrintToConsole(client, "Workshop: http://steamcommunity.com/sharedfiles/filedetails/?id=526792721");
			PrintToConsole(client, "Dead Air Surf v%s\n", PLUGIN_VER);
		}
	}
	else if (StrEqual(name, "player_disconnect"))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		g_bIsPlayerStarted[client] = false;
	}
}

public OnEntityOutput(const String:output[], entity, client, Float:delay)
{
	if (client <= 0 || client > MAXCLIENTS)
	{
		return;
	}
	decl String:sEntName[64];
	GetEntPropString(entity, Prop_Data, "m_iName", sEntName, sizeof(sEntName));
	if (StrEqual(sEntName, "trigger_start") && !IsFakeClient(client))
	{
		g_bIsPlayerStarted[client] = true;
		g_fTime[client] = GetGameTime();
		g_bIsFair[client] = true;
		PrintHintText(client, "Hold space to jump.");
		CPrintToChat(client, "[SM] Type in chat {olive}!tp{default} to teleport to start.");
		CPrintToChat(client, "[SM] Type in chat {blue}!top{default} to show Leaderboard in console.");
	}
	else if (StrContains(sEntName, "trigger_cp") != -1)
	{
		if (g_bIsPlayerStarted[client])
		{
			new Float:fTime = GetGameTime() - g_fTime[client];
			PrintToConsole(client, "Time: %.03f", fTime);
			PrintHintText(client, "%.03f", fTime);
			ClientCommand(client, "playgamesound buttons/blip1.wav");
		}
	}
	else if (StrEqual(sEntName, "trigger_finish"))
	{
		if (g_bIsPlayerStarted[client])
		{
			g_bIsPlayerStarted[client] = false;
			new Float:fTime = GetGameTime() - g_fTime[client];
			if (g_bIsFair[client])
			{
				Func_SaveToFile(client, fTime);
			}
			else
			{
				CPrintToChat(client, "[SM] You are suspected in {red}cheating{default}, therefore results were not saved.");
			}
		}
	}
}

//========================================================================================================================
//Funcs
//========================================================================================================================

public Func_SaveToFile(client, Float:fTime)
{
	decl String:sSteamID[64], String:sFilePath[64], String:sPlayerResult[ARRAY_SIZE], String:sDate[16];
	GetClientAuthId(client, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), DIR_FILEPATH);
	FormatTime(sDate, sizeof(sDate), "%d/%m/%Y", GetTime());
	Format(sPlayerResult, ARRAY_SIZE, "%.03fs %N http://steamcommunity.com/profiles/%s - %s\n", fTime, client, sSteamID, sDate);
	new Handle:hFile = INVALID_HANDLE;
	if (FileExists(sFilePath))
	{
		hFile = OpenFile(sFilePath, "r");
		decl String:sFileData[FileSize(sFilePath)];
		ReadFileString(hFile, sFileData, FileSize(sFilePath));
		CloseHandle(hFile);
		if (StrContains(sFileData, sSteamID) != -1)
		{
			new Handle:hData = Func_CheckLines(sFilePath, sSteamID);
			decl String:sPlayerAccept[ARRAY_SIZE];
			ResetPack(hData, false);
			ReadPackString(hData, sPlayerAccept, ARRAY_SIZE);
			CloseHandle(hData);
			if (StringToFloat(sPlayerAccept) > fTime)
			{
				ReplaceString(sFileData, ARRAY_SIZE, sPlayerAccept, sPlayerResult);
				hFile = OpenFile(sFilePath, "w+");
				WriteFileString(hFile, sFileData, false);
				CloseHandle(hFile);
			}
			return;
		}
		hFile = OpenFile(sFilePath, "a+");
	}
	else
	{
		hFile = OpenFile(sFilePath, "w+");
		PrintToServer("Config file Leaderboard has been created and put to \"%s\" directory.", sFilePath);
	}
	WriteFileString(hFile, sPlayerResult, false);
	CloseHandle(hFile);
}

public Handle:Func_CheckLines(const String:sFilePath[], const String:sSteamID[])
{
	new iLines;
	new Handle:hFile = OpenFile(sFilePath, "r");
	new Handle:hData = CreateDataPack();
	decl String:sLine[ARRAY_SIZE];
	while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sLine, ARRAY_SIZE))
	{
		if (StrContains(sLine, sSteamID) != -1)
		{
			WritePackString(hData, sLine);
		}
		iLines++;
	}
	WritePackCell(hData, iLines);
	CloseHandle(hFile);
	return hData;
}

public Func_Leaderboard(client)
{
	decl String:sFilePath[64];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), DIR_FILEPATH);
	if (FileExists(sFilePath))
	{
		new Handle:hData = Func_CheckLines(sFilePath, "N/A");
		ResetPack(hData, false);
		new iLines = ReadPackCell(hData);
		CloseHandle(hData);
		if (iLines > 0)
		{
			decl Float:fTime[iLines];
			decl String:sTime[iLines][ARRAY_SIZE];
			iLines = 0;
			new Handle:hFile = OpenFile(sFilePath, "r");
			decl String:sLine[ARRAY_SIZE];
			while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sLine, ARRAY_SIZE))
			{
				fTime[iLines] = StringToFloat(sLine);
				Format(sTime[iLines], ARRAY_SIZE, "%s", sLine);
				iLines++;
			}
			CloseHandle(hFile);
			
			new Handle:hTable = CreatePanel();
			SetPanelTitle(hTable, "LEADERBOARD\n \n");
			PrintToConsole(client, "\n================ Leaderboard ================");
			decl String:sValue[ARRAY_SIZE];
			new String:sToConsole[1024];
			new Float:fMax;
			new Float:fValue;
			for (new i = 0; i < iLines; i++)
			{
				if (fTime[i] > fValue)
				{
					fValue = fTime[i];
				}
			}
			fMax = fValue;
			new Float:fMin;
			new bool:bUsed[iLines];
			new n;
			new iPrintStep = 9;
			new Float:fCurrentTimer;
			for (new i = 0; i < iLines; i++)
			{
				fValue = fMax;
				for (new d = 0; d < iLines; d++)
				{
					if (fTime[d] <= fValue && fTime[d] >= fMin && !bUsed[d])
					{
						fValue = fTime[d];
						Format(sValue, ARRAY_SIZE, "%s", sTime[d]);
						n = d;
					}
				}
				bUsed[n] = true;
				fMin = fValue;
				if (i < TOP_SIZE)
				{
					Format(sValue, ARRAY_SIZE, "%d place: %s", (i + 1), sValue);
					SplitString(sValue, "\n", sValue, ARRAY_SIZE);
					Format(sToConsole, sizeof(sToConsole), "%s\n%s", sToConsole, sValue);
					if (i < 10)
					{
						SplitString(sValue, "http://steamcommunity.com/profiles/", sValue, ARRAY_SIZE);
						DrawPanelText(hTable, sValue);
					}
					if (i == iPrintStep)
					{
						g_hDataPack[client] = CreateDataPack();
						WritePackString(g_hDataPack[client], sToConsole);
						WritePackCell(g_hDataPack[client], client);
						CreateTimer(fCurrentTimer, TimerToConsole, g_hDataPack[client]);
						Format(sToConsole, sizeof(sToConsole), "");
						iPrintStep += 10;
						fCurrentTimer += 0.1;
					}
				}
				else
				{
					break;
				}
			}
			if (strlen(sToConsole) != 0)
			{
				g_hDataPack[client] = CreateDataPack();
				WritePackString(g_hDataPack[client], sToConsole);
				WritePackCell(g_hDataPack[client], client);
				CreateTimer(fCurrentTimer, TimerToConsole, g_hDataPack[client]);
			}
			Format(sValue, ARRAY_SIZE, "\n \nTOP%d in console.", TOP_SIZE);
			DrawPanelText(hTable, sValue);
			SendPanelToClient(hTable, client, MenuHandler, 60);
			CloseHandle(hTable);
		}
		else
		{
			PrintToChat(client, "[SM] No data in file.");
		}
	}
	else
	{
		PrintToChat(client, "[SM] File \"%s\" is not exists.", sFilePath);
	}
}

public Action:TimerToConsole(Handle:timer, any:hData)
{
	if (hData != INVALID_HANDLE)
	{
		ResetPack(hData, false);
		decl String:sToConsole[1024];
		ReadPackString(hData, sToConsole, sizeof(sToConsole));
		new client = ReadPackCell(hData);
		if (client > 0 && IsClientInGame(client))
		{
			PrintToConsole(client, "%s", sToConsole);
		}
		CloseHandle(hData);
	}
}

public MenuHandler(Handle:menu, MenuAction:action, int param1, int param2)
{
}

public bool:IsPlayerStuck(client)
{
	decl Float:vecMins[3];
	decl Float:vecMaxs[3];
	decl Float:vecOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", vecMaxs);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecOrigin);
	new Handle:hTrace = TR_TraceHullFilterEx(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceEntityFilterSolid);
	new bool:bValue = TR_DidHit(hTrace);
	CloseHandle(hTrace);
	return bValue;
}

public bool:TraceEntityFilterSolid(entity, contentsMask)
{
	if (entity > 0 && entity <= MaxClients)
	{
		return false;
	}
	if (entity >= 0 && IsValidEdict(entity) && IsValidEntity(entity))
	{
		new iValue = GetEntProp(entity, Prop_Send, "m_CollisionGroup");
		if (iValue == 1 || iValue == 11 || iValue == 5)
		{
			return false;
		}
	}
	return true;
}

//========================================================================================================================
//Cmds
//========================================================================================================================

public Action:Cmd_DAS_Teleport(client, args)
{
	if (client > 0)
	{
		decl String:sParams[32];
		Format(sParams, sizeof(sParams), "DAS_Teleport(%d)", client);
		SetVariantString(sParams);
		AcceptEntityInput(client, "RunScriptCode");
	}
	return Plugin_Handled;
}

public Action:Cmd_DAS_Mode(client, args)
{
	if (client > 0)
	{
		decl String:sParams[32];
		Format(sParams, sizeof(sParams), "DAS_Mode(%d)", client);
		SetVariantString(sParams);
		AcceptEntityInput(client, "RunScriptCode");
	}
	return Plugin_Handled;
}

public Action:Cmd_Help(client, args)
{
	if (client > 0)
	{
		PrintToChat(client, "Dead Air Surf v%s\n[SM] Open the console to read the description.", PLUGIN_VER);
		PrintToConsole(client, "\nThis map is made out of props and included into c11m5. For fun races. Dead Air Surf requires the bunnyhop scripts.");
		PrintToConsole(client, "Add the binds below to your console for convenience.\n");
		PrintToConsole(client, "Commands:\n!tp — Teleport to start.\n!s — Join spectators team.\n!js — Join survivors team.\n!mode — Start race.\n!take — Take a bot from picker.\n!top — Show the Leaderboard.");
		PrintToConsole(client, "\nVisit the website for more info about SourceMod plugin: https://forums.alliedmods.net/showthread.php?t=272400");
		PrintToConsole(client, "Workshop: http://steamcommunity.com/sharedfiles/filedetails/?id=526792721");
		PrintToConsole(client, "Dead Air Surf v%s\n", PLUGIN_VER);
	}
	return Plugin_Handled;
}

public Action:Cmd_JoinSurvivor(client, args)
{
	if (client > 0 && GetClientTeam(client) != 2)
	{
		if ((GetGameTime() - g_fAntiFloodTime[client]) > FLOOD_DELAY)
		{
			g_fAntiFloodTime[client] = GetGameTime();
			new target;
			decl String:sNetClass[64];
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetEntityNetClass(i, sNetClass, sizeof(sNetClass));
					if (StrEqual(sNetClass, "SurvivorBot"))
					{
						target = i;
						break;
					}
				}
			}
			if (target > 0)
			{
				decl Float:fPlayerPos[3];
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", fPlayerPos);
				TeleportEntity(client, fPlayerPos, NULL_VECTOR, NULL_VECTOR);
				SetCommandFlags("sb_takecontrol", GetCommandFlags("sb_takecontrol") & ~FCVAR_CHEAT);
				FakeClientCommand(client, "sb_takecontrol");
				SetCommandFlags("sb_takecontrol", GetCommandFlags("sb_takecontrol") | FCVAR_CHEAT);
			}
		}
		else
		{
			PrintToChat(client, "[SM] Cannot use this command now.");
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_JoinBot(client, args)
{
	if (client > 0)
	{
		if ((GetGameTime() - g_fAntiFloodTime[client]) > FLOOD_DELAY)
		{
			g_fAntiFloodTime[client] = GetGameTime();
			SetCommandFlags("sb_takecontrol", GetCommandFlags("sb_takecontrol") & ~FCVAR_CHEAT);
			FakeClientCommand(client, "sb_takecontrol");
			SetCommandFlags("sb_takecontrol", GetCommandFlags("sb_takecontrol") | FCVAR_CHEAT);
		}
		else
		{
			PrintToChat(client, "[SM] Cannot use this command now.");
		}
	}
	return Plugin_Handled;
}

public Action:Cmd_Leaderboard(client, args)
{
	if (client > 0)
	{
		if ((GetGameTime() - g_fAntiFloodTime[client]) > FLOOD_DELAY)
		{
			g_fAntiFloodTime[client] = GetGameTime();
			Func_Leaderboard(client);
		}
		else
		{
			PrintToChat(client, "[SM] Cannot use this command now.");
		}
	}
	return Plugin_Handled;
}