/*******************************************************************************

  No Block for Players and Hostages

  Version: 2.0
  Author: SWAT_88

  1.0 	First version, should work on basically any mod
        Added no hostage/player block.
  1.5	Added !block command.
  2.0	Fixed cvar bug.
   
  Description:
  
	Removes player versus player/hostage collisions.
	Useful for mod-tastic servers running surf maps, etc.
	
  Commands:
  
	Type in chat: !block to become blockable. Sidenote: Only if time > 0. 

  Cvars:

	nb_enabled 	"1"		- 0: disables the plugin - 1: enables the plugin
	nb_hostage	"1"		- 0: blocking hostages - 1 no blocking hostages
	nb_player	"1"		- 0: blocking players - 1 no blocking players
	nb_time		"0"		- 0: disables !block command - x: How long a player will be blockable. This activates the !block command.
	nb_verbose	"2"		- 1: print status only to player - 2: print status to all.
 
  Setup (SourceMod):

	Install the smx file to addons\sourcemod\plugins.
	(Re)Load Plugin or change Map.
	
  TO DO:
  
	Nothing
	
  Copyright:
  
	Everybody can edit this plugin and copy this plugin.
	
  Special Thanks to:
	sslice
	
  HAVE FUN!!!

*******************************************************************************/

#include <sourcemod>
#include <sdktools>

#define NB_VERSION		"2.0"

new Handle:g_enabled;
new Handle:g_version;
new Handle:g_hostage;
new Handle:g_player;
new Handle:g_time;
new Handle:g_verbose;

new g_offsCollisionGroup;

public Plugin:myinfo = 
{
	name = "SM No Block",
	author = "SWAT_88",
	description = "Removes hostage/player collisions...useful for mod-tastic servers running surf maps, etc.",
	version = NB_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	g_enabled = CreateConVar("nb_enabled", "1");
	g_hostage = CreateConVar("nb_hostage", "1");
	g_player = CreateConVar("nb_player", "1");
	g_time = CreateConVar("nb_time", "0");
	g_verbose = CreateConVar("nb_verbose","2");
	g_version = CreateConVar("nb_version", NB_VERSION, "Removes player vs. player/hostage collisions", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(g_version, NB_VERSION);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	
	RegConsoleCmd("say",HandleSay,"",FCVAR_GAMEDLL);
	RegConsoleCmd("say_team",HandleSay,"",FCVAR_GAMEDLL);
	
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_offsCollisionGroup == -1)
	{
		SetConVarInt(g_enabled,0);
		PrintToServer("* FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup");
	}
	else
	{
		SetConVarInt(g_enabled,1);
	}
}

public OnPluginEnd(){
	CloseHandle(g_enabled);
	CloseHandle(g_version);
	CloseHandle(g_hostage);
	CloseHandle(g_player);
	CloseHandle(g_time);
	CloseHandle(g_verbose);
}

public OnEventShutdown()
{
	UnhookEvent("round_start",Event_RoundStart);
	UnhookEvent("player_spawn",Event_PlayerSpawn)
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new entity = GetClientOfUserId(userid);
	
	if(GetConVarInt(g_enabled) == 1 && GetConVarInt(g_player) == 1){
		SetNoBlock(entity);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	new String:sClassName[100];
	
	if(GetConVarInt(g_enabled) == 1 && GetConVarInt(g_hostage) == 1){
		for(new i = 1; i < GetMaxEntities(); i++)
		{
			if(!IsValidEntity(i) || !GetEdictClassname(i, sClassName, sizeof(sClassName)) || !StrEqual("hostage_entity", sClassName))
				continue;
			SetNoBlock(i);
		}
	}
}

public SetNoBlock(entity){
	SetEntData(entity, g_offsCollisionGroup, 2, 4, true);
}

public SetBlock(entity){
	SetEntData(entity, g_offsCollisionGroup, 5, 4, true);
}

public Action:HandleSay(client, args){
	new String:line[30];
	new String:nick[MAX_NAME_LENGTH];
	
	if(GetConVarInt(g_enabled) == 0) return Plugin_Continue;
	if(GetConVarInt(g_time) == 0) return Plugin_Continue;
	if(GetConVarInt(g_player) == 0) return Plugin_Continue;
	
	if (args > 0){
		GetCmdArg(1,line,sizeof(line));
		
		if (StrEqual(line, "!block", false))
		{
			if(!IsBlockable(client))
			{
				SetBlock(client);
				
				if(GetConVarInt(g_verbose) == 1)
					PrintToChat(client,"\x01\x04[No Block]\x01 You are now blockable for %.1f seconds!",GetConVarFloat(g_time));
				else{
					GetClientName(client,nick,sizeof(nick));
					PrintToChatAll("\x01\x04[No Block]\x01 %s is now blockable for %.1f seconds!",nick, GetConVarFloat(g_time));
				}
				
				CreateTimer(GetConVarFloat(g_time),SetNoBlockTimer,client,TIMER_HNDL_CLOSE);
			}
			else{
				PrintToChat(client,"\x01\x04[No Block]\x01 You are already blockable!");
			}
		
		}
	}
	
	return Plugin_Continue;
}

public bool:IsBlockable(client){
	return GetEntData(client,g_offsCollisionGroup,4) == 5; 
}

public Action:SetNoBlockTimer(Handle:timer, any:client){
	new String:nick[MAX_NAME_LENGTH];
	SetNoBlock(client);

	if(GetConVarInt(g_verbose) == 1)
		PrintToChat(client,"\x01\x04[No Block]\x01 You are no longer blockable!");
	else{
		GetClientName(client,nick,sizeof(nick));
		PrintToChatAll("\x01\x04[No Block]\x01 %s is no longer blockable!",nick, GetConVarFloat(g_time));
	}
}
