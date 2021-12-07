/**
 * ====================
 *     Zombie Riot
 *   File: zombieriot.sp
 *   Author: Greyscale
 * ==================== 
 */

#pragma semicolon 1
#include <sourcemod>
#include <zr>

#define VERSION "1.0"

new offsMoney;

public Plugin:myinfo =
{
    name = "ZCash Empty", 
    author = "Greyscale", 
    description = "Takes all of the zombie's cash on infection", 
    version = VERSION, 
    url = ""
};

public OnPluginStart()
{
    offsMoney = FindSendPropInfo("CCSPlayer", "m_iAccount");
    if (offsMoney == -1)
    {
        SetFailState("Couldn't find \"m_iAccount\"!");
    }
}

public ZR_Zombify(client, bool:mother)
{
    SetEntData(client, offsMoney, 0, 1, true);
}