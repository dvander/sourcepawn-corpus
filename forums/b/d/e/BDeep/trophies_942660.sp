/* ========================================================================== */
/*                                                                            */
/*   Trophies.sp                                                              */
/*   (c) 2009 Stinkyfax                                                       */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#define VERSION "1.2"

#define COLOR_DEFAULT 0x01
#define COLOR_LIGHTGREEN 0x03
#define COLOR_GREEN 0x04 // DOD = Red
#define SOUND_BELL "common/stuck1.wav"

#include <sdktools>

#pragma semicolon 1

enum Data   {
   D_rank,
   D_amount,
   String:D_name[30]
}



new g_modelLaser, g_modelHalo; //models
new Handle:g_hData=INVALID_HANDLE; //database handle
new Handle:g_hArray=INVALID_HANDLE; //Sorted Array
new String:g_sPath[PLATFORM_MAX_PATH]; //path to database
//cvars handles
new Handle:g_hSpec, Handle:g_hDistance, Handle:g_hDelay, Handle:g_hDur;

new Handle:g_mTop10=INVALID_HANDLE;

//Trophies array functions
new Handle:g_hTrophies;

new bool:timer=false;

public Plugin:myinfo = 
{
  name = "Trophies",
  author = "Stinkyfax",
  description = "Converted plugin from ES:Python",
  version = VERSION,
  url = "http://sourcemod.net/"
};

public bool:AskPluginLoad(Handle:plugin,bool:late,String:error[],error_maxlen)   {
  return true;
}

public OnPluginStart()  {
   PrintToServer("[Trophies]: -- Loading Part 1 --"); 
   //Load models for beamring effect
   g_modelLaser = PrecacheModel("sprites/laser.vmt");
   g_modelHalo = PrecacheModel("materials/sprites/halo01.vmt");
   PrecacheSound(SOUND_BELL, true); 
   
   //Load cvars
   CreateConVar("sm_trophies_version", VERSION, "Current version of the Trophies", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
   
   g_hDelay = CreateConVar("trophies_delay", "600.0", "Delay in seconds to save the data. (Float)",0,true,50.0);
   g_hSpec = CreateConVar("trophies_spectatorclaim", "0", 
                           "If 1 - Spectators can claim trophies", 0, true, 0.0, true, 1.0);
   g_hDistance = CreateConVar("trophies_claimdistance", "25", 
                              "Distance within which a player can claim a trophy.", 0, true, 0.0);
   g_hDur = CreateConVar("trophies_duration", "30.0", 
                              "Time in seconds trophy doesn't dissapear.", 0, true, 0.0);
   //end of load cvars
   AutoExecConfig(true, "trophies"); //Executes config from game_dir/cfg/sourcemod/trophies.cfg
   
   //Generate path to data
   decl String:thepath[255];
   Format (thepath,sizeof(thepath),"data/trophies.txt");
   BuildPath(Path_SM,g_sPath,PLATFORM_MAX_PATH,thepath);
   //Load data
   KVLoad();
   

   
   //Register commands
   RegConsoleCmd("say",SayCommand);
   RegConsoleCmd("say_team",SayCommand);
   RegConsoleCmd("claim",SayCommand);
   
   //Refresh rank
   RefreshRank(INVALID_HANDLE, "", false);
   HookEvent("round_start", RefreshRank, EventHookMode_PostNoCopy);
   
   g_hTrophies = CreateArray(4);
   //Hook plugin related actions like take trophie, etc
   HookActions();
   
   PrintToServer("[Trophies]: -- Finished Part 1 --");
}

public OnMapStart()  {
   RemoveTrophies();
   g_modelLaser = PrecacheModel("sprites/laser.vmt");
   g_modelHalo = PrecacheModel("materials/sprites/halo01.vmt"); 
   //Timer to draw circles
   CreateTimer(1.0, DrawCircles, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnConfigsExecuted() {
   //Add timer to save data periodically (to prevent loss of data at crashes)
   if(!timer)  {
      CreateTimer(GetConVarFloat(g_hDelay), KVSave, 0, TIMER_REPEAT);
      timer=true;
   }
   for(new i=1; i<GetMaxClients(); i++)   {
      if(IsClientConnected(i) && IsClientAuthorized(i))
         InitPlayer(i);
   }
}

public RefreshRank(Handle:event, String:name[], bool:dontBroadcast)  {

   //Retrieve id's from data
   
   if(g_hArray==INVALID_HANDLE)  {
      g_hArray = CreateArray();
      new bool:went=false;
      if( (went=KvGotoFirstSubKey(g_hData)))   do {
         new id = -1;
         if(KvGetSectionSymbol(g_hData, id)) {
            PushArrayCell(g_hArray, id);
         }
      }  while(KvGotoNextKey(g_hData));
      if(went)
         KvRewind(g_hData);
   }
   //Sort array by id's
   SortADTArrayCustom(g_hArray, SortFunction);
   
   //Generate Top10
   if(g_mTop10!=INVALID_HANDLE)  {
      CloseHandle(g_mTop10);
   }
   g_mTop10 = CreatePanel();
   new max=10;
   new size = GetArraySize(g_hArray);
   if(size < max)
      max=size;
   SetPanelTitle(g_mTop10, "Trophies Top 10");
   DrawPanelItem(g_mTop10, "Servers Best Headhunters", ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);
   DrawPanelItem(g_mTop10, "-----------------------", ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);
   for(new i=0; i<max; i++)   {
      decl String:buffer[40];
      KvJumpToKeySymbol(g_hData, GetArrayCell(g_hArray, i));
      new data[Data];
      GetData(data);
      KvRewind(g_hData);
      Format(buffer, sizeof(buffer), "->%s - %i", data[D_name], data[D_amount]);
      if(i<9)
         DrawPanelItem(g_mTop10, buffer);
      else
         DrawPanelItem(g_mTop10, buffer, ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);
   }
   DrawPanelItem(g_mTop10, "-----------------------", ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE);
   SetPanelCurrentKey(g_mTop10, 10);
   DrawPanelItem(g_mTop10, "exit");
}

public SortFunction(index1, index2, Handle:array, Handle:hndl)  {
   KvJumpToKeySymbol(g_hData, GetArrayCell(array, index1));
   new val1 = KvGetNum(g_hData, "amount");
   KvRewind(g_hData);
   KvJumpToKeySymbol(g_hData, GetArrayCell(array, index2));
   new val2 = KvGetNum(g_hData, "amount");
   KvRewind(g_hData);
   if(val1 > val2)
      return -1;
   if(val1 == val2)
      return 0;
   return 1; 
}

DrawCircle(Float:loc[3])   {
   decl color[4];
   for(new i=0; i<3;i++)
      color[i] = GetRandomInt(10,255);
   color[3]=255;
   TE_SetupBeamRingPoint(loc, 30.0, 50.0, g_modelLaser, g_modelHalo, 0, 1, 1.0, 3.0, 1.0, color, 10, 0);
   TE_SendToAll();
}



KVLoad()   {
   if(g_hData!=INVALID_HANDLE)
      CloseHandle(g_hData);
   g_hData = CreateKeyValues("data", "first");

   FileToKeyValues(g_hData,g_sPath); 
}

public Action:KVSave(Handle:tm, any:trash) {
   //Update Ranks
   for(new i=0; i<GetArraySize(g_hArray); i++)  {
      new id = GetArrayCell(g_hArray, i);
      KvJumpToKeySymbol(g_hData, id);
      KvSetNum(g_hData, "rank", i+1);
      KvRewind(g_hData);
   }
   
   //Save file
   KeyValuesToFile(g_hData, g_sPath);
   
   LogMessage("[Trophies]: Saved data file");
   return Plugin_Continue;
}


public OnClientAuthorized(client, const String:auth[])   {
   InitPlayer(client);
}

InitPlayer(client)   {
   new String:auth[32];
   GetClientAuthString(client,auth,32);
   //KvRewind(g_hData);
   if(!KvJumpToKey(g_hData, auth, false))  {
      //KvRewind(g_hData);
      KvJumpToKey(g_hData, auth, true);
      new id=0;
      if(KvGetSectionSymbol(g_hData, id))
         PushArrayCell(g_hArray, id);
   }
   decl String:name[30];
   GetClientName(client, name, 30);
   KvSetString(g_hData, "name", name);
   KvRewind(g_hData);
}

stock bool:GetData(data[Data], client=0)  {
   if(client>0)   {
      if(!IsClientConnected(client))
         return false;
      new String:auth[32];
      GetClientAuthString(client,auth,32);
      KvJumpToKey(g_hData, auth, true);
   }
   new id=-1;
   data[D_rank] = KvGetNum(g_hData, "rank");
   if(KvGetSectionSymbol(g_hData, id)) {
      if( (id = FindValueInArray(g_hArray,id)) >= 0 ) {
         data[D_rank]= id+1;
      }
   }
   data[D_amount] = KvGetNum(g_hData, "amount");
   KvGetString(g_hData, "name", data[D_name], 30);
   KvRewind(g_hData);
   return true;
}

//Handles all say commands
public Action:SayCommand(client,argc)
{
   decl String:command[255];
   GetCmdArgString(command,255);
   TrimString(command);
   ReplaceString(command,255,"\"","");
   
   if(StrEqual(command,"trophies",false))   {
      decl String:text[300];
      new data[Data];
      GetData(data, client);
      Format(text, 300, "@lightgreenYou have @green%i@lightgreen trophies.", data[D_amount]);
      Answer(client, text);
   }
   else if(StrEqual(command,"ttop10",false))   {
      SendPanelToClient(g_mTop10, client, TrophMenu2, MENU_TIME_FOREVER);
   }
   else if(StrEqual(command,"trank",false))   {
      decl String:text[300];
      new data[Data];
      GetData(data, client);
      decl String:name[30];
      GetClientName(client, name, 30);
      Format(text, 300, 
         "Player @green%s @defaulthas @lightgreen%i @defaulttrophies, with a rank of @lightgreen%i/%i.",
         name, data[D_amount], data[D_rank], GetArraySize(g_hArray)); 
      Answer(client,text,true);
   }
   else if(StrEqual(command,"tstats",false))   {
      //creating menu
      new Handle:menu = CreatePanel();

      //Getting Data
      decl String:text[300];
      new data[Data];
      GetData(data, client);
      decl String:name[30];
      GetClientName(client, name, 30);
      //end
      //Adding lines
      SetPanelTitle(menu, "Trophies");
      
      DrawPanelItem(menu, "Stats For Player :", ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);
      Format(text, sizeof(text), "-> %s", name);
      DrawPanelItem(menu, text);
      
      DrawPanelItem(menu, "-----------------------", ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);
      
      DrawPanelItem(menu, "-> Trophies Collected :");
      Format(text, sizeof(text), "-> %i", data[D_amount]);
      DrawPanelItem(menu, text);
      
      DrawPanelItem(menu, "-> Rank :");
      Format(text, sizeof(text), "-> %i of %i", data[D_rank], GetArraySize(g_hArray));
      DrawPanelItem(menu, text);
      
      
      new id = data[D_rank]-1;
      if(id>=0)   {
         KvJumpToKeySymbol(g_hData, id);
         new data2[Data];
         GetData(data2);
         KvRewind(g_hData);
         DrawPanelItem(menu, "-> Next Rank :");
         Format(text, sizeof(text), "-> %i Trophies(s) needed to overtake %s.",
          data2[D_amount] - data[D_amount] + 1,
          data2[D_name]);
         DrawPanelItem(menu, text);
      }
      DrawPanelItem(menu, "-----------------------", ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);
      SetPanelCurrentKey(menu, 10);
      DrawPanelItem(menu, "exit");
      SendPanelToClient(menu, client, TrophMenu2, 60);
      CloseHandle(menu);
   }
}



stock Answer(client, String:text[], bool:all=false) {
   decl String:translation[350];
   Format(translation,sizeof(translation),"%c[%cTrophies%c] %c%s",COLOR_GREEN, COLOR_LIGHTGREEN, COLOR_GREEN,COLOR_DEFAULT,text);
   ReplaceString(translation,350,"@default","\x01");
   ReplaceString(translation,350,"@lightgreen","\x03");
   ReplaceString(translation,350,"@green","\x04");
   if(!all)
      PrintToChat(client,translation);
   else
      PrintToChatAll(translation);
}

public TrophMenu2(Handle:menu, MenuAction:action, client, slot)   {
}
public TrophMenu(Handle:menu,MenuAction:action,client,slot)
{
}

HookActions()  {
   RegConsoleCmd("claim", Claim, "Claims a nearby trophie");
   
   HookEvent("player_death",PlayerDeathEvent);
   //HookEvent("round_end", CleanTrophies);
   HookEvent("round_start", CleanTrophies);
}

public Action:CleanTrophies(Handle:event,const String:name[],bool:dontBroadcast) {
   RemoveTrophies();
   return Plugin_Continue;
}

public Action:PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast) {
   new client=GetClientOfUserId(GetEventInt(event,"userid"));
   new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
   if(attacker <= 0 )
      return Plugin_Continue;
   if(GetClientTeam(client) != GetClientTeam(attacker))  {
      decl Float:loc[3];
      GetClientAbsOrigin(client, loc);
      loc[2]+=40;
      AddTrophy(loc);
   }
   return Plugin_Continue;
}

public Action:Claim(client,args) {
   if(client <=0) {
      PrintToChat(client, "Only clients can use");
      return Plugin_Handled;
   }
   if( IsPlayerAlive(client) || GetConVarBool(g_hSpec) )  {
      new bool:got=false;
      new i=0;
      new Float:ploc[3];
      GetClientEyePosition(client, ploc);
      while(i < GetArraySize(g_hTrophies))  {
         decl Float:loc[3];
         GetArrayArray(g_hTrophies, i, loc, 3);
         new Float:max = GetConVarFloat(g_hDistance);
         new bool:pass=true;
         for(new x=0; x<2; x++)  {
            
            new Float:dif = loc[x] - ploc[x];
            if(dif<0)
               dif*=-1;
            if(dif > max)
               pass=false;
         }
         if(pass) {
            got=true;
            RemoveFromArray(g_hTrophies, i--);
            GotTrophie(client);
            Answer(client, "You Have Picked Up A Trophy!");
            EmitSoundToClient(client, SOUND_BELL, client, _, _, _, 1.0);
         }
         i++;
      }
      if(!got) {
         PrintToChat(client, "[Trophies]: There were no Trophies nearby.");
      }
   }
   else  {
      PrintToChat(client, "[Trophies]: You should be alive to claim a trophy.");
   } 
   return Plugin_Handled;
}

RemoveTrophies()  {
   ClearArray(g_hTrophies);
}

AddTrophy(Float:loc[3]) {
   new ind=PushArrayArray(g_hTrophies, loc, 3);
   SetArrayCell(g_hTrophies, ind, GetEngineTime(), 3); 
}

GotTrophie(client)   {
   new String:auth[32];
   GetClientAuthString(client,auth,32);
   KvJumpToKey(g_hData, auth, true);
   new amount = KvGetNum(g_hData, "amount");
   KvSetNum(g_hData, "amount", ++amount);
   KvRewind(g_hData);
   
   ReplyToCommand(client, "[Trophies]: Now you have %i Tropies.", amount);
}

public Action:DrawCircles(Handle:tm, any:trash) {
   new i=0;
   new Float:dur = GetConVarFloat(g_hDur);
   new Float:now = GetEngineTime();
   while(i < GetArraySize(g_hTrophies))   {
      new Float:when = GetArrayCell(g_hTrophies, i, 3);
      if( (when + dur) < now )   {
         RemoveFromArray(g_hTrophies, i--);
      }
      else  {
         new Float:loc[3];
         GetArrayArray(g_hTrophies, i, loc, 3);
         DrawCircle(loc);
      }
      i++;
   }
   return Plugin_Continue;
}

public OnPluginEnd() {
   KVSave(INVALID_HANDLE, 0);
}