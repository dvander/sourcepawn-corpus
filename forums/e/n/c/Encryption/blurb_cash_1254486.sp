#include <sourcemod>
#include <sdktools>

new g_iAccount = -1;
new Handle:Switch;
new Handle:Cash;

public Plugin:myinfo = 
{
	name = "Blurb Cash",
	author = "Encryption",
	description = "Gives cash when players say a phrase.",
	version = "1.0",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	Switch = CreateConVar("blurb_cash_enabled","1","1 enabled 0 is disabled.",FCVAR_NOTIFY);
	Cash = CreateConVar("blurb_cash_amount","16000","Amount to give.",FCVAR_NOTIFY);
	RegConsoleCmd( "say", CommandSay );
	RegConsoleCmd( "say_team", CommandSay );
}

public Action:CommandSay( client, args )
{
	decl String:Said[ 128 ];
	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	if( StrEqual( Said, "its my money and i need it now!" ) || StrEqual( Said, "i need my green!" ))
	{
		SetMoney(client,GetConVarInt(Cash));
	}
	return Plugin_Continue;
}	 

public SetMoney(client, amount)
{
	if (g_iAccount != -1)
	{
		SetEntData(client, g_iAccount, amount);
	}	
}