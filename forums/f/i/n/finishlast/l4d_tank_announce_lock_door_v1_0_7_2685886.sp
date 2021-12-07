/********************************************************************************************
* Plugin	: L4D Tank announce and lock door
* Version	: 1.0.7
* Game		: Left 4 Dead 
* Author	: Finishlast
* Based on code  from:
* [L4D / L4D2] Lockdown System | 1.7 [Final] : Jan. 30, 2019 |
* https://forums.alliedmods.net/showthread.php?t=281305
* Aya Supay for making the code look great again
* MasterMind420 for providing a fix to check for all kinds of ending checkpoint doors
*
* Testers	: Myself
* Website	: www.l4d.com
* Purpose	: This plugin announces tank spawns and locks the safehouse door until 
*		  the tank is dead.
********************************************************************************************/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define UNLOCK 0
#define LOCK 1
int iCheckpointDoor;
bool g_bIsTankAlive;
public Plugin myinfo = 
{
	name = "L4D1 - Tank Announce with automatic door locking",
	author = "finishlast",
	description = "Announce when a Tank has spawned and lock the door until Tank is dead",
	version = "1.0.7",
	url = ""
};

public void OnMapStart()
{
	PrecacheSound("ui\\pickup_secret01.wav");
	PrecacheSound("player\\tank\\voice\\yell\\hulk_yell_4.wav");
}

public void OnPluginStart()
{
	HookEvent("round_start", 	Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", 	Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", 	Event_PlayerDeath, EventHookMode_Pre);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if (IsFinaleMap())
	{
		return;
	}
	g_bIsTankAlive = false;
	CreateTimer(1.5, CheckDelay);
}

public Action CheckDelay(Handle timer)
{
    if(!IsFinaleMap())
	{
	    InitDoor();
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int UserId = event.GetInt("userid");
	if (UserId != 0) {
		int client = GetClientOfUserId(UserId);
		if (client != 0) {
			if (IsTank(client) && !g_bIsTankAlive) {
				g_bIsTankAlive = true;
				Command_Play("ui\\pickup_secret01.wav");
				Command_Play("player\\tank\\voice\\yell\\hulk_yell_4.wav");
				if(!IsFinaleMap()) {
				    ControlDoor(iCheckpointDoor, LOCK);
				    PrintToChatAll("[SM] A Tank spawned. The safehouse is locked!");
				}
				else {
				    PrintToChatAll("[SM] A Tank spawned!");
				}
			}
		}
	}
}

public void Event_PlayerDeath(Event hEvent, const char[] name, bool DontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client && IsClientInGame(client)) {
		if (IsTank(client)) {
			int Tankcount = 0; 
   			for (int i = 1; i <= MaxClients; i++) 
    			if (IsClientConnected(i) && IsClientInGame(i) &&  IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 5) Tankcount++; 
			if(Tankcount==0){
				if(!IsFinaleMap()) {
		        	PrintToChatAll("[SM] The Tank is dead! The safehouse is open!");
		        	ControlDoor(iCheckpointDoor, UNLOCK);
				}
				else {
				PrintToChatAll("[SM] The Tank is dead!");	
				}
				g_bIsTankAlive = false;
			}
		}
	}
}

void ControlDoor(int entity, int iOperation)
{
	switch (iOperation)
	{
		case LOCK:
		{
       		AcceptEntityInput(entity, "Close");
       		AcceptEntityInput(entity, "Lock");
       		AcceptEntityInput(entity, "ForceClosed");
			
       		if (HasEntProp(entity, Prop_Data, "m_hasUnlockSequence"))
       		{ 
				SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", LOCK);
       		} 
		}
		case UNLOCK:
		{
           	if (HasEntProp(entity, Prop_Data, "m_hasUnlockSequence"))
           	{ 
          		SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK); 
           	} 
           	AcceptEntityInput(entity, "Unlock"); 
           	AcceptEntityInput(entity, "ForceClosed"); 
           	AcceptEntityInput(entity, "Open"); 
		}
	}
}

void InitDoor()
{
	int target = -1;
	while((target = FindEntityByClassname(target, "prop_door_rotating_checkpoint")) > -1)
	{
		if(IsValidEntity(target))
		{
			char sModel[64];
			GetEntPropString(target, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

			if(StrContains(sModel, "checkpoint_door") > -1 && StrContains(sModel, "02") > -1)
			{
				iCheckpointDoor = target;
			}
		}
	}
}

bool IsFinaleMap()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "l4d_vs_airport05_runway", false) 
	|| StrEqual(sMap, "l4d_river03_port", false) 
	|| StrEqual(sMap, "l4d_vs_smalltown03_ranchhouse", false) //churchguy door fix
	|| StrEqual(sMap, "l4d_vs_smalltown05_houseboat", false) 
	|| StrEqual(sMap, "l4d_garage02_lots", false) 
	|| StrEqual(sMap, "l4d_vs_farm05_cornfield", false) 
	|| StrEqual(sMap, "l4d_vs_hospital05_rooftop", false))
	{
	return true;
	}
	return false;
	}

bool IsTank(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == 5)
			return true;
	}
	return false;
}

public void Command_Play(const char[] arguments)
{

	for(int i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);
	}  
}