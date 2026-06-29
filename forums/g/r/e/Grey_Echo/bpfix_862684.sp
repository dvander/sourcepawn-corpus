#include <sourcemod>
#include <entity>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Bouncing Props Fix + NoBlock",
	author = "Grey Echo",
	description = "Fixes the highly irritating bouncing props issue once and for all!",
	version = PLUGIN_VERSION,
	url = "http://www.ke0.us/"
};

new g_offsCollisionGroup;
new bool:g_isHooked;
new bool:g_isNoBlock;
new Handle:sm_noblock;
new i;
new maxents;
new maxclients;
new entvalue;

public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");

	if ( g_offsCollisionGroup == -1 )
	{
		g_isHooked = false;
		PrintToServer("[BPFIX] FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup !!!");
		PrintToServer("[NoBlock] FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup !!!");
	}
	else
	{
		g_isHooked = true;
		PrintToServer("[BPFIX] Bouncing prop fix successfully activated!");

		sm_noblock = CreateConVar("sm_noblock", "1", "Removes player vs. player collisions", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
		HookConVarChange(sm_noblock, OnConVarChange);
	}
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new value = !!StringToInt(newValue);

	if (value == 0)
	{
		if (g_isNoBlock == true)
		{
			g_isNoBlock = false;
			PrintToServer("[NoBlock] Successfully disabled!");
		}
	}
	else
	{
		g_isNoBlock = true;
		PrintToServer("[NoBlock] Successfully enabled!");
	}
}

public OnGameFrame()
{
	if ( g_isHooked == true )
	{
		maxents = GetMaxEntities();

		for( i = 0; i < maxents; i++ )
		{
			if( IsValidEntity(i) )
			{
				entvalue = GetEntData(i, g_offsCollisionGroup);
				maxclients = GetMaxClients();

				if ( (i <= 0 || i > maxclients) && (g_isNoBlock == true) && (entvalue != 2) )
				{
					SetEntData(i, g_offsCollisionGroup, 2, 4, true);
				}
				else if( entvalue != 8 )
				{
					SetEntData(i, g_offsCollisionGroup, 8, 4, true);
				}
			}
		}
	}
}