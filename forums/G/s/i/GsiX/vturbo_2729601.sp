#include	<sourcemod>
#pragma		semicolon 1
#pragma		newdecls required

#define		PLUGIN_VERSION	"0.0.0"

ConVar	g_ConVar_MarkZuckerberg_VturboEnable;
ConVar	g_ConVar_MarkZuckerberg_VturboDuration;
ConVar	g_ConVar_MarkZuckerberg_VturboInterval;
ConVar	g_ConVar_MarkZuckerberg_VturboSpeed;
bool	g_bThisIs_MarkZuckerberg_Enable;
float	g_fThisIs_MarkZuckerberg_MaxSpeed;
float	g_fThisIs_MarkZuckerberg_Interval;
float	g_fThisIs_MarkZuckerberg_Duration;

float	g_fZmiennaPrzetrzymujacaCzasAbySprawdzacCzyMoznaUzycKomendy[MAXPLAYERS+1] = { 0.0, ... };
float	g_fThisIs_MarkZuckerberg_LastUsage[MAXPLAYERS+1] = { 0.0, ... };

public Plugin myinfo =
{
    name        = "Turbo na 7 sekund dla vipa",
    author      = "",
    description = "Komenda dla vipa, ktora daje turbo na 7 sekund",
    version     = PLUGIN_VERSION,
    url         = "-----"
};

public void OnPluginStart()
{
	CreateConVar( "vturbo_version", PLUGIN_VERSION, "vturbo version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	g_ConVar_MarkZuckerberg_VturboEnable = CreateConVar( "vturbo_enabled", "1", "0:Off, 1:On,  Toggle plugin on/off", FCVAR_SPONLY|FCVAR_NOTIFY );
	
	// How long Vturbo last
	g_ConVar_MarkZuckerberg_VturboDuration = CreateConVar( "vturbo_duration", "7.0",	"Jak długo trwa Vturbo", FCVAR_SPONLY|FCVAR_NOTIFY );
	
	// Interval between ability usage
	g_ConVar_MarkZuckerberg_VturboInterval = CreateConVar( "vturbo_interval", "60.0",	"Odstęp czasu między użyciem zdolności", FCVAR_SPONLY|FCVAR_NOTIFY );
	
	// Percentage added to the player speed
	g_ConVar_MarkZuckerberg_VturboSpeed = CreateConVar( "vturbo_speed", "40.0",	"Procent dodany do szybkości gracza", FCVAR_SPONLY|FCVAR_NOTIFY );
	
	AutoExecConfig( true , "vturbo" );
	
	HookEvent( "player_spawn",	MarkZuckerberg_EventSpawn );
	RegAdminCmd("sm_vturbo", MarkZuckerberg_Command, ADMFLAG_CUSTOM6);
	
	g_ConVar_MarkZuckerberg_VturboEnable.AddChangeHook( MarkZuckerberg_ConVar_Changed );
	g_ConVar_MarkZuckerberg_VturboDuration.AddChangeHook( MarkZuckerberg_ConVar_Changed );
	g_ConVar_MarkZuckerberg_VturboInterval.AddChangeHook( MarkZuckerberg_ConVar_Changed );
	g_ConVar_MarkZuckerberg_VturboSpeed.AddChangeHook( MarkZuckerberg_ConVar_Changed );
	
	// nothing to see here.
	// nie ma tu nic do oglądania
	UpdateConVar_GsiX();
}

public void MarkZuckerberg_ConVar_Changed( Handle convar, const char[] oldValue, const char[] newValue )
{
	UpdateConVar_GsiX();
}

void UpdateConVar_GsiX()
{
	g_bThisIs_MarkZuckerberg_Enable		= g_ConVar_MarkZuckerberg_VturboEnable.BoolValue;
	g_fThisIs_MarkZuckerberg_Duration	= g_ConVar_MarkZuckerberg_VturboDuration.FloatValue;
	g_fThisIs_MarkZuckerberg_Interval	= g_ConVar_MarkZuckerberg_VturboInterval.FloatValue;
	g_fThisIs_MarkZuckerberg_MaxSpeed	= g_ConVar_MarkZuckerberg_VturboSpeed.FloatValue;
	
	// this suppost to be percentage. My math is poor so please double confirm. :cry: :cry:
	g_fThisIs_MarkZuckerberg_MaxSpeed = 1.0 + ( 1.0 * g_fThisIs_MarkZuckerberg_MaxSpeed / 100.0 );
	
	if( g_fThisIs_MarkZuckerberg_Duration > g_fThisIs_MarkZuckerberg_Interval )
	{
		g_fThisIs_MarkZuckerberg_Duration = g_fThisIs_MarkZuckerberg_Interval;
	}
	
	if( !g_bThisIs_MarkZuckerberg_Enable )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame( i ))
			{
				SetEntPropFloat( i, Prop_Send, "m_flLaggedMovementValue", 1.0 );
				MarkZuckerberg_ResetPlayer( i );
			}
		}
	}
}

public void OnClientPutInServer( int client )
{
	MarkZuckerberg_ResetPlayer( client );
}

public Action MarkZuckerberg_Command( int client, int args )
{
	if( client > 0 )
	{
		if( !g_bThisIs_MarkZuckerberg_Enable )
		{
			ReplyToCommand( client, "\x06[VTURBO]: \x02wtyczki zostały wyłączone" );
			return Plugin_Handled;
		}
		
		if( g_fZmiennaPrzetrzymujacaCzasAbySprawdzacCzyMoznaUzycKomendy[client] > 0.0 ) {
			PrintToChat(client, "\x06[VTURBO]:\x02 Aby użyć jeszcze raz turbo, poczekaj \x06%f \x02 sekund!", g_fZmiennaPrzetrzymujacaCzasAbySprawdzacCzyMoznaUzycKomendy[client]);
			return Plugin_Handled;
		}

		g_fThisIs_MarkZuckerberg_LastUsage[client]	= g_fThisIs_MarkZuckerberg_Duration;							// duration speed cooldown
		g_fZmiennaPrzetrzymujacaCzasAbySprawdzacCzyMoznaUzycKomendy[client] = g_fThisIs_MarkZuckerberg_Interval;	// duration ability cooldown
		
		SetEntPropFloat( client, Prop_Send, "m_flLaggedMovementValue", g_fThisIs_MarkZuckerberg_MaxSpeed );
		
		int userid = GetClientUserId( client );
		CreateTimer( 0.1, MarkZuckerberg_TimerSkill, userid, TIMER_REPEAT );
		CreateTimer( 0.1, MarkZuckerberg_TimerUsage, userid, TIMER_REPEAT );
	}
	return Plugin_Handled;
}

public Action MarkZuckerberg_TimerSkill( Handle hTimer, int userid )
{
	int client = GetClientOfUserId(userid);
	if( MarkZuckerberg_IsValid( client ))
	{
		if( IsPlayerAlive( client ) && g_fThisIs_MarkZuckerberg_LastUsage[client] > 0.0 )
		{
			g_fThisIs_MarkZuckerberg_LastUsage[client] -= 0.1;
			return Plugin_Continue;
		}
		
		g_fThisIs_MarkZuckerberg_LastUsage[client] = 0.0;
		SetEntPropFloat( client, Prop_Send, "m_flLaggedMovementValue", 1.0 );
	}
	return Plugin_Stop;
}

public Action MarkZuckerberg_TimerUsage( Handle hTimer, int userid )
{
	int client = GetClientOfUserId(userid);
	if( MarkZuckerberg_IsValid( client ))
	{
		if( IsPlayerAlive( client ) && g_fZmiennaPrzetrzymujacaCzasAbySprawdzacCzyMoznaUzycKomendy[client] > 0.0 )
		{
			g_fZmiennaPrzetrzymujacaCzasAbySprawdzacCzyMoznaUzycKomendy[client] -= 0.1;
			return Plugin_Continue;
		}
		g_fZmiennaPrzetrzymujacaCzasAbySprawdzacCzyMoznaUzycKomendy[client] = 0.0;
	}
	return Plugin_Stop;
}

public void MarkZuckerberg_EventSpawn( Event event, const char[] name, bool dontBroadcast )
{
	if( !g_bThisIs_MarkZuckerberg_Enable ) { return; }
	
	int userid = event.GetInt( "userid" );
	int client = GetClientOfUserId( userid );
	if( MarkZuckerberg_IsValid( client ))
	{
		SetEntPropFloat( client, Prop_Send, "m_flLaggedMovementValue", 1.0 );
		MarkZuckerberg_ResetPlayer( client );
	}
}

void MarkZuckerberg_ResetPlayer( int client )
{
	if( g_bThisIs_MarkZuckerberg_Enable )
	{
		g_fThisIs_MarkZuckerberg_LastUsage[client] = 0.0;
		g_fZmiennaPrzetrzymujacaCzasAbySprawdzacCzyMoznaUzycKomendy[client] = 0.0;
	}
}

bool MarkZuckerberg_IsValid( int client )
{
	return ( client > 0 && client <= MaxClients && IsClientInGame( client ));
}














