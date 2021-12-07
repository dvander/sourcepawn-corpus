#include < SourceMod >
#include < SDKHooks >

public Plugin:myinfo = {
	name        = "Game Description Changer",
	author      = "xPaw",
	description = "Changes game description to your own",
	version     = "1.0",
	url         = "http://xpaw.crannk.de"
};

new Handle:g_hName;

public OnPluginStart( )
	g_hName = CreateConVar( "sv_game_desc", "", "Sets game description" );

public Action:OnGetGameDescription( String:szGameDesc[ 64 ] ) {
	GetConVarString( g_hName, szGameDesc, 63 );
	
	return Plugin_Changed;
}