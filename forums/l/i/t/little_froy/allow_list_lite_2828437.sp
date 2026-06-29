#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Allow List Lite Edition",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349281"
}

ConVar C_enable;
bool O_enable;

char Data_path[PLATFORM_MAX_PATH];

ArrayList Allowed_steamids;

GlobalForward Forward_OnPassed;
GlobalForward Forward_OnRefused;

void push_status(int client, bool passed, const char[] ip, const char[] auth)
{
    Call_StartForward(passed ? Forward_OnPassed : Forward_OnRefused);
    Call_PushCell(client);
    Call_PushString(ip);
    Call_PushString(auth);
    Call_Finish();
}

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
    if(!O_enable || IsFakeClient(client))
    {
        return;
    }
    char ip[64];
    GetClientIP(client, ip, sizeof(ip));
    if(Allowed_steamids.FindString(auth) == -1)
    {
        KickClient(client, "%T", "not_allow_kick", client);
        push_status(client, false, ip, auth);
    }
    else
    {
        push_status(client, true, ip, auth);
    }
}

Action cmd_reload(int client, int args)
{
    load_list();
    return Plugin_Handled;
}

Action cmd_list(int client, int args)
{
    if(Allowed_steamids.Length == 0)
    {
        ReplyToCommand(client, "empty");
    }
    else
    {
        ReplyToCommand(client, "count: %d", Allowed_steamids.Length);
        for(int i = 0; i < Allowed_steamids.Length; i++)
        {
            char line[MAX_AUTHID_LENGTH];
            Allowed_steamids.GetString(i, line, sizeof(line));
            ReplyToCommand(client, "%s", line);
        }
    }
    return Plugin_Handled;
}

void load_list()
{
    Allowed_steamids.Clear();
    File file = OpenFile(Data_path, "rt");
    if(file)
    {
        char line[2048];
        while(file.ReadLine(line, sizeof(line)))
        {
            PrintToServer("读取了:%s", line);
            int delimiter = get_string_comment_index(line);
            if(delimiter != -1)
            {
                line[delimiter] = '\0';
            }
            TrimString(line);
            if(line[0] != '\0')
            {
                Allowed_steamids.PushString(line);
            }
        }
        delete file;
    }
}

void get_all_cvars()
{
    O_enable = C_enable.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_enable)
    {
        O_enable = C_enable.BoolValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    Forward_OnPassed = new GlobalForward("AllowListLite_OnPassed", ET_Ignore, Param_Cell, Param_String, Param_String);
    Forward_OnRefused = new GlobalForward("AllowListLite_OnRefused", ET_Ignore, Param_Cell, Param_String, Param_String);
    RegPluginLibrary("allow_list_lite");
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("allow_list_lite.phrases");

    Allowed_steamids = new ArrayList(ByteCountToCells(MAX_AUTHID_LENGTH));

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/allow_list_lite_steamid.txt");

    C_enable = CreateConVar("allow_list_lite_enable", "1", "1 = enable the plugin, 0 = disable");
    C_enable.AddChangeHook(convar_changed);
    CreateConVar("allow_list_lite_version", PLUGIN_VERSION, "version of Allow List Lite Edition", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "allow_list_lite");
    get_all_cvars();
    load_list();

    RegAdminCmd("sm_allow_list_lite_reload", cmd_reload, ADMFLAG_ROOT, "reload steamid");
    RegAdminCmd("sm_allow_list_lite_list", cmd_list, ADMFLAG_ROOT, "show the list of allowed steamid");
}
