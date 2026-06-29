#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "BoostHealth",
	author = "Greg Sucks",
	description = "Add Health to a Player",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	RegAdminCmd("sm_boosthealth", Command_givehealth, ADMFLAG_SLAY, "[SM] Usage: sm_givehealth <name|#userid>");
}

public Action:Command_givehealth(client, args)
{
	new String:arg1[32]

	GetCmdArg(1, arg1, sizeof(arg1))

	new target = FindTarget(client, arg1)
	if (target == -1)
	{
		return Plugin_Handled;
	}

	new amount = 0;
	if (args > 1)
	{
		decl String:arg2[20];
		GetCmdArg(2, arg2, sizeof(arg2));

		if (StringToIntEx(arg2, amount) == 0)
		{
			ReplyToCommand(client, "[SM] %t", "Invalid Amount");
			return Plugin_Handled;
		}
		if (IsValidEntity(target))
		{
			if (IsClientInGame(target) && IsPlayerAlive(target))
			{
				new health = GetClientHealth(target);
				SetEntityHealth(target, health + amount);
			}
		}
	}

return Plugin_Handled;
}
