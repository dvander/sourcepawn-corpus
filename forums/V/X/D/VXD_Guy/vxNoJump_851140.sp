#pragma semicolon 1
#include <sourcemod>
#include <dukehacks>

#define PLUGIN_VERSION "0.0.0.2"

public Plugin:myinfo = 
{
	name = "NoJump",
	author = "VX aka VXDGuy",
	description = "Prevents demojump and rocketjump",
	version = PLUGIN_VERSION,
	url = "http://elitegamin.clanservers.com/"
}



new Handle:cvFallDmg = INVALID_HANDLE;
new bool:gBlockJump = true;

public OnPluginStart()
{
	// setup convars
	CreateConVar("sm_vxnojump_version", PLUGIN_VERSION, "NoJump mod version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvFallDmg = CreateConVar("sm_vxnojump", "1", "Stop demojump and rocketjumps (1=on 0=off)");
	HookConVarChange(cvFallDmg, cvChanged);
	
	// register the TakeDamageHook function to be notified of damage
	dhAddClientHook(CHK_TakeDamage, TakeDamageHook);
}

// Note that damage is BEFORE modifiers are applied by the game
public Action:TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype)
{
  // kick in only when actively blocking blast jumps
	if (gBlockJump)
	{
	  // filter for self-damage attacks
    if (attacker == client)
    {
      // optional debugging message, identifies attacker, target, ...
      // PrintToChatAll("%N hurt %N for %.1fx%.1f (type=%08X)",attacker,client,damage,multiplier,damagetype);
      
      if (damagetype & DMG_BLAST)
      {
        if (damagetype & DMG_RADIATION)
        {
          // PrintToChatAll("[vxNoJump] %N tries to demo/rocketjump and failed.",client);
          multiplier=multiplier/6.0;
          return Plugin_Continue;
        }
      }
    }    
	}
	// let game continue with damage
	return Plugin_Continue;
}

// update gBlockJump when convar changes
public cvChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue)==1)
	{
		gBlockJump = true;
	}
	else
	{
		gBlockJump = false;
	}
}

