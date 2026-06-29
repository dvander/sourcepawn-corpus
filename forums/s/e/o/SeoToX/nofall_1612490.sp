#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"
#define DMG_FALL   (1 << 5)

new bool:g_noFall[MAXPLAYERS+1] = {false, ...};
new bool:g_noSelf[MAXPLAYERS+1] = {false, ...};

new Float:g_noFallGlobal = 0.0;
new Float:g_noSelfGlobal = 0.0;

new Handle:g_noFallCvar = INVALID_HANDLE;
new Handle:g_noSelfCvar = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "[TF2] No Fall Damage",
    author = "[HuN]SeoToX",
    description = "Enable/disable fall damage on players",
    version = PLUGIN_VERSION,
    url = "www.seerpg.net"
}

public OnPluginStart()
{
		RegAdminCmd("sm_nofall", nofall, ADMFLAG_SLAY);
		RegAdminCmd("sm_noself", noself, ADMFLAG_SLAY);
		
		CreateConVar("sm_nofall_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

		g_noFallCvar = CreateConVar("sm_nofalldamage", "0", "Fall damage: 1 = disable", 0, true, 0.0, true, 1.0);
		g_noSelfCvar = CreateConVar("sm_noselfdamage", "0", "Self damage: 1 = disable", 0, true, 0.0, true, 1.0);

		g_noFallGlobal = GetConVarFloat(g_noFallCvar);
		if(g_noFallGlobal != 0.0 && g_noFallGlobal != 1.0)
			g_noFallGlobal = 0.0;

		g_noSelfGlobal = GetConVarFloat(g_noSelfCvar);
		if(g_noSelfGlobal != 0.0 && g_noSelfGlobal != 1.0)
			g_noSelfGlobal = 0.0;

		HookEvent("player_spawn", Event_PlayerSpawn);
		HookConVarChange(g_noFallCvar, NoFallChanged);
		HookConVarChange(g_noSelfCvar, NoSelfChanged);

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}

}

public NoFallChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_noFallGlobal = GetConVarFloat(g_noFallCvar);
	if(g_noFallGlobal != 0.0 && g_noFallGlobal != 1.0)
		g_noFallGlobal = 0.0;
}

public NoSelfChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_noSelfGlobal = GetConVarFloat(g_noSelfCvar);
	if(g_noSelfGlobal != 0.0 && g_noSelfGlobal != 1.0)
		g_noSelfGlobal = 0.0;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	g_noFall[client] = false;
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(damagetype & DMG_FALL)
	{
		if(g_noFall[client] || g_noFallGlobal)
			return Plugin_Handled;
	}

	if(client == attacker)
	{
		if(g_noSelf[client] || g_noSelfGlobal)
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:noself(client,args)
{	
	if (args != 0 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_noself OR sm_noself [target] [0/1]");
		return Plugin_Handled;
	}
	
	if (args == 0 && IsPlayerAlive(client))
	{
		//Do low-level admin self target
		if (!g_noSelf[client]) //On
		{
			g_noSelf[client] = true;
			LogAction(client, client, "\"%L\" disabled self damage on himself", client);
			ReplyToCommand(client,"\x04[NoSelf]\x01 You disabled self damage on yourself!");
			return Plugin_Handled;
		}
		else if
		(g_noSelf[client]) //Off
		{
			g_noSelf[client] = false;
			LogAction(client, client, "\"%L\" enabled self damage on himself", client);
			ReplyToCommand(client,"\x04[NoSelf]\x01 You enabled self damage on yourself!");
			return Plugin_Handled;
		}
		return Plugin_Handled;
	}
	
	else if (args == 2)
	{
		//Create strings
		decl String:buffer[64];
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
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
		
		decl String:Enabled[32];
		GetCmdArg(2, Enabled, sizeof(Enabled));
		new iEnabled = StringToInt(Enabled)
		
		if (iEnabled == 1)
		{
			ReplyToCommand(client,"\x04[NoSelf]\x01 You disabled self damage on %s!", target_name);
		}
		else
		{
			ReplyToCommand(client,"\x04[NoSelf]\x01 You enabled self damage on %s!", target_name);
		}
		
		for (new i = 0; i < target_count; i ++)
		{
			if (iEnabled == 1) //Turn on
			{
				g_noSelf[target_list[i]] = true;
				LogAction(client, target_list[i], "[NoSelf] \"%L\" disabled self damage on \"%L\"", client, target_list[i]);
			}
			else //Turn Off
			{
				g_noSelf[target_list[i]] = false;
				LogAction(client, target_list[i], "[NoSelf] \"%L\" enabled self damage on \"%L\"", client, target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}

public Action:nofall(client,args)
{	
	if (args != 0 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_nofall OR sm_noself [target] [0/1]");
		return Plugin_Handled;
	}
	
	if (args == 0 && IsPlayerAlive(client))
	{
		//Do low-level admin self target
		if (!g_noFall[client]) //On
		{
			g_noFall[client] = true;
			LogAction(client, client, "\"%L\" disabled fall damage on himself", client);
			ReplyToCommand(client,"\x04[NoFall]\x01 You disabled fall damage on yourself!");
			return Plugin_Handled;
		}
		else if
		(g_noFall[client]) //Off
		{
			g_noFall[client] = false;
			LogAction(client, client, "\"%L\" enabled fall damage on himself", client);
			ReplyToCommand(client,"\x04[NoFall]\x01 You enabled fall damage on yourself!");
			return Plugin_Handled;
		}
		return Plugin_Handled;
	}
	
	else if (args == 2)
	{
		//Create strings
		decl String:buffer[64];
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
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
		
		decl String:Enabled[32];
		GetCmdArg(2, Enabled, sizeof(Enabled));
		new iEnabled = StringToInt(Enabled)
		
		if (iEnabled == 1)
		{
			ReplyToCommand(client,"\x04[NoFall]\x01 You disabled fall damage on %s!", target_name);
		}
		else
		{
			ReplyToCommand(client,"\x04[NoFall]\x01 You enabled fall damage on %s!", target_name);
		}
		
		for (new i = 0; i < target_count; i ++)
		{
			if (iEnabled == 1) //Turn on
			{
				g_noFall[target_list[i]] = true;
				LogAction(client, target_list[i], "[NoFall] \"%L\" disabled fall damage on \"%L\"", client, target_list[i]);
			}
			else //Turn Off
			{
				g_noFall[target_list[i]] = false;
				LogAction(client, target_list[i], "[NoFall] \"%L\" enabled fall damage on \"%L\"", client, target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}