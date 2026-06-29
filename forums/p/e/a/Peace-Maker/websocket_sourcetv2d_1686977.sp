/**
 * Control chars:
 * A: SourceTV2D spectator amount changed
 * B: Bomb action, see BOMB_ defines
 * C: Player connected
 * D: Player disconnected
 * E: Round ended
 * F:
 * G: 
 * H: Player was hurt
 * I: Initial child socket connect. Sends game and map
 * J:
 * K: Player died
 * L:
 * M: Map changed
 * N: Player changed his name
 * O: Player position update
 * P:
 * Q: 
 * R: Round start
 * S: Player spawned
 * T: Player changed team
 * U:
 * V: ConVar changed
 * W:
 * X: Chat message
 * Y: 
 * Z: SourceTV2D spectator chat
 */
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <websocket>

#define PLUGIN_VERSION "1.0"

#define POSITION_UPDATE_RATE 0.3

#define BOMB_PICKUP 0
#define BOMB_DROPPED 1
#define BOMB_POSITION 2
#define BOMB_PLANTED 3
#define BOMB_DEFUSED 4
#define BOMB_EXPLODED 5
#define BOMB_BEGINPLANT 6
#define BOMB_ABORTPLANT 7
#define BOMB_BEGINDEFUSE 8
#define BOMB_ABORTDEFUSE 9

new WebsocketHandle:g_hListenSocket = INVALID_WEBSOCKET_HANDLE;
new Handle:g_hChilds;
new Handle:g_hChildIP;
new Handle:g_hUpdatePositions = INVALID_HANDLE;

new Handle:g_hostname;

new g_iRoundStartTime = -1;
new bool:g_bBombDropped = false;
new Float:g_vecBombPosition[3];
new g_iBombEntity = -1;
new g_iBombPlantTime = -1;

public Plugin:myinfo = 
{
	name = "SourceTV 2D",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "SourceTV 2D Server",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	g_hChilds = CreateArray();
	g_hChildIP = CreateArray(ByteCountToCells(33));
	
	AddCommandListener(CmdLstnr_Say, "say");
	
	g_hostname = FindConVar("hostname");
	
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_hurt", Event_OnPlayerHurt);
	HookEvent("player_changename", Event_OnChangeName);
	
	// cstrike
	HookEventEx("round_start", Event_OnRoundStart);
	HookEventEx("round_end", Event_OnRoundEnd);
	HookEventEx("bomb_pickup", Event_OnBombPickup);
	HookEventEx("bomb_dropped", Event_OnBombDropped);
	HookEventEx("bomb_planted", Event_OnBombPlanted);
	HookEventEx("bomb_defused", Event_OnBombDefused);
	HookEventEx("bomb_exploded", Event_OnBombExploded);
	HookEventEx("bomb_beginplant", Event_OnBombBeginPlant);
	HookEventEx("bomb_abortplant", Event_OnBombAbortPlant);
	HookEventEx("bomb_begindefuse", Event_OnBombBeginDefuse);
	HookEventEx("bomb_abortdefuse", Event_OnBombAbortDefuse);
}

public OnAllPluginsLoaded()
{
	decl String:sServerIP[40];
	new longip = GetConVarInt(FindConVar("hostip")), pieces[4];
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	FormatEx(sServerIP, sizeof(sServerIP), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	if(g_hListenSocket == INVALID_WEBSOCKET_HANDLE)
		g_hListenSocket = Websocket_Open(sServerIP, 12346, OnWebsocketIncoming, OnWebsocketMasterError, OnWebsocketMasterClose);
}

public OnPluginEnd()
{
	if(g_hListenSocket != INVALID_WEBSOCKET_HANDLE)
		Websocket_Close(g_hListenSocket);
}

public OnMapStart()
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	g_iBombEntity = -1;
	g_bBombDropped = false;
	
	decl String:sBuffer[128];
	GetCurrentMap(sBuffer, sizeof(sBuffer));
	Format(sBuffer, sizeof(sBuffer), "M%s", sBuffer);
	
	SendToAllChildren(sBuffer);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if(IsFakeClient(client))
		return true;
	
	decl String:sIP[33], String:sSocketIP[33];
	GetClientIP(client, sIP, sizeof(sIP));
	new iSize = GetArraySize(g_hChildIP);
	for(new i=0;i<iSize;i++)
	{
		GetArrayString(g_hChildIP, i, sSocketIP, sizeof(sSocketIP));
		if(StrEqual(sIP, sSocketIP))
		{
			Websocket_UnhookChild(WebsocketHandle:GetArrayCell(g_hChilds, i));
			RemoveFromArray(g_hChildIP, i);
			RemoveFromArray(g_hChilds, i);
			if(iSize == 1)
				break;
			i--;
			iSize--;
		}
	}
	
	return true;
}

public OnClientPutInServer(client)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	decl String:sBuffer[128];
	GetClientIP(client, sBuffer, sizeof(sBuffer));
	Format(sBuffer, sizeof(sBuffer), "C%d:%s:%d:0:x:x:100:0:0:%N", GetClientUserId(client), sBuffer, GetClientTeam(client), client);
	
	SendToAllChildren(sBuffer);
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		new iSize = GetArraySize(g_hChilds);
		if(iSize == 0)
			return;
		
		decl String:sBuffer[20];
		Format(sBuffer, sizeof(sBuffer), "D%d", GetClientUserId(client));
		
		SendToAllChildren(sBuffer);
	}
}

public Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	new team = GetEventInt(event, "team");
	
	if(team == 0)
		return;
	
	decl String:sBuffer[10];
	Format(sBuffer, sizeof(sBuffer), "T%d:%d", userid, team);
	
	SendToAllChildren(sBuffer);
}

public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new victim = GetEventInt(event, "userid");
	new attacker = GetEventInt(event, "attacker");
	
	new String:sBuffer[64];
	GetEventString(event, "weapon", sBuffer, sizeof(sBuffer));
	Format(sBuffer, sizeof(sBuffer), "K%d:%d:%s", victim, attacker, sBuffer);
	
	SendToAllChildren(sBuffer);
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "S%d", userid);
	
	SendToAllChildren(sBuffer);
}

public Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "H%d:%d", userid, GetEventInt(event, "dmg_health"));
	
	SendToAllChildren(sBuffer);
}

public Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	g_iRoundStartTime = GetTime();
	g_iBombPlantTime = -1;
	
	decl String:sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "R%d", g_iRoundStartTime);
	
	SendToAllChildren(sBuffer);
}

public Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	g_bBombDropped = false;
	g_iBombEntity = -1;
	g_iRoundStartTime = -1;
	
	new winner = GetEventInt(event, "winner");
	
	if(winner < 2)
		return;
	
	decl String:sBuffer[10];
	Format(sBuffer, sizeof(sBuffer), "E%d", winner);
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	new client = GetClientOfUserId(userid);
	if(client)
	{
		g_iBombEntity = GetPlayerWeaponSlot(client, 4);
		if(g_iBombEntity != -1 && !IsValidEntity(g_iBombEntity))
			g_iBombEntity = -1;
	}
	
	g_bBombDropped = false;
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "B%d:%d", BOMB_PICKUP, userid);
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombDropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	if(g_iBombEntity != -1 && IsValidEntity(g_iBombEntity))
	{
		SetEntPropVector(g_iBombEntity, Prop_Send, "m_vecOrigin", g_vecBombPosition);
		decl String:sBuffer[30];
		Format(sBuffer, sizeof(sBuffer), "B%d:%d:%d", BOMB_POSITION, RoundToNearest(g_vecBombPosition[0]), RoundToNearest(g_vecBombPosition[1]));
		SendToAllChildren(sBuffer);
	}
	else
		g_iBombEntity = -1;
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "B%d:%d", BOMB_DROPPED, userid);
	
	g_bBombDropped = true;
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	new posx = GetEventInt(event, "posx");
	new posy = GetEventInt(event, "posy");
	
	decl String:sBuffer[64];
	Format(sBuffer, sizeof(sBuffer), "B%d:%d:%d:%d:%d", BOMB_PLANTED, posx, posy, GetTime(), userid);
	
	g_vecBombPosition[0] = float(posx);
	g_vecBombPosition[1] = float(posy);
	
	g_bBombDropped = false;
	g_iBombPlantTime = GetTime();
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "B%d:%d", BOMB_DEFUSED, userid);
	
	g_bBombDropped = false;
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	decl String:sBuffer[10];
	Format(sBuffer, sizeof(sBuffer), "B%d", BOMB_EXPLODED);
	
	g_bBombDropped = false;
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombBeginPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "B%d:%d", BOMB_BEGINPLANT, userid);
	
	g_bBombDropped = false;
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombAbortPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "B%d:%d", BOMB_ABORTPLANT, userid);
	
	g_bBombDropped = false;
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombBeginDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "B%d:%d:%d", BOMB_BEGINDEFUSE, GetEventBool(event, "haskit"), userid);
	
	g_bBombDropped = false;
	
	SendToAllChildren(sBuffer);
}

public Event_OnBombAbortDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	
	decl String:sBuffer[20];
	Format(sBuffer, sizeof(sBuffer), "B%d:%d", BOMB_ABORTDEFUSE, userid);
	
	g_bBombDropped = false;
	
	SendToAllChildren(sBuffer);
}

public Event_OnChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSize = GetArraySize(g_hChilds);
	if(iSize == 0)
		return;
	
	new userid = GetEventInt(event, "userid");
	decl String:sOldName[MAX_NAME_LENGTH];
	decl String:sNewName[MAX_NAME_LENGTH];
	GetEventString(event, "oldname", sOldName, sizeof(sOldName));
	GetEventString(event, "newname", sNewName, sizeof(sNewName));
	
	if(StrEqual(sNewName, sOldName))
		return;
	
	decl String:sBuffer[MAX_NAME_LENGTH+10];
	Format(sBuffer, sizeof(sBuffer), "N%d:%s", userid, sNewName);
	
	SendToAllChildren(sBuffer);
}

public Action:CmdLstnr_Say(client, const String:command[], argc)
{
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	StripQuotes(sBuffer);
	if(strlen(sBuffer) == 0)
		return Plugin_Continue;
	
	// Send console messages either.
	new userid = 0;
	if(client)
		userid = GetClientUserId(client);
	
	Format(sBuffer, sizeof(sBuffer), "X%d:%s", userid, sBuffer);
	
	new iSize = GetArraySize(g_hChilds);
	for(new i=0;i<iSize;i++)
		Websocket_Send(GetArrayCell(g_hChilds, i), SendType_Text, sBuffer);
	
	return Plugin_Continue;
}

public Action:OnWebsocketIncoming(WebsocketHandle:websocket, WebsocketHandle:newWebsocket, const String:remoteIP[], remotePort, String:protocols[256])
{
	// Make sure there's no ghosting!
	decl String:sIP[33];
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientIP(i, sIP, sizeof(sIP));
			if(StrEqual(sIP, remoteIP))
				return Plugin_Stop;
		}
	}
	
	Websocket_HookChild(newWebsocket, OnWebsocketReceive, OnWebsocketDisconnect, OnChildWebsocketError);
	Websocket_HookReadyStateChange(newWebsocket, OnWebsocketReadyStateChanged);
	PushArrayCell(g_hChilds, newWebsocket);
	PushArrayString(g_hChildIP, remoteIP);
	//CreateTimer(1.0, Timer_SocketReady, newWebsocket, TIMER_REPEAT);
	//PrintToServer("readyState: %d", _:Websocket_GetReadyState(newWebsocket));
	return Plugin_Continue;
}

public OnWebsocketReadyStateChanged(WebsocketHandle:websocket, WebsocketReadyState:readystate)
//public Action:Timer_SocketReady(Handle:timer, any:websocket)
{
	new iIndex = FindValueInArray(g_hChilds, websocket);
	if(iIndex == -1)
		return;
	
	if(readystate != State_Open)
		return;
	
	decl String:sMap[64], String:sGameFolder[64], String:sBuffer[256], String:sTeam1[32], String:sTeam2[32], String:sHostName[128];
	GetCurrentMap(sMap, sizeof(sMap));
	GetGameFolderName(sGameFolder, sizeof(sGameFolder));
	GetTeamName(2, sTeam1, sizeof(sTeam1));
	GetTeamName(3, sTeam2, sizeof(sTeam2));
	GetConVarString(g_hostname, sHostName, sizeof(sHostName));
	Format(sBuffer, sizeof(sBuffer), "I%s:%s:%s:%s:%s", sGameFolder, sMap, sTeam1, sTeam2, sHostName);
	
	Websocket_Send(websocket, SendType_Text, sBuffer);
	
	if(StrEqual(sGameFolder, "cstrike"))
	{
		new Handle:hRoundTime = FindConVar("mp_roundtime");
		new Handle:hC4Timer = FindConVar("mp_c4timer");
		Format(sBuffer, sizeof(sBuffer), "V%f:%d", GetConVarFloat(hRoundTime), GetConVarInt(hC4Timer));
		Websocket_Send(websocket, SendType_Text, sBuffer);
	}
	
	if(g_iRoundStartTime != -1)
	{
		Format(sBuffer, sizeof(sBuffer), "R%d", g_iRoundStartTime);
		Websocket_Send(websocket, SendType_Text, sBuffer);
	}
	
	// Inform others there's another spectator!
	Format(sBuffer, sizeof(sBuffer), "A%d", GetArraySize(g_hChilds));
	new iSize = GetArraySize(g_hChilds);
	new WebsocketHandle:hHandle;
	for(new i=0;i<iSize;i++)
	{
		hHandle = WebsocketHandle:GetArrayCell(g_hChilds, i);
		if(Websocket_GetReadyState(hHandle) == State_Open)
			Websocket_Send(hHandle, SendType_Text, sBuffer);
	}
	
	// Add all players to it's list
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			GetClientIP(i, sBuffer, sizeof(sBuffer));
			Format(sBuffer, sizeof(sBuffer), "C%d:%s:%d:%d:%d:%d:%d:%d:%d:%N", GetClientUserId(i), sBuffer, GetClientTeam(i), IsPlayerAlive(i), GetClientFrags(i), GetClientDeaths(i), GetClientHealth(i), (GetPlayerWeaponSlot(i, 4)!=-1), GetEntProp(i, Prop_Send, "m_bHasDefuser"), i);
			
			Websocket_Send(websocket, SendType_Text, sBuffer);
		}
	}
	
	// bomb planted?
	if(g_iBombPlantTime != -1 || g_bBombDropped)
	{
		CreateTimer(1.0, Timer_SendBombStuff, websocket);
	}
	
	if(g_hUpdatePositions == INVALID_HANDLE)
	{
		g_hUpdatePositions = CreateTimer(POSITION_UPDATE_RATE, Timer_UpdatePlayerPositions, _, TIMER_REPEAT);
	}
	return;
}

public Action:Timer_UpdatePlayerPositions(Handle:timer, any:data)
{
	decl String:sBuffer[4096];
	// Update bomb position
	if(g_iBombEntity != -1 && g_bBombDropped)
	{
		new Float:vecBombPosition[3];
		GetEntPropVector(g_iBombEntity, Prop_Send, "m_vecOrigin", vecBombPosition);
		if(g_vecBombPosition[0] != vecBombPosition[0] || g_vecBombPosition[1] != vecBombPosition[1] || g_vecBombPosition[2] != vecBombPosition[2])
		{
			Format(sBuffer, sizeof(sBuffer), "B%d:%d:%d", BOMB_POSITION, RoundToNearest(vecBombPosition[0]), RoundToNearest(vecBombPosition[1]));
			g_vecBombPosition = vecBombPosition;
			SendToAllChildren(sBuffer);
		}
	}
	
	
	// Update player positions
	Format(sBuffer, sizeof(sBuffer), "O");
	new Float:fOrigin[3], Float:fAngle[3];
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(strlen(sBuffer) > 1)
				Format(sBuffer, sizeof(sBuffer), "%s|", sBuffer);
			
			GetClientAbsOrigin(i, fOrigin);
			GetClientEyeAngles(i, fAngle);
			Format(sBuffer, sizeof(sBuffer), "%s%d:%d:%d:%d", sBuffer, GetClientUserId(i), RoundToNearest(fOrigin[0]), RoundToNearest(fOrigin[1]), RoundToNearest(fAngle[1]));
		}
	}
	
	if(strlen(sBuffer) == 1)
		return Plugin_Continue;
	
	SendToAllChildren(sBuffer);
	return Plugin_Continue;
}

public Action:Timer_SendBombStuff(Handle:timer, any:data)
{
	decl String:sBuffer[256];
	// bomb planted?
	if(g_iBombPlantTime != -1)
	{
		Format(sBuffer, sizeof(sBuffer), "B%d:%d:%d:%d:-1", BOMB_PLANTED, RoundToNearest(g_vecBombPosition[0]), RoundToNearest(g_vecBombPosition[1]), g_iBombPlantTime);
		Websocket_Send(data, SendType_Text, sBuffer);
	}
	
	if(g_bBombDropped)
	{
		Format(sBuffer, sizeof(sBuffer), "B%d:%d:%d", BOMB_POSITION, RoundToNearest(g_vecBombPosition[0]), RoundToNearest(g_vecBombPosition[1]));
		Websocket_Send(data, SendType_Text, sBuffer);
	}
}

public OnWebsocketMasterError(WebsocketHandle:websocket, const errorType, const errorNum)
{
	LogError("MASTER SOCKET ERROR: handle: %d type: %d, errno: %d", _:websocket, errorType, errorNum);
	g_hListenSocket = INVALID_WEBSOCKET_HANDLE;
}

public OnWebsocketMasterClose(WebsocketHandle:websocket)
{
	g_hListenSocket = INVALID_WEBSOCKET_HANDLE;
}

public OnChildWebsocketError(WebsocketHandle:websocket, const errorType, const errorNum)
{
	LogError("CHILD SOCKET ERROR: handle: %d, type: %d, errno: %d", _:websocket, errorType, errorNum);
	new iIndex = FindValueInArray(g_hChilds, websocket);
	RemoveFromArray(g_hChilds, iIndex);
	RemoveFromArray(g_hChildIP, iIndex);
	if(GetArraySize(g_hChilds) == 0 && g_hUpdatePositions != INVALID_HANDLE)
	{
		KillTimer(g_hUpdatePositions);
		g_hUpdatePositions = INVALID_HANDLE;
	}
	
	// Inform others there's one spectator less!
	decl String:sBuffer[10];
	Format(sBuffer, sizeof(sBuffer), "A%d", GetArraySize(g_hChilds));
	SendToAllChildren(sBuffer);
}

public OnWebsocketReceive(WebsocketHandle:websocket, WebsocketSendType:iType, const String:receiveData[], const dataSize)
{
	if(iType != SendType_Text)
		return;
	
	decl String:sBuffer[dataSize+4];
	Format(sBuffer, dataSize+4, "Z%s", receiveData);
	
	new iSize = GetArraySize(g_hChilds);
	new WebsocketHandle:hHandle;
	for(new i=0;i<iSize;i++)
	{
		hHandle = WebsocketHandle:GetArrayCell(g_hChilds, i);
		if(hHandle != websocket && Websocket_GetReadyState(hHandle) == State_Open)
			Websocket_Send(hHandle, SendType_Text, sBuffer);
	}
}

public OnWebsocketDisconnect(WebsocketHandle:websocket)
{
	new iIndex = FindValueInArray(g_hChilds, websocket);
	RemoveFromArray(g_hChilds, iIndex);
	RemoveFromArray(g_hChildIP, iIndex);
	if(GetArraySize(g_hChilds) == 0 && g_hUpdatePositions != INVALID_HANDLE)
	{
		KillTimer(g_hUpdatePositions);
		g_hUpdatePositions = INVALID_HANDLE;
	}
	
	// Inform others there's one spectator less!
	decl String:sBuffer[10];
	Format(sBuffer, sizeof(sBuffer), "A%d", GetArraySize(g_hChilds));
	SendToAllChildren(sBuffer);
}

SendToAllChildren(const String:sData[])
{
	new iSize = GetArraySize(g_hChilds);
	new WebsocketHandle:hHandle;
	for(new i=0;i<iSize;i++)
	{
		hHandle = WebsocketHandle:GetArrayCell(g_hChilds, i);
		if(Websocket_GetReadyState(hHandle) == State_Open)
			Websocket_Send(hHandle, SendType_Text, sData);
	}
}

stock UTF8_Encode(const String:sText[], String:sReturn[], const maxlen)
{
	new iStrLenI = strlen(sText);
	new iStrLen = 0;
	for(new i=0;i<iStrLenI;i++)
	{
		iStrLen += GetCharBytes(sText[i]);
	}
	
	decl String:sBuffer[iStrLen+1];
	
	new i = 0;
	for(new w=0;w<iStrLenI;w++)
	{
		if(sText[w] < 0x80)
		{
			sBuffer[i++] = sText[w];
		}
		else if(sText[w] < 0x800)
		{
			sBuffer[i++] = 0xC0 | sText[w] >> 6;
			sBuffer[i++] = 0x80 | sText[w] & 0x3F;
		}
		else if(sText[w] < 0x10000)
		{
			sBuffer[i++] = 0xE0 | sText[w] >> 12;
			sBuffer[i++] = 0x80 | sText[w] >> 6 & 0x3F;
			sBuffer[i++] = 0x80 | sText[w] & 0x3F;
		}
	}
	sBuffer[i] = '\0';
	strcopy(sReturn, maxlen, sBuffer);
}