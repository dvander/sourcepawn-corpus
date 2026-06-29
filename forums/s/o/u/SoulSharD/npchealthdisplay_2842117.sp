#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION				"1.0.0"

#define DEFAULT_DISPLAY_FILE		"npc_health_display.cfg"
#define DISPLAY_UPDATE_INTERVAL 	0.1 	// How often to update the health display.
#define DEFAULT_BAR_TEXT_SPACING	-14.0	// At -14.0 the bar becomes a dot, so we'll treat it as a length of zero and anything added to it increases its length.

#define KRAMPUS_HEALTH_BUFFER		1000	// KRAMPUS! has a 1000 health buffer for whatever reason. So we'll need to subtract this amount to get his actual functional health.
#define SALMANN_HEALTH				200		// Salmann's max health isn't set on spawn, and defaults to 50. We'll set it ourselves or it'll mess up our colours.

//#define SKELETON_NORMAL		0
//#define SKELETON_KING		1
#define SKELETON_MINI		2

StringMap g_DisplayTable;
char g_sDisplayName[64];
int g_iSkeletonTypeOffset = -1;

ConVar g_cvFile;
ConVar g_cvSeparator;
ConVar g_cvPrecision;
ConVar g_cvDisableBar;

enum DisplayType 
{
	DisplayType_Invalid = -1,
	DisplayType_Numeric = 0,
	DisplayType_Percent,
	DisplayType_Bar,
	DisplayType_Text
};

enum ColorMode 
{
	ColorMode_Auto,
	ColorMode_Custom,
	ColorMode_CustomStatic,
	ColorMode_Rainbow
}

enum struct Display {
	DisplayType type;
	float delay;
	float offset;
	int font;
	float size;
	float spacing[2]; // X, Y
	char prefix[32];
	char suffix[32];
	ColorMode colorMode;
	int primaryColor[4];
	int secondaryColor[4];
	char text[128]; // Text only.
	int entity;
	int parent;
	int maxHealth; // Instead of using the m_iMaxHealth prop.
	int healthOffset; // All for Krampus.

	int GetFont()
	{
		if (this.font <= -1) {
			return GetRandomInt(0, 10);
		}
		return this.font;
	}
}

public Plugin myinfo =
{
	name = "[TF2] NPC Health Display",
	author = "SoulSharD",
	description = "Customisable overhead health displays for TF2 NPCs.",
	version = PLUGIN_VERSION,
	url = "https://www.sourcemod.net/"
};

public void OnPluginStart()
{	
	CreateConVar("sm_health_display_version", PLUGIN_VERSION, "NPC Health Display Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_cvFile = CreateConVar("sm_health_display_file", DEFAULT_DISPLAY_FILE, "Configuration file to read, starting from the 'sourcemod/configs/' folder.", FCVAR_NONE);
	g_cvSeparator = CreateConVar("sm_health_display_separator", ",", "The character to use as the thousands separator for numerical displays.", FCVAR_NONE);
	g_cvPrecision = CreateConVar("sm_health_display_precision", "1", "The number of decimal places to display for percentage displays.", FCVAR_NONE, true, 0.0, true, 10.0);
	g_cvDisableBar = CreateConVar("sm_disable_boss_health_bar", "0", "Disables the game's integrated boss health bar HUD element. (Requires map restart.)", FCVAR_NOTIFY);

	RegAdminCmd("sm_reload_health_display", Command_ReloadConfiguration, ADMFLAG_CONFIG, "Re/loads the health display configuration file.");

	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Post);
	
	int offset = FindSendPropInfo("CZombie", "m_flHeadScale");
	if (offset != -1) {
		g_iSkeletonTypeOffset = offset - 4;
	}
	
	FormatEx(g_sDisplayName, sizeof(g_sDisplayName), "__npc_health_display__%d_%s", GetTime(), PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	int entity = -1; 
	char targetName[64];
	
	while ((entity = FindEntityByClassname(entity, "point_worldtext")) != -1) // Clean up our stuff. 
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (StrEqual(targetName, g_sDisplayName)) {
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public void OnConfigsExecuted()
{
	LoadConfigurationFile();
}

public Action Command_ReloadConfiguration(int client, int argCount)
{
	if (LoadConfigurationFile()) {
		ReplyToCommand(client, "[SM] Successfully loaded configuration file.");
	} else {
		ReplyToCommand(client, "[SM] Failed to load configuration file. File is either missing or invalid.");
	}
	return Plugin_Handled;
}

public void OnRoundStart(Event hEvent, const char[] eventName, bool dontBroadcast)
{
	if (hEvent.GetBool("full_reset") && g_cvDisableBar.BoolValue)
	{
		int entity = FindEntityByClassname(-1, "monster_resource");
		if (entity != -1) {
			SetEdictFlags(entity, (GetEdictFlags(entity) | FL_EDICT_DONTSEND));
		}
	}
}

public void OnEntityCreated(int entity, const char[] className)
{
	if (IsMonsterClassname(className)) {
		SDKHook(entity, SDKHook_SpawnPost, OnMonsterSpawned);
	}
}

public void OnMonsterSpawned(int entity)
{
	RequestFrame(OnMonsterFrame, EntIndexToEntRef(entity)); // Still need to delay by a frame because even _SpawnPost is too early to get model info.
}

public void OnMonsterFrame(int ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE)
	{
		char className[64];
		GetEntityClassname(entity, className, sizeof(className));
	
		if (StrEqual(className, "eyeball_boss") && GetEntProp(entity, Prop_Data, "m_iTeamNum") != 5) {
			return; // Ignore spell MONOCULUS! as they're invincible anyway.
		}
	
		char modelName[128];
		GetMonsterModelName(entity, modelName, sizeof(modelName));
		
		if (StrEqual(className, "tf_zombie")) 
		{
			if (GetSkeletonType(entity) == SKELETON_MINI) {
				StrCat(modelName, sizeof(modelName), "_mini");
			}
		}
		
		Display display;
		if (CreateDisplay(modelName, display)) {
			AttachDisplay(entity, display);
		}
	}
}

void AttachDisplay(int parent, Display display)
{
	int entity = CreateEntityByName("point_worldtext");
	if (IsValidEdict(entity))
	{
		float origin[3]; float maxBounds[3];
	
		DispatchKeyValue(entity, "targetname", g_sDisplayName);
		DispatchKeyValueInt(entity, "orientation", 1);
		DispatchKeyValueFloat(entity, "textsize", display.size);
		DispatchKeyValueInt(entity, "font", display.GetFont());
		DispatchKeyValueFloat(entity, "textspacingx", display.spacing[0]);
		DispatchKeyValueFloat(entity, "textspacingy", display.spacing[1]);
		
		DispatchSpawn(entity);
		
		GetEntPropVector(parent, Prop_Data, "m_vecOrigin", origin);
	    GetEntPropVector(parent, Prop_Data, "m_vecMaxs", maxBounds);
		origin[2] += maxBounds[2] + display.offset;
		TeleportEntity(entity, origin);
		
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", parent);
		
		if (display.type == DisplayType_Text) // Set and forget the text.
		{
			SetVariantString(display.text);
			AcceptEntityInput(entity, "SetText");
		}

		switch (display.colorMode)
		{
			case ColorMode_Auto:
			{
				SetVariantColor({0, 255, 0, 255});
				AcceptEntityInput(entity, "SetColor");
			}

			case ColorMode_Custom, ColorMode_CustomStatic:
			{
				SetVariantColor(display.primaryColor);
				AcceptEntityInput(entity, "SetColor");
			}

			case ColorMode_Rainbow:
			{
				SetVariantBool(true);
				AcceptEntityInput(entity, "SetRainbow");
			}
		}

       	if (HasEntProp(parent, Prop_Send, "m_bRevealed")) { // Workaround for when Merasmus hides.
            SDKHook(entity, SDKHook_SetTransmit, OnDisplayTransmit);
        }

		display.entity = EntIndexToEntRef(entity);
		display.parent = EntIndexToEntRef(parent);

		char vScript[PLATFORM_MAX_PATH];
		GetEntPropString(parent, Prop_Data, "m_iszVScripts", vScript, sizeof(vScript));

		if (StrEqual(vScript, "koth_krampus/krampus/krampus.nut")) {
			display.healthOffset = -KRAMPUS_HEALTH_BUFFER;
		}

		// We can't rely on the m_iMaxHealth prop because not all community-made NPCs actually set it.
		// So we'll just have to assume the NPC's health at spawn is their maximum health.
		// With the exception of Salmann which, when spawned, have their health briefly set to 1234 for some reason.
		
		if (StrEqual(vScript, "koth_slime/salmann.nut")) {
			display.maxHealth = SALMANN_HEALTH;
		} else {
			display.maxHealth = GetEntProp(parent, Prop_Data, "m_iHealth");
		}

		if (display.delay > 0.0) 
		{
			SetEdictFlags(entity, (GetEdictFlags(entity) | FL_EDICT_DONTSEND));
			CreateTimer(display.delay, tDisplayDelay, display.entity, TIMER_FLAG_NO_MAPCHANGE);
		}

		DataPack data = new DataPack();
		data.WriteCellArray(display, sizeof(display));
		data.WriteCell(-1);

		CreateTimer(DISPLAY_UPDATE_INTERVAL, tUpdateDisplay, data, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	}
}

public Action tUpdateDisplay(Handle timer, DataPack data)
{
	data.Reset();

	Display display;
	data.ReadCellArray(display, sizeof(display));

	int entity = EntRefToEntIndex(display.entity);
	if (entity == INVALID_ENT_REFERENCE) {
		return Plugin_Stop;
	}

    int parent = EntRefToEntIndex(display.parent);
	if (parent == INVALID_ENT_REFERENCE || GetEntPropEnt(entity, Prop_Data, "m_hMoveParent") != parent) {
		return Plugin_Stop;
	}

	int health = GetEntProp(parent, Prop_Data, "m_iHealth") + display.healthOffset;
	
	if (health < 0) {
		health = 0;
	}

	DataPackPos dataPos = data.Position;
	int previousHealth = data.ReadCell();
	
	if (health == previousHealth) {
		return Plugin_Continue;
	}

	float healthPct = float(health) / (display.maxHealth + display.healthOffset);

	if (display.type != DisplayType_Text)
	{
		char text[128];

		switch (display.type)
		{
			case DisplayType_Numeric, DisplayType_Percent: 
			{
				char healthValue[32];
				
				if (display.type == DisplayType_Percent) 
				{
					FloatToStringEx(healthPct * 100.0, healthValue, sizeof(healthValue), g_cvPrecision.IntValue);
					StrCat(healthValue, sizeof(healthValue), "%");
				} 
                else
                {
					IntToSeparatedString(health, healthValue, sizeof(healthValue), GetConVarChar(g_cvSeparator));
				}

				FormatEx(text, sizeof(text), "%s%s%s", display.prefix, healthValue, display.suffix);
			}
			
			case DisplayType_Bar:
			{
				int count = RoundToCeil(healthPct * 100.0);
				for (int i; i < count; i++) {
					StrCat(text, sizeof(text), ".");
				}
			}
		}
		
		SetVariantString(text);
		AcceptEntityInput(entity, "SetText");
	}
	
	if (display.colorMode == ColorMode_Auto || display.colorMode == ColorMode_Custom)
	{
		int color[4];

		if (display.colorMode == ColorMode_Custom) {
			GetColorLerp(color, healthPct, display.secondaryColor, display.primaryColor);
		} else {
			GetHealthColor(color, healthPct);
		}
		
		SetVariantColor(color);
		AcceptEntityInput(entity, "SetColor");
	}

	data.Position = dataPos;
	data.WriteCell(health);

	return Plugin_Continue;
}

public void tDisplayDelay(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE) {
		SetEdictFlags(entity, (GetEdictFlags(entity) & ~FL_EDICT_DONTSEND));
	}
}

public Action OnDisplayTransmit(int entity, int client)
{
	if(GetEntProp(GetEntPropEnt(entity, Prop_Data, "m_hMoveParent"), Prop_Send, "m_bRevealed")) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

void GetColorLerp(int color[4], float pct, int startColor[4], int endColor[4])
{
	for (int i; i < 4; i++) {
		color[i] = RoundToNearest(((endColor[i] - startColor[i]) * pct) + startColor[i]);
	}
}

void GetHealthColor(int color[4], float pct)
{
	color[0] = RoundToNearest(255.0 * SquareRoot(FloatAbs(Cosine(pct * FLOAT_PI / 2.0))));
	color[1] = RoundToNearest(255.0 * SquareRoot(FloatAbs(Sine(pct * FLOAT_PI / 2.0))));
//	color[2] = 0;
	color[3] = 255;
}

DisplayType GetDisplayType(const char[] type)
{
	static char s_sDisplayType[][] = {"numeric", "percent", "bar", "text"}; 
	for (int i; i < 4; i++)
	{
		if (StrEqual(s_sDisplayType[i], type, false)) {
			return view_as<DisplayType>(i);
		}
	}
	return DisplayType_Invalid;
}

int GetConVarChar(ConVar conVar)
{
	char charString[2];
	conVar.GetString(charString, sizeof(charString));
	return charString[0];
}

bool LoadConfigurationFile()
{
	char fileName[PLATFORM_MAX_PATH];
	g_cvFile.GetString(fileName, sizeof(fileName));
		
	KeyValues kv = GetConfigurationFile(fileName);
	if (kv != null && kv.GotoFirstSubKey()) 
	{
		if (g_DisplayTable == null) {
			g_DisplayTable = new StringMap();
		} else {
			g_DisplayTable.Clear();
		}

		do
		{
			char displayName[64];
			kv.GetSectionName(displayName, sizeof(displayName));

			if (!g_DisplayTable.ContainsKey(displayName)) // Ignore duplicates.
			{
				char typeName[8];
				kv.GetString("display_type", typeName, sizeof(typeName));
				DisplayType type = GetDisplayType(typeName);

				if (type == DisplayType_Invalid) {
					continue;
				}

				Display display;
				display.type = type;
				display.delay = kv.GetFloat("delay");
				display.offset = kv.GetFloat("vertical_offset");
				display.size = kv.GetFloat("size");
				
				if (type != DisplayType_Bar)
				{
					display.font = kv.GetNum("font");
					display.spacing[0] = kv.GetFloat("text_spacing_x");
				}
				else
				{
					float length = kv.GetFloat("bar_length", 1.0);

					if (length < 0.0) {
						length = 0.0;
					}

					display.font = 1;
					display.spacing[0] = DEFAULT_BAR_TEXT_SPACING + length;
				}

				switch (type)
				{
					case DisplayType_Numeric, DisplayType_Percent:
					{
						kv.GetString("prefix", display.prefix, sizeof(display.prefix));
						kv.GetString("suffix", display.suffix, sizeof(display.suffix));
					}

					case DisplayType_Text:
					{
						kv.GetString("text", display.text, sizeof(display.text));
						ReplaceString(display.text, sizeof(display.text), "\\n", "\n"); // Fix for new lines.
					}
				}

				if (kv.GetNum("rainbow_mode") != 0) {
					display.colorMode = ColorMode_Rainbow;
				}
				else
				{
					if (kv.GetDataType("primary_color") == KvData_None) {
						display.colorMode = ColorMode_Auto;
					}
					else
					{
						kv.GetColor4("primary_color", display.primaryColor);
						display.primaryColor[3] = 255;

						if (kv.GetDataType("secondary_color") != KvData_None) 
						{
							kv.GetColor4("secondary_color", display.secondaryColor);
							display.secondaryColor[3] = 255;
							display.colorMode = ColorMode_Custom;
						} else {
							display.colorMode = ColorMode_CustomStatic;
						}
					}
				}

				g_DisplayTable.SetArray(displayName, display, sizeof(display));
			}
		}
		while (kv.GotoNextKey());

		delete kv;
		return true;
	}

	return false;
}

KeyValues GetConfigurationFile(const char[] fileName)
{
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "configs/%s", fileName);
	
	if (FileExists(filePath)) 
	{
		KeyValues kv = new KeyValues("NPCHealthDisplay");
		if (kv.ImportFromFile(filePath)) {
			return kv;
		}
		delete kv;
	}
	
	return null;
}

void GetMonsterModelName(int entity, char[] modelName, int maxLength)
{
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	ReplaceStringEx(model, sizeof(model), ".mdl", NULL_STRING);
	
	int index = FindCharInString(model, '/', true) + 1;
	strcopy(modelName, maxLength, model[index]);
}

bool CreateDisplay(const char[] displayName, Display display)
{
	if (g_DisplayTable != null) {
		return g_DisplayTable.GetArray(displayName, display, (sizeof(display)));
	}
	return false;
}

bool IsMonsterClassname(const char[] className)
{
	static const char s_sMonsterClass[][] = 
	{
		"headless_hatman",
		"eyeball_boss",
		"merasmus",
		"tf_zombie",
		"tank_boss",
		"base_boss"
	};

	for (int i; i < sizeof(s_sMonsterClass); i++)
	{
		if (StrEqual(s_sMonsterClass[i], className)) {
			return true;
		}
	}
	
	return false;
}

int GetSkeletonType(int entity)
{
	if (g_iSkeletonTypeOffset != -1) {
		return GetEntData(entity, g_iSkeletonTypeOffset);
	}
	return -1;
}

int IntToSeparatedString(int v, char[] output, int maxLength, int c=',')
{
	char temp[17]; 
	int outputPos, numPos;
	int numLen = IntToString(v, temp, sizeof(temp));

	if (numLen <= 3 || c <= 0) 
	{
		outputPos += strcopy(output[outputPos], maxLength, temp);
	}
	else
	{
		while ((numPos < numLen) && (outputPos < maxLength))
		{
			output[outputPos++] = temp[numPos++];
			
			if ((numLen - numPos) && !((numLen - numPos) % 3)) {
				output[outputPos++] = c;
			}
		}
		output[outputPos] = '\0';
	}
	return outputPos;
}

void FloatToStringEx(float v, char[] string, int maxLength, int precision)
{
	char buffer[16];
	FormatEx(buffer, sizeof(buffer), "%%.%df", precision);
	FormatEx(string, maxLength, buffer, v);
}