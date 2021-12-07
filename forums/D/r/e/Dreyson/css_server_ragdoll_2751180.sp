#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sourcescramble>

#define MAX 32

public Plugin myinfo =
{
	name = "[CSS] Server Side Ragdolls",
	author = "Dreyson",
	description = "Creates server side ragdolls on death",
	version = "0.2",
	url = ""
};

Handle g_hRagdoll;
ConVar sm_side_dolls_remove_body;
ConVar sm_side_dolls_limit_bodys;
bool g_bInvisible;
bool g_bRemove;

int g_iRagdolls[MAX];
MemoryBlock memory;

public void OnPluginStart()
{
	memory = new MemoryBlock(0x4C);
	
	
	sm_side_dolls_remove_body 			= CreateConVar("sm_side_dolls_remove_body"			, "1");
	sm_side_dolls_limit_bodys = CreateConVar("sm_side_dolls_limit_bodys", "1");
	
	sm_side_dolls_remove_body.AddChangeHook(OnConVarChanged);
	sm_side_dolls_limit_bodys.AddChangeHook(OnConVarChanged);
	
	g_bInvisible = sm_side_dolls_remove_body.BoolValue;
	g_bRemove = sm_side_dolls_limit_bodys.BoolValue;
	
	AutoExecConfig(true, "server_side_ragdolls");
	
	Handle hData = LoadGameConfigFile("css_side_dolls");
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CreateServerRagdoll");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hRagdoll = EndPrepSDKCall();		
	
	delete hData;

	HookEvent("player_death", player_death, EventHookMode_Pre);

}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bRemove = sm_side_dolls_limit_bodys.BoolValue;
	g_bInvisible = sm_side_dolls_remove_body.BoolValue;
}



public void player_death(Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	// if (!client || GetClientTeam(client) != 2)
	if (!client || GetClientTeam(client) <= 1)
		return;
	
	int _iEntity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
		if(_iEntity > 0 && IsValidEdict(_iEntity))
		{
		
if(g_bInvisible)
AcceptEntityInput(_iEntity, "Kill");


         }
         
	int entity = SDKCall(g_hRagdoll, client, GetEntProp(client, Prop_Send, "m_nForceBone"), memory.Address, 3, true);
	
	if (g_bRemove)
	{
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		g_iRagdolls[GetIndex()] = EntIndexToEntRef(entity);
	}
}




int GetIndex (int client = -1)
{
	int entity;
	
	if (client != -1)
	{
		for (int i; i < MAX; i++)
		{
			if ((entity = EntRefToEntIndex(g_iRagdolls[i])) <= 0 || !IsValidEntity(entity))
				continue;
				
			if (client == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))
			{
				g_iRagdolls[i] = 0;
				return entity;
			}
		}
		
		return -1;
	}
	
	for (int i; i < MAX; i++)
	{
		if ((entity = EntRefToEntIndex(g_iRagdolls[i])) > 0 && IsValidEntity(entity))
			continue;
			
		return i;
	}
	
	return -1;
}