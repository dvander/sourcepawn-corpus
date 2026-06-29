#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION  "0.02"

public Plugin:myinfo =
{
	name = "Player Quits (SDKHooks Fix)",
	author = "NIGathan",
	description = "Resolves the issue when running SDKHooks preventing the client quit messages from showing.",
	version = PLUGIN_VERSION,
	url = "http://justca.me/"
};
new Handle:Enabled = INVALID_HANDLE;
new Enable = 1;

new String:clientNames[MAXPLAYERS][MAX_TARGET_LENGTH];

public OnPluginStart()
{
	CreateConVar("sm_quitfix_version", PLUGIN_VERSION, "Player Quits Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Enabled = CreateConVar("sm_quitfix", "1", "Enable player quit messages.", FCVAR_PLUGIN);
	Enable = GetConVarInt(Enabled);
	HookConVarChange(Enabled, OnCvarUpdate);
}

public OnEventShutDown()
{
	UnhookConVarChange(Enabled,OnCvarUpdate);
}

public OnCvarUpdate(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Enable = GetConVarInt(Enabled);
}

public OnClientAuthorized(client, const String:auth[])
{
	if (Enable)
	{
		if (!GetClientName(client, clientNames[client-1], MAX_TARGET_LENGTH))
		{
			LogAction(0,client,"Can't get client's name on authorized, disabling plugin.");
			Enable = 0;
		}
	}
}

public OnClientDisconnect_Post(client)
{
	if (Enable)
	{
		new String:target[5] = "@all";
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		if ((target_count = ProcessTargetString(
				target,
				0,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) > 0)
		{
			for (new i = 0;i < target_count;i++)
			{
				PrintToChat(target_list[i],"Player %s left the game.", clientNames[client-1]);
			}
		}
	}
}
