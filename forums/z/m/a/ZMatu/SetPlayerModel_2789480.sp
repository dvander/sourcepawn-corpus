#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

public Plugin:myinfo = {
	name        = "Set PlayerModel",
	author      = "ZMatu",
	description = "Cambia de modelo a uno personalizado sin errores / Change from model to custom without errors ",
	version     = "1.0",
	url         = "https://github.com/ZMatu"
};
	
public MakeFilesReady()
{	
	//add files of your model for download / añada archivos de su modelo para la descarga
	//example Models and Materials 
	//AddFileToDownloadsTable("models/player/example/player.phy");
	//AddFileToDownloadsTable("models/player/example/player.mdl");
	//AddFileToDownloadsTable("models/player/example/player.vvd");
	//AddFileToDownloadsTable("models/player/example/player.dx90.vtx");
	//AddFileToDownloadsTable("materials/models/player/example.vtf");
	//AddFileToDownloadsTable("materials/models/player/example.vtf");

}
public InitilizePreCache() 
{
	//PrecacheModel("models/player/example/player.phy", true);
	//PrecacheModel("models/player/example/player.vvd", true);
	//PrecacheModel("models/player/example/player.dx90.vtx", true);

}

public OnMapStart()
{

//PrecacheModel("models/weapons/t_arms_leet.mdl", true);
//PrecacheModel("models/player/example/player.mdl", true);

}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}
public Action:Event_PlayerSpawn(Handle:MrEvent, const String:name[], bool:dontBroadcast)
{
	new MrClient = GetClientOfUserId(GetEventInt(MrEvent, "userid"));
	if(IsPlayerAlive(MrClient))
	{
		SetEntityModel(MrClient, "Path your model"); 
	}
	return Plugin_Handled;
}