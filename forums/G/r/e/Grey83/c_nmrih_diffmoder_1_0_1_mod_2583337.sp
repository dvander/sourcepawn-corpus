#pragma newdecls required
#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>

static const float	VOTE_LIMIT			= 0.6;
static const int	MENUDISPLAY_TIME	= 20;
static const char sModVote[][] = {
	"ModMenuRunerVote",
	"ModMenuKidVote",
	"ModMenuDefVote"
};
static const char sDifVote[][] =
{
	"DifMenuClassicVote",
	"DifMenuClassicCustomVote",
	"DifMenuCasualVote",
	"DifMenuNightmareVote",
	"DifMenuNightmareCustomVote",
	"DifMenuNightmareInfinityVote",
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
	"DifMenuItemClassicCustom",
	"DifMenuItemCasual",
	"DifMenuItemNightmare",
	"DifMenuItemNightmareCustom",
	"DifMenuItemNightmareInfinity",
	"DifMenuItemDefault"
};

enum GameMod{
	GameMod_Runner,
	GameMod_Kid,
	GameMod_Default
}

enum GameDif{
	GameDif_Classic,
	GameDif_ClassicCustom,
	GameDif_Casual,
	GameDif_Nightmare,
	GameDif_NightmareCustom,
	GameDif_NightmareInfinity,
	GameDif_Default
}

enum GameConf{
	GameConf_Realism,
	GameConf_Friendly,
	GameConf_Hardcore,
	GameConf_Default
}

ConVar sv_max_runner_chance,
	ov_runner_chance,
	ov_runner_kid_chance,
	sv_realism, mp_friendlyfire,
	sv_hardcore_survival,
	sv_difficulty;
bool g_bSVRealism_default,
	g_bMpFriendlyFire_default,
	g_bSVHardcore_default, g_bEnable;
float g_fMax_runner_chance_default,
	g_fRunner_chance_default,
	g_fRunner_kid_chance_default;
char g_cSVDifficult_default[32];

public Plugin myinfo =
{
	name		= "[NMRiH] Difficult Moder",
	author		= "Mostten (rewritten by Grey83)",
	description	= "Allow player to enable the change difficult and mod by ballot.",
	version		= "1.0.1_mod",
	url			= "https://forums.alliedmods.net/showthread.php?t=301322"
}

public void OnPluginStart()
{
	LoadTranslations("nmrih.diffmoder.phrases");
	(sv_max_runner_chance = FindConVar("sv_max_runner_chance")).AddChangeHook(OnConVarChanged);
	g_fMax_runner_chance_default = sv_max_runner_chance.FloatValue;
	(ov_runner_chance = FindConVar("ov_runner_chance")).AddChangeHook(OnConVarChanged);
	g_fRunner_chance_default = ov_runner_chance.FloatValue;
	(ov_runner_kid_chance = FindConVar("ov_runner_kid_chance")).AddChangeHook(OnConVarChanged);
	g_fRunner_kid_chance_default = ov_runner_kid_chance.FloatValue;
	(sv_realism = FindConVar("sv_realism")).AddChangeHook(OnConVarChanged);
	g_bSVRealism_default = sv_realism.BoolValue;
	(mp_friendlyfire = FindConVar("mp_friendlyfire")).AddChangeHook(OnConVarChanged);
	g_bMpFriendlyFire_default = mp_friendlyfire.BoolValue;
	(sv_hardcore_survival = FindConVar("sv_hardcore_survival")).AddChangeHook(OnConVarChanged);
	g_bSVHardcore_default = sv_hardcore_survival.BoolValue;
	(sv_difficulty = FindConVar("sv_difficulty")).AddChangeHook(OnConVarChanged);
	sv_difficulty.GetString(g_cSVDifficult_default, sizeof(g_cSVDifficult_default));

	ConVar CVar;
	(CVar = CreateConVar("nmrih_diffmoder", "1", "Enable/Disable plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(OnConVarChanged_Enable);
	g_bEnable = CVar.BoolValue;

	//Reg Cmd
	RegConsoleCmd("sm_dif", Cmd_MenuTop);
	RegConsoleCmd("sm_difshow", Cmd_InfoShow);

	//event
	HookEvent("nmrih_round_begin", Event_RoundBegin);
}

public void OnConVarChanged(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	GameMod mod = Game_GetMod();
	GameDif dif = Game_GetDif();

	if(CVar == sv_max_runner_chance)		GameMod_Enable(mod);
	else if(CVar == ov_runner_chance)		GameMod_Enable(mod);
	else if(CVar == ov_runner_kid_chance)	GameMod_Enable(mod);
	else if(CVar == sv_difficulty)			GameDiff_Enable(dif);
/*	else if(CVar == sv_realism)				sv_realism.BoolValue = sv_realism.BoolValue;
	else if(CVar == mp_friendlyfire)		mp_friendlyfire.BoolValue = mp_friendlyfire.BoolValue;
	else if(CVar == sv_hardcore_survival)	sv_hardcore_survival.BoolValue = sv_hardcore_survival.BoolValue;*/
}

public void OnConVarChanged_Enable(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	g_bEnable = CVar.BoolValue;
	if(g_bEnable) HookEvent("nmrih_round_begin", Event_RoundBegin);
	else UnhookEvent("nmrih_round_begin", Event_RoundBegin);
}

void ConVars_InitDefault()
{
	GameMod_Def();
	GameDiff_Def();
	GameConfig_Def();
}

public void OnConfigsExecuted()
{
	ConVars_InitDefault();
}

public void OnPluginEnd()
{
	ConVars_InitDefault();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!g_bEnable) return;

	if((entity > MaxClients) && IsValidEntity(entity)
	&& StrEqual(classname, "npc_nmrih_shamblerzombie", false))
		SDKHook(entity, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);
}

public void OnEntityDestroyed(int entity)
{
	if(g_bEnable && IsValidShamblerzombie(entity)) SDKUnhook(entity, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);
}

bool IsValidShamblerzombie(int zombie)
{
	if((zombie <= MaxClients) || !IsValidEntity(zombie)) return false;

	char classname[32];
	GetEntityClassname(zombie, classname, sizeof(classname));
	return StrEqual(classname, "npc_nmrih_shamblerzombie", false);
}

public void SDKHookCB_ZombieSpawnPost(int zombie)
{
	if(!g_bEnable || !IsValidEntity(zombie) || !IsValidShamblerzombie(zombie))
		SDKUnhook(zombie, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);

	float orgin[3];
	GetEntPropVector(zombie, Prop_Send, "m_vecOrigin", orgin);
	switch(Game_GetMod())
	{
		case GameMod_Runner:ShamblerToRunnerFromPosion(zombie, orgin);
		case GameMod_Kid:	ShamblerToRunnerFromPosion(zombie, orgin, true);
	}
	SDKUnhook(zombie, SDKHook_SpawnPost, SDKHookCB_ZombieSpawnPost);
}

int ShamblerToRunnerFromPosion(int shambler, float[3] pos, bool isKid = false)
{
	AcceptEntityInput(shambler, "kill");
	RemoveEdict(shambler);
	return FastZombie_Create(pos, isKid);
}

void Game_ShamblerToRunner(const GameMod mod)
{
	int MaxEnt = GetMaxEntities();
	for(int zombie = MaxClients + 1; zombie <= MaxEnt; zombie++)
	{
		if(!IsValidShamblerzombie(zombie)) continue;

		float orgin[3];
		GetEntPropVector(zombie, Prop_Send, "m_vecOrigin", orgin);
		switch(mod)
		{
			case GameMod_Runner:ShamblerToRunnerFromPosion(zombie, orgin);
			case GameMod_Kid:	ShamblerToRunnerFromPosion(zombie, orgin, true);
		}
	}
}

int FastZombie_Create(float orgin[3], bool isKid = false)
{
	int zombie = -1;
	zombie = CreateEntityByName(isKid ? "npc_nmrih_kidzombie" : "npc_nmrih_turnedzombie");
	if(!IsValidEntity(zombie)) return -1;

	if(DispatchSpawn(zombie)) TeleportEntity(zombie, orgin, NULL_VECTOR, NULL_VECTOR);

	return zombie;
}

public void Event_RoundBegin(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bEnable) GameInfo_ShowToAll();
	else UnhookEvent("nmrih_round_begin", Event_RoundBegin);
}

void GameConfig_Enable(GameConf conf, bool on = true)
{
	switch(conf)
	{
		case GameConf_Realism:	sv_realism.BoolValue = on;
		case GameConf_Friendly:	mp_friendlyfire.BoolValue = on;
		case GameConf_Hardcore:	sv_hardcore_survival.BoolValue = on;
		case GameConf_Default:	GameConfig_Def();
	}
}

void GameConfig_Def()
{
	sv_realism.BoolValue = g_bSVRealism_default;
	mp_friendlyfire.BoolValue = g_bMpFriendlyFire_default;
	sv_hardcore_survival.BoolValue = g_bSVHardcore_default;
}

void GameMod_Enable(GameMod mod)
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

void GameMod_Def()
{
	sv_max_runner_chance.FloatValue = g_fMax_runner_chance_default;
	ov_runner_chance.FloatValue = g_fRunner_chance_default;
	ov_runner_kid_chance.FloatValue = g_fRunner_kid_chance_default;
}

void GameDiff_Enable(GameDif dif)
{
	switch(dif)
	{
		case GameDif_Classic:			sv_difficulty.SetString("classic");
		case GameDif_ClassicCustom:		sv_difficulty.SetString("classic_custom");
		case GameDif_Casual:			sv_difficulty.SetString("casual");
		case GameDif_Nightmare:			sv_difficulty.SetString("nightmare");
		case GameDif_NightmareCustom:	sv_difficulty.SetString("nightmare_custom");
		case GameDif_NightmareInfinity:	sv_difficulty.SetString("nightmare_Infinity");
		case GameDif_Default:			GameDiff_Def();
	}
}

void GameDiff_Def()
{
	sv_difficulty.SetString(g_cSVDifficult_default);
}

GameMod Game_GetMod()
{
	if(ov_runner_kid_chance.FloatValue == 1.0)
		return GameMod_Kid;
	else if(sv_max_runner_chance.FloatValue == 1.0 || ov_runner_chance.FloatValue == 1.0)
		return GameMod_Runner;

	return GameMod_Default;
}

GameDif Game_GetDif()
{
	char dif[32];
	sv_difficulty.GetString(dif, sizeof(dif));
	if(StrEqual(dif, "classic"))					return GameDif_Classic;
	if(StrEqual(dif, "classic_custom"))				return GameDif_ClassicCustom;
	else if(StrEqual(dif, "casual"))				return GameDif_Casual;
	else if(StrEqual(dif, "nightmare"))				return GameDif_Nightmare;
	else if(StrEqual(dif, "nightmare_custom"))		return GameDif_NightmareCustom;
	else if(StrEqual(dif, "nightmare_Infinity"))	return GameDif_NightmareInfinity;

	return GameDif_Default;
}

public Action Cmd_InfoShow(int client, int args)
{
	if(!g_bEnable) PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "ModDisable", client);
	else GameInfo_ShowToClient(client);

	return Plugin_Handled;
}

void GameInfo_ShowToAll()
{
	for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i)) GameInfo_ShowToClient(i);
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && !IsClientSourceTV(client);
}

void GameInfo_ShowToClient(const int client)
{
	PrintToChat(client, "\x04%T \x01%T \x04%T \x01%T\n\x04%T \x01%T \x04%T \x01%T\n\x04%T \x01%T",
		"ModFlag", client,		sModItem[view_as<int>(Game_GetMod())], client,
		"DifFlag", client,		sDifItem[view_as<int>(Game_GetDif())], client,
		"RealismFlag", client,	sv_realism.BoolValue ? "On" : "Off", client,
		"HardcoreFlag", client,	sv_hardcore_survival.BoolValue ? "On" : "Off", client,
		"FriendlyFlag", client,	mp_friendlyfire.BoolValue ? "On" : "Off", client);
}

public Action Cmd_MenuTop(int client, int args)
{
	if(Game_CanEnable(client)) TopMenu_ShowToClient(client);

	return Plugin_Handled;
}

void TopMenu_ShowToClient(const int client)
{
	char buffer[128];
	Menu menu = new Menu(MenuHandler_TopMenu);
	menu.SetTitle("%T", "TopMenuTitle", client);
	Format(buffer, sizeof(buffer), "%T", "TopMenuItemMod", client);
	menu.AddItem("0", buffer);
	Format(buffer, sizeof(buffer), "%T", "TopMenuItemDifficult", client);
	menu.AddItem("1", buffer);
	Format(buffer, sizeof(buffer), "%T", "TopMenuItemConfig", client);
	menu.AddItem("2", buffer);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_TopMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
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

bool Game_CanEnable(const int client)
{
	if(!g_bEnable)
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "ModDisable", client);
		return false;
	}
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteByAlive", client);
		return false;
	}
	return true;
}

void ModMenu_ShowToClient(const int client)
{
	char buffer[128];
	Menu menu = new Menu(MenuHandler_ModMenu);
	menu.SetTitle("%T", "ModMenuTitle", client);
	Format(buffer, sizeof(buffer), "%T", "ModMenuItemRunner", client);
	menu.AddItem("0", buffer);
	Format(buffer, sizeof(buffer), "%T", "ModMenuItemKid", client);
	menu.AddItem("1", buffer);
	Format(buffer, sizeof(buffer), "%T", "ModMenuItemDefault", client);
	menu.AddItem("2", buffer);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ModMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	delete menu;
		case MenuAction_Cancel:	TopMenu_ShowToClient(client);
		case MenuAction_Select:	if(Game_CanEnable(client)) ModMenu_Vote(client, view_as<GameMod>(param2));
	}
	return 0;
}

bool TestVoteDelay(int client)
{
	int delay = CheckVoteDelay();
	if(!delay) return true;

	if (delay > 60) PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteDelayMinutes", client, RoundToNearest(delay / 60.0));
	else PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteDelaySeconds", client, delay);
	return false;
}

float GetVotePercent(int votes, int totalVotes)
{
	return FloatDiv(float(votes), float(totalVotes));
}

void ModMenu_Vote(const int client, GameMod mod)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}
	if(!TestVoteDelay(client)) return;

	char item_yes[32], item_no[32], name[32], item_yes_flag[32], item_no_flag[32];
	GetClientName(client, name, sizeof(name));
	Format(item_yes, sizeof(item_yes), "%T", "Yes", client);
	Format(item_no, sizeof(item_no), "%T", "No", client);
	Format(item_yes_flag, sizeof(item_yes_flag), "%d", mod);
	Format(item_no_flag, sizeof(item_no_flag), "no,%d", mod);
	Menu menu = new Menu(MenuHandler_ModVote, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", sModVote[view_as<int>(mod)], client, name);
	menu.AddItem(item_yes_flag, item_yes);
	menu.AddItem(item_no_flag, item_no);
	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
	return;
}

public int MenuHandler_ModVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			Format(item_yes, sizeof(item_yes), "%t", "On");
			Format(item_no, sizeof(item_no), "%t", "Off");
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
				if(StrEqual(item_no[0], "no"))
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

void DifMenu_ShowToClient(const int client)
{
	char buffer[128];
	Menu menu = new Menu(MenuHandler_DifMenu);
	menu.SetTitle("%T", "DifMenuTitle", client);
	Format(buffer, sizeof(buffer), "%T", "DifMenuItemClassic", client);
	menu.AddItem("0", buffer);
	Format(buffer, sizeof(buffer), "%T", "DifMenuItemClassicCustom", client);
	menu.AddItem("1", buffer);
	Format(buffer, sizeof(buffer), "%T", "DifMenuItemCasual", client);
	menu.AddItem("2", buffer);
	Format(buffer, sizeof(buffer), "%T", "DifMenuItemNightmare", client);
	menu.AddItem("3", buffer);
	Format(buffer, sizeof(buffer), "%T", "DifMenuItemNightmareCustom", client);
	menu.AddItem("4", buffer);
	Format(buffer, sizeof(buffer), "%T", "DifMenuItemNightmareInfinity", client);
	menu.AddItem("5", buffer);
	Format(buffer, sizeof(buffer), "%T", "DifMenuItemDefault", client);
	menu.AddItem("6", buffer);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_DifMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	delete menu;
		case MenuAction_Cancel:	TopMenu_ShowToClient(client);
		case MenuAction_Select:	if(Game_CanEnable(client)) DifMenu_Vote(client, view_as<GameDif>(param2));
	}
	return 0;
}

void DifMenu_Vote(const int client, GameDif dif)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}
	if(!TestVoteDelay(client)) return;

	char item_yes[32], item_no[32], name[32], item_yes_flag[32], item_no_flag[32];
	GetClientName(client, name, sizeof(name));
	Format(item_yes, sizeof(item_yes), "%T", "Yes", client);
	Format(item_no, sizeof(item_no), "%T", "No", client);
	Format(item_yes_flag, sizeof(item_yes_flag), "%d", dif);
	Format(item_no_flag, sizeof(item_no_flag), "no,%d", dif);
	Menu menu = new Menu(MenuHandler_DifVote, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", sDifVote[view_as<int>(dif)], client, name);
	menu.AddItem(item_yes_flag, item_yes);
	menu.AddItem(item_no_flag, item_no);
	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
}

public int MenuHandler_DifVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			Format(item_yes, sizeof(item_yes), "%t", "On");
			Format(item_no, sizeof(item_no), "%t", "Off");
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
				dif = view_as<GameDif>(StringToInt(item_no[StrEqual(item_no[0], "no") ? 1 : 0]));
			}
			else dif = view_as<GameDif>(StringToInt(item));
			GameDiff_Enable(dif);
			PrintToChatAll("\x04%t\x01 %t", "ChatFlag", "VoteFinish");
		}
	}
	return 0;
}

void ConfMenu_ShowToClient(const int client)
{
	char buffer[128];
	Menu menu = new Menu(MenuHandler_ConfMenu);
	menu.SetTitle("%T", "ConfMenuTitle", client);
	Format(buffer, sizeof(buffer), "%T", "ConfMenuItemRealism", client);
	menu.AddItem("0", buffer);
	Format(buffer, sizeof(buffer), "%T", "ConfMenuItemFriendly", client);
	menu.AddItem("1", buffer);
	Format(buffer, sizeof(buffer), "%T", "ConfMenuItemHardcore", client);
	menu.AddItem("2", buffer);
	Format(buffer, sizeof(buffer), "%T", "ConfMenuItemDefault", client);
	menu.AddItem("3", buffer);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ConfMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:	delete menu;
		case MenuAction_Cancel:	TopMenu_ShowToClient(client);
		case MenuAction_Select:	if(Game_CanEnable(client)) ConfMenu_Vote(client, view_as<GameConf>(param2));
	}
	return 0;
}

void ConfMenu_Vote(const int client, GameConf conf)
{
	if(!Game_CanEnable(client)) return;

	if(IsVoteInProgress())
	{
		PrintToChat(client, "\x04%T\x01 %T", "ChatFlag", client, "VoteInProgress", client);
		return;
	}
	if(!TestVoteDelay(client)) return;

	char item_yes[32], item_no[32], name[32], item_yes_flag[32], item_no_flag[32];
	GetClientName(client, name, sizeof(name));
	Format(item_yes, sizeof(item_yes), "%T", "On", client);
	Format(item_no, sizeof(item_no), "%T", "Off", client);
	Format(item_yes_flag, sizeof(item_yes_flag), "%d", conf);
	Format(item_no_flag, sizeof(item_no_flag), "Off,%d", conf);
	Menu menu = new Menu(MenuHandler_ConfVote, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", sConfVote[view_as<int>(conf)], client, name);
	menu.AddItem(item_yes_flag, item_yes);
	menu.AddItem(item_no_flag, item_no);
	menu.DisplayVoteToAll(MENUDISPLAY_TIME);
	return;
}

public int MenuHandler_ConfVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action){
		case MenuAction_End: delete menu;
		case MenuAction_DisplayItem:
		{
			char display[64], item_yes[32], item_no[32];
			Format(item_yes, sizeof(item_yes), "%T", "On", param1);
			Format(item_no, sizeof(item_no), "%T", "Off", param1);
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
				conf = view_as<GameConf>(StringToInt(item_no[StrEqual(item_no[0], "Off") ? 1 : 0]));
			}
			else conf = view_as<GameConf>(StringToInt(item));
			if(!isOff && param1 == 1) votes = totalVotes - votes;
			if((!isOff && FloatCompare(GetVotePercent(votes, totalVotes),VOTE_LIMIT) < 0 && !param1)
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