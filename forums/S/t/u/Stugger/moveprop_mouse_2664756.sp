#include <sourcemod>
#include <sdktools>

#define VERSION "1."
public Plugin myinfo = { name = "MouseMoveEnt", author = "Jake", description = "A build command with the freedom of moving the [X,Y] position of a prop via mouse",	version = VERSION, url = "http://www.sourcemod.com" };

public void OnPluginStart()
{
	RegAdminCmd("+movexy", MoveProp_XY, 0);
	RegAdminCmd("-movexy", ReleaseProp_XY, 0);
}

Handle grabTimer[MAXPLAYERS+1];
int grabbed_prop = -1;
float grabOffset[3];

public Action MoveProp_XY(client, args)
{		
	if (!IsPlayerAlive(client))
		return Plugin_Handled;
	
	int targEnt = GetClientAimTarget(client, false);
		
	if (targEnt == -1)
		return Plugin_Handled;
	
	float targEntOrigin[3];
	GetEntPropVector(targEnt, Prop_Send, "m_vecOrigin", targEntOrigin);
	
	grabbed_prop = targEnt;
	
	grabOffset[0] = targEntOrigin[0] - GetRayEndPoint(client,0); //not the best method, but better than without
	grabOffset[1] = targEntOrigin[1] - GetRayEndPoint(client,1);

	SetEntityRenderMode(grabbed_prop, RENDER_TRANSALPHA);
	SetEntityRenderColor(grabbed_prop, 150, 25, 40, 200);
	
	DataPack pack;
	grabTimer[client] = CreateDataTimer(0.1, UpdateTraceRay, pack, TIMER_REPEAT);
	pack.WriteCell(client);
	pack.WriteCell(targEnt);
	pack.WriteFloat(targEntOrigin[2]);
	
	return Plugin_Handled;
}

public Action ReleaseProp_XY(client, args)
{
	if (grabbed_prop == -1)
		return Plugin_Handled;
		
	CloseHandle(grabTimer[client]);
	grabTimer[client] = null;
	
	SetEntityRenderColor(grabbed_prop, 255, 255, 255, 255);
	
	grabbed_prop = -1;
	
	return Plugin_Handled;
}

public Action UpdateTraceRay(Handle timer, DataPack pack)
{	
////////UNPACKING THE DATA PACK FOR ITS CONTENTS(MUST BE DONE IN ORDER OF WRITTEN)////////
	int client, ent;
	float entZ;
	
	pack.Reset();
	client = pack.ReadCell();
	ent = pack.ReadCell();
	entZ = pack.ReadFloat();

////////SET THE PROPS NEW POSITION BASED ON OFFSET AND TRACERAY POSITION///////////
	float trX, trY, targEntNewPos[3];
	
	trX = GetRayEndPoint(client,0); //X-axis position of traceray hit
	trY = GetRayEndPoint(client,1); //Y-axis position of traceray hit
	
	targEntNewPos[0] = trX + grabOffset[0];
	targEntNewPos[1] = trY + grabOffset[1];
	targEntNewPos[2] = entZ; //retain the same Z-axis
	
///////FREEZE PROP TO PREVENT IT SPAZZING OUT/////////
	char sClass[32];
	GetEntityClassname(ent, sClass, sizeof(sClass));
	if ((StrContains(sClass, "player") != -1))
		return Plugin_Handled;

	AcceptEntityInput(ent, "DisableMotion");
	
///////FINALLY, MOVE THE PROP////////
	TeleportEntity(ent, targEntNewPos, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

//===================================================================================================================//

stock float GetRayEndPoint(int client, int axis)
{ 
	float RayEndPos[3];
	
	float clientEye[3], clientAngle[3];
	GetClientEyePosition(client, clientEye);
	GetClientEyeAngles(client, clientAngle);

	TR_TraceRayFilter(clientEye, clientAngle, MASK_SOLID, RayType_Infinite, TraceRayTryToHit);
    
	if (TR_DidHit(INVALID_HANDLE))
		TR_GetEndPosition(RayEndPos);
	 
	//Don't know how to return an array, so based on parameter, return either X or Y
	if(axis == 0)	
		return RayEndPos[0]; 
	else if(axis == 1)
		return RayEndPos[1];
		
	return 0.0;
}

public bool TraceRayTryToHit(int entity, int mask)
{
	if((entity > 0 && entity <= MaxClients) || entity == grabbed_prop)
		return false;
	return true;
}  
