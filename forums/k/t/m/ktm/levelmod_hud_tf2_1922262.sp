#include <sourcemod>
#include <sdktools>
#include <tf2_advanced>

#pragma semicolon 1

#define NO_ATTACH		0
#define ATTACH_NORMAL		1
#define ATTACH_HEAD		2

#define PLUGIN_VERSION "0.1.1"
#define SOUND_LEVELUP "misc/achievement_earned.wav"

new Handle:g_hCvarLevelUpParticles;

new Handle:g_hLevelHUD[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:hud_targetname = INVALID_HANDLE;
new Handle:g_hHudLevel;
new Handle:g_hHudExp;
new Handle:g_hHudPlus1;
new Handle:g_hHudPlus2;
new Handle:g_hHudLevelUp;
new Handle:timer_target[MAXPLAYERS+1] = INVALID_HANDLE;

new bool:g_bLevelUpParticles;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "Leveling Mod, TF2 Interface",
	author = "noodleboy347, Thrawn",
	description = "A interface fitting to tf2",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	// G A M E  C H E C K //
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(!(StrEqual(game, "tf")))
	{
		SetFailState("This plugin is not for %s", game);
	}

	g_hCvarLevelUpParticles = CreateConVar("sm_lm_levelupparticle", "1", "Enables level up particle effects", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvarLevelUpParticles, Cvar_Changed);

	HookEvent("player_spawn",       Event_PlayerSpawn);

	// O T H E R //
	g_hHudLevel = CreateHudSynchronizer();
	g_hHudExp = CreateHudSynchronizer();
	g_hHudPlus1 = CreateHudSynchronizer();
	g_hHudPlus2 = CreateHudSynchronizer();
	g_hHudLevelUp = CreateHudSynchronizer();
}

public OnMapStart() {
	PrecacheSound(SOUND_LEVELUP, true);
}

public OnConfigsExecuted()
{
	g_bLevelUpParticles = GetConVarBool(g_hCvarLevelUpParticles);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

//////////////////////////////////
//C L I E N T  C O N N E C T E D//
//////////////////////////////////
public OnClientPutInServer(client)
{
	if(lm_IsEnabled())
	{
		g_hLevelHUD[client] = CreateTimer(5.0, Timer_DrawHud, client);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if(lm_IsEnabled() && g_hLevelHUD[iClient] == INVALID_HANDLE)
	{
		g_hLevelHUD[iClient] = CreateTimer(0.5, Timer_DrawHud, iClient);
	}
}



///////////////////
//D R A W  H U D //
///////////////////
public Action:Timer_DrawHud(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new iPlayerLevel = lm_GetClientLevel(client);

		SetHudTextParams(0.14, 0.90, 1.95, 100, 200, 255, 150, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudLevel, "Level: %i", iPlayerLevel);

		SetHudTextParams(0.14, 0.93, 1.95, 255, 200, 100, 150, 0, 0.0, 0.0, 0.0);

		if(iPlayerLevel >= lm_GetLevelMax())
		{
			ShowSyncHudText(client, g_hHudExp, "XP: MAX LEVEL REACHED", lm_GetClientXP(client), lm_GetClientXPNext(client));
		}
		else
		{
			new iRequired = lm_GetXpRequiredForLevel(iPlayerLevel+1) - lm_GetXpRequiredForLevel(iPlayerLevel);
			new iAchieved = lm_GetClientXP(client) - lm_GetXpRequiredForLevel(iPlayerLevel);

			ShowSyncHudText(client, g_hHudExp, "EXP: %i/%i", iAchieved, iRequired);
		}
	}

	g_hLevelHUD[client] = CreateTimer(1.9, Timer_DrawHud, client);
	return Plugin_Handled;
}

public Action:Timer_Target(Handle:timer, any:client)
{
	new target = GetClientAimTarget(client, true);
	if(!IsClientObserver(client) && target != -1)
	{
		if(IsClientInGame(target))
		{
			new clientteam = GetClientTeam(client);
			new targetteam = GetClientTeam(target);
			if(IsPlayerAlive(target) && clientteam != targetteam && !((GetEntProp(target, Prop_Send, "m_nPlayerCond") & (TF2_PLAYERCOND_DISGUISING|TF2_PLAYERCOND_DISGUISED|TF2_PLAYERCOND_SPYCLOAK))))
			{
				SetHudTextParams(-1.0, 0.53, 5.0, 255, 160, 120, 200);
				ShowSyncHudText(client, g_hHudLevel, "Level: %i", iPlayerLevel);
			}
		}
	}
}

///////////////////////
//D I S C O N N E C T//
///////////////////////
public OnClientDisconnect(client)
{
	if(g_hLevelHUD[client]!=INVALID_HANDLE)
		CloseHandle(g_hLevelHUD[client]);
}

public lm_OnClientLevelUp(client, level, amount, bool:isLevelDown)
{
	SetHudTextParams(0.24, 0.90, 5.0, 100, 255, 100, 150, 2);

	if(isLevelDown) {
		ShowSyncHudText(client, g_hHudLevelUp, "LEVEL LOST!");
	} else {
		ShowSyncHudText(client, g_hHudLevelUp, "LEVEL UP!");

		if(TF2_IsPlayerCloaked(client))
			return;

		EmitSoundToClient(client, SOUND_LEVELUP);

		if(g_bLevelUpParticles) {
			//achieved
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);

			CreateParticle("achieved", 3.0, client, ATTACH_HEAD, 0.0, 0.0, 4.0);
		}
	}
}

public lm_OnClientExperience(client, amount, iChannel)
{
	if(client > 0) {
		if(iChannel == 0) {
			SetHudTextParams(0.30, 0.93, 1.0, 255, 100, 100, 150, 1);
			ShowSyncHudText(client, g_hHudPlus1, "+%i", amount);
		} else {
			SetHudTextParams(0.34, 0.93, 1.0, 255, 100, 100, 150, 1);
			ShowSyncHudText(client, g_hHudPlus2, "+%i", amount);
		}
	}
}


// Particles ------------------------------------------------------------------
// Particle Attachment Types  -------------------------------------------------

/* CreateParticle()
**
** Creates a particle at an entity's position. Attach determines the attachment
** type (0 = not attached, 1 = normal attachment, 2 = head attachment). Allows
** offsets from the entity's position. Returns the handle of the timer that
** deletes the particle (should you wish to trigger it early).
** ------------------------------------------------------------------------- */


stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");

	// Check if it was created correctly
	if (IsValidEdict(particle)) {
		decl Float:pos[3];

		// Get position of entity
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		// Add position offsets
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;

		// Teleport, set up
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);

		if (attach != NO_ATTACH) {
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);

			if (attach == ATTACH_HEAD) {
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}

		// All entities in presents are given a targetname to make clean up easier
		DispatchKeyValue(particle, "targetname", "present");

		// Spawn and start
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");

		return CreateTimer(time, DeleteParticle, particle);
	} else {
		LogError("Presents (CreateParticle): Could not create info_particle_system");
	}

	return INVALID_HANDLE;
}

/* DeleteParticle()
**
** Deletes a particle.
** ------------------------------------------------------------------------- */
public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEdict(particle)) {
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));

		if (StrEqual(classname, "info_particle_system", false)) {
			RemoveEdict(particle);
		}
	}
}