#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1"

public Plugin myinfo = 
{
	name = "Panzer Pants Fire Rockets",
	author = "Dr_Newbie",
	description = " ",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new g_entTankTauntActive[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
new g_entTankTauntBoom[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };

public OnEntityCreated(entity, const String:classname[])
{
	if (!StrEqual(classname, "instanced_scripted_scene", false))
	{
		return;
	}
	SDKHook(entity, SDKHook_SpawnPost, OnSceneSpawnedPost);
}

public OnSceneSpawnedPost(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
	if( client > 0 && client <= GetMaxClients() && IsClientInGame(client))
	{
		g_entTankTauntActive[client] = INVALID_ENT_REFERENCE;
		g_entTankTauntBoom[client] = INVALID_ENT_REFERENCE;
		
		decl String:szSceneFile[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_iszSceneFile", szSceneFile, sizeof(szSceneFile));
		
		if (StrContains(szSceneFile, "taunt_vehicle_tank.vcd") != -1)
		{
			g_entTankTauntActive[client] = EntIndexToEntRef(entity);
		}
		else if (StrContains(szSceneFile, "taunt_vehicle_tank_fire.vcd") != -1)
		{
			g_entTankTauntBoom[client] = EntIndexToEntRef(entity);
		}
	}
	return;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_ATTACK)
	{
		if(IsValidEntity(g_entTankTauntBoom[client]))
		{
			g_entTankTauntBoom[client] = INVALID_ENT_REFERENCE;
			
			new Float:vAngles[3]; // pass
			new Float:vAngles2[3]; // original
			new Float:vPosition[3]; // pass
			new Float:vPosition2[3]; // original
			//new Amount = GetConVarInt(cvarAmount);
			new Amount = 1;
			new ClientTeam = GetClientTeam(client);
			//new Float:Random = GetConVarFloat(cvarRandom);
			new Float:Random = 1.0;
			//new Float:DamageMul = GetConVarFloat(cvarDamageMul);
			new Float:DamageMul = 1.0;
			
			GetClientEyeAngles(client, vAngles2);
			GetClientEyePosition(client, vPosition2);
			vPosition[2] = vPosition[2] - 15.0;
			vPosition[0] = vPosition2[0];
			vPosition[1] = vPosition2[1];
			vPosition[2] = vPosition2[2];
			
			new Float:Random2 = Random*-1;
			new counter = 0;
			for (new i = 0; i < Amount; i++)
			{
				vAngles[0] = vAngles2[0] + GetRandomFloat(Random2,Random);
				vAngles[1] = vAngles2[1] + GetRandomFloat(Random2,Random);
				// avoid unwanted collision
				new i2 = i%4;
				switch(i2)
				{
					case 0:
					{
						counter++;
						vPosition[0] = vPosition2[0] + counter;
					}
					case 1:
					{	
						vPosition[1] = vPosition2[1] + counter;
					}
					case 2:
					{
						vPosition[0] = vPosition2[0] - counter;
					}
					case 3:
					{
						vPosition[1] = vPosition2[1] - counter;
					}
				}
				fireProjectile(vPosition, vAngles, 1100.0, 90.0*DamageMul, ClientTeam, client);
			}
		}
	}
	return Plugin_Continue;
}

fireProjectile(Float:vPosition[3], Float:vAngles[3] = NULL_VECTOR, Float:flSpeed = 1100.0, Float:flDamage = 90.0, iTeam, client)
{
	new String:strClassname[32] = "";
	new String:strEntname[32] = "";

	strClassname = "CTFProjectile_Rocket";
	strEntname = "tf_projectile_rocket";

	new iRocket = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iRocket))
		return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*flSpeed;
	vVelocity[1] = vBuffer[1]*flSpeed;
	vVelocity[2] = vBuffer[2]*flSpeed;
	
	SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iRocket,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iRocket,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntData(iRocket, FindSendPropInfo(strClassname, "m_nSkin"), (iTeam-2), 1, true);

	SetEntDataFloat(iRocket, FindSendPropInfo(strClassname, "m_iDeflected") + 4, flDamage, true); // set damage
	TeleportEntity(iRocket, vPosition, vAngles, vVelocity);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iRocket);
	return iRocket;
}