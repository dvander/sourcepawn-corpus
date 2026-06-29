#pragma semicolon 1

#include <sourcemod>
#include <steamtools>

new Handle:g_hBannedGroups = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Steam Group Banner",
    author = "bl4nk",
    description = "Disallow users from certain Steam groups to join your server",
    version = "1.0.1",
    url = "http://forums.alliedmods.net/"
};

public OnPluginStart() {
    g_hBannedGroups = CreateArray();
    
    RegAdminCmd("sm_bangroup", Command_BanGroup, ADMFLAG_RCON, "sm_bangroup <32-bit group id>");
}

public OnClientAuthorized(iClient, const String:szAuth[]) {
    new iSize = GetArraySize(g_hBannedGroups);
    for (new i = 0; i < iSize; i++) {
        Steam_RequestGroupStatus(iClient, GetArrayCell(g_hBannedGroups, i));
    }
}

public Steam_GroupStatusResult(iClient, iGroup, bool:bMember, bool:bOfficer) {
    if (FindCellInArray(g_hBannedGroups, iGroup) > -1 && (bMember || bOfficer)) {
        KickClient(iClient, "In a banned group");
    }
}

public Action:Command_BanGroup(iClient, iArgCount) {
    if (iArgCount < 1) {
        ReplyToCommand(iClient, "[SM] Usage: sm_bangroup <32-bit group id>");
        return Plugin_Handled;
    }
    
    decl String:szArg1[8];
    GetCmdArg(1, szArg1, sizeof(szArg1));
    
    new iGroup = StringToInt(szArg1);
    if (iGroup) {
        new iIndex = FindCellInArray(g_hBannedGroups, iGroup);
        if (iIndex > -1) {
            RemoveFromArray(g_hBannedGroups, iIndex);
            
            ReplyToCommand(iClient, "[SM] Removed banned Group ID: %i", iGroup);
            
            return Plugin_Handled;
        }
        
        PushArrayCell(g_hBannedGroups, iGroup);
        
        ReplyToCommand(iClient, "[SM] Added banned Group ID: %i", iGroup);
    }
    
    return Plugin_Handled;
}

stock FindCellInArray(Handle:hArray, iValue) {
    new iSize = GetArraySize(hArray);
    for (new i = 0; i < iSize; i++) {
        if (GetArrayCell(hArray, i) == iValue) {
            return iValue;
        }
    }
    
    return -1;
}