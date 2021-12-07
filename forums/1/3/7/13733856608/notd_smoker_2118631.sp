//Unique_Compile_String: v2//

/**
 * ====================
 *	 Zombie Riot
 *   File: smoker.inc
 *   Author: [NotD] l0calh0st
 *   www.notdelite.com
 * ====================
 */

#include <sourcemod>
#include <sdktools>

new Handle:repeatTimer;

new maxPlayers;
new g_sprite;


public OnPluginStart()
{
	repeatTimer = CreateTimer(0.5, DotInfo, _, TIMER_REPEAT);
	maxPlayers = GetMaxClients();

}

public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/laser.vmt");
	colorD[0] = 5;
	colorD[1] = 245;
	colorD[2] = 5;
	colorD[3] = 245;
}

public OnPluginEnd()
{
	if (repeatTimer != INVALID_HANDLE) 
		KillTimer(repeatTimer);
	repeatTimer = INVALID_HANDLE;
}

public Action:DotInfo(Handle:timer)
{	
	new String:model[75];
	for (new client = 1; client < maxPlayers; client++)
	{
		if (!IsValidEdict(client))
			continue; 
	
		if (IsFakeClient(client) && IsClientInGame(client))
		{
			
			GetClientModel(client, model, sizeof(model))
			if (StrEqual(model, SMOKERMODEL))
			{
				new target;
				target = GetClientAimTarget(client, true);

				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
				//Send player info!
				if (target > 0)
				{
					new Float:clientVec[3];
					new Float:targetVec[3];
					GetClientAbsOrigin(client, clientVec);
					GetClientAbsOrigin(target, targetVec);
					
					if (GetVectorDistance(clientVec, targetVec) < 1000)
					{
						clientVec[2] += 10;
						targetVec[2] += 10;
						decl Float:clientEyeVec[3], Float:targetWepVec[3];
						GetClientEyePosition(client, clientEyeVec);
						GetClientEyePosition(target, targetWepVec);
						TE_SetupBeamPoints(clientEyeVec, targetWepVec, g_sprite, 0, 0, 0, 0.5, 3.0, 3.0, 10, 0.0, colorD, 0);
						TE_SendToAll();
						
						new Float:eyeVec[3];
						new Float:speedVec[3];
						GetClientEyeAngles(client, eyeVec);
						GetAngleVectors(eyeVec, speedVec, NULL_VECTOR, NULL_VECTOR);
						speedVec[0]*=-500; 
						speedVec[1]*=-500; 
						speedVec[2]*=550;
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
						TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, speedVec);
					}
				}
				continue;
			}
		}
	}
}