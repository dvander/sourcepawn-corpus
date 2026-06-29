#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <little_froy_utils>

public Plugin myinfo =
{
	name = "Respawn With Gun",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=347163"
};

ConVar C_defib;
ArrayList O_defib;
ConVar C_rescue;
ArrayList O_rescue;

void event_defibrillator_used(Event event, const char[] name, bool dontBroadcast)
{
    if(O_defib.Length == 0)
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("subject"));
    if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && GetPlayerWeaponSlot(client, 0) == -1)
    {
		char weapon_name[64];
		O_defib.GetString(GetRandomInt(0, O_defib.Length - 1), weapon_name, sizeof(weapon_name));
		GivePlayerItem(client, weapon_name);
    }
}

void event_survivor_rescued(Event event, const char[] name, bool dontBroadcast)
{
    if(O_rescue.Length == 0)
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("victim"));
    if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && GetPlayerWeaponSlot(client, 0) == -1)
    {
		char weapon_name[64];
		O_rescue.GetString(GetRandomInt(0, O_rescue.Length - 1), weapon_name, sizeof(weapon_name));
		GivePlayerItem(client, weapon_name);
    }
}

void get_all_cvars()
{
	char buffer[2048];

	O_defib.Clear();
	C_defib.GetString(buffer, sizeof(buffer));
	if(buffer[0] != '\0')
	{
		explode_string_to_list(buffer, ",", O_defib, 64, StringExplodeType_String);
	}
	O_rescue.Clear();
	C_rescue.GetString(buffer, sizeof(buffer));
	if(buffer[0] != '\0')
	{
		explode_string_to_list(buffer, ",", O_rescue, 64, StringExplodeType_String);
	}
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_defib)
	{
		O_defib.Clear();
		char buffer[2048];
		C_defib.GetString(buffer, sizeof(buffer));
		if(buffer[0] != '\0')
		{
			explode_string_to_list(buffer, ",", O_defib, 64, StringExplodeType_String);
		}
	}
	else if(convar == C_rescue)
	{
		O_rescue.Clear();
		char buffer[2048];
		C_rescue.GetString(buffer, sizeof(buffer));
		if(buffer[0] != '\0')
		{
			explode_string_to_list(buffer, ",", O_rescue, 64, StringExplodeType_String);
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
    O_defib = new ArrayList(ByteCountToCells(64));
    O_rescue = new ArrayList(ByteCountToCells(64));

    HookEvent("defibrillator_used", event_defibrillator_used);
    HookEvent("survivor_rescued", event_survivor_rescued);

    C_defib = CreateConVar("respawn_with_gun_defib", "weapon_pumpshotgun,weapon_shotgun_chrome,weapon_smg,weapon_smg_silenced,weapon_smg_mp5", "give these weapon on defibrillator used, split up with \",\"");
    C_defib.AddChangeHook(convar_changed);
    C_rescue = CreateConVar("respawn_with_gun_rescue", "weapon_pumpshotgun,weapon_shotgun_chrome,weapon_smg,weapon_smg_silenced,weapon_smg_mp5", "give these weapon on rescued, split up with \",\"");
    C_rescue.AddChangeHook(convar_changed);
    CreateConVar("respawn_with_gun_version", PLUGIN_VERSION, "version of Respawn With Gun", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "respawn_with_gun");
    get_all_cvars();
}
