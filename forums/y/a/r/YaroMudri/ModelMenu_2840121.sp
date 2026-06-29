#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[TF2] Model Menu",
	description = "Simple model menu for TF2",
	author = "",
	version = PLUGIN_VERSION,
	url = ""
};

// Model data structure
enum struct ModelData
{
	char name[32];
	char path[256];
}

ArrayList g_Models;

// Store original player class and model
StringMap g_OriginalClasses;

// Track players with modified models
ArrayList g_ModifiedPlayers;

public void OnPluginStart()
{
	g_Models = new ArrayList(sizeof(ModelData));
	g_OriginalClasses = new StringMap();
	g_ModifiedPlayers = new ArrayList();
	
	LoadModels();
	
	RegConsoleCmd("sm_models", Command_Models, "Open model selection menu");
	
	// Hook entity outputs
	HookEntityOutput("func_regenerate", "OnStartTouch", OnRegenerateStartTouch);
	HookEntityOutput("func_regenerate", "OnEndTouch", OnRegenerateEndTouch);
	
	// Hook player spawn and death events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_InventoryApplication);
}

public void OnMapStart()
{
	// Precache all models when map starts
	for (int i = 0; i < g_Models.Length; i++)
	{
		ModelData model;
		g_Models.GetArray(i, model);
		
		if (FileExists(model.path, true))
		{
			PrecacheModel(model.path, true);
		}
	}
	
	// Clear modified players on map change
	g_ModifiedPlayers.Clear();
}

public void OnClientDisconnect(int client)
{
	// Remove player from tracking when they disconnect
	int index = g_ModifiedPlayers.FindValue(client);
	if (index != -1)
	{
		g_ModifiedPlayers.Erase(index);
	}
	
	// Remove their original class from storage
	char steamID[32];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	g_OriginalClasses.Remove(steamID);
}

void LoadModels()
{
	g_Models.Clear();
	AddModel("Hatman", "models/bots/headless_hatman.mdl");
	AddModel("Skeleton Sniper", "models/bots/skeleton_sniper/skeleton_sniper.mdl");
	AddModel("Merasmus", "models/bots/merasmus/merasmus.mdl");
	AddModel("SentryBuster", "models/bots/demo/bot_sentry_buster.mdl");
	AddModel("Scout", "models/player/scout.mdl");
	AddModel("Soldier", "models/player/soldier.mdl");
	AddModel("Pyro", "models/player/pyro.mdl");
	AddModel("Demoman", "models/player/demo.mdl");
	AddModel("Heavy", "models/player/heavy.mdl");
	AddModel("Engineer", "models/player/engineer.mdl");
	AddModel("Medic", "models/player/medic.mdl");
	AddModel("Sniper", "models/player/sniper.mdl");
	AddModel("Spy", "models/player/spy.mdl");
	AddModel("Robo-Scout", "models/bots/scout/bot_scout.mdl");
	AddModel("Robo-Soldier", "models/bots/soldier/bot_soldier.mdl");
	AddModel("Robo-Pyro", "models/bots/pyro/bot_pyro.mdl");
	AddModel("Robo-Demo", "models/bots/demo/bot_demo.mdl");
	AddModel("Robo-Heavy", "models/bots/heavy/bot_heavy.mdl");
	AddModel("Robo-Engineer", "models/bots/engineer/bot_engineer.mdl");
	AddModel("Robo-Medic", "models/bots/medic/bot_medic.mdl");
	AddModel("Robo-Sniper", "models/bots/sniper/bot_sniper.mdl");
	AddModel("Robo-Spy", "models/bots/spy/bot_spy.mdl");
}

void AddModel(const char[] name, const char[] path)
{
	ModelData model;
	strcopy(model.name, sizeof(model.name), name);
	strcopy(model.path, sizeof(model.path), path);
	
	g_Models.PushArray(model);
}

public Action Command_Models(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	ShowModelMenu(client);
	return Plugin_Handled;
}

void ShowModelMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Models);
	menu.SetTitle("Available Models");
	
	for (int i = 0; i < g_Models.Length; i++)
	{
		ModelData model;
		g_Models.GetArray(i, model);
		menu.AddItem(model.path, model.name);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Models(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char modelPath[256];
			menu.GetItem(param2, modelPath, sizeof(modelPath));
			
			if (SetPlayerModel(client, modelPath))
			{
				PrintToChat(client, "Model changed successfully!");
			}
			else
			{
				PrintToChat(client, "Failed to change model!");
			}
			
			// Re-show menu for convenience
			ShowModelMenu(client);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

bool SetPlayerModel(int client, const char[] modelPath)
{
	if (!IsModelPrecached(modelPath))
	{
		if (!PrecacheModel(modelPath, true))
		{
			LogError("Failed to precache model: %s", modelPath);
			return false;
		}
	}
	
	// Store original class if not already stored
	char steamID[32];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	
	int originalClass;
	if (!g_OriginalClasses.GetValue(steamID, originalClass))
	{
		// Store the current class
		TFClassType currentClass = TF2_GetPlayerClass(client);
		g_OriginalClasses.SetValue(steamID, view_as<int>(currentClass));
	}
	
	// Set the custom model
	SetVariantString(modelPath);
	AcceptEntityInput(client, "SetCustomModel");
	
	// Enable class animations
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	// Remove wearables for better compatibility
	RemoveAllWearables(client);
	
	// Add to modified players list if not already there
	if (g_ModifiedPlayers.FindValue(client) == -1)
	{
		g_ModifiedPlayers.Push(client);
	}
	
	return true;
}

void RemoveAllWearables(int client)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable*")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	// Also check for tf_wearable_vm (viewmodel wearables)
	entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable_vm*")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}

// Handle func_regenerate start touch
public void OnRegenerateStartTouch(const char[] output, int caller, int activator, float delay)
{
	if (!IsValidClient(activator))
		return;
	
	// Check if player has modified model
	if (g_ModifiedPlayers.FindValue(activator) != -1)
	{
		// Kill the modified model and restore original
		RestoreOriginalModel(activator);
		PrintToChat(activator, "Your model has been restored by the resupply locker!");
	}
}

// Handle func_regenerate end touch (for safety)
public void OnRegenerateEndTouch(const char[] output, int caller, int activator, float delay)
{
	// Optional: You can add functionality here if needed
}

// Restore player's original model
void RestoreOriginalModel(int client)
{
	char steamID[32];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	
	int originalClass;
	if (g_OriginalClasses.GetValue(steamID, originalClass))
	{
		// Clear custom model
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		
		// Force class change to restore proper model
		TF2_SetPlayerClass(client, view_as<TFClassType>(originalClass), _, true);
		
		// Reapply inventory to ensure proper loadout
		TF2_RegeneratePlayer(client);
		
		// Remove from modified players list
		int index = g_ModifiedPlayers.FindValue(client);
		if (index != -1)
		{
			g_ModifiedPlayers.Erase(index);
		}
		
		// Clear the stored original class
		g_OriginalClasses.Remove(steamID);
	}
}

// Handle player spawn - restore model if needed
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return;
	
	// Small delay to ensure spawn is complete
	CreateTimer(0.2, Timer_CheckModel, GetClientUserId(client));
}

// Handle inventory application (when player changes class or respawns)
public void Event_InventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return;
	
	// If player has custom model, reapply it after inventory update
	if (g_ModifiedPlayers.FindValue(client) != -1)
	{
		CreateTimer(0.3, Timer_ReapplyModel, GetClientUserId(client));
	}
}

// Timer to reapply custom model after inventory application
public Action Timer_ReapplyModel(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	// Reapply the last custom model
	char steamID[32];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	
	// Store the current class before reapplying custom model
	TFClassType currentClass = TF2_GetPlayerClass(client);
	g_OriginalClasses.SetValue(steamID, view_as<int>(currentClass));
	
	// You might want to store which model the player had selected
	// and reapply it here. For now, we'll just keep them in modified list.
	
	return Plugin_Stop;
}

// Handle player death
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return;
	
	// Optional: You can choose to restore model on death or not
	// RestoreOriginalModel(client);
}

// Timer to check model after spawn
public Action Timer_CheckModel(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	// If player is in modified list but doesn't have custom model, fix it
	if (g_ModifiedPlayers.FindValue(client) != -1)
	{
		// Check if custom model is still applied
		if (GetEntProp(client, Prop_Send, "m_nModelIndexOverrides") == 0)
		{
			// Custom model was lost, reapply or restore original
			// For now, we'll remove them from modified list
			int index = g_ModifiedPlayers.FindValue(client);
			if (index != -1)
			{
				g_ModifiedPlayers.Erase(index);
			}
			char steamID[32];
			GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
			g_OriginalClasses.Remove(steamID);
		}
	}
	
	return Plugin_Stop;
}

// Stock function to check if client is valid
stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}