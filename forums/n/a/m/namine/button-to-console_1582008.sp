#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <cstrike>
 
 
#define VERSION "1.0"
 
public Plugin:myinfo =
{
	name = "Button Spam Preventer - CSS",
	author = "Silence",
	description = "Logs button presses to console.",
	version = VERSION,
	url = "www.xenogamers.org"
};
 
public OnMapStart()
{
	CreateTimer( 1.0, Hook_Buttons );
}
 
public Action:Hook_Buttons( Handle:Timer )
{
	HookEntityOutput( "func_button" , "OnPressed", ButtonPressed );
}
 
public ButtonPressed( const String:Output[], Caller, Activator, Float:Delay )
{
	if( Activator > 0 ) 
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if( IsClientInGame(i) ) 
			{
				if( CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT) || GetClientTeam(i) == CS_TEAM_CT )
				{
					PrintToConsole( i, "[BUTTOM SPAM] %N pressed a button.", Activator );
				}
			}
		}
	}
}
 
public OnMapEnd()
{
	UnhookEntityOutput( "func_button" , "OnPressed", ButtonPressed );
}
 