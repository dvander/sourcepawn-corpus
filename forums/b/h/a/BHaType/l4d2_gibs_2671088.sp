#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MODEL "models/gibs/hgibs.mdl"

Handle g_hCreateGib, g_hSpawnGib, g_hInitGibs, g_hLookupAttachment, g_hGetAttachment;

public Plugin myinfo = 
{
	name = "[L4D2] Gibs",
	author = "BHaType",
	description = "If you kill an ordinary infected person in the head the skull will fly out",
	version = "0.0",
	url = "SDKCall"
};

public void OnPluginStart()
{
	Handle hData = LoadGameConfigFile("l4d2_gibs");
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "_CreateEntity");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hCreateGib = EndPrepSDKCall();	
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CGib::Spawn");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSpawnGib = EndPrepSDKCall();	
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CGib::InitGib");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	g_hInitGibs = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CBaseAnimating::LookupAttachment");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hLookupAttachment = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CBaseAnimating::GetAttachment");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	g_hGetAttachment = EndPrepSDKCall();
	
	HookEvent("player_death", eEvent);
}

public void OnMapStart()
{
	PrecacheModel(MODEL, true);
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	int entity = event.GetInt("entityid");
	
	if (entity <= MaxClients || !event.GetBool("headshot"))
		return;
		
	int client = GetClientOfUserId(event.GetInt("attacker"));
	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;
	
	int iGib = SDKCall(g_hCreateGib, "gib", -1, 1);
	SDKCall(g_hSpawnGib, iGib, MODEL);
	SetEntProp(iGib, Prop_Data, "m_nBody", 2);
	SDKCall(g_hInitGibs, iGib, client, 300.0, 400.0);

	SetEntProp(iGib, Prop_Data, "m_nSolidType", 2);
	SetEntProp(iGib, Prop_Send, "m_CollisionGroup", 1);
	
	float vAngles[3], vVec[3], vOrigin[3], vAng[3];
	
	int iAttachment = SDKCall(g_hLookupAttachment, entity, "forward");
	
	if (iAttachment == -1)
		return;
	
	SDKCall(g_hGetAttachment, entity, iAttachment, vOrigin, vAng);
	
	vOrigin[2] += 2.5;
	
	GetClientEyeAngles(client, vAngles);
	
	GetAngleVectors(vAngles, vVec, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vVec, GetRandomFloat(300.0, 600.0));
	
	TeleportEntity(iGib, vOrigin, NULL_VECTOR, vVec);
}