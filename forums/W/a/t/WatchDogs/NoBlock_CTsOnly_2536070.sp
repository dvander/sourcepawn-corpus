#include <sourcemod>
#include <cstrike>

bool b_NBEnable[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "CTs Only No Block",
	author = "sslice, [W]atch [D]ogs",
	description = "Removes player collisions...useful for servers running jail maps.",
	version = "1.1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=299539"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_nb", CMD_SetNoBlock, "Set your no block enable or disable");
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void OnClientDisconnect_Post(int client)
{
	if(b_NBEnable[client]) b_NBEnable[client] = false;
}

public Action CMD_SetNoBlock(int client, int args)
{
	if(GetClientTeam(client) != CS_TEAM_CT)
	{
		ReplyToCommand(client, "[NoBlock] This command is only for CT players.");
		return Plugin_Handled;
	}
	
	if(b_NBEnable[client])
	{
		b_NBEnable[client] = false;
		SetClientNB(client, false);
		ReplyToCommand(client, "[NoBlock] No block has been disabled for you!");
	}
	else
	{
		b_NBEnable[client] = true;
		SetClientNB(client, true);
		ReplyToCommand(client, "[NoBlock] No block has been enabled for you!");
	}
	return Plugin_Handled;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(b_NBEnable[client])
	{
		SetClientNB(client, true);
	}
	else
	{
		SetClientNB(client, false);
	}
}

stock void SetClientNB(int client, bool enable)
{
	if(!IsPlayerAlive(client))
		return;
		
	if(enable)
	{
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
	}
	
}
