/* ========================================================
 * L4D & L4D2 MultiTanks
 * ========================================================
 * Created by Red Alex
 * Spawn multiply tanks instead of one
 * ========================================================
*/

/*
Version 1.6 (16.03.11)
- Fixed tank dissapears when more then one tank alive and one of them lose control
- Added tanks HUD (mt_showhud)
- Added translations
- Added tank teleport from some bad spawns
- Added specific isFinalMap check for c4m4_milltown_b map
- Change Tank dedecting system from model to class
- Improve final map detected

Version 1.5 (27.01.10)
- Left 4 Dead 2 Support added
- New spawning system
- Increased maximum tank count to 65535
- Increased maxmimum spawn delay to 65535 seconds
- Added commands for spawn tanks (mt_spawnbot)
- Fixed bug, caused by very fast tank control changes
- Improved Debug logs (1 - debug in file, 2 - debug in file and chat)

Version 1.4.4 (04.09.09)
- Instant Multiply check disabled for Versus
- Added first map after server started fix

Version 1.4.3 (04.09.09)
- Fixed check for spawning additional tanks
- Reverse Instant Multiply spawn check
- Added specific isFinalMap check for l4d_garage01_alleys

Version 1.4.1 (03.09.09)
- Removed debug messages

Version 1.4 (02.09.09)
- Renamed l4d_multianks.sp to l4d_multitanks.sp
- Fixed bug causes addition spawns when tank frustrated and control going to bot
- Fixed bug causes addition spawns when tank owner change the team or disconnect
- Increased tank count to 32
- Added CVAR for tank spawn together when esape start CVAR (mt_spawntogether_escape)
- Added CVAR for spawn delay between tanks spawns wneh escape start (mt_spawndelay_escape)
- Added CVAR's for second wave in final (mt_count_finalestart2_* and mt_health_finalestart2_*)

Version 1.3 (19.09.09)
- Improved Debug Logs
- Added check for Instant Multi Spawns (Fixes bugs in COOP)
- Fixed some spelling errors (MatState to MapState, regual to regular)
- Renamed config file from multitanks.cfg to l4d_multitanks.cfg
- Added command for refresh tanks settings
- Adder CVAR for tanks to spawn together
- Rename multitanks_version to l4d_multitanks_version

Version 1.2 (08.09.09)
- Added specific isFinalMap check for l4d_vs_smalltown04_mainstreet and l4d_smalltown04_mainstreet
- Rename mt_version to multitanks_version

Version 1.1 (04.09.09)
- Added different CVARs for coop/survival/versus
- Added different CVARs for regular/final/escape tanks

Version 1.0 (26.08.09)
- Code Refactoring
- Added support for non SuperVersus
- Added check for tank dissapearing
- Added report for MaximumHP when tank changes control
- Public release

Version 0.9  (18.08.09)
- Improved spawn tank detected
- Added check for connected and ingame for SetTankHP

Version 0.8  (11.08.09)
- CVAR added

Version 0.7 (08.08.09)
- Initial Release

*/


#include <sourcemod>
#include <sdktools>

#define CONSISTENCY_CHECK	1.0
#define PLUGIN_VERSION "1.6"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

#define GM_UNKNOWN = 0
#define GM_COOP = 1
#define GM_VERSUS = 2
#define GM_SURVIVAL = 3
#define GM_SCAVENGE = 4

#define MS_UNKNOWN = 0
#define MS_ROUNDSTART = 1
#define MS_FINAL = 2
#define MS_ESCAPE = 3
#define MS_LEAVING = 4
#define MS_ROUNDEND = 5

new TanksSpawned = 0;
new TanksToSpawn=0;
new TanksMustSpawned=0;
new TanksFrustrated = 0;
new DefaultMaxZombies = 0;

new bool:g_IsFinalMap;
new g_GameMode;
new g_MTHealth;
new g_MTCount;
new g_MapState;
new g_Wave;
new g_Multiply;
new Float:g_FirstTankPos[3];

new Float:g_BoxA[10][3];
new Float:g_BoxB[10][3];
new Float:g_SpawnPos[10][3];
new bool:g_SpawnFix;
new g_SpawnFixes;

new propinfoburn = - 1;

new Handle:CurrentGameMode = INVALID_HANDLE;

new Handle:MTDebug	= INVALID_HANDLE;
new Handle:MTOn		= INVALID_HANDLE;

new Handle:MTCountRegularCoop	= INVALID_HANDLE;
new Handle:MTHealthRegularCoop	= INVALID_HANDLE;
new Handle:MTHealthFinaleCoop	= INVALID_HANDLE;
new Handle:MTCountFinaleCoop	= INVALID_HANDLE;
new Handle:MTHealthFinaleStartCoop	= INVALID_HANDLE;
new Handle:MTCountFinaleStartCoop	= INVALID_HANDLE;
new Handle:MTHealthFinaleStart2Coop	= INVALID_HANDLE;
new Handle:MTCountFinaleStart2Coop	= INVALID_HANDLE;
new Handle:MTHealthEscapeStartCoop	= INVALID_HANDLE;
new Handle:MTCountEscapeStartCoop	= INVALID_HANDLE;

new Handle:MTHealthRegularVersus	= INVALID_HANDLE;
new Handle:MTCountRegularVersus	= INVALID_HANDLE;
new Handle:MTHealthFinaleVersus	= INVALID_HANDLE;
new Handle:MTCountFinaleVersus	= INVALID_HANDLE;
new Handle:MTHealthFinaleStartVersus	= INVALID_HANDLE;
new Handle:MTCountFinaleStartVersus	= INVALID_HANDLE;
new Handle:MTHealthFinaleStart2Versus	= INVALID_HANDLE;
new Handle:MTCountFinaleStart2Versus	= INVALID_HANDLE;
new Handle:MTHealthEscapeStartVersus	= INVALID_HANDLE;
new Handle:MTCountEscapeStartVersus	= INVALID_HANDLE;

new Handle:MTHealthSurvival	= INVALID_HANDLE;
new Handle:MTCountSurvival		= INVALID_HANDLE;

new Handle:MTHealthScavenge	= INVALID_HANDLE;
new Handle:MTCountScavenge	= INVALID_HANDLE;

new Handle:AnnounceTankHP	= INVALID_HANDLE;
new Handle:MTAutoSpawn	= INVALID_HANDLE;
new Handle:MTSpawnTogether	= INVALID_HANDLE;
new Handle:MTSpawnTogetherFinal	= INVALID_HANDLE;
new Handle:MTSpawnTogetherEscape	= INVALID_HANDLE;
new Handle:MTSpawnDelay	= INVALID_HANDLE;
new Handle:MTSpawnCheck	= INVALID_HANDLE;
new Handle:MTSpawnDelayEscape	= INVALID_HANDLE;

new Handle:SpawnTimer    		= INVALID_HANDLE;
new Handle:CheckTimer    		= INVALID_HANDLE;

new Handle:MTShowHUD	= INVALID_HANDLE;

new bool:IsTank[MAXPLAYERS+1];
new bool:IsFrustrated[MAXPLAYERS+1];
new Frustrates[MAXPLAYERS+1];
new bool:IsRoundStarted;
new bool:IsRoundEnded;

new Handle:logfile;

static const L4D_ZOMBIECLASS_TANK						= 5;
static const L4D2_ZOMBIECLASS_TANK						= 8;

new ZC_TANK;

new infectedClass[MAXPLAYERS+1];
new bool:resetGhostState[MAXPLAYERS+1];
new bool:resetIsAlive[MAXPLAYERS+1];
new bool:resetLifeState[MAXPLAYERS+1];
new bool:restoreStatus[MAXPLAYERS+1];

new Float:HUD_UPDATE_INTERVAL		= 1.0;
new Handle:g_hHUD	= INVALID_HANDLE;
new Handle:HUDTimer    		= INVALID_HANDLE;

public bool:isSuperVersus()
{
	if(FindConVar("sm_superversus_version") != INVALID_HANDLE) return true;
	else return false;
}

public Plugin:myinfo = {
	name = "[L4D & L4D2] MultiTanks",
	author = "Red Alex ",
	description = "Spawns Multi Tanks instead of 1",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=101781"
};

public OnPluginStart()
{
	LoadTranslations("l4dmultitanks.phrases");

	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if(StrEqual(game, "left4dead2") )
		ZC_TANK = L4D2_ZOMBIECLASS_TANK; else
		ZC_TANK = L4D_ZOMBIECLASS_TANK; 

	RegAdminCmd("mt_refresh", Command_RefreshSettings, ADMFLAG_GENERIC, "Refresh tanks settings");
	RegAdminCmd("mt_test", Command_MTTest, ADMFLAG_GENERIC, "Print debug info");
	RegAdminCmd("mt_test2", Command_MTTest2, ADMFLAG_GENERIC, "Print debug info");
	RegAdminCmd("mt_spawnbot", Command_MTSpawnBot, ADMFLAG_GENERIC, "Spawn bot tank");

	propinfoburn = FindSendPropInfo("CTerrorPlayer", "m_burnPercent");

	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("tank_frustrated", Event_TankFrustrated);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	HookEvent("finale_start", Event_finale_start);
	HookEvent("finale_escape_start", Event_finale_escape_start);
	HookEvent("finale_vehicle_leaving", Event_finale_vehicle_leaving);

//	HookEvent("player_team", PlayerTeam);

	MTOn = CreateConVar("mt_enabled","1","Enabled MultiTanks?", CVAR_FLAGS,true,0.0,true,1.0);

	CreateConVar("l4d_multitanks_version", PLUGIN_VERSION, "[L4D & L4D2] MultiTanks version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	MTHealthRegularCoop = CreateConVar("mt_health_regular_coop","6000.0","Tanks health on regular maps in coop", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountRegularCoop = CreateConVar("mt_count_regular_coop","1","Count of total tanks on regular maps in coop", CVAR_FLAGS,true,1.0,true,65535.0);
	MTHealthFinaleCoop = CreateConVar("mt_health_finale_coop","6000.0","Tanks health on final maps in coop", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountFinaleCoop = CreateConVar("mt_count_finale_coop","1","Count of total tanks on final maps in coop", CVAR_FLAGS,true,1.0,true,65535.0);
	MTHealthFinaleStartCoop = CreateConVar("mt_health_finalestart_coop","6000.0","Tanks health when final start in coop", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountFinaleStartCoop = CreateConVar("mt_count_finalestart_coop","1","Count of total tanks when final start in coop", CVAR_FLAGS,true,1.0,true,65535.0);
	MTHealthFinaleStart2Coop = CreateConVar("mt_health_finalestart2_coop","6000.0","Tanks health in second wave after final start in coop", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountFinaleStart2Coop = CreateConVar("mt_count_finalestart2_coop","1","Count of total tanks in second wave after final start in coop", CVAR_FLAGS,true,1.0,true,65535.0);
	MTHealthEscapeStartCoop = CreateConVar("mt_health_escapestart_coop","6000.0","Tanks health when escape start in coop", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountEscapeStartCoop = CreateConVar("mt_count_escapestart_coop","1","Count of total tanks when escape start in coop", CVAR_FLAGS,true,1.0,true,65535.0);

	MTHealthRegularVersus = CreateConVar("mt_health_regular_versus","6000.0","Tanks health on regular maps in versus", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountRegularVersus = CreateConVar("mt_count_regular_versus","1","Count of total tanks on regular maps in versus", CVAR_FLAGS,true,1.0,true,65535.0);
	MTHealthFinaleVersus = CreateConVar("mt_health_finale_versus","6000.0","Tanks health on final maps in versus", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountFinaleVersus = CreateConVar("mt_count_finale_versus","1","Count of total tanks on final maps in versus", CVAR_FLAGS,true,1.0,true,65535.0);
	MTHealthFinaleStartVersus = CreateConVar("mt_health_finalestart_versus","6000.0","Tanks health when final start in versus", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountFinaleStartVersus = CreateConVar("mt_count_finalestart_versus","1","Count of total tanks when final start in versus", CVAR_FLAGS,true,1.0,true,65535.0);
	MTHealthFinaleStart2Versus = CreateConVar("mt_health_finalestart2_versus","6000.0","Tanks health in second wave after final start in versus", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountFinaleStart2Versus = CreateConVar("mt_count_finalestart2_versus","1","Count of total tanks in second wave after final start in versus", CVAR_FLAGS,true,1.0,true,65535.0);
	MTHealthEscapeStartVersus = CreateConVar("mt_health_escapestart_versus","6000.0","Tanks health when escape start in versus", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountEscapeStartVersus = CreateConVar("mt_count_escapestart_versus","1","Count of total tanks when escape start in versus", CVAR_FLAGS,true,1.0,true,65535.0);

	MTHealthSurvival = CreateConVar("mt_health_survival","4000.0","Tanks health in survival", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountSurvival = CreateConVar("mt_count_survival","1","Count of total tanks in survival", CVAR_FLAGS,true,1.0,true,65535.0);

	MTHealthScavenge = CreateConVar("mt_health_scavenge","4000.0","Tanks health in scavenge", CVAR_FLAGS,true,0.0,true,65535.0);
	MTCountScavenge = CreateConVar("mt_count_scavenge","1","Count of total tanks in scavenge", CVAR_FLAGS,true,1.0,true,65535.0);

	MTDebug = CreateConVar("mt_debug","0","Enabled Debug?", CVAR_FLAGS,true,0.0,true,2.0);
	AnnounceTankHP = CreateConVar("mt_tankhp_announce","1","Say about tank HP?", CVAR_FLAGS,true,0.0,true,1.0);
	MTAutoSpawn = CreateConVar("mt_autospawn","1","Tanks spawn auto?", CVAR_FLAGS,true,0.0,true,1.0);
	MTSpawnTogether = CreateConVar("mt_spawntogether","0","Tanks spawns together?", CVAR_FLAGS,true,0.0,true,1.0);
	MTSpawnTogetherFinal = CreateConVar("mt_spawntogether_final","0","Tanks spawns together in final?", CVAR_FLAGS,true,0.0,true,1.0);
	MTSpawnTogetherEscape = CreateConVar("mt_spawntogether_escape","0","Tanks spawns together when escape start?", CVAR_FLAGS,true,0.0,true,1.0);
	MTSpawnDelay = CreateConVar("mt_spawndelay","2.0","Delay between Tanks spawns", CVAR_FLAGS,true,0.1,true,65535.0);
	MTSpawnDelayEscape = CreateConVar("mt_spawndelay_escape","2.0","Delay between Tanks spawns when escape start", CVAR_FLAGS,true,0.1,true,65535.0);
	MTSpawnCheck = CreateConVar("mt_spawncheck","8.0","Time when check that all tanks spawned", CVAR_FLAGS,true,1.0,true,20.0);

	MTShowHUD = CreateConVar("mt_showhud","1","Show Tanks HUD?", CVAR_FLAGS,true,0.0,true,1.0);


	CurrentGameMode = FindConVar("mp_gamemode");
	HookConVarChange(CurrentGameMode,OnCVGameModeChange);

	AutoExecConfig(true, "l4d_multitanks");

	CreateTimer(1.0, MapStart);

	logfile = OpenFile("/addons/sourcemod/logs/multitanks_log.txt", "w");
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.2, TankSpawn, GetEventInt(event, "userid"));
}

public Action:TankSpawn(Handle:timer, any:userid) 
{
	if (! GetConVarInt(MTOn) )
		return;

//	new client = GetClientOfUserId(GetEventInt(event, "userid"));
//	new tankid = GetEventInt(event, "tankid");

	new client =  GetClientOfUserId(userid);
	new tankid = 0;

//	SetEntProp(client, Prop_Send, "m_frustration", 0)

	// Tank instantly change owner, so skip this spawn
	if (client == 0)
		return;

	if (GetConVarInt(MTDebug))
	{

		if (IsFakeClient(client))
			PrintDebug("[TANK] TankSpawn [FAKE] [%d,%d]",tankid,client); else 
			PrintDebug("[TANK] TankSpawn [REAL] [%d,%d]",tankid,client);
		if (TanksFrustrated > 0)
			PrintDebug("[TANK] Its just FRUSTRATED");
		Command_MTTest(0,0);
	}


	new bool: isNew = true;
	decl maxclients;
	maxclients = GetMaxClients();
	new bool: isTankClient = false;
//	decl String:stringclass[32];
	new TotalCount = 0;
	new Float:Pos[3];
	for (new i=1 ; i<=maxclients ; i++)
	{	
		isTankClient = false;
		if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == 3))
		{
//			GetClientModel(i, stringclass, 32);
			if (IsPlayerTank(i))
			{
				isTankClient = true;
				TotalCount++;
				if (GetConVarInt(MTDebug))
				{
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", Pos);

					if (IsFakeClient(i))
						PrintDebug("[TANK] === [FAKE] [%d] [%d,%d,%d] [%f,%f,%f]",i, IsClientConnected(i), IsClientInGame(i), GetClientTeam(i), Pos[0],Pos[1],Pos[2]); else 
						PrintDebug("[TANK] === [REAL] [%d] [%d,%d,%d] [%f,%f,%f]",i, IsClientConnected(i), IsClientInGame(i), GetClientTeam(i), Pos[0],Pos[1],Pos[2]);
				}
			}
		}

	
		if (GetConVarInt(MTDebug))
		{
//			PrintDebug("[TANK] [%d] [%d,%d]",i, IsTank[i], isTankClient);
		}

		if (IsTank[i] && !isTankClient) // Tank changes owner
		{	
			if (GetConVarInt(MTDebug))
			{
				PrintDebug("[TANK] [%d] Tank changes owner", i);
			}
			IsTank[i] = false;
			IsFrustrated[i] = false;
			isNew = false;
		} else
/*
		if (IsTank[i] && isTankClient && IsFrustrated[i]) // Tank frustrated, but is still tank
		{	
			if (GetConVarInt(MTDebug))
			{
				PrintDebug("[TANK] [%d] Tank frustrated, but is still tank", i);
			}
			IsTank[i] = false;
			IsFrustrated[i] = false;
			isNew = false;
		} else
*/
		if ((g_GameMode != 2) && (i != client) && !IsTank[i] && isTankClient) //  Multiply Instant spawns [Only for COOP and Survival]
		{
			if (GetConVarInt(MTDebug))
			{
				PrintDebug("[TANK] [%d] Multiply Instant spawns", i);
			}
			g_Multiply++;
//			IsTank[i] = true;
//			isTank[client] = true;
		}

	}
	
	// Skip first multiply
	if (g_Multiply == 1)
		return;

	if (!IsFakeClient(client))
		CreateTimer(10.0, CheckFrustration, client);

	if (g_SpawnFix)
	{
		new Float:g_TankPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin",g_TankPos);
		PrintToServer("Fix %f,%f,%f", g_TankPos[0], g_TankPos[1], g_TankPos[2]);
		for (new k=0; k < g_SpawnFixes; k++)
		{
			if ((g_TankPos[0] >= g_BoxA[k][0]) && (g_TankPos[0] <= g_BoxB[k][0]) && (g_TankPos[1] >= g_BoxA[k][1]) && (g_TankPos[1] <= g_BoxB[k][1]))
			{
				PrintToServer("Telepor To %f,%f,%f" ,g_SpawnPos[k][0],g_SpawnPos[k][1], g_SpawnPos[k][2]);
				SetEntPropVector(client, Prop_Data, "m_vecOrigin",g_SpawnPos[k]);
			}
		}
	}

	Frustrates[client] = 0;
	if (!IsTank[client])
	{
		IsTank[client] = true;
		if (isNew)
		{
			// NEW TANK
			if (GetConVarInt(MTDebug))
			{
				PrintDebug("[TANK] This is NEW Tank [%d], [Total Count = %d]", TanksSpawned+1, TotalCount);
			}

			SetTankHP(client);

			TanksSpawned++;
			TanksMustSpawned--;

			// If it is first tank, then spawn additional tanks
			if (TanksSpawned == 1)
			{		
				if ((HUDTimer == INVALID_HANDLE) && GetConVarInt(MTShowHUD))
					HUDTimer = CreateTimer(HUD_UPDATE_INTERVAL, HUD_Timer, _, TIMER_REPEAT);
				if (GetConVarInt(MTDebug))
				{
					PrintDebug("[TANK] This is first tank");
				}
				
				if (g_MapState == 2)
				{
					g_Wave++;
					CalculateTanksParamaters();
					if (GetConVarInt(MTDebug))
					{
						PrintDebug("[TANK] Final, Wave = %d", g_Wave);
					}
				}


				GetEntPropVector(client, Prop_Data, "m_vecOrigin",g_FirstTankPos);

				SaveAndInreaseMaxZombies(g_MTCount);
				TanksMustSpawned=0;
				TanksToSpawn = g_MTCount - 1;
				if (GetConVarInt(MTDebug))
				{
					PrintDebug("[TANK] Spawn Additional Timer");
				}
				SpawnTimer = CreateTimer(((g_MapState==3) ? GetConVarFloat(MTSpawnDelayEscape) : GetConVarFloat(MTSpawnDelay)), SpawnAdditionalTank, client);

			} else
			{

				if ((g_MapState==2) ? GetConVarInt(MTSpawnTogetherFinal) : (g_MapState==3) ? GetConVarInt(MTSpawnTogetherEscape) : GetConVarInt(MTSpawnTogether))
				{
					SetEntPropVector(client, Prop_Data, "m_vecOrigin",g_FirstTankPos);
				}

			}

			// If it is the last additional tank
			if (TanksSpawned==g_MTCount)
			{
				g_Multiply=0;
				TanksSpawned=0;
				TanksMustSpawned=0;
				if (SpawnTimer != INVALID_HANDLE) {KillTimer(SpawnTimer); SpawnTimer = INVALID_HANDLE;}
				if (CheckTimer != INVALID_HANDLE) {KillTimer(CheckTimer); CheckTimer = INVALID_HANDLE;}
				RestoreMaxZombies();
			} // last tank
		} else // new tank
		{
			// Control Transfer
			TanksFrustrated--;
			if (!IsFakeClient(client))
				SetTankMaximumHP(client);
		}
	} // unique tank
	else
	{
		IsTank[client] = false;
//		ForcePlayerSuicide(client);
	}
	return;
}


public Event_TankFrustrated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
//	IsTank[client] = false;
	IsFrustrated[client] = true;
	TanksFrustrated++;
//	SetEntProp(client, Prop_Send, "m_frustration", 0)

	new String:PlayerName[200];
	GetClientName(client, PlayerName, sizeof(PlayerName));

	for (new i=1 ; i<=MaxClients; i++)
	{	
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 3)
			{
				PrintToChat(i, "\x04[MT]\x01 %s %t", PlayerName, "loose tank control");
			}
		}
	}

	if (GetConVarInt(MTDebug))
	{
		PrintDebug("[TANK] TankFrustrated [%d]",client);
	}

	return;		
}

public Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(MTDebug))
	{
		PrintDebug("[TANK] TankKillled [%d]",client);
	}

//	TankDie(client);

}

public CalculateTanksParamaters()
{
	switch (g_GameMode)
	{
		case 1:
		{
			switch (g_MapState)
			{
				case 1:
				{
					g_MTHealth = g_IsFinalMap ? GetConVarInt(MTHealthFinaleCoop) : GetConVarInt(MTHealthRegularCoop); 	
					g_MTCount = g_IsFinalMap ? GetConVarInt(MTCountFinaleCoop) : GetConVarInt(MTCountRegularCoop); 	
				}

				case 2:
				{
					g_MTHealth = (g_Wave == 2) ? GetConVarInt(MTHealthFinaleStart2Coop) : GetConVarInt(MTHealthFinaleStartCoop);
					g_MTCount = (g_Wave == 2) ? GetConVarInt(MTCountFinaleStart2Coop) : GetConVarInt(MTCountFinaleStartCoop);
				}

				case 3:
				{
					g_MTHealth = GetConVarInt(MTHealthEscapeStartCoop);
					g_MTCount = GetConVarInt(MTCountEscapeStartCoop);
				}

				case 4: g_MTCount = 0;
				case 5: g_MTCount = 0;
			}

		}

		case 2: 
		{
			switch (g_MapState)
			{
				case 1:
				{
					g_MTHealth = g_IsFinalMap ? GetConVarInt(MTHealthFinaleVersus) : GetConVarInt(MTHealthRegularVersus); 	
					g_MTCount = g_IsFinalMap ? GetConVarInt(MTCountFinaleVersus) : GetConVarInt(MTCountRegularVersus); 	
				}

				case 2:
				{
					g_MTHealth = (g_Wave == 2) ? GetConVarInt(MTHealthFinaleStart2Versus) : GetConVarInt(MTHealthFinaleStartVersus);
					g_MTCount =  (g_Wave == 2) ? GetConVarInt(MTCountFinaleStart2Versus) : GetConVarInt(MTCountFinaleStartVersus);
				}

				case 3:
				{
					g_MTHealth = GetConVarInt(MTHealthEscapeStartVersus);
					g_MTCount = GetConVarInt(MTCountEscapeStartVersus);
				}

				case 4: g_MTCount = 0;
				case 5: g_MTCount = 0;
			}
		}

		case 3: 
		{
			g_MTHealth = GetConVarInt(MTHealthSurvival);
			g_MTCount = GetConVarInt(MTCountSurvival);
		}
	
		case 4: 
		{
			g_MTHealth = GetConVarInt(MTHealthScavenge);
			g_MTCount = GetConVarInt(MTCountScavenge);
		}

		case 0: 
		{
			g_MTHealth = 6000;
			g_MTCount = 1;
		}
	}

	if (GetConVarInt(MTDebug))
	{
		PrintDebug("[TANK] GameMode = %d, MapState = %d [%d Wave] [F=%d] (%d x %d)", g_GameMode, g_MapState, g_Wave, g_IsFinalMap, g_MTCount, g_MTHealth);
		PrintToServer("[TANK] GameMode = %d, MapState = %d [%d Wave] [F=%d] (%d x %d)", g_GameMode, g_MapState, g_Wave, g_IsFinalMap, g_MTCount, g_MTHealth);
	}
}

public Action:MapStart(Handle:timer)
{
	// Called 1 second after OnPluginStart since srcds does not log the first map loaded. Idea from Stormtrooper's "mapfix.sp" for psychostats
	OnMapStart();
}

public OnMapStart()
{
	g_GameMode = l4d_gamemode();
	g_IsFinalMap = IsFinalMap();	
	CalculateTanksParamaters();

	new String:g_MapName[64];
	GetCurrentMap(g_MapName, 64);

	g_SpawnFix = false;
	if (StrEqual(g_MapName, "l4d_vs_hospital03_sewers"))
	{
		g_SpawnFix = true;
		g_SpawnFixes = 1;
		g_BoxA[0][0] = 9728.0;
		g_BoxA[0][1] = 5735.0; 
		g_BoxB[0][0] = 12985.0;
		g_BoxB[0][1] = 8752.0; 
		g_SpawnPos[0][0] = 12984.0; 
		g_SpawnPos[0][1] = 6117.0;
		g_SpawnPos[0][2] = 382.0;
	} else
	if (StrEqual(g_MapName, "l4d_vs_farm03_bridge"))
	{
		g_SpawnFix = true;
		g_SpawnFixes = 1;
		g_BoxA[0][0] = 3152.0;
		g_BoxA[0][1] = -14879.0; 
		g_BoxB[0][0] = 10347.0;
		g_BoxB[0][1] = -13231.0; 
		g_SpawnPos[0][0] = 6041.0; 
		g_SpawnPos[0][1] = -12145.0;
		g_SpawnPos[0][2] = 382.0;
	} 
	if (StrEqual(g_MapName, "l4d_vs_airport03_garage"))
	{
		g_SpawnFix = true;
		g_SpawnFixes = 2;
		g_BoxA[0][0] = -8128.0;
		g_BoxA[0][1] = -7478.0; 
		g_BoxB[0][0] = -2128.0;
		g_BoxB[0][1] = -1969.0; 
		g_SpawnPos[0][0] = -6399.9; 
		g_SpawnPos[0][1] = -655.5;
		g_SpawnPos[0][2] = 542.0;

		g_BoxA[1][0] = -5887.0;
		g_BoxA[1][1] = -5159.0; 
		g_BoxB[1][0] = 1960.0;
		g_BoxB[1][1] = 4980.0; 
		g_SpawnPos[1][0] = -5119.9; 
		g_SpawnPos[1][1] =  1723.6;
		g_SpawnPos[1][2] = 546.0;
	}

	if (StrEqual(g_MapName, "l4d_river01_docks"))
	{
		g_SpawnFix = true;
		g_SpawnFixes = 1;
		g_BoxA[0][0] = 6780.7;
		g_BoxA[0][1] = 420.1; 
		g_BoxB[0][0] = 7171.3;
		g_BoxB[0][1] = 953.7; 
		g_SpawnPos[0][0] = 7366.0; 
		g_SpawnPos[0][1] = 1412.7;
		g_SpawnPos[0][2] = 384.0;
	}


	if (GetConVarInt(MTDebug) >= 1)
	{
		decl String:mBuffer[128];
		Format(mBuffer, sizeof(mBuffer), "Map: %s", g_MapName);
		WriteFileLine(logfile, mBuffer);
	}
}

public OnMapEnd()
{
	if (GetConVarInt(MTDebug) >= 1)
	{
		FlushFile(logfile);
	}
}

public Action:PrintDebug(const String:format[], any:...)
{
	decl String:buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);

	if (GetConVarInt(MTDebug) >= 2)
	{
		PrintToChatAll("[MT] %s", buffer);
	}
	WriteFileLine(logfile, buffer);
}


public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	g_MapState = 1;
	CalculateTanksParamaters();
	
	TanksSpawned=0;
	TanksFrustrated=0;
	TanksMustSpawned=0;
	TanksToSpawn = 0;
	IsRoundStarted = true;
	IsRoundEnded = false;
	if (CheckTimer != INVALID_HANDLE) {KillTimer(CheckTimer); CheckTimer = INVALID_HANDLE;}
	if (SpawnTimer != INVALID_HANDLE) {KillTimer(SpawnTimer); SpawnTimer = INVALID_HANDLE;}
	for (new i=0; i <= MAXPLAYERS; i++)
	{
 		IsTank[i] = false;
 		IsFrustrated[i] = false;
	}
		
	return;
}
public Action:Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	g_MapState = 5;
	CalculateTanksParamaters();

	if (TanksMustSpawned > 0)
		RestoreMaxZombies()
	TanksSpawned=0;
	TanksFrustrated=0;
	TanksMustSpawned=0;
	TanksToSpawn = 0;
	IsRoundStarted = false;
	IsRoundEnded = true;
	if (CheckTimer != INVALID_HANDLE) {KillTimer(CheckTimer); CheckTimer = INVALID_HANDLE;}
	if (SpawnTimer != INVALID_HANDLE) {KillTimer(SpawnTimer); SpawnTimer = INVALID_HANDLE;}
	for (new i=0; i <= MAXPLAYERS; i++)
	{
 		IsTank[i] = false;
 		IsFrustrated[i] = false;
	}
	return;
}

public Action:Event_PlayerDeath (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if (client==0) return Plugin_Continue;

//	decl String:stringclass[32];
//	GetClientModel(client, stringclass, 32);
	
	if (IsPlayerTank(client))
	{
//		PrintDebug("[TANK] PlayerDeath as Tank [%d] [%d,%d]",client, IsTank[client], IsFrustrated[client]);
		// Its just Tank frustrated, or Player which receive tank. I HATE YOU VALVE!
		if (IsFrustrated[client])
		{
			TanksFrustrated--;
			IsFrustrated[client] = false;
			IsTank[client] = false;
//			return Plugin_Continue;
		} else	
		if (!IsTank[client])
		{
			IsTank[client] = true;
//			return Plugin_Continue;
		} else
		TankDie(client);
	}
	return Plugin_Continue;
}

public Action:TankDie(any:client)
{
	if (GetConVarInt(MTDebug))
	{
		Command_MTTest(0,0);
		PrintDebug("[TANK] TankDie [%d]",client);
	}
	IsTank[client] = false;
}

public Action:SetTankHP(any:client) 
{
	if (!GetConVarInt(MTOn)) return;
	if ((!IsClientConnected(client)) || (!IsClientInGame(client))) return;
	new TankHP = g_MTHealth;
	if(TankHP>65535) TankHP=65535;
	if ( GetConVarInt(AnnounceTankHP) )
	{
		new String:PlayerName[200];
		GetClientName(client, PlayerName, sizeof(PlayerName));
		for (new i=1 ; i<=MaxClients; i++)
		{	
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (GetClientTeam(i) == 3)
				{
					if (IsFakeClient(client))
						PrintToChat(i, "\x04[MT]\x01 %t (%d HP) [%t]", "New Tank Spawning", TankHP, "Bot"); else
						PrintToChat(i, "\x04[MT]\x01 %t (%d HP) [%s]", "New Tank Spawning", TankHP, PlayerName);
				} else
				if (GetClientTeam(i) == 2)
					 PrintToChat(i, "\x04[MT]\x01 %t (%d HP)", "New Tank Spawning", TankHP); else
				if (GetClientTeam(i) == 1)
					 PrintToChat(i, "\x04[MT]\x01 %t (%d HP)", "New Tank Spawning", TankHP);
			}
		}

//		 PrintToChatAll("Tank new HP %d (default %d)",TankHP,GetEntProp(client,Prop_Send,"m_iHealth"));
	}

	SetEntProp(client,Prop_Send,"m_iHealth",TankHP);
	SetEntProp(client,Prop_Send,"m_iMaxHealth",TankHP);
}

public Action:SetTankMaximumHP(any:client) 
{
	if (!GetConVarInt(MTOn)) return;
	if ((!IsClientConnected(client)) || (!IsClientInGame(client))) return;
	new TankHP = g_MTHealth;
	if(TankHP>65535) TankHP=65535;
	SetEntProp(client,Prop_Send,"m_iMaxHealth",TankHP);
}
public Action:SpawnAdditionalTank(Handle:timer, any:client)
{
	SpawnTimer = INVALID_HANDLE;
	if (!GetConVarInt(MTOn)) return;
	if ((!IsRoundStarted) || IsRoundEnded) return;
	if (TanksToSpawn <= 0) return;

	if (GetConVarInt(MTDebug))
	{
		PrintDebug("[TANK] Spawn Additional Tank");
	}
	TanksToSpawn--;
	TanksMustSpawned++;

	// Spawn NEW TANK

	// We get any client ....
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == 0)
	{
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{
			LogError("[L4D] MultiTanks CreateFakeClient returned 0 -- Tank bot was not spawned");
			return;
		}
		temp = true;
	}

	new String:command[] = "z_spawn";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(anyclient, "%s %s %s", command, "tank",  GetConVarInt(MTAutoSpawn) ? "auto" : "");
	SetCommandFlags(command, flags);

	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1,kickbot,anyclient);

	if (TanksToSpawn==0)
	{
		// Timer for check that all tanks spawned
		CheckTimer = CreateTimer(GetConVarFloat(MTSpawnCheck), CheckAdditionalTanks, client);
	} else SpawnTimer = CreateTimer(((g_MapState==3) ? GetConVarFloat(MTSpawnDelayEscape) : GetConVarFloat(MTSpawnDelay)), SpawnAdditionalTank, client);


}

public Action:CheckAdditionalTanks(Handle:timer, any:client)
{
	CheckTimer = INVALID_HANDLE;
	if (!GetConVarInt(MTOn)) return;
	if ((!IsRoundStarted) || IsRoundEnded) return;

	if (GetConVarInt(MTDebug))
	{
		PrintDebug("[TANK] Check Additional Tanks [%d]", TanksMustSpawned);
	}

	// Check if not all additional tanks successfully spawned
	if (TanksMustSpawned > 0)
	{
		if (GetConVarInt(MTDebug))
		{
			PrintDebug("[TANK] Spawn Additional Timer");
		}
		TanksToSpawn = TanksMustSpawned;
		TanksMustSpawned = 0;
		SpawnTimer = CreateTimer(((g_MapState==3) ? GetConVarFloat(MTSpawnDelayEscape) : GetConVarFloat(MTSpawnDelay)), SpawnAdditionalTank, client);

	} else
	{
		// Check for tanks dissapears

		decl maxclients;
		maxclients = GetMaxClients();
		new bool: isTankClient = false;
		decl String:stringclass[32];
		new TanksDissapears=0;
		for (new i=1 ; i<=maxclients ; i++)
		{	
			isTankClient = false;
			if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == 3))
			{
				GetClientModel(i, stringclass, 32);
				if (IsPlayerTank(i)) isTankClient = true;
			}
			
			if (IsTank[i] && !isTankClient) // Tank dissapear
			{	
				TanksSpawned--;
				TanksDissapears++;
			}
		}

		if (TanksDissapears == 1)
		{
			
			PrintToChatAll("[TANK] Tank magically disappeared, the new tank in the way!");
		} else
		if (TanksDissapears > 1)
		{
			PrintToChatAll("[TANK] %d Tanks magically disappeared, the new tanks in the way!", TanksDissapears);
		}

		if (TanksDissapears != 0)
		{
			SaveAndInreaseMaxZombies(TanksDissapears);
			TanksToSpawn = TanksDissapears;
			TanksMustSpawned = 0;
			if (GetConVarInt(MTDebug))
			{
				PrintDebug("[TANK] Spawn Additional Timer");
			}
			SpawnTimer = CreateTimer(((g_MapState==3) ? GetConVarFloat(MTSpawnDelayEscape) : GetConVarFloat(MTSpawnDelay)), SpawnAdditionalTank, client);
		}
	
	}

}

public SaveAndInreaseMaxZombies(number)
{
	if (isSuperVersus())
	{
		DefaultMaxZombies = GetConVarInt(FindConVar("l4d_infected_limit")); // Save  max zombies
		UnsetNotifytVar(FindConVar("l4d_infected_limit"));
		SetConVarInt(FindConVar("l4d_infected_limit"), DefaultMaxZombies+number); // and inreases limit
		SetNotifytVar(FindConVar("l4d_infected_limit"))
		if (GetConVarInt(MTDebug))
		{
			PrintDebug("[TANK] l4d_infected_limit = %d", GetConVarInt(FindConVar("l4d_infected_limit")));
		}
	} else
	{
		DefaultMaxZombies = GetConVarInt(FindConVar("z_max_player_zombies")); // Save  max zombies
		SetConVarInt(FindConVar("z_max_player_zombies"), DefaultMaxZombies+number); // and inreases limit
		if (GetConVarInt(MTDebug))
		{
			PrintDebug("[TANK] z_max_player_zombies = %d", GetConVarInt(FindConVar("z_max_player_zombies")));
		}
	}
}

public RestoreMaxZombies()
{
	if (isSuperVersus())
	{
		UnsetNotifytVar(FindConVar("l4d_infected_limit"));
		SetConVarInt(FindConVar("l4d_infected_limit"), DefaultMaxZombies); // restores limit
		SetNotifytVar(FindConVar("l4d_infected_limit"))
		if (GetConVarInt(MTDebug))
		{
			PrintDebug("[TANK] l4d_infected_limit = %d", GetConVarInt(FindConVar("l4d_infected_limit")));
		}
	} else
	{
		SetConVarInt(FindConVar("z_max_player_zombies"), DefaultMaxZombies); // restores limit
		if (GetConVarInt(MTDebug))
		{
			PrintDebug("[TANK] z_max_player_zombies = %d", GetConVarInt(FindConVar("z_max_player_zombies")));
		}
	}
}


public UnsetNotifytVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl)
	flags &= ~FCVAR_NOTIFY
	SetConVarFlags(hndl, flags)
}
 
public SetNotifytVar(Handle:hndl)
{
	new flags = GetConVarFlags(hndl)
	flags |= FCVAR_NOTIFY
	SetConVarFlags(hndl, flags)
}

public GetAnyClient ()
{
	
	new i;
	for (i=1;i<=GetMaxClients();i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)))
		{
			return i;
		}
	}
	return 0;
}

public Action:kickbot(Handle:timer, any:value)
{
	
	KickThis(value);
}

KickThis (client)
{
	if (IsClientConnected(client) && (!IsClientInKickQueue(client)))
	{
		KickClient(client,"Kick");
	}
}

public OnCVGameModeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	//If game mode actually changed
	if (strcmp(oldValue, newValue) != 0)
	{
		g_GameMode = l4d_gamemode();
		CalculateTanksParamaters();
	}
}


public Event_finale_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_MapState = 2;
	g_Wave = 0;
	CalculateTanksParamaters();
	return;		
}
	

public Event_finale_escape_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_MapState = 3;
	CalculateTanksParamaters();
}

public Event_finale_vehicle_leaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_MapState = 4;
	CalculateTanksParamaters();
}


l4d_gamemode()
{
	// based on DDR Khat code
	new String:gmode[32];
	GetConVarString(FindConVar("mp_gamemode"), gmode, sizeof(gmode));

	if (StrEqual(gmode, "coop", false) || StrEqual(gmode, "realism", false))
		return 1; else
	if (StrEqual(gmode, "versus", false) || StrEqual(gmode, "teamversus", false))
		return 2;
	if (StrEqual(gmode, "survival", false))
		return 3;
	if (StrEqual(gmode, "scavenge", false) || StrEqual(gmode, "teamscavenge", false))
		return 4; else
		return 0;
}

/*
public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new newteam = GetEventInt(event, "team");
	new oldteam = GetEventInt(event, "oldteam");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(MTDebug))
	{
		PrintDebug("[TANK] [%d] Player Change Team [%d to %d]", client, oldteam, newteam);
	}
}
*/


bool:IsFinalMap()
{
	new entitycount = GetEntityCount();
	new String:entname[50];

	//loop through entities
	for (new i = 1; i < entitycount; i++)
	{
		if (!IsValidEntity(i)) continue;
		
		GetEdictClassname(i, entname, sizeof(entname));
		if (StrContains(entname, "trigger_finale") > -1) return true;
	}

	return false;	
}

/*
bool:IsFinalMap()
{
	new String:Classname[128];
	new max_entities = GetMaxEntities();
//	decl String:netclass[32];
	new bool:isFinal = true;

	new String:map[128];
	GetCurrentMap(map, sizeof(map));
	
//	if(StrEqual(map, "l4d_vs_smalltown04_mainstreet") || StrEqual(map, "l4d_smalltown04_mainstreet") ||
// StrEqual(map, "l4d_garage01_alleys") || StrEqual(map, "c2m1_highway") || StrEqual(map, "c5m1_waterfront") || StrEqual(map, "c5m2_park") ||  StrEqual(map, "c4m4_milltown_b"))
	if(StrEqual(map, "l4d_vs_smalltown04_mainstreet") || StrEqual(map, "l4d_smalltown04_mainstreet") || StrEqual(map, "l4d_garage01_alleys") || StrEqual(map, "l4d_river01_docks") || StrEqual(map, "l4d_river02_barge"))
		return false;

	for (new i = 0; i < max_entities; i++)
	{
		if (IsValidEntity (i))
		{
      			GetEdictClassname(i, Classname, sizeof(Classname));
//			GetEntityNetClass(i, netclass, sizeof(netclass));
			if(StrEqual(Classname, "prop_door_rotating_checkpoint"))
				{
//					new Float:pos[3];
					new String:targetname[128];
//					GetEntPropVector(i, Prop_Data, "m_vecOrigin",g_DoorPos);
					GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
//					PrintToChatAll("[TEST]  %s (prop_door_rotating_checkpoint') [name=%s] = %f %f  %f", netclass, targetname, pos[0], pos[1], pos[2]);
					if(StrEqual(targetname, "checkpoint_entrance") || StrEqual(targetname, "door_checkpointentrance"))
					{
						isFinal = false;
						break;	
					}
				}
		}
	}
	return isFinal;
}
*/

public Action:Command_RefreshSettings(client, args)
{
	CalculateTanksParamaters();
	ReplyToCommand(client, "[MT] Tanks Settings are refreshed");

	return Plugin_Handled;
}


public Action:Command_MTTest2(client, args)
{
	SetEntProp(client, Prop_Send, "m_frustration", 0)
}

public Action:Command_MTTest(client, args)
{
	decl maxclients;
	maxclients = GetMaxClients();
	new bool: isTankClient = false;
	decl String:stringclass[32];
	new TotalCount = 0;
	new Float:Pos[3];
	PrintDebug("[TANK] ====== MT TEST ======= [BEGIN]");
	for (new i=1 ; i<=maxclients ; i++)
	{	
		isTankClient = false;
		if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == 3))
		{
			GetClientModel(i, stringclass, 32);
			
			PrintDebug("[TANK] === [%d] [%d,%s]", i , GetEntProp(i, Prop_Send, "m_zombieClass"), stringclass);
			if (IsPlayerTank(i))
			{
				isTankClient = true;
				TotalCount++;
				if (GetConVarInt(MTDebug))
				{
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", Pos);

					if (IsFakeClient(i))
						PrintDebug("[TANK] === [FAKE] [%d] [%d,%d,%d] [%f,%f,%f]",i, IsClientConnected(i), IsClientInGame(i), GetClientTeam(i), Pos[0],Pos[1],Pos[2]); else 
						PrintDebug("[TANK] === [REAL] [%d] [%d,%d,%d] [%f,%f,%f]",i, IsClientConnected(i), IsClientInGame(i), GetClientTeam(i), Pos[0],Pos[1],Pos[2]);
				}
			}
		}

	
		if (GetConVarInt(MTDebug))
		{
			PrintDebug("[TANK] [%d] [%d,%d]",i, IsTank[i], isTankClient);
		}
	}

	PrintDebug("[TANK] TotalCount = %d", TotalCount);
	PrintDebug("[TANK] ====== MT TEST ======= [END]");

}


public Action:Command_MTSpawnBot(client, args)
{

	for (new i=1; i<=MaxClients; i++) //now to 'disable' all human players
	{
		restoreStatus[i] = false;
		if (IsClientInGame(i) && (GetClientTeam(i) == 3)  && !IsFakeClient(i)) 
		{
			restoreStatus[i] = true;
			infectedClass[i] = GetEntProp(i, Prop_Send, "m_zombieClass");
			SetEntProp(i, Prop_Send, "m_zombieClass", ZC_TANK);

			if (IsPlayerGhost(i))
			{
				resetGhostState[i] = true;
				SetPlayerGhostStatus(i, false);
				resetIsAlive[i] = true;
				SetPlayerIsAlive(i, true);
			}
			else if (!IsPlayerAlive(i))
			{
				resetLifeState[i] = true;
				SetPlayerLifeState(i, false)
			}
		}
	}
	
	new userflags = GetUserFlagBits(client)
	SetUserFlagBits(client, ADMFLAG_ROOT)
	
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	
	FakeClientCommand(client, "z_spawn tank");
	
	SetUserFlagBits(client, userflags);
	SetCommandFlags("z_spawn", flags);

	CreateTimer(0.1, RevertPlayerStatus);
	return;
/*	
	// We restore the human players' status
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) == 3)  && !IsFakeClient(i)) 
		{
			if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
			if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
			if (resetLifeState[i]) SetPlayerLifeState(i, true);
			SetEntProp(i, Prop_Send, "m_zombieClass", infectedClass[i]);
		}
	}
*/
}

public Action:RevertPlayerStatus(Handle:timer)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) == 3)  && !IsFakeClient(i) && restoreStatus[i]) 
		{
			if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
			if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
			if (resetLifeState[i]) SetPlayerLifeState(i, true);
			SetEntProp(i, Prop_Send, "m_zombieClass", infectedClass[i]);
		}
	}

	// We restore the player's status
}

public Action:CheckFrustration(Handle:timer, any:client)
{
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client) || (GetClientTeam(client)!=3) || !IsPlayerTank(client) || !IsPlayerAlive(client)) return;
	new frustration = GetEntProp(client, Prop_Send, "m_frustration");
//	PrintToChatAll("Frustration [%d] - %d", client, frustration);
	if (frustration >= 95) 
	{
		new TotalCount = 0;
		for (new i=1 ; i<=MaxClients; i++)
		{	
			if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerTank(i) && IsPlayerAlive(i))
				TotalCount++;
		}

		if (((TotalCount >= 2) && !IsPlayerBurning(client)) || (Frustrates[client] > 0))
		{
			Frustrates[client]++;
			new String:PlayerName[200];
			GetClientName(client, PlayerName, sizeof(PlayerName));
			for (new i=1 ; i<=MaxClients; i++)
			{	
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (GetClientTeam(i) == 3)
					{
						if (Frustrates[client] >= 2)
							PrintToChat(i, "\x04[MT]\x01 %s %t", PlayerName, "loose tank control"); else
							PrintToChat(i, "\x04[MT]\x01 %s %t", PlayerName, "loose first tank control"); 
					}
				}
			}

			if (Frustrates[client] >= 2)
			{
				ChangeClientTeam(client, 1);
//			 	FakeClientCommand(client, "jointeam 3"); 
				CreateTimer(0.1, RestoreInfectedTeam, client);
			} else
			{
				SetEntProp(client, Prop_Send, "m_frustration", 0)
				CreateTimer(0.1, CheckFrustration, client)
			}
		} else CreateTimer(0.1, CheckFrustration, client)

	} else CreateTimer(0.1+(95-frustration)*0.1, CheckFrustration, client);
}

public Action:RestoreInfectedTeam(Handle:timer, any:client)
{
	if (!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client) || (GetClientTeam(client)==3)) return;
 	FakeClientCommand(client, "jointeam 3"); 
}

stock SetPlayerIsAlive(client, bool:alive)
{
	new offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive) SetEntData(client, offset, 1, 1, true);
	else SetEntData(client, offset, 0, 1, true);
}

stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}

stock SetPlayerGhostStatus(client, bool:ghost)
{
	if(ghost)
	{	
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC)
	}
	
	else
	{
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
		SetEntityMoveType(client, MOVETYPE_WALK)
	}
}

stock SetPlayerLifeState(client, bool:ready)
{
	if (ready) SetEntProp(client, Prop_Data, "m_lifeState", 1, 1);
	else SetEntProp(client, Prop_Data, "m_lifeState", 0, 1);
}

public bool:IsPlayerTank (client)
{
	new String:class[150];
	GetClientModel(client, class, sizeof(class));
	return (StrContains(class, "hulk", false) != -1);
//	return ((GetClientTeam(client) == 3) && (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK));
}

bool:IsPlayerBurning(client)
{
//	if (!IsValidClient(client)) return false;
	new Float:isburning = GetEntDataFloat(client, propinfoburn);
	if (isburning>0)
		return true; else
		return false;
}

public Action:HUD_Timer(Handle:timer)
{
	HUD_Draw();
	for (new i=1 ; i<=MaxClients; i++)
	{	
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) != 2))
			SendPanelToClient(g_hHUD, i, HUD_Handler, 1); // Show HUD to client
	}
}

public HUD_Handler(Handle:menu, MenuAction:action, param1, param2) 
{ 
	/* Empty, as we don't care about what gets pressed in the HUD. */
}

/*
HUD_Draw()
{
	if (g_hHUD != INVALID_HANDLE) CloseHandle(g_hHUD); // Close handle if used
	g_hHUD = CreatePanel();
	decl String:sBuffer[512];
	new String:PlayerName[200];
	new TotalCount = 0;
	Format(sBuffer, sizeof(sBuffer), "");
	for (new i=1 ; i<=MaxClients; i++)
	{	
		if (IsClientInGame(i) && IsPlayerTank(i) && IsPlayerAlive(i) && !IsPlayerIncapped(i))
		{
			TotalCount++;
			GetClientName(i, PlayerName, sizeof(PlayerName));
			new frustration = 100-GetEntProp(i, Prop_Send, "m_frustration");
			new health = GetEntData(i, FindDataMapOffs(i, "m_iHealth"));
			decl String:tBuffer[512];
			if (IsPlayerBurning(i)) 
				Format(tBuffer, sizeof(tBuffer), "%s: %d HP (FIRE)", PlayerName, health); else
				Format(tBuffer, sizeof(tBuffer), "%s: %d HP,control: %d%%", PlayerName, health, frustration);
			if (TotalCount == 1)
				Format(sBuffer, sizeof(sBuffer), "%s", tBuffer); else
				Format(sBuffer, sizeof(sBuffer), "%s\n%s", sBuffer, tBuffer);
		}
	}


	if (TotalCount == 0)
	{
		if (HUDTimer != INVALID_HANDLE) {KillTimer(HUDTimer); HUDTimer = INVALID_HANDLE;}
		// return;
	}
	DrawPanelText(g_hHUD, sBuffer);
}
*/

HUD_Draw()
{
	if (g_hHUD != INVALID_HANDLE) CloseHandle(g_hHUD); // Close handle if used
	g_hHUD = CreatePanel();
	new String:PlayerName[200];
	new TotalCount = 0;
	for (new i=1 ; i<=MaxClients; i++)
	{	
		if (IsClientInGame(i) && IsPlayerTank(i) && IsPlayerAlive(i) && !IsPlayerIncapped(i))
		{
			TotalCount++;
			GetClientName(i, PlayerName, sizeof(PlayerName));
			new frustration = 100-GetEntProp(i, Prop_Send, "m_frustration");
			new health = GetEntData(i, FindDataMapOffs(i, "m_iHealth"));
			decl String:tBuffer[512];
			if (IsPlayerBurning(i)) 
				Format(tBuffer, sizeof(tBuffer), " %s: %d HP (FIRE)", PlayerName, health); else
				Format(tBuffer, sizeof(tBuffer), " %s: %d HP,control: %d%%", PlayerName, health, frustration);
			DrawPanelText(g_hHUD, tBuffer);
		}
	}


	if (TotalCount == 0)
	{
		if (HUDTimer != INVALID_HANDLE) {KillTimer(HUDTimer); HUDTimer = INVALID_HANDLE;}
		// return;
	}
}


bool:IsPlayerIncapped(client)
{
	new propincapped = FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated");
	new isincapped = GetEntData(client, propincapped, 1);
	if (isincapped == 1) return true;
	else return false;
}