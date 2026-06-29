#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public OnPluginStart()
{
    CreateTimer(0.5, RenderSkin, _, TIMER_REPEAT);
}

public Action:RenderSkin(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == 2)
				{
					SetEntityRenderColor(i, 255, 0, 255, 255); //Green
				}
				else
				{
					SetEntityRenderColor(i, 0, 255, 0, 255); //Pink
				}
			}
		}
	}
}