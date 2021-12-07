#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.5.3"

//new Handle:v_PowerTime = INVALID_HANDLE;
new bool:g_PoweredUp[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo = 
{
    name = "[TF2] PowerPlay",
    author = "DarthNinja",
    description = "The Robin Walker Uber!",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
}

public OnPluginStart()
{
		RegAdminCmd("sm_powerup", PowerPlay, ADMFLAG_SLAY);
		RegAdminCmd("sm_powerplay", PowerPlay, ADMFLAG_SLAY);
		RegAdminCmd("sm_pp", PowerPlay, ADMFLAG_SLAY);
		
		CreateConVar("sm_powerplay_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		HookEvent("player_spawn", Event_PlayerSpawn);
		LoadTranslations("common.phrases");
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	g_PoweredUp[client] = false;
	return Plugin_Continue;
}


public Action:PowerPlay(client,args)
{	
	if (args != 0 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_powerup");
		return Plugin_Handled;
	}
	
	if (args == 0 && IsPlayerAlive(client))
	{
		//Do low-level admin self target
		if (!g_PoweredUp[client]) //Off
		{
			TF2_SetPlayerPowerPlay(client, true);
			g_PoweredUp[client] = true;
			LogAction(client, client, "\"%L\" enabled PowerPlay on himself", client);
			ReplyToCommand(client,"\x04[PowerPlay]\x01 You enabled PowerPlay yourself!");
			return Plugin_Handled;
		}
		else if
		(g_PoweredUp[client]) //On
		{
			TF2_SetPlayerPowerPlay(client, false);
			g_PoweredUp[client] = false;
			LogAction(client, client, "\"%L\" disabled PowerPlay on himself", client);
			ReplyToCommand(client,"\x04[PowerPlay]\x01 You disabled PowerPlay yourself!");
			return Plugin_Handled;
		}
		return Plugin_Handled;
	}
	
	else if (args == 2)
	{
		if (!CheckCommandAccess(client, "sm_powerplay_override", ADMFLAG_BAN))
		{
			ReplyToCommand(client, "Usage: sm_powerup");
			return Plugin_Handled;
		}
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
			ReplyToCommand(client,"\x04[PowerPlay]\x01 You enabled PowerPlay on %s!", target_name);
		}
		else
		{
			ReplyToCommand(client,"\x04[PowerPlay]\x01 You disabled PowerPlay on %s!", target_name);
		}
		
		for (new i = 0; i < target_count; i ++)
		{
			if (iEnabled == 1) //Turn on
			{
				TF2_SetPlayerPowerPlay(target_list[i], true);
				g_PoweredUp[target_list[i]] = true;
				LogAction(client, target_list[i], "[PowerPlay] \"%L\" enabled PowerPlay on \"%L\"", client, target_list[i]);
			}
			else //Turn Off
			{
				TF2_SetPlayerPowerPlay(target_list[i], false);
				g_PoweredUp[target_list[i]] = false;
				LogAction(client, target_list[i], "[PowerPlay] \"%L\" disabled PowerPlay on \"%L\"", client, target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}