#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "Admin Skins",
    author = "Programmiert von FeritGang",
    description = "Admin Skins Sourcemod (Ersatz wie bei Mani Admin Plugin)",
    version = "1.0",
    url = "http://http://5.189.131.115/"
}

public Handle:g_hAdminFlag;

public void OnPluginStart()
{
    g_hAdminFlag = CreateConVar("admin_skins_flag", "z", "Flag für Admin-Skins");
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    PrecacheModels();
}

public void PrecacheModels()
{
    PrecacheModel("models/player/ics/t_leet_admin/t_leet.mdl", true);
    PrecacheModel("models/player/ics/admin_ct_fixed/urban.mdl", true);
    PrecacheModel("models/player/ics/t_arctic_admin/t_arctic.mdl", true);
    PrecacheModel("models/player/ics/t_guerilla_admin/t_guerilla.mdl", true);
    PrecacheModel("models/player/ics/admin_t_fixed/terror.mdl", true);
    PrecacheModel("models/player/ics/ct_gign_admin/ct_gign.mdl", true);
    PrecacheModel("models/player/ics/ct_gsg9_admin/ct_gsg9.mdl", true);
    PrecacheModel("models/player/ics/ct_sas_admin/ct_sas.mdl", true);
    PrintToServer("Modelle erfolgreich vorgeladen.");
}

// Materialien zur Downloadliste hinzufügen
public void OnClientConnected(int client)
{
    // Hinzufügen von Modelldateien zur Downloadliste
    AddFileToDownloadsTable("models/player/ics/t_leet_admin/t_leet.mdl");
    AddFileToDownloadsTable("models/player/ics/t_leet_admin/t_leet.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/t_leet_admin/t_leet.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/t_leet_admin/t_leet.phy");
    AddFileToDownloadsTable("models/player/ics/t_leet_admin/t_leet.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/t_leet_admin/t_leet.vvd");
    
    AddFileToDownloadsTable("models/player/ics/t_guerilla_admin/t_guerilla.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/t_guerilla_admin/t_guerilla.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/t_guerilla_admin/t_guerilla.mdl");
    AddFileToDownloadsTable("models/player/ics/t_guerilla_admin/t_guerilla.phy");
    AddFileToDownloadsTable("models/player/ics/t_guerilla_admin/t_guerilla.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/t_guerilla_admin/t_guerilla.vvd");
    
    AddFileToDownloadsTable("models/player/ics/t_arctic_admin/t_arctic.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/t_arctic_admin/t_arctic.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/t_arctic_admin/t_arctic.mdl");
    AddFileToDownloadsTable("models/player/ics/t_arctic_admin/t_arctic.phy");
    AddFileToDownloadsTable("models/player/ics/t_arctic_admin/t_arctic.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/t_arctic_admin/t_arctic.vvd");
    
    AddFileToDownloadsTable("models/player/ics/admin_t_fixed/terror.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/admin_t_fixed/terror.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/admin_t_fixed/terror.mdl");
    AddFileToDownloadsTable("models/player/ics/admin_t_fixed/terror.phy");
    AddFileToDownloadsTable("models/player/ics/admin_t_fixed/terror.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/admin_t_fixed/terror.vvd");

    // Beispiel für das Hinzufügen weiterer Modelldateien
    AddFileToDownloadsTable("models/player/ics/admin_ct_fixed/urban.mdl");
    AddFileToDownloadsTable("models/player/ics/admin_ct_fixed/urban.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/admin_ct_fixed/urban.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/admin_ct_fixed/urban.phy");
    AddFileToDownloadsTable("models/player/ics/admin_ct_fixed/urban.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/admin_ct_fixed/urban.vvd");
    
    AddFileToDownloadsTable("models/player/ics/ct_gign_admin/ct_gign.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_gign_admin/ct_gign.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_gign_admin/ct_gign.mdl");
    AddFileToDownloadsTable("models/player/ics/ct_gign_admin/ct_gign.phy");
    AddFileToDownloadsTable("models/player/ics/ct_gign_admin/ct_gign.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_gign_admin/ct_gign.vvd");
    
    AddFileToDownloadsTable("models/player/ics/ct_gsg9_admin/ct_gsg9.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_gsg9_admin/ct_gsg9.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_gsg9_admin/ct_gsg9.mdl");
    AddFileToDownloadsTable("models/player/ics/ct_gsg9_admin/ct_gsg9.phy");
    AddFileToDownloadsTable("models/player/ics/ct_gsg9_admin/ct_gsg9.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_gsg9_admin/ct_gsg9.vvd");
    
    AddFileToDownloadsTable("models/player/ics/ct_sas_admin/ct_sas.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_sas_admin/ct_sas.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_sas_admin/ct_sas.mdl");
    AddFileToDownloadsTable("models/player/ics/ct_sas_admin/ct_sas.phy");
    AddFileToDownloadsTable("models/player/ics/ct_sas_admin/ct_sas.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/ct_sas_admin/ct_sas.vvd");

    // Hinzufügen von Materialdateien zur Downloadliste
    AddFileToDownloadsTable("materials/models/player/ics/admin_ct_fixed/ct_urban.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/admin_ct_fixed/ct_urban.vtf");

    // Beispiel für das Hinzufügen weiterer Materialdateien
    AddFileToDownloadsTable("materials/models/player/ics/ct_gign_admin/ct_gign.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/ct_gign_admin/ct_gign.vtf");
    AddFileToDownloadsTable("materials/models/player/ics/ct_gign_admin/ct_gign_glass.vmt");

    AddFileToDownloadsTable("materials/models/player/ics/ct_gsg9_admin/ct_gsg9.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/ct_gsg9_admin/ct_gsg9.vtf");

    AddFileToDownloadsTable("materials/models/player/ics/ct_sas_admin/ct_sas.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/ct_sas_admin/ct_sas.vtf");
    AddFileToDownloadsTable("materials/models/player/ics/ct_sas_admin/ct_sas_glass.vmt");

    AddFileToDownloadsTable("materials/models/player/ics/admin_t_fixed/t_phoenix.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/admin_t_fixed/t_phoenix.vtf");

    AddFileToDownloadsTable("materials/models/player/ics/t_arctic_admin/t_arctic.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/t_arctic_admin/t_arctic.vtf");

    AddFileToDownloadsTable("materials/models/player/ics/t_guerilla_admin/t_guerilla.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/t_guerilla_admin/t_guerilla.vtf");

    AddFileToDownloadsTable("materials/models/player/ics/t_leet_admin/t_leet.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/t_leet_admin/t_leet.vtf");
    AddFileToDownloadsTable("materials/models/player/ics/t_leet_admin/t_leet_glass.vmt");
}

public Action:Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsClientInGame(client) && IsPlayerAdmin(client))
    {
        PrintToServer("Admin erkannt: %N", client);
        PrecacheModel("models/player/ics/t_leet_admin/t_leet.mdl", true); // Zwischenspeichern des Modells
		PrecacheModel("models/player/ics/admin_t_fixed/terror.mdl", true); // Zwischenspeichern des Modells
		PrecacheModel("models/player/ics/t_arctic_admin/t_arctic.mdl", true); // Zwischenspeichern des Modells
		PrecacheModel("models/player/ics/t_guerilla_admin/t_guerilla.mdl", true); // Zwischenspeichern des Modells		
		PrecacheModel("models/player/ics/ct_sas_admin/ct_sas.mdl", true); // Zwischenspeichern des Modells
		PrecacheModel("models/player/ics/ct_gsg9_admin/ct_gsg9.mdl", true); // Zwischenspeichern des Modells
		PrecacheModel("models/player/ics/ct_gign_admin/ct_gign.mdl", true); // Zwischenspeichern des Modells
		PrecacheModel("models/player/ics/admin_ct_fixed/urban.mdl", true); // Zwischenspeichern des Modells
        SetAdminSkin(client);
    }   
    return Plugin_Continue;
}

bool:IsPlayerAdmin(int client)
{
    bool isAdmin = GetUserAdmin(client) != INVALID_ADMIN_ID;
    return isAdmin;
}

void SetAdminSkin(int client)
{
    char modelPath[PLATFORM_MAX_PATH];

    int team = GetClientTeam(client);

    // Überprüfe die aktuellen Modelle des Clients
    char currentModel[PLATFORM_MAX_PATH];
    GetClientModel(client, currentModel, sizeof(currentModel));

    // Terroristen-Teams
    if (team == 2) 
    {
        if (StrContains(currentModel, "leet") != -1)
        {
            Format(modelPath, sizeof(modelPath), "models/player/ics/t_leet_admin/t_leet.mdl");
        }
        else if (StrContains(currentModel, "arctic") != -1)
        {
            Format(modelPath, sizeof(modelPath), "models/player/ics/t_arctic_admin/t_arctic.mdl");
        }
        else if (StrContains(currentModel, "guerilla") != -1)
        {
            Format(modelPath, sizeof(modelPath), "models/player/ics/t_guerilla_admin/t_guerilla.mdl");
        }
        else if (StrContains(currentModel, "t_phoenix") != -1)
        {
            Format(modelPath, sizeof(modelPath), "models/player/ics/admin_t_fixed/terror.mdl");
        }
    }
    // Anti-Terror-Teams
    else if (team == 3) 
    {
        if (StrContains(currentModel, "urban") != -1)
        {
            Format(modelPath, sizeof(modelPath), "models/player/ics/admin_ct_fixed/urban.mdl");
        }
        else if (StrContains(currentModel, "gign") != -1)
        {
            Format(modelPath, sizeof(modelPath), "models/player/ics/ct_gign_admin/ct_gign.mdl");
        }
        else if (StrContains(currentModel, "gsg9") != -1)
        {
            Format(modelPath, sizeof(modelPath), "models/player/ics/ct_gsg9_admin/ct_gsg9.mdl");
        }
        else if (StrContains(currentModel, "sas") != -1)
        {
            Format(modelPath, sizeof(modelPath), "models/player/ics/ct_sas_admin/ct_sas.mdl");
        }
    }
    
    ApplyModel(client, modelPath);
    ApplyMaterials(modelPath);
    PrintToServer("Modell und Materialien gesetzt für Spieler: %N", client);
}

void ApplyModel(int client, const char[] modelPath)
{
    if (IsValidClient(client) && IsValidModel(modelPath))
    {
        SetEntityModel(client, modelPath);
    }
    else
    {
        PrintToServer("Fehler beim Zuweisen des Modells für Spieler: %N", client);
    }
}

bool:IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool:IsValidModel(const char[] model)
{
    return model[0] != '\0'; // Überprüfen, ob der Modellpfad nicht leer ist
}

void ApplyMaterials(const char[] modelPath)
{
    char materialPath[PLATFORM_MAX_PATH];

    if (StrContains(modelPath, "admin_ct_fixed") != -1)
    {
        Format(materialPath, sizeof(materialPath), "materials/models/player/ics/admin_ct_fixed/ct_urban.vmt");
        AddFileToDownloadsTable("materials/models/player/ics/admin_ct_fixed/ct_urban.vtf");
    }
    else if (StrContains(modelPath, "ct_gign_admin") != -1)
    {
        Format(materialPath, sizeof(materialPath), "materials/models/player/ics/ct_gign_admin/ct_gign.vmt");
        AddFileToDownloadsTable("materials/models/player/ics/ct_gign_admin/ct_gign.vtf");
        AddFileToDownloadsTable("materials/models/player/ics/ct_gign_admin/ct_gign_glass.vmt");
    }
    else if (StrContains(modelPath, "ct_gsg9_admin") != -1)
    {
        Format(materialPath, sizeof(materialPath), "materials/models/player/ics/ct_gsg9_admin/ct_gsg9.vmt");
        AddFileToDownloadsTable("materials/models/player/ics/ct_gsg9_admin/ct_gsg9.vtf");
    }
    else if (StrContains(modelPath, "ct_sas_admin") != -1)
    {
        Format(materialPath, sizeof(materialPath), "materials/models/player/ics/ct_sas_admin/ct_sas.vmt");
        AddFileToDownloadsTable("materials/models/player/ics/ct_sas_admin/ct_sas.vtf");
        AddFileToDownloadsTable("materials/models/player/ics/ct_sas_admin/ct_sas_glass.vmt");
    }
    else if (StrContains(modelPath, "admin_t_fixed") != -1)
    {
        Format(materialPath, sizeof(materialPath), "materials/models/player/ics/admin_t_fixed/t_phoenix.vmt");
        AddFileToDownloadsTable("materials/models/player/ics/admin_t_fixed/t_phoenix.vtf");
    }
    else if (StrContains(modelPath, "t_arctic_admin") != -1)
    {
        Format(materialPath, sizeof(materialPath), "materials/models/player/ics/t_arctic_admin/t_arctic.vmt");
        AddFileToDownloadsTable("materials/models/player/ics/t_arctic_admin/t_arctic.vtf");
    }
    else if (StrContains(modelPath, "t_guerilla_admin") != -1)
    {
        Format(materialPath, sizeof(materialPath), "materials/models/player/ics/t_guerilla_admin/t_guerilla.vmt");
        AddFileToDownloadsTable("materials/models/player/ics/t_guerilla_admin/t_guerilla.vtf");
    }
    else if (StrContains(modelPath, "t_leet_admin") != -1)
    {
        Format(materialPath, sizeof(materialPath), "materials/models/player/ics/t_leet_admin/t_leet.vmt");
        AddFileToDownloadsTable("materials/models/player/ics/t_leet_admin/t_leet.vtf");
        AddFileToDownloadsTable("materials/models/player/ics/t_leet_admin/t_leet_glass.vmt");
    }

    int hModel = CreateEntityByName("prop_dynamic_override");
if (hModel != -1)
{
    DispatchKeyValue(hModel, "model", modelPath);
    DispatchSpawn(hModel);
    SetVariantString(materialPath);
    AcceptEntityInput(hModel, "SetMaterial");
    RemoveEdict(hModel);
}