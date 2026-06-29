#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <adminmenu>
#include <smlib>
#include <timer>
#include <timer-mapzones>
#include <timer-logging>
#include <timer-stocks>
#include <timer-config_loader.sp>

#undef REQUIRE_PLUGIN
#include <js_ljstats>
#include <timer-physics>
#include <timer-hide>
#include <timer-maptier>
#include <timer-teams>

new bool:g_timerPhysics = false;
new bool:g_timerTeams = false;
new bool:g_timerMapTier = false;
new bool:g_timerLjStats = false;

new g_ioffsCollisionGroup;

enum MapZoneEditor
{
	Step,
	Float:Point1[3],
	Float:Point2[3],
	Level_Id,
	MapZoneType:Type,
	String:Name[32]
}

new Handle:g_MapZoneDrawDelayTimer[2048];
new g_MapZoneEntityZID[2048];

/**
* Global Variables
*/
new Handle:g_hSQL;

new Handle:g_hFF;

new adminmode = 0;
new bool:g_bZonesLoaded = false;

new bool:g_bHurt[MAXPLAYERS+1] = {false, ...};
new bool:g_bZone[2048][MAXPLAYERS+1];

new Float:g_fCord_Old[MAXPLAYERS+1][3];
new Float:g_fCord_New[MAXPLAYERS+1][3];

new g_iIgnoreEndTouchStart[MAXPLAYERS+1];

new g_iTargetNPC[MAXPLAYERS+1];

new Handle:g_PreSpeedStart = INVALID_HANDLE;
new g_bPreSpeedStart = true;
new Handle:g_PreSpeedBonusStart = INVALID_HANDLE;
new g_bPreSpeedBonusStart = true;

new Handle:g_startMapZoneColor = INVALID_HANDLE;
new g_startColor[4] = { 0, 255, 255, 255 };

new Handle:g_endMapZoneColor = INVALID_HANDLE;
new g_endColor[4] = { 255, 0, 255, 255 };

new Handle:g_shortEndZoneColor = INVALID_HANDLE;
new g_shortendColor[4] = { 255, 99, 25, 255 };

new Handle:g_endBonusZoneColor = INVALID_HANDLE;
new g_bonusendColor[4] = { 255, 165, 0, 255 };

new Handle:g_startBonusZoneColor = INVALID_HANDLE;
new g_bonusstartColor[4] = { 255, 0, 0, 255 };

new Handle:g_glitch1ZoneColor = INVALID_HANDLE;
new g_stopColor[4] = { 138, 0, 180, 255 };

new Handle:g_glitch2ZoneColor = INVALID_HANDLE;
new g_restartColor[4] = { 255, 0, 0, 255 };

new Handle:g_glitch3ZoneColor = INVALID_HANDLE;
new g_telelastColor[4] = { 255, 255, 0, 255 };

new Handle:g_glitch4ZoneColor = INVALID_HANDLE;
new g_telenextColor[4] = { 0, 255, 255, 255 };

new Handle:g_levelZoneColor = INVALID_HANDLE;
new g_levelColor[4] = { 0, 255, 0, 255 };

new Handle:g_bonusLevelZoneColor = INVALID_HANDLE;
new g_bonuslevelColor[4] = { 0, 0, 255, 255 };

new Handle:g_freeStyleZoneColor = INVALID_HANDLE;
new g_freeStyleColor[4] = { 20, 20, 255, 200 };

new Handle:Sound_TeleLast = INVALID_HANDLE;
new String:SND_TELE_LAST[MAX_FILE_LEN];
new Handle:Sound_TeleNext = INVALID_HANDLE;
new String:SND_TELE_NEXT[MAX_FILE_LEN];
new Handle:Sound_TimerStart = INVALID_HANDLE;
new String:SND_TIMER_START[MAX_FILE_LEN];

new String:g_currentMap[64];
new g_reconnectCounter = 0;

new g_mapZones[128][MapZone];
new g_mapZonesCount = 0;

new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:oMapZoneMenu;

new g_mapZoneEditors[MAXPLAYERS+1][MapZoneEditor];

new precache_laser;

new g_clientLevel[MAXPLAYERS+1]=0;

new Handle:g_OnClientStartTouchZoneType;
new Handle:g_OnClientEndTouchZoneType;

new Handle:g_OnClientStartTouchLevel;
new Handle:g_OnClientStartTouchBonusLevel;

public Plugin:myinfo =
{
	name        = "[Timer] MapZones",
	author      = "Zipcore, Credits: Alongub",
	description = "[Timer] MapZones manager with trigger_multiple hooks",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-mapzones");
	CreateNative("Timer_GetClientLevel", Native_GetClientLevel);
	CreateNative("Timer_GetClientLevelID", Native_GetClientLevelID);
	CreateNative("Timer_GetLevelName", Native_GetLevelName);
	CreateNative("Timer_SetClientLevel", Native_SetClientLevel);
	CreateNative("Timer_SetIgnoreEndTouchStart", Native_SetIgnoreEndTouchStart);
	CreateNative("Timer_IsPlayerTouchingZoneType", Native_IsPlayerTouchingZoneType);
	CreateNative("Timer_GetMapzoneCount", Native_GetMapzoneCount);
	CreateNative("Timer_ClientTeleportLevel", Native_ClientTeleportLevel);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	g_hFF = FindConVar("mp_friendlyfire");

	g_timerPhysics = LibraryExists("timer-physics");
	g_timerTeams = LibraryExists("timer-teams");
	g_timerMapTier = LibraryExists("timer-maptier");
	g_timerLjStats = LibraryExists("timer-ljstats");
	
	FindCollisionGroup();
	
	g_PreSpeedStart = CreateConVar("timer_prespeed_start", "1", "Enable prespeed limit for start zone.", _, true, 0.0, true, 1.0);
	g_PreSpeedBonusStart = CreateConVar("timer_prespeed_bonusstart", "1", "Enable prespeed limit for bonus start zone.", _, true, 0.0, true, 1.0);
	
	g_startMapZoneColor = CreateConVar("timer_startcolor", "0 255 0 255", "The color of the start map zone.");
	g_endMapZoneColor = CreateConVar("timer_endcolor", "255 0 0 255", "The color of the end map zone.");
	g_startBonusZoneColor = CreateConVar("timer_startbonuscolor", "0 0 255 255", "The color of the start bonus zone.");
	g_endBonusZoneColor = CreateConVar("timer_endbonuscolor", "138 0 184 255", "The color of the end bonus zone.");
	g_glitch1ZoneColor = CreateConVar("timer_glitch1color", "138 0 180 255", "The color of the glitch1 zone.");
	g_glitch2ZoneColor = CreateConVar("timer_glitch2color", "255 0 0 255", "The color of the glitch2 zone.");
	g_glitch3ZoneColor = CreateConVar("timer_glitch3color", "255 255 0 255", "The color of the glitch3 zone.");
	g_glitch4ZoneColor = CreateConVar("timer_glitch4color", "0 255 255 255", "The color of the glitch4 zone.");
	g_levelZoneColor = CreateConVar("timer_levelcolor", "0 255 0 0", "The color of the level zone.");
	g_bonusLevelZoneColor = CreateConVar("timer_bonuslevelcolor", "0 0 255 0", "The color of the bonus level zone.");
	g_shortEndZoneColor = CreateConVar("timer_shortendcolor", "255 99 25 255", "The color of the short end zone.");
	g_freeStyleZoneColor = CreateConVar("timer_freestylecolor", "20 20 255 200", "The color of the short end zone.");
	
	Sound_TeleLast = CreateConVar("timer_sound_tele_last", "ui/freeze_cam.wav", "");
	Sound_TeleNext = CreateConVar("timer_sound_tele_next", "ui/freeze_cam.wav", "");
	Sound_TimerStart = CreateConVar("timer_sound_start", "ui/freeze_cam.wav", "");
	
	HookConVarChange(g_PreSpeedStart, Action_OnSettingsChange);
	HookConVarChange(g_PreSpeedBonusStart, Action_OnSettingsChange);
	
	HookConVarChange(g_startMapZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_endMapZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_startBonusZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_endBonusZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_glitch1ZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_glitch2ZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_glitch3ZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_glitch4ZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_levelZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_bonusLevelZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_shortEndZoneColor, Action_OnSettingsChange);
	
	HookConVarChange(Sound_TeleLast, Action_OnSettingsChange);
	HookConVarChange(Sound_TeleNext, Action_OnSettingsChange);
	HookConVarChange(Sound_TimerStart, Action_OnSettingsChange);
	
	AutoExecConfig(true, "timer/timer-mapzones");
	
	LoadTranslations("timer.phrases");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	RegAdminCmd("sm_zoneadminmode", Command_LevelAdminMode, ADMFLAG_RCON);
	RegAdminCmd("sm_zonename", Command_LevelName, ADMFLAG_RCON);
	RegAdminCmd("sm_zoneid", Command_LevelID, ADMFLAG_RCON);
	RegAdminCmd("sm_zonetype", Command_LevelType, ADMFLAG_RCON);
	RegAdminCmd("sm_zonereload", Command_ReloadZones, ADMFLAG_SLAY);
	RegAdminCmd("sm_npc_next", Command_NPC_Next, ADMFLAG_RCON);
	RegAdminCmd("sm_zone", Command_AdminZone, ADMFLAG_ROOT);
	
	RegConsoleCmd("sm_levels", Command_Levels);
	RegConsoleCmd("sm_stage", Command_Levels);
	
	if(g_Settings[RestartEnable])
	{
		RegConsoleCmd("sm_restart", Command_Restart);
		RegConsoleCmd("sm_r", Command_Restart);
	}
	
	if(g_Settings[StartEnable])
	{
		RegConsoleCmd("sm_start", Command_Start);
		RegConsoleCmd("sm_s", Command_Start);
		
		RegConsoleCmd("sm_bonusrestart", Command_BonusRestart);
		RegConsoleCmd("sm_bonusstart", Command_BonusRestart);
		RegConsoleCmd("sm_br", Command_BonusRestart);
		RegConsoleCmd("sm_b", Command_BonusRestart);
	}
	
	if(g_Settings[StuckEnable]) RegConsoleCmd("sm_stuck", Command_Stuck);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	AddNormalSoundHook(Hook_NormalSound);
	
	g_ioffsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	g_OnClientStartTouchZoneType = CreateGlobalForward("OnClientStartTouchZoneType", ET_Event, Param_Cell,Param_Cell);
	g_OnClientEndTouchZoneType = CreateGlobalForward("OnClientEndTouchZoneType", ET_Event, Param_Cell,Param_Cell);
	
	g_OnClientStartTouchLevel = CreateGlobalForward("OnClientStartTouchLevel", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_OnClientStartTouchBonusLevel = CreateGlobalForward("OnClientStartTouchBonusLevel", ET_Event, Param_Cell, Param_Cell, Param_Cell);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		g_timerTeams = true;
	}
	else if (StrEqual(name, "timer-maptier"))
	{
		g_timerMapTier = true;
	}
	else if (StrEqual(name, "timer-ljstats"))
	{
		g_timerLjStats = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		g_timerTeams = false;
	}
	else if (StrEqual(name, "timer-maptier"))
	{
		g_timerMapTier = false;
	}
	else if (StrEqual(name, "timer-ljstats"))
	{
		g_timerLjStats = false;
	}
	else if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public OnGameFrame()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))
			continue;
		
		if(!IsPlayerAlive(client))
			continue;
		
		if(IsClientSourceTV(client))
			continue;
		
		g_fCord_Old[client][0] = g_fCord_New[client][0];
		g_fCord_Old[client][1] = g_fCord_New[client][1];
		g_fCord_Old[client][2] = g_fCord_New[client][2];
		
		GetClientAbsOrigin(client, g_fCord_New[client]);
	}
}

public OnTimerStarted(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetClientHealth(client) < g_Physics[Timer_GetMode(client)][ModeSpawnHealth])
		{
			SetEntityHealth(client, g_Physics[Timer_GetMode(client)][ModeSpawnHealth]);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_mapZoneEditors[client][Step] == 0)
		return Plugin_Continue;
	
	if (!IsPlayerAlive(client) || IsClientSourceTV(client))
		return Plugin_Continue;

	if (buttons & IN_ATTACK2)
	{
		if (g_mapZoneEditors[client][Step] == 1)
		{
			new Float:vec[3];			
			GetClientAbsOrigin(client, vec);
			g_mapZoneEditors[client][Point1] = vec;
			DisplayPleaseWaitMenu(client);
			CreateTimer(1.0, ChangeStep, GetClientSerial(client));
			return Plugin_Handled;
		}
		else if (g_mapZoneEditors[client][Step] == 2)
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			g_mapZoneEditors[client][Point2] = vec;
			g_mapZoneEditors[client][Step] = 3;
			DisplaySelectZoneTypeMenu(client, 0);
			
			return Plugin_Handled;
		}		
	}
	
	return Plugin_Continue;
}

//public Action:StartTouchTrigger(caller, activator)
public Action:OnTouchTrigger(caller, activator)
{
	if(!g_bZonesLoaded)
		return;
	
	if(g_mapZonesCount < 1)
		return;
	
	if (activator < 1 || activator > MaxClients)
	{
		return;
	}
	
	if (!IsClientInGame(activator))
	{
		return;
	}
	
	if (!IsPlayerAlive(activator))
	{
		return;
	}
	
	new client = activator;
	
	ChangePlayerVelocity(client);
}

//public Action:StartTouchTrigger(caller, activator)
public Action:StartTouchTrigger(caller, activator)
{
	if(!g_bZonesLoaded)
		return;
	if(g_mapZonesCount < 1)
		return;
	
	if (activator < 1 || activator > MaxClients)
	{
		return;
	}
	
	if (!IsClientInGame(activator))
	{
		return;
	}
	
	if (!IsPlayerAlive(activator))
	{
		return;
	}
	
	new client = activator;
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	new mate;
	if(g_timerTeams) mate = Timer_GetClientTeammate(client);
	
	new zone = g_MapZoneEntityZID[caller];
	
	if(zone < 0)
		return;
	
	decl String:TriggerName[32]; 
	GetEntPropString(caller, Prop_Data, "m_iName", TriggerName, sizeof(TriggerName));
	
	if(adminmode == 1 && Client_IsAdmin(client))
	{
		if(GetGameMod() == MOD_CSGO)
		{
			PrintHintText(client, "ID: %d", zone);
		}
		else 
		{
			PrintCenterText(client, "ID: %d", zone);
			DrawZone(zone, false);
		}
		return;
	}
	
	Call_StartForward(g_OnClientStartTouchZoneType);
	Call_PushCell(client);
	Call_PushCell(g_mapZones[zone][Type]);
	Call_Finish();
	
	g_bZone[zone][client] = true;
	
	if (g_mapZones[zone][Type] == ZtReset)
	{
		Timer_Reset(client);
	}
	else if (g_mapZones[zone][Type] == ZtStart)
	{
		if(!g_Settings[NoblockEnable])
			SetPush(client);
		
		if(mate == 0)
		{
			g_iIgnoreEndTouchStart[client] = false;
			g_clientLevel[client] = zone;
			
			Timer_Stop(client, false);
			Timer_SetBonus(client, 0);
		}
	}
	else if (g_mapZones[zone][Type] == ZtBonusStart)
	{
		g_iIgnoreEndTouchStart[client] = false;
		g_clientLevel[client] = zone;
		
		Timer_Stop(client, false);
		Timer_SetBonus(client, 1);
		
		if(g_timerLjStats) SetLJMode(client, false);
	}
	else if (g_mapZones[zone][Type] == ZtEnd)
	{
		if(!g_Settings[NoblockEnable])
			SetPush(client);
		
		if(mate == 0)
		{
			//has player noclip?
			if(GetEntProp(client, Prop_Send, "movetype", 1) == 8)
			{
				Timer_Stop(client, false);
			}
			else if(Timer_GetBonus(client) == 0)
			{
				g_clientLevel[client] = zone;
				
				if (Timer_Stop(client, false))
				{
					new bool:enabled = false;
					new jumps = 0;
					new Float:time;
					new fpsmax;
					
					if (Timer_GetClientTimer(client, enabled, time, jumps, fpsmax))
					{
						new difficulty = 0;
						if (g_timerPhysics)
							difficulty = Timer_GetMode(client);
						
						Timer_FinishRound(client, g_currentMap, time, jumps, difficulty, fpsmax, 0);
					}
				}
			}
		}
	}
	else if (g_mapZones[zone][Type] == ZtShortEnd)
	{
		if(mate == 0)
		{
			//has player noclip?
			if(GetEntProp(client, Prop_Send, "movetype", 1) == 8)
			{
				Timer_Stop(client, false);
			}
			else if(Timer_GetBonus(client) == 0)
			{
				g_clientLevel[client] = zone;
				
				new bool:enabled = false;
				new jumps = 0;
				new Float:time;
				new fpsmax;
				
				if (Timer_GetClientTimer(client, enabled, time, jumps, fpsmax))
				{
					new mode = 0;
					if (g_timerPhysics)
						mode = Timer_GetMode(client);
					
					Timer_FinishRound(client, g_currentMap, time, jumps, mode, fpsmax, 2);
				}
			}
		}
	}
	else if (g_mapZones[zone][Type] == ZtBonusEnd)
	{
		if(mate == 0)
		{
			//has player noclip?
			if(GetEntProp(client, Prop_Send, "movetype", 1) == 8)
			{
				Timer_Stop(client, false);
			}
			else if(Timer_GetBonus(client) == 1)
			{
				g_clientLevel[client] = zone;
				
				if (Timer_Stop(client, false))
				{
					new bool:enabled = false;
					new jumps = 0;
					new Float:time;
					new fpsmax;
					
					if (Timer_GetClientTimer(client, enabled, time, jumps, fpsmax))
					{
						new difficulty = 0;
						if (g_timerPhysics)
							difficulty = Timer_GetMode(client);
						
						Timer_FinishRound(client, g_currentMap, time, jumps, difficulty, fpsmax, 1);
					}
				}
			}
		}
	}
	else if (g_mapZones[zone][Type] == ZtStop)
	{
		Timer_Stop(client, true);
	}
	else if (g_mapZones[zone][Type] == ZtRestart)
	{
		if(Timer_GetBonus(client) == 1) 
		{
			Tele_Level(client, 1001);
		}
		else
		{
			Tele_Level(client, 1);
		}
	}
	else if (g_mapZones[zone][Type] == ZtRestartNormalTimer)
	{
		if(Timer_GetBonus(client) == 0) 
		{
			Tele_Level(client, 1);
		}
	}
	else if (g_mapZones[zone][Type] == ZtRestartBonusTimer)
	{
		if(Timer_GetBonus(client) == 1) 
		{
			Tele_Level(client, 1001);
		}
	}
	else if (g_mapZones[zone][Type] == ZtLast)
	{
		new lowestcheckpoint = g_mapZones[g_clientLevel[client]][Level_Id];
		
		if(0 < mate && IsClientInGame(mate) && IsPlayerAlive(mate)) 
		{
			if(g_clientLevel[client] > g_clientLevel[mate]) lowestcheckpoint = g_mapZones[g_clientLevel[mate]][Level_Id];
			
			Tele_Level(client, lowestcheckpoint);
			Tele_Level(mate, lowestcheckpoint);
			
			if(Client_IsValid(client, true)) EmitSoundToClient(client, SND_TELE_LAST);
			if(Client_IsValid(mate, true)) EmitSoundToClient(mate, SND_TELE_LAST);
		}
		else
		{
			if(Client_IsValid(client, true)) EmitSoundToClient(client, SND_TELE_LAST);
			Tele_Level(client, lowestcheckpoint);
		}
	}
	else if (g_mapZones[zone][Type] == ZtNext)
	{
		if(0 < mate && IsClientInGame(mate) && IsPlayerAlive(mate) && g_mapZones[g_clientLevel[client]][Level_Id] == g_mapZones[g_clientLevel[mate]][Level_Id])
		{
			Tele_Level(client, g_mapZones[g_clientLevel[client]][Level_Id]+1);
			Tele_Level(mate, g_mapZones[g_clientLevel[client]][Level_Id]+1);
			if(Client_IsValid(client, true)) EmitSoundToClient(client, SND_TELE_NEXT);
			if(Client_IsValid(mate, true)) EmitSoundToClient(mate, SND_TELE_NEXT);
		}
		else
		{
			Tele_Level(client, g_mapZones[g_clientLevel[client]][Level_Id]+1);
			if(Client_IsValid(client, true)) EmitSoundToClient(client, SND_TELE_NEXT);
		}
		
	}
	else if (g_mapZones[zone][Type] == ZtLevel)
	{
		if(Timer_GetBonus(client) == 0)
		{
			new lastlevel = g_mapZones[g_clientLevel[client]][Level_Id];
			g_clientLevel[client] = zone;
			
			Call_StartForward(g_OnClientStartTouchLevel);
			Call_PushCell(client);
			Call_PushCell(g_mapZones[g_clientLevel[client]][Level_Id]);
			Call_PushCell(lastlevel);
			Call_Finish();
		}
	}
	else if (g_mapZones[zone][Type] == ZtBonusLevel)
	{
		if(Timer_GetBonus(client) == 1)
		{
			new lastlevel = g_mapZones[g_clientLevel[client]][Level_Id];
			g_clientLevel[client] = zone;
			
			Call_StartForward(g_OnClientStartTouchBonusLevel);
			Call_PushCell(client);
			Call_PushCell(g_mapZones[g_clientLevel[client]][Level_Id]);
			Call_PushCell(lastlevel);
			Call_Finish();
		}
	}
	else if (g_mapZones[zone][Type] == ZtBlock)
	{
		if(g_Settings[NoblockEnable])
			SetBlock(client);
		else SetNoBlock(client);
	}
	else if (g_mapZones[zone][Type] == ZtPlayerClip)
	{
		CheckVelocity(client, 0, 10000.0);
	}
	else if (g_mapZones[zone][Type] == ZtLongjump)
	{
		if(g_timerLjStats) SetLJMode(client, true);
	}
	else if (g_mapZones[zone][Type] == ZtBooster)
	{
		CheckVelocity(client, 3, 10000.0);
	}
	else if (g_mapZones[zone][Type] == ZtArena)
	{
		g_bHurt[client] = true;
	}
	else if (g_mapZones[zone][Type] == ZtBounceBack)
	{
		CheckVelocity(client, 2, 10000.0);
	}
	else if (g_mapZones[zone][Type] == ZtJail)
	{
		g_bHurt[client] = true;
	}
	else if (g_mapZones[zone][Type] == ZtBulletTime)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.7);
	}
	
	DrawZone(zone, true);
	
	return;
}

//public Action:EndTouchTrigger(caller, activator)
public Action:EndTouchTrigger(caller, activator)
{
	if(!g_bZonesLoaded)
		return;
	if(g_mapZonesCount < 1)
		return;
	
	if (activator < 1 || activator > MaxClients)
	{
		return;
	}
	
	if (!IsClientInGame(activator))
	{
		return;
	}
	
	if (!IsPlayerAlive(activator))
	{
		return;
	}
	
	new client = activator;
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	new mate;
	if(g_timerTeams) mate = Timer_GetClientTeammate(client);
	
	new zone = g_MapZoneEntityZID[caller];
	
	if(zone < 0)
		return;
	
	decl String:TriggerName[32]; 
	GetEntPropString(caller, Prop_Data, "m_iName", TriggerName, sizeof(TriggerName));
	
	if(adminmode == 1 && Client_IsAdmin(client))
	{
		if(GetGameMod() == MOD_CSGO)
		{
			PrintHintText(client, "ID: %d", zone);
		}
		else PrintCenterText(client, "ID: %d", zone);
		return;
	}
	
	g_bZone[zone][client] = false;
	
	Call_StartForward(g_OnClientEndTouchZoneType);
	Call_PushCell(client);
	Call_PushCell(g_mapZones[zone][Type]);
	Call_Finish();
	
	if(Timer_GetForceMode() && !Timer_GetPickedMode(client))
	{
		FakeClientCommand(client, "sm_restart");
		FakeClientCommand(client, "sm_style");
		CPrintToChat(client, PLUGIN_PREFIX, "Force Mode");
	}
	
	if(g_mapZones[zone][Type] == ZtEnd)
	{
		if(!g_Settings[NoblockEnable])
			SetBlock(client);
	}
	else if(g_mapZones[zone][Type] == ZtStart)
	{
		if(!g_Settings[NoblockEnable])
			SetBlock(client);
		
		if(mate == 0 && CheckIllegalTeleport(client))
		{
			if(Timer_IsPlayerTouchingZoneType(client, ZtStop))
				return;
			
			if(GetEntProp(client, Prop_Send, "movetype", 1) == 8)
				return;
			
			if(g_iIgnoreEndTouchStart[client])
			{
				g_iIgnoreEndTouchStart[client] = false;
				return;
			}
			
			if(IsClientConnected(client))
				EmitSoundToClient(client, SND_TIMER_START);
			
			Timer_Restart(client);
			Timer_SetBonus(client, 0);
		}
	}
	else if(g_mapZones[zone][Type] == ZtBonusStart)
	{
		if(Timer_IsPlayerTouchingZoneType(client, ZtStop) || !CheckIllegalTeleport(client))
			return;
		
		if(GetEntProp(client, Prop_Send, "movetype", 1) == 8)
			return;
		
		if(g_iIgnoreEndTouchStart[client])
		{
			g_iIgnoreEndTouchStart[client] = false;
			return;
		}
		if(IsClientConnected(client)) EmitSoundToClient(client, SND_TIMER_START);
		Timer_Restart(client);
		Timer_SetBonus(client, 1);
	}
	else if (g_mapZones[zone][Type] == ZtBlock)
	{
		if(g_Settings[NoblockEnable])
			SetNoBlock(client);
		else SetBlock(client);
	}
	else if (g_mapZones[zone][Type] == ZtLongjump)
	{
		if(g_timerLjStats) SetLJMode(client, false);
	}
	else if (g_mapZones[zone][Type] == ZtArena)
	{
		g_bHurt[client] = false;
	}
	else if (g_mapZones[zone][Type] == ZtJail)
	{
		Tele_Zone(client, zone);
		g_bHurt[client] = false;
	}
	else if (g_mapZones[zone][Type] == ZtBulletTime)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
	
	return;
}  

public Action:NPC_Use(caller, activator)
{
	decl Float:camangle[3], Float:vecClient[3], Float:vecCaller[3];
	
	decl Float:vec[3];
	Entity_GetAbsOrigin(caller, vecCaller);
	GetClientAbsOrigin(activator, vecClient);   
	
	MakeVectorFromPoints(vecCaller, vecClient, vec);
	GetVectorAngles(vec, camangle);
	camangle[0] = 0.0;
	//camangle[1] = 0.0;
	camangle[2] = 0.0;
	
	TeleportEntity(caller, NULL_VECTOR, camangle, NULL_VECTOR);
	
	for (new i = 0; i < g_mapZonesCount; i++)
	{
		if(g_mapZones[i][NPC] == caller)
		{
			g_clientLevel[activator] = i;
			
			Menu_NPC_Next(activator, i);
			
			break;
		}
	}
	
	SetEntData(caller, g_ioffsCollisionGroup, 17, 4, true);
	CreateTimer(0.5, SetBlockable, caller, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public OnConfigsExecuted()
{
	CacheSounds();
}

public CacheSounds()
{
	GetConVarString(Sound_TeleLast, SND_TELE_LAST, sizeof(SND_TELE_LAST));
	PrepareSound(SND_TELE_LAST);
	
	GetConVarString(Sound_TeleNext, SND_TELE_NEXT, sizeof(SND_TELE_NEXT));
	PrepareSound(SND_TELE_NEXT);
	
	GetConVarString(Sound_TimerStart, SND_TIMER_START, sizeof(SND_TIMER_START));
	PrepareSound(SND_TIMER_START);
}

public PrepareSound(String: sound[MAX_FILE_LEN])
{
	decl String:fileSound[MAX_FILE_LEN];
	
	FormatEx(fileSound, MAX_FILE_LEN, "sound/%s", sound);
	
	if (FileExists(fileSound))
	{
		PrecacheSound(sound, true);
		AddFileToDownloadsTable(fileSound);
	}
	else
	{
		PrintToServer("[Timer] ERROR: File '%s' not found!", fileSound);
	}
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	if(g_Settings[TerminateRoundEnd]) ServerCommand("mp_ignore_round_win_conditions 1");
	else ServerCommand("mp_ignore_round_win_conditions 0");
	
	g_bZonesLoaded = false;
	adminmode = 0;
	
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	ConnectSQL();
	
	CreateTimer(1.0, DrawZones, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(4.0, CheckEntitysLoaded, _, TIMER_FLAG_NO_MAPCHANGE);
	
	precache_laser = PrecacheModel("materials/sprites/laserbeam.vmt");
	
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		g_clientLevel[i] = 0;
	}
	
	PrecacheModel("models/props_junk/wood_crate001a.mdl", true);
}

public Action:CheckEntitysLoaded(Handle:timer)
{
	if(GetZoneEntityCount() < g_mapZonesCount)
	{
		if (g_hSQL != INVALID_HANDLE)
		{
			Timer_LogInfo("No mapzone entitys spawned, reloading...");
			LoadMapZones();
		}
		
		CreateTimer(4.0, CheckEntitysLoaded, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

public OnClientDisconnect_Post(client)
{
	g_bHurt[client] = false;
	g_iIgnoreEndTouchStart[client] = 0;
	g_iTargetNPC[client] = 0;
	Timer_Resume(client);
	Timer_Stop(client, false);
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if(g_Settings[TerminateRoundEnd])
		return Plugin_Handled;
	else
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (g_hSQL != INVALID_HANDLE)
		LoadMapZones();
	else 
		ConnectSQL();
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_clientLevel[client] = 0;
	g_bHurt[client] = false;
	g_iIgnoreEndTouchStart[client] = 0;
	g_iTargetNPC[client] = 0;
	Timer_Resume(client);
	Timer_Stop(client, false);
	
	for (new i = 0; i < 127; i++)
	{
		g_bZone[i][client] = false;
	}
	
	if(g_Settings[TeleportOnSpawn])
	{
		FakeClientCommand(client, "sm_restart");
	}
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_Settings[TeleportOnSpawn]) Tele_Level(client, 1);
		
		if(g_Settings[NoblockEnable])
			SetNoBlock(client);
		else SetBlock(client);
	}
}


public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == g_startMapZoneColor)
		ParseColor(newvalue, g_startColor);
	else if (cvar == g_endMapZoneColor)
		ParseColor(newvalue, g_endColor);
	else if (cvar == g_startBonusZoneColor)
		ParseColor(newvalue, g_bonusstartColor);
	else if (cvar == g_endBonusZoneColor)
		ParseColor(newvalue, g_bonusendColor);
	else if (cvar == g_glitch1ZoneColor)
		ParseColor(newvalue, g_stopColor);
	else if (cvar == g_glitch2ZoneColor)
		ParseColor(newvalue, g_restartColor);
	else if (cvar == g_glitch3ZoneColor)
		ParseColor(newvalue, g_telelastColor);
	else if (cvar == g_glitch4ZoneColor)
		ParseColor(newvalue, g_telenextColor);
	else if (cvar == g_levelZoneColor)
		ParseColor(newvalue, g_levelColor);
	else if (cvar == g_bonusLevelZoneColor)
		ParseColor(newvalue, g_bonuslevelColor);
	else if (cvar == g_shortEndZoneColor)
		ParseColor(newvalue, g_shortendColor);
	else if (cvar == g_freeStyleZoneColor)
		ParseColor(newvalue, g_freeStyleColor);
	else if (cvar == Sound_TeleLast)
		FormatEx(SND_TELE_LAST, sizeof(SND_TELE_LAST) ,"%s", newvalue);
	else if (cvar == Sound_TeleNext)
		FormatEx(SND_TELE_NEXT, sizeof(SND_TELE_NEXT) ,"%s", newvalue);
	else if (cvar == Sound_TimerStart)
		FormatEx(SND_TIMER_START, sizeof(SND_TIMER_START) ,"%s", newvalue);
	else if (cvar == g_PreSpeedStart)
		g_bPreSpeedStart = GetConVarBool(g_PreSpeedStart);
	else if (cvar == g_PreSpeedBonusStart)
		g_bPreSpeedBonusStart = GetConVarBool(g_PreSpeedBonusStart);
}

AddMapZone(String:map[], MapZoneType:type, String:name[], level_id, Float:point1[3], Float:point2[3])
{
	decl String:query[512];
	
	if ((type == ZtStart && !g_Settings[AllowMultipleStart])
	|| (type == ZtEnd && !g_Settings[AllowMultipleEnd])
	|| (type == ZtBonusStart && !g_Settings[AllowMultipleBonusStart]
	|| (type == ZtBonusEnd && !g_Settings[AllowMultipleBonusEnd])
	|| (type == ZtShortEnd) && !g_Settings[AllowMultipleShortEnd]))
	{
		decl String:deleteQuery[256];
		FormatEx(deleteQuery, sizeof(deleteQuery), "DELETE FROM mapzone WHERE map = '%s' AND type = %d;", map, type);
		
		SQL_TQuery(g_hSQL, MapZoneChangedCallback, deleteQuery, _, DBPrio_High);	
	}
	
	//add new zone
	FormatEx(query, sizeof(query), "INSERT INTO mapzone (map, type, name, level_id, point1_x, point1_y, point1_z, point2_x, point2_y, point2_z) VALUES ('%s','%d','%s','%d', %f, %f, %f, %f, %f, %f);", map, type, name, level_id, point1[0], point1[1], point1[2], point2[0], point2[1], point2[2]);
	
	SQL_TQuery(g_hSQL, MapZoneChangedCallback, query, _, DBPrio_Normal);	
}

public MapZoneChangedCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on AddMapZone: %s", error);
		return;
	}
	
	if(g_timerMapTier)
	{
		Timer_UpdateStageCount(0);
		Timer_UpdateStageCount(1);
	}
	
	LoadMapZones();
}

bool:LoadMapZones()
{
	if (g_hSQL != INVALID_HANDLE)
	{
		decl String:query[512];
		FormatEx(query, sizeof(query), "SELECT * FROM mapzone WHERE map = '%s' ORDER BY level_id ASC;", g_currentMap);
		SQL_TQuery(g_hSQL, LoadMapZonesCallback, query, _, DBPrio_High);
		
		return true;
	}
	
	return false;
}


public LoadMapZonesCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	g_bZonesLoaded = false;
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on LoadMapZones: %s", error);
		return;
	}
	
	g_mapZonesCount = 0;
	DeleteAllZoneEntitys();
	
	while (SQL_FetchRow(hndl))
	{
		strcopy(g_mapZones[g_mapZonesCount][Map], 64, g_currentMap);
		
		g_mapZones[g_mapZonesCount][Id] = SQL_FetchInt(hndl, 0);
		g_mapZones[g_mapZonesCount][Type] = MapZoneType:SQL_FetchInt(hndl, 1);
		g_mapZones[g_mapZonesCount][Level_Id] = SQL_FetchInt(hndl, 2);
		
		g_mapZones[g_mapZonesCount][Point1][0] = SQL_FetchFloat(hndl, 3);
		g_mapZones[g_mapZonesCount][Point1][1] = SQL_FetchFloat(hndl, 4);
		g_mapZones[g_mapZonesCount][Point1][2] = SQL_FetchFloat(hndl, 5);
		
		g_mapZones[g_mapZonesCount][Point2][0] = SQL_FetchFloat(hndl, 6);
		g_mapZones[g_mapZonesCount][Point2][1] = SQL_FetchFloat(hndl, 7);
		g_mapZones[g_mapZonesCount][Point2][2] = SQL_FetchFloat(hndl, 8);
		
		decl String:ZoneName[32];
		SQL_FetchString(hndl, 10, ZoneName, sizeof(ZoneName));
		FormatEx(g_mapZones[g_mapZonesCount][zName], 32, "%s", ZoneName);
		
		SpawnZoneEntitys(g_mapZonesCount);
		
		g_mapZonesCount++;
	}
	
	g_bZonesLoaded = true;
}

ConnectSQL()
{
	if (g_hSQL != INVALID_HANDLE)
	{
		CloseHandle(g_hSQL);
	}
	
	g_hSQL = INVALID_HANDLE;
	
	if (SQL_CheckConfig("timer"))
	{
		SQL_TConnect(ConnectSQLCallback, "timer");
	}
	else
	{
		SetFailState("PLUGIN STOPPED - Reason: no config entry found for 'timer' in databases.cfg - PLUGIN STOPPED");
	}
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (g_reconnectCounter >= 5)
	{
		SetFailState("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("Connection to SQL database has failed, Reason: %s", error);
		
		g_reconnectCounter++;
		ConnectSQL();
		
		return;
	}
	
	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));
	
	g_hSQL = CloneHandle(hndl);
	
	if (StrEqual(driver, "mysql", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `mapzone` (`id` int(11) NOT NULL AUTO_INCREMENT, `type` int(11) NOT NULL, `level_id` int(11) NOT NULL, `point1_x` float NOT NULL, `point1_y` float NOT NULL, `point1_z` float NOT NULL, `point2_x` float NOT NULL, `point2_y` float NOT NULL, `point2_z` float NOT NULL, `map` varchar(64) NOT NULL, `name` varchar(32) NOT NULL, PRIMARY KEY (`id`));");
	}
	else if (StrEqual(driver, "sqlite", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `mapzone` (`id` INTEGER PRIMARY KEY, `type` INTEGER NOT NULL, `level_id` INTEGER NOT NULL, `point1_x` float NOT NULL, `point1_y` float NOT NULL, `point1_z` float NOT NULL, `point2_x` float NOT NULL, `point2_y` float NOT NULL, `point2_z` float NOT NULL, `map` varchar(32) NOT NULL, `name` varchar(32) NOT NULL);");
	}
	
	g_reconnectCounter = 1;
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError(error);
		
		g_reconnectCounter++;
		ConnectSQL();
		
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateSQLTable: %s", error);
		return;
	}
	
	LoadMapZones();
}

public OnAdminMenuReady(Handle:topmenu)
{
	// Block this from being called twice
	if (topmenu == hTopMenu) {
		return;
	}
	
	// Save the Handle
	hTopMenu = topmenu;
	
	if ((oMapZoneMenu = FindTopMenuCategory(topmenu, "Timer Zones")) == INVALID_TOPMENUOBJECT)
	{
		oMapZoneMenu = AddToTopMenu(hTopMenu,"Timer Zones",TopMenuObject_Category,AdminMenu_CategoryHandler,INVALID_TOPMENUOBJECT);
	}
	
	AddToTopMenu(hTopMenu, "timer_mapzones_add",TopMenuObject_Item,AdminMenu_AddMapZone,
	oMapZoneMenu,"timer_mapzones_add",ADMFLAG_RCON);
	
	AddToTopMenu(hTopMenu, "timer_mapzones_remove",TopMenuObject_Item,AdminMenu_RemoveMapZone,
	oMapZoneMenu,"timer_mapzones_remove",ADMFLAG_RCON);
	
	AddToTopMenu(hTopMenu, "timer_mapzones_remove_all",TopMenuObject_Item,AdminMenu_RemoveAllMapZones,
	oMapZoneMenu,"timer_mapzones_remove_all",ADMFLAG_RCON);
	
	AddToTopMenu(hTopMenu, "sm_npc_next",TopMenuObject_Item,AdminMenu_NPC,
	oMapZoneMenu,"sm_npc_next",ADMFLAG_RCON);
	
	AddToTopMenu(hTopMenu, "sm_zoneadminmode",TopMenuObject_Item,AdminMenu_AdminMode,
	oMapZoneMenu,"sm_zoneadminmode",ADMFLAG_CHANGEMAP);
	
	AddToTopMenu(hTopMenu, "sm_zonereload",TopMenuObject_Item,AdminMenu_Reload,
	oMapZoneMenu,"sm_zonereload",ADMFLAG_CHANGEMAP);
	
	AddToTopMenu(hTopMenu, "sm_zone",TopMenuObject_Item,AdminMenu_Teleport,
	oMapZoneMenu,"sm_zone",ADMFLAG_CHANGEMAP);
}

public AdminMenu_CategoryHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle) {
		FormatEx(buffer, maxlength, "Timer Zones");
	} else if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Timer Zones");
	}
}

public AdminMenu_AddMapZone(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Add Map Zone");
	} else if (action == TopMenuAction_SelectOption) {
		RestartMapZoneEditor(param);
		g_mapZoneEditors[param][Step] = 1;
		DisplaySelectPointMenu(param, 1);
	}
}

public AdminMenu_RemoveMapZone(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Delete Zone");
	} else if (action == TopMenuAction_SelectOption) {
		DeleteMapZone(param);
	}
}

public AdminMenu_RemoveAllMapZones(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Delete All Zones");
	} else if (action == TopMenuAction_SelectOption) 
	{
		if(param == 0)
			DeleteAllMapZones(param);
		else DeleteMapZonesMenu(param);
	}
}

public AdminMenu_NPC(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Create NPC Teleporter");
	} else if (action == TopMenuAction_SelectOption) 
	{
		CreateNPC(param, 0);
	}
}

public AdminMenu_AdminMode(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Toggle Admin Mode");
	} else if (action == TopMenuAction_SelectOption) 
	{
		if(adminmode == 0)
		{
			CPrintToChatAll("%s Adminmode enabled!", PLUGIN_PREFIX2);
			adminmode = 1;
		}
		else 
		{
			CPrintToChatAll("%s Adminmode disabled!", PLUGIN_PREFIX2);
			adminmode = 0;
		}
	}
}

public AdminMenu_Reload(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Zone Reload");
	} else if (action == TopMenuAction_SelectOption) 
	{
		CPrintToChatAll("%s Zones Reloaded!", PLUGIN_PREFIX2);
		LoadMapZones();
	}
}

public AdminMenu_Teleport(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Zone Teleport");
	} else if (action == TopMenuAction_SelectOption) 
	{
		AdminZoneTeleport(param);
	}
}

DeleteMapZonesMenu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_DeleteMapZonesMenu);
		
		SetMenuTitle(menu, "Are you sure!");
		
		AddMenuItem(menu, "no", "Oh no");		
		AddMenuItem(menu, "no", "Oh no");
		AddMenuItem(menu, "no", "Oh no");
		AddMenuItem(menu, "yes", "!!! YES DELETE ALL ZONES !!!");		
		AddMenuItem(menu, "no", "Oh no");
		AddMenuItem(menu, "no", "Oh no");
		AddMenuItem(menu, "no", "Oh no");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public Handle_DeleteMapZonesMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "yes"))
			{
				decl String:map[32];
				GetCurrentMap(map, sizeof(map));
				DeleteAllMapZones(client);
			}
		}
	}
}

RestartMapZoneEditor(client)
{
	g_mapZoneEditors[client][Step] = 0;
	
	for (new i = 0; i < 3; i++)
		g_mapZoneEditors[client][Point1][i] = 0.0;
	
	for (new i = 0; i < 3; i++)
		g_mapZoneEditors[client][Point1][i] = 0.0;		
}

DeleteMapZone(client)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	for (new zone = 0; zone < g_mapZonesCount; zone++)
	{
		if (IsInsideBox(vec, g_mapZones[zone][Point1][0], g_mapZones[zone][Point1][1], g_mapZones[zone][Point1][2], g_mapZones[zone][Point2][0], g_mapZones[zone][Point2][1], g_mapZones[zone][Point2][2]))
		{
			decl String:query[64];
			FormatEx(query, sizeof(query), "DELETE FROM mapzone WHERE id = %d", g_mapZones[zone][Id]);
			
			SQL_TQuery(g_hSQL, DeleteMapZoneCallback, query, client, DBPrio_Normal);	
			break;
		}
	}
}

DeleteAllMapZones(client)
{
	decl String:query[256];
	FormatEx(query, sizeof(query), "DELETE FROM mapzone WHERE map = '%s'", g_currentMap);
	
	SQL_TQuery(g_hSQL, DeleteMapZoneCallback, query, client, DBPrio_Normal);
}

public DeleteMapZoneCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeleteMapZone: %s", error);
		return;
	}
	
	LoadMapZones();
	
	if (IsClientInGame(data))
		CPrintToChat(data, PLUGIN_PREFIX, "Map Zone Delete");
}

DisplaySelectPointMenu(client, n)
{
	new Handle:panel = CreatePanel();
	
	decl String:message[255];
	decl String:first[32], String:second[32];
	FormatEx(first, sizeof(first), "%t", "FIRST");
	FormatEx(second, sizeof(second), "%t", "SECOND");
	
	FormatEx(message, sizeof(message), "%t", "Point Select Panel", (n == 1) ? first : second);
	
	DrawPanelItem(panel, message, ITEMDRAW_RAWLINE);
	
	FormatEx(message, sizeof(message), "%t", "Cancel");
	DrawPanelItem(panel, message);
	
	SendPanelToClient(panel, client, PointSelect, 540);
	CloseHandle(panel);
}

DisplayPleaseWaitMenu(client)
{
	new Handle:panel = CreatePanel();
	
	decl String:wait[64];
	FormatEx(wait, sizeof(wait), "%t", "Please wait");
	DrawPanelItem(panel, wait, ITEMDRAW_RAWLINE);
	
	SendPanelToClient(panel, client, PointSelect, 540);
	CloseHandle(panel);
}

public PointSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	} 
	else if (action == MenuAction_Select) 
	{
		if (param2 == MenuCancel_Exit && hTopMenu != INVALID_HANDLE) 
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
		
		RestartMapZoneEditor(param1);
	}
}

public Action:ChangeStep(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	g_mapZoneEditors[client][Step] = 2;
	CreateTimer(0.1, DrawAdminBox, GetClientSerial(client), TIMER_REPEAT);
	
	DisplaySelectPointMenu(client, 2);
}

DisplaySelectZoneTypeMenu(client, category)
{
	new Handle:menu = CreateMenu(ZoneTypeSelect);
	SetMenuTitle(menu, "%T", "Select zone type", client);
	
	if(category == 0)
	{
		AddMenuItem(menu, "cat_timer", "Timer");
		AddMenuItem(menu, "cat_timer_bonus", "Timer (Bonus)");
		AddMenuItem(menu, "cat_timer_other", "Timer (Other)");
		AddMenuItem(menu, "cat_physics", "Physics");
		AddMenuItem(menu, "cat_teleport", "Teleport");
		AddMenuItem(menu, "cat_control", "Control");
		AddMenuItem(menu, "cat_speed", "Speed");
		AddMenuItem(menu, "cat_other", "Other");
	}
	else if(category == 1)
	{
		AddMenuItem(menu, "level", "Level");
		AddMenuItem(menu, "start", "Start");
		AddMenuItem(menu, "end", "End");
		AddMenuItem(menu, "short_end", "Short End");
	}
	else if(category == 2)
	{
		AddMenuItem(menu, "bonuslevel", "Bonus Level");
		AddMenuItem(menu, "bonusstart", "Bonus Start");
		AddMenuItem(menu, "bonusend", "Bonus End");
	}
	else if(category == 3)
	{
		AddMenuItem(menu, "stop", "Stop");
		AddMenuItem(menu, "restart", "Restart");
		AddMenuItem(menu, "reset", "Reset");
		AddMenuItem(menu, "restart_normal", "Restart Normal Timer");
		AddMenuItem(menu, "restart_bonus", "Restart Bonus Timer");
	}
	else if(category == 4)
	{
		AddMenuItem(menu, "auto", "Enable Auto Bhop");
		AddMenuItem(menu, "noauto", "Disable Auto Bhop");
		AddMenuItem(menu, "nogravity", "No Gravity verwrite");
		AddMenuItem(menu, "noboost", "Disable Style Boost");
		AddMenuItem(menu, "block", "Toggle Noblock");
	}
	else if(category == 5)
	{
		AddMenuItem(menu, "last", "Teleport Last");
		AddMenuItem(menu, "next", "Teleport Next");
		AddMenuItem(menu, "npc_next", "NPC Teleporter");
		AddMenuItem(menu, "npc_next_double", "NPC Double Teleporter");
	}
	else if(category == 6)
	{
		AddMenuItem(menu, "freestyle", "Freestyle");
		AddMenuItem(menu, "up", "Push Up");
		AddMenuItem(menu, "down", "Push Down");
		AddMenuItem(menu, "north", "Push North");
		AddMenuItem(menu, "south", "Push South");
		AddMenuItem(menu, "east", "Push East");
		AddMenuItem(menu, "west", "Push West");
		AddMenuItem(menu, "hover", "Hover");
	}
	else if(category == 7)
	{
		AddMenuItem(menu, "limit", "Speed Limit");
		
		AddMenuItem(menu, "booster", "Booster");
		AddMenuItem(menu, "fullbooster", "Fullbooster");
	}
	else if(category == 8)
	{
		AddMenuItem(menu, "longjump", "Long Jump Stats");
		AddMenuItem(menu, "arena", "PvP Arena");
		AddMenuItem(menu, "jail", "Jail");
		AddMenuItem(menu, "bullettime", "Bullettime");
		//AddMenuItem(menu, "clip", "Clip");
		//AddMenuItem(menu, "bounceback", "Bounce Back");
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 360);
}

public ZoneTypeSelect(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		
		if(found)
		{
			new String:ZoneName[32];
			new LvlID;
			new bool:valid = false;
			new MapZoneType:zonetype;
		
			if(StrEqual(info, "cat_timer"))
			{
				DisplaySelectZoneTypeMenu(client, 1);
			}
			else if(StrEqual(info, "cat_timer_bonus"))
			{
				DisplaySelectZoneTypeMenu(client, 2);
			}
			else if(StrEqual(info, "cat_timer_other"))
			{
				DisplaySelectZoneTypeMenu(client, 3);
			}
			else if(StrEqual(info, "cat_physics"))
			{
				DisplaySelectZoneTypeMenu(client, 4);
			}
			else if(StrEqual(info, "cat_teleport"))
			{
				DisplaySelectZoneTypeMenu(client, 5);
			}
			else if(StrEqual(info, "cat_control"))
			{
				DisplaySelectZoneTypeMenu(client, 6);
			}
			else if(StrEqual(info, "cat_speed"))
			{
				DisplaySelectZoneTypeMenu(client, 7);
			}
			else if(StrEqual(info, "cat_other"))
			{
				DisplaySelectZoneTypeMenu(client, 8);
			}
			else if(StrEqual(info, "start"))
			{
				zonetype = ZtStart;
				ZoneName = "Start";
				LvlID = 1;
				valid = true;
			}
			else if(StrEqual(info, "end"))
			{
				zonetype = ZtEnd;
				ZoneName = "End";
				LvlID = 999;
				valid = true;
			}
			else if(StrEqual(info, "stop"))
			{
				zonetype = ZtStop;
				ZoneName = "Stop Timer";
				valid = true;
			}
			else if(StrEqual(info, "restart"))
			{
				zonetype = ZtRestart;
				ZoneName = "Restart Timer";
				valid = true;
			}
			else if(StrEqual(info, "last"))
			{
				zonetype = ZtLast;
				ZoneName = "Tele Last Level";
				valid = true;
			}
			else if(StrEqual(info, "next"))
			{
				zonetype = ZtNext;
				ZoneName = "Tele Next Level";
				valid = true;
			}
			else if(StrEqual(info, "level"))
			{
				zonetype = ZtLevel;
				new String:lvlbuffer[32];
				
				new hcount = 1;
				for (new zone = 0; zone < g_mapZonesCount; zone++)
				{
					if(g_mapZones[zone][Type] != ZtLevel) continue;
					if(g_mapZones[zone][Level_Id] <= hcount) continue;
					hcount = g_mapZones[zone][Level_Id];
				}
				hcount++;
				
				FormatEx(lvlbuffer, sizeof(lvlbuffer), "Stage %d", hcount);
				
				LvlID = hcount;
				ZoneName = lvlbuffer;
				valid = true;
			}
			else if(StrEqual(info, "bonusstart"))
			{
				zonetype = ZtBonusStart;
				ZoneName = "BonusStart";
				LvlID = 1001;
				valid = true;
			}
			else if(StrEqual(info, "bonusend"))
			{
				zonetype = ZtBonusEnd;
				ZoneName = "BonusEnd";
				LvlID = 1999;
				valid = true;
			}
			else if(StrEqual(info, "bonuslevel"))
			{
				zonetype = ZtBonusLevel;
				new String:lvlbuffer[32];
				
				new hcount = 1001;
				for (new zone = 0; zone < g_mapZonesCount; zone++)
				{
					if(g_mapZones[zone][Type] != ZtBonusLevel) continue;
					if(g_mapZones[zone][Level_Id] <= hcount) continue;
					hcount = g_mapZones[zone][Level_Id];
				}
				hcount++;
				
				FormatEx(lvlbuffer, sizeof(lvlbuffer), "Bonus-Stage %d", hcount);
				
				LvlID = hcount;
				ZoneName = lvlbuffer;
				valid = true;
			}
			else if(StrEqual(info, "npcnext"))
			{
				FakeClientCommand(client, "sm_npc_next");
			}
			else if(StrEqual(info, "npcnext_double"))
			{
				FakeClientCommand(client, "sm_npc_next");
			}
			else if(StrEqual(info, "block"))
			{
				zonetype = ZtBlock;
				ZoneName = "Block";
				valid = true;
			}
			else if(StrEqual(info, "limit"))
			{
				zonetype = ZtLimitSpeed;
				ZoneName = "LimitSpeed";
				valid = true;
			}
			else if(StrEqual(info, "clip"))
			{
				zonetype = ZtPlayerClip;
				ZoneName = "PlayerClip";
				valid = true;
			}
			else if(StrEqual(info, "longjump"))
			{
				zonetype = ZtLongjump;
				ZoneName = "Longjump";
				valid = true;
			}
			else if(StrEqual(info, "booster"))
			{
				zonetype = ZtBooster;
				ZoneName = "Booster";
				valid = true;
			}
			else if(StrEqual(info, "fullbooster"))
			{
				zonetype = ZtFullBooster;
				ZoneName = "FullBooster";
				valid = true;
			}
			else if(StrEqual(info, "arena"))
			{
				zonetype = ZtArena;
				ZoneName = "Arena";
				valid = true;
			}
			else if(StrEqual(info, "bounceback"))
			{
				zonetype = ZtBounceBack;
				ZoneName = "BounceBack";
				valid = true;
			}
			else if(StrEqual(info, "jail"))
			{
				zonetype = ZtJail;
				ZoneName = "Jail";
				valid = true;
			}
			else if(StrEqual(info, "up"))
			{
				zonetype = ZtPushUp;
				ZoneName = "Push Up";
				valid = true;
			}
			else if(StrEqual(info, "down"))
			{
				zonetype = ZtPushDown;
				ZoneName = "Push Down";
				valid = true;
			}
			else if(StrEqual(info, "north"))
			{
				zonetype = ZtPushNorth;
				ZoneName = "Push North";
				valid = true;
			}
			else if(StrEqual(info, "south"))
			{
				zonetype = ZtPushSouth;
				ZoneName = "Push South";
				valid = true;
			}
			else if(StrEqual(info, "east"))
			{
				zonetype = ZtPushEast;
				ZoneName = "Push East";
				valid = true;
			}
			else if(StrEqual(info, "west"))
			{
				zonetype = ZtPushWest;
				ZoneName = "Push West";
				valid = true;
			}
			else if(StrEqual(info, "auto"))
			{
				zonetype = ZtAuto;
				ZoneName = "Enable Auto Bhop";
				valid = true;
			}
			else if(StrEqual(info, "noauto"))
			{
				zonetype = ZtNoAuto;
				ZoneName = "DisableAuto Bhop";
				valid = true;
			}
			else if(StrEqual(info, "bullettime"))
			{
				zonetype = ZtBulletTime;
				ZoneName = "Bullet Time";
				valid = true;
			}
			else if(StrEqual(info, "nogravity"))
			{
				zonetype = ZtNoGravityOverwrite;
				ZoneName = "No Gravity Overwrite";
				valid = true;
			}
			else if(StrEqual(info, "noboost"))
			{
				zonetype = ZtNoBoost;
				ZoneName = "No Boost";
				valid = true;
			}
			else if(StrEqual(info, "restart_normal"))
			{
				zonetype = ZtRestartNormalTimer;
				ZoneName = "Restart Normal";
				valid = true;
			}
			else if(StrEqual(info, "restart_bonus"))
			{
				zonetype = ZtRestartBonusTimer;
				ZoneName = "Restart Bonust";
				valid = true;
			}
			else if(StrEqual(info, "short_end"))
			{
				zonetype = ZtShortEnd;
				ZoneName = "Short End";
				LvlID = 500;
				valid = true;
			}
			else if(StrEqual(info, "reset"))
			{
				zonetype = ZtReset;
				ZoneName = "Reset Timer";
				valid = true;
			}
			else if(StrEqual(info, "hover"))
			{
				zonetype = ZtHover;
				ZoneName = "Hover";
				valid = true;
			}
			else if(StrEqual(info, "freestyle"))
			{
				zonetype = ZtFreeStyle;
				ZoneName = "Freestyle Zone";
				valid = true;
			}
			
			if(valid)
			{
				new Float:point1[3];
				Array_Copy(g_mapZoneEditors[client][Point1], point1, 3);
				
				new Float:point2[3];
				Array_Copy(g_mapZoneEditors[client][Point2], point2, 3);
				
				point1[2] -= 2;
				point2[2] += 100;
				
				AddMapZone(g_currentMap, MapZoneType:zonetype, ZoneName, LvlID, point1, point2);
				RestartMapZoneEditor(client);
				LoadMapZones();
			}
		}
	}
	else if (action == MenuAction_End) 
	{
		CloseHandle(menu);
		RestartMapZoneEditor(client);
	} 
	else if (action == MenuAction_Cancel) 
	{
		if (itemNum == MenuCancel_Exit && hTopMenu != INVALID_HANDLE) 
		{
			DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
			RestartMapZoneEditor(client);
		}
	}
}

stock TeleLastCheckpoint(client)
{
	Tele_Level(client, g_mapZones[g_clientLevel[client]][Level_Id]);
}

stock CheckIllegalTeleport(client)
{
	if(GetVectorDistance(g_fCord_Old[client], g_fCord_New[client]) < 100.0)
	{
		return true;
	}
	
	return false;
}

stock CreateNPC(client, step, bool:double = false)
{
	if (0 < client < MaxClients)
	{
		if(!IsClientInGame(client))
			return;
		
		if(step == 0)
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			g_mapZoneEditors[client][Point1] = vec;
			new Handle:menu = CreateMenu(Handle_Menu_NPC);
			
			SetMenuTitle(menu, "Timer Menu");
			
			AddMenuItem(menu, "npc_reset", "Reset NPC Point");
			AddMenuItem(menu, "dest", "Set Destination (Teammate)");
			AddMenuItem(menu, "dest_double", "Set Destination (Both Players)");
			
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else
		{
			new String:lvlbuffer[32];
			
			new hcount = 1;
			for (new zone = 0; zone < g_mapZonesCount; zone++)
			{
				if(g_mapZones[zone][Type] != ZtNPC_Next) continue;
				if(g_mapZones[zone][Level_Id] <= hcount) continue;
				hcount = g_mapZones[zone][Level_Id];
			}
			
			hcount++;
			
			FormatEx(lvlbuffer, sizeof(lvlbuffer), "Level %d", hcount);
			
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			g_mapZoneEditors[client][Point2] = vec;
			
			new Float:point1[3];
			Array_Copy(g_mapZoneEditors[client][Point1], point1, 3);
			
			new Float:point2[3];
			Array_Copy(g_mapZoneEditors[client][Point2], point2, 3);
			
			if(!double) AddMapZone(g_currentMap, MapZoneType:ZtNPC_Next, lvlbuffer, hcount, point1, point2);
			else AddMapZone(g_currentMap, MapZoneType:ZtNPC_Next_Double, lvlbuffer, hcount, point1, point2);
			
			LoadMapZones();
		}
	}
}

public Handle_Menu_NPC(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "npc_reset"))
			{
				CreateNPC(client, 0);
			}
			else if(StrEqual(info, "dest"))
			{
				CreateNPC(client, 1, false);
			}
			else if(StrEqual(info, "dest_double"))
			{
				CreateNPC(client, 1, true);
			}
		}
	}
}

public Action:DrawAdminBox(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (g_mapZoneEditors[client][Step] == 0)
	{
		return Plugin_Stop;
	}
	
	new Float:a[3], Float:b[3];
	
	Array_Copy(g_mapZoneEditors[client][Point1], b, 3);
	
	if (g_mapZoneEditors[client][Step] == 3)
		Array_Copy(g_mapZoneEditors[client][Point2], a, 3);
	else
	GetClientAbsOrigin(client, a);
	
	new color[4] = {255, 255, 255, 255};
	
	a[2]=a[2]+100;
	DrawBox(a, b, 0.1, color, false);
	return Plugin_Continue;
}

public Action:DrawZones(Handle:timer)
{
	for (new zone = 0; zone < g_mapZonesCount; zone++)
	{
		new Float:point1[3];
		Array_Copy(g_mapZones[zone][Point1], point1, 3);
		
		new Float:point2[3];
		Array_Copy(g_mapZones[zone][Point2], point2, 3);
		
		if (point1[2] < point2[2])
			point2[2] = point1[2];
		else
			point1[2] = point2[2];
		
		if (g_mapZones[zone][Type] == ZtStart)
			DrawBox(point1, point2, 2.0, g_startColor, true);
		else if (g_mapZones[zone][Type] == ZtEnd)
			DrawBox(point1, point2, 2.0, g_endColor, true);
		else if (g_mapZones[zone][Type] == ZtBonusStart)
			DrawBox(point1, point2, 2.0, g_bonusstartColor, true);
		else if (g_mapZones[zone][Type] == ZtBonusEnd)
			DrawBox(point1, point2, 2.0, g_bonusendColor, true);
		else if (g_mapZones[zone][Type] == ZtShortEnd)
			DrawBox(point1, point2, 2.0, g_shortendColor, true);
	}
	
	return Plugin_Continue;
}

DrawZone(zone, bool:flat)
{
	if(g_MapZoneDrawDelayTimer[zone] == INVALID_HANDLE)
	{
		new Float:point1[3];
		Array_Copy(g_mapZones[zone][Point1], point1, 3);
		
		new Float:point2[3];
		Array_Copy(g_mapZones[zone][Point2], point2, 3);
		
		if(flat)
		{
			if (point1[2] < point2[2])
				point2[2] = point1[2];
			else
			point1[2] = point2[2];
		}
		
		if(flat)
		{
			if (g_mapZones[zone][Type] == ZtStop)
				DrawBox(point1, point2, 2.0, g_stopColor, flat);
			else if (g_mapZones[zone][Type] == ZtRestart)
				DrawBox(point1, point2, 2.0, g_restartColor, flat);
			else if (g_mapZones[zone][Type] == ZtLast)
				DrawBox(point1, point2, 2.0, g_telelastColor, flat);
			else if (g_mapZones[zone][Type] == ZtNext)
				DrawBox(point1, point2, 2.0, g_telenextColor, flat);
			else if (g_mapZones[zone][Type] == ZtLevel)
				DrawBox(point1, point2, 2.0, g_levelColor, flat);
			else if (g_mapZones[zone][Type] == ZtBonusLevel)
				DrawBox(point1, point2, 2.0, g_bonuslevelColor, flat);
			else if (g_mapZones[zone][Type] == ZtStart)
				DrawBox(point1, point2, 2.0, g_startColor, flat);
			else if (g_mapZones[zone][Type] == ZtEnd)
				DrawBox(point1, point2, 2.0, g_endColor, flat);
		}
		else
		{
			DrawBox(point1, point2, 2.0, g_startColor, flat);
		}
		
		g_MapZoneDrawDelayTimer[zone] = CreateTimer(2.0, Timer_DelayDraw, zone, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_DelayDraw(Handle:timer, any:zone)
{
	g_MapZoneDrawDelayTimer[zone] = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public TraceToEntity(client)
{
	new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);    
	
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceASDF, client);
	
	if (TR_DidHit(INVALID_HANDLE))
		return (TR_GetEntityIndex(INVALID_HANDLE));
	
	return (-1);
}

public bool:TraceASDF(entity, mask, any:data)
{
	return (data != entity);
}

bool:IsPlayerTouchingSpeedZone(client)
{
	if(g_bPreSpeedStart && Timer_IsPlayerTouchingZoneType(client, ZtStart))
		return true;
	if(g_bPreSpeedBonusStart && Timer_IsPlayerTouchingZoneType(client, ZtBonusStart))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtLimitSpeed))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtFullBooster))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtPlayerClip))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtBounceBack))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtPushUp))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtPushDown))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtPushNorth))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtPushSouth))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtPushEast))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtPushWest))
		return true;
	if(Timer_IsPlayerTouchingZoneType(client, ZtHover))
		return true;
	
	return false;
}

ChangePlayerVelocity(client)
{
	if(!g_timerPhysics)
		return;
	if(!g_bZonesLoaded)
		return;
	if(!IsClientInGame(client))
		return;
	if(!IsPlayerAlive(client))
		return;
	if(IsClientObserver(client))
		return;
	if(g_mapZonesCount < 1)
		return;
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	new mode = Timer_GetMode(client);
	new Float:maxspeed = g_Physics[mode][ModeBlockPreSpeeding];
	
	if(!IsPlayerTouchingSpeedZone(client))
		return;
	
	new Float:push_maxspeed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	
	if (Timer_IsPlayerTouchingZoneType(client, ZtFullBooster))
	{
		CheckVelocity(client, 4, maxspeed);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtPlayerClip))
	{
		CheckVelocity(client, 0, 10000.0);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtBounceBack))
	{
		CheckVelocity(client, 2, 10000.0);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtPushUp))
	{
		new Float:fVelocity[3];
		fVelocity[2] = push_maxspeed;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtPushDown))
	{
		new Float:fVelocity[3];
		fVelocity[2] = push_maxspeed*-1.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtPushNorth))
	{
		new Float:fVelocity[3];
		fVelocity[0] = push_maxspeed;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		Block_MovementControl(client);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtPushSouth))
	{
		new Float:fVelocity[3];
		fVelocity[0] = push_maxspeed*-1.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		Block_MovementControl(client);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtPushEast))
	{
		new Float:fVelocity[3];
		fVelocity[1] = push_maxspeed*-1;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		Block_MovementControl(client);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtPushWest))
	{
		new Float:fVelocity[3];
		fVelocity[1] = push_maxspeed;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
		Block_MovementControl(client);
	}
	else if (Timer_IsPlayerTouchingZoneType(client, ZtHover))
	{
		new Float:fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = -1.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	else
	{
		CheckVelocity(client, 1, maxspeed);
	}
}

IsInsideBox(Float:fPCords[3], Float:fbsx, Float:fbsy, Float:fbsz, Float:fbex, Float:fbey, Float:fbez)
{
	new Float:fpx = fPCords[0];
	new Float:fpy = fPCords[1];
	new Float:fpz = fPCords[2]+30;
	
	new bool:bX = false;
	new bool:bY = false;
	new bool:bZ = false;
	
	if (fbsx > fbex && fpx <= fbsx && fpx >= fbex)
		bX = true;
	else if (fbsx < fbex && fpx >= fbsx && fpx <= fbex)
		bX = true;
	
	if (fbsy > fbey && fpy <= fbsy && fpy >= fbey)
		bY = true;
	else if (fbsy < fbey && fpy >= fbsy && fpy <= fbey)
		bY = true;
	
	if (fbsz > fbez && fpz <= fbsz && fpz >= fbez)
		bZ = true;
	else if (fbsz < fbez && fpz >= fbsz && fpz <= fbez)
		bZ = true;
	
	if (bX && bY && bZ)
		return true;
	
	return false;
}

DrawBox(Float:fFrom[3], Float:fTo[3], Float:fLife, color[4], bool:flat)
{
	if(g_Settings[ZoneEffects])
	{
		//initialize tempoary variables bottom front
		decl Float:fLeftBottomFront[3];
		fLeftBottomFront[0] = fFrom[0];
		fLeftBottomFront[1] = fFrom[1];
		if(flat)
			fLeftBottomFront[2] = fTo[2]-g_Settings[ZoneBeamHeight];
		else
			fLeftBottomFront[2] = fTo[2];
		
		decl Float:fRightBottomFront[3];
		fRightBottomFront[0] = fTo[0];
		fRightBottomFront[1] = fFrom[1];
		if(flat)
			fRightBottomFront[2] = fTo[2]-g_Settings[ZoneBeamHeight];
		else
			fRightBottomFront[2] = fTo[2];
		
		//initialize tempoary variables bottom back
		decl Float:fLeftBottomBack[3];
		fLeftBottomBack[0] = fFrom[0];
		fLeftBottomBack[1] = fTo[1];
		if(flat)
			fLeftBottomBack[2] = fTo[2]-g_Settings[ZoneBeamHeight];
		else
			fLeftBottomBack[2] = fTo[2];
		
		decl Float:fRightBottomBack[3];
		fRightBottomBack[0] = fTo[0];
		fRightBottomBack[1] = fTo[1];
		if(flat)
			fRightBottomBack[2] = fTo[2]-g_Settings[ZoneBeamHeight];
		else
			fRightBottomBack[2] = fTo[2];
		
		//initialize tempoary variables top front
		decl Float:lefttopfront[3];
		lefttopfront[0] = fFrom[0];
		lefttopfront[1] = fFrom[1];
		if(flat)
			lefttopfront[2] = fFrom[2]+g_Settings[ZoneBeamHeight];
		else
			lefttopfront[2] = fFrom[2];
		decl Float:righttopfront[3];
		righttopfront[0] = fTo[0];
		righttopfront[1] = fFrom[1];
		if(flat)
			righttopfront[2] = fFrom[2]+g_Settings[ZoneBeamHeight];
		else
			righttopfront[2] = fFrom[2];
		
		//initialize tempoary variables top back
		decl Float:fLeftTopBack[3];
		fLeftTopBack[0] = fFrom[0];
		fLeftTopBack[1] = fTo[1];
		if(flat)
			fLeftTopBack[2] = fFrom[2]+g_Settings[ZoneBeamHeight];
		else
			fLeftTopBack[2] = fFrom[2];
		decl Float:fRightTopBack[3];
		fRightTopBack[0] = fTo[0];
		fRightTopBack[1] = fTo[1];
		if(flat)
			fRightTopBack[2] = fFrom[2]+g_Settings[ZoneBeamHeight];
		else
		fRightTopBack[2] = fFrom[2];
		
		//create the box
		TE_SetupBeamPoints(lefttopfront,righttopfront,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,10,0.0,color,0);TE_SendToAll(0.0);
		TE_SetupBeamPoints(lefttopfront,fLeftTopBack,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,10,0.0,color,0);TE_SendToAll(0.0);
		TE_SetupBeamPoints(fRightTopBack,fLeftTopBack,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,10,0.0,color,0);TE_SendToAll(0.0);
		TE_SetupBeamPoints(fRightTopBack,righttopfront,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,10,0.0,color,0);TE_SendToAll(0.0);
		
		if(!flat)
		{
			TE_SetupBeamPoints(fLeftBottomFront,fRightBottomFront,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,0,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
			TE_SetupBeamPoints(fLeftBottomFront,fLeftBottomBack,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,0,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
			TE_SetupBeamPoints(fLeftBottomFront,lefttopfront,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,0,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
			
			
			TE_SetupBeamPoints(fRightBottomBack,fLeftBottomBack,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,0,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
			TE_SetupBeamPoints(fRightBottomBack,fRightBottomFront,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,0,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
			TE_SetupBeamPoints(fRightBottomBack,fRightTopBack,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,0,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
			
			TE_SetupBeamPoints(fRightBottomFront,righttopfront,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,0,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
			TE_SetupBeamPoints(fLeftBottomBack,fLeftTopBack,precache_laser,0,0,0,fLife,g_Settings[ZoneBeamThickness],1.0,0,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		}
	}
}


stock DrawBlueBalls(Float:fFrom[3], Float:fTo[3])
{
	//initialize tempoary variables bottom front
	decl Float:fLeftBottomFront[3];
	fLeftBottomFront[0] = fFrom[0];
	fLeftBottomFront[1] = fFrom[1];
	fLeftBottomFront[2] = fTo[2]-20;

	decl Float:fRightBottomFront[3];
	fRightBottomFront[0] = fTo[0];
	fRightBottomFront[1] = fFrom[1];
	fRightBottomFront[2] = fTo[2]-20;

	//initialize tempoary variables bottom back
	decl Float:fLeftBottomBack[3];
	fLeftBottomBack[0] = fFrom[0];
	fLeftBottomBack[1] = fTo[1];
	fLeftBottomBack[2] = fTo[2]-20;

	decl Float:fRightBottomBack[3];
	fRightBottomBack[0] = fTo[0];
	fRightBottomBack[1] = fTo[1];
	fRightBottomBack[2] = fTo[2]-20;

	//initialize tempoary variables top front
	decl Float:fLeftTopFront[3];
	fLeftTopFront[0] = fFrom[0];
	fLeftTopFront[1] = fFrom[1];
	fLeftTopFront[2] = fFrom[2]+20;
	decl Float:fRightTopFront[3];
	fRightTopFront[0] = fTo[0];
	fRightTopFront[1] = fFrom[1];
	fRightTopFront[2] = fFrom[2]+20;

	//initialize tempoary variables top back
	decl Float:fLeftTopBack[3];
	fLeftTopBack[0] = fFrom[0];
	fLeftTopBack[1] = fTo[1];
	fLeftTopBack[2] = fFrom[2]+20;
	decl Float:fRightTopBack[3];
	fRightTopBack[0] = fTo[0];
	fRightTopBack[1] = fTo[1];
	fRightTopBack[2] = fFrom[2]+20;

	TE_SetupGlowSprite(fLeftTopBack, gGlow1, 1.0, 1.0, 255);TE_SendToAll();
	TE_SetupGlowSprite(fLeftTopFront, gGlow1, 1.0, 1.0, 255);TE_SendToAll();
	TE_SetupGlowSprite(fRightTopFront, gGlow1, 1.0, 1.0, 255);TE_SendToAll();
	TE_SetupGlowSprite(fRightTopBack, gGlow1, 1.0, 1.0, 255);TE_SendToAll();
}

stock DrawSmoke(Float:fFrom[3], Float:fTo[3])
{
	//initialize tempoary variables bottom front
	decl Float:fLeftBottomFront[3];
	fLeftBottomFront[0] = fFrom[0];
	fLeftBottomFront[1] = fFrom[1];
	fLeftBottomFront[2] = fTo[2]-50;

	decl Float:fRightBottomFront[3];
	fRightBottomFront[0] = fTo[0];
	fRightBottomFront[1] = fFrom[1];
	fRightBottomFront[2] = fTo[2]-50;

	//initialize tempoary variables bottom back
	decl Float:fLeftBottomBack[3];
	fLeftBottomBack[0] = fFrom[0];
	fLeftBottomBack[1] = fTo[1];
	fLeftBottomBack[2] = fTo[2]-50;

	decl Float:fRightBottomBack[3];
	fRightBottomBack[0] = fTo[0];
	fRightBottomBack[1] = fTo[1];
	fRightBottomBack[2] = fTo[2]-50;

	//initialize tempoary variables top front
	decl Float:fLeftTopFront[3];
	fLeftTopFront[0] = fFrom[0];
	fLeftTopFront[1] = fFrom[1];
	fLeftTopFront[2] = fFrom[2]+50;
	decl Float:fRightTopFront[3];
	fRightTopFront[0] = fTo[0];
	fRightTopFront[1] = fFrom[1];
	fRightTopFront[2] = fFrom[2]+50;

	//initialize tempoary variables top back
	decl Float:fLeftTopBack[3];
	fLeftTopBack[0] = fFrom[0];
	fLeftTopBack[1] = fTo[1];
	fLeftTopBack[2] = fFrom[2]+50;
	decl Float:fRightTopBack[3];
	fRightTopBack[0] = fTo[0];
	fRightTopBack[1] = fTo[1];
	fRightTopBack[2] = fFrom[2]+50;

	TE_SetupSmoke(fLeftTopBack, gSmoke1, 10.0, 2);TE_SendToAll();
	TE_SetupSmoke(fLeftTopFront, gSmoke1, 10.0, 2);TE_SendToAll();
	TE_SetupSmoke(fRightTopFront, gSmoke1, 10.0, 2);TE_SendToAll();
	TE_SetupSmoke(fRightTopBack, gSmoke1, 10.0, 2);TE_SendToAll();
}

stock DrawXBeam(Float:fFrom[3], Float:fTo[3])
{
	//initialize tempoary variables bottom front
	decl Float:fLeftBottomFront[3];
	fLeftBottomFront[0] = fFrom[0];
	fLeftBottomFront[1] = fFrom[1];
	fLeftBottomFront[2] = fTo[2]-20;

	decl Float:fRightBottomFront[3];
	fRightBottomFront[0] = fTo[0];
	fRightBottomFront[1] = fFrom[1];
	fRightBottomFront[2] = fTo[2]-20;

	//initialize tempoary variables bottom back
	decl Float:fLeftBottomBack[3];
	fLeftBottomBack[0] = fFrom[0];
	fLeftBottomBack[1] = fTo[1];
	fLeftBottomBack[2] = fTo[2]-20;

	decl Float:fRightBottomBack[3];
	fRightBottomBack[0] = fTo[0];
	fRightBottomBack[1] = fTo[1];
	fRightBottomBack[2] = fTo[2]-20;

	//initialize tempoary variables top front
	decl Float:fLeftTopFront[3];
	fLeftTopFront[0] = fFrom[0];
	fLeftTopFront[1] = fFrom[1];
	fLeftTopFront[2] = fFrom[2]+20;
	decl Float:fRightTopFront[3];
	fRightTopFront[0] = fTo[0];
	fRightTopFront[1] = fFrom[1];
	fRightTopFront[2] = fFrom[2]+20;

	//initialize tempoary variables top back
	decl Float:fLeftTopBack[3];
	fLeftTopBack[0] = fFrom[0];
	fLeftTopBack[1] = fTo[1];
	fLeftTopBack[2] = fFrom[2]+20;
	decl Float:fRightTopBack[3];
	fRightTopBack[0] = fTo[0];
	fRightTopBack[1] = fTo[1];
	fRightTopBack[2] = fFrom[2]+20;

	TE_SetupBeamPoints(fRightTopBack, fLeftTopFront, gLaser1, 0, 0, 0, 1.1, 25.0, 25.0, 0, 1.0, {255, 0, 0, 255}, 3 );TE_SendToAll();
	TE_SetupBeamPoints(fLeftTopBack, fRightTopFront, gLaser1, 0, 0, 0, 1.1, 25.0, 25.0, 0, 1.0, {255, 0, 0, 255}, 3 );TE_SendToAll();
}

stock DrawXBeam2(Float:fFrom[3], Float:fTo[3])
{
	//initialize tempoary variables bottom front
	decl Float:fLeftBottomFront[3];
	fLeftBottomFront[0] = fFrom[0];
	fLeftBottomFront[1] = fFrom[1];
	fLeftBottomFront[2] = fTo[2]-20;

	decl Float:fRightBottomFront[3];
	fRightBottomFront[0] = fTo[0];
	fRightBottomFront[1] = fFrom[1];
	fRightBottomFront[2] = fTo[2]-20;

	//initialize tempoary variables bottom back
	decl Float:fLeftBottomBack[3];
	fLeftBottomBack[0] = fFrom[0];
	fLeftBottomBack[1] = fTo[1];
	fLeftBottomBack[2] = fTo[2]-20;

	decl Float:fRightBottomBack[3];
	fRightBottomBack[0] = fTo[0];
	fRightBottomBack[1] = fTo[1];
	fRightBottomBack[2] = fTo[2]-20;

	//initialize tempoary variables top front
	decl Float:fLeftTopFront[3];
	fLeftTopFront[0] = fFrom[0];
	fLeftTopFront[1] = fFrom[1];
	fLeftTopFront[2] = fFrom[2]+20;
	decl Float:fRightTopFront[3];
	fRightTopFront[0] = fTo[0];
	fRightTopFront[1] = fFrom[1];
	fRightTopFront[2] = fFrom[2]+20;

	//initialize tempoary variables top back
	decl Float:fLeftTopBack[3];
	fLeftTopBack[0] = fFrom[0];
	fLeftTopBack[1] = fTo[1];
	fLeftTopBack[2] = fFrom[2]+20;
	decl Float:fRightTopBack[3];
	fRightTopBack[0] = fTo[0];
	fRightTopBack[1] = fTo[1];
	fRightTopBack[2] = fFrom[2]+20;

	TE_SetupBeamPoints(fRightTopBack, fLeftTopFront, gLaser1, 0, 0, 0, 1.1, 25.0, 25.0, 0, 1.0, {255, 0, 255, 255}, 3 );TE_SendToAll();
	TE_SetupBeamPoints(fLeftTopBack, fRightTopFront, gLaser1, 0, 0, 0, 1.1, 25.0, 25.0, 0, 1.0, {255, 0, 255, 255}, 3 );TE_SendToAll();
}

stock ZoneEffectTesla(targetzone)
{
	new Float:zero[3];

	new Float:center[3];
	center[0] = (g_mapZones[targetzone][Point1][0] + g_mapZones[targetzone][Point2][0]) / 2.0;
	center[1] = (g_mapZones[targetzone][Point1][1] + g_mapZones[targetzone][Point2][1]) / 2.0;
	center[2] = (g_mapZones[targetzone][Point1][2] + g_mapZones[targetzone][Point2][2]) / 2.0;
	center[2] = center[2]+20;

	new laserent = CreateEntityByName("point_tesla");
	DispatchKeyValue(laserent, "m_flRadius", "70.0");
	DispatchKeyValue(laserent, "m_SoundName", "DoSpark");
	DispatchKeyValue(laserent, "beamcount_min", "42");
	DispatchKeyValue(laserent, "beamcount_max", "62");
	DispatchKeyValue(laserent, "texture", "sprites/physbeam.vmt");
	DispatchKeyValue(laserent, "m_Color", "255 255 255");
	DispatchKeyValue(laserent, "thick_min", "10.0");
	DispatchKeyValue(laserent, "thick_max", "11.0");
	DispatchKeyValue(laserent, "lifetime_min", "0.3");
	DispatchKeyValue(laserent, "lifetime_max", "0.3");
	DispatchKeyValue(laserent, "interval_min", "0.1");
	DispatchKeyValue(laserent, "interval_max", "0.2");
	DispatchSpawn(laserent);

	TeleportEntity(laserent, center, zero, zero);

	AcceptEntityInput(laserent, "TurnOn");  
	AcceptEntityInput(laserent, "DoSpark");
}

GetZoneEntityCount()
{
	new count;
	
	for (new i = MaxClients; i <= 2047; i++)
	{
		if(!IsValidEntity(i)) continue;
		
		new String:EntName[256];
		Entity_GetName(i, EntName, sizeof(EntName));
		
		new valid = StrContains(EntName, "#DHC_");
		if(valid > -1)
		{
			count++;
		}
	}
	
	return count;
}

DeleteAllZoneEntitys()
{
	for (new i = MaxClients; i <= 2047; i++)
	{
		g_MapZoneDrawDelayTimer[i] = INVALID_HANDLE;
		g_MapZoneEntityZID[i] = -1;
		
		if(!IsValidEntity(i)) continue;
		
		new String:EntName[256];
		Entity_GetName(i, EntName, sizeof(EntName));
		
		
		new valid = StrContains(EntName, "#DHC_NPC");
		if(valid > -1)
		{
			SDKUnhook(i, SDKHook_StartTouch, NPC_Use);
		}
		
		new valid2 = StrContains(EntName, "#DHC_TRIGGER");
		if(valid2 > -1)
		{
			SDKUnhook(i, SDKHook_StartTouch, StartTouchTrigger);
			SDKUnhook(i, SDKHook_EndTouch, EndTouchTrigger);
			SDKUnhook(i, SDKHook_Touch, OnTouchTrigger);
		}
		
		new valid3 = StrContains(EntName, "#DHC_");
		if(valid3 > -1)
		{
			DeleteEntity(i);
		}
		
		
		for (new client = 1; client <= MaxClients; client++)
		{
			g_bZone[i][client] = false;
		}
	}
}

DeleteEntity(entity)
{
	AcceptEntityInput(entity, "kill");
}

SpawnZoneEntitys(zone)
{
	if(g_mapZones[zone][Point1][0] != 0.0 || g_mapZones[zone][Point1][1]  != 0.0 || g_mapZones[zone][Point1][2] != 0.0 )
	{
		new entity = CreateEntityByName("trigger_multiple");
		if (entity > 0)
		{
			if(!IsValidEntity(entity)) {
				PrintToServer("DEBUG ----> Invalid entity index %i", entity);
				return;
			}
			
			g_MapZoneEntityZID[entity] = zone;
			
			SetEntityModel(entity, "models/props_junk/wood_crate001a.mdl"); 
			
			new Float:origin[3];
			origin[0] = (g_mapZones[zone][Point1][0] + g_mapZones[zone][Point2][0]) / 2.0;
			origin[1] = (g_mapZones[zone][Point1][1] + g_mapZones[zone][Point2][1]) / 2.0;
			origin[2] = g_mapZones[zone][Point1][2] / 1.0;
			
			new Float:minbounds[3]; 
			new Float:maxbounds[3]; 
			
			minbounds[0] = FloatAbs(g_mapZones[zone][Point1][0]-g_mapZones[zone][Point2][0]) / -2.0;
			minbounds[1] = FloatAbs(g_mapZones[zone][Point1][1]-g_mapZones[zone][Point2][1]) / -2.0;
			minbounds[2] = -1.0;
			
			maxbounds[0] = FloatAbs(g_mapZones[zone][Point1][0]-g_mapZones[zone][Point2][0]) / 2.0;
			maxbounds[1] = FloatAbs(g_mapZones[zone][Point1][1]-g_mapZones[zone][Point2][1]) / 2.0;
			maxbounds[2] = FloatAbs(g_mapZones[zone][Point1][2]-g_mapZones[zone][Point2][2]) / 1.0;
			
			//Resize trigger
			minbounds[0] += g_Settings[ZoneResize];
			minbounds[1] += g_Settings[ZoneResize];
			minbounds[2] += g_Settings[ZoneResize];
			
			maxbounds[0] -= g_Settings[ZoneResize];
			maxbounds[1] -= g_Settings[ZoneResize];
			maxbounds[2] -= g_Settings[ZoneResize];
			
			if(IsValidEntity(entity))
			{ 
				
				// Spawnflags:	1 - only a player can trigger this by touch, makes it so a NPC cannot fire a trigger_multiple
				// 2 - Won't fire unless triggering ent's view angles are within 45 degrees of trigger's angles (in addition to any other conditions), so if you want the player to only be able to fire the entity at a 90 degree angle you would do ",angles,0 90 0," into your spawnstring.
				// 4 - Won't fire unless player is in it and pressing use button (in addition to any other conditions), you must make a bounding box,(max\mins) for this to work.
				// 8 - Won't fire unless player/NPC is in it and pressing fire button, you must make a bounding box,(max\mins) for this to work.
				// 16 - only non-player NPCs can trigger this by touch
				// 128 - Start off, has to be activated by a target_activate to be touchable/usable
				// 256 - multiple players can trigger the entity at the same time
				DispatchKeyValue(entity, "spawnflags", "257"); 
				DispatchKeyValue(entity, "StartDisabled", "0");
				DispatchKeyValue(entity, "OnTrigger", "!activator,IgnitePlayer,,0,-1");
				
				new String:EntName[256];
				FormatEx(EntName, sizeof(EntName), "#DHC_Trigger_%d", g_mapZones[zone][Id]);
				DispatchKeyValue(entity, "targetname", EntName);
				
				if(g_mapZones[zone][Type] == ZtBlock) DispatchKeyValue(entity, "Solid", "6"); 
				
				if(DispatchSpawn(entity))
				{
					ActivateEntity(entity);
					
					SetEntPropVector(entity, Prop_Send, "m_vecMins", minbounds);
					SetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxbounds);
					
					if(g_mapZones[zone][Type] != ZtBlock) SetEntProp(entity, Prop_Send, "m_nSolidType", 2);
					
					TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
					
					// SetVariantString(Buffer);
					AcceptEntityInput(entity, "SetParent");
					
					new iEffects = GetEntProp(entity, Prop_Send, "m_fEffects");
					iEffects |= 0x020;
					SetEntProp(entity, Prop_Send, "m_fEffects", iEffects);
					
					SDKHook(entity, SDKHook_StartTouch,  StartTouchTrigger);
					SDKHook(entity, SDKHook_EndTouch, EndTouchTrigger);
					SDKHook(entity, SDKHook_Touch, OnTouchTrigger);
					
				}
				else 
				{
					PrintToServer("Not able to dispatchspawn for Entity %i in SpawnTrigger", entity);
					PrintToChatAll("Not able to dispatchspawn for Entity %i in SpawnTrigger", entity);
				}
				
			} 
			else 
			{
				PrintToServer("Entity %i did not pass the validation check in SpawnTrigger", entity);
				PrintToChatAll("Entity %i did not pass the validation check in SpawnTrigger", entity);
			}
		}
	}
	
	if(g_mapZones[zone][Type] == ZtNPC_Next || g_mapZones[zone][Type] == ZtNPC_Next_Double)
	{
		new Float:vecNPC[3];
		vecNPC[0] = g_mapZones[zone][Point1][0];
		vecNPC[1] = g_mapZones[zone][Point1][1];
		vecNPC[2] = g_mapZones[zone][Point1][2];
		
		new Float:vecDestination[3];
		vecDestination[0] = g_mapZones[zone][Point2][0];
		vecDestination[1] = g_mapZones[zone][Point2][1];
		vecDestination[2] = g_mapZones[zone][Point2][2];
		
		new String:ModePath[256];
		if(g_mapZones[zone][Type] == ZtNPC_Next)
		{
			PrecacheModel(g_Settings[NPC_Path], true);
			FormatEx(ModePath, sizeof(ModePath), "%s", g_Settings[NPC_Path]);
		}
		else if(g_mapZones[zone][Type] == ZtNPC_Next_Double)
		{
			PrecacheModel(g_Settings[NPC_Double_Path], true);
			FormatEx(ModePath, sizeof(ModePath), "%s", g_Settings[NPC_Double_Path]);
		}
		
		decl String:EntName[256];
		FormatEx(EntName, sizeof(EntName), "#DHC_NPC_%d", g_mapZones[zone][Id]);
		
		new String:Classname[] = "prop_physics_override";
		
		new entity1 = CreateEntityByName(Classname);
		SetEntityModel(entity1, ModePath);
		
		DispatchKeyValue(entity1, "targetname", EntName);
		
		DispatchSpawn(entity1);
		AcceptEntityInput(entity1, "DisableMotion");
		AcceptEntityInput(entity1, "DisableShadow");
		TeleportEntity(entity1, vecNPC, NULL_VECTOR, NULL_VECTOR);
		
		g_mapZones[zone][NPC] = entity1;
		
		SDKHook(entity1, SDKHook_StartTouch, NPC_Use);
	}
	else if(adminmode == 1)
	{
		new Float:fFrom[3];
		fFrom[0] = g_mapZones[zone][Point2][0];
		fFrom[1] = g_mapZones[zone][Point2][1];
		fFrom[2] = g_mapZones[zone][Point2][2];
		
		new Float:fTo[3];
		fTo[0] = g_mapZones[zone][Point1][0];
		fTo[1] = g_mapZones[zone][Point1][1];
		fTo[2] = g_mapZones[zone][Point1][2];
		
		//initialize tempoary variables bottom front
		decl Float:fLeftBottomFront[3];
		fLeftBottomFront[0] = fFrom[0];
		fLeftBottomFront[1] = fFrom[1];
		fLeftBottomFront[2] = fTo[2]+20;
		
		decl Float:fRightBottomFront[3];
		fRightBottomFront[0] = fTo[0];
		fRightBottomFront[1] = fFrom[1];
		fRightBottomFront[2] = fTo[2]+20;
		
		//initialize tempoary variables bottom back
		decl Float:fLeftBottomBack[3];
		fLeftBottomBack[0] = fFrom[0];
		fLeftBottomBack[1] = fTo[1];
		fLeftBottomBack[2] = fTo[2]+20;
		
		decl Float:fRightBottomBack[3];
		fRightBottomBack[0] = fTo[0];
		fRightBottomBack[1] = fTo[1];
		fRightBottomBack[2] = fTo[2]+20;
		
		PrecacheModel("models/props_junk/trafficcone001a.mdl", true);
		
		decl String:EntName[256];
		FormatEx(EntName, sizeof(EntName), "#DHC_Zone_%d", g_mapZones[zone][Id]);
		
		new String:ModePath[] = "models/props_junk/trafficcone001a.mdl";
		new String:Classname[] = "prop_physics_override";
		
		new entity1 = CreateEntityByName(Classname);
		SetEntityModel(entity1, ModePath);
		SetEntProp(entity1, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(entity1, Prop_Send, "m_usSolidFlags", 12);
		SetEntProp(entity1, Prop_Send, "m_nSolidType", 6);
		SetEntityMoveType(entity1, MOVETYPE_NONE);		
		DispatchKeyValue(entity1, "targetname", EntName);
		DispatchSpawn(entity1);
		AcceptEntityInput(entity1, "DisableMotion");
		AcceptEntityInput(entity1, "DisableShadow");
		TeleportEntity(entity1, fRightBottomBack, NULL_VECTOR, NULL_VECTOR);
		
		new entity2 = CreateEntityByName(Classname);
		SetEntityModel(entity2, ModePath);
		SetEntProp(entity2, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(entity2, Prop_Send, "m_usSolidFlags", 12);
		SetEntProp(entity2, Prop_Send, "m_nSolidType", 6);
		SetEntityMoveType(entity2, MOVETYPE_NONE);
		DispatchKeyValue(entity2, "targetname", EntName);
		DispatchSpawn(entity2);
		AcceptEntityInput(entity2, "DisableMotion");
		AcceptEntityInput(entity2, "DisableShadow");
		TeleportEntity(entity2, fRightBottomFront, NULL_VECTOR, NULL_VECTOR);
		
		new entity3 = CreateEntityByName(Classname);
		SetEntityModel(entity3, ModePath);
		SetEntProp(entity3, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(entity3, Prop_Send, "m_usSolidFlags", 12);
		SetEntProp(entity3, Prop_Send, "m_nSolidType", 6);
		SetEntityMoveType(entity3, MOVETYPE_NONE);
		DispatchKeyValue(entity3, "targetname", EntName);
		DispatchSpawn(entity3);
		AcceptEntityInput(entity3, "DisableMotion");
		AcceptEntityInput(entity3, "DisableShadow");
		TeleportEntity(entity3, fLeftBottomFront, NULL_VECTOR, NULL_VECTOR);
		
		new entity4 = CreateEntityByName(Classname);
		SetEntityModel(entity4, ModePath);
		SetEntProp(entity4, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(entity4, Prop_Data, "m_CollisionGroup", 2, 4);
		SetEntProp(entity4, Prop_Send, "m_usSolidFlags", 12);
		SetEntProp(entity4, Prop_Send, "m_nSolidType", 6);
		SetEntityMoveType(entity4, MOVETYPE_NONE);
		DispatchKeyValue(entity4, "targetname", EntName);
		DispatchSpawn(entity4);
		AcceptEntityInput(entity4, "DisableMotion");
		AcceptEntityInput(entity4, "DisableShadow");
		TeleportEntity(entity4, fLeftBottomBack, NULL_VECTOR, NULL_VECTOR);
		
		if(g_mapZones[zone][Type] == ZtLevel || g_mapZones[zone][Type] == ZtStart || g_mapZones[zone][Type] == ZtEnd)
		{
			SetEntityRenderColor(entity1, 0, 255, 0, 200);
			SetEntityRenderColor(entity2, 0, 255, 0, 200);
			SetEntityRenderColor(entity3, 0, 255, 0, 200);
			SetEntityRenderColor(entity4, 0, 255, 0, 200);
		}
		else if(g_mapZones[zone][Type] == ZtBonusLevel || g_mapZones[zone][Type] == ZtBonusStart || g_mapZones[zone][Type] == ZtBonusEnd)
		{
			SetEntityRenderColor(entity1, 0, 0, 255, 200);
			SetEntityRenderColor(entity2, 0, 0, 255, 200);
			SetEntityRenderColor(entity3, 0, 0, 255, 200);
			SetEntityRenderColor(entity4, 0, 0, 255, 200);
		}
		else if(g_mapZones[zone][Type] == ZtStop)
		{
			SetEntityRenderColor(entity1, 138, 0, 180, 200);
			SetEntityRenderColor(entity2, 138, 0, 180, 200);
			SetEntityRenderColor(entity3, 138, 0, 180, 200);
			SetEntityRenderColor(entity4, 138, 0, 180, 200);
		}
		else if(g_mapZones[zone][Type] == ZtRestart)
		{
			SetEntityRenderColor(entity1, 255, 0, 0, 200);
			SetEntityRenderColor(entity2, 255, 0, 0, 200);
			SetEntityRenderColor(entity3, 255, 0, 0, 200);
			SetEntityRenderColor(entity4, 255, 0, 0, 200);
		}
		else if(g_mapZones[zone][Type] == ZtLast)
		{
			SetEntityRenderColor(entity1, 255, 255, 0, 200);
			SetEntityRenderColor(entity2, 255, 255, 0, 200);
			SetEntityRenderColor(entity3, 255, 255, 0, 200);
			SetEntityRenderColor(entity4, 255, 255, 0, 200);
		}
		else if(g_mapZones[zone][Type] == ZtNext)
		{
			SetEntityRenderColor(entity1, 0, 255, 255, 200);
			SetEntityRenderColor(entity2, 0, 255, 255, 200);
			SetEntityRenderColor(entity3, 0, 255, 255, 200);
			SetEntityRenderColor(entity4, 0, 255, 255, 200);
		}
	}
}

public Action:SetBlockable(Handle:timer, any:entity)
{
	SetEntData(entity, g_ioffsCollisionGroup, 5, 4, true);
	return Plugin_Stop;
}

Menu_NPC_Next(client, zone)
{
	if (0 < client < MaxClients)
	{
		
		if(adminmode == 1 && Client_IsAdmin(client))
		{
			new Handle:menu = CreateMenu(Handle_Menu_NPC_Delete);
			
			SetMenuTitle(menu, "Delete this NPC?");
			
			AddMenuItem(menu, "yes", "Yes");
			AddMenuItem(menu, "no", "No!");
			
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			g_iTargetNPC[client] = zone;
		}
		else if(g_Settings[NPCConfirm])
		{
			new Handle:menu = CreateMenu(Handle_Menu_NPC_Next);
			
			SetMenuTitle(menu, "Do you like to teleport?");
			
			AddMenuItem(menu, "yes", "Yes Please");
			AddMenuItem(menu, "no", "Not now!");
			
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else
		{
			if(g_clientLevel[client] > 0 && client > 0 && g_bZonesLoaded)
			{
				new Float:velStop[3];
				new Float:vecDestination[3];
				vecDestination[0] = g_mapZones[g_clientLevel[client]][Point2][0];
				vecDestination[1] = g_mapZones[g_clientLevel[client]][Point2][1];
				vecDestination[2] = g_mapZones[g_clientLevel[client]][Point2][2];
				
				if(Timer_IsPlayerTouchingZoneType(client, ZtStart)) Timer_SetIgnoreEndTouchStart(client, 1);
				
				new mate;
				if(g_timerTeams) mate = Timer_GetClientTeammate(client);
				
				if(mate > 0)
				{
					if(g_mapZones[zone][Type] == ZtNPC_Next_Double)
					{
						TeleportEntity(client, vecDestination, NULL_VECTOR, velStop);
						CreateTimer(1.5, SetBlockable, client, TIMER_FLAG_NO_MAPCHANGE);
						SetPush(client);
						
						TeleportEntity(mate, vecDestination, NULL_VECTOR, velStop);
						CreateTimer(1.5, SetBlockable, mate, TIMER_FLAG_NO_MAPCHANGE);
						SetPush(mate);
					}
					else if(Timer_GetCoopStatus(client))
					{
						TeleportEntity(Timer_GetClientTeammate(client), vecDestination, NULL_VECTOR, velStop);
					}
					else TeleportEntity(client, vecDestination, NULL_VECTOR, velStop);
				}
				else TeleportEntity(client, vecDestination, NULL_VECTOR, velStop);
			}
		}
	}
}

public Handle_Menu_NPC_Next(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "yes"))
			{
				if(g_clientLevel[client] > 0 && client > 0 && g_bZonesLoaded)
				{
					new Float:velStop[3];
					new Float:vecDestination[3];
					vecDestination[0] = g_mapZones[g_clientLevel[client]][Point2][0];
					vecDestination[1] = g_mapZones[g_clientLevel[client]][Point2][1];
					vecDestination[2] = g_mapZones[g_clientLevel[client]][Point2][2];
					
					if(Timer_IsPlayerTouchingZoneType(client, ZtStart)) Timer_SetIgnoreEndTouchStart(client, 1);
					
					new mate;
					if(g_timerTeams) mate= Timer_GetClientTeammate(client);
					
					if(mate > 0)
					{
						if(Timer_GetCoopStatus(client))
						{
							TeleportEntity(mate, vecDestination, NULL_VECTOR, velStop);
						}
						else TeleportEntity(client, vecDestination, NULL_VECTOR, velStop);
					}
					else TeleportEntity(client, vecDestination, NULL_VECTOR, velStop);
				}
			}
			else if(StrEqual(info, "no"))
			{
				
			}
		}
	}
}

public Handle_Menu_NPC_Delete(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "yes"))
			{
				new zone = g_iTargetNPC[client];
				
				decl String:query[64];
				FormatEx(query, sizeof(query), "DELETE FROM mapzone WHERE id = %d", g_mapZones[zone][Id]);
				
				SQL_TQuery(g_hSQL, DeleteMapZoneCallback, query, client, DBPrio_Normal);
			}
			else if(StrEqual(info, "no"))
			{
				
			}
		}
	}
}

ParseColor(const String:color[], result[])
{
	decl String:buffers[4][4];
	ExplodeString(color, " ", buffers, sizeof(buffers), sizeof(buffers[]));
	
	for (new i = 0; i < sizeof(buffers); i++)
		result[i] = StringToInt(buffers[i]);
}

stock Tele_Level(client, level)
{
	if(level > 0 && client > 0 && g_bZonesLoaded)
	{
		for (new mapZone = 0; mapZone < g_mapZonesCount; mapZone++)
		{
			if(g_mapZones[mapZone][Level_Id] < 1)
			{
				continue;
			}
			
			if (g_mapZones[mapZone][Level_Id] == level)
			{
				Tele_Zone(client, mapZone);
				break;
			}
		}
	}
}

stock Tele_Zone(client, zone)
{
	new Float:zero[3];
	
	new Float:center[3];
	center[0] = (g_mapZones[zone][Point1][0] + g_mapZones[zone][Point2][0]) / 2.0;
	center[1] = (g_mapZones[zone][Point1][1] + g_mapZones[zone][Point2][1]) / 2.0;
	center[2] = g_mapZones[zone][Point1][2] + g_Settings[ZoneTeleportZ];
	
	if(IsClientInGame(client)) 
	{
		if((Timer_IsPlayerTouchingZoneType(client, ZtStart) || Timer_IsPlayerTouchingZoneType(client, ZtBonusStart)) 
			&& g_mapZones[zone][Type] != ZtStart && g_mapZones[zone][Type] != ZtBonusStart)
		Timer_SetIgnoreEndTouchStart(client, 1);
		
		new mode = Timer_GetMode(client);
		
		//Anti-Chat
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_Physics[mode][ModeTimeScale]);
		SetEntityGravity(client, g_Physics[mode][ModeGravity]);
		TeleportEntity(client, center, NULL_VECTOR, zero);
		CreateTimer(0.0, Timer_StopSpeed, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_StopSpeed(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(!IsPlayerAlive(client))
		return Plugin_Stop;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,-100.0});
	
	return Plugin_Stop;
}

public Action:Command_LevelAdminMode(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_zoneadminmode [0/1]");
		return Plugin_Handled;	
	}
	if (args == 1)
	{
		decl String:name2[64];
		GetCmdArg(1,name2,sizeof(name2));
		adminmode = StringToInt(name2);
		
		if(adminmode == 1) 
		{
			CPrintToChat(client, PLUGIN_PREFIX, "Adminmode Enabled");
		}
		else  
		{
			CPrintToChat(client, PLUGIN_PREFIX, "Adminmode Disabled");
		}
	}
	return Plugin_Handled;	
}

public Action:Command_ReloadZones(client, args)
{
	LoadMapZones();
	CPrintToChat(client, PLUGIN_PREFIX, "Zones Reloaded");
	
	return Plugin_Handled;
}

public Action:Command_NPC_Next(client, args)
{
	CreateNPC(client, 0);
	
	return Plugin_Handled;
}

public Action:Command_LevelName(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_zonename [name]");
		return Plugin_Handled;	
	}
	if (args == 1)
	{
		decl String:name2[64];
		GetCmdArg(1,name2,sizeof(name2));
		decl String:query[256];
		FormatEx(query, sizeof(query), "UPDATE mapzone SET name = '%s' WHERE id = %d", name2, g_mapZones[g_clientLevel[client]][Id]);
		SQL_TQuery(g_hSQL, UpdateLevelCallback, query, client, DBPrio_Normal);	
		PrintToChat(client, "Set LevelName: %s for ZoneID: %d", name2, g_mapZones[g_clientLevel[client]][Id]);
	}
	return Plugin_Handled;	
}

public Action:Command_LevelID(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_zoneid [id]");
		return Plugin_Handled;	
	}
	if (args == 1)
	{
		decl String:name2[64];
		GetCmdArg(1, name2, sizeof(name2));
		
		decl String:query2[512];
		FormatEx(query2, sizeof(query2), "UPDATE mapzone SET level_id = '%s' WHERE id = %d", name2, g_mapZones[g_clientLevel[client]][Id]);
		SQL_TQuery(g_hSQL, UpdateLevelCallback, query2, client, DBPrio_Normal);	
		PrintToChat(client, "Set LevelID: %s for ZoneID: %d", name2, g_mapZones[g_clientLevel[client]][Id]);
	}
	return Plugin_Handled;	
}

public Action:Command_LevelType(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_zonetype");
		return Plugin_Handled;	
	}
	if (args == 1)
	{
		decl String:name2[64];
		GetCmdArg(1, name2, sizeof(name2));
		
		decl String:query2[512];
		FormatEx(query2, sizeof(query2), "UPDATE mapzone SET type = '%s' WHERE id = %d", name2, g_mapZones[g_clientLevel[client]][Id]);
		SQL_TQuery(g_hSQL, UpdateLevelCallback, query2, client, DBPrio_Normal);	
		PrintToChat(client, "Set Type: %s for ZoneID: %d", name2, g_mapZones[g_clientLevel[client]][Id]);
	}
	return Plugin_Handled;	
}

public UpdateLevelCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on UpdateZone: %s", error);
		return;
	}
	
	LoadMapZones();
}

public Action:Command_Stuck(client, args)
{
	if(!g_Settings[StuckEnable])
		return Plugin_Handled;
	
	if(!IsClientInGame(client)) 
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client)) 
		return Plugin_Handled;
	
	if(Timer_GetStatus(client) && g_Settings[StuckPenaltyTime] > 0)
	{
		Timer_AddPenaltyTime(client, g_Settings[StuckPenaltyTime]);
		CPrintToChatAll("%s %N used !stuck and got %ds penalty time.", PLUGIN_PREFIX2, client, RoundToFloor(g_Settings[StuckPenaltyTime]));
	}
	
	TeleLastCheckpoint(client);
	
	return Plugin_Handled;
}

public Action:Command_Restart(client, args)
{
	if(!g_Settings[RestartEnable])
		return Plugin_Handled;
	
	if(!IsClientInGame(client)) 
		return Plugin_Handled;
		
	if(Timer_GetMapzoneCount(ZtStart) < 1)
		return Plugin_Handled;
	
	if(g_timerTeams)
	{
		if(Timer_GetChallengeStatus(client) == 1 || Timer_GetCoopStatus(client) == 1)
		{
			ConfirmAbortMenu(client, SCMD_RESTART);
			return Plugin_Handled;
		}
	}
	
	Client_Restart(client);
	
	return Plugin_Handled;
}

public Action:Command_Start(client, args)
{
	if(!g_Settings[StartEnable])
		return Plugin_Handled;
		
	decl String:slevel[64];
	GetCmdArg(1, slevel, sizeof(slevel));
	new level = StringToInt(slevel);
	
	if(level > 0)
	{
		Timer_Reset(client);
		Tele_Level(client, level);
		return Plugin_Handled;
	}
	
	if(!IsClientInGame(client)) 
		return Plugin_Handled;
		
	if(Timer_GetMapzoneCount(ZtStart) < 1)
		return Plugin_Handled;
	
	if(g_timerTeams)
	{
		if(Timer_GetChallengeStatus(client) == 1 || Timer_GetCoopStatus(client) == 1)
		{
			ConfirmAbortMenu(client, SCMD_START);
			return Plugin_Handled;
		}
	}
	
	Client_Start(client);
	
	return Plugin_Handled;
}

public Action:Command_BonusRestart(client, args)
{
	if(!g_Settings[StartEnable])
		return Plugin_Handled;
	
	if(!IsClientInGame(client)) 
		return Plugin_Handled;
		
	if(Timer_GetMapzoneCount(ZtBonusStart) < 1)
		return Plugin_Handled;
	
	if(g_timerTeams)
	{
		if(Timer_GetChallengeStatus(client) == 1 || Timer_GetCoopStatus(client) == 1)
		{
			ConfirmAbortMenu(client, SCMD_BONUSSTART);
			return Plugin_Handled;
		}
	}
	
	Client_BonusRestart(client);
	
	return Plugin_Handled;
}

ConfirmAbortMenu(client, command)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_ConfirmAbortMenu);
		
		new mate;
		if(g_timerTeams) mate = Timer_GetClientTeammate(client);
		
		if(mate > 0)
		{
			if(Timer_GetChallengeStatus(client) == 1)
				SetMenuTitle(menu, "Are you sure to quit the Challenge?");
			else if(Timer_GetCoopStatus(client) == 1)
				SetMenuTitle(menu, "Are you sure to quit the Coop?");
		}else SetMenuTitle(menu, "Are you sure to quit?");
		
		if(command == SCMD_RESTART)
			AddMenuItem(menu, "restart", "Yes");
		else if(command == SCMD_START)
			AddMenuItem(menu, "start", "Yes");
		else if(command == SCMD_BONUSSTART)
			AddMenuItem(menu, "bonusstart", "Yes");
		
		AddMenuItem(menu, "no", "No");
		
		DisplayMenu(menu, client, 5);
	}
}

public Handle_ConfirmAbortMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "start"))
			{
				Client_Start(client);
			}
			else if(StrEqual(info, "restart"))
			{
				Client_Restart(client);
			}
			else if(StrEqual(info, "bonusstart"))
			{
				Client_BonusRestart(client);
			}
		}
	}
}

bool:Client_Start(client)
{
	if(!IsClientInGame(client)) 
		return false;
	
	//Has player a valid team
	if(GetClientTeam(client) != CS_TEAM_CT && GetClientTeam(client) != CS_TEAM_T)
	{
		new validteam = CS_GetValidSpawnTeam();
		
		if(validteam != CS_TEAM_NONE)
		{
			CS_SwitchTeam(client, validteam);
		}
		else Timer_LogError("No spawn points for %s", g_currentMap);
	}
	
	new mode = Timer_GetMode(client);
	
	//Stop timer
	Timer_Reset(client);
	
	//Is player alive
	if(!IsPlayerAlive(client)) 
	{
		CS_RespawnPlayer(client);
	}
	else
	{
		//Anti-Chat
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_Physics[mode][ModeTimeScale]);
		SetEntityGravity(client, g_Physics[mode][ModeGravity]);
	}
	
	//Teleport player to starzone
	Tele_Level(client, 1);
	
	return true;
}

bool:Client_Restart(client)
{
	if(!IsClientInGame(client)) 
		return false;
	
	//Has player a valid team
	if(GetClientTeam(client) != CS_TEAM_CT && GetClientTeam(client) != CS_TEAM_T)
	{
		new validteam = CS_GetValidSpawnTeam();
		
		if(validteam != CS_TEAM_NONE)
		{
			CS_SwitchTeam(client, validteam);
		}
		else Timer_LogError("No spawn points for %s", g_currentMap);
	}
	
	new mode = Timer_GetMode(client);
	
	//Stop timer
	Timer_Reset(client);
	
	new bool:respawn = true;
	
	//Is player alive
	if(!IsPlayerAlive(client)) 
	{
		CS_RespawnPlayer(client);
		respawn = false;
	}
	else
	{
		//Anti-Chat
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_Physics[mode][ModeTimeScale]);
		SetEntityGravity(client, g_Physics[mode][ModeGravity]);
	}
	
	//Teleport player to starzone
	if(g_Settings[TeleportOnRestart])
	{
		Tele_Level(client, 1);
	} 
	//Or just respawn him
	else if(respawn)
	{
		CS_RespawnPlayer(client);
	}
	
	return true;
}

bool:Client_BonusRestart(client)
{
	if(!IsClientInGame(client)) 
		return false;
	
	//Has player a valid team
	if(GetClientTeam(client) != CS_TEAM_CT && GetClientTeam(client) != CS_TEAM_T)
	{
		new validteam = CS_GetValidSpawnTeam();
		
		if(validteam != CS_TEAM_NONE)
		{
			CS_SwitchTeam(client, validteam);
		}
		else Timer_LogError("No spawn points for %s", g_currentMap);
	}
	
	new mode = Timer_GetMode(client);
	
	//Stop timer
	Timer_Reset(client);
	
	//Is player alive
	if(!IsPlayerAlive(client)) 
	{
		CS_RespawnPlayer(client);
	}
	else
	{
		//Anti-Chat
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_Physics[mode][ModeTimeScale]);
		SetEntityGravity(client, g_Physics[mode][ModeGravity]);
	}
	
	//Teleport player to bonus-starzone
	Tele_Level(client, 1001);
	
	return true;
}

public Action:Command_AdminZone(client, args)
{
	AdminZoneTeleport(client);
	return Plugin_Handled;
}

AdminZoneTeleport(client)
{
	new Handle:menu = CreateMenu(MenuHandlerAdminZone);
	SetMenuTitle(menu, "Zone Selection");
	
	for (new zone = 0; zone < g_mapZonesCount; zone++)
	{
		decl String:zone_name[32];
		FormatEx(zone_name, sizeof(zone_name), "%s", g_mapZones[zone][zName]);
		
		decl String:zone_id[32];
		FormatEx(zone_id,sizeof(zone_id), "%d", zone);
		AddMenuItem(menu, zone_id, zone_name);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandlerAdminZone(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
		new zone = StringToInt(info);
		if(found)
		{
			Timer_Reset(client);
			Tele_Zone(client, zone);
		}
	}
}

public Action:Command_Levels(client, args)
{
	if(!g_Settings[LevelTeleportEnable])
		return Plugin_Handled;

	decl String:slevel[64];
	GetCmdArg(1, slevel, sizeof(slevel));
	new level = StringToInt(slevel);
	
	if(level > 0)
	{
		Timer_Reset(client);
		Tele_Level(client, level);
		return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(MenuHandlerLevels);
	SetMenuTitle(menu, "Stage Teleport Selection");
	
	for (new zone = 0; zone < g_mapZonesCount; zone++)
	{
		if(g_mapZones[zone][Level_Id] < 1)
		{
			continue;
		}
		
		decl String:zone_name[32];
		FormatEx(zone_name, sizeof(zone_name), "%s", g_mapZones[zone][zName]);
		
		decl String:zone_id[32];
		FormatEx(zone_id,sizeof(zone_id), "%d", zone);
		AddMenuItem(menu, zone_id, zone_name);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public MenuHandlerLevels(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
		new zone = StringToInt(info);
		if(found)
		{
			Timer_Reset(client);
			Tele_Zone(client, zone);
		}
	}
}

public Native_AddMapZone(Handle:plugin, numParams)
{
	decl String:map[32];
	GetNativeString(1, map, sizeof(map));
	
	new MapZoneType:type = GetNativeCell(2);	
	
	decl String:name[32];
	GetNativeString(1, name, sizeof(name));
	
	new level_id = GetNativeCell(2);
	
	new Float:point1[3];
	GetNativeArray(3, point1, sizeof(point1));
	
	new Float:point2[3];
	GetNativeArray(3, point2, sizeof(point2));
	
	AddMapZone(map, type, name, level_id, point1, point2);
}

public Native_ClientTeleportLevel(Handle:plugin, numParams)
{
	Tele_Level(GetNativeCell(1), GetNativeCell(2));
}

public Native_GetClientLevel(Handle:plugin, numParams)
{
	return g_clientLevel[GetNativeCell(1)];
}

public Native_GetClientLevelID(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(client && Client_IsValid(client, true) && g_clientLevel[client] >= 0 && g_clientLevel[client] > 0)
	{
		return g_mapZones[g_clientLevel[client]][Level_Id];
	}
	else return 0;
}

public Native_GetLevelName(Handle:plugin, numParams)
{
	new id = GetNativeCell(1);
	new nlen = GetNativeCell(3); 
	if (nlen <= 0)
		return false;
	
	for (new i = 0; i < g_mapZonesCount; i++)
	{
		if(g_mapZones[i][Level_Id] == id)
		{
			decl String:buffer[nlen];
			FormatEx(buffer, nlen, "%s", g_mapZones[id][zName]);
			if (SetNativeString(2, buffer, nlen, true) == SP_ERROR_NONE)
				return true;
		}
	}
	
	return false;
}

public Native_SetClientLevel(Handle:plugin, numParams)
{
	g_clientLevel[GetNativeCell(1)] = GetNativeCell(2);
}

public Native_SetIgnoreEndTouchStart(Handle:plugin, numParams)
{
	g_iIgnoreEndTouchStart[GetNativeCell(1)] = GetNativeCell(2);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(g_Settings[NoblockEnable])
	{
		if (StrEqual(classname, "hegrenade_projectile"))
		{
			SetNoBlock(entity);
		} else if (StrEqual(classname, "flashbang_projectile"))
		{
			SetNoBlock(entity);
		} else if (StrEqual(classname, "smokegrenade_projectile"))
		{
			SetNoBlock(entity);
		}
	}
}

public Native_IsPlayerTouchingZoneType(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new MapZoneType:type = GetNativeCell(2);
	
	for (new i = 0; i < g_mapZonesCount; i++)
	{
		if(g_mapZones[i][Type] != type)
			continue;
		
		if(g_bZone[i][client])
			return 1;
	}
	return 0;
}

public Native_GetMapzoneCount(Handle:plugin, numParams)
{
	new MapZoneType:type = GetNativeCell(1);
	
	new count = 0;

	if(type == ZtLevel || type == ZtBonusLevel)
	{
		new LevelID[g_mapZonesCount];
		for (new mapZone = 0; mapZone < g_mapZonesCount; mapZone++)
		{
			if (g_mapZones[mapZone][Type] == type)
			{
				LevelID[mapZone] = g_mapZones[mapZone][Level_Id];
			}
		}
		
		SortIntegers(LevelID, g_mapZonesCount, Sort_Ascending);
		
		new lastlevel;
		
		for (new mapZone = 0; mapZone < g_mapZonesCount; mapZone++)
		{
			if (LevelID[mapZone] > lastlevel)
			{
				count++;
				lastlevel = LevelID[mapZone];
			}
		}
	}
	else
	{
		for (new mapZone = 0; mapZone < g_mapZonesCount; mapZone++)
		{
			if (g_mapZones[mapZone][Type] == type)
			{
				count++;
			}
		}
	}
	
	return count;
}

public bool:FilterOnlyPlayers(entity, contentsMask, any:data)
{
	if(entity != data && entity > 0 && entity <= MaxClients) 
		return true;
	return false;
}

stock FindCollisionGroup()
{
	g_ioffsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
}

// For Noblock
stock SetNoBlock(entity)
{
	SetEntData(entity, g_ioffsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, 4, true);
}

// For Block
stock SetBlock(entity)
{
	SetEntData(entity, g_ioffsCollisionGroup, COLLISION_GROUP_PLAYER, 4, true);
}

// For Push
stock SetPush(entity)
{
	SetEntData(entity, g_ioffsCollisionGroup, COLLISION_GROUP_PUSHAWAY, 4, true);
}

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (StrContains(sample, "door") != -1)
		return Plugin_Stop;
	
	if (StrContains(sample, "button") != -1)
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new bool:ff = GetConVarBool(g_hFF); 
	new mode = Timer_GetMode(victim);

	if (g_Settings[Godmode])
	{
		if (attacker == 0 || attacker >= MaxClients)
		{
			if(g_Physics[mode][ModeAllowWorldDamage])
			{
				return Plugin_Continue;
			}
		
			return Plugin_Handled;
		}
	
		//Player can hurt each other
		if(g_bHurt[victim] && g_bHurt[attacker])
		{
			return Plugin_Continue;
		}

		return Plugin_Handled;
	}

	if(g_bHurt[victim] && g_bHurt[attacker])
	{
		return Plugin_Continue;
	}
	
	if (attacker == 0 || attacker >= MaxClients)
	{
		if(g_Physics[mode][ModeAllowWorldDamage])
		{
			return Plugin_Continue;
		}
	}
	else if(GetClientTeam(victim) == GetClientTeam(attacker))
	{
		if(ff)
		{
			return Plugin_Continue;
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock RemovePunchAngle(client)
{
	if(GetGameMod() == MOD_CSS)
	{
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", NULL_VECTOR);
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", NULL_VECTOR);
	}
}
