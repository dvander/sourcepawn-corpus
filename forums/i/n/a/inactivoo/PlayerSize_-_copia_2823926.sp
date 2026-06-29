#include <sourcemod>
#include <sdktools>

const char ADMIN_FLAG = ADMFLAG_RESERVATION; // Flag "a" for reserved slots

public Plugin myinfo = {
    name = "PlayerSize",
    author = "inactivo",
    description = "Permite a los administradores cambiar el tamaño de su personaje",
    version = "1.0",
    url = "https://example.com"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_playersize", Command_PlayerSize, ADMIN_FLAG, "Cambia el tamaño de tu personaje: pequeño, normal, grande");
}

public Action Command_PlayerSize(int client, int args)
{
    if (args < 1)
    {
        PrintToChat(client, "\x04Uso: sm_playersize <pequeño|normal|grande>");
        return Plugin_Handled;
    }

    char arg[16];
    GetCmdArg(1, arg, sizeof(arg));

    int scale = 100; // Default scale
    if (StrEqual(arg, "pequeño", false))
    {
        scale = 75;
    }
    else if (StrEqual(arg, "normal", false))
    {
        scale = 100;
    }
    else if (StrEqual(arg, "grande", false))
    {
        scale = 125;
    }
    else
    {
        PrintToChat(client, "\x04Opción no válida. Usa: pequeño, normal o grande.");
        return Plugin_Handled;
    }

    SetPlayerScale(client, scale);
    PrintToChat(client, "\x04Tu tamaño ha sido cambiado a %s (%d%%).", arg, scale);
    return Plugin_Handled;
}

void SetPlayerScale(int client, int scale)
{
    char command[64];
    Format(command, sizeof(command), "mp_player_model_scale %d %d", GetClientUserId(client), scale);
    ServerCommand(command);
}
