#include <sourcemod>

public OnPluginStart()
{
    RegConsoleCmd("sm_health", HealthCommand);
}

public Action:HealthCommand(client, argc)
{
    new health;
    new String:buffer[16];
    
    if (client > 0)
    {
        if (argc > 0)
        {
            GetCmdArg(1, buffer, sizeof(buffer));
            health = StringToInt(buffer);
            SetEntityHealth(client, health);
        }
        else
        {
            health = GetClientHealth(client);
            ReplyToCommand(client, "Current health: %d", health);
        }
    }
    
    return Plugin_Handled;
}
