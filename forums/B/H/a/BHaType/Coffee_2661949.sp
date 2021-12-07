#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool g_bStop;
Handle g_hStop;

static const char szNames[][] = 
{
	"smoker auto",
	"smoker auto",
	"boomer auto",
    "hunter auto",
    "spitter auto",
    "jockey auto",
    "charger auto"
};

public Plugin myinfo =
{
    name        = "Coffee",
    author      = "BHaType",
    description = "0x90",
    version     = "0x90",
    url         = "0x90"
}

public void OnPluginStart()
{
	HookEvent("create_panic_event", eEvent, EventHookMode_PostNoCopy);
	HookEvent("explain_panic_button", eEvent, EventHookMode_PostNoCopy);
	//HookEvent("explain_gas_can_panic", eEvent, EventHookMode_PostNoCopy);
	//HookEvent("explain_van_panic", eEvent, EventHookMode_PostNoCopy);
	HookEvent("panic_event_finished", eEvent, EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
	if(g_hStop != null)
		delete g_hStop;
}

public void eEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(strcmp(name, "panic_event_finished") == 0)
	{
		g_bStop = true;
		return;
	}
	g_bStop = false;
	
	if(g_hStop == null)
		g_hStop = CreateTimer(GetRandomFloat(5.0, 10.0), tSpawn, _, TIMER_REPEAT);
}

public Action tSpawn (Handle timer)
{
	if(g_bStop)
	{
		delete g_hStop;
		return Plugin_Stop;
	}
	
	int index;
	
	for(index = 1; index <= MaxClients; index++)
	{
		if(IsClientInGame(index))
			break;
	}
	
	if(index)
	{
		index = CreateFakeClient("fakeclient");
		Execute(index, "z_spawn_old", szNames[GetRandomInt(0, sizeof szNames - 1)]);
		CreateTimer(0.1, tKick, GetClientUserId(index));
	}
	
	return Plugin_Continue;
}

public Action tKick (Handle timer, int index)
{
	index = GetClientOfUserId(index);
	if(index && IsClientInGame(index))
		KickClient(index, "fakeclient");
}

void Execute(int client, const char[] cmd, const char[] args)
{
	int flags = GetCommandFlags(cmd);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", cmd, args);
	SetCommandFlags(cmd, flags);
}