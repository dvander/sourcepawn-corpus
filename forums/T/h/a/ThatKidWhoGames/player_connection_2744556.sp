#include <sourcemod>
#include <geoip>

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if (!IsFakeClient(iClient))
	{
		char sIP[32], sCountry[45];
		GetClientIP(iClient, sIP, sizeof(sIP));
		GeoipCountry(sIP, sCountry, sizeof(sCountry));

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
			{
				PrintToChat(i, "[SM] Player: %N\n[SM] SteamID: %s\n[SM] IP: %s\n[SM] Country: %s", iClient, sAuth, sIP, sCountry);
			}
		}
	}
}