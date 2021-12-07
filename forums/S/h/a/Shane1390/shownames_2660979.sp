#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <multicolors>

bool g_bShowName[MAXPLAYERS+1];
bool g_bShowDamage[MAXPLAYERS + 1];
bool g_bShowHM[MAXPLAYERS + 1];

float g_fWait[MAXPLAYERS + 1];

Handle ShowDamage_Cookie = INVALID_HANDLE;
Handle hudSync = INVALID_HANDLE;

char ctFormat[256], tFormat[256], damageFormatT[256], damageFormatCT[256];

public Plugin myinfo =
{
    name = "ShowNames",
    author = "AntiTeal, edit by Shane",
    description = "Shows the name of the player you're looking at, or displays your damage to them.",
    version = "1.7",
    url = "www.joinsg.net"
}

public void OnPluginStart()
{
    //looking at ct
    ctFormat = "<font color='#3366FF' size='20'>Counter-Terrorist: <font color='#FFFFFF'>%N</font><br><font color='#3366FF'>Health: </font><font color='#00FF00'>%i HP</font>";
    //looking at t
    tFormat = "<font color='#FF0000' size='20'>Terrorist: <font color='#FFFFFF'>%N</font><br><font color='#FF0000'>Health: </font><font color='#00FF00'>%i HP</font>";
    //damage to t
    damageFormatT = "<font color='#FFFFFF'>You dealt</font><font color='#FF0000'> %i</font><font color='#FFFFFF'> Damage to</font><font color='#FF0000'> %N</font><br><font color='#FFFFFF'>Health Remaining:</font><font color='#00FF00'> %i</font>";
    //damage to ct
    damageFormatCT = "<font color='#FFFFFF'>You dealt</font><font color='#FF0000'> %i</font><font color='#FFFFFF'> Damage to</font><font color='#3366FF'> %N</font><br><font color='#FFFFFF'>Health Remaining:</font><font color='#00FF00'> %i</font>";

    RegConsoleCmd("sm_showname", ShowNamesMenu);
    RegConsoleCmd("sm_shownames", ShowNamesMenu);
    RegConsoleCmd("sm_sn", ShowNamesMenu);
    RegConsoleCmd("sm_showdamage", ShowNamesMenu);
    RegConsoleCmd("sm_sd", ShowNamesMenu);

    CreateTimer(0.0, ShowNameHud, _, TIMER_REPEAT);
    hudSync = CreateHudSynchronizer();
    
    ShowDamage_Cookie = RegClientCookie("sn_cookie", "Toggle seeing Damage in HUD.", CookieAccess_Protected);
    SetCookieMenuItem(ShowNamesMenu_Cookie, 0, "Show Names & Damage");
    
    for(int client = 1; client <= MaxClients; client++) {
        if(AreClientCookiesCached(client)) {
            OnClientCookiesCached(client);
        }
    }
    HookEvent("player_hurt", evntPlayerHurt);
}

public void OnPluginEnd()
{
    if(hudSync != INVALID_HANDLE) {
        CloseHandle(hudSync);
        hudSync = INVALID_HANDLE;
    }
}

public void OnClientDisconnect(int client)
{
    g_bShowName[client] = false;
    g_bShowDamage[client] = false;
    g_bShowHM[client] = false;
}

public void hitMarker(int client)
{
    SetHudTextParams(-1.0, -1.0, 0.5, 255, 0, 0, 255, 1, 0.2, 0.0, 0.2);
    ShowSyncHudText(client, hudSync, "∷");
}

public void OnClientCookiesCached(int client)
{
    char sBuffer[4];
    GetClientCookie(client, ShowDamage_Cookie, sBuffer, sizeof(sBuffer));

    if(sBuffer[0] != '\0') {
        char sTemp[2];
        FormatEx(sTemp, sizeof(sTemp), "%c", sBuffer[0]);
        g_bShowDamage[client] = StrEqual(sTemp, "1");
        FormatEx(sTemp, sizeof(sTemp), "%c", sBuffer[1]);
        g_bShowHM[client] = StrEqual(sTemp, "1");
        FormatEx(sTemp, sizeof(sTemp), "%c", sBuffer[2]);
        g_bShowName[client] = StrEqual(sTemp, "1");
    } else {
        g_bShowDamage[client] = false;
        g_bShowHM[client] = false;
        g_bShowName[client] = true;
        SaveClientCookies(client);
    }
}

void SaveClientCookies(int client)
{
    char sCookie[4];
    FormatEx(sCookie, sizeof(sCookie), "%b%b%b", g_bShowDamage[client], g_bShowHM[client], g_bShowName[client]);
    SetClientCookie(client, ShowDamage_Cookie, sCookie);
}

public void ShowNamesMenu_Cookie(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    if(action == CookieMenuAction_SelectOption)
        ShowNamesMenu(client, 1);
}

public int ShowNamesMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
    if(action == MenuAction_Select) {
        if(param == 0) {
            g_bShowDamage[client] = !g_bShowDamage[client];
            CPrintToChat(client, "Damage: %s{default}.", g_bShowDamage[client] ? "{green}Enabled" : "{darkred}Disabled");
        } else if(param == 1) {
            g_bShowHM[client] = !g_bShowHM[client];
            CPrintToChat(client, "Hitmarkers: %s{default}.", g_bShowHM[client] ? "{green}Enabled" : "{darkred}Disabled");
        } else {
            g_bShowName[client] = !g_bShowName[client];
            CPrintToChat(client, "Player Info: %s{default}.", g_bShowName[client] ? "{green}Enabled" : "{darkred}Disabled");
        }
        SaveClientCookies(client);
        ShowNamesMenu(client, 1);
    } else if(action == MenuAction_Cancel)
        ShowCookieMenu(client);
    else if(action == MenuAction_End)
        delete menu;
}

public Action ShowNamesMenu(int client, int args)
{
    Menu menu = new Menu(ShowNamesMenu_Handler, MENU_ACTIONS_DEFAULT);
    menu.SetTitle("Show Names & Damage \n \nToggle HUD and Hitmarkers Below \n ");

    char sTemp[32];
    FormatEx(sTemp, sizeof(sTemp), "Damage: %s", g_bShowDamage[client] ? "Enabled" : "Disabled");
    menu.AddItem("btnDmg", sTemp);
    FormatEx(sTemp, sizeof(sTemp), "Hitmarkers: %s", g_bShowHM[client] ? "Enabled" : "Disabled");
    menu.AddItem("btnHM", sTemp);
    FormatEx(sTemp, sizeof(sTemp), "Player Info: %s", g_bShowName[client] ? "Enabled" : "Disabled");
    menu.AddItem("btnInfo", sTemp);
    
    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

stock int TraceClientViewEntity(int client)
{
    float vPos[3], vAng[3];
    GetClientEyePosition(client, vPos);
    GetClientEyeAngles(client, vAng);

    Handle hTrace = TR_TraceRayFilterEx(vPos, vAng, MASK_VISIBLE, RayType_Infinite, TraceFilter, client);
    int iEntity = TR_GetEntityIndex(hTrace);
    CloseHandle(hTrace);
    return iEntity;
}

public bool TraceFilter(int entity, int mask, any data)
{
    return (entity != data && 1 <= entity <= MaxClients); 
}

public Action ShowNameHud(Handle timer, int data)
{
    for(int client = 1; client <= MaxClients; client++) 
    {
        if(!g_bShowName[client] || !IsClientInGame(client) || !IsPlayerAlive(client) || IsVoteInProgress() || g_fWait[client] >= GetGameTime())continue;
        int iTarget = TraceClientViewEntity(client);
        if(iTarget <= 0 || !IsClientInGame(iTarget) || IsFakeClient(iTarget))continue;

        int health = GetClientHealth(iTarget);
        PrintHintText(client, (GetClientTeam(iTarget) == 3 ? ctFormat : tFormat), iTarget, health);
    }
}

public Action evntPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("attacker"));
    if(!g_bShowDamage[client] && !g_bShowHM[client])return;
    if(client == 0 || !IsClientInGame(client) || IsVoteInProgress())return;

    int iVictim = GetClientOfUserId(event.GetInt("userid"));
    if(client == iVictim)return;

    int iHealth = GetClientHealth(iVictim);
    int iDamage = event.GetInt("dmg_health");

    if(g_bShowDamage[client])
    {
        PrintHintText(client, (GetClientTeam(iVictim) == 2 ? damageFormatT : damageFormatCT), iDamage, iVictim, iHealth);
        g_fWait[client] = GetGameTime() + 0.7;
    }
    if(g_bShowHM[client])
        hitMarker(client);
}