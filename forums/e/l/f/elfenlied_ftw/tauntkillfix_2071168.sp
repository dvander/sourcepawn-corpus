#pragma semicolon 1


#include <sourcemod>
#include <sdkhooks>
#include <sdktools>


#define PLUGIN_DESCRIPTION	"Prevent users from exploiting to high5/taunt kill glitch by nullifying damage."
#define PLUGIN_VERSION		"1.1"


new Handle:oz_hCvarEnabled;
new Handle:oz_hCvarKillSelf;

public Plugin:myinfo = {
	name = "[TF2] high5/taunt kill exploit fix",
	author = "ozzeh (ozzeh@qq.com)",
	version = PLUGIN_VERSION,
	description = PLUGIN_DESCRIPTION
}


public OnPluginStart()
{
	// - cvars -
	CreateConVar( "oz_tauntexploit_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY );
	oz_hCvarEnabled		=	CreateConVar( "oz_tauntkill_fix_enabled",	"1",	"0/1 0=disabled,1=enabled. Enable plugin?" );
	oz_hCvarKillSelf	=	CreateConVar( "oz_tauntkill_fix_killself",	"0",	"0/1 0=disabled,1=enabled. If enabled, the user will taunt kill him/herself while trying to exploit instead of killing others." );
	
	
	
	// dmg hook
	for( new i=1; i<=MaxClients; ++i )
	{
		if( IsClientInGame(i) )
		{
			SDKHook( i, SDKHook_OnTakeDamage, OnTakeDamage );
		}
	}
}

public OnClientPutInServer( client )
{
	SDKHook( client, SDKHook_OnTakeDamage, OnTakeDamage );
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:dmg, &dmgtype )
{
	if( GetConVarBool(oz_hCvarEnabled) && inflictor == attacker  && GetEntProp( attacker, Prop_Send, "m_bIsReadyToHighFive" ) != 0 )
	{
		// Kill yourself. Because I said so.
		if( GetConVarBool( oz_hCvarKillSelf ) )
		{
			//SDKHooks_TakeDamage( attacker, attacker, attacker, dmg, dmgtype  );
			ForcePlayerSuicide( attacker );
			return Plugin_Handled;
		}
		// ....or just nullify the damage
		else
		{
			dmg = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

