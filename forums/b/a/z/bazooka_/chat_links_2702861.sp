/*
   - v2.0.2 Fully tested and working general use version

   - USAGE: Add links to chat_links.txt in configs and thats it. No need to refresh plugin
*/

#include <sourcemod>
#include <multicolors>

#define VERSION "2.1.0"
#pragma newdecls required

Handle Cvar_Links = INVALID_HANDLE;
char filepath[] = {"configs/chat_links.txt"};
Menu linksMenu;
Handle file;

public Plugin myinfo =
{
   name = "Bazooka's Chat Links Plugin",
   description = "Plugin that dynamically adds provided links for users to access in game via !links or each individual link's command.",
   author = "bazooka",
   version = VERSION,
   url= "https://github.com/bazooka-codes"
};

public void OnPluginStart()
{
   CreateConVar("sm_chat_links_version", VERSION, "Current build of Chat links Plugin.");
   Cvar_Links = CreateConVar("sm_chat_links_enable", "1", "1 - Links plugin enabled | 0 - Links plugin disabled");
   RegConsoleCmd("sm_links", ShowLinkMenu);

   //Timer repeats every 7 minutes
   CreateTimer(420.0, NotifyTimer, _, TIMER_REPEAT);

   verifyFilePath();
}

public void OnMapStart()
{
   verifyFilePath();

   //Create menu to display
   linksMenu = new Menu(LinkMenuHandler, MENU_ACTIONS_ALL);
   linksMenu.SetTitle("Choose Link to Display");

   GetLinkFromFile(true, 0, "", 0);
}

public Action NotifyTimer(Handle timer)
{
   if(file == null || GetConVarInt(Cvar_Links) != 1)
   {
      return Plugin_Stop;
   }

   //Advertise clients can !links
   CPrintToChatAll("{olive}Want to get in touch? {orange}Want more info? {orchid}Type {darkblue}\"!links\" {lightred}in chat to see a menu of relevant links!");

   return Plugin_Continue;
}

public Action ShowLinkMenu(int client, int args)
{
   if(file == null || GetConVarInt(Cvar_Links) != 1)
   {
      return Plugin_Stop;
   }

   //Display menu to client
   linksMenu.Display(client, MENU_TIME_FOREVER);

   return Plugin_Handled;
}

public int LinkMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
   if(file == null || GetConVarInt(Cvar_Links) != 1)
   {
      return 0;
   }

   //Client "selected" a menu item
   if(action == MenuAction_Select)
   {
      //Client is first parameter of menu selection
      int client = param1;

      //Extract the line number we stored as id from other method
      char lineNumStr[32];
      menu.GetItem(param2, lineNumStr, sizeof(lineNumStr));
      int lineNum = StringToInt(lineNumStr);

      GetLinkFromFile(false, client, "", lineNum);
   }

   return 0;
}

public Action LinkCommandHandler(int client, int args)
{
   if(file == null || GetConVarInt(Cvar_Links) != 1)
   {
      return Plugin_Stop;
   }

   char argstr[32];
   GetCmdArg(0, argstr, sizeof(argstr));
   GetLinkFromFile(false, client, argstr, 0);

   return Plugin_Handled;
}

/*
*  client
*  Mode  true  *   add to menu and register links
*        false *  find link
*  cmd   if mode = false and cmd !="", use cmd to search for matching link
*  lineNum  if mode = false and lineNum != 0, use line number to search for link
*/
public void GetLinkFromFile(bool mode, int client, char[] cmd, int lineNum)
{
   resetSeek();

   //Return the link to the given command or at given line number
   int counter = 0;
   char line[256];
   while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
   {
      if(!mode && lineNum != 0 && counter != lineNum)
      {
         //Mode finding line number and this isnt it
         counter++;
         continue;
      }

      if(line[0] == '/' && line[1] == '/')
      {
         //Line starts "//" meaning skip comment
         counter++;
         continue;
      }

      char words[2][124];
      if(ExplodeString(line, "\t", words, sizeof(words), sizeof(words[]), false) == 2)
      {
         //Split line into seperate strings
         char command[124];
         strcopy(command, sizeof(command), words[0]);
         char link[124];
         strcopy(link, sizeof(link), words[1]);

         //Remove messy characters
         TrimString(command);
         TrimString(link);
         StripQuotes(command);
         StripQuotes(link);

         //adding to menu and registering links
         if(mode)
         {
            //Use line count as the id for selection
            char counterStr[32];
            IntToString(counter, counterStr, sizeof(counterStr));

            //Add the current line to the menu
            linksMenu.AddItem(counterStr, command);

            if(!CommandExists(command))
            {
               RegConsoleCmd(command, LinkCommandHandler);
            }
         }

         //finding links
         if(!mode)
         {
            if(lineNum == 0 && !StrEqual(command, cmd))
            {
               //Current command does not match entered argument
               counter++;
               continue;
            }

            //Current line matches lineNum or given command argument
            //Print the link in the client's console and chat
            CPrintToChat(client, "{orchid}Chat Links: {default}%s - {darkblue}Copy and paste link into a browser.", link);
            PrintToConsole(client, "Chat Links: %s - Copy and paste link into a browser.", link);
         }
      }
      counter++
   }
}

public bool verifyFilePath()
{
   //Create the filepath from local string path
   char path[PLATFORM_MAX_PATH];
   BuildPath(Path_SM, path, sizeof(path), filepath);

   if(FileExists(path, false))
   {
      file = OpenFile(path, "r");

      if(file != null)
      {
         PrintToServer("[Chat Links]: File successfully located.");
         return true;
      }
      else
      {
         PrintToServer("[Chat Links]: ERROR - File could not be opened.");
      }
   }
   else
   {
      PrintToServer("[Chat Links]: ERROR - Unable to find .txt file at path: %s.", filepath);
   }

   return false;
}

public void resetSeek()
{
   if(file == null)
   {
      return;
   }

   //Set the file reader back to the start
   FileSeek(file, 0, SEEK_SET);
}
