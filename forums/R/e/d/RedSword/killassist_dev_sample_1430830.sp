#include <killassist>

#pragma semicolon 1

#define PLUGIN_VERSION	"0.0.1T"

public Plugin:myinfo = 
{
	name = "Kill assist forward test",
	author = "RedSword / Bob Le Ponge",
	description = "Getposition",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
//=====Forwards=====

public OnPluginStart()
{
	CreateConVar( "Kill assist forward test version", PLUGIN_VERSION, "Kill assist forward test", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
}

public OnAssistedKill( const any:assisters[], const nbAssisters, const killerId, const victimId )
{
	PrintToChatAll( "%N killed %N being assisted by :", killerId, victimId );
	for ( new i; i < nbAssisters; ++i )
	{
		PrintToChatAll( "%N", assisters[ i ] );
	}
}