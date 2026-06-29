#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR	"Wanhelsing"
#define PLUGIN_VERSION	"1.5"
#pragma semicolon 1

new Handle:gPluginEnabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Resetskore",
	author = PLUGIN_AUTHOR,
	description = "Napiš !resetskore do chatu pro vynulovaní skore.",
	version = PLUGIN_VERSION,
	url = "css.darkruby.net"
};
public OnPluginStart()
{
	RegConsoleCmd( "say", CommandSay );
	RegConsoleCmd( "say_team", CommandSay );
	
	gPluginEnabled = CreateConVar( "sm_resetskore", "1" );
	CreateConVar( "resetscore_version", PLUGIN_VERSION, "Reset Score", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
}
public Action:CommandSay( id, args )
{
	decl String:Said[ 128 ];
	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	
	if( StrEqual( Said, "!resetskore" ) || StrEqual( Said, "!resetskore" ) )
	{
		if( GetConVarInt( gPluginEnabled ) == 0 )
		{
			PrintToChat( id, "\x03[SM Resetskore] Plugin vypnut." );
			PrintToConsole( id, "[SM Resetskore] Nelze pouitt kdyz je plugin vypnut." );
		
			return Plugin_Continue;
		}
	
		if( !IsPlayerAlive( id ) )
		{
			PrintToChat( id, "\x03[SM Resetskore] Nemuzes pouzit tento prikaz kdyz jsi mrtvi." );
			PrintToConsole( id, "[SM Resetskore] Pouze zivi hraci mohou  pouzivat tento prikaz." );
		
			return Plugin_Continue;
		}

		if( GetClientDeaths( id ) == 0 && GetClientFrags( id ) == 0 )
		{
			PrintToChat( id, "\x03[SM Resetskore] Uz mas skore 0!" );
			PrintToConsole( id, "[SM Resetskore] Momentalne nemuzes resetovat tvoje skore." );
			
			return Plugin_Continue;
		}
				
		SetClientFrags( id, 0 );
		SetClientDeaths( id, 0 );
	
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
	
		PrintToChat( id, "\x03[SM Resetskore] Uspesne sis resetoval skore!" );
		PrintToChatAll( "\x03[SM Resetskore] %s si vyresetoval sve skore.", Name );
		PrintToConsole( id, "[SM Resetskore] Uspesne sis resetoval skore." );
	}
	
	return Plugin_Continue;
}	 
stock SetClientFrags( index, frags )
{
	SetEntProp( index, Prop_Data, "m_iFrags", frags );
	return 1;
}
stock SetClientDeaths( index, deaths )
{
	SetEntProp( index, Prop_Data, "m_iDeaths", deaths );
	return 1;
}
