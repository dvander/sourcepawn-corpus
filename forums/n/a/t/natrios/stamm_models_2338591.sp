/**
 * -----------------------------------------------------
 * File        stamm_models.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2014 David <popoklopsi> Ordnung
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */


// Includes
#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>


#pragma semicolon 1




#define MODELPATH 0
#define MODELNAME 1
#define MODELTEAM 2
#define MODELLEVEL 3




new PlayerHasModel[MAXPLAYERS + 1];
new LastTeam[MAXPLAYERS + 1];
new modelCount;
new model_change;
new same_models;
new admin_model;

new String:PlayerModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH + 1];
new String:models[64][4][PLATFORM_MAX_PATH + 1];
new String:model_change_cmd[32];

new Handle:g_hModelChangeCmd;
new Handle:g_hModelChange;
new Handle:g_hSameModels;
new Handle:g_hAdminModel;

new bool:Loaded;



public Plugin:myinfo =
{
	name = "Stamm Feature Vip Models",
	author = "Popoklopsi",
	version = "1.3.2",
	description = "Give VIP's VIP Models",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add the feature
public OnAllPluginsLoaded()
{
	if (!STAMM_IsAvailable()) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_RegisterFeature("VIP Models");
}




// Feature loaded, parse models
public STAMM_OnFeatureLoaded(const String:basename[])
{
	decl String:urlString[256];

	new Handle:model_settings;


	// Auto updater
	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

		Updater_AddPlugin(urlString);
		Updater_ForceUpdate();
	}



	// Load Models configs
	if (!FileExists("cfg/stamm/features/ModelSettings.txt"))
	{
		SetFailState("Couldn't load Stamm Models. ModelSettings.txt missing.");
	}
	
	// To Keyvalues
	model_settings = CreateKeyValues("ModelSettings");


	FileToKeyValues(model_settings, "cfg/stamm/features/ModelSettings.txt");



	// Key value loop
	if (KvGotoFirstSubKey(model_settings))
	{
		do
		{
			// Get Settings for each model
			KvGetString(model_settings, "team", models[modelCount][MODELTEAM], sizeof(models[][]));
			KvGetString(model_settings, "model", models[modelCount][MODELPATH], sizeof(models[][]));

			if (!StrEqual(models[modelCount][MODELPATH], "") && !StrEqual(models[modelCount][MODELPATH], "0"))
			{
				PrecacheModel(models[modelCount][MODELPATH]);
			}

			KvGetString(model_settings, "name", models[modelCount][MODELNAME], sizeof(models[][]));
			KvGetString(model_settings, "level", models[modelCount][MODELLEVEL], sizeof(models[][]), "none");


			// Backwarts compatiblity
			if (StrEqual(models[modelCount][MODELLEVEL], "none"))
			{
				// Notice new location
				STAMM_WriteToLog(false, "ATTENTION: Level Config is now in ModelSettings.txt under the key \"level\"!");

				// Found nothing
				if (STAMM_GetBlockLevel() == 0)
				{
					STAMM_WriteToLog(false, "ATTENTION: Found no level for model %s. Zero assumed!!", models[modelCount][MODELNAME]);
				}


				Format(models[modelCount][MODELLEVEL], sizeof(models[][]), "%i", STAMM_GetBlockLevel());
			}

			else
			{
				// Get the level
				new levelNumber = STAMM_GetLevelNumber(models[modelCount][MODELLEVEL]);

				// Given as int
				if (levelNumber != 0)
				{
					Format(models[modelCount][MODELLEVEL], sizeof(models[][]), "%i", levelNumber);
				}

				// Else we need model name
				else if (StringToInt(models[modelCount][MODELLEVEL]) == 0)
				{
					STAMM_WriteToLog(false, "ATTENTION: Found incorrect level for model %s. One assumed!!", models[modelCount][MODELNAME]);
					Format(models[modelCount][MODELLEVEL], sizeof(models[][]), "1");
				}
			}

			// One model more
			modelCount++;
		}
		while (KvGotoNextKey(model_settings));
	}
	

	CloseHandle(model_settings);
}




// Add descriptions
public STAMM_OnClientRequestFeatureInfo(client, block, &Handle:array)
{
	decl String:fmt[256];
	new bool:found = false;
	
	for (new item = 0; item < modelCount; item++)
	{
		// Right team and right level?
		if (GetClientTeam(client) == StringToInt(models[item][MODELTEAM]) && STAMM_GetClientLevel(client) >= StringToInt(models[item][MODELLEVEL]))
		{
			if (!StrEqual(models[item][MODELPATH], "") && !StrEqual(models[item][MODELPATH], "0"))
			{
				found = true;
				
				break;
			}
		}
	}
	
	
	if (found)
	{
		if (model_change && same_models)
		{
			Format(fmt, sizeof(fmt), "%T", "GetModelChange", client, model_change_cmd);
		}
		else 
		{
			Format(fmt, sizeof(fmt), "%T", "GetModel", client);
		}

		PushArrayString(array, fmt);
	}
}





public OnMapStart()
{
	// Precache the models again
	for (new i = 0; i < modelCount; i++)
	{
		if (!StrEqual(models[i][MODELPATH], "") && !StrEqual(models[i][MODELPATH], "0"))
		{
			PrecacheModel(models[i][MODELPATH]);
		}
	}
}





// Create the config
public OnPluginStart()
{
	AutoExecConfig_SetFile("vip_models", "stamm/features");
	AutoExecConfig_SetCreateFile(true);

	g_hModelChange = AutoExecConfig_CreateConVar("model_change", "1", "0 = Players can only change models, when changing team, 1 = Players can always change it");
	g_hAdminModel = AutoExecConfig_CreateConVar("model_admin_model", "1", "Should Admins also get a VIP Skin 1 = Yes, 0 = No");
	g_hModelChangeCmd = AutoExecConfig_CreateConVar("model_change_cmd", "sm_smodel", "Command to change model");
	g_hSameModels = AutoExecConfig_CreateConVar("model_models", "0", "1 = VIP's can choose the model, 0 = Random Skin every Round");

	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	
	
	HookEvent("player_team", eventPlayerTeam);
	HookEvent("player_spawn", eventPlayerSpawn);
	
	ModelDownloads();
	
	Loaded = false;
}





// And load the configs
public OnConfigsExecuted()
{
	model_change = GetConVarInt(g_hModelChange);
	same_models = GetConVarInt(g_hSameModels);
	admin_model = GetConVarInt(g_hAdminModel);
	
	GetConVarString(g_hModelChangeCmd, model_change_cmd, sizeof(model_change_cmd));


	if (!Loaded)
	{
		RegConsoleCmd(model_change_cmd, CmdModel);

		Loaded = true;
	}

	// Register command
	if (!StrContains(model_change_cmd, "sm_") || StrContains(model_change_cmd, "!") != 0)
	{
		ReplaceString(model_change_cmd, sizeof(model_change_cmd), "sm_", "");
		Format(model_change_cmd, sizeof(model_change_cmd), "!%s", model_change_cmd);
	}
}




// Player spawned
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	// Valid?
	if (STAMM_IsClientValid(client))
	{
		// Valid team?
		if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
		{
			// Is in a new team?
			if (LastTeam[client] != GetClientTeam(client))
			{
				// Delete old Model
				PlayerHasModel[client] = 0;
				
				Format(PlayerModel[client], sizeof(PlayerModel[]), "");
			}
			
			// Get last Team
			LastTeam[client] = GetClientTeam(client);

			// is VIP?
			if (STAMM_WantClientFeature(client))
			{
				if (same_models) 
				{
					PrepareSameModels(client);
				}
				else
				{ 
					PrepareRandomModels(client);
				}
			}
		}
	}
}





// Player changed team
public Action:eventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Reset model
	if (STAMM_IsClientValid(client))
	{
		PlayerHasModel[client] = 0;
		
		Format(PlayerModel[client], sizeof(PlayerModel[]), "");
	}
}





// Download all model files
public ModelDownloads()
{
	// Do we have a model downloads file?
	if (!FileExists("cfg/stamm/features/ModelDownloads.txt"))
	{
		STAMM_WriteToLog(false, "Couldn't find ModelDownloads.txt");

		return;
	}


	// If yes, open it
	new Handle:downloadfile = OpenFile("cfg/stamm/features/ModelDownloads.txt", "rb");
	
	// Read out all downloads
	if (downloadfile != INVALID_HANDLE)
	{
		while (!IsEndOfFile(downloadfile))
		{
			// And add them to the downloads table
			decl String:filecontent[PLATFORM_MAX_PATH + 10];
			
			ReadFileLine(downloadfile, filecontent, sizeof(filecontent));
			ReplaceString(filecontent, sizeof(filecontent), " ", "");
			ReplaceString(filecontent, sizeof(filecontent), "\n", "");
			ReplaceString(filecontent, sizeof(filecontent), "\t", "");
			ReplaceString(filecontent, sizeof(filecontent), "\r", "");
			

			if (strlen(filecontent) > 2 && !(filecontent[0] == '/' && filecontent[1] == '/'))
			{
				if (filecontent[strlen(filecontent) - 1] == '*')
				{
					filecontent[strlen(filecontent) - 2] = '\0';

					if (DirExists(filecontent))
					{
						new Handle:dir = OpenDirectory(filecontent);

						if (dir != INVALID_HANDLE)
						{
							decl String:content[PLATFORM_MAX_PATH + 1];
							new FileType:type;

							while (ReadDirEntry(dir, content, sizeof(content), type))
							{
								if (type == FileType_File)
								{
									Format(content, sizeof(content), "%s/%s", filecontent, content);

									AddFileToDownloadsTable(filecontent);
								}
							}
						}
					}
					else
					{
						STAMM_WriteToLog(false, "Found folder '%s' in ModelDownloads, but folder does not exist!", filecontent);
					}
				}
				else
				{
					if (FileExists(filecontent))
					{
						AddFileToDownloadsTable(filecontent);
					}
					else
					{
						STAMM_WriteToLog(false, "Found file '%s' in ModelDownloads, but file does not exist!", filecontent);
					}
				}
			}
		}

		CloseHandle(downloadfile);
	}
}





// Player want a new model
public Action:CmdModel(client, args)
{
	decl String:tag[64];


	if (STAMM_IsClientValid(client))
	{
		if (model_change && same_models && PlayerHasModel[client])
		{
			STAMM_GetTag(tag, sizeof(tag));

			// Reset his mark for a model
			PlayerHasModel[client] = 0;
			Format(PlayerModel[client], sizeof(PlayerModel[]), "");
			

			STAMM_PrintToChat(client, "%s %t", tag, "NewModel", client);
		}
	}
	
	return Plugin_Handled;
}





// The model menu handler
public ModelMenuCall(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (STAMM_IsClientValid(param1))
		{
			decl String:ModelChoose[128];
			
			GetMenuItem(menu, param2, ModelChoose, sizeof(ModelChoose));
			

			// don't want standard model
			if (!StrEqual(ModelChoose, "standard"))
			{
				// set the new model
				SetEntityModel(param1, ModelChoose);
				
				// and mark it
				PlayerHasModel[param1] = 1;
				
				Format(PlayerModel[param1], sizeof(PlayerModel[]), ModelChoose);
			}
			else
			{
				// Reset model
				// But mark he don't want a model
				PlayerHasModel[param1] = 1;
				
				Format(PlayerModel[param1], sizeof(PlayerModel[]), "");
			}
		}
	}
	else if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
}






// Perpare the models
public PrepareSameModels(client)
{
	// does the player have already a model?
	if (!PlayerHasModel[client] && (((!admin_model && !STAMM_IsClientAdmin(client)) || admin_model)))
	{ 
		decl String:ModelChooseLang[256];
		decl String:StandardModel[256];

		new bool:found = false;
		

		// if not open a menu with model choose
		Format(ModelChooseLang, sizeof(ModelChooseLang), "%T", "ChooseModel", client);
		Format(StandardModel, sizeof(StandardModel), "%T", "StandardModel", client);
		
		new Handle:ModelMenu = CreateMenu(ModelMenuCall);
		
		SetMenuTitle(ModelMenu, ModelChooseLang);
		SetMenuExitButton(ModelMenu, false);


		// Loop through available models
		for (new item = 0; item < modelCount; item++)
		{
			// Right team and right level?
			if (GetClientTeam(client) == StringToInt(models[item][MODELTEAM]) && STAMM_GetClientLevel(client) >= StringToInt(models[item][MODELLEVEL]))
			{
				if (!StrEqual(models[item][MODELPATH], "") && !StrEqual(models[item][MODELPATH], "0"))
				{
					// Add model to menu
					AddMenuItem(ModelMenu, models[item][MODELPATH], models[item][MODELNAME]);

					found = true;
				}
			}
		}
		

		// Also add standard choose
		AddMenuItem(ModelMenu, "standard", StandardModel);
		
		// Display the menu
		if (found)
		{
			DisplayMenu(ModelMenu, client, MENU_TIME_FOREVER);
		}
		else
		{
			CloseHandle(ModelMenu);
		}
	}
	else if (PlayerHasModel[client] && !StrEqual(PlayerModel[client], ""))
	{
		SetEntityModel(client, PlayerModel[client]);
	}
}






// Prepare random models
public PrepareRandomModels(client)
{
	new randomValue;
	new found = 0;
	new modelsFound[64];


	// Collect available models of the client
	for (new item = 0; item < modelCount; item++)
	{
		if (StringToInt(models[item][MODELTEAM]) == GetClientTeam(client) && STAMM_GetClientLevel(client) >= StringToInt(models[item][MODELLEVEL]))
		{
			modelsFound[found] = item;

			found++;
		}
	}


	// Found available ones?
	if (found > 0)
	{
		// Get a random one
		randomValue = GetRandomInt(1, found);
		
		// No admin?
		if ((!admin_model && !STAMM_IsClientAdmin(client)) || admin_model)
		{
			// set the new model
			if (!StrEqual(models[randomValue-1][MODELPATH], "") && !StrEqual(models[randomValue-1][MODELPATH], "0"))
			{
				SetEntityModel(client, models[randomValue-1][MODELPATH]);
			}
		}
	}
}