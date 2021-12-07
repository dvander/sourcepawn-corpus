#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR    "tuty/Comrade Bulkin/Bacardi"
#define PLUGIN_VERSION    "1.4"
#pragma semicolon 1

new Handle:gPluginEnabled = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "ResetScore (TeamServer Edition)",
    author = PLUGIN_AUTHOR,
    description = "Type !resetscore (!restartscore, !rs) in chat to reset your score.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=1812925#post1812925"
};

public OnPluginStart()
{
	RegConsoleCmd( "sm_resetscore", CommandSay );
	RegConsoleCmd( "sm_restartscore", CommandSay );
	RegConsoleCmd( "sm_rs", CommandSay );

	LoadTranslations("common.phrases");
	LoadTranslations("resetscore.phrases.txt");

	gPluginEnabled = CreateConVar( "sm_resetscore_enabled", "1" );
	CreateConVar( "rs_version", PLUGIN_VERSION, "Reset Score", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
}

public OnClientPutInServer(client)
{
    CreateTimer(15.0, TimerAnnounce, client);
}

// Message about plugin presense
public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		PrintToChat(client, "\x04[ResetScore]\x01 %t", "announce_chat");
	}
}

public Action:CommandSay( id, args )
{

	// Check if plugin is enabled
	if( GetConVarInt( gPluginEnabled ) == 0 )
	{
		PrintToChat( id, "\x04[ResetScore]\x01 %t", "plugin_disabled_chat" );
		PrintToConsole( id, "[ResetScore] %t", "plugin_disabled_console");

		return Plugin_Handled;
	}

	// Run the command only if client isnt using the server console
	if (id < 1)
	{
		PrintToServer("\x03[ResetScore] \x05%T", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;
	}
	else
	if ((!IsClientConnected(id)) || (!IsClientInGame(id)))
	{
		PrintToServer("[ResetScore] The player is not avilable anymore.");
		return Plugin_Handled;
	}
	else
	{
		if( GetClientDeaths( id ) == 0 && GetClientFrags( id ) == 0 )
		{
			PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_already_chat");
			PrintToConsole( id, "[ResetScore] %t", "reset_already_console");

			return Plugin_Handled;
		}

		SetClientFrags( id, 0 );
		SetClientDeaths( id, 0 );

		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );

		PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_success");

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

		PrintToConsole( id, "[ResetScore] %t", "reset_success" );
	}

	return Plugin_Handled;
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