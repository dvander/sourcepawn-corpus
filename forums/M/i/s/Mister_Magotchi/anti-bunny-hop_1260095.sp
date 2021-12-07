#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

new Handle:cvar_ratio_threshold = INVALID_HANDLE;
new Handle:cvar_ratio_punish = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Anti Bunny Hop",
	author = "Mister_Magotchi",
	description = "Limits player jump speed based on weapon-specific maximum ground speed with configurable speed punishment.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart() {
  CreateConVar(
    "sm_anti_bunny_hop_version",
    PLUGIN_VERSION,
    "Anti Bunny Hop version",
    FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
  );
  cvar_ratio_threshold = CreateConVar(
    "sm_anti_bunny_hop_ratio_threshold",
    "1.45",
    "Ratio of [air speed .1 seconds into jump] over [weapon-specific maximum ground speed] at which punishment should happen.  1.45 or greater seems safe.  0 disables plugin.",
    FCVAR_PLUGIN
  );
  cvar_ratio_punish = CreateConVar(
    "sm_anti_bunny_hop_ratio_punish",
    "0.75",
    "Ratio of [speed after punishment] over [weapon-specific maximum ground speed].  Anything under 1.5 makes sense.  Setting equal to threshold limits speed to threshold without any punishment.",
    FCVAR_PLUGIN
  );
  HookEvent("player_jump", OnPlayerJump);
  AutoExecConfig(true, "anti-bunny-hop");
}

public OnPlayerJump(Handle:event, const String:name[], bool:dontBroadcast) {
  if (GetConVarBool(cvar_ratio_threshold)) {
    CreateTimer(0.1, ManageJumpSpeed, GetClientOfUserId(GetEventInt(event, "userid")));
  }
}

public Action:ManageJumpSpeed(Handle:timer, any:client) {
  new Float:velocity[3];
  GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
  new Float:max_ground_speed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
  if (FloatCompare(210.0, max_ground_speed) == 1) {
    max_ground_speed = 210.0;
  }
  new Float:ratio_max_to_current_speed = FloatDiv(max_ground_speed, GetVectorLength(velocity));
  //PrintToChat(client, "Threshold: %f - Current Speed Ratio: %f - Max Speed: %f - Current Speed: %f", GetConVarFloat(cvar_ratio_threshold), FloatDiv(1.0, ratio_max_to_current_speed), max_ground_speed, GetVectorLength(velocity)); //Ratio Test
  if (ratio_max_to_current_speed < FloatDiv(1.0, GetConVarFloat(cvar_ratio_threshold))) {
    ScaleVector(velocity, FloatMul(ratio_max_to_current_speed, GetConVarFloat(cvar_ratio_punish)));
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
  }
}
