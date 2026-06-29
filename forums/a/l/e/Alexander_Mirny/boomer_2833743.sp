#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo = 
{
    name = "boomer",
    author = "Alexander Mirny",
    description = "Когда толстяк заблевал вас у вас скрываются все HUD, и наносит вам урон.",
    version = "1.0",
    url = "https://vk.com/id602817125"
};

#define HIDEHUD_ALL 127 // Значение, скрывающее все элементы HUD

public OnPluginStart()
{
    HookEvent("player_now_it", PlayerNowIt);
}       

public Action:PlayerNowIt(Handle:event, const String:name[], bool:dontBroadcast) 
{
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (!IsValidClient(victim) || !IsPlayerAlive(victim))
        return Plugin_Continue;
    
    // Нанесение урона (существующий код)
    switch(GetRandomInt(0, 5))
    {
        case 0: applyDamage(15, victim, attacker, "Рвота толстяка ядовита -15HP");
        case 1: applyDamage(20, victim, attacker, "Рвота толстяка ядовита -20HP");
        case 2: applyDamage(35, victim, attacker, "Рвота толстяка ядовита -35HP");
        case 3: applyDamage(46, victim, attacker, "Рвота толстяка ядовита -46HP");
        case 4: applyDamage(51, victim, attacker, "Рвота толстяка ядовита -51HP");
    }
    
    // Скрытие HUD
    int originalHideHUD = GetEntProp(victim, Prop_Send, "m_iHideHUD");
    SetEntProp(victim, Prop_Send, "m_iHideHUD", HIDEHUD_ALL);
    
    // Создание таймера для восстановления HUD
    Handle hData = CreateDataPack();
    WritePackCell(hData, victim);
    WritePackCell(hData, originalHideHUD);
    CreateTimer(8.0, Timer_RestoreHUD, hData);
    
    return Plugin_Continue;
}

// Таймер восстановления HUD
public Action Timer_RestoreHUD(Handle timer, Handle hData)
{
    ResetPack(hData);
    int client = ReadPackCell(hData);
    int originalHUD = ReadPackCell(hData);
    CloseHandle(hData);
    
    if (IsValidClient(client))
    {
        SetEntProp(client, Prop_Send, "m_iHideHUD", originalHUD);
    }
}

// Проверка валидности клиента
bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

// Модифицированная функция нанесения урона с сообщением
static applyDamage(damage, victim, attacker, const String:message[])
{ 
    PrintToChat(victim, "\x04%s", message);
    
    new Handle:dataPack = CreateDataPack();
    WritePackCell(dataPack, damage);  
    WritePackCell(dataPack, victim);
    WritePackCell(dataPack, attacker);
    
    CreateTimer(0.10, timer_stock_applyDamage, dataPack);
}

// Существующий обработчик урона
public Action:timer_stock_applyDamage(Handle:timer, Handle:dataPack)
{
    ResetPack(dataPack);
    new damage = ReadPackCell(dataPack);  
    new victim = ReadPackCell(dataPack);
    new attacker = ReadPackCell(dataPack);
    CloseHandle(dataPack);
    
    decl Float:victimPos[3], String:strDamage[16], String:strDamageTarget[16];
    
    if (!IsValidClient(victim)) return;
    GetClientEyePosition(victim, victimPos);
    IntToString(damage, strDamage, sizeof(strDamage));
    Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
    
    new entPointHurt = CreateEntityByName("point_hurt");
    if(!entPointHurt) return;

    DispatchKeyValue(victim, "targetname", strDamageTarget);
    DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
    DispatchKeyValue(entPointHurt, "Damage", strDamage);
    DispatchSpawn(entPointHurt);
    
    TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(entPointHurt, "Hurt", (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
    
    DispatchKeyValue(entPointHurt, "classname", "point_hurt");
    DispatchKeyValue(victim, "targetname", "null");
    RemoveEdict(entPointHurt);
}