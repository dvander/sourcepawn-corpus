#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma semicolon 1

new bool:deagleDropped[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Deagle Spawner",
	author = "Zee",
	description = "A simple plugin to spawn deagles, made on request.",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=243939"
}

public OnPluginStart()
{
	//HookEvent("round_start" , Event_Start);
	HookEvent("player_spawn" 	, Event_Spawn);
	AddCommandListener(Event_Say, "say");
}

public Action:Event_Say(client, const String:command[], argc)
{
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	TrimString(text);
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && StrEqual(text, "!deagle")){
		if(deagleDropped[client] == true){
			new weaponID = GetPlayerWeaponSlot(client, 1);
			CS_DropWeapon(client, weaponID, true, true);
			GivePlayerItem(client, "weapon_deagle");
			deagleDropped[client] = false;
			PrintToChat(client, "Deagle Spawner: Deagle spawned");
			return Plugin_Handled;
		} else {
			PrintToChat(client, "Deagle Spawner: You already spawned a deagle this life");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

//public Action:Event_Start(Handle:event, const String:name[], bool:dontBroadcast)
//{
//	for(new i = 0; i <= MaxClients; i++){
//		deagleDropped[i] = true;
//	}
//}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client)){
		deagleDropped[client] = true;
	}
}