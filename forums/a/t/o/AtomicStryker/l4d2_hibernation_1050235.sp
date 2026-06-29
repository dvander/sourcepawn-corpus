#include <sourcemod>

public OnClientDisconnect(client)
{
    CreateTimer(1.5, CheckServer);
}

public Action:CheckServer(Handle:timer)
{
    if (!HumansConnected())
    {
        ResetConVar(FindConVar("sb_all_bot_team"), true, true);
        KickAll();
        SetConVarInt(FindConVar("sb_all_bot_team"), 1);
		decl String:map[64]
		GetCurrentMap(map, sizeof(map))
		ForceChangeLevel(map, "Unspawned Equipment Bug.")
    }
}

stock bool:HumansConnected()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && !IsFakeClient(i))
        {
            return true;
        }
    }
    return false;
}

stock KickAll()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
        {
            KickClientEx(i);
        }
    }
}