#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"
new Handle:g_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
  name = "SV_Gravity Patch",
  author = "Panda|USAF",
  description = "Simple plugin to prevent gravity from corrupting props in the map.",
  version = PLUGIN_VERSION,
  url = "http://alliedmods.net"
}

public OnPluginStart ()
{
  CreateConVar("sm_gravity_version", PLUGIN_VERSION, "Gravity Patch Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Enabled  = CreateConVar("sm_gravity_enable", "1", "Setting: If enabled, the gravity will be reset to 800 on map end.");
}

public OnMapEnd()
{
  if(GetConVarInt(g_Enabled))
    ServerCommand("sm_cvar sv_gravity 800");
}