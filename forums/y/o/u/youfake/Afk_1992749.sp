#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
    name = "AFK",
    author = "You Fake",
    description = "Say !afk to go spectator",
    version = PLUGIN_VERSION,
    url = "http://sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_afk_version", PLUGIN_VERSION, "Afk Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
   	CreateConVar("sm_sayafk_enabled", "1", "0 = disabled",FCVAR_PLUGIN,true,0.0,false);
   	
	LoadTranslations("plugin.say_afk");
	
	RegConsoleCmd( "say", AfkCommand ); RegConsoleCmd( "say_team", AfkCommand );
}

public Action:AfkCommand( client, args )
{
	decl String:Said[ 128 ];
	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	
	if( StrEqual( Said, "!afk" ) || StrEqual( Said, "!spect" ) )
	{
		ChangeClientTeam(client, 1);
		
		new String:name[32], String:buffer[128];
		GetClientName(client, name, sizeof(name));
		PrintToChat(client, "\x03[\x01Afk\x03]\x01 %t", "to spect", client, name);
		Format(buffer, sizeof(buffer), "\x03[\x01Afk\x03]\x01 %t", "to spect", LANG_SERVER, name);
	}
}

public Action:Timersayafk(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		PrintToChat(client, "\x03[\x01Afk\x03]\x01 %t", "say afk");
	}
}