#include <sourcemod>
#include <clientprefs>
#define PLUGIN_VERSION		"1.2"
#define PLUGIN_NAME			"csgo_knifemenu"
#define PLUGIN_DESCRIPTION	"Override knife command"
#define PLUGIN_FCVAR		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define KNM_MAXLEN			16

new Handle:g_hKnifeMenuCookies, Handle:g_hKnifeSpam, Handle:g_hKnifeLoad;
new bool:g_bSpam, bool:g_bLoad;
new g_iSelection[MAXPLAYERS+1][2];

static const String:g_sMenuList[5][KNM_MAXLEN] =
{
	"sm_bayonet",
	"sm_gut",
	"sm_m9",
	"sm_flip",
	"sm_karambit"
};

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
	decl String:buff[KNM_MAXLEN];
	if( AreClientCookiesCached( client ))
	{
		if ( KNM_LoadClientSetting( client ))
		{
			switch( g_iSelection[client][1] )
			{
				case 0: { Format( buff, sizeof( buff ), "AutoLoad | Disabled" ); }
				case 1: { Format( buff, sizeof( buff ), "AutoLoad | Enabled" ); }
			}
		}
	}
	else PrintToChat( client, "Player %N loading, cookies late load!!", client );
	
	new Handle:knm_menu = CreateMenu( KNM_MenuHandler );
	SetMenuPagination( knm_menu, MENU_NO_PAGINATION );
	SetMenuTitle( knm_menu,	"Select A Knife");
	AddMenuItem( knm_menu,	"Bayonet",	"Bayonet Knife" );
	AddMenuItem( knm_menu,	"Gut",		"Gut Knife" );
	AddMenuItem( knm_menu,	"Flip",		"Flip Knife" );
	AddMenuItem( knm_menu,	"M9",		"M9 Bayonet" );
	AddMenuItem( knm_menu,	"Karambit",	"Karambit" );
	AddMenuItem( knm_menu,	"AutoLoad",	buff );
	
	SetMenuExitButton( knm_menu, true );
	DisplayMenu( knm_menu, client, 20 );
	return Plugin_Handled;
}

public KNM_MenuHandler( Handle:menu, MenuAction:action, client, param2 )
{
	if (action == MenuAction_Select)
	{
		decl String:info[KNM_MAXLEN];
		GetMenuItem( menu, param2, info, KNM_MAXLEN );
		if( param2 < 5 )
		{
			g_iSelection[client][0] = param2;
			FakeClientCommand( client, g_sMenuList[param2] );
			if( g_bSpam )
				PrintToChat( client, "[SM]: %s Knife Selected", info );
		}
		else
		{
			if( g_iSelection[client][1] == 0 )
			{
				g_iSelection[client][1] = 1;
				PrintToChat( client, "[SM]: Auto load knife Enabled..!!" );
			}
			else
			{
				g_iSelection[client][1] = 0;
				PrintToChat( client, "[SM]: Auto load knife Disabled..!!" );
			}
		}
		KNM_SaveKnife( client );
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
	g_bLoad	= GetConVarBool( g_hKnifeLoad );
}

KNM_LoadKnife( iClient )
{
	if( AreClientCookiesCached( iClient ))
	{
		if ( KNM_LoadClientSetting( iClient ))
		{
			if ( g_iSelection[iClient][1] == 1 )
			{
				new iBuff = g_iSelection[iClient][0];
				FakeClientCommand( iClient, g_sMenuList[iBuff] );
			}
		}
	}
	else
		PrintToChat( iClient, "[SM]: Player %N loading, cookies late load!!", iClient );
}

KNM_SaveKnife( iClient )
{
	if( AreClientCookiesCached( iClient ))
	{
		decl String:CommandBuffer[KNM_MAXLEN];
		Format( CommandBuffer, sizeof( CommandBuffer ), "%d %d", g_iSelection[iClient][0], g_iSelection[iClient][1] );
		SetClientCookie( iClient, g_hKnifeMenuCookies, CommandBuffer );
	}
	else
		PrintToChat( iClient, "[SM]: Player %N saving, cookies late load!!", iClient );
}

bool:KNM_LoadClientSetting( iClient )
{
	new String:sBuffer[KNM_MAXLEN], String:sBuffer_2[2][KNM_MAXLEN];
	
	GetClientCookie( iClient, g_hKnifeMenuCookies, sBuffer, KNM_MAXLEN );
	ExplodeString( sBuffer, " ", sBuffer_2, sizeof( sBuffer_2 ), KNM_MAXLEN );
	if ( !StrEqual( sBuffer_2[0], " " ))
	{
		g_iSelection[iClient][0] = StringToInt( sBuffer_2[0] );
		g_iSelection[iClient][1] = StringToInt( sBuffer_2[1] );
		return true;
	}
	else
		PrintToChat( iClient, "[SM]: Type !knife for first time user..!!" );
		
	return false;
}

