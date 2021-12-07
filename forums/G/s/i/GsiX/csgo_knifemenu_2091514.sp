#include <sourcemod>
#include <clientprefs>
#define PLUGIN_VERSION		"1.1"
#define PLUGIN_NAME			"csgo_knifemenu"
#define PLUGIN_DESCRIPTION	"Override knife command"
#define PLUGIN_FCVAR		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define KNM_MAXLEN			16

new Handle:g_hKnifeMenuCookies, Handle:g_hKnifeSpam, Handle:g_hKnifeLoad;
new String:g_sKnifeCookies[MAXPLAYERS+1][KNM_MAXLEN];
new bool:g_bSpam, bool:g_bLoad;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "static2601",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar( "csgo_knm_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	g_hKnifeSpam = CreateConVar( "csgo_knm_announce", 		"0",	"Toggle announce knife handler", PLUGIN_FCVAR );
	g_hKnifeLoad = CreateConVar( "csgo_knm_autoloadknife",	"1",	"0:Off, 1:On, If on, knife is autoload on player spawn", PLUGIN_FCVAR );
	g_hKnifeMenuCookies = RegClientCookie( "Custom_Knife_Cookies", "CommanMenuHandler", CookieAccess_Protected );
	
	HookEvent( "player_spawn", 		KNM_EVENT_PlayerSpawn );
	HookConVarChange( g_hKnifeSpam,	KNM_CvarChanged );
	HookConVarChange( g_hKnifeLoad,	KNM_CvarChanged );
	RegConsoleCmd( "sm_knife", 		KNM_KnifeMenu );
	KNM_UpdateCvar();
}

public KNM_CvarChanged( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	KNM_UpdateCvar();
}

public Action:KNM_KnifeMenu( client, args )
{	
	new Handle:menu = CreateMenu( KNM_MenuHandler );
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

public KNM_MenuHandler( Handle:menu, MenuAction:action, client, param2 )
{
	if (action == MenuAction_Select)
	{
		decl String:info[KNM_MAXLEN];
		GetMenuItem( menu, param2, info, KNM_MAXLEN );
		if ( StrEqual( info, "Bayonet" ))
		{
			Format( info, KNM_MAXLEN, "sm_bayonet" );
			FakeClientCommand( client, info );
			if( g_bSpam ) PrintToChat( client, "Bayonet Knife Selected" );
		}
		else if ( StrEqual( info, "Gut" ))
		{
			Format( info, KNM_MAXLEN, "sm_gut" );
			FakeClientCommand( client, info );
			if( g_bSpam ) PrintToChat( client, "Gut Knife Selected" );
		}
		else if ( StrEqual( info, "Flip" ))
		{
			Format( info, KNM_MAXLEN, "sm_m9" );
			FakeClientCommand( client, info );
			if( g_bSpam ) PrintToChat( client, "Flip Knife Selected" );
		}
		else if ( StrEqual( info, "M9" ))
		{
			Format( info, KNM_MAXLEN, "sm_flip" );
			FakeClientCommand( client, info );
			if( g_bSpam ) PrintToChat( client, "M9 Bayonet Selected" );
		}
		else if (StrEqual( info, "Karambit" ))
		{
			Format( info, KNM_MAXLEN, "sm_karambit" );
			FakeClientCommand( client, info );
			if( g_bSpam ) PrintToChat( client, "Karambit Selected" );
		}
		KNM_SaveKnife( client, info );
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public KNM_EVENT_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( iClient > 0 && IsClientInGame( iClient ) && !IsFakeClient( iClient ))
	{
		if ( g_bLoad ) KNM_LoadKnife( iClient );
	}
}

KNM_UpdateCvar()
{
	g_bSpam	= GetConVarBool( g_hKnifeSpam );
	g_bLoad	= GetConVarBool( g_hKnifeSpam );
}

KNM_LoadKnife( iClient )
{
	if( AreClientCookiesCached( iClient ))
	{
		Format( g_sKnifeCookies[iClient], KNM_MAXLEN, "" );
		GetClientCookie( iClient, g_hKnifeMenuCookies, g_sKnifeCookies[iClient], sizeof( g_sKnifeCookies[] ));
		if( StrContains( g_sKnifeCookies[iClient], "sm_" ) != -1 )
			FakeClientCommand( iClient, g_sKnifeCookies[iClient] );
	}
	else
		PrintToChat( iClient, "Player %N cookies late load!!", iClient );
}

KNM_SaveKnife( iClient, const String:CommandKnife[] )
{
	if( AreClientCookiesCached( iClient ))
		SetClientCookie( iClient, g_hKnifeMenuCookies, CommandKnife );
	else
		PrintToChat( iClient, "Player %N cookies late load!!", iClient );
}


