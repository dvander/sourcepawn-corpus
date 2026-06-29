#include <sourcemod>

public Plugin:myinfo =
{
	name = "L4D and L4D2 game mode changer",
	author = "Sharft 6",
	description = "allows players to change the game mode based on votes",
	version = "12",
	url = "http://forums.alliedmods.net/showthread.php?t=109439"
}

new String:g_game[16];
new String:g_cGameMode[32];
new String:g_gameMode[32];
new String:g_campagin[32];
new Handle:g_gameModeMenu = INVALID_HANDLE;
new Handle:g_campaginMenu = INVALID_HANDLE;
new Handle:g_mapMenu = INVALID_HANDLE;
new Handle:g_advertisePlugin = INVALID_HANDLE;
new Handle:g_modeVoteTime = INVALID_HANDLE;
new Handle:g_mapVoteTime = INVALID_HANDLE;
new Handle:g_coopEnabled = INVALID_HANDLE;
new	Handle:g_versusEnabled = INVALID_HANDLE;
new	Handle:g_survivalEnabled = INVALID_HANDLE;
new	Handle:g_teamScavengeEnabled = INVALID_HANDLE;
new	Handle:g_teamVersusEnabled = INVALID_HANDLE;
new	Handle:g_realismEnabled = INVALID_HANDLE;
new	Handle:g_mutationEnabled = INVALID_HANDLE;
 
public OnPluginStart()
{
	GetGameFolderName(g_game, sizeof(g_game));
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegAdminCmd("sm_cancelvote", Command_CancelVote, ADMFLAG_VOTE);
	
	RegAdminCmd("sm_changegamemode", Command_GameMode, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_coop", Command_Coop, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_versus", Command_Versus, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_survival", Command_Survival, ADMFLAG_CHANGEMAP);
	if(strcmp(g_game, "left4dead2", false) == 0)
	{
		RegAdminCmd("sm_teamscavenge", Command_TeamScavenge, ADMFLAG_CHANGEMAP);
		RegAdminCmd("sm_teamversus", Command_TeamVersus, ADMFLAG_CHANGEMAP);
		RegAdminCmd("sm_realism", Command_Realism, ADMFLAG_CHANGEMAP);
		RegAdminCmd("sm_mutation", Command_Mutation, ADMFLAG_CHANGEMAP);
	}
	
	g_advertisePlugin = CreateConVar("sm_advertisegamemodechanger", "0", "指定插件是否向玩家宣传自己");
	
	g_modeVoteTime = CreateConVar("sm_modevotetime", "20", "默认时间在几秒钟内投票");
	g_mapVoteTime = CreateConVar("sm_mapvotetime", "20", "默认时间在几秒钟内投票");
	
	g_coopEnabled = CreateConVar("sm_coopenabled", "1", "1启用coop-指定该游戏模式是否在投票菜单中可用");
	g_versusEnabled = CreateConVar("sm_versusenabled", "1", "1启用versus-指定该游戏模式是否在投票菜单中可用");
	g_survivalEnabled = CreateConVar("sm_survivalenabled", "1", "1启用survival -指定该游戏模式是否在投票菜单中可用");
	g_teamScavengeEnabled = CreateConVar("sm_teamscavengeenabled", "1", "1启用teamscavenge -指定该游戏模式是否在投票菜单中可用");
	g_teamVersusEnabled = CreateConVar("sm_teamversusenabled", "1", "1启用teamversus -指定该游戏模式是否在投票菜单中可用");
	g_realismEnabled = CreateConVar("sm_realismenabled", "1", "1启用realism -指定该游戏模式是否在投票菜单中可用");
	g_mutationEnabled = CreateConVar("sm_mutationenabled", "1", "1启用mutation -指定该游戏模式是否在投票菜单中可用");
	
	AutoExecConfig(true, "plugin_gamemodechanger");
}

public OnMapStart()
{
	new Handle:currentGameMode = FindConVar("mp_gamemode");
	GetConVarString(currentGameMode, g_cGameMode, sizeof(g_cGameMode));	
}

public OnClientPutInServer(client)
{
	// 在40秒内宣布，除非通知被关闭。
	if(client && !IsFakeClient(client) && GetConVarBool(g_advertisePlugin))
	{
		CreateTimer(40.0, TimerAnnounce, client);
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	PrintToChat(client, "\x04 !gamemode \x05更改\x03游戏模式和地图任务的菜单");
}

public Action:Command_Say(client, args)
{
	if(!client)
	{
		return Plugin_Continue;
	}

	decl String:text[192];
	if(!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if(strcmp(text[startidx], "!gamemode", false) == 0)
	{
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			DoGameModeList(client);
		}
	}
	return Plugin_Continue;
}

DoGameModeList(client)
{
	g_gameModeMenu = BuildGameModeMenu(false);
	DisplayMenu(g_gameModeMenu, client, 20);
}

public Handle_GameModeList(Handle:gameModeMenu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if(action == MenuAction_Select)
	{
		decl String:gameMode[32];
		GetMenuItem(gameModeMenu, param2, gameMode, sizeof(gameMode));
		DoVoteMenu(gameMode);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(gameModeMenu);
	}
}

DoVoteMenu(const String:gameMode[])
{
	if(IsVoteInProgress())
	{
		return;
	}
 
	new Handle:voteMenu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(voteMenu, "[游戏模式]将更改为: %s?", gameMode);
	AddMenuItem(voteMenu, gameMode, "Yes");
	AddMenuItem(voteMenu, "no", "No");
	SetMenuExitButton(voteMenu, false);
	
	new voteTime = GetConVarInt(g_modeVoteTime);
	VoteMenuToAll(voteMenu, voteTime);
	
	PrintToChatAll("正在进行[游戏模式更改]投票...");
}

public Handle_VoteMenu(Handle:voteMenu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(voteMenu);
	}
	else if(action == MenuAction_VoteEnd)
	{
		/* 0=yes, 1=no */
		if(param1 == 0)
		{
			GetMenuItem(voteMenu, param1, g_gameMode, sizeof(g_gameMode));
			
			DoCampaginVote();
		}
		else
		{
			PrintToChatAll("保持当前[游戏模式].");
		}
	}
	else if(action == MenuAction_VoteCancel)
	{
		// We were actually cancelled. Guess we do nothing.
	}
}

DoCampaginVote()
{
	if(IsVoteInProgress())
	{
		return;
	}
	
	g_campaginMenu = BuildCampaginMenu(false);

	CreateTimer(1.0, displayCampaginVoteMenu);
}

public Action:displayCampaginVoteMenu(Handle:timer)
{
	new voteTime = GetConVarInt(g_mapVoteTime);
	VoteMenuToAll(g_campaginMenu, voteTime);
	
	PrintToChatAll("[战役模式]投票进行中...");
	
	return Plugin_Handled;
}

public Handle_CampaginVote(Handle:campaginMenu, MenuAction:action, param1, param2)
{	
	if(action == MenuAction_End)
	{
		CloseHandle(campaginMenu);
	}
	else if(action == MenuAction_VoteEnd)
	{
		GetMenuItem(campaginMenu, param1, g_campagin, sizeof(g_campagin));
		
		DoMapVote()
	}
	else if(action == MenuAction_VoteCancel)
	{
		// If we receive 0 votes, pick at random.
		if (param1 == VoteCancel_NoVotes)
			{
				new count = GetMenuItemCount(campaginMenu);
				new item = GetRandomInt(0, count - 1);
				decl String:campagin[32];
				GetMenuItem(campaginMenu, item, campagin, sizeof(campagin));
				
				g_campagin = campagin
			}
			else
			{
				// We were actually cancelled. Guess we do nothing.
			}
	}
}

DoMapVote()
{
	if(IsVoteInProgress())
	{
		return;
	}
	
	g_mapMenu = BuildMapMenu(false);
	
	CreateTimer(1.0, displayMapVoteMenu);
}

public Action:displayMapVoteMenu(Handle:timer)
{
	new voteTime = GetConVarInt(g_mapVoteTime);
	VoteMenuToAll(g_mapMenu, voteTime);
	
	PrintToChatAll("正在进行[更换地图]投票...");
	
	return Plugin_Handled;
}

public Handle_MapVote(Handle:mapMenu, MenuAction:action, param1, param2)
{	
	if(action == MenuAction_End)
	{
		CloseHandle(mapMenu);
	}
	else if(action == MenuAction_VoteEnd)
	{
		ServerCommand("sm_cvar mp_gamemode %s", g_gameMode);
		
		decl String:map[32];
		GetMenuItem(mapMenu, param1, map, sizeof(map));
		
		ServerCommand("changelevel %s", map);
	}
	else if(action == MenuAction_VoteCancel)
	{
		// If we receive 0 votes, pick at random.
		if (param1 == VoteCancel_NoVotes)
			{
				ServerCommand("sm_cvar mp_gamemode %s", g_gameMode);
				
				new count = GetMenuItemCount(mapMenu);
				new item = GetRandomInt(0, count - 1);
				decl String:map[32];
				GetMenuItem(mapMenu, item, map, sizeof(map));
				
				ServerCommand("changelevel %s", map);
			}
			else
			{
				// We were actually cancelled. Guess we do nothing.
			}
	}
}

public Action:Command_CancelVote(client, args)
{
	CancelVote();
	
	return Plugin_Handled;
}

public Action:Command_Coop(client, args)
{
	g_gameMode = "coop";
	ServerCommand("sm_cvar mp_gamemode coop");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_Versus(client, args)
{
	g_gameMode = "versus";
	ServerCommand("sm_cvar mp_gamemode versus");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_Survival(client, args)
{
	g_gameMode = "survival";
	ServerCommand("sm_cvar mp_gamemode survival");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_TeamScavenge(client, args)
{
	g_gameMode = "teamscavenge";
	ServerCommand("sm_cvar mp_gamemode teamscavenge");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_TeamVersus(client, args)
{
	g_gameMode = "teamversus";
	ServerCommand("sm_cvar mp_gamemode teamversus");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_Realism(client, args)
{
	g_gameMode = "realism";
	ServerCommand("sm_cvar mp_gamemode realism");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_Mutation(client, args)
{
	g_gameMode = "mutation";
	ServerCommand("sm_cvar mp_gamemode mutation");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_GameMode(client, args)
{
	g_gameModeMenu = BuildGameModeMenu(true);
	DisplayMenu(g_gameModeMenu, client, 60);
 
	return Plugin_Handled;
}

public Handle_AdminGameModeMenu(Handle:gameModeMenu, MenuAction:action, param1, param2)
{
	// If an option was selected, tell the client about the item.
	if(action == MenuAction_Select)
	{
		GetMenuItem(gameModeMenu, param2, g_gameMode, sizeof(g_gameMode));
		ServerCommand("sm_cvar mp_gamemode %s", g_gameMode);
		
		DoAdminMapMenu(param1);
	}
	// If the menu was cancelled, print a message to the server about it.
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	// If the menu has ended, destroy it
	else if (action == MenuAction_End)
	{
		CloseHandle(gameModeMenu);
	}
}

DoAdminCampaginMenu(client)
{
	g_campaginMenu = BuildCampaginMenu(true);
	DisplayMenu(g_campaginMenu, client, 60);
}

public Handle_AdminCampaginMenu(Handle:campaginMenu, MenuAction:action, param1, param2)
{
	// Change the campagin to the selected item.
	if(action == MenuAction_Select)
	{
		decl String:campagin[32];
		GetMenuItem(campaginMenu, param2, campagin, sizeof(campagin));
		g_campagin = campagin;
		
		DoAdminMapMenu(param1);
	}
	// If the menu was cancelled, choose a random campagin.
	else if (action == MenuAction_Cancel)
	{
		new count = GetMenuItemCount(campaginMenu);
		new item = GetRandomInt(0, count - 1);
		decl String:campagin[32];
		GetMenuItem(campaginMenu, item, campagin, sizeof(campagin));
		
		DoAdminMapMenu(param1);
	}
	// If the menu has ended, destroy it
	else if (action == MenuAction_End)
	{
		CloseHandle(campaginMenu);
	}
}

DoAdminMapMenu(client)
{
	g_mapMenu = BuildMapMenu(true);
	DisplayMenu(g_mapMenu, client, 60);
}

public Handle_AdminMapMenu(Handle:mapMenu, MenuAction:action, param1, param2)
{
	// Change the map to the selected item.
	if(action == MenuAction_Select)
	{
		decl String:map[32];
		GetMenuItem(mapMenu, param2, map, sizeof(map));
		ServerCommand("changelevel %s", map);
	}
	// If the menu was cancelled, choose a random map.
	else if (action == MenuAction_Cancel)
	{
		new count = GetMenuItemCount(mapMenu);
		new item = GetRandomInt(0, count - 1);
		decl String:map[32];
		GetMenuItem(mapMenu, item, map, sizeof(map));
		
		ServerCommand("changelevel %s", map);
	}
	// If the menu has ended, destroy it
	else if (action == MenuAction_End)
	{
		CloseHandle(mapMenu);
	}
}

Handle:BuildGameModeMenu(bool:adminMode)
{
	new Handle:gameModeMenu = INVALID_HANDLE;
	
	if(adminMode)
	{
		gameModeMenu = CreateMenu(Handle_AdminGameModeMenu);
	}
	else
	{
		gameModeMenu = CreateMenu(Handle_GameModeList);
	}
		
	SetMenuTitle(gameModeMenu, "选择游戏模式");
	
	if(strcmp(g_cGameMode, "coop", false) != 0)
	{
		new coopEnabled = GetConVarInt(g_coopEnabled);
		if(adminMode == false && coopEnabled == 0)
		{
			// Don't add the item.
		}
		else
		{
			// Add the item.
			AddMenuItem(gameModeMenu, "coop", "战役-模式");
		}
	}
	if(strcmp(g_cGameMode, "versus", false) != 0)
	{
		new versusEnabled = GetConVarInt(g_versusEnabled);
		if(adminMode == false && versusEnabled == 0)
		{
			// Don't add the item.
		}
		else
		{
			// Add the item.
			AddMenuItem(gameModeMenu, "versus", "对抗-模式");
		}
	}
	if(strcmp(g_cGameMode, "survival", false) != 0)
	{
		new survivalEnabled = GetConVarInt(g_survivalEnabled);
		if(adminMode == false && survivalEnabled == 0)
		{
			// Don't add the item.
		}
		else
		{
			// Add the item.
			AddMenuItem(gameModeMenu, "survival", "生存模式");
		}
	}
	if(strcmp(g_game, "left4dead2", false) == 0)
	{
		if(strcmp(g_cGameMode, "teamscavenge", false) != 0)
		{
			new teamScavengeEnabled = GetConVarInt(g_teamScavengeEnabled);
			if(adminMode == false && teamScavengeEnabled == 0)
			{
				// Don't add the item.
			}
			else
			{
				// Add the item.
				AddMenuItem(gameModeMenu, "teamscavenge", "团队清道夫");
			}
		}
		if(strcmp(g_cGameMode, "teamversus", false) != 0)
		{
			new teamVersusEnabled = GetConVarInt(g_teamVersusEnabled);
			if(adminMode == false && teamVersusEnabled == 0)
			{
				// Don't add the item.
			}
			else
			{
				// Add the item.
				AddMenuItem(gameModeMenu, "teamversus", "团队对抗");
			}
		}
		if(strcmp(g_cGameMode, "realism", false) != 0)
		{
			new realismEnabled = GetConVarInt(g_realismEnabled);
			if(adminMode == false && realismEnabled == 0)
			{
				// Don't add the item.
			}
			else
			{
				// Add the item.
				AddMenuItem(gameModeMenu, "realism", "写实模式");
			}
		}
		if(strcmp(g_cGameMode, "mutation", false) != 0)
		{
			new mutationEnabled = GetConVarInt(g_mutationEnabled);
			if(adminMode == false && mutationEnabled == 0)
			{
				// Don't add the item.
			}
			else
			{
				// Add the item.
				AddMenuItem(gameModeMenu, "mutation", "突变模式");
			}
		}
	}
	return gameModeMenu;
}

Handle:BuildCampaginMenu(bool:adminMode)
{
	new Handle:campaginMenu = INVALID_HANDLE;

	if(adminMode)
	{
		campaginMenu = CreateMenu(Handle_AdminCampaginMenu);
	}
	else
	{
		campaginMenu = CreateMenu(Handle_CampaginVote);
	}
	
	SetMenuTitle(campaginMenu, "投票给战役");
	SetMenuExitButton(campaginMenu, false);
	
	if(strcmp(g_game, "left4dead", false) == 0)	//l4d1建图代码
	{
		AddMenuItem(campaginMenu, "Mercy Hospital", "毫不留情");	//毫不留情(共5关)
		AddMenuItem(campaginMenu, "Crash Course", "坠机险途");	//坠机险途(共2关)
		AddMenuItem(campaginMenu, "Death Toll", "死亡丧钟");		//死亡丧钟(共5关)
		AddMenuItem(campaginMenu, "Dead Air", "静寂时分");			//静寂时分(共5关)
		AddMenuItem(campaginMenu, "Blood Harvest", "血腥收获");	//血腥收获(共5关)
		AddMenuItem(campaginMenu, "The Sacrifice", "牺牲");	//牺牲(共3关)
		if(strcmp(g_gameMode, "survival", false) == 0)
		{
			AddMenuItem(campaginMenu, "Lighthouse", "最后一刻 -灯塔");			//“最后一刻”灯塔战役
		}
	}
	else if(strcmp(g_game, "left4dead2", false) == 0)	//l4d2建图代码
	{
		AddMenuItem(campaginMenu, "Campagin 1", "c1-死亡中心"); 	//死亡中心
		AddMenuItem(campaginMenu, "Campagin 2", "c2-黑色狂欢节"); 	//黑色狂欢节
		AddMenuItem(campaginMenu, "Campagin 3", "c3-沼泽激战"); 	//沼泽激战
		AddMenuItem(campaginMenu, "Campagin 4", "c4-暴风骤雨");		//暴风骤雨
		AddMenuItem(campaginMenu, "Campagin 5", "c5-教区");			//教区
		AddMenuItem(campaginMenu, "The Passing", "c6-短暂时刻"); 	//c6-短暂时刻
		AddMenuItem(campaginMenu, "The Sacrifice", "c7-牺牲");		//c7-牺牲
		AddMenuItem(campaginMenu, "Mercy Hospital", "c8-毫不留情");	//c8-毫不留情
		AddMenuItem(campaginMenu, "Crash Course", "c9-坠机险途");	//c9-坠机险途
		AddMenuItem(campaginMenu, "Death Toll", "c10-死亡丧钟");	//c10-死亡丧钟
		AddMenuItem(campaginMenu, "Dead Air", "c11-静寂时分");		//c11-静寂时分
		AddMenuItem(campaginMenu, "Blood Harvest", "c12-血腥收获");	//c12-血腥收获
		AddMenuItem(campaginMenu, "Cold Stream", "c13-刺骨寒溪");	//c13-刺骨寒溪
	}
	return campaginMenu;
}

Handle:BuildMapMenu(bool:adminMode)
{
	new Handle:mapMenu = INVALID_HANDLE;
	
	if(adminMode)
	{
		mapMenu = CreateMenu(Handle_AdminMapMenu);
	}
	else
	{
		mapMenu = CreateMenu(Handle_MapVote);
	}
	
	SetMenuTitle(mapMenu, "选择地图");
	SetMenuExitButton(mapMenu, false);
	
	if(strcmp(g_game, "left4dead", false) == 0)	//l4d1建图代码
	{
		if(strcmp(g_gameMode, "coop", false) == 0)
		{
			if(strcmp(g_campagin, "Mercy Hospital", false) == 0)	//毫不留情(共5关)
			{
				AddMenuItem(mapMenu, "l4d_hospital01_apartment", "毫不留情1_Apartment");
				AddMenuItem(mapMenu, "l4d_hospital02_subway", "毫不留情2_Generator Room");
				AddMenuItem(mapMenu, "l4d_hospital03_sewers", "毫不留情3_Gas Station");
				AddMenuItem(mapMenu, "l4d_hospital04_interior", "毫不留情4_Hospital");
				AddMenuItem(mapMenu, "l4d_hospital05_rooftop", "毫不留情5_Rooftop");
			}
			else if(strcmp(g_campagin, "Crash Course", false) == 0)	//坠机险途(共2关)
			{
				AddMenuItem(mapMenu, "l4d_garage01_alleys", "坠机险途1_Alleys");	
				AddMenuItem(mapMenu, "l4d_garage02_lots", "坠机险途2_Truck Depot");
			}
			else if(strcmp(g_campagin, "Death Toll", false) == 0)	//死亡丧钟_(共5关)
			{
				AddMenuItem(mapMenu, "l4d_smalltown01_caves", "死亡丧钟1_Caves");
				AddMenuItem(mapMenu, "l4d_smalltown02_drainage", "死亡丧钟2_Drains");
				AddMenuItem(mapMenu, "l4d_smalltown03_ranchhouse", "死亡丧钟3_Church");
				AddMenuItem(mapMenu, "l4d_smalltown04_mainstreet", "死亡丧钟4_Street");
				AddMenuItem(mapMenu, "l4d_smalltown05_houseboat", "死亡丧钟5_Boathouse");
			}
			else if(strcmp(g_campagin, "Dead Air", false) == 0)	//静寂时分_(共5关)
			{
				AddMenuItem(mapMenu, "l4d_airport01_greenhouse", "静寂时分1_Greenhouse");
				AddMenuItem(mapMenu, "l4d_airport02_offices", "静寂时分2_Crane");
				AddMenuItem(mapMenu, "l4d_airport03_garage", "静寂时分3_Construction Site");
				AddMenuItem(mapMenu, "l4d_airport04_terminal", "静寂时分4_Terminal");
				AddMenuItem(mapMenu, "l4d_airport05_runway", "静寂时分5_Runway");
			}
			else if(strcmp(g_campagin, "Blood Harvest", false) == 0)	//血腥收获(共5关)
			{
				AddMenuItem(mapMenu, "l4d_farm01_hilltop", "血腥收获1_Hilltop");
				AddMenuItem(mapMenu, "l4d_farm02_traintunnel", "血腥收获2_Warehouse");
				AddMenuItem(mapMenu, "l4d_farm03_bridge", "血腥收获3_Bridge");
				AddMenuItem(mapMenu, "l4d_farm04_barn", "血腥收获4_Barn");
				AddMenuItem(mapMenu, "l4d_farm05_cornfield", "血腥收获5_Farmhouse");
			}
			else if(strcmp(g_campagin, "The Sacrifice", false) == 0)	//牺牲(共3关)
			{
				AddMenuItem(mapMenu, "l4d_river01_docks", "牺牲1_Docks");
				AddMenuItem(mapMenu, "l4d_river02_barge", "牺牲2_Barge");
				AddMenuItem(mapMenu, "l4d_river03_port", "牺牲3_The Port");
			}
		}
		else if(strcmp(g_gameMode, "versus", false) == 0)			//对抗模式
		{
			if(strcmp(g_campagin, "Mercy Hospital", false) == 0)	//毫不留情(共5关)
			{
				AddMenuItem(mapMenu, "l4d_vs_hospital01_apartment", "毫不留情1_Apartment");
				AddMenuItem(mapMenu, "l4d_vs_hospital02_subway", "毫不留情2_Generator Room");
				AddMenuItem(mapMenu, "l4d_vs_hospital03_sewers", "毫不留情3_Gas Station");
				AddMenuItem(mapMenu, "l4d_vs_hospital04_interior", "毫不留情4_Hospital");
				AddMenuItem(mapMenu, "l4d_vs_hospital05_rooftop", "毫不留情5_Rooftop");
			}
			else if(strcmp(g_campagin, "Crash Course", false) == 0)		//坠机险途(共2关)
			{
				AddMenuItem(mapMenu, "l4d_garage01_alleys", "坠机险途1_Alleys");
				AddMenuItem(mapMenu, "l4d_garage02_lots", "坠机险途2_Truck Depot");
			}
			else if(strcmp(g_campagin, "Death Toll", false) == 0)		//死亡丧钟(共5关)
			{
				AddMenuItem(mapMenu, "l4d_vs_smalltown01_caves", "死亡丧钟1_Caves");
				AddMenuItem(mapMenu, "l4d_vs_smalltown02_drainage", "死亡丧钟2_Drains");
				AddMenuItem(mapMenu, "l4d_vs_smalltown03_ranchhouse", "死亡丧钟3_Church");
				AddMenuItem(mapMenu, "l4d_vs_smalltown04_mainstreet", "死亡丧钟4_Street");
				AddMenuItem(mapMenu, "l4d_vs_smalltown05_houseboat", "死亡丧钟5_Boathouse");
			}
			else if(strcmp(g_campagin, "Dead Air", false) == 0)				//静寂时分(共5关)
			{
				AddMenuItem(mapMenu, "l4d_vs_airport01_greenhouse", "静寂时分1_Greenhouse");
				AddMenuItem(mapMenu, "l4d_vs_airport02_offices", "静寂时分2_Crane");
				AddMenuItem(mapMenu, "l4d_vs_airport03_garage", "静寂时分3_Construction Site");
				AddMenuItem(mapMenu, "l4d_vs_airport04_terminal", "静寂时分4_Terminal");
				AddMenuItem(mapMenu, "l4d_vs_airport05_runway", "静寂时分5_Runway");
			}
			else if(strcmp(g_campagin, "Blood Harvest", false) == 0)		//血腥收获(共5关)
			{
				AddMenuItem(mapMenu, "l4d_vs_farm01_hilltop", "血腥收获1_Hilltop");
				AddMenuItem(mapMenu, "l4d_vs_farm02_traintunnel", "血腥收获2_Warehouse");
				AddMenuItem(mapMenu, "l4d_vs_farm03_bridge", "血腥收获3_Bridge");
				AddMenuItem(mapMenu, "l4d_vs_farm04_barn", "血腥收获4_Barn");
				AddMenuItem(mapMenu, "l4d_vs_farm05_cornfield", "血腥收获5_Farmhouse");
			}
			else if(strcmp(g_campagin, "The Sacrifice", false) == 0)		//牺牲(共3关)
			{
				AddMenuItem(mapMenu, "l4d_river01_docks", "牺牲1_Docks");
				AddMenuItem(mapMenu, "l4d_river02_barge", "牺牲2_Barge");
				AddMenuItem(mapMenu, "l4d_river03_port", "牺牲3_The Port");
			}
		}
		else if(strcmp(g_gameMode, "survival", false) == 0)			//生存模式
		{
			if(strcmp(g_campagin, "Mercy Hospital", false) == 0)					//毫不留情
			{
				AddMenuItem(mapMenu, "l4d_hospital02_subway", "毫不留情1_Generator Room");	
				AddMenuItem(mapMenu, "l4d_hospital03_sewers", "毫不留情2_Gas Station");
				AddMenuItem(mapMenu, "l4d_hospital04_interior", "毫不留情3_Hospital");
				AddMenuItem(mapMenu, "l4d_vs_hospital05_rooftop", "毫不留情4_Rooftop");
			}
			else if(strcmp(g_campagin, "Crash Course", false) == 0)					//坠机险途
			{
				AddMenuItem(mapMenu, "l4d_garage01_alleys", "坠机险途1_Bridge");
				AddMenuItem(mapMenu, "l4d_garage02_lots", "坠机险途2_Truck Depot");
			}
			else if(strcmp(g_campagin, "Death Toll", false) == 0)					//死亡丧钟
			{
				AddMenuItem(mapMenu, "l4d_smalltown02_drainage", "死亡丧钟1_Drains");
				AddMenuItem(mapMenu, "l4d_smalltown03_ranchhouse", "死亡丧钟2_Church");
				AddMenuItem(mapMenu, "l4d_smalltown04_mainstreet", "死亡丧钟3_Street");
				AddMenuItem(mapMenu, "l4d_vs_smalltown05_houseboat", "死亡丧钟4_Boathouse");
			}
			else if(strcmp(g_campagin, "Dead Air", false) == 0)						//静寂时分
			{
				AddMenuItem(mapMenu, "l4d_airport02_offices", "静寂时分1_Crane");
				AddMenuItem(mapMenu, "l4d_airport03_garage", "静寂时分2_Construction Site");
				AddMenuItem(mapMenu, "l4d_airport04_terminal", "静寂时分3_Terminal");
				AddMenuItem(mapMenu, "l4d_vs_airport05_runway", "静寂时分4_Runway");
			}
			else if(strcmp(g_campagin, "Blood Harvest", false) == 0)				//血腥收获
			{
				AddMenuItem(mapMenu, "l4d_farm02_traintunnel", "血腥收获1_Warehouse");
				AddMenuItem(mapMenu, "l4d_farm03_bridge", "血腥收获2_Bridge (bloodharvest)");
				AddMenuItem(mapMenu, "l4d_vs_farm05_cornfield", "血腥收获3_Farmhouse");
			}
			else if(strcmp(g_campagin, "The Sacrifice", false) == 0)			//牺牲
			{
				AddMenuItem(mapMenu, "l4d_river01_docks", "牺牲1_The Traincar");
				AddMenuItem(mapMenu, "l4d_river03_port", "牺牲2_The Port");
			}
			else if(strcmp(g_campagin, "Lighthouse", false) == 0)				//灯塔战役
			{
				AddMenuItem(mapMenu, "l4d_sv_lighthouse", "灯塔Lighthouse");
			}
		}
	}
	else if(strcmp(g_game, "left4dead2", false) == 0)	//l4d2建图代码 
	{
		if(strcmp(g_campagin, "Campagin 1", false) == 0)	//c1-死亡中心
		{
			AddMenuItem(mapMenu, "c1m1_hotel", "c1-死亡中心1旅馆Hotel");
			AddMenuItem(mapMenu, "c1m2_streets", "死亡中心2街道Streets");
			AddMenuItem(mapMenu, "c1m3_mall", "死亡中心3购物中心Mall");
			AddMenuItem(mapMenu, "c1m4_atrium", "死亡中心4中厅Atrium");
		}
		else if(strcmp(g_campagin, "Campagin 2", false) == 0)	//c2-黑色狂欢节
		{
			AddMenuItem(mapMenu, "c2m1_highway", "c2-黑色狂欢节1高速公路Highway");
			AddMenuItem(mapMenu, "c2m2_fairgrounds", "黑色狂欢节2游乐场Fairgrounds");
			AddMenuItem(mapMenu, "c2m3_coaster", "黑色狂欢节3过山车Coaster");
			AddMenuItem(mapMenu, "c2m4_barns", "黑色狂欢节4谷仓Barns");
			AddMenuItem(mapMenu, "c2m5_concert", "黑色狂欢节5音乐会Concert");
		}
		else if(strcmp(g_campagin, "Campagin 3", false) == 0)		//c3-沼泽激战
		{
			AddMenuItem(mapMenu, "c3m1_plankcountry", "c3-沼泽激战1乡村Plank Country");
			AddMenuItem(mapMenu, "c3m2_swamp", "沼泽激战2沼泽Swamp");
			AddMenuItem(mapMenu, "c3m3_shantytown", "沼泽激战3贫民窟Shanty Town");
			AddMenuItem(mapMenu, "c3m4_plantation", "沼泽激战4种植园Plantation");
		}
		else if(strcmp(g_campagin, "Campagin 4", false) == 0)			//c4-暴风骤雨
		{
			AddMenuItem(mapMenu, "c4m1_milltown_a", "c4-暴风骤雨1密尔城Mill Town 1");
			AddMenuItem(mapMenu, "c4m2_sugarmill_a", "暴风骤雨2糖厂Sugar Mill 1");
			AddMenuItem(mapMenu, "c4m3_sugarmill_b", "暴风骤雨3逃离工厂Sugar Mill 2");
			AddMenuItem(mapMenu, "c4m4_milltown_b", "暴风骤雨4重返小镇Mill Town 2");
			AddMenuItem(mapMenu, "c4m5_milltown_escape", "暴风骤雨5逃离小镇Mill Town Escape");
		}
		else if(strcmp(g_campagin, "Campagin 5", false) == 0)		//c5-教区
		{
			AddMenuItem(mapMenu, "c5m1_waterfront", "c5-教区1-码头Waterfront");
			AddMenuItem(mapMenu, "c5m2_park", "教区2-公园Park");
			AddMenuItem(mapMenu, "c5m3_cemetery", "教区3-墓地Cemetery");
			AddMenuItem(mapMenu, "c5m4_quarter", "教区4-特区Quarter");
			AddMenuItem(mapMenu, "c5m5_bridge ", "教区5-桥Bridge");
		}
		else if(strcmp(g_campagin, "The Passing", false) == 0)	//c6-短暂时刻
		{
			AddMenuItem(mapMenu, "C6m1_riverbank", "c6-短暂时刻River Bank");
			AddMenuItem(mapMenu, "C6m2_bedlam", "短暂时刻Bedlam");
			AddMenuItem(mapMenu, "C6m3_port", "短暂时刻Port");
		}
		else if(strcmp(g_campagin, "The Sacrifice", false) == 0)	//c7-牺牲
		{
			AddMenuItem(mapMenu, "C7m1_docks", "c7-牺牲Docks");
			AddMenuItem(mapMenu, "C7m2_barge", "牺牲Barge");
			AddMenuItem(mapMenu, "C7m3_port", "牺牲Port");
		}
		else if(strcmp(g_campagin, "Mercy Hospital", false) == 0)	//c8-毫不留情
		{
			AddMenuItem(mapMenu, "C8m1_apartment", "c8-毫不留情Apartments");
			AddMenuItem(mapMenu, "C8m2_subway", "毫不留情Subway");
			AddMenuItem(mapMenu, "C8m3_sewers", "毫不留情Sewers");
			AddMenuItem(mapMenu, "C8m4_interior", "毫不留情Interior");
			AddMenuItem(mapMenu, "C8m5_rooftop", "毫不留情Rooftop");
		}
		else if(strcmp(g_campagin, "Crash Course", false) == 0)	//c9-坠机险途-----添加c9 mapMenu
		{
			AddMenuItem(mapMenu, "c9m1_alleys", "c9-坠机险途-小巷");
			AddMenuItem(mapMenu, "c9m2_lots", "坠机险途-卡车停车场");
		}
		else if(strcmp(g_campagin, "Death Toll", false) == 0)	//c10-死亡丧钟
		{		
			AddMenuItem(mapMenu, "C10m1_caves", "c10-死亡丧钟Caves");
			AddMenuItem(mapMenu, "C10m2_drainage", "死亡丧钟Drainage");
			AddMenuItem(mapMenu, "C10m3_ranchhouse", "死亡丧钟Ranch House");
			AddMenuItem(mapMenu, "C10m4_mainstreet", "死亡丧钟Main Street");
			AddMenuItem(mapMenu, "C10m5_houseboat", "死亡丧钟House Boat");		
		}
		else if(strcmp(g_campagin, "Dead Air", false) == 0)		//c11-静寂时分
		{
			AddMenuItem(mapMenu, "C11m1_greenhouse", "c11-静寂时分Greenhouse");	
			AddMenuItem(mapMenu, "C11m2_offices", "静寂时分Offices");
			AddMenuItem(mapMenu, "C11m3_garage", "静寂时分Garage");
			AddMenuItem(mapMenu, "11m4_terminal", "静寂时分Terminal");
			AddMenuItem(mapMenu, "C11m5_runway", "静寂时分Runway");
		}
		else if(strcmp(g_campagin, "Blood Harvest", false) == 0)	//c12-血腥收获
		{
			AddMenuItem(mapMenu, "C12m1_hilltop", "c12-血腥收获Hilltop");
			AddMenuItem(mapMenu, "C12m2_traintunnel", "血腥收获Train Tunnel");
			AddMenuItem(mapMenu, "C12m3_bridge", "血腥收获Bridge");
			AddMenuItem(mapMenu, "C12m4_barn", "血腥收获Barn");
			AddMenuItem(mapMenu, "C12m5_cornfield", "血腥收获Cornfield");
		}
		else if(strcmp(g_campagin, "Cold Stream", false) == 0)	//c13-刺骨寒溪
		{
			AddMenuItem(mapMenu, "C13m1_alpinecreek", "c13-刺骨寒溪1_Alpine Creek");
			AddMenuItem(mapMenu, "C13m2_southpinestream", "刺骨寒溪2_South Pine Stream");
			AddMenuItem(mapMenu, "C13m3_memorialbridge", "刺骨寒溪3_Memorial Bridge");
			AddMenuItem(mapMenu, "13m4_cutthroatcreek", "刺骨寒溪4_Cut Throat Creek");
		}
		else if(strcmp(g_campagin, "The Sacrifice again?", false) == 0)	//再次牺牲？
		{
			AddMenuItem(mapMenu, "l4d_river01_docks", "牺牲1_The Traincar");
			AddMenuItem(mapMenu, "l4d_river03_port", "牺牲2_The Port");
		}
	}
	return mapMenu;
}