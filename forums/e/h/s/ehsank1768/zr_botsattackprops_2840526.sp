#include <sdktools>
#include <zombiereloaded>
//#include <morecolors>


public Plugin:myinfo = 
{
	name = "[ZR] Zombie Bots: Aggrasiveness",
	author = "Khebre, Gary83, Franc1sco franug",
	description = "Fixes the bug where Zombie Bot's AI stops when it gets close to you(Making them much more Aggrasive than before)",
	version = "1.0"
}

new tracer_fx;
new bool:GabrieleMet[MAXPLAYERS + 1];
new Float:clientCounter[MAXPLAYERS + 1];
new bool:Loading[MAXPLAYERS + 1];

bool IsValidAliveClient(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}
public OnClientPutInServer(int client)
{
		GabrieleMet[client] = false;
		Loading[client] = false;
		clientCounter[client] = 0.0;
}
public OnMapStart()
{
	tracer_fx = PrecacheModel("sprites/lgtning.vmt");
}
public Action:OnPlayerRunCmd(int iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Check if player is valid, alive, is a bot, and is a zombie
	if (!IsValidClient(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Continue;
	
	// Only process for zombie bots
	if (!IsFakeClient(iClient) || !ZR_IsClientZombie(iClient))
		return Plugin_Continue;
	// Decrement client counter and print current value (but don't go below 0)
	if (clientCounter[iClient] > 0.0)
	{
		clientCounter[iClient] -= 3.0;
		FakeClientCommand(iClient, "-sm_gouse");
		FakeClientCommand(iClient, "-sm_goattack");
	}
	if (Loading[iClient])
	{
		clientCounter[iClient] += 4.0;
		Loading[iClient] = false;
	}
	if (clientCounter[iClient] > 3000.0)
	{
		clientCounter[iClient] = 0.0;
		FakeClientCommand(iClient, "say !ztele");
	}
	if (clientCounter[iClient] >= 1.0 && clientCounter[iClient] <= 224.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		//FakeClientCommand(iClient, "+sm_goattack");
	}
	if (clientCounter[iClient] >= 225.0 && clientCounter[iClient] <= 270.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		FakeClientCommand(iClient, "+sm_goattack");
		int iTarget = GetClosestEntity(iClient);
		if (iTarget != -1)
		{
			LookAtEntity(iClient, iTarget);
		}
	}
	if (clientCounter[iClient] >= 271.0 && clientCounter[iClient] <= 375.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		FakeClientCommand(iClient, "+sm_goattack");
	}
	if (clientCounter[iClient] >= 376.0 && clientCounter[iClient] <= 435.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		FakeClientCommand(iClient, "+sm_goattack");
		int iTarget = GetClosestEntity(iClient);
		if (iTarget != -1)
		{
			LookAtEntity(iClient, iTarget);
		}
	}
	if (clientCounter[iClient] >= 436.0 && clientCounter[iClient] <= 660.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		FakeClientCommand(iClient, "+sm_goattack");
	}
	
	if (clientCounter[iClient] >= 661.0 && clientCounter[iClient] <= 770.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		FakeClientCommand(iClient, "+sm_goattack");
		
		// Find closest entity and aim at it
		int iTarget = GetClosestEntity(iClient);
		if (iTarget != -1)
		{
			LookAtEntity(iClient, iTarget);
		}
	}
	if (clientCounter[iClient] >= 771.0 && clientCounter[iClient] <= 1250.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		FakeClientCommand(iClient, "+sm_goattack");
	}
	if (clientCounter[iClient] >= 1251.0 && clientCounter[iClient] <= 1649.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		FakeClientCommand(iClient, "+sm_goattack");
		
		// Find closest entity and aim at it
		int iTarget = GetClosestEntity(iClient);
		if (iTarget != -1)
		{
			LookAtEntity(iClient, iTarget);
		}
	}
	if (clientCounter[iClient] >= 1650.0 && clientCounter[iClient] <= 2999.0)
	{
		FakeClientCommand(iClient, "+sm_gouse");
		FakeClientCommand(iClient, "+sm_goattack");
	}
	
	//PrintToChat(iClient, "Counter: %.1f", clientCounter[iClient]);
		
		
		
	//int iTarget = GetClosestEntity(iClient);
	//if (iTarget != -1)
	//{
		//LookAtEntity(iClient, iTarget);
	//}
	// Check if GabrieleMet is true for this client
	//if (GabrieleMet[iClient])
	//{
		// Get current weapon
		decl String:weaponName[32];
		GetClientWeapon(iClient, weaponName, sizeof(weaponName));
		
		// Check if weapon is scout
		if (StrEqual(weaponName, "weapon_knife", false))
		{
			decl Float:EyePosition[3], Float:EyeAngles[3], Float:beampos[3], Float:clientpos[3]; 
			GetClientEyePosition(iClient, EyePosition);
			GetClientEyeAngles(iClient, EyeAngles);
			GetClientEyePosition(iClient, clientpos);
			
			// Array to store Z values
			decl Float:zValues[8];
			
			// Lower the starting position from player's head
			decl Float:beamStartPos[3];
			beamStartPos[0] = clientpos[0];
			beamStartPos[1] = clientpos[1];
			beamStartPos[2] = clientpos[2] - 20.0; // Lower by 20 units from head
			
			// Create 8 beams at fixed angles for full 360-degree coverage
			for (new i = 0; i < 8; i++)
			{
				// Fixed angles: 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°
				decl Float:fixedAngles[3];
				fixedAngles[0] = 30.0; // Fixed pitch at 30 degrees
				fixedAngles[1] = float(i) * 45.0; // Yaw: 0, 45, 90, 135, 180, 225, 270, 315 degrees
				fixedAngles[2] = 0.0; // Roll stays at 0
				
				// Trace to find where the beam hits MASK_SHOT
				new Handle:trace = TR_TraceRayFilterEx(beamStartPos, fixedAngles, MASK_OPAQUE, RayType_Infinite, wS_GetLookPos_Filter, iClient);
				TR_GetEndPosition(beampos, trace);
				
				// Get the entity that was hit
				new hitEntity = TR_GetEntityIndex(trace);
				CloseHandle(trace);
				
				// Print what entity the beam hit
				if (hitEntity > 0)
				{
					decl String:entityName[64];
					decl String:className[64];
					
					// Get entity class name
					if (hitEntity <= MaxClients)
					{
						// It's a player
						decl String:playerName[32];
						GetClientName(hitEntity, playerName, sizeof(playerName));
						//PrintToChat(iClient, "Beam %d hit player: %s (entity %d)", i+1, playerName, hitEntity);
					}
					else
					{
						// It's a prop or other entity
						GetEntityClassname(hitEntity, className, sizeof(className));
						GetEntPropString(hitEntity, Prop_Data, "m_iName", entityName, sizeof(entityName));
						
						// Check if it's a physics prop
						if (StrEqual(className, "prop_physics", false) || StrEqual(className, "prop_physics_multiplayer", false))
						{
							// Get entity position
							decl Float:entityPos[3];
							GetEntPropVector(hitEntity, Prop_Send, "m_vecOrigin", entityPos);
							
							// Print entity location in chat
							//PrintToChat(iClient, "Found %s at position: X=%.1f, Y=%.1f, Z=%.1f (Entity ID: %d)", className, entityPos[0], entityPos[1], entityPos[2], hitEntity);
							
							Loading[iClient] = true;
						}
						
						if (strlen(entityName) > 0)
						{
							//PrintToChat(iClient, "Beam %d hit entity: %s (%s) - entity %d", i+1, entityName, className, hitEntity);
						}
						else
						{
							//PrintToChat(iClient, "Beam %d hit entity: %s - entity %d", i+1, className, hitEntity);
						}
					}
				}
				else
				{
					//PrintToChat(iClient, "Beam %d hit world geometry", i+1);
				}
				
				// Store the Z value
				zValues[i] = beampos[2];
				
				// Print to chat where the trace ended
				//CPrintToChat(iClient, "{WHITE}Beam %d ended at Z: %.1f", i+1, beampos[2]);
				
				//TE_SetupBeamPoints(beamStartPos, beampos, tracer_fx,0,0,0,1.0,4.0,4.0,2,0,{0, 100, 255, 190},1);
				//TE_SendToAll();
			}
			
			// Check if all Z values are within 10 units of each other NOT USED ANYMORE
			// Find min and max Z values
			decl Float:minZ, Float:maxZ;
			minZ = zValues[0];
			maxZ = zValues[0];
			for (new i = 1; i < 8; i++)
			{
				if (zValues[i] < minZ)
					minZ = zValues[i];
				if (zValues[i] > maxZ)
					maxZ = zValues[i];
			}
			
			// Check if the range is within 10 units
			if ((maxZ - minZ) <= 10.0)
			{
			      //FakeClientCommand(iClient, "+sm_goforward");
			    //TE_SetupBeamPoints(clientpos, beampos, tracer_fx,0,0,0,1.0,4.0,4.0,2,0,{255, 0, 255, 190},1);
				//TE_SendToAll();
				//CPrintToChat(iClient, "{CYAN}We Successfully got the results");
			}
		}
	//}
	//else
	//{
	//FakeClientCommand(iClient, "-sm_goforward");
	//}
	
	return Plugin_Continue;
}

public bool:wS_GetLookPos_Filter(entity, contentsMask, any:data)
{
	if(entity != data && entity > MaxClients){
		return true;
	}
	return false;
}
bool:IsValidClient(client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

// Function to find the closest physics prop entity
stock int GetClosestEntity(int iClient)
{
	float fClientOrigin[3], fTargetOrigin[3];
	
	GetClientAbsOrigin(iClient, fClientOrigin);
	
	int iClosestTarget = -1;
	float fClosestDistance = -1.0;
	float fTargetDistance;
	
	// Loop through all entities
	int maxEntities = GetMaxEntities();
	for (int i = MaxClients + 1; i <= maxEntities; i++)
	{
		if (!IsValidEntity(i))
		{
			continue;
		}
		
		// Get entity class name
		char className[64];
		GetEntityClassname(i, className, sizeof(className));
		
		// Check if it's a physics prop
		if (!StrEqual(className, "prop_physics", false) && !StrEqual(className, "prop_physics_multiplayer", false))
		{
			continue;
		}
		
		// Get entity position
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", fTargetOrigin);
		fTargetDistance = GetVectorDistance(fClientOrigin, fTargetOrigin);

		if (fTargetDistance > fClosestDistance && fClosestDistance > -1.0)
		{
			continue;
		}

		if (fTargetDistance > 250.0)
		{
			continue;
		}
		
		fClosestDistance = fTargetDistance;
		iClosestTarget = i;
	}
	
	return iClosestTarget;
}

// Function to make client look at entity
stock void LookAtEntity(int iClient, int iEntity)
{
	float fEntityPos[3]; float fClientPos[3]; float fFinalPos[3];
	GetClientEyePosition(iClient, fClientPos);
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityPos);
	
	MakeVectorFromPoints(fClientPos, fEntityPos, fFinalPos);
	GetVectorAngles(fFinalPos, fFinalPos);

	TeleportEntity(iClient, NULL_VECTOR, fFinalPos, NULL_VECTOR); 
}
