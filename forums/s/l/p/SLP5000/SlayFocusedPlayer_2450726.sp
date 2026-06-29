#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

new clientHit;

public Plugin:myinfo =
{
	name = "SlayFocusedPlayer",
	author = "SLP5000",
	description = "Slays a focused player",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_slayfocusedplayer_version", PLUGIN_VERSION, "SlayFocusedPlayer version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegAdminCmd("sm_fslay", FSlayCommand, ADMFLAG_SLAY, "Slays a focused player");
}

public Action:FSlayCommand(client, args)
{
	if(args > 0) {
		ReplyToCommand(client,"[SM]Usage:sm_fslay");
		return Plugin_Handled;
	}	
	clientHit = -1;
	new Float:flPos[3];
	new Float:flAng[3];
	GetClientEyePosition(client, flPos);
	GetClientEyeAngles(client, flAng);
	new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnoreObjects, client);
	if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace) && clientHit > 0 && clientHit != client)
	{		
		ServerCommand("sm_slay #%d", GetClientUserId(clientHit));
	}	
	return Plugin_Handled;
}

public bool:TraceFilterIgnoreObjects(entity, contentsMask, any:client)
{
	if(entity >= 1 && entity <= MaxClients)
	{
		clientHit = entity;
		return true;
	}
	
	return false;
}	