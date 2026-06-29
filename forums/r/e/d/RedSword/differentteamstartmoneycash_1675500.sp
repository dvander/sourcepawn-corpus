#pragma semicolon 1

#include <sdktools>

#define PLUGIN_VERSION	"1.0.0"

public Plugin:myinfo = 
{
	name = "Different Team Start Money/Cash",
	author = "RedSword / Bob Le Ponge",
	description = "Allows teams to get different start money (a different mp_startmoney for each team)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//ConVars
new Handle:g_hStartMoneyAlternate;
new Handle:g_hStartMoneyT;
new Handle:g_hStartMoneyCT;

//Prevent re-running a function
new g_iAccount; //Money of the player
new g_iAlternate;
new g_iBaseCash_T;
new g_iBaseCash_CT;

//===== Forwards

public OnPluginStart()
{
	//CVars
	CreateConVar( "differentteamstartmoneycashversion",  //yes, very long cvar =D
	PLUGIN_VERSION, 
	"Different Teams Start Money/Cash version", 
	FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_hStartMoneyAlternate = CreateConVar( "sm_startmoney_alternate",
	"2", 
	"Are CVars sm_startmoney_t and sm_startmoney_ct used instead of mp_startmoney ? 2=Yes (set mp_startmoney to 800), 1=Yes, 0=No. Def. 2", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 2.0 );
	
	g_hStartMoneyT = CreateConVar( "sm_startmoney_t",
	"1000", 
	"mp_startmoney value for terrorists. Def. 1000", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 800.0 );
	g_hStartMoneyCT = CreateConVar( "sm_startmoney_ct",
	"900", 
	"mp_startmoney value for CTs. Def. 900", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 800.0 );
	
	//Hooks event
	HookEvent( "player_team", Event_TeamChanged );
	HookEvent( "round_start", Event_RoundStart );
	
	//Hooks ConVarChanges
	g_iBaseCash_T = GetConVarInt( g_hStartMoneyT );
	g_iBaseCash_CT = GetConVarInt( g_hStartMoneyCT );
	g_iAlternate = GetConVarInt( g_hStartMoneyAlternate );
	HookConVarChange( g_hStartMoneyT, ConVarChange_BaseCashT );
	HookConVarChange( g_hStartMoneyCT, ConVarChange_BaseCashCT );
	HookConVarChange( g_hStartMoneyAlternate, ConVarChange_Alternate );
	
	//Prevent re-running functions
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
}

public OnConfigsExecuted()
{
	if ( g_iAlternate == 2 )
	{
		SetConVarInt( FindConVar( "mp_startmoney" ), 800 );
	}
}

//===== Events

public Action:Event_TeamChanged( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_iAlternate )
	{
		new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
		if ( iClient )
		{
			setClientTeamBaseCashIfBelow( iClient, GetEventInt( event, "team" ) ); //delay ?
		}
	}
	
	return Action:Plugin_Continue;
}

public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_iAlternate )
	{
		if ( GetTeamScore( 2 ) + GetTeamScore( 3 ) == 0 )
		{
			//First round, need to adjust everyone's cash (in case second restart)
			for ( new i = 1; i <= MaxClients; ++i )
			{
				if ( IsClientInGame( i ) )
				{
					setClientTeamBaseCashIfBelow( i, GetClientTeam( i ) ); //delay ?
				}
			}
		}
	}
	
	return Action:Plugin_Continue;
}

//===== ConVarChanges

public ConVarChange_BaseCashT(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iBaseCash_T = GetConVarInt( convar );
}
public ConVarChange_BaseCashCT(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iBaseCash_CT = GetConVarInt( convar );
}
public ConVarChange_Alternate(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iAlternate = GetConVarInt( convar );
	if ( g_iAlternate == 2 )
	{
		SetConVarInt( FindConVar( "mp_startmoney" ), 800 );
	}
}

//===== Privates

setClientTeamBaseCashIfBelow( iClient, iTeam )
{
	new iBaseCash;
	
	if ( iTeam == 2 )
	{
		iBaseCash = g_iBaseCash_T;
	}
	else if ( iTeam == 3 )
	{
		iBaseCash = g_iBaseCash_CT;
	}
	else
	{
		return;
	}
	
	if ( GetEntData( iClient, g_iAccount ) < iBaseCash )
	{
		//Have to delay this ?
		SetEntData( iClient, g_iAccount, iBaseCash );
	}
}