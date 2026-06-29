#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#pragma semicolon 1
#pragma newdecls required

Database g_db;
ConVar g_cvEnabled;

public Plugin myinfo = 
{
    name = "L4D1 Weapon Saver",
    author = "Alexander Mirny",
    description = "Saves and restores players' weapons between sessions.",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    g_cvEnabled = CreateConVar("l4d_weaponsaver_enable", "1", "Enable or disable the plugin(0/1)", _, true, 0.0, true, 1.0);
    
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
    
    SQL_TConnect(OnDatabaseConnected, "l4d1_weapons");
}

public void OnDatabaseConnected(Handle owner, Handle hndl, const char[] error, any data) 
{
    if (hndl == null) {
        LogError("Database connection error: %s", error);
        return;
    }

    g_db = view_as<Database>(hndl);
    g_db.Query(SQL_ErrorCheckCallback, "CREATE TABLE IF NOT EXISTS weapons (steamid TEXT PRIMARY KEY, slot0 TEXT, slot1 TEXT, slot2 TEXT, slot3 TEXT, active_slot INT)");
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsClientInGame(client) && !IsFakeClient(client))
    {
        SaveClientWeapons(client);
    }
}

void SaveClientWeapons(int client)
{
	if(!g_cvEnabled.BoolValue) return;
		
	char steamId[32];
	if(!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
		return;
	  
	char weapons[4][64];
	int activeSlot = -1;
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
	for(int slot = 0; slot < 4; slot++)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if(weapon != -1)
        {
            GetEntityClassname(weapon, weapons[slot], sizeof(weapons[]));
            if(weapon == activeWeapon) activeSlot = slot;
        }
        else
        {
            weapons[slot][0] = '\0';
        }
    }
		
	char query[512];
	g_db.Format(query, sizeof(query), 
	"INSERT OR REPLACE INTO weapons (steamid, slot0, slot1, slot2, slot3, active_slot) "
	..."VALUES ('%s', '%s', '%s', '%s', '%s', %d)",
	steamId, 
	weapons[0], weapons[1], weapons[2], weapons[3], 
	activeSlot);
			
	g_db.Query(SQL_SaveWeaponsCallback, query);
			
	LogMessage("The weapon is saved by the player. %N: %s, %s, %s, %s (slot %d)", 
	client, weapons[0], weapons[1], weapons[2], weapons[3], activeSlot);
}

public void SQL_SaveWeaponsCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if(error[0])
    {
        LogError("Weapon saving error: %s", error);
    }
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!client || IsFakeClient(client)) return;
    
    RequestFrame(Frame_GiveWeapons, GetClientUserId(client));
}

void Frame_GiveWeapons(int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client || !IsClientInGame(client)) return;
    
    char steamId[32];
    if(!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
        return;
    
    char query[256];
    g_db.Format(query, sizeof(query), 
        "SELECT slot0, slot1, slot2, slot3, active_slot FROM weapons WHERE steamid = '%s'", 
        steamId);
    
    g_db.Query(SQL_LoadWeaponsCallback, query, GetClientSerial(client));
}

public void SQL_LoadWeaponsCallback(Database db, DBResultSet results, const char[] error, any data)
{
    int client = GetClientFromSerial(data);
    if(!client || !IsClientInGame(client)) return;
    
    if(error[0])
    {
        LogError("Weapon loading error: %s", error);
        return;
    }
    
    if(results.FetchRow())
    {
        RemoveAllWeapons(client);
        
        char weaponClass[32];
        int activeSlot = results.FetchInt(4);
        int weapons[4];
        
        int cheatFlags = GetCommandFlags("give");
        SetCommandFlags("give", cheatFlags & ~FCVAR_CHEAT);
        
        for(int slot = 0; slot < 4; slot++)
        {
            results.FetchString(slot, weaponClass, sizeof(weaponClass));
            if(weaponClass[0] && IsValidWeapon(weaponClass))
            {
                GiveWeaponWithCheats(client, weaponClass);
                weapons[slot] = GetPlayerWeaponSlot(client, slot);
                
                LogMessage("Restoring weapon %s to player %N in slot %d", 
                    weaponClass, client, slot);
            }
        }
        
        SetCommandFlags("give", cheatFlags);
        
        if(activeSlot >= 0 && activeSlot < 4 && weapons[activeSlot] != -1)
        {
            SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapons[activeSlot]);
            LogMessage("Installed active weapon for player %N in slot %d", client, activeSlot);
        }
    }
}

void GiveWeaponWithCheats(int client, const char[] weaponName)
{
    FakeClientCommand(client, "give %s", weaponName);
}

bool IsValidWeapon(const char[] weaponName)
{
    static const char validWeapons[][] = {
        "weapon_pistol", "weapon_rifle", "weapon_smg",
        "weapon_pumpshotgun", "weapon_autoshotgun", 
        "weapon_hunting_rifle", "weapon_first_aid_kit",
        "weapon_pipe_bomb", "weapon_molotov",
        "weapon_pain_pills"
    };
    
    for(int i = 0; i < sizeof(validWeapons); i++)
    {
        if(StrEqual(weaponName, validWeapons[i]))
            return true;
    }
    return false;
}

void RemoveAllWeapons(int client)
{
    int weapon;
    for(int slot = 0; slot < 5; slot++)
    {
        while((weapon = GetPlayerWeaponSlot(client, slot)) != -1)
        {
            RemovePlayerItem(client, weapon);
            RemoveEntity(weapon);
        }
    }
}

public void SQL_ErrorCheckCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if(error[0])
    {
        LogError("SQL Ошибка: %s", error);
    }
}