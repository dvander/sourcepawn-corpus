#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

char g_sCurrentGameMode[32];

public Plugin myinfo = 
{
    name = "El seletor mas cabron de la puta historia tio",
    author = "moisas y tute",
    description = "version definitiva enhanced gay",
    version = "9.0",
    url = ""
};

public void OnPluginStart()
{
    // Tu comando para abrir el menú principal
    RegConsoleCmd("sm_sex", Cmd_ShowMenu);
}

// Obtenemos el modo actual para la opción rápida
void GetCurrentMode()
{
    ConVar cv = FindConVar("mp_gamemode");
    if (cv != null) {
        cv.GetString(g_sCurrentGameMode, sizeof(g_sCurrentGameMode));
    } else {
        strcopy(g_sCurrentGameMode, sizeof(g_sCurrentGameMode), "coop");
    }
}

public Action Cmd_ShowMenu(int client, int args)
{
    if (client > 0 && IsClientInGame(client))
    {
        GetCurrentMode();
        ShowMainMenu(client);
    }
    return Plugin_Handled;
}

// ==========================================
// 1. MENÚ PRINCIPAL
// ==========================================
void ShowMainMenu(int client)
{
    Menu menu = new Menu(MainMenu_Handler);
    menu.SetTitle("Selector Principal:");
    
    char currentModeText[64];
    Format(currentModeText, sizeof(currentModeText), "Cambiar mapa (Modo actual: %s)", g_sCurrentGameMode);
    
    menu.AddItem("current", currentModeText);
    menu.AddItem("change", "Cambiar Modo de Juego");
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));
        
        if (StrEqual(info, "current")) {
            ShowGamesMenu(client, g_sCurrentGameMode);
        } else if (StrEqual(info, "change")) {
            ShowModesMenu(client);
        }
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

// ==========================================
// 2. MENÚ DE MODOS
// ==========================================
void ShowModesMenu(int client)
{
    Menu menu = new Menu(ModesMenu_Handler);
    menu.SetTitle("Modos de Juego:");
    
    menu.AddItem("coop", "Cooperativo");
    menu.AddItem("realism", "Realista");
    menu.AddItem("versus", "Enfrentamiento");
    menu.AddItem("survival", "Supervivencia");
    menu.AddItem("scavenge", "Búsqueda");
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int ModesMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char mode[32];
        menu.GetItem(item, mode, sizeof(mode));
        ShowGamesMenu(client, mode); // Pasamos al siguiente menú
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

// ==========================================
// 3. MENÚ DE JUEGOS (L4D1 / L4D2)
// ==========================================
void ShowGamesMenu(int client, const char[] mode)
{
    Menu menu = new Menu(GamesMenu_Handler);
    menu.SetTitle("Selecciona Juego (%s):", mode);
    
    // Empaquetamos la información para saber qué seleccionó antes
    char infoL4D1[64], infoL4D2[64];
    Format(infoL4D1, sizeof(infoL4D1), "%s|l4d1", mode);
    Format(infoL4D2, sizeof(infoL4D2), "%s|l4d2", mode);
    
    menu.AddItem(infoL4D1, "Left 4 Dead 1");
    menu.AddItem(infoL4D2, "Left 4 Dead 2");
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int GamesMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[64], parts[2][32];
        menu.GetItem(item, info, sizeof(info));
        ExplodeString(info, "|", parts, 2, 32); // Separamos el modo del juego
        
        ShowCampaignsMenu(client, parts[0], parts[1]); // Abrimos el menú de campañas
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

// ==========================================
// 4. MENÚ DE CAMPAÑAS (Extracción del TXT)
// ==========================================
void ShowCampaignsMenu(int client, const char[] mode, const char[] game)
{
    Menu menu = new Menu(CampaignsMenu_Handler);
    menu.SetTitle("Campañas (%s - %s):", game, mode);
    
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/campaigns-SPN.txt");
    File file = OpenFile(path, "r");
    
    if (file == null) {
        menu.AddItem("err", "Falta campaigns.txt en configs/", ITEMDRAW_DISABLED);
        menu.Display(client, MENU_TIME_FOREVER);
        return;
    }

    StringMap addedCats = new StringMap(); // Para no duplicar categorías de supervivencia
    char line[256];
    
    while (file.ReadLine(line, sizeof(line))) {
        TrimString(line);
        if (line[0] == '\0' || line[0] == ';' || StrContains(line, "===") == 0 || StrContains(line, "---") == 0) continue;

        char parts[4][64];
        if (ExplodeString(line, "|", parts, 4, 64) < 4) continue;
        
        char fMap[64], fMode[32], fName[128], fGame[32];
        strcopy(fMap, sizeof(fMap), parts[0]); TrimString(fMap);
        strcopy(fMode, sizeof(fMode), parts[1]); TrimString(fMode);
        strcopy(fName, sizeof(fName), parts[2]); TrimString(fName);
        strcopy(fGame, sizeof(fGame), parts[3]); TrimString(fGame);

        // Solo leemos las líneas que coinciden con el modo y juego seleccionado
        if (!StrEqual(fMode, mode, false) || !StrEqual(fGame, game, false)) continue;

        if (StrContains(fName, ":") != -1) {
            // Es Supervivencia o Búsqueda (tiene dos puntos). Creamos un apartado.
            char nameParts[2][64];
            ExplodeString(fName, ":", nameParts, 2, 64);
            char category[64];
            strcopy(category, sizeof(category), nameParts[0]); TrimString(category);

            int dummy;
            if (!addedCats.GetValue(category, dummy)) {
                addedCats.SetValue(category, 1); // Lo marcamos como añadido
                
                char itemInfo[128];
                Format(itemInfo, sizeof(itemInfo), "cat|%s|%s|%s", mode, game, category);
                menu.AddItem(itemInfo, category); // Agregamos la carpeta al menú
            }
        } else {
            // Es Coop/Enfrentamiento (sin dos puntos). Agregamos el mapa directo.
            char itemInfo[128];
            Format(itemInfo, sizeof(itemInfo), "map|%s|%s", fMap, fMode);
            menu.AddItem(itemInfo, fName);
        }
    }
    delete file;
    delete addedCats;

    menu.Display(client, MENU_TIME_FOREVER);
}

public int CampaignsMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[128], parts[4][64];
        menu.GetItem(item, info, sizeof(info));
        int numParts = ExplodeString(info, "|", parts, 4, 64);
        
        if (StrEqual(parts[0], "cat") && numParts == 4) {
            // Eligieron una carpeta de supervivencia -> Abrimos el Submenú
            ShowMapsMenu(client, parts[1], parts[2], parts[3]);
        } else if (StrEqual(parts[0], "map") && numParts == 3) {
            // Eligieron un mapa directo -> Cambiamos el nivel
            ChangeMapSafe(parts[1], parts[2]);
        }
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

// ==========================================
// 5. MENÚ DE MAPAS (Solo Survival/Scavenge)
// ==========================================
void ShowMapsMenu(int client, const char[] mode, const char[] game, const char[] category)
{
    Menu menu = new Menu(MapsMenu_Handler);
    menu.SetTitle("%s (%s):", category, mode);
    
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/campaigns.txt");
    File file = OpenFile(path, "r");
    
    if (file == null) return;

    char line[256];
    while (file.ReadLine(line, sizeof(line))) {
        TrimString(line);
        if (line[0] == '\0' || line[0] == ';') continue;

        char parts[4][64];
        if (ExplodeString(line, "|", parts, 4, 64) < 4) continue;
        
        char fMap[64], fMode[32], fName[128], fGame[32];
        strcopy(fMap, sizeof(fMap), parts[0]); TrimString(fMap);
        strcopy(fMode, sizeof(fMode), parts[1]); TrimString(fMode);
        strcopy(fName, sizeof(fName), parts[2]); TrimString(fName);
        strcopy(fGame, sizeof(fGame), parts[3]); TrimString(fGame);

        if (!StrEqual(fMode, mode, false) || !StrEqual(fGame, game, false)) continue;

        // Buscamos que el nombre contenga la categoría seleccionada (ej. "Dead Center:")
        char searchPrefix[128];
        Format(searchPrefix, sizeof(searchPrefix), "%s:", category);
        
        if (StrContains(fName, searchPrefix) == 0) {
            char nameParts[2][64];
            ExplodeString(fName, ":", nameParts, 2, 64);
            char subname[64];
            strcopy(subname, sizeof(subname), nameParts[1]); TrimString(subname); // Extraemos la parte final (ej. "Gun Shop")

            char itemInfo[128];
            Format(itemInfo, sizeof(itemInfo), "map|%s|%s", fMap, fMode);
            menu.AddItem(itemInfo, subname);
        }
    }
    delete file;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MapsMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[128], parts[3][64];
        menu.GetItem(item, info, sizeof(info));
        if (ExplodeString(info, "|", parts, 3, 64) == 3) {
            ChangeMapSafe(parts[1], parts[2]);
        }
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

// ==========================================
// LÓGICA FINAL (Temporizador Seguro)
// ==========================================
void ChangeMapSafe(const char[] mapName, const char[] modeName)
{
    DataPack pack;
    CreateDataTimer(0.1, Timer_ChangeMap, pack);
    pack.WriteString(mapName);
    pack.WriteString(modeName);
}

public Action Timer_ChangeMap(Handle timer, DataPack pack)
{
    char map[64], mode[32];
    pack.Reset();
    pack.ReadString(map, sizeof(map));
    pack.ReadString(mode, sizeof(mode));

    // Forzamos el mapa y el modo al Director de Valve
    ServerCommand("map %s %s", map, mode);
    return Plugin_Stop;
}