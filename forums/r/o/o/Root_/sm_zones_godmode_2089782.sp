public Plugin:myinfo =
{
	name        = "SM Zones God Mode",
	author      = "Root",
	description = "Enables/disables God Mode when player enteres or leaves a zone",
	version     = "1.0",
	url         = "http://www.dodsplugins.com/"
}

public Action:OnEnteredProtectedZone(client, const String:prefix[])
{
	static Handle:ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		ServerCommand("sm_god #%i 1", GetClientUserId(client))
		if (GetConVarBool(ShowZones))
		{
			PrintToChat(client, "%sYou have entered buddha zone. God Mode is enabled!", prefix);
		}
	}
}

public Action:OnLeftProtectedZone(client, const String:prefix[])
{
	static Handle:ShowZones   = INVALID_HANDLE;
	if (!ShowZones) ShowZones = FindConVar("sm_zones_show_messages");

	if (1 <= client <= MaxClients)
	{
		ServerCommand("sm_god #%i 0", GetClientUserId(client))

		// It's also called whenever player dies within a zone, so dont show a message if player died there
		if (GetConVarBool(ShowZones) && IsPlayerAlive(client))
		{
			PrintToChat(client, "%sYou have left buddha zone. God mode is disabled!", prefix);
		}
	}
}