#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#tryinclude <tf2pyroairjump>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.2.2"

new Handle:sm_tf2paj_version = INVALID_HANDLE;
new Handle:sm_tf2paj_enabled = INVALID_HANDLE;
new Handle:sm_tf2paj_prethink = INVALID_HANDLE;
new Handle:tf_flamethrower_burst_zvelocity = INVALID_HANDLE;

new bool:bPluginEnabled = true;
new bool:bOnPreThink = false;
new Float:flZVelocity = 0.0;

new Float:flNextSecondaryAttack[MAXPLAYERS+1];

new Handle:fwOnPyroAirBlast = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "[TF2] Pyro Airblast Jump",
	author = "Leonardo",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
}

public APLRes:AskPluginLoad2(Handle:hMySelf, bool:bLate, String:strError[], iMaxErrors)
{
    RegPluginLibrary( "tf2pyroairjump" );
    return APLRes_Success;
}

public OnPluginStart()
{
	sm_tf2paj_version = CreateConVar("sm_tf2paj_version", PLUGIN_VERSION, "TF2 Pyro Airblast Jump plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(sm_tf2paj_version, PLUGIN_VERSION, true, true);
	HookConVarChange(sm_tf2paj_version, OnConVarChanged_PluginVersion);
	
	sm_tf2paj_enabled = CreateConVar("sm_tf2paj_enabled", "1", "", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(sm_tf2paj_enabled, OnConVarChanged);
	
	sm_tf2paj_prethink = CreateConVar("sm_tf2paj_prethink", "0", "Use OnPreThink instead of OnGameFrame?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(sm_tf2paj_prethink, OnConVarChanged);
	
	decl String:strGameDir[8];
	GetGameFolderName( strGameDir, sizeof(strGameDir) );
	if( !StrEqual( strGameDir, "tf", false ) && !StrEqual( strGameDir, "tf_beta", false ) )
		SetFailState( "THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!" );
	
	tf_flamethrower_burst_zvelocity = FindConVar( "tf_flamethrower_burst_zvelocity" );
	
	fwOnPyroAirBlast = CreateGlobalForward( "TF2_OnPyroAirBlast", ET_Event, Param_Cell );
	
	for( new i = 0; i <= MAXPLAYERS; i++ )
	{
		flNextSecondaryAttack[i] = GetGameTime();
		if( IsValidClient(i) )
		{
			if( bOnPreThink )
				SDKHook( i, SDKHook_PreThink, OnPreThink );
			SDKHook( i, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost );
		}
	}
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );
public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

public OnConfigsExecuted()
{
	bPluginEnabled = GetConVarBool( sm_tf2paj_enabled );
	bOnPreThink = GetConVarBool( sm_tf2paj_prethink );
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient( i ) )
		{
			if( bOnPreThink )
				SDKHook( i, SDKHook_PreThink, OnPreThink );
			else
				SDKUnhook( i, SDKHook_PreThink, OnPreThink );
		}
	flZVelocity = GetConVarFloat( tf_flamethrower_burst_zvelocity );
}

public OnClientPutInServer( iClient )
{
	flNextSecondaryAttack[iClient] = GetGameTime();
	if( bOnPreThink )
		SDKHook( iClient, SDKHook_PreThink, OnPreThink );
	SDKHook( iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost );
}

public OnGameFrame()
{
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient( i ) )
			OnPreThink( i );
}

public OnPreThink( iClient )
{
	if( !IsPlayerAlive(iClient) )
		return;
	
	if( TF2_GetPlayerClass(iClient) != TFClass_Pyro )
		return;

	new iNextTickTime = RoundToNearest( FloatDiv( GetGameTime() , GetTickInterval() ) ) + 5;
	SetEntProp( iClient, Prop_Data, "m_nNextThinkTick", iNextTickTime );
	
	new Float:flSpeed = GetEntPropFloat( iClient, Prop_Send, "m_flMaxspeed" );
	if( flSpeed > 0.0 && flSpeed < 5.0 )
		return;
	
	if( GetEntProp( iClient, Prop_Data, "m_nWaterLevel" ) > 1 )
		return;
	
	if( (GetClientButtons(iClient) & IN_ATTACK2) != IN_ATTACK2 )
		return;

	new iWeapon = GetEntPropEnt( iClient, Prop_Send, "m_hActiveWeapon" );
	if( !IsValidEntity(iWeapon) )
		return;
	
	decl String:strClassname[32];
	GetEntityClassname( iWeapon, strClassname, sizeof(strClassname) );
	if( !StrEqual( strClassname, "tf_weapon_flamethrower", false ) )
		return;
	
	if( ( GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" ) - flNextSecondaryAttack[iClient] ) <= 0.0 )
		return;
	flNextSecondaryAttack[iClient] = GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" );
	
	//PrintToChat( iClient, "%0.1f", GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" ) - flNextSecondaryAttack[iClient] );
	//PrintToChat( iClient, "%0.1f %0.1f %0.1f", GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" ), flNextSecondaryAttack[iClient], GetGameTime() );
	
	decl Action:result;
	Call_StartForward( fwOnPyroAirBlast );
	Call_PushCell( iClient );
	Call_Finish( result );
	if( result == Plugin_Handled || result == Plugin_Stop )
		return;
	
	if( (GetEntityFlags(iClient) & FL_ONGROUND) == FL_ONGROUND )
		return;
	
	if( !bPluginEnabled )
		return;
	
	decl Float:vecAngles[3], Float:vecVelocity[3];
	GetClientEyeAngles( iClient, vecAngles );
	GetEntPropVector( iClient, Prop_Data, "m_vecVelocity", vecVelocity );
	vecAngles[0] = DegToRad( -1.0 * vecAngles[0] );
	vecAngles[1] = DegToRad( vecAngles[1] );
	vecVelocity[0] -= flZVelocity * Cosine( vecAngles[0] ) * Cosine( vecAngles[1] );
	vecVelocity[1] -= flZVelocity * Cosine( vecAngles[0] ) * Sine( vecAngles[1] );
	vecVelocity[2] -= flZVelocity * Sine( vecAngles[0] );
	TeleportEntity( iClient, NULL_VECTOR, NULL_VECTOR, vecVelocity );
}

public OnWeaponSwitchPost( iClient, iWeapon )
{
	if( !IsValidClient(iClient) || !IsPlayerAlive(iClient) || !IsValidEntity(iWeapon) )
		return;
	
	decl String:strClassname[32];
	GetEntityClassname( iWeapon, strClassname, sizeof(strClassname) );
	if( !StrEqual( strClassname, "tf_weapon_flamethrower", false ) )
		return;
	
	flNextSecondaryAttack[iClient] = GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" );
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}