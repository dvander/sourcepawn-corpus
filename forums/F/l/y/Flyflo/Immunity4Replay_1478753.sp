#include <sourcemod>
#include <admin>
#define PLUGIN_VERSION "2.0.1"

new Handle:v_Enabled = INVALID_HANDLE;
new Handle:v_Name = INVALID_HANDLE;
new Handle:v_Level = INVALID_HANDLE;

new g_ReplayBot = -1;

public Plugin:myinfo = 
{
	name = "[TF2] Immunity4Replay",
	author = "DarthNinja",
	description = "Give your replay bot some immunity!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{	
	CreateConVar("sm_i4r_version", PLUGIN_VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	v_Enabled = CreateConVar("sm_i4r_enable", "1", "Enable/Disable the plugin.", 0, true, 0.0, true, 1.0);
	v_Name = CreateConVar("sm_i4r_name", "replay", "If set to something other then \"replay\", the bot will be renamed to the new value.");
	v_Level = CreateConVar("sm_i4r_level", "9001", "Immunity level for the replay bot");
	
	HookConVarChange(v_Name, OnCvarChanged);
}

SetBotImmunity(client)
{
	new AdminId:admin = CreateAdmin("ReplayBot");
	SetAdminFlag(admin, Admin_Custom1, true);
	SetAdminImmunityLevel(admin, GetConVarInt(v_Level));
	
	SetUserAdmin(client, admin);
}

SetBotName(client)
{
	new String:sName[64];
	new String:sNewName[64];
	GetClientName(client, sName, sizeof(sName));
	GetConVarString(v_Name, sNewName, sizeof(sNewName))
	
	if (!StrEqual(sNewName, sName, true))
	{
		//Names do not match - rename the bot:
		ServerCommand("sm_rename #%i \"%s\"", GetClientUserId(client), sNewName);
	}
}


public OnClientAuthorized(client, const String:steamid[])
{
	if ((g_ReplayBot == -1) && GetConVarBool(v_Enabled)) // Plugin enabled, and replaybot hasnt been seen yet
	{
		if(client > 0 && client <= MaxClients && IsFakeClient(client))
		{
			new String:sName[64];
			GetClientName(client, sName, sizeof(sName));
		
			if(StrEqual(sName, "replay", false))
			{
				SetBotImmunity(client);
				SetBotName(client);
				g_ReplayBot = client;
			}
		}
	}
}

public OnConfigsExecuted()
{
	if (g_ReplayBot != -1)
	{
		SetBotImmunity(g_ReplayBot);
		SetBotName(g_ReplayBot);
	}
}

public OnCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (g_ReplayBot != -1)
	{
		SetBotName(g_ReplayBot);
	}
}