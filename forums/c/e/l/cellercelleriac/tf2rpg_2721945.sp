#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sdktools> 
      
Handle SetupTimer[1];      
int PlayerClass[MAXPLAYERS+1];


public Plugin:myinfo = {
  name = "TF2RPG",
  version = "0.10",
  author = "Celler Celleriac",
  description = "Realistic weapons (sort of), friendly fire, no respawning etc. Bugs.",
  url = ""
};

public OnPluginStart()
{
  HookEvent("player_spawn", EventPlayerSpawn);
  HookEvent("player_death", EventPlayerDeath);
  HookEvent("teamplay_round_start", OnRoundStart);
  
  RegConsoleCmd("dex", Command_Dx, "destroys the exit");
  RegConsoleCmd("den", Command_Dn, "destroys the entrance");
}






public Action Command_Dx(int client, int args)
{
	if (args < 1)
	{
    ClientCommand(client, "destroy 3");
    return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action Command_Dn(int client, int args)
{
	if (args < 1)
	{
    ClientCommand(client, "destroy 1");
    return Plugin_Handled;
	}
	return Plugin_Handled;                                                        //destroying teleporters won´t work properly with the multiple buildings plugin
}







public OnMapStart()
{
    ServerCommand("mp_humans_must_join_team any");                              //during setup people can join teams, otherwise not
                                                                                
    ServerCommand("sm_setammo_showtext 0");                                     
    ServerCommand("sm_sentry_limit 3; sm_dispenser_limit 3");                   //inspired by Meet the Engineer (initially it was 7 and 10, but I think engi is op enough already)
    ServerCommand("mp_highlander 1; mp_friendlyfire 1");                        //useful built-in variables. (if i remember well they would restart on map change)
    ServerCommand("sm_cvar sv_accelerate 7; sm_cvar sv_airaccelerate 0.1");     //for realistic physics. air accelerate minimal for crouch-jumping to be possible
}







public OnClientPutInServer(client)
{
  new String:name[32];
  
  GetClientName(client, name, sizeof(name));
  
  PrintToChatAll("\x01[SERVER] \x04%s\x01 just joined the clusterfuck party", name);
  
  CreateTimer(1.0, Timer_PlayerDed);                                            //so the round begins properly when a player joins an empty server
}





//public OnClientDisconnect(client)                                             //i don´t remember what this is, probably useless :P
//{
//  CreateTimer(1.0, Timer_PlayerDed);
//}








public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{  
    PrintToChatAll("\x01Round begins in 60 secs (short for testing)\x04");
    ServerCommand("mp_humans_must_join_team any");                              //now players can join teams
    delete SetupTimer[0];
    SetupTimer[0] = CreateTimer(59.0, SetupOver);                               //setup short for testing, properly it should be a little longer
}







public Action SetupOver(Handle timer)
{
    PrintToChatAll("\x01Fight to death! Or cap points\x05");
    ServerCommand("mp_humans_must_join_team spectator");                        //now players can only join spectator
    for(new i = 1; i <= MaxClients; i++)
      {
        if(PlayerClass[i] == 9)                                                 //if the guy´s an engineer
        {
          PrintToChat(i, "Hey look buddy, you´re an engineer. (etc)");
          
          new String:name[32];
          GetClientName(i, name, sizeof(name));
          
          ServerCommand("sm_gi \"%s\" 169 3 100 -1 0 0 tf_weapon_wrench \"2 ; 0.4\" \"287 ; 6\" \"344 ; 2\"  \"732 ; 1\" \"94 ; 0\" \"2043 ; 0\" \"81 ; 1\" \"276 ; 1\" \"353 ; 1\" \"321 ; 4\" \"148 ; 10.285\" \"790 ; 0.39\"", name);
          SetEntData(i, FindDataMapOffs(i, "m_iAmmo") + (3 * 4), 200, 4);
        }                                                                       //takes the setup abilities away from the engi player
      } 
    SetupTimer[0] = null;
}









public Action:EventPlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
      CreateTimer(1.0, Timer_PlayerDed);                                        //when a player dies, the game checks if there are any more players alive (with short delay)
      return Plugin_Handled;
}
public Action:Timer_PlayerDed(Handle:timer)
{
      int red = 0;
      int blu = 0;
      for(new i = 1; i <= MaxClients; i++)                                      
      {
      
        if(i && IsClientInGame(i) && IsPlayerAlive(i))                          
        {   
          if(GetClientTeam(i) == 2)                                              
          {
            red = 1;
          } 
          if(GetClientTeam(i) == 3)                                             
          {
            blu = 1;                                                            //decide if there are alive players on each team
          }
        }                                                                       
      }  



      if(red == 0 && blu == 1)
      {
        ServerCommand("sv_cheats 1");
        ServerCommand("mp_forcewin 3");
        ServerCommand("sv_cheats 0");                                           //blu wins - this is the stupidest way to force a win, i don´t have a clue how else to trigger it though.... pls help
      }
      if(red == 1 && blu == 0)
      {
        ServerCommand("sv_cheats 1");
        ServerCommand("mp_forcewin 2");
        ServerCommand("sv_cheats 0");                                           //red wins
      }
      if(red == 0 && blu == 0)
      {
        ServerCommand("sv_cheats 1");
        ServerCommand("mp_forcewin 0");
        ServerCommand("sv_cheats 0");                                           //stalemate
      }
      return Plugin_Handled;
} 

        












public Action:EventPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
 
 
    new String:name[32];
    PlayerClass[client] = 0;
 
    GetClientName(client, name, sizeof(name));
    
    if (client && IsClientInGame(client) && IsPlayerAlive(client))
    {
        new class = GetEventInt(event, "class");
       
       
        if (class == 1)
        {   
            ServerCommand("sm_gi \"%s\" 45 1 100 -1 0 0 tf_weapon_scattergun \"2 ; 5\" \"6 ; 0.1\" \"43 ; 1\" \"3 ; 0.33\" \"106 ; 3\" \"45 ; 2\" \"775 ; 0.1\" \"49 ; 1\" \"15 ; 1\" \"68 ; -1\" \"96 ; 1.2\" \"773 ; 4\" \"772 ; 2\" \"61 ; 3\"; sm_gi \"%s\" 23 2 100 -1 0 0 tf_weapon_pistol \"2 ; 1\" \"20\" \"408\" \"775 ; 0.1\" \"106 ; 5\" \"804 ; 0.1\" \"773 ; 1.4\" \"96 ; 1.5\"; sm_gi \"%s\" 0 3 100 -1 0 0 tf_weapon_bat \"2 ; 0.5\" \"775 ; 0\" \"773 ; 1\" \"269\"", name, name, name);            
        }
        
        if (class == 2)
        {   
            ServerCommand("sm_gi \"%s\" 14 1 100 -1 0 0 tf_weapon_sniperrifle \"2 ; 2\" \"421\" \"77 ; 2\" \"775 ; 0.025\" \"41 ; 0\" \"46\" \"15\" \"266 ; 1\" \"773 ; 3\" \"772 ; 1.2\" \"61 ; 3\" \"378 ; 0.2\"; sm_gi \"%s\" 16 2 100 -1 0 0 tf_weapon_smg \"2 ; 2\" \"20\" \"408\" \"775 ; 0.1\" \"773 ; 1.8\" \"96 ; 2\" \"804 ; 0.1\" \"106 ; 5\"; sm_gi \"%s\" 3 3 100 -1 0 0 tf_weapon_club \"2 ; 1.2\" \"775 ; 0.1\" \"773 ; 1.2\" \"772 ; 1.6\" \"269\"", name, name, name);
            ServerCommand("sm_setammo \"%s\" 1 50", name);
                        
        }
        
        if (class == 3)
        {   
            ServerCommand("sm_gi \"%s\" 18 1 100 -1 0 0 tf_weapon_rocketlauncher \"2 ; 9\" \"207 ; 1000\" \"3 ; 0.25\" \"77 ; 0.2\" \"96 ; 3\" \"99 ; 1.8\" \"117 ; -0.7\" \"103 ; 2\" \"411 ; 1.1\" \"15 ; 1\" \"54 ; 0.6\" \"443 ; 0.71\" \"773 ; 8\" \"772 ; 2\" \"285 ; 1\"; sm_gi \"%s\" 10 2 100 -1 0 0 tf_weapon_shotgun_soldier \"2 ; 6\" \"775 ; 0.1\" \"15 ; 1\" \"5 ; 1.1\" \"96 ; 2\" \"773 ; 2\"; sm_gi \"%s\" 6 3 100 -1 0 0 tf_weapon_shovel \"773 ; 2\" \"775 ; 0.1\" \"61 ; 3\" \"269\" \"68 ; 1\"; sm_setammo \"%s\" 1 4", name, name, name, name);
            
        }
        
        if (class == 4)
        {   
            ServerCommand("sm_gi \"%s\" 19 1 100 -1 0 0 tf_weapon_grenadelauncher \"2 ; 7\" \"3 ; 1.5\" \"77 ; 0.375\" \"96 ; 1.5\" \"99 ; 2\" \"102 ; 1.1\" \"207 ; 100\" \"117 ; -0.7\" \"411 ; 2.6\" \"681\" \"467 ; -1\" \"787 ; 2\" \"15 ; 1\" \"773 ; 3\" \"772 ; 2\"; sm_gi \"%s\" 20 2 100 -1 0 0 tf_weapon_pipebomblauncher \"2 ; 6\" \"3 ; 0.125\" \"102 ; 0.45\" \"79 ; 0.333\" \"99 ; 1.7\" \"6 ; 0.6\" \"207 ; 100\" \"117 ; -0.7\" \"411 ; 2.6\" \"120 ; -1\" \"88 ; 100\" \"15 ; 1\" \"773 ; 3\" \"772 ; 2\" \"285 ; 1\"; sm_gi \"%s\" 1 3 100 -1 0 0 tf_weapon_bottle \"2 ; 0.5\" \"775 ; 0\" \"773 ; 1.2\" \"61 ; 3\" \"54 ; 0.68\" \"443 ; 0.88\" \"269\" \"68 ; 1\"; sm_setammo \"%s\" 1 6; sm_setammo \"%s\" 2 8", name, name, name, name, name);
            
        }
        
        if (class == 5)
        {   
            ServerCommand("sm_gi \"%s\" 17 1 100 -1 0 0 tf_weapon_syringegun_medic \"2 ; 0.2\" \"96 ; 1.6\" \"775 ; 0\" \"773 ; 2\" \"61 ; 3\" \"3 ; 0.3\" \"77 ; 0.32\" \"149 ; 75\"; sm_gi \"%s\" 29 2 100 -1 0 0 tf_weapon_medigun \"773 ; 2.4\" \"772 ; 2\" \"11 ; -1\" \"9 ; 0.02\" \"314 ; 12\" \"739 ; 4\"; sm_gi \"%s\" 8 3 100 -1 0 0 tf_weapon_bonesaw \"2 ; 0.7\" \"775 ; 0\" \"773 ; 1.4\" \"269\" \"54 ; 0.7\"; sm_setammo \"%s\" 1 48", name, name, name, name);
            CreateTimer(0.25, Timer_PlayerUberDelay, client);
        }
        
        if (class == 6)
        {   
            ServerCommand("sm_gi \"%s\" 15 1 100 -1 0 0 tf_weapon_minigun \"2 ; 5\" \"20\" \"408\" \"106 ; 0.4\" \"183 ; 0.2\" \"443 ; 0.69\" \"775 ; 0.02\" \"323 ; 10\" \"266 ; 1\" \"773 ; 7\" \"772 ; 6\" \"421\" \"45 ; 0.25\" \"6 ; 0\" \"76 ; 10\"; sm_gi \"%s\" 11 2 100 -1 0 0 tf_weapon_shotgun_hwg \"2 ; 6\" \"68 ; 2\" \"775 ; 0.1\" \"15 ; 1\" \"5 ; 1.4\" \"96 ; 2.2\" \"775 ; 0.1\" \"773 ; 2\"; sm_gi \"%s\" 5 3 100 -1 0 0 tf_weapon_fists \"2 ; 0.8\" \"775 ; 0.01\" \"773 ; 1.2\" \"269\" \"54 ; 0.5\" \"61 ; 3\"", name, name, name);
            ServerCommand("sm_setammo \"%s\" 1 2000", name);
        }   
        
        if (class == 7)
        {   
            ServerCommand("sm_gi \"%s\" 12 2 100 -1 0 0 tf_weapon_shotgun_pyro \"2 ; 6\" \"421\" \"775 ; 0.1\" \"15 ; 1\" \"5 ; 1.4\" \"96 ; 2.2\" \"773 ; 2\" \"772 ; 3\" \"54 ; 0.7\" \"443 ; 0.92\" \"61 ; 1.5\"; sm_gi \"%s\" 2 3 100 -1 0 0 tf_weapon_fireaxe \"775 ; 1\" \"269\" \"68 ; 1\"", name, name);        }
        
        if (class == 8)
        {   
            ServerCommand("sm_gi \"%s\" 24 1 100 -1 0 0 tf_weapon_revolver \"2 ; 1\" \"20\" \"408\" \"106 ; 4\" \"804 ; 0.2\" \"775 ; 0.2\" \"773 ; 2\" \"61 ; 3\" \"96 ; 1.4\"; sm_gi \"%s\" 4 3 100 -1 0 0 tf_weapon_knife \"425 ; 0\" \"429 ; 0.2\" \"775 ; 0\" \"773 ; 1.4\"; sm_gi \"%s\" 30 5 100 -1 0 0 tf_weapon_invis \"34 ; -5\" \"35 ; 0\" \"221 ; 1\" \"253 ; 1\" \"48 ; 2\" \"816\"", name, name, name);
            
            PlayerClass[client] = 8;
        }
        
        if (class == 9)
        {      
            ServerCommand("sm_gi \"%s\" 9 1 100 -1 0 0 tf_weapon_shotgun_primary \"2 ; 6\" \"775 ; 0.1\" \"15 ; 1\" \"5 ; 1.4\" \"96 ; 2\" \"773 ; 2\" \"443 ; 0.92\" \"61 ; 3\"  \"269\" \"353 ; 1\"; sm_gi \"%s\" 22 2 100 -1 0 0 tf_weapon_pistol \"2 ; 1\" \"20\" \"408\" \"96 ; 1.35\" \"775 ; 0.1\" \"773 ; 2\" \"804 ; 0.1\" \"106 ; 5\" \"79 ; 0.36\"; sm_gi \"%s\" 7 3 100 -1 0 0 tf_weapon_wrench \"2 ; 0.4\" \"287 ; 6\" \"344 ; 2\" \"732 ; 0\" \"353 ; 0\" \"321 ; 1\" \"94 ; 0\" \"2043 ; 8\" \"148 ; 1\" \"81 ; 5\" \"464 ; 2\" \"276 ; 1\" \"790 ; 0\"", name, name, name);
            SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 2000, 4);
            ServerCommand("sm_setammo \"%s\" 2 72", name);
            
            PrintToChat(client, "Hey look buddy. You´re an engineer. (tutorial etc)");
            
            PlayerClass[client] = 9;        
        }                                                                       //the second stupidest thing in this whole script - it should be completely rewritten into straight code with no stupid callbacks. i´m a script noob though. pls help
        
    }      
}          
public Action:Timer_PlayerUberDelay(Handle:timer, any:client)                   //if a player is medic, this fills their uber level on 100% (with 0.25s delay, for some reason it wouldn´t work otherwise)
{
    new index = GetPlayerWeaponSlot(client, 1);
    SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", 1.0); 
}     
  
  
  
  
  
  
  
  
  
  
  
  
  
  
public void OnEntityCreated(int entity, const char[] classname)
{
		if (StrContains(classname, "tf_ammo_pack", false) != -1)
		{
			SDKHook(entity, SDKHook_SpawnPost, OnAmmoPackSpawn);
		}
}

public void OnAmmoPackSpawn (int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
	if (client >= 1)
		AcceptEntityInput(entity, "Kill");                                          //delete ammopacks because - ammo types matter (and you can already pick the correct ammo from the dropped weapon) and so there´s no ammo from destroyed buildings
}

