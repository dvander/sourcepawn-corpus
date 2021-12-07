#include <tf2attributes>

bool InGodeMode[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_god", Command_God, ADMFLAG_BAN, "Uber God");
	HookEvent("player_spawn", OnPlayerSpawn);
}

public void OnClientPutInServer(int client)
{
	InGodeMode[client] = false;
}

public Action Command_God(int client, int args)
{
	if (!client)
		return Plugin_Handled;

	if (args == 1)
	{
		char arg1[64]; GetCmdArg(1, arg1, 64);
		char clientName[32];
		int target_list[MAXPLAYERS];
		bool tn_is_ml;

		int target_count = ProcessTargetString(arg1, client, target_list, sizeof(target_list), COMMAND_FILTER_NO_IMMUNITY, clientName, sizeof(clientName), tn_is_ml);

		if (target_count != 1)
			ReplyToTargetError(client, target_count);

		for(int i = 0; i < target_count; i++) 
		{
			if(IsClientValid(target_list[i]))
			{
				InGodeMode[target_list[i]] ? RemoveGod(target_list[i]) : SetGod(target_list[i]);
				PrintToChat(client, InGodeMode[target_list[i]] ? "[SM] God status is enabled for %N" : "[SM] God status is disabled for %N", target_list[i]);
			}
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_god <#userid|name>");
	}

	return Plugin_Handled;
}

void SetGod(int client)
{
	InGodeMode[client] = true;
	TF2Attrib_SetByName(client, "uber on damage taken", 1.0);
}

void RemoveGod(int client)
{
	InGodeMode[client] = false;
	TF2Attrib_RemoveByName(client, "uber on damage taken");
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(InGodeMode[client])
	{
		TF2Attrib_SetByName(client, "uber on damage taken", 1.0);
	}

	return Plugin_Continue;
}

bool IsClientValid(int client){
	return client > 0 && client <= MaxClients;
}