#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.1"

static Handle hCvar_fFallVec = null;
static float fMaxFallVec;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "High_Impact_Ragdoll_Deaths",
	author = "Lux",
	description = "High impact falls that kill you as a survivor will now ragdoll and no defibbing.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2615988"
};

public void OnPluginStart()
{
	CreateConVar("hird_version", PLUGIN_VERSION, "High_Impact_Ragdoll_Deaths version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvar_fFallVec = FindConVar("survivor_incap_max_fall_damage");
	if(hCvar_fFallVec == null)
		SetFailState("Unable to find survivor_incap_max_fall_damage");
	HookConVarChange(hCvar_fFallVec, eCvarsChanged);
	fMaxFallVec = float(GetConVarInt(hCvar_fFallVec));
}

public void eCvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fMaxFallVec = float(GetConVarInt(hCvar_fFallVec));
}


public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if(damagetype & ~DMG_FALL)
		return;
	
	if(GetClientTeam(victim) != 2 && IsFakeClient(victim))
	{
		SDKUnhook(victim, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);
		return;
	}
	
	if(GetEntProp(victim, Prop_Send, "m_isFallingFromLedge", 1))
		return;
	
	if(fMaxFallVec > GetEntPropFloat(victim, Prop_Send, "m_flFallVelocity"))
		return;
	
	SetEntProp(victim, Prop_Send, "m_isFallingFromLedge", 1, 1);
	
	int iEntity;
	char sModelName[128];
	float g_Origin[3], g_Angle[3];
		
	GetEntPropString(victim, Prop_Data, "m_ModelName", sModelName, 128);
	GetClientAbsOrigin(victim, g_Origin);
	GetClientAbsAngles(victim, g_Angle);
	
	iEntity = CreateEntityByName("survivor_death_model");
	SetEntityModel(iEntity, sModelName);
	TeleportEntity(iEntity, g_Origin, g_Angle, NULL_VECTOR);
	DispatchSpawn(iEntity);
	SetEntityRenderMode(iEntity, RENDER_NONE);

	SDKHook(victim, SDKHook_SetTransmit, CheckIfAlive);
}

public void CheckIfAlive(int iEntity, int iClient)
{
	if(IsPlayerAlive(iEntity))
		SetEntProp(iEntity, Prop_Send, "m_isFallingFromLedge", 0, 1);
	
	SDKUnhook(iEntity, SDKHook_SetTransmit, CheckIfAlive);
}