#pragma semicolon 1

#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"


public Plugin:myinfo = 
{
	name = "Bot Ignore",
	author = "Tylerst",
	
	description = "Bots will ignore selected player(s)",
	
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2087931"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}



new bool:g_BotIgnore[MAXPLAYERS+1] = false;

public OnPluginStart()
{
	CreateConVar("sm_botignore_version", PLUGIN_VERSION, "Bot Ignore", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_botignore", Command_BotIgnore, ADMFLAG_GENERIC, "Set bot ignore on selected player Usage: sm_botignore \"target\" \"1/0\"");

	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnClientPutInServer(client)
{
	g_BotIgnore[client] = false;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_BotIgnore[client])	SetBotIgnore(client, true);
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if((condition == TFCond_StealthedUserBuffFade) && g_BotIgnore[client]) SetBotIgnore(client, true);
}

public Action:Command_BotIgnore(client, args)
{
	switch(args)
	{
		case 0:
		{
			if(client < 1 || client > MaxClients) return Plugin_Handled;
			ToggleBotIgnore(client);

		}
		case 2:
		{
			new String:strTarget[MAX_TARGET_LENGTH], String:strOnOff[2], bool:bOnOff, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
			GetCmdArg(1, strTarget, sizeof(strTarget));
			if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			GetCmdArg(2, strOnOff, sizeof(strOnOff));
			bOnOff = bool:StringToInt(strOnOff);


			if(bOnOff)
			{
				for(new i = 0; i < target_count; i++)
				{
					SetBotIgnore(target_list[i], true);
				}
				ShowActivity2(client, "[SM] ","Bots are now ignoring %s", target_name);
			}
			else
			{
				for(new i = 0; i < target_count; i++)
				{
					SetBotIgnore(target_list[i], false);
				}
				ShowActivity2(client, "[SM] ","Bots will not ignore %s", target_name);
			}
		
		}
		default:
		{
			ReplyToCommand(client, "[SM] Usage: sm_botignore \"target\" \"1/0\"");
		}
	}

	return Plugin_Handled;
}

ToggleBotIgnore(client)
{
	if(TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade)) SetBotIgnore(client, false);
	else SetBotIgnore(client, true);
}

SetBotIgnore(client, bool:bIgnore)
{
	if(bIgnore)
	{
		TF2_AddCondition(client, TFCond_StealthedUserBuffFade, -1.0);
		g_BotIgnore[client] = true;

	}
	else
	{
		TF2_RemoveCondition(client, TFCond_StealthedUserBuffFade);
		g_BotIgnore[client] = false;
	}
}


