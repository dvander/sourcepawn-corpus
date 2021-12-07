#include <sourcemod>
#include <sdktools>
#include tf2
#include tf2_stocks

#pragma semicolon 1
new Handle:c_Enabled = INVALID_HANDLE;
new Handle:c_Distance = INVALID_HANDLE;

new Handle:c_BackBurner = INVALID_HANDLE;
new Handle:c_FlameThrower = INVALID_HANDLE;
new Handle:c_Degreaser = INVALID_HANDLE;
new airblastcost[MAXPLAYERS+1];
new bool:CustomOffSwitch[MAXPLAYERS+1];
new bool:FirstSpawned[MAXPLAYERS+1];

new Handle:c_DistanceRequired = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "Pyro Knockback",
	author = "Ugleh",
	description = "Allows Pyros to have a Knockback from Compression Blasts, which gives a double jump effect",
	version = "1.4",
	url = "http://ugleh.com"
}

public OnPluginStart()
{
	c_Enabled   = CreateConVar("sm_pk_enable",    	"1",        "<0/1> Enable PK.");
	c_BackBurner   = CreateConVar("sm_pk_backburner",    	"-1",        "<-1/50/etc> Only set this if you have a Custom BackBurner Airblast Cost.");
	c_FlameThrower   = CreateConVar("sm_pk_flamethrower",    	"-1",        "<-1/20/etc> Only set this if you have a Custom FlameThrower's Airblast Cost.");
	c_Degreaser   = CreateConVar("sm_pk_degreaser",    	"-1",        "<-1/50/etc> Only set this if you have a Custom Degreaser Airblast Cost.");
	c_Distance    = CreateConVar("sm_pk_d",    	"-250.0",    	"<10/20/30/etc> Amount of Push Distance, Negative is pushed, Positive is Pulled.");
	c_DistanceRequired    = CreateConVar("sm_pk_dr",    	"150",    	"<60/120/180/etc> Required distance of entity to push off of.");
	RegConsoleCmd("say", Command_Say);
	HookEvent("player_spawn",SpawnEvent);
}

public Action:SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new Float:origin[3];
	origin[0] = 1180.0;
	origin[1] = -717.0;
	origin[2] = -309.0;
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	if(!FirstSpawned[client]){
		if (GetConVarInt(c_Enabled) == 1){
			PrintToChat(client, "\x04You have Pyro Knockback enabled, to disable it type !pyro.");
		}
		FirstSpawned[client] = true;
	}
}



stock Blast(client)
{
	new Float:vector[3];    
	new Float:lookingloc[3];
	new Float:clientloc[3];
	new Float:angles[3];
	GetClientEyePosition( client, lookingloc );
	GetClientEyeAngles( client, angles );
	
	new Handle:trace = TR_TraceRayFilterEx( lookingloc, angles, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers, client );
	if( TR_DidHit( trace ) )
	{
		TR_GetEndPosition( lookingloc, trace );
	}
	CloseHandle(trace);
	
	GetClientAbsOrigin(client, clientloc);
	MakeVectorFromPoints(clientloc, lookingloc, vector);
	NormalizeVector(vector, vector);
	ScaleVector(vector, GetConVarFloat(c_Distance));
	new TheDistance;
	TheDistance= RoundToNearest(GetVectorDistance(lookingloc, clientloc));
	if(TheDistance < GetConVarInt(c_DistanceRequired)){
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
		
	}	
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GetConVarInt(c_Enabled) == 1 && CustomOffSwitch[client] == false){
		if(TF2_GetPlayerClass(client) == TFClass_Pyro){
			if(buttons & IN_ATTACK2)
			{
				new weapon2 = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(!IsValidEntity(weapon2)) return;
				new ItemDefinition = GetEntProp(weapon2, Prop_Send, "m_iItemDefinitionIndex");
				if(ItemDefinition == 21 || ItemDefinition == 40 || ItemDefinition == 215){
					if(ItemDefinition == 21){
						if(GetConVarInt(c_FlameThrower) >= 0){
							airblastcost[client] = GetConVarInt(c_FlameThrower);
						}else{
							airblastcost[client] = 20;
						}
					}else if(ItemDefinition == 40){
						if(GetConVarInt(c_BackBurner) >= 0){
							airblastcost[client] = GetConVarInt(c_BackBurner);
						}else{
							airblastcost[client] = 50;
						}
					}else if(ItemDefinition == 215){
						if(GetConVarInt(c_Degreaser) >= 0){
							airblastcost[client] = GetConVarInt(c_Degreaser);
						}else{
							airblastcost[client] = 20;
						}
						
					}
					new entvalue;
					new ammoOffset;  
					ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
					entvalue = GetEntData(client, ammoOffset + 4, 4);
					if(entvalue >= airblastcost[client]){
						Blast(client);
					}
					
				}
			}
		}
	}
}
public bool:TraceEntityFilterPlayers(entity, contentsMask) 
{
	return entity > GetMaxClients();
}


public Action:Command_Say(client, args)
{
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	
	if (StrEqual(text[startidx], "!pyro") && GetConVarInt(c_Enabled) == 1)
	{
		if(CustomOffSwitch[client] == true){
			PrintToChat(client, "\x04Pyro Knockback is now ENABLED for you.");
			CustomOffSwitch[client] = false;
		}else{
			PrintToChat(client, "\x04Pyro Knockback is now DISABLED for you.");
			CustomOffSwitch[client] = true;
			
		}
		return Plugin_Handled;
	}
}