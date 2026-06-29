#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new StartCheckpointDoor;
new EndCheckpointDoor;
new checkpointreached[MAXPLAYERS];
new String:current_map[24];

public OnPluginStart()
{
	HookEvent("player_entered_checkpoint", Player_Entered_Checkpoint);
	HookEvent("player_left_checkpoint", Player_Left_Checkpoint);
	HookEvent("round_start", Round_Start);
}

public Action:Player_Entered_Checkpoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	new door = GetEventInt(event, "door");

	if (client > 0)
	{
		checkpointreached[client] = 1;
		if (StartCheckpointDoor == 0)
		{
			StartCheckpointDoor = door;
		}
		else if (StartCheckpointDoor != door)
		{
			EndCheckpointDoor = door;
		}		
	}
}
public Action:Player_Left_Checkpoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (client > 0)
	{
		checkpointreached[client] = 0;
	}
}
public Action:Round_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	StartCheckpointDoor = 0;
	EndCheckpointDoor = 0;
}
public OnMapStart()
{
	GetCurrentMap(current_map, 24);
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsClientInGame(client) && GetClientHealth(client) > 0)
	{
		if (GetClientTeam(client) == 2)
		{
			if (buttons & IN_USE)
			{
				new String:entname[64];
				new door = GetClientAimTarget(client, false);

				if (IsValidEntity(door) && IsValidEdict(door))
				{
					GetEdictClassname(door, entname, sizeof(entname));
					if (StrEqual(entname, "prop_door_rotating_checkpoint"))
					{
						if (IsChapterBegin() && door == StartCheckpointDoor && StartCheckpointDoor > 0 || !IsChapterBegin() && door == EndCheckpointDoor && EndCheckpointDoor > 0)
						{
							decl Float:PlayerPos[3], Float:DoorPos[3];
							GetEntPropVector(client, Prop_Send, "m_vecOrigin", PlayerPos);
							GetEntPropVector(door, Prop_Send, "m_vecOrigin", DoorPos);
							new Float:distance = GetVectorDistance(PlayerPos, DoorPos);
							if (distance <= 120.0)
							{
								if (checkpointreached[client] == 1)
								{	
									//Lock Door
									SetVariantString("spawnflags 40960");
    									AcceptEntityInput(door, "AddOutput");
									AcceptEntityInput(door, "Close");
								}
								else if (checkpointreached[client] == 0)
								{	//Unlock Door
									SetVariantString("spawnflags 8192");
    									AcceptEntityInput(door, "AddOutput");
    									AcceptEntityInput(door, "Open");
								}
							}
						}
					}
				}
			}
		}
	}
}
stock bool:IsChapterBegin()
{
	if (StrEqual(current_map, "c1m1_hotel", false) || StrEqual(current_map, "c2m1_highway", false) || StrEqual(current_map, "c3m1_plankcountry", false) || StrEqual(current_map, "c4m1_milltown_a", false) || StrEqual(current_map, "c5m1_waterfront", false) || StrEqual(current_map, "c6m1_riverbank", false) || StrEqual(current_map, "c7m1_docks", false) || StrEqual(current_map, "c8m1_apartment", false))
	{
		return true;
	}
	return false;
}