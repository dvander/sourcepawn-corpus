#include <sourcemod>
#include <sdktools>
#include <zombieplague>

#pragma semicolon 1

new icon[MAXPLAYERS+1];
new maxvida[MAXPLAYERS+1];
new Handle:Timers[MAXPLAYERS + 1];


public Plugin:myinfo =
{
	name = "SM Health Bar",
	author = "Franc1sco franug",
	description = "Show health Bar",
	version = "2.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", event_Death, EventHookMode_Pre);
	CreateConVar("sm_HealthBar_version", "2.0", "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i)) OnClientPutInServer(i);
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i)) ClearIcon(i);
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar1.vmt");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar2.vmt");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar3.vmt");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar4.vmt");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar5.vmt");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar6.vmt");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar1.vtf");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar2.vtf");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar3.vtf");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar4.vtf");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar5.vtf");
	AddFileToDownloadsTable("materials/sprites/franug/hp_bar6.vtf");
	PrecacheModel("materials/sprites/franug/hp_bar1.vmt");
	PrecacheModel("materials/sprites/franug/hp_bar2.vmt");
	PrecacheModel("materials/sprites/franug/hp_bar3.vmt");
	PrecacheModel("materials/sprites/franug/hp_bar4.vmt");
	PrecacheModel("materials/sprites/franug/hp_bar5.vmt");
	PrecacheModel("materials/sprites/franug/hp_bar6.vmt");
}

public ZP_OnClientInfected(client)
{
	maxvida[client] = GetClientHealth(client);
	//ClearIcon(client);
	//ClearTimer(Timers[client]);
}

public Action:event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClearIcon(client);
	ClearTimer(Timers[client]);
}

public OnClientPutInServer(client)
{
	maxvida[client] = 6000;
	icon[client] = 0;
}

public OnClientDisconnect(client)
{
	ClearTimer(Timers[client]);
	ClearIcon(client);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(ZP_IsPlayerZombie(client) && (!IsValidClient(attacker) || !ZP_IsPlayerZombie(attacker)))
	{
		new total = RoundToNearest((GetEventFloat(event, "health") / maxvida[client])*100.0);
		if(IconValid(client)) Comprobar(client, total);
		else icon[client] = CreateIcon(client, total);
		ClearTimer(Timers[client]);
		Timers[client] = CreateTimer(4.0, Pasado, client);
	}
}

public Action:Pasado(Handle:timer, any:client)
{
	Timers[client] = INVALID_HANDLE;
	ClearIcon(client);
}

CreateIcon(client, hp) 
{
	if(hp <= 0) return 0;
	
	decl String:iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);

	decl Float:origin[3];
  
	GetClientAbsOrigin(client, origin);				
	origin[2] = origin[2] + 80.0;

	new Ent = CreateEntityByName("env_sprite");
	if(!Ent) return 0;
	
	if(hp >= 100) DispatchKeyValue(Ent, "model", "materials/sprites/franug/hp_bar1.vmt");
	else if(hp >= 80) DispatchKeyValue(Ent, "model", "materials/sprites/franug/hp_bar2.vmt");
	else if(hp >= 60) DispatchKeyValue(Ent, "model", "materials/sprites/franug/hp_bar3.vmt");
	else if(hp >= 40) DispatchKeyValue(Ent, "model", "materials/sprites/franug/hp_bar4.vmt");
	else if(hp >= 20) DispatchKeyValue(Ent, "model", "materials/sprites/franug/hp_bar5.vmt");
	else DispatchKeyValue(Ent, "model", "materials/sprites/franug/hp_bar6.vmt");

	DispatchKeyValue(Ent, "classname", "barra");
	DispatchKeyValue(Ent, "spawnflags", "1");
	DispatchKeyValue(Ent, "scale", "0.08");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0);
 
	return EntIndexToEntRef(Ent);
}

ClearIcon(client)
{
	if(icon[client] != 0)
	{
		new entity = EntRefToEntIndex(icon[client]);
		if(entity != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
		
		icon[client] = 0;
	}
}

IconValid(client)
{
	if(icon[client] != 0)
	{
		new entity = EntRefToEntIndex(icon[client]);
		if(entity != INVALID_ENT_REFERENCE) return true;
	}
	return false;
}

stock ClearTimer(&Handle:timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }     
} 

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || !IsPlayerAlive(client) ) 
        return false; 
     
    return true; 
}

Comprobar(client, hp)
{
	new entidad = EntRefToEntIndex(icon[client]);
	
	if(hp >= 100) {

			SetEntityModel(entidad, "materials/sprites/franug/hp_bar1.vmt");
		
	}
	else if(hp >= 80) {

			SetEntityModel(entidad, "materials/sprites/franug/hp_bar2.vmt");
	}
	else if(hp >= 60) {

			SetEntityModel(entidad, "materials/sprites/franug/hp_bar3.vmt");
	}
	else if(hp >= 40) {

			SetEntityModel(entidad, "materials/sprites/franug/hp_bar4.vmt");
	}
	else if(hp > 20) {

			SetEntityModel(entidad, "materials/sprites/franug/hp_bar5.vmt");
	}
	else {


			SetEntityModel(entidad, "materials/sprites/franug/hp_bar6.vmt");
	}
}
