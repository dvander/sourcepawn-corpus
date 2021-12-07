#include <sourcemod>
#include <tf2>
#include <tf2_stocks>


public Plugin myinfo =
{
	name = "Spec Hit Sound",
	author = "lugui",
	description = "Plays a hitsound for spectators",
	version = "2.0",
	url = ""
}


public void OnPluginStart()
{
	PrecacheSound("*/buttons/button10.wav", true);
	HookEvent("player_hurt", OnTakeDamage);
	
 }
 
 public OnTakeDamage(Handle event, const char[] name, bool dontBroadcast)
 {
	if(GetTeamClientCount(1) > 0 ){
		
		int victim =  GetClientOfUserId(GetEventInt(event, "userid"));
		int attacker =  GetClientOfUserId(GetEventInt(event, "attacker"));
		
		for (int i = 1; i <= MaxClients; i++){
			if(IsValidClient(i) && IsClientObserver(i)){
				int observertarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				int observermode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				
				if (observertarget == attacker && (observermode == 4 || observermode == 5) && attacker != victim ){
					EmitSoundToClient(i, "*/buttons/button10.wav");
					EmitSoundToClient(i, "*/buttons/button10.wav");
					EmitSoundToClient(i, "*/buttons/button10.wav");
					
			}
				}
			else {
				continue;
			}
		}
	}
 }



IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}