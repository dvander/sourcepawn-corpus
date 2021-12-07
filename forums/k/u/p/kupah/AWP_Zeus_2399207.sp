#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	RegConsoleCmd("sm_awp", Command_deagle, "Spawn AWP with Zeus bullets");
}

public Action Command_deagle(int client, int args)
{
	if (IsClientConnected(client) && IsPlayerAlive(client))
	{
		int Awp = CreateEntityByName("weapon_taser");
		SetEntProp(Awp, Prop_Send, "m_iItemDefinitionIndex", 9);
		DispatchSpawn(Awp);
		EquipPlayerWeapon(client, Awp);
	}
}