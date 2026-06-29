/*
TF2x10

Current developer: Wliu
Original developers: Isatis and Invisighost
Config updates: Mr. Blue and Ultimario

Alliedmodders thread: https://forums.alliedmods.net/showthread.php?p=2338136
Github: https://github.com/50DKP/TF2x10
Bitbucket: https://bitbucket.org/umario/tf2x10/src
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <steamtools>
#include <updater>
#undef REQUIRE_PLUGIN
#tryinclude <freak_fortress_2>
#tryinclude <saxtonhale>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define PLUGIN_NAME			"Multiply a Weapon's Stats by 10"
#define PLUGIN_AUTHOR		"The TF2x10 group"
#define PLUGIN_VERSION		"1.7.4"
#define PLUGIN_CONTACT		"http://steamcommunity.com/group/tf2x10/"
#define PLUGIN_DESCRIPTION	"It's in the name! Also known as TF2x10 or TF20."

#define UPDATE_URL			"http://50dkp.github.io/TF2x10/addons/sourcemod/update.txt"

#define KUNAI_DAMAGE			2100
#define DALOKOH_MAXHEALTH		800
#define DALOKOH_HEALTHPERSEC	150
#define DALOKOH_LASTHEALTH		50
#define MAX_CURRENCY			30000

static const float g_fBazaarRates[] =
{
	16.5, //seconds for 0 heads
	8.25, //seconds for 1 head
	3.3, //seconds for 2 heads
	1.32, //seconds for 3 heads
	0.66, //seconds for 4 heads
	0.44, //seconds for 5 heads
	0.33 //seconds for 6+ heads
};

int buildingsDestroyed[MAXPLAYERS + 1];
int cabers[MAXPLAYERS + 1];
int dalokohsSeconds[MAXPLAYERS + 1];
int dalokohs[MAXPLAYERS + 1];
float dalokohsTimer[MAXPLAYERS + 1];
//int headsTaken[MAXPLAYERS + 1];
int razorbacks[MAXPLAYERS + 1];
int revengeCrits[MAXPLAYERS + 1];
int amputatorHealing[MAXPLAYERS + 1];

bool aprilFools;
bool aprilFoolsOverride;
bool ff2Running;
bool hiddenRunning;
bool vshRunning;

bool hasCaber[MAXPLAYERS + 1];
bool hasManmelter[MAXPLAYERS + 1];
bool hasBazooka[MAXPLAYERS + 1];
bool takesHeads[MAXPLAYERS + 1];
bool chargingClassic[MAXPLAYERS + 1];

float chargeBegin[MAXPLAYERS + 1];

Handle hudText;
Handle equipWearable;
StringMap itemInfoTrie;
TopMenu globalTopMenu;

char selectedMod[16] = "default";

ConVar cvarEnabled;
ConVar cvarGameDesc;
ConVar cvarAutoUpdate;
//ConVar cvarHeadCap;
ConVar cvarHeadScaling;
ConVar cvarHeadScalingCap;
ConVar cvarHealthCap;
ConVar cvarIncludeBots;
ConVar cvarCritsFJ;
ConVar cvarCritsDiamondback;
ConVar cvarCritsManmelter;
ConVar cvarZatoichiSheathThreshold;
ConVar cvarFeignDeathDuration;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
}

/******************************************************************

Plugin Initialization

******************************************************************/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char gameFolder[8];
	GetGameFolderName(gameFolder, sizeof(gameFolder));

	if(StrContains(gameFolder, "tf") < 0)
	{
		strcopy(error, err_max, "This plugin can only run on Team Fortress 2... hence TF2x10!");
		return APLRes_Failure;
	}

	MarkNativeAsOptional("Steam_SetGameDescription");
	MarkNativeAsOptional("VSH_IsSaxtonHaleModeEnabled");
	MarkNativeAsOptional("VSH_GetSaxtonHaleUserId");
	MarkNativeAsOptional("FF2_IsFF2Enabled");
	MarkNativeAsOptional("FF2_GetBossCharge");
	MarkNativeAsOptional("FF2_GetBossIndex");
	MarkNativeAsOptional("FF2_GetBossTeam");
	MarkNativeAsOptional("FF2_SetBossCharge");

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("tf2x10_version", PLUGIN_VERSION, "TF2x10 version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cvarAutoUpdate = CreateConVar("tf2x10_autoupdate", "1", "Tells Updater to automatically update this plugin.  0 = off, 1 = on.", _, true, 0.0, true, 1.0);
	cvarCritsDiamondback = CreateConVar("tf2x10_crits_diamondback", "10", "Number of crits after successful sap with Diamondback equipped.", _, true, 0.0, false);
	cvarCritsFJ = CreateConVar("tf2x10_crits_fj", "10", "Number of crits after Frontier kill or for buildings. Half this for assists.", _, true, 0.0, false);
	cvarCritsManmelter = CreateConVar("tf2x10_crits_manmelter", "10", "Number of crits after Manmelter extinguishes player.", _, true, 0.0, false);
	cvarEnabled = CreateConVar("tf2x10_enabled", "1", "Toggle TF2x10. 0 = disable, 1 = enable", _, true, 0.0, true, 1.0);
	cvarGameDesc = CreateConVar("tf2x10_gamedesc", "1", "Toggle setting game description. 0 = disable, 1 = enable.", _, true, 0.0, true, 1.0);
	//cvarHeadCap = CreateConVar("tf2x10_headcap", "40", "The number of heads before the wielder stops gaining health and speed bonuses", _, true, 4.0);
	cvarHeadScaling = CreateConVar("tf2x10_headscaling", "1", "Enable any decapitation weapon (eyelander etc) to grow their head as they gain heads. 0 = off, 1 = on.", _, true, 0.0, true, 1.0);
	cvarHeadScalingCap = CreateConVar("tf2x10_headscalingcap", "6.0", "The number of heads before head scaling stops growing their head. 6.0 = 24 heads.", _, true, 0.0, false);
	cvarHealthCap = CreateConVar("tf2x10_healthcap", "2100", "The max health a player can have. -1 to disable.", _, true, -1.0, false);
	cvarIncludeBots = CreateConVar("tf2x10_includebots", "0", "1 allows bots to receive TF2x10 weapons, 0 disables this.", _, true, 0.0, true, 1.0);
	cvarZatoichiSheathThreshold = CreateConVar("tf2x10_zatoichi_sheath_threshold", "500", "Minimum required health needed in order to sheath the Half-Zatoichi.  Damage will be 500 regardless.", _, true, 0.0);
	cvarFeignDeathDuration = FindConVar("tf_feign_death_duration");

	cvarEnabled.AddChangeHook(OnConVarChanged);
	cvarAutoUpdate.AddChangeHook(OnConVarChanged);

	AutoExecConfig(true, "plugin.tf2x10");

	RegAdminCmd("sm_tf2x10_disable", Command_Disable, ADMFLAG_CONVARS);
	RegAdminCmd("sm_tf2x10_enable", Command_Enable, ADMFLAG_CONVARS);
	RegAdminCmd("sm_tf2x10_getmod", Command_GetMod, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tf2x10_recache", Command_Recache, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tf2x10_setmod", Command_SetMod, ADMFLAG_CHEATS);
	RegAdminCmd("sm_tf2x10_april_fools", Command_AprilFools, ADMFLAG_CHEATS);
	RegConsoleCmd("sm_x10group", Command_Group);

	HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_builtobject", OnObjectBuilt, EventHookMode_Post);
	HookEvent("object_destroyed", OnObjectDestroyed, EventHookMode_Post);
	HookEvent("object_removed", OnObjectRemoved, EventHookMode_Post);
	HookEvent("player_healed", OnPlayerHealed, EventHookMode_Post);
	HookEvent("player_extinguished", OnPlayerExtinguished, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Post);
	HookEvent("teamplay_restart_round", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_win_panel", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Post);
	HookEvent("mvm_pickup_currency", OnPickupMVMCurrency, EventHookMode_Pre);

	HookUserMessage(GetUserMessageId("PlayerShieldBlocked"), OnPlayerShieldBlocked);

	Handle config = LoadGameConfigFile("tf2items.randomizer");
	if(config == null)
	{
		SetFailState("Could not find 'gamedata/tf2.randomizer.txt'. Get the file from [TF2Items] Randomizer.");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "CTFPlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	equipWearable = EndPrepSDKCall();
	config.Close();

	if(equipWearable == null)
	{
		SetFailState("Failed to set up EquipWearable sdkcall. Get a new 'gamedata/tf2items.randomizer.txt' file from [TF2Items] Randomizer.");
	}

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client) && IsClientInGame(client))
		{
			UpdateVariables(client);
		}
	}

	TopMenu topmenu = GetAdminTopMenu();
	if(LibraryExists("adminmenu") && topmenu != null)
	{
		OnAdminMenuReady(topmenu);
	}

	hudText = CreateHudSynchronizer();
	itemInfoTrie = CreateTrie();
}

public void OnConfigsExecuted()
{
	if(!cvarEnabled.BoolValue)
	{
		return;
	}

	if(FindConVar("aw2_version") != null)
	{
		SetFailState("TF2x10 is incompatible with Advanced Weaponiser.");
	}

	switch(LoadFileIntoTrie("default", "tf2x10_base_items"))
	{
		case -1:
		{
			SetFailState("Could not find configs/x10.default.txt. Aborting.");
		}
		case -2:
		{
			SetFailState("Your configs/x10.default.txt seems to be corrupt. Aborting.");
		}
		default:
		{
			CreateTimer(330.0, Timer_ServerRunningX10, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	if(LibraryExists("updater") && cvarAutoUpdate.BoolValue)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == cvarEnabled)
	{
		if(cvarEnabled.BoolValue)
		{
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					ResetVariables(client);
					SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
					SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
					SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
				}
			}

			if(FindConVar("sm_hidden_enabled"))
			{
				hiddenRunning = FindConVar("sm_hidden_enabled").BoolValue;
			}
			else
			{
				hiddenRunning = false;
			}

			#if defined _FF2_included
			ff2Running = LibraryExists("freak_fortress_2") ? FF2_IsFF2Enabled() : false;
			#else
			ff2Running = false;
			#endif

			#if defined _VSH_included
			vshRunning = LibraryExists("saxtonhale") ? VSH_IsSaxtonHaleModeEnabled() : false;
			#else
			vshRunning = false;
			#endif

			itemInfoTrie.Clear();
			LoadFileIntoTrie("default", "tf2x10_base_items");

			if(ff2Running || vshRunning)
			{
				selectedMod = "vshff2";
				LoadFileIntoTrie(selectedMod);
			}

			if(aprilFools)
			{
				selectedMod = "aprilfools";
				LoadFileIntoTrie(selectedMod);
			}
		}
		else
		{
			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					ResetVariables(client);
					SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
					SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
					SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
					SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
				}
			}
			itemInfoTrie.Clear();
		}
		SetGameDescription();
	}
	else if(convar == cvarAutoUpdate)
	{
		cvarAutoUpdate.BoolValue ? Updater_AddPlugin(UPDATE_URL) : Updater_RemovePlugin();
	}
}

void SetGameDescription()
{
	char description[16];
	GetGameDescription(description, sizeof(description));

	if(cvarEnabled.BoolValue && cvarGameDesc.BoolValue && StrEqual(description, "Team Fortress"))
	{
		Format(description, sizeof(description), "TF2x10 v%s", PLUGIN_VERSION);
		Steam_SetGameDescription(description);
	}
	else if((!cvarEnabled.BoolValue || !cvarGameDesc.BoolValue) && StrContains(description, "TF2x10 ") != -1)
	{
		Steam_SetGameDescription("Team Fortress");
	}
}

public void OnAdminMenuReady(Handle topmenu)
{
	if(topmenu == globalTopMenu)
	{
		return;
	}

	globalTopMenu = TopMenu.FromHandle(topmenu);

	TopMenuObject player_commands = globalTopMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);

	if(player_commands != INVALID_TOPMENUOBJECT)
	{
		globalTopMenu.AddItem("TF2x10: Recache Weapons", AdminMenu_Recache, player_commands, "sm_tf2x10_recache", ADMFLAG_GENERIC);
	}
}

int LoadFileIntoTrie(const char[] rawname, const char[] basename = "")
{
	char config[64];
	char weapon[64];
	char attribute[64];
	char value[64];
	BuildPath(Path_SM, config, sizeof(config), "configs/x10.%s.txt", rawname);
	char tmpID[64];
	char finalbasename[32];
	int i;

	strcopy(finalbasename, sizeof(finalbasename), StrEqual(basename, "") ? rawname : basename);

	KeyValues kv = CreateKeyValues(finalbasename);
	if(kv.ImportFromFile(config))
	{
		kv.GetSectionName(config, sizeof(config));
		if(StrEqual(config, finalbasename))
		{
			if(kv.GotoFirstSubKey())
			{
				do
				{
					i = 0;

					kv.GetSectionName(weapon, sizeof(weapon));
					if(kv.GotoFirstSubKey(false))
					{
						do
						{
							kv.GetSectionName(attribute, sizeof(attribute));
							Format(tmpID, sizeof(tmpID), "%s__%s_%i_name", rawname, weapon, i);
							itemInfoTrie.SetString(tmpID, attribute);

							kv.GetString(NULL_STRING, value, sizeof(value));
							Format(tmpID, sizeof(tmpID), "%s__%s_%i_val", rawname, weapon, i);
							itemInfoTrie.SetString(tmpID, value);

							i++;
						}
						while(kv.GotoNextKey(false));
						kv.GoBack();
					}

					Format(tmpID, sizeof(tmpID), "%s__%s_size", rawname, weapon);
					itemInfoTrie.SetValue(tmpID, i);
				}
				while(kv.GotoNextKey());
				kv.GoBack();

				itemInfoTrie.SetValue(weapon, 1);
			}
		}
		else
		{
			kv.Close();
			return -2;
		}
	}
	else
	{
		kv.Close();
		return -1;
	}
	kv.Close();
	return 1;
}

public Action Timer_ServerRunningX10(Handle hTimer)
{
	if(!cvarEnabled.BoolValue)
	{
		return Plugin_Stop;
	}

	SetGameDescription();

	PrintToChatAll("\x01[\x07FF0000TF2\x070000FFx10\x01] Mod by \x07FF5C33UltiMario\x01 and \x073399FFMr. Blue\x01. Plugin development by \x079EC34FWliu\x01 (based off of \x0794DBFFI\x01s\x0794DBFFa\x01t\x0794DBFFi\x01s's and \x075C5C8AInvisGhost\x01's code).");
	PrintToChatAll("\x01Join our Steam group for Hale x10, Randomizer x10 and more by typing \x05/x10group\x01!");
	return Plugin_Continue;
}

/******************************************************************

SourceMod Admin Commands

******************************************************************/

public void AdminMenu_Recache(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if(cvarEnabled.BoolValue)
	{
		switch(action)
		{
			case TopMenuAction_DisplayOption:
			{
				Format(buffer, maxlength, "TF2x10 Recache Weapons");
			}

			case TopMenuAction_SelectOption:
			{
				Command_Recache(param, 0);
			}
		}
	}
}

public Action Command_Enable(int client, int args)
{
	if(!cvarEnabled.BoolValue)
	{
		ServerCommand("tf2x10_enabled 1");
		ReplyToCommand(client, "[TF2x10] Multiply A Weapon's Stats by 10 Plugin is now enabled.");
	}
	else
	{
		ReplyToCommand(client, "[TF2x10] Multiply A Weapon's Stats by 10 Plugin is already enabled.");
	}
	return Plugin_Handled;
}

public Action Command_Disable(int client, int args)
{
	if(cvarEnabled.BoolValue)
	{
		ServerCommand("tf2x10_enabled 0");
		ReplyToCommand(client, "[TF2x10] Multiply A Weapon's Stats by 10 Plugin is now disabled.");
	}
	else
	{
		ReplyToCommand(client, "[TF2x10] Multiply A Weapon's Stats by 10 Plugin is already disabled.");
	}
	return Plugin_Handled;
}

public Action Command_GetMod(int client, int args)
{
	if(cvarEnabled.BoolValue)
	{
		ReplyToCommand(client, "[TF2x10] This mod is loading primarily from configs/x10.%s.txt.", selectedMod);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_Group(int client, int args)
{
	KeyValues kv = CreateKeyValues("data");
	kv.SetString("title", "TF2x10 Steam Group");
	kv.SetString("msg", "http://www.steamcommunity.com/groups/tf2x10");
	kv.SetNum("customsvr", 1);
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	ShowVGUIPanel(client, "info", kv, true);
	kv.Close();

	return Plugin_Handled;
}

public Action Command_Recache(int client, int args)
{
	if(cvarEnabled.BoolValue)
	{
		switch(LoadFileIntoTrie("default", "tf2x10_base_items"))
		{
			case -1:
			{
				ReplyToCommand(client, "[TF2x10] Could not find configs/x10.default.txt. Please check and try again.");
			}
			case -2:
			{
				ReplyToCommand(client, "[TF2x10] Your configs/x10.default.txt seems to be corrupt. Please check and try again.");
			}
			default:
			{
				ReplyToCommand(client, "[TF2x10] Weapons recached.");
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_SetMod(int client, int args)
{
	if(cvarEnabled.BoolValue)
	{
		if(args != 1)
		{
			ReplyToCommand(client, "[TF2x10] Please specify a mod name to load. Usage: sm_tf2x10_setmod <name>");
			return Plugin_Handled;
		}

		int uselessVar;
		GetCmdArg(1, selectedMod, sizeof(selectedMod));

		if(!StrEqual(selectedMod, "default") && !itemInfoTrie.GetValue(selectedMod, uselessVar))
		{
			switch(LoadFileIntoTrie(selectedMod))
			{
				case -1:
				{
					ReplyToCommand(client, "[TF2x10] Could not find configs/x10.%s.txt. Please check and try again.", selectedMod);
					selectedMod = "default";
					return Plugin_Handled;
				}
				case -2:
				{
					ReplyToCommand(client, "[TF2x10] Your configs/x10.%s.txt seems to be corrupt: first line does not match filename.", selectedMod);
					selectedMod = "default";
					return Plugin_Handled;
				}
			}
		}

		if(!StrEqual(selectedMod, "default"))
		{
			ReplyToCommand(client, "[TF2x10] Now loading from configs/x10.%s.txt, defaulting to configs/x10.default.txt.", selectedMod);
		}
		else
		{
			ReplyToCommand(client, "[TF2x10] Now loading from configs/x10.default.txt.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_AprilFools(int client, int args)
{
	if(aprilFools)
	{
		aprilFools = false;
		ReplyToCommand(client, "[TF2x10] April Fool's mode has been disabled!");
	}
	else
	{
		aprilFools = true;
		ReplyToCommand(client, "[TF2x10] April Fool's mode has been enabled!");
	}
	aprilFoolsOverride = true;
	return Plugin_Continue;
}

/******************************************************************

SourceMod Map/Library Events

******************************************************************/

public void OnAllPluginsLoaded()
{
	if(FindConVar("sm_hidden_enabled"))
	{
		hiddenRunning = FindConVar("sm_hidden_enabled").BoolValue;
	}
	else
	{
		hiddenRunning = false;
	}

	#if defined _FF2_included
	ff2Running = LibraryExists("freak_fortress_2") ? FF2_IsFF2Enabled() : false;
	#else
	ff2Running = false;
	#endif

	#if defined _VSH_included
	vshRunning = LibraryExists("saxtonhale") ? VSH_IsSaxtonHaleModeEnabled() : false;
	#else
	vshRunning = false;
	#endif

	if(ff2Running || vshRunning)
	{
		selectedMod = "vshff2";
		LoadFileIntoTrie(selectedMod);
	}

	if(aprilFools)
	{
		selectedMod = "aprilfools";
		LoadFileIntoTrie(selectedMod);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "updater") && cvarAutoUpdate.BoolValue)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	else if(StrEqual(name, "freak_fortress_2"))
	{
		#if defined _FF2_included
		ff2Running = FF2_IsFF2Enabled();
		#endif
	}
	else if(StrEqual(name, "saxtonhale"))
	{
		#if defined _VSH_included
		vshRunning = VSH_IsSaxtonHaleModeEnabled();
		#endif
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "freak_fortress_2"))
	{
		ff2Running = false;
	}
	else if(StrEqual(name, "saxtonhale"))
	{
		vshRunning = false;
	}
	else if(StrEqual(name, "updater"))
	{
		Updater_RemovePlugin();
	}
}

public void OnMapStart()
{
	if(cvarEnabled.BoolValue)
	{
		SetGameDescription();
	}
}

public void OnMapEnd()
{
	char description[16];
	GetGameDescription(description, sizeof(description));

	if(cvarEnabled.BoolValue && cvarGameDesc.BoolValue && StrContains(description, "TF2x10 ") != -1)
	{
		Steam_SetGameDescription("Team Fortress");
	}
}

/******************************************************************

Player Connect/Disconnect & Round End

******************************************************************/

public void OnClientPutInServer(int client)
{
	if(cvarEnabled.BoolValue)
	{
		ResetVariables(client);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		SDKHook(client, SDKHook_PreThink, OnPreThink);
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
}

public void OnClientDisconnect(int client)
{
	if(cvarEnabled.BoolValue)
	{
		ResetVariables(client);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(cvarEnabled.BoolValue)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			ResetVariables(client);
		}
	}
	return Plugin_Continue;
}

/******************************************************************

Gameplay: Event-Specific

******************************************************************/

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(!cvarEnabled.BoolValue)
	{
		return;
	}

	int weapon = IsValidClient(client) ? GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") : -1;
	int index = IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;

	if(condition == TFCond_Zoomed && index == 402)  //Bazaar Bargain
	{
		chargeBegin[client] = GetGameTime();
		CreateTimer(0.0, Timer_BazaarCharge, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	if(condition == TFCond_Taunting && (index == 159 || index == 433) && !vshRunning && !ff2Running && !hiddenRunning)  //Dalokohs Bar, Fishcake
	{
		CreateTimer(1.0, Timer_DalokohX10, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(cvarEnabled.BoolValue)
	{
		if(condition == TFCond_Zoomed && chargeBegin[client])
		{
			chargeBegin[client] = 0.0;
		}

		if(condition == TFCond_Taunting && dalokohsSeconds[client])
		{
			dalokohsSeconds[client] = 0;
		}
	}
}

public Action Timer_BazaarCharge(Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!IsValidClient(client) || !IsPlayerAlive(client) || !TF2_IsPlayerInCondition(client, TFCond_Zoomed))
	{
		return Plugin_Stop;
	}

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(weapon))
	{
		return Plugin_Stop;
	}

	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if(index != 402)  //Bazaar Bargain
	{
		return Plugin_Stop;
	}

	int heads = GetEntProp(client, Prop_Send, "m_iDecapitations");
	if(heads > sizeof(g_fBazaarRates) - 1)
	{
		heads = sizeof(g_fBazaarRates) - 1;
	}

	float charge = 150 * (GetGameTime() - chargeBegin[client]) / g_fBazaarRates[heads];
	if(charge > 150)
	{
		charge = 150.0;
	}

	SetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage", charge);
	return Plugin_Continue;
}

public Action Timer_DalokohX10(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || !TF2_IsPlayerInCondition(client, TFCond_Taunting))
	{
		dalokohsTimer[client] = 0.0;
		return Plugin_Stop;
	}

	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!IsValidEntity(weapon))
	{
		return Plugin_Stop;
	}

	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if(index != 159 && index != 433)  //Dalokohs Bar, Fishcake
	{
		return Plugin_Stop;
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(!IsValidEntity(weapon))
	{
		return Plugin_Stop;
	}

	index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

	int health = GetClientHealth(client);
	int newHealth, maxHealth;
	if(index == 310)  //Warrior's Spirit
	{
		maxHealth = DALOKOH_MAXHEALTH - 200;  //Warrior's Spirit subtracts 200 health
	}
	else
	{
		maxHealth = DALOKOH_MAXHEALTH;
	}

	dalokohsSeconds[client]++;
	if(dalokohsSeconds[client] == 1)
	{
		if(!dalokohs[client])
		{
			dalokohs[client] = maxHealth;
			SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
		}
		dalokohsTimer[client] = GetEngineTime() + 30.0;
		//TF2Attrib_SetByName(secondary, "hidden maxhealth non buffed", float(DALOKOH_MAXHEALTH - 300));  //Disabled due to Invasion crashes
	}
	else if(dalokohsSeconds[client] == 4)
	{
		newHealth = health + DALOKOH_LASTHEALTH;
		if(newHealth > maxHealth)
		{
			newHealth = maxHealth;
		}
		TF2_SetHealth(client, newHealth);
	}

	if(health < DALOKOH_MAXHEALTH && dalokohsSeconds[client] >= 1 && dalokohsSeconds[client] <= 3)
	{
		newHealth = dalokohsSeconds[client] == 3 ? health + DALOKOH_HEALTHPERSEC : health + DALOKOH_HEALTHPERSEC - 50;
		if(newHealth > maxHealth)
		{
			newHealth = maxHealth;
		}
		TF2_SetHealth(client, newHealth);
	}
	return Plugin_Continue;
}

public void OnGameFrame()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsValidClient(client) || !IsPlayerAlive(client))
		{
			continue;
		}

		if(takesHeads[client])
		{
			int heads = GetEntProp(client, Prop_Send, "m_iDecapitations");
			/*if(heads > cvarHeadCap.IntValue)
			{
				heads = cvarHeadCap.IntValue;
			}

			if(heads > 4)
			{
				float speed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
				if(heads != headsTaken[client] && !TF2_IsPlayerInCondition(client, TFCond_Charging))  //Don't change the speed if they're charging
				{
					speed += heads * 22.4;  //Speed increases by 22.4 each head
					if(speed > 520.0)  //520 is the max speed: don't go above it :P
					{
						speed = 520.0;
					}

					headsTaken[client] = heads;
					PrintToChatAll("[TF2x10] New speed: %f", speed);
				}
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed);
			}*/

			if(cvarHeadScaling.BoolValue)
			{
				float fPlayerHeadScale = 1.0 + heads / 4.0;
				if(fPlayerHeadScale <= (aprilFools ? 9999.0 : cvarHeadScalingCap.FloatValue))  //April Fool's 2015: Heads keep getting bigger!
				{
					SetEntPropFloat(client, Prop_Send, "m_flHeadScale", fPlayerHeadScale);
				}
				else
				{
					SetEntPropFloat(client, Prop_Send, "m_flHeadScale", cvarHeadScalingCap.FloatValue);
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!cvarEnabled.BoolValue || !IsValidClient(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int index = IsValidEntity(activeWep) ? GetEntProp(activeWep, Prop_Send, "m_iItemDefinitionIndex") : -1;

	if(buttons & IN_ATTACK && index == 1098)  //Classic
	{
		chargingClassic[client] = true;
	}
	else
	{
		chargingClassic[client] = false;
	}

	if(index == 307)  //Ullapool Caber
	{
		int detonated = GetEntProp(activeWep, Prop_Send, "m_iDetonated");
		if(!detonated)
		{
			SetHudTextParams(0.0, 0.0, 0.5, 255, 255, 255, 255, 0, 0.1, 0.1, 0.2);
			ShowSyncHudText(client, hudText, "Cabers: %i", cabers[client]);
		}

		if(cabers[client] > 1 && detonated == 1)
		{
			SetEntProp(activeWep, Prop_Send, "m_iDetonated", 0);
			cabers[client]--;
		}
	}

	else if(index == 19 || index == 206 || index == 1007) //Grenade Launcher, Strange Grenade Launcher, Festive Grenade Launcher
	{
		if(GetEntProp(activeWep, Prop_Send, "m_iClip1") >= 10)
		{
			buttons &= ~IN_ATTACK;
		}
	}

	if(razorbacks[client] > 1)
	{
		SetHudTextParams(0.0, 0.0, 0.5, 255, 255, 255, 255, 0, 0.1, 0.1, 0.2);
		ShowSyncHudText(client, hudText, "Razorbacks: %i", razorbacks[client]);
	}

	if(hasManmelter[client])
	{
		int crits = GetEntProp(client, Prop_Send, "m_iRevengeCrits");
		if(crits > revengeCrits[client])
		{
			int newCrits = ((crits - revengeCrits[client]) * cvarCritsManmelter.IntValue) + crits - 1;
			SetEntProp(client, Prop_Send, "m_iRevengeCrits", newCrits);

			revengeCrits[client] = newCrits;
		}
		else
		{
			revengeCrits[client] = crits;
		}
	}
	return Plugin_Continue;
}

public Action OnGetMaxHealth(int client, int &maxHealth)
{
	if(cvarEnabled.BoolValue)
	{
		if(dalokohs[client])
		{
			maxHealth = dalokohs[client];
			return Plugin_Changed;
		}

		/*int heads = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if(heads > cvarHeadCap.IntValue)
		{
			heads = cvarHeadCap.IntValue;
		}

		if(heads > 4)
		{
			maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth") + heads * 15;
			return Plugin_Changed;
		}*/
	}
	return Plugin_Continue;
}

public Action OnPlayerExtinguished(Handle event, const char[] name, bool dontBroadcast)
{
	if(cvarEnabled.BoolValue)
	{
		int healer = GetEventInt(event, "healer");  //NOTE: This IS the client index, unlike most events.  Not a typo!
		if(IsValidClient(healer))
		{
			int weapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(weapon))
			{
				char classname[64];
				GetEdictClassname(weapon, classname, sizeof(classname));
				if(StrEqual(classname, "tf_weapon_flamethrower") || StrEqual(classname, "tf_weapon_flaregun_revenge"))
				{
					int health = GetClientHealth(healer);
					int newhealth = health + 180;  //TF2 already adds 20 by default
					int max = GetEntProp(healer, Prop_Data, "m_iMaxHealth");
					if(newhealth <= max)
					{
						SetEntityHealth(healer, newhealth);
					}
					else if(health <= max)
					{
						SetEntityHealth(healer, max);
					}
				}
				/*else
				{
					char classname[64];
					GetEdictClassname(weapon, classname, sizeof(classname));
					if(StrEqual(classname, "tf_weapon_jar_milk") || StrEqual(classname, "tf_weapon_jar"))
					{
						SetEntProp(weapon, Prop_Data, "m_iClip2", GetEntProp(weapon, Prop_Data, "m_iClip2") + 2);
						SetEntProp(healer, Prop_Data, "m_iAmmo", 1, _, GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"));
					}
				}*/
			}
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerHealed(Handle event, const char[] name, bool dontBroadcast)
{
	if(!cvarEnabled.BoolValue)
	{
		return Plugin_Continue;
	}

	int healer = GetClientOfUserId(GetEventInt(event, "healer"));
	if(IsValidClient(healer))
	{
		int weapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
		if(weapon == GetPlayerWeaponSlot(healer, TFWeaponSlot_Melee))
		{
			amputatorHealing[healer] += GetEventInt(event, "amount");
			if(amputatorHealing[healer] >= 49)  //From the TF2 wiki
			{
				amputatorHealing[healer] -= 49;
				int medigun=GetPlayerWeaponSlot(healer, TFWeaponSlot_Secondary);
				if(IsValidEntity(medigun))
				{
					char medigunClassname[64];
					GetEdictClassname(medigun, medigunClassname, sizeof(medigunClassname));
					if(StrEqual(medigunClassname, "tf_weapon_medigun"))
					{
						float uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
						if(uber + 0.1 < 1.0)
						{
							//TF2 already adds 1% per 49 damage, so add 9 to that to make it x10
							SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber + 0.09);
						}
						else if(uber < 1.0)
						{
							SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 1.0);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnObjectDeflected(Handle event, const char[] name, bool dontBroadcast)
{
	#if defined _FF2_included
	if(cvarEnabled.BoolValue && ff2Running && !GetEventInt(event, "weaponid"))  //We only want a weaponid of 0 (a client)
	{
		int client = GetClientOfUserId(GetEventInt(event, "ownerid"));
		int boss = FF2_GetBossIndex(client);

		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int index = IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;

		if(boss != -1 && (index == 40 || index == 1146)) //Backburner
		{
			float charge = FF2_GetBossCharge(boss, 0) + 63.0; //Work with FF2's deflect to set to 70 in total instead of 7
			if(charge > 100.0)
			{
				FF2_SetBossCharge(boss, 0, 100.0);
			}
			else
			{
				FF2_SetBossCharge(boss, 0, charge);
			}
		}
	}
	#endif
	return Plugin_Continue;
}

/**
 * Event parameters:
 * @param userid	Client userid
 * @param object	See TFObjectType
 * @param index		Entity index of the object built
 */
public Action OnObjectBuilt(Handle event, const char[] name, bool dontBroadcast)
{
	if(cvarEnabled.BoolValue)
	{
		SDKHook(GetEventInt(event, "index"), SDKHook_OnTakeDamage, OnTakeDamage_Object);

		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(view_as<TFObjectType>(GetEventInt(event, "object")) == TFObject_Teleporter
		&& GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_iItemDefinitionIndex") == 589) // Eureka Effect
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", 200, 4, 3); // Building teleporters gives you max metal again!
		}
	}
	return Plugin_Continue;
}

public Action OnObjectDestroyed(Handle event, const char[] name, bool dontBroadcast)
{
	if(!cvarEnabled.BoolValue)
	{
		return Plugin_Continue;
	}

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int primary = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
	int critsDiamondback = cvarCritsDiamondback.IntValue;

	if(IsValidClient(attacker) && IsPlayerAlive(attacker) && critsDiamondback > 0 && IsValidEntity(primary) && WeaponHasAttribute(attacker, primary, "sapper kills collect crits"))
	{
		char weapon[32];
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		if(StrContains(weapon, "sapper") != -1 || StrEqual(weapon, "recorder"))
		{
			SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits") + critsDiamondback - 1);
		}
	}

	SDKUnhook(GetEventInt(event, "index"), SDKHook_OnTakeDamage, OnTakeDamage_Object);
	return Plugin_Continue;
}

public Action OnObjectRemoved(Handle event, const char[] name, bool dontBroadcast)
{
	if(!cvarEnabled.BoolValue)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}

	if(WeaponHasAttribute(client, weapon, "mod sentry killed revenge") && view_as<TFObjectType>(GetEventInt(event, "objecttype")) == TFObject_Sentry)
	{
		int crits = GetEntProp(client, Prop_Send, "m_iRevengeCrits") + buildingsDestroyed[client];
		SetEntProp(client, Prop_Send, "m_iRevengeCrits", crits);
		buildingsDestroyed[client] = 0;
	}

	SDKUnhook(GetEventInt(event, "index"), SDKHook_OnTakeDamage, OnTakeDamage_Object);
	return Plugin_Continue;
}

public Action OnPickupMVMCurrency(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetEventInt(event, "player");
	int dollars = GetEventInt(event, "currency");
	int newDollahs = 0;

	if(GetEntProp(client, Prop_Send, "m_nCurrency") < MAX_CURRENCY)
	{
		newDollahs = RoundToNearest(float(dollars) / 3.16);
	}

	SetEventInt(event, "currency", newDollahs);

	return Plugin_Continue;
}

public Action TF2_OnIsHolidayActive(TFHoliday holiday, bool &result)
{
	if(holiday == TFHoliday_AprilFools && !aprilFoolsOverride)
	{
		aprilFools = result;
	}
	return Plugin_Continue;
}

/******************************************************************

Gameplay: Damage and Death Only

******************************************************************/

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(!cvarEnabled.BoolValue)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int inflictor_entindex = GetEventInt(event, "inflictor_entindex");
	int activewep = IsValidClient(attacker) ? GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon") : -1;
	int weaponid = IsValidEntity(activewep) ? GetEntProp(activewep, Prop_Send, "m_iItemDefinitionIndex") : -1;
	int customKill = GetEventInt(event, "customkill");

	if(aprilFools && weaponid == 356)  //April Fool's 2015: Kunai gives health on ALL kills
	{
		TF2_SetHealth(attacker, KUNAI_DAMAGE);
	}
	else if(weaponid == 317)
	{
		TF2_SpawnMedipack(client);
	}
	else if(customKill == TF_CUSTOM_BACKSTAB && !hiddenRunning)
	{
		if(weaponid == 356)
		{
			TF2_SetHealth(attacker, KUNAI_DAMAGE);
		}
		if(IsValidClient(attacker))
		{
			int primWep = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
			if(IsValidEntity(primWep) && WeaponHasAttribute(attacker, primWep, "sapper kills collect crits"))
			{
				int crits = GetEntProp(attacker, Prop_Send, "m_iRevengeCrits") + cvarCritsDiamondback.IntValue - 1;
				SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", crits);
			}
		}
	}

	if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, cvarFeignDeathDuration.IntValue * 10.0);  //Speed boost * 10
	}

	if(IsValidEntity(inflictor_entindex))
	{
		char inflictorName[32];
		GetEdictClassname(inflictor_entindex, inflictorName, sizeof(inflictorName));

		if(StrContains(inflictorName, "sentry") >= 0)
		{
			int critsFJ = cvarCritsFJ.IntValue;

			if(GetEventInt(event, "assister") < 1)
			{
				buildingsDestroyed[attacker] = buildingsDestroyed[attacker] + critsFJ - 2;
			}
			else
			{
				buildingsDestroyed[attacker] = buildingsDestroyed[attacker] + RoundToNearest(critsFJ / 2.0) - 2;
			}
		}
	}

	if(dalokohs[client])
	{
		SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
		if(dalokohsTimer[client])
		{
			dalokohsTimer[client] = 0.0;
		}
	}

	if(takesHeads[client])
	{
		SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	}

	ResetVariables(client);
	return Plugin_Continue;
}

int _medPackTraceFilteredEnt = 0;

void TF2_SpawnMedipack(int client, bool cmd = false)
{
	float fPlayerPosition[3];
	GetClientAbsOrigin(client, fPlayerPosition);

	if(fPlayerPosition[0] != 0.0 && fPlayerPosition[1] != 0.0 && fPlayerPosition[2] != 0.0)
	{
		fPlayerPosition[2] += 4;

		if(cmd)
		{
			float PlayerPosEx[3], PlayerAngle[3], PlayerPosAway[3];
			GetClientEyeAngles(client, PlayerAngle);
			PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[2] = 0.0;
			ScaleVector(PlayerPosEx, 75.0);
			AddVectors(fPlayerPosition, PlayerPosEx, PlayerPosAway);

			_medPackTraceFilteredEnt = client;
			Handle TraceEx = TR_TraceRayFilterEx(fPlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);
			TR_GetEndPosition(fPlayerPosition, TraceEx);
			TraceEx.Close();
		}

		float Direction[3];
		Direction[0] = fPlayerPosition[0];
		Direction[1] = fPlayerPosition[1];
		Direction[2] = fPlayerPosition[2]-1024;
		Handle Trace = TR_TraceRayFilterEx(fPlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);

		float MediPos[3];
		TR_GetEndPosition(MediPos, Trace);
		Trace.Close();
		MediPos[2] += 4;

		int Medipack = CreateEntityByName("item_healthkit_full");
		DispatchKeyValue(Medipack, "OnPlayerTouch", "!self,Kill,,0,-1");
		if(DispatchSpawn(Medipack))
		{
			SetEntProp(Medipack, Prop_Send, "m_iTeamNum", 0, 4);
			TeleportEntity(Medipack, MediPos, NULL_VECTOR, NULL_VECTOR);
			EmitSoundToAll("items/spawn_item.wav", Medipack, _, _, _, 0.75);
		}
	}
}

public bool MedipackTraceFilter(int ent, int contentMask)
{
	return (ent != _medPackTraceFilteredEnt);
}

public void OnPreThink(int client)
{
	if(chargingClassic[client])
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int index = IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;

		if(IsValidEntity(weapon) && index == 1098)  //Classic
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage", GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") * 10);
		}
	}

	if(dalokohsTimer[client] && GetEngineTime() >= dalokohsTimer[client])
	{
		dalokohs[client] = 0;
		dalokohsTimer[client] = 0.0;
		SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!cvarEnabled.BoolValue)
	{
		return Plugin_Continue;
	}

	char classname[64];
	if(!IsValidEntity(weapon) || !GetEdictClassname(weapon, classname, sizeof(classname)))
	{
		return Plugin_Continue;
	}

	if(damagecustom == TF_CUSTOM_BOOTS_STOMP)
	{
		damage *= 10;
		return Plugin_Changed;
	}
	/*else if(damagecustom == TF_CUSTOM_CHARGE_IMPACT)
	{
		int heads = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if(heads > cvarHeadCap.IntValue)
		{
			heads = cvarHeadCap.IntValue;
		}

		if(heads > 4)
		{
			Address attribute = TF2Attrib_GetByName(client, "charge impact damage increased");
			float damageIncrease = attribute ? TF2Attrib_GetValue(attribute) : 1.0;
			damage = damageIncrease * (heads * 10 + 50);  //50 being the base damage of the shield and 10 the default increase in damage per head
			PrintToChatAll("[TF2x10] Damage is %f", damage);
			return Plugin_Changed;
		}
	}*/

	if(StrEqual(classname, "tf_weapon_bat_fish") && damagecustom != TF_CUSTOM_BLEEDING &&
		damagecustom != TF_CUSTOM_BURNING && damagecustom != TF_CUSTOM_BURNING_ARROW &&
		damagecustom != TF_CUSTOM_BURNING_FLARE && attacker != client && IsPlayerAlive(client))
	{
		float ang[3];
		GetClientEyeAngles(client, ang);
		ang[1] = ang[1] + 120.0;

		TeleportEntity(client, NULL_VECTOR, ang, NULL_VECTOR);
	}

	//Alien Isolation bonuses
	bool validWeapon = !StrContains(classname, "tf_weapon", false);
	if(validWeapon && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 30474 &&
		TF2Attrib_GetByDefIndex(client, 694) &&
		TF2Attrib_GetByDefIndex(attacker, 695))
	{
		damage *= 10;
		return Plugin_Changed;
	}
	else if(validWeapon && weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) &&
		TF2Attrib_GetByDefIndex(client, 696) &&
		TF2Attrib_GetByDefIndex(attacker, 693))
	{
		damage *= 10;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if(!cvarEnabled.BoolValue)
	{
		return;
	}

	if(IsValidClient(client) && IsPlayerAlive(client) && !ShouldDisableWeapons(client))
	{
		CheckHealthCaps(client);
	}

	if(IsValidClient(attacker) && attacker != client && !ShouldDisableWeapons(attacker) && IsPlayerAlive(attacker))
	{
		CheckHealthCaps(attacker);
	}
}

public Action OnTakeDamage_Object(int building, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(cvarEnabled.BoolValue && IsValidEntity(building) && damagecustom == TF_CUSTOM_PLASMA_CHARGED)
	{
		CreateTimer(4.1, Timer_DisableBuilding, EntIndexToEntRef(building), TIMER_FLAG_NO_MAPCHANGE);  //Wait 4 seconds for the default disable to end, then set ours
		CreateTimer(40.0, Timer_EnableBuilding, EntIndexToEntRef(building), TIMER_FLAG_NO_MAPCHANGE);  //4 x 10 = 40
	}
	return Plugin_Continue;
}

public Action Timer_DisableBuilding(Handle timer, any buildingRef)
{
	int building = EntRefToEntIndex(buildingRef);
	if(IsValidEntity(building) && building > MaxClients)
	{
		SetEntProp(building, Prop_Send, "m_bDisabled", 1);
	}
	return Plugin_Continue;
}

public Action Timer_EnableBuilding(Handle timer, any buildingRef)
{
	int building = EntRefToEntIndex(buildingRef);
	if(IsValidEntity(building) && building > MaxClients)
	{
		SetEntProp(building, Prop_Send, "m_bDisabled", 0);
	}
	return Plugin_Continue;
}

public Action OnWeaponSwitch(int client, int weapon)
{
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(cvarEnabled.BoolValue && IsValidClient(client) && IsValidEntity(activeWeapon))
	{
		char classname[64];
		GetEdictClassname(activeWeapon, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_katana") && !GetEntProp(activeWeapon, Prop_Send, "m_bIsBloody"))
		{
			int health = GetClientHealth(client);
			if(health - cvarZatoichiSheathThreshold.IntValue <= 0)
			{
				return Plugin_Handled;
			}
			else
			{
				SetEntityHealth(client, health - 450);  //50 + 450 = 500
			}
		}
	}
	return Plugin_Continue;
}

bool ShouldDisableWeapons(int client)
{
	//in case vsh/ff2 and other mods are running, disable x10 effects and checks
	//this list may get extended as I check out more game mods

	#if defined _FF2_included
	if(ff2Running && FF2_GetBossTeam() == GetClientTeam(client))
	{
		return true;
	}
	#endif

	#if defined _VSH_included
	if(vshRunning && VSH_GetSaxtonHaleUserId() == GetClientUserId(client))
	{
		return true;
	}
	#endif

	return (hiddenRunning && TF2_GetClientTeam(client) == TFTeam_Blue);
}

void CheckHealthCaps(int client)
{
	if(!aprilFools)  //April Fool's 2015: Unlimited health!
	{
		int cap = cvarHealthCap.IntValue;
		if(cap > 0 && GetClientHealth(client) > cap)
		{
			TF2_SetHealth(client, cap);
		}
	}
}

public Action OnPlayerShieldBlocked(UserMsg msg_id, Handle bf, const players[], int playersNum, bool reliable, bool init)
{
	if(!cvarEnabled.BoolValue || playersNum < 2)
	{
		return Plugin_Continue;
	}

	int victim = players[0];
	if(razorbacks[victim] > 1)
	{
		razorbacks[victim]--;
		int entity;
		while((entity = GetPlayerWeaponSlot_Wearable(victim, TFWeaponSlot_Secondary)) != -1)
		{
			TF2_RemoveWearable(victim, entity);
		}

		Handle weapon = TF2Items_CreateItem(OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
		TF2Items_SetClassname(weapon, "tf_wearable");
		TF2Items_SetItemIndex(weapon, 57);  //Razorback
		TF2Items_SetLevel(weapon, 10);
		TF2Items_SetQuality(weapon, 6);
		TF2Items_SetAttribute(weapon, 0, 52, 1.0);  //Block one backstab attempt
		TF2Items_SetAttribute(weapon, 1, 292, 5.0);  //...kill eater score type?
		TF2Items_SetNumAttributes(weapon, 2);

		entity = TF2Items_GiveNamedItem(victim, weapon);
		weapon.Close();
		SDKCall(equipWearable, victim, entity);
	}

	return Plugin_Continue;
}

/******************************************************************

Gameplay: Player & Item Spawn

******************************************************************/

public int TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int itemDefinitionIndex, int itemLevel, int itemQuality, int entityIndex)
{
	if(!cvarEnabled.BoolValue
	|| (!cvarIncludeBots.BoolValue && IsFakeClient(client))
	|| ShouldDisableWeapons(client)
	|| !isCompatibleItem(classname, itemDefinitionIndex)
	|| (itemQuality == 5 && itemDefinitionIndex != 266)
	|| itemQuality == 8 || itemQuality == 10)
	{
		return;
	}

	int size = 0;

	char attribName[64];
	char attribValue[8];
	char modToUse[16];
	char tmpID[64];

	Format(tmpID, sizeof(tmpID), "%s__%i_size", selectedMod, itemDefinitionIndex);
	if(!itemInfoTrie.GetValue(tmpID, size))
	{
		Format(tmpID, sizeof(tmpID), "%s__%s_size", selectedMod, classname);
		if(!itemInfoTrie.GetValue(tmpID, size))
		{
			Format(tmpID, sizeof(tmpID), "default__%i_size", itemDefinitionIndex);
			if(!itemInfoTrie.GetValue(tmpID, size))
			{
				Format(tmpID, sizeof(tmpID), "default__%s_size", classname);
				if(!itemInfoTrie.GetValue(tmpID, size))
				{
					return;
				}
				else
				{
					strcopy(modToUse, sizeof(modToUse), "default");
				}
			}
			else
			{
				strcopy(modToUse, sizeof(modToUse), "default");
			}
		}
		else
		{
			strcopy(modToUse, sizeof(modToUse), selectedMod);
		}
	}
	else
	{
		strcopy(modToUse, sizeof(modToUse), selectedMod);
	}

	for(int i; i < size; i++)
	{
		Format(tmpID, sizeof(tmpID), "%s__%i_%i_name", modToUse, itemDefinitionIndex, i);
		if(itemInfoTrie.GetString(tmpID, attribName, sizeof(attribName)))
		{
			Format(tmpID, sizeof(tmpID), "%s__%i_%i_val", modToUse, itemDefinitionIndex, i);
			itemInfoTrie.GetString(tmpID, attribValue, sizeof(attribValue));

			if(StrEqual(attribValue, "remove"))
			{
				TF2Attrib_RemoveByName(entityIndex, attribName);
			}
			else
			{
				TF2Attrib_SetByName(entityIndex, attribName, StringToFloat(attribValue));
			}
		}
		else //Use the weapon classname as the backup
		{
			Format(tmpID, sizeof(tmpID), "%s__%s_%i_name", modToUse, classname, i);
			itemInfoTrie.GetString(tmpID, attribName, sizeof(attribName));

			Format(tmpID, sizeof(tmpID), "%s__%s_%i_val", modToUse, classname, i);
			itemInfoTrie.GetString(tmpID, attribValue, sizeof(attribValue));

			if(StrEqual(attribValue, "remove"))
			{
				TF2Attrib_RemoveByName(entityIndex, attribName);
			}
			else
			{
				TF2Attrib_SetByName(entityIndex, attribName, StringToFloat(attribValue));
			}
		}

		//Engineer has the Panic Attack in the primary slot
		if(itemDefinitionIndex==1153 && TF2_GetPlayerClass(client)==TFClass_Engineer && StrEqual(attribName, "maxammo secondary increased"))
		{
			TF2Attrib_RemoveByName(entityIndex, "maxammo secondary increased");
			TF2Attrib_SetByName(entityIndex, "maxammo primary increased", StringToFloat(attribValue));
		}
	}
}

bool isCompatibleItem(char[] classname, int iItemDefinitionIndex)
{
	return StrContains(classname, "tf_weapon") != -1 ||
		StrEqual(classname, "saxxy") ||
		StrEqual(classname, "tf_wearable_demoshield") ||
		(StrEqual(classname, "tf_wearable") &&
		(iItemDefinitionIndex == 133 ||
		iItemDefinitionIndex == 444 ||
		iItemDefinitionIndex == 405 ||
		iItemDefinitionIndex == 608 ||
		iItemDefinitionIndex == 57 ||
		iItemDefinitionIndex == 231 ||
		iItemDefinitionIndex == 642));
}

public Action OnPostInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	if(!cvarEnabled.BoolValue)
	{
		return Plugin_Continue;
	}

	int userid = GetEventInt(event, "userid");
	float delay;
	if(FindConVar("tf2items_rnd_enabled"))
	{
		delay = FindConVar("tf2items_rnd_enabled").BoolValue ? 0.3 : 0.1;
	}
	else
	{
		delay = 0.1;
	}

	UpdateVariables(GetClientOfUserId(userid));
	CreateTimer(delay, Timer_FixClips, userid, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Timer_FixClips(Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!cvarEnabled.BoolValue || !IsValidClient(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int weapon;
	for(int slot; slot < 2; slot++)
	{
		weapon = GetPlayerWeaponSlot(client, slot);

		if(IsValidEntity(weapon))
		{
			CheckClips(weapon);

			if(FindConVar("tf2items_rnd_enabled") && FindConVar("tf2items_rnd_enabled").BoolValue)
			{
				Randomizer_CheckAmmo(client, weapon);
			}
		}
	}

	int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	if(GetClientHealth(client) != maxHealth)
	{
		TF2_SetHealth(client, maxHealth);
	}

	UpdateVariables(client);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01); //recalc speed - thx sarge

	// Apparently the rage meter isn't resetting after switching buffs, so reset it forcefully
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(weapon) && WeaponHasAttribute(client, weapon, "mod soldier buff type"))
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
	}

	return Plugin_Continue;
}

void CheckClips(int entityIndex)
{
	Address attribAddress;

	if((attribAddress = TF2Attrib_GetByName(entityIndex, "clip size penalty")) != Address_Null ||
		(attribAddress = TF2Attrib_GetByName(entityIndex, "clip size bonus")) != Address_Null ||
		(attribAddress = TF2Attrib_GetByName(entityIndex, "clip size penalty HIDDEN")) != Address_Null)
	{
		int ammoCount = GetEntProp(entityIndex, Prop_Data, "m_iClip1");
		float clipSize = TF2Attrib_GetValue(attribAddress);
		ammoCount = (TF2Attrib_GetByName(entityIndex, "can overload") != Address_Null) ? 0 : RoundToCeil(ammoCount * clipSize);

		SetEntProp(entityIndex, Prop_Send, "m_iClip1", ammoCount);
	}
	else if((attribAddress = TF2Attrib_GetByName(entityIndex, "mod max primary clip override")) != Address_Null)
	{
		SetEntProp(entityIndex, Prop_Send, "m_iClip1", RoundToNearest(TF2Attrib_GetValue(attribAddress)));
	}
}

void Randomizer_CheckAmmo(int client, int entityIndex)
{
	//Canceling out Randomizer's own "give ammo" function to the right amount

	int ammoCount = -1;
	int iOffset = GetEntProp(entityIndex, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
	int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	Address attribAddress;

	if((attribAddress = TF2Attrib_GetByName(entityIndex, "maxammo primary increased")) != Address_Null ||
		(attribAddress = TF2Attrib_GetByName(entityIndex, "maxammo secondary increased")) != Address_Null ||
		(attribAddress = TF2Attrib_GetByName(entityIndex, "maxammo primary reduced")) != Address_Null ||
		(attribAddress = TF2Attrib_GetByName(entityIndex, "maxammo secondary reduced")) != Address_Null)
	{
		ammoCount = RoundToCeil(GetEntData(client, iAmmoTable + iOffset) * TF2Attrib_GetValue(attribAddress));
	}
	else if((attribAddress = TF2Attrib_GetByName(entityIndex, "maxammo grenades1 increased")) != Address_Null)
	{
		ammoCount = RoundToCeil(TF2Attrib_GetValue(attribAddress));
	}
	else
	{
		return;
	}

	SetEntData(client, iAmmoTable+iOffset, ammoCount, 4, true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "item_ammopack")!=-1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
	}
}

public void OnItemSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPickup);
	SDKHook(entity, SDKHook_Touch, OnPickup);
}

public Action OnPickup(int entity, int client)
{
	if(aprilFools && IsValidClient(client) && hasBazooka[client])
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/******************************************************************

Stock Functions In Gameplay

******************************************************************/

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client)
	&& !IsFakeClient(client) && IsClientInGame(client)
	&& !GetEntProp(client, Prop_Send, "m_bIsCoaching")
	&& !IsClientSourceTV(client) && !IsClientReplay(client);
}

void ResetVariables(int client)
{
	razorbacks[client] = 0;
	cabers[client] = 0;
	dalokohsSeconds[client] = 0;
	dalokohs[client] = 0;
	//headsTaken[client] = 0;
	revengeCrits[client] = 0;
	amputatorHealing[client] = 0;
	hasCaber[client] = false;
	hasManmelter[client] = false;
	takesHeads[client] = false;
	hasBazooka[client] = false;
	chargeBegin[client] = 0.0;
}

void UpdateVariables(int client)
{
	int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	int secondary = GetPlayerWeaponSlot_Wearable(client, TFWeaponSlot_Secondary);
	int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if(!IsValidEntity(secondary))
	{
		secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	}

	if(IsValidEntity(primary))
	{
		hasBazooka[client] = GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex") == 730;
	}
	else
	{
		hasBazooka[client] = false;
	}

	if(IsValidEntity(secondary))
	{
		razorbacks[client] = WeaponHasAttribute(client, secondary, "backstab shield") ? 10 : 0;
		hasManmelter[client] = WeaponHasAttribute(client, secondary, "extinguish earns revenge crits");
	}
	else
	{
		razorbacks[client] = 0;
		hasManmelter[client] = false;
	}

	if(IsValidEntity(melee))
	{
		hasCaber[client] = GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") == 307;
		takesHeads[client] = WeaponHasAttribute(client, melee, "decapitate type");
		if(takesHeads[client])
		{
			SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
		}
	}
	else
	{
		hasCaber[client] = hasManmelter[client] = hasBazooka[client] = takesHeads[client] = false;
	}

	cabers[client] = hasCaber[client] ? 10 : 0;

	dalokohs[client] = 0;
}

stock void TF2_SetHealth(int client, int health)
{
	if(IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iHealth", health);
		SetEntProp(client, Prop_Data, "m_iHealth", health);
	}
}

stock int GetPlayerWeaponSlot_Wearable(int client, int slot)
{
	int edict = MaxClients + 1;
	if(slot == TFWeaponSlot_Secondary)
	{
		while((edict = FindEntityByClassname2(edict, "tf_wearable_demoshield")) != -1)
		{
			int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if((idx == 131 || idx == 406) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				return edict;
			}
		}
	}

	edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if(GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if(((slot == TFWeaponSlot_Primary && (idx == 405 || idx == 608))
				|| (slot == TFWeaponSlot_Secondary && (idx == 57 || idx == 133 || idx == 231 || idx == 444 || idx == 642)))
				&& GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				return edict;
			}
		}
	}
	return -1;
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt > -1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

//I have this in case TF2Attrib_GetByName acts up
stock bool WeaponHasAttribute(int client, int entity, char[] name)
{
	if(TF2Attrib_GetByName(entity, name) != Address_Null)
	{
		return true;
	}

	if(StrEqual(name, "backstab shield") && (GetPlayerWeaponSlot_Wearable(client, TFWeaponSlot_Secondary) == 57))
	{
		return true;
	}

	int itemIndex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

	return (StrEqual(name, "sapper kills collect crits") && (itemIndex == 525))
		|| (StrEqual(name, "mod sentry killed revenge") &&
		(itemIndex == 141 || itemIndex == 1004))
		|| (StrEqual(name, "decapitate type") &&
		(itemIndex == 132 || itemIndex == 266 || itemIndex == 482 || itemIndex == 1082))
		|| (StrEqual(name, "ullapool caber") && (itemIndex == 307))
		|| (StrEqual(name, "extinguish earns revenge crits") && (itemIndex == 595));
}
