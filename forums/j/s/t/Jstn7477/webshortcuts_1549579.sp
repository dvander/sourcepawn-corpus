#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION				"1.0.1"

public Plugin:myinfo = 
{
	name = "Web Shortcuts",
	author = "James \"sslice\" Gray",
	description = "Provides chat-triggered web shortcuts",
	version = PLUGIN_VERSION,
	url = "http://www.steamfriends.com/"
};

new Handle:g_Shortcuts;
new Handle:g_Titles;
new Handle:g_Links;

new String:g_ServerIp [32];
new String:g_ServerPort [16];

public OnPluginStart()
{
	CreateConVar( "sm_webshortcuts_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_REPLICATED );
	
	RegConsoleCmd( "say", OnSay );
	RegConsoleCmd( "say_team", OnSay );
	
	g_Shortcuts = CreateArray( 32 );
	g_Titles = CreateArray( 64 );
	g_Links = CreateArray( 512 );
	
	new Handle:cvar = FindConVar( "hostip" );
	new hostip = GetConVarInt( cvar );
	FormatEx( g_ServerIp, sizeof(g_ServerIp), "%u.%u.%u.%u",
		(hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF );
	
	cvar = FindConVar( "hostport" );
	GetConVarString( cvar, g_ServerPort, sizeof(g_ServerPort) );
	
	LoadWebshortcuts();
}
 
public OnMapEnd()
{
	LoadWebshortcuts();
}
 
public Action:OnSay( client, args )
{
	decl String:text [512];
	GetCmdArgString( text, sizeof(text) );
	
	new start;
	new len = strlen(text);
	if ( text[len-1] == '"' )
	{
		text[len-1] = '\0';
		start = 1;
	}
	
	decl String:shortcut [32];
	BreakString( text[start], shortcut, sizeof(shortcut) );
	
	new size = GetArraySize( g_Shortcuts );
	for (new i; i != size; ++i)
	{
		GetArrayString( g_Shortcuts, i, text, sizeof(text) );
		
		if ( strcmp( shortcut, text, false ) == 0 )
		{
			decl String:title [64];
			decl String:steamId [64];
			decl String:userId [16];
			decl String:name [64];
			decl String:clientIp [32];
			
			GetArrayString( g_Titles, i, title, sizeof(title) );
			GetArrayString( g_Links, i, text, sizeof(text) );
			
			GetClientAuthString( client, steamId, sizeof(steamId) );
			FormatEx( userId, sizeof(userId), "%u", GetClientUserId( client ) );
			GetClientName( client, name, sizeof(name) );
			GetClientIP( client, clientIp, sizeof(clientIp) );
			
			ReplaceString( title, sizeof(title), "{SERVER_IP}", g_ServerIp);
			ReplaceString( title, sizeof(title), "{SERVER_PORT}", g_ServerPort);
			ReplaceString( title, sizeof(title), "{STEAM_ID}", steamId);
			ReplaceString( title, sizeof(title), "{USER_ID}", userId);
			ReplaceString( title, sizeof(title), "{NAME}", name);
			ReplaceString( title, sizeof(title), "{IP}", clientIp);
			
			ReplaceString( text, sizeof(text), "{SERVER_IP}", g_ServerIp);
			ReplaceString( text, sizeof(text), "{SERVER_PORT}", g_ServerPort);
			ReplaceString( text, sizeof(text), "{STEAM_ID}", steamId);
			ReplaceString( text, sizeof(text), "{USER_ID}", userId);
			ReplaceString( text, sizeof(text), "{NAME}", name);
			ReplaceString( text, sizeof(text), "{IP}", clientIp);
			
			ShowMOTDPanel( client, title, text, MOTDPANEL_TYPE_URL );
		}
	}
	
	return Plugin_Continue;	
}
 
LoadWebshortcuts()
{
	decl String:buffer [1024];
	BuildPath( Path_SM, buffer, sizeof(buffer), "configs/webshortcuts.txt" );
	
	if ( !FileExists( buffer ) )
	{
		return;
	}
 
	new Handle:f = OpenFile( buffer, "r" );
	if ( f == INVALID_HANDLE )
	{
		LogError( "[SM] Could not open file: %s", buffer );
		return;
	}
	
	ClearArray( g_Shortcuts );
	ClearArray( g_Titles );
	ClearArray( g_Links );
	
	decl String:shortcut [32];
	decl String:title [64];
	decl String:link [512];
	while ( !IsEndOfFile( f ) && ReadFileLine( f, buffer, sizeof(buffer) ) )
	{
		TrimString( buffer );
		if ( buffer[0] == '\0' || buffer[0] == ';' || ( buffer[0] == '/' && buffer[1] == '/' ) )
		{
			continue;
		}
		
		new pos = BreakString( buffer, shortcut, sizeof(shortcut) );
		if ( pos == -1 )
		{
			continue;
		}
		
		new linkPos = BreakString( buffer[pos], title, sizeof(title) );
		if ( linkPos == -1 )
		{
			continue;
		}
		
		strcopy( link, sizeof(link), buffer[linkPos+pos] );
		TrimString( link );
		
		PushArrayString( g_Shortcuts, shortcut );
		PushArrayString( g_Titles, title );
		PushArrayString( g_Links, link );
	}
	
	CloseHandle( f );
}
