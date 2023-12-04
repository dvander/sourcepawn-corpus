#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.00"

public Plugin:myinfo =
{
	name		= "MVM Money Teleport",
	author		= "Recluse",
	description	= "No more annoying manual money collecting",
	version		= PLUGIN_VERSION,
};

stock bool IsValidClient( client, bool replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}

public void OnEntityCreated(int entity, const char[] classname)
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "item_currencypack_custom")) != -1) 
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				new Float:Radius = 10000.0;
				new Float:Pos1[3];
				GetClientEyePosition(i, Pos1);
				Pos1[2] -= 30.0;
					
				new Float:Pos2[3]
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos2);
					
				new Float:distance = GetVectorDistance(Pos1, Pos2);
					
				if(IsValidEntity(ent))
				{
					if(distance <= Radius)
					{
						TeleportEntity(ent, Pos1, NULL_VECTOR, NULL_VECTOR );
					}
				}
			}
		}
	}
}