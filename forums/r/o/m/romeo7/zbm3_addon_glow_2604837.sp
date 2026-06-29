#include <sourcemod>
#include <sdktools>
#include <zombieplague>

#pragma newdecls required

int glowentity[MAXPLAYERS + 1] = {-1,...};
int g_iEntity[MAXPLAYERS + 1];

ConVar gH_NGEnable = null;
ConVar gH_SGEnable = null;
ConVar gH_NGRadius = null;
ConVar gH_SGRadius = null;

bool	bNGEnabled = true;
bool	bSGEnabled = true;
float	flNGRadius;
float	flSGRadius;

public Plugin myinfo =
{
	name        	= "[ZP] Addon: Glow",
	author      	= "Romeo",
	description 	= "Glow Addon for Nemesis and Survivor",
	version     	= "1.2",
	url         	= ""
}

public void OnPluginStart()
{
	gH_NGEnable = CreateConVar("zp_glow_nemesis", "1", "Aura & Glow for Nemesis", 0, true, 0.0, true, 1.0);
	gH_SGEnable = CreateConVar("zp_glow_survivor", "1", "Aura & Glow for Survivor", 0, true, 0.0, true, 1.0);
	gH_NGRadius = CreateConVar("zp_glow_radius_nemesis", "20", "Aura & Glow Radius for Nemesis", 0, true, 0.0, true, 100.0);
	gH_SGRadius = CreateConVar("zp_glow_radius_survivor", "20", "Aura & Glow Radius for Survivor", 0, true, 0.0, true, 100.0);
	
	gH_NGEnable.AddChangeHook(ConVarChange);
	gH_SGEnable.AddChangeHook(ConVarChange);
	gH_NGRadius.AddChangeHook(ConVarChange);
	gH_SGRadius.AddChangeHook(ConVarChange);
	
	bNGEnabled = gH_NGEnable.BoolValue;
	bSGEnabled = gH_SGEnable.BoolValue;
	flNGRadius = gH_NGRadius.FloatValue;
	flSGRadius = gH_SGRadius.FloatValue;
	
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);

	for(int i=1;i<=64;i++)
	{
		OnClientPutInServer(i);
	}
	
	AutoExecConfig(true, "zombieplague_glow");
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	bNGEnabled = gH_NGEnable.BoolValue;
	bSGEnabled = gH_SGEnable.BoolValue;
	flNGRadius = gH_NGRadius.FloatValue;
	flSGRadius = gH_SGRadius.FloatValue;
}

public Action EventPlayerDeath(Event hEvent, const char[] sName, bool dontBroadcast) 
{
	int userid = GetEventInt(hEvent, "userid");
	int clientIndex = GetClientOfUserId(userid);
	
	if(bNGEnabled && ZP_IsPlayerNemesis(clientIndex) || bSGEnabled && ZP_IsPlayerSurvivor(clientIndex))
	{
		RemoveLight(clientIndex);
	}
}

public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{	
	if(bNGEnabled && ZP_IsPlayerNemesis(clientIndex))
	{
		SetLightNemesis(clientIndex);
	}
}

public void ZP_OnClientHumanized(int clientIndex)
{
	if(bSGEnabled && ZP_IsPlayerSurvivor(clientIndex))
	{
		SetLightSurvivior(clientIndex);
	}
}

public Action RemoveLight(int clientIndex)
{
	if(!(clientIndex<65&&clientIndex>0))
	{
		return;
	}
	
	AcceptEntityInput(glowentity[clientIndex], "kill");
	glowentity[clientIndex]=-1;
}

public Action SetLightNemesis(int clientIndex)
{
	// Aura
	int iEntity = CreateEntityByName("light_dynamic");
	glowentity[clientIndex]=iEntity;
	DispatchKeyValue(iEntity, "brightness", "5");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 75.0);
	DispatchKeyValue(iEntity, "style", "0");
	DispatchKeyValue(iEntity, "_light", "150 0 0 150");
	DispatchKeyValueFloat(iEntity, "distance", flNGRadius*100.0);
	DispatchSpawn(iEntity);
	
	float m_flClientOrigin[3];
	GetClientAbsOrigin(clientIndex, m_flClientOrigin);
	
	TeleportEntity(iEntity, m_flClientOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(iEntity, MOVETYPE_NONE);
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", clientIndex, iEntity, 0);
	
	// Glow
	char sBuffer[128];
	GetClientModel(clientIndex, sBuffer, sizeof(sBuffer));
	
	int Entity = CreatePlayerModel(clientIndex, sBuffer);
	
	SetEntProp(Entity, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(Entity, Prop_Send, "m_nGlowStyle", 1); // 0 - esp / 1,2 - glow
	SetEntPropFloat(Entity, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow"), 255, _, true);    // Red 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 1, 0, _, true); // Green 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 2, 0, _, true); // Blue 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 3, 150, _, true); // Alpha 
}

public Action SetLightSurvivior(int clientIndex)
{
	// Aura
	int iEntity = CreateEntityByName("light_dynamic");
	glowentity[clientIndex]=iEntity;
	DispatchKeyValue(iEntity, "brightness", "5");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 75.0);
	DispatchKeyValue(iEntity, "style", "0");
	DispatchKeyValue(iEntity, "_light", "100 100 100 100");
	DispatchKeyValueFloat(iEntity, "distance", flSGRadius*100.0);
	DispatchSpawn(iEntity);
	
	float m_flClientOrigin[3];
	GetClientAbsOrigin(clientIndex, m_flClientOrigin);
	
	TeleportEntity(iEntity, m_flClientOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(iEntity, MOVETYPE_NONE);
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", clientIndex, iEntity, 0);
	
	// Glow
	char sBuffer[128];
	GetClientModel(clientIndex, sBuffer, sizeof(sBuffer));
	
	int Entity = CreatePlayerModel(clientIndex, sBuffer);
	
	SetEntProp(Entity, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(Entity, Prop_Send, "m_nGlowStyle", 1); // 0 - esp / 1,2 - glow
	SetEntPropFloat(Entity, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow"), 100, _, true);    // Red 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 1, 100, _, true); // Green 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 2, 100, _, true); // Blue 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 3, 100, _, true); // Alpha 
}

public void OnClientPutInServer(int clientIndex)
{
	glowentity[clientIndex]=-1;
}

int CreatePlayerModel(int client, const char[] sBuffer)
{
	RemoveModel(client);
	
	int iEntity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(iEntity, "model", sBuffer);
	DispatchKeyValue(iEntity, "solid", "0");
	DispatchSpawn(iEntity);
	
	SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
	SetEntityRenderColor(iEntity, 255, 255, 255, 0);
	
	SetEntProp(iEntity, Prop_Send, "m_fEffects", (1 << 0)|(1 << 4)|(1 << 6)|(1 << 9));
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", client, iEntity, 0);
	SetVariantString("primary");
	AcceptEntityInput(iEntity, "SetParentAttachment", iEntity, iEntity, 0);
	
	g_iEntity[client] = EntIndexToEntRef(iEntity);
	return iEntity;
}

void RemoveModel(int client)
{
	int iEntity = EntRefToEntIndex(g_iEntity[client]);
	if(iEntity != INVALID_ENT_REFERENCE && iEntity > 0 && IsValidEntity(iEntity)) AcceptEntityInput(iEntity, "Kill");

	g_iEntity[client] = 0;
}