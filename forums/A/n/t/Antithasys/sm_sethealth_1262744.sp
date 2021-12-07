#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.2.2"

// Globals
new g_iPlayerHealth[MAXPLAYERS + 1] = {-1, ...};
new String:mod[32];
new maxHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};
new target_list[MAXPLAYERS];

// Functions
public Plugin:myinfo =
{
	name = "Set Health",
	author = "Mr. Blip",
	description = "Sets a player or teams health to the specified amount.",
	version = PLUGIN_VERSION,
};


public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("sethealth.phrases");
	CreateConVar("sm_sethealth_version", PLUGIN_VERSION, "SetHealth Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_sethealth", Command_SetHealth, ADMFLAG_SLAY, "sm_sethealth <#userid|name> <amount>");
	HookEvent("player_spawn", Event_Spawn, EventHookMode_PostNoCopy);
	GetGameFolderName(mod, sizeof(mod));
}

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && g_iPlayerHealth[client] != -1)
	{
		SetTargetHealth(client);
	}
}

public OnClientPostAdminCheck(client)
{
	g_iPlayerHealth[client] = -1;
}

public Action:Command_SetHealth(client, args)
{
	decl String:target[32], String:health[10];
	new nHealth;
	

	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sethealth <#userid|name> <amount>");
		return Plugin_Handled;
	}
	else {
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, health, sizeof(health));
		nHealth = StringToInt(health);
	}

	if (nHealth < 0) {
		ReplyToCommand(client, "[SM] Health must be greater then zero.");
		return Plugin_Handled;
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	new target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			target,
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

	for (new i = 0; i < target_count; i++)
	{
		g_iPlayerHealth[i] = nHealth;
	}
	SetTargetsHealth(client, target_count, tn_is_ml);
	
	return Plugin_Handled;

}

stock SetTargetHealth(target)
{
	if (strcmp(mod, "tf") == 0) {
		new class = GetEntProp(target, Prop_Send, "m_iClass");
		
		if (g_iPlayerHealth[target] == 0) {
			FakeClientCommand(target, "explode");
			g_iPlayerHealth[target] = -1;
		}
		else if (g_iPlayerHealth[target] > maxHealth[class]) {
			SetEntProp(target, Prop_Data, "m_iMaxHealth", g_iPlayerHealth[target]);
			SetEntityHealth(target, g_iPlayerHealth[target]);
		}
	}

	else {
		if (g_iPlayerHealth[target] == 0)
			SetEntityHealth(target, 1);
		else
			SetEntityHealth(target, g_iPlayerHealth[target]);
	}
}


stock SetTargetsHealth(client, target_count, tn_is_ml)
{
	for (new i = 0; i < target_count; i++)
	{
		if (strcmp(mod, "tf") == 0) {
			new class = GetEntProp(target_list[i], Prop_Send, "m_iClass");
			
			if (g_iPlayerHealth[i] == 0) {
				FakeClientCommand(target_list[i], "explode");
				g_iPlayerHealth[i] = -1;
			}
			else if (g_iPlayerHealth[i] > maxHealth[class]) {
				SetEntProp(target_list[i], Prop_Data, "m_iMaxHealth", g_iPlayerHealth[i]);
				SetEntityHealth(target_list[i], g_iPlayerHealth[i]);
			}
		}

		else {
			if (g_iPlayerHealth[i] == 0)
				SetEntityHealth(target_list[i], 1);
			else
				SetEntityHealth(target_list[i], g_iPlayerHealth[i]);
		}

		LogAction(client, target_list[i], "\"%L\" set \"%L\" health to  %i", client, target_list[i], g_iPlayerHealth[i]);
		new String:target_name[MAX_TARGET_LENGTH];
		GetClientName(i, target_name, sizeof(target_name));
		if (tn_is_ml)
			ShowActivity2(client, "[SM] ", "%t", "Set Health", target_name, g_iPlayerHealth[i]);
		else
			ShowActivity2(client, "[SM] ", "%t", "Set Health", "_s", target_name, g_iPlayerHealth[i]);
	}
}

	
stock bool:IsValidClient(client, bool:nobots = true)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false; 
    }
	return IsClientInGame(client); 
}