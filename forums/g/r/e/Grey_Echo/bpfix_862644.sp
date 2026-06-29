#include <sourcemod>
#include <entity>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Bouncing Props Fix",
	author = "Grey Echo",
	description = "Fixes the highly irritating bouncing props issue once and for all!",
	version = PLUGIN_VERSION,
	url = "http://www.ke0.us/"
};

new g_offsCollisionGroup;
new bool:g_isHooked;
new i;
new maxents;
new entvalue;

public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if ( g_offsCollisionGroup == -1 )
	{
		g_isHooked = false;
		PrintToServer("* FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup !!!");
	}
	else
	{
		g_isHooked = true;
		PrintToServer("* Bouncing prop fix ACTIVATED successfully!");
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
				if( entvalue != 8 )
				{
					SetEntData(i, g_offsCollisionGroup, 8, 4, true);
				}
			}
		}
	}
}