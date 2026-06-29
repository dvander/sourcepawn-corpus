#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "2.2.0"
#define PLUGIN_TAG "\x03[SUPPLY]\x01"

public Plugin myinfo = {
	name        = "L4D2 Simple Supplier - Missing Medkit and Weapons Fix",
	author      = "-=BwA=- jester + Edits and improvements by LordVGames",
	description = "Handle the missing medkits and weapons for > 4 player teams or the occasional no medkits/weapons at all.",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showpost.php?p=2775621&postcount=37"
}

ConVar cvSpawnMeds, cvSpawnWeaps, cvSpawnWeaps_T3s, cvSpawnWeaps_Pistols, cvSpawnWeaps_Melees, cvItemSearchDistance, cvItemSpawnDelay, cvEnableExtraLogging;
bool g_bIsThereACutscene, g_bHasFirstPlayerJoined, g_bCanDoCommand;
int ITEM_SEARCH_DISTANCE, g_iStartKitCount, g_iStartingWeaponTotalCount, g_iSurvivorCount, g_iMeleeClassCount = 0;
float ITEM_SPAWN_DELAY, g_fStartLoc[3], g_fStartKitLoc[3], g_fStartWeapLoc[3], g_fStartAmmo[3], g_fMeleeSpawnLocation[3], g_fWeaponSpawnLocation[3];
char g_saMeleeClasses[16][32];
static char g_saWeaponSpawnList[20][32] = {
    "weapon_spawn",
	"weapon_pistol_spawn",
	"weapon_pistol_magnum_spawn",
	"weapon_pumpshotgun_spawn",
	"weapon_shotgun_chrome_spawn",
	"weapon_smg_spawn",
	"weapon_smg_silenced_spawn",
	"weapon_smg_mp5_spawn",
	"weapon_sniper_scout_spawn",
	"weapon_sniper_awp_spawn",
	"weapon_hunting_rifle_spawn",
	"weapon_sniper_military_spawn",
	"weapon_rifle_ak47_spawn",
	"weapon_rifle_desert_spawn",
	"weapon_rifle_m60_spawn",
	"weapon_rifle_sg552_spawn",
	"weapon_rifle_spawn",
	"weapon_autoshotgun_spawn",
	"weapon_shotgun_spas_spawn",
    "weapon_grenade_launcher_spawn"
};

public void OnPluginStart()
{
    EngineVersion engine = GetEngineVersion();
    if(engine != Engine_Left4Dead2)
        SetFailState("Plugin only supports Left 4 Dead 2.");
    HookEvent("gameinstructor_nodraw", OnGameInstructorNoDraw);
    CreateConVar("l4d2_simplesupply_version", PLUGIN_VERSION, "L4D2 Simple Supply Version.", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    cvEnableExtraLogging = CreateConVar("l4d2_simplesupply_enable_extralogging", "0", "Toggles having debug-like info printed in the log file for certain plugin code events.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvSpawnMeds = CreateConVar("l4d2_simplesupply_supplymeds", "1", "Toggles supplying medkits.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvSpawnWeaps = CreateConVar("l4d2_simplesupply_supplyweapons", "1", "Toggles supplying weapons.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvSpawnWeaps_T3s = CreateConVar("l4d2_simplesupply_supplyt3s", "1", "Toggles supplying tier 3 weapons (grenade launcher, M60) when at the finale map of a campaign. Does nothing if 'l4d2_simplesupply_supplyweapons' is 0.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvSpawnWeaps_Pistols = CreateConVar("l4d2_simplesupply_supplypistols", "0", "Toggles supplying a pistol with each gun supplied. Does nothing if 'l4d2_simplesupply_supplyweapons' is 0.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvSpawnWeaps_Melees = CreateConVar("l4d2_simplesupply_supplymelees", "1", "Toggles supplying a melee weapon with every other gun supplied. Does nothing if 'l4d2_simplesupply_supplyweapons' is 0.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cvItemSearchDistance = CreateConVar("l4d2_simplesupply_itemsearch_distance", "1000", "How far to search for items in the starting area.", FCVAR_NOTIFY, true, 1.0, false);
    cvItemSpawnDelay = CreateConVar("l4d2_simplesupply_itemsupply_delay", "1", "Should there be a delay before supplying items in the starting area?", FCVAR_NOTIFY, true, 0.0, false);

    AutoExecConfig(true, "l4d2_simplesupply");

    RegAdminCmd("sm_supply", Command_Supply, ADMFLAG_GENERIC, "Supplies extra medkits and weapons if needed.");
}

public void OnAllPluginsLoaded()
{
    if (L4D_GetCurrentChapter() == 1)
        HookEvent("player_team", OnPlayerJoined);
    else
        HookEvent("player_transitioned", OnPlayerJoined);
}

public void OnConfigsExecuted()
{
    ITEM_SEARCH_DISTANCE = cvItemSearchDistance.IntValue;
    ITEM_SPAWN_DELAY = cvItemSpawnDelay.FloatValue;
}

public void OnMapStart()
{
    g_iStartKitCount = 0; g_iStartingWeaponTotalCount = 0; g_iSurvivorCount = 0; g_iMeleeClassCount = 0;
    g_bHasFirstPlayerJoined = false;
    g_bIsThereACutscene = false;
}

public void OnGameInstructorNoDraw(Event hEvent, const char[] name, bool dontBroadcast) {
    g_bIsThereACutscene = true;
}

public void OnGameInstructorDraw(Event hEvent, const char[] name, bool dontBroadcast) {
    if (g_bIsThereACutscene)
    {
        if (ITEM_SPAWN_DELAY > 0.0)
            CreateTimer(ITEM_SPAWN_DELAY, SetupSupply_Timer);
        else
            RequestFrame(SetupSupply);
    }
}

public void OnPlayerJoined(Event hEvent, const char[] name, bool dontBroadcast) {
    if (!g_bIsThereACutscene && !g_bHasFirstPlayerJoined) {
        LogAction(0, -1, "[SUPPLY] Player joined, doing cutscene check...");
        CreateTimer(0.5, CutsceneCheck);
        g_bHasFirstPlayerJoined = true;
    }
}

void SetupCountsAndLocations(bool setnewlocations)
{
    if (!FindStartArea()) {
        PrintToChatAll("%s Could not find start area! Try using the command again.");
        return;
    }
    GetSurvivorCount();
    GetHealthPacksAtLocation(g_fStartLoc, ITEM_SEARCH_DISTANCE, setnewlocations);
    GetWeaponCountAtLocation(g_fStartLoc, ITEM_SEARCH_DISTANCE, setnewlocations);
}

public Action CutsceneCheck(Handle timer) {
    SetupCountsAndLocations(true);
    if (g_bIsThereACutscene) {
        LogAction(0, -1, "[SUPPLY] Cutscene was detected! Doing auto supply when cutscene is over!");
        HookEvent("gameinstructor_draw", OnGameInstructorDraw);
    }
    else
    {
        LogAction(0, -1, "[SUPPLY] Cutscene was NOT detected! Doing auto supply, NOW!");
        if (ITEM_SPAWN_DELAY > 0.0)
            CreateTimer(ITEM_SPAWN_DELAY, SetupSupply_Timer);
        else
            RequestFrame(SetupSupply);
    }
}

void SetupSupply()
{
    g_bCanDoCommand = true;
    if (cvSpawnWeaps_Melees.BoolValue)
        GetMeleeStringTableArray();
    SupplyMissingEntities();
}

public Action SetupSupply_Timer(Handle timer) {SetupSupply();}

void GetMeleeStringTableArray()
{
	int MeleeStringTable = FindStringTable("MeleeWeapons");
	g_iMeleeClassCount = GetStringTableNumStrings(MeleeStringTable);
	for(int i = 0; i < g_iMeleeClassCount; i++)
		ReadStringTable(MeleeStringTable, i, g_saMeleeClasses[i], 32);
}

public Action Command_Supply(int client, int args) {
    if (g_bCanDoCommand) {
        SetupCountsAndLocations(false);
	    SupplyMissingEntities();
    }
    else
        ReplyToCommand(client, "[SUPPLY] Please wait for the map intro to be over before supplying items!");
    return Plugin_Handled;
}

void SupplyMissingEntities()
{
    int iMedKitsToSpawn, iWeapsToSpawn;
    if (cvSpawnMeds.BoolValue)
        iMedKitsToSpawn = g_iSurvivorCount - g_iStartKitCount;
    if (cvSpawnWeaps.BoolValue)
        iWeapsToSpawn = g_iSurvivorCount - g_iStartingWeaponTotalCount;
    if (cvEnableExtraLogging.BoolValue) {
        LogAction(0, -1, "[SUPPLY] SupplyMissingEntities info:\ng_iSurvivorCount: %i, g_iStartKitCount: %i, g_iStartingWeaponTotalCount: %i", g_iSurvivorCount, g_iStartKitCount, g_iStartingWeaponTotalCount);
        LogAction(0, -1, "[SUPPLY] SupplyMissingEntities info (processed):\niMedKitsToSpawn: %i, iWeapsToSpawn: %i", iMedKitsToSpawn, iWeapsToSpawn);
    }
    if (iMedKitsToSpawn > 0)  
	{ 
		PrintToChatAll("%s Found \x05%d\x01 medkits at the start for \x05%d\x01 survivors. Spawning \x05%d\x01 extra medkits.", PLUGIN_TAG, g_iStartKitCount, g_iSurvivorCount, iMedKitsToSpawn);
		for (int i = 1; i <= iMedKitsToSpawn; i++)
            SpawnEntityAtLocation(g_fStartKitLoc, "weapon_first_aid_kit");
	}
    else {
        PrintToChatAll("%s There is no need to spawn in medkits at the start for \x05%d\x01 survivors!", PLUGIN_TAG, g_iSurvivorCount);
        LogAction(0, -1, "[SUPPLY] No need to spawn more medkits! (Medkits needed to spawn: %i)", iMedKitsToSpawn);
    }
    if (iWeapsToSpawn > 0)
    {
        LogAction(0, -1, "[SUPPLY] Assuming there are not enough weapon pickups (%i) for all %i survivors! Spawning in more!", g_iStartingWeaponTotalCount, g_iSurvivorCount);
        //Use an ammo pile location
        if (FindMedkitSpawnArea(g_fStartLoc, ITEM_SEARCH_DISTANCE))	
			g_fStartAmmo[2] += 16.0; //Move the spawn a little up off the pile
        else
		{
			int client = FirstSurvivor();
			if (client == -1) return;
			GetClientAbsOrigin(client, g_fStartAmmo);	
		}
        g_fWeaponSpawnLocation = g_fStartAmmo;
        RequestFrame(SpawnWeapons, iWeapsToSpawn);
        if (cvSpawnWeaps_Melees.BoolValue)
        {
            int iNumMeleeToSpawn = view_as<int>(RoundToCeil(iWeapsToSpawn / 2.0));
            g_fMeleeSpawnLocation = g_fStartAmmo;
            RequestFrame(SpawnMeleeWeapons, iNumMeleeToSpawn);
        }
    }
	else {
        PrintToChatAll("%s There is no need to spawn in  weapons at the start for \x05%d\x01 survivors!", PLUGIN_TAG, g_iSurvivorCount);
        LogAction(0, -1, "[SUPPLY] No need to spawn more weapons! (Weapons needed to spawn: %i)", iWeapsToSpawn);
	}
}

void SpawnWeapons(int iWeapsToSpawn)
{
    if (L4D_GetGameModeType() == GAMEMODE_SURVIVAL) {
        SpawnWeaponsPart2(iWeapsToSpawn, 4);
        return;
    }
    else if (L4D_GetGameModeType() == GAMEMODE_SCAVENGE) {
        SpawnWeaponsPart2(iWeapsToSpawn, 2);
        return;
    }
    bool halfwaythrough;
    //if more than halfway through a campaign
    if (L4D_GetCurrentChapter() > view_as<int>(RoundToCeil(L4D_GetMaxChapters() / 2.0)))
        halfwaythrough = true;
    if (!halfwaythrough) {
        //special exception for dead center's first map
        char mapname[128]; GetCurrentMap(mapname, sizeof(mapname));
        if (StrEqual(mapname, "c1m1_hotel"))
            SpawnWeaponsPart2(iWeapsToSpawn, 1);
        else
            SpawnWeaponsPart2(iWeapsToSpawn, 2);
    }
	else
	{
        if (cvSpawnWeaps_T3s.BoolValue && L4D_IsMissionFinalMap())
            SpawnWeaponsPart2(iWeapsToSpawn, 4);
        else
            SpawnWeaponsPart2(iWeapsToSpawn, 3);
	}

}	

void SpawnMeleeWeapons(int iNumMeleeToSpawn)
{
	float fSpawnPos[3]; float fSpawnAngles[3];
	fSpawnPos = g_fMeleeSpawnLocation;
	fSpawnPos[2] += 16; fSpawnAngles[0] = 90.0;
	for (int i = 0; i < iNumMeleeToSpawn; i++) {
		int rand = GetRandomInt(0, g_iMeleeClassCount - 1);
		SpawnMeleeWeapon(g_saMeleeClasses[rand], fSpawnPos, fSpawnAngles);
	}
    if (iNumMeleeToSpawn == 1)
        PrintToChatAll("%s Spawning in \x051\x01 melee weapon.", PLUGIN_TAG);
    else
	    PrintToChatAll("%s Spawning in \x05%i\x01 melee weapons.", PLUGIN_TAG, iNumMeleeToSpawn);
}

//there's probably a way i can do this more simple but if there is i don't know it
void SpawnWeaponsPart2(int iWeapsToSpawn, int iStage)
{
    /*
    iStages
    1 = On c1m1_hotel/pistols only
    2 = Before halfway through
    3 = After halfway through
    4 = On the finale
    */
    char sSpawnMsg[192]; Format(sSpawnMsg, sizeof(sSpawnMsg), "%s Spawning ", PLUGIN_TAG);
    int iRandomNum, iGunCountPistol, iGunCountSMG, iGunCountRifle, iGunCountShotgun, iGunCountSniper, iGunCountGL, iGunCountM60;
    char weaponname[32];
    while (iWeapsToSpawn > 0)
    {
        //choose random gun category + spawn a pistol appropriate for the progression stage
        if (cvSpawnWeaps_T3s.BoolValue)
        {
            switch (iStage)
            {
                case 2:
                {
                    if (cvSpawnWeaps_Pistols.BoolValue) {
                        SpawnEntityAtLocation(g_fWeaponSpawnLocation, "weapon_pistol");
                        iGunCountPistol++;
                    }
                    iRandomNum = Math_GetRandomInt(1, 3);
                }
                case 3:
                {
                    if (cvSpawnWeaps_Pistols.BoolValue)
                    {
                        switch(Math_GetRandomInt(1, 2))
                        {
                            case 1:
                                SpawnEntityAtLocation(g_fWeaponSpawnLocation, "weapon_pistol");
                            case 2:
                                SpawnEntityAtLocation(g_fWeaponSpawnLocation, "weapon_pistol_magnum");
                        }
                        iGunCountPistol++;
                    }
                    iRandomNum = Math_GetRandomInt(1, 3);
                }
                case 4:
                {
                    if (cvSpawnWeaps_Pistols.BoolValue)
                    {
                        switch(Math_GetRandomInt(1, 2))
                        {
                            case 1:
                                SpawnEntityAtLocation(g_fWeaponSpawnLocation, "weapon_pistol");
                            case 2:
                                SpawnEntityAtLocation(g_fWeaponSpawnLocation, "weapon_pistol_magnum");
                        }
                        iGunCountPistol++;
                    }
                    iRandomNum = Math_GetRandomInt(1, 4);
                }
            }
        }
        else
        {
            switch (iStage)
            {
                case 2:
                {
                    if (cvSpawnWeaps_Pistols.BoolValue) {
                        SpawnEntityAtLocation(g_fWeaponSpawnLocation, "weapon_pistol");
                        iGunCountPistol++;
                    }
                    iRandomNum = Math_GetRandomInt(1, 2);
                }
                case 3, 4:
                {
                    if (cvSpawnWeaps_Pistols.BoolValue)
                    {
                        switch(Math_GetRandomInt(1, 2))
                        {
                            case 1:
                                SpawnEntityAtLocation(g_fWeaponSpawnLocation, "weapon_pistol");
                            case 2:
                                SpawnEntityAtLocation(g_fWeaponSpawnLocation, "weapon_pistol_magnum");
                        }
                        iGunCountPistol++;
                    }
                    iRandomNum = Math_GetRandomInt(1, 3);
                }
            }
        }
        switch (iRandomNum)
        {
            //smgs, maybe rifles
            case 1:
            {
                switch (iStage)
                {
                    case 2:
                    {
                        switch (Math_GetRandomInt(1, 3))
                        {
                            case 1:
                                Format(weaponname, sizeof(weaponname), "weapon_smg");
                            case 2:
                                Format(weaponname, sizeof(weaponname), "weapon_smg_silenced");
                            case 3:
                                Format(weaponname, sizeof(weaponname), "weapon_smg_mp5");
                        }
                        iGunCountSMG++;
                    }
                    case 3, 4:
                    {
                        switch (Math_GetRandomInt(1, 4))
                        {
                            case 1:
                                Format(weaponname, sizeof(weaponname), "weapon_rifle");
                            case 2:
                                Format(weaponname, sizeof(weaponname), "weapon_rifle_ak47");
                            case 3:
                                Format(weaponname, sizeof(weaponname), "weapon_rifle_desert");
                            case 4:
                                Format(weaponname, sizeof(weaponname), "weapon_rifle_sg552");
                        }
                        iGunCountRifle++;
                    }
                }
            }
            //shotguns
            case 2:
            {
                switch (iStage)
                {
                    case 2:
                        switch(Math_GetRandomInt(1, 2))
                        {
                            case 1:
                                Format(weaponname, sizeof(weaponname), "weapon_pumpshotgun");
                            case 2:
                                Format(weaponname, sizeof(weaponname), "weapon_shotgun_chrome");
                        }
                    case 3, 4:
                        switch(Math_GetRandomInt(1, 2))
                        {
                            case 1:
                                Format(weaponname, sizeof(weaponname), "weapon_autoshotgun");
                            case 2:
                                Format(weaponname, sizeof(weaponname), "weapon_shotgun_spas");
                        }
                }
                iGunCountShotgun++;
            }
            //snipers
            case 3:
            {
                switch (iStage)
                {
                    case 2:
                    {
                        switch(Math_GetRandomInt(1, 2))
                        {
                            case 1:
                                Format(weaponname, sizeof(weaponname), "weapon_hunting_rifle");
                            case 2:
                                Format(weaponname, sizeof(weaponname), "weapon_sniper_scout");
                        }
                    }
                    case 3, 4:
                    {
                        switch(Math_GetRandomInt(1, 2))
                        {
                            case 1:
                                Format(weaponname, sizeof(weaponname), "weapon_sniper_military");
                            case 2:
                                Format(weaponname, sizeof(weaponname), "weapon_sniper_awp");
                        }
                    }
                }
                iGunCountSniper++;
            }
            //t3 weapons
            case 4:
            {
                switch(Math_GetRandomInt(1, 2))
                {
                    case 1:
                        Format(weaponname, sizeof(weaponname), "weapon_rifle_m60");
                    case 2:
                        Format(weaponname, sizeof(weaponname), "weapon_grenade_launcher");
                }
            }
        }
        SpawnEntityAtLocation(g_fWeaponSpawnLocation, weaponname);
        iWeapsToSpawn--;
    }
    if (iGunCountPistol > 0)
    {
        char pistolmsg[16];
        Format(pistolmsg, sizeof(pistolmsg), "\x05%i\x01 pistol", iGunCountPistol);
        if (iGunCountPistol > 1)
            StrCat(pistolmsg, sizeof(pistolmsg), "s");
        StrCat(pistolmsg, sizeof(pistolmsg), ", ");
        StrCat(sSpawnMsg, sizeof(sSpawnMsg), pistolmsg);
    }
    if (iGunCountSMG > 0)
    {
        char smgmsg[16];
        Format(smgmsg, sizeof(smgmsg), "\x05%i\x01 SMG", iGunCountSMG);
        if (iGunCountSMG > 1)
            StrCat(smgmsg, sizeof(smgmsg), "s");
        if (iGunCountRifle != 0 || iGunCountShotgun != 0 || iGunCountSniper != 0 || iGunCountGL != 0 || iGunCountM60 != 0)
            StrCat(smgmsg, sizeof(smgmsg), ", ");
        StrCat(sSpawnMsg, sizeof(sSpawnMsg), smgmsg);
    }
    if (iGunCountRifle > 0)
    {
        char riflemsg[16];
        Format(riflemsg, sizeof(riflemsg), "\x05%i\x01 rifle", iGunCountRifle);
        if (iGunCountRifle > 1)
            StrCat(riflemsg, sizeof(riflemsg), "s");
        if (iGunCountShotgun != 0 || iGunCountSniper != 0 || iGunCountGL != 0 || iGunCountM60 != 0)
            StrCat(riflemsg, sizeof(riflemsg), ", ");
        StrCat(sSpawnMsg, sizeof(sSpawnMsg), riflemsg);
    }
    if (iGunCountShotgun > 0)
    {
        char shotgunmsg[16];
        Format(shotgunmsg, sizeof(shotgunmsg), "\x05%i\x01 shotgun", iGunCountShotgun);
        if (iGunCountShotgun > 1)
            StrCat(shotgunmsg, sizeof(shotgunmsg), "s");
        if (iGunCountSniper != 0 || iGunCountGL != 0 || iGunCountM60 != 0)
            StrCat(shotgunmsg, sizeof(shotgunmsg), ", ");
        StrCat(sSpawnMsg, sizeof(sSpawnMsg), shotgunmsg);
    }
    if (iGunCountSniper > 0)
    {
        char snipermsg[16];
        Format(snipermsg, sizeof(snipermsg), "\x05%i\x01 sniper rifle", iGunCountSniper);
        if (iGunCountSniper > 1)
            StrCat(snipermsg, sizeof(snipermsg), "s");
        if (iGunCountGL != 0 || iGunCountM60 != 0)
            StrCat(snipermsg, sizeof(snipermsg), ", ");
        StrCat(sSpawnMsg, sizeof(sSpawnMsg), snipermsg);
    }
    if (iGunCountGL > 0)
    {
        char glmsg[16];
        Format(glmsg, sizeof(glmsg), "\x05%i\x01 grenade launcher", iGunCountGL);
        if (iGunCountGL > 1)
            StrCat(glmsg, sizeof(glmsg), "s");
        if (iGunCountM60 != 0)
            StrCat(glmsg, sizeof(glmsg), ", and ");
        StrCat(sSpawnMsg, sizeof(sSpawnMsg), glmsg);
    }
    if (iGunCountM60 > 0)
    {
        char m60msg[16];
        Format(m60msg, sizeof(m60msg), "\x05%i\x01 M60", iGunCountM60);
        if (iGunCountM60 > 1)
            StrCat(m60msg, sizeof(m60msg), "s");
        StrCat(sSpawnMsg, sizeof(sSpawnMsg), m60msg);
    }
    //PrintToChatAll("iGunCountPistol: %i, iGunCountSMG: %i, iGunCountShotgun: %i, iGunCountSniper: %i, iGunCountRifle: %i, iGunCountM60: %i, iGunCountGL: %i", iGunCountPistol, iGunCountSMG, iGunCountShotgun, iGunCountSniper, iGunCountRifle, iGunCountM60, iGunCountGL);
    StrCat(sSpawnMsg, sizeof(sSpawnMsg), ".");
    PrintToChatAll(sSpawnMsg);
}

//Little tidbit from "Melee In The Saferoom" by N3wton	
stock void SpawnMeleeWeapon(const char meleeclass[32], float meleepos[3], float meleeangles[3])
{
	float pos[3]; float angles[3];
	pos = meleepos;
	angles = meleeangles;
	
	pos[0] += (-10 + GetRandomInt(0, 20));
	pos[1] += (-10 + GetRandomInt(0, 20));
	pos[2] += GetRandomInt(0, 10);
	angles[1] = GetRandomFloat(0.0, 360.0);

	int wep = CreateEntityByName("weapon_melee");
	DispatchKeyValue(wep, "melee_script_name", meleeclass);
	DispatchSpawn(wep);
	TeleportEntity(wep, pos, angles, NULL_VECTOR);
}

bool FindStartArea() {
    g_fStartLoc[0] = 0.0;
    g_fStartLoc[1] = 0.0;
    g_fStartLoc[2] = 0.0;
	
    int ent = -1;
    //Find a safe room door
    while((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
    {
        if(IsValidEntity(ent))
        {
            //The start saferoom door is the locked one
            if(GetEntProp(ent, Prop_Send, "m_bLocked") == 1)
            {
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", g_fStartLoc);
                if (cvEnableExtraLogging.BoolValue)
                    LogAction(0, -1, "[SUPPLY] FindStartArea (prop_door_rotating_checkpoint) %f %f %f", g_fStartLoc[0], g_fStartLoc[1], g_fStartLoc[2]);
                return true;
            }
        }
    }

	//If that fails, then it must be on the first map, not in safe room
    if (ent == -1)
    {
        while((ent = FindEntityByClassname(ent, "info_survivor_position")) != -1)
        {
            if(IsValidEntity(ent))
            {
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", g_fStartLoc);
                if (cvEnableExtraLogging.BoolValue)
                    LogAction(0, -1, "[SUPPLY] FindStartArea (info_survivor_position) %f %f %f", g_fStartLoc[0], g_fStartLoc[1], g_fStartLoc[2]);
                return true;
            }
        }
    }
    LogError("[SUPPLY] FindStartArea Uh oh! Startarea wasn't found!");
    return false;
}	
	
void GetHealthPacksAtLocation(float location[3], int maxradius, bool setnewlocation)
{
    if (setnewlocation)
    {
        //Zero out the one that holds the closest pack
        g_fStartKitLoc[0] = 0.0;
        g_fStartKitLoc[1] = 0.0;
        g_fStartKitLoc[2] = 0.0;
    }
	
	float tmploc[3];
	float dist = 0.0;
	float lastkitdist = 0.0;
	
	int count = 0;
	int ent = -1;
	
	while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", tmploc);
            dist = GetVectorDistance(location, tmploc, false);
            if (cvEnableExtraLogging.BoolValue)		
                LogAction(0, -1, "[SUPPLY] Found medkit spawn info:\nlocation: %f %f %f, vecorigin: %f %f %f,  dist: %f, maxradius: %i", location[0], location[1], location[2], tmploc[0], tmploc[1], tmploc[2], dist, maxradius);
            if (dist < maxradius)
			{
                if ((lastkitdist == 0.0) || (dist < lastkitdist))
                {
                    if (setnewlocation)
                        g_fStartKitLoc = tmploc;
                    lastkitdist = dist;
                }
                count++;
                LogAction(0, -1, "[SUPPLY] Medkit spawn detected, current medkit pickups at spawn: %i", count);
			}		
		}
    }
    //in case we haven't found any medkit spawn entities
    if (ent == -1)
    {
        while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit")) != -1)
        {
            if(IsValidEntity(ent))
            {
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", tmploc);
                dist = GetVectorDistance(location, tmploc, false);
                if (cvEnableExtraLogging.BoolValue)	
                    LogAction(0, -1, "[SUPPLY] Found medkit info:\nlocation: %f %f %f, vecorigin: %f %f %f,  dist: %f, maxradius: %i", location[0], location[1], location[2], tmploc[0], tmploc[1], tmploc[2], dist, maxradius);
                if (dist < maxradius)
                {
                    if ((lastkitdist == 0.0) || (dist < lastkitdist))
                    {
                        if (setnewlocation)
                            g_fStartKitLoc = tmploc;
                        lastkitdist = dist;
                    }
                    count++;
                    LogAction(0, -1, "[SUPPLY] Medkit pickup detected, current medkit pickups at spawn: %i", count);
                }		
            }
        }
    }
	g_iStartKitCount = count;
}

void GetWeaponCountAtLocation(float location[3], int maxradius, bool setnewlocation)
{
    if (setnewlocation)
    {
        g_fStartWeapLoc[0] = 0.0;
        g_fStartWeapLoc[1] = 0.0;
        g_fStartWeapLoc[2] = 0.0;
    }
	
    float tmploc[3];
    float dist = 0.0;
    float lastweapdist = 0.0;
    int weaponcount = 0;
    int ent = -1;
    for (int i = 0; i < 19; i++)
    {
        while((ent = FindEntityByClassname(ent, g_saWeaponSpawnList[i])) != -1)
        {
            if(IsValidEntity(ent))
            {
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", tmploc);
                dist = GetVectorDistance(location, tmploc, false);
                if (cvEnableExtraLogging.BoolValue)
                    LogAction(0, -1, "[SUPPLY] Found weapon info:\nlocation: %f %f %f, vecorigin: %f %f %f,  dist: %f, maxradius: %i", location[0], location[1], location[2], tmploc[0], tmploc[1], tmploc[2], dist, maxradius);
                if (dist < maxradius)
                {
                    if ((lastweapdist == 0.0) || (dist < lastweapdist))
                    {
                        if (setnewlocation)
                            g_fStartWeapLoc = tmploc;
                        lastweapdist = dist;
                    }
                    weaponcount += GetEntProp(ent, Prop_Data, "m_itemCount");
                    LogAction(0, -1, "[SUPPLY] Weapon pickup count detected, current weapon pickup count at spawn: %i", weaponcount);
                }		
            }
        }
    }
    g_iStartingWeaponTotalCount = weaponcount;
}
	
public bool FindMedkitSpawnArea(float location[3], int maxradius)
{
	int ent = -1;
	float tmploc[3];
	g_fStartAmmo[0] = 0.0;
	g_fStartAmmo[1] = 0.0;
	g_fStartAmmo[2] = 0.0;
	
	while((ent = FindEntityByClassname(ent, "weapon_ammo_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", tmploc);
			if(GetVectorDistance(location, tmploc, false) < maxradius)
			{
				g_fStartAmmo = tmploc;
				return true;
			}
		}
	}
	return false;
}

bool SpawnEntityAtLocation(float loc[3], char[] entname) {
			
	int entity = CreateEntityByName(entname);
	if(entity != -1)
	{							
        TeleportEntity(entity, loc, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(entity);
        if (cvEnableExtraLogging.BoolValue)
            LogAction(0, -1, "[SUPPLY] Spawned a %s", entname);
        return true;
	}
	else
	{
        PrintToChatAll("%s Error Creating \x04%s\x01 in [SpawnEntityAtLocation].", PLUGIN_TAG, entname);
        LogError("%s Error Creating \x04%s\x01 in [SpawnEntityAtLocation].", PLUGIN_TAG, entname);
        return false;
	}

}

//Get the first survivor (player or bot, doesn't matter)
stock int FirstSurvivor()
{
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsClientConnected(i) && (L4D_GetClientTeam(i) == L4DTeam_Survivor) && IsPlayerAlive(i))
			return i;
	return -1;
}

//re-used + modified from l4d2lib's include file
stock void GetSurvivorCount()
{
    g_iSurvivorCount = 0;
    for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
            if (GetClientTeam(i) == 2 && IsPlayerAlive(i))
			    g_iSurvivorCount++;
        else continue;
}

#define SIZE_OF_INT         2147483647 // without 0
/**
 * From SMLIB + modified some.
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * Rewritten by MatthiasVance, thanks.
 *
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Integer number between min and max
 */
stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();
	if (random == 0) random++;
	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}