#include <sourcemod>

#define PLUGIN_VERSION "1.0"

#define FFADE_IN            0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT           0x0002        // Fade out (not in)
#define FFADE_MODULATE      0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT       0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE         0x0010        // Purges all other fades, replacing them with this one

new Handle:g_hFadeDuration;

public Plugin:myinfo = 
{
	name = "Spawn Fade",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Fades player's screen in after spawn",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	CreateConVar("sm_spawnfade_version", PLUGIN_VERSION, "Spawn Fade version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hFadeDuration = CreateConVar("sm_spawnfade_duration", "5", "How long should the screen be faded out in seconds?", FCVAR_PLUGIN, true, 0.0);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(0.1, Timer_Blind, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Blind(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new Float:duration = GetConVarFloat(g_hFadeDuration);
		if(duration == 0.0)
		{
			CreateTimer(0.1, Timer_Unfade, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			new Handle:hFadeClient = StartMessageOne("Fade", client);
			BfWriteShort(hFadeClient, 1);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration
			BfWriteShort(hFadeClient, 1);		// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration until reset (fade & hold)
			BfWriteShort(hFadeClient, (FFADE_PURGE|FFADE_OUT|FFADE_STAYOUT)); // fade type (in / out)
			BfWriteByte(hFadeClient, 0);	// fade red
			BfWriteByte(hFadeClient, 0);	// fade green
			BfWriteByte(hFadeClient, 0);	// fade blue
			BfWriteByte(hFadeClient, 255);	// fade alpha
			EndMessage();

			CreateTimer(duration, Timer_Unfade, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_Unfade(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(!IsPlayerAlive(client))
			return Plugin_Handled;
		
		new Handle:hFadeClient = StartMessageOne("Fade", client);
		BfWriteShort(hFadeClient, 800);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration
		BfWriteShort(hFadeClient, 800);		// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, seconds duration until reset (fade & hold)
		BfWriteShort(hFadeClient, (FFADE_PURGE|FFADE_IN|FFADE_STAYOUT)); // fade type (in / out)
		BfWriteByte(hFadeClient, 0);	// fade red
		BfWriteByte(hFadeClient, 0);	// fade green
		BfWriteByte(hFadeClient, 0);	// fade blue
		BfWriteByte(hFadeClient, 255);	// fade alpha
		EndMessage();
	}
	return Plugin_Handled;
}