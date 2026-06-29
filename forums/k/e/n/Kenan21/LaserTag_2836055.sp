#include <sourcemod>
#include <sdktools>

#define VERSION "1.6"

// Teamdefinitionen
#define TERRORIST_TEAM 2
#define COUNTER_TERRORIST_TEAM 3

// Variablendeklarationen
new Handle:g_CvarEnable;
new Handle:g_CvarLife;
new Handle:g_CvarWidth;
new Handle:g_CvarAlpha;
new Handle:g_CvarColorT;
new Handle:g_CvarColorCT;

new Handle:hGetWeaponPosition;
new g_sprite;

public Plugin:myinfo =
{
    name = "Laser Tag",
    author = "Programmiert von FeritGang",
    description = "Laserstrahlen für alle Spieler. 1.6",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{
    // Variablen initialisieren
    g_CvarEnable = CreateConVar("sm_laser_tag_enable", "1", "Enable/Disable Laser Tag plugin", FCVAR_NOTIFY);
    g_CvarLife = CreateConVar("sm_laser_tag_life", "0.3", "Laser beam life duration (0.01 - 1.0 seconds)", FCVAR_NOTIFY);
    g_CvarWidth = CreateConVar("sm_laser_tag_width", "3.0", "Laser beam width (0.1 - 100.0)", FCVAR_NOTIFY);
    g_CvarAlpha = CreateConVar("sm_laser_tag_alpha", "150", "Laser beam alpha (transparency) (0-255)", FCVAR_NOTIFY);

    g_CvarColorT = CreateConVar("sm_laser_tag_t", "FF3F1F", "Terrorist laser beam color in HEX (RGB or RRGGBB)", FCVAR_NOTIFY);
    g_CvarColorCT = CreateConVar("sm_laser_tag_ct", "1F3FFF", "CT laser beam color in HEX (RGB or RRGGBB)", FCVAR_NOTIFY);

    // Konfigurationsdatei automatisch generieren
    AutoExecConfig(true, "laser_tag");

    g_sprite = PrecacheModel("materials/sprites/laser.vmt");

    // Fehlerprüfung beim Laden des Models
    if (g_sprite == -1)
    {
        PrintToServer("Fehler: Das Sprite 'materials/sprites/laser.vmt' konnte nicht geladen werden!");
    }

    // Spielekonfigurationsdatei laden
    Handle hGameConf = LoadGameConfigFile("laser_tag.games");
    if (hGameConf == INVALID_HANDLE)
    {
        PrintToServer("Fehler: gamedata/laser_tag.games.txt konnte nicht geladen werden.");
        return;
    }

    // SDKCall für Waffenschüsse initialisieren
    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "Weapon_ShootPosition"))
    {
        PrintToServer("Fehler: Weapon_ShootPosition konnte nicht initialisiert werden.");
        CloseHandle(hGameConf);
        return;
    }

    PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
    hGetWeaponPosition = EndPrepSDKCall();

    if (hGetWeaponPosition == INVALID_HANDLE)
    {
        PrintToServer("Fehler: hGetWeaponPosition ist ungültig.");
        CloseHandle(hGameConf);
        return;
    }

    CloseHandle(hGameConf);

    // Ereignishooks
    HookEvent("bullet_impact", BulletImpact);
}

public BulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!GetConVarBool(g_CvarEnable))
        return;

    // Angreifer validieren
    new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
    if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
        return;

    // Ursprung des Strahls abrufen
    new Float:bulletOrigin[3];
    GetClientEyePosition(attacker, bulletOrigin);

    // Winkel abrufen und Blickrichtung berechnen
    new Float:eyeAngles[3];
    GetClientEyeAngles(attacker, eyeAngles);

    new Float:bulletDirection[3];
    GetAngleVectors(eyeAngles, bulletDirection, NULL_VECTOR, NULL_VECTOR);

    // Zielpunkt erweitern
    new Float:bulletDestination[3];
    bulletDestination[0] = bulletOrigin[0] + (bulletDirection[0] * 5000.0);
    bulletDestination[1] = bulletOrigin[1] + (bulletDirection[1] * 5000.0);
    bulletDestination[2] = bulletOrigin[2] + (bulletDirection[2] * 5000.0);

    // Farbdaten basierend auf Teams laden
    new color[4];
    char hexColor[8];

    if (GetClientTeam(attacker) == TERRORIST_TEAM)
    {
        GetConVarString(g_CvarColorT, hexColor, sizeof(hexColor)); // HEX-Farbe abrufen
        ParseHexColor(hexColor, color); // Umwandeln in RGB
    }
    else if (GetClientTeam(attacker) == COUNTER_TERRORIST_TEAM)
    {
        GetConVarString(g_CvarColorCT, hexColor, sizeof(hexColor)); // HEX-Farbe abrufen
        ParseHexColor(hexColor, color); // Umwandeln in RGB
    }
    else
    {
        return;
    }
    color[3] = GetConVarInt(g_CvarAlpha);

    // Strahlen erzeugen
    TE_SetupBeamPoints(bulletOrigin, bulletDestination, g_sprite, 0, 0, 0,
        GetConVarFloat(g_CvarLife), GetConVarFloat(g_CvarWidth),
        GetConVarFloat(g_CvarWidth), 1, 0.0, color, 0);
    TE_SendToAll();
}

// Funktion zur Verarbeitung von HEX-Farbwerten
stock void ParseHexColor(const char[] hexColor, int color[4])
{
    if (strlen(hexColor) == 6) // Überprüfen, ob der HEX-String die richtige Länge hat
    {
        char red[3], green[3], blue[3];

        // Extrahieren der Farbanteile
        red[0] = hexColor[0];
        red[1] = hexColor[1];
        red[2] = '\0';

        green[0] = hexColor[2];
        green[1] = hexColor[3];
        green[2] = '\0';

        blue[0] = hexColor[4];
        blue[1] = hexColor[5];
        blue[2] = '\0';

        // Konvertieren von HEX zu RGB
        color[0] = StringToInt(red, 16);  // Rot
        color[1] = StringToInt(green, 16); // Grün
        color[2] = StringToInt(blue, 16);  // Blau
    }
    else
    {
        // Standardwerte: Rot für T, Blau für CT
        color[0] = 255; // Rot
        color[1] = 63;  // Grün
        color[2] = 31;  // Blau
    }
}