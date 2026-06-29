/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.0.0.0";

public Plugin:myinfo = {
	
	name = "Eavesdropper",
	author = "javalia",
	description = "Eavesdropper for test",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>
//#include <cstrike>
//#include "sdkhooks"
//#include "vphysics"
#include "stocklib"

//semicolon!!!!
#pragma semicolon 1

new Handle:g_normalsoudqueue[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new Handle:g_ambientsoundqueue[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

new Float:g_lastdetectposition[MAXPLAYERS + 1][3];

public OnPluginStart(){

	CreateConVar("Eavesdropper_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	//AddAmbientSoundHook(AmbientSoundHook);
	AddNormalSoundHook(NormalSoundHook);
	
	for(new i = 1; i <= MAXPLAYERS; i++){
	
		g_normalsoudqueue[i] = CreateArray();
		g_ambientsoundqueue[i] = CreateArray();
		
	}
	
}

public OnPluginEnd(){



}

public OnClientPutInServer(client){
	
	//this is test, lets not care about resources on test..derp
	//clearsoundqueue(g_normalsoundqueue[client]);
	//clearsoundqueue(g_ambientsoundqueue[client]);
	
	PrintToConsole(client, "blabablalbalba");
	PrintToConsole(client, "blabablalbalba");
	PrintToConsole(client, "blabablalbalba");

}

public OnGameFrame(){

	for(new client = 1; client <= MaxClients; client++){
		
		if(isClientConnectedIngameAlive(client)){
		
			decl Float:cleyepos[3], Float:cleyeangle[3];
			GetClientEyePosition(client, cleyepos); 
			GetClientEyeAngles(client, cleyeangle);
			
			new Handle:traceresulthandle = INVALID_HANDLE;
			
			traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
			
			if(TR_DidHit(traceresulthandle) == true){
				
				TR_GetEndPosition(g_lastdetectposition[client], traceresulthandle);
				
			}
			
			CloseHandle(traceresulthandle);
			
			new arraysize = GetArraySize(g_normalsoudqueue[client]);
			
			for(new i = 0; i < arraysize; i++){
			
				new Handle:datapack = GetArrayCell(g_normalsoudqueue[client], i);
				
				new String:sound[PLATFORM_MAX_PATH], entity, channel, Float:volume, level, pitch, flags;
				
				ReadPackString(datapack, sound, PLATFORM_MAX_PATH);
				channel = ReadPackCell(datapack);
				flags = ReadPackCell(datapack);
				volume = ReadPackFloat(datapack);
				level = ReadPackCell(datapack);
				pitch = ReadPackCell(datapack);
				
				CloseHandle(datapack);
				
				EmitSoundToClient(client, sound, client, channel, level, flags, volume, pitch, -1, cleyepos);
				
			}
			
			ClearArray(g_normalsoudqueue[client]);
		
		}
		
	}

}

public Action:AmbientSoundHook(String:sample[PLATFORM_MAX_PATH], &entity, &Float:volume, &level, &pitch, Float:pos[3], &flags, &Float:delay){

	for(new client = 1; client <= MaxClients; client++){
		
		if(isClientConnectedIngameAlive(client)){
		
			new Float:distance = GetVectorDistance(g_lastdetectposition[client], pos);
			
			//PrintToServer("sound detected %s", sample);
		
		}
		
	}
	
	PrintToServer("sound detected %s", sample);

}

public Action:NormalSoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags){

	if(entity != 0){
	
		new Float:entpos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entpos);
		
		/* for(new i = 0; i < numClients; i++){
			
			if(entity != clients[i] && isClientConnectedIngameAlive(clients[i])){
			
				new Float:distance = GetVectorDistance(g_lastdetectposition[clients[i]], entpos); */
		
		for(new client = 1; client <= MaxClients; client++){
		
			if(isClientConnectedIngameAlive(client) && !IsFakeClient(client) && entity != client){
			
				new Float:distance = GetVectorDistance(g_lastdetectposition[client], entpos);
		
				if(distance <= 200.0){
					
					new Handle:datapack = CreateDataPack();
					WritePackString(datapack, sample);
					WritePackCell(datapack, channel);
					WritePackCell(datapack, flags);
					WritePackFloat(datapack, volume);
					WritePackCell(datapack, level);
					WritePackCell(datapack, pitch);
					ResetPack(datapack);
					
					PushArrayCell(g_normalsoudqueue[client], datapack);
					
					PrintToServer("sound to queue %s", sample);
				
				}
				
			}
				
		}
		
	}

}