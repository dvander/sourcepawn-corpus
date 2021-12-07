#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <smlib>

#pragma semicolon 1;

public Plugin:myinfo = 
{
	name = "TrainYourNade",
	author = "cubuspl42",
	description = "",
	version = "0.1",
	url = ""
};

#define N MAXPLAYERS+1

new bool:ClientView[N];

new Float:ClientAngles[N][3];
new Float:ClientOrigins[N][3];

new Float:ClientTargetAngles[N][3];
new Float:ClientTargetOrigins[N][3];

new String:ClientNadeName[N][64];

public SaveTargetPosition(client)
{
	GetClientEyeAngles(client, Float:ClientTargetAngles[client]);
	GetClientAbsOrigin(client, Float:ClientTargetOrigins[client]);
}

public LoadTargetPosition(client)
{
	TeleportEntity(client, Float:ClientTargetOrigins[client], Float:ClientTargetAngles[client], NULL_VECTOR);
}

public SavePosition(client)
{
	GetClientEyeAngles(client, Float:ClientAngles[client]);
	GetClientAbsOrigin(client, Float:ClientOrigins[client]);
}

public LoadPosition(client)
{
	TeleportEntity(client, Float:ClientOrigins[client], Float:ClientAngles[client], NULL_VECTOR);
}

public StartView(client)
{
	if(!ClientView[client])
	{
		if(IsClientInGame(client))
		{
			LoadTargetPosition(client);
		}
		ClientView[client] = true;
	}
}

public StopView(client)
{
	if(ClientView[client])
	{
		if(IsClientInGame(client))
		{
			LoadPosition(client);
		}
		ClientView[client] = false;
	}
}

public OnPluginStart()
{
	HookEvent("smokegrenade_detonate", OnDetonate);
	HookEvent("hegrenade_detonate", OnDetonate);
	HookEvent("flashbang_detonate", OnDetonate);
	HookEvent("weapon_fire", OnShot);
	HookEvent("player_spawned", OnPlayerSpawn);
}

public OnClientDisconnect(client)
{
	StopView(client);
}

public IsGrenadeName(const String:name[], const String:postfix[])
{
	new String:buffer[64];
	Format(buffer, 63, "%s%s", "hegrenade", postfix);
	if(StrEqual(name, buffer)) return true;
	Format(buffer, 63, "%s%s", "smokegrenade", postfix);
	if(StrEqual(name, buffer)) return true;
	Format(buffer, 63, "%s%s", "flashbang", postfix);
	if(StrEqual(name, buffer)) return true;
	else return false;
}

public OnEntityCreated(iEntity, const String:classname[]) 
{
	if(IsGrenadeName(classname, "_projectile")) SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
}

public OnEntitySpawned(iGrenade)
{
	new client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
	//Client_ChangeToLastWeapon(client);
	SavePosition(client);
	CreateTimer(0.6, StartViewAction, client);
}

public Action:StartViewAction(Handle:timer, any:client)
{
	StartView(client);
}

public Action:StopViewAction(Handle:timer, any:client)
{
	StopView(client);
}

public Action:GiveNade(Handle:timer, any:client)
{
	new String:buffer[128] = 
	"give weapon_";
	//"weapon_";
	StrCat(buffer, 127, ClientNadeName[client]);
	FakeClientCommand(client, buffer);
	//Client_GiveWeapon(client, buffer);
}

public OnDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(1.7, StopViewAction, client);
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChatAll("Event: player_spawned");
	if(IsClientInGame(client)) SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
}

public OnShot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[32];
	GetEventString(event, "weapon", String:weapon, 32);
	if(
	!IsGrenadeName(weapon, "")
	&& IsClientInGame(client)) SaveTargetPosition(client);
	else {
		strcopy(ClientNadeName[client], 63, weapon);
		CreateTimer(0.2, GiveNade, client);
	}
}