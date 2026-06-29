#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
	name = "Win panel for losing team",
	author = "Reflex",
	description = "Plugin shows top players from losing team.",
	version = PLUGIN_VERSION
};

new g_BeginScore[MAXPLAYERS + 1];
new g_EntPlayerManager;
new g_OffsetScore;
new g_OffsetClass;

public OnPluginStart()
{
	HookEvent("teamplay_round_start", Event_TeamPlayRoundStart);
	HookEvent("teamplay_win_panel", Event_TeamPlayWinPanel);
	// Arena shows their own win panel for losing team. So no need to hook this events.
	//HookEvent("arena_round_start", Event_TeamPlayRoundStart);
	//HookEvent("arena_win_panel", Event_TeamPlayWinPanel);
	
	g_OffsetScore = FindSendPropOffs("CTFPlayerResource", "m_iTotalScore");
	g_OffsetClass = FindSendPropOffs("CTFPlayerResource", "m_iPlayerClass");
	
	if (g_OffsetScore == -1 || g_OffsetClass == -1)
		SetFailState("Cant find proper offsets");
		
	LoadTranslations("win-panel.phrases");
	
	CreateConVar("sm_win_panel_version", PLUGIN_VERSION, "Plugin Version",
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED |
		FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public OnMapStart()
{
	g_EntPlayerManager = FindEntityByClassname(-1, "tf_player_manager");
	
	if (g_EntPlayerManager == -1)
		SetFailState("Cant find tf_player_manager entity");
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	g_BeginScore[client] = 0;
	return true;
}

public Event_TeamPlayRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
		g_BeginScore[i] = GetClientScore(i);
}

public Event_TeamPlayWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	new DefeatedTeam = GetEventInt(event, "winning_team");
	if (DefeatedTeam == 2 || DefeatedTeam == 3)
	{
		DefeatedTeam = (DefeatedTeam == 2) ? 3 : 2;
		CreateTimer(0.1, Timer_ShowWinPanel, DefeatedTeam);
	}
}

public Action:Timer_ShowWinPanel(Handle:timer, any:DefeatedTeam)
{
	new Scores[MaxClients][2];
	new RowCount;
	new client;
	
	// For sorting purpose, start fill Scores[][] array from zero index
	//
	for (new i = 0; i < MaxClients; i++)
	{
		client = i + 1;
		Scores[i][0] = client;
		if (IsClientInGame(client) && GetClientTeam(client) == DefeatedTeam)
			Scores[i][1] = GetClientScore(client) - g_BeginScore[client];
		else
			Scores[i][1] = -1;
	}
	
	SortCustom2D(Scores, MaxClients, SortScoreDesc);
	
	// Create and show Win Panel
	//
	for (new j = 1; j <= MaxClients; j++)
	{
		if (IsClientInGame(j))
		{
			new Handle:hPanel = CreatePanel();
			
			Draw_PanelHeader(hPanel, DefeatedTeam, j);
			
			// Draw three top players
			//
			RowCount = 0;
			for (new n = 0; n <= 2; n++)
			{
				if (Scores[n][1] > 0)
				{
					Draw_PanelPlayer(hPanel, Scores[n][1], Scores[n][0], j);
					RowCount++;
				}
			}
			
			// Don't show anything if there are not top players
			//
			if (RowCount > 0)
				SendPanelToClient(hPanel, j, Handler_DoNothing, 12);
			
			CloseHandle(hPanel);
		}
	}
}

Draw_PanelHeader(Handle:handle, team, client)
{
	decl String:_teamX[6];
	decl String:_panelTitle[128];
	decl String:_panelFirstRow[128];
	
	Format(_teamX, sizeof(_teamX), "team%d", team);
	Format(_panelTitle, sizeof(_panelTitle), "%T", _teamX, client);
	Format(_panelFirstRow, sizeof(_panelFirstRow), "%T", "header", client);
	
	SetPanelTitle(handle, _panelTitle);
	DrawPanelText(handle, " ");
	//DrawPanelItem(handle, "", ITEMDRAW_SPACER);
	DrawPanelText(handle, _panelFirstRow);
}

Draw_PanelPlayer(Handle:handle, score, client, translate)
{
	decl String:_panelTopPlayerRow[256];
	decl String:_playerName[MAX_NAME_LENGTH];
	decl String:_playerScore[13];
	decl String:_playerClass[128];
	decl String:_classX[7];
	
	// Format player name
	GetClientName(client, _playerName, sizeof(_playerName));
	
	// Format player score
	//
	if (score < 10)
		Format(_playerScore, sizeof(_playerScore), "      %d     ", score);
	else if (score < 100)
		Format(_playerScore, sizeof(_playerScore), "    %d     ", score);
	else
		Format(_playerScore, sizeof(_playerScore), "  %d     ", score);
		
	// Format player class
	//
	Format(_classX, sizeof(_classX), "class%d", GetClientClass(client));
	Format(_playerClass, sizeof(_playerClass), "%T", _classX, translate);
	
	// Format player row
	Format(_panelTopPlayerRow, sizeof(_panelTopPlayerRow), "%s%s%s", _playerScore, _playerClass, _playerName);
	
	DrawPanelText(handle, _panelTopPlayerRow);
	DrawPanelText(handle, " ");
	DrawPanelItem(handle, "Close.");
}

// Thanks to Goerge for code snippet
//
public SortScoreDesc(x[], y[], array[][], Handle:data)
{
	if (x[1] > y[1])
		return -1;
	else if (x[1] < y[1])
		return 1;
	return 0;
}

GetClientScore(client)
{
	if (IsClientConnected(client))
		return GetEntData(g_EntPlayerManager, g_OffsetScore + (client * 4), 4);
	return -1;
}

GetClientClass(client)
{
	if (IsClientConnected(client))
		return GetEntData(g_EntPlayerManager, g_OffsetClass + (client * 4), 4);
	return 0; 
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	// Do nothing
}