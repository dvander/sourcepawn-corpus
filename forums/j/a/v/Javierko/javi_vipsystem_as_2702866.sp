#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[CS:GO] VIP system",
	author = "Javierko",
	description = "Add or remove steamids in admins_simple.ini",
	version = "1.0.0",
	url = "https://github.com/javierko"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_addvip", Command_AddVip, ADMFLAG_RCON);
	RegAdminCmd("sm_removevip", Command_RemoveVip, ADMFLAG_RCON);
}

public Action Command_AddVip(int client, int args)
{
    if(args < 2) {
        ReplyToCommand(client, "Use: sm_addvip <steamid> <flag>");
        
        return Plugin_Handled;
    }
    
    char szTarget[64], szFlags[20];
    GetCmdArg(1, szTarget, sizeof(szTarget));
    GetCmdArg(2, szFlags, sizeof(szFlags));
    
    char szFile[256];
    BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");
    
    File fFile = OpenFile(szFile, "at");
    
    fFile.WriteLine("\"%s\" \"%s\"", szTarget, szFlags);
    
    delete fFile;

    LogAction(0, -1, "System added steamid %s into admins_simple.ini", szTarget);
    
    ReloadAdmins();
    
    return Plugin_Handled;
}

public Action Command_RemoveVip(int client, int args)
{
    if(args < 1) {
        ReplyToCommand(client, "Use: sm_removevip <steamid>");

        return Plugin_Handled;
    }
    
    char szFilePath[PLATFORM_MAX_PATH], szFileCopyPath[PLATFORM_MAX_PATH], szAuth[21], szLine[256];

    GetCmdArg(1, szAuth, sizeof(szAuth));
    BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "configs/admins_simple.ini");
    FormatEx(szFileCopyPath, sizeof(szFileCopyPath), "%s.copy", szFilePath);

    File fFile = OpenFile(szFilePath, "rt");
    File fTempFile = OpenFile(szFileCopyPath, "wt");

    bool bFound = false;

    while(!fFile.EndOfFile()) {
        if(!fFile.ReadLine(szLine, sizeof(szLine))) {
            continue;
        }

        TrimString(szLine);

        if(StrContains(szLine, szAuth) == -1) {
            fTempFile.WriteLine(szLine);
        } else {
            bFound = true;
        }
    }

    delete fFile;
    delete fTempFile;

    DeleteFile(szFilePath);
    RenameFile(szFilePath, szFileCopyPath);

    if(bFound) {
        LogAction(0, -1, "System removed steamid %s from admins_simple.ini", szAuth);

        ReloadAdmins();
    } else {
        LogAction(0, -1, "System tryed to remove steamid %s from admins_simple.ini, but not found", szAuth);
    }
    
    return Plugin_Handled;
}

void ReloadAdmins()
{
    DumpAdminCache(AdminCache_Admins, true);

    LogAction(0, -1, "Cache has been refreshed from VIP system plugin.");
}