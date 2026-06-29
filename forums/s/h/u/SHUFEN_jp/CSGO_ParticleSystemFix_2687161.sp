#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

#define PLATFORM_LINE_LENGTH 1024
#define NORMAL_LINE_LENGTH 256
#define PLUGIN_CONFIG "CSGO_ParticleSystemFix.games"
#define PLUGIN_LOGFILE "logs/CSGO_ParticleSystemFix.log"

/**
 * @section List of operation systems.
 **/
enum EngineOS {
	OS_Unknown,
	OS_Windows,
	OS_Linux
};

/**
 * @section Struct of operation types for server arrays.
 **/
enum struct ServerData
{
	/* Internal Particles */
	ArrayList Particles;

	/* OS */
	EngineOS Platform;

	/* Gamedata */
	Handle Config;
}
/**
 * @endsection
 **/

ServerData gServerData;

/**
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallDestructorParticleDictionary;
Handle hSDKCallTableDeleteAllStrings;

/**
 * Variables to store virtual SDK offsets.
 **/
Address pParticleSystemDictionary;
int ParticleSystem_Count;

char g_sLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo = {
	name = "[CS:GO] Particle System Fix",
	description = "",
	author = "gubka && PŠΣ™ SHUFEN",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=313951 && https://possession.jp"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("CSGO_ParticleSystemFix");
	CreateNative("UncacheAllParticleSystems", Native_UncacheAllParticleSystems);
	return APLRes_Success;
}

public int Native_UncacheAllParticleSystems(Handle plugin, int numParams) {
	ParticlesOnPurge();
}

/**
 * @brief Particles module init function.
 **/
public void OnPluginStart() {
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), PLUGIN_LOGFILE);

	if (GetEngineVersion() != Engine_CSGO) {
		LogToFileEx(g_sLogPath, "[System Init] Engine error: This plugin only works on Counter-Strike: Global Offensive.");
		return;
	}

	gServerData.Config = LoadGameConfigFile(PLUGIN_CONFIG);

	/*_________________________________________________________________________________________________________________________________________*/

	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CParticleSystemDictionary::~CParticleSystemDictionary");

	// Validate call
	if ((hSDKCallDestructorParticleDictionary = EndPrepSDKCall()) == null) {
		// Log failure
		LogToFileEx(g_sLogPath, "[GameData Validation] Failed to load SDK call \"CParticleSystemDictionary::~CParticleSystemDictionary\". Update signature in \"%s\"", PLUGIN_CONFIG);
		return;
	}

	/*_________________________________________________________________________________________________________________________________________*/

	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CNetworkStringTable::DeleteAllStrings");

	// Validate call
	if ((hSDKCallTableDeleteAllStrings = EndPrepSDKCall()) == null) {
		// Log failure
		LogToFileEx(g_sLogPath, "[GameData Validation] Failed to load SDK call \"CNetworkStringTable::DeleteAllStrings\". Update signature in \"%s\"", PLUGIN_CONFIG);
		return;
	}

	/*_________________________________________________________________________________________________________________________________________*/

	// Load other offsets
	fnInitGameConfAddress(gServerData.Config, pParticleSystemDictionary, "m_pParticleSystemDictionary");
	fnInitGameConfOffset(gServerData.Config, ParticleSystem_Count, "CParticleSystemDictionary::Count");

	/*_________________________________________________________________________________________________________________________________________*/

	//fnInitGameConfOffset(gServerData.Config, view_as<int>(gServerData.Platform), "CServer::OS");
	LogToFileEx(g_sLogPath, "[System Init] Loaded \"Particle System Fix\"");
}

public void OnMapStart() {
	// Precache CS:GO internal particles
	ParticlesOnLoad();

	// Load map particles
	LoadMapExtraFiles();
}

public void OnMapEnd() {
	ParticlesOnPurge();
}

/**
 * @brief Particles module load function.
 **/
void ParticlesOnLoad() {
	// Initialize buffer char
	static char sBuffer[PLATFORM_LINE_LENGTH];

	// Validate that particles wasn't precache yet
	bool bSave = LockStringTables(false);
	Address pTable = CNetworkStringTableContainer_FindTable("ParticleEffectNames");
	int iCount = LoadFromAddress(pParticleSystemDictionary + view_as<Address>(ParticleSystem_Count), NumberType_Int16);
	if (pTable != Address_Null && !iCount) { /// Validate that table is exist and it empty
		// Opens the file
		File hFile = OpenFile("particles/particles_manifest.txt", "rt", true);

		// If doesn't exist stop
		if (hFile == null) {
			LogToFileEx(g_sLogPath, "[Config Validation] Error opening file: \"particles/particles_manifest.txt\"");
			return;
		}

		// Read lines in the file
		while (hFile.ReadLine(sBuffer, sizeof(sBuffer))) {
			// Checks if string has correct quotes
			int iQuotes = CountCharInString(sBuffer, '"');
			if (iQuotes == 4) {
				// Trim string
				TrimString(sBuffer);

				// Copy value string
				strcopy(sBuffer, sizeof(sBuffer), sBuffer[strlen("\"file\"")]);

				// Trim string
				TrimString(sBuffer);

				// Strips a quote pair off a string
				StripQuotes(sBuffer);

				// Precache model
				int i = 0; if (sBuffer[i] == '!') i++;
				PrecacheGeneric(sBuffer[i], true);
				SDKCall(hSDKCallTableDeleteAllStrings, pTable); /// HACK~HACK
				/// Clear tables after each file because some of them contains
				/// huge amount of particles and we work around the limit
			}
		}

		delete hFile;
	}

	// Initialize the table index
	static int tableIndex = INVALID_STRING_TABLE;

	// Validate table
	if (tableIndex == INVALID_STRING_TABLE) {
		// Searches for a string table
		tableIndex = FindStringTable("ParticleEffectNames");
	}

	// If array hasn't been created, then create
	if (gServerData.Particles == null) {
		// Initialize a particle list array
		gServerData.Particles = CreateArray(NORMAL_LINE_LENGTH);

		// i = table string
		iCount = GetStringTableNumStrings(tableIndex);
		for (int i = 0; i < iCount; i++) {
			// Gets the string at a given index
			ReadStringTable(tableIndex, i, sBuffer, sizeof(sBuffer));

			// Push data into array
			gServerData.Particles.PushString(sBuffer);
		}
	} else {
		// i = particle name
		iCount = gServerData.Particles.Length;
		for (int i = 0; i < iCount; i++) {
			// Gets the string at a given index
			gServerData.Particles.GetString(i, sBuffer, sizeof(sBuffer));

			// Push data into table
			AddToStringTable(tableIndex, sBuffer);
		}
	}

	/*
	// Refresh tables
	pTable = CNetworkStringTableContainer_FindTable("ExtraParticleFilesTable");
	if (pTable != Address_Null) {
		SDKCall(hSDKCallTableDeleteAllStrings, pTable);
	}

	pTable = CNetworkStringTableContainer_FindTable("genericprecache");
	if (pTable != Address_Null) {
		SDKCall(hSDKCallTableDeleteAllStrings, pTable);
	}
	*/
	LockStringTables(bSave);
}

void LoadMapExtraFiles() {
	char sMapName[PLATFORM_MAX_PATH];
	GetCurrentMap(sMapName, sizeof(sMapName));

	LoadPerMapParticleManifest(sMapName);
}

void LoadPerMapParticleManifest(const char[] sMapName) {
	KeyValues hKv = GetParticleManifestKv(sMapName);
	if (hKv == null) {
		return;
	}

	ParseParticleManifestKv(hKv, true, true);

	delete hKv;
}

char sDirExt[][][] = { {
		"particles/", "maps/", "particles/", "maps/"
	}, {
		"_manifest_override.txt", "_particles_override.txt", "_manifest.txt", "_particles.txt"
	}
};

KeyValues GetParticleManifestKv(const char[] sMapName) {
	char sFileName[PLATFORM_MAX_PATH];

	for (int i = 0; i < sizeof(sDirExt[]); i++) {
		Format(sFileName, sizeof(sFileName), "%s%s%s", sDirExt[0][i], sMapName, sDirExt[1][i]);
		if (FileExists(sFileName, true)) {
			if (FileExists(sFileName, false))
				AddFileToDownloadsTable(sFileName);

			return CreateManifestKv(sFileName);
		}
	}

	return null;
}

KeyValues CreateManifestKv(const char[] sPath) {
	KeyValues hKv = CreateKeyValues("particles_manifest");

	//hKv.SetEscapeSequences(true);
	if (hKv.ImportFromFile(sPath)) {
		return hKv;
	}

	return null;
}

void ParseParticleManifestKv(KeyValues hKv, bool perMap = false, bool awayPreloads = false) {
	char sPCF[PLATFORM_MAX_PATH];
	if (hKv.GotoFirstSubKey(false))
		do {
			hKv.GetString(NULL_STRING, sPCF, sizeof(sPCF));
			if (sPCF[0] == '\0')
				continue;

			bool preload = FindCharInString(sPCF, '!') == 0;
			if (preload)
				strcopy(sPCF, sizeof(sPCF), sPCF[1]);
			if (FileExists(sPCF, true)) {
				if (perMap && FileExists(sPCF, false))
					AddFileToDownloadsTable(sPCF);
				PrecacheGeneric(sPCF, awayPreloads || preload);
			}
		} while (hKv.GotoNextKey(false));
}

/**
 * @brief Particles module purge function.
 **/
void ParticlesOnPurge() {
	// @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/particles/particles.cpp#L81
	SDKCall(hSDKCallDestructorParticleDictionary, pParticleSystemDictionary);

	/*_________________________________________________________________________________________________________________________________________*/

	// Clear particles in the effect table
	bool bSave = LockStringTables(false);
	Address pTable = CNetworkStringTableContainer_FindTable("ParticleEffectNames");
	if (pTable != Address_Null) {
		SDKCall(hSDKCallTableDeleteAllStrings, pTable);
	}

	// Clear particles in the extra effect table
	pTable = CNetworkStringTableContainer_FindTable("ExtraParticleFilesTable");
	if (pTable != Address_Null) {
		SDKCall(hSDKCallTableDeleteAllStrings, pTable);
	}

	// Clear particles in the generic precache table
	pTable = CNetworkStringTableContainer_FindTable("genericprecache");
	if (pTable != Address_Null) {
		SDKCall(hSDKCallTableDeleteAllStrings, pTable);
	}
	LockStringTables(bSave);
}

stock Address CNetworkStringTableContainer_FindTable(const char[] tableName) {
	Address pNetworkstringtable = GetNetworkStringTableAddr();
	if (pNetworkstringtable == Address_Null)
		return Address_Null;

	static Handle hFindTable = INVALID_HANDLE;
	if (hFindTable == INVALID_HANDLE) {
		if (gServerData.Config == INVALID_HANDLE)
			return Address_Null;

		StartPrepSDKCall(SDKCall_Raw);
		if (!PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "CNetworkStringTableContainer::FindTable")) {
			LogToFileEx(g_sLogPath, "[Find Table] Cant find the method CNetworkStringTableContainer::FindTable.");
			return Address_Null;
		}
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer); // tableName
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		hFindTable = EndPrepSDKCall();
		if (hFindTable == INVALID_HANDLE) {
			LogToFileEx(g_sLogPath, "[Find Table] Method CNetworkStringTableContainer::FindTable was not loaded right.");
			return Address_Null;
		}
	}

	return SDKCall(hFindTable, pNetworkstringtable, tableName);
}

stock Address GetNetworkStringTableAddr() {
	static Address pEngineServerStringTable = Address_Null;
	if (pEngineServerStringTable == Address_Null) {
		if (gServerData.Config == null)
			return Address_Null;

		char sInterfaceName[64];
		if (!GameConfGetKeyValue(gServerData.Config, "VEngineServerStringTable", sInterfaceName, sizeof(sInterfaceName)))
			strcopy(sInterfaceName, sizeof(sInterfaceName), "VEngineServerStringTable001");
		pEngineServerStringTable = CreateEngineInterface(sInterfaceName);
	}

	return pEngineServerStringTable;
}

stock Address CreateEngineInterface(const char[] sInterfaceKey, Address ptr = Address_Null) {
	static Handle hCreateInterface = null;
	if (hCreateInterface == null) {
		if (gServerData.Config == null)
			return Address_Null;

		StartPrepSDKCall(SDKCall_Static);
		if (!PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CreateInterface")) {
			LogToFileEx(g_sLogPath, "[Create Engine Interface] Failed to get CreateInterface");
			return Address_Null;
		}

		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

		hCreateInterface = EndPrepSDKCall();
		if (hCreateInterface == null) {
			LogToFileEx(g_sLogPath, "[Create Engine Interface] Function CreateInterface was not loaded right.");
			return Address_Null;
		}
	}

	if (gServerData.Config == null)
		return Address_Null;

	char sInterfaceName[64];
	if (!GameConfGetKeyValue(gServerData.Config, sInterfaceKey, sInterfaceName, sizeof(sInterfaceName)))
		strcopy(sInterfaceName, sizeof(sInterfaceName), sInterfaceKey);

	Address addr = SDKCall(hCreateInterface, sInterfaceName, ptr);
	if (addr == Address_Null) {
		LogToFileEx(g_sLogPath, "[Create Engine Interface] Failed to get pointer to interface %s(%s)", sInterfaceKey, sInterfaceName);
		return Address_Null;
	}

	return addr;
}

/**
 * @brief Finds the amount of all occurrences of a character in a string.
 *
 * @param sBuffer		  Input string buffer.
 * @param cSymbol		  The character to search for.
 * @return				  The amount of characters in the string, or -1 if the characters were not found.
 */
int CountCharInString(char[] sBuffer, char cSymbol) {
	// Initialize index
	int iCount;

	// i = char index
	int iLen = strlen(sBuffer);
	for (int i = 0; i < iLen; i++) {
		// Validate char
		if (sBuffer[i] == cSymbol) {
			// Increment amount
			iCount++;
		}
	}

	// Return amount
	return iCount ? iCount : -1;
}

/**
 * @brief Returns an offset value from a given config.
 *
 * @param gameConf		  The game config handle.
 * @param iOffset		  An offset, or -1 on failure.
 * @param sKey			  Key to retrieve from the offset section.
 **/
stock void fnInitGameConfOffset(Handle gameConf, int &iOffset, char[] sKey) {
	// Validate offset
	if ((iOffset = GameConfGetOffset(gameConf, sKey)) == -1) {
		LogToFileEx(g_sLogPath, "[GameData Validation] Failed to get offset: \"%s\"", sKey);
	}
}

/**
 * @brief Returns an address value from a given config.
 *
 * @param gameConf		  The game config handle.
 * @param pAddress		  An address, or null on failure.
 * @param sKey			  Key to retrieve from the address section.
 **/
stock void fnInitGameConfAddress(Handle gameConf, Address &pAddress, char[] sKey) {
	// Validate address
	if ((pAddress = GameConfGetAddress(gameConf, sKey)) == Address_Null) {
		LogToFileEx(g_sLogPath, "[GameData Validation] Failed to get address: \"%s\"", sKey);
	}
}