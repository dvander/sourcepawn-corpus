#include <sourcemod>

public OnPluginStart()
{
	RegAdminCmd("sm_getchoke", Command_getchoke, ADMFLAG_KICK);
}

public Action:Command_getchoke(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		ReplyToCommand(client, "#%i %N - %f", GetClientUserId(i), i, GetClientAvgChoke(i, NetFlow_Both));
	}
	return Plugin_Handled;
}