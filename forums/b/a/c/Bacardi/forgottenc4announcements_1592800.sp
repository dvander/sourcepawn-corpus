public Plugin:myinfo = {
	name = "[Cs:s & Cs:go] Forgotten C4 announcements",
	author = "Bacardi",
	description = "Revive game own chat announce bomb pickup/drop with game own translation phrases",
	version = "0.2",
}

#include <cstrike>

public OnPluginStart()
{
	HookEvent("bomb_dropped", bomb);
	HookEvent("bomb_pickup", bomb);
}

public bomb(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client) // Clientindex not 0 = Console
	{
		new numClients, clients[MaxClients];

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i)) // Chat message alive Terrorists, no bots
			{
				clients[numClients] = i; // Collect player indexs
				numClients++;
			}
		}

		if(numClients < 1) // No players
		{
			return;
		}

		new Handle:hBf;
		hBf = StartMessage("TextMsg", clients, numClients);

		if (hBf != INVALID_HANDLE)
		{
			new String:buffer[128];

			if(GetUserMessageType() == UM_Protobuf)
			{
				StrEqual(name, "bomb_pickup", false) ? Format(buffer, sizeof(buffer), "#Cstrike_TitlesTXT_Game_bomb_pickup"):Format(buffer, sizeof(buffer), "#Cstrike_TitlesTXT_Game_bomb_drop"); // Game own translations
				PbSetInt(hBf, "msg_dst", 3);
				PbAddString(hBf, "params", buffer);
				Format(buffer, MAX_NAME_LENGTH, "%N", client);
				PbAddString(hBf, "params", buffer);
				PbAddString(hBf, "params", "");
				PbAddString(hBf, "params", "");
				PbAddString(hBf, "params", "");
			}
			else
			{
				StrEqual(name, "bomb_pickup", false) ? Format(buffer, sizeof(buffer), "\x03#Game_bomb_pickup"):Format(buffer, sizeof(buffer), "\x03#Game_bomb_drop"); // Game own translations
				BfWriteString(hBf, buffer);
				Format(buffer, MAX_NAME_LENGTH, "%N", client); // Bomp carrier name
				BfWriteString(hBf, buffer);
			}
			EndMessage();
		}
	}
}