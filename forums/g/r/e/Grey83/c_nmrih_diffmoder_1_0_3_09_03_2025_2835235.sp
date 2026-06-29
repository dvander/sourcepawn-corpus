#pragma newdecls required
#pragma semicolon 1

#include <sdkhooks>
#include <sdktools_functions>
#include <sdktools_entinput>

static const float	VOTE_LIMIT			= 0.6;
static const int	MENUDISPLAY_TIME	= 20;
static const char
	sModVote[][] =
{
	"ModMenuRunerVote",
	"ModMenuKidVote",
	"ModMenuDefVote"
},
	sDifVote[][] =
{
	"DifMenuClassicVote",
	"DifMenuCasualVote",
	"DifMenuNightmareVote",
	"DifMenuDefVote"
},
	sConfVote[][] =
{
	"ConfMenuRealismVote",
	"ConfMenuFriendlyVote",
	"ConfMenuHardcoreVote",
	"ConfMenuDefaultVote"
},
	sModItem[][] =
{
	"ModMenuItemRunner",
	"ModMenuItemKid",
	"ModMenuItemDefault"
},
	sDifItem[][] =
{
	"DifMenuItemClassic",
	"DifMenuItemCasual",
	"DifMenuItemNightmare",
	"DifMenuItemDefault"
};

enum GameMod{
	GameMod_Runner,
	GameMod_Kid,
	GameMod_Default
}

enum GameDif{
	GameDif_Classic,
	GameDif_Casual,
	GameDif_Nightmare,
	GameDif_Default
}

enum GameConf{
	GameConf_Realism,
	GameConf_Friendly,
	GameConf_Hardcore,
	GameConf_Default
}

ConVar
	sv_max_runner_chance,
	ov_runner_chance,
	ov_runner_kid_chance,
	sv_realism, mp_friendlyfire,
	sv_hardcore_survival,
	sv_difficulty;
bool
	g_bSVRealism_default,
	g_bMpFriendlyFire_default,
	g_bSVHardcore_default, g_bEnable;
float
	g_fMax_runner_chance_default,
	g_fRunner_chance_default,
	g_fRunner_kid_chance_default;
char
	g_cSVDifficult_default[32];

public Plugin myinfo =
{
	name		= "[NMRiH] Difficult Moder",
	author		= "Mostten (rewritten by Grey83)",
	description	= "Allow player to enable the change difficult and mod by ballot.",
	version		= "1.0.3_09.03.2025",
	url			= "https://forums.alliedmods.net/showthread.php?t=301322"
}

public void OnPluginStart()
{
	LoadTranslations("nmrih.diffmoder.phrases");

	(sv_difficulty = CreateConVar("nmrih_diffmoder", "1", "Enable/Disable plugin.", FCVAR_NOTIFY, true, _, true, 1.0)).AddChangeHook(CvarChange_Enable);
	CvarChange_Enable(sv_difficulty, NULL_STRING, NULL_STRING);

	(sv_max_runner_chance = FindConVar("sv_max_runner_chance")).AddChangeHook(CvarChange_Runner);
	g_fMax_runner_chance_default = sv_max_runner_chance.FloatValue;

	(ov_runner_chance = FindConVar("ov_runner_chance")).AddChangeHook(CvarChange_Runner);
	g_fRunner_chance_default = ov_runner_chance.FloatValue;

	(ov_runner_kid_chance = FindConVar("ov_runner_kid_chance")).AddChangeHook(CvarChange_Runner);
	g_fRunner_kid_chance_default = ov_runner_kid_chance.FloatValue;

	g_bSVRealism_default = (sv_realism = FindConVar("sv_realism")).BoolValue;

	g_bMpFriendlyFire_default = (mp_friendlyfire = FindConVar("mp_friendlyfire")).BoolValue;

	g_bSVHardcore_default = (sv_hardcore_survival = FindConVar("sv_hardcore_survival")).BoolValue;

	(sv_difficulty = FindConVar("sv_difficulty")).AddChangeHook(CvarChange_Diff);
	sv_difficulty.GetString(g_cSVDifficult_default, sizeof(g_cSVDifficult_default));

	//Reg Cmd
	RegConsoleCmd("sm_dif", Cmd_MenuTop);
	RegConsoleCmd("sm_difshow", Cmd_InfoShow);
}

public void CvarChange_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	static bool hooked;
	if(hooked == (g_bEnable = CVar.BoolValue)) return;

	if(!(hooked ^= true))
		UnhookEvent("nmrih_round_begin", Event_RoundBegin, EventHookMode_PostNoCopy);
	else HookEvent("nmrih_round_begin", Event_RoundBegin, EventHookMode_PostNoCopy);
}

public void CvarChange_Runner(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	GameMod_Enable(Game_GetMod());
}

public void CvarChange_Diff(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	GameDiff_Enable(Game_GetDif());
}

public void OnConfigsExecuted()
{
	ConVars_InitDefault();
}

public void OnPluginEnd()
{
	ConVars_InitDefault();
}

void ConVars_InitDefault()
{
	GameMod_Def();
	GameDiff_Def();
	GameConfig_Def();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(g_bEnable && entity > MaxClients && IsValidEntity(entity) && !strcmp(classname, "npc_nmrih_shamblerzombie", false))
		SDKHook(entity, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);
}

public void SDKHookCB_ZombieSpawnPost(int zombie)
{
	ShamblerToRunnerFromPosion(zombie, (Game_GetMod() == GameMod_Kid));
}

stock void Game_ShamblerToRunner(const GameMod mod)
{
	bool kid = mod == GameMod_Kid;
	int entity = MaxClients + 1;
	while((entity = FindEntityByClassname(entity, "npc_nmrih_shamblerzombie")) != -1) ShamblerToRunnerFromPosion(entity, kid);
}

stock int ShamblerToRunnerFromPosion(int zombie, bool isKid = false)
{
	if(!isKid)
	{
		AcceptEntityInput(zombie, "BecomeRunner", zombie, zombie);
		return zombie;
	}

	static float pos[3];
	GetEntPropVector(zombie, Prop_Send, "m_vecOrigin", pos);
#if SOURCEMOD_V_MAJOR > 1 || SOURCEMOD_V_MINOR > 9
	RemoveEntity(zombie);
#else
	AcceptEntityInput(zombie, "kill");
#endif

	if((zombie = CreateEntityByName("npc_nmrih_kidzombie")) != -1 && DispatchSpawn(zombie))
		TeleportEntity(zombie, pos, NULL_VECTOR, NULL_VECTOR);
	return zombie;
}

public void Event_RoundBegin(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable) GameInfo_ShowToAll();
}

stock void GameConfig_Enable(GameConf conf, bool on = true)
{
	switch(conf)
	{
		case GameConf_Realism:	sv_realism.BoolValue = on;
		case GameConf_Friendly:	mp_friendlyfire.BoolValue = on;
		case GameConf_Hardcore:	sv_hardcore_survival.BoolValue = on;
		case GameConf_Default:	GameConfig_Def();
	}
}

stock void GameConfig_Def()
{
	sv_realism.BoolValue = g_bSVRealism_default;
	mp_friendlyfire.BoolValue = g_bMpFriendlyFire_default;
	sv_hardcore_survival.BoolValue = g_bSVHardcore_default;
}

stock void GameMod_Enable(GameMod mod)
{
	switch(mod)
	{
		case GameMod_Runner:
		{
			sv_max_runner_chance.FloatValue = ov_runner_chance.FloatValue = 1.0;
			ov_runner_kid_chance.FloatValue = g_fRunner_kid_chance_default;
		}
		case GameMod_Kid:
			sv_max_runner_chance.FloatValue = ov_runner_chance.FloatValue = ov_runner_kid_chance.FloatValue = 1.0;
		case GameMod_Default: GameMod_Def();
	}
}

stock void GameMod_Def()
{
	sv_max_runner_chance.FloatValue = g_fMax_runner_chance_default;
	ov_runner_chance.FloatValue = g_fRunner_chance_default;
	ov_runner_kid_chance.FloatValue = g_fRunner_kid_chance_default;
}

stock void GameDiff_Enable(GameDif dif)
{
	switch(dif)
	{
		case GameDif_Classic:	sv_difficulty.SetString("classic");
		case GameDif_Casual:	sv_difficulty.SetString("casual");
		case GameDif_Nightmare:	sv_difficulty.SetString("nightmare");
		case GameDif_Default:	GameDiff_Def();
	}
}

stock void GameDiff_Def()
{
	sv_difficulty.SetString(g_cSVDifficult_default);
}

stock GameMod Game_GetMod()
{
	if(ov_runner_kid_chance.FloatValue == 1.0)
		return GameMod_Kid;

	if(sv_max_runner_chance.FloatValue == 1.0 || ov_runner_chance.FloatValue == 1.0)
		return GameMod_Runner;

	return GameMod_Default;
}

stock GameDif Game_GetDif()
{
	char dif[12];
	sv_difficulty.GetString(dif, sizeof(dif));

	if(!strcmp(dif, "classic"))
		return GameDif_Classic;

	if(!strcmp(dif, "casual"))
		return GameDif_Casual;

	if(!strcmp(dif, "nightmare"))
		return GameDif_Nightmare;

	return GameDif_Default;
}

public Action Cmd_InfoShow(int client, int args)
{
	if(!client || !IsClientInGame(client)) return Plugin_Handled;

	if(!g_bEnable)
		PrintToChat(client, "\x04%t\x01 %t", "ChatFlag", "ModDisable");
	else GameInfo_ShowToClient(client);

	return Plugin_Handled;
}

stock void GameInfo_ShowToAll()
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) GameInfo_ShowToClient(i);
}

stock void GameInfo_ShowToClient(const int client)
{
	PrintToChat(client, "\x04%t \x01%t \x04%t \x01%t\n\x04%t \x01%t \x04%t \x01%t\n\x04%t \x01%t",
		"ModFlag",		sModItem[view_as<int>(Game_GetMod())], client,
		"DifFlag",		sDifItem[view_as<int>(Game_GetDif())], client,
		"RealismFlag",	sv_realism.BoolValue ? "On" : "Off", client,
		"HardcoreFlag",	sv_hardcore_survival.BoolValue ? "On" : "Off", client,
		"FriendlyFlag",	mp_friendlyfire.BoolValue ? "On" : "Off", client);
}

public Action Cmd_MenuTop(int client, int args)
{
	if(client && IsClientInGame(client) && Game_CanEnable(client)) TopMenu_ShowToClient(client);

	return Plugin_Handled;
}

stock void TopMenu_ShowToClient(int client)
{
	if(!client || !IsClientInGame(client)) return;

	Menu menu = new Menu(MenuHandler_TopMenu);
	menu.SetTitle("%t", "TopMenuTitle");

	char buffer[128];
	FormatEx(buffer, sizeof(buffer), "%T", "TopMenuItemMod", client);
	menu.AddItem("0", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "TopMenuItemDifficult", client);
	menu.AddItem("1", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "TopMenuItemConfig", client);
	menu.AddItem("2", buffer);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_TopMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_Select:
		{
			if(!Game_CanEnable(client)) return 0;

			switch(param2)
			{
				case 0: ModMenu_ShowToClient(client);
				case 1: DifMenu_ShowToClient(client);
				case 2: ConfMenu_ShowToClient(client);
			}
		}
	}
	return 0;
}

stock bool Game_CanEnable(int client)
{
	if(!g_bEnable)
	{
		PrintToChat(client, "\x04%t\x01 %t", "ChatFlag", "ModDisable");
		return false;
	}

	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04%t\x01 %t", "ChatFlag", "VoteByAlive");
		return false;
	}

	return true;
}

stock void ModMenu_ShowToClient(int client)
{
	if(!client || !IsClientInGame(client)) return;

	Menu menu = new Menu(MenuHandler_ModMenu);
	menu.SetTitle("%t", "ModMenuTitle");

	char buffer[128];
	FormatEx(buffer, sizeof(buffer), "%T", "ModMenuItemRunner", client);
	menu.AddItem("0", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "ModMenuItemKid", client);
	menu.AddItem("1", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "ModMenuItemDefault", client);
	menu.AddItem("2", buffer);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ModMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	CloseHandle(menu);
		case MenuAction_Cancel:	if(param2 == MenuCancel_ExitBack) TopMenu_ShowToClient(client);
		case MenuAction_Select:	if(Game_CanEnable(client)) ModMenu_Vote(client, view_as<GameMod>(param2));
	}
	return 0;
}

stock bool TestVoteDelay(int client)
{
	int delay = CheckVoteDelay();
	if(!delay) return true;

	if (delay > 60)
		PrintToChat(client, "\x04%t\x01 %t", "ChatFlag", "VoteDelayMinutes", RoundToNearest(delay / 60.0));
	else PrintToChat(client, "\x04%t\x01 %t", "ChatFlag", "VoteDelaySeconds", delay);

	return false;
}

stock float GetVotePercent(int votes, int totalVotes)
{
#if SOURCEMOD_V_MAJOR > 1 || SOURCEMOD_V_MINOR > 9
	return votes/(totalVotes + 0.0);
#else
	return FloatDiv(float(votes), float(totalVotes));
#endif
}

stock void ModMenu_Vote(const int client, GameMod mod)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%t\x01 %t", "ChatFlag", "VoteInProgress");
		return;
	}

	if(!TestVoteDelay(client)) return;

	char buffer1[32], buffer2[32];
	Menu menu = new Menu(MenuHandler_ModVote, MENU_ACTIONS_ALL);
	GetClientName(client, buffer1, sizeof(buffer1));
	menu.SetTitle("%t", sModVote[view_as<int>(mod)], buffer1);

	FormatEx(buffer2, sizeof(buffer2), "%T", "Yes", client);
	FormatEx(buffer1, sizeof(buffer1), "%d", mod);
	menu.AddItem(buffer1, buffer2);

	FormatEx(buffer2, sizeof(buffer2), "%T", "No", client);
	FormatEx(buffer1, sizeof(buffer1), "no,%d", mod);
	menu.AddItem(buffer1, buffer2);

	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
	return;
}

public int MenuHandler_ModVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			FormatEx(item_yes, sizeof(item_yes), "%t", "On");
			FormatEx(item_no, sizeof(item_no), "%t", "Off");
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			if(!strcmp(display, item_no) || !strcmp(display, item_yes)) return RedrawMenuItem(display);
		}
		case MenuAction_VoteCancel: PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "NoVotesCast");
		case MenuAction_VoteEnd:
		{
			char item[64], display[64];
			int votes, totalVotes;
			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
			bool isNo = StrContains(item, "no") == 0;
			if(!isNo && param1 == 1) votes = totalVotes - votes;
			if((!isNo && FloatCompare(GetVotePercent(votes, totalVotes), VOTE_LIMIT) < 0 && !param1)
			|| (isNo && param1 == 1))
			{
				PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFailed");
				return 0;
			}

			GameMod mod;
			if(isNo)
			{
				char item_no[2][32];
				ExplodeString(item, ",", item_no, 2, 32);
				if(!strcmp(item_no[0], "no"))
					mod = view_as<GameMod>(StringToInt(item_no[1]));
				else mod = view_as<GameMod>(StringToInt(item_no[0]));
			}
			else mod = view_as<GameMod>(StringToInt(item));
			GameMod_Enable(mod);
			Game_ShamblerToRunner(mod);
			PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFinish");
		}
	}
	return 0;
}

stock void DifMenu_ShowToClient(const int client)
{
	char buffer[128];
	Menu menu = new Menu(MenuHandler_DifMenu);
	menu.SetTitle("%t", "DifMenuTitle");
	FormatEx(buffer, sizeof(buffer), "%T", "DifMenuItemClassic", client);
	menu.AddItem("0", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "DifMenuItemCasual", client);
	menu.AddItem("1", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "DifMenuItemNightmare", client);
	menu.AddItem("2", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "DifMenuItemDefault", client);
	menu.AddItem("3", buffer);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_DifMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	CloseHandle(menu);
		case MenuAction_Cancel:	if(param2 == MenuCancel_ExitBack) TopMenu_ShowToClient(client);
		case MenuAction_Select:	if(Game_CanEnable(client)) DifMenu_Vote(client, view_as<GameDif>(param2));
	}
	return 0;
}

stock void DifMenu_Vote(const int client, GameDif dif)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%t\x01 %t", "ChatFlag", "VoteInProgress");
		return;
	}

	if(!TestVoteDelay(client)) return;

	char buffer1[32], buffer2[32];
	Menu menu = new Menu(MenuHandler_DifVote, MENU_ACTIONS_ALL);

	GetClientName(client, buffer1, sizeof(buffer1));
	menu.SetTitle("%t", sDifVote[view_as<int>(dif)], buffer1);

	FormatEx(buffer2, sizeof(buffer2), "%T", "Yes", client);
	FormatEx(buffer1, sizeof(buffer1), "%d", dif);
	menu.AddItem(buffer1, buffer2);

	FormatEx(buffer2, sizeof(buffer2), "%T", "No", client);
	FormatEx(buffer1, sizeof(buffer1), "no,%d", dif);
	menu.AddItem(buffer1, buffer2);

	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
}

public int MenuHandler_DifVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			FormatEx(item_yes, sizeof(item_yes), "%t", "On");
			FormatEx(item_no, sizeof(item_no), "%t", "Off");
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			if(!strcmp(display, item_no) || !strcmp(display, item_yes)) return RedrawMenuItem(display);
		}
		case MenuAction_VoteCancel: PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "NoVotesCast");
		case MenuAction_VoteEnd:
		{
			char item[64], display[64];
			int votes, totalVotes;
			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
			bool isNo = StrContains(item, "no") == 0;
			if(!isNo && param1 == 1) votes = totalVotes - votes;
			if((!isNo && FloatCompare(GetVotePercent(votes, totalVotes),VOTE_LIMIT) < 0 && param1 == 0)
			|| (isNo && param1 == 1))
			{
				PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFailed");
				return 0;
			}

			GameDif dif;
			if(isNo)
			{
				char item_no[2][32];
				ExplodeString(item, ",", item_no, 2, 32);
				dif = view_as<GameDif>(StringToInt(item_no[!strcmp(item_no[0], "no") ? 1 : 0]));
			}
			else dif = view_as<GameDif>(StringToInt(item));
			GameDiff_Enable(dif);
			PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFinish");
		}
	}
	return 0;
}

stock void ConfMenu_ShowToClient(const int client)
{
	char buffer[128];
	Menu menu = new Menu(MenuHandler_ConfMenu);
	menu.SetTitle("%t", "ConfMenuTitle");
	FormatEx(buffer, sizeof(buffer), "%T", "ConfMenuItemRealism", client);
	menu.AddItem("0", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "ConfMenuItemFriendly", client);
	menu.AddItem("1", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "ConfMenuItemHardcore", client);
	menu.AddItem("2", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "ConfMenuItemDefault", client);
	menu.AddItem("3", buffer);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ConfMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	CloseHandle(menu);
		case MenuAction_Cancel:	if(param2 == MenuCancel_ExitBack) TopMenu_ShowToClient(client);
		case MenuAction_Select:	if(Game_CanEnable(client)) ConfMenu_Vote(client, view_as<GameConf>(param2));
	}
	return 0;
}

stock void ConfMenu_Vote(const int client, GameConf conf)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}

	if(!TestVoteDelay(client)) return;

	char buffer1[32], buffer2[32];
	GetClientName(client, buffer1, sizeof(buffer1));
	Menu menu = new Menu(MenuHandler_ConfVote, MENU_ACTIONS_ALL);
	menu.SetTitle("%t", sConfVote[view_as<int>(conf)], buffer1);

	FormatEx(buffer2, sizeof(buffer2), "%T", "On", client);
	FormatEx(buffer1, sizeof(buffer1), "%d", conf);
	menu.AddItem(buffer1, buffer2);

	FormatEx(buffer2, sizeof(buffer2), "%T", "Off", client);
	FormatEx(buffer1, sizeof(buffer1), "Off,%d", conf);
	menu.AddItem(buffer1, buffer2);

	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
	return;
}

public int MenuHandler_ConfVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			FormatEx(item_yes, sizeof(item_yes), "%T", "On", param1);
			FormatEx(item_no, sizeof(item_no), "%T", "Off", param1);
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			if(!strcmp(display, item_no) || !strcmp(display, item_yes)) return RedrawMenuItem(display);
		}
		case MenuAction_VoteCancel: PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "NoVotesCast");
		case MenuAction_VoteEnd:
		{
			char item[64];
			int votes, totalVotes;
			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item));
			bool isOff = StrContains(item, "Off") == 0;
			GameConf conf;
			if(isOff)
			{
				char item_no[2][32];
				ExplodeString(item, ",", item_no, 2, 32);
				conf = view_as<GameConf>(StringToInt(item_no[!strcmp(item_no[0], "Off") ? 1 : 0]));
			}
			else conf = view_as<GameConf>(StringToInt(item));
			if(!isOff && param1 == 1) votes = totalVotes - votes;
			if((!isOff && FloatCompare(GetVotePercent(votes, totalVotes), VOTE_LIMIT) < 0 && !param1)
			|| (isOff && param1 == 1))
			{
				if(conf == GameConf_Default) PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFailed");
				else
				{
					GameConfig_Enable(conf, false);
					PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFinishToOff");
				}
				return 0;
			}

			GameConfig_Enable(conf, true);
			PrintToChatAll("\x04%t\x01 %t", "ChatFlag", conf == GameConf_Default ? "VoteFinish" : "VoteFinishToOn");
		}
	}
	return 0;
}