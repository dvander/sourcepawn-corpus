//# vim: set filetype=cpp :

/*
* license = "https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html#SEC1",
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required
#define PLUGIN_NAME "Scuffle"
#define PLUGIN_VERSION "0.0.18"

ConVar g_cvRequires; char g_requirementsRaw[1024];  // e.g., "kit=30;pills=50;adrenaline"
char g_requirements[32][32];  // required items to revive e.g., kit, pills, adrenaline
ConVar g_cvRequireSlots; char g_requireSlots[5];  // user defined slot order to scan for requirements
bool g_requireNil;  // true if survivors require nothing to scuffle
bool g_requireAny;  // true if any item can be provided for a scuffle

float g_itemHealthMap[32];  // health map of items (above) e.g., 50.0, 0.0, 10.0
float g_itemHealth[MAXPLAYERS + 1];  // [client] current item health e.g, 50.0, 0.0, 10.0

int g_attackId[MAXPLAYERS + 1];  // who is attacking [client]? -1 ledge, -2 ground, >0 SI Id
int g_payments[MAXPLAYERS + 1];  // if an item to revive is required, this holds [client] entity to be killed
int g_health[MAXPLAYERS + 1];  // [client] health state
float g_healthBuffer[MAXPLAYERS + 1];  // [client] health buffer state
float g_cooldowns[MAXPLAYERS + 1];  // [client] = GetGameTime() + float;
int g_scuffling[MAXPLAYERS + 1];  // is [client] in a scuffle?
int g_cleanup[MAXPLAYERS + 1];  // clean up [client] arrays?
int g_lastKeyPress[MAXPLAYERS + 1];  // last key [client] pressed (during scuffle)
float g_lastScuffle[MAXPLAYERS + 1];  // time remaining until [client] meets g_reviveDuration

ConVar g_cvDecayRate;
ConVar g_cvHealthReviveBit;
ConVar g_cvMaxRevives;

#define g_decayRate GetConVarFloat(g_cvDecayRate)
#define g_healthReviveBit GetConVarFloat(g_cvHealthReviveBit)
#define g_maxRevives GetConVarInt(g_cvMaxRevives)

ConVar g_cvCooldown; float g_cooldown;  // time it takes before reviving is possible again
ConVar g_cvLastLeg; int g_lastLeg;  // reviving turns off when m_currentReviveCount matches
ConVar g_cvMinHealth; int g_minHealth;  // minimum amount of health to be able to revive

ConVar g_cvAnyTokens; int g_anyToken;  // tokens shared among all types of -1
int g_anyTokens[MAXPLAYERS + 1];  // how many tokens does [client] have left?
ConVar g_cvAttackTokens; int g_attackToken;  // tokens to break an SI hold
int g_attackTokens[MAXPLAYERS + 1];  // how many tokens does [client] have left against SI?
ConVar g_cvLedgeTokens; int g_ledgeToken;  // tokens for picking oneself up from a ledge
int g_ledgeTokens[MAXPLAYERS + 1];  // how many tokens does [client] have against ledges?
ConVar g_cvGroundTokens; int g_groundToken;  // tokens to get up from the ground
int g_groundTokens[MAXPLAYERS + 1];  // how many tokens does [client] have to get up from the ground?

ConVar g_cvDuration; float g_reviveDuration;  //
ConVar g_cvReviveHold; float g_reviveHoldTime;
ConVar g_cvReviveTap; float g_reviveTapTime;
ConVar g_cvReviveLoss; float g_reviveLossTime;
ConVar g_cvReviveShiftBit; int g_reviveShiftBit;
ConVar g_cvKillChance; int g_killChance;
ConVar g_cvStayDown; bool g_stayDown;
ConVar g_cvHurtSurvivor; int g_hurtSurvivor;  // applies if survivor revives themselves

int g_blockDamage[MAXPLAYERS + 1];  // block [client] = attackerId
float g_staggerTime[MAXPLAYERS + 1];  // stagger time on [attackerId] until GetGameTime + float
float g_staggers[4];  // hunter, smoker, charger, jockey. See IsPlayerInTrouble

ConVar g_cvHunterStagger;
ConVar g_cvSmokerStagger;
ConVar g_cvChargerStagger;
ConVar g_cvJockeyStagger;

char g_shiftKey[26];
char g_shiftKeyMap[26][26] = {
    "+attack",      // 0    IN_ATTACK
    "+jump",        // 1    IN_JUMP
    "+duck",        // 2    IN_DUCK
    "+forward",     // 3    IN_FORWARD
    "+back",        // 4    IN_BACK
    "+use",         // 5    IN_USE
    "+cancel",      // 6?   IN_CANCEL
    "+left",        // 7    IN_LEFT
    "+right",       // 8?   IN_RIGHT
    "+moveleft",    // 9?   IN_MOVELEFT
    "+moveright",   // 10   IN_MOVERIGHT
    "+attack2",     // 11   IN_ATTACK2
    "+run",         // 12?  IN_RUN
    "+reload",      // 13   IN_RELOAD
    "+alt1",        // 14?  IN_ALT1
    "+alt2",        // 15?  IN_ALT2
    "+score",       // 16?  IN_SCORE
    "+speed",       // 17   IN_SPEED  // THIS IS WALK
    "+walk",        // 18?  IN_WALK
    "+zoom",        // 19   IN_ZOOM
    "+weapon1",     // 20?  IN_WEAPON1
    "+weapon2",     // 21?  IN_WEAPON2
    "+bullrush",    // 22?  IN_BULLRUSH
    "+grenade1",    // 23?  IN_GRENADE1
    "+grenade2",    // 24?  IN_GRENADE2
    "+attack3"      // 25   IN_ATTACK3
};

public Plugin myinfo= {
    name = PLUGIN_NAME,
    author = "Lux & Victor \"NgBUCKWANGS\" Gonzalez",
    description = "Scuffle Back Into the Fight",
    version = PLUGIN_VERSION,
    url = "https://github.com/LuxLuma/Scuffle"
}

public void OnMapStart() {
    ResetAllClients(true);
}

void ResetAllClients(bool hardReset=false) {

    /**
    * Reset all client scuffle tracking (see ResetClient)
    *
    * @param hardReset  Reset middle state, default is false
    * @return void
    */

    for (int i = 1; i <= MaxClients; i++) {
        ResetClient(i, hardReset);
    }
}

void ResetClient(int client, bool hardReset=false) {

    /**
    * Reset specific client scuffle tracking
    *
    * Scuffle keeps track of a clients state and upon healing, death, restart
    * and joining of the server, that information should be reset and cleaned.
    * See OnPlayerRunCmd on how these arrays are used. The hardReset argument
    * will reset a clients revival tokens, cooldown and block damage arrays.
    *
    * Variables immediately reset are those that are defined during a scuffle.
    * It is safe to reset a client at any point as whether or not they're in a
    * scuffle, these variables will be immediately defined again when needed.
    * The hardReset argument resets all client tracking (information that is
    * tracked between scuffles e.g., tokens, cooldown, etc).
    *
    * @param client     Client to reset
    * @param hardReset  Reset middle state, default is false
    * @return void
    */

    g_cleanup[client] = 0;
    g_lastScuffle[client] = 0.0;
    g_staggerTime[client] = 0.0;
    g_lastKeyPress[client] = 0;
    g_scuffling[client] = 0;
    g_payments[client] = 0;
    g_attackId[client] = 0;

    if (hardReset) {
        ResetClientTokens(client);
        g_cooldowns[client] = 0.0;
        g_blockDamage[client] = 0;
    }
}

void ResetAllClientTokens() {

    /**
    * Reset all clients token tally on server (see ResetClientTokens)
    *
    * @return void
    */

    for (int i = 1; i <= MaxClients; i++) {
        ResetClientTokens(i);
    }
}

void ResetClientTokens(int client) {

    /**
    * Reset specific clients token tally on server.
    *
    * Tokens represent the number of times a survivor can self revive. There
    * are 4 different types. Any, ledge, ground and attack. A value of -1 means
    * infinite and anything else will be decremented on self-revival. If "any" is
    * set to -1 then all types are infinite (see CanPlayerScuffle). If "any" is
    * set to 0 or higher, the value is shared among all types of -1 value.
    *
    * If you would like a survivor to self-revive in any situation up to and
    * no more than 10 times (until death, heal and round start), set "any" to 10
    * and the rest to -1. This will allow self-revival in any situation up to
    * 10 times. If you would like to limit a specific revival, set it and that'll
    * be the total times a self-revival can happen in that specific situation.
    *
    * If "any" is greater than zero, its value is shared among all -1 types until
    * "any" reaches zero and all scuffling is disabled. The value of "any" will
    * change *if* a value greater than -1 is provided for all remaining types.
    *
    * @param client     Client to reset
    * @return void
    */

    g_ledgeTokens[client] = g_ledgeToken;
    g_groundTokens[client] = g_groundToken;
    g_attackTokens[client] = g_attackToken;
    g_anyTokens[client] = g_anyToken;

    static int i;
    i = 0;

    if (g_anyToken > -1) {
        if (g_ledgeToken > -1) {
            g_anyTokens[client] += g_ledgeToken;
            i++;
        }

        if (g_groundToken > -1) {
            g_anyTokens[client] += g_groundToken;
            i++;
        }

        if (g_attackToken > -1) {
            g_anyTokens[client] += g_attackToken;
            i++;
        }

        if (i == 3) {
            g_anyTokens[client] = (
                g_ledgeToken + g_groundToken + g_attackToken
            );

            SetConVarInt(g_cvAnyTokens, g_anyTokens[client]);
        }
    }
}

bool IsEntityValid(int ent) {

    /**
    * Check if an entity is valid
    *
    * @param ent    Entity to check for validity
    * @return void
    */

    return (ent > MaxClients && ent <= 2048 && IsValidEntity(ent));
}

public void OnClientPostAdminCheck(int client) {

    /**
    * Setup for clients entering the server
    *
    */

    if (client > 0) {
        if (IsClientConnected(client) && !IsFakeClient(client)) {
            SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);
            ResetClient(client, true);
        }
    }
}

public void OnPluginStart() {
    LoadTranslations("scuffle.phrases");

    HookEvent("round_start", RoundStartHook);
    HookEvent("heal_success", HealSuccessHook);
    HookEvent("player_death", PlayerDeathHook);
    HookEvent("bot_player_replace", BotPlayerReplaceHook, EventHookMode_Pre);

    // get a handle on general cvars required for scuffle
    g_cvDecayRate = FindConVar("pain_pills_decay_rate");
    g_cvHealthReviveBit = FindConVar("survivor_revive_health");
    g_cvMaxRevives = FindConVar("survivor_max_incapacitated_count");

    // setup the cvars we created specifically for scuffle
    SetupCvar(g_cvAnyTokens, "scuffle_any", "-1", "-1: Infinite. >0: Shared with attack, ledge and ground tokens of value -1.");
    SetupCvar(g_cvAttackTokens, "scuffle_attack", "-1", "-1: Infinite. >0: Times a survivor can revive from an SI attack hold.");
    SetupCvar(g_cvLedgeTokens, "scuffle_ledge", "-1", "-1: Infinite. >0: Times a survivor can revive from a ledge.");
    SetupCvar(g_cvGroundTokens, "scuffle_ground", "-1", "-1: Infinite. >0: Times a survivor can revive from the ground.");
    SetupCvar(g_cvRequires, "scuffle_requires", "", "Semicolon separated items and health e.g., 'item1=temphealth;item2'.");
    SetupCvar(g_cvCooldown, "scuffle_cooldown", "10", "Cooldown (no reviving) between self-revivals.");
    SetupCvar(g_cvLastLeg, "scuffle_lastleg", "2", "-1: Off: >=0: Stop self revivals at this strike.");
    SetupCvar(g_cvMinHealth, "scuffle_minhealth", "0", "Stop self revivals at this health.");
    SetupCvar(g_cvDuration, "scuffle_duration", "30.0", "Overall time to spread holds and taps.");
    SetupCvar(g_cvReviveHold, "scuffle_holdtime", "0.1", "Time deduced on server frame when holding scuffle_shiftbit.");
    SetupCvar(g_cvReviveTap, "scuffle_taptime", "1.5", "Time deduced on server frame when tapping scuffle_shiftbit.");
    SetupCvar(g_cvReviveLoss, "scuffle_losstime", "0.2", "Time added on server frame when missing scuffle_shiftbit.");
    SetupCvar(g_cvReviveShiftBit, "scuffle_shiftbit", "1", "Shift bit for revival see https://sm.alliedmods.net/api/index.php?fastload=file&id=47&");
    SetupCvar(g_cvKillChance, "scuffle_killchance", "0", "Chance of killing an SI when reviving.");
    SetupCvar(g_cvStayDown, "scuffle_staydown", "0", "0: Break SI hold and get up. 1: Break SI hold and stay down.");
    SetupCvar(g_cvHunterStagger, "scuffle_hunterstagger", "3.0", "Hunter stagger and secondary attack block time.");
    SetupCvar(g_cvSmokerStagger, "scuffle_smokerstagger", "1.2", "Smoker stagger and secondary attack block time.");
    SetupCvar(g_cvChargerStagger, "scuffle_chargerstagger", "3.5", "Charger stagger and secondary attack block time.");
    SetupCvar(g_cvJockeyStagger, "scuffle_jockeystagger", "1.2", "Jockey stagger and secondary attack block time.");
    SetupCvar(g_cvRequireSlots, "scuffle_slots", "", "Zero based slot search order (slot 1 is ignored).");
    SetupCvar(g_cvHurtSurvivor, "scuffle_hurt", "1", "Hurt survivor this amount per second (applies on self revival).");
    AutoExecConfig(true, "scuffle");

    // if scuffle is reloaded, get all clients back on the same page
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && IsClientInGame(i)) {
            OnClientPostAdminCheck(i);
        }
    }
}

public void RoundStartHook(Handle event, const char[] name, bool dontBroadcast) {
    ResetAllClients(true);
}

public void HealSuccessHook(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "subject"));
    ResetClient(client, true);
    SetRevive(client, 0);
}

public void PlayerDeathHook(Handle event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    ResetClient(client, true);
    SetRevive(client, 0);
}

public void BotPlayerReplaceHook(Handle event, const char[] name, bool dontBroadcast) {
    int target = GetClientOfUserId(GetEventInt(event, "bot"));
    int client = GetClientOfUserId(GetEventInt(event, "player"));
    SetRevive(client, GetEntProp(target, Prop_Send, "m_currentReviveCount"));
}

void SetRevive(int client, int count) {

    /**
    * Set a client's revival count (for survivors only)
    *
    * If a clients revival count is less than m_currentReviveCount stop any
    * heartbeat sound and return the clients vision to normal. If revive count
    * is greater than or equal to survivor_max_incapacitated_count emit the
    * heartbeat and visually notify client with "black and white" vision.
    *
    * @param client     Client to modify
    * @param count      Client's current revival count
    * @return void
    */

    if (client <= 0) {
        return;
    }

    // https://forums.alliedmods.net/showpost.php?p=1583406&postcount=4
    if (IsClientConnected(client) && GetClientTeam(client) == 2) {
        if (!IsFakeClient(client)) {
            bool isMaxed = count >= g_maxRevives;

            switch (isMaxed && !GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1)) {
                case 1: EmitSoundToClient(client, "player/heartbeatloop.wav");
                case 0: StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
            }

            SetEntProp(client, Prop_Send, "m_currentReviveCount", count);
            SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", isMaxed, 1);
            SetEntProp(client, Prop_Send, "m_isGoingToDie", isMaxed);
        }
    }
}

void SetupCvar(Handle &cvHandle, char[] name, char[] value, char[] details) {

    /**
    * Create, hook and update console variables (a convenient wrapper)
    *
    * Create a cvar and hook it to UpdateConVarsHook to watch for updates. Give
    * the cvar a name, a value and provide helpful usage details. SetupCvar is
    * a fast and painless way to create cvars quickly.
    *
    * @param cvHandle   Console variable handle (cvar)
    * @param name       Name of cvar to create
    * @param value      Cvar value
    * @param details    Cvar details
    * @return void
    */

    cvHandle = CreateConVar(name, value, details);
    HookConVarChange(cvHandle, UpdateConVarsHook);
    UpdateConVarsHook(cvHandle, value, value);
}

public void UpdateConVarsHook(Handle cvHandle, const char[] oldVal, const char[] newVal) {

    /**
    * Manage and cache console variable (cvar) changes
    *
    * When a cvar we've hooked is changed, it'll go through here. Most changes
    * are simple and the new value is cached into a global variable. In few cases
    * values may require parsing or validation before having it's final value
    * globally accessible.
    *
    */

    char cvName[32], cvVal[128];
    GetConVarName(cvHandle, cvName, sizeof(cvName));
    Format(cvVal, sizeof(cvVal), "%s", newVal);
    SetConVarString(cvHandle, newVal);

    if (StrEqual(cvName, "scuffle_requires")) {

        g_requireNil = false;
        g_requireAny = false;

        // clean up the previous item/health arrays
        for (int i = 0; i < sizeof(g_requirements[]); i++) {
            g_itemHealthMap[i] = 0.0;
            g_requirements[i] = "";
        }

        GetConVarString(cvHandle, g_requirementsRaw, sizeof(g_requirementsRaw));
        ExplodeString(cvVal, ";", g_requirements, 32, sizeof(g_requirements[]));

        static char reqs[32][32];
        if (g_requirements[0][0] == EOS) {
            g_requireNil = true;
            return;
        }

        for (int i = 0; i < sizeof(g_requirements[]); i++) {
            ExplodeString(g_requirements[i], "=", reqs, 32, sizeof(reqs[]));

            switch (g_requirements[i][0] == EOS) {
                case 1: break;
                case 0: {
                    g_requirements[i] = reqs[0];
                    g_itemHealthMap[i] = StringToFloat(reqs[1]);
                    reqs[1] = "0.0";

                    if (StrEqual(reqs[0], "any", false)) {
                        g_requireAny = true;
                    }
                }
            }
        }
    }

    else if (StrEqual(cvName, "scuffle_cooldown")) {
        g_cooldown = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_lastleg")) {
        SetConVarBounds(cvHandle, ConVarBound_Lower, true, -1.0);
        SetConVarBounds(cvHandle, ConVarBound_Upper, true, float(g_maxRevives));
        g_lastLeg = GetConVarInt(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_minhealth")) {
        g_minHealth = GetConVarInt(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_any")) {
        g_anyToken = GetConVarInt(cvHandle);
        ResetAllClientTokens();
    }

    else if (StrEqual(cvName, "scuffle_attack")) {
        g_attackToken = GetConVarInt(cvHandle);
        ResetAllClientTokens();
    }

    else if (StrEqual(cvName, "scuffle_ledge")) {
        g_ledgeToken = GetConVarInt(cvHandle);
        ResetAllClientTokens();
    }

    else if (StrEqual(cvName, "scuffle_ground")) {
        g_groundToken = GetConVarInt(cvHandle);
        ResetAllClientTokens();
    }

    else if (StrEqual(cvName, "scuffle_duration")) {
        g_reviveDuration = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_holdtime")) {
        g_reviveHoldTime = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_taptime")) {
        g_reviveTapTime = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_losstime")) {
        g_reviveLossTime = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_shiftbit")) {
        static int shiftBit;
        shiftBit = GetConVarInt(cvHandle);
        SetConVarBounds(cvHandle, ConVarBound_Lower, true, 0.0);
        SetConVarBounds(cvHandle, ConVarBound_Upper, true, 25.0);
        g_shiftKey = g_shiftKeyMap[shiftBit];
        g_reviveShiftBit = 1 << shiftBit;
    }

    else if (StrEqual(cvName, "scuffle_killchance")) {
        SetConVarBounds(cvHandle, ConVarBound_Lower, true, 0.0);
        SetConVarBounds(cvHandle, ConVarBound_Upper, true, 100.0);
        g_killChance = GetConVarInt(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_staydown")) {
        g_stayDown = GetConVarBool(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_hunterstagger")) {
        g_staggers[0] = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_smokerstagger")) {
        g_staggers[1] = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_chargerstagger")) {
        g_staggers[2] = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_jockeystagger")) {
        g_staggers[3] = GetConVarFloat(cvHandle);
    }

    else if (StrEqual(cvName, "scuffle_slots")) {
        GetConVarString(cvHandle, g_requireSlots, sizeof(g_requireSlots));
        // survivors always have pistols when incapacitated
        ReplaceString(g_requireSlots, sizeof(g_requireSlots), "1", "");
    }

    else if (StrEqual(cvName, "scuffle_hurt")) {
        g_hurtSurvivor = GetConVarInt(cvHandle);
    }
}

bool HasRequirement(int client) {

    /**
    * Check if client meets scuffling requirements
    *
    * If a specific item (e.g., pills, adrenaline) is required for a scuffle,
    * this function will scan client for that item. If an item has its health
    * defined, its associated health is only applied after striking the client.
    * If a survivor never fully goes down and isn't truly incapacitated, the
    * associated health will not be applied.
    *
    * Searches are case insensitive (e.g, KIT = Kit = kit). They can also be
    * shortened (e.g., KIT = weapon_first_aid_kit). A special item called "any"
    * can also be used and it's position will make a difference. If "any" is at
    * position zero, we return on the first item found in scanned slots. If "any"
    * is in a non-zero position, all other items will be fully considered.
    *
    * @param client     Survivor to scan for requirement
    * @return           True if client has requirement, false otherwise
    */

    if (g_requireNil) {
        return true;
    }

    static char slot[2];
    static char item[32];
    static int anyEnt; anyEnt = 0;
    static float anyEntHealth; anyEntHealth = 0.0;
    static bool breakMain; breakMain = false;
    static int ent;

    for (int i = 0; i <= sizeof(g_requireSlots); i++) {

        if (breakMain || g_requireSlots[i] == EOS) {
            break;
        }

        strcopy(slot, 2, g_requireSlots[i]);  // get the slot
        ent = GetPlayerWeaponSlot(client, StringToInt(slot));

        if (IsEntityValid(ent)) {
            GetEntityClassname(ent, item, sizeof(item));

            if (anyEnt == 0 && g_requireAny) {
                anyEnt = ent;
            }

            for (int j = 0; j < sizeof(g_requirements[]); j++) {

                if (g_requirements[j][0] == EOS) {
                    break;
                }

                else if (StrContains(item, g_requirements[j], false) >= 0) {
                    g_itemHealth[client] = g_itemHealthMap[j];
                    g_payments[client] = ent;
                    return true;
                }

                else if (StrEqual("any", g_requirements[j], false)) {
                    anyEntHealth = g_itemHealthMap[j];

                    if (j == 0) {
                        breakMain = true;
                        break;
                    }
                }
            }
        }
    }

    if (IsEntityValid(anyEnt)) {
        g_itemHealth[client] = anyEntHealth;
        g_payments[client] = anyEnt;
        return true;
    }

    return false;
}

bool CanPlayerScuffle(int client) {

    /**
    * Check if a survivor can scuffle and notify as to why or why not
    *
    * There are several reasons why a survivor may or may not be able to self
    * revive and this function will check for that reason. The function has early
    * termination logic and should be used with IsPlayerInTrouble. If a survivor
    * is in trouble, has already been scanned and is not in cooldown, early
    * termination applies with the previous status as the reason.
    *
    * Early termination for all reasons but cooldown are final. If a client is in
    * cooldown, the cooldown must be fully over with before CanPlayerScuffle will
    * scan them again.
    *
    * @param client     Survivor to check for self revival
    * @return           True if client can scuffle, false otherwise
    */

    static char key[32];
    static char notice[128];
    static int status[MAXPLAYERS + 1];
    static int attack[MAXPLAYERS + 1];

    if (g_scuffling[client]) {
        if (attack[client] == g_attackId[client]) {
            if (status[client] != -3) {
                return status[client] > 0;
            }

            else if (g_cooldowns[client] > GetGameTime()) {
                return false;
            }
        }
    }

    key = "";
    notice = "";
    status[client] = 0;
    attack[client] = g_attackId[client];
    g_scuffling[client] = 1;

    if (g_cooldowns[client] > GetGameTime()) {
        notice = "COOLINGDOWN";
        status[client] = -3;
    }

    if (g_anyTokens[client] != -1) {
        if (g_anyTokens[client] == 0) {
            notice = "NOTOKENS";
            status[client] = -1;
        }

        else if (attack[client] == -1 && g_ledgeTokens[client] == 0) {
            notice = "NOLEDGE";
            status[client] = -5;
        }

        else if (attack[client] == -2 && g_groundTokens[client] == 0) {
            notice = "NOGROUND";
            status[client] = -6;
        }

        else if (attack[client] > 0 && g_attackTokens[client] == 0) {
            notice = "NOATTACK";
            status[client] = -7;
        }
    }

    if (g_lastLeg >= 0) {
        if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= g_maxRevives) {
            notice = "LASTLEG";
            status[client] = -2;
        }
    }

    // this checks against ledges and SI *not* ground incaps
    if (!GetEntProp(client, Prop_Send, "m_isIncapacitated")) {
        if (g_health[client] + GetClientHealthBuffer(client) <= float(g_minHealth)) {
            notice = "TOWEAK";
            status[client] = -4;
        }
    }

    if (status[client] == 0) {
        if (HasRequirement(client)) {
            status[client] = 1;
        }

        else {
            notice = "MISSINGREQ";
            status[client] = -8;
        }
    }

    if (status[client] > 0) {
        notice = "GETUP";
        key = g_shiftKey;
    }

    Format(notice, sizeof(notice), "[scuffle] %T", notice, client);
    DisplayDirectorHint(client, notice, 5, "icon_Tip", key);
    return status[client] > 0;
}

float GetClientHealthBuffer(int client, float defaultVal=0.0) {
    // https://forums.alliedmods.net/showpost.php?p=1365630&postcount=1
    static float healthBuffer, healthBufferTime, tempHealth;
    healthBuffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    healthBufferTime = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    tempHealth = healthBuffer - (healthBufferTime / (1.0 / g_decayRate));
    return tempHealth < 0.0 ? defaultVal : tempHealth;
}

void RecordClientHealth(int client) {

    /**
    * Take a snapshot of a survivors health and health buffer
    *
    * Record a client's health state. If a client is not incapacitated their
    * health is recorded unmodified. If a client is incapacitated the health
    * recorded is modified to hurt every one second while down. This will not
    * reflect on a survivor that is helped up by someone else but will affect
    * survivors that revive themselves (in an effort to prevent abuse).
    *
    * @param client     Survivor to snapshot
    * @return void
    */

    static float attackHealth[MAXPLAYERS + 1];
    static float gameTime;
    gameTime = GetGameTime();

    if (!GetEntProp(client, Prop_Send, "m_isIncapacitated")) {
        g_health[client] = GetClientHealth(client);
        g_healthBuffer[client] = GetClientHealthBuffer(client);
        attackHealth[client] = gameTime;
    }

    else if (g_attackId[client] != 0) {

        // if we're not hanging on a ledge, we're officially down
        if (g_attackId[client] != -1) {
            g_healthBuffer[client] = 0.0;
            g_health[client] = 0;
        }

        // this penalty will apply if the user gets themselves up
        if (attackHealth[client] < gameTime) {
            attackHealth[client] = gameTime + 1.0;
            g_healthBuffer[client] -= float(g_hurtSurvivor);
            g_health[client] -= g_hurtSurvivor;
        }
    }
}

void RestoreClientHealth(int client) {

    /**
    * Restore a client's health state after they've revived themselves
    *
    * If a survivor has a recorded health state of less than zero (both health
    * and health buffer), the client will get a strike. In this and all other
    * cases, the health restored to a client is from calculations derived from
    * RecordClientHealth.
    *
    * @param client     Survivor to restore
    * @return void
    */

    int strike = GetEntProp(client, Prop_Send, "m_currentReviveCount");

    if (g_health[client] <= 0) {
        g_health[client] = 1;

        if (g_healthBuffer[client] <= 0.0) {
            strike++;

            switch (g_itemHealth[client] > 0.0) {
                case 1: g_healthBuffer[client] = g_itemHealth[client];
                case 0: g_healthBuffer[client] = g_healthReviveBit;
            }
        }
    }

    Client_ExecuteCheat(client, "give", "health");
    SetEntityHealth(client, g_health[client]);
    L4D_SetPlayerTempHealth(client, g_healthBuffer[client]);
    SetRevive(client, strike);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {

    /**
    * Manage survivors in self revival situations
    *
    * Record a survivors health state every time through. If a survivor is in
    * trouble proceed to see if they can actually scuffle through it. Plenty of
    * customizable cvars affect the outcome of this forward. The purpose boils
    * down to "IsPlayerInTrouble" and "CanPlayerScuffle".
    *
    */

    static float gameTime;
    static int attackerId;
    static int reviving;
    static int ent;

    if (IsClientConnected(client) && GetClientTeam(client) == 2) {

        RecordClientHealth(client);
        if (IsFakeClient(client)) {
            return;
        }

        attackerId = 0;
        gameTime = GetGameTime();

        if (IsPlayerInTrouble(client, attackerId)) {
            g_cleanup[client] = 1;

            if (!CanPlayerScuffle(client)) {
                return;
            }

            if (g_lastScuffle[client] == 0.0) {
                g_lastScuffle[client] = gameTime;
            }

            else if (gameTime - g_lastScuffle[client] < 0.0) {
                g_lastScuffle[client] = gameTime;
            }

            reviving = (buttons & g_reviveShiftBit);

            if (gameTime - g_reviveDuration <= g_lastScuffle[client]) {
                switch (reviving) {
                    case 1: g_lastScuffle[client] -= g_reviveHoldTime;
                    case 0: g_lastScuffle[client] += g_reviveLossTime;
                }
            }

            if (!reviving && g_lastKeyPress[client] & g_reviveShiftBit) {
                g_lastScuffle[client] -= g_reviveTapTime;
            }

            ShowProgressBar(client, g_lastScuffle[client], g_reviveDuration);
            g_lastKeyPress[client] = buttons;

            if (gameTime - g_reviveDuration >= g_lastScuffle[client]) {
                if (g_anyTokens[client] > 0) {
                    g_anyTokens[client]--;
                }

                if (attackerId == -1 && g_ledgeTokens[client] > 0) {
                    g_ledgeTokens[client]--;
                } else if (attackerId == -2 && g_groundTokens[client] > 0) {
                    g_groundTokens[client]--;
                } else if (attackerId > 0 && g_attackTokens[client] > 0) {
                    g_attackTokens[client]--;
                }

                ent = g_payments[client];
                if (IsEntityValid(ent)) {
                    RemovePlayerItem(client, ent);
                    AcceptEntityInput(ent,"kill");
                }

                if (attackerId > 0) {
                    g_blockDamage[client] = attackerId;
                    CreateTimer(0.01, StaggerTimer, client, TIMER_REPEAT);
                    L4D2_Stagger(attackerId);

                    if (GetRandomInt(1, 100) <= g_killChance) {
                        ForcePlayerSuicide(attackerId);
                        g_blockDamage[client] = 0;
                    }
                }

                if (g_blockDamage[client] > 0 && g_stayDown) {
                    g_lastScuffle[client] = gameTime;
                    return;
                }

                g_cooldowns[client] = gameTime + g_cooldown;
                RestoreClientHealth(client);
                // and penalize ...
            }
        }

        else if (g_cleanup[client]) {
            ResetClient(client);
        }
    }
}

public Action OnTakeDamageHook(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {

    /**
    * Block damage on self reviving survivors against specific SI attacks
    *
    * When a survivor breaks loose from an SI incap (e.g., Hunter, Charger) the
    * time it takes for the survivor to get back up on their feet is time where
    * the survivor is vulnerable to any further secondary attack by the same SI.
    * Survivors are only protected against the specific SI that incapped them.
    *
    * The protection time is derived from the cvars g_cv<SI>Stagger. A Hunter's
    * default stagger time is 3.0 seconds and only during the first 3.0 seconds
    * of the Hunter staggering is the survivor protected against their attack.
    *
    */

    if (attacker > 0 && g_blockDamage[victim] == attacker) {
        damage = 0.0;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public Action StaggerTimer(Handle timer, int client) {

    /**
    * Stagger client's attacker repeatedly
    *
    * If a client passed in has an attackerId in g_blockDamage[client] the found
    * attackerId is staggered until the timer is exhausted. If the attackerId is
    * invalid or until it is invalid or until the timer runs out, the attackerId
    * is staggered and its attack blocked against client (see OnTakeDamageHook).
    *
    */

    static int attackerId;
    attackerId = g_blockDamage[client];

    if (attackerId > 0 && GetGameTime() <= g_staggerTime[attackerId]) {
        if (IsClientConnected(attackerId) && IsPlayerAlive(attackerId)) {
            if (GetClientTeam(attackerId) == 3) {
                L4D2_Stagger(attackerId);
                return Plugin_Continue;
            }
        }
    }

    g_blockDamage[client] = 0;
    return Plugin_Stop;
}

bool IsPlayerInTrouble(int client, int &attackerId) {

    /**
    * Check to see if client is in trouble
    *
    * Check if client is being attacked and is immobilized. If the player is not
    * being attacked, check if they're incapacitated. An attackerId > 0 is the
    * ID of the SI attacking the player. An attackerId of -1 means the player is
    * hanging from a ledge. An attackerId of -2 means the player is rotting.
    *
    * @param client         survivor to check for trouble
    * @param attackerId     A referenced attackerId (returns type/ID of attacker)
    * @return               true if survivor is in trouble, otherwise false
    */

    static char attackTypes[4][] = {
        "m_pounceAttacker",     // g_staggers[0] + GetGameTime()
        "m_tongueOwner",        // g_staggers[1] ...
        "m_pummelAttacker",     // g_staggers[2] ...
        "m_jockeyAttacker"      // g_staggers[3] ...
    };

    for (int i = 0; i < sizeof(attackTypes); i++) {
        if (HasEntProp(client, Prop_Send, attackTypes[i])) {
            attackerId = GetEntPropEnt(client, Prop_Send, attackTypes[i]);
            if (attackerId > 0) {
                g_staggerTime[attackerId] = GetGameTime() + g_staggers[i];
                g_attackId[client] = attackerId;
                return true;
            }
        }
    }

    static char incapTypes[2][] = {"m_isHangingFromLedge", "m_isIncapacitated"};

    for (int i = 0; i < sizeof(incapTypes); i++) {
        if (HasEntProp(client, Prop_Send, incapTypes[i])) {
            if (GetEntProp(client, Prop_Send, incapTypes[i])) {
                attackerId = (i + 1) * -1;
                g_attackId[client] = attackerId;
                return true;
            }
        }
    }

    g_attackId[client] = 0;
    if (g_lastScuffle[client]) {
        ShowProgressBar(client, 0.1, 0.0);
    }

    return false;
}

stock void L4D2_RunScript(const char[] sCode, any ...) {

    /**
    * Run a VScript (Credit to Timocop)
    *
    * @param sCode      Magic
    * @return void
    */

    static int iScriptLogic = INVALID_ENT_REFERENCE;
    if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
        iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));

        if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
            SetFailState("Could not create 'logic_script'");
        }

        DispatchSpawn(iScriptLogic);
    }

    static char sBuffer[512];
    VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
    SetVariantString(sBuffer);
    AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

stock void L4D2_Stagger(int iClient, float fPos[3]=NULL_VECTOR) {

    /**
    * Stagger a client (Credit to Timocop)
    *
    * @param iClient    Client to stagger
    * @param fPos       Vector to stagger
    * @return void
    */

    L4D2_RunScript(
        "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))",
        GetClientUserId(iClient),
        RoundFloat(fPos[0]),
        RoundFloat(fPos[1]),
        RoundFloat(fPos[2])
    );
}

static void ShowProgressBar(int iClient, const float fStartTime, const float fDuration) {

    /**
    * Show the client a progress bar
    *
    * @param iClient        Client to show progress bar
    * @param fStartTime     Time e.g., GetGameTime()
    * @param fDuration      Number of seconds to show e.g., 10.5
    * @return void
    */

    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", fStartTime);
    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarDuration", fDuration);
}

static void Client_ExecuteCheat(int iClient, const char[] sCmd, const char[] sArgs) {

    /**
    * Execute a cheat
    *
    * @param iClient    Client that will execute the cheat
    * @param sCmd       Command e.g., z_spawn
    * @param sArgs      Variable arguments e.g., "tank auto"
    * @return void
    */

    int flags = GetCommandFlags(sCmd);
    SetCommandFlags(sCmd, flags & ~FCVAR_CHEAT);
    FakeClientCommand(iClient, "%s %s", sCmd, sArgs);
    SetCommandFlags(sCmd, flags | FCVAR_CHEAT);
}

static void L4D_SetPlayerTempHealth(int iClient, float fTempHealth) {

    /**
    * Set a survivors health buffer
    *
    * @param iClient        Client to apply health buffer
    * @param fTempHealth    Amount of health e.g., 30.0
    * @return void
    */

    SetEntPropFloat(iClient, Prop_Send, "m_healthBuffer", fTempHealth);
    SetEntPropFloat(iClient, Prop_Send, "m_healthBufferTime", GetGameTime());
}

stock void DisplayDirectorHint(
    int iClient, char sHintTxt[128], int iHintTimeout, char[] sIcon="icon_Tip",
    char[] sBind="+jump", char[] sHintColorRGB="255 0 100") {

    /**
    * Display a Director hint to a client
    *
    * Note: If sBind has a value, it'll replace any sIcon. These are prefixed
    * onto the hint text displayed to a client.
    *
    * @param iClient        Client to show Director hint
    * @param sHintTxt       Hint Text
    * @param iHintTimeout   How long before text times out e.g., 10
    * @param sIcon          Icon to use (will not show if sBind has a value)
    * @param sBind          Key hint (Shows key in place of sIcon)
    * @param sHintColorRGB  Color of Director text
    * @return void
    */

    static int iEntity;
    iEntity = CreateEntityByName("env_instructor_hint");

    static char sValues[64];
    FormatEx(sValues, sizeof(sValues), "hint%d", iClient);
    DispatchKeyValue(iClient, "targetname", sValues);
    DispatchKeyValue(iEntity, "hint_target", sValues);

    Format(sValues, sizeof(sValues), "%d", iHintTimeout);
    DispatchKeyValue(iEntity, "hint_timeout", sValues);
    DispatchKeyValue(iEntity, "hint_range", "100");

    if (sBind[0] == '\0') {
        DispatchKeyValue(iEntity, "hint_icon_onscreen", sIcon);
    }

    else {
        DispatchKeyValue(iEntity, "hint_icon_onscreen", "use_binding");
        DispatchKeyValue(iEntity, "hint_binding", sBind);
    }

    Format(sValues, sizeof(sValues), "%s", sHintTxt);
    DispatchKeyValue(iEntity, "hint_caption", sHintTxt);
    DispatchKeyValue(iEntity, "hint_color", sHintColorRGB);
    DispatchSpawn(iEntity);
    AcceptEntityInput(iEntity, "ShowHint", iClient);

    Format(sValues, sizeof(sValues), "OnUser1 !self:Kill::%d:1", iHintTimeout);
    SetVariantString(sValues);
    AcceptEntityInput(iEntity, "AddOutput");
    AcceptEntityInput(iEntity, "FireUser1");
}
