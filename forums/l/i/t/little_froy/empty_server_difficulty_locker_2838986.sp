#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <connected_counter>

public Plugin myinfo =
{
	name = "Empty Server Difficulty Locker",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351461"
};

ConVar C_z_difficulty;
ConVar C_value;
char O_value[32];

bool Changing;

void set_difficulty(bool in_event)
{
	if(Changing)
	{
		return;
	}
	if(!in_event)
	{
		int count = 0;
		ConnectedCounter_GetConnected(count);
		if(count > 0)
		{
			return;
		}
	}
	char difficulty[32];
	C_z_difficulty.GetString(difficulty, sizeof(difficulty));
	if(strcmp(difficulty, O_value, false) != 0)
	{
		Changing = true;
		C_z_difficulty.SetString(O_value);
		Changing = false;
	}
}

public void ConnectedCounter_OnDisconnect(int userid, int count, const int userids[MAXPLAYERS], const char[] reason, const char[] name, const char[] networkid)
{
	if(count == 0)
	{
		set_difficulty(true);
	}
}

void get_all_cvars()
{
	C_value.GetString(O_value, sizeof(O_value));

	set_difficulty(false);
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_value)
	{
		C_value.GetString(O_value, sizeof(O_value));
	}
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);

	set_difficulty(false);
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
    C_z_difficulty = FindConVar("z_difficulty");
	C_z_difficulty.AddChangeHook(convar_changed);
	C_value = CreateConVar("empty_server_difficulty_locker_value", "Hard", "lock this difficulty on server empty");
	C_value.AddChangeHook(convar_changed);
    CreateConVar("empty_server_difficulty_locker_version", PLUGIN_VERSION, "version of Empty Server Difficulty Locker", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "empty_server_difficulty_locker");
	get_all_cvars();
}