#include <sourcemod>
#include "CBaseServer.inc"

enum KickType
{
	Kick_HighestPing,
	Kick_HighestTime,
	Kick_Random,
};

new g_maxClients;

public OnMapStart()
{
	g_maxClients = GetMaxClients();
}

public OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[])
{
	if (GetClientCount(false) < g_maxClients)
	{
		return;
	}

	new AdminId:admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);

	if (admin == INVALID_ADMIN_ID)
	{
		return;
	}

	if (GetAdminFlag(admin, Admin_Reservation))
	{
		new target = SelectKickClient();

		if (target)
		{
			KickClientEx(target, "Slot Reserved");
		}
	}
}

SelectKickClient()
{
	new KickType:type = Kick_HighestPing;

	new Float:highestValue;
	new highestValueId;

	new Float:highestSpecValue;
	new highestSpecValueId;

	new bool:specFound;

	new Float:value;

	new maxclients = GetMaxClients();

	for (new i=1; i<=maxclients; i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}

		new flags = GetUserFlagBits(i);

		if (IsFakeClient(i) || flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || CheckCommandAccess(i, "sm_reskick_immunity", ADMFLAG_RESERVATION, false))
		{
			continue;
		}

		value = 0.0;

		if (IsClientInGame(i))
		{
			if (type == Kick_HighestPing)
			{
				value = GetClientAvgLatency(i, NetFlow_Outgoing);
			}
			else if (type == Kick_HighestTime)
			{
				value = GetClientTime(i);
			}
			else
			{
				value = GetRandomFloat(0.0, 100.0);
			}

			if (IsClientObserver(i))
			{
				specFound = true;

				if (value > highestSpecValue)
				{
					highestSpecValue = value;
					highestSpecValueId = i;
				}
			}
		}

		if (value >= highestValue)
		{
			highestValue = value;
			highestValueId = i;
		}
	}

	if (specFound)
	{
		return highestSpecValueId;
	}

	return highestValueId;
}