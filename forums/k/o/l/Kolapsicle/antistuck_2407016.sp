#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.00"
#define PREFIX "\x03[AntiStuck]\x01"

public Plugin myinfo =  {
	name = "Anti Stuck", 
	author = "muso.sk", 
	description = "Allows players to push them away from stucked player", 
	version = PLUGIN_VERSION
};

ConVar hStuckDuration;
int TimerActive;
bool bCanUnstuck;

#define COLLISION_GROUP_PUSHAWAY            17
#define COLLISION_GROUP_PLAYER              5

public OnPluginStart()
{
	hStuckDuration = CreateConVar("sm_antistuck_duration", "60.0", "Stuck usage duration each round.", FCVAR_PLUGIN);
	HookEvent("round_start", Event_RoundStart);
	RegConsoleCmd("sm_stuck", Command_Stuck);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bCanUnstuck = true;
	CreateTimer(GetConVarFloat(hStuckDuration), Timer_BlockStuck, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_Stuck(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	if (!bCanUnstuck) {
		PrintToChat(client, "%s Stuck is disabled for the remainder of this round.", PREFIX);
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client) && TimerActive == 0) {
		PrintToChatAll("%s Unstuck all players.", PREFIX);
		TimerActive = 1;
		CreateTimer(1.0, Timer_UnBlockPlayer, client);
		
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && IsPlayerAlive(i))
				EnableAntiStuck(i);
		}
	}
	else if (TimerActive == 1)
		PrintToChat(client, "%s Command is already in use.", PREFIX);
	else
		PrintToChat(client, "%s You must be alive to use this command.", PREFIX);
	
	return Plugin_Handled;
	
}

public Action Timer_BlockStuck(Handle timer)
{
	bCanUnstuck = false;
}

public Action Timer_UnBlockPlayer(Handle timer, any client)
{
	TimerActive = 0;
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i))
			DisableAntiStuck(i);
	}
	
	return Plugin_Continue;
}

void DisableAntiStuck(int client)
{
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
}

void EnableAntiStuck(int client)
{
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
}

bool IsValidClient(int client)
{
	if (client < 1)
		return false;
	if (client > MaxClients)
		return false;
	if (!IsClientInGame(client))
		return false;
	return true;
} 