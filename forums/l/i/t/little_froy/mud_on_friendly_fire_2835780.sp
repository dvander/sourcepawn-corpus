#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <little_froy_utils>

#if !defined DMG_GENERIC
 #define DMG_GENERIC 0
#endif

public Plugin myinfo =
{
	name = "Mud On Friendly Fire",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=350803"
};

ConVar C_weapon_bypass;
ArrayList O_weapon_bypass;
ConVar C_include_self;
bool O_include_self;
ConVar C_interval;
float O_interval;
ConVar C_damagetype_bypass;
int O_damagetype_bypass;
ConVar C_ignore_range;
float O_ignore_range;
ConVar C_bypass_damagetype_generic;
bool O_bypass_damagetype_generic;

Handle H_timer_in_mud[MAXPLAYERS+1];

void reset_player(int client)
{
	delete H_timer_in_mud[client];
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client);
}

void timer_in_mud(Handle timer, int client)
{
	H_timer_in_mud[client] = null;
}

void check_hurt(Event event)
{
	int damagetype = event.GetInt("type");
	if(damagetype & O_damagetype_bypass)
	{
		return;
	}
	if(O_bypass_damagetype_generic && damagetype == DMG_GENERIC)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if(attacker > 0 && !H_timer_in_mud[attacker] && (O_include_self || client != attacker) && IsClientInGame(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
		{
			if(client != attacker && O_ignore_range >= 0.0)
			{
				float pos1[3];
				float pos2[3];
				GetClientAbsOrigin(client, pos1);
				GetClientAbsOrigin(attacker, pos2);
				if(GetVectorDistance(pos1, pos2) <= O_ignore_range)
				{
					return;
				}
			}
			char weapon[64];
			event.GetString("weapon", weapon, sizeof(weapon));
			if(weapon[0] != '\0' && O_weapon_bypass.FindString(weapon) == -1)
			{
				H_timer_in_mud[attacker] = CreateTimer(O_interval, timer_in_mud, attacker);
				BfWrite bf = view_as<BfWrite>(StartMessageOne("MudSplatter", attacker, USERMSG_RELIABLE));
				bf.WriteByte(1);
				EndMessage();
			}
		}
	}
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	check_hurt(event);
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	check_hurt(event);
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	reset_all();
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

void get_all_cvars()
{
	O_weapon_bypass.Clear();
	char buffer[2048];
	C_weapon_bypass.GetString(buffer, sizeof(buffer));
	if(buffer[0] != '\0')
	{
		explode_string_to_list(buffer, ",", O_weapon_bypass, 64, StringExplodeType_String);
	}
	O_include_self = C_include_self.BoolValue;
	O_interval = C_interval.FloatValue;
	O_damagetype_bypass = C_damagetype_bypass.IntValue;
	O_ignore_range = C_ignore_range.FloatValue;
	O_bypass_damagetype_generic = C_bypass_damagetype_generic.BoolValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_weapon_bypass)
	{
		O_weapon_bypass.Clear();
		char buffer[2048];
		C_weapon_bypass.GetString(buffer, sizeof(buffer));
		if(buffer[0] != '\0')
		{
			explode_string_to_list(buffer, ",", O_weapon_bypass, 64, StringExplodeType_String);
		}
	}
	else if(convar == C_include_self)
	{
		O_include_self = C_include_self.BoolValue;
	}
	else if(convar == C_interval)
	{
		O_interval = C_interval.FloatValue;
	}
	else if(convar == C_damagetype_bypass)
	{
		O_damagetype_bypass = C_damagetype_bypass.IntValue;
	}
	else if(convar == C_ignore_range)
	{
		O_ignore_range = C_ignore_range.FloatValue;
	}
	else if(convar == C_bypass_damagetype_generic)
	{
		O_bypass_damagetype_generic = C_bypass_damagetype_generic.BoolValue;
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
	O_weapon_bypass = new ArrayList(ByteCountToCells(64));

	HookEvent("player_hurt", event_player_hurt);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("round_start", event_round_start);

	C_weapon_bypass = CreateConVar("mud_on_friendly_fire_weapon_bypass", "inferno,fire_cracker_blast,pipe_bomb,grenade_launcher_projectile", "weapon bypass. split up with \",\"");
	C_weapon_bypass.AddChangeHook(convar_changed);
	C_include_self = CreateConVar("mud_on_friendly_fire_include_self", "0", "1 = enable, 0 = disable. include self as victim?");
	C_include_self.AddChangeHook(convar_changed);
	C_interval = CreateConVar("mud_on_friendly_fire_interval", "0.1", "interval to mud to the same one again", _, true, 0.1);
	C_interval.AddChangeHook(convar_changed);
	C_damagetype_bypass = CreateConVar("mud_on_friendly_fire_damagetype_bypass", "64", "damagetype bypass. add damagetypes together");
	C_damagetype_bypass.AddChangeHook(convar_changed);
	C_ignore_range = CreateConVar("mud_on_friendly_fire_ignore_range", "-1.0", "ignore if distance between attacker and victim lower than or equal to this value");
	C_ignore_range.AddChangeHook(convar_changed);
	C_bypass_damagetype_generic = CreateConVar("mud_on_friendly_fire_bypass_damagetype_generic", "0", "1 = enable, 0 = disable. bypass by damagetype generic?");
	C_bypass_damagetype_generic.AddChangeHook(convar_changed);
	CreateConVar("mud_on_friendly_fire_version", PLUGIN_VERSION, "version of Mud On Friendly Fire", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, "mud_on_friendly_fire");
	get_all_cvars();
}
