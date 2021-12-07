#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <weaponmodel>

public Plugin:myinfo = {
	name = "WeaponModel Test",
	author = "raydan",
	description = "WeaponModel Test",
	version = "1.0",
	url = "http://www.zombiex2.net"
};

public OnPluginStart()
{
	HookEvent("round_start",ev_round_start);
	HookEvent("item_pickup",ev_item_pickup);
	RegConsoleCmd("hookme", Command_hookme);
	RegConsoleCmd("unhookme", Command_unhookme);
}
public OnMapStart()
{
	WeaponAddToDownload("knife_v1","w_knife");
	AddFileToDownloadsTable("materials/models/weapons/swordofdarkness/swordofdarkness.vmt");
	AddFileToDownloadsTable("materials/models/weapons/swordofdarkness/swordofdarkness.vtf");

}
public WeaponAddToDownload(const String:folder[], const String:file[])
{
	static String:weapon_path[65] = "models/zombiex2/weapons/";
	decl String:path[128];
	Format(path,sizeof(path),"%s%s/%s.mdl",weapon_path,folder,file);
	PrecacheModel(path);
	AddFileToDownloadsTable(path);

	Format(path,sizeof(path),"%s%s/%s.dx80.vtx",weapon_path,folder,file);
	AddFileToDownloadsTable(path);
	Format(path,sizeof(path),"%s%s/%s.dx90.vtx",weapon_path,folder,file);
	AddFileToDownloadsTable(path);
	Format(path,sizeof(path),"%s%s/%s.phy",weapon_path,folder,file);
	AddFileToDownloadsTable(path);
	Format(path,sizeof(path),"%s%s/%s.sw.vtx",weapon_path,folder,file);
	AddFileToDownloadsTable(path);
	Format(path,sizeof(path),"%s%s/%s.vvd",weapon_path,folder,file);
	AddFileToDownloadsTable(path);
	Format(path,sizeof(path),"%s%s/%s.xbox.vtx",weapon_path,folder,file);
	AddFileToDownloadsTable(path);
}
public Action:ev_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity;
	entity = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(entity))
	{
		DispatchKeyValue(entity,"model","models/zombiex2/weapons/knife_v1/w_knife.mdl");
		DispatchSpawn(entity);
	}
	return Plugin_Continue;
}
public ev_item_pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl client;
	decl String:item[65];
	client = GetClientOfUserId(GetEventInt(event,"userid"));
	GetEventString(event,"item",item,sizeof(item));
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(StrEqual(item,"knife"))
		{
			decl entity;
			entity = GetPlayerWeaponSlot(client,2);
			if(entity != -1)
			{
				WeaponModel_Hook(entity,"models/zombiex2/weapons/knife_v1/w_knife.mdl");
			}

		}
	}

}
public Action:Command_hookme(client, args)
{  
	ServerCommand("sv_maxspeed 1000");
	if (client && IsClientInGame(client) &&IsPlayerAlive(client))
    	{
		WeaponModel_HookPlayerSpeed(client,400.0);
	}
	return Plugin_Handled;
}
public Action:Command_unhookme(client, args)
{  
	if (client && IsClientInGame(client) &&IsPlayerAlive(client))
    	{
		WeaponModel_UnHookPlayerSpeed(client);
	}
	return Plugin_Handled;
}