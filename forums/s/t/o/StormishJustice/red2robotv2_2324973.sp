#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>
#include <tf2>
#include <tf2attributes>

#pragma newdecls required;

#define PLUGIN_VERSION "2.1.2"

#define GIANTSCOUT_SND_LOOP			"MVM.GiantScoutLoop"
#define GIANTSOLDIER_SND_LOOP		"MVM.GiantSoldierLoop"
#define GIANTPYRO_SND_LOOP			"MVM.GiantPyroLoop"
#define GIANTDEMOMAN_SND_LOOP		"MVM.GiantDemomanLoop"
#define GIANTHEAVY_SND_LOOP			"MVM.GiantHeavyLoop"
#define SENTRYBUSTER_SND_LOOP		"MVM.SentryBusterLoop"
#define SENTRYBUSTER_SND_INTRO		"MVM.SentryBusterIntro"
#define SENTRYBUSTER_SND_ALERT		"Announcer.MVM_Sentry_Buster_Alert"
#define SENTRYBUSTER_SND_SPIN		"MVM.SentryBusterSpin"

#define TFTeam_Blue 3
#define TFTeam_Spectator 1
#define TFTeam_Red 2

enum
{
	BotSkill_Easy,
	BotSkill_Normal,
	BotSkill_Hard,
	BotSkill_Expert
};

enum RobotMode
{
	Robot_Stock,
	Robot_Normal,
	Robot_BigNormal,
	Robot_Giant,
	Robot_SentryBuster,
	Robot_Human,
	Robot_None
};

char weaponAttribs[256];
Handle hSDKEquipWearable = INVALID_HANDLE;
bool bInRespawn[MAXPLAYERS];
bool bFreezed[MAXPLAYERS];
bool IsMannhattan;
bool Is666Mode;
bool bSpawnFreeze;
bool bBetweenUber;
RobotMode iRobotMode[MAXPLAYERS];
bool bRestrictReady;
bool bFlagPickup;
bool bSentryBusterDebug;
int iFilterEnt[2];
Handle hTimer_SentryBuster_Beep[MAXPLAYERS+1];
int iLaserModel = -1;
//bool bNeedToRespawn;
bool bRespawnForm;
bool bWearables;
bool bAction;
bool AboutToExplode[MAXPLAYERS + 1];
//bool g_bIsSentryBuster[MAXPLAYERS + 1];
//bool g_bIsGiantRobot[MAXPLAYERS + 1];
//bool g_bWantsToBeGiant[MAXPLAYERS + 1];
//bool g_bIsBigRobot[MAXPLAYERS + 1];
//bool g_bIsRobot[MAXPLAYERS + 1];
//bool g_bWantsToBeRobot[MAXPLAYERS + 1];
bool g_bHasCrits[MAXPLAYERS + 1];
Handle cvarBossScale;
Handle sm_red2robot_freeze;
Handle sm_red2robot_between_uber;
Handle sm_red2robot_restrict_ready;
Handle sm_red2robot_flag;
Handle sm_red2robot_sentrybuster_debug
//Handle sm_red2robot_need_respawn;
Handle sm_red2robot_respawn_form;
Handle sm_red2robot_wearables;
Handle sm_red2robot_action;

public Plugin myinfo = 
{
	name = "[TF2] Red2Robot v2",
	author = "StormishJustice",
	description = "Allows you to go to the ROBOTS team on MvM.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2324973"
}

public void OnPluginStart()
{
	CheckGame();
	
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("post_inventory_application", event_PostInventoryApplication);
	
	AddNormalSoundHook(SoundHook);
	
	RegAdminCmd("sm_bot", Command_Help, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_machine", Command_Robot_Me, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_joinblu", Command_Robot_Me, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_mann", Command_Human_Me, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_joinred", Command_Human_Me, ADMFLAG_RESERVATION);
	RegConsoleCmd("sm_gauntlet", Command_SteelGauntlet);
	RegConsoleCmd("sm_shortstop", Command_Shortstop);
	RegConsoleCmd("sm_gauntletpusher", Command_GauntletPusher);
	RegConsoleCmd("sm_deflector", Command_GiantDeflectorHeavy);
	RegConsoleCmd("sm_bowmanrapidfire", Command_BowSpammer);
	RegConsoleCmd("sm_giantchargedsoldier", Command_GiantChargedSoldier);
	RegConsoleCmd("sm_giantrapidsoldier", Command_GiantRapidFireSoldier);
	RegConsoleCmd("sm_giant", Command_Giant);
	RegConsoleCmd("sm_busterrobot", Command_SentryBuster);
	RegConsoleCmd("sm_small", Command_Small);
	
	AddCommandListener(Command_Ready, "tournament_player_readystate");
	AddCommandListener(Listener_taunt, "taunt");
	AddCommandListener(Command_Suicide, "kill");
	AddCommandListener(Command_Suicide, "explode");
	AddCommandListener(Listener_taunt, "+taunt");
	
	CreateConVar("sm_red2robot_version", PLUGIN_VERSION, "Red2Robot Version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	sm_red2robot_freeze = CreateConVar( "sm_red2robot_freeze", "1", "Disable movement for robohumans between rounds.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_red2robot_freeze, OnConVarChanged );
	
	sm_red2robot_between_uber = CreateConVar( "sm_red2robot_between_uber", "1", "Enable uber for robohumans between rounds.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_red2robot_between_uber, OnConVarChanged );
	
	sm_red2robot_restrict_ready = CreateConVar( "sm_red2robot_restrict_ready", "1", "Block BLU team Ready status command.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_red2robot_restrict_ready, OnConVarChanged );
	
	sm_red2robot_flag = CreateConVar( "sm_red2robot_flag", "1", "Allow flag pick up by humans. (not recommend)", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_red2robot_flag, OnConVarChanged );
	
//	sm_red2robot_need_respawn = CreateConVar( "sm_red2robot_need_respawn", "1", "Enable if players wants to be robot and needs to respawn.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ); // Unused due to broken stuff
//	HookConVarChange( sm_red2robot_need_respawn, OnConVarChanged );
	
	sm_red2robot_sentrybuster_debug = CreateConVar( "sm_red2robot_sentrybuster_debug", "0", "Enable debug mode for sentry buster.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_red2robot_sentrybuster_debug, OnConVarChanged );
	
	sm_red2robot_respawn_form = CreateConVar( "sm_red2robot_respawn_form", "1", "Enable players to automatically respawn after using robot command.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_red2robot_respawn_form, OnConVarChanged );
	
	sm_red2robot_wearables = CreateConVar( "sm_red2robot_wearables", "1", "Allow wearables as a robot.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_red2robot_wearables, OnConVarChanged );
	
	sm_red2robot_action = CreateConVar( "sm_red2robot_action", "1", "Allow action items as a robot.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_red2robot_action, OnConVarChanged );
	
	HookEntityOutput("team_control_point", "OnCapTeam2", OnGateCapture);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	for (int i = MaxClients + 1; i <= 2048; i++)
	{
		if (!IsValidEntity(i)) continue;
		char cls[10];
		GetEntityClassname(i, cls, sizeof(cls));
		if (StrContains(cls, "obj_sen", false) == 0) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnMapStart()
{
	if (IsMvM())
	{
		PrintToServer("[Red2Robot] MvM Detected. Red2Robot activated and ready for use!");
		int iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "func_respawnroom") ) != -1 )
			if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == TFTeam_Blue )
			{
				SDKHook( iEnt, SDKHook_Touch, OnSpawnStartTouch );
				SDKHook( iEnt, SDKHook_EndTouch, OnSpawnEndTouch );
			}
		iLaserModel = PrecacheModel("materials/sprites/laserbeam.vmt");
		for (int i = 1; i <= 7; i++)
		{
			char snd[PLATFORM_MAX_PATH];
			Format(snd, sizeof(snd), "vo/mvm_sentry_buster_alerts0%i.mp3", i);
			PrecacheSound(snd, true);
		}
	}
	else
	{
		SetFailState("[Red2Robot] Error #1: This plugin is only usable on MvM maps.");
		return;
	}
	
	IsMannhattan = false;
	Is666Mode = false;
	char map[32];
	GetCurrentMap(map,sizeof(map));
	if (StrEqual(map, "mvm_mannhattan"))
	{
		IsMannhattan = true;
	}
	if (StrEqual(map, "mvm_ghost_town"))
	{
		Is666Mode = true;
	}
}

void CheckGame()
{
	char strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (StrEqual(strModName, "tf")) return;
	SetFailState("[SM] This plugin is only for Team Fortress 2.");
}

public Action Command_Robot_Me(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (args == 0)
	{
		if (GetClientTeam(client) == 2)
		{
			int entflags = GetEntityFlags(client);
			SetEntityFlags(client, entflags | FL_FAKECLIENT);
			ChangeClientTeam(client, TFTeam_Blue);
			SetEntityFlags(client, entflags);
			ReplyToCommand(client, "[Red2Robot] You are now in the ROBOTS team!");
			ShowActivity2(client, "[Red2Robot] ", "%N changed his team to the ROBOTS team!", client);
		}
		else
		{
			ReplyToCommand(client, "[Red2Robot] You are already in the ROBOTS team.");
		}
	}
	else if (args == 1)
	{
		char arg1[128];
		GetCmdArg(1, arg1, 128);
		//Create strings
		char buffer[64];
		char target_name[MAX_NAME_LENGTH];
		int target_list[MAXPLAYERS];
		int target_count;
		bool tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
		if ((target_count = ProcessTargetString(
				buffer,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i ++)
		{
			if (GetClientTeam(target_list[i]) ==2)
			{
				int entflags = GetEntityFlags(target_list[i]);
				SetEntityFlags(target_list[i], entflags | FL_FAKECLIENT);
				ChangeClientTeam(target_list[i], TFTeam_Blue);
				SetEntityFlags(target_list[i], entflags &~ FL_FAKECLIENT);
				ReplyToCommand(target_list[i], "[Red2Robot] You are now in the ROBOTS team!");
				ShowActivity2(target_list[i], "[Red2Robot] ", "%N changed his team to the ROBOTS team!", target_list[i]);
			}
			else
			{
				ReplyToCommand(target_list[i], "[Red2Robot] You are already in the ROBOTS team.");
			}
		}	
	}

	return Plugin_Handled;
}


public Action Command_Human_Me(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (args == 0)
	{
		if (GetClientTeam(client) ==3)
		{
			ChangeClientTeam(client, TFTeam_Red);
			ReplyToCommand(client, "[Red2Robot] You are now in the DEFENDERS team!");
			ShowActivity2(client, "[Red2Robot] ", "%N changed his team to the DEFENDERS team!", client);
		}
		else
		{
			ReplyToCommand(client, "[Red2Robot] You are already in the DEFENDERS team.");
		}
	}
	else if (args == 1)
	{
		char arg1[128];
		GetCmdArg(1, arg1, 128);
		//Create strings
		char buffer[64];
		char target_name[MAX_NAME_LENGTH];
		int target_list[MAXPLAYERS];
		int target_count;
		bool tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
		if ((target_count = ProcessTargetString(
				buffer,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i ++)
		{
			if (GetClientTeam(target_list[i]) ==3)
			{
				int entflags = GetEntityFlags(target_list[i]);
				SetEntityFlags(target_list[i], entflags | FL_FAKECLIENT);
				ChangeClientTeam(target_list[i], TFTeam_Red);
				SetEntityFlags(target_list[i], entflags);
				ReplyToCommand(target_list[i], "[Red2Robot] You are now in the DEFENDERS team!");
				ShowActivity2(target_list[i], "[Red2Robot] ", "%N changed his team to the DEFENDERS team!", target_list[i]);
			}
			else
			{
				ReplyToCommand(target_list[i], "[Red2Robot] You are already in the DEFENDERS team.");
			}
		}
	}

	return Plugin_Handled;
}

public Action Command_Shortstop(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && bInRespawn[client])
	{
		iRobotMode[client] = Robot_BigNormal;
		TF2_SetPlayerClass(client, TFClass_Scout);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.4);
		UpdatePlayerHitbox(client, 1.4);
		TF2_RegeneratePlayer(client);
		SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Easy);
		RemoveAttribs(client);
		if (iRobotMode[client] == Robot_SentryBuster)
				TF2_RemoveCondition(client, TFCond_PreventDeath);
		if(g_bHasCrits[client])
		{
			g_bHasCrits[client] = false;
		}
		int minigun = GetPlayerWeaponSlot(client, 0);
		if(TF2_GetPlayerClass(client) == TFClass_Heavy && iRobotMode[client] == Robot_Giant)
			TF2Attrib_RemoveByName(minigun, "damage bonus");
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		TF2Attrib_SetByName(client, "head scale", 0.7);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 525.0);
		TF2Attrib_SetByName(client, "move speed bonus", 1.25);
		Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
		SpawnWeapon( client, "tf_weapon_handgun_scout_primary", 220, 100, 5, weaponAttribs, false );
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
		SetEntProp(client, Prop_Data, "m_iHealth", 650);
		StopSounds(client);
		AboutToExplode[client] = false;
	
		SetModel(client);
		
		ReplyToCommand(client, "[Red2Robot] You are now a Shortstop Scout!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now a Shortstop Scout!", client);
	}
	else if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Normal)
	{
		ReplyToCommand(client, "[Red2Robot] You need to be a small robot in order to become a Shortstop Scout.");
	}
	else if (iRobotMode[client] == Robot_BigNormal)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Shortstop Scout again because you already are.")
	}
	else if (GetClientTeam(client) == 3 && !bInRespawn[client])
	{
		ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Shortstop Scout.");
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be a Shortstop Scout.");
	}
	return Plugin_Continue;
}

public Action Command_BowSpammer(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && bInRespawn[client])
	{
		iRobotMode[client] = Robot_BigNormal;
		TF2_SetPlayerClass(client, TFClass_Sniper);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
		UpdatePlayerHitbox(client, 1.5);
		TF2_RegeneratePlayer(client);
		SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Hard);
		RemoveAttribs(client);
		if (iRobotMode[client] == Robot_SentryBuster)
				TF2_RemoveCondition(client, TFCond_PreventDeath);
		if(g_bHasCrits[client])
		{
			g_bHasCrits[client] = false;
		}
		int minigun = GetPlayerWeaponSlot(client, 0);
		if(TF2_GetPlayerClass(client) == TFClass_Heavy && iRobotMode[client] == Robot_Giant)
			TF2Attrib_RemoveByName(minigun, "damage bonus");
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		TF2Attrib_SetByName(client, "head scale", 0.7);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1075.0);
		TF2Attrib_SetByName(client, "move speed bonus", 0.85);
		Format(weaponAttribs, sizeof(weaponAttribs), "6 ; 0.6");
		SpawnWeapon( client, "tf_weapon_compound_bow", 56, 100, 5, weaponAttribs, false );
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
		SetEntProp(client, Prop_Data, "m_iHealth", 1200);
		StopSounds(client);
		AboutToExplode[client] = false;
	
		SetModel(client);
		
		ReplyToCommand(client, "[Red2Robot] You are now a Bowman Rapid Fire!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now a Bowman Rapid Fire!", client);
	}
	else if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Normal)
	{
		ReplyToCommand(client, "[Red2Robot] You need to be a small robot in order to become a Bowman Rapid Fire.");
	}
	else if (iRobotMode[client] == Robot_BigNormal)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Bowman Rapid Fire again because you already are.")
	}
	else if (GetClientTeam(client) == 3 && !bInRespawn[client])
	{
		ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Bowman Rapid Fire.");
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be a Bowman Rapid Fire.");
	}
	return Plugin_Continue;
}

public Action Command_SteelGauntlet(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && bInRespawn[client])
	{
		iRobotMode[client] = Robot_BigNormal;
		TF2_SetPlayerClass(client, TFClass_Heavy);
		TF2_RegeneratePlayer(client);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
		UpdatePlayerHitbox(client, 1.5);
		SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Hard);
		RemoveAttribs(client);
		if (iRobotMode[client] == Robot_SentryBuster)
				TF2_RemoveCondition(client, TFCond_PreventDeath);
		if(g_bHasCrits[client])
		{
			g_bHasCrits[client] = false;
		}
		int minigun = GetPlayerWeaponSlot(client, 0);
		if(TF2_GetPlayerClass(client) == TFClass_Heavy && iRobotMode[client] == Robot_Giant)
			TF2Attrib_RemoveByName(minigun, "damage bonus");
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 600.0);
		Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
		SpawnWeapon( client, "tf_weapon_fists", 331, 100, 5, weaponAttribs, false );
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
		SetEntProp(client, Prop_Data, "m_iHealth", 900);
		StopSounds(client);
		AboutToExplode[client] = false;
	
		SetModel(client);
		
		ReplyToCommand(client, "[Red2Robot] You are now a Steel Gauntlet!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now a Steel Gauntlet!", client);
	}
	else if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Normal)
	{
		ReplyToCommand(client, "[Red2Robot] You need to be a small robot in order to become a Steel Gauntlet.");
	}
	else if (iRobotMode[client] == Robot_BigNormal)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Steel Gauntlet again because you already are.")
	}
	else if (GetClientTeam(client) == 3 && !bInRespawn[client])
	{
		ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Steel Gauntlet.");
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be a Steel Gauntlet.");
	}
	return Plugin_Continue;
}

public Action Command_GauntletPusher(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && bInRespawn[client])
	{
		iRobotMode[client] = Robot_BigNormal;
		TF2_SetPlayerClass(client, TFClass_Heavy);
		TF2_RegeneratePlayer(client);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
		UpdatePlayerHitbox(client, 1.5);
		SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Expert);
		RemoveAttribs(client);
		if (iRobotMode[client] == Robot_SentryBuster)
				TF2_RemoveCondition(client, TFCond_PreventDeath);
		if(g_bHasCrits[client])
		{
			g_bHasCrits[client] = false;
		}
		int minigun = GetPlayerWeaponSlot(client, 0);
		if(TF2_GetPlayerClass(client) == TFClass_Heavy && iRobotMode[client] == Robot_Giant)
			TF2Attrib_RemoveByName(minigun, "damage bonus");
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 600.0);
		Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.5 ; 522 ; 1");
		SpawnWeapon( client, "tf_weapon_fists", 331, 100, 5, weaponAttribs, false );
		SetEntProp(client, Prop_Data, "m_iHealth", 900);
		StopSounds(client);
		AboutToExplode[client] = false;
	
		SetModel(client);
		
		ReplyToCommand(client, "[Red2Robot] You are now a Steel Gauntlet Pusher!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now a Steel Gauntlet Pusher!", client);
	}
	else if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Normal)
	{
		ReplyToCommand(client, "[Red2Robot] You need to be a small robot in order to become a Steel Gauntlet Pusher.");
	}
	else if (iRobotMode[client] == Robot_BigNormal)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Steel Gauntlet Pusher again because you already are.")
	}
	else if (GetClientTeam(client) == 3 && !bInRespawn[client])
	{
		ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Steel Gauntlet Pusher.");
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be a Steel Gauntlet Pusher.");
	}
	return Plugin_Continue;
}

public Action Command_GiantDeflectorHeavy(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && bInRespawn[client] && iRobotMode[client] == Robot_Giant)
	{
		TF2_SetPlayerClass(client, TFClass_Heavy);
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.5 ; 323 ; 1");
		SpawnWeapon( client, "tf_weapon_minigun", 850, 100, 5, weaponAttribs, false );
		ReplyToCommand(client, "[Red2Robot] You are now a Giant Deflector Heavy!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now a Giant Deflector Heavy!", client);
	}
	else if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Giant)
	{
		ReplyToCommand(client, "[Red2Robot] You need to be a giant in order to become a Giant Deflector Heavy.");
	}
	else if (GetClientTeam(client) == 3 && TF2_GetPlayerClass(client) != TFClass_Heavy)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Giant Deflector Heavy because you are not playing as heavy.")
	}
	else if (GetClientTeam(client) == 3 && !bInRespawn[client])
	{
		ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Giant Deflector Heavy.");
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be a Giant Deflector Heavy.");
	}
	return Plugin_Continue;
}

public Action Command_GiantChargedSoldier(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && bInRespawn[client] && iRobotMode[client] == Robot_Giant)
	{
		TF2_SetPlayerClass(client, TFClass_Soldier);
		SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Normal);
		if(!g_bHasCrits[client] && !Is666Mode)
		{
			g_bHasCrits[client] = true;
		}
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		Format(weaponAttribs, sizeof(weaponAttribs), "318 ; 0.2 ; 6 ; 2 ; 103 ; 0.5");
		SpawnWeapon( client, "tf_weapon_rocketlauncher", 513, 100, 5, weaponAttribs, false );
		ReplyToCommand(client, "[Red2Robot] You are now a Giant Charged Soldier!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now a Giant Charged Soldier!", client);
	}
	else if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Giant)
	{
		ReplyToCommand(client, "[Red2Robot] You need to be a giant in order to become a Giant Charged Soldier.");
	}
	else if (GetClientTeam(client) == 3 && TF2_GetPlayerClass(client) != TFClass_Soldier)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Giant Charged Soldier because you are not playing as soldier.")
	}
	else if (GetClientTeam(client) == 3 && !bInRespawn[client])
	{
		ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Giant Charged Soldier.");
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be a Giant Charged Soldier.");
	}
	return Plugin_Continue;
}

public Action Command_GiantRapidFireSoldier(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && bInRespawn[client] && iRobotMode[client] == Robot_Giant)
	{
		TF2_SetPlayerClass(client, TFClass_Soldier);
		SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Expert);
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		Format(weaponAttribs, sizeof(weaponAttribs), "318 ; -0.8 ; 6 ; 0.5");
		SpawnWeapon( client, "tf_weapon_rocketlauncher", 205, 100, 5, weaponAttribs, false );
		ReplyToCommand(client, "[Red2Robot] You are now a Giant Rapid Fire Soldier!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now a Giant Rapid Fire Soldier!", client);
	}
	else if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Giant)
	{
		ReplyToCommand(client, "[Red2Robot] You need to be a giant in order to become a Giant Rapid Fire Soldier.");
	}
	else if (GetClientTeam(client) == 3 && TF2_GetPlayerClass(client) != TFClass_Soldier)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Giant Rapid Fire Soldier because you are not playing as soldier.")
	}
	else if (GetClientTeam(client) == 3 && !bInRespawn[client])
	{
		ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Giant Rapid Fire Soldier.");
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be a Giant Rapid Fire Soldier.");
	}
	return Plugin_Continue;
}

public Action Command_Giant(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Giant && iRobotMode[client] != Robot_SentryBuster)
	{
		if (bRespawnForm || !IsPlayerAlive(client))
		{
			iRobotMode[client] = Robot_Giant;
			TF2_RespawnPlayer(client);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
			ReplyToCommand(client, "[Red2Robot] You are now a Giant Robot!");
			ShowActivity2(client, "[Red2Robot] ", "%N is now a Giant Robot!", client);
		}
		else if (!bRespawnForm && bInRespawn[client])
		{
			if (iRobotMode[client] == Robot_SentryBuster)
				TF2_RemoveCondition(client, TFCond_PreventDeath);
			GiantRobot(client);
			TF2_RegeneratePlayer(client);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
			ReplyToCommand(client, "[Red2Robot] You are now a Giant Robot!");
			ShowActivity2(client, "[Red2Robot] ", "%N is now a Giant Robot!", client);
		}
		else if (!bRespawnForm && !bInRespawn[client])
		{
			ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Giant Robot.")
		}
	}
	else if (iRobotMode[client] == Robot_Giant)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Giant Robot again because you already are.")
	}
	else if (iRobotMode[client] == Robot_SentryBuster)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Giant Robot while you're a Sentry Buster.")
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn into a Giant Robot.");
	}
	return Plugin_Continue;
}

public Action Command_SentryBuster(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Giant && iRobotMode[client] != Robot_SentryBuster)
	{
		if (bRespawnForm || !IsPlayerAlive(client))
		{
			TF2_RespawnPlayer(client);
			SentryBuster(client);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
			ReplyToCommand(client, "[Red2Robot] You are now a Sentry Buster!");
			ShowActivity2(client, "[Red2Robot] ", "%N is now a Sentry Buster!", client);
		}
		else if (!bRespawnForm && bInRespawn[client])
		{
			SentryBuster(client);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
			ReplyToCommand(client, "[Red2Robot] You are now a Sentry Buster!");
			ShowActivity2(client, "[Red2Robot] ", "%N is now a Sentry Buster!", client);
		}
		else if (!bRespawnForm && !bInRespawn[client])
		{
			ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Sentry Buster.")
		}
	}
	else if (iRobotMode[client] == Robot_SentryBuster)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Sentry Buster again because you already are.")
	}
	else if (iRobotMode[client] == Robot_Giant)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Sentry Buster while you're a Giant Robot.")
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn into a Sentry Buster.");
	}
	return Plugin_Continue;
}

public Action Command_Small(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == 3 && iRobotMode[client] != Robot_Normal)
	{
		if (bRespawnForm || !IsPlayerAlive(client))
		{
			NormalRobot(client);
			TF2_RespawnPlayer(client);
			ReplyToCommand(client, "[Red2Robot] You are now a Normal Robot!");
			ShowActivity2(client, "[Red2Robot] ", "%N is now a Normal Robot!", client);
		}
		else if (!bRespawnForm && bInRespawn[client])
		{
			TF2_RegeneratePlayer(client);
			if (iRobotMode[client] == Robot_SentryBuster)
				TF2_RemoveCondition(client, TFCond_PreventDeath);
			NormalRobot(client);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
			ReplyToCommand(client, "[Red2Robot] You are now a Normal Robot!");
			ShowActivity2(client, "[Red2Robot] ", "%N is now a Normal Robot!", client);
		}
		else if (!bRespawnForm && !bInRespawn[client])
		{
			ReplyToCommand(client, "[Red2Robot] You need to be on spawn in order to become a Normal Robot.")
		}
	}
	else if (iRobotMode[client] == Robot_Normal)
	{
		ReplyToCommand(client, "[Red2Robot] You can't be a Normal Robot again because you already are.")
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn into a Normal Robot.");
	}
	return Plugin_Continue;
}

public Action OnSpawnStartTouch(int iEntity, int iOther)
{
	if( !IsMvM() || !IsValidClient(iOther) || IsFakeClient(iOther) || GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != TFTeam_Blue )
		return Plugin_Continue;
	
	bInRespawn[iOther] = true;
	return Plugin_Continue;
}

public void OnGameFrame()
{
	if( !IsMvM() )
		return;
	
	int i, iFlag = -1;
	while((iFlag = FindEntityByClassname(iFlag, "item_teamflag")) != -1)
	{
		i = GetEntPropEnt( iFlag, Prop_Send, "m_hOwnerEntity" );
		if(IsValidClient(i) && (!bFlagPickup && GetClientTeam(i) != TFTeam_Blue))
			AcceptEntityInput(iFlag, "ForceReset");
	}
	
	int iEFlags;
	for (i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			iFlag = GetEntPropEnt(i, Prop_Send, "m_hItem");
			if(!IsValidEdict(iFlag))
				iFlag = 0;
			
			if(IsFakeClient(i))
				continue;
			
			SetEntProp(i, Prop_Send, "m_bIsMiniBoss", false);
			if(GetClientTeam(i) == TFTeam_Blue)
			{
				if(iRobotMode[i] == Robot_Giant || iRobotMode[i] == Robot_SentryBuster)
				{
					SetEntProp(i, Prop_Send, "m_bIsMiniBoss", true);
				}
				if(bBetweenUber && GameRules_GetRoundState() == RoundState_BetweenRounds)
				{
					TF2_AddCondition(i, TFCond_UberchargedHidden, 1.0);
					TF2_AddCondition(i, TFCond_UberchargeFading, 1.0);
				}
			}
			if(GetClientTeam(i) == TFTeam_Blue && IsValidClient(i) && !IsFakeClient(i) && bInRespawn[i])
			{
				TF2_AddCondition(i, TFCond_UberchargedHidden, 1.4);
				TF2_AddCondition(i, TFCond_UberchargeFading, 1.4);
			}
			if(g_bHasCrits[i])
				TF2_AddCondition(i, TFCond_CritCanteen, 0.125);
			else if(GetClientTeam(i) == TFTeam_Blue && TF2_GetPlayerClass(i) == TFClass_Spy)
				SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 100.0);
			if(GetClientTeam(i) != TFTeam_Blue)
			{
				if(iFlag)
					AcceptEntityInput(iFlag, "ForceDrop");
				continue;
			}
			else if(iFlag && !bFlagPickup || iRobotMode[i] == Robot_SentryBuster)
				AcceptEntityInput(iFlag, "ForceDrop");
			
			iEFlags = GetEntityFlags(i);
			if(GetClientTeam(i) == TFTeam_Blue && bSpawnFreeze && GameRules_GetRoundState() == RoundState_BetweenRounds) //
			{
				SetEntPropFloat( i, Prop_Send, "m_flMaxspeed", 1.0 );
				iEFlags |= FL_ATCONTROLS;
				SetEntityFlags( i, iEFlags );
				bFreezed[i] = true;
			}
			else if( bFreezed[i] )
			{
				iEFlags &= ~FL_ATCONTROLS;
				SetEntityFlags( i, iEFlags );
//				iHealth = GetClientHealth( i );
//				TF2_RegeneratePlayer( i );
//				SetEntityHealth( i, iHealth );
				bFreezed[i] = false;
			}
			if (Is666Mode)
			{
				if (GetClientTeam(i) ==3)
				{
					TF2_AddCondition(i, TFCond_CritCanteen, TFCondDuration_Infinite); //for all classes
					if(TF2_GetPlayerClass(i) == TFClass_Engineer)
						TF2_AddCondition(i, TFCond_Buffed, TFCondDuration_Infinite); //minicrits for sentry main engi defense 
				}
			}
		}
	}
}

public Action OnFlagTouch(int iEntity, int iOther)
{
	if( !IsMvM() || !IsValidClient(iOther) || IsFakeClient(iOther) )
		return Plugin_Continue;
		
	if( GetClientTeam(iOther) != TFTeam_Blue || !bFlagPickup)
		return Plugin_Handled;

	return Plugin_Continue; 
}

public Action OnSpawnEndTouch(int iEntity, int iOther)
{
	if( !IsMvM() || !IsValidClient(iOther) || IsFakeClient(iOther) || GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != TFTeam_Blue )
		return Plugin_Continue;
	
	bInRespawn[iOther] = false;
	return Plugin_Continue;
}

public void OnEntityCreated(int iEntity, const char[] strClassname )
{
	char sEnt[255];
	Entity_GetClassName(iEntity,sEnt,sizeof(sEnt));
	
	if( StrEqual( strClassname, "func_respawnroom", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnSpawnStartTouch );
		SDKHook( iEntity, SDKHook_EndTouch, OnSpawnEndTouch );
	}
	if (StrEqual(sEnt, "entity_revive_marker"))
	{
		if( StrEqual( strClassname, "entity_revive_marker", false ) )
			CreateTimer(0.05, FindReviveMaker, iEntity);
	}
	
	if (GetGameTime() < 0.5) return;
	if (iEntity < MaxClients || iEntity > 2048) return;
	if (StrContains(sEnt, "obj_sen", false) == 0)
		SDKHook(iEntity, SDKHook_Spawn, OnSentrySpawned);
}

public Action OnSentrySpawned(int Ent)
{
	SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage);
}

stock bool Entity_GetClassName(int entity, char[] buffer, int size)
{
	GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);
	
	if (buffer[0] == '\0') 	
	{
		return false;
	}
	
	return true;
}

public void OnClientDisconnect(int client)
{
	RemoveModel(client);
	StopSounds(client);
}

public Action Command_Help(int client, int args)
{
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	ReplyToCommand(client, "[Red2Robot] !bot, !machine [target], !mann [target], !giant, !small, !bowmanrapidfire, !shortstop, !gauntlet, !gauntletpusher, !deflector, !giantchargedsoldier, !giantrapidsoldier");
	
	return Plugin_Continue;
}

public Action event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (IsMvM())
	{
		StopSounds(client);
		int minigun = GetPlayerWeaponSlot(client, 0);
		if(TF2_GetPlayerClass(client) == TFClass_Heavy && iRobotMode[client] == Robot_Giant)
			TF2Attrib_RemoveByName(minigun, "damage bonus");
		if(iRobotMode[client] == Robot_Giant || iRobotMode[client] == Robot_BigNormal || iRobotMode[client] == Robot_SentryBuster)
		{
			CreateTimer(0.05, Timer_RemoveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			
			int Ent
			float ClientOrigin[3]
			
			//Initialize:
			Ent = CreateEntityByName("tf_ragdoll")
			GetClientAbsOrigin(client, ClientOrigin)
			
			//Write:
			SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin)
			SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client)
			SetEntPropVector(Ent, Prop_Send, "m_vecForce", NULL_VECTOR)
			SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR)
			SetEntProp(Ent, Prop_Send, "m_bGib", 1)
			
			//Send:
			DispatchSpawn(Ent)	
		}
	}
	return Plugin_Continue;
}

public Action Timer_RemoveRagdoll(Handle timer, any uid)
{
	int client = GetClientOfUserId(uid);
	if (!IsValidClient(client)) return;
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsValidEntity(ragdoll) || ragdoll <= MaxClients) return;
	AcceptEntityInput(ragdoll, "Kill");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (IsMvM())
	{
		if (GetClientTeam(client) == 3)
		{
			StopSounds(client);
			TF2_AddCondition(client, TFCond_UberchargedHidden, 0.3);
			TF2_AddCondition(client, TFCond_UberchargeFading, 0.3);
			if (iRobotMode[client] == Robot_Giant)
			{
				GiantRobot(client);
			}
			else
			{
				NormalRobot(client);
			}
			if (TF2_GetPlayerClass(client) == TFClass_Medic)
			{
				int weapon = GetPlayerWeaponSlot(client, 1);
				if (IsValidEdict(weapon))
				SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 1.0);
			}
			else if (TF2_GetPlayerClass(client) == TFClass_Soldier)
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
		}
		else
		{
			RemoveAttribs(client);
			if(iRobotMode[client] == Robot_Normal || iRobotMode[client] == Robot_Giant || iRobotMode[client] == Robot_BigNormal || iRobotMode[client] == Robot_SentryBuster)
			{
				StopSounds(client);
				RemoveModel(client);
				if(iRobotMode[client] == Robot_Giant || iRobotMode[client] == Robot_BigNormal || iRobotMode[client] == Robot_SentryBuster)
				{
					SetEntProp(client, Prop_Data, "m_iMaxHealth", GetClassMaxHealth(client));
					SetEntProp(client, Prop_Send, "m_iHealth", GetClassMaxHealth(client), 1);
				}
				iRobotMode[client] = Robot_Human;
				AboutToExplode[client] = false;
			}
		}
	}
	if (Is666Mode)
	{
		if (GetClientTeam(client) ==3)
		{
			TF2_AddCondition(client, TFCond_CritCanteen, TFCondDuration_Infinite); //for all classes
			if(TF2_GetPlayerClass(client) == TFClass_Engineer)
				TF2_AddCondition(client, TFCond_Buffed, TFCondDuration_Infinite); //minicrits for sentry main engi defense 
		}
	}
	return Plugin_Continue;
}

public Action event_PostInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsMvM() || !IsValidClient(client) || IsFakeClient(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) == TFTeam_Blue)
	{
		if(!bWearables)
			TF2_RemoveWearables(client);
		if(!bAction)
			TF2_RemoveActions(client);
	}
	return Plugin_Continue;
}

public Action FindReviveMaker(Handle Timer, any iEntity)
{
//	new ReviveMakers = -1;
//	if((ReviveMakers = FindEntityByClassname(ReviveMakers,"entity_revive_marker")) != -1)
//	{
		int client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwner");
		if(GetClientTeam(client) == TFTeam_Blue)
		{
			AcceptEntityInput(iEntity,"Kill");
		}
//	}
}

int GetClassMaxHealth(int client)
{
	TFClassType class = TF2_GetPlayerClass(client);
	int Health;
	switch(class)
	{
		case TFClass_Scout: Health = 125;
		case TFClass_Soldier: Health = 200;
		case TFClass_Pyro: Health = 175;
		case TFClass_DemoMan: Health = 175;
		case TFClass_Heavy: Health = 300;
		case TFClass_Engineer: Health = 125;
		case TFClass_Medic: Health = 150;
		case TFClass_Sniper: Health = 125;
		case TFClass_Spy: Health = 125;
	}
	return Health;
}

stock bool SetModel(int client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	char Mdl[PLATFORM_MAX_PATH];
	if(iRobotMode[client] == Robot_SentryBuster)
	{
		PrecacheModel("models/bots/demo/bot_sentry_buster.mdl");
		SetVariantString("models/bots/demo/bot_sentry_buster.mdl");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", GetConVarFloat(cvarBossScale));
		UpdatePlayerHitbox(client, GetConVarFloat(cvarBossScale));
	}
	else
	{
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout: Format(Mdl, sizeof(Mdl), "scout");
			case TFClass_Soldier: Format(Mdl, sizeof(Mdl), "soldier");
			case TFClass_Pyro: Format(Mdl, sizeof(Mdl), "pyro");
			case TFClass_DemoMan: Format(Mdl, sizeof(Mdl), "demo");
			case TFClass_Heavy: Format(Mdl, sizeof(Mdl), "heavy");
			case TFClass_Medic: Format(Mdl, sizeof(Mdl), "medic");
			case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
			case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
			case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "engineer");
		}
		if(iRobotMode[client] == Robot_Giant)
		{
			if( TF2_GetPlayerClass(client) == TFClass_DemoMan || TF2_GetPlayerClass(client) == TFClass_Heavy || TF2_GetPlayerClass(client) == TFClass_Pyro || TF2_GetPlayerClass(client) == TFClass_Scout || TF2_GetPlayerClass(client) == TFClass_Soldier )
				Format(Mdl, sizeof(Mdl), "models/bots/%s_boss/bot_%s_boss.mdl", Mdl, Mdl);
			else
			{
				Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
			}
			PrecacheModel(Mdl);
			SetVariantString(Mdl);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", GetConVarFloat(cvarBossScale));
			UpdatePlayerHitbox(client, GetConVarFloat(cvarBossScale));
		}
		else
		{
			Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
			PrecacheModel (Mdl);
			SetVariantString(Mdl);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		}
		if (StrEqual(Mdl, "")) return false;
		return true;
	}
	return false;
}

stock float GetVectorDistanceMeter( const float vec1[3], const float vec2[3], bool squared = false )
{
	return ( GetVectorDistance( vec1, vec2, squared ) / 50.00 );
}

public bool TraceFilter( int iEntity, int iContentsMask )
{
	if( iEntity == 0 || IsValidEntity(iEntity) && !IsValidEdict(iEntity) )
		return true;
	if( iEntity == iFilterEnt[0] )
		return false;
	if( iEntity == iFilterEnt[1] )
		return true;
	char strClassname[64];
	GetEdictClassname( iEntity, strClassname, sizeof(strClassname) ); 
	if( StrEqual( strClassname, "player", false ) || StrContains( strClassname, "obj_", false ) == 0 || StrEqual( strClassname, "tf_ammo_pack", false ) )
		return false;
	//PrintToServer( "%s - block", strClassname );
	return true;
}

public Action Command_Ready(int iClient, const char[] strCommand, int nArgs)
{
	if(IsMvM() && bRestrictReady && GetClientTeam(iClient) == TFTeam_Blue)
	{
		PrintToChat( iClient, "* BLU team can't start the game." );
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock int SpawnWeapon(int client,char[] name,int index,int level,int qual,char[] att, bool bWearable = false)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2 = 0;
		for (int i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	if( IsValidEdict( entity ) )
	{
		if( bWearable )
		{
			if( hSDKEquipWearable != INVALID_HANDLE )
				SDKCall( hSDKEquipWearable, client, entity );
		}
		else
			EquipPlayerWeapon( client, entity );
	}
	return entity;
}

stock void StopSounds(int entity)
{
	if(entity <= 0 || !IsValidEntity(entity))
		return;
	
	StopSnd(entity, SNDCHAN_STATIC, "mvm/giant_scout/giant_scout_loop.wav");
	StopSnd(entity, SNDCHAN_STATIC, "mvm/giant_soldier/giant_soldier_loop.wav");
	StopSnd(entity, SNDCHAN_STATIC, "mvm/giant_pyro/giant_pyro_loop.wav");
	StopSnd(entity, SNDCHAN_STATIC, "mvm/giant_demoman/giant_demoman_loop.wav");
	StopSnd(entity, SNDCHAN_STATIC, ")mvm/giant_heavy/giant_heavy_loop.wav");
	StopSnd(entity, SNDCHAN_STATIC, "mvm/sentrybuster/mvm_sentrybuster_loop.wav")
}

stock void StopSnd(int client, int channel = SNDCHAN_AUTO, const char sound[PLATFORM_MAX_PATH])
{
	if(!IsValidEntity(client))
		return;
	StopSound(client, channel, sound);
}

stock void UpdatePlayerHitbox(const int client, const float fScale)
{
	static const float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
   
	float vecScaledPlayerMin[3], vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
   
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
   
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

stock bool RemoveModel(int client)
{
	if (!IsValidClient(client)) return false;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	return true;
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock void NormalRobot(int client)
{
	RemoveAttribs(client);
	if(iRobotMode[client] == Robot_Giant || iRobotMode[client] == Robot_BigNormal || iRobotMode[client] == Robot_SentryBuster)
	{
		SetEntProp(client, Prop_Data, "m_iMaxHealth", GetClassMaxHealth(client));
		SetEntProp(client, Prop_Send, "m_iHealth", GetClassMaxHealth(client), 1);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		UpdatePlayerHitbox(client, 1.0);
		SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Easy);
		int minigun = GetPlayerWeaponSlot(client, 0);
		if(TF2_GetPlayerClass(client) == TFClass_Heavy && iRobotMode[client] == Robot_Giant)
			TF2Attrib_RemoveByName(minigun, "damage bonus");
	}
	if(g_bHasCrits[client])
	{
		g_bHasCrits[client] = false;
	}
	iRobotMode[client] = Robot_Normal;
	
	StopSounds(client);
	
	AboutToExplode[client] = false;
	
	SetModel(client);
}

stock void GiantRobot(int client)
{
	iRobotMode[client] = Robot_Giant;
	SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Expert);
	RemoveAttribs(client);
	if(g_bHasCrits[client])
	{
		g_bHasCrits[client] = false;
	}
	
	CreateTimer(0.05, Timer_OnPlayerBecomeGiant, client);
	AddAttribs(client);
	
	AboutToExplode[client] = false;
	
	SetModel(client);
}

stock void SentryBuster(int client)
{
	iRobotMode[client] = Robot_SentryBuster;
	TF2_RegeneratePlayer(client);
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RemoveWearables(client);
	SetEntProp(client, Prop_Send, "m_nBotSkill", BotSkill_Expert);
	RemoveAttribs(client);
	if(g_bHasCrits[client])
	{
		g_bHasCrits[client] = false;
	}
	
	TF2_AddCondition(client, TFCond_PreventDeath, TFCondDuration_Infinite);
	CreateTimer(0.05, Timer_OnPlayerBecomeGiant, client);
	if( hTimer_SentryBuster_Beep[client] != INVALID_HANDLE )
		KillTimer( hTimer_SentryBuster_Beep[client] );
	hTimer_SentryBuster_Beep[client] = CreateTimer( 5.0, Timer_SentryBuster_Beep, GetClientUserId(client), TIMER_REPEAT );
	TriggerTimer( hTimer_SentryBuster_Beep[client] );
	EmitGameSoundToClients(SENTRYBUSTER_SND_ALERT);
	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 2);
	Format(weaponAttribs, sizeof(weaponAttribs), "704 ; 0");
	SpawnWeapon( client, "tf_weapon_stickbomb", 307, 100, 5, weaponAttribs, false );
	AddAttribs(client);
	
	SetModel(client);
}

public Action Timer_SentryBuster_Beep( Handle hTimer, any iUserID )
{
	int iClient = GetClientOfUserId( iUserID );
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster || TF2_IsPlayerInCondition( iClient, TFCond_Taunting ) )
	{
		if( hTimer_SentryBuster_Beep[iClient] != INVALID_HANDLE )
			KillTimer( hTimer_SentryBuster_Beep[iClient] );
		hTimer_SentryBuster_Beep[iClient] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	EmitGameSoundToAll( SENTRYBUSTER_SND_INTRO, iClient );
	return Plugin_Handled;
}

public Action Timer_OnPlayerBecomeGiant(Handle Timer, any client)
{
	PlaySounds(client);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!IsMvM())
		return Plugin_Stop;
	
	if (IsValidClient(victim))
	{
		if (iRobotMode[victim] != Robot_SentryBuster || victim == attacker) return Plugin_Continue;
		float dmg = ((damagetype & DMG_CRIT) ? damage*3 : damage) + 10.0; // +10 to attempt to account for damage rampup.
		if (AboutToExplode[victim])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		else if (dmg > GetClientHealth(victim))
		{
			damage = 0.0;
			GetReadyToExplode(victim);
			FakeClientCommand(victim, "taunt");
			return Plugin_Changed;
		}
	}
	else if (IsValidClient(attacker)) // This is a Sentry.
	{
		if (iRobotMode[attacker] == Robot_SentryBuster && !AboutToExplode[attacker])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action Listener_taunt(int client, const char[] command, int args)
{
	if (iRobotMode[client] == Robot_SentryBuster)
	{
		if (AboutToExplode[client]) return Plugin_Continue;
		if (GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1) return Plugin_Continue;
		GetReadyToExplode(client);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action Command_Suicide( int iClient, const char[] strCommand, int nArgs )
{
	if( !IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster )
		return Plugin_Continue;
	
	FakeClientCommand( iClient, "taunt" );
	return Plugin_Handled;
}

stock void EmitGameSoundToClients( const char strSample[PLATFORM_MAX_PATH] )
{
	for( int i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) )
			EmitGameSoundToClient( i, strSample );
}

//stock void RemoveHeal(int client)
//{
//	if(iRobotMode[client] == Robot_Giant)
//	{
//		if(TF2_GetPlayerClass(client) != TFClass_Medic)
//		{
//			TF2Attrib_RemoveByName(client, "heal rate bonus")
//		}
//	}
//}

stock void GetReadyToExplode(int client)
{
	EmitGameSoundToAll(SENTRYBUSTER_SND_SPIN, client);
	StopSounds(client);
	CreateTimer(2.0, Timer_SentryBuster_Explode, GetClientUserId(client));
	AboutToExplode[client] = true;
}

public Action Timer_SentryBuster_Explode(Handle hTimer, any iUserID )
{
	int iClient = GetClientOfUserId( iUserID );
	if(!IsMvM() || !IsValidClient(iClient) || IsFakeClient(iClient) || !IsPlayerAlive(iClient) || iRobotMode[iClient] != Robot_SentryBuster)
		return Plugin_Stop;
	
	float flExplosionPos[3];
	GetClientAbsOrigin( iClient, flExplosionPos );
	int i;
	for( i = 1; i <= MaxClients; i++ )
		if( i != iClient && IsValidClient(i) && IsPlayerAlive(i) ) //&& GetClientTeam(i) == TFTeam_Red )
			if( CanSeeTarget( iClient, i, 400.0 ) )
				DealDamage( i, 2500, iClient, TF_CUSTOM_PUMPKIN_BOMB );
	
	char strObjects[5][] = { "obj_sentrygun","obj_dispenser","obj_teleporter","obj_teleporter_entrance","obj_teleporter_exit" };
	for( int o = 0; o < sizeof(strObjects); o++ )
	{
		i = -1;
		while( ( i = FindEntityByClassname( i, strObjects[o] ) ) != -1 )
			if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) != TFTeam_Blue && !GetEntProp( i, Prop_Send, "m_bCarried" ) && !GetEntProp( i, Prop_Send, "m_bPlacing" ) )
				if( CanSeeTarget( iClient, i, 400.0 ) )
					DealDamage( i, 2500, iClient );
	}
	
	CreateParticle( flExplosionPos, "fluidSmokeExpl_ring_mvm", 6.5 );
	CreateParticle( flExplosionPos, "explosionTrail_seeds_mvm", 5.5 );	//fluidSmokeExpl_ring_mvm  explosionTrail_seeds_mvm
	
	ForcePlayerSuicide( iClient );
	
	AboutToExplode[iClient] = false;
	
	return Plugin_Stop;
}

stock void DealDamage( int victim, int damage, int attacker = 0, int dmg_type = 0 )
{
	if( victim > 0 && IsValidEntity(victim) && ( victim > MaxClients || IsClientInGame(victim) && IsPlayerAlive(victim) ) && damage > 0 )
	{
		char dmg_str[16];
		IntToString(damage, dmg_str, 16);
		
		char dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);

		int pointHurt = CreateEntityByName("point_hurt");
		if( pointHurt )
		{
			DispatchKeyValue(victim, "targetname", "point_hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "point_hurtme");
			DispatchKeyValue(pointHurt, "Damage", dmg_str);
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "point_donthurtme");
			AcceptEntityInput(pointHurt, "Kill");
		}
	}
}

stock bool CanSeeTarget( int iEntity, int iOther, float flMaxDistance = 0.0 )
{
	if( iEntity <= 0 || iOther <= 0 || !IsValidEntity(iEntity) || !IsValidEntity(iOther) )
		return false;
	
	float vecStart[3];
	float vecStartMaxs[3];
	float vecTarget[3];
	float vecTargetMaxs[3];
	float vecEnd[3];
	
	GetEntPropVector( iEntity, Prop_Data, "m_vecOrigin", vecStart );
	GetEntPropVector( iEntity, Prop_Send, "m_vecMaxs", vecStartMaxs );
	GetEntPropVector( iOther, Prop_Data, "m_vecOrigin", vecTarget );
	GetEntPropVector( iOther, Prop_Send, "m_vecMaxs", vecTargetMaxs );
	
	vecStart[2] += vecStartMaxs[2] / 2.0;
	vecTarget[2] += vecTargetMaxs[2] / 2.0;
	
	if( flMaxDistance > 0.0 )
	{
		float flDistance = GetVectorDistance( vecStart, vecTarget );
		if( flDistance > flMaxDistance )
		{
			BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{255,0,0,255},0.0,0);
			return false;
		}
	}
	
	iFilterEnt[0] = iEntity;
	iFilterEnt[1] = iOther;
	Handle hTrace = TR_TraceRayFilterEx( vecStart, vecTarget, MASK_VISIBLE, RayType_EndPoint, TraceFilter );
	if( !TR_DidHit( hTrace ) )
	{
		BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{255,255,0,255},0.0,0);
		CloseHandle( hTrace );
		return false;
	}
	
	int iHitEnt = TR_GetEntityIndex( hTrace );
	TR_GetEndPosition( vecEnd, hTrace );
	CloseHandle( hTrace );
	
	if( iHitEnt == iOther || GetVectorDistanceMeter( vecEnd, vecTarget ) <= 1.0 )
	{
		BeamEffect(vecStart,vecTarget,6.0,5.0,5.0,{0,255,0,255},0.0,0);
		return true;
	}
	
	BeamEffect(vecStart,vecEnd,6.0,5.0,5.0,{0,0,255,255},0.0,0);
	return false;
}

stock void BeamEffect(float startvec[3],float endvec[3],float life,float width,float endwidth,const int color[4],float amplitude,int speed)
{
	if(!bSentryBusterDebug) return;
	TE_SetupBeamPoints(startvec,endvec,iLaserModel,0,0,66,life,width,endwidth,0,amplitude,color,speed);
	TE_SendToAll();
} 

stock void RemoveAttribs(int client)
{
	if (iRobotMode[client] == Robot_Giant || iRobotMode[client] == Robot_BigNormal || iRobotMode[client] == Robot_SentryBuster)
	{
		TF2Attrib_RemoveByName(client, "override footstep sound set");
		TF2Attrib_RemoveByName(client, "airblast vulnerability multiplier");
		TF2Attrib_RemoveByName(client, "damage force reduction");
		TF2Attrib_RemoveByName(client, "heal rate bonus");
		TF2Attrib_RemoveByName(client, "head scale");
		TF2Attrib_RemoveByName(client, "cannot be backstabbed");
		TF2Attrib_RemoveByName(client, "move speed bonus");
		TF2Attrib_RemoveByName(client, "hidden maxhealth non buffed");
	}
}

stock void AddAttribs(int client)
{
	if (iRobotMode[client] == Robot_Giant)
	{
		int minigun = GetPlayerWeaponSlot(client, 0);
		if (TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 5.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
			TF2Attrib_SetByName(client, "damage force reduction", 0.7);
			TF2Attrib_SetByName(client, "move speed bonus", 1.0);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1475.0);
			SetEntProp(client, Prop_Data, "m_iHealth", 1600);
		}
		else if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
			TF2Attrib_SetByName(client, "damage force reduction", 0.4);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3600.0);
			SetEntProp(client, Prop_Data, "m_iHealth", 3800);
		}
		else if (TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
			TF2Attrib_SetByName(client, "damage force reduction", 0.6);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 2825.0);
			SetEntProp(client, Prop_Data, "m_iHealth", 3000);
		}
		else if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
			TF2Attrib_SetByName(client, "damage force reduction", 0.5);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3125.0);
			SetEntProp(client, Prop_Data, "m_iHealth", 3300);
		}
		else if (TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
			TF2Attrib_SetByName(client, "damage force reduction", 0.3);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 4700.0);
			TF2Attrib_SetByName(minigun, "damage bonus", 1.5);
			SetEntProp(client, Prop_Data, "m_iHealth", 5000);
		}
		else if (TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
			TF2Attrib_SetByName(client, "damage force reduction", 0.6);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3475.0);
			SetEntProp(client, Prop_Data, "m_iHealth", 3600);
		}
		else if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 0.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
			TF2Attrib_SetByName(client, "damage force reduction", 0.6);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "heal rate bonus", 200.0);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 4350.0);
			SetEntProp(client, Prop_Data, "m_iHealth", 4500);
		}
		else if (TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
			TF2Attrib_SetByName(client, "damage force reduction", 0.5);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1625.0);
			SetEntProp(client, Prop_Data, "m_iHealth", 1750);
		}
		else if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			TF2Attrib_SetByName(client, "override footstep sound set", 5.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
			TF2Attrib_SetByName(client, "damage force reduction", 0.6);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1375.0);
			SetEntProp(client, Prop_Data, "m_iHealth", 1500);
		}
	}
	else if (iRobotMode[client] == Robot_SentryBuster)
	{
		TF2Attrib_SetByName(client, "override footstep sound set", 7.0);
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
		TF2Attrib_SetByName(client, "damage force reduction", 0.5);
		TF2Attrib_SetByName(client, "move speed bonus", 2.0);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 2325.0);
		TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
		SetEntProp(client, Prop_Data, "m_iHealth", 2500);
	}
}

stock void PlaySounds(int entity)
{
	if(entity <= 0 || !IsValidEntity(entity))
		return;
	
	if(iRobotMode[entity] == Robot_SentryBuster)
	{
		EmitGameSoundToAll(SENTRYBUSTER_SND_LOOP, entity);
	}
	else
	{
		if(TF2_GetPlayerClass(entity) == TFClass_Scout)
			EmitGameSoundToAll(GIANTSCOUT_SND_LOOP, entity);
		else if(TF2_GetPlayerClass(entity) == TFClass_Soldier)
			EmitGameSoundToAll(GIANTSOLDIER_SND_LOOP, entity);
		else if(TF2_GetPlayerClass(entity) == TFClass_Pyro)
			EmitGameSoundToAll(GIANTPYRO_SND_LOOP, entity);
		else if(TF2_GetPlayerClass(entity) == TFClass_DemoMan)
			EmitGameSoundToAll(GIANTDEMOMAN_SND_LOOP, entity);
		else if(TF2_GetPlayerClass(entity) == TFClass_Heavy)
			EmitGameSoundToAll(GIANTHEAVY_SND_LOOP, entity);
	}
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float flVelocity[3], float flAngles[3], int &iWeapon )
{
	if( !IsMvM() || GetClientTeam(iClient) != TFTeam_Blue || !IsValidClient(iClient) || IsFakeClient(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	if(bSpawnFreeze && GameRules_GetRoundState() == RoundState_BetweenRounds /*&& bInRespawn[iClient]*/)
	{
		if(iButtons & IN_JUMP)
		{
			iButtons &= ~IN_JUMP;
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if(iButtons & IN_ATTACK)
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		else if(iButtons & IN_ATTACK2)
		{
			iButtons &= ~IN_ATTACK;
			iButtons &= ~IN_ATTACK2;
			return Plugin_Changed;
		}
		if(iButtons & IN_FORWARD && TF2_IsPlayerInCondition(iClient, TFCond_HalloweenKartNoTurn)) 
		{
			iButtons &= ~IN_FORWARD;
		}
		
	}
	
	return Plugin_Continue;
}

public Action SoundHook(int clients[64], int &numClients, char strSound[PLATFORM_MAX_PATH], int &iEntity, int &channel, float &volume, int &level, int &iPitch, int &flags)
{
	if(StrContains(strSound, "announcer", false) != -1)
		return Plugin_Continue;
	else if(StrContains(strSound, "vo/", false) != -1)
	{
		if(iRobotMode[iEntity] == Robot_SentryBuster)
			return Plugin_Handled;//Stop Sound
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock void TF2_RemoveActions(int client)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				AcceptEntityInput(wearable, "Kill");
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				AcceptEntityInput(wearable, "Kill");
			}
		}
	}
	
	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_grapplinghook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				AcceptEntityInput(wearable, "Kill");
			}
		}
	}
}

stock void TF2_RemoveWearables(int client)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}

stock bool IsMvM(bool forceRecalc = false)
{
    static bool found = false;
    static bool ismvm = false;
    if (forceRecalc)
    {
        found = false;
        ismvm = false;
    }
    if (!found)
    {
        int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
        if (i > MaxClients && IsValidEntity(i)) ismvm = true;
        found = true;
    }
    return ismvm;
}

public void OnGateCapture(const char[] output, int caller, int activator, float delay)
{
	if(IsMannhattan)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TFTeam_Blue && !IsFakeClient(i))
			{
				SetEntProp(i, Prop_Send, "m_iTeamNum", 0);
				CreateTimer(0.13,ResetTeam, i);//prevent the crash
				if(iRobotMode[i] != Robot_Giant && iRobotMode[i] != Robot_SentryBuster)
				{
					TF2_AddCondition(i, TFCond_MVMBotRadiowave, 22.0);
					TF2_StunPlayer(i, 22.0, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, _);
				}
			}
		}
	}
}

public Action ResetTeam(Handle timer,any iclient)
{
	int entflags = GetEntityFlags(iclient);

	SetEntityFlags(iclient, entflags | FL_FAKECLIENT);
	SetEntProp(iclient, Prop_Send, "m_iTeamNum", 3);
	SetEntityFlags(iclient, entflags);
}

public void OnConfigsExecuted()
{
	cvarBossScale = FindConVar("tf_mvm_miniboss_scale");
	bSpawnFreeze = GetConVarBool(sm_red2robot_freeze);
	bBetweenUber = GetConVarBool(sm_red2robot_between_uber);
	bRestrictReady = GetConVarBool(sm_red2robot_restrict_ready);
	bFlagPickup = GetConVarBool(sm_red2robot_flag);
//	bNeedToRespawn = GetConVarBool(sm_red2robot_need_respawn);
	bSentryBusterDebug = GetConVarBool(sm_red2robot_sentrybuster_debug);
	bRespawnForm = GetConVarBool(sm_red2robot_respawn_form);
	bWearables = GetConVarBool(sm_red2robot_wearables);
	bAction = GetConVarBool(sm_red2robot_action);
}

stock int CreateParticle( float flOrigin[3], const char[] strParticle, float flDuration = -1.0 )
{
	int iParticle = CreateEntityByName( "info_particle_system" );
	if( IsValidEdict( iParticle ) )
	{
		DispatchKeyValue( iParticle, "effect_name", strParticle );
		DispatchSpawn( iParticle );
		TeleportEntity( iParticle, flOrigin, NULL_VECTOR, NULL_VECTOR );
		ActivateEntity( iParticle );
		AcceptEntityInput( iParticle, "Start" );
		if( flDuration >= 0.0 )
			CreateTimer( flDuration, Timer_DeleteParticle, EntIndexToEntRef(iParticle) );
	}
	return iParticle;
}

public Action Timer_DeleteParticle( Handle hTimer, any iEntRef )
{
	int iParticle = EntRefToEntIndex( iEntRef );
	if( IsValidEntity(iParticle) )
	{
		char strClassname[256];
		GetEdictClassname( iParticle, strClassname, sizeof(strClassname) );
		if( StrEqual( strClassname, "info_particle_system", false ) )
			AcceptEntityInput( iParticle, "Kill" );
	}
}

public void OnConVarChanged(Handle hConVar, const char[] strOldValue, const char[] strNewValue)
{
	OnConfigsExecuted();
}