#include <sourcemod>
#include <adminmenu>
#include <csgo_colors> /* for colors csgo */
#include <morecolors> /* for any game colors, but no csgo */
#include <geoipcity> /* for draw country and city */

#pragma newdecls required

#define SGT(%0) SetGlobalTransTarget(%0)
#define CID(%0) GetClientOfUserId(%0)
#define CUD(%0) GetClientUserId(%0)
#define VERSION "1.4.1"
/* Global variables */
TopMenu hTopMenu;
bool g_bGame;
int iViewPly[MAXPLAYERS+1];
char szFlag[32];
/* ConVars */
ConVar g_cv,
       g_padm,
       g_cEnableMotd,
       g_cEnableShow,
       g_cShowIPSID;
/* Info of plugin */
public Plugin myinfo = 
{
    version     = VERSION,
    author      = "Rabb1t",
    name        = "[SM] Info about players",
    description = "Draw information of players",
    url         = "http://hlmod.ru/resources/player-information.279/"
};

public void OnPluginStart() 
{   /* For ALL players */
    RegConsoleCmd("sm_info", Cmd_Info);
    RegConsoleCmd("sm_players", Cmd_Info);
    RegConsoleCmd("sm_infop", Cmd_Info);
    RegConsoleCmd("sm_playersinfo", Cmd_Info);
    /* For ONLY admins */
    RegAdminCmd("sm_infop_version", Cmd_Info_Version, ADMFLAG_ROOT); /* For only admin with flag Z */
    
    LoadTranslations("infoply.phrases");

    TopMenu topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
        OnAdminMenuReady(topmenu);
    
    CreateCvars();
    g_bGame = (GetEngineVersion() == Engine_CSGO);
}

public Action Cmd_Info(int iClient, int args) 
{
    if (iClient)
        RenderPlayersMenu(iClient);
    else
        ReplyToCommand(iClient, "[SM] Use this command in-game");
    return Plugin_Handled;
}

public void CreateCvars()
{
    CreateConVar("sm_infoplayers_version", VERSION, "Info about players version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_CHEAT);
    g_cv = CreateConVar("sm_infoplayers_type", "1", "Draw player information with menu, if value equal 1, or print to chat if value 0.", 0, true, 0.0, true, 1.0);
    g_padm = CreateConVar("sm_infoplayers_players_check_ip", "0", "Show the players IP to the other players", 0, true, 0.0, true, 1.0);
    g_cEnableMotd = CreateConVar("sm_infoplayers_enablemotd", "1", "Show player-profile in MOTD Window.", 0, true, 0.0, true, 1.0);
    g_cEnableShow = CreateConVar("sm_infoplayers_checkflags", "0", "Enable admin flags check (1 - on, 0 - off).", 0, true, 0.0, true, 1.0);
    g_cShowIPSID = CreateConVar("sm_infoplayers_adminflag", "z", "Admin-flag for check IP and SteamID of players.");
    
    HookConVarChange(g_cv,               OnCvarChanged);
    HookConVarChange(g_padm,             OnCvarChanged);
    HookConVarChange(g_cEnableMotd,      OnCvarChanged);
    HookConVarChange(g_cEnableShow,      OnCvarChanged)
    HookConVarChange(g_cShowIPSID,       OnCvarChanged);
    
    AutoExecConfig(true, "PlayerInformation");
}

public void OnConfigsExecuted() {
  OnCvarChanged(g_cv,    NULL_STRING,  NULL_STRING);
  OnCvarChanged(g_padm,  NULL_STRING,  NULL_STRING);
  OnCvarChanged(g_cEnableMotd, NULL_STRING,  NULL_STRING);
  OnCvarChanged(g_cEnableShow, NULL_STRING, NULL_STRING);
  OnCvarChanged(g_cShowIPSID,  NULL_STRING,  NULL_STRING);
}

bool g_bType = true, g_bCheckIP, g_bEnableMOTD = true, g_bCheckFlag;

public void OnCvarChanged(ConVar hCvar, const char[] szOV, const char[] szNV) {
  if (g_cv == hCvar) {
    g_bType = hCvar.BoolValue;
    return;
  }

  if (g_padm == hCvar) {
    g_bCheckIP = hCvar.BoolValue;
    return;
  }

  if (g_cEnableMotd == hCvar) {
    g_bEnableMOTD = hCvar.BoolValue;
    return;
  }
  
  if (g_cEnableShow == hCvar) {
      g_bCheckFlag = hCvar.BoolValue;
      return;
  }
  
  if (g_cShowIPSID == hCvar) {
      GetConVarString(g_cShowIPSID, szFlag, sizeof(szFlag));
      return;
  }

  // HAAAAAAAAX!
}


public void OnAdminMenuReady(Handle aTopMenu) 
{
    TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

    if (topmenu == hTopMenu)
        return;

    hTopMenu = topmenu;

    TopMenuObject plycommands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
    if (plycommands != INVALID_TOPMENUOBJECT)
        hTopMenu.AddItem("sm_info", AdminMenu_Info, plycommands, "sm_info", ADMFLAG_BAN);
}

public void AdminMenu_Info(TopMenu topmenu, TopMenuAction action, TopMenuObject objId, int param, char[] buffer, int maxlength) 
{
    if (action == TopMenuAction_DisplayOption)
        FormatEx(buffer, maxlength, "%T", "plyinfo_adminmenu", param);
    else if (action == TopMenuAction_SelectOption)
        RenderPlayersMenu(param, true);
}

/* Handlers */
public int PlyMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
    if (action == MenuAction_Select) 
    {
        char szBuffer[6];
        menu.GetItem(param2, szBuffer, sizeof(szBuffer));
        int iTarget = CID(StringToInt(szBuffer));
        if (iTarget)
            RenderPlayerInformation(param1, iTarget);
        else 
        {
                SGT(param1);
                if(g_bGame)
                    CGOPrintToChat(param1, "[SM] %t", "plyinfo_playerexited");
                else
                    CPrintToChat(param1, "[SM] %t", "plyinfo_playerexited");
                
                RenderPlayersMenu(param1);
        }
    } else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu)
        hTopMenu.Display(param1, TopMenuPosition_LastCategory);
}

public int AboutPlyHandler(Menu menu, MenuAction action, int param1, int param2) 
{
    if (action == MenuAction_Select && param2 == 9) 
    {
        int iTarget = CID(iViewPly[param1]);
        if (iTarget)
            RenderPlayerProfile(param1, iTarget);
        else 
        {
            SGT(param1);
            if(g_bGame)
                CGOPrintToChat(param1, "[SM] %t", "plyinfo_playerexited");
            else
                CPrintToChat(param1, "[SM] %t", "plyinfo_playerexited");
        }
    } 
    
    else if(action == MenuAction_Select && param2 == 8)
    {
        int iTarget = CID(iViewPly[param1]);
        if (iTarget)
            RenderPlayerProfile(param1, iTarget);
        else 
        {
            SGT(param1);
            if(g_bGame)
                CGOPrintToChat(param1, "[SM] %t", "plyinfo_playerexited");
            else
                CPrintToChat(param1, "[SM] %t", "plyinfo_playerexited");
        }
    }
   
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
        RenderPlayersMenu(param1);
}

/* Renders */
void RenderPlayersMenu(int iClient, bool fromAdmin = false) 
{
    SGT(iClient);

    Menu menu = new Menu(PlyMenuHandler);

    menu.SetTitle("%t:\n ", "plyinfo_menutitle");
    if (fromAdmin)
        menu.ExitBackButton = true;
    else
        menu.ExitButton = true;
    AddTargetsToMenu2(menu, 0, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS);

    menu.Display(iClient, MENU_TIME_FOREVER);
}

void RenderPlayerInformation(int iClient, int target) 
{
    SGT(iClient);
    iViewPly[iClient] = CUD(target);

    char szBuffer[80];
    char szAuth[32];
    char szPlayerIP[16];
    char szConnectTime[15];
    int iFlag;
    Menu hMenu;
    iFlag = ReadFlagString(szFlag);
    
    if(g_bType) {
        hMenu = new Menu(AboutPlyHandler);
        hMenu.SetTitle("%t:\n ", "plyinfo_plytitle_menu");
    }
    else
    {
        if(g_bGame)
            CGOPrintToChat(iClient, "%t", "plyinfo_plytitle");
        else
            CPrintToChat(iClient, "%t", "plyinfo_plytitle");
    }

    /**
     * 1. Username: Newbie
     * 2. Status: Player \ Administrator
     * 3. SteamID: STEAM_0:1:1337
     * 4. IP: 127.0.0.1
     * 5. Connect time: 2 min., 28 sec.
     * 
     * 7. Show user profile in MOTD
     */

    /* Player username */
    FormatEx(szBuffer, sizeof(szBuffer), "%t", "plyinfo_nickname_menu", target);
    if(g_bType)
        hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
    else
    {
        if(g_bGame)
            CGOPrintToChat(iClient, "%t", "plyinfo_nickname", target);
        else
            CPrintToChat(iClient, "%t", "plyinfo_nickname", target);
    }
    
    /* Status Client (Admin or player) */
    if(GetUserFlagBits(target) & (ADMFLAG_BAN|ADMFLAG_ROOT)) /* Client Admin */
    {
        FormatEx(szBuffer, sizeof(szBuffer), "%t", "plyinfo_status_admin");
        if(g_bType)
            hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
        else
        {
            if(g_bGame)
                CGOPrintToChat(iClient, "%t", "plyinfo_status_admin_chat");
            else
                CPrintToChat(iClient, "%t", "plyinfo_status_admin_chat");
        }
    }
    else /* Client Player */
    {
        FormatEx(szBuffer, sizeof(szBuffer), "%t", "plyinfo_status_player");
        if(g_bType)
            hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
        else
        {
            if(g_bGame)
                CGOPrintToChat(iClient, "%t", "plyinfo_status_player_chat");
            else
                CPrintToChat(iClient, "%t", "plyinfo_status_player_chat");
        }
    }
    
    /* SteamID */
    if(g_bCheckFlag) {
        if(iFlag != 0 && (GetUserFlagBits(iClient) & (iFlag|ADMFLAG_ROOT))) {
            if (!GetClientAuthId(target, AuthId_Steam2, szAuth, sizeof(szAuth)))
            strcopy(szAuth, sizeof(szAuth), "STEAM_ID_PENDING");
        
            if(g_bType)
            {
                FormatEx(szBuffer, sizeof(szBuffer), "%t", "steamid_phrase_menu", szAuth);
                hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
            }
            else
            {
                if(g_bGame)
                    CGOPrintToChat(iClient, "%t", "steamid_phrase_chat", szAuth);
                else
                    CPrintToChat(iClient, "%t", "steamid_phrase_chat", szAuth);
            }
        }
    }
    else {
        if (!GetClientAuthId(target, AuthId_Steam2, szAuth, sizeof(szAuth)))
            strcopy(szAuth, sizeof(szAuth), "STEAM_ID_PENDING");
        
        if(g_bType)
        {
            FormatEx(szBuffer, sizeof(szBuffer), "%t", "steamid_phrase_menu", szAuth);
            hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
        }
        else
        {
            if(g_bGame)
                CGOPrintToChat(iClient, "%t", "steamid_phrase_chat", szAuth);
            else
                CPrintToChat(iClient, "%t", "steamid_phrase_chat", szAuth);
        }
    }


    /* IP */
    if(g_bCheckFlag) {
        if(iFlag != 0 && (GetUserFlagBits(iClient) & (iFlag|ADMFLAG_ROOT))) {
            if (!GetClientIP(target, szPlayerIP, sizeof(szPlayerIP)))
                strcopy(szPlayerIP, sizeof(szPlayerIP), "127.0.0.1");
            
            if (g_bCheckIP || GetUserFlagBits(iClient) & (ADMFLAG_BAN|ADMFLAG_ROOT)) /* IP now Draw to players, only admins */
            {
                Format(szBuffer, sizeof(szBuffer), "%t", "plyinfo_ip_menu", szPlayerIP);
                if(g_bType)
                    hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
                else
                {
                    if(g_bGame)
                        CGOPrintToChat(iClient, "%t", "plyinfo_ip", szPlayerIP);
                    else
                        CPrintToChat(iClient, "%t", "plyinfo_ip", szPlayerIP);
                }
            }
        }
    }
    else {
        if (!GetClientIP(target, szPlayerIP, sizeof(szPlayerIP)))
                strcopy(szPlayerIP, sizeof(szPlayerIP), "127.0.0.1");
            
        if (g_bCheckIP || GetUserFlagBits(iClient) & (ADMFLAG_BAN|ADMFLAG_ROOT)) /* IP now Draw to players, only admins */
        {
            Format(szBuffer, sizeof(szBuffer), "%t", "plyinfo_ip_menu", szPlayerIP);
            if(g_bType)
                hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
            else
            {
                if(g_bGame)
                    CGOPrintToChat(iClient, "%t", "plyinfo_ip", szPlayerIP);
                else
                    CPrintToChat(iClient, "%t", "plyinfo_ip", szPlayerIP);
            }
        }
    }
    
    /* Connection time */
    PrepareTime(szConnectTime, sizeof(szConnectTime), RoundToFloor(GetClientTime(target)));
    Format(szBuffer, sizeof(szBuffer), "%t", "plyinfo_connected_menu", szConnectTime);
    if(g_bType)
        hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
    else
    {
        if(g_bGame)
            CGOPrintToChat(iClient, "%t", "plyinfo_connected", szConnectTime);
        else
            CPrintToChat(iClient, "%t", "plyinfo_connected", szConnectTime);
    }
    
    /* GeoIP */
    char szCity[45], szRegion[45], szCountry[45], szCountryCode[3], szCountryCode3[4], szBuff[150], szBuff2[150], szBuff3[150];
    if(GeoipGetRecord(szPlayerIP, szCity, szRegion, szCountry, szCountryCode, szCountryCode3))
    {
        FormatEx(szBuff, sizeof(szBuff), "%t", "plyinfo_country", szCountry);
        FormatEx(szBuff3, sizeof(szBuff3), "%t", "plyinfo_city", szCity);
        FormatEx(szBuff2, sizeof(szBuff2), "%t", "plyinfo_region", szRegion);
        
        if(g_bType)
        {
            hMenu.AddItem(NULL_STRING, szBuff, ITEMDRAW_DISABLED);
            hMenu.AddItem(NULL_STRING, szBuff2, ITEMDRAW_DISABLED);
            hMenu.AddItem(NULL_STRING, szBuff3, ITEMDRAW_DISABLED);
        }
        else 
        {
            if(g_bGame)
            {
                CGOPrintToChat(iClient, "%t", "plyinfo_country_chat", szCountry);
                CGOPrintToChat(iClient, "%t", "plyinfo_city_chat", szCity);
                CGOPrintToChat(iClient, "%t", "plyinfo_region_chat", szRegion);
            }
            else
            {
                CPrintToChat(iClient, "%t", "plyinfo_country_chat", szCountry);
                CPrintToChat(iClient, "%t", "plyinfo_city_chat", szCity);
                CPrintToChat(iClient, "%t", "plyinfo_region_chat", szRegion); 
            }
        }
    }
    
   /* if (bLogging) // Logging Connection time 
        LogMessage(szBuffer); */ 
    
    /* Spacer and MOTD */
    if(g_bEnableMOTD) {
        if(!g_bGame) /* OFF on CS:GO */
        {
            if(g_bType) {
                hMenu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_SPACER);
                FormatEx(szBuffer, sizeof(szBuffer), "%t", "plyinfo_showprofile");
                hMenu.AddItem(NULL_STRING, szBuffer);
            }
        }
    }
    
    /* DRAW, IF THE MENU. */
    if(g_bType){
        hMenu.ExitBackButton = true;
        hMenu.Display(iClient, MENU_TIME_FOREVER);
    }
}

void RenderPlayerProfile(int iClient, int target) 
{
    char szBuffer[64];
    if (GetClientAuthId(target, AuthId_SteamID64, szBuffer, sizeof(szBuffer))) 
    {
        Format(szBuffer, sizeof(szBuffer), "https://steamcommunity.com/profiles/%s/", szBuffer);
        
        ShowMOTDPanel(iClient, "Steam Profile", szBuffer, MOTDPANEL_TYPE_URL);
    }
}

/* Helpers */
int PrepareTime(char[] buff, int buffLength, int iTime) {
    int iMinute =   iTime/60; 
    int iHour   =   (iTime-(iMinute*60))/60;
    int iSecond =   iTime-((iHour*3600)+iMinute*60);
    
    return FormatEx(buff, buffLength, "%d:%d:%d", iHour, iMinute, iSecond);
}
/* Draw version of plugin (*/
public Action Cmd_Info_Version(int iClient, int args)
{
    if (iClient >= 1 && IsClientInGame(iClient))
        ReplyToCommand(iClient, "Version of plugin = %s", VERSION); 
    return Plugin_Handled;
}