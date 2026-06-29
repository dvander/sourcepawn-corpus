#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:EntPos[2048][3];
new bool:PosChange[2048];

public Plugin:myinfo =
{
	name = "LagFixer",
	author = "tRololo312312",
	description = "Might solve some lag issues on some maps.",
	version = "1.1",
	url = "https://steamcommunity.com/profiles/76561198039186809/"
};

public OnPluginStart()
{
	CreateTimer(7.0, CheckPos, _, TIMER_REPEAT);
}

public Action:CheckPos(Handle:timer)
{
	decl Float:currentPos[3];
	new index;
	new i = -1;
	while((i = FindEntityByClassname(i, "phys_bone_follower")) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(i))
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", currentPos);
			if(EntPos[i][0] != 0.0)
			{
				for(index = 0; index < 3; index++)
				{
					if(currentPos[index] != EntPos[i][index])
					{
						PosChange[i] = true;
						break;
					}
					else if(PosChange[i] && index == 2)
						PosChange[i] = false;
				}
			}

			for(index = 0; index < 3; index++)
			{
				EntPos[i][index] = currentPos[index];
			}
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "phys_bone_follower"))
	{
		if(IsValidEntity(entity))
		{
			SDKHook(entity, SDKHook_SetTransmit, HideIt);
			EntPos[entity] = Float:{0.0, 0.0, 0.0};
			PosChange[entity] = false;
		}
	}
}

public Action HideIt(int iEntity, int iClient)
{
	if(!IsFakeClient(iClient) && PosChange[iEntity])
		return Plugin_Handled;
	return Plugin_Continue;
}
