#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

new bool:g_bLate; 

public Plugin:myinfo = 
{
	name = "Area Condition",
	author = "[poni] Shutterfly, Mini",
	description = "Toggles clients' condition-states while they're inside a specific trigger_multiple brush.",
	version = "1.1",
	url = "forums.alliedmodders.com"
}

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public OnMapStart()
{
	if (g_bLate)
	{
		new ent;
		while ((ent = FindEntityByClassname(-1, "trigger_multiple")) != -1)
		{
			SDKHook(ent, SDKHook_StartTouch, OnStartTouch);
			SDKHook(ent, SDKHook_EndTouch, OnEndTouch);
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!strcmp(classname, "trigger_multiple", false))
	{
		SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
		SDKHook(entity, SDKHook_EndTouch, OnEndTouch);
	}
}

public Action:OnStartTouch(entity, activator)
{
	if (IsValidEntity(activator) && IsClientInGame(activator) && IsPlayerAlive(activator))
	{
		decl String:triggerName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", triggerName, sizeof(triggerName));
		
		new String:CondVals[64][64];
		new n = ExplodeString(triggerName, " ", CondVals, sizeof(CondVals), sizeof(CondVals[])) - 1;
		
		if (StrEqual(CondVals[0], "areacond"))
		{
			for(new i=1; i<n; i++)
			{
				TF2_AddCondition(activator, TFCond:StringToInt(CondVals[i]), 999999.999999);
				if (StrEqual(CondVals[i], "41"))
				{
					new weapon = GetPlayerWeaponSlot(activator, 2);
					SetEntPropEnt(activator, Prop_Send, "m_hActiveWeapon", weapon);
				}
			}
		}
	}
}

public OnEndTouch(entity, activator)
{
	if (IsValidEntity(activator) && IsClientInGame(activator) && IsPlayerAlive(activator))
	{
		decl String:triggerName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", triggerName, sizeof(triggerName));
		
		new String:CondVals[64][64];
		new n = ExplodeString(triggerName, " ", CondVals, sizeof(CondVals), sizeof(CondVals[])) - 1;
		
		if (StrEqual(CondVals[0], "areacond"))
		{
			for(new i=1; i<n; i++)
				TF2_RemoveCondition(activator, TFCond:StringToInt(CondVals[1]));
			
		}
	}
}
