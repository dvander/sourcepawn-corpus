#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

new bool:ga_bSlayed[MAXPLAYERS + 1] = {false, ...};

public Plugin:myinfo =
{
	name = "Repeat Slay Blocker",
	author = "That One Guy",
	description = "Blocks slaying client more than once per map (assuming no reconnecting)",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=188078"
}

public OnPluginStart()
{
	AddCommandListener(Command_Slay, "sm_slay");
}

public OnClientConnected(client)
{
	ga_bSlayed[client] = false;
}

public Action:Command_Slay(client, const String:sCommand[], iArgs) 
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	if(!iArgs)
	{
		return Plugin_Continue;
	}
	
	decl String:sTarget[65], String:sTargetName[MAX_TARGET_LENGTH];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	new a_iTargets[MAXPLAYERS], iTargetCount, bool:bTN_ML;
	if((iTargetCount = ProcessTargetString(sTarget, client, a_iTargets, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bTN_ML)) <= 0)
	{
		ReplyToCommand(client, "Target not found or invalid parameter.");
		return Plugin_Handled;
	}
	
	for(new i = 0; i < iTargetCount; i++)
	{
		new target = a_iTargets[i];
		if(IsValidClient(target, true))
		{
			if(!ga_bSlayed[target])
			{
				ga_bSlayed[target] = true;
				ForcePlayerSuicide(target);
			}
			else
			{
				ReplyToCommand(client, "%N has already been slayed once this map!", target);
			}
		}
	}
	
	return Plugin_Handled;
}

bool:IsValidClient(client, bool:bAllowBots = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	return true;
}