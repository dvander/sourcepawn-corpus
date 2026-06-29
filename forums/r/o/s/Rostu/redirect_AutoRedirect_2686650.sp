
#include <server_redirect>

public Plugin myinfo = 
{
	name		= "[Redirect Module] Auto Redirect",
	author		= "Rostu",
	version		= "1.2",
	url			= "https://vk.com/id226205458 | Discord: Rostu#7917"
};

char g_sServerIP[24];

int g_iFlags;

ConVar g_hRedirect;
ConVar g_hPlayersCount;
ConVar g_hAdminFlag;

public void OnPluginStart()
{
	(g_hRedirect = CreateConVar("sm_redirect_server", "192.168.0.1:27015", "server ip to which the player will automatically redirected")).AddChangeHook(Change_);
	(g_hPlayersCount = CreateConVar("sm_redirect_maxplayers", "0", "After how many players do redirect to another server. 0 - auto redirect", _, true, 0.0, true, 64.0)).AddChangeHook(Change_);
	(g_hAdminFlag = CreateConVar("sm_redirect_admin", "a", "Flag of ignoring administrator redirection to another server")).AddChangeHook(Change_);

	AutoExecConfig(true, "AutoRedirect");
}
public void Change_ (ConVar convar, const char[] oldValue, const char[] newValue)
{
	ParseRedirectIP();
}
public void OnConfigsExecuted()
{
	ParseRedirectIP();
}
void ParseRedirectIP()
{
	g_hRedirect.GetString(g_sServerIP, sizeof g_sServerIP);

	char sBuffer[24];
	g_hAdminFlag.GetString(sBuffer, sizeof sBuffer);
	g_iFlags = ReadFlagString(sBuffer);
}
bool CheckToNeededRedirect(int iClient = 0)
{
	if(!g_hPlayersCount.IntValue)
	{
		return true;
	}

	int iCount;

	for(int i = 1; i <= MaxClients; ++i) 
    { 
        if (iClient != i && IsClientConnected(i) && !IsClientInKickQueue(i) && !IsClientSourceTV(i) && !IsFakeClient(i)) 
        {
			iCount++;
        } 
    }

	return (iCount >= g_hPlayersCount.IntValue);
}
public bool OnClientConnect(int iClient, char[] rejectmsg, int maxlen)
{
	if(!g_iFlags && CheckToNeededRedirect())
	{
		RedirectClient(iClient, g_sServerIP);
	}
	return true;
}
public void OnClientPostAdminCheck(int iClient)
{
	if(!g_iFlags)
	{
		return;
	}

	if(CheckToNeededRedirect(iClient))
	{
		AdminId admin = GetUserAdmin(iClient);

		if(admin != INVALID_ADMIN_ID && ((admin.GetFlags(Access_Effective) & g_iFlags)|| (admin.GetFlags(Access_Effective) & ADMFLAG_ROOT)))
		{
			return;
		}

		RedirectClient(iClient, g_sServerIP);
	}
}