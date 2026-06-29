#include <sourcemod>   
#include <sdktools>   


#define Version "1.0"   
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY   

#define SOUND_BOMB "physics/plastic/plastic_box_break2.wav"   

public Plugin:myinfo =   
{  
    name = "",   
    author = "",   
    description = "",   
    version = Version,   
    url = ""  
};  

new g_iLaggedMovementO = -1;  

new Float:bomb_pos[3];  
new bomb_timer[MAXPLAYERS + 1];  

new Handle:l4d2_icebomb_time;  
new Handle:l4d2_icebomb_speed;  
new Handle:l4d2_icebomb_type;  
new Handle:l4d2_icebomb_surv;  
/* 手雷名称 */  
//pipe_bomb      土制炸弹   
//molotov        燃烧瓶   
//vomitjar    胆汁液   

//pipe_bomb_projectile    土制炸弹破坏   
//molotov_projectile        燃烧瓶破坏   
//vomitjar_projectile    胆汁液破坏   

public OnPluginStart()  
{  
    decl String:game_name[64];  
    GetGameFolderName(game_name, sizeof(game_name));  
    if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))  
    {  
        SetFailState("只支持L4D2");  
    }  
      
    g_iLaggedMovementO = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");  
      
    l4d2_icebomb_time = CreateConVar("l4d2_icebomb_time", "10", "冻结持续的时间", CVAR_FLAGS);  
    l4d2_icebomb_speed = CreateConVar("l4d2_icebomb_speed", "0.5", "冻结时的移动速度(0 = 完全冻结,无法动弹)", CVAR_FLAGS);  
    l4d2_icebomb_type = CreateConVar("l4d2_icebomb_type", "1", "可以使用冰冻手雷的物品(0 = 全部 1 = 土制炸弹 2 = 燃烧瓶 3 = 胆汁液)", CVAR_FLAGS);  
    l4d2_icebomb_surv = CreateConVar("l4d2_icebomb_surv", "0", "冰冻手雷对幸存者是否有效(0 = 无效 1 = 有效)", CVAR_FLAGS);  
      
    AutoExecConfig(true, "l4d2_Ice_Bomb");  
}  


/* 判断玩家是否有效 */  
public bool:IsValidPlayer(client)  
{  
    if (client < 1 || client > MaxClients)return false;  
    if (!IsClientInGame(client))return false;  
      
    return true;  
}  

/* 事件-实体被破坏 */  
public OnEntityDestroyed(entity)  
{  
    if (entity <= MaxClients || entity > 2048 || !IsValidEdict(entity) || !IsValidEntity(entity))return;  
      
    decl String:classname[32];  
      
    new type = GetConVarInt(l4d2_icebomb_type);  
      
    //获取实体所有者   
    //new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    //CheckCommandAccess(client, "sm_blahblah", ADMFLAG_UNBAN);
	 
    //获取实体类名   
    GetEdictClassname(entity, classname, 32);
      
    //识别实体类名   
    if (StrEqual(classname, "pipe_bomb_projectile", false))  
    {  
        if (type == 1 || type == 0)  
        {  
            //获取实体坐标   
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", bomb_pos);  
            Freeze_Points();  
        }  
    }  
    else if (StrEqual(classname, "molotov_projectile", false))  
    {  
        if (type == 2 || type == 0)  
        {  
            //获取实体坐标   
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", bomb_pos);  
            Freeze_Points();  
        }  
    }  
    else if (StrEqual(classname, "vomitjar_projectile", false))  
    {  
        if (type == 3 || type == 0)  
        {  
            //获取实体坐标   
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", bomb_pos);  
            Freeze_Points();  
        }  
    }  
      
    //PrintToChatAll("武器: %s 所有者: %N", classname, client);   
}  

Freeze_Points() 
{  
    new Float:entpos[3];  
    new Float:distance;  
      
    //开始循环判断   
    for (new i = 1; i <= MaxClients; i++)  
    {  
        //判断玩家是否在游戏且实体是有效的   
        if (!IsClientInGame(i) || !IsValidEntity(i))  
            continue;  
        if (!IsPlayerAlive(i))  
            continue;  
        if (GetConVarInt(l4d2_icebomb_surv) == 0)  
        {  
            if (GetClientTeam(i) == 2)  
                continue;  
        }  
        //获取实体坐标   
        GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos);  
        //对比距离   
        distance = GetVectorDistance(bomb_pos, entpos);  
        if (distance <= 250)  
        {  
            //PrintToChatAll("进入冰冻范围: %N", i);   
            SetEntDataFloat(i, g_iLaggedMovementO, GetConVarFloat(l4d2_icebomb_speed), true);  
            ScreenFade(i, 0, 50, 200, 100, 1000, 1);  
            //运行计时器   
            bomb_timer[i] = 0;  
            CreateTimer(1.0, Ice_Bomb_Timer, i, TIMER_REPEAT);  
        }  
    }  
      
}  

public Action:Ice_Bomb_Timer(Handle:timer, any:client)  
{  
    if (client <= 0 || !IsClientInGame(client) || !IsValidEntity(client) || !IsPlayerAlive(client) || IsPlayerGhost(client))
    {  
        //PrintToChatAll("无效解冻: %N", client);   
        bomb_timer[client] = 0;  
//      SetEntDataFloat(client, g_iLaggedMovementO, 1.0, true);  
        return Plugin_Stop;  
    }  
      
    bomb_timer[client] += 1;  
    if (bomb_timer[client] >= GetConVarInt(l4d2_icebomb_time))  
    {  
        //PrintToChatAll("正常解冻: %N", client);   
        bomb_timer[client] = 0;  
        SetEntDataFloat(client, g_iLaggedMovementO, 1.0, true);  
        return Plugin_Stop;  
    }  
      
    new Float:entpos[3]  
    new Float:effectpos[3];  
    //获取实体坐标   
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", entpos);  
    effectpos[0] = entpos[0];  
    effectpos[1] = entpos[1];  
    effectpos[2] = entpos[2] + 90;  
    ShowParticle(effectpos, "item_defibrillator_body", 1.0);  
    AttachParticle(client, "water_child_water5");  
    SetEntDataFloat(client, g_iLaggedMovementO, GetConVarFloat(l4d2_icebomb_speed), true);  
    ScreenFade(client, 0, 50, 200, 100, 1000, 1);  
    EmitSoundToClient(client, SOUND_BOMB);  
      
    return Plugin_Continue;  
}  

//屏幕颜色   
public ScreenFade(target, red, green, blue, alpha, duration, type)  
{  
    new Handle:msg = StartMessageOne("Fade", target);  
    BfWriteShort(msg, 500);  
    BfWriteShort(msg, duration);  
    if (type == 0)  
        BfWriteShort(msg, (0x0002 | 0x0008));  
    else  
        BfWriteShort(msg, (0x0001 | 0x0010));  
    BfWriteByte(msg, red);  
    BfWriteByte(msg, green);  
    BfWriteByte(msg, blue);  
    BfWriteByte(msg, alpha);  
    EndMessage();  
      
}  


/* 显示你想要的粒子效果 */  
public ShowParticle(Float:pos[3], String:particlename[], Float:time)  
{  
    new particle = CreateEntityByName("info_particle_system");  
    if (IsValidEdict(particle))  
    {  
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);  
        DispatchKeyValue(particle, "effect_name", particlename);  
        DispatchKeyValue(particle, "targetname", "particle");  
        DispatchSpawn(particle);  
        ActivateEntity(particle);  
        AcceptEntityInput(particle, "start");  
        CreateTimer(time, DeleteParticles, particle);  
    }  
}  

/* 删除粒子 */  
public Action:DeleteParticles(Handle:timer, any:particle)  
{  
    if (IsValidEntity(particle))  
    {  
        new String:classname[64];  
        GetEdictClassname(particle, classname, sizeof(classname));  
        if (StrEqual(classname, "info_particle_system", false))  
            RemoveEdict(particle);  
    }  
}  

/* 连接粒子 */  
public AttachParticle(ent, String:particleType[])  
{  
    decl String:tName[64];  
    new particle = CreateEntityByName("info_particle_system");  
    if (IsValidEdict(particle))  
    {  
        new Float:pos[3];  
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);  
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);  
        GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));  
        DispatchKeyValue(particle, "targetname", "tf2particle");  
        DispatchKeyValue(particle, "parentname", tName);  
        DispatchKeyValue(particle, "effect_name", particleType);  
        DispatchSpawn(particle);  
        SetVariantString(tName);  
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);  
        ActivateEntity(particle);  
        AcceptEntityInput(particle, "start");  
    }  
}  

/* 预先缓存 */  
public PrecacheParticle(String:particlename[])  
{  
    new particle = CreateEntityByName("info_particle_system");  
    if (IsValidEdict(particle))  
    {  
        DispatchKeyValue(particle, "effect_name", particlename);  
        DispatchKeyValue(particle, "targetname", "particle");  
        DispatchSpawn(particle);  
        ActivateEntity(particle);  
        AcceptEntityInput(particle, "start");  
        CreateTimer(0.01, DeleteParticles, particle);  
    }  
}  

public OnMapStart()  
{  
    //预缓存粒子特效   
    PrecacheParticle("item_defibrillator_body");  
    PrecacheParticle("water_child_water5");  
    //预缓存音效文件   
    PrecacheSound(SOUND_BOMB, true);  
}

/**
* Validates if the client is a ghost.
*
* @param client Client index.
* @return True if client is a ghost, false otherwise.
*/
bool IsPlayerGhost(int client)
{
return GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1;
}