#include <tf2items>

#pragma newdecls required
#pragma semicolon 1

public Action TF2Items_OnGiveNamedItem(int iClient, char[] szClassName, int iItemDefinitionIndex, Handle &hItem) {
    return (iItemDefinitionIndex == 1179) ?
        Plugin_Handled : Plugin_Continue;
}