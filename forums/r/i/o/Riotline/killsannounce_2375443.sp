#include <sourcemod>
#include <tf2jail>
#include <morecolors>
 
public Plugin:myinfo =
{
    name = "-=II=- Kills",
    author = "Riotline/Astrak",
    description = "Announces the death of players.",
    version = "1.2",
    url = ""
};
 
public OnPluginStart()
{
    HookEvent("player_death", OnClientDied, EventHookMode_Pre);
}
 
public OnClientDied(Handle:event, const String:name[], bool:dontBroadcast)
{
   new victim = GetClientOfUserId(GetEventInt(event, "userid"));
   new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
   new String:victimName[MAX_NAME_LENGTH];
   GetClientName(victim, victimName, sizeof(victimName));
   new clientTeam = GetClientTeam(victim);
   new String:victimjail[64];
   new String:attackerjail[64];
 
   if( GetClientTeam(victim) == 3 )
   {
       if( TF2Jail_IsWarden(victim) == true )
       {
           victimjail = "{fullblue}(Warden)"
       }
       else
       {
           victimjail = "{fullblue}(Guard)"
       }
   }
   else if( clientTeam == 2 )
   {
       if( TF2Jail_IsRebel(victim) == true )
       {
           victimjail = "{fullred}(Rebel)"
       }
       else if ( TF2Jail_IsFreeday(victim) == true )
	   {
	       victimjail = "{aqua}(Freeday)"
	   }
	   else
       {
           victimjail = "{tomato}(Non-Rebel)"
       }
   }
 
   new String:attackerName[MAX_NAME_LENGTH];
   GetClientName(attacker, attackerName, sizeof(attackerName));
   clientTeam = GetClientTeam(attacker);
 
   if( clientTeam == 3 )
   {
       if( TF2Jail_IsWarden(attacker) == true )
       {
           attackerjail = "{fullblue}(Warden){white}"
       }
       else
       {
           attackerjail = "{fullblue}(Guard){white}"
       }
   }
   else if( clientTeam == 2 )
   {
       if( TF2Jail_IsRebel(attacker) == true )
       {
           attackerjail = "{fullred}(Rebel){white}"
       }
       else if ( TF2Jail_IsFreeday(attacker) == true )
	   {
	       attackerjail = "{aqua}(Freeday){white}"
	   }
	   else
       {
           attackerjail = "{tomato}(Non-Rebel){white}"
       }
   }
 
   if( (attacker < 33) && (attacker != 0) && attacker != victim)
   {
      CPrintToChatAll("{lime}[Kills]{white} %s%s  killed %s%s", attackerName, attackerjail, victimName, victimjail);
   }
   else
   {
      PrintToServer("\"%s\" has suicided", victimName);
   }
}