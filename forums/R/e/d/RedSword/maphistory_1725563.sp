#pragma semicolon 1

#define PLUGIN_VERSION	"1.1.1"

public Plugin:myinfo = 
{
	name = "Map History",
	author = "RedSword / Bob Le Ponge",
	description = "Have a way to know which maps were the last played.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Defines
//32 because more is pretty useless and you'll probably have problem visualizing more (it depends on in-game resolution) ; 50 seems to be ok in x720 or x768; but its big like f*ck
#define HISTORY_LENGTH 32

#define MAPNAME_LENGTH 32
#define STARTTIME_LENGTH 8
#define TIMEFORMAT "%Hh%Mm"

//#define DEBUG

//ConVars
new Handle:g_hMHLastMap;
new Handle:g_hMHMenu;
new Handle:g_hMHMenuNbMapsShown;
new Handle:g_hMHMenuDelayMin;

//ConVars cache
new g_iFlagLastMap;
new String:g_szOverrideLastMap[ 32 ];
new g_iFlagMenu;
new String:g_szOverrideMenu[ 32 ];

//Vars
new bool:g_bLastMapPublic; //panda D:
new bool:g_bMenuPublic;
new g_iLastTimeStampMenu[ MAXPLAYERS + 1 ];

//1.1
new Handle:g_hHistoryPanel = INVALID_HANDLE;
new Handle:g_hShowCurrentMap = INVALID_HANDLE;

//===== Forwards

public OnPluginStart()
{
	//CVars
	CreateConVar( "maphistoryversion",
	PLUGIN_VERSION, 
	"Last Maps History version", 
	FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	
	decl String:szBuffer[ 32 ];
	
	g_hMHLastMap = CreateConVar( "mh_allow_lastmap",
	"1.0", 
	"Allow people to use 'lastmap' command to see the last map. 0=disable command, 1=enable command (default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	
	g_hMHMenu = CreateConVar( "mh_allow_menu",
	"1.0", 
	"Allow people to use the menu to show last maps. 0=disable command, 1=enable command (default).", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	FloatToString( float( HISTORY_LENGTH ), szBuffer, 6 ); //3 digits + ".0\0"
	g_hMHMenuNbMapsShown = CreateConVar( "mh_allow_menu_mapnumbershown",
	szBuffer, //reused later
	"Allow people to use the menu to show last maps. 0=disable command, 1=enable command (default).", 
		FCVAR_PLUGIN, true, 0.0, true, float(HISTORY_LENGTH) );
	
	g_hMHMenuDelayMin = CreateConVar( "mh_allow_menu_delaymin",
	"2.0",
	"Minimum time in seconds between two menu requests for a player. Default 2.", 
		FCVAR_PLUGIN, true, 0.0 );
	
	g_hShowCurrentMap = CreateConVar( "mh_showcurrentmap",
	"0.0",
	"Show current map in '!lastmaps' ? 1=yes, 0=no (default) ; changing value requires map change",
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	
	decl Handle:randomHandle;
	
	randomHandle = CreateConVar( "mh_lastmap_flag", 
	"", 
	"Restrict 'lastmap' to people with this flag. \"\" for everyone.",
		FCVAR_PLUGIN );
	HookConVarChange(randomHandle, OnLastMapFlagChanged);
	GetConVarString(randomHandle, szBuffer, sizeof(szBuffer));
	g_iFlagLastMap = ReadFlagString( szBuffer );
	
	randomHandle = CreateConVar( "mh_lastmap_override", 
	"", 
	"Restrict 'lastmap' to people with this override. \"\" for everyone.",
		FCVAR_PLUGIN );
	HookConVarChange(randomHandle, OnLastMapOverrideChanged);
	GetConVarString(randomHandle, g_szOverrideLastMap, sizeof(g_szOverrideLastMap));
	
	g_bLastMapPublic = StrEqual(g_szOverrideLastMap, "") || !g_iFlagLastMap;
	
	
	randomHandle = CreateConVar( "mh_menu_flag", 
	"", 
	"Restrict 'menu' to people with this flag. \"\" for everyone.",
		FCVAR_PLUGIN );
	HookConVarChange(randomHandle, OnMenuFlagChanged);
	GetConVarString(randomHandle, szBuffer, sizeof(szBuffer));
	g_iFlagMenu = ReadFlagString( szBuffer );
	
	randomHandle = CreateConVar( "mh_menu_override", 
	"", 
	"Restrict 'menu' to people with this override. \"\" for everyone.",
		FCVAR_PLUGIN );
	HookConVarChange(randomHandle, OnMenuOverrideChanged);
	GetConVarString(randomHandle, g_szOverrideMenu, sizeof(g_szOverrideMenu));
	
	g_bMenuPublic = StrEqual(g_szOverrideMenu, "") || !g_iFlagMenu;
	
	
	AutoExecConfig(true, "maphistory");
	
	LoadTranslations( "common.phrases" );
	LoadTranslations( "maphistory.phrases" );
	
	RegConsoleCmd( "sm_lastmap", Command_LastMap, "sm_lastmap" );
	RegConsoleCmd( "sm_lastmaps", Command_MapHistory, "sm_lastmaps" );
	
#if defined DEBUG
	RegConsoleCmd( "sm_allmaphistory", Command_AllMapHistory, "sm_allmaphistory" );
#endif
	
	g_hHistoryPanel = CreatePanel();
}

public OnMapStart()
{
	reloadHistoryPanel();
}

//===== Commands

public Action:Command_LastMap(client, args)
{
	if ( !GetConVarBool( g_hMHLastMap ) )
		return Plugin_Continue;
	
	//Access --> print
	if ( g_bLastMapPublic || CheckCommandAccess(client, g_szOverrideLastMap, g_iFlagLastMap) )
	{
		if ( 0 == GetMapHistorySize() )
		{
			PrintToChat( client, "\x04[SM] \x01%t", "NoLastMap" );
		}
		else
		{
			decl String:szBuffer[ 32 ];
			decl timeStart;
			
			//0 = last map
			GetMapHistory( 0, szBuffer, sizeof(szBuffer), szBuffer, 0, timeStart );
			
			decl String:szStartTime[ STARTTIME_LENGTH ];
			FormatTime( szStartTime, sizeof(szStartTime), TIMEFORMAT, timeStart );
			
			PrintToChat( client, "\x04[SM] \x01%t", "LastMapNameTime", 
				"\x05", szBuffer, "\x01",
				"\x05", szStartTime, "\x01" );
		}
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}
#if defined DEBUG
public Action:Command_AllMapHistory(client, args)
{
	decl String:szBuffer[ 32 ];
	decl useless;
	ReplyToCommand( client, "SizeOfHistory = %d", GetMapHistorySize() );
	for ( new i; i < GetMapHistorySize(); ++i )
	{
		GetMapHistory( i, szBuffer, sizeof(szBuffer), szBuffer, 0, useless );
		ReplyToCommand( client, "Map #%d = '%s'", i, szBuffer );
	}
}
#endif

public Action:Command_MapHistory(client, args)
{
	if ( !GetConVarBool( g_hMHMenu ) )
		return Plugin_Continue;
	
	//Prevent people from outside to run the command
	if ( client == 0 )
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	new currentTime = GetTime();
	
	if ( g_iLastTimeStampMenu[ client ] + GetConVarInt( g_hMHMenuDelayMin ) >= currentTime  )
	{
		return Plugin_Continue;
	}
	
	//Access --> print
	if ( g_bMenuPublic || CheckCommandAccess(client, g_szOverrideMenu, g_iFlagMenu) )
	{
		if ( 0 == GetMapHistorySize() )
		{
			PrintToChat( client, "\x04[SM] \x01%t", "NoLastMap" );
			return Plugin_Handled;
		}
		
		decl String:szTitleBuffer[ 32 ];
		FormatEx( szTitleBuffer, sizeof(szTitleBuffer), "%T", "PanelTitleMapHistory", client );
		
		SetPanelTitle( g_hHistoryPanel, szTitleBuffer );

		SendPanelToClient( g_hHistoryPanel, client, Handler_Panel, MENU_TIME_FOREVER );
		
		g_iLastTimeStampMenu[ client ] = currentTime;
	
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}
public Handler_Panel(Handle:menu, MenuAction:action, param1, param2)
{
}

/* //Test script if someone wants ;) ; useful to test amount of map u can get for a resolution
decl String:szMapInHistoryNumber[ 4 ];
for ( new i; i < HISTORY_LENGTH; ++i )
{
	IntToString( i + 1, szMapInHistoryNumber, sizeof(szMapInHistoryNumber) );
	DrawPanelText( menu, szMapInHistoryNumber );
}*/

//=====Privates

reloadHistoryPanel()
{
	//RemoveAllMenuItems( g_hHistoryPanel ); //crashes :@ @invalid handle(error 2)
	CloseHandle( g_hHistoryPanel );
	g_hHistoryPanel = CreatePanel();
	
	new nbMapsShown = GetMapHistorySize();
	
	if ( nbMapsShown >= GetConVarInt( g_hMHMenuNbMapsShown ) ) //= @ currentMap
	{
		nbMapsShown = GetConVarInt( g_hMHMenuNbMapsShown );
		
		if ( GetConVarBool( g_hShowCurrentMap ) )
			--nbMapsShown;
	}
	
	new count;
	
	decl String:szMapInHistoryNumber[ 4 ];
	
	decl startTime;
	decl String:szMapName[ MAPNAME_LENGTH ];
	
	decl String:szStartTime[ STARTTIME_LENGTH ];
	
	decl String:szDisplay[ 4 + MAPNAME_LENGTH + STARTTIME_LENGTH + 5 ]; //5 = 3 spaces + '.' + '@'
	
	//MapHistory in SM holds maps in reverse order (higher = older; i.e. GetMapHistory(0) = lastmap)
	for ( new i = nbMapsShown - 1; i >= 0; --i )
	{
		++count;
		IntToString( count, szMapInHistoryNumber, sizeof(szMapInHistoryNumber) );
		
		GetMapHistory( i, szMapName, sizeof(szMapName), szMapName, 0, startTime );
		
		FormatTime( szStartTime, sizeof(szStartTime), TIMEFORMAT, startTime );
		
		FormatEx( szDisplay, sizeof(szDisplay), "%s. %s @ %s",
			szMapInHistoryNumber,
			szMapName, 
			szStartTime
			);
		
		DrawPanelText( g_hHistoryPanel, szDisplay );
	}
	
	if ( GetConVarBool( g_hShowCurrentMap ) )
	{
		++count;
		IntToString( count, szMapInHistoryNumber, sizeof(szMapInHistoryNumber) );
		
		GetCurrentMap( szMapName, sizeof(szMapName) );
		
		FormatTime( szStartTime, sizeof(szStartTime), TIMEFORMAT, GetTime() );
		
		FormatEx( szDisplay, sizeof(szDisplay), "%s. %s @ %s",
			szMapInHistoryNumber,
			szMapName, 
			szStartTime
			);
		
		DrawPanelText( g_hHistoryPanel, szDisplay );
	}
	
	DrawPanelItem( g_hHistoryPanel, "Close Menu" );
}

//=====HookConVarChange

public OnLastMapFlagChanged(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_iFlagLastMap = ReadFlagString( newvalue );
	g_bLastMapPublic = StrEqual(g_szOverrideLastMap, "") || !g_iFlagLastMap;
}
public OnLastMapOverrideChanged(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	strcopy( g_szOverrideLastMap, sizeof(g_szOverrideLastMap), newvalue );
	g_bLastMapPublic = StrEqual(g_szOverrideLastMap, "") || !g_iFlagLastMap;
}
public OnMenuFlagChanged(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	g_iFlagMenu = ReadFlagString( newvalue );
	g_bLastMapPublic = StrEqual(g_szOverrideMenu, "") || !g_iFlagMenu;
}
public OnMenuOverrideChanged(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	strcopy( g_szOverrideMenu, sizeof(g_szOverrideMenu), newvalue );
	g_bLastMapPublic = StrEqual(g_szOverrideMenu, "") || !g_iFlagMenu;
}