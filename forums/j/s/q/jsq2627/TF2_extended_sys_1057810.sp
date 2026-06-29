/*  *Team Fortress 2 Extended System
	Included functions
		*Respawn system
		*Win panel for losing team
		*Respawner
	Thanks for:
		WoZeR
		Reflex
		Zuko
		
	Welcome to my website: http://www.tf2cn.com/
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <sdktools>
#include <colors>
#undef REQUIRE_PLUGIN
#include <adminmenu>

/* Switchers */
new Handle:g_hRespEnabled;
new Handle:g_hWinPEnabled;

/* Respawn moudel */
new String:TMTag[128] = "TF2@CN"; //Buff team tag
new Handle:g_hTeamMembers  = INVALID_HANDLE;
new Handle:RespawnTimeBlue = INVALID_HANDLE;
new Handle:RespawnTimeRed = INVALID_HANDLE;
new Handle:RespawnTimeEnabled = INVALID_HANDLE;
new bool:SuddenDeathMode; //Are we in SuddenDeathMode boolean?
new TF2GameRulesEntity; //The entity that controls spawn wave times

/* Win-Panel moudel */
new g_BeginScore[MAXPLAYERS + 1];
new g_EntPlayerManager;
new g_OffsetScore;
new g_OffsetClass;

/* Respawner moudel */
new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:g_Cvar_PluginEnable = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify = INVALID_HANDLE;
new Handle:g_Cvar_ChatNotify_AutoRespawn = INVALID_HANDLE;
new Handle:g_Cvar_Log = INVALID_HANDLE;

new bool:autorespawn_enabled[MAXPLAYERS+1] = false;
new Float:respawn_delay[MAXPLAYERS+1] = -1.0;

new bool:RoundIsActive;

new String:logFile[256];
new PlayerTeam_Rper;

//TF2 Teams
const TeamBlu = 3;
const TeamRed = 2;

#define PLUGIN_VERSION "1.0.0"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "TF2 Extended System",
	author = "PuNDiT",
	description = "Extended system in TF2!",
	version = PLUGIN_VERSION,
	url = "http://www.tf2cn.com"
}

public OnPluginStart()
{
	CreateConVar("sm_tf2_version", PLUGIN_VERSION, "TF2 Extended System version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	/* Respawn moudel */
	g_hRespEnabled = CreateConVar("sm_tf2_respawn_tm_enable", "0", "Enable/disable team members respawn settings.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RespawnTimeEnabled = CreateConVar("sm_tf2_respawn_enable", "0", "Enable or disable the plugin 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RespawnTimeBlue = CreateConVar("sm_tf2_respawn_time_blue", "6.0", "Respawn time for Blue team.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RespawnTimeRed = CreateConVar("sm_tf2_respawn_time_red", "6.0", "Respawn time for Red team.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_tf2_respawn_tm_reload", Command_ReloadTeamMembers, ADMFLAG_RCON, "Reload team members.");
	
	//Hook the ConVar for changes
	HookConVarChange(RespawnTimeBlue, RespawnConVarChanged);
	HookConVarChange(RespawnTimeRed, RespawnConVarChanged);
	HookConVarChange(RespawnTimeEnabled, RespawnConVarChanged);
	
	//Hook events
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy); //Disable spawning during suddendeath. Could be fun if enabled with melee only.
	HookEvent("teamplay_round_win", EventRoundWon, EventHookMode_PostNoCopy); //Disable spawning during beat the crap out of the losing team mode. Fun if on :)
	HookEvent("teamplay_game_over", EventSuddenDeath, EventHookMode_PostNoCopy); //Disable spawning
	HookEvent("teamplay_round_start", EventRoundReset, EventHookMode_PostNoCopy); //Enable fast spawning
	HookEvent("teamplay_win_panel", Event_TeamPlayWinPanel);
	// Arena shows their own win panel for losing team. So no need to hook this events.
	//HookEvent("arena_round_start", Event_TeamPlayRoundStart);
	//HookEvent("arena_win_panel", Event_TeamPlayWinPanel);
	
	/* Win-Panel moudel */
	g_hWinPEnabled = CreateConVar("sm_tf2_winp_enable", "0", "Enable/disable win panel for losing team.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_OffsetScore = FindSendPropOffs("CTFPlayerResource", "m_iTotalScore");
	g_OffsetClass = FindSendPropOffs("CTFPlayerResource", "m_iPlayerClass");
	
	if (g_OffsetScore == -1 || g_OffsetClass == -1)
		SetFailState("Cant find proper offsets");
		
	/* Respawner moudel */
	g_Cvar_PluginEnable = CreateConVar("sm_tf2_rper_enable", "0", "Enable/Disable Respawn Player Plugin", _, true, 0.0, true, 1.0);
	g_Cvar_ChatNotify = CreateConVar("sm_tf2_rper_chat_notify", 	"1", "Respawn Chat Notifications", _, true, 0.0, true, 2.0);
	g_Cvar_ChatNotify_AutoRespawn = CreateConVar("sm_tf2_rper_autorp_chat_notify", "1", "Auto Respawn Chat Notifications",		 	_, true, 0.0, true, 2.0);
	g_Cvar_Log = CreateConVar("sm_tf2_rper_log", "0", "Respawn Actions Logging", _, true, 0.0, true, 2.0);
	
	RegAdminCmd("sm_tf2_rper_rp", 			Command_Rplayer, 			ADMFLAG_KICK, "sm_rp <#userid | name>");
	RegAdminCmd("sm_tf2_rper_autorespawn", 	Command_AutoRplayer,		ADMFLAG_KICK, "sm_autorespawn <#userid | name> <delay>");
	RegAdminCmd("sm_tf2_rper_rme", 			Command_RespawnMe, 			ADMFLAG_KICK, "Respawn yourself");
	
	/* Config and log */
	AutoExecConfig(true, "plugin.TF2_extended_sys");
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/TF2_extended_sys.log");
	
	/* Load translations */
	LoadTranslations("common.phrases");
	LoadTranslations("TF2_extended_sys.phrases");
	
	/*Menu Handler */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	/* Respawn moudel */
	//Find the TF_GameRules Entity
	TF2GameRulesEntity = FindEntityByClassname(-1, "tf_gamerules");
	
	if (TF2GameRulesEntity == -1)
	{
		LogToGame("Could not find TF_GameRules to set respawn wave time");
	}
	
	ReloadTeamMembers();
	
	/* Win-Panel moudel */
	g_EntPlayerManager = FindEntityByClassname(-1, "tf_player_manager");
	
	if (g_EntPlayerManager == -1)
	{
		SetFailState("Cant find tf_player_manager entity");
	}
}


/* Events list */
public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:RespawnTime = 0.0;
	
	if ((autorespawn_enabled[client] == true) && (!SuddenDeathMode) && (RoundIsActive == true))
	{
		RespawnTime = respawn_delay[client];
		if (respawn_delay[client] == -1)
		{
			return Plugin_Handled;
		}
		else
		{
			CreateTimer(RespawnTime, SpawnPlayerTimer_Rper, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		if (GetConVarBool(RespawnTimeEnabled) && !SuddenDeathMode) //If we are enabled and SuddenDeathMode is not running then spawn players
		{
			if (GetConVarBool(g_hRespEnabled)) 
			{
				new String:sName[256], Float:TMRespawnTime, String:TMLevel[256];
				GetClientName(client, sName, sizeof(sName));
				if (KvJumpToKey(g_hTeamMembers, sName))
				{
					KvGetString(g_hTeamMembers, "level", TMLevel, sizeof(TMLevel));
					TMRespawnTime = KvGetFloat(g_hTeamMembers, "time");
					
					PrintHintText(client, "%T", "respfortm", client, TMTag, TMLevel, TMRespawnTime);
					CreateTimer(TMRespawnTime, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE);
					KvGoBack(g_hTeamMembers);
					return Plugin_Continue;
				}
			}
			new PlayerTeam = GetClientTeam(client);
			if (PlayerTeam == TeamBlu)
			{
				SetRespawnTime(); //Have to do this since valve likes to reset the TF_GameRules during rounds and map changes
				RespawnTime = GetConVarFloat(RespawnTimeBlue);
				PrintHintText(client, "%T", "resp", client, RespawnTime); //inform the player time to wait for respond
				CreateTimer(RespawnTime, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE); //Respawn the player at the specified time
			}
			else if (PlayerTeam == TeamRed)
			{
				SetRespawnTime(); //Have to do this since valve likes to reset the TF_GameRules during rounds and map changes
				RespawnTime = GetConVarFloat(RespawnTimeRed);
				PrintHintText(client, "%T", "resp", client, RespawnTime); //inform the player time to wait for respond
				CreateTimer(RespawnTime, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE); //Respawn the player at the specified time
			}
		}
	}
	return Plugin_Continue;
}

public Event_TeamPlayWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_hWinPEnabled))
	{
		new DefeatedTeam = GetEventInt(event, "winning_team");
		if (DefeatedTeam == 2 || DefeatedTeam == 3)
		{
			DefeatedTeam = (DefeatedTeam == 2) ? 3 : 2;
			CreateTimer(0.1, Timer_ShowWinPanel, DefeatedTeam);
		}
	}
}

public Action:EventSuddenDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Don't respawn players during sudden death mode
	SuddenDeathMode = true;
	return Plugin_Continue;
}

public Action:EventRoundReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_hWinPEnabled))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			g_BeginScore[i] = GetClientScore(i);
		}
	}
	
	//Time to respawn players again, wahoo!
	SuddenDeathMode = false;
	
	RoundIsActive = true;
	
	return Plugin_Continue;
}

public EventRoundWon(Handle:event, const String:name[], bool:dontBroadcast)
{
	SuddenDeathMode = true;
	RoundIsActive = false;
}

/* Functions */
public Action:SpawnPlayerTimer(Handle:timer, any:client)
{
	//Respawn the player if he is in game and is dead.
	if(!SuddenDeathMode && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		new PlayerTeam = GetClientTeam(client);
		if( (PlayerTeam == TeamRed) || (PlayerTeam == TeamBlu) )
		{
			TF2_RespawnPlayer(client);
		}
	}
	return Plugin_Continue;
} 

//One of the Respawn ConVar's changed so update the respawn wave time
public RespawnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetRespawnTime();
}

public SetRespawnTime()
{
	if (TF2GameRulesEntity != -1)
	{
		new Float:RespawnTimeRedValue = GetConVarFloat(RespawnTimeRed);
		if (RespawnTimeRedValue >= 6.0) //Added this check for servers setting spawn time to 6 seconds. The -6.0 below would cause instant spawn.
		{
			SetVariantFloat(RespawnTimeRedValue - 6.0); //I subtract 6 to help with getting an exact spawn time since valve adds on time to the spawn wave
		}
		else
		{
			SetVariantFloat(RespawnTimeRedValue);
		}
		AcceptEntityInput(TF2GameRulesEntity, "SetRedTeamRespawnWaveTime", -1, -1, 0);
		
		new Float:RespawnTimeBlueValue = GetConVarFloat(RespawnTimeBlue);
		if (RespawnTimeBlueValue >= 6.0)
		{
			SetVariantFloat(RespawnTimeBlueValue - 6.0); //I subtract 6 to help with getting an exact spawn time since valve adds on time to the spawn wave
		}
		else
		{
			SetVariantFloat(RespawnTimeBlueValue);
		}
		AcceptEntityInput(TF2GameRulesEntity, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
	}
}

public ReloadTeamMembers()
{
	if (g_hTeamMembers != INVALID_HANDLE) {
		CloseHandle(g_hTeamMembers);
	}
	g_hTeamMembers = CreateKeyValues("TeamMembers");
	
	decl String:sPath[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/teammembers.txt");
	
	if (FileExists(sPath)) {
		FileToKeyValues(g_hTeamMembers, sPath);
	} else {
		SetFailState("File Not Found: %s", sPath);
	}
	
	KvGetString(g_hTeamMembers, "TeamTag", TMTag, sizeof(TMTag));
}

public Action:Command_ReloadTeamMembers(client, args) 
{
	new String:OriTag[128];
	strcopy(OriTag, sizeof(OriTag), TMTag);
	ReloadTeamMembers();
	
	//Print to console
	PrintToServer("The list of team members has been reloaded.");
	PrintToConsole(client, "[SM] %T", "reloadedtmlst", client, OriTag, TMTag);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	g_BeginScore[client] = 0;
	return true;
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
	DrawPanelItem(handle, "", ITEMDRAW_SPACER);
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

public OnClientPostAdminCheck(client)
{
	autorespawn_enabled[client] = false;
	respawn_delay[client] = -1.0;
}

public Action:Command_RespawnMe(client, args)
{
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %T", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
	
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		PlayerTeam_Rper = GetClientTeam(client);
		if (PlayerTeam_Rper != 1)
		{
			if (!IsPlayerAlive(client))
			{
				TF2_RespawnPlayer(client);
				CPrintToChat(client, "{lightgreen}[SM] %T", "RespawnMe", LANG_SERVER);
				return Plugin_Handled;
			}
			else
			ReplyToCommand(client, "[SM] %T", "YouAreAlive", LANG_SERVER);
		}
		else 
		ReplyToCommand(client, "[SM] %T", "YouAreOnSpectator", LANG_SERVER);
	}
	return Plugin_Handled;
}

public Action:Command_Rplayer(client, args)
{
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %T", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
	
	decl String:target[MAXPLAYERS];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] %T", "PluginUsage_RP", LANG_SERVER);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
	}

	if (target[client] == -1)
	{
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_DEAD,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		PerformRespawnPlayer(client,target_list[i]);
	}	
	return Plugin_Handled;
}

PerformRespawnPlayer(client, target)
{	
	PlayerTeam_Rper = GetClientTeam(target);
	if (PlayerTeam_Rper != 1)
	{
		if (GetConVarInt(g_Cvar_PluginEnable) == 0)
		{
			ReplyToCommand(client, "[SM] %T", "PluginDisabled", LANG_SERVER);
		}
	
		if (IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
		{
			TF2_RespawnPlayer(target);
	
			switch(GetConVarInt(g_Cvar_Log))
			{
				case 0:
					return;
				case 1:
					LogToFile(logFile, "%T", "PluginLog", LANG_SERVER, client, target);
				case 2:
					LogAction(client, target, "%T", "PluginLog", LANG_SERVER, client, target);
			}
			switch(GetConVarInt(g_Cvar_ChatNotify))
			{
				case 0:
					return;
				case 1:
					CPrintToChat(target, "{lightgreen}[SM] %T", "SpawnPhrase1", LANG_SERVER, client);
				case 2:
					CPrintToChatAll("{lightgreen}[SM] %T", "SpawnPhrase2", LANG_SERVER, client, target);
			}
			ReplyToCommand(client, "[SM] %T", "SpawnPhrase3", LANG_SERVER, target);
		}
	}
	else 
	ReplyToCommand(client, "[SM] %T", "YouAreOnSpectator", LANG_SERVER);
}

public Action:Command_AutoRplayer(client, args)
{
	new Float:nDelay;
	new iDelay;
	if (GetConVarInt(g_Cvar_PluginEnable) == 0)
	{
		ReplyToCommand(client, "[SM] %T", "PluginDisabled", LANG_SERVER);
		return Plugin_Stop;
	}
		
	decl String:target[MAXPLAYERS];
	decl String:delay[10];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] %T", "PluginUsage_AutoRespawn", LANG_SERVER);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, delay, sizeof(delay));
		nDelay = StringToFloat(delay);
		iDelay = StringToInt(delay);
	}

	if (nDelay < -1)
	{
		ReplyToCommand(client, "[SM] %T", "RespawnDelay1", LANG_SERVER);
		return Plugin_Handled;
	}
	
	if (nDelay > 30)
	{
		ReplyToCommand(client, "[SM] %T", "RespawnDelay2", LANG_SERVER);
		return Plugin_Handled;
	}
		
	if (target[client] == -1)
	{
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			MAX_TARGET_LENGTH,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (!SuddenDeathMode && IsClientConnected(target_list[i]) && IsClientInGame(target_list[i]))
		{
			PlayerTeam_Rper = GetClientTeam(target_list[i]);
			if (PlayerTeam_Rper != 1)
			{
				autorespawn_enabled[target_list[i]] = true;
				respawn_delay[target_list[i]] = nDelay;
				if (!IsPlayerAlive(target_list[i]))
				{
					TF2_RespawnPlayer(target_list[i]);
				}
				
				if (client == target_list[i])
				{
					if (nDelay == 0.0)
					{
					ReplyToCommand(client, "[SM] %T", "RespawnDelay6", LANG_SERVER);
					}
					else if (nDelay == -1.0)
					{
						ReplyToCommand(client, "[SM] %T", "RespawnDelay3", LANG_SERVER);
					}
					else
					ReplyToCommand(client, "[SM] %T", "RespawnDelay5", LANG_SERVER, iDelay);
				}
				else if (nDelay == 0.0)
				{
					ReplyToCommand(client, "[SM] %T", "RespawnDelay7", LANG_SERVER, target_list[i]);
				}
				else
				ReplyToCommand(client, "[SM] %T", "RespawnDelay4", LANG_SERVER, target_list[i], iDelay);
				
				switch(GetConVarInt(g_Cvar_ChatNotify_AutoRespawn))
				{
					case 0:
						return Plugin_Continue;
					case 1:
					{
						if (client == target_list[i])
						{	
							if (nDelay == -1.0)
							{
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase4", LANG_SERVER);
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase4a", LANG_SERVER);
							}
							else
							{
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase3", LANG_SERVER);
								CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase3a", LANG_SERVER, iDelay);
							}
						}
						else
						{
							CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase1", LANG_SERVER, client);
							CPrintToChat(target_list[i], "{lightgreen}[SM] %T", "AutoSpawnPhrase1a", LANG_SERVER, iDelay);
						}
					}
					case 2:
					{
						if (nDelay == -1.0)
						{
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoSpawnPhrase5", LANG_SERVER, client, target_list[i], iDelay);
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoSpawnPhrase5a", LANG_SERVER);
						}
						else
						{
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoSpawnPhrase2", LANG_SERVER, client, target_list[i]);
							CPrintToChatAll("{lightgreen}[SM] %T", "AutoSpawnPhrase2a", LANG_SERVER, iDelay);
						}
					}
				}
			}
			else
			ReplyToCommand(client, "[SM] %T", "YouAreOnSpectator", LANG_SERVER);
		}
	}	
	return Plugin_Handled;
}

public Action:SpawnPlayerTimer_Rper(Handle:timer, any:client)
{
	if (!SuddenDeathMode && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	autorespawn_enabled[client] = false;
	respawn_delay[client] = -1.0;
}

/* Menu */
public OnAdminMenuReady(Handle:topmenu)
{	
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_tf2_rper_rp",
			TopMenuObject_Item,
			AdminMenu_Particles, 
			player_commands,
			"sm_tf2_rper_rp",
			ADMFLAG_KICK);
	}
}
 
public AdminMenu_Particles( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "RespawnPlayer", LANG_SERVER);
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param);
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players);
	
	decl String:title[100];
	Format(title, sizeof(title),"%T", "ChoosePlayer", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(StringToInt(info));

			if ((target) == 0)
			{
				PrintToChat(param1, "[SM] %T", "Player no longer available", LANG_SERVER);
			}
			else if (!CanUserTarget(param1, target))
			{
				PrintToChat(param1, "[SM] %T", "Unable to target", LANG_SERVER);
			}
			else
			{                     
				PerformRespawnPlayer(param1, target);
				if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
				{
					DisplayPlayerMenu(param1);
				}
			}
		}
	}
}