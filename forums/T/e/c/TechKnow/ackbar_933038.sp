/* sm_ackbar.sp

Description: ackbar Theme model changer

Versions: 1.0

Changelog:

1.0 - Initial Release

- sm_ackbar <1|0>


*/

#include <sourcemod>
#include <sdktools>

//#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define MAX_FILE_LEN 256


// Plugin definitions
public Plugin:myinfo = 
{
	name = "sm_ackbar",
	author = "TechKnow",
        version = "1.0",
	description = "ackbar Theme model changer", version = PLUGIN_VERSION,
	url = "http://sourcemodplugin.14.forumer.com"
};

new Handle:g_Cvarackbar_on = INVALID_HANDLE;
new Handle:g_Cvarctackbar = INVALID_HANDLE;
new Handle:g_Cvartackbar = INVALID_HANDLE;
new String:g_ctackbar[MAX_FILE_LEN];
new String:g_tackbar[MAX_FILE_LEN];
new onoff;
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hSetModel;
new bool:custom = true;


public OnPluginStart()
{
	CreateConVar("sm_ackbar_version", PLUGIN_VERSION, "ackbar Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        g_Cvarackbar_on = CreateConVar("sm_ackbar_on", "1", "Set to 1 to enable custom models");

        g_Cvarctackbar = CreateConVar("sm_ctackbar_model", "models/player/techknow/paranoya/paranoya.mdl", "The ct custom model");

        g_Cvartackbar = CreateConVar("sm_tackbar_model", "models/player/techknow/ackbar/ackbar.mdl", "The t custom model");
 
        RegAdminCmd("sm_ackbar", Command_SetCustom, ADMFLAG_SLAY);

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
        GetConVarString(g_Cvarctackbar, g_ctackbar, sizeof(g_ctackbar));
        if (strcmp(g_ctackbar, ""))
	{
		PrecacheModel(g_ctackbar, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_ctackbar);
		AddFileToDownloadsTable(buffer);
	}
        GetConVarString(g_Cvartackbar, g_tackbar, sizeof(g_tackbar));
        if (strcmp(g_tackbar, ""))
	{
		PrecacheModel(g_tackbar, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_tackbar);
		AddFileToDownloadsTable(buffer);
	}
        //open precache file and add everything to download table
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/ackbar.ini")
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
        PrecacheModel(g_ctackbar, true);
        PrecacheModel(g_tackbar, true);
}

public Action:Command_SetCustom(client, args)
{
	if (args < 1)
        {
		ReplyToCommand(client, "[SM] Usage: sm_ackbar <1/0>");
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
                          SDKCall(hSetModel,(i),g_ctackbar);
                       }
                       else if (GetClientTeam(i) == 2)
                       {
                        // Make player Custom t model
                          SDKCall(hSetModel,(i),g_tackbar);
                       }
	       }
        }
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{       
        if (!GetConVarBool(g_Cvarackbar_on) && (custom == false))
	{
		return Plugin_Continue;
	}
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (GetClientTeam(client) == 3)
	{
        // Make player a CT custom model
           SDKCall(hSetModel,client,g_ctackbar);
        }
        else if (GetClientTeam(client) == 2)
        {
        // Make player a T custom model
            SDKCall(hSetModel,client,g_tackbar);
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