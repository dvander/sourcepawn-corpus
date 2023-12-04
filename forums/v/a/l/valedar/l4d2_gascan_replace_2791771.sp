#pragma semicolon 1
#pragma newdecls required

#include <sdktools_entinput>
#include <sdktools_functions>

public Plugin myinfo = 
{
	name = "[L4D2] Gascan Replace",
	author = "Vitamin",
	description = "Replace prop_physics Entity to weapon_gascan",
	version = "1.0",
	url = "https://steamcommunity.com/id/vitamin4107/"
};

public void OnPluginStart()
{
	HookEvent("round_freeze_end", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
}

public void Event_RoundFreezeEnd(Event event, char[] name, bool dontBroadcast)
{
	char szModel[36];
	float vOrigin[3];
	float vAngles[3];
	int iGasCan = -1;
	int iEntity = -1;
	
	while ((iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1)
	{
		GetEntPropString(iEntity, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
		if (strcmp(szModel, "models/props_junk/gascan001a.mdl", false) != 0)
		{
			continue;
		}
		
		iGasCan = CreateEntityByName("weapon_gascan");
		if (iGasCan == -1)
		{
			return;
		}

		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vOrigin);
		GetEntPropVector(iEntity, Prop_Send, "m_angRotation", vAngles);
		
		AcceptEntityInput(iEntity, "Kill");
		
		DispatchKeyValueVector(iGasCan, "origin", vOrigin);
		DispatchKeyValueVector(iGasCan, "angles", vAngles);
		
		DispatchSpawn(iGasCan);
	}
}