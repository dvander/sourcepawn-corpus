#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0"

#define TEST_DEBUG			0
#define TEST_DEBUG_LOG		1

#define DEFAULT_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

static const	ASSAULT_RIFLE_OFFSET_IAMMO		= 12;
static const	SMG_OFFSET_IAMMO				= 20;
static const	PUMPSHOTGUN_OFFSET_IAMMO		= 28;
static const	AUTO_SHOTGUN_OFFSET_IAMMO		= 32;
static const	HUNTING_RIFLE_OFFSET_IAMMO		= 36;
static const	MILITARY_SNIPER_OFFSET_IAMMO	= 40;
//static const	GRENADE_LAUNCHER_OFFSET_IAMMO	= 68;

static Handle:AssaultAmmoCVAR = INVALID_HANDLE;
static Handle:SMGAmmoCVAR = INVALID_HANDLE;
static Handle:ShotgunAmmoCVAR = INVALID_HANDLE;
static Handle:AutoShotgunAmmoCVAR = INVALID_HANDLE;
static Handle:HRAmmoCVAR = INVALID_HANDLE;
static Handle:SniperRifleAmmoCVAR = INVALID_HANDLE;
static Handle:GrenadeLauncherAmmoCVAR = INVALID_HANDLE;
static Handle:M60AmmoCVAR = INVALID_HANDLE;
static Handle:M60AmmoReserveCVAR = INVALID_HANDLE;

static Handle:GrenadeResupplyCVAR = INVALID_HANDLE;
static Handle:M60ResupplyCVAR = INVALID_HANDLE;
static Handle:GLtoM60TransformCVAR = INVALID_HANDLE;
static Handle:IncendAmmoMultiplier = INVALID_HANDLE;
static Handle:SplosiveAmmoMultiplier = INVALID_HANDLE;

static bool:buttondelay[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "L4D2 Gun Control",
	author = "MasterMind420, AtomicStryker",
	description = " Allows Customization of some gun related game mechanics ",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	/*REQUIRES L4D2*/
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");

	CreateConVar("l4d2_guncontrol_version", PLUGIN_VERSION, " Version of L4D2 Gun Control on this server ", DEFAULT_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);

	AssaultAmmoCVAR = CreateConVar("l4d2_guncontrol_assaultammo", "360", " How much Ammo for Assault Rifles ", DEFAULT_FLAGS);
	SMGAmmoCVAR = CreateConVar("l4d2_guncontrol_smgammo", "650", " How much Ammo for SMG gun types ", DEFAULT_FLAGS);
	ShotgunAmmoCVAR = CreateConVar("l4d2_guncontrol_shotgunammo", "56", " How much Ammo for Shotgun and Chrome Shotgun ", DEFAULT_FLAGS);
	AutoShotgunAmmoCVAR = CreateConVar("l4d2_guncontrol_autoshotgunammo", "90", " How much Ammo for Autoshottie and SPAS ", DEFAULT_FLAGS);
	HRAmmoCVAR = CreateConVar("l4d2_guncontrol_huntingrifleammo", "150", " How much Ammo for the Hunting Rifle ", DEFAULT_FLAGS);
	SniperRifleAmmoCVAR = CreateConVar("l4d2_guncontrol_sniperrifleammo", "180", " How much Ammo for the Military Sniper Rifle, AWP, and Scout ", DEFAULT_FLAGS);	
	GrenadeLauncherAmmoCVAR = CreateConVar("l4d2_guncontrol_grenadelauncherammo", "30", " How much Ammo for the Grenade Launcher ", DEFAULT_FLAGS);
	M60AmmoCVAR = CreateConVar("l4d2_guncontrol_m60ammo", "150", " How much Ammo for the M60 ", DEFAULT_FLAGS);
	M60AmmoReserveCVAR = CreateConVar("l4d2_guncontrol_m60ammo_reserve", "300", " How much Ammo Reserve for the M60 ", DEFAULT_FLAGS);

	GrenadeResupplyCVAR = CreateConVar("l4d2_guncontrol_allowgrenadereplenish", "1", " Do you allow Players to resupply the Grenadelauncher off ammospots ", DEFAULT_FLAGS);
	M60ResupplyCVAR = CreateConVar("l4d2_guncontrol_allowm60replenish", "1", " Do you allow Players to resupply the M60 off ammospots ", DEFAULT_FLAGS);
	GLtoM60TransformCVAR = CreateConVar("l4d2_guncontrol_turnGLintoM60chance", "2", " Turns GL spawns into M60 spawns. Works as chance setting. 1 is FULL chance, 2 is half chance, 3 one third and so on ", DEFAULT_FLAGS);
	IncendAmmoMultiplier = CreateConVar("l4d2_guncontrol_incendammomulti", "3", " Multiplier for Incendiary Ammo Pickup Amount ", DEFAULT_FLAGS);
	SplosiveAmmoMultiplier = CreateConVar("l4d2_guncontrol_explosiveammomulti", "1", " Multiplier for Explosive Ammo Pickup Amount ", DEFAULT_FLAGS);

	HookConVarChange(AssaultAmmoCVAR, CVARChanged);
	HookConVarChange(SMGAmmoCVAR, CVARChanged);
	HookConVarChange(ShotgunAmmoCVAR, CVARChanged);
	HookConVarChange(AutoShotgunAmmoCVAR, CVARChanged);
	HookConVarChange(HRAmmoCVAR, CVARChanged);
	HookConVarChange(SniperRifleAmmoCVAR, CVARChanged);
	HookConVarChange(GrenadeLauncherAmmoCVAR, CVARChanged);
	HookConVarChange(M60AmmoCVAR, CVARChanged);
	HookConVarChange(M60AmmoReserveCVAR, CVARChanged);

	HookEvent("player_use", Event_Ammo_Pile, EventHookMode_Pre);
	HookEvent("item_pickup", Event_Item_Pickup);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("upgrade_pack_added", Event_SpecialAmmo);

	RegConsoleCmd("give_ammo", Cmd_GiveAmmo, "Gives the Player you look at your current ammo clip");
	RegAdminCmd("sm_guncontroldebug", Cmd_ReadGunData, ADMFLAG_ROOT, " Reads your current weapons data ");

	AutoExecConfig(true, "l4d2_guncontrol");

	UpdateConVars();
}

public OnMapStart()
{
	UpdateConVars();
}

public CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateConVars();
}

UpdateConVars()
{
	SetConVarInt(FindConVar("ammo_assaultrifle_max"), GetConVarInt(AssaultAmmoCVAR));
	SetConVarInt(FindConVar("ammo_smg_max"), GetConVarInt(SMGAmmoCVAR));
	SetConVarInt(FindConVar("ammo_shotgun_max"), GetConVarInt(ShotgunAmmoCVAR));
	SetConVarInt(FindConVar("ammo_autoshotgun_max"), GetConVarInt(AutoShotgunAmmoCVAR));
	SetConVarInt(FindConVar("ammo_huntingrifle_max"), GetConVarInt(HRAmmoCVAR));
	SetConVarInt(FindConVar("ammo_sniperrifle_max"), GetConVarInt(SniperRifleAmmoCVAR));
	SetConVarInt(FindConVar("ammo_grenadelauncher_max"), GetConVarInt(GrenadeLauncherAmmoCVAR));
	SetConVarInt(FindConVar("ammo_m60_max"), GetConVarInt(M60AmmoReserveCVAR));
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:UnlockGunsPlugin = FindConVar("l4d2_WeaponUnlock");

	if (UnlockGunsPlugin == INVALID_HANDLE)
		return;

	decl String:version[12];
	GetConVarString(UnlockGunsPlugin, version, sizeof(version));
	
	new unlockversion = ParseVersionNumber(version);
	new neededversion = ParseVersionNumber("0.8.2");

	if (unlockversion < neededversion)
		return;

	CreateTimer(10.0, ReplaceGLWithM60Delayed);

	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl"))
		PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/v_models/v_m60.mdl"))
		PrecacheModel("models/v_models/v_m60.mdl");
}

stock ParseVersionNumber(const String:versionText[])
{
	new String:versionNumbers[4][4];
	ExplodeString(versionText, /* split */ ".", versionNumbers, .maxStrings = 4, .maxStringLength = 4);
	
	new version = 0;
	new shift = 24;
	for(new i = 0; i < sizeof(versionNumbers); i++)
	{
		version = version | (StringToInt(versionNumbers[i]) << shift);
		
		shift -= 8;
	}
	
	return version;
}

public Action:ReplaceGLWithM60Delayed(Handle:timer)
{
	ReplaceGrenadeLauncherWithM60(GetConVarInt(GLtoM60TransformCVAR));
}

ReplaceGrenadeLauncherWithM60(chance)
{
	if (chance == 0)
		return;

	new ent = -1;
	new prev = 0;
	new Replacement;
	decl Float:origin[3];
	decl Float:angles[3];

	while ((ent = FindEntityByClassname(ent, "weapon_grenade_launcher_spawn")) != -1)
	{
		if (prev)
		{
			if (GetRandomInt(1, chance) == 1)
			{
				GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
				GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
				
				Replacement = CreateEntityByName("weapon_rifle_m60");
				DispatchSpawn(Replacement);
				if (!IsValidEntity(Replacement))
					return;

				TeleportEntity(Replacement, origin, angles, NULL_VECTOR);
				SetEntProp(Replacement, Prop_Data, "m_iClip1", GetConVarInt(M60AmmoCVAR), 1);
				
				if (IsValidEdict(prev))
					RemoveEdict(prev);
			}
		}
		prev = ent;
	}
	if (prev)
	{
		if (GetRandomInt(1, chance) == 1)
		{
			GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
			GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
			
			Replacement = CreateEntityByName("weapon_rifle_m60");
			DispatchSpawn(Replacement);
			//DebugPrintToAll("Replacing weapon_grenade_launcher_spawn %i with weapon_rifle_m60 %i", prev, Replacement);
			if (!IsValidEdict(Replacement))
				return;

			TeleportEntity(Replacement, origin, angles, NULL_VECTOR);
			SetEntProp(Replacement, Prop_Data, "m_iClip1", GetConVarInt(M60AmmoCVAR), 1);
			//DebugPrintToAll("Teleported weapon_rifle_m60 %i into position, removing weapon_grenade_launcher_spawn now", Replacement);
			
			if (IsValidEdict(prev))
				RemoveEdict(prev);
		}
	}
}

public Action:Event_Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsSurvivor(client))
		return;

	decl String:sWeapon[32];
	GetEventString(event, "item", sWeapon, sizeof(sWeapon));

	if (!StrEqual(sWeapon, "rifle_m60", false))
		return;

	decl Weapon;
	Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(Weapon))
		return;

	static AmmoType;
	AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");

	SetEntProp(Weapon, Prop_Data, "m_iClip1", GetConVarInt(M60AmmoCVAR), 1);
	SetEntProp(client, Prop_Send, "m_iAmmo", GetConVarInt(M60AmmoReserveCVAR), _, AmmoType);
}

public Action:Event_Ammo_Pile(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if (!buttondelay[client])
	{
		CreateTimer(2.0, ResetDelay, client);

		decl AmmoPile;
		AmmoPile = GetClientAimTarget(client, false);
		if (AmmoPile < 32 || !IsValidEntity(AmmoPile))
			return Plugin_Continue;

		decl String:eName[32];
		GetEntityClassname(AmmoPile, eName, sizeof(eName));

		decl Weapon;
		//Weapon = GetPlayerWeaponSlot(client, 0);
		Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (!IsValidEntity(Weapon))
			return Plugin_Continue;

		decl String:sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		if (StrEqual(eName, "weapon_ammo_spawn", false) && (!StrEqual(sWeapon, "weapon_pistol", false) || !StrEqual(sWeapon, "weapon_pistol", false)))
		{
			decl AmmoType;
			AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
			if (AmmoType != -1)
			{
				decl Ammo;
				Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

				//M60 REMUNITION
				if (StrEqual(sWeapon, "weapon_rifle_m60", false) && GetConVarBool(M60ResupplyCVAR))
				{
					//SetEntProp(Weapon, Prop_Data, "m_iClip1", GetConVarInt(M60AmmoCVAR), 1);
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					SetEntProp(client, Prop_Send, "m_iAmmo", GetConVarInt(M60AmmoReserveCVAR) + GetConVarInt(M60AmmoCVAR), _, AmmoType);
					PrintHintText(client, "RELOADED");
				}

				//GRENADE LAUNCHER REMUNITION
				else if (StrEqual(sWeapon, "weapon_grenade_launcher", false) && GetConVarBool(GrenadeResupplyCVAR))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					SetEntProp(client, Prop_Send, "m_iAmmo", GetConVarInt(GrenadeLauncherAmmoCVAR) + 1, _, AmmoType);
					PrintHintText(client, "RELOADED");
				}

				if (!StrEqual(eName, sWeapon)) //If aim target and weapon aren't equal they are incompatible
					return Plugin_Continue;

				new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
				decl offsettoadd, maxammo;

				//ASSAULT REMUNITION
				if (StrEqual(sWeapon, "weapon_rifle", false) || StrEqual(sWeapon, "weapon_rifle_ak47", false) || StrEqual(sWeapon, "weapon_rifle_desert", false) || StrEqual(sWeapon, "weapon_rifle_sg552", false))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					offsettoadd = ASSAULT_RIFLE_OFFSET_IAMMO; //gun type specific offset
					maxammo = GetConVarInt(AssaultAmmoCVAR); //get max ammo as set
				}
				//SMG REMUNITION
				else if (StrEqual(sWeapon, "weapon_smg", false) || StrEqual(sWeapon, "weapon_smg_silenced", false) || StrEqual(sWeapon, "weapon_smg_mp5", false))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					offsettoadd = SMG_OFFSET_IAMMO; //gun type specific offset
					maxammo = GetConVarInt(SMGAmmoCVAR); //get max ammo as set
				}
				//SHOTGUN REMUNITION
				else if (StrEqual(sWeapon, "weapon_pumpshotgun", false) || StrEqual(sWeapon, "weapon_shotgun_chrome", false))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					offsettoadd = PUMPSHOTGUN_OFFSET_IAMMO; //gun type specific offset
					maxammo = GetConVarInt(ShotgunAmmoCVAR); //get max ammo as set
				}
				else if (StrEqual(sWeapon, "weapon_autoshotgun", false) || StrEqual(sWeapon, "weapon_shotgun_spas", false))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					offsettoadd = AUTO_SHOTGUN_OFFSET_IAMMO; //gun type specific offset
					maxammo = GetConVarInt(AutoShotgunAmmoCVAR); //get max ammo as set
				}
				//SNIPER REMUNITION
				else if (StrEqual(sWeapon, "weapon_hunting_rifle", false))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					offsettoadd = HUNTING_RIFLE_OFFSET_IAMMO; //gun type specific offset
					maxammo = GetConVarInt(HRAmmoCVAR); //get max ammo as set
				}
				else if (StrEqual(sWeapon, "weapon_sniper_military", false) || StrEqual(sWeapon, "weapon_sniper_awp", false) || StrEqual(sWeapon, "weapon_sniper_scout", false))
				{
					if (Ammo == 0) SetEntProp(Weapon, Prop_Send, "m_iClip1", 0);
					offsettoadd = MILITARY_SNIPER_OFFSET_IAMMO; //gun type specific offset
					maxammo = GetConVarInt(SniperRifleAmmoCVAR); //get max ammo as set
				}
				//NO GUN MATCH
				else
					return Plugin_Continue;

				new currentammo = GetEntData(client, (iAmmoOffset + offsettoadd)); //get current ammo
		
				if (currentammo >= maxammo) return Plugin_Continue; //if youre full, do nothing
/*		
				new foundgunammo = GetEntProp(AmmoPile, Prop_Send, "m_iExtraPrimaryAmmo", 4); //get the lying around guns contained ammo

				if (!foundgunammo) //if its zero
				{
					PrintHintText(client, "EMPTY GUN"); //the gun is empty, bug out
					return Plugin_Continue;
				}

				if ((currentammo + foundgunammo) <= maxammo) //if contained ammo is less than youd need to be full
				{
					SetEntData(client, (iAmmoOffset + offsettoadd), (currentammo + foundgunammo), 4, true); //add bullets to your supply
					SetEntProp(AmmoPile, Prop_Send, "m_iExtraPrimaryAmmo",0 ,4); //empty the gun
					PrintHintText(client, "SCAVENGED %i BULLETS", foundgunammo); //inform the client
				}
				else //if contained ammo exceeds your needs
				{
					new neededammo = (maxammo - currentammo); //find out how much exactly you need
					SetEntData(client, (iAmmoOffset + offsettoadd), maxammo, 4, true); //fill you up
					SetEntProp(AmmoPile, Prop_Send, "m_iExtraPrimaryAmmo",(foundgunammo - neededammo) ,4); //take needed ammo from gun
					PrintHintText(client, "SCAVENGED %i BULLETS", neededammo); //inform the client
				}
*/
			}
		}
	}
	return Plugin_Continue;
}

public Action:ResetDelay(Handle:timer, any:client)
{
	buttondelay[client] = false;
}

public Action:Cmd_GiveAmmo(client, args)
{
	if (!client) client=1;
	new target = GetClientAimTarget(client, true); //get the player our client is looking at
	if (!target || !IsClientInGame(target)) return Plugin_Handled; //invalid
	
	new targetgun = GetPlayerWeaponSlot(target, 0); //get the players primary weapon
	if (!IsValidEdict(targetgun)) return Plugin_Handled; //check for validity
	
	decl String:targetgunname[64];
	GetEdictClassname(targetgun, targetgunname, sizeof(targetgunname));
	
	new oldgun = GetPlayerWeaponSlot(client, 0); //get the players primary weapon
	if (!IsValidEdict(oldgun)) return Plugin_Handled; //check for validity
	
	decl String:currentgunname[64];
	GetEdictClassname(oldgun, currentgunname, sizeof(currentgunname)); //get the primary weapon name
	
	if (!StrEqual(targetgunname, currentgunname))
	{
		PrintToChat(client, "\x01You can only give \x04%N\x01 ammo if you got \x04the same weapon", target);
		return Plugin_Handled; //if targets and your weapon dont have the same name theyre incompatible
	}
	
	if (GetEntProp(oldgun, Prop_Send, "m_iClip1", 1)<2) 
	{
		PrintToChat(client, "\x01You can only give \x04%N\x01 ammo if you got \x04a clip with bullets in your gun", target);
		return Plugin_Handled;
	}
	
	new iAmmoOffset = FindDataMapOffs(target, "m_iAmmo"); //get the iAmmo Offset
	decl offsettoadd, maxammo;
	
	if (StrEqual(currentgunname, "weapon_rifle", false) || StrEqual(currentgunname, "weapon_rifle_ak47", false) || StrEqual(currentgunname, "weapon_rifle_desert", false) || StrEqual(currentgunname, "weapon_rifle_sg552", false))
	{ //case: Assault rifles
		offsettoadd = ASSAULT_RIFLE_OFFSET_IAMMO; //gun type specific offset
		maxammo = GetConVarInt(AssaultAmmoCVAR); //get max ammo as set
	}
	else if (StrEqual(currentgunname, "weapon_smg", false) || StrEqual(currentgunname, "weapon_smg_silenced", false) || StrEqual(currentgunname, "weapon_smg_mp5", false))
	{ //case: SMGS
		offsettoadd = SMG_OFFSET_IAMMO; //gun type specific offset
		maxammo = GetConVarInt(SMGAmmoCVAR); //get max ammo as set
	}		
	else if (StrEqual(currentgunname, "weapon_pumpshotgun", false) || StrEqual(currentgunname, "weapon_shotgun_chrome", false))
	{ //case: Pump Shotguns
		offsettoadd = PUMPSHOTGUN_OFFSET_IAMMO; //gun type specific offset
		maxammo = GetConVarInt(ShotgunAmmoCVAR); //get max ammo as set
	}
	else if (StrEqual(currentgunname, "weapon_autoshotgun", false) || StrEqual(currentgunname, "weapon_shotgun_spas", false))
	{ //case: Auto Shotguns
		offsettoadd = AUTO_SHOTGUN_OFFSET_IAMMO; //gun type specific offset
		maxammo = GetConVarInt(AutoShotgunAmmoCVAR); //get max ammo as set
	}
	else if (StrEqual(currentgunname, "weapon_hunting_rifle", false))
	{ //case: Hunting Rifle
		offsettoadd = HUNTING_RIFLE_OFFSET_IAMMO; //gun type specific offset
		maxammo = GetConVarInt(HRAmmoCVAR); //get max ammo as set
	}
	else if (StrEqual(currentgunname, "weapon_sniper_military", false) || StrEqual(currentgunname, "weapon_sniper_awp", false) || StrEqual(currentgunname, "weapon_sniper_scout", false))
	{ //case: Military Sniper Rifle or CSS Snipers
		offsettoadd = MILITARY_SNIPER_OFFSET_IAMMO; //gun type specific offset
		maxammo = GetConVarInt(SniperRifleAmmoCVAR); //get max ammo as set
	}
	else
	{ //case: no gun this plugin recognizes
		PrintToChat(client, "Error: WTF what gun is that");
		return Plugin_Handled;
	}
	
	new currentammo = GetEntData(target, (iAmmoOffset + offsettoadd)); //get targets current ammo
	
	if (currentammo >= maxammo) //if hes full, do nothing
	{
		PrintToChat(client, "\x01That guy \x04has full\x01 ammo");
		return Plugin_Handled;
	}
	
	new donateammo = GetEntProp(oldgun, Prop_Send, "m_iClip1", 1)-1; //you give your current gun clip minus the bullet thats in the barrel
	
	if ((currentammo + donateammo) <= maxammo) //if clips ammo is less than hed need to be full
	{
		SetEntData(target, (iAmmoOffset + offsettoadd), (currentammo + donateammo), 4, true); //add bullets to his supply
		SetEntProp(oldgun, Prop_Send, "m_iClip1",1 ,1); //empty your gun
		PrintToChat(client, "\x01You gave your clip of \x04%i bullets\x01 to \x04%N\x01", donateammo, target);
	}
	else //if given ammo exceeds his needs
	{
		new neededammo = (maxammo - currentammo); //find out how much exactly he needs
		SetEntData(target, (iAmmoOffset + offsettoadd), maxammo, 4, true); //fill him up
		SetEntProp(oldgun, Prop_Send, "m_iClip1",(donateammo - neededammo) ,1); //take needed ammo from your clip
		PrintToChat(client, "\x01You gave \x04%i bullets\x01 off your clip to \x04%N\x01", neededammo, target);
	}	
	return Plugin_Handled;
}

public Action:Event_SpecialAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new upgradeid = GetEventInt(event, "upgradeid");
	decl String:class[256];
	GetEdictClassname(upgradeid, class, sizeof(class));
	//PrintToChatAll("Upgrade caught, entity = %i, entclass: %s", upgradeid, class);
	
	if (StrEqual(class, "upgrade_laser_sight"))
		return;
	
	new ammo = GetSpecialAmmoInPlayerGun(client);
	new newammo;

	if (StrEqual(class, "upgrade_ammo_incendiary"))
		newammo = ammo * GetConVarInt(IncendAmmoMultiplier);
	else if (StrEqual(class, "upgrade_ammo_explosive"))	
		newammo = ammo * GetConVarInt(SplosiveAmmoMultiplier);

	decl String:sWeapon[32];
	static Weapon;
	Weapon = GetPlayerWeaponSlot(client, 0);
	if (IsValidEntity(Weapon) || IsValidEdict(Weapon))
	{
		GetEdictClassname(Weapon, sWeapon, sizeof(sWeapon));
		if (StrEqual(sWeapon, "weapon_rifle_m60"))
		{
			if (StrEqual(class, "upgrade_ammo_incendiary"))	
				newammo = ammo * 1;
			else if (StrEqual(class, "upgrade_ammo_explosive"))	
				newammo = ammo * 1;
		}
	}

	if (newammo > 1)
		SetSpecialAmmoInPlayerGun(client, newammo);
	else return;

	PrintToChat(client, "\x01You receive \x04%i clips\x01 of Special Ammo!", newammo/ammo);
}

stock GetSpecialAmmoInPlayerGun(client) //returns the amount of special rounds in your gun
{
	if (!client) client = 1;
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		return GetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
	else return 0;
}

stock SetSpecialAmmoInPlayerGun(client, amount)
{
	if (!client) client = 1;
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		SetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}

public Action:Cmd_ReadGunData(client, args)
{
	if (!client || !IsClientInGame(client))
	{
		ReplyToCommand(client, "Can only use this command ingame");
		return Plugin_Handled;
	}
	
	new targetgun = GetPlayerWeaponSlot(client, 0); //get the players primary weapon
	if (!IsValidEdict(targetgun)) return Plugin_Handled; //check for validity
	
	decl String:name[256];
	GetEdictClassname(targetgun, name, sizeof(name));
	PrintToChat(client, "Gun Class: %s", name);
	
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo"); //get the iAmmo Offset
	PrintToChat(client, "m_iAmmo Offset: %i", iAmmoOffset);
	
	for (new offset = 0; offset <= 128 ; offset += 4)
	{
		PrintToChat(client, "Offset %i Value: %i", offset, GetEntData(client, (iAmmoOffset + offset)));
	}
	
	PrintToChat(client, "m_iClip1 Value in gun: %i", GetEntProp(targetgun, Prop_Data, "m_iClip1", 1));
	PrintToChat(client, "m_iExtraPrimaryAmmo Value in gun: %i", GetEntProp(targetgun, Prop_Data, "m_iExtraPrimaryAmmo", 4));
	return Plugin_Handled;
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[GUNCONTROL] %s", buffer);
	PrintToConsole(0, "[GUNCONTROL] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}

stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}