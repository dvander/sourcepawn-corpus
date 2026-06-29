#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION	"1.0.5"
#define CVAR_FLAGS FCVAR_NOTIFY
#define WITCH_OFFSET	33.0

ConVar g_hPluginOn;
bool g_bHooked = false, g_bRoundStart = false, g_bPlayerSpawn = false;

public Plugin myinfo =
{
	name = "[L4D2] End Safedoor Witch",
	author = "sorallll",
	description = "",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=335777"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_end_safedoor_witch_version", PLUGIN_VERSION, "[L4D2] End Safedoor Witch plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_hPluginOn = CreateConVar("l4d2_end_safedoor_witch_enable", "1", "Enable/Disable plugin.", CVAR_FLAGS);

	AutoExecConfig(true, "l4d2_end_safedoor_witch");

	g_hPluginOn.AddChangeHook(OnConVarEnableChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = g_hPluginOn.BoolValue;
	if(!g_bHooked && bPluginOn)
	{
		g_bHooked = true;
		HookEvent("player_spawn", Events, EventHookMode_PostNoCopy);
		HookEvent("round_start", Events, EventHookMode_PostNoCopy);
		HookEvent("round_end", Events, EventHookMode_PostNoCopy);
		HookEvent("map_transition", Events, EventHookMode_PostNoCopy);
		HookEvent("finale_win", Events, EventHookMode_PostNoCopy);
	}
	else if(g_bHooked && !bPluginOn)
	{
		g_bHooked = false;
		UnhookEvent("player_spawn", Events, EventHookMode_PostNoCopy);
		UnhookEvent("round_start", Events, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", Events, EventHookMode_PostNoCopy);
		UnhookEvent("map_transition", Events, EventHookMode_PostNoCopy);
		UnhookEvent("finale_win", Events, EventHookMode_PostNoCopy);
		OnMapEnd();
	}
}

public void OnMapEnd()
{
	g_bRoundStart = false;
	g_bPlayerSpawn = false;
	PrecacheModel("models/infected/witch.mdl", false);
	PrecacheModel("models/infected/witch_bride.mdl", false);
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "player_spawn") == 0)
	{
		if (g_bRoundStart && !g_bPlayerSpawn)
		{
			Init();
		}
		g_bPlayerSpawn = true;
	}
	else if(strcmp(name, "round_start") == 0)
	{
		if (!g_bRoundStart && g_bPlayerSpawn)
		{
			Init();
		}
		g_bRoundStart = true;
	}
	else if(strcmp(name, "round_end") == 0 || strcmp(name, "map_transition") == 0 || strcmp(name, "finale_win") == 0)
	{
		OnMapEnd();
	}
	return Plugin_Continue;
}

void Init()
{
	int entity = INVALID_ENT_REFERENCE;
	if ((entity = FindEntityByClassname(MaxClients + 1, "info_changelevel")) == -1)
	{
		entity = FindEntityByClassname(MaxClients + 1, "trigger_changelevel");
	}

	if (entity == -1)
	{
		return;
	}

	int door = L4D_GetCheckpointLast();
	if (door == -1)
	{
		return;
	}

	float vOrigin[3];
	GetAbsOrigin(entity, vOrigin, true);
	vOrigin[2] = 0.0;

	float height;
	float vPos[3];
	float vAng[3];
	float vFwd[3];
	float vVec[2][3];
	float vEnd[2][3];

	GetEntPropVector(door, Prop_Data, "m_vecAbsOrigin", vPos);
	vVec[0] = vPos;
	vVec[0][2] = 0.0;
	MakeVectorFromPoints(vVec[0], vOrigin, vVec[0]);
	NormalizeVector(vVec[0], vVec[0]);

	GetEntPropVector(door, Prop_Data, "m_angRotationOpenBack", vAng);
	vAng[0] = vAng[2] = 0.0;
	GetAngleVectors(vAng, vFwd, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vFwd, vFwd);
	ScaleVector(vFwd, 28.0);
	AddVectors(vPos, vFwd, vPos);

	if (GetEndPoint(vPos, vAng, 56.0, vEnd[0]))
	{
		vAng[1] += 180.0;
		if (GetEndPoint(vPos, vAng, 56.0, vEnd[1]))
		{
			NormalizeVector(vFwd, vFwd);
			ScaleVector(vFwd, GetVectorDistance(vEnd[0], vEnd[1]) * 0.5);
			AddVectors(vEnd[1], vFwd, vPos);
		}
	}

	vAng[1] += 90.0;
	GetAngleVectors(vAng, vVec[1], NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vVec[1], vVec[1]);
	vAng[1] += RadToDeg(ArcCosine(GetVectorDotProduct(vVec[0], vVec[1]))) >= 90.0 ? 15.0 : 195.0;

	GetAngleVectors(vAng, vFwd, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vFwd, vFwd);
	ScaleVector(vFwd, WITCH_OFFSET);
	AddVectors(vPos, vFwd, vPos);

	vPos[2] -= 25.0;
	height = GetGroundHeight(vPos, 128.0);
	vPos[2] = height ? height : vPos[2] - 10.5;

	int iWitch = 0;
	switch(GetRandomInt(1, 2))
	{
		case 1:
		{
			iWitch = L4D2_SpawnWitch(vPos, vAng);
		}
		case 2:
		{
			iWitch = L4D2_SpawnWitchBride(vPos, vAng);
		}
	}

	if(iWitch > 0)
	{
		SetEntPropFloat(iWitch, Prop_Send, "m_rage", 0.5);
		SetEntProp(iWitch, Prop_Data, "m_nSequence", 4);
		SetEntProp(iWitch, Prop_Send, "m_CollisionGroup", 1);
		RequestFrame(FrameSolidCollision, EntIndexToEntRef(iWitch));
	}
}

void FrameSolidCollision(int iEnt)
{
	if (EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE)
	{
		SetEntProp(iEnt, Prop_Send, "m_CollisionGroup", 0);
	}
}

bool GetEndPoint(const float vStart[3], const float vAng[3], float scale, float vBuffer[3])
{
	float vEnd[3];
	GetAngleVectors(vAng, vEnd, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vEnd, vEnd);
	ScaleVector(vEnd, scale);
	AddVectors(vStart, vEnd, vEnd);

	Handle hTrace = TR_TraceHullFilterEx(vStart, vEnd, view_as<float>({-5.0, -5.0, 0.0}), view_as<float>({5.0, 5.0, 5.0}), MASK_ALL, TraceWorldFilter);
	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(vBuffer, hTrace);
		delete hTrace;
		return true;
	}

	delete hTrace;
	return false;
}

float GetGroundHeight(const float vPos[3], float scale)
{
	float vEnd[3];
	GetAngleVectors(view_as<float>({90.0, 0.0, 0.0}), vEnd, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vEnd, vEnd);
	ScaleVector(vEnd, scale);
	AddVectors(vPos, vEnd, vEnd);

	Handle hTrace = TR_TraceHullFilterEx(vPos, vEnd, view_as<float>({-5.0, -5.0, 0.0}), view_as<float>({5.0, 5.0, 5.0}), MASK_ALL, TraceWorldFilter);
	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(vEnd, hTrace);
		delete hTrace;
		return vEnd[2];
	}

	delete hTrace;
	return 0.0;
}

bool TraceWorldFilter(int entity, int contentsMask)
{
	return !entity;
}
