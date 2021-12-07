


#include <csgo_items>

public OnPluginStart()
{
	RegConsoleCmd("sm_test", test);
}

public Action:test(client, args)
{
	if(client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	new entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if(entity == -1)
	{
		return Plugin_Handled;
	}

	new iItemDefinitionIndex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

	new String:buffer[128];
	CSGO_GetItemDefinitionNameByIndex(iItemDefinitionIndex, buffer, sizeof(buffer));
	PrintToChat(client, "iItemDefinitionIndex %i = CSGO_GetItemDefinitionNameByIndex string %s", iItemDefinitionIndex, buffer);


	new value = CSGO_GetItemDefinitionIndexByName("weapon_sawedoff");
	PrintToServer("CSGO_GetItemDefinitionIndexByName(\"weapon_sawedoff\") = %i", value);
	return Plugin_Handled;
}