#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION		"1.0"

#define N_PAINTS			14
#define N_SIZES				3
#define PAINT_DISTANCE_SQ	1.0

public Plugin myinfo = 
{
    name = "Paint!",
    author = "SlidyBat",
    description = "Allow players to paint on walls",
    version = PLUGIN_VERSION,
    url = ""
}

/* GLOBALS */
Menu	g_hPaintMenu;
Menu	g_hPaintSizeMenu;

int		g_PlayerPaintColour[MAXPLAYERS + 1];
int		g_PlayerPaintSize[MAXPLAYERS + 1];

float	g_fLastPaint[MAXPLAYERS + 1][3];
bool	g_bIsPainting[MAXPLAYERS + 1];

int		g_Sprites[N_PAINTS*N_SIZES];

/* COOKIES */
Handle	g_hPlayerPaintColour;
Handle	g_hPlayerPaintSize;

/* COLOURS! */
/* Colour name, file name */
char g_cPaintColours[][][64] = // Modify this to add/change colours
{
	{ "Random", "random" },
	{ "White", "laser_white" },
	{ "Black", "laser_black" },
	{ "Blue", "laser_blue" },
	{ "Light Blue", "laser_lightblue" },
	{ "Brown", "laser_brown" },
	{ "Brown", "laser_brown" },
	{ "Cyan", "laser_cyan" },
	{ "Green", "laser_green" },
	{ "Dark Green", "laser_darkgreen" },
	{ "Red", "laser_red" },
	{ "Orange", "laser_orange" },
	{ "Yellow", "laser_yellow" },
	{ "Pink", "laser_pink" },
	{ "Light Pink", "laser_lightpink" },
	{ "Purple", "laser_purple" },
};

/* Size name, size suffix */
char g_cPaintSizes[][][64] = // Modify this to add more sizes
{
	{ "Small", "" },
	{ "Medium", "_med" },
	{ "Large", "_large" },
};

public void OnPluginStart()
{
	CreateConVar("paint_version", PLUGIN_VERSION, "Paint plugin version", FCVAR_NOTIFY);
	
	/* Register Cookies */
	g_hPlayerPaintColour = RegClientCookie( "paint_playerpaintcolour", "paint_playerpaintcolour", CookieAccess_Protected );
	g_hPlayerPaintSize = RegClientCookie( "paint_playerpaintsize", "paint_playerpaintsize", CookieAccess_Protected );
	
	/* COMMANDS */
	RegAdminCmd( "+paint", cmd_EnablePaint, ADMFLAG_CHAT );
	RegAdminCmd( "-paint", cmd_DisablePaint, ADMFLAG_CHAT );
	RegAdminCmd( "sm_paintcolour", cmd_PaintColour, ADMFLAG_CHAT );
	RegAdminCmd( "sm_paintcolor", cmd_PaintColour, ADMFLAG_CHAT );
	RegAdminCmd( "sm_paintsize", cmd_PaintSize, ADMFLAG_CHAT );
	
	
	CreatePaintMenus();
	
	/* Late loading */
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame( i ) )
		{
			OnClientCookiesCached( i );
		}
	}
}

public void OnClientCookiesCached( int client )
{
	char sValue[64];

	GetClientCookie( client, g_hPlayerPaintColour, sValue, sizeof( sValue ) );
	g_PlayerPaintColour[client] = StringToInt( sValue );
	
	GetClientCookie( client, g_hPlayerPaintSize, sValue, sizeof( sValue ) );
	g_PlayerPaintSize[client] = StringToInt( sValue );
}

public void OnMapStart()
{
	char buffer[64];
	
	for( int i = 1; i <= N_PAINTS; i++ )
	{
		Format( buffer, sizeof( buffer ), "decals/paint/%s.vtf", g_cPaintColours[i][1] );
		PrecachePaint( buffer );
	
		int index = (i - 1) * N_SIZES; // i - 1 because starts from [1], [0] is reserved for random
		
		for( int j = 0; j < N_SIZES; j++ )
		{
			Format( buffer, sizeof( buffer ), "decals/paint/%s%s.vmt", g_cPaintColours[i][1], g_cPaintSizes[j][1] );
			g_Sprites[index + j] = PrecachePaint( buffer );
		}
	}
	
	CreateTimer( 0.1, Timer_Paint, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
}

public Action cmd_EnablePaint( int client, int args )
{
	TraceEye(client, g_fLastPaint[client]);
	g_bIsPainting[client] = true;
	
	return Plugin_Handled;
}

public Action cmd_DisablePaint( int client, int args )
{
	g_bIsPainting[client] = false;
	
	return Plugin_Handled;
}

public Action cmd_PaintColour( int client, int args )
{
	g_hPaintMenu.Display( client, 20 );
	
	return Plugin_Handled;
}

public Action cmd_PaintSize( int client, int args )
{
	g_hPaintSizeMenu.Display( client, 20 );
	
	return Plugin_Handled;
}

public Action Timer_Paint( Handle timer )
{
	float pos[3];
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame( i ) && IsPlayerAlive( i ) && g_bIsPainting[i] )
		{
				TraceEye( i, pos );
				
				if( GetVectorDistance( pos, g_fLastPaint[i], true ) > PAINT_DISTANCE_SQ )
				{
					AddPaint( pos, g_PlayerPaintColour[i], g_PlayerPaintSize[i] );
					
					g_fLastPaint[i][0] = pos[0];
					g_fLastPaint[i][1] = pos[1];
					g_fLastPaint[i][2] = pos[2];
				}
		}
	}
}

void AddPaint( float pos[3], int paint = 0, int size = 0 )
{
	if( paint == 0 )
	{
		paint = GetRandomInt( 1, N_PAINTS + 1 );
	}
	
	TE_SetupWorldDecal( pos, g_Sprites[(paint - 1)*N_SIZES + size] );
	TE_SendToAll();
}

int PrecachePaint( char[] filename )
{
	char tmpPath[PLATFORM_MAX_PATH];
	Format( tmpPath, sizeof( tmpPath ), "materials/%s", filename );
	AddFileToDownloadsTable( tmpPath );
	
	return PrecacheDecal( filename, true );
}

void CreatePaintMenus()
{
	/* COLOURS MENU */
	delete g_hPaintMenu;
	g_hPaintMenu = new Menu(PaintColourMenuHandle);
	
	g_hPaintMenu.SetTitle( "Select Paint Colour:" );
	
	for( int i = 0; i <= N_PAINTS; i++ )
	{
		g_hPaintMenu.AddItem( g_cPaintColours[i][0], g_cPaintColours[i][0] );
	}
	
	/* SIZE MENU */
	delete g_hPaintSizeMenu;
	g_hPaintSizeMenu = new Menu(PaintSizeMenuHandle);
	
	g_hPaintSizeMenu.SetTitle( "Select Paint Size:" );
	
	for( int i = 0; i < N_SIZES; i++ )
	{
		g_hPaintSizeMenu.AddItem( g_cPaintSizes[i][0], g_cPaintSizes[i][0] );
	}
}

public int PaintColourMenuHandle( Menu menu, MenuAction menuAction, int param1, int param2 )
{
	if( menuAction == MenuAction_Select )
	{
		SetClientPaintColour( param1, param2 );
	}
}

public int PaintSizeMenuHandle( Menu menu, MenuAction menuAction, int param1, int param2 )
{
	if( menuAction == MenuAction_Select )
	{
		SetClientPaintSize( param1, param2 );
	}
}

void SetClientPaintColour( int client, int paint )
{
	char sValue[64];
	g_PlayerPaintColour[client] = paint;
	IntToString( paint, sValue, sizeof( sValue ) );
	SetClientCookie( client, g_hPlayerPaintColour, sValue );
	
	PrintToChat( client, "[SM] Paint colour now: \x10%s", g_cPaintColours[paint][0] );
}

void SetClientPaintSize( int client, int size )
{
	char sValue[64];
	g_PlayerPaintSize[client] = size;
	IntToString( size, sValue, sizeof( sValue ) );
	SetClientCookie( client, g_hPlayerPaintSize, sValue );
	
	PrintToChat( client, "[SM] Paint size now: \x10%s", g_cPaintSizes[size][0] );
}

stock void TE_SetupWorldDecal( const float vecOrigin[3], int index )
{    
    TE_Start( "World Decal" );
    TE_WriteVector( "m_vecOrigin", vecOrigin );
    TE_WriteNum( "m_nIndex", index );
}

stock void TraceEye( int client, float pos[3] )
{
	float vAngles[3], vOrigin[3];
	GetClientEyePosition( client, vOrigin );
	GetClientEyeAngles( client, vAngles );
	
	TR_TraceRayFilter( vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer );
	
	if( TR_DidHit() )
		TR_GetEndPosition( pos );
}

public bool TraceEntityFilterPlayer( int entity, int contentsMask )
{
	return ( entity > GetMaxClients() || !entity );
}