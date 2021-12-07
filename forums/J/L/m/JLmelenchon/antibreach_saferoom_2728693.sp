#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#pragma semicolon 1

bool NoSpam[MAXPLAYERS + 1];
new bool:SafeRoomDoorClosed = false;

public Plugin myinfo = 
{
	name = "Anti breach saferoom.",
	author = "Lunatix",
	description = "To prevent an infected breaching safe room door with a bug. Credits to Eyal282 & djromero.",
	version = "2.0",
	url = "https://github.com/lunatixxx/"
}

ConVar hAntiBreachConVar;
int AntiBreachConVar;

public void OnPluginStart()
{
	LoadTranslations("antibreachdoor.phrases");
	
	// The cvar to enable the plugin. 0 = Disabled. Other values = Enabled.
	hAntiBreachConVar = CreateConVar("l4d2_anti_breach", "1");
	
	// To prevent waste of resources, hook the change of the console variable AntiBreach
	HookConVarChange(hAntiBreachConVar, AntiBreachConVarChange);
	
	// Save the current value of l4d2_anti_breach in a variable. Main reason is to avoid wasting resources.
	AntiBreachConVar = GetConVarInt(hAntiBreachConVar);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	
	RegisterEvents();
}

public void OnClientPutInServer(int client)
{
	NoSpam[client] = false;
}

public void AntiBreachConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	AntiBreachConVar = GetConVarInt(convar);
}

public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
// We mark the safe room door as open
SafeRoomDoorClosed = false;

return Plugin_Continue;
}

public Action:Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
return Plugin_Continue;
}


public Action:Event_DoorOpen (Handle:event, const String:name[], bool:dontBroadcast)
{
// if the door was a checkpoint door ...
new bool:checkpointdoor = GetEventBool(event, "checkpoint");

if (checkpointdoor == true)
{
SafeRoomDoorClosed = false;
}

return Plugin_Continue;
}

public Action:Event_DoorClose(Handle:event, const String:name[], bool:dontBroadcast)
{
// if the door was a checkpoint door ...
new bool:checkpointdoor = GetEventBool(event, "checkpoint");

if (checkpointdoor == true)
{
SafeRoomDoorClosed = true;
}

return Plugin_Continue;
}

public Action OnPlayerRunCmd(int SInfected, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	// Player is not attacking.
	if(!(buttons & IN_ATTACK))
		return Plugin_Continue;
	
	// Cvar is disabled, aborting.
	if(AntiBreachConVar == 0)
		return Plugin_Continue;
	
	// Player is either a bot, not infected or not a ghost.
	else if(GetClientTeam(SInfected) != 3 || IsFakeClient(SInfected) || GetEntProp(SInfected, Prop_Send, "m_isGhost") != 1)
		return Plugin_Continue;

	// Being a ghost, the player can not spawn ( seen / close / blocked etc... )
	else if(GetEntProp(SInfected, Prop_Send, "m_ghostSpawnState") != 0) 
	     return Plugin_Continue;

	int EntityCount = GetEntityCount();

	for (int Door = MaxClients; Door < EntityCount; Door++) // https://forums.alliedmods.net/showpost.php?p=2502446&postcount=2
	{
		if (IsValidEntity(Door) && IsValidEdict(Door))
		{
			char Classname[100];

			GetEdictClassname(Door, Classname, sizeof(Classname));
			
			if(strcmp(Classname, "prop_door_rotating_checkpoint") != 0 ) // Found the classname from l4d_loading: https://forums.alliedmods.net/showthread.php?p=836849
				continue;
			
			float SInfectedOrigin[3];
			float DoorOrigin[3];
			float SInfectedVelocity[3];
			GetEntPropVector(SInfected, Prop_Send, "m_vecOrigin", SInfectedOrigin);
			GetEntPropVector(Door, Prop_Send, "m_vecOrigin", DoorOrigin);
			GetEntPropVector(SInfected, Prop_Data, "m_vecVelocity", SInfectedVelocity);
			float Speed = GetVectorLength(SInfectedVelocity);
			float Distance = GetVectorDistance(SInfectedOrigin, DoorOrigin);
			
			// Player has too much speed vs distance from door.
			
			if(Distance < Speed / 2.0) // Tested and the 1.5 division will not assist the use of the bug.
			if (SafeRoomDoorClosed == true)
			{
				if(!NoSpam[SInfected])
				{
					PrintToChat(SInfected, "%T", "Spawn_prevented", SInfected);
					NoSpam[SInfected] = true;
					CreateTimer(2.5, AllowMessageAgain, GetClientUserId(SInfected));
				}
				buttons &= ~IN_ATTACK;
				
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

public Action AllowMessageAgain(Handle Timer, int UserId)
{
	int SInfected = GetClientOfUserId(UserId);
	
	if(!IsClientInGame(SInfected))
		return Plugin_Continue;
	
	NoSpam[SInfected] = false;

	return Plugin_Continue;
}

RegisterEvents ()
{
HookEvent("door_open", Event_DoorOpen, EventHookMode_Post);
HookEvent("door_close", Event_DoorClose, EventHookMode_Post);
}
