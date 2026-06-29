/**
 *	1.7.0
 *		- Converted to Transitional API.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required

#define PLUGIN_VERSION "1.7.0"

#define CHICKEN		"models/chicken/chicken.mdl"
#define FEATHERS	"models/chicken/chicken_gone.mdl"

ConVar sm_coc_enable		= null;
ConVar sm_coc_random		= null;
ConVar sm_coc_ratio			= null;
ConVar sm_coc_beacon		= null;
ConVar sm_coc_knife			= null;
ConVar sm_coc_c4pickup		= null;
ConVar sm_coc_thirdperson	= null;
ConVar sm_coc_slaytk		= null;
ConVar sm_coc_winordie		= null;
ConVar sm_coc_hpchicken		= null;
ConVar sm_coc_hpbonus		= null;
ConVar sm_coc_hpreward		= null;
ConVar sm_coc_burntime		= null;
ConVar sm_coc_timeleft		= null;
ConVar sm_coc_minrivals		= null;
ConVar sm_coc_maxrivals		= null;
ConVar sm_coc_mdl_cluckct	= null;
ConVar sm_coc_mdl_cluckt	= null;
ConVar sm_coc_mdl_clutchct	= null;
ConVar sm_coc_mdl_clutcht	= null;
ConVar sm_coc_msg_warn		= null;
ConVar sm_coc_msg_killdeath	= null;
ConVar sm_coc_msg_clutch	= null;
ConVar sm_coc_msg_windordie	= null;
ConVar sm_coc_version		= null;

char playerName[MAX_NAME_LENGTH], cluckCT[PLATFORM_MAX_PATH], cluckT[PLATFORM_MAX_PATH], clutchCT[PLATFORM_MAX_PATH], clutchT[PLATFORM_MAX_PATH];
bool clutch = false, cluck = false, displayed = false, roundend = false, tp = false, tpOld = false;
int playerId = 0, chickenId = 0, chickenIdOld = 0, lastButton = 0, lastButtonOld = 0, savedTime, roundTime, aliveT, aliveCT, rivals;

EngineVersion g_EngineVersion;

public Plugin myinfo = 
{
	name = "[CS:GO/CS:S] Clutch Or Cluck",
	author = "GabenNewell (Bad Kitty)",
	description = "Clutch now or cluck the next round.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=237554"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_chicken", Command_Chicken, ADMFLAG_SLAY, "Sets the model of a player to a chicken.");
	
	sm_coc_enable			= CreateConVar("sm_coc_enable",			"1",	"Enable/disable the plugin.",																				FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_random			= CreateConVar("sm_coc_random",			"0",	"Randomly set Clutch or Cluck based on a ratio.",															FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_ratio			= CreateConVar("sm_coc_ratio",			"50",	"Percentage (%) chance for the player to turn into a chicken if sm_coc_random is 1. (100 = Always)",		FCVAR_NOTIFY, true, 0.0,	true, 100.0);
	sm_coc_beacon			= CreateConVar("sm_coc_beacon",			"0",	"Sets beacon on the player. (0 = Disabled, 1 = Clutch, 2 = Cluck, 3 = Both)\n* Requires funcommands.smx",	FCVAR_NOTIFY, true, 0.0,	true, 3.0);
	sm_coc_knife			= CreateConVar("sm_coc_knife",			"1",	"Allow chickens to use a knife.",																			FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_c4pickup			= CreateConVar("sm_coc_c4pickup",		"1",	"Allow chickens to pick up and plant the bomb.",															FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_thirdperson		= CreateConVar("sm_coc_thirdperson",	"1",	"Allow chickens to toggle third-person view using reload key. (CS:GO only)",								FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_slaytk			= CreateConVar("sm_coc_slaytk",			"1",	"Slay players who team kill friendly chickens.",															FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_winordie			= CreateConVar("sm_coc_winordie",		"50",	"If non-zero, slays players of the losing team whose HP is greater than or equal to this value.",			FCVAR_NOTIFY, true, 0.0,	true, 5000.0);
	sm_coc_hpchicken		= CreateConVar("sm_coc_hpchicken",		"1",	"Health points when turned into a chicken.",																FCVAR_NOTIFY, true, 1.0,	true, 5000.0);
	sm_coc_hpbonus			= CreateConVar("sm_coc_hpbonus",		"500",	"Health points when attempting to clutch a round.",															FCVAR_NOTIFY, true, 1.0,	true, 5000.0);
	sm_coc_hpreward			= CreateConVar("sm_coc_hpreward",		"200",	"Health points for successfully clutching a round.",														FCVAR_NOTIFY, true, 1.0,	true, 1000.0);
	sm_coc_burntime 		= CreateConVar("sm_coc_burntime",		"60.0",	"Number of seconds to burn a player for not clutching.",													FCVAR_NOTIFY, true, 0.0,	true, 120.0);
	sm_coc_timeleft 		= CreateConVar("sm_coc_timeleft",		"20",	"Minimum number of seconds left in a round for Clutch Or Cluck to activate.",								FCVAR_NOTIFY, true, 10.0,	true, 240.0);
	sm_coc_minrivals		= CreateConVar("sm_coc_minrivals",		"5",	"Minimum number of rivals for Clutch Or Cluck to activate.",												FCVAR_NOTIFY, true, 1.0,	true, 40.0);
	sm_coc_maxrivals		= CreateConVar("sm_coc_maxrivals",		"20",	"Maximum number of rivals for Clutch Or Cluck to activate.",												FCVAR_NOTIFY, true, 1.0,	true, 40.0);
	sm_coc_mdl_cluckct		= CreateConVar("sm_coc_mdl_cluckct",	"models/chicken/chicken.mdl",	"Cluck model for Counter-Terrorists.",												FCVAR_NOTIFY);
	sm_coc_mdl_cluckt		= CreateConVar("sm_coc_mdl_cluckt",		"models/chicken/chicken.mdl",	"Cluck model for Terrorists.",														FCVAR_NOTIFY);
	sm_coc_mdl_clutchct		= CreateConVar("sm_coc_mdl_clutchct",	"",								"Clutch model for Counter-Terrorists.",												FCVAR_NOTIFY);
	sm_coc_mdl_clutcht		= CreateConVar("sm_coc_mdl_clutcht",	"",								"Clutch model for Terrorists.",														FCVAR_NOTIFY);
	sm_coc_msg_warn			= CreateConVar("sm_coc_msg_warn",		"1",	"Show warning when Clutch or Cluck has been set on a player.",												FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_msg_killdeath	= CreateConVar("sm_coc_msg_killdeath",	"1",	"Show chicken kill/death notifications.",																	FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_msg_clutch		= CreateConVar("sm_coc_msg_clutch",		"1",	"Show clutch round information.",																			FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_msg_windordie	= CreateConVar("sm_coc_msg_windordie",	"1",	"Show win or die team slay message.",																		FCVAR_NOTIFY, true, 0.0,	true, 1.0);
	sm_coc_version			= CreateConVar("sm_coc_version",		PLUGIN_VERSION,	"Clutch Or Cluck plugin version.",																	FCVAR_NOTIFY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	sm_coc_enable		.AddChangeHook(ConVarChanged);
	sm_coc_thirdperson	.AddChangeHook(ConVarChanged);	
	sm_coc_mdl_cluckct	.AddChangeHook(ConVarChanged);
	sm_coc_mdl_cluckt	.AddChangeHook(ConVarChanged);
	sm_coc_mdl_clutchct	.AddChangeHook(ConVarChanged);
	sm_coc_mdl_clutcht	.AddChangeHook(ConVarChanged);
	sm_coc_version		.AddChangeHook(ConVarChanged);
	
	sm_coc_mdl_cluckct	.GetString(cluckCT, 	sizeof(cluckCT));
	sm_coc_mdl_cluckt	.GetString(cluckT,		sizeof(cluckT));
	sm_coc_mdl_clutchct	.GetString(clutchCT,	sizeof(clutchCT));
	sm_coc_mdl_clutcht	.GetString(clutchT,		sizeof(clutchT));
	
	g_EngineVersion = GetEngineVersion();
	
	LoadTranslations("common.phrases");
	//LoadTranslations("clutchorcluck.phrases");
	AutoExecConfig(true, "clutchorcluck");
	
	if (!FileExists(CHICKEN, true) && !FileExists(CHICKEN, false))
	{
		SetFailState("Chicken model missing: %s", CHICKEN);
	}
	else if (!StrEqual(cluckCT, "") && !FileExists(cluckCT, true) && !FileExists(cluckCT, false))
	{
		SetFailState("Missing model for sm_coc_mdl_cluckct: %s", cluckCT);
	}
	else if (!StrEqual(cluckT, "") && !FileExists(cluckT, true) && !FileExists(cluckT, false))
	{
		SetFailState("Missing model for sm_coc_mdl_cluckt: %s", cluckT);
	}
	else if (!StrEqual(clutchCT, "") && !FileExists(clutchCT, true) && !FileExists(clutchCT, false))
	{
		SetFailState("Missing model for sm_coc_mdl_clutchct: %s", clutchCT);
	}
	else if (!StrEqual(clutchT, "") && !FileExists(clutchT, true) && !FileExists(clutchT, false))
	{
		SetFailState("Missing model for sm_coc_mdl_clutcht: %s", clutchT);
	}
	else if (sm_coc_enable.BoolValue)
	{
		EnablePlugin();
	}
}

public void OnConfigsExecuted()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/clutchorcluck.ini");
	
	File file = OpenFile(path, "r");
	
	if (file != null)
	{
		char buffer[128];
		
		while (!file.EndOfFile() && file.ReadLine(buffer, sizeof(buffer)))
		{
			TrimString(buffer);
			
			if (FileExists(buffer))
			{
				AddFileToDownloadsTable(buffer);
				
				if (StrContains(buffer, ".mdl", false) >= 0)
				{
					PrecacheModel(buffer, true);
				}
			}
		}
	}
	
	file.Close();
	
	if (g_EngineVersion == Engine_CSS)
	{
		AddFileToDownloadsTable("materials/models/props_farm/chicken_white.vmt");
		AddFileToDownloadsTable("materials/models/props_farm/chicken_white.vtf");
		AddFileToDownloadsTable("models/chicken/chicken.dx90.vtx");
		AddFileToDownloadsTable("models/chicken/chicken.phy");
		AddFileToDownloadsTable("models/chicken/chicken.vvd");
		AddFileToDownloadsTable(CHICKEN);
	}
	
	PrecacheModel(CHICKEN, true);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

void EnablePlugin()
{
	if (sm_coc_thirdperson.BoolValue && g_EngineVersion == Engine_CSGO)
	{
		SetConVarBool(FindConVar("sv_allow_thirdperson"), true);
	}
	else
	{
		sm_coc_thirdperson.BoolValue = false;
	}
	
	HookEvent("round_start",		Event_RoundStart);
	HookEvent("round_freeze_end",	Event_RoundFreezeEnd);
	HookEvent("round_end",			Event_RoundEnd);
	HookEvent("player_spawn",		Event_Spawn);
	HookEvent("player_death",		Event_Death);
}

void DisablePlugin()
{
	UnhookEvent("round_start",		Event_RoundStart);
	UnhookEvent("round_freeze_end",	Event_RoundFreezeEnd);
	UnhookEvent("round_end",		Event_RoundEnd);
	UnhookEvent("player_spawn",		Event_Spawn);
	UnhookEvent("player_death",		Event_Death);
}

public void ConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == sm_coc_enable)
	{		
		if (StringToInt(newValue) == 1)
		{
			EnablePlugin();
		}
		else
		{
			DisablePlugin();
		}
	}
	else if (cvar == sm_coc_thirdperson)
	{
		if (g_EngineVersion == Engine_CSGO)
		{
			sm_coc_thirdperson.BoolValue = (StringToInt(newValue) == 1) ? true : false;
		}
	}
	else if (cvar == sm_coc_mdl_cluckct)
	{
		sm_coc_mdl_cluckct.GetString(cluckCT, sizeof(cluckCT));
	}
	else if (cvar == sm_coc_mdl_cluckt)
	{
		sm_coc_mdl_cluckt.GetString(cluckT, sizeof(cluckT));
	}
	else if (cvar == sm_coc_mdl_clutchct)
	{
		sm_coc_mdl_clutchct.GetString(clutchCT, sizeof(clutchCT));
	}
	else if (cvar == sm_coc_mdl_clutcht)
	{
		sm_coc_mdl_clutcht.GetString(clutchT, sizeof(clutchT));
	}
	else if (cvar == sm_coc_version)
	{
		sm_coc_version.SetString(PLUGIN_VERSION);
	}
}

public Action Command_Chicken(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_chicken <#userid|name>");
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
		
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
		
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			if (IsValidClient(target_list[i]) && IsPlayerAlive(target_list[i]))
			{
				SetEntityModel(target_list[i], CHICKEN);
				PrintCenterText(target_list[i], "You are a rambo chicken.");
			}
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3])
{
	if (sm_coc_enable.BoolValue && sm_coc_thirdperson.BoolValue && IsValidClient(client) && IsPlayerAlive(client))
	{
		int id = GetClientUserId(client);
		
		if (chickenId == id)
		{
			if ((buttons & IN_RELOAD) && !(lastButton & IN_RELOAD))
			{
				ClientCommand(client, tp ? "firstperson" : "thirdperson");
				tp = !tp;
			}
			lastButton = buttons;
		}
		else if (chickenIdOld == id)
		{
			if ((buttons & IN_RELOAD) && !(lastButtonOld & IN_RELOAD))
			{
				ClientCommand(client, tpOld ? "firstperson" : "thirdperson");
				tpOld = !tpOld;
			}
			lastButtonOld = buttons;
		}
	}
	
	return Plugin_Continue;
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if (sm_coc_enable.BoolValue)
	{
		int id = GetClientUserId(client);
		
		if (chickenId == id || chickenIdOld == id)
		{
			char wname[32]; 
			GetEdictClassname(weapon, wname, sizeof(wname));
			
			if (!((sm_coc_knife.BoolValue && StrEqual(wname, "weapon_knife", false)) || (sm_coc_c4pickup.BoolValue && StrEqual(wname, "weapon_c4", false))))
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	if (sm_coc_enable.BoolValue && IsPlayerAlive(client))
	{
		int id = GetClientUserId(client);
		
		if (chickenId == id || chickenIdOld == id)
		{
			PrintCenterText(client, "Chickens are not allowed to buy.");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	roundTime = event.GetInt("timelimit");
	displayed = false;
	roundend = false;
}

public Action Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	savedTime = GetTime();
	
	if (playerId != 0 && !clutch && !cluck)
	{
		int client = GetClientOfUserId(playerId);
		
		if (client != 0 && IsValidClient(client) && IsPlayerAlive(client))
		{
			IgniteEntity(client, sm_coc_burntime.FloatValue);
			
			if (sm_coc_msg_clutch.BoolValue)
			{
				PrintToChatAll("\x01[COC]\x04 %s has been set on fire for failing to clutch.", playerName);
			}
		}
		playerId = 0;
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{	
	roundend = true;
	
	int winner = event.GetInt("winner");
	
	if (displayed && playerId != 0 && !cluck)
	{
		int client = GetClientOfUserId(playerId);
		
		if (client != 0 && IsValidClient(client))
		{
			if (GetClientTeam(client) == winner)
			{
				if (sm_coc_msg_clutch.BoolValue)
				{
					PrintToChatAll("\x01[COC]\x04 %s clutched the round against %d opponents! (%d HP remaining)", playerName, rivals, GetClientHealth(client));
				}
				clutch = true;
			}
			else
			{
				if (sm_coc_msg_clutch.BoolValue)
				{
					PrintToChatAll("\x01[COC]\x04 %s pathetically failed to clutch against %d opponents.", playerName, rivals);
				}
				clutch = false;
			}
		}
	}
	
	if (sm_coc_winordie.IntValue > 0 && winner > 1)
	{		
		if (event.GetInt("reason") == 0)
		{
			CreateTimer(0.10, C4Explode);
		}
		else
		{
			SlayLosers(winner);
		}
	}
	
	chickenId = 0;
	chickenIdOld = 0;
	displayed = false;
}

public Action C4Explode(Handle timer)
{
	SlayLosers(2);
	return Plugin_Stop;
}

void SlayLosers(int winner)
{
	bool slayed = false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (roundend && IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != winner)
		{
			int id = GetClientUserId(client);
			
			if (GetClientHealth(client) >= sm_coc_winordie.IntValue || id == chickenId || id == chickenIdOld)
			{
				ForcePlayerSuicide(client);
				slayed = true;
			}
			else
			{
				PrintHintText(client, "You have been spared for trying...");
			}
		}
	}
	
	if (sm_coc_msg_windordie.BoolValue && (!displayed || cluck) && slayed)
	{
		PrintToChatAll("\x01[COC]\x04 %s slayed for failing to do the objective in time.", (winner == CS_TEAM_T) ? "Counter-Terrorists" : "Terrorists");
	}
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int spawnId = event.GetInt("userid");
	int client = GetClientOfUserId(spawnId);
	
	if (sm_coc_thirdperson.BoolValue)
	{
		ClientCommand(client, "firstperson");
	}
	
	if ((clutch || cluck) && playerId == spawnId)
	{		
		if (clutch)
		{
			if (sm_coc_hpreward.IntValue != 100)
			{
				SetEntityHealth(client, sm_coc_hpreward.IntValue);
				
				if (sm_coc_msg_clutch.BoolValue)
				{
					PrintToChatAll("\x01[COC]\x04 %s is rewarded with %d HP for clutching.", playerName, sm_coc_hpreward.IntValue);
				}
			}
		}
		else
		{
			SetCluck(client);
			
			if (sm_coc_msg_warn.BoolValue)
			{
				PrintToChatAll("\x01[COC]\x04 %s is still a chicken for this round...", playerName);
			}
		}
		
		playerId = 0;
		clutch = false;
		cluck = false;
	}
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int died = event.GetInt("userid");
	int dclient = GetClientOfUserId(died);
	
	if (g_EngineVersion == Engine_CSGO)
	{
		char dmodel[64];
		GetClientModel(dclient, dmodel, sizeof(dmodel));
		
		if (StrEqual(dmodel, CHICKEN, false))
		{
			SetEntityModel(dclient, FEATHERS);
		}
		
		if (sm_coc_thirdperson.BoolValue)
		{
			ClientCommand(dclient, "firstperson");
		}
	}
	
	if (chickenId != 0)
	{
		int killer = event.GetInt("attacker");
		
		if (killer != died)
		{
			int kclient = GetClientOfUserId(killer);
			bool slayed = false;
			
			if (sm_coc_slaytk.BoolValue && kclient > 0 && (chickenId == died || chickenIdOld == died) && GetClientTeam(kclient) == GetClientTeam(dclient) && IsPlayerAlive(kclient))
			{
				CreateTimer(0.0, SlayTimer, kclient);
				slayed = true;
			}
			
			if (sm_coc_msg_killdeath.BoolValue)
			{
				if (chickenId == died || chickenIdOld == died)
				{
					if (killer == 0)
					{
						PrintToChatAll("\x01[COC]\x04 %s chicken tried to fly.", (chickenIdOld == 0) ? "The" : "A");
					}
					else if ((chickenId == killer && chickenIdOld == died) || (chickenIdOld == killer && chickenId == died))
					{
						PrintToChatAll("\x01[COC]\x04 A chicken has dominated an enemy chicken.");
					}
					else if (slayed)
					{
						char kname[32];
						GetClientName(kclient, kname, sizeof(kname));
						PrintToChatAll("\x01[COC]\x04 %s has been slayed for killing a friendly chicken.", kname);
					}
					else
					{
						PrintToChatAll("\x01[COC]\x04 %s chicken has been killed.", (chickenIdOld == 0) ? "The" : "A");
					}
				}
				else if (chickenId == killer || chickenIdOld == killer)
				{
					char dname[32];
					GetClientName(dclient, dname, sizeof(dname));
					PrintToChatAll("\x01[COC]\x04 %s was killed by a chicken.", dname);
				}
			}
		}
		
		if (chickenId == died)
		{
			chickenId = 0;
		}
	}
	
	if (!displayed && !roundend && EnoughTimeLeft())
	{
		aliveT = 0, aliveCT = 0;
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				switch (GetClientTeam(client))
				{
					case CS_TEAM_T:
					{
						aliveT++;
					}
					case CS_TEAM_CT:
					{
						aliveCT++;
					}
				}
			}
		}
		
		if ((aliveT == 1 && aliveCT >= sm_coc_minrivals.IntValue && aliveCT <= sm_coc_maxrivals.IntValue) || (aliveCT == 1 && aliveT >= sm_coc_minrivals.IntValue && aliveT <= sm_coc_maxrivals.IntValue))
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsValidClient(client) && IsPlayerAlive(client) && !IsFakeClient(client))
				{
					if ((aliveT == 1 && GetClientTeam(client) == CS_TEAM_T) || (aliveCT == 1 && GetClientTeam(client) == CS_TEAM_CT))
					{
						rivals = aliveT + aliveCT - 1;
						
						if (chickenId == GetClientUserId(client) || (sm_coc_random.BoolValue && sm_coc_ratio.IntValue < GetRandomInt(1, 100)))
						{
							displayed = true;
							SetClutch(client);
							
							if (sm_coc_msg_warn.BoolValue)
							{
								PrintToChatAll("\x01[COC]\x04 %s clutch or burn!", (chickenId == playerId) ? "Chicken" : playerName);
							}
						}
						else if (sm_coc_random.BoolValue)
						{
							displayed = true;
							SetCluck(client);
							
							if (sm_coc_msg_warn.BoolValue)
							{
								PrintToChatAll("\x01[COC]\x04 %s has randomly turned into a chicken.", playerName);
							}
						}
						else
						{
							Menu menu = new Menu(MenuHandler);
							menu.SetTitle("Clutch or Cluck?");
							menu.AddItem("clutch", "Clutch");
							menu.AddItem("cluck", "Cluck");
							menu.ExitButton = false;
							displayed = menu.Display(client, 10);
						}
					}
				}
			}
		}
	}
}

public Action SlayTimer(Handle timer, any client)
{
	ForcePlayerSuicide(client);
	return Plugin_Stop;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{	
	switch (action)
	{
		case MenuAction_Select:
		{
			if (displayed && EnoughTimeLeft() && IsPlayerAlive(param1))
			{				
				if (param2 == 0)
				{
					SetClutch(param1);
					
					if (sm_coc_msg_warn.BoolValue)
					{
						PrintToChatAll("\x01[COC]\x04 Clutch or burn initiated by %s.", playerName);
					}
				}
				else
				{
					SetCluck(param1);
					
					if (sm_coc_msg_warn.BoolValue)
					{
						PrintToChatAll("\x01[COC]\x04 %s chose to be a cowardly chicken. Find and kill him!", playerName);
					}
				}
			}
			else
			{
				cluck = false;
				displayed = false;
				PrintHintText(param1, "Too late! You ran out of time...");
			}
		}
		case MenuAction_Cancel:
		{
			if (displayed && EnoughTimeLeft() && IsValidClient(param1) && IsPlayerAlive(param1) && param2 == MenuCancel_Timeout)
			{
				SetCluck(param1);
				
				if (sm_coc_msg_warn.BoolValue)
				{
					PrintToChatAll("\x01[COC]\x04 %s failed to pick an option and has now turned into a chicken.", playerName);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

bool EnoughTimeLeft()
{
	return ((roundTime - (GetTime() - savedTime)) > sm_coc_timeleft.IntValue && roundTime < 999);
}

void SetPlayerInfo(int client)
{
	playerId = GetClientUserId(client);
	GetClientName(client, playerName, sizeof(playerName));
}

void SetClutch(int client)
{
	cluck = false;
	SetPlayerInfo(client);
	
	SetEntityHealth(client, sm_coc_hpbonus.IntValue);
	
	if (chickenId != playerId)
	{
		if (!StrEqual(clutchCT, "") && GetClientTeam(client) == CS_TEAM_CT)
		{
			SetEntityModel(client, clutchCT);
		}
		else if (!StrEqual(clutchT, "") && GetClientTeam(client) == CS_TEAM_T)
		{
			SetEntityModel(client, clutchT);
		}
	}
	
	if (sm_coc_beacon.IntValue == 1 || sm_coc_beacon.IntValue == 3)
	{
		ServerCommand("sm_beacon #%d", GetClientUserId(client));
	}
}

void SetCluck(int client)
{
	cluck = true;
	SetPlayerInfo(client);
	
	if (chickenId != 0 && chickenId != playerId)
	{
		int old = GetClientOfUserId(chickenId);
		
		if (old != 0 && IsValidClient(client) && IsValidClient(old) && IsPlayerAlive(client) && IsPlayerAlive(old))
		{
			PrintToChat(client, "\x01[COC]\x04 Enemy chicken detected!");
			PrintToChat(old, "\x01[COC]\x04 Enemy chicken detected!");
		}
		
		chickenIdOld = chickenId;
	}
	
	chickenId = playerId;
	SetEntityHealth(client, sm_coc_hpchicken.IntValue);
	
	if (!StrEqual(cluckCT, "") && GetClientTeam(client) == CS_TEAM_CT)
	{
		SetEntityModel(client, cluckCT);
	}
	else if (!StrEqual(cluckT, "") && GetClientTeam(client) == CS_TEAM_T)
	{
		SetEntityModel(client, cluckT);
	}
	
	for (int weapon, i = 0; i < 5; i++)
	{
		if (sm_coc_knife.BoolValue && i == 2) { continue; }
		if (sm_coc_c4pickup.BoolValue && i == 4) { continue; }
		
		while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			CS_DropWeapon(client, weapon, true, false);
		}
	}
	
	if (sm_coc_beacon.IntValue == 2 || sm_coc_beacon.IntValue == 3)
	{
		ServerCommand("sm_beacon #%d", GetClientUserId(client));
	}
	else
	{
		PrintCenterText(client, "You are a stealthy chicken!\nPress RELOAD key to toggle view.");
	}
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	return IsClientInGame(client);
}