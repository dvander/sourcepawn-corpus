#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0.2"

/*

  v1.0.2
  - Fixed Client Index 0 Bug
  
  v1.0.1
  - Added explosion sound and sprite effect (ala firebomb of funcommands) when client is slain
  - Fixed slay message spam when shot by a shotgun
  
  v1.0.0
  - Initial Release
  
*/

// Definitions
static Punish_Check = 0;
static Handle:Punish_Time = INVALID_HANDLE; //Time to allow for slaying
static Handle:Punish_Timer = INVALID_HANDLE; //Timer to check if slaying is okay
static Handle:Punish_Announce = INVALID_HANDLE; //Announce the slay
static Handle:Punish_Restore = INVALID_HANDLE; //Restore victim's health
static Handle:Punish_Restore_Announce = INVALID_HANDLE; //Restore victim's health

static Handle:FF_cvar = INVALID_HANDLE; //FF cvar check
new victim_client = 0; //Client index to match victim
new attacker_client = 0; //Client index to match attacker

//Sounds
#define SOUND_BOOM		"weapons/explode3.wav"

//Sprite
new g_ExplosionSprite   = -1;

public Plugin:myinfo =
{
	name = "Spawn Friendly Fire Punishment",
	author = "HowIChrgeLazer",
	description = "Punish people who friendly fire at the beginning of the round",
	version = PL_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1663377"
};
 
public OnPluginStart()
{
  HookEvent("player_hurt", Event_PlayerHurt);
  HookEvent("player_death", Event_PlayerDeath);
  HookEvent("round_freeze_end", Event_RoundFreezeEnd);
  
  // Cvar for plugin version
  CreateConVar("spawnff_version", PL_VERSION, "Spawn FF", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  
  // Cvars for plugin functionality
  Punish_Time = CreateConVar("spawnff_time", "5.00", "How many seconds to allow punishment for spawn ff", FCVAR_PLUGIN);
  Punish_Announce = CreateConVar("spawnff_announce_slay", "1", "Announce the slay punishment (0 = off, 1 = on)", FCVAR_PLUGIN);
  Punish_Restore = CreateConVar("spawnff_restore", "1", "Restore health to the victim (0 = off, 1 = on)", FCVAR_PLUGIN);
  Punish_Restore_Announce = CreateConVar("spawnff_announce_restore", "0", "Announce the health restore (0 = off, 1 = on)", FCVAR_PLUGIN);
  
  FF_cvar = FindConVar("mp_friendlyfire");
  AutoExecConfig (true, "spawnff_punish");
}

public OnMapStart()
{
  PrecacheSound(SOUND_BOOM, true);
  g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
}

// Freeze time is over, let's get started
public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
  
  // Check FF CVAR and skip if FF is off
  if (GetConVarInt(FF_cvar) != 1 || GetConVarFloat(Punish_Time) <= 0.00)
  {
    return;
  }
  
  // Start the count down timer! All FF will result in slay unil this ends
  Punish_Timer = CreateTimer(GetConVarFloat(Punish_Time), PunishTimerEnd);
  Punish_Check = 1;
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
  // Check FF CVAR and skip if FF is off
  if (GetConVarInt(FF_cvar) != 1)
  {
    return;
  }
  
  // Get the information and client indexes of the attacker and victim
  
  new attacker_id = GetEventInt(event, "attacker");
  attacker_client = GetClientOfUserId(attacker_id);
  
  new victim_id = GetEventInt(event, "userid");
  victim_client = GetClientOfUserId(victim_id);
  
  if (attacker_client == 0 || victim_client == 0)
  {
    return;
  }
  
  new attacker_team = GetClientTeam(attacker_client);
  new victim_team = GetClientTeam(victim_client);
  
  
  
  // Victim and Attacker aren't on the same team, bail out!
  if (victim_team != attacker_team)
	{
    return;
	}
  
  // Punish timer ended or is off
  if (Punish_Check == 0)
  {
    return;
  }
	
	// Time to slay the player! Let's get his name too, and do some nifty effects
	new Float:vec[3];
	GetClientEyePosition(attacker_client, vec);
	TE_SetupExplosion(vec, g_ExplosionSprite, 0.05, 1, 0, 1, 1);
	TE_SendToAll();
	EmitAmbientSound(SOUND_BOOM, vec, attacker_client, SNDLEVEL_RAIDSIREN);
	ForcePlayerSuicide (attacker_client);
	
	// If we feel bad enough, give the victim his or her health back
	if (GetConVarInt(Punish_Restore) == 1)
	{
    decl String: victim_name[64];
    GetClientName(victim_client, victim_name, sizeof(victim_name));
    new damage_health	= GetEventInt(event, "dmg_health");
    new victim_health = GetClientHealth(victim_client);
    SetEntityHealth (victim_client, (victim_health + damage_health));
    
    // And maybe announce it too if we feel like it
    if (GetConVarInt(Punish_Restore_Announce) == 1)
    {
      PrintToChatAll ("[SM] %s had %i health restored due to spawn friendly fire.", victim_name, damage_health);
    }
	}
	
}

// To prevent repeat slay announcement when using a shotgun, we'll announce on death
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  // Punish timer ended or is off
  if (Punish_Check == 0)
  {
    return;
  }
  
  if (attacker_client == 0 || victim_client == 0)
  {
    return;
  }
  
  new check_attacker_id = GetEventInt(event, "userid");
  new check_attacker_client = GetClientOfUserId(check_attacker_id);
  
  if (check_attacker_client == attacker_client && GetConVarInt(Punish_Announce) == 1)
  {
    decl String: attacker_name[64];
    GetClientName(check_attacker_client, attacker_name, sizeof(attacker_name));
    PrintToChatAll ("[SM] %s was slain for attacking at spawn.", attacker_name);
  }
}

// Kill the timer when it's done
public Action:PunishTimerEnd(Handle:timer)
{
  Punish_Check = 0;
  KillTimer (Punish_Timer);
}