#include <sourcemod>
#include <sdktools_functions>
#pragma semicolon 1
#pragma newdecls required

bool RJoincheck;
bool RCNcheck;
bool RAutoBotcheck;
char Rmc_ChangeTeam[66];
Handle hRJoincheck;
Handle hAutoBotcheck;
Handle hAwayCEnable;
Handle hUsermnums;
int usermnums;
int AwayCEnable;

public Plugin myinfo =
{
	name = "L4D2 Multiplayer RMC",
	description = "L4D2 Multiplayer Commands (!jg, !joingame, !away, !addbot, !sinfo, !sp, !zs, !bd, !rhelp, !kb, !sset)",
	author = "Ryanx，joyist",
	version = "1.2",
	url = "http://chdong.top/"
};

public void OnPluginStart()
{
	CreateConVar("L4D2_Multiplayer_RMC_version", "1.1", "L4D2多人游戏设置");
	RegConsoleCmd("sm_jg", Jointhegame);
	RegConsoleCmd("sm_joingame", Jointhegame);
	RegConsoleCmd("sm_away", Gotoaway);
	RegConsoleCmd("sm_addbot", CreateOneBot);
	RegConsoleCmd("sm_sinfo", Vserverinfo);
	RegConsoleCmd("sm_bd", Bindkeyhots);
	RegConsoleCmd("sm_rhelp", Scdescription);
	RegAdminCmd("sm_kb", Kbcheck, ADMFLAG_ROOT);
	RegConsoleCmd("sm_sp", RListLoadplayer);
	RegConsoleCmd("sm_zs", Rzhisha);
	RegAdminCmd("sm_set", Numsetcheck, ADMFLAG_ROOT);
	HookEvent("round_start", Event_rmcRoundStart, EventHookMode_Post);
	HookEvent("player_team", Event_rmcteam, EventHookMode_Pre);
	hUsermnums = CreateConVar("L4D2_Rmc_total", "4", "服务器支持玩家人数设置");
	usermnums = GetConVarInt(hUsermnums);
	hRJoincheck = CreateConVar("l4d2_ADM_CHA", "0", "[0=关|1=开]是否开启2个管理员预留通道");
	RJoincheck = GetConVarBool(hRJoincheck);
	hAwayCEnable = CreateConVar("L4D2_Away_Enable", "0", "[0=关|1=开]是否只允许管理员使用!away加入观察者.1=On,0=Off");
	AwayCEnable = GetConVarBool(hAwayCEnable);
	hAutoBotcheck = CreateConVar("l4d2_AUOT_ADDBOT", "1", "[0=关|1=开]是否开启自动增加BOT");
	RAutoBotcheck = GetConVarBool(hAutoBotcheck);
	RCNcheck = false;
	AutoExecConfig(true, "l4d2_rmc");
}

public void OnMapStart()
{
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 999999, false, false);
	RJoincheck = GetConVarBool(hRJoincheck);
	AwayCEnable = GetConVarBool(hAwayCEnable);
	RAutoBotcheck = GetConVarBool(hAutoBotcheck);
	if (!RCNcheck)
	{
		usermnums = GetConVarInt(hUsermnums);
		if (usermnums < 1)
		{
			usermnums = 1;
		}
	}
}

public Action Event_rmcRoundStart(Event event, char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, rmcRepDelays);
}

public Action JgHintplayers16(Handle timer, any client)
{
	if (0 < Botnums())
	{
		if (0 < Alivebotnums())
		{
			ClientCommand(client, "jointeam 2");
			ClientCommand(client, "go_away_from_keyboard");
		}
		PrintToChat(client, "\x05[加入失败:]\x04请等待BOT被拯救后再输入!jg加入.");
	}
	PrintToChat(client, "\x05[加入失败:]\x04没有足够的BOT允许你控制,请输入!addbot增加电脑. ");
}

public void OnClientDisconnect(int client)
{
	if (client)
	{
		Rmc_ChangeTeam[client] = 0;
		CreateTimer(1.0, DisKickClient);
	}
}

public Action DisKickClient(Handle timer)
{
	char asnus[4];
	char aynus[4];
	char abnus[4];
	int asnus1 = 0;
	int aynus1 = 0;
	int abnus1 = 0;
	Format(asnus, 3, "%i", Survivors());
	Format(aynus, 3, "%i", Gonaways());
	Format(abnus, 3, "%i", Botnums());
	asnus1 = StringToInt(asnus, 10);
	aynus1 = StringToInt(aynus, 10);
	abnus1 = StringToInt(abnus, 10);
	if (abnus1 > aynus1)
	{
		if (asnus1 > 4)
		{
			int i = 1;
			while (i <= MaxClients)
			{
				if (IsClientInGame(i))
				{
					KickClient(i, "");
				}
				i++;
			}
		}
	}
}

public Action rmcRepDelays(Handle timer)
{
	if (usermnums < 1)
	{
		usermnums = 1;
	}
	if (RJoincheck)
	{
		ServerCommand("sm_cvar sv_maxplayers %i", usermnums + 2);
		ServerCommand("sm_cvar sv_visiblemaxplayers %i", usermnums);
		PrintToChatAll("\x04[提示] \x03公共位置\x01[%i] \x03管理员预留位置\x01[2]", 2272);
	}
	else
	{
		ServerCommand("sm_cvar sv_maxplayers %i", usermnums);
		ServerCommand("sm_cvar sv_visiblemaxplayers %i", usermnums);
	}
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (RJoincheck)
	{
		int Rnmax = GetConVarInt(FindConVar("sv_maxplayers"));
		int asnus1 = Allplayersn();
		if (Rnmax + -2 <= asnus1)
		{
			if (client)
			{
				KickClient(client, "服务器已满,你不是管理员无法进入预留通道!");
			}
			Rmc_ChangeTeam[client] = 0;
			return true;
		}
		Rmc_ChangeTeam[client] = 0;
		return true;
	}
	Rmc_ChangeTeam[client] = 0;
	return true;
}

public Action Kbcheck(int client, int args)
{
	if (GetUserFlagBits(client))
	{
		int ix = 1;
		while (ix <= MaxClients)
		{
			if (IsClientInGame(ix))
			{
				KickClient(ix, "");
				ix++;
			}
			ix++;
		}
		PrintToChatAll("\x05[提示]\x03 踢除所有bot.");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
	return Plugin_Handled;
}

public Action Numsetcheck(int client, int args)
{
	if (GetUserFlagBits(client))
	{
		rDisplaySnumMenu(client);
	}
	ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
	return Plugin_Handled;
}

public int rDisplaySnumMenu(int client)
{
	char namelist[64];
	char nameno[4];
	Handle menu = CreateMenu(rNumMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem|MenuAction_VoteEnd);
	SetMenuTitle(menu, "服务器人数设置");
	int i = 1;
	while (i <= 24)
	{
		Format(nameno, 3, "%i", i);
		AddMenuItem(menu, nameno, namelist, 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int rNumMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		char clientinfos[12];
		int userids = 0;
		GetMenuItem(menu, itemNum, clientinfos, sizeof(clientinfos));
		userids = StringToInt(clientinfos, 10);
		usermnums = userids;
		RCNcheck = true;
		PrintToChat(client, "\x05[提醒:]\x04 默认人数请修改l4d2_rmc.cfg");
		CreateTimer(0.1, rmcRepDelays);
	}
	return 0;
}

public Action Scdescription(int client, int args)
{
	PrintToChatAll("\x05[插件说明]\x03 !jg\x04或\x03!joingame\x04 加入游戏, \x03!away\x04 观察者, \x03!addbot\x04 增加一个电脑,");
	PrintToChatAll("\x05[插件说明]\x03 !sinfo\x04 显示服务器人数信息, \x03!rhelp\x04 显示插件使用说明, \x03!bd\x04 绑定键盘 L 键自动输入joingame");
	PrintToChatAll("\x05[插件说明]\x03 !sp\x04 显示还在加载中的玩家列表, \x03!zs\x04 自杀");
	PrintToChatAll("\x05[插件说明]\x03 !kb\x04 踢除所有bot, \x03!sset\x04 设置服务器人数 \x03");
	return Plugin_Handled;
}

public Action Bindkeyhots(int client, int args)
{
	ClientCommand(client, "bind l \"say_team !joingame\"");
	PrintToChat(client, "\x05[提醒:]\x04已绑定键盘\x03 L \x04键为自动输入\x03!joingame\x04");
	return Plugin_Handled;
}

public Action Gotoaway(int client, int argCount)
{
	if (AwayCEnable)
	{
		if (GetUserFlagBits(client))
		{
			ChangeClientTeam(client, 1);
		}
		PrintToChat(client, "\x05[失败:]\x04服务没有开启!away可请管理员修改l4d2_rmc.cfg");
	}
	ChangeClientTeam(client, 1);
}

public Action Jointhegame(int client, int args)
{
	if (0 < Botnums())
	{
		if (0 < Alivebotnums())
		{
			ClientCommand(client, "jointeam 2");
			ClientCommand(client, "go_away_from_keyboard");
		}
		PrintToChat(client, "\x05[加入失败:]\x04请等待BOT被拯救后再输入!jg加入.");
		return Plugin_Handled;
	}
	PrintToChat(client, "\x05[加入失败:]\x04没有足够的BOT允许你控制,请输入!addbot增加电脑.");
	return Plugin_Handled;
}

public int Survivors()
{
	int numSurvivors = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			numSurvivors++;
			i++;
		}
		i++;
	}
	return numSurvivors;
}

public int AliveSurvivors()
{
	int numSurvivors = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientConnected(i))
		{
			numSurvivors++;
			i++;
		}
		i++;
	}
	return numSurvivors;
}

public int Allplayersn()
{
	int numplayers = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientConnected(i))
		{
			numplayers++;
			i++;
		}
		i++;
	}
	return numplayers;
}

public int Botnums()
{
	int numBots = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			numBots++;
			i++;
		}
		i++;
	}
	return numBots;
}

public int Alivebotnums()
{
	int AnumBots = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			AnumBots++;
			i++;
		}
		i++;
	}
	return AnumBots;
}

public int Gonaways()
{
	int numaways = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			numaways++;
			i++;
		}
		i++;
	}
	return numaways;
}

public Action Vserverinfo(int client, int args)
{
	PrintToChat(client, "\x05[提示]\x03 幸存者数量 \x04[%i]\x03 玩家幸存者数量 \x04[%i]\x03 观察者数量 \x04[%i]\x03 bot数量 \x04[%i]\x03 生存的bot数量 \x04[%i]", Survivors(), AliveSurvivors(), Gonaways(), Botnums(), Alivebotnums());
	return Plugin_Handled;
}

public Action Rzhisha(int client, int args)
{
	if (IsClientInGame(client))
	{
		ForcePlayerSuicide(client);
	}
	return Plugin_Handled;
}

public Action RListLoadplayer(int client, int args)
{
	char RLPlist[64];
	int Rlnameall = 0;
	bool RloadplayerN = false;
	PrintToChatAll("\x05[提示]\x03 加载中的玩家列表...");
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientConnected(i))
		{
			GetClientName(i, RLPlist, 64);
			Rlnameall++;
			PrintToChatAll("\x05[%i]\x04 %s \x01ID: %i", Rlnameall, RLPlist, i);
			RloadplayerN = true;
			i++;
		}
		i++;
	}
	if (!RloadplayerN)
	{
		PrintToChatAll("\x05       ------ 无 ------");
	}
	else
	{
		PrintToChatAll("\x05------\x04 %i \x05人还在加载中------", Rlnameall);
	}
	return Plugin_Handled;
}

public Action CreateOneBot(int client, int agrs)
{
	LCreateOneBot(client);
}

public int LCreateOneBot(int client)
{
	char asnus[4];
	char aynus[4];
	char abnus[4];
	int aynus1 = 0;
	int abnus1 = 0;
	Format(asnus, 3, "%i", Survivors());
	Format(aynus, 3, "%i", Gonaways());
	Format(abnus, 3, "%i", Botnums());
	aynus1 = StringToInt(aynus, 10);
	abnus1 = StringToInt(abnus, 10);
	if (abnus1 < aynus1)
	{
		int survivorbot = CreateFakeClient("survivor bot");
		ChangeClientTeam(survivorbot, 2);
		DispatchKeyValue(survivorbot, "classname", "SurvivorBot");
		DispatchSpawn(survivorbot);
		CreateTimer(1.0, SurvivorKicker, survivorbot);
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsClientConnected(i))
			{
				float vAngles1[3];
				float vOrigin1[3];
				GetClientAbsOrigin(i, vOrigin1);
				GetClientAbsAngles(i, vAngles1);
				TeleportEntity(survivorbot, vOrigin1, vAngles1, NULL_VECTOR);
			}
			i++;
		}
	}
	else
	{
		PrintCenterText(client, "\x05[提示]\x03 无需增加bot.");
		PrintToChat(client, "\x05[提示]\x03 无需增加bot.");
	}
}

public Action SurvivorKicker(Handle timer, any survivorbot)
{
	KickClient(survivorbot, "CreateOneBot...");
	PrintToChatAll("\x05[提示]\x01 BOT 创建完成,加入请按鼠标左键.");
}

public Action Event_rmcteam(Event event, char[] name, bool dontBroadcast)
{
	if (RAutoBotcheck)
	{
		int Client = GetClientOfUserId(event.GetInt("userid"));
		if (Client)
		{
			if (Rmc_ChangeTeam[Client])
			{
			}
			else
			{
				CreateTimer(0.5, JointeamRmc, Client);
				Rmc_ChangeTeam[Client] = 1;
			}
		}
	}
}

public Action JointeamRmc(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		if (GetClientTeam(client) != 2)
		{
			LCreateOneBot(client);
			CreateTimer(1.5, JgHintplayers16, client);
		}
	}
}