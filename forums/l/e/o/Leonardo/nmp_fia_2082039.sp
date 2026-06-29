#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3.9-20140911"
#define PLUGIN_SV_TAG "infinite_ammo"

#define PLUGIN_REPLY_PREFIX "[NMP-FIA] "


new Handle:nmp_fia_version = INVALID_HANDLE;
new Handle:nmp_fia_silent = INVALID_HANDLE;
new Handle:nmp_fia_for_all = INVALID_HANDLE;
new Handle:nmp_fia_no_reload = INVALID_HANDLE;
new Handle:nmp_fia_stamina = INVALID_HANDLE;
new Handle:nmp_fia_noinfect = INVALID_HANDLE;
new Handle:sv_max_stamina = INVALID_HANDLE;

new bool:bSilentAdmin = true;
new bool:bFIAForAll = false;
new bool:bFIAForAllCV = false;
new bool:bNoReload = false;
new Float:flMaxStamina = 130.0;
new Float:flStamina = -1.0;
new bool:bNIForAll = false;

new iAmmoOffset = -1;
new iClip1Offset = -1;

new Handle:hItemsData = INVALID_HANDLE;

new nFIAState[MAXPLAYERS+1] = { 0, ... };
new Float:flRateOfFire[MAXPLAYERS+1] = { 1.0, ... };
new Float:flFixStamina[MAXPLAYERS+1] = { -1.0, ... };
new bool:bNoInfect[MAXPLAYERS+1] = { false, ... };

new Float:flReloadTime[MAXPLAYERS+1] = { -1.0, ... };

public Plugin:myinfo = {
	name = "[NMRiH] Full Infinite Ammo",
	author = "Leonardo",
	description = "Unlimited ammo.",
	version = PLUGIN_VERSION,
	url = "http://www.xpenia.org/"
};


public OnPluginStart()
{
	LoadTranslations( "common.phrases.txt" );
	LoadTranslations( "nmp_fia.phrases.txt" );
	
	nmp_fia_version = CreateConVar( "nmp_fia_version", PLUGIN_VERSION, "NoMorePlugins Full Infinite Ammo", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD );
	SetConVarString( nmp_fia_version, PLUGIN_VERSION );
	HookConVarChange( nmp_fia_version, OnConVarChanged_Version );
	
	HookConVarChange( nmp_fia_silent = CreateConVar( "nmp_fia_silent", bSilentAdmin ? "1" : "0", "Hide admin activity.", FCVAR_PLUGIN, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_fia_for_all = CreateConVar( "nmp_fia_for_all", bFIAForAllCV ? "1" : "0", "Inifite ammo for everyone.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_fia_no_reload = CreateConVar( "nmp_fia_no_reload", bNoReload ? "1" : "0", "Inifite clip ammo.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( nmp_fia_stamina = CreateConVar( "nmp_fia_stamina", "-1", "Stamina for everyone. (-1 = disabled)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, -1.0 ), OnConVarChanged );
	HookConVarChange( nmp_fia_noinfect = CreateConVar( "nmp_fia_noinfect", bNIForAll ? "1" : "0", "No infection mode for everyone.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
	HookConVarChange( sv_max_stamina = FindConVar( "sv_max_stamina" ), OnConVarChanged );
	
	RegAdminCmd( "sm_fia", Command_ToggleFIA, ADMFLAG_CHEATS, "Usage: sm_fia <targets> <0-2>" );
	RegAdminCmd( "sm_rof", Command_SetROF, ADMFLAG_CHEATS, "Usage: sm_rof <targets> <1.0-10.0>" );
	RegAdminCmd( "sm_stamina", Command_SetStamina, ADMFLAG_CHEATS, "Usage: sm_stamina <targets> <float/-1>" );
	RegAdminCmd( "sm_ni", Command_ToggleNI, ADMFLAG_CHEATS, "Usage: sm_ni <targets> <0/1>" );
	RegAdminCmd( "sm_fia_reload", Command_ReloadConfig, ADMFLAG_ROOT );
	AddCommandListener( Command_DropItem, "dropitem" );
	
	iAmmoOffset = FindSendPropInfo( "CNMRiH_Player", "m_iAmmo" );
	iClip1Offset = FindSendPropInfo( "CNMRiH_WeaponBase", "m_iClip1" );
	
	new String:szFile[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, szFile, sizeof( szFile ), "data/nmrih_items_data.txt" );
	if( FileExists( szFile ) )
	{
		hItemsData = CreateKeyValues( "items_data" );
		if( !FileToKeyValues( hItemsData, szFile ) )
		{
			CloseHandle( hItemsData );
			hItemsData = INVALID_HANDLE;
		}
	}
	
	AutoExecConfig( true, "plugin.nmp_fia" );
}

public OnConfigsExecuted()
{
	flMaxStamina = GetConVarFloat( sv_max_stamina );
	for( new i = 0; i < sizeof( flFixStamina ); i++ )
		if( flFixStamina[i] > flMaxStamina )
			flFixStamina[i] = flMaxStamina;
	
	bNIForAll = GetConVarBool( nmp_fia_noinfect );
	flStamina = GetConVarFloat( nmp_fia_stamina );
	if( flStamina < 0.0 )
		flStamina = -1.0;
	if( flStamina > flMaxStamina )
		flStamina = flMaxStamina;
	
	bSilentAdmin = GetConVarBool( nmp_fia_silent );
	bNoReload = GetConVarBool( nmp_fia_no_reload );
	
	bFIAForAllCV = GetConVarBool( nmp_fia_for_all );
	
	new iFIACmdFlags;
	bFIAForAll = bFIAForAllCV || GetCommandOverride( "sm_fia", Override_Command, iFIACmdFlags ) && iFIACmdFlags == 0;
	ServerTag( PLUGIN_SV_TAG, bFIAForAll );
	if( bFIAForAll )
	{
		new iEntity;
		while( ( iEntity = FindEntityByClassname( iEntity, "item_ammo_box" ) ) != INVALID_ENT_REFERENCE )
			AcceptEntityInput( iEntity, "Kill" );
	}
}


public OnConVarChanged( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	OnConfigsExecuted();

public OnConVarChanged_Version( Handle:hConVar, const String:szOldValue[], const String:szNewValue[] )
	if( strcmp( szNewValue, PLUGIN_VERSION, false ) )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );


public OnEntityCreated( iEntity, const String:szClassname[] )
	if( StrEqual( szClassname, "item_ammo_box", false ) )
		SDKHook( iEntity, SDKHook_SpawnPost, Hook_OnAmmoBoxSpawn );

public Hook_OnAmmoBoxSpawn( iEntity )
{
	//new iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
	if( bFIAForAll /*|| 0 < iOwner <= MaxClients && nFIAState[iOwner]*/ )
		AcceptEntityInput( iEntity, "Kill" );
}


public Action:Command_ToggleFIA( iClient, nArgs )
{
	if( nArgs < 2 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_fia <targets> <0-2>", PLUGIN_REPLY_PREFIX );
		return Plugin_Handled;
	}
	
	new String:szBuffer[121];
	new iTargets[MAXPLAYERS], nTargets, String:szTargetName[MAX_NAME_LENGTH], bool:bTargetNameML;
	new nNewState;
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
	nNewState = StringToInt( szBuffer );
	if( nNewState < 0 )
		nNewState = 0;
	if( nNewState > 2 )
		nNewState = 2;
	
	for( new /*iEntity, iOwner,*/ i = 0; i < nTargets; i++ )
	{
		nFIAState[ iTargets[i] ] = nNewState;
		
		/*while( ( iEntity = FindEntityByClassname( iEntity, "item_ammo_box" ) ) != INVALID_ENT_REFERENCE )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iTargets[i] == iOwner )
				AcceptEntityInput( iEntity, "Kill" );
		}*/
		
		if( !bSilentAdmin && bTargetNameML )
			ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t", nNewState ? "NMP FIA Enabled 2" : "NMP FIA Disabled 2", iTargets[i] );
		LogAction( iClient, iTargets[i], nNewState ? "infinite ammo on" : "infinite ammo off" );
	}
	
	if( !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_REPLY_PREFIX, "%t %t", nNewState ? "NMP FIA Enabled" : "NMP FIA Disabled", szTargetName );
	
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
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
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
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
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
		flFixStamina[ iTargets[i] ] = flNewStamina;
		
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
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
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

public Action:Command_ReloadConfig( iClient, nArgs )
{
	new String:szFile[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, szFile, sizeof( szFile ), "data/nmrih_items_data.txt" );
	if( FileExists( szFile ) )
	{
		hItemsData = CreateKeyValues( "items_data" );
		if( !FileToKeyValues( hItemsData, szFile ) )
		{
			CloseHandle( hItemsData );
			hItemsData = INVALID_HANDLE;
			ReplyToCommand( iClient, "Invalid or empty config." );
		}
		else
			ReplyToCommand( iClient, "Done." );
	}
	else
		ReplyToCommand( iClient, "Missing config." );
	return Plugin_Handled;
}

public Action:Command_DropItem( iClient, const String:szCmd[], nArgs )
{
	/*if( 0 < iClient <= MaxClients && ( nFIAState[iClient] || bFIAForAllCV ) )
	{
		if( nArgs > 1 )
		{
			new String:szItem[6];
			GetCmdArg( 1, szItem, sizeof( szItem ) );
			if( !strcmp( szItem, "item_", false ) )
				return Plugin_Continue;
			
			//new iEntity = GetEntPropEnt( iClient, Prop_Send, "m_hActiveWeapon" );
			//if( iAmmoOffset > 0 && WeaponHasClip( iEntity ) && GetEntData( iClient, iAmmoOffset + GetEntProp( iEntity, Prop_Send, "m_iPrimaryAmmoType" ) * 4 ) > 0 )
			//	SetEntData( iClient, iAmmoOffset + GetEntProp( iEntity, Prop_Send, "m_iPrimaryAmmoType" ) * 4, 0, _, true );
		}
		return Plugin_Stop;
	}*/
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd( iClient, &iButtons, &iImpulse, Float:vecVelocity[3], Float:vecAngles[3], &iWeapon, &iWeaponSub, &nCommand, &nTick, &iRandomSeed, iMouseDir[2] )
{
	if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) && IsPlayerAlive( iClient ) )
	{
		new Float:flCurTime = GetGameTime();
		if( ( iButtons & IN_RELOAD ) && flReloadTime[iClient] < 0.0 )
			flReloadTime[iClient] = flCurTime;
		else if( !( iButtons & IN_RELOAD ) && flReloadTime[iClient] >= 0.0 )
		{
			if( ( flCurTime - flReloadTime[iClient] ) <= 0.5 )
			{
				new iEntity = GetEntPropEnt( iClient, Prop_Send, "m_hActiveWeapon" );
				new iClip = GetWeaponClipSize( iEntity );
				if( ( nFIAState[iClient] == 1 || bFIAForAllCV && !bNoReload ) && iAmmoOffset > 0 && WeaponHasClip( iEntity ) && iClip >= 1 )
				{
					new iAmmoType = GetEntProp( iEntity, Prop_Send, "m_iPrimaryAmmoType" );
					if( iClip1Offset > 0 )
						iClip -= GetEntData( iEntity, iClip1Offset );
					if( GetEntData( iClient, iAmmoOffset + iAmmoType * 4 ) < iClip )
						SetEntData( iClient, iAmmoOffset + iAmmoType * 4, iClip, _, true );
				}
			}
			flReloadTime[iClient] = -1.0;
		}
	}
	return Plugin_Continue;
}


public OnClientPutInServer( iClient )
{
	nFIAState[iClient] = 0;
	flRateOfFire[iClient] = 1.0;
	flFixStamina[iClient] = -1.0;
	bNoInfect[iClient] = false;
	
	flReloadTime[iClient] = -1.0;
}

public OnClientDisconnect( iClient )
	OnClientPutInServer( iClient );


public OnGameFrame()
{
	new iWeapon, iClip, iAmmoType, Float:flNextPrimaryAttack, Float:flNextSecondaryAttack, Float:flNextBashAttack, Float:flCurTime = GetGameTime();
	for( new i = 1; i <= MaxClients; i++ )
		if( IsClientInGame( i ) && IsPlayerAlive( i ) )
		{
			if( flStamina >= 0.0 || flFixStamina[i] >= 0.0 )
			{
				SetEntPropFloat( i, Prop_Send, "m_flStamina", flFixStamina[i] >= 0.0 ? flFixStamina[i] : flStamina );
				SetEntProp( i, Prop_Send, "_bleedingOut", 0 );
				SetEntProp( i, Prop_Send, "m_bSprintEnabled", 1 );
				SetEntProp( i, Prop_Send, "m_bGrabbed", 0 );
			}
			
			if( ( bNIForAll || bNoInfect[i] ) && GetEntPropFloat( i, Prop_Send, "m_flInfectionDeathTime" ) >= 0.0 )
			{
				SetEntPropFloat( i, Prop_Send, "m_flInfectionTime", flCurTime );
				SetEntPropFloat( i, Prop_Send, "m_flInfectionDeathTime", flCurTime + 60.0 );
			}
			
			if( nFIAState[i] >= 1 || flRateOfFire[i] != 1.0 )
			{
				iWeapon = GetEntPropEnt( i, Prop_Send, "m_hActiveWeapon" );
				if( IsValidEdict( iWeapon ) )
				{
					iClip = GetWeaponClipSize( iWeapon );
					if( iClip >= 1 )
					{
						if( iAmmoOffset > 0 && ( nFIAState[i] == 1 || bFIAForAllCV && !bNoReload ) && !WeaponHasClip( iWeapon, true ) )
						{
							iAmmoType = GetEntProp( iWeapon, Prop_Send, "m_iPrimaryAmmoType" );
							//if( iClip1Offset > 0 )
							//	iClip -= GetEntData( iWeapon, iClip1Offset );
							if( GetEntData( i, iAmmoOffset + iAmmoType * 4 ) < iClip )
								SetEntData( i, iAmmoOffset + iAmmoType * 4, iClip, _, true );
						}
						else if( iClip1Offset > 0 && ( nFIAState[i] >= 2 || bFIAForAllCV && bNoReload ) && 0 <= GetEntData( iWeapon, iClip1Offset ) < iClip )
							SetEntData( iWeapon, iClip1Offset, iClip, _, true );
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
}

stock bool:WeaponHasClip( iEntity, bool:bAndReload = false )
{
	if( !IsValidEdict( iEntity ) )
		return false;
	
	new String:szClassname[21];
	GetEdictClassname( iEntity, szClassname, sizeof( szClassname ) );
	
	if( !bAndReload && ( StrEqual( szClassname, "me_chainsaw" ) || StrEqual( szClassname, "bow_deerhunter" ) ) || StrEqual( szClassname, "tool_flare_gun" ) || StrContains( szClassname, "fa_" ) == 0 )
		return true;
	
	return false;
}

stock GetWeaponClipSize( iEntity )
{
	if( !IsValidEdict( iEntity ) )
		return -1;
	
	new String:szClassname[21];
	GetEdictClassname( iEntity, szClassname, sizeof( szClassname ) );
	
	if( hItemsData == INVALID_HANDLE )
	{
		if(
			StrEqual( szClassname, "tool_flare_gun" )
			|| StrEqual( szClassname, "tool_barricade" )
			|| StrContains( szClassname, "exp_" ) == 0
			|| StrEqual( szClassname, "bow_deerhunter" )
		)
			return 1;
		else if( StrEqual( szClassname, "fa_sv10" ) )
			return 2;
		else if(
			StrEqual( szClassname, "fa_sako85" )
			|| StrEqual( szClassname, "fa_superx3" )
		)
			return 5;
		else if( StrEqual( szClassname, "fa_sw686" ) )
			return 6;
		else if( StrEqual( szClassname, "fa_1911" ) )
			return 7;
		else if( StrEqual( szClassname, "fa_870" ) )
			return 8;
		else if(
			StrEqual( szClassname, "fa_1022" )
			|| StrEqual( szClassname, "fa_jae700" )
			|| StrEqual( szClassname, "fa_mkiii" )
			|| StrEqual( szClassname, "fa_sks" )
		)
			return 10;
		else if(
			StrEqual( szClassname, "fa_m92fs" )
			|| StrEqual( szClassname, "fa_winchester1892" )
		)
			return 15;
		else if( StrEqual( szClassname, "fa_glock17" ) )
			return 17;
		else if( StrEqual( szClassname, "fa_fnfal" ) )
			return 20;
		else if(
			StrEqual( szClassname, "fa_cz858" )
			|| StrEqual( szClassname, "fa_m16a4" )
			|| StrEqual( szClassname, "fa_mac10" )
			|| StrEqual( szClassname, "fa_mp5a3" )
		)
			return 30;
		else if( StrEqual( szClassname, "me_chainsaw" ) )
			return 100;
	}
	else
	{
		KvRewind( hItemsData );
		if( KvJumpToKey( hItemsData, "items" ) && KvGotoFirstSubKey( hItemsData ) )
		{
			new String:szBuffer[32];
			do
			{
				KvGetString( hItemsData, "classname", szBuffer, sizeof( szBuffer ) );
				if( StrEqual( szBuffer, szClassname, false ) )
					return KvGetNum( hItemsData, "clip" );
			}
			while( KvGotoNextKey( hItemsData ) );
		}
	}
	
	return 0;
}

stock bool:ServerTag( const String:szTag[], bool:bAdd = true )
{
	if( bFIAForAllCV || true )
		return false;
#if 0
	if( bAdd )
		AddServerTag( szTag );
	else
		RemoveServerTag( szTag );
	return true;
#else
	static Handle:sv_tags = INVALID_HANDLE;
	if( sv_tags == INVALID_HANDLE && ( sv_tags = FindConVar( "sv_tags" ) ) == INVALID_HANDLE )
		return false;
	new String:szBuffer[576], String:szOldTags[24][24], String:szNewTags[24][24];
	GetConVarString( sv_tags, szBuffer, sizeof( szBuffer ) );
	new nTags = ExplodeString( szBuffer, ",", szOldTags, sizeof( szOldTags ), sizeof( szOldTags[] ) );
	for( new n, o; o < nTags; o++ )
	{
		if( ++n >= sizeof( szOldTags ) || StrEqual( szOldTags[o], szTag, false ) )
		{
			if( bAdd ) return true;
			else continue;
		}
		strcopy( szNewTags[n], sizeof( szNewTags[] ), szOldTags[o] );
	}
	if( bAdd ) strcopy( szNewTags[0], sizeof( szNewTags[] ), szTag );
	ImplodeStrings( szNewTags, sizeof( szNewTags ), ",", szBuffer, sizeof( szBuffer ) );
	SetConVarString( sv_tags, szBuffer );
	return true;
#endif
}