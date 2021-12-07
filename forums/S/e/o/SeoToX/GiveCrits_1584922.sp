#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

//new Handle:v_PowerTime = INVALID_HANDLE;
new bool:g_FullCrit[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo = 
{
    name = "[TF2] GiveCrits",
    author = "[HuN]SeoToX",
    description = "Giving fullcrits",
    version = PLUGIN_VERSION,
    url = "www.seerpg.net"
}

public OnPluginStart()
{
		RegAdminCmd("sm_crit", crit, ADMFLAG_SLAY);
		
		CreateConVar("sm_crit_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	g_FullCrit[client] = false;
	return Plugin_Continue;
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
		if(g_FullCrit[client])
		{
			result = true;
			return Plugin_Handled;
		}

		return Plugin_Continue;
}

public Action:crit(client,args)
{	
	if (args != 0 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_crit");
		return Plugin_Handled;
	}
	
	if (args == 0 && IsPlayerAlive(client))
	{
		//Do low-level admin self target
		if (!g_FullCrit[client]) //Off
		{
			g_FullCrit[client] = true;
			LogAction(client, client, "\"%L\" enabled crit on himself", client);
			ReplyToCommand(client,"\x04[Crit]\x01 You enabled crit yourself!");
			return Plugin_Handled;
		}
		else if
		(g_FullCrit[client]) //On
		{
			g_FullCrit[client] = false;
			LogAction(client, client, "\"%L\" disabled crit on himself", client);
			ReplyToCommand(client,"\x04[Crit]\x01 You disabled crit yourself!");
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
			ReplyToCommand(client,"\x04[Crit]\x01 You enabled crit on %s!", target_name);
		}
		else
		{
			ReplyToCommand(client,"\x04[Crit]\x01 You disabled crit on %s!", target_name);
		}
		
		for (new i = 0; i < target_count; i ++)
		{
			if (iEnabled == 1) //Turn on
			{
				g_FullCrit[target_list[i]] = true;
				LogAction(client, target_list[i], "[Crit] \"%L\" enabled crit on \"%L\"", client, target_list[i]);
			}
			else //Turn Off
			{
				g_FullCrit[target_list[i]] = false;
				LogAction(client, target_list[i], "[Crit] \"%L\" disabled crit on \"%L\"", client, target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}