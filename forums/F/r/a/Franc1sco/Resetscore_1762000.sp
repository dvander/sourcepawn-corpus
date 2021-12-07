#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_AUTHOR   "tuty, Otstrel.ru team"
#define PLUGIN_VERSION  "1.1.otstrel.2"
#pragma semicolon 1

new Handle:gPluginEnabled = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Resetscore",
    author = PLUGIN_AUTHOR,
    description = "Type !resetscore in chat to reset your score.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=96270"
};
public OnPluginStart()
{
    LoadTranslations("resetscore");

    RegConsoleCmd( "say", CommandSay );
    RegConsoleCmd( "say_team", CommandSay );
    
    gPluginEnabled = CreateConVar( "sm_resetscore", "1" );
    CreateConVar( "resetscore_version", PLUGIN_VERSION, "Reset Score", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
}
public Action:CommandSay( id, args )
{
    if(!id || !IsClientInGame(id))  // added by Fran1sco Franug
          return Plugin_Continue;   //


    decl String:Said[ 128 ];
    GetCmdArgString( Said, sizeof( Said ) - 1 );
    StripQuotes( Said );
    TrimString( Said );
    
    if( id && StrEqual( Said, "!rs" ) || StrEqual( Said, "!resetscore" ) || StrEqual( Said, "!restartscore" ) )
    {
        if( GetConVarInt( gPluginEnabled ) == 0 )
        {
            CPrintToChat( id, "%t", "The plugin is disabled." );
        
            return Plugin_Continue;
        }
    
        if( GetClientDeaths( id ) == 0 && GetClientFrags( id ) == 0 )
        {
            CPrintToChat( id, "%t", "Your score is already 0!" );

            return Plugin_Continue;
        }
                
        SetClientFrags( id, 0 );
        SetClientDeaths( id, 0 );
    
        decl String:Name[ 32 ];
        GetClientName( id, Name, sizeof( Name ) - 1 );
    
        CPrintToChatAllEx( id, "%t", "%s has just reseted his score.", Name );
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
