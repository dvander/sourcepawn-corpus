#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0-csgo-ayrton09"

static const char g_FirearmTokens[][] =
{
    "ak47",
    "aug",
    "awp",
    "bizon",
    "cz75",
    "deagle",
    "elite",
    "famas",
    "fiveseven",
    "g3sg1",
    "galil",
    "galilar",
    "glock",
    "hkp2000",
    "usp",
    "m249",
    "m4a1",
    "m4a1_silencer",
    "m4a4",
    "mac10",
    "mag7",
    "mp5",
    "mp7",
    "mp9",
    "negev",
    "nova",
    "p2000",
    "p250",
    "p90",
    "sawedoff",
    "scar20",
    "sg556",
    "ssg08",
    "tec9",
    "ump45",
    "xm1014",
    "revolver"
};

static const char g_ExcludedTokens[][] =
{
    "knife",
    "bayonet",
    "grenade",
    "flashbang",
    "smoke",
    "molotov",
    "incgrenade",
    "decoy",
    "hegrenade",
    "c4",
    "taser",
    "zeus",
    "breachcharge",
    "bumpmine",
    "healthshot",
    "tablet",
    "fists",
    "shield",
    "clipin",
    "clipout",
    "cliphit",
    "cliprelease",
    "draw",
    "deploy",
    "select",
    "pickup",
    "reload",
    "boltback",
    "boltforward",
    "boltpull",
    "boltrelease",
    "pump",
    "insertshell",
    "slideback",
    "sliderelease",
    "foley",
    "hit",
    "melee",
    "move",
    "coverup",
    "coverdown",
    "safety",
    "pinpull",
    "throw",
    "detonate",
    "drawback",
    "ready",
    "zoom",
    "silencer",
    "hammer",
    "idle"
};

ConVar gCvarVersion;
ConVar gCvarEnabled;
ConVar gCvarMusicLevel;
ConVar gCvarWeaponLevel;

public Plugin myinfo =
{
    name = "Sound Volume Control",
    author = "sinsic, port by Ayrton09",
    description = "Change map music and CS:GO firearm shot sound levels.",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
    gCvarVersion = CreateConVar(
        "zr_SVoC_version",
        PLUGIN_VERSION,
        "Sound Volume Control version.",
        FCVAR_NOTIFY|FCVAR_DONTRECORD
    );

    gCvarEnabled = CreateConVar(
        "zr_SVoC_Enabled",
        "3",
        "If plugin is enabled (0: Disable | 1: Map Music Control | 2: Weapon Sound Control | 3: Both)",
        FCVAR_NONE,
        true,
        0.0,
        true,
        3.0
    );

    gCvarMusicLevel = CreateConVar(
        "zr_SVoC_MLevel",
        "0.3",
        "Map music volume adjustment (0.0: No sound | 1.0: Full sound)",
        FCVAR_NONE,
        true,
        0.0,
        true,
        1.0
    );

    gCvarWeaponLevel = CreateConVar(
        "zr_SVoC_WLevel",
        "0.3",
        "Firearm shot volume adjustment (0.0: No sound | 1.0: Full sound)",
        FCVAR_NONE,
        true,
        0.0,
        true,
        1.0
    );

    HookConVarChange(gCvarVersion, OnVersionChanged);

    AddAmbientSoundHook(AmbientSoundHook);
    AddNormalSoundHook(NormalSoundHook);

    AutoExecConfig(true, "zr_SVoC", "sourcemod/zombiereloaded");
}

public void OnVersionChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(newValue, PLUGIN_VERSION))
    {
        convar.SetString(PLUGIN_VERSION);
    }
}

public Action AmbientSoundHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
    int mode = gCvarEnabled.IntValue;
    if (mode != 1 && mode != 3)
    {
        return Plugin_Continue;
    }

    int len = strlen(sample);
    if (len < 5)
    {
        return Plugin_Continue;
    }

    if (StrContains(sample, ".mp3", false) == -1 && StrContains(sample, ".wav", false) == -1)
    {
        return Plugin_Continue;
    }

    volume *= gCvarMusicLevel.FloatValue;
    return Plugin_Changed;
}

public Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    int mode = gCvarEnabled.IntValue;
    if (mode != 2 && mode != 3)
    {
        return Plugin_Continue;
    }

    if (!IsStrictCsgoFirearmShot(sample, soundEntry, channel))
    {
        return Plugin_Continue;
    }

    volume *= gCvarWeaponLevel.FloatValue;
    return Plugin_Changed;
}

bool IsStrictCsgoFirearmShot(const char[] sample, const char[] soundEntry, int channel)
{
    if (channel != SNDCHAN_WEAPON && channel != SNDCHAN_STATIC)
    {
        return false;
    }

    if (!LooksLikeWeaponPath(sample, soundEntry))
    {
        return false;
    }

    if (HasAnyToken(sample, soundEntry, g_ExcludedTokens, sizeof(g_ExcludedTokens)))
    {
        return false;
    }

    if (!HasAnyToken(sample, soundEntry, g_FirearmTokens, sizeof(g_FirearmTokens)))
    {
        return false;
    }

    return true;
}

bool LooksLikeWeaponPath(const char[] sample, const char[] soundEntry)
{
    return (StrContains(sample, "weapons/", false) != -1 || StrContains(soundEntry, "Weapon_", false) != -1);
}

bool HasAnyToken(const char[] sample, const char[] soundEntry, const char[][] tokens, int count)
{
    for (int i = 0; i < count; i++)
    {
        if (StrContains(sample, tokens[i], false) != -1 || StrContains(soundEntry, tokens[i], false) != -1)
        {
            return true;
        }
    }

    return false;
}

