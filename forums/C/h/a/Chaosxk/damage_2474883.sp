#pragma semicolon 1

#define PLUGIN_AUTHOR "Tak (Chaosxk)"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

float g_fDamage[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2] Modify damage output",
	author = PLUGIN_AUTHOR,
	description = "Modify damage output",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=291141"
};

public void OnPluginStart()
{
	CreateConVar("sm_mdo_version", PLUGIN_VERSION, "Modify damage output version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_damage", Command_ToggleDamage, ADMFLAG_GENERIC, "Modifies a player damage output.");
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
}

public void OnClientPostAdminCheck(int client)
{
	g_fDamage[client] = 0.0;
	SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_ClientTakeDamageAlive);
}

public Action Command_ToggleDamage(int client, int args)
{
	if (!IsClientInGame(client))
	{
		ReplyToCommand(client, "[SM] You must be in game to use this command.");
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_damage <client> <float: damage> (E.G sm_damage @all 0.5 will make all clients do half damage)");
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	float damage = StringToFloat(arg2);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToCommand(client, "[SM] Can not find client");
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
		if (1 <= target_list[i] <= MaxClients && IsClientInGame(target_list[i]))
			g_fDamage[target_list[i]] = damage;
		
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "%N has modified %t damage output by %-.2f%%.", client, target_name, damage*100);
	else
		ShowActivity2(client, "[SM] ", "%N has modified %s damage output by %-.2f%%.", client, target_name, damage*100);

	return Plugin_Handled;
}

public Action Hook_ClientTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!(1 <= attacker <= MaxClients) || !IsClientInGame(attacker))
		return Plugin_Continue;
		
	if (!g_fDamage[attacker])
		return Plugin_Continue;
		
	damage *= g_fDamage[attacker];
	return Plugin_Changed;
}