#include	<sdktools>
#include	<clientprefs>

Handle	name_storage;

public	Plugin	myinfo	=	{
	name		=	"[ANY] Keep Player Name",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Stores the player name to make sure player stays within the same name",
	version		=	"1.0.0",
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

public	void	OnPluginStart()	{
	name_storage	=	RegClientCookie("keep_player_name",	"Keeps The Players Name",	CookieAccess_Private);
	HookEvent("player_changename",	Event_PlayerNameChange);
}

public	void	OnClientCookiesCached(int client)	{
	cookies(client);
}

public	void	OnClientPutInServer(int client)	{
	cookies(client);
}

void	cookies(int client)	{
	if(IsClientInGame(client) && !IsFakeClient(client))	{
		char	cookie		[256],
				clientname	[256];
		GetClientCookie(client,	name_storage,	cookie,	sizeof(cookie));
		GetClientName(client,	clientname,	sizeof(clientname));
		if(StrEqual(cookie,	""))
			SetClientCookie(client,	name_storage,	clientname);
		else if(!StrEqual(cookie,	""))
			SetClientName(client,	cookie);
	}
}

Action	Event_PlayerNameChange(Event event,	const char[] name,	bool dontBroadcast)	{
	return	Plugin_Handled;
}