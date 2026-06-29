#include <sourcemod>
#include <tf2_stocks>
#include <vsh2>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
    name = "[VSH2] Razorback",
    author = "Sajt",
    description = "Regenerates Sniper's Razorback with R key after dealing 1500 damage",
    version = PLUGIN_VERSION,
    url = ""
};

int g_iShieldDmg[MAXPLAYERS + 1];
int g_iReqDmg[MAXPLAYERS + 1];
bool g_bHadRazorback[MAXPLAYERS + 1];

#define DAMAGE 1500
#define DAMAGE_ADDITION 600

public void OnLibraryAdded(const char[] name) {
	if( StrEqual(name, "VSH2") ) {
		LoadVSH2Hooks();
	}
}

Handle g_HudRazorSync;

public void OnPluginStart() {
    HookEvent("player_death", SniperDed);
    HookEvent("arena_round_start", SniperRoundStart);
    HookEvent("teamplay_round_win", SniperRoundEnd);
    HookEvent("teamplay_round_stalemate", SniperRoundEnd);
    for (int i = 1; i <= MaxClients; i++) {
        g_iShieldDmg[i] = 0;
        g_iReqDmg[i] = DAMAGE;
    }
    g_HudRazorSync = CreateHudSynchronizer();

}

public void OnMapStart() {
    PrecacheSound("items/powerup_pickup_crits.wav");
}

public Action SniperRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++) {
    g_iShieldDmg[i] = 0;
    g_iReqDmg[i] = DAMAGE;
    }
    return Plugin_Continue;
}


public Action SniperRoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast) {
    for (int i = 1; i <= MaxClients; i++) {
    g_iShieldDmg[i] = 0;
    g_iReqDmg[i] = DAMAGE;
    g_bHadRazorback[i] = false;
    }
    return Plugin_Continue;
}


public Action SniperDed(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++) {
    g_iShieldDmg[i] = 0;
    g_iReqDmg[i] = DAMAGE;
    g_bHadRazorback[i] = false;
    }
    return Plugin_Continue;
}

public void LoadVSH2Hooks() {

	if( !VSH2_HookEx(OnPlayerHurt, VSH2_OnPlayerHurt) )
		LogError("Error loading OnPlayerHurt forwards for VSH2 plugin.");
		
	if( !VSH2_HookEx(OnRedPlayerHUD, RazorBackHUD) )
		LogError("Error loading OnBossCalcHealth forward for VSH2 plugin.");
}

public void OnClientPutInServer(int client) {
    g_iShieldDmg[client] = 0;
    g_iReqDmg[client] = DAMAGE;
}

public Action OnPlayerRunCmd(int client, int &buttons) {
    if (IsValidClient(client) && (buttons & IN_RELOAD) && TF2_GetPlayerClass(client) == TFClass_Sniper) {
        
        if (!g_bHadRazorback[client]) return Plugin_Continue;

        bool hasRazorback = GetRazorBack(client) != -1;
        if (hasRazorback || GetEntProp(client, Prop_Send, "m_bShieldEquipped", 1))
            return Plugin_Continue;

        if (g_iShieldDmg[client] >= g_iReqDmg[client]) {
            RegenerateRazorback(client);
            EmitSoundToClient(client, "items/powerup_pickup_crits.wav", client);
            g_iReqDmg[client] += DAMAGE_ADDITION;
        }
    }
    return Plugin_Continue;
}

public void VSH2_OnPlayerHurt(const VSH2Player attacker, const VSH2Player victim, Event event) {
    if (!IsValidClient(attacker.index) || GetClientTeam(attacker.index) == GetClientTeam(victim.index)) {
        return;
    }
    if (attacker.iTFClass != TFClass_Sniper) {
        return;
    }
    if (attacker.bIsMinion) {
        return;
    }
    int damage = event.GetInt("damageamount");
    g_iShieldDmg[attacker.index] += damage;
}

void RegenerateRazorback(int client) {
    
    int health = GetClientHealth(client);
    int primammo = GetAmmo(client, TFWeaponSlot_Primary);
    int primclip = GetClip(client, TFWeaponSlot_Primary);
    int secammo = GetAmmo(client, TFWeaponSlot_Secondary);
    int secclip = GetClip(client, TFWeaponSlot_Secondary);

    TF2_RegeneratePlayer(client);
    SetEntityHealth(client, health);

    SetAmmo(client, TFWeaponSlot_Primary, primammo);
    SetClip(client, TFWeaponSlot_Primary, primclip);
    SetAmmo(client, TFWeaponSlot_Secondary, secammo);
    SetClip(client, TFWeaponSlot_Secondary, secclip);

    g_iShieldDmg[client] = 0;
    g_bHadRazorback[client] = true;
}

public Action RazorBackHUD(const VSH2Player player, char hud_text[PLAYER_HUD_SIZE]) {
    int client = GetClientOfUserId(player.userid);
    if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Continue;
    if (GetClientTeam(client) != VSH2Team_Red) return Plugin_Continue;
    if (TF2_GetPlayerClass(client) != TFClass_Sniper) return Plugin_Continue;

    bool hasRazorback = (GetRazorBack(client) != -1);
    if (hasRazorback) g_bHadRazorback[client] = true;
    
    if (!g_bHadRazorback[client]) return Plugin_Continue;

    if (GetEntProp(client, Prop_Send, "m_bShieldEquipped")) return Plugin_Continue;

    char hudText[64];
    if (!hasRazorback && g_iShieldDmg[client] >= g_iReqDmg[client]) {
        Format(hudText, sizeof(hudText), "Ready: Press R(Reload)!\nRazorback: Not Equipped");
    } else {
        Format(hudText, sizeof(hudText), "Razorback Damage: %d/%d\nRazorback: %s",
            g_iShieldDmg[client], g_iReqDmg[client], hasRazorback ? "Equipped" : "Not Equipped");
    }

    SetHudTextParams(0.8, 0.8, 0.35, 255, 0, 0, 255);
    ShowSyncHudText(client, g_HudRazorSync, hudText);
    return Plugin_Continue;
}

stock bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock void SetAmmo(const int client, const int slot, const int ammo)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if( IsValidEntity(weapon) ) {
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}
stock void SetClip(const int client, const int slot, const int ammo)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if( IsValidEntity(weapon) ) {
		int iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(weapon, iAmmoTable, ammo, 4, true);
	}
}
stock int GetAmmo(const int client, const int slot)
{
	if( !IsValidClient(client) )
		return 0;
	int weapon = GetPlayerWeaponSlot(client, slot);
	if( IsValidEntity(weapon) ) {
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(client, iAmmoTable+iOffset);
	}
	return 0;
}
stock int GetClip(const int client, const int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if( IsValidEntity(weapon) ) {
		int AmmoClipTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		return GetEntData(weapon, AmmoClipTable);
	}
	return 0;
}

stock int GetRazorBack(int client)
{
	int numwearables = TF2_GetNumWearables(client);
	for( int i=numwearables-1; i>=0; --i ) {
		int wearable = TF2_GetWearable(client, i);
		if( wearable && !GetEntProp(wearable, Prop_Send, "m_bDisguiseWearable") ) {
			char cls[32];
			if( GetEntityClassname(wearable, cls, sizeof(cls)), !strncmp(cls, "tf_wearable_razo", 16, false) ) {
				return wearable;
			}
		}
	}
	return -1;
}

stock int TF2_GetNumWearables(int client)
{
	/// 3552 linux
	/// 3532 windows
	int offset = FindSendPropInfo("CTFPlayer", "m_flMaxspeed") - 20 + 12;
	return GetEntData(client, offset);
}

stock int TF2_GetWearable(int client, int wearableidx)
{
	/// 3540 linux
	/// 3520 windows
	int offset = FindSendPropInfo("CTFPlayer", "m_flMaxspeed") - 20;
	Address m_hMyWearables = view_as< Address >(LoadFromAddress(GetEntityAddress(client) + view_as< Address >(offset), NumberType_Int32));
	return LoadFromAddress(m_hMyWearables + view_as< Address >(4 * wearableidx), NumberType_Int32) & 0xFFF;
}