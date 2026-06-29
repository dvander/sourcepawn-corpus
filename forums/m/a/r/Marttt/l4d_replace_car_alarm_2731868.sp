/**
// ====================================================================================================
Change Log:

1.0.4 (22-January-2021)
    - Added info_remarkable entity. (thanks "Edison1318" for requesting)
    - Added info_game_event_proxy entity.
    - Added proper entities kill on OnCarAlarmEnd/OnHitByTank.
    - Added pallete color.

1.0.3 (20-January-2021)
    - Now compatible with Mutant Tanks plugin. (big thanks to "Psyk0tik" for adding support)

1.0.2 (18-January-2021)
    - Fixed plugin crashing on Glubtastic 1, 3rd Map. (thanks "jeremyvillanueva" for reporting)

1.0.1 (14-January-2021)
    - Fixed a bug where the glass light was blinking after a tank hit. (thanks "Merc1less" for reporting)

1.0.0 (09-January-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Replace Cars Into Car Alarms"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Replaces normal cars with car alarms"
#define PLUGIN_VERSION                "1.0.4"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=329806"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_replace_car_alarm"
#define DATA_FILENAME                 "l4d_replace_car_alarm"

// ====================================================================================================
// Defines
// ====================================================================================================
#define ALARMCAR_MODEL                "models/props_vehicles/cara_95sedan.mdl"
#define ALARMCAR_GLASS_ALARM_ON       "models/props_vehicles/cara_95sedan_glass_alarm.mdl"
#define ALARMCAR_GLASS_ALARM_OFF      "models/props_vehicles/cara_95sedan_glass.mdl"
#define ALARMCAR_GLOW_SPRITE          "sprites/glow.vmt"

#define SOUND_CAR_ALARM               "vehicles/car_alarm/car_alarm.wav"
#define SOUND_CAR_ALARM_CHIRP2        "vehicles/car_alarm/car_alarm_chirp2.wav"

#define COLOR_YELLOWLIGHT             "224 162 44"
#define COLOR_REDLIGHT                "255 13 19"
#define COLOR_WHITELIGHT              "252 243 226"

#define DISTANCE_FRONT                101.0
#define DISTANCE_SIDETURN             34.0
#define DISTANCE_UPFRONT              29.0
#define DISTANCE_BACK                 103.0
#define DISTANCE_SIDE                 27.0
#define DISTANCE_UPBACK               31.0

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Chance;
ConVar g_hCvar_GlassOn;
ConVar g_hCvar_GlassOff;
ConVar g_hCvar_Sound;
ConVar g_hCvar_Chirp;
ConVar g_hCvar_Lights;
ConVar g_hCvar_Headlights;
ConVar g_hCvar_Timer;
ConVar g_hCvar_Remark;
ConVar g_hCvar_GameEvent;
ConVar g_hCvar_Targetname;
ConVar g_hCvar_Color;
ConVar g_hCvar_IgnoreCarAlarm;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bCvar_Enabled;
bool g_bCvar_Chance;
bool g_bCvar_GlassOn;
bool g_bCvar_GlassOff;
bool g_bCvar_Sound;
bool g_bCvar_Chirp;
bool g_bCvar_Lights;
bool g_bCvar_Headlights;
bool g_bCvar_Timer;
bool g_bCvar_Remark;
bool g_bCvar_GameEvent;
bool g_bCvar_Targetname;
bool g_bCvar_PalleteColor;
bool g_bCvar_MaintainColor;
bool g_bCvar_RandomColor;
bool g_bCvar_IgnoreCarAlarm;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_Color[3];
int g_iCarIncrement;
int g_iPalleteColors[][3] = {{138,  37,   9}, { 52,  46,  46}, { 84, 101, 144}, { 99, 135, 157},
                                       {114,  80,  52}, {135, 166, 158}, {138, 137,  89}, {153,  65,  29},
                                       {153,  95, 110}, {156,  81,  62}, {162, 189, 196}, {178, 160,  94},
                                       {182,  92,  68}, {182, 122,  68}, {197, 176, 129}, {212, 158,  70},
                                       {226, 188,  87}, {253, 241, 203}};

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_Chance;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
char g_sMapName[64];
char g_sCvar_Color[12];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bIgnoreEntity[MAXENTITIES+1];

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alModel;

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smModel;
StringMap g_smModelRotate;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    g_alModel = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    g_smModel = new StringMap();
    g_smModelRotate = new StringMap();

    LoadModelsData();

    CreateConVar("l4d_replace_car_alarm_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled        = CreateConVar("l4d_replace_car_alarm_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Chance         = CreateConVar("l4d_replace_car_alarm_chance", "100.0", "Chance of a normal car be replaced by the plugin.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_GlassOn        = CreateConVar("l4d_replace_car_alarm_glass_on", "1", "Blinking car glass until the car alarm starts.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GlassOff       = CreateConVar("l4d_replace_car_alarm_glass_off", "1", "Normal car glass when the car alarm starts.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Sound          = CreateConVar("l4d_replace_car_alarm_sound", "1", "Car alarm sound when the car alarm starts.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Chirp          = CreateConVar("l4d_replace_car_alarm_chirp", "1", "Chirp sound. Sound that plays when someone shoots near a car before the car alarm starts.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Lights         = CreateConVar("l4d_replace_car_alarm_lights", "1", "Lights at front and back when the car alarm starts.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Headlights     = CreateConVar("l4d_replace_car_alarm_headlights", "1", "Headlights at front when the car alarm starts.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Timer          = CreateConVar("l4d_replace_car_alarm_timer", "1", "Timer that controls the lights and headlights during the car alarm.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Remark         = CreateConVar("l4d_replace_car_alarm_remark", "0", "Remark. Survivors may warn about the car alarm through vocalizers.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GameEvent      = CreateConVar("l4d_replace_car_alarm_game_event", "0", "Game event. A instructor hint may warn about the car alarm.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Targetname     = CreateConVar("l4d_replace_car_alarm_targetname", "0", "Keep original targetname.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Color          = CreateConVar("l4d_replace_car_alarm_color", "maintain", "Car alarm color.\n\"palette\" = colors used by cars on official maps.\n\"maintain\" = keep original car color (\"pallete\" if colorless).\n\"random\" = random colors.\n\"<0-255> <0-255> <0-255>\" = specific car color. (e.g: \"138 37 9\", default car alarm color).", CVAR_FLAGS);
    g_hCvar_IgnoreCarAlarm = CreateConVar("l4d_replace_car_alarm_ignore_car_alarm", "1", "Ignore prop_car_alarm entities while replacing.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlassOn.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlassOff.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Sound.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chirp.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Lights.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Headlights.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Timer.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Remark.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GameEvent.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Targetname.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Color.AddChangeHook(Event_ConVarChanged);
    g_hCvar_IgnoreCarAlarm.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_car_alarm_reload", CmdModelsReload, ADMFLAG_ROOT, "Reload the valid models file to replace into car alarms.");
    RegAdminCmd("sm_car_alarm_refresh", CmdCarAlarmRefresh, ADMFLAG_ROOT, "Refresh the car alarms replace chance.");
    RegAdminCmd("sm_print_cvars_l4d_replace_car_alarm", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void LoadModelsData()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    g_alModel.Clear();
    g_smModel.Clear();

    g_smModelRotate.Clear();
    g_smModelRotate.SetString("models/props_vehicles/police_car.mdl", "");
    g_smModelRotate.SetString("models/props_vehicles/police_car_city.mdl", "");
    g_smModelRotate.SetString("models/props_vehicles/police_car_rural.mdl", "");
    g_smModelRotate.SetString("models/props_vehicles/van.mdl", "");
    g_smModelRotate.SetString("models/props_vehicles/van001a.mdl", "");
    g_smModelRotate.SetString("models/props_vehicles/van_interior.mdl", "");

    File hFile = OpenFile(path, "r");
    if (hFile != null)
    {
        char g_sModels[64];
        while (!hFile.EndOfFile() && hFile.ReadLine(g_sModels, sizeof(g_sModels)))
        {
            TrimString(g_sModels);
            StringToLowerCase(g_sModels);

            if (g_sModels[0] == 'm')
            {
                g_alModel.PushString(g_sModels);
                g_smModel.SetString(g_sModels, "");
            }
        }
    }
    delete hFile;
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iCarIncrement = 0;

    GetCurrentMap(g_sMapName, sizeof(g_sMapName));
    StringToLowerCase(g_sMapName);

    PrecacheModel(ALARMCAR_MODEL, true);
    PrecacheModel(ALARMCAR_GLASS_ALARM_ON, true);
    PrecacheModel(ALARMCAR_GLASS_ALARM_OFF, true);
    PrecacheModel(ALARMCAR_GLOW_SPRITE, true);

    PrecacheSound(SOUND_CAR_ALARM, true);
    PrecacheSound(SOUND_CAR_ALARM_CHIRP2, true);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_Chance = g_hCvar_Chance.FloatValue;
    g_bCvar_Chance = (g_fCvar_Chance > 0.0);
    g_bCvar_GlassOn = g_hCvar_GlassOn.BoolValue;
    g_bCvar_GlassOff = g_hCvar_GlassOff.BoolValue;
    g_bCvar_Chirp = g_hCvar_Chirp.BoolValue;
    g_bCvar_Sound = g_hCvar_Sound.BoolValue;
    g_bCvar_Lights = g_hCvar_Lights.BoolValue;
    g_bCvar_Headlights = g_hCvar_Headlights.BoolValue;
    g_bCvar_Timer = g_hCvar_Timer.BoolValue;
    g_bCvar_Remark = g_hCvar_Remark.BoolValue;
    g_bCvar_GameEvent = g_hCvar_GameEvent.BoolValue;
    g_bCvar_Targetname = g_hCvar_Targetname.BoolValue;
    g_hCvar_Color.GetString(g_sCvar_Color, sizeof(g_sCvar_Color));
    TrimString(g_sCvar_Color);
    g_bCvar_PalleteColor = StrEqual(g_sCvar_Color, "pallete", false);
    g_bCvar_MaintainColor = StrEqual(g_sCvar_Color, "maintain", false);
    g_bCvar_RandomColor = StrEqual(g_sCvar_Color, "random", false);
    g_iCvar_Color = ConvertRGBToIntArray(g_sCvar_Color);
    g_bCvar_IgnoreCarAlarm = g_hCvar_IgnoreCarAlarm.BoolValue;
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "p*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
            RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (ge_bIgnoreEntity[entity])
        return;

    if (!HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
        return;

    RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bIgnoreEntity[entity] = false;
}

/****************************************************************************************************/

void OnNextFrame(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != -1) // Ignore cars created by Mutant Tanks plugin
        return;

    if (g_bCvar_IgnoreCarAlarm)
    {
        char classname[36];
        GetEntityClassname(entity, classname, sizeof(classname));

        if (StrEqual(classname, "prop_car_alarm"))
            return;
    }

    ReplaceWithAlarmCar(entity);
}

/****************************************************************************************************/

void ReplaceWithAlarmCar(int entity)
{
    if (!IsValidEntity(entity))
        return;

    if (!g_bCvar_Chance)
        return;

    if (g_fCvar_Chance < GetRandomFloat(0.0, 100.0))
        return;

    char targetname[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (g_bL4D2)
    {
        switch (g_sMapName[0])
        {
            case 'g':
            {
                // Fix for Glubtastic 1, 3rd Map. These cars can't be removed and respawned, otherwise it will bug some map events
                if (StrEqual(g_sMapName, "glubtastic_3") && StrContains(targetname, "car") == 0 && StrContains(targetname, "&") > 3)
                    return;
            }
            case 'q':
            {
                // Fix for Questionable Ethics 1, 2nd Map. These cars can't be removed and respawned, otherwise it will bug some map events
                if (StrEqual(g_sMapName, "qe_2_remember_me") && StrContains(targetname, "PP_") == 0)
                    return;
            }
        }
    }

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    StringToLowerCase(modelname);

    char buffer[1];
    if (!g_smModel.GetString(modelname, buffer, sizeof(buffer)))
        return;

    float vPos[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);

    float vAng[3];
    GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAng);

    if (g_smModelRotate.GetString(modelname, buffer, sizeof(buffer)))
        vAng[1] += 90.0;

    int color[4];

    if (g_bCvar_PalleteColor)
    {
        color = g_iPalleteColors[GetRandomInt(0, sizeof(g_iPalleteColors)-1)];
    }
    else if (g_bCvar_MaintainColor)
    {
        GetEntityRenderColor(entity, color[0], color[1], color[2], color[3]);

        if (color[0] == 255 && color[1] == 255 && color[2] == 255) // No color
            color = g_iPalleteColors[GetRandomInt(0, sizeof(g_iPalleteColors)-1)];
    }
    else if (g_bCvar_RandomColor)
    {
        color[0] = GetRandomInt(0, 255);
        color[1] = GetRandomInt(0, 255);
        color[2] = GetRandomInt(0, 255);
    }
    else // specific color
    {
        color[0] = g_iCvar_Color[0];
        color[1] = g_iCvar_Color[1];
        color[2] = g_iCvar_Color[2];
    }

    char rendercolor[12];
    FormatEx(rendercolor, sizeof(rendercolor), "%i %i %i", color[0], color[1], color[2]);

    AcceptEntityInput(entity, "Kill");

    SpawnAlarmCar(vPos, vAng, rendercolor, targetname);
}

/**
// ====================================================================================================
:::BEGIN::: -> Source Code (with changes) from DieTeetasse - [L4D1&2] Spawn Alarmcars plugin https://forums.alliedmods.net/showthread.php?t=139352
// ====================================================================================================
*/

/****************************************************************************************************/

void SpawnAlarmCar(float vPos[3], float vAng[3], char[] rendercolor, char[] targetname)
{
    char carName[64];
    char glassOnName[64];
    char glassOffName[64];
    char timerName[64];
    char alarmSoundName[64];
    char chirpSoundName[64];
    char lightsName[64];
    char headlightsName[64];
    char remarkName[64];
    char gameEventName[64];

    if (++g_iCarIncrement > GetMaxEntities())
        g_iCarIncrement = 1;

    // create car
    int carEntity = CreateEntityByName("prop_car_alarm");
    ge_bIgnoreEntity[carEntity] = true;

    if (!g_bCvar_Targetname || targetname[0] == 0)
    {
        FormatEx(carName, sizeof(carName), "l4d_rca_car_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(glassOnName, sizeof(glassOnName), "l4d_rca_glasson_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(glassOffName, sizeof(glassOffName), "l4d_rca_glassoff_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(timerName, sizeof(timerName), "l4d_rca_alarmtimer_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(alarmSoundName, sizeof(alarmSoundName), "l4d_rca_alarmsound_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(chirpSoundName, sizeof(chirpSoundName), "l4d_rca_chirpsound_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(lightsName, sizeof(lightsName), "l4d_rca_lights_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(headlightsName, sizeof(headlightsName), "l4d_rca_headlights_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(remarkName, sizeof(remarkName), "l4d_rca_remark_%i-%i", carEntity, g_iCarIncrement);
        FormatEx(gameEventName, sizeof(gameEventName), "l4d_rca_gameevent_%i-%i", carEntity, g_iCarIncrement);
    }
    else
    {
        strcopy(carName, sizeof(carName), targetname);
        FormatEx(glassOnName, sizeof(glassOnName), "l4d_rca_glasson-%s", targetname);
        FormatEx(glassOffName, sizeof(glassOffName), "l4d_rca_glassoff-%s", targetname);
        FormatEx(timerName, sizeof(timerName), "l4d_rca_alarmtimer-%s", targetname);
        FormatEx(alarmSoundName, sizeof(alarmSoundName), "l4d_rca_alarmsound-%s", targetname);
        FormatEx(chirpSoundName, sizeof(chirpSoundName), "l4d_rca_chirpsound-%s", targetname);
        FormatEx(lightsName, sizeof(lightsName), "l4d_rca_lights-%s", targetname);
        FormatEx(headlightsName, sizeof(headlightsName), "l4d_rca_headlights-%s", targetname);
        FormatEx(remarkName, sizeof(remarkName), "l4d_rca_remark-%s", targetname);
        FormatEx(gameEventName, sizeof(gameEventName), "l4d_rca_gameevent-%s", targetname);
    }

    DispatchKeyValue(carEntity, "targetname", carName);
    DispatchKeyValue(carEntity, "model", ALARMCAR_MODEL);
    DispatchKeyValue(carEntity, "rendercolor", rendercolor);

    char tempString[128];
    Format(tempString, sizeof(tempString), "%s,PlaySound,,0.2,-1", chirpSoundName);
    DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
    Format(tempString, sizeof(tempString), "%s,ShowSprite,,0.2,-1", lightsName);
    DispatchKeyValue(carEntity, "OnCarAlarmChirpStart", tempString);
    Format(tempString, sizeof(tempString), "%s,HideSprite,,0.7,-1", lightsName);
    DispatchKeyValue(carEntity, "OnCarAlarmChirpEnd", tempString);
    Format(tempString, sizeof(tempString), "%s,Enable,,0,-1", timerName);
    DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
    Format(tempString, sizeof(tempString), "%s,PlaySound,,0,-1", alarmSoundName);
    DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
    Format(tempString, sizeof(tempString), "%s,Enable,,0,-1", glassOffName);
    DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, sizeof(tempString), "%s,Kill,,0,-1", glassOnName);
    DispatchKeyValue(carEntity, "OnCarAlarmStart", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, sizeof(tempString), "%s,Kill,,0,-1", timerName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, sizeof(tempString), "%s,Kill,,0,-1", alarmSoundName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, sizeof(tempString), "%s,Kill,,0,-1", chirpSoundName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, sizeof(tempString), "%s,Kill,,0,-1", lightsName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, sizeof(tempString), "%s,Kill,,0,-1", headlightsName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, sizeof(tempString), "%s,Kill,,0,-1", remarkName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    Format(tempString, sizeof(tempString), "%s,Kill,,0,-1", gameEventName);
    DispatchKeyValue(carEntity, "OnCarAlarmEnd", tempString);
    DispatchKeyValue(carEntity, "OnHitByTank", tempString);
    DispatchKeyValueVector(carEntity, "origin", vPos);
    DispatchKeyValueVector(carEntity, "angles", vAng);
    DispatchSpawn(carEntity);

    // create glasses
    if (g_bCvar_GlassOn)
        CreateGlass(glassOnName, false, vPos, vAng, carName);
    if (g_bCvar_GlassOff)
        CreateGlass(glassOffName, true, vPos, vAng, carName);

    // create sounds
    if (g_bCvar_Sound)
        CreateSound(alarmSoundName, "16", "Car.Alarm", vPos, carName);
    if (g_bCvar_Chirp)
        CreateSound(chirpSoundName, "48", "Car.Alarm.Chirp2", vPos, carName);

    // create lights
    if (g_bCvar_Lights)
        CreateLights(lightsName, vPos, vAng, carName);

    // create headlights
    if (g_bCvar_Headlights)
        CreateHeadlights(headlightsName, vPos, vAng, carName);

    // create timer
    if (g_bCvar_Timer)
        CreateLogicTimer(timerName, lightsName, headlightsName, vPos, carName);

    // create remark
    if (g_bCvar_Remark)
        CreateRemark(remarkName, vPos, vAng, carName);

    // create game event
    if (g_bCvar_GameEvent)
        CreateGameEvent(gameEventName, vPos, vAng, carName);
}

/****************************************************************************************************/

void CreateGlass(char[] targetName, bool startDisabled, float vPos[3], float vAng[3], char[] carName)
{
    int entity = CreateEntityByName("prop_car_glass");

    DispatchKeyValue(entity, "targetname", targetName);
    DispatchKeyValue(entity, "model", startDisabled ? ALARMCAR_GLASS_ALARM_OFF : ALARMCAR_GLASS_ALARM_ON);
    DispatchKeyValue(entity, "StartDisabled", startDisabled ? "1" : "0");
    DispatchKeyValueVector(entity, "origin", vPos);
    DispatchKeyValueVector(entity, "angles", vAng);
    DispatchSpawn(entity);

    SetVariantString(carName);
    AcceptEntityInput(entity, "SetParent", entity, entity, 0);
}

/****************************************************************************************************/

void CreateSound(char[] targetName, char[] spawnFlags, char[] messageName, float vPos[3], char[] carName)
{
    int entity = CreateEntityByName("ambient_generic");

    float newPos[3];
    newPos = vPos;
    newPos[2] += 80.0;

    DispatchKeyValue(entity, "targetname", targetName);
    DispatchKeyValue(entity, "spawnflags", spawnFlags);
    DispatchKeyValue(entity, "message", messageName);
    DispatchKeyValue(entity, "SourceEntityName", carName);
    DispatchKeyValue(entity, "radius", "4000");
    DispatchKeyValueVector(entity, "origin", newPos);
    DispatchSpawn(entity);
    ActivateEntity(entity); // Don't work without it

    SetVariantString(carName);
    AcceptEntityInput(entity, "SetParent", entity, entity, 0);
}

/****************************************************************************************************/

void CreateLights(char[] lightsName, float vPos[3], float vAng[3], char[] carName)
{
    float distance[6] = {DISTANCE_FRONT, DISTANCE_SIDETURN, DISTANCE_UPFRONT, DISTANCE_BACK, DISTANCE_SIDE, DISTANCE_UPBACK};
    float newPos[3];
    float lightDistance[3];

    newPos = vPos;
    lightDistance[0] = distance[0];
    lightDistance[1] = distance[1]*-1.0;
    lightDistance[2] = distance[2];
    MoveVectorvPos3D(newPos, vAng, lightDistance); // front left
    CreateLight(lightsName, COLOR_YELLOWLIGHT, newPos, carName);

    newPos = vPos;
    lightDistance[1] = distance[1];
    MoveVectorvPos3D(newPos, vAng, lightDistance); // front right
    CreateLight(lightsName, COLOR_YELLOWLIGHT, newPos, carName);

    newPos = vPos;
    lightDistance[0] = distance[3]*-1.0;
    lightDistance[1] = distance[4]*-1.0;
    lightDistance[2] = distance[5];
    MoveVectorvPos3D(newPos, vAng, lightDistance); // back left
    CreateLight(lightsName, COLOR_REDLIGHT, newPos, carName);

    newPos = vPos;
    lightDistance[1] = distance[4];
    MoveVectorvPos3D(newPos, vAng, lightDistance); // back right
    CreateLight(lightsName, COLOR_REDLIGHT, newPos, carName);
}

/****************************************************************************************************/

void CreateLight(char[] targetName, char[] renderColor, float vPos[3], char[] carName)
{
    int entity = CreateEntityByName("env_sprite");

    DispatchKeyValue(entity, "targetname", targetName);
    DispatchKeyValue(entity, "rendercolor", renderColor);
    DispatchKeyValue(entity, "model", ALARMCAR_GLOW_SPRITE);
    DispatchKeyValue(entity, "scale", "0.5");
    DispatchKeyValue(entity, "rendermode", "9");
    DispatchKeyValue(entity, "renderamt", "255");
    DispatchKeyValue(entity, "HDRColorScale", "0.7");
    DispatchKeyValue(entity, "GlowProxySize", "5");
    DispatchKeyValueVector(entity, "origin", vPos);
    DispatchSpawn(entity);

    SetVariantString(carName);
    AcceptEntityInput(entity, "SetParent", entity, entity, 0);
}

/****************************************************************************************************/

void CreateHeadlights(char[] headlightsName, float vPos[3], float vAng[3], char[] carName)
{
    float distance[3] = {DISTANCE_FRONT, DISTANCE_SIDE, DISTANCE_UPFRONT};
    float newPos[3];
    float headlightDistance[3];

    newPos = vPos;
    headlightDistance[0] = distance[0];
    headlightDistance[1] = distance[1]*-1.0;
    headlightDistance[2] = distance[2];
    MoveVectorvPos3D(newPos, vAng, headlightDistance); // front left
    CreateHeadlight(headlightsName, newPos, vAng, carName);

    newPos = vPos;
    headlightDistance[1] = distance[1];
    MoveVectorvPos3D(newPos, vAng, headlightDistance); // front right
    CreateHeadlight(headlightsName, newPos, vAng, carName);
}

/****************************************************************************************************/

void CreateHeadlight(char[] targetName, float vPos[3], float vAng[3], char[] carName)
{
    int entity = CreateEntityByName("beam_spotlight");

    DispatchKeyValue(entity, "targetname", targetName);
    DispatchKeyValue(entity, "rendercolor", COLOR_WHITELIGHT);
    DispatchKeyValue(entity, "spotlightwidth", "32");
    DispatchKeyValue(entity, "spotlightlength", "256");
    DispatchKeyValue(entity, "spawnflags", "2");
    DispatchKeyValue(entity, "rendermode", "5");
    DispatchKeyValue(entity, "renderamt", "150");
    DispatchKeyValue(entity, "maxspeed", "100");
    DispatchKeyValue(entity, "HDRColorScale", "0.5");
    DispatchKeyValueVector(entity, "origin", vPos);
    DispatchKeyValueVector(entity, "angles", vAng);
    DispatchSpawn(entity);

    SetVariantString(carName);
    AcceptEntityInput(entity, "SetParent", entity, entity, 0);
}

/****************************************************************************************************/

void CreateLogicTimer(char[] targetName, char[] lightsName, char[] headlightsName, float vPos[3], char[] carName)
{
    int entity = CreateEntityByName("logic_timer");

    DispatchKeyValue(entity, "targetname", targetName);
    DispatchKeyValue(entity, "StartDisabled", "1");
    DispatchKeyValue(entity, "RefireTime", "0.75");

    char tempString[128];
    Format(tempString, sizeof(tempString), "%s,ShowSprite,,0,-1", lightsName);
    DispatchKeyValue(entity, "OnTimer", tempString);
    Format(tempString, sizeof(tempString), "%s,ShowSprite,,0,-1", lightsName);
    DispatchKeyValue(entity, "OnTimer", tempString);
    Format(tempString, sizeof(tempString), "%s,LightOn,,0,-1", headlightsName);
    DispatchKeyValue(entity, "OnTimer", tempString);
    Format(tempString, sizeof(tempString), "%s,HideSprite,,0.5,-1", lightsName);
    DispatchKeyValue(entity, "OnTimer", tempString);
    Format(tempString, sizeof(tempString), "%s,HideSprite,,0.5,-1", lightsName);
    DispatchKeyValue(entity, "OnTimer", tempString);
    Format(tempString, sizeof(tempString), "%s,LightOff,,0.5,-1", headlightsName);
    DispatchKeyValue(entity, "OnTimer", tempString);
    DispatchKeyValueVector(entity, "origin", vPos);
    DispatchSpawn(entity);

    SetVariantString(carName);
    AcceptEntityInput(entity, "SetParent", entity, entity, 0);
}

/****************************************************************************************************/

void CreateRemark(char[] targetName, float vPos[3], float vAng[3], char[] carName)
{
    int entity = CreateEntityByName("info_remarkable");

    DispatchKeyValue(entity, "targetname", targetName);
    DispatchKeyValue(entity, "contextsubject", "remark_caralarm");
    DispatchKeyValueVector(entity, "origin", vPos);
    DispatchKeyValueVector(entity, "angles", vAng);
    DispatchSpawn(entity);

    SetVariantString(carName);
    AcceptEntityInput(entity, "SetParent", entity, entity, 0);
}

/****************************************************************************************************/

void CreateGameEvent(char[] targetName, float vPos[3], float vAng[3], char[] carName)
{
    int entity = CreateEntityByName("info_game_event_proxy");

    DispatchKeyValue(entity, "targetname", targetName);
    DispatchKeyValue(entity, "spawnflags", "1");
    DispatchKeyValue(entity, "range", "100");
    DispatchKeyValue(entity, "event_name", "explain_disturbance");
    DispatchKeyValueVector(entity, "origin", vPos);
    DispatchKeyValueVector(entity, "angles", vAng);
    DispatchSpawn(entity);

    SetVariantString(carName);
    AcceptEntityInput(entity, "SetParent", entity, entity, 0);
}

/****************************************************************************************************/

void MoveVectorvPos3D(float vPos[3], float constvAng[3], float constDistance[3])
{
    float vAng[3], dirFw[3], dirRi[3], dirUp[3], distance[3];
    distance = constDistance;

    vAng[0] = DegToRad(constvAng[0]);
    vAng[1] = DegToRad(constvAng[1]);
    vAng[2] = DegToRad(constvAng[2]);

    // roll (rotation over x)
    dirFw[0] = 1.0;
    dirFw[1] = 0.0;
    dirFw[2] = 0.0;
    dirRi[0] = 0.0;
    dirRi[1] = Cosine(vAng[2]);
    dirRi[2] = Sine(vAng[2])*-1;
    dirUp[0] = 0.0;
    dirUp[1] = Sine(vAng[2]);
    dirUp[2] = Cosine(vAng[2]);
    MatrixMulti(dirFw, dirRi, dirUp, distance);

    // pitch (rotation over y)
    dirFw[0] = Cosine(vAng[0]);
    dirFw[1] = 0.0;
    dirFw[2] = Sine(vAng[0]);
    dirRi[0] = 0.0;
    dirRi[1] = 1.0;
    dirRi[2] = 0.0;
    dirUp[0] = Sine(vAng[0])*-1;
    dirUp[1] = 0.0;
    dirUp[2] = Cosine(vAng[0]);
    MatrixMulti(dirFw, dirRi, dirUp, distance);

    // yaw (rotation over z)
    dirFw[0] = Cosine(vAng[1]);
    dirFw[1] = Sine(vAng[1])*-1;
    dirFw[2] = 0.0;
    dirRi[0] = Sine(vAng[1]);
    dirRi[1] = Cosine(vAng[1]);
    dirRi[2] = 0.0;
    dirUp[0] = 0.0;
    dirUp[1] = 0.0;
    dirUp[2] = 1.0;
    MatrixMulti(dirFw, dirRi, dirUp, distance);

    // addition
    for (int i = 0; i < 3; i++) vPos[i] += distance[i];
}

/****************************************************************************************************/

void MatrixMulti(float matA[3], float matB[3], float matC[3], float vec[3])
{
    float res[3];
    for (int i = 0; i < 3; i++) res[0] += matA[i]*vec[i];
    for (int i = 0; i < 3; i++) res[1] += matB[i]*vec[i];
    for (int i = 0; i < 3; i++) res[2] += matC[i]*vec[i];
    vec = res;
}

/**
// ====================================================================================================
:::END::: -> Source Code from DieTeetasse - [L4D1&2] Spawn Alarmcars plugin https://forums.alliedmods.net/showthread.php?t=139352
// ====================================================================================================
*/

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdModelsReload(int client, int args)
{
    LoadModelsData();

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdCarAlarmRefresh(int client, int args)
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "p*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
            RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_replace_car_alarm) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_replace_car_alarm_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_replace_car_alarm_Activate : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_chance : %.1f%% (%s)", g_fCvar_Chance, g_bCvar_Chance ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_glass_on : %b (%s)", g_bCvar_GlassOn, g_bCvar_GlassOn ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_glass_off : %b (%s)", g_bCvar_GlassOff, g_bCvar_GlassOff ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_sound : %b (%s)", g_bCvar_Sound, g_bCvar_Sound ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_chirp : %b (%s)", g_bCvar_Chirp, g_bCvar_Chirp ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_lights : %b (%s)", g_bCvar_Lights, g_bCvar_Lights ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_headlights : %b (%s)", g_bCvar_Headlights, g_bCvar_Headlights ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_timer : %b (%s)", g_bCvar_Timer, g_bCvar_Timer ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_remark : %b (%s)", g_bCvar_Remark, g_bCvar_Remark ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_game_event : %b (%s)", g_bCvar_GameEvent, g_bCvar_GameEvent ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_targetname : %b (%s)", g_bCvar_Targetname, g_bCvar_Targetname ? "true" : "false");
    PrintToConsole(client, "l4d_replace_car_alarm_color : \"%s\"", g_sCvar_Color);
    PrintToConsole(client, "l4d_replace_car_alarm_ignore_car_alarm : %b (%s)", g_bCvar_IgnoreCarAlarm, g_bCvar_IgnoreCarAlarm ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "Map : \"%s\"", g_sMapName);
    PrintToConsole(client, "");
    PrintToConsole(client, "Models:");
    char modelname[64];
    for (int i = 0; i < g_alModel.Length; i++)
    {
        g_alModel.GetString(i, modelname, sizeof(modelname));
        PrintToConsole(client, "%s", modelname);
    }
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}

/****************************************************************************************************/

/**
 * Returns the integer array value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer array (int[3]) value of the RGB string or {0,0,0} if not in specified format.
 */
int[] ConvertRGBToIntArray(char[] sColor)
{
    int color[3];

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color[0] = StringToInt(sColors[0]);
        }
        case 2:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
        }
        case 3:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
            color[2] = StringToInt(sColors[2]);
        }
    }

    return color;
}