#include <sdktools>

Handle TimerCheckpointDoor;
bool DoOnce;

public void OnPluginStart()
{
	HookEventEx("round_freeze_end", round_freeze_end);
	HookEventEx("player_first_spawn", player_first_spawn);
}


public void round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
	// when map start

	DoOnce = false;

	if(TimerCheckpointDoor == null) return;

	delete TimerCheckpointDoor;
}


public void player_first_spawn(Event event, const char[] name, bool dontBroadcast)
{
	// Timer already executed
	if(DoOnce || TimerCheckpointDoor != null) return;


	int client = GetClientOfUserId(event.GetInt("userid"));
	
	// Don't check unnecessary events. Only players in team survivor
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2) return;

	char doorname[30];
	int door = -1;


	int entity = -1;
	
	while( (entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1 )
	{
		//PrintToServer("m_hasUnlockSequence %i,   %i", GetEntProp(entity, Prop_Data, "m_hasUnlockSequence"), entity);
		GetEntPropString(entity, Prop_Data, "m_iName", doorname, sizeof(doorname));
		
		if(StrEqual(doorname, "checkpoint_exit", false))
		{
			// yes
			door = entity;
			break;
		}
		else if(StrEqual(doorname, "checkpoint_entrance", false))
		{
			// skip
			continue;
		}
		else if(GetEntProp(entity, Prop_Data, "m_hasUnlockSequence") == 1)
		{
			// empty targetname ex. Look door m_hasUnlockSequence
			door = entity;
			break;
		}
	}


	if(door == -1) return;


	SetVariantString("OnOpen !self:Lock::0.1:1");
	AcceptEntityInput(door, "AddOutput");
	
	SetVariantString("OnUser1 !self:playeropen::0.1:1");
	AcceptEntityInput(door, "AddOutput");

	SetVariantString("OnUser1 !self:playeropen::1.0:1");
	AcceptEntityInput(door, "AddOutput");
	
	PrintToChatAll("\x05[SM] \x04Checkpoint Exit Door \x05will be forced open in 30 seconds");

	DoOnce = true;
	TimerCheckpointDoor = CreateTimer(30.0, OpenDoor, EntIndexToEntRef(door));
}

public Action OpenDoor(Handle timer, int ref)
{
	TimerCheckpointDoor = null;

	int door = EntRefToEntIndex(ref);

	if(door != -1)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || GetClientTeam(i) != 2) continue;

			AcceptEntityInput(door, "FireUser1", i);
			PrintToChatAll("\x05[SM] \x04Checkpoint Exit Door \x05will be forced open!");
			break;
		}
	}
}  