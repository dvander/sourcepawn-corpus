#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"1.0.0"

#define TEAM_SPECTATOR 	1
#define TEAM_SURVIVOR 	2

#define MAX_COLORS 		6

#define SERVER_INDEX 	0
#define NO_INDEX 		-1
#define NO_PLAYER 		-2
#define BLUE_INDEX 		2
#define RED_INDEX 		3

#define NON_FLAMMABLE 	1
#define FLAMMABLE 		2

#define FULL_ADS 		1
#define LIFE_STATUS 	2
#define IGNITION_STATUS 3

static const char CTag[][] 				= { "'White'", "'Orange'", "'Cyan'", "'Red'", "'Blue'", "'Green'" };
static const char CTagCode[][] 			= { "\x01", "\x04", "\x03", "\x03", "\x03", "\x05" };
static const bool CTagReqSayText2[] 	= { false, false, true, true, true, false };
static const int CProfile_TeamIndex[] 	= { NO_INDEX, NO_INDEX, SERVER_INDEX, RED_INDEX, BLUE_INDEX, NO_INDEX };

static ConVar hCvar_Enabled;
static ConVar hCvar_IgnitionModes;
static ConVar hCvar_DisplayHealth;
static ConVar hCvar_TankHpMulti;
static ConVar hCvar_BasicTankHP;
static ConVar hCvar_TankIncludeBots;
static ConVar hCvar_TankSurvivorMultipler;
static ConVar hCvar_EnabledAds;
static ConVar hCvar_Difficult;

static bool bCvar_Enabled;
static bool bCvar_TankIncludeBots;
static bool bCvar_TankSurvivorMultipler;
static bool bLeft4DeadTwo;

static float TankBurnIndex;
static float fCvar_TankHpMulti;

static int iCvar_DisplayHealth;
static int iCvar_IgnitionModes;
static int iCvar_EnabledAds;
static int BasicTankHP;
//int MaxHealth[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name        = "[L4D1 AND L4D2] HP Tank Multiplier",
	author      = "Ernecio (Satanael)",
	description = "Multiply HP of the Tank according to the number of players.",
	version     = PLUGIN_VERSION,
	url         = "https://steamcommunity.com/profiles/76561198404709570/"
}

/**
 * Called on pre plugin start.
 *
 * @param hMyself        Handle to the plugin.
 * @param bLate          Whether or not the plugin was loaded "late" (after map load).
 * @param sError         Error message buffer in case load failed.
 * @param Error_Max      Maximum number of characters for error message buffer.
 * @return               APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2( Handle hMyself, bool bLate, char[] sError, int Error_Max )
{
	EngineVersion Engine = GetEngineVersion();
	if ( Engine != Engine_Left4Dead && Engine != Engine_Left4Dead2 /* || !IsDedicatedServer() */ )
	{
		strcopy( sError, Error_Max, "This plugin \"HP Tank Multiplier\" only runs in the \"Left 4 Dead 1/2\" Games!" );
		return APLRes_SilentFailure;
	}
	
	bLeft4DeadTwo = ( Engine == Engine_Left4Dead2 );
	return APLRes_Success;
}

/**
 * Called on plugin start.
 *
 * @noreturn
 */
public void OnPluginStart()
{
	CreateConVar(				"l4d_multipler_tank_hp_version", 			PLUGIN_VERSION, "Multiply HP of the Tank according to the number of players", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvar_Enabled 				= CreateConVar("director_enabled_plugin", 		"1", 		"Enables/Disables The plugin. 0 = Plugin OFF, 1 = Plugin ON.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_IgnitionModes 		= CreateConVar("director_ignition_modes", 		"1", 		"Enables/Disables Ignition modes towards the Tank.\n0 = Do Nothing.\n1 = Allows the Tank not to catch fire but him takes damage if touches the fire.\n2 = Allows the Tank to catch fire according to the amount of life his has.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hCvar_DisplayHealth 		= CreateConVar("director_display_health", 		"1", 		"Enables/Disables Display Tanks health in crosshair.\n0 = Display HP OFF.\n1 = Shows the state of health in percentage.\n2 = Shows the state of health with numbering.\n3 = Displays health status with bar and numbering", FCVAR_NOTIFY, true, 0.0, true, 3.0 );
	hCvar_TankHpMulti   		= CreateConVar("director_tank_hpmultiplier",	"0.25",		"Amount by which the HP of the Tank will be multiplied.", FCVAR_NOTIFY, true, 0.00, true, 1.00);
	hCvar_BasicTankHP 			= CreateConVar("director_basic_tankhp", 		"15000", 	"Basic amount of HP for the Tank.", FCVAR_NOTIFY, true, 0.0, true, 65535.0);
	hCvar_TankIncludeBots 		= CreateConVar("director_include_bots", 		"1", 		"Include bots to the multiplier.\n0 = No include bots.\n1 = Include bots.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_TankSurvivorMultipler = CreateConVar("director_survivor_multipler", 	"1", 		"Multiply Tank's HP if there are more four survivors or start from one survivor.\n0 = Start multiplying from one.\n1 = Start multiplying from four.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_EnabledAds			= CreateConVar("director_enabled_ads", 			"1", 		"Enables/Disables Tank life status ads in chat.\n0 = Ads OFF.\n1 = Show full ads.\n2 = Show only health status.\n3 = Show only ignition status", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	hCvar_Difficult 			= FindConVar("z_difficulty");
	
	hCvar_Enabled.AddChangeHook( Event_ConVarChanged );
	hCvar_IgnitionModes.AddChangeHook( Event_ConVarChanged );
	hCvar_DisplayHealth.AddChangeHook( Event_ConVarChanged );
	hCvar_TankHpMulti.AddChangeHook( Event_ConVarChanged ); 
	hCvar_BasicTankHP.AddChangeHook( Event_ConVarChanged );
	hCvar_TankIncludeBots.AddChangeHook( Event_ConVarChanged );
	hCvar_TankSurvivorMultipler.AddChangeHook( Event_ConVarChanged );
	hCvar_EnabledAds.AddChangeHook( Event_ConVarChanged );
	hCvar_Difficult.AddChangeHook( Event_OnCVarChange );
	
//	HookEvent("player_spawn", 			Event_PlayerSpawn, 	EventHookMode_Post);
	HookEvent("tank_spawn", 			Event_TankSpawn, 	EventHookMode_Post);
	HookEvent("player_death",			Event_PlayerDeath, 	EventHookMode_Pre);
	HookEvent("round_start",			Event_RoundStart, 	EventHookMode_PostNoCopy);
//	HookEvent("player_hurt", 			Event_PlayerHurt); 								// Replaced by SDKHook_OnTakeDamage.
//	HookEvent("server_spawn", 			Event_MapStart, 	EventHookMode_PostNoCopy);
//	HookEvent("player_incapacitated", 	Event_PlayerIncapacited ); 						// Replaced by Boolean function.

	CreateTimer( 0.1, TimerUpdateHintTextHP, _, TIMER_REPEAT );
	
	AutoExecConfig( true, "l4d_multipler_tank_hp" );	
}

/**
 * Called on configs executed.
 *
 * @noreturn
 */
public void OnConfigsExecuted()
{
	GetCvars();
	DFF_OnCvarChange();
}

void Event_ConVarChanged( Handle hCvar, const char[] sOldValue, const char[] sNewValue )
{
	GetCvars();
}

void Event_OnCVarChange( Handle hCvar, const char[] sOldValue, const char[] sNewValue )
{
	DFF_OnCvarChange();
}

/**************************************************************************/

void GetCvars()
{
	bCvar_Enabled = hCvar_Enabled.BoolValue;
	iCvar_IgnitionModes = hCvar_IgnitionModes.IntValue;
	iCvar_DisplayHealth = hCvar_DisplayHealth.IntValue;
	fCvar_TankHpMulti = hCvar_TankHpMulti.FloatValue;
	BasicTankHP = hCvar_BasicTankHP.IntValue;
	bCvar_TankIncludeBots = hCvar_TankIncludeBots.BoolValue;
	bCvar_TankSurvivorMultipler = hCvar_TankSurvivorMultipler.BoolValue;
	iCvar_EnabledAds = hCvar_EnabledAds.IntValue;
}

void DFF_OnCvarChange()
{
	static char sBuffer[64];
	hCvar_Difficult.GetString( sBuffer, sizeof( sBuffer ) );
	
	if ( strncmp( sBuffer, "Easy", sizeof( sBuffer ), false ) == 0 ) TankBurnIndex = 0.011666;
	else if ( strncmp( sBuffer, "Hard", sizeof( sBuffer ), false ) == 0 ) TankBurnIndex = 0.013333;
	else if ( strncmp( sBuffer, "Impossible", sizeof( sBuffer ), false ) == 0 ) TankBurnIndex = 0.014166;
	else TankBurnIndex = 0.0125;
}

public void Event_RoundStart( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	for( int i = 1; i <= MaxClients; i ++ )
		if( IsClientInGame( i ) )
			SDKUnhook( i, SDKHook_OnTakeDamage, OnTakeDamage );
}

/**
 * @note Event callback (tank_spawn)
 * @note The Tank is about to spawn.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public void Event_TankSpawn( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	if ( !bCvar_Enabled ) return;
	
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( client && IsClientInGame( client ) )
		CreateTimer( 0.3, TankSpawnTimer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
}

public void Event_PlayerDeath( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
	if( client ) SDKUnhook( client, SDKHook_OnTakeDamage, OnTakeDamage );
}

/**
 * @note Handler for the Timer to set player HP values.
 * 
 * @param hTimer 		Handle for the timer
 * @param UserID		Client ID
 */
public Action TankSpawnTimer( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if( client == 0 || !IsTank( client ) || !IsClientInGame( client ) || !IsClientConnected( client ) ) return;
	
	static char sBuffer[64];
	hCvar_Difficult.GetString( sBuffer, sizeof( sBuffer ) );
	
	int ExtraSurvivors = bCvar_TankSurvivorMultipler ? ( GetSurvivorTeam() - 4 ) : GetSurvivorTeam();
	ExtraSurvivors = ( ExtraSurvivors > 0 ) ? ExtraSurvivors : 0;
	
	float TankHp_Multi = 1 + fCvar_TankHpMulti * ExtraSurvivors;
	int TankHP = RoundFloat( BasicTankHP * TankHp_Multi );
	
	if ( TankHP > 65535 ) TankHP = 65535;
	
	float TankBurnTime = float( TankHP ) * TankBurnIndex;
	int TankBurnHP = RoundToCeil( TankBurnTime );
	
	SetEntProp( client, Prop_Send, "m_iMaxHealth", TankHP );
	SetEntProp( client, Prop_Send, "m_iHealth", TankHP );
	
	/** 	Fix for when the Tank is burning	 **/
	
	if ( iCvar_IgnitionModes == NON_FLAMMABLE )
		SDKHook( client, SDKHook_OnTakeDamage, OnTakeDamage );
	
	if ( iCvar_IgnitionModes == FLAMMABLE && strncmp( sBuffer, "Easy", sizeof( sBuffer ), false ) == 0 ) FindConVar(bLeft4DeadTwo ? "tank_burn_duration" : "tank_burn_duration_normal").IntValue = TankBurnHP;
	else if ( iCvar_IgnitionModes == FLAMMABLE && strncmp( sBuffer, "Hard", sizeof( sBuffer ), false ) == 0 ) FindConVar("tank_burn_duration_hard" ).IntValue = TankBurnHP;
	else if ( iCvar_IgnitionModes == FLAMMABLE && strncmp( sBuffer, "Impossible", sizeof( sBuffer ), false ) == 0 ) FindConVar("tank_burn_duration_expert" ).IntValue = TankBurnHP;
	else if ( iCvar_IgnitionModes == FLAMMABLE ) FindConVar(bLeft4DeadTwo ? "tank_burn_duration" : "tank_burn_duration_normal").IntValue = TankBurnHP;
	
	switch( iCvar_EnabledAds ) 
	{
		case FULL_ADS: 
		{
			CPrintToChatAll( "'White'['Blue'%N'White'] Health 'Blue'%i", client, TankHP );
			
			if( iCvar_IgnitionModes == FLAMMABLE )
				CPrintToChatAll( "'White'['Red'%N'White'] Max Burning Time 'Orange'¡'Red'%i'Orange'!", client, TankBurnHP );
			else if( iCvar_IgnitionModes == NON_FLAMMABLE )
				CPrintToChatAll( "'White'['Red'%N'White'] Takes Fire Damage But Doesn't 'Orange'¡'Red'Burn'Orange'!", client );
		}
		case LIFE_STATUS:
		{
			CPrintToChatAll( "'White'['Blue'%N'White'] Health 'Blue'%i", client, TankHP );
		}
		case IGNITION_STATUS:
		{
			if( iCvar_IgnitionModes == FLAMMABLE )
				CPrintToChatAll( "'White'['Red'%N'White'] Max Burning Time 'Orange'¡'Red'%i'Orange'!", client, TankBurnHP );
			else if( iCvar_IgnitionModes == NON_FLAMMABLE )
				CPrintToChatAll( "'White'['Red'%N'White'] Takes Fire Damage But Doesn't 'Orange'¡'Red'Burn'Orange'!", client );
		}
	}
}

public Action OnTakeDamage( int client, int &attacker, int &inflictor, float &damage, int &damagetype )
{
	if( damage > 0.0 && IsValidClient( client ) && ( damagetype == DMG_BURN || damagetype == DMG_PREVENT_PHYSICS_FORCE + DMG_BURN || damagetype == DMG_DIRECT + DMG_BURN ) )
	{		
//		damage = 25.0;
		HurtTarget( attacker, 25.0, DMG_NERVEGAS, client );
//		return Plugin_Changed;
		return Plugin_Handled;
	}
	
//	return Plugin_Continue;
	return Plugin_Changed;
}

void HurtTarget( int attacker, float fDamage, int DMGType, int victim )
{
	if( victim > 0 /*&& attacker > 0*/ )
	{
		char sDamage[16];
		char sDMGType[16];
		FloatToString( fDamage, sDamage, sizeof( sDamage ));
		IntToString( DMGType, sDMGType, sizeof( sDMGType ));
		
		int PointHurt = CreateEntityByName( "point_hurt" );
		if( PointHurt )
		{
			DispatchKeyValue( victim, "targetname", "hurtme" );
			DispatchKeyValue( PointHurt, "DamageTarget", "hurtme" );
			DispatchKeyValue( PointHurt, "Damage", sDamage );
			DispatchKeyValue( PointHurt, "DamageType", sDMGType );
			DispatchKeyValue( PointHurt, "classname", "weapon_rifle" );
			DispatchSpawn( PointHurt );
			AcceptEntityInput( PointHurt, "Hurt",( attacker > 0 ) ? attacker : -1 );
			DispatchKeyValue( PointHurt, "classname", "point_hurt" );
			DispatchKeyValue( victim, "targetname", "donthurtme" );
			RemoveEdict( PointHurt );
		}
	}
}

public Action TimerUpdateHintTextHP( Handle hTimer )
{
	if( !IsServerProcessing() )
		return Plugin_Continue;

	if ( bCvar_Enabled && iCvar_DisplayHealth )
	{
		for ( int i = 1; i <= MaxClients; i ++ )
		{
			if ( IsClientInGame( i ) && GetClientTeam( i ) == 2 )
			{
				if ( !IsFakeClient( i ) )
				{
					int entity = GetClientAimTarget( i, false );
					if ( IsValidEntity( entity ) )
					{
						char sClassName[32];
						GetEdictClassname( entity, sClassName, sizeof( sClassName ) );
						if ( StrEqual( sClassName, "player", false ) )
						{
							if ( entity > 0 ) 
							{
								if ( IsTank( entity ) )
								{
									int Health = GetClientHealth( entity );
									int MaxHealth = GetEntProp( entity, Prop_Send, "m_iMaxHealth" ) & 0xFFFF;				
									float HealthStatus = float( Health ) / float( MaxHealth ) * 100.0;
									
									if( !IsPlayerIncapped( entity ) )
									{
										if ( iCvar_DisplayHealth == 1 ) 
										{
											PrintHintText( i, "%N [%d - 100 HP]", entity, RoundToCeil( HealthStatus ) );
										}
										else if ( iCvar_DisplayHealth == 2 )
										{
											PrintHintText( i, "%N [%d HP]", entity, Health );
										}
										else if ( iCvar_DisplayHealth == 3 ) 
										{
											PercentageBar( i, 30, MaxHealth, Health, entity);
										}
									}
									else if( IsPlayerIncapped( entity ) )
									{
										PrintHintText( i, "%N Is Dead", entity );
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

void PercentageBar( int client, int MaxBAR, int MaxHP, int NowHP, int Name )
{
	int Percent = RoundToCeil( ( float( NowHP ) / float( MaxHP ) ) * float( MaxBAR ) );
	int CharLength = 1;
	int i; 
	int Length = MaxBAR * CharLength + 2;
	char sShowBAR[256];
	char sBufferA[8] = "|";
	char sBufferB[8] = " "; // Subrayado
	
	sShowBAR[0] = '\0';
	
	for( i = 0; i < Percent && i < MaxBAR; i ++ ) 
		StrCat( sShowBAR, Length, sBufferA );
	
	for( ; i < MaxBAR; i ++ ) 
		StrCat( sShowBAR, Length, sBufferB );

	PrintHintText( client, "HP |-%s-| [%d / %d] %N", sShowBAR, NowHP, MaxHP, Name );
}

/**
 * @note Get the number of survivors on the team.
 *
 * @return 		Return the number of survivors.
 */
int GetSurvivorTeam()
{
	return GetTeamPlayers( TEAM_SURVIVOR, bCvar_TankIncludeBots );
}

/**
 * @note Get the number of players on the team.
 *
 * @param 		Team 			Team Index.
 * @param 		bIncludeBots 	Boolean index that determines whether to count bots or not.
 * @return 		Players 		return the number of players based on bIncludeBots.
 */
int GetTeamPlayers( int Team, bool bIncludeBots )
{
	int Players = 0;
	for ( int i = 1; i <= MaxClients; i ++ )
	{
		if ( IsClientInGame( i ) && GetClientTeam( i ) == Team && IsPlayerAlive( i ) )
		{
			if( IsFakeClient( i ) && !bIncludeBots )
				continue;
			
			if( GetIdlePlayer( i ) && !bIncludeBots )
				continue;
			
			Players ++;
		}
	}
	return Players;
}

stock int GetIdlePlayer( int bot )
{
	if ( IsClientInGame( bot ) && GetClientTeam( bot ) == TEAM_SURVIVOR && IsPlayerAlive( bot ) && IsFakeClient( bot ) )
	{
		char sNetClass[12];
		GetEntityNetClass( bot, sNetClass, sizeof( sNetClass ) );

		if ( strcmp( sNetClass, "SurvivorBot" ) == 0 )
		{
			int client = GetClientOfUserId( GetEntProp( bot, Prop_Send, "m_humanSpectatorUserID" ) );	
			if( client > 0 && IsClientInGame( client ) && GetClientTeam( client ) == TEAM_SPECTATOR )
			{
				return client;
			}
		}
	}
	
	return 0;
}

stock bool IsValidClient(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) )
		return true;
	
	return false;
}

stock bool IsPlayerIncapped( int client )
{
	if ( GetEntProp( client, Prop_Send, "m_isIncapacitated", 1 ) ) 
		return true;
		
	return false;
}

/**
 * @note Validates if the current client is valid.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */
stock bool IsTank( int client )
{
	if( client > 0 && client <= MaxClients && IsClientInGame( client ) && GetClientTeam( client ) == 3 )
		if( GetEntProp( client, Prop_Send, "m_zombieClass" ) == ( bLeft4DeadTwo ? 8 : 5 ) )
			return true;
	
	return false;
}

/**
 * @note Prints a message to a specific client in the chat area.
 * @note Supports color tags.
 *
 * @param client 		Client index.
 * @param sMessage 		Message (formatting rules).
 * @return 				No return
 * 
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChat( int client, const char[] sMessage, any ... )
{
	if ( client <= 0 || client > MaxClients )
		ThrowError( "Invalid client index %d", client );
	
	if ( !IsClientInGame( client ) )
		ThrowError( "Client %d is not in game", client );
	
	static char sBuffer[250];
	static char sCMessage[250];
	SetGlobalTransTarget(client);
	Format( sBuffer, sizeof( sBuffer ), "\x01%s", sMessage );
	VFormat( sCMessage, sizeof( sCMessage ), sBuffer, 3 );
	
	int index = CFormat( sCMessage, sizeof( sCMessage ) );
	if( index == NO_INDEX )
		PrintToChat( client, sCMessage );
	else
		CSayText2( client, index, sCMessage );
}

/**
 * @note Prints a message to all clients in the chat area.
 * @note Supports color tags.
 *
 * @param client		Client index.
 * @param sMessage 		Message (formatting rules)
 * @return 				No return
 */
stock void CPrintToChatAll( const char[] sMessage, any ... )
{
	static char sBuffer[250];
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame( i ) && !IsFakeClient( i ) )
		{
			SetGlobalTransTarget( i );
			VFormat( sBuffer, sizeof( sBuffer ), sMessage, 2 );
			CPrintToChat( i, sBuffer );
		}
	}
}

/**
 * @note Replaces color tags in a string with color codes
 *
 * @param sMessage    String.
 * @param maxlength   Maximum length of the string buffer.
 * @return			  Client index that can be used for SayText2 author index
 * 
 * On error/Errors:   If there is more then one team color is used an error will be thrown.
 */
stock int CFormat( char[] sMessage, int maxlength )
{	
	int iRandomPlayer = NO_INDEX;
	
	for ( int i = 0; i < MAX_COLORS; i++ )													//	Para otras etiquetas de color se requiere un bucle.
	{
		if ( StrContains( sMessage, CTag[i]) == -1 ) 										//	Si no se encuentra la etiqueta, omitir.
			continue;
		else if ( !CTagReqSayText2[i] )
			ReplaceString( sMessage, maxlength, CTag[i], CTagCode[i] ); 					//	Si la etiqueta no necesita Saytext2 simplemente reemplazará.
		else																				//	La etiqueta necesita Saytext2.
		{	
			if ( iRandomPlayer == NO_INDEX )												//	Si no se especificó un cliente aleatorio para la etiqueta, reemplaca la etiqueta y busca un cliente para la etiqueta.
			{
				iRandomPlayer = CFindRandomPlayerByTeam( CProfile_TeamIndex[i] ); 			//	Busca un cliente válido para la etiqueta, equipo de infectados oh supervivientes.
				if ( iRandomPlayer == NO_PLAYER ) 
					ReplaceString( sMessage, maxlength, CTag[i], CTagCode[5] ); 			//	Si no se encuentra un cliente valido, reemplasa la etiqueta con una etiqueta de color verde.
				else 
					ReplaceString( sMessage, maxlength, CTag[i], CTagCode[i] ); 			// 	Si el cliente fue encontrado simplemente reemplasa.
			}
			else 																			//	Si en caso de usar dos colores de equipo infectado y equipo de superviviente juntos se mandará un mensaje de error.
				ThrowError("Using two team colors in one message is not allowed"); 			//	Si se ha usadó una combinación de colores no validad se registrara en la carpeta logs.
		}
	}
	
	return iRandomPlayer;
}

/**
 * @note Founds a random player with specified team
 *
 * @param color_team  Client team.
 * @return			  Client index or NO_PLAYER if no player found
 */
stock int CFindRandomPlayerByTeam( int color_team )
{
	if ( color_team == SERVER_INDEX )
		return 0;
	else
		for ( int i = 1; i <= MaxClients; i ++ )
			if ( IsClientInGame( i ) && GetClientTeam( i ) == color_team )
				return i;

	return NO_PLAYER;
}

/**
 * @note Sends a SayText2 usermessage to a client
 *
 * @param sMessage 		Client index
 * @param maxlength 	Author index
 * @param sMessage 		Message
 * @return 				No return.
 */
stock void CSayText2( int client, int author, const char[] sMessage )
{
	Handle hBuffer = StartMessageOne( "SayText2", client );
	BfWriteByte( hBuffer, author );
	BfWriteByte( hBuffer, true );
	BfWriteString( hBuffer, sMessage );
	EndMessage();
}
