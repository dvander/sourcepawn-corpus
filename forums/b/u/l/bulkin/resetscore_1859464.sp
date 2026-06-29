#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_AUTHOR    "Comrade Bulkin. Original by tuty, Bacardi."
#define PLUGIN_VERSION    "1.6.2"
#pragma semicolon 1


new Handle:gPluginEnabled = INVALID_HANDLE;
new Handle:printToAll  = INVALID_HANDLE;
new Handle:resetMoney  = INVALID_HANDLE;
new Handle:moneyAmount = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "ResetScore (TeamServer Edition)",
    author = PLUGIN_AUTHOR,
    description = "Type !resetscore (!restartscore, !rs) in chat to reset your score.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showpost.php?p=1813542&postcount=51"
};

public OnPluginStart()
{
	RegConsoleCmd( "sm_resetscore", CommandSay );
	RegConsoleCmd( "sm_restartscore", CommandSay );
	RegConsoleCmd( "sm_rs", CommandSay );

	LoadTranslations("common.phrases");
	LoadTranslations("resetscore.phrases.txt");
	
	CreateConVar( "rs_version", PLUGIN_VERSION, "Reset Score", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD );

	gPluginEnabled = CreateConVar( "sm_resetscore_enabled", "1", "Plugin enabled or not" );
	printToAll     = CreateConVar( "sm_resetscore_print_to_all", "1", "If this is '1' and player resets his score, then print to common chat. Else print to player chat only.");
	resetMoney     = CreateConVar( "sm_resetscore_reset_money", "1", "Reset player money or not" );
	moneyAmount    = CreateConVar( "sm_resetscore_money_on_reset", "800", "Amount of money given to player after Score reset" );

	AutoExecConfig(true, "resetscore");
}

// Announce plugin in 15 seconds after player connects
public OnClientPutInServer(client)
{
    // Check if plugin is enabled
	if( GetConVarInt( gPluginEnabled ) == 1 )
	{
    	CreateTimer(15.0, TimerAnnounce, client);
    }
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
	// GameName
	new String:GameType[20];
	GetGameFolderName(GameType, sizeof(GameType));

	// Check if plugin is enabled
	if( GetConVarInt( gPluginEnabled ) == 0 )
	{
		PrintToChat( id, "\x04[ResetScore]\x01 %t", "plugin_disabled_chat" );

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
	    // Check if the score is already equal to 0	
		if ( StrEqual(GameType, "csgo", false) )
		{
			if( GetClientDeaths(id) == 0 && GetClientFrags(id) == 0 
				&& CS_GetClientAssists(id) == 0 && CS_GetClientContributionScore(id) == 0)
			{
				PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_already_chat");
				return Plugin_Handled;
			}
			else
			{
				SetClientFrags( id, 0 );
				SetClientDeaths( id, 0 );
				SetClientMoney( id );
				CS_SetClientAssists( id, 0 );
				CS_SetClientContributionScore( id, 0 );
			}
		}
		else
		if ( StrEqual(GameType, "cstrike", false) )
		{
			if( GetClientDeaths(id) == 0 && GetClientFrags(id) == 0 )
			{
				PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_already_chat");
				return Plugin_Handled;
			}
			else
			{
				SetClientFrags( id, 0 );
				SetClientDeaths( id, 0 );
				SetClientMoney( id );
			}
		}
		else
		if ( StrEqual(GameType, "dod", false) )
		{
			if( GetClientDeaths(id) == 0 && GetClientFrags(id) == 0 
				&& GetEntProp(id, Prop_Send, "m_iAssists") == 0)
			{
				PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_already_chat");
				return Plugin_Handled;
			}
			else
			{
				SetClientFrags( id, 0 );
				SetClientDeaths( id, 0 );
				SetClientAssists( id, 0 );
			}
		}
		else
		{
			if( GetClientDeaths( id ) == 0 && GetClientFrags( id ) == 0 )
			{
				PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_already_chat");
				return Plugin_Handled;
			}
			else
			{
				SetClientFrags( id, 0 );
				SetClientDeaths( id, 0 );
			}
		}

		// Print to all or not
		if( GetConVarInt( printToAll ) == 1 )
		{
			PrintToChatAll("\x04[ResetScore]\x01 \x03%N\x01 %t", id, "reset_chat_all");
		}
		else
		{
			PrintToChat( id, "\x04[ResetScore]\x01 %t", "reset_success");
		}

		PrintToServer("[ResetScore] %N %t", id, "reset_success_log", LANG_SERVER);
	}

	return Plugin_Handled;
}


stock SetClientFrags( player, frags )
{
    SetEntProp( player, Prop_Data, "m_iFrags", frags );
    return 1;
}


stock SetClientDeaths( player, deaths )
{
    SetEntProp( player, Prop_Data, "m_iDeaths", deaths );
    return 1;
}

stock SetClientAssists( player, assists )
{
    SetEntProp(player, Prop_Send, "m_iAssists", assists);
    return 1;
}

stock SetClientMoney( player )
{
    if( GetConVarInt(resetMoney) == 1 )
    {
    	new setMoneyAmount;
    	setMoneyAmount = GetConVarInt(moneyAmount);

		//Reset money only if player has more, than set in moneyAmount
    	if ( setMoneyAmount < GetEntProp(player, Prop_Send, "m_iAccount") )
    	{
    		SetEntProp(player, Prop_Send, "m_iAccount", setMoneyAmount);
    	}
    }
    return 1;
}