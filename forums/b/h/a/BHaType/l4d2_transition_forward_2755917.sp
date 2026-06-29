#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] Transition Forward",
	author = "BHaType",
	description = "Provides forward to determine transitioned entities between map",
	version = "0.1"
};

int m_nSkin;
GlobalForward g_hTransition;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{	
	g_hTransition = new GlobalForward ("OnEntityTransitioned", ET_Ignore, Param_Cell, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{
	m_nSkin = FindSendPropInfo("CBaseAnimating", "m_nSkin");
	
	HookEvent("map_transition", map_transition, EventHookMode_PostNoCopy);
}

public Action map_transition (Event event, const char[] name, bool dontbroadcast)
{
	SaveWeapons();
}

public void OnEntityCreated (int entity, const char[] name)
{
	if ( StrContains(name, "weapon_") == -1 || !IsValidEntity(entity) )
		return;
	
	SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawnedSH);
}

public void OnEntitySpawnedSH (int entity) {	RequestFrame(NextFrame, EntIndexToEntRef(entity)); }

public void NextFrame (int entity)
{
	if ( (entity = EntRefToEntIndex(entity)) == -1 || !IsValidEntity(entity) || entity <= MaxClients )
		return;
		
	int skin = GetEntData(entity, m_nSkin);
	
	if ( skin >> 16 == 0 )
		return;
		
	Call_StartForward(g_hTransition);
	Call_PushCell(skin >> 16);
	Call_PushCell(entity);
	Call_Finish();
	
	SetEntData(entity, m_nSkin, skin & 0xFFFF);
}

void SaveWeapons()
{	
	int entity = MaxClients + 1;
	
	while ( (entity = FindEntityByClassname(entity, "weapon_*")) && IsValidEntity(entity) )
		SetEntData(entity, m_nSkin, (entity << 16) | GetEntData(entity, m_nSkin));
}