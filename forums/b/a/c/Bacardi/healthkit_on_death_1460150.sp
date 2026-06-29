#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION	"1.7.0"

#define HEALTHKIT_SOUND	"items/medshot4.wav"
#define HEALTHKIT_MODEL	"models/items/healthkit.mdl"

#define MAX_HEALTHKITS	255

// ConVars
new Handle:hod_enabled		= INVALID_HANDLE;
new Handle:hod_health		= INVALID_HANDLE;
new Handle:hod_max_health	= INVALID_HANDLE;
new Handle:hod_lifetime		= INVALID_HANDLE;
new Handle:hod_dissolve		= INVALID_HANDLE;
new Handle:mp_teamplay		= INVALID_HANDLE;

// SendProp Offsets
new g_iCollision	= -1;
new g_iSolidFlags	= -1;

// SDKTools Stuff
new Handle:g_hGameConf		= INVALID_HANDLE;
new Handle:g_hDissolve		= INVALID_HANDLE;
new Handle:g_hUtilRemove	= INVALID_HANDLE;

// Healthkit
new g_iHealthkits[MAX_HEALTHKITS]	= {-1,...};
new g_iHealthkitIndex = 0;

// Timers
new Handle:g_hTimersDissolve[MAX_HEALTHKITS]	= {INVALID_HANDLE,...};
new Handle:g_hTimersRemove[MAX_HEALTHKITS]		= {INVALID_HANDLE,...};

public Plugin:myinfo =
{
	name = "HL2MP Healthkit On Death",
	author = "Knagg0",
	description = "Added to work with cvar mp_teamplay",
	version = PLUGIN_VERSION,
	url = "-"
}

public OnPluginStart()
{
	AutoExecConfig();

	// Create ConVars
	CreateConVar("hod_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	hod_enabled		= CreateConVar("hod_enabled", "1", "", FCVAR_PLUGIN);
	hod_health		= CreateConVar("hod_health", "25", "", FCVAR_PLUGIN);
	hod_max_health	= CreateConVar("hod_max_health", "150", "", FCVAR_PLUGIN);
	hod_lifetime	= CreateConVar("hod_lifetime", "5", "", FCVAR_PLUGIN);
	hod_dissolve	= CreateConVar("hod_dissolve", "1", "", FCVAR_PLUGIN);
	mp_teamplay		= FindConVar("mp_teamplay");

	// Find SendProp Offsets
	if((g_iCollision = FindSendPropOffs("CBaseEntity", "m_Collision")) == -1) {
		LogError("Could not find offset for CBaseEntity::m_Collision");
	}

	if((g_iSolidFlags = FindSendPropOffs("CBaseEntity", "m_usSolidFlags")) == -1) {
		LogError("Could not find offset for CBaseEntity::m_usSolidFlags");
	}

	// SDKTools
	if((g_hGameConf = LoadGameConfigFile("plugin.healthkit_on_death")) != INVALID_HANDLE) {
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "Dissolve");
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByValue);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hDissolve = EndPrepSDKCall();

		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "UTIL_Remove");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hUtilRemove = EndPrepSDKCall();
	}
	
	// Hook Events
	HookEvent("player_death", EventPlayerDeath);
}

public OnMapStart()
{
	PrecacheSound(HEALTHKIT_SOUND, true);
	PrecacheModel(HEALTHKIT_MODEL, true);
}

public StartTouch(iEntity, iOther)
{
	if (iOther < 1 || iOther > MaxClients || !IsClientInGame(iOther) || !IsPlayerAlive(iOther)) {
		return;
	}

	new iMaxHealth = GetConVarInt(hod_max_health);
	new iClientHealth = GetClientHealth(iOther);

	if (iClientHealth < iMaxHealth) {
		iClientHealth += GetConVarInt(hod_health);
		if (iClientHealth > iMaxHealth) {
			iClientHealth = iMaxHealth;
		}
		SetEntityHealth(iOther, iClientHealth);

		new Float:vecPos[3];
		GetClientAbsOrigin(iOther, vecPos);
		EmitSoundToAll(HEALTHKIT_SOUND, iOther, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);

		RemoveEntity(iEntity);
	}
}

public OnEntityDestroyed(iEntity)
{
	new iIndex = GetHealthkitIndex(iEntity);
	if (iIndex == -1) return;

	if (g_hTimersDissolve[iIndex] != INVALID_HANDLE) {
		CloseHandle(g_hTimersDissolve[iIndex]);
		g_hTimersDissolve[iIndex] = INVALID_HANDLE;
	}

	if (g_hTimersRemove[iIndex] != INVALID_HANDLE) {
		CloseHandle(g_hTimersRemove[iIndex]);
		g_hTimersRemove[iIndex] = INVALID_HANDLE;
	}

	g_iHealthkits[iIndex] = -1;
}

public EventPlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if(!GetConVarBool(hod_enabled)) {
		return;
	}

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new bool:teamplay = GetConVarBool(mp_teamplay);

	if(iClient != 0 && iAttacker != 0 && (teamplay && GetClientTeam(iClient) != GetClientTeam(iAttacker) || !teamplay)) {
		CreateHealthkit(iClient, g_iHealthkitIndex);
		SetNextHealthkitIndex();
	}
}

// Timers
public Action:TimerDissolve(Handle:hTimer, any:iIndex)
{
	g_hTimersDissolve[iIndex] = INVALID_HANDLE;

	if (g_iHealthkits[iIndex] != -1) {
		DissolveEntity(g_iHealthkits[iIndex]);
	}
}

public Action:TimerRemove(Handle:hTimer, any:iIndex)
{
	g_hTimersRemove[iIndex] = INVALID_HANDLE;

	if (g_iHealthkits[iIndex] != -1) {
		RemoveEntity(g_iHealthkits[iIndex]);
	}
}

CreateHealthkit(iClient, iIndex)
{
	new iEntity = CreateEntityByName("prop_physics", -1);
	if (iEntity == -1) return;

	new Float:vecPos[3];
	GetClientAbsOrigin(iClient, vecPos);
	vecPos[2] += GetRandomFloat(5.0, 1.0);

	new Float:vecVel[3];
	vecVel[0] = GetRandomFloat(-200.0, 200.0);
	vecVel[1] = GetRandomFloat(-200.0, 200.0);
	vecVel[2] = GetRandomFloat(1.0, 200.0);

	SetEntityModel(iEntity, HEALTHKIT_MODEL);
	TeleportEntity(iEntity, vecPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iEntity);

	SetEntityMoveType(iEntity, MOVETYPE_VPHYSICS);
	SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 1);
	SetEntProp(iEntity, Prop_Data, "m_MoveCollide", 0);
	SetSolidFlags(iEntity, 152);

	TeleportEntity(iEntity, NULL_VECTOR, NULL_VECTOR, vecVel);

	SDKHook(iEntity, SDKHook_StartTouch, StartTouch);

	new Float:fLifeTime = GetConVarFloat(hod_lifetime);
	new Float:fDissolve = fLifeTime - 2.5;

	if(GetConVarBool(hod_dissolve)) {
		if (fDissolve < 0.0) fDissolve = 0.0;
		g_hTimersDissolve[iIndex] = CreateTimer(fDissolve, TimerDissolve, iIndex);
	}

	g_hTimersRemove[iIndex] = CreateTimer(fLifeTime, TimerRemove, iIndex);

	g_iHealthkits[iIndex] = iEntity;
}

GetHealthkitIndex(iEntity) {
	for (new i = 0; i < MAX_HEALTHKITS; i++) {
		if (g_iHealthkits[i] == iEntity) {
			return i;
		}
	}
	return -1;
}

SetNextHealthkitIndex() {
	g_iHealthkitIndex++;
	if (g_iHealthkitIndex >= MAX_HEALTHKITS) {
		g_iHealthkitIndex = 0;
	}
}

SetSolidFlags(iEntity, iFlags)
{
	if(g_iCollision == -1 || g_iSolidFlags == -1) return;
	SetEntData(iEntity, g_iCollision + g_iSolidFlags, iFlags, 2, true);
}

DissolveEntity(iEntity)
{
	if(g_hDissolve == INVALID_HANDLE) return -1;
	return SDKCall(g_hDissolve, iEntity, NULL_STRING, GetGameTime(), false, 0, Float:{0.0,0.0,0.0}, 0);
}

RemoveEntity(iEntity)
{
    if(g_hUtilRemove == INVALID_HANDLE) return;
    SDKCall(g_hUtilRemove, iEntity);
}
