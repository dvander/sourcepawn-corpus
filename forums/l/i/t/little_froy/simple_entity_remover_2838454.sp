#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "Simple Entity Remover",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351332"
}

char Data_path[PLATFORM_MAX_PATH];

ArrayList Class_names;

public void OnEntityCreated(int entity, const char[] classname)
{
    if(entity < 1)
    {
        return;
    }
    if(Class_names.FindString(classname) != -1)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
    }
}

void OnSpawnPost(int entity)
{
    RequestFrame(frame_remove, EntIndexToEntRef(entity));
}

void frame_remove(int ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        RemoveEntity(entity);
    }
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

Action cmd_reload(int client, int args)
{
    load_list();
    return Plugin_Handled;
}

void load_list()
{
    Class_names.Clear();
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
                Class_names.PushString(line);
            }
        }
        delete file;
    }
}

public void OnPluginStart()
{
    Class_names = new ArrayList(ByteCountToCells(64));

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/simple_entity_remover.txt");

    CreateConVar("simple_entity_remover_version", PLUGIN_VERSION, "version of Simple Entity Remover", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    load_list();

    RegAdminCmd("sm_simple_entity_remover_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");
}