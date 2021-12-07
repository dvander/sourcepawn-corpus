#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.0"

float g_flWaitForNextCommand[MAXPLAYERS + 1];

float g_flTimer[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "TF2 Bot Medic Fix",
	author = "EfeDursun125",
	description = "This Plugin Fixes Medic Bots.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				decl Float:clientEyes[3];
				GetClientEyePosition(client, clientEyes);
				if(class == TFClass_Medic && g_flTimer[client] < GetGameTime())
				{
					if(IsValidEntity(GetPlayerWeaponSlot(client, 1)))
					{
						new MedigunID = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex");
						char weaponclass[64];
						GetEntityNetClass(GetPlayerWeaponSlot(client, 1), weaponclass, sizeof(weaponclass));
						new EProjectiles = GetNearestProjectiles(client);
						if(EProjectiles != -1)
						{
							new Float:EProjectileOrigin[3];
							GetEntPropVector(EProjectiles, Prop_Send, "m_vecOrigin", EProjectileOrigin);
							
							if(GetVectorDistance(clientEyes, EProjectileOrigin) < 750.0)
							{
								if(MedigunID == 998)
								{
									if(TF2_IsPlayerInCondition(client, TFCond_OnFire))
									{
										SetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo(weaponclass, "m_nChargeResistType"), 2);
									}
									else if(!TF2_IsPlayerInCondition(client, TFCond_OnFire) && IsPointVisible(clientEyes, EProjectileOrigin))
									{
										SetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo(weaponclass, "m_nChargeResistType"), 1);
									}
									else
									{
										SetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo(weaponclass, "m_nChargeResistType"), 0);
									}
								}
							}
						}
						
						if(MedigunID == 35)
						{
							if(IsWeaponSlotActive(client, 1))
							{
								if(GetHealth(client) < 50.0 || (GetHealth(client) < 100.0 && (TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Bleeding))))
								{
									for (new enemy = 1; enemy <= MaxClients; enemy++)
									{
										if (IsValidClient(enemy) && IsClientInGame(enemy) && IsPlayerAlive(enemy) && enemy != client && (GetClientTeam(enemy) != GetClientTeam(enemy)))
										{
											new Float:enemyorigin[3];
											GetClientEyePosition(enemy, enemyorigin);
											
											if(IsPointVisible(clientEyes, enemyorigin))
											{
												g_flWaitForNextCommand[client] = GetGameTime() + 5.0;
											}
											else
											{
												if(g_flWaitForNextCommand[client] < GetGameTime())
												{
													FakeClientCommand(client, "taunt");
													g_flWaitForNextCommand[client] = GetGameTime() + 2.0;
												}
											}
										}
									}
								}
							}
						}
					}
					
					g_flTimer[client] = GetGameTime() + 1.0;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

public int GetNearestProjectiles(int client)
{
	decl String:ClassName[32];
	decl Float:clientOrigin[3];
	decl Float:entityOrigin[3];
	new Float:distance = -1.0;
	new nearestEntity = -1;
	for(new entity = 0; entity <= GetMaxEntities(); entity++)
	{
		if(IsValidEdict(entity) && IsValidEntity(entity))
		{
			GetEdictClassname(entity, ClassName, 32);
			
			if(StrContains(ClassName, "tf_projectile_rocket", false) != -1 || StrContains(ClassName, "tf_projectile_pipe", false) != -1 || StrContains(ClassName, "tf_projectile_sentryrocket", false) != -1 || StrContains(ClassName, "tf_weapon_stickbomb", false) != -1)
			{
				if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == GetClientTeam(client))
					continue;
				
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				new Float:edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEntity = entity;
				}
			}
		}
	}
	return nearestEntity;
}

public int GetNearestEntity(int client, char[] classname)
{    
	decl Float:clientOrigin[3];
	decl Float:entityOrigin[3];
	new Float:distance = -1.0;
	new nearestEntity = -1;
	new entity = -1;
	while((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
			GetClientAbsOrigin(client, clientOrigin);
			
			new Float:edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				nearestEntity = entity;
			}
		}
	}
	return nearestEntity;
}

stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  