/**
 * l4d2_bot_no_auto_secondary.sp
 *
 * Prevents survivor bots from automatically switching to their secondary
 * weapon slot unless their primary weapon has truly run out of reserve ammo.
 * Bots will now prefer to reload their primary instead of drawing their
 * pistol (or melee weapon) mid-fight.
 *
 * L4D2 weapon slot layout:
 *   Slot 0  – Primary    (rifles, shotguns, grenade launcher, M60, etc.)
 *   Slot 1  – Secondary  (pistol, dual pistols, magnum, OR melee weapon)
 *                         Melee replaces the pistol/magnum when picked up.
 *   Slot 2  – Throwable  (molotov, pipe bomb, bile jar)
 *   Slot 3  – Medical    (first-aid kit, defibrillator, etc.)
 *   Slot 4  – Pills/Adrenaline
 *
 * How it works:
 *   SDKHook_WeaponSwitch fires before every weapon switch attempt.
 *   When a bot tries to go from slot-0 (primary) → slot-1 (secondary),
 *   we inspect the primary's reserve ammo.  If reserve > 0 the switch is
 *   blocked (Plugin_Handled); otherwise we allow it so the bot can still
 *   fall back when genuinely dry.
 *
 * M60 handling:
 *   By default ammo_m60_max is 0, meaning the M60 has no reserve and all
 *   150 rounds live in the clip.  However a server or mod may raise
 *   ammo_m60_max to any positive value, giving the M60 real reserve ammo.
 *   HasReserveAmmo() detects the M60 by classname and checks the convar
 *   directly so the plugin always respects the live server setting:
 *     ammo_m60_max == 0  → no reserve possible, bot may switch freely
 *                          once the clip is empty.
 *     ammo_m60_max  > 0  → reserve exists; fall through to the normal
 *                          m_iAmmo[] check just like any other primary.
 *
 * Grenade Launcher:
 *   Has a valid ammo type and real reserve grenades — handled correctly
 *   by the standard path; bots won't switch while grenades remain.
 *
 * Melee (slot 1):
 *   Occupies the secondary slot instead of a pistol/magnum.  The plugin
 *   blocks switching to it from a primary with remaining reserve, same as
 *   it would block switching to a pistol.
 *
 * Incapacitated:
 *   While a bot is downed they can only fire their pistol.  The plugin
 *   always allows the secondary switch in this state so the bot can shoot
 *   back while on the ground, regardless of primary reserve ammo.
 *
 * Ledge-hang (m_isHangingFromLedge):
 *   While hanging from a ledge the bot cannot fire any weapon at all.
 *   The switch is intentionally NOT exempted here — allowing it would
 *   leave the bot holding their pistol after they are rescued, with no
 *   benefit since they could not shoot during the hang anyway.
 *
 * Compatible with:
 *   Left 4 Dead 2  |  SourceMod 1.10+
 *
 * Installation:
 *   1. Compile: spcomp l4d2_bot_no_auto_secondary.sp
 *   2. Place the .smx in:
 *        <server>/left4dead2/addons/sourcemod/plugins/
 *   3. Loads automatically on the next map, or immediately via:
 *        sm plugins load l4d2_bot_no_auto_secondary
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ─── Plugin meta ─────────────────────────────────────────────────────────────

public Plugin myinfo =
{
    name        = "L4D2 Bot – No Auto Secondary Switch",
    author      = "BatoSaiX",
    description = "Blocks survivor bots from auto-drawing their secondary while primary reserve ammo remains",
    version     = "1.5.0",
    url         = ""
};

// ─── Constants ───────────────────────────────────────────────────────────────

#define TEAM_SURVIVOR       2
#define SLOT_PRIMARY        0
#define SLOT_SECONDARY      1
#define CLASSNAME_M60       "weapon_rifle_m60"

// ─── Globals ─────────────────────────────────────────────────────────────────

ConVar g_cvM60Max;   // ammo_m60_max — cached on load, stays live via the handle

// ─── Plugin lifecycle ─────────────────────────────────────────────────────────

public void OnPluginStart()
{
    // Cache the M60 reserve convar so we can query it at switch-time without
    // calling FindConVar() every frame.
    g_cvM60Max = FindConVar("ammo_m60_max");

    // Hook clients already in-game (hot / late-load support).
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            HookClient(i);
    }
}

public void OnClientPutInServer(int client)
{
    HookClient(client);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

void HookClient(int client)
{
    SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

/**
 * Returns true if the bot is downed and actively able to fire their pistol.
 *
 * m_isIncapacitated – set when the survivor is downed and crawling on the
 *                     ground.  In this state the pistol (secondary) is the
 *                     only weapon they can fire, so the switch must be
 *                     allowed.
 *
 * NOTE: m_isHangingFromLedge is intentionally NOT included here.  While
 * hanging, the bot cannot fire any weapon at all — their hands are occupied
 * holding the ledge.  Allowing the switch in that state would leave them
 * holding their pistol instead of their primary when pulled back up, with
 * no benefit since they cannot shoot anyway.
 */
bool IsIncapacitated(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

/**
 * Returns true if the given primary weapon currently has reserve ammo.
 *
 * Special case — M60:
 *   We first check ammo_m60_max.  If it is 0 (the default) the M60 was
 *   never given a reserve pool, so we return false immediately regardless
 *   of what m_iAmmo might say.  If ammo_m60_max > 0 a mod has enabled M60
 *   reserve ammo, and we fall through to the standard m_iAmmo[] read so
 *   the bot behaves correctly under that custom rule too.
 *
 * Standard path (all other primaries):
 *   m_iPrimaryAmmoType  – index into the player's m_iAmmo[] array.
 *   < 1  → weapon has no ammo pool at all; return false.
 *   >= 1 → read the live reserve count and return whether any remain.
 */
bool HasReserveAmmo(int client, int weapon)
{
    // ── M60 special case ─────────────────────────────────────────────────
    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));

    if (StrEqual(classname, CLASSNAME_M60))
    {
        // If the convar is missing for some reason, treat as no reserve.
        if (g_cvM60Max == null)
            return false;

        // ammo_m60_max == 0  →  no reserve by design; allow switching.
        // ammo_m60_max  > 0  →  reserve is enabled; fall through to the
        //                       normal m_iAmmo check below.
        if (g_cvM60Max.IntValue <= 0)
            return false;

        // Falls through intentionally to the standard reserve check.
    }

    // ── Standard reserve check ───────────────────────────────────────────
    int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (ammoType < 1)
        return false;

    // m_iAmmo is an int array; element size = 4 bytes, index = ammoType.
    int reserve = GetEntProp(client, Prop_Send, "m_iAmmo", 4, ammoType);
    return (reserve > 0);
}

// ─── Core hook ───────────────────────────────────────────────────────────────

/**
 * Called by the engine just before a weapon switch is committed.
 * Return Plugin_Handled to cancel; Plugin_Continue to allow.
 *
 * @param client   The player entity attempting the switch.
 * @param weapon   The weapon entity being switched TO.
 */
public Action OnWeaponSwitch(int client, int weapon)
{
    // ── Guard: only act on survivor bots ─────────────────────────────────
    if (!IsFakeClient(client))
        return Plugin_Continue;

    if (GetClientTeam(client) != TEAM_SURVIVOR)
        return Plugin_Continue;

    // ── Guard: always allow switch while downed (incapacitated) ──────────
    // Downed bots can only fire their secondary weapon.  Blocking the switch
    // here would leave them unable to shoot back while on the ground.
    // Ledge-hang is NOT exempt — bots cannot fire at all while hanging,
    // so the switch would only leave them on the wrong weapon after rescue.
    if (IsIncapacitated(client))
        return Plugin_Continue;

    // ── Guard: valid entity references ───────────────────────────────────
    if (!IsValidEntity(weapon))
        return Plugin_Continue;

    int primaryWeapon   = GetPlayerWeaponSlot(client, SLOT_PRIMARY);
    int secondaryWeapon = GetPlayerWeaponSlot(client, SLOT_SECONDARY);

    // If the bot has no primary or no secondary there is nothing to block.
    if (primaryWeapon == -1 || secondaryWeapon == -1)
        return Plugin_Continue;

    // ── Guard: must be switching FROM primary TO secondary ────────────────
    // The secondary slot may hold a pistol, magnum, dual pistols, OR a
    // melee weapon — all treated the same way.
    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    if (activeWeapon != primaryWeapon)
        return Plugin_Continue;   // Bot is not currently holding their primary.

    if (weapon != secondaryWeapon)
        return Plugin_Continue;   // Bot is not switching to their secondary.

    // ── Decision: block if reserve ammo still exists ─────────────────────
    if (HasReserveAmmo(client, primaryWeapon))
    {
        // Primary still has reserve ammo — keep the bot on their primary
        // so they reload rather than drawing their secondary prematurely.
        return Plugin_Handled;
    }

    // Reserve is exhausted; allow the natural fallback to the secondary.
    return Plugin_Continue;
}
