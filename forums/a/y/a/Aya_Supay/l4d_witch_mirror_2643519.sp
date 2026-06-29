// includes
#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define PLUGIN_VERSION		"1.0"

ConVar g_hCvarWitchMirror;

public Plugin myinfo =
{
	name = "witch mirror",
	description = "Create dynamic light when the witch spawn.  Selected randomly the colors.",
	author = "Joshe Gatito",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/joshegatito/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{	
	g_hCvarWitchMirror = CreateConVar("l4d_witch_mirror", "1", "0=Disable off, 1=Enable on.", CVAR_FLAGS );
	CreateConVar( "l4d_witch_mirror_version",PLUGIN_VERSION,	"Witch Mirror plugin version.", FCVAR_DONTRECORD);
	
	HookEvent("witch_spawn", eWitchSpawn);
	
	AutoExecConfig(true, "l4d_witch_mirror");	
}

public Action eWitchSpawn(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	int witch = GetEventInt(hEvent, "witchid");
	
	if (GetConVarInt(g_hCvarWitchMirror))
	{
		CreateTimer(0.1, Tail, witch, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Tail(Handle timer, any witch)
{
	int entity = CreateEntityByName("beam_spotlight");
	if (IsValidEntity(entity))
	{
		float pos[3], ang[3];
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(witch, Prop_Send, "m_angRotation", ang);
		ang[0] += -90.0;
		char tName[64];
		Format(tName, sizeof(tName), "Witch%d", witch);
		DispatchKeyValue(witch, "targetname", tName);
		GetEntPropString(witch, Prop_Data, "m_iName", tName, sizeof(tName));

		DispatchKeyValue(entity, "targetname", "LightEntity");
		DispatchKeyValue(entity, "parentname", tName);
		DispatchKeyValueVector(entity, "pos", pos);
		DispatchKeyValueVector(entity, "ang", ang);
		DispatchKeyValue(entity, "spotlightwidth", "10");
		DispatchKeyValue(entity, "spotlightlength", "60");
		DispatchKeyValue(entity, "spawnflags", "3");
		char buffer[12];
		Format(buffer, sizeof(buffer), "%i %i %i", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
		DispatchKeyValue(entity, "RenderColor", buffer);
		DispatchKeyValue(entity, "RenderAmt", "255");
		DispatchKeyValue(entity, "maxspeed", "100");
		DispatchKeyValue(entity, "HDRColorScale", "0.7");
		DispatchKeyValue(entity, "fadescale", "1");
		DispatchKeyValue(entity, "fademindist", "-1");
		DispatchSpawn(entity);
		SetVariantString(tName);
		AcceptEntityInput(entity, "SetParent", witch, entity);
		SetVariantString("forward");
		AcceptEntityInput(entity, "SetParentAttachment");
		AcceptEntityInput(entity, "Enable");
		AcceptEntityInput(entity, "DisableCollision");
		SetEntProp(entity, Prop_Send, "m_hOwnerEntity", witch);
		TeleportEntity(entity, NULL_VECTOR, ang, NULL_VECTOR);
	}
}