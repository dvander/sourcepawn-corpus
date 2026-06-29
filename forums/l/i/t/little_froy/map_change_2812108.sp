#define PLUGIN_VERSION	"1.10"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <l4d2_changelevel>
#include <little_froy_utils>

public Plugin myinfo =
{
	name = "Map Change",
	author = "Alex Dragokas, fdxx, sorallll, little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344329"
};

ConVar C_default;
ArrayList O_default;

StringMap End_and_next;

int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];

char Data_path[PLATFORM_MAX_PATH];

bool is_valid_map(const char[] map)
{
	char path[PLATFORM_MAX_PATH];
	return FindMap(map, path, sizeof(path)) == FindMap_Found;
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
		if(strcmp(key, "next") == 0)
		{
            End_and_next.SetString(Current_section_name, value);
		}
	}
    return SMCParse_Continue;
}

void check_config()
{
    End_and_next.Clear();
    Current_section_level = 0;
    Current_section_name[0] = '\0';
    SMCParser parser = new SMCParser();
    parser.OnEnterSection = OnEnterSection;
    parser.OnLeaveSection = OnLeaveSection;
    parser.OnKeyValue = OnKeyValue;
    parser.ParseFile(Data_path);
    delete parser;
}

Action OnStatsCrawlMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    char now[64];
    char next[64];
    GetCurrentMap(now, sizeof(now));
    if(End_and_next.GetString(now, next, sizeof(next)) && is_valid_map(next))
    {
        L4D2_ChangeLevel(next);
        return Plugin_Handled;
    }
    if(O_default.Length > 0)
    {
        O_default.GetString(GetRandomInt(0, O_default.Length - 1), next, sizeof(next));
        if(is_valid_map(next))
        {
            L4D2_ChangeLevel(next);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;    
}

Action cmd_reload(int client, int args)
{
    check_config();
    return Plugin_Handled;
}

void get_all_cvars()
{
    O_default.Clear();
    char buffer[2048];
    C_default.GetString(buffer, sizeof(buffer));
    if(buffer[0] != '\0')
    {
        explode_string_to_list(buffer, ",", O_default, 64, StringExplodeType_String);
    }
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_default)
    {
        O_default.Clear();
        char buffer[2048];
        C_default.GetString(buffer, sizeof(buffer));
        if(buffer[0] != '\0')
        {
            explode_string_to_list(buffer, ",", O_default, 64, StringExplodeType_String);
        }
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
    O_default = new ArrayList(ByteCountToCells(64));
    End_and_next = new StringMap();

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/map_change.cfg");

    C_default = CreateConVar("map_change_default", "c1m1_hotel,c2m1_highway,c3m1_plankcountry,c4m1_milltown_a,c5m1_waterfront,c6m1_riverbank,c7m1_docks,c8m1_apartment,c9m1_alleys,c10m1_caves,c11m1_greenhouse,c12m1_hilltop,c13m1_alpinecreek,c14m1_junkyard", "default map when no next map matched. split up with \",\"");
    C_default.AddChangeHook(convar_changed);
    CreateConVar("map_change_version", PLUGIN_VERSION, "version of Map Change", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "map_change");
	get_all_cvars();
    check_config();
    
    HookUserMessage(GetUserMessageId("StatsCrawlMsg"), OnStatsCrawlMsg, true);

    RegAdminCmd("sm_map_change_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");
}
