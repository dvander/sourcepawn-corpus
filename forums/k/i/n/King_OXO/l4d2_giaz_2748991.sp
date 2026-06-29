#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define FILENAME "give_and_spawn"

char sFilePath[128];

int LimitItem[MAXPLAYERS+1];

ConVar LimitWeapons;

#define give "ui/gift_pickup.wav"
#define spawn "ui/pickup_secret01.wav"

public Plugin myinfo =
{
	name		= "[L4D|L4D2]Give Items And Z-Spawn Chat Command",
	author		= "King_OXO",
	description = "Give Items for a player and spawn a zombie per count",
	version		= "3.0",
	url			= "www.sourcemod.net"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, sFilePath, sizeof sFilePath, "data/%s.cfg", FILENAME);
	
	LimitWeapons = CreateConVar("l4d2_chat_command_limit", "25", "limits the number of commands per round", FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_give", GiveChat, "sm_give [ITEM_NAME] <#user id|name>");
	RegConsoleCmd("sm_spawn", SpawnChat, "sm_spawn [ZOMBIE_NAME] <COUNT>");
	
	HookEvent("round_start", Event_Round);
	HookEvent("round_end", Event_Round);
	
	AutoExecConfig(true, "GiveAndSpawn");
}

void Event_Round(Event event, const char[] sName, bool dontBroadCast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client))
	{
		LimitItem[client] = 0;
	}
}

public void OnMapEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		LimitItem[i] = 0;
	}
}

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		LimitItem[i] = 0;
	}
	
	PrecacheSound(give, true);
	PrecacheSound(spawn, true);
}

Action SpawnChat(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		ReplyToCommand(client, "[GiveAndSpawn] Usage: sm_spawn [ZOMBIE_NAME] <COUNT>");
		return Plugin_Handled;
	}
	
	if(IsValidClient(client) && GetClientTeam(client) == 3 && LimitItem[client] < LimitWeapons.IntValue)
	{
		if(args == 1)
		{
			char arg[32];
			GetCmdArg(1, arg, sizeof(arg));
			
			ZSpawn(client, arg, 1);
			
			LimitItem[client] += 1;
		}
		else if(args == 2)
		{
			char arg[32], arg2[2];
			GetCmdArg(1, arg, sizeof(arg));
			GetCmdArg(2, arg2, sizeof(arg2));
		
			int count = StringToInt(arg2);
			
			if(count > 4) 
			{
				CPrintToChat(client, "{blue}[\x04GIAZ{blue}]\x05You \x01Can't Spawn more than\x04 4 Zombies!");
			}
		
			else if(count > 1 && count <= 4)
			{
				ZSpawn(client, arg, count);
			}
			else if(count == 1)
			{
				ZSpawn(client, arg, 1);
			}
			LimitItem[client] += count;
		}
	}
	
	return Plugin_Handled;
}

Action GiveChat(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		ReplyToCommand(client, "[GiveAndSpawn] Usage: sm_give [ITEM_NAME] <#user id|name>");
		return Plugin_Handled;
	}
	
	if(IsValidClient(client) && GetClientTeam(client) == 2 && LimitItem[client] < LimitWeapons.IntValue)
	{
		if(args == 1)
		{
			char arg[48];
			GetCmdArg(1, arg, sizeof(arg));
			
			IGive(client, arg);
			
			LimitItem[client]++;
			
			return Plugin_Handled;
		}
		else if(args == 2)
		{
			char arg[48], arg2[MAX_NAME_LENGTH];
			GetCmdArg(1, arg, sizeof(arg));
			GetCmdArg(2, arg2, sizeof(arg2));
			char target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
			int  targetclient;
			if ((target_count = ProcessTargetString(
				arg2,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof target_name,
				tn_is_ml)) <= 0)
			{
				CPrintToChat(client, "\x01 Client not found");
				return Plugin_Handled;
			}
			else
			{
				for (int i = 0; i < target_count; i++)
				{
					targetclient = target_list[i];
					IGive(targetclient, arg);
				
					LimitItem[client]++;
				}
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Handled;
}

void ZSpawn(int client, char[] name, int count)
{
	if(SpawnForAdmins(client, name))
	{
		int spawnflags = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", spawnflags & ~FCVAR_CHEAT);
	
		for(int i = 1; i <= count; i++)
		{
			FakeClientCommand(client, "z_spawn_old %s", name);
		}
	
		EmitSoundToClient(client, spawn, SNDCHAN_WEAPON, SNDLEVEL_SCREAMING);
		SetCommandFlags("z_spawn", spawnflags|FCVAR_CHEAT);
	}
	else
	{
		CPrintToChat(client, "{blue}[\x04GIAZ{blue}]\x05You \x01Can't\x01 Summon That \x04Zombie!\x01 ( %s )", name);
	}
}

void IGive(int client, const char[] name)
{
	if(ItemsForAdmins(client, name))
	{
		int giveflags = GetCommandFlags("give");
		SetCommandFlags("give", giveflags & ~FCVAR_CHEAT);
	
		FakeClientCommand(client, "give %s", name);
	
		EmitSoundToClient(client, give, SNDCHAN_WEAPON, SNDLEVEL_SCREAMING);
		SetCommandFlags("give", giveflags|FCVAR_CHEAT);
	}
	else
	{
		CPrintToChat(client, "{blue}[\x04GIAZ{blue}]\x05You \x01Can't\x01 Pull This \x04Item! \x01( %s )", name);
	}
}

bool ItemsForAdmins(int client, const char[] command)
{
	KeyValues kv = new KeyValues("List Of Items");
	if (!kv.ImportFromFile(sFilePath))
	{
		SetFailState("[GiveAndSpawn] - %s The File Was Not Created", FILENAME);
		return true;
	}
	
	int adminlevel, adminid;
	AdminId ClientAdminId = GetUserAdmin(client);
	adminid = GetAdminFlags(ClientAdminId, Access_Effective);
	
	if(kv.JumpToKey("Items"))
	{
		if(kv.JumpToKey(command))
		{
			adminlevel = kv.GetNum("admin", 0);
		}
		else
		{
			return true;
		}
	}
	
	delete kv;
	if(adminid >= adminlevel)
	{
		return true;
	}
	
	return false;
}

bool SpawnForAdmins(int client, const char[] command)
{
	KeyValues kv = new KeyValues("List Of Items");
	if (!kv.ImportFromFile(sFilePath))
	{
		SetFailState("[GiveAndSpawn] - %s The File Was Not Created", FILENAME);
		return true;
	}
	
	int adminlevel, adminid;
	AdminId ClientAdminId = GetUserAdmin(client);
	adminid = GetAdminFlags(ClientAdminId, Access_Effective);
	
	if(kv.JumpToKey("Spawns"))
	{
		if(kv.JumpToKey(command))
		{
			adminlevel = kv.GetNum("admin", 0);
		}
		else
		{
			return true;
		}
	}
	
	delete kv;
	if(adminid >= adminlevel)
	{
		return true;
	}
	
	return false;
}

bool IsValidClient(int client)
{
	return client > 0 && client < MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}