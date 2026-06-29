/**
 * ==========================================================================
 * SourceMod Show The Right Next Map for CS:GO
 *
 * by PharaohsPaw
 *
 * SourceMod Forums Plugin Thread URL:
 * http://forums.alliedmods.net/showthread.php?t=195384
 *
 * A relatively simple plugin which intercepts and blocks CS:GO's own
 * "Next Map: <blah>" message it always shows at map end, and prints a
 * message that shows what *SOURCEMOD* thinks the next map is going to be
 * instead (since Sourcemod is right).
 *
 * Especially useful when a server is using SourceMod-based map voting and
 * "valve" map voting has been disabled, and possibly other situations.
 *
 * Without this plugin, CS:GO's own Next Map: message at map end will show
 * whatever map is listed next in the configured mapcyclefile -- yes, that's
 * right -- the configured mapcyclefile, not the next map in the mapgroup the
 * server is currently running.  So if a different map was voted in by a
 * Sourcemod voting plugin, or otherwise changed by Sourcemod, the Next Map:
 * message at the end of the map will show the wrong map name.  Even though
 * the server WILL correctly change the map to the one that got voted in.
 *
 * Hopefully this plugin will not even be necessary for long, but until this
 * is no longer a problem, here's a solution.
 *
 * CREDITS
 * Thanks to Psychonic for providing the event to hook and data to search for
 * to make this possible.
 * 
 */

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"

new UserMsg:g_TextMsg;
new String:SMNextMap[64];

public Plugin:myinfo =
{
	name = "CS:GO - Show The Right Next Map (STRNM)",
	author = "PharaohsPaw",
	description = "Replace CS:GO's end of map chat msg with what SM says the next map will be",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=195384"
}


public OnPluginStart()
{
	g_TextMsg = GetUserMessageId("TextMsg");
	HookUserMessage(g_TextMsg, pReplaceNextMapMsg, true);

	// public CVAR so we can tell how many servers are using this plugin and what version
	CreateConVar("csgo_strnm_version", PLUGIN_VERSION, "CSGO STRNM Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);

}

public Action:pReplaceNextMapMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	// message original?
	if (!reliable)
	{
		return Plugin_Continue;
	}

	decl String:message[256];

	BfReadString(bf, message, sizeof(message));
	if (StrContains(message, "#game_nextmap") != -1)
	{

		// Get SM's Next Map
		if ( GetNextMap(SMNextMap, sizeof(SMNextMap)) )
		{
			// Iterate through players, send real players a correct next map message
			for ( new i = 0; i < playersNum; i++ )
			{
				if ( !IsClientInGame(players[i]) || IsFakeClient(players[i]) )
				{
					continue;
				}
				else
				{
					// we can't PrintToChat() from a usermsg hook, it would create
					// an endless loop if it allowed it, so create a timer instead
					CreateTimer(0.1, pPrintNextMap, players[i]);
				}
			}

		}

		else	// GetNextMap call failed
		{

			PrintToServer("[csgo_strnm] GetNextMap() call failed :(");

		}

		return Plugin_Handled;

	}
	else
	{
		return Plugin_Continue;
	}
}

public Action:pPrintNextMap(Handle:timer, any:client)
{

	PrintToChat(client, "\x01 \x04[SourceMod] \x01Next Map: \x05%s", SMNextMap);

}
