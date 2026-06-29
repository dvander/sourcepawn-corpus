/**
 * ====================
 *     Zombie Riot
 *   File: gigante.inc
 *   Author: [NotD] l0calh0st
 *   www.notdelite.com
 * ====================
 */
#include <sourcemod>
#include <sdktools>

new Handle:repeatTimer;

new maxPlayers;
#define GIGANTEMODEL "models/player/slow/el_g_fix2/slow_gigante.mdl"

public OnPluginStart()
{
	repeatTimer = CreateTimer(0.5, DotInfo, _, TIMER_REPEAT);
	maxPlayers = GetMaxClients();
}

public OnMapStart()
{
	PrecacheSound("npc/zombie/zombie_alert1.wav", true);
	PrecacheSound("npc/ichthyosaur/snap.wav", true);
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
			if (StrEqual(model, GIGANTEMODEL))
			{
				new target;
				target = GetClientAimTarget(client, true);
				
				new Float:clientVec[3];
				new Float:targetVec[3];
				GetClientAbsOrigin(client, clientVec);
				GetClientAbsOrigin(target, targetVec);
				if (GetVectorDistance(clientVec, targetVec) < 100)
				{
					new Float:eyeAngles[3];
					new Float:push[3];
					GetClientEyeAngles(client, eyeAngles);
					push[0] = (2500.0 * Cosine(DegToRad(eyeAngles[1])));
					push[1] = (2500.0 * Sine(DegToRad(eyeAngles[1])));
					push[2] = 1500.0;
					TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, push);
					EmitSoundToAll("npc/zombie/zombie_alert1.wav");
					ScreenShake(target);
					
					new targetHealth = (GetClientHealth(target) - 10);
					
					if ((targetHealth) <= 0)
						 ForcePlayerSuicide(target);
					else
						SetEntityHealth(target, targetHealth);
				}
				if (GetClientHealth(client) < 10000)
				{
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
				}
			}
		}
	}
}