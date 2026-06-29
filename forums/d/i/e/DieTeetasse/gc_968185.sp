#include <sourcemod>
#include <sdktools> 
 
new bool:players[1025];
 
public OnPluginStart()
{
	HookEvent("player_incapacitated", Event_player_incapacitated);
	HookEvent("revive_success", Event_revive_success);
}

public Event_player_incapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetEventInt(event, "userid");
	new cid = GetClientOfUserId(id);
	
	//Bot?
	if (!IsFakeClient(cid))
	{
		//Got a gren? Check weapon slot 2...
		if (GetPlayerWeaponSlot(cid, 2) > -1)
		{
			players[cid] = true;
		}
	}
}

public Event_revive_success(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetEventInt(event, "userid");
	new cid = GetClientOfUserId(id);
	
	players[cid] = false;
}

public OnGameFrame()
{
    for (new i = 1; i <= MaxClients; i++)
    {
		//Incap?
		if (players[i] == false)
		{
			continue;
		}
	
		//Existing?
		if (!IsValidEntity(i)) 
		{
			continue;
		}
		
		//Ingame?
		if (!IsClientInGame(i))
		{
			continue;
		}		
		
		//Alive?
		if (!IsPlayerAlive(i))
		{
			continue;
		}	
			
		//Button? (Middle Mouse Button)
		if (GetClientButtons(i) & IN_ZOOM)
		{
		
			//Unincap
			SetEntProp(i, Prop_Send, "m_isIncapacitated", 0);
			
			//Unmovable
			SetEntityMoveType(i, MOVETYPE_NONE);
			
			//Find old gren
			new gren = GetPlayerWeaponSlot(i, 2);
			
			//Get name
			new String:name[30];
			GetEdictClassname(gren, name, sizeof(name));
			
			//Use gren			
			FakeClientCommand(i, "use %s", name)
			
			//Timer
			CreateTimer(0.5, Timer_Attack, i);

			//Reset variable
			players[i] = false;
		}  
	}
}

public Action:Timer_Attack(Handle:timer, any:client)
{	
	//Fire
	ClientCommand(client, "+attack")
			
	//Timer
	CreateTimer(0.5, Timer_Reset, client);
}

public Action:Timer_Reset(Handle:timer, any:client)
{	
	//Reset fire
	ClientCommand(client, "-attack")
			
	//Timer
	CreateTimer(0.5, Timer_Incap, client);
}

public Action:Timer_Incap(Handle:timer, any:client)
{		
	//Movable
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	//Incap
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}
