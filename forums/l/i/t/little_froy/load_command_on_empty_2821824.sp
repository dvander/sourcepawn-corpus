#define PLUGIN_VERSION	"1.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <connected_counter>

#define LITTLE_FROY_INTEGER_MAX	0x7FFFFFFF

public Plugin myinfo =
{
	name = "Load Command On Empty",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=347490"
};

char Data_path[PLATFORM_MAX_PATH];

int G_exit_id = -1;
int Exit_id_current = -1;

void load_commands()
{    
    File file = OpenFile(Data_path, "rt");
    if(file)
    {
        char line[2048];
        while(file.ReadLine(line, sizeof(line)))
        {
            TrimString(line);
            if(line[0] != '\0')
            {
                ServerCommand("%s", line);
                ServerExecute();
            }
        }
        delete file;
    }  
}

public void ConnectedCounter_OnDisconnect(int userid, int count, const int userids[MAXPLAYERS], const char[] reason, const char[] name, const char[] networkid)
{
    if(Exit_id_current != -1)
    {
        return;
    }
    if(count == 0)
    {
        load_commands();
    }
}

void frame_exit(int id)
{
    if(id == Exit_id_current)
    {
        Exit_id_current = -1;
    }
}

Action on_cmd_exit(int client, const char[] command, int argc)
{
    G_exit_id++;
    if(G_exit_id == LITTLE_FROY_INTEGER_MAX)
    {
        G_exit_id = 0;
    }
    Exit_id_current = G_exit_id;
    RequestFrame(frame_exit, G_exit_id);
    return Plugin_Continue;
}

public void OnPluginStart()
{
    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/load_command_on_empty.txt");

    CreateConVar("load_command_on_empty_version", PLUGIN_VERSION, "version of Load Command On Empty", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    AddCommandListener(on_cmd_exit, "exit");
    AddCommandListener(on_cmd_exit, "quit");
}
