#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

#define NAME "Sourcerev.com"
#define URL "https://sourcerev.com"
#define AD_URL "https://sourcerev.com/ads/?serverId="
#define DEATHTIME %deathtime%
#define ENFORCEMENT %enforcement%
#define SERVERID %serverId%

%hidden%

#define HIDDEN_INTERVAL %hiddenInterval% // 300.0 = 5 minutes

#include <sourcemod>

EngineVersion engine;

float g_timerRemainingTime[MAXPLAYERS + 1];
int g_prefTime[MAXPLAYERS + 1];
bool g_hasJoinTeam[MAXPLAYERS + 1];

char g_adUrl[256];


public Plugin:myinfo = 
{
    name = NAME, 
    author = "Sourcerev.com",
    description = "", 
    version = PLUGIN_VERSION, 
    url = URL
};

public void OnPluginStart() {
    if (engine == Engine_TF2 || engine == Engine_DODS)
        HookEvent("player_changeclass", Event_PlayerClassOrTeamJoin, EventHookMode_Post);
    else
        HookEvent("player_team", Event_PlayerClassOrTeamJoin, EventHookMode_Post);
        
    #if DEATHTIME > 0
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    #endif
    
    FormatEx(g_adUrl, sizeof(g_adUrl), "%s%d", AD_URL, SERVERID);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    engine = GetEngineVersion();
}

public void OnClientConnected(int client)
{
    SetDeathTime(client);
    g_timerRemainingTime[client] = 0.0;
    g_hasJoinTeam[client] = false;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);
    
    if (0 == client || IsFakeClient(client))
        return;

    if(GetTime() <= g_prefTime[client])
        return;
        
    StartMotdProcess(client, userId);
}

public void Event_PlayerClassOrTeamJoin(Event event, const char[] name, bool dontBroadcast)
{
    int userId = event.GetInt("userid");
    int client = GetClientOfUserId(userId);
    
    if (0 == client || IsFakeClient(client) || g_hasJoinTeam[client])
        return;
        
    g_hasJoinTeam[client] = true;
    StartMotdProcess(client, userId);
}

public Action Timer_ProcessMotd(Handle timer, DataPack data) {
    data.Reset();
    int userId = data.ReadCell();
    int client = GetClientOfUserId(userId);
    
    if (0 == client || IsFakeClient(client)) {
        SetDeathTime(client);
        return Plugin_Stop;
    }
    
    PrintCenterText(client, "Remaining Time %d", RoundToCeil(g_timerRemainingTime[client]));
    OpenMotd(client, false);
    
    g_timerRemainingTime[client] -= 0.25;
    if (0 > g_timerRemainingTime[client]) {
        delete data;
        SetDeathTime(client);
		PrintCenterText(client, "Thank you !");
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

void StartMotdProcess(int client, int userId) {
    DataPack data = new DataPack();
    data.WriteCell(userId);
    
    SetEnforcement(client);
    
    OpenMotd(client);
    CreateTimer(0.25, Timer_ProcessMotd, data, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void SetEnforcement(int client) {
    g_timerRemainingTime[client] = ENFORCEMENT;
}

void SetDeathTime(int client) {
    g_prefTime[client] = GetTime() + DEATHTIME;
}

void OpenMotd(int client, bool load = true) {
    Handle kv = CreateKeyValues("data");
    KvSetNum(kv, "cmd", 5);
    KvSetNum(kv, "customsvr", 1);
    KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
    KvSetString(kv, "title", "Info");
    KvSetString(kv, "msg", load ? g_adUrl : "http://");
    ShowVGUIPanelEx(client, "info", kv, true, USERMSG_BLOCKHOOKS|USERMSG_RELIABLE);
    CloseHandle(kv);
}

ShowVGUIPanelEx(client, const String:name[], Handle:kv=INVALID_HANDLE, bool:show=true, usermessageFlags=0)
{
    new Handle:msg = StartMessageOne("VGUIMenu", client, usermessageFlags);
    
    if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
    {
        PbSetString(msg, "name", name);
        PbSetBool(msg, "show", true);
        
        if (kv != INVALID_HANDLE && KvGotoFirstSubKey(kv, false))
        {
            new Handle:subkey;
            
            do
            {
                decl String:key[128], String:value[128];
                KvGetSectionName(kv, key, sizeof(key));
                KvGetString(kv, NULL_STRING, value, sizeof(value), "");
                
                subkey = PbAddMessage(msg, "subkeys");
                PbSetString(subkey, "name", key);
                PbSetString(subkey, "str", value);
                
            } while (KvGotoNextKey(kv, false));
        }
    }
    else //BitBuffer
    {
        BfWriteString(msg, name);
        BfWriteByte(msg, show);
        
        if (kv == INVALID_HANDLE)
        {
            BfWriteByte(msg, 0);
        }
        else
        {
            if (!KvGotoFirstSubKey(kv, false))
            {
                BfWriteByte(msg, 0);
            }
            else
            {
                new keyCount = 0;
                do
                {
                    ++keyCount;
                } while (KvGotoNextKey(kv, false));
                
                BfWriteByte(msg, keyCount);
                
                if (keyCount > 0)
                {
                    KvGoBack(kv);
                    KvGotoFirstSubKey(kv, false);
                    do
                    {
                        decl String:key[128], String:value[128];
                        KvGetSectionName(kv, key, sizeof(key));
                        KvGetString(kv, NULL_STRING, value, sizeof(value), "");
                        
                        BfWriteString(msg, key);
                        BfWriteString(msg, value);
                    } while (KvGotoNextKey(kv, false));
                }
            }
        }
    }
    
    EndMessage();
}