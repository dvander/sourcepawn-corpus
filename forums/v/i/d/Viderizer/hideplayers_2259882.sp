#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>

public Plugin:myinfo =
{
    name = "hide players",
    author = "exvel, viderizer",
    description = "adds a /hide command to hide players",
    version = "0.2",
    url = ""
};

bool g_bHide[MAXPLAYERS + 1] = {false, ...};
Handle g_hHideOnlyTeam = null;
Handle g_hClientCookie = null;

public void OnPluginStart()
{
    RegConsoleCmd("sm_hide", command_hide);

    g_hHideOnlyTeam = CreateConVar("sm_hide_onlyteam", "1", "Whether /hide hides everyone or only the player's team", FCVAR_NOTIFY);
    g_hClientCookie = RegClientCookie("sm_hide_enable", "enable hiding players", CookieAccess_Public);

    AutoExecConfig(true, "hideplayers");
    LoadTranslations("hideplayers.phrases");

    // players have connected before the plugin has been loaded, late load
    for (int i = 1; i < MaxClients; i++) {
        if (IsClientConnected(i) && IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }
}

public Action command_hide(int client, int argc)
{
    char translation[128];

    if (g_bHide[client]) {
        g_bHide[client] = false;
        Format(translation, sizeof translation, "%t", "showPlayers", "/hide");
        ReplyToCommand(client, replaceColors(translation));
    } else {
        g_bHide[client] = true;
        Format(translation, sizeof translation, "%t", "hidePlayers", "/hide");
        ReplyToCommand(client, replaceColors(translation));
    }

    if (AreClientCookiesCached(client)) {
        if (g_bHide[client])
            SetClientCookie(client, g_hClientCookie, "true");
        else
            SetClientCookie(client, g_hClientCookie, "false");
    }
}

char replaceColors(char str[128])
{
    char colorText[][] = {"{c:01}", "{c:02}", "{c:03}", "{c:04}", "{c:05}", "{c:06}", "{c:07}", "{c:08}", "{c:09}", "{c:0a}", "{c:0b}", "{c:0c}", "{c:0d}", "{c:0e}", "{c:0f}"};
    char colorCode[][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0a", "\x0b", "\x0c", "\x0d", "\x0e", "\x0f"};

    for (int i = 0; i <= sizeof colorText[]; i++) {
        ReplaceString(str, sizeof str, colorText[i], colorCode[i]);
    }

    return str;
}

public OnClientPutInServer(int client)
{
    g_bHide[client] = false;
    SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
    CreateTimer(5.0, checkCookies, client);
}

public Action checkCookies(Handle timer, int client) {
    if (AreClientCookiesCached(client)) {
        char cookieBuffer[8];
        GetClientCookie(client, g_hClientCookie, cookieBuffer, sizeof cookieBuffer);
        if (strcmp(cookieBuffer, "false", false) == 0)
            g_bHide[client] = false;
        else if (strcmp(cookieBuffer, "true", false) == 0)
            g_bHide[client] = true;
    }
}

public Action Hook_SetTransmit(int entity, int client)
{
    if (client != entity && (0 < entity <= MaxClients) && g_bHide[client] && IsPlayerAlive(client)) {
        if (GetConVarInt(g_hHideOnlyTeam) > 0) {
            if (GetClientTeam(client) == GetClientTeam(entity))
                return Plugin_Handled;
            else
                return Plugin_Continue;
        } else
            return Plugin_Handled;
    }

    return Plugin_Continue;
}
