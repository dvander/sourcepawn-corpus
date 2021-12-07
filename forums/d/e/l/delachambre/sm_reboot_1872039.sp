#include <sdktools>

public Plugin:myinfo =
{
    name = "sm_reboot",
    description = "Reboot with chat trigger",
    author = "Delachambre",
    version = "1.0.0",
    url = "http://forum.clan-magnetik.fr"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_reboot", Command_Reboot);
}

public Action:Command_Reboot(client, args)
{
	if (IsClientInGame(client))
	{
		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		{
			ServerCommand("exit");
		}
		else
		{
			PrintToChat(client, "[REBOOT] : Vous n'avez pas accès a cette commande \x03%N.", client);
		}
	}
}