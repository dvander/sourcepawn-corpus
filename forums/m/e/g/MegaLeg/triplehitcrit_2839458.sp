#pragma semicolon 1

#include <tf2_stocks>
#include <sdkhooks>

#define MAX_CLASSNAME_LENGTH 64

public Plugin myinfo = {
    name = "Melee Triple Hit Crits",
    author = "MegaLeg",
    description = "Bring the gunslinger's crit on three consecutive punches mechanic to every melee weapon.",
    version = "1.0",
    url = "https://git.upwardmc.net/UpwardMC/TF2/MeleeTripleHitCrits"
};

ConVar timeAllowedBetweenHitsConVar;
ConVar additionalHitsForScoutConVar;
ConVar preventDemoknightConVar;

enum struct ComboProgress {
    int lastSwingTime;
    int numSwings;
    int numHits;
   
    void onSwing(int clientIndex) {
        int nowTime = GetSysTickCount();

        if (isCritting(clientIndex)) {
            turnOffCrits(clientIndex); // We already started swinging so the crit will still register on hit
            this.resetComboProgress();
            this.numHits = -1; // Stop the crit swing itself from counting as a combo hit
        } else if (this.numSwings > this.numHits) {
            this.resetComboProgress();
        } else if (nowTime - this.lastSwingTime > GetConVarInt(timeAllowedBetweenHitsConVar)) {
            this.resetComboProgress();
        }

        this.numSwings++;
        this.lastSwingTime = nowTime;
    }

    void onHit(int clientIndex) {
        this.numHits++;

        if (this.numHits == getComboHits(clientIndex)) {
            turnOnCrits(clientIndex);
        }
    }

    void resetComboProgress() {
        this.lastSwingTime = 0;
        this.numSwings = 0;
        this.numHits = 0;
    }
}

ComboProgress playerComboProgress[MAXPLAYERS + 1];

public void OnPluginStart() {
    HookEvent("player_spawn", OnPlayerSpawn);

    timeAllowedBetweenHitsConVar = CreateConVar("mthc_ms_allowed_between_hits", "1250", "How lenient are the \"consecutive\" hits in the triple hit combo. Consecutive melee swings are allowed to be started at most this many milliseconds apart and count towards the combo.", FCVAR_NONE, true, 0.0);
    additionalHitsForScoutConVar = CreateConVar("mthc_additional_scout_hits", "2", "How many additional hits does scout require for a melee combo", FCVAR_NONE, true, 0.0);
    preventDemoknightConVar = CreateConVar("mthc_prevent_demoknight", "1", "Whether or not demoknights are prevented from getting melee combos", FCVAR_NONE, true, 0.0, true, 1.0);

    for (int i = 1; i < MaxClients + 1; ++i) {
        if (!IsClientInGame(i)) {
            continue;
        }

        OnClientPutInServer(i);
    }

    PrintToServer("[TripleHitCrit] Plugin loaded");
}

public void OnClientPutInServer(int clientIndex) {
    playerComboProgress[clientIndex].resetComboProgress();

    SDKHook(clientIndex, SDKHook_WeaponSwitch, OnClientSwitchWeapon);
    SDKHook(clientIndex, SDKHook_OnTakeDamage, OnPlayerHurt);
}

public Action OnPlayerHurt(int victim, int &attackerClientIndex, int &inflictor, float &damage, int &damageType, int &sourceWeapon,
		float damageForce[3], float damagePosition[3], int damagecustom) {
    // Not all damage is caused by an entity
    if (attackerClientIndex == 0) {
        return Plugin_Continue;
    }

    // Was the damage type actually melee or damage caused by a status effect inflicted by a melee weapon
    if (damageType & DMG_CLUB == 0) {
        return Plugin_Continue;
    }
    // Projectile melee's shouldn't count
    if (inflictor != attackerClientIndex) {
        return Plugin_Continue;
    }

    int meleeWeapon = GetPlayerWeaponSlot(attackerClientIndex, TFWeaponSlot_Melee);

    if (meleeWeapon != sourceWeapon) {
        return Plugin_Continue;
    }
    
    if (!shouldTripleHitCrit(attackerClientIndex)) {
        return Plugin_Continue;
    }

    playerComboProgress[attackerClientIndex].onHit(attackerClientIndex);

    return Plugin_Continue;
}

int getComboHits(int attackerClientIndex) {
    TFClassType playerClass = TF2_GetPlayerClass(attackerClientIndex);

    if (playerClass == TFClass_Scout) {
        return 2 + GetConVarInt(additionalHitsForScoutConVar);
    }

    return 2;
}

bool shouldTripleHitCrit(int attackerClientIndex) {
    TFClassType playerClass = TF2_GetPlayerClass(attackerClientIndex);

    switch (playerClass) {
        case TFClass_Spy: {
            return false;
        }
        case TFClass_DemoMan: {
            if (GetConVarInt(preventDemoknightConVar) == 0) {
                return true;
            }

            int weapon = GetPlayerWeaponSlot(attackerClientIndex, TFWeaponSlot_Secondary);

            if (weapon == -1) {
                return false;
            }
        }
        case TFClass_Engineer: {
            int weapon = GetPlayerWeaponSlot(attackerClientIndex, TFWeaponSlot_Melee);

            if (weapon == -1) {
                return true; 
            }

            char classname[MAX_CLASSNAME_LENGTH];
            GetEntityClassname(weapon, classname, MAX_CLASSNAME_LENGTH);

            if (strcmp(classname, "tf_weapon_robot_arm") == 0) {
                return false;
            }
        }
    }

    return true;
}

public Action TF2_CalcIsAttackCritical(int attackerClientIndex, int weapon, char[] weaponname, bool &result) {
    if (shouldTripleHitCrit(attackerClientIndex)) {
        playerComboProgress[attackerClientIndex].onSwing(attackerClientIndex);
    }
}

public Action OnClientSwitchWeapon(int clientIndex, int weapon) {
    turnOffCrits(clientIndex);

    return Plugin_Continue;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int userid = event.GetInt("userid");
    int clientIndex = GetClientOfUserId(userid);
    
    playerComboProgress[clientIndex].resetComboProgress();

    return Plugin_Continue;
}

bool isCritting(int clientIndex) {
    return TF2_IsPlayerInCondition(clientIndex, TFCond_CritOnDamage);
}

void turnOnCrits(int clientIndex) {
    TF2_AddCondition(clientIndex, TFCond_CritOnDamage, GetConVarInt(timeAllowedBetweenHitsConVar) / 1000.0);
}

void turnOffCrits(int clientIndex) {
    TF2_RemoveCondition(clientIndex, TFCond_CritOnDamage);
}