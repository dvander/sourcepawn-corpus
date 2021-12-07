#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0.0"
#define TAG "[SM:MM]"

#define GUNS_PISTOL				0
#define GUNS_MAGNUM				1
#define GUNS_START				2
#define GUNS_END				19
#define GUNS_UPGRADE_EXPLOSIVE	20
#define GUNS_UPGRADE_INCENDIARY	21
#define GUNS_AMMO				22
#define GUNS_CHAINSAW			23
#define GUNS_UPGRADE_LASER		24
#define GUNS_SIZE				25

#define MM_PISTOL		(1<<0)
#define MM_MAGNUM		(1<<1)
#define MM_EXPLOSIVE	(1<<2)
#define MM_INCENDIARY	(1<<3)
#define MM_LASER		(1<<4)

#define MAX_MELEE_LENGTH 12

public Plugin:myinfo = 
{
	name = "[L4D2] Melee Mode",
	author = "McFlurry",
	description = "Removes all guns.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

new String:sMeleeList[MAX_MELEE_LENGTH][20] =
{
	"cricket_bat",
	"crowbar",
	"baseball_bat",
	"electric_guitar",
	"fireaxe",
	"katana",
	"knife",
	"tonfa",
	"golfclub",
	"machete",
	"frying_pan",
	"knife"
};
new String:sValidMelee[MAX_MELEE_LENGTH][20];	

new String:sGuns[GUNS_SIZE][] =
{
	"weapon_pistol_spawn",
	"weapon_pistol_magnum_spawn",
	"weapon_rifle_spawn",
	"weapon_rifle_desert_spawn",
	"weapon_rifle_ak47_spawn",
	"weapon_rifle_sg552_spawn",
	"weapon_rifle_m60_spawn",
	"weapon_hunting_rifle_spawn",
	"weapon_sniper_scout_spawn",
	"weapon_sniper_awp_spawn",
	"weapon_sniper_military_spawn",
	"weapon_autoshotgun_spawn",
	"weapon_shotgun_spas_spawn",
	"weapon_shotgun_chrome_spawn",
	"weapon_pumpshotgun_spawn",
	"weapon_smg_spawn",
	"weapon_smg_silenced_spawn",
	"weapon_smg_mp5_spawn",
	"weapon_grenade_launcher_spawn",
	"weapon_spawn",
	"weapon_upgradepack_explosive_spawn",
	"weapon_upgradepack_incendiary_spawn",
	"weapon_ammo_spawn",
	"weapon_chainsaw_spawn",
	"upgrade_laser_sight"
};	

new Handle:hEnable = INVALID_HANDLE;
new Handle:hMeleeToWeaponRatio = INVALID_HANDLE;
new Handle:hRemoveSecondaries = INVALID_HANDLE;
new Handle:hRemoveChainsaws = INVALID_HANDLE;
new Handle:hRemoveUpgrades = INVALID_HANDLE;
new Handle:hRemoveAmmo = INVALID_HANDLE;
new Handle:hModes = INVALID_HANDLE;

new initMelee;
new Handle:hBotMelee = INVALID_HANDLE;
new Handle:hSLimit = INVALID_HANDLE;

new pistolRemoved[MAXPLAYERS];
new iMeleeWeapon[MAXPLAYERS];
new bDead[MAXPLAYERS] = { true, ... };
new bool:bMissionFailed;
new bool:bFoundMelee;

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{		
		SetFailState("[SM] Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("l4d2_meleemode_version", PLUGIN_VERSION, "Installed version of Melee Mode on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnable = CreateConVar("l4d2_meleemode_enable", "1", "Enable Melee Mode?",FCVAR_PLUGIN);
	hMeleeToWeaponRatio = CreateConVar("l4d2_meleemode_weapon_ratio", "1", "Ratio of melee weapons per 1 weapon(pistol/magnum) that bots will uphold", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hRemoveSecondaries = CreateConVar("l4d2_meleemode_secondaries", "3", "Remove secondaries 0=no 1=pistols 2=magnums, you can add the values up", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hRemoveChainsaws = CreateConVar("l4d2_meleemode_remove_chainsaws", "0", "Remove chainsaws?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hRemoveUpgrades = CreateConVar("l4d2_meleemode_remove_upgrades", "28", "Remove upgrades 0=no 4=incendiary 8=explosive 16=lasers, you can add the values up", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hRemoveAmmo = CreateConVar("l4d2_meleemode_ammo_remove", "1", "Remove ammo piles?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hModes = CreateConVar("l4d2_meleemode_modes", "coop,realism", "Game modes Melee Mode is allowed to operate in", FCVAR_PLUGIN|FCVAR_NOTIFY);

	hSLimit = FindConVar("survivor_limit");
	if(hSLimit == INVALID_HANDLE)
	{
		SetFailState("Melee Mode: Failed to find survivor_limit");
	}
	hBotMelee = FindConVar("sb_max_team_melee_weapons");
	if(hBotMelee == INVALID_HANDLE)
	{
		SetFailState("Melee Mode: Failed to find sb_max_team_melee_weapons");
	}
	initMelee = GetConVarInt(hBotMelee);
	
	RegConsoleCmd("sm_ent", Command_Ent);
	
	AutoExecConfig(true, "l4d2_meleemode");
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("mission_lost", Event_MissionFailed);
	HookEvent("survivor_rescued", OnPlayerRescued);
	HookEvent("player_death", OnPlayerDeath);
}

public Action:Command_Ent(client, args)
{
	if(client > 0)
	{
		new target = GetClientAimTarget(client, false);
		if(target > MaxClients)
		{
			decl String:classname[128];
			GetEdictClassname(target, classname, sizeof(classname));
			PrintToChat(client, "%d %s", target, classname);
		}
	}
}	

public OnPluginEnd()
{
	SetConVarInt(hBotMelee, initMelee);
}

public OnClientDisconnect(client)
{
	bDead[client] = true;
}	

public OnMapStart()
{
	bFoundMelee = false;
	bMissionFailed = false;
	for(new i=1;i<=MaxClients;i++)
	{
		pistolRemoved[i] = false;
		bDead[i] = true;
	}	
}

public OnConfigsExecuted()
{
	new total = GetConVarInt(hSLimit);
	new leftratio = GetConVarInt(hMeleeToWeaponRatio);
	new rightratio = 1;
	new part = leftratio+rightratio;
	new Float:val = float(total/part);
	SetConVarInt(hBotMelee, total-RoundFloat(val));
}	

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == 0) return;
	bDead[client] = true;
}	

public Action:OnPlayerRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	bDead[client] = false;
	CheckPlayerMelee(client, true);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CheckPlayerMelee(client);
	bDead[client] = false;
}

public Action:Event_MissionFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	bMissionFailed = true;
}	

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hEnable) || !IsAllowedGameMode()) return;
	
	new i;
	
	for(i=GUNS_START;i<=GUNS_END;i++)
	{
		RemoveAllEntitiesByClassname(sGuns[i]);
	}
	
	new upgrades = GetConVarInt(hRemoveUpgrades);
	if((upgrades & MM_EXPLOSIVE))
	{
		RemoveAllEntitiesByClassname(sGuns[GUNS_UPGRADE_EXPLOSIVE]);
	}
	if((upgrades & MM_INCENDIARY))
	{
		RemoveAllEntitiesByClassname(sGuns[GUNS_UPGRADE_INCENDIARY]);
	}
	if((upgrades & MM_LASER))
	{
		RemoveAllEntitiesByClassname(sGuns[GUNS_UPGRADE_LASER]);
	}	
	
	if(GetConVarBool(hRemoveAmmo))
	{
		RemoveAllEntitiesByClassname(sGuns[GUNS_AMMO]);
	}	
	
	if(GetConVarBool(hRemoveChainsaws))
	{
		RemoveAllEntitiesByClassname(sGuns[GUNS_CHAINSAW]);
	}	
	
	new bit = GetConVarInt(hRemoveSecondaries);
	if((bit & MM_PISTOL))
	{
		RemoveAllEntitiesByClassname(sGuns[GUNS_PISTOL]);
	}	
	if((bit & MM_MAGNUM))
	{
		RemoveAllEntitiesByClassname(sGuns[GUNS_MAGNUM]);
	}
}

stock CheckPlayerMelee(client, bool:closet=false)
{
	if(!GetConVarBool(hEnable)) return;
	if(!bFoundMelee)
	{
		GetValidMeleeWeapons();
		bFoundMelee = true;
	}
	if((bMissionFailed || !pistolRemoved[client] || closet || bDead[client]) && GetClientTeam(client) == 2)
	{
		new slot = GetPlayerWeaponSlot(client, 1);
		decl String:classname[32];
		if(slot > -1)
		{
			GetEntityClassname(slot, classname, sizeof(classname));
			decl String:sVal[2];
			GetConVarString(hRemoveSecondaries, sVal, sizeof(sVal));
			new bit = StringToInt(sVal);
			if(StrContains(classname, "melee", false) != -1)
			{
				return;
			}
			else if(StrContains(classname, "pistol_magnum", false) != -1 && (bit & MM_MAGNUM))
			{
				RemoveEdict(slot);
			}	
			else if(StrContains(classname, "pistol", false) != -1 && (bit & MM_PISTOL))
			{
				RemoveEdict(slot);
			}	
		}	
		
		new entity = CreateEntityByName("weapon_melee");
		
		if(!bMissionFailed || closet || bDead[client]) GetRandomValidMelee(iMeleeWeapon[client]);
		
		DispatchKeyValue(entity, "melee_script_name", sValidMelee[iMeleeWeapon[client]]);
		DispatchSpawn(entity);
		
		EquipPlayerWeapon(client, entity);
		pistolRemoved[client] = true;
	}
}	

stock GetValidMeleeWeapons()
{
	for(new i=0;i<MAX_MELEE_LENGTH;i++)
	{
		Format(sValidMelee[i], sizeof(sValidMelee[]), "");
	}
	for(new i=0;i<MAX_MELEE_LENGTH;i++)
	{
		new entity = CreateEntityByName("weapon_melee");
		if(entity != -1)
		{
			continue;
		}	
		DispatchKeyValue(entity, "melee_script_name", sMeleeList[i]);
		DispatchSpawn(entity);
		decl String:modelname[256];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		if(StrContains(modelname, "hunter", false) == -1)
		{
			Format(sValidMelee[i], sizeof(sValidMelee[]), sMeleeList[i]);
		}
		RemoveEdict(entity);
	}
}

stock GetRandomValidMelee(&storage)
{
	new counter;
	new validlist[MAX_MELEE_LENGTH];
	
	for(new i;i<MAX_MELEE_LENGTH;i++)
	{
		if(strlen(sValidMelee[i]) > 0)
		{
			validlist[counter] = i;
			counter++;
		}
	}
	
	new random = GetRandomInt(0, counter-1);
	storage = validlist[random];
}	

stock bool:IsAllowedGameMode()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(hModes, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}

stock RemoveAllEntitiesByClassname(const String:classname[])
{
	new ent = -1;
	new prev = 0;
	while ((ent = FindEntityByClassname(ent, classname)) != -1)
	{
		if (prev) RemoveEdict(prev);
		prev = ent;
	}
	if (prev)
	{
		RemoveEdict(prev);
	}	
}