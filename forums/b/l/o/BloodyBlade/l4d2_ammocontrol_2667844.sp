#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.8"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

int g_FreezeSerial[MAXPLAYERS+1] = { 0, ... };
int g_FreezeTime[MAXPLAYERS+1] = { 0, ... };
int g_FreezeBombSerial[MAXPLAYERS+1] = { 0, ... };
int g_FreezeBombTime[MAXPLAYERS+1] = { 0, ... };
int g_Serial_Gen = 0;
int g_GlowSprite;

ConVar Special_Ammo_Count;
ConVar Special_Ammo_Bonus_Count;

public Plugin myinfo = 
{
	name = "L4D2 Ammo Control MOD",
	author = "AtomicStryker",
	description = " Allows Customization of some gun related game mechanics ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1020236"
}

public void OnPluginStart()
{
	HookEvent("upgrade_pack_added", Event_SpecialAmmo);
	HookEvent("upgrade_pack_used", Event_UpgradePackUsed);
	HookEvent("round_start", Event_RoundStart);
//	HookEvent("player_death", Event_PlayerDeath);
	Special_Ammo_Count = CreateConVar("l4d2_ammo_upgradepack_count", "15", "", FCVAR_SPONLY|FCVAR_NOTIFY);
	Special_Ammo_Bonus_Count = CreateConVar("l4d2_ammo_upgradepack_bcount", "50", "", FCVAR_SPONLY|FCVAR_NOTIFY);
}

public void OnMapStart()
{
	PrecacheSound(SOUND_FREEZE, true);
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	KillAllFreezes();
}

void FreezeClient(int client, int time)
{
	if (g_FreezeSerial[client] != 0)
	{
		UnfreezeClient(client);
		return;
	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);

	float vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

	g_FreezeTime[client] = time;
	g_FreezeSerial[client] = ++ g_Serial_Gen;
	CreateTimer(1.0, Timer_Freeze, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
}

void UnfreezeClient(int client)
{
	g_FreezeSerial[client] = 0;
	g_FreezeTime[client] = 0;

	if (IsClientInGame(client))
	{
		float vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;	
		
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

public Action Timer_Freeze(Handle timer, any value)
{
	int client = value & 0x7f;
	int serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_FreezeSerial[client] != serial)
	{
		UnfreezeClient(client);
		return Plugin_Stop;
	}

	if (g_FreezeTime[client] == 0)
	{
		UnfreezeClient(client);
		/* HintText doesn't work on Dark Messiah */
		if (GetEngineVersion() == Engine_Left4Dead2)
		{
			PrintHintText(client, "You are now unfrozen.");
		}
		else
		{
			PrintCenterText(client, "You are now unfrozen.");
		}
		return Plugin_Stop;
	}

	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		PrintHintText(client, "You will be unfrozen in %d seconds.", g_FreezeTime[client]);
	}
	else
	{
		PrintCenterText(client, "You will be unfrozen in %d seconds.", g_FreezeTime[client]);
	}
	
	g_FreezeTime[client]--;
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 135);

	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupGlowSprite(vec, g_GlowSprite, 0.95, 1.5, 50);
	TE_SendToAll();

	return Plugin_Continue;
}

void KillAllFreezes()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (g_FreezeSerial[i] != 0)
		{
			UnfreezeClient(i);
		}

		if (g_FreezeBombSerial[i] != 0)
		{
			KillFreezeBomb(i);
		}
	}
}

void KillFreezeBomb(int client)
{
	g_FreezeBombSerial[client] = 0;
	g_FreezeBombTime[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

public Action Kickbot(Handle timer, any client)
{ // code from l4d2_monsterbots.sp
	if (IsClientInGame(client))
	{
		if (IsFakeClient(client))
		{
			KickClient(client);
		}
	}
}

public Action Event_PlayerDeath(Event hEvent, const char[] strName, bool DontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (client == 0) 
		return;
		
	if (GetClientTeam(client) != 3)
		return;
	
	ChangeClientTeam(client, 2);	
}

stock void SpawnCommandEx(int client, char[] command, char[] arguments = "", int count)
{ // code from l4d2_monsterbots.sp
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	for (int i = 1; i < count; i++)
	{
		FakeClientCommand(client, "%s %s", command, arguments);
	}
	SetCommandFlags(command, flags);
}

stock void SpawnCommand(int client, char[] command, char[] arguments = "")
{ // code from l4d2_monsterbots.sp
	if (client)
	{
		ChangeClientTeam(client, 3);
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
		CreateTimer(0.1, Kickbot, client);
	}
}

stock void SpawnCommandControl(int client, char[] command, char[] arguments = "")
{ // code from l4d2_monsterbots.sp
	if (client)
	{
		ChangeClientTeam(client, 3);
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

stock int IsTankAlive()
{
	char classname[32];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 3)
			{
				if (IsFakeClient(i))
				{
					GetClientModel(i, classname, sizeof(classname));
					if (StrContains(classname, "tank"))
					{
						return 1;
					}
				}
			}
		}
	}
	return 0;
}

public Action Event_SpecialAmmo(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int upgradeid = GetEventInt(event, "upgradeid");
	char class[256];
	GetEdictClassname(upgradeid, class, sizeof(class));
	
	if (StrEqual(class, "upgrade_laser_sight"))
	{
		if (GetRandomInt(1, 2) == 1)
		{
			RemoveEdict(upgradeid);
		}
		return;
	}

//	char s_Weapon[32];
	char PrimaryWeaponName[64];
//	GetClientWeapon(client, s_Weapon, sizeof(s_Weapon))
	GetEdictClassname(GetPlayerWeaponSlot(client, 0), PrimaryWeaponName, sizeof(PrimaryWeaponName));
	if (StrEqual(PrimaryWeaponName, "weapon_grenade_launcher", false))
	{
		int MaxAmmo = GetRandomInt(1, 10);
		if (MaxAmmo == 1)
		{
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", GetConVarInt(Special_Ammo_Bonus_Count));
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", GetConVarInt(Special_Ammo_Bonus_Count), 1);
		}
		else
		{
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", GetConVarInt(Special_Ammo_Count));
			SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", GetConVarInt(Special_Ammo_Count), 1);
		}
		RemoveEdict(upgradeid);
		return;
	}
	if (StrEqual(PrimaryWeaponName, "weapon_rifle_m60", false))
	{
		RemoveEdict(upgradeid);
		return;
	}	
	else if (GetSpecialAmmoInPlayerGun(client) > 1)
	{
		int AMMORND = GetRandomInt(1, 3);
		SetSpecialAmmoInPlayerGun(client, AMMORND * GetSpecialAmmoInPlayerGun(client));
	}
	RemoveEdict(upgradeid);
}

public Action Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int upgradeid = GetEventInt(event, "upgradeid");
	int RND = GetRandomInt(1, 6);
	if (RND == 1)
	{
		int LaserEntity = CreateEntityByName("upgrade_laser_sight");
		if (LaserEntity == -1)
		{
			return;
		}
		PrintToChat(client, "\x05You have found a laser sight!");
		float vecOrigin[3];
		float angRotation[3];
		GetEntPropVector(upgradeid, Prop_Send, "m_vecOrigin", vecOrigin);
		GetEntPropVector(upgradeid, Prop_Send, "m_angRotation", angRotation);		
		RemoveEdict(upgradeid);
		TeleportEntity(LaserEntity, vecOrigin, angRotation, NULL_VECTOR);
		DispatchSpawn(LaserEntity);
		return;
	}
	RND = GetRandomInt(1, 55);
	if (RND < 3)
	{
		SpawnCommandEx(client, "z_spawn", "witch auto", 5);
		PrintHintTextToAll("%N have found a witchbox!", client);
		RemoveEdict(upgradeid);
		return;
	}
	else if (RND < 5)
	{
		if (!IsTankAlive())
		{
			int flags = GetCommandFlags("z_spawn");
			SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "z_spawn tank auto");
			SetCommandFlags("z_spawn", flags);
			if (IsTankAlive())
			{
				PrintHintTextToAll("%N have found a tankbox!", client);
				RemoveEdict(upgradeid);
				return;
			}
		}
	}
	else if (RND < 6)
	{
		PrintHintTextToAll("%N have found a panicbox!", client);
		char command[] = "director_force_panic_event";
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, command);
		SetCommandFlags(command, flags);
		RemoveEdict(upgradeid);
		return;
	}
	else if (RND < 10)
	{
		PrintHintTextToAll("%N have found a icebox!", client);
		FreezeClient(client, 20);
		RemoveEdict(upgradeid);
		return;
	}
}

public void give_laser_sight(int client)
{
	int flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "upgrade_add laser_sight");
	SetCommandFlags("upgrade_add", flags);
}

stock int GetSpecialAmmoInPlayerGun(int client) //returns the amount of special rounds in your gun
{
	if (!client)
	{
//		client = 1;
		return 0;
	}
	int gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		return GetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
	else return 0;
}

void SetSpecialAmmoInPlayerGun(int client, int amount)
{
	if (!client)
	{
//		client = 1;
		return;
	}
	int gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		SetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}