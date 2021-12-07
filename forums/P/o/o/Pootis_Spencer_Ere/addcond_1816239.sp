#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "Add Condition",
	author = "Panzer",
	description = "Lets you set player's conditions through triggers",
	version = "1.0",
	url = "forums.alliedmodders.com"
}

public OnPluginStart()
{
	HookEntityOutput("trigger_multiple", "OnTrigger", OnTrigger);
}

public OnTrigger(const String:output[], caller, activator, Float:delay)
{
	if (IsValidEntity(activator) && IsClientInGame(activator) && IsPlayerAlive(activator))
	{
		decl String:triggerName[64];
		GetEntPropString(caller, Prop_Data, "m_iName", triggerName, sizeof(triggerName));
		
		new String:addCondVals[4][32];
		ExplodeString(triggerName, " ", addCondVals, sizeof(addCondVals), sizeof(addCondVals[]));
		
		if (StrEqual(addCondVals[0], "addcond"))
		{
			TF2_AddCondition(activator, StringToInt(addCondVals[1]), StringToFloat(addCondVals[2]));
			if (StrEqual(addCondVals[1], "41"))
			{
				new weapon = GetPlayerWeaponSlot(activator, 2);
				SetEntPropEnt(activator, Prop_Send, "m_hActiveWeapon", weapon);
			}
		}
		else if (StrEqual(addCondVals[0], "removecond"))
			TF2_RemoveCondition(activator, StringToInt(addCondVals[1]));
	}
}
