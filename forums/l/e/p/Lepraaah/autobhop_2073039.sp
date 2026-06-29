#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{	
	if (IsPlayerAlive(client))
    {
		if (buttons & IN_JUMP)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				{
					if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
					{
						buttons &= ~IN_JUMP;
					}
				}
			}
		}
    }
	
	return Plugin_Continue;
}
