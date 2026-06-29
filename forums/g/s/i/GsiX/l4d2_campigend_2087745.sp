new g_bLoader, g_bLimiter, String:g_sMapName[64];

public OnPluginStart()
{
	g_bLoader	= 0;
	g_bLimiter	= 0;
	Format( g_sMapName, sizeof( g_sMapName ), "" );
}

public OnMapStart()
{
	g_bLoader += 1;
	GetCurrentMap( g_sMapName, sizeof( g_sMapName ));
	GetMapConfig( g_sMapName );
}

public OnMapEnd()
{
	if ( g_bLoader >= g_bLimiter )
	{
		PrintToServer( "Server shout down at map %s", g_sMapName );
		ServerCommand( "quit" );
	}
}

GetMapConfig( const String:map[] )
{
	if ( StrContains( map, "c1m" ) != -1 )		g_bLimiter = 4;
	else if ( StrContains( map, "c2m" ) != -1 )	g_bLimiter = 5;
	else if ( StrContains( map, "c3m" ) != -1 )	g_bLimiter = 4;
	else if ( StrContains( map, "c4m" ) != -1 )	g_bLimiter = 5;
	else if ( StrContains( map, "c5m" ) != -1 )	g_bLimiter = 5;
	// and so on to c12m. g_bLimiter is the total map per campign.
}


