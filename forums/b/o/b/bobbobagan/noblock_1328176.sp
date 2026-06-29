#pragma semicolon 1

// SetEntData(client, g_offsCollisionGroup, 5, 4, true); // CAN NOT PASS THRU ie: Players can jump on each other
// SetEntData(client, g_offsCollisionGroup, 2, 4, true); // Noblock active ie: Players can walk thru each other

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION  "2.0"
#define MESS  "[\x03NoBlock\x01] %t"

new g_CollisionOffset;

new Handle:sm_grenplayer_noblock_version = INVALID_HANDLE;
new Handle:sm_noblock_grenades = INVALID_HANDLE;
new Handle:sm_noblock_players = INVALID_HANDLE;
new Handle:sm_noblock_allow_block = INVALID_HANDLE;
new Handle:sm_noblock_allow_block_time = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Noblock players and Nades",
	author = "Originally by Tony G. Fixed by Rogue",
	description = "Manipulates players and grenades so they can't block each other",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("noblock.phrases");
	
	new String:modname[50];
	GetGameFolderName(modname, sizeof(modname));
	if(!StrEqual(modname,"cstrike",false))
		SetFailState("Sorry! This plugin only works on Counter-Strike: Source.");
	
	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");   
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("sm_block", Command_NoBlock);
	
	sm_grenplayer_noblock_version = CreateConVar("sm_grenplayer_noblock_version", PLUGIN_VERSION, "Noblock Version; not changeable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_noblock_grenades = CreateConVar("sm_noblock_grenades", "1", "Enables/Disables blocking of grenades; 0 - Disabled, 1 - Enabled");
	sm_noblock_players = CreateConVar("sm_noblock_players", "1", "Removes player vs. player collisions");
	sm_noblock_allow_block = CreateConVar("sm_noblock_allow_block", "1", "Allow players to use say !block; 0 - Disabled, 1 - Enabled");
	sm_noblock_allow_block_time = CreateConVar("sm_noblock_allow_block_time", "20.0", "Time limit to say !block command", FCVAR_PLUGIN, true, 0.0, true, 600.0);
	
	HookConVarChange(sm_noblock_players, OnConVarChange);
	SetConVarString(sm_grenplayer_noblock_version, PLUGIN_VERSION);
	AutoExecConfig(true, "sm_noblock");
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == sm_noblock_players)
	{
		if (GetConVarInt(sm_noblock_players) == 1)
		{
			UnblockClientAll();
		}
		else
		{
			BlockClientAll();
			PrintToChatAll(MESS, "noblock disabled");
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (GetConVarInt(sm_noblock_players) == 1)
	{
		EnableNoBlock(client);
	}
}

public Action:Command_NoBlock(client, args)
{
	if (GetConVarInt(sm_noblock_players) == 1 && (GetConVarInt(sm_noblock_allow_block) == 1))
	{
		new Float:Time;
		decl String:nbBuffer[128] = "";
		Time = GetConVarFloat(sm_noblock_allow_block_time);
		
		CreateTimer(Time, Timer_UnBlockPlayer, client);
		PrintToChat(client, MESS, "now solid", Time);
		Format(nbBuffer, sizeof (nbBuffer), "%T", "now solid", LANG_SERVER, Time);
		EnableBlock(client);
	}
	
	return Plugin_Handled;
}

public Action:Timer_UnBlockPlayer(Handle:timer, any:client)
{
	if(!IsClientInGame(client) && !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}    
	
	EnableNoBlock(client);
	return Plugin_Continue;
}

EnableBlock(client)
{
	SetEntData(client, g_CollisionOffset, 5, 4, true);
}

EnableNoBlock(client)
{
	PrintToChat(client, MESS, "noblock enabled");
	SetEntData(client, g_CollisionOffset, 2, 4, true);
	
	if (GetConVarInt(sm_noblock_allow_block) == 1)
		PrintToChat(client, MESS, "block for solid");
}

public OnEntityCreated(entity, const String:classname[])
{
	if (GetConVarInt(sm_noblock_grenades) == 1)
	{
		if (StrEqual(classname, "hegrenade_projectile"))
		{
			SetEntData(entity, g_CollisionOffset, 2, 1, true);
		}
		
		if (StrEqual(classname, "flashbang_projectile"))
		{
			SetEntData(entity, g_CollisionOffset, 2, 1, true);
		}
		
		if (StrEqual(classname, "smokegrenade_projectile"))
		{
			SetEntData(entity, g_CollisionOffset, 2, 1, true);
		}
	}
}

BlockClientAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			EnableBlock(i);
		}
	}
}

UnblockClientAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			EnableNoBlock(i);
		}
	}
}