#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new Handle:cvarEnable;
new Handle:cvarGuns;
new Handle:cvarRadius;
new Handle:cvarMagnitude;

// Functions
public Plugin:myinfo =
{
  name = "Rocket Guns",
  author = "bl4nk",
  description = "Specified guns shoot explosive rounds",
  version = PLUGIN_VERSION,
  url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
  CreateConVar("sm_rocketguns_version", PLUGIN_VERSION, "Rocket Guns Version", 
FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  cvarEnable = CreateConVar("sm_rocketguns_enable", "1", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
  cvarGuns = CreateConVar("sm_rocketguns_guns", "scout", "Which guns shoot explosions (separated by spaces)", FCVAR_PLUGIN);
  cvarRadius = CreateConVar("sm_rocketguns_radius", "85", "Radius of the explosions", FCVAR_PLUGIN, true, 1.0, false, _);
  cvarMagnitude = CreateConVar("sm_rocketguns_magnitude", "50", "Magnitude of the explosions", FCVAR_PLUGIN, true, 1.0, 
false, _);

  PrecacheGeneric("sprites/zerogxplode.spr", true);
  HookEvent("bullet_impact", event_BulletImpact);
}

public Action:event_BulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
  if (!GetConVarInt(cvarEnable))
    return;

  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  new Float:origin[3];
  origin[0] = GetEventFloat(event, "x");
  origin[1] = GetEventFloat(event, "y");
  origin[2] = GetEventFloat(event, "z");

  decl String:weapon[32], String:gunsString[255];
  GetClientWeapon(client, weapon, sizeof(weapon));
  ReplaceString(weapon, sizeof(weapon), "weapon_", "");

  GetConVarString(cvarGuns, gunsString, sizeof(gunsString));

  new startidx = 0;
  if (gunsString[0] == '"')
  {
    startidx = 1;

    new len = strlen(gunsString);
    if (gunsString[len-1] == '"')
    {
      gunsString[len-1] = '\0';
    }
  }

  if (StrContains(gunsString[startidx], weapon, false) != -1)
  {
    new radius = GetConVarInt(cvarRadius);
    new magnitude = GetConVarInt(cvarMagnitude);

    decl String:s_radius[32], String:s_magnitude[32];
    IntToString(radius, s_radius, sizeof(s_radius));
    IntToString(magnitude, s_magnitude, sizeof(s_magnitude));

    new entity = CreateEntityByName("env_explosion");
    DispatchKeyValueVector(entity, "origin", origin);
    DispatchKeyValue(entity, "imagnitude", s_magnitude);
    DispatchKeyValue(entity, "iradiusoverride", s_radius);
    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

    DispatchSpawn(entity);
    AcceptEntityInput(entity, "Explode");

    TE_SetupExplosion(origin, -1, 1.0, 30, TE_EXPLFLAG_NONE, radius, magnitude);
    TE_SendToClient(client);
  }
}

