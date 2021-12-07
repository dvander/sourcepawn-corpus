#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "Ghostfade",
	author = "MistaGee, TnTSCS",
	description = "Fades players' screen when there is another player with the same IP",
	version = "1.1b",
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	HookEvent(	"player_death",	Event_PlayerDeath );
	HookEvent(	"round_start",	Event_RoundStart,	EventHookMode_PostNoCopy	);
}

#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

/**
 * Fades a client's screen to a specified color
 * Your adviced to read the FFADE_ Comments
 *
 * @param client		Player for which to fade the screen
 * @param duration		duration in seconds the effect stays
 * @param mode			fade mode, see FFADE_ defines
 * @param holdtime		holdtime in seconds
 * @param r				red amount
 * @param g				green amount
 * @param b				blue amount
 * @param a				transparency
 * @return				True on success, false otherwise
 */
stock bool:Client_ScreenFade(client, duration, mode, holdtime=-1, r=0, g=0, b=0, a=255, bool:reliable=true)
{
	new Handle:userMessage = StartMessageOne("Fade", client, (reliable?USERMSG_RELIABLE:0));
	
	if (userMessage == INVALID_HANDLE) {
		return false;
	}

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available &&
		GetUserMessageType() == UM_Protobuf) {

		new color[4];
		color[0] = r;
		color[1] = g;
		color[2] = b;
		color[3] = a;

		PbSetInt(userMessage,   "duration",   duration);
		PbSetInt(userMessage,   "hold_time",  holdtime);
		PbSetInt(userMessage,   "flags",      mode);
		PbSetColor(userMessage, "clr",        color);
	}
	else {
		BfWriteShort(userMessage,	duration);	// Fade duration
		BfWriteShort(userMessage,	holdtime);	// Fade hold time
		BfWriteShort(userMessage,	mode);		// What to do
		BfWriteByte(userMessage,	r);			// Color R
		BfWriteByte(userMessage,	g);			// Color G
		BfWriteByte(userMessage,	b);			// Color B
		BfWriteByte(userMessage,	a);			// Color Alpha
	}
	EndMessage();
	
	return true;
}

public Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	// Loop through specters to find ghosts
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsClientObserver(i) )
		{
			findGhostsForClient(i);
		}
	}
}

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
	new theClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	findGhostsForClient( theClient );
}
	
void:findGhostsForClient( theClient )
{
	new String:theClientIP[16];
	GetClientIP( theClient, theClientIP, sizeof(theClientIP) );
	
	new String:refClientIP[16];
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		// Look for an alive player...
		if( theClient != i && IsClientInGame(i) && IsPlayerAlive(i) )
		{
			GetClientIP( i, refClientIP, sizeof(refClientIP) );
			// who's sitting on the same IP
			if( StrEqual( theClientIP, refClientIP ) )
			{
				// There's an alive player on the same IP, so the dead one
				// could tell the alive one what's going on - fade them to prevent
				//SendFadeMsgOut( theClient );
				Client_ScreenFade(theClient, 1000, FFADE_OUT, -1);
				Client_HideRadar(theClient);
				
				// Tell them what's up
				PrintToChat( theClient, "[SM] Your screen has been faded for ghosting on the same IP (%s) with %N.", theClientIP, i );
				
				// A single fading is enough
				break;
			}
		}
	}
}

Client_HideRadar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}
#if 0
Client_ShowRadar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.5);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}
#endif