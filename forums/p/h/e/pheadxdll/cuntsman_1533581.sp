#include <sourcemod>

#define DEF_HUNTSMAN 56

new g_iOffsetOwner;
new g_iOffsetDef;

public OnPluginStart()
{
	g_iOffsetOwner = FindSendPropOffs("CBasePlayer", "m_hActiveWeapon");
	if(g_iOffsetOwner <= 0)
	{
		SetFailState("Could not locate offset for: %s!", "CBasePlayer::m_hActiveWeapon");
		return;
	}
	g_iOffsetDef = FindSendPropInfo("CBaseCombatWeapon", "m_iItemDefinitionIndex");
	if(g_iOffsetDef <= 0)
	{
		SetFailState("Could not locate offset for: %s!", "CBaseCombatWeapon::m_iItemDefinitionIndex");
		return;
	}
	
	AddCommandListener(Listener_Taunt, "taunt");
}

public Action:Listener_Taunt(client, const String:command[], argc)
{
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new iWeapon = GetActiveWeapon(client);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon) && GetItemDefinition(iWeapon) == DEF_HUNTSMAN)
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

GetItemDefinition(weapon)
{
	return GetEntData(weapon, g_iOffsetDef);
}

GetActiveWeapon(client)
{
	return GetEntDataEnt2(client, g_iOffsetOwner);
}