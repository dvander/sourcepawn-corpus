#include <sourcemod>
#include <basecomm>

public Plugin:myinfo =
{
	name = "Silence Unauthenticated Players",
	author = "allienaded",
	description = "Blocks chat and voice from unauthenticated players.",
	version = "1.0"
};

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
		return;

	if (client && !IsClientAuthorized(client))
	{
		BaseComm_SetClientGag(client, true);
		BaseComm_SetClientMute(client, true);
	}

	return;
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client))
		return;

	BaseComm_SetClientGag(client, false);
	BaseComm_SetClientMute(client, false);

	return;
}