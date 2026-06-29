#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include "include/morecolors.inc"

#define HUDTICK     1.2

static Level1[MAXPLAYERS + 1];

public Plugin myinfo = {
    name = "GunGame HL2DM",
    author = "Remade using Dezz420_'s GunGame code by CaptainZero93",
    description = "GunGame mod for HL2DM with stock weapons",
    version = "1.1",
    url = ""
};

//Initation:
public OnPluginStart() {
    LoadTranslations("common.phrases");
    
    //Events:
    HookEvent("player_death", EventDeath);
    HookEvent("player_spawn", EventSpawn, EventHookMode_Pre);
    CreateTimer(1.0, Clearweapons);
}

public OnClientPostAdminCheck(client) 
{
    Level1[client] = 0;
    CreateTimer(HUDTICK, DisplayHud, client);
}

//Spawn:
public Action EventSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    CreateTimer(0.1, RemoveWeapons, client);
    CreateTimer(0.4, GunGameWeapons, client);
    
    return Plugin_Continue;
}

//Remove Weapons:
public Action RemoveWeapons(Handle timer, any client)
{
    if(!IsValidClient(client)) return Plugin_Continue;

    int offset = FindSendPropInfo("CHL2MP_Player", "m_hMyWeapons");
    int maxGuns = (Level1[client] < 100) ? 20 : 0;
    
    for(int x = 0; x < maxGuns; x += 4)
    {
        int weaponId = GetEntDataEnt2(client, offset + x);
        
        if(weaponId > 0)
        {
            char weaponClass[32];
            GetEdictClassname(weaponId, weaponClass, sizeof(weaponClass));
            
            // Skip removing the gravity gun
            if(!StrEqual(weaponClass, "weapon_physcannon", false))
            {
                RemovePlayerItem(client, weaponId);
                RemoveEdict(weaponId);
            }
        }
    }
    return Plugin_Continue;
}

public Action GunGameWeapons(Handle timer, any client)
{
   if(!IsValidClient(client)) return Plugin_Continue;

   char primaryWeapon[32];
   switch(Level1[client])
   {
       case 0: // Level 1
       {
           primaryWeapon = "weapon_smg1";
           GivePlayerItem(client, "weapon_crowbar");      
           GivePlayerItem(client, "weapon_physcannon");   
           int weapon = GivePlayerItem(client, primaryWeapon);  
           if(weapon != -1)                                     
           {
               SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
           }
       }
       case 2: // Level 2
       {
           primaryWeapon = "weapon_ar2";
           GivePlayerItem(client, "weapon_crowbar");
           GivePlayerItem(client, "weapon_physcannon");
           int weapon = GivePlayerItem(client, primaryWeapon);
           if(weapon != -1)
           {
               SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
           }
       }
       case 3: // Level 3
       {
           primaryWeapon = "weapon_shotgun";
           GivePlayerItem(client, "weapon_crowbar");
           GivePlayerItem(client, "weapon_physcannon");
           int weapon = GivePlayerItem(client, primaryWeapon);
           if(weapon != -1)
           {
               SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
           }
       }
       case 4: // Level 4
       {
           primaryWeapon = "weapon_357";
           GivePlayerItem(client, "weapon_crowbar");
           GivePlayerItem(client, "weapon_physcannon");
           int weapon = GivePlayerItem(client, primaryWeapon);
           if(weapon != -1)
           {
               SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
           }
       }
       case 5: // Level 5
       {
           primaryWeapon = "weapon_crossbow";
           GivePlayerItem(client, "weapon_crowbar");
           GivePlayerItem(client, "weapon_physcannon");
           int weapon = GivePlayerItem(client, primaryWeapon);
           if(weapon != -1)
           {
               SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
           }
       }
       case 6: // Level 6
       {
           primaryWeapon = "weapon_rpg";
           GivePlayerItem(client, "weapon_crowbar");
           GivePlayerItem(client, "weapon_physcannon");
           int weapon = GivePlayerItem(client, primaryWeapon);
           if(weapon != -1)
           {
               SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
           }
       }
       case 7: // Level 7
       {
           primaryWeapon = "weapon_pistol";
           GivePlayerItem(client, "weapon_crowbar");
           GivePlayerItem(client, "weapon_physcannon");
           int weapon = GivePlayerItem(client, primaryWeapon);
           if(weapon != -1)
           {
               SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
           }
       }
       case 8: // Level 8 (Final)
       {
           primaryWeapon = "weapon_stunstick";
           GivePlayerItem(client, "weapon_physcannon");
           int weapon = GivePlayerItem(client, primaryWeapon);
           if(weapon != -1)
           {
               SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
           }
       }
   }
   
   // Double-check weapon selection
   CreateTimer(0.1, ForceSwitchToPrimary, client);
   return Plugin_Continue;
}

public Action ForceSwitchToPrimary(Handle timer, any client)
{
    if(!IsValidClient(client)) return Plugin_Continue;
    
    char primaryWeapon[32];
    switch(Level1[client])
    {
        case 0: primaryWeapon = "weapon_smg1";
        case 2: primaryWeapon = "weapon_ar2";
        case 3: primaryWeapon = "weapon_shotgun";
        case 4: primaryWeapon = "weapon_357";
        case 5: primaryWeapon = "weapon_crossbow";
        case 6: primaryWeapon = "weapon_rpg";
        case 7: primaryWeapon = "weapon_pistol";
        case 8: primaryWeapon = "weapon_stunstick";
    }
    
    FakeClientCommand(client, "use %s", primaryWeapon);
    return Plugin_Continue;
}

public Action WonRound(Handle timer, any client)
{
    for(int i = 1; i <= MaxClients; i++)
    {   
        if(IsClientInGame(i))
        {
            Level1[i] = 0;
        }
    }
    CreateTimer(1.0, mapboot2);
    return Plugin_Continue;
}

public Action DisplayHud(Handle timer, any client)
{
    if(IsClientConnected(client) && IsClientInGame(client))
    {
        char levelDisplay[8];
        IntToString(Level1[client] == 0 ? 1 : Level1[client], levelDisplay, sizeof(levelDisplay));

        SetHudTextParams(0.015, 0.015, HUDTICK, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
        ShowHudText(client, -1, "|GunGame|\n|Level %s| \n|Info| \n|Beat Level 8|\n|to Win|", levelDisplay);     
        
        CreateTimer(HUDTICK, DisplayHud, client);
    }
    return Plugin_Continue;
}

public Action mapboot2(Handle timer) {
    CPrintToChatAll("{green}[GunGame]{default}Next Game in");
    CPrintToChatAll("{green}[GunGame]{green}-[5]-");
    CreateTimer(1.0, mapboot428);
    for(int i = 1; i <= MaxClients; i++)
    {   
        if(IsClientInGame(i))
        {
            ClientCommand(i, "play 5.wav");
        }
    }
    return Plugin_Continue;
}

public Action mapboot428(Handle timer) {
    CPrintToChatAll("{green}[GunGame]{green}-[4]-");
    CreateTimer(1.0, mapboot429);
    for(int i = 1; i <= MaxClients; i++)
    {   
        if(IsClientInGame(i))
        {
            ClientCommand(i, "play 4.wav");
        }
    }
    return Plugin_Continue;
}

public Action mapboot429(Handle timer) {
    CPrintToChatAll("{green}[GunGame]{green}-[3]-");
    CreateTimer(1.0, mapboot430);
    for(int i = 1; i <= MaxClients; i++)
    {   
        if(IsClientInGame(i))
        {
            ClientCommand(i, "play 3.wav");
        }
    }
    return Plugin_Continue;
}

public Action mapboot430(Handle timer) {
    CPrintToChatAll("{green}[GunGame]{green}-[2]-");
    CreateTimer(1.0, mapboot431);
    for(int i = 1; i <= MaxClients; i++)
    {   
        if(IsClientInGame(i))
        {
            ClientCommand(i, "play 2.wav");
        }
    }
    return Plugin_Continue;
}

public Action mapboot431(Handle timer) {
    CPrintToChatAll("{green}[GunGame]{green}-[1]-");
    CreateTimer(1.0, mapboot433);
    for(int i = 1; i <= MaxClients; i++)
    {   
        if(IsClientInGame(i))
        {
            ClientCommand(i, "play 1.wav");
        }
    }
    return Plugin_Continue;
}

public Action mapboot433(Handle timer) {
    ServerCommand("sm_slay @all");
    ServerCommand("sm_say NEXT Round STARTS NOW!!!!");
    ServerCommand("sm_say NEXT Round STARTS NOW!!!!");
    ServerCommand("sm_say NEXT Round STARTS NOW!!!!");
    return Plugin_Continue;
}

public Action EventDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if(!IsValidClient(client) || !IsValidClient(attacker) || attacker == client)
    {
        return Plugin_Continue;
    }

    char weaponName[32];
    GetClientWeapon(attacker, weaponName, sizeof(weaponName));
    
    char clientName[32], attackerName[32];
    GetClientName(client, clientName, sizeof(clientName));
    GetClientName(attacker, attackerName, sizeof(attackerName));

    CreateTimer(0.001, Clearweapons3);
    
    if(StrEqual(weaponName, "weapon_crowbar", false))
    {
        ProcessHumiliation(client, attacker, clientName, attackerName);
    }
    else
    {
        ProcessWeaponKill(attacker, weaponName, attackerName);
    }

    return Plugin_Continue;
}

void ProcessHumiliation(int client, int attacker, const char[] clientName, const char[] attackerName)
{
    if(Level1[client] >= 2 && Level1[client] <= 8)
    {
        Level1[client]--;
        PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 humiliated \x04%s\x04\x01", attackerName, clientName);
        CreateTimer(0.1, RemoveWeapons, client);
        CreateTimer(0.5, GunGameWeapons, client);
        
        for(int i = 1; i <= MaxClients; i++)
        {   
            if(IsClientInGame(i))
            {
                ClientCommand(i, "play humiliation.mp3");
            }
        }
    }
}

bool ProcessWeaponKill(int attacker, const char[] weaponName, const char[] attackerName)
{
    bool levelUp = false;
    
    if(Level1[attacker] == 0 && StrEqual(weaponName, "weapon_smg1", false))
    {
        Level1[attacker] = 2;
        levelUp = true;
    }
    else if(Level1[attacker] == 2 && StrEqual(weaponName, "weapon_ar2", false))
    {
        Level1[attacker]++;
        levelUp = true;
    }
    else if(Level1[attacker] == 3 && StrEqual(weaponName, "weapon_shotgun", false))
    {
        Level1[attacker]++;
        levelUp = true;
    }
    else if(Level1[attacker] == 4 && StrEqual(weaponName, "weapon_357", false))
    {
        Level1[attacker]++;
        levelUp = true;
    }
    else if(Level1[attacker] == 5 && StrEqual(weaponName, "weapon_crossbow", false))
    {
        Level1[attacker]++;
        levelUp = true;
    }
    else if(Level1[attacker] == 6 && StrEqual(weaponName, "weapon_rpg", false))
    {
        Level1[attacker]++;
        levelUp = true;
    }
    else if(Level1[attacker] == 7 && StrEqual(weaponName, "weapon_pistol", false))
    {
        Level1[attacker]++;
        levelUp = true;
    }
    else if(Level1[attacker] == 8 && StrEqual(weaponName, "weapon_stunstick", false))
    {
        Level1[attacker]++;
        PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 has won this Round", attackerName);
        PrintCenterTextAll("%s won the Round", attackerName);
        ClientCommand(attacker, "play winner.wav");
        CreateTimer(0.001, WonRound, attacker);
        return true;
    }
    
    if(levelUp)
    {
        PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now on Level \x04%d\x04\x01", attackerName, Level1[attacker]);
        ClientCommand(attacker, "play buttons/blip1.wav");
        CreateTimer(0.1, RemoveWeapons, attacker);
        CreateTimer(0.5, GunGameWeapons, attacker);
    }
    
    return levelUp;
}

stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsRevolverModel(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/weapons/w_357.mdl", false);
}

stock bool IsCrossbowModel(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/weapons/w_crossbow.mdl", false);
}

stock bool IsAr2Model(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/Weapons/w_IRifle.mdl", false);
}

stock bool IsCrowbarModel(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/Weapons/w_crowbar.mdl", false);
}

stock bool IsRpgModel(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/Weapons/w_rocket_launcher.mdl", false);
}

stock bool IsShotgunModel(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/Weapons/w_shotgun.mdl", false);
}

stock bool IsPistolModel(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/Weapons/W_pistol.mdl", false);
}

stock bool IsSmgModel(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/Weapons/w_smg1.mdl", false);
}

stock bool IsStunStickModel(int ent) {
    char model[128];
    GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
    return StrEqual(model, "models/Weapons/w_stunbaton.mdl", false);
}

stock bool IsGravityGun(int ent) {
    char classname[32];
    GetEdictClassname(ent, classname, sizeof(classname));
    return StrEqual(classname, "weapon_physcannon", false);
}

public Action Clearweapons(Handle timer) {
    for (int x = 0; x < 4028; x++) {
        if(IsValidEntity(x)) {
            if(!IsGravityGun(x) && (IsSmgModel(x) || IsPistolModel(x) || IsShotgunModel(x) || IsRpgModel(x) || 
               IsAr2Model(x) || IsRevolverModel(x) || IsCrossbowModel(x) ||
               IsStunStickModel(x))) {
                AcceptEntityInput(x, "Kill");
                CreateTimer(20.0, Clearweapons1);
                break;
            }
        }
    }
    return Plugin_Continue;
}

public Action Clearweapons1(Handle timer) {
    for (int x = 0; x < 4028; x++) {
        if(IsValidEntity(x)) {
            if(!IsGravityGun(x) && (IsSmgModel(x) || IsPistolModel(x) || IsShotgunModel(x) || IsRpgModel(x) || 
               IsAr2Model(x) || IsRevolverModel(x) || IsCrossbowModel(x) ||
               IsStunStickModel(x))) {
                AcceptEntityInput(x, "Kill");
                CreateTimer(20.0, Clearweapons);
                break;
            }
        }
    }
    return Plugin_Continue;
}

public Action Clearweapons3(Handle timer) {
    for (int x = 0; x < 4028; x++) {
        if(IsValidEntity(x)) {
            if(!IsGravityGun(x) && (IsSmgModel(x) || IsPistolModel(x) || IsShotgunModel(x) || IsRpgModel(x) || 
               IsAr2Model(x) || IsRevolverModel(x) || IsCrossbowModel(x) ||
               IsStunStickModel(x))) {
                AcceptEntityInput(x, "Kill");
            }
        }
    }
    return Plugin_Continue;
}
