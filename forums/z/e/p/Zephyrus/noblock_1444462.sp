#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0"

new Handle:g_Enabled = INVALID_HANDLE;
new Handle:g_TeamFilter = INVALID_HANDLE;
new bool:g_ShouldCollide[MAXPLAYERS + 1] = { true, ... }

public Plugin:myinfo =
{
	name = "NoBlock",
	author = "Zephyrus",
	description = "A new NoBlock plugin with TeamFilter, designed to avoid the Mayhem bug.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	g_Enabled = CreateConVar("sm_noblock_enabled", "1");
	g_TeamFilter = CreateConVar("sm_noblock_teamfilter", "1");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
	SDKHook(client, SDKHook_StartTouch, Touch);
	SDKHook(client, SDKHook_Touch, Touch);
}

public OnGameFrame()
{
	if(GetConVarBool(g_TeamFilter))
	{
		new ent;
		new Float:pos[3];
		new Float:ang[3];
		new Float:mins[3];
		new Float:maxs[3];
		ang[0]=90.0;
		ang[1]=0.0;
		ang[2]=0.0;
	   
		for(new i = 1; i<=MaxClients; ++i)
		{
			if (!g_ShouldCollide[i])
			{
				if(IsValidEdict(i) && IsClientInGame(i))
				{
					GetClientEyePosition(i, pos);
					GetClientMins(i, mins);
					GetClientMaxs(i, maxs);

					TR_TraceRayFilter(pos, ang, MASK_PLAYERSOLID, RayType_Infinite, DontHitSelf, i);

					new Float:down[3];

					TR_GetEndPosition(down);

					down[2] -= 100.0;

					TR_TraceHullFilter(pos, down, mins, maxs, MASK_PLAYERSOLID, DontHitSelf, i);

					if (TR_DidHit(INVALID_HANDLE))
					{
						ent = TR_GetEntityIndex(INVALID_HANDLE);
					}

					if((ent == 0 || ent > MaxClients))
					{
						g_ShouldCollide[i]=true;
					}
				}
			}
		}
	}
}
	 
public bool:DontHitSelf(entity, mask, any:data)
{
	if(entity == data)
		return false;
	return true;
}

public bool:ShouldCollide(entity, collisiongroup, contentsmask, bool:result)
{
	if(!GetConVarBool(g_Enabled))
		return true;
		
	if (contentsmask == 33636363)
	{
		if(!GetConVarBool(g_TeamFilter))
		{
			result = false;
			return false;
		}
		
		if(!g_ShouldCollide[entity])
		{
			result = false;
			return false;
		}
		else
		{
			result = true;
			return true;
		}
	}
	
	return true;
}

public Touch(ent1, ent2)
{
	if(!GetConVarBool(g_Enabled))
		return;

	if(ent1 == ent2)
		return;
	if(ent1 > MaxClients || ent1 == 0)
		return;
	if(ent2 > MaxClients || ent2 == 0)
		return;
		
	if(GetConVarBool(g_TeamFilter))
	{
		if(GetClientTeam(ent1) != GetClientTeam(ent2))
		{
			g_ShouldCollide[ent1] = true;
			g_ShouldCollide[ent2] = true;
			return;
		}
	}
	
	g_ShouldCollide[ent1] = false;
	g_ShouldCollide[ent2] = false;
}
