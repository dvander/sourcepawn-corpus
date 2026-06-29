#include <sourcemod>
#include <sdktools>
#define Version "1.0.7"
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

public Plugin:myinfo=
{
	name = "RPG 모드 - Infected, RPG Mode - For Infected",
	author = "Rayne", //추가 NoBLess
	description = "RPG 모드 - Infected",
	version = Version,
	url = ""
};

//Boomer
new Handle:BEDmg
new Handle:BERad
new bool:BECount[MAXPLAYERS+1]
new Handle:BEDelay
new InfDef[MAXPLAYERS+1]

//Hunter
new bool:HECount[MAXPLAYERS+1]
new Handle:HEDelay

//Tank
new bool:TECount[MAXPLAYERS+1]
new Handle:TEDelay
new Float:MoveSpeed

//차져 Extreme Force 기술
new Handle:CEDelay
new bool:CECount[MAXPLAYERS+1]

//조키
new Handle:JocDelay
new bool:JocCount[MAXPLAYERS+1]

//좀비 클래스
new ZC2

//현재 위치
new Float:NowLoc[MAXPLAYERS+1][3]

public OnPluginStart()
{
	CreateConVar("l4d2_RPG_Mode_Infected_Version", Version, "RPG 모드 버전 - Infected", CVAR_FLAGS)
	
	ZC2 = FindSendPropInfo("CTerrorPlayer", "m_zombieClass")
	
	//부머 Explo~
	BEDmg = CreateConVar("sm_BEDmg","500.0","부머 폭발 데미지. 소수로 적어주세요. 500.0은 데미지 500.0", FCVAR_PLUGIN)
	BERad = CreateConVar("sm_BERad","300.0","부머 폭발 범위. 소수로 적어주세요. 300.0은 범위 300.0", FCVAR_PLUGIN)
	BEDelay = CreateConVar("sm_BETimer","20.0","부머 폭발 딜레이. 소수로 적어주세요. 20.0은 20.0초", FCVAR_PLUGIN)
	
	//헌터 Cryi~~
	HEDelay = CreateConVar("sm_HETimer","30.0","헌터 울부짖기 딜레이. 소수로 적어주세요. 30.0은 30.0초", FCVAR_PLUGIN)
	
	//탱크 Massi~~
	TEDelay = CreateConVar("sm_TETimer","120.0","탱크 극도의 흥분 딜레이. 소수로 적어주세요. 120.0은 120.0초", FCVAR_PLUGIN)
	
	//차져 Trans~~
	CEDelay = CreateConVar("sm_CETimer","10.0","차져 극도의 근력 딜레이. 소수로 적어주세요. 10.0은 10.0초", FCVAR_PLUGIN)
	
	//조키
	JocDelay = CreateConVar("sm_JocTimer","300.0","조키 예상치 못한 체력!! 딜레이. 소수로 적어주세요. 300.0은 300.0초", FCVAR_PLUGIN)
	
	//이벤트
	HookEvent("player_spawn", PlayerSp)
	HookEvent("jockey_ride_end", EvJocRideEnd)
	HookEvent("jockey_ride", EvJocRide)
	
	//CFG파일 생성
	AutoExecConfig(true, "l4d2_RollPlayingGameMode_Infected")
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_ZOOM && GetClientTeam(client) == TEAM_INFECTED && IsPlayerAlive(client) && IsPlayerGhost(client) == false)
	{
		new ZClass = GetEntData(client, ZC2)
		if(ZClass == 2 && BECount[client] == true && InfDef[client] == 2)
		{
			GetClientAbsOrigin(client, NowLoc[client])
			Create_PointHurt(NowLoc[client], GetConVarFloat(BEDmg), GetConVarFloat(BERad), 64)
			CreateTimer(GetConVarFloat(BEDelay), BETFC, client)
			PrintToChat(client, "\x04Explosion \x03을 사용하셨습니다.")
			BECount[client] = false
			PrintToChat(client, "\x04Explosion \x03딜레이가 시작됩니다. \x05%d \x03초", RoundToNearest(GetConVarFloat(BEDelay)))
		}
		
		if(ZClass == 3 && HECount[client] == true && InfDef[client] == 3)
		{
			CheatCommand(client, "z_spawn", "mob")
			CheatCommand(client, "director_force_panic_event")
			HECount[client] = false
			CreateTimer(GetConVarFloat(HEDelay), HETFC, client)
			PrintToChat(client, "\x04Crying Wolf \x03딜레이가 시작됩니다. \x05%d \x03초", RoundToNearest(GetConVarFloat(HEDelay)))
		}
		
		if(IsPlayerTank(client) && TECount[client] == true && InfDef[client] == 10)
		{
			MoveSpeed = GetEntDataFloat(client, FindSendPropOffs("CTerrorPlayer","m_flLaggedMovementValue"))
			new TankHealth = GetClientHealth(client)
			SetEntDataFloat(client, FindSendPropOffs("CTerrorPlayer","m_flLaggedMovementValue"), MoveSpeed*2, true)
			SetEntData(client, FindDataMapOffs(client, "m_iHealth"), 2*TankHealth, 4, true)
			CreateTimer(GetConVarFloat(TEDelay), TETFC, client)
			TECount[client] = false
			CreateTimer(GetConVarFloat(TEDelay)*0.5, TMETimer, client)
			PrintToChat(client, "\x04Massive Excitation \x03딜레이가 시작됩니다. \x05%d \x03초", RoundToNearest(GetConVarFloat(TEDelay)))
		}
		
		if(ZClass == 6 && CECount[client] == true && InfDef[client] == 6)
		{
			CECount[client] = false
			CreateTimer(GetConVarFloat(CEDelay), CETFC, client)
			ChargerTeleport(client)
			PrintToChat(client, "\x04Extreme Force \x03딜레이가 시작됩니다. \x05%d \x03초", RoundToNearest(GetConVarFloat(CEDelay)))
		}
		
		if(ZClass == 5 && JocCount[client] == true && InfDef[client] == 5)
		{
			new JHealth = GetClientHealth(client)
			SetEntData(client, FindDataMapOffs(client, "m_iHealth"), 5*JHealth, 4, true)
			JocCount[client] = false
			CreateTimer(GetConVarFloat(JocDelay), JETFC, client)
			PrintToChat(client, "\x04Unexpected Health!! \x03딜레이가 시작됩니다. \x05%d \x03초", RoundToNearest(GetConVarFloat(JocDelay)))
		}	
	}
}

bool:IsPlayerGhost(client)
{
	//플레이어가 고스트 상태인가?
	if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1))
		return true;
	else
	return false;
}

public Action:ChangeMovType(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_WALK)
	PrintToChat(client, "\x03발이 풀립니다.")
}

public Action:JETFC(Handle:timer, any:client)
{
	JocCount[client] = true
	PrintToChat(client, "\x04Unexpected Health!! \x03딜레이가 끝났습니다.")
}

public Action:CETFC(Handle:timer, any:client)
{
	CECount[client] = true
	PrintToChat(client, "\x04Extreme Force 딜레이가 끝났습니다.")
}

public Action:BETFC(Handle:timer, any:client)
{
	BECount[client] = true
	PrintToChat(client, "\x04Explosion \x03딜레이가 끝났습니다.")
}

public Action:HETFC(Handle:timer, any:client)
{
	HECount[client] = true
	PrintToChat(client, "\x04Crying Wolf \x03딜레이가 끝났습니다.")
}

public Action:TMETimer(Handle:timer, any:client)
{
	SetEntDataFloat(client, FindSendPropOffs("CTerrorPlayer","m_flLaggedMovementValue"), MoveSpeed, true)
	PrintToChat(client, "\x03흥분이 가라 앉습니다.")
}

public Action:TETFC(Handle:timer, any:client)
{
		TECount[client] = true
		PrintToChat(client, "\x04Massive Excitation \x03딜레이가 끝났습니다.")
}

//데미지데미지
public bool:Create_PointHurt(Float:Position[3], Float:Damage, Float:Radius, Type)
{
	new Entity;
	new String:sDamage[128];
	new String:sRadius[128];
	new String:sType[128];
	
	FloatToString(Damage, sDamage, sizeof(sDamage));
	FloatToString(Radius, sRadius, sizeof(sRadius));
	IntToString(Type, sType, sizeof(sType));
	
	Entity = CreateEntityByName("point_hurt");
	
	if (!IsValidEdict(Entity)) return false;

	DispatchKeyValue(Entity, "targetname", "Point_Hurt");	
	DispatchKeyValue(Entity, "DamageRadius", sRadius);
	DispatchKeyValue(Entity, "Damage", sDamage);
	DispatchKeyValue(Entity, "DamageType", sType);
	
	TeleportEntity(Entity, Position, NULL_VECTOR, NULL_VECTOR);	
	DispatchSpawn(Entity);

	ActivateEntity(Entity);
	AcceptEntityInput(Entity, "Hurt");

	CreateTimer(0.1, DeleteEntity, Entity);
	
	return true;
}

public Action:DeleteEntity(Handle:Timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		RemoveEdict(entity);
	}
}

//차져 순간이동
ChargerTeleport(client)
{
	new Float:NowLocation3[3]
	new Float:ToLocation[3]
	SetEntityMoveType(client, MOVETYPE_WALK)
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", NowLocation3)
	ToLocation[0] = (NowLocation3[0])
	ToLocation[1] = NowLocation3[1]
	ToLocation[2] = (NowLocation3[2] + 1500)
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, ToLocation)
	CreateTimer(1.7, ReleaseTimer, client)
}

public Action:ReleaseTimer(Handle:timer, any:client)
{
	GetClientAbsOrigin(client, NowLoc[client])
	Create_PointHurt(NowLoc[client], 9999999.0, 100.0, 64)
	ForcePlayerSuicide(client)
	PrintToChat(client, "\x03힘이 없어서 \x04죽습니다..")
}

public Action:PlayerSp(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(target) == TEAM_INFECTED && !IsFakeClient(target))
	{
		new ZClass = GetEntData(target, ZC2)
		if(ZClass == 2)
		{
			BECount[target] = true
			InfDef[target] = 2
			PrintToChat(target, "\x03부머는 \x04Explosion(자폭) \x03을 쓸 수 있습니다. 생존자들의 근처에서 \x05 Zoom \x03를 누르세요.")
		}
		
		if(ZClass == 3)
		{
			HECount[target] = true
			InfDef[target] = 3
			PrintToChat(target, "\x03헌터는 \x04Crying Wolf(울부짖기) \x03를 쓸 수 있습니다. \x05 Zoom \x03를 \x04누르면 좀비 떼가 나옵니다.")
		}
		
		if(IsPlayerTank(target))
		{
			TECount[target] = true
			InfDef[target] = 10
			PrintToChat(target, "\x03탱크는 \x04Massive Excitation(극도의 흥분) \x03을 쓸 수 있습니다. \x05 Zoom \x03를 누르면 속도가 2배가 됩니다.")
			MoveSpeed = GetEntDataFloat(target, FindSendPropOffs("CTerrorPlayer","m_flLaggedMovementValue"))
		}
		
		if(ZClass == 6)
		{
			CECount[target] = true
			InfDef[target] = 6
			PrintToChat(target, "\x03차져는 \x04Extreme Force(극도의 근력) \x03을 쓸 수 있습니다. 생존자를 붙잡고 \x05 Zoom \x03를 누르면 \x04높은 점프 \x03를 합니다.")
		}
		
		if(ZClass == 5)
		{
			JocCount[target] = true
			InfDef[target] = 5
			PrintToChat(target, "\x03죠키는 \x04Unexpected Health!!(예상치 못한 체력) \x03을 쓸 수 있습니다. \x05 Zoom \x03를 누르면 체력이 \x04 5배 \x03가 됩니다.")
		}
	}
}

bool:IsPlayerTank(client)
{
	//플레이어가 탱크인가?
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	else
	return false;
}

//치트 커맨드
CheatCommand(client, const String:command[], const String:arguments[]="", const String:arguments2[]="")
{
	if (!client) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, arguments, arguments2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}

public EvJocRide(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new Rider = GetClientOfUserId(GetEventInt(event, "useid"))
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"))
	if(!IsFakeClient(Rider))
	{
		ChangeLagValue(Victim, Rider, 2.0, 1)
	}
}

public EvJocRideEnd(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new Rider = GetClientOfUserId(GetEventInt(event, "useid"))
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"))
	if(!IsFakeClient(Rider))
	{
		ChangeLagValue(Victim, Rider, 1.0, 0)
	}
}

ChangeLagValue(A, B, Float:C, D)
{
	if(D == 1)
	{
		SetEntDataFloat(A, FindSendPropOffs("CTerrorPlayer","m_flLaggedMovementValue"), C, true)
	}
	SetEntDataFloat(B, FindSendPropOffs("CTerrorPlayer","m_flLaggedMovementValue"), C, true)
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg949\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
