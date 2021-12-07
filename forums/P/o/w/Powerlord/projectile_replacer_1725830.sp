#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define VERSION "1,1"

#define CONFIG_FILE "data/projectile_replacer.cfg"

// global variables
new Handle:g_Cvar_Enabled = INVALID_HANDLE;

new g_ArrayModelSize;
new g_ClassSize = 65;

// For storage, we need a multiple dimensional array, but it can't be fixed size...
// Therefore, we have adt_arrays of adt_arrays. :/
new Handle:g_Replacements = INVALID_HANDLE;
new Handle:g_ReplacementClasses = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Projectile Replacer",
	author = "Powerlord",
	description = "Change the model on projectiles specified in configs/data/projectile_replacer.cfg",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187108"
}

public OnPluginStart()
{
	CreateConVar("tpr_version", VERSION, "Projectile Replacer version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("tpr_enabled", "1", "Projectile Replacer enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	RegAdminCmd("tpr_reload", ReloadConfig, ADMFLAG_CONFIG, "Reload Projectile Replacer configuration file");
	
	HookConVarChange(g_Cvar_Enabled, OnEnabledChanged);
	
	g_ArrayModelSize = ByteCountToCells(PLATFORM_MAX_PATH);
	
	// This is the index of the Trie
	g_ReplacementClasses = CreateArray(ByteCountToCells(g_ClassSize));
	
	// This is a Trie of array handles
	g_Replacements = CreateTrie();
}

public OnConfigsExecuted()
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		// Re-read our configuration every time configurations are reloaded.
		ReadConfigFile();
		
		LoadModels();
	}
}

public OnEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		// Re-read our configuration when the convar is enabled
		// This allows us to not reload the config when the plugin is disabled on map start
		ReadConfigFile();
		
		LoadModels();
	}
}

public Action:ReloadConfig(client, args)
{
	ReadConfigFile();
	
	ReplyToCommand(client, "Reloaded Projectile Replacer configuration file");
	
	return Plugin_Handled;
}

stock ReadConfigFile()
{
	LogMessage("Loaded configuration file");

	ClearReplacementArrays();
	
	decl String:filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "%s", CONFIG_FILE);
	
	new Handle:kvProjectiles = CreateKeyValues("ProjectileReplacements");

	if (!FileToKeyValues(kvProjectiles, filePath))
	{
		SetFailState("Could not find configuration file %s", filePath);
		return;
	}
	
	if (!KvGotoFirstSubKey(kvProjectiles))
	{
		CloseHandle(kvProjectiles);
		return;
	}
	
	do
	{
		decl String:classname[g_ClassSize];
		KvGetSectionName(kvProjectiles, classname, g_ClassSize);
		
		// Go to the values
		new Handle:replacements = CreateArray(g_ArrayModelSize);
		
		if (!KvGotoFirstSubKey(kvProjectiles, false))
		{
			continue;
		}
		
		do
		{
			// Get the current element
			decl String:model[PLATFORM_MAX_PATH];
			KvGetString(kvProjectiles, NULL_STRING, model, sizeof(model));
			
			if (!StrEqual(model, ""))
			{
				PushArrayString(replacements, model);
			}
			
		} while (KvGotoNextKey(kvProjectiles, false));
		
		if (GetArraySize(replacements) > 0)
		{
			PushArrayString(g_ReplacementClasses, classname);
			SetTrieValue(g_Replacements, classname, replacements);
		}
		
		// Back up to the previous level
		KvGoBack(kvProjectiles);
		
	} while (KvGotoNextKey(kvProjectiles));
	
	CloseHandle(kvProjectiles);
}

stock LoadModels()
{
	new size = GetArraySize(g_ReplacementClasses);

	for (new i = 0; i < size; i++)
	{
		decl String:classname[g_ClassSize];
		GetArrayString(g_ReplacementClasses, i, classname, g_ClassSize);
		
		new Handle:replacements;
		GetTrieValue(g_Replacements, classname, replacements);
		
		new modelCount = GetArraySize(replacements);
		
		for (new j = 0; j < modelCount; j++)
		{
			decl String:model[PLATFORM_MAX_PATH];
			GetArrayString(replacements, j, model, PLATFORM_MAX_PATH);
			
			PrecacheModel(model);
		}
		
	}
	
}

public OnEntityCreated(entity, const String:classname[])
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		if (FindStringInArray(g_ReplacementClasses, classname) > -1)
		{
			SDKHook(entity, SDKHook_SpawnPost, ProjectileSpawned);
		}
	}
}

public ProjectileSpawned(entity)
{
	decl String:classname[g_ClassSize];
	
	GetEntityClassname(entity, classname, g_ClassSize);
	
	new Handle:replacements;
	if (GetTrieValue(g_Replacements, classname, replacements))
	{
		decl String:model[PLATFORM_MAX_PATH];
		new rand = GetRandomInt(1, GetArraySize(replacements)) - 1;
		GetArrayString(replacements, rand, model, PLATFORM_MAX_PATH);
		SetEntityModel(entity, model);
	}

}

// To prevent leaks
stock ClearReplacementArrays()
{
	new size = GetArraySize(g_ReplacementClasses);
	
	for (new i = 0; i < size; i++)
	{
		decl String:classname[g_ClassSize];
		GetArrayString(g_ReplacementClasses, i, classname, g_ClassSize);
		
		new Handle:replacements;
		GetTrieValue(g_Replacements, classname, replacements);
		
		CloseHandle(replacements);
	}
	
	ClearArray(g_ReplacementClasses);
	ClearTrie(g_Replacements);
}