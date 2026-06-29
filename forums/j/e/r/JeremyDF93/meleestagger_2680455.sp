#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define NYXTOOLS_VERSION "1.0.1"
#define NYXTOOLS_AUTHOR "Kiwi, JeremyDF93"
#define NYXTOOLS_WEBSITE "https://praisethemoon.com/"

#define L4D2_TEAM_UNASSIGNED  0
#define L4D2_TEAM_SPECTATOR   1
#define L4D2_TEAM_SURVIVOR    2
#define L4D2_TEAM_INFECTED    3

public Plugin myinfo = {
  name = "Melee Stagger",
  author = NYXTOOLS_AUTHOR,
  description = "Stagger like you're drunk",
  version = NYXTOOLS_VERSION,
  url = NYXTOOLS_WEBSITE
};

/***
 *        ______
 *       / ____/___  __  ______ ___  _____
 *      / __/ / __ \/ / / / __ `__ \/ ___/
 *     / /___/ / / / /_/ / / / / / (__  )
 *    /_____/_/ /_/\__,_/_/ /_/ /_/____/
 *
 */

enum NyxConVar {
  ConVar:ConVar_StaggerTank,
}

/***
 *       ________      __          __
 *      / ____/ /___  / /_  ____ _/ /____
 *     / / __/ / __ \/ __ \/ __ `/ / ___/
 *    / /_/ / / /_/ / /_/ / /_/ / (__  )
 *    \____/_/\____/_.___/\__,_/_/____/
 *
 */

ConVar g_hConVars[NyxConVar];

/***
 *        ____  __            _          ____      __            ____
 *       / __ \/ /_  ______ _(_)___     /  _/___  / /____  _____/ __/___ _________
 *      / /_/ / / / / / __ `/ / __ \    / // __ \/ __/ _ \/ ___/ /_/ __ `/ ___/ _ \
 *     / ____/ / /_/ / /_/ / / / / /  _/ // / / / /_/  __/ /  / __/ /_/ / /__/  __/
 *    /_/   /_/\__,_/\__, /_/_/ /_/  /___/_/ /_/\__/\___/_/  /_/  \__,_/\___/\___/
 *                  /____/
 */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
  EngineVersion engine = GetEngineVersion();
  if (engine != Engine_Left4Dead2) {
    strcopy(error, err_max, "Incompatible with this game");
    return APLRes_SilentFailure;
  }

  return APLRes_Success;
}

public void OnPluginStart() {
  g_hConVars[ConVar_StaggerTank] = CreateConVar("nyx_melee_stagger_tank", "0",
      "Allow melee weapons to stagger the tank?", _, true, 0.0, true, 1.0);

  HookEvent("player_hurt", Event_PlayerHurt);
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
  int victim = GetClientOfUserId(event.GetInt("userid"));
  int attacker = GetClientOfUserId(event.GetInt("attacker"));
  if (!IsValidClient(victim)) return Plugin_Continue;
  if (!IsValidClient(attacker)) return Plugin_Continue;
  if (!IsPlayerInfected(victim)) return Plugin_Continue;
  if (!IsPlayerSurvivor(attacker)) return Plugin_Continue;

  if (IsPlayerTank(victim)) {
    bool staggerTank = g_hConVars[ConVar_StaggerTank].BoolValue;
    if (!staggerTank) return Plugin_Continue;
  }

  int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
  if (!IsValidEntity(weapon)) {
    return Plugin_Continue;
  }

  char classname[255]; GetEntityClassname(weapon, classname, sizeof(classname));
  if (strcmp(classname, "weapon_melee", false) != 0) {
    return Plugin_Continue;
  }

  float pos[3]; GetClientAbsOrigin(attacker, pos);
  RunScriptCode("GetPlayerFromUserID(%d).Stagger(Vector(%.3f, %.3f, %.3f))", GetClientUserId(victim), pos[0], pos[1], pos[2]);

  return Plugin_Continue;
}

/***
 *        ______                 __  _
 *       / ____/_  ______  _____/ /_(_)___  ____  _____
 *      / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
 *     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
 *    /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
 *
 */

stock bool IsValidClient(int client) {
  if (client <= 0 || client > MaxClients) return false;
  if (!IsClientInGame(client)) return false;

  return true;
}

stock bool IsPlayerTank(int client) {
  if (IsPlayerSurvivor(client)) return false;
  if (GetEntProp(client, Prop_Send, "m_zombieClass") != 8) return false;

  return true;
}

stock bool IsPlayerSurvivor(int client) {
  if (GetClientTeam(client) == L4D2_TEAM_INFECTED) return false;

  return true;
}

stock bool IsPlayerInfected(int client) {
  if (GetClientTeam(client) == L4D2_TEAM_SURVIVOR) return false;

  return true;
}

stock void RunScriptCode(const char[] fmt, any ...) {
  char buffer[512];
  VFormat(buffer, sizeof(buffer), fmt, 2);

  int ent = CreateEntityByName("logic_script");
  DispatchSpawn(ent);

  SetVariantString(buffer);
  AcceptEntityInput(ent, "RunScriptCode");

  RemoveEntity(ent);
}
