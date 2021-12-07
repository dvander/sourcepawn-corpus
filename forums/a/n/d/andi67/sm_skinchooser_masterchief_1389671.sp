#include <sourcemod>
#include <sdktools>


#define SM_SKINCHOOSER_MASTERCHIEF_VERSION		"1.0"

new Handle:g_version=INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "SM SKINCHOOSER Masterchief",
	author = "Andi67",
	description = "Simple Skinset Plugin",
	version = "SM_SKINCHOOSER_MASTERCHIEF_VERSION",
	url = "http://www.sourcemod.net"
}
	
public OnMapStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	InitPrecache();
	g_version = CreateConVar("sm_skinchooser_masterchief_version",SM_SKINCHOOSER_MASTERCHIEF_VERSION,"SM SKINCHOOSER MASTERCHIEF VERSION",FCVAR_NOTIFY);
	SetConVarString(g_version,SM_SKINCHOOSER_MASTERCHIEF_VERSION);
}

InitPrecache()
{
	PrecacheModel("models/player/techknow/masterchief/blue_mc.mdl");
	PrecacheModel("models/player/techknow/masterchief/red_mc.mdl");

	AddFileToDownloadsTable("models/player/techknow/masterchief/blue_mc.dx80.vtx");
	AddFileToDownloadsTable("models/player/techknow/masterchief/blue_mc.dx90.vtx");
	AddFileToDownloadsTable("models/player/techknow/masterchief/blue_mc.mdl");
	AddFileToDownloadsTable("models/player/techknow/masterchief/blue_mc.phy");
	AddFileToDownloadsTable("models/player/techknow/masterchief/blue_mc.sw.vtx");
	AddFileToDownloadsTable("models/player/techknow/masterchief/blue_mc.vvd");
	AddFileToDownloadsTable("models/player/techknow/masterchief/red_mc.dx80.vtx");
	AddFileToDownloadsTable("models/player/techknow/masterchief/red_mc.dx90.vtx");
	AddFileToDownloadsTable("models/player/techknow/masterchief/red_mc.mdl");
	AddFileToDownloadsTable("models/player/techknow/masterchief/red_mc.phy");
	AddFileToDownloadsTable("models/player/techknow/masterchief/red_mc.sw.vtx");
	AddFileToDownloadsTable("models/player/techknow/masterchief/red_mc.vvd");

	AddFileToDownloadsTable("materials/models/player/techknow/masterchief/blue_mc.vmt");
	AddFileToDownloadsTable("materials/models/player/techknow/masterchief/blue_mc.vtf");
	AddFileToDownloadsTable("materials/models/player/techknow/masterchief/mc_n.vtf");
	AddFileToDownloadsTable("materials/models/player/techknow/masterchief/red_mc.vmt");
	AddFileToDownloadsTable("materials/models/player/techknow/masterchief/red_mc.vtf");
	AddFileToDownloadsTable("materials/models/player/techknow/masterchief/specmap.vtf");
	AddFileToDownloadsTable("materials/models/player/techknow/masterchief/visor.vmt");
	AddFileToDownloadsTable("materials/models/player/techknow/masterchief/visor.vtf");
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(client) == 2)
	{
		SetEntityModel(client,"models/player/techknow/masterchief/red_mc.mdl");
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	else if (GetClientTeam(client) == 3)
	{
		SetEntityModel(client,"models/player/techknow/masterchief/blue_mc.mdl");
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}
