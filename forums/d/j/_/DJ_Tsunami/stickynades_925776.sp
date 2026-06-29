#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define CLR_DEFAULT			1
#define CLR_LIGHTGREEN	3
#define CLR_GREEN				4

#define AMP_SHAKE		50.0
#define DUR_SHAKE		1.0

#define MAX_RADIUS	80.0

#define PL_VERSION	"1.1.0"

public Plugin myinfo =
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
static const char MDL_BLUE[] = "models/stickynades/stickynades_blue_fixed.mdl";
static const char MDL_RED[]  = "models/stickynades/stickynades_red_fixed.mdl";

static const char SND_LAUGH[]  = "sound/stickynades/muhahaha.mp3";
static const char SND_SCREAM[] = "sound/stickynades/scream.mp3";

ConVar g_hFlashbangEnabled;
ConVar g_hFlashbangStickPlayers;
ConVar g_hFlashbangStickThrower;
ConVar g_hFlashbangStickWalls;

ConVar g_hHEGrenadeEnabled;
ConVar g_hHEGrenadeStickPlayers;
ConVar g_hHEGrenadeStickThrower;
ConVar g_hHEGrenadeStickWalls;

ConVar g_hHEGrenadeNormalPower;
ConVar g_hHEGrenadeNormalRadius;
ConVar g_hHEGrenadeStuckPower;
ConVar g_hHEGrenadeStuckRadius;
ConVar g_hHEGrenadeModel;

ConVar g_hEmitSounds;
ConVar g_hNotice;
ConVar g_hShake;


/**
 * Forwards
 */
public void OnPluginStart()
{
	CreateConVar("sm_stickynades_version", PL_VERSION, "Allows grenades to stick to walls and players!", FCVAR_NOTIFY);

	g_hFlashbangEnabled      = CreateConVar("sn_flashbang_enabled",          "1",   "Make Flashbangs stick to selected objects");
	g_hFlashbangStickPlayers = CreateConVar("sn_flashbang_stick_to_players", "1",   "Make Flashbangs stick to players");
	g_hFlashbangStickThrower = CreateConVar("sn_flashbang_stick_to_thrower", "0",   "Make Flashbangs stick to the thrower of the grenade");
	g_hFlashbangStickWalls   = CreateConVar("sn_flashbang_stick_to_walls",   "1",   "Make Flashbangs stick to walls");

	g_hHEGrenadeEnabled      = CreateConVar("sn_hegrenade_enabled",          "1",   "Make HE Grenades stick to selected objects");
	g_hHEGrenadeStickPlayers = CreateConVar("sn_hegrenade_stick_to_players", "1",   "Make HE Grenades stick to players");
	g_hHEGrenadeStickThrower = CreateConVar("sn_hegrenade_stick_to_thrower", "0",   "Make HE Grenades stick to the thrower of the grenade");
	g_hHEGrenadeStickWalls   = CreateConVar("sn_hegrenade_stick_to_walls",   "1",   "Make HE Grenades stick to walls");

	g_hHEGrenadeNormalPower  = CreateConVar("sn_hegrenade_normal_power",     "100", "Power of a HE grenade when not stuck to a player");
	g_hHEGrenadeNormalRadius = CreateConVar("sn_hegrenade_normal_radius",    "350", "Radius of a HE grenade when not stuck to a player");
	g_hHEGrenadeStuckPower   = CreateConVar("sn_hegrenade_stuck_power",      "300", "Power of a HE grenade when stuck to a player");
	g_hHEGrenadeStuckRadius  = CreateConVar("sn_hegrenade_stuck_radius",     "350", "Radius of a HE grenade when stuck to a player");
	g_hHEGrenadeModel        = CreateConVar("sn_hegrenade_model",            "1",   "Use a custom model for HE grenades");

	g_hEmitSounds            = CreateConVar("sn_emit_sounds",                "1",   "Play sounds when a player gets stuck");
	g_hNotice                = CreateConVar("sn_notice",                     "1",   "Display StickyNades information on round start");
	g_hShake                 = CreateConVar("sn_shake",                      "1",   "Shake player when hit by a stickynade");

	HookEvent("grenade_bounce", Event_GrenadeBounce);
	HookEvent("round_start",    Event_RoundStart);

	AutoExecConfig(true, "stickynades");
}

public void OnConfigsExecuted()
{
	// If custom models are enabled
	if (g_hHEGrenadeModel.BoolValue)
	{
		// Precache models
		PrecacheModel(MDL_BLUE, true);
		PrecacheModel(MDL_RED,  true);

		// Add materials and models to downloads table
		AddFileToDownloadsTable("materials/models/stickynades/stickynades_blue.vmt");
		AddFileToDownloadsTable("materials/models/stickynades/stickynades_blue.vtf");
		AddFileToDownloadsTable("materials/models/stickynades/stickynades_red.vmt");
		AddFileToDownloadsTable("materials/models/stickynades/stickynades_red.vtf");

		AddFileToDownloadsTable(MDL_BLUE);
		AddFileToDownloadsTable("models/stickynades/stickynades_blue_fixed.dx80.vtx");
		AddFileToDownloadsTable("models/stickynades/stickynades_blue_fixed.dx90.vtx");
		AddFileToDownloadsTable("models/stickynades/stickynades_blue_fixed.phy");
		AddFileToDownloadsTable("models/stickynades/stickynades_blue_fixed.sw.vtx");
		AddFileToDownloadsTable("models/stickynades/stickynades_blue_fixed.vvd");

		AddFileToDownloadsTable(MDL_RED);
		AddFileToDownloadsTable("models/stickynades/stickynades_red_fixed.dx80.vtx");
		AddFileToDownloadsTable("models/stickynades/stickynades_red_fixed.dx90.vtx");
		AddFileToDownloadsTable("models/stickynades/stickynades_red_fixed.phy");
		AddFileToDownloadsTable("models/stickynades/stickynades_red_fixed.sw.vtx");
		AddFileToDownloadsTable("models/stickynades/stickynades_red_fixed.vvd");
	}
	// If sounds are enabled
	if (g_hEmitSounds.BoolValue)
	{
		// Precache sounds
		PrecacheSound(SND_LAUGH[6],  true);
		PrecacheSound(SND_SCREAM[6], true);

		// Add sounds to downloads table
		AddFileToDownloadsTable(SND_LAUGH);
		AddFileToDownloadsTable(SND_SCREAM);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "hegrenade_projectile") && g_hHEGrenadeEnabled.BoolValue)
		SDKHook(entity, SDKHook_SpawnPost, OnHEGrenadeSpawned);
}

public void OnHEGrenadeSpawned(int entity)
{
	RequestFrame(InitHEGrenade, entity);
}

void InitHEGrenade(int iGrenade)
{
	if (!IsValidEntity(iGrenade))
		return;

	int iThrower = GetEntPropEnt(iGrenade, Prop_Send, "m_hThrower");
	if (iThrower <= 0)
		return;

	int iTeam    = GetClientTeam(iThrower);
	if (g_hHEGrenadeModel.BoolValue && iTeam > 1)
	{
		SetEntityModel(iGrenade, iTeam == 2 ? MDL_RED : MDL_BLUE);
		SetEntProp(iGrenade, Prop_Send, "m_clrRender", -1);
	}

	SetEntPropFloat(iGrenade, Prop_Send, "m_flDamage",  g_hHEGrenadeNormalPower.FloatValue);
	SetEntPropFloat(iGrenade, Prop_Send, "m_DmgRadius", g_hHEGrenadeNormalRadius.FloatValue);
}


/**
 * Events
 */
public void Event_GrenadeBounce(Event event, const char[] name, bool dontBroadcast)
{
	int iThrower = GetClientOfUserId(event.GetInt("userid")),
		iGrenade = GetGrenade(iThrower);
	if (!iGrenade)
		return;

	char sClass[32];
	GetEdictClassname(iGrenade, sClass, sizeof(sClass));

	// HE Grenade
	if (StrEqual(sClass, "hegrenade_projectile"))
	{
		// If HE grenades are disabled, ignore
		if (!g_hHEGrenadeEnabled.BoolValue)
			return;

		// If HE grenades stick to players
		if (g_hHEGrenadeStickPlayers.BoolValue)
			StickGrenade(iThrower, iGrenade);

		// If HE grenades stick to walls, stop moving
		if (g_hHEGrenadeStickWalls.BoolValue)
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
	}
	// Flashbang
	else if (StrEqual(sClass, "flashbang_projectile"))
	{
		// If flashbangs are disabled, ignore
		if (!g_hFlashbangEnabled.BoolValue)
			return;

		// If flashbangs stick to players
		if (g_hFlashbangStickPlayers.BoolValue)
			StickGrenade(iThrower, iGrenade);

		// If flashbangs stick to walls, stop moving
		if (g_hFlashbangStickWalls.BoolValue)
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hNotice.BoolValue)
		return;

	// HE Grenades
	if (g_hHEGrenadeEnabled.BoolValue)
	{
		bool bStickPlayers = g_hHEGrenadeStickPlayers.BoolValue,
			 bStickWalls   = g_hHEGrenadeStickWalls.BoolValue;

		if (bStickPlayers && bStickWalls)
			PrintToChatAll("%c[StickyNades] %cFrag Grenades%c stick to %cwalls%c and %cplayers%c.",
							CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		else if (bStickPlayers)
			PrintToChatAll("%c[StickyNades] %cFrag Grenades%c stick to %cplayers%c.",
							CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		else if (bStickWalls)
			PrintToChatAll("%c[StickyNades] %cFrag Grenades%c stick to %cwalls%c.",
							CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
	}
	// Flashbangs
	if (g_hFlashbangEnabled.BoolValue)
	{
		bool bStickPlayers = g_hFlashbangStickPlayers.BoolValue,
			 bStickWalls   = g_hFlashbangStickWalls.BoolValue;

		if (bStickPlayers && bStickWalls)
			PrintToChatAll("%c[StickyNades] %cFlashbangs%c stick to %cwalls%c and %cplayers%c.",
							CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		else if (bStickPlayers)
			PrintToChatAll("%c[StickyNades] %cFlashbangs%c stick to %cplayers%c.",
							CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		else if (bStickWalls)
			PrintToChatAll("%c[StickyNades] %cFlashbangs%c stick to %cwalls%c.",
							CLR_GREEN, CLR_LIGHTGREEN, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
	}
}


/**
 * Functions
 */
int GetGrenade(int iThrower)
{
	char sClass[2][32] = {"flashbang_projectile", "hegrenade_projectile"};
	for (int i = 0, iGrenade; i < sizeof(sClass); i++)
	{
		iGrenade = MaxClients + 1;
		while ((iGrenade = FindEntityByClassname(iGrenade, sClass[i])) != -1)
		{
			if (GetEntPropEnt(iGrenade, Prop_Send, "m_hThrower") == iThrower)
				return iGrenade;
		}
	}
	return 0;
}

void StickGrenade(int iThrower, int iGrenade)
{
	float flClientOrigin[3], flDistance, flGrenadeOrigin[3];
	GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", flGrenadeOrigin);

	int iVictim;
	float flMaxRadius = MAX_RADIUS;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		GetEntPropVector(i, Prop_Send, "m_vecOrigin", flClientOrigin);
		flDistance = GetVectorDistance(flClientOrigin, flGrenadeOrigin);
		if (flDistance <= flMaxRadius)
		{
			flMaxRadius = flDistance;
			iVictim     = i;
		}
	}
	if (!iVictim)
		return;

	char sClass[32];
	GetEdictClassname(iGrenade, sClass, sizeof(sClass));

	// HE Grenade
	if (StrEqual(sClass, "hegrenade_projectile"))
	{
		// If thrower is not the victim or HE grenades stick to thrower
		if (iThrower != iVictim || g_hHEGrenadeStickThrower.BoolValue)
		{
			// Remove collision and stop moving
			SetEntProp(iGrenade, Prop_Send, "m_CollisionGroup", 1);
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);

			// If sounds are enabled, emit them
			if (g_hEmitSounds.BoolValue)
				ClientCommand(iVictim, "play *%s", SND_SCREAM[6]);

			// If shake is enabled, shake victim
			if (g_hShake.BoolValue)
				Shake(iVictim, AMP_SHAKE, DUR_SHAKE);

			// Stick grenade to victim
			SetVariantString("!activator");
			AcceptEntityInput(iGrenade, "SetParent", iVictim);
			SetVariantString("idle");
			AcceptEntityInput(iGrenade, "SetAnimation");

			SetEntPropFloat(iGrenade, Prop_Send, "m_flDamage",  g_hHEGrenadeStuckPower.FloatValue);
			SetEntPropFloat(iGrenade, Prop_Send, "m_DmgRadius", g_hHEGrenadeStuckRadius.FloatValue);

			if (iThrower == iVictim)
				PrintToChatAll("%c[StickyNades] %c%N%c stuck themself with a %cFrag Grenade%c!",
								CLR_GREEN, CLR_LIGHTGREEN, iThrower, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
			else
				PrintToChatAll("%c[StickyNades] %c%N%c stuck %c%N%c with a %cFrag Grenade%c!",
								CLR_GREEN, CLR_LIGHTGREEN, iThrower, CLR_DEFAULT, CLR_LIGHTGREEN, iVictim, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		}
	}
	// Flashbang
	else if (StrEqual(sClass, "flashbang_projectile"))
	{
		// If thrower is not the victim or flashbangs stick to thrower
		if (iThrower != iVictim || g_hFlashbangStickThrower.BoolValue)
		{
			// Remove collision and stop moving
			SetEntProp(iGrenade, Prop_Send, "m_CollisionGroup", 1);
			SetEntityMoveType(iGrenade, MOVETYPE_NONE);

			// If sounds are enabled, emit them
			if (g_hEmitSounds.BoolValue)
				ClientCommand(iVictim, "play *%s", SND_SCREAM[6]);

			// If shake is enabled, shake victim
			if (g_hShake.BoolValue)
				Shake(iVictim, AMP_SHAKE, DUR_SHAKE);

			// Stick grenade to victim
			SetVariantString("!activator");
			AcceptEntityInput(iGrenade, "SetParent", iVictim);
			SetVariantString("idle");
			AcceptEntityInput(iGrenade, "SetAnimation");

			if (iThrower == iVictim)
				PrintToChatAll("%c[StickyNades] %c%N%c stuck themself with a %cFlashbang%c!",
								CLR_GREEN, CLR_LIGHTGREEN, iThrower, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
			else
				PrintToChatAll("%c[StickyNades] %c%N%c stuck %c%N%c with a %cFlashbang%c!",
								CLR_GREEN, CLR_LIGHTGREEN, iThrower, CLR_DEFAULT, CLR_LIGHTGREEN, iVictim, CLR_DEFAULT, CLR_LIGHTGREEN, CLR_DEFAULT);
		}
	}

	// If thrower is not the victim and sounds are enabled, emit them
	if (iThrower != iVictim && g_hEmitSounds.BoolValue)
		ClientCommand(iThrower, "play *%s", SND_LAUGH[6]);
}


/**
 * Stocks
 */
stock void Shake(int iClient, float flAmplitude, float flDuration)
{
	Handle hMsg = StartMessageOne("Shake", iClient);
	if (!hMsg)
		return;

	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf hPb = UserMessageToProtobuf(hMsg);
		hPb.SetInt("command", 0);
		hPb.SetFloat("local_amplitude", flAmplitude);
		hPb.SetFloat("frequency", 1.0);
		hPb.SetFloat("duration", flDuration);
	}
	else
	{
		BfWrite hBf = UserMessageToBfWrite(hMsg);
		hBf.WriteByte(0);
		hBf.WriteFloat(flAmplitude);
		hBf.WriteFloat(1.0);
		hBf.WriteFloat(flDuration);
	}
	EndMessage();
}
