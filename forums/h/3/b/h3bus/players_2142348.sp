
#define HIDEHUD_RADAR 1 << 12
#define EYES_OFFSET 64.0

enum Teams
{
    TeamNone,
    TeamSpectator,
    TeamT,
    TeamCT
};

enum players_MyWeapons {
    players_MyWeapon_Primary,
    players_MyWeapon_Secondary,
    players_MyWeapon_Knife,
    players_MyWeapon_Tazer,
    players_MyWeapon_Decoy,
    players_MyWeapon_Smoke,
    players_MyWeapon_Flash,
    players_MyWeapon_He,
    players_MyWeapon_Incendiary,
    players_MyWeapon_C4
    
}

enum players_EquipmentRewards {
    players_EquipmentReward_Kill,
    players_EquipmentReward_HS,
    players_EquipmentReward_Knife,
    players_EquipmentReward_Nade
}

// Offsets
static g_iPlayers_ArmourOffset;
static g_iPlayers_HelmetOffset;
static g_iPlayers_DefuserOffset;
static g_iPlayers_RagdollOffset;
static g_iPlayers_NextAttackOffset;
static g_iPlayers_ActiveWeaponOffset;
static g_iPlayers_LastWeaponOffset;
static g_iPlayers_MyWeaponsOffset;
static g_iPlayers_ViewModelOffset;
static g_iPlayers_ViewModel_SequenceOffset;
static g_iPlayers_FovOffset;
static g_iPlayers_DefaultFovOffset;
static g_iPlayers_TeamNumOffset;

// Weapon indexes
static g_iPlayers_WeaponIndex_M4a1S;


// Player settings
static g_iPlayers_PrimaryWeapon[MAXPLAYERS + 1] = { NO_WEAPON_SELECTED, ... };
static g_iPlayers_SecondaryWeapon[MAXPLAYERS + 1] = { NO_WEAPON_SELECTED, ... };
static bool:g_bPlayers_FirstWeaponSelection[MAXPLAYERS + 1] = { true, ... };
static bool:g_bPlayers_PrimaryChosenThisRound[MAXPLAYERS + 1] = { false, ... };
static bool:g_bPlayers_SecondaryChosenThisRound[MAXPLAYERS + 1] = { false, ... };

// Player equipment
static g_iPlayers_SpawnEquipment[players_MyWeapons] = {0, ...};
new g_iPlayers_MaxEquipment[players_MyWeapons] = {0, ...};

static bool:g_bPlayers_HasEquipmentReward[players_EquipmentRewards] = {false, ...};
static g_iPlayers_EquipmentReward[players_EquipmentRewards][players_MyWeapons];

stock players_Init()
{
    // Find offsets
    g_iPlayers_ArmourOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
    g_iPlayers_HelmetOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
    g_iPlayers_DefuserOffset = FindSendPropOffs("CCSPlayer", "m_bHasDefuser");
    g_iPlayers_RagdollOffset = FindSendPropOffs("CCSPlayer", "m_hRagdoll");
    g_iPlayers_NextAttackOffset = FindSendPropOffs("CCSPlayer", "m_flNextAttack");
    g_iPlayers_ActiveWeaponOffset = FindSendPropOffs("CCSPlayer", "m_hActiveWeapon");
    g_iPlayers_LastWeaponOffset = FindSendPropOffs("CCSPlayer", "m_hLastWeapon");
    g_iPlayers_MyWeaponsOffset = FindSendPropOffs("CCSPlayer", "m_hMyWeapons");
    g_iPlayers_ViewModelOffset = FindSendPropOffs("CCSPlayer", "m_hViewModel");
    g_iPlayers_ViewModel_SequenceOffset = FindSendPropOffs("CBaseViewModel", "m_nSequence");
    g_iPlayers_FovOffset = FindSendPropOffs("CCSPlayer", "m_iFOV");
    g_iPlayers_DefaultFovOffset = FindSendPropOffs("CCSPlayer", "m_iDefaultFOV");
    g_iPlayers_TeamNumOffset = FindSendPropOffs("CCSPlayer", "m_iTeamNum");
    
    weapons_FindId("weapon_m4a1_silencer", g_iPlayers_WeaponIndex_M4a1S);
}

stock players_UpdateSpawnEquipment()
{
    g_iPlayers_SpawnEquipment[players_MyWeapon_Knife] = g_bConfig_Knife? 1 : 0;
    g_iPlayers_SpawnEquipment[players_MyWeapon_Tazer] = g_bConfig_ZeusRefill? weapons_GetAmmoMax(g_iWeapons_WeaponIndex_Tazer) : g_iConfig_Zeus;
    g_iPlayers_SpawnEquipment[players_MyWeapon_Decoy] = g_iConfig_Decoy;
    g_iPlayers_SpawnEquipment[players_MyWeapon_Smoke] = g_iConfig_Smoke;
    g_iPlayers_SpawnEquipment[players_MyWeapon_Flash] = g_iConfig_flashbang;
    g_iPlayers_SpawnEquipment[players_MyWeapon_He] = g_iConfig_He;
    g_iPlayers_SpawnEquipment[players_MyWeapon_Incendiary] = g_iConfig_Incendiary;
}

stock players_UpdateMaxEquipment()
{
    g_iPlayers_MaxEquipment[players_MyWeapon_Knife] = g_bConfig_Knife? 1 : 0;
    g_iPlayers_MaxEquipment[players_MyWeapon_Tazer] = g_bConfig_ZeusRefill? weapons_GetAmmoMax(g_iWeapons_WeaponIndex_Tazer) : g_iConfig_ZeusMax;
    g_iPlayers_MaxEquipment[players_MyWeapon_Decoy] = g_iConfig_DecoyMax;
    g_iPlayers_MaxEquipment[players_MyWeapon_Smoke] = g_iConfig_SmokeMax;
    g_iPlayers_MaxEquipment[players_MyWeapon_Flash] = g_iConfig_flashbangMax;
    g_iPlayers_MaxEquipment[players_MyWeapon_He] = g_bConfig_HeRefill? 1 : g_iConfig_HeMax;
    g_iPlayers_MaxEquipment[players_MyWeapon_Incendiary] = g_iConfig_IncendiaryMax;
    
    for(new weapon = 0; weapon < _:players_MyWeapon_C4; weapon++)
    {
        new maxEquipment = g_iPlayers_MaxEquipment[players_MyWeapons:weapon];
        
        if(g_iPlayers_SpawnEquipment[players_MyWeapons:weapon] > maxEquipment)
            maxEquipment = g_iPlayers_SpawnEquipment[players_MyWeapons:weapon];
        
        for(new rewardType = 0; rewardType <= _:players_EquipmentReward_Nade; rewardType++)
        {
            if(g_iPlayers_EquipmentReward[players_EquipmentRewards:rewardType][players_MyWeapons:weapon] > maxEquipment)
                maxEquipment = g_iPlayers_EquipmentReward[players_EquipmentRewards:rewardType][players_MyWeapons:weapon];
        }
        
        g_iPlayers_MaxEquipment[players_MyWeapons:weapon] = maxEquipment;
    }
    
}

stock players_LoadEquimpentReward(String:equimpentReward[], players_EquipmentRewards:rewardType)
{
    new bool:HasEquimpentReward = false;
    decl String:deSerialisedRewards[_:players_MyWeapon_C4][50];
    
    RemoveChar(equimpentReward, ' ');
    new rewardsCount = deserializeStrings(equimpentReward, deSerialisedRewards, sizeof(deSerialisedRewards), sizeof(deSerialisedRewards[]), ',');
    
    for(new rewardWeapon = 0; rewardWeapon < _:players_MyWeapon_C4; rewardWeapon++)
    {
        g_iPlayers_EquipmentReward[rewardType][rewardWeapon:rewardWeapon] = 0;
    }
    
    for(new i = 0; i < rewardsCount; i++)
    {
        decl String:reward[2][50];
        
        new itemCount = deserializeStrings(deSerialisedRewards[i], reward, sizeof(reward), sizeof(reward[]), '*');
        
        if(itemCount != 2)
        {
            LogError("Unknown reward syntax %s", deSerialisedRewards[i]);
            continue;
        }
        
        new itemsToGive = StringToInt(reward[0]);
        
        if(itemsToGive > 0)
        {
            decl players_MyWeapons:rewardWeapon;
            
            if(StrEqual(reward[1], "he", false))
                rewardWeapon = players_MyWeapon_He;
            
            else if(StrEqual(reward[1], "flash", false))
                rewardWeapon = players_MyWeapon_Flash;
            
            else if(StrEqual(reward[1], "smoke", false))
                rewardWeapon = players_MyWeapon_Smoke;
            
            else if(StrEqual(reward[1], "incendiary", false))
                rewardWeapon = players_MyWeapon_Incendiary;
            
            else if(StrEqual(reward[1], "decoy", false))
                rewardWeapon = players_MyWeapon_Decoy;
            
            else if(StrEqual(reward[1], "zeus", false))
                rewardWeapon = players_MyWeapon_Tazer;
            
            else
            {
                LogError("Unknown reward weapon in %s", deSerialisedRewards[i]);
                continue;
            }
            
            g_iPlayers_EquipmentReward[rewardType][rewardWeapon] = itemsToGive;
            HasEquimpentReward = true;
        }
        else
        {
            LogError("Null or invalid reward number in %s", deSerialisedRewards[i]);
            continue;
        }
    }    
    
    g_bPlayers_HasEquipmentReward[rewardType] = HasEquimpentReward;
}

stock players_ResetClientSettings(clientIndex)
{
    players_SetClientGunModeSettings(clientIndex);
    weapons_ResetClientWeapons(clientIndex);
    
    g_bPlayers_PrimaryChosenThisRound[clientIndex] = false;
    g_bPlayers_SecondaryChosenThisRound[clientIndex] = false;
}

stock players_SetClientGunModeSettings(clientIndex)
{
    if (g_iConfig_GunMenuMode != 3)
    {
        if (IsClientConnected(clientIndex) && IsFakeClient(clientIndex))
        {
            g_iPlayers_PrimaryWeapon[clientIndex] = (g_iConfig_DefaultPrimary == NO_WEAPON_SELECTED && g_iConfig_GunMenuMode != 2) ? RANDOM_WEAPON_SELECTED : g_iConfig_DefaultPrimary;
            g_iPlayers_SecondaryWeapon[clientIndex] =(g_iConfig_DefaultSecondary == NO_WEAPON_SELECTED && g_iConfig_GunMenuMode != 2) ? RANDOM_WEAPON_SELECTED : g_iConfig_DefaultSecondary;
        }
        else
        {
            g_iPlayers_PrimaryWeapon[clientIndex] = g_iConfig_DefaultPrimary;
            g_iPlayers_SecondaryWeapon[clientIndex] = g_iConfig_DefaultSecondary;
        }
    }
    else
    {
        g_iPlayers_PrimaryWeapon[clientIndex] = RANDOM_WEAPON_SELECTED;
        g_iPlayers_SecondaryWeapon[clientIndex] = RANDOM_WEAPON_SELECTED;
    }
    
    if (IsClientConnected(clientIndex) && IsFakeClient(clientIndex))
    {
        g_bPlayers_FirstWeaponSelection[clientIndex] = false;
    }
    else
    {
        if (g_iConfig_GunMenuMode != 3)
            g_bPlayers_FirstWeaponSelection[clientIndex] = !g_bConfig_ConnectHideMenu;
        else
            g_bPlayers_FirstWeaponSelection[clientIndex] = false;
    }
}

stock players_ResetAllClientsSettings()
{
    for (new i = 1; i <= MaxClients; i++)
        players_ResetClientSettings(i);
}

stock bool:players_IsClientValid(clientIndex)
{
    return (clientIndex > 0) && (clientIndex <= MaxClients) && IsClientConnected(clientIndex);
}

stock players_ComputeValidEnnemies(bool:validEnemies[], bool:validClients[], includeCts, includeTs, &totalEnnemies)
{
    totalEnnemies = 0;
    for (new i = 1; i <= MaxClients; i++)
        if (players_IsClientValid(i) && IsClientInGame(i) && IsPlayerAlive(i))
        {
            new bool:isCt = GetClientTeam(i) == CS_TEAM_CT;
            
            if((includeCts && isCt) || (includeTs && !isCt))
            {
                totalEnnemies++;
                validEnemies[i] = true;
            }
            else
            {
                validEnemies[i] = false;
            }
            
            validClients[i] = true;
        }
        else
        {
            validEnemies[i] = false;
            validClients[i] = false;
        }
}

stock Float:players_GetMinDistanceToPoint(const Float:point[3], Float:distances[], &Float:globalScore, &Float:minTeammatesDistance, const bool:validEnemies[], const bool:validClients[], bool:isCT, bool:squared=false)
{
    new Float:minDistance = 99999999999999.9;
    decl Float:position[3];
    globalScore = 0.0;
    minTeammatesDistance = 99999999999999.9;
        
    for (new i = 1; i <= MaxClients; i++)
    if (validEnemies[i])
    {
        GetClientAbsOrigin(i, position);
        
        distances[i] = GetVectorDistance(position, point, squared);
        
        globalScore += spawns_ComputeScoreFromDistance(distances[i], .isTeammate = false, .isCT = isCT);
        
        if(minDistance > distances[i])
            minDistance = distances[i];
    }
    else if (validClients[i])
    {
        GetClientAbsOrigin(i, position);
        
        distances[i] = GetVectorDistance(position, point, squared);
        
        if(minTeammatesDistance > distances[i])
            minTeammatesDistance = distances[i];
    }
    
    return minDistance;
}

stock bool:players_HasPointClearLineOfSight(Float:point[3], Float:distances[], bool:validEnemies[], &LOSSearch)
{    
    new Float:minAllowedDistance = -1.0;
    LOSSearch = 0;
    
    do
    {
        new bool:noHigherDistance = true;
        new Float:mindistance = 99999999999999.9;
        new mindistanceIndex = 0;
        decl Float:position[3];

        for(new i = 1; i <= MaxClients; i++)
        {
            if(
                validEnemies[i] &&
                distances[i] > minAllowedDistance && 
                distances[i] < mindistance
              )
            {
                noHigherDistance = false;
                mindistance = distances[i];
                mindistanceIndex = i;
            }
        }
        
        if(noHigherDistance)
            return true;
        
        minAllowedDistance = mindistance;
        
        GetClientAbsOrigin(mindistanceIndex, position);
        position[2] += EYES_OFFSET;
        
        TR_TraceRayFilter(position, point, MASK_OPAQUE, RayType_EndPoint, spawns_TraceFilterClients);
        LOSSearch++;
    } while(TR_GetFraction() != 1.0);
    
    return false;
}

public Action:players_Timer_Respawn(Handle:Timer, any:aliveAlso)
{
    static client = 1;
    
    while(  client <= MaxClients &&
            !(
                players_IsClientValid(client) && 
                IsClientInGame(client) && 
                Teams:GetClientTeam(client) > TeamSpectator &&
                (!IsPlayerAlive(client) || aliveAlso)
             )
        )
        client++;
    
    if(client <= MaxClients)
    {
        CS_RespawnPlayer(client);
        client++;
        return Plugin_Continue;
    }
    else
    {
        client = 1;
        weapons_EnforceLimits();
        return Plugin_Stop;
    }   
}

stock players_RespawnAll()
{
    CreateTimer(0.0, players_Timer_Respawn, true, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

stock players_RespawnDead()
{
    CreateTimer(0.0, players_Timer_Respawn, false, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

stock player_FakeTeamSwitch(clientIndex, targetTeam)
{
    new lastTeam = CS_TEAM_NONE;
        
    if(targetTeam != CS_TEAM_NONE)
    {
        new team = GetEntData(clientIndex, g_iPlayers_TeamNumOffset);
        
        if(team != targetTeam)
        {
            lastTeam = team;
            SetEntData(clientIndex, g_iPlayers_TeamNumOffset, targetTeam);
        }
    }
    
    return lastTeam;
}

stock players_EquipAll()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (players_IsClientValid(i) && IsClientInGame(i) && IsPlayerAlive(i))
        {
            g_bPlayers_PrimaryChosenThisRound[i] = false;
            g_bPlayers_SecondaryChosenThisRound[i] = false;
            players_RemoveClientWeapons(i);
            
            players_SetSpawnProps(i);
            
            menus_OnClientSpawn(i);
            menusFifo_OnClientSpawn(i);
        }
    }
}

public Action:players_Timer_FastSwitch(Handle:timer, Handle:pack)
{
    ResetPack(pack);
    new clientIndex = EntRefToEntIndex(ReadPackCell(pack));
    new weaponId = ReadPackCell(pack);
    
    new sequence = 0;
    
    if(!players_IsClientValid(clientIndex) || !IsPlayerAlive(clientIndex))
        return Plugin_Stop;
    
    if (weaponId == g_iPlayers_WeaponIndex_M4a1S)
        sequence = 1;
    
    SetEntData(clientIndex, g_iPlayers_NextAttackOffset, GetGameTime());
    
    new viewModel = GetEntDataEnt2(clientIndex, g_iPlayers_ViewModelOffset);
    
    if(IsValidEntity(viewModel))
        SetEntData(viewModel, g_iPlayers_ViewModel_SequenceOffset, sequence);
    
    return Plugin_Stop;
}

stock players_FastSwitch(clientIndex, weaponId)
{
    new Handle:pack;
    CreateDataTimer(0.0, players_Timer_FastSwitch, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
    
    WritePackCell(pack, EntIndexToEntRef(clientIndex));
    WritePackCell(pack, weaponId);
}

stock players_GivePrimary(clientIndex, bool:noSwitch=false)
{
    players_RemoveClientWeaponSlot(clientIndex, SlotPrimary);
    
    weapons_GivePlayerWeapon(clientIndex,  true, g_iPlayers_PrimaryWeapon[clientIndex]);
    if(!noSwitch && weapons_GetPrimaryWeaponId(clientIndex) > NO_WEAPON_SELECTED)
    {
        SetEntDataEnt2(clientIndex, g_iPlayers_ActiveWeaponOffset, weapons_GetPrimaryWeaponEntity(clientIndex));
        
        if(g_bConfig_FastEquip)
            players_FastSwitch(clientIndex, weapons_GetPrimaryWeaponId(clientIndex));
    }
}

stock players_GiveSecondary(clientIndex, bool:noSwitch=false)
{
    players_RemoveClientWeaponSlot(clientIndex, SlotSecondary);
    
    weapons_GivePlayerWeapon(clientIndex,  false, g_iPlayers_SecondaryWeapon[clientIndex]);
    if(!noSwitch && weapons_GetSecondaryWeaponId(clientIndex) > NO_WEAPON_SELECTED)
    {
        SetEntDataEnt2(clientIndex, g_iPlayers_ActiveWeaponOffset, weapons_GetSecondaryWeaponEntity(clientIndex));
        
        if(g_bConfig_FastEquip)
            players_FastSwitch(clientIndex, weapons_GetSecondaryWeaponId(clientIndex));
    }
    else if(weapons_GetSecondaryWeaponId(clientIndex) > NO_WEAPON_SELECTED)
    {
        SetEntDataEnt2(clientIndex, g_iPlayers_LastWeaponOffset, weapons_GetSecondaryWeaponEntity(clientIndex));
    }
    
}

stock players_GetWeapons(clientIndex, weapons[players_MyWeapons])
{
    new weaponsEnt[64];
    
    GetEntDataArray(clientIndex, g_iPlayers_MyWeaponsOffset, weaponsEnt, sizeof(weaponsEnt), 4);
    
    for(new i=0; i < sizeof(weaponsEnt); i++)
    {
        decl weaponId;
        
        weaponsEnt[i] = EntRefToEntIndex(weaponsEnt[i] & 0x7FFF);
        
        if(IsValidEdict(weaponsEnt[i]) && weapons_IsEntityTagged(weaponsEnt[i], weaponId) && weaponId > NO_WEAPON_SELECTED)
        {
            new weapons_Types:weaponType = weapons_GetType(weaponId);
            
            if(weaponType == weapons_type_Primary)
                weapons[players_MyWeapon_Primary] = weaponsEnt[i];
                
            else if(weaponType == weapons_type_Secondary)
                weapons[players_MyWeapon_Secondary] = weaponsEnt[i];
                
            else if(weaponId == g_iWeapons_WeaponIndex_Knife)
                weapons[players_MyWeapon_Knife] = weaponsEnt[i];
                
            else if(weaponId == g_iWeapons_WeaponIndex_Tazer)
                weapons[players_MyWeapon_Tazer] = weaponsEnt[i];
                
            else if(weaponId == g_iWeapons_WeaponIndex_Decoy)
                weapons[players_MyWeapon_Decoy] = weaponsEnt[i];
                
            else if(weaponId == g_iWeapons_WeaponIndex_Smoke)
                weapons[players_MyWeapon_Smoke] = weaponsEnt[i];
                
            else if(weaponId == g_iWeapons_WeaponIndex_Flash)
                weapons[players_MyWeapon_Flash] = weaponsEnt[i];
                
            else if(weaponId == g_iWeapons_WeaponIndex_HE)
                weapons[players_MyWeapon_He] = weaponsEnt[i];
                
            else if(weaponId == g_iWeapons_WeaponIndex_Molotov || weaponId == g_iWeapons_WeaponIndex_Incendiary)
                weapons[players_MyWeapon_Incendiary] = weaponsEnt[i];
                
            else if(weaponId == g_iWeapons_WeaponIndex_C4)
                weapons[players_MyWeapon_C4] = weaponsEnt[i];
        }
    }
}

stock players_GetWeaponIdFromMyWeapon(clientIndex, players_MyWeapons:weapon)
{
    if(weapon == players_MyWeapon_Knife)
        return g_iWeapons_WeaponIndex_Knife;
    else if(weapon == players_MyWeapon_Tazer)
        return g_iWeapons_WeaponIndex_Tazer;
    else if(weapon == players_MyWeapon_Decoy)
        return g_iWeapons_WeaponIndex_Decoy;
    else if(weapon == players_MyWeapon_Smoke)
        return g_iWeapons_WeaponIndex_Smoke;
    else if(weapon == players_MyWeapon_Flash)
        return g_iWeapons_WeaponIndex_Flash;
    else if(weapon == players_MyWeapon_He)
        return g_iWeapons_WeaponIndex_HE;
    else if(weapon == players_MyWeapon_Incendiary)
        return GetClientTeam(clientIndex) == CS_TEAM_CT? g_iWeapons_WeaponIndex_Incendiary : g_iWeapons_WeaponIndex_Molotov;
    else
        return NO_WEAPON_SELECTED;
}

stock player_DeltaEquipItem(clientIndex, players_MyWeapons:weapon, itemEntity, countAdd, maxCount)
{
    new actualEntity = itemEntity;
    new bool:entityCreated = false;
    
    if(actualEntity <= MaxClients && maxCount > 0 && countAdd > 0)
    {
        new weaponId = players_GetWeaponIdFromMyWeapon(clientIndex, weapon);
        actualEntity = weapons_GivePlayerItemId(clientIndex, weaponId);
        entityCreated = true;
    }
    
    if(actualEntity > MaxClients)
    {
        if(maxCount <= 0)
        {
            players_OnWeaponStrippedPre(clientIndex, actualEntity);
            weapons_RemovePlayerWeapon(actualEntity, clientIndex);
        }
        else if(countAdd > 0 && weapon != players_MyWeapon_Knife)
        {
            decl currentAmmo;
            
            if(entityCreated)
                currentAmmo = 1;
            else
            {
                currentAmmo = weapons_GetAmmo(clientIndex, actualEntity);
                
                if(weapon == players_MyWeapon_Tazer)
                    currentAmmo += weapons_GetClipBulletsCount(actualEntity);
            }
            
            new ClampedTargetCount = currentAmmo + countAdd - (entityCreated?1:0);
            ClampedTargetCount = ClampedTargetCount < maxCount? ClampedTargetCount : maxCount;
            
            if(currentAmmo != ClampedTargetCount)
            {
                if(weapon == players_MyWeapon_Tazer)
                {
                    weapons_RefillClip(EntIndexToEntRef(actualEntity), NO_WEAPON_SELECTED, 1);
                    weapons_GiveAmmo(clientIndex, actualEntity, ClampedTargetCount - 1);
                }
                else if(ClampedTargetCount > 1)
                    weapons_GiveAmmo(clientIndex, actualEntity, ClampedTargetCount);
            }
            
        }
    }
}

stock players_GiveEquipment(clientIndex, targetEquipment[players_MyWeapons])
{
    new weapons[players_MyWeapons] = {-1, ...};
    
    players_GetWeapons(clientIndex, weapons);
    
    for(new players_MyWeapons:weapon = players_MyWeapon_Knife; weapon <= players_MyWeapon_Incendiary; weapon++)
    {
        player_DeltaEquipItem(clientIndex, weapon, weapons[weapon], targetEquipment[weapon], g_iPlayers_MaxEquipment[weapon]);
    }
}

stock players_GiveWeapons(clientIndex)
{
    weapons_ResetAmmo(clientIndex);
    
    players_GiveSecondary(clientIndex, .noSwitch = true);
    
    players_GivePrimary(clientIndex, .noSwitch = true);
    
    players_GiveEquipment(clientIndex, g_iPlayers_SpawnEquipment);
    
    players_SwitchToBestWeapon(clientIndex);
}

stock players_SwitchToWeaponId(clientIndex, weaponId)
{
    if(players_IsClientValid(clientIndex))
    {
        new bool:IsSecondary;
        if(weapons_IsPrimary(weaponId, IsSecondary))
            g_iPlayers_PrimaryWeapon[clientIndex] = weaponId;
        else if(IsSecondary)
            g_iPlayers_SecondaryWeapon[clientIndex] = weaponId;
        
        if(IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
        {
            if(weapons_IsPrimary(weaponId, IsSecondary))
                players_GivePrimary(clientIndex, .noSwitch = false);
            else if(IsSecondary)
                players_GiveSecondary(clientIndex, .noSwitch = (weapons_GetPrimaryWeaponId(clientIndex) > NO_WEAPON_SELECTED));
        }
    }
}

stock players_SwitchToBestWeapon(clientIndex, excludeEntity=-1)
{
    new activeWeapon = -1;
    new lastActiveWeapon = -1;
    decl slotEntity;
    
    for(new slot = _:SlotC4; slot >= _:SlotPrimary; slot--)
    {
        slotEntity = GetPlayerWeaponSlot(clientIndex, slot);
        
        if( slotEntity != -1 && slotEntity != excludeEntity )
        {
            lastActiveWeapon = activeWeapon;
            activeWeapon = slotEntity;
        }
    }
    
    SetEntData(clientIndex, g_iPlayers_FovOffset, 90);
    SetEntData(clientIndex, g_iPlayers_DefaultFovOffset, 90);
    
    if(activeWeapon > MaxClients)
        SetEntDataEnt2(clientIndex, g_iPlayers_ActiveWeaponOffset, activeWeapon);
        
    if(lastActiveWeapon > MaxClients)
        SetEntDataEnt2(clientIndex, g_iPlayers_LastWeaponOffset, lastActiveWeapon);
        
    if(g_bConfig_FastEquip && activeWeapon > MaxClients)
    {
        decl activeWeaponIndex;
        
        weapons_IsEntityTagged(activeWeapon, activeWeaponIndex);
        
        players_FastSwitch(clientIndex, activeWeaponIndex);
    }
}

stock players_RemoveClientRagdoll(clientIndex)
{
    if (IsValidEdict(clientIndex))
    {
        new ragdoll = GetEntDataEnt2(clientIndex, g_iPlayers_RagdollOffset);
        if (ragdoll != -1)
            AcceptEntityInput(ragdoll, "Kill");
    }
}

stock players_RemoveC4(clientIndex)
{
    new entityIndex;
    while ((entityIndex = GetPlayerWeaponSlot(clientIndex, _:SlotC4)) != -1)
    {
        players_OnWeaponStrippedPre(clientIndex, entityIndex);
        RemovePlayerItem(clientIndex, entityIndex);
        AcceptEntityInput(entityIndex, "Kill");
    }
}

stock players_RemoveClientWeaponSlot(clientIndex, Slots:weaponSlot)
{
    new entityIndex;
    
    while ((entityIndex = GetPlayerWeaponSlot(clientIndex, _:weaponSlot)) != -1)
    {
        players_OnWeaponStrippedPre(clientIndex, entityIndex);
        weapons_RemovePlayerWeapon(entityIndex, clientIndex);
    }
}

stock players_RemoveClientWeapons(clientIndex)
{
    if (players_IsClientValid(clientIndex) && IsPlayerAlive(clientIndex))
    {        
        for (new i = _:SlotPrimary; i < _:SlotNone; i++)
        {
            new entityIndex;
            
            if (Slots:i == SlotC4 && !g_bConfig_RemoveObjectives)
            {
                if((entityIndex = GetPlayerWeaponSlot(clientIndex, i)) != -1)
                    weapons_TagEntity(entityIndex, g_iWeapons_WeaponIndex_C4, clientIndex, .isCT = GetClientTeam(clientIndex) == CS_TEAM_CT);
                
                continue;
            }
            
            new knifeEntity = -1;
            decl String:weaponName[WEAPON_ENTITIES_NAME_SIZE];
            
            while ((entityIndex = GetPlayerWeaponSlot(clientIndex, i)) != -1)
            {
                players_OnWeaponStrippedPre(clientIndex, entityIndex);
                RemovePlayerItem(clientIndex, entityIndex);
                
                if(Slots:i == SlotKnife && g_bConfig_Knife)
                {
                    GetEdictClassname(entityIndex, weaponName, sizeof(weaponName));
                    if(StrEqual(weaponName, "weapon_knife"))
                        knifeEntity = entityIndex;
                    else
                        AcceptEntityInput(entityIndex, "Kill");
                }
                else
                {
                    weapons_RemovePlayerWeapon(entityIndex, clientIndex);
                }
            }
            
            if(Slots:i == SlotKnife && g_bConfig_Knife && knifeEntity > -1)
            {
                weapons_TagEntity(knifeEntity, g_iWeapons_WeaponIndex_Knife, clientIndex, .isCT = GetClientTeam(clientIndex) == CS_TEAM_CT);
                EquipPlayerWeapon(clientIndex, knifeEntity);
            }
        }
    }
}

stock players_RemoveWeaponId(clientIndex, weaponId)
{
    new bool:IsSecondary;
    
    if(!weapons_IsPrimary(weaponId, IsSecondary) && !IsSecondary)
        return;
        
    new weaponEntity = weapons_IsPrimary(weaponId)? weapons_GetPrimaryWeaponEntity(clientIndex) : weapons_GetSecondaryWeaponEntity(clientIndex);
    
    if(players_IsClientValid(clientIndex) && IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
        players_OnWeaponStrippedPre(clientIndex, weaponEntity);
    
    if(!IsFakeClient(clientIndex))
        if(g_iPlayers_PrimaryWeapon[clientIndex] == weaponId)
            g_iPlayers_PrimaryWeapon[clientIndex] = NO_WEAPON_SELECTED;
        else if(g_iPlayers_SecondaryWeapon[clientIndex] == weaponId)
            g_iPlayers_SecondaryWeapon[clientIndex] = NO_WEAPON_SELECTED;
    
    if(weapons_RemovePlayerWeapon(weaponEntity, clientIndex))
        sounds_PlayToClient(clientIndex, SOUNDS_WEAPON_REMOVED);
    
    players_OnWeaponStripped(clientIndex, weaponId, .silent=true);
}

stock players_RewardOnKill(clientIndex, bool:didKnife, bool:didNade, bool:didHeadshot)
{
    new hp = GetClientHealth(clientIndex);
    new kev = GetEntData(clientIndex, g_iPlayers_ArmourOffset);
    new helmet = GetEntData(clientIndex, g_iPlayers_HelmetOffset);
    
    new addHP = 0;
    new addKev = 0;
    new newHP = hp;
    new remHP = 0;
    new newKev = kev;
    new bool:giveHelmet = false;
    
    if (didKnife)
        addHP = g_iConfig_HPPerKnifeKill;
    else if (didHeadshot)
        addHP = g_iConfig_HPPerHeadshotKill;
    else if (didNade)
        addHP = g_iConfig_HPPerNadeKill;
    else
        addHP = g_iConfig_HPPerKill;
    
    newHP += addHP;
    
    if (newHP >= g_iConfig_MaxHP)
    {
        remHP = newHP - g_iConfig_MaxHP;
        newHP = g_iConfig_MaxHP;
    }
    
    if (g_iConfig_HPToKevlarMode == 1)
        addKev = (addHP * g_iConfig_HPToKevlarRatio) / 100;
    else if (g_iConfig_HPToKevlarMode == 2)
        addKev = (remHP * g_iConfig_HPToKevlarRatio) / 100;
    
    newKev += addKev;
    if (newKev >= g_iConfig_MaxKevlar)
    {
        addKev = g_iConfig_MaxKevlar - kev;
        newKev = g_iConfig_MaxKevlar;
    }
    
    if(helmet == 0)
    {
        if(g_iConfig_HPToHelmet == 1)
            giveHelmet = true;
        else if(g_iConfig_HPToHelmet == 2 && newHP >= g_iConfig_MaxHP)
            giveHelmet = true;
        else if(g_iConfig_HPToHelmet == 3 && newHP >= g_iConfig_MaxHP && newKev >= g_iConfig_MaxKevlar)
            giveHelmet = true;
    }
    
    SetEntityHealth(clientIndex, newHP);
    SetEntData(clientIndex, g_iPlayers_ArmourOffset, newKev);
    if (giveHelmet)
        SetEntData(clientIndex, g_iPlayers_HelmetOffset, 1);
    
    if (g_bConfig_DisplayHPMessages)
    {
        decl String:hpStr[50];
        decl String:kevStr[50];
        decl String:helmetStr[50];
        
        if(addHP - remHP > 0)
            Format(hpStr, sizeof(hpStr), " \x04+%iHP\x01", addHP - remHP);
        else
            hpStr[0] = '\0';
        
        if(addKev > 0)
            Format(kevStr, sizeof(kevStr), " \x09+%i %t\x01", addKev, "Kevlar");
        else
            kevStr[0] = '\0';
        
        if(giveHelmet)
            Format(helmetStr, sizeof(helmetStr), " \x0C+%t\x01", "Helmet");
        else
            helmetStr[0] = '\0';
        
        if(hpStr[0] != '\0' || kevStr[0] != '\0' || helmetStr[0] != '\0')
        {
            if (didKnife)
                PrintToChat(clientIndex, "%s%s%s %t %t.", hpStr, kevStr, helmetStr, "for killing an enemy", "with knife");
            else if (didNade)
                PrintToChat(clientIndex, "%s%s%s %t %t.", hpStr, kevStr, helmetStr, "for killing an enemy", "with nade");
            else if (didHeadshot)
                PrintToChat(clientIndex, "%s%s%s %t %t.", hpStr, kevStr, helmetStr, "for killing an enemy", "with headshot");
            else
                PrintToChat(clientIndex, "%s%s%s %t.", hpStr, kevStr, helmetStr, "for killing an enemy");
        }
    }
    
    
    if (
        (
            g_bConfig_ReplenishClip && !g_bConfig_ReplenishClipHS && !g_bConfig_ReplenishClipKnife&& !g_bConfig_ReplenishClipNade ||
            g_bConfig_ReplenishClipHS && didHeadshot ||
            g_bConfig_ReplenishClipKnife && didKnife ||
            g_bConfig_ReplenishClipNade && didNade
        )
       )
    {
        // Immediate refill to avoid reload in case of clip empty
        players_Timer_RefillWeaponsClip(INVALID_HANDLE, clientIndex);
        // Delayed refill to handle the few bullets that may be fired after the kill
        CreateTimer(0.3, players_Timer_RefillWeaponsClip, clientIndex, TIMER_FLAG_NO_MAPCHANGE);
    }
        
    if(g_bPlayers_HasEquipmentReward[players_EquipmentReward_HS] && didHeadshot)
        players_GiveEquipment(clientIndex, g_iPlayers_EquipmentReward[players_EquipmentReward_HS]);
    
    else if(g_bPlayers_HasEquipmentReward[players_EquipmentReward_Knife] && didKnife)
        players_GiveEquipment(clientIndex, g_iPlayers_EquipmentReward[players_EquipmentReward_Knife]);
    
    else if(g_bPlayers_HasEquipmentReward[players_EquipmentReward_Nade] && didNade)
        players_GiveEquipment(clientIndex, g_iPlayers_EquipmentReward[players_EquipmentReward_Nade]);
    
    else if(g_bPlayers_HasEquipmentReward[players_EquipmentReward_Kill])
        players_GiveEquipment(clientIndex, g_iPlayers_EquipmentReward[players_EquipmentReward_Kill]);
        
}

public Action:players_Timer_RefillWeaponsClip(Handle:timer, any:clientIndex)
{
    decl weaponEntity;

    if(players_IsClientValid(clientIndex) && IsPlayerAlive(clientIndex))
    {
        weaponEntity = GetPlayerWeaponSlot(clientIndex, _:SlotPrimary);
        if (weaponEntity != -1)
            weapons_RefillClip(EntIndexToEntRef(weaponEntity), weapons_GetPrimaryWeaponId(clientIndex));
        
        weaponEntity = GetPlayerWeaponSlot(clientIndex, _:SlotSecondary);
        if (weaponEntity != -1)
            weapons_RefillClip(EntIndexToEntRef(weaponEntity), weapons_GetSecondaryWeaponId(clientIndex));
    }
}

stock players_OnClientSwitchTeam(clientIndex, oldTeam, newTeam)
{
    if (players_IsClientValid(clientIndex))
    {
        menus_OnClientSwitchTeam(clientIndex);
        players_RemoveClientRagdoll(clientIndex);
        weapons_PlayerSwitchTeam(clientIndex, oldTeam, newTeam);
    }
}

stock bool:players_ShouldAdvertiseGunMenu(clientIndex)
{
    return  players_IsClientValid(clientIndex) && 
            !IsFakeClient(clientIndex) &&
            Teams:GetClientTeam(clientIndex) > TeamSpectator &&
            !g_bPlayers_FirstWeaponSelection[clientIndex] &&
            g_iConfig_GunMenuMode == 1;
}

public Action:players_Timer_SetSpawnProps(Handle:timer, any:clientRef)
{
    new clientIndex = EntRefToEntIndex(clientRef);
    
    if (players_IsClientValid(clientIndex) && IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
    {
        SetEntityHealth(clientIndex, g_iConfig_StartHP);
        
        SetEntData(clientIndex, g_iPlayers_ArmourOffset, g_iConfig_StartKevlar);
        
        if (g_bConfig_Helmet)
            SetEntData(clientIndex, g_iPlayers_HelmetOffset, 1);
        else
            SetEntData(clientIndex, g_iPlayers_HelmetOffset, 0);
        
        if (g_bConfig_Defuser && GetClientTeam(clientIndex) == CS_TEAM_CT)
            SetEntData(clientIndex, g_iPlayers_DefuserOffset, 1);
        else
            SetEntData(clientIndex, g_iPlayers_DefuserOffset, 0);
        
        if (g_bConfig_HideRadar)
            SetEntProp(clientIndex, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
        
        spawns_SetEditorModeProps(clientIndex);
    }
}

stock players_SetSpawnProps(clientIndex)
{
    CreateTimer(0.1, players_Timer_SetSpawnProps, EntIndexToEntRef(clientIndex));
    
    players_RemoveClientWeapons(clientIndex);
    players_GiveWeapons(clientIndex);
}

stock players_SetSpawnOffset(clientIndex)
{
    decl Float:position[3];
    
    GetClientAbsOrigin(clientIndex, position);
    position[2] += 2.0;
    
    TeleportEntity(clientIndex, position, NULL_VECTOR, NULL_VECTOR);
}

stock players_Fade(clientIndex)
{
    new color[4] = { 0, 0, 0, 230 };

    new Handle:message = StartMessageOne("Fade", clientIndex, USERMSG_RELIABLE);
    PbSetInt(message, "duration", 1000);
    PbSetInt(message, "hold_time", 0);
    PbSetInt(message, "flags", 0x0001 | 0x0008);
    PbSetColor(message, "clr", color);
    EndMessage();
}

stock players_OnClientSpawn(clientIndex)
{
    if (players_IsClientValid(clientIndex) && GetClientTeam(clientIndex) > CS_TEAM_SPECTATOR)
    {
        g_bPlayers_PrimaryChosenThisRound[clientIndex] = false;
        g_bPlayers_SecondaryChosenThisRound[clientIndex] = false;
        
        players_SetSpawnProps(clientIndex);
        
        players_SetSpawnOffset(clientIndex);
        
        players_Fade(clientIndex);
        
        sounds_PlayToAll(SOUNDS_SPAWN, .entity=clientIndex, .level=SNDLEVEL_GUNFIRE);
        
        if (g_bPlayers_FirstWeaponSelection[clientIndex])
        {
            menus_OnClientSpawn(clientIndex);
            g_bPlayers_FirstWeaponSelection[clientIndex] = false;
        }
        menusFifo_OnClientSpawn(clientIndex);
    }
}

stock players_OnClientConnected(clientIndex)
{
    players_ResetClientSettings(clientIndex);
}

stock players_OnClientDisconnect(clientIndex)
{
    weapons_OnClientDisconnect(clientIndex);
}

stock players_OnPrimarySelected(clientIndex, weaponId)
{
    if (players_IsClientValid(clientIndex))
    {
        if (weaponId != NO_WEAPON_SELECTED)
        {
            g_iPlayers_PrimaryWeapon[clientIndex] = weaponId;
            
            if (g_bPlayers_PrimaryChosenThisRound[clientIndex])
                PrintToChat(clientIndex, " \x01\x0B\x07%t.", "You'll get your new weapons on next spawn");
            
            else
            {
                g_bPlayers_PrimaryChosenThisRound[clientIndex] = true;
                
                players_GivePrimary(clientIndex, .noSwitch = false);
            }
        }
    }
}

stock players_OnSecondarySelected(clientIndex, weaponId)
{
    if (players_IsClientValid(clientIndex))
    {
        if (weaponId != NO_WEAPON_SELECTED)
        {
            g_iPlayers_SecondaryWeapon[clientIndex] = weaponId;
            
            if (g_bPlayers_SecondaryChosenThisRound[clientIndex])
                PrintToChat(clientIndex, " \x01\x0B\x07%t.", "You'll get your new weapons on next spawn");
            
            else
            {
                g_bPlayers_SecondaryChosenThisRound[clientIndex] = true;
                
                players_GiveSecondary(clientIndex, .noSwitch = (weapons_GetPrimaryWeaponId(clientIndex) > NO_WEAPON_SELECTED));
            }
        }
    }
}

stock players_OnDeathEvent(clientIndex)
{
    if(!players_IsClientValid(clientIndex))
        return;
    
    weapons_OnClientDeath(clientIndex);
}

stock players_OnkillEvent(clientIndex, Handle:event)
{
    if (players_IsClientValid(clientIndex))
    {
        decl String:attackerWeapon[10];
        GetEventString(event, "weapon", attackerWeapon, sizeof(attackerWeapon));
    
        new bool:knife = StrPartEqual(attackerWeapon, "knife");
        new bool:nade = StrEqual(attackerWeapon, "hegrenade");
        new bool:headshot = GetEventBool(event, "headshot"); 
                
        players_RewardOnKill(clientIndex, knife, nade, headshot);        
    }
}

stock players_OnWeaponStrippedPre(clientIndex, entity)
{
    players_SwitchToBestWeapon(clientIndex, .excludeEntity = entity);
}

stock players_OnWeaponStripped(clientIndex, weaponId, bool:silent=false)
{
    new bool:IsSecondary;
    if( 
        weapons_IsPrimary(weaponId, IsSecondary) &&
        (
            g_iPlayers_PrimaryWeapon[clientIndex] == RANDOM_WEAPON_SELECTED ||
            (
                g_iPlayers_PrimaryWeapon[clientIndex] != weaponId &&
                g_iPlayers_PrimaryWeapon[clientIndex] != NO_WEAPON_SELECTED
            )
        )
      )
    {
        players_GivePrimary(clientIndex, .noSwitch = false);
    }
    else if (
        IsSecondary && 
        (
            g_iPlayers_SecondaryWeapon[clientIndex] == RANDOM_WEAPON_SELECTED ||
            (
                g_iPlayers_SecondaryWeapon[clientIndex] != weaponId &&
                g_iPlayers_SecondaryWeapon[clientIndex] != NO_WEAPON_SELECTED
            )
        )
      )
    {
        players_GiveSecondary(clientIndex, .noSwitch = false);
    }
    else
    {
        if(weapons_IsPrimary(weaponId, IsSecondary))
            g_bPlayers_PrimaryChosenThisRound[clientIndex] = false;
        else if(IsSecondary)
            g_bPlayers_SecondaryChosenThisRound[clientIndex] = false;
        
        if(players_IsClientValid(clientIndex) && IsClientInGame(clientIndex))
        {
            if(!silent)
                sounds_PlayToClient(clientIndex, SOUNDS_WEAPON_FORBIDEN);
            menus_OnWeaponStripped(clientIndex, weapons_IsPrimary(weaponId));
        }
    }
}