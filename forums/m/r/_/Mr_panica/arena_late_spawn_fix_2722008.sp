
#include <tf2_stocks>

public Plugin myinfo =
{
	name = "TF2: Anti-Arena Latespawn (v from Mr_panica)",
	description = "Stops players from spawning during in Arena mode | Предотвращает респавн игроков на режиме арены",
	author = "Mr_panica (code borrowed from [TF2] Ghost Mode)",
	version = "1.0"
}

public void OnPluginStart()
{
    AddCommandListener(ChangeClass, "joinclass");
}


public Action ChangeClass(int client, const char[] command, int argc)
{
    if(IsClientInGame(client) && !IsPlayerAlive(client))
    {

        char arg1[24];
	GetCmdArg(1, arg1, sizeof(arg1));
        TFClassType class = TF2_GetClass(arg1);

        if (class != TFClass_Unknown)
            TF2_SetPlayerDesiredClass(client, class)
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

stock TF2_SetPlayerDesiredClass(int client, TFClassType class)
{
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);
}
