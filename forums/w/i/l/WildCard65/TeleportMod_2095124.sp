#include <sourcemod>
#include <sdktools>
#define MAX_PLAYERS 64

new Float:playercords[64+1][3];
new Handle:cvarEnable;
new userused[64+1];
new Float:globalcords[3];

public Plugin:myinfo = 
{
	name = "TeleportMod",
	author = "TimberM",
	description = "This Mod Was Created by TimberM -- Allows the user on surf_bedroom to go into the Secret room or the Blue Box, Also allows users on any map to save a location then return back to that location.",
	version = "1.0",
	url = "http://www.timberm-gaming.com"
}
public OnClientPutInServer(client)
{
	userused[client] = 0;
}
public OnPluginStart()
{
	cvarEnable = CreateConVar("teleportmod", "1", "Enable/Disable the plugin", FCVAR_PLUGIN);
	CreateConVar("sm_savelocation_version", "2.00", "The Save location plugin's version", FCVAR_REPLICATED , true, 0.0, true, 1.0);
	RegAdminCmd("sm_savelocation",Command_globalsave,ADMFLAG_KICK,"Save a global location for all ppl");
	RegAdminCmd("sm_save",SaveClientLocation,ADMFLAG_CUSTOM1,"Saves your location.");
	RegAdminCmd("sm_tele",TeleClient,ADMFLAG_CUSTOM1,"Teleports you to your saved location.");
	RegAdminCmd("sm_teleport",TeleClient,ADMFLAG_CUSTOM1,"Teleports you to your saved location.");
	RegAdminCmd("sm_gtele",GlobalTeleClient,ADMFLAG_CUSTOM1,"Teleports you to global location.");
	RegAdminCmd("sm_gteleport",GlobalTeleClient,ADMFLAG_CUSTOM1,"Teleports you to global location.");
}
NotifyPluginDisabled(client)
{
	PrintToChat(client,"[Teleport Mod] Sorry but the plugin is currently disabled");
}
public OnPluginEnd()
{
	CloseHandle(cvarEnable);
	cvarEnable=INVALID_HANDLE;
}
public Action:Command_globalsave(client, args)
{
	if (GetConVarInt(cvarEnable) == 0)
	{
		NotifyPluginDisabled(client);
	}else{
		GetClientAbsOrigin(client,globalcords);
		ReplyToCommand(client,"[Teleport Mod] You saved global location %d,%d,%d", globalcords[0],globalcords[1],globalcords[2]);
	}
	return Plugin_Handled;
}
public Action:GlobalTeleClient(client, args)
{
	if (GetConVarInt(cvarEnable) == 0)
	{
		NotifyPluginDisabled(client);
	}else{
		TeleportEntity(client,globalcords,NULL_VECTOR,NULL_VECTOR);
		ReplyToCommand(client,"Teleport to global position successful.");
	}
	return Plugin_Handled;
}
public Action:SaveClientLocation(client, args)
{
	if (GetConVarInt(cvarEnable) == 0)
	{
		NotifyPluginDisabled(client);
	}else{
		userused[client] = 1;
		GetClientAbsOrigin(client,playercords[client]);
		ReplyToCommand(client,"[Teleport Mod] You just saved your location, Use !tele or !teleport to get to the saved location.")
	}
	return Plugin_Handled;
}
public Action:TeleClient(client, args)
{
	
	if (GetConVarInt(cvarEnable) == 0)
	{
		NotifyPluginDisabled(client);
	}else{
		if (userused[client] == 0)
		{
			ReplyToCommand(client,"You didn't save a location yet, use the !save command to save one.");
		}else{
			TeleportEntity(client, playercords[client],NULL_VECTOR,NULL_VECTOR)
			ReplyToCommand(client,"[Teleport Mod] Teleport successful!");
		}
	}
	return Plugin_Handled;
}

