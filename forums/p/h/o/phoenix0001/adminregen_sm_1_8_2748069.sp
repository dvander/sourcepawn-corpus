#include <sourcemod>

#pragma newdecls required

#define PLUGIN_VERSION "1.1.1"

Handle adminregen_health = null;
Handle adminregen_time = null;
Handle adminregen_maxhp = null;

bool isRegenActive[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Admin Regenerate",
	author = "joac1144/Zyanthius",
	description = "Lets admins regenerate their health with a command",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_adminregen", AdminRegenCmd, ADMFLAG_SLAY, "Activates regeneration.");
	
	CreateConVar("adminregen_version", PLUGIN_VERSION, "Plugin version. Do not change.", FCVAR_SPONLY);
	adminregen_maxhp = CreateConVar("adminregen_maxhp", "100", "Maximum health you can have by regenerating", FCVAR_SPONLY);
	adminregen_health = CreateConVar("adminregen_health", "2", "Amount of health to regenerate", FCVAR_SPONLY);
	adminregen_time = CreateConVar("adminregen_time", "2.0", "Amount of time (in seconds) between each health", FCVAR_SPONLY);
	AutoExecConfig(true, "plugin.adminregen");
}

public Action AdminRegenCmd(int client, int args)
{
	int cHealth = GetClientHealth(client);

	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	
	if (isRegenActive[client])
	{
		ReplyToCommand(client, "[SM] You have deactivated regeneration!");
		PrintToServer("[SM] %s has deactivated regeneration!", clientName);
		isRegenActive[client] = false;
		return Plugin_Handled;
	}
	else if (cHealth >= GetConVarInt(adminregen_maxhp))
	{
		ReplyToCommand(client, "[SM] You already have maximum hp!");
		PrintToServer("[SM] %s already has maximum hp!", clientName);
		return Plugin_Handled;
	}
	else
	{
		CreateTimer(GetConVarFloat(adminregen_time), RegenTimer, GetClientSerial(client), TIMER_REPEAT);
		ReplyToCommand(client, "[SM] You have activated regeneration!");
		PrintToServer("[SM] %s has activated regeneration!", clientName);
		isRegenActive[client] = true;
	}
	
	return Plugin_Handled;
}

public Action RegenTimer(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	int cHealth = GetClientHealth(client);
	
	if (isRegenActive[client] && client != 0)
	{
		SetEntityHealth(client, cHealth + GetConVarInt(adminregen_health));
	}
	else
	{
		return Plugin_Stop;
	}
	
	if (GetClientHealth(client) > GetConVarInt(adminregen_maxhp))
	{
		SetEntityHealth(client, GetConVarInt(adminregen_maxhp));
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (isRegenActive[client])
	{
		isRegenActive[client] = false;
	}
}





