#include <sourcemod>
#include <sdktools>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

new Handle:v_NameFreePrefix = INVALID_HANDLE;
new Handle:v_NameFreeSuffix = INVALID_HANDLE;

new Handle:v_NamePremiumPrefix = INVALID_HANDLE;
new Handle:v_NamePremiumSuffix = INVALID_HANDLE;

new bool:g_PluginChangedName[MAXPLAYERS+1] = false;

new Handle:cvarAllowedCodes = INVALID_HANDLE;

new g_allowedCodes = 1;

#define PLUGIN_VERSION "2.0.0"

public Plugin:myinfo = {
   name        = "[TF2] Name CleanUp and Tagger",
   author      = "DarthNinja & Sillium",
   description = "Automatically adds tags for premium and non-premium players and cleans up color code",
   version     = PLUGIN_VERSION,
   url         = "alliedmods.net"
};

public OnPluginStart()
{
   CreateConVar("sm_free2rename_version", PLUGIN_VERSION, "Free2BeRenamed", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
   v_NameFreePrefix = CreateConVar("sm_free_prefix", "[F2P]", "Prefix tag for free users");
   v_NameFreeSuffix = CreateConVar("sm_free_suffix", "", "Suffix tag for free users");
   
   v_NamePremiumPrefix = CreateConVar("sm_premium_prefix", "", "Prefix tag for premium users");
   v_NamePremiumSuffix = CreateConVar("sm_premium_suffix", "", "Suffix tag for premium users");
   
   cvarAllowedCodes = CreateConVar("sm_colorcodecleanup_threshold", "1", "Max color codes before strip");

   HookEvent("player_changename", OnPlayerChangeName, EventHookMode_Post);
   
   AutoExecConfig(true, "Free2Rename");
}

public OnClientPostAdminCheck(client)
{   
   if (IsFakeClient(client))
      return;
      
      
   g_allowedCodes = GetConVarInt(cvarAllowedCodes);
   decl String:clientName[MAX_NAME_LENGTH];
   decl String:newNameColor[MAX_NAME_LENGTH];
   new j = 0;
   new foundCodes = 0;
   if(!GetClientName(client, clientName, MAX_NAME_LENGTH))
      return;
   new nameLen = strlen(clientName);
   new curchar, nextchar;
   for(new i = 0; i < nameLen; i++)
   {
      curchar = clientName[i];
      nextchar = clientName[i+1];
      if(curchar == '^' && nextchar >= '0' && nextchar <= '9')
      {
         foundCodes++;
         i++;
      }
      else
      {
         newNameColor[j++] = curchar;
      }
   }
   newNameColor[j] = 0;
   if(foundCodes > g_allowedCodes)
   {
      if(newNameColor[0] == 0) // Null, like empty name?
         strcopy(newNameColor, MAX_NAME_LENGTH, "Unnamed");
      //ServerCommand("sm_rename #%d \"%s\"", GetClientUserId(client), newNameColor);
      ShowActivityEx(client, "[NameChange] ", "%s was stripped of color codes to leave %s", clientName, newNameColor);
   }

      
   if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
   {
      decl String:Prefix[MAX_NAME_LENGTH];
      decl String:Suffix[MAX_NAME_LENGTH];
      GetConVarString(v_NameFreePrefix, Prefix, MAX_NAME_LENGTH);
      GetConVarString(v_NameFreeSuffix, Suffix, MAX_NAME_LENGTH);
      
      if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
      {
         decl String:NewName[MAX_NAME_LENGTH];
         FormatEx(NewName, MAX_NAME_LENGTH, "%s%s%s", Prefix, newNameColor, Suffix);
         SetClientInfo(client, "name", NewName);
         g_PluginChangedName[client] = true;
      }
      return;
   }
   else
   {
      decl String:Prefix[MAX_NAME_LENGTH];
      decl String:Suffix[MAX_NAME_LENGTH];
      GetConVarString(v_NamePremiumPrefix, Prefix, MAX_NAME_LENGTH);
      GetConVarString(v_NamePremiumSuffix, Suffix, MAX_NAME_LENGTH);
      
      if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
      {
         decl String:NewName[MAX_NAME_LENGTH];
         FormatEx(NewName, MAX_NAME_LENGTH, "%s%s%s", Prefix, newNameColor, Suffix);
         SetClientInfo(client, "name", NewName);
         g_PluginChangedName[client] = true;
      }
   }
   return;
}

public Action:Timer_Rename(Handle:timer, Handle:pack)
{
   decl String:NewName[MAX_NAME_LENGTH]
   ResetPack(pack);
   ReadPackString(pack, NewName, sizeof(NewName));
   new client = GetClientOfUserId(ReadPackCell(pack));
   
   if (client != 0)
   {
      SetClientInfo(client, "name", NewName);
   }
      
   return Plugin_Stop;
}


public OnPlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
   new client = GetClientOfUserId(GetEventInt(event, "userid"));
   
   if (IsFakeClient(client))
   {
      return;
   }
   //This plugin changed the players name, we can skip the rest of this.
   if (g_PluginChangedName[client])
   {
      g_PluginChangedName[client] = false;
      return;
   }
   
   g_allowedCodes = GetConVarInt(cvarAllowedCodes);
   decl String:Name[MAX_NAME_LENGTH];
   GetEventString(event, "newname", Name, sizeof(Name));
   
   decl String:newNameColor[MAX_NAME_LENGTH];
   new j = 0;
   new foundCodes = 0;
 
   new nameLen = strlen(Name);
   new curchar, nextchar;
   for(new i = 0; i < nameLen; i++)
   {
      curchar = Name[i];
      nextchar = Name[i+1];
      if(curchar == '^' && nextchar >= '0' && nextchar <= '9')
      {
         foundCodes++;
         i++;
      }
      else
      {
         newNameColor[j++] = curchar;
      }
   }
   newNameColor[j] = 0;
   if(foundCodes > g_allowedCodes)
   {
      if(newNameColor[0] == 0) // Null, like empty name?
         strcopy(newNameColor, MAX_NAME_LENGTH, "Unnamed");
      //ServerCommand("sm_rename #%d \"%s\"", GetClientUserId(client), newNameColor);
      ShowActivityEx(client, "[NameChange] ", "%s was stripped of color codes to leave %s", Name, newNameColor);
   }
   
   if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
   {
      //Free player
      decl String:Prefix[MAX_NAME_LENGTH];
      decl String:Suffix[MAX_NAME_LENGTH];
      GetConVarString(v_NameFreePrefix, Prefix, MAX_NAME_LENGTH);
      GetConVarString(v_NameFreeSuffix, Suffix, MAX_NAME_LENGTH);
      if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
      {
         decl String:NewName[MAX_NAME_LENGTH];
         FormatEx(NewName, MAX_NAME_LENGTH, "%s%s%s", Prefix, newNameColor, Suffix);
         g_PluginChangedName[client] = true;
         new Handle:pack;
         CreateDataTimer(15.0, Timer_Rename, pack, TIMER_FLAG_NO_MAPCHANGE);
         WritePackString(pack, NewName);
         WritePackCell(pack, GetClientUserId(client));
      }
   }
   else
   {
      decl String:Prefix[MAX_NAME_LENGTH];
      decl String:Suffix[MAX_NAME_LENGTH];
      GetConVarString(v_NamePremiumPrefix, Prefix, MAX_NAME_LENGTH);
      GetConVarString(v_NamePremiumSuffix, Suffix, MAX_NAME_LENGTH);
      
      if (!StrEqual(Prefix, "") || !StrEqual(Suffix, ""))
      {
         decl String:NewName[MAX_NAME_LENGTH];
         FormatEx(NewName, MAX_NAME_LENGTH, "%s%s%s", Prefix, newNameColor, Suffix);
         g_PluginChangedName[client] = true;
         new Handle:pack;
         CreateDataTimer(15.0, Timer_Rename, pack, TIMER_FLAG_NO_MAPCHANGE);
         WritePackString(pack, NewName);
         WritePackCell(pack, GetClientUserId(client));
      }
   }
}