#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define VERSION "1.0"
#define DAMAGE_SOUND "buttons/blip1.wav"

public Plugin:myinfo =
{
	name = "Damage Indicator Sound HL2/HL2DM",
	author = "XARiUS",
	description = "Plugin which indicates damage by playing a brief sound.",
	version = "1.0",
	url = "http://www.the-otc.com/"
};

new bool:g_enabled;
new Handle:g_Cvarenabled = INVALID_HANDLE;

public OnPluginStart()
{
  CreateConVar("sm_damagesound_version", VERSION, "Damage Indicator Sound", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Cvarenabled = CreateConVar("sm_damagesound_enabled", "1", "Enable this plugin. 0 = Disabled");

  HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Post);

  HookConVarChange(g_Cvarenabled, OnSettingChanged);
}

public OnConfigsExecuted()
{
  PrecacheSound(DAMAGE_SOUND, true);
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
  if (convar == g_Cvarenabled)
  {
    if (newValue[0] == '1')
    {
			g_enabled = true;
    }
    else
    {
      g_enabled = false;
    }
  }
}

public Action:EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
  if (g_enabled)
  {
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    if (attacker != victim && attacker != 0 && victim != 0)
    {
      EmitSoundToClient(attacker, DAMAGE_SOUND);
    }
  }
  return Plugin_Continue;
}
