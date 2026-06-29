/*
   - v1.0.1 Working except for on round change

   -Usage:
   - !intg | !interrogate will create menu of all clients to choose from
   - !intg <name> | !interrogate <name> will either interrogate match or make menu of matches
   -     upon collisions are found
*/

#include <sourcemod>
#include <sdktools>
#include <multicolors>

#define VERSION "1.0.1"
#pragma newdecls required

Handle Cvar_Intg = INVALID_HANDLE;
bool in_interrogation = false;
int interrogater = 0;
int interrogatee = 0;
char interrogateeName[MAX_NAME_LENGTH];

public Plugin myinfo =
{
   name = "Bazooka's Interrogate Plugin",
   description = "Plugin that allows an admin to drag a player into a 1 on 1 conversation that no other client can hear.",
   author = "bazooka",
   version = VERSION,
   url = "https://github.com/bazooka-codes"
};

public void OnPluginStart()
{
   CreateConVar("sm_interrogate_version", VERSION, "Bazooka's interrogate plugin version.");
   Cvar_Intg = CreateConVar("sm_interrogate_enable", "1", "1 - Interrogate plugin enabled | 0 - Interrogate plugin disabled");

   RegAdminCmd("interrogate", InterrogateHandler, ADMFLAG_GENERIC);
   RegAdminCmd("intg", InterrogateHandler, ADMFLAG_GENERIC);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
   //Load the plugin, linking the function in .inc with the one defined below
   CreateNative("IsClientInInterrogation", Native_Interrogate_Include);
   return APLRes_Success;
}

public void OnMapEnd()
{
   //Reset all comms on map change
   if(GetConVarInt(Cvar_Intg) != 1)
   {
      return;
   }

   //If map ends during interrogation
   if(in_interrogation)
   {
      EndInterrogate("Map ended.");
   }
}

public void OnClientConnected(int client)
{
   if(GetConVarInt(Cvar_Intg) != 1)
   {
      //Plugin disabled
      return;
   }

   //If someone joins while interrogating, disable the hearing for connecting player
   if(in_interrogation)
   {
      SetListenOverride(client, interrogater, Listen_No);
      SetListenOverride(interrogater, client, Listen_No);

      SetListenOverride(client, interrogatee, Listen_No);
      SetListenOverride(interrogatee, client, Listen_No);

      CPrintToChat(client, "{orchid}Interrogate: {default}Interrogation in progess. You may not be able to reach certain players.");

      char connectName[MAX_NAME_LENGTH];
      GetClientName(client, connectName, sizeof(connectName));
      CPrintToChat(interrogater, "{orchid}Interrogate: {default}New client: %s joined and was blocked from hearing interrogation.", connectName);
   }
}

public void OnClientDisconnect(int client)
{
   if(GetConVarInt(Cvar_Intg) != 1)
   {
      return;
   }

   //If someone leaves when interrogation is happening, end interrogation for matching reason
   if(in_interrogation)
   {
      if(client == interrogatee)
      {
         CancelClientMenu(interrogater, true, INVALID_HANDLE);
         EndInterrogate("Target disconnected.");
      }

      if(client == interrogater)
      {
         EndInterrogate("Admin disconnected.");
      }
   }
}

public Action InterrogateHandler(int client, int args)
{
   if(GetConVarInt(Cvar_Intg) != 1)
   {
      //Plugin is disabled
      return Plugin_Stop;
   }

   if(!IsClientInGame(client))
   {
      //Client disconnected
      return Plugin_Handled;
   }

   if(!CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
   {
      //Client is not an admin
      CReplyToCommand(client, "{orchid}Interrogate: {darkred}ERROR  {default}You do not have access to this command.");
      return Plugin_Handled;
   }

   if(in_interrogation)
   {
      //Client is trying to start interrogation while already in one

      char interrogaterName[MAX_NAME_LENGTH];
      GetClientName(interrogater, interrogaterName, sizeof(interrogaterName));
      CReplyToCommand(client, "{orchid}Interrogate: {darkred}ERROR {default}%s is currently investigating %s. Please try again later when that investigation concludes.", interrogaterName, interrogateeName);

      return Plugin_Handled;
   }

   if(GetClientMenu(client, INVALID_HANDLE) != MenuSource_None)
   {
      //Stop client from trying to pull up another menu with one already open
      CReplyToCommand(client, "{orchid}Interrogate: {default}ERROR - Cannot display menu as client already has menu open. Please close current menu and try again.");
      return Plugin_Handled;
   }

   if(GetCmdArgs() == 1) //Client entered target name
   {
      //Loop through current clients for matching name
      char targetArg[MAX_NAME_LENGTH];
      GetCmdArg(1, targetArg, sizeof(targetArg));

      //Create variables to check for collisions
      int timesFound = 0;
      int matchclient = 0;
      Menu menu = new Menu(InterrogateMenu, MENU_ACTIONS_ALL);
      menu.SetTitle("Multiple Matches Found:");

      for(int i = 1; i < GetClientCount(true); i++)
      {
         if(!IsClientInGame(i))
         {
            continue;
         }

         //Get the name of current client
         char temp[MAX_NAME_LENGTH];
         GetClientName(i, temp, sizeof(temp));

         //If the query is contained within current client name or is equal to
         if(StrEqual(targetArg, temp, false) || StrContains(temp, targetArg, false) != -1)
         {
            timesFound++;
            matchclient = i;

            char tempid[12];
            IntToString(GetClientUserId(i), tempid, sizeof(tempid));
            menu.AddItem(tempid, temp);
         }
      }

      if(timesFound == 0)
      {
         //Couldn't find matching client
         CReplyToCommand(client, "{orchid}Interrogate: {default}Unable to locate client: %s. Check spelling and try again, or type \"!intg\" or \"!interrogate\" to choose from all connected clients.", targetArg);
      }
      else if(timesFound == 1)
      {
         //Found the target with no collisions
         Interrogate(client, matchclient);
      }
      else
      {
         //Display menu of collisions for requester to choose
         CReplyToCommand(client, "{orchid}Interrogate: {default}Multiple matches found. Please choose correct target.");
         menu.Display(client, MENU_TIME_FOREVER);
      }

      return Plugin_Continue;
   }

   if(GetCmdArgs() != 0)
   {
      //Invalid argument syntax
      CReplyToCommand(client, "{orchid}Interrogate: {darkred}ERROR {default}Invalid command syntax. (!intg | !interrogate <username>)");
      return Plugin_Handled;
   }

   //Create menu of all clients for interrogater to choose target
   Menu menu = new Menu(InterrogateMenu, MENU_ACTIONS_ALL);
   menu.SetTitle("Choose Target");

   for(int target = 1; target <= GetClientCount(true); target++)
   {
      if(!IsClientInGame(target) || target == client)
      {
         //Skip if target left or found own client
         continue;
      }

      //Add menu item of (Menu ID: target's userid, Display: target's name)
      char targetid[12];
      char targetName[MAX_NAME_LENGTH];
      IntToString(GetClientUserId(target), targetid, sizeof(targetid));
      GetClientName(target, targetName, sizeof(targetName));
      menu.AddItem(targetid, targetName);
   }

   menu.Display(client, MENU_TIME_FOREVER);

   return Plugin_Handled;
}

public Action Interrogate(int client, int target)
{
   if(GetConVarInt(Cvar_Intg) != 1)
   {
      return Plugin_Stop;
   }

   if(!IsClientInGame(client))
   {
      //Client disconnected
      return Plugin_Continue;
   }

   if(!IsClientInGame(target))
   {
      CReplyToCommand(client, "{orchid}Interrogate: {default}ERROR - Target not in game.");
      return Plugin_Handled;
   }

   //Set so interrogater and interrogatee can hear each other
   SetListenOverride(client, target, Listen_Yes);
   SetListenOverride(target, client, Listen_Yes);

   for(int i = 1; i <= GetClientCount(true); i++)
   {
      if(i == client || i == target || !IsClientInGame(i))
      {
         continue;
      }

      //Set so all other clients can't hear either person in interrogation
      SetListenOverride(i, client, Listen_No);
      SetListenOverride(client, i, Listen_No);

      SetListenOverride(i, target, Listen_No);
      SetListenOverride(target, i, Listen_No);
   }

   //Set values of corresponding global variables
   in_interrogation = true;
   interrogater = client;
   interrogatee = target;
   GetClientName(target, interrogateeName, sizeof(interrogateeName));

   //Display menu that allows interrogater to end interrogation
   Menu endMenu = new Menu(EndInterrogateMenu, MENU_ACTIONS_ALL);
   endMenu.SetTitle("Active interrogation: %s", interrogateeName);
   endMenu.AddItem("done", "End interrogation");
   endMenu.ExitButton = false;
   endMenu.Display(interrogater, MENU_TIME_FOREVER);

   //Alert the respective parties about interrogation
   CReplyToCommand(interrogater, "{orchid}Interrogate: {default}Interrogation of target \"%s\" has successfully been started.", interrogateeName);
   CPrintToChat(interrogatee, "{orchid}Interrogate: {default}You are now being interrogated.");

   //Alert all admins interrogation is beginning
   NotifyAdmins(1);

   return Plugin_Continue;
}

public void EndInterrogate(char[] reason)
{
   char targetName[MAX_NAME_LENGTH];

   if(!in_interrogation)
   {
      CPrintToServer("Interrogate: ERROR - Trying to end nonexistent interrogation.");
   }

   if(IsClientInGame(interrogatee))
   {
      GetClientName(interrogatee, targetName, sizeof(targetName));
      CPrintToChat(interrogatee, "{orchid}Interrogate: {default}Interrogation has now ended.");
      resetListen(interrogatee);
   }

   if(IsClientInGame(interrogater))
   {
      CPrintToChat(interrogater, "{orchid}Interrogate: {default}Interrogation of %s ended. Reason: %s", targetName, reason);
      resetListen(interrogater);
   }

   if(IsClientInGame(interrogater) && !IsClientInGame(interrogatee))
   {
      CPrintToChat(interrogater, "{orchid}Interrogate: {default}Interrogation was ended. Reason: %s", reason);
      resetListen(interrogater);
   }

   //Alert all admins interrogation is ending
   NotifyAdmins(0);

   in_interrogation = false;
   interrogater = 0;
   interrogatee = 0;
}

public int InterrogateMenu(Menu menu, MenuAction action, int param1, int param2)
{
   if(action ==  MenuAction_Select)
   {
      //Client selected a menu item; get the target from param2
      char t_string[32];
      menu.GetItem(param2, t_string, sizeof(t_string));
      int target = StringToInt(t_string);
      target = GetClientOfUserId(target);

      if(target == 0)
      {
         //Error getting client
         CPrintToChat(param1, "{orchid}Interrogate: {default}ERROR - Unable to interrogate.");
      }

      Interrogate(param1, target);
   }
   else if(action == MenuAction_Cancel)
   {
      //Client has cancelled the menu; get the cancel reason from param2
      char choice[32];
      menu.GetItem(param2, choice, sizeof(choice));

      if(StrEqual(choice, "MenuAction_Select"))
      {
         //Menu closed because client made selection
         CPrintToChat(param1, "{orchid}Interrogate: {default}Interrogation has begun.");
      }
      else
      {
         //Menu closed because client exited
         CPrintToChat(param1, "{orchid}Interrogate: {default}Interrogation aborted.");
      }
   }

   return 0;
}

public int EndInterrogateMenu(Menu menu, MenuAction action, int param1, int param2)
{
   //Display menu which allows interrogater to end interrogation
   if(action == MenuAction_Select)
   {
      char choice[32]
      menu.GetItem(param2, choice, sizeof(choice));

      if(StrEqual(choice, "done"))
      {
         EndInterrogate("Successfully completed interrogation.");
      }
   }
}

public void resetListen(int client)
{
   //Reset listening override of given client so everyone can hear them
   if(!IsClientInGame(client))
   {
      return;
   }

   for(int i = 1; i <= GetClientCount(true); i++)
   {
      if(i == client || !IsClientInGame(i))
      {
         continue;
      }

      SetListenOverride(client, i, Listen_Default);
      SetListenOverride(i, client, Listen_Default);
   }
}

//Goes through all clients and alerts if they are an admin; 1 = begin | 0 = end
public void NotifyAdmins(int bcuz)
{
   char interrogaterName[MAX_NAME_LENGTH];
   GetClientName(interrogater, interrogaterName, sizeof(interrogaterName));

   char output[126];
   if(bcuz == 0)
   {
      //Notify the interrogation is ending
      Format(output, sizeof(output), "%s's interrogation of %s has ended.", interrogaterName, interrogateeName);
   }
   else if(bcuz == 1)
   {
      //Notify interrogation is starting
      Format(output, sizeof(output), "%s's interrogation of %s has begun.", interrogaterName, interrogateeName);
   }
   else
   {
      return;
   }

   for(int i = 1; i < GetClientCount(true); i++)
   {
      if(CheckCommandAccess(i, "", ADMFLAG_GENERIC, true))
      {
         //Current client is an admin
         CPrintToChat(i, "{orchid}Interrogate: {default}%s", output);
      }
   }
}

//Returns true or false if client is involved in interrogation
public int Native_Interrogate_Include(Handle plugin, int numParams)
{
   //This native matches with the .inc file to communicate with other plugins
   //Get the client parameter
   int client = GetNativeCell(1);

   if(!in_interrogation)
   {
      //Investigation is not going on
      return false;
   }

   if(client == 0 || interrogater == 0 || interrogatee == 0)
   {
      //Investigation is not going on
      return false;
   }

   if(client == interrogater || client == interrogatee)
   {
      //Client is either the interrogater or interrogatee
      return true;
   }

   return false;
}
