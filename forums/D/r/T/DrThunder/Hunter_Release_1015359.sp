#define PLUGIN_VERSION "1.0"
#define MAX_PLAYERS 256
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "L4D2 Hunter Release",
	author = "DR_Thunder",
	description = "Allows Hunter to release a pounce after a set time.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

new Handle:HunterCrouch[MAX_PLAYERS+1];
new Handle:HunterRelease[MAX_PLAYERS+1];
new Handle:NoClipRelease[MAX_PLAYERS+1];
new StoredID;

public OnPluginStart()
{	
	HookEvent("lunge_pounce", EventPounce);
	HookEvent("pounce_end",   EventPounceStop);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Pre);	
	HookEvent("round_start", EventRoundStart);
	HookEvent("player_spawn", PlayerHasSpawned);
}


Hunter_Crouch_Press(HunterID)
{
	HunterCrouch[HunterID] = CreateTimer(0.25, HunterCrouchPress, HunterID, TIMER_REPEAT);
}

public Action:HunterCrouchPress(Handle:timer, any:HunterID)
{
	new buttons = GetClientButtons(HunterID);

	if (buttons & IN_USE)
	{
		OnPlayerRelease(HunterID)
		return Plugin_Stop
	}
	return Plugin_Continue
}

Hunter_Release_Timer(HunterID)
{
	HunterRelease[HunterID] = CreateTimer(4.0, HunterReleaseTimer, HunterID);
}

public Action:HunterReleaseTimer(Handle:timer, any:HunterID)
{
	Hunter_Crouch_Press(HunterID);	
}

public Action:EventRoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	KillTimer(HunterRelease[StoredID]);
	KillTimer(HunterCrouch[StoredID]);
}

public Action:PlayerHasSpawned(Handle:event, String:event_name[], bool:dontBroadcast)
{
	KillTimer(HunterRelease[StoredID]);
	KillTimer(HunterCrouch[StoredID]);
}

public Action:EventRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	KillTimer(HunterRelease[StoredID]);
	KillTimer(HunterCrouch[StoredID]);
}

public Action:EventPlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	KillTimer(HunterRelease[StoredID]);
	KillTimer(HunterCrouch[StoredID]);
}

public Action:EventPounceStop(Handle:event, String:event_name[], bool:dontBroadcast)
{
	KillTimer(HunterRelease[StoredID]);
	KillTimer(HunterCrouch[StoredID]);
}

public Action:EventPounce(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	StoredID = client;	
	PrintToChat(client, "Release the pounce by hitting USE key. Must wait 4 seconds");
	Hunter_Release_Timer(client);
}


NoClip_Timer(client)
{
	NoClipRelease[client] = CreateTimer(0.01, NoClipTimer, client);
}

public Action:NoClipTimer(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);	
}

OnPlayerRelease(client)
{
	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	NoClip_Timer(client);
}

