#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
public Plugin:myinfo = 
{
    name = "Warn terrorists (jail)",
    author = "wyd3x",
    description = "show messages on center",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=197680"
}

public OnMapStart()
{
	RegConsoleCmd("sm_warn", Command_warn);
}

public Action:Command_warn(client, args)
{
	if (GetClientTeam(client) == 3)
	{
		new player = GetClientAimTarget(client, false);
		if (GetClientTeam(player) == 2)
			PrintHintText(GetClientUserId(player), "Drop Your Weapons Or Die");
	}
	return Plugin_Handled;
}
