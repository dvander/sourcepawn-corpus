#define PLUGIN_VERSION	"1.4"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <little_froy_utils_colors>

#define LITTLE_FROY_INTEGER_MAX 0x7FFFFFFF

public Plugin myinfo =
{
	name = "Block Name Change",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351553"
};

ConVar C_kick_times;
int O_kick_times;

int G_name_back_id = -1;
int Name_back_id[MAXPLAYERS+1] = {-1, ...};
int Try_to_change_times[MAXPLAYERS+1];

public void OnClientDisconnect_Post(int client)
{
    Name_back_id[client] = -1;
    Try_to_change_times[client] = 0;
}

void frame_name_back(DataPack dp)
{
    dp.Reset();
    char oldname[MAX_NAME_LENGTH];
    int id = dp.ReadCell();
    dp.ReadString(oldname, sizeof(oldname));
    delete dp;
    for(int client = 1; client <= MaxClients; client++)
    {
        if(Name_back_id[client] == id)
        {
            if(IsClientInGame(client) && !IsFakeClient(client))
            {
                SetClientName(client, oldname);
            }
            Name_back_id[client] = -1;
        }
    }
}

void event_player_changename(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client == 0 || Name_back_id[client] != -1 || IsFakeClient(client) || !IsClientInGame(client))
    {
		return;
    }
    Try_to_change_times[client]++;
    if(O_kick_times > 0)
    {
        if(Try_to_change_times[client] >= O_kick_times)
        {
            KickClient(client, "%T", "try_to_change_kick", client);
            return;
        }
        else
        {
            int left = O_kick_times - Try_to_change_times[client];
            colors_print_to_chat(client, "%T", "try_to_change_times_left", client, left);
            colors_strip_print_to_console(client, "%T", "try_to_change_times_left", client, left);
        }
    }
    else
    {
        colors_print_to_chat(client, "%T", "try_to_change_unlimited", client);
        colors_strip_print_to_console(client, "%T", "try_to_change_unlimited", client);  
    }
    G_name_back_id++;
    if(G_name_back_id == LITTLE_FROY_INTEGER_MAX)
    {
        G_name_back_id = 0;
    }
    Name_back_id[client] = G_name_back_id;
    char oldname[MAX_NAME_LENGTH];
    event.GetString("oldname", oldname, sizeof(oldname));
    DataPack dp = new DataPack();
    dp.WriteCell(G_name_back_id);
    dp.WriteString(oldname);
    RequestFrame(frame_name_back, dp);
}

void get_all_cvars()
{
    O_kick_times = C_kick_times.IntValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_kick_times)
    {
        O_kick_times = C_kick_times.IntValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

Action OnSayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    char buffer[128];
	msg.ReadString(buffer, sizeof(buffer));
	msg.ReadString(buffer, sizeof(buffer));
	if(strcmp(buffer, "#Cstrike_Name_Change") == 0)
    {
		return Plugin_Handled;
    }
	return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("block_name_change.phrases");

    HookUserMessage(GetUserMessageId("SayText2"), OnSayText2, true);

    HookEvent("player_changename", event_player_changename);

    C_kick_times = CreateConVar("block_name_change_kick_times", "3", "try to change name times reaches this value, kick the client. 0 or lower = warn only");
    C_kick_times.AddChangeHook(convar_changed);
    CreateConVar("block_name_change_version", PLUGIN_VERSION, "version of Block Name Change", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "block_name_change");
    get_all_cvars();
}
