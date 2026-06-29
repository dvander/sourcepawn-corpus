/* sm_masterchief.sp

Description: masterchief Theme model changer

Versions: 1.0

Changelog:

1.0 - Initial Release

- sm_masterchief <1|0>


*/

#include <sourcemod>
#include <sdktools>

//#pragma semicolon 1

#define PLUGIN_VERSION "2.0"
#define MAX_FILE_LEN 256


// Plugin definitions
public Plugin:myinfo = 
{
	name = "sm_masterchief",
	author = "TechKnow",
        version = "1.0",
	description = "masterchief Theme model changer", version = PLUGIN_VERSION,
	url = "http://sourcemodplugin.14.forumer.com"
};

new Handle:g_Cvarmasterchief_on = INVALID_HANDLE;
new String:g_ctmasterchief[MAX_FILE_LEN] = "models/player/techknow/masterchief/blue_mc.mdl";
new String:g_tmasterchief[MAX_FILE_LEN] = "models/player/techknow/masterchief/red_mc.mdl";
new onoff;
new bool:custom = true;


public OnPluginStart()
{
	CreateConVar("sm_masterchief_version", PLUGIN_VERSION, "masterchief Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        g_Cvarmasterchief_on = CreateConVar("sm_masterchief_on", "1", "Set to 1 to enable custom models");

        RegAdminCmd("sm_masterchief", Command_SetCustom, ADMFLAG_SLAY);

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public OnMapStart()
{
        decl String:buffer[MAX_FILE_LEN];
        //open precache file and add everything to download table
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/masterchief.ini")
	new Handle:fileh = OpenFile(file, "r")
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		new len = strlen(buffer)
		if (buffer[len-1] == '\n')
   			buffer[--len] = '\0'
   			
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer)
		}
		
		if (IsEndOfFile(fileh))
			break
	}
        PrecacheModel(g_ctmasterchief, true);
        PrecacheModel(g_tmasterchief, true);
}

public Action:Command_SetCustom(client, args)
{
	if (args < 1)
        {
		ReplyToCommand(client, "[SM] Usage: sm_masterchief <1/0>");
		return Plugin_Handled;
	}
       
	new String:sb[10];
	GetCmdArg(1, sb, sizeof(sb));
        onoff = StringToInt(sb);
        if(onoff == 1)
        {
                custom = true;
                DoCustom();
	}
        if(onoff == 0)
        {
          // Admin Turnoff custom model /// REMOVE MODEL/////
         custom = false;
	 for(new i = 1; i <= GetMaxClients(); i++)
	 {
	       if(IsClientInGame(i))
	       {
                       PrintToChat((i),"[SM] Your custom model has been removed"); 
                       new team;
                       if (GetClientTeam(i) == 3)
	               {
                        // Make player a random ct model 
                          team = 3;
                          set_random_model(i,team);
                       }
                       else if (GetClientTeam(i) == 2)
                       {
                        // Make player random t model
                          team = 2;
                          set_random_model(i,team);
                       }
	       }
        }
        }
        return Plugin_Continue;
}
//149
public DoCustom()
{
	 for(new i = 1; i <= GetMaxClients(); i++)
	 {
	       if(IsClientInGame(i))
	       {
                       PrintToChat((i),"[SM] You have been given a custom model"); 
                       if (GetClientTeam(i) == 3)
	               {
                        // Make player a Custom ct model 
                          SetEntityModel(i,g_ctmasterchief);
                       }
                       else if (GetClientTeam(i) == 2)
                       {
                        // Make player Custom t model
                          SetEntityModel(i,g_tmasterchief);
                       }
	       }
        }
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{       
        if (!GetConVarBool(g_Cvarmasterchief_on) && (custom == false))
	{
		return Plugin_Continue;
	}
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (GetClientTeam(client) == 3)
	{
        // Make player a CT custom model
           SetEntityModel(client,g_ctmasterchief);
        }
        else if (GetClientTeam(client) == 2)
        {
        // Make player a T custom model
            SetEntityModel(client,g_tmasterchief);
        }
        return Plugin_Continue;
}

static const String:ctmodels[4][] = {"models/player/ct_urban.mdl","models/player/ct_gsg9.mdl","models/player/ct_sas.mdl","models/player/ct_gign.mdl"}
static const String:tmodels[4][] = {"models/player/t_phoenix.mdl","models/player/t_leet.mdl","models/player/t_arctic.mdl","models/player/t_guerilla.mdl"}

stock set_random_model(client,team)
{
	new random=GetRandomInt(0, 3)
	
	if (team==2) //t
	{
		SetEntityModel(client,tmodels[random])
	}
	else if (team==3) //ct	
	{
		SetEntityModel(client,ctmodels[random])
	}	
}