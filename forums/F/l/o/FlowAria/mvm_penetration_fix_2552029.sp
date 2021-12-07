#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

public Plugin myinfo =
{
	name = "MvM Shield Penetration Fix",
	author = "Flowaria",
	description = "Allow to penetration bullets to penetrate projectile shield",
	version = "2.5",
	url = "http://steamcommunity.com/id/flowaria/"
};

bool g_IsOnce[2048];

public void OnPluginStart()
{
	AddTempEntHook("Fire Bullets", Hook_TEFireBullets);
}

public Action Hook_TEFireBullets(const char[] te_name, const Players[], int numClients, float delay)
{
	int iClient = TE_ReadNum("m_iPlayer") + 1;
	if(IsClient(iClient))
	{
		int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(iWeapon))
		{
			int value = 30;
			bool IsOnce;
			if(hasAttributes(iWeapon, 266)) /*projectile penetration: sniper, smg, scattergun etc...*/
			{
				char classname[128];
				GetEntityClassname(iWeapon, classname, sizeof(classname));
				//Sniper rifle
				if(StrEqual(classname, "tf_weapon_sniperrifle", false) || StrEqual(classname, "tf_weapon_sniperrifle_decap", false) || StrEqual(classname, "tf_weapon_sniperrifle_classic", false)) 
				{
					IsOnce = true;
				}
				//Else something scattering weapon
				else 
				{
					IsOnce = false;
				}
			}
			else if(hasAttributes(iWeapon, 397, value)) /*projectile penetration heavy: for heavy weapons*/ 
			{
				IsOnce = false;
			}
			else
			{
				return Plugin_Continue;
			}
			
			float vecOrigin[3], vecAngle[3];
			GetClientEyePosition(iClient, vecOrigin);
			GetClientEyeAngles(iClient, vecAngle);
			
			int[] list = new int[value];
			int[] originent = new int[value]; //originent[0] = iClient;
			int length = TraceRegression(list, value, GetEntProp(iClient, Prop_Send, "m_iTeamNum"), vecOrigin, vecAngle, originent);
			if(length > 0)
			{
				for(int i = 0; i<length;i++)
				{
					if(IsValidEntity(list[i]))
					{
						g_IsOnce[list[i]] = IsOnce;
						SDKHook(list[i], SDKHook_ShouldCollide, ShouldCollide);
						CreateTimer(0.0, KillHookTimer, list[i]);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock int TraceRegression(int[] list, int maxcount, int teamnum, const float origin[3], const float angle[3], int[] originEntity, int count=0)
{
	if(count < maxcount)
	{
		DataPack pack = new DataPack();
		
		pack.WriteCell(teamnum);
		pack.WriteCell(count);
		for(int i = 0; i<count; i++)
		{
			pack.WriteCell(originEntity[i]);
		}
		
		int entity = -1;
		float pos[3];
		Handle trace = TR_TraceRayFilterEx(origin, angle, MASK_ALL, RayType_Infinite, TraceFilterShield, pack);
		if(TR_DidHit(trace))
		{
			entity = TR_GetEntityIndex(trace);
			if(entity > MaxClients) //Meet Shield
			{
				TR_GetEndPosition(pos, trace);
				list[count] = entity;
				originEntity[count] = entity;
			}
			else //Meet World
			{
				CloseHandle(pack);
				CloseHandle(trace);
				
				if(count > 0) return count;
				else			return -1;
			}
		}
		CloseHandle(pack);
		CloseHandle(trace);
		
		return TraceRegression(list, maxcount, teamnum, pos, angle, originEntity, ++count);
	}
	else
	{
		return count;
	}
}

stock bool TraceFilterShield(entity, contentsMask, DataPack pack)
{
	if(entity <= 0)
	{
		return true;
	}
	else if(IsClient(entity))
	{
		return false;
	}
	else
	{
		if(IsValidShield(entity))
		{
			pack.Reset(false);
			int originTeam = pack.ReadCell();
			int originCount = pack.ReadCell();
			
			bool IsHandled = false;
			for(int i = 0; i<originCount; i++)
			{
				if(entity == pack.ReadCell())
				{
					IsHandled = true;
					break;
				}
			}
			if(!IsHandled)
			{
				return GetEntProp(entity, Prop_Send, "m_iTeamNum") != originTeam;
			}
		}
	}
	return false;
}

public Action KillHookTimer(Handle timer, any entity)
{
	SDKUnhook(entity, SDKHook_ShouldCollide, ShouldCollide);
}

public bool ShouldCollide(entity, collisiongroup, contentsmask, bool result)
{
	if(collisiongroup == 0 && contentsmask == 1107312651) //Bullets Collide
	{
		if(g_IsOnce[entity])
			SDKUnhook(entity, SDKHook_ShouldCollide, ShouldCollide);
		return false;
	}
	/*else if(collisiongroup == 13) // Enemy Shield Projectile
	{
		return true;
	}*/
	else if(collisiongroup == 24) // Friendly Shield Projectile // Help prevent projectile being stop when hit the friendly shield
	{
		return false;
	}
	return result; //Else : Same as original
}

stock bool hasAttributes(weapon, id, &value=0)
{
	Address attrib = TF2Attrib_GetByDefIndex(weapon, id);
	if(attrib != Address_Null)
	{
		value = RoundFloat(TF2Attrib_GetValue(attrib));
		return value >= 1;
	}
	return false;
}

stock bool IsClient(entity)
{
	return (1 <= entity <= MaxClients);
}

stock bool IsValidShield(entity)
{
	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrEqual(classname, "entity_medigun_shield", false);
}