/*
It is ripped sm_tele from funcommandsX
*/

#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "0.1"

public Plugin:myinfo ={
	name = "Blink",
	author = "kroleg",
	description = "Self teport",
	version = PL_VERSION,
	url = "http://tf2.kz"
}

//Initation:
public OnPluginStart(){
	RegAdminCmd("blink", Command_Blink, ADMFLAG_CUSTOM1, "Teleports you to where you are aiming!");
}

public Action:Command_Blink(client, args){
	if( !client ){
		ReplyToCommand(client, "[SM] Cannot teleport from rcon");
		return Plugin_Handled;	
	}
		
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	decl Float:position[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite,TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace)){   	 
   	 	TR_GetEndPosition(vStart, trace);
		//GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		position[0] = vStart[0] + (vBuffer[0]*Distance);
		position[1] = vStart[1] + (vBuffer[1]*Distance);
		position[2] = vStart[2] + (vBuffer[2]*Distance);
		CloseHandle(trace);
		TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
	}
	else {
		PrintToChat(client, "\x05[SM]\x01 %s", "Can't blink there");
		CloseHandle(trace);
		return Plugin_Handled;
	}
	return Plugin_Handled;	
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}