#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION 		"1.0"

public Plugin myinfo =
{
	name = "Realism witch break door",
	author = "Hoangzp",
	description = "Mô tả",
	version = PLUGIN_VERSION,
	url = "Link forum tải :))"
}
public OnPluginStart()
{
	AddNormalSoundHook(SoundHook1);
}
public Action SoundHook1(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH],  int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(StrContains(sample, "physics/wood/wood_panel_impact_hard1.wav", false) > -1
	|| StrContains(sample, "doors/Hit_KickMetalDoor1.wav", false) > -1
	|| StrContains(sample, "doors/Hit_KickMetalDoor2.wav", false) > -1
	|| StrContains(sample, "Hit", false) > -1
	|| StrContains(sample, "impact", false) > -1)
	{
		if(IsValidEdict(entity) && IsValidEntity(entity) && entity > 0)
		{
		char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		//PrintToChatAll("NormalSound:sample:%s - entity:%i", sample, entity);
		if(StrEqual(classname, "prop_door_rotating", false))
		{
			//char sDifficulty[128];
			//ConVar g_hDifficulty = FindConVar("mp_gamemode");
			//g_hDifficulty.GetString(sDifficulty, 128);
			//if (StrEqual(sDifficulty, "realism", false))
			{
			//PrintToChatAll("NormalSound:sample:%s - entity:%i", sample, entity);	

				float Posdoor[3], Poswitch[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Posdoor);
				for (new i = MaxClients; i <= GetEntityCount(); i++)
				{
					if (IsValidWitch(i))
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", Poswitch);
						//PrintToChatAll("sequenwitch %i", GetEntProp(i, Prop_Send, "m_nSequence"));
						//GetEntPropString(entity, Prop_Data, "m_iName", classname, sizeof(classname));
						//PrintToChatAll("%s", classname);
						if(GetVectorDistance(Posdoor,Poswitch) <= 100 && (6 <= GetEntProp(i, Prop_Send, "m_nSequence") <= 7 
						|| 38 <= GetEntProp(i, Prop_Send, "m_nSequence") <= 39
						|| (16 <= GetEntProp(i, Prop_Send, "m_nSequence") <= 25) ))
						{
							char strDamageTarget[32];
							float origin[3];
							int dam = CreateEntityByName("point_hurt");
						 	Format(strDamageTarget, sizeof(strDamageTarget), "witchbreak%d", entity);
							DispatchKeyValue(entity, "targetname", strDamageTarget);
							DispatchKeyValue(dam, "DamageTarget", strDamageTarget);
							IntToString(GetEntProp(entity, Prop_Data, "m_iHealth")+1, strDamageTarget, sizeof(strDamageTarget));
							DispatchKeyValue(dam, "Damage", strDamageTarget);
							DispatchKeyValue(dam, "DamageType", "64");
							GetEntPropVector(entity,Prop_Data,"m_vecOrigin",origin);
							TeleportEntity(dam, origin, NULL_VECTOR, NULL_VECTOR);
							DispatchSpawn(dam);
							AcceptEntityInput(dam, "Hurt", entity);
							DispatchKeyValue(entity, "targetname", "");
							RemoveEdict(dam);
						}
					}	
				}
			}
			}
		}
	}
}


stock IsValidWitch(common)
{
	if(common > MaxClients && IsValidEdict(common) && IsValidEntity(common))
	{
		char classname[32];
		GetEdictClassname(common, classname, sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			return true;
		}
	}
	
	return false;
}