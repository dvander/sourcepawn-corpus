#include <sourcemod>
#include <sdktools> 
#include <sdkhooks>
#include "includes/hurt.sp"
#pragma newdecls required

bool hasLeftSafeArea = false;
bool hasLeftCheckPT = false;
bool hasOpenedDoor = false;

public Plugin myinfo = 
{
	name = "[L4D2] Tank Stasis",
	author = "BHaType",
	description = "Tank leave stasis while spawn",
	version = "0.1",
	url = "SDKCall"
};

public void OnPluginStart()
{
	HookEvent("tank_spawn", eSpawn);
	HookEvent("player_left_start_area", Event_player_left_start_area );
	HookEvent("player_left_checkpoint", Event_player_left_checkpoint );
	HookEvent("door_open", Event_DoorOpen);
	HookEvent("round_end", Event_round_end);
	
	//RegConsoleCmd("d", PrintStats, "Debug");
}

public Action eSpawn (Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	CreateTimer(0.5, tLeaveStasis, GetClientUserId(client));
}

public Action tLeaveStasis (Handle timer, int client)
{
	if (LeftStartArea()) { SendTank(client); }
	else if (hasOpenedDoor && hasLeftCheckPT) { SendTank(client); }
	else {
		CreateTimer(1.0, tLeaveStasis, client);
	}
}

public void SendTank(int client){
	
	if ((client = GetClientOfUserId(client)) == 0 || !IsClientInGame(client))
		return;

	PrintToChatAll("\x05A Tank has spotted you!");
	DealDamage(client, 0, GetRandomSurvivor(), DMG_BULLET, "weapon_rifle_ak47");
}

// Debug Command
public Action PrintStats(int client, int args){
	PrintToChatAll("Left Start Area: %d\nLeft Check Point: %d\nDoor Opened: %d", hasLeftSafeArea, hasLeftCheckPT, hasOpenedDoor);
}

// Safe Area Checking

public void Event_player_left_start_area(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !hasLeftSafeArea )
	{	
		hasLeftSafeArea = true;
	}
}

public void Event_player_left_checkpoint(Handle event, const char[] name, bool dontBroadcast)
{

	if ( !hasLeftCheckPT )
	{		
		hasLeftCheckPT = true;		
	}
}

public void Event_DoorOpen(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !hasOpenedDoor )
	{		
		hasOpenedDoor = true;
	}
}

public void Event_round_end(Handle event, const char[] name, bool dontBroadcast)
{
	hasLeftSafeArea = false;
	hasOpenedDoor = false;
	hasLeftCheckPT = false;
}

bool LeftStartArea()
{
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			hasLeftSafeArea = true;
			return true;
		}
	}
	hasLeftSafeArea = false;
	return false;
}


// Misc Functions

public int GetRandomSurvivor() {
	int survivors[MAXPLAYERS];
	int numSurvivors = 0;
	for( int i = 0; i < MAXPLAYERS; i++ ) {
		if( IsSurvivor(i) && IsPlayerAlive(i) ) {
		    survivors[numSurvivors] = i;
		    numSurvivors++;
		}
	}
	return survivors[GetRandomInt(0, numSurvivors - 1)];
}

public bool IsSurvivor(int client) {
	if( IsValidClient(client) && GetClientTeam(client) == 2 ) {
		return true;
	} else {
		return false;
	}
}

public bool IsValidClient(int client) {
    if( client > 0 && client <= MaxClients && IsClientInGame(client) ) {
    	return true;
    } else {
    	return false;
    }    
}
