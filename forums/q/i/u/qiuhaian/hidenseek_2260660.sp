#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <smlib>

#define PLUGIN_VERSION "1.5.1"

// that's what GetLanguageCount() got me
#define MAX_LANGUAGES 27

#define PREFIX "\x04Hide and Seek \x01> \x03"

// plugin cvars
new Handle:g_hCVEnable = INVALID_HANDLE;
new Handle:g_hCVFreezeCTs = INVALID_HANDLE;
new Handle:g_hCVFreezeTime = INVALID_HANDLE;
new Handle:g_hCVChangeLimit = INVALID_HANDLE;
new Handle:g_hCVChangeLimittime = INVALID_HANDLE;
new Handle:g_hCVAutoChoose = INVALID_HANDLE;
new Handle:g_hCVWhistle = INVALID_HANDLE;
new Handle:g_hCVWhistleTimes = INVALID_HANDLE;
new Handle:g_hCVWhistleSeeker = INVALID_HANDLE;
new Handle:g_hCVAntiCheat = INVALID_HANDLE;
new Handle:g_hCVCheatPunishment = INVALID_HANDLE;
new Handle:g_hCVHiderWinFrags = INVALID_HANDLE;
new Handle:g_hCVSlaySeekers = INVALID_HANDLE;
new Handle:g_hCVHPSeekerEnable = INVALID_HANDLE;
new Handle:g_hCVHPSeekerDec = INVALID_HANDLE;
new Handle:g_hCVHPSeekerInc = INVALID_HANDLE;
new Handle:g_hCVHPSeekerIncShotgun = INVALID_HANDLE;
new Handle:g_hCVHPSeekerBonus = INVALID_HANDLE;
new Handle:g_hCVOpacityEnable = INVALID_HANDLE;
new Handle:g_hCVHiderSpeed = INVALID_HANDLE;
new Handle:g_hCVDisableRightKnife = INVALID_HANDLE;
new Handle:g_hCVDisableDucking = INVALID_HANDLE;
new Handle:g_hCVAutoThirdPerson = INVALID_HANDLE;
new Handle:g_hCVHiderFreezeMode = INVALID_HANDLE;
new Handle:g_hCVHideBlood = INVALID_HANDLE;
new Handle:g_hCVShowHideHelp = INVALID_HANDLE;
new Handle:g_hCVShowProgressBar = INVALID_HANDLE;
new Handle:g_hCVCTRatio = INVALID_HANDLE;
new Handle:g_hCVDisableUse = INVALID_HANDLE;
new Handle:g_hCVHiderFreezeInAir = INVALID_HANDLE;
new Handle:g_hCVRemoveShadows = INVALID_HANDLE;
new Handle:g_hCVUseTaxedInRandom = INVALID_HANDLE;
new Handle:g_hCVHidePlayerLocation = INVALID_HANDLE;

// primary enableswitch
new bool:g_bEnableHnS = true;

// config and menu handles
new Handle:g_hModelMenu[MAX_LANGUAGES] = {INVALID_HANDLE, ...};
new String:g_sModelMenuLanguage[MAX_LANGUAGES][4];
new Handle:kv;

// offsets
new g_Render;
new g_flFlashDuration;
new g_flFlashMaxAlpha;
new g_Freeze;
new g_iHasNightVision;
new g_flLaggedMovementValue;
new g_flProgressBarStartTime;
new g_iProgressBarDuration;
new g_iAccount;

new bool:g_bInThirdPersonView[MAXPLAYERS+1] = {false,...};
new bool:g_bIsFreezed[MAXPLAYERS+1] = {false,...};
new bool:g_bShotgun[MAXPLAYERS+1] = {false,...};
new g_iFreezeEntity[MAXPLAYERS+1] = {-1,...};
new Handle:g_hRoundTimeTimer = INVALID_HANDLE;
new Handle:g_iRoundTime = INVALID_HANDLE;
new g_iRoundStartTime = 0;

new g_iFirstCTSpawn = 0;
new g_iFirstTSpawn = 0;
new Handle:g_hShowCountdownTimer = INVALID_HANDLE;
new Handle:g_hSpamCommandsTimer = INVALID_HANDLE;
new bool:g_bRoundEnded = false;
new bool:g_bFirstSpawn[MAXPLAYERS+1] = {true,...};

// Cheat cVar part
new Handle:g_hCheckVarTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new String:cheat_commands[][] = {"cl_radaralpha", "r_shadows"};
new bool:g_bConVarViolation[MAXPLAYERS+1][2]; // 2 = amount of cheat_commands. update if you add one.
new g_iConVarMessage[MAXPLAYERS+1][2]; // 2 = amount of cheat_commands. update if you add one.
new Handle:g_hCheatPunishTimer[MAXPLAYERS+1] = {INVALID_HANDLE};

// Terrorist Modelchange stuff
new g_iTotalModelsAvailable = 0;
new g_iModelChangeCount[MAXPLAYERS+1] = {0,...};
new bool:g_bAllowModelChange[MAXPLAYERS+1] = {true,...};
new Handle:g_hAllowModelChangeTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new bool:g_bShowFakeProp[MAXPLAYERS+1];
// Model ground fix
new Float:g_iFixedModelHeight[MAXPLAYERS+1] = {0.0,...};
new bool:g_bClientIsHigher[MAXPLAYERS+1] = {false,...};
new g_iLowModelSteps[MAXPLAYERS+1] = {0,...};

new bool:g_bIsCTWaiting[MAXPLAYERS+1] = {false,...};
new Handle:g_hFreezeCTTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new Handle:g_hUnfreezeCTTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};

// protected server cvars
new String:protected_cvars[][] = {"mp_flashlight", 
								  "sv_footsteps", 
								  "mp_limitteams", 
								  "mp_autoteambalance", 
								  "mp_freezetime", 
								  "sv_nonemesis", 
								  "sv_nomvp", 
								  "sv_nostats", 
								  "mp_playerid",
								  "sv_allowminmodels",
								  "sv_turbophysics",
								  "mp_teams_unbalance_limit",
								  "mp_show_voice_icons"
								 };
new forced_values[] = {0, // mp_flashlight
					   0, // sv_footsteps
					   0, // mp_limitteams
					   0, // mp_autoteambalance
					   0, // mp_freezetime
					   1, // sv_nonemesis
					   1, // sv_nomvp
					   1, // sv_nostats
					   1, // mp_playerid
					   0, // sv_allowminmodels
					   1, // sv_turbophysics
					   0, // mp_teams_unbalance_limit
					   0 // mp_show_voice_icons
					  };
new previous_values[13] = {0,...}; // save previous values when forcing above, so we can restore the config if hns is disabled midgame. !same as comment next line!
new Handle:g_hProtectedConvar[13] = {INVALID_HANDLE,...}; // 13 = amount of protected_cvars. update if you add one.
new Handle:g_hForceCamera = INVALID_HANDLE;

// whistle sounds
new g_iWhistleCount[MAXPLAYERS+1] = {0,...};
new Handle:g_hWhistleDelay = INVALID_HANDLE;
new String:whistle_sounds[][] = {"ambient/animal/cow.wav", "ambient/animal/horse_4.wav", "ambient/animal/horse_5.wav", "ambient/machines/train_horn_3.wav", "ambient/misc/creak3.wav", "doors/door_metal_gate_close1.wav", "ambient/misc/flush1.wav"};

// Teambalance
new g_iLastJoinedCT = -1;
new bool:g_bCTToSwitch[MAXPLAYERS+1] = {false,...};

// AFK check
new Float:g_fSpawnPosition[MAXPLAYERS+1][3];

public Plugin:myinfo = 
{
	name = "Hide and Seek",
	author = "Jannik 'Peace-Maker' Hartung and Vladislav Dolgov and edited by Dk-- for works on CSGO",
	description = "Terrorists set a model and hide, CT seek terrorists.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/ | http://www.elistor.ru/"
};

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_hns_version", PLUGIN_VERSION, "Hide and seek", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	// Config cvars
	g_hCVEnable = 			CreateConVar("sm_hns_enable", "1", "Enable the Hide and Seek Mod?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVFreezeCTs = 		CreateConVar("sm_hns_freezects", "1", "Should CTs get freezed and blinded on spawn?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVFreezeTime = 		CreateConVar("sm_hns_freezetime", "25.0", "How long should the CTs are freezed after spawn?", FCVAR_PLUGIN, true, 1.00, true, 120.00);
	g_hCVChangeLimit = 		CreateConVar("sm_hns_changelimit", "2", "How often a T is allowed to choose his model ingame? 0 = unlimited", FCVAR_PLUGIN, true, 0.00);
	g_hCVChangeLimittime = 	CreateConVar("sm_hns_changelimittime", "30.0", "How long should a T be allowed to change his model again after spawn?", FCVAR_PLUGIN, true, 0.00);
	g_hCVAutoChoose = 		CreateConVar("sm_hns_autochoose", "0", "Should the plugin choose models for the hiders automatically?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVWhistle = 			CreateConVar("sm_hns_whistle", "1", "Are terrorists allowed to whistle?", FCVAR_PLUGIN);
	g_hCVWhistleTimes = 	CreateConVar("sm_hns_whistle_times", "5", "How many times a hider is allowed to whistle per round?", FCVAR_PLUGIN);
	g_hCVWhistleSeeker = 	CreateConVar("sm_hns_whistle_seeker", "0", "Allow CTs to enforce T whistle?", FCVAR_PLUGIN);
	g_hCVAntiCheat = 		CreateConVar("sm_hns_anticheat", "0", "Check player cheat convars, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVCheatPunishment = 	CreateConVar("sm_hns_cheat_punishment", "1", "How to punish players with wrong cvar values after 15 seconds? 0: Disabled. 1: Switch to Spectator. 2: Kick", FCVAR_PLUGIN, true, 0.00, true, 2.00);
	g_hCVHiderWinFrags = 	CreateConVar("sm_hns_hider_win_frags", "5", "How many frags should surviving terrorists gain?", FCVAR_PLUGIN, true, 0.00, true, 10.00);
	g_hCVSlaySeekers = 		CreateConVar("sm_hns_slay_seekers", "0", "Should we slay all seekers on round end and there are still some hiders alive? (Default: 0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVHPSeekerEnable = 	CreateConVar("sm_hns_hp_seeker_enable", "1", "Should CT lose HP when shooting, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVHPSeekerDec = 		CreateConVar("sm_hns_hp_seeker_dec", "5", "How many hp should a CT lose on shooting?", FCVAR_PLUGIN, true, 0.00);
	g_hCVHPSeekerInc = 		CreateConVar("sm_hns_hp_seeker_inc", "15", "How many hp should a CT gain when hitting a hider?", FCVAR_PLUGIN, true, 0.00);
	g_hCVHPSeekerIncShotgun=CreateConVar("sm_hns_hp_seeker_inc_shotgun", "5", "How many hp should a CT gain when hitting a hider with shotgun? (CS:GO only)", FCVAR_PLUGIN, true, 0.00);
	g_hCVHPSeekerBonus = 	CreateConVar("sm_hns_hp_seeker_bonus", "50", "How many hp should a CT gain when killing a hider?", FCVAR_PLUGIN, true, 0.00);
	g_hCVOpacityEnable = 	CreateConVar("sm_hns_opacity_enable", "0", "Should T get more invisible on low hp, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVHiderSpeed  = 		CreateConVar("sm_hns_hidersspeed", "1.00", "Hiders speed (Default: 1.00).", FCVAR_PLUGIN, true, 1.00, true, 3.00);
	g_hCVDisableRightKnife =CreateConVar("sm_hns_disable_rightknife", "1", "Disable rightclick for CTs with knife? Prevents knifing without losing heatlh. (Default: 1).", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVDisableDucking =	CreateConVar("sm_hns_disable_ducking", "1", "Disable ducking. (Default: 1).", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVAutoThirdPerson =	CreateConVar("sm_hns_auto_thirdperson", "1", "Enable thirdperson view for hiders automatically. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVHiderFreezeMode =	CreateConVar("sm_hns_hider_freeze_mode", "2", "0: Disables /freeze command for hiders, 1: Only freeze on position, be able to move camera, 2: Freeze completely (no cameramovements) (Default: 2)", FCVAR_PLUGIN, true, 0.00, true, 2.00);
	g_hCVHideBlood =		CreateConVar("sm_hns_hide_blood", "1", "Hide blood on hider damage. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVShowHideHelp =		CreateConVar("sm_hns_show_hidehelp", "1", "Show helpmenu explaining the game on first player spawn. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVShowProgressBar =	CreateConVar("sm_hns_show_progressbar", "1", "Show progressbar for last 15 seconds of freezetime. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVCTRatio =			CreateConVar("sm_hns_ct_ratio", "3", "The ratio of hiders to 1 seeker. 0 to disables teambalance. (Default: 3)", FCVAR_PLUGIN, true, 1.00, true, 64.00);
	g_hCVDisableUse =		CreateConVar("sm_hns_disable_use", "1", "Disable CTs pushing things. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVHiderFreezeInAir =	CreateConVar("sm_hns_hider_freeze_inair", "0", "Are hiders allowed to freeze in the air? (Default: 0)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVRemoveShadows =	CreateConVar("sm_hns_remove_shadows", "1", "Remove shadows from players and physic models? (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVUseTaxedInRandom =	CreateConVar("sm_hns_use_taxed_in_random", "0", "Include taxed models when using random model choice? (Default: 0)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_hCVHidePlayerLocation=CreateConVar("sm_hns_hide_player_locations", "1", "Hide the location info shown next to players name on voice chat and teamsay? (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	
	g_bEnableHnS = GetConVarBool(g_hCVEnable);
	HookConVarChange(g_hCVEnable, Cfg_OnChangeEnable);
	HookConVarChange(FindConVar("mp_restartgame"), RestartGame);
	
	if(g_bEnableHnS)
	{
		// !ToDo: Exclude hooks and other EnableHnS dependand functions into one seperate function.
		// Now you need to add the hooks to the Cfg_OnChangeEnable callback too..
		HookConVarChange(g_hCVHiderSpeed, OnChangeHiderSpeed);
		HookConVarChange(g_hCVAntiCheat, OnChangeAntiCheat);
		
		// Hooking events
		HookEvent("player_spawn", Event_OnPlayerSpawn);
		HookEvent("weapon_fire", Event_OnWeaponFire);
		HookEvent("player_death", Event_OnPlayerDeath);
		HookEvent("player_blind", Event_OnPlayerBlind);
		HookEvent("round_start", Event_OnRoundStart);
		HookEvent("round_end", Event_OnRoundEnd);
		HookEvent("player_team", Event_OnPlayerTeam);
		HookEvent("item_pickup", Event_OnItemPickup);
		
		decl String:theFolder[40];
		GetGameFolderName(theFolder, sizeof(theFolder));
		if(StrEqual(theFolder, "csgo"))
		{
			HookEvent("item_equip", Event_ItemEquip);
		}
	}
	
	// Register console commands
	RegConsoleCmd("hide", Menu_SelectModel, "Opens a menu with different models to choose as hider.");
	RegConsoleCmd("hidemenu", Menu_SelectModel, "Opens a menu with different models to choose as hider.");
	RegConsoleCmd("tp", Toggle_ThirdPerson, "Toggles the view to thirdperson for hiders.");
	RegConsoleCmd("thirdperson", Toggle_ThirdPerson, "Toggles the view to thirdperson for hiders.");
	RegConsoleCmd("third", Toggle_ThirdPerson, "Toggles the view to thirdperson for hiders.");
	RegConsoleCmd("+3rd", Enable_ThirdPerson, "Set the view to thirdperson for hiders.");
	RegConsoleCmd("-3rd", Disable_ThirdPerson, "Set the view to firstperson for hiders.");
	RegConsoleCmd("jointeam", Command_JoinTeam);
	RegConsoleCmd("whistle", Play_Whistle, "Plays a random sound from the hiders position to give the seekers a hint.");
	RegConsoleCmd("whoami", Display_ModelName, "Displays the current models description in chat.");
	RegConsoleCmd("hidehelp", Display_Help, "Displays a panel with informations how to play.");
	RegConsoleCmd("freeze", Freeze_Cmd, "Toggles freezing for hiders.");
	
	
	RegConsoleCmd("overview_mode", Block_Cmd);
	
	RegAdminCmd("sm_hns_force_whistle", ForceWhistle, ADMFLAG_CHAT, "Force a player to whistle");
	RegAdminCmd("sm_hns_reload_models", ReloadModels, ADMFLAG_RCON, "Reload the modellist from the map config file.");
		
	// Loading translations
	LoadTranslations("plugin.hide_and_seek");
	LoadTranslations("common.phrases"); // for FindTarget()
	
	// set the default values for cvar checking
	for(new x=1;x<=MaxClients;x++)
	{
		for(new y=0;y<sizeof(cheat_commands);y++)
		{
			g_bConVarViolation[x][y] = false;
			g_iConVarMessage[x][y] = 0;
		}
		if(IsClientInGame(x))
			OnClientPutInServer(x);
	}

	if(g_bEnableHnS)
	{
		// start advertising spam
		g_hSpamCommandsTimer = CreateTimer(120.0, SpamCommands, 0);
	}
	
	// hook cvars
	g_hForceCamera =  FindConVar("mp_forcecamera");
	g_iRoundTime =  FindConVar("mp_roundtime");
	
	// get the offsets
	// for transparency
	g_Render = FindSendPropOffs("CAI_BaseNPC", "m_clrRender");
	if(g_Render == -1)
		SetFailState("Couldnt find the m_clrRender offset!");	
	
	// for hiding players on radar
	g_flFlashDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
	if(g_flFlashDuration == -1)
		SetFailState("Couldnt find the m_flFlashDuration offset!");
	g_flFlashMaxAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	if(g_flFlashMaxAlpha == -1)
		SetFailState("Couldnt find the m_flFlashMaxAlpha offset!");
	g_Freeze = FindSendPropOffs("CBasePlayer", "m_fFlags");
	if(g_Freeze == -1)
		SetFailState("Couldnt find the m_fFlags offset!");
	g_iHasNightVision = FindSendPropOffs("CCSPlayer", "m_bHasNightVision");
	if(g_iHasNightVision == -1)
		SetFailState("Couldnt find the m_bHasNightVision offset!");
	g_flLaggedMovementValue = FindSendPropOffs("CCSPlayer", "m_flLaggedMovementValue");
	if(g_flLaggedMovementValue == -1)
		SetFailState("Couldnt find the m_flLaggedMovementValue offset!");
	g_flProgressBarStartTime = FindSendPropOffs("CCSPlayer", "m_flProgressBarStartTime");
	if(g_flProgressBarStartTime == -1)
		SetFailState("Couldnt find the m_flProgressBarStartTime offset!");
	g_iProgressBarDuration = FindSendPropOffs("CCSPlayer", "m_iProgressBarDuration");
	if(g_iProgressBarDuration == -1)
		SetFailState("Couldnt find the m_iProgressBarDuration offset!");
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if(g_iAccount == -1)
		SetFailState("Couldnt find the m_iAccount offset!");
	
	
	AutoExecConfig(true, "plugin.hide_and_seek");
}

public OnPluginEnd()
{
	if(g_bEnableHnS)
		ServerCommand("mp_restartgame 1");
}

public OnConfigsExecuted()
{
	if(g_bEnableHnS)
	{
		// set bad server cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			g_hProtectedConvar[i] = FindConVar(protected_cvars[i]);
			if(g_hProtectedConvar[i] == INVALID_HANDLE)
				continue;
			
			previous_values[i] = GetConVarInt(g_hProtectedConvar[i]);
			SetConVarInt(g_hProtectedConvar[i], forced_values[i], true);
			HookConVarChange(g_hProtectedConvar[i], OnCvarChange);
		}
	}
}

/*
* 
* Generic Events
* 
*/
public OnMapStart()
{
	if(!g_bEnableHnS)
		return;
	
	BuildMainMenu();
	for(new i=0;i<sizeof(whistle_sounds);i++)
		PrecacheSound(whistle_sounds[i], true);
	
	PrecacheSound("radio/go.wav", true);
	
	// prevent us from bugging after mapchange
	g_iFirstCTSpawn = 0;
	g_iFirstTSpawn = 0;
	
	if(g_hShowCountdownTimer != INVALID_HANDLE)
	{
		KillTimer(g_hShowCountdownTimer);
		g_hShowCountdownTimer = INVALID_HANDLE;
	}
	
	new bool:foundHostageZone = false;
	
	// check if there is a hostage rescue zone
	new maxent = GetMaxEntities(), String:eName[64];
	for (new i=MaxClients;i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, eName, sizeof(eName));
			if(StrContains(eName, "func_hostage_rescue") != -1)
			{
				foundHostageZone = true;
			}
		}
	}
	
	// add a hostage rescue zone if there isn't one, so T will win after round time
	if(!foundHostageZone)
	{
		new ent = CreateEntityByName("func_hostage_rescue");
		if (ent>0)
		{
			new Float:orign[3] = {-1000.0,...};
			DispatchKeyValue(ent, "targetname", "hidenseek_roundend");
			DispatchKeyValueVector(ent, "orign", orign);
			DispatchSpawn(ent);
		}
	}
	
	// Remove shadows
	// Thanks to Bacardi and Leonardo @ http://forums.alliedmods.net/showthread.php?t=154269
	if(GetConVarBool(g_hCVRemoveShadows))
	{
		new bool:bShadowDisabled = false;
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "shadow_control")) != -1)
		{
			SetVariantInt(1);
			AcceptEntityInput(ent, "SetShadowsDisabled");
			bShadowDisabled = true;
		}
		
		// Some maps don't have a shadow_control entity, so we create one.
		// Thanks to zipcore's suggestion http://forums.alliedmods.net/showpost.php?p=1811214&postcount=16
		if(!bShadowDisabled)
		{
			ent = CreateEntityByName("shadow_control");
			if(ent != -1)
			{
				SetVariantInt(1);
				AcceptEntityInput(ent, "SetShadowsDisabled");
			}
		}
	}
}

public OnMapEnd()
{
	if(!g_bEnableHnS)
		return;
	
	CloseHandle(kv);
	for(new i=0;i<MAX_LANGUAGES;i++)
	{
		if(g_hModelMenu[i] != INVALID_HANDLE)
		{
			CloseHandle(g_hModelMenu[i]);
			g_hModelMenu[i] = INVALID_HANDLE;
		}
		Format(g_sModelMenuLanguage[i], 4, "");
	}
	
	g_iFirstCTSpawn = 0;
	g_iFirstTSpawn = 0;
	
	if(g_hShowCountdownTimer != INVALID_HANDLE)
	{
		KillTimer(g_hShowCountdownTimer);
		g_hShowCountdownTimer = INVALID_HANDLE;
	}
	
	if(g_hRoundTimeTimer != INVALID_HANDLE)
	{
		KillTimer(g_hRoundTimeTimer);
		g_hRoundTimeTimer = INVALID_HANDLE;
	}
	
	if(g_hWhistleDelay != INVALID_HANDLE)
	{
		KillTimer(g_hWhistleDelay);
		g_hWhistleDelay = INVALID_HANDLE;
	}
}

public OnClientPutInServer(client)
{
	if(!g_bEnableHnS)
		return;
	
	if(!IsFakeClient(client) && GetConVarBool(g_hCVAntiCheat))
		g_hCheckVarTimer[client] = CreateTimer(1.0, StartVarChecker, client, TIMER_REPEAT);
	
	// Hook weapon pickup
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponCanUse);
	
	// Hook attackings to hide blood
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	
	// Hide player location info
	SDKHook(client, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
	SDKHook(client, SDKHook_PostThink, Hook_OnPostThink);
}

public OnClientDisconnect(client)
{
	if(!g_bEnableHnS)
		return;
	
	// set the default values for cvar checking
	if(!IsFakeClient(client))
	{
		for(new i=0;i<sizeof(cheat_commands);i++)
		{
			g_bConVarViolation[client][i] = false;
			g_iConVarMessage[client][i] = 0;
		}
	
		g_bInThirdPersonView[client] = false;
		g_bIsFreezed[client] = false;
		g_iModelChangeCount[client] = 0;
		g_bIsCTWaiting[client] = false;
		g_iWhistleCount[client] = 0;
		if (g_hCheatPunishTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hCheatPunishTimer[client]);
			g_hCheatPunishTimer[client] = INVALID_HANDLE;
		}
		if (g_bAllowModelChange[client] && g_hAllowModelChangeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hAllowModelChangeTimer[client]);
			g_hAllowModelChangeTimer[client] = INVALID_HANDLE;
		}
		if(g_hFreezeCTTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hFreezeCTTimer[client]);
			g_hFreezeCTTimer[client] = INVALID_HANDLE;
		}
		if(g_hUnfreezeCTTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hUnfreezeCTTimer[client]);
			g_hUnfreezeCTTimer[client] = INVALID_HANDLE;
		}
	}
	g_bAllowModelChange[client] = true;
	g_bFirstSpawn[client] = true;
	
	g_bClientIsHigher[client] = false;
	g_iFixedModelHeight[client] = 0.0;
	g_iLowModelSteps[client] = 0;
	
	// Teambalancer
	g_bCTToSwitch[client] = false;
	CreateTimer(0.1, Timer_ChangeTeam, client, TIMER_FLAG_NO_MAPCHANGE);
	
	// AFK check
	for(new i=0;i<3;i++)
	{
		g_fSpawnPosition[client][i] = 0.0;
	}
	
	/*if (g_hCheckVarTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hCheckVarTimer[client]);
		g_hCheckVarTimer[client] = INVALID_HANDLE;
	}*/
}

// prevent players from ducking
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(!g_bEnableHnS)
		return Plugin_Continue;
	
	new iInitialButtons = buttons;
	
	decl String:weaponName[30];
	// don't allow ct's to shoot in the beginning of the round
	new team = GetClientTeam(client);
	GetClientWeapon(client, weaponName, sizeof(weaponName));
	if(team == CS_TEAM_CT && g_bIsCTWaiting[client] && (buttons & IN_ATTACK || buttons & IN_ATTACK2))
	{
		buttons &= ~IN_ATTACK;
		buttons &= ~IN_ATTACK2;
	} // disable rightclick knifing for cts
	else if(team == CS_TEAM_CT && GetConVarBool(g_hCVDisableRightKnife) && buttons & IN_ATTACK2 && !strcmp(weaponName, "weapon_knife"))
	{
		buttons &= ~IN_ATTACK2;
	}
	
	//Freeze and rotation fix
	Client_UpdateFakeProp(client);
	
	// Modelfix
	if(g_iFixedModelHeight[client] != 0.0 && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		new Float:vecVelocity[3];
		vecVelocity[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		vecVelocity[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		vecVelocity[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
		// Player isn't moving
		if(vecVelocity[0] == 0.0 && vecVelocity[1] == 0.0 && vecVelocity[2] == 0.0 && !(buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_JUMP))
		{
			if(!g_bClientIsHigher[client] && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
			{
				new Float:vecClientOrigin[3];
				GetClientAbsOrigin(client, vecClientOrigin);
				vecClientOrigin[2] += g_iFixedModelHeight[client];
				TeleportEntity(client, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(client, MOVETYPE_NONE);
				g_bClientIsHigher[client] = true;
				g_iLowModelSteps[client] = 0;
			}
		}
		// Player is running for 60 thinks? make him visible for a short time
		else if(g_iLowModelSteps[client] == 60)
		{
			if(!g_bClientIsHigher[client] && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
			{
				new Float:vecClientOrigin[3];
				GetClientAbsOrigin(client, vecClientOrigin);
				vecClientOrigin[2] += g_iFixedModelHeight[client];
				TeleportEntity(client, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
			}
			g_iLowModelSteps[client] = 0;
		}
		// Player is moving
		else if(!g_bIsFreezed[client])
		{
			if(g_bClientIsHigher[client])
			{
				new Float:vecClientOrigin[3];
				GetClientAbsOrigin(client, vecClientOrigin);
				vecClientOrigin[2] -= g_iFixedModelHeight[client];
				TeleportEntity(client, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(client, MOVETYPE_WALK);
				g_bClientIsHigher[client] = false;
			}
			g_iLowModelSteps[client]++;
		}
		
		// Always disable ducking for that kind of models.
		if(buttons & IN_DUCK)
		{
			buttons &= ~IN_DUCK;
		}
	}
	
	// disable ducking for everyone
	if(buttons & IN_DUCK && GetConVarBool(g_hCVDisableDucking))
		buttons &= ~IN_DUCK;
	
	// disable use for everyone
	if(GetConVarBool(g_hCVDisableUse) && buttons & IN_USE)
		buttons &= ~IN_USE;
	
	if(iInitialButtons != buttons)
		return Plugin_Changed;
	else
		return Plugin_Continue;
}

// SDKHook Callbacks
public Action:OnWeaponCanUse(client, weapon)
{
	// Allow only CTs to use a weapon
	if(g_bEnableHnS && IsClientInGame(client) && GetClientTeam(client) != CS_TEAM_CT)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

//Used to balance life hit for seekers
public Action:Event_ItemEquip(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	new type = GetEventInt(event, "weptype");

	if(type == 4) // 4 = Shotgun
	{
		//Player has a shutgun in his hand
		g_bShotgun[client] = true;
	}
	else g_bShotgun[client] = false;
}

// Used to block blood
// set a normal model right before death to avoid errors
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(!g_bEnableHnS)
		return Plugin_Continue;
	
	if(GetClientTeam(victim) == CS_TEAM_T)
	{
		new remainingHealth = GetClientHealth(victim)-RoundToFloor(damage);
		
		// Attacker is a human?
		if(GetConVarBool(g_hCVHPSeekerEnable) && attacker > 0 && attacker <= MaxClients && IsPlayerAlive(attacker) && !IsPlayerAFK(victim))
		{
			new decrease = GetConVarInt(g_hCVHPSeekerDec);
			
			if(g_bShotgun[attacker])
				SetEntityHealth(attacker, GetClientHealth(attacker)+GetConVarInt(g_hCVHPSeekerIncShotgun)+decrease);
			else SetEntityHealth(attacker, GetClientHealth(attacker)+GetConVarInt(g_hCVHPSeekerInc)+decrease);
			
			// the hider died? give extra health! need to add the decreased value again, since he fired his gun and lost hp.
			// possible "bug": seeker could be slayed because weapon_fire is called earlier than player_hurt.
			if(remainingHealth < 0)
				SetEntityHealth(attacker, GetClientHealth(attacker)+GetConVarInt(g_hCVHPSeekerBonus)+decrease);
		}
		
		// prevent errors in console because of missing death animation of prop ;)
		if(remainingHealth < 0)
		{
			//SetEntityModel(victim, "models/player/t_guerilla.mdl");
			return Plugin_Continue; // just let the damage get through
		}
		else if(GetConVarBool(g_hCVOpacityEnable))
		{
			new alpha = 150 + RoundToNearest(10.5*float(remainingHealth/10));
			
			SetEntData(victim, g_Render+3, alpha, 1, true);
			SetEntityRenderMode(victim, RENDER_TRANSTEXTURE);
		}
		
		if(GetConVarBool(g_hCVHideBlood))
		{
			// Simulate the damage
			SetEntityHealth(victim, remainingHealth);
			
			// Don't show the blood!
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Hook_OnPostThinkPost(client)
{
	if(GetConVarBool(g_hCVHidePlayerLocation) && GetClientTeam(client) == CS_TEAM_T)
		SetEntPropString(client, Prop_Send, "m_szLastPlaceName", "");
}

public Hook_OnPostThink(client)
{
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	if(StrEqual(theFolder, "csgo") && GetClientTeam(client) == CS_TEAM_T)
		SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
}

/*
* 
* Hooked Events
* 
*/
// Player Spawn event
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnableHnS)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);

	if(team <= CS_TEAM_SPECTATOR || !IsPlayerAlive(client))
		return Plugin_Continue;
	else if(team == CS_TEAM_T) // Team T
	{
		// set the mp_forcecamera value correctly, so he can use thirdperson again
		if(!IsFakeClient(client) && GetConVarInt(g_hForceCamera) == 1)
			SendConVarValue(client, g_hForceCamera, "0");
		
		// reset model change count
		g_iModelChangeCount[client] = 0;
		g_bInThirdPersonView[client] = false;
		if(!IsFakeClient(client) && g_hAllowModelChangeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hAllowModelChangeTimer[client]);
			g_hAllowModelChangeTimer[client] = INVALID_HANDLE;
		}
		g_bAllowModelChange[client] = true;
		
		// Reset model fix height
		g_iFixedModelHeight[client] = 0.0;
		g_bClientIsHigher[client] = false;
		
		// set the speed
		SetEntDataFloat(client, g_flLaggedMovementValue, GetConVarFloat(g_hCVHiderSpeed), true);
		
		// reset the transparent
		if(GetConVarBool(g_hCVOpacityEnable))
		{
			SetEntData(client,g_Render+3,255,1,true);
			SetEntityRenderMode(client, RENDER_TRANSTEXTURE);
		}
		
		new Float:changeLimitTime = GetConVarFloat(g_hCVChangeLimittime);
		
		// Assign a model to bots immediately and disable all menus or timers.
		if(IsFakeClient(client))
			g_hAllowModelChangeTimer[client] = CreateTimer(0.1, DisableModelMenu, client);
		else
		{
			// only disable the menu, if it's not unlimited
			if(changeLimitTime > 0.0)
				g_hAllowModelChangeTimer[client] = CreateTimer(changeLimitTime, DisableModelMenu, client);
			
			// Set them to thirdperson automatically
			if(GetConVarBool(g_hCVAutoThirdPerson))
				SetThirdPersonView(client, true);
			
			if(GetConVarBool(g_hCVAutoChoose))
				SetRandomModel(client);
			else if(changeLimitTime > 0.0)
				DisplayMenu(g_hModelMenu[GetClientLanguageID(client)], client, RoundToFloor(changeLimitTime));
			else
				DisplayMenu(g_hModelMenu[GetClientLanguageID(client)], client, MENU_TIME_FOREVER);
		}
		
		g_iWhistleCount[client] = 0;
		g_bIsFreezed[client] = false;
		
		if(g_iFirstTSpawn == 0)
		{
			g_iFirstTSpawn = GetTime();
		}

		if(GetConVarBool(g_hCVFreezeCTs))
			PrintToChat(client, "%s%t", PREFIX, "seconds to hide", RoundToFloor(GetConVarFloat(g_hCVFreezeTime)));
		else
			PrintToChat(client, "%s%t", PREFIX, "seconds to hide", 0);
	}
	else if(team == CS_TEAM_CT) // Team CT
	{
		if(!IsFakeClient(client) && GetConVarInt(g_hForceCamera) == 1)
			SendConVarValue(client, g_hForceCamera, "1");
		
		new currentTime = GetTime();
		new Float:freezeTime = GetConVarFloat(g_hCVFreezeTime);
		// don't keep late spawning cts blinded longer than the others :)
		if(g_iFirstCTSpawn == 0)
		{
			if(g_hShowCountdownTimer != INVALID_HANDLE)
			{
				KillTimer(g_hShowCountdownTimer);
				g_hShowCountdownTimer = INVALID_HANDLE;
				if(GetConVarBool(g_hCVShowProgressBar))
				{
					for(new i=1;i<=MaxClients;i++)
					{
						if(IsClientInGame(i))
						{
							SetEntDataFloat(i, g_flProgressBarStartTime, 0.0, true);
							SetEntData(i, g_iProgressBarDuration, 0, 4, true);
						}
					}
				}
			}
			else if(GetConVarBool(g_hCVFreezeCTs))
			{
				// show time in center
				g_hShowCountdownTimer = CreateTimer(0.01, ShowCountdown, RoundToFloor(GetConVarFloat(g_hCVFreezeTime)));
			}
			g_iFirstCTSpawn = currentTime;
		}
		// only freeze spawning players if the freezetime is still running.
		if(GetConVarBool(g_hCVFreezeCTs) && (float(currentTime - g_iFirstCTSpawn) < freezeTime))
		{
			g_bIsCTWaiting[client] = true;
			CreateTimer(0.05, FreezePlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			
			// Start freezing player
			g_hFreezeCTTimer[client] = CreateTimer(2.0, FreezePlayer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			
			if(g_hUnfreezeCTTimer[client] != INVALID_HANDLE)
			{
				KillTimer(g_hUnfreezeCTTimer[client]);
				g_hUnfreezeCTTimer[client] = INVALID_HANDLE;
			}
			
			// Stop freezing player
			g_hUnfreezeCTTimer[client] = CreateTimer(freezeTime-float(currentTime - g_iFirstCTSpawn), UnFreezePlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			
			PrintToChat(client, "%s%t", PREFIX, "Wait for t to hide", RoundToFloor(freezeTime-float(currentTime - g_iFirstCTSpawn)));
		}
		
		// show help menu on first spawn
		if(GetConVarBool(g_hCVShowHideHelp) && g_bFirstSpawn[client])
		{
			Display_Help(client, 0);
			g_bFirstSpawn[client] = false;
		}
		
		// Make sure CTs have a knife
		CreateTimer(2.0, Timer_CheckCTHasKnife, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// hide radar
	// Huge thanks to GoD-Tony!
	SetEntDataFloat(client, g_flFlashDuration, 10000.0, true);
	SetEntDataFloat(client, g_flFlashMaxAlpha, 0.5, true);
	
	CreateTimer(0.5, Timer_SaveSpawnPosition, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

// subtract 5hp for every shot a seeker is giving
public Action:Event_OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnableHnS)
		return Plugin_Continue;
	
	if(!GetConVarBool(g_hCVHPSeekerEnable) || g_bRoundEnded)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new decreaseHP = GetConVarInt(g_hCVHPSeekerDec);
	new clientHealth = GetClientHealth(client);
	
	// he can take it
	if((clientHealth-decreaseHP) > 0)
	{
		SetEntityHealth(client, (clientHealth-decreaseHP));
	}
	else // slay him
	{
		ForcePlayerSuicide(client);
	}
	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnableHnS)
		return Plugin_Continue;
	
	g_bRoundEnded = false;
	
	// When disabling +use or "e" button open all doors on the map and keep them opened.
	new bool:bUse = GetConVarBool(g_hCVDisableUse);
	
	new maxent = GetMaxEntities(), String:eName[64];
	for (new i=MaxClients;i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, eName, sizeof(eName));
			// remove bombzones and hostages so no normal gameplay could end the round
			if ( StrContains(eName, "hostage_entity") != -1 || StrContains(eName, "func_bomb_target") != -1  || (StrContains(eName, "func_buyzone") != -1 && GetEntProp(i, Prop_Data, "m_iTeamNum", 4) == CS_TEAM_T))
			{
				RemoveEdict(i);
			}
			// Open all doors
			else if(bUse && StrContains(eName, "_door", false) != -1)
			{
				AcceptEntityInput(i, "Open");
				HookSingleEntityOutput(i, "OnClose", EntOutput_OnClose);
			}
		}
	}
	
	// Remove shadows
	// Thanks to Bacardi and Leonardo @ http://forums.alliedmods.net/showthread.php?t=154269
	if(GetConVarBool(g_hCVRemoveShadows))
	{
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "shadow_control")) != -1)
		{
			SetVariantInt(1);
			AcceptEntityInput(ent, "SetShadowsDisabled");
		}
	}
	
	// show the roundtime in env_hudhint entity
	g_iRoundStartTime = GetTime();
	new realRoundTime = RoundToNearest(GetConVarFloat(g_iRoundTime)*60.0);

	//If it's CS:Source we need to show round time while in thirdperson
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	if(StrEqual(theFolder, "cstrike"))
	{
		g_hRoundTimeTimer = CreateTimer(0.5, ShowRoundTime, realRoundTime, TIMER_FLAG_NO_MAPCHANGE);
	}
		
	return Plugin_Continue;
}
// give terrorists frags
public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnableHnS)
		return Plugin_Continue;
	
	// round has ended. used to not decrease seekers hp on shoot
	g_bRoundEnded = true;
	
	g_iFirstCTSpawn = 0;
	g_iFirstTSpawn = 0;
	
	if(g_hShowCountdownTimer != INVALID_HANDLE)
	{
		KillTimer(g_hShowCountdownTimer);
		g_hShowCountdownTimer = INVALID_HANDLE;
	}
	
	if(g_hRoundTimeTimer != INVALID_HANDLE)
	{
		KillTimer(g_hRoundTimeTimer);
		g_hRoundTimeTimer = INVALID_HANDLE;
	}
	
	if(g_hWhistleDelay != INVALID_HANDLE)
	{
		KillTimer(g_hWhistleDelay);
		g_hWhistleDelay = INVALID_HANDLE;
	}
	
	new winnerTeam = GetEventInt(event, "winner");
	
	if(winnerTeam == CS_TEAM_T)
	{
		new increaseFrags = GetConVarInt(g_hCVHiderWinFrags);
		
		new bool:aliveTerrorists = false;
		new iFrags = 0;
		// increase playerscore of all alive Terrorists
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				if(increaseFrags > 0)
				{
					// increase kills by x
					iFrags = GetClientFrags(i) + increaseFrags;
					SetEntProp(i, Prop_Data, "m_iFrags", iFrags, 4);
					aliveTerrorists = true;
				}
				
				// set godmode for the rest of the round
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			}
		}
		
		if(aliveTerrorists)
		{
			PrintToChatAll("%s%t", PREFIX, "got frags", increaseFrags);
		}
		
		if(GetConVarBool(g_hCVSlaySeekers))
		{
			// slay all seekers
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
				{
					ForcePlayerSuicide(i);
				}
			}
		}
	}
	
	// Switch the flagged players to CT
	CreateTimer(0.1, Timer_SwitchTeams, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

// remove ragdolls on death...
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnableHnS)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_iFixedModelHeight[client] != 0.0 && g_bClientIsHigher[client])
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_bClientIsHigher[client] = false;
	}
	g_iFixedModelHeight[client] = 0.0;
	g_bClientIsHigher[client] = false;
	
	// Show guns again.
	SetThirdPersonView(client, false);
	
	// set the mp_forcecamera value correctly, so he can watch his teammates
	// This doesn't work. Even if the convar is set to 0, the hiders are only able to spectate their teammates..
	if(GetConVarInt(g_hForceCamera) == 1)
	{
		if(!IsFakeClient(client) && GetClientTeam(client) != CS_TEAM_T)
			SendConVarValue(client, g_hForceCamera, "1");
		else if(!IsFakeClient(client))
			SendConVarValue(client, g_hForceCamera, "0");
	}
	
	if (!IsValidEntity(client) || IsPlayerAlive(client))
		return Plugin_Continue;
	
	// Unfreeze, if freezed before
	if(g_bIsFreezed[client])
	{
		if(GetConVarInt(g_hCVHiderFreezeMode) == 1)
			SetEntityMoveType(client, MOVETYPE_WALK);
		else
		{
			SetEntData(client, g_Freeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		
		g_bIsFreezed[client] = false;
	}
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
		return Plugin_Continue;
	
	RemoveEdict(ragdoll);
	
	return Plugin_Continue;
}

public Event_OnPlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnableHnS)
		return;
	
	// Thanks to GoD-Tony!
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new Float:iDuration = GetEntDataFloat(client, g_flFlashDuration);
	if(iDuration > 0.1)
		iDuration -= 0.1;
	
	if (client && GetClientTeam(client) > 1)
		CreateTimer(iDuration, Timer_FlashEnd, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnableHnS)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	new bool:disconnect = GetEventBool(event, "disconnect");
	
	// Handle the thirdperson view values
	// terrors are always allowed to view players in thirdperson
	if(client && !IsFakeClient(client) && GetConVarInt(g_hForceCamera) == 1)
	{
		if(team == CS_TEAM_T)
			SendConVarValue(client, g_hForceCamera, "0");
		else if(team != CS_TEAM_CT)
			SendConVarValue(client, g_hForceCamera, "1");
	}
	
	// Player disconnected?
	if(disconnect)
		g_bCTToSwitch[client] = false;
	
	// Player joined spectator?
	if(!disconnect && team < CS_TEAM_T)
	{
		g_bCTToSwitch[client] = false;
		
		// Unblind and show weapons again
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		PerformBlind(client, 0);
		
		// Reset the model fix
		if(g_iFixedModelHeight[client] != 0.0 && g_bClientIsHigher[client])
		{
			SetEntityMoveType(client, MOVETYPE_OBSERVER);
		}
		g_iFixedModelHeight[client] = 0.0;
		g_bClientIsHigher[client] = false;
		
		// Unfreeze, if freezed before
		if(g_bIsFreezed[client])
		{
			if(GetConVarInt(g_hCVHiderFreezeMode) == 1)
				SetEntityMoveType(client, MOVETYPE_OBSERVER);
			else
			{
				SetEntData(client, g_Freeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
				SetEntityMoveType(client, MOVETYPE_OBSERVER);
			}
			
			g_bIsFreezed[client] = false;
		}
	}
	
	// Reset the last joined ct, if he left
	if(disconnect && g_iLastJoinedCT == client)
		g_iLastJoinedCT = -1;
	
	// Strip the player if joined T midround
	if(!disconnect && team == CS_TEAM_T && IsPlayerAlive(client))
	{
		StripPlayerWeapons(client);
	}
	
	// Ignore, if Teambalance is disabled
	if(GetConVarFloat(g_hCVCTRatio) == 0.0)
		return Plugin_Continue;
	
	// GetTeamClientCount() doesn't handle the teamchange we're called for in player_team,
	// so wait two frames to update the counts
	CreateTimer(0.2, Timer_ChangeTeam, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Event_OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnableHnS)
		return;
	
	new client = GetClientOfUserId(GetEventInt( event, "userid"));
	decl String:sItem[100];
	GetEventString(event, "item", sItem, sizeof(sItem));
	
	// restrict nightvision
	if(StrEqual(sItem, "nvgs", false))
		SetEntData(client, g_iHasNightVision, 0, 4, true);
}

public EntOutput_OnClose(const String:output[], caller, activator, Float:delay)
{
	AcceptEntityInput(caller, "Open");
}

/*
* 
* Timer Callbacks
* 
*/

// Freeze player function
public Action:FreezePlayer(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !g_bIsCTWaiting[client])
	{
		g_hFreezeCTTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	// Force him to watch at the ground.
	new Float:fPlayerEyes[3];
	GetClientEyeAngles(client, fPlayerEyes);
	fPlayerEyes[0] = 180.0;
	TeleportEntity(client, NULL_VECTOR, fPlayerEyes, NULL_VECTOR);
	SetEntData(client, g_Freeze, FL_CLIENT|FL_ATCONTROLS, 4, true);
	SetEntityMoveType(client, MOVETYPE_NONE);
	PerformBlind(client, 255);
	
	return Plugin_Continue;
}

// Unfreeze player function
public Action:UnFreezePlayer(Handle:timer, any:client)
{
	g_hUnfreezeCTTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	SetEntData(client, g_Freeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	if(!IsConVarCheater(client))
		PerformBlind(client, 0);
	
	g_bIsCTWaiting[client] = false;
	
	EmitSoundToClient(client, "radio/go.wav");
	
	PrintToChat(client, "%s%t", PREFIX, "Go search");
		
	return Plugin_Stop;
}

public Action:DisableModelMenu(Handle:timer, any:client)
{
	
	g_hAllowModelChangeTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	g_bAllowModelChange[client] = false;
	
	if(IsPlayerAlive(client))
		PrintToChat(client, "%s%t", PREFIX, "Modelmenu Disabled");
	
	// didn't he chose a model?
	if(GetClientTeam(client) == CS_TEAM_T && g_iModelChangeCount[client] == 0)
	{
		// give him a random one.
		PrintToChat(client, "%s%t", PREFIX, "Did not choose model");
		SetRandomModel(client);
	}
	
	return Plugin_Stop;
}

public Action:StartVarChecker(Handle:timer, any:client)
{	
	if (!IsClientInGame(client))
		return Plugin_Stop;
	
	// allow watching
	if(GetClientTeam(client) < CS_TEAM_T)
	{
		PerformBlind(client, 0);
		return Plugin_Continue;
	}
	
	// check all defined cvars for value "0"
	for(new i=0;i<sizeof(cheat_commands);i++)
		QueryClientConVar(client, cheat_commands[i], ConVarQueryFinished:ClientConVar, client);
	
	if(IsConVarCheater(client))
	{
		// Blind and Freeze player
		PerformBlind(client, 255);
		SetEntityMoveType(client, MOVETYPE_NONE);
		
		if(GetConVarInt(g_hCVCheatPunishment) != 0 && g_hCheatPunishTimer[client] == INVALID_HANDLE)
		{
			g_hCheatPunishTimer[client] = CreateTimer(15.0, PerformCheatPunishment, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		if(g_hCheatPunishTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hCheatPunishTimer[client]);
			g_hCheatPunishTimer[client] = INVALID_HANDLE;
		}
		
		if(!g_bIsCTWaiting[client])
		{
			if(IsPlayerAlive(client))
				SetEntityMoveType(client, MOVETYPE_WALK);
			PerformBlind(client, 0);
		}
	}
	
	return Plugin_Continue;
}

public Action:PerformCheatPunishment(Handle:timer, any:client)
{
	g_hCheatPunishTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client) || !IsConVarCheater(client))
		return Plugin_Stop;
	
	new punishmentType = GetConVarInt(g_hCVCheatPunishment);
	if(punishmentType == 1 && GetClientTeam(client) != CS_TEAM_SPECTATOR )
	{
		g_bCTToSwitch[client] = false;
		
		// Unblind and show weapons again
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		PerformBlind(client, 0);
		
		// Reset the model fix
		if(g_iFixedModelHeight[client] != 0.0 && g_bClientIsHigher[client])
		{
			SetEntityMoveType(client, MOVETYPE_OBSERVER);
		}
		g_iFixedModelHeight[client] = 0.0;
		g_bClientIsHigher[client] = false;
		
		// Unfreeze, if freezed before
		if(g_bIsFreezed[client])
		{
			if(GetConVarInt(g_hCVHiderFreezeMode) == 1)
				SetEntityMoveType(client, MOVETYPE_OBSERVER);
			else
			{
				SetEntData(client, g_Freeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
				SetEntityMoveType(client, MOVETYPE_OBSERVER);
			}
			
			g_bIsFreezed[client] = false;
		}
		
		if(g_iLastJoinedCT == client)
			g_iLastJoinedCT = -1;
		
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		PrintToChatAll("%s%N %t", PREFIX, client, "Spectator Cheater");
	}
	else if(punishmentType == 2)
	{
		for(new i=0;i<sizeof(cheat_commands);i++)
			if(g_bConVarViolation[client][i])
				PrintToConsole(client, "Hide and Seek: %t %s 0", "Print to console", cheat_commands[i]);
		KickClient(client, "Hide and Seek: %t", "Kick bad cvars");
	}
	return Plugin_Stop;
}

// teach the players the /whistle and /tp commands
public Action:SpamCommands(Handle:timer, any:data)
{
	if(GetConVarBool(g_hCVWhistle) && data == 1)
		PrintToChatAll("%s%t", PREFIX, "T type /whistle");
	else if(!GetConVarBool(g_hCVWhistle) || data == 0)
	{
		for(new i=1;i<=MaxClients;i++)
			if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
				PrintToChat(i, "%s%t", PREFIX, "T type /tp");
	}
	g_hSpamCommandsTimer = CreateTimer(120.0, SpamCommands, (data==0?1:0));
	return Plugin_Stop;
}

// show all players a countdown
// CT: I'm coming!
public Action:ShowCountdown(Handle:timer, any:freezeTime)
{
	new seconds = freezeTime - GetTime() + g_iFirstCTSpawn;
	PrintCenterTextAll("%d", seconds);
	if(seconds <= 0)
	{
		g_hShowCountdownTimer = INVALID_HANDLE;
		if(GetConVarBool(g_hCVShowProgressBar))
		{
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i))
				{
					SetEntDataFloat(i, g_flProgressBarStartTime, 0.0, true);
					SetEntData(i, g_iProgressBarDuration, 0, 4, true);
				}
			}
		}
		return Plugin_Stop;
	}
	
	// m_iProgressBarDuration has a limit of 15 seconds, so start showing the bar on 15 seconds left.
	if(GetConVarBool(g_hCVShowProgressBar) && (seconds) < 15)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && GetEntProp(i, Prop_Send, "m_iProgressBarDuration") == 0)
			{
				SetEntDataFloat(i, g_flProgressBarStartTime, GetGameTime(), true);
				SetEntData(i, g_iProgressBarDuration, seconds, 4, true);
			}
		}
	}
	
	g_hShowCountdownTimer = CreateTimer(0.5, ShowCountdown, freezeTime);
	
	return Plugin_Stop;
}

public Action:ShowRoundTime(Handle:timer, any:roundTime)
{
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	if(StrEqual(theFolder, "csgo"))
		return Plugin_Stop;
	
	decl String:timeLeft[10];
	new seconds = roundTime - GetTime() + g_iRoundStartTime;
	
	new minutes = RoundToFloor(float(seconds) / 60.0);
	new secs = seconds - minutes*60;
	if(secs < 10)
		Format(timeLeft, sizeof(timeLeft), "%d:0%d", minutes, secs);
	else
		Format(timeLeft, sizeof(timeLeft), "%d:%d", minutes, secs);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && g_bInThirdPersonView[i])
		{
			Client_PrintKeyHintText(i, "%s", timeLeft);
		}
	}
	
	if(seconds > 0)
		g_hRoundTimeTimer = CreateTimer(0.5, ShowRoundTime, roundTime, TIMER_FLAG_NO_MAPCHANGE);
	else
		g_hRoundTimeTimer = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public Action:Timer_SwitchTeams(Handle:timer, any:data)
{
	decl String:sName[64];
	for(new i=1;i<=MaxClients;i++)
	{
		if(g_bCTToSwitch[i])
		{
			if(IsClientInGame(i))
			{
				GetClientName(i, sName, sizeof(sName));
				CS_SwitchTeam(i, CS_TEAM_T);
				PrintToChatAll("%s%t", PREFIX, "switched", sName);
			}
			g_bCTToSwitch[i] = false;
		}
	}
	return Plugin_Stop;
}

public Action:Timer_ChangeTeam(Handle:timer, any:client)
{
	new iCTCount = GetTeamClientCount(CS_TEAM_CT);
	new iTCount = GetTeamClientCount(CS_TEAM_T);
	
	new iToBeSwitched = 0;
	
	// Check, how many cts are going to get switched to terror at the end of the round
	new iTeam;
	for(new i=1;i<=MaxClients;i++)
	{
		// Don't care for cheaters
		if(IsConVarCheater(i))
		{
			if(IsClientInGame(i))
			{
				iTeam = GetClientTeam(i);
				if(iTeam == CS_TEAM_CT)
					iCTCount--;
				else if(iTeam == CS_TEAM_T)
					iTCount--;
			}
		}
		else if(g_bCTToSwitch[i])
		{
			iCTCount--;
			iTCount++;
			iToBeSwitched++;
		}
	}
	//PrintToServer("Debug: %d players are flagged to switch at the end of the round.", iToBeSwitched);
	new Float:fRatio = FloatDiv(float(iCTCount), float(iTCount));
	
	new Float:fCFGCTRatio = GetConVarFloat(g_hCVCTRatio);
	
	new Float:fCFGRatio = FloatDiv(1.0, fCFGCTRatio);
	
	//PrintToServer("Debug: Initial CTCount: %d TCount: %d Ratio: %f, CFGRatio: %f", iCTCount, iTCount, fRatio, fCFGRatio);
	
	decl String:sName[64];
	// There are more CTs than we want in the CT team and it's not the first CT
	if((iCTCount > 0 || iTCount > 0) && iCTCount != 1 && fRatio > fCFGRatio)
	{
		//PrintToServer("Debug: Too much CTs! Taking action...");
		// Any players flagged to be moved at the end of the round?
		if(iToBeSwitched > 0)
		{
			for(new i=1;i<=MaxClients;i++)
			{
				if(g_bCTToSwitch[i])
				{
					g_bCTToSwitch[i] = false;
					iCTCount++;
					iTCount--;
					GetClientName(i, sName, sizeof(sName));
					PrintToChatAll("%s%t.", PREFIX, "stop switch", sName);
					
					//PrintToServer("Debug: Unflagged one player from being switched to T. CTCount: %d TCount: %d Ratio: %f", iCTCount, iTCount, FloatDiv(float(iCTCount), float(iTCount)));
					
					// switched enough players?
					if(float(iTCount) < fCFGCTRatio || FloatDiv(float(iCTCount), float(iTCount)) <= fCFGRatio)
					{
						//PrintToServer("Debug: Switched enough players after unflagging.");
						return Plugin_Stop;
					}
				}
			}
		}
		
		// First check, if the last change has been from x->CT
		if(client && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
		{
			// Reverse the change or put him in T directly
			iCTCount--;
			iTCount++;
			ChangeClientTeam(client, CS_TEAM_T);
			GetClientName(client, sName, sizeof(sName));
			PrintToChatAll("%s%t", PREFIX, "switched", sName);
			
			//PrintToServer("Debug: Switched the player %s straight back to T. CTCount: %d TCount: %d Ratio: %f", sName, iCTCount, iTCount, FloatDiv(float(iCTCount), float(iTCount)));
			
			// switched enough players?
			if(float(iTCount) < fCFGCTRatio || FloatDiv(float(iCTCount), float(iTCount)) <= fCFGRatio)
			{
				//PrintToServer("Debug: Switched enough players after reversing the last change.");
				return Plugin_Stop;
			}
		}
		// Switch last joined CT
		else if(g_iLastJoinedCT != -1)
		{
			// Dead? switch directly.
			if(IsClientInGame(g_iLastJoinedCT) && !IsPlayerAlive(g_iLastJoinedCT))
			{
				iCTCount--;
				iTCount++;
				ChangeClientTeam(g_iLastJoinedCT, CS_TEAM_T);
				GetClientName(g_iLastJoinedCT, sName, sizeof(sName));
				PrintToChatAll("%s%t", PREFIX, "switched", sName);
				//PrintToServer("Debug: Switched the last joined CT %s to T. CTCount: %d TCount: %d Ratio: %f", sName, iCTCount, iTCount, FloatDiv(float(iCTCount), float(iTCount)));
			}
			else if(IsClientInGame(g_iLastJoinedCT))
			{
				iCTCount--;
				iTCount++;
				g_bCTToSwitch[g_iLastJoinedCT] = true;
				GetClientName(g_iLastJoinedCT, sName, sizeof(sName));
				PrintToChatAll("%s%t", PREFIX, "going to switch", sName);
				//PrintToServer("Debug: Flagged the last joined CT %s to switch at roundend. CTCount: %d TCount: %d Ratio: %f", sName, iCTCount, iTCount, FloatDiv(float(iCTCount), float(iTCount)));
			}
			
			// switched enough players?
			if(float(iTCount) < fCFGCTRatio || FloatDiv(float(iCTCount), float(iTCount)) <= fCFGRatio)
			{
				//PrintToServer("Debug: Switched enough players after checking the last joined CT.");
				return Plugin_Stop;
			}
		}
		
		// First search for a dead seeker, so we can switch him
		// @TODO: Take care for ranking on the scoreboard or longest playtime as CT
		for(new i=1;i<=MaxClients;i++)
		{
			// switched enough players?
			if(float(iTCount) < fCFGCTRatio || FloatDiv(float(iCTCount), float(iTCount)) <= fCFGRatio)
			{
				//PrintToServer("Debug: Switched enough players after switching dead cts");
				return Plugin_Stop;
			}
			
			// Switch one ct to t immediately.
			if(IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT && !g_bCTToSwitch[i])
			{
				iCTCount--;
				iTCount++;
				ChangeClientTeam(i, CS_TEAM_T);
				GetClientName(i, sName, sizeof(sName));
				PrintToChatAll("%s%t", PREFIX, "switched", sName);
				//PrintToServer("Debug: Switched dead CT %s to T. CTCount: %d TCount: %d Ratio: %f", sName, iCTCount, iTCount, FloatDiv(float(iCTCount), float(iTCount)));
			}
		}
		
		// Still not enough switched? Just pick a random one and switch him at the end of the round
		for(new i=1;i<=MaxClients;i++)
		{
			// switched enough players?
			if(float(iTCount) < fCFGCTRatio || FloatDiv(float(iCTCount), float(iTCount)) <= fCFGRatio)
			{
				//PrintToServer("Debug: Switched enough players after flagging alive CTs");
				return Plugin_Stop;
			}
			
			if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && !g_bCTToSwitch[i])
			{
				iCTCount--;
				iTCount++;
				g_bCTToSwitch[i] = true;
				GetClientName(i, sName, sizeof(sName));
				PrintToChatAll("%s%t", PREFIX, "going to switch", sName);
				//PrintToServer("Debug: Flagging alive CT %s to switch to T at roundend. CTCount: %d TCount: %d Ratio: %f", sName, iCTCount, iTCount, FloatDiv(float(iCTCount), float(iTCount)));
			}
		}
	}
	// Is the player in CT now?
	// He joined last!
	else if(client && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		g_iLastJoinedCT = client;
	}
	return Plugin_Stop;
}

// Make sure CTs have knifes
public Action:Timer_CheckCTHasKnife(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		new iWeapon = GetPlayerWeaponSlot(client, 2);
		if(iWeapon == -1)
		{
			iWeapon = GivePlayerItem(client, "weapon_knife");
			EquipPlayerWeapon(client, iWeapon);
		}
	}
	
	return Plugin_Stop;
}

// Hide the radar again after flashing
public Action:Timer_FlashEnd(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (client && GetClientTeam(client) > 1)
	{
		SetEntDataFloat(client, g_flFlashDuration, 10000.0, true);
		SetEntDataFloat(client, g_flFlashMaxAlpha, 0.5, true);
	}
		
	return Plugin_Stop;
}

public Action:Timer_SaveSpawnPosition(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	GetClientAbsOrigin(client, g_fSpawnPosition[client]);
	return Plugin_Stop;
}

/*
* 
* Console Command Handling
* 
*/

// say /hide /hidemenu
public Action:Menu_SelectModel(client,args)
{
	if (!g_bEnableHnS || g_hModelMenu[GetClientLanguageID(client)] == INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		new changeLimit = GetConVarInt(g_hCVChangeLimit);
		if(g_bAllowModelChange[client] && (changeLimit == 0 || g_iModelChangeCount[client] < (changeLimit+1)))
		{
			if(GetConVarBool(g_hCVAutoChoose))
				SetRandomModel(client);
			else
				DisplayMenu(g_hModelMenu[GetClientLanguageID(client)], client, RoundToFloor(GetConVarFloat(g_hCVChangeLimittime)));
		}
		else
			PrintToChat(client, "%s%t", PREFIX, "Modelmenu Disabled");
	}
	else
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can select models");
	}
	return Plugin_Handled;
}

// say /tp /third /thirdperson
public Action:Toggle_ThirdPerson(client, args)
{
	if (!g_bEnableHnS || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// Only allow Terrorists to use thirdperson view
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	if(!g_bInThirdPersonView[client])
	{
		SetThirdPersonView(client, true);
		PrintToChat(client, "%s%t", PREFIX, "Type again for ego");
	}
	else
	{
		SetThirdPersonView(client, false);
		// remove the roundtime message
		decl String:theFolder[40];
		GetGameFolderName(theFolder, sizeof(theFolder));
		if(StrEqual(theFolder, "cstrike")) Client_PrintKeyHintText(client, "");
	}
	
	return Plugin_Handled;
}

// say /+3rd
public Action:Enable_ThirdPerson(client, args)
{
	if (!g_bEnableHnS || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// Only allow Terrorists to use thirdperson view
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	if(!g_bInThirdPersonView[client])
	{
		SetThirdPersonView(client, true);
		PrintToChat(client, "%s%t", PREFIX, "Type again for ego");
	}
	
	return Plugin_Handled;
}

// say /-3rd
public Action:Disable_ThirdPerson(client, args)
{
	if (!g_bEnableHnS || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// Only allow Terrorists to use thirdperson view
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	if(g_bInThirdPersonView[client])
	{
		SetThirdPersonView(client, false);
		// remove the roundtime message
		decl String:theFolder[40];
		GetGameFolderName(theFolder, sizeof(theFolder));
		if(StrEqual(theFolder, "cstrike")) Client_PrintKeyHintText(client, "");
	}
	
	return Plugin_Handled;
}

// jointeam command
// handle the team sizes
public Action:Command_JoinTeam(client, args)
{
	if (!g_bEnableHnS || !client || !IsClientInGame(client) || GetConVarFloat(g_hCVCTRatio) == 0.0)
	{
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	StripQuotes(text);
	
	// Player wants to join CT
	if(strcmp(text, "3", false) == 0)
	{
		new iCTCount = GetTeamClientCount(CS_TEAM_CT);
		new iTCount = GetTeamClientCount(CS_TEAM_T);
		
		// This client would be in CT if we continue.
		iCTCount++;
		
		// And would leave T
		if(GetClientTeam(client) == CS_TEAM_T)
			iTCount--;
		
		// Check, how many terrors are going to get switched to ct at the end of the round
		for(new i=1;i<=MaxClients;i++)
		{
			if(g_bCTToSwitch[i])
			{
				iCTCount--;
				iTCount++;
			}
		}
		
		new Float:fRatio = FloatDiv(float(iCTCount), float(iTCount));
		
		new Float:fCFGRatio = FloatDiv(1.0, GetConVarFloat(g_hCVCTRatio));
		
		//PrintToServer("Debug: Player %N wants to join CT. CTCount: %d TCount: %d Ratio: %f", client, iCTCount, iTCount, FloatDiv(float(iCTCount), float(iTCount)));
		
		// There are more CTs than we want in the CT team.
		if(iCTCount > 1 && fRatio > fCFGRatio)
		{
			PrintCenterText(client, "CT team is full");
			//PrintToServer("Debug: Blocked.");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

// say /whistle
// plays a random sound loudly
public Action:Play_Whistle(client,args)
{
	// check if whistling is enabled
	if(!g_bEnableHnS || !GetConVarBool(g_hCVWhistle) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	new bool:cvarWhistleSeeker = bool:GetConVarInt(g_hCVWhistleSeeker);
	
	if(cvarWhistleSeeker && GetClientTeam(client) != CS_TEAM_CT)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only counter-terrorists can use");
		return Plugin_Handled;
	}
	// only Ts are allowed to whistle
	else if(!cvarWhistleSeeker && GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	new cvarWhistleTimes = GetConVarInt(g_hCVWhistleTimes);
	
	if(g_iWhistleCount[client] < cvarWhistleTimes)
	{
		if(!cvarWhistleSeeker)
		{
			EmitSoundToAll(whistle_sounds[GetRandomInt(0, sizeof(whistle_sounds)-1)], client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			PrintToChatAll("%s%N %t", PREFIX, client, "whistled");
			g_iWhistleCount[client]++;
			PrintToChat(client, "%s%t", PREFIX, "whistles left", (cvarWhistleTimes-g_iWhistleCount[client]));
		}
		else
		{
			new target;
			new iCount;
			new Float:maxrange;
			new Float:range;
			
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
				{
					iCount++;
					range = Entity_GetDistance(client, i);
					if(range > maxrange)
					{
						maxrange = range;
						target = i;
					}
				}
			}
			
			if(iCount > 1)
			{
				EmitSoundToAll(whistle_sounds[GetRandomInt(0, sizeof(whistle_sounds)-1)], target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
				PrintToChatAll("%s %N forced %N to whistle.", PREFIX, client, target);
				g_iWhistleCount[client]++;
				PrintToChat(client, "%s%t", PREFIX, "whistles left", (cvarWhistleTimes-g_iWhistleCount[client]));
			}
		}
	}
	else
	{
		PrintToChat(client, "%s%t", PREFIX, "whistle limit exceeded", cvarWhistleTimes);
	}
	
	return Plugin_Handled;
}
// say /whoami
// displays the model name in chat again
public Action:Display_ModelName(client,args)
{
	// only enable command, if player already chose a model
	if(!g_bEnableHnS || !IsPlayerAlive(client) || g_iModelChangeCount[client] == 0)
		return Plugin_Handled;
	
	// only Ts can use a model
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	decl String:modelName[128], String:langCode[4];
	GetClientModel(client, modelName, sizeof(modelName));
	
	if (!KvGotoFirstSubKey(kv))
	{
		return Plugin_Handled;
	}
	
	decl String:name[30], String:path[100], String:fullPath[100];
	do
	{
		KvGetSectionName(kv, path, sizeof(path));
		FormatEx(fullPath, sizeof(fullPath), "models/%s.mdl", path);
		if(StrEqual(fullPath, modelName))
		{
			GetClientLanguageID(client, langCode, sizeof(langCode));
			KvGetString(kv, langCode, name, sizeof(name));
			PrintToChat(client, "%s%t\x01 %s.", PREFIX, "Model Changed", name);
		}
	} while (KvGotoNextKey(kv));
	KvRewind(kv);
	
	return Plugin_Handled;
}


// say /hidehelp
// Show the help menu
public Action:Display_Help(client,args)
{
	if(!g_bEnableHnS)
		return Plugin_Handled;
	
	new Handle:menu = CreateMenu(Menu_Help);
	
	decl String:buffer[512];
	Format(buffer, sizeof(buffer), "%T", "HnS Help", client);
	SetMenuTitle(menu, buffer);
	SetMenuExitButton(menu, true);
	
	Format(buffer, sizeof(buffer), "%T", "Running HnS", client);
	AddMenuItem(menu, "", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Instructions 1", client);
	AddMenuItem(menu, "", buffer);
	
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	
	Format(buffer, sizeof(buffer), "%T", "Available Commands", client);
	AddMenuItem(menu, "1", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Howto CT", client);
	AddMenuItem(menu, "2", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Howto T", client);
	AddMenuItem(menu, "3", buffer);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

// say /freeze
// Freeze hiders in position
public Action:Freeze_Cmd(client,args)
{
	if(!g_bEnableHnS || !GetConVarInt(g_hCVHiderFreezeMode) || GetClientTeam(client) != CS_TEAM_T || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	if(g_bIsFreezed[client])
	{
		if(GetConVarInt(g_hCVHiderFreezeMode) == 1)
		{
			if(!g_bClientIsHigher[client])
				SetEntityMoveType(client, MOVETYPE_WALK);
		}
		else
		{
			SetEntData(client, g_Freeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
			if(!g_bClientIsHigher[client])
				SetEntityMoveType(client, MOVETYPE_WALK);
		}
		
		g_bIsFreezed[client] = false;
		PrintToChat(client, "%s%t", PREFIX, "Hider Unfreezed");
	}
	else if (GetConVarBool(g_hCVHiderFreezeInAir) || (GetEntityFlags(client) & FL_ONGROUND || g_bClientIsHigher[client])) // only allow freezing when being on the ground!
	{
		// Don't allow fixed models to freeze while being bugged
		// Put him up before freezing
		if(g_iFixedModelHeight[client] > 0.0 && !g_bClientIsHigher[client] && GetEntityFlags(client) & FL_ONGROUND)
		{
			new Float:vecClientOrigin[3];
			GetClientAbsOrigin(client, vecClientOrigin);
			vecClientOrigin[2] += g_iFixedModelHeight[client];
			TeleportEntity(client, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
			g_bClientIsHigher[client] = true;
		}
		
		if(GetConVarInt(g_hCVHiderFreezeMode) == 1)
			SetEntityMoveType(client, MOVETYPE_NONE); // Still able to move camera
		else
		{
			SetEntData(client, g_Freeze, FL_CLIENT|FL_ATCONTROLS, 4, true); // Can't move anything
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
		
		// Stop him
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,0.0});
		
		g_bIsFreezed[client] = true;
		PrintToChat(client, "%s%t", PREFIX, "Hider Freezed");
	}
	
	return Plugin_Handled;
}

public Action:Block_Cmd(client,args)
{
	// only block if anticheat is enabled
	if(g_bEnableHnS && GetConVarBool(g_hCVAntiCheat))
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

// Admin Command
// sm_hns_force_whistle
// Forces a terrorist player to whistle
public Action:ForceWhistle(client, args)
{
	if(!g_bEnableHnS || !GetConVarBool(g_hCVWhistle))
	{
		ReplyToCommand(client, "Disabled.");
		return Plugin_Handled;
	}
	
	if(GetCmdArgs() < 1)
	{
		ReplyToCommand(client, "Usage: sm_hns_force_whistle <#userid|steamid|name>");
		return Plugin_Handled;
	}
	
	decl String:player[70];
	GetCmdArg(1, player, sizeof(player));
	
	new target = FindTarget(client, player);
	if(target == -1)
		return Plugin_Handled;
	
	if(GetClientTeam(target) == CS_TEAM_T && IsPlayerAlive(target))
	{
		EmitSoundToAll(whistle_sounds[GetRandomInt(0, sizeof(whistle_sounds)-1)], target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		PrintToChatAll("%s%N %t", PREFIX, target, "whistled");
	}
	else
	{
		ReplyToCommand(client, "Hide and Seek: %t", "Only terrorists can use");
	}
	
	return Plugin_Handled;
}

public Action:ReloadModels(client, args)
{
	if(!g_bEnableHnS)
	{
		ReplyToCommand(client, "Disabled.");
		return Plugin_Handled;
	}
	
	// reset the model menu
	OnMapEnd();
	
	// rebuild it
	BuildMainMenu();
	
	ReplyToCommand(client, "Hide and Seek: Reloaded config.");
	
	return Plugin_Handled;
}


/*
* 
* Menu Handler
* 
*/
public Menu_Group(Handle:menu, MenuAction:action, client, param2)
{
	// make sure again, the player is a Terrorist
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T && g_bAllowModelChange[client])
	{
		if (action == MenuAction_Select)
		{
			decl String:info[100], String:info2[100], String:sModelPath[100];
			new bool:found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
			if(found)
			{
				
				if(StrEqual(info, "random"))
				{
					SetRandomModel(client);
				}
				else
				{
					// Check for enough money
					decl String:sTax[32];
					new iPosition;
					if((iPosition = StrContains(info, "||t_")) != -1)
					{
						new iAccountValue = GetEntData(client, g_iAccount);
						
						// Stupid string information storage-.-
						new iPosition2 = StrContains(info[iPosition+4], "||hi_");
						if(iPosition2 != -1)
							strcopy(sTax, iPosition2-iPosition+3, info[iPosition+4]);
						else
							strcopy(sTax, sizeof(sTax), info[iPosition+4]);
						
						new iTax = StringToInt(sTax);
						// He doesn't have enough money?
						if(iTax > iAccountValue)
						{
							PrintToChat(client, "%s%t", PREFIX, "not enough money");
							// Show the menu again
							Menu_SelectModel(client, 0);
							return;
						}
						
						// Get the money
						SetEntData(client, g_iAccount, (iAccountValue - iTax), 4, true);
						
						PrintToChat(client, "%s%t", PREFIX, "tax charged", iTax);
					}
					
					// Put him down before changing the model again
					if(g_bClientIsHigher[client])
					{
						new Float:vecClientOrigin[3];
						GetClientAbsOrigin(client, vecClientOrigin);
						vecClientOrigin[2] -= g_iFixedModelHeight[client];
						TeleportEntity(client, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
						SetEntityMoveType(client, MOVETYPE_WALK);
						g_bClientIsHigher[client] = false;
					}
					
					// Modelheight fix
					if((iPosition = StrContains(info, "||hi_")) != -1)
					{
						g_iFixedModelHeight[client] = StringToFloat(info[iPosition+5]);
						PrintToChat(client, "%s%t", PREFIX, "is heightfixed");
					}
					else
					{
						g_iFixedModelHeight[client] = 0.0;
					}
					
					if(SplitString(info, "||", sModelPath, sizeof(sModelPath)) == -1)
						strcopy(sModelPath, sizeof(sModelPath), info);
					
					SetEntityModel(client, sModelPath);
					PrintToChat(client, "%s%t \x01%s.", PREFIX, "Model Changed", info2);
				}
				g_iModelChangeCount[client]++;
			}
		} else if(action == MenuAction_Cancel)
		{
			PrintToChat(client, "%s%t", PREFIX, "Type !hide");
		}
		
		// display the help menu afterwards on first spawn
		if(GetConVarBool(g_hCVShowHideHelp) && g_bFirstSpawn[client])
		{
			Display_Help(client, 0);
			g_bFirstSpawn[client] = false;
		}
	}
}

// Display the different help menus
public Menu_Help(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new iInfo = StringToInt(info);
		switch(iInfo)
		{
			case 1:
			{
				// Available Commands
				new Handle:menu2 = CreateMenu(Menu_Dummy);
				decl String:buffer[512];
				Format(buffer, sizeof(buffer), "%T", "Available Commands", param1);
				SetMenuTitle(menu2, buffer);
				SetMenuExitBackButton(menu2, true);
				
				Format(buffer, sizeof(buffer), "/hide, /hidemenu - %T", "cmd hide", param1);
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				Format(buffer, sizeof(buffer), "/tp, /third, /thirdperson - %T", "cmd tp", param1);
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				if(GetConVarBool(g_hCVWhistle))
				{
					Format(buffer, sizeof(buffer), "/whistle - %T", "cmd whistle", param1);
					AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				}
				if(GetConVarInt(g_hCVHiderFreezeMode))
				{
					Format(buffer, sizeof(buffer), "/freeze - %T", "cmd freeze", param1);
					AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				}
				Format(buffer, sizeof(buffer), "/whoami - %T", "cmd whoami", param1);
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				Format(buffer, sizeof(buffer), "/hidehelp - %T", "cmd hidehelp", param1);
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				
				DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
			}
			case 2:
			{
				// Howto CT
				new Handle:menu2 = CreateMenu(Menu_Dummy);
				decl String:buffer[512];
				Format(buffer, sizeof(buffer), "%T", "Howto CT", param1);
				SetMenuTitle(menu2, buffer);
				SetMenuExitBackButton(menu2, true);
				
				Format(buffer, sizeof(buffer), "%T", "Instructions CT 1", param1);
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				
				AddMenuItem(menu2, "", "", ITEMDRAW_SPACER);
				
				Format(buffer, sizeof(buffer), "%T", "Instructions CT 2", param1, GetConVarInt(g_hCVHPSeekerDec));
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				
				Format(buffer, sizeof(buffer), "%T", "Instructions CT 3", param1, GetConVarInt(g_hCVHPSeekerInc), GetConVarInt(g_hCVHPSeekerBonus));
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				
				DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
			}
			case 3:
			{
				// Howto T
				new Handle:menu2 = CreateMenu(Menu_Dummy);
				decl String:buffer[512];
				Format(buffer, sizeof(buffer), "%T", "Howto T", param1);
				SetMenuTitle(menu2, buffer);
				SetMenuExitBackButton(menu2, true);
				
				Format(buffer, sizeof(buffer), "%T", "Instructions T 1", param1);
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				
				Format(buffer, sizeof(buffer), "%T", "Instructions T 2", param1);
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				
				DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_Dummy(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Cancel && param2 != MenuCancel_Exit)
	{
		if(IsClientInGame(param1))
			Display_Help(param1, 0);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/*
* 
* Helper Functions
* 
*/

// read the hide_and_seek map config
// add all models to the menus according to the language
BuildMainMenu()
{
	g_iTotalModelsAvailable = 0;
		
	kv = CreateKeyValues("Models");
	new String:file[256], String:map[64], String:title[64], String:finalOutput[100];
	GetCurrentMap(map, sizeof(map));
	
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	if(StrEqual(theFolder, "csgo"))
	{
		BuildPath(Path_SM, file, 255, "configs/hide_and_seek/maps_csgo/%s.cfg", map);
		if(!FileExists(file))
		{
			BuildPath(Path_SM, file, 255, "configs/hide_and_seek/maps_csgo/default.cfg");
		}
	}
	else if(StrEqual(theFolder, "cstrike"))
	{
		BuildPath(Path_SM, file, 255, "configs/hide_and_seek/maps_css/%s.cfg", map);
		if(!FileExists(file))
		{
			BuildPath(Path_SM, file, 255, "configs/hide_and_seek/maps_css/default.cfg");
		}
	}
	
	FileToKeyValues(kv, file);
	
	if (!KvGotoFirstSubKey(kv))
	{
		SetFailState("Can't parse modelconfig file for map %s.", map);
		return;
	}
	
	decl String:name[30];
	decl String:lang[4];
	decl String:path[100];
	new langID, nextLangID = -1;
	do
	{
		// get the model path and precache it
		KvGetSectionName(kv, path, sizeof(path));
		FormatEx(finalOutput, sizeof(finalOutput), "models/%s.mdl", path);
		PrecacheModel(finalOutput, true);
		
		// Check for heightfixed models
		decl String:sHeightFix[32];
		KvGetString(kv, "heightfix", sHeightFix, sizeof(sHeightFix), "noo");
		if(!StrEqual(sHeightFix, "noo"))
		{
			Format(finalOutput, sizeof(finalOutput), "%s||hi_%s", finalOutput, sHeightFix);
		}
		
		// Check for tax
		decl String:sTax[32];
		KvGetString(kv, "tax", sTax, sizeof(sTax), "noo");
		if(!StrEqual(sTax, "noo"))
		{
			Format(finalOutput, sizeof(finalOutput), "%s||t_%s", finalOutput, sTax);
		}
		
		// roll through all available languages
		for(new i=0;i<GetLanguageCount();i++)
		{
			GetLanguageInfo(i, lang, sizeof(lang));
			// search for the translation
			KvGetString(kv, lang, name, sizeof(name));
			if(strlen(name) > 0)
			{
				// Show the tax
				if(!StrEqual(sTax, "noo"))
					Format(name, sizeof(name), "%s ($%d)", name, StringToInt(sTax));
				
				// language already in array, only in the wrong order in the file?
				langID = GetLanguageID(lang);
				
				// language new?
				if(langID == -1)
				{
					nextLangID = GetNextLangID();
					g_sModelMenuLanguage[nextLangID] = lang;
				}
				
				if(langID == -1 && g_hModelMenu[nextLangID] == INVALID_HANDLE)
				{
					// new language, create the menu
					g_hModelMenu[nextLangID] = CreateMenu(Menu_Group);
					Format(title, sizeof(title), "%T:", "Title Select Model", LANG_SERVER);
					
					SetMenuTitle(g_hModelMenu[nextLangID], title);
					SetMenuExitButton(g_hModelMenu[nextLangID], true);
					
					// Add random option
					Format(title, sizeof(title), "%T", "random", LANG_SERVER);
					AddMenuItem(g_hModelMenu[nextLangID], "random", title);
				}
				
				// add it to the menu
				if(langID == -1)
					AddMenuItem(g_hModelMenu[nextLangID], finalOutput, name);
				else
					AddMenuItem(g_hModelMenu[langID], finalOutput, name);
			}
			
		}
		
		g_iTotalModelsAvailable++;
	} while (KvGotoNextKey(kv));
	KvRewind(kv);
	
	if (g_iTotalModelsAvailable == 0)
	{
		SetFailState("No models parsed in %s.cfg", map);
		return;
	}
}

GetLanguageID(const String:langCode[])
{
	for(new i=0;i<MAX_LANGUAGES;i++)
	{
		if(StrEqual(g_sModelMenuLanguage[i], langCode))
			return i;
	}
	return -1;
}

GetClientLanguageID(client, String:languageCode[]="", maxlen=0)
{
	decl String:langCode[4];
	GetLanguageInfo(GetClientLanguage(client), langCode, sizeof(langCode));
	// is client's prefered language available?
	new langID = GetLanguageID(langCode);
	if(langID != -1)
	{
		strcopy(languageCode, maxlen, langCode);
		return langID; // yes.
	}
	else
	{
		GetLanguageInfo(GetServerLanguage(), langCode, sizeof(langCode));
		// is default server language available?
		langID = GetLanguageID(langCode);
		if(langID != -1)
		{
			strcopy(languageCode, maxlen, langCode);
			return langID; // yes.
		}
		else
		{
			// default to english
			for(new i=0;i<MAX_LANGUAGES;i++)
			{
				if(StrEqual(g_sModelMenuLanguage[i], "en"))
				{
					strcopy(languageCode, maxlen, "en");
					return i;
				}
			}
			
			// english not found? happens on custom map configs e.g.
			// use the first language available
			// this should always work, since we would have SetFailState() on parse
			if(strlen(g_sModelMenuLanguage[0]) > 0)
			{
				strcopy(languageCode, maxlen, g_sModelMenuLanguage[0]);
				return 0;
			}
		}
	}
	// this should never happen
	return -1;
}

GetNextLangID()
{
	for(new i=0;i<MAX_LANGUAGES;i++)
	{
		if(strlen(g_sModelMenuLanguage[i]) == 0)
			return i;
	}
	SetFailState("Can't handle more than %d languages. Increase MAX_LANGUAGES and recompile.", MAX_LANGUAGES);
	return -1;
}

// Check if a player has a bad convar value set
bool:IsConVarCheater(client)
{
	for(new i=0;i<sizeof(cheat_commands);i++)
	{
		if(g_bConVarViolation[client][i])
		{
			return true;
		}
	}
	return false;
}

bool:IsPlayerAFK(client)
{
	new Float:fOrigin[3];
	GetClientAbsOrigin(client, fOrigin);
	
	// Did he move after spawn?
	if(UTIL_VectorEqual(fOrigin, g_fSpawnPosition[client], 0.1))
		return true;
	return false;
}

stock bool:UTIL_VectorEqual(const Float:vec1[3], const Float:vec2[3], const Float:tolerance)
{
	for(new i=0;i<3;i++)
		if(vec1[i] > (vec2[i] + tolerance) || vec1[i] < (vec2[i] - tolerance))
			return false;
	return true;
}

// Fade a players screen to black (amount=0) or removes the fade (amount=255)
PerformBlind(client, amount)
{	
	new mode;
	if(amount == 0)
		mode = FFADE_PURGE;
	else
		mode = FFADE_STAYOUT;
	
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	if(StrEqual(theFolder, "cstrike"))
	{
		Client_ScreenFade(client, 1536, mode, 1536, 0, 0, 0, amount);
	}
	else if(StrEqual(theFolder, "csgo"))
	{
		new Handle:hFadeClient = StartMessageOne("Fade", client);
		PbSetInt(hFadeClient, "duration", 1);
		PbSetInt(hFadeClient, "hold_time", 3);
		if(amount == 0)
		{
			PbSetInt(hFadeClient, "flags", FFADE_PURGE);
		}
		else
		{
			PbSetInt(hFadeClient, "flags", FFADE_STAYOUT);
		}
		PbSetColor(hFadeClient, "clr", {0, 0, 0, 255});
		EndMessage();
	}
}

// set a random model to a client
SetRandomModel(client)
{
	// give him a random one.
	decl String:ModelPath[80], String:finalPath[100], String:ModelName[60];
	decl String:langCode[4], String:sHeightFix[35], String:sTax[32];
	new RandomNumber = GetRandomInt(0, g_iTotalModelsAvailable-1);	
	new currentI = 0;
	new iTax;
	new iAccountValue = GetEntData(client, g_iAccount);
	new bool:bUseTaxedInRandom = GetConVarBool(g_hCVUseTaxedInRandom);
	KvGotoFirstSubKey(kv);
	do
	{
		if(currentI == RandomNumber)
		{
			// Check for enough money
			KvGetString(kv, "tax", sTax, sizeof(sTax), "noo");
			if(!StrEqual(sTax, "noo"))
			{
				iTax = StringToInt(sTax);
				// He doesn't have enough money? skip this one
				if(!bUseTaxedInRandom || iTax > iAccountValue)
					continue;
				
				// Get the money
				SetEntData(client, g_iAccount, iAccountValue - iTax, 4, true);
				
				PrintToChat(client, "%s%t", PREFIX, "tax charged", iTax);
			}
			
			// set the model
			KvGetSectionName(kv, ModelPath, sizeof(ModelPath));
			
			FormatEx(finalPath, sizeof(finalPath), "models/%s.mdl", ModelPath);
			
			// Put him down before changing the model again
			if(g_bClientIsHigher[client])
			{
				new Float:vecClientOrigin[3];
				GetClientAbsOrigin(client, vecClientOrigin);
				vecClientOrigin[2] -= g_iFixedModelHeight[client];
				TeleportEntity(client, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(client, MOVETYPE_WALK);
				g_bClientIsHigher[client] = false;
			}
			
			SetEntityModel(client, finalPath);
			
			// Check for heightfixed models
			KvGetString(kv, "heightfix", sHeightFix, sizeof(sHeightFix), "noo");
			if(!StrEqual(sHeightFix, "noo"))
			{
				g_iFixedModelHeight[client] = StringToFloat(sHeightFix);
				PrintToChat(client, "%s%t", PREFIX, "is heightfixed");
			}
			else
			{
				g_iFixedModelHeight[client] = 0.0;
			}
			
			if(!IsFakeClient(client))
			{
				// print name in chat
				GetClientLanguageID(client, langCode, sizeof(langCode));
				KvGetString(kv, langCode, ModelName, sizeof(ModelName));
				PrintToChat(client, "%s%t \x01%s.", PREFIX, "Model Changed", ModelName);
			}
			break;
		}
		currentI++;
	} while (KvGotoNextKey(kv));
	
	KvRewind(kv);	
	g_iModelChangeCount[client]++;
	
	// display the help menu afterwards on first spawn
	if(GetConVarBool(g_hCVShowHideHelp) && g_bFirstSpawn[client])
	{
		Display_Help(client, 0);
		g_bFirstSpawn[client] = false;
	}
}

bool:SetThirdPersonView(client, bool:third)
{
	if(third && !g_bInThirdPersonView[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		g_bInThirdPersonView[client] = true;
		return true;
	}
	else if(!third && g_bInThirdPersonView[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		g_bInThirdPersonView[client] = false;
		return true;
	}
	return false;
}

stock StripPlayerWeapons(client)
{
	new iWeapon = -1;
	for(new i=CS_SLOT_PRIMARY;i<=CS_SLOT_C4;i++)
	{
		while((iWeapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iWeapon);
			RemoveEdict(iWeapon);
		}
	}
}

/*
* 
* Handle ConVars
* 
*/
// Monitor the protected cvars and... well protect them ;)
public OnCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!g_bEnableHnS)
		return;
	
	decl String:cvarName[50];
	GetConVarName(convar, cvarName, sizeof(cvarName));
	for(new i=0;i<sizeof(protected_cvars);i++)
	{
		if(StrEqual(protected_cvars[i], cvarName) && StringToInt(newValue) != forced_values[i])
		{
			SetConVarInt(convar, forced_values[i]);
			PrintToServer("Hide and Seek: %T", "protected cvar", LANG_SERVER);
			break;
		}
	}
}

// directly change the hider speed on change
public OnChangeHiderSpeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!g_bEnableHnS)
		return;
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			SetEntDataFloat(i, g_flLaggedMovementValue, GetConVarFloat(g_hCVHiderSpeed), true);
	}
}

// directly change the hider speed on change
public OnChangeAntiCheat(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!g_bEnableHnS)
		return;
	
	if(StrEqual(oldValue, newValue))
		return;
	
	// disable anticheat
	if(StrEqual(newValue, "0"))
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				if(g_hCheckVarTimer[i] != INVALID_HANDLE)
				{
					KillTimer(g_hCheckVarTimer[i]);
					g_hCheckVarTimer[i] = INVALID_HANDLE;
				}
				if(g_hCheatPunishTimer[i] != INVALID_HANDLE)
				{
					KillTimer(g_hCheatPunishTimer[i]);
					g_hCheatPunishTimer[i] = INVALID_HANDLE;
				}
			}
		}
	}
	// enable anticheat
	else if(StrEqual(newValue, "1"))
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_hCheckVarTimer[i] == INVALID_HANDLE)
			{
				g_hCheckVarTimer[i] = CreateTimer(1.0, StartVarChecker, i, TIMER_REPEAT);
			}
		}
	}
}

// disable/enable plugin and restart round
public RestartGame(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!g_bEnableHnS)
		return;
	
	// don't execute if it's unchanged
	if(StrEqual(oldValue, newValue))
		return;
	
	// disable - it's been enabled before.
	if(!StrEqual(newValue, "0"))
	{
		// round has ended. used to not decrease seekers hp on shoot
		g_bRoundEnded = true;
		
		g_iFirstCTSpawn = 0;
		g_iFirstTSpawn = 0;
		
		if(g_hShowCountdownTimer != INVALID_HANDLE)
		{
			KillTimer(g_hShowCountdownTimer);
			g_hShowCountdownTimer = INVALID_HANDLE;
		}
		
		if(g_hRoundTimeTimer != INVALID_HANDLE)
		{
			KillTimer(g_hRoundTimeTimer);
			g_hRoundTimeTimer = INVALID_HANDLE;
		}
		
		if(g_hWhistleDelay != INVALID_HANDLE)
		{
			KillTimer(g_hWhistleDelay);
			g_hWhistleDelay = INVALID_HANDLE;
		}
		
		// Switch the flagged players to CT
		CreateTimer(0.1, Timer_SwitchTeams, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
// disable/enable plugin and restart round
public Cfg_OnChangeEnable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// don't execute if it's unchanged
	if(StrEqual(oldValue, newValue))
		return;
	
	// disable - it's been enabled before.
	if(StrEqual(newValue, "0"))
	{
		UnhookConVarChange(g_hCVAntiCheat, OnChangeAntiCheat);
		UnhookConVarChange(g_hCVHiderSpeed, OnChangeHiderSpeed);
		
		// Unhooking events
		UnhookEvent("player_spawn", Event_OnPlayerSpawn);
		UnhookEvent("weapon_fire", Event_OnWeaponFire);
		UnhookEvent("player_death", Event_OnPlayerDeath);
		UnhookEvent("player_blind", Event_OnPlayerBlind);
		UnhookEvent("round_start", Event_OnRoundStart);
		UnhookEvent("round_end", Event_OnRoundEnd);
		UnhookEvent("player_team", Event_OnPlayerTeam);
		UnhookEvent("item_pickup", Event_OnItemPickup);
		
		// unprotect the cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			// reset old cvar values
			if(g_hProtectedConvar[i] == INVALID_HANDLE)
				continue;
			UnhookConVarChange(g_hProtectedConvar[i], OnCvarChange);
			SetConVarInt(g_hProtectedConvar[i], previous_values[i], true);
		}
		
		// stop advertising spam
		if(g_hSpamCommandsTimer != INVALID_HANDLE)
		{
			KillTimer(g_hSpamCommandsTimer);
			g_hSpamCommandsTimer = INVALID_HANDLE;
		}
		
		// stop countdown
		if(g_hShowCountdownTimer != INVALID_HANDLE)
		{
			KillTimer(g_hShowCountdownTimer);
			g_hShowCountdownTimer = INVALID_HANDLE;
		}
		
		// stop roundtime counter
		if(g_hRoundTimeTimer != INVALID_HANDLE)
		{
			KillTimer(g_hRoundTimeTimer);
			g_hRoundTimeTimer = INVALID_HANDLE;
		}
		
		// close handles
		if(kv != INVALID_HANDLE)
			CloseHandle(kv);
		for(new i=0;i<MAX_LANGUAGES;i++)
		{
			if(g_hModelMenu[i] != INVALID_HANDLE)
			{
				CloseHandle(g_hModelMenu[i]);
				g_hModelMenu[i] = INVALID_HANDLE;
			}
			Format(g_sModelMenuLanguage[i], 4, "");
		}
		
		for(new c=1;c<=MaxClients;c++)
		{
			if(!IsClientInGame(c))
				continue;
			
			// stop cheat checking
			if(!IsFakeClient(c))
			{
				if(g_hCheckVarTimer[c] != INVALID_HANDLE)
				{
					KillTimer(g_hCheckVarTimer[c]);
					g_hCheckVarTimer[c] = INVALID_HANDLE;
				}
				if(g_hCheatPunishTimer[c] != INVALID_HANDLE)
				{
					KillTimer(g_hCheatPunishTimer[c]);
					g_hCheatPunishTimer[c] = INVALID_HANDLE;
				}
			}
			
			// Unhook weapon pickup
			SDKUnhook(c, SDKHook_WeaponCanUse, OnWeaponCanUse);
			
			// Unhook attacking
			SDKUnhook(c, SDKHook_TraceAttack, OnTraceAttack);
			
			// reset every players vars
			OnClientDisconnect(c);
		}
		
		g_bEnableHnS = false;
		// restart game to reset the models and scores
		ServerCommand("mp_restartgame 1");
	}
	else if(StrEqual(newValue, "1"))
	{
		// hook the convars again
		HookConVarChange(g_hCVHiderSpeed, OnChangeHiderSpeed);
		HookConVarChange(g_hCVAntiCheat, OnChangeAntiCheat);
		
		// Hook events again
		HookEvent("player_spawn", Event_OnPlayerSpawn);
		HookEvent("weapon_fire", Event_OnWeaponFire);
		HookEvent("player_death", Event_OnPlayerDeath);
		HookEvent("player_blind", Event_OnPlayerBlind);
		HookEvent("round_start", Event_OnRoundStart);
		HookEvent("round_end", Event_OnRoundEnd);
		HookEvent("player_team", Event_OnPlayerTeam);
		HookEvent("item_pickup", Event_OnItemPickup);
		
		// set bad server cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			g_hProtectedConvar[i] = FindConVar(protected_cvars[i]);
			if(g_hProtectedConvar[i] == INVALID_HANDLE)
				continue;
			previous_values[i] = GetConVarInt(g_hProtectedConvar[i]);
			SetConVarInt(g_hProtectedConvar[i], forced_values[i], true);
			HookConVarChange(g_hProtectedConvar[i], OnCvarChange);
		}
		// start advertising spam
		g_hSpamCommandsTimer = CreateTimer(120.0, SpamCommands, 0);
		
		for(new c=1;c<=MaxClients;c++)
		{
			if(!IsClientInGame(c))
				continue;
			
			// start cheat checking
			if(!IsFakeClient(c) && GetConVarBool(g_hCVAntiCheat) && g_hCheckVarTimer[c] == INVALID_HANDLE)
			{
				g_hCheckVarTimer[c] = CreateTimer(1.0, StartVarChecker, c, TIMER_REPEAT);
			}
			
			// Hook weapon pickup
			SDKHook(c, SDKHook_WeaponCanUse, OnWeaponCanUse);
			
			// Hook attack to hide blood
			SDKHook(c, SDKHook_TraceAttack, OnTraceAttack);
		}
		
		g_bEnableHnS = true;
		// build the menu and setup the hostage_rescue zone
		OnMapStart();
		
		// restart game to reset the models and scores
		ServerCommand("mp_restartgame 1");
	}
}

// check the given cheat cvars on every client
public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if(!IsClientInGame(client))
		return;
	
	new bool:match = StrEqual(cvarValue, "0");
	
	for(new i=0;i<sizeof(cheat_commands);i++)
	{
		if(!StrEqual(cheat_commands[i], cvarName))
			continue;
		
		if(!match)
		{
			g_bConVarViolation[client][i] = true;
			// only spam the message every 5 checks
			if(g_iConVarMessage[client][i] == 0)
			{
				PrintToChat(client, "%s%t\x04 %s 0", PREFIX, "Print to console", cvarName);
				PrintHintText(client, "%t %s 0", "Print to console", cvarName);
			}
			g_iConVarMessage[client][i]++;
			if(g_iConVarMessage[client][i] > 5)
				g_iConVarMessage[client][i] = 0;
		}
		else
			g_bConVarViolation[client][i] = false;
	}
}

stock Client_ResetFakeProp(client)
{
	if(IsFakeClient(client))
		return;
	
	new entity = g_iFreezeEntity[client];
	if (entity > 0) 
	{
		if (IsValidEntity(entity)) AcceptEntityInput(entity, "kill");
		g_iFreezeEntity[client] = -1;
	}
	
	if(IsClientInGame(client))
	{
		g_bIsFreezed[client] = false;
	}
}

stock Client_UpdateFakeProp(client)
{
	if(IsFakeClient(client))
		return;
	
	if(!IsClientInGame(client))
	{
		Client_ResetFakeProp(client);
		return;
	}
	
	new bool:showprop = true;
	
	//Not alive, reset prop
	if(!IsPlayerAlive(client))
	{
		if(g_bShowFakeProp[client]) 
		{
			g_bShowFakeProp[client] = false;
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		}
		Client_ResetFakeProp(client);
		return;
	}
	
	//Wrong team, reset prop
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		if(g_bShowFakeProp[client]) 
		{
			g_bShowFakeProp[client] = false;
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		}
		Client_ResetFakeProp(client);
		return;
	}
	
	//No fake prop exist? Create a one
	if(g_iFreezeEntity[client] <= 0)
	{
		if(g_bShowFakeProp[client]) 
		{
			g_bShowFakeProp[client] = false;
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		}
		Client_ReCreateFakeProp(client);
		return;
	}
	
	//Not a valid prop? Create a new one
	if(!Entity_IsValid(g_iFreezeEntity[client]))
	{
		if(g_bShowFakeProp[client]) 
		{
			g_bShowFakeProp[client] = false;
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		}
		Client_ReCreateFakeProp(client);
		return;
	}
	
	//Don't use fake prop in air and if highfix is enabled while moving
	if(!(GetEntityFlags(client) & FL_ONGROUND) && !g_bIsFreezed[client] && !g_bClientIsHigher[client])
	{
		showprop = false;
	}
	
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity); //velocity
	new Float:currentspeed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	
	//Player is moving fast?
	if(currentspeed >= 160.0)
	{
		showprop = false;
	}
	
	new Float:ang_eye[3], Float:ang_abs[3];
	GetClientEyeAngles(client, ang_eye);
	GetClientAbsAngles(client, ang_abs);
	
	decl String:fullPath[100];
	GetClientModel(client, fullPath, sizeof(fullPath));
	
	new Float:place[3], Float:place2[3], Float:secondpos[3];
	
	GetClientAbsOrigin(client, place);

	ang_eye[0] = 0.0; //no x-axis rotation
	ang_eye[2] = 0.0; //no z-axis rotation
	place[0] -= 0.0;
	place2[0] = 0.0;
	
	if(g_iFixedModelHeight[client] < 0.0)
	{
		place[2] += g_iFixedModelHeight[client];
		place2[2] += g_iFixedModelHeight[client];
	}
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", secondpos);
	AddVectors(place2, secondpos, place2);
	
	decl String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	if(StrEqual(theFolder, "cstrike"))
	{
			if(g_bIsFreezed[client]) 
			TeleportEntity(g_iFreezeEntity[client], place, NULL_VECTOR, place2);
			else TeleportEntity(g_iFreezeEntity[client], place, ang_eye, place2);
			
			//Toggle visibility
			if(g_bShowFakeProp[client] != showprop)
			{
				g_bShowFakeProp[client] = showprop;
				
				if(showprop)
				{
					SetEntityRenderMode(g_iFreezeEntity[client], RENDER_TRANSCOLOR);
					SetEntityRenderMode(client, RENDER_NONE);
				}
				else
				{
					SetEntityRenderMode(g_iFreezeEntity[client], RENDER_NONE);
					SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				}
			}
			
			if(g_bIsFreezed[client]) 
			TeleportEntity(g_iFreezeEntity[client], place, NULL_VECTOR, place2);
			else TeleportEntity(g_iFreezeEntity[client], place, ang_eye, place2);
	
	}
}
	
stock Client_ReCreateFakeProp(client)
{
	if(IsFakeClient(client))
		return;
	
	//delete old one if valid
	new entity_old = g_iFreezeEntity[client];
	if (entity_old > 0) 
	{
		if (IsValidEntity(entity_old)) AcceptEntityInput(entity_old, "kill");
		g_iFreezeEntity[client] = -1;
	}
	
	//Det model
	decl String:fullPath[100];
	GetClientModel(client, fullPath, sizeof(fullPath));
	
	//Create Fake Model
	new entity = CreateEntityByName("prop_physics_override");
	if (IsValidEntity(entity))
	{
		g_iFreezeEntity[client] = entity;
		PrecacheModel(fullPath, true);
		SetEntityModel(entity, fullPath);
		SetEntityMoveType(entity, MOVETYPE_NONE);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 17);
		DispatchKeyValue(entity, "targetname", "prop");
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 12);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
		DispatchSpawn(entity);
		SetEntData(entity, g_Freeze, FL_CLIENT|FL_ATCONTROLS, 4, true);
		SetEntPropEnt(entity, Prop_Data, "m_hLastAttacker", client);
	}
	else g_iFreezeEntity[client] = -1;
}