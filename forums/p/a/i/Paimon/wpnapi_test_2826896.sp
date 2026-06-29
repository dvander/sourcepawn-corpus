/**
 * @Author: 我是派蒙啊
 * @Last Modified by:   我是派蒙啊
 * @Create Date: 2024-08-17 10:25:50
 * @Last Modified time: 2024-08-17 10:37:24
 * @Github: https://github.com/Paimon-Kawaii
 */

#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#include <paiutils>

#define VERSION ""

public Plugin myinfo =
{
    name = "wpnapi_test",
    author = "我是派蒙啊",
    description = "",
    version = VERSION,
    url = "https://github.com/Paimon-Kawaii"
};

#define MAXSIZE MaxPlayers + 1

#undef REQUIRE_PLUGIN
#include <weapon_action_api>

public Action Player_OnSwitchToWeapon(int client, int weapon, int param)
{
    PrintToChatAll("Switch detect");
    char buffer1[32], buffer2[32];
    int equip = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (IsValidEdict(equip) && IsValidEdict(weapon))
    {
        GetEntityClassname(equip, buffer1, sizeof(buffer1));
        GetEntityClassname(weapon, buffer2, sizeof(buffer2));
    }
    else return Plugin_Continue;

    PrintToChatAll("%N switch %s to %s", client, buffer1, buffer2);
    PrintToChatAll("Handled");

    return Plugin_Handled;
}