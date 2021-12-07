#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0"

public Plugin myinfo = 
{
    name = "Distance Checker",
    author = "SlidyBat",
    description = "Allow players to get distance stats between 2 points",
    version = PLUGIN_VERSION,
    url = ""
}

/* GLOBALS */
int		g_ClientStep[MAXPLAYERS + 1];
bool	g_bLastUsePressed[MAXPLAYERS + 1];
float	g_SavedPos[MAXPLAYERS + 1][3];

Handle	g_hDrawTimer;
int		g_Sprite;
int		g_nSelectingClients;

public void OnPluginStart()
{
	CreateConVar("getdist_version", PLUGIN_VERSION, "Distance checker plugin version", FCVAR_NOTIFY);
	
	/* COMMANDS */
	RegConsoleCmd( "sm_getdist", cmd_GetDist );
}

public void OnMapStart()
{
	g_Sprite = PrecacheModel( "sprites/blueglow1.vmt" );
}

public void OnClientDisconnect( int client )
{
	if( g_ClientStep[client] > 0 )
	{
		g_nSelectingClients--;
		CheckTimer();
		g_ClientStep[client] = 0;
	}
}

public Action cmd_GetDist( int client, int args )
{
	g_ClientStep[client] = 1;
	PrintToChat( client, "[SM] Select first point by pressing +use ..." );

	if( ++g_nSelectingClients == 1 )
	{
		g_hDrawTimer = CreateTimer( 0.1, Timer_Draw, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd( int client, int& buttons )
{
	bool usePressed = buttons & IN_USE > 0;
	
	if( usePressed && !g_bLastUsePressed[client] )
	{
		OnUsePressed( client );
	}

	g_bLastUsePressed[client] = usePressed;
}

void OnUsePressed( const int client )
{
	if( g_ClientStep[client] == 1 )
	{
		TraceEye( client, g_SavedPos[client] );
		
		PrintToChat( client, "[SM] Select second point by pressing +use ... " );
		g_ClientStep[client]++;
	}
	else if( g_ClientStep[client] == 2 )
	{
		float pos[3];
		TraceEye( client, pos );
		
		float dx = pos[0] - g_SavedPos[client][0];
		float dy = pos[1] - g_SavedPos[client][1];
		float dz = FloatAbs( pos[2] - g_SavedPos[client][2] );
		
		float dist = SquareRoot( dx*dx + dy*dy + dz*dz );
		float horizontaldist = SquareRoot( dx*dx + dy*dy );
		
		PrintToChat( client, "[SM] Δ Height: %.2f | Distance: %.2f | 2D Dist: %.2f", dz, dist, horizontaldist );
		g_ClientStep[client] = 0;
		g_nSelectingClients--;
		CheckTimer();
	}
}

void CheckTimer()
{
	if( g_nSelectingClients == 0 )
	{
		delete g_hDrawTimer;
	}
}

public Action Timer_Draw( Handle timer )
{
	float pos[3];
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame( i ) && IsPlayerAlive( i ) && g_ClientStep[i] )
		{
			TraceEye( i, pos );
			DrawPoint( i, pos );
			
			if( g_ClientStep[i] == 2 )
				DrawPoint( i, g_SavedPos[i] );
		}
	}
}

void DrawPoint( const int client, const float pos[3] )
{
	TE_SetupGlowSprite( pos, g_Sprite, 0.1, 1.0, 249 );
	TE_SendToClient( client );
}

stock void TraceEye( const int client, float pos[3] )
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