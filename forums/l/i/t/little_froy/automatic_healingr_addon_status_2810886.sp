#define PLUGIN_VERSION	"1.5"
#define PLUGIN_NAME		"Automatic Healing R Addon Interrupt Healing On Status"
#define PLUGIN_PREFIX	"automatic_healingr_addon_status"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <automatic_healingr>

#define INTERRUPT_STAGGERED				(1 << 0)
#define INTERRUPT_PINNED				(1 << 1)
#define INTERRUPT_FALLING_FROM_LEDGE	(1 << 2)
#define INTERRUPT_CUSTOM_SEQUENCE       (1 << 3)
#define INTERRUPT_GETTING_UP_FROM_DEFIB (1 << 4)

#define QueuedPummel_Attacker	8

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344086"
};

ConVar C_enable;
int O_enable;

StringMap Custom_sequences;

char Data_path[PLATFORM_MAX_PATH];

int Offset_QueuedPummelVictim;

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

int get_special_infected_attacker(int client)
{
    int attacker = -1;
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
    attacker = GetEntDataEnt2(client, Offset_QueuedPummelVictim + QueuedPummel_Attacker);
    if(attacker > 0)
    {
        return attacker;
    }
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	return -1;
}

bool is_get_staggered(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0;
}

bool is_survivor_falling(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isFallingFromLedge");
}

bool should_restart_healing(int client)
{
    if(O_enable & INTERRUPT_STAGGERED && is_get_staggered(client))
    {
        return true;
    }
    if(O_enable & INTERRUPT_PINNED && get_special_infected_attacker(client) != -1)
    {
        return true;
    }
    if(O_enable & INTERRUPT_FALLING_FROM_LEDGE && is_survivor_falling(client))
    {
        return true;
    }
    if(O_enable & INTERRUPT_GETTING_UP_FROM_DEFIB && GetEntProp(client, Prop_Send, "m_iCurrentUseAction") == 5)
    {
        return true;
    }
    if(O_enable & INTERRUPT_CUSTOM_SEQUENCE)
    {
        char model[PLATFORM_MAX_PATH];
        GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
        ArrayList ar = null;
        if(Custom_sequences.GetValue(model, ar) && ar.FindValue(GetEntProp(client, Prop_Send, "m_nSequence")) != -1)
        {
            return true;
        }
    }
    return false;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client) && should_restart_healing(client))
    {
        AutomaticHealingR_WaitToHeal(client);
    }
}

void load_custom_sequences()
{
    StringMapSnapshot snap = Custom_sequences.Snapshot();
    for(int i = 0; i < snap.Length; i++)
    {
        char key[PLATFORM_MAX_PATH];
        snap.GetKey(i, key, sizeof(key));
        ArrayList value = null;
        if(Custom_sequences.GetValue(key, value))
        {
            delete value;
        }
        Custom_sequences.Remove(key);
    }
    delete snap;
    if(FileExists(Data_path))
    {
        KeyValues kv = new KeyValues(PLUGIN_PREFIX ... "_custom_sequences");
        if(kv.ImportFromFile(Data_path) && kv.GotoFirstSubKey())
        {
            do
            {
                char key[PLATFORM_MAX_PATH];
                if(kv.GetSectionName(key, sizeof(key)))
                {
                    ArrayList ar = new ArrayList();
                    if(!Custom_sequences.SetValue(key, ar, false))
                    {
                        delete ar;
                        continue;
                    }
                    char line[1024];
                    kv.GetString("sequences", line, sizeof(line));
                	TrimString(line);
					int len = strlen(line);
					if(!len)
					{
						continue;
					}
                    int delimiter_count = 1;
                    for(int i = 0; i < len; i++)
                    {
                        if(line[i] == ',')
                        {
                            delimiter_count++;
                        }
                    }
                    char[][] str_get = new char[delimiter_count][16];
                    ExplodeString(line, ",", str_get, delimiter_count, 16);
                    for(int i = 0; i < delimiter_count; i++)
                    {
                        ar.Push(StringToInt(str_get[i]));
                    }
                }
            }
            while(kv.GotoNextKey());
        }
        delete kv;
    }
}

Action cmd_reload(int client, int args)
{
    load_custom_sequences();
    return Plugin_Handled;
}

void get_cvars()
{
	O_enable = C_enable.IntValue;
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
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
    Offset_QueuedPummelVictim = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker") + 4;

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/%s_custom_sequences.cfg", PLUGIN_PREFIX);

    Custom_sequences = new StringMap();

    load_custom_sequences();

    RegAdminCmd("sm_" ... PLUGIN_PREFIX ... "_reload_custom_sequences", cmd_reload, ADMFLAG_ROOT, "reload config data from file");

	C_enable = CreateConVar(PLUGIN_PREFIX ... "_enable", "31", "which type of status will interrupt healing? 1 = get staggered, 2 = pinned by speical infected, 4 = falling from ledge,\n8 = custom sequences, 16 = getting up from defib. add numbers together", _, true, 0.0, true, 31.0);
	C_enable.AddChangeHook(convar_changed);
	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, PLUGIN_PREFIX);
    get_cvars();
}