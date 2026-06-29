#define PLUGIN_VERSION "1.1"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#tryinclude <left4dragokas>

public Plugin myinfo = 
{
    name = "Hard Snow - Winter Wonderland",
    author = "BlueRaja (Fork by Dragokas)",
    description = "Make it snow!!",
    version = PLUGIN_VERSION,
    url = ""
}

#define CVAR_FLAGS 			FCVAR_NOTIFY

const int SNOW_LIMIT = 6; // max players to limit snow entities

enum struct Snow_Data {
	float BaseSpread;
	int Speed;
	float StartSize;
	float EndSize;
	int Twist;
}

char SNOW_MODEL[] = "particle/snow.vmt";
int g_SnowEntity[MAXPLAYERS+1][2];
int g_iTanks;
bool g_bLate;
char g_sColor[32];
int g_iTemplate;
bool g_bInsideRoom[MAXPLAYERS+1];
bool g_bShowOtherSnow;
bool g_bDoorUsed;
int g_iCheckpointDoor;

Snow_Data Template[10];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_hard_snow_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD | CVAR_FLAGS);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", 		Event_PlayerDisconnect, EventHookMode_Pre);
	HookEventEx("finale_escape_start",	Event_EscapeStart,	EventHookMode_PostNoCopy);
	HookEvent("player_use", 	OnPlayerUsePre, EventHookMode_Pre);
	
	if (g_bLate)
	{
		PrecacheModel(SNOW_MODEL);
		StartSnowAll();
	}
}

public void OnPluginEnd()
{
	KillSnowAll();
}

public void OnMapStart()
{
	PrecacheModel(SNOW_MODEL);
	InitDoor();
	ChangeColor();
	CreateTimer(1.0, Timer_CheckRoom, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

Action Timer_CheckRoom(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			g_bInsideRoom[i] = IsInsideRoom(i);
		}
	}
}

public void OnMapEnd()
{
    KillSnowAll();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	KillSnowAll();
}

void KillSnowAll()
{
	for(int i = 1; i <= MaxClients; i++)
    {
        KillSnow(i);
    }
}

public void OnTankCountChanged(int iCount)
{
	if (iCount > 0)
	{
		KillSnowAll();
	}

	if (iCount == 0 && g_iTanks != 0) // all tanks killed
	{
		StartSnowAll();
	}
	g_iTanks = iCount;
}

public Action OnPlayerUsePre(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bDoorUsed)
		return Plugin_Continue;
	
	int door = event.GetInt("targetid");
	if (IsValidEnt(door))
	{
		static char sEntityClass[64];
		GetEdictClassname(door, sEntityClass, sizeof(sEntityClass));
		if ( door != g_iCheckpointDoor || !StrEqual(sEntityClass, "prop_door_rotating_checkpoint"))
		{
			return Plugin_Continue;
		}
		g_bDoorUsed = true;
		g_bShowOtherSnow = true;
		StartSnowAll();
	}
	return Plugin_Continue;
}

void StartSnowAll(bool bRandom = true)
{
	if (bRandom)
	{
		ChangeColor();
		ChangeTemplate();
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			KillSnow(i);
			CreateTimer(GetRandomFloat(0.5, 10.0), TimerCallback_CreateSnow, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iTanks = 0;
	g_bShowOtherSnow = false;
	g_bDoorUsed = false;
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	KillSnow(client);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	if (client && g_iTanks == 0 && !IsFakeClient(client))
	{
		KillSnow(client);
		CreateTimer(1.0, TimerCallback_CreateSnow, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    
    KillSnow(client);
}

void ChangeTemplate()
{
	if (GetRandomInt(0, 3) == 0)
	{
		g_iTemplate = 1; // 25 %
	}
	else {
		g_iTemplate = 0;
	}
}

void ChangeColor()
{
	if (GetRandomInt(0, 1) == 0)
	{
		Format(g_sColor, sizeof(g_sColor), "%i %i %i", GetRandomInt(150, 200), 255, 255);
	}
	else {
		int channel =  GetRandomInt(200, 255);
		Format(g_sColor, sizeof(g_sColor), "%i %i %i", channel, channel, channel);
	}
}

public void Event_EscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bShowOtherSnow = true;

	if (GetRandomInt(0, 1) == 0)
	{
		g_sColor = "255 0 0";
		g_iTemplate = 1;
		StartSnowAll(false);
	}
}

public Action TimerCallback_CreateSnow(Handle timerInstance, int UserId)
{
	if (g_iTanks != 0 || EntityMaxed())
		return;
	
	Template[0].BaseSpread = 10.0;
	Template[0].Speed = 25;
	Template[0].StartSize = 1.0;
	Template[0].EndSize = 5.0;
	Template[0].Twist = GetRandomInt(0, 2) * 5;
	
	Template[1].BaseSpread = 400.0;
	Template[1].Speed = 25;
	Template[1].StartSize = 1.0;
	Template[1].EndSize = 2.0;
	Template[1].Twist = GetRandomInt(0, 1) * 25;
	
	int client = GetClientOfUserId(UserId);
	
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_SnowEntity[client][0] = CreateSnow(client, Template[g_iTemplate], g_sColor, "180 0 180", 50.0);
		g_SnowEntity[client][1] = CreateSnow(client, Template[g_iTemplate], g_sColor, "0 0 180", 40.0);	
	}
}

int GetSnowCount()
{
	int total = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int c = 0; c < sizeof(g_SnowEntity[]); c++)
		{
			int iSnow = EntRefToEntIndex(g_SnowEntity[i][c]);
			
			if(iSnow && iSnow != INVALID_ENT_REFERENCE && IsValidEntity(iSnow))
			{
				total++;
			}
		}
	}
	return total;
}

int CreateSnow(int client, Snow_Data t, char[] color, char[] angles, float EyeOffset )
{
	if (GetSnowCount() >= SNOW_LIMIT)
		return -1;
	
	float eyePosition[3];
	GetClientEyePosition(client, eyePosition);
	
	int iSnow = CreateEntityByName("env_smokestack");
	if(iSnow != -1)
	{
		DispatchKeyValueVector(iSnow,"Origin", eyePosition);
		DispatchKeyValueFloat(iSnow,"BaseSpread", t.BaseSpread); // 400	
		DispatchKeyValue(iSnow,"SpreadSpeed", "100"); // 100
		DispatchKeyValue(iSnow,"Speed", IntToStr(t.Speed)); // 25
		DispatchKeyValueFloat(iSnow,"StartSize", t.StartSize); // 1.0
		DispatchKeyValueFloat(iSnow,"EndSize", t.EndSize); // 1.0
		DispatchKeyValue(iSnow,"Twist", IntToStr(t.Twist)); 
		DispatchKeyValue(iSnow,"Rate", "100"); // 125
		DispatchKeyValue(iSnow,"JetLength", "200"); // 200
		DispatchKeyValue(iSnow,"RenderColor", color);
		DispatchKeyValue(iSnow,"RenderAmt", "200"); // 200
		DispatchKeyValue(iSnow,"RenderMode", "18"); // 18
		DispatchKeyValue(iSnow,"SmokeMaterial", "particle/snow");
		DispatchKeyValue(iSnow,"Angles", angles); // 180 0 0
		
		DispatchSpawn(iSnow);
		ActivateEntity(iSnow);
		
		eyePosition[2] += EyeOffset;
		TeleportEntity(iSnow, eyePosition, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(iSnow, "SetParent", client);
		
		AcceptEntityInput(iSnow, "TurnOn");
		
		SetEntityKillTimer(iSnow, GetRandomFloat(60.0, 180.0));
		
		SDKHook(iSnow, SDKHook_SetTransmit, Hook_SetTransmit);
		
		iSnow = EntIndexToEntRef(iSnow);
	}
	return iSnow;
}

public Action Hook_SetTransmit(int entity, int client)
{
	static int c;
	
	if (g_bShowOtherSnow)
		return Plugin_Continue;

	if (g_bInsideRoom[client])
		return Plugin_Handled;
		
	for (c = 0; c < sizeof(g_SnowEntity[]); c++)
	{
		if( EntIndexToEntRef(entity) == g_SnowEntity[client][c] )
			return Plugin_Continue;
	}
	return Plugin_Handled;
}

char[] IntToStr(int i)
{
	static char s[16];
	IntToString(i, s, sizeof(s));
	return s;
}

void KillSnow(int client)
{
	for (int c = 0; c < sizeof(g_SnowEntity[]); c++)
	{
		int iSnow = EntRefToEntIndex(g_SnowEntity[client][c]);

		if(iSnow && iSnow != INVALID_ENT_REFERENCE && IsValidEntity(iSnow))
		{
			AcceptEntityInput(iSnow, "Kill");
		}
		g_SnowEntity[client][c] = -1;
	}
}

void SetEntityKillTimer(int ent, float time)
{
	char sRemove[64];
	Format(sRemove, sizeof(sRemove), "OnUser1 !self:Kill::%f:1", time);
	SetVariantString(sRemove);
	AcceptEntityInput(ent, "AddOutput");
	AcceptEntityInput(ent, "FireUser1");
}

bool EntityMaxed()
{
	const int MAX = 1600;
	int entity;
	for (int i = 1; i < 2048; i++)
	{
		if(IsValidEdict(i))
		{
			if (entity > MAX)
				return true;
			entity++;
		}
	}
	return false;
}

/*
stock bool IsInsideRoom(int client)
{
	float fEndPos[3], vEye[3], vSky[3];
	
	GetClientEyePosition(client, vEye);
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vSky);
	vSky[0] = vEye[0];
	vSky[1] = vEye[1];
	
	Handle hTrace = TR_TraceRayFilterEx(vSky, view_as<float>({90.0, 0.0, 0.0}), MASK_VISIBLE, RayType_Infinite, TraceRayNoPlayers, client); 
	if (hTrace != INVALID_HANDLE) {
		if(TR_DidHit(hTrace))
		{
			TR_GetEndPosition(fEndPos, hTrace);
		}
		CloseHandle(hTrace);
	}
	return fEndPos[2] > vEye[2];
}
*/

stock bool IsInsideRoom(int client)
{
	static char sSky[] = "TOOLS/TOOLSSKYBOX";
	static char surface[64];
	float eyePos[3];
	
	GetClientEyePosition(client, eyePos);
	
	Handle hTrace = TR_TraceRayFilterEx(eyePos, view_as<float>({-90.0, 0.0, 0.0}), MASK_VISIBLE, RayType_Infinite, TraceRayNoPlayers, client);
	if (hTrace != INVALID_HANDLE) {
		if (TR_DidHit(hTrace))
		{
			TR_GetSurfaceName(hTrace, surface, sizeof(surface));
		}
		CloseHandle(hTrace);
	}
	return strcmp(surface, sSky) != 0;
}

public bool TraceRayNoPlayers(int entity, int mask, any data) 
{ 
	if(entity == data || (entity >= 1 && entity <= MaxClients)) 
	{
		return false; 
	} 
	return true; 
}

void InitDoor()
{
	g_iCheckpointDoor = 0;
	int iCheckpointEnt = -1;
	while ((iCheckpointEnt = FindEntityByClassname(iCheckpointEnt, "prop_door_rotating_checkpoint")) != -1)
	{
		if (!IsValidEnt(iCheckpointEnt))
		{
			continue;
		}
		
		static char sEntityName[128];
		GetEntPropString(iCheckpointEnt, Prop_Data, "m_iName", sEntityName, sizeof(sEntityName));
		if (StrEqual(sEntityName, "checkpoint_entrance", false))
		{			
			g_iCheckpointDoor = iCheckpointEnt;
			break;
		}
		else
		{
			static char sEntityModel[128];
			GetEntPropString(iCheckpointEnt, Prop_Data, "m_ModelName", sEntityModel, sizeof(sEntityModel));
			if (!StrEqual(sEntityModel, "models/props_doors/checkpoint_door_02.mdl", false) && !StrEqual(sEntityModel, "models/props_doors/checkpoint_door_-02.mdl", false))
			{
				continue;
			}
			g_iCheckpointDoor = iCheckpointEnt;
			break;
		}
	}
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}