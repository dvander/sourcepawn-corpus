#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

new bool:isGray[MAXPLAYERS+1] = false;
new lastTeam[MAXPLAYERS+1] = 0;

#define PLUGIN_VERSION "0.2"

public Plugin:myinfo =
{
    name = "Gray Team",
    author = "Dachtone",
    description = "Changes player's team to gray",
    version = PLUGIN_VERSION,
    url = "http://sourcegames.ru/"
}

public OnPluginStart()
{
	CreateConVar("gray_version", PLUGIN_VERSION, "Gray Team Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_gray", AdmGray, ADMFLAG_ROOT, "Change player's team to gray");
	
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	
	HookEvent("arena_round_start", RoundStart);
	HookEvent("teamplay_round_start", PreRoundStart);
	
	LoadTranslations("common.phrases");
}

public OnClientPostAdminCheck(client)
{
	isGray[client] = false;
}

public OnClientDisconnect(client)
{
	isGray[client] = false;
}

public Action:PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (IsValidClient(client) && isGray[client])
	{
		ChangeClientTeam(client, lastTeam[client]);
		isGray[client] = false;
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	isGray[client] = false;
}

public PreRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= 32; i++)
	{
		if (IsValidClient(i) && isGray[i])
		{
			ChangeClientTeam(i, lastTeam[i]);
			TF2_RespawnPlayer(i);
			isGray[i] = false;
		}
	}
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= 32; i++)
	{
		if (IsValidClient(i) && isGray[i])
		{
			ChangeClientTeam(i, lastTeam[i]);
			TF2_RespawnPlayer(i);
			isGray[i] = false;
		}
	}
}

public Action:AdmGray(client, args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	new target;
	if (args < 1)
	{
		target = client;
	}
	else
	{
		new String:arg[32];
		GetCmdArg(1, arg, sizeof(arg));
		target = FindTarget(client, arg);
		if (target == -1)
			return Plugin_Handled;
	}
	if (IsValidClient(target))
	{
		if (!isGray[target])
		{
			if (IsPlayerAlive(target))
			{
				lastTeam[target] = GetClientTeam(target);
				new Float:origin[3], Float:angles[3];
				GetClientAbsOrigin(target, origin);
				GetClientAbsAngles(target, angles);
				ChangeClientTeam(target, 0);
				TF2_RespawnPlayer(target);
				TeleportEntity(target, origin, angles, NULL_VECTOR);
				isGray[target] = true;
				
				PrintToChat(client, "[SM] %N is in the Gray team now", target);
			}
			else
			{
				ReplyToCommand(client, "[SM] Player must be alive");
			}
		}
		else
		{
			if (IsPlayerAlive(target))
			{
				new Float:origin[3], Float:angles[3];
				GetClientAbsOrigin(target, origin);
				GetClientAbsAngles(target, angles);
				ChangeClientTeam(target, lastTeam[target]);
				TF2_RespawnPlayer(target);
				TeleportEntity(target, origin, angles, NULL_VECTOR);
				isGray[target] = false;
			}
			else
			{
				ChangeClientTeam(target, lastTeam[target]);
				isGray[target] = false;
			}
			PrintToChat(client, "[SM] %N is no longer in the Gray team", target);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Player must be available");
	}
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientConnected(client) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}