// This is 1.0.0.5NN edited by Natalya and is not yet official.
#pragma semicolon 1
#include <sourcemod>
#include <mapchooser>
#include <sdktools>
#include <cstrike>
#include <rallymod>

#define  RALLYRACE_VERSION			"1.0.0.5NN"

public Plugin:myinfo =
{
	name = "CSS Rally Race",
	author = "ben",
	description = "CSS Rally Race",
	version = RALLYRACE_VERSION,
	url = "http://www.ZombieX2.net/"
};

//////////////////////////////////////////////
//					CONFIG					//
//////////////////////////////////////////////
#define 	DEBUG			1					// print debug message for getting entitys

new String:place_name[][3] = {"","st","nd","rd","th"};

//////////////////////////////////////////////
//				END CONFIG					//
//////////////////////////////////////////////

#define 	MAX_CAR							100		// will you make more than 100 cars?
#define		MAXENTITYS						2048
#define  	MODEL_BUGGY	"models/buggy.mdl"
#define		ENTITYS_ARRAY_SIZE				3
#define		ENTITYS_ZONE_TYPE				0
#define		ENTITYS_CHECK_POINT_INDEX		1
#define		ENTITYS_CHECK_POINT_PASSED		2
#define  	CMD_RANDOM		0
#define		NONE			0
#define		READY			1
#define		RACING			2

#define 	CHECKPOINT		0
#define 	POSITION		1

#define 	CHECKPOINT_ENTITY			"trigger_multiple"
#define 	CAR_SPAWN_ENTITY			"info_target"
#define		CHECKPOINT_NAME				"checkpoint_#"
#define		READYZONE_NAME				"ready_zone"
#define		SPECTATE_ZONE_NAME			"spectate_zone"
#define		CAR_SPAWN_NAME				"car_spawn"

enum TriggerType {
	TT_CHECKPOINT,
	TT_READYPOINT,
	TT_SPECPOINT
};

new String:g_Car_model[MAX_CAR][256];
new String:g_Car_script[MAX_CAR][256];
new g_Car_skin_min[MAX_CAR];
new g_Car_skin_max[MAX_CAR];
new g_Total_Car;

new m_vecOrigin;
new m_angRotation;
new m_ArmorValue;
new m_hRagdoll;
new m_hOwnerEntity;

new g_Entitys[ENTITYS_ARRAY_SIZE][MAXENTITYS+1];

new Float:g_Player_JoinReadyTime[MAXPLAYERS+1];
new Float:g_Player_LastCheckPointTime[MAXPLAYERS+1];
new Float:g_Player_RaceTime[MAXPLAYERS+1];
new bool:g_Player_CanBoost[MAXPLAYERS+1];

new g_Player_CheckPoint[MAXPLAYERS+1][2];

new g_Max_CheckPoint;
new g_Player_Race_Finish;
new g_Player_Race_Count;

new Handle:g_RaceTimer = INVALID_HANDLE;
new Handle:g_CarSpawnArray = INVALID_HANDLE;
new g_Game_Stats;
new g_Game_CountDown;
new g_Game_Race_Round_Count;

new Handle:g_PlayerTimer[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:hIncrementFragCount = INVALID_HANDLE;
new Handle:hResetFragCount = INVALID_HANDLE;
new Handle:hIncrementDeathCount = INVALID_HANDLE;
new Handle:hResetDeathCount = INVALID_HANDLE;
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hCleanUp = INVALID_HANDLE;

new Handle:h_rallyrace_readytime = INVALID_HANDLE;
new Handle:h_rallyrace_racetime = INVALID_HANDLE;
new Handle:h_rallyrace_raceround = INVALID_HANDLE;
new Handle:h_rallyrace_car;
new Handle:F_OnPlayerFinishRace = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	m_vecOrigin = FindSendPropInfo("CBaseEntity", "m_vecOrigin");
	m_angRotation = FindSendPropInfo("CBaseEntity", "m_angRotation");
	m_ArmorValue = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	m_hRagdoll = FindSendPropInfo("CCSPlayer", "m_hRagdoll");
	m_hOwnerEntity = FindSendPropOffs("CBaseEntity","m_hOwnerEntity");

	CreateConVar("rallyrace_version",RALLYRACE_VERSION,"Rally Race Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	h_rallyrace_readytime = CreateConVar("rallyrace_readytime","20","Ready Time",0,true,5.0,true,120.0);
	h_rallyrace_racetime= CreateConVar("rallyrace_racetime","320","Racers will force suicide to end current race round after this value (0 = disable)",0,true,0.0);
	h_rallyrace_raceround = CreateConVar("rallyrace_raceround","6","How many race round start a map vote? (0 = disable)",0,true,0.0);
	h_rallyrace_car = CreateConVar("rallyrace_car", "1", "What car will be used?",0,true,0.0 );

	HookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	HookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);
	HookEvent("player_death",Ev_player_death);
	HookEvent("player_spawn",Ev_player_spawn);
	HookEvent("player_team",Ev_player_team,EventHookMode_Pre);

	RCM_BlockRoundEnd(true);

	g_CarSpawnArray = CreateArray();

	hGameConf = LoadGameConfigFile("rallymod");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IncrementFragCount");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hIncrementFragCount = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "ResetFragCount");
	hResetFragCount = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IncrementDeathCount");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hIncrementDeathCount = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "ResetDeathCount");
	hResetDeathCount = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"CleanUp");
	hCleanUp = EndPrepSDKCall();

	F_OnPlayerFinishRace = CreateGlobalForward("OnPlayerFinishRace",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Float);

	AutoExecConfig(true, "rallyrace");
	RegConsoleCmd("sm_car_exit", Car_Exit, " -- Exit a Drivable Vehicle");
}


#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	RegPluginLibrary("rallyrace");
	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
    return APLRes_Success;
	#else
	    return true;
	#endif
}

public OnPluginEnd()
{
	UnhookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	UnhookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);

	RCM_BlockRoundEnd(false);
	ClearArray(g_CarSpawnArray);
	CloseHandle(F_OnPlayerFinishRace);
}

public OnClientPutInServer(client)
{
	g_Player_JoinReadyTime[client] = 0.0;
	g_Player_LastCheckPointTime[client] = 0.0;
	g_Player_CheckPoint[client][CHECKPOINT] = 0;
	g_Player_CheckPoint[client][POSITION] = 0;
	g_Player_RaceTime[client] = 0.0;
	g_Player_CanBoost[client] = true;
	KillPlayerTimer(client);
	CreateTimer(1.0,PlayerTextDisplayTimer,client,TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	RemovePlayerCar(client);
	g_Player_JoinReadyTime[client] = 0.0;
	g_Player_LastCheckPointTime[client] = 0.0;
	g_Player_CheckPoint[client][CHECKPOINT] = 0;
	g_Player_CheckPoint[client][POSITION] = 0;
	g_Player_RaceTime[client] = 0.0;
	g_Player_CanBoost[client] = true;
	KillPlayerTimer(client);
}


public OnMapStart()
{
	g_Game_Race_Round_Count = 0;
	g_Total_Car = 0;

	ReadDownloadFile();

	ClearArray(g_CarSpawnArray);

	if(!ReadCarConfig())
	{
		PrintToServer("[*] Unable To Load Car Config!");
		return;
	}

	InitEntityArray();
	LoadPointEntitys();
	CheckEnoughPlayer();
}

public Action:Ev_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new team = GetEventInt(event,"team");
	if(!client || !IsClientInGame(client) || team <  2)
		return Plugin_Continue;

	if(!IsPlayerAlive(client))
	{
		RespawnClient(1.0,client);
	}
	return Plugin_Handled;
}

public Ev_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(!IsClientInGame(client) || GetClientTeam(client) < 2)
		return;

	new weaponIndex;
	for(new i=0;i<=1;i++)
	{
		weaponIndex = GetPlayerWeaponSlot(client,i);
		if(weaponIndex != -1)
		{
			RemovePlayerItem(client, weaponIndex);
			RemoveEdict(weaponIndex);
		}
	}
	weaponIndex = GetPlayerWeaponSlot(client,2);
	if(weaponIndex != -1)
	{
		EquipPlayerWeapon(client,weaponIndex);
	}
	g_Player_JoinReadyTime[client] = 0.0;
	SetEntData(client,m_ArmorValue,0,4,true);

	RemoveIdleWeapon();
}

public Ev_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	Disintegrate(victim);
	RemovePlayerCar(victim);

	if(g_Player_RaceTime[victim] != 0.0 && GetClientTeam(victim) == 3)
	{
		CS_SwitchTeam(victim,2);
		g_Player_JoinReadyTime[victim] = 0.0;
	}
	RespawnClient(0.5,victim);
}

public Action:RaceTimerFunc(Handle:timer)
{
	switch(g_Game_Stats)
	{
		case NONE: // check enough player to start run reday time
		{
			new maxClients = GetMaxClients();
			new total = 0;
			for (new i=1; i<=maxClients; i++)
				if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
					total++;

			if(total >= 1) // enough player! go to reday time count down
			{
				g_Game_CountDown = GetConVarInt(h_rallyrace_readytime);
				g_Game_Stats = READY;
			} else {
				PrintCenterTextAll("Not enough player to start, at least 1 players!");
			}
		}
		case READY:
		{
			PrintCenterTextAll("%ds Race Start\n      \"GO!\"",g_Game_CountDown);
			g_Game_CountDown--;
			if(g_Game_CountDown >= 0) // counting down...
				return Plugin_Continue;

			new maxClients = GetMaxClients();
			new total = 0;
			new clients[maxClients];
			for (new i=1; i<=maxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i))
				{
					g_Player_CheckPoint[i][CHECKPOINT] = 0;
					g_Player_CheckPoint[i][POSITION] = 0;
					g_Player_RaceTime[i] = 0.0;
					g_Player_CanBoost[i] = true;
					ResetDeath(i);
					ResetScore(i);
					if(GetClientTeam(i) == 2 && g_Player_JoinReadyTime[i] != 0.0)
						clients[total++] = i;
				}
			}
			if(total == 0) // no one in ready zone, check enough player again
			{
				PrintCenterTextAll("Nobody Ready\n   Wait Again");
				g_Game_Stats = NONE;
				return Plugin_Continue;
			}
			g_Player_Race_Finish = 0;
			g_Player_Race_Count = 0;
			PrintCenterTextAll("");
			g_Game_Stats = RACING;
			g_Game_CountDown = GetConVarInt(h_rallyrace_racetime) + 4;
			ResetCheckPointsPass();
			SpawnCarsToRace(clients,total);
		}
		case RACING:
		{
			g_Game_CountDown--;
			new racetime = GetConVarInt(h_rallyrace_racetime);
			if(g_Game_CountDown >= racetime)
			{
				if(g_Game_CountDown == (racetime + 3))
					ShowOverlays("r_screenoverlay zx2_car/3");
				else if(g_Game_CountDown == (racetime + 2))
					ShowOverlays("r_screenoverlay zx2_car/2");
				else if(g_Game_CountDown == (racetime + 1))
					ShowOverlays("r_screenoverlay zx2_car/1");
				else if(g_Game_CountDown == racetime) {
					ShowOverlays("r_screenoverlay zx2_car/go");
					StartAllPLayerVehicleEngine();
					CreateTimer(0.5,KillOverlays);
				}
			} else {
				new maxClients = GetMaxClients();
				new total = 0;
				for (new i=1; i<=maxClients; i++)
					if (IsClientConnected(i) && IsClientInGame(i) && g_Player_JoinReadyTime[i] == 0.0 &&  g_Player_RaceTime[i] != 0.0 && GetClientTeam(i) == 3) // player join race
						total++;

				if(g_Game_CountDown <= 0 || total == 0) // all racers finish or no racers or timeout
				{
					if(g_Game_CountDown <= 0 && GetConVarInt(h_rallyrace_racetime) > 0)
					{
						SendSayText2Message(0,0,"\x04[-]\x03 Timeout!");
						KillAllRacePlayer();
					}
					g_Game_Race_Round_Count++;
					new raceround = GetConVarInt(h_rallyrace_raceround);
					if(raceround > 0 && g_Game_Race_Round_Count >= raceround) // played x rounds, time to change map, if use CleanUp() call, no need??
					{
						InitiateMapChooserVote(MapChange_Instant);
						g_RaceTimer = INVALID_HANDLE;
						return Plugin_Stop;
					}
					CleanUpRound();
					g_Game_CountDown = GetConVarInt(h_rallyrace_readytime);
					g_Game_Stats = READY;
				}
			}
		}
	}
	return Plugin_Continue;
}

public CheckEnoughPlayer()
{
	g_Game_Stats = NONE;
	if(g_RaceTimer != INVALID_HANDLE)
	{
		KillTimer(g_RaceTimer);
		g_RaceTimer = INVALID_HANDLE;
	}
	g_RaceTimer = CreateTimer(1.0,RaceTimerFunc,INVALID_HANDLE,TIMER_REPEAT);
}

public OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if(g_Entitys[ENTITYS_ZONE_TYPE][caller] == -1)
		return;
	if(!IsPlayer(activator))
		return;
	if(!IsClientInGame(activator))
		return;

	switch(g_Entitys[ENTITYS_ZONE_TYPE][caller])
	{
		case TT_CHECKPOINT: // touching checkpoint
		{
			if(g_Entitys[ENTITYS_CHECK_POINT_INDEX][caller] ==  -1)
				return;

			new car = RCM_GetPlayerCar(activator);
			if(car == -1) // player not in car, on foot?
				return;

			if((g_Entitys[ENTITYS_CHECK_POINT_INDEX][caller] - g_Player_CheckPoint[activator][CHECKPOINT]) != 1)
				return;
			if(g_Player_CheckPoint[activator][CHECKPOINT] >= g_Max_CheckPoint) { // finish last checkpoint
				PlayerFinishRace(car,activator);
			}else {
				g_Entitys[ENTITYS_CHECK_POINT_PASSED][caller]++;
				g_Player_LastCheckPointTime[activator] = GetGameTime();
				g_Player_CheckPoint[activator][CHECKPOINT]++;
				g_Player_CheckPoint[activator][POSITION] = g_Entitys[ENTITYS_CHECK_POINT_PASSED][caller];
				AddScore(activator,1); // add score to scoreboard
				UpdatAllPLayersPosition(); // update all player place
			}
		}
		case TT_SPECPOINT: // player touching gman
		{
			ChangeClientTeam(activator,1);
		}
		case TT_READYPOINT: // player ready to race
		{
			g_Player_JoinReadyTime[activator] = GetGameTime();
		}
	}
}

public OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if(g_Entitys[ENTITYS_ZONE_TYPE][caller] == -1)
		return;
	if(!IsPlayer(activator))
		return;
	if(!IsClientInGame(activator))
		return;

	if(g_Entitys[ENTITYS_ZONE_TYPE][caller] == _:TT_READYPOINT) // player leave ready zone (may be going to find gman)
	{
		g_Player_JoinReadyTime[activator] = 0.0;
	}
}

public PlayerFinishRace(car,client)
{
	new String:playername[32];
	GetClientName(client, playername, sizeof(playername));
	new Float:finish_time = GetGameTime() - g_Player_RaceTime[client] - 0.005;
	new minutes = RoundToZero(finish_time/60);
	new Float:seconds = finish_time  - (minutes * 60);
	g_Player_Race_Finish++;

	RCM_HandleEntryExitFinish(car, true, false ); // don't remove the car if there are driver, kick the driver first
	CS_SwitchTeam(client,2);
	CS_RespawnPlayer(client);
	AcceptEntityInput(car,"Kill"); // car can remove now
	new index = (g_Player_Race_Finish >= 4) ? 4 : g_Player_Race_Finish;
	if(seconds < 10.0) // time = 3:02
	{
		SendSayText2Message(0,0,"\x04[-]\x03 %d%s: %s\x01 %d:0%.2f",g_Player_Race_Finish,place_name[index],playername,minutes,seconds);
	} else { // time = 3:12
		SendSayText2Message(0,0,"\x04[-]\x03 %d%s: %s\x01 %d:%.2f",g_Player_Race_Finish,place_name[index],playername,minutes,seconds);
	}

	CallOnPlayerFinishRace(client, true, minutes, seconds);
}

public RCM_DriveVehicle(car, client, bool:turnover, iButtons, bool:m_bExitAnimOn, bool:can_boot, m_nSpeed)
{
	g_Player_CanBoost[client] = can_boot;
	if(turnover) // car already turnover 2 seconds (2 seconds is defined in extension)
	{
		if((iButtons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_SPEED|IN_JUMP|IN_ATTACK|IN_ATTACK2)) && !m_bExitAnimOn )
		{
			ForcePlayerSuicide(client); // kill the player if he press the above key
			new Float:finish_time = GetGameTime() - g_Player_RaceTime[client] - 0.005;
			new minutes = RoundToZero(finish_time/60);
			new Float:seconds = finish_time  - (minutes * 60);
			CallOnPlayerFinishRace(client, false, minutes, seconds);
			return;
		}
	}
	SetEntData(client,m_ArmorValue,m_nSpeed,4,true); // use armor value field to display car speed
}

public Action:RCM_IsPassengerVisible(car, nRole, &bool:visible)
{
	visible = false; // make driver visible, if set to false, this forward is useless, default is invisible
	return Plugin_Changed;
}

public Action:RCM_CanExitVehicle(car, player, &bool:canexit)
{
	canexit = false; // don't let player press "E" to exit the car
	return Plugin_Changed;
}

stock ShowPlayerText(client)
{
	if(IsPlayerAlive(client))
	{
		PrintHintText(client,"CheckPoints\n %d/%d\nPosition\n %d/%d\n%s",g_Player_CheckPoint[client][CHECKPOINT],g_Max_CheckPoint+1,g_Player_CheckPoint[client][POSITION],g_Player_Race_Count,(g_Player_CanBoost[client]) ? "BOOST" : "");
	}
}

public Action:PlayerTextDisplayTimer(Handle:timer, any:client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		ShowPlayerText(client);
	}
	return Plugin_Continue;
}

public SortPosition(array1[], array2[], const array[][], Handle:hndl)
{
	if(array1[CHECKPOINT] == array2[CHECKPOINT]) return array1[POSITION] - array2[POSITION];
	return array2[CHECKPOINT] - array1[CHECKPOINT];
}

public UpdatAllPLayersPosition()
{
	new SortArray[MAXPLAYERS+1][3];
	new maxClients = GetMaxClients();
	new total = 0;
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && g_Player_RaceTime[i] != 0.0)
		{
			SortArray[total][CHECKPOINT] = g_Player_CheckPoint[i][CHECKPOINT];
			SortArray[total][POSITION] = g_Player_CheckPoint[i][POSITION];
			SortArray[total][2] = i;
			total++;
		}
	}
	if(total > 0)
	{
		SortCustom2D(SortArray,total,SortPosition);
		for(new i=0;i< total;i++)
		{
			new client = SortArray[i][2];
			g_Player_CheckPoint[client][POSITION] = i+1;
			if(GetClientTeam(client) == 3)
			{
				ShowPlayerText(client);
			}
		}
	}
}

public KillAllRacePlayer()
{
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			ForcePlayerSuicide(i);
		}
	}
}

public StartAllPLayerVehicleEngine()
{
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && g_Player_RaceTime[i] != 0.0 && GetClientTeam(i) == 3)
		{
			new car = RCM_GetPlayerCar(i);
			if(car != -1)
			{
				new String:model[255];
				GetEntPropString(car, Prop_Data, "m_ModelName", model, sizeof(model));
				if (!StrEqual(model, MODEL_BUGGY))
				{
					RCM_HandleEntryExitFinish(car,true,false);
					RCM_SetPlayerToJeep(car,i);
					//ServerCommand("sm_exec @all sm_car_exit");
				}
				RCM_StartCarEngine(car,true);
			}
		}
	}
}

public RemovePlayerCar(client)
{
	if(IsClientInGame(client))
	{
		new car = RCM_GetPlayerCar(client);
		if(car != -1)
		{
			RCM_HandleEntryExitFinish(car,true,false);
			AcceptEntityInput(car,"Kill");
		}
	}
}

public SortJoinReadyTime(array1[], array2[], const array[][], Handle:hndl)
{
	return array2[0] - array1[0];
}

public SpawnCarsToRace(clients[], total)
{
	new size = GetArraySize(g_CarSpawnArray);
	if(size == 0)
		return;

	new SortArray[MAXPLAYERS+1][2];
	for(new i=0;i<total;i++)
	{
		SortArray[i][0] = RoundToNearest(g_Player_JoinReadyTime[clients[i]]); // sourcemod can sort float??
		SortArray[i][1] = clients[i];
	}

	SortCustom2D(SortArray,total,SortJoinReadyTime);
	for(new i=0;i<total;i++)
	{
		new client = SortArray[i][1];
		if(i >= size) // if there are 16 players, but only 6 car spawn points...
		{
			SendSayText2Message(client,0,"\x04[-]\x03 Spawn Car Fail");
		} else {
			new ent = GetArrayCell(g_CarSpawnArray,i);
			new Float:vec[3],Float:ang[3];
			GetEntDataVector(ent,m_vecOrigin,vec);
			GetEntDataVector(ent,m_angRotation,ang);
			new car = CreateJeep();
			if(IsValidEntity(car))
			{
				TeleportEntity(car,vec,ang,NULL_VECTOR);
				CS_SwitchTeam(client,3);
				g_Player_RaceTime[client] = GetGameTime();
				g_Player_Race_Count++;
				RCM_SetPlayerToJeep(car,client); // set player into car
				RCM_StartCarEngine(car, false); // race not start, stop the engine first
			}
		}
	}
}

stock bool:IsPlayer(client)
{
	return (client > 0 && client <= MAXPLAYERS);
}

public ResetCheckPointsPass()
{
	for(new i=0;i<=MAXENTITYS;i++)
	{
		g_Entitys[ENTITYS_CHECK_POINT_PASSED][i] = 0;
	}
}

public InitEntityArray()
{
	for(new j=0;j<ENTITYS_ARRAY_SIZE;j++)
	{
		for(new i=0;i<=MAXENTITYS;i++)
		{
			g_Entitys[j][i] = -1;
		}
	}
}

public LoadPointEntitys()
{
	g_Max_CheckPoint = 0;
	new String:classname[64];
	new String:targetname[64];
	new maxents = GetMaxEntities();
	for(new i=0;i<=maxents;i++)
	{
		if(!IsValidEntity(i))
			continue;

		GetEdictClassname(i,classname,sizeof(classname));
		if(StrEqual(classname,CHECKPOINT_ENTITY))
		{
			GetTargetName(i,targetname,sizeof(targetname));
			if(StrEqual(targetname,READYZONE_NAME,false)) // ready zone
			{
				g_Entitys[ENTITYS_ZONE_TYPE][i] = _:TT_READYPOINT;

				#if DEBUG == 1
				PrintToServer("Found Ready Zone");
				#endif
			} else if(StrEqual(targetname,SPECTATE_ZONE_NAME,false)) { // spectate zone
				g_Entitys[ENTITYS_ZONE_TYPE][i] = _:TT_SPECPOINT;

				#if DEBUG == 1
				PrintToServer("Found Spectate Zone");
				#endif
			} else if(strcmp(targetname,CHECKPOINT_NAME,false) > 1) { // check points
				new index = StringToInt(targetname[12]);
				g_Entitys[ENTITYS_ZONE_TYPE][i] = _:TT_CHECKPOINT;
				g_Entitys[ENTITYS_CHECK_POINT_INDEX][i] = index;
				g_Entitys[ENTITYS_CHECK_POINT_PASSED][i] = 0;
				g_Max_CheckPoint++;
				#if DEBUG == 1
				PrintToServer("Found CheckPoint: %d",index);
				#endif
			}
		} else if(StrEqual(classname,CAR_SPAWN_ENTITY)) {
			GetTargetName(i,targetname,sizeof(targetname));
			if(StrEqual(targetname,CAR_SPAWN_NAME,false)) // car spawn points
			{
				PushArrayCell(g_CarSpawnArray,i);
				#if DEBUG == 1
				new Float:vec[3],Float:ang[3];
				GetEntDataVector(i,m_vecOrigin,vec);
				GetEntDataVector(i,m_angRotation,ang);
				PrintToServer("Found Car Spawn Point: %.1f %.1f %.1f (%.1f %.1f %.1f)",vec[0],vec[1],vec[2],ang[0],ang[1],ang[2]);
				#endif
			}
		}
	}
	g_Max_CheckPoint--;
}

stock GetTargetName(entity, String:buf[], len)
{
	GetEntPropString(entity, Prop_Data, "m_iName", buf, len);
}

stock SendSayText2Message(target, color, const String:szMsg[], any:...)
{
	if (strlen(szMsg) > 191)
		return;

	decl String:buffer[192];
	VFormat(buffer, 192, szMsg, 4);
	decl Handle:hBf;
	if (!target)
	{
		hBf = StartMessageAll("SayText2");
	} else {
		hBf = StartMessageOne("SayText2", target);
	}
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, color); // Players index, to send a global message from the server make it 0
		BfWriteByte(hBf, 0); // 0 to phrase for colour 1 to ignore it
		BfWriteString(hBf, buffer); // the message itself
		CloseHandle(hBf);
		EndMessage();
	}
}

stock ShowOverlays(const String:overlay[])
{
	SetConVarBool(FindConVar("sv_cheats"),true,false);
	decl maxplayers,i;
	maxplayers = GetMaxClients();
	for(i=1;i<=maxplayers;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			ClientCommand(i,overlay);
		}
	}
	SetConVarBool(FindConVar("sv_cheats"),false,false);
}

public Action:KillOverlays(Handle:timer)
{
	SetConVarBool(FindConVar("sv_cheats"),true,false);
	decl maxplayers,i;
	maxplayers = GetMaxClients();
	for(i=1;i<=maxplayers;i++)
		if(IsClientInGame(i))
			ClientCommand(i,"r_screenoverlay \"\"");
	SetConVarBool(FindConVar("sv_cheats"),false,false);
	return Plugin_Stop;
}

public Action:_RespawnClient(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) >= 2 && !IsPlayerAlive(client))
	{
		CS_RespawnPlayer(client);
	}
	return Plugin_Stop;
}

public RespawnClient(Float:seconds, client)
{
	CreateTimer(seconds,_RespawnClient,client,TIMER_FLAG_NO_MAPCHANGE);
}

public CreateJeep()
{
	new c_mdl = GetConVarInt(h_rallyrace_car);
	new ent  = CreateEntityByName("prop_vehicle_driveable");
	if(IsValidEntity(ent))
	{
		if (c_mdl == 0)
		{
			new index= GetRandomCar();
			new String:skin[3];
			IntToString(GetRandomInt(g_Car_skin_min[index], g_Car_skin_max[index]), skin,sizeof(skin));
			DispatchKeyValue(ent, "vehiclescript", g_Car_script[index]);
			DispatchKeyValue(ent, "model", g_Car_model[index]);
			DispatchKeyValue(ent, "solid","6");
			DispatchKeyValue(ent, "skin",skin);
			DispatchKeyValue(ent, "actionScale","1");
			DispatchKeyValue(ent, "EnableGun","0");
			DispatchKeyValue(ent, "ignorenormals","0");
			DispatchKeyValue(ent, "fadescale","1");
			DispatchKeyValue(ent, "fademindist","-1");
			DispatchKeyValue(ent, "VehicleLocked","0");
			DispatchKeyValue(ent, "screenspacefade","0");
			DispatchKeyValue(ent, "spawnflags", "256" );
			DispatchSpawn(ent);
			RCM_InitJeep(ent);
		}
		if (c_mdl > 0)
		{
			new String:skin[3];
			IntToString(GetRandomInt(g_Car_skin_min[c_mdl], g_Car_skin_max[c_mdl]), skin,sizeof(skin));
			DispatchKeyValue(ent, "vehiclescript", g_Car_script[c_mdl]);
			DispatchKeyValue(ent, "model", g_Car_model[c_mdl]);
			DispatchKeyValue(ent, "solid","6");
			DispatchKeyValue(ent, "skin",skin);
			DispatchKeyValue(ent, "actionScale","1");
			DispatchKeyValue(ent, "EnableGun","0");
			DispatchKeyValue(ent, "ignorenormals","0");
			DispatchKeyValue(ent, "fadescale","1");
			DispatchKeyValue(ent, "fademindist","-1");
			DispatchKeyValue(ent, "VehicleLocked","0");
			DispatchKeyValue(ent, "screenspacefade","0");
			DispatchKeyValue(ent, "spawnflags", "256" );
			DispatchSpawn(ent);
			RCM_InitJeep(ent);
		}
	}
	return ent;
}
stock GetRandomCar()
{
	return GetRandomInt(1,g_Total_Car-1);
}
public bool:ReadCarConfig()
{
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/rallyrace/carconfig.txt");
	if(!FileExists(sPath))
		return false;

	new String:buffer[65];
	new Handle:kv = CreateKeyValues("RallyRaceCar");
	FileToKeyValues(kv, sPath);

	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv,"model",g_Car_model[g_Total_Car],sizeof(g_Car_model[]));
			KvGetString(kv,"script",g_Car_script[g_Total_Car],sizeof(g_Car_script[]));
			KvGetString(kv,"skin_min",buffer,sizeof(buffer),"0");
			g_Car_skin_min[g_Total_Car] = StringToInt(buffer);
			KvGetString(kv,"skin_max",buffer,sizeof(buffer),"0");
			g_Car_skin_max[g_Total_Car] = StringToInt(buffer);
			PrecacheModel(g_Car_model[g_Total_Car],true);
			g_Total_Car++;
			if(g_Total_Car >= MAX_CAR)
			{
				PrintToServer("[*] Too Many Cars, Max: %d",MAX_CAR);
				break;
			}
		} while(KvGotoNextKey(kv));
	}

	CloseHandle(kv);

	#if DEBUG == 1
	PrintToServer("Found %d Cars",g_Total_Car);
	#endif
	if(g_Total_Car == 0)
		return false;

	return true;
}

public ReadDownloadFile()
{
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/rallyrace/download.txt");

	new Handle:file = OpenFile(sPath, "rb");
	if(file == INVALID_HANDLE)
		return;

	new String:readData[256];
	new length;
	while(!IsEndOfFile(file) && ReadFileLine(file, readData, sizeof(readData)))
	{
		TrimString(readData);
		if(!FileExists(readData))
			continue;

		length = strlen(readData);
		if(length >= 4)
		{
			if(StrEqual(readData[length-4],".mdl") && !IsModelPrecached(readData))
			{
				PrecacheModel(readData,true);
			}
		}
		AddFileToDownloadsTable(readData);
	}

	CloseHandle(file);
}


stock KillPlayerTimer(client)
{
	if(g_PlayerTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_PlayerTimer[client]);
		g_PlayerTimer[client] = INVALID_HANDLE;
	}
}

stock Disintegrate(client)
{
	new ragdoll = GetEntDataEnt2(client,m_hRagdoll);
	if(ragdoll != -1)
	{
		RemoveEdict(ragdoll);
	}
}

stock RemoveIdleWeapon()
{
	new maxents = GetMaxEntities();
	for(new i=0;i<=maxents;i++)
	{
		new String:Class[65];
		if(IsValidEdict(i) && IsValidEntity(i) && IsEntNetworkable(i))
		{
			GetEdictClassname(i, Class, sizeof(Class));
			if(StrContains(Class,"weapon_") != -1 || StrContains(Class,"defuser") != -1)
			{
				decl owner;
				owner = GetEntData(i,m_hOwnerEntity);
				if (owner == -1)
				{
					RemoveEdict(i);
				}
			}
		}
	}
}

stock CallOnPlayerFinishRace(client, bool:isfinish, minutes, Float:seconds)
{
	Call_StartForward(F_OnPlayerFinishRace);
	Call_PushCell(client);
	Call_PushCell(isfinish);
	Call_PushCell(minutes);
	Call_PushFloat(seconds);
	Call_Finish();
}

stock AddScore(client,value)
{
	SDKCall(hIncrementFragCount,client,value);
}
stock AddDeath(client,value)
{
	SDKCall(hIncrementDeathCount,client,value);
}
stock ResetScore(client)
{
	SDKCall(hResetFragCount,client);
}
stock ResetDeath(client)
{
	SDKCall(hResetDeathCount,client);
}
stock SetScore(client, value)
{
	ResetScore(client);
	AddScore(client,value);
}
stock SetDeath(client, value)
{
	ResetDeath(client);
	AddDeath(client,value);
}
stock CleanUpRound()
{
	SDKCall(hCleanUp);
}
public Action:Car_Exit(client, args)
{
	new car = RCM_GetPlayerCar(client);
	if(car != -1)
	{
		RCM_HandleEntryExitFinish(car,true,false);
	}
	return Plugin_Handled;
}
