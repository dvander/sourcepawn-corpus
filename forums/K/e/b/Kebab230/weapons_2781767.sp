#define WEAPON_ENTITIES_NAME_SIZE 24
#define WEAPON_NAME_SIZE 20

#define NO_WEAPON_SELECTED -1
#define NO_WEAPON_SELECTED_NAME "none"
#define RANDOM_WEAPON_SELECTED -2
#define RANDOM_WEAPON_SELECTED_NAME "random"

enum Slots {
    SlotPrimary,
    SlotSecondary,
    SlotKnife,
    SlotGrenade,
    SlotC4,
    SlotNone
};

enum weapons_MenuActions{
    weapons_MenuActions_Equip = 0x00000000,
    weapons_MenuActions_GetInWaitLine = 0x4000,
    weapons_MenuActions_GetOutWaitLine = 0x8000
};

enum weapons_StructureElements {
    weapons_StructureElement_EntityName,
    weapons_StructureElement_Name,
    weapons_StructureElement_Type,
    weapons_StructureElement_SkinTeam,
    weapons_StructureElement_DefinitionIndex,
    weapons_StructureElement_Limit,
    weapons_StructureElement_Tracker,
    weapons_StructureElement_UncarriedQueue,
    weapons_StructureElement_ClipSize,
    weapons_StructureElement_OririnalClipSize,
    weapons_StructureElement_AmmoMax,
    weapons_StructureElement_ReloadTime,
    weapons_StructureElement_PerBulletReload,
    weapons_StructureElement_COUNT
};

static weapons_StructureElementsSize[_:weapons_StructureElement_COUNT] =
{
    WEAPON_ENTITIES_NAME_SIZE,  // weapons_StructureElement_EntityName
    WEAPON_NAME_SIZE,           // weapons_StructureElement_Name
    1,                          // weapons_StructureElement_Type
    1,                          // weapons_StructureElement_SkinTeam
    1,                          //weapons_StructureElement_DefinitionIndex
    1,                          // weapons_StructureElement_Limit
    1,                          // weapons_StructureElement_Tracker
    1,                          // weapons_StructureElement_UncarriedQueue
    1,                          // weapons_StructureElement_ClipSize
    1,                          // weapons_StructureElement_OririnalClipSize
    1,                          // weapons_StructureElement_AmmoMax
    1,                          // weapons_StructureElement_ReloadTime
    1,                          // weapons_StructureElement_PerBulletReload
};

static Handle:g_hWeapons_WeaponsArray;

static Handle:g_hWeapons_PrimaryWeaponsListed;
static Handle:g_hWeapons_SecondaryWeaponsListed;

static Handle:g_hWeapons_UncarriedQueue;

static g_iWeapons_AvailableWeapons = 0;

static g_iWeapons_AmmoTypeOffset;
static g_iWeapons_AmmoOffset;
static g_iWeapons_Clip1Offset;
new g_iWeapons_OwnerOffset;
static g_iWeapons_OriginOffset;

new g_iWeapons_WeaponIndex_Decoy;
new g_iWeapons_WeaponIndex_Smoke;
new g_iWeapons_WeaponIndex_Flash;
new g_iWeapons_WeaponIndex_HE;
new g_iWeapons_WeaponIndex_Molotov;
new g_iWeapons_WeaponIndex_Incendiary;
new g_iWeapons_WeaponIndex_Knife;
new g_iWeapons_WeaponIndex_Tazer;
new g_iWeapons_WeaponIndex_C4;

enum weapons_EdictsStructureElements {
        bool:bWeapons_EdictsStructureElements_isTagged,
        iWeapons_EdictsStructureElements_Owner,
        iWeapons_EdictsStructureElements_Id,
        iWeapons_EdictsStructureElements_Team,
        Float:fWeapons_EdictsStructureElements_lastReload,
        bool:bWeapons_EdictsStructureElements_ReloadHooked,
        weapons_EdictsStructureElements_ClipContent,
        weapons_EdictsStructureElements_AmmoContent
};

static g_aWeapons_EdictsData[4096][weapons_EdictsStructureElements];

enum weapons_PlayerEquipmentStructureElements {
    weapons_PlayerEquipment_PrimaryId,
    weapons_PlayerEquipment_SecondaryId,
    weapons_PlayerEquipment_PrimaryEntity,
    weapons_PlayerEquipment_SecondaryEntity,
    weapons_PlayerEquipment_PrimaryWaitLine,
    weapons_PlayerEquipment_SecondaryWaitLine,
    bool:weapons_PlayerEquipment_IsTeamInverted
}

static g_aWeapons_PlayerEquipment[MAXPLAYERS + 1][weapons_PlayerEquipmentStructureElements];

stock weapons_Init()
{
    g_hWeapons_WeaponsArray = CreateArray(HANDLE_SIZE, _:weapons_StructureElement_COUNT);
    
    for (new index = 0; index < _:weapons_StructureElement_COUNT; index++)
    {
        SetArrayCell(g_hWeapons_WeaponsArray, index, CreateArray(weapons_StructureElementsSize[index]));
    }
    
    g_hWeapons_PrimaryWeaponsListed    = CreateArray(1);
    g_hWeapons_SecondaryWeaponsListed  = CreateArray(1);
    
    g_iWeapons_AvailableWeapons = 0;
    
    g_hWeapons_UncarriedQueue = fifo_Create();
    
    weapons_Build();
    
    weapons_FindId("weapon_taser", g_iWeapons_WeaponIndex_Tazer);
    
    // Find offsets
    g_iWeapons_Clip1Offset      = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
    g_iWeapons_AmmoTypeOffset   = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
    g_iWeapons_OwnerOffset      = FindSendPropOffs("CBaseCombatWeapon", "m_hOwner");
    g_iWeapons_AmmoOffset       = FindSendPropOffs("CCSPlayer", "m_iAmmo");
    g_iWeapons_OriginOffset     = FindSendPropOffs("CBaseCombatWeapon", "m_vecOrigin");
    
    CreateTimer(1.0, weapons_Timer_Worker, _, TIMER_REPEAT);
}

stock weapons_OnMapStart()
{
    for (new index = 0; index < sizeof(g_aWeapons_EdictsData); index++)
    {
        g_aWeapons_EdictsData[index][bWeapons_EdictsStructureElements_isTagged] = false;
    }
    
    fifo_Clear(g_hWeapons_UncarriedQueue);
}

stock weapons_ClearLists()
{
    ClearArray(g_hWeapons_PrimaryWeaponsListed);
    ClearArray(g_hWeapons_SecondaryWeaponsListed);
}

stock weapons_ClearList(bool:weaponPrimary)
{
    new Handle:listArray = weaponPrimary ? g_hWeapons_PrimaryWeaponsListed : g_hWeapons_SecondaryWeaponsListed;
    new weaponCount;
    
    ClearArray(listArray);
    
    weaponCount = GetArraySize( GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Limit) );
    
    new bool:IsSecondary;
    for(new weaponIndex = 0; weaponIndex < weaponCount; weaponIndex++)
        if(weaponPrimary && weapons_IsPrimary(weaponIndex, IsSecondary))
            weapons_SetLimit(weaponIndex, 0);
        else if(!weaponPrimary && IsSecondary)
            weapons_SetLimit(weaponIndex, 0);
}

stock weapons_Clear()
{
    for (new index = 0; index < _:weapons_StructureElement_COUNT; index++)
    {
        if(index == _:weapons_StructureElement_Tracker)
            for(new trackIndex = 0; trackIndex < GetArraySize(GetArrayCell(g_hWeapons_WeaponsArray, index)); trackIndex++)
                weaponTracking_Clear(weapons_GetTracker(trackIndex));
                
        if(index == _:g_hWeapons_UncarriedQueue)
            for(new queueIndex = 0; queueIndex < GetArraySize(GetArrayCell(g_hWeapons_WeaponsArray, queueIndex)); queueIndex++)
                fifo_Clear(weapons_GetUncarriedQueue(queueIndex));
        
        ClearArray(GetArrayCell(g_hWeapons_WeaponsArray, index));
    }
    weapons_ClearLists();
    
    g_iWeapons_AvailableWeapons = 0;
}

stock weapons_Close()
{
    weapons_Clear();
    
    for (new index = 0; index < _:weapons_StructureElement_COUNT; index++)
    {
        if(index == _:weapons_StructureElement_Tracker)
            for(new trackIndex = 0; trackIndex < GetArraySize(GetArrayCell(g_hWeapons_WeaponsArray, index)); trackIndex++)
                weaponTracking_Close(weapons_GetTracker(trackIndex));
        
        if(index == _:g_hWeapons_UncarriedQueue)
            for(new queueIndex = 0; queueIndex < GetArraySize(GetArrayCell(g_hWeapons_WeaponsArray, queueIndex)); queueIndex++)
                fifo_Close(weapons_GetUncarriedQueue(queueIndex));
        
        CloseHandle(GetArrayCell(g_hWeapons_WeaponsArray, index));
    }
    
    ClearArray( g_hWeapons_WeaponsArray);
    CloseHandle(g_hWeapons_WeaponsArray);
    
    CloseHandle(g_hWeapons_PrimaryWeaponsListed);
    CloseHandle(g_hWeapons_SecondaryWeaponsListed);
}

stock weapons_Build()
{
    // Primary weapons
    weapons_Add(.weaponEntityName = "weapon_ak47",          .weaponName = "AK-47",          .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 7,    .weaponReloadTime = 2.5, .weaponPerBulletReload = 0,.weaponClipSize = 30,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_m4a1",          .weaponName = "M4A4",           .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 16,   .weaponReloadTime = 3.4, .weaponPerBulletReload = 0,.weaponClipSize = 30,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_m4a1_silencer", .weaponName = "M4A1-S",         .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 60,   .weaponReloadTime = 3.4, .weaponPerBulletReload = 0,.weaponClipSize = 20,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 80);
    weapons_Add(.weaponEntityName = "weapon_sg556",         .weaponName = "SG 556",         .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 39,   .weaponReloadTime = 3.0, .weaponPerBulletReload = 0,.weaponClipSize = 30,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_aug",           .weaponName = "AUG",            .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 8,    .weaponReloadTime = 3.8, .weaponPerBulletReload = 0,.weaponClipSize = 30,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_galilar",       .weaponName = "Galil AR",       .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 13,   .weaponReloadTime = 3.3, .weaponPerBulletReload = 0,.weaponClipSize = 35,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_famas",         .weaponName = "FAMAS",          .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 10,   .weaponReloadTime = 3.4, .weaponPerBulletReload = 0,.weaponClipSize = 25,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_awp",           .weaponName = "AWP",            .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 9,    .weaponReloadTime = 3.8, .weaponPerBulletReload = 0,.weaponClipSize = 10,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 30);
    weapons_Add(.weaponEntityName = "weapon_ssg08",         .weaponName = "Scout",          .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 40,   .weaponReloadTime = 3.9, .weaponPerBulletReload = 0,.weaponClipSize = 10,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_g3sg1",         .weaponName = "G3SG1",          .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 11,   .weaponReloadTime = 5.0, .weaponPerBulletReload = 0,.weaponClipSize = 20,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_scar20",        .weaponName = "SCAR-20",        .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 38,   .weaponReloadTime = 5.0, .weaponPerBulletReload = 0,.weaponClipSize = 20,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 90);
    weapons_Add(.weaponEntityName = "weapon_m249",          .weaponName = "M249",           .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 14,   .weaponReloadTime = 5.0, .weaponPerBulletReload = 0,.weaponClipSize = 100,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 200);
    weapons_Add(.weaponEntityName = "weapon_negev",         .weaponName = "Negev",          .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 28,   .weaponReloadTime = 5.9, .weaponPerBulletReload = 0,.weaponClipSize = 150,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 200);
    weapons_Add(.weaponEntityName = "weapon_nova",          .weaponName = "Nova",           .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 35,   .weaponReloadTime = 6.0, .weaponPerBulletReload = 1,.weaponClipSize = 8,    .weaponOriginalClipSize = 8, .weaponAmmoMax = 32);
    weapons_Add(.weaponEntityName = "weapon_xm1014",        .weaponName = "XM1014",         .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 25,   .weaponReloadTime = 5.2, .weaponPerBulletReload = 1,.weaponClipSize = 7,    .weaponOriginalClipSize = 7, .weaponAmmoMax = 32);
    weapons_Add(.weaponEntityName = "weapon_sawedoff",      .weaponName = "Sawed-Off",      .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 29,   .weaponReloadTime = 6.0, .weaponPerBulletReload = 1,.weaponClipSize = 7,    .weaponOriginalClipSize = 7, .weaponAmmoMax = 32);
    weapons_Add(.weaponEntityName = "weapon_mag7",          .weaponName = "MAG-7",          .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 27,   .weaponReloadTime = 3.0, .weaponPerBulletReload = 0,.weaponClipSize = 5,    .weaponOriginalClipSize = 0, .weaponAmmoMax = 32);
    weapons_Add(.weaponEntityName = "weapon_mac10",         .weaponName = "MAC-10",         .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 17,   .weaponReloadTime = 3.5, .weaponPerBulletReload = 0,.weaponClipSize = 30,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 100);
    weapons_Add(.weaponEntityName = "weapon_mp9",           .weaponName = "MP9",            .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 34,   .weaponReloadTime = 2.3, .weaponPerBulletReload = 0,.weaponClipSize = 30,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 120);
    weapons_Add(.weaponEntityName = "weapon_mp7",           .weaponName = "MP7",            .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 33,   .weaponReloadTime = 3.5, .weaponPerBulletReload = 0,.weaponClipSize = 30,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 120);
    weapons_Add(.weaponEntityName = "weapon_mp5sd",         .weaponName = "MP5",            .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 23,   .weaponReloadTime = 3.5, .weaponPerBulletReload = 0,.weaponClipSize = 30,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 120);
    weapons_Add(.weaponEntityName = "weapon_ump45",         .weaponName = "UMP-45",         .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 24,   .weaponReloadTime = 3.8, .weaponPerBulletReload = 0,.weaponClipSize = 25,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 100);
    weapons_Add(.weaponEntityName = "weapon_p90",           .weaponName = "P90",            .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 19,   .weaponReloadTime = 3.5, .weaponPerBulletReload = 0,.weaponClipSize = 50,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 100);
    weapons_Add(.weaponEntityName = "weapon_bizon",         .weaponName = "PP-Bizon",       .weaponType = weapons_type_Primary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 26,   .weaponReloadTime = 2.5, .weaponPerBulletReload = 0,.weaponClipSize = 64,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 120);
    // Secondary weapons
    weapons_Add(.weaponEntityName = "weapon_glock",         .weaponName = "Glock",          .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 4,   .weaponReloadTime = 2.2, .weaponPerBulletReload = 0, .weaponClipSize = 20,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 120);
    weapons_Add(.weaponEntityName = "weapon_p250",          .weaponName = "P250",           .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 36,  .weaponReloadTime = 2.5, .weaponPerBulletReload = 0, .weaponClipSize = 13,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 26);
    weapons_Add(.weaponEntityName = "weapon_cz75a",         .weaponName = "CZ75-Auto",      .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 63,  .weaponReloadTime = 2.5, .weaponPerBulletReload = 0, .weaponClipSize = 12,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 12);
    weapons_Add(.weaponEntityName = "weapon_usp_silencer",  .weaponName = "USP-S",          .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 61,  .weaponReloadTime = 2.5, .weaponPerBulletReload = 0, .weaponClipSize = 12,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 24);
    weapons_Add(.weaponEntityName = "weapon_fiveseven",     .weaponName = "Five-SeveN",     .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 3,   .weaponReloadTime = 2.5, .weaponPerBulletReload = 0, .weaponClipSize = 20,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 100);
    weapons_Add(.weaponEntityName = "weapon_deagle",        .weaponName = "Desert Eagle",   .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 1,   .weaponReloadTime = 2.2, .weaponPerBulletReload = 0, .weaponClipSize = 7,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 35);
    weapons_Add(.weaponEntityName = "weapon_revolver",      .weaponName = "R8 Revolver",    .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 64,  .weaponReloadTime = 3.0, .weaponPerBulletReload = 0, .weaponClipSize = 8,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 8);
    weapons_Add(.weaponEntityName = "weapon_elite",         .weaponName = "Dual Berettas",  .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 2,   .weaponReloadTime = 3.8, .weaponPerBulletReload = 0, .weaponClipSize = 30,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 120);
    weapons_Add(.weaponEntityName = "weapon_tec9",          .weaponName = "Tec-9",          .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_T,    .weaponDefinitionIndex = 30,  .weaponReloadTime = 2.7, .weaponPerBulletReload = 0, .weaponClipSize = 24,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 120);
    weapons_Add(.weaponEntityName = "weapon_hkp2000",       .weaponName = "P2000",          .weaponType = weapons_type_Secondary, .weaponSkinTeam = CS_TEAM_CT,   .weaponDefinitionIndex = 32,  .weaponReloadTime = 2.5, .weaponPerBulletReload = 0, .weaponClipSize = 13,  .weaponOriginalClipSize = 0, .weaponAmmoMax = 52);
    // Nades
    g_iWeapons_WeaponIndex_Decoy = weapons_Add(.weaponEntityName = "weapon_decoy",         .weaponName = "Decoy",      .weaponType = weapons_type_Equipement,  .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 47, .weaponReloadTime = 0.0, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 1);
    g_iWeapons_WeaponIndex_Smoke = weapons_Add(.weaponEntityName = "weapon_smokegrenade",  .weaponName = "Smoke",      .weaponType = weapons_type_Equipement,  .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 45, .weaponReloadTime = 0.0, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 1);
    g_iWeapons_WeaponIndex_Flash = weapons_Add(.weaponEntityName = "weapon_flashbang",     .weaponName = "Flash",      .weaponType = weapons_type_Equipement,  .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 43, .weaponReloadTime = 0.0, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 1);
    g_iWeapons_WeaponIndex_HE    = weapons_Add(.weaponEntityName = "weapon_hegrenade",     .weaponName = "HE",         .weaponType = weapons_type_Equipement,  .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 44, .weaponReloadTime = 0.0, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 1);
    g_iWeapons_WeaponIndex_Molotov    = weapons_Add(.weaponEntityName = "weapon_molotov",   .weaponName = "Molotov",    .weaponType = weapons_type_Equipement, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 46, .weaponReloadTime = 0.0, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 1);
    g_iWeapons_WeaponIndex_Incendiary = weapons_Add(.weaponEntityName = "weapon_incgrenade",.weaponName = "Incendiary", .weaponType = weapons_type_Equipement, .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 48, .weaponReloadTime = 0.0, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 1);
    // Others
    g_iWeapons_WeaponIndex_Knife = weapons_Add(.weaponEntityName = "weapon_knife",         .weaponName = "Knife",      .weaponType = weapons_type_Equipement,  .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 42,  .weaponReloadTime = 0.0, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 1);
    g_iWeapons_WeaponIndex_Tazer = weapons_Add(.weaponEntityName = "weapon_taser",         .weaponName = "Taser",      .weaponType = weapons_type_Equipement,  .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 31,  .weaponReloadTime = 1.5, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 10);
    g_iWeapons_WeaponIndex_C4    = weapons_Add(.weaponEntityName = "weapon_c4",            .weaponName = "C4",         .weaponType = weapons_type_Equipement,  .weaponSkinTeam = CS_TEAM_NONE, .weaponDefinitionIndex = 49,  .weaponReloadTime = 1.5, .weaponPerBulletReload = 0, .weaponClipSize = 1,   .weaponOriginalClipSize = 0, .weaponAmmoMax = 10);
}

stock weapons_Add(const String:weaponEntityName[], const String:weaponName[], weapons_Types:weaponType=weapons_type_Primary, weaponSkinTeam, weaponDefinitionIndex, weaponLimit=-1, Float:weaponReloadTime=2.0, weaponPerBulletReload=0, weaponClipSize=30, weaponOriginalClipSize=30, weaponAmmoMax=120)
{
    new existingId = -1;
    
    if(weapons_FindId(weaponEntityName, existingId))
    {
        if(!StrEqual(weaponName, ""))
            SetArrayString(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Name),          existingId, weaponName);
        
        if(weaponType != weapons_type_None)
            SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Type),            existingId, weaponType);
        
        if(weaponSkinTeam != CS_TEAM_SPECTATOR)
            SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_SkinTeam),        existingId, weaponSkinTeam);
        
        if(weaponDefinitionIndex > -1)
            SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_DefinitionIndex), existingId, weaponDefinitionIndex);
            
        if(weaponReloadTime > -1.0)
            SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_ReloadTime),      existingId, weaponReloadTime);
           
        if(weaponPerBulletReload > -1)
            SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_PerBulletReload), existingId, weaponPerBulletReload);
               
        if(weaponClipSize > -1)
            SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_ClipSize),        existingId, weaponClipSize);
            
        if(weaponOriginalClipSize > -1)
            SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_OririnalClipSize),existingId, weaponOriginalClipSize);
            
        if(weaponAmmoMax > -1)
            SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_AmmoMax),         existingId, weaponAmmoMax);
    }
    else
    {
        new id = PushArrayString(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_EntityName),  weaponEntityName);
        PushArrayString(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Name),             weaponName);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Type),             weaponType);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_SkinTeam),         weaponSkinTeam);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_DefinitionIndex),  weaponDefinitionIndex);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Limit),            weaponLimit);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Tracker),          weaponTracking_Create(id));
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_UncarriedQueue),   fifo_Create());
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_ClipSize),         weaponClipSize);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_OririnalClipSize), weaponOriginalClipSize);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_AmmoMax),          weaponAmmoMax);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_ReloadTime),       weaponReloadTime);
        PushArrayCell(  GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_PerBulletReload),  weaponPerBulletReload);
        
        g_iWeapons_AvailableWeapons++;
        existingId = id;
    }
    
    return existingId;
}

stock bool:weapons_FindId(const String:weaponEntityName[], &id)
{
    decl String:weaponCorrectEntityName[WEAPON_ENTITIES_NAME_SIZE];
    
    if(!StrStartWith("weapon_", weaponEntityName))
        Format(weaponCorrectEntityName, WEAPON_ENTITIES_NAME_SIZE, "weapon_%s", weaponEntityName);
    else
        strcopy(weaponCorrectEntityName, WEAPON_ENTITIES_NAME_SIZE, weaponEntityName);
    
    id = FindStringInArray(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_EntityName), weaponCorrectEntityName);
    
    if (id == -1)
    {
        if (StrEqual(weaponEntityName, NO_WEAPON_SELECTED_NAME))
        {
            id = NO_WEAPON_SELECTED;
        }
        else if (StrEqual(weaponEntityName, RANDOM_WEAPON_SELECTED_NAME))
        {
            id = RANDOM_WEAPON_SELECTED;
        }
        
        return false;
    }
    else
        return true;
}

stock weapons_FindIdFromEntity(weaponEntity)
{
    new definitionIndex = GetEntProp(weaponEntity, Prop_Send, "m_iItemDefinitionIndex");
    new weaponId = FindValueInArray(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_DefinitionIndex), definitionIndex);
    
    if(weaponId == -1)
    {
        decl String:EntityName[WEAPON_ENTITIES_NAME_SIZE];
        GetEdictClassname(weaponEntity, EntityName, sizeof(EntityName));
        
        if(StrStartWith(EntityName, "weapon_knife") || StrStartWith(EntityName, "weapon_bayonet"))
            weaponId = g_iWeapons_WeaponIndex_Knife;
    }
    
    return weaponId;
    
}

stock weapons_SetReloadHooked(weaponEntity, bool:reloadHooked)
{   
    g_aWeapons_EdictsData[weaponEntity][bWeapons_EdictsStructureElements_ReloadHooked] = reloadHooked;
}

stock weapons_TagEntity(weaponEntity, id, owner, bool:isCT=false, bool:reloadHooked=false)
{    
    if(owner > 0)
        weapons_AddUser(id, owner, isCT);
    else
    {
        fifo_PushIfNotPresent(g_hWeapons_UncarriedQueue, weaponEntity);
        fifo_PushIfNotPresent(weapons_GetUncarriedQueue(id), weaponEntity);
    }
    
    g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Id] = id;
    g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Owner] = owner;
    g_aWeapons_EdictsData[weaponEntity][bWeapons_EdictsStructureElements_ReloadHooked] = reloadHooked;
    g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Team] = isCT? CS_TEAM_CT: CS_TEAM_T;
    g_aWeapons_EdictsData[weaponEntity][fWeapons_EdictsStructureElements_lastReload] = -20.0;
    g_aWeapons_EdictsData[weaponEntity][bWeapons_EdictsStructureElements_isTagged] = true;
}

stock weapons_DeTagEntity(weaponEntity)
{
    if(g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Owner] == 0)
    {
        fifo_RemoveValue(g_hWeapons_UncarriedQueue, weaponEntity && g_aWeapons_EdictsData[weaponEntity][bWeapons_EdictsStructureElements_isTagged]);
        fifo_RemoveValue(weapons_GetUncarriedQueue(g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Id]), weaponEntity);
    }
        
    g_aWeapons_EdictsData[weaponEntity][bWeapons_EdictsStructureElements_isTagged] = false;
}

stock Float:weapons_GetLastEntityReload(weaponEntity)
{
    return g_aWeapons_EdictsData[weaponEntity][fWeapons_EdictsStructureElements_lastReload];
}

stock weapons_TagEntityAsReloading(weaponEntity, Float:reloadTime)
{
    g_aWeapons_EdictsData[weaponEntity][fWeapons_EdictsStructureElements_lastReload] = reloadTime;
}

stock bool:weapons_IsEntityTagged(weaponEntity, &id=0, &owner=0, &bool:reloadHooked=false, &team=0)
{
    id = g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Id];
    owner = g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Owner];
    reloadHooked = g_aWeapons_EdictsData[weaponEntity][bWeapons_EdictsStructureElements_ReloadHooked];
    team = g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Team];
    
    return g_aWeapons_EdictsData[weaponEntity][bWeapons_EdictsStructureElements_isTagged];
}

stock weapons_SwitchTeam(weaponEntity, oldTeam=CS_TEAM_NONE, newTeam)
{
    g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Team] = newTeam;
}

stock weapons_GetUncarriedCount()
{
    return fifo_Size(g_hWeapons_UncarriedQueue);
}

stock weapons_GetUncarriedCountOfID(id)
{
    return fifo_Size(weapons_GetUncarriedQueue(id));
}

stock weapons_AddUncarried(weaponEntity, weaponId)
{
    fifo_PushIfNotPresent(g_hWeapons_UncarriedQueue, weaponEntity);
    fifo_PushIfNotPresent(weapons_GetUncarriedQueue(weaponId), weaponEntity);
}

stock weapons_RemoveUncarried(weaponEntity, weaponId)
{
    fifo_RemoveValue(g_hWeapons_UncarriedQueue, weaponEntity);
    fifo_RemoveValue(weapons_GetUncarriedQueue(weaponId), weaponEntity);
}

stock weapons_Types:weapons_GetType(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Type), id);
}

stock bool:weapons_IsPrimary(id, &bool:IsSecondary=false)
{
    new weapons_Types:type = GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Type), id);
    
    IsSecondary = (type == weapons_type_Secondary);
    
    return (type == weapons_type_Primary);
}

stock weapons_GetSkinTeam(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_SkinTeam), id);
}

stock weapons_GetItemDefinitionIndex(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_DefinitionIndex), id);
}

stock weapons_GetClipSize(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_ClipSize), id);
}

stock weapons_GetOriginalClipSize(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_OririnalClipSize), id);
}

stock weapons_GetAmmoMax(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_AmmoMax), id);
}

stock Float:weapons_GetReloadTime(id)
{
    return Float:GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_ReloadTime), id);
}

stock bool:weapons_IsPerBulletReload(id)
{
    return bool:GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_PerBulletReload), id);
}

stock Handle:weapons_GetTracker(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Tracker), id);
}

stock Handle:weapons_GetUncarriedQueue(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_UncarriedQueue), id);
}

stock weapons_GetUsedCount(id, bool:isCT)
{
    return weaponTracking_GetUsersCount(weapons_GetTracker(id), isCT);
}

stock weapons_GetLimit(id)
{
    return GetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Limit), id);
}

stock weapons_SetLimit(id, weaponLimit)
{
    SetArrayCell(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Limit), id, weaponLimit);
}

stock weapons_GetEntityName(id, String:name[], size)
{
    GetArrayString(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_EntityName), id, name, size);
}

stock weapons_GetName(id, String:name[], size)
{
    if(id == NO_WEAPON_SELECTED)
        strcopy(name, size, NO_WEAPON_SELECTED_NAME);
    else
        GetArrayString(GetArrayCell(g_hWeapons_WeaponsArray, _:weapons_StructureElement_Name), id, name, size);
}

stock bool:weapons_AddToWeaponsListed(id)
{
    new Handle:listArray = weapons_IsPrimary(id) ? g_hWeapons_PrimaryWeaponsListed : g_hWeapons_SecondaryWeaponsListed;
    new idInList = FindValueInArray(listArray, id);
    
    if ( idInList == -1 )
    {
        PushArrayCell(listArray, id);
        return true;
    }
    else
        return false;
}

stock bool:weapons_RemoveFromWeaponsListed(id)
{
    new Handle:listArray = weapons_IsPrimary(id) ? g_hWeapons_PrimaryWeaponsListed : g_hWeapons_SecondaryWeaponsListed;
    new idInList = FindValueInArray(listArray, id);
    
    if ( idInList != -1 )
    {
        RemoveFromArray(listArray, idInList);
        return true;
    }
    else
        return false;
}

stock weapons_AddUser(id, user, bool:isCT)
{
    if (id > NO_WEAPON_SELECTED)
    {
        weaponTracking_AddUser(weapons_GetTracker(id), user, isCT);
    }
}

stock weapons_RemoveUser(id, user, bool:isCT)
{
    if (id > NO_WEAPON_SELECTED && user > 0)
    {
        new bool:IsSecondary;
        if(weapons_IsPrimary(id, IsSecondary))
        {
            g_aWeapons_PlayerEquipment[user][weapons_PlayerEquipment_PrimaryId] = NO_WEAPON_SELECTED;
            g_aWeapons_PlayerEquipment[user][weapons_PlayerEquipment_PrimaryEntity] = -1;
        }
        else if(IsSecondary)
        {
            g_aWeapons_PlayerEquipment[user][weapons_PlayerEquipment_SecondaryId] = NO_WEAPON_SELECTED;
            g_aWeapons_PlayerEquipment[user][weapons_PlayerEquipment_SecondaryEntity] = -1;
        }
            
        weaponTracking_RemoveUser(weapons_GetTracker(id), user, isCT);
    }
}

stock weapons_ResetUsers()
{
    for (new index = 0; index < g_iWeapons_AvailableWeapons; index++)
    {
        weaponTracking_Clear(weapons_GetTracker(index));
    }
}

stock bool:weapons_IsLimited(id, bool:isCT, &currentUsed=0, &limit=0, user=-1)
{
    new bool:isUsing = user!= -1 && weaponTracking_IsUsing(weapons_GetTracker(id), user, isCT);
    currentUsed = weapons_GetUsedCount(id, isCT);
    new bool:hasWaiters = weaponTracking_GetWaitersCount(weapons_GetTracker(id), isCT) > 0;
    limit = weapons_GetLimit(id);
    
    if ((limit == 0) || (limit > 0 && ((currentUsed >= limit + (isUsing?1:0)) || (!isUsing  && hasWaiters))))
        return true;
    else
        return false;
}

stock weapons_EnforceLimits()
{
    for(new entity = MaxClients + 1; entity < GetMaxEntities(); entity++)
    {
        if(IsValidEntity(entity))
        {
            decl String:EntityName[WEAPON_ENTITIES_NAME_SIZE];
            decl weaponId;
            decl weaponLimit;
            
            GetEdictClassname(entity, EntityName, sizeof(EntityName));
            
            if(!StrStartWith(EntityName, "weapon_") || StrEqual(EntityName[7], "c4"))
                continue;       
            
            if(weapons_IsEntityTagged(entity, weaponId))
            {
                new clientIndex = GetEntDataEnt2(entity, g_iWeapons_OwnerOffset);
                
                if(!players_IsClientValid(clientIndex) && !g_bConfig_WeaponsAllowUncarried)
                {
                    AcceptEntityInput(entity, "Kill");
                }
                else if(players_IsClientValid(clientIndex) && weaponId > NO_WEAPON_SELECTED && weapons_IsLimited(weaponId, GetClientTeam(clientIndex) == CS_TEAM_CT, _, weaponLimit, clientIndex))
                {
                    players_OnWeaponStrippedPre(clientIndex, entity);
                    
                    weapons_RemovePlayerWeapon(entity, clientIndex);
                    sounds_PlayToClient(clientIndex, SOUNDS_WEAPON_FORBIDEN);
                    
                    decl String:weaponName[WEAPON_NAME_SIZE];
                    decl String:formatedWeaponName[WEAPON_NAME_SIZE+2];
                    
                    weapons_GetName(weaponId, weaponName, WEAPON_NAME_SIZE);
                    Format(formatedWeaponName, sizeof(formatedWeaponName), "\x0C%s\x01", weaponName);
                    
                    PrintToChat(clientIndex, "[ \x02DM\x01 ] %t", "Weapon removed because limited", formatedWeaponName, weaponLimit);
                    
                    players_OnWeaponStripped(clientIndex, weaponId);
                }
            }
            else if(g_bConfig_WeaponsAllowThirdParty)
            {
                weaponId = weapons_FindIdFromEntity(entity);
                new clientIndex = GetEntDataEnt2(entity, g_iWeapons_OwnerOffset);
                
                if(weaponId == -1 || (!players_IsClientValid(clientIndex) && !g_bConfig_WeaponsAllowUncarried) )
                {
                    AcceptEntityInput(entity, "Kill");
                }
                else
                {
                    weapons_TagEntity(entity, weaponId, .owner = (clientIndex == -1? 0:clientIndex));
                    SDKHook(entity, SDKHook_Reload, Hook_OnWeaponReload);
                    weapons_SetReloadHooked(entity, true);
                    
                    if(weapons_GetLimit(weaponId) == 0)
                        weapons_SetLimit(weaponId, -1);
                }
            }
            else
            {
                AcceptEntityInput(entity, "Kill");
            }
        }
    }
    
    weapons_EnforceUncarriedLimits();
}

stock weapons_EnforceUncarriedLimits(weaponId=-1)
{
    new removableEntity = -1;
    
    while((removableEntity = weapons_UncarriedFindRemovable(weaponId)) != -1)
    {
        decl removableEntityId;
        
        fifo_RemoveValue(g_hWeapons_UncarriedQueue, removableEntity);
        
        if(weapons_IsEntityTagged(removableEntity, removableEntityId))
            fifo_RemoveValue(weapons_GetUncarriedQueue(removableEntityId), removableEntity);
        
        AcceptEntityInput(removableEntity, "Kill");
    }
}

stock weapons_UncarriedFindRemovable(weaponId=-1)
{
    new sameTypeUncarriedCount = 0;
    
    if(weaponId == g_iWeapons_WeaponIndex_C4)
        return -1;
    
    if(weaponId != -1)
        sameTypeUncarriedCount = weapons_GetUncarriedCountOfID(weaponId);
    
    if(
        (fifo_Size(g_hWeapons_UncarriedQueue)) <= g_iConfig_WeaponsMaxUncarried &&
        (
            weaponId == -1 ||
            sameTypeUncarriedCount  <= g_iConfig_WeaponsMaxUncarriedSameType
        )
       )
        return -1;
    
    new bestFound = -1;
    new Float:furtherDistance = 0.0;
    new bool:hasFoundClearedLOS = false;
    
    if(weaponId != -1 && sameTypeUncarriedCount > g_iConfig_WeaponsMaxUncarriedSameType)
    {
        new Handle:sameTypeFifo = weapons_GetUncarriedQueue(weaponId);
        
        if((bestFound = weapons_UncarriedFindRemovableInFifo(sameTypeFifo, furtherDistance, hasFoundClearedLOS)) != -1)
            return bestFound;
    }
    
    if(!g_bConfig_WeaponsUncarriedEnforce_MostWeaponSameTypeFirst)
    {
        if((bestFound = weapons_UncarriedFindRemovableInFifo(g_hWeapons_UncarriedQueue, furtherDistance, hasFoundClearedLOS)) != -1)
            return bestFound;
    }
    else
    {
        new bestFoundInLOS = -1;
        
        do
        {
            new bool:minimumWeaponCount = true;
            new currentWeaponId = 0;
            new currentWeaponCount = 0;
            new highestProcessedWeaponCount = 10000;

            for(new i = 0; i < g_iWeapons_AvailableWeapons; i++)
            {
                new weaponCount = weapons_GetUncarriedCountOfID(i);
                if(
                    weaponCount > currentWeaponCount && 
                    currentWeaponCount < highestProcessedWeaponCount
                  )
                {
                    minimumWeaponCount = false;
                    currentWeaponCount = weaponCount;
                    currentWeaponId = i;
                }
            }
            
            if(minimumWeaponCount)
                return bestFound == -1? bestFoundInLOS: bestFound;
            
            bestFound = weapons_UncarriedFindRemovableInFifo(weapons_GetUncarriedQueue(currentWeaponId), furtherDistance, hasFoundClearedLOS);
            
            if(g_bConfig_WeaponsUncarriedEnforce_NotInPlayerLOS && !hasFoundClearedLOS)
            {
                bestFoundInLOS = bestFound;
                bestFound = -1;
            }
            
            if(bestFound != -1)
                return bestFound;
           
        } while(bestFound != -1);
    }
    
    return -1;
    
}

stock weapons_UncarriedFindRemovableInFifo(Handle:fifo, &Float:furtherDistance, &hasFoundClearedLOS)
{
    new fifoSize = fifo_Size(fifo);
    decl Float:weaponPosition[3];
    decl Float:distances[MAXPLAYERS + 1] = {0.0, 1.0, ...};
    
    new bestFound = -1;
    
    for(new i = fifoSize - 1; i >= 0; i--)
    {
        decl entity;
        new Float:distance = 0.0;
        new bool:isFurther = false;
        new bool:isLOSClear = false;
        
        fifo_GetItem(fifo, i, entity);
        
        if(!IsValidEdict(entity))
        {
            fifo_RemoveValue(fifo, entity);
            continue;
        }
        
        GetEntDataVector(entity, g_iWeapons_OriginOffset, weaponPosition);
        
        if(g_bConfig_WeaponsUncarriedEnforce_FurthestToPlayers)
        { 
            distance = players_GetSimpleMinDistanceToPoint(weaponPosition, distances,.squared=true);
            
            if(distance > furtherDistance)
                isFurther = true;
        }
        
        if(g_bConfig_WeaponsUncarriedEnforce_NotInPlayerLOS)
        {
            if(players_HasPointSimpleClearLineOfSight(weaponPosition, distances))
                isLOSClear = true;
        }
        
        if(
            !g_bConfig_WeaponsUncarriedEnforce_FurthestToPlayers && 
                (
                    !g_bConfig_WeaponsUncarriedEnforce_NotInPlayerLOS ||
                    isLOSClear
                )
           )
        {
            bestFound = entity;
            furtherDistance = distance;
            hasFoundClearedLOS = isLOSClear;
            break;
        }
        
        if(
            isFurther && 
            (
                !g_bConfig_WeaponsUncarriedEnforce_NotInPlayerLOS ||
                isLOSClear ||
                !hasFoundClearedLOS
            )
          )
        {
            bestFound = entity;
            furtherDistance = distance;
            hasFoundClearedLOS = isLOSClear;
        }
    }
    
    return bestFound;
}

stock bool:weapons_GetRandomWeapon(bool:weaponPrimary, bool:isCT, &id)
{
    new Handle:listArray = weaponPrimary ? g_hWeapons_PrimaryWeaponsListed : g_hWeapons_SecondaryWeaponsListed;
    new weaponsCount = GetArraySize(listArray);
    new weaponsAvailCount = 0;
    
    // Get The number of available weapon count
    for (new index = 0; index < weaponsCount; index ++)
        if (!weapons_IsLimited(GetArrayCell(listArray, index), isCT))
            weaponsAvailCount++;
    
    if (weaponsAvailCount > 0)
    {
        new randomId = GetRandomInt(0, weaponsAvailCount - 1);
        
        // If all weapons are available, just return the random number
        if (weaponsAvailCount  == weaponsCount)
        {
            id = GetArrayCell(listArray, randomId);
            return true;
        }
        
        // Else iterate on weapons to match randomId with available slots
        for (new index = 0; index < weaponsCount; index ++)
        {
            if (!weapons_IsLimited(GetArrayCell(listArray, index), isCT))
            {
                if (index == randomId)
                {
                    id = GetArrayCell(listArray, randomId);
                    return true;
                }
            }
            else
            {
                randomId++;
            }
        }
        
        // If we are there, we did not find any match (this should never occur)
        return false;
    }
    else
        return false;
}

stock weapons_GivePlayerWeapon(clientIndex, bool:weaponPrimary, weaponId)
{
    new bool:isCT = (GetClientTeam(clientIndex) == CS_TEAM_CT);
    
    if (weaponId != NO_WEAPON_SELECTED)
    {
        if (weaponId == RANDOM_WEAPON_SELECTED)
        {
            new randomId;
             
            if (weapons_GetRandomWeapon(weaponPrimary, isCT, randomId))
            {
                weapons_ProvidePlayerWeapon(clientIndex, randomId, weaponPrimary);
                
                return randomId;
            }
            else
            {
                weapons_ProvidePlayerWeapon(clientIndex, NO_WEAPON_SELECTED, weaponPrimary);
                
                return NO_WEAPON_SELECTED;
            }
        }
        else
        {
            if (!weapons_IsLimited(weaponId, isCT, .user=clientIndex))
            {
                weapons_ProvidePlayerWeapon(clientIndex, weaponId, weaponPrimary);
                
                return weaponId;
            }
            else
            {
                if(IsFakeClient(clientIndex))
                    weapons_EnterWaitLine(clientIndex, weaponId);
                else
                {
                    decl String:weaponName[WEAPON_NAME_SIZE];
                    decl String:formatedWeaponName[WEAPON_NAME_SIZE+2];
                    
                    weapons_GetName(weaponId, weaponName, WEAPON_NAME_SIZE);
                    Format(formatedWeaponName, sizeof(formatedWeaponName), "\x0C%s\x01", weaponName);
                    
                    PrintToChat(clientIndex, "[ \x02DM\x01 ] %t", "Weapon removed because limited", formatedWeaponName, weapons_GetLimit(weaponId));
                    
                    new bool:IsSecondary;
                    if(weapons_IsPrimary(weaponId, IsSecondary) || IsSecondary)
                        menus_OnWeaponStripped(clientIndex, !IsSecondary);
                }
                
                weapons_ProvidePlayerWeapon(clientIndex, NO_WEAPON_SELECTED, weaponPrimary);
                
                return NO_WEAPON_SELECTED;
            }
        }
    }
    else
    {
        weapons_ProvidePlayerWeapon(clientIndex, weaponId, weaponPrimary);
        
        return NO_WEAPON_SELECTED;
    }
}

stock weapons_ProvidePlayerWeapon(clientIndex, weaponId, bool:weaponPrimary)
{
    decl String:weaponEntityName[WEAPON_ENTITIES_NAME_SIZE];
    decl newEnt;
    
    new existingId = weaponPrimary ? g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryId]
                                      : g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryId];
    
    new existingEnt= weaponPrimary ? g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity]
                                      : g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity];
    
    
    if( weaponId == existingId && IsValidEdict(existingEnt) )
    {
        EquipPlayerWeapon(clientIndex, existingEnt);
    
        g_aWeapons_EdictsData[existingEnt][weapons_EdictsStructureElements_ClipContent] = weapons_GetClipSize(weaponId);
        g_aWeapons_EdictsData[existingEnt][weapons_EdictsStructureElements_AmmoContent] = weapons_GetAmmoMax(weaponId);
        
        CreateTimer(0.1, weapons_Timer_SetAmmoAndClip, EntIndexToEntRef(existingEnt), TIMER_FLAG_NO_MAPCHANGE);
        
        return;
    }
    
    if( IsValidEdict(existingEnt) )
    {
        AcceptEntityInput(existingEnt, "Kill");
    }
    
    if(existingId != NO_WEAPON_SELECTED)
    {
        weaponTracking_RemoveUser( weapons_GetTracker(existingId), clientIndex, true );
        weaponTracking_RemoveUser( weapons_GetTracker(existingId), clientIndex, false );
    }
    
    newEnt = -1;
    
    if( weaponId != NO_WEAPON_SELECTED )
    {
        weaponTracking_RemoveWaiter( weapons_GetTracker(weaponId), clientIndex, true );
        weaponTracking_RemoveWaiter( weapons_GetTracker(weaponId), clientIndex, false );
        weapons_GetEntityName(weaponId, weaponEntityName, WEAPON_ENTITIES_NAME_SIZE);
        newEnt = weapons_GivePlayerItem(clientIndex, weaponEntityName, weaponId);
        
        if(newEnt > -1)
        {
            g_aWeapons_EdictsData[newEnt][weapons_EdictsStructureElements_ClipContent] = weapons_GetClipSize(weaponId);
            g_aWeapons_EdictsData[newEnt][weapons_EdictsStructureElements_AmmoContent] = weapons_GetAmmoMax(weaponId);
            
            CreateTimer(0.1, weapons_Timer_SetAmmoAndClip, EntIndexToEntRef(newEnt), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
        
    if( weaponPrimary ) g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity] = newEnt;
    else g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity] = newEnt;
    
    if( weaponPrimary ) g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryId] = weaponId;
    else g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryId] = weaponId;
}

public Action:weapons_Timer_DelayedWeaponKill(Handle:timer, any:weaponRef)
{
    new weaponEntity = EntRefToEntIndex(weaponRef);
        
    if (IsValidEntity(weaponEntity))
    {
        AcceptEntityInput(weaponEntity, "Kill");
    }
}

stock weapons_GivePlayerItem(clientIndex, String:weaponEntityName[], weaponId=NO_WEAPON_SELECTED)
{
    new targetDefinitinIndex = weaponId > NO_WEAPON_SELECTED ? weapons_GetItemDefinitionIndex(weaponId) : -1;
    new origTeam = CS_TEAM_NONE;
    new skinTeam = weapons_GetSkinTeam(weaponId);
    
    if(weaponId > NO_WEAPON_SELECTED)
       origTeam = player_FakeTeamSwitch(clientIndex, skinTeam);
    
    if(origTeam == CS_TEAM_SPECTATOR || origTeam == CS_TEAM_NONE)
    {
        player_FakeTeamSwitch(clientIndex, origTeam);
        return -1;
    }
    
    if(origTeam != weapons_GetSkinTeam(weaponId))
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_IsTeamInverted] = true;
    
    new weaponEntity = GivePlayerItem(clientIndex, weaponEntityName);
    
    if(weaponId > NO_WEAPON_SELECTED)
       player_FakeTeamSwitch(clientIndex, origTeam);
    
    g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_IsTeamInverted] = false;
    
    // Some hacking to bypass inventory
    if(weaponId > NO_WEAPON_SELECTED && targetDefinitinIndex != GetEntProp(weaponEntity, Prop_Send, "m_iItemDefinitionIndex"))
    {
        weapons_RemovePlayerWeapon(weaponEntity, clientIndex);
        // Weapon is removed on a timer to prevent crash
        CreateTimer(0.2, weapons_Timer_DelayedWeaponKill, EntIndexToEntRef(weaponEntity));
        
        weaponEntity = CreateEntityByName(weaponEntityName);
        DispatchSpawn(weaponEntity);
        SetEntProp(weaponEntity, Prop_Send, "m_iItemDefinitionIndex", targetDefinitinIndex);
        EquipPlayerWeapon(clientIndex, weaponEntity);
    }
   
    weapons_TagEntity(weaponEntity, weaponId, clientIndex, .isCT = GetClientTeam(clientIndex) == CS_TEAM_CT);
    
    return weaponEntity;
}

stock bool:weapons_IsClientTeamInverted(clientIndex)
{
    return g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_IsTeamInverted];
}

stock weapons_GivePlayerItemId(clientIndex, weaponId)
{
    decl String:weaponEntityName[WEAPON_ENTITIES_NAME_SIZE];
    
    weapons_GetEntityName(weaponId, weaponEntityName, WEAPON_ENTITIES_NAME_SIZE);
    
    return weapons_GivePlayerItem(clientIndex, weaponEntityName, weaponId);
}

stock bool:weapons_RemovePlayerWeapon(entityIndex, clientIndex)
{
    new bool:ret = false;
    
    if(!IsValidEdict(entityIndex))
        return false;
    
    if(
        g_aWeapons_EdictsData[entityIndex][bWeapons_EdictsStructureElements_isTagged] &&
        g_aWeapons_EdictsData[entityIndex][iWeapons_EdictsStructureElements_Id] != NO_WEAPON_SELECTED
      )
    {
        new bool:IsSecondary;
        if(weapons_IsPrimary(g_aWeapons_EdictsData[entityIndex][iWeapons_EdictsStructureElements_Id], IsSecondary))
        {
            g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity] = -1;
            g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryId] = NO_WEAPON_SELECTED;
        }
        else if(IsSecondary)
        {
            g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity] = -1;
            g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryId] = NO_WEAPON_SELECTED;
        }
    }
    
    if(IsValidEdict(entityIndex))
    {
        if(players_IsClientValid(clientIndex) && IsPlayerAlive(clientIndex))
        {
            RemovePlayerItem(clientIndex, entityIndex);
            ret = true;
        }
        AcceptEntityInput(entityIndex, "Kill");
    }
    
    return ret;
}

stock weapons_EnterWaitLine(clientIndex, id, team=-1)
{
    new bool:IsSecondary;
    if(!weapons_IsPrimary(id, IsSecondary) && !IsSecondary)
        return;
    
    if(
        !IsSecondary && 
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryWaitLine] != NO_WEAPON_SELECTED &&
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryWaitLine] != id
      )
        weapons_ExitWaitLine(clientIndex, g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryWaitLine]);
    else if (
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryWaitLine] != NO_WEAPON_SELECTED &&
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryWaitLine] != id
      )
        weapons_ExitWaitLine(clientIndex, g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryWaitLine]);
    
    new lTeam = team;
    if(lTeam == -1)
        lTeam = GetClientTeam(clientIndex);
    
    weaponTracking_AddWaiter(weapons_GetTracker(id), clientIndex, lTeam == CS_TEAM_CT);
        
    if(!IsSecondary)
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryWaitLine] = id;
    else
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryWaitLine] = id;
}

stock bool:weapons_ExitWaitLine(clientIndex, id)
{
    new bool:isWaiter = false;
    new bool:IsSecondary;
    isWaiter |= weaponTracking_RemoveWaiter(weapons_GetTracker(id), clientIndex, false);
    isWaiter |= weaponTracking_RemoveWaiter(weapons_GetTracker(id), clientIndex, true);
    
    if(weapons_IsPrimary(id, IsSecondary))
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryWaitLine] = NO_WEAPON_SELECTED;
    else if(!IsSecondary)
        g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryWaitLine] = NO_WEAPON_SELECTED;
    
    return isWaiter;
}

stock weapons_MenuActions:weapons_MenuDecodeAction(&id)
{
    if(id & (_:weapons_MenuActions_GetInWaitLine) != 0)
    {
        id &= ~(_:weapons_MenuActions_GetInWaitLine);
        return weapons_MenuActions_GetInWaitLine;
    }
    
    if(id & (_:weapons_MenuActions_GetOutWaitLine) != 0)
    {
        id &= ~(_:weapons_MenuActions_GetOutWaitLine);
        return weapons_MenuActions_GetOutWaitLine;
    }
    
    return weapons_MenuActions_Equip;    
}

stock weapons_BuildListedMenu(Handle:menu, bool:weaponPrimary, bool:isCT, clientIndex)
{
    decl String:weaponName[WEAPON_NAME_SIZE];
    decl String:weaponIdStr[9];
    decl weaponId;
    
    decl currentUsed;
    decl limit;
    
    new Handle:listArray = weaponPrimary ? g_hWeapons_PrimaryWeaponsListed : g_hWeapons_SecondaryWeaponsListed;
    new weaponsCount = GetArraySize(listArray);
     
    for (new index = 0; index < weaponsCount; index++)
    {
        weaponId = GetArrayCell(listArray, index);
        
        weapons_GetName(weaponId, weaponName, WEAPON_NAME_SIZE);
        
        if (!weapons_IsLimited(weaponId, isCT, currentUsed, limit, .user=clientIndex))
        {
            IntToString(weaponId, weaponIdStr, sizeof(weaponIdStr));
            if (limit > -1 && !weaponTracking_IsUsing(weapons_GetTracker(weaponId), clientIndex, isCT))
            {
                decl String:menuItemStr[WEAPON_NAME_SIZE + 35];
                
                Format(menuItemStr, sizeof(menuItemStr), "%s (%d %T)", weaponName, limit - currentUsed, "available", clientIndex);
                AddMenuItem(menu, weaponIdStr, menuItemStr);
            }
            else if(limit > -1 && weaponTracking_IsUsing(weapons_GetTracker(weaponId), clientIndex, isCT) && weaponTracking_IsTransfertToUserPending(weapons_GetTracker(weaponId), clientIndex, isCT))
                AddMenuItem(menu, weaponIdStr, weaponName, ITEMDRAW_DISABLED);
            else
                AddMenuItem(menu, weaponIdStr, weaponName);
        }
        else
        {
            decl String:menuItemStr[WEAPON_NAME_SIZE + 70];
        
            if(limit == 0)
            {
                IntToString(weaponId, weaponIdStr, sizeof(weaponIdStr));
                AddMenuItem(menu, weaponIdStr, weaponName, ITEMDRAW_DISABLED);
            }
            else if(g_bConfig_LimitedWeaponsRotation && !weaponTracking_IsWaiting(weapons_GetTracker(weaponId), clientIndex, isCT))
            {
                new encodedId = weaponId | (_:weapons_MenuActions_GetInWaitLine);
                
                IntToString(encodedId, weaponIdStr, sizeof(weaponIdStr));
                
                if(g_fConfig_LimitedWeaponsRotationTime == 0.0)
                {
                    new waitersCount = weaponTracking_GetWaitersCount(weapons_GetTracker(weaponId), isCT);
                    Format(menuItemStr, sizeof(menuItemStr), "%s (%T)", weaponName, "Client in wait line", clientIndex, waitersCount);
                }
                else
                {
                    new Float:time = weaponTracking_GetWaitTime(weapons_GetTracker(weaponId), clientIndex, isCT, weapons_GetLimit(weaponId));
                    decl String:timeStr[10];
                
                    FormatGameTime(timeStr, sizeof(timeStr), time);
                    Format(menuItemStr, sizeof(menuItemStr), "%s (%T~%s)", weaponName, "Wait", clientIndex, timeStr);
                }
                AddMenuItem(menu, weaponIdStr, menuItemStr);
            }
            else if(g_bConfig_LimitedWeaponsRotation && weaponTracking_IsWaiting(weapons_GetTracker(weaponId), clientIndex, isCT))
            {
                new encodedId = weaponId | (_:weapons_MenuActions_GetOutWaitLine);
                
                IntToString(encodedId, weaponIdStr, sizeof(weaponIdStr));
                
                if(g_fConfig_LimitedWeaponsRotationTime == 0.0)
                {
                    Format(menuItemStr, sizeof(menuItemStr), "%s (%T)", weaponName, "Exit wait", clientIndex);
                }
                else
                {
                    new Float:time = weaponTracking_GetWaitTime(weapons_GetTracker(weaponId), clientIndex, isCT, weapons_GetLimit(weaponId));
                    decl String:timeStr[10];
                    FormatGameTime(timeStr, sizeof(timeStr), time);
                    Format(menuItemStr, sizeof(menuItemStr), "%s (%T~%s)", weaponName, "Exit wait or wait", clientIndex, timeStr);
                }
                AddMenuItem(menu, weaponIdStr, menuItemStr);
            }
            else
            {
                IntToString(weaponId, weaponIdStr, sizeof(weaponIdStr));
                Format(menuItemStr, sizeof(menuItemStr), "%s (%d %T!)", weaponName, currentUsed, "in your team", clientIndex);
                AddMenuItem(menu, weaponIdStr, menuItemStr, ITEMDRAW_DISABLED);
            }
        }
    }
}

stock weapons_IsListEmpty(bool:weaponPrimary)
{
    new Handle:listArray = weaponPrimary ? g_hWeapons_PrimaryWeaponsListed : g_hWeapons_SecondaryWeaponsListed;
    
    if (GetArraySize(listArray) > 0)
        return false;
    else
        return true;
}

stock weapons_GetAmmoType(weaponEntity)
{
    return GetEntData(weaponEntity, g_iWeapons_AmmoTypeOffset);
}

stock weapons_GetAmmo(clientIndex, weaponEntity)
{
    new ammoType = weapons_GetAmmoType(weaponEntity);
    
    if ((ammoType >= 0) && (ammoType < 32))
        return GetEntData(clientIndex, g_iWeapons_AmmoOffset + (ammoType * 4), 4);
    else
        return 0;
}

stock weapons_GiveAmmo(clientIndex, weaponEntity, ammo)
{
    new ammoType = weapons_GetAmmoType(weaponEntity);
    
    if ((ammoType >= 0) && (ammoType < 32))
        SetEntData(clientIndex, g_iWeapons_AmmoOffset + (ammoType * 4), ammo, 4, true);
}

stock weapons_ResetAmmo(clientIndex)
{
    new ammoArray[32] = {0, ...};
    
    SetEntDataArray(clientIndex, g_iWeapons_AmmoOffset, ammoArray, sizeof(ammoArray), 4);
}

public Action:weapons_Timer_RefillAmmo(Handle:timer, any:weaponRef)
{
    new weaponEntity = EntRefToEntIndex(weaponRef);
    decl weaponId;
        
    if(!IsValidEdict(weaponEntity) || !weapons_IsEntityTagged(weaponEntity, weaponId))
        return Plugin_Stop;
        
    new clientIndex = GetEntDataEnt2(weaponEntity, g_iWeapons_OwnerOffset);
    
    if (players_IsClientValid(clientIndex) && IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
    {
        weapons_GiveAmmo(clientIndex, weaponEntity, g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent]);
    }

    return Plugin_Stop;
}

stock weapons_RefillAmmo(weaponEntity)
{
    decl weaponId;
    decl clientIndex;
    
    if(IsValidEdict(weaponEntity) && weapons_IsEntityTagged(weaponEntity, weaponId, clientIndex) && weaponId > NO_WEAPON_SELECTED)
    {
        new Float:gameTime = GetGameTime();
        
        if(dhook_IsAmmoNetworkStateChangedAvailable())
        {
            weapons_TagEntityAsReloading(weaponEntity, gameTime);
        }
        else
        {
            new Float:reloadTime = weapons_GetReloadTime(weaponId);
            new Float:LastReloadTime = weapons_GetLastEntityReload(weaponId);
            
            if (
                LastReloadTime + reloadTime < gameTime &&
                (weaponId != g_iWeapons_WeaponIndex_Tazer || g_bConfig_ZeusRefill)
               )
            {
                g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent] = weapons_GetAmmoMax(weaponId);
                weapons_TagEntityAsReloading(weaponEntity, gameTime);
                CreateTimer(reloadTime, weapons_Timer_RefillAmmo, EntIndexToEntRef(weaponEntity), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    
    }
}

public Action:weapons_Timer_StopPerBulletReload(Handle:timer, any:weaponRef)
{
    new weaponEntity = EntRefToEntIndex(weaponRef);
    decl weaponId;
    
    if(!IsValidEdict(weaponEntity) || !weapons_IsEntityTagged(weaponEntity, weaponId))
        return Plugin_Stop;
        
    new clientIndex = GetEntDataEnt2(weaponEntity, g_iWeapons_OwnerOffset);
    
    if (players_IsClientValid(clientIndex) && IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
    {
        // Set Ammo to 0 to stop reload animation
        weapons_GiveAmmo(clientIndex,  weaponEntity, 0);
        // Set back Ammo after a timer
        CreateTimer(0.5, weapons_Timer_RefillAmmo, weaponRef, TIMER_FLAG_NO_MAPCHANGE);
    }

    return Plugin_Stop;
}

stock weapons_NetworkStateChanged_m_iAmmo(clientIndex, offset)
{
    if(!g_bConfig_Enabled)
        return;
    
    new ammoType = (offset - g_iWeapons_AmmoOffset) / 4;
    
    new weaponEntity = players_FindWeaponFromAmmoOffset(clientIndex, ammoType);
    
    decl weaponId;
    
    if(weaponEntity == -1 || !weapons_IsEntityTagged(weaponEntity, weaponId))
        return;
    
    if(weapons_IsPerBulletReload(weaponId))
    {
        new oldClipContent = g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent];
        
        if(g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] < weapons_GetClipSize(weaponId))
            g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent]++;
        else
            g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] = weapons_GetClipSize(weaponId);
        
        if(!g_bConfig_ReplenishAmmo && oldClipContent < weapons_GetClipSize(weaponId))
            g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent]--;
        
        if(g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] == weapons_GetClipSize(weaponId))
        {
            weapons_RefillClip(EntIndexToEntRef(weaponEntity), weaponId, g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent]);
            
            if(g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] == weapons_GetOriginalClipSize(weaponId))
            {
                CreateTimer(0.1, weapons_Timer_RefillAmmo, EntIndexToEntRef(weaponEntity), TIMER_FLAG_NO_MAPCHANGE);
            }
            else
                CreateTimer(0.1, weapons_Timer_StopPerBulletReload, EntIndexToEntRef(weaponEntity), TIMER_FLAG_NO_MAPCHANGE); 
        }
        else if(g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] == weapons_GetOriginalClipSize(weaponId))
        {
            g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] = weapons_GetClipSize(weaponId);
            
            if(g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] - oldClipContent > g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent])
                g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] = oldClipContent + g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent];
        
            if(g_bConfig_ReplenishAmmo)
                g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent] = weapons_GetAmmoMax(weaponId);
            else
                g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent] += oldClipContent - g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent];
            
            CreateTimer(0.1, weapons_Timer_RefillAmmo, EntIndexToEntRef(weaponEntity), TIMER_FLAG_NO_MAPCHANGE);
            weapons_RefillClip(EntIndexToEntRef(weaponEntity), weaponId, g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent]);
        }
        else if (g_bConfig_ReplenishAmmo)
            CreateTimer(0.1, weapons_Timer_RefillAmmo, EntIndexToEntRef(weaponEntity), TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        CreateTimer(0.1, weapons_Timer_RefillAmmo, EntIndexToEntRef(weaponEntity), TIMER_FLAG_NO_MAPCHANGE);
        weapons_RefillClip(EntIndexToEntRef(weaponEntity), weaponId, g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent]);
    }
}

stock weapons_RefillClip(weaponRef, actualWeapon, forcedAmmo=-1)
{
    new weaponEntity = EntRefToEntIndex(weaponRef);
    
    if (forcedAmmo > -1 && IsValidEdict(weaponEntity))
        SetEntData(weaponEntity, g_iWeapons_Clip1Offset, forcedAmmo, 4, true);
    
    else if ((actualWeapon > NO_WEAPON_SELECTED) && IsValidEdict(weaponEntity))
    {
        new targetAmmo = weapons_GetClipSize(actualWeapon);
        
        g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] = targetAmmo;
        SetEntData(weaponEntity, g_iWeapons_Clip1Offset, targetAmmo, 4, true);
    }
}

public  Action:weapons_Timer_SetAmmoAndClip(Handle:timer, any:weaponRef)
{
    new weaponEntity = EntRefToEntIndex(weaponRef);
        
    if (IsValidEntity(weaponEntity))
    {
        weapons_RefillClip(weaponRef, NO_WEAPON_SELECTED, g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent]);

        new owner = GetEntDataEnt2(weaponEntity, g_iWeapons_OwnerOffset);
        
        if(players_IsClientValid(owner))
            weapons_GiveAmmo(owner, weaponEntity, g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent]);
    }
}

stock weapons_GetClipBulletsCount(weaponEntity)
{
    if (IsValidEdict(weaponEntity))
        return GetEntData(weaponEntity, g_iWeapons_Clip1Offset, 4);
    else
        return -1;
}

stock bool:weapons_IsClipFull(weaponEntity, actualWeapon)
{
    if ((actualWeapon > NO_WEAPON_SELECTED) && IsValidEdict(weaponEntity))
    {
        if (weapons_GetClipBulletsCount(weaponEntity) >= weapons_GetClipSize(actualWeapon))
            return true;
        else
            return false;
    }
    else
        return false;
}

public Action:weapons_Timer_AfterWeaponSpawn(Handle:timer, any:weaponRef)
{
    new weaponEntity = EntRefToEntIndex(weaponRef);
        
    if (IsValidEntity(weaponEntity))
    {
        decl bool:reloadHooked;
        
        if(weapons_IsEntityTagged(weaponEntity, .reloadHooked=reloadHooked))
        {
            if(!reloadHooked)
            {
                SDKHook(weaponEntity, SDKHook_Reload, Hook_OnWeaponReload);
                weapons_SetReloadHooked(weaponEntity, true);
            }
        }
        else if(g_bConfig_WeaponsAllowThirdParty || weapons_FindIdFromEntity(weaponEntity) == g_iWeapons_WeaponIndex_C4)
        {
            new weaponId = weapons_FindIdFromEntity(weaponEntity);
            new clientIndex = GetEntDataEnt2(weaponEntity, g_iWeapons_OwnerOffset);
            
            if(weaponId == -1 || (!players_IsClientValid(clientIndex) && !g_bConfig_WeaponsAllowUncarried) )
            {
                AcceptEntityInput(weaponEntity, "Kill");
            }
            else
            {
                if(players_IsClientValid(clientIndex))
                {
                    new bool:isCT = GetClientTeam(clientIndex) == CS_TEAM_CT;

                    if(weapons_IsClientTeamInverted(clientIndex))
                        isCT = !isCT;
                    
                    weapons_TagEntity(weaponEntity, weaponId, .owner = clientIndex, .isCT=isCT);
                }
                else
                    weapons_TagEntity(weaponEntity, weaponId, .owner = 0);
                
                SDKHook(weaponEntity, SDKHook_Reload, Hook_OnWeaponReload);
                weapons_SetReloadHooked(weaponEntity, true);
                
                
                if(players_IsClientValid(clientIndex) && weapons_IsLimited(weaponId, GetClientTeam(clientIndex) == CS_TEAM_CT, _, _, clientIndex))
                {
                    decl String:weaponName[WEAPON_NAME_SIZE];
                    decl String:formatedWeaponName[WEAPON_NAME_SIZE+2];
                    
                    new weaponLimit = weapons_GetLimit(weaponId);
                    
                    weapons_GetName(weaponId, weaponName, WEAPON_NAME_SIZE);
                    Format(formatedWeaponName, sizeof(formatedWeaponName), "\x0C%s\x01", weaponName);
                    PrintToChat(clientIndex, "[ \x02DM\x01 ] %t", "Weapon removed because limited", formatedWeaponName, weaponLimit);
                    
                    players_OnWeaponStrippedPre(clientIndex, weaponEntity);
                    weapons_RemovePlayerWeapon(weaponEntity, clientIndex);
                    players_OnWeaponStripped(clientIndex, weaponId);
                }
                else
                    weapons_EnforceUncarriedLimits(weaponId);
            }
        }
        else
        {
            AcceptEntityInput(weaponEntity, "Kill");
        }
    }
}

public Hook_OnWeaponSpawned(weaponEntity)
{
    CreateTimer(0.0, weapons_Timer_AfterWeaponSpawn, EntIndexToEntRef(weaponEntity));
}

public Hook_OnWeaponReload(weaponEntity)
{
    decl weaponId;
    if (!g_bConfig_Enabled || !weapons_IsEntityTagged(weaponEntity, weaponId))
        return;
    
    if (!weapons_IsPerBulletReload(weaponId))
    {
        new oldClipContent = g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent];
        
        g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] = weapons_GetClipSize(weaponId);
        
        if(g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] - oldClipContent > g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent])
            g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] = oldClipContent + g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent];
        
        if(g_bConfig_ReplenishAmmo)
            g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent] = weapons_GetAmmoMax(weaponId);
        else
            g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent] += oldClipContent - g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent];
    }
    
    if (g_bConfig_ReplenishAmmo && !dhook_IsAmmoNetworkStateChangedAvailable())
        weapons_RefillAmmo(weaponEntity);
}

stock weapons_OnWeaponFire(weaponEntity)
{
   g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] -= 1;
}

stock weapons_ResetClientWeapons(clientIndex)
{
    g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryId] = NO_WEAPON_SELECTED;
    g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity] = -1;
    g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryId] = NO_WEAPON_SELECTED;
    g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity] = -1;
    g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryWaitLine] = NO_WEAPON_SELECTED;
    g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryWaitLine] = NO_WEAPON_SELECTED;
    g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_IsTeamInverted] = false;
}

stock weapons_PlayerSwitchTeam(clientIndex, oldTeam, newTeam)
{
    for(new slot = _:weapons_PlayerEquipment_PrimaryEntity; slot <= _:weapons_PlayerEquipment_SecondaryEntity; slot++)
    {
        if(MaxClients <= g_aWeapons_PlayerEquipment[clientIndex][slot] < sizeof(g_aWeapons_EdictsData))
            weapons_SwitchTeam(g_aWeapons_PlayerEquipment[clientIndex][slot], oldTeam, newTeam);
    }
    
    for(new slot = _:weapons_PlayerEquipment_PrimaryId; slot <= _:weapons_PlayerEquipment_SecondaryId; slot++)
    {
        if((oldTeam == CS_TEAM_CT || oldTeam == CS_TEAM_T) && g_aWeapons_PlayerEquipment[clientIndex][slot] != NO_WEAPON_SELECTED)
            weaponTracking_RemoveUser( 
                    weapons_GetTracker(g_aWeapons_PlayerEquipment[clientIndex][slot]),
                    clientIndex,
                    oldTeam == CS_TEAM_CT
                );
        
        if((newTeam == CS_TEAM_CT || newTeam == CS_TEAM_T) && g_aWeapons_PlayerEquipment[clientIndex][slot] != NO_WEAPON_SELECTED)
            weaponTracking_AddUser( 
                    weapons_GetTracker(g_aWeapons_PlayerEquipment[clientIndex][slot]),
                    clientIndex,
                    newTeam == CS_TEAM_CT
                );
    }
    
    for(new slot = _:weapons_PlayerEquipment_PrimaryWaitLine; slot <= _:weapons_PlayerEquipment_SecondaryWaitLine; slot++)
    {
        new weapon = g_aWeapons_PlayerEquipment[clientIndex][slot];
        if(weapon != NO_WEAPON_SELECTED)
        {
            new bool:isWaiter = false;
            if(oldTeam == CS_TEAM_CT || oldTeam == CS_TEAM_T)
                isWaiter = weapons_ExitWaitLine(clientIndex, weapon);
                        
            if(isWaiter && (newTeam == CS_TEAM_CT || newTeam == CS_TEAM_T))
            {
                weapons_EnterWaitLine(clientIndex, weapon, newTeam);
            }
        }
    }
}

stock weapons_OnClientDisconnect(clientIndex)
{
    for(new slot = _:weapons_PlayerEquipment_PrimaryWaitLine; slot <= _:weapons_PlayerEquipment_SecondaryWaitLine; slot++)
    {
        new weapon = g_aWeapons_PlayerEquipment[clientIndex][slot];
        if(weapon != NO_WEAPON_SELECTED)
            weapons_ExitWaitLine(clientIndex, weapon);
    }
    
    if(IsValidEdict(g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity]))
        AcceptEntityInput(g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity], "Kill");
    
    if(IsValidEdict(g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity]))
        AcceptEntityInput(g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity], "Kill");
    
    weapons_ResetClientWeapons(clientIndex);
}

stock weapons_StoreClientWeapon(clientIndex, weaponEntity)
{
    if(IsValidEdict(weaponEntity))
    {
        RemovePlayerItem(clientIndex, weaponEntity);
        TeleportEntity(weaponEntity, g_vOffWorldPosition, NULL_VECTOR, NULL_VECTOR);
    }
}

stock bool:weapons_DropClientWeapon(clientIndex, weaponEntity)
{
    if(weaponEntity < 0)
        return false;
    
    new bool:ret = false;

    if(!IsValidEdict(weaponEntity))
        return false;

    if(
            g_aWeapons_EdictsData[weaponEntity][bWeapons_EdictsStructureElements_isTagged] &&
            g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Id] != NO_WEAPON_SELECTED
          )
    {
        new bool:IsSecondary;
        if(weapons_IsPrimary(g_aWeapons_EdictsData[weaponEntity][iWeapons_EdictsStructureElements_Id], IsSecondary))
        {
            g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity] = -1;
            g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryId] = NO_WEAPON_SELECTED;
        }
        else if(IsSecondary)
        {
            g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity] = -1;
            g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryId] = NO_WEAPON_SELECTED;
        }
    }
    
    if(players_IsClientValid(clientIndex) && IsPlayerAlive(clientIndex))
    {
        SDKHooks_DropWeapon(clientIndex, weaponEntity);
        players_OnWeaponDrop(clientIndex, weaponEntity);
        ret = true;
    }
    
    return ret;
}

stock weapons_OnClientDeath(clientIndex)
{
    new bool:dropNade = false;
    
    if(g_iConfig_mp_death_drop_gun == 1)
    {
        if(!weapons_DropClientWeapon(clientIndex, g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity]))
            weapons_DropClientWeapon(clientIndex, g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity]);
    }
    else if(g_iConfig_mp_death_drop_gun == 2)
    {
        if(g_iConfig_mp_death_drop_grenade == 2)
            dropNade = true;
        
        players_DropActiveWeaponOnDeath(clientIndex, dropNade);
    }
    if(!dropNade || g_iConfig_mp_death_drop_grenade > 0)
        players_DropBestNadeOnDeath(clientIndex);
    
    weapons_StoreClientWeapon(clientIndex, g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity]);
    weapons_StoreClientWeapon(clientIndex, g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity]);
}

stock weapons_OnPlayerEquiped(clientIndex, weaponEntity, weaponId)
{
    decl bool:weaponSecondary;
    new bool:weaponPrimary = weapons_IsPrimary(weaponId, weaponSecondary);
    
    if( weaponPrimary ) g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity] = weaponEntity;
    else if(weaponSecondary) g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity] = weaponEntity;
    
    if( weaponPrimary ) g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryId] = weaponId;
    else if(weaponSecondary) g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryId] = weaponId;
    
    g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent] = weapons_GetClipSize(weaponId);
    g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent] = weapons_GetAmmoMax(weaponId);
    
    weapons_GiveAmmo(clientIndex, weaponEntity, g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_AmmoContent]);
    weapons_RefillClip(EntIndexToEntRef(weaponEntity), weaponId, g_aWeapons_EdictsData[weaponEntity][weapons_EdictsStructureElements_ClipContent]);
}

stock weapons_GetPrimaryWeaponEntity(clientIndex)
{
    return g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryEntity];
}

stock weapons_GetSecondaryWeaponEntity(clientIndex)
{
    return g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryEntity];
}

stock weapons_GetPrimaryWeaponId(clientIndex)
{
    return g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_PrimaryId];
}

stock weapons_GetSecondaryWeaponId(clientIndex)
{
    return g_aWeapons_PlayerEquipment[clientIndex][weapons_PlayerEquipment_SecondaryId];
}

static weapons_Worker_AdvertiseWeaponAwarded(clientIndex, weaponId)
{
    if(!players_IsClientValid(clientIndex) || !IsClientInGame(clientIndex))
        return;
    
    decl String:weaponName[WEAPON_NAME_SIZE];
    decl String:formatedWeaponName[WEAPON_NAME_SIZE+2];
    
    weapons_GetName(weaponId, weaponName, WEAPON_NAME_SIZE);
    Format(formatedWeaponName, sizeof(formatedWeaponName), "\x0C%s\x01", weaponName);
    
    sounds_PlayToClient(clientIndex, SOUNDS_WEAPON_AWARDED);
    PrintToChat(clientIndex, "[ \x02DM\x01 ] %t", "Weapon awarded", formatedWeaponName);
}

static weapons_Worker_AdvertiseWeaponTransfer(waiter, targetUser, weaponId, Float:time, level=-1)
{
    if(!players_IsClientValid(waiter) || !IsClientInGame(waiter))
        return;
    
    decl String:weaponName[WEAPON_NAME_SIZE];
    decl String:formatedWeaponName[WEAPON_NAME_SIZE+2];
    decl String:timeStr[10];
    decl String:timeStrFormated[12];
    
    FormatGameTime(timeStr, sizeof(timeStr), time);
    Format(timeStrFormated, sizeof(timeStrFormated), "\x09%s\x01", timeStr);
    weapons_GetName(weaponId, weaponName, WEAPON_NAME_SIZE);
    Format(formatedWeaponName, sizeof(formatedWeaponName), "\x0C%s\x01", weaponName);
    
    weapons_playTimerSound(waiter, level);
    PrintToChat(waiter, "[ \x02DM\x01 ] %t", "Weapon delayed", formatedWeaponName, timeStrFormated);
    
    if(time != g_fConfig_LimitedWeaponsRotationTime && players_IsClientValid(targetUser) && IsClientInGame(targetUser))
    {
        weapons_playTimerSound(targetUser, level);
        PrintToChat(targetUser, "[ \x02DM\x01 ] %t", "Weapon removal pending", formatedWeaponName, timeStrFormated);
    }
}

static weapons_playTimerSound(clientIndex, level)
{
    if(level == 1)
        sounds_PlayToClient(clientIndex, SOUNDS_WEAPON_TIMER1);
    else if(level == 2)
        sounds_PlayToClient(clientIndex, SOUNDS_WEAPON_TIMER2);
    else if(level == 3)
        sounds_PlayToClient(clientIndex, SOUNDS_WEAPON_TIMER3);
}

static bool:weapons_Worker_ShallAdvertiseWeaponTransfer(Float:waitTime, &level)
{
    decl Float:displayStep;
    
    level = -1;
    
    if(waitTime < 0.5)
        return false;
    
    
    if (waitTime <= 5.0)
    {
        displayStep = 0.5;
        level = 3;
    }
    else if (waitTime <= 20.0)
    {
        displayStep = 5.0;
        level = 2;
    }
    else if(waitTime <= 60.0)
    {
        displayStep = 10.0;
        level = 1;
    }
    else
    {
        displayStep = 30.0;
        level = 1;
    }
    
    if(FloatAbs(waitTime - (RoundToFloor(waitTime/displayStep) * displayStep)) < 1.0)
        return true;
    else
        return false;
}

static bool:weapons_Worker_ShallOpenTargetWeaponMenu(Float:waitTime)
{
    if(2.0 < waitTime <= 3.0)
        return true;
    else
        return false;
}

static weapons_Worker(weaponId, bool:isCT)
{
    new Handle:tracker = weapons_GetTracker(weaponId);
    new waitersCount = weaponTracking_GetWaitersCount(tracker, isCT);
    new usersCount = weaponTracking_GetUsersCount(tracker, isCT);
    new limit = weapons_GetLimit(weaponId);
    
    if(waitersCount == 0)
        return;
    
    for(new index = 0; index < limit-usersCount; index++)
    {
        decl waiter;
        if(!weaponTracking_FromWaiterToUser(tracker, waiter, isCT))
            return;
        
        players_SwitchToWeaponId(waiter, weaponId);
        weapons_Worker_AdvertiseWeaponAwarded(waiter, weaponId);
    }
    
    if(g_fConfig_LimitedWeaponsRotationTime == 0.0)
        return;
    
    waitersCount = weaponTracking_GetWaitersCount(tracker, isCT);
    for(new index = 0; index < waitersCount; index++)
    {
        new waiter = weaponTracking_GetWaiterByIndex(tracker, index, isCT);
        new targetUser = -1;
        decl level;
        new Float:waitTime = weaponTracking_GetWaitTime(tracker, waiter, isCT, limit, targetUser, .exact = true);
        
        if(weapons_Worker_ShallAdvertiseWeaponTransfer(waitTime, level))
            weapons_Worker_AdvertiseWeaponTransfer(waiter, targetUser, weaponId, waitTime, level);
        
        if(players_IsClientValid(targetUser) && weapons_Worker_ShallOpenTargetWeaponMenu(waitTime) && !IsFakeClient(targetUser))
            menus_OnWeaponStripped(targetUser, weapons_IsPrimary(weaponId));
        
        if(waitTime <= 0.0)
        {
            
            weaponTracking_RemoveUser(tracker, targetUser, isCT);
            weaponTracking_RemoveWaiter(tracker, waiter, isCT);
            weaponTracking_AddUser(tracker, waiter, isCT);
            
            players_RemoveWeaponId(targetUser, weaponId);
            players_SwitchToWeaponId(waiter, weaponId);
            
            weapons_Worker_AdvertiseWeaponAwarded(waiter, weaponId);
        }
    }
}

public Action:weapons_Timer_Worker(Handle:timer)
{
    if(!g_bConfig_LimitedWeaponsRotation)
        return Plugin_Continue;
    
    for(new weapon = 0; weapon < g_iWeapons_AvailableWeapons; weapon++)
    {
        if(weapons_GetLimit(weapon) > 0)
        {
            weapons_Worker(weapon, .isCT = false);
            weapons_Worker(weapon, .isCT = true);
        }
    }
    
    return Plugin_Continue;
}

stock weapons_debug(clientIndex)
{
    for(new weapon = 0; weapon < g_iWeapons_AvailableWeapons - 1; weapon++)
    {
        new Handle:tracker = weapons_GetTracker(weapon);
        new userSize = weaponTracking_GetUsersCount(tracker, false);
        
        decl String:weaponName[WEAPON_NAME_SIZE];
        weapons_GetName(weapon, weaponName, WEAPON_NAME_SIZE);
        
        if(0 < weapons_GetLimit(weapon) < userSize )
            ReplyToCommand(clientIndex, "!WTF! Weapon %s has limit %d but T users %d", weaponName, weapons_GetLimit(weapon), userSize);
        
        for (new index = 0; index < userSize; index++)
        {
            new user = weaponTracking_GetUserByIndex(tracker, index, false);
            decl String:userName[50];
            
            GetClientName(user, userName, 50);
            
            if(GetClientTeam(user) != CS_TEAM_T)
                ReplyToCommand(clientIndex, "!WTF! User %s is not T but is in users of weapon %s", userName, weaponName);
            
            new actualweaponId = weapons_IsPrimary(weapon)? g_aWeapons_PlayerEquipment[user][weapons_PlayerEquipment_PrimaryId] : g_aWeapons_PlayerEquipment[user][weapons_PlayerEquipment_SecondaryId];
            
            if(weapon < g_iWeapons_WeaponIndex_Decoy && weapon != actualweaponId)
            {
                decl String:actualWeaponName[WEAPON_NAME_SIZE];
                weapons_GetName(actualweaponId, actualWeaponName, WEAPON_NAME_SIZE);
                ReplyToCommand(clientIndex, "!WTF! User %s is in %s T users but has %s", userName, weaponName, actualWeaponName);
            }
        }
        
        new waiterSize = weaponTracking_GetWaitersCount(tracker, false);
        for (new index = 0; index < waiterSize; index++)
        {
            new user = weaponTracking_GetWaiterByIndex(tracker, index, false);
            decl String:userName[50];
            
            if(!players_IsClientValid(user))
            {
                ReplyToCommand(clientIndex, "!WTF! User %d is invalid but is in T waiters of weapon %s", user, weaponName);
                continue;
            }
            
            GetClientName(user, userName, 50);
            
            if(GetClientTeam(user) != CS_TEAM_T)
                ReplyToCommand(clientIndex, "!WTF! User %s is not T but is in waiters of weapon %s", userName, weaponName);
            
        }
    }
    
    for(new weapon = 0; weapon < g_iWeapons_AvailableWeapons - 1; weapon++)
    {
        new Handle:tracker = weapons_GetTracker(weapon);
        new userSize = weaponTracking_GetUsersCount(tracker, true);
        
        decl String:weaponName[WEAPON_NAME_SIZE];
        weapons_GetName(weapon, weaponName, WEAPON_NAME_SIZE);
        
        if(0 < weapons_GetLimit(weapon) < userSize )
            ReplyToCommand(clientIndex, "!WTF! Weapon %s has limit %d but CT users %d", weaponName, weapons_GetLimit(weapon), userSize);
        
        for (new index = 0; index < userSize; index++)
        {
            new user = weaponTracking_GetUserByIndex(tracker, index, true);
            decl String:userName[50];
            
            GetClientName(user, userName, 50);
            
            if(GetClientTeam(user) != CS_TEAM_CT)
                ReplyToCommand(clientIndex, "!WTF! User %s is not CT but is in users of weapon %s", userName, weaponName);
            
            new actualweaponId = weapons_IsPrimary(weapon)? g_aWeapons_PlayerEquipment[user][weapons_PlayerEquipment_PrimaryId] : g_aWeapons_PlayerEquipment[user][weapons_PlayerEquipment_SecondaryId];
            
            if(weapon < g_iWeapons_WeaponIndex_Decoy && weapon != actualweaponId)
            {
                decl String:actualWeaponName[WEAPON_NAME_SIZE];
                weapons_GetName(actualweaponId, actualWeaponName, WEAPON_NAME_SIZE);
                ReplyToCommand(clientIndex, "!WTF! User %s is in %s CT users but has %s", userName, weaponName, actualWeaponName);
            }
        }
        
        new waiterSize = weaponTracking_GetWaitersCount(tracker, true);
        for (new index = 0; index < waiterSize; index++)
        {
            new user = weaponTracking_GetWaiterByIndex(tracker, index, true);
            decl String:userName[50];
            
            if(!players_IsClientValid(user))
            {
                ReplyToCommand(clientIndex, "!WTF! User %d is invalid but is in CT waiters of weapon %s", user, weaponName);
                continue;
            }
            
            GetClientName(user, userName, 50);
            
            if(GetClientTeam(user) != CS_TEAM_CT)
                ReplyToCommand(clientIndex, "!WTF! User %s is not CT but is in waiters of weapon %s", userName, weaponName);
            
        }
    }
    
    for(new client = 0; client <= MaxClients; client++)
    {
        if(!players_IsClientValid(client) || !IsClientInGame(client))
            continue;
            
        decl String:userName[50];
        
        GetClientName(client, userName, 50);
            
        new weapon = g_aWeapons_PlayerEquipment[client][weapons_PlayerEquipment_PrimaryId];
        decl String:weaponName[WEAPON_NAME_SIZE];
        
        if(weapon != -1)
            weapons_GetName(weapon, weaponName, WEAPON_NAME_SIZE);
        
        if(weapon != -1 && !weaponTracking_IsUsing(weapons_GetTracker(weapon), client, GetClientTeam(client) == CS_TEAM_CT))
            ReplyToCommand(clientIndex, "!WTF! User %s has weapon %s but is not in its users", userName, weaponName);
        
        if(weapon != -1 && weaponTracking_IsWaiting(weapons_GetTracker(weapon), client, GetClientTeam(client) == CS_TEAM_CT))
            ReplyToCommand(clientIndex, "!WTF! User %s has weapon %s but is also in its wait line", userName, weaponName);
            
        weapon = g_aWeapons_PlayerEquipment[client][weapons_PlayerEquipment_SecondaryId];
        if(weapon != -1)
            weapons_GetName(weapon, weaponName, WEAPON_NAME_SIZE);
        
        if(weapon != -1 && !weaponTracking_IsUsing(weapons_GetTracker(weapon), client, GetClientTeam(client) == CS_TEAM_CT))
            ReplyToCommand(clientIndex, "!WTF! User %s has weapon %s but is not in its users", userName, weaponName);
        
        if(weapon != -1 && weaponTracking_IsWaiting(weapons_GetTracker(weapon), client, GetClientTeam(client) == CS_TEAM_CT))
            ReplyToCommand(clientIndex, "!WTF! User %s has weapon %s but is also in its wait line", userName, weaponName);
    }
}
