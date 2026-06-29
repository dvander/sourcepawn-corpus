#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <little_froy_utils_colors>

public Plugin myinfo =
{
	name = "Block Vote Kick",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351514"
}

ConVar C_print;
bool O_print;

char Data_path[PLATFORM_MAX_PATH];

ArrayList Bypass_steamids;

bool Bypassed[MAXPLAYERS+1];
char Steamids[MAXPLAYERS+1][MAX_AUTHID_LENGTH];

int get_string_comment_index(const char[] str)
{
    int len = strlen(str);
    bool ignoring = false;
    for(int i = 0; i < len; i++)
    {
        if(ignoring)
        {
            if(str[i] == '"')
            {
                ignoring = false;
            }
        }
        else
        {
            if(str[i] == '"')
            {
                ignoring = true;
            }
            else if(str[i] == '/' && i != len - 1 && str[i + 1] == '/')
            {
                return i;
            }
        }
    }
    return -1;
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if(IsFakeClient(client))
    {
        return;
    }
    strcopy(Steamids[client], sizeof(Steamids[]), auth);
    if(Bypass_steamids.FindString(auth) != -1)
    {
        Bypassed[client] = true;
    }
}

public void OnClientDisconnect_Post(int client)
{
    Bypassed[client] = false;
    Steamids[client][0] = '\0';
}

void print_block_msg(int client, const char[] phrases)
{
    if(O_print && client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
    {
        colors_print_to_chat(client, "%T", phrases, client);
    }
}

Action on_cmd_callvote(int client, const char[] command, int argc)
{
    if(argc < 2)
    {
        return Plugin_Continue;
    }
    char arg1[64];
    GetCmdArg(1, arg1, sizeof(arg1));
    if(strcmp(arg1, "kick", false) != 0)
    {
        return Plugin_Continue;
    }
    int target = GetClientOfUserId(GetCmdArgInt(2));
    if(target > 0 && !IsFakeClient(target))
    {
        if(Steamids[target][0] == '\0')
        {
            print_block_msg(client, "block_vote_kick_unauthorized");
            return Plugin_Handled;
        }
        else if(Bypassed[target])
        {
            print_block_msg(client, "block_vote_kick_blocked");
            return Plugin_Handled;    
        }
    }
    return Plugin_Continue;
}

Action cmd_reload(int client, int args)
{
    load_list();
    check_all();
    return Plugin_Handled;
}

void check_all()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(Steamids[i][0] != '\0' && Bypass_steamids.FindString(Steamids[i]) != -1)
        {
            Bypassed[i] = true;
        }
    }
}

void load_list()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        Bypassed[i] = false;
    }
    Bypass_steamids.Clear();
    File file = OpenFile(Data_path, "rt");
    if(file)
    {
        char line[2048];
        while(file.ReadLine(line, sizeof(line)))
        {
            int delimiter = get_string_comment_index(line);
            if(delimiter != -1)
            {
                line[delimiter] = '\0';
            }
            TrimString(line);
            if(line[0] != '\0')
            {
                Bypass_steamids.PushString(line);
            }
        }
        delete file;
    }
}

void get_all_cvars()
{
    O_print = C_print.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_print)
    {
        O_print = C_print.BoolValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
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
    AddCommandListener(on_cmd_callvote, "callvote");

    LoadTranslations("block_vote_kick.phrases");

    Bypass_steamids = new ArrayList(ByteCountToCells(MAX_AUTHID_LENGTH));

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/block_vote_kick_steamid.txt");

    C_print = CreateConVar("block_vote_kick_print", "1 = enable, 0 = disable. print msg when vote blocked?");
    C_print.AddChangeHook(convar_changed);
    CreateConVar("block_vote_kick_version", PLUGIN_VERSION, "version of Block Vote Kick", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "block_vote_kick");
    get_all_cvars();
    load_list();

    RegAdminCmd("sm_block_vote_kick_reload", cmd_reload, ADMFLAG_ROOT, "reload bypass steamid");

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientConnected(client) && !IsFakeClient(client) && IsClientAuthorized(client))
        {
            char auth[MAX_AUTHID_LENGTH];
            if(GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)))
            {
                strcopy(Steamids[client], sizeof(Steamids[]), auth);
                if(Bypass_steamids.FindString(auth) != -1)
                {
                    Bypassed[client] = true;
                }
            }
        }
    }
}
