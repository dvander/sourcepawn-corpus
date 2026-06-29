#include <sourcemod>

public Plugin:myinfo =
{
	name = "Auto-Kick SteamPlayer",
	author = "rotab and Haikiri_kun",
	description = "This plugin will auto kick players with the nick SteamPlayer and say in Reason space Change your nick",
	version = "1.0.0.0",
	url = "forums.alliedmods.net"
}

public OnClientPostAdminCheck(client)
{
    decl String:name[64];
    GetClientName(client, name, sizeof(name));
    
    if (StrEqual(name, "SteamPlayer", false))
    {
        new String:reason[32] = "nick";
        new String:kickMessage[32] = "Fix your nick";
        BanClient(client, 1, BANFLAG_AUTHID, reason, kickMessage);
    }
}