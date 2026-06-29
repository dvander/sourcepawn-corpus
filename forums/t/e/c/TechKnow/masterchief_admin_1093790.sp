/* sm_masterchief.sp

Description: masterchief vs masterchief Theme model changer

Versions: 1.0

Changelog:

1.0 - Initial Release

- sm_masterchief <1|0>


*/

#include <sourcemod>
#include <sdktools>

//#pragma semicolon 1

#define PLUGIN_VERSION "1.0a"
#define MAX_FILE_LEN 256


// Plugin definitions
public Plugin:myinfo = 
{
	name = "sm_masterchief",
	author = "TechKnow",
        version = "1.0a",
	description = "masterchief Theme model changer", version = PLUGIN_VERSION,
	url = "http://sourcemodplugin.14.forumer.com"
};

new Handle:g_Cvarctmasterchief = INVALID_HANDLE;
new Handle:g_Cvartmasterchief = INVALID_HANDLE;
new String:g_ctmasterchief[MAX_FILE_LEN];
new String:g_tmasterchief[MAX_FILE_LEN];
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hSetModel;


public OnPluginStart()
{
	CreateConVar("sm_masterchief_version", PLUGIN_VERSION, "masterchief Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        g_Cvarctmasterchief = CreateConVar("sm_ctmasterchief_model", "models/player/techknow/masterchief/blue_mc.mdl", "The ct custom model");

        g_Cvartmasterchief = CreateConVar("sm_tmasterchief_model", "models/player/techknow/masterchief/red_mc.mdl", "The t custom model");
 

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
        GetConVarString(g_Cvarctmasterchief, g_ctmasterchief, sizeof(g_ctmasterchief));
        if (strcmp(g_ctmasterchief, ""))
	{
		PrecacheModel(g_ctmasterchief, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_ctmasterchief);
		AddFileToDownloadsTable(buffer);
	}
        GetConVarString(g_Cvartmasterchief, g_tmasterchief, sizeof(g_tmasterchief));
        if (strcmp(g_tmasterchief, ""))
	{
		PrecacheModel(g_tmasterchief, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_tmasterchief);
		AddFileToDownloadsTable(buffer);
	}
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

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{    
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
        // See if spawnd player is an admin
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID)
	{   
            // see if admin is a CT
            if (GetClientTeam(client) == 3)
	    {
            // Make player a CT custom model
               SDKCall(hSetModel,client,g_ctmasterchief);
            }
            // if not a CT Admin is a T
            else if (GetClientTeam(client) == 2)
            {
            // Make player a T custom model
                SDKCall(hSetModel,client,g_tmasterchief);
            }
        }
}