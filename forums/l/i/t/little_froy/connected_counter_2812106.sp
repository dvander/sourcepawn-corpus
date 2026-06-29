#define PLUGIN_VERSION	"2.5"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Connected Counter",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344327"
};

GlobalForward Forward_OnConnected;
GlobalForward Forward_OnDisconnect;

ArrayList Connected_userid;

void get_connected_userid(int userids[MAXPLAYERS])
{
    for(int i = 0; i < Connected_userid.Length; i++)
    {
        userids[i] = Connected_userid.Get(i);
    }
}

public void OnClientConnected(int client)
{
    if(IsFakeClient(client))
    {
        return;
    }
    int userid = GetClientUserId(client);
    if(Connected_userid.FindValue(userid) == -1)
    {
        Connected_userid.Push(userid);
        
        int userids[MAXPLAYERS];
        get_connected_userid(userids);

        Call_StartForward(Forward_OnConnected);
        Call_PushCell(userid);
        Call_PushCell(Connected_userid.Length);
        Call_PushArray(userids, sizeof(userids));
        Call_Finish();
    }
}

void event_player_disconnect(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int index = Connected_userid.FindValue(userid);
    if(index != -1)
    {
        Connected_userid.Erase(index);

        int userids[MAXPLAYERS];
        char reason[256];
        char player_name[MAX_NAME_LENGTH];
        char networkid[MAX_AUTHID_LENGTH];
        get_connected_userid(userids);
        event.GetString("reason", reason, sizeof(reason));
        event.GetString("name", player_name, sizeof(player_name));
        event.GetString("networkid", networkid, sizeof(networkid));

        Call_StartForward(Forward_OnDisconnect);
        Call_PushCell(userid);
        Call_PushCell(Connected_userid.Length);
        Call_PushArray(userids, sizeof(userids));
        Call_PushString(reason);
        Call_PushString(player_name);
        Call_PushString(networkid);
        Call_Finish();
    }
}

any native_ConnectedCounter_GetConnected(Handle plugin, int numParams)
{
    int userids[MAXPLAYERS];
    get_connected_userid(userids);
    SetNativeCellRef(1, Connected_userid.Length);
    SetNativeArray(2, userids, sizeof(userids));
    return 0;
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    Connected_userid = new ArrayList();
    Forward_OnConnected = new GlobalForward("ConnectedCounter_OnConnected", ET_Ignore, Param_Cell, Param_Cell, Param_Array);
    Forward_OnDisconnect = new GlobalForward("ConnectedCounter_OnDisconnect", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_String, Param_String, Param_String);
    CreateNative("ConnectedCounter_GetConnected", native_ConnectedCounter_GetConnected);
    RegPluginLibrary("connected_counter");
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("player_disconnect", event_player_disconnect, EventHookMode_Pre);

    CreateConVar("connected_counter_version", PLUGIN_VERSION, "version of Connected Counter", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
