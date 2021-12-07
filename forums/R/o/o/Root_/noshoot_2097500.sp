#include <sdkhooks>
public Action:OnEnteredProtectedZone(client, const String:name[], const String:prefix[])
{
	static Handle:ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		if (StrEqual(name, "myzone", false))
		{
			if (SDKHookEx(client, SDKHook_PreThink, OnPreThink))
				if (GetConVarBool(ShowZones)) PrintToChat(client, "%sYou have entered \"%s\" zone.", prefix, name);
		}
	}
}

public Action:OnLeftProtectedZone(client, const String:name[], const String:prefix[])
{
	static Handle:ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		// It's also called whenever player dies within a zone, so dont show a message if player died there
		if (StrEqual(name, "myzone", false))
		{
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);

			if (IsPlayerAlive(client) && GetConVarBool(ShowZones))
				PrintToChat(client, "%sYou have left \"%s\" zone.", prefix, name);
		}
	}
}

public OnPreThink(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 0.5);
}