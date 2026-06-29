#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
    
public Plugin:myinfo = 
{
    name = "Knife_Power",
    author = "cjsrk",
    description = "Modified the knife's damage and range",
    url = ""
};

new Handle:ConVarFF = INVALID_HANDLE;

new Handle:cvarEnable;
new Handle:cvarUseForBots;
new Handle:cvarModifiedKnifes;
new Handle:cvarKnifesDamage;
new Handle:cvarPrimaryRange;
new Handle:cvarSecondaryRange;
new Handle:cvarKnifeHitSound;
new Handle:cvarKnifeHitWallSound;
new Handle:cvarShieldName;

static bool isEnabled;    //启动或禁用插件变量
static bool isUseForBots = true;     // bot的刀子是否也可以修改伤害和射程
static char ModifiedKnifesText[512];    // 需要修改的刀子名称字符串（支持加枪插件的新刀）
static char ModifiedKnifes[16][32];     // 需要修改的刀子名称
static char KnifesDamageText[136];    // 需要修改的刀子对应伤害字符串
static float KnifesDamage[16] = {1.0};     // 需要修改的刀子对应伤害
static char PrimaryRangeText[136];    // 需要修改的刀子对应左键轻击伤害范围字符串
static float PrimaryRange[16] = {0.0};     // 需要修改的刀子对应左键轻击伤害范围
static char SecondaryRangeText[136];    // 需要修改的刀子对应右键重击伤害范围字符串
static float SecondaryRange[16] = {0.0};     // 需要修改的刀子对应右键重击伤害范围
static char HitKnifeSoundText[1024];    // 需要播放的近战武器击中人体声音字符串
static char HitKnifeSound[16][64];     // 需要播放的近战武器击中人体声音
static char KnifeHitWallSoundText[1024];    // 需要播放的近战武器击中物体声音字符串
static char KnifeHitWallSound[16][64];     // 需要播放的近战武器击中1物体声音
static char ShieldName[32];    //应用盾牌功能的武器，用于兼容盾牌插件以削弱对盾牌手的近战攻击

static int KnifesNum = 0;
int Victim[MAXPLAYERS+1] = {0};
int g_decal1 = -1, g_decal2 = -1, g_decal3 = -1;


public OnPluginStart()
{
    CreateConVar("sm_knife_power_skin_version", "1.1.0", "Plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvarEnable = CreateConVar("sm_knife_power_enable", "1", "Whether to enable the plugin (1: Enabled; 0: disabled)", _, true, 0.0, true, 1.0);
    cvarUseForBots = CreateConVar("sm_knife_power_for_bots", "1", "Whether Bots's knives can also modify damage and range (1: Enabled; 0: disabled)", _, true, 0.0, true, 1.0);
    cvarModifiedKnifes = CreateConVar("sm_knife_power_weapons", "weapon_knife", "The name of the melee weapon that needs to be modified. New weapons are supported. Multiple (up to 16) weapons can be entered, separated by commas (,).", _);
    cvarKnifesDamage = CreateConVar("sm_knife_power_damage", "1.0", "The damage ratio of the melee weapon that needs to be modified corresponds to the name of the weapon. Unit: The default damage multiple, ranging from 0.0 to 10.0, 0.0 indicates no damage, 1.0 indicates no damage change. A maximum of 16 entries can be entered and separated by commas (,).", _);
    cvarPrimaryRange = CreateConVar("sm_knife_power_primary_range", "0.0", "The left-click attack damage range of the melee weapon that needs to be modified corresponds to the weapon name. Unit: Meter, range 1.22-4.0, value 1.22 below indicates no change in damage range (default range 1.2192). A maximum of 16 entries can be entered and separated by commas (,).", _);
    cvarSecondaryRange = CreateConVar("sm_knife_power_secondary_range", "0.0", "The right-click attack damage range of melee weapons that needs to be modified corresponds to the weapon name one by one. Unit: Meter, range 0.92-4.0, a value below 0.92 means that the damage range is not changed (default range 0.9144). The typical heavy blow range is three quarters of the light blow. A maximum of 16 entries can be entered and separated by commas (,).", _);
    cvarKnifeHitSound = CreateConVar("sm_knife_power_hit_sound", "", "The sound of a melee weapon hitting a body that needs to be played corresponds to the name of the weapon when hitting an enemy in the new damage range. Fill in the sound in your knife sound script txt (such as scripts/knife.txt) (such as weapons/knife/knife_hit1.wav), you must add the extension '.wav', if left blank, no sound will be played. A maximum of 16 entries can be entered and separated by commas (,).", _);
    cvarKnifeHitWallSound = CreateConVar("sm_knife_power_hitwall_sound", "", "The sound of a melee weapon hitting an object that needs to be played corresponds to the name of the weapon when hitting an object such as a wall in the new damage range. Fill in the sound from your knife sound script txt (for example weapons/knife/knife_hitwall1.wav), you must add the extension '.wav', if left blank, no sound will be played. A maximum of 16 entries can be entered and separated by commas (,).", _);
    cvarShieldName = CreateConVar("sm_knife_power_shield_weapon", "", "The name of the weapon for which the shield function is applied.This option is used to be compatible with shield plugins to weaken melee attacks on shielders (shield names are mostly weapon_elite), leave blank if shield plugins are not installed.", _);
    
    AutoExecConfig(true, "plugin.knife_power");
    HookConVarChange(cvarEnable, CvarChange);
    HookConVarChange(cvarUseForBots, CvarChange);
    HookConVarChange(cvarModifiedKnifes, CvarChange);
    HookConVarChange(cvarKnifesDamage, CvarChange);
    HookConVarChange(cvarPrimaryRange, CvarChange);
    HookConVarChange(cvarSecondaryRange, CvarChange);
    HookConVarChange(cvarKnifeHitSound, CvarChange);
    HookConVarChange(cvarKnifeHitWallSound, CvarChange);
    HookConVarChange(cvarShieldName, CvarChange);
    
    AddTempEntHook("PlayerAnimEvent", Hook_PlayerKnifeAnimEvent);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
    
    ConVarFF = FindConVar("mp_friendlyfire");
}


public OnMapStart()
{
    CreateTimer(0.5, Timer_LoadInfo3, _);
    PrecacheSound("physics/flesh/flesh_squishy_impact_hard4.wav", true);
    g_decal1 = PrecacheDecal("decals/manhackcut_subrect", true);
    g_decal2 = PrecacheDecal("decals/manhackcut2_subrect", true);
    g_decal3 = PrecacheDecal("decals/manhackcut3_subrect", true);
    
    PrecacheSound("physics/metal/metal_box_impact_bullet1.wav", true);
    PrecacheSound("physics/metal/metal_solid_impact_bullet2.wav", true);
    PrecacheSound("physics/metal/metal_solid_impact_bullet3.wav", true);
    PrecacheSound("physics/metal/metal_solid_impact_bullet4.wav", true);
}


public Action:Timer_LoadInfo3(Handle timer, any:temp)
{
    // 读取信息字符串的值，载入武器信息
    
    if(KnifesNum > 0)
        return;
    
    TrimString(ModifiedKnifesText);
    decl String:data[16][32];
    ExplodeString(ModifiedKnifesText, ",", data, 16, 32);
    int num = 0;
    for(int i = 0; i < sizeof(data); i++) 
    {
        TrimString(data[i]);
        if(strlen(data[i]) > 7)
        {
            strcopy(ModifiedKnifes[num], strlen(data[i]) + 1, data[i]);
            num++;
        }
    }
    
    decl String:data2[16][8];
    ExplodeString(KnifesDamageText, ",", data2, 16, 8);
    for(int i = 0; i < num; i++) 
    {
        TrimString(data2[i]);
        if(strlen(data2[i]) > 0)
        {   
            KnifesDamage[i] = StringToFloat(data2[i]);  
            if(KnifesDamage[i] < 0.0)
                KnifesDamage[i] = 0.0;
            if(KnifesDamage[i] > 10.0)
                KnifesDamage[i] = 10.0;
        }
    }
    
    decl String:data3[16][8];
    ExplodeString(PrimaryRangeText, ",", data3, 16, 8);
    for(int i = 0; i < num; i++) 
    {
        TrimString(data3[i]);
        if(strlen(data3[i]) > 0)
        {   
            PrimaryRange[i] = StringToFloat(data3[i]);  
            if(PrimaryRange[i] < 1.22)
                PrimaryRange[i] = 0.0;
            if(PrimaryRange[i] > 4.0)
                PrimaryRange[i] = 4.0;
        }
    }
    
    decl String:data4[16][8];
    ExplodeString(SecondaryRangeText, ",", data4, 16, 8);
    for(int i = 0; i < num; i++) 
    {
        TrimString(data4[i]);
        if(strlen(data4[i]) > 0)
        {   
            SecondaryRange[i] = StringToFloat(data4[i]);    
            if(SecondaryRange[i] < 0.92)
                SecondaryRange[i] = 0.0;
            if(SecondaryRange[i] > 4.0)
                SecondaryRange[i] = 4.0;
        }
    }
    
    TrimString(HitKnifeSoundText);
    decl String:data5[16][64];
    ExplodeString(HitKnifeSoundText, ",", data5, 16, 64);
    int num2 = 0;
    for(int i = 0; i < sizeof(data5); i++) 
    {
        TrimString(data5[i]);
        if(strlen(data5[i]) > 0)
        {
            strcopy(HitKnifeSound[num2], strlen(data5[i]) + 1, data5[i]);
            ReplaceStringEx(HitKnifeSound[num2], strlen(HitKnifeSound[num2]) + 1, "sound/", "", -1, -1, false);
            TrimString(HitKnifeSound[num2]);
            num2++;
        }
    }
    
    TrimString(KnifeHitWallSoundText);
    decl String:data6[16][64];
    ExplodeString(KnifeHitWallSoundText, ",", data6, 16, 64);
    int num3 = 0;
    for(int i = 0; i < sizeof(data6); i++) 
    {
        TrimString(data6[i]);
        if(strlen(data6[i]) > 0)
        {
            strcopy(KnifeHitWallSound[num3], strlen(data6[i]) + 1, data6[i]);
            ReplaceStringEx(KnifeHitWallSound[num3], strlen(KnifeHitWallSound[num3]) + 1, "sound/", "", -1, -1, false);
            TrimString(KnifeHitWallSound[num3]);
            num3++;
        }
    }
    
    KnifesNum++;
}


//读取配置文件的cvar的值
public OnConfigsExecuted()
{
    isEnabled = GetConVarBool(cvarEnable);
    isUseForBots = GetConVarBool(cvarUseForBots);
    GetConVarString(cvarModifiedKnifes, ModifiedKnifesText, sizeof(ModifiedKnifesText));
    GetConVarString(cvarKnifesDamage, KnifesDamageText, sizeof(KnifesDamageText));
    GetConVarString(cvarPrimaryRange, PrimaryRangeText, sizeof(PrimaryRangeText));
    GetConVarString(cvarSecondaryRange, SecondaryRangeText, sizeof(SecondaryRangeText));
    GetConVarString(cvarKnifeHitSound, HitKnifeSoundText, sizeof(HitKnifeSoundText));
    GetConVarString(cvarKnifeHitWallSound, KnifeHitWallSoundText, sizeof(KnifeHitWallSoundText));
    GetConVarString(cvarShieldName, ShieldName, sizeof(ShieldName));
}


//cvar值变化时的响应数组
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == cvarEnable)
    {
        if(StringToInt(newValue) == 1)
        {
            isEnabled = true;
        }
        else
        {
            isEnabled = false;
        }
    }
    if(convar == cvarUseForBots)
    {
        if(StringToInt(newValue) == 1)
        {
            isUseForBots = true;
        }
        else
        {
            isUseForBots = false;
        }
    }
    if(convar == cvarModifiedKnifes)
    {
        if(strlen(newValue) > 0 && !StrEqual("", newValue))
        {
            strcopy(ModifiedKnifesText, strlen(newValue) + 1, newValue);        
        }
    }
    if(convar == cvarKnifesDamage)
    {
        if(strlen(newValue) > 0 && !StrEqual("", newValue))
        {
            strcopy(KnifesDamageText, strlen(newValue) + 1, newValue);      
        }
    }
    if(convar == cvarPrimaryRange)
    {
        if(strlen(newValue) > 0 && !StrEqual("", newValue))
        {
            strcopy(PrimaryRangeText, strlen(newValue) + 1, newValue);      
        }
    }
    if(convar == cvarSecondaryRange)
    {
        if(strlen(newValue) > 0 && !StrEqual("", newValue))
        {
            strcopy(SecondaryRangeText, strlen(newValue) + 1, newValue);        
        }
    }
    if(convar == cvarKnifeHitSound)
    {
        if(strlen(newValue) > 0 && !StrEqual("", newValue))
        {
            strcopy(HitKnifeSoundText, strlen(newValue) + 1, newValue);     
        }
    }
    if(convar == cvarKnifeHitWallSound)
    {
        if(strlen(newValue) > 0 && !StrEqual("", newValue))
        {
            strcopy(KnifeHitWallSoundText, strlen(newValue) + 1, newValue);     
        }
    }
    if(convar == cvarShieldName)
    {
        if(strlen(newValue) > 0 && !StrEqual("", newValue))
        {
            strcopy(ShieldName, strlen(newValue) + 1, newValue);        
        }
    }
}


public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);  
}


//调整刀的伤害值
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
    if(isEnabled == false)
        return Plugin_Continue;
    
    if( (damagetype & DMG_BULLET == 0 && damagetype & DMG_NEVERGIB == 0) || // 伤害不是来自刀子
        damage <= 0.0 ||
        attacker < 1 ||
        attacker > MaxClients || // 攻击者不是玩家
        victim < 1 ||
        victim > MaxClients || // 受害者不是玩家
        attacker != inflictor ||
        !IsClientInGame(attacker) ||
        !IsClientInGame(victim) )
        {
            // PrintToChatAll("提示：不符合基本条件。");
            return Plugin_Continue; // Allow damage to go through
        }
    else
    {
        if(HasEntProp(attacker, Prop_Send, "m_hActiveWeapon") == false)
            return Plugin_Continue;
        new currentWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
        if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
            return Plugin_Continue;
        decl String:sWeapon0[32];
        GetEdictClassname(currentWeapon, sWeapon0, sizeof(sWeapon0));
        
        int myWeapon = -1;
        for(int i = 0; i <= (sizeof(ModifiedKnifes) - 1); i++) {
            if(StrEqual(ModifiedKnifes[i], sWeapon0))
            {
                myWeapon = i;
                break;
            }
        }
        
        if(myWeapon > -1)
        {
            Victim[attacker] = victim;
            if (!GetConVarBool(ConVarFF) && GetClientTeam(attacker) == GetClientTeam(victim))
            {
                // PrintToChatAll("队友伤害关闭");
                CreateTimer(0.1, Timer_ChangeVictim, attacker);
            }
            
            float DamageMultiplier = -1.0;
            if(KnifesDamage[myWeapon] != 1.0)
            {
                DamageMultiplier = KnifesDamage[myWeapon];
                
                // 如果设置了盾牌名称
                if(strlen(ShieldName) > 0)
                {
                    int AttackDirection = GetDirection(attacker, victim);    // 确定攻击方向
                    // 检测受害者使用的武器
                    if(HasEntProp(victim, Prop_Send, "m_hActiveWeapon") == true)
                    {
                        new currentWeapon2 = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
                        if (IsValidEdict(currentWeapon2) && (currentWeapon2 != -1))
                        {
                            decl String:sWeapon[32];
                            GetEdictClassname(currentWeapon2, sWeapon, sizeof(sWeapon));
                            
                            // 如果攻击受害者前方且受害者正在使用盾牌
                            if(AttackDirection == 1 && StrEqual(ShieldName, sWeapon))
                            {
                                DamageMultiplier = -1.0;    // 抵消攻击
                            }
                            // 如果攻击受害者未在使用盾牌
                            if(!StrEqual(ShieldName, sWeapon))
                            {
                                bool ShieldOnBack = false;    //检测盾牌有没有在背上
                                new main = GetPlayerWeaponSlot(victim, 0);
                                new pistol = GetPlayerWeaponSlot(victim, 1);
                                new knife = GetPlayerWeaponSlot(victim, 2);
                                if(main > -1)
                                {
                                    decl String:sWeapon2[32];
                                    GetEdictClassname(main, sWeapon2, sizeof(sWeapon2));
                                    if(StrEqual(ShieldName, sWeapon2))
                                        ShieldOnBack = true;
                                }
                                if(pistol > -1)
                                {
                                    decl String:sWeapon2[32];
                                    GetEdictClassname(pistol, sWeapon2, sizeof(sWeapon2));
                                    if(StrEqual(ShieldName, sWeapon2))
                                        ShieldOnBack = true;
                                }
                                if(knife > -1)
                                {
                                    decl String:sWeapon2[32];
                                    GetEdictClassname(knife, sWeapon2, sizeof(sWeapon2));
                                    if(StrEqual(ShieldName, sWeapon2))    
                                        ShieldOnBack = true;
                                }
                                
                                // 如果攻击受害者后方且受害者的盾牌在背上（未使用）
                                if((AttackDirection == 2 || AttackDirection == 3) && ShieldOnBack == true)
                                {
                                    DamageMultiplier = -1.0;    // 抵消攻击
                                }
                            }
                        }
                    }
                }
                
                if(DamageMultiplier >= 0.0)
                {
                    damage *=  DamageMultiplier;
                    return Plugin_Changed;
                }
            }
            // PrintToChatAll("触发OnTakeDamage：%f", damage);
        }
    }
    return Plugin_Continue; 
}


public Action:Timer_ChangeVictim(Handle timer, int attacker)
{
    Victim[attacker] = 0;
}


// 调整刀的伤害范围
public Action Hook_PlayerKnifeAnimEvent(const String:te_name[], const Players[], numClients, Float:delay)
{
    if(isEnabled == false)
        return Plugin_Continue;
    
    int player = TE_ReadNum("m_hPlayer");
    int animType = TE_ReadNum("m_iEvent");
    // int animData = TE_ReadNum("m_nData");
    
    int client = MakeCompatEntRef(player);
    
    if(client > 0 && IsValidEntity(client) && IsClient(client, true))
    {
        if(isUseForBots == false && IsFakeClient(client))
            return Plugin_Continue;
        // PrintToChatAll("AnimEvent: Player: %i, Event: %i, Data: %i", client, animType, data);
        
        new currentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (!IsValidEdict(currentWeapon) || (currentWeapon == -1))
            return Plugin_Continue;
        decl String:sWeapon[32];
        GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));
        
        int myWeapon = -1;
        for(int i = 0; i <= (sizeof(ModifiedKnifes) - 1); i++) {
            if(StrEqual(ModifiedKnifes[i], sWeapon))
            {
                myWeapon = i;
                break;
            }
        }
        
        if(myWeapon > -1)
        {
            float PlayerOrigin[3], PlayerAngle[3];
            GetClientEyePosition(client, PlayerOrigin);
            GetClientEyeAngles(client, PlayerAngle);
            
            // 针对玩家和人质
            float AimOrigin[3];
            int HitGroup = 0;
            
            if(animType == 1)    // 刀轻击
            {
                if(PrimaryRange[myWeapon] < 1.22 ||  PrimaryRange[myWeapon] > 4.0)
                    return Plugin_Continue;
                
                // 如果击中人体
                int AimEntity = GetPlayerAimOrigin(client, AimOrigin);    // 获取被击中的玩家或人质索引
                if(AimEntity > 0)
                {                   
                    char ClassName[32];
                    GetEdictClassname(AimEntity, ClassName, sizeof(ClassName));
                    if(StrEqual(ClassName, "player") || StrEqual(ClassName, "hostage_entity"))
                    {
                        if(StrEqual(ClassName, "player") && (!IsClientConnected(AimEntity) || !IsClientInGame(AimEntity)))
                            return Plugin_Continue;
                        
                        float distance = GetVectorDistance(PlayerOrigin, AimOrigin, false);
                        if(distance > 64.0 && distance <= (PrimaryRange[myWeapon] / 0.01905))
                        {
                            // PrintToChat(client, "轻击！");
                            
                            HitGroup = GetPlayerAimOrigin2(client, AimEntity);    // 获取被击中的玩家或人质命中组
                            
                            int EntityType = 0;
                            if(StrEqual(ClassName, "player"))
                                EntityType = 1;
                            else
                                EntityType = 2;
                            
                            DataPack pack = new DataPack();
                            pack.WriteCell(client);
                            pack.WriteCell(AimEntity);
                            pack.WriteCell(EntityType);
                            pack.WriteCell(animType);
                            pack.WriteCell(HitGroup);
                            pack.WriteCell(currentWeapon);
                            pack.WriteCell(myWeapon);
                            pack.WriteFloat(AimOrigin[0]);
                            pack.WriteFloat(AimOrigin[1]);
                            pack.WriteFloat(AimOrigin[2]);
                            pack.WriteFloat(PlayerAngle[0]);
                            pack.WriteFloat(PlayerAngle[1]);
                            pack.WriteFloat(PlayerAngle[2]);
                            CreateTimer(0.0, SpawnKnifeDamage, pack);
                            
                            return Plugin_Continue;
                        }
                    }
                }
                
                // 如果击中物体
                float AimOrigin2[3];
                int ResultEntity  = GetPlayerAimOrigin3(client, AimOrigin2);
                if(ResultEntity >= 0)
                {
                    float distance2 = GetVectorDistance(PlayerOrigin, AimOrigin2, false);
                    if(distance2 > 64.0 && distance2 <= (PrimaryRange[myWeapon] / 0.01905))
                    {
                        if(g_decal1 > -1 && g_decal2 > -1 && g_decal3 > -1)
                        {
                            int NewDecal = 0;
                            switch(GetRandomInt(1,3))
                            {
                                case 1: NewDecal = g_decal1;
                                case 2: NewDecal = g_decal2;
                                case 3: NewDecal = g_decal3;
                            }
                            
                            DataPack pack2 = new DataPack();
                            pack2.WriteFloat(AimOrigin2[0]);
                            pack2.WriteFloat(AimOrigin2[1]);
                            pack2.WriteFloat(AimOrigin2[2]);
                            pack2.WriteCell(NewDecal);
                            CreateTimer(0.1, SpawnKnifeDecal, pack2);
                        }
                        
                        decl String:ClassName2[32];
                        GetEdictClassname(ResultEntity, ClassName2, sizeof(ClassName2));
                        if(StrContains(ClassName2, "prop_physics", false) != -1)
                        {
                            // 产生火花
                            float OutputDir[3];
                            MakeVectorFromPoints(AimOrigin2, PlayerOrigin, OutputDir);  
                            DataPack pack3 = new DataPack();
                            pack3.WriteFloat(AimOrigin2[0]);
                            pack3.WriteFloat(AimOrigin2[1]);
                            pack3.WriteFloat(AimOrigin2[2]);
                            pack3.WriteFloat(OutputDir[0]);
                            pack3.WriteFloat(OutputDir[1]);
                            pack3.WriteFloat(OutputDir[2]);
                            CreateTimer(0.1, SpawnSparks, pack3);
                        }
						else
                        {
                            float OutputDir[3];
                            MakeVectorFromPoints(AimOrigin2, PlayerOrigin, OutputDir);  
                            DataPack pack3 = new DataPack();
                            pack3.WriteFloat(AimOrigin2[0]);
                            pack3.WriteFloat(AimOrigin2[1]);
                            pack3.WriteFloat(AimOrigin2[2]);
                            pack3.WriteFloat(OutputDir[0]);
                            pack3.WriteFloat(OutputDir[1]);
                            pack3.WriteFloat(OutputDir[2]);
                            CreateTimer(0.1, SpawnDust, pack3);
                        }
						
                        // 播放新伤害范围内近战武器击中击中物体声音
                        if(strlen(KnifeHitWallSound[myWeapon]) > 0)
                        {
                            // EmitSoundToAll(KnifeHitWallSound[myWeapon], currentWeapon, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_STOP, 1.0);
                            DataPack pack4 = new DataPack();
                            int SoundType = 2;
                            pack4.WriteCell(SoundType);
                            pack4.WriteCell(myWeapon);
                            pack4.WriteCell(currentWeapon);
                            CreateTimer(0.0, PlayKnifeSound, pack4);
                        }
						
						// 破坏物体
                        if(StrContains(ClassName2, "func_breakable", false) != -1 || StrContains(ClassName2, "prop_physics", false) != -1 || StrContains(ClassName2, "prop_dynamic", false) != -1)
                        {
                            if(StrEqual(ClassName2, "func_breakable_surf"))    // 破坏玻璃
                            {
                                SetVariantString("0.5 0.5 32");
                                AcceptEntityInput(ResultEntity, "Shatter");
                            }
                            else
                                CreateExplosion(AimOrigin2, client, 25.0);    
                        }
                    }
                }
            }
            
            if(animType == 0)    // 刀重击
            {
                if(SecondaryRange[myWeapon] < 0.92 ||  SecondaryRange[myWeapon] > 4.0)
                    return Plugin_Continue;
                
                // 如果击中人体
                int AimEntity = GetPlayerAimOrigin(client, AimOrigin);    // 获取被击中的玩家或人质索引
                if(AimEntity > 0)
                {
                    char ClassName[32];
                    GetEdictClassname(AimEntity, ClassName, sizeof(ClassName));
                    if(StrEqual(ClassName, "player") || StrEqual(ClassName, "hostage_entity"))
                    {
                        if(StrEqual(ClassName, "player") && (!IsClientConnected(AimEntity) || !IsClientInGame(AimEntity)))
                            return Plugin_Continue;
                        
                        float distance = GetVectorDistance(PlayerOrigin, AimOrigin, false);
                        if(distance > 48.0 && distance <= (SecondaryRange[myWeapon] / 0.01905))
                        {
                            // PrintToChat(client, "重击！");
                            
                            HitGroup = GetPlayerAimOrigin2(client, AimEntity);    // 获取被击中的玩家或人质命中组
                            int EntityType = 0;
                            if(StrEqual(ClassName, "player"))
                                EntityType = 1;
                            else
                                EntityType = 2;
                            
                            DataPack pack = new DataPack();
                            pack.WriteCell(client);
                            pack.WriteCell(AimEntity);
                            pack.WriteCell(EntityType);
                            pack.WriteCell(animType);
                            pack.WriteCell(HitGroup);
                            pack.WriteCell(currentWeapon);
                            pack.WriteCell(myWeapon);
                            pack.WriteFloat(AimOrigin[0]);
                            pack.WriteFloat(AimOrigin[1]);
                            pack.WriteFloat(AimOrigin[2]);
                            pack.WriteFloat(PlayerAngle[0]);
                            pack.WriteFloat(PlayerAngle[1]);
                            pack.WriteFloat(PlayerAngle[2]);
                            CreateTimer(0.0, SpawnKnifeDamage, pack);
                            
                            return Plugin_Continue;
                        }
                    }
                }
                
                // 如果击中物体
                float AimOrigin2[3];
                int ResultEntity  = GetPlayerAimOrigin3(client, AimOrigin2);
                if(ResultEntity >= 0)
                {
                    float distance2 = GetVectorDistance(PlayerOrigin, AimOrigin2, false);
                    if(distance2 > 48.0 && distance2 <= (SecondaryRange[myWeapon] / 0.01905))
                    {
                        if(g_decal1 > -1 && g_decal2 > -1 && g_decal3 > -1)
                        {
                            int NewDecal = 0;
                            switch(GetRandomInt(1,3))
                            {
                                case 1: NewDecal = g_decal1;
                                case 2: NewDecal = g_decal2;
                                case 3: NewDecal = g_decal3;
                            }
                            DataPack pack2 = new DataPack();
                            pack2.WriteFloat(AimOrigin2[0]);
                            pack2.WriteFloat(AimOrigin2[1]);
                            pack2.WriteFloat(AimOrigin2[2]);
                            pack2.WriteCell(NewDecal);
                            CreateTimer(0.1, SpawnKnifeDecal, pack2);
                        }
                        
                        decl String:ClassName2[32];
                        GetEdictClassname(ResultEntity, ClassName2, sizeof(ClassName2));
                        if(StrContains(ClassName2, "prop_physics", false) != -1)
                        {
                            // 产生火花
                            float OutputDir[3];
                            MakeVectorFromPoints(AimOrigin2, PlayerOrigin, OutputDir);  
                            DataPack pack3 = new DataPack();
                            pack3.WriteFloat(AimOrigin2[0]);
                            pack3.WriteFloat(AimOrigin2[1]);
                            pack3.WriteFloat(AimOrigin2[2]);
                            pack3.WriteFloat(OutputDir[0]);
                            pack3.WriteFloat(OutputDir[1]);
                            pack3.WriteFloat(OutputDir[2]);
                            CreateTimer(0.1, SpawnSparks, pack3);
                        }
						else
                        {
                            float OutputDir[3];
                            MakeVectorFromPoints(AimOrigin2, PlayerOrigin, OutputDir);  
                            DataPack pack3 = new DataPack();
                            pack3.WriteFloat(AimOrigin2[0]);
                            pack3.WriteFloat(AimOrigin2[1]);
                            pack3.WriteFloat(AimOrigin2[2]);
                            pack3.WriteFloat(OutputDir[0]);
                            pack3.WriteFloat(OutputDir[1]);
                            pack3.WriteFloat(OutputDir[2]);
                            CreateTimer(0.1, SpawnDust, pack3);
                        }
						
                        // 播放新伤害范围内近战武器击中击中物体声音
                        if(strlen(KnifeHitWallSound[myWeapon]) > 0)
                        {
                            // EmitSoundToAll(KnifeHitWallSound[myWeapon], currentWeapon, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_STOP, 1.0);
                            DataPack pack4 = new DataPack();
                            int SoundType = 2;
                            pack4.WriteCell(SoundType);
                            pack4.WriteCell(myWeapon);
                            pack4.WriteCell(currentWeapon);
                            CreateTimer(0.0, PlayKnifeSound, pack4);
                        }
						
						// 破坏物体
                        if(StrContains(ClassName2, "func_breakable", false) != -1 || StrContains(ClassName2, "prop_physics", false) != -1 || StrContains(ClassName2, "prop_dynamic", false) != -1)
                        {
                            if(StrEqual(ClassName2, "func_breakable_surf"))    // 破坏玻璃
                            {
                                SetVariantString("0.5 0.5 32");
                                AcceptEntityInput(ResultEntity, "Shatter");
                            }
                            else
                                CreateExplosion(AimOrigin2, client, 50.0);    
                        }
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}


public Action SpawnKnifeDecal(Handle timer, DataPack pack2)
{
    pack2.Reset(); 
    float origin[3];
    origin[0] = pack2.ReadFloat();
    origin[1] = pack2.ReadFloat();
    origin[2] = pack2.ReadFloat();
    int NewDecal = pack2.ReadCell();
    CloseHandle(pack2);
    
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin", origin);
    TE_WriteNum("m_nIndex", NewDecal);
    TE_SendToAll();
    
    return Plugin_Continue;
}


public Action SpawnSparks(Handle timer, DataPack pack3)
{
    pack3.Reset(); 
    float origin[3], outDir[3];
    origin[0] = pack3.ReadFloat();
    origin[1] = pack3.ReadFloat();
    origin[2] = pack3.ReadFloat();
    outDir[0] = pack3.ReadFloat();
    outDir[1] = pack3.ReadFloat();
    outDir[2] = pack3.ReadFloat();
    CloseHandle(pack3);
    
    TE_SetupSparks(origin, outDir, 1, 2);
    TE_SendToAll();
    
    return Plugin_Continue;
}


public Action SpawnDust(Handle timer, DataPack pack3)
{
    pack3.Reset(); 
    float origin[3], outDir[3];
    origin[0] = pack3.ReadFloat();
    origin[1] = pack3.ReadFloat();
    origin[2] = pack3.ReadFloat();
    outDir[0] = pack3.ReadFloat();
    outDir[1] = pack3.ReadFloat();
    outDir[2] = pack3.ReadFloat();
    CloseHandle(pack3);
    
    TE_SetupDust(origin, outDir, 1.0, 0.01);
    TE_SendToAll();
    
    return Plugin_Continue;
}


void CreateExplosion(float pos[3], int attacker, float damage)
{
    int explosion = CreateEntityByName("env_explosion");
    if (explosion != -1)
    {
        DispatchKeyValueFloat(explosion, "iMagnitude", damage); // 设置威力
        DispatchKeyValue(explosion, "iRadiusOverride", "15");  // 设置范围
        DispatchSpawn(explosion);
        
        // 设置爆炸位置
        TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);
        
        // 设置攻击者（可选）
        SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", attacker);
        
        // 引爆
        AcceptEntityInput(explosion, "Explode");
        
        // 爆炸后立即移除实体
        CreateTimer(0.1, Timer_RemoveEntity, explosion);
    }
}

public Action Timer_RemoveEntity(Handle timer, any entity)
{
    if (IsValidEntity(entity))
        AcceptEntityInput(entity, "Kill");
    
    return Plugin_Continue;
}


public Action SpawnKnifeDamage(Handle timer, DataPack pack)
{
    pack.Reset(); 
    float origin[3], angle[3];
    int attacker = pack.ReadCell();
    int victim = pack.ReadCell();
    int EntityType = pack.ReadCell();
    int animType = pack.ReadCell();
    int hitGroup = pack.ReadCell();
    int weapon = pack.ReadCell();
    int myWeapon = pack.ReadCell();
    origin[0] = pack.ReadFloat();
    origin[1] = pack.ReadFloat();
    origin[2] = pack.ReadFloat();
    angle[0] = pack.ReadFloat();
    angle[1] = pack.ReadFloat();
    angle[2] = pack.ReadFloat();
    CloseHandle(pack);
    
    if(EntityType == 1)    // 伤害对象是玩家
    {
        if(Victim[attacker] > 0)
            return Plugin_Continue;
    }
    
    float AttackerOrigin[3], AttackerAngle[3];
    GetClientEyePosition(attacker, AttackerOrigin);
    GetClientEyeAngles(attacker, AttackerAngle);
    int AttackDirection = GetDirection(attacker, victim);    // 确定攻击方向
    float damage = 0.0;
    
    if(animType == 1)    // 刀轻击
    {
        // PrintToChat(attacker, "轻击成功！");
        
        float oldDamage = 1.0;
        if(hitGroup == 1 || hitGroup == 2)
            oldDamage = 20.0;
        else
            oldDamage = 15.0;
        
        if(KnifesDamage[myWeapon] != 1.0)
            damage = oldDamage * KnifesDamage[myWeapon];
        else
            damage = oldDamage;
    }
    if(animType == 0)    // 刀重击
    {
        // PrintToChat(attacker, "重击成功！");
        
        float oldDamage = 65.0;
        if(AttackDirection == 2)
            oldDamage = 195.0;
        
        if(KnifesDamage[myWeapon] != 1.0)
            damage = oldDamage * KnifesDamage[myWeapon];
        else
            damage = oldDamage;
    }
    
    // 如果设置了盾牌名称且伤害对象是玩家
    if(strlen(ShieldName) > 0 && EntityType == 1)
    {
        // 检测受害者使用的武器
        if(HasEntProp(victim, Prop_Send, "m_hActiveWeapon") == true)
        {
            new currentWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
            if (IsValidEdict(currentWeapon) && (currentWeapon != -1))
            {
                decl String:sWeapon[32];
                GetEdictClassname(currentWeapon, sWeapon, sizeof(sWeapon));
                
                // 如果攻击受害者前方且受害者正在使用盾牌
                if(AttackDirection == 1 && StrEqual(ShieldName, sWeapon))
                {
                    damage = 0.0;    // 抵消攻击
                    
                    switch(GetRandomInt(1,4))    //播放金属响声
                    {
                        case 1: EmitAmbientSound("physics/metal/metal_box_impact_bullet1.wav", origin, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
                        case 2: EmitAmbientSound("physics/metal/metal_solid_impact_bullet2.wav", origin, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
                        case 3: EmitAmbientSound("physics/metal/metal_solid_impact_bullet3.wav", origin, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
                        case 4: EmitAmbientSound("physics/metal/metal_solid_impact_bullet4.wav", origin, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
                    }
                    
                    //产生金属火花
                    float OldOutputDir[3];
                    MakeVectorFromPoints(origin, AttackerOrigin, OldOutputDir);  
                    TE_SetupSparks(origin, OldOutputDir, 1, 2);
                    TE_SendToAll();
                }
                // 如果攻击受害者未在使用盾牌
                if(!StrEqual(ShieldName, sWeapon))
                {
                    bool ShieldOnBack = false;    //检测盾牌有没有在背上
                    new main = GetPlayerWeaponSlot(victim, 0);
                    new pistol = GetPlayerWeaponSlot(victim, 1);
                    new knife = GetPlayerWeaponSlot(victim, 2);
                    if(main > -1)
                    {
                        decl String:sWeapon2[32];
                        GetEdictClassname(main, sWeapon2, sizeof(sWeapon2));
                        if(StrEqual(ShieldName, sWeapon2))
                            ShieldOnBack = true;
                    }
                    if(pistol > -1)
                    {
                        decl String:sWeapon2[32];
                        GetEdictClassname(pistol, sWeapon2, sizeof(sWeapon2));
                        if(StrEqual(ShieldName, sWeapon2))
                            ShieldOnBack = true;
                    }
                    if(knife > -1)
                    {
                        decl String:sWeapon2[32];
                        GetEdictClassname(knife, sWeapon2, sizeof(sWeapon2));
                        if(StrEqual(ShieldName, sWeapon2))    
                            ShieldOnBack = true;
                    }
                    
                    // 如果攻击受害者后方且受害者的盾牌在背上（未使用）
                    if((AttackDirection == 2 || AttackDirection == 3) && ShieldOnBack == true)
                    {
                        damage = 0.0;    // 抵消攻击
                        
                        switch(GetRandomInt(1,4))    //播放金属响声
                        {
                            case 1: EmitAmbientSound("physics/metal/metal_box_impact_bullet1.wav", origin, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
                            case 2: EmitAmbientSound("physics/metal/metal_solid_impact_bullet2.wav", origin, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
                            case 3: EmitAmbientSound("physics/metal/metal_solid_impact_bullet3.wav", origin, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
                            case 4: EmitAmbientSound("physics/metal/metal_solid_impact_bullet4.wav", origin, currentWeapon, SNDLEVEL_NORMAL, SND_CHANGEVOL, 1.0, SNDPITCH_NORMAL);
                        }
                        
                        //产生金属火花
                        float OldOutputDir[3];
                        MakeVectorFromPoints(origin, AttackerOrigin, OldOutputDir);  
                        TE_SetupSparks(origin, OldOutputDir, 1, 2);
                        TE_SendToAll();
                    }
                }
            }
        }
    }
    
    // PrintToChat(attacker, "伤害：%f", damage);
    SDKHooks_TakeDamage(victim, attacker, attacker, damage, 4098, weapon, origin);
    
    // 播放新伤害范围内近战武器击中人体声音
    if(strlen(HitKnifeSound[myWeapon]) > 0)
    {
        // EmitSoundToAll(HitKnifeSound[myWeapon], weapon, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_STOP, 1.0);
        DataPack pack4 = new DataPack();
        int SoundType = 1;
        pack4.WriteCell(SoundType);
        pack4.WriteCell(myWeapon);
        pack4.WriteCell(weapon);
        CreateTimer(0.0, PlayKnifeSound, pack4);
    }
    
    if (EntityType == 1 && !GetConVarBool(ConVarFF) && GetClientTeam(attacker) == GetClientTeam(victim))    // 队友伤害关闭且受害者是队友
        return Plugin_Continue;
    
    // 产生血液飞溅效果和流血声音（人质除外）
    if(EntityType == 1 && damage > 0.0)
    {
        float OutputDir[3];
        MakeVectorFromPoints(origin, AttackerOrigin, OutputDir);  
        
        new particle = CreateEntityByName("info_particle_system");
        decl String:name[64];
        if (IsValidEdict(particle))
        {
            GetEntPropString(victim, Prop_Data, "m_iName", name, sizeof(name));
            DispatchKeyValue(particle, "targetname", "cssparticle2");
            DispatchKeyValue(particle, "parentname", name);
            DispatchKeyValue(particle, "effect_name", "blood_impact_red_01_droplets");    // 粒子名称
            DispatchSpawn(particle);
            
            TeleportEntity(particle, origin, OutputDir, NULL_VECTOR);
            
            ActivateEntity(particle);
            AcceptEntityInput(particle, "start");
            CreateTimer(1.0, DeleteParticle, particle);
        }
        EmitSoundToAll("physics/flesh/flesh_squishy_impact_hard4.wav", victim, SNDCHAN_BODY, SNDLEVEL_NORMAL, _, 1.0);
    }
    
    return Plugin_Continue;
}


public Action:DeleteParticle(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classN[64];
        GetEdictClassname(particle, classN, sizeof(classN));
        if (StrEqual(classN, "info_particle_system", false))
        {
            AcceptEntityInput(particle, "Stop" );
            AcceptEntityInput(particle, "Kill");
        }
    }
}


public Action PlayKnifeSound(Handle timer, DataPack pack4)
{
    pack4.Reset(); 
    int SoundType = pack4.ReadCell();
    int myWeapon = pack4.ReadCell();
    int weapon = pack4.ReadCell();
    CloseHandle(pack4);
    
    if(SoundType == 1)
    {
        EmitSoundToAll(HitKnifeSound[myWeapon], weapon, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_STOP, 1.0);
    }
    if(SoundType == 2)
    {
        EmitSoundToAll(KnifeHitWallSound[myWeapon], weapon, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_STOP, 1.0);
    }
    
    return Plugin_Continue;
}


// 检测玩家瞄准的另一个玩家或人质的原点
stock int GetPlayerAimOrigin(int client, float hOrigin[3]) 
{
    float vAngles[3], fOrigin[3];
    GetClientEyePosition(client, fOrigin);
    GetClientEyeAngles(client, vAngles);

    Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayer, client);    // MASK_SOLID : everything that is normally solid

    if(TR_DidHit(trace)) 
    {
        int pEntity = -1;
        TR_GetEndPosition(hOrigin, trace);
        pEntity = TR_GetEntityIndex(trace);
        if(pEntity <= 0)
            return -1;
        if (!IsValidEntity(pEntity))
            return -1;
        char ClassName[32];
        GetEdictClassname(pEntity, ClassName, sizeof(ClassName));
        if(!StrEqual(ClassName, "player") && !StrEqual(ClassName, "hostage_entity"))
            return -1;
        return pEntity;
    }

    CloseHandle(trace);
    return -1;
}


public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data) 
{
    if(entity != data)
        return true;
    else
        return false;
}


// 检测玩家瞄准的另一个玩家或人质的命中组
stock int GetPlayerAimOrigin2(int client, int aimEntity) 
{
    float vAngles[3], fOrigin[3];
    GetClientEyePosition(client, fOrigin);
    GetClientEyeAngles(client, vAngles);

    Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer2, aimEntity); 

    if(TR_DidHit(trace)) 
    {
        int hitgroup = TR_GetHitGroup(trace);
        return hitgroup;
    }

    CloseHandle(trace);
    return -1;
}


public bool TraceEntityFilterPlayer2(int entity, int contentsMask, any data) 
{
    if(entity == data)
        return true;
    else
        return false;
}


// 检测玩家瞄准的物体的原点
stock int GetPlayerAimOrigin3(int client, float hOrigin[3]) 
{
    float vAngles[3], fOrigin[3];
    GetClientEyePosition(client, fOrigin);
    GetClientEyeAngles(client, vAngles);

    Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer3);    // MASK_SHOT : bullets see these as solid

    if(TR_DidHit(trace)) 
    {
        int pEntity = -1;
        TR_GetEndPosition(hOrigin, trace);
        pEntity = TR_GetEntityIndex(trace);
        return pEntity;
    }

    CloseHandle(trace);
    return -2;
}


public bool TraceEntityFilterPlayer3(int entity, int contentsMask) 
{
    return entity > MaxClients;
}


// 检测攻击方向
public int GetDirection(int attacker, int victim)
{
    float attackerOrigin[3], victimAngles[3], victimOrigin[3], vecPoints[3], vecAngles[3];
    char ClassName2[32];
    GetEdictClassname(victim, ClassName2, sizeof(ClassName2));

    // 检测攻击者的坐标
    GetClientEyePosition(attacker, attackerOrigin); 
    // 检测受害者的坐标
    if(StrEqual(ClassName2, "player"))
        GetClientEyePosition(victim, victimOrigin);
    if(StrEqual(ClassName2, "hostage_entity"))
        GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimOrigin);
    // 检测受害者的角度方向
    if(StrEqual(ClassName2, "player"))
        GetClientEyeAngles(victim, victimAngles);
    if(StrEqual(ClassName2, "hostage_entity"))
        GetEntPropVector(victim, Prop_Send, "m_angRotation", victimAngles);
    // 建立从受害者到攻击者的方向向量
    MakeVectorFromPoints(victimOrigin, attackerOrigin, vecPoints);
    GetVectorAngles(vecPoints, vecAngles);
    
    // Differenz
    new diff = RoundFloat(victimAngles[1]) - RoundFloat(vecAngles[1]);
    
    // Correct it
    if (diff < -180)
    {
        diff = 360 + diff;
    }

    if (diff > 180)
    {
        diff = 360 - diff;
    }
    // PrintToChatAll("diff转换后的值：%d 。", diff);
    
    // 检测攻击的方向
    bool RightSide = false;    // 正面攻击
    bool RightBackSide = false;    // 正背面攻击
    bool OtherBackSide = false;    // 其他背面攻击
    bool OtherSide = false;    // 其他方向攻击
    
    // 打中前方
    if (diff >= -22.5 && diff < 22.5)
    {
        RightSide = true;
    }

    // 打中右前方
    else if (diff >= 22.5 && diff < 67.5)
    {
        RightSide = true;
    }

    // 打中右方
    else if (diff >= 67.5 && diff < 112.5)
    {
        OtherSide = false;
    }

    // 打中右后方
    else if (diff >= 112.5 && diff < 157.5)
    {
        OtherBackSide = true;
    }

    // 打中后方
    else if (diff >= 157.5 || diff < -157.5)
    {
        RightBackSide = true;
    }

    // 打中左后方
    else if (diff >= -157.5 && diff < -112.5)
    {
        OtherBackSide = true;
    }

    // 打中左方
    else if (diff >= -112.5 && diff < -67.5)
    {
        OtherSide = true;
    }

    // 打中左前方
    else if (diff >= -67.5 && diff < -22.5)
    {
        RightSide = true;
    }
    
    if(RightSide == true)
        return 1;    // 正面攻击
    if(RightBackSide == true)
        return 2;    // 正背面攻击
    if(OtherBackSide == true)
        return 3;    // 其他背面攻击
    else
        return 0;    // 其他方向攻击
}


public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(isEnabled == false)
        return;
    
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    // new victim_hit_armor = GetEventInt(event, "dmg_armor");
    // new victim_armor = GetEventInt(event, "armor");
    // new hitgroup = GetEventInt(event, "hitgroup");
    
    if((0 < victim <= MAXPLAYERS) && (0 < attacker <= MAXPLAYERS))
    {
        CreateTimer(0.1, Timer_ChangeVictim2, attacker);
    }
    
    return;
}


public Action:Timer_ChangeVictim2(Handle timer, int attacker)
{
    Victim[attacker] = 0;
}


public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
    if(isEnabled == false)
        return;
    
    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        Victim[i] = 0;
    }
    
    return;
}


bool:IsClient(Client, bool:Alive)
{
    return Client <= MaxClients && IsClientConnected(Client) && IsClientInGame(Client) && (Alive && IsPlayerAlive(Client));
}