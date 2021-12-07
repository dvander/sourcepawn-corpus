#include <sourcemod>
#include <sdktools>
#include <multi1v1>

#pragma semicolon 1

#define ROUND_INT_NAME "Xhp"
#define ROUND_NAME "%d HP round"
#define ROUND_NAME_BUFFER 15

public Plugin myinfo = {
  name = "Multi1v1: Custom HP rounds",
  author = "Douile",
  description = "Adds rounds with different amounts of HP",
  version = "1.0",
  url = "https://github.com/Douile/Multi1v1-CustomHealth"
}

ConVar gh_enabled, gh_health;
int g_roundType;

public void OnPluginStart() {
    RegPluginLibrary("CS:GO Multi1v1");

    gh_enabled = CreateConVar("sm_1v1_hp_enabled","1","Enable/Disable Multi1v1 HP rounds",FCVAR_PROTECTED,true,0.0,true,1.0);
    gh_health = CreateConVar("sm_1v1_hp_health","1","Set health for Multi1v1 HP rounds",FCVAR_PROTECTED,true,1.0,true,100.0);

    HookConVarChange(gh_enabled,OnEnabledChanged);

    RegAdminCmd("sm_1v1_hp_test",TestPluginCallback,ADMFLAG_GENERIC,"Test setting health","",0);
}

public Action TestPluginCallback(int client, int args) {
  int health = gh_health.IntValue;
  SetEntityHealth(client,health);
  ReplyToCommand(client,"Set your health to %d",health);
  return Plugin_Handled;
}


public void OnEnabledChanged(ConVar enabled, const char[] oldValue, const char[] newValue) {
  if (enabled.BoolValue) {
    Multi1v1_EnableRoundType(g_roundType);
  } else {
    Multi1v1_DisableRoundType(g_roundType);
  }
}

public void Multi1v1_OnRoundTypesAdded() {
  char roundName[ROUND_NAME_BUFFER];
  Format(roundName,ROUND_NAME_BUFFER,ROUND_NAME,gh_health.IntValue);
  g_roundType = Multi1v1_AddRoundType(roundName,ROUND_INT_NAME,CustomHealthHandler,true,false,"",gh_enabled.BoolValue);
}

public void CustomHealthHandler(int client) {
  char wep_name[WEAPON_NAME_LENGTH];
  Multi1v1_GetPistolChoice(client,wep_name);

  SetEntityHealth(client,gh_health.IntValue);
  Multi1v1_GivePlayerKnife(client);
  int iWeapon = GivePlayerItem(client,wep_name);
  EquipPlayerWeapon(client, iWeapon);
}
