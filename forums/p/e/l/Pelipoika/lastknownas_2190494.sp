#include <clientprefs>
#include <morecolors>

new Handle:g_hClientCookie = INVALID_HANDLE;		//Name cookie

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name		= "[ANY] Last Known As",
	author		= "Pelipoika",
	description	= "Announces a clients previous name if they change names between connects",
	version		= PLUGIN_VERSION,
	url			= "http://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Pelipoika&description=&search=1"
};

public OnPluginStart()
{
	CreateConVar("lastknownas_version", PLUGIN_VERSION, "Plugin Version",  FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hClientCookie = RegClientCookie("LastKnowAs", "The last known name of a client", CookieAccess_Private);
}

public OnClientCookiesCached(client)
{
	if (IsFakeClient(client))
		return;

	decl String:sValue[MAX_NAME_LENGTH], String:sCurrentName[MAX_NAME_LENGTH];
	GetClientName(client, sCurrentName, MAX_NAME_LENGTH);
	GetClientCookie(client, g_hClientCookie, sValue, sizeof(sValue));
	
	if(!StrEqual(sValue, "", false) && !StrEqual(sCurrentName, sValue, true))
		CPrintToChatAll("{arcana}%N {default}was last known as: {ancient}%s", client, sValue);
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
		return;

	decl String:sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, MAX_NAME_LENGTH);
	SetClientCookie(client, g_hClientCookie, sName);
}