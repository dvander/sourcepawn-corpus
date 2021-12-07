#include <sourcemod>

new Float:g_fGravity[MAXPLAYERS + 1];
new MoveType:gMT_MoveType[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Ladder Gravity Fixer",
	author = "CoMaNdO",
	description = "Fixes player gravity on ladders",
	version = "1.0",
	url = ""
};

public OnGameFrame()
{
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			new MoveType:MT_MoveType = GetEntityMoveType(i), Float:fGravity = GetEntityGravity(i);
			if(MT_MoveType == MOVETYPE_LADDER)
			{
				if(fGravity != 0.0)
				{
					g_fGravity[i] = fGravity;
				}
			}
			else
			{
				if(gMT_MoveType[i] == MOVETYPE_LADDER)
				{
					SetEntityGravity(i, g_fGravity[i]);
				}
				g_fGravity[i] = fGravity;
			}
			gMT_MoveType[i] = MT_MoveType;
		}
		else
		{
			g_fGravity[i] = 1.0;
			gMT_MoveType[i] = MOVETYPE_WALK;
		}
	}
}