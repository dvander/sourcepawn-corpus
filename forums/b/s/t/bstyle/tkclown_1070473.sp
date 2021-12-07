/* Teamkiller Clown

Description: Teamkilling results in becoming a TK Clown.
Thanks to Lumpi@work from the eventscripts forum for letting me use his clown skins. 
He did this script for eventscripts, i just ported it to sourcemod.

Changelog:

(06/27/10): Version 1.0.2
-------------------------
! Fixed multiple chat output when killing more than one teammate during one round.

(01/29/10): Version 1.0.1
-------------------------
! Fixed german Translation
! Fixed UTF-8 format for translation file

(01/28/10): Version 1.0.0
-------------------------
Initial Release

*/

#include <sourcemod> 
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
  name = "tkclown",
  author = "bstyle",
	version = PLUGIN_VERSION,
  description = "Teamkilling results in becoming a TK Clown.",
  url = "http://www.sourcemod.net/"
};

new Handle:g_CvarEnabled;
new Handle:g_CvarDuration;
new Handle:g_CvarTkClownCtModel;
new Handle:g_CvarTkClownTModel;
new arrayTkPlayer[MAXPLAYERS + 1];
new String:g_CtSkin[256];
new String:g_TSkin[256];
new bool:g_bSkinCT;
new bool:g_bSkinT;

public OnPluginStart()
{
  LoadTranslations("tkclown.phrases");
  
  CreateConVar("tk_clown_version", PLUGIN_VERSION, "TK Clowns Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  
  g_CvarEnabled = CreateConVar("tk_clown_enabled", "1", "Enables (1) oder disables (0) the plugin.");
  g_CvarDuration = CreateConVar("tk_clown_duration", "1", "Configures the duration of the Clown status. 0 - till the end of the actual round, >0 sets the number of rounds the teamkiller gets the clown status.");
  g_CvarTkClownCtModel = CreateConVar("tk_clown_ct_model", "models/player/tkclown/clown_gsg9/ct_gsg9.mdl", "Path to the CT's custom model .mdl-file. Use 'off' to disable the custom model. Use forward slashes only!");
  g_CvarTkClownTModel = CreateConVar("tk_clown_t_model", "models/player/tkclown/clown_leet/t_leet.mdl", "Path to the T's custom model .mdl-file. Use 'off' to disable the custom model. Use forward slashes only!");
  
  HookEvent("player_spawn", Event_PlayerSpawn);
  HookEvent("player_death", Event_PlayerDeath);
  
  AutoExecConfig(true, "tk_clown", "sourcemod");
}

public OnConfigsExecuted()
{
  decl String:buffer[256];
  GetConVarString(g_CvarTkClownCtModel, buffer, sizeof(buffer));
  if (!StrEqual(buffer, "off", false))
	{
		PrecacheModel(buffer);
		Format(g_CtSkin, sizeof(g_CtSkin), buffer);
		AddDLs(buffer);
		Format(buffer, sizeof(buffer), "materials/%s", g_CtSkin);
		AddDLs(buffer);
		g_bSkinCT = true;
	}
	else
		g_bSkinCT = false;
  GetConVarString(g_CvarTkClownTModel, buffer, sizeof(buffer));
  if (!StrEqual(buffer, "off", false))
	{
		PrecacheModel(buffer);
		Format(g_TSkin, sizeof(g_TSkin), buffer);
		AddDLs(buffer);
		Format(buffer, sizeof(buffer), "materials/%s", g_TSkin);
		AddDLs(buffer);
		g_bSkinT = true;
	}
	else
		g_bSkinT = false;
}

public OnClientConnected(client)
{
  arrayTkPlayer[client] = 0;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{ 
  // Get player index of teamkiller
  new client = GetClientOfUserId(GetEventInt(event,"userid"));
  
  if (arrayTkPlayer[client] > 0)
  {
    decl String:attackerName[64];
    GetClientName(client, attackerName, sizeof(attackerName));
    
    // Get tk_clown duration of teamkiller
    new tkrounds = arrayTkPlayer[client];
    
    if (arrayTkPlayer[client] == 1)
    {
      CPrintToChat(client, "%t", "Clown");
      CPrintToChatAllEx(client, "%t", "Woohoo" ,attackerName);
      SetModel(client);
      arrayTkPlayer[client] -= 1;      
    }
    else
    {
      CPrintToChat(client, "%t", "Clown_plural", tkrounds);
      CPrintToChatAllEx(client, "%t", "Woohoo", attackerName);
      SetModel(client);
      arrayTkPlayer[client] -= 1;
    }      
  }
}  

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  
  if (GetConVarBool(g_CvarEnabled))
  {
    // Get player index of involved players
    new victim = GetClientOfUserId(GetEventInt(event,"userid"));
    new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
    
    decl String:attackerName[64];
    GetClientName(attacker, attackerName, sizeof(attackerName));
    
    if(attacker != 0 && victim != 0 && IsClientConnected(attacker) && IsClientConnected(victim) && victim != attacker && arrayTkPlayer[attacker] == 0)
		{
			// Get team of involved players
      new victimTeam = GetClientTeam(victim);
      new attackerTeam = GetClientTeam(attacker);

      if(victimTeam == attackerTeam)
			{
        new tkrounds = GetConVarInt(g_CvarDuration);
        arrayTkPlayer[attacker] = tkrounds;
        
        CPrintToChatEx(victim, attacker, "%t", "gotKilled", attacker);
        
        if (arrayTkPlayer[attacker] == 1)
        {
          CPrintToChat(attacker, "%t", "Clown");
          CPrintToChatAllEx(attacker, "%t", "Woohoo" ,attackerName);      
        }
        else
        {
          CPrintToChat(attacker, "%t", "Clown_plural", tkrounds);
          CPrintToChatAllEx(attacker, "%t", "Woohoo", attackerName);
        }
        
        //Set clown model
        SetModel(attacker);
      }
    }
  }
}

AddDLs(String:path[])
{
	new len = strlen(path);
	for (new i = len; i >= 0; i--)
	{
		if (path[i] != '/')
			path[i] = '\0';
		else
		{
			path[i] = '\0';
			break;
		}
	}
	TrimString(path);
	if (DirExists(path))
	{
		new Handle:dir = OpenDirectory(path);
		new FileType:type;
		decl String:file[256];
		while (ReadDirEntry(dir, file, sizeof(file), type))
		{
			if (type == FileType_File)
			{
				Format(file, sizeof(file), "%s/%s", path, file);
				AddFileToDownloadsTable(file);
			}
		}
		CloseHandle(dir);
	}
	else
		LogError("Directory %s does not exist.", path);
}

SetModel(client)
{
	new team = GetClientTeam(client);
	if ((team == 3) && g_bSkinCT)
		SetEntityModel(client, g_CtSkin);
	else if ((team == 2) && g_bSkinT)
		SetEntityModel(client, g_TSkin);
}