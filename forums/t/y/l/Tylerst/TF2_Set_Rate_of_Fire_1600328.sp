#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>


#define PLUGIN_VERSION "1.1.3"

public Plugin:myinfo =
{
	name = "TF2 Set Rate of Fire",
	author = "Tylerst",
	description = "Set target(s) rate of fire",
	version = PLUGIN_VERSION,
	url = "none"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}


new Handle:hChat = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;

new Float:g_rof[MAXPLAYERS+1] = 0.0;
new bool:spawnreset[MAXPLAYERS+1] = false;

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_setrof_version", PLUGIN_VERSION, "Set target(s) rate of fire", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	hChat = CreateConVar("sm_setrof_chat", "1", "Enable/Disable Showing rate of fire changes in chat");
	hLog = CreateConVar("sm_setrof_log", "1", "Enable/Disable Logging rate of fire changes");
	
	RegAdminCmd("sm_setrof", Command_SetRateofFire, ADMFLAG_SLAY, "Set target(s) rate of fire, Usage: sm_rof \"target\" \"multiplier\"");

	HookEvent("player_spawn", Event_Spawn);
}

public OnClientPutInServer(client)
{
	g_rof[client] = 0.0;
	spawnreset[client] = false;
}
public OnClientDisconnect_Post(client)
{
	g_rof[client] = 0.0;
	spawnreset[client] = false;
}

public Action:Command_SetRateofFire(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rof \"target\" \"multiplier\"");
		return Plugin_Handled;
	}
	new String:roftarget[32], String:strrof[32], Float:rof;
	GetCmdArg(1, roftarget, sizeof(roftarget));
	GetCmdArg(2, strrof, sizeof(strrof));
	rof = StringToFloat(strrof);
	if(rof <= 0)
	{
		ReplyToCommand(client, "[SM] Rate of fire must be above 0");
		return Plugin_Handled;
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			roftarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if(rof == 1.0)g_rof[target_list[i]] = 0.0;
		else g_rof[target_list[i]] = rof;
		
		if(IsPlayerAlive(target_list[i]))
		{
			TF2_RemoveAllWeapons(target_list[i]);
			new health = GetClientHealth(target_list[i]);
			TF2_RegeneratePlayer(target_list[i]);
			SetEntityHealth(target_list[i], health);
		}
		else spawnreset[target_list[i]] = true;

		if(GetConVarBool(hLog)) LogAction(client, target_list[i], "\"%L\" Set rate of fire for  \"%L\" to (%f)", client, target_list[i], rof);
	}
	if(GetConVarBool(hChat)) ShowActivity2(client, "[SM] ","Set rate of fire for %s to %-.2f", target_name, rof);
	return Plugin_Handled;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(g_rof[client])
	{
		new Handle:weapon = TF2Items_CreateItem(PRESERVE_ATTRIBUTES|OVERRIDE_ATTRIBUTES);
		TF2Items_SetItemIndex(weapon, iItemDefinitionIndex);
		new Float:weaponrof = 100.0/(g_rof[client]*100.0);
		TF2Items_SetAttribute(weapon, 0, 6, weaponrof);
		TF2Items_SetNumAttributes(weapon, 1);	
		hItem = weapon;
		return Plugin_Changed;
	}
	else return Plugin_Continue;
}

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(spawnreset[client])
	{
		TF2_RemoveAllWeapons(client);
		TF2_RegeneratePlayer(client);
		spawnreset[client] = false;
	}
		
}
