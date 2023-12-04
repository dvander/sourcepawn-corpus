//Each round tank/Witch spawn same position and angle for both team
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

#define INTRO		0
#define REGULAR		1
#define FINAL		2
#define TANK		0
#define WITCH		1
#define MIN			0
#define MAX			1

static Handle:g_hCvarVsBossChance[3][2], Handle:g_hCvarVsBossFlow[3][2], Float:g_fCvarVsBossChance[3][2], Float:g_fCvarVsBossFlow[3][2];
static	bool:g_bFixed,Float:g_fTankData_origin[3],Float:g_fTankData_angel[3];
static 	Float:fWitchData_agnel[3],Float:fWitchData_origin[3];
static	bool:Tank_firstround_spawn,bool:Witch_firstround_spawn;
float g_fWitchFlow, g_fTankFlow;
int g_iRoundStart, g_iPlayerSpawn;
ConVar sv_cheats;
ConVar g_hTankMapOff, g_hWitchMapOff;

native void SaveBossPercents(); // from l4d_boss_percent
static int ZC_TANK;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead )
	{
		ZC_TANK = 5;
	}
	else if( test == Engine_Left4Dead2 )
	{
		ZC_TANK = 8;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin:myinfo = 
{
	name = "l4d_versus_same_UnprohibitBosses",
	author = "Harry",
	version = "1.0",
	description = "Force Enable bosses spawning on all maps, and same spawn positions for both team",
	url = "http://steamcommunity.com/profiles/76561198026784913"
}

public void OnPluginStart()
{
	//強制每一關生出tank與witch
	g_hCvarVsBossChance[INTRO][TANK] = FindConVar("versus_tank_chance_intro");
	g_hCvarVsBossChance[REGULAR][TANK] = FindConVar("versus_tank_chance");
	g_hCvarVsBossChance[FINAL][TANK] = FindConVar("versus_tank_chance_finale");
	g_hCvarVsBossChance[INTRO][WITCH] = FindConVar("versus_witch_chance_intro");
	g_hCvarVsBossChance[REGULAR][WITCH] = FindConVar("versus_witch_chance");
	g_hCvarVsBossChance[FINAL][WITCH] = FindConVar("versus_witch_chance_finale");
	g_hCvarVsBossFlow[INTRO][MIN]  = FindConVar("versus_boss_flow_min_intro");
	g_hCvarVsBossFlow[INTRO][MAX] = FindConVar("versus_boss_flow_max_intro");
	g_hCvarVsBossFlow[REGULAR][MIN] = FindConVar("versus_boss_flow_min");
	g_hCvarVsBossFlow[REGULAR][MAX] = FindConVar("versus_boss_flow_max");
	g_hCvarVsBossFlow[FINAL][MIN] = FindConVar("versus_boss_flow_min_finale");
	g_hCvarVsBossFlow[FINAL][MAX] = FindConVar("versus_boss_flow_max_finale");
	for (new campaign; campaign < 3; campaign++){

		for (new index; index < 2; index++){

			g_fCvarVsBossChance[campaign][index] = GetConVarFloat(g_hCvarVsBossChance[campaign][index]);
			g_fCvarVsBossFlow[campaign][index] = GetConVarFloat(g_hCvarVsBossFlow[campaign][index]);

			HookConVarChange(g_hCvarVsBossChance[campaign][index], _UB_Common_CvarChange);
			HookConVarChange(g_hCvarVsBossFlow[campaign][index], _UB_Common_CvarChange);
		}
	}

	HookEvent("tank_spawn",			TS_ev_TankSpawn,		EventHookMode_PostNoCopy);
	HookEvent("player_spawn", 	Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	HookEvent("round_start", 	Event_RoundStart, 	EventHookMode_PostNoCopy);
	HookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("witch_spawn", TS_ev_WitchSpawn);

	g_hTankMapOff =  CreateConVar("l4d_versus_tank_map_off",	"c7m1_docks,c7m3_port",	"Plugin will not spawn Tank in these maps, separate by commas (no spaces). (0=All maps, Empty = none).", FCVAR_NOTIFY );
	g_hWitchMapOff = CreateConVar("l4d_versus_witch_map_off",	"c6m1_riverbank",	"Plugin will not spawn Witch in these maps, separate by commas (no spaces). (0=All maps, Empty = none).", FCVAR_NOTIFY );

	//Autoconfig for plugin
	AutoExecConfig(true, "l4d_boss_filter");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnAllPluginsLoaded()
{
	sv_cheats = FindConVar("sv_cheats");
}

char sMap[64], g_sCurMap[64];
bool g_bTankVaildMap, g_bWitchValidMap;
public OnMapStart()
{
	g_bTankVaildMap = true;
	g_bWitchValidMap = true;
	GetCurrentMap(g_sCurMap, 64);
	Format(sMap, sizeof(sMap), ",%s,", g_sCurMap);

	char sCvar[512];
	g_hTankMapOff.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != '\0' )
	{
		if( strcmp(sCvar, "0") == 0 )
		{
			g_bTankVaildMap = false;
		}
		else
		{
			Format(sCvar, sizeof(sCvar), ",%s,", sCvar);
			if( StrContains(sCvar, sMap, false) != -1 )
				g_bTankVaildMap = false;
		}
	}

	sCvar = "";
	g_hWitchMapOff.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != '\0' )
	{
		if( strcmp(sCvar, "0") == 0 )
		{
			g_bWitchValidMap = false;
		}
		else
		{
			Format(sCvar, sizeof(sCvar), ",%s,", sCvar);
			if( StrContains(sCvar, sMap, false) != -1 )
				g_bWitchValidMap = false;
		}
	}
}

public void OnMapEnd()
{
	ResetPlugin();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(2.0, COLD_DOWN, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(2.0, COLD_DOWN, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action:COLD_DOWN(Handle:timer)
{
	ResetPlugin();

	if (InSecondHalfOfRound())
	{
		if(g_fTankFlow <= 0.0)
		{
			L4D2Direct_SetVSTankFlowPercent(1, 0.0);
			L4D2Direct_SetVSTankToSpawnThisRound(1, false);
		}

		if(g_fWitchFlow <= 0.0)
		{
			L4D2Direct_SetVSWitchFlowPercent(1, 0.0);
			L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
		}
		else
		{
			L4D2Direct_SetVSWitchFlowPercent(1, 0.2);
			L4D2Direct_SetVSWitchFlowPercent(1, g_fWitchFlow);
			L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
			L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
		}
	}
	else
	{
		g_fTankFlow = g_fWitchFlow = 0.0;

		//強制每一關生出tank與witch
		int iCampaign = (L4D_IsMissionFinalMap())? FINAL : (L4D_IsFirstMapInScenario())? INTRO : REGULAR;
		if (g_bTankVaildMap == true){
			g_fTankFlow = GetRandomBossFlow(iCampaign, TANK);
		}
		
		if (g_fTankFlow > 0.0)
		{
			L4D2Direct_SetVSTankFlowPercent(0, g_fTankFlow);
			L4D2Direct_SetVSTankFlowPercent(1, g_fTankFlow);
			L4D2Direct_SetVSTankToSpawnThisRound(0, true);
			L4D2Direct_SetVSTankToSpawnThisRound(1, true);
		}
		else
		{
			L4D2Direct_SetVSTankFlowPercent(0, 0.0);
			L4D2Direct_SetVSTankFlowPercent(1, 0.0);
			L4D2Direct_SetVSTankToSpawnThisRound(0, false);
			L4D2Direct_SetVSTankToSpawnThisRound(1, false);	
		}
		
		if (g_bWitchValidMap == true && !IsWitchProhibit())
		{
			g_fWitchFlow = GetRandomBossFlow(iCampaign, WITCH);
		}
		
		if(g_fWitchFlow > 0.0)
		{
			L4D2Direct_SetVSWitchFlowPercent(0, g_fWitchFlow);
			L4D2Direct_SetVSWitchFlowPercent(1, g_fWitchFlow);
			L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
			L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
		}
		else
		{
			L4D2Direct_SetVSWitchFlowPercent(0, 0.0);
			L4D2Direct_SetVSWitchFlowPercent(1, 0.0);
			L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
			L4D2Direct_SetVSWitchToSpawnThisRound(1, false);	
		}
		
		//強制tank出生在一樣的位置
		g_bFixed = false;
		Tank_firstround_spawn = false;
		ClearVec();
		
		//強制witch出生在一樣的位置
		Witch_firstround_spawn = false;
	}

	SaveBossPercents();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

static bool IsWitchProhibit()
{
	return false;
}

public _UB_Common_CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue)) return;

	for (new campaign; campaign < 3; campaign++){

		for (new index; index < 2; index++){

			if (g_hCvarVsBossChance[campaign][index] == convar)
				g_fCvarVsBossChance[campaign][index] = GetConVarFloat(convar);
			else if (g_hCvarVsBossFlow[campaign][index] == convar)
				g_fCvarVsBossFlow[campaign][index] = GetConVarFloat(convar);
		}
	}
}

public TS_ev_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( IsWitchProhibit() || sv_cheats.IntValue == 1 ) return;
	
	new iEnt = GetEventInt(event, "witchid");
	if(InSecondHalfOfRound() == false)
	{
		if(Witch_firstround_spawn == false)
		{
			GetEntPropVector(iEnt, Prop_Send, "m_angRotation", fWitchData_agnel);
			GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fWitchData_origin);
			Witch_firstround_spawn = true;
			
			//PrintToChatAll("Witch first position: %f, %f, %f", fWitchData_origin[0], fWitchData_origin[1], fWitchData_origin[2]);
			//PrintToChatAll("Witch first angel: %f, %f, %f", fWitchData_agnel[0], fWitchData_agnel[1], fWitchData_agnel[2]);
		}
	}
	else
	{
		if(Witch_firstround_spawn)
		{
			Witch_firstround_spawn = false;
			//TeleportEntity(iEnt, fWitchData_origin, fWitchData_agnel, NULL_VECTOR); //not working on sitting witch after 2022 l4d1 update
			RemoveEntity(iEnt);
			L4D2_SpawnWitch(fWitchData_origin, fWitchData_agnel);
			//PrintToChatAll("轉換妹子到第一回合的位置");
		}
	}
}

public Action:ColdDown(Handle:timer,any:witchid)
{
	if(IsValidEntity(witchid))
		RemoveEdict(witchid);
}

public Action:TS_ev_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!InSecondHalfOfRound())
	{
		if(!Tank_firstround_spawn){
			new iTank = IsTankInGame();
			if (iTank){
				GetEntPropVector(iTank, Prop_Send, "m_angRotation", g_fTankData_angel);
				GetEntPropVector(iTank, Prop_Send, "m_vecOrigin", g_fTankData_origin);
				//PrintToChatAll("round1 tank pos: %.1f %.1f %.1f", vector[0], vector[1], vector[2]);
				Tank_firstround_spawn = true;
			}
		}
	}
	else
	{
		if(g_bFixed || !Tank_firstround_spawn) return;
		
		new iTank = IsTankInGame();
		if (iTank){

			TeleportEntity(iTank, g_fTankData_origin, g_fTankData_angel, NULL_VECTOR);
			//PrintToChatAll("teleport '%N' to round1 pos.", iTank);
			g_bFixed = true;
		}
	}
}

IsTankInGame(exclude = 0)
{
	for (new i = 1; i <= MaxClients; i++)
		if (exclude != i && IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerTank(i) && IsPlayerAlive(i) && !IsIncapacitated(i))
			return i;

	return 0;
}

static ClearVec()
{
	for (new index; index < 3; index++){
		fWitchData_agnel[index] = 0.0;
		fWitchData_origin[index] = 0.0;
		g_fTankData_origin[index] = 0.0;
		g_fTankData_angel[index] = 0.0;
	}
}

bool:InSecondHalfOfRound()
{
	return bool:GameRules_GetProp("m_bInSecondHalfOfRound");
}

void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}
stock bool IsPlayerTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK;
}
stock bool IsIncapacitated(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

static float GetRandomBossFlow(int iCampaign, int index)
{
	if(g_fCvarVsBossChance[iCampaign][index] == 0.0 ) return 0.0;
	if(GetRandomFloat(0.0, 1.0) > g_fCvarVsBossChance[iCampaign][index]) return 0.0;

	return GetRandomFloat(g_fCvarVsBossFlow[iCampaign][MIN], g_fCvarVsBossFlow[iCampaign][MAX]);
}