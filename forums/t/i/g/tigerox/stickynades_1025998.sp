#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define CLR_DEFAULT			1
#define CLR_LIGHTGREEN	3
#define CLR_GREEN				4

#define AMP_SHAKE		50.0
#define DUR_SHAKE		1.0

#define MIN_RADIUS	80.0
#define MAX_RADIUS	50000.0

#define MDL_BLUE		"models/stickynades/stickynades_blue.mdl"
#define MDL_RED			"models/stickynades/stickynades_red.mdl"

#define SND_LAUGH		"stickynades/muhahaha.wav"
#define SND_SCREAM	"stickynades/scream.wav"

#define PL_VERSION	"1.2"

//TIGEROX
//Fixed nades allways sticking to random stuff
//Fixed stuck nade strength and radius not set correctly
//Optimized for performance

public Plugin:myinfo =
{
	name        = "Sticky Nades",
	author      = "Tsunami",
	description = "Allows grenades to stick to walls and players!",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}


/**
 * Globals
 */
new Handle:g_hFlashbangEnabled = INVALID_HANDLE;
new Handle:g_hFlashbangStickPlayers = INVALID_HANDLE;
new Handle:g_hFlashbangStickThrower = INVALID_HANDLE;
new Handle:g_hFlashbangStickWalls = INVALID_HANDLE;

new Handle:g_hHEGrenadeEnabled = INVALID_HANDLE;
new Handle:g_hHEGrenadeStickPlayers = INVALID_HANDLE;
new Handle:g_hHEGrenadeStickThrower = INVALID_HANDLE;
new Handle:g_hHEGrenadeStickWalls = INVALID_HANDLE;

new Handle:g_hHEGrenadeNormalPower = INVALID_HANDLE;
new Handle:g_hHEGrenadeNormalRadius = INVALID_HANDLE;
new Handle:g_hHEGrenadeStuckPower = INVALID_HANDLE;
new Handle:g_hHEGrenadeStuckRadius = INVALID_HANDLE;
new Handle:g_hHEGrenadeModel = INVALID_HANDLE;

new Handle:g_hEmitSounds = INVALID_HANDLE;
new Handle:g_hNotice = INVALID_HANDLE;
new Handle:g_hShake = INVALID_HANDLE;

//Values for speed
new bool:v_FlashbangEnabled;
new bool:v_FlashbangStickPlayers;
new bool:v_FlashbangStickThrower; 
new bool:v_FlashbangStickWalls;   
	
new bool:v_HEGrenadeEnabled;     
new bool:v_HEGrenadeStickPlayers;
new bool:v_HEGrenadeStickThrower;
new bool:v_HEGrenadeStickWalls;

new Float:v_HEGrenadeNormalPower;
new Float:v_HEGrenadeNormalRadius;
new Float:v_HEGrenadeStuckPower; 
new Float:v_HEGrenadeStuckRadius;
new bool:v_HEGrenadeModel;
	
new bool:v_EmitSounds; 
new bool:v_Notice;
new bool:v_Shake;

/**
 * Forwards
 */
public OnPluginStart()
{
	CreateConVar("sm_stickynades_version", PL_VERSION, "Allows grenades to stick to walls and players!", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	
	g_hFlashbangEnabled      = CreateConVar("sn_flashbang_enabled",          "1",   "Make Flashbangs stick to selected objects",            FCVAR_PLUGIN);
	g_hFlashbangStickPlayers = CreateConVar("sn_flashbang_stick_to_players", "1",   "Make Flashbangs stick to players",                     FCVAR_PLUGIN);
	g_hFlashbangStickThrower = CreateConVar("sn_flashbang_stick_to_thrower", "0",   "Make Flashbangs stick to the thrower of the grenade",  FCVAR_PLUGIN);
	g_hFlashbangStickWalls   = CreateConVar("sn_flashbang_stick_to_walls",   "1",   "Make Flashbangs stick to walls",                       FCVAR_PLUGIN);
	
	g_hHEGrenadeEnabled      = CreateConVar("sn_hegrenade_enabled",          "1",   "Make HE Grenades stick to selected objects",           FCVAR_PLUGIN);
	g_hHEGrenadeStickPlayers = CreateConVar("sn_hegrenade_stick_to_players", "1",   "Make HE Grenades stick to players",                    FCVAR_PLUGIN);
	g_hHEGrenadeStickThrower = CreateConVar("sn_hegrenade_stick_to_thrower", "0",   "Make HE Grenades stick to the thrower of the grenade", FCVAR_PLUGIN);
	g_hHEGrenadeStickWalls   = CreateConVar("sn_hegrenade_stick_to_walls",   "1",   "Make HE Grenades stick to walls",                      FCVAR_PLUGIN);
	
	g_hHEGrenadeNormalPower  = CreateConVar("sn_hegrenade_normal_power",     "100", "Power of a HE grenade when not stuck to a player",     FCVAR_PLUGIN);
	g_hHEGrenadeNormalRadius = CreateConVar("sn_hegrenade_normal_radius",    "350", "Radius of a HE grenade when not stuck to a player",    FCVAR_PLUGIN);
	g_hHEGrenadeStuckPower   = CreateConVar("sn_hegrenade_stuck_power",      "300", "Power of a HE grenade when stuck to a player",         FCVAR_PLUGIN);
	g_hHEGrenadeStuckRadius  = CreateConVar("sn_hegrenade_stuck_radius",     "350", "Radius of a HE grenade when stuck to a player",        FCVAR_PLUGIN);
	g_hHEGrenadeModel        = CreateConVar("sn_hegrenade_model",            "1",   "Use a custom model for HE grenades",                   FCVAR_PLUGIN);
	
	g_hEmitSounds            = CreateConVar("sn_emit_sounds",                "1",   "Play sounds when a player gets stuck",                 FCVAR_PLUGIN);
	g_hNotice                = CreateConVar("sn_notice",                     "1",   "Display StickyNades information on round start",       FCVAR_PLUGIN);
	g_hShake                 = CreateConVar("sn_shake",                      "1",   "Shake player when hit by a stickynade",                FCVAR_PLUGIN);
	
	HookEvent("grenade_bounce", Event_GrenadeBounce);
	HookEvent("round_start",    Event_RoundStart);
	
	AutoExecConfig(true, "stickynades");
	
}

public OnConfigsExecuted()
{
	//Update Convars - might have changed
	UpdateAllConVars();
}

public ConVarChanged()
{
	//Update Convars - might have changed
	UpdateAllConVars();
}

UpdateAllConVars()
{
	v_FlashbangEnabled = GetConVarBool(g_hFlashbangEnabled);
	v_FlashbangStickPlayers = GetConVarBool(g_hFlashbangStickPlayers);
	v_FlashbangStickThrower = GetConVarBool(g_hFlashbangStickThrower);
	v_FlashbangStickWalls = GetConVarBool(g_hFlashbangStickWalls);

	v_HEGrenadeEnabled = GetConVarBool(g_hHEGrenadeEnabled);
	v_HEGrenadeStickPlayers = GetConVarBool(g_hHEGrenadeStickPlayers);
	v_HEGrenadeStickThrower = GetConVarBool(g_hHEGrenadeStickThrower);
	v_HEGrenadeStickWalls = GetConVarBool(g_hHEGrenadeStickWalls);

	v_HEGrenadeNormalPower = GetConVarFloat(g_hHEGrenadeNormalPower);
	v_HEGrenadeNormalRadius = GetConVarFloat(g_hHEGrenadeNormalRadius);
	v_HEGrenadeStuckPower = GetConVarFloat(g_hHEGrenadeStuckPower);
	v_HEGrenadeStuckRadius = GetConVarFloat(g_hHEGrenadeStuckRadius);
	v_HEGrenadeModel = GetConVarBool(g_hHEGrenadeModel);
	
	v_EmitSounds = GetConVarBool(g_hEmitSounds);
	v_Notice = GetConVarBool(g_hNotice);
	v_Shake = GetConVarBool(g_hShake);
}

public OnMapStart()
{
	// Precache models and sounds
	PrecacheModel(MDL_BLUE, true);
	PrecacheModel(MDL_RED,  true);
	
	PrecacheSound(SND_LAUGH,  true);
	PrecacheSound(SND_SCREAM, true);
	
	// If custom models are enabled, add materials and models to downloads table
	if(v_HEGrenadeModel)
	{
		AddFolderToDownloadsTable("materials/models/stickynades");
		AddFolderToDownloadsTable("models/stickynades");
	}
	// If sounds are enabled, add sounds to downloads table
	if(v_EmitSounds)
		AddFolderToDownloadsTable("sound/stickynades");
}

public OnGameFrame()
{
	// If HE grenades are disabled, ignore
	if(!v_HEGrenadeEnabled)
		return;
	
	new iClient,
			iGrenade                      = -1,
			iTeam;
	
	while((iGrenade = FindEntityByClassname(iGrenade, "hegrenade_projectile")) != -1)
	{
		iClient = GetEntPropEnt(iGrenade, Prop_Send, "m_hThrower");
		if(iClient <= 0)
			continue;
		
		iTeam   = GetClientTeam(iClient);
		if(v_HEGrenadeModel && iTeam > 1)
		{
			SetEntityModel(iGrenade, iTeam == 2 ? MDL_RED : MDL_BLUE);
			SetEntProp(iGrenade, Prop_Send, "m_clrRender", -1);
		}
		
		if(GetEntityMoveType(iGrenade) != MOVETYPE_NONE)
		{
			SetEntPropFloat(iGrenade, Prop_Send, "m_flDamage",  v_HEGrenadeNormalPower);
			SetEntPropFloat(iGrenade, Prop_Send, "m_DmgRadius", v_HEGrenadeNormalRadius);
		}
	}
}


/**
 * Events
 */
public Event_GrenadeBounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient  = GetClientOfUserId(GetEventInt(event, "userid")),
			iGrenade = GetGrenade(iClient);
	if(!iGrenade)
		return;
	
	decl String:sClass[32];
	GetEdictClassname(iGrenade, sClass, sizeof(sClass));
	
	// HE Grenade
	if(StrEqual(sClass, "hegrenade_projectile"))
	{
		// If HE grenades are disabled, ignore
		if(!v_HEGrenadeEnabled)
			return;
		
		// If HE grenades stick to players
		if(v_HEGrenadeStickPlayers)
			StickGrenade(iClient, iGrenade);
		
		// If HE grenades stick to walls, stop moving
		if(v_HEGrenadeStickWalls && GetEntityMoveType(iGrenade) != MOVETYPE_NONE)
		{
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
			SetEntPropFloat(iGrenade, Prop_Send, "m_flDamage",  v_HEGrenadeNormalPower);
			SetEntPropFloat(iGrenade, Prop_Send, "m_DmgRadius", v_HEGrenadeNormalRadius);
		}
	}
	// Flashbang
	else if(StrEqual(sClass, "flashbang_projectile"))
	{
		// If flashbangs are disabled, ignore
		if(!v_FlashbangEnabled)
			return;
		
		// If flashbangs stick to players
		if(v_FlashbangStickPlayers)
			StickGrenade(iClient, iGrenade);
		
		// If flashbangs stick to walls, stop moving
		if(v_FlashbangStickWalls)
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!v_Notice)
		return;
	
	// HE Grenades
	if(v_HEGrenadeEnabled)
	{
		if(v_HEGrenadeStickPlayers && g_hHEGrenadeStickWalls)
			PrintToChatAll("%c[StickyNades] %cFlashbangs%c stick to %cwalls%c and %cplayers%c.",
											CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		else if(v_HEGrenadeStickPlayers)
			PrintToChatAll("%c[StickyNades] %cFlashbangs%c stick to %cplayers%c.",
											CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		else if(g_hHEGrenadeStickWalls)
			PrintToChatAll("%c[StickyNades] %cFlashbangs%c stick to %cwalls%c.",
											CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
	}
	// Flashbangs
	if(v_FlashbangEnabled)
	{
		if(v_FlashbangStickPlayers && v_FlashbangStickWalls)
			PrintToChatAll("%c[StickyNades] %cFrag Grenades%c stick to %cwalls%c and %cplayers%c.",
											CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		else if(v_FlashbangStickPlayers)
			PrintToChatAll("%c[StickyNades] %cFrag Grenades%c stick to %cplayers%c.",
											CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		else if(v_FlashbangStickWalls)
			PrintToChatAll("%c[StickyNades] %cFrag Grenades%c stick to %cwalls%c.",
											CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
	}
}


/**
 * Functions
 */
GetGrenade(iClient)
{
	decl String:sClass[2][32] = {"flashbang_projectile", "hegrenade_projectile"};
	for(new i = 0, iGrenade = -1; i < sizeof(sClass); i++)
	{
		while((iGrenade = FindEntityByClassname(iGrenade, sClass[i])) != -1)
		{
			if(GetEntPropEnt(iGrenade, Prop_Send, "m_hThrower") == iClient)
				return iGrenade;
		}
	}
	return 0;
}

StickGrenade(iClient, iGrenade)
{
	decl Float:flClientOrigin[3], Float:flDistance, Float:flOrigin[3];
	GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", flOrigin);
	
	new iNear = 0, Float:flMaxRadius = MIN_RADIUS;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", flClientOrigin);
		flDistance = GetVectorDistance(flClientOrigin, flOrigin);
		if(flDistance <= flMaxRadius)
		{
			flMaxRadius = flDistance;
			iNear       = i;
		}
	}
	if(!iNear)
		return;
	
	decl String:sClass[32];
	GetEdictClassname(iGrenade, sClass, sizeof(sClass));
	
	// HE Grenade
	if(StrEqual(sClass, "hegrenade_projectile"))
	{
		// If HE grenades stick to thrower, stop moving
		if((iClient == iNear && v_HEGrenadeStickThrower) || iClient != iNear)
		{
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
			
			SetEntPropFloat(iGrenade, Prop_Send, "m_flDamage",  v_HEGrenadeStuckPower);
			SetEntPropFloat(iGrenade, Prop_Send, "m_DmgRadius", v_HEGrenadeStuckRadius);
			
			// Stick grenade to victim
			SetVariantString("!activator");
			AcceptEntityInput(iGrenade, "SetParent", iNear);
			SetVariantString("idle");
			AcceptEntityInput(iGrenade, "SetAnimation");
				
			SetEntProp(iGrenade,       Prop_Data, "m_nSolidType",  0);
			SetEntPropVector(iGrenade, Prop_Send, "m_angRotation", Float:{0.0, 0.0, 0.0});
				
			// If sounds are enabled, emit them
			if(v_EmitSounds)
				EmitSoundToClient(iNear, SND_SCREAM);
				
			// If shake is enabled, shake victim
			if(v_Shake)
				Shake(iNear, AMP_SHAKE, DUR_SHAKE);
				
			if(iClient == iNear)
				PrintToChatAll("%c[StickyNades] %c%N%c stuck himself with a %cFrag Grenade%c!",
												CLR_GREEN, CLR_LIGHTGREEN, iClient, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
			else
				PrintToChatAll("%c[StickyNades] %c%N%c stuck %c%N%c with a %cFrag Grenade%c!",
												CLR_GREEN, CLR_LIGHTGREEN, iClient, CLR_DEFAULT, CLR_LIGHTGREEN, iNear, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		}
		// Flashbang
	}
	else if(StrEqual(sClass, "flashbang_projectile"))
	{
		// If flashbangs stick to thrower, stop moving
		if((iClient == iNear && v_FlashbangStickThrower) || iClient != iNear)
		{
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
				
			// Stick grenade to victim
			SetVariantString("!activator");
			AcceptEntityInput(iGrenade, "SetParent", iNear);
			SetVariantString("idle");
			AcceptEntityInput(iGrenade, "SetAnimation");
				
			SetEntProp(iGrenade,       Prop_Data, "m_nSolidType",  0);
			SetEntPropVector(iGrenade, Prop_Send, "m_angRotation", Float:{0.0, 0.0, 0.0});
				
			// If sounds are enabled, emit them
			if(v_EmitSounds)
				EmitSoundToClient(iNear, SND_SCREAM);
				
			// If shake is enabled, shake victim
			if(v_Shake)
				Shake(iNear, AMP_SHAKE, DUR_SHAKE);
				
			if(iClient == iNear)
				PrintToChatAll("%c[StickyNades] %c%N%c stuck himself with a %cFlashbang%c!",
												CLR_GREEN, CLR_LIGHTGREEN, iClient, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
			else
				PrintToChatAll("%c[StickyNades] %c%N%c stuck %c%N%c with a %cFlashbang%c!",
												CLR_GREEN, CLR_LIGHTGREEN, iClient, CLR_DEFAULT, CLR_LIGHTGREEN, iNear, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		}
	}
	
	// If sounds are enabled, emit them
	if(v_EmitSounds && iClient != iNear)
		EmitSoundToClient(iClient, SND_LAUGH);
}


/**
 * Stocks
 */
stock AddFolderToDownloadsTable(const String:sDirectory[], bool:bRecursive = false)
{
	decl String:sFile[64], String:sPath[512];
	new FileType:iType, Handle:hDir = OpenDirectory(sDirectory);
	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iType))     
	{
		if(iType      == FileType_Directory && bRecursive)         
			AddFolderToDownloadsTable(sFile);
		else if(iType == FileType_File)
		{
			Format(sPath, sizeof(sPath), "%s/%s", sDirectory, sFile);
			AddFileToDownloadsTable(sPath);
		}
	}
}

stock Shake(iClient, Float:flAmplitude, Float:flDuration)
{
	new Handle:hBf = StartMessageOne("Shake", iClient);
	if(!hBf)
		return;
	
	BfWriteByte(hBf,  0);
	BfWriteFloat(hBf, flAmplitude);
	BfWriteFloat(hBf, 1.0);
	BfWriteFloat(hBf, flDuration);
	EndMessage();
}