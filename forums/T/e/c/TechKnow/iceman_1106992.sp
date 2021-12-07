/* sm_iceman.sp

Description: iceman Theme model changer

Versions: 1.0

Changelog:

1.0 - Initial Release

- sm_iceman <1|0>


*/

#include <sourcemod>
#include <sdktools>

//#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define MAX_FILE_LEN 256


// Plugin definitions
public Plugin:myinfo = 
{
	name = "sm_iceman",
	author = "TechKnow",
        version = "1.0",
	description = "iceman Theme model changer", version = PLUGIN_VERSION,
	url = "http://sourcemodplugin.14.forumer.com"
};

new Handle:g_Cvariceman_on = INVALID_HANDLE;
new Handle:g_Cvarcticeman = INVALID_HANDLE;
new Handle:g_Cvarticeman = INVALID_HANDLE;
new String:g_cticeman[MAX_FILE_LEN];
new String:g_ticeman[MAX_FILE_LEN];
new onoff;
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hSetModel;
new bool:custom = true;


public OnPluginStart()
{
	CreateConVar("sm_iceman_version", PLUGIN_VERSION, "iceman Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        g_Cvariceman_on = CreateConVar("sm_iceman_on", "1", "Set to 1 to enable custom models");

        g_Cvarcticeman = CreateConVar("sm_cticeman_model", "models/player/techknow/ironman_v3/ironman3.mdl", "The ct custom model");

        g_Cvarticeman = CreateConVar("sm_ticeman_model", "models/player/techknow/iceman/iceman.mdl", "The t custom model");
 
        RegAdminCmd("sm_iceman", Command_SetCustom, ADMFLAG_SLAY);

	// Load the gamedata file
	hGameConf = LoadGameConfigFile("custom.games");
	if (hGameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/custom.games.txt not loadable");
	}

        StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	hSetModel = EndPrepSDKCall();

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public OnMapStart()
{
	decl String:buffer[MAX_FILE_LEN];
        GetConVarString(g_Cvarcticeman, g_cticeman, sizeof(g_cticeman));
        if (strcmp(g_cticeman, ""))
	{
		PrecacheModel(g_cticeman, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_cticeman);
		AddFileToDownloadsTable(buffer);
	}
        GetConVarString(g_Cvarticeman, g_ticeman, sizeof(g_ticeman));
        if (strcmp(g_ticeman, ""))
	{
		PrecacheModel(g_ticeman, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_ticeman);
		AddFileToDownloadsTable(buffer);
	}
        //open precache file and add everything to download table
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/iceman.ini")
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
        PrecacheModel(g_cticeman, true);
        PrecacheModel(g_ticeman, true);
}

public Action:Command_SetCustom(client, args)
{
	if (args < 1)
        {
		ReplyToCommand(client, "[SM] Usage: sm_iceman <1/0>");
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
                          set_random_model((i),team);
                       }
                       else if (GetClientTeam(i) == 2)
                       {
                        // Make player random t model
                          team = 2;
                          set_random_model((i),team);
                       }
	       }
        }
        }
        return Plugin_Continue;
}

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
                          SDKCall(hSetModel,(i),g_cticeman);
                       }
                       else if (GetClientTeam(i) == 2)
                       {
                        // Make player Custom t model
                          SDKCall(hSetModel,(i),g_ticeman);
                       }
	       }
        }
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{       
        if (!GetConVarBool(g_Cvariceman_on) && (custom == false))
	{
		return Plugin_Continue;
	}
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (GetClientTeam(client) == 3)
	{
        // Make player a CT custom model
           SDKCall(hSetModel,client,g_cticeman);
        }
        else if (GetClientTeam(client) == 2)
        {
        // Make player a T custom model
            SDKCall(hSetModel,client,g_ticeman);
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
		SDKCall(hSetModel,client,tmodels[random])
	}
	else if (team==3) //ct	
	{
		SDKCall(hSetModel,client,ctmodels[random])
	}
	
}