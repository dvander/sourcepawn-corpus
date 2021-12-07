#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.2.2"

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
}

public Action:Command_SetHealth(client, args)
{
	decl String:target[32], String:mod[32], String:health[10];
	new nHealth;
	new maxHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};

	GetGameFolderName(mod, sizeof(mod));

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
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

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
		if (strcmp(mod, "tf") == 0) {
			new class = GetEntProp(target_list[i], Prop_Send, "m_iClass");
			
			if (nHealth == 0)
				FakeClientCommand(target_list[i], "explode");
			else if (nHealth > maxHealth[class]) {
				SetEntProp(target_list[i], Prop_Data, "m_iMaxHealth", nHealth);
				SetEntityHealth(target_list[i], nHealth);
			}
		}

		else {
			if (nHealth == 0)
				SetEntityHealth(target_list[i], 1);
			else
				SetEntityHealth(target_list[i], nHealth);
		}

		LogAction(client, target_list[i], "\"%L\" set \"%L\" health to  %i", client, target_list[i], nHealth);
	}

	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "%t", "Set Health", target_name, nHealth);
	else
		ShowActivity2(client, "[SM] ", "%t", "Set Health", "_s", target_name, nHealth);
	
	return Plugin_Handled;

}