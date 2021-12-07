#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[Any] Teleport",
	author = "LenHard"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_tp", Cmd_Teleport, "Teleports you at where you aim");	
}

public Action Cmd_Teleport(int client, int args)
{
	if (0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		float fPos[3], fBackwards[3];
		float fOrigin[3]; GetClientEyePosition(client, fOrigin); 
		float fAngles[3]; GetClientEyeAngles(client, fAngles);
		
		Handle trace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers, client);
		
		bool failed;
		
		int loopLimit = 100;
		
		GetAngleVectors(fAngles, fBackwards, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(fBackwards, fBackwards);
		ScaleVector(fBackwards, 10.0); 
		
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(fPos, trace);
			
			while (IsPlayerStuck(fPos, client) && !failed)
	        {
	            SubtractVectors(fPos, fBackwards, fPos); 
				
	            if (GetVectorDistance(fPos, fOrigin) < 10 || loopLimit-- < 1)
	            {
	                failed = true;
	                fPos = fOrigin;   
	            }
	        }
		}
		delete trace;
		
		TeleportEntity(client, fPos, NULL_VECTOR, NULL_VECTOR);
		PrintCenterText(client, "You have teleported!");
	}
	return Plugin_Handled;
}

bool IsPlayerStuck(float pos[3], int client)
{
    float mins[3]; GetClientMins(client, mins);
    float maxs[3]; GetClientMaxs(client, maxs);
    
    for (int i = 0; i < 3; ++i)
    {
        mins[i] -= 3;
        maxs[i] += 3;
    }

    TR_TraceHullFilter(pos, pos, mins, maxs, MASK_SOLID, TraceRayDontHitPlayers, client);
    return TR_DidHit();
}  

public bool TraceRayDontHitPlayers(int iEntity, int iMask, any iData)
{
	if (0 < iEntity <= MaxClients)
		return false;
	return true;
}