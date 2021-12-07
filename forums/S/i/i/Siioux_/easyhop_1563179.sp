#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define EasyHop_Version "v1.0"

public Plugin:myinfo = {
  name = "Easy Hop",
  author = "Siioux.",
  description = "A simple plugin to help players in BunnyHop.",
  version = EasyHop_Version,
  url = "http://liquidbr.com"
};

public OnPluginStart() {
  CreateConVar( "EasyHop_Version", EasyHop_Version, "Easy Hop Version", FCVAR_NOTIFY );
  HookEvent("player_jump", PlayerJump);
}

public Action:PlayerJump(Handle:event, const String:name[], bool:dontBroadcast) {
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
}