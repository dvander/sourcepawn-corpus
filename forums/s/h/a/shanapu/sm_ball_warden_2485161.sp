public Plugin myinfo = 
{
	name = "Simple Soccer Ball",
	author = "mottzi, shanapu",
	description = "Simple Ball for CS:GO - with warden support",
	version = "1.2.1",
	url = "https://forums.alliedmods.net/showthread.php?p=2423345"
}

#include <sourcemod>
#include <sdkhooks>
#include <emitsoundany>
#include <warden>

// *** 
// only modify if you know what you're doing
#define BALL_ENTITY_NAME "simpleball"
#define BALL_CFG_FILE "configs/ballspawns.cfg"
#define BALL_PLAYER_DISTANCE 55.0
#define BALL_KICK_DISTANCE 55.0
#define BALL_KICK_POWER 600.0
#define BALL_HOLD_HEIGHT 15
#define BALL_KICK_HEIGHT_ADDITION 25
#define BALL_RADIUS 16.0
#define BALL_AUTO_RESPAWN 35.0
#define BALL_ADMIN_MENU_FLAG ADMFLAG_BAN
// thanks.
// *** 

#define FSOLID_NOT_SOLID 0x0004
#define FSOLID_TRIGGER 0x0008
#define IsClientValid(%0) (1 <= %0 <= MaxClients)

int g_Ball
int g_BallHolder

float g_BallSpawnOrigin[3]
bool g_BallSpawnExists

Handle g_TimerRespawn = INVALID_HANDLE

void InitializeVariables()
{
	g_BallHolder = 0
	g_BallSpawnExists = false
	g_TimerRespawn = INVALID_HANDLE
}

public OnPluginStart()
{
	RegConsoleCmd("ball", CommandBallMenu)
	
	AddNormalSoundHook(Event_SoundPlayed)
	HookEvent("round_start", EventRoundStart)
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre)
}

public Action CommandBallMenu(int client, int args)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Continue
	}
	
	int iFlags = GetUserFlagBits(client)
	
	if(iFlags & BALL_ADMIN_MENU_FLAG || warden_iswarden(client))
	{
		BallMenu(client)
	}
	else
	{
		PrintToChat(client, "[SM] Ball Plugin by mottzi.")
	}
	
	return Plugin_Continue
}

void BallMenu(int client)
{
	Menu menu = new Menu(BallMenuHandler)
	
	menu.SetTitle("[Ball] Menu")
	
	if(warden_iswarden(client)) menu.AddItem("", "Remove Ball", ITEMDRAW_DISABLED)
	else menu.AddItem("", "Remove Ball")
	if(warden_iswarden(client)) menu.AddItem("", "Add Ball", ITEMDRAW_DISABLED)
	else menu.AddItem("", "Add Ball")
	menu.AddItem("", "Reset Ball")
	
	menu.Display(client, MENU_TIME_FOREVER)
}

public int BallMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(param2)
			{
				// remove ball
				case 0:
				{
					if(g_BallSpawnExists)
					{
						DestroyBall()
						InitializeVariables()
						
						char szPathConfig[PLATFORM_MAX_PATH]
						BuildPath(Path_SM, szPathConfig, sizeof szPathConfig, BALL_CFG_FILE)
						
						Handle ConfigTree = CreateKeyValues("Spawns")
						FileToKeyValues(ConfigTree, szPathConfig)

						if(!ConfigTree)
						{
							PrintToChat(param1, "[SM] Loading from %s failed.", szPathConfig)
							CloseHandle(ConfigTree)
							return
						}
					
						char szMap[50]
						GetCurrentMap(szMap, sizeof szMap)
						
						if(KvJumpToKey(ConfigTree, szMap))
						{
							KvDeleteThis(ConfigTree)
						}
						
						KvRewind(ConfigTree)
						KeyValuesToFile(ConfigTree, szPathConfig)
						
						CloseHandle(ConfigTree)
						
						PrintToChat(param1, "[SM] Ball removed.")
					}
				}
				// add ball
				case 1:
				{
					DestroyBall()
					InitializeVariables()
					
					char szPathConfig[PLATFORM_MAX_PATH]
					BuildPath(Path_SM, szPathConfig, sizeof szPathConfig, BALL_CFG_FILE)
					
					Handle ConfigTree = CreateKeyValues("Spawns")
					FileToKeyValues(ConfigTree, szPathConfig)
					
					if(!ConfigTree)
					{
						PrintToChat(param1, "[SM] Loading from %s failed.", szPathConfig)
						CloseHandle(ConfigTree)
						return
					}
					
					char szMap[50]
					GetCurrentMap(szMap, sizeof szMap)
					
					if(KvJumpToKey(ConfigTree, szMap, true))
					{
						float fOrigin[3]
						GetPlayerEyeViewPoint(param1, fOrigin)
						fOrigin[2] += 20.0
						
						KvSetFloat(ConfigTree, "x", fOrigin[0])
						KvSetFloat(ConfigTree, "y", fOrigin[1])
						KvSetFloat(ConfigTree, "z", fOrigin[2])
						
						g_BallSpawnOrigin = fOrigin
						g_BallSpawnExists = true
						
						RespawnBall()
					}
					
					KvRewind(ConfigTree)
					KeyValuesToFile(ConfigTree, szPathConfig)
					
					CloseHandle(ConfigTree)
					
					PrintToChat(param1, "[SM] Ball added.")
				}
				case 2:
				{
					if(g_BallSpawnExists)
					{
						RespawnBall()
						
						PrintToChat(param1, "[SM] Ball resetted.")
					}
				}
			}
			
			BallMenu(param1)
		}
		case MenuAction_End:
		{
			delete menu
		}
	}
}

public OnMapStart()
{
	InitializeVariables()
	
	PrecacheSoundAny("knastjunkies/bounce.mp3")
	AddFileToDownloadsTable("sound/knastjunkies/bounce.mp3")
	PrecacheSoundAny("knastjunkies/gotball.mp3")
	AddFileToDownloadsTable("sound/knastjunkies/gotball.mp3")
	
	PrecacheModel("models/knastjunkies/soccerball.mdl")
	AddFileToDownloadsTable("models/knastjunkies/soccerball.mdl")
	AddFileToDownloadsTable("models/knastjunkies/SoccerBall.dx90.vtx")
	AddFileToDownloadsTable("models/knastjunkies/SoccerBall.phy")
	AddFileToDownloadsTable("models/knastjunkies/soccerball.vvd")
	
	AddFileToDownloadsTable("materials/knastjunkies/Material__0.vmt")
	AddFileToDownloadsTable("materials/knastjunkies/Material__1.vmt")
	
	LoadBall()
}

public Action Event_SoundPlayed(clients[64],&numClients,String:sample[PLATFORM_MAX_PATH],&entity,&channel,&Float:volume,&level,&pitch,&flags) 
{
	if(g_Ball == entity && StrEqual(sample, ")weapons/hegrenade/he_bounce-1.wav"))
	{
		EmitSoundToAllAny("knastjunkies/bounce.mp3", entity)
		
		return Plugin_Handled
	}
	
	return Plugin_Continue
}

public OnClientDisconnect(int client)
{
	if (IsClientInGame(client))
	{
		if (client == g_BallHolder)
		{
			RemoveBallHolder()
			
			StartRespawnTimer()
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{	
	if(client == g_BallHolder)
	{
		if(buttons & IN_USE)
		{
			KickBall(client, BALL_KICK_POWER)
		}
		else
		{
			SetBallInFront(client)
		}
	}
}

public EventPlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if(client == g_BallHolder)
	{
		RemoveBallHolder()
		
		StartRespawnTimer()
	}
}

public Action EventRoundStart(Handle event, char[] name, bool dontBroadcast) 
{
	if(g_BallSpawnExists)
	{
		RespawnBall()
	}
	
	StopRespawnTimer()
}

void StartRespawnTimer()
{
	if(g_TimerRespawn == INVALID_HANDLE)
	{
		g_TimerRespawn = CreateTimer(BALL_AUTO_RESPAWN, TimerRespawnBall, _, TIMER_FLAG_NO_MAPCHANGE)
	}
}

void StopRespawnTimer()
{
	if(g_TimerRespawn != INVALID_HANDLE)
	{
		KillTimer(g_TimerRespawn)
	}
	
	g_TimerRespawn = INVALID_HANDLE
}

public Action TimerRespawnBall(Handle h)
{
	StopRespawnTimer()
	RespawnBall()
}

void OnBallKicked()
{
	RemoveBallHolder()
	
	StartRespawnTimer()
}

void SetBallHolder(int client)
{
	if (client != g_BallHolder)
	{
		if(IsClientValid(g_BallHolder))
		{
			SDKUnhook(g_BallHolder, SDKHook_TraceAttack, TraceAttack)
		}
		
		g_BallHolder = client
		
		SDKHook(client, SDKHook_TraceAttack, TraceAttack)

		float v[3]
		GetClientAbsOrigin(client, v)
		
		EmitAmbientSoundAny("knastjunkies/gotball.mp3", v)
		
		StopRespawnTimer()
	}
}

public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) 
{ 
	if(victim == g_BallHolder && IsClientValid(attacker) && IsClientValid(victim) && victim != attacker)
	{
		KickBall(victim, 500.0)
	}
} 

void RecreateBall()
{
	DestroyBall()
	CreateBall()
}

void CreateBall()
{
	g_Ball = CreateEntityByName("hegrenade_projectile")
	DispatchKeyValue(g_Ball, "targetname", BALL_ENTITY_NAME)
	
	DispatchSpawn(g_Ball)
	SetEntityModel(g_Ball, "models/knastjunkies/soccerball.mdl")

	SetEntProp(g_Ball, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER)
	SetEntPropFloat(g_Ball, Prop_Data, "m_flModelScale", 0.60)
	
	Entity_SetMinSize(g_Ball, Float:{-BALL_RADIUS, -BALL_RADIUS, -BALL_RADIUS})
	Entity_SetMaxSize(g_Ball, Float:{BALL_RADIUS, BALL_RADIUS, BALL_RADIUS})
	
	SetEntityGravity(g_Ball, 0.8)
	
	SDKHook(g_Ball, SDKHook_Touch, OnBallTouch)
}

public OnBallTouch(int ball, int entity)
{
	if(g_BallHolder == 0 && IsClientValid(entity) && IsPlayerAlive(entity))
	{
		SetBallHolder(entity)
	}
}

void DestroyBall()
{
	if(IsValidEntity(g_Ball))
	{
		AcceptEntityInput(g_Ball, "Kill")
	}
}

public bool BallTraceFilter(int entity, int mask, any client)
{
	return !IsClientValid(entity) && entity != g_Ball
}

void RespawnBall()
{
	ClearBall()
	SetEntityMoveType(g_Ball, MOVETYPE_FLYGRAVITY)
	TeleportEntity(g_Ball, g_BallSpawnOrigin, NULL_VECTOR, Float:{0.0, 0.0, 100.0})
}

void RemoveBallHolder()
{
	g_BallHolder = 0
}

void ClearBall()
{
	RecreateBall()
	RemoveBallHolder()
}

void KickBall(int client, float power)
{
	if(IsInterferenceForKick(client, BALL_KICK_DISTANCE))
	{
		return
	}
	
	float clientEyeAngles[3]
	GetClientEyeAngles(client, clientEyeAngles)	
	
	float angleVectors[3]
	GetAngleVectors(clientEyeAngles, angleVectors, NULL_VECTOR, NULL_VECTOR)
	
	float ballVelocity[3]
	ballVelocity[0] = angleVectors[0] * power
	ballVelocity[1] = angleVectors[1] * power
	ballVelocity[2] = angleVectors[2] * power
	
	float frontOrigin[3]
	GetClientFrontBallOrigin(client, BALL_KICK_DISTANCE, BALL_HOLD_HEIGHT + BALL_KICK_HEIGHT_ADDITION, frontOrigin)
	
	float kickOrigin[3]
	kickOrigin[0] = frontOrigin[0]
	kickOrigin[1] = frontOrigin[1]
	kickOrigin[2] = frontOrigin[2] + BALL_KICK_HEIGHT_ADDITION

	RecreateBall()

	TeleportEntity(g_Ball, kickOrigin, NULL_VECTOR, ballVelocity)	

	g_BallHolder = 0
	
	OnBallKicked()
}

bool IsInterferenceForKick(int client, float kickDistance)
{
	float clientOrigin[3]
	GetClientAbsOrigin(client, clientOrigin)
	
	float clientEyeAngles[3]
	GetClientEyeAngles(client, clientEyeAngles)
		
	float cos = Cosine(DegToRad(clientEyeAngles[1]))
	float sin = Sine(DegToRad(clientEyeAngles[1]))
	
	float leftBottomOrigin[3]
	leftBottomOrigin[0] = clientOrigin[0] - sin * BALL_RADIUS
	leftBottomOrigin[1] = clientOrigin[1] - cos * BALL_RADIUS
	leftBottomOrigin[2] = clientOrigin[2] + BALL_HOLD_HEIGHT + BALL_KICK_HEIGHT_ADDITION - BALL_RADIUS
	
	float startOriginAddtitions[3]
	startOriginAddtitions[0] = sin * BALL_RADIUS
	startOriginAddtitions[1] = cos * BALL_RADIUS
	startOriginAddtitions[2] = BALL_RADIUS
	
	float testOriginAdditions[3]
	testOriginAdditions[0] = cos * (kickDistance + BALL_RADIUS)
	testOriginAdditions[1] = sin * (kickDistance + BALL_RADIUS)
	testOriginAdditions[2] = 0.0;	
	
	float startOrigin[3]
	float testOrigin[3]
	
	for(int x = 0; x < 3; x++)
	{
		for(int y = 0; y < 3; y++)
		{
			for(int z = 0; z < 3; z++)
			{
				startOrigin[0] = leftBottomOrigin[0] + x * startOriginAddtitions[0]
				startOrigin[1] = leftBottomOrigin[1] + y * startOriginAddtitions[1]
				startOrigin[2] = leftBottomOrigin[2] + z * startOriginAddtitions[2]
				
				for (int j = 0; j < 3; j++)
				{
					testOrigin[j] = startOrigin[j] + testOriginAdditions[j]
				}
				
				TR_TraceRayFilter(startOrigin, testOrigin, MASK_SOLID, RayType_EndPoint, BallTraceFilter, client)	
				
				if(TR_DidHit())
				{
					return true
				}
			}
		}
	}
	
	return false
}

void SetBallInFront(int client)
{
	float origin[3]
	GetClientFrontBallOrigin(client, BALL_PLAYER_DISTANCE, BALL_HOLD_HEIGHT, origin)
	
	TeleportEntity(g_Ball, origin, NULL_VECTOR, Float:{0.0, 0.0, 100.0})
}

void GetClientFrontBallOrigin(int client, float distance, int height, float destOrigin[3])
{
	float clientOrigin[3]
	GetClientAbsOrigin(client, clientOrigin)
	
	float clientEyeAngles[3]
	GetClientEyeAngles(client, clientEyeAngles)
	
	float cos = Cosine(DegToRad(clientEyeAngles[1]))
	float sin = Sine(DegToRad(clientEyeAngles[1]))
	
	destOrigin[0] = clientOrigin[0] + cos * distance
	destOrigin[1] = clientOrigin[1] + sin * distance
	destOrigin[2] = clientOrigin[2] + height
}

void LoadBall() 
{
	char szPathConfig[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, szPathConfig, sizeof szPathConfig, BALL_CFG_FILE)
	
	Handle ConfigTree = CreateKeyValues("Spawns")
	FileToKeyValues(ConfigTree, szPathConfig);

	char szMap[50]
	GetCurrentMap(szMap, sizeof szMap)
	
	if(KvJumpToKey(ConfigTree, szMap)) 
	{
		g_BallSpawnOrigin[0] = KvGetFloat(ConfigTree, "x")
		g_BallSpawnOrigin[1] = KvGetFloat(ConfigTree, "y")
		g_BallSpawnOrigin[2] = KvGetFloat(ConfigTree, "z")
		
		g_BallSpawnExists = true
		CreateBall()
		RespawnBall()
	}
	
	CloseHandle(ConfigTree)
}

stock Entity_SetMinSize(entity, float vecMins[3])
{
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vecMins);
}

stock Entity_SetMaxSize(entity, float vecMaxs[3])
{
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMaxs);
}

stock GetPlayerEyeViewPoint(iClient, float fPosition[3])
{
	float fAngles[3]
	GetClientEyeAngles(iClient, fAngles)

	float fOrigin[3]
	GetClientEyePosition(iClient, fOrigin)

	Handle hTrace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer)
	
	if(TR_DidHit(hTrace))
	{
		TR_GetEndPosition(fPosition, hTrace)
		CloseHandle(hTrace)
		
		return true
	}
	
	CloseHandle(hTrace)
	
	return false
}

public bool TraceEntityFilterPlayer(int iEntity, int iContentsMask)
{
	return iEntity > GetMaxClients()
}