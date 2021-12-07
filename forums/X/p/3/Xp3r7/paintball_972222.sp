#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PAINTBALL_VERSION      "1.0"

public Plugin:myinfo = 
{
    name = "Paintball",
    author = "otstrel.ru Team",
    description = "Add paintball impacts on the map after shots.",
    version = PAINTBALL_VERSION,
    url = "otstrel.ru"
}

new const String:PrimarySprites[][] = 
{ 
    "paintball/pb_cyan.vmt",
    "paintball/pb_green.vmt",
    "paintball/pb_pink.vmt",
    "paintball/pb_orange.vmt",
    "paintball/pb_yellow.vmt",
    "paintball/pb_babyblue2.vmt",
    "paintball/pb_blue2.vmt",
    "paintball/pb_limegreen2.vmt",
    "paintball/pb_purple2.vmt",
    "paintball/pb_red2.vmt",
    "paintball/pb_white2.vmt"
};

new gSpriteIndex[sizeof PrimarySprites];

new const String:SecondarySprites[][] =
{
    "paintball/pb_cyan.vtf",
    "paintball/pb_green.vtf",
    "paintball/pb_pink.vtf",
    "paintball/pb_orange.vtf",
    "paintball/pb_yellow.vtf",
    "paintball/pb_babyblue2.vtf",
    "paintball/pb_blue2.vtf",
    "paintball/pb_limegreen2.vtf",
    "paintball/pb_purple2.vtf",
    "paintball/pb_red2.vtf",
    "paintball/pb_white2.vtf"
};

new g_clientPrefs[MAXPLAYERS+1];

new g_clientsPaintballEnabled[MAXPLAYERS];
new g_clientsPaintballEnabledTotal = 0;

new Handle:g_Cvar_PrefDefault = INVALID_HANDLE;
new Handle:g_Cookie_Pref      = INVALID_HANDLE;

public OnPluginStart()
{
    LoadTranslations("paintball.phrases");

    new Handle:Cvar_Version = CreateConVar("sm_paintball_version", PAINTBALL_VERSION, 
        "Paintball Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    // KLUGE: Update version cvar if plugin updated on map change.
    SetConVarString(Cvar_Version, PAINTBALL_VERSION);

    g_Cvar_PrefDefault     = CreateConVar("sm_paintball_prefdefault", "1", 
        "Default setting for new users.");
    g_Cookie_Pref      = RegClientCookie("sm_paintball_pref", 
            "Paintball pref", CookieAccess_Private);

    RegConsoleCmd("paintball", MenuPaintball, "Show paintball settings menu.");

    HookEvent("bullet_impact",Event_BulletImpact);
}
    
public OnMapStart()
{
    static String:tmpPath[256];
    for(new i = 0 ; i < sizeof(PrimarySprites); i++)
    {
        gSpriteIndex[i] = PrecacheDecal(PrimarySprites[i], true);
        Format(tmpPath,sizeof(tmpPath),"materials/%s",PrimarySprites[i]);
        AddFileToDownloadsTable(tmpPath);
    }
    
    for(new i = 0; i < sizeof(SecondarySprites); i++)
    {
        PrecacheDecal(SecondarySprites[i], true);
        Format(tmpPath,sizeof(tmpPath),"materials/%s",SecondarySprites[i]);
        AddFileToDownloadsTable(tmpPath);
    }
    
}

public Action:Event_BulletImpact(Handle:event, const String:weaponName[], bool:dontBroadcast)
{
    static Float:pos[3];
    pos[0] = GetEventFloat(event,"x");
    pos[1] = GetEventFloat(event,"y");
    pos[2] = GetEventFloat(event,"z");

    if ( g_clientsPaintballEnabledTotal )
    {
        // Setup new decal
        TE_SetupWorldDecal(pos, gSpriteIndex[GetRandomInt(0,sizeof(PrimarySprites)-1)]);
        TE_Send(g_clientsPaintballEnabled, g_clientsPaintballEnabledTotal);
    }
}

TE_SetupWorldDecal(const Float:vecOrigin[3], index)
{    
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("m_nIndex",index);
}

public Action:MenuPaintball(client, args)
{
    new Handle:menu = CreateMenu(MenuHandlerPaintball);
    decl String:buffer[64];

    Format(buffer, sizeof(buffer), "%t", "Paintball settings");
    SetMenuTitle(menu, buffer);

    Format(buffer, sizeof(buffer), "%t %t", "Show paintball impacts", 
        g_clientPrefs[client] ? "Selected" : "NotSelected");
    AddMenuItem(menu, "Show paintball impacts", buffer);

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 20);
    return Plugin_Handled;
}

public MenuHandlerPaintball(Handle:menu, MenuAction:action, client, item)
{
    if(action == MenuAction_Select) 
    {
        if(item == 0)
        {
            g_clientPrefs[client] = g_clientPrefs[client] ? 0 : 1;
            decl String:buffer[5];
            IntToString(g_clientPrefs[client], buffer, 5);
            SetClientCookie(client, g_Cookie_Pref, buffer);
            recalculateClients();
            MenuPaintball(client, 0);
        }
    } 
    else if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public OnClientPutInServer(client)
{
    g_clientPrefs[client] = GetConVarInt(g_Cvar_PrefDefault);

    if(!IsFakeClient(client))
    {   
        if (AreClientCookiesCached(client))
        {
            loadClientCookies(client);
        } 
    }
}

public OnClientCookiesCached(client)
{
    if(IsClientInGame(client) && !IsFakeClient(client))
    {
        loadClientCookies(client);  
    }
}

loadClientCookies(client)
{
    decl String:buffer[5];
    GetClientCookie(client, g_Cookie_Pref, buffer, 5);
    if ( !StrEqual(buffer, "") )
    {
        g_clientPrefs[client] = StringToInt(buffer);
    }
    recalculateClients();
}

recalculateClients()
{
    g_clientsPaintballEnabledTotal = 0;
    for (new i=1; i<=MaxClients; i++)
    {
        if (IsClientInGame(i) && g_clientPrefs[i])
        {
            g_clientsPaintballEnabled[g_clientsPaintballEnabledTotal++] = i;
        }
    }
}

public OnClientDisconnect(client)
{
    CreateTimer(0.1, DelayedRecalculateClients);
}

public Action:DelayedRecalculateClients(Handle:timer, any:client)
{
    recalculateClients();
}
