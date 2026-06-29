#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// 2D Arrays: [Class ID][Difficulty ID]
// Classes: 0=Common, 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger, 8=Tank, 9=Witch
// Difficulties: 0=Easy, 1=Normal, 2=Hard, 3=Expert
ConVar cv_Bile[10][4];
ConVar cv_BileMult[10][4];
ConVar cv_Fire[10][4];
ConVar cv_DiffMult[10][4];

ConVar g_cvDifficulty;
int g_iCurrentDifficulty = 1; 

public Plugin myinfo = 
{
	name = "[L4D2] Infected Bile And Fire Damage Modifier",
	author = "KELLOGGG",
	description = "Base * (BileMult + FireMult + DiffMult) - Full Difficulty Support",
	version = "10.3"
};

public void OnPluginStart()
{
	// --- 0 = COMMON ---
	cv_Bile[0][0] = CreateConVar("bile_common_easy", "10.0");
	cv_BileMult[0][0] = CreateConVar("bile_mult_common_easy", "1.0");
	cv_Fire[0][0] = CreateConVar("fire_common_easy", "4.0");
	cv_DiffMult[0][0] = CreateConVar("diff_mult_common_easy", "8.0");
	cv_Bile[0][1] = CreateConVar("bile_common_normal", "10.0");
	cv_BileMult[0][1] = CreateConVar("bile_mult_common_normal", "1.0");
	cv_Fire[0][1] = CreateConVar("fire_common_normal", "4.0");
	cv_DiffMult[0][1] = CreateConVar("diff_mult_common_normal", "8.0");
	cv_Bile[0][2] = CreateConVar("bile_common_hard", "10.0");
	cv_BileMult[0][2] = CreateConVar("bile_mult_common_hard", "1.0");
	cv_Fire[0][2] = CreateConVar("fire_common_hard", "4.0");
	cv_DiffMult[0][2] = CreateConVar("diff_mult_common_hard", "8.0");
	cv_Bile[0][3] = CreateConVar("bile_common_expert", "10.0");
	cv_BileMult[0][3] = CreateConVar("bile_mult_common_expert", "1.0");
	cv_Fire[0][3] = CreateConVar("fire_common_expert", "4.0");
	cv_DiffMult[0][3] = CreateConVar("diff_mult_common_expert", "8.0");

	// --- 1 = SMOKER ---
	cv_Bile[1][0] = CreateConVar("bile_smoker_easy", "20.0");
	cv_BileMult[1][0] = CreateConVar("bile_mult_smoker_easy", "1.0");
	cv_Fire[1][0] = CreateConVar("fire_smoker_easy", "4.0");
	cv_DiffMult[1][0] = CreateConVar("diff_mult_smoker_easy", "8.0");
	cv_Bile[1][1] = CreateConVar("bile_smoker_normal", "20.0");
	cv_BileMult[1][1] = CreateConVar("bile_mult_smoker_normal", "1.0");
	cv_Fire[1][1] = CreateConVar("fire_smoker_normal", "4.0");
	cv_DiffMult[1][1] = CreateConVar("diff_mult_smoker_normal", "8.0");
	cv_Bile[1][2] = CreateConVar("bile_smoker_hard", "20.0");
	cv_BileMult[1][2] = CreateConVar("bile_mult_smoker_hard", "1.0");
	cv_Fire[1][2] = CreateConVar("fire_smoker_hard", "4.0");
	cv_DiffMult[1][2] = CreateConVar("diff_mult_smoker_hard", "8.0");
	cv_Bile[1][3] = CreateConVar("bile_smoker_expert", "20.0");
	cv_BileMult[1][3] = CreateConVar("bile_mult_smoker_expert", "1.0");
	cv_Fire[1][3] = CreateConVar("fire_smoker_expert", "4.0");
	cv_DiffMult[1][3] = CreateConVar("diff_mult_smoker_expert", "8.0");

	// --- 2 = BOOMER ---
	cv_Bile[2][0] = CreateConVar("bile_boomer_easy", "20.0");
	cv_BileMult[2][0] = CreateConVar("bile_mult_boomer_easy", "1.0");
	cv_Fire[2][0] = CreateConVar("fire_boomer_easy", "4.0");
	cv_DiffMult[2][0] = CreateConVar("diff_mult_boomer_easy", "8.0");
	cv_Bile[2][1] = CreateConVar("bile_boomer_normal", "20.0");
	cv_BileMult[2][1] = CreateConVar("bile_mult_boomer_normal", "1.0");
	cv_Fire[2][1] = CreateConVar("fire_boomer_normal", "4.0");
	cv_DiffMult[2][1] = CreateConVar("diff_mult_boomer_normal", "8.0");
	cv_Bile[2][2] = CreateConVar("bile_boomer_hard", "20.0");
	cv_BileMult[2][2] = CreateConVar("bile_mult_boomer_hard", "1.0");
	cv_Fire[2][2] = CreateConVar("fire_boomer_hard", "4.0");
	cv_DiffMult[2][2] = CreateConVar("diff_mult_boomer_hard", "8.0");
	cv_Bile[2][3] = CreateConVar("bile_boomer_expert", "20.0");
	cv_BileMult[2][3] = CreateConVar("bile_mult_boomer_expert", "1.0");
	cv_Fire[2][3] = CreateConVar("fire_boomer_expert", "4.0");
	cv_DiffMult[2][3] = CreateConVar("diff_mult_boomer_expert", "8.0");

	// --- 3 = HUNTER ---
	cv_Bile[3][0] = CreateConVar("bile_hunter_easy", "20.0");
	cv_BileMult[3][0] = CreateConVar("bile_mult_hunter_easy", "1.0");
	cv_Fire[3][0] = CreateConVar("fire_hunter_easy", "4.0");
	cv_DiffMult[3][0] = CreateConVar("diff_mult_hunter_easy", "8.0");
	cv_Bile[3][1] = CreateConVar("bile_hunter_normal", "20.0");
	cv_BileMult[3][1] = CreateConVar("bile_mult_hunter_normal", "1.0");
	cv_Fire[3][1] = CreateConVar("fire_hunter_normal", "4.0");
	cv_DiffMult[3][1] = CreateConVar("diff_mult_hunter_normal", "8.0");
	cv_Bile[3][2] = CreateConVar("bile_hunter_hard", "20.0");
	cv_BileMult[3][2] = CreateConVar("bile_mult_hunter_hard", "1.0");
	cv_Fire[3][2] = CreateConVar("fire_hunter_hard", "4.0");
	cv_DiffMult[3][2] = CreateConVar("diff_mult_hunter_hard", "8.0");
	cv_Bile[3][3] = CreateConVar("bile_hunter_expert", "20.0");
	cv_BileMult[3][3] = CreateConVar("bile_mult_hunter_expert", "1.0");
	cv_Fire[3][3] = CreateConVar("fire_hunter_expert", "4.0");
	cv_DiffMult[3][3] = CreateConVar("diff_mult_hunter_expert", "8.0");

	// --- 4 = SPITTER ---
	cv_Bile[4][0] = CreateConVar("bile_spitter_easy", "20.0");
	cv_BileMult[4][0] = CreateConVar("bile_mult_spitter_easy", "1.0");
	cv_Fire[4][0] = CreateConVar("fire_spitter_easy", "4.0");
	cv_DiffMult[4][0] = CreateConVar("diff_mult_spitter_easy", "8.0");
	cv_Bile[4][1] = CreateConVar("bile_spitter_normal", "20.0");
	cv_BileMult[4][1] = CreateConVar("bile_mult_spitter_normal", "1.0");
	cv_Fire[4][1] = CreateConVar("fire_spitter_normal", "4.0");
	cv_DiffMult[4][1] = CreateConVar("diff_mult_spitter_normal", "8.0");
	cv_Bile[4][2] = CreateConVar("bile_spitter_hard", "20.0");
	cv_BileMult[4][2] = CreateConVar("bile_mult_spitter_hard", "1.0");
	cv_Fire[4][2] = CreateConVar("fire_spitter_hard", "4.0");
	cv_DiffMult[4][2] = CreateConVar("diff_mult_spitter_hard", "8.0");
	cv_Bile[4][3] = CreateConVar("bile_spitter_expert", "20.0");
	cv_BileMult[4][3] = CreateConVar("bile_mult_spitter_expert", "1.0");
	cv_Fire[4][3] = CreateConVar("fire_spitter_expert", "4.0");
	cv_DiffMult[4][3] = CreateConVar("diff_mult_spitter_expert", "8.0");

	// --- 5 = JOCKEY ---
	cv_Bile[5][0] = CreateConVar("bile_jockey_easy", "25.0");
	cv_BileMult[5][0] = CreateConVar("bile_mult_jockey_easy", "1.0");
	cv_Fire[5][0] = CreateConVar("fire_jockey_easy", "4.0");
	cv_DiffMult[5][0] = CreateConVar("diff_mult_jockey_easy", "8.0");
	cv_Bile[5][1] = CreateConVar("bile_jockey_normal", "25.0");
	cv_BileMult[5][1] = CreateConVar("bile_mult_jockey_normal", "1.0");
	cv_Fire[5][1] = CreateConVar("fire_jockey_normal", "4.0");
	cv_DiffMult[5][1] = CreateConVar("diff_mult_jockey_normal", "8.0");
	cv_Bile[5][2] = CreateConVar("bile_jockey_hard", "25.0");
	cv_BileMult[5][2] = CreateConVar("bile_mult_jockey_hard", "1.0");
	cv_Fire[5][2] = CreateConVar("fire_jockey_hard", "4.0");
	cv_DiffMult[5][2] = CreateConVar("diff_mult_jockey_hard", "8.0");
	cv_Bile[5][3] = CreateConVar("bile_jockey_expert", "25.0");
	cv_BileMult[5][3] = CreateConVar("bile_mult_jockey_expert", "1.0");
	cv_Fire[5][3] = CreateConVar("fire_jockey_expert", "4.0");
	cv_DiffMult[5][3] = CreateConVar("diff_mult_jockey_expert", "8.0");

	// --- 6 = CHARGER ---
	cv_Bile[6][0] = CreateConVar("bile_charger_easy", "30.0");
	cv_BileMult[6][0] = CreateConVar("bile_mult_charger_easy", "1.0");
	cv_Fire[6][0] = CreateConVar("fire_charger_easy", "4.0");
	cv_DiffMult[6][0] = CreateConVar("diff_mult_charger_easy", "8.0");
	cv_Bile[6][1] = CreateConVar("bile_charger_normal", "30.0");
	cv_BileMult[6][1] = CreateConVar("bile_mult_charger_normal", "1.0");
	cv_Fire[6][1] = CreateConVar("fire_charger_normal", "4.0");
	cv_DiffMult[6][1] = CreateConVar("diff_mult_charger_normal", "8.0");
	cv_Bile[6][2] = CreateConVar("bile_charger_hard", "30.0");
	cv_BileMult[6][2] = CreateConVar("bile_mult_charger_hard", "1.0");
	cv_Fire[6][2] = CreateConVar("fire_charger_hard", "4.0");
	cv_DiffMult[6][2] = CreateConVar("diff_mult_charger_hard", "8.0");
	cv_Bile[6][3] = CreateConVar("bile_charger_expert", "30.0");
	cv_BileMult[6][3] = CreateConVar("bile_mult_charger_expert", "1.0");
	cv_Fire[6][3] = CreateConVar("fire_charger_expert", "4.0");
	cv_DiffMult[6][3] = CreateConVar("diff_mult_charger_expert", "8.0");

	// --- 8 = TANK ---
	cv_Bile[8][0] = CreateConVar("bile_tank_easy", "50.0");
	cv_BileMult[8][0] = CreateConVar("bile_mult_tank_easy", "1.0");
	cv_Fire[8][0] = CreateConVar("fire_tank_easy", "4.0");
	cv_DiffMult[8][0] = CreateConVar("diff_mult_tank_easy", "8.0");
	cv_Bile[8][1] = CreateConVar("bile_tank_normal", "50.0");
	cv_BileMult[8][1] = CreateConVar("bile_mult_tank_normal", "1.0");
	cv_Fire[8][1] = CreateConVar("fire_tank_normal", "4.0");
	cv_DiffMult[8][1] = CreateConVar("diff_mult_tank_normal", "8.0");
	cv_Bile[8][2] = CreateConVar("bile_tank_hard", "50.0");
	cv_BileMult[8][2] = CreateConVar("bile_mult_tank_hard", "1.0");
	cv_Fire[8][2] = CreateConVar("fire_tank_hard", "4.0");
	cv_DiffMult[8][2] = CreateConVar("diff_mult_tank_hard", "8.0");
	cv_Bile[8][3] = CreateConVar("bile_tank_expert", "39.0");
	cv_BileMult[8][3] = CreateConVar("bile_mult_tank_expert", "4.0");
	cv_Fire[8][3] = CreateConVar("fire_tank_expert", "4.0");
	cv_DiffMult[8][3] = CreateConVar("diff_mult_tank_expert", "8.0");

	// --- 9 = WITCH ---
	cv_Bile[9][0] = CreateConVar("bile_witch_easy", "40.0");
	cv_BileMult[9][0] = CreateConVar("bile_mult_witch_easy", "1.0");
	cv_Fire[9][0] = CreateConVar("fire_witch_easy", "4.0");
	cv_DiffMult[9][0] = CreateConVar("diff_mult_witch_easy", "8.0");
	cv_Bile[9][1] = CreateConVar("bile_witch_normal", "40.0");
	cv_BileMult[9][1] = CreateConVar("bile_mult_witch_normal", "1.0");
	cv_Fire[9][1] = CreateConVar("fire_witch_normal", "4.0");
	cv_DiffMult[9][1] = CreateConVar("diff_mult_witch_normal", "8.0");
	cv_Bile[9][2] = CreateConVar("bile_witch_hard", "40.0");
	cv_BileMult[9][2] = CreateConVar("bile_mult_witch_hard", "1.0");
	cv_Fire[9][2] = CreateConVar("fire_witch_hard", "4.0");
	cv_DiffMult[9][2] = CreateConVar("diff_mult_witch_hard", "8.0");
	cv_Bile[9][3] = CreateConVar("bile_witch_expert", "40.0");
	cv_BileMult[9][3] = CreateConVar("bile_mult_witch_expert", "1.0");
	cv_Fire[9][3] = CreateConVar("fire_witch_expert", "4.0");
	cv_DiffMult[9][3] = CreateConVar("diff_mult_witch_expert", "8.0");

	AutoExecConfig(true, "InfectedBileFireDamage");
	
	g_cvDifficulty = FindConVar("z_difficulty");
	if (g_cvDifficulty != null)
	{
		g_cvDifficulty.AddChangeHook(OnDifficultyChanged);
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnConfigsExecuted() { CacheDifficulty(); }
public void OnDifficultyChanged(ConVar convar, const char[] oldValue, const char[] newValue) { CacheDifficulty(); }

void CacheDifficulty()
{
	if (g_cvDifficulty == null) return;
	char sDiff[32];
	g_cvDifficulty.GetString(sDiff, sizeof(sDiff));
	if (StrEqual(sDiff, "Easy", false)) g_iCurrentDifficulty = 0;
	else if (StrEqual(sDiff, "Hard", false)) g_iCurrentDifficulty = 2;
	else if (StrEqual(sDiff, "Impossible", false)) g_iCurrentDifficulty = 3;
	else g_iCurrentDifficulty = 1;
}

public void OnClientPutInServer(int client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public void OnEntityCreated(int entity, const char[] classname)
{
	if ((classname[0] == 'i' && StrEqual(classname, "infected")) || (classname[0] == 'w' && StrEqual(classname, "witch")))
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	// REDEFINITION FIX: DMG_SLASH and DMG_CLUB are already in the includes
	if (!(damagetype & (DMG_SLASH | DMG_CLUB))) return Plugin_Continue;

	int vIndex = GetClassIndex(victim);
	if (vIndex == -1) return Plugin_Continue;

	int aIndex = GetClassIndex(attacker);
	if (aIndex == -1) return Plugin_Continue;

	float base = cv_Bile[vIndex][g_iCurrentDifficulty].FloatValue;
	float dMult = cv_DiffMult[vIndex][g_iCurrentDifficulty].FloatValue;
	float bMult = 0.0;
	float fMult = 0.0;

	if (IsBiled(victim)) bMult = cv_BileMult[vIndex][g_iCurrentDifficulty].FloatValue;
	if (IsOnFire(victim)) fMult = cv_Fire[vIndex][g_iCurrentDifficulty].FloatValue;

	damage = base * (bMult + fMult + dMult);
	
	return Plugin_Changed;
}

int GetClassIndex(int entity)
{
	if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity) && GetClientTeam(entity) == 3)
		{
			int zClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
			if ((zClass >= 1 && zClass <= 6) || zClass == 8) return zClass;
		}
		return -1;
	}
	else if (entity > MaxClients && IsValidEntity(entity))
	{
		static char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if (classname[0] == 'i' && StrEqual(classname, "infected")) return 0;
		if (classname[0] == 'w' && StrEqual(classname, "witch")) return 9;
	}
	return -1;
}

stock bool IsOnFire(int entity) { return (GetEntProp(entity, Prop_Data, "m_fFlags") & 1) != 0; }
stock bool IsBiled(int entity) { return (GetEntProp(entity, Prop_Send, "m_nRenderMode") == 3); }