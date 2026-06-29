#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Hostname",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351596"
};

ConVar C_hostname;

char Hostname_path[PLATFORM_MAX_PATH];

void load_and_set()
{
    File file = OpenFile(Hostname_path, "rt");
    if(file)
    {
        char line[2048];
        if(file.ReadLine(line, sizeof(line)))
        {
            TrimString(line);
            if(line[0] != '\0')
            {
                C_hostname.SetString(line);
            }
        }
        delete file;
    }
}

Action cmd_reload(int client, int args)
{
    load_and_set();
    return Plugin_Handled;
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
    BuildPath(Path_SM, Hostname_path, sizeof(Hostname_path), "data/hostname.txt");

    C_hostname = FindConVar("hostname");
    CreateConVar("hostname_version", PLUGIN_VERSION, "version of Hostname", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    load_and_set();

    RegAdminCmd("sm_hostname_reload", cmd_reload, ADMFLAG_ROOT, "reload hostname from file");
}
