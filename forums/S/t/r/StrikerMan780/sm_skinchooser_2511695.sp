/*******************************************************************************

  SM Skinchooser

  Version: 4.7
  Author: Andi67
  
  Added new Cvar "sm_skinchooser_use_request_frame".
  Choose which method you want to use for setting the Armmodels in CSGO , 
  removing the weapons and equip them new or simply respawn the player.
  
  4.6 Error Message fixed?
  
  
  4.5 Really needed?
  
  Added fic for Armsmodels in CSGO.
  
  Updated to new Syntax.
  Added more Cvars for customization.
   
  Added CSGO Armmodels support. 
  Updated SteamId check for matching SteamId3.
  Plugin now uses mapbased cnnfigs.
   
  
  Added more Botchecks , some cosmetic. 
   
   
  Now you can force a skin to Admins automaticly. 
   
  
   
  Added possebility to restrict the sm_models/!models command by cvar. 
  Added Timer for Menu closing automaticly. 
  
   
  Changed some cvars from "enabled" to "disabled" by default , seams necessary since some people are not able to read the documentation , 
  also changed some code. 
   
  

  Added new Cvar "sm_skinchooser_forceplayerskin" , only works if "sm_skinchooser_playerspawntimer" is set to "1" !!!
  This is used to force players become a customskin on Spawn.
  Added autocreating configfile on first start.
  
 
  Update to 2.2
  Added Cvar for displaying Menu only for Admins
  Added Cvar for Mods like Resistance and Liberation where player_spawn is fired a little bit later so we add an one second timer
  to make sure Model is set on spawn.
  
  
  Update to 2.1:
  Added new Cvar sm_skinchooser_admingroup , brings back the old GroupSystem.
  Bahhhh amazing now you can use Flags and multiple Groups!!!
  
   
  Update to 2.0: 
  New cvar sm_skinchooser_SkinBots , forces Bots to have a skin.
  New cvar sm_skinchooser_displaytimer , makes it possible to display the menu a little bit
  later not directly by choosing a team.
  New cvar sm_skinchooser_menustarttime , here you can modify the time when Menu should be displayed by joining the team
  related to sm_skinchooser_displaytimer.
  
  
  Update to 1.9:
  Removed needing of Gamedata.txt , so from now Gamedata.txt is no more needed!!!  
   
   
  Update to 1.8:
  Fixed another Handlebug. 
   
    
  Update to 1.7: 
   
  Added new Cvar "sm_skinchooser_autodisplay"   
  
  
  Update to 1.6: 
   
  Supported now all Flags
   
  
  Update to 1.5:
  
  Fixed native Handle error
  

  Update to 1.4:
   
   Plugin now handles the following Flags:
   
   "" - for Public
   "b" - Generic Admins
   "g" - Mapchange Admins
   "t" - Custom Admins for use Reserved Skins
   "z" - Root Admins
    
   Now you only will see Sections/Groups in the Menu you have Access to 
    
    Rearranged skins.ini for better overview
   
   Fixed some Menubugs
  
  Added Gamedata for Hl2mp


  
	Everybody can edit this plugin and copy this plugin.
	
  Thanks to:
	Pred,Tigerox,Recon for making Modelmenu

	Swat_88 for making sm_downloader and precacher
	
	Paegus,Ghosty for helping me to bring up the Menu on Teamjoin
	
	And special THX to Feuersturm who helped me to fix the Spectatorbug!!!
	
  HAVE FUN!!!

*******************************************************************************/

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required
#define MAX_FILE_LEN 1024
#define MODELS_PER_TEAM 128

#define SM_SKINCHOOSER_VERSION		"4.7"


Handle g_version;
Handle g_enabled;
Handle g_steamid;
Handle g_arms_enabled;
Handle g_autodisplay;
Handle g_displaytimer;
Handle g_AdminGroup;
Handle g_AdminOnly;
Handle g_SkinBots;
Handle g_SkinAdmin;
Handle g_ForcePlayerSkin;
Handle g_CommandCountsEnabled;
Handle g_CloseMenuTimer;
Handle g_menustarttime;
Handle g_CommandCounts;
Handle g_mapbased;
Handle g_request_frame;

Handle playermodelskv;
Handle playermodelskva;
Handle kv;
Handle kva;
Handle mainmenu = INVALID_HANDLE;
Handle armsmainmenu = INVALID_HANDLE;


char g_ModelsAdminTeam2[MODELS_PER_TEAM][MAX_FILE_LEN];
char g_ModelsAdminTeam3[MODELS_PER_TEAM][MAX_FILE_LEN];
char g_ModelsAdmin_Count_Team2;
char g_ModelsAdmin_Count_Team3;
char g_ModelsPlayerTeam2[MODELS_PER_TEAM][MAX_FILE_LEN];
char g_ModelsPlayerTeam3[MODELS_PER_TEAM][MAX_FILE_LEN];
char g_ModelsPlayer_Count_Team2;
char g_ModelsPlayer_Count_Team3;
char g_ModelsBotsTeam2[MODELS_PER_TEAM][MAX_FILE_LEN];
char g_ModelsBotsTeam3[MODELS_PER_TEAM][MAX_FILE_LEN];
char g_ModelsBots_Count_Team2;
char g_ModelsBots_Count_Team3;

char authid[MAXPLAYERS+1][64];
char map[256];
char mediatype[256];
int downloadtype;

char g_CmdCount[MAXPLAYERS+1];
char Game[64];

char anarchistModelsT[][] = 
{
	"models/player/custom_player/legacy/tm_anarchist.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantA.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantB.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantC.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantD.mdl"
};

char balkanModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_balkan_variantA.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantB.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantC.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantD.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantE.mdl"
};

char leetModelsT[][] = 
{ 	
	"models/player/custom_player/legacy/tm_leet_variantA.mdl",
	"models/player/custom_player/legacy/tm_leet_variantB.mdl",
	"models/player/custom_player/legacy/tm_leet_variantC.mdl",
	"models/player/custom_player/legacy/tm_leet_variantD.mdl",
	"models/player/custom_player/legacy/tm_leet_variantE.mdl"
};

char phoenixModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_phoenix.mdl",
	"models/player/custom_player/legacy/tm_phoenix_heavy.mdl",	
	"models/player/custom_player/legacy/tm_phoenix_variantA.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantB.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantC.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantD.mdl"
};

char pirateModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_pirate.mdl",	
	"models/player/custom_player/legacy/tm_pirate_variantA.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantB.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantC.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantD.mdl"
};

char professionalModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_professional.mdl",	
	"models/player/custom_player/legacy/tm_professional_var1.mdl",
	"models/player/custom_player/legacy/tm_professional_var2.mdl",
	"models/player/custom_player/legacy/tm_professional_var3.mdl",
	"models/player/custom_player/legacy/tm_professional_var4.mdl"
};

char separatistModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_separatist.mdl",	
	"models/player/custom_player/legacy/tm_separatist_variantA.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantB.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantC.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantD.mdl"
};

char fbiModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_fbi.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantA.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantB.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantC.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantD.mdl"
};

char gignModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_gign.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantA.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantB.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantC.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantD.mdl"	
};

char gsg9ModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_gsg9.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantA.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantB.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantC.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantD.mdl"	
};

char idfModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_idf.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantA.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantB.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantC.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantD.mdl",	
	"models/player/custom_player/legacy/ctm_idf_variantE.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantF.mdl"	
};

char sasModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_sas.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantA.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantB.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantC.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantD.mdl",	
	"models/player/custom_player/legacy/ctm_sas_variantE.mdl"	
};

char st6ModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_st6.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantA.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantB.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantC.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantD.mdl"
};

char swatModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_swat.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantA.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantB.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantC.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantD.mdl"
};

public Plugin myinfo = 
{
	name = "SM SKINCHOOSER",
	author = "Andi67",
	description = "Skin Menu",
	version = SM_SKINCHOOSER_VERSION,
	url = "http://www.andi67-blog.de.vu"
}

public void OnPluginStart()
{
	g_version = CreateConVar("sm_skinchooser_version",SM_SKINCHOOSER_VERSION,"SM SKINCHOOSER VERSION",FCVAR_NOTIFY);
	SetConVarString(g_version,SM_SKINCHOOSER_VERSION);
	g_enabled = CreateConVar("sm_skinchooser_enabled", "1", "0 = Disabled , 1 = Enables the Plugin.", _, true, 0.0, true, 1.0);
	g_arms_enabled = CreateConVar("sm_skinchooser_arms_enabled","0", "0 = disabled , 1 = Enables the usage for Armmodels in CSGO.", _, true, 0.0, true, 1.0);
	g_steamid  = CreateConVar("sm_skinchooser_steamid_format","1", "0 = SteamId 2 , 1 = SteamId 3", _, true, 0.0, true, 1.0);
	g_mapbased = CreateConVar("sm_skinchooser_mapbased","1", "0 = Disabled , 1 = Enables usage of mapbased inis.", _, true, 0.0, true, 1.0);	
	g_autodisplay = CreateConVar("sm_skinchooser_autodisplay","1", "0 = Disabled , 1 = Enables Menu Auto popup.", _, true, 0.0, true, 1.0);
	g_displaytimer = CreateConVar("sm_skinchooser_displaytimer","0", "0 = Disabled , 1 = Enables the Delay when Menu should auto popup.", _, true, 0.0, true, 1.0);
	g_menustarttime = CreateConVar("sm_skinchooser_menustarttime" , "5.0", "Time in seconds when Menu should be started", _, true, 0.0, true, 1000.0);	
	g_AdminGroup = CreateConVar("sm_skinchooser_admingroup","1", "0 = Disabled , 1 = Enables the Groupsystem.", _, true, 0.0, true, 1.0);
	g_AdminOnly = CreateConVar("sm_skinchooser_adminonly","0", "0 = Disabled , 1 = Enabled for Admins only.", _, true, 0.0, true, 1.0);
	g_CommandCountsEnabled = CreateConVar("sm_skinchooser_commandcountsenabled", "0", "Enables the CommandCounter.", _, true, 0.0, true, 1.0);	
	g_CommandCounts = CreateConVar("sm_skinchooser_commandcounts", "1", "How many times users should be able to use the !models command.", _, true, 0.0, true, 1000.0);
	g_CloseMenuTimer = CreateConVar("sm_skinchooser_closemenutimer" , "30", "Seconds when the Menu should be closed", _, true, 0.0, true, 1000.0);	
	g_ForcePlayerSkin = CreateConVar("sm_skinchooser_forceplayerskin" , "0", "0 = Disabled , 1 = Enabled , should Players get automaticly a Model?", _, true, 0.0, true, 1.0);
	g_SkinBots = CreateConVar("sm_skinchooser_skinbots","0", "0 = Disabled , 1 = Enabled , should Bots have  a custom Model?", _, true, 0.0, true, 1.0);
	g_SkinAdmin = CreateConVar("sm_skinchooser_skinadmin","0", "0 = Disabled , 1 = Enabled , should Admins get automaticly a Model?", _, true, 0.0, true, 1.0);	
	g_request_frame = CreateConVar("sm_skinchooser_use_request_frame","0", "0 = Uses RemoveItem Timer(comes with a little delay when setting Armmodel) , 1 = Enabled , uses the RequestFrame function(No delay when setting Armmodel) and respawns the player.", _, true, 0.0, true, 1.0);		
	
	// Create the model menu command
	RegConsoleCmd("sm_models", Command_Model);
	
	GetGameFolderName(Game, sizeof(Game));
	
	// Hook the spawn event
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	if (StrEqual(Game, "dod"))	
	{
		HookEvent("dod_round_start", Event_RoundStart, EventHookMode_Post);
	}
	else
	{
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	}	
	
	AutoExecConfig(true, "sm_skinchooser");	
}

public void OnPluginEnd()
{
	CloseHandle(g_version);
	CloseHandle(g_enabled);
}

//public void OnMapStart()
public void OnConfigsExecuted()
{	
	if(GetConVarInt(g_enabled) == 1)	
	{			
		for (int i = 0; i < sizeof(fbiModelsCT); i++) 
		{
			if(fbiModelsCT[i][0] && !IsModelPrecached(fbiModelsCT[i]))
				PrecacheModel(fbiModelsCT[i]);
		}
		
		for (int i = 0; i < sizeof(gignModelsCT); i++) 
		{
			if(gignModelsCT[i][0] && !IsModelPrecached(gignModelsCT[i]))
				PrecacheModel(gignModelsCT[i]);
		}	
	
		for (int i = 0; i < sizeof(anarchistModelsT); i++) 
		{
			if(anarchistModelsT[i][0] && !IsModelPrecached(anarchistModelsT[i]))
				PrecacheModel(anarchistModelsT[i]);
		}	
		
		for (int i = 0; i < sizeof(phoenixModelsT); i++) 
		{
			if(phoenixModelsT[i][0] && !IsModelPrecached(phoenixModelsT[i]))
				PrecacheModel(phoenixModelsT[i]);
		}
	
		for (int i = 0; i < sizeof(pirateModelsT); i++) 
		{
			if(pirateModelsT[i][0] && !IsModelPrecached(pirateModelsT[i]))
				PrecacheModel(pirateModelsT[i]);
		}
		PrecacheModel("models/weapons/t_arms.mdl");
		PrecacheModel("models/weapons/ct_arms.mdl");		
			
		// Declare string to load skin's config from sourcemod/configs folder
		char file[PLATFORM_MAX_PATH];
		char files[PLATFORM_MAX_PATH];
		char filea[PLATFORM_MAX_PATH];
		char fileb[PLATFORM_MAX_PATH];
		char curmap[PLATFORM_MAX_PATH];
		GetCurrentMap(curmap, sizeof(curmap));
		
		if(GetConVarInt(g_mapbased) == 1)	
		{
			// Does current map string contains a "workshop" prefix at a start?
			if (strncmp(curmap, "workshop", 8) == 0)
			{
				// If yes - skip the first 19 characters to avoid comparing the "workshop/12345678" prefix
				BuildPath(Path_SM, file, sizeof(file), "configs/sm_skinchooser/%s_skins.ini", curmap[19]);			
				BuildPath(Path_SM, files, sizeof(files), "configs/sm_skinchooser/%s_skins_downloads.ini", curmap[19]);
			}
			else /* That's not a workshop map */
			{
				// Let's check that custom skin configuration file is exists for current map
				BuildPath(Path_SM, file, sizeof(file), "configs/sm_skinchooser/%s_skins.ini", curmap);
				BuildPath(Path_SM, files, sizeof(files), "configs/sm_skinchooser/%s_skins_downloads.ini", curmap);	
			}
	
			// Unfortunately config for current map is not exists
			if (!FileExists(file))
			{
			// Then use default one
				BuildPath(Path_SM, file, sizeof(file), "configs/sm_skinchooser/default_skins.ini");
			}
				
			if (!FileExists(files))
			{			
				BuildPath(Path_SM, files, sizeof(files), "configs/sm_skinchooser/default_skins_downloads.ini");
			}
			
			if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)
			{			
				if (strncmp(curmap, "workshop", 8) == 0)
				{			
					BuildPath(Path_SM, filea, sizeof(filea), "configs/sm_skinchooser/%s_arms.ini", curmap[19]);
					BuildPath(Path_SM, fileb, sizeof(fileb), "configs/sm_skinchooser/%s_arms_downloads.ini", curmap[19]);			
				}	
				else /* That's not a workshop map */
				{		
					BuildPath(Path_SM, filea, sizeof(filea), "configs/sm_skinchooser/%s_arms.ini", curmap);
					BuildPath(Path_SM, fileb, sizeof(fileb), "configs/sm_skinchooser/%s_arms_downloads.ini", curmap);		
				}
			
				if (!FileExists(filea))
				{
					BuildPath(Path_SM, filea, sizeof(filea), "configs/sm_skinchooser/default_arms.ini");
				}			
				if (!FileExists(fileb))
				{						
					BuildPath(Path_SM, fileb, sizeof(fileb), "configs/sm_skinchooser/default_arms_downloads.ini");
				}
			}
		}
		
		else if(GetConVarInt(g_mapbased) == 0)	
		{		
			BuildPath(Path_SM, file, sizeof(file), "configs/sm_skinchooser/default_skins.ini");	
			BuildPath(Path_SM, files, sizeof(files), "configs/sm_skinchooser/default_skins_downloads.ini");
			
			if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)
			{	
				BuildPath(Path_SM, filea, sizeof(filea), "configs/sm_skinchooser/default_arms.ini");
				BuildPath(Path_SM, fileb, sizeof(fileb), "configs/sm_skinchooser/default_arms_downloads.ini");
			}
		}
	
		LoadMapFile(file);	
		ReadDownloads(files);
		
		if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)
		{			
			LoadArmsMapFile(filea);	
			ReadArmsDownloads(fileb);
		}
		
		if(GetConVarInt(g_ForcePlayerSkin) == 1)	
		{			
			g_ModelsPlayer_Count_Team2 = 0;
			g_ModelsPlayer_Count_Team3 = 0;
			g_ModelsPlayer_Count_Team2 = LoadModels(g_ModelsPlayerTeam2, "configs/sm_skinchooser/forceskinsplayer_team2.ini");
			g_ModelsPlayer_Count_Team3  = LoadModels(g_ModelsPlayerTeam3,  "configs/sm_skinchooser/forceskinsplayer_team3.ini");		
		}
		if(GetConVarInt(g_SkinBots) == 1)	
		{	
			g_ModelsBots_Count_Team2 = 0;
			g_ModelsBots_Count_Team3 = 0;
			g_ModelsBots_Count_Team2 = LoadModels(g_ModelsBotsTeam2, "configs/sm_skinchooser/forceskinsbots_team2.ini");
			g_ModelsBots_Count_Team3  = LoadModels(g_ModelsBotsTeam3,  "configs/sm_skinchooser/forceskinsbots_team3.ini");				
		}
		if(GetConVarInt(g_SkinAdmin) == 1)	
		{		
			g_ModelsAdmin_Count_Team2 = 0;
			g_ModelsAdmin_Count_Team3 = 0;
			g_ModelsAdmin_Count_Team2 = LoadModels(g_ModelsAdminTeam2, "configs/sm_skinchooser/forceskinsadmin_team2.ini");
			g_ModelsAdmin_Count_Team3  = LoadModels(g_ModelsAdminTeam3,  "configs/sm_skinchooser/forceskinsadmin_team3.ini");			
		}
	}
	// Load Player last choosen Models
	char filex[PLATFORM_MAX_PATH];
	char filey[PLATFORM_MAX_PATH];
	char curmapa[PLATFORM_MAX_PATH];
	GetCurrentMap(curmapa, sizeof(curmapa));
	
	if(GetConVarInt(g_mapbased) == 1)	
	{		
		if (strncmp(curmapa, "workshop", 8) == 0)
		{
			BuildPath(Path_SM, filex, sizeof(filex), "data/%s_skinchooser_playermodels.ini", curmapa[19]);
			playermodelskv = CreateKeyValues("Models");
			FileToKeyValues(playermodelskv, filex);
		}
		else
		{
			BuildPath(Path_SM, filex, sizeof(filex), "data/%s_skinchooser_playermodels.ini", curmapa);	
			playermodelskv = CreateKeyValues("Models");
			FileToKeyValues(playermodelskv, filex);		
		}	
	
		// If Game is CSGO load the last choosen Armmodel
		if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)	
		{	
			if (strncmp(curmapa, "workshop", 8) == 0)
			{
				BuildPath(Path_SM, filey, sizeof(filey), "data/%s_skinchooser_armsmodels.ini", curmapa[19]);
				playermodelskva = CreateKeyValues("Arms");
				FileToKeyValues(playermodelskva, filey);
			}
			else
			{
				BuildPath(Path_SM, filey, sizeof(filey), "data/%s_skinchooser_armsmodels.ini", curmapa);	
				playermodelskva = CreateKeyValues("Arms");
				FileToKeyValues(playermodelskva, filey);		
			}
		}
	}
	else if(GetConVarInt(g_mapbased) == 0)	
	{
		BuildPath(Path_SM, filex, sizeof(filex), "data/skinchooser_playermodels.ini");	
		playermodelskv = CreateKeyValues("Models");
		FileToKeyValues(playermodelskv, filex);	
		
		if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)	
		{	
			BuildPath(Path_SM, filey, sizeof(filey), "data/skinchooser_armsmodels.ini");	
			playermodelskva = CreateKeyValues("Arms");
			FileToKeyValues(playermodelskva, filey);
		}
	}		
}

public void OnMapEnd()
{	
	// Write the last choosen Model
	char filea[PLATFORM_MAX_PATH];
	char fileb[PLATFORM_MAX_PATH];
	char curmap[PLATFORM_MAX_PATH];
	GetCurrentMap(curmap, sizeof(curmap));
	
	if(GetConVarInt(g_mapbased) == 1)	
	{	
		if (strncmp(curmap, "workshop", 8) == 0)
		{
			BuildPath(Path_SM, fileb, sizeof(fileb), "data/%s_skinchooser_playermodels.ini", curmap[19]);
			KeyValuesToFile(playermodelskv, fileb);
			CloseHandle(playermodelskv);
		}
		else
		{
			BuildPath(Path_SM, fileb, sizeof(fileb), "data/%s_skinchooser_playermodels.ini", curmap);	
			KeyValuesToFile(playermodelskv, fileb);
			CloseHandle(playermodelskv);
		}
		// Write the last choosen Arms if Game is CSGO
		if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)	
		{	
			if (strncmp(curmap, "workshop", 8) == 0)
			{
				BuildPath(Path_SM, filea, sizeof(filea), "data/%s_skinchooser_armsmodels.ini", curmap[19]);
				KeyValuesToFile(playermodelskva, filea);
				CloseHandle(playermodelskva);
			}
			else
			{
				BuildPath(Path_SM, filea, sizeof(filea), "data/%s_skinchooser_armsmodels.ini", curmap);	
				KeyValuesToFile(playermodelskva, filea);
				CloseHandle(playermodelskva);		
			}
		}
		CloseHandle(kv);
		CloseHandle(kva);
	}
	if(GetConVarInt(g_mapbased) == 0)	
	{	
		BuildPath(Path_SM, fileb, sizeof(fileb), "data/skinchooser_playermodels.ini");
		KeyValuesToFile(playermodelskv, fileb);
		CloseHandle(playermodelskv);
		
		if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)	
		{		
			BuildPath(Path_SM, filea, sizeof(filea), "data/skinchooser_armsmodels.ini");	
			KeyValuesToFile(playermodelskva, filea);
			CloseHandle(playermodelskva);	
		}
		CloseHandle(kv);
		CloseHandle(kva);
	}		
}

public int LoadModels(const char[][] models, char[] ini_file)
{
	char buffer[MAX_FILE_LEN];
	char file[MAX_FILE_LEN];
	int models_count;

	BuildPath(Path_SM, file, MAX_FILE_LEN, ini_file);

	//open precache file and add everything to download table
	Handle fileh = OpenFile(file, "r");
	while (ReadFileLine(fileh, buffer, MAX_FILE_LEN))
	{
		// Strip leading and trailing whitespace
		TrimString(buffer);
		
		// Skip comments
		if (buffer[0] != '/')
		{
		// Skip non existing files (and Comments)
			if (FileExists(buffer, true))
			{
				// Tell Clients to download files
				AddFileToDownloadsTable(buffer);
				// Tell Clients to cache model
				if (StrEqual(buffer[strlen(buffer)-4], ".mdl", false) && (models_count<MODELS_PER_TEAM))
				{
					strcopy(models[models_count++], strlen(buffer)+1, buffer);
					PrecacheModel(buffer, true);
				}
			}
		}
	}
	return models_count;
}

void LoadMapFile(const char[] file)
{	
	char path[100];	
	
	kv = CreateKeyValues("Commands");
	
	FileToKeyValues(kv, file);
	
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	do
	{
		KvJumpToKey(kv, "Team1");
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetString(kv, "path", path, sizeof(path),"");
			if (FileExists(path , true))
				PrecacheModel(path,true);
		} 
		while (KvGotoNextKey(kv));
		
		KvGoBack(kv);
		KvGoBack(kv);
		KvJumpToKey(kv, "Team2");
		KvGotoFirstSubKey(kv);
		do
		{
			KvGetString(kv, "path", path, sizeof(path),"");
			if (FileExists(path , true))
				PrecacheModel(path,true);
		}
		while (KvGotoNextKey(kv));
			
		KvGoBack(kv);
		KvGoBack(kv);	
	} 
	while (KvGotoNextKey(kv));	
		
	KvRewind(kv);
}

void LoadArmsMapFile(const char[] filea)
{	
	char arms[100];	
	
	kva = CreateKeyValues("Commands");
	
	FileToKeyValues(kva, filea);
	
	if (!KvGotoFirstSubKey(kva))
	{
		return;
	}
	do
	{
		KvJumpToKey(kva, "Team1");
		KvGotoFirstSubKey(kva);
		do
		{
			KvGetString(kva, "arms", arms, sizeof(arms),"");
			if (FileExists(arms , true))
				PrecacheModel(arms,true);
		} 
		while (KvGotoNextKey(kva));
		
		KvGoBack(kva);
		KvGoBack(kva);
		KvJumpToKey(kva, "Team2");
		KvGotoFirstSubKey(kva);
		do
		{
			KvGetString(kva, "arms", arms, sizeof(arms),"");
			if (FileExists(arms , true))
				PrecacheModel(arms,true);
		}
		while (KvGotoNextKey(kva));
			
		KvGoBack(kva);
		KvGoBack(kva);
			
	} 
	while (KvGotoNextKey(kva));	
		
	KvRewind(kva);
}

Handle BuildMainMenu(int client)
{
	/* Create the menu Handle */
	Handle menu = CreateMenu(Menu_Group);
	
	if (!KvGotoFirstSubKey(kv))
	{
		return INVALID_HANDLE;
	}
	
	char buffer[30];
	char accessFlag[5];
	AdminId admin = GetUserAdmin(client);

	{
		do
		{
			if(GetConVarInt(g_AdminGroup) == 1)
			{
				// check if they have access
				char group[30];
				char temp[2];
				KvGetString(kv,"Admin",group,sizeof(group));
				AdminId AdmId = GetUserAdmin(client);
				int count = GetAdminGroupCount(AdmId);
				for (int i =0; i<count; i++) 
				{
					if (FindAdmGroup(group) == GetAdminGroup(AdmId, i, temp, sizeof(temp)))
					{
						// Get the model group name and add it to the menu
						KvGetSectionName(kv, buffer, sizeof(buffer));		
						AddMenuItem(menu,buffer,buffer);
					}
				}
			}

			//Get accesFlag and see if the Admin is in it
			KvGetString(kv, "admin", accessFlag, sizeof(accessFlag));
			
			if(StrEqual(accessFlag,""))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"a") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Reservation, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}			
			
			if(StrEqual(accessFlag,"b") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Generic, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"c") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Kick, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"d") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Ban, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"e") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Unban, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"f") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Slay, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}			
			
			if(StrEqual(accessFlag,"g") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Changemap, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"h") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Convars, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"i") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Config, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"j") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Chat, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"k") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Vote, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"l") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Password, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"m") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_RCON, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"n") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Cheats, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"o") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom1, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"p") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom2, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"q") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom3, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"r") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom4, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"s") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom5, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}			
				
			if(StrEqual(accessFlag,"t") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom6, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
			if(StrEqual(accessFlag,"z") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Root, Access_Effective))
			{
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(menu,buffer,buffer);
			}
			
		} while (KvGotoNextKey(kv));	
	}
	KvRewind(kv);

	AddMenuItem(menu,"none","None");
	SetMenuTitle(menu, "Skins");
 
	return menu;
}

public void ReadFileFolder(char[] path )
{
	Handle dirh = INVALID_HANDLE;
	char buffer[256];
	char tmp_path[256];
	FileType type = FileType_Unknown;
	int len;
	
	len = strlen(path);
	if (path[len-1] == '\n')
		path[--len] = '\0';

	TrimString(path);
	
	if(DirExists(path))
	{
		dirh = OpenDirectory(path);
		while(ReadDirEntry(dirh,buffer,sizeof(buffer),type))
		{
			len = strlen(buffer);
			if (buffer[len-1] == '\n')
				buffer[--len] = '\0';

			TrimString(buffer);

			if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false))
			{
				strcopy(tmp_path,255,path);
				StrCat(tmp_path,255,"/");
				StrCat(tmp_path,255,buffer);
				if(type == FileType_File)
				{
					if(downloadtype == 1)
					{
						ReadItem(tmp_path);
					}
					
				
				}
			}
		}
	}
	else{
		if(downloadtype == 1)
		{
			ReadItem(path);
		}
		
	}
	if(dirh != INVALID_HANDLE)
	{
		CloseHandle(dirh);
	}
}

void ReadDownloads(const char[] files)
{
	Handle fileh = OpenFile(files, "r");
	char buffer[256];
	downloadtype = 1;
	int len;
	
	GetCurrentMap(map,255);
	
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{	
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';

		TrimString(buffer);

		if(!StrEqual(buffer,"",false))
		{
			ReadFileFolder(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE)
	{
		CloseHandle(fileh);
	}
}

void ReadArmsDownloads(const char[] fileb)
{
	Handle fileh = OpenFile(fileb, "r");
	char buffer[256];
	downloadtype = 1;
	int len;
	
	GetCurrentMap(map,255);
	
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{	
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';

		TrimString(buffer);

		if(!StrEqual(buffer,"",false))
		{
			ReadFileFolder(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE)
	{
		CloseHandle(fileh);
	}
}

public void ReadItem(char[] buffer)
{
	int len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	
	if(len >= 2 && buffer[0] == '/' && buffer[1] == '/')
	{
		if(StrContains(buffer,"//") >= 0)
		{
			ReplaceString(buffer,255,"//","");
		}
	}
	else if (!StrEqual(buffer,"",false) && FileExists(buffer, true))
	{
		if(StrContains(mediatype,"Model",true) >= 0)
		{
			PrecacheModel(buffer,true);
		}
		AddFileToDownloadsTable(buffer);
		}
	}

public int Menu_Group(Menu menu, MenuAction action, int param1, int param2)
{
	// User has selected a model group
	if (action == MenuAction_Select)
	{
		char info[30];
		
		// Get the group they selected
		bool found = GetMenuItem(menu, param2, info, sizeof(info));
		
		if (!found)
			return;
			
		//tigeox
		// Check to see if the user has decided they don't want a model
		// (e.g. go to a stock model)%%
		if(StrEqual(info,"none"))
		{
			// Get the player's authid			
			KvJumpToKey(playermodelskv,authid[param1],true);
		
			// Clear their saved model so that the next time
			// they spawn, they are able to use a stock model
			if (GetClientTeam(param1) == 2)
			{
				KvSetString(playermodelskv, "Team1", "");
				KvSetString(playermodelskv, "Team1Group", "");
			}
			else if (GetClientTeam(param1) == 3)
			{
				KvSetString(playermodelskv, "Team2", "");
				KvSetString(playermodelskv, "Team2Group", "");				
			}
			
			// Rewind the KVs
			KvRewind(playermodelskv);
			
			// We don't need to go any further, return
			return;
		}
			
		// User selected a group
		// advance kv to this group
		KvJumpToKey(kv, info);
		
		
		// Check users team		
		if (GetClientTeam(param1) == 2)
		{
			// Show team 1 models
			KvJumpToKey(kv, "Team1");
		}
		else if (GetClientTeam(param1) == 3)
		{
			// Show team 2 models
			KvJumpToKey(kv, "Team2");
		}
		else
		
			// They must be spectator, return
			return;
			
		
		// Get the first model		
		KvGotoFirstSubKey(kv);
		
		// Create the menu
		Handle tempmenu = CreateMenu(Menu_Model);

		// Add the models to the menu
		char buffer[30];
		char path[256];
		do
		{
			// Add the model to the menu
			KvGetSectionName(kv, buffer, sizeof(buffer));			
			KvGetString(kv, "path", path, sizeof(path),"");			
			AddMenuItem(tempmenu,path,buffer);
	
		} 
		while (KvGotoNextKey(kv));
		
		
		// Set the menu title to the model group name
		SetMenuTitle(tempmenu, info);
		
		// Rewind the KVs
		KvRewind(kv);
		
		// Display the menu
		DisplayMenu(tempmenu, param1, MENU_TIME_FOREVER);
	}
		else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int Menu_Model(Handle menu, MenuAction action, int param1, int param2)
{
	// User choose a model	
	if (action == MenuAction_Select)
	{
		char info[256];
		char group[30];

		// Get the model's menu item
		bool found = GetMenuItem(menu, param2, info, sizeof(info));

		
		if (!found)
			return;
			
		// Set the user's model
		if (!StrEqual(info,"") && IsModelPrecached(info) && IsClientConnected(param1))
		{
			// Set the model
			SetEntityModel(param1, info);
		}
					
		KvJumpToKey(playermodelskv,authid[param1],true);		
		
		// Save the user's choice so it is automatically applied
		// each time they spawn
		if (GetClientTeam(param1) == 2)
		{
			KvSetString(playermodelskv, "Team1", info);
			KvSetString(playermodelskv, "Team1Group", group);
		}
		else if (GetClientTeam(param1) == 3)
		{
			KvSetString(playermodelskv, "Team2", info);
			KvSetString(playermodelskv, "Team2Group", group);
		}
		
		// Rewind the KVs
		KvRewind(playermodelskv);
	}	
	
	// If Game is not CSGO, close the menu handle else display Armsmenu
	if(action == MenuAction_Select)
	{
		if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)
		{
			CreateTimer(0.1 , CommandSecMenu , param1);			
		}

		else
		{
			CloseHandle(menu);
		}
	}
}

public Action CommandSecMenu(Handle timer, any param1)
{
	armsmainmenu = BuildArmsMainMenu(param1);
	
	if (armsmainmenu == INVALID_HANDLE)
	{ 
		// We don't, send an error message and return
		PrintToConsole(param1, "There was an error generating the menu. Check your skins.ini file.");
		return Plugin_Handled;
	}
	
	DisplayMenu(armsmainmenu, param1, GetConVarInt(g_CloseMenuTimer));
	return Plugin_Handled;
}

Handle BuildArmsMainMenu(int param1)
{
			/* Create the menu Handle */
			Handle secmenu = CreateMenu(Menu_Arms_Group);
	
			if (!KvGotoFirstSubKey(kva))
			{
				return INVALID_HANDLE;
			}
	
			char buffer[30];
			char accessFlag[5];
			AdminId admin = GetUserAdmin(param1);

			{
				do
				{
					if(GetConVarInt(g_AdminGroup) == 1)
					{
						// check if they have access
						char group[30];
						char temp[2];
						KvGetString(kva,"Admin",group,sizeof(group));
						AdminId AdmId = GetUserAdmin(param1);
						int count = GetAdminGroupCount(AdmId);
						for (int i =0; i<count; i++) 
						{
							if (FindAdmGroup(group) == GetAdminGroup(AdmId, i, temp, sizeof(temp)))
							{
								// Get the model group name and add it to the menu
								KvGetSectionName(kva, buffer, sizeof(buffer));		
								AddMenuItem(secmenu,buffer,buffer);
							}
						}
					}

					//Get accesFlag and see if the Admin is in it
					KvGetString(kva, "admin", accessFlag, sizeof(accessFlag));
			
					if(StrEqual(accessFlag,""))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"a") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Reservation, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}			
			
					if(StrEqual(accessFlag,"b") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Generic, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"c") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Kick, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"d") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Ban, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"e") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Unban, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"f") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Slay, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}			
			
					if(StrEqual(accessFlag,"g") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Changemap, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"h") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Convars, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"i") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Config, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"j") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Chat, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"k") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Vote, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"l") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Password, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"m") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_RCON, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"n") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Cheats, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"o") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom1, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"p") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom2, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"q") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom3, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"r") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom4, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"s") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom5, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}			
				
					if(StrEqual(accessFlag,"t") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Custom6, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
					if(StrEqual(accessFlag,"z") && admin != INVALID_ADMIN_ID && GetAdminFlag(admin, Admin_Root, Access_Effective))
					{
						KvGetSectionName(kva, buffer, sizeof(buffer));
						AddMenuItem(secmenu,buffer,buffer);
					}
			
				} while (KvGotoNextKey(kva));	
			}
			KvRewind(kva);

			AddMenuItem(secmenu,"none","None");
			SetMenuTitle(secmenu, "Arms");
 
			return secmenu;	
}

public int Menu_Arms_Group(Menu secmenu, MenuAction action,int param1, int param2)
{
	// User has selected a model group
	if (action == MenuAction_Select)
	{
		char info[30];
		
		// Get the group they selected
		bool found = GetMenuItem(secmenu, param2, info, sizeof(info));
		
		if (!found)
			return;
			
		//tigeox
		// Check to see if the user has decided they don't want a model
		// (e.g. go to a stock model)%%
		if(StrEqual(info,"none"))
		{
			// Get the player's authid			
			KvJumpToKey(playermodelskva,authid[param1],true);
		
			// Clear their saved model so that the next time
			// they spawn, they are able to use a stock model
			if (GetClientTeam(param1) == 2)
			{
				KvSetString(playermodelskva, "Team1", "");
				KvSetString(playermodelskva, "Team1Group", "");
			}
			else if (GetClientTeam(param1) == 3)
			{
				KvSetString(playermodelskva, "Team2", "");
				KvSetString(playermodelskva, "Team2Group", "");				
			}
			
			// Rewind the KVs
			KvRewind(playermodelskva);
			
			// We don't need to go any further, return
			return;
		}
			
		// User selected a group
		// advance kv to this group
		KvJumpToKey(kva, info);
		
		
		// Check users team		
		if (GetClientTeam(param1) == 2)
		{
			// Show team 1 models
			KvJumpToKey(kva, "Team1");
		}
		else if (GetClientTeam(param1) == 3)
		{
			// Show team 2 models
			KvJumpToKey(kva, "Team2");
		}
		else
		
			// They must be spectator, return
			return;
			
		
		// Get the first model		
		KvGotoFirstSubKey(kva);
		
		// Create the menu
		Menu atempmenu = CreateMenu(Menu_Arms);

		// Add the models to the menu
		char buffer[30];
		char arms[256];
		do
		{
			// Add the model to the menu
			KvGetSectionName(kva, buffer, sizeof(buffer));			
			KvGetString(kva, "arms", arms, sizeof(arms),"");			
			AddMenuItem(atempmenu,arms,buffer);
	
		} 
		while (KvGotoNextKey(kva));
		
		
		// Set the menu title to the model group name
		SetMenuTitle(atempmenu, info);
		
		// Rewind the KVs
		KvRewind(kva);
		
		// Display the menu
		DisplayMenu(atempmenu, param1, MENU_TIME_FOREVER);
	}
		else if (action == MenuAction_End)
	{
		CloseHandle(secmenu);
	}
}

public int Menu_Arms(Menu amenu, MenuAction action, int param1,int param2)
{
	// User choose a model	
	if (action == MenuAction_Select)
	{
		char info[256];
		char group[30];

		// Get the model's menu item
		bool found = GetMenuItem(amenu, param2, info, sizeof(info));

		
		if (!found)
			return;
			
		// Set the user's model
		if (!StrEqual(info,"") && IsModelPrecached(info) && IsClientConnected(param1))
		{
			if(IsPlayerAlive(param1)) 	
			{
				// Set the model
				SetEntPropString(param1, Prop_Send, "m_szArmsModel", info);
				if(GetConVarInt(g_request_frame) == 1)	
				{				
					RequestFrame(Respawn, param1);
				}
				if(GetConVarInt(g_request_frame) == 0)	
				{
					CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(param1), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		
		// Get the player's steam		
		KvJumpToKey(playermodelskva,authid[param1], true);		
		
		// Save the user's choice so it is automatically applied
		// each time they spawn
		if (GetClientTeam(param1) == 2)
		{
			KvSetString(playermodelskva, "Team1", info);
			KvSetString(playermodelskva, "Team1Group", group);
		}
		else if (GetClientTeam(param1) == 3)
		{
			KvSetString(playermodelskva, "Team2", info);
			KvSetString(playermodelskva, "Team2Group", group);
		}
		
		// Rewind the KVs
		KvRewind(playermodelskva);
	}
	
	// If they picked exit, close the menu handle
	if (action == MenuAction_End)
	{
		CloseHandle(amenu);
	}
}

public void OnClientPostAdminCheck(int client)
{	
	if(GetConVarInt(g_steamid) == 0)	
	{	
		GetClientAuthId(client,AuthId_Steam2, authid[client], sizeof(authid[]));
	}
	else if(GetConVarInt(g_steamid) == 1)	
	{	
		GetClientAuthId(client,AuthId_Steam3, authid[client], sizeof(authid[]));
	}	
		
	if(GetConVarInt(g_CommandCountsEnabled) == 1)	
	{	
		g_CmdCount[client] = 0;
	}
}

public Action Timer_Menu(Handle timer, any client)
{
	if(GetClientTeam(client) == 2 || GetClientTeam(client) == 3 && IsValidClient(client))
	{
		Command_Model(client, 0);
	}
	
	mainmenu = BuildMainMenu(client);
	
	if (mainmenu == INVALID_HANDLE)
	{ 
		// We don't, send an error message and return
		PrintToConsole(client, "There was an error generating the menu. Check your skins.ini file.");
		return Plugin_Handled;
	}
	
	DisplayMenu(mainmenu, client, GetConVarInt(g_CloseMenuTimer));
	PrintToChat(client, "Skinmenu is open , choose your Model!!!");
	return Plugin_Handled;
}

public Action Command_Model(int client,int args)
{
	if(GetConVarInt(g_enabled) == 1)
	{
		if(GetConVarInt(g_CommandCountsEnabled) == 1)	
		{
			g_CmdCount[client]++;	
			int curCount = g_CmdCount[client];
		
			if(curCount <= GetConVarInt(g_CommandCounts))
			{
				//Create the main menu
				mainmenu = BuildMainMenu(client);
			
				// Do we have a valid model menu
				if (mainmenu == INVALID_HANDLE)
				{ 
					// We don't, send an error message and return
					PrintToConsole(client, "There was an error generating the menu. Check your skins.ini file.");
					return Plugin_Handled;
				}
		
				AdminId admin = GetUserAdmin(client);
		
				if (GetConVarInt(g_AdminOnly) == 1 && admin != INVALID_ADMIN_ID)
				{
					// We have a valid menu, display it and return
					DisplayMenu(mainmenu, client, GetConVarInt(g_CloseMenuTimer));
				}
				else if(GetConVarInt(g_AdminOnly) == 0)
				{
					DisplayMenu(mainmenu, client, GetConVarInt(g_CloseMenuTimer));
				}
			}
		}
		else if(GetConVarInt(g_CommandCountsEnabled) == 0)
		{
			//Create the main menu
			mainmenu = BuildMainMenu(client);
	
			// Do we have a valid model menu
			if (mainmenu == INVALID_HANDLE)
			{ 
				// We don't, send an error message and return
				PrintToConsole(client, "There was an error generating the menu. Check your skins.ini file.");
				return Plugin_Handled;
			}
	
			AdminId admin = GetUserAdmin(client);
		
			if (GetConVarInt(g_AdminOnly) == 1 && admin != INVALID_ADMIN_ID)
			{
				// We have a valid menu, display it and return
				DisplayMenu(mainmenu, client, GetConVarInt(g_CloseMenuTimer));
			}
			else if(GetConVarInt(g_AdminOnly) == 0)
			{
				DisplayMenu(mainmenu, client, GetConVarInt(g_CloseMenuTimer));
			}
		}	
	}
	return Plugin_Handled;	
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{	
		g_CmdCount[i] = 0;
	}
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_enabled) == 1)	
	{	
		if( GetConVarBool(g_autodisplay) )
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));
			int team = GetEventInt(event, "team");
			if( GetConVarBool(g_displaytimer))
			{
				if((team == 2 || team == 3) && IsValidClient(client) && !IsFakeClient(client))
				{
					CreateTimer(GetConVarFloat(g_menustarttime), Timer_Menu, client);
				}
			}
		
			else if((team == 2 || team == 3) && IsValidClient(client) && !IsFakeClient(client))
			{
				Command_Model(client, 0);
			}
			return;
		}
	}
}

public Action Event_PlayerSpawn(Handle event,  const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_enabled) == 1)	
	{	
		// Get the userid and client
		int client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)
		{				
			
			SetDefaultModels(client);
			// Get the user's authid				
			KvJumpToKey(playermodelskva,authid[client],true);
	
			char arms[256];
			char groups[30];	
	
			// Get the user's model pref
			if (!IsFakeClient(client) && IsValidClient(client) && GetClientTeam(client) == 2)
			{
				KvGetString(playermodelskva, "Team1", arms, sizeof(arms), "");
				KvGetString(playermodelskva, "Team1Group", groups, sizeof(groups), "");
			}
			else if (!IsFakeClient(client) && IsValidClient(client) && GetClientTeam(client) == 3)
			{
				KvGetString(playermodelskva, "Team2", arms, sizeof(arms), "");
				KvGetString(playermodelskva, "Team2Group", groups, sizeof(groups), "");
			}		
	
			// Make sure that they have a valid model pref
			if (!StrEqual(arms,"", false) && IsModelPrecached(arms))
			{
				// Set the Armsmodel
				SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
			}
			if (!StrEqual(arms,"") && IsModelPrecached(arms))
			{
				SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
			}
	
			// Rewind the KVs
			KvRewind(playermodelskva);
		}
	
		if (StrEqual(Game, "csgo") && GetConVarInt(g_arms_enabled) == 1)
		{
			if (!IsFakeClient(client) && IsValidClient(client))
			{			
  				CreateTimer(1.5, PlayerModel, client);
  			}
  		}
  		else
  		{
			if (!IsFakeClient(client) && IsValidClient(client))
			{  			
  				CreateTimer(0.5, Timer_Spawn, client);
  			}
  		}
  		
		if(IsFakeClient(client) && GetConVarInt(g_SkinBots) == 1)
		{
			skin_bots(client);
		}
		
		if (!IsFakeClient(client) && IsValidClient(client) && GetConVarInt(g_SkinAdmin) == 1)	
		{
			AdminId admin = GetUserAdmin(client);
			if(admin != INVALID_ADMIN_ID )	
			{			
				CreateTimer(2.0, skin_admin, client);				
			}
		}
		
		if (!IsFakeClient(client) && IsValidClient(client) && GetConVarInt(g_ForcePlayerSkin) == 1)		
		{		
			AdminId admin = GetUserAdmin(client);		
			if(admin == INVALID_ADMIN_ID)	
			{
				CreateTimer(2.0, skin_players, client);	
			}
		}			
  	}
}

public Action PlayerModel(Handle timer ,any client)
{
	// Get the user's authid			
	KvJumpToKey(playermodelskv,authid[client],true);
	
	char model[256];
	char group[30];	
	
	// Get the user's model pref
	if (!IsFakeClient(client) && IsValidClient(client) && GetClientTeam(client) == 2)
	{
		KvGetString(playermodelskv, "Team1", model, sizeof(model), "");
		KvGetString(playermodelskv, "Team1Group", group, sizeof(group), "");
	}
	else if (!IsFakeClient(client) && IsValidClient(client) && GetClientTeam(client) == 3)
	{
		KvGetString(playermodelskv, "Team2", model, sizeof(model), "");
		KvGetString(playermodelskv, "Team2Group", group, sizeof(group), "");
	}		
	
	// Make sure that they have a valid model pref
	if (!StrEqual(model,"", false) && IsModelPrecached(model))
	{
		// Set the model
		SetEntityModel(client, model);
	}
	if (!StrEqual(model,"") && IsModelPrecached(model))
	{
		SetEntityModel(client, model);
	}
	
	// Rewind the KVs
	KvRewind(playermodelskv);	
}

public Action Timer_Spawn(Handle timer, any client)
{
	// Get the user's authid	
	KvJumpToKey(playermodelskv,authid[client],true);
	
	char model[256];
	char group[30];	
	
	// Get the user's model pref
	if (!IsFakeClient(client) && IsValidClient(client) && GetClientTeam(client) == 2)
	{
		KvGetString(playermodelskv, "Team1", model, sizeof(model), "");
		KvGetString(playermodelskv, "Team1Group", group, sizeof(group), "");
	}
	else if (!IsFakeClient(client) && IsValidClient(client) && GetClientTeam(client) == 3)
	{
		KvGetString(playermodelskv, "Team2", model, sizeof(model), "");
		KvGetString(playermodelskv, "Team2Group", group, sizeof(group), "");
	}		
	
	// Make sure that they have a valid model pref
	if (!StrEqual(model,"", false) && IsModelPrecached(model))
	{
		// Set the model
		SetEntityModel(client, model);
	}
	if (!StrEqual(model,"") && IsModelPrecached(model))
	{
		SetEntityModel(client, model);
	}
	
	// Rewind the KVs
	KvRewind(playermodelskv);
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

void skin_bots(int client)
{
	int team = GetClientTeam(client);
	if (team==2)
	{
		SetEntityModel(client,g_ModelsBotsTeam2[GetRandomInt(0, g_ModelsBots_Count_Team2-1)]);
	}
	else if (team==3)
	{
		SetEntityModel(client,g_ModelsBotsTeam3[GetRandomInt(0, g_ModelsBots_Count_Team3-1)]);
	}
}

public Action skin_players(Handle timer, any client)
{
	int team = GetClientTeam(client);
	if (team==2)
	{
		SetEntityModel(client,g_ModelsPlayerTeam2[GetRandomInt(0, g_ModelsPlayer_Count_Team2-1)]);	
	}
	else if (team==3)
	{
		SetEntityModel(client,g_ModelsPlayerTeam3[GetRandomInt(0, g_ModelsPlayer_Count_Team3-1)]);		
	}
}

public Action skin_admin(Handle timer, any client)
{
	int team = GetClientTeam(client);
	if (team==2)
	{
		SetEntityModel(client,g_ModelsAdminTeam2[GetRandomInt(0, g_ModelsAdmin_Count_Team2-1)]);		
	}
	else if (team==3)
	{
		SetEntityModel(client,g_ModelsAdminTeam3[GetRandomInt(0, g_ModelsAdmin_Count_Team3-1)]);		
	}
}

stock void SetDefaultModels(int client) 
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{			
		int team = GetClientTeam(client);		

		if (team == 2) 
		{			
			char sModelT[128];
 			GetEntPropString(client, Prop_Data, "m_ModelName", sModelT, sizeof(sModelT));
			
			for (int a = 0; a < sizeof(anarchistModelsT); a++) 
			{
    			if (StrEqual(anarchistModelsT[a], sModelT))
    			{
   			 		SetEntityModel(client,pirateModelsT[GetRandomInt(0 , -1)]);	
  				}  					
			} 
			for (int b = 0; b < sizeof(phoenixModelsT); b++) 
			{
    			if (StrEqual(phoenixModelsT[b], sModelT))
    			{
   			 		SetEntityModel(client,pirateModelsT[GetRandomInt(0 , -1)]);	
  				}  					
			} 
			for (int c = 0; c < sizeof(balkanModelsT); c++) 
			{
    			if (StrEqual(balkanModelsT[c], sModelT))
    			{
   			 		SetEntityModel(client,anarchistModelsT[GetRandomInt(0 , -1)]);	
  				}  					
			}	
			for (int d = 0; d < sizeof(leetModelsT); d++) 
			{
    			if (StrEqual(leetModelsT[d], sModelT))
    			{
   			 		SetEntityModel(client,anarchistModelsT[GetRandomInt(0 , -1)]);	
  				}  					
			}
			for (int e = 0; e < sizeof(pirateModelsT); e++) 
			{
    			if (StrEqual(pirateModelsT[e], sModelT))
    			{
   			 		SetEntityModel(client,anarchistModelsT[GetRandomInt(0 , -1)]);	
  				}  					
			}	
			for (int f = 0; f < sizeof(professionalModelsT); f++) 
			{
    			if (StrEqual(professionalModelsT[f], sModelT))
    			{
   			 		SetEntityModel(client,anarchistModelsT[GetRandomInt(0 , -1)]);	
  				}  					
			}
			for (int h = 0; h < sizeof(separatistModelsT); h++) 
			{
    			if (StrEqual(separatistModelsT[h], sModelT))
    			{
   			 		SetEntityModel(client,anarchistModelsT[GetRandomInt(0 , -1)]);	
  				}  					
			}	
			SetEntPropString(client, Prop_Send, "m_szArmsModel","models/weapons/t_arms.mdl");			
		} 
		else if (team == 3) 
		{			
			char sModelCT[128];
 			GetEntPropString(client, Prop_Data, "m_ModelName", sModelCT, sizeof(sModelCT));

			for (int i = 0; i < sizeof(fbiModelsCT); i++) 
			{
    			if (StrEqual(fbiModelsCT[i], sModelCT))
    			{
   			 		SetEntityModel(client,gignModelsCT[GetRandomInt(0 , -1)]);				
				}
			}		
			for (int j = 0; j < sizeof(gsg9ModelsCT); j++) 
			{			
    			if (StrEqual(gsg9ModelsCT[j], sModelCT))
    			{
					SetEntityModel(client,fbiModelsCT[GetRandomInt(0 , -1)]);								
				}
			}	
			for (int k = 0; k < sizeof(gignModelsCT); k++) 
			{
    			if (StrEqual(gignModelsCT[k], sModelCT))
    			{
   			 		SetEntityModel(client,fbiModelsCT[GetRandomInt(0 , -1)]);				
				}
			}
			for (int l = 0; l < sizeof(idfModelsCT); l++) 
			{
    			if (StrEqual(idfModelsCT[l], sModelCT))
    			{
   			 		SetEntityModel(client,fbiModelsCT[GetRandomInt(0 , -1)]);				
				}
			}
			for (int m = 0; m < sizeof(sasModelsCT); m++) 
			{
    			if (StrEqual(sasModelsCT[m], sModelCT))
    			{
   			 		SetEntityModel(client,gignModelsCT[GetRandomInt(0 , -1)]);				
				}
			}	
			for (int n = 0; n < sizeof(st6ModelsCT); n++) 
			{
    			if (StrEqual(st6ModelsCT[n], sModelCT))
    			{
   			 		SetEntityModel(client,fbiModelsCT[GetRandomInt(0 , -1)]);				
				}
			}	
			for (int o = 0; o < sizeof(swatModelsCT); o++) 
			{
    			if (StrEqual(swatModelsCT[o], sModelCT))
    			{
   			 		SetEntityModel(client,gignModelsCT[GetRandomInt(0 , -1)]);			
				}
			}
			SetEntPropString(client, Prop_Send, "m_szArmsModel","models/weapons/ct_arms.mdl");			
		} 
	}
}	

public void Respawn(any param1)
{
	CS_RespawnPlayer(param1);
}

// Timers for updating the viewmodel arms
public Action RemoveItemTimer(Handle timer ,any ref)
{
	int client = EntRefToEntIndex(ref);
	
	if (client != INVALID_ENT_REFERENCE)
	{
		int item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (item > 0)
		{
			RemovePlayerItem(client, item);
			
			Handle ph=CreateDataPack();
			WritePackCell(ph, EntIndexToEntRef(client));
			WritePackCell(ph, EntIndexToEntRef(item));
			CreateTimer(0.15 , AddItemTimer, ph, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action AddItemTimer(Handle timer ,any ph)
{  
	int client, item;
	
	ResetPack(ph);
	
	client = EntRefToEntIndex(ReadPackCell(ph));
	item = EntRefToEntIndex(ReadPackCell(ph));
	
	if (client != INVALID_ENT_REFERENCE && item != INVALID_ENT_REFERENCE)
	{
		EquipPlayerWeapon(client, item);
	}
}