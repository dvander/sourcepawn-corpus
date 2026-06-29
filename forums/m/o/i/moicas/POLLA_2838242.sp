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
    RegConsoleCmd("sm_campaigns", Cmd_ShowMenu);
}

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

void ShowMainMenu(int client)
{
    Menu menu = new Menu(MainMenu_Handler);
    menu.SetTitle("Main Selector:");
    
    char currentModeText[64];
    Format(currentModeText, sizeof(currentModeText), "Change map (Current mode: %s)", g_sCurrentGameMode);
    
    menu.AddItem("current", currentModeText);
    menu.AddItem("change", "Change Game Mode");
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));
        
        if (StrEqual(info, "current")) { ShowGamesMenu(client, g_sCurrentGameMode); } 
        else if (StrEqual(info, "change")) { ShowModesMenu(client); }
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

void ShowModesMenu(int client)
{
    Menu menu = new Menu(ModesMenu_Handler);
    menu.SetTitle("Select Game Mode:");
    
    menu.AddItem("coop", "Co-op");
    menu.AddItem("realism", "Realism");
    menu.AddItem("versus", "Versus");
    menu.AddItem("survival", "Survival");
    menu.AddItem("scavenge", "Scavenge");
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int ModesMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char mode[32];
        menu.GetItem(item, mode, sizeof(mode));
        ShowGamesMenu(client, mode);
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

void ShowGamesMenu(int client, const char[] mode)
{
    Menu menu = new Menu(GamesMenu_Handler);
    menu.SetTitle("Select Game (%s):", mode);
    
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
        ExplodeString(info, "|", parts, 2, 32);
        ShowCampaignsMenu(client, parts[0], parts[1]);
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

void ShowCampaignsMenu(int client, const char[] mode, const char[] game)
{
    Menu menu = new Menu(CampaignsMenu_Handler);
    menu.SetTitle("Campaigns (%s - %s):", game, mode);
    
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/campaigns_en.txt");
    File file = OpenFile(path, "r");
    
    if (file == null) {
        menu.AddItem("err", "Missing campaigns_en.txt in configs/", ITEMDRAW_DISABLED);
        menu.Display(client, MENU_TIME_FOREVER);
        return;
    }

    StringMap addedCats = new StringMap();
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

        if (!StrEqual(fMode, mode, false) || !StrEqual(fGame, game, false)) continue;

        if (StrContains(fName, ":") != -1) {
            char nameParts[2][64];
            ExplodeString(fName, ":", nameParts, 2, 64);
            char category[64];
            strcopy(category, sizeof(category), nameParts[0]); TrimString(category);

            int dummy;
            if (!addedCats.GetValue(category, dummy)) {
                addedCats.SetValue(category, 1);
                char itemInfo[128];
                Format(itemInfo, sizeof(itemInfo), "cat|%s|%s|%s", mode, game, category);
                menu.AddItem(itemInfo, category);
            }
        } else {
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
            ShowMapsMenu(client, parts[1], parts[2], parts[3]);
        } else if (StrEqual(parts[0], "map") && numParts == 3) {
            ChangeMapSafe(parts[1], parts[2]);
        }
    }
    else if (action == MenuAction_End) { delete menu; }
    return 0;
}

void ShowMapsMenu(int client, const char[] mode, const char[] game, const char[] category)
{
    Menu menu = new Menu(MapsMenu_Handler);
    menu.SetTitle("%s (%s):", category, mode);
    
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/campaigns_en.txt");
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

        char searchPrefix[128];
        Format(searchPrefix, sizeof(searchPrefix), "%s:", category);
        
        if (StrContains(fName, searchPrefix) == 0) {
            char nameParts[2][64];
            ExplodeString(fName, ":", nameParts, 2, 64);
            char subname[64];
            strcopy(subname, sizeof(subname), nameParts[1]); TrimString(subname);

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

    ServerCommand("map %s %s", map, mode);
    return Plugin_Stop;
}