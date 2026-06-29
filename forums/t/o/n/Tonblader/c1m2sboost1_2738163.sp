#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define MAX_CALLS			1 // How many times to print each forward

#pragma newdecls required
#pragma semicolon 1

#define CLIENTS		0
#define EVENT		1
#define ROUND		2
#define TIMELEFT	3
#define TOTAL		4

//#define GAMEDATA_FILE	"staggersolver"

#define PL_VERSION "2.0.0.2"

//CHANGELOG#
//
//31/7 2.0.0.1 me equivoque era || no && en musthaveanyWeaponfromListinHand
//10/8 2.0.0.2 se comento codigo que por el momento no se usa, se elimino los warnings al momento de compilar y se elimino espacios en blanco/sangrias
//

#define DEBUG		0

//Cvar
#define CVARMAP    "c1m2_sboost1"
#define PLUGINNAME "Movement Anim Detector - " ... CVARMAP

//Movement Reader Files
//MR Player 1
#define FILESTMR1 "c1m2/sboost/gl1"
//MR Player 2
#define FILESTMR2 "c1m2/sboost/bile1"
//MR Player 3
#define FILESTMR3 "c1m2/sboost/run1"

//Player Position 1
#define IMPACT1ORIGIN0 1440.752
#define IMPACT1ORIGIN1 4390.685
#define IMPACT1ORIGIN2 468.842
//Player Position 2
#define IMPACT2ORIGIN0 1360.234
#define IMPACT2ORIGIN1 4260.946
#define IMPACT2ORIGIN2 478.149
//Player Position 3
#define IMPACT3ORIGIN0 1635.812
#define IMPACT3ORIGIN1 4727.136
#define IMPACT3ORIGIN2 704.031

//Player 1 Valid Weapons in Hand
#define PIPEBOMBVAL1 0
#define MOLOTOVVAL1 0
#define VOMITJARVAL1 0
#define GRENADE_LAUNCHERVAL1 1
//Player 2 Valid Weapons in Hand
#define PIPEBOMBVAL2 0
#define MOLOTOVVAL2 0
#define VOMITJARVAL2 1
#define GRENADE_LAUNCHERVAL2 0
//Player 3 Valid Weapons in Hand
#define PIPEBOMBVAL3 0
#define MOLOTOVVAL3 0
#define VOMITJARVAL3 0
#define GRENADE_LAUNCHERVAL3 0

public Plugin myinfo =
{
  name        = PLUGINNAME,
  author      = "Jeremy,Tonblader",
  description = "Execute configs on certain events.",
  version     = PL_VERSION,
  url         = "https://forums.alliedmods.net/showthread.php?t=330875"
};

/**
 * Globals
 */
int g_iRound;
bool g_bSection;
SMCParser g_hConfigParser;
ConVar g_hGCEnable;
ConVar g_hEnabled;
ConVar g_hIncludeBots;
ConVar g_hIncludeSpec;
Handle g_hTimer;
Handle g_hTimers[TOTAL];
StringMap g_hTries[TOTAL];
StringMap g_hTypes;
char g_sConfigFile[PLATFORM_MAX_PATH + 1];
char g_sMap[32];

//new variables
int clientinpos1 = 0;
int clientinpos2 = 0;
int clientinpos3 = 0;
bool g_bLeft4Dead2;
//bool g_bLateLoad;
//Handle hGameConf;
//Handle hIsStaggering;
bool g_bStagger[MAXPLAYERS+1];
int clientAnim[MAXPLAYERS+1];
//char g_NewName[MAXPLAYERS+1][MAX_NAME_LENGTH];

bool g_bLibraryActive;
//bool g_bTestForwards = true;	// To enable forwards testing
//int g_iForwardsMax;			// Total forwards we expect to see
//int g_iForwards;
Handle g_hTimerAnim;
Handle g_hTimerExecAMR1;
Handle g_hTimerExecAMR2; 
Handle g_hTimerExecAMR3; 
//Globals add by Tonblader
//char g_cRunnerMR[MAXPLAYERS+1][64];
const float g_DamageRadius = 250.0;
float g_vAngGL[3];
float g_vPosBile[3];
float g_vAngBile[3];
float g_vPosRun[3];
float g_vVec[3];
float g_vPosTemp[3];
int STMR_client1;
int STMR_client2;
int STMR_client3;
//PrecacheModel("models/props_junk/propanecanister001a.mdl", true);

/**
 * Forwards
 */

/*public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	// (+2 for "L4D2_OnEndVersusModeRound_Post" and "L4D2_OnSelectTankAttackPre")
	if( g_bLeft4Dead2 )
		g_iForwardsMax = 43;
	else
		g_iForwardsMax = 33;
	g_bLateLoad = late;
	
	RegPluginLibrary("left4dhooks");


	return APLRes_Success;
}*/

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "left4dhooks") == 0 )
		g_bLibraryActive = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "left4dhooks") == 0 )
		g_bLibraryActive = false;
}

public void OnAllPluginsLoaded()
{
	if( g_bLibraryActive == false )
		LogError("Required plugin left4dhooks is missing.");
}

/*void ResetPlugin()
{
	delete g_hTimer;
}*/

public void OnPluginStart()
{
	g_hGCEnable = CreateConVar(CVARMAP,"1","1=On , 0=Off.",ADMFLAG_ROOT);
	
	CreateConVar("sm_executeconfigs_version", PL_VERSION, "Execute configs on certain events.", FCVAR_NOTIFY);
	g_hEnabled		= CreateConVar("sm_executeconfigs_enabled",			"1", "Enable/disable executing configs");
	g_hIncludeBots	= CreateConVar("sm_executeconfigs_include_bots",	"1", "Enable/disable including bots when counting number of clients");
	g_hIncludeSpec	= CreateConVar("sm_executeconfigs_include_spec",	"1", "Enable/disable including spectators when counting number of clients");

	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/executeconfigs.txt");
	RegServerCmd("sm_executeconfigs_reload", Command_Reload, "Reload the configs");
	RegServerCmd("sm_detectanim", Command_Anim, "Anim");
	RegAdminCmd("sm_prueba", ExecConfigCmd, ADMFLAG_ROOT, "PRobando.");


	g_hConfigParser = new SMCParser();
	g_hConfigParser.OnEnterSection	= ReadConfig_NewSection;
	g_hConfigParser.OnKeyValue		= ReadConfig_KeyValue;
	g_hConfigParser.OnLeaveSection	= ReadConfig_EndSection;

	g_hTypes = new StringMap();
	g_hTypes.SetValue("clients",	CLIENTS);
	g_hTypes.SetValue("event",		EVENT);
	g_hTypes.SetValue("round",		ROUND);
	g_hTypes.SetValue("timeleft",	TIMELEFT);

	for (int i = 0; i < TOTAL; i++)
		g_hTries[i] = new StringMap();

	char sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));

	if (StrEqual(sGameDir, "insurgency"))
		HookEvent("game_newmap",			Event_GameStart,  EventHookMode_PostNoCopy);
	else
		HookEvent("game_start",				Event_GameStart,  EventHookMode_PostNoCopy);

	if (StrEqual(sGameDir, "dod"))
		HookEvent("dod_round_start",		Event_RoundStart, EventHookMode_PostNoCopy);
	else if (StrEqual(sGameDir, "tf"))
	{
		HookEvent("teamplay_restart_round",	Event_GameStart,  EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start",	Event_RoundStart, EventHookMode_PostNoCopy);
	}
	else
	{
		HookEvent("round_start",			Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("player_spawn",			player_spawn);
		//HookEvent("player_hurt_concise",verifyStagger, EventHookMode_Pre);
		//HookEvent("hegrenade_detonate",verifyStagger, EventHookMode_Pre);
		//HookEvent("charger_impact",verifyStagger, EventHookMode_Pre);
		//HookEvent("player_shoved",verifyStagger, EventHookMode_Pre);
		HookEvent("round_end",				Event_RoundEnd);
		HookEvent("map_transition",			Event_RoundEnd); //戰役過關到下一關的時候 (沒有觸發round_end)
		HookEvent("mission_lost",			Event_RoundEnd); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
		HookEvent("finale_vehicle_leaving",	Event_RoundEnd); //救援載具離開之時  (沒有觸發round_end)
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		g_bStagger[i]=false;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		clientAnim[i]=0;
	}
	
/*	
    // sdkhook
    hGameConf = LoadGameConfigFile(GAMEDATA_FILE);
    if (hGameConf == INVALID_HANDLE)
    SetFailState("[aidmgfix] Could not load game config file (staggersolver.txt).");
    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IsStaggering"))
    SetFailState("[aidmgfix] Could not find signature IsStaggering.");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	
    hIsStaggering = EndPrepSDKCall();
    if (hIsStaggering == INVALID_HANDLE)
    SetFailState("[aidmgfix] Failed to load signature IsStaggering");
    CloseHandle(hGameConf);
	
	
	if (g_bLateLoad)
	{
		g_bLateLoad = false;
	}
	
	//new GameData("l4d2_signatures");
	LoadGameConfigFile("l4d2_signatures");
	
	int iOffset = gdData.GetOffset("Detonate");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetVirtual(iOffset);
	g_hSDK_Detonate = EndPrepSDKCall();
	if (g_hSDK_Detonate == null)
	{
		LogError("Your \"Detonate\" offsets are outdated.");
	}
}

public Action L4D2_OnStagger(int target, int source)
{	
		return Plugin_Handled;
	//return Plugin_Continue;
}
*/
	//Cvars by Tonblader
	//g_hCvarGLspeed = FindConVar("grenadelauncher_velocity");
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		AnimHookDisable(i, OnAnim, OnAnimPost);
	}

}

public void OnMapEnd()
{

	clientinpos1 = 0;
	clientinpos2 = 0;
	clientinpos3 = 0;

}

public void OnMapStart()
{
	g_iRound = 0;
	g_hTimer = null;

	for (int i = 0; i < TOTAL; i++)
		g_hTimers[i] = null;

	GetCurrentMap(g_sMap, sizeof(g_sMap));
	ParseConfig();
}

public void OnMapTimeLeftChanged()
{
	delete g_hTimer;

	int iTimeleft;
	if (GetMapTimeLeft(iTimeleft) && iTimeleft > 0)
		g_hTimer = CreateTimer(60.0, Timer_ExecTimeleftConfig, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
	ExecClientsConfig(0);
}

public void OnClientDisconnect(int client)
{
	ExecClientsConfig(-1);
}


/**
 * Commands
 */
public Action Command_Reload(int args)
{
	ParseConfig();
}

public Action Command_Anim(int args)
{
	delete g_hTimerAnim;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 2)//&& !SDKCall(hIsStaggering, target))
		{
			#if DEBUG
			PrintToChatAll("DetectAnim Iniciado clientAnim para el cliente %d, inicial: %d",i,clientAnim[i]);
			#endif
			g_hTimer = CreateTimer(0.1, Timer_DetectAnim, i, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}
}


/**
 * Events
 */
public void Event_GameStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iRound = 0;
}

public void Event_Hook(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hEnabled.BoolValue)
		ExecConfig(EVENT, name);
}

public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && GetClientTeam(client) == 2)
		AnimHookEnable(client, OnAnim, OnAnimPost);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iRound++;

	if (!g_hEnabled.BoolValue)
		return;

	char sRound[4];
	IntToString(g_iRound, sRound, sizeof(sRound));
	ExecConfig(ROUND, sRound);
}


/**
 * Timers
 */
public Action Timer_ExecConfig(Handle timer, DataPack pack)
{
	pack.Reset();

	char sConfig[32];
	int iType = pack.ReadCell();
	pack.ReadString(sConfig, sizeof(sConfig));
	
	ServerCommand("exec \"%s\"", sConfig);
	g_hTimers[iType] = null;
}

public Action Timer_ExecTimeleftConfig(Handle timer)
{
	if (!g_hEnabled.BoolValue)
		return Plugin_Handled;

	int iTimeleft;
	if (!GetMapTimeLeft(iTimeleft) || iTimeleft < 0)
		return Plugin_Handled;

	char sTimeleft[4];
	IntToString(iTimeleft / 60, sTimeleft, sizeof(sTimeleft));
	ExecConfig(TIMELEFT, sTimeleft);

	return Plugin_Handled;
}


public Action Timer_ExecConfigCommand(Handle timer, DataPack pack)
{
	delete g_hTimerExecAMR1;
	delete g_hTimerExecAMR2;
	delete g_hTimerExecAMR3;
	pack.Reset();
	char sConfig[32];
	int iType = pack.ReadCell();
	pack.ReadString(sConfig, sizeof(sConfig));
	if (isCorrectPositionsandHaveCorrectWeapons())
	{
		ServerCommand("sm_cr_time 0 30"); // Setear reloj en 30 segundos
		ServerCommand("sm_cv l4d2_grenade_detonation_chance 0");
		ServerCommand("sm_cv st_mr_force_file \"%s\"",FILESTMR1);
		ServerCommand("sm_cv st_mr_play \"%d\"",clientinpos1);
		g_hTimerExecAMR1 = CreateTimer(0.4, Timer_ExecAMovementReader, clientinpos1, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		ServerCommand("sm_cv st_mr_force_file \"%s\"",FILESTMR2);
		ServerCommand("sm_cv st_mr_play \"%d\"",clientinpos2);
		g_hTimerExecAMR2 = CreateTimer(0.4, Timer_ExecAMovementReader, clientinpos2, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		ServerCommand("sm_cv st_mr_force_file \"%s\"",FILESTMR3);
		ServerCommand("sm_cv st_mr_play \"%d\"",clientinpos3);
		g_hTimerExecAMR3 = CreateTimer(0.4, Timer_ExecAMovementReader, clientinpos3, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	else
	{
		#if DEBUG
		PrintToChatAll("no cumple con posicion o armas o vida o zombies lejos");
		#endif
		PrintToServer("no cumple con posicion o armas o vida o zombies lejos");	
	}
	g_hTimers[iType] = null;
}

public void OnPlayEnd(int client, const char[] name)
{
	if (client==clientinpos1)
	{
		ServerCommand("sm_cv l4d2_grenade_detonation_chance 5");
		delete g_hTimerExecAMR1;
	}
	if (client==clientinpos2)
	{
		delete g_hTimerExecAMR2;
	}
	if (client==clientinpos3)
	{
		delete g_hTimerExecAMR3;
	}
}





public void OnPlayLine(int client, const char[] name,int ticks,int buttons)
{
	/*int anim;
	anim=clientAnim[client];
	bool validAnimation = validateAnimation(anim);
	if (!validAnimation)
	{
		SetConVarInt(FindConVar("st_mr_stop_player"), client);
	}*/
	//if (StrContains(g_cRunnerMR[client],"run") != -1 && !(ticks%5))
	if (StrContains(name, "run") != -1)
	{
		if (ticks == 1)
		{
			STMR_client1 = client;
		}
		int anim;
		anim=clientAnim[client];
		bool validAnimation = validateAnimation(anim);
		if (!validAnimation)
		{
			SetConVarInt(FindConVar("st_mr_stop_player"), client);		 //Runner
			SetConVarInt(FindConVar("st_mr_stop_player"), STMR_client2); //GL
			SetConVarInt(FindConVar("st_mr_stop_player"), STMR_client3); //Vomit
		}
		if (ticks == 50)
		{
			GetClientAbsOrigin(client, g_vPosRun); //Vomit Jar Boost Impact
			//g_vPosRun[2] += 100.0;
			//obtener posicion del runner mas abajo para teletransportar el vomito aqui y evitar que se quede colgado el que lanza vomito
			g_vPosRun[2] -= 25.0;
		}
		if (!(ticks%5))
		{
			#if DEBUG
			PrintToChat(client,"Player %d STMR %s",client,name);
			#endif
			float position[3];
			GetClientEyePosition(client,position);
			float vecMins[3];
			vecMins[0] = -g_DamageRadius;
			vecMins[1] = -g_DamageRadius;
			vecMins[2] = -g_DamageRadius;
			float vecMaxs[3];
			vecMaxs[0] = g_DamageRadius;
			vecMaxs[1] = g_DamageRadius;
			vecMaxs[2] = g_DamageRadius;
			TR_EnumerateEntitiesHull(position,position,vecMins,vecMaxs,MASK_SOLID_BRUSHONLY|MASK_VISIBLE,TraceDamageInfecteds,client);
		}
	}
	if (StrContains(name, "gl") != -1)
	{
		if (ticks == 1)
		{
			STMR_client2 = client;
		}
		int anim;
		anim=clientAnim[client];
		bool validAnimation = validateAnimation(anim);
		if (!validAnimation)
		{
			SetConVarInt(FindConVar("st_mr_stop_player"), STMR_client1); //Runner
			SetConVarInt(FindConVar("st_mr_stop_player"), client); 		 //GL
			SetConVarInt(FindConVar("st_mr_stop_player"), STMR_client3); //Vomit
			//return Plugin_Handled;
		}
		if (ticks == 45)
		{
			int entity_gl;
			while ((entity_gl = FindEntityByClassname(entity_gl, "grenade_launcher_projectile")) > 0)
			{
				if (client == GetEntPropEnt(entity_gl, Prop_Send, "m_hThrower"))
				{						
					GetClientEyeAngles(client, g_vAngGL);
					g_vAngGL[0] -= 90.0;
					g_vVec[0] = 0.0;
					g_vVec[1] = 0.0;
					g_vVec[2] = FindConVar("grenadelauncher_velocity").FloatValue;
					TeleportEntity(entity_gl, g_vPosBile, g_vAngGL, g_vVec);// Teleport Teleport grenade_launcher_projectile to Bile Position
					//PrintToChatAll("Teleport grenade_launcher_projectile");
				}
			}
		}
	}
	if (StrContains(name, "bile") != -1)
	{
		if (ticks == 1)
		{
			STMR_client3 = client;
		}
		int anim;
		anim=clientAnim[client];
		bool validAnimation = validateAnimation(anim);
		if (!validAnimation)
		{
			SetConVarInt(FindConVar("st_mr_stop_player"), STMR_client1); //Runner
			SetConVarInt(FindConVar("st_mr_stop_player"), STMR_client2); //GL
			SetConVarInt(FindConVar("st_mr_stop_player"), client);		 //Vomit
		}
		if (ticks == 45)
		{
			GetClientAbsOrigin(client, g_vPosBile); //Grenade Launcher Boost Impact
			g_vPosBile[2] -= 115.0;
		}
		if (ticks == 50)
		{
			int entity_bile;
			while ((entity_bile = FindEntityByClassname(entity_bile, "vomitjar_projectile")) > 0)
			{
				//if (client == GetEntPropEnt(entity_bile, Prop_Send, "m_hThrower") && client == GetEntPropEnt(entity_bile, Prop_Send, "m_hOwnerEntity"))
				if (client == GetEntPropEnt(entity_bile, Prop_Send, "m_hThrower"))
				{
					//GetClientEyeAngles(client, g_vAngBile);
					g_vAngBile[0] = 0.0;
					g_vAngBile[1] = 90.0;
					g_vAngBile[2] = 0.0;
					g_vVec[0] = 0.0;
					g_vVec[1] = 0.0;
					g_vVec[2] = 0.0;
					TeleportEntity(entity_bile, g_vPosRun, g_vAngBile, g_vVec); // Teleport vomitjar_projectile to Runner Position
					//PrintToChatAll("Teleport vomitjar_projectile");
					
					int prop = CreateEntityByName("prop_physics");
					SetEntityModel(prop, "models/props_junk/propanecanister001a.mdl");
					DispatchKeyValue(prop, "spawnflags", "8"); // https://developer.valvesoftware.com/wiki/Physics_optimization
					//DispatchKeyValue(prop, "targetname", CVARMAP);
					DispatchKeyValue(prop, "disableshadows", "1");
					SetEntityMoveType(prop, MOVETYPE_NONE);
					SetEntityRenderMode(prop, RENDER_NONE);
					GetEntPropVector(entity_bile, Prop_Data, "m_vecOrigin", g_vPosTemp);
					g_vPosTemp[0] += 5.0;
					g_vPosTemp[1] -= 7.0;
					g_vPosTemp[2] -= 15.0;
					//g_vPosRun[0] += 7.5;
					//g_vPosRun[1] -= 7.5;
					//g_vPosRun[2] -= 35.0;
					TeleportEntity(prop, g_vPosTemp, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(prop);
					ActivateEntity(prop);
					SetEntProp(prop, Prop_Data, "m_iHealth", 1000.0);
					//PrintToChatAll("Teleport PropaneTank %f %f %f", g_vPosTemp[0], g_vPosTemp[1], g_vPosTemp[2]);
					SetVariantString("OnUser1 !self:Kill::0.2:-1");
					AcceptEntityInput(prop, "AddOutput");
					AcceptEntityInput(prop, "FireUser1");
					//SetEntProp(prop, Prop_Data, "m_iHammerID", -1); // Set value to check it on SpawnPost/EntitySpawned/NextFrame
					
					//ActivateEntity(prop);
					//SDKHook(prop, SDKHook_SetTransmit, OnSetTransmit); // Fix to hide the outline glow
					/*DataPack pack = new DataPack();
					pack.WriteCell(prop);
					PropaneTimer = CreateTimer(1.0, TimerRemoveEntity, pack);*/

					//if (IsValidClient(client))
					//	SetEntPropEnt(prop, Prop_Send, "m_hOwnerEntity", client);
					//RequestFrame(OnNextFrameBreak, EntIndexToEntRef(prop)); // Next frame to prevent crashes
				}
			}
		}
	}
}

/*public Action TimerRemoveEntity(Handle timer, int prop)
{
	//RemoveEntity(prop);
	return Plugin_Continue;
}*/

public Action OnSetTransmit(int entity, int client)
{
    // Never transmits
    return Plugin_Handled;
}

bool TraceDamageInfecteds(int entity, any data)
{
	if(IsValidEdict(entity) && IsValidEntity(entity))
	{
		char classname[16];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrContains(classname,"infected") != -1)
		{
			float clientPos[3];
			float entPos[3];
			GetClientAbsOrigin(data, clientPos);
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entPos);
			if (FloatAbs(GetVectorDistance(clientPos,entPos)) <= g_DamageRadius)
			{
				SDKHooks_TakeDamage(entity,data,data,100000.0,DMG_BLAST,-1,NULL_VECTOR,entPos);
				//RemoveEntity(entity);
			}
			return true;
		}
	}
	return false;
}

public Action Timer_ExecAMovementReader(Handle timer,int target)
{
	#if DEBUG
	PrintToChatAll("Timer_ExecAMovementReader");
	PrintToChatAll("target %d", target);
	PrintToChatAll("clientinpos1 %d", clientinpos1);
	PrintToChatAll("clientinpos2 %d", clientinpos2);
	PrintToChatAll("clientinpos3 %d", clientinpos3);
	#endif
	//float DISTANCESETTING = float(18);
	//float DISTANCESETTINGINFECTED = float(100);
	float targetVector[3];
	//int infected = -1;
	/*while( (infected = FindEntityByClassname(infected, "infected")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropVector(infected, Prop_Data, "m_vecOrigin", targetVector);
		float distance = GetVectorDistance(targetVector, impact1);
		if (distance < DISTANCESETTINGINFECTED)
		{
			#if DEBUG
			PrintToChatAll("Infectado: Parar ejecucion de:%d",target);
			#endif
			ServerCommand("st_mr_stop %d",target);
			if (target==clientinpos1)
				delete g_hTimerExecAMR1;
			if (target==clientinpos2)
				delete g_hTimerExecAMR2;
			ServerCommand("st_mr_stop %d",clientinpos1);
			ServerCommand("st_mr_stop %d",clientinpos2);
		}
	}		*/
	if (IsValidClient(target) && GetClientTeam(target) == 2 && !IsClientPinned(target) && !(GetEntProp(target, Prop_Send, "m_isIncapacitated")) )//&& !SDKCall(hIsStaggering, target))
	{
		#if DEBUG
		PrintToChatAll("Timer condiciones de vivo target %d",target);
		#endif
		GetClientAbsOrigin(target, targetVector);
		float fHealth = GetEntPropFloat(target, Prop_Send, "m_healthBuffer");
		ConVar g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
		fHealth -= (GetGameTime() - GetEntPropFloat(target, Prop_Send, "m_healthBufferTime")) * g_hCvarDecayRate.FloatValue;
		if( fHealth < 0.0 )
			fHealth = 0.0;
		if ((GetClientHealth(target)+RoundFloat(fHealth))>=40)
		{
			int anim;
			anim=clientAnim[target];
			
			bool validAnimation = validateAnimation(anim);
			
			/*
			bool validAnimation = true;
			int invalidAnims[1939];
			invalidAnims[1]=10;
			invalidAnims[2]=12;
			for (int validation = 1; validation <= 1939; validation++)
			{
				if (anim==invalidAnims[validation])
				{
					validAnimation=false;
				}
			}
			*/

			if (!validAnimation)
			{
				ServerCommand("st_mr_stop %d",target);
				#if DEBUG
				PrintToChatAll("Anim: Parar ejecucion de:%d",target);
				#endif
				if (target==clientinpos1)
					delete g_hTimerExecAMR1;
				if (target==clientinpos2)
					delete g_hTimerExecAMR2;
				if (target==clientinpos3)
					delete g_hTimerExecAMR3;
				ServerCommand("st_mr_stop %d",clientinpos1);
				ServerCommand("st_mr_stop %d",clientinpos2);
				ServerCommand("st_mr_stop %d",clientinpos3);
			}

			//if ((anim != 515)||(anim != 520)||!((anim >= 973)&&(anim <= 982))||!((anim >= 987)&&(anim <= 1008)))
			/*if ((anim != 972)||(anim != 974)||!((anim >= 10)&&(anim <= 11))||(anim != 14)||(anim != 85)||(anim != 97)||!((anim >= 109)&&(anim <= 110))||!((anim >= 131)&&(anim <= 133))||!((anim >= 312)&&(anim <= 323))||!((anim >= 325)&&(anim <= 326))||(anim != 332)||!((anim >= 334)&&(anim <= 335))||!((anim >= 338)&&(anim <= 350))||!((anim >= 351)&&(anim <= 378))||!((anim >= 512)&&(anim <= 520))||(anim != 520)||(anim != 942)||!((anim >= 946)&&(anim <= 974))||((anim >= 976)&&(anim <= 980))||!((anim >= 983)&&(anim <= 989))||!((anim >= 991)&&(anim <= 994))||!((anim >= 997)&&(anim <= 1002))||!((anim >= 1004)&&(anim <= 1006))||!((anim >= 1009)&&(anim <= 1011))||!((anim >= 1013)&&(anim <= 1017))||!((anim >= 1020)&&(anim <= 1021))||!((anim >= 1023)&&(anim <= 1027))||!((anim >= 1030)&&(anim <= 1034))||!((anim >= 1037)&&(anim <= 1041))||!((anim >= 1045)&&(anim <= 1051))||!((anim >= 1053)&&(anim <= 1055))||!((anim >= 1058)&&(anim <= 1063))||!((anim >= 1067)&&(anim <= 1076))||!((anim >= 1080)&&(anim <= 1092))||!((anim >= 1094)&&(anim <= 1096))||!((anim >= 1098)&&(anim <= 1102))||!((anim >= 1104)&&(anim <= 1106))||!((anim >= 1108)&&(anim <= 1112))||!((anim >= 1114)&&(anim <= 1118))||!((anim >= 1121)&&(anim <= 1137))||!((anim >= 1139)&&(anim <= 1140))||(anim != 1142)||!((anim >= 1144)&&(anim <= 1159))||!((anim >= 1161)&&(anim <= 1162))||(anim != 1164)||!((anim >= 1166)&&(anim <= 1185))||!((anim >= 1187)&&(anim <= 1188))||(anim != 1190)||!((anim >= 1192)&&(anim <= 1207))||!((anim >= 1209)&&(anim <= 1210))||(anim != 1212)||!((anim >= 1214)&&(anim <= 1223))||(anim != 1225)||!((anim >= 1227)&&(anim <= 1239))||!((anim >= 1241)&&(anim <= 1242))||(anim != 1244)||!((anim >= 1246)&&(anim <= 1249)))
			{
				ServerCommand("st_mr_stop %d",target);
				#if DEBUG
				PrintToChatAll("Anim: Parar ejecucion de:%d",target);
				#endif
				if (target==clientinpos1)
					delete g_hTimerExecAMR1;
				if (target==clientinpos2)
					delete g_hTimerExecAMR2;
				ServerCommand("st_mr_stop %d",clientinpos1);
				ServerCommand("st_mr_stop %d",clientinpos2);
			}
			*/
		}
		else
		{
			#if DEBUG
			PrintToChatAll("Vida> Parar ejecucion de:%d",target);
			#endif
			ServerCommand("st_mr_stop %d",target);
			if (target==clientinpos1)
				delete g_hTimerExecAMR1;
			if (target==clientinpos2)
				delete g_hTimerExecAMR2;
			if (target==clientinpos3)
				delete g_hTimerExecAMR3;
			ServerCommand("st_mr_stop %d",clientinpos1);
			ServerCommand("st_mr_stop %d",clientinpos2);
			ServerCommand("st_mr_stop %d",clientinpos3);
		}
	}
	else
	{
			#if DEBUG
			PrintToChatAll("Client> Parar ejecucion de:%d",target);
			#endif
			ServerCommand("st_mr_stop %d",target);
			if (target==clientinpos1)
				delete g_hTimerExecAMR1;
			if (target==clientinpos2)
				delete g_hTimerExecAMR2;
			if (target==clientinpos3)
				delete g_hTimerExecAMR3;
			ServerCommand("st_mr_stop %d",clientinpos1);
			ServerCommand("st_mr_stop %d",clientinpos2);
			ServerCommand("st_mr_stop %d",clientinpos3);
	}
}

bool isCorrectPositionsandHaveCorrectWeapons()
{
	#if DEBUG
	PrintToChatAll("isCorrectPositionsandHaveCorrectWeapons");
	#endif
	float DISTANCESETTING = float(18);
//	float DISTANCESETTINGINFECTED = float(100);
	float targetVector[3];
	float impact1[3];
	impact1[0] = IMPACT1ORIGIN0;
	impact1[1] = IMPACT1ORIGIN1;
	impact1[2] = IMPACT1ORIGIN2;
	float impact2[3];
	impact2[0] = IMPACT2ORIGIN0;
	impact2[1] = IMPACT2ORIGIN1;
	impact2[2] = IMPACT2ORIGIN2;
	float impact3[3];
	impact3[0] = IMPACT3ORIGIN0;
	impact3[1] = IMPACT3ORIGIN1;
	impact3[2] = IMPACT3ORIGIN2;
	clientinpos1=0;
	clientinpos2=0;
	clientinpos3=0;
	//1ra posicion
	//int infected = -1;
	bool infectedinarea=false;
	/*
	while( (infected = FindEntityByClassname(infected, "infected")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropVector(infected, Prop_Data, "m_vecOrigin", targetVector);
		float distance = GetVectorDistance(targetVector, impact1);
		if (distance < DISTANCESETTINGINFECTED)
		{
			infectedinarea=true;
			#if DEBUG
			PrintToChatAll("infectedinarea 1");
			#endif
			break;
		}
	}

	while( (infected = FindEntityByClassname(infected, "infected")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropVector(infected, Prop_Data, "m_vecOrigin", targetVector);
		float distance = GetVectorDistance(targetVector, impact2);
		if (distance < DISTANCESETTINGINFECTED)
		{
			infectedinarea=true;
			#if DEBUG
			PrintToChatAll("infectedinarea 2");
			#endif
			break;
		}
	}
	*/
	if (!infectedinarea)
	{
		#if DEBUG
		PrintToChatAll("no hay infectados");
		#endif
		for (int target=1;target<=MaxClients;target++)
		{

			if (IsValidClient(target) && GetClientTeam(target) == 2 && !IsClientPinned(target) && !(GetEntProp(target, Prop_Send, "m_isIncapacitated")) )//&& !SDKCall(hIsStaggering, target))
			{
				#if DEBUG
				PrintToChatAll("condiciones de vivo 1");
				#endif

				GetClientAbsOrigin(target, targetVector);
				float distance = GetVectorDistance(targetVector, impact1);
				if (distance < DISTANCESETTING)
				{
					#if DEBUG
					PrintToChatAll("Distancia Correcta %d",target);
					#endif
					static char sClass[25];
					int iWeapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
					if( iWeapon != -1 )
					{
						GetEdictClassname(iWeapon, sClass, sizeof(sClass));
						PrintToServer("Weapon si esta %d",iWeapon);
						bool validararma=validateWeaponfromListinHand(1,sClass);
						if( validararma )
						{
							#if DEBUG
							PrintToChatAll("Clase esta dentro de la lista: %s",sClass);
							#endif
							int iAmmoinClip = GetEntProp(iWeapon, Prop_Send, "m_iClip1");
							if( iAmmoinClip > 0 )
							{
								#if DEBUG
								PrintToChatAll("Si tiene balas %d",iAmmoinClip);
								#endif
								/*
								int test;
								test=L4D2_OnStagger(clientinpos1,clientinpos2);
								if (test) PrintToChatAll("L4D2_OnStagger(target) test if %d",clientinpos1);
									else PrintToChatAll("L4D2_OnStagger(target) test else %d",clientinpos1);
								PrintToChatAll("L4D2_OnStagger(target) test %d",clientinpos1);
								*/
								//if (!g_bStagger[clientinpos1])
								//{

								int anim;
								anim=clientAnim[target];

								bool validAnimation = validateAnimation(anim);

								/*
								bool validAnimation = true;
								int invalidAnims[1939];
								invalidAnims[1]=10;
								invalidAnims[2]=12;
								for (int validation = 1; validation <= 1939; validation++)
								{
									if (anim==invalidAnims[validation])
									{
										validAnimation=false;
									}
								}
								*/
								//if ((anim != 515)||(anim != 520)||!((anim >= 973)&&(anim <= 982))||!((anim >= 987)&&(anim <= 1008)))
								//if ((anim != 972)||(anim != 974)||!((anim >= 10)&&(anim <= 11))||(anim != 14)||(anim != 85)||(anim != 97)||!((anim >= 109)&&(anim <= 110))||!((anim >= 131)&&(anim <= 133))||!((anim >= 312)&&(anim <= 323))||!((anim >= 325)&&(anim <= 326))||(anim != 332)||!((anim >= 334)&&(anim <= 335))||!((anim >= 338)&&(anim <= 350))||!((anim >= 351)&&(anim <= 378))||!((anim >= 512)&&(anim <= 520))||(anim != 520)||(anim != 942)||!((anim >= 946)&&(anim <= 974))||((anim >= 976)&&(anim <= 980))||!((anim >= 983)&&(anim <= 989))||!((anim >= 991)&&(anim <= 994))||!((anim >= 997)&&(anim <= 1002))||!((anim >= 1004)&&(anim <= 1006))||!((anim >= 1009)&&(anim <= 1011))||!((anim >= 1013)&&(anim <= 1017))||!((anim >= 1020)&&(anim <= 1021))||!((anim >= 1023)&&(anim <= 1027))||!((anim >= 1030)&&(anim <= 1034))||!((anim >= 1037)&&(anim <= 1041))||!((anim >= 1045)&&(anim <= 1051))||!((anim >= 1053)&&(anim <= 1055))||!((anim >= 1058)&&(anim <= 1063))||!((anim >= 1067)&&(anim <= 1076))||!((anim >= 1080)&&(anim <= 1092))||!((anim >= 1094)&&(anim <= 1096))||!((anim >= 1098)&&(anim <= 1102))||!((anim >= 1104)&&(anim <= 1106))||!((anim >= 1108)&&(anim <= 1112))||!((anim >= 1114)&&(anim <= 1118))||!((anim >= 1121)&&(anim <= 1137))||!((anim >= 1139)&&(anim <= 1140))||(anim != 1142)||!((anim >= 1144)&&(anim <= 1159))||!((anim >= 1161)&&(anim <= 1162))||(anim != 1164)||!((anim >= 1166)&&(anim <= 1185))||!((anim >= 1187)&&(anim <= 1188))||(anim != 1190)||!((anim >= 1192)&&(anim <= 1207))||!((anim >= 1209)&&(anim <= 1210))||(anim != 1212)||!((anim >= 1214)&&(anim <= 1223))||(anim != 1225)||!((anim >= 1227)&&(anim <= 1239))||!((anim >= 1241)&&(anim <= 1242))||(anim != 1244)||!((anim >= 1246)&&(anim <= 1249)))
								if (!validAnimation)
								{
									#if DEBUG
									PrintToChatAll("clientinpos1 Animacion INCorrecta");
									#endif	
								}
								else
								{
									#if DEBUG
									PrintToChatAll("clientinpos1 Animacion Correcta");
									#endif	
									clientinpos1=target;	
									#if DEBUG
									PrintToChatAll("clientinpos1 %d",clientinpos1);
									#endif
								}
								//}
								break;
							}
						}
					}
				}
			}
		}
	}
	if (clientinpos1!=0)
	{
		for (int target=1;target<=MaxClients;target++)
		{

			//if (SDKCall(hIsStaggering, target))
				//PrintToChatAll("SDKCall(hIsStaggering, target)");

			if (IsValidClient(target) && GetClientTeam(target) == 2 && !IsClientPinned(target) && !(GetEntProp(target, Prop_Send, "m_isIncapacitated")) )//&& !SDKCall(hIsStaggering, target))
			{
				#if DEBUG
				PrintToChatAll("condiciones de vivo 2");
				#endif	
				if(target != clientinpos1)
				{
					GetClientAbsOrigin(target, targetVector);
					float distance = GetVectorDistance(targetVector, impact2);
					if (distance < DISTANCESETTING)
					{
						#if DEBUG
						PrintToChatAll("Distancia Correcta %d",target);
						#endif
						static char sClass[25];
						int iWeapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
						if( iWeapon != -1 )
						{
							GetEdictClassname(iWeapon, sClass, sizeof(sClass));
							PrintToServer("Weapon si esta %d",iWeapon);
							bool validararma=validateWeaponfromListinHand(2,sClass);
							if( validararma )
							{
								float fHealth = GetEntPropFloat(target, Prop_Send, "m_healthBuffer");
								ConVar g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
								fHealth -= (GetGameTime() - GetEntPropFloat(target, Prop_Send, "m_healthBufferTime")) * g_hCvarDecayRate.FloatValue;
								if( fHealth < 0.0 )
									fHealth = 0.0;
								if ((GetClientHealth(target)+RoundFloat(fHealth))>=40)
								{
									#if DEBUG
									PrintToChatAll("clientinpos2 tiene la vida necesaria.");
									#endif
									//if (!g_bStagger[clientinpos2])
									//{
									int anim;
									anim=clientAnim[target];
									bool validAnimation = validateAnimation(anim);
									/*
									bool validAnimation = true;
									int invalidAnims[1939];
									invalidAnims[1]=10;
									invalidAnims[2]=12;
									for (int validation = 1; validation <= 1939; validation++)
									{
										if (anim==invalidAnims[validation])
										{
											validAnimation=false;
										}
									}
									*/
									if (!validAnimation)
									{
										#if DEBUG
										PrintToChatAll("clientinpos2 Animacion INCorrecta");
										#endif
									}
									else
									{
										#if DEBUG
										PrintToChatAll("clientinpos2 animacion correcta.");
										#endif
										clientinpos2=target;
										#if DEBUG
										PrintToChatAll("clientinpos2 %d",clientinpos2);
										#endif
									}
									//}
									break;
								}
							}
						}
					}
				}
			}
		}
	}
	if ((clientinpos1!=0) && (clientinpos2!=0))
	{
		for (int target=1;target<=MaxClients;target++)
		{

			//if (SDKCall(hIsStaggering, target))
				//PrintToChatAll("SDKCall(hIsStaggering, target)");

			if (IsValidClient(target) && GetClientTeam(target) == 2 && !IsClientPinned(target) && !(GetEntProp(target, Prop_Send, "m_isIncapacitated")) )//&& !SDKCall(hIsStaggering, target))
			{
				#if DEBUG
				PrintToChatAll("condiciones de vivo 3");
				#endif
				if ((target != clientinpos1) && (target != clientinpos2))
				{
					GetClientAbsOrigin(target, targetVector);
					float distance = GetVectorDistance(targetVector, impact3);
					if (distance < DISTANCESETTING)
					{
						#if DEBUG
						PrintToChatAll("Distancia Correcta %d",target);
						#endif
						static char sClass[25];
						int iWeapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
						if( iWeapon != -1 )
						{
							GetEdictClassname(iWeapon, sClass, sizeof(sClass));
							PrintToServer("Weapon si esta %d",iWeapon);
							bool validararma=validateWeaponfromListinHand(3,sClass);
							if( validararma )
							{
								float fHealth = GetEntPropFloat(target, Prop_Send, "m_healthBuffer");
								ConVar g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
								fHealth -= (GetGameTime() - GetEntPropFloat(target, Prop_Send, "m_healthBufferTime")) * g_hCvarDecayRate.FloatValue;
								if( fHealth < 0.0 )
									fHealth = 0.0;
								if ((GetClientHealth(target)+RoundFloat(fHealth))>=40)
								{
									#if DEBUG
									PrintToChatAll("clientinpos3 tiene la vida necesaria.");
									#endif
									//if (!g_bStagger[clientinpos2])
									//{
									int anim;
									anim=clientAnim[target];
									bool validAnimation = validateAnimation(anim);
									
									/*
									bool validAnimation = true;
									int invalidAnims[1939];
									invalidAnims[1]=10;
									invalidAnims[2]=12;
									for (int validation = 1; validation <= 1939; validation++)
									{
										if (anim==invalidAnims[validation])
										{
											validAnimation=false;
										}
									}
									*/
									if (!validAnimation)
									{
										#if DEBUG
										PrintToChatAll("clientinpos3 Animacion INCorrecta");
										#endif
									}
									else
									{
										#if DEBUG
										PrintToChatAll("clientinpos3 animacion correcta.");
										#endif
										clientinpos3=target;
										#if DEBUG
										PrintToChatAll("clientinpos3 %d",clientinpos3);
										#endif
									}
									//}
									break;
								}
							}
						}
					}
				}
			}
		}
	}
	if ((clientinpos1!=0) && (clientinpos2!=0) && (clientinpos3!=0))
	{
		#if DEBUG
		PrintToChatAll("Cumplio condiciones");
		#endif
		return true;
	}
	return false;
}

/**
 * Config Parser
 */
public SMCResult ReadConfig_EndSection(SMCParser smc) {}

public SMCResult ReadConfig_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (!g_bSection || !key[0])
		return SMCParse_Continue;

	int iType;
	char sKeys[2][32];
	ExplodeString(key, ":", sKeys, sizeof(sKeys), sizeof(sKeys[]));
	if (!g_hTypes.GetValue(sKeys[0], iType))
		return SMCParse_Continue;

	g_hTries[iType].SetString(sKeys[1], value);
	if (iType == EVENT)
		HookEvent(sKeys[1], Event_Hook);

	return SMCParse_Continue;
}

public SMCResult ReadConfig_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	g_bSection = StrEqual(name, "*") || strncmp(g_sMap, name, strlen(name), false) == 0;
}


/**
 * Stocks
 */
void ExecClientsConfig(int iClients)
{
	if (!g_hEnabled.BoolValue)
		return;

	bool bIncludeBots = g_hIncludeBots.BoolValue;
	bool bIncludeSpec = g_hIncludeSpec.BoolValue;
	if (bIncludeBots && bIncludeSpec)
		iClients += GetClientCount();
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			bool bBot  = IsFakeClient(i);
			bool bSpec = IsClientObserver(i);
			if ((!bBot && !bSpec) ||
				(bIncludeBots && bBot) ||
				(bIncludeSpec && bSpec))
				iClients++;
		}
	}

	char sClients[4];
	IntToString(iClients, sClients, sizeof(sClients));
	ExecConfig(CLIENTS, sClients);
}

void ExecConfig(int iType, const char[] sKey)
{
	char sValue[64];
	if (!g_hTries[iType].GetString(sKey, sValue, sizeof(sValue)))
		return;

	char sValues[2][32];
	ExplodeString(sValue, ":", sValues, sizeof(sValues), sizeof(sValues[]));

	DataPack hPack = new DataPack();
	hPack.WriteCell(iType);
	hPack.WriteString(sValues[1]);
	g_hTimers[iType] = CreateTimer(StringToFloat(sValues[0]), Timer_ExecConfig, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
}

public Action ExecConfigCmd(int client, int args)
{

	//if( client == 0 )
	//{
		//PrintToConsole(client, "[Prueba] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	//	return Plugin_Handled;
	//}
	
	
	char sCmd[256];
	GetCmdArgString(sCmd, sizeof(sCmd));

	StripQuotes(sCmd);

	//char sValue[64];
	//if (!g_hTries[iType].GetString(sKey, sValue, sizeof(sValue)))
	//	return;

	//char sValues[2][32];
	//ExplodeString(sValue, ":", sValues, sizeof(sValues), sizeof(sValues[]));
	int iType=EVENT;
	DataPack hPack = new DataPack();
	hPack.WriteCell(iType);
	hPack.WriteString(sCmd);
	if (GetConVarBool(g_hGCEnable)) {
		g_hTimers[iType] = CreateTimer(0.1, Timer_ExecConfigCommand, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

void ParseConfig()
{
	if (!FileExists(g_sConfigFile))
		SetFailState("File Not Found: %s", g_sConfigFile);

	for (int i = 0; i < TOTAL; i++)
		g_hTries[i].Clear();

	SMCError iError = g_hConfigParser.ParseFile(g_sConfigFile);
	if (iError)
	{
		char sError[64];
		if (g_hConfigParser.GetErrorString(iError, sError, sizeof(sError)))
			LogError(sError);
		else
			LogError("Fatal parse error");
		return;
	}
}


public bool IsValidClient(int client)
{
	if (client <= 0)
		return false;

	if (client > MaxClients)
		return false;

	if (!IsClientConnected(client))
		return false;

	//if (IsFakeClient(client))
		//return false;

	if (!IsClientInGame(client))
		return false;

	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}

public bool IsValidClientandNotBot(int client)
{
	if (client <= 0)
		return false;

	if (client > MaxClients)
		return false;

	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return false;

	if (!IsClientInGame(client))
		return false;

	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}


//Es cliente?
public bool IsValidClientTon(int client)
{
	//Si no es BOT = false // cliente es falso
	if (!IsFakeClient(client))
		return false;
	//Si no es Superviviente  = false // cliente es falso
	if (IsFakeClient(client))//no es bot entonces es superviviente//a la inversa no es superviviente
		return false;
	//Si no estan Vivos = False
	if (!IsPlayerAlive(client))
		return false;

	return true;
}


bool IsClientPinned(int client)
{
	if( GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0
	) return true;

	if( g_bLeft4Dead2 &&
	(
		GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0
	)) return true;

	return false;
}



public Action verifyStagger (Event event, const char[] name, bool dontBroadcast)
{
	int id = GetClientOfUserId(event.GetInt("userid"));
	#if DEBUG
	PrintToChatAll("verifyStagger evento %s, jugador %d",name,id);
	#endif
	g_bStagger[id]=true;
	RequestFrame(Stagger,id);
	//if( IsClientInGame(id) )
	//AnimHookEnable(id, OnAnim, OnAnimPost);
	//ServerCommand("st_mr_stop");
}

void Stagger(int i)
{
	if (g_bStagger[i])
	{
		g_bStagger[i]=false;
		#if DEBUG
		PrintToChatAll("Staggereado, pasar a no staggereado %d",i);
		#endif
	}
	else
	{
		g_bStagger[i]=true;
		#if DEBUG
		PrintToChatAll("No Staggereado, pasar a staggereado %d",i);
		#endif
	}
}

public Action Timer_DetectAnim(Handle timer,int target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)//&& !SDKCall(hIsStaggering, target))
	{
		#if DEBUG
		PrintToChatAll("Anim cliente %d clientAnim %d",target,clientAnim[target]);
		#endif
		char animacion[MAX_NAME_LENGTH];
		IntToString(clientAnim[target],animacion,sizeof(animacion));
		RenameClient(target,animacion);
	}
}

public Action RenameClient(int client, char rename[MAX_NAME_LENGTH])
{	
	SetClientName(client, rename);
	PrintToChatAll("Cambiar nombre");
	return Plugin_Handled;
}




// Uses "Activity" numbers, which means 1 animation number is the same for all Survivors.	
Action OnAnim(int client, int &anim)
{
	//#if DEBUG
	//PrintToChatAll("OnAnim client %d, anim %d",client,anim);
	//#endif
	//if (clientinpos2==client)
	//{
	clientAnim[client]=anim;
	//}
	//if (clientinpos1==client)
	//{
	//}
	//return Plugin_Continue;
}

// Uses "m_nSequence" animation numbers, which are different for each model.
Action OnAnimPost(int client, int &anim)
{
	/*
	if( g_bCrawling )
	{
		static char model[40];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		switch( model[29] )
		{
			// case 'c': { Format(model, sizeof(model), "coach");		anim = -1; }
			case 'b': { Format(model, sizeof(model), "gambler");	anim = 631; }
			case 'h': { Format(model, sizeof(model), "mechanic");	anim = 636; }
			case 'd': { Format(model, sizeof(model), "producer");	anim = 639; }
			case 'v': { Format(model, sizeof(model), "NamVet");		anim = 539; }
			case 'e': { Format(model, sizeof(model), "Biker");		anim = 542; }
			case 'a': { Format(model, sizeof(model), "Manager");	anim = 539; }
			case 'n': { Format(model, sizeof(model), "TeenGirl");	anim = 529; }
		}
		return Plugin_Changed;
	}
	// */

	return Plugin_Continue;
}

bool musthaveanyWeaponfromListinHand(int pos)
{
	bool val = true;
	if (pos ==1 && (PIPEBOMBVAL1 || MOLOTOVVAL1 || VOMITJARVAL1 || GRENADE_LAUNCHERVAL1))
	{
		val=false;
	}
	if (pos ==2 && (PIPEBOMBVAL2 || MOLOTOVVAL2 || VOMITJARVAL2 || GRENADE_LAUNCHERVAL2))
	{
		val=false;
	}
	if (pos ==3 && (PIPEBOMBVAL3 || MOLOTOVVAL3 || VOMITJARVAL3 || GRENADE_LAUNCHERVAL3))
	{
		val=false;
	}
	return val;
}

bool validateWeaponfromListinHand(int pos, char sClass[25])
{
	bool val = false;
	if (pos ==1) //GL Hand Weapon
	{
		val=musthaveanyWeaponfromListinHand(1);
		if (PIPEBOMBVAL1 && strcmp(sClass[7], "pipe_bomb") == 0)
		{
			val=true;
		}
		if (MOLOTOVVAL1 && strcmp(sClass[7], "molotov") == 0)
		{
			val=true;
		}
		if (VOMITJARVAL1 && strcmp(sClass[7], "vomitjar") == 0)
		{
			val=true;
		}
		if (GRENADE_LAUNCHERVAL1 && strcmp(sClass[7], "grenade_launcher") == 0)
		{
			val=true;
		}
	}
	if (pos ==2) //Vomit Hand Weapon
	{
		val=musthaveanyWeaponfromListinHand(2);
		if (PIPEBOMBVAL2 && strcmp(sClass[7], "pipe_bomb") == 0)
		{
			val=true;
		}
		if (MOLOTOVVAL2 && strcmp(sClass[7], "molotov") == 0)
		{
			val=true;
		}
		if (VOMITJARVAL2 && strcmp(sClass[7], "vomitjar") == 0)
		{
			val=true;
		}
		if (GRENADE_LAUNCHERVAL2 && strcmp(sClass[7], "grenade_launcher") == 0)
		{
			val=true;
		}
	}
	if (pos ==3) //Runner Hand Weapon
	{
		val=musthaveanyWeaponfromListinHand(3);
		if (PIPEBOMBVAL3 && strcmp(sClass[7], "pipe_bomb") == 0)
		{
			val=true;
		}
		if (MOLOTOVVAL3 && strcmp(sClass[7], "molotov") == 0)
		{
			val=true;
		}
		if (VOMITJARVAL3 && strcmp(sClass[7], "vomitjar") == 0)
		{
			val=true;
		}
		if (GRENADE_LAUNCHERVAL3 && strcmp(sClass[7], "grenade_launcher") == 0)
		{
			val=true;
		}
	}
	return val;
}
bool validateAnimation(int anim)
{
	bool validAnimation=true;
	int invalidAnimations[] = {
		20,696,697,698,700,701,770,771,772,773,774,775,776,777,778,779,780,781,782,783,784,785,799, //Inccaped Hunter/Smoker/Jockey
		521,522,523,791, //Tank
		524,525,526,527,528,529,530,531,532,533,534, //Charger
		621,622,623,624,625,626,627,628,629,630,631,632,633,634,635,636, //Shove
		637,638,639,640,641,642,643, //Shove WALL & SIT
		693,694 //Flinch (Example: when a zombie hit you, but apparently this not work.)
	};
	for (int validation=0; validation < sizeof(invalidAnimations); validation++)
	{
		if (anim==invalidAnimations[validation])
		{
			return !validAnimation;
		}
	}
	return validAnimation;
}