#include <sourcemod>
#include <csgocolors>

bool ConfiguredMap;
char g_Config[PLATFORM_MAX_PATH], g_CurrentMap[128], allowed[6], info[32];

// ====[ PLUGIN ]==============================================================
public Plugin myinfo =
{
    name = "Block/Allow joining team",
    author = "PinHeaDi",
    description = "Blockteam with a userfriendly menu",
    version = "1.0",
    url = "http://steamcommunity.com/profiles/76561198047681263"
};

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
    RegAdminCmd("sm_allowteam", BlockTeam, ADMFLAG_ROOT);
}

public void OnMapStart()
{
    BuildPath(Path_SM, g_Config, sizeof(g_Config), "configs/blockteam_maps.cfg");
    if(!FileExists(g_Config))
    {
        KeyValues generatefile = new KeyValues("blockteam_config");
        generatefile.ExportToFile(g_Config);
        delete generatefile;
    }
}

public void OnConfigsExecuted()
{
    ParseConfig();
}

public Action BlockTeam(int client, int args)
{
    if(IsFakeClient(client)) return Plugin_Handled;

    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    
    if(ConfiguredMap)
    {
        char team[6];
        GetConVarString(FindConVar("mp_humanteam"), team, sizeof(team));
        
        if(StrEqual(team, "t", false))
        {
            CPrintToChat(client,"[{lightgreen}Info{default}] {orange}%s {default}is currently configured. Players can only join as {green}Terrorits{default}.", g_CurrentMap);
        }
        else if(StrEqual(team, "ct", false))
        {
            CPrintToChat(client,"[{lightgreen}Info{default}] {orange}%s {default}is currently configured. Players can only join as {green}Counter-Terrorits{default}.", g_CurrentMap);
        }
    }
    else
    {
        CPrintToChat(client,"[{lightgreen}Info{default}] {orange}%s {default}is {red}not {default}configured.", g_CurrentMap);
    }
    
    BlockingMenu(client, args);
    return Plugin_Continue;
}

// ====[ PARSE MAP ]============================================================
void ParseConfig()
{
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    BuildPath(Path_SM, g_Config, sizeof(g_Config), "configs/blockteam_maps.cfg");    

    KeyValues block = new KeyValues("blockteam_config");
    Handle allowedteam = FindConVar("mp_humanteam");

    if (FileToKeyValues(block, g_Config))
    {
        if (KvJumpToKey(block, g_CurrentMap))
        {
            KvGetString(block, "team_allowed", allowed, sizeof(allowed));
            
            if(StrEqual(allowed, "t"))
            {
                SetConVarString(allowedteam, "t", true, false);
                ConfiguredMap = true;
            }
            else if(StrEqual(allowed, "ct"))
            {
                SetConVarString(allowedteam, "ct", true, false);
                ConfiguredMap = true;
            }
        }
        else
        {
            SetConVarString(allowedteam, "any", true, false);
            ConfiguredMap = false;
        }
        delete allowedteam;
    }
    delete block;
}  

// ====[ MENUS ]===============================================================
public int Block_Menu(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
            BuildPath(Path_SM, g_Config, sizeof(g_Config), "configs/blockteam_maps.cfg");
            menu.GetItem(param2, info, sizeof(info));

            if (StrEqual(info, "AddCT"))
            {
                KeyValues BlockedMaps = new KeyValues("blockteam_config");
                BlockedMaps.ImportFromFile(g_Config);
                BlockedMaps.JumpToKey(g_CurrentMap, true);
                
                Format(allowed, sizeof(allowed), "ct");
                CPrintToChat(client, "[{lightgreen}Done!{default}] Now players can only join as {green}Counter-Terrorits {default}on {orange}%s{default}.", g_CurrentMap);
                
                BlockedMaps.SetString("team_allowed", allowed);
                BlockedMaps.Rewind();
                BlockedMaps.ExportToFile(g_Config);
                delete BlockedMaps; 
                ParseConfig();
            }
            else if (StrEqual(info, "AddT"))
            {
                KeyValues BlockedMaps = new KeyValues("blockteam_config");
                BlockedMaps.ImportFromFile(g_Config);
                BlockedMaps.JumpToKey(g_CurrentMap, true);
                
                Format(allowed, sizeof(allowed), "t");
                CPrintToChat(client, "[{lightgreen}Done!{default}] Now players can only join as {green}Terrorits {default}on {orange}%s{default}.", g_CurrentMap);
                
                BlockedMaps.SetString("team_allowed", allowed);
                BlockedMaps.Rewind();
                BlockedMaps.ExportToFile(g_Config);
                delete BlockedMaps; 
                ParseConfig();
            }
            else if (StrEqual(info, "Remove"))
            {
                KeyValues RemoveMap = new KeyValues("blockteam_config");
                RemoveMap.ImportFromFile(g_Config);
                
                if (!KvJumpToKey(RemoveMap, g_CurrentMap))
                {
                    CPrintToChat(client,"[{lightgreen}Info{default}] The map is {orange}not {default}configured, thereforce it can't be removed.");
                    delete RemoveMap; 
                }
                else
                {
                    RemoveMap.DeleteThis();
                    RemoveMap.Rewind();
                    RemoveMap.ExportToFile(g_Config);
                    delete RemoveMap;
                    CPrintToChat(client,"[{lightgreen}Info{default}] {orange}%s {default}was {green}removed{default}. Now players can join {lightgreen}both teams.", g_CurrentMap);
                    ParseConfig();
                }
            }
        }
        case MenuAction_End:{delete menu;}
    }    

    return 0;
}

public void BlockingMenu(int client, int args)
{
    Menu BlockMenu = new Menu(Block_Menu);
    BlockMenu.SetTitle("What do you want to do?");
    BlockMenu.AddItem("AddCT", "Allow players to only join as Counter-Terrorits");
    BlockMenu.AddItem("AddT", "Allow players to only join as Terrorits");
    BlockMenu.AddItem("Info1", "- - - - - - - - - - - - - - - - - - - - - - - - - -", ITEMDRAW_DISABLED);
    BlockMenu.AddItem("Remove", "Remove any blocks on this map");
    BlockMenu.ExitButton = true;
    BlockMenu.Display(client, 15);
}