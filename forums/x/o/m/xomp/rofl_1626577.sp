#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new Float:Multi[MAXPLAYERS+1];

new bool:SpeedEnabled[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[TF2] ROFlMod",
	author = "FlaminSarge (orig by EHG)",
	description = "Change the Rate of Fire (ROF) for any client",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_rof", Command_Rof, ADMFLAG_ROOT, "Set ROF on target");
}
public OnClientPutInServer(client)
{
	SpeedEnabled[client] = false;
	Multi[client] = 1.0;
}
public Action:Command_Rof(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rof <#userid|name> [ 1.0 - 3.0 ]");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));

	new Float:amount = StringToFloat(arg2);
	if (amount < 1 || amount > 3)
	{
		ReplyToCommand(client, "[SM] Invalid Amount");
		return Plugin_Handled;
	}

	if (amount == 1.1)
	{
		amount = 0.98;
	}
	else if (amount == 1.2)
	{
		amount = 0.97;
	}
	else if (amount == 1.3)
	{
		amount = 0.96;
	}
	else if (amount == 1.4)
	{
		amount = 0.949;
	}
	else if (amount == 1.5)
	{
		amount = 0.939;
	}
	else if (amount == 1.6)
	{
		amount = 0.92;
	}
	else if (amount == 1.7)
	{
		amount = 0.91;
	}
	else if (amount == 1.8)
	{
		amount = 0.87;
	}
	else if (amount == 1.9)
	{
		amount = 0.85;
	}
	else if (amount == 2.0)
	{
		amount = 0.80;
	}
	else if (amount == 2.1)
	{
		amount = 0.75;
	}
	else if (amount == 2.2)
	{
		amount = 0.70;
	}
	else if (amount == 2.3)
	{
		amount = 0.65;
	}
	else if (amount == 2.4)
	{
		amount = 0.60;
	}
	else if (amount == 2.5)
	{
		amount = 0.55;
	}
	else if (amount == 2.6)
	{
		amount = 0.50;
	}
	else if (amount == 2.7)
	{
		amount = 0.45;
	}
	else if (amount == 2.8)
	{
		amount = 0.35;
	}
	else if (amount == 2.9)
	{
		amount = 0.30;
	}
	else if (amount == 3.0)
	{
		amount = 0.20;
	}
	else amount = (1 / amount);

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
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
		if (amount == 1)
		{
			SpeedEnabled[target_list[i]] = false;
			Multi[target_list[i]] = amount;
			PrintToChat(client, "[SM] ROF disabled for %N", target_list[i]);
		}
		else
		{
			SpeedEnabled[target_list[i]] = true;
			Multi[target_list[i]] = amount;
			PrintToChat(client, "[SM] ROF set to %s for %N", arg2, target_list[i]);
		}
	}

	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	Multi[client] = 1.0;
	SpeedEnabled[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_ATTACK)
	{
		if(SpeedEnabled[client])
		{
			if (Multi[client] != 1.0)
			{
				new ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(ent))
				{
					decl Float:time;
					new Float:ETime = GetGameTime();
					new Float:MAS = Multi[client];
					time = (GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack") - ETime) * MAS + ETime;
					SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", time);
				}
			}
		}
	}
	else if (buttons & IN_ATTACK2)
	{
		if(SpeedEnabled[client])
		{
			if (Multi[client] != 1.0)
			{
				new ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (IsValidEntity(ent))
				{
					decl Float:time;
					new Float:ETime = GetGameTime();
					new Float:MAS = Multi[client];
					time = (GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack") - ETime) * MAS + ETime;
					SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", time);
				}
			}
		}
	}
}