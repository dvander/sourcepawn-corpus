#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
    name = "AFK",
    author = "You Fake",
    description = "Say !afk to go spectator",
    version = PLUGIN_VERSION,
    url = "http://sourcemod.net"
}

// Globalne prikazy
new Handle:g_CvarSayafk = INVALID_HANDLE;

public OnPluginStart()
{
    CreateConVar( "afk_version", PLUGIN_VERSION, "Afk", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	g_CvarSayafk = CreateConVar("sm_sayafk", "1", "sayafkcement preferences");
	
    RegConsoleCmd( "say", AfkCommand );
	RegConsoleCmd( "say_team", AfkCommand );
	
	LoadTranslations("plugin.say_afk");
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
		PrintToChat(client, "\x03[\x01Afk\x03]\x01 %T", "to spect", client, name);
		Format(buffer, sizeof(buffer), "\x03[\x01Afk\x03]\x01 %T", "to spect", LANG_SERVER, name);
	}
}

public Action:Timersayafk(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		PrintToChat(client, "\x03[\x01Afk\x03]\x01 %T", "say afk");
	}
}