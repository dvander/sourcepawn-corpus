#include <sourcemod>
#include <sdktools_functions>
#include <gungame>

#define GG_SLOTINDEX_KNIFE 2

// Initilize ConVar Globals
new Handle:sm_gungame_give_uses = INVALID_HANDLE;

// Set ConVar Globals to Default Values
new sm_gungame_give_uses_default = 3; // 3 uses per spawn
new g_gungame_give_uses = 3; // 3 uses per spawn
new g_gungame_give_used[MAXPLAYERS+1]; // = {0,...};

public Plugin:myinfo =
{
	name = "SM Advanced GunGame Give",
	author = "Dave Smith",
	description = "Gives the player the current weapon they are on.",
	version = "1.0",
	url = "http://avitar.net/"
};

/*
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    RegPluginLibrary("gungame_give");
    return APLRes_Success;
}
*/ 

public OnPluginStart()
{
  RegConsoleCmd("sm_give", Function_Give, "", FCVAR_GAMEDLL);
  //CreateConVar("sm_gungame_give_version", "1.0", "SM GunGame Give", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

  if( FindConVar("sm_gungame_give_uses") == INVALID_HANDLE ){
		g_gungame_give_uses = sm_gungame_give_uses_default;
  }else{
		g_gungame_give_uses = GetConVarInt(sm_gungame_give_uses);	
  }
  // HookEventEx("round_start",Function_RoundStart,EventHookMode_Post);
  HookEvent("player_spawn", EventPlayerSpawn);
}

/*
public Action:Function_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	if( sm_gungame_give_uses > 0 ){
		new i = MAXPLAYERS + 1;
		new x = 0;
		do{
			g_gungame_give_used[i] = 0;
		} while (x < i);
	}
	return Plugin_Continue
}
*/ 
/*
public Function_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {

	if( sm_gungame_give_uses > 0 ){
		new i = MAXPLAYERS + 1;
		new x = 0;
		do{
			g_gungame_give_used[i] = 0;
		} while (x < i);
	}
	return Plugin_Continue
}
*/
public EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast) {

	//if (GetConVarBool(g_CVarEnable)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		g_gungame_give_used[client] = 0;
		if(g_gungame_give_uses < 1){
		    PrintToChat(client, "\x04[SM] Type !give in console to get your current weapon.",g_gungame_give_uses);
		}else{
		    PrintToChat(client, "\x04[SM] Type !give in console up to %d per spawn to get your current weapon.", g_gungame_give_uses);
	    }
	//}
}

public Action:Function_Give(client, args){

  if ( IsPlayerAlive(client) ){

	if( (g_gungame_give_uses < 1) || (g_gungame_give_used[client] < g_gungame_give_uses ) ){
	
		decl String:weaponid[64];
	
		// get weapon name based on clients level
		// ie. compare against gg configuration via native includes

		GG_GetLevelWeaponName( GG_GetClientLevel(client), weaponid, 64 );
		
		// give that weapon
		// PrintToChat(client, "\x04Client Level %d.", GG_GetClientLevel(client) );
		// PrintToChat(client, "\x04Using weapon %s.", weaponid);
		
		if ( strcmp(weaponid,"glock",false) == 0 ) {
			StripWeaponsButKnife(client);
			GivePlayerItem(client, "weapon_glock");
			ClientCommand( client, "slot2" );  
			g_gungame_give_used[client]++;
		
		}else if ( strcmp(weaponid,"usp",false) == 0 ) {
			StripWeaponsButKnife(client);
			GivePlayerItem(client, "weapon_usp");
			ClientCommand( client, "slot2" ); 
			g_gungame_give_used[client]++;
		
		}else if ( strcmp(weaponid,"p228",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_p228");
				ClientCommand( client, "slot2" ); 
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"deagle",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_deagle");
				ClientCommand( client, "slot2" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"fiveseven",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_fiveseven");
				ClientCommand( client, "slot2" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"elite",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_elite");
				ClientCommand( client, "slot2" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"m3",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_m3");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"xm1014",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_xm1014");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"tmp",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_tmp");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"mac10",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_mac10");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"mp5navy",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_mp5navy");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"ump45",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_ump45");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"p90",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_p90");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"galil",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_galil");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"famas",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_famas");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"ak47",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_ak47");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"scout",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_scout");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"m4a1",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_m4a1");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"sg552",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_sg552");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"aug",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_aug");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"m249",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_m249");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"awp",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_awp");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;
			
		}else if ( strcmp(weaponid,"sg550",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_sg550");
				ClientCommand( client, "slot1" ); 	
				g_gungame_give_used[client]++;

		}else if ( strcmp(weaponid,"g3sg1",false) == 0 ) {
				StripWeaponsButKnife(client);
				GivePlayerItem(client, "weapon_g3sg1");
				ClientCommand( client, "slot1" ); 
				g_gungame_give_used[client]++;

		}else if ( strcmp(weaponid,"knife",false) == 0 ) {
				PrintToChat(client, "\x04[SM] Command unavailable for knife level.");		

		}else if ( strcmp(weaponid,"hegrenade",false) == 0 ) {
				PrintToChat(client, "\x04[SM] Command unavailable for grenade level.");				
				
		}else{
			PrintToChat(client, "\x04[SM] Command unavailable for %s.", weaponid);
		}
		
	}else{
		PrintToChat(client, "\x04[SM] You have used up all %d of your give uses until your next respawn.", g_gungame_give_uses);
	}
  } else {
	PrintToChat(client, "\x04[SM] You must be alive to use this command."); 
  }
  
  return Plugin_Handled;
}

// Thanks to MistaGee JailMod for this part
StripWeaponsButKnife(client)
{
	new wepIdx;
	// Iterate through weapon slots
	for( new i = 0; i < 5; i++ )  {
		if( i == GG_SLOTINDEX_KNIFE ) continue; // You can leave knife on
		// Strip all weapons from current slot
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 )    {
			RemovePlayerItem( client, wepIdx );
		}
	}
}