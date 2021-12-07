#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"

new Handle:TimerStopSound[MAXPLAYERS+1];
new Handle:TimerStopTimer[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[L4D] & [L4D2] Silent Panic",
	author = "chinagreenelvis",
	description = "Stops the obvious incoming horde sound.",
	version = PLUGIN_VERSION,
	url = "www.chinagreenelvis.com"
}

public OnPluginStart()
{
    HookEvent("create_panic_event", Event_CreatePanicEvent);
}

public Event_CreatePanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			StopSound(i, SNDCHAN_STATIC, "npc/mega_mob/mega_mob_incoming.wav");
			TimerStopSound[i] = CreateTimer(1.0/10, Timer_StopSound, i, TIMER_REPEAT);
			TimerStopTimer[i] = CreateTimer(7.0, Timer_StopTimer, i);
		}
	}
}

public Action:Timer_StopSound(Handle:timer, any:client)
{
	if (TimerStopSound[client] != INVALID_HANDLE)
	{
		StopSound(client, SNDCHAN_STATIC, "npc/mega_mob/mega_mob_incoming.wav");
		//PrintToChatAll("Stopping panic sound");
	}
}

public Action:Timer_StopTimer(Handle:timer, any:client)
{
	if (TimerStopSound[client] != INVALID_HANDLE)
	{
		KillTimer(TimerStopSound[client]);
		TimerStopSound[client] = INVALID_HANDLE;
		//PrintToChatAll("TimerStopSound finished.");
	}
}