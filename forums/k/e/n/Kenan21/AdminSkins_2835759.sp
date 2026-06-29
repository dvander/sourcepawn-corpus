#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "Admin Skins",
    author = "Programmiert von FeritGang",
    description = "Admin Skins Sourcemod (Ersatz wie bei Mani Admin Plugin)",
    version = "2.0",
    url = "http://http://5.189.131.115/"
}

public Handle:g_hAdminFlag;

public void OnPluginStart()
{
    g_hAdminFlag = CreateConVar("admin_skins_flag", "z", "Flag für Admin-Skins");
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    // Modelle für beide Teams vorladen
    PrecacheModelsForTeams("addons/sourcemod/configs/AdminSkins/AdminSkins_T.cfg"); // Terroristen
    PrecacheModelsForTeams("addons/sourcemod/configs/AdminSkins/AdminSkins_CT.cfg"); // Anti-Terroristen
}

void PrecacheModelsForTeams(const char[] configFile)
{
    Handle file = OpenFile(configFile, "r");
    if (file == null)
    {
        PrintToServer("WARNUNG: Konnte Konfigurationsdatei %s nicht öffnen!", configFile);
        return;
    }

    char line[PLATFORM_MAX_PATH];
    while (ReadFileLine(file, line, sizeof(line)))
    {
        TrimString(line);
        if (line[0] == '\0' || line[0] == '/' || StrContains(line, ".mdl") == -1) continue;

        if (FileExists(line, true))
        {
            PrecacheModel(line, true);
            AddFileToDownloadsTable(line);
            LoadMaterialsForModel(line);
        }
    }

    CloseHandle(file);
}

void LoadMaterialsForModel(const char[] modelPath)
{
    char materialBase[PLATFORM_MAX_PATH];
    strcopy(materialBase, sizeof(materialBase), modelPath);

    if (strncmp(materialBase, "materials/", 9) == 0)
    {
        return;
    }

    ReplaceString(materialBase, sizeof(materialBase), "models/player", "materials/models/player");

    int dotIndex = -1;
    for (int i = strlen(materialBase) - 1; i >= 0; i--)
    {
        if (materialBase[i] == '.')
        {
            dotIndex = i;
            break;
        }
    }

    if (dotIndex != -1)
    {
        materialBase[dotIndex] = '\0';
    }

    char vmtPath[PLATFORM_MAX_PATH];
    char vtfPath[PLATFORM_MAX_PATH];
    Format(vmtPath, sizeof(vmtPath), "%s.vmt", materialBase);
    Format(vtfPath, sizeof(vtfPath), "%s.vtf", materialBase);

    if (FileExists(vmtPath, true))
    {
        AddFileToDownloadsTable(vmtPath);
    }

    if (FileExists(vtfPath, true))
    {
        AddFileToDownloadsTable(vtfPath);
    }
}

public Action:Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsClientInGame(client) && IsPlayerAdmin(client))
    {
        char modelPath[PLATFORM_MAX_PATH];
        GetAdminSkinForClient(client, modelPath, sizeof(modelPath));
        ApplyModel(client, modelPath);
    }
    return Plugin_Continue;
}

void GetAdminSkinForClient(int client, char[] modelPath, int maxlen)
{
    int team = GetClientTeam(client);

    char configFile[PLATFORM_MAX_PATH];
    if (team == 2) // Terroristen-Team
    {
        Format(configFile, sizeof(configFile), "addons/sourcemod/configs/AdminSkins/AdminSkins_T.cfg");
    }
    else if (team == 3) // Anti-Terroristen-Team
    {
        Format(configFile, sizeof(configFile), "addons/sourcemod/configs/AdminSkins/AdminSkins_CT.cfg");
    }
    else
    {
        modelPath[0] = '\0';
        return;
    }

    char currentModel[PLATFORM_MAX_PATH];
    GetClientModel(client, currentModel, sizeof(currentModel));

    Handle file = OpenFile(configFile, "r");
    if (file == null)
    {
        modelPath[0] = '\0';
        return;
    }

    char line[PLATFORM_MAX_PATH];
    while (ReadFileLine(file, line, sizeof(line)))
    {
        TrimString(line);

        if (line[0] == '\0' || line[0] == '/' || StrContains(line, ".mdl") == -1) continue;

        // Prüfe auf aktuelles Modell des Spielers für T-Teams
        if (team == 2) // Terroristen
        {
            if (StrContains(currentModel, "leet") != -1 && StrContains(line, "t_leet_admin") != -1)
            {
                strcopy(modelPath, maxlen, line);
                CloseHandle(file);
                return;
            }
            if (StrContains(currentModel, "arctic") != -1 && StrContains(line, "t_arctic_admin") != -1)
            {
                strcopy(modelPath, maxlen, line);
                CloseHandle(file);
                return;
            }
            if (StrContains(currentModel, "guerilla") != -1 && StrContains(line, "t_guerilla_admin") != -1)
            {
                strcopy(modelPath, maxlen, line);
                CloseHandle(file);
                return;
            }
            if (StrContains(currentModel, "phoenix") != -1 && StrContains(line, "admin_t_fixed") != -1)
            {
                strcopy(modelPath, maxlen, line);
                CloseHandle(file);
                return;
            }
        }

        // Prüfe auf aktuelles Modell des Spielers für CT-Teams
        else if (team == 3) // Anti-Terroristen
        {
            if (StrContains(currentModel, "urban") != -1 && StrContains(line, "admin_ct_fixed") != -1)
            {
                strcopy(modelPath, maxlen, line);
                CloseHandle(file);
                return;
            }
            if (StrContains(currentModel, "gign") != -1 && StrContains(line, "ct_gign_admin") != -1)
            {
                strcopy(modelPath, maxlen, line);
                CloseHandle(file);
                return;
            }
            if (StrContains(currentModel, "gsg9") != -1 && StrContains(line, "ct_gsg9_admin") != -1)
            {
                strcopy(modelPath, maxlen, line);
                CloseHandle(file);
                return;
            }
            if (StrContains(currentModel, "sas") != -1 && StrContains(line, "ct_sas_admin") != -1)
            {
                strcopy(modelPath, maxlen, line);
                CloseHandle(file);
                return;
            }
        }
    }

    // Kein passendes Modell gefunden
    modelPath[0] = '\0'; // Kein Modell verwenden
    CloseHandle(file);   // Datei schließen
    return;              // Funktion beenden
}

bool:IsPlayerAdmin(int client)
{
    return GetUserAdmin(client) != INVALID_ADMIN_ID; // Überprüft, ob der Spieler Adminrechte hat
}

void ApplyModel(int client, const char[] modelPath)
{
    if (IsValidClient(client) && modelPath[0] != '\0') // Überprüft, ob ein gültiger Client vorhanden ist und ein Modellpfad angegeben wurde
    {
        SetEntityModel(client, modelPath); // Setzt das Modell für den Spieler
    }
}

bool:IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client); // Überprüft, ob der Client im Spiel ist und gültig ist
}