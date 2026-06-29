#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2>

#define PLUGIN_VERSION "1.1.1"

new Float:g_fSpawnLocation[MAXPLAYERS+1][3];
new Float:g_fSpawnAngles[MAXPLAYERS+1][3];
new bool:isTF2 = false;

public Plugin:myinfo = {
	name        = "[Any] Return Trip",
	author      = "DarthNinja",
	description = "Returns players to their spawn point.",
	version     = PLUGIN_VERSION,
	url         = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_return_trip_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_returntrip", ReturnPlayer, ADMFLAG_BAN);
	RegAdminCmd("sm_return2spawn", ReturnPlayer, ADMFLAG_BAN);
	HookEvent("player_spawn", PlayerSpawned,  EventHookMode_Post);
	LoadTranslations("common.phrases");
	
	decl String:gamedir[32];
	GetGameFolderName(gamedir, sizeof(gamedir));
	if (StrEqual(gamedir, "tf", false))
		isTF2 = true;
}

public PlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientEyePosition(client, g_fSpawnLocation[client]);
	GetClientEyeAngles(client, g_fSpawnAngles[client]);
}


public Action:ReturnPlayer(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_returntrip <client>");
		return Plugin_Handled;
	}
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));

	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new Float:NullVelocity[3] = 0.0;
	
	ShowActivity2(client, "[SM] ","returned %s to their spawn area.", target_name);
	for (new i = 0; i < target_count; i ++)
	{
		PrintToChat(target_list[i], "\x04[SM]\x01: You have been returned to your spawn.");
		LogAction(client, target_list[i], "%L returned %L to their spawn area.", client, target_list[i]);
		TeleportEntity(target_list[i], g_fSpawnLocation[target_list[i]], g_fSpawnAngles[target_list[i]], NullVelocity /* NULL_VECTOR */ );
		if (isTF2)
			TF2_RegeneratePlayer(target_list[i]);
	}
	return Plugin_Handled;
}