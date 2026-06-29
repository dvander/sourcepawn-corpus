#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

new bool:Camera[MAXPLAYERS+1];
new Float:originSaves[MAXPLAYERS+1][3];
new Float:angleSaves[MAXPLAYERS+1][3];

new Handle:g_NoBlock = INVALID_HANDLE;
new Handle:g_RemoveWeapons = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "Camera Mode",
    author = "Internet Bully",
    description = "Let's a user type !camera to scope out a jump",
    url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("player_spawn", OnSpawn, EventHookMode_Post);
	RegConsoleCmd("camera", Cmd_Camera);
	AddCommandListener(BlockCPSave, "sm_cpsave");
	
	g_NoBlock 			= CreateConVar("sm_camera_noblock", "0", "Removes collision for all players.", FCVAR_PLUGIN);
	g_RemoveWeapons 	= CreateConVar("sm_camera_removeweapons", "0", "Removes all weapons from players on spawn.", FCVAR_PLUGIN);
}

public Action:Cmd_Camera(client, args)
{
	if(Camera[client])   //teleport them back and turn off noclip
	{
		TeleportEntity(client, originSaves[client], angleSaves[client], NULL_VECTOR);
		Camera[client] = false;
		SetEntityMoveType(client, MOVETYPE_WALK)
		ReplyToCommand(client, "You are out of camera mode");
	}
	else //save where they were and put them in noclip
	{
		GetClientAbsOrigin(client, originSaves[client]);
		GetClientAbsAngles(client, angleSaves[client]);
		Camera[client] = true;
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		ReplyToCommand(client, "You are in camera mode, !camera to return")
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	InitPlayer(client);
}

public InitPlayer(client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	Camera[client] = false;
	originSaves[client] = NULL_VECTOR;
	angleSaves[client] = NULL_VECTOR;
}

public OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetConVarInt(g_NoBlock) == 1) SetEntData(client, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 4, true); // set noblock on if you don't have it
	if(GetConVarInt(g_RemoveWeapons) == 1) Client_RemoveAllWeapons(client, "", true);
	InitPlayer(client);
}

public Action:BlockCPSave(client, const String:command[], args)
{
	if(Camera[client])
	{
		ReplyToCommand(client, "Stop trying to cheat!");
		TeleportEntity(client, originSaves[client], angleSaves[client], NULL_VECTOR);
		Camera[client] = false;
		SetEntityMoveType(client, MOVETYPE_WALK)
		ReplyToCommand(client, "You are out of camera mode");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}