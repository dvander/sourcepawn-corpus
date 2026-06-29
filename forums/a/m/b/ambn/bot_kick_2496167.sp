#include <sourcemod>
#define Plugin_Version "1.0"
public Plugin:myinfo = {
	name = "bot_kick",
	author = "noBrain",
	description = "bot_kick",
	version = Plugin_Version,
};
public void OnClientPutInServer(int client)
{
	if(IsClientInGame(client) && IsFakeClient(client))
	{
		ServerCommand("bot_kick");
		PrintToChatAll("[SM] Bots Has Been Kicked From The Server!");
	}
}