#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"

new bool:g_CanRegen[MAXPLAYERS+1] = {false, ...};
new Handle:allowSelfRegen;

public Plugin:myinfo = {
    name = "[TF2] Regenerate Player",
    author = "DarthNinja",
    description = "The portable resupply cabinet!",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
};

 
public OnPluginStart()
{
	/* Check Game */
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(StrEqual(game, "tf"))
	{
		LogMessage("[TF2] Regenerate Player has loaded!");
	}
	else
	{
		SetFailState("Team Fortress 2 Only.");
	}
	//cvars
	allowSelfRegen = CreateConVar("sm_regen_allow_client", "0", "Allow players to regen their own items/ammo? (will not regen health) 1/0", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("sm_regen_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	//Admin cmds
	RegAdminCmd("sm_regen", Cmd_Regen, ADMFLAG_BAN);
	RegAdminCmd("sm_regen_nohp", Cmd_RegenNoHealth, ADMFLAG_SLAY);
	//Client cmds
	RegConsoleCmd("sm_changeitems", Command_Change, "sm_changeitems - Changes your equipped items");
	//Events
	HookEvent("player_spawn", PlayerSpawn,  EventHookMode_Post);
	//Other
	LoadTranslations("common.phrases");
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_CanRegen[client] = true;
}

public Action:Cmd_Regen(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_regen <target>");
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
	
	for (new i = 0; i < target_count; i ++)
	{
		TF2_RegeneratePlayer(target_list[i]);
		//ShowActivity2(client, "[SM] ","Regenerated %N's health and ammo.", target_list[i]);
		PrintToChat(target_list[i], "An admin regenerated your health and ammo!");
		LogAction(client, target_list[i], "[RegeneratePlayer] %L regenerated %L's health and ammo!", client, target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:Cmd_RegenNoHealth(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_regen_nohp <target>");
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
	
	for (new i = 0; i < target_count; i ++)
	{
		//Get health and save to "health"
		new health = GetClientHealth(target_list[i]);
		//Regen player
		TF2_RegeneratePlayer(target_list[i]);
		//Reset health back to previous value
		SetEntProp(target_list[i], Prop_Send, "m_iHealth", health, 1);
		SetEntProp(target_list[i], Prop_Data, "m_iHealth", health, 1);
		//ShowActivity2(client, "[SM] ","Regenerated %N's ammo and weapons.", target_list[i]);
		PrintToChat(target_list[i], "An admin regenerated your ammo and weapons!");
		LogAction(client, target_list[i], "[RegeneratePlayer] %L regenerated %L's weapons and ammo!", client, target_list[i]);
	}
	
	return Plugin_Handled;
}


public Action:Command_Change(client, args)
{
	if (!g_CanRegen[client])
	{
		PrintToChat(client, "[SM] You cannot use this again this life!");
		return Plugin_Handled;
	}

	if (!GetConVarBool(allowSelfRegen))
	{
		PrintToChat(client, "[SM] This feature is disabled!");
		return Plugin_Handled;
	}

	if (g_CanRegen[client] && GetConVarBool(allowSelfRegen))
	{
		//Get health and save to "health"
		new health = GetClientHealth(client);
		//Regen player
		TF2_RegeneratePlayer(client);
		//Reset health back to previous value
		SetEntProp(client, Prop_Send, "m_iHealth", health, 1);
		SetEntProp(client, Prop_Data, "m_iHealth", health, 1);
		//Block more regens this life
		g_CanRegen[client] = false;
		//----
		PrintToChatAll("%N used !changeitems to change his item loadout in the field!", client);
		//LogAction(client, client, "[RegeneratePlayer] %L regenerated his weapons and ammo!", client);
	}	
	return Plugin_Handled;
}