/*
* Prop Bonus Round (TF2) 
* Author(s): retsam
* File: prop_bonus_round.sp
* Description: Turns the losing team into random props during bonus round!
*
* Credits to: strontiumdog for the idea based off his DODS version.
* Credits to: Antithasys for SMC Parser/SM auto-cmds code and much help!
* 
* 1.5 - Modify by Sillium - merged changes by Pfsm999, Thraka and FlaminSarge
* 1.4 - Modify by Pfsm999 - Remove all cosmetic item and canteen for mvm mode. Add some color with morecolors color and add translation.
* 1.3 - Accidently forgot about the whole hat invisibility issue in previous update. This is a fix for that.
*
* 1.2 - Removed colorize code. Decided to allow guns to show visible. 
*     - Commented out 12 models from list as to help reduce strain on precache table that is causing crashes. Thx valve..
*     - Did a little code maintenance....
*     
* 1.1 - Added check to make sure admin flag cvar isnt set to nothing.
*     - Added cvar to respawn dead team players so everyone can be propped. 
*
* 1.0 - Added stripping of all weapons to fix issue of player view models getting visual glitches with new model code when pressing attack.
* 0.9 - Possible fix for issue of models failing to be reset on round-start?
* 0.8 - Added public announcement printtochatall msg w/ cvar. Fixed plugin being broken due to valve update. Fixed incorrect post hook callbacks.
*       Had to remove (3) models from the models file due to them spawning halfway in ground and no longer being able to fix this.  Thirdperson command currently not showing models and needs fixing.
* 0.7 - Removed Logactivity cvar, no longer needed I dont think. Removed the precache models console spam. 
* 0.6 - Fix for non-prop errors. New Addcond code to deal with demoman glowing eyes. Flagged equip timer with timer_flag_no_mapchange. 
* 0.5 - Changed deletion code again(Crash issues fixed?). Fixed couple potential issues related to plugin being disabled.
* 0.4.1 - Changed the prop deletion code a bit. 
* 0.4 - Removed sm_forcethird cvar, forgot losing team in TF2 is already put into thirdperson. Changed IsValidEdict to IsValidEntity(possible crash issue?). Added couple more models.
* 0.3 - Added admin command for turning players into props. Moved some stuff around.
* 0.2   - Added admin only cvar and flag.  Added a log debug cvar. Put in a couple checks related to model stuff. 
* 0.1   - Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>

#define PLUGIN_VERSION "1.5"

#define INVIS               {255,255,255,0}
#define NORMAL               {255,255,255,255}

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:Cvar_AdminFlag = INVALID_HANDLE;
new Handle:Cvar_AdminOnly = INVALID_HANDLE;
new Handle:Cvar_ThirdTriggers = INVALID_HANDLE;
new Handle:Cvar_ThirdPerson = INVALID_HANDLE;
new Handle:Cvar_Enabled = INVALID_HANDLE;
new Handle:Cvar_HitRemoveProp = INVALID_HANDLE;
new Handle:Cvar_Announcement = INVALID_HANDLE;
new Handle:Cvar_Respawnplayer = INVALID_HANDLE;
new Handle:Cvar_LogModels = INVALID_HANDLE;
new Handle:g_hModelNames = INVALID_HANDLE;
new Handle:g_hModelPaths = INVALID_HANDLE;
new Handle:g_hModelExcludePaths = INVALID_HANDLE;
new Handle:g_hModelFinalPaths = INVALID_HANDLE;
new Handle:g_hModelMapBased = INVALID_HANDLE;

new g_adminonlyCvar;
new g_thirdpersonCvar;
new g_hitremovePropCvar;
new g_announcementCvar;
new g_respawnplayerCvar;
new g_winnerTeam;

new g_InThirdperson[MAXPLAYERS+1] = { 0, ... };
new g_IsPropModel[MAXPLAYERS+1] = { 0, ... };
new g_iPlayerModelIndex[MAXPLAYERS+1] = { -1, ... };
//new g_iFov[MAXPLAYERS+1] = { -1, ... };
//new g_iDefFov[MAXPLAYERS+1] = { -1, ... };

new g_oFOV;
new g_oDefFOV;

new bool:bIsPlayerAdmin[MAXPLAYERS + 1] = { false, ... };
new bool:g_bIsEnabled = true;
new bool:g_bBonusRound = false;

new String:g_sConfigPath[PLATFORM_MAX_PATH];
new String:g_sCharAdminFlag[32];

public Plugin:myinfo = 
{
   name = "Prop Bonus Round",
   author = "retsam;Thraka;Pfsm999;FlaminSarge;sillium",
   description = "Turns the losing team into random props during bonus round!",
   version = PLUGIN_VERSION,
   url = "http://forums.alliedmods.net/showthread.php?t=119481"
}

public OnPluginStart()
{
   CheckGame();
   LoadTranslations("prop_bonus_round.phrases");
   CreateConVar("sm_propbonus_version", PLUGIN_VERSION, "Version of Prop Bonus Round", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
   Cvar_Enabled = CreateConVar("sm_propbonus_enabled", "1", "Enable/Disable prop bonus round plugin.");
   Cvar_AdminOnly = CreateConVar("sm_propbonus_adminonly", "0", "Enable plugin for admins only? (1/0 = yes/no)");
   Cvar_AdminFlag = CreateConVar("sm_propbonus_flag", "b", "Admin flag to use if adminonly is enabled (only one).  Must be a in char format.");
   Cvar_ThirdPerson = CreateConVar("sm_propbonus_allowtriggers", "0", "Allow prop players thirdperson triggers?(1/0 = yes/no)");
   Cvar_Announcement = CreateConVar("sm_propbonus_announcement", "1", "Public announcement msg at start of bonus round?(1/0 = yes/no)");
   Cvar_HitRemoveProp = CreateConVar("sm_propbonus_removeproponhit", "0", "Remove player prop once they take damage?(1/0 = yes/no)");
   Cvar_Respawnplayer = CreateConVar("sm_propbonus_respawndead", "0", "Respawn dead players at start of bonusround?(1/0 = yes/no)");
   Cvar_LogModels = CreateConVar("sm_propbonus_logmodels", "0", "Print the models found by map and the ones included and excluded by config? (1/0 = yes/no)");
   Cvar_ThirdTriggers = CreateConVar("sm_propbonus_triggers", "thirdperson,third", "SM command triggers for thirdperson - Separated by commas. Each will have the !third, /third, sm_third associated with it.");

   RegAdminCmd("sm_propplayer", Command_Propplayer, ADMFLAG_BAN, "sm_propplayer <#userid|name>");
   RegAdminCmd("sm_propme", Command_Propself, ADMFLAG_CUSTOM1, "sm_propme");
   HookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
   HookEvent("teamplay_round_win", Hook_RoundWin, EventHookMode_Post);
   HookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
   HookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Post);
   
   HookConVarChange(Cvar_Enabled, Cvars_Changed);
   HookConVarChange(Cvar_ThirdPerson, Cvars_Changed);
   HookConVarChange(Cvar_HitRemoveProp, Cvars_Changed);
   HookConVarChange(Cvar_AdminOnly, Cvars_Changed);
   HookConVarChange(Cvar_Announcement, Cvars_Changed);
   HookConVarChange(Cvar_Respawnplayer, Cvars_Changed);
   
   g_oFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
   g_oDefFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
   
   CreateThirdpersonCommands();
   
   new Handle:topmenu;
   if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
   {
      OnAdminMenuReady(topmenu);
   }
   
   g_hModelMapBased = CreateArray(PLATFORM_MAX_PATH, 0);

   AutoExecConfig(true, "plugin.propbonusround");
}


public OnEntityCreated(entity, const String:classname[])
{
   //tf_ammo_pack
   //item_healthkit_small
   //func_brush
   //ammo
   //health
   if (StrContains(classname, "prop_", false) != -1)
   {
      SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
   }
}

public OnEntitySpawned(entity)
{
   new bool:logModel = GetConVarBool(Cvar_LogModels);
   decl String:propName[500];
   GetEntPropString(entity, Prop_Data, "m_ModelName", propName, sizeof(propName));

   if (!StrEqual(propName, ""))
   {
      if (!ModelNameExists(g_hModelMapBased, propName))
      {
         if (logModel)
            LogMessage("Prop Map Loaded: %s", propName);
         PushArrayString(g_hModelMapBased, propName);
      }
   }
}

public bool:ModelNameExists(Handle:array, const String:model[])
{
   new propArrayMax = GetArraySize(array);

   for (new i = 0; i < propArrayMax; i++)
   {
      new String:tempName[256];
      GetArrayString(array, i, tempName, sizeof(tempName));

      if (StrEqual(tempName, model, false))
      {
         return true;
      }
   }
   return false;
}



public OnClientPostAdminCheck(client)
{
   if(IsValidAdmin(client, g_sCharAdminFlag))
   {
      bIsPlayerAdmin[client] = true;
   }
   else
   {
      bIsPlayerAdmin[client] = false;
   }

   g_InThirdperson[client] = 0;
   g_IsPropModel[client] = 0;
   g_iPlayerModelIndex[client] = -1;
   //g_iFov[client] = -1;
   //g_iDefFov[client] = -1;
}

public OnConfigsExecuted()
{
   g_bBonusRound = false;

   g_bIsEnabled = GetConVarBool(Cvar_Enabled);
   GetConVarString(Cvar_AdminFlag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));

   g_thirdpersonCvar = GetConVarInt(Cvar_ThirdPerson);
   g_hitremovePropCvar = GetConVarInt(Cvar_HitRemoveProp);
   g_adminonlyCvar = GetConVarInt(Cvar_AdminOnly);
   g_announcementCvar = GetConVarInt(Cvar_Announcement);
   g_respawnplayerCvar = GetConVarInt(Cvar_Respawnplayer);
}

public OnClientDisconnect(client)
{
   g_InThirdperson[client] = 0;
   g_iPlayerModelIndex[client] = -1;
   g_IsPropModel[client] = 0;
}

public OnMapStart()
{
   new String:mapName[128];
   new String:mapConfigFile[PLATFORM_MAX_PATH];
   new bool:logModel = GetConVarBool(Cvar_LogModels);

   GetCurrentMap(mapName, sizeof(mapName));

   if (g_hModelFinalPaths != INVALID_HANDLE)
      ClearArray(g_hModelFinalPaths);
   if (g_hModelExcludePaths != INVALID_HANDLE)
      ClearArray(g_hModelExcludePaths);

   //Process the models data file and make sure it exists. If not, create default.
   ProcessConfigFile();

   ProcessExcludeFile("propbonusround_models_exclude.txt");
   Format(mapConfigFile, PLATFORM_MAX_PATH, "propbonusround_%s_exclude.txt", mapName);
   ProcessExcludeFile(mapConfigFile);

   ProcessIncludeFile("propbonusround_models_include.txt");
   Format(mapConfigFile, PLATFORM_MAX_PATH, "propbonusround_%s_include.txt", mapName);
   ProcessIncludeFile(mapConfigFile);

   // Build the final list of models
   new mapModelMax = GetArraySize(g_hModelMapBased);

   for (new i = 0; i < mapModelMax; i++)
   {
      new String:tempName[PLATFORM_MAX_PATH];
      GetArrayString(g_hModelMapBased, i, tempName, sizeof(tempName));

      if (!ModelNameExists(g_hModelExcludePaths, tempName))
      {
         if (!ModelNameExists(g_hModelFinalPaths, tempName))
         {
            PushArrayString(g_hModelFinalPaths, tempName);
         }
      }
   }

   //Precache all models and names. (for the admin menu)
   decl String:sPath[PLATFORM_MAX_PATH];
   for(new i = 0; i < GetArraySize(g_hModelNames); i++)
   {
      GetArrayString(g_hModelPaths, i, sPath, sizeof(sPath));
      //GetArrayString(g_hModelNames, i, sName, sizeof(sName));
      PrecacheModel(sPath, true);
      //PrintToServer("Precached: %s - %s", sName, sPath);
   } 

   if (logModel)
      LogMessage(" --- Listing final props for end of round prop hunt --- ");

   for(new i = 0; i < GetArraySize(g_hModelFinalPaths); i++)
   {
      GetArrayString(g_hModelFinalPaths, i, sPath, sizeof(sPath));
      PrecacheModel(sPath, true);
      if (logModel)
         LogMessage("%s", sPath);
   }
}

public OnMapEnd()
{
   ClearArray(g_hModelMapBased);
}

public Action:Command_Propplayer(client, args)
{
   decl String:target[65];
   decl String:target_name[MAX_TARGET_LENGTH];
   decl target_list[MAXPLAYERS];
   decl target_count;
   decl bool:tn_is_ml;
   
   if (args < 1)
   {
      ReplyToCommand(client, "[SM] Usage: sm_propplayer <#userid|name>");
      return Plugin_Handled;
   }
   
   GetCmdArg(1, target, sizeof(target));
   
   if((target_count = ProcessTargetString(
               target,
               client,
               target_list,
               MAXPLAYERS,
               COMMAND_FILTER_ALIVE,
               target_name,
               sizeof(target_name),
               tn_is_ml)) <= 0)
   {
      ReplyToTargetError(client, target_count);
      return Plugin_Handled;
   }
   
   for(new i = 0; i < target_count; i++)
   {
      if(IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
      {
         PerformPropPlayer(client, target_list[i]);
      }
   }
   return Plugin_Handled;
}
public Action:Command_Propself(client, args)
{
   if (!IsClientInGame(client))
   {
      ReplyToCommand(client, "[SM] Command is in-game only.");
      return Plugin_Handled;
   }
   if (!IsPlayerAlive(client))
   {
      ReplyToCommand(client, "[SM] Must be alive to use this command.");
      return Plugin_Handled;
   }
   PerformPropPlayer(client, client, true);
   return Plugin_Handled;
}
public Hook_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
   if(!g_bIsEnabled || !g_bBonusRound || !g_hitremovePropCvar)
   return;
   
   new client = GetClientOfUserId(GetEventInt(event, "userid"));
   new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

   if(client < 1 || attacker < 1 || client == attacker)
   return;

   if(g_IsPropModel[client] == 1)
   {
      Colorize(client, NORMAL);
      RemovePropModel(client);

      if(g_InThirdperson[client] == 1)
      {
         SwitchView(client, false, true);
      }
   }
}

public Hook_Playerdeath(Handle:event, const String:name[], bool:dontBroadcast)
{
   if(!g_bIsEnabled)
   return;

   new deathflags = GetEventInt(event, "death_flags");
   if(deathflags & TF_DEATHFLAG_DEADRINGER) return;
   
   new client = GetClientOfUserId(GetEventInt(event, "userid"));
   
   if(client < 1 || !IsClientInGame(client))
   return;

   if(g_IsPropModel[client] == 1)
   {
      Colorize(client, NORMAL);
      
      SetVariantString("");
      AcceptEntityInput(client, "SetCustomModel");
      g_iPlayerModelIndex[client] = -1;
      
      if(g_InThirdperson[client] == 1)
      {
         SwitchView(client, false, true);
         
         /*
   if(g_iFov[client] != -1)
         {
            SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
            SetEntProp(client, Prop_Send, "m_iDefaultFOV", g_iDefFov[client]);
            
            g_iFov[client] = -1;
            g_iDefFov[client] = -1;
         }*/
         
         g_IsPropModel[client] = 0;
      }
   }
}

public Hook_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
   if(!g_bIsEnabled)
   return;

   for(new x = 1; x <= MaxClients; x++)
   {
      if(!IsClientInGame(x))
      {
         continue;
      }
      
      //If player is not a prop, skip.
      if(g_IsPropModel[x] == 0)
      {
         continue;
      }

      Colorize(x, NORMAL);
      RemovePropModel(x);
      
      if(g_InThirdperson[x] == 1)
      {
         SwitchView(x, false, true);
      }
   }
   
   g_bBonusRound = false;
}

public Hook_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
   if(!g_bIsEnabled)
   return;

   g_bBonusRound = true;

   g_winnerTeam = GetEventInt(event, "team");
   
   if(!IsEntLimitReached())
   {
      if(g_announcementCvar)
      {
         CPrintToChatAll("{community}-------------------------------------------");
         CPrintToChatAll("**%t{normal}**","Start Hiding");
         CPrintToChatAll("{community}-------------------------------------------");
      }
      
      CreateTimer(0.1, Timer_EquipProps, _, TIMER_FLAG_NO_MAPCHANGE);
   }
}

public Action:Timer_EquipProps(Handle:timer)
{
   for (new x = 1; x <= MaxClients; x++)
   {
      if(!IsClientInGame(x))
      {
         continue;
      }
      
      if(GetClientTeam(x) == g_winnerTeam)
      {
         continue;
      }
      
      if(!IsPlayerAlive(x))
      {
         if(g_respawnplayerCvar)
         {
            TF2_RespawnPlayer(x);
         }
         else
         {
            continue;
         }
      }
      
      //If player is already a prop, skip id.
      if(g_IsPropModel[x] != 0)
      {
         //PrintToChatAll("Client %i already is a prop, skipped", x);
         continue;
      }
      
      //If admin only cvar is enabled and not admin, skip id.
      if((g_adminonlyCvar && !bIsPlayerAdmin[x]))
      {
         //PrintToChatAll("Client %i doesnt have flag, skipped", x);
         continue;
      }
      
      if(IsPlayerAlive(x))
      {
         StripWeapons(x);
         CreatePropPlayer(x);
      }
   }
}

public CreatePropPlayer(client)
{
   g_iPlayerModelIndex[client] = GetRandomInt(0, GetArraySize(g_hModelFinalPaths) - 1);
   new String:sPath[PLATFORM_MAX_PATH], String:sName[128];
   GetArrayString(g_hModelNames, g_iPlayerModelIndex[client], sName, sizeof(sName));
   GetArrayString(g_hModelFinalPaths, g_iPlayerModelIndex[client], sPath, sizeof(sPath));
   
   //Safety check to make sure they dont have model attached already.
   //DeleteProps(client);
   
   g_IsPropModel[client] = 1;
   Colorize(client, INVIS);

   SetVariantString(sPath);
   AcceptEntityInput(client, "SetCustomModel");
   SetVariantInt(1);
   AcceptEntityInput(client, "SetCustomModelRotates");

   //SetVariantBool(true);
   //AcceptEntityInput(client, "SetCustomModelVisibletoSelf");

   /*
   g_PropModel[client] = CreateEntityByName("prop_dynamic_override");
   if(g_PropModel[client] == -1)
   {
      ReplyToCommand(client, "Failed to create entity!");
      LogMessage("[PB] %i Failed to create entity!", client);
      return;
   }

   decl String:sPlayername[64];
   Format(sPlayername, sizeof(sPlayername), "target%i", client);
   DispatchKeyValue(client, "targetname", sPlayername);
   
   if(IsValidEntity(g_PropModel[client]))
   {
      DispatchKeyValue(g_PropModel[client],"model", sPath);
      
      DispatchKeyValue(g_PropModel[client], "disableshadows", "1");
      
      DispatchKeyValue(g_PropModel[client], "solid", "0");
      
      SetEntityMoveType(g_PropModel[client], MOVETYPE_NOCLIP);
      
      DispatchSpawn(g_PropModel[client]);         
      
      decl Float:origin[3], Float:angles[3];
      GetClientAbsOrigin(client, origin);
      GetClientAbsAngles(client, angles);
      
      origin[2] += 1.0;
      if(StrEqual(sName, "Trashcan") || StrEqual(sName, "Weather Vane") || StrEqual(sName, "Wood Barrel"))
      {
         origin[2] += 29.0;
      }
      
      //SetEntProp(g_PropModel[client], Prop_Data, "m_CollisionGroup", 5);
      //SetEntProp(g_PropModel[client], Prop_Send, "m_CollisionGroup", 5);
      
      TeleportEntity(g_PropModel[client], origin, angles, NULL_VECTOR);               
      
      //SetVariantFloat(1.0);
      //AcceptEntityInput(g_PropModel[client], "SetScale", g_PropModel[client], g_PropModel[client], 0);
      
      SetVariantString(sPlayername);
      AcceptEntityInput(g_PropModel[client], "SetParent", g_PropModel[client], g_PropModel[client], 0);
      
      SetEntPropEnt(g_PropModel[client], Prop_Send, "m_hOwnerEntity", client);
      */
   
   //Print Model name info to client
   PrintCenterText(client, "%t '%s' !","Hiding in", sName);
   if(g_thirdpersonCvar == 1)
   {
      CPrintToChat(client,"%t{normal} : ' {haunted}%s{normal} ' - %t", "Hiding in",sName,"Third Person");
   }
   else
   {
      CPrintToChat(client,"%t{normal} : ' {haunted}%s{normal} ' - %t","Hiding in", sName,"Run hiding");
   }
}

stock PerformPropPlayer(client, target, bool:self = false)
{
   if(!IsClientInGame(target) || !IsPlayerAlive(target))
   return;
   
   if(g_IsPropModel[target] == 0)
   {
      CreatePropPlayer(target);
      
      LogAction(client, target, "\"%L\" set prop on \"%L\"%s", client, target, self ? " via sm_propme" : "");
      ShowActivity(client, " set prop on %N", target);
   }
   else
   {
      Colorize(target, NORMAL);
      RemovePropModel(target);
      
      if(g_InThirdperson[target] == 1)
      {
         SwitchView(target, false, true);
      }
      
      LogAction(client, target, "\"%L\" removed prop on \"%L\"%s", client, target, self ? " via sm_propme" : "");
      ShowActivity(client, " removed prop on %N", target);
   }
}

public Action:Command_Thirdperson(client, args)
{
   if(!g_bIsEnabled || client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client))
   return Plugin_Handled;
   
   if(g_thirdpersonCvar != 1)
   {
      PrintToConsole(client, "[SM] Sorry, this command has been disabled.");
      return Plugin_Handled;
   }

   if(g_IsPropModel[client] != 0)
   {
      if(g_InThirdperson[client] == 0)
      {
         SwitchView(client, true, false);
      }
      else
      {
         SwitchView(client, false, true);
      }
   }
   else
   {
      ReplyToCommand(client, "[SM] You must be a PROP to use thirdperson.");
   }

   return Plugin_Handled;
}

stock SwitchView(target, bool:observer, bool:viewmodel)
{   
   SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target : -1);
   SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1 : 0);
   SetEntData(target, g_oFOV, observer ? 100 : GetEntData(target, g_oDefFOV, 4), 4, true);      
   SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1 : 0);
   
   //SetVariantBool(observer);
   //AcceptEntityInput(target, "SetCustomModelVisibletoSelf");
   
   if(g_InThirdperson[target] == 1)
   {
      g_InThirdperson[target] = 0;
   }
   else
   {
      g_InThirdperson[target] = 1;
   }
}

/*
stock SwitchView(client)
{
   if(client)
   {
      if(IsPlayerAlive(client))
      {
         if(g_InThirdperson[client] == 0)
         {
            g_InThirdperson[client] = 1;
            
            g_iFov[client] = GetEntProp(client,Prop_Data,"m_iFOV");
            g_iDefFov[client] = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
            
            SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
            SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
            SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
            SetEntProp(client, Prop_Send, "m_iFOV", 100);
            SetEntProp(client, Prop_Send, "m_iDefaultFOV", 100);
      
      SetVariantBool(true);
      AcceptEntityInput(client, "SetCustomModelVisibletoSelf");         
         }
         else
         {
            g_InThirdperson[client] = 0;
            SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
            SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
            SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
            SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
            SetEntProp(client, Prop_Send, "m_iDefaultFOV", g_iDefFov[client]);
            
            g_iFov[client] = -1;
            g_iDefFov[client] = -1;
      
      SetVariantBool(false);
      AcceptEntityInput(client, "SetCustomModelVisibletoSelf");         
         }
      }
   }
}
*/

/*
Credit to pheadxdll and FoxMulder for invisibility code.
*/

public Colorize(client, color[4])
{   
   //Colorize the weapons
   //new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");   
   //new String:classname[256];
   new type;
   new TFClassType:class = TF2_GetPlayerClass(client);
   
   //Colorize the wearables, such as hats
   SetWearablesRGBA_Impl(client, "tf_wearable", "CTFWearableItem",color);
   
   if(color[3] > 0)
   type = 1;

   if(class == TFClass_DemoMan)
   {
      SetWearablesRGBA_Impl(client, "tf_wearable_item_demoshield", "CTFWearableItemDemoShield", color);
      HideGlowingEyes(client, type);
   }

   return;
}

SetWearablesRGBA_Impl(client,  const String:entClass[], const String:serverClass[], color[4])
{
   new hat = -1;
   while((hat = FindEntityByClassname(hat, entClass)) != INVALID_ENT_REFERENCE)
   {
      if(IsValidEntity(hat) && GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)
      {
         SetEntityRenderMode(hat, RENDER_TRANSCOLOR);
         SetEntityRenderColor(hat, color[0], color[1], color[2], color[3]);
      }
   }
}

stock RemovePlayerCanteen(client)
   {
   new edict = MaxClients+1;
   while((edict = FindEntityByClassname(edict, "tf_powerup_bottle")) != -1)
      {      
      new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
      if(idx == 489)
         {
         AcceptEntityInput(edict, "Kill");
         }
      }
   }

stock RemoveDemoShield ()
{
   new ent = -1;
   while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
   {
      AcceptEntityInput(ent, "kill");
   }
}


HideGlowingEyes(client, type)
{
   new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
   if(decapitations >= 1)
   {
      if(!type)
      {
         //Removes Glowing Eye
         TF2_RemoveCondition(client, TFCond_DemoBuff);
      }
      else
      {
         //Add Glowing Eye
         TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
      }
   }
}

stock ProcessExcludeFile(const String:file[])
{
   new String:filePath[PLATFORM_MAX_PATH];
   new bool:logModel = GetConVarBool(Cvar_LogModels);
   BuildPath(Path_SM, filePath, sizeof(filePath), "data/%s", file);

   if (g_hModelExcludePaths == INVALID_HANDLE)
      g_hModelExcludePaths = CreateArray(PLATFORM_MAX_PATH, 0);

   // Open stream, if possible
   new Handle:hStream = OpenFile(filePath, "r");
   new String:strLine[256];
   if (hStream == INVALID_HANDLE) { LogMessage(" --- Unable to read exclude file (\"%s\").", filePath); return; }

   LogMessage(" --- Processing exclude file %s", filePath);

   while(!IsEndOfFile(hStream))
   {
      // Try to read line. If EOF has been hit, exit.
      ReadFileLine(hStream, strLine, sizeof(strLine));
      CleanString(strLine);
      if (!StrEqual(strLine, ""))
      {
         PushArrayString(g_hModelExcludePaths, strLine);

         if (logModel)
            LogMessage("Excluding: %s", strLine);
      }
   }

   // Close file
   CloseHandle(hStream);
}

stock ProcessIncludeFile(const String:file[])
{
   new String:filePath[PLATFORM_MAX_PATH];
   new bool:logModel = GetConVarBool(Cvar_LogModels);
   BuildPath(Path_SM, filePath, sizeof(filePath), "data/%s", file);

   if (g_hModelFinalPaths == INVALID_HANDLE)
      g_hModelFinalPaths = CreateArray(PLATFORM_MAX_PATH, 0);

   // Open stream, if possible
   new Handle:hStream = OpenFile(filePath, "r");
   new String:strLine[256];
   if (hStream == INVALID_HANDLE) { LogMessage(" --- Unable to read include file (\"%s\").", filePath); return; }

   LogMessage(" --- Processing include file %s", filePath);

   while(!IsEndOfFile(hStream))
   {
      // Try to read line. If EOF has been hit, exit.
      ReadFileLine(hStream, strLine, sizeof(strLine));
      CleanString(strLine);
      if (!StrEqual(strLine, ""))
      {
         PushArrayString(g_hModelFinalPaths, strLine);

         if (logModel)
            LogMessage("Including: %s", strLine);
      }
   }

   // Close file
   CloseHandle(hStream);
}

/*
Credit for SMC Parser related code goes to Antithasys!
*/
stock ProcessConfigFile()
{
   BuildPath(Path_SM, g_sConfigPath, sizeof(g_sConfigPath), "data/propbonusround_models.txt");
   
   /*
   Model file checks. Auto-create or disable if necessary.
   */
   if (!FileExists(g_sConfigPath))
   {
      /*
      Config file does not exist. Re-create the file before precache.
      */
      LogMessage("Models file not found at %s. Auto-Creating file...", g_sConfigPath);
      SetupDefaultProplistFile();
      
      if (!FileExists(g_sConfigPath))
      {
         /*
   Second fail-safe check. Somehow, the file did not get created, so it is disable time.
   */
         SetFailState("Models file (propbonusround_models.txt) still not found. You Suck.");
      }
   }
   
   if (g_hModelNames == INVALID_HANDLE)
   {
      g_hModelNames = CreateArray(128, 0);
      g_hModelPaths = CreateArray(PLATFORM_MAX_PATH, 0);
   }

   ClearArray(g_hModelNames);
   ClearArray(g_hModelPaths);

   new Handle:hParser = SMC_CreateParser();
   SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
   SMC_SetParseEnd(hParser, Config_End);

   new line, col;
   new String:error[128];
   new SMCError:result = SMC_ParseFile(hParser, g_sConfigPath, line, col);
   CloseHandle(hParser);
   
   if (result != SMCError_Okay) 
   {
      SMC_GetErrorString(result, error, sizeof(error));
      LogError("[propbonus] %s on line %d, col %d of %s", error, line, col, g_sConfigPath);
      LogError("[propbonus] Propbonus is not running! Failed to parse %s", g_sConfigPath);
      SetFailState("Could not parse file %s", g_sConfigPath);
   }

}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) 
{
   //LogMessage("In Section %s", section);
   //PrintToChatAll("In Section %s", section);
   return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
   //LogMessage("Saving model name %s", key);
   //LogMessage("Saving model path %s", value);
   //PrintToChatAll("Saving model name %s", key);
   //PrintToChatAll("Saving model path %s", value);
   
   PushArrayString(g_hModelNames, key);
   PushArrayString(g_hModelPaths, value);
   return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) 
{   
   //LogMessage("Leaving Section");
   //PrintToChatAll("Leaving Section");
   return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) 
{
   if (failed)
   {
      SetFailState("Plugin configuration error");
   }
}

public OnLibraryRemoved(const String:name[])
{
   if (StrEqual(name, "adminmenu")) 
   {
      hAdminMenu = INVALID_HANDLE;
   }
}

public OnAdminMenuReady(Handle:topmenu)
{
   if (topmenu == hAdminMenu)
   {
      return;
   }
   
   hAdminMenu = topmenu;

   new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);

   if (player_commands != INVALID_TOPMENUOBJECT)
   {
      AddToTopMenu(hAdminMenu,
      "sm_propplayer",
      TopMenuObject_Item,
      AdminMenu_Propplayer, 
      player_commands,
      "sm_propplayer",
      ADMFLAG_ROOT);
   }
}

public AdminMenu_Propplayer( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
   if (action == TopMenuAction_DisplayOption)
   {
      Format(buffer, maxlength, "Prop player");
   }
   else if( action == TopMenuAction_SelectOption)
   {
      DisplayPlayerMenu(param);
   }
}

DisplayPlayerMenu(client)
{
   new Handle:menu = CreateMenu(MenuHandler_Players);
   
   decl String:title[100];
   Format(title, sizeof(title), "Choose Player:");
   SetMenuTitle(menu, title);
   SetMenuExitBackButton(menu, true);
   
   AddTargetsToMenu(menu, client, true, true);
   
   DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
   if (action == MenuAction_End)
   {
      CloseHandle(menu);
   }
   else if (action == MenuAction_Cancel)
   {
      if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
      {
         DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
      }
   }
   else if (action == MenuAction_Select)
   {
      decl String:info[32];
      new userid, target;
      
      GetMenuItem(menu, param2, info, sizeof(info));
      userid = StringToInt(info);

      if ((target = GetClientOfUserId(userid)) == 0)
      {
         PrintToChat(param1, "[SM] %s", "Player no longer available");
      }
      else if (!CanUserTarget(param1, target))
      {
         PrintToChat(param1, "[SM] %s", "Unable to target");
      }
      else
      {               
         PerformPropPlayer(param1, target);
      }
      
      /* Re-draw the menu if they're still valid */
      if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
      {
         DisplayPlayerMenu(param1);
      }
   }
}

SetupDefaultProplistFile()
{
   new Handle:hKVBuildProplist = CreateKeyValues("propbonusround");

   KvJumpToKey(hKVBuildProplist, "proplist", true);
   KvSetString(hKVBuildProplist, "Oildrum", "models/props_2fort/oildrum.mdl");
   KvSetString(hKVBuildProplist, "Barricade Sign", "models/props_gameplay/sign_barricade001a.mdl");
   KvSetString(hKVBuildProplist, "Stack of Tires", "models/props_2fort/tire002.mdl");
   //KvSetString(hKVBuildProplist, "Tire", "models/props_2fort/tire001.mdl"); //commented due to polycount
   //KvSetString(hKVBuildProplist, "Oil Can", "models/props_farm/oilcan02.mdl");  //commented due to polycount
   KvSetString(hKVBuildProplist, "Dynamite Crate", "models/props_2fort/miningcrate001.mdl");
   //KvSetString(hKVBuildProplist, "Water Pump", "models/props_2fort/waterpump001.mdl");  //commented due to polycount
   //KvSetString(hKVBuildProplist, "Control Point", "models/props_gameplay/cap_point_base.mdl"); //commented due to polycount
   KvSetString(hKVBuildProplist, "Metal Bucket", "models/props_2fort/metalbucket001.mdl");
   //KvSetString(hKVBuildProplist, "Trashcan", "models/props_2fort/wastebasket01.mdl");
   //KvSetString(hKVBuildProplist, "Wood Barrel", "models/props_farm/wooden_barrel.mdl");
   KvSetString(hKVBuildProplist, "Lantern", "models/props_2fort/lantern001_off.mdl");
   KvSetString(hKVBuildProplist, "Stack of Trainwheels", "models/props_2fort/trainwheel003.mdl");
   //KvSetString(hKVBuildProplist, "Corrugated Metal", "models/props_2fort/corrugated_metal003.mdl"); //commented due to polycount
   KvSetString(hKVBuildProplist, "Milk Jug", "models/props_2fort/milkjug001.mdl");
   KvSetString(hKVBuildProplist, "Mop and Bucket", "models/props_2fort/mop_and_bucket.mdl");
   KvSetString(hKVBuildProplist, "Propane Tank", "models/props_2fort/propane_tank_tall01.mdl");
   //KvSetString(hKVBuildProplist, "Tombstone", "models/props_halloween/tombstone_01.mdl");  //commented due to polycount
   KvSetString(hKVBuildProplist, "Cow Cutout", "models/props_2fort/cow001_reference.mdl");
   KvSetString(hKVBuildProplist, "Biohazard Barrel", "models/props_badlands/barrel01.mdl");
   KvSetString(hKVBuildProplist, "Wood Pallet", "models/props_farm/pallet001.mdl");
   KvSetString(hKVBuildProplist, "Hay Patch", "models/props_farm/haypile001.mdl");
   //KvSetString(hKVBuildProplist, "Concrete Block", "models/props_farm/concrete_block001.mdl"); //commented due to polycount
   KvSetString(hKVBuildProplist, "Shrub", "models/props_forest/shrub_03b.mdl");
   KvSetString(hKVBuildProplist, "Wood Pile", "models/props_farm/wood_pile.mdl");
   KvSetString(hKVBuildProplist, "Welding Machine", "models/props_farm/welding_machine01.mdl");
   KvSetString(hKVBuildProplist, "Giant Cactus", "models/props_foliage/cactus01.mdl");
   KvSetString(hKVBuildProplist, "Tree", "models/props_foliage/tree01.mdl");
   //KvSetString(hKVBuildProplist, "Cluster of Shrubs", "models/props_foliage/shrub_03_cluster.mdl"); //commented due to polycount
   KvSetString(hKVBuildProplist, "Spike Plant", "models/props_foliage/spikeplant01.mdl");
   KvSetString(hKVBuildProplist, "Grain Sack", "models/props_granary/grain_sack.mdl");
   KvSetString(hKVBuildProplist, "Traffic Cone", "models/props_gameplay/orange_cone001.mdl");
   //KvSetString(hKVBuildProplist, "Weather Vane", "models/props_2fort/weathervane001.mdl");
   KvSetString(hKVBuildProplist, "Milk Crate", "models/props_forest/milk_crate.mdl");
   KvSetString(hKVBuildProplist, "Rock", "models/props_nature/rock_worn001.mdl");
   KvSetString(hKVBuildProplist, "Computer Cart", "models/props_well/computer_cart01.mdl");
   KvSetString(hKVBuildProplist, "Skull Sign", "models/props_mining/sign001.mdl");
   KvSetString(hKVBuildProplist, "Wood Fence", "models/props_mining/fence001_reference.mdl");
   KvSetString(hKVBuildProplist, "Hay Bale", "models/props_gameplay/haybale.mdl");
   KvSetString(hKVBuildProplist, "Water Cooler", "models/props_spytech/watercooler.mdl");
   //KvSetString(hKVBuildProplist, "Television", "models/props_spytech/tv001.mdl"); //commented due to polycount
   //KvSetString(hKVBuildProplist, "Jackolantern", "models/props_halloween/jackolantern_02.mdl"); //commented due to polycount
   KvSetString(hKVBuildProplist, "Terminal Chair", "models/props_spytech/terminal_chair.mdl");
   //KvSetString(hKVBuildProplist, "Hand Truck", "models/props_well/hand_truck01.mdl");  //commented due to polycount
   //KvSetString(hKVBuildProplist, "Sink", "models/props_2fort/sink001.mdl");  //commented due to polycount
   KvSetString(hKVBuildProplist, "Chimney", "models/props_2fort/chimney005.mdl");

   KvRewind(hKVBuildProplist);         
   KeyValuesToFile(hKVBuildProplist, g_sConfigPath);
   
   //Phew...glad thats over with.
   CloseHandle(hKVBuildProplist);
}

/*
stock DeleteModel(client)
{   
   new anime = GetAnimeEnt(client);
   if(anime > 0 && IsValidEntity(anime))
   {
      AcceptEntityInput(anime, "kill");
   }
   if(anime > 0 && IsValidEdict(anime))
   {
      RemoveEdict(anime);
      g_PropModel[client] = -1;
   }
}

stock GetAnimeEnt(client)
{
   new client2, ent;
   while(IsValidEntity(ent) && (ent = FindEntityByClassname(ent, "prop_dynamic")) != -1)
   {
      client2 = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
      if(client2 == client)
      {
         return ent;
      }
   }
   return -1;
}
*/

stock StripWeapons(client) 
{
   if(IsClientInGame(client) && IsPlayerAlive(client)) 
   {
      for(new x = 0; x <= 5; x++)
      {
         //if(x == 2)
         //{
         //continue;
         //}
         
         TF2_RemoveWeaponSlot(client, x);
      }
      RemovePlayerCanteen(client);
      RemoveDemoShield();
      //new weapon = GetPlayerWeaponSlot(client, 2);
      //SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
   }
}

stock RemovePropModel(client)
{
   if(IsValidEntity(client))
   {
      SetVariantString("");
      AcceptEntityInput(client, "SetCustomModel");
      
      g_IsPropModel[client] = 0;
      g_iPlayerModelIndex[client] = -1;
   }
}

/*
stock DeleteProps(client)
{
   if(g_PropModel[client] != -1)
   {
      if(IsValidEntity(g_PropModel[client]))
      {
         //PrintToChatAll("%i IsValidEntity, AcceptEntityInput KILL entity", client);
         //PrintToServer("%i IsValidEntity, AcceptEntityInput KILL entity", client);
         AcceptEntityInput(g_PropModel[client], "kill");
         g_PropModel[client] = -1;
      }
   }
}
*/

CheckGame()
{
   new String:strGame[10];
   GetGameFolderName(strGame, sizeof(strGame));
   
   if(StrEqual(strGame, "tf"))
   {
      PrintToServer("[propbonusround] Detected game [TF2], plugin v%s loaded..", PLUGIN_VERSION);
   }
   else
   {
      SetFailState("[propbonusround] Detected game other than [TF2], plugin disabled.");
   }
}

/*
Credit for auto-create SM commands code goes to Antithasys!
*/
stock CreateThirdpersonCommands()
{
   new String:sBuffer[128], String:sTriggerCommands[18][128];
   GetConVarString(Cvar_ThirdTriggers, sBuffer, sizeof(sBuffer));
   ExplodeString(sBuffer, ",", sTriggerCommands, sizeof(sTriggerCommands), sizeof(sTriggerCommands[]));
   for (new x = 0; x < sizeof(sTriggerCommands); x++)
   {
      if(IsStringBlank(sTriggerCommands[x]))
      {
         continue;
      }
      new String:sCommand[128];
      Format(sCommand, sizeof(sCommand), "sm_%s", sTriggerCommands[x]);
      RegConsoleCmd(sCommand, Command_Thirdperson, "Command(s) used to enable thirdperson view");
   }
}

stock bool:IsStringBlank(const String:input[])
{
   new len = strlen(input);
   for (new i=0; i<len; i++)
   {
      if (!IsCharSpace(input[i]))
      {
         return false;
      }
   }
   return true;
}

stock bool:IsValidAdmin(client, const String:flags[])
{
   if (!IsClientConnected(client))
   return false;
   
   new ibFlags = ReadFlagString(flags);
   if(!StrEqual(flags, ""))
   {
      if((GetUserFlagBits(client) & ibFlags) == ibFlags)
      {
         return true;
      }
   }
   
   return false;
}

stock bool:IsEntLimitReached()
{
   new maxents = GetMaxEntities();
   new i, c = 0;
   
   for(i = MaxClients; i <= maxents; i++)
   {
      if(IsValidEntity(i))
      c += 1;
      
   }
   
   //PrintToChatAll("%Entity Count: %i", c);
   
   if (c >= (maxents-32))
   {
      PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
      LogError("Entity limit is nearly reached: %d/%d", c, maxents);
      return true;
   }
   else
   return false;
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
   if(convar == Cvar_Enabled)
   {
      if(StringToInt(newValue) == 0)
      {
         g_bIsEnabled = false;
         UnhookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
         UnhookEvent("teamplay_round_win", Hook_RoundWin, EventHookMode_Post);
         UnhookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
         UnhookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Post);
         for(new x = 1; x <= MaxClients; x++)
         {
            if(IsClientInGame(x) && IsPlayerAlive(x))
            {
               if(g_IsPropModel[x] != 0)
               {
                  RemovePropModel(x);
               }
               if(g_InThirdperson[x] == 1)
               {
                  SwitchView(x, false, true);
               }
            }
         }
      }
      else
      {
         g_bIsEnabled = true;
         HookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
         HookEvent("teamplay_round_win", Hook_RoundWin, EventHookMode_Post);
         HookEvent("player_death", Hook_Playerdeath, EventHookMode_Post);
         HookEvent("player_hurt", Hook_PlayerHurt, EventHookMode_Post);
      }
   }
   else if(convar == Cvar_ThirdPerson)
   {
      g_thirdpersonCvar = StringToInt(newValue);
   }
   else if(convar == Cvar_HitRemoveProp)
   {
      g_hitremovePropCvar = StringToInt(newValue);
   }
   else if(convar == Cvar_AdminOnly)
   {
      g_adminonlyCvar = StringToInt(newValue);
   }
   else if(convar == Cvar_Announcement)
   {
      g_announcementCvar = StringToInt(newValue);
   }
   else if(convar == Cvar_Respawnplayer)
   {
      g_respawnplayerCvar = StringToInt(newValue);
   }
}

// ------------------------------------------------------------------------
// CleanString  -- Thanks FlaminSarge
// ------------------------------------------------------------------------
stock CleanString(String:strBuffer[])
{
   // Cleanup any illegal characters
   new Length = strlen(strBuffer);
   for (new iPos=0; iPos<Length; iPos++)
   {
      switch(strBuffer[iPos])
      {
         case '\r': strBuffer[iPos] = ' ';
         case '\n': strBuffer[iPos] = ' ';
         case '\t': strBuffer[iPos] = ' ';
      }
   }

   // Trim string
   TrimString(strBuffer);
}
