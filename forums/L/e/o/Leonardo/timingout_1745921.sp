#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0.3"

#define TOA_EFFECT_RENDERFX	(1<<0)
#define TOA_EFFECT_GODMODE	(1<<1)

new Handle:sm_toa_version = INVALID_HANDLE;
new Handle:sm_toa_enabled = INVALID_HANDLE;
new Handle:sm_toa_renderfx = INVALID_HANDLE;
new Handle:sm_toa_godmode = INVALID_HANDLE;

new bool:bEnabled = false;
new bool:bRenderFx = false;
new bool:bGodMode = false;

new bool:bTimedOut[MAXPLAYERS+1];
new iEffects[MAXPLAYERS+1];
new RenderFx:iOldRenderFx[MAXPLAYERS+1];
new iOldGodMode[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Timing Out Announce",
	author = "Leonardo",
	description = "Note everyone that player is timing out...",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	sm_toa_version = CreateConVar( "sm_toa_version", PLUGIN_VERSION, "Timing Out Announce plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED );
	SetConVarString( sm_toa_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_toa_version, OnConVarChanged_PluginVersion );
	
	sm_toa_enabled = CreateConVar( "sm_toa_enabled", "1", "", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_toa_enabled, OnConVarChanged );
	
	sm_toa_renderfx = CreateConVar( "sm_toa_renderfx", "0", "Change RenderFx when timing out.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_toa_renderfx, OnConVarChanged );
	
	sm_toa_godmode = CreateConVar( "sm_toa_godmode", "0", "Set godmode when timing out.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_toa_godmode, OnConVarChanged );
	
	for( new i = 1; i <= MaxClients; i++ )
		ResetData( i );
}

public OnPluginEnd()
{
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) && bTimedOut[i] )
			SetTimingOutEffects( i, false );
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
{
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );
}

public OnConVarChanged(Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
{
	OnConfigsExecuted();
}

public OnConfigsExecuted()
{
	bEnabled = GetConVarBool( sm_toa_enabled );
	bRenderFx = GetConVarBool( sm_toa_renderfx );
	bGodMode = GetConVarBool( sm_toa_godmode );
}

public OnGameFrame()
{
	new bool:bTimingOut;
	
	for( new i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) )
		{
			bTimingOut = IsClientTimingOut(i);
			
			if( !bEnabled && bTimedOut[i] )
			{
				SetTimingOutEffects( i, false );
				continue;
			}
			
			if( bTimedOut[i] != bTimingOut )
			{
				bTimedOut[i] = bTimingOut;
				TimingOutStatusMsg( i, bTimingOut );
			}
			
			SetTimingOutEffects( i, bTimingOut );
		}
		else
			ResetData( i );
}

ResetData( iClient )
{
	if( iClient < 0 || iClient > MAXPLAYERS )
		return;
	
	bTimedOut[iClient] = false;
	iEffects[iClient] = 0;
	iOldRenderFx[iClient] = RENDERFX_NONE;
	iOldGodMode[iClient] = 2;
}

TimingOutStatusMsg( iClient, bool:iTimingOut )
{
	if( !IsValidClient(iClient) )
		return;
	
	if( iTimingOut )
	{
		PrintToChatAll( "\x03%N\x01 is timing out!", iClient );
		LogMessage( "\x03%N\x01 is timing out.", iClient );
	}
	else
	{
		PrintToChatAll( "\x03%N\x01 is back!", iClient );
		LogMessage( "\x03%N\x01 is no longer timing out.", iClient );
	}
}

SetTimingOutEffects( iClient, bool:bEnable )
{
	if( !IsValidClient(iClient) )
		return;
	
	if( bEnable )
	{
		if( bRenderFx && !ContainsBits( iEffects[iClient], TOA_EFFECT_RENDERFX ) )
		{
			iOldRenderFx[iClient] = GetEntityRenderFx( iClient );
			SetEntityRenderFx( iClient, RENDERFX_DISTORT );
			AddBits( iEffects[iClient], TOA_EFFECT_RENDERFX );
		}
		if( bGodMode && !ContainsBits( iEffects[iClient], TOA_EFFECT_GODMODE ) )
		{
			iOldGodMode[iClient] = GetEntProp( iClient, Prop_Data, "m_takedamage", 1 );
			SetEntProp( iClient, Prop_Data, "m_takedamage", 0, 1 );
			AddBits( iEffects[iClient], TOA_EFFECT_GODMODE );
		}
	}
	else
	{
		if( ContainsBits( iEffects[iClient], TOA_EFFECT_RENDERFX ) )
		{
			SetEntityRenderFx( iClient, iOldRenderFx[iClient] );
			RemoveBits( iEffects[iClient], TOA_EFFECT_RENDERFX );
		}
		if( ContainsBits( iEffects[iClient], TOA_EFFECT_GODMODE ) )
		{
			SetEntProp( iClient, Prop_Data, "m_takedamage", iOldGodMode[iClient], 1 );
			RemoveBits( iEffects[iClient] , TOA_EFFECT_GODMODE );
		}
	}
}

stock AddBits( &iSum, iBits )
{
	iSum |= iBits;
}
stock RemoveBits( &iSum, iBits )
{
	iSum &= ~iBits;
}
stock ContainsBits( iSum, iBits )
{
	return ( iSum & iBits ) == iBits;
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	if( !IsClientInGame(iClient) ) return false;
	return !IsFakeClient(iClient);
}