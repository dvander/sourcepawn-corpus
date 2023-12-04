#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D] Ladder Creator (prototype)",
	author = "Dragokas",
	description = "Creates additional ladders on the map",
	version = "1.0 alpha",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_freeze_end", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
}

public void Event_RoundFreezeEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	static char szMapName[64];
	int entity = -1;
	char modelname[128];
	
	GetCurrentMap(szMapName, sizeof(szMapName));

	if (StrContains(szMapName, "l4d_hospital05_rooftop", false) != -1)
	{
		// change team of default game ladder
		while (-1 != (entity = FindEntityByClassname(entity, "func_simpleladder")))
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof modelname);
			if (strcmp(modelname, "*25") == 0)
			{
				SetEntProp(entity, Prop_Send, "m_iTeamNum", 0);
				break;
			}
		}
		
		// "expand" ladder altitude by cloning
		PrecacheModel("*25", true);
		entity = CreateEntityByName("func_simpleladder");
		if (entity == -1)
		{
			return;
		}
		DispatchKeyValue(entity, "model", "*25");
		DispatchKeyValue(entity, "normal.z", "0.00");
		DispatchKeyValue(entity, "normal.y", "1.00");
		DispatchKeyValue(entity, "normal.x", "0.00");
		DispatchKeyValue(entity, "team", "0");
		DispatchKeyValue(entity, "origin", "0 0 -3095.0");
		DispatchKeyValue(entity, "angles", "0 0 0");

		DispatchSpawn(entity);
		
		// *25 model has y = 2562.0 dimension. So it is not fully cover all altitude requires,
		// so need to clone once more.
		
		entity = CreateEntityByName("func_simpleladder");
		if (entity == -1)
		{
			return;
		}
		DispatchKeyValue(entity, "model", "*25");
		DispatchKeyValue(entity, "normal.z", "0.00");
		DispatchKeyValue(entity, "normal.y", "1.00");
		DispatchKeyValue(entity, "normal.x", "0.00");
		DispatchKeyValue(entity, "team", "0");
		DispatchKeyValue(entity, "origin", "0 0 -2095.0");
		DispatchKeyValue(entity, "angles", "0 0 0");

		DispatchSpawn(entity);
	}
	else if (StrContains(szMapName, "l4d_airport01_greenhouse", false) != -1)
	{
		// create ladder next to caravan to be able to find way from dead zone
		PrecacheModel("*32", true);
		entity = CreateEntityByName("func_simpleladder");
		if (entity == -1)
		{
			return;
		}
		DispatchKeyValue(entity, "model", "*32");
		DispatchKeyValue(entity, "normal.z", "0.00");
		DispatchKeyValue(entity, "normal.y", "-1.00");
		DispatchKeyValue(entity, "normal.x", "0.00");
		DispatchKeyValue(entity, "team", "0");
		DispatchKeyValue(entity, "origin", "1974,49 2795,24 -501,00");
		DispatchKeyValue(entity, "angles", "0 0 0");
		
		DispatchSpawn(entity);

		// prevents player stuck between wall and caravan
		/*
		entity = CreateEntityByName("env_player_blocker");
		
		if (entity == -1)
		{
			return;
		}
		
		float mins[3] = {3665.0, 2578.0, 8.0};
		float maxs[3] = {4084.0, 2774.0, 246.0};
		
		DispatchKeyValue(entity, "targetname", "@env_player_blocker");
		DispatchKeyValue(entity, "BlockType", "1");
		DispatchKeyValue(entity, "Blocks", "1");
		DispatchKeyValue(entity, "InitialState", "1");
		DispatchKeyValueVector(entity, "origin", view_as<float>({0.0, 0.0, 0.0}));
		DispatchKeyValueVector(entity, "Mins", mins);
		DispatchKeyValueVector(entity, "Maxs", maxs);
		DispatchSpawn(entity);
		
		SetEntPropVector(entity, Prop_Data, "m_vecMins", mins);
		SetEntPropVector(entity, Prop_Data, "m_vecMaxs", maxs);
		
		SetEntPropVector(entity, Prop_Data, "m_vecSurroundingMins", mins);
		SetEntPropVector(entity, Prop_Data, "m_vecSurroundingMaxs", maxs);
		
		AcceptEntityInput(entity, "Enable");
		*/
		
	}
}
