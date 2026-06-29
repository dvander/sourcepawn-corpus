/*
*	Infected Populations Editor
*	Copyright (C) 2026 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.9"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Infected Populations Editor
*	Author	:	SilverShot
*	Descrp	:	Modify population.txt values by config instead of conflicting VPK files.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=344298
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.9 (31-Mar-2026)
    - Added sm_pop_stat for debugging. To enable, compile with DEBUG_STATS 1.

1.8 (30-Mar-2026)
	- Plugin now limits "Fallen Survivors" to the number set by "z_fallen_max_count" cvar.
	- Chance changed to float values (test).
	- gvazdas: added automatic normalization to 100 percent.

1.7 (25-Jan-2026)
	- L4D2: Fixed breaking some spawn nav areas. Thanks to "Marttt" for reporting.

1.6 (04-Jan-2026)
	- Added checks for the Witch. Thanks to "Uncle Jessie" for reporting.

1.5 (22-Sep-2024)
	- Added support for Left 4 Dead 1 game.
	- Plugin and GameData updated.

1.4 (16-May-2024)
	- Updated plugin and GameData to fix errors and Windows signature from the recent L4D2 game update. Thanks to "Sev" for reporting.

1.3 (05-Mar-2024)
	- Added support for Special Infected NavArea placements. Requested by "Sev".
	- Plugin now requires the "Left 4 DHooks" plugin.
	- GameData file has been updated.

1.2 (07-Nov-2023)
	- Added feature to load configs by base mode: "coop", "realism", "survival", "versus", "scavenge" or defaults to "file" within the data config.
	- Added "population3.txt" scripts config example to spawn all types of available infected.

1.1 (26-Oct-2023)
	- Ignores non-common infected spawn areas allowing Special Infected to spawn.

1.0 (25-Oct-2023)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks>


#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_population_editor"
#define CONFIG_DATA			"data/l4d_population_editor.cfg"
#define DEBUG_PRINT			0 // Debug print the models loaded, the chance etc
#define DEBUG_STATS			0 // Unlock sm_pop_stat


ConVar g_hCvarMPGameMode, g_hCvarFallenCount;
int g_iCurrentMode, g_iCvarFallenCount;
bool g_bValidData;
// bool g_bLeft4Dead2;
StringMap g_hData;
StringMapSnapshot g_hSnap;
// Address g_aPatchConfig;
// Handle g_hSDK_ReloadPopulation;

// L4D2: Unused
enum
{
	TYPE_CEDA			= 11,
	TYPE_MUD_MEN		= 12,
	TYPE_ROAD_WORKER	= 13,
	TYPE_FALLEN			= 14,
	TYPE_RIOT			= 15,
	TYPE_CLOWN			= 16,
	TYPE_JIMMY_GIBBS	= 17
}

// Print statistics.
#if DEBUG_STATS
StringMap g_hModelStats;
#endif


// ====================================================================================================
//					PLUGIN INFO / NATIVES
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Infected Populations Editor",
	author = "SilverShot",
	description = "Modify population.txt values by config instead of conflicting VPK files.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344298"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	// if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	// else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	// else
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}



// ====================================================================================================
//					PLUGIN START / END
// ====================================================================================================
public void OnPluginStart()
{
	// =========================
	// GAMEDATA
	// =========================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false )
    	SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	GameData hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);



	// =========================
	// SDKCALL
	// =========================
	/*
	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::ReloadPopulationData");
		g_hSDK_ReloadPopulation = EndPrepSDKCall();
		if( g_hSDK_ReloadPopulation == null )
			SetFailState("Failed to create SDKCall: CDirector::ReloadPopulationData");
	}
	*/



	// =========================
	// ADDRESSES
	// =========================
	// g_aPatchConfig = GameConfGetAddress(hGameData, "PatchPopConfig") + view_as<Address>(8);



	// =========================
	// DETOURS
	// =========================
	Handle hDetour;

	// Spawn by population:
	hDetour = DHookCreateFromConf(hGameData, "SelectModelByPopulation");
	if( !hDetour )
		SetFailState("Failed to find \"SelectModelByPopulation\" signature.");
	if( !DHookEnableDetour(hDetour, false, SelectModelByPopulation) )
		SetFailState("Failed to detour \"SelectModelByPopulation\"");
	delete hDetour;

	delete hGameData;

	// Uncommon infected spawns:
	/*
	if( g_bLeft4Dead2 )
	{
		hDetour = DHookCreateFromConf(hGameData, "Infected::Spawn");
		if( !hDetour )
			SetFailState("Failed to find \"Infected::Spawn\" signature.");
		if( !DHookEnableDetour(hDetour, false, Infected_Spawn) )
			SetFailState("Failed to detour \"Infected::Spawn\"");
		if( !DHookEnableDetour(hDetour, true, Infected_Spawn_Post) )
			SetFailState("Failed to detour \"Infected::Spawn\"");
		delete hDetour;
	}
	*/



	// =========================
	// OTHER
	// =========================
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	
	g_hCvarFallenCount = FindConVar("z_fallen_max_count");
	g_hCvarFallenCount.AddChangeHook(ConVarChanged_Cvars);
	g_iCvarFallenCount = g_hCvarFallenCount.IntValue; // in case convarchanged didn't trigger

	CreateConVar("l4d_population_editor_version", PLUGIN_VERSION, "Infected Populations Editor plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_pop_reload", CmdReload, ADMFLAG_ROOT, "Reloads the Infected Populations Editor data config.");

	g_hData = new StringMap();
	#if DEBUG_STATS
    g_hModelStats = new StringMap();
    RegAdminCmd("sm_pop_stat",CmdStats,ADMFLAG_ROOT,"Print statistics. Use with only default specified.");
    #endif
	
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarFallenCount = g_hCvarFallenCount.IntValue;
}



// ====================================================================================================
// LOAD CONFIG
// ====================================================================================================
Action CmdReload(int client, int args)
{
	LoadConfig();
	ReplyToCommand(client, "Population Editor: config reloaded!");
	return Plugin_Handled;
}

public void OnMapStart()
{
	GetGameMode();
	LoadConfig();
}

void GetGameMode()
{
	g_iCurrentMode = L4D_GetGameModeType();

	if( g_iCurrentMode == 1 )
	{
		static char temp[16];
		g_hCvarMPGameMode.GetString(temp, sizeof(temp));
		if( strcmp(temp, "realism") == 0 )
		{
			g_iCurrentMode = 5;
		}
	}
}

public void L4D_OnGameModeChange(int gamemode)
{
	OnMapStart();
}

void ResetPlugin()
{
	g_bValidData = false;

	if( g_hSnap && g_hSnap.Length > 0 )
	{
		static char sMap[64];
		StringMap aMap;

		for( int i = 0; i < g_hSnap.Length; i++ )
		{
			g_hSnap.GetKey(i, sMap, sizeof(sMap));
			g_hData.GetValue(sMap, aMap);
			delete aMap;
		}
	}

	g_hData.Clear();
	delete g_hSnap;
}

void LoadConfig()
{
	static char sModel[PLATFORM_MAX_PATH];
	static char sPath[PLATFORM_MAX_PATH];
	static char sMap[64];
	StringMap aMap;



	// Clean data
	ResetPlugin();



	// Load config
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_DATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	KeyValues hFile = new KeyValues("populations");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}



	// Check for current map in the config, or load from the "all" section
	GetCurrentMap(sMap, sizeof(sMap));

	if( hFile.JumpToKey(sMap) || hFile.JumpToKey("all") )
	{
		// Get the "file" path, by mode or default
		switch( g_iCurrentMode )
		{
			case 1:		hFile.GetString("coop", sPath, sizeof(sPath));
			case 2:		hFile.GetString("versus", sPath, sizeof(sPath));
			case 4:		hFile.GetString("survival", sPath, sizeof(sPath));
			case 8:		hFile.GetString("scavenge", sPath, sizeof(sPath));
			case 5:		hFile.GetString("realism", sPath, sizeof(sPath));
			default:	hFile.GetString("file", sPath, sizeof(sPath));
		}

		// Ignore no modes
		if( sPath[0] == 0 )
		{
			hFile.GetString("file", sPath, sizeof(sPath));
		}

		// Ignore blank configs
		if( sPath[0] == 0 )
		{
			delete hFile;
			return;
		}
		// Validate the config exists
		else if( !FileExists(sPath) )
		{
			LogError("Error: custom file \"%s\" missing.", sPath);
		}
		else
		{
			// Load population.txt keyvalues
			KeyValues hData = new KeyValues("Population");
			if( !hData.ImportFromFile(sPath) )
			{
				LogError("Failed to read the custom \"%s\" population config.", sPath);
			}
			else
			{
				#if DEBUG_PRINT
				PrintToServer(" ");
				PrintToServer("##### Population: Loading config [%s]", sPath);
				#endif

				char sTemp[64];
				float percent;
				float chance;
				bool passed;

				hData.GotoFirstSubKey(true);

				// Loop through the keyvalues "NavArea place names" sections
				do
				{
					hData.GetSectionName(sTemp, sizeof(sTemp));

					#if DEBUG_PRINT
					PrintToServer(" ");
					PrintToServer("##### Population: section [%s]", sTemp);
					#endif

					aMap = new StringMap();
					percent = 0.0;

					// Loop through the models and chance to spawn
					do
					{
						passed = true;
						hData.GotoFirstSubKey(false);
						hData.GetSectionName(sModel, sizeof(sModel));
						hData.GoBack();

						#if DEBUG_PRINT
						PrintToServer("##### Population: key [%s]", sModel);
						#endif

						// Ignore all models that are not "common" infected or Special Infected
						if( strncmp(sModel, "common", 6) && strcmp(sModel, "tank") && strcmp(sModel, "boomer") && strcmp(sModel, "hunter") && strcmp(sModel, "smoker") && strcmp(sModel, "charger") &&
    						strcmp(sModel, "jockey") && strcmp(sModel, "spitter") && strcmp(sModel, "boomette") && strcmp(sModel, "witch") && strcmp(sModel, "witch_bride") )
						{
							passed = false;
							hData.JumpToKey(sModel);

							#if DEBUG_PRINT
							PrintToServer("##### Population: SKIP: INVALID MODEL [%s]", sModel);
							#endif
						}

						// Add together percentage
						chance = hData.GetFloat(sModel);
						if( chance <= 0.0 )
						{
							passed = false;
							#if DEBUG_PRINT
							PrintToServer("##### Population: SKIP: %f CHANCE [%s]", chance, sModel);
							#endif
						}

						hData.JumpToKey(sModel);

						if( passed )
						{
							percent += chance;

							#if DEBUG_PRINT
							PrintToServer("##### Population: val [%f]", percent);
							#endif

							// Set full model path
							if( strcmp(sModel, "tank") == 0 ) sModel = "hulk";
							Format(sModel, sizeof(sModel), "models/infected/%s.mdl", sModel);

							// Config error checks
							//if( percent > 100.0 )
							//{
							//	LogError("\n==========\nError: percent adds up to > 100.0 (%f):\n===== File: \"%s\"\n===== Section: \"%s\"\n==========", percent, sPath, sTemp);
							//	ResetPlugin();
							//	return;
							//}
							if( aMap.ContainsKey(sModel) )
							{
								LogError("\n==========\nError: duplicate model:\n===== File: \"%s\"\n===== Section: \"%s\"\n===== Model: \"%s\"\n==========", sPath, sTemp, sModel);
								ResetPlugin();
								return;
							}
							else if( FileExists(sModel, true) == false )
							{
								LogError("\n==========\nError: invalid model, file \"%s\" missing.\n==========", sModel);
								ResetPlugin();
								return;
							}
							// Save and Precache
							else
							{
								PrecacheModel(sModel);
								aMap.SetValue(sModel, percent);
							}
						}
					}
					while( hData.GotoNextKey(false) );

					// Error checking (0% can be from sections that do not have any common infected models)
					if( percent <= 0.0 )
					{
						LogError("\n==========\nError: invalid percent (%f):\n===== File: \"%s\"\n===== Section: \"%s\"\n==========", percent, sPath, sTemp);
						ResetPlugin();
						return;
					}

					// Ready for next section
					hData.GoBack();

					// Save StringMap in global StringMap
					if( aMap.Size > 0 )
					{
						// Enforce percent adding up to 100.0
    					#if DEBUG_PRINT
    					LogMessage("%s adds up to %f", sTemp, percent);
    					#endif
    					if (percent!=100.0)
    					{
      						#if DEBUG_PRINT
          					LogMessage("Renormalizing %s:", sTemp);
          					#endif
          					float percent_old, percent_new = 0.0;
          					float norm = percent/100.0; // if percent>100.0, norm>1.0; we divide old percentages by norm to get sum to be 100.0
          					StringMapSnapshot aSnap = aMap.Snapshot();
          					for(int i = aMap.Size - 1; i >= 0; i--)
          					{
              					aSnap.GetKey(i,sModel,sizeof(sModel));
              					aMap.GetValue(sModel, percent_old);
              					percent_new = percent_old/norm;
              					aMap.SetValue(sModel, percent_new);
              					#if DEBUG_PRINT
                                LogMessage("%s %f -> %f", sModel, percent_old, percent_new);
                                #endif
          					}
    					}
						g_hData.SetValue(sTemp, aMap);
					}
					else
					{
						// Save a blank section to allow Special Infected to spawn
						delete aMap;
						g_hData.SetValue(sTemp, 0.0);
					}
				}
				while( hData.GotoNextKey(false) );



				// Reload population data
				// Note: Even though we call this to overwrite the config, common still spawn using the old config, hence why we continue to detour SelectModelByPopulation
				// Note: Although it seems to overwrite fine for InputspawnZombie, and hopefully other parts of the game using the population config
				/*
				if( g_bLeft4Dead2 )
				{
					// Rename config to force overriding
					if( FileExists("scripts/Kopulation.txt") )
						DeleteFile("scripts/Kopulation.txt");

					RenameFile("scripts/Kopulation.txt", sPath);

					// Patch config string name so it's loaded
					StoreToAddress(g_aPatchConfig, 'K', NumberType_Int8);

					Address director = L4D_GetPointer(POINTER_DIRECTOR);
					SDKCall(g_hSDK_ReloadPopulation, director);

					// Restore patched string
					StoreToAddress(g_aPatchConfig, 'p', NumberType_Int8);

					// Restore config name
					RenameFile(sPath, "scripts/Kopulation.txt");
				}
				// */
			}
		}
	}

	if( g_hData.Size > 0 )
	{
		g_hSnap = g_hData.Snapshot();
		g_bValidData = true;
	}

	delete hFile;
}

// "Linear Space" model to maximize RNG.


// ====================================================================================================
// DETOURS
// ====================================================================================================
MRESReturn SelectModelByPopulation(DHookReturn hReturn, DHookParam hParams)
{
	if( !g_bValidData ) return MRES_Ignored;

	// Vars
	static char sPlace[64], usedKey[64];
	StringMap aMap;

	// NavArea name
	DHookGetParamString(hParams, 1, sPlace, sizeof(sPlace));

	#if DEBUG_PRINT
	PrintToServer("##### Population: Entry [%s]", sPlace);
	#endif
    
    // Match "NavArea place names" or "default" section
    if (g_hData.ContainsKey(sPlace)) usedKey = sPlace;
    else usedKey = "default";
    
	if( g_hData.GetValue(usedKey, aMap) )
	{
		if( aMap ) // Ignore sections that have no data, Special Infected sections etc (if they trigger)
		{
			// Get model name and chance to spawn
			int size = aMap.Size;

			if( size>0 )
			{
				// Vars
				float last = 101.0;
				float percent;
				// the floor needs to be 0.0. otherwise, if a given percent is less than 1.0, it will never be rolled due to the chance<=percent comparison.
				float chance = GetRandomFloat(0.0, 100.0);
				
				int index = -1;
				int num_fallen = -1;
				
				StringMapSnapshot aSnap = aMap.Snapshot();
				static char sModel[PLATFORM_MAX_PATH];

				// Loop models and chance
				// This was supposed to order from 100 to 0 chance.
				// But the "aSnap" is not ordered by index, so looping the whole list and using the "last" var to track the lowest valid percent
				for( int i = size - 1; i >= 0; i-- )
				{
					aSnap.GetKey(i, sModel, sizeof(sModel));
					aMap.GetValue(sModel, percent);
					if (size>1) // for sanity. if there is only one model in list, skip these checks.
					{
    					if (chance>percent || percent >= last) continue; // avoiding useless computation
					}
                    
                    // Prevent too many Fallen Survivors. They get automatically culled if we don't track the number of them on field.
					if( strncmp(sModel,"models/infected/common_male_fallen",34)==0 || strncmp(sModel,"models/infected/common_male_parachutist",39)==0 )
					{
						if (g_iCvarFallenCount<=0) continue; // no fallen allowed
						if (num_fallen<0) num_fallen = count_fallen();
  						if (num_fallen>=g_iCvarFallenCount) continue;
					}
					
					// PrintToServer("##### LIST %d %d %s", i, percent, sModel);
					index = i;
					last = percent;
					#if DEBUG_PRINT
					PrintToServer("##### Population: Index: %d Chance: %d/%d/%d [%s]", i, chance, percent, last, sModel);
					#endif
				}

				// Override model
				if( index != -1 )
				{
					aSnap.GetKey(index, sModel, sizeof(sModel));
					delete aSnap;

					#if DEBUG_PRINT
					PrintToServer("##### Population: Selected [%s]", sModel);
					#endif
					#if DEBUG_STATS
					int model_count = 0;
					if (g_hModelStats.ContainsKey(sModel)) g_hModelStats.GetValue(sModel,model_count);
					model_count += 1;
					g_hModelStats.SetValue(sModel,model_count);
					#endif

					hReturn.SetString(sModel);
					return MRES_Supercede;
				}
				#if DEBUG_PRINT
				else
				{
					PrintToServer("##### Selection failed: Chance %d/%d. Size: %d", chance, percent, size);
				}
				#endif

				delete aSnap;
			}
		}
	}

	return MRES_Ignored;
}

int count_fallen()
{
    int count = 0;
    int target = INVALID_ENT_REFERENCE;
    //static char sModel[PLATFORM_MAX_PATH];
    int gender;
  	while( (target = FindEntityByClassname(target, "infected")) != INVALID_ENT_REFERENCE )
  	{
      	//GetEntPropString(target,Prop_Data,"m_ModelName",sModel,sizeof(sModel));
      	gender = GetEntProp(target, Prop_Send, "m_Gender");
      	//LogMessage("%s %d", sModel, gender);
      	if( gender == TYPE_FALLEN )
          	count++;
      	if( count >= g_iCvarFallenCount )
      	{
          	break;
      	}
  	}
    return count;
}

#if DEBUG_STATS
Action CmdStats(int client, int args)
{
	int size = g_hModelStats.Size;
	if (size<=0) return Plugin_Handled;
	StringMapSnapshot aSnap = g_hModelStats.Snapshot();
	int count, total;
	float percent;
	static char sModel[PLATFORM_MAX_PATH];
	for (int i = 0; i < size; i++) // Get total first.
	{
    	aSnap.GetKey(i,sModel,sizeof(sModel));
    	g_hModelStats.GetValue(sModel,count);
    	total += count;
	}
	LogMessage("Statistics:");
	for (int i = 0; i < size; i++)
	{
    	aSnap.GetKey(i,sModel,sizeof(sModel));
    	g_hModelStats.GetValue(sModel,count);
    	percent = 100.0*count/total;
    	LogMessage("%s %d %f %%%", sModel, count, percent);
	}
	delete aSnap;
	return Plugin_Handled;
}
#endif

/*
// Uncommon infected trigger here when spawning
MRESReturn Infected_Spawn(int pThis, DHookReturn hReturn)
{
	int type = GetEntProp(pThis, Prop_Send, "m_Gender");

	switch( type )
	{
		case TYPE_CEDA:
		case TYPE_MUD_MEN:
		case TYPE_ROAD_WORKER:
		case TYPE_FALLEN:
		case TYPE_RIOT:
		case TYPE_CLOWN:
		case TYPE_JIMMY_GIBBS:
	}

	return MRES_Ignored;
}
*/