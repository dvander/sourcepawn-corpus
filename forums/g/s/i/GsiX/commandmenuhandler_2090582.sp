#include <sourcemod>
#include <clientprefs>

new Handle:g_hKnifeMenuCookies;
new String:g_sKnifeCookies[MAXPLAYERS+1][24];

public Plugin:myinfo = 
{
	name = "Command Menu Handler",
	author = "static2601",
	description = "Commands in menu",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent( "player_spawn", Bla_EVENT_PlayerSpawn );
	g_hKnifeMenuCookies = RegClientCookie( "Custom_Knife_Cookies", "CommanMenuHandler", CookieAccess_Protected );
	RegConsoleCmd("sm_knife", KnifeMenu);
}

public Action:KnifeMenu(client, args)
{	
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuTitle(menu, "Select A Knife");
	AddMenuItem(menu, "Bayonet", "Bayonet Knife");
	AddMenuItem(menu, "Gut", "Gut Knife");
	AddMenuItem(menu, "Flip", "Flip Knife");
	AddMenuItem(menu, "M9", "M9 Bayonet");
	AddMenuItem(menu, "Karambit", "Karambit");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;

}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info, "Bayonet"))
		{
			Format( info, sizeof( info ), "say !bayonet" );
			PrintToChat(client, "Bayonet Knife Selected");
			FakeClientCommand(client, info );
		}
		else if (StrEqual(info, "Gut"))
		{
			Format( info, sizeof( info ), "say !gut" );
			PrintToChat(client, "Gut Knife Selected");
			FakeClientCommand(client, info );
		}
		else if (StrEqual(info, "Flip"))
		{
			Format( info, sizeof( info ), "say !m9" );
			PrintToChat(client, "Flip Knife Selected");
			FakeClientCommand(client, info );
		}
		else if (StrEqual(info, "M9"))
		{
			Format( info, sizeof( info ), "say !flip" );
			PrintToChat(client, "M9 Bayonet Selected");
			FakeClientCommand(client, info );
		}
		else if (StrEqual(info, "Karambit"))
		{
			Format( info, sizeof( info ), "say !karambit" );
			PrintToChat(client, "Karambit Selected");
			FakeClientCommand(client, info );
		}
		SaveKnife( client, info );
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Bla_EVENT_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( iClient > 0 && IsClientInGame( iClient ) && !IsFakeClient( iClient ))
		LoadKnife( iClient );
}

LoadKnife( iClient )
{
	if( AreClientCookiesCached( iClient ))
	{
		GetClientCookie( iClient, g_hKnifeMenuCookies, g_sKnifeCookies[iClient], sizeof( g_sKnifeCookies[] ));
		FakeClientCommand( iClient, g_sKnifeCookies[iClient] );
	}
	else
		PrintToChat( iClient, "Player %N cookies late load!!", iClient );
}

SaveKnife( iClient, const String:CommandKnife[] )
{
	if( AreClientCookiesCached( iClient ))
		SetClientCookie( iClient, g_hKnifeMenuCookies, CommandKnife );
	else
		PrintToChat( iClient, "Player %N cookies late load!!", iClient );
}
