#include <sourcemod>
#include <basecomm>

new bool:IsClientMuted[MAXPLAYERS + 1] = false;
public void OnPluginStart()
{
	RegAdminCmd("sm_pmute", Command_pmute, ADMFLAG_ROOT);
}
public Action Command_pmute(int client, int args)
{
	if(args < 2)
	{
		return Plugin_Handled;
	}
	char PlayerName[MAX_NAME_LENGTH], Player[32], time[8];
	GetCmdArg(1, Player, sizeof(Player));
	GetCmdArg(2, time, sizeof(time));
	int target = FindTarget(client, Player);
	if(target == -1)
	{
		PrintToChat(client, "[SM] Player not found.");
		return Plugin_Handled;
	}
	GetClientName(target, PlayerName, sizeof(PlayerName));
	BaseComm_SetClientMute(client, true)
	PrintToChatAll("[SM] Player %s Has Been Muted!", PlayerName);
	CreateTimer(StringToFloat(time), Time_UnMute, client);
	IsClientMuted[client] = true;
	return Plugin_Handled;
}
public Action Time_UnMute(Handle timer, any:client)
{
	if(IsClientMuted[client] == true && IsClientInGame(client))
	{
		BaseComm_SetClientMute(client, false);
		IsClientMuted[client] = false;
		PrintToChat(client, "[SM] You are no longer muted!");
	}
}
public OnClientPutInServer(int client)
{
	if(IsClientMuted[client] == true)
	{
		BaseComm_SetClientMute(client, true);
	}
}
public void OnMapStart()
{
	for(new i=1;i <= MaxClients;i++)
	{
		IsClientMuted[i] = false;
	}
}