#pragma semicolon 1

#define PLUGIN_VERSION "1.1.0"

#include <sdktools>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <filesmanagementinterface>

new Handle:g_hEnable;
new Handle:g_hSoundFolder;
new bool:g_bCanPlaySounds;
new String:g_szSoundFolderPath[ 256 ];
new bool:g_bLibraryIsPresent;

new Handle:g_hCookie; //nom nom nom
new g_iDefaultCookieValue;

new g_iCookieValue[ MAXPLAYERS + 1 ];

new bool:g_bJoinedAtTeamYet[ MAXPLAYERS + 1 ];

new bool:g_bSoundPlayed[ MAXPLAYERS + 1 ];
new String:g_szPathSound[ MAXPLAYERS + 1 ][ 256 ];

public Plugin:myinfo =
{
	name = "Random Join Sound",
	author = "RedSword / Bob Le Ponge",
	description = "Play a random sound to clients that connect",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	//CVARs
	CreateConVar("randomjoinsoundversion", PLUGIN_VERSION, "Random Join Sound version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);
	
	g_hEnable = CreateConVar("sm_join_sound_enable", "1.0", "If the join sound plugin is enabled. 1=Yes", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hSoundFolder = CreateConVar("sm_join_sound", "sound/joinsounds", "The sound folder where to take a sound to play", FCVAR_PLUGIN);
	decl Handle:tmpHandle;
	HookConVarChange( tmpHandle = CreateConVar("sm_join_sound_defaultcookie", "1.0", "Default cookie value. 0=Do not play, 1=Play random sound, 2=Play but stop when joining a playable team. Def=1", FCVAR_PLUGIN, true, 0.0, true, 2.0), ConVarChange_Cookie );
	g_iDefaultCookieValue = GetConVarInt( tmpHandle );
	
	//Tr
	LoadTranslations("randomjoinsound.phrases");
	
	//Cookie
	decl String:menutitle[64];
	Format( menutitle, sizeof(menutitle), "%T", "rjs_menuTitle", LANG_SERVER );
	SetCookieMenuItem(PrefMenu, 0, menutitle);
	g_hCookie = RegClientCookie( "rjs", "How welcome sound is played", CookieAccess_Protected );
	
	//Event
	HookEvent( "player_team", Event_PlayerTeam );
	
	//Lib
	g_bLibraryIsPresent = true;
	if ( !LibraryExists( "filesmanagement.core" ) )
	{
		g_bLibraryIsPresent = false;
	}
}
public OnLibraryAdded(const String:name[])
{
	if ( StrEqual( name, "filesmanagement.core" ) )
	{
		g_bLibraryIsPresent = true;
	}
}
public OnLibraryRemoved(const String:name[])
{
	if ( StrEqual( name, "filesmanagement.core" ) )
	{
		g_bLibraryIsPresent = false;
	}
}

public OnClientCookiesCached(client)
{
	if ( !GetConVarBool( g_hEnable ) || !g_bCanPlaySounds || !g_bLibraryIsPresent || g_bSoundPlayed[ client ] )
		return;
	
	decl String:pref[ 8 ];
	GetClientCookie( client, g_hCookie, pref, sizeof(pref) );
	
	if ( !StrEqual( pref, "" ) )
		g_iCookieValue[ client ] = StringToInt( pref );
	else
		g_iCookieValue[ client ] = g_iDefaultCookieValue;
	
	//seems impossible; after some tests I was emitting to unconnected clients (even if I checked if they were connected...)
	//plus it looks dumb if cookies are loaded reaaaaaally late
	/*if ( g_iCookieValue[ client ] != 0 )
	{
		//decl String:szBuffer[ 256 ];
		
		FMI_GetRandomSound( g_szSoundFolderPath, g_szPathSound[ client ], sizeof(g_szPathSound[]) );
		
		EmitSoundToClient( client, g_szPathSound[ client ] );
		g_bSoundPlayed[ client ] = true; //in case cookies are unloaded + reloaded I guess lul
	}*/
}

public OnConfigsExecuted()
{
	if ( !GetConVarBool( g_hEnable ) || !g_bLibraryIsPresent )
		return;
	
	GetConVarString( g_hSoundFolder, g_szSoundFolderPath, sizeof(g_szSoundFolderPath) );
	
	new nbPrecached = FMI_PrecacheSoundsFolder( g_szSoundFolderPath );
	
	PrintToServer("[Random Join Sound] Precached a total of %d sounds", nbPrecached);
	
	g_bCanPlaySounds = false;
	
	if ( nbPrecached > 0 )
	{
		strcopy( g_szSoundFolderPath, sizeof(g_szSoundFolderPath), g_szSoundFolderPath[ 6 ] ); //remove 'sound/'
		g_bCanPlaySounds = true;
	}
}

public OnClientPutInServer(client)
{
	g_bJoinedAtTeamYet[ client ] = false;
	
	if ( !GetConVarBool( g_hEnable ) || !g_bCanPlaySounds || !g_bLibraryIsPresent || g_iCookieValue[ client ] == 0 ||
		( g_iCookieValue[ client ] == -1 && g_iDefaultCookieValue == 0 ) ||
		( !AreClientCookiesCached(client) && g_iDefaultCookieValue == 0 ) ) //overcheck :$
		return;
	
	//decl String:szBuffer[ 256 ];
	
	FMI_GetRandomSound( g_szSoundFolderPath, g_szPathSound[ client ], sizeof(g_szPathSound[]) );
	
	EmitSoundToClient( client, g_szPathSound[ client ] );
	g_bSoundPlayed[ client ] = true;
}

public OnClientDisconnect(client)
{
	g_bSoundPlayed[ client ] = false;
	g_iCookieValue[ client ] = -1;
}

//========== Menu ==========

public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		decl String:menuItem[64];
		new Handle:prefmenu = CreateMenu(PrefMenuHandler);
		FormatEx(menuItem, sizeof(menuItem), "%T", "rjs_menuTitle", client);
		SetMenuTitle(prefmenu, menuItem);
		FormatEx(menuItem, sizeof(menuItem), "%T%T", "Disabled", client, g_iCookieValue[ client ] == 0 ? "(Selected)" : "space", client);
		AddMenuItem(prefmenu, "0", menuItem);
		FormatEx(menuItem, sizeof(menuItem), "%T%T", "Enabled", client, g_iCookieValue[ client ] == 1 ? "(Selected)" : "space", client);
		AddMenuItem(prefmenu, "1", menuItem);
		FormatEx(menuItem, sizeof(menuItem), "%T%T", "EnabledAndStopOnJoinTeam", client, g_iCookieValue[ client ] == 2 ? "(Selected)" : "space", client);
		AddMenuItem(prefmenu, "2", menuItem);
		DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
	}
}

public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item)
{
	if ( action == MenuAction_Select )
	{
		decl String:pref[8];
		GetMenuItem( prefmenu, item, pref, sizeof(pref) );
		g_iCookieValue[ client ] = StringToInt( pref );
		SetClientCookie( client, g_hCookie, pref );
		ShowCookieMenu( client );
	}
	else if ( action == MenuAction_End )
		CloseHandle(prefmenu);
}

//========== Events ==========

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( g_bSoundPlayed[ iClient ] == true && g_bJoinedAtTeamYet[ iClient ] == false && GetEventInt( event, "team" ) >= 2 )
	{
		if ( g_iCookieValue[ iClient ] == 2 )
		{
			StopSound( iClient, SNDCHAN_AUTO, g_szPathSound[ iClient ] );
		}
	}
}

//========== ConVarChange ===========

public ConVarChange_Cookie(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_iDefaultCookieValue = StringToInt( newvalue );
}