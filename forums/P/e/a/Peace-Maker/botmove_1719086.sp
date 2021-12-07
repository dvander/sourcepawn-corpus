#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
new Handle:g_hMoveTowardsPosition;
new Handle:g_hWiggle;

public OnPluginStart()
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x83\xEC\x30\x56\x57\x8B\xF1\x8D\x2A\x2A\x56\x50\xE8\x2A\x2A\x2A\x2A\x8B", 21);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hMoveTowardsPosition = EndPrepSDKCall();
	if(g_hMoveTowardsPosition == INVALID_HANDLE)
	{
		SetFailState("CCSBot::MoveTowardsPosition(Vector  const&) not found");
	}
	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x83\xEC\x38\x56\x8B\xF1\x80\xBE\x2A\x2A\x2A\x2A\x00\x0F\x85\x2A\x2A\x2A\x2A\x57", 23);
	g_hWiggle = EndPrepSDKCall();
	if(g_hWiggle == INVALID_HANDLE)
	{
		SetFailState("CCSBot::Wiggle(void) not found");
	}
	
	RegConsoleCmd("sm_move", Cmd_MoveBot);
	RegConsoleCmd("sm_wiggle", Cmd_WiggleBot);
}

public Action:Cmd_MoveBot(client, args) 
{
	if(!client)
	{
		ReplyToCommand(client, "You have to be ingame.");
		return Plugin_Handled;
	}
	
	decl Float:vOrigin[3], Float:vAngle[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngle);
	TR_TraceRayFilter(vOrigin, vAngle, MASK_PLAYERSOLID, RayType_Infinite, FilterNotSelf, client);
	if(TR_DidHit())
	{
		decl Float:vAim[3];
		TR_GetEndPosition(vAim);
		
		new iBot = GetNearestBot(client);
		if(iBot == -1)
		{
			ReplyToCommand(client, "No alive bot found.");
			return Plugin_Handled;
		}
		ReplyToCommand(client, "Ordering bot %N to position %f %f %f", iBot, vAim[0], vAim[1], vAim[2]);
		SDKCall(g_hMoveTowardsPosition, iBot, vAim);
	}
	return Plugin_Handled;
}

public Action:Cmd_WiggleBot(client, args) 
{
	if(!client)
	{
		ReplyToCommand(client, "You have to be ingame.");
		return Plugin_Handled;
	}
	
	new iBot = GetNearestBot(client);
	if(iBot == -1)
	{
		ReplyToCommand(client, "No alive bot found.");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "Ordering bot %N to wiggle", iBot);
	SDKCall(g_hWiggle, iBot);
	
	return Plugin_Handled;
}

public bool:FilterNotSelf(entity, contentsMask, any:data)
{
	return entity != data;
}
	
stock GetNearestBot(client)
{
	new Float:vOrigin[3], Float:vBotOrigin[3], Float:fNearestDistance = -1.0, Float:fCurrentDistance, iNearestBot = -1;
	GetClientAbsOrigin(client, vOrigin);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, vBotOrigin);
			fCurrentDistance = GetVectorDistance(vOrigin, vBotOrigin);
			if(iNearestBot == -1 || fCurrentDistance < fNearestDistance)
			{
				fNearestDistance = fCurrentDistance;
				iNearestBot = i;
			}
		}
	}
	return iNearestBot;
}