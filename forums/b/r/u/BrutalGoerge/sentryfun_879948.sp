#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define TEAM_RED 2
#define TEAM_BLU 3
#define VERSION "2.0.0"

// --- ConVars ---
ConVar g_cvEnabled;
ConVar g_cvWinningBetray;
ConVar g_cvBetrayChance;
ConVar g_cvReactiveChance;
ConVar g_cvHeroMode;
ConVar g_cvHeroAmmoPrimary;
ConVar g_cvHeroAmmoSecondary;
ConVar g_cvBonusTime;
ConVar g_cvMpBonusRoundTime;

// --- Globals ---
bool g_bHooked = false;
bool g_bBonusRound = false;

// Hero Tracking
int g_iHero = -1;
float g_flNextRocketTime = 0.0;
float g_flNextFlareTime = 0.0;
int g_iHeroRockets = 0;
int g_iHeroFlares = 0;

public Plugin myinfo = 
{
	name = "Sentry Fun",
	author = "Goerge (Modernized)",
	description = "Restores sentry operation for losing team, turns winning sentries against them, and unleashes a Hero.",
	version = VERSION,
	url = "https://github.com/BrutalGoerge/tf2tmng"
};

public void OnPluginStart()
{
	LoadTranslations("sentryfun.phrases");
	
	// Core Plugin Settings
	g_cvEnabled = CreateConVar("sentryfun_enabled", "1", "Enable/disable the plugin and its hook", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvWinningBetray = CreateConVar("sentryfun_betray", "1", "Winning team's sentries attack members of the winning team.", 0, true, 0.0, true, 1.0);
	g_cvBetrayChance = CreateConVar("sentryfun_betray_chance", "1.00", "% chance that a sentry will betray its teammates.", 0, true, 0.0, true, 1.0);
	g_cvReactiveChance = CreateConVar("sentryfun_reactivate_chance", "1.00", "% chance that a sentry will reactivate if its been disabled.", 0, true, 0.0, true, 1.0);
	
	// Hero Settings
	g_cvHeroMode = CreateConVar("sentryfun_hero_mode", "1", "Give one losing player 2000 HP and crits to fight back.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvHeroAmmoPrimary = CreateConVar("sentryfun_hero_ammo_primary", "5", "Amount of primary shots (rockets) the hero gets.", 0, true, 1.0);
	g_cvHeroAmmoSecondary = CreateConVar("sentryfun_hero_ammo_secondary", "5", "Amount of secondary shots (flares) the hero gets.", 0, true, 1.0);
	g_cvBonusTime = CreateConVar("sentryfun_bonusround_time", "15", "Override for TF2 bonus round time.", 0, true, 5.0, true, 30.0);
	
	CreateConVar("sentryfun_version", VERSION, "Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Remove the hardcoded 15-second upper bound limit on the native mp_bonusroundtime ConVar
	g_cvMpBonusRoundTime = FindConVar("mp_bonusroundtime");
	if (g_cvMpBonusRoundTime != null)
	{
		g_cvMpBonusRoundTime.SetBounds(ConVarBound_Upper, true, 30.0);
	}
	
	// Hooks to apply changes dynamically
	g_cvEnabled.AddChangeHook(EnabledChange);
	g_cvBonusTime.AddChangeHook(BonusTimeChange);
	
	AutoExecConfig(true, "plugin.sentryfun");
}

public void OnMapStart()
{
	// Precache custom audio effects
	PrecacheSound("ui/halloween_boss_summoned_fx.wav", true);
	PrecacheSound("weapons/rocket_shoot_crit.wav", true);
	PrecacheSound("weapons/flaregun_shoot_crit.wav", true);
	// Note: We don't precache announcer_am_lastmanalive01.wav here because we trigger it natively via playgamesound
}

public void OnConfigsExecuted()
{
	if (g_cvEnabled.BoolValue)
	{
		HookEvents();
	}
	else
	{
		UnhookEvents();
	}
	
	SyncBonusTime();
}

public void EnabledChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar.BoolValue)
	{
		HookEvents();
	}
	else
	{
		UnhookEvents();
	}
}

public void BonusTimeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SyncBonusTime();
}

// Forces the native TF2 bonus round time to match our custom ConVar
void SyncBonusTime()
{
	if (g_cvMpBonusRoundTime != null)
	{
		g_cvMpBonusRoundTime.SetFloat(g_cvBonusTime.FloatValue);
	}
}

void HookEvents()
{
	if (!g_bHooked)
	{
		HookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		g_bHooked = true;
	}
}

void UnhookEvents()
{
	if (g_bHooked)
	{
		UnhookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
		g_bHooked = false;
	}
}

// Triggers when a team wins the round and the bonus (humiliation) period begins
public Action Event_RoundWin(Event event, const char[] name, bool dontBroadcast)
{
	g_bBonusRound = true;
	int winningTeam = event.GetInt("team");
	
	// Ensure both teams actually have players before running the bonus round events
	if (GetTeamClientCount(TEAM_RED) > 0 && GetTeamClientCount(TEAM_BLU) > 0)
	{
		CreateTimer(0.5, Timer_SentryDelay, winningTeam, TIMER_FLAG_NO_MAPCHANGE);	
	}
	return Plugin_Continue;
}	

// Resets global states at the start of a fresh round
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bBonusRound = false;
	g_iHero = -1;
	g_flNextRocketTime = 0.0;
	g_flNextFlareTime = 0.0;
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (client == g_iHero) 
	{
		g_iHero = -1;
	}
	
	if (g_bBonusRound)
	{
		DestroySentry(client);
	}
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bBonusRound)
	{
		DestroySentry(event.GetInt("userid"));
	}
	return Plugin_Continue;
}

public Action Timer_SentryDelay(Handle timer, any team)
{
	ManipulateSentries(team);
	
	if (g_cvHeroMode.BoolValue)
	{
		MakeRandomLoserHero(team);
	}
	
	return Plugin_Handled;
}

// Rebuilds winning sentries for the losing team and revives losing sentries
void ManipulateSentries(int winningTeam)
{
	int iTeamser = GetOppositeTeamMember(winningTeam);
	
	if (iTeamser <= 0) return; 

	float fBetrayChance = g_cvBetrayChance.FloatValue;
	float fActivateChance = g_cvReactiveChance.FloatValue;
	
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != -1)
	{
		int client = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");
		if (client <= 0 || client > MaxClients) continue;

		float ran = GetRandomFloat(0.0, 1.0);
		if (GetClientTeam(client) == winningTeam)
		{
			if (g_cvWinningBetray.BoolValue && fBetrayChance >= ran)
			{
				float location[3], angle[3];
				GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", location);
				GetEntPropVector(iEnt, Prop_Send, "m_angRotation", angle);
				bool bMini = view_as<bool>(GetEntProp(iEnt, Prop_Send, "m_bMiniBuilding"));
				bool bDisposable = view_as<bool>(GetEntProp(iEnt, Prop_Send, "m_bDisposableBuilding"));
				int level = GetEntProp(iEnt, Prop_Send, "m_iUpgradeLevel");
				
				// Destroy original and replace it with a betrayed version
				AcceptEntityInput(iEnt, "Kill");
				TF2_BuildSentry(iTeamser, location, angle, level, bMini, bDisposable);
			}
		}
		else if (fActivateChance >= ran)
		{
			// Revive disabled losing sentry
			SetEntProp(iEnt, Prop_Send, "m_bDisabled", 0);
			int newHealth = GetEntProp(iEnt, Prop_Send, "m_iMaxHealth") + 100;
			SetEntProp(iEnt, Prop_Send, "m_iMaxHealth", newHealth);
			SetEntProp(iEnt, Prop_Send, "m_iHealth", newHealth);
		}
	}
}

// Selects one random player on the losing team and gives them massive health and custom projectiles
void MakeRandomLoserHero(int winningTeam)
{
	int losingTeam = (winningTeam == TEAM_RED) ? TEAM_BLU : TEAM_RED;
	int losers[MAXPLAYERS + 1];
	int loserCount = 0;
	
	// Collect valid losing players
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == losingTeam)
		{
			losers[loserCount++] = i;
		}
	}

	if (loserCount > 0)
	{
		int hero = losers[GetRandomInt(0, loserCount - 1)];
		g_iHero = hero;
		
		float currentTime = GetGameTime();
		g_flNextRocketTime = currentTime;
		g_flNextFlareTime = currentTime;
		
		// Set internal ammo count for the chosen player
		g_iHeroRockets = g_cvHeroAmmoPrimary.IntValue;
		g_iHeroFlares = g_cvHeroAmmoSecondary.IntValue;
		
		SetEntityHealth(hero, 2000);
		
		char heroName[MAX_NAME_LENGTH];
		GetClientName(hero, heroName, sizeof(heroName));
		
		// Display initial ammo count HUD
		PrintCenterText(hero, "Hero Ammo - Rockets: %d | Flares: %d", g_iHeroRockets, g_iHeroFlares);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (i == hero)
				{
					// Play character dialog natively to bypass channel interference with the 'You Failed!' sound
					ClientCommand(i, "playgamesound Announcer.AM_LastManAlive01");
					PrintToChat(i, "\x04[Sentry Fun]\x01 %t", "Hero_Self_Message");
				}
				else
				{
					// Play universal halloween sound for the rest of the server
					EmitSoundToClient(i, "ui/halloween_boss_summoned_fx.wav");
					PrintToChat(i, "\x04[Sentry Fun]\x01 %t", "Hero_Global_Message", heroName);
				}
			}
		}
	}
}

// Intercepts input every tick. Allows the Hero to shoot custom projectiles while bypassing the humiliation weapon lock.
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (g_bBonusRound && client == g_iHero)
	{
		float currentTime = GetGameTime();
		
		// Primary Fire: Rockets
		if (buttons & IN_ATTACK)
		{
			if (g_iHeroRockets > 0 && currentTime >= g_flNextRocketTime)
			{
				g_flNextRocketTime = currentTime + 0.8; // Fire rate cooldown
				g_iHeroRockets--;
				FireHeroRocket(client);
				PrintCenterText(client, "Hero Ammo - Rockets: %d | Flares: %d", g_iHeroRockets, g_iHeroFlares);
			}
		}
		// Secondary Fire: Flares
		else if (buttons & IN_ATTACK2)
		{
			if (g_iHeroFlares > 0 && currentTime >= g_flNextFlareTime)
			{
				g_flNextFlareTime = currentTime + 0.5; // Fire rate cooldown
				g_iHeroFlares--;
				FireHeroFlare(client);
				PrintCenterText(client, "Hero Ammo - Rockets: %d | Flares: %d", g_iHeroRockets, g_iHeroFlares);
			}
		}
	}
	return Plugin_Continue;
}

// Spawns a critical rocket from the player's eyes to bypass the missing weapon entities during humiliation
void FireHeroRocket(int client)
{
	int rocket = CreateEntityByName("tf_projectile_rocket");
	if (IsValidEntity(rocket))
	{
		float vPosition[3], vAngles[3], vVelocity[3];
		GetClientEyePosition(client, vPosition);
		GetClientEyeAngles(client, vAngles);
		
		// Calculate forward trajectory
		GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vVelocity, 1100.0);
		
		// Shift spawn point slightly forward so it doesn't detonate on the player's own face
		vPosition[0] += vVelocity[0] * 0.05;
		vPosition[1] += vVelocity[1] * 0.05;
		vPosition[2] += vVelocity[2] * 0.05;
		
		SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(rocket, Prop_Send, "m_bCritical", 1);
		SetEntProp(rocket, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		
		TeleportEntity(rocket, vPosition, vAngles, vVelocity);
		DispatchSpawn(rocket);
		
		// Raw projectiles have no weapon data to pull damage from. 
		// We use a memory offset relative to 'm_iDeflected' to inject 100 base damage directly.
		SetEntDataFloat(rocket, GetEntSendPropOffs(rocket, "m_iDeflected") + 4, 100.0, true);
		
		EmitSoundToAll("weapons/rocket_shoot_crit.wav", client);
	}
}

// Spawns a critical flare from the player's eyes to bypass the missing weapon entities during humiliation
void FireHeroFlare(int client)
{
	int flare = CreateEntityByName("tf_projectile_flare");
	if (IsValidEntity(flare))
	{
		float vPosition[3], vAngles[3], vVelocity[3];
		GetClientEyePosition(client, vPosition);
		GetClientEyeAngles(client, vAngles);
		
		// Calculate forward trajectory. Flares travel much faster than rockets.
		GetAngleVectors(vAngles, vVelocity, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(vVelocity, 2000.0); 
		
		// Shift spawn point slightly forward
		vPosition[0] += vVelocity[0] * 0.05;
		vPosition[1] += vVelocity[1] * 0.05;
		vPosition[2] += vVelocity[2] * 0.05;
		
		SetEntPropEnt(flare, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(flare, Prop_Send, "m_bCritical", 1);
		SetEntProp(flare, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		
		TeleportEntity(flare, vPosition, vAngles, vVelocity);
		DispatchSpawn(flare);
		
		// Inject 30 base damage into memory offset
		SetEntDataFloat(flare, GetEntSendPropOffs(flare, "m_iDeflected") + 4, 30.0, true);
		
		EmitSoundToAll("weapons/flaregun_shoot_crit.wav", client);
		
		// Hook the collision to apply afterburn to enemies
		SDKHook(flare, SDKHook_StartTouch, OnFlareTouch);
	}
}

// Handles custom flare ignition logic since the flare isn't attached to a real weapon
public Action OnFlareTouch(int entity, int other)
{
	if (other > 0 && other <= MaxClients && IsClientInGame(other) && IsPlayerAlive(other))
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (owner > 0 && owner <= MaxClients)
		{
			// Only ignite players on the opposite team
			if (GetClientTeam(other) != GetClientTeam(owner))
			{
				TF2_IgnitePlayer(other, owner);
			}
		}
	}
	return Plugin_Continue;
}

// Finds the highest scoring player on the opposing team to claim ownership of the betrayed sentries
int GetOppositeTeamMember(int team)
{
	int client = 0;
	int highScore = -1;
	int targetTeam = (team == TEAM_RED) ? TEAM_BLU : TEAM_RED;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == targetTeam)
		{
			int tempScore = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", _, i);
			if (tempScore >= highScore)
			{
				client = i;
				highScore = tempScore;
			}
		}
	}
	return client;
}

// Silently removes a player's sentry from the map
void DestroySentry(int client)
{
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != -1)
	{
		if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(iEnt, "RemoveHealth");
		}
	}
}

// Spawns and configures a fully operational sentry gun entity
void TF2_BuildSentry(int builder, const float fOrigin[3], const float fAngle[3], int level, bool mini=false, bool disposable=false, int flags=4)
{
	// Native model boundaries for miniaturized buildings
	static const float m_vecMinsMini[3] = {-15.0, -15.0, 0.0};
	static const float m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	static const float m_vecMinsDisp[3] = {-13.0, -13.0, 0.0};
	static const float m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	int sentry = CreateEntityByName("obj_sentrygun");
	
	if (IsValidEntity(sentry))
	{
		AcceptEntityInput(sentry, "SetBuilder", builder);
		DispatchKeyValueVector(sentry, "origin", fOrigin);
		DispatchKeyValueVector(sentry, "angles", fAngle);
		
		int teamSkin = GetClientTeam(builder);
		
		if (mini)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", (level == 1) ? teamSkin : teamSkin - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
		}
		else if (disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", (level == 1) ? teamSkin : teamSkin - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
		}
		else
		{
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", teamSkin - 2);
			DispatchSpawn(sentry);
		}

		// Force the sentry to instantly bypass the construction phase and become active
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 0);
		SetEntProp(sentry, Prop_Send, "m_bPlacing", 0);
		SetEntProp(sentry, Prop_Send, "m_iState", 1);
		SetEntPropFloat(sentry, Prop_Send, "m_flPercentageConstructed", 1.0);
		SetEntProp(sentry, Prop_Send, "m_bDisabled", 0);
		
		int shells = 100;
		if (level == 2) shells = 120;
		else if (level == 3) shells = 144;
		
		if (mini || disposable) shells = 150;

		SetEntProp(sentry, Prop_Send, "m_iAmmoShells", shells);
		if (level == 3)
		{
			SetEntProp(sentry, Prop_Send, "m_iAmmoRockets", 20);
		}
	}
}