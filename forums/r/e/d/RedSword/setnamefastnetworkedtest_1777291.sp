#include <sdktools>
#include <setname>

#pragma semicolon 1

#define PLUGIN_VERSION	"0.0.1T"
#define CS_SLOT_KNIFE 2

public Plugin:myinfo = 
{
	name = "Equip Player Weapon",
	author = "RedSword / Bob Le Ponge",
	description = "Getposition",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//new bool:g_bCanEvent;

new Handle:g_hConVarNbFrame;

//=====Forwards=====

public OnPluginStart()
{
	CreateConVar( "equipplayerweaponversion", PLUGIN_VERSION, "Get Position version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	g_hConVarNbFrame = CreateConVar( "sm_framenb", "15.0", "Number of frame before setting back name" );
	
	HookEvent( "player_death", Event_PlayerDeath_Pre, EventHookMode_Pre );
	//HookEvent( "player_death", Event_PlayerDeath_Post, EventHookMode_Post );
	HookEvent( "player_spawn", Event_PlayerSpawn, EventHookMode_Post );
	
	//g_bCanEvent = true;
}

new g_iHasBeenHandled[ MAXPLAYERS + 1 ];
new String:g_szKillerName[ 32 ];
new String:g_iKiller;

public Action:Event_PlayerDeath_Pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:tmpKillerName[ 32 ];
	
	new killerId = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	new victimId = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( g_iHasBeenHandled[ victimId ] == 0 )
	{
		//Change name ; append random name to killer name
		GetClientName( killerId, g_szKillerName, sizeof(g_szKillerName) );
		g_iKiller = killerId;
		
		FormatEx( tmpKillerName, sizeof(tmpKillerName), "%s + Potato", g_szKillerName );
		
		CS_SetClientName( killerId, tmpKillerName );
		
		//Do something to allow it :$ --> Victim
		g_iHasBeenHandled[ victimId ] = 1;
		return Action:Plugin_Handled;
	}
	return Action:Plugin_Continue;
}
//Didn't work ! =(
/*public Action:Event_PlayerDeath_Post(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killerId = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	new victimId = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( g_iHasBeenHandled[ victimId ] == 1 )
	{
		decl String:wpn[ 32 ];
		
		GetEventString( event, "weapon", wpn, sizeof(wpn) );
		
		//Fire event
		new Handle:event2 = CreateEvent("player_death");
		if (event2 == INVALID_HANDLE)
		{
			return Action:Plugin_Continue;
		}

		SetEventInt(event2, "userid", GetClientUserId(victimId));
		SetEventInt(event2, "attacker", GetClientUserId(killerId));
		//ASSIST : GetClientUserId(3) :D
		SetEventString(event2, "weapon", wpn);
		SetEventBool(event2, "headshot", GetEventBool( event, "headshot" ) );
		
		g_iHasBeenHandled[ victimId ] = 2;
		
		FireEvent(event2);
		
		//Reset name
		CS_SetClientName( killerId, g_szKillerName );
	}
	
	
	return Action:Plugin_Continue;
}*/
public OnGameFrame()
{
	new cvarValue = GetConVarInt( g_hConVarNbFrame );
	
	for (new i = 1; i <= MaxClients; ++i )
	{
		if ( g_iHasBeenHandled[ i ] == cvarValue )
		{
			//Fire event
			
			new Handle:event2 = CreateEvent("player_death");
			if (event2 == INVALID_HANDLE)
			{
				return;
			}

			SetEventInt(event2, "userid", GetClientUserId(i));
			SetEventInt(event2, "attacker", GetClientUserId(g_iKiller));
			//ASSIST : GetClientUserId(3) :D
			SetEventString(event2, "weapon", "");
			SetEventBool(event2, "headshot", true );
			
			g_iHasBeenHandled[ i ] = cvarValue + 1;
			
			FireEvent(event2);
			
			//Reset name
			CS_SetClientName( g_iKiller, g_szKillerName );
		}
	}
	
	//wait 1 frame
	for (new i = 1; i <= MaxClients; ++i )
	{
		if ( g_iHasBeenHandled[ i ] >= 1 && g_iHasBeenHandled[ i ] < cvarValue )
		{
			g_iHasBeenHandled[ i ]++;
		}
	}
}
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Reset name
	g_iHasBeenHandled[ GetClientOfUserId( GetEventInt( event, "userid" ) ) ] = 0;
}

/*public Action:OnPlayerRunCmd(iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ( IsFakeClient( iClient ) )
		return Plugin_Continue;
	
	if ( buttons & IN_USE && g_bCanEvent )
	{
		//0- Format buffer
		decl String:szOldKillerName[ 32 ];
		decl String:szNewKillerName[ 32 ];
		decl String:szAssistName[ 32 ];
		
		GetClientName( 2, szOldKillerName, sizeof(szOldKillerName) );
		strcopy( szNewKillerName, sizeof(szNewKillerName), szOldKillerName );
		
		GetClientName( 3, szAssistName, sizeof(szAssistName) );
		
		StrCat( szNewKillerName, sizeof(szNewKillerName), " + " );
		StrCat( szNewKillerName, sizeof(szNewKillerName), szAssistName );
		
		//1- Lets append to client 2's name, client 3' name
		CS_SetClientName( 2, szNewKillerName );
		
		
		new Handle:event = CreateEvent("player_death");
		if (event == INVALID_HANDLE)
		{
			return Plugin_Continue;
		}
	
		SetEventInt(event, "userid", GetClientUserId(1));
		SetEventInt(event, "attacker", GetClientUserId(2));
		//ASSIST : GetClientUserId(3) :D
		SetEventString(event, "weapon", "");
		SetEventBool(event, "headshot", true);
		FireEvent(event);
		
		CS_SetClientName( 2, szOldKillerName );

		CreateTimer( 1.0, PreventSpam );
		
		g_bCanEvent = false;
	}
	
	return Plugin_Continue;
}

public Action:PreventSpam(Handle:timer) //UserId used to prevent a possible problem if someone would leave and take bomber's "state" within 0.5 sec (lol)
{
	g_bCanEvent = true;
}*/