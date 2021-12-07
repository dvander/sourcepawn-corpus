#pragma semicolon 1

#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo =
{
	name = "MvM Share Cash",
	author = "Th13teen",
	description = "Give your cash to other players in MvM",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{
	RegConsoleCmd( "gm", Command_give_mvm_money );
	RegConsoleCmd( "givemoney", Command_give_mvm_money );
}

public Action:Command_give_mvm_money( client, args )
{
	if ( client == -1 )
	{
		return Plugin_Handled;
	}
	
	if ( GetCmdArgs() < 2 )
	{
		PrintToChat( client, "Usage: /givemoney <Name> <Ammount>" );
		return Plugin_Handled;
	}
	
	new String:targetCmd[MAX_NAME_LENGTH];
	GetCmdArg( 1, targetCmd, MAX_NAME_LENGTH );
	
	new String:ammountCmd[5];
	GetCmdArg( 2, ammountCmd, 5 );
	
	new ammountConverted = StringToInt( ammountCmd, 10 );
	
	new target = FindTarget( -1, targetCmd );
	
	if ( target == -1 )
	{
		PrintToChat( client, "No player found!" );
		return Plugin_Handled;
	}
	
	if ( GetEntProp( target, Prop_Send, "m_nCurrency" ) + ammountConverted > 30000 )
	{
		PrintToChat( client, "You cannot send this much, The player would have too much!" );
		return Plugin_Handled;
	}
	
	if ( GetEntProp( client, Prop_Send, "m_nCurrency" ) - ammountConverted < 0 )
	{
		PrintToChat( client, "You cannot send this much, You dont have enough!" );
		return Plugin_Handled;
	}
	
	if ( ammountConverted < 1 )
	{
		PrintToChat( client, "You must send more than $0!" );
		return Plugin_Handled;
	}
	
	if ( GetClientTeam( client ) == GetClientTeam( target ) )
	{
		SetEntProp( target, Prop_Send, "m_nCurrency", GetEntProp( target, Prop_Send, "m_nCurrency" ) + ammountConverted );
		SetEntProp( client, Prop_Send, "m_nCurrency", GetEntProp( client, Prop_Send, "m_nCurrency" ) - ammountConverted );
	}else{
		return Plugin_Handled;
	}
	
	new String:senderName[MAX_NAME_LENGTH];
	GetClientName( client, senderName, MAX_NAME_LENGTH );
	
	new String:targetName[MAX_NAME_LENGTH];
	GetClientName( target, targetName, MAX_NAME_LENGTH );
	
	PrintToChatAll( "\x03%s\x01 has given $%d to \x03%s", senderName, ammountConverted, targetName );
	return Plugin_Handled;
}