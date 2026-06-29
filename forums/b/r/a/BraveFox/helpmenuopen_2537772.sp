#include <sourcemod>
#include <clientprefs>
Handle IsNewCookies;
public Plugin myinfo = 
{
	name = "[Any]Auto Helpmenu Open For New Players",
	author = "S4muRaY'",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/bravefox"
};

public void OnPluginStart()
{
	IsNewCookies = RegClientCookie("IsNewCookies", "No Description", CookieAccess_Private); 
}
public void OnClientCookiesCached(int client)
{
	char cookies[64];
	GetClientCookie(client, IsNewCookies, cookies, sizeof(cookies));
	if(StrEqual(cookies, "false"))
	{
		//Do nothing
	} else {
		FakeClientCommand(client, "sm_helpmenu");
		SetClientCookie(client, IsNewCookies, "false");
	}
}
stock bool IsValidClient(int client)
{
	if(client > MaxClients)
		return false;
	if(client <= 0)
		return false;
	if(!IsClientConnected(client))
		return false;
	return IsClientInGame(client);
}