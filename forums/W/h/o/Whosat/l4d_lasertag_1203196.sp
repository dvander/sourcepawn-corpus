/******************************/
/*     [L4D(2)] Laser Tag     */
/*       By KrX/ Whosat       */
/* -------------------------- */
/* Creates a laser beam from  */
/*  player to bullet impact   */
/*  point.                    */
/* -------------------------- */
/*  Version 0.2 (12 Jan 2011) */
/* -------------------------- */
/******************************/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2"

#define DEFAULT_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

#define WEAPONTYPE_PISTOL   6
#define WEAPONTYPE_RIFLE    5
#define WEAPONTYPE_SNIPER   4
#define WEAPONTYPE_SMG      3
#define WEAPONTYPE_SHOTGUN  2
#define WEAPONTYPE_MELEE    1
#define WEAPONTYPE_UNKNOWN  0

new Handle:cvar_vsenable;
new Handle:cvar_realismenable;
new Handle:cvar_bots;
new Handle:cvar_enable;

new Handle:cvar_pistols;
new Handle:cvar_rifles;
new Handle:cvar_snipers;
new Handle:cvar_smgs;
new Handle:cvar_shotguns;

new Handle:cvar_laser_red;
new Handle:cvar_laser_green;
new Handle:cvar_laser_blue;
new Handle:cvar_laser_alpha;

new Handle:cvar_bots_red;
new Handle:cvar_bots_green;
new Handle:cvar_bots_blue;
new Handle:cvar_bots_alpha;

new Handle:cvar_laser_life;
new Handle:cvar_laser_width;
new Handle:cvar_laser_offset;

new bool:g_LaserTagEnable = true;
new bool:g_Bots;

new bool:b_TagWeapon[7];
new Float:g_LaserOffset;
new Float:g_LaserWidth;
new Float:g_LaserLife;
new g_LaserColor[4];
new g_BotsLaserColor[4];
new g_Sprite;

new GameMode;
new bool:isL4D2;

public Plugin:myinfo = 
{
	name = "[L4D(2)] Laser Tag",
	author = "KrX/Whosat",
	description = "Shows a laser for straight-flying fired projectiles",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1203196"
}

public OnPluginStart()
{	
	cvar_enable = CreateConVar("l4d_lasertag_enable", "1", "Turnon Lasertagging. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
 	cvar_vsenable = CreateConVar("l4d_lasertag_vs", "1", "Enable or Disable Lasertagging in Versus / Scavenge. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_realismenable = CreateConVar("l4d_lasertag_realism", "1", "Enable or Disable Lasertagging in Realism. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_bots = CreateConVar("l4d_lasertag_bots", "1", "Enable or Disable lasertagging for bots. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	
	cvar_pistols = CreateConVar("l4d_lasertag_pistols", "1", "LaserTagging for Pistols. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_rifles = CreateConVar("l4d_lasertag_rifles", "1", "LaserTagging for Rifles. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_snipers = CreateConVar("l4d_lasertag_snipers", "1", "LaserTagging for Sniper Rifles. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_smgs = CreateConVar("l4d_lasertag_smgs", "1", "LaserTagging for SMGs. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
	cvar_shotguns = CreateConVar("l4d_lasertag_shotguns", "1", "LaserTagging for Shotguns. 0=disable, 1=enable", DEFAULT_FLAGS, true, 0.0, true, 1.0);
		
	cvar_laser_red = CreateConVar("l4d_lasertag_red", "0", "Amount of Red", DEFAULT_FLAGS, true, 0.0, true, 255.0);
	cvar_laser_green = CreateConVar("l4d_lasertag_green", "125", "Amount of Green", DEFAULT_FLAGS, true, 0.0, true, 255.0);
	cvar_laser_blue = CreateConVar("l4d_lasertag_blue", "255", "Amount of Blue", DEFAULT_FLAGS, true, 0.0, true, 255.0);
	cvar_laser_alpha = CreateConVar("l4d_lasertag_alpha", "100", "Transparency (Alpha) of Laser", DEFAULT_FLAGS, true, 0.0, true, 255.0);
	
	cvar_bots_red = CreateConVar("l4d_lasertag_bots_red", "0", "Bots Laser - Amount of Red", DEFAULT_FLAGS, true, 0.0, true, 255.0);
	cvar_bots_green = CreateConVar("l4d_lasertag_bots_green", "255", "Bots Laser - Amount of Green", DEFAULT_FLAGS, true, 0.0, true, 255.0);
	cvar_bots_blue = CreateConVar("l4d_lasertag_bots_blue", "75", "Bots Laser - Amount of Blue", DEFAULT_FLAGS, true, 0.0, true, 255.0);
	cvar_bots_alpha = CreateConVar("l4d_lasertag_bots_alpha", "70", "Bots Laser - Transparency (Alpha) of Laser", DEFAULT_FLAGS, true, 0.0, true, 255.0);
	
	cvar_laser_life = CreateConVar("l4d_lasertag_life", "0.80", "Seconds Laser will remain", DEFAULT_FLAGS, true, 0.1);
	cvar_laser_width = CreateConVar("l4d_lasertag_width", "1.0", "Width of Laser", DEFAULT_FLAGS, true, 1.0);
	cvar_laser_offset = CreateConVar("l4d_lasertag_offset", "36", "Lasertag Offset", DEFAULT_FLAGS);
	
	CreateConVar("l4d_lasertag_version", PLUGIN_VERSION, "Lasertag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "l4d_lasertag");
	
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	// Check if L4D2 or L4D1
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false)) isL4D2 = true;
	else isL4D2 = false;
	
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false))
		GameMode = 1;
	else if (StrEqual(GameName, "realism", false))
		GameMode = 0;
	else
		GameMode = -1;
	
	HookEvent("bullet_impact", Event_BulletImpact);
	
	// ConVars that change whether the plugin is enabled
	HookConVarChange(cvar_enable, CheckEnabled);
	HookConVarChange(cvar_vsenable, CheckEnabled);
	HookConVarChange(cvar_realismenable, CheckEnabled);
	HookConVarChange(cvar_bots, CheckEnabled);
	
	HookConVarChange(cvar_pistols, CheckWeapons);
	HookConVarChange(cvar_rifles, CheckWeapons);
	HookConVarChange(cvar_snipers, CheckWeapons);
	HookConVarChange(cvar_smgs, CheckWeapons);
	HookConVarChange(cvar_shotguns, CheckWeapons);
	
	HookConVarChange(cvar_laser_red, UselessHooker);
	HookConVarChange(cvar_laser_blue, UselessHooker);
	HookConVarChange(cvar_laser_green, UselessHooker);
	HookConVarChange(cvar_laser_alpha, UselessHooker);
	HookConVarChange(cvar_bots_red, UselessHooker);
	HookConVarChange(cvar_bots_blue, UselessHooker);
	HookConVarChange(cvar_bots_green, UselessHooker);
	HookConVarChange(cvar_bots_alpha, UselessHooker);
	
	HookConVarChange(cvar_laser_life, UselessHooker);
	HookConVarChange(cvar_laser_width, UselessHooker);
	HookConVarChange(cvar_laser_offset, UselessHooker);
}

public OnMapStart()
{
	if(isL4D2)
	{
		g_Sprite = PrecacheModel("materials/sprites/laserbeam.vmt");			
	}
	else
	{
		g_Sprite = PrecacheModel("materials/sprites/laser.vmt");		
	}
}

public UselessHooker(Handle:convar, const String:oldValue[], const String:newValue[])
{
	OnConfigsExecuted();
}

public OnConfigsExecuted()
{
	CheckEnabled(INVALID_HANDLE, "", "");
	CheckWeapons(INVALID_HANDLE, "", "");
	
	g_LaserColor[0] = GetConVarInt(cvar_laser_red);
	g_LaserColor[1] = GetConVarInt(cvar_laser_green);
	g_LaserColor[2] = GetConVarInt(cvar_laser_blue);
	g_LaserColor[3] = GetConVarInt(cvar_laser_alpha);
	g_BotsLaserColor[0] = GetConVarInt(cvar_bots_red);
	g_BotsLaserColor[1] = GetConVarInt(cvar_bots_green);
	g_BotsLaserColor[2] = GetConVarInt(cvar_bots_blue);
	g_BotsLaserColor[3] = GetConVarInt(cvar_bots_alpha);
	
	g_LaserLife = GetConVarFloat(cvar_laser_life);
	g_LaserWidth = GetConVarFloat(cvar_laser_width);
	g_LaserOffset = GetConVarFloat(cvar_laser_offset);
}

public CheckEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Bot Laser Tagging?
	g_Bots = GetConVarBool(cvar_bots);
	
	if(GetConVarInt(cvar_enable) == 0) {
		// IS GLOBALLY ENABLED?
		g_LaserTagEnable = false;
	} else if(GameMode == 2 && GetConVarInt(cvar_vsenable) == 0) {
		// IS VS Enabled?
		g_LaserTagEnable = false;
	} else if(GameMode == 0 && GetConVarInt(cvar_realismenable) == 0) {
		// IS REALISM ENABLED?
		g_LaserTagEnable = false;
	} else {
		// None of the above fulfilled, enable plugin.
		g_LaserTagEnable = true;
	}
}

public CheckWeapons(Handle:convar, const String:oldValue[], const String:newValue[])
{
	b_TagWeapon[WEAPONTYPE_PISTOL] = GetConVarBool(cvar_pistols);
	b_TagWeapon[WEAPONTYPE_RIFLE] = GetConVarBool(cvar_rifles);
	b_TagWeapon[WEAPONTYPE_SNIPER] = GetConVarBool(cvar_snipers);
	b_TagWeapon[WEAPONTYPE_SMG] = GetConVarBool(cvar_smgs);
	b_TagWeapon[WEAPONTYPE_SHOTGUN] = GetConVarBool(cvar_shotguns);
}

GetWeaponType(userid)
{
	// Get current weapon
	decl String:weapon[32];
	GetClientWeapon(userid, weapon, 32);
	
	if(StrEqual(weapon, "weapon_hunting_rifle") || StrContains(weapon, "sniper") >= 0) return WEAPONTYPE_SNIPER;
	if(StrContains(weapon, "weapon_rifle") >= 0) return WEAPONTYPE_RIFLE;
	if(StrContains(weapon, "pistol") >= 0) return WEAPONTYPE_PISTOL;
	if(StrContains(weapon, "smg") >= 0) return WEAPONTYPE_SMG;
	if(StrContains(weapon, "shotgun") >=0) return WEAPONTYPE_SHOTGUN;
	
	return WEAPONTYPE_UNKNOWN;
}

public Action:Event_BulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_LaserTagEnable) return Plugin_Continue;
	
	// Get Shooter's Userid
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	// Check if is Survivor
 	if(GetClientTeam(userid) != 2) return Plugin_Continue;
	// Check if is Bot and enabled
	new bot = 0;
	if(IsFakeClient(userid)) { if(!g_Bots) return Plugin_Continue; bot = 1; }
	
	// Check if the weapon is an enabled weapon type to tag
	if(b_TagWeapon[GetWeaponType(userid)])
	{
		// Bullet impact location
		new Float:x = GetEventFloat(event, "x");
		new Float:y = GetEventFloat(event, "y");
		new Float:z = GetEventFloat(event, "z");
		
		decl Float:startPos[3];
		startPos[0] = x;
		startPos[1] = y;
		startPos[2] = z;
		
		/*decl Float:bulletPos[3];
		bulletPos[0] = x;
		bulletPos[1] = y;
		bulletPos[2] = z;*/
		
		decl Float:bulletPos[3];
		bulletPos = startPos;
		
		// Current player's EYE position
		decl Float:playerPos[3];
		GetClientEyePosition(userid, playerPos);
		
		decl Float:lineVector[3];
		SubtractVectors(playerPos, startPos, lineVector);
		NormalizeVector(lineVector, lineVector);
		
		// Offset
		ScaleVector(lineVector, g_LaserOffset);
		// Find starting point to draw line from
		SubtractVectors(playerPos, lineVector, startPos);
		
		// Draw the line
		if(!bot) TE_SetupBeamPoints(startPos, bulletPos, g_Sprite, 0, 0, 0, g_LaserLife, g_LaserWidth, g_LaserWidth, 1, 0.0, g_LaserColor, 0);
		else TE_SetupBeamPoints(startPos, bulletPos, g_Sprite, 0, 0, 0, g_LaserLife, g_LaserWidth, g_LaserWidth, 1, 0.0, g_BotsLaserColor, 0);
		
		TE_SendToAll();
	}
	
 	return Plugin_Continue;
}