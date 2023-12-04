#define PLUGIN_VERSION	"1.1"
#define PLUGIN_NAME		"Connected Counter"
#define PLUGIN_PREFIX   "connected_counter"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
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
    if(!IsFakeClient(client))
    {
        int userid = GetClientUserId(client);
        if(Connected_userid.FindValue(userid) == -1)
        {
            Connected_userid.Push(userid);
            int userids[MAXPLAYERS];
            get_connected_userid(userids);
            Call_StartForward(Forward_OnConnected);
            Call_PushCell(userid);
            Call_PushCell(Connected_userid.Length);
            Call_PushArray(userids, MAXPLAYERS);
            Call_Finish();
        }
    }
}

void event_player_disconnect(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client == 0 || !IsFakeClient(client))
	{
        int index = Connected_userid.FindValue(userid);
        if(index != -1)
        {
            Connected_userid.Erase(index);
            int userids[MAXPLAYERS];
            get_connected_userid(userids);
            Call_StartForward(Forward_OnDisconnect);
            Call_PushCell(userid);
            Call_PushCell(Connected_userid.Length);
            Call_PushArray(userids, MAXPLAYERS);
            Call_Finish();
        }
	}
}

any native_ConnectedCounter_GetConnected(Handle plugin, int numParams)
{
    if(!Connected_userid)
    {
        ThrowNativeError(SP_ERROR_NOT_RUNNABLE, "called too early, the data has not been initialized yet");
    }
    int userids[MAXPLAYERS];
    get_connected_userid(userids);
    SetNativeCellRef(1, Connected_userid.Length);
    SetNativeArray(2, userids, MAXPLAYERS);
    return 0;
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    Forward_OnConnected = new GlobalForward("ConnectedCounter_OnConnected", ET_Ignore, Param_Cell, Param_Cell, Param_Array);
    Forward_OnDisconnect = new GlobalForward("ConnectedCounter_OnDisconnect", ET_Ignore, Param_Cell, Param_Cell, Param_Array);
    CreateNative("ConnectedCounter_GetConnected", native_ConnectedCounter_GetConnected);
    RegPluginLibrary(PLUGIN_PREFIX);
    return APLRes_Success;
}

public void OnPluginStart()
{
    Connected_userid = new ArrayList();

    HookEvent("player_disconnect", event_player_disconnect, EventHookMode_Pre);

    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
}