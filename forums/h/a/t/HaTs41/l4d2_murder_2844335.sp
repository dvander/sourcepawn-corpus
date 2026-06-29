#pragma semicolon 1
#pragma newdecls required
#include <colors>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "L4D2 Murder Gamemode",
	author = "Not HaTs",
	description = "Social deduction Murder gamemode for Left 4 Dead 2",
	version = PLUGIN_VERSION,
	url = ""
};

// Roles
enum {
	ROLE_NONE = 0,
	ROLE_BYSTANDER,
	ROLE_GUNNER,
	ROLE_MURDERER
};

int g_iPlayerRole[MAXPLAYERS + 1];
char g_szPlayerFakeName[MAXPLAYERS + 1][64];
int g_iPlayerColor[MAXPLAYERS + 1][3];
int g_iLastAimTarget[MAXPLAYERS + 1];
Handle g_hKnifeRegenTimer = INVALID_HANDLE;
Handle g_hKnifeDelayTimer = INVALID_HANDLE;
// Name Pool
char g_szNameList[64][64];
int g_iTotalNames = 0;

int g_iColors[10][3] = {
	{255, 0, 0}, {0, 255, 0}, {0, 0, 255},
	{255, 255, 0}, {255, 0, 255}, {0, 255, 255},
	{255, 128, 0}, {255, 192, 203}, {128, 128, 128}, {255, 255, 255}
};

char g_szAllModels[8][] = {
	"models/survivors/survivor_gambler.mdl", // 0
	"models/survivors/survivor_producer.mdl", // 1
	"models/survivors/survivor_coach.mdl", // 2
	"models/survivors/survivor_mechanic.mdl", // 3
	"models/survivors/survivor_namvet.mdl", // 4
	"models/survivors/survivor_teenangst.mdl", // 5
	"models/survivors/survivor_biker.mdl", // 6
	"models/survivors/survivor_manager.mdl" // 7
};
int g_iAllCharacters[8] = {0, 1, 2, 3, 4, 5, 6, 7};
char g_szCurrentRoundModel[PLATFORM_MAX_PATH];
int g_iCurrentRoundCharacter;
// Sprites
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iSmokeModel = -1;

// Game State
bool g_bRoundLive = false;
bool g_bKnifeTimerStarted = false;
int g_iMurderer = 0;
int g_iGunner = 0;
int g_iCurrentRoundCount = 0;
float g_fGunnerPenaltyEnd[MAXPLAYERS + 1];

// Time & Smoke
ConVar g_cvRoundTime;
ConVar g_cvSmokeTime;
int g_iRoundTimeRemaining = 300;
int g_iTimeSinceLastKill = 0;
int g_iMurdererSmokeEnt = -1;


// ConVars
ConVar g_cvDeaglePenaltyTime;
ConVar g_cvKnifeRegenTime;
ConVar g_cvKnifeRegenDelay;
float g_fSpawnPoints[256][3];
int g_iSpawnCount = 0;

public void OnPluginStart()
{
	// Hooks for game events
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	// ConVars
	g_cvDeaglePenaltyTime = CreateConVar("murder_deagle_penalty_time", "20.0", "Time in seconds for Gunner penalty after shooting innocent");
	g_cvKnifeRegenTime = CreateConVar("murder_knife_regen_time", "60.0", "Time in seconds for Murderer knife to regenerate");
	// Delay before starting regen countdown (so player can pick up thrown knife)
	g_cvKnifeRegenDelay = CreateConVar("murder_knife_regen_delay", "10.0", "Delay in seconds after losing knife before regen countdown/message starts");
	g_cvRoundTime = CreateConVar("murder_round_time", "300", "Round time limit in seconds");
	g_cvSmokeTime = CreateConVar("murder_smoke_time", "90", "Time in seconds without kills before Murderer smokes");

	// SDKHooks for all clients
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}

    
	// Create Timers
	CreateTimer(1.0, Timer_HUDUpdate, _, TIMER_REPEAT);
	CreateTimer(0.4, Timer_Footprints, _, TIMER_REPEAT);
	
	// Disable Director
	SetConVarInt(FindConVar("director_no_mobs"), 1);
	SetConVarInt(FindConVar("director_no_specials"), 1);
	SetConVarInt(FindConVar("director_no_bosses"), 1);
	SetConVarInt(FindConVar("z_common_limit"), 0);
}

public void OnMapStart()
{
	PrecacheModel("particle/smokestack.vmt");
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_iSmokeModel = PrecacheModel("sprites/steam1.vmt");
	PrecacheSound("player/survivor/voice/gambler/deathscream06.wav");
	PrecacheSound("player/survivor/voice/coach/deathscream07.wav");
	PrecacheSound("player/survivor/voice/mechanic/deathscream05.wav");
	PrecacheSound("buttons/blip2.wav");
	
	for (int i = 0; i < 8; i++)
	{
		PrecacheModel(g_szAllModels[i]);
	}
	
	LoadNames();
}

void LoadNames()
{
	g_iTotalNames = 0;
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/murder_names.txt");
	File file = OpenFile(path, "r");
	if (file != null)
	{
		char line[64];
		while (!file.EndOfFile() && file.ReadLine(line, sizeof(line)) && g_iTotalNames < 64)
		{
			TrimString(line);
			if (line[0] != '\0')
			{
				strcopy(g_szNameList[g_iTotalNames], sizeof(g_szNameList[]), line);
				g_iTotalNames++;
			}
		}
		file.Close();
	}
	else
	{
		LogError("Murder: No se pudo abrir configs/murder_names.txt");
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "weapon_") == 0)
	{
		SDKHook(entity, SDKHook_SetTransmit, OnWeaponTransmit);
	}
}

// ------------------------------------------------------------------------
// Round Logic
// ------------------------------------------------------------------------
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundLive = false;
	
	// Strip all entities we don't want (medkits, pills, defibs, primary weapons)
	StripMapEntities();
}

public void OnRoundIsLive()
{
	// Ensure the map is completely clean of previous round weapons without wiping spawn data
	CleanDroppedWeapons();
	
	// Desactivar rescue closets
    ConVar hRescue = FindConVar("rescue_min_dead_time");
    if (hRescue != null) hRescue.SetInt(99999);
    
    ConVar hClosets = FindConVar("director_no_rescue_closets");
    if (hClosets != null) hClosets.SetInt(1);
	g_bRoundLive = true;
	g_iRoundTimeRemaining = g_cvRoundTime.IntValue;
	g_iTimeSinceLastKill = 0;
	
	int randModel = GetRandomInt(0, 7);
	strcopy(g_szCurrentRoundModel, sizeof(g_szCurrentRoundModel), g_szAllModels[randModel]);
	g_iCurrentRoundCharacter = g_iAllCharacters[randModel];
	
	RemoveSmoke();
	AssignFakeNames();
	AssignRoles();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundLive = false;
	g_iMurderer = 0;
	g_iGunner = 0;
	g_bKnifeTimerStarted = false;
	RemoveSmoke();

	if (g_hKnifeRegenTimer != INVALID_HANDLE)
	{
		KillTimer(g_hKnifeRegenTimer);
		g_hKnifeRegenTimer = INVALID_HANDLE;
	}
	if (g_hKnifeDelayTimer != INVALID_HANDLE)
	{
		KillTimer(g_hKnifeDelayTimer);
		g_hKnifeDelayTimer = INVALID_HANDLE;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iPlayerRole[i] = ROLE_NONE;
		g_fGunnerPenaltyEnd[i] = 0.0;
		g_iLastAimTarget[i] = -1;

		if (IsClientInGame(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.0);
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}
}

void AssignRoles()
{
	int survivors[MAXPLAYERS+1];
	int survivorCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) // Survivor team
		{
			survivors[survivorCount++] = i;
			g_iPlayerRole[i] = ROLE_BYSTANDER;
			
			// Strip standard weapons
			RemoveAllWeapons(i);
		}
	}
	
	if (survivorCount < 2)
	{
		PrintToChatAll("\x01 \x04[Murder]\x01 Not enough players to start!");
		g_bRoundLive = false;
		return;
	}
	
	// Pick Murderer
	int murdererIdx = GetRandomInt(0, survivorCount - 1);
	g_iMurderer = survivors[murdererIdx];
	g_iPlayerRole[g_iMurderer] = ROLE_MURDERER;
	
	// Pick Gunner
	int gunnerIdx;
	do {
		gunnerIdx = GetRandomInt(0, survivorCount - 1);
	} while (gunnerIdx == murdererIdx && survivorCount > 1);
	
	g_iGunner = survivors[gunnerIdx];
	g_iPlayerRole[g_iGunner] = ROLE_GUNNER;
	
	// Give Weapons & Dummy Slot
	GiveMurdererKnife(g_iMurderer);
	GiveGunnerDeagle(g_iGunner);
	
	for (int i = 0; i < survivorCount; i++)
	{
		int client = survivors[i];
		GiveDummyPrimary(client);
		// Switch to dummy slot to look innocent
		FakeClientCommand(client, "use weapon_pain_pills");
		
		// Apply native model and character to force identical survivors
		SetEntityModel(client, g_szCurrentRoundModel);
		SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iCurrentRoundCharacter);
		
		int totalMins = g_cvRoundTime.IntValue / 60;
		int totalSecs = g_cvRoundTime.IntValue % 60;
		
		CPrintToChat(client, "{olive}[Murder]{default} Tiempo de ronda: {green}%02d:%02d{default} | Tu nombre es: {green}%s", totalMins, totalSecs, g_szPlayerFakeName[client]);
		
		DataPack pack1;
		CreateDataTimer(1.5, Timer_PrintRoleMessage, pack1);
		pack1.WriteCell(GetClientUserId(client));
		pack1.WriteCell(client == g_iMurderer ? 1 : (client == g_iGunner ? 2 : 3));
		
		DataPack pack2;
		CreateDataTimer(3.5, Timer_PrintRoleTask, pack2);
		pack2.WriteCell(GetClientUserId(client));
		pack2.WriteCell(client == g_iMurderer ? 1 : (client == g_iGunner ? 2 : 3));
		
		// Freeze and blind
		SetEntityFlags(client, GetEntityFlags(client) | FL_FROZEN);
		PerformFadeBlack(client, 6);
	}
	
	int rScream = GetRandomInt(1, 3);
	if (rScream == 1) EmitSoundToAll("player/survivor/voice/gambler/deathscream06.wav");
	else if (rScream == 2) EmitSoundToAll("player/survivor/voice/coach/deathscream07.wav");
	else EmitSoundToAll("player/survivor/voice/mechanic/deathscream05.wav");
	
	CreateTimer(6.0, Timer_UnfreezeAll);
	
	ScatterPlayers();
}

public Action Timer_UnfreezeAll(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			SetEntityFlags(i, GetEntityFlags(i) & ~FL_FROZEN);
			PerformFade(i, 0); // Clear fade
		}
	}
	return Plugin_Stop;
}

public Action Timer_PrintRoleMessage(Handle timer, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	int roleType = pack.ReadCell();
	
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		if (roleType == 1) // Murderer
		{
			CPrintToChat(client, "{olive}[Murder]{default} Eres el {red}murderer");
		}
		else if (roleType == 2) // Gunner
		{
			CPrintToChat(client, "{olive}[Murder]{default} Eres un {blue}bystander{default}, {green}con un arma secreta");
		}
		else // Bystander
		{
			CPrintToChat(client, "{olive}[Murder]{default} Eres un {blue}bystander{default}");
		}
	}
	return Plugin_Stop;
}

public Action Timer_PrintRoleTask(Handle timer, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	int roleType = pack.ReadCell();
	
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		if (roleType == 1)
			CPrintToChat(client, "{olive}[Murder]{default} Mata a todos. No dejes que te atrapen");
		else if (roleType == 2)
			CPrintToChat(client, "{olive}[Murder]{default} Hay un {red}murderer{default} suelto. Encuentralo y matalo");
		else
			CPrintToChat(client, "{olive}[Murder]{default} Hay un {red}murderer{default} suelto. No te dejes matar");
	}
	return Plugin_Stop;
}

void ScatterPlayers()
{
	if (g_iSpawnCount == 0) return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			int r = GetRandomInt(0, g_iSpawnCount - 1);
			float pos[3];
			pos[0] = g_fSpawnPoints[r][0];
			pos[1] = g_fSpawnPoints[r][1];
			pos[2] = g_fSpawnPoints[r][2] + 10.0;
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

void AssignFakeNames()
{
	if (g_iTotalNames == 0) return;
	
	int colorPool[10];
	for (int i = 0; i < 10; i++) colorPool[i] = i;
	
	// Shuffle names
	for (int i = 0; i < g_iTotalNames; i++)
	{
		int swap = GetRandomInt(0, g_iTotalNames - 1);
		char temp[64];
		strcopy(temp, sizeof(temp), g_szNameList[i]);
		strcopy(g_szNameList[i], sizeof(g_szNameList[]), g_szNameList[swap]);
		strcopy(g_szNameList[swap], sizeof(g_szNameList[]), temp);
	}
	
	// Shuffle colors
	for (int i = 0; i < 10; i++)
	{
		int swap = GetRandomInt(0, 9);
		int temp = colorPool[i];
		colorPool[i] = colorPool[swap];
		colorPool[swap] = temp;
	}
	
	int assignedCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			// Assign name
			int nameIdx = assignedCount % g_iTotalNames;
			strcopy(g_szPlayerFakeName[i], sizeof(g_szPlayerFakeName[]), g_szNameList[nameIdx]);
			
			// Assign color
			int cIdx = colorPool[assignedCount % 10];
			g_iPlayerColor[i][0] = g_iColors[cIdx][0];
			g_iPlayerColor[i][1] = g_iColors[cIdx][1];
			g_iPlayerColor[i][2] = g_iColors[cIdx][2];
			
			assignedCount++;
		}
	}
}

// ------------------------------------------------------------------------
// Weapon Handling & Entities
// ------------------------------------------------------------------------
void StripMapEntities()
{
	g_iSpawnCount = 0;
	int maxEnts = GetMaxEntities();
	char cls[64];
	for (int i = MaxClients + 1; i <= maxEnts; i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, cls, sizeof(cls));
			if (StrContains(cls, "weapon_") == 0 && StrContains(cls, "spawn") != -1)
			{
				if (g_iSpawnCount < 256)
				{
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", g_fSpawnPoints[g_iSpawnCount]);
					g_iSpawnCount++;
				}
				AcceptEntityInput(i, "KillHierarchy");
			}
			else if (StrEqual(cls, "upgrade_item") || StrContains(cls, "defibrillator") != -1 || StrContains(cls, "first_aid_kit") != -1 || StrContains(cls, "pain_pills") != -1)
			{
				if (g_iSpawnCount < 256)
				{
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", g_fSpawnPoints[g_iSpawnCount]);
					g_iSpawnCount++;
				}
				AcceptEntityInput(i, "KillHierarchy");
			}
		}
	}
}

void CleanDroppedWeapons()
{
	int maxEnts = GetMaxEntities();
	char cls[64];
	for (int i = MaxClients + 1; i <= maxEnts; i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, cls, sizeof(cls));
			if (StrEqual(cls, "weapon_melee") || StrEqual(cls, "weapon_pistol_magnum"))
			{
				if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == -1)
				{
					// If the weapon has EF_ITEM_BLINK or glows, turn it off before killing to prevent ghost particles
					SetEntProp(i, Prop_Send, "m_fEffects", 0);
					AcceptEntityInput(i, "KillHierarchy");
				}
			}
		}
	}
}

void RemoveAllWeapons(int client)
{
	for (int i = 0; i < 5; i++)
	{
		int wep = GetPlayerWeaponSlot(client, i);
		if (wep != -1)
		{
			RemovePlayerItem(client, wep);
			AcceptEntityInput(wep, "Kill");
		}
	}
}

void GiveMurdererKnife(int client)
{
	int weapon = CreateEntityByName("weapon_melee");
	DispatchKeyValue(weapon, "melee_script_name", "knife");
	DispatchSpawn(weapon);
	EquipPlayerWeapon(client, weapon);
	SetEntProp(weapon, Prop_Send, "m_fEffects", GetEntProp(weapon, Prop_Send, "m_fEffects") | 32);
}

// Comprueba si el jugador tiene actualmente un arma melee en cualquiera de sus ranuras
bool PlayerHasMelee(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	for (int i = 0; i <= 5; i++)
	{
		int wep = GetPlayerWeaponSlot(client, i);
		if (wep > 0 && IsValidEntity(wep))
		{
			char cls[64];
			GetEdictClassname(wep, cls, sizeof(cls));
			if (StrContains(cls, "weapon_melee") != -1) return true;
		}
	}
	return false;
}

void GiveGunnerDeagle(int client)
{
	int wep = GivePlayerItem(client, "weapon_pistol_magnum");
	if (wep > 0)
	{
		SetEntProp(wep, Prop_Send, "m_iClip1", 1);
		int ammoOffset = FindDataMapInfo(client, "m_iAmmo");
		int primaryAmmoType = GetEntProp(wep, Prop_Data, "m_iPrimaryAmmoType");
		if (primaryAmmoType != -1) SetEntData(client, ammoOffset + (primaryAmmoType * 4), 0);
		SetEntProp(wep, Prop_Send, "m_fEffects", GetEntProp(wep, Prop_Send, "m_fEffects") | 32);
	}
}

void GiveDummyPrimary(int client)
{
	int wep = GivePlayerItem(client, "weapon_pain_pills");
	if (wep > 0)
	{
		SetEntProp(wep, Prop_Send, "m_fEffects", GetEntProp(wep, Prop_Send, "m_fEffects") | 32);
	}
}

void DropGunnerWeaponWithGlow(int client)
{
	int wep = GetPlayerWeaponSlot(client, 1);
	if (wep > 0)
	{
		SetEntProp(wep, Prop_Send, "m_iGlowType", 3);
		SetEntProp(wep, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(wep, Prop_Send, "m_nGlowRangeMin", 0);
		SetEntProp(wep, Prop_Send, "m_glowColorOverride", 65535); // Yellow glow
		SetEntityRenderMode(wep, RENDER_NORMAL);
		SetEntityRenderColor(wep, 255, 255, 255, 255);
		SDKHooks_DropWeapon(client, wep);
	}
}

// Invisible Back Weapons & Dummy Slot
public Action OnWeaponTransmit(int weapon, int client)
{
	if (!g_bRoundLive) return Plugin_Continue;
	
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner > 0 && owner <= MaxClients && IsClientInGame(owner))
	{
		// Let the owner see their own weapon in first person
		if (owner == client) return Plugin_Continue;
		
		int activeWep = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		
		// Hide if holstered on the back
		if (weapon != activeWep)
		{
			return Plugin_Handled;
		}
		
		// Hide if it's the dummy item
		int dummy = GetPlayerWeaponSlot(owner, 4);
		if (weapon == dummy)
		{
			return Plugin_Handled; // Hide worldmodel
		}
	}
	
	return Plugin_Continue;
}

// Block picking up unauthorized weapons
public Action OnWeaponCanUse(int client, int weapon)
{
	if (!g_bRoundLive) return Plugin_Continue;
	
	char classname[64];
	GetEdictClassname(weapon, classname, sizeof(classname));
	
	if (g_iPlayerRole[client] == ROLE_MURDERER)
	{
		if (StrEqual(classname, "weapon_pistol_magnum")) return Plugin_Handled; // Murderer can't use gun
	}
	else if (g_iPlayerRole[client] == ROLE_BYSTANDER || g_iPlayerRole[client] == ROLE_GUNNER)
	{
		if (StrEqual(classname, "weapon_melee")) return Plugin_Handled; // Innocents can't pick up knife
		
		if (StrEqual(classname, "weapon_pistol_magnum"))
		{
			if (GetGameTime() < g_fGunnerPenaltyEnd[client])
			{
				return Plugin_Handled; // Gunner is penalized, can't pick up yet
			}
		}
	}
	
	return Plugin_Continue;
}
public Action OnWeaponDrop(int client, int weapon)
{
    if (weapon > 0 && IsValidEntity(weapon))
    {
        char cls[64];
        GetEdictClassname(weapon, cls, sizeof(cls));
        if (StrEqual(cls, "weapon_pain_pills"))
        {
            RemovePlayerItem(client, weapon);
            AcceptEntityInput(weapon, "Kill");
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action Timer_RegenKnife(Handle timer)
{
    g_hKnifeRegenTimer = INVALID_HANDLE;
    if (g_iMurderer > 0 && IsClientInGame(g_iMurderer) && IsPlayerAlive(g_iMurderer))
    {
		// Only give a new knife if the Murderer still doesn't have one
		if (!PlayerHasMelee(g_iMurderer))
		{
			GiveMurdererKnife(g_iMurderer);
			CPrintToChat(g_iMurderer, "\x01 \x04[Murder]\x01 Tu cuchillo ha regenerado.");
		}
		else
		{
			// They already recovered the knife (picked it up), cancel the started flag
			g_bKnifeTimerStarted = false;
		}
    }
    return Plugin_Stop;
}

public Action Timer_StartKnifeRegen(Handle timer, any userid)
{
	g_hKnifeDelayTimer = INVALID_HANDLE;
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (!PlayerHasMelee(client))
		{
			if (g_hKnifeRegenTimer != INVALID_HANDLE)
			{
				KillTimer(g_hKnifeRegenTimer);
				g_hKnifeRegenTimer = INVALID_HANDLE;
			}
			g_hKnifeRegenTimer = CreateTimer(g_cvKnifeRegenTime.FloatValue, Timer_RegenKnife);
			CPrintToChat(client, "{olive}[Murder]{default} Tu cuchillo regenerara en {green}%.0f{default} segundos.", g_cvKnifeRegenTime.FloatValue);
		}
		else
		{
			g_bKnifeTimerStarted = false;
		}
	}
	return Plugin_Stop;
}
// ------------------------------------------------------------------------
// Damage & Death Logic
// ------------------------------------------------------------------------
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bRoundLive)
	{
		// Celebration!
		if (attacker > 0 && attacker <= MaxClients && g_iPlayerRole[attacker] == ROLE_GUNNER)
		{
			SetEntProp(victim, Prop_Send, "m_isFallingFromLedge", 1);
			damage = 1000.0;
			ForcePlayerSuicide(victim);
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}
	
	// If attacker is valid survivor
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 2)
	{
		if (victim > 0 && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == 2)
		{
			// Instant kill logic
			damage = 1000.0;
			
			// Force physical ragdoll instead of animation/defib model (from restoreragdolls logic)
			SetEntProp(victim, Prop_Send, "m_isFallingFromLedge", 1);
			
			if (g_iPlayerRole[victim] == ROLE_GUNNER)
			{
				DropGunnerWeaponWithGlow(victim);
			}
			
			// Gunner penalty logic
			if (g_iPlayerRole[attacker] == ROLE_GUNNER && g_iPlayerRole[victim] == ROLE_BYSTANDER)
			{
				ApplyGunnerPenalty(attacker);
			}
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bRoundLive)
		event.BroadcastDisabled = true;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (!g_bRoundLive || victim <= 0 || victim > MaxClients) return;

	// Announce kill messages according to roles
	if (attacker > 0 && attacker <= MaxClients && attacker != victim && IsClientInGame(attacker))
	{
		char sReal[64];
		char sFake[64];
		GetClientName(attacker, sReal, sizeof(sReal));
		strcopy(sFake, sizeof(sFake), g_szPlayerFakeName[attacker]);

		// Attacker killed the Murderer -> broadcast
		if (victim == g_iMurderer)
		{
			CPrintToChatAll("{olive}[Murder]{default} {green}%s{default}, {green}%s{default} ha matado al murderer.", sReal, sFake);
		}
		// Murderer killed someone (innocent) -> do NOT broadcast (hide to prevent metagaming)
		else if (attacker == g_iMurderer)
		{
			// Intentionally do not notify anyone (avoid metagaming)
		}
		// Other player killed an innocent -> broadcast
		else
		{
			CPrintToChatAll("{olive}[Murder]{default} {green}%s{default}, {green}%s{default} ha matado a un inocente bystander.", sReal, sFake);
		}
	}

	if (attacker == g_iMurderer && victim != g_iMurderer)
	{
		g_iTimeSinceLastKill = 0;
		RemoveSmoke();
	}
	
	if (victim == g_iMurderer)
	{
		RemoveSmoke();
	}
	
	// Delete dummy pills so it doesn't drop
	int pills = GetPlayerWeaponSlot(victim, 4);
	if (pills > 0)
	{
		RemovePlayerItem(victim, pills);
		AcceptEntityInput(pills, "Kill");
	}
	
	CheckWinConditions();
}

void ApplyGunnerPenalty(int client)
{
	// Fade screen to black (blind)
	PerformFade(client, 20);
	
	// Slow down movement
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.4);
	
	// Drop the weapon
	DropGunnerWeaponWithGlow(client);
	
	// Lock weapon pickup
	g_fGunnerPenaltyEnd[client] = GetGameTime() + 20.0;
	
	// Start timer to restore
	CreateTimer(20.0, Timer_RestoreGunner, GetClientUserId(client));
}

public Action Timer_RestoreGunner(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		PerformFade(client, 0); // Clear fade
	}
	return Plugin_Stop;
}

void PerformFade(int client, int durationSeconds)
{
	Handle hMessage = StartMessageOne("Fade", client);
	if (hMessage != INVALID_HANDLE)
	{
		BfWriteShort(hMessage, durationSeconds * 500); // duration
		BfWriteShort(hMessage, durationSeconds * 500); // hold time
		BfWriteShort(hMessage, 0x0001); // IN flag
		BfWriteByte(hMessage, 0); // r
		BfWriteByte(hMessage, 0); // g
		BfWriteByte(hMessage, 0); // b
		BfWriteByte(hMessage, durationSeconds > 0 ? 200 : 0); // a
		EndMessage();
	}
}

void PerformFadeBlack(int client, int durationSeconds)
{
	Handle hMessage = StartMessageOne("Fade", client);
	if (hMessage != INVALID_HANDLE)
	{
		BfWriteShort(hMessage, durationSeconds * 500); // duration
		BfWriteShort(hMessage, durationSeconds * 500); // hold time
		BfWriteShort(hMessage, 0x0001); // IN flag
		BfWriteByte(hMessage, 0); // r
		BfWriteByte(hMessage, 0); // g
		BfWriteByte(hMessage, 0); // b
		BfWriteByte(hMessage, durationSeconds > 0 ? 255 : 0); // a
		EndMessage();
	}
}

void CheckWinConditions()
{
	if (!g_bRoundLive) return; // Prevent double trigger
	
	int aliveInnocents = 0;
	bool murdererAlive = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (g_iPlayerRole[i] == ROLE_MURDERER) murdererAlive = true;
			else aliveInnocents++;
		}
	}
	
	if (!murdererAlive || g_iRoundTimeRemaining <= 0)
	{
		// Announce Bystanders win and reveal murderer
		char sReal[64];
		char sFake[64];
		if (g_iMurderer > 0 && g_iMurderer <= MaxClients)
		{
			GetClientName(g_iMurderer, sReal, sizeof(sReal));
			strcopy(sFake, sizeof(sFake), g_szPlayerFakeName[g_iMurderer]);
		}
		else
		{
			strcopy(sReal, sizeof(sReal), "Unknown");
			strcopy(sFake, sizeof(sFake), "Unknown");
		}
		CPrintToChatAll("{olive}[Murder]{default} ¡Los bystanders ganan! El murderer era {green}%s{default}, {green}%s{default}", sReal, sFake);
		EmitSoundToAll("buttons/blip2.wav");
		RemoveSmoke();
		g_bRoundLive = false;
		CreateTimer(5.0, Timer_RestartRound);
	}
	else if (aliveInnocents == 0)
	{
		// Announce Murderer win and reveal who it was
		char sReal2[64];
		char sFake2[64];
		if (g_iMurderer > 0 && g_iMurderer <= MaxClients)
		{
			GetClientName(g_iMurderer, sReal2, sizeof(sReal2));
			strcopy(sFake2, sizeof(sFake2), g_szPlayerFakeName[g_iMurderer]);
		}
		else
		{
			strcopy(sReal2, sizeof(sReal2), "Unknown");
			strcopy(sFake2, sizeof(sFake2), "Unknown");
		}
		CPrintToChatAll("{olive}[Murder]{default} ¡El murderer gana! Era {green}%s{default}, {green}%s{default}", sReal2, sFake2);
		EmitSoundToAll("buttons/blip2.wav");
		RemoveSmoke();
		g_bRoundLive = false;
		CreateTimer(5.0, Timer_RestartRound);
	}
}

public Action Timer_RestartRound(Handle timer)
{
	g_iCurrentRoundCount++;
	
	if (g_iCurrentRoundCount >= 8)
	{
		// Kill all remaining players to force L4D2 Director to wipe and restart the scenario / return to lobby
		g_iCurrentRoundCount = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				ForcePlayerSuicide(i);
			}
		}
	}
	else
	{
		// Revive everyone for the next round
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if (!IsPlayerAlive(i))
				{
					L4D_RespawnPlayer(i);
				}
				
				// Full heal and reset strikes
				SetEntProp(i, Prop_Send, "m_iHealth", 100);
				SetEntProp(i, Prop_Send, "m_iMaxHealth", 100);
				SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
				SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
			}
		}
		
		// Start the round again manually
		OnRoundIsLive();
	}
	
	return Plugin_Stop;
}

// ------------------------------------------------------------------------
// Smoke Aura
// ------------------------------------------------------------------------
void CreateSmoke(int client)
{
    if (g_iMurdererSmokeEnt != -1)
    {
        int ent = EntRefToEntIndex(g_iMurdererSmokeEnt);
        if (ent > 0 && IsValidEntity(ent)) return;
        g_iMurdererSmokeEnt = -1;
    }

    int ent = CreateEntityByName("env_smokestack");
    if (ent > 0)
    {
		DispatchKeyValue(ent, "BaseSpread", "12");
		DispatchKeyValue(ent, "Speed", "90");
		DispatchKeyValue(ent, "StartSize", "16");
		DispatchKeyValue(ent, "EndSize", "40");
		DispatchKeyValue(ent, "Rate", "80");
		DispatchKeyValue(ent, "JetLength", "120");
		DispatchKeyValue(ent, "Spread", "12");
		DispatchKeyValue(ent, "rendercolor", "0 0 0");
		DispatchKeyValue(ent, "renderamt", "255");
        DispatchKeyValue(ent, "SmokeMaterial", "particle/particle_smokegrenade1.vmt");
		DispatchKeyValue(ent, "angles", "0 0 0");
		DispatchSpawn(ent);
		ActivateEntity(ent);

		// Place the smoke above the player's head and turn it on
		if (client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			float pos[3];
			GetClientAbsOrigin(client, pos);
			pos[2] += 50.0;
			TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		}
		AcceptEntityInput(ent, "TurnOn");

		g_iMurdererSmokeEnt = EntIndexToEntRef(ent);
    }
}

void RemoveSmoke()
{
	if (g_iMurdererSmokeEnt != -1)
	{
		int ent = EntRefToEntIndex(g_iMurdererSmokeEnt);
		if (ent > 0 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Stop");
			AcceptEntityInput(ent, "Kill");
		}
		g_iMurdererSmokeEnt = -1;
	}
}

// ------------------------------------------------------------------------
// Knife Physics & Throwing
// ------------------------------------------------------------------------
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!g_bRoundLive || client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Continue;
	
	int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int dummy = GetPlayerWeaponSlot(client, 4); // Pills slot
	int secondary = GetPlayerWeaponSlot(client, 1);
	
	if (activeWep > 0 && IsValidEntity(activeWep))
	{
		// Force Deagle to always have 1 bullet max
		if (activeWep == secondary && g_iPlayerRole[client] == ROLE_GUNNER)
		{
			char cls[64];
			GetEdictClassname(activeWep, cls, sizeof(cls));
			if (StrEqual(cls, "weapon_pistol_magnum"))
			{
				int clip = GetEntProp(activeWep, Prop_Send, "m_iClip1");
				if (clip > 1) SetEntProp(activeWep, Prop_Send, "m_iClip1", 1);
			}
		}
		
		// Handle Dummy Slot Viewmodel
		if (activeWep == dummy && dummy > 0)
		{
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
			buttons &= ~IN_ATTACK; // Block consuming pills
			buttons &= ~IN_ATTACK2; // Block shoving with pills
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		}
	}
	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// HUD & Display
// ------------------------------------------------------------------------

public Action Timer_Footprints(Handle timer)
{
	if (!g_bRoundLive) return Plugin_Continue;
	
	if (g_iBeamSprite == -1 || g_iHaloSprite == -1) return Plugin_Continue;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if (g_iPlayerRole[i] == ROLE_MURDERER) continue; // Murderer leaves NO footprints
			
			float vel[3];
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", vel);
			if (GetVectorLength(vel) > 10.0 && (GetEntityFlags(i) & FL_ONGROUND))
			{
				float pos[3];
				GetClientAbsOrigin(i, pos);
				pos[2] += 5.0; // slightly above ground
				
				int color[4];
				color[0] = g_iPlayerColor[i][0];
				color[1] = g_iPlayerColor[i][1];
				color[2] = g_iPlayerColor[i][2];
				color[3] = 200; // Alpha
				
				int clients[1];
				clients[0] = g_iMurderer;
				if (g_iMurderer > 0 && IsClientInGame(g_iMurderer) && !IsFakeClient(g_iMurderer))
				{
					TE_SetupBeamRingPoint(pos, 5.0, 8.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 20.0, 1.5, 0.0, color, 1, 0);
					TE_Send(clients, 1);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_HUDUpdate(Handle timer)
{
	if (!g_bRoundLive) return Plugin_Continue;
	
	g_iRoundTimeRemaining--;
	if (g_iRoundTimeRemaining <= 0)
	{
		CheckWinConditions();
		return Plugin_Continue;
	}
	
	// Avisos por minuto
	if (g_iRoundTimeRemaining == 240)
	    CPrintToChatAll("{olive}[Murder]{default} {green}Quedan 4 minutos.");
	else if (g_iRoundTimeRemaining == 180)
	    CPrintToChatAll("{olive}[Murder]{default} {green}Quedan 3 minutos.");
	else if (g_iRoundTimeRemaining == 120)
	    CPrintToChatAll("{olive}[Murder]{default} {green}Quedan 2 minutos.");
	else if (g_iRoundTimeRemaining == 60)
    CPrintToChatAll("{olive}[Murder]{default} {green}Queda 1 minuto!");
	else if (g_iRoundTimeRemaining == 30)
    CPrintToChatAll("{olive}[Murder]{default} {green}Quedan 30 segundos!");

if (g_iMurderer > 0 && IsClientInGame(g_iMurderer) && IsPlayerAlive(g_iMurderer))
{
	// Use a robust check across all weapon slots to determine if the Murderer has a melee
	if (!PlayerHasMelee(g_iMurderer) && !g_bKnifeTimerStarted)
	{
		g_bKnifeTimerStarted = true;

		// Cancel any existing regen or delay timers
		if (g_hKnifeRegenTimer != INVALID_HANDLE)
		{
			KillTimer(g_hKnifeRegenTimer);
			g_hKnifeRegenTimer = INVALID_HANDLE;
		}
		if (g_hKnifeDelayTimer != INVALID_HANDLE)
		{
			KillTimer(g_hKnifeDelayTimer);
			g_hKnifeDelayTimer = INVALID_HANDLE;
		}

		// Start a short delay before announcing and starting the regen countdown
		g_hKnifeDelayTimer = CreateTimer(g_cvKnifeRegenDelay.FloatValue, Timer_StartKnifeRegen, GetClientUserId(g_iMurderer));
	}
	else if (PlayerHasMelee(g_iMurderer))
	{
		// If they recovered the knife, cancel any pending timers
		g_bKnifeTimerStarted = false;
		if (g_hKnifeDelayTimer != INVALID_HANDLE)
		{
			KillTimer(g_hKnifeDelayTimer);
			g_hKnifeDelayTimer = INVALID_HANDLE;
		}
		if (g_hKnifeRegenTimer != INVALID_HANDLE)
		{
			KillTimer(g_hKnifeRegenTimer);
			g_hKnifeRegenTimer = INVALID_HANDLE;
		}
	}
}

	// Murderer smoke logic
	g_iTimeSinceLastKill++;
	if (g_iTimeSinceLastKill >= g_cvSmokeTime.IntValue && g_iMurderer > 0 && IsPlayerAlive(g_iMurderer))
	{
		CreateSmoke(g_iMurderer);
	}

	// If smoke entity exists, update its position to follow the murderer
	if (g_iMurdererSmokeEnt != -1)
	{
		int ent = EntRefToEntIndex(g_iMurdererSmokeEnt);
		if (ent > 0 && IsValidEntity(ent) && g_iMurderer > 0 && IsClientInGame(g_iMurderer) && IsPlayerAlive(g_iMurderer))
		{
			float pos[3];
			GetClientAbsOrigin(g_iMurderer, pos);
			pos[2] += 50.0;
			TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		}
		else
		{
			// Cleanup if entity/player invalid
			RemoveSmoke();
		}
	}
	
	// Wipe infected to prevent random spawns
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "infected")) != -1) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "witch")) != -1) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "smoker")) != -1) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "boomer")) != -1) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "hunter")) != -1) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "spitter")) != -1) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "jockey")) != -1) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "charger")) != -1) AcceptEntityInput(ent, "Kill");
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "tank")) != -1) AcceptEntityInput(ent, "Kill");

	int mins = g_iRoundTimeRemaining / 60;
	int secs = g_iRoundTimeRemaining % 60;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			int target = GetClientAimTargetRay(i);
if (target > 0 && target != g_iLastAimTarget[i])
{
    g_iLastAimTarget[i] = target;
    CPrintToChat(i, "{olive}[Murder]{default} Estas viendo a {green}%s", g_szPlayerFakeName[target]);
}
else if (target <= 0)
{
    g_iLastAimTarget[i] = -1;
}
		}
	}
	return Plugin_Continue;
}

int GetClientAimTargetRay(int client)
{
	float vAngles[3], vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter_ClientsOnly, client);
	if (TR_DidHit(trace))
	{
		int hit = TR_GetEntityIndex(trace);
		delete trace;
		if (hit > 0 && hit <= MaxClients && IsClientInGame(hit) && GetClientTeam(hit) == 2 && IsPlayerAlive(hit))
		{
			return hit;
		}
	}
	else
	{
		delete trace;
	}
	return -1;
}

public bool TraceFilter_ClientsOnly(int entity, int contentsMask, any data)
{
	if (entity == data) return false;
	return true;
}
