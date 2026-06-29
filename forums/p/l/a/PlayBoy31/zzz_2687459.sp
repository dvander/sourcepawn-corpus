#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
  name = "bug trace rays",
  author = "PlayBoy31.fr",
  description = "bug",
  version = "1.0.0",
  url = "http://www.fastpath.fr"
};

public OnPluginStart()
{
	//
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2]) 
{	
	if (IsClientPlaying(client))
	{
		if (IsPlayerAlive(client))
		{
			new Float:pos[3];
			new Float:pos_target[3];
			
			GetClientEyePosition(client, pos);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if ((i != client) && (IsClientPlaying(i) && (IsPlayerAlive(i))))
				{
					GetClientEyePosition(i, pos_target);
					
					if (IsPointVisible(pos, pos_target))
					{
						PrintToServer("%d is visible to target %d", client, i);
					}
					else
					{
						//PrintToServer("Not visible");
					}
				}
			}
		}		
	}
	
	return Plugin_Continue;
}

bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_SHOT|CONTENTS_GRATE|CONTENTS_OPAQUE, RayType_EndPoint, TraceEntityFilterPoints);
	return TR_GetFraction() == 1.0;
}

public bool:TraceEntityFilterPoints(entity, mask, data)
{
	return entity > MaxClients;
}

bool:IsClientPlaying(client)
{
	if ((client > 0) && (client <= MaxClients) && IsClientInGame(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}
