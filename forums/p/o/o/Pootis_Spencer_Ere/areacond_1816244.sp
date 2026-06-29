#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "Area Condition",
	author = "[poni] Shutterfly",
	description = "Toggles clients' condition-states while they're inside a specific trigger_multiple brush.",
	version = "1.0",
	url = "forums.alliedmodders.com"
}

public OnPluginStart()
{
	HookEntityOutput("trigger_multiple", "OnStartTouch", OnStartTouch);
	HookEntityOutput("trigger_multiple", "OnEndTouch", OnEndTouch);
}

public OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if (IsValidEntity(activator) && IsClientInGame(activator) && IsPlayerAlive(activator))
	{
		decl String:triggerName[64];
		GetEntPropString(caller, Prop_Data, "m_iName", triggerName, sizeof(triggerName));
		
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

public OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if (IsValidEntity(activator) && IsClientInGame(activator) && IsPlayerAlive(activator))
	{
		decl String:triggerName[64];
		GetEntPropString(caller, Prop_Data, "m_iName", triggerName, sizeof(triggerName));
		
		new String:CondVals[64][64];
		new n = ExplodeString(triggerName, " ", CondVals, sizeof(CondVals), sizeof(CondVals[])) - 1;
		
		if (StrEqual(CondVals[0], "areacond"))
		{
			for(new i=1; i<n; i++)
				TF2_RemoveCondition(activator, TFCond:StringToInt(CondVals[1]));
			
		}
	}
}
