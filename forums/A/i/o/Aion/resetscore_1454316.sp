#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR    "tuty & Bacardi"
#define PLUGIN_VERSION    "1.2"
#pragma semicolon 1

new Handle:gPluginEnabled = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "ResetScore",
    author = PLUGIN_AUTHOR,
    description = "Type !resetscore in chat to reset your score.",
    version = PLUGIN_VERSION,
    url = "www.ligs.us"
};
public OnPluginStart()
{
    RegConsoleCmd( "say", CommandSay );
    RegConsoleCmd( "say_team", CommandSay );

    LoadTranslations("resetscore.phrases.txt");

    gPluginEnabled = CreateConVar( "sm_resetscore", "1" );
    CreateConVar( "resetscore_version", PLUGIN_VERSION, "Reset Score", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
}
public OnClientPutInServer(client)
{
    CreateTimer(15.0, TimerAnnounce, client);
}
public Action:TimerAnnounce(Handle:timer, any:client)
{
    if(IsClientInGame(client))
    {
        PrintToChat(client, "\x04[ResetScore]\x01 %t", "announce_chat");
    }
}
public Action:CommandSay( id, args )
{
    decl String:Said[ 128 ];
    GetCmdArgString( Said, sizeof( Said ) - 1 );
    StripQuotes( Said );
    TrimString( Said );

    if( StrEqual( Said, "!rs" ) || StrEqual( Said, "/resetscore" ) )
    {
        if( GetConVarInt( gPluginEnabled ) == 0 )
        {
            PrintToChat( id, "\x04[ResetScore]\x01 %t", "plugin_disabled_chat" );
            PrintToConsole( id, "[ResetScore] %t", "plugin_disabled_console");

            return Plugin_Continue;
        }

        if( !IsPlayerAlive( id ) )
        {
            PrintToChat( id, "\x04[ResetScore]\x01 %t", "player_dead_chat" );
            PrintToConsole( id, "[ResetScore] %t", "player_dead_console");

            return Plugin_Continue;
        }

        if( GetClientDeaths( id ) == 0 && GetClientFrags( id ) == 0 )
        {
            PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_already_chat");
            PrintToConsole( id, "[ResetScore] %t", "reset_already_console");

            return Plugin_Continue;
        }

        SetClientFrags( id, 0 );
        SetClientDeaths( id, 0 );

        decl String:Name[ 32 ];
        GetClientName( id, Name, sizeof( Name ) - 1 );

        PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_chat");

        decl String:mesg[100];
        Format(mesg,sizeof(mesg),"\x04[ResetScore]\x01 %t", "reset_chat_all", "\x03", Name, "\x01");
        new Handle:hBf = StartMessageAll("SayText2");
        if (hBf != INVALID_HANDLE)
        {
            BfWriteByte(hBf, id);
            BfWriteByte(hBf, true);
            BfWriteString(hBf, mesg);

            EndMessage();
        }
        PrintToConsole( id, "[ResetScore] %t", "reset_console" );
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