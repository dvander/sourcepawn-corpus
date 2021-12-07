
#pragma semicolon 1
#include <sourcemod>
#include <mapchooser>
#include <sdktools>
#include <cstrike>
#include <rallymod>

#define  RALLYRACE_VERSION			"1.0.0.4t"

public Plugin:myinfo = 
{
	name = "CSS Rally Race",
	author = "ben, TigerOx",
	description = "CSS Rally Race",
	version = RALLYRACE_VERSION,
	url = "http://www.ZombieX2.net/"
};

//////////////////////////////////////////////
//					CONFIG					//
//////////////////////////////////////////////
#define 	DEBUG			1					//print debug message for getting entitys

new String:place_name[][3] = {"","st","nd","rd","th"};

//////////////////////////////////////////////
//				END CONFIG					//
//////////////////////////////////////////////

#define		MAXENTITYS						2048
		
#define		ENTITYS_ARRAY_SIZE				3
#define		ENTITYS_ZONE_TYPE				0
#define		ENTITYS_CHECK_POINT_INDEX		1
#define		ENTITYS_CHECK_POINT_PASSED		2
	
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

//TigerOx
//Added !times command - stores fastes map time and keeps race times on maps.
//Added Timeout x number of seconds after first player finishes.
//  	- ConVar rallyrace_timetofinish to control timeout seconds.
//Added auto times popup on race finish
//Changed to use native MaxClients
//Fixed 'Native "RCM_GetPlayerCar" reported: Index 3 is not valid' error

//Changes marked with TigerOx - This is prototype code.
#define		MAX_TIME		100000.0
#define		MENU_TIME		20
#define		MAX_RACE_TIMES	6
#define		TEAM_CT			3

/* Contains the race time data */
new String:TimeFile[PLATFORM_MAX_PATH];
new Handle:KvTime = INVALID_HANDLE;
new bool:TimeOpen;

//Finish timeout var
new g_Finish_CountDown;
new Handle:h_rallyrace_timetofinish;

//Top map time vars
new Float:g_TopTime;
new String:g_TopPlayerAuthid[64]; 
new String:g_TopPlayerName[64];
new String:g_CurrentMapName[64];

//Times menu
new Handle:TopTimePanel[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new Float:g_Player_Times[MAXPLAYERS+1][MAX_RACE_TIMES];



//****


enum TriggerType {
	TT_CHECKPOINT,
	TT_READYPOINT,
	TT_SPECPOINT
};
	
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

new Handle:hIncrementFragCount;
new Handle:hResetFragCount;
new Handle:hIncrementDeathCount;
new Handle:hResetDeathCount;
new Handle:hGameConf;
new Handle:hCleanUp;

new Handle:h_rallyrace_readytime;
new Handle:h_rallyrace_racetime;
new Handle:h_rallyrace_raceround;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	m_vecOrigin = FindSendPropInfo("CBaseEntity", "m_vecOrigin");
	m_angRotation = FindSendPropInfo("CBaseEntity", "m_angRotation");
	m_ArmorValue = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	m_hRagdoll = FindSendPropInfo("CCSPlayer", "m_hRagdoll");
	m_hOwnerEntity = FindSendPropOffs("CBaseEntity","m_hOwnerEntity");
	
	CreateConVar("rallyrace_version",RALLYRACE_VERSION,"Rally Race Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	h_rallyrace_readytime = CreateConVar("rallyrace_readytime","30","Ready Time",0,true,5.0,true,120.0);
	h_rallyrace_racetime= CreateConVar("rallyrace_racetime","320","Racers will force suicide to end current race round after this value (0 = disable)",0,true,0.0);
	h_rallyrace_raceround = CreateConVar("rallyrace_raceround","4","How many race round start a map vote? (0 = disable)",0,true,0.0);
	//TigerOx
	h_rallyrace_timetofinish= CreateConVar("rallyrace_timetofinish","35","Race will end this many seconds after the first player finishes (0 = disable)",0,true,0.0);
	
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
	
	//TigerOx - Create top map times
	RegConsoleCmd("times", TimeCommand);
	
	OnCreateKeyValues();
	
	AutoExecConfig(true, "rallyrace");
}

public OnPluginEnd()
{
	UnhookEntityOutput("trigger_multiple","OnStartTouch",OnStartTouch);
	UnhookEntityOutput("trigger_multiple","OnEndTouch",OnEndTouch);
	
	RCM_BlockRoundEnd(false);
	ClearArray(g_CarSpawnArray);
}

public OnClientPutInServer(client)
{
	//TigerOx
	//Clear their last times
	for(new i = 0; i<MAX_RACE_TIMES; i++)
		g_Player_Times[client][i] = 0.0;
	//
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
	//TigerOx
	if(TopTimePanel[client] != INVALID_HANDLE)
	{
		CloseHandle(TopTimePanel[client]);
		TopTimePanel[client] = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	g_Game_Race_Round_Count = 0;
	PrecacheModel("models/buggy.mdl",true);
	
	AddFileToDownloadsTable("materials/zx2_car/1.vmt");
	AddFileToDownloadsTable("materials/zx2_car/1.vtf");
	AddFileToDownloadsTable("materials/zx2_car/2.vmt");
	AddFileToDownloadsTable("materials/zx2_car/2.vtf");
	AddFileToDownloadsTable("materials/zx2_car/3.vmt");
	AddFileToDownloadsTable("materials/zx2_car/3.vtf");
	AddFileToDownloadsTable("materials/zx2_car/go.vmt");
	AddFileToDownloadsTable("materials/zx2_car/go.vtf");
	
	ClearArray(g_CarSpawnArray);
	InitEntityArray();
	LoadPointEntitys();
	CheckEnoughPlayer();
	
	//TigerOx
	GetCurrentMap(g_CurrentMapName, sizeof(g_CurrentMapName));
	if(!LoadTopTime())
		g_TopTime = MAX_TIME;
	
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
			//TigerOx
			g_Finish_CountDown = 0;
			//
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
				//tigerox
				if(g_Game_CountDown <= 0 || total == 0 || (g_Finish_CountDown - g_Game_CountDown) >= GetConVarInt(h_rallyrace_timetofinish)) // all racers finish or no racers or timeout
				{	//tigerox
					if((g_Game_CountDown <= 0 && GetConVarInt(h_rallyrace_racetime) > 0) || (g_Finish_CountDown - g_Game_CountDown) >= GetConVarInt(h_rallyrace_timetofinish))
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
	//TigerOx
	//Add race time to last times list
	for(new i = 0; i < MAX_RACE_TIMES; i++)
	{
		if(g_Player_Times[client][i] == 0.0)
		{
			g_Player_Times[client][i] = finish_time;
			break;
		}
	}
	//Check for first to finsih
	if(g_Finish_CountDown == 0) //Do not display winner or start time limit with only 1 racer
	{
		PrintCenterTextAll("%s won the race!", playername);
		if(GetTeamClientCount(TEAM_CT) > 0)
		{
			new timeleft = GetConVarInt(h_rallyrace_timetofinish);
			g_Finish_CountDown = g_Game_CountDown;
			for (new i=1; i<=MaxClients; i++)
				if (IsClientConnected(i) && IsClientInGame(i) && g_Player_JoinReadyTime[i] == 0.0 &&  g_Player_RaceTime[i] != 0.0 && GetClientTeam(i) == 3)
					PrintToChat(i,"%d seconds left in the race!", timeleft);
		}
		
		//Add to top time list
		if(finish_time < g_TopTime)
		{
			PrintToChatAll("%s - set a new fastest time!", playername);
			g_TopTime = finish_time;
			GetClientName(client, g_TopPlayerName, sizeof(g_TopPlayerName));
			GetClientAuthString(client,g_TopPlayerAuthid, sizeof(g_TopPlayerAuthid));
			AddTopTime();
		}
	}
	//Show times panel to client
	CreateTimer(1.0, AutoPopup, client);
}

public RCM_DriveVehicle(car, client, bool:turnover, iButtons, bool:m_bExitAnimOn, bool:can_boot, m_nSpeed)
{
	g_Player_CanBoost[client] = can_boot;
	if(turnover) // car already turnover 2 seconds (2 seconds is defined in extension)
	{
		if((iButtons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_SPEED|IN_JUMP|IN_ATTACK|IN_ATTACK2)) && !m_bExitAnimOn )
		{
			ForcePlayerSuicide(client); // kill the player if he press the above key
			return;
		}
	}
	SetEntData(client,m_ArmorValue,m_nSpeed,4,true); // use armor value field to display car speed
}

public Action:RCM_IsPassengerVisible(car, nRole, &bool:visible)
{
	visible = true; // make driver visible
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
	new total = 0;
	for (new i=1; i<=MaxClients; i++)
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
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			ForcePlayerSuicide(i);
		}
	}
}

public StartAllPLayerVehicleEngine()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && g_Player_RaceTime[i] != 0.0 && GetClientTeam(i) == 3)
		{
			new car = RCM_GetPlayerCar(i);
			if(car != -1)
			{
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
				PrintToServer("Find Ready Zone");
				#endif
			} else if(StrEqual(targetname,SPECTATE_ZONE_NAME,false)) { // spectate zone
				g_Entitys[ENTITYS_ZONE_TYPE][i] = _:TT_SPECPOINT;
				
				#if DEBUG == 1
				PrintToServer("Find Spectate Zone");
				#endif
			} else if(strcmp(targetname,CHECKPOINT_NAME,false) > 1) { // check points
				new index = StringToInt(targetname[12]);
				g_Entitys[ENTITYS_ZONE_TYPE][i] = _:TT_CHECKPOINT;
				g_Entitys[ENTITYS_CHECK_POINT_INDEX][i] = index;
				g_Entitys[ENTITYS_CHECK_POINT_PASSED][i] = 0;
				g_Max_CheckPoint++;
				#if DEBUG == 1
				PrintToServer("Find CheckPoint: %d",index);
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
				PrintToServer("Find Car Spawn Point: %.1f %.1f %.1f (%.1f %.1f %.1f)",vec[0],vec[1],vec[2],ang[0],ang[1],ang[2]);
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
	for(new i=1;i<=MaxClients;i++)
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
	for(new i=1;i<=MaxClients;i++)
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
	new ent  = CreateEntityByName("prop_vehicle_driveable");
	if(IsValidEntity(ent))
	{
		DispatchKeyValue(ent, "vehiclescript", "scripts/vehicles/ep1.txt");
		DispatchKeyValue(ent, "model", "models/buggy.mdl");
		DispatchKeyValue(ent, "solid","6");
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
	return ent;
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


//TigerOx*********************************************************

//Update Player name if top time
public OnClientAuthorized(client)
{
	decl String:Name[64], String:Auth[64], String:buffer[64];
	new bool:changed = false;
	
	if(TimeOpen)
	{
		GetClientAuthString(client, Auth, sizeof(Auth));
		GetClientName(client,Name,sizeof(Name));
		
		KvRewind(KvTime);
		
		if(!KvGotoFirstSubKey(KvTime))
			return;
		
		while(TimeOpen)
		{	
			KvGetString(KvTime, "authid", buffer, sizeof(buffer));
			if(StrEqual(buffer, Auth))
			{
				KvGetString(KvTime, "name", buffer, sizeof(buffer));
				if(!StrEqual(buffer, Name))
				{	
					KvSetString(KvTime, "name", Name);
					changed = true;
				}
			}
			
			if(!KvGotoNextKey(KvTime))
				break;
		}
		KvRewind(KvTime);
		
		if(changed)
		{
			KeyValuesToFile(KvTime, TimeFile);
			//Rebuild top time list
			LoadTopTime();
		}
	}
}

//Show top time menu to client
public Action:TimeCommand(client, args)
{
	ShowClientTimes(client);
	return Plugin_Handled;
}

public Action:AutoPopup(Handle:timer, any:client)
{
	ShowClientTimes(client);
	return Plugin_Stop;
}

//Send times panel to client
ShowClientTimes(client)
{
	if(TopTimePanel[client] != INVALID_HANDLE)
		CloseHandle(TopTimePanel[client]);
	
	TopTimePanel[client] = CreateTopTimePanel(client);
	
	if(TopTimePanel[client] != INVALID_HANDLE)
		SendPanelToClient(TopTimePanel[client], client, EmptyHandler, MENU_TIME);
}

//Race Time Menu
Handle:CreateTopTimePanel(client)
{
	decl String:Key[74];
	new Handle:TopTime = CreatePanel();

	FormatEx(Key, sizeof(Key), "%s", g_CurrentMapName);
	SetPanelTitle(TopTime, "Race times -");
	DrawPanelText(TopTime, Key);
	DrawPanelText(TopTime, " ");
	if(g_TopTime == MAX_TIME)
	{
		DrawPanelText(TopTime, "No time for this map yet!");
	} 
	else 
	{
		DrawPanelText(TopTime, "Fastest:");
		new minutes = RoundToZero(g_TopTime/60);
		new Float:seconds = g_TopTime - (minutes * 60);
		if(seconds < 10)
			FormatEx(Key, sizeof(Key), "%s - %d:0%.2f", g_TopPlayerName, minutes, seconds);
		else
			FormatEx(Key, sizeof(Key), "%s - %d:%.2f", g_TopPlayerName, minutes, seconds);
		DrawPanelText(TopTime, Key);
	}
	DrawPanelText(TopTime, " ");
	
	//Add recent times
	new Float:timex = g_Player_Times[client][0];
	DrawPanelText(TopTime, "Last race times:");
	if(timex == 0.0)
		DrawPanelText(TopTime,"Finish the race to record a time.");
	
	for(new i = 0; i<MAX_RACE_TIMES; i++)
	{
		timex = g_Player_Times[client][i];
		if(timex != 0.0)
		{
			new minutes = RoundToZero(timex/60);
			new Float:seconds = timex - (minutes * 60);
			if(seconds < 10)
				FormatEx(Key, sizeof(Key), "%d. %d:0%.2f", i+1, minutes, seconds);
			else
				FormatEx(Key, sizeof(Key), "%d. %d:%.2f", i+1, minutes, seconds);
			DrawPanelText(TopTime, Key);
		}
	}
	DrawPanelText(TopTime, " ");
	DrawPanelItem(TopTime, "Exit", ITEMDRAW_CONTROL);
	return TopTime;
}

public EmptyHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* Don't care what they pressed. */
}

//***Map race time keyvalues!***//
OnCreateKeyValues()
{
	KvTime = CreateKeyValues("race_top", _, _);
	BuildPath(Path_SM, TimeFile, sizeof(TimeFile), "data/rallyracetop.txt");
	TimeOpen = FileToKeyValues(KvTime, TimeFile);
}

bool:LoadTopTime()
{
	new bool:gotTime = false;
	
	/* Load top race time data, if file is found */
	if(TimeOpen)
	{
		KvRewind(KvTime);

		// Go to first SubKey
		if(!KvGotoFirstSubKey(KvTime))
			return false;

		new String:MapName[64];

		while(TimeOpen)
		{
			if(!KvGetSectionName(KvTime, MapName, sizeof(MapName)))
			{
				break;
			}
			
			if(StrEqual(MapName, g_CurrentMapName))
			{
				//Get top map time player info
				KvGetString(KvTime, "authid", g_TopPlayerAuthid, sizeof(g_TopPlayerAuthid));
				KvGetString(KvTime, "name", g_TopPlayerName, sizeof(g_TopPlayerName));
				g_TopTime = KvGetFloat(KvTime, "time");
				gotTime = true;
				break;
			}

			if(!KvGotoNextKey(KvTime))
			{
				break;
			}
		}

		KvRewind(KvTime);
	}
	return gotTime;
}

AddTopTime()
{
	/* Set at top of file */
	KvRewind(KvTime);
	
	if(KvJumpToKey(KvTime, g_CurrentMapName, true))
	{
		KvSetString(KvTime, "authid", g_TopPlayerAuthid);
		KvSetString(KvTime, "name", g_TopPlayerName);
		KvSetFloat(KvTime, "time", g_TopTime);
	}
	/* Need to be at the top of the file to before writing */
	KvRewind(KvTime);
	KeyValuesToFile(KvTime, TimeFile);
}