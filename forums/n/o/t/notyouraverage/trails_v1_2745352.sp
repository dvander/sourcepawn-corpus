#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_engine>
#include <sdktools_trace>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

new Trails[MAXPLAYERS+1];
new Handle:gH_Enabled = INVALID_HANDLE;
new bool:gB_Enabled;
new spritetrail;

public OnPluginStart()
{	
	gH_Enabled = CreateConVar("sm_trails_enabled", "1", "Trails enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	gB_Enabled = true;
	
	HookConVarChange(gH_Enabled, ConVarChanged);
	
	RegConsoleCmd("sm_trails", Command_Trails, "Toggle Trails");
	
	HookEvent("player_death", Player_Death);
	HookEvent("player_spawn", Player_Death);
	
	LoadTranslations("common.phrases");
	
	AutoExecConfig();
}

public OnMapStart()
{ 
  spritetrail = PrecacheModel("materials/sprites/bluelaser1.vmt"); 
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = StringToInt(newVal)? true:false;
	}
}

public Action:Command_Trails(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	new target = client, String:arg1[MAX_TARGET_LENGTH];
	
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "\x04[Trails]\x01 Plugin is disabled.");
		return Plugin_Handled;
	}
	
	if(IsValidClient(target, true))
	{
		Toggle(target);
		
		return Plugin_Handled;
	}
	
	else if(!IsPlayerAlive(target))
	{
		ReplyToCommand(client, "\x04[Trails]\x03 You have to be alive to toggle !trails.");
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Player_Death(Handle:event, String:name[], bool:dontBroadcast)
{
	OnClientPutInServer(GetClientOfUserId(GetEventInt(event, "userid")));
	
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	Trails[client] = false;
}

public Toggle(client)
{
	if(!Trails[client])
	{
		new Float:vector[3];
  
		GetClientAbsOrigin(client, vector);
		vector[2] += 50;
  
		new rt_i = CreateEntityByName("func_rotating");
		new sp_i = CreateEntityByName("env_spritetrail");

	
	    DispatchKeyValue(client, "targetname", "player");
        SetVariantString("player");
        AcceptEntityInput(rt_i, "SetParent");
	
		// Erstes func_rotating Objekt. 
		DispatchKeyValueVector(rt_i, "origin", vector);
		DispatchKeyValue(rt_i, "targetname", "x_rotating");
		DispatchKeyValue(rt_i, "renderfx", "5");
		DispatchKeyValue(rt_i, "rendermode", "5");
		DispatchKeyValue(rt_i, "renderamt", "255");
		DispatchKeyValue(rt_i, "rendercolor", "255 255 255"); 
		DispatchKeyValue(rt_i, "maxspeed", "200");
		DispatchKeyValue(rt_i, "friction", "20");
		DispatchKeyValue(rt_i, "dmg", "0");
		DispatchKeyValue(rt_i, "solid", "0");
		DispatchKeyValue(rt_i, "spawnflags", "64");
		DispatchSpawn(rt_i); //Objekt gespawnt (erschaffen)
    
		// material, dass das Objekt func_rotating anpasst.
		vector[0] += 35.0; 
		DispatchKeyValueVector(sp_i, "origin", vector);
		DispatchKeyValue(sp_i, "lifetime", "0.5");
		DispatchKeyValue(sp_i, "startwidth", "8.0");
		DispatchKeyValue(sp_i, "endwidth", "1.0");
		DispatchKeyValue(sp_i, "spritename", "materials/sprites/bluelaser1.vmt");
		DispatchKeyValue(sp_i, "rendermode", "5");
		DispatchKeyValue(sp_i, "rendercolor", "255 255 255");
		DispatchKeyValue(sp_i, "renderamt", "255");
		DispatchSpawn(sp_i);
		SetVariantString("x_rotating");
		AcceptEntityInput(sp_i, "SetParent");
		AcceptEntityInput(sp_i, "ShowSprite");
		AcceptEntityInput(rt_i, "Start");
		
		Trails[client] = true;
		PrintToChat(client, "\x04[Trails]\x03 You have enabled !trails");
	}
	
	else
	{
		//AcceptEntityInput(rt_i, "Kill");
		
		//Trails[client] = true
		//PrintToChat(client, "\x04[Trails]\x03 You have disabled !trails");
	}
}

stock bool:IsValidClient(client, bool:bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}