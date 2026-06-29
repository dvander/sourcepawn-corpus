#pragma semicolon			1

#include <sourcemod>
#include <tf2>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION			"1.2.0"
#define PLUGIN_DESCRIPTION	"Prevents players from damaging others through the gates during setup (including jarate/madmilk etc)"
#define ArenaRoundState_RoundRunning 7
#define MAX_MAP_ENTRIES		100
#define MAX_MAPNAME_LEN		64



// borrowed from RTD
enum eGameMode
{
	GameMode_Other=0,
	GameMode_Arena
};
new eGameMode:g_nGameMode;
//

enum g_eMapSettings
{
	String:g_sMapname[MAX_MAPNAME_LEN],
	bool:g_bAllowDmg,
	bool:g_bAllowCond
}
new g_nMapSettings[MAX_MAP_ENTRIES][g_eMapSettings];


new Handle:oz_hCvarEnabled;
new Handle:oz_hCvarAllowDmg;
new Handle:oz_hCvarAllowCond;



public Plugin:myinfo = {
	name = "[TF2] Gate Exploit Fix",
	author = "ozzeh (ozzeh@qq.com)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION
}


public OnPluginStart()
{
	// only run with TF2
	decl String:sGame[10];
	GetGameFolderName(sGame, sizeof(sGame));
	if( 0 != strcmp(sGame, "tf") ){
		SetFailState("This plugin will only run in TF2.");
		return;
	}
	
	// verify the map config exists
	new String:sMapConfig[200];
	BuildPath( Path_SM, sMapConfig, sizeof(sMapConfig), "configs/setupfix.cfg" );
	if( !FileExists( sMapConfig ) )
	{
		SetFailState( "Unable to load configs/setupfix.cfg" );
		return;
	}
	
	
	// - cvars -
	CreateConVar( "oz_setupfix_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	oz_hCvarEnabled		=	CreateConVar( "oz_setupfix_enabled",	"1",	"0/1 0=disabled,1=enabled. Enable plugin?" );
	oz_hCvarAllowDmg	=	CreateConVar( "oz_allowDmg",			"0",	"0/1 0=disabled,1=enabled. Allow players to take damage from other players during setup/waiting for players?" );
	oz_hCvarAllowCond	=	CreateConVar( "oz_allowCond", 			"0",	"0/1 0=disabled,1=enabled. Allow players to get madmilked, jarated etc. during setup/waiting for players?" );
	
	// - cmds -
	RegAdminCmd( "sm_setupfix_reload",	cmd_reloadconfig,	ADMFLAG_ROOT,	"Reloads the map settins config file." );
	

	// load map configs
	if( !LoadMapSettings() )
		return;
	
	// dmg hook
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}


public OnMapStart()
{
	// borrowed from rtd
	g_nGameMode = GameMode_Other;
	if(FindEntityByClassname(MaxClients+1, "tf_logic_arena") > MaxClients)
	{
		g_nGameMode = GameMode_Arena;
	}
	//
	
	decl String:currentmap[MAX_MAPNAME_LEN];
	GetCurrentMap( currentmap, sizeof(currentmap) );
	LogMessage( "Map settings for \"%s\": allowdmg=%d, allowcond=%d", currentmap, MapAllowsDmg(), MapAllowsCond() );
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

// Prevent users from taking damage from others during setup.
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype )
{
	if( !GetConVarBool(oz_hCvarEnabled) )
		return Plugin_Continue;
	
	
	
	// only when the round isn't active
	if( !IsRoundActive() )
	{
		// allow the player to damage themselves but not others
		if( attacker != victim && !MapAllowsDmg() ){
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if( !GetConVarBool(oz_hCvarEnabled) )
		return;
	
	if( !IsRoundActive() && !MapAllowsCond() )
	{
		// remove various conditions
		if( condition == TFCond:TFCond_Milked  ||
			condition == TFCond:TFCond_Jarated ||
			condition == TFCond:TFCond_OnFire  ||
			condition == TFCond:TFCond_Bonked  ||
			condition == TFCond:TFCond_Dazed
		)
		{
			TF2_RemoveCondition( client, condition );
		}
	}
}


bool:MapAllowsDmg()
{
	decl String:currentmap[MAX_MAPNAME_LEN];
	GetCurrentMap( currentmap, sizeof(currentmap) );
	
	
	for( new i=0; i<sizeof(g_nMapSettings); ++i )
	{
		if( 0 == strcmp( currentmap, g_nMapSettings[i][g_sMapname], false ) )
		{
			return g_nMapSettings[i][g_bAllowDmg];
		}
	}
	
	
	return GetConVarBool( oz_hCvarAllowDmg );
}

bool:MapAllowsCond()
{
	decl String:currentmap[MAX_MAPNAME_LEN];
	GetCurrentMap( currentmap, sizeof(currentmap) );
	
	
	for( new i=0; i<sizeof(g_nMapSettings); ++i )
	{
		if( 0 == strcmp( currentmap, g_nMapSettings[i][g_sMapname], false ) )
		{
			return g_nMapSettings[i][g_bAllowCond];
		}
	}
	
	
	return GetConVarBool( oz_hCvarAllowCond );
}


// borrowed and modified from RTD
bool:IsRoundActive()
{
	new RoundState:nRoundState = GameRules_GetRoundState();
	
	if( GameRules_GetProp("m_bInWaitingForPlayers", 1) ||
		GameRules_GetProp("m_bInSetup", 1) ||
		(g_nGameMode == GameMode_Arena && nRoundState != RoundState:ArenaRoundState_RoundRunning) ||
		(g_nGameMode == GameMode_Other && nRoundState != RoundState_RoundRunning && nRoundState != RoundState_Stalemate)
	)
	{
		return false;
	}

	return true;
}


bool:LoadMapSettings()
{
	new String:filepath[200];
	
	BuildPath( Path_SM, filepath, sizeof(filepath), "configs/setupfix.cfg" );
	if( !FileExists( filepath ) )
	{
		SetFailState( "Unable to load configs/setupfix.cfg" );
		return false;
	}
	
	
	new Handle:hKey = CreateKeyValues( "SetupFix" );
	if( FileToKeyValues( hKey, filepath ) && KvGotoFirstSubKey( hKey ) )
	{
		decl String:sSection[10];
		new iNumMaps;
		do
		{
			KvGetSectionName( hKey, sSection, sizeof(sSection) );
			new iIndex = StringToInt( sSection );
			
			if( iIndex < 0 || iIndex >= sizeof(g_nMapSettings) )
			{
				LogMessage( "Map Settings index \"%s\" not valid. Valid range is 0 to %d.", sSection, MAX_MAP_ENTRIES );
				continue;
			}
			
			KvGetString( hKey, "mapname", g_nMapSettings[iIndex][g_sMapname], MAX_MAPNAME_LEN );
			g_nMapSettings[iIndex][g_bAllowDmg]  = bool:KvGetNum( hKey, "allowdmg",  GetConVarInt(oz_hCvarAllowDmg)  );
			g_nMapSettings[iIndex][g_bAllowCond] = bool:KvGetNum( hKey, "allowcond", GetConVarInt(oz_hCvarAllowCond) );
			
			++iNumMaps;
			
		}while( KvGotoNextKey( hKey ) );
		
		if( hKey != INVALID_HANDLE )
			CloseHandle( hKey );
			
		LogMessage( "Loaded %d map configs.", iNumMaps );
		
		return true;
	}
	
	if( hKey != INVALID_HANDLE )
		CloseHandle( hKey );
	
	return false;
}


public Action:cmd_reloadconfig(client, args)
{
	if( !LoadMapSettings() )
		PrintToChat( client, "Failed to reload map settings file!" );
	else
		PrintToChat( client, "Successfully reloaded map settings file!" );
		
	return Plugin_Handled;
}