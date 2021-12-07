#include <sdktools>
#include <zombiereloaded>

new Float:start_radius = 220.1;
new Float:end_radius = 220.0;
new Handle: SpriteTimer[MAXPLAYERS +1] = INVALID_HANDLE;
new Handle: DistanceTimer[MAXPLAYERS +1] = INVALID_HANDLE;
new Handle: ChickenTimer[MAXPLAYERS +1] = INVALID_HANDLE;
new g_Sprite;
new SafeZone = 130;
new chicken[MAXPLAYERS +1];
#define BOUNDINGBOX_INFLATION_OFFSET 3

new colours[4] = {255, 0, 0, 255};

public Plugin:myinfo =
{
    name        = "Decoy Chicken",
    author      = "8GuaWong",
    description = "Changes Decoy Grenade Into A Decoy Chicken!!",
    version     = "1.0",
    url         = "http://www.blackmarke7.com"
};

public OnPluginStart()
{	
	HookEvent("decoy_started", EventGrenade_Detonate);
	HookEvent("other_death", Event_OtherDeath);
	HookEvent("round_end", Event_RoundEnd);
}

public OnMapStart()
{
	g_Sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new x=1; x <= MaxClients; x++)
	{
		if(SpriteTimer[x] != INVALID_HANDLE)
		{
			KillTimer(SpriteTimer[x]);
			SpriteTimer[x] = INVALID_HANDLE;			
		}
		if(DistanceTimer[x] != INVALID_HANDLE)
		{
			KillTimer(DistanceTimer[x]);
			DistanceTimer[x] = INVALID_HANDLE;			
		}
		if(ChickenTimer[x] != INVALID_HANDLE)
		{
			KillTimer(ChickenTimer[x]);
			ChickenTimer[x] = INVALID_HANDLE;			
		}
	}
}

public Event_OtherDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (GetEventInt(event, "otherid") == chicken[i])
			chicken[i] = 0;
	}
}

public EventGrenade_Detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	chicken[client] = 0;
	new Float:Origin[3];
	Origin[0] = GetEventFloat(event,"x");
	Origin[1] = GetEventFloat(event,"y");
	Origin[2] = GetEventFloat(event,"z");
	
	new index = MaxClients+1; decl Float:xyz[3];
	while ((index = FindEntityByClassname(index, "decoy_projectile")) != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", xyz);
		if (xyz[0] == Origin[0] && xyz[1] == Origin[1] && xyz[2] == Origin[2])
		{
			AcceptEntityInput(index, "kill");
			ThrowChicken(Origin, client);
			new Handle:data3;
			ChickenTimer[client] = CreateDataTimer(0.1, Timer_CheckChickenDistance, data3, TIMER_REPEAT);
			WritePackFloat(data3, Origin[0]);
			WritePackFloat(data3, Origin[1]);
			WritePackFloat(data3, Origin[2]);
			WritePackCell(data3, client);
		}
	}

	new Handle:data;
	SpriteTimer[client] = CreateDataTimer(0.1, Timer_DrawSprite, data, TIMER_REPEAT);
	WritePackFloat(data, Origin[0]);
	WritePackFloat(data, Origin[1]);
	WritePackFloat(data, Origin[2]);
	WritePackCell(data, client);

	new Float:zombiePos[3];
	new Float:Distance;
	 
	for (new i=1; i<= MaxClients; i++)
	{		
		if (!IsClientValid(i))
			continue;
		if (ZR_IsClientHuman(i))
			continue;
		if (ZR_IsClientZombie(i))
		{
			GetClientAbsOrigin(i, zombiePos);
			Distance = GetVectorDistance(Origin, zombiePos);
			decl Float:VecOrigin[3];
			// Look for a collision point from this client from their eyes in the direction they are looking
			if (!GetTeleportEndpoint(i, VecOrigin, true))
			{
				// If we fail using the eye position, we're probably hitting a roof so use abs origin instead
				GetTeleportEndpoint(i, VecOrigin, false);
			}
					
			if (Distance < 200.0)
			{
				TeleportEntity(i, VecOrigin, NULL_VECTOR, NULL_VECTOR);
				new Handle:data2;
				DistanceTimer[i] = CreateDataTimer(0.1, Timer_CheckDistance, data2, TIMER_REPEAT);
				WritePackCell(data2, GetClientUserId(i));
				WritePackCell(data2, client);
				WritePackFloat(data2, Origin[0]);
				WritePackFloat(data2, Origin[1]);
				WritePackFloat(data2, Origin[2]);					
			}
		}
	}
}

stock ThrowChicken(Float:vSpawnPos[3], client)
{
	chicken[client] = CreateEntityByName("chicken");
	SetEntProp(chicken[client], Prop_Send, "m_bShouldGlow", true, true);
	DispatchSpawn(chicken[client]);
	TeleportEntity(chicken[client], vSpawnPos, NULL_VECTOR, NULL_VECTOR);
}

public Action:Timer_CheckDistance(Handle:timer, any:data)
{		 
	new Float:distance;
	new Float:clientLocation[3];
	new Float:origin[3];
	ResetPack(data);
	new client = GetClientOfUserId(ReadPackCell(data));
	if (!IsClientValid(client))
		return Plugin_Stop;
	new tokill =  ReadPackCell(data);
	origin[0] = ReadPackFloat(data);
	origin[1] = ReadPackFloat(data);
	origin[2] = ReadPackFloat(data);
	

	GetClientAbsOrigin(client, clientLocation);
	distance = SquareRoot(Pow((clientLocation[0] - origin[0]), 2.0) + Pow((clientLocation[1] - origin[1]), 2.0));
	if (chicken[tokill] != 0)
	{
		if (distance > SafeZone)
		{
			TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
			PrintHintText(client, "Kill The Chicken!!");
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	else
		return Plugin_Stop;
}

public Action:Timer_CheckChickenDistance(Handle:timer, any:data)
{		 
	new Float:distance;
	new Float:chickenLocation[3];
	new Float:origin[3];
	ResetPack(data);
	origin[0] = ReadPackFloat(data);
	origin[1] = ReadPackFloat(data);
	origin[2] = ReadPackFloat(data);
	new tokill =  ReadPackCell(data);
	
	if (!IsValidEdict(chicken[tokill]))
		return Plugin_Stop;
		
	GetEntPropVector(chicken[tokill], Prop_Data, "m_vecOrigin", chickenLocation);
	distance = SquareRoot(Pow((chickenLocation[0] - origin[0]), 2.0) + Pow((chickenLocation[1] - origin[1]), 2.0));
	if (chicken[tokill] != 0)
	{
		if (distance > SafeZone)
		{
			TeleportEntity(chicken[tokill], origin, NULL_VECTOR, NULL_VECTOR);
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	else
		return Plugin_Stop;
}

public Action:Timer_DrawSprite(Handle:timer, any:data)
{
	new Float:origin[3];
	ResetPack(data);
	origin[0] = ReadPackFloat(data);
	origin[1] = ReadPackFloat(data);
	origin[2] = ReadPackFloat(data);
	new client = ReadPackCell(data);
	TE_SetupBeamRingPoint(origin, start_radius + 70, end_radius + 70, g_Sprite, 0, 0, 25, 0.1, 5.0, 0.0, colours, 1, 0);
	TE_SendToAll();
	if (!chicken[client])
		return Plugin_Stop;
	return Plugin_Continue;
}

stock bool:GetTeleportEndpoint(client, Float:pos[3], bool:findFloor=true)
{
	decl Float:vOrigin[3], Float:vAngles[3], Float:vBackwards[3], Float:vUp[3];
	new bool:failed = false;
	new loopLimit = 100;	// only check 100 times, as a precaution against runaway loops
	new Float:downAngles[3];
	new Handle:traceDown;
	new Float:floor[3];

	GetClientAbsOrigin(client, floor);
	GetClientEyePosition(client, vOrigin);

	downAngles[0] = 90.0;	 //thats right you'd think its a z value - this will point you down
	GetAngleVectors(downAngles, vUp, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vUp, vUp);
	ScaleVector(vUp, -3.0);	   // TODO: percentage of distance from endpoint to eyes instead of fixed distance?

	GetClientEyeAngles(client, vAngles);
	GetAngleVectors(vAngles, vBackwards, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vBackwards, vBackwards);
	ScaleVector(vBackwards, 10.0);	  // TODO: percentage of distance from endpoint to eyes instead of fixed distance?
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
			
	if (TR_DidHit(trace))
	{	 
		new bool:first = true;
				
		while (first || (IsPlayerStuck(floor, client) && !failed))	  // iteratively check if they would become stuck
		{
			if (first)
			{
				TR_GetEndPosition(pos, trace);
				first = false;
			}
			else
			{
				SubtractVectors(pos, vBackwards, pos);		  // if they would, subtract backwards from the position
			}
			
			if(findFloor)
			{
				traceDown = TR_TraceRayFilterEx(pos, downAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
				new bool:hit = TR_DidHit(traceDown);
				if (hit)
				{
					TR_GetEndPosition(floor, traceDown);
					new j = 10;
					while (j > 0 && IsPlayerStuck(floor, client))
					{
						AddVectors(floor, vUp, floor);	  // lift off the floor a hair
						j--;
					}
				}
					
				CloseHandle(traceDown);
				
				if (!hit) continue;	   // If there is no floor, continue searching
			}
			else
			{
				floor = pos;
			}
			//PrintToChat(client, "floorpos %f %f %f", floor[0], floor[1], floor[2]);
			
			if (GetVectorDistance(pos, vOrigin) < 10 || loopLimit-- < 1)
			{
				
				failed = true;	  // If we get all the way back to the origin without colliding, we have failed
				//PrintToChat(client, "failed to find endpos");
				GetClientAbsOrigin(client, floor);
			}
		}
	}
	
	pos = floor;
	
	CloseHandle(trace);
	return !failed;		   // If we have not failed, return true to let the caller know pos has teleport coordinates
} 

stock bool:IsPlayerStuck(Float:pos[3], client)
{
	new Float:mins[3];
	new Float:maxs[3];

	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	
	// inflate the sizes just a little bit
	for (new i=0; i<sizeof(mins); i++)
	{
		mins[i] -= BOUNDINGBOX_INFLATION_OFFSET;
		maxs[i] += BOUNDINGBOX_INFLATION_OFFSET;
	}

	TR_TraceHullFilter(pos, pos, mins, maxs, MASK_SOLID, TraceEntityFilterPlayer, client);

	return TR_DidHit();
}  

// filter out players, since we can't get stuck on them
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity <= 0 || entity > MaxClients;
} 

stock bool:IsClientValid(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		return true;
	}
	return false;
}