#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	RegConsoleCmd("sm_deagle", Command_deagle, "Spawn Deagle with Awp Properties");
}

public Action Command_deagle(int client, int args)
{
	if (IsClientConnected(client) && IsPlayerAlive(client))
	{
		new DeagleAwp;
		DeagleAwp = CreateEntityByName("weapon_deagle");
		SetEntProp(DeagleAwp, Prop_Send, "m_iItemDefinitionIndex", 9);
		DispatchSpawn(DeagleAwp);
		EquipPlayerWeapon(client, DeagleAwp);
	}
}