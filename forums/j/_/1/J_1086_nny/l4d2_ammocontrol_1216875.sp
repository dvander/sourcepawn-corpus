#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.8"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

new g_FreezeSerial[MAXPLAYERS+1] = { 0, ... };
new g_FreezeTime[MAXPLAYERS+1] = { 0, ... };
new g_FreezeBombSerial[MAXPLAYERS+1] = { 0, ... };
new g_FreezeBombTime[MAXPLAYERS+1] = { 0, ... };
new g_Serial_Gen = 0;
new g_GameEngine = SOURCE_SDK_UNKNOWN;
new g_GlowSprite;

new Handle:Special_Ammo_Count;
new Handle:Special_Ammo_Bonus_Count;

public Plugin:myinfo = 
{
	name = "L4D2 Ammo Control MOD",
	author = "AtomicStryker",
	description = " Allows Customization of some gun related game mechanics ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1020236"
}

public OnPluginStart()
{
	g_GameEngine = GuessSDKVersion();
	HookEvent("upgrade_pack_added", Event_SpecialAmmo);
	HookEvent("upgrade_pack_used", Event_UpgradePackUsed);
	HookEvent("round_start", Event_RoundStart);
//	HookEvent("player_death", Event_PlayerDeath);
	Special_Ammo_Count = CreateConVar("l4d2_ammo_upgradepack_count", "15", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Special_Ammo_Bonus_Count = CreateConVar("l4d2_ammo_upgradepack_bcount", "50", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
}

public OnMapStart()
{
	PrecacheSound(SOUND_FREEZE, true);
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	KillAllFreezes();
}

FreezeClient(client, time)
{
	if (g_FreezeSerial[client] != 0)
	{
		UnfreezeClient(client);
		return;
	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);

	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

	g_FreezeTime[client] = time;
	g_FreezeSerial[client] = ++ g_Serial_Gen;
	CreateTimer(1.0, Timer_Freeze, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
}

UnfreezeClient(client)
{
	g_FreezeSerial[client] = 0;
	g_FreezeTime[client] = 0;

	if (IsClientInGame(client))
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;	
		
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

		SetEntityMoveType(client, MOVETYPE_WALK);
		
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

public Action:Timer_Freeze(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

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
		if (g_GameEngine != SOURCE_SDK_DARKMESSIAH)
		{
			PrintHintText(client, "You are now unfrozen.");
		}
		else
		{
			PrintCenterText(client, "You are now unfrozen.");
		}
		
		return Plugin_Stop;
	}

	if (g_GameEngine != SOURCE_SDK_DARKMESSIAH)
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

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupGlowSprite(vec, g_GlowSprite, 0.95, 1.5, 50);
	TE_SendToAll();

	return Plugin_Continue;
}

KillAllFreezes()
{
	for(new i = 1; i <= MaxClients; i++)
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

KillFreezeBomb(client)
{
	g_FreezeBombSerial[client] = 0;
	g_FreezeBombTime[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

public Action:Kickbot(Handle:timer, any:client)
{ // code from l4d2_monsterbots.sp
	if (IsClientInGame(client))
	{
		if (IsFakeClient(client))
		{
			KickClient(client);
		}
	}
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (client == 0) 
		return;
		
	if (GetClientTeam(client) != 3)
		return;
	
	ChangeClientTeam(client, 2);	
}

stock SpawnCommandEx(client, String:command[], String:arguments[] = "", count)
{ // code from l4d2_monsterbots.sp
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	for (new i = 1; i < count; i++)
	{
		FakeClientCommand(client, "%s %s", command, arguments);
	}
	SetCommandFlags(command, flags);
}

stock SpawnCommand(client, String:command[], String:arguments[] = "")
{ // code from l4d2_monsterbots.sp
	if (client)
	{
		ChangeClientTeam(client, 3);
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
		CreateTimer(0.1, Kickbot, client);
	}
}

stock SpawnCommandControl(client, String:command[], String:arguments[] = "")
{ // code from l4d2_monsterbots.sp
	if (client)
	{
		ChangeClientTeam(client, 3);
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

stock IsTankAlive()
{
	decl String: classname[32];
	for (new i = 1; i <= MaxClients; i++)
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

public Action:Event_SpecialAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new upgradeid = GetEventInt(event, "upgradeid");
	decl String:class[256];
	GetEdictClassname(upgradeid, class, sizeof(class));
	
	if (StrEqual(class, "upgrade_laser_sight"))
	{
		if (GetRandomInt(1, 2) == 1)
		{
			RemoveEdict(upgradeid);
		}
		return;
	}
	
	
//	decl String:s_Weapon[32];
	decl String:PrimaryWeaponName[64];

//	GetClientWeapon(client, s_Weapon, sizeof(s_Weapon))

	GetEdictClassname(GetPlayerWeaponSlot(client, 0), PrimaryWeaponName, sizeof(PrimaryWeaponName));

	if (StrEqual(PrimaryWeaponName, "weapon_grenade_launcher", false))
	{
		new MaxAmmo = GetRandomInt(1, 10);
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
		new AMMORND = GetRandomInt(1, 3);
		SetSpecialAmmoInPlayerGun(client, AMMORND * GetSpecialAmmoInPlayerGun(client));
	}
	RemoveEdict(upgradeid);
}

public Action:Event_UpgradePackUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new upgradeid = GetEventInt(event, "upgradeid");
	new RND = GetRandomInt(1, 6);
	if (RND == 1)
	{
		new LaserEntity = CreateEntityByName("upgrade_laser_sight");
		if (LaserEntity == -1)
		{
			return;
		}
		PrintToChat(client, "\x05You have found a laser sight!");
		new Float:vecOrigin[3];
		new Float:angRotation[3];
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
			new flags = GetCommandFlags("z_spawn");
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
		new String:command[] = "director_force_panic_event";
		new flags = GetCommandFlags(command);
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

public give_laser_sight(client)
{
	new flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "upgrade_add laser_sight");
	SetCommandFlags("upgrade_add", flags);
}

stock GetSpecialAmmoInPlayerGun(client) //returns the amount of special rounds in your gun
{
	if (!client)
	{
//		client = 1;
		return 0;
	}
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		return GetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
	else return 0;
}

SetSpecialAmmoInPlayerGun(client, amount)
{
	if (!client)
	{
//		client = 1;
		return;
	}
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		SetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}