#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

public OnPluginStart()
{
	AddCommandListener(Taunt, "+use_action_slot_item_server");
	AddCommandListener(Taunt, "use_action_slot_item_server");
}
public Action:Taunt(client, String:cmd[], args)
{
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;	
	}
	if (CheckPlayerHasShredActionTaunt(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
stock bool:CheckPlayerHasShredActionTaunt(client)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") != client || GetEntProp(i, Prop_Send, "m_bDisguiseWearable")) continue;
		new idx = GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex");
		switch (idx)
		{
			case 1015: return true;
		}
	}
	return false;
}

