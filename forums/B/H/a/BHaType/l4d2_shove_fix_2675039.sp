#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "[L4D2] Shove Dir Fix",
	author = "BHaType",
	description = "Fixes shove",
	version = "0.1",
	url = "N/A"
}

Handle g_hReset;

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile("l4d2_shove_fix");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "ResetEntityState");
	g_hReset = EndPrepSDKCall();		

	delete hGamedata;
	
	HookEvent("entity_shoved", eEvent);
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{	
	int client = GetClientOfUserId(event.GetInt("attacker"));
	int entity = event.GetInt("entityid");
	
	if (entity <= MaxClients || entity > 2048 || client <= 0)
		return;
	
	char szName[36];
	GetEntityClassname(entity, szName, sizeof szName);
	
	if (strcmp(szName, "infected") == 0)
	{
		int index = GetEntProp(entity, Prop_Data, "m_iHealth");
	
		if (index <= 1)
		{
			SDKHooks_TakeDamage(entity, client, client, 666.666, DMG_BLAST);
			return;
		}
		
		SDKCall(g_hReset, entity);
		SetEntProp(entity, Prop_Send, "m_nSequence", 1);
		SetEntPropFloat(entity, Prop_Data, "m_flCycle", 1.0);
		
		DataPack dPack;
		
		// Dont ask me 
		CreateDataTimer(0.08099996692352168753182763521876539546387561293452167352197635123678125317623518549426, tTimer, dPack, TIMER_DATA_HNDL_CLOSE); 
		
		dPack.WriteCell(GetClientUserId(client));
		dPack.WriteCell(EntIndexToEntRef(entity));
	}
}

public Action tTimer (Handle timer, DataPack dPack)
{
	dPack.Reset();
	
	int client = GetClientOfUserId(dPack.ReadCell()), entity = EntRefToEntIndex(dPack.ReadCell());
	
	if (client <= 0 || entity <= MaxClients || !IsClientInGame(client))
		return;
	
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	
	SDKHooks_TakeDamage(entity, client, client, 0.000, DMG_BLAST, -1, NULL_VECTOR, vOrigin);
	SDKHooks_TakeDamage(entity, client, client, 0.0001, DMG_BUCKSHOT, -1, NULL_VECTOR, vOrigin);
}