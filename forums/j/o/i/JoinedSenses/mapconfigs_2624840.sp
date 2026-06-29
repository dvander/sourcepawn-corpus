
// enforce semicolons after each code statement
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.4"

#define CONFIG_DIR "sourcemod/map-cfg/"

/*****************************************************************
		P L U G I N   I N F O
*****************************************************************/

public Plugin myinfo = {
	name = "Map configs",
	author = "Berni",
	description = "Map specific configs execution with prefix support",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=607079"
}

// Misc
/*****************************************************************
		F O R W A R D   P U B L I C S
*****************************************************************/

public void OnPluginStart() {
	CreateConVar("mc_version", PLUGIN_VERSION, "Map Configs plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
}

public void OnAutoConfigsBuffered() {
	ExecuteMapSpecificConfigs();
}

/*****************************************************************
		P L U G I N   F U N C T I O N S
*****************************************************************/

public void ExecuteMapSpecificConfigs() {
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	int mapSepPos = FindCharInString(currentMap, '/', true);
	if (mapSepPos != -1) {
		strcopy(currentMap, sizeof(currentMap), currentMap[mapSepPos+1]);
	}

	LogMessage("Searching specific configs for %s", currentMap);

	ArrayList adt_configs = new ArrayList(PLATFORM_MAX_PATH);
	char cfgdir[PLATFORM_MAX_PATH];

	Format(cfgdir, sizeof(cfgdir), "cfg/%s", CONFIG_DIR);

	DirectoryListing dir = OpenDirectory(cfgdir);

	if (dir == null) {
		LogMessage("Error iterating folder %s, folder doesn't exist !", cfgdir);
		return;
	}

	char configFile[PLATFORM_MAX_PATH];
	char explode[2][64];
	FileType fileType;

	while (dir.GetNext(configFile, sizeof(configFile), fileType)) {
		if (fileType == FileType_File) {
			ExplodeString(configFile, ".", explode, 2, sizeof(explode[]));
			if (StrEqual(explode[1], "cfg", false)) {
				if (strncmp(currentMap, explode[0], strlen(explode[0]), false) == 0) {
					adt_configs.PushString(configFile);
				}
			}
		}
	}

	SortADTArray(adt_configs, Sort_Ascending, Sort_String);

	int size = adt_configs.Length;

	for (int i = 0; i < size; ++i) {
		adt_configs.GetString(i, configFile, sizeof(configFile));
		LogMessage("Executing map specific config: %s", configFile);
		ServerCommand("exec %s%s", CONFIG_DIR, configFile);
	}

	delete dir;
	delete adt_configs;

	return;
}