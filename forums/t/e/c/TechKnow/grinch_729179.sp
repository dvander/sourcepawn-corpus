/* sm_grinch.sp

Description: grinch Theme model changer

Versions: 2.0

Changelog:

1.0 - Initial Release
2.0 - Repaired to work with july 2010 css big update, No longer need the gamedata/custom.games.txt

- sm_grinch <1|0>


*/

#include <sourcemod>
#include <sdktools>

//#pragma semicolon 1

#define PLUGIN_VERSION "2.0"
#define MAX_FILE_LEN 256


// Plugin definitions
public Plugin:myinfo = 
{
	name = "sm_grinch",
	author = "TechKnow",
        version = "2.0",
	description = "grinch Theme model changer", version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=82151"
};

new Handle:g_Cvargrinch_on = INVALID_HANDLE;
new Handle:g_Cvarctgrinch = INVALID_HANDLE;
new Handle:g_Cvartgrinch = INVALID_HANDLE;
new String:g_ctgrinch[MAX_FILE_LEN];
new String:g_tgrinch[MAX_FILE_LEN];
new onoff;
new bool:custom = true;


public OnPluginStart()
{
	CreateConVar("sm_grinch_version", PLUGIN_VERSION, "grinch Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        g_Cvargrinch_on = CreateConVar("sm_grinch_on", "1", "Set to 1 to enable custom models");

        g_Cvarctgrinch = CreateConVar("sm_ctgrinch_model", "models/player/techknow/grinch_css/grinch-b.mdl", "The ct custom model");

        g_Cvartgrinch = CreateConVar("sm_tgrinch_model", "models/player/techknow/grinch_css/grinch-r.mdl", "The t custom model");
 
        RegAdminCmd("sm_grinch", Command_SetCustom, ADMFLAG_SLAY);

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public OnMapStart()
{
	decl String:buffer[MAX_FILE_LEN];
        GetConVarString(g_Cvarctgrinch, g_ctgrinch, sizeof(g_ctgrinch));
        if (strcmp(g_ctgrinch, ""))
	{
		PrecacheModel(g_ctgrinch, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_ctgrinch);
		AddFileToDownloadsTable(buffer);
	}
        GetConVarString(g_Cvartgrinch, g_tgrinch, sizeof(g_tgrinch));
        if (strcmp(g_tgrinch, ""))
	{
		PrecacheModel(g_tgrinch, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_tgrinch);
		AddFileToDownloadsTable(buffer);
	}
        //open precache file and add everything to download table
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/grinch.ini")
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
        PrecacheModel(g_ctgrinch, true);
        PrecacheModel(g_tgrinch, true);
}

public Action:Command_SetCustom(client, args)
{
	if (args < 1)
        {
		ReplyToCommand(client, "[SM] Usage: sm_grinch <1/0>");
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
                       PrintToChat((i),"[SM] Your Grinch model has been removed"); 
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
                       PrintToChat((i),"[SM] You have been given a Grinch model"); 
                       if (GetClientTeam(i) == 3)
	               {
                        // Make player a Custom ct model 
                          SetEntityModel((i),g_ctgrinch);
                       }
                       else if (GetClientTeam(i) == 2)
                       {
                        // Make player Custom t model
                          SetEntityModel((i),g_tgrinch);
                       }
	       }
        }
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{       
        if (!GetConVarBool(g_Cvargrinch_on) && (custom == false))
	{
		return Plugin_Continue;
	}
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (GetClientTeam(client) == 3)
	{
        // Make player a CT custom model
           SetEntityModel(client,g_ctgrinch);
        }
        else if (GetClientTeam(client) == 2)
        {
        // Make player a T custom model
            SetEntityModel(client,g_tgrinch);
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