#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "Multiple Supply",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351353"
};

char Data_path[PLATFORM_MAX_PATH];

StringMap Supply_count;
int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];

void frame_count(int ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity == -1)
    {
        return;
    }
    if(GetEntProp(entity, Prop_Data, "m_spawnflags") & (1 << 3))
    {
        return;
    }
    char class_name[64];
    int count = 0;
    GetEntityClassname(entity, class_name, sizeof(class_name));
    if(!Supply_count.GetValue(class_name, count))
    {
        return;
    }
    int pre_count = GetEntProp(entity, Prop_Data, "m_itemCount");
    if(pre_count > 0 && pre_count < count)
    {
        SetEntProp(entity, Prop_Data, "m_itemCount", count);
    }
}

void OnSpawnPost(int entity)
{
    RequestFrame(frame_count, EntIndexToEntRef(entity));
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(entity < 1)
    {
        return;
    }
    if(!HasEntProp(entity, Prop_Data, "m_itemCount"))
    {
        return;
    }
	if(Supply_count.ContainsKey(classname))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
	}
}

SMCResult OnEnterSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	Current_section_level++;
	if(Current_section_level == 2)
	{
        strcopy(Current_section_name, sizeof(Current_section_name), name);
	}
    return SMCParse_Continue;
}

SMCResult OnLeaveSection(SMCParser smc)
{
    Current_section_level--;
    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if(Current_section_level == 2)
	{
        if(strcmp(key, "count") == 0)
        {
            int the_value = StringToInt(value);
            if(the_value > 0)
            {
                Supply_count.SetValue(Current_section_name, the_value);
            }
        }
	}
    return SMCParse_Continue;
}

void check_configs()
{
    Supply_count.Clear();
    Current_section_level = 0;
    Current_section_name[0] = '\0';
    SMCParser parser = new SMCParser();
    parser.OnEnterSection = OnEnterSection;
    parser.OnLeaveSection = OnLeaveSection;
    parser.OnKeyValue = OnKeyValue;
    parser.ParseFile(Data_path);
    delete parser;
}

Action cmd_reload(int client, int args)
{
    check_configs();
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
    Supply_count = new StringMap();

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/multiple_supply.cfg");

    CreateConVar("multiple_supply_version", PLUGIN_VERSION, "version of Multiple Supply", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    check_configs();

    RegAdminCmd("sm_multiple_supply_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");
}
