#include <sdkhooks>
public Action:OnEnteredProtectedZone(client, const String:name[])
{
	static Handle:ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		if (StrEqual(name, "test", false))
		{
			if (SDKHookEx(client, SDKHook_PreThink, OnPreThink))
				if (GetConVarBool(ShowZones)) PrintToChat(client, "You have entered \"%s\" zone.", name);
		}
	}
}

public Action:OnLeftProtectedZone(client, const String:name[])
{
	static Handle:ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		// It's also called whenever player dies within a zone, so dont show a message if player died there
		if (StrEqual(name, "test", false))
		{
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);

			if (IsPlayerAlive(client) && GetConVarBool(ShowZones))
				PrintToChat(client, "You have left \"%s\" zone.", name);
		}
	}
}

public OnPreThink(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 0.5);
}