#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define ARRAY_HOMING_SIZE 2
Handle g_hArrayHoming[MAXPLAYERS+1];

enum
{
	ArrayHoming_EntityRef = 0,
	ArrayHoming_CurrentTarget,
}

public void OnPluginStart()
{
	RegAdminCmd("sm_removepart", Command_Remove, ADMFLAG_ROOT);
	RegAdminCmd("sm_addpart", Command_Add, ADMFLAG_ROOT);
}

public Action Command_Add(int client, int args)
{
	if(args > 0)
	{
		char strParticle[64];
		GetCmdArgString(strParticle, 64);
	
		int iParticle = CreateEntityByName("info_particle_system");
		DispatchKeyValue(iParticle, "effect_name", strParticle); 
		DispatchSpawn(iParticle); 
	
		ActivateEntity(iParticle); 
		
		AcceptEntityInput(iParticle, "start"); 
		
		int iData[ARRAY_HOMING_SIZE];
		iData[ArrayHoming_EntityRef] = EntIndexToEntRef(iParticle);
		PushArrayArray(g_hArrayHoming[client], iData);
	}
	else
	{
		PrintToChat(client, "sm_addpart particlename");
	}

	return Plugin_Handled;
}

public void OnGameFrame()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{		
			if(g_hArrayHoming[client] != null)
			{
				float flOrigin[3], flTargetPos[3], flRotation[3];
				GetClientEyePosition(client, flOrigin);
				GetClientEyeAngles(client, flRotation);
				
				float time = GetTickedTime();
				
				for(int i = GetArraySize(g_hArrayHoming[client]) - 1; i >= 0; i--)
				{
					int iData[ARRAY_HOMING_SIZE];
					GetArrayArray(g_hArrayHoming[client], i, iData);
					int iProjectile = EntRefToEntIndex(iData[ArrayHoming_EntityRef]);
			
					if(IsValidEntity(iProjectile))
					{
						GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flTargetPos);
						
						float newX = flOrigin[0] + 50.0 * Cosine(time);	//Partikkelin x + 50 * Cosine(aika)
						float newY = flOrigin[1] + 50.0 * Sine(time);	//Partikkelin y + 50 * Sine(aika)
						float newZ = flOrigin[2] + 50.0 * Tangent(time);	//Partikkelin z + 50 * Tangent(aika)

						time = time + 2 * 3.1415 / GetArraySize(g_hArrayHoming[client]);
			
						flTargetPos[0] = newX;
						flTargetPos[1] = newY;
						flTargetPos[2] = newZ;
						
						DispatchKeyValueVector(iProjectile, "origin", flTargetPos);
						DispatchKeyValueVector(iProjectile, "angles", flRotation);
					}
					else
					{
						RemoveFromArray(g_hArrayHoming[client], i);
					}
				}
			}
			else
			{
				g_hArrayHoming[client] = CreateArray(ARRAY_HOMING_SIZE);	
			}
		}
	}
}

public Action Command_Remove(int client, int args)
{
	if(IsValidClient(client))
	{
		if(g_hArrayHoming[client] != null)
		{
			if(GetArraySize(g_hArrayHoming[client]) > 0)
			{
				int index = FindNotHomingArrayIndex(client);
				if(index == -1) index = 0;
				
				int iData[ARRAY_HOMING_SIZE];
				GetArrayArray(g_hArrayHoming[client], index, iData);
				
				int iProjectile = EntRefToEntIndex(iData[ArrayHoming_EntityRef]);
				
				if(iProjectile != INVALID_ENT_REFERENCE && IsValidEntity(iProjectile))
				{
					AcceptEntityInput(iProjectile, "Stop");
					AcceptEntityInput(iProjectile, "Kill");
				}
			}
		}
	}
	
	return Plugin_Handled;
}

stock FindNotHomingArrayIndex(client)
{
	int index = -1;
	
	if(g_hArrayHoming[client] != null)
	{
		if(GetArraySize(g_hArrayHoming[client]) > 0)
		{
			for(int i = GetArraySize(g_hArrayHoming[client]) - 1; i >= 0; i--)
			{								
				int iData[ARRAY_HOMING_SIZE];
				GetArrayArray(g_hArrayHoming[client], i, iData);
				
				int iProjectile = EntRefToEntIndex(iData[ArrayHoming_EntityRef]);
				if(iProjectile > MaxClients)
				{
					index = i;
					break;
				}
			}
		}
	}
	
	return index;
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
} 