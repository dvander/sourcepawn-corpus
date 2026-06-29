#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sourcescramble>

#define GAMEDATA "l4d2.botpatch"

static const char g_sPatchNames[][] =
{
    "CTerrorPlayer::CommandABot_FF::BypassFF"
};

public Plugin myinfo =
{
    name = "CommandABot Friendly Fire Patch",
    author = "Malibu",
    description = "Remove o filtro de fogo amigo do CommandABot via MemoryPatch.",
    version = "1.0"
};

public void OnPluginStart()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);

    if (!FileExists(sPath))
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

    GameData hGameData = new GameData(GAMEDATA);
    if (!hGameData)
        SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

    MemoryPatch patch;
    for (int i = 0; i < sizeof g_sPatchNames; i++)
    {
        patch = MemoryPatch.CreateFromConf(hGameData, g_sPatchNames[i]);
        if (!patch.Validate())
            LogError("Falha ao verificar patch: \"%s\"", g_sPatchNames[i]);
        else if (patch.Enable())
            PrintToServer("Patch habilitado: \"%s\"", g_sPatchNames[i]);
    }

    delete hGameData;
}
