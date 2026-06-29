#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#define MENU_EXIT 0
#define DAMAGE_RECEIVED

Handle g_VIPMenu;
bool HasC4[MAXPLAYERS+1];
int CurrentRound = 0;
ConVar g_moneyPerDamage;
ConVar g_killBonus;
ConVar g_headshotBonus;
ConVar g_awp_active;
ConVar g_menu_active;
int g_healthAdd;
int g_healthHeadshotAdd;
int g_healthMax;


//Information:
public Plugin myinfo =
{

	//Initialize:
	name = "VIP Weapon",
	author = "+SyntX (Based on Dunn0)",
	description = "Gives Weapon",
	version = "1.0",
	url = "https://steamcommunity.com/id/syntx34"
}

public void OnPluginStart()
{
    // ConVars
    g_moneyPerDamage = CreateConVar("money_per_damage", "3", "Money awarded per damage point");
    g_killBonus = CreateConVar("money_kill_bonus", "200", "Kill bonus money");
    g_headshotBonus = CreateConVar("money_hs_bonus", "500", "Headshot bonus money");
    g_awp_active = CreateConVar("awp_active", "1", "Allow AWP for VIPs only");
    g_menu_active = CreateConVar("menu_active", "1", "VIP menu active");
    g_healthAdd = CreateConVar("vip_health", "15", "HP added on kill for VIPs");
    g_healthHeadshotAdd = CreateConVar("vip_health_hs", "30", "HP added on headshot for VIPs");
    g_healthMax = CreateConVar("vip_health_max", "100", "Maximum HP for VIPs");

    // Event Hooks
    HookEvent("player_hurt", OnPlayerHurt);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("round_start", OnRoundStart);
    HookEvent("round_end", OnRoundEnd);
 
    // Commands
    RegConsoleCmd("sm_viptest", VIPMenuCommand);
}

public Action VIPMenuCommand(int client, int args)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && CheckVIP(client))
    {
        // Re-create the menu each time it's opened
        Handle vipMenu = CreateMenu(VIPMenuHandler);
        SetMenuTitle(vipMenu, "Free VIP Guns");
        AddMenuItem(vipMenu, "1", "Get M4A1 + Dual Elites");
        AddMenuItem(vipMenu, "2", "Get AK47 + Dual Elites");
        AddMenuItem(vipMenu, "3", "Get AWP + Dual Elites");
        SetMenuExitButton(vipMenu, true);

        DisplayMenu(vipMenu, client, MENU_TIME_FOREVER);
    }
    else
    {
        CPrintToChat(client, "{green}[VIP Weapon] You are not authorized to access the VIP menu.");
    }
    return Plugin_Handled;
}

public int VIPMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        // Close the menu handle when the menu ends to prevent memory leaks.
        CloseHandle(menu); 
    }
    else if (action == MenuAction_Select)
    {
        if (IsClientInGame(client))
        {
            // Remove all weapons only after the player makes a selection.
            RemoveAllWeapons(client);

            // Give selected weapons based on menu choice
            if (item == 0)
            {
                GivePlayerWeapon(client, "weapon_m4a1", "weapon_elite");
                CPrintToChat(client, "{green}[VIP Weapon] You received M4A1 and Dual Elites!");
            }
            else if (item == 1)
            {
                GivePlayerWeapon(client, "weapon_ak47", "weapon_elite");
                CPrintToChat(client, "{green}[VIP Weapon] You received AK47 and Dual Elites!");
            }
            else if (item == 2)
            {
                GivePlayerWeapon(client, "weapon_awp", "weapon_elite");
                CPrintToChat(client, "{green}[VIP Weapon] You received AWP and Dual Elites!");
            }
        }
    }
    return 0;
}


public OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int damage = event.GetInt("dmg_health");

    if (IsClientInGame(attacker) && CheckVIP(attacker))
    {
        int moneyBonus = damage * GetConVarInt(g_moneyPerDamage);
        if (event.GetInt("hitgroup") == 1) // 1 = Headshot
        {
            moneyBonus += GetConVarInt(g_headshotBonus);
        }
        GivePlayerMoney(attacker, moneyBonus);
    }
}

public OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (IsClientInGame(attacker) && CheckVIP(attacker))
    {
        int hpAdd = (event.GetInt("headshot") == 1) ? GetConVarInt(g_healthHeadshotAdd) : GetConVarInt(g_healthAdd);
        int newHP = GetClientHealth(attacker) + hpAdd;
        newHP = (newHP > GetConVarInt(g_healthMax)) ? GetConVarInt(g_healthMax) : newHP;
        SetEntityHealth(attacker, newHP);
        CPrintToChat(attacker, "{green}[VIP Weapon] Healed +%d HP", hpAdd);
    }
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    CurrentRound++;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && CheckVIP(i))
        {
            GivePlayerItem(i, "weapon_hegrenade");
            GivePlayerItem(i, "weapon_flashbang");
            GivePlayerItem(i, "weapon_smokegrenade");
            GivePlayerItem(i, "item_assaultsuit");
            
            if (GetConVarBool(g_menu_active) && CurrentRound >= 3)
            {
                DisplayMenu(g_VIPMenu, i, MENU_TIME_FOREVER);
            }
        }
    }
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    CurrentRound = 0;
}

bool CheckVIP(int client)
{
    return IsClientInGame(client) && (GetUserFlagBits(client) & ADMFLAG_CUSTOM1); // Assuming CUSTOM1 is the VIP flag
}

void GivePlayerWeapon(int client, const char[] primaryWeapon, const char[] secondaryWeapon)
{
    RemoveAllWeapons(client); // Ensure all weapons are removed first
    GivePlayerItem(client, primaryWeapon); // Give the primary weapon immediately
    
    // Use a timer to add the secondary weapon after a brief delay (e.g., 0.1 seconds)
    CreateTimer(0.1, GiveSecondaryWeapon, client, TIMER_FLAG_NO_MAPCHANGE);
}

// Callback function to give the secondary weapon
public Action GiveSecondaryWeapon(Handle timer, int client)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        GivePlayerItem(client, "weapon_elite"); // Add the secondary weapon after the delay
        GivePlayerItem(client, "weapon_knife");  // Give knife as well if needed
    }
    return Plugin_Handled;
}



void RemoveAllWeapons(int client)
{
    int weapon = -1;
    while ((weapon = GetPlayerWeaponSlot(client, 0)) != -1)
    {
        RemovePlayerItem(client, weapon);
    }
}

void GivePlayerMoney(int client, int amount)
{
    int currentMoney = GetEntProp(client, Prop_Send, "m_iAccount");
    SetEntProp(client, Prop_Send, "m_iAccount", currentMoney + amount);
}
