#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define PLUGIN_VERSION "1.4.0"

// that's what GetLanguageCount() got me
#define MAX_LANGUAGES 27

#define PREFIX "\x04Hide and Seek \x01> \x03"

// plugin cvars
new Handle:hns_cfg_enable = INVALID_HANDLE;
new Handle:hns_cfg_freezects = INVALID_HANDLE;
new Handle:hns_cfg_freezetime = INVALID_HANDLE;
new Handle:hns_cfg_changelimit = INVALID_HANDLE;
new Handle:hns_cfg_changelimittime = INVALID_HANDLE;
new Handle:hns_cfg_autochoose = INVALID_HANDLE;
new Handle:hns_cfg_whistle = INVALID_HANDLE;
new Handle:hns_cfg_whistle_times = INVALID_HANDLE;
new Handle:hns_cfg_whistle_delay = INVALID_HANDLE;
new Handle:hns_cfg_anticheat = INVALID_HANDLE;
new Handle:hns_cfg_cheat_punishment = INVALID_HANDLE;
new Handle:hns_cfg_hider_win_frags = INVALID_HANDLE;
new Handle:hns_cfg_slay_seekers = INVALID_HANDLE;
new Handle:hns_cfg_hp_seeker_enable = INVALID_HANDLE;
new Handle:hns_cfg_hp_seeker_dec = INVALID_HANDLE;
new Handle:hns_cfg_hp_seeker_inc = INVALID_HANDLE;
new Handle:hns_cfg_hp_seeker_bonus = INVALID_HANDLE;
new Handle:hns_cfg_opacity_enable = INVALID_HANDLE;
new Handle:hns_cfg_hidersspeed = INVALID_HANDLE;
new Handle:hns_cfg_disable_rightknife = INVALID_HANDLE;
new Handle:hns_cfg_disable_ducking = INVALID_HANDLE;
new Handle:hns_cfg_auto_thirdperson = INVALID_HANDLE;
new Handle:hns_cfg_hider_freeze_mode = INVALID_HANDLE;
new Handle:hns_cfg_hide_blood = INVALID_HANDLE;
new Handle:hns_cfg_show_hidehelp = INVALID_HANDLE;
new Handle:hns_cfg_show_progressbar = INVALID_HANDLE;
new Handle:hns_cfg_ct_ratio = INVALID_HANDLE;
new Handle:hns_cfg_disable_use = INVALID_HANDLE;
new Handle:hns_cfg_hider_freeze_inair = INVALID_HANDLE;

// primary enableswitch
new bool:g_EnableHnS = true;

// config and menu handles
new Handle:g_ModelMenu[MAX_LANGUAGES] = {INVALID_HANDLE, ...};
new String:g_ModelMenuLanguage[MAX_LANGUAGES][4];
new Handle:kv;

// offsets
new g_Render;
new g_Radar;
new g_Bomb;
new g_Freeze;
new g_iHasNightVision;
new g_flLaggedMovementValue;
new g_flProgressBarStartTime;
new g_iProgressBarDuration;
new g_iAccount;

new bool:g_InThirdPersonView[MAXPLAYERS+2] = {false,...};
new bool:g_IsFreezed[MAXPLAYERS+2] = {false,...};
new Handle:g_RoundTimeTimer = INVALID_HANDLE;
new Handle:g_roundTime = INVALID_HANDLE;
new g_iRoundStartTime = 0;
new g_iPlayerManager;

new g_FirstCTSpawn = 0;
new Handle:g_ShowCountdownTimer = INVALID_HANDLE;
new Handle:g_SpamCommandsTimer = INVALID_HANDLE;
new bool:g_RoundEnded = false;
new bool:g_FirstSpawn[MAXPLAYERS+2] = {true,...};

// Cheat cVar part
new Handle:g_CheckVarTimer[MAXPLAYERS+2] = {INVALID_HANDLE,...};
new String:cheat_commands[][] = {"cl_radaralpha", "r_shadows"};
new bool:g_ConVarViolation[MAXPLAYERS+2][2]; // 2 = amount of cheat_commands. update if you add one.
new g_ConVarMessage[MAXPLAYERS+2][2]; // 2 = amount of cheat_commands. update if you add one.
new Handle:g_CheatPunishTimer[MAXPLAYERS+2] = {INVALID_HANDLE};

// Terrorist Modelchange stuff
new g_TotalModelsAvailable = 0;
new g_ModelChangeCount[MAXPLAYERS+2] = {0,...};
new bool:g_AllowModelChange[MAXPLAYERS+2] = {true,...};
new Handle:g_AllowModelChangeTimer[MAXPLAYERS+2] = {INVALID_HANDLE,...};
// Model ground fix
new Float:g_FixedModelHeight[MAXPLAYERS+2] = {0.0,...};
new bool:g_bClientIsHigher[MAXPLAYERS+2] = {false,...};
new g_iLowModelSteps[MAXPLAYERS+2] = {0,...};

new bool:g_IsCTWaiting[MAXPLAYERS+2] = {false,...};
new Handle:g_UnfreezeCTTimer[MAXPLAYERS+2] = {INVALID_HANDLE,...};

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
								  "mp_teams_unbalance_limit"
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
					   0 // mp_teams_unbalance_limit
					  };
new previous_values[12] = {0,...}; // save previous values when forcing above, so we can restore the config if hns is disabled midgame. !same as comment next line!
new Handle:g_ProtectedConvar[12] = {INVALID_HANDLE,...}; // 12 = amount of protected_cvars. update if you add one.
new Handle:g_forceCamera = INVALID_HANDLE;

// whistle sounds
new g_WhistleCount[MAXPLAYERS+2] = {0,...};
new Handle:g_WhistleDelay = INVALID_HANDLE;
new bool:g_WhistlingAllowed = true;
new String:whistle_sounds[][] = {"labodtupue/whistle.wav"};

// Teambalance
new g_iLastJoinedCT = -1;
new bool:g_bCTToSwitch[MAXPLAYERS+2] = {false,...};

public Plugin:myinfo = 
{
	name = "Hide and Seek",
	author = "Jannik 'Peace-Maker' Hartung and Vladislav Dolgov",
	description = "Terrorists set a model and hide, CT seek terrorists.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/ | http://www.elistor.ru/"
};

public OnPluginStart()
{
	CreateConVar("sm_hns_version", PLUGIN_VERSION, "Hide and seek", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Config cvars
	hns_cfg_enable = 			CreateConVar("sm_hns_enable", "1", "Enable the Hide and Seek Mod?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_freezects = 		CreateConVar("sm_hns_freezects", "1", "Should CTs get freezed and blinded on spawn?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_freezetime = 		CreateConVar("sm_hns_freezetime", "25.0", "How long should the CTs are freezed after spawn?", FCVAR_PLUGIN, true, 1.00, true, 120.00);
	hns_cfg_changelimit = 		CreateConVar("sm_hns_changelimit", "2", "How often a T is allowed to choose his model ingame? 0 = unlimited", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_changelimittime = 	CreateConVar("sm_hns_changelimittime", "30.0", "How long should a T be allowed to change his model again after spawn?", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_autochoose = 		CreateConVar("sm_hns_autochoose", "0", "Should the plugin choose models for the hiders automatically?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_whistle = 			CreateConVar("sm_hns_whistle", "1", "Are terrorists allowed to whistle?", FCVAR_PLUGIN);
	hns_cfg_whistle_times = 	CreateConVar("sm_hns_whistle_times", "5", "How many times a hider is allowed to whistle per round?", FCVAR_PLUGIN);
	hns_cfg_whistle_delay =		CreateConVar("sm_hns_whistle_delay", "25.0", "How long after spawn should we delay the use of whistle?.", FCVAR_PLUGIN, true, 0.00, true, 120.00);
	hns_cfg_anticheat = 		CreateConVar("sm_hns_anticheat", "0", "Check player cheat convars, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_cheat_punishment = 	CreateConVar("sm_hns_cheat_punishment", "1", "How to punish players with wrong cvar values after 15 seconds? 0: Disabled. 1: Switch to Spectator. 2: Kick", FCVAR_PLUGIN, true, 0.00, true, 2.00);
	hns_cfg_hider_win_frags = 	CreateConVar("sm_hns_hider_win_frags", "5", "How many frags should surviving terrorists gain?", FCVAR_PLUGIN, true, 0.00, true, 10.00);
	hns_cfg_slay_seekers = 		CreateConVar("sm_hns_slay_seekers", "0", "Should we slay all seekers on round end and there are still some hiders alive? (Default: 0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_hp_seeker_enable = 	CreateConVar("sm_hns_hp_seeker_enable", "1", "Should CT lose HP when shooting, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_hp_seeker_dec = 	CreateConVar("sm_hns_hp_seeker_dec", "5", "How many hp should a CT lose on shooting?", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_hp_seeker_inc = 	CreateConVar("sm_hns_hp_seeker_inc", "15", "How many hp should a CT gain when hitting a hider?", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_hp_seeker_bonus = 	CreateConVar("sm_hns_hp_seeker_bonus", "50", "How many hp should a CT gain when killing a hider?", FCVAR_PLUGIN, true, 0.00);
	hns_cfg_opacity_enable = 	CreateConVar("sm_hns_opacity_enable", "0", "Should T get more invisible on low hp, 0 = off/1 = on.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hns_cfg_hidersspeed  = 		CreateConVar("sm_hns_hidersspeed", "1.00", "Hiders speed (Default: 1.00).", FCVAR_PLUGIN, true, 1.00, true, 3.00);
	hns_cfg_disable_rightknife =CreateConVar("sm_hns_disable_rightknife", "1", "Disable rightclick for CTs with knife? Prevents knifing without losing heatlh. (Default: 1).", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_disable_ducking =	CreateConVar("sm_hns_disable_ducking", "1", "Disable ducking. (Default: 1).", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_auto_thirdperson =	CreateConVar("sm_hns_auto_thirdperson", "1", "Enable thirdperson view for hiders automatically. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_hider_freeze_mode =	CreateConVar("sm_hns_hider_freeze_mode", "2", "0: Disables /freeze command for hiders, 1: Only freeze on position, be able to move camera, 2: Freeze completely (no cameramovements) (Default: 2)", FCVAR_PLUGIN, true, 0.00, true, 2.00);
	hns_cfg_hide_blood =		CreateConVar("sm_hns_hide_blood", "1", "Hide blood on hider damage. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_show_hidehelp =		CreateConVar("sm_hns_show_hidehelp", "1", "Show helpmenu explaining the game on first player spawn. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_show_progressbar =	CreateConVar("sm_hns_show_progressbar", "1", "Show progressbar for last 15 seconds of freezetime. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_ct_ratio =			CreateConVar("sm_hns_ct_ratio", "3", "The ratio of hiders to 1 seeker. 0 to disables teambalance. (Default: 3:1)", FCVAR_PLUGIN, true, 1.00, true, 64.00);
	hns_cfg_disable_use =		CreateConVar("sm_hns_disable_use", "1", "Disable CTs pushing things. (Default: 1)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	hns_cfg_hider_freeze_inair =CreateConVar("sm_hns_hider_freeze_inair", "0", "Are hiders allowed to freeze in the air? (Default: 0)", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	
	g_EnableHnS = GetConVarBool(hns_cfg_enable);
	HookConVarChange(hns_cfg_enable, Cfg_OnChangeEnable);
	HookConVarChange(FindConVar("mp_restartgame"), RestartGame);
	
	if(g_EnableHnS)
	{
		// !ToDo: Exclude hooks and other EnableHnS dependand functions into one seperate function.
		// Now you need to add the hooks to the Cfg_OnChangeEnable callback too..
		HookConVarChange(hns_cfg_hidersspeed, OnChangeHiderSpeed);
		HookConVarChange(hns_cfg_anticheat, OnChangeAntiCheat);
		
		// Hooking events
		HookEvent("player_spawn", Event_OnPlayerSpawn);
		HookEvent("weapon_fire", Event_OnWeaponFire);
		HookEvent("player_death", Event_OnPlayerDeath);
		HookEvent("round_start", Event_OnRoundStart);
		HookEvent("round_end", Event_OnRoundEnd);
		HookEvent("player_team", Event_OnPlayerTeam);
		HookEvent("item_pickup", Event_OnItemPickup);
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
			g_ConVarViolation[x][y] = false;
			g_ConVarMessage[x][y] = 0;
		}
		if(IsClientInGame(x))
			OnClientPutInServer(x);
	}

	if(g_EnableHnS)
	{
		// start advertising spam
		g_SpamCommandsTimer = CreateTimer(120.0, SpamCommands, 0);
	}
	
	// hook cvars
	g_forceCamera =  FindConVar("mp_forcecamera");
	g_roundTime =  FindConVar("mp_roundtime");
	
	// get the offsets
	// for transparency
	g_Render = FindSendPropOffs("CAI_BaseNPC", "m_clrRender");
	if(g_Render == -1)
		SetFailState("Couldnt find the m_clrRender offset!");	
	
	// for hiding players on radar
	g_Radar = FindSendPropOffs("CCSPlayerResource", "m_bPlayerSpotted");
	if(g_Radar == -1)
		SetFailState("Couldnt find the m_bPlayerSpotted offset!");
	g_Bomb = FindSendPropOffs("CCSPlayerResource", "m_bBombSpotted");
	if(g_Bomb == -1)
		SetFailState("Couldnt find the m_bBombSpotted offset!");
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
	if(g_EnableHnS)
		ServerCommand("mp_restartgame 1");
}

public OnConfigsExecuted()
{
	if(g_EnableHnS)
	{
		// set bad server cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			g_ProtectedConvar[i] = FindConVar(protected_cvars[i]);
			previous_values[i] = GetConVarInt(g_ProtectedConvar[i]);
			SetConVarInt(g_ProtectedConvar[i], forced_values[i], true);
			HookConVarChange(g_ProtectedConvar[i], OnCvarChange);
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
	if(!g_EnableHnS)
		return;
	
	BuildMainMenu();
	for(new i=0;i<sizeof(whistle_sounds);i++)
		PrecacheSound(whistle_sounds[i], true);
	AddFileToDownloadsTable("sound/labodtupue/whistle.wav");  
	PrecacheSound("radio/go.wav", true);
	
	
	// prevent us from bugging after mapchange
	g_FirstCTSpawn = 0;
	
	if(g_ShowCountdownTimer != INVALID_HANDLE)
	{
		KillTimer(g_ShowCountdownTimer);
		g_ShowCountdownTimer = INVALID_HANDLE;
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
	
	// Hide players from being shown on the radar.
	// Thanks to javalia @ alliedmods.net
	g_iPlayerManager = FindEntityByClassname(0, "cs_player_manager");
	
	SDKHook(g_iPlayerManager, SDKHook_PreThink, Hook_PMOnPostThink);
	SDKHook(g_iPlayerManager, SDKHook_PreThinkPost, Hook_PMOnPostThink);
	SDKHook(g_iPlayerManager, SDKHook_Think, Hook_PMOnPostThink);
	SDKHook(g_iPlayerManager, SDKHook_PostThink, Hook_PMOnPostThink);
	SDKHook(g_iPlayerManager, SDKHook_PostThinkPost, Hook_PMOnPostThink);
}

public OnMapEnd()
{
	if(!g_EnableHnS)
		return;
	
	CloseHandle(kv);
	for(new i=0;i<MAX_LANGUAGES;i++)
	{
		if(g_ModelMenu[i] != INVALID_HANDLE)
		{
			CloseHandle(g_ModelMenu[i]);
			g_ModelMenu[i] = INVALID_HANDLE;
		}
		Format(g_ModelMenuLanguage[i], 4, "");
	}

}

public OnClientPutInServer(client)
{
	if(!g_EnableHnS)
		return;
	
	if(!IsFakeClient(client) && GetConVarBool(hns_cfg_anticheat))
		g_CheckVarTimer[client] = CreateTimer(1.0, StartVarChecker, client, TIMER_REPEAT);
	
	// Hook weapon pickup
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	
	// Hide Radar
	SDKHook(client, SDKHook_PreThink, OnPlayerThink);
	SDKHook(client, SDKHook_PreThinkPost, OnPlayerThink);
	SDKHook(client, SDKHook_Think, OnPlayerThink);
	SDKHook(client, SDKHook_PostThink, OnPlayerThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPlayerThink);
	
	// Hook attackings to hide blood
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public OnClientDisconnect(client)
{
	if(!g_EnableHnS)
		return;
	
	// set the default values for cvar checking
	if(!IsFakeClient(client))
	{
		for(new i=0;i<sizeof(cheat_commands);i++)
		{
			g_ConVarViolation[client][i] = false;
			g_ConVarMessage[client][i] = 0;
		}
	
		g_InThirdPersonView[client] = false;
		g_IsFreezed[client] = false;
		g_ModelChangeCount[client] = 0;
		g_IsCTWaiting[client] = false;
		g_WhistleCount[client] = 0;
		if (g_CheatPunishTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_CheatPunishTimer[client]);
			g_CheatPunishTimer[client] = INVALID_HANDLE;
		}
		if (g_AllowModelChange[client] && g_AllowModelChangeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_AllowModelChangeTimer[client]);
			g_AllowModelChangeTimer[client] = INVALID_HANDLE;
		}
		if(g_UnfreezeCTTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_UnfreezeCTTimer[client]);
			g_UnfreezeCTTimer[client] = INVALID_HANDLE;
		}
	}
	g_AllowModelChange[client] = true;
	g_FirstSpawn[client] = true;
	
	g_bClientIsHigher[client] = false;
	g_FixedModelHeight[client] = 0.0;
	g_iLowModelSteps[client] = 0;
	
	// Teambalancer
	g_bCTToSwitch[client] = false;
	CreateTimer(0.1, Timer_ChangeTeam, client, TIMER_FLAG_NO_MAPCHANGE);
	
	/*if (g_CheckVarTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_CheckVarTimer[client]);
		g_CheckVarTimer[client] = INVALID_HANDLE;
	}*/
}

// prevent players from ducking
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	new iInitialButtons = buttons;
	
	decl String:weaponName[30];
	// don't allow ct's to shoot in the beginning of the round
	new team = GetClientTeam(client);
	GetClientWeapon(client, weaponName, sizeof(weaponName));
	if(team == CS_TEAM_CT && g_IsCTWaiting[client] && (buttons & IN_ATTACK || buttons & IN_ATTACK2))
	{
		buttons &= ~IN_ATTACK;
		buttons &= ~IN_ATTACK2;
	} // disable rightclick knifing for cts
	else if(team == CS_TEAM_CT && GetConVarBool(hns_cfg_disable_rightknife) && buttons & IN_ATTACK2 && !strcmp(weaponName, "weapon_knife"))
	{
		buttons &= ~IN_ATTACK2;
	}
	
	// Modelfix
	if(g_FixedModelHeight[client] != 0.0 && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		new Float:vecVelocity[3];
		vecVelocity[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		vecVelocity[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		vecVelocity[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
		// Player isn't moving
		if(vecVelocity[0] == 0.0 && vecVelocity[1] == 0.0 && vecVelocity[2] == 0.0 && !(buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_JUMP))
		{
			new iGroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
			if(iGroundEntity != -1 && !g_bClientIsHigher[client])
			{
				new Float:vecClientOrigin[3];
				GetClientAbsOrigin(client, vecClientOrigin);
				vecClientOrigin[2] += g_FixedModelHeight[client];
				TeleportEntity(client, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
				SetEntityMoveType(client, MOVETYPE_NONE);
				g_bClientIsHigher[client] = true;
				g_iLowModelSteps[client] = 0;
			}
		}
		// Player is running for 60 thinks? make him visible for a short time
		else if(g_iLowModelSteps[client] == 60)
		{
			new iGroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
			if(iGroundEntity != -1 && !g_bClientIsHigher[client])
			{
				new Float:vecClientOrigin[3];
				GetClientAbsOrigin(client, vecClientOrigin);
				vecClientOrigin[2] += g_FixedModelHeight[client];
				TeleportEntity(client, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
			}
			g_iLowModelSteps[client] = 0;
		}
		// Player is moving
		else
		{
			if(g_bClientIsHigher[client])
			{
				new Float:vecClientOrigin[3];
				GetClientAbsOrigin(client, vecClientOrigin);
				vecClientOrigin[2] -= g_FixedModelHeight[client];
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
	if(buttons & IN_DUCK && GetConVarBool(hns_cfg_disable_ducking))
		buttons &= ~IN_DUCK;
	
	// disable use for everyone
	if(GetConVarBool(hns_cfg_disable_use) && buttons & IN_USE)
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
	if(g_EnableHnS && GetClientTeam(client) != CS_TEAM_CT)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Hook_PMOnPostThink(entity)
{	
	if(g_EnableHnS)
	{
		// hide players on radar
		for(new target = 0; target <= 65; target++){
			SetEntData(entity, g_Radar + target, 0, 4, true);
		}
		SetEntData(entity, g_Bomb, 0, 4, true);
	}
}

public OnPlayerThink(entity)
{
	if(g_EnableHnS)
	{
		// hide players on radar
		for(new target = 0; target <= 65; target++){
			SetEntData(g_iPlayerManager, g_Radar + target, 0, 4, true);
		}
		SetEntData(g_iPlayerManager, g_Bomb, 0, 4, true);
	}
}

// Used to block blood
// set a normal model right before death to avoid errors
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	if(GetClientTeam(victim) == CS_TEAM_T)
	{
		new remainingHealth = GetClientHealth(victim)-RoundToFloor(damage);
		
		// Attacker is a human?
		if(GetConVarBool(hns_cfg_hp_seeker_enable) && attacker > 0 && attacker <= MaxClients && IsPlayerAlive(attacker))
		{
			new decrease = GetConVarInt(hns_cfg_hp_seeker_dec);
			
			SetEntityHealth(attacker, GetClientHealth(attacker)+GetConVarInt(hns_cfg_hp_seeker_inc)+decrease);
			
			// the hider died? give extra health! need to add the decreased value again, since he fired his gun and lost hp.
			// possible "bug": seeker could be slayed because weapon_fire is called earlier than player_hurt.
			if(remainingHealth <= 0)
				SetEntityHealth(attacker, GetClientHealth(attacker)+GetConVarInt(hns_cfg_hp_seeker_bonus)+decrease);
		}
		
		// prevent errors in console because of missing death animation of prop ;)
		if(remainingHealth <= 0)
		{
			SetEntityModel(victim, "models/player/t_guerilla.mdl");
			return Plugin_Continue; // just let the damage get through
		}
		else if(GetConVarBool(hns_cfg_opacity_enable))
		{
			new alpha = 150 + RoundToNearest(10.5*float(remainingHealth/10));
			
			SetEntData(victim, g_Render+3, alpha, 1, true);
			SetEntityRenderMode(victim, RENDER_TRANSTEXTURE);
		}
		
		if(GetConVarBool(hns_cfg_hide_blood))
		{
			// Simulate the damage
			SetEntityHealth(victim, remainingHealth);
			
			// Don't show the blood!
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/*
* 
* Hooked Events
* 
*/
// Player Spawn event
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);

	if(team <= CS_TEAM_SPECTATOR || !IsPlayerAlive(client))
		return Plugin_Continue;
	else if(team == CS_TEAM_T) // Team T
	{
		// set the mp_forcecamera value correctly, so he can use thirdperson again
		if(!IsFakeClient(client) && GetConVarInt(g_forceCamera) == 1)
			SendConVarValue(client, g_forceCamera, "0");
		
		// reset model change count
		g_ModelChangeCount[client] = 0;
		g_InThirdPersonView[client] = false;
		if(!IsFakeClient(client) && g_AllowModelChangeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_AllowModelChangeTimer[client]);
			g_AllowModelChangeTimer[client] = INVALID_HANDLE;
		}
		g_AllowModelChange[client] = true;
		
		// Reset model fix height
		g_FixedModelHeight[client] = 0.0;
		g_bClientIsHigher[client] = false;
		
		// set the speed
		SetEntDataFloat(client, g_flLaggedMovementValue, GetConVarFloat(hns_cfg_hidersspeed), true);
		
		// reset the transparent
		if(GetConVarBool(hns_cfg_opacity_enable))
		{
			SetEntData(client,g_Render+3,255,1,true);
			SetEntityRenderMode(client, RENDER_TRANSTEXTURE);
		}
		
		new Float:changeLimitTime = GetConVarFloat(hns_cfg_changelimittime);
		
		// Assign a model to bots immediately and disable all menus or timers.
		if(IsFakeClient(client))
			g_AllowModelChangeTimer[client] = CreateTimer(0.1, DisableModelMenu, client);
		else
		{
			// only disable the menu, if it's not unlimited
			if(changeLimitTime > 0.0)
				g_AllowModelChangeTimer[client] = CreateTimer(changeLimitTime, DisableModelMenu, client);
			
			// Set them to thirdperson automatically
			if(GetConVarBool(hns_cfg_auto_thirdperson))
				SetThirdPersonView(client, true);
			
			if(GetConVarBool(hns_cfg_autochoose))
				SetRandomModel(client);
			else if(changeLimitTime > 0.0)
				DisplayMenu(g_ModelMenu[GetClientLanguageID(client)], client, RoundToFloor(changeLimitTime));
			else
				DisplayMenu(g_ModelMenu[GetClientLanguageID(client)], client, MENU_TIME_FOREVER);
		}
		
		g_WhistleCount[client] = 0;
		g_IsFreezed[client] = false;
		
		new Float:whistle_delay = GetConVarFloat(hns_cfg_whistle_delay);
		if(whistle_delay > 0.0 && g_WhistleDelay == INVALID_HANDLE)
		{
			g_WhistlingAllowed = false;
			g_WhistleDelay = CreateTimer(whistle_delay, Timer_AllowWhistle, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			g_WhistlingAllowed = true;
		}

		if(GetConVarBool(hns_cfg_freezects))
			PrintToChat(client, "%s%t", PREFIX, "seconds to hide", RoundToFloor(GetConVarFloat(hns_cfg_freezetime)));
		else
			PrintToChat(client, "%s%t", PREFIX, "seconds to hide", 0);
	}
	else if(team == CS_TEAM_CT) // Team CT
	{
		if(!IsFakeClient(client) && GetConVarInt(g_forceCamera) == 1)
			SendConVarValue(client, g_forceCamera, "1");
		
		new currentTime = GetTime();
		new Float:freezeTime = GetConVarFloat(hns_cfg_freezetime);
		// don't keep late spawning cts blinded longer than the others :)
		if(g_FirstCTSpawn == 0)
		{
			if(g_ShowCountdownTimer != INVALID_HANDLE)
			{
				KillTimer(g_ShowCountdownTimer);
				g_ShowCountdownTimer = INVALID_HANDLE;
				if(GetConVarBool(hns_cfg_show_progressbar))
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
			else if(GetConVarBool(hns_cfg_freezects))
			{
				// show time in center
				g_ShowCountdownTimer = CreateTimer(0.01, ShowCountdown, RoundToFloor(GetConVarFloat(hns_cfg_freezetime)));
			}
			g_FirstCTSpawn = currentTime;
		}
		// only freeze spawning players if the freezetime is still running.
		if(GetConVarBool(hns_cfg_freezects) && (float(currentTime - g_FirstCTSpawn) < freezeTime))
		{
			// Start freezing player
			CreateTimer(0.05, FreezePlayer, client);
			
			if(g_UnfreezeCTTimer[client] != INVALID_HANDLE)
			{
				KillTimer(g_UnfreezeCTTimer[client]);
				g_UnfreezeCTTimer[client] = INVALID_HANDLE;
			}
			
			// Stop freezing player
			g_UnfreezeCTTimer[client] = CreateTimer(freezeTime-float(currentTime - g_FirstCTSpawn), UnFreezePlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			
			PrintToChat(client, "%s%t", PREFIX, "Wait for t to hide", RoundToFloor(freezeTime-float(currentTime - g_FirstCTSpawn)));
			g_IsCTWaiting[client] = true;
		}
		
		// Give full money
		SetEntData(client, g_iAccount, 16000, 4, true);
		
		// show help menu on first spawn
		if(GetConVarBool(hns_cfg_show_hidehelp) && g_FirstSpawn[client])
		{
			Display_Help(client, 0);
			g_FirstSpawn[client] = false;
		}
	}
	
	return Plugin_Continue;
}

// subtract 5hp for every shot a seeker is giving
public Action:Event_OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	if(!GetConVarBool(hns_cfg_hp_seeker_enable) || g_RoundEnded)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new decreaseHP = GetConVarInt(hns_cfg_hp_seeker_dec);
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
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	g_RoundEnded = false;
	
	// When disabling +use or "e" button open all doors on the map and keep them opened.
	new bool:bUse = GetConVarBool(hns_cfg_disable_use);
	
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
	
	// show the roundtime in env_hudhint entity
	g_iRoundStartTime = GetTime();
	new realRoundTime = RoundToNearest(GetConVarFloat(g_roundTime)*60.0);
	g_RoundTimeTimer = CreateTimer(0.5, ShowRoundTime, realRoundTime, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}
// give terrorists frags
public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	// round has ended. used to not decrease seekers hp on shoot
	g_RoundEnded = true;
	
	g_FirstCTSpawn = 0;
	
	if(g_ShowCountdownTimer != INVALID_HANDLE)
	{
		KillTimer(g_ShowCountdownTimer);
		g_ShowCountdownTimer = INVALID_HANDLE;
	}
	
	if(g_RoundTimeTimer != INVALID_HANDLE)
	{
		KillTimer(g_RoundTimeTimer);
		g_RoundTimeTimer = INVALID_HANDLE;
	}
	
	if(g_WhistleDelay != INVALID_HANDLE)
	{
		KillTimer(g_WhistleDelay);
		g_WhistleDelay = INVALID_HANDLE;
	}
	
	new winnerTeam = GetEventInt(event, "winner");
	
	if(winnerTeam == CS_TEAM_T)
	{
		new increaseFrags = GetConVarInt(hns_cfg_hider_win_frags);
		
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
		
		if(GetConVarBool(hns_cfg_slay_seekers))
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
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_FixedModelHeight[client] != 0.0 && g_bClientIsHigher[client])
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_bClientIsHigher[client] = false;
	}
	g_FixedModelHeight[client] = 0.0;
	g_bClientIsHigher[client] = false;
	
	// Show guns again.
	SetThirdPersonView(client, false);
	
	// set the mp_forcecamera value correctly, so he can watch his teammates
	// This doesn't work. Even if the convar is set to 0, the hiders are only able to spectate their teammates..
	if(GetConVarInt(g_forceCamera) == 1)
	{
		if(!IsFakeClient(client) && GetClientTeam(client) != CS_TEAM_T)
			SendConVarValue(client, g_forceCamera, "1");
		else if(!IsFakeClient(client))
			SendConVarValue(client, g_forceCamera, "0");
	}
	
	if (!IsValidEntity(client) || IsPlayerAlive(client))
		return Plugin_Continue;
	
	// Unfreeze, if freezed before
	if(g_IsFreezed[client])
	{
		if(GetConVarInt(hns_cfg_hider_freeze_mode) == 1)
			SetEntityMoveType(client, MOVETYPE_WALK);
		else
		{
			SetEntData(client, g_Freeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		
		g_IsFreezed[client] = false;
	}
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
		return Plugin_Continue;
	
	RemoveEdict(ragdoll);
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_EnableHnS)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	new bool:disconnect = GetEventBool(event, "disconnect");
	
	// Handle the thirdperson view values
	// terrors are always allowed to view players in thirdperson
	if(client && !IsFakeClient(client) && GetConVarInt(g_forceCamera) == 1)
	{
		if(team == CS_TEAM_T)
			SendConVarValue(client, g_forceCamera, "0");
		else if(team != CS_TEAM_CT)
			SendConVarValue(client, g_forceCamera, "1");
	}
	
	// Player disconnected or joined spectator?
	if(disconnect || (team != CS_TEAM_CT && team != CS_TEAM_T))
		g_bCTToSwitch[client] = false;
	
	if(disconnect && g_iLastJoinedCT == client)
		g_iLastJoinedCT = -1;
	
	if(GetConVarFloat(hns_cfg_ct_ratio) == 0.0)
		return Plugin_Continue;
	
	// GetTeamClientCount() doesn't handle the teamchange we're called for in player_team,
	// so wait one frame to update the counts
	CreateTimer(0.1, Timer_ChangeTeam, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Event_OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_EnableHnS)
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
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	SetEntData(client, g_Freeze, FL_CLIENT|FL_ATCONTROLS, 4, true);
	SetEntityMoveType(client, MOVETYPE_NONE);
	PerformBlind(client, 255);
	
	return Plugin_Handled;
}

// Unfreeze player function
public Action:UnFreezePlayer(Handle:timer, any:client)
{
	
	g_UnfreezeCTTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	SetEntData(client, g_Freeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	if(!IsConVarCheater(client))
		PerformBlind(client, 0);
	
	g_IsCTWaiting[client] = false;
	
	EmitSoundToClient(client, "radio/go.wav");
	
	PrintToChat(client, "%s%t", PREFIX, "Go search");
		
	return Plugin_Handled;
}

public Action:DisableModelMenu(Handle:timer, any:client)
{
	
	g_AllowModelChangeTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	g_AllowModelChange[client] = false;
	
	if(IsPlayerAlive(client))
		PrintToChat(client, "%s%t", PREFIX, "Modelmenu Disabled");
	
	// didn't he chose a model?
	if(GetClientTeam(client) == CS_TEAM_T && g_ModelChangeCount[client] == 0)
	{
		// give him a random one.
		PrintToChat(client, "%s%t", PREFIX, "Did not choose model");
		SetRandomModel(client);
	}
	
	return Plugin_Handled;
}

public Action:StartVarChecker(Handle:timer, any:client)
{	
	if (!IsClientInGame(client))
		return Plugin_Handled;
	
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
		
		if(GetConVarInt(hns_cfg_cheat_punishment) != 0 && g_CheatPunishTimer[client] == INVALID_HANDLE)
		{
			g_CheatPunishTimer[client] = CreateTimer(15.0, PerformCheatPunishment, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if(!g_IsCTWaiting[client])
	{
		if(IsPlayerAlive(client))
			SetEntityMoveType(client, MOVETYPE_WALK);
		PerformBlind(client, 0);
	}
	
	return Plugin_Continue;
}

public Action:PerformCheatPunishment(Handle:timer, any:client)
{
	g_CheatPunishTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client) || !IsConVarCheater(client))
		return Plugin_Handled;
	
	new punishmentType = GetConVarInt(hns_cfg_cheat_punishment);
	if(punishmentType == 1 && GetClientTeam(client) != CS_TEAM_SPECTATOR )
	{
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		PrintToChatAll("%s%N %t", PREFIX, client, "Spectator Cheater");
	}
	else if(punishmentType == 2)
	{
		for(new i=0;i<sizeof(cheat_commands);i++)
			if(g_ConVarViolation[client][i])
				PrintToConsole(client, "Hide and Seek: %t %s 0", "Print to console", cheat_commands[i]);
		KickClient(client, "Hide and Seek: %t", "Kick bad cvars");
	}
	return Plugin_Handled;
}

// teach the players the /whistle and /tp commands
public Action:SpamCommands(Handle:timer, any:data)
{
	if(GetConVarBool(hns_cfg_whistle) && data == 1)
		PrintToChatAll("%s%t", PREFIX, "T type /whistle");
	else if(!GetConVarBool(hns_cfg_whistle) || data == 0)
	{
		for(new i=1;i<=MaxClients;i++)
			if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
				PrintToChat(i, "%s%t", PREFIX, "T type /tp");
	}
	g_SpamCommandsTimer = CreateTimer(120.0, SpamCommands, (data==0?1:0));
	return Plugin_Handled;
}

// show all players a countdown
// CT: I'm coming!
public Action:ShowCountdown(Handle:timer, any:freezeTime)
{
	new seconds = freezeTime - GetTime() + g_FirstCTSpawn;
	PrintCenterTextAll("%d", seconds);
	if(seconds <= 0)
	{
		g_ShowCountdownTimer = INVALID_HANDLE;
		if(GetConVarBool(hns_cfg_show_progressbar))
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
		return Plugin_Handled;
	}
	
	// m_iProgressBarDuration has a limit of 15 seconds, so start showing the bar on 15 seconds left.
	if(GetConVarBool(hns_cfg_show_progressbar) && (seconds) < 15)
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
	
	g_ShowCountdownTimer = CreateTimer(0.5, ShowCountdown, freezeTime);
	
	return Plugin_Handled;
}

public Action:ShowRoundTime(Handle:timer, any:roundTime)
{
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
		if(IsClientInGame(i) && g_InThirdPersonView[i])
		{
			new Handle:hBuffer = StartMessageOne("KeyHintText", i);
			BfWriteByte(hBuffer, 1);
			BfWriteString(hBuffer, timeLeft);
			EndMessage();
		}
	}
	
	if(seconds > 0)
		g_RoundTimeTimer = CreateTimer(0.5, ShowRoundTime, roundTime, TIMER_FLAG_NO_MAPCHANGE);
	else
		g_RoundTimeTimer = INVALID_HANDLE;
	
	return Plugin_Handled;
}

public Action:Timer_AllowWhistle(Handle:timer, any:data)
{
	g_WhistlingAllowed = true;
	
	g_WhistleDelay = INVALID_HANDLE;
	return Plugin_Handled;
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
}

public Action:Timer_ChangeTeam(Handle:timer, any:client)
{
	new iCTCount = GetTeamClientCount(CS_TEAM_CT);
	new iTCount = GetTeamClientCount(CS_TEAM_T);
	
	new iToBeSwitched = 0;
	
	// Check, how many cts are going to get switched to terror at the end of the round
	for(new i=1;i<=MaxClients;i++)
	{
		if(g_bCTToSwitch[i])
		{
			iCTCount--;
			iTCount++;
			iToBeSwitched++;
		}
	}
	//PrintToServer("Debug: %d players are flagged to switch at the end of the round.", iToBeSwitched);
	new Float:fRatio = FloatDiv(float(iCTCount), float(iTCount));
	
	new Float:fCFGCTRatio = GetConVarFloat(hns_cfg_ct_ratio);
	
	new Float:fCFGRatio = FloatDiv(1.0, fCFGCTRatio);
	
	//PrintToServer("Debug: Initial CTCount: %d TCount: %d Ratio: %f, CFGRatio: %f", iCTCount, iTCount, fRatio, fCFGRatio);
	
	decl String:sName[64];
	// There are more CTs than we want in the CT team and it's not the first CT
	if(iCTCount != 1 && fRatio > fCFGRatio)
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
						return Plugin_Handled;
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
				return Plugin_Handled;
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
				return Plugin_Handled;
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
				return Plugin_Handled;
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
				return Plugin_Handled;
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
	return Plugin_Handled;
}

/*
* 
* Console Command Handling
* 
*/

// say /hide /hidemenu
public Action:Menu_SelectModel(client,args)
{
	if (!g_EnableHnS || g_ModelMenu[GetClientLanguageID(client)] == INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		new changeLimit = GetConVarInt(hns_cfg_changelimit);
		if(g_AllowModelChange[client] && (changeLimit == 0 || g_ModelChangeCount[client] < (changeLimit+1)))
		{
			if(GetConVarBool(hns_cfg_autochoose))
				SetRandomModel(client);
			else
				DisplayMenu(g_ModelMenu[GetClientLanguageID(client)], client, RoundToFloor(GetConVarFloat(hns_cfg_changelimittime)));
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
	if (!g_EnableHnS || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// Only allow Terrorists to use thirdperson view
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	if(!g_InThirdPersonView[client])
	{
		SetThirdPersonView(client, true);
		PrintToChat(client, "%s%t", PREFIX, "Type again for ego");
	}
	else
	{
		SetThirdPersonView(client, false);
		// remove the roundtime message
		new Handle:hBuffer = StartMessageOne("KeyHintText", client);
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, "");
		EndMessage();
	}
	
	return Plugin_Handled;
}

// say /+3rd
public Action:Enable_ThirdPerson(client, args)
{
	if (!g_EnableHnS || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// Only allow Terrorists to use thirdperson view
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	if(!g_InThirdPersonView[client])
	{
		SetThirdPersonView(client, true);
		PrintToChat(client, "%s%t", PREFIX, "Type again for ego");
	}
	
	return Plugin_Handled;
}

// say /-3rd
public Action:Disable_ThirdPerson(client, args)
{
	if (!g_EnableHnS || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// Only allow Terrorists to use thirdperson view
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	if(g_InThirdPersonView[client])
	{
		SetThirdPersonView(client, false);
		// remove the roundtime message
		new Handle:hBuffer = StartMessageOne("KeyHintText", client);
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, "");
		EndMessage();
	}
	
	return Plugin_Handled;
}

// jointeam command
// handle the team sizes
public Action:Command_JoinTeam(client, args)
{
	if (!g_EnableHnS || !client || !IsClientInGame(client) || GetConVarFloat(hns_cfg_ct_ratio) == 0.0)
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
		
		new Float:fCFGRatio = FloatDiv(1.0, GetConVarFloat(hns_cfg_ct_ratio));
		
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
	if(!g_EnableHnS || !GetConVarBool(hns_cfg_whistle) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	// only Ts are allowed to whistle
	if(GetClientTeam(client) != CS_TEAM_T)
	{
		PrintToChat(client, "%s%t", PREFIX, "Only terrorists can use");
		return Plugin_Handled;
	}
	
	if(!g_WhistlingAllowed)
	{
		PrintToChat(client, "%s%t", PREFIX, "Whistling not allowed yet");
		return Plugin_Handled;
	}
	
	new cvarWhistleTimes = GetConVarInt(hns_cfg_whistle_times);
	
	if(g_WhistleCount[client] < cvarWhistleTimes)
	{
		EmitSoundToAll(whistle_sounds[GetRandomInt(0, sizeof(whistle_sounds)-1)], client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		PrintToChatAll("%s%N %t", PREFIX, client, "whistled");
		g_WhistleCount[client]++;
		PrintToChat(client, "%s%t", PREFIX, "whistles left", (cvarWhistleTimes-g_WhistleCount[client]));
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
	if(!g_EnableHnS || !IsPlayerAlive(client) || g_ModelChangeCount[client] == 0)
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
	if(!g_EnableHnS)
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
	if(!g_EnableHnS || !GetConVarInt(hns_cfg_hider_freeze_mode) || GetClientTeam(client) != CS_TEAM_T || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	if(g_IsFreezed[client])
	{
		if(GetConVarInt(hns_cfg_hider_freeze_mode) == 1)
			SetEntityMoveType(client, MOVETYPE_WALK);
		else
		{
			SetEntData(client, g_Freeze, FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND, 4, true);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		
		g_IsFreezed[client] = false;
		PrintToChat(client, "%s%t", PREFIX, "Hider Unfreezed");
	}
	else if (GetConVarBool(hns_cfg_hider_freeze_inair) || GetEntityFlags(client) & FL_ONGROUND) // only allow freezing when being on the ground!
	{
		if(GetConVarInt(hns_cfg_hider_freeze_mode) == 1)
			SetEntityMoveType(client, MOVETYPE_NONE); // Still able to move camera
		else
		{
			SetEntData(client, g_Freeze, FL_CLIENT|FL_ATCONTROLS, 4, true); // Can't move anything
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
		
		g_IsFreezed[client] = true;
		PrintToChat(client, "%s%t", PREFIX, "Hider Freezed");
	}
	
	return Plugin_Handled;
}

public Action:Block_Cmd(client,args)
{
	// only block if anticheat is enabled
	if(g_EnableHnS && GetConVarBool(hns_cfg_anticheat))
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

// Admin Command
// sm_hns_force_whistle
// Forces a terrorist player to whistle
public Action:ForceWhistle(client, args)
{
	if(!g_EnableHnS || !GetConVarBool(hns_cfg_whistle))
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
	if(!g_EnableHnS)
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
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T && g_AllowModelChange[client])
	{
		if (action == MenuAction_Select)
		{
			decl String:info[100], String:info2[100], String:sModelPath[100];
			new bool:found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
			if(found)
			{
				// Modelheight fix
				new iPosition;
				if((iPosition = StrContains(info, "||")) != -1)
				{
					g_FixedModelHeight[client] = StringToFloat(info[iPosition+2]);
					PrintToChat(client, "This model is bugged and uses a fixed height set. (%f)", g_FixedModelHeight[client]);
				}
				else
				{
					g_FixedModelHeight[client]= 0.0;
				}
				
				if(SplitString(info, "||", sModelPath, sizeof(sModelPath)) == -1)
					strcopy(sModelPath, sizeof(sModelPath), info);
				
				SetEntityModel(client, sModelPath);
				PrintToChat(client, "%s%t \x01%s.", PREFIX, "Model Changed", info2);
				g_ModelChangeCount[client]++;
			}
		} else if(action == MenuAction_Cancel)
		{
			PrintToChat(client, "%s%t", PREFIX, "Type !hide");
		}
		
		// display the help menu afterwards on first spawn
		if(GetConVarBool(hns_cfg_show_hidehelp) && g_FirstSpawn[client])
		{
			Display_Help(client, 0);
			g_FirstSpawn[client] = false;
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
				if(GetConVarBool(hns_cfg_whistle))
				{
					Format(buffer, sizeof(buffer), "/whistle - %T", "cmd whistle", param1);
					AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				}
				if(GetConVarInt(hns_cfg_hider_freeze_mode))
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
				
				Format(buffer, sizeof(buffer), "%T", "Instructions CT 2", param1, GetConVarInt(hns_cfg_hp_seeker_dec));
				AddMenuItem(menu2, "", buffer, ITEMDRAW_DISABLED);
				
				Format(buffer, sizeof(buffer), "%T", "Instructions CT 3", param1, GetConVarInt(hns_cfg_hp_seeker_inc), GetConVarInt(hns_cfg_hp_seeker_bonus));
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
	g_TotalModelsAvailable = 0;
		
	kv = CreateKeyValues("Models");
	new String:file[256], String:map[64], String:title[64], String:finalOutput[100];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, file, 255, "configs/hide_and_seek/maps/%s.cfg", map);
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
			Format(finalOutput, sizeof(finalOutput), "%s||%s", finalOutput, sHeightFix);
		}
		
		// roll through all available languages
		for(new i=0;i<GetLanguageCount();i++)
		{
			GetLanguageInfo(i, lang, sizeof(lang));
			// search for the translation
			KvGetString(kv, lang, name, sizeof(name));
			if(strlen(name) > 0)
			{
				// language already in array, only in the wrong order in the file?
				langID = GetLanguageID(lang);
				
				// language new?
				if(langID == -1)
				{
					nextLangID = GetNextLangID();
					g_ModelMenuLanguage[nextLangID] = lang;
				}
				
				if(langID == -1 && g_ModelMenu[nextLangID] == INVALID_HANDLE)
				{
					// new language, create the menu
					g_ModelMenu[nextLangID] = CreateMenu(Menu_Group);
					FormatEx(title, sizeof(title), "%T:", "Title Select Model", LANG_SERVER);
					
					SetMenuTitle(g_ModelMenu[nextLangID], title);
					SetMenuExitButton(g_ModelMenu[nextLangID], true);
				}
				
				// add it to the menu
				if(langID == -1)
					AddMenuItem(g_ModelMenu[nextLangID], finalOutput, name);
				else
					AddMenuItem(g_ModelMenu[langID], finalOutput, name);
			}
			
		}
		
		g_TotalModelsAvailable++;
	} while (KvGotoNextKey(kv));
	KvRewind(kv);
	
	if (g_TotalModelsAvailable == 0)
	{
		SetFailState("No models parsed in %s.cfg", map);
		return;
	}
}

GetLanguageID(const String:langCode[])
{
	for(new i=0;i<MAX_LANGUAGES;i++)
	{
		if(StrEqual(g_ModelMenuLanguage[i], langCode))
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
				if(StrEqual(g_ModelMenuLanguage[i], "en"))
				{
					strcopy(languageCode, maxlen, "en");
					return i;
				}
			}
			
			// english not found? happens on custom map configs e.g.
			// use the first language available
			// this should always work, since we would have SetFailState() on parse
			if(strlen(g_ModelMenuLanguage[0]) > 0)
			{
				strcopy(languageCode, maxlen, g_ModelMenuLanguage[0]);
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
		if(strlen(g_ModelMenuLanguage[i]) == 0)
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
		if(g_ConVarViolation[client][i])
		{
			return true;
		}
	}
	return false;
}

// Fade a players screen to black (amount=0) or removes the fade (amount=255)
PerformBlind(client, amount)
{	
	new Handle:message = StartMessageOne("Fade", client);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0)
	{
		BfWriteShort(message, 0x0010);
	}
	else
	{
		BfWriteShort(message, 0x0008);
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	EndMessage();
}

// set a random model to a client
SetRandomModel(client)
{
	// give him a random one.
	decl String:ModelPath[80], String:finalPath[100], String:ModelName[60], String:langCode[4], String:sHeightFix[35];
	new RandomNumber = GetRandomInt(0, g_TotalModelsAvailable-1);	
	new currentI = 0;
	KvGotoFirstSubKey(kv);
	do
	{
		if(currentI == RandomNumber)
		{
			// set the model
			KvGetSectionName(kv, ModelPath, sizeof(ModelPath));
			
			FormatEx(finalPath, sizeof(finalPath), "models/%s.mdl", ModelPath);
			
			SetEntityModel(client, finalPath);
			
			// Check for heightfixed models
			KvGetString(kv, "heightfix", sHeightFix, sizeof(sHeightFix), "noo");
			if(!StrEqual(sHeightFix, "noo"))
			{
				g_FixedModelHeight[client] = StringToFloat(sHeightFix);
			}
			else
			{
				g_FixedModelHeight[client] = 0.0;
			}
			
			if(!IsFakeClient(client))
			{
				// print name in chat
				GetClientLanguageID(client, langCode, sizeof(langCode));
				KvGetString(kv, langCode, ModelName, sizeof(ModelName));
				PrintToChat(client, "%s%t \x01%s.", PREFIX, "Model Changed", ModelName);
			}
		}
		currentI++;
	} while (KvGotoNextKey(kv));
	
	KvRewind(kv);	
	g_ModelChangeCount[client]++;
	
	// display the help menu afterwards on first spawn
	if(GetConVarBool(hns_cfg_show_hidehelp) && g_FirstSpawn[client])
	{
		Display_Help(client, 0);
		g_FirstSpawn[client] = false;
	}
}

bool:SetThirdPersonView(client, third)
{
	if(third && !g_InThirdPersonView[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		g_InThirdPersonView[client] = true;
		return true;
	}
	else if(!third && g_InThirdPersonView[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		g_InThirdPersonView[client] = false;
		return true;
	}
	return false;
}

/*
* 
* Handle ConVars
* 
*/
// Monitor the protected cvars and... well protect them ;)
public OnCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!g_EnableHnS)
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
	if(!g_EnableHnS)
		return;
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			SetEntDataFloat(i, g_flLaggedMovementValue, GetConVarFloat(hns_cfg_hidersspeed), true);
	}
}

// directly change the hider speed on change
public OnChangeAntiCheat(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!g_EnableHnS)
		return;
	
	if(StrEqual(oldValue, newValue))
		return;
	
	// disable anticheat
	if(StrEqual(newValue, "0"))
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_CheckVarTimer[i] != INVALID_HANDLE)
			{
				KillTimer(g_CheckVarTimer[i]);
				g_CheckVarTimer[i] = INVALID_HANDLE;
			}
		}
	}
	// enable anticheat
	else if(StrEqual(newValue, "1"))
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_CheckVarTimer[i] == INVALID_HANDLE)
			{
				g_CheckVarTimer[i] = CreateTimer(1.0, StartVarChecker, i, TIMER_REPEAT);
			}
		}
	}
}

// disable/enable plugin and restart round
public RestartGame(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!g_EnableHnS)
		return;
	
	// don't execute if it's unchanged
	if(StrEqual(oldValue, newValue))
		return;
	
	// disable - it's been enabled before.
	if(!StrEqual(newValue, "0"))
	{
		// round has ended. used to not decrease seekers hp on shoot
		g_RoundEnded = true;
		
		g_FirstCTSpawn = 0;
		
		if(g_ShowCountdownTimer != INVALID_HANDLE)
		{
			KillTimer(g_ShowCountdownTimer);
			g_ShowCountdownTimer = INVALID_HANDLE;
		}
		
		if(g_RoundTimeTimer != INVALID_HANDLE)
		{
			KillTimer(g_RoundTimeTimer);
			g_RoundTimeTimer = INVALID_HANDLE;
		}
		
		if(g_WhistleDelay != INVALID_HANDLE)
		{
			KillTimer(g_WhistleDelay);
			g_WhistleDelay = INVALID_HANDLE;
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
		UnhookConVarChange(hns_cfg_anticheat, OnChangeAntiCheat);
		UnhookConVarChange(hns_cfg_hidersspeed, OnChangeHiderSpeed);
		
		// Unhooking events
		UnhookEvent("player_spawn", Event_OnPlayerSpawn);
		UnhookEvent("weapon_fire", Event_OnWeaponFire);
		UnhookEvent("player_death", Event_OnPlayerDeath);
		UnhookEvent("round_start", Event_OnRoundStart);
		UnhookEvent("round_end", Event_OnRoundEnd);
		UnhookEvent("player_team", Event_OnPlayerTeam);
		UnhookEvent("item_pickup", Event_OnItemPickup);
		
		// unprotect the cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			// reset old cvar values
			UnhookConVarChange(g_ProtectedConvar[i], OnCvarChange);
			SetConVarInt(g_ProtectedConvar[i], previous_values[i], true);
		}
		
		// stop advertising spam
		if(g_SpamCommandsTimer != INVALID_HANDLE)
		{
			KillTimer(g_SpamCommandsTimer);
			g_SpamCommandsTimer = INVALID_HANDLE;
		}
		
		// stop countdown
		if(g_ShowCountdownTimer != INVALID_HANDLE)
		{
			KillTimer(g_ShowCountdownTimer);
			g_ShowCountdownTimer = INVALID_HANDLE;
		}
		
		// stop roundtime counter
		if(g_RoundTimeTimer != INVALID_HANDLE)
		{
			KillTimer(g_RoundTimeTimer);
			g_RoundTimeTimer = INVALID_HANDLE;
		}
		
		// close handles
		if(kv != INVALID_HANDLE)
			CloseHandle(kv);
		for(new i=0;i<MAX_LANGUAGES;i++)
		{
			if(g_ModelMenu[i] != INVALID_HANDLE)
			{
				CloseHandle(g_ModelMenu[i]);
				g_ModelMenu[i] = INVALID_HANDLE;
			}
			Format(g_ModelMenuLanguage[i], 4, "");
		}
		
		for(new c=1;c<=MaxClients;c++)
		{
			if(!IsClientInGame(c))
				continue;
			
			// stop cheat checking
			if(!IsFakeClient(c) && g_CheckVarTimer[c] != INVALID_HANDLE)
			{
				KillTimer(g_CheckVarTimer[c]);
				g_CheckVarTimer[c] = INVALID_HANDLE;
			}
			
			// Unhook weapon pickup
			SDKUnhook(c, SDKHook_WeaponCanUse, OnWeaponCanUse);
			
			// Hide Radar
			SDKUnhook(c, SDKHook_PreThink, OnPlayerThink);
			SDKUnhook(c, SDKHook_PreThinkPost, OnPlayerThink);
			SDKUnhook(c, SDKHook_Think, OnPlayerThink);
			SDKUnhook(c, SDKHook_PostThink, OnPlayerThink);
			SDKUnhook(c, SDKHook_PostThinkPost, OnPlayerThink);
			
			// Unhook attacking
			SDKUnhook(c, SDKHook_TraceAttack, OnTraceAttack);
			
			// reset every players vars
			OnClientDisconnect(c);
		}
		
		g_EnableHnS = false;
		// restart game to reset the models and scores
		ServerCommand("mp_restartgame 1");
	}
	else if(StrEqual(newValue, "1"))
	{
		// hook the convars again
		HookConVarChange(hns_cfg_hidersspeed, OnChangeHiderSpeed);
		HookConVarChange(hns_cfg_anticheat, OnChangeAntiCheat);
		
		// Hook events again
		HookEvent("player_spawn", Event_OnPlayerSpawn);
		HookEvent("weapon_fire", Event_OnWeaponFire);
		HookEvent("player_death", Event_OnPlayerDeath);
		HookEvent("round_start", Event_OnRoundStart);
		HookEvent("round_end", Event_OnRoundEnd);
		HookEvent("player_team", Event_OnPlayerTeam);
		HookEvent("item_pickup", Event_OnItemPickup);
		
		// set bad server cvars
		for(new i=0;i<sizeof(protected_cvars);i++)
		{
			g_ProtectedConvar[i] = FindConVar(protected_cvars[i]);
			previous_values[i] = GetConVarInt(g_ProtectedConvar[i]);
			SetConVarInt(g_ProtectedConvar[i], forced_values[i], true);
			HookConVarChange(g_ProtectedConvar[i], OnCvarChange);
		}
		// start advertising spam
		g_SpamCommandsTimer = CreateTimer(120.0, SpamCommands, 0);
		
		for(new c=1;c<=MaxClients;c++)
		{
			if(!IsClientInGame(c))
				continue;
			
			// start cheat checking
			if(!IsFakeClient(c) && GetConVarBool(hns_cfg_anticheat) && g_CheckVarTimer[c] == INVALID_HANDLE)
			{
				g_CheckVarTimer[c] = CreateTimer(1.0, StartVarChecker, c, TIMER_REPEAT);
			}
			
			// Hook weapon pickup
			SDKHook(c, SDKHook_WeaponCanUse, OnWeaponCanUse);
			
			// Hide Radar
			SDKHook(c, SDKHook_PreThink, OnPlayerThink);
			SDKHook(c, SDKHook_PreThinkPost, OnPlayerThink);
			SDKHook(c, SDKHook_Think, OnPlayerThink);
			SDKHook(c, SDKHook_PostThink, OnPlayerThink);
			SDKHook(c, SDKHook_PostThinkPost, OnPlayerThink);
			
			// Hook attack to hide blood
			SDKHook(c, SDKHook_TraceAttack, OnTraceAttack);
		}
		
		g_EnableHnS = true;
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
			g_ConVarViolation[client][i] = true;
			// only spam the message every 5 checks
			if(g_ConVarMessage[client][i] == 0)
			{
				PrintToChat(client, "%s%t\x04 %s 0", PREFIX, "Print to console", cvarName);
				PrintHintText(client, "%t %s 0", "Print to console", cvarName);
			}
			g_ConVarMessage[client][i]++;
			if(g_ConVarMessage[client][i] > 5)
				g_ConVarMessage[client][i] = 0;
		}
		else
			g_ConVarViolation[client][i] = false;
	}
}