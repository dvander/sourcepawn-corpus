#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>

#define PLUGIN_VERSION "1.0.0-20140106"

#define PLUGIN_REPLY_PREFIX "[NMP-FIA] "


new Handle:nmp_fia_version = INVALID_HANDLE;
new Handle:nmp_fia_silent = INVALID_HANDLE;
new Handle:nmp_fia_for_all = INVALID_HANDLE;
new Handle:nmp_fia_no_reload = INVALID_HANDLE;
new Handle:sv_max_stamina = INVALID_HANDLE;

new bool:bSilentAdmin = true;
new bool:bFIAForAll = true;
new bool:bNoReload = false;
new Float:flMaxStamina = 130.0;

new iAmmoOffset = -1;
new iClip1Offset = -1;

new bool:bFIAState[MAXPLAYERS+1] = { false, ... };
new Float:flRateOfFire[MAXPLAYERS+1] = { 1.0, ... };
new Float:flStamina[MAXPLAYERS+1] = { -1.0, ... };
new bool:bNoInfect[MAXPLAYERS+1] = { false, ... };

public Plugin:myinfo = {
	name = "[NMRiH] Full Infinite Ammo",
	author = "Leonardo",
	description = "Unlimited ammo.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
};


public OnPluginStart()
{
	PluginManager_Initialize("nmp_fia", "[SM] ");
	LoadTranslations( "common.phrases.txt" );
	LoadTranslations( "nmp_fia.phrases.txt" );
	
	nmp_fia_version = CreateConVar( "nmp_fia_version", PLUGIN_VERSION, "NoMorePlugins Full Infinite Ammo", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
	SetConVarString( nmp_fia_version, PLUGIN_VERSION );
	AddCommandListener(CommandHook_DropItem,"dropitem");
	HookConVarChange( nmp_fia_version, OnConVarChanged_Version );
	HookConVarChange( nmp_fia_silent = CreateConVar( "nmp_fia_silent", bSilentAdmin ? "1" : "0", "Hide admin activity.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_fia_for_all = CreateConVar( "nmp_fia_for_all", bFIAForAll ? "1" : "0", "Inifite ammo for everyone.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_fia_no_reload = CreateConVar( "nmp_fia_no_reload", bNoReload ? "1" : "0", "Inifite clip ammo.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( sv_max_stamina = FindConVar( "sv_max_stamina" ), OnConVarChanged );
	
	RegAdminCmd( "sm_fia", Command_ToggleFIA, ADMFLAG_SLAY, "Usage: sm_fia <targets> <1/0>" );
	RegAdminCmd( "sm_rof", Command_SetROF, ADMFLAG_CHEATS, "Usage: sm_rof <targets> <1.0-10.0>" );
	RegAdminCmd( "sm_stamina", Command_SetStamina, ADMFLAG_CHEATS, "Usage: sm_stamina <targets> <float/-1>" );
	//RegAdminCmd( "sm_ni", Command_ToggleNI, ADMFLAG_CHEATS, "Usage: sm_ni <targets> <0/1>" ); // is not working
	
	iAmmoOffset = FindSendPropInfo( "CNMRiH_Player", "m_iAmmo" );
	iClip1Offset = FindSendPropInfo( "CNMRiH_WeaponBase", "m_iClip1" );
	AutoExecConfig(true, "nmp_fia");
	// Event Hooks
	PluginManager_HookEvent("nmrih_practice_ending",Event_Practice_Ending);
	PluginManager_HookEvent("nmrih_reset_map",Event_Reset_Map);
	PluginManager_HookEvent("player_death",Event_Player_Death);
	PluginManager_HookEvent("player_leave",Event_Player_Leave);
}

public OnConfigsExecuted()
{
	bSilentAdmin = GetConVarBool( nmp_fia_silent );
	bFIAForAll = GetConVarBool( nmp_fia_for_all );
	bNoReload = GetConVarBool( nmp_fia_no_reload );
	flMaxStamina = GetConVarFloat( sv_max_stamina );
	for( new i = 0; i < sizeof( flStamina ); i++ )
		if( flStamina[i] > flMaxStamina )
			flStamina[i] = flMaxStamina;
}


public OnConVarChanged( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	OnConfigsExecuted();

public OnConVarChanged_Version( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	if( strcmp( szNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );


public Action:Command_ToggleFIA( iClient, nArgs )
{
	if( nArgs < 2 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_fia <targets> <0/1>", PLUGIN_REPLY_PREFIX );
		return Plugin_Handled;
	}
	
	new String:szBuffer[121];
	new iTargets[MAXPLAYERS], nTargets, String:szTargetName[MAX_NAME_LENGTH], bool:bTargetNameML;
	new bool:bNewState;
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
	bNewState = !!StringToInt( szBuffer );
	
	for( new i = 0; i < nTargets; i++ )
	{
		bFIAState[ iTargets[i] ] = bNewState;
		
		if( !bSilentAdmin && bTargetNameML )
			ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t", bNewState ? "NMP FIA Enabled 2" : "NMP FIA Disabled 2", iTargets[i] );
		LogAction( iClient, iTargets[i], bNewState ? "infinite ammo on" : "infinite ammo off" );
	}
	
	if( !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t %t", bNewState ? "NMP FIA Enabled" : "NMP FIA Disabled", szTargetName );
	
	return Plugin_Handled;
}

public Action:Command_SetROF( iClient, nArgs )
{
	if( nArgs < 2 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_rof <targets> <1.0-10.0>", PLUGIN_REPLY_PREFIX );
		return Plugin_Handled;
	}
	
	new String:szBuffer[121];
	new iTargets[MAXPLAYERS], nTargets, String:szTargetName[MAX_NAME_LENGTH], bool:bTargetNameML;
	new Float:flRate;
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
	StringToFloatEx( szBuffer, flRate );
	if( flRate < 1.0 )
		flRate = 1.0;
	if( flRate > 10.0 )
		flRate = 10.0;
	
	for( new i = 0; i < nTargets; i++ )
	{
		flRateOfFire[ iTargets[i] ] = flRate;
		
		if( !bSilentAdmin && bTargetNameML )
			ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t", "NMP ROF Set 2", flRate, iTargets[i] );
		LogAction( iClient, iTargets[i], "rate of fire %f", flRate );
	}
	
	if( !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t %t", "NMP ROF Set", flRate, szTargetName );
	
	return Plugin_Handled;
}

public Action:Command_SetStamina( iClient, nArgs )
{
	if( nArgs < 2 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_stamina <targets> <float/-1>", PLUGIN_REPLY_PREFIX );
		return Plugin_Handled;
	}
	
	new String:szBuffer[121];
	new iTargets[MAXPLAYERS], nTargets, String:szTargetName[MAX_NAME_LENGTH], bool:bTargetNameML;
	new Float:flNewStamina;
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
	StringToFloatEx( szBuffer, flNewStamina );
	if( flNewStamina < 0.0 )
		flNewStamina = -1.0;
	if( flNewStamina > flMaxStamina )
		flNewStamina = flMaxStamina;
	
	for( new i = 0; i < nTargets; i++ )
	{
		flStamina[ iTargets[i] ] = flNewStamina;
		
		if( !bSilentAdmin && bTargetNameML )
			ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t", "NMP Stamina Set 2", flNewStamina, iTargets[i] );
		LogAction( iClient, iTargets[i], "set stamina to %f", flNewStamina );
	}
	
	if( !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t %t", "NMP Stamina Set", flNewStamina, szTargetName );
	
	return Plugin_Handled;
}

public Action:Command_ToggleNI( iClient, nArgs )
{
	if( nArgs < 2 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_ni <targets> <0/1>", PLUGIN_REPLY_PREFIX );
		return Plugin_Handled;
	}
	
	new String:szBuffer[121];
	new iTargets[MAXPLAYERS], nTargets, String:szTargetName[MAX_NAME_LENGTH], bool:bTargetNameML;
	new bool:bNewState;
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
	bNewState = !!StringToInt( szBuffer );
	
	for( new i = 0; i < nTargets; i++ )
	{
		bNoInfect[ iTargets[i] ] = bNewState;
		
		if( !bSilentAdmin && bTargetNameML )
			ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t", bNewState ? "NMP No Infection Enabled 2" : "NMP No Infection Disabled 2", iTargets[i] );
		LogAction( iClient, iTargets[i], bNewState ? "no infection on" : "no infection off" );
	}
	
	if( !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t %t", bNewState ? "NMP No Infection Enabled" : "NMP No Infection Disabled", szTargetName );
	
	return Plugin_Handled;
}


public OnClientPutInServer( iClient )
{
	bFIAState[iClient] = false;
	flRateOfFire[iClient] = 1.0;
	flStamina[iClient] = -1.0;
	bNoInfect[iClient] = false;
}

public OnClientDisconnect_Post( iClient )
	OnClientPutInServer( iClient );


public OnGameFrame()
{
	new iWeapon, String:szWeaponClassname[21], Float:flNextPrimaryAttack, Float:flNextSecondaryAttack, Float:flNextBashAttack;
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame( i ) && IsPlayerAlive( i ) )
		{
			if( flStamina[i] >= 0.0 )
			{
				SetEntPropFloat( i, Prop_Send, "m_flStamina", flStamina[i] );
				SetEntProp( i, Prop_Send, "_bleedingOut", 0 );
				SetEntProp( i, Prop_Send, "m_bSprintEnabled", 1 );
			}
			
			if( bNoInfect[i] )
			{
				SetEntPropFloat( i, Prop_Send, "m_flInfectionTime", -1.0 );
				SetEntPropFloat( i, Prop_Send, "m_flInfectionDeathTime", -1.0 );
			}
			
			
			iWeapon = GetEntPropEnt( i, Prop_Send, "m_hActiveWeapon" );
			if( IsValidEdict( iWeapon ) )
			{
				if( bFIAState[i] || bFIAForAll )
				{
					GetEdictClassname( iWeapon, szWeaponClassname, sizeof( szWeaponClassname ) );
					
					if( iAmmoOffset > 0 )
					SetEntData( i, iAmmoOffset + GetEntProp( iWeapon, Prop_Send, "m_iPrimaryAmmoType" ) * 4, ( StrContains( szWeaponClassname, "fa_", false ) == 0 ? 30 : 1 ), _, true );
					if( iClip1Offset > 0 && bNoReload && 0 <= GetEntData( iWeapon, iClip1Offset ) < 2 )
						SetEntData( iWeapon, iClip1Offset, 2, _, true );
				}
				
				if( flRateOfFire[i] > 1.0 )
				{
					SetEntPropFloat( iWeapon, Prop_Send, "m_flPlaybackRate", flRateOfFire[i] > 12.0 ? 12.0 : flRateOfFire[i] );
					
					flNextPrimaryAttack = GetEntPropFloat( iWeapon, Prop_Send, "m_flNextPrimaryAttack" ) - ( flRateOfFire[i] - 1.0 ) / 50.0;
					flNextSecondaryAttack = GetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack" ) - ( flRateOfFire[i] - 1.0 ) / 50.0;
					flNextBashAttack = GetEntPropFloat( iWeapon, Prop_Send, "m_flNextBashAttack" ) - ( flRateOfFire[i] - 1.0 ) / 50.0;
					
					SetEntPropFloat( iWeapon, Prop_Send, "m_flNextPrimaryAttack", flNextPrimaryAttack );
					SetEntPropFloat( iWeapon, Prop_Send, "m_flNextSecondaryAttack", flNextSecondaryAttack );
					SetEntPropFloat( iWeapon, Prop_Send, "m_flNextBashAttack", flNextBashAttack );
				}
			}
		}
}
public Action:CommandHook_DropItem(iClient, const String:command[], argc){

	PrintCenterText(iClient, "Ammo is auto-generated. Drop the weapon which uses this ammo first.");
	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}

public Action:Event_Practice_Ending(Handle:event, const String:name[], bool:dontBroadcast){
	
	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}

public Action:Event_Reset_Map(Handle:event, const String:name[], bool:dontBroadcast){

	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}

public Action:Event_Player_Leave(Handle:event, const String:name[], bool:dontBroadcast){

	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast){

	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}

stock RemoveAllAmmoBoxes(){ //thanks Chanz for this code
	
	static lastTime = 0;
	new theTime = GetTime();
	if(lastTime == theTime){
		return;
	}
	lastTime = theTime;
	
	new maxEntities = GetMaxEntities();
	
	for(new entity=MaxClients+1;entity<maxEntities;entity++){
		
		if(IsValidEdict(entity) && Entity_ClassNameMatches(entity,"item_ammo_box",true)){
			
			Entity_Kill(entity);
		}
	}
}