#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define DMG_BLAST			(1 << 6)	// explosive blast damage

new bool:g_bPlayerIsDucking[MAXPLAYERS+1] = {false,...};
new g_iExplosionModel;

public Plugin:myinfo = 
{
	name = "Duck Explode",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Explodes players on duck O_o",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_duckexplode_version", PLUGIN_VERSION, "Duck explode version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
}

public OnMapStart()
{
	g_iExplosionModel = PrecacheModel("materials/sprites/sprite_fire01.vmt");
}

public OnClientDisconnect(client)
{
	g_bPlayerIsDucking[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_DUCK)
	{
		if(!g_bPlayerIsDucking[client] && IsPlayerAlive(client))
		{
			g_bPlayerIsDucking[client] = true;
			
			new Float:fOrigin[3];
			GetClientAbsOrigin(client, fOrigin);
			fOrigin[2] += 20.0;
			
			// Create explosion
			new iExplosion = CreateEntityByName("env_explosion");
			if(iExplosion != -1)
			{
				TeleportEntity(iExplosion, fOrigin, NULL_VECTOR, NULL_VECTOR);
				SetEntProp(iExplosion, Prop_Data, "m_sFireballSprite", g_iExplosionModel);
				// The amount of damage done by the explosion. 
				SetEntProp(iExplosion, Prop_Data, "m_iMagnitude", 1000);
				// Damagetype
				SetEntProp(iExplosion, Prop_Data, "m_iCustomDamageType", DMG_BLAST);
				SetEntProp(iExplosion, Prop_Data, "m_nRenderMode", 5); // Additive
				DispatchSpawn(iExplosion);
				ActivateEntity(iExplosion);
				AcceptEntityInput(iExplosion, "Explode");
			}
			
			// Play effect
			TE_SetupExplosion(fOrigin, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, 200, 1000);
			TE_SendToAll();
		}
	}
	else
	{
		g_bPlayerIsDucking[client] = false;
	}
}