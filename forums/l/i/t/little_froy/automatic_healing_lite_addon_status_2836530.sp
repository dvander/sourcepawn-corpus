#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <automatic_healing_lite>
#include <little_froy_utils>

#define INTERRUPT_STAGGERED				(1 << 0)
#define INTERRUPT_PINNED				(1 << 1)
#define INTERRUPT_FALLING_FROM_LEDGE	(1 << 2)
#define INTERRUPT_CUSTOM_SEQUENCE       (1 << 3)
#define INTERRUPT_GETTING_UP_FROM_DEFIB (1 << 4)
#define INTERRUPT_ONFIRE				(1 << 5)

#define QueuedPummel_Attacker	8

public Plugin myinfo =
{
	name = "Automatic Healing Lite Addon Interrupt Healing On Status",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=350951"
};

ConVar C_enable;
int O_enable;

ArrayList Sequences[MAXPLAYERS+1];
int Last_model_index[MAXPLAYERS+1] = {-1, ...};

StringMap Custom_sequences;
int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];

bool Started;

char Data_path[PLATFORM_MAX_PATH];

int Offset_QueuedPummelVictim;

public void AutomaticHealingLite_OnGameStart()
{
	Started = true;
}

public void AutomaticHealingLite_OnGameEnd()
{
	Started = false;
}

public void OnMapEnd()
{
	reset_all();
}

bool is_player_alright(int client)
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

bool is_player_falling(int client)
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
    if(O_enable & INTERRUPT_FALLING_FROM_LEDGE && is_player_falling(client))
    {
        return true;
    }
    if(O_enable & INTERRUPT_GETTING_UP_FROM_DEFIB && GetEntProp(client, Prop_Send, "m_iCurrentUseAction") == 5)
    {
        return true;
    }
	if(O_enable & INTERRUPT_ONFIRE && GetEntityFlags(client) & FL_ONFIRE)
	{
		return true;
	}
    if(O_enable & INTERRUPT_CUSTOM_SEQUENCE)
    {
		int index = GetEntProp(client, Prop_Data, "m_nModelIndex");
		if(Last_model_index[client] != index)
		{
			Last_model_index[client] = index;
			char model[PLATFORM_MAX_PATH];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			Sequences[client] = null;
			Custom_sequences.GetValue(model, Sequences[client]);
		}
		if(Sequences[client] && Sequences[client].FindValue(GetEntProp(client, Prop_Send, "m_nSequence")) != -1)
		{
			return true;
		}
    }
    return false;
}

public void OnGameFrame()
{
	if(!Started)
	{
		return;
	}
    for(int client = 1; client <= MaxClients; client++)
    {
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client) && should_restart_healing(client))
		{
			AutomaticHealingLite_WaitToHeal(client);
		}
	}
}

void reset_player(int client)
{
	Last_model_index[client] = -1;
	Sequences[client] = null;
}

void reset_all()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			reset_player(client);
		}
	}
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client);
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
		if(!Custom_sequences.ContainsKey(Current_section_name))
		{
			if(strcmp(key, "sequences") == 0)
			{
				if(value[0] != '\0')
				{
					ArrayList ar = new ArrayList();
					explode_string_to_list(value, ",", ar, 12, StringExplodeType_Int);
					if(ar.Length > 0)
					{
						Custom_sequences.SetValue(Current_section_name, ar);
					}
					else
					{
						delete ar;
					}
				}
			}
		}
	}
    return SMCParse_Continue;
}

void load_custom_sequences()
{
	reset_all();
    StringMapSnapshot snap = Custom_sequences.Snapshot();
    for(int i = 0; i < snap.Length; i++)
    {
        int len = snap.KeyBufferSize(i);
        char[] key = new char[len];
        snap.GetKey(i, key, len);
        ArrayList value = null;
        if(Custom_sequences.GetValue(key, value))
        {
            delete value;
        }
    }
    delete snap;
	Custom_sequences.Clear();
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
    load_custom_sequences();
    return Plugin_Handled;
}

void get_all_cvars()
{
	O_enable = C_enable.IntValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_enable)
	{
		O_enable = C_enable.IntValue;
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
    Offset_QueuedPummelVictim = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker") + 4;

    Custom_sequences = new StringMap();

	BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/automatic_healing_lite_addon_status_custom_sequences.cfg");

	C_enable = CreateConVar("automatic_healing_lite_addon_status_enable", "63", "which type of status will interrupt healing? 1 = get staggered, 2 = pinned by speical infected, 4 = falling from ledge,\n8 = custom sequences, 16 = getting up from defib, 32 = on fire. add numbers together");
	C_enable.AddChangeHook(convar_changed);
	CreateConVar("automatic_healing_lite_addon_status_version", PLUGIN_VERSION, "version of Automatic Healing Lite Addon Interrupt Healing On Status", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, "automatic_healing_lite_addon_status");
    get_all_cvars();
	load_custom_sequences();

    RegAdminCmd("sm_automatic_healing_lite_addon_status_reload_custom_sequences", cmd_reload, ADMFLAG_ROOT, "reload config data from file");

	Started = AutomaticHealingLite_HasGameStart();
}
