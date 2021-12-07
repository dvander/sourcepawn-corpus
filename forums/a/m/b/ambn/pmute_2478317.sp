#include <sourcemod>
#include <basecomm>

new bool:IsClientMuted[MAXPLAYERS + 1] = false;
public void OnPluginStart()
{
	RegAdminCmd("sm_pmute", Command_pmute, ADMFLAG_ROOT);
}
public Action Command_pmute(int client, int args)
{
	if(args < 1)
	{
		return Plugin_Handled;
	}
	char PlayerName[MAX_NAME_LENGTH], Player[32];
	GetCmdArg(1, Player, sizeof(Player));
	int target = FindTarget(client, Player);
	if(target == -1)
	{
		PrintToChat(client, "[SM] Player not found.");
		return Plugin_Handled;
	}
	GetClientName(target, PlayerName, sizeof(PlayerName));
	BaseComm_SetClientMute(client, true)
	PrintToChatAll("[SM] Player %s Has Been Muted!", PlayerName);
	IsClientMuted[client] = true;
	return Plugin_Handled;
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