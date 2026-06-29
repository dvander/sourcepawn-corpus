#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Force Director Script KeyValues",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349152"
};

char Data_path[PLATFORM_MAX_PATH];

StringMap Keyvalues_int;
StringMap Keyvalues_float;
StringMap Keyvalues_string;

int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];
char Current_type[32];
char Current_value[PLATFORM_MAX_PATH];

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
    int value = 0;
    if(Keyvalues_int.GetValue(key, value))
    {
        retVal = value;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D_OnGetScriptValueFloat(const char[] key, float &retVal)
{
    float value = 0.0;
    if(Keyvalues_float.GetValue(key, value))
    {
        retVal = value;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D_OnGetScriptValueString(const char[] key, const char[] defaultVal, char retVal[128])
{
    char value[128];
    if(Keyvalues_string.GetString(key, value, sizeof(value)))
    {
        strcopy(retVal, sizeof(retVal), value);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void reset_pre_load_data()
{
    Current_type[0] = '\0';
    Current_value[0] = '\0';
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
    if(Current_section_level == 1)
    {
        if(strcmp(Current_type, "int") == 0)
        {
            Keyvalues_int.SetValue(Current_section_name, StringToInt(Current_value));
        }
        else if(strcmp(Current_type, "float") == 0)
        {
            Keyvalues_float.SetValue(Current_section_name, StringToFloat(Current_value));
        }
        else if(strcmp(Current_type, "string") == 0)
        {
            Keyvalues_string.SetString(Current_section_name, Current_value);
        }
        reset_pre_load_data();
    }
    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if(Current_section_level == 2)
	{
        if(strcmp(key, "type") == 0)
        {
            strcopy(Current_type, sizeof(Current_type), value);
        }
        else if(strcmp(key, "value") == 0)
        {
            strcopy(Current_value, sizeof(Current_value), value);
        }
	}
    return SMCParse_Continue;
}

void check_configs()
{
    Keyvalues_int.Clear();
    Keyvalues_float.Clear();
    Keyvalues_string.Clear();
    reset_pre_load_data();
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
    Keyvalues_int = new StringMap();
    Keyvalues_float = new StringMap();
    Keyvalues_string = new StringMap();

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/force_director_script_keyvalues.cfg");

	CreateConVar("force_director_script_keyvalues_version", PLUGIN_VERSION, "version of Force Director Script KeyValues", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    check_configs();

    RegAdminCmd("sm_force_director_script_keyvalues_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");
}
