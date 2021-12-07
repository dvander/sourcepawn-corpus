#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "No hurt no medic"
#define PLUGIN_AUTHOR "Psychonic, idea Snelvuur"
#define PLUGIN_DESCRIPTION "If your not below 100% health, you cannot call for medic"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=204703"

public Plugin:myinfo = {
        name = PLUGIN_NAME,
        author = PLUGIN_AUTHOR,
        description = PLUGIN_DESCRIPTION,
        version = PLUGIN_VERSION,
        url = PLUGIN_URL
};

new Handle:fnGetMaxHealth;
const MEDIC_VOICE_MENU = 0;
const MEDIC_VOICE_SUBMENU = 0;
public OnPluginStart()
{
        new Handle:hConf = LoadGameConfigFile( "sdkhooks.games" );
        if( hConf == INVALID_HANDLE )
        {
                SetFailState( "Cannot find sdkhooks.games gamedata" );
        }

        StartPrepSDKCall( SDKCall_Entity );
        PrepSDKCall_SetFromConf( hConf, SDKConf_Virtual, "GetMaxHealth" );
        PrepSDKCall_SetReturnInfo( SDKType_PlainOldData, SDKPass_Plain );
        fnGetMaxHealth = EndPrepSDKCall();

        if( fnGetMaxHealth == INVALID_HANDLE )
        {
                SetFailState( "Failed to set up GetMaxHealth sdkcall" );
        }

        CloseHandle( hConf );
        AddCommandListener( voicemenu, "voicemenu" );
}

public Action:voicemenu( client, const String:szCommand[], argc )
{
        if( client == 0 || !IsClientInGame( client ) )
                return Plugin_Continue;

        new String:szBuffer[16];

        GetCmdArg( 1, szBuffer, sizeof(szBuffer) );
        if( StringToInt( szBuffer ) != MEDIC_VOICE_MENU )
                return Plugin_Continue;

        GetCmdArg( 2, szBuffer, sizeof(szBuffer) );
        if( StringToInt( szBuffer ) != MEDIC_VOICE_SUBMENU )
                return Plugin_Continue;

        new maxHealth = SDKCall( fnGetMaxHealth, client );
        new health = GetEntProp( client, Prop_Send, "m_iHealth" );
        if( health < maxHealth )
                return Plugin_Continue;

        return Plugin_Handled;
}
