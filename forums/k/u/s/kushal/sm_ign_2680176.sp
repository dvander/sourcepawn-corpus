#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION		"1.0.2"

char clienthasadmin[1024];
char enteringoldname[1024];
char oldname[1024];

public Plugin myinfo = 
{
    name        = "[CS:S] IGN",
    author      = "kushal",
    description = "Shows Steamid , Oldest Name IP and Admin Status to Admins",
    version     = PLUGIN_VERSION,
    url         = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_ign", cmd_ign,ADMFLAG_GENERIC);
}

public void OnClientAuthorized(int client)
{
    char clientnameconnected[512];
    char clientid[512];
    char tempoldname[512];
    GetClientName(client, clientnameconnected, sizeof(clientnameconnected));
    GetClientAuthId(client, AuthId_Engine, clientid, sizeof(clientid));
    KeyValues kv = new KeyValues("ign"); 
    char sPath[PLATFORM_MAX_PATH]; 

    BuildPath(Path_SM, sPath, sizeof(sPath), "data/ign.txt"); 
    kv.ImportFromFile(sPath); 
    kv.GoBack();
    kv.JumpToKey(clientid, true);
    kv.GetString(clientid, tempoldname, sizeof(oldname), "no");
    kv.GoBack();
    delete kv;
    Format(oldname, sizeof(oldname), tempoldname);
    if (strlen(oldname) == 2)
    {
        Handle KV_Save = CreateKeyValues("ign");
        FileToKeyValues(KV_Save, "addons/sourcemod/data/ign.txt");
        KvJumpToKey(KV_Save, clientid, true);
        KvSetString(KV_Save, clientid, clientnameconnected);
        KvRewind(KV_Save);
        KeyValuesToFile(KV_Save, "addons/sourcemod/data/ign.txt"); 
        KvGoBack(KV_Save);
        KvJumpToKey(KV_Save, clientid, true);
        KvGetString(KV_Save, clientid, tempoldname, sizeof(oldname));
        CloseHandle(KV_Save); 
        Format(oldname, sizeof(oldname), tempoldname);
    }
    //Get Oldest Name
    KeyValues kvjoin = new KeyValues("ign"); 
    BuildPath(Path_SM, sPath, sizeof(sPath), "data/ign.txt"); 
    kvjoin.ImportFromFile(sPath); 
    kvjoin.GoBack();
    kvjoin.JumpToKey(clientid, true);
    kvjoin.GetString(clientid, tempoldname, sizeof(oldname), "no");
    kvjoin.GoBack();
    delete kvjoin;
    Format(enteringoldname, sizeof(enteringoldname), tempoldname);
    CPrintToChatAll("\x02[{lime}SM\x02] {magenta}Client {lime}%s {magenta}connected to the server. Oldest name : \x03%s", clientnameconnected, enteringoldname);
    PrintToServer("[IGN] Client %s connected. Old Name: %s", clientnameconnected, enteringoldname);
}

public Action cmd_ign(int client, int args)
{
    if (args < 1)
    {
        CPrintToChat(client, "{lime}[{orange}IGN{lime}] {indigo}Invalid Usage .Type {cyan}!ign <playername>");
    }
    if (args == 1)
    {
        //Initial Action
        char TargetString[100]; 
        GetCmdArg(1, TargetString, 100); 
        int[] Clients = new int[MaxClients]; 
        char TargetName[100];
        bool tn_is_ml; 
        int ValidClients = ProcessTargetString(TargetString, client, Clients, MaxClients, COMMAND_FILTER_NO_IMMUNITY, TargetName, sizeof(TargetName), tn_is_ml);
        int PlayerClient; 
        char ClientName[100]; 
        for (int i = 0; i < ValidClients; i++) 
        { 
            PlayerClient = Clients[i];
            GetClientName(PlayerClient, ClientName, sizeof(ClientName));
        }
        char steamid[256];
        char ip[256];
        Format(clienthasadmin, sizeof(clienthasadmin), "No.");
        if (GetUserFlagBits(PlayerClient) != 0)
        {
            Format(clienthasadmin, sizeof(clienthasadmin), "Yes.");
        }
        char clientidtarget[512];
        char tempoldname[512];
        GetClientAuthId(PlayerClient, AuthId_Engine, clientidtarget, sizeof(clientidtarget));

        //Get Oldest Name
        KeyValues kv = new KeyValues("ign"); 
        char sPath[PLATFORM_MAX_PATH]; 
        BuildPath(Path_SM, sPath, sizeof(sPath), "data/ign.txt"); 

        kv.ImportFromFile(sPath); 
        kv.GoBack();
        kv.JumpToKey(clientidtarget, true);
        kv.GetString(clientidtarget, tempoldname, sizeof(oldname), "no");
        kv.GoBack();
        delete kv;
        Format(oldname, sizeof(oldname), tempoldname);

        GetClientAuthId(PlayerClient, AuthId_Engine, steamid, sizeof(steamid));
        GetClientIP(PlayerClient, ip, sizeof(ip));
        CPrintToChat(client, "{darkred}**********************************");
        CPrintToChat(client, "{lime}\x09Player Name:{black} %s", ClientName);
        CPrintToChat(client, "{lime}\x09Oldest Name:{maroon} %s", oldname);
        CPrintToChat(client, "{lime}\x09SteamID:{hotpink} %s", steamid);
        CPrintToChat(client, "{lime}\x09IP:{black} %s\n{lime}\x09\x09Adminship:{black} %s", ip, clienthasadmin);
        CPrintToChat(client, "{darkblue}*********************************");
    }
    if (args > 1)
    {
        CPrintToChat(client, "{black}[{lime}SM{black}]{lime}Invalid Usage.");
    }
} 