#include <sourcemod>
#include <swarmtools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.1.4"

new Handle:v_AllowClients = INVALID_HANDLE;
new Handle:v_Announce = INVALID_HANDLE;
new g_iState[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = "[SWARM] Deluxe Godmod",
	author = "DarthNinja",
	description = "Enables GodMode on clients - Alien Swarm version",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_god", Command_God, "sm_god [#userid|name] [0/1] - Toggles God mod on player(s)");
	RegConsoleCmd("sm_mortal", Command_Mortal, "sm_mortal [#userid|name] - Makes specified players mortal");

	CreateConVar("sm_godmode_swarm_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_AllowClients = CreateConVar("sm_godmode_clients", "0", "Set to 1 to allow clients to set Godmode on themselves", 0, true, 0.0, true, 1.0);
	v_Announce = CreateConVar("sm_godmode_announce", "1", "Tell players if an admin gives/removes their Godmode", 0, true, 0.0, true, 1.0);

	HookEvent("marine_infested", FaceFuckerFix,  EventHookMode_Post);
	
	LoadTranslations("common.phrases");
} 

public FaceFuckerFix(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iMarine = GetEventInt(event, "entindex")
	if (Swarm_IsMarineInfested(iMarine) && g_iState[Swarm_GetClientOfMarine(iMarine)] == 1) //add g_iState check
	{
		Swarm_CureMarineInfestation(iMarine);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (g_iState[Swarm_GetClientOfMarine(victim)] == 1) //just for safety
	{
		damage = 0.0;
		damagetype = DMG_CRUSH;
		return Plugin_Changed;
	}
	return Plugin_Handled;
}


public Action:Command_God(client, args)
{
	if (args != 0 && args != 1 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god [#userid|name] [0/1]");
		return Plugin_Handled;
	}

	new bool:isAdmin = CheckCommandAccess(client, "sm_slay", ADMFLAG_SLAY);

	if (!isAdmin && !GetConVarBool(v_AllowClients))
	{
		ReplyToCommand(client, "[SM] You are not authorized to use this command");
		return Plugin_Handled;
	}

	if (args == 0)
	{
		new RAMIREZ = Swarm_GetMarine(client);
		
		if (RAMIREZ == -1)
		{
			ReplyToCommand(client, "Unable to get your Marine's Entity!\n Godmode not enabled!");
			return Plugin_Handled;
		}
		
		if (g_iState[client] != 1) //Mortal
		{
			ReplyToCommand(client,"\x01[SM] \x04God Mode on");
			g_iState[client] = 1;
			SDKHook(RAMIREZ, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		else // GodMode on
		{
			ReplyToCommand(client,"\x01[SM] \x04God Mode off");
			g_iState[client] = 0;
			SDKUnhook(RAMIREZ, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		return Plugin_Handled;
	}

	if (!isAdmin)
	{
		ReplyToCommand(client, "[SM] You are not authorized to target other players");
		return Plugin_Handled;
	}

	if (args == 2)
	{
		new String:target[32];
		new String:arg2[32];

		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, arg2, sizeof(arg2));

		new toggle = StringToInt(arg2)

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

		new bool:chat = GetConVarBool(v_Announce);

		if (toggle == 1)
		{
			ShowActivity2(client, "\x04[SM] ","\x01Enabled God Mode on \x05%s", target_name);
		}
		else if (toggle == 0)
		{
			ShowActivity2(client, "\x04[SM] ","\x01Disabled God Mode on \x05%s", target_name);
		}

		for (new i = 0; i < target_count; i++)
		{
			new RAMIREZ = Swarm_GetMarine(target_list[i]);
			
			if (RAMIREZ == -1)
			{
				ReplyToCommand(client, "Unable to get %N's Marine Entity!\n Godmode not enabled!", target_list[i]);
				return Plugin_Continue;
			}
			
			if (toggle == 1) //Turn on godmode
			{
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05God Mode\x01!");
				}
				LogAction(client, target_list[i], "%L enabled godmode on %L", client, target_list[i]);
				g_iState[target_list[i]] = 1;
				SDKHook(RAMIREZ, SDKHook_OnTakeDamage, OnTakeDamage);
			}

			else if (toggle == 0) //Turn off godmode
			{
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05God Mode\x01!");
				}
				LogAction(client, target_list[i], "%L disabled godmode on %L", client, target_list[i]);
				g_iState[target_list[i]] = 0;
				SDKUnhook(RAMIREZ, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}

	if (args == 1)
	{
		new String:target[32];

		GetCmdArg(1, target, sizeof(target));

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

		new bool:chat = GetConVarBool(v_Announce);

		ShowActivity2(client, "\x04[SM] ","\x01Toggled God Mode on \x05%s", target_name);

		for (new i = 0; i < target_count; i++)
		{
			new RAMIREZ = Swarm_GetMarine(target_list[i]);
			
			if (RAMIREZ == -1)
			{
				ReplyToCommand(client, "Unable to get %N's Marine Entity!\n Godmode not enabled!", target_list[i]);
				return Plugin_Continue;
			}
			
			if (RAMIREZ == -1)
			{
				ReplyToCommand(client, "Unable to get your Marine's Entity!\n Godmode not enabled!");
				return Plugin_Handled; 
			}
			
			if (g_iState[target_list[i]] != 1) // -> Turn on godmode
			{
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05God Mode\x01!");
				}
				LogAction(client, target_list[i], "%L enabled godmode on %L", client, target_list[i]);
				g_iState[target_list[i]] = 1;
				SDKHook(RAMIREZ, SDKHook_OnTakeDamage, OnTakeDamage);
			}

			else //Turn off godmode
			{
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05God Mode\x01!");
				}
				LogAction(client, target_list[i], "%L disabled godmode on %L", client, target_list[i]);
				g_iState[target_list[i]] = 0;
				SDKUnhook(RAMIREZ, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}

	return Plugin_Handled;
}


public Action:Command_Mortal( client, args )
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_mortal [#userid|name]");
		return Plugin_Handled;
	}

	new bool:isAdmin = CheckCommandAccess(client, "sm_slay", ADMFLAG_SLAY);

	if (args == 0)
	{
		new RAMIREZ = Swarm_GetMarine(client);
		
		if (RAMIREZ == -1)
		{
			return Plugin_Continue;
		}
		
		ReplyToCommand(client,"\x01[SM] \x04You are now mortal!");
		g_iState[client] = 0;
		SDKUnhook(RAMIREZ, SDKHook_OnTakeDamage, OnTakeDamage);
		return Plugin_Handled;
	}

	if (!isAdmin)
	{
		ReplyToCommand(client, "[SM] You are not authorized to target other players");
		return Plugin_Handled;
	}


	if (args == 1)
	{
		new String:target[32];
		GetCmdArg(1, target, sizeof(target));

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

		new bool:chat = GetConVarBool(v_Announce);

		ShowActivity2(client, "\x04[SM] ","\x01Made \x05%s\x01 mortal", target_name);

		for (new i = 0; i < target_count; i++)
		{
			new RAMIREZ = Swarm_GetMarine(target_list[i]);
			if (g_iState[target_list[i]] != 0) //Not mortal
			{
				if (RAMIREZ == -1)
				{
					return Plugin_Continue;
				}
				
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has made you \x05Mortal\x01!");
				}
				LogAction(client, target_list[i], "%L made %L mortal", client, target_list[i]);
				g_iState[target_list[i]] = 0;
				SDKUnhook(RAMIREZ, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
	return Plugin_Handled;
}