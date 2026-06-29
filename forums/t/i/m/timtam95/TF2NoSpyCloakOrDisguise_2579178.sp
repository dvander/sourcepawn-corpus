
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>



public Plugin:myinfo =
{
	name = "Remove Spy Disguise Kit and Cloak Weapons",
	author = "timtam95",
	description = "Remove Spy Disguise Kit and Cloak Weapons",
	version = "1.0",
	url = "https://forums.alliedmods.net"
}


public void OnPluginStart()
{
    HookEvent("player_spawn", StripWeapons);
}


public StripWeapons(Handle:event, const String:name[], bool:dontBroadcast)
{
  int client = GetClientOfUserId(GetEventInt(event, "userid"));

  if (client && IsClientInGame(client) && IsPlayerAlive(client))
  {
    int iCurrentTarget;
    int wpnEnt;
    int wpnSlotIndex;
    decl String:sWeapon[64]; 
	
    iCurrentTarget = GetClientOfUserId(GetEventInt(event, "userid"));

    for ( wpnSlotIndex = 1; wpnSlotIndex < 11; wpnSlotIndex++ )
    {
        wpnEnt = GetPlayerWeaponSlot( iCurrentTarget, wpnSlotIndex );

        if (wpnEnt != -1)
        {
 
                GetEdictClassname(wpnEnt, sWeapon, sizeof(sWeapon)); 

                if (StrEqual(sWeapon, "tf_weapon_pda_spy") || StrEqual(sWeapon, "tf_weapon_invis"))
                {
                  //PrintToChatAll("Removing %s", sWeapon);
                  RemoveEdict(wpnEnt);

                }
        }

    }

  }

}