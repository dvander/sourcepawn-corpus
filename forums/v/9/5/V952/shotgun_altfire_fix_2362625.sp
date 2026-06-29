#include <sourcemod>

public OnPluginStart()
{
	CreateConVar( "rls_shotgun_fix_version", "1.0.0.0", "This cvar is here for tracking plugin usage.", FCVAR_NOTIFY );
}

public Plugin:myinfo =
{
	name = "Shotgun AltFire Fix",
	author = "V952",
	description = "Fixes shotgun double attack lagcompensation.",
	version = "1.0.0.0",
	url = "http://hl2mp.net/"
}

public Action:OnPlayerRunCmd( client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon )
{
	decl String:szWeaponClass[32];
	new m_hActiveWeapon = GetEntPropEnt( client, Prop_Send, "m_hActiveWeapon" );
	
	if ( m_hActiveWeapon != -1 && GetEdictClassname( m_hActiveWeapon, szWeaponClass, sizeof( szWeaponClass ) ) && !strcmp( szWeaponClass, "weapon_shotgun" ) && ( buttons & IN_ATTACK2 ) == IN_ATTACK2 )
		buttons |= IN_ATTACK;
	
	return Plugin_Continue;
}
