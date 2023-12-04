#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CONFIG "data/weapons_destroying_chances.cfg"

#define SHOOTING_SOUND "weapons/smg_silenced/gunother/smg_fullautobutton_1.wav"
#define DESTROYED_SOUND "weapons/hunting_rifle/gunother/hunting_rifle_cliplocked.wav"
#define REPAIRED_SOUND "weapons/scout/gunother/scout_clipin.wav"

#define SOUND_PER_TICKS 50

#define MAX_SLOT_0_WEAPONS 18
#define MAX_BEING_DESTROYED 64

// #define _DEBUG

#if defined _DEBUG
	#define LOG(%0) LogMessage(%0)
#else
	#define LOG(%0) (0)
#endif

enum struct WeaponDestroyInfo
{
	char name[36];
	float destroy_chance;
	float repair_time;
}

enum struct WeaponDestroyManager
{
	int weapons[MAX_BEING_DESTROYED];
	int count;
	
	int Find( int weapon )
	{
		if ( !IsValidEntity(weapon) )
			return -1;
		
		for( int i; i < this.count; i++ )
		{
			if ( EntRefToEntIndex(this.weapons[i]) == weapon )
			{
				return i;
			}
		}
		
		return -1;
	}
	
	bool Add( int weapon )
	{
		if ( this.count == MAX_BEING_DESTROYED )
		{
			LogError("Failed to add new weapon to manager due to limit... Expand it");
			return false;
		}
		
		if ( this.Find(weapon) != -1 )
			return false;
		
		this.weapons[this.count++] = EntIndexToEntRef(weapon);
		return true;
	}
	
	bool Remove( int weapon )
	{
		int i = this.Find(weapon);
		
		if ( i == -1 )
			return false;
		
		if ( i != this.count - 1 )
		{
			for (int j = i; j < this.count - 1; j++)
			{
				this.weapons[j] = this.weapons[j + 1];
			}
		}
		else
		{
			this.weapons[i] = 0;
		}
		
		return true;
	}
	
	void Clear()
	{
		for (int i; i < MAX_BEING_DESTROYED; i++)
		{
			this.weapons[i] = 0;
		}
		
		this.count = 0;
	}
}

WeaponDestroyInfo g_Info[MAX_SLOT_0_WEAPONS];
WeaponDestroyManager g_Manager;

float g_flRepairTime[MAXPLAYERS + 1];

int g_iDIEntries;
int g_iLevel;

char g_szPath[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	BuildPath(Path_SM, g_szPath, sizeof g_szPath, "%s", CONFIG);
	
	HookEvent("weapon_fire", weapon_fire);
	HookEvent("player_use", player_use);
	
	if ( !ParseConfig(g_szPath) )
	{
		LogError("Failed to parse config... Aborting");
		return;
	}
	
	RegAdminCmd("sm_wd_config_dump", sm_wd_config_dump, ADMFLAG_CHEATS);
	RegAdminCmd("sm_wd_config_reload", sm_wd_config_reload, ADMFLAG_CHEATS);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame(i) )
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnMapStart()
{
	g_Manager.Clear();
	
	PrecacheSound(SHOOTING_SOUND, true);
	PrecacheSound(REPAIRED_SOUND, true);
	PrecacheSound(DESTROYED_SOUND, true);
}

public void OnClientPutInServer( int client )
{	
	SDKHook(client, SDKHook_PreThink, OnThink);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action sm_wd_config_dump( int client, int args )
{
	for (int i; i < g_iDIEntries; i++)
	{
		ReplyToCommand(client, "%i. Name [ %s ] repair_time [ %.2f ] destroy_chance [ %.2f ]", i + 1, g_Info[i].name, g_Info[i].repair_time, g_Info[i].destroy_chance);
	}

	return Plugin_Handled;
}

public Action sm_wd_config_reload( int client, int args )
{
	ReplyToCommand(client, "Config reloaded: %s", ParseConfig(g_szPath) ? "OK" : "NOT OK");
	return Plugin_Handled;
}

public void player_use( Event event, const char[] name, bool replicate )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int weapon = event.GetInt("targetid");
	
	if ( !client || GetClientTeam(client) != 2 || IsFakeClient(client) || g_Manager.Find(weapon) == -1 )
		return;
	
	LOG("Player %N picked up destroyed weapon", client);
	DestroyWeapon(client, weapon, false);
}

public void weapon_fire( Event event, const char[] name, bool replicate )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( !client || GetClientTeam(client) != 2 || IsFakeClient(client) )
		return;
		
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if ( weapon == -1 || weapon != GetPlayerWeaponSlot(client, 0) )
		return;
	
	WeaponDestroyInfo info;
	
	if ( !GetWeaponDestroyInfo(weapon, info) )
		return;

	if ( GetRandomFloat(1.0, 100.0) <= info.destroy_chance && g_Manager.Add(weapon) )
	{
		LOG("Adding %N weapon to manager", client);
		DestroyWeapon(client, weapon, true);
		PrintHintText(client, "Your weapon has been destroyed. Hold SHIFT + USE button to fix it");
	}
}

public Action OnWeaponSwitch( int client, int weapon )
{
	if ( !IsValidEntity(weapon) || GetPlayerWeaponSlot(client, 0) != weapon )
		return Plugin_Continue;
	
	if ( g_Manager.Find(weapon) == -1 )
	{
		LOG("%N switched to repaired weapon %i", client, weapon);
		RepairWeapon(client, weapon, false);
	}
	else
	{
		LOG("%N switched to broken weapon", client);
		
		DataPack pack;
		
		CreateDataTimer(0.0, timer_break_weapon, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(EntIndexToEntRef(weapon));
	}
	
	return Plugin_Continue;
}

public Action timer_break_weapon( Handle timer, DataPack pack )
{
	pack.Reset();
	
	int client = GetClientOfUserId(pack.ReadCell());
	int weapon = EntRefToEntIndex(pack.ReadCell());
	
	if ( !client || weapon == INVALID_ENT_REFERENCE )
		return Plugin_Continue;
	
	DestroyWeapon(client, weapon, false);
	return Plugin_Continue;
}

public Action OnThink( int client )
{
	WeaponDestroyInfo info;
	int buttons, weapon, i = -1;
	bool fixed;
	
	weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if ( weapon == -1 || weapon != GetPlayerWeaponSlot(client, 0) || (i = g_Manager.Find(weapon)) == -1 )
	{
		g_flRepairTime[client] = 0.0;
		EndProgressBar(client);
		return Plugin_Continue;
	}
	
	GetWeaponDestroyInfo(weapon, info);
	
	buttons = GetClientButtons(client);
	
	if ( buttons & IN_USE && buttons & IN_SPEED )
	{
		if ( g_flRepairTime[client] && g_flRepairTime[client] - GetGameTime() <= 0.0 )
		{
			g_flRepairTime[client] = 0.0;
			g_Manager.Remove(weapon);
			EndProgressBar(client);
			RepairWeapon(client, weapon, true);
			fixed = true;
		}
		else if ( g_flRepairTime[client] <= GetGameTime() )
		{
			LOG("Start repairing weapon");
			g_flRepairTime[client] = GetGameTime() + info.repair_time;
			StartProgressBar(client, info.repair_time);
		}
	}
	else
	{
		if ( g_flRepairTime[client] >= GetGameTime() )
		{
			LOG("Released use button -> failed to repair weapon");
			g_flRepairTime[client] = 0.0;
			EndProgressBar(client);
		}
	}
	
	if ( !fixed )
	{
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 999999.0);
		
		if ( buttons & IN_ATTACK )
		{
			static int tick[MAXPLAYERS + 1];
			
			if ( tick[client]++ % SOUND_PER_TICKS == 0 )
			{
				EmitSoundToAll(SHOOTING_SOUND, client);
			}
		}
	}
	
	return Plugin_Continue;
}

void DestroyWeapon( int client, int weapon, bool sound )
{
	LOG("%N destroyed weapon", client);
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 999999.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 999999.0);
	
	if ( sound )
	{
		EmitSoundToAll(DESTROYED_SOUND, client);
	}
}

void RepairWeapon( int client, int weapon, bool sound )
{
	LOG("%N repaired weapon", client);
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 1.0);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 1.0);
	
	if ( sound )
	{
		EmitSoundToAll(REPAIRED_SOUND, client);
	}
}

bool GetWeaponDestroyInfo( int weapon, WeaponDestroyInfo out )
{
	char name[36];
	GetEntityClassname(weapon, name, sizeof name);
	
	for (int i; i < MAX_SLOT_0_WEAPONS; i++)
	{
		if ( strcmp(g_Info[i].name, name) == 0 )
		{
			out = g_Info[i];
			
			#if SOURCEMOD_V_MINOR > 10
				out = out;
			#endif
			
			return true;
		}
	}
	
	return false;
}

void StartProgressBar( int client, float time )
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

void EndProgressBar( int client )
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}

bool ParseConfig( const char[] path )
{
	if ( !FileExists(path) )
	{
		LogError("Failed to load config... File doesn't exist");
		return false;
	}
	
	SMCParser parser = new SMCParser();
	char error[128]; 
	int line = 0, col = 0;
	
	parser.OnEnterSection = Config_NewSection;
	parser.OnLeaveSection = Config_EndSection;
	parser.OnKeyValue = Config_KeyValue;
	
	SMCError result = SMC_ParseFile(parser, path, line, col);
	delete parser;
	
	if ( result != SMCError_Okay )
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, path);
		return false;
	}
	
	return ( result == SMCError_Okay );
}

public SMCResult Config_NewSection( Handle parser, const char[] section, bool quotes )
{
	g_iLevel++;
	
	if ( g_iLevel == 2 )
	{
		strcopy(g_Info[g_iDIEntries].name, sizeof WeaponDestroyInfo::name, section);
	}
	
	return SMCParse_Continue;
}

public SMCResult Config_KeyValue(Handle parser, char[] key, char[] value, bool key_quotes, bool value_quotes)
{
	if ( strcmp(key, "repair_time") == 0 )
	{
		g_Info[g_iDIEntries].repair_time = StringToFloat(value);
	}
	else if ( strcmp(key, "destroy_chance") == 0 )
	{
		g_Info[g_iDIEntries].destroy_chance = StringToFloat(value);
	}
	
	return SMCParse_Continue;
}

public SMCResult Config_EndSection(Handle parser)
{
	if ( g_iLevel == 2 )
	{
		g_iDIEntries++;
	}
	
	g_iLevel--;
	return SMCParse_Continue;
}