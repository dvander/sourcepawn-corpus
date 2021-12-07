#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

#define VERSION "1.1"

static bool:Godmode[MAXPLAYERS+1];

new Handle:c_RemovalType;
new Handle:c_RemoveOnTaunt;

static g_Type = 1;
static bool:g_RemoveOnTaunt = false;

public Plugin:myinfo =
{
	name = "|GUA| Godmode Until Attack",
	author = "Samantha",
	description = "Player has godmode until he attacks another player.",
	version = VERSION,
	url = "www.foxyden.com"
};

public OnPluginStart()
{
	CreateConVar( "sm_gua_version", VERSION, "Version of GUA", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	c_RemovalType = CreateConVar( "sm_gua_removaltype", "1", "1 - Removes godmode when a player hurts a player. 2 - Removes godmode when an attack key is pressed. - 0 Disabled", 0, true, 0.0, true, 2.0 );
	c_RemoveOnTaunt = CreateConVar( "sm_gua_removeontaunt", "0", "1 - Removes godmode when a player uses a killing taunt. - 0 Disabled", 0, true, 0.0, true, 1.0 );

	
	HookConVarChange( c_RemovalType, ConvarChanged );
	HookConVarChange( c_RemoveOnTaunt, ConvarChanged );
	
	HookEvent( "player_spawn", EventSpawn );
	HookEvent( "player_hurt", EventHurt );
	
	AddCommandListener( OnPlayerTaunt, "taunt" );
}

public ConvarChanged(Handle:Convar, const String:OldValue[], const String:NewValue[])
{
	if( Convar == c_RemovalType )
		g_Type = StringToInt(NewValue);
	else if( Convar == c_RemoveOnTaunt )
	{
		if( StringToInt( NewValue ) == 0 )
			g_RemoveOnTaunt = false;
		else 
			g_RemoveOnTaunt = true;
	}
}

public Action:EventSpawn(Handle:Event, const String:Name[], bool:dontBroadcast) 
{
	if( g_Type )
	{
		new Client = GetClientOfUserId(GetEventInt( Event, "userid" ));

		if( Client != 0 && IsClientInGame( Client ) )
		{
			Godmode[Client] = true;
			SetEntProp( Client, Prop_Data, "m_takedamage", 0);
			PrintToChat( Client, "[GUA] Godmode Enabled" );
		}
	}
	return Plugin_Handled;
}

public Action:EventHurt(Handle:Event, const String:Name[], bool:dontBroadcast) 
{
	if( g_Type == 1 )
	{
		new Client = GetClientOfUserId(GetEventInt( Event, "userid" ));
		new Attacker = GetClientOfUserId(GetEventInt( Event, "attacker" ));
		
		if( Godmode[Attacker] )
		{
			if( Client != 0 && IsClientInGame( Client ) )
			{
				if( Attacker != 0 && IsClientInGame( Attacker ) )
				{
					Godmode[Attacker] = false;
					SetEntProp( Attacker, Prop_Data, "m_takedamage", 2);
					PrintToChat( Client, "[GUA] Godmode Disabled" );
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd( Client, &Buttons, &Impulse, Float:Vel[3], Float:Angles[3], &Weapon)
{
	if( g_Type == 2 )
	{
		if( Godmode[Client] )
		{
			if( IsPlayerAlive(Client) )
			{
				if(Buttons & (IN_ATTACK|IN_ATTACK2) )
				{
					Godmode[Client] = false;
					SetEntProp( Client, Prop_Data, "m_takedamage", 2);
					PrintToChat( Client, "[GUA] Godmode Disabled" );
				}
			}
		}
	}
}

public Action:OnPlayerTaunt( Client, String:Command[], Args)
{
	if( Godmode[Client] && g_RemoveOnTaunt ) CreateTimer( 0.5, Timer_CheckTaunt, Client );
}

public Action:Timer_CheckTaunt( Handle:Timer, any:Client )
{
	if( TF2_IsPlayerTauntKilling( Client, true ) )
	{
		if( Godmode[Client] )
		{
			Godmode[Client] = false;
			SetEntProp( Client, Prop_Data, "m_takedamage", 2);
			PrintToChat( Client, "[GUA] Godmode Disabled" );
		}
	}
}

stock bool:TF2_IsPlayerTauntKilling(client, bool:healtaunts)
{
	new flags = TF2_GetPlayerConditionFlags(client);
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new idx;
	if (weapon != -1) idx = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	else return false;
	if ((flags & TF_CONDFLAG_TAUNTING)  && (idx == 4 || idx == 5 || idx == 12 || idx == 37 || idx == 39 || idx == 44 || idx == 56 || idx == 128 || idx == 132 || idx == 141 || idx == 143 || idx == 225 || (healtaunts && (idx == 35 || idx == 304))))
	{
		return true;
	}
	return false;
}