/**
 * vim: set ts=4 :
 * =============================================================================
 * Themes by J-Factor
 * Dynamically change the theme of maps! Enjoy a dark night, sweeping storm or a
 * frosty blizzard without being forced to download another map. Modifiable
 * attributes include the skybox, lighting, fog, particles, soundscapes and
 * color correction.
 * 
 * Credits:
 *			CrimsonGT				Environmental Tools plugin
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
/* PREPROCESSOR ***************************************************************/
#pragma semicolon 1

/* INCLUDES *******************************************************************/
#include <sourcemod>
#include <sdktools>
#include <colors>

/* CONSTANTS ******************************************************************/

// Plugin ----------------------------------------------------------------------
#define PLUGIN_NAME		"Themes"
#define PLUGIN_AUTHOR	"J-Factor"
#define PLUGIN_DESC		"Dynamically change the theme of maps!"
#define PLUGIN_VERSION	"0.8"
#define PLUGIN_URL		"http://j-factor.com/"

// Debug -----------------------------------------------------------------------
// #define DEBUG		1 

// Configs ---------------------------------------------------------------------
#define CONFIG_MAPS 		"configs/themes/maps.cfg"
#define CONFIG_THEMES		"configs/themes/themes.cfg"
#define CONFIG_THEMESETS	"configs/themes/themesets.cfg"

// Particles -------------------------------------------------------------------
#define NUM_PARTICLE_FILES	500 // Note: This can never be changed as clients
								// can't redownload the particle manifests

// General ---------------------------------------------------------------------
#define MAX_STAGES		8  // Maximum number of stages in a given map
#define MAX_THEMES		32 // Maximum number of themes in a given map

#define TEAM_RED		2
#define TEAM_BLU		3

#define STYLE_RANDOM	0
#define STYLE_TIME		1

/* VARIABLES ******************************************************************/

// Convars ---------------------------------------------------------------------
new Handle:cvPluginEnable  = INVALID_HANDLE;
new Handle:cvNextTheme	   = INVALID_HANDLE;
new Handle:cvAnnounce	   = INVALID_HANDLE;
new Handle:cvParticles     = INVALID_HANDLE;

// Plugin ----------------------------------------------------------------------
new bool:pluginEnabled = false;
new Handle:pluginTimer = INVALID_HANDLE;

// Key Values ------------------------------------------------------------------
new Handle:kvMaps = INVALID_HANDLE;
new Handle:kvThemes = INVALID_HANDLE;
new Handle:kvThemeSets = INVALID_HANDLE;

// General ---------------------------------------------------------------------
new currentStage = 0; // The current stage of the map
new numStages = 0;    // The number of stages defined for the theme

new Handle:windTimer = INVALID_HANDLE;

// Map Attributes --------------------------------------------------------------
new String:map[64];

// Theme
new String:mapTheme[32];
new String:mapTag[32];

// Skybox
new String:mapSkybox[32];
new mapSkyboxFogColor;
new Float:mapSkyboxFogStart;
new Float:mapSkyboxFogEnd;

// Fog
new String:mapFogColor[16];
new Float:mapFogStart;
new Float:mapFogEnd;
new Float:mapFogDensity;

// Particles
new String:mapParticle[64];
new Float:mapParticleHeight;

// Soundscape
new String:mapSoundscapeInside[32];
new String:mapSoundscapeOutside[32];

// Lighting, Bloom & Color Correction
new String:mapLighting[32];
new Float:mapBloom;
new String:mapColorCorrection1[64];
new String:mapColorCorrection2[64];

// Misc
new String:mapDetailSprites[32];
new bool:mapNoSun;
new bool:mapBigSun;
new bool:mapWind;
new bool:mapNoParticles;
new bool:mapIndoors;
new String:mapOverlay[32];

// Map Region
new bool:mapEstimateRegion;
new Float:mapX1[MAX_STAGES], Float:mapX2[MAX_STAGES],
	Float:mapY1[MAX_STAGES], Float:mapY2[MAX_STAGES],
	Float:mapZ[MAX_STAGES];
	
// Extra
new mapCCEntity1;
new mapCCEntity2;

// Theme -----------------------------------------------------------------------
new String:themes[MAX_THEMES][32];

// Time Period
new themeStart[MAX_THEMES];
new themeDuration[MAX_THEMES];

// Random Chance
new Float:themeChance[MAX_THEMES]; // Chance for each theme

// Number of themes defined for the current map
new numThemes = 0;

// Number of themes that do not have a chance defined for them
new numUnknownChanceThemes = 0;

// Total chance for all themes that have a chance defined
new Float:totalChance = 0.0;

// Theme selection style
new selectionStyle = STYLE_RANDOM;
	
/* PLUGIN *********************************************************************/
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

/* METHODS ********************************************************************/

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Confirm this is TF2
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (!StrEqual(strModName, "tf")) SetFailState("This plugin is TF2 only.");

	// Convars
	CreateConVar("sm_themes_version", PLUGIN_VERSION, "Themes version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvPluginEnable = CreateConVar("sm_themes_enable", "1", "Enables Themes", FCVAR_PLUGIN);
	cvNextTheme = 	 CreateConVar("sm_themes_next_theme", "", "Forces the next map to use the given theme", FCVAR_PLUGIN);
	cvAnnounce =     CreateConVar("sm_themes_announce", "1", "Whether or not to announce the current theme", FCVAR_PLUGIN);
	cvParticles =    CreateConVar("sm_themes_particles", "1", "Enables or disables custom particles for themes", FCVAR_PLUGIN);

	HookConVarChange(cvPluginEnable, Event_EnableChange);
	HookConVarChange(cvNextTheme, Event_NextThemeChange);

	// Configuration
	kvMaps = CreateKeyValues("Maps");
	kvThemes = CreateKeyValues("Themes");
	kvThemeSets = CreateKeyValues("Themesets");
	
	// Translations
	LoadTranslations("themes.phrases");

	// Execute main config
	AutoExecConfig(true, "themes");

	// Initialize
	Initialize(GetConVarBool(cvPluginEnable));
}

/* Event_EnableChange()
**
** When the plugin is enabled/disabled.
** -------------------------------------------------------------------------- */
public Event_EnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Initialize(strcmp(newValue, "1") == 0);
}

/* Initialize()
**
** Initializes the plugin.
** -------------------------------------------------------------------------- */
public Initialize(bool:enable)
{
	if (enable && !pluginEnabled) {
		// Enable!
		HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_win", Event_RoundEnd);
		HookEvent("teamplay_round_stalemate", Event_RoundEnd);
		HookEvent("player_team", Event_PlayerTeam);
	
		pluginTimer = CreateTimer(10.0, Timer_Plugin, INVALID_HANDLE, TIMER_REPEAT);
		windTimer = CreateTimer(0.2, Timer_Wind, INVALID_HANDLE, TIMER_REPEAT);
		pluginEnabled = true;
		
		CPrintToChatAll("%t", "Plugin_Enable", PLUGIN_NAME);
	} else if (!enable && pluginEnabled) {
		// Disable!
		UnhookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_win", Event_RoundEnd);
		UnhookEvent("teamplay_round_stalemate", Event_RoundEnd);
		UnhookEvent("player_team", Event_PlayerTeam);
		
		KillTimer(pluginTimer);
		KillTimer(windTimer);
		pluginEnabled = false;
		
		CPrintToChatAll("%t", "Plugin_Disable", PLUGIN_NAME);
	}
}

/* Event_NextThemeChange()
**
** When the next theme is changed.
** -------------------------------------------------------------------------- */
public Event_NextThemeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, "")) {
		decl String:nextTheme[32];
		decl String:nextTag[32];

		if (KvJumpToKey(kvThemes, newValue)) {
			KvGetString(kvThemes, "name", nextTheme, sizeof(nextTheme), "Unnamed Theme");
			KvGetString(kvThemes, "tag", nextTag, sizeof(nextTag), "{olive}");
		
			KvGoBack(kvThemes);
			
			if (GetConVarBool(cvAnnounce)) {
				CPrintToChatAll("%t", "Announce_NextTheme", nextTag, nextTheme);
			}
		}
	}
}
/* Timer_Wind()
**
** Timer for moving ropes, simulating wind. Called every 0.2s.
** ------------------------------------------------------------------------- */
public Action:Timer_Wind(Handle:timer)
{
	// Apply Wind
	if (mapWind) {
		new ent = -1;
		
		while ((ent = FindEntityByClassname(ent, "move_rope")) != -1) {
			decl String:force[32];
			Format(force, sizeof(force), "-%d -%d 0", GetRandomInt(300, 1000), GetRandomInt(300, 1000));
			
			SetVariantString(force);
			AcceptEntityInput(ent, "SetForce");
		}
		
		ent = -1;
		
		while ((ent = FindEntityByClassname(ent, "keyframe_rope")) != -1) {
			decl String:force[32];
			Format(force, sizeof(force), "-%d -%d 0", GetRandomInt(300, 1000), GetRandomInt(300, 1000));
			
			SetVariantString(force);
			AcceptEntityInput(ent, "SetForce");
		}
	}
}

/* Timer_Plugin()
**
** Timer for general plugin fixes. Called every 10s.
** ------------------------------------------------------------------------- */
public Action:Timer_Plugin(Handle:timer)
{
	// Possible fix for some players not seeing color correction at times?
	if (IsValidEntity(mapCCEntity1)) {
		DispatchKeyValue(mapCCEntity1, "filename", mapColorCorrection1);
	}
	if (IsValidEntity(mapCCEntity2)) {
		DispatchKeyValue(mapCCEntity2, "filename", mapColorCorrection2);
	}
}

/* OnMapStart()
**
** When the a map starts.
** -------------------------------------------------------------------------- */
public OnMapStart()
{
	if (pluginEnabled) {
		// Initializes the configuration
		InitConfig();
		
		// Loads the new configuration
		if (LoadConfig()) {
			// Updates the downloads table
			UpdateDownloadsTable();
			
			// Log the theme values
			LogTheme();
			
			// Applys the loaded configuration for the map
			ApplyConfigMap();
			
			// Applys the loaded configuration for the current round
			ApplyConfigRound();
		}
	}
}

/* InitConfig()
**
** Initializes the configuration, resetting the previous map attributes.
** -------------------------------------------------------------------------- */
InitConfig()
{
	decl String:file[128];
	
	// Load the Maps config
	BuildPath(Path_SM, file, sizeof(file), CONFIG_MAPS);
	FileToKeyValues(kvMaps, file);
	
	// Load the Themes config
	BuildPath(Path_SM, file, sizeof(file), CONFIG_THEMES);
	FileToKeyValues(kvThemes, file);
	
	// Load the Themesets config
	BuildPath(Path_SM, file, sizeof(file), CONFIG_THEMESETS);
	FileToKeyValues(kvThemeSets, file);

	// Reset the map attributes
	map = "";
	
	mapTheme = "Default";
	mapTag = "{olive}";
	
	// Skybox
	mapSkybox[0]      = '\0';
	mapSkyboxFogColor = -1;
	mapSkyboxFogStart = -1.0;
	mapSkyboxFogEnd	  = -1.0;
	
	// Fog
	mapFogColor[0] = '\0';
	mapFogStart	   = -1.0;
	mapFogEnd	   = -1.0;
	mapFogDensity  = -1.0;
	
	// Particles
	mapParticle[0]	   = '\0';
	mapParticleHeight  = 800.0;
	
	// Soundscape
	mapSoundscapeInside[0]  = '\0';
	mapSoundscapeOutside[0] = '\0';
	
	// Lighting, Bloom & Color Correction
	mapLighting[0] = '\0';
	mapBloom 	   = -1.0;
	mapColorCorrection1[0] = '\0';
	mapColorCorrection2[0] = '\0';
	
	// Misc
	mapDetailSprites[0] = '\0';
	mapNoSun  = false;
	mapBigSun = false;
	mapWind   = false;
	mapNoParticles = false;
	mapIndoors = false;
	mapOverlay[0] = '\0';
	
	// Region
	numStages = 0;
	mapEstimateRegion = true;
	
	for (new i = 0; i < MAX_STAGES; i++) {
		mapX1[i] = 0.0;
		mapX2[i] = 0.0;
		mapY1[i] = 0.0;
		mapY2[i] = 0.0;
		mapZ[i] = 0.0;
	}
	
	// Reset etc
	numThemes = 0;
	numUnknownChanceThemes = 0;
	totalChance = 0.0;
	selectionStyle = STYLE_RANDOM;
}

/* LoadConfig()
**
** Loads the new configuration.
** -------------------------------------------------------------------------- */
public bool:LoadConfig()
{
	decl String:themeConvar[64];
    
	// Read the map name and check if it's in the config
	GetCurrentMap(map, sizeof(map));
    
    // Check if we should load a specific theme or randomly select one
	GetConVarString(cvNextTheme, themeConvar, sizeof(themeConvar));
	
	if (KvJumpToKey(kvMaps, map)) {
		// Map is defined in the config
		decl String:themeSet[32];
		
		// Read ThemeSet
		KvGetString(kvMaps, "themeset", themeSet, sizeof(themeSet), "");
		
		// Check if the map is using a ThemeSet
		if (!StrEqual(themeSet, "")) {
			if (KvJumpToKey(kvThemeSets, themeSet)) {
				// Read all themes in ThemeSet
				ReadThemeSet(kvThemeSets);
				
				KvGoBack(kvThemeSets);
			}
		} else {
			// Treat map config as ThemeSet and read all themes
			ReadThemeSet(kvMaps);
		}
		
		// Read Map Region
		ReadMapRegion(kvMaps);
		
		// Read Theme
		if (!StrEqual(themeConvar, "")) {
			// Use theme convar
			ReadTheme(themeConvar);
			
			// Check if this theme is defined for the map
			for (new i = 0; i < numThemes; i++) {
				if (StrEqual(themes[i], themeConvar)) {
					// Read custom attributes for this theme that are specific to this map
					ReadThemeAttributesNumber(kvMaps, i);
					
					break;
				}
			}
			
			// Reset theme convar
			SetConVarString(cvNextTheme, "");
		} else if (selectionStyle == STYLE_TIME) {
			// Time period for themes
			new i, j = 0;
			
			for (i = 0; i < numThemes; i++) {
				if (themeDuration[i] == 0) {
					j = i;
					continue;
				}
				
				new time = GetTimeOfDay();
				
				if (time < themeStart[i]) {
					time += (24 * 60 * 60) - themeStart[i];
				} else {
					time -= themeStart[i];
				}
				
				if (time <= themeDuration[i]) {
					ReadTheme(themes[i]);
					ReadThemeAttributesNumber(kvMaps, i);

					break;
				}
			}
			
			if (i == numThemes) {
				ReadTheme(themes[j]);
				ReadThemeAttributesNumber(kvMaps, j);
			}
		} else {
			// Random chance for themes
			new Float:randomNum = GetRandomFloat();
			
			for (new i = 0; i < numThemes; i++) {
				// If a chance hasn't been defined for this theme divide the remaining undefined chance equally
				if (themeChance[i] == -1.0) {
					themeChance[i] = (1.0 - totalChance)/numUnknownChanceThemes;
				}
				
				if (randomNum <= themeChance[i]) {
					ReadTheme(themes[i]);
					ReadThemeAttributesNumber(kvMaps, i);

					break;
				}
				
				randomNum -= themeChance[i];
			}
		}
		
		// Read custom attributes for all themes that are specific to this map
		ReadThemeAttributes(kvMaps);
		
		// Reset theme convar
		SetConVarString(cvNextTheme, "");
		
		// Go back
		KvGoBack(kvMaps);
		
		return true;
	} else {
		// Reset theme convar
		SetConVarString(cvNextTheme, "");
		
		return false;
	}
}

/* ReadThemeSet()
**
** Reads a ThemeSet from the current position in the given KeyValues.
** -------------------------------------------------------------------------- */
ReadThemeSet(Handle:kv)
{
	decl String:style[16];
	new String:key[8] = "theme1"; 
	
	// Read the Theme Selection Style
	KvGetString(kv, "style", style, sizeof(style), "");
	
	if (StrEqual(style, "random")) {
		selectionStyle = STYLE_RANDOM;
	} else if (StrEqual(style, "time")) {
		selectionStyle = STYLE_TIME;
	}
	
	// Find each theme
	while (KvJumpToKey(kv, key)) {
		decl String:time[6];
		
		// Read Theme Name
		KvGetString(kvThemeSets, "theme", themes[numThemes], 32, "");
		
		// Read Time Period
		KvGetString(kvThemeSets, "start", time, sizeof(time), "");
		themeStart[numThemes] = StringToTimeOfDay(time);
		
		KvGetString(kvThemeSets, "end", time, sizeof(time), "");
		themeDuration[numThemes] = StringToTimeOfDay(time);
		
		if (themeDuration[numThemes] < themeStart[numThemes]) {
			themeDuration[numThemes] += 86400 - themeStart[numThemes];
		}
		
		// Read Random Chance
		themeChance[numThemes] = KvGetFloat(kvThemeSets, "chance", -1.0);
		
		if (themeChance[numThemes] != -1.0) {
			totalChance += themeChance[numThemes];
		} else {
			numUnknownChanceThemes++;
		}
		
		KvGoBack(kvThemeSets);
		
		// Check for next theme
		Format(key, sizeof(key), "theme%i", ++numThemes + 1);
	}
}

/* ReadMapRegion()
**
** Reads the map region.
** -------------------------------------------------------------------------- */
ReadMapRegion(Handle:kv)
{
	if (KvJumpToKey(kv, "region")) {
		mapEstimateRegion = false;
	
		// Read the region for each stage of the map
		for (new i = 0; i < MAX_STAGES; i++) {
			decl String:stage[8];
			Format(stage, sizeof(stage), "stage%i", i + 1);
			
			if (KvJumpToKey(kv, stage)) {
				new Float:n1, Float:n2;
				
				n1 = KvGetFloat(kv, "x1", 0.0);
				n2 = KvGetFloat(kv, "x2", 0.0);
				
				if (n1 > n2) {
					mapX1[i] = n2;
					mapX2[i] = n1;
				} else {
					mapX1[i] = n1;
					mapX2[i] = n2;
				}
				
				n1 = KvGetFloat(kv, "y1", 0.0);
				n2 = KvGetFloat(kv, "y2", 0.0);
				
				if (n1 > n2) {
					mapY1[i] = n2;
					mapY2[i] = n1;
				} else {
					mapY1[i] = n1;
					mapY2[i] = n2;
				}
				
				mapZ[i] = KvGetFloat(kv, "z", 0.0);
				
				numStages++;
				
				KvGoBack(kv);
			}
		}
		
		KvGoBack(kv);
	}
}

/* ReadTheme()
**
** Reads a theme.
** -------------------------------------------------------------------------- */
ReadTheme(String:theme[])
{
	if (KvJumpToKey(kvThemes, theme)) {
		// Read Name
		KvGetString(kvThemes, "name", mapTheme, sizeof(mapTheme), "Unnamed Theme");
		
		// Read Tag
		KvGetString(kvThemes, "tag", mapTag, sizeof(mapTag), mapTag);
		
		// Read Attributes
		ReadThemeAttributes(kvThemes);
		
		KvGoBack(kvThemes);
	}
}

/* ReadThemeAttributesNumber()
**
** Jumps to the key holding the given theme number and reads theme attributes.
** -------------------------------------------------------------------------- */
ReadThemeAttributesNumber(Handle:kv, num)
{
	decl String:key[8];
	
	Format(key, sizeof(key), "theme%i", num + 1);
	
	if (KvJumpToKey(kv, key)) {
		ReadThemeAttributes(kv);
		KvGoBack(kv);
	}
}

/* ReadThemeAttributes()
**
** Reads theme attributes from the current position in the given KeyValues.
** -------------------------------------------------------------------------- */
ReadThemeAttributes(Handle:kv)
{
	// Read Skybox
	if (KvJumpToKey(kv, "skybox")) {
		KvGetString(kv, "name", mapSkybox, sizeof(mapSkybox), mapSkybox);
		
		// Read Skybox Fog
		if (KvJumpToKey(kv, "fog")) {
			decl String:skyboxFogColor[16];
			
			// Read Skybox Fog Color
			// Note: We need an integer for this as we directly send the prop
			// value to players
			KvGetString(kv, "color", skyboxFogColor, sizeof(skyboxFogColor), "");
			
			if (!StrEqual(skyboxFogColor, "")) {
				decl String:buffers[3][8];
				new num = ExplodeString(skyboxFogColor, " ", buffers, 3, 8);
				
				if (num == 3) {
					mapSkyboxFogColor = StringToInt(buffers[0]) | StringToInt(buffers[1]) << 8 | StringToInt(buffers[2]) << 16;
				}
			}
			
			// Read Skybox Fog Start
			mapSkyboxFogStart = KvGetFloat(kv, "start", mapSkyboxFogStart);
			
			// Read Skybox Fog End
			mapSkyboxFogEnd = KvGetFloat(kv, "end", mapSkyboxFogEnd);
			
			KvGoBack(kv);
		}

		KvGoBack(kv);
	}
	
	// Read Fog
	if (KvJumpToKey(kv, "fog")) {
		// Read Fog Color
		KvGetString(kv, "color", mapFogColor, sizeof(mapFogColor), mapFogColor);
		
		// Read Fog Start
		mapFogStart = KvGetFloat(kv, "start", mapFogStart);
		
		// Read Fog End
		mapFogEnd = KvGetFloat(kv, "end", mapFogEnd);
		
		// Read Fog Density
		mapFogDensity = KvGetFloat(kv, "density", mapFogDensity);
		
		KvGoBack(kv);
	}
	
	// Read Particles
	if (KvJumpToKey(kv, "particles")) {
		// Read Particle Name
		KvGetString(kv, "name", mapParticle, sizeof(mapParticle), mapParticle);
		
		// Read Particle Height
		mapParticleHeight = KvGetFloat(kv, "height", mapParticleHeight);
		
		KvGoBack(kv);
	}
	
	// Read Soundscape
	if (KvJumpToKey(kv, "soundscape")) {
		// Read Inside Soundscape
		KvGetString(kv, "inside", mapSoundscapeInside, sizeof(mapSoundscapeInside), mapSoundscapeInside);
		
		// Read Outside Soundscape
		KvGetString(kv, "outside", mapSoundscapeOutside, sizeof(mapSoundscapeOutside), mapSoundscapeOutside);
		
		KvGoBack(kv);
	}
	
	// Read Lighting
	KvGetString(kv, "lighting", mapLighting, sizeof(mapLighting), mapLighting);

	// Read Bloom
	mapBloom = KvGetFloat(kv, "bloom", mapBloom);
	
	// Read Color Correction
	KvGetString(kv, "color1", mapColorCorrection1, sizeof(mapColorCorrection1), mapColorCorrection1);
	KvGetString(kv, "color2", mapColorCorrection2, sizeof(mapColorCorrection2), mapColorCorrection2);
	
	// Read Detail Sprites
	KvGetString(kv, "detail", mapDetailSprites, sizeof(mapDetailSprites), mapDetailSprites);
	
	// Read No Sun
	mapNoSun = (KvGetNum(kv, "nosun", mapNoSun) == 1);
	
	// Read Big Sun
	mapBigSun = (KvGetNum(kv, "bigsun", mapBigSun) == 1);
	
	// Read Wind
	mapWind = (KvGetNum(kv, "wind", mapWind) == 1);
	
	// Read No Particles
	mapNoParticles = (KvGetNum(kv, "noparticles", mapNoParticles) == 1);
	
	// Read Indoors
	mapIndoors = (KvGetNum(kv, "indoors", mapIndoors) == 1);
	
	// Read Overlay
	KvGetString(kv, "overlay", mapOverlay, sizeof(mapOverlay), mapOverlay);
}

/* UpdateDownloadsTable()
**
** Updates the downloads table.
** -------------------------------------------------------------------------- */
UpdateDownloadsTable()
{
	decl String:filename[96];
	
	// Handle Particles
	if (GetConVarBool(cvParticles)) {
		HandleParticleFiles();
		
		AddFileToDownloadsTable("materials/particles/themes_leaf.vmt");
		AddFileToDownloadsTable("materials/particles/themes_leaf.vtf");
	}
	
	// Handle Color Correction
	if (!StrEqual(mapColorCorrection1, "")) {
		Format(filename, sizeof(filename), "materials/correction/%s", mapColorCorrection1);
		AddFileToDownloadsTable(filename);
	}
	
	if (!StrEqual(mapColorCorrection2, "")) {
		Format(filename, sizeof(filename), "materials/correction/%s", mapColorCorrection2);
		AddFileToDownloadsTable(filename);
	}
}

/* HandleParticleFiles()
**
** Handles custom particle files.
** -------------------------------------------------------------------------- */
HandleParticleFiles()
{
	decl String:file[96];
	
	// Add ALL map particle manifest files (due to waffle bug)
	if (KvGotoFirstSubKey(kvMaps)) {
		do {
			KvGetSectionName(kvMaps, file, sizeof(file));
			Format(file, sizeof(file), "maps/%s_particles.txt", file);
	
			if (!FileExists(file)) {
				LogMessage("Error: Particles file does not exist: %s", file);
			} else {
				AddFileToDownloadsTable(file);
			}
		} while (KvGotoNextKey(kvMaps));
		
		KvGoBack(kvMaps);
	}
	
	// Add particle files
	for (new i = 1; i <= NUM_PARTICLE_FILES; i++) {
		Format(file, sizeof(file), "particles/custom_particles%03i.pcf", i);
	
		if (FileExists(file)) {
			AddFileToDownloadsTable(file);
		}
	}
}

/* ApplyConfigMap()
**
** Applys the loaded configuration to the current map. Not all attributes can be
** applied here. Some must be reapplied every round start.
** -------------------------------------------------------------------------- */
ApplyConfigMap()
{
	new ent;
	decl String:detailMaterial[48];
	
	// Apply Skybox
	if (!StrEqual(mapSkybox, "")) {
		DispatchKeyValue(0, "skyname", mapSkybox);
	}
	
	// Apply Fog
	ent = FindEntityByClassname(-1, "env_fog_controller");
	
	if (ent != -1) {
		// Apply Fog Color
		if (!StrEqual(mapFogColor, "")) {
			DispatchKeyValue(ent, "fogblend", "0");
			DispatchKeyValue(ent, "fogcolor", mapFogColor);
		}
		
		// Apply Fog Start
		if (mapFogStart != -1.0) {
			DispatchKeyValueFloat(ent, "fogstart", mapFogStart);
		}
		
		// Apply Fog End
		if (mapFogEnd != -1.0) {
			DispatchKeyValueFloat(ent, "fogend", mapFogEnd);
		}
		
		// Apply Fog Density
		if (mapFogDensity != -1.0) {
			DispatchKeyValueFloat(ent, "fogmaxdensity", mapFogDensity);
		}
	}
	
	// Apply Indoors
	if (mapIndoors) {
		strcopy(mapSoundscapeInside, sizeof(mapSoundscapeInside), mapSoundscapeOutside);
	}
	
	// Apply No Particles
	if (mapNoParticles) {
		new bool:p = false;
		ent = -1;
		decl String:targetname[64];
		
		while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1) {
			GetEntPropString(ent, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
			if ((StrContains(targetname, "particle_rain") != -1) ||
					(StrContains(targetname, "particle_snow") != -1) ||
					(StrContains(targetname, "particle_waterdrops") != -1)) {
				AcceptEntityInput(ent, "Kill");
				p = true;
			}
		}
		
		// Check if we removed any particles
		if (p) {
			// Change the soundscape to stop rain sounds with no rain particles
			if (StrEqual(mapSoundscapeInside, "")) {
				mapSoundscapeInside = "Lumberyard.Inside";
			}
			
			if (StrEqual(mapSoundscapeOutside, "")) {
				mapSoundscapeOutside = "Lumberyard.Outside";
			}
		}
	}

	// Apply Soundscape
	if (!StrEqual(mapSoundscapeInside, "") || !StrEqual(mapSoundscapeOutside, "")) {
		ApplySoundscape();
	}
	
	// Apply Lighting
	if (!StrEqual(mapLighting, "")) {
		SetLightStyle(0, mapLighting);
	}
	
	// Apply Detail Sprites
	if (!StrEqual(mapDetailSprites, "")) {
		Format(detailMaterial, sizeof(detailMaterial), "detail/detailsprites_%s", mapDetailSprites);
		DispatchKeyValue(0, "detailmaterial", detailMaterial);
	}
	
	
	// Remove old Overlay
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "env_screenoverlay")) != -1) {
		AcceptEntityInput(ent, "Kill");
	}
	
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for (ent = 1; ent <= MaxClients; ent++) {
		if (IsClientInGame(ent)) {
			ClientCommand(ent, "r_screenoverlay \"\"");
		}
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
	
	// Apply Overlay
	if (!StrEqual(mapOverlay, "")) {
		ent = CreateEntityByName("env_screenoverlay");
		
		if (IsValidEntity(ent)) {
			DispatchKeyValue(ent, "OverlayName1", mapOverlay);

			SetVariantString("OnUser1 !self,StartOverlays");
			AcceptEntityInput(ent, "AddOutput");

			SetVariantString("OnUser1 !self,FireUser1,,1");
			AcceptEntityInput(ent, "AddOutput");

			AcceptEntityInput(ent, "FireUser1");
		}
	}
	
	// Estimate Map Region
	if (mapEstimateRegion) {
		EstimateMapRegion();
	}
	
	// Init Color Correction
	if (!StrEqual(mapColorCorrection1, "")) {
		Format(mapColorCorrection1, sizeof(mapColorCorrection1), "materials/correction/%s", mapColorCorrection1);
	}
	
	if (!StrEqual(mapColorCorrection2, "")) {
		Format(mapColorCorrection2, sizeof(mapColorCorrection2), "materials/correction/%s", mapColorCorrection2);
	}
}

/* ApplySoundscape()
**
** Applies the Soundscape to the map.
** -------------------------------------------------------------------------- */
ApplySoundscape()
{
	new ent = -1;
	new proxy = -1;
	new scape = -1;
	decl Float:org[3];
	decl String:target[32];
	
	// Find all soundscape proxies and determine if they're inside or outside
	while ((ent = FindEntityByClassname(ent, "env_soundscape_proxy")) != -1) {
		proxy = GetEntDataEnt2(ent, FindDataMapOffs(ent, "m_hProxySoundscape"));
		
		if (proxy != -1) {
			GetEntPropString(proxy, Prop_Data, "m_iName", target, sizeof(target));
			
			if ((StrContains(target, "inside", false) != -1) || (StrContains(target, "indoor", false) != -1) ||
					(StrContains(target, "outside", false) != -1) || (StrContains(target, "outdoor", false) != -1)) {
				// Create new soundscape using loaded attributes
				scape = CreateEntityByName("env_soundscape");

				if (IsValidEntity(scape)) {
					GetEntPropVector(ent, Prop_Data, "m_vecOrigin", org);
					TeleportEntity(scape, org, NULL_VECTOR, NULL_VECTOR);
					
					DispatchKeyValueFloat(scape, "radius", GetEntDataFloat(ent, FindDataMapOffs(ent, "m_flRadius")));
					
					if ((StrContains(target, "inside", false) != -1) || (StrContains(target, "indoor", false) != -1)) {
						DispatchKeyValue(scape, "soundscape", mapSoundscapeInside);
						DispatchKeyValue(scape, "targetname", mapSoundscapeInside);
					} else if ((StrContains(target, "outside", false) != -1) || (StrContains(target, "outdoor", false) != -1)) {
						DispatchKeyValue(scape, "soundscape", mapSoundscapeOutside);
						DispatchKeyValue(scape, "targetname", mapSoundscapeOutside);
					}
					
					DispatchSpawn(scape);
				}
			}
		}
		
		AcceptEntityInput(ent, "Kill");
	}
	
	// Do the same to normal soundscapes
	while ((ent = FindEntityByClassname(ent, "env_soundscape")) != -1) {
		GetEntPropString(ent, Prop_Data, "m_iName", target, sizeof(target));
		
		if (!StrEqual(target, mapSoundscapeInside) && !StrEqual(target, mapSoundscapeOutside)) {
			scape = CreateEntityByName("env_soundscape");
		
			if (IsValidEntity(scape)) {
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", org);
				TeleportEntity(scape, org, NULL_VECTOR, NULL_VECTOR);
				
				DispatchKeyValueFloat(scape, "radius", GetEntDataFloat(ent, FindDataMapOffs(ent, "m_flRadius")));
				
				if ((StrContains(target, "inside", false) != -1) || (StrContains(target, "indoor", false) != -1)) {
					DispatchKeyValue(scape, "soundscape", mapSoundscapeInside);
					DispatchKeyValue(scape, "targetname", mapSoundscapeInside);
				} else {
					DispatchKeyValue(scape, "soundscape", mapSoundscapeOutside);
					DispatchKeyValue(scape, "targetname", mapSoundscapeOutside);
				}
				
				DispatchSpawn(scape);
			}
		
			AcceptEntityInput(ent, "Kill");
		}
	}
}

/* ApplyConfigRound()
**
** Applys the loaded configuration to the current map. Not all attributes can be
** applied here. Some must be reapplied every round start.
** -------------------------------------------------------------------------- */
ApplyConfigRound()
{
	new ent;
	decl String:filename[96];
	
	// Apply No Particles
	if (mapNoParticles) {
		ent = -1;
		
		while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1) {
			GetEntPropString(ent, Prop_Data, "m_iName", filename, sizeof(filename));
			
			if ((StrContains(filename, "particle_rain") != -1) ||
					(StrContains(filename, "particle_snow") != -1) ||
					(StrContains(filename, "particle_waterdrops") != -1)) {
				AcceptEntityInput(ent, "Kill");
			}
		}
	}
	
	// Apply Indoors
	if (mapIndoors) {
		if (StrEqual(mapParticle, "env_themes_rain") ||
				StrEqual(mapParticle, "env_themes_rain_light") ||
				StrEqual(mapParticle, "env_themes_snow") ||
				StrEqual(mapParticle, "env_themes_snow_light") ||
				StrEqual(mapParticle, "env_themes_leaves")) {
			StrCat(mapParticle, sizeof(mapParticle), "_noclip");
		}
	}
	
	// Apply Particles
	if (GetConVarBool(cvParticles)) {
		CreateParticles();
	}
	
	// Apply Bloom
	if (mapBloom != -1.0) {
		ent = FindEntityByClassname(-1, "env_tonemap_controller");
		
		if (ent != -1) {
			SetVariantFloat(mapBloom);
			AcceptEntityInput(ent, "SetBloomScale");
		}
	}
	
	// Remove old Color Correction
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "color_correction")) != -1) {
		AcceptEntityInput(ent, "Kill");
	}
	
	// Apply Color Correction
	mapCCEntity1 = -1;
	if (!StrEqual(mapColorCorrection1, "")) {
		mapCCEntity1 = CreateEntityByName("color_correction");
		
		if (IsValidEntity(mapCCEntity1)) {
			DispatchKeyValue(mapCCEntity1, "maxweight", "1.0");
			DispatchKeyValue(mapCCEntity1, "maxfalloff", "-1");
			DispatchKeyValue(mapCCEntity1, "minfalloff", "0.0");
			DispatchKeyValue(mapCCEntity1, "filename", mapColorCorrection1);
			
			DispatchSpawn(mapCCEntity1);
			ActivateEntity(mapCCEntity1);
			AcceptEntityInput(mapCCEntity1, "Enable");
		}
	}
	
	mapCCEntity2 = -1;
	if (!StrEqual(mapColorCorrection2, "")) {
		mapCCEntity2 = CreateEntityByName("color_correction");
		
		if (IsValidEntity(mapCCEntity2)) {
			DispatchKeyValue(mapCCEntity2, "maxweight", "1.0");
			DispatchKeyValue(mapCCEntity2, "maxfalloff", "-1");
			DispatchKeyValue(mapCCEntity2, "minfalloff", "0.0");
			DispatchKeyValue(mapCCEntity2, "filename", mapColorCorrection2);
			
			DispatchSpawn(mapCCEntity2);
			ActivateEntity(mapCCEntity2);
			AcceptEntityInput(mapCCEntity2, "Enable");
		}
	}
	
	// Apply No Sun
	if (mapNoSun) {
		ent = -1;
		
		while ((ent = FindEntityByClassname(ent, "env_sun")) != -1) {
			AcceptEntityInput(ent, "Kill");
		}
		
		ent = -1;
		
		while ((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1) {
			decl String:model[128];
			
			GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
			
			if (StrEqual(model, "models/props_skybox/sunnoon.mdl")) {
				AcceptEntityInput(ent, "Kill");
			}
		}
	}
	
	// Apply Big Sun
	if (mapBigSun) {
		ent = CreateEntityByName("env_sun");
		
		if (IsValidEntity(ent)) {
			DispatchKeyValue(ent, "angles", "0 180 0");
			DispatchKeyValue(ent, "HDRColorScale", "2.0");
			DispatchKeyValue(ent, "material", "sprites/light_glow02_add_noz");
			DispatchKeyValue(ent, "overlaycolor", "57 73 87");
			DispatchKeyValue(ent, "overlaymaterial", "sprites/light_glow02_add_noz");
			DispatchKeyValue(ent, "overlaysize", "-1");
			DispatchKeyValue(ent, "pitch", "-45");
			DispatchKeyValue(ent, "rendercolor", "242 197 134");
			DispatchKeyValue(ent, "size", "100");
			DispatchKeyValue(ent, "use_angles", "1");
			
			DispatchSpawn(ent);
			ActivateEntity(ent);
			
			AcceptEntityInput(ent, "TurnOn");
		}
	}
}

/* CreateParticles()
**
** Creates particles around the map.
** -------------------------------------------------------------------------- */
CreateParticles()
{
	if (!StrEqual(mapParticle, "")) {
		// Remove old particles
		new ent = -1;
		new num = 0;
		
		while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1) {
			if (IsValidEntity(ent)) {
				decl String:name[32];
				
				GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
				
				if (StrContains(name, "themes_particle") != -1) {
					AcceptEntityInput(ent, "Kill");
				}
			}
		}
		
		/*ent = -1;
		
		while ((ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1) {
			if (IsValidEntity(ent)) {
				AcceptEntityInput(ent, "Kill");
			}
		}*/
		
		new x, y, nx, ny, Float:w, Float:h, Float:ox, Float:oy;
		
		w = mapX2[currentStage] - mapX1[currentStage];
		h = mapY2[currentStage] - mapY1[currentStage];
		
		nx = RoundToFloor(w/1024.0) + 1;
		ny = RoundToFloor(h/1024.0) + 1;
		
		ox = (((RoundToFloor(w/1024.0) + 1) * 1024.0) - w)/2;
		oy = (((RoundToFloor(h/1024.0) + 1) * 1024.0) - h)/2;
		
		for (x = 0; x < nx; x++) {
			for (y = 0; y < ny; y++) {
				new particle = CreateEntityByName("info_particle_system");

				// Check if it was created correctly
				if (IsValidEdict(particle)) {
					decl Float:pos[3];
					
					pos[0] = mapX1[currentStage] + x*1024.0 + 512.0 - ox;
					pos[1] = mapY1[currentStage] + y*1024.0 + 512.0 - oy;
					pos[2] = mapParticleHeight + mapZ[currentStage];
					
					// Teleport, set up
					TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
					DispatchKeyValue(particle, "effect_name", mapParticle);
					DispatchKeyValue(particle, "targetname", "themes_particle");
					
					// Spawn and start
					DispatchSpawn(particle);
					ActivateEntity(particle);
					AcceptEntityInput(particle, "Start");
					
					/*ent = CreateEntityByName("item_ammopack_full");
					TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(ent);
					ActivateEntity(ent);*/
				}
				
				num++;
				
				if (num > 64) {
					LogMessage("Error: Too many particles!");
					return;
				}
			}
		}
		
		LogMessage("Current stage: %i", currentStage);
		LogMessage("Created %i particles of type %s", num, mapParticle);
	}
}

/* EstimateMapRegion()
**
** Estimates the region of the map by finding the minimum and maximum position
** of entities. Only used for particles.
** -------------------------------------------------------------------------- */
EstimateMapRegion()
{
	if (!StrEqual(mapParticle, "")) {
		new maxEnts = GetMaxEntities();
		
		for (new i = MaxClients + 1; i <= maxEnts; i++) {
			if (!IsValidEntity(i)) continue;
			
			decl String:name[32];
			GetEntityNetClass(i, name, 32);
			
			if (FindSendPropOffs(name, "m_vecOrigin") != -1) {
				decl Float:pos[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
				
				if (pos[0] < mapX1[0]) {
					mapX1[0] = pos[0];
				}
				if (pos[0] > mapX2[0]) {
					mapX2[0] = pos[0];
				}
				
				if (pos[1] < mapY1[0]) {
					mapY1[0] = pos[1];
				}
				if (pos[1] > mapY2[0]) {
					mapY2[0] = pos[1];
				}
			}
		}
		
		for (new i = 1; i < MAX_STAGES; i++) {
			mapX1[i] = mapX1[0];
			mapX2[i] = mapX2[0];
			mapY1[i] = mapY1[0];
			mapY2[i] = mapY2[0];
		}
		
		LogMessage("Map region estimated: (%f, %f) to (%f, %f) [%f x %f]", mapX1[0], mapY1[0], mapX2[0], mapY2[0], mapX2[0] - mapX1[0], mapY2[0] - mapY1[0]);
	}
}

/* LogTheme()
**
** Prints all of the current theme's attributes.
** -------------------------------------------------------------------------- */
LogTheme()
{
	LogMessage("Loaded theme: %s", mapTheme);
	
	#if defined DEBUG
	LogMessage("Skybox: %s", mapSkybox);
	LogMessage("Skybox Fog Color: %d", mapSkyboxFogColor);
	LogMessage("Skybox Fog Start: %f", mapSkyboxFogStart);
	LogMessage("Skybox Fog End: %f", mapSkyboxFogEnd);
	
	LogMessage("Fog Color: %s", mapFogColor);
	LogMessage("Fog Start: %f", mapFogStart);
	LogMessage("Fog End: %f", mapFogEnd);
	LogMessage("Fog Density: %f", mapFogDensity);	
	
	LogMessage("Particles: %s", mapParticle);
	LogMessage("Particle Height: %f", mapParticleHeight);
	
	LogMessage("Soundscape Inside: %s", mapSoundscapeInside);
	LogMessage("Soundscape Outside: %s", mapSoundscapeOutside);
	
	LogMessage("Lighting: %s", mapLighting);
	LogMessage("Bloom: %f", mapBloom);
	LogMessage("Color Correction 1: %s", mapColorCorrection1);
	LogMessage("Color Correction 2: %s", mapColorCorrection2);
	
	LogMessage("Detail Sprites: %s", mapDetailSprites);
	LogMessage("No Sun: %d", mapNoSun);
	LogMessage("Big Sun: %d", mapBigSun);
	LogMessage("No Particles: %d", mapNoParticles);
	LogMessage("Indoors: %d", mapIndoors);
	LogMessage("Overlay: %s", mapOverlay);
	#endif
}

/* Event_RoundEnd()
**
** When a round ends.
** -------------------------------------------------------------------------- */
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (pluginEnabled) {
		// Check if a full round has completed
		if (GetEventInt(event, "full_round")) {
			currentStage = 0;
		} else if (currentStage < numStages - 1) {
			currentStage++;
		}
	}
	
	return Plugin_Continue;
}

/* Event_RoundStart()
**
** When a round starts.
** -------------------------------------------------------------------------- */
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (pluginEnabled) {
		// Need to wait at least 0.2 before bloom is able to be set
		// Increased delay as possible fix for CC and particles
		CreateTimer(2.0, Timer_RoundStart);
	}
	
	return Plugin_Continue;
}

/* Timer_RoundStart()
**
** Timer for round start.
** ------------------------------------------------------------------------- */
public Action:Timer_RoundStart(Handle:timer, any:data)
{
	ApplyConfigRound();
	
	AnnounceTheme();
}

/* Event_PlayerTeam()
**
** When a player joins a team.
** -------------------------------------------------------------------------- */
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (pluginEnabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (client && IsClientInGame(client)) {
			// Apply Skybox Fog Color
			if (mapSkyboxFogColor != -1) {
				SetEntProp(client, Prop_Send, "m_skybox3d.fog.enable", 1);
				SetEntProp(client, Prop_Send, "m_skybox3d.fog.colorPrimary", mapSkyboxFogColor);
				SetEntProp(client, Prop_Send, "m_skybox3d.fog.colorSecondary", mapSkyboxFogColor);
			}
			
			// Apply Skybox Fog Start
			if (mapSkyboxFogStart != -1.0) {
				SetEntPropFloat(client, Prop_Send, "m_skybox3d.fog.start", mapSkyboxFogStart);
			}
			
			// Apply Skybox Fog End
			if (mapSkyboxFogEnd != -1.0) {
				SetEntPropFloat(client, Prop_Send, "m_skybox3d.fog.end", mapSkyboxFogEnd);
			}
		}
	}
	
	return Plugin_Continue;
}

/* AnnounceTheme()
**
** Announces the current theme.
** -------------------------------------------------------------------------- */
AnnounceTheme()
{
	if (GetConVarBool(cvAnnounce)) {
		CPrintToChatAll("%t", "Announce_Theme", mapTag, mapTheme);
	}
}

/* StringToTimeOfDay()
**
** Converts a string representation of a time of day into an integer.
** -------------------------------------------------------------------------- */
StringToTimeOfDay(String:time[6])
{
	new hours = 0;
	new minutes = 0;
	decl String:buffers[2][4];
	
	new num = ExplodeString(time, ":", buffers, 3, 4);
	
	if (num > 0) {
		hours = StringToInt(buffers[0]) - GetTimezoneHourOffset();
		
		if (num > 1) {
			minutes = StringToInt(buffers[1]) - GetTimezoneMinuteOffset();
		}
	}
	
	if (minutes < 0) {
		minutes += 60;
		hours -= 1;
	}
	
	if (hours < 0) {
		hours += 24;
	}
	
	return hours * 60 * 60 + minutes * 60;
}

/* GetTimeOfDay()
**
** Returns an integer storing the current time of day (hours and minutes only.)
** -------------------------------------------------------------------------- */
GetTimeOfDay()
{
	new result = GetTime();
	
	result %= 86400;
	result -= result % 60;
	
	return result;
}

/* GetTimezoneHourOffset()
**
** Returns the hour offset for the server's current timezone.
** -------------------------------------------------------------------------- */
GetTimezoneHourOffset()
{
	decl String:temp[3];
	FormatTime(temp, sizeof(temp), "%H", 0);
	
	return StringToInt(temp);
}

/* GetTimezoneMinuteOffset()
**
** Returns the minute offset for the server's current timezone.
** -------------------------------------------------------------------------- */
GetTimezoneMinuteOffset()
{
	decl String:temp[3];
	FormatTime(temp, sizeof(temp), "%M", 0);
	
	return StringToInt(temp);
}