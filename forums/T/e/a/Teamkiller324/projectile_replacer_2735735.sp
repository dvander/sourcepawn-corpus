#include	<sdktools>
#include	<sdkhooks>

#pragma		semicolon	1
#pragma		newdecls	required

#define		VERSION		"1.2"
#define		CONFIG_FILE	"data/projectile_replacer.cfg"

// global variables
ConVar	g_Cvar_Enabled;

int	g_ArrayModelSize,
	g_ClassSize = 65;

// For storage, we need a multiple dimensional array, but it can't be fixed size...
// Therefore, we have adt_arrays of adt_arrays. :/
ArrayList	g_Replacements,
			g_ReplacementClasses;

public	Plugin	myinfo	=	{
	name		=	"Projectile Replacer",
	author		=	"Powerlord",
	description	=	"Change the model on projectiles specified in configs/data/projectile_replacer.cfg",
	version		=	VERSION,
	url			=	"https://forums.alliedmods.net/showthread.php?t=187108"
}

public	void	OnPluginStart()	{
	CreateConVar("tpr_version", VERSION, "Projectile Replacer version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_Enabled	=	CreateConVar("tpr_enabled", "1", "Projectile Replacer enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	RegAdminCmd("tpr_reload",	ReloadConfig,	ADMFLAG_CONFIG,	"Reload Projectile Replacer configuration file");
	
	g_Cvar_Enabled.AddChangeHook(OnEnabledChanged);
	g_ArrayModelSize = ByteCountToCells(PLATFORM_MAX_PATH);
	
	// This is the index of the Trie
	g_ReplacementClasses = new ArrayList(ByteCountToCells(g_ClassSize));
	
	// This is a Trie of array handles
	g_Replacements = new ArrayList(); //Same as CreateTrie() ??
}

public	void	OnConfigsExecuted()	{
	if(g_Cvar_Enabled.BoolValue)	{
		// Re-read our configuration every time configurations are reloaded.
		ReadConfigFile();
		
		LoadModels();
	}
}

void	OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)	{
	if(convar.BoolValue)	{
		// Re-read our configuration when the convar is enabled
		// This allows us to not reload the config when the plugin is disabled on map start
		ReadConfigFile();
		
		LoadModels();
	}
}

Action	ReloadConfig(int client, int args)	{
	ReadConfigFile();
	
	ReplyToCommand(client, "Reloaded Projectile Replacer configuration file");
	
	return Plugin_Handled;
}

stock	void	ReadConfigFile()	{
	LogMessage("Loaded configuration file");

	ClearReplacementArrays();
	
	char	filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "%s", CONFIG_FILE);
	
	KeyValues	kvProjectiles = new KeyValues("ProjectileReplacements");

	if(!kvProjectiles.ImportFromFile(filePath))
		SetFailState("Could not find configuration file %s", filePath);
	
	if(!kvProjectiles.GotoFirstSubKey())
		return;
	
	do	{
		char	classname[65];
		kvProjectiles.GetSectionName(classname, g_ClassSize);
		
		// Go to the values
		ArrayList	replacements = new ArrayList(g_ArrayModelSize);
		
		if(!kvProjectiles.GotoFirstSubKey(false))
			continue;
		
		do	{
			// Get the current element
			char	model[PLATFORM_MAX_PATH];
			kvProjectiles.GetString(NULL_STRING, model, sizeof(model));
			
			if(!StrEqual(model, ""))
				replacements.PushString(model);
			
		}
		while(kvProjectiles.GotoNextKey(false));
		
		if(GetArraySize(replacements) > 0)	{
			g_ReplacementClasses.PushString(classname);
			SetTrieValue(g_Replacements, classname, replacements);
		}
		
		// Back up to the previous level
		kvProjectiles.GoBack();
		
	}
	while(kvProjectiles.GotoNextKey());
	
	delete	kvProjectiles;
}

stock	void	LoadModels()	{
	int size = GetArraySize(g_ReplacementClasses);

	for (int i = 0; i < size; i++)	{
		char	classname[65];
		g_ReplacementClasses.GetString(i, classname, g_ClassSize);
		
		ArrayList	replacements;
		GetTrieValue(g_Replacements, classname, replacements);
		
		int modelCount = GetArraySize(replacements);
		
		for(int j = 0; j < modelCount; j++)	{
			char	model[PLATFORM_MAX_PATH];
			replacements.GetString(j, model, PLATFORM_MAX_PATH);
			
			PrecacheModel(model);
		}
		
	}
	
}

public	void	OnEntityCreated(int entity, const char[] classname)	{
	if(g_Cvar_Enabled.BoolValue)	{
		if(FindStringInArray(g_ReplacementClasses, classname) > -1)	{
			SDKHook(entity, SDKHook_SpawnPost, ProjectileSpawned);
		}
	}
}

void	ProjectileSpawned(int entity)	{
	char	classname[65];
	
	GetEntityClassname(entity, classname, g_ClassSize);
	
	ArrayList	replacements;
	if(GetTrieValue(g_Replacements, classname, replacements))	{
		char	model[PLATFORM_MAX_PATH];
		int rand = GetRandomInt(1, GetArraySize(replacements)) - 1;
		replacements.GetString(rand, model, PLATFORM_MAX_PATH);
		SetEntityModel(entity, model);
	}

}

// To prevent leaks
stock	void	ClearReplacementArrays()	{
	int size = GetArraySize(g_ReplacementClasses);
	
	for(int i = 0; i < size; i++)	{
		char	classname[65];
		g_ReplacementClasses.GetString(i, classname, g_ClassSize);
		
		ArrayList	replacements;
		GetTrieValue(g_Replacements, classname, replacements);
		
		delete	replacements;
	}
	
	g_ReplacementClasses.Clear();
	g_Replacements.Clear();
}