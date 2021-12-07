#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>

#define PLUGIN_VERSION	"1.01"
#define DOVEMODEL	"models/props_forest/dove.mdl"
#define BIRDMODEL	"models/props_forest/bird.mdl"
// #define TAG			"[VIP]"
#define TAG			"[SM]"
#define BIRDFLAG	ADMFLAG_CUSTOM1
public Plugin:myinfo =
{
	name = "[TF2] Bird Launcher - SDKHooks",
	author = "FlaminSarge",
	description = "Changes rockets/stickies into birds",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};
new bool:BirdLauncher[MAXPLAYERS + 1];
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return (TF2only() ? APLRes_Success : APLRes_Failure);
}
public OnPluginStart()
{
	CreateConVar("sm_birdlauncher_version", PLUGIN_VERSION, "TF2 Bird Launcher", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_birds", BirdLaunch, BIRDFLAG, "sm_birds [0/1]");
//	RegConsoleCmd("sm_birds", BirdLaunch, "sm_birds [0/1]");
}
public Action:BirdLaunch(client, args)
{
	decl String:arg1[32];
	if (!IsValidClient(client)) return Plugin_Continue;
	new bool:launchon;
	if (args == 1)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		launchon = bool:StringToInt(arg1);
	}
	else launchon = !BirdLauncher[client];
	BirdLauncher[client] = launchon;
	PrintToChat(client, "%s Your Rockets and Stickybombs will %s be birds.", TAG, launchon ? "now" : "not");
	return Plugin_Handled;
}
public OnMapStart()
{
	PrecacheModel(BIRDMODEL, true);
	PrecacheModel(DOVEMODEL, true);
	for (new i = 0; i <= MaxClients; i++)
	{
		OnClientPutInServer(i);
	}	
}
public OnClientPutInServer(client) BirdLauncher[client] = false;
public OnClientDisconnect_Post(client) OnClientPutInServer(client);
public OnEntityCreated(entity, const String:classname[])
{
	if (strcmp(classname, "tf_projectile_rocket", false) == 0)
		SDKHook(entity, SDKHook_Spawn, OnRocketSpawned);
	if (strcmp(classname, "tf_projectile_pipe_remote", false) == 0)
		SDKHook(entity, SDKHook_Spawn, OnStickySpawned);
}
public OnRocketSpawned(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner) && BirdLauncher[owner])
		CreateTimer(0.0, Timer_SetRocket, entity, TIMER_FLAG_NO_MAPCHANGE);
}
public OnStickySpawned(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner) && BirdLauncher[owner])
		CreateTimer(0.0, Timer_SetSticky, entity, TIMER_FLAG_NO_MAPCHANGE);
}
stock IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}
public Action:Timer_SetRocket(Handle:timer, any:entity)
{
	if (IsModelPrecached(DOVEMODEL) && IsValidEntity(entity))
	{
		SetEntityModel(entity, DOVEMODEL);
//		SetVariantString("fly_cycle");
//		AcceptEntityInput(entity, "SetAnimation");
	}
}
public Action:Timer_SetSticky(Handle:timer, any:entity)
{
	if (IsModelPrecached(BIRDMODEL) && IsValidEntity(entity))
	{
		SetEntityModel(entity, BIRDMODEL);
//		new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
//		if (IsValidClient(owner))
//		{
//			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
//			if (GetClientTeam(owner) == _:TFTeam_Blue) SetEntityRenderColor(entity, 0, 0, 255, 255);
//			else if (GetClientTeam(owner) == _:TFTeam_Red) SetEntityRenderColor(entity, 255, 0, 0, 255);
//		}
	}
}
TF2only()
{
	new String:Game[10];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		return false;
	}
	return true;
}