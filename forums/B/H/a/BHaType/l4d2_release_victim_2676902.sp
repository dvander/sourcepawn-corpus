#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[L4D2] Release Victim Extended version",
	author = "BHaType",
	description = "Allow to release victim",
	version = "0.4"
};

bool g_bReset, g_bEffect;
int g_iCharger, g_iHunter, g_iJockey, g_iSmoker, g_iZombieClass, g_iVelocity;
Handle g_hCharger, g_hJockey, g_hSmoker, g_hHunter, g_hReset;
ConVar sm_release_distance, sm_release_height, sm_release_ability_reset, sm_release_effect;
float g_flDistance, g_flHeight, g_flCharger, g_flSmoker, g_flJockey;


public void OnPluginStart()
{
	sm_release_distance = CreateConVar("sm_release_distance", "900.0", "Release distance", FCVAR_NONE);
	sm_release_height = CreateConVar("sm_release_height", "600.0", "Release height", FCVAR_NONE);
	sm_release_ability_reset = CreateConVar("sm_release_ability_reset", "0", "Reset ability", FCVAR_NONE);
	sm_release_effect = CreateConVar("sm_release_effect", "0", "Show effect after release", FCVAR_NONE);
	
	OnConVarChanged(GetMyHandle(), NULL_STRING, NULL_STRING);
	
	sm_release_ability_reset.AddChangeHook(OnConVarChanged);
	sm_release_distance.AddChangeHook(OnConVarChanged);
	sm_release_height.AddChangeHook(OnConVarChanged);
	sm_release_effect.AddChangeHook(OnConVarChanged);
	
	SetupSDK();
	
	g_flCharger = FindConVar("z_charge_interval").FloatValue;
	g_flSmoker = FindConVar("smoker_tongue_delay").FloatValue;
	g_flJockey = FindConVar("z_jockey_leap_again_timer").FloatValue;
	
	AutoExecConfig(true, "l4d2_release_victim");
	
	g_iCharger = FindSendPropInfo("CTerrorPlayer", "m_pummelVictim"); 
	g_iHunter = FindSendPropInfo("CTerrorPlayer", "m_pounceVictim");
	g_iJockey = FindSendPropInfo("CTerrorPlayer", "m_jockeyVictim");
	g_iSmoker = FindSendPropInfo("CTongue", "m_tongueState");
	g_iZombieClass = FindSendPropInfo("CTerrorPlayer", "m_zombieClass");
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	HookEvents(EventHandler);
}

public void OnMapStart()
{
	int pTable = FindStringTable("ParticleEffectNames");

	if ( FindStringIndex(pTable, "gen_hit1_c") == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(pTable, "gen_hit1_c");
		LockStringTables(save);
	}
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_flDistance = sm_release_distance.FloatValue;
	g_flHeight = sm_release_height.FloatValue;
	g_bReset = sm_release_ability_reset.BoolValue;
	g_bEffect = sm_release_effect.BoolValue;
}

public Action OnPlayerRunCmd (int client, int &buttons)
{
	if (IsFakeClient(client) || GetClientTeam(client) != 3 || !(buttons & IN_ATTACK2))
		return Plugin_Continue;
	
	int iClass = GetEntData(client, g_iZombieClass), index;
	
	switch (iClass)
	{
		case 6: index = GetEntData(client, g_iCharger);
		case 3: index = GetEntData(client, g_iHunter);
		case 5: index = GetEntData(client, g_iJockey);
		case 1: 
		{
			int iEntity = GetEntPropEnt(client, Prop_Send, "m_customAbility");
			
			if (iEntity <= MaxClients)
				return Plugin_Continue;
			
			index = GetEntData(iEntity, g_iSmoker);
		}
	}

	if (index <= 0 || (iClass == 1 && index != 3))
		return Plugin_Continue;
	
	Release(client, iClass);
	return Plugin_Continue;
}

void Release (int client, int iClass)
{
	switch (iClass)
	{
		case 6: SDKCall(g_hCharger, client, true, client);
		case 3: SDKCall(g_hHunter, client);
		case 5: SDKCall(g_hJockey, client, client);
		case 1: SDKCall(g_hSmoker, client, true);
	}
	
	float vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	vOrigin[2] += 5.0;
	
	if ( g_bEffect )
		SpoofEffect(vOrigin);
	
	if ( g_flDistance > 0 || g_flHeight > 0 )
		CreateTimer(0.05, tFly, GetClientUserId(client));
		
	CreateTimer(0.2, tReset, GetClientUserId(client)); 
}

public Action tFly (Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !IsClientInGame(client))
		return;
		
	StoreToAddress(GetEntityAddress(client) + view_as<Address>(11481), 1, NumberType_Int32);
	
	float vAngles[3], vDirection[3], vCurrent[3], vResult[3];
	
	GetClientEyeAngles(client, vAngles);
	
	GetAngleVectors(vAngles, vDirection, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vDirection, g_flDistance);
	GetEntDataVector(client, g_iVelocity, vCurrent);
	
	vResult[0] = vCurrent[0] + vDirection[0];
	vResult[1] = vCurrent[1] + vDirection[1];
	vResult[2] = g_flHeight;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vResult);
	
	CreateTimer(0.2, tReset, GetClientUserId(client)); 
}

public Action tReset (Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) == 0 || !IsClientInGame(client))
		return;
		
	StoreToAddress(GetEntityAddress(client) + view_as<Address>(11481), 0, NumberType_Int32);
	
	if (g_bReset)
	{
		int iEntity = GetEntPropEnt(client, Prop_Send, "m_customAbility");
		
		if (iEntity > MaxClients)
		{
			switch (GetEntData(client, g_iZombieClass))
			{
				case 6: SDKCall(g_hReset, iEntity, g_flCharger, 0.0);
				case 5: SDKCall(g_hReset, iEntity, g_flJockey, 0.0);
				case 1: SDKCall(g_hReset, iEntity, g_flSmoker, 0.0);
			}
		}
	}
}

void HookEvents(EventHook EventCallback)
{
	HookEvent("jockey_ride_end", EventCallback);
	HookEvent("charger_pummel_end", EventCallback);
}

public void EventHandler (Event event, const char[] name, bool dontbroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iVctim = GetClientOfUserId(event.GetInt("victim"));
	
	if (!iClient || !iVctim)
		return;
		
	SetEntProp(iClient, Prop_Send, "m_hOwnerEntity", iVctim);
}

void SetupSDK()
{
	GameData hData = new GameData("l4d2_release_victim_data");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hCharger = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CTerrorPlayer::ReleaseTongueVictim");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hSmoker = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CTerrorPlayer::OnPounceEnded");
	g_hHunter = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CTerrorPlayer::OnRideEnded");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hJockey = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CBaseAbility::StartActivationTimer");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_hReset = EndPrepSDKCall();
	
	delete hData;
}

void SpoofEffect(float vOrigin[3])
{
	int entity = CreateEntityByName("info_particle_system");
	
	if (entity == -1)
	{
		LogError("Invalid entity");
		return;
	}
	
	DispatchKeyValue(entity, "effect_name", "gen_hit1_c");
	//fireworks_flare_trail_01
	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	ActivateEntity(entity);

	AcceptEntityInput(entity, "start");
	
	SetVariantString("OnUser1 !self:Kill::4.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}