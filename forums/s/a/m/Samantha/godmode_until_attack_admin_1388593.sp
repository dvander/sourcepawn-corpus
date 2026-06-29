#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define VERSION "1.0"

static bool:Godmode[MAXPLAYERS+1];

new Handle:c_RemovalType;

static g_Type = 1;

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

	HookConVarChange( c_RemovalType, ConvarChanged );
	
	HookEvent( "player_spawn", EventSpawn );
	HookEvent( "player_hurt", EventHurt );
}

public ConvarChanged(Handle:Convar, const String:OldValue[], const String:NewValue[])
{
	g_Type = StringToInt(NewValue);
}

public Action:EventSpawn(Handle:Event, const String:Name[], bool:dontBroadcast) 
{
	if( g_Type )
	{
		new Client = GetClientOfUserId(GetEventInt( Event, "userid" ));

		if( Client != 0 && IsClientInGame( Client ) )
		{
			if( GetUserFlagBits(Client) & (ADMFLAG_GENERIC|ADMFLAG_ROOT) )
			{
				Godmode[Client] = true;
				SetEntProp( Client, Prop_Data, "m_takedamage", 0);
				PrintToChat( Client, "[GUA] Godmode Enabled" );
			}
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