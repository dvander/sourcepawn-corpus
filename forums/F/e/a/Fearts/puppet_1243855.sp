#include <sourcemod>
#include <sdktools>

forward Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon);

public Plugin:myinfo = {
	name = "Puppet Script",
	author = "pRED*",
	description = "",
	version = "1.0",
	url = ""
};


new controller[MAXPLAYERS+1];
new buttonFlags[MAXPLAYERS+1];
new Float:lastAngles[MAXPLAYERS+1][3];
new Float:lastVel[MAXPLAYERS+1][3];
new lastButtons[MAXPLAYERS+1];
new following[MAXPLAYERS+1];
new bool:weaponSwitch[MAXPLAYERS+1];

public OnPluginStart()
{
	RegAdminCmd("sm_setpuppet", CmdSetPuppet, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removepuppet", CmdRemovePuppet, ADMFLAG_GENERIC);
	
	RegAdminCmd("sm_follow", CmdFollow, ADMFLAG_GENERIC);
	
	RegConsoleCmd("+sm_attack", PlusAttack);
	RegConsoleCmd("-sm_attack", MinusAttack);
	RegConsoleCmd("+sm_attack2", PlusAttack2);
	RegConsoleCmd("-sm_attack2", MinusAttack2);
	RegConsoleCmd("+sm_duck", PlusDuck);
	RegConsoleCmd("-sm_duck", MinusDuck);
	RegConsoleCmd("+sm_jump", PlusJump);
	RegConsoleCmd("-sm_jump", MinusJump)
	RegConsoleCmd("+sm_walk", PlusWalk);
	RegConsoleCmd("-sm_walk", MinusWalk);
	RegConsoleCmd("+sm_reload", PlusReload);
	RegConsoleCmd("-sm_reload", MinusReload);
	RegConsoleCmd("+sm_use", PlusUse);
	RegConsoleCmd("-sm_use", MinusUse);
	RegConsoleCmd("+sm_forward", PlusForward);
	RegConsoleCmd("-sm_forward", MinusForward);
	RegConsoleCmd("+sm_back", PlusBack);
	RegConsoleCmd("-sm_back", MinusBack);
	RegConsoleCmd("+sm_left", PlusLeft);
	RegConsoleCmd("-sm_left", MinusLeft);
	RegConsoleCmd("+sm_right", PlusRight);
	RegConsoleCmd("-sm_right", MinusRight);
	
	RegConsoleCmd("sm_nextinv", NextInv);
	RegConsoleCmd("sm_previnv", PrevInv);
	RegConsoleCmd("sm_drop", Drop);
	
	LoadTranslations("common.phrases")
}

public Action:CmdFollow(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_follow <#userid|name>");
		return Plugin_Handled;	
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		//SetClientViewEntity(client, target_list[i]);
		new Float:origin[3];
		GetClientEyePosition(target_list[i], origin);
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
		//SetEntPropEnt(client, Prop_Send, "moveparent", target_list[i]);
		following[client] = target_list[i];
	}
	
	return Plugin_Handled;	
}

public OnGameFrame()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsPlayerAlive(i))
		{
			if (following[i] && IsClientInGame(following[i]))
			{
				if (controller[following[i]] != i)
				{
					following[i] = 0;	
				}
				else
				{
					new Float:origin[3];
					GetClientEyePosition(following[i], origin);
					TeleportEntity(i, origin, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}		
	}
}

public Action:CmdSetPuppet(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setpuppet <#userid|name>");
		return Plugin_Handled;	
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (target_list[i] != client)
			controller[target_list[i]] = client;
	}
	
	return Plugin_Handled;
}

public Action:CmdRemovePuppet(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removepuppet <#userid|name>");
		return Plugin_Handled;	
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		controller[target_list[i]] = 0;
	}
	
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	controller[client] = 0;
	buttonFlags[client] = 0;
	following[client] = 0;	
}

public OnClientDisconnect(client)
{
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		if (controller[i] == client)
		{
			controller[i] = 0;	
		}
	}	
}

public Action:NextInv(client, puppet)
{
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		if (controller[i] == client)
		{
			ClientCommand(i, "invnext");
		}
	}	

	return Plugin_Handled;
}

public Action:PrevInv(client, puppet)
{
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		if (controller[i] == client)
		{
			ClientCommand(i, "invprev");
		}
	}	

	return Plugin_Handled;
}

public Action:Drop(client, puppet)
{
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		if (controller[i] == client)
		{
			ClientCommand(i, "drop");
		}
	}	

	return Plugin_Handled;
}


public Action:PlusAttack(client, puppet)
{
	buttonFlags[client] |= IN_ATTACK;
	return Plugin_Handled;
}

public Action:MinusAttack(client, puppet)
{
	buttonFlags[client] &= ~IN_ATTACK;
	return Plugin_Handled;
}

public Action:PlusAttack2(client, puppet)
{
	buttonFlags[client] |= IN_ATTACK2;
	return Plugin_Handled;
}

public Action:MinusAttack2(client, puppet)
{
	buttonFlags[client] &= ~IN_ATTACK2;
	return Plugin_Handled;
}

public Action:PlusDuck(client, puppet)
{
	buttonFlags[client] |= IN_DUCK;
	return Plugin_Handled;
}

public Action:MinusDuck(client, puppet)
{
	buttonFlags[client] &= ~IN_DUCK;
	return Plugin_Handled;
}

public Action:PlusJump(client, puppet)
{
	buttonFlags[client] |= IN_JUMP;
	return Plugin_Handled;
}

public Action:MinusJump(client, puppet)
{
	buttonFlags[client] &= ~IN_JUMP;
	return Plugin_Handled;
}

public Action:PlusWalk(client, puppet)
{
	buttonFlags[client] |= IN_SPEED;
	return Plugin_Handled;
}

public Action:MinusWalk(client, puppet)
{
	buttonFlags[client] &= ~IN_SPEED;
	return Plugin_Handled;
}

public Action:PlusReload(client, puppet)
{
	buttonFlags[client] |= IN_RELOAD;
	return Plugin_Handled;
}

public Action:MinusReload(client, puppet)
{
	buttonFlags[client] &= ~IN_RELOAD;
	return Plugin_Handled;
}

public Action:PlusUse(client, puppet)
{
	buttonFlags[client] |= IN_USE;
	return Plugin_Handled;
}

public Action:MinusUse(client, puppet)
{
	buttonFlags[client] &= ~IN_USE;
	return Plugin_Handled;
}

public Action:PlusForward(client, puppet)
{
	buttonFlags[client] |= IN_FORWARD;
	return Plugin_Handled;
}

public Action:MinusForward(client, puppet)
{
	buttonFlags[client] &= ~IN_FORWARD;
	return Plugin_Handled;
}

public Action:PlusBack(client, puppet)
{
	buttonFlags[client] |= IN_BACK;
	return Plugin_Handled;
}

public Action:MinusBack(client, puppet)
{
	buttonFlags[client] &= ~IN_BACK;
	return Plugin_Handled;
}

public Action:PlusLeft(client, puppet)
{
	buttonFlags[client] |= IN_LEFT;
	return Plugin_Handled;
}

public Action:MinusLeft(client, puppet)
{
	buttonFlags[client] &= ~IN_LEFT;
	return Plugin_Handled;
}

public Action:PlusRight(client, puppet)
{
	buttonFlags[client] |= IN_RIGHT;
	return Plugin_Handled;
}

public Action:MinusRight(client, puppet)
{
	buttonFlags[client] &= ~IN_RIGHT;
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	lastAngles[client][0] = angles[0];
	lastAngles[client][1] = angles[1];
	lastAngles[client][2] = angles[2];
	lastVel[client][0] = vel[0];
	lastVel[client][1] = vel[1];
	lastVel[client][2] = vel[2];
	lastButtons[client] = buttons;
	
	
	new control = controller[client];
	if (control)
	{
		new currentButtons = buttonFlags[control] | lastButtons[control];
		
		buttons = currentButtons;
			
		angles[0] = lastAngles[control][0];
		angles[1] = lastAngles[control][1];
		angles[2] = lastAngles[control][2];
		TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
		
		if (currentButtons & IN_FORWARD)
		{
			vel[0] = 400.0;	
		}
		if (currentButtons & IN_BACK)
		{
			vel[0] = -400.0;
		}
		if (currentButtons & (IN_FORWARD|IN_BACK) == IN_FORWARD|IN_BACK)
		{
			vel[0] = 0.0;	
		}
		
		if (currentButtons & IN_LEFT)
		{
			vel[1] = -400.0;	
		}
		if (currentButtons & IN_RIGHT)
		{
			vel[1] = 400.0;
		}
		if (currentButtons & (IN_LEFT|IN_RIGHT) == IN_LEFT|IN_RIGHT)
		{
			vel[1] = 0.0;	
		}
		
		vel[0] = lastVel[control][0];
		vel[1] = lastVel[control][1];
		vel[2] = lastVel[control][2];
	}
		
	return Plugin_Continue;
}