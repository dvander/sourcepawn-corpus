#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <sdkhooks>

#define CLR_DEFAULT		1
#define CLR_LIGHTGREEN	3
#define CLR_GREEN		4

#define AMP_SHAKE		50.0
#define DUR_SHAKE		1.0

#define MDL_BLUE		"models/stickynades/stickynades_blue.mdl"
#define MDL_RED			"models/stickynades/stickynades_red.mdl"

#define SND_LAUGH		"music/stickynades/muhahaha.mp3"
#define SND_SCREAM		"music/stickynades/scream.mp3"

#define PL_VERSION		"1.3.1"

/* Adapted from DJ Tsunami's Sticky Nades 1.0
*  Sticky nade models are from Sticky Nades 1.0
*  http://forums.alliedmods.net/showthread.php?t=102921
*/

/* Changelog:
*  1.1.0 - Cvar snlite_admin_only changed to snlite_admin_only_flags. You can
*  		 - use any string of admin flags you want.
* 		 - Added support for old stickynade models. Use Cvar snlite_hegrenade_model
* 		 - to enable.
*  1.2.0 - Added old Sticky Nades 1.0 sounds. Use convar snlite_emit_sounds to 
* 		 - enable. Normal grenade damage and radius settings now work even if 
* 		 - nades are not sticky.
*  1.2.1 - Fixed. Native "GetEntPropEnt" reported: Property "m_hThrower" not found.
*  1.2.2 - Fixed. Various entity related errors being reported in InitGrenade.
*  1.2.3 - Fixed invalid entities being found.
*  1.2.4 - Fixed Native "EmitSound" reported: Client index -1 is invalid.
* 		 - InitGrenade now uses a timer method.
*  1.2.5 - Fixed models not working until first map change.
*  1.2.6 - Fixed models not precaching until first map change.
*  1.3.0 - Improved method of setting grenade properties.
* 		 - Removed snlite_admin_only_flags. Use admin override snlite_admin_only instead.
* 		 - snlite_hegrenade_normal_power and snlite_hegrenade_normal_radius are now 
* 		   always set. Does not depend on snlite_admin_only.
*  1.3.1 - Added CS:GO support.
* 		 - Note for CS:S - The sound location has changed to music/stickynades.
*/

public Plugin:myinfo =
{
	name        = "StickyNades Lite",
	author      = "TigerOx, Tsunami",
	description = "Allows grenades to stick to walls and players!",
	version     = PL_VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=140758"
}

// PropOffsets
new OFFSET_OWNER;
new OFFSET_DAMAGE;
new OFFSET_RADIUS;
new OFFSET_RENDER;

// Globals
new Handle:g_hHEGrenadeStickPlayers = INVALID_HANDLE;
new Handle:g_hHEGrenadeStickWalls = INVALID_HANDLE;

new Handle:g_hHEGrenadeNormalPower = INVALID_HANDLE;
new Handle:g_hHEGrenadeNormalRadius = INVALID_HANDLE;
new Handle:g_hHEGrenadeStuckPower = INVALID_HANDLE;
new Handle:g_hHEGrenadeStuckRadius = INVALID_HANDLE;

new Handle:g_hHEGrenadeModel = INVALID_HANDLE;
new Handle:g_hEmitSounds = INVALID_HANDLE;
new Handle:g_hShake = INVALID_HANDLE;
new Handle:g_hNotice = INVALID_HANDLE;

// Values for speed
new bool:v_HEGrenadeStickPlayers;
new bool:v_HEGrenadeStickWalls;

new Float:v_HEGrenadeNormalPower;
new Float:v_HEGrenadeNormalRadius;
new Float:v_HEGrenadeStuckPower; 
new Float:v_HEGrenadeStuckRadius;

new bool:v_HEGrenadeModel;
new bool:v_EmitSounds;
new bool:v_Shake;
new bool:v_Notice;

new bool:v_CanUseSticky[MAXPLAYERS+1];


public OnPluginStart()
{
	CreateConVar("sm_snlite_version", PL_VERSION, "Allows grenades to stick to walls and players!", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	
	g_hHEGrenadeStickPlayers = CreateConVar("snlite_hegrenade_stick_to_players", "1",   "Make HE Grenades stick to players",                    FCVAR_PLUGIN);
	g_hHEGrenadeStickWalls   = CreateConVar("snlite_hegrenade_stick_to_walls",   "1",   "Make HE Grenades stick to walls",                      FCVAR_PLUGIN);
	
	g_hHEGrenadeNormalPower  = CreateConVar("snlite_hegrenade_normal_power",     "100", "Power of a HE grenade when not stuck to a player",     FCVAR_PLUGIN);
	g_hHEGrenadeNormalRadius = CreateConVar("snlite_hegrenade_normal_radius",    "350", "Radius of a HE grenade when not stuck to a player",    FCVAR_PLUGIN);
	g_hHEGrenadeStuckPower   = CreateConVar("snlite_hegrenade_stuck_power",      "300", "Power of a HE grenade when stuck to a player",         FCVAR_PLUGIN);
	g_hHEGrenadeStuckRadius  = CreateConVar("snlite_hegrenade_stuck_radius",     "350", "Radius of a HE grenade when stuck to a player",        FCVAR_PLUGIN);
	
	g_hHEGrenadeModel        = CreateConVar("snlite_hegrenade_model",            "0",   "Use a custom model for HE grenades",                   FCVAR_PLUGIN);
	g_hEmitSounds            = CreateConVar("snlite_emit_sounds",                "0",   "Play sounds when a player gets stuck",                 FCVAR_PLUGIN);
	g_hShake                 = CreateConVar("snlite_shake",                      "1",   "Shake player when hit by a stickynade",                FCVAR_PLUGIN);
	g_hNotice                = CreateConVar("snlite_notice",                     "1",   "Display StickyNades information on round start",       FCVAR_PLUGIN);
	
	OFFSET_OWNER  = FindSendPropOffs("CBaseEntity", "m_hOwnerEntity");
	OFFSET_DAMAGE = FindSendPropOffs("CBaseGrenade", "m_flDamage");
	OFFSET_RADIUS = FindSendPropOffs("CBaseGrenade", "m_DmgRadius");
	OFFSET_RENDER = FindSendPropOffs("CBaseEntity", "m_clrRender");
	
	AutoExecConfig(true, "snlite");
	LoadResources();
	
	HookEvent("round_start",    Event_RoundStart);
}

public OnConfigsExecuted()
{
	UpdateAllConVars();
}

public ConVarChanged()
{
	UpdateAllConVars();
}

UpdateAllConVars()
{
	v_HEGrenadeStickPlayers = GetConVarBool(g_hHEGrenadeStickPlayers);
	v_HEGrenadeStickWalls = GetConVarBool(g_hHEGrenadeStickWalls);

	v_HEGrenadeNormalPower = GetConVarFloat(g_hHEGrenadeNormalPower);
	v_HEGrenadeNormalRadius = GetConVarFloat(g_hHEGrenadeNormalRadius);
	v_HEGrenadeStuckPower = GetConVarFloat(g_hHEGrenadeStuckPower);
	v_HEGrenadeStuckRadius = GetConVarFloat(g_hHEGrenadeStuckRadius);
	
	v_Shake = GetConVarBool(g_hShake);
	v_Notice = GetConVarBool(g_hNotice);
}

public OnMapStart()
{
	LoadResources();
}

LoadResources()
{
	//Only update models and sound Convars on mapstart 
	//to ensure files are cached.
	if((v_HEGrenadeModel = GetConVarBool(g_hHEGrenadeModel)))
	{
		//Precache models
		PrecacheModel(MDL_BLUE, true);
		PrecacheModel(MDL_RED,  true);
		
		//Add files to downloadtable
		AddFolderToDownloadsTable("materials/models/stickynades");
		AddFolderToDownloadsTable("models/stickynades");
	}
	if((v_EmitSounds = GetConVarBool(g_hEmitSounds)))
	{
		//Precache sounds
		PrecacheSound(SND_LAUGH,  true);
		PrecacheSound(SND_SCREAM, true);
		
		//Add files to downloadtable
		AddFolderToDownloadsTable("sound/music/stickynades");
	}
}

public OnClientPostAdminCheck(client)
{
	new flags;
	
	v_CanUseSticky[client] = !GetCommandOverride("snlite_admin_only", Override_Command, flags);
	
	//Check if admin flag set
	if(!v_CanUseSticky[client])
	{	
		//Check if player has sticknades access	 
		if(CheckCommandAccess(client, "snlite_admin_only", flags))
		{
			v_CanUseSticky[client] = true;
		}
	}
}

/**
 * SDKHooks
 */
public OnEntityCreated(iEntity, const String:classname[]) 
{
	//Change Grenade model and properties before it is spawned
	if(StrEqual(classname, "hegrenade_projectile"))
    {	
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}

public OnEntitySpawned(iGrenade)
{
	// Change properties on next frame.
	CreateTimer(0.01, InitGrenade, iGrenade, TIMER_FLAG_NO_MAPCHANGE);
}

public GrenadeTouch(iGrenade, iEntity) 
{
	//Stick if player
	if(v_HEGrenadeStickPlayers && iEntity > 0 && iEntity <= MaxClients)
	{
		StickGrenade(iEntity, iGrenade);
	}
	//Stick to object
	else if(v_HEGrenadeStickWalls && GetEntityMoveType(iGrenade) != MOVETYPE_NONE)
	{
		SetEntityMoveType(iGrenade, MOVETYPE_NONE);
	}
}
/**
 * SDKHooks END
 */

public Action:InitGrenade(Handle:timer, any:iGrenade)
{
	new iClient = GetEntDataEnt2(iGrenade, OFFSET_OWNER);
	
	//Set normal grenade properties
	SetEntDataFloat(iGrenade, OFFSET_DAMAGE, v_HEGrenadeNormalPower);
	SetEntDataFloat(iGrenade, OFFSET_RADIUS, v_HEGrenadeNormalRadius);
	
	if(v_CanUseSticky[iClient])
	{	
		if(v_HEGrenadeModel)
		{
			SetEntityModel(iGrenade, GetClientTeam(iClient) == 2 ? MDL_RED : MDL_BLUE);
			SetEntData(iGrenade, OFFSET_RENDER, -1);
		}
		
		//Hook grenade collision for sticky nades
		SDKHook(iGrenade, SDKHook_StartTouch, GrenadeTouch);
	}
}

StickGrenade(iClient, iGrenade)
{	
	//stop movement
	SetEntityMoveType(iGrenade, MOVETYPE_NONE);
	
	// Stick grenade to victim
	SetVariantString("!activator");
	AcceptEntityInput(iGrenade, "SetParent", iClient);
	SetVariantString("idle");
	AcceptEntityInput(iGrenade, "SetAnimation");
		
	//set properties
	SetEntDataFloat(iGrenade, OFFSET_DAMAGE, v_HEGrenadeStuckPower);
	SetEntDataFloat(iGrenade, OFFSET_RADIUS, v_HEGrenadeStuckRadius);
		
	// If shake is enabled, shake victim
	if(v_Shake)
	{
		Shake(iClient, AMP_SHAKE, DUR_SHAKE);
	}
	
	new iThrower = GetEntDataEnt2(iGrenade, OFFSET_OWNER);
	
	//Rare case where owner of grenade is gone when it sticks.
	//Rare case where owner of grenade is gone when it sticks.
	if(iThrower > 0)
	{	
		if(v_EmitSounds)
		{
			for (new i=0; i<5; i++)
			{
				EmitSoundToClient(iClient, SND_SCREAM, SOUND_FROM_PLAYER, _, SNDLEVEL_RAIDSIREN, SND_NOFLAGS);
				EmitSoundToClient(iThrower, SND_LAUGH, SOUND_FROM_PLAYER, _, SNDLEVEL_RAIDSIREN, SND_NOFLAGS);
			}
		}
		
		//Print stuck message
		PrintToChatAll("\x01 \x04[StickyNades] \x05%N \x01stuck \x05%N \x01with a \x04Frag Grenade\x01!",iThrower,iClient);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(v_Notice)
	{
		//Print stickynades announcement
		if(v_HEGrenadeStickPlayers && g_hHEGrenadeStickWalls)
			PrintToChatAll("\x01 \x04[StickyNades] \x01Frag Grenades stick to \x05walls \x01and \x05players\x01.");
		else if(v_HEGrenadeStickPlayers)
			PrintToChatAll("\x01 \x04[StickyNades] \x01Frag Grenades stick to \x05players\x01.");
		else if(g_hHEGrenadeStickWalls)
			PrintToChatAll("\x01 \x04[StickyNades] \x01Frag Grenades stick to \x05walls\x01.");
	}
}

 /* Shake
 *  By Tsunami - Sticky Nades 1.0
 * */
stock Shake(iClient, Float:flAmplitude, Float:flDuration)
{
	new Handle:hBf = StartMessageOne("Shake", iClient);
	if(hBf)
	{
		BfWriteByte(hBf,  0);
		BfWriteFloat(hBf, flAmplitude);
		BfWriteFloat(hBf, 1.0);
		BfWriteFloat(hBf, flDuration);
		EndMessage();
	}
}

 /* AddFolderToDownloadsTable
 *  By Tsunami - Sticky Nades 1.0
 * */
stock AddFolderToDownloadsTable(const String:sDirectory[])
{
	decl String:sFile[64], String:sPath[512];
	new FileType:iType, Handle:hDir = OpenDirectory(sDirectory);
	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iType))     
	{
		if(iType == FileType_File)
		{
			Format(sPath, sizeof(sPath), "%s/%s", sDirectory, sFile);
			AddFileToDownloadsTable(sPath);
		}
	}
}
