/*	
 *	============================================================================
 *	
 *	[TF2] Custom Boss Spawner
 *	Alliedmodders: https://forums.alliedmods.net/showthread.php?t=218119
 *	Current Version: 5.1.1
 *
 *	Written by Tak (Chaosxk)
 *	https://forums.alliedmods.net/member.php?u=87026
 *
 *	This plugin is FREE and can be distributed to anyone.  
 *	If you have paid for this plugin, get your money back.
 *	
Version Log:
~ v.5.1.1
	- Removed the HUD Timer
~ v.5.1
	- Properly use FindConvar instead of ServerCommand to execute convars ("tf_eyeball_boss_lifetime" and "tf_merasmus_lifetime").
	- Changed a bad attempt at managing convars ("tf_eyeball_boss_lifetime" and "tf_merasmus_lifetime"), plugin will now instead just set those values to 9999999 and default values when unloaded.
	- No longer caches values from convars (convars.IntValue is already cached)
	- No longer need to unhook sdkhook on client disconnect
	- Fixed a bug where round start would make the next boss timer to disappear
	- Fixed a bug where the health bar text would only work on the first map and no longer works after a map change
	- Fixed a bug where plugin should be disabled and still blocked some halloween notications/sounds
	- Fixed a bug where boss spawned from other plugin would have it's damaged changed by this plugin
	- Fixed a bug where monoculus would switch between models
	- Fixed a bug where merasmus would switch between skins/colors
	- Fixed a bug where healthbar type convar set to 0 or 2 might break the health bar tracking of bosses
	- Fixed some translation code not correctly displaying right language
	- Fixed a Call stack trace error on RemoveExistingBoss()
	- Fixed bug with total votes would be wrong if too many people disconnected
	- FINALLY fixed a bug where boss would need to be hit 1 MORE time after it hit 0 health. (People should be able to get achievement now but that is untested.)
	- Fixed issue with healthbar/hud having issue tracking when 2 or more bosses were active at the same time
	- Fixed memory leak with stringmap in boss configuration file when changing maps
	- Added a death event chat notification of who killed what boss
	- Plugin now uses a custom methodmap to create a data storage specifically for bosses
	- Plugin now requires bossspawner.inc to compile
	- Gnome key is removed as it was annoying to maintain/keep track of, plugin will just remove the mini-skeletons on spawn
	- Changed warhammer boss from chaos_bosspack config "WeaponModel" to Invisible
	- added !client check for command callback so it doesn't error out on console
	- Changed ShowHudText to ShowSyncHudText to prevent HUD display conflict with other plugins
	- Will now remove a command listener when a boss is removed during map changes
	- Countdown timers now uses GetEngineTime instead of using variables to track time
	- Bosses health are no longer increased by *10 and health bar *0.9 (Did this for merasmus but seems like merasmus bug was fixed by valve)
	- Improved caching of bosses data into memory
	- Improved timer that keeps track of boss lifetime
	- Updated some syntax and code clean up

Known bugs: 
	- Fixed sync hud, flickering between health and countdown
	- Fix glow name from random to entity number
	- small skeletons still spawning
	- Need to fix the vote percentage being wrong
	- Need to fix translation files for vote ended
	- multiple sounds played on death
	- There seems to be an engine limit of how many skeletons can spawn which is 30, spawning more will cause #skeletons-30 to die
	- Can not set model on monoculus, plugin will error out if done so
	- Botkiller and Ghost can not be resized
	- When tf_skeleton with a hat attacks you while standing still, his hat model may freeze until he starts moving
	- eyeball_boss can die from collision from a payload cart, most of time in air so it doesn't matter too much
	- Hat size and offset does not change if player manually spawns a boss with a different size from the config (e.g !horseman 1000 5 1 : Horseman size is 5 but default size in boss config is 1, if this boss has a hat the hat won't resize)
 *	============================================================================
 */
#pragma semicolon 1
#include <morecolors>
#include <sdktools>
#include <sourcemod>
#include <sdkhooks>
#include <bossspawner>

#pragma newdecls required

#define PLUGIN_VERSION "5.0.2"
#define INTRO_SND	"ui/halloween_boss_summoned_fx.wav"
#define DEATH_SND	"ui/halloween_boss_defeated_fx.wav"
#define HORSEMAN	"headless_hatman"
#define MONOCULUS	"eyeball_boss"
#define MERASMUS	"merasmus"
#define SKELETON	"tf_zombie"
#define SNULL 		"\0"

#define EF_NODRAW				(1 << 5)
#define EF_BONEMERGE            (1 << 0)
#define EF_NOSHADOW             (1 << 4)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_PARENT_ANIMATES      (1 << 9)

Handle g_hTimer, g_hHudSync;
ArrayList g_iArray, g_iArrayData;
ConVar g_cMode, g_cInterval, g_cMinplayers, g_cHealthbar, g_cVote;
//ConVar g_cHudx, g_cHudy;
int g_iEyeball_Default, g_iMerasmus_Default, g_iBossCount, g_iTotalVotes, g_iIndex, g_iIndexCmd, g_iArgIndex, g_iSaveIndex, g_iAttacker;
int g_iBossEntity = -1, g_iHealthbar = -1;
float g_fPos[3], g_fkPos[3];
bool g_bEnabled, g_bSlayCommand;

int g_iVotes[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2] Custom Boss Spawner",
	author = "Tak (chaosxk)",
	description = "A customizable boss spawner",
	version = PLUGIN_VERSION,
	url = "https://github.com/xcalvinsz/bossspawner"
}

public void OnPluginStart()
{
	CreateConVar("sm_boss_version", PLUGIN_VERSION, "Custom Boss Spawner Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cMode = CreateConVar("sm_boss_mode", "1", "Spawn mode for auto-spawning [0:Random | 1:Ordered | 2:Vote]");
	g_cInterval = CreateConVar("sm_boss_interval", "300", "How many seconds until the next boss spawns?");
	g_cMinplayers = CreateConVar("sm_boss_minplayers", "12", "How many players are needed before enabling auto-spawning?");
//	g_cHudx = CreateConVar("sm_boss_hud_x", "0.05", "X-Coordinate of the HUD display.");
//	g_cHudy = CreateConVar("sm_boss_hud_y", "0.05", "Y-Coordinate of the HUD display");
	g_cHealthbar = CreateConVar("sm_healthbar_type", "3", "What kind of healthbar to display? [0:None | 1:HUDBar | 2:HUDText | 3:Both]");
	g_cVote = CreateConVar("sm_boss_vote", "50", "How many people are needed to type !voteboss before a vote starts to spawn a boss? [0-100] as percentage");
	
	RegAdminCmd("sm_getcoords", Command_GetCoordinates, ADMFLAG_GENERIC, "Get the Coordinates of your cursor.");
	RegAdminCmd("sm_forceboss", Command_ForceBossSpawn, ADMFLAG_GENERIC, "Forces a auto-spawning boss to spawn early.");
	RegAdminCmd("sm_fb", Command_ForceBossSpawn, ADMFLAG_GENERIC, "Forces a auto-spawning boss to spawn early.");
	RegAdminCmd("sm_spawnboss", Command_SpawnMenu, ADMFLAG_GENERIC, "Opens a menu to spawn a boss.");
	RegAdminCmd("sm_sb", Command_SpawnMenu, ADMFLAG_GENERIC, "Opens a menu to spawn a boss.");
	RegAdminCmd("sm_slayboss", Command_SlayBoss, ADMFLAG_GENERIC, "Slay all active bosses on map.");
	RegAdminCmd("sm_forcevote", Command_ForceVote, ADMFLAG_GENERIC, "Start a vote, this is the same as !forceboss if sm_boss_mode was set to 2");
	
	RegConsoleCmd("sm_voteboss", Command_BossVote, "Start a vote, needs minimum amount of people to run this command to start a vote.  Follows sm_boss_vote");
	
	HookEvent("teamplay_round_start", Event_Round_Start, EventHookMode_Pre);
	HookEvent("pumpkin_lord_summoned", Event_Blocked, EventHookMode_Pre);
	HookEvent("eyeball_boss_summoned", Event_Blocked, EventHookMode_Pre);
	HookEvent("merasmus_summoned", Event_Blocked, EventHookMode_Pre);
	HookEvent("pumpkin_lord_killed", Event_Blocked, EventHookMode_Pre);
	HookEvent("eyeball_boss_killed", Event_Blocked, EventHookMode_Pre);
	HookEvent("merasmus_killed", Event_Blocked, EventHookMode_Pre);
	HookEvent("merasmus_escape_warning", Event_Blocked, EventHookMode_Pre);
	HookEvent("eyeball_boss_escape_imminent", Event_Blocked, EventHookMode_Pre);
	
	HookUserMessage(GetUserMessageId("SayText2"), SayText2, true);
	
	g_iArray = new ArrayList();
	g_iArrayData = new ArrayList();
	
	CreateTimer(0.5, Timer_Healthbar, _, TIMER_REPEAT);
	g_hHudSync = CreateHudSynchronizer();
	
	g_iEyeball_Default = FindConVar("tf_eyeball_boss_lifetime").IntValue;
	g_iMerasmus_Default = FindConVar("tf_merasmus_lifetime").IntValue;
	
	g_cMinplayers.AddChangeHook(OnConvarChanged);
	g_cInterval.AddChangeHook(OnConvarChanged);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	
	LoadTranslations("common.phrases");
	LoadTranslations("bossspawner.phrases");
	
	AutoExecConfig(false, "bossspawner");
}

public void OnPluginEnd()
{
	//When plugin is unloaded, remove any bosses on map and set the monoculus/merasmus convars back to their default values
	RemoveExistingBoss();
	SetEyeballLifetime(g_iEyeball_Default);
	SetMerasmusLifetime(g_iMerasmus_Default);
}

public void OnConfigsExecuted() 
{	
	SetupMapConfigs("bossspawner_maps.cfg");
	SetupBossConfigs("bossspawner_boss.cfg");
	SetupDownloads("bossspawner_downloads.cfg");
	
	if (!g_bEnabled)
		return;
		
	g_iHealthbar = FindHealthBar();
	PrecacheSound("items/cart_explode.wav");
}

public void OnMapEnd()
{
	delete g_hTimer;
	RemoveExistingBoss();
}

public void OnClientPostAdminCheck(int client)
{
	if (GetClientCount(true) == g_cMinplayers.IntValue)
		if(g_iBossCount == 0)
			ResetTimer();
			
	if (!g_bEnabled)
		return;
		
	SDKHook(client, SDKHook_OnTakeDamage, Hook_ClientTakeDamage);
}

public void OnClientDisconnect_Post(int client)
{
	if (GetClientCount(true) < g_cMinplayers.IntValue)
		delete g_hTimer;
	if (g_iVotes[client])
	{
		g_iVotes[client] = 0;
		g_iTotalVotes--;
	}
}

public void OnConvarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	if (StrEqual(oldValue, newValue, true))
		return;
		
	if (convar == g_cMinplayers)
	{
		if (!g_iBossCount)
			ResetTimer();
		else
			delete g_hTimer;
	}
	else if (convar == g_cInterval)
	{
		ResetTimer();
	}
}

public Action SayText2(UserMsg msg_id, Handle bf, int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bEnabled)
		return Plugin_Continue;
		
	if (!reliable) 
		return Plugin_Continue;
	
	char buffer[128];
	BfReadByte(bf);
	BfReadByte(bf);
	
	BfReadString(bf, buffer, sizeof(buffer));
	
	if (StrEqual(buffer, "#TF_Halloween_Boss_Killers") || StrEqual(buffer, "#TF_Halloween_Eyeball_Boss_Killers") || StrEqual(buffer, "#TF_Halloween_Merasmus_Killers"))
		return Plugin_Handled;
		
	return Plugin_Continue;
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	g_iBossCount = 0;
	
	if (!g_bEnabled)
		return Plugin_Continue;
	
	delete g_hTimer;
	
	if (GetClientCount(true) >= g_cMinplayers.IntValue)
	{
		ResetTimer();
	}
	return Plugin_Continue;
}

public Action Event_Blocked(Event event, const char[] name, bool dontBroadcast)
{
	return g_bEnabled ? Plugin_Handled : Plugin_Continue;
}

public Action Command_BossVote(int client, int args)
{
	if (!g_bEnabled)
	{
		CReplyToCommand(client, "{frozen}[Boss] {orange}Custom Boss Spawner is disabled.");
		return Plugin_Handled;
	}
	
	if (!client || !IsClientInGame(client))
	{
		CReplyToCommand(client, "{frozen}[Boss] You must be alive and in-game to use this command.");
		return Plugin_Handled;
	}
		
	if (!g_iVotes[client])
	{
		g_iVotes[client] = 1;
		g_iTotalVotes++;
		
		int percentage = (g_iTotalVotes / GetClientCount(true) * 100);
		
		if (percentage >= g_cVote.IntValue)
		{
			for(int i = 0; i < MaxClients; i++)
				g_iVotes[i] = 0;
			delete g_hTimer;
			CreateVote();
		}
		else
			CPrintToChatAll("{frozen}[Boss] {orange}%N has casted a vote! %d%% out of %d%% is needed to start a vote!", client, percentage, g_cVote.IntValue);
	}
	else
		CReplyToCommand(client, "{frozen}[Boss] {orange}You have already casted a vote!");
	return Plugin_Handled;
}

public Action Command_ForceBossSpawn(int client, int args)
{
	if (!g_bEnabled)
	{
		CReplyToCommand(client, "{frozen}[Boss] {orange}Custom Boss Spawner is disabled.");
		return Plugin_Handled;
	}
	
	if (args == 1)
	{
		g_iSaveIndex = g_iIndex;
		char arg1[32], sName[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		int i;
		for (i = 0; i < g_iArray.Length; i++)
		{
			StringMap HashMap = g_iArray.Get(i);
			HashMap.GetString("Name", sName, sizeof(sName));
			if (StrEqual(sName, arg1, false))
			{
				g_iIndex = i; break;
			}
		}
		
		if (i == g_iArray.Length)
		{
			CReplyToCommand(client, "{frozen}[Boss] {red}Error: {orange}Boss does not exist.");
			return Plugin_Handled;
		}
		g_iArgIndex = 1;
		delete g_hTimer;
		char sGlow[32];
		CreateBoss(g_iIndex, g_fPos, -1, -1, -1.0, sGlow, false, true);
	}
	else if (args == 0)
	{
		g_iArgIndex = 0;
		delete g_hTimer;
		SpawnBoss();
	}
	else
		CReplyToCommand(client, "{frozen}[Boss] {red}Format: {orange}!forceboss <bossname>");
	return Plugin_Handled;
}

public Action Command_GetCoordinates(int client, int args)
{
	if (!g_bEnabled)
	{
		CReplyToCommand(client, "{frozen}[Boss] {orange}Custom Boss Spawner is disabled.");
		return Plugin_Handled;
	}
	
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		CReplyToCommand(client, "{frozen}[Boss] You must be alive and in-game to use this command.");
		return Plugin_Handled;
	}
	
	float pos[3];
	GetClientAbsOrigin(client, pos);
	CReplyToCommand(client, "{frozen}[Boss] {orange}Coordinates: %0.0f,%0.0f,%0.0f\n{frozen}[Boss] {orange}Use those coordinates and place them in configs/bossspawner_maps.cfg", pos[0], pos[1], pos[2]);
	return Plugin_Handled;
}

public Action Command_SlayBoss(int client, int args)
{
	if (!g_bEnabled)
	{
		CReplyToCommand(client, "{frozen}[Boss] {orange}Custom Boss Spawner is disabled.");
		return Plugin_Handled;
	}
	g_bSlayCommand = true;
	RemoveExistingBoss();
	CReplyToCommand(client, "%t", "Boss_Slain");
	return Plugin_Handled;
}

public Action Command_ForceVote(int client, int args)
{
	if (!g_bEnabled)
	{
		CReplyToCommand(client, "{frozen}[Boss] {orange}Custom Boss Spawner is disabled.");
		return Plugin_Handled;
	}
	delete g_hTimer;
	CreateVote();
	CReplyToCommand(client, "%t", "Vote_Forced");
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{	
	char arg[4][64];
	int args = ExplodeString(sArgs, " ", arg, sizeof(arg), sizeof(arg[]));
	
	if (arg[0][0] == '!' || arg[0][0] == '/')
		strcopy(arg[0], 64, arg[0][1]);
	else 
		return Plugin_Continue;
		
	int i; StringMap HashMap; char sName[64];
	
	for (i = 0; i < g_iArray.Length; i++)
	{
		HashMap = g_iArray.Get(i);
		HashMap.GetString("Name", sName, sizeof(sName));
		
		if (StrEqual(sName, arg[0], false))
			break;
	}
	if (i == g_iArray.Length)
		return Plugin_Continue;
		
	if (!g_bEnabled)
	{
		CPrintToChat(client, "{frozen}[Boss] {orange}Custom Boss Spawner is disabled.");
		return Plugin_Handled;
	}
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		CPrintToChat(client, "{frozen}[Boss] {orange}You must be alive and in-game to use this command.");
		return Plugin_Handled;
	}
	
	if (!CheckCommandAccess(client, "sm_boss_override", ADMFLAG_GENERIC, false))
	{
		CPrintToChat(client, "{frozen}[Boss] {orange}You do not have access to this command.");
		return Plugin_Handled;
	}
	
	if (!SetTeleportEndPoint(client))
	{
		CPrintToChat(client, "{Frozen}[Boss] {orange}Could not find spawn point.");
		return Plugin_Handled;
	}
	
	g_fkPos[2] -= 10.0;
	int iBaseHP = -1, iScaleHP = -1;
	char sGlow[32];
	float iSize = -1.0;
	
	if (args < 1 || args > 4)
	{
		CPrintToChat(client, "{Frozen}[Boss] {orange}Incorrect parameters: !<bossname> <health> <optional:size> <optional:RGBA values for color>");
		CPrintToChat(client, "{Frozen}[Boss] {orange}Example usage: !horseman 1000 2 255,255,255,255");
		return Plugin_Handled;
	}
	else
	{
		if(args > 1)
		{
			iBaseHP = StringToInt(arg[1]);
			iScaleHP = 0;
		}
		
		if(args > 2)
			iSize = StringToFloat(arg[2]);
			
		if(args > 3)
		{
			Format(sGlow, sizeof(sGlow), "%s", arg[3]);
			ReplaceString(sGlow, sizeof(sGlow), ",", " ", false);
		}
	}
	g_iIndexCmd = i;
	
	CreateBoss(g_iIndexCmd, g_fkPos, iBaseHP, iScaleHP, iSize, sGlow, true, false);
	return Plugin_Handled;
}

public Action SpawnBossCommand(int client, const char[] command, int args)
{
	char arg1[64], arg2[32], arg3[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int i;
	StringMap HashMap = null;
	char sName[64];
	int nIndex = FindCharInString(command, '_', _) + 1;
	char command2[64];
	strcopy(command2, sizeof(command2), command[nIndex]);
	
	for (i = 0; i < g_iArray.Length; i++)
	{
		HashMap = g_iArray.Get(i);
		HashMap.GetString("Name", sName, sizeof(sName));
		
		if(StrEqual(sName, command2, false))
			break;
	}
	if (i == g_iArray.Length)
		return Plugin_Continue;
		
	if (!g_bEnabled)
	{
		CPrintToChat(client, "{frozen}[Boss] {orange}Custom Boss Spawner is disabled.");
		return Plugin_Handled;
	}
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		CPrintToChat(client, "{frozen}[Boss] {orange}You must be alive and in-game to use this command.");
		return Plugin_Handled;
	}
	
	if (!CheckCommandAccess(client, "sm_boss_override", ADMFLAG_GENERIC, false))
	{
		CPrintToChat(client, "{frozen}[Boss] {orange}You do not have access to this command.");
		return Plugin_Handled;
	}
	
	if (!SetTeleportEndPoint(client))
	{
		CPrintToChat(client, "{Frozen}[Boss] {orange}Could not find spawn point.");
		return Plugin_Handled;
	}
	g_fkPos[2] -= 10.0;
	int iBaseHP = -1, iScaleHP = -1;
	char sGlow[32];
	float iSize = -1.0;
	
	if (args < 0 || args > 3)
	{
		CPrintToChat(client, "{Frozen}[Boss] {orange}Incorrect parameters: !<bossname> <health> <optional:size> <optional:RGBA values for color>");
		CPrintToChat(client, "{Frozen}[Boss] {orange}Example usage: !horseman 1000 2 255,255,255,255");
		return Plugin_Handled;
	}
	else
	{
		if (args > 0)
		{
			GetCmdArg(1, arg1, sizeof(arg1));
			iBaseHP = StringToInt(arg1);
			iScaleHP = 0;
		}
		
		if (args > 1)
		{
			GetCmdArg(2, arg2, sizeof(arg2));
			iSize = StringToFloat(arg2);
		}
		
		if (args > 2)
		{
			GetCmdArg(3, arg3, sizeof(arg3));
			Format(sGlow, sizeof(sGlow), "%s", arg3);
			ReplaceString(sGlow, sizeof(sGlow), ",", " ", false);
		}
	}
	g_iIndexCmd = i;
	CreateBoss(g_iIndexCmd, g_fkPos, iBaseHP, iScaleHP, iSize, sGlow, true, false);
	return Plugin_Handled;
}

public Action Command_SpawnMenu(int client, int args)
{
	if (!g_bEnabled)
	{
		CReplyToCommand(client, "{frozen}[Boss] {orange}Custom Boss Spawner is disabled.");
		return Plugin_Handled;
	}
	if (!client || !IsClientInGame(client))
	{
		CReplyToCommand(client, "{frozen}[Boss] You must be alive and in-game to use this command.");
		return Plugin_Handled;
	}
	ShowMenu(client);
	return Plugin_Handled;
}

public void ShowMenu(int client)
{
	StringMap HashMap = null;
	char sName[64], sInfo[8];
	Menu menu = new Menu(DisplayHealth);
	SetMenuTitle(menu, "Boss Menu");
	for (int i = 0; i < g_iArray.Length; i++)
	{
		HashMap = g_iArray.Get(i);
		HashMap.GetString("Name", sName, sizeof(sName));
		IntToString(i, sInfo, sizeof(sInfo));
		menu.AddItem(sInfo, sName);
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DisplayHealth(Menu MenuHandle, MenuAction action, int client, int num)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		MenuHandle.GetItem(num, info, sizeof(info));
		Menu menu = new Menu(DisplaySizes);
		menu.SetTitle("Boss Health");
		char param[32];
		char health[][] = {"1000", "5000", "10000", "15000", "20000", "30000", "50000"};
		for (int i = 0; i < sizeof(health); i++)
		{
			Format(param, sizeof(param), "%s %s", info, health[i]);
			menu.AddItem(param, health[i]);
		}
		SetMenuExitButton(menu, true);
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
		delete MenuHandle;
}

public int DisplaySizes(Menu MenuHandle, MenuAction action, int client, int num)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		MenuHandle.GetItem(num, info, sizeof(info));
		Menu menu = new Menu(DisplayGlow);
		menu.SetTitle("Boss Size");
		char param[32];
		char size[][] = {"0.5", "1.0", "1.5", "2.0", "3.0", "4.0", "5.0"};
		for (int i = 0; i < sizeof(size); i++)
		{
			Format(param, sizeof(param), "%s %s", info, size[i]);
			menu.AddItem(param, size[i]);
		}
		SetMenuExitButton(menu, true);
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
		delete MenuHandle;
}

public int DisplayGlow(Menu MenuHandle, MenuAction action, int client, int num)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		MenuHandle.GetItem(num, info, sizeof(info));
		Menu menu = new Menu(EndMenu);
		menu.SetTitle("Boss Glow");
		char param[32];
		
		Format(param, sizeof(param), "%s 0,255,0,255", info);
		menu.AddItem(param, "Green");
		Format(param, sizeof(param), "%s 255,255,0,255", info);
		menu.AddItem(param, "Yellow");
		Format(param, sizeof(param), "%s 255,165,0,255", info);
		menu.AddItem(param, "Orange");
		Format(param, sizeof(param), "%s 255,0,0,255", info);
		menu.AddItem(param, "Red");
		Format(param, sizeof(param), "%s 0,0,128,255", info);
		menu.AddItem(param, "Navy");
		Format(param, sizeof(param), "%s 0,0,255,255", info);
		menu.AddItem(param, "Blue");
		Format(param, sizeof(param), "%s 255,0,255,255", info);
		menu.AddItem(param, "Purple");
		Format(param, sizeof(param), "%s 0,255,255,255", info);
		menu.AddItem(param, "Cyan");
		Format(param, sizeof(param), "%s 255,192,203,255", info);
		menu.AddItem(param, "Pink");
		Format(param, sizeof(param), "%s 127,255,212,255", info);
		menu.AddItem(param, "Aquamarine");
		Format(param, sizeof(param), "%s 255,218,185,255", info);
		menu.AddItem(param, "Peachpuff");
		Format(param, sizeof(param), "%s 255,255,255,255", info);
		menu.AddItem(param, "White");
		Format(param, sizeof(param), "%s 0,0,0,0", info);
		menu.AddItem(param, "None");
			
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
		delete MenuHandle;
}

public int EndMenu(Menu MenuHandle, MenuAction action, int client, int num)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		MenuHandle.GetItem(num, info, sizeof(info));
		char sAttribute[4][16];
		ExplodeString(info, " ", sAttribute, sizeof(sAttribute), sizeof(sAttribute[]));
		int iIndex, iBaseHP;
		float iSize;
		iIndex = StringToInt(sAttribute[0]);
		iBaseHP = StringToInt(sAttribute[1]);
		iSize = StringToFloat(sAttribute[2]);
		ReplaceString(sAttribute[3], sizeof(sAttribute[]), ",", " ", false);
		
		if (!SetTeleportEndPoint(client)) {
			CReplyToCommand(client, "{Frozen}[Boss] {orange}Could not find spawn point.");
			return;
		}
		
		g_fkPos[2] -= 10.0;
		CreateBoss(iIndex, g_fkPos, iBaseHP, 0, iSize, sAttribute[3], true, false);
	}
	else if (action == MenuAction_End)
		delete MenuHandle;
}

bool SetTeleportEndPoint(int client)
{
	float vAngles[3], vOrigin[3], vBuffer[3], vStart[3], Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceentFilterPlayer);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_fkPos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_fkPos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_fkPos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

public bool TraceentFilterPlayer(int ent, int contentsMask)
{
	return ent > MaxClients || !ent;
}

public void CreateVote()
{
	if (IsVoteInProgress())
		return;
		
	CPrintToChatAll("{frozen}[Boss] {orange}A vote has been started to spawn the next boss!");
	//create a random list to push random bosses
	ArrayList randomList = new ArrayList();
	//then clone the original array so we don't mess with the original
	ArrayList copyList = g_iArray.Clone();
	
	//we loop through the copy list and get a random hash and push it to the random list then erase the index from copylist
	while (copyList.Length != 0)
	{
		int rand = GetRandomInt(0, copyList.Length-1);
		randomList.Push(copyList.Get(rand));
		copyList.Erase(rand);
	}
	char iData[64], sName[64];
	Menu menu = new Menu(Handle_VoteMenu);
	for (int i = 0; i < randomList.Length; i++)
	{
		StringMap HashMap = randomList.Get(i);
		HashMap.GetString("Name", sName, sizeof(sName));
		int index = g_iArray.FindValue(HashMap);
		Format(iData, sizeof(iData), "%d", index);
		menu.SetTitle("Vote for the next boss!");
		menu.AddItem(iData, sName);
	}
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
	delete randomList;
	delete copyList;
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;
	else if (action == MenuAction_VoteEnd)
	{
		char iData[64];
		menu.GetItem(param1, iData, sizeof(iData));
		int index = StringToInt(iData);
		char sGlow[32];
		CreateBoss(index, g_fPos, -1, -1, -1.0, sGlow, false, true);
	}
}

public void SpawnBoss()
{
	char sGlow[32];
	switch (g_cMode.IntValue)
	{
		case 0:
		{
			g_iIndex = GetRandomInt(0, g_iArray.Length-1);
			CreateBoss(g_iIndex, g_fPos, -1, -1, -1.0, sGlow, false, true);
		}
		case 1: CreateBoss(g_iIndex, g_fPos, -1, -1, -1.0, sGlow, false, true);
		case 2: CreateVote();
	}
}

public void CreateBoss(int index, float kpos[3], int iBaseHP, int iScaleHP, float iSize, const char[] sGlowValue, bool isCMD, bool timed)
{
	float temp[3];
	for (int i = 0; i < 3; i++)
		temp[i] = kpos[i];
	
	char sName[64], sModel[256], sType[32], sGlow[32], sPosition[32], sHModel[256], sISound[256];
	int iBase, iScale, iLifetime, iHorde, iColor;
	float fSize, fPosFix, fHatPosFix, fHatSize;

	StringMap HashMap = g_iArray.Get(index);
	HashMap.GetString("Name", sName, sizeof(sName));
	HashMap.GetString("Model", sModel, sizeof(sModel));
	HashMap.GetString("Type", sType, sizeof(sType));
	HashMap.GetValue("Base", iBase);
	HashMap.GetValue("Scale", iScale);
	HashMap.GetValue("Size", fSize);
	HashMap.GetString("Glow", sGlow, sizeof(sGlow));
	HashMap.GetValue("PosFix", fPosFix);
	HashMap.GetValue("Lifetime", iLifetime);
	HashMap.GetString("Position", sPosition, sizeof(sPosition));
	HashMap.GetValue("Horde", iHorde);
	HashMap.GetValue("Color", iColor);
	HashMap.GetString("HatModel", sHModel, sizeof(sHModel));
	HashMap.GetString("IntroSound", sISound, sizeof(sISound));
	HashMap.GetValue("HatPosFix", fHatPosFix);
	HashMap.GetValue("HatSize", fHatSize);
	
	if (iBaseHP == -1)
		iBaseHP = iBase;
		
	if (iScaleHP == -1)
		iScaleHP = iScale;
		
	if (iSize == -1.0)
		iSize = fSize;
		
	if (!sPosition[0] && !isCMD)
	{
		char sPos[3][16];
		ExplodeString(sPosition, ",", sPos, sizeof(sPos), sizeof(sPos[]));
		
		for(int i = 0; i < 3; i++)
			temp[i] = StringToFloat(sPos[i]);
	}
	
	temp[2] += fPosFix;
	int count = iHorde <= 1 ? 1 : iHorde;
	int playerCounter = GetClientCount(true);
	int sHealth = (iBaseHP + RoundFloat(float(iScaleHP) * float(playerCounter)));
	PrintToChatAll("%d", sHealth);
	
	Reference reference = new Reference(count);
	
	for (int i = 0; i < count; i++)
	{
		int ent = CreateEntityByName(sType);
		BossPack pack = new BossPack(ent, reference, index, timed);
		g_iArrayData.Push(pack);
		
		TeleportEntity(ent, temp, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		
		ResizeHitbox(ent, iSize);
		SetSize(iSize, ent);
		
		SetEntProp(ent, Prop_Data, "m_iHealth", sHealth);
		SetEntProp(ent, Prop_Data, "m_iMaxHealth", sHealth); 
		SetEntProp(ent, Prop_Data, "m_iTeamNum", (StrEqual(sType, MONOCULUS) || StrEqual(sType, SKELETON)) ? 5 : 0);
		
		int attach = ent;
		char targetname[128];
		Format(targetname, sizeof(targetname), "%s%d", sName, GetRandomInt(2000, 10000));
		//Creates boss model to bonemerge
		if (sModel[0])
		{
			if (!StrEqual(sType, MONOCULUS))
			{
				int model = CreateEntityByName("prop_dynamic_override");
				attach = model;
				
				DispatchKeyValue(model, "targetname", targetname);
				DispatchKeyValue(model, "model", sModel);
				DispatchKeyValue(model, "solid", "0");
				SetEntPropEnt(model, Prop_Send, "m_hOwnerEntity", ent);
				SetEntProp(model, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
				
				TeleportEntity(model, kpos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(model);
				
				SetVariantString("!activator");
				AcceptEntityInput(model, "SetParent", ent, model, 0);
				
				SetVariantString("head"); 
				AcceptEntityInput(model, "SetParentAttachment", ent, model, 0);
				
				SetEntProp(ent, Prop_Send, "m_fEffects", EF_NODRAW);
			}
			else
				DispatchKeyValue(ent, "targetname", targetname);
		}
		else
			DispatchKeyValue(ent, "targetname", targetname);
			
		SetEntProp(attach, Prop_Send, "m_nSkin", iColor == 4 ? GetRandomInt(0, 3) : iColor);
		
		if (!sGlowValue[0])
			SetGlow(ent, targetname, kpos, sGlow);
		else
			SetGlow(ent, targetname, kpos, sGlowValue);
		
		if (timed) 
			g_iBossCount++;
		
		if (!i)
		{
			DataPack hPack;
			CreateDataTimer(1.0, Timer_Remove, hPack, TIMER_REPEAT);
			hPack.WriteFloat(GetEngineTime() + float(iLifetime) - 1.0);
			hPack.WriteCell(EntIndexToEntRef(ent));
			hPack.WriteCell(index);
		}
		SetEntitySelfDestruct(ent, float(iLifetime)+0.1);
		
		if (sHModel[0])
		{
			int hat = CreateEntityByName("prop_dynamic_override");
			DispatchKeyValue(hat, "model", sHModel);
			DispatchKeyValue(hat, "spawnflags", "256");
			DispatchKeyValue(hat, "solid", "0");
			SetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity", attach);
			//Hacky tacky way..
			//SetEntPropFloat(hat, Prop_Send, "m_flModelScale", iSize > 5 ? (iSize > 10 ? (iSize/5+0.80) : (iSize/4+0.75)) : (iSize/3+0.66));
			SetEntPropFloat(hat, Prop_Send, "m_flModelScale", fHatSize);
			//SetEntPropFloat(hat, Prop_Send, "m_flModelScale", iSize*StringToFloat(sHatSize));
			DispatchSpawn(hat);	
			
			SetVariantString("!activator");
			AcceptEntityInput(hat, "SetParent", attach, hat, 0);
			
			//maintain the offset of hat to the center of head
			if (!StrEqual(sType, MONOCULUS))
			{
				SetVariantString("head");
				AcceptEntityInput(hat, "SetParentAttachment", attach, hat, 0);
				SetVariantString("head");
				AcceptEntityInput(hat, "SetParentAttachmentMaintainOffset", attach, hat, 0);
			}
			
			float hatpos[3];
			hatpos[2] += fHatPosFix;//*iSize; //-9.5*iSize
			//hatpos[0] += -5.0;
			TeleportEntity(hat, hatpos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	if (!StrEqual(sISound, "none", false))
		EmitSoundToAll(sISound, _, _, _, _, 1.0);
		
	ReplaceString(sName, sizeof(sName), "_", " ");
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			CPrintToChat(i, "%t", "Boss_Spawn", sName);
	
	if (g_iArgIndex == 1)
		g_iIndex = g_iSaveIndex;
	
	if (timed)
	{
		g_iIndex++;
		if (g_iIndex > g_iArray.Length-1) 
			g_iIndex = 0;
	}
}


public Action Timer_Remove(Handle hTimer, DataPack hPack)
{
	hPack.Reset();
	
	if (GetEngineTime() >= hPack.ReadFloat())
	{
		int ent = EntRefToEntIndex(hPack.ReadCell());
	
		if (!IsValidEntity(ent))
			return Plugin_Stop;
		
		char sName[64];
		StringMap HashMap = g_iArray.Get(hPack.ReadCell());
		HashMap.GetString("Name", sName, sizeof(sName));
		
		g_bSlayCommand = true;
		
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				CPrintToChat(i, "%t", "Boss_Left", sName);
				
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

//Instead of hooking to sdkhook_takedamage, we use a 0.5 timer because of hud overloading when taking damage
public Action Timer_Healthbar(Handle hTimer, any ref)
{
	if (g_cHealthbar.IntValue == 0 || g_cHealthbar.IntValue == 1)
		return Plugin_Continue;
		
	if (!IsValidEntity(g_iBossEntity))
		return Plugin_Continue;
		
	int health = GetEntProp(g_iBossEntity, Prop_Data, "m_iHealth");
	int max_health = GetEntProp(g_iBossEntity, Prop_Data, "m_iMaxHealth");
	
	float max_threshold = max_health * 0.65;
	float min_threshold = max_health * 0.25;
	
	if (health > max_threshold) 
		SetHudTextParams(0.46, 0.12, 0.5, 0, 255, 0, 255);
	else if (min_threshold < health < max_threshold) 
		SetHudTextParams(0.46, 0.12, 0.5, 255, 255, 0, 255);
	else if (0 < health < min_threshold)
		SetHudTextParams(0.46, 0.12, 0.5, 255, 0, 0, 255);
	else
	{
		SetHudTextParams(0.46, 0.12, 0.5, 0, 0, 0, 0);
		health = 0;
	}
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			ShowSyncHudText(i, g_hHudSync, "HP: %d", health);
			
	return Plugin_Continue;
}

void RemoveExistingBoss()
{
	int ent; char classname[32];
	while ((ent = FindEntityByClassname(ent, "*")) != -1)
	{
		GetEntityClassname(ent, classname, 32);
		if (StrEqual(classname, HORSEMAN) || StrEqual(classname, MONOCULUS) || StrEqual(classname, MERASMUS) || StrEqual(classname, SKELETON))
			AcceptEntityInput(ent, "Kill");
	}
		
	if (g_iHealthbar != -1)
		SetEntProp(g_iHealthbar, Prop_Send, "m_iBossHealthPercentageByte", 0);
}

public void CreateCountdownTimer()
{
	if (!g_bEnabled) 
		return;
	
	g_hTimer = CreateTimer(1.0, Timer_HUDCounter, GetEngineTime() + float(g_cInterval.IntValue), TIMER_REPEAT);
}

public Action Timer_HUDCounter(Handle hTimer, float time)
{
	if (GetEngineTime() >= time)
	{
		SpawnBoss();
		g_hTimer = null;
		return Plugin_Stop;
	}
	
//	for (int i = 1; i <= MaxClients; i++)
//	{
//		if(!IsClientInGame(i))
//			continue;
//		SetHudTextParams(g_cHudx.FloatValue, g_cHudy.FloatValue, 1.0, 255, 255, 255, 255);
//		ShowSyncHudText(i, g_hHudSync, "Boss: %d seconds", RoundFloat(time - GetEngineTime()));
//	}
	
	return Plugin_Continue;
}

void ResetTimer()
{
	delete g_hTimer;
	CreateCountdownTimer();
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			CPrintToChat(i, "%t", "Time", g_cInterval.IntValue);
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if (!g_bEnabled)
		return;
		
	if (StrEqual(classname, "monster_resource"))
		g_iHealthbar = ent;		
	else if (StrEqual(classname, HORSEMAN) || StrEqual(classname, MONOCULUS) || StrEqual(classname, MERASMUS) || StrEqual(classname, SKELETON))
	{
		g_iBossEntity = ent;
		SDKHook(ent, SDKHook_OnTakeDamage, Hook_BossTakeDamage);
		if (g_cHealthbar.IntValue == 1 || g_cHealthbar.IntValue == 3)
			SetEntProp(g_iHealthbar, Prop_Send, "m_iBossHealthPercentageByte", 2559);
	}
	else if (StrEqual(classname, "prop_dynamic"))
		RequestFrame(OnPropSpawn, EntIndexToEntRef(ent));
}

public void OnEntityDestroyed(int ent)
{
	if (!g_bEnabled)
		return;
	
	if (!IsValidEntity(ent))
		return;
		
	char classname[32];
	GetEntityClassname(ent, classname, sizeof(classname));
	if (!StrEqual(classname, HORSEMAN) && !StrEqual(classname, MONOCULUS) && !StrEqual(classname, MERASMUS) && !StrEqual(classname, SKELETON))
		return;

	for (int i = g_iArrayData.Length-1; i >= 0; i--)
	{
		BossPack pack = g_iArrayData.Get(i);
		int boss_entity = pack.Entity;
		
		if (ent != boss_entity)
			continue;
		
		if (g_iBossEntity == ent)
		{
			g_iBossEntity = -1;
			int boss;
			while ((boss = FindEntityByClassname(boss, "*")) != -1)
			{
				GetEntityClassname(boss, classname, 32);
				if (StrEqual(classname, HORSEMAN) || StrEqual(classname, MONOCULUS) || StrEqual(classname, MERASMUS) || StrEqual(classname, SKELETON))
				{
					if (boss == ent)
						continue;
					g_iBossEntity = boss;
					break;
				}
			}
			
			if (g_iBossEntity == -1)
				SetEntProp(g_iHealthbar, Prop_Send, "m_iBossHealthPercentageByte", 0);
			else
			{
				int health = GetEntProp(g_iBossEntity, Prop_Data, "m_iHealth");
				int max_health = GetEntProp(g_iBossEntity, Prop_Data, "m_iMaxHealth");
				
				if (g_cHealthbar.IntValue == 1 || g_cHealthbar.IntValue == 3)
					SetEntProp(g_iHealthbar, Prop_Send, "m_iBossHealthPercentageByte", RoundToCeil((float(health) / float(max_health)) * 255.9));
			}
		}
		
		Reference reference = pack.Ref;
		int count = reference.Value;
		int index = pack.Index;
		int timed = pack.Timed;		
		count -= 1;
		reference.Value = count;
		pack.Ref = reference;
		
		if (timed)
			g_iBossCount--;
			
		if (count == 0)
		{
			StringMap HashMap = g_iArray.Get(index);
			char sDSound[256];
			HashMap.GetString("DeathSound", sDSound, sizeof(sDSound));
			
			if (!StrEqual(sDSound, "none", false))
				EmitSoundToAll(sDSound, _, _, _, _, 1.0);
				
			if (timed && GetClientCount(true) >= g_cMinplayers.IntValue && g_iBossCount == 0)
				ResetTimer();
			
			if (!g_bSlayCommand)
			{
				char sName[64];
				HashMap.GetString("Name", sName, sizeof(sName));
				if (1 <= g_iAttacker <= MaxClients)
					CPrintToChatAll("{green}[HappyLand] {darkslateblue}%N slayed the %s!", g_iAttacker, sName);
				else
					CPrintToChatAll("{green}[HappyLand] {darkslateblue}%s died from an unknown entity!", sName);
			}
			delete reference;
		}
		g_iAttacker = -1;
		g_iArrayData.Erase(i);
		delete pack;
		break;
	}
}

public void OnPropSpawn(any ref)
{
	int ent = EntRefToEntIndex(ref);
	
	if (!IsValidEntity(ent)) 
		return;
		
	int parent = GetEntPropEnt(ent, Prop_Data, "m_pParent");
	
	if (!IsValidEntity(parent)) 
		return;
		
	char classname[64];
	GetEntityClassname(parent, classname, 64);
	if (StrEqual(classname, HORSEMAN, false))
	{
		for (int i = g_iArrayData.Length-1; i >= 0; i--)
		{
			BossPack pack = g_iArrayData.Get(i);
			int boss_entity = pack.Entity;
			int index = pack.Index;
			
			if (parent == boss_entity)
			{
				char sWModel[256];
				StringMap HashMap = g_iArray.Get(index);
				HashMap.GetString("WeaponModel", sWModel, sizeof(sWModel));
				if (sWModel[0])
				{
					if (StrEqual(sWModel, "Invisible"))
						SetEntProp(ent, Prop_Send, "m_fEffects", EF_NODRAW);
					else
					{
						SetEntityModel(ent, sWModel);
						SetEntPropEnt(parent, Prop_Send, "m_hActiveWeapon", ent);
					}
				}
				break;
			}
		}
	}
}

public Action Hook_ClientTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{	
	if (!IsValidEntity(attacker)) 
		return Plugin_Continue;
		
	char classname[32];
	GetEntityClassname(attacker, classname, sizeof(classname));
	
	if (StrEqual(classname, HORSEMAN) || StrEqual(classname, MONOCULUS) || StrEqual(classname, MERASMUS) || StrEqual(classname, SKELETON))
	{
		float fDamage;
		for (int i = g_iArrayData.Length-1; i >= 0; i--)
		{
			BossPack pack = g_iArrayData.Get(i);
			int boss_entity = pack.Entity;
			
			if (attacker == boss_entity)
			{
				int index = pack.Index;
				StringMap HashMap = g_iArray.Get(index);
				HashMap.GetValue("Damage", fDamage);
				damage = fDamage;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action Hook_BossTakeDamage(int ent, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (g_iHealthbar == -1)
		return Plugin_Continue;
		
	if (!IsValidEntity(ent))
		return Plugin_Continue;
	
	int health = GetEntProp(ent, Prop_Data, "m_iHealth");
	int max_health = GetEntProp(ent, Prop_Data, "m_iMaxHealth");
	
	g_iBossEntity = ent;
	
	if (health - damage > 0)
	{
		if (g_cHealthbar.IntValue == 1 || g_cHealthbar.IntValue == 3)
			SetEntProp(g_iHealthbar, Prop_Send, "m_iBossHealthPercentageByte", RoundToCeil((float(health) / float(max_health)) * 255.9));
		return Plugin_Continue;
	}
	
	g_iAttacker = attacker;
	g_bSlayCommand = false;
	
	char classname[32];
	GetEntityClassname(ent, classname, sizeof(classname));
	
	if (StrEqual(classname, SKELETON))
	{
		AcceptEntityInput(ent, "kill");
		return Plugin_Handled;
	}
	
	SetEntProp(ent, Prop_Data, "m_iHealth", 0);
	
	return Plugin_Continue;
}

public void SetupMapConfigs(const char[] sFile)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if (!FileExists(sPath))
	{
		LogError("[Boss] Error: Can not find map filepath %s", sPath);
		SetFailState("[Boss] Error: Can not find map filepath %s", sPath);
	}
	
	KeyValues kv = CreateKeyValues("Boss Spawner Map");
	FileToKeyValues(kv, sPath);

	if (!KvGotoFirstSubKey(kv))
	{
		LogError("[Boss] Could not read maps file: %s", sPath);
		SetFailState("[Boss] Could not read maps file: %s", sPath);
	}
	
	int mapEnabled = 0;
	bool Default = false;
	int tempEnabled = 0;
	float temp_pos[3];
	char requestMap[64], currentMap[64], sPosition[64], tPosition[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	PrintToServer("%s", currentMap);
	do 
	{
		kv.GetSectionName(requestMap, sizeof(requestMap));
		if (StrEqual(requestMap, currentMap, false))
		{
			mapEnabled = kv.GetNum("Enabled", 0);
			g_fPos[0] = kv.GetFloat("Position X", 0.0);
			g_fPos[1] = kv.GetFloat("Position Y", 0.0);
			g_fPos[2] = kv.GetFloat("Position Z", 0.0);
			kv.GetString("TeleportPosition", sPosition, sizeof(sPosition), SNULL);
			Default = true;
		}
		else if (StrEqual(requestMap, "Default", false))
		{
			tempEnabled = kv.GetNum("Enabled", 0);
			temp_pos[0] = kv.GetFloat("Position X", 0.0);
			temp_pos[1] = kv.GetFloat("Position Y", 0.0);
			temp_pos[2] = kv.GetFloat("Position Z", 0.0);
			kv.GetString("TeleportPosition", tPosition, sizeof(tPosition), SNULL);
		}
	} while kv.GotoNextKey();
	delete kv;
	
	if (Default == false)
	{
		mapEnabled = tempEnabled;
		g_fPos = temp_pos;
		Format(sPosition, sizeof(sPosition), "%s", tPosition);
	}
	
	float tpos[3];
	if (sPosition[0])
	{
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, "info_target")) != -1)
		{
			char strName[32];
			GetEntPropString(ent, Prop_Data, "m_iName", strName, sizeof(strName));
			if (StrContains(strName, "spawn_loot") != -1)
				AcceptEntityInput(ent, "Kill");
		}
		
		char sPos[3][16];
		ExplodeString(sPosition, ",", sPos, sizeof(sPos), sizeof(sPos[]));
		tpos[0] = StringToFloat(sPos[0]);
		tpos[1] = StringToFloat(sPos[1]);
		tpos[2] = StringToFloat(sPos[2]);
		
		for (int i = 0; i < 4; i++)
		{
			ent = CreateEntityByName("info_target");
			char spawn_name[16];
			Format(spawn_name, sizeof(spawn_name), "%s", i == 0 ? "spawn_loot" : (i == 1 ? "spawn_loot_red" : (i == 2 ? "spawn_loot_blue" : "spawn_boss_alt")));
			SetEntPropString(ent, Prop_Data, "m_iName", spawn_name);
			TeleportEntity(ent, tpos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(ent);
		}
	}
	
	if (mapEnabled != 0)
	{
		g_bEnabled = true;
		if (GetClientCount(true) >= g_cMinplayers.IntValue)
		{
			CreateCountdownTimer();
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					CPrintToChat(i, "%t", "Time", g_cInterval.IntValue);
		}
	}
	else if (mapEnabled == 0)
		g_bEnabled = false;
		
	LogMessage("[CBS] Loaded Map configs successfully."); 
}

public void SetupBossConfigs(const char[] sFile)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if (!FileExists(sPath))
	{
		LogError("[CBS] Error: Can not find map filepath %s", sPath);
		SetFailState("[CBS] Error: Can not find map filepath %s", sPath);
	}
	
	Handle kv = CreateKeyValues("Custom Boss Spawner");
	FileToKeyValues(kv, sPath);

	if (!KvGotoFirstSubKey(kv))
	{
		LogError("[CBS] Could not read maps file: %s", sPath);
		SetFailState("[CBS] Could not read maps file: %s", sPath);
	}
	
	char sName[64], sModel[256], sType[32], sBase[16], sScale[16], sWModel[256], sSize[16], sGlow[32], sPosFix[32];
	char sLifetime[32], sPosition[32], sHorde[8], sColor[16], sISound[256], sDSound[256], sHModel[256];
	char sHatPosFix[32], sHatSize[16], sDamage[32];
	
	//Remove any command listeners if boss was removed between map changes
	for (int i = 0; i < g_iArray.Length; i++)
	{
		StringMap HashMap = g_iArray.Get(i);
		HashMap.GetString("Name", sName, sizeof(sName));
		
		char command[64];
		Format(command, sizeof(command), "sm_%s", sName);
		RemoveCommandListener(SpawnBossCommand, command);
	}
	
	g_iArray.Clear();
	
	do
	{
		KvGetSectionName(kv, sName, sizeof(sName));
		KvGetString(kv, "Model", sModel, sizeof(sModel), SNULL);
		KvGetString(kv, "Type", sType, sizeof(sType));
		KvGetString(kv, "HP Base", sBase, sizeof(sBase), "10000");
		KvGetString(kv, "HP Scale", sScale, sizeof(sScale), "1000");
		KvGetString(kv, "WeaponModel", sWModel, sizeof(sWModel), SNULL);
		KvGetString(kv, "Size", sSize, sizeof(sSize), "1.0");
		KvGetString(kv, "Glow", sGlow, sizeof(sGlow), "0 0 0 0");
		KvGetString(kv, "PosFix", sPosFix, sizeof(sPosFix), "0.0");
		KvGetString(kv, "Lifetime", sLifetime, sizeof(sLifetime), "120");
		KvGetString(kv, "Position", sPosition, sizeof(sPosition), SNULL);
		KvGetString(kv, "Horde", sHorde, sizeof(sHorde), "1");
		KvGetString(kv, "Color", sColor, sizeof(sColor), SNULL);
		KvGetString(kv, "IntroSound", sISound, sizeof(sISound), INTRO_SND);
		KvGetString(kv, "DeathSound", sDSound, sizeof(sDSound), DEATH_SND);
		KvGetString(kv, "HatModel", sHModel, sizeof(sHModel), SNULL);
		KvGetString(kv, "HatPosFix", sHatPosFix, sizeof(sHatPosFix), "0.0");
		KvGetString(kv, "HatSize", sHatSize, sizeof(sHatSize), "1.0");
		KvGetString(kv, "Damage", sDamage, sizeof(sDamage), "100.0");
		
		
		if (StrContains(sName, " ") != -1)
		{
			LogError("[CBS] Error: Boss names should not have spaces, please replace spaces with underscore '_'");
			SetFailState("[CBS] Error: Boss names should not have spaces, please replace spaces with underscore '_'");
		}
		
		bool bHorseman = StrEqual(sType, HORSEMAN);
		bool bMonoculus = StrEqual(sType, MONOCULUS);
		bool bMerasmus = StrEqual(sType, MERASMUS);
		bool bSkeleton = StrEqual(sType, SKELETON);
		
		int iBase = StringToInt(sBase);
		int iScale = StringToInt(sScale);
		float fSize = StringToFloat(sSize);
		float fPosFix = StringToFloat(sPosFix);
		int iLifetime = StringToInt(sLifetime);
		int iHorde = StringToInt(sHorde);
		
		int iColor;
		if (StrEqual(sColor, "red", false))
			iColor = 0;
		else if (StrEqual(sColor, "blue", false))
			iColor = 1;
		else if (StrEqual(sColor, "green", false))
			iColor = 2;
		else if (StrEqual(sColor, "yellow", false))
			iColor = 3;
		else if (StrEqual(sColor, SNULL, false))
			iColor = -1;
		else
			iColor = 4;
			
		float fHatPosFix = StringToFloat(sHatPosFix);
		float fHatSize = StringToFloat(sHatSize);
		float fDamage = StringToFloat(sDamage);
		
		
		if (!bHorseman && !bMonoculus && !bMerasmus && !bSkeleton)
		{
			LogError("[CBS] Boss type is undetermined, please check the boss type spelling again.");
			SetFailState("[CBS] Boss type is undetermined, please check the boss type spelling again.");
		}
		
		if (!bSkeleton)
		{
			if (iHorde != 1)
			{
				LogError("[CBS] Horde mode only works for boss type: tf_zombie.");
				SetFailState("[CBS] Horde mode only works for boss type: tf_zombie.");
			}
			if (iColor != -1)
			{
				LogError("[CBS] Color mode only works for boss type: tf_zombie.");
				SetFailState("[CBS] Color mode only works for boss type: tf_zombie.");
			}
		}
		
		if (bMonoculus)
		{
			SetEyeballLifetime(9999999);
			if (sModel[0])
			{
				LogError("[CBS] Can not apply custom model to monoculus.");
				SetFailState("[CBS] Can not apply custom model to monoculus.");
			}
		}
		
		if (bMerasmus)
			SetMerasmusLifetime(9999999);
			
		if (bSkeleton && fSize < 1.0)
		{
			LogError("[CBS] For tf_zombie type, size can not be lower than 1.0.");
			SetFailState("[CBS] For tf_zombie type, size can not be lower than 1.0");
		}
		
		if (sWModel[0])
		{
			PrintToServer("1");
			if (!bHorseman)
			{
				LogError("[CBS] Weapon model can only be changed on boss type: headless_hatman");
				SetFailState("[CBS] Weapon model can only be changed on boss type: headless_hatman");
			}
			else if (!StrEqual(sWModel, "Invisible"))
				PrecacheModel(sWModel, true);
		}
		
		if (sModel[0])
			PrecacheModel(sModel, true);
			
		if (sHModel[0])
			PrecacheModel(sHModel, true);
			
		PrecacheSound(sISound);
		PrecacheSound(sDSound);
		
		StringMap HashMap = new StringMap();
		HashMap.SetString("Name", sName, false);
		HashMap.SetString("Model", sModel, false);
		HashMap.SetString("Type", sType, false);
		HashMap.SetValue("Base", iBase, false);
		HashMap.SetValue("Scale", iScale, false);
		HashMap.SetString("WeaponModel", sWModel, false);
		HashMap.SetValue("Size", fSize, false);
		HashMap.SetString("Glow", sGlow, false);
		HashMap.SetValue("PosFix", fPosFix, false);
		HashMap.SetValue("Lifetime", iLifetime, false);
		HashMap.SetString("Position", sPosition, false);
		HashMap.SetValue("Horde", iHorde, false);
		HashMap.SetValue("Color", iColor, false);
		HashMap.SetString("IntroSound", sISound, false);
		HashMap.SetString("DeathSound", sDSound, false);
		HashMap.SetString("HatModel", sHModel, false);
		HashMap.SetValue("HatPosFix", fHatPosFix, false);
		HashMap.SetValue("HatSize", fHatSize, false);
		HashMap.SetValue("Damage", fDamage, false);
		g_iArray.Push(HashMap);
		
		char command[64];
		Format(command, sizeof(command), "sm_%s", sName);
		AddCommandListener(SpawnBossCommand, command);
	} while (KvGotoNextKey(kv));
	
	delete kv;
	LogMessage("[CBS] Custom Boss Spawner Configuration has loaded successfully."); 
}

public void SetupDownloads(const char[] sFile)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if (!FileExists(sPath))
	{
		LogError("[CBS] Error: Can not find download file %s", sPath);
		SetFailState("[CBS] Error: Can not find download file %s", sPath);
	}
	
	File file = OpenFile(sPath, "r");
	char buffer[256], fName[128], fPath[256];
	while (!file.EndOfFile() && file.ReadLine(buffer, sizeof(buffer)))
	{
		int i;	
		if ((i = FindCharInString(buffer, '\n', true)) != -1)
			buffer[i] = '\0';
			
		TrimString(buffer);
		
		if (!DirExists(buffer))
		{
			LogError("[CBS] Error: '%s' directory can not be found.", buffer);
			SetFailState("[CBS] Error: '%s' directory can not be found.", buffer);
		}
		
		int isMaterial = 0;
		if (StrContains(buffer, "materials/", true) != -1 || StrContains(buffer, "materials\\", true) != -1)
			isMaterial = 1;
			
		DirectoryListing sDir = OpenDirectory(buffer, true);
		while (sDir.GetNext(fName, sizeof(fName)))
		{
			if (StrEqual(fName, ".") || StrEqual(fName, "..")) 
				continue;
			if (StrContains(fName, ".ztmp") != -1) 
				continue;
			if (StrContains(fName, ".bz2") != -1)
				continue;
				
			Format(fPath, sizeof(fPath), "%s/%s", buffer, fName);
			AddFileToDownloadsTable(fPath);
			
			if (isMaterial == 1) 
				continue;
			if (StrContains(fName, ".vtx") != -1)
				continue;
			if (StrContains(fName, ".vvd") != -1)
				continue;
			if (StrContains(fName, ".phy") != -1)
				continue;
				
			PrecacheGeneric(fPath, true);
		}
		delete sDir;
	}
	delete file;
}
