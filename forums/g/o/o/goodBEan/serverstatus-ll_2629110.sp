#include <sourcemod>

int g_iBootTime;

#define PLUGIN_VERSION          "1.1.1"
#define PLUGIN_NAME             "Server Status-LL MOD"
#define PLUGIN_AUTHOR           "Maxximou5,goodBEan"
#define PLUGIN_DESCRIPTION      "Announces important information regarding the server when a client connects."
#define PLUGIN_URL              "http://maxximou5.com/"

public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}

public void OnPluginStart()
{
    g_iBootTime = GetTime();
}

public void OnMapStart()
{
    CreateTimer(1.0, Timer_ServerStatus);
	PrintToServer("[SM/MM IS FULLY LOADED]");	
}

public Action Timer_ServerStatus(Handle timer)
{
    PrintToServer("===============================================================");
    PrintToServer("======================BEGIN SERVER STATUS======================");
    PrintToServer("===============================================================");
    char server_ip[32];
    char server_name[256];
    char server_date[20];
    int server_port;
    FormatTime(server_date, sizeof(server_date), "%m/%d/%Y");
    GetServerIPAddress(server_ip, sizeof(server_ip));
    server_port = GetServerPort();
    GetConVarString(FindConVar("hostname"), server_name, sizeof(server_name));
    PrintToServer("    HOSTNAME: %s", server_name);
    PrintToServer("    SERVER DATE: %s", server_date);
    ServerUptime()
    PrintToServer("    IP ADDRESS: %s:%i", server_ip, server_port);
    PrintToServer("---------------------------------------------------------------");
	PrintToServer("[SM/MM Information]");
	PrintToServer("---------------------------------------------------------------");
    ServerCommand("sm version");
    ServerCommand("meta version");
    ServerCommand("sm plugins list");
    CreateTimer(1.0, Timer_EndStatus);
}

public Action Timer_EndStatus(Handle timer)
{
    PrintToServer("===============================================================");
    PrintToServer("=======================END SERVER STATUS=======================");
    PrintToServer("===============================================================");
}

ServerUptime()
{
    //Credit to Dr. McKay
    int diff = GetTime() - g_iBootTime;
    int days = diff / 86400;
    diff %= 86400;
    int hours = diff / 3600;
    diff %= 3600;
    int mins = diff / 60;
    diff %= 60;
    int secs = diff;
    PrintToServer("    SERVER UPTIME: %i days, %i hours, %i mins, %i secs", days, hours, mins, secs);
}

void GetServerIPAddress(char[] buffer, int length)
{
    ConVar hostip = FindConVar("hostip");
    int longip = hostip.IntValue;
    delete hostip;

    int pieces[4];
    pieces[0] = (longip >> 24) & 0x000000FF;
    pieces[1] = (longip >> 16) & 0x000000FF;
    pieces[2] = (longip >> 8) & 0x000000FF;
    pieces[3] = longip & 0x000000FF;

    Format(buffer, length, "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
}

int GetServerPort()
{
    ConVar cvar = FindConVar("hostport");
    int port = cvar.IntValue;
    delete cvar;
    return port;
}