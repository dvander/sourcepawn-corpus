#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

public Plugin:myinfo =
{
    name = "Super Moce",
    author = "xBBBay & Shibby (Poprawa Kodu)",
    description = "Dodaje losowe moce na poczatku rundy",
    version = "2.1",
    url = "http://steamcommunity.com/id/shibbypg"
};

new String:nazwa_gracza[65][65];

#define MAX_PLAYERS 32 //ilosc slotow
#define ILOSC_SUPERMOCY 17
#define ILOSC_SUPERMOCYFUNKCJA ILOSC_SUPERMOCY+1

new SuperMoc[MAX_PLAYERS+1];
new Float:obrazenia[MAX_PLAYERS+1], Float:wytrzymalosc[MAX_PLAYERS+1];
new Laser;
new g_LaserModel;
new g_HaloModel;
new sprite_blue;

new g_iMyWeaponsMax = 63; 

new freeze_time;
Handle DajMocTimers[MAXPLAYERS+1];

new C4TimerON, C4Timer;

new    g_iJumps[MAXPLAYERS+1]
new    g_iJumpMax
new    g_fLastButtons[MAXPLAYERS+1]
new    g_fLastFlags[MAXPLAYERS+1]
new clientlevel[MAXPLAYERS+1]
new    Handle:g_cvJumpBoost = INVALID_HANDLE
new    Handle:g_cvJumpMax = INVALID_HANDLE
new Handle:g_cvJumpKnife = INVALID_HANDLE
new    Float:g_flBoost    = 250.0

new String:modele_serwera[][] =
{
    "", // 0
    "models/player/ctm_fbi.mdl", // 1
    "models/player/ctm_gign.mdl", // 2
    "models/player/ctm_gsg9.mdl", // 3
    "models/player/ctm_sas.mdl", // 4
    "models/player/ctm_st6.mdl", // 5
    "models/player/tm_anarchist.mdl", // 6
    "models/player/tm_phoenix.mdl", // 7
    "models/player/tm_pirate.mdl", // 8
};

new String:SuperMocNazwy[ILOSC_SUPERMOCYFUNKCJA][] =
{
    {""}, //0
    {"kazde trafienie zabija"}, //1
    {"Tank"}, //2
    {"Wampir"}, //3
    {"Wallhack"}, //4
    {"Ninja"}, //5
    {"Grawitacja"}, //6
    {"Kamienna skora"}, //7
    {"Super predkosc"}, //8
    {"Nieskonczona amunicja"}, //9
    {"Medyk"}, //10
    {"Kameleon"}, //11
    {"Nozownik"}, //12
    {"Szybkostrzelnosc"}, //13
    {"Bogacz"}, //14
    {"Boomer"}, //15
    {"Jumper"}, //16
    {"Morfina"} //17
};
new String:SuperMocOpisy[ILOSC_SUPERMOCYFUNKCJA][] =
{
    {""},
    {"+1000 DMG z kazdej broni"},
    {"Dostajesz +1000HP"},
    {"Gdy zadajesz dmg przeciwnikowi, dostajesz dodatkowe hp"},
    {"Posiadasz wallhacka, czerwona linia wskaze przeciwnikow"},
    {"30% widocznosci"},
    {"Zmniejszona grawitacja"},
    {"-75% otrzymanych obrazen"},
    {"2.5 raza szybsze chodzenie"},
    {"Amunicja nigdy sie nie konczy"},
    {"4 Apteczki, mozesz leczyc czlownkow swojej druzyny strzelajac w nich"},
    {"Posiadasz ubranie wroga"},
    {"Natychmiastowe zabicie z noza"},
    {"Szybciej strzelasz"},
    {"+16000$"},
    {"Po smierci wybuchasz, zabijasz przeciwnikow obok siebie"},
    {"Posiadasz +10 dodatkowych skokow"},
    {"Posiadasz 1/8 szans na ponowne odrodzenie po smierci"}
};


public OnPluginStart()
{
    CreateConVar("Super Moce", "2.0", "xBBBay");
    
    CreateTimer(0.1, UpdateLine, 0, 1);
    CreateTimer(5.0, SetCvars, 0, 1);
    
    Laser = -1;
    
    HookEvent("weapon_fire",  EventWeaponFire);
    HookEvent("player_spawn", PlayerSpawn);
    HookEvent("player_death", PlayerDeath);
    
    HookEvent("round_freeze_end", PoczatekRundy);
    HookEvent("round_start", NowaRunda);
    HookEvent("bomb_planted", BombaPodlozona);
    HookEvent("bomb_defused", BombaRozbrojona);
    
    RegConsoleCmd("sm_test", Command_TEST);
    
    CreateConVar("csgo_doublejump_version", "2.0", "CS:GO Double Jump Version")
    g_cvJumpKnife = CreateConVar("csgo_doublejump_knife", "0",    "disable(0) / enable(1) double-jumping only on Knife Level for AR (GunGame)")
    g_cvJumpBoost = CreateConVar("csgo_doublejump_boost", "300.0", "The amount of vertical boost to apply to double jumps")
    g_cvJumpMax = CreateConVar("csgo_doublejump_max", "10", "The maximum number of re-jumps allowed while already jumping")
    AutoExecConfig(true, "csgo_doublejump", "csgo_doublejump")
    
    HookConVarChange(g_cvJumpBoost,        convar_ChangeBoost)
    HookConVarChange(g_cvJumpMax,        convar_ChangeMax)
    g_flBoost        = GetConVarFloat(g_cvJumpBoost)
    g_iJumpMax        = GetConVarInt(g_cvJumpMax)
    HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
}
public OnMapStart()
{
    for(new i = 1; i < sizeof modele_serwera; i ++)
               
    g_LaserModel = PrecacheModel("sprites/laserbeam.vmt", true);
    g_HaloModel = PrecacheModel("sprites/glow01.vmt", true);
    sprite_blue = PrecacheModel("materials/sprites/blueflare1.vmt");
}
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_PreThink, Prethink);
    SDKHook(client, SDKHook_OnTakeDamage, TakeDamage);
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost)
    GetClientName(client, nazwa_gracza[client], 64); 
}
public OnClientDisconnect(client)
{
    SDKUnhook(client, SDKHook_PreThink, Prethink);
    SDKUnhook(client, SDKHook_OnTakeDamage, TakeDamage);
    SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost)
}
public Action:TakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if(!IsValidClient(victim))
        return Plugin_Continue;

    if(IsValidClient(attacker) && GetClientTeam(victim) != GetClientTeam(attacker))
    {
        new dmg = 0;
        
        new String:weapon[32];
        GetClientWeapon(attacker, weapon, sizeof(weapon));
        
        if(SuperMoc[attacker] == 12)
        {
            if(StrEqual(weapon, "weapon_knife") && damagetype & DMG_SLASH)
            {
                dmg += GetClientHealth(victim)+1;
            }
        }
        
        damage = RoundFloat(damage+dmg)+(obrazenia[attacker]-wytrzymalosc[victim]);
    
        return Plugin_Changed;
    }
    if (IsValidClient(attacker) && IsValidClient(victim) && GetClientTeam(attacker) == GetClientTeam(victim))
    {
        if(SuperMoc[attacker] == 10)
        {
            if(SuperMoc[victim] == 2)
            {
            
            }
            else
            {
                if (GetClientHealth(victim) < 100)
                {
                    new ClientHealth = GetClientHealth(victim);
                    SetClientHealth(victim, ClientHealth + RoundFloat(damage * 0.2));
                }
                if (GetClientHealth(victim) > 100)
                {
                    SetClientHealth(victim, 100);
                }
                damagetype = -1;
                damage = 0.0;
            }
        }
    }
    if (IsValidClient(attacker) && IsValidClient(victim) && GetClientTeam(attacker) != GetClientTeam(victim))
    {
        if(SuperMoc[attacker] == 3)
        {
            new ClientHealth = GetClientHealth(attacker);
            SetClientHealth(attacker, ClientHealth + RoundFloat(damage * 0.2));
        }
    }
    return Plugin_Continue;
}
SetClientHealth(client, amount)
{
    new HealthOffs = FindDataMapInfo(client, "m_iHealth");
    SetEntData(client, HealthOffs, amount, true);
}
public Action:NowaRunda(Handle:event_newround, const String:name[],bool:dontBroadcast)
{
    freeze_time = 1;
}
public Action:PoczatekRundy(Handle:event_freezetime, const String:name[], bool:dontBroadcast)
{
    C4TimerON = 0;
    freeze_time = 0;
}
public Action:Prethink(client)
{
    if(!IsValidClient(client) || IsFakeClient(client))
        return Plugin_Continue;

    if(IsPlayerAlive(client))
    {
        if(freeze_time == 0)
        {
            if(C4TimerON == 0)
            {
                PrintHintText(client, "<font size='16'><font color='#006699'>[4FUN]</font>\n<font color='#666699'>Super Moc:</font> <b>%s</b>\n<font color='#666699'>Opis Super Mocy:</font> <b>%s</b></font>", SuperMocNazwy[SuperMoc[client]], SuperMocOpisy[SuperMoc[client]]);
            }
            
            if(C4TimerON == 1)
            {
                if(C4Timer > 0)
                {
                    PrintHintText(client, "<font size='16'><font color='#006699'>[4FUN]</font>\n<font color='#666699'>Super Moc:</font> <b>%s</b>\n<font color='#666699'>Bomba została podłożona\nCzas do wybuchu:</font> <b>%ds</b></font>", SuperMocNazwy[SuperMoc[client]], C4Timer);
                }
                if(C4Timer < 1)
                {
                    PrintHintText(client, "<font size='16'><font color='#006699'>[4FUN]</font>\n<font color='#666699'>Super Moc:</font> <b>%s</b>\n<font color='#666699'>Bomba eksplodowała</font></font>", SuperMocNazwy[SuperMoc[client]]);
                }
            }
            if(C4TimerON == 2)
            {
                PrintHintText(client, "<font size='16'><font color='#006699'>[4FUN]</font>\n<font color='#666699'>Super Moc:</font> <b>%s</b>\n\n<font color='#666699'>Bomba została rozbrojona", SuperMocNazwy[SuperMoc[client]]);
            }
            
            switch(SuperMoc[client])
            {
                case 0: Odrodzenie(client);
                case ILOSC_SUPERMOCYFUNKCJA: Odrodzenie(client);
            }
        }
        if(freeze_time == 1)
        {
            new c1;
            new c2;
            new c3;
            new c4;
            new c5;
            new c6;
            c1 = GetRandomInt(0, 9);
            c2 = GetRandomInt(0, 9);
            c3 = GetRandomInt(0, 9);
            c4 = GetRandomInt(0, 9);
            c5 = GetRandomInt(0, 9);
            c6 = GetRandomInt(0, 9);
            PrintHintText(client, "<font size='36'>   LOSOWANIE</font><br><font size='20' color='#%d%d%d%d%d%d'>             SUPER MOCY</font>", c1, c2, c3, c4, c5, c6);
                
            switch(SuperMoc[client])
            {
                case 0: Odrodzenie(client);
                case ILOSC_SUPERMOCYFUNKCJA: Odrodzenie(client);
            }
        }
        
        if(SuperMoc[client] == 13)
        {
            new Float:flNextPrimaryAttack = GetEntDataFloat(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack"))-GetGameTime();
            SetEntDataFloat(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack"), (flNextPrimaryAttack/1.2)+GetGameTime());
        }
    }
    else
    {
        new spect = GetEntProp(client, Prop_Send, "m_iObserverMode");
        if(spect == 4 || spect == 5) 
        {
            new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
            if(!(target == -1) && IsValidClient(target))
            {
                if(freeze_time == 0)
                {
                    PrintHintText(client, "<font size='16'><font color='#006699'>[4FUN] - <b>%s</b></font>\n<font color='#666699'>Super Moc:</font> <b>%s</b></font>", nazwa_gracza[target], SuperMocNazwy[SuperMoc[target]]);
                }
                if(freeze_time == 1)
                {
                    new c1;
                    new c2;
                    new c3;
                    new c4;
                    new c5;
                    new c6;
                    c1 = GetRandomInt(0, 9);
                    c2 = GetRandomInt(0, 9);
                    c3 = GetRandomInt(0, 9);
                    c4 = GetRandomInt(0, 9);
                    c5 = GetRandomInt(0, 9);
                    c6 = GetRandomInt(0, 9);
                    PrintHintText(client, "<font size='36'>   LOSOWANIE</font><br><font size='20' color='#%d%d%d%d%d%d'>             SUPER MOCY</font>", c1, c2, c3, c4, c5, c6);
                }
            }
        }
    }

    return Plugin_Continue;
}
public Action:PlayerSpawn(Handle:event_spawn, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event_spawn, "userid"));
    if(!IsValidClient(client) || IsFakeClient(client))
        return;

    Odrodzenie(client);
}
public Action:Command_TEST(client, args)
{
    if(GetUserFlagBits(client) & ADMFLAG_ROOT)
    {
        Odrodzenie(client);
    }
    return Plugin_Handled;
}
public Action:Odrodzenie(client)
{
    if(!IsValidClient(client) || !IsPlayerAlive(client))
        return;
    
    CS_UpdateClientModel(client);
    SetEntityHealth(client, 100);
    SetEntityRenderMode(client, RENDER_TRANSCOLOR);
    SetEntityRenderColor(client, 255, 255, 255, 255);
    obrazenia[client] = 0.0;
    wytrzymalosc[client] = 0.0;
    SetEntityGravity(client, 1.0);
    SetClientSpeed(client, 1.0);
    Laser = -1;
    SetEntityModel(client, (GetClientTeam(client) == CS_TEAM_CT)? modele_serwera[GetRandomInt(1, 5)]: modele_serwera[GetRandomInt(6, 10)]);
    
    for(new x = 0; x <= g_iMyWeaponsMax; x++) 
    { 
        new index = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", x); 
        if(index && IsValidEdict(index)) 
        { 
            new String:classname[64]; 
            GetEdictClassname(index, classname, sizeof(classname)); 
            if(StrEqual("weapon_healthshot", classname)) 
            { 
                RemoveWeaponDrop(client, index); 
            }
        } 
    } 
    
    new randomnum = GetRandomInt(1, ILOSC_SUPERMOCY);
    
    SuperMoc[client] = randomnum;
    
    DajMocTimers[client] = CreateTimer(5.0, DajMoc, client, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:DajMoc(Handle:timer, any:client)
{
    if(!IsValidClient(client))
        return;
        
    switch(SuperMoc[client])
    {
        case 1: obrazenia[client] = 1000.0;
        case 2: SetEntData(client, FindDataMapInfo(client, "m_iHealth"), 100*10);
        case 4: 
        {
            Laser = client;
        }
        case 5:
        {
            SetEntityRenderMode(client, RENDER_TRANSCOLOR);
            SetEntityRenderColor(client, 255, 255, 255, 255-255);
        }
        case 6: SetEntityGravity(client, 0.3)
        case 7: wytrzymalosc[client] = 30.0;
        case 8: SetClientSpeed(client, 2.0)
        case 10:
        {
            GivePlayerItem(client, "weapon_healthshot", 0);
            GivePlayerItem(client, "weapon_healthshot", 0);
            GivePlayerItem(client, "weapon_healthshot", 0);
            GivePlayerItem(client, "weapon_healthshot", 0);
        }
        case 11: SetEntityModel(client, (GetClientTeam(client) == CS_TEAM_CT)? modele_serwera[GetRandomInt(6, 10)]: modele_serwera[GetRandomInt(1, 5)]);
        case 14: SetEntData(client, FindSendPropInfo("CCSPlayer", "m_iAccount"), 16000);
    }
}
RemoveWeaponDrop(client, entity) 
{ 
    CS_DropWeapon(client, entity, true, true); 
    AcceptEntityInput(entity, "Kill") 
}
public Action:PlayerDeath(Handle:event_death, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event_death, "userid"));
    new killer = GetClientOfUserId(GetEventInt(event_death, "attacker"));
    if(!IsValidClient(client) || !IsValidClient(killer))
        return;
    
    if(GetClientTeam(client) != GetClientTeam(killer))
    {
        PrintToChat(client, "\x01[\x04SuperMoce\x01] Zabiłeś zabity przez: %s", nazwa_gracza[killer]);
        PrintToChat(client, "\x01[\x04SuperMoce\x01] Jego Super moc to: %s", SuperMocNazwy[SuperMoc[killer]]);
    }
    switch(SuperMoc[client])
    {
        case 15:
        {
            new Float:fOrigin[3];
            new Float:iOrigin[3];
            GetClientEyePosition(client, Float:fOrigin);

            for(new i = 1; i <= MaxClients; i++)
            {
                if(!IsClientInGame(i) || !IsPlayerAlive(i))
                    continue;

                if(GetClientTeam(client) == GetClientTeam(i))
                    continue;

                GetClientEyePosition(i, Float:iOrigin);
                if(GetVectorDistance(fOrigin, iOrigin) <= 500.0)
                    SDKHooks_TakeDamage(i, client, client, (1000.0+GetClientHealth(i)), DMG_GENERIC);
            }

            TE_SetupExplosion(fOrigin, sprite_blue, 10.0, 1, 0, 200, 200);
            TE_SendToAll();
        }
		case 17 : CreateTimer ( 0.1 , Wskrzes , client , TIMER_FLAG_NO_MAPCHANGE ); 
    }
}
public Action:Wskrzes(Handle:timer, any:client)
{
    if(!IsValidClient(client))
        return;

    CS_RespawnPlayer(client);
}
public Action EventWeaponFire(Event gEventHook, const char[] gEventName, bool iDontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 

    if(SuperMoc[client] == 9)
    {
        int iWeapon = Client_GetActiveWeapon(client);

        if(IsValidEdict(iWeapon))
        {
            Weapon_SetPrimaryClip(iWeapon, Weapon_GetPrimaryClip(iWeapon) + 1);
        }
    }
}
Client_GetActiveWeapon(client)
{
    new weapon =  GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    
    if (!Entity_IsValid(weapon)) {
        return INVALID_ENT_REFERENCE;
    }
    
    return weapon;
}
Entity_IsValid(entity)
{
    return IsValidEntity(entity);
} 
stock Weapon_GetPrimaryClip(weapon)
{
    return GetEntProp(weapon, Prop_Data, "m_iClip1");
}
stock Weapon_SetPrimaryClip(weapon, value)
{
    SetEntProp(weapon, Prop_Data, "m_iClip1", value);
}
public SetClientSpeed(client,Float:speed) 
{ 
    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue",speed)
}
public Action:SetCvars(Handle:timer)
{
    ServerCommand("sv_disable_immunity_alpha 1");
    ServerCommand("sv_hibernate_when_empty 0");
    ServerCommand("mp_limitteams 0");
    ServerCommand("mp_autoteambalance 0");
    ServerCommand("mp_friendlyfire 1");
    ServerCommand("mp_freezetime 9");
    ServerCommand("mp_roundtime 1.75");
    ServerCommand("mp_roundtime_defuse 1.75");
    ServerCommand("mp_roundtime_hostage 1.75");
}
public Action:UpdateLine(Handle:timer)
{
    for(new i = 1; i <= MAX_PLAYERS; i++)
    {
        if(!IsValidClient(i))
            return;
        
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {    
            if (Laser != -1)
            {
                if(!IsValidClient(Laser))
                    return;
            
                if (GetClientTeam(Laser) != GetClientTeam(i))
                {
                    new color[4] = {255,0,0,200};
                    TE_SetupBeamLaser(i, Laser, g_LaserModel, g_HaloModel, 1, 1, 0.1, 2.0, 1.0, 1, 0.0, color, 1);
                    TE_SendToClient(Laser, 0.0);
                }
            }
        }
        i++;
    }
    return;
}
public Action:BombaPodlozona(Handle:event_bomb_planted, const String:name[], bool:dontBroadcast)
{
    C4TimerON = 1;
    C4Timer = 40;
    C4Timer--;
    CreateTimer(1.0, C4Timerek, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:C4Timerek(Handle:timer)
{
    if(C4TimerON == 1)
    {
        C4Timer--;
        CreateTimer(1.0, C4Timerek, TIMER_FLAG_NO_MAPCHANGE);
    }
}
public Action:BombaRozbrojona(Handle:event_bomb_defused, const String:name[], bool:dontBroadcast)
{
    C4TimerON = 2;
}
public OnWeaponEquipPost(client, weapon)
{
    clientlevel[client] = 0
    if (g_cvJumpKnife) 
    {
        if(LastLevel(client) == true)
        {
            clientlevel[client] = 1
        }
    }    
}
public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"))
    clientlevel[client] = 0
    if (GetConVarInt(g_cvJumpKnife) == 1)
    {
        if(LastLevel(client) == true)
        {
            clientlevel[client] = 1
        }
    }    
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(SuperMoc[client] == 16)
    {
        DoubleJump(client)
    }
}


stock DoubleJump(const any:client)
{
    new fCurFlags = GetEntityFlags(client), fCurButtons = GetClientButtons(client)
    if (g_fLastFlags[client] & FL_ONGROUND)
    {
        if (!(fCurFlags & FL_ONGROUND) && !(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)
        {
            OriginalJump(client)
        }
    }
    else if (fCurFlags & FL_ONGROUND)
    {
        Landed(client)
    }
    else if (!(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)
    {
        ReJump(client)
    }
    g_fLastFlags[client]    = fCurFlags
    g_fLastButtons[client]    = fCurButtons
}

stock OriginalJump(const any:client)
{
    g_iJumps[client]++
}

stock Landed(const any:client)
{
    g_iJumps[client] = 0
}

stock ReJump(const any:client)
{
    if ( 1 <= g_iJumps[client] <= g_iJumpMax)
    {
        g_iJumps[client]++
        decl Float:vVel[3]
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel)
        vVel[2] = g_flBoost
        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel)
    }
}

public convar_ChangeBoost(Handle:convar, const String:oldVal[], const String:newVal[])
{
    g_flBoost = StringToFloat(newVal)
}

public convar_ChangeMax(Handle:convar, const String:oldVal[], const String:newVal[])
{
    g_iJumpMax = StringToInt(newVal)
}

public bool:LastLevel(client)
{
        if(IsValidClient(client) && IsPlayerAlive(client))
        {
			new weapon_count = 0
                for(new i = 0; i <= 4; i++)
                {
                    if(GetPlayerWeaponSlot(client, i) != -1) weapon_count++
                }
                return (weapon_count == 1);  
        }
        return false
}
public bool:IsValidClient(client)
{
    if(client >= 1 && client <= MaxClients && IsClientInGame(client))
        return true;

    return false;
} 