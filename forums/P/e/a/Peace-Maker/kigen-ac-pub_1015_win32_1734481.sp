new PlVers:__version = 5;
new Float:NULL_VECTOR[3];
new String:NULL_STRING[1];
new Extension:__ext_core = 64;
new MaxClients;
new SharedPlugin:__pl_kac = 272;
new Extension:__ext_sdktools = 348;
new String:CTag[6][0];
new String:CTagCode[6][4] =
{
    "",
    "",
    "",
    "",
    "",
    ""
}
new bool:CTagReqSayText2[6] =
{
    0, 0, 1, 1, 1, 0
}
new bool:CEventIsHooked;
new bool:CSkipList[66];
new bool:CProfile_Colors[6] =
{
    1, 1, 0, 0, 0, 0
}
new CProfile_TeamIndex[6] =
{
    -1, ...
}
new bool:CProfile_SayText2;
new Extension:__ext_sdkhooks = 1140;
public Plugin:myinfo =
{
    name = "Kigen's Anti-Cheat",
    description = "'CS:S v.34' The greatest thing since sliced pie",
    author = "Kigen, GoD-Tony, psychonic, GoDtm666 and killer666",
    version = "1.2.2.2",
    url = "www.SourceTM.com"
};
new GameType:g_Game;
new Handle:g_hCvarWelcomeMsg;
new Handle:g_hCvarAdminSoundsMsg;
new Handle:g_hCvarBanDuration;
new Handle:g_hCvarLogVerbose;
new String:g_sLogPath[64];
new bool:g_bSDKHooksLoaded;
new bool:g_bMapStarted;
new bool:g_bWelcomeMsg;
new bool:g_bEnabledAdminSounds;
new bool:g_bCvarLogVerbose;
new g_iBanDuration;
new String:g_sBadPlugins[13][0];
new String:g_sBadExtensions[3][28] =
{
    "extensions/sdkhooks.ext.dll",
    "extensions/sdkhooks.ext.so",
    "gamedata/sdkhooks.games.txt"
}
new Handle:g_hCVarAimBot;
new Handle:g_hAimBotDeviation;
new Handle:g_hCvarAimbotBan;
new Handle:g_IgnoreWeapons;
new bool:g_bAimbotEnabled;
new Float:g_fAimBotDeviation;
new Float:g_fEyeAngles[66][32][3];
new g_iEyeIndex[66];
new g_iAimDetections[66];
new g_iAimbotBan;
new Handle:g_hCvarIpAlreadyEnable;
new bool:g_bEnabledIpAlready;
new Handle:g_hTimerAutoTrigger;
new Handle:g_hCvarTriggerDetections;
new Handle:g_hCvarMethod;
new Handle:g_hCvarAutoTriggerBlock;
new bool:g_bEnabledAutoTrigger;
new bool:g_bEnabledAutoTriggerBunnyHop;
new bool:g_bEnabledAutoTriggerAutoFire;
new g_iAutoTriggerDetections;
new g_iAutoTriggerBlock;
new g_iDetections[2][66];
new g_iAttackMax = 66;
new Handle:g_hCvarConnectSpam;
new Float:fSpamTime;
new Handle:g_hClientConnections;
new Handle:g_hIgnoreList;
new g_iNameChanges[66];
new Handle:g_hCVarClientNameProtect;
new bool:g_bClientNameProtect;
new bool:g_bMapStartedWait;
new Handle:g_hBlockedCmds;
new Handle:g_hIgnoredCmds;
new g_iCmdSpam = 30;
new g_iCmdCount[66];
new Handle:g_hCvarCmdSpam;
new bool:g_bSpamCmds;
new bool:g_bLogCmds;
new String:g_sCmdLogPath[64];
new Handle:g_hCVarCmdLog;
new Handle:g_hCVarCVarsEnabled;
new bool:g_bCVarCVarsEnabled;
new Handle:g_hSvCVarChtForceEnable;
new bool:g_bSvCVarChtForce;
new Handle:g_hCVars;
new Handle:g_hCVarIndex;
new Handle:g_hCurrentQuery[66];
new Handle:g_hReplyTimer[66];
new Handle:g_hPeriodicTimer[66];
new String:g_sQueryResult[4][0];
new g_iCurrentIndex[66];
new g_iRetryAttempts[66];
new g_iSize;
new Handle:g_hCvarRconPass;
new String:g_sRconRealPass[32];
new bool:g_bRconLocked;
new Handle:g_hCVarEyeType;
new bool:g_bEnabledEye;
new g_iEyeBlock;
new Float:g_fDetectedTime[66];
new Handle:g_hCVarSpinHack;
new Handle:g_hSpinLoop;
new bool:g_bSpinHackEnabled;
new Float:g_fPrevAngle[66];
new Float:g_fAngleDiff[66];
new Float:g_fAngleBuffer;
new Float:g_fSensitivity[66];
new g_iSpinCount[66];
new g_iSpinHackMode;
new Handle:g_hCVarAntiRespawn;
new Handle:g_hClientSpawned;
new g_iClientClass[66] =
{
    -1, ...
}
new bool:g_bAntiRespawn;
new bool:g_bClientMapStarted;
new Handle:g_hCvarRestartGame;
new Handle:g_hCVarAntiFlash;
new bool:g_bFlashEnabled;
new g_iFlashDuration = -1;
new g_iFlashAlpha = -1;
new Float:g_fFlashedUntil[66];
new bool:g_bFlashHooked;
new Handle:g_hCvarWallhack;
new Handle:g_hTimeToTick;
new bool:g_bEnabled;
new bool:g_bIsVisible[66][66];
new bool:g_bProcess[66];
new bool:g_bIgnore[66];
new g_iWeaponOwner[2048];
new g_iTeam[66];
new Float:g_vMins[66][3];
new Float:g_vMaxs[66][3];
new Float:g_vAbsCentre[66][3];
new Float:g_vEyePos[66][3];
new Float:g_vEyeAngles[66][3];
new g_iCurrentThread = 1;
new g_iThread[66] =
{
    1, ...
}
new g_iCacheTicks;
new g_iNumChecks;
new g_iTickCount;
new g_iCmdTickCount[66];
new Float:g_fTickDelta;
new bool:g_bIsMod;
new bool:g_bFarEspEnabled;
new UserMsg:g_msgUpdateRadar = -1;
new Handle:g_hRadarTimer;
new bool:g_bPlayerSpotted[66];
new g_iPlayerManager = -1;
new g_iPlayerSpotted = -1;
new Handle:g_hCVarSpeedhack;
new bool:g_bSpeedEnabled;
new Handle:g_hCvarFutureTicks;
new g_iShTickCount[66];
new Handle:hShTimerResTicks;
new g_iTickRate;
new Handle:g_hCVarAntiSmoke;
new bool:g_bSmokeEnabled;
new Handle:g_hSmokeLoop;
new Handle:g_hSmokes;
new bool:g_bIsInSmoke[66];
new bool:g_bSmokeHooked;
new Extension:__ext_smsock = 128280;
new Handle:g_hCVarNetEnabled;
new bool:g_bCVarNetEnabled;
new String:AutoUpdater_Host[6] = "kigenac.sourcetm.com";
new String:AutoUpdater_Ip[4] = "91.218.229.98";
new String:AutoUpdater_Url[9] = "/update/kigen-ac-pub/version.txt";
new AutoUpdater_Port = 80;
new Handle:g_hCVarNetUseUpdate;
new Handle:g_hCVarNetAllowUpdateToBeta;
new bool:g_bCVarNetUseUpdate;
new bool:g_bCVarNetAllowUpdateToBeta;
new Handle:g_hUpdateSocket;
new Handle:g_hUpdateTimer;
new Handle:g_hUpdateFile;
new Handle:g_hUpdateList;
new AutoUpdater_States:g_iUpdateState;
new g_iUpdateFile;
new g_iUpdateFilesCount;
new bool:g_iUpdateFileGotHeader;
new bool:g_bMessageShown;
new String:g_sUpdateFile[64];
new String:g_sUpdateFileURI[64];
new String:ServersList_Host[6] = "kigenac.sourcetm.com";
new String:ServersList_Ip[4] = "91.218.229.98";
new String:ServersList_AddUrl[3] = "/list.add/";
new String:ServersList_Url[8] = "http://kigenac.sourcetm.com/";
new ServersList_Port = 80;
new Handle:g_hListSocket;
new Handle:g_OnCheatDetected;
public __ext_core_SetNTVOptional()
{
    MarkNativeAsOptional("GetFeatureStatus");
    MarkNativeAsOptional("RequireFeature");
    MarkNativeAsOptional("AddCommandListener");
    MarkNativeAsOptional("RemoveCommandListener");
    VerifyCoreVersion();
    return 0;
}

Float:operator*(Float:,_:)(Float:oper1, oper2)
{
    return FloatMul(oper1, float(oper2));
}

Float:operator-(Float:,_:)(Float:oper1, oper2)
{
    return FloatSub(oper1, float(oper2));
}

bool:operator==(Float:,Float:)(Float:oper1, Float:oper2)
{
    return FloatCompare(oper1, oper2) == 0;
}

bool:operator!=(Float:,Float:)(Float:oper1, Float:oper2)
{
    return FloatCompare(oper1, oper2) != 0;
}

bool:operator>(Float:,Float:)(Float:oper1, Float:oper2)
{
    return FloatCompare(oper1, oper2) > 0;
}

bool:operator>(Float:,_:)(Float:oper1, oper2)
{
    return FloatCompare(oper1, float(oper2)) > 0;
}

bool:operator<(Float:,Float:)(Float:oper1, Float:oper2)
{
    return FloatCompare(oper1, oper2) < 0;
}

bool:operator<(Float:,_:)(Float:oper1, oper2)
{
    return FloatCompare(oper1, float(oper2)) < 0;
}

bool:operator<=(Float:,Float:)(Float:oper1, Float:oper2)
{
    return FloatCompare(oper1, oper2) <= 0;
}

bool:operator<=(Float:,_:)(Float:oper1, oper2)
{
    return FloatCompare(oper1, float(oper2)) <= 0;
}

AddVectors(Float:vec1[3], Float:vec2[3], Float:result[3])
{
    result[0] = FloatAdd(vec1[0], vec2[0]);
    result[4] = FloatAdd(vec1[4], vec2[4]);
    result[8] = FloatAdd(vec1[8], vec2[8]);
    return 0;
}

SubtractVectors(Float:vec1[3], Float:vec2[3], Float:result[3])
{
    result[0] = FloatSub(vec1[0], vec2[0]);
    result[4] = FloatSub(vec1[4], vec2[4]);
    result[8] = FloatSub(vec1[8], vec2[8]);
    return 0;
}

ScaleVector(Float:vec[3], Float:scale)
{
    new var1 = vec;
    var1[0] = FloatMul(var1[0], scale);
    new var2 = vec[4];
    var2 = FloatMul(var2, scale);
    new var3 = vec[8];
    var3 = FloatMul(var3, scale);
    return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
    return strcmp(str1, str2, caseSensitive) == 0;
}

CharToLower(chr)
{
    if (IsCharUpper(chr)) {
        return chr | 32;
    }
    return chr;
}

FindCharInString(String:str[], c, bool:reverse)
{
    new i = 0;
    new len = strlen(str);
    if (!reverse) {
        i = 0;
        while (i < len) {
            if (c == str[i]) {
                return i;
            }
            i++;
        }
    } else {
        i = len + -1;
        while (0 <= i) {
            if (c == str[i]) {
                return i;
            }
            i--;
        }
    }
    return -1;
}

ExplodeString(String:text[], String:split[], String:buffers[][], maxStrings, maxStringLength, bool:copyRemainder)
{
    new reloc_idx = 0;
    new idx = 0;
    new total = 0;
    new var1;
    if (maxStrings < 1) {
        return 0;
    }
    new var2 = SplitString(text[reloc_idx], split, buffers[total], maxStringLength);
    idx = var2;
    while (var2 != -1) {
        reloc_idx = idx + reloc_idx;
        total++;
        if (maxStrings == total) {
            if (copyRemainder) {
                strcopy(buffers[total + -1], maxStringLength, text[reloc_idx - idx]);
            }
            return total;
        }
    }
    total++;
    strcopy(buffers[total], maxStringLength, text[reloc_idx]);
    return total;
}

bool:WriteFileCell(Handle:hndl, data, size)
{
    decl array[1];
    array[0] = data;
    return WriteFile(hndl, array, 1, size);
}


/* ERROR! Das Objekt des Typs "Lysis.DReturn" kann nicht in Typ "Lysis.DJumpCondition" umgewandelt werden. */
 function "IsValidConVarChar" (number 19)
Handle:StartMessageOne(String:msgname[], client, flags)
{
    decl players[1];
    players[0] = client;
    return StartMessage(msgname, players, 1, flags);
}

PrintToChatAll(String:format[])
{
    decl String:buffer[192];
    new i = 1;
    while (i <= MaxClients) {
        if (IsClientInGame(i)) {
            SetGlobalTransTarget(i);
            VFormat(buffer, 192, format, 2);
            PrintToChat(i, "%s", buffer);
            i++;
        }
        i++;
    }
    return 0;
}

ShowMOTDPanel(client, String:title[], String:msg[], type)
{
    decl String:num[4];
    new Handle:Kv = CreateKeyValues("data", "", "");
    IntToString(type, num, 3);
    KvSetString(Kv, "title", title);
    KvSetString(Kv, "type", num);
    KvSetString(Kv, "msg", msg);
    ShowVGUIPanel(client, "info", Kv, true);
    CloseHandle(Kv);
    return 0;
}

GetPluginBasename(Handle:plugin, String:buffer[], maxlength)
{
    GetPluginFilename(plugin, buffer, maxlength);
    new check = -1;
    new var2 = FindCharInString(buffer, 47, true);
    check = var2;
    new var1;
    if (var2 == -1) {
        Format(buffer, maxlength, "%s", buffer[check + 1]);
    }
    return 0;
}


/* ERROR! Das Objekt des Typs "Lysis.DReturn" kann nicht in Typ "Lysis.DJumpCondition" umgewandelt werden. */
 function "IsClientNew" (number 24)
bool:GetClientAbsVelocity(client, Float:velocity[3])
{
    static offset = -1;
    new var1;
    if (offset == -1) {
        ZeroVector(velocity);
        return false;
    }
    GetEntDataVector(client, offset, velocity);
    return true;
}

ZeroVector(Float:vec[3])
{
    vec[8] = 0;
    vec[4] = 0;
    vec[0] = 0;
    return 0;
}


/* ERROR! unknown operator */
 function "IsVectorZero" (number 27)
IPToLong(String:ip[])
{
    decl String:pieces[16][4];
    if (ExplodeString(ip, ".", pieces, 4, 4, false) != 4) {
        return 0;
    }
    return StringToInt(pieces[12], 10) | StringToInt(pieces[8], 10) << 8 | StringToInt(pieces[4], 10) << 16 | StringToInt(pieces[0][pieces], 10) << 24;
}

LongToIP(ip, String:buffer[], size)
{
    FormatEx(buffer, size, "%d.%d.%d.%d", ip >>> 24 & 255, ip >>> 16 & 255, ip >>> 8 & 255, ip & 255);
    return 0;
}

Float:MT_GetRandomFloat(Float:min, Float:max)
{
    return FloatAdd(FloatMul(GetURandomFloat(), FloatSub(max, min)), min);
}

BfWriteSBitLong(Handle:bf, data, numBits)
{
    new i = 0;
    while (i < numBits) {
        BfWriteBool(bf, !!1 << i & data);
        i++;
    }
    return 0;
}

EmitSoundToClient(client, String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
    decl clients[1];
    clients[0] = client;
    new var1;
    if (entity == -2) {
        var1 = client;
    } else {
        var1 = entity;
    }
    entity = var1;
    EmitSound(clients, 1, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
    return 0;
}

AddFileToDownloadsTable(String:filename[])
{
    static table = -1;
    if (table == -1) {
        table = FindStringTable("downloadables");
    }
    new bool:save = LockStringTables(false);
    AddToStringTable(table, filename, "", -1);
    LockStringTables(save);
    return 0;
}

CPrintToChat(client, String:szMessage[])
{
    new var1;
    if (client <= 0) {
        ThrowError("Invalid client index %d", client);
    }
    if (!IsClientInGame(client)) {
        ThrowError("Client %d is not in game", client);
    }
    decl String:szBuffer[252];
    decl String:szCMessage[252];
    SetGlobalTransTarget(client);
    Format(szBuffer, 250, "%s", szMessage);
    VFormat(szCMessage, 250, szBuffer, 3);
    new index = CFormat(szCMessage, 250, -1);
    if (index == -1) {
        PrintToChat(client, szCMessage);
    } else {
        CSayText2(client, index, szCMessage);
    }
    return 0;
}

CRemoveTags(String:szMessage[], maxlength)
{
    new i = 0;
    while (i < 6) {
        ReplaceString(szMessage, maxlength, CTag[i][0][0], "", true);
        i++;
    }
    ReplaceString(szMessage, maxlength, "{teamcolor}", "", true);
    return 0;
}

CFormat(String:szMessage[], maxlength, author)
{
    if (!CEventIsHooked) {
        CSetupProfile();
        HookEvent("server_spawn", EventHook:105, EventHookMode:2);
        CEventIsHooked = 1;
    }
    new iRandomPlayer = -1;
    if (author != -1) {
        if (CProfile_SayText2) {
            ReplaceString(szMessage, maxlength, "{teamcolor}", "", true);
            iRandomPlayer = author;
        } else {
            ReplaceString(szMessage, maxlength, "{teamcolor}", CTagCode[4][0], true);
        }
    } else {
        ReplaceString(szMessage, maxlength, "{teamcolor}", "", true);
    }
    new i = 0;
    while (i < 6) {
        if (!(StrContains(szMessage, CTag[i][0][0], true) == -1)) {
            if (!CProfile_Colors[i][0][0]) {
                ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[4][0], true);
            } else {
                if (!CTagReqSayText2[i][0][0]) {
                    ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[i][0][0], true);
                }
                if (!CProfile_SayText2) {
                    ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[4][0], true);
                }
                if (iRandomPlayer == -1) {
                    iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i][0][0]);
                    if (iRandomPlayer == -2) {
                        ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[4][0], true);
                    } else {
                        ReplaceString(szMessage, maxlength, CTag[i][0][0], CTagCode[i][0][0], true);
                    }
                }
                ThrowError("Using two team colors in one message is not allowed");
            }
        }
        i++;
    }
    return iRandomPlayer;
}

CFindRandomPlayerByTeam(color_team)
{
    if (color_team) {
        new i = 1;
        while (i <= MaxClients) {
            new var1;
            if (IsClientInGame(i)) {
                return i;
            }
            i++;
        }
        return -2;
    }
    return 0;
}

CSayText2(client, author, String:szMessage[])
{
    new Handle:hBuffer = StartMessageOne("SayText2", client, 0);
    BfWriteByte(hBuffer, author);
    BfWriteByte(hBuffer, 1);
    BfWriteString(hBuffer, szMessage);
    EndMessage();
    return 0;
}

CSetupProfile()
{
    decl String:szGameName[32];
    GetGameFolderName(szGameName, 30);
    if (StrEqual(szGameName, "cstrike", false)) {
        CProfile_Colors[8] = 1;
        CProfile_Colors[12] = 1;
        CProfile_Colors[16] = 1;
        CProfile_Colors[20] = 1;
        CProfile_TeamIndex[8] = 0;
        CProfile_TeamIndex[12] = 2;
        CProfile_TeamIndex[16] = 3;
        CProfile_SayText2 = 1;
    } else {
        if (StrEqual(szGameName, "tf", false)) {
            CProfile_Colors[8] = 1;
            CProfile_Colors[12] = 1;
            CProfile_Colors[16] = 1;
            CProfile_Colors[20] = 1;
            CProfile_TeamIndex[8] = 0;
            CProfile_TeamIndex[12] = 2;
            CProfile_TeamIndex[16] = 3;
            CProfile_SayText2 = 1;
        }
        new var1;
        if (StrEqual(szGameName, "left4dead", false)) {
            CProfile_Colors[8] = 1;
            CProfile_Colors[12] = 1;
            CProfile_Colors[16] = 1;
            CProfile_Colors[20] = 1;
            CProfile_TeamIndex[8] = 0;
            CProfile_TeamIndex[12] = 3;
            CProfile_TeamIndex[16] = 2;
            CProfile_SayText2 = 1;
        }
        if (StrEqual(szGameName, "hl2mp", false)) {
            if (GetConVarBool(FindConVar("mp_teamplay"))) {
                CProfile_Colors[12] = 1;
                CProfile_Colors[16] = 1;
                CProfile_Colors[20] = 1;
                CProfile_TeamIndex[12] = 3;
                CProfile_TeamIndex[16] = 2;
                CProfile_SayText2 = 1;
            } else {
                CProfile_SayText2 = 0;
                CProfile_Colors[20] = 1;
            }
        }
        if (StrEqual(szGameName, "dod", false)) {
            CProfile_Colors[20] = 1;
            CProfile_SayText2 = 0;
        }
        if (GetUserMessageId("SayText2") == -1) {
            CProfile_SayText2 = 0;
        }
        CProfile_Colors[12] = 1;
        CProfile_Colors[16] = 1;
        CProfile_TeamIndex[12] = 2;
        CProfile_TeamIndex[16] = 3;
        CProfile_SayText2 = 1;
    }
    return 0;
}

public Action:CEvent_MapStart(Handle:event, String:name[], bool:dontBroadcast)
{
    CSetupProfile();
    new i = 1;
    while (i <= MaxClients) {
        CSkipList[i] = 0;
        i++;
    }
    return Action:0;
}

public __ext_sdkhooks_SetNTVOptional()
{
    MarkNativeAsOptional("SDKHook");
    MarkNativeAsOptional("SDKHookEx");
    MarkNativeAsOptional("SDKUnhook");
    MarkNativeAsOptional("SDKHooks_TakeDamage");
    MarkNativeAsOptional("SDKHooks_DropWeapon");
    return 0;
}

public DelBadExtensionsServerRestart_OnConfigsExecutedt()
{
    decl String:BadExtensionsBinare[512];
    new bool:ExtsWarnServerKill = 0;
    new i = 0;
    while (i < 3) {
        BuildPath(PathType:0, BadExtensionsBinare, 512, "%s", g_sBadExtensions[i][0][0]);
        if (FileExists(BadExtensionsBinare, false)) {
            if (FileExists(BadExtensionsBinare, false)) {
                DeleteFile(BadExtensionsBinare);
                KAC_Log("Was removed old SDK Hooks (%s), the old version SDK Hooks not suitable for correct operation of %s", g_sBadExtensions[i][0][0], "Kigen's Anti-Cheat");
            }
            if (!ExtsWarnServerKill) {
                ExtsWarnServerKill = 1;
                i++;
            }
            i++;
        }
        i++;
    }
    if (ExtsWarnServerKill) {
        KAC_Log("Fatal error Extensions SDK Hooks!!");
        KAC_Log("Download the latest version of the SDK Hooks working on this page http://forum.sourcetm.com/index.php?showtopic=41");
        KAC_Log("After 10 seconds the server will be automatically turned off.");
        PrintToServer("\n\n\n[KAC] [SM] Fatal error Extensions SDK Hooks!!");
        PrintToServer("[KAC] [SM] After 10 seconds the server will be automatically turned off.\n");
        CreateTimer(10, Timer_ErrorServerKill, any:0, 0);
    }
    return 0;
}

public Action:Timer_ErrorServerKill(Handle:timer)
{
    KAC_Log("Shutting down the server.");
    InsertServerCommand("_restart");
    return Action:0;
}

public UnloadBadPlugins_OnConfigsExecuted()
{
    decl String:pluginfile[512];
    new i = 0;
    while (i < 13) {
        BuildPath(PathType:0, pluginfile, 512, "plugins/%s", g_sBadPlugins[i][0][0]);
        if (FileExists(pluginfile, false)) {
            decl String:newpluginfile[512];
            CreateDirectory("addons/sourcemod/plugins/disabled/kac_disabled", 1000);
            BuildPath(PathType:0, newpluginfile, 512, "plugins/disabled/kac_disabled/%s", g_sBadPlugins[i][0][0]);
            ServerCommand("sm plugins unload %s", g_sBadPlugins[i][0][0]);
            if (FileExists(newpluginfile, false)) {
                DeleteFile(newpluginfile);
            }
            RenameFile(newpluginfile, pluginfile);
            KAC_Log("plugins/%s was unloaded and moved to plugins/disabled/kac_disabled/%s", g_sBadPlugins[i][0][0], g_sBadPlugins[i][0][0]);
            i++;
        }
        i++;
    }
    return 0;
}

public AntiFlash_LoadNoTeamFlashPlugin()
{
    decl String:pluginnoteamflash[200];
    BuildPath(PathType:0, pluginnoteamflash, 200, "plugins/disabled/kac_disabled/no_team_flash.smx");
    if (FileExists(pluginnoteamflash, false)) {
        decl String:newpluginnoteamflash[200];
        BuildPath(PathType:0, newpluginnoteamflash, 200, "plugins/no_team_flash.smx");
        ServerCommand("sm plugins load no_team_flash");
        if (FileExists(newpluginnoteamflash, false)) {
            DeleteFile(newpluginnoteamflash);
        }
        RenameFile(newpluginnoteamflash, pluginnoteamflash);
    }
    return 0;
}

public AntiFlash_UnloadNoTeamFlashPlugin()
{
    decl String:pluginnoteamflash[200];
    BuildPath(PathType:0, pluginnoteamflash, 200, "plugins/no_team_flash.smx");
    if (FileExists(pluginnoteamflash, false)) {
        decl String:newpluginnoteamflash[200];
        CreateDirectory("addons/sourcemod/plugins/disabled/kac_disabled", 1000);
        BuildPath(PathType:0, newpluginnoteamflash, 200, "plugins/disabled/kac_disabled/no_team_flash.smx");
        ServerCommand("sm plugins unload no_team_flash");
        if (FileExists(newpluginnoteamflash, false)) {
            DeleteFile(newpluginnoteamflash);
        }
        RenameFile(newpluginnoteamflash, pluginnoteamflash);
    }
    return 0;
}

public AutoTrigger_LoadBhopPlugin()
{
    decl String:pluginbhop[200];
    BuildPath(PathType:0, pluginbhop, 200, "plugins/disabled/kac_disabled/infinite-jumping.smx");
    if (FileExists(pluginbhop, false)) {
        decl String:newpluginbhop[200];
        BuildPath(PathType:0, newpluginbhop, 200, "plugins/infinite-jumping.smx");
        ServerCommand("sm plugins load infinite-jumping");
        if (FileExists(newpluginbhop, false)) {
            DeleteFile(newpluginbhop);
        }
        RenameFile(newpluginbhop, pluginbhop);
    }
    return 0;
}

public AutoTrigger_UnLoadBhopPlugin()
{
    decl String:pluginbhop[200];
    BuildPath(PathType:0, pluginbhop, 200, "plugins/infinite-jumping.smx");
    if (FileExists(pluginbhop, false)) {
        decl String:newpluginbhop[200];
        CreateDirectory("addons/sourcemod/plugins/disabled/kac_disabled", 1000);
        BuildPath(PathType:0, newpluginbhop, 200, "plugins/disabled/kac_disabled/infinite-jumping.smx");
        ServerCommand("sm plugins unload infinite-jumping");
        if (FileExists(newpluginbhop, false)) {
            DeleteFile(newpluginbhop);
        }
        RenameFile(newpluginbhop, pluginbhop);
    }
    return 0;
}

public AimBot_OnPluginStart()
{
    g_hCVarAimBot = CreateConVar("kac_antiaimbot", "1", "????????? ? ??????? Aimbot.\nAimbot detection module.", 262144, true, 0, true, 1);
    Aimbot_OnSettingsChanged(g_hCVarAimBot, "", "");
    HookConVarChange(g_hCVarAimBot, ConVarChanged:23);
    g_hAimBotDeviation = CreateConVar("kac_antiaimbot_deviation", "38.0", "???????????? ?????????? AimBot.\nThe maximum deviation AimBot.", 262144, true, 35, true, 80);
    AimBotDeviation_OnSettingsChanged(g_hAimBotDeviation, "", "");
    HookConVarChange(g_hAimBotDeviation, ConVarChanged:3);
    g_hCvarAimbotBan = CreateConVar("kac_antiaimbot_ban", "4", "????? ?????????????? ??????? AimBot ?? ????. (0 - ?? ??????, ?????? ?????????????.)\nNumber of AimBot detections before a player is banned. Minimum allowed is 4. (0 = Never ban).", 262144, true, 0, true, 10);
    AimbotBan_OnSettingsChanged(g_hCvarAimbotBan, "", "");
    HookConVarChange(g_hCvarAimbotBan, ConVarChanged:15);
    return 0;
}

public Aimbot_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValue = GetConVarBool(convar);
    new var1;
    if (bNewValue) {
        AimBot_Enable();
    } else {
        new var2;
        if (!bNewValue) {
            AimBot_Disable();
        }
    }
    return 0;
}

public AimBot_Enable()
{
    g_bAimbotEnabled = 1;
    g_IgnoreWeapons = CreateTrie();
    SetTrieValue(g_IgnoreWeapons, "weapon_knife", any:1, true);
    HookEntityOutput("trigger_teleport", "OnEndTouch", EntityOutput:25);
    HookEvent("player_spawn", EventHook:19, EventHookMode:1);
    HookEvent("player_death", EventHook:17, EventHookMode:1);
    return 0;
}

public AimBot_Disable()
{
    g_bAimbotEnabled = 0;
    if (g_IgnoreWeapons) {
        CloseHandle(g_IgnoreWeapons);
        g_IgnoreWeapons = 0;
    }
    UnhookEntityOutput("trigger_teleport", "OnEndTouch", EntityOutput:25);
    UnhookEvent("player_spawn", EventHook:19, EventHookMode:1);
    UnhookEvent("player_death", EventHook:17, EventHookMode:1);
    return 0;
}

public AimBotDeviation_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    g_fAimBotDeviation = GetConVarFloat(convar);
    return 0;
}

public AimBot_OnClientPutInServer(client)
{
    if (IsClientNew(client)) {
        g_iAimDetections[client] = 0;
        Aimbot_ClearAngles(client);
    }
    return 0;
}

public AimbotBan_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new iNewValue = GetConVarInt(convar);
    new var1;
    if (iNewValue > 0) {
        SetConVarInt(convar, 4, false, false);
        return 0;
    }
    g_iAimbotBan = iNewValue;
    return 0;
}

public Aimbot_TeleportOnEndTouch(String:output[], caller, activator, Float:delay)
{
    new var2 = activator;
    new var1;
    if (MaxClients >= var2 & 1 <= var2) {
        Aimbot_ClearAngles(activator);
        CreateTimer(FloatAdd(0,1, delay), Timer_ClearAngles, GetClientUserId(activator), 2);
    }
    return 0;
}

public Aimbot_EventPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    new var1 = client;
    if (MaxClients >= var1 & 1 <= var1) {
        Aimbot_ClearAngles(client);
        CreateTimer(0,1, Timer_ClearAngles, userid, 2);
    }
    return 0;
}


/* ERROR! Das Objekt des Typs "Lysis.DConstant" kann nicht in Typ "Lysis.DDeclareLocal" umgewandelt werden. */
 function "Aimbot_EventPlayerDeath" (number 58)
public Action:Timer_ClearAngles(Handle:timer, userid)
{
    new client = GetClientOfUserId(userid);
    new var1 = client;
    if (MaxClients >= var1 & 1 <= var1) {
        Aimbot_ClearAngles(client);
    }
    return Action:4;
}

public Action:AimBot_TimerDecreaseCount(Handle:timer, userid)
{
    new client = GetClientOfUserId(userid);
    new var2 = client;
    new var1;
    if (MaxClients >= var2 & 1 <= var2) {
        g_iAimDetections[client]--;
    }
    return Action:4;
}

public Action:Aimbot_OnPlayerRunCmd(client, Float:angles[3])
{
    if (!g_bAimbotEnabled) {
        return Action:0;
    }
    g_iEyeIndex[client]++;
    if (g_iEyeIndex[client][0][0] == 32) {
        g_iEyeIndex[client] = 0;
    }
    return Action:0;
}


/* ERROR! unknown operator */
 function "Aimbot_AnalyzeAngles" (number 62)

/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "AimBot_Detected" (number 63)
Aimbot_ClearAngles(client)
{
    g_iEyeIndex[client] = 0;
    new i = 0;
    while (i < 32) {
        ZeroVector(g_fEyeAngles[client][0][0][i]);
        i++;
    }
    return 0;
}

public IpAlready_OnPluginStart()
{
    g_hCvarIpAlreadyEnable = CreateConVar("kac_ipalready_playerkick", "0", "????????? ??????? ?????? ?? ??????? ? ?????? Ip ??????.\nDeny players to play on a server with one Ip address.", 262144, true, 0, true, 1);
    IpAlready_OnSettingsChanged(g_hCvarIpAlreadyEnable, "", "");
    HookConVarChange(g_hCvarIpAlreadyEnable, ConVarChanged:201);
    return 0;
}

public IpAlready_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueIpAlready = GetConVarBool(convar);
    new var1;
    if (bNewValueIpAlready) {
        g_bEnabledIpAlready = 1;
    } else {
        new var2;
        if (!bNewValueIpAlready) {
            g_bEnabledIpAlready = 0;
        }
    }
    return 0;
}

public OnClientConnected(client)
{
    if (g_bEnabledIpAlready) {
        decl String:ip1[16];
        GetClientIP(client, ip1, 16, true);
        if (strcmp(ip1, "127.0.0.1", false)) {
            new i = 1;
            while (GetMaxClients() >= i) {
                if (IsClientInGame(i)) {
                    decl String:ip2[16];
                    GetClientIP(i, ip2, 16, true);
                    new var1;
                    if (!strcmp(ip1, ip2, false)) {
                        KickClient(client, "%t", "KAC_IpAlreadyKick", ip1);
                        i++;
                    }
                    i++;
                }
                i++;
            }
        }
    }
    return 0;
}

public AutoTrigger_OnPluginStart()
{
    g_hCvarMethod = CreateConVar("kac_autotrigger_method", "3", "??????????? ??????????????? ??????? ???: (0 ?????????, 1 BunnyHop, 2 Auto-Fire, 3 BunnyHop ? Auto-Fire).\n1Defining automatic trigger bot: (0 Disable, 1 BunnyHop, 2 Auto-Fire, 3 BunnyHop and Auto-Fire).", 262144, true, 0, true, 3);
    AutoTriggerMethod_OnSettingsChanged(g_hCvarMethod, "", "");
    HookConVarChange(g_hCvarMethod, ConVarChanged:85);
    g_hCvarTriggerDetections = CreateConVar("kac_autotrigger_detections", "9", "???????????? ????? ???????? Auto-Trigger (Auto-Fire ? BunnyHop).\nThe number of detections of Auto-Trigger (Auto-Fire ? BunnyHop).", 262144, true, 8, true, 30);
    AutoTriggerDetections_OnSettingsChanged(g_hCvarTriggerDetections, "", "");
    HookConVarChange(g_hCvarTriggerDetections, ConVarChanged:83);
    g_hCvarAutoTriggerBlock = CreateConVar("kac_autotrigger_block", "2", "1 - ????????????? ??????????, 2 - ????????????? ?????? ??? ???????????.\nAutomatically 1 - kicked, 2 - ban players on auto-trigger detections.", 262144, true, 0, true, 2);
    AutoTriggerBlock_OnSettingsChanged(g_hCvarAutoTriggerBlock, "", "");
    HookConVarChange(g_hCvarAutoTriggerBlock, ConVarChanged:81);
    g_iAttackMax = RoundToNearest(FloatDiv(FloatDiv(1, GetTickInterval()), 3));
    return 0;
}


/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "AutoTriggerMethod_OnSettingsChanged" (number 69)
public AutoTrigger_Enable()
{
    g_bEnabledAutoTrigger = 1;
    g_hTimerAutoTrigger = CreateTimer(5, AutoTriggerTimer_DecreaseCount, any:0, 1);
    return 0;
}

public AutoTrigger_Disable()
{
    g_bEnabledAutoTrigger = 0;
    if (g_hTimerAutoTrigger) {
        KillTimer(g_hTimerAutoTrigger, false);
        g_hTimerAutoTrigger = 0;
    }
    return 0;
}

public AutoTriggerDetections_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    g_iAutoTriggerDetections = GetConVarInt(convar);
    return 0;
}

public AutoTriggerBlock_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    g_iAutoTriggerBlock = GetConVarInt(convar);
    return 0;
}

public AutoTrigger_OnClientDisconnect_Post(client)
{
    new i = 0;
    while (i < 2) {
        g_iDetections[i][0][0][client] = 0;
        i++;
    }
    return 0;
}

public Action:AutoTriggerTimer_DecreaseCount(Handle:timer)
{
    new i = 0;
    while (i < 2) {
        new j = 1;
        while (j <= MaxClients) {
            if (g_iDetections[i][0][0][j]) {
                g_iDetections[i][0][0][j]--;
                j++;
            }
            j++;
        }
        i++;
    }
    return Action:0;
}

public Action:AutoTrigger_OnPlayerRunCmd(client, &buttons)
{
    if (!g_bEnabledAutoTrigger) {
        return Action:0;
    }
    static iPrevButtons[66];
    if (g_bEnabledAutoTriggerBunnyHop) {
        static Float:fCheckTime[66];
        new var1;
        if (!buttons & 2) {
            40324[client] = 0;
        }
        new var2;
        if (buttons & 2) {
            if (GetEntityFlags(client) & 1) {
                new Float:fGameTime = GetGameTime();
                new var3;
                if (40324[client] > 0) {
                    AutoTrigger_Detected(client, 0);
                } else {
                    40324[client] = FloatAdd(0,2, fGameTime);
                }
            }
            40324[client] = 0;
        }
    }
    static iAttackAmt[66];
    static bool:bResetNext[66];
    if (g_bEnabledAutoTriggerAutoFire) {
        new var4;
        if (buttons & 1) {
            new var7 = 40588[client];
            var7++;
            if (var7 >= g_iAttackMax) {
                AutoTrigger_Detected(client, 1);
                40588[client] = 0;
            }
            40852[client] = 0;
        }
        if (40852[client]) {
            40588[client] = 0;
            40852[client] = 0;
        }
        40852[client] = 1;
    }
    40060[client] = buttons;
    return Action:0;
}


/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "AutoTrigger_Detected" (number 77)
public Client_OnPluginStart()
{
    g_hCVarClientNameProtect = CreateConVar("kac_client_nameprotect", "1", "?????? ??????? ?? ???-???.\nThis will protect the server from name crashes and hacks.", 262144, true, 0, true, 1);
    ClientNameProtect_OnSettingsChanged(g_hCVarClientNameProtect, "", "");
    HookConVarChange(g_hCVarClientNameProtect, ConVarChanged:133);
    g_hCvarConnectSpam = CreateConVar("kac_antispam_connect", "2", "?????? ?? ??????? ??????????????? N ??? ? 1 ???????. (0 ?????????)\nProtection against fast reconnections N of times in 1 second. (0 Disabled)", 262144, true, 0, true, 2);
    OnClientConnect_OnSettingsChanged(g_hCvarConnectSpam, "", "");
    HookConVarChange(g_hCvarConnectSpam, ConVarChanged:271);
    g_hClientConnections = CreateTrie();
    g_hIgnoreList = CreateTrie();
    AddCommandListener(CommandListener:147, "autobuy");
    if (g_bMapStartedWait) {
        decl String:sReason[256];
        new i = 1;
        while (i <= MaxClients) {
            new var1;
            if (IsClientConnected(i)) {
                KickClient(i, "%s", sReason);
                i++;
            }
            i++;
        }
    }
    return 0;
}

public ClientNameProtect_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValue = GetConVarBool(convar);
    new var1;
    if (bNewValue) {
        g_bClientNameProtect = 1;
        HookEvent("player_changename", EventHook:137, EventHookMode:1);
    } else {
        new var2;
        if (!bNewValue) {
            g_bClientNameProtect = 0;
            UnhookEvent("player_changename", EventHook:137, EventHookMode:1);
        }
    }
    return 0;
}

public OnClientConnect_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    fSpamTime = GetConVarFloat(convar);
    return 0;
}

public Client_OnMapStart()
{
    CreateTimer(20, ClientTimer_MapStarted, any:0, 2);
    return 0;
}

public Client_OnMapEnd()
{
    g_bMapStartedWait = 0;
    ClearTrie(g_hClientConnections);
    return 0;
}

public Action:ClientTimer_MapStarted(Handle:timer)
{
    g_bMapStartedWait = 1;
    return Action:4;
}

public bool:OnClientConnect(client, String:rejectmsg[], size)
{
    if (IsFakeClient(client)) {
        return true;
    }
    new var1;
    if (g_bMapStartedWait) {
        decl String:sIP[20];
        decl String:sTempIP[20];
        GetClientIP(client, sIP, 17, true);
        new i = 1;
        while (i <= MaxClients) {
            new var2;
            if (client != i) {
                SetTrieValue(g_hIgnoreList, sIP, any:1, true);
                new temp = 0;
                if (!GetTrieValue(g_hIgnoreList, sIP, temp)) {
                    if (GetTrieValue(g_hClientConnections, sIP, temp)) {
                        KAC_LogAction(client, "was temporarily banned on 1 minute for connection spam.");
                        BanIdentity(sIP, 1, 2, "Spam Connecting", "KAC", any:0);
                        FormatEx(rejectmsg, size, "%T", "KAC_PleaseWait", client);
                        return false;
                    }
                    if (SetTrieValue(g_hClientConnections, sIP, any:1, true)) {
                        CreateTimer(fSpamTime, Timer_AntiSpamConnect, IPToLong(sIP), 0);
                    }
                }
            }
            i++;
        }
        new temp = 0;
        if (!GetTrieValue(g_hIgnoreList, sIP, temp)) {
            if (GetTrieValue(g_hClientConnections, sIP, temp)) {
                KAC_LogAction(client, "was temporarily banned on 1 minute for connection spam.");
                BanIdentity(sIP, 1, 2, "Spam Connecting", "KAC", any:0);
                FormatEx(rejectmsg, size, "%T", "KAC_PleaseWait", client);
                return false;
            }
            if (SetTrieValue(g_hClientConnections, sIP, any:1, true)) {
                CreateTimer(fSpamTime, Timer_AntiSpamConnect, IPToLong(sIP), 0);
            }
        }
    }
    new var3;
    if (g_bClientNameProtect) {
        FormatEx(rejectmsg, size, "%T", "KAC_ChangeName", client);
        return false;
    }
    return true;
}

Client_OnClientPutInServer(client)
{
    if (IsClientNew(client)) {
        g_iNameChanges[client] = 0;
    }
    return 0;
}

public OnClientSettingsChanged(client)
{
    new var1;
    if (g_bClientNameProtect) {
        KickClient(client, "%t", "KAC_ChangeName");
    }
    return 0;
}

public Client_EventPlayerChangeName(Handle:event, String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    new var2 = client;
    new var1;
    if (MaxClients >= var2 & 1 <= var2) {
        g_iNameChanges[client]++;
        CreateTimer(10, Timer_DecreaseCount, userid, 0);
        if (g_iNameChanges[client][0][0] >= 5) {
            if (!(KAC_CheatDetected(client))) {
                KAC_LogAction(client, "was kicked for name change spam.");
                KickClient(client, "%t", "KAC_CommandSpamKick");
            }
            g_iNameChanges[client] = 0;
        }
    }
    return 0;
}

public Action:Command_Autobuy(client, String:command[], args)
{
    new var1 = client;
    if (!var1 <= MaxClients & 1 <= var1) {
        return Action:0;
    }
    if (!IsClientInGame(client)) {
        return Action:3;
    }
    decl String:sAutobuy[256];
    decl String:sArg[64];
    new i = 0;
    new t = 0;
    GetClientInfo(client, "cl_autobuy", sAutobuy, 256);
    if (strlen(sAutobuy) > 255) {
        return Action:3;
    }
    i = 0;
    t = BreakString(sAutobuy, sArg, 64);
    while (t != -1) {
        if (strlen(sArg) > 30) {
            return Action:3;
        }
        i = t + i;
        t = BreakString(sAutobuy[i], sArg, 64);
    }
    if (strlen(sArg) > 30) {
        return Action:3;
    }
    return Action:0;
}

public Action:Timer_AntiSpamConnect(Handle:timer, ip)
{
    decl String:sIP[20];
    LongToIP(ip, sIP, 17);
    RemoveFromTrie(g_hClientConnections, sIP);
    return Action:4;
}

public Action:Timer_DecreaseCount(Handle:timer, userid)
{
    new client = GetClientOfUserId(userid);
    new var2 = client;
    new var1;
    if (MaxClients >= var2 & 1 <= var2) {
        g_iNameChanges[client]--;
    }
    return Action:4;
}

bool:IsClientNameValid(client)
{
    decl String:sName[32];
    decl String:sChar;
    new bool:bWhiteSpace = 1;
    GetClientName(client, sName, 32);
    new iSize = strlen(sName);
    new var1;
    if (iSize < 1) {
        return false;
    }
    new i = 0;
    while (i < iSize) {
        sChar = sName[i];
        if (!IsCharSpace(sChar)) {
            bWhiteSpace = 0;
        }
        if (IsCharMB(sChar)) {
            i++;
            new var2;
            if (sChar == String:194) {
                return false;
            }
            i++;
        } else {
            new var3;
            if (sChar < String:32) {
                return false;
            }
            i++;
        }
        i++;
    }
    if (bWhiteSpace) {
        return false;
    }
    return true;
}

public Commands_OnPluginStart()
{
    g_hCvarCmdSpam = CreateConVar("kac_antispam_cmds", "30", "?????????? ??????, ??????? ????? ??????? ?????? ? ???? ???????. ??? ????????? ??????? ??????.\nAmount of commands allowed in one second before kick. (0 = Disabled).", 262144, true, 0, true, 500);
    CmdSpam_OnSettingsChanged(g_hCvarCmdSpam, "", "");
    HookConVarChange(g_hCvarCmdSpam, ConVarChanged:145);
    g_hCVarCmdLog = CreateConVar("kac_cmds_log", "0", "?????????? ? log ???? ??????? ????????? ??????? ? ??????? ??????? (???????).\nLog command usage. Use only for debugging purposes.", 262144, true, 0, true, 1);
    CommandsCmdLog_OnSettingsChanged(g_hCVarCmdLog, "", "");
    HookConVarChange(g_hCVarCmdLog, ConVarChanged:151);
    new i = 0;
    BuildPath(PathType:0, g_sCmdLogPath, 256, "logs/KAC_CmdLog_%d.log", i);
    while (!FileExists(g_sCmdLogPath, false)) {
        i++;
    }
    AddCommandListener(CommandListener:165, "say");
    AddCommandListener(CommandListener:165, "say_team");
    AddCommandListener(CommandListener:159, "sm_menu");
    AddCommandListener(CommandListener:157, "ent_create");
    AddCommandListener(CommandListener:157, "ent_fire");
    AddCommandListener(CommandListener:157, "give");
    HookEvent("player_disconnect", EventHook:163, EventHookMode:0);
    g_hBlockedCmds = CreateTrie();
    g_hIgnoredCmds = CreateTrie();
    SetTrieValue(g_hBlockedCmds, "ai_test_los", any:0, true);
    SetTrieValue(g_hBlockedCmds, "changelevel", any:1, true);
    SetTrieValue(g_hBlockedCmds, "cl_fullupdate", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dbghist_addline", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dbghist_dump", any:0, true);
    SetTrieValue(g_hBlockedCmds, "drawcross", any:0, true);
    SetTrieValue(g_hBlockedCmds, "drawline", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dump_entity_sizes", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dump_globals", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dump_panels", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dump_terrain", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dumpcountedstrings", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dumpentityfactories", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dumpeventqueue", any:0, true);
    SetTrieValue(g_hBlockedCmds, "dumpgamestringtable", any:0, true);
    SetTrieValue(g_hBlockedCmds, "editdemo", any:0, true);
    SetTrieValue(g_hBlockedCmds, "endround", any:0, true);
    SetTrieValue(g_hBlockedCmds, "groundlist", any:0, true);
    SetTrieValue(g_hBlockedCmds, "listmodels", any:0, true);
    SetTrieValue(g_hBlockedCmds, "map_showspawnpoints", any:0, true);
    SetTrieValue(g_hBlockedCmds, "mem_dump", any:0, true);
    SetTrieValue(g_hBlockedCmds, "mp_dump_timers", any:0, true);
    SetTrieValue(g_hBlockedCmds, "npc_ammo_deplete", any:0, true);
    SetTrieValue(g_hBlockedCmds, "npc_heal", any:0, true);
    SetTrieValue(g_hBlockedCmds, "npc_speakall", any:0, true);
    SetTrieValue(g_hBlockedCmds, "npc_thinknow", any:0, true);
    SetTrieValue(g_hBlockedCmds, "physics_budget", any:0, true);
    SetTrieValue(g_hBlockedCmds, "physics_debug_entity", any:0, true);
    SetTrieValue(g_hBlockedCmds, "physics_highlight_active", any:0, true);
    SetTrieValue(g_hBlockedCmds, "physics_report_active", any:0, true);
    SetTrieValue(g_hBlockedCmds, "physics_select", any:0, true);
    SetTrieValue(g_hBlockedCmds, "q_sndrcn", any:1, true);
    SetTrieValue(g_hBlockedCmds, "report_entities", any:0, true);
    SetTrieValue(g_hBlockedCmds, "report_touchlinks", any:0, true);
    SetTrieValue(g_hBlockedCmds, "report_simthinklist", any:0, true);
    SetTrieValue(g_hBlockedCmds, "respawn_entities", any:0, true);
    SetTrieValue(g_hBlockedCmds, "rr_reloadresponsesystems", any:0, true);
    SetTrieValue(g_hBlockedCmds, "scene_flush", any:0, true);
    SetTrieValue(g_hBlockedCmds, "send_me_rcon", any:1, true);
    SetTrieValue(g_hBlockedCmds, "snd_digital_surround", any:0, true);
    SetTrieValue(g_hBlockedCmds, "snd_restart", any:0, true);
    SetTrieValue(g_hBlockedCmds, "soundlist", any:0, true);
    SetTrieValue(g_hBlockedCmds, "soundscape_flush", any:0, true);
    SetTrieValue(g_hBlockedCmds, "sv_benchmark_force_start", any:0, true);
    SetTrieValue(g_hBlockedCmds, "sv_findsoundname", any:0, true);
    SetTrieValue(g_hBlockedCmds, "sv_soundemitter_filecheck", any:0, true);
    SetTrieValue(g_hBlockedCmds, "sv_soundemitter_flush", any:0, true);
    SetTrieValue(g_hBlockedCmds, "sv_soundscape_printdebuginfo", any:0, true);
    SetTrieValue(g_hBlockedCmds, "wc_update_entity", any:0, true);
    SetTrieValue(g_hIgnoredCmds, "buy", any:1, true);
    SetTrieValue(g_hIgnoredCmds, "buyammo1", any:1, true);
    SetTrieValue(g_hIgnoredCmds, "buyammo2", any:1, true);
    SetTrieValue(g_hIgnoredCmds, "use", any:1, true);
    SetTrieValue(g_hIgnoredCmds, "vmodenable", any:1, true);
    SetTrieValue(g_hIgnoredCmds, "vban", any:1, true);
    CreateTimer(1, Timer_CountReset, any:0, 1);
    AddCommandListener(CommandListener:161, "");
    RegAdminCmd("kac_addcmd", Commands_AddCmd, 16384, "Adds a command to be blocked by KAC.", "", 0);
    RegAdminCmd("kac_addignorecmd", Commands_AddIgnoreCmd, 16384, "Adds a command to ignore on command spam.", "", 0);
    RegAdminCmd("kac_removecmd", Commands_RemoveCmd, 16384, "Removes a command from the block list.", "", 0);
    RegAdminCmd("kac_removeignorecmd", Commands_RemoveIgnoreCmd, 16384, "Remove a command to ignore.", "", 0);
    return 0;
}

public CmdSpam_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    g_iCmdSpam = GetConVarInt(convar);
    new bool:bNewValueSpamCmds = GetConVarBool(convar);
    new var1;
    if (bNewValueSpamCmds) {
        g_bSpamCmds = 1;
    } else {
        new var2;
        if (!bNewValueSpamCmds) {
            g_bSpamCmds = 0;
        }
    }
    return 0;
}

public CommandsCmdLog_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueLogCmds = GetConVarBool(convar);
    new var1;
    if (bNewValueLogCmds) {
        g_bLogCmds = 1;
    } else {
        new var2;
        if (!bNewValueLogCmds) {
            g_bLogCmds = 0;
        }
    }
    return 0;
}

public Action:Commands_EventDisconnect(Handle:event, String:name[], bool:dontBroadcast)
{
    decl String:f_sReason[512];
    decl String:f_sTemp[512];
    decl f_iLength;
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    GetEventString(event, "reason", f_sReason, 512);
    GetEventString(event, "name", f_sTemp, 512);
    f_iLength = strlen(f_sTemp) + strlen(f_sReason);
    GetEventString(event, "networkid", f_sTemp, 512);
    f_iLength = strlen(f_sTemp) + f_iLength;
    if (f_iLength > 235) {
        new var4 = client;
        new var1;
        if (MaxClients >= var4 & 1 <= var4) {
            KAC_LogAction(client, "submitted a bad disconnect reason, length %d, \"%s\"", f_iLength, f_sReason);
        } else {
            KAC_Log("Bad disconnect reason, length %d, \"%s\"", f_iLength, f_sReason);
        }
        SetEventString(event, "reason", "Bad disconnect message");
        return Action:0;
    }
    f_iLength = strlen(f_sReason);
    new i = 0;
    while (i < f_iLength) {
        new var2;
        if (f_sReason[i] < ' ') {
            new var5 = client;
            new var3;
            if (MaxClients >= var5 & 1 <= var5) {
                KAC_LogAction(client, "submitted a bad disconnect reason, \"%s\" len = %d. Possible corruption or attack.", f_sReason, f_iLength);
            } else {
                KAC_Log("Bad disconnect reason, \"%s\" len = %d. Possible corruption or attack.", f_sReason, f_iLength);
            }
            SetEventString(event, "reason", "Bad disconnect message");
            return Action:0;
        }
        i++;
    }
    return Action:0;
}

public Action:Commands_AddCmd(client, args)
{
    if (args != 2) {
        ReplyToCommand(client, "Usage: kac_addcmd <command name> <ban (1 or 0)>");
        return Action:3;
    }
    decl String:f_sCmdName[64];
    decl String:f_sTemp[8];
    decl bool:f_bBan;
    GetCmdArg(1, f_sCmdName, 64);
    GetCmdArg(2, f_sTemp, 8);
    new var1;
    if (StringToInt(f_sTemp, 10)) {
        f_bBan = 1;
    } else {
        f_bBan = 0;
    }
    if (SetTrieValue(g_hBlockedCmds, f_sCmdName, f_bBan, true)) {
        ReplyToCommand(client, "You have successfully added %s to the command block list.", f_sCmdName);
    } else {
        ReplyToCommand(client, "%s already exists in the command block list.", f_sCmdName);
    }
    return Action:3;
}

public Action:Commands_AddIgnoreCmd(client, args)
{
    if (args != 1) {
        ReplyToCommand(client, "Usage: kac_addignorecmd <command name>");
        return Action:3;
    }
    decl String:f_sCmdName[64];
    GetCmdArg(1, f_sCmdName, 64);
    if (SetTrieValue(g_hIgnoredCmds, f_sCmdName, any:1, true)) {
        ReplyToCommand(client, "You have successfully added %s to the command ignore list.", f_sCmdName);
    } else {
        ReplyToCommand(client, "%s already exists in the command ignore list.", f_sCmdName);
    }
    return Action:3;
}

public Action:Commands_RemoveCmd(client, args)
{
    if (args != 1) {
        ReplyToCommand(client, "Usage: kac_removecmd <command name>");
        return Action:3;
    }
    decl String:f_sCmdName[64];
    GetCmdArg(1, f_sCmdName, 64);
    if (RemoveFromTrie(g_hBlockedCmds, f_sCmdName)) {
        ReplyToCommand(client, "You have successfully removed %s from the command block list.", f_sCmdName);
    } else {
        ReplyToCommand(client, "%s is not in the command block list.", f_sCmdName);
    }
    return Action:3;
}

public Action:Commands_RemoveIgnoreCmd(client, args)
{
    if (args != 1) {
        ReplyToCommand(client, "Usage: kac_removeignorecmd <command name>");
        return Action:3;
    }
    decl String:f_sCmdName[64];
    GetCmdArg(1, f_sCmdName, 64);
    if (RemoveFromTrie(g_hIgnoredCmds, f_sCmdName)) {
        ReplyToCommand(client, "You have successfully removed %s from the command ignore list.", f_sCmdName);
    } else {
        ReplyToCommand(client, "%s is not in the command ignore list.", f_sCmdName);
    }
    return Action:3;
}


/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "Commands_BlockExploit" (number 100)
public Action:Commands_FilterSay(client, String:command[], args)
{
    new var1;
    if (!g_bSpamCmds) {
        return Action:0;
    }
    new iSpaceNum = 0;
    decl String:f_sMsg[256];
    decl f_iLen;
    decl String:f_cChar;
    GetCmdArgString(f_sMsg, 256);
    f_iLen = strlen(f_sMsg);
    new i = 0;
    while (i < f_iLen) {
        f_cChar = f_sMsg[i];
        if (f_cChar == String:32) {
            iSpaceNum++;
            if (iSpaceNum >= 64) {
                CPrintToChat(client, "%t %t", 45876, 45884);
                EmitSoundToClient(client, "buttons/button11.wav", -2, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
                return Action:4;
            }
        }
        new var2;
        if (f_cChar < String:32) {
            CPrintToChat(client, "%t %t", 45932, 45940);
            EmitSoundToClient(client, "buttons/button11.wav", -2, 0, 75, 0, 1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
            return Action:4;
        }
        i++;
    }
    return Action:0;
}

public Action:Commands_BlockEntExploit(client, String:command[], args)
{
    new var2 = client;
    if (!var2 <= MaxClients & 1 <= var2) {
        return Action:0;
    }
    if (!IsClientInGame(client)) {
        return Action:4;
    }
    decl String:f_sCmd[512];
    GetCmdArgString(f_sCmd, 512);
    if (strlen(f_sCmd) > 500) {
        return Action:4;
    }
    new var1;
    if (StrContains(f_sCmd, "point_servercommand", true) == -1) {
        if (g_bLogCmds) {
            decl String:f_sCmdName[64];
            GetCmdArg(0, f_sCmdName, 64);
            LogToFileEx(g_sCmdLogPath, "%L attempted command: %s %s", client, f_sCmdName, f_sCmd);
        }
        return Action:4;
    }
    return Action:0;
}


/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "Commands_CommandListener" (number 103)
public Action:Timer_CountReset(Handle:timer, args)
{
    new i = 1;
    while (i <= MaxClients) {
        g_iCmdCount[i] = 0;
        i++;
    }
    return Action:0;
}

StringToLower(String:f_sInput[])
{
    new f_iSize = strlen(f_sInput);
    new i = 0;
    while (i < f_iSize) {
        f_sInput[i] = CharToLower(f_sInput[i]);
        i++;
    }
    return 0;
}

public CVars_OnPluginStart()
{
    g_hCVarCVarsEnabled = CreateConVar("kac_cvars_enable", "1", "1 ????????, 0 ?????????: ???????? Cvars, ???????? ? ??????? ?? ???????.\nEnable the CVar checks module.", 262144, true, 0, true, 1);
    CVarsEnabled_OnSettingsChanged(g_hCVarCVarsEnabled, "", "");
    HookConVarChange(g_hCVarCVarsEnabled, ConVarChanged:109);
    g_hSvCVarChtForceEnable = CreateConVar("kac_cvars_force_cheats", "1", "1 ????????. 0 ?????????: ????????????? ?????????? ???????? sv_cheats 0 ??? ??????? 1. (?? ????????? ???????? 1).\nAutomatically return the value 0 sv_cheats set to 1", 262144, true, 0, true, 1);
    CVarSvChtForce_OnSettingsChanged(g_hSvCVarChtForceEnable, "", "");
    HookConVarChange(g_hSvCVarChtForceEnable, ConVarChanged:107);
    decl Handle:f_hConCommand;
    decl String:f_sName[64];
    decl bool:f_bIsCommand;
    decl f_iFlags;
    decl Handle:f_hConVar;
    g_hCVars = CreateArray(64, 0);
    g_hCVarIndex = CreateTrie();
    CVars_AddCVar("0penscript", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("openscript", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("antiban", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("aim_bot", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("aim_fov", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("bat_version", 5, 3, "0.0", 0, 3, "");
    CVars_AddCVar("beetlesmod_version", 5, 3, "0.0", 0, 3, "");
    CVars_AddCVar("est_version", 5, 3, "0.0", 0, 3, "");
    CVars_AddCVar("eventscripts_ver", 5, 3, "0.0", 0, 3, "");
    CVars_AddCVar("fm_attackmode", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("lua_open", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("Lua-Engine", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("mani_admin_plugin_version", 5, 3, "0.0", 0, 3, "");
    CVars_AddCVar("Kentavr1kTakeOver", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("Kentavr1kTakeOver_Information", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("ManiAdminHacker", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("ManiAdminTakeOver", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("TakeOver_Password", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("metamod_version", 5, 3, "0.0", 0, 3, "");
    CVars_AddCVar("openscript_version", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("runnscript", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("SmAdminTakeover", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("sourcemod_version", 5, 3, "0.0", 0, 3, "");
    CVars_AddCVar("tb_enabled", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("zb_version", 5, 3, "0.0", 0, 3, "");
    CVars_AddCVar("NosorogManiTakeOver", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("NosorogSmTakeOver", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("NosorogServercfgDownload", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("NosorogDownloadFile", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("NosorogUploadFile", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("NosorogAddAdmin", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("NosorogAdminAdd", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("NosorogSmallCheatMenu", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("FunnyExploitByNosorog", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("MNosorogcrashOver", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("DownloadServerCfg", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("AdminAddedByMrWhite", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("TakeOverByMrWhite", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("TakeOverByMrWhite_Information", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("ManiNogganoooHack", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("SmNogganoooHack", 5, 4, "0.0", 0, 3, "");
    CVars_AddCVar("sv_cheats", 0, 4, "0.0", 0, 1, "");
    CVars_AddCVar("sv_consistency", 0, 4, "1.0", 0, 1, "");
    CVars_AddCVar("r_drawothermodels", 0, 4, "1.0", 0, 1, "");
    CVars_AddCVar("cl_clock_correction", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("cl_leveloverview", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("cl_overdraw_test", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("cl_particles_show_bbox", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("cl_phys_timescale", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("cl_showevents", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("fog_enable", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("host_timescale", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("mat_dxlevel", 1, 3, "80.0", 0, 0, "");
    CVars_AddCVar("mat_fillrate", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("mat_measurefillrate", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("mat_proxy", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("mat_showlowresimage", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("mat_wireframe", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("mem_force_flush", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("snd_show", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("snd_visualize", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("r_aspectratio", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("r_colorstaticprops", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("r_DispWalkable", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("r_DrawBeams", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_drawbrushmodels", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_drawclipbrushes", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("r_drawdecals", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_drawentities", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_drawmodelstatsoverlay", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("r_drawopaqueworld", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_drawparticles", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_drawrenderboxes", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("r_drawskybox", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_drawtranslucentworld", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_shadowwireframe", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("r_skybox", 0, 4, "1.0", 0, 0, "");
    CVars_AddCVar("r_visocclusion", 0, 4, "0.0", 0, 0, "");
    CVars_AddCVar("vcollide_wireframe", 0, 4, "0.0", 0, 0, "");
    f_hConCommand = FindFirstConCommand(f_sName, 64, f_bIsCommand, f_iFlags, "", 0);
    if (f_hConCommand) {
        do {
            if (!f_bIsCommand) {
                if (!f_iFlags & 8192) {
                } else {
                    if (f_iFlags & 262144) {
                    } else {
                        f_hConVar = FindConVar(f_sName);
                        if (f_hConVar) {
                            CVars_ReplicateConVar(f_hConVar);
                            HookConVarChange(f_hConVar, ConVarChanged:125);
                        }
                    }
                }
            }
        } while (FindNextConCommand(f_hConCommand, f_sName, 64, f_bIsCommand, f_iFlags, "", 0));
        CloseHandle(f_hConCommand);
        RegAdminCmd("kac_addcvar", CVars_CmdAddCVar, 16384, "Adds a CVar to the check list.", "", 0);
        RegAdminCmd("kac_removecvar", CVars_CmdRemCVar, 16384, "Removes a CVar from the check list.", "", 0);
        RegAdminCmd("kac_cvars_status", CVars_CmdStatus, 2, "Shows the status of all in-game clients.", "", 0);
        if (g_bMapStarted) {
            new i = 1;
            while (i <= MaxClients) {
                new var1;
                if (IsClientInGame(i)) {
                    OnClientPostAdminCheck(i);
                    i++;
                }
                i++;
            }
        }
        return 0;
    } else {
        SetFailState("Failed getting first ConVar");
        do {
            if (!f_bIsCommand) {
                if (!f_iFlags & 8192) {
                } else {
                    if (f_iFlags & 262144) {
                    } else {
                        f_hConVar = FindConVar(f_sName);
                        if (f_hConVar) {
                            CVars_ReplicateConVar(f_hConVar);
                            HookConVarChange(f_hConVar, ConVarChanged:125);
                        }
                    }
                }
            }
        } while (FindNextConCommand(f_hConCommand, f_sName, 64, f_bIsCommand, f_iFlags, "", 0));
        CloseHandle(f_hConCommand);
        RegAdminCmd("kac_addcvar", CVars_CmdAddCVar, 16384, "Adds a CVar to the check list.", "", 0);
        RegAdminCmd("kac_removecvar", CVars_CmdRemCVar, 16384, "Removes a CVar from the check list.", "", 0);
        RegAdminCmd("kac_cvars_status", CVars_CmdStatus, 2, "Shows the status of all in-game clients.", "", 0);
        if (g_bMapStarted) {
            new i = 1;
            while (i <= MaxClients) {
                new var1;
                if (IsClientInGame(i)) {
                    OnClientPostAdminCheck(i);
                    i++;
                }
                i++;
            }
        }
        return 0;
    }
    do {
        if (!f_bIsCommand) {
            if (!f_iFlags & 8192) {
            } else {
                if (f_iFlags & 262144) {
                } else {
                    f_hConVar = FindConVar(f_sName);
                    if (f_hConVar) {
                        CVars_ReplicateConVar(f_hConVar);
                        HookConVarChange(f_hConVar, ConVarChanged:125);
                    }
                }
            }
        }
    } while (FindNextConCommand(f_hConCommand, f_sName, 64, f_bIsCommand, f_iFlags, "", 0));
    CloseHandle(f_hConCommand);
    RegAdminCmd("kac_addcvar", CVars_CmdAddCVar, 16384, "Adds a CVar to the check list.", "", 0);
    RegAdminCmd("kac_removecvar", CVars_CmdRemCVar, 16384, "Removes a CVar from the check list.", "", 0);
    RegAdminCmd("kac_cvars_status", CVars_CmdStatus, 2, "Shows the status of all in-game clients.", "", 0);
    if (g_bMapStarted) {
        new i = 1;
        while (i <= MaxClients) {
            new var1;
            if (IsClientInGame(i)) {
                OnClientPostAdminCheck(i);
                i++;
            }
            i++;
        }
    }
    return 0;
}

public CVarsEnabled_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueCVarsEnabled = GetConVarBool(convar);
    new var1;
    if (bNewValueCVarsEnabled) {
        g_bCVarCVarsEnabled = 1;
    } else {
        new var2;
        if (!bNewValueCVarsEnabled) {
            g_bCVarCVarsEnabled = 0;
        }
    }
    return 0;
}

public CVarSvChtForce_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueCVarSvChtForceEnabled = GetConVarBool(convar);
    new var1;
    if (bNewValueCVarSvChtForceEnabled) {
        g_bSvCVarChtForce = 1;
        new Handle:f_hConVar = FindConVar("sv_cheats");
        if (f_hConVar) {
            SetConVarInt(f_hConVar, 0, false, false);
        }
    } else {
        new var2;
        if (!bNewValueCVarSvChtForceEnabled) {
            g_bSvCVarChtForce = 0;
        }
    }
    return 0;
}

public OnClientPostAdminCheck(client)
{
    if (!IsFakeClient(client)) {
        g_hPeriodicTimer[client] = CreateTimer(0,1, CVars_PeriodicTimer, client, 0);
    }
    return 0;
}

public CVars_OnClientDisconnect(client)
{
    decl Handle:f_hTemp;
    g_iCurrentIndex[client] = 0;
    g_iRetryAttempts[client] = 0;
    f_hTemp = g_hPeriodicTimer[client][0][0];
    if (f_hTemp) {
        g_hPeriodicTimer[client] = 0;
        CloseHandle(f_hTemp);
    }
    f_hTemp = g_hReplyTimer[client][0][0];
    if (f_hTemp) {
        g_hReplyTimer[client] = 0;
        CloseHandle(f_hTemp);
    }
    return 0;
}


/* ERROR! Das Objekt des Typs "Lysis.LDebugBreak" kann nicht in Typ "Lysis.LConstant" umgewandelt werden. */
 function "CVars_CmdStatus" (number 111)
public Action:CVars_CmdAddCVar(client, args)
{
    new var1;
    if (args != 4) {
        ReplyToCommand(client, "Usage: kac_addcvar <cvar name> <comparison type> <action> <value> <value2 if bound>");
        return Action:3;
    }
    decl String:f_sCVarName[64];
    decl String:f_sTemp[64];
    decl f_iCompType;
    decl f_iAction;
    decl String:f_sValue[64];
    decl Float:f_fValue2;
    GetCmdArg(1, f_sCVarName, 64);
    if (!CVars_IsValidName(f_sCVarName)) {
        ReplyToCommand(client, "The ConVar name \"%s\" is invalid and cannot be used.", f_sCVarName);
        return Action:3;
    }
    GetCmdArg(2, f_sTemp, 64);
    new var2;
    if (StrEqual(f_sTemp, "=", true)) {
        f_iCompType = 0;
    } else {
        new var3;
        if (StrEqual(f_sTemp, "<", true)) {
            f_iCompType = 1;
        }
        new var4;
        if (StrEqual(f_sTemp, ">", true)) {
            f_iCompType = 2;
        }
        new var5;
        if (StrEqual(f_sTemp, "bound", true)) {
            f_iCompType = 3;
        }
        if (StrEqual(f_sTemp, "strequal", true)) {
            f_iCompType = 4;
        }
        if (StrEqual(f_sTemp, "nonexist", true)) {
            f_iCompType = 5;
        }
        ReplyToCommand(client, "Unrecognized comparison type \"%s\", acceptable values: \"equal\", \"greater\", \"less\", \"between\", \"strequal\", or \"nonexist\".", f_sTemp);
        return Action:3;
    }
    new var6;
    if (f_iCompType == 3) {
        ReplyToCommand(client, "Bound comparison type needs two values to compare with.");
        return Action:3;
    }
    GetCmdArg(3, f_sTemp, 64);
    if (StrEqual(f_sTemp, "warn", true)) {
        f_iAction = 0;
    } else {
        if (StrEqual(f_sTemp, "motd", true)) {
            f_iAction = 1;
        }
        if (StrEqual(f_sTemp, "mute", true)) {
            f_iAction = 2;
        }
        if (StrEqual(f_sTemp, "kick", true)) {
            f_iAction = 3;
        }
        if (StrEqual(f_sTemp, "ban", true)) {
            f_iAction = 4;
        }
        ReplyToCommand(client, "Unrecognized action type \"%s\", acceptable values: \"warn\", \"mute\", \"kick\", or \"ban\".", f_sTemp);
        return Action:3;
    }
    GetCmdArg(4, f_sValue, 64);
    if (f_iCompType == 3) {
        GetCmdArg(5, f_sTemp, 64);
        f_fValue2 = StringToFloat(f_sTemp);
    }
    if (CVars_AddCVar(f_sCVarName, f_iCompType, f_iAction, f_sValue, f_fValue2, 0, "")) {
        if (client) {
            KAC_LogAction(client, "added convar %s to the check list.", f_sCVarName);
        }
        ReplyToCommand(client, "Successfully added ConVar %s to the check list.", f_sCVarName);
    } else {
        ReplyToCommand(client, "Failed to add ConVar %s to the check list.", f_sCVarName);
    }
    return Action:3;
}

public Action:CVars_CmdRemCVar(client, args)
{
    if (args != 1) {
        ReplyToCommand(client, "Usage: kac_removecvar <cvar name>");
        return Action:3;
    }
    decl String:f_sCVarName[64];
    GetCmdArg(1, f_sCVarName, 64);
    if (CVars_RemoveCVar(f_sCVarName)) {
        if (client) {
            KAC_LogAction(client, "removed convar %s from the check list.", f_sCVarName);
        } else {
            KAC_Log("Console removed convar %s from the check list.", f_sCVarName);
        }
        ReplyToCommand(client, "ConVar %s was successfully removed from the check list.", f_sCVarName);
    } else {
        ReplyToCommand(client, "Unable to find ConVar %s in the check list.", f_sCVarName);
    }
    return Action:3;
}

public Action:CVars_PeriodicTimer(Handle:timer, client)
{
    if (g_hPeriodicTimer[client][0][0]) {
        if (!g_bCVarCVarsEnabled) {
            g_hPeriodicTimer[client] = CreateTimer(60, CVars_PeriodicTimer, client, 0);
            return Action:4;
        }
        g_hPeriodicTimer[client] = 0;
        if (!IsClientConnected(client)) {
            return Action:4;
        }
        decl String:f_sName[64];
        decl Handle:f_hCVar;
        decl f_iIndex;
        if (g_iSize < 1) {
            PrintToServer("Nothing in convar list");
            CreateTimer(10, CVars_PeriodicTimer, client, 0);
            return Action:4;
        }
        new var1 = g_iCurrentIndex[client];
        var1++;
        f_iIndex = var1[0][0];
        if (f_iIndex >= g_iSize) {
            f_iIndex = 0;
            g_iCurrentIndex[client] = 1;
        }
        f_hCVar = GetArrayCell(g_hCVars, f_iIndex, 0, false);
        if (GetArrayCell(f_hCVar, 8, 0, false)) {
            g_hPeriodicTimer[client] = CreateTimer(0,1, CVars_PeriodicTimer, client, 0);
        } else {
            GetArrayString(f_hCVar, 0, f_sName, 64);
            g_hCurrentQuery[client] = f_hCVar;
            QueryClientConVar(client, f_sName, ConVarQueryFinished:123, client);
            g_hReplyTimer[client] = CreateTimer(30, CVars_ReplyTimer, GetClientUserId(client), 0);
        }
        return Action:4;
    }
    return Action:4;
}

public Action:CVars_ReplyTimer(Handle:timer, userid)
{
    new client = GetClientOfUserId(userid);
    new var1;
    if (!client) {
        return Action:4;
    }
    g_hReplyTimer[client] = 0;
    new var2;
    if (!g_bCVarCVarsEnabled) {
        return Action:4;
    }
    new var3 = g_iRetryAttempts[client];
    var3++;
    if (var3[0][0] > 3) {
        KickClient(client, "%t", "KAC_FailedToReply");
    } else {
        decl String:f_sName[64];
        decl Handle:f_hCVar;
        if (g_iSize < 1) {
            PrintToServer("Nothing in convar list");
            CreateTimer(10, CVars_PeriodicTimer, client, 0);
            return Action:4;
        }
        f_hCVar = g_hCurrentQuery[client][0][0];
        if (GetArrayCell(f_hCVar, 8, 0, false)) {
            g_hPeriodicTimer[client] = CreateTimer(0,1, CVars_PeriodicTimer, client, 0);
        } else {
            GetArrayString(f_hCVar, 0, f_sName, 64);
            QueryClientConVar(client, f_sName, ConVarQueryFinished:123, client);
            g_hReplyTimer[client] = CreateTimer(15, CVars_ReplyTimer, GetClientUserId(client), 0);
        }
    }
    return Action:4;
}

public Action:CVars_ReplicateTimer(Handle:timer, f_hConVar)
{
    decl String:f_sName[64];
    GetConVarName(f_hConVar, f_sName, 64);
    new var1;
    if (g_bCVarCVarsEnabled) {
        SetConVarInt(f_hConVar, 0, false, false);
    }
    CVars_ReplicateConVar(f_hConVar);
    return Action:4;
}

public Action:CVars_ReplicateCheck(Handle:timer, f_hIndex)
{
    SetArrayCell(f_hIndex, 8, any:0, 0, false);
    return Action:4;
}


/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "CVars_QueryCallback" (number 118)
public CVars_Replicate(Handle:convar, String:oldvalue[], String:newvalue[])
{
    decl String:f_sName[64];
    decl Handle:f_hCVarIndex;
    decl Handle:f_hTimer;
    GetConVarName(convar, f_sName, 64);
    if (GetTrieValue(g_hCVarIndex, f_sName, f_hCVarIndex)) {
        f_hTimer = GetArrayCell(f_hCVarIndex, 8, 0, false);
        if (f_hTimer) {
            CloseHandle(f_hTimer);
        }
        f_hTimer = CreateTimer(30, CVars_ReplicateCheck, f_hCVarIndex, 0);
        SetArrayCell(f_hCVarIndex, 8, f_hTimer, 0, false);
    }
    CreateTimer(0,1, CVars_ReplicateTimer, convar, 0);
    return 0;
}

bool:CVars_IsValidName(String:f_sName[])
{
    if (f_sName[0]) {
        new len = strlen(f_sName);
        new i = 0;
        while (i < len) {
            if (!IsValidConVarChar(f_sName[i])) {
                return false;
            }
            i++;
        }
        return true;
    }
    return false;
}

bool:CVars_AddCVar(String:f_sName[], f_iComparisonType, f_iAction, String:f_sValue[], Float:f_fValue2, f_iImportance, String:f_sAlternative[])
{
    new Handle:f_hConVar = 0;
    new Handle:f_hArray = 0;
    new c = 0;
    do {
        f_sName[c] = CharToLower(f_sName[c]);
        c++;
    } while (f_sName[c]);
    f_hConVar = FindConVar(f_sName);
    new var2;
    if (f_hConVar) {
        f_iComparisonType = 0;
    } else {
        f_hConVar = 0;
    }
    if (GetTrieValue(g_hCVarIndex, f_sName, f_hArray)) {
        SetArrayString(f_hArray, 0, f_sName);
        SetArrayCell(f_hArray, 1, f_iComparisonType, 0, false);
        SetArrayCell(f_hArray, 2, f_hConVar, 0, false);
        SetArrayCell(f_hArray, 3, f_iAction, 0, false);
        SetArrayString(f_hArray, 4, f_sValue);
        SetArrayCell(f_hArray, 5, f_fValue2, 0, false);
        SetArrayString(f_hArray, 6, f_sAlternative);
    } else {
        f_hArray = CreateArray(64, 0);
        PushArrayString(f_hArray, f_sName);
        PushArrayCell(f_hArray, f_iComparisonType);
        PushArrayCell(f_hArray, f_hConVar);
        PushArrayCell(f_hArray, f_iAction);
        PushArrayString(f_hArray, f_sValue);
        PushArrayCell(f_hArray, f_fValue2);
        PushArrayString(f_hArray, f_sAlternative);
        PushArrayCell(f_hArray, f_iImportance);
        PushArrayCell(f_hArray, any:0);
        if (!SetTrieValue(g_hCVarIndex, f_sName, f_hArray, true)) {
            CloseHandle(f_hArray);
            KAC_Log("Unable to add convar to Trie link list %s.", f_sName);
            return false;
        }
        PushArrayCell(g_hCVars, f_hArray);
        g_iSize = GetArraySize(g_hCVars);
        new var3;
        if (f_iImportance) {
            CVars_CreateNewOrder();
        }
    }
    return true;
}

bool:CVars_RemoveCVar(String:f_sName[])
{
    decl Handle:f_hConVar;
    decl f_iIndex;
    if (!GetTrieValue(g_hCVarIndex, f_sName, f_hConVar)) {
        return false;
    }
    f_iIndex = FindValueInArray(g_hCVars, f_hConVar);
    if (f_iIndex == -1) {
        return false;
    }
    new i = 0;
    while (i <= MaxClients) {
        if (f_hConVar == g_hCurrentQuery[i][0][0]) {
            g_hCurrentQuery[i] = 0;
            i++;
        }
        i++;
    }
    RemoveFromArray(g_hCVars, f_iIndex);
    RemoveFromTrie(g_hCVarIndex, f_sName);
    CloseHandle(f_hConVar);
    g_iSize = GetArraySize(g_hCVars);
    return true;
}


/* ERROR! Unrecognized opcode: genarray_z */
 function "CVars_CreateNewOrder" (number 123)
CVars_ReplicateConVar(Handle:f_hConVar)
{
    decl String:f_sValue[64];
    GetConVarString(f_hConVar, f_sValue, 64);
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            SendConVarValue(i, f_hConVar, f_sValue);
            i++;
        }
        i++;
    }
    return 0;
}

public Rcon_OnPluginStart()
{
    g_hCvarRconPass = FindConVar("rcon_password");
    HookConVarChange(g_hCvarRconPass, ConVarChanged:307);
    new Handle:hConVar = FindConVar("sv_rcon_minfailuretime");
    if (hConVar) {
        SetConVarBounds(hConVar, ConVarBounds:0, true, 1);
        SetConVarInt(hConVar, 1, false, false);
    }
    hConVar = FindConVar("sv_rcon_minfailures");
    if (hConVar) {
        SetConVarBounds(hConVar, ConVarBounds:0, true, 9999999);
        SetConVarBounds(hConVar, ConVarBounds:1, true, 9999999);
        SetConVarInt(hConVar, 9999999, false, false);
    }
    hConVar = FindConVar("sv_rcon_maxfailures");
    if (hConVar) {
        SetConVarBounds(hConVar, ConVarBounds:0, true, 9999999);
        SetConVarBounds(hConVar, ConVarBounds:1, true, 9999999);
        SetConVarInt(hConVar, 9999999, false, false);
    }
    return 0;
}

public Rcon_OnConfigsExecuted()
{
    if (!g_bRconLocked) {
        GetConVarString(g_hCvarRconPass, g_sRconRealPass, 128);
        g_bRconLocked = 1;
    }
    return 0;
}

public OnRconPassChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new var1;
    if (g_bRconLocked) {
        KAC_Log("Rcon password changed to \"%s\". Reverting back to original config value.", newValue);
        SetConVarString(g_hCvarRconPass, g_sRconRealPass, false, false);
    }
    return 0;
}

public Eye_OnPluginStart()
{
    g_hCVarEyeType = CreateConVar("kac_eye", "2", "???????? ? ???? ?????? ??????. (0 - ?????????.), (1 - ????????????? ??????????????.), (2 - ?????? ?????????????.)\nEnable the eye detection routine. (0 = Disabled, 1 = Warn Admins, 2 = Ban).", 262144, true, 0, true, 2);
    Eye_OnSettingsChanged(g_hCVarEyeType, "", "");
    HookConVarChange(g_hCVarEyeType, ConVarChanged:183);
    return 0;
}

public Eye_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    g_iEyeBlock = GetConVarInt(convar);
    new bool:bNewValueEye = GetConVarBool(convar);
    new var1;
    if (bNewValueEye) {
        g_bEnabledEye = 1;
    } else {
        new var2;
        if (!bNewValueEye) {
            g_bEnabledEye = 0;
        }
    }
    return 0;
}

public Eye_OnClientDisconnect_Post(client)
{
    g_fDetectedTime[client] = 0;
    return 0;
}

public Action:Eye_OnPlayerRunCmd(client, Float:angles[3])
{
    if (!g_bEnabledEye) {
        return Action:0;
    }
    if (angles[0] > 180) {
        new var4 = angles;
        var4[0] = FloatSub(var4[0], 360);
    }
    if (angles[8] > 180) {
        new var5 = angles[8];
        var5 = FloatSub(var5, 360);
    }
    new var1;
    if (angles[0] > -90) {
        return Action:0;
    }
    new var2;
    if (IsFakeClient(client)) {
        return Action:0;
    }
    new flags = GetEntityFlags(client);
    new var3;
    if (flags & 32) {
        return Action:0;
    }
    Eyetest_Detected(client, angles);
    return Action:0;
}


/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "Eyetest_Detected" (number 132)
public SpinHack_OnPluginStart()
{
    g_hCVarSpinHack = CreateConVar("kac_spinhack_detected", "1", "SpinHack detection module. (0 = Disabled, 1 = Warn Admins, 2 = Kick, 3 = Ban)", 262144, true, 0, true, 3);
    SpinHack_OnSettingsChanged(g_hCVarSpinHack, "", "");
    HookConVarChange(g_hCVarSpinHack, ConVarChanged:337);
    return 0;
}

public SpinHack_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:g_bSpinHackMode = GetConVarBool(convar);
    g_iSpinHackMode = GetConVarInt(convar);
    new var1;
    if (g_bSpinHackMode) {
        SpinHack_Enable();
    } else {
        new var2;
        if (!g_bSpinHackMode) {
            SpinHack_Disable();
        }
    }
    return 0;
}

public SpinHack_Enable()
{
    g_bSpinHackEnabled = 1;
    g_hSpinLoop = CreateTimer(1, Timer_CheckSpins, any:0, 1);
    return 0;
}

public SpinHack_Disable()
{
    g_bSpinHackEnabled = 0;
    if (g_hSpinLoop) {
        KillTimer(g_hSpinLoop, false);
        g_hSpinLoop = 0;
    }
    return 0;
}

public SpinHack_OnClientDisconnect(client)
{
    g_iSpinCount[client] = 0;
    g_fSensitivity[client] = 0;
    return 0;
}

public Action:Timer_CheckSpins(Handle:timer)
{
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (!IsClientInGame(i)) {
        } else {
            new var2;
            if (g_fAngleDiff[i][0][0] > 2,01787E-42) {
                g_iSpinCount[i]++;
                if (g_iSpinCount[i][0][0] == 1) {
                    QueryClientConVar(i, "sensitivity", ConVarQueryFinished:313, GetClientUserId(i));
                }
                new var3;
                if (g_iSpinCount[i][0][0] == 15) {
                    Spinhack_Detected(i);
                }
            } else {
                g_iSpinCount[i] = 0;
            }
            g_fAngleDiff[i] = 0;
        }
        i++;
    }
    return Action:0;
}

public Query_MouseCheck(QueryCookie:cookie, client, ConVarQueryResult:result, String:cvarName[], String:cvarValue[], userid)
{
    new var1;
    if (result) {
        g_fSensitivity[client] = StringToFloat(cvarValue);
    }
    return 0;
}


/* ERROR! unknown operator */
 function "SpinHack_OnPlayerRunCmd" (number 140)

/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "Spinhack_Detected" (number 141)
public AntiReJoin_OnPluginStart()
{
    g_hCVarAntiRespawn = CreateConVar("kac_antirejoin", "1", "?????? ?? ??? ?????? ??????????? ????? ??????????????? ? ???????.\nThe module does not allow dead to revive after reconnection to a server.", 262144, true, 0, true, 1);
    AntiReJoin_OnSettingsChanged(g_hCVarAntiRespawn, "", "");
    HookConVarChange(g_hCVarAntiRespawn, ConVarChanged:59);
    return 0;
}

public AntiReJoin_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueAntiRespawn = GetConVarBool(convar);
    new var1;
    if (bNewValueAntiRespawn) {
        AntiReJoin_Enable();
    } else {
        new var2;
        if (!bNewValueAntiRespawn) {
            AntiReJoin_Disable();
        }
    }
    return 0;
}

public AntiReJoin_Enable()
{
    g_bAntiRespawn = 1;
    g_hClientSpawned = CreateTrie();
    g_hCvarRestartGame = FindConVar("mp_restartgame");
    HookConVarChange(g_hCvarRestartGame, ConVarChanged:53);
    AddCommandListener(CommandListener:149, "joinclass");
    HookEvent("player_spawn", EventHook:47, EventHookMode:1);
    HookEvent("player_death", EventHook:45, EventHookMode:1);
    HookEvent("round_start", EventHook:51, EventHookMode:1);
    HookEvent("round_end", EventHook:49, EventHookMode:1);
    return 0;
}

public AntiReJoin_Disable()
{
    g_bAntiRespawn = 0;
    if (g_hClientSpawned) {
        CloseHandle(g_hClientSpawned);
        g_hClientSpawned = 0;
    }
    UnhookConVarChange(g_hCvarRestartGame, ConVarChanged:53);
    g_hCvarRestartGame = 0;
    RemoveCommandListener(CommandListener:149, "joinclass");
    UnhookEvent("player_spawn", EventHook:47, EventHookMode:1);
    UnhookEvent("player_death", EventHook:45, EventHookMode:1);
    UnhookEvent("round_start", EventHook:51, EventHookMode:1);
    UnhookEvent("round_end", EventHook:49, EventHookMode:1);
    return 0;
}

public AntiReJoin_OnMapEnd()
{
    g_bClientMapStarted = 0;
    if (g_bAntiRespawn) {
        ClearData();
    }
    return 0;
}


/* ERROR! Das Objekt des Typs "Lysis.DConstant" kann nicht in Typ "Lysis.DDeclareLocal" umgewandelt werden. */
 function "Command_JoinClass" (number 147)
public Action:AntiReJoin_EventPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    decl String:f_sAuthID[64];
    new var1;
    if (!client) {
        return Action:0;
    }
    RemoveFromTrie(g_hClientSpawned, f_sAuthID);
    return Action:0;
}

public Action:AntiReJoin_EventPlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    decl String:f_sAuthID[64];
    new var1;
    if (!client) {
        return Action:0;
    }
    SetTrieValue(g_hClientSpawned, f_sAuthID, any:1, true);
    return Action:0;
}

public Action:AntiReJoin_EventRoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
    g_bClientMapStarted = 1;
    ClearData();
    return Action:0;
}

public Action:AntiReJoin_EventRoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
    ClearData();
    return Action:0;
}

public AntiReJoin_Hook_RestartGame(Handle:convar, String:oldValue[], String:newValue[])
{
    if (0 < StringToInt(newValue, 10)) {
        ClearData();
    }
    return 0;
}

ClearData()
{
    ClearTrie(g_hClientSpawned);
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            FakeClientCommandEx(i, "joinclass %d", g_iClientClass[i]);
            g_iClientClass[i] = -1;
            i++;
        }
        i++;
    }
    return 0;
}

public AntiFlash_OnPluginStart()
{
    g_hCVarAntiFlash = CreateConVar("kac_antiflash", "1", "??????????? No-Flash ????, ????? ????? ?????????.\nPrevent No-Flash cheats from working when a player is fully blind", 262144, true, 0, true, 1);
    AntiFlash_OnSettingsChanged(g_hCVarAntiFlash, "", "");
    HookConVarChange(g_hCVarAntiFlash, ConVarChanged:35);
    return 0;
}

public AntiFlash_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValue = GetConVarBool(convar);
    new var1;
    if (bNewValue) {
        if (!g_bSDKHooksLoaded) {
            LogError("SDKHooks is not running. Cannot enable CS:S Anti-Flash.");
            SetConVarBool(convar, false, false, false);
            return 0;
        }
        AntiFlash_UnloadNoTeamFlashPlugin();
        AntiFlash_Enable();
    } else {
        new var2;
        if (!bNewValue) {
            AntiFlash_Disable();
            AntiFlash_LoadNoTeamFlashPlugin();
        }
    }
    return 0;
}

AntiFlash_Enable()
{
    g_bFlashEnabled = 1;
    HookEvent("player_blind", EventHook:27, EventHookMode:1);
    new var1 = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
    g_iFlashDuration = var1;
    if (var1 == -1) {
        SetFailState("Failed to find CCSPlayer::m_flFlashDuration offset");
    }
    new var2 = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
    g_iFlashAlpha = var2;
    if (var2 == -1) {
        SetFailState("Failed to find CCSPlayer::m_flFlashMaxAlpha offset");
    }
    return 0;
}

AntiFlash_Disable()
{
    g_bFlashEnabled = 0;
    UnhookEvent("player_blind", EventHook:27, EventHookMode:1);
    g_iFlashDuration = -1;
    g_iFlashAlpha = -1;
    return 0;
}

public AntiFlash_OnClientDisconnect(client)
{
    g_fFlashedUntil[client] = 0;
    return 0;
}

public AntiFlash_EventPlayerBlind(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new var2 = client;
    new var1;
    if (MaxClients >= var2 & 1 <= var2) {
        new Float:alpha = GetEntDataFloat(client, g_iFlashAlpha);
        if (alpha < 255) {
            return 0;
        }
        new Float:duration = GetEntDataFloat(client, g_iFlashDuration);
        if (duration > 2,5) {
            g_fFlashedUntil[client] = FloatSub(FloatAdd(GetGameTime(), duration), 2,5);
        } else {
            g_fFlashedUntil[client] = FloatAdd(GetGameTime(), FloatMul(0,1, duration));
        }
        if (!g_bFlashHooked) {
            AntiFlash_HookAll();
        }
        CreateTimer(duration, Timer_FlashEnded, any:0, 0);
    }
    return 0;
}

public Action:Timer_FlashEnded(Handle:timer)
{
    new Float:fGameTime = GetGameTime();
    new i = 1;
    while (i <= MaxClients) {
        if (g_fFlashedUntil[i][0][0] > fGameTime) {
            return Action:4;
        }
        i++;
    }
    if (g_bFlashHooked) {
        AntiFlash_UnhookAll();
    }
    return Action:4;
}

public Action:AntiFlash_SetTransmit(entity, client)
{
    new var3 = client;
    new var1;
    if (!var3 <= MaxClients & 1 <= var3) {
        return Action:0;
    }
    new var2;
    if (g_fFlashedUntil[client][0][0]) {
        return Action:3;
    }
    g_fFlashedUntil[client] = 0;
    return Action:0;
}

AntiFlash_HookAll()
{
    g_bFlashHooked = 1;
    new i = 1;
    while (i <= MaxClients) {
        if (IsClientInGame(i)) {
            SDKHook(i, SDKHookType:6, SDKHookCB:37);
            i++;
        }
        i++;
    }
    return 0;
}

AntiFlash_UnhookAll()
{
    g_bFlashHooked = 0;
    new i = 1;
    while (i <= MaxClients) {
        if (IsClientInGame(i)) {
            SDKUnhook(i, SDKHookType:6, SDKHookCB:37);
            i++;
        }
        i++;
    }
    return 0;
}

public WallHack_OnPluginStart()
{
    g_hCvarWallhack = CreateConVar("kac_antiwallhack", "1", "???????? Anti-Wallhack. ??? ???????? ????????????? ???????????? ?????????? ?????? ???????.\nEnable Anti-Wallhack. This will increase your server's CPU usage.", 262144, true, 0, true, 1);
    WallHack_OnSettingsChanged(g_hCvarWallhack, "", "");
    HookConVarChange(g_hCvarWallhack, ConVarChanged:379);
    g_hTimeToTick = CreateConVar("kac_antiwallhack_ticktime", "0.75", "????????? Tick Anti-WallHack.\nTick Time Anti-WallHack", 262144, true, 0,1, true, 2);
    WallHackTimeToTick_OnSettingsChanged(g_hTimeToTick, "", "");
    HookConVarChange(g_hTimeToTick, ConVarChanged:365);
    new Handle:hCvar = 0;
    new iTickRate = RoundToFloor(FloatDiv(1, GetTickInterval()));
    new var1 = FindConVar("sv_minupdaterate");
    hCvar = var1;
    if (var1) {
        SetConVarInt(hCvar, iTickRate, false, false);
    }
    new var2 = FindConVar("sv_maxupdaterate");
    hCvar = var2;
    if (var2) {
        SetConVarInt(hCvar, iTickRate, false, false);
    }
    new var3 = FindConVar("sv_client_min_interp_ratio");
    hCvar = var3;
    if (var3) {
        SetConVarInt(hCvar, 0, false, false);
    }
    new var4 = FindConVar("sv_client_max_interp_ratio");
    hCvar = var4;
    if (var4) {
        SetConVarInt(hCvar, 1, false, false);
    }
    HookEvent("player_spawn", EventHook:175, EventHookMode:1);
    HookEvent("player_death", EventHook:175, EventHookMode:1);
    HookEvent("player_team", EventHook:175, EventHookMode:1);
    g_bIsMod = 0;
    new i = 0;
    while (i < 66) {
        new var5 = g_bIsVisible;
        var5[0][0][var5][i] = 1;
        i++;
    }
    return 0;
}

public WallHack_OnClientPutInServer(client)
{
    if (g_bEnabled) {
        Wallhack_Hook(client);
        Wallhack_UpdateClientCache(client);
    }
    return 0;
}

public WallHack_OnClientDisconnect(client)
{
    g_bProcess[client] = 0;
    g_bIgnore[client] = 0;
    return 0;
}

public Event_PlayerStateChanged(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new var2 = client;
    new var1;
    if (MaxClients >= var2 & 1 <= var2) {
        Wallhack_UpdateClientCache(client);
    }
    return 0;
}


/* ERROR! Das Objekt des Typs "Lysis.DReturn" kann nicht in Typ "Lysis.DJumpCondition" umgewandelt werden. */
 function "Wallhack_UpdateClientCache" (number 168)
public WallHack_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValue = GetConVarBool(convar);
    new var1;
    if (bNewValue) {
        if (g_bSDKHooksLoaded) {
            Wallhack_Enable();
        }
        LogError("SDKHooks is not running. Cannot enable Anti-WallHack.");
        SetConVarInt(convar, 0, false, false);
        return 0;
    } else {
        new var2;
        if (!bNewValue) {
            Wallhack_Disable();
        }
    }
    return 0;
}

public WallHackTimeToTick_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    g_iCacheTicks = RoundToNearest(FloatDiv(GetConVarFloat(convar), GetTickInterval()));
    return 0;
}

public Wallhack_Enable()
{
    g_bEnabled = 1;
    AddNormalSoundHook(NormalSHook:187);
    farESP_Enable();
    new i = 1;
    while (i <= MaxClients) {
        if (IsClientInGame(i)) {
            Wallhack_Hook(i);
            Wallhack_UpdateClientCache(i);
            i++;
        }
        i++;
    }
    new client = -1;
    new i = MaxClients + 1;
    while (i < 2048) {
        new var1;
        if (IsValidEntity(i)) {
            client = GetEntPropEnt(i, PropType:1, "m_hOwnerEntity", 0);
            new var2 = client;
            if (MaxClients >= var2 & 1 <= var2) {
                g_iWeaponOwner[i] = client;
                SDKHook(i, SDKHookType:6, SDKHookCB:191);
                i++;
            }
            i++;
        }
        i++;
    }
    return 0;
}

public Wallhack_Disable()
{
    g_bEnabled = 0;
    RemoveNormalSoundHook(NormalSHook:187);
    farESP_Disable();
    new i = 1;
    while (i <= MaxClients) {
        if (IsClientInGame(i)) {
            Wallhack_Unhook(i);
            i++;
        }
        i++;
    }
    new i = MaxClients + 1;
    while (i < 2048) {
        if (g_iWeaponOwner[i][0][0]) {
            g_iWeaponOwner[i] = 0;
            SDKUnhook(i, SDKHookType:6, SDKHookCB:191);
            i++;
        }
        i++;
    }
    return 0;
}

Wallhack_Hook(client)
{
    SDKHook(client, SDKHookType:6, SDKHookCB:189);
    SDKHook(client, SDKHookType:16, SDKHookCB:197);
    SDKHook(client, SDKHookType:15, SDKHookCB:195);
    return 0;
}

Wallhack_Unhook(client)
{
    SDKUnhook(client, SDKHookType:6, SDKHookCB:189);
    SDKUnhook(client, SDKHookType:16, SDKHookCB:197);
    SDKUnhook(client, SDKHookType:15, SDKHookCB:195);
    return 0;
}

public OnEntityCreated(entity, String:classname[])
{
    new var1;
    if (entity > MaxClients) {
        g_iWeaponOwner[entity] = 0;
    }
    return 0;
}

public OnEntityDestroyed(entity)
{
    new var1;
    if (entity > MaxClients) {
        g_iWeaponOwner[entity] = 0;
    }
    return 0;
}

public Action:Hook_WeaponEquip(client, weapon)
{
    new var1;
    if (weapon > MaxClients) {
        g_iWeaponOwner[weapon] = client;
        SDKHook(weapon, SDKHookType:6, SDKHookCB:191);
    }
    return Action:0;
}

public Action:Hook_WeaponDrop(client, weapon)
{
    new var1;
    if (weapon > MaxClients) {
        g_iWeaponOwner[weapon] = 0;
        SDKUnhook(weapon, SDKHookType:6, SDKHookCB:191);
    }
    return Action:0;
}


/* ERROR! Unrecognized opcode: genarray */
 function "Hook_NormalSound" (number 179)

/* ERROR! Unrecognized opcode: load_both */
 function "OnGameFrame" (number 180)

/* ERROR! Unrecognized opcode: load_both */
 function "Hook_SetTransmit" (number 181)
public Action:Hook_SetTransmitWeapon(entity, client)
{
    new var1;
    if (g_bIsVisible[g_iWeaponOwner[entity][0][0]][0][0][client]) {
        var1 = 0;
    } else {
        var1 = 3;
    }
    return var1;
}

public Action:WallHack_OnPlayerRunCmd(client)
{
    static iLastReset[66];
    if (g_iTickCount != 126284[client]) {
        g_iCmdTickCount[client] = 0;
        126284[client] = g_iTickCount;
    }
    g_iCmdTickCount[client]++;
    return Action:0;
}


/* ERROR! unknown operator */
 function "UpdateClientData" (number 184)
bool:IsAbleToSee(entity, client)
{
    if (IsPointVisible(g_vEyePos[client][0][0], g_vAbsCentre[entity][0][0])) {
        return true;
    }
    if (IsFwdVecVisible(g_vEyePos[client][0][0], g_vEyeAngles[entity][0][0], g_vEyePos[entity][0][0])) {
        return true;
    }
    if (IsRectangleVisible(g_vEyePos[client][0][0], g_vAbsCentre[entity][0][0], g_vMins[entity][0][0], g_vMaxs[entity][0][0], 1,3)) {
        return true;
    }
    if (IsRectangleVisible(g_vEyePos[client][0][0], g_vAbsCentre[entity][0][0], g_vMins[entity][0][0], g_vMaxs[entity][0][0], 0,65)) {
        return true;
    }
    return false;
}


/* ERROR! Das Objekt des Typs "Lysis.DReturn" kann nicht in Typ "Lysis.DJumpCondition" umgewandelt werden. */
 function "Filter_NoPlayers" (number 186)

/* ERROR! unknown operator */
 function "IsPointVisible" (number 187)
bool:IsFwdVecVisible(Float:start[3], Float:angles[3], Float:end[3])
{
    decl Float:fwd[3];
    GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, 50);
    AddVectors(end, fwd, fwd);
    return IsPointVisible(start, fwd);
}


/* ERROR! unknown operator */
 function "IsRectangleVisible" (number 189)
farESP_Enable()
{
    new var1 = FindEntityByClassname(0, "cs_player_manager");
    g_iPlayerManager = var1;
    if (var1 == -1) {
        return 0;
    }
    g_iPlayerSpotted = FindSendPropOffs("CCSPlayerResource", "m_bPlayerSpotted");
    SDKHook(g_iPlayerManager, SDKHookType:21, SDKHookCB:311);
    g_msgUpdateRadar = GetUserMessageId("UpdateRadar");
    HookUserMessage(g_msgUpdateRadar, MsgHook:193, true, MsgPostHook:-1);
    g_hRadarTimer = CreateTimer(1, Timer_UpdateRadar, any:0, 1);
    g_bFarEspEnabled = 1;
    return 0;
}

farESP_Disable()
{
    SDKUnhook(g_iPlayerManager, SDKHookType:21, SDKHookCB:311);
    new i = 0;
    while (i < 66) {
        g_bPlayerSpotted[i] = 0;
        i++;
    }
    KillTimer(g_hRadarTimer, false);
    g_hRadarTimer = 0;
    UnhookUserMessage(g_msgUpdateRadar, MsgHook:193, true);
    g_bFarEspEnabled = 0;
    return 0;
}

public WallHack_OnMapStart()
{
    new var1;
    if (g_bEnabled) {
        farESP_Enable();
    }
    return 0;
}

public WallHack_OnMapEnd()
{
    if (g_bFarEspEnabled) {
        farESP_Disable();
    }
    return 0;
}

public Action:Hook_UpdateRadar(UserMsg:msg_id, Handle:bf, players[], playersNum, bool:reliable, bool:init)
{
    return Action:3;
}

public PlayerManager_ThinkPost(entity)
{
    if (!g_bFarEspEnabled) {
        return 0;
    }
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (g_bProcess[i][0][0]) {
            if (!g_bPlayerSpotted[i][0][0]) {
                g_bPlayerSpotted[i] = 1;
                SendClientDataToAll(i);
                i++;
            }
            i++;
        } else {
            g_bPlayerSpotted[i] = 0;
            i++;
        }
        i++;
    }
    return 0;
}


/* ERROR! Unrecognized opcode: genarray */
 function "Timer_UpdateRadar" (number 196)

/* ERROR! Unrecognized opcode: genarray */
 function "SendClientDataToAll" (number 197)
public SpeedHack_OnPluginStart()
{
    g_hCVarSpeedhack = CreateConVar("kac_speedhack_block", "1", "?????????? ????? SpeedHack.\nBlocking cheats SpeedHack.", 262144, true, 0, true, 1);
    SpeedHack_OnSettingsChanged(g_hCVarSpeedhack, "", "");
    HookConVarChange(g_hCVarSpeedhack, ConVarChanged:325);
    g_iTickRate = RoundToCeil(FloatMul(1,5, FloatDiv(1, GetTickInterval())));
    return 0;
}

public SpeedHack_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueSh = GetConVarBool(convar);
    new var1;
    if (bNewValueSh) {
        SpeedHack_Enable();
    } else {
        new var2;
        if (!bNewValueSh) {
            SpeedHack_Disable();
        }
    }
    return 0;
}

SpeedHack_Enable()
{
    g_bSpeedEnabled = 1;
    hShTimerResTicks = CreateTimer(1, Timer_ResetTicks, any:0, 1);
    g_hCvarFutureTicks = FindConVar("sv_max_usercmd_future_ticks");
    if (g_hCvarFutureTicks) {
        OnTickCvarChanged(g_hCvarFutureTicks, "", "");
        HookConVarChange(g_hCvarFutureTicks, ConVarChanged:309);
    }
    return 0;
}

SpeedHack_Disable()
{
    g_bSpeedEnabled = 0;
    if (g_hCvarFutureTicks) {
        UnhookConVarChange(g_hCvarFutureTicks, ConVarChanged:309);
    }
    if (hShTimerResTicks) {
        KillTimer(hShTimerResTicks, false);
        hShTimerResTicks = 0;
    }
    return 0;
}

public SpeedHack_OnClientDisconnect_Post(client)
{
    g_iShTickCount[client] = 0;
    return 0;
}

public OnTickCvarChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    if (GetConVarInt(convar) != 1) {
        SetConVarInt(convar, 1, false, false);
    }
    return 0;
}

public Action:Timer_ResetTicks(Handle:timer)
{
    new i = 1;
    while (i <= MaxClients) {
        g_iShTickCount[i] = 0;
        i++;
    }
    return Action:0;
}

public Action:SpeedHack_OnPlayerRunCmd(client)
{
    if (!g_bSpeedEnabled) {
        return Action:0;
    }
    new var1 = g_iShTickCount[client];
    var1++;
    if (var1[0][0] > g_iTickRate) {
        return Action:3;
    }
    return Action:0;
}

public AntiSmoke_OnPluginStart()
{
    g_hCVarAntiSmoke = CreateConVar("kac_antismoke", "0", "1 ????????, 0 ?????????. ?????????? ????????? No-Smoke. (??????????? ?? ?????? ??????, ??? ?????? ????? ????)\nPrevent No-Smoke cheats from working when a player is immersed in smoke.", 262144, true, 0, true, 1);
    AntiSmoke_OnSettingsChanged(g_hCVarAntiSmoke, "", "");
    HookConVarChange(g_hCVarAntiSmoke, ConVarChanged:77);
    return 0;
}

public AntiSmoke_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValue = GetConVarBool(convar);
    new var1;
    if (bNewValue) {
        if (!g_bSDKHooksLoaded) {
            LogError("SDKHooks is not running. Cannot enable CS:S Anti-Smoke.");
            SetConVarBool(convar, false, false, false);
            return 0;
        }
        AntiSmoke_Enable();
    } else {
        new var2;
        if (!bNewValue) {
            AntiSmoke_Disable();
        }
    }
    return 0;
}

public AntiSmoke_Enable()
{
    g_bSmokeEnabled = 1;
    g_hSmokes = CreateArray(3, 0);
    HookEvent("smokegrenade_detonate", EventHook:67, EventHookMode:1);
    HookEvent("round_start", EventHook:65, EventHookMode:2);
    HookEvent("round_end", EventHook:65, EventHookMode:2);
    return 0;
}

public AntiSmoke_Disable()
{
    g_bSmokeEnabled = 0;
    if (g_hSmokes) {
        CloseHandle(g_hSmokes);
        g_hSmokes = 0;
    }
    UnhookEvent("smokegrenade_detonate", EventHook:67, EventHookMode:1);
    UnhookEvent("round_start", EventHook:65, EventHookMode:2);
    UnhookEvent("round_end", EventHook:65, EventHookMode:2);
    return 0;
}

public AntiSmoke_OnMapEnd()
{
    if (g_bSmokeHooked) {
        AntiSmoke_UnhookAll();
    }
    return 0;
}

public AntiSmoke_OnClientDisconnect(client)
{
    g_bIsInSmoke[client] = 0;
    return 0;
}

public AntiSmoke_EventSmokeDetonate(Handle:event, String:name[], bool:dontBroadcast)
{
    decl Float:vSmoke[3];
    vSmoke[0] = GetEventFloat(event, "x");
    vSmoke[4] = GetEventFloat(event, "y");
    vSmoke[8] = GetEventFloat(event, "z");
    PushArrayArray(g_hSmokes, vSmoke, -1);
    if (!g_bSmokeHooked) {
        AntiSmoke_HookAll();
    }
    CreateTimer(15, Timer_SmokeEnded, any:0, 0);
    return 0;
}

public AntiSmoke_EventRoundChanged(Handle:event, String:name[], bool:dontBroadcast)
{
    if (g_bSmokeHooked) {
        AntiSmoke_UnhookAll();
    }
    return 0;
}

public Action:Timer_SmokeEnded(Handle:timer)
{
    if (GetArraySize(g_hSmokes)) {
        RemoveFromArray(g_hSmokes, 0);
    }
    new var1;
    if (!GetArraySize(g_hSmokes)) {
        AntiSmoke_UnhookAll();
    }
    return Action:4;
}

public Action:Timer_SmokeCheck(Handle:timer)
{
    decl Float:vClient[3];
    decl Float:vSmoke[3];
    decl Float:fDistance;
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            GetClientAbsOrigin(i, vClient);
            new idx = 0;
            while (GetArraySize(g_hSmokes) > idx) {
                GetArrayArray(g_hSmokes, idx, vSmoke, -1);
                fDistance = GetVectorDistance(vClient, vSmoke, true);
                if (fDistance < 3,503246E-42) {
                    g_bIsInSmoke[i] = 1;
                    i++;
                }
                g_bIsInSmoke[i] = 0;
                idx++;
            }
            i++;
        }
        i++;
    }
    return Action:0;
}

public Action:AntiSmoke_HookSetTransmit(entity, client)
{
    new var2 = client;
    new var1;
    if (!var2 <= MaxClients & 1 <= var2) {
        return Action:0;
    }
    if (g_bIsInSmoke[client][0][0]) {
        return Action:3;
    }
    return Action:0;
}

AntiSmoke_HookAll()
{
    g_bSmokeHooked = 1;
    if (!g_hSmokeLoop) {
        g_hSmokeLoop = CreateTimer(0,1, Timer_SmokeCheck, any:0, 1);
    }
    new i = 1;
    while (i <= MaxClients) {
        if (IsClientInGame(i)) {
            SDKHook(i, SDKHookType:6, SDKHookCB:69);
            i++;
        }
        i++;
    }
    return 0;
}

AntiSmoke_UnhookAll()
{
    g_bSmokeHooked = 0;
    if (g_hSmokeLoop) {
        KillTimer(g_hSmokeLoop, false);
        g_hSmokeLoop = 0;
    }
    new i = 1;
    while (i <= MaxClients) {
        if (IsClientInGame(i)) {
            SDKUnhook(i, SDKHookType:6, SDKHookCB:69);
            i++;
        }
        i++;
    }
    ClearArray(g_hSmokes);
    return 0;
}

public Network2_Event_Start()
{
    g_hCVarNetUseUpdate = CreateConVar("kac_net_autoupdate", "1", "Use the Auto-Update feature.", 0, false, 0, false, 0);
    g_bCVarNetUseUpdate = GetConVarBool(g_hCVarNetUseUpdate);
    g_hCVarNetAllowUpdateToBeta = CreateConVar("kac_net_allow_update_to_beta", "1", "Allow update to beta version of plugin.", 0, false, 0, false, 0);
    g_bCVarNetAllowUpdateToBeta = GetConVarBool(g_hCVarNetAllowUpdateToBeta);
    HookConVarChange(g_hCVarNetUseUpdate, ConVarChanged:225);
    HookConVarChange(g_hCVarNetAllowUpdateToBeta, ConVarChanged:225);
    g_hUpdateTimer = CreateTimer(30, Network2_UpdateTimer, any:0, 0);
    return 0;
}

public Network2_Event_PluginUnload()
{
    Network2_ClearValues();
    return 0;
}

public Network2_ConVarChange(Handle:convar, String:oldValue[], String:newValue[])
{
    g_bCVarNetUseUpdate = GetConVarBool(g_hCVarNetUseUpdate);
    g_bCVarNetAllowUpdateToBeta = GetConVarBool(g_hCVarNetAllowUpdateToBeta);
    new var1;
    if (g_bCVarNetEnabled) {
        g_hUpdateTimer = CreateTimer(5, Network2_UpdateTimer, any:0, 0);
    }
    return 0;
}

public Action:Network2_UpdateTimer(Handle:timer, we)
{
    g_hUpdateTimer = 0;
    new var1;
    if (g_iUpdateState) {
        g_iUpdateState = 2;
        g_hUpdateSocket = SocketCreate(SocketType:1, Network2_OnSocketError);
        SocketConnect(g_hUpdateSocket, Network2_OnSocketConnect, Network2_OnSocketReceive, Network2_OnSocketDisconnect, AutoUpdater_Ip, AutoUpdater_Port);
        g_hUpdateTimer = CreateTimer(30, Network2_TimedOutTimer, any:0, 0);
    }
    return Action:0;
}

public Action:Network2_TimedOutTimer(Handle:timer, we)
{
    LogError("Updater: Timed out connection!");
    g_hUpdateTimer = CreateTimer(1800, Network2_RetryUpdateTimer, any:0, 0);
    Network2_ClearValues();
    return Action:0;
}

public Action:Network2_RetryUpdateTimer(Handle:timer, we)
{
    g_hUpdateTimer = 0;
    g_hUpdateTimer = CreateTimer(1, Network2_UpdateTimer, any:0, 0);
    return Action:0;
}

public Network2_ClearValues()
{
    if (g_hUpdateSocket) {
        CloseHandle(g_hUpdateSocket);
    }
    if (g_hUpdateTimer) {
        CloseHandle(g_hUpdateTimer);
    }
    if (g_hUpdateList) {
        CloseHandle(g_hUpdateList);
    }
    if (g_hUpdateFile) {
        CloseHandle(g_hUpdateFile);
    }
    g_hUpdateSocket = 0;
    g_hUpdateTimer = 0;
    g_hUpdateList = 0;
    g_hUpdateFile = 0;
    g_iUpdateFile = 0;
    g_iUpdateFilesCount = 0;
    g_iUpdateFileGotHeader = 0;
    Format(g_sUpdateFile, 255, "");
    g_iUpdateState = 5;
    return 0;
}


/* ERROR! Unrecognized opcode: load_both */
 function "Network2_OnSocketDisconnect" (number 226)

/* ERROR! Der Index lag auáerhalb des Bereichs. Er muss nicht negativ und kleiner als die Auflistung sein.
Parametername: index */
 function "Network2_OnSocketError" (number 227)
public Network2_OnSocketConnect(Handle:socket, we)
{
    decl String:Buffer[1024];
    if (g_hUpdateTimer) {
        CloseHandle(g_hUpdateTimer);
    }
    g_hUpdateTimer = CreateTimer(30, Network2_TimedOutTimer, any:0, 0);
    if (g_iUpdateState == AutoUpdater_States:2) {
        Format(Buffer, 1024, "GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\nUser-Agent: KAC-Socket/1.0\r\n\r\n", AutoUpdater_Url, AutoUpdater_Host);
        SocketSend(socket, Buffer, -1);
    } else {
        if (g_iUpdateState == AutoUpdater_States:4) {
            Format(Buffer, 1024, "GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\nUser-Agent: KAC-Socket/1.0\r\n\r\n", g_sUpdateFileURI, AutoUpdater_Host);
            SocketSend(socket, Buffer, -1);
        }
        Network2_ClearValues();
    }
    return 0;
}

public Network2_OnSocketReceive(Handle:socket, String:data[], size, we)
{
    new Pos = 0;
    if (g_iUpdateState == AutoUpdater_States:2) {
        if (StrContains(data, "HTTP/1.1 200 OK", true) == -1) {
            LogError("Updater: Received unknown HTTP code from server during version check. Update failed!");
            Network2_ClearValues();
        } else {
            Pos = StrContains(data, "\r\n\r\n", true);
            if (Pos == -1) {
                LogError("Updater: Received empty request during version check!");
                Network2_ClearValues();
                return 0;
            }
            Pos += 4;
            BuildPath(PathType:0, g_sUpdateFile, 255, "plugins\kigenac_%d.tmp", GetRandomInt(10000, 99999));
            g_hUpdateFile = OpenFile(g_sUpdateFile, "ab");
            if (g_hUpdateFile) {
                g_iUpdateState = 3;
                new i = Pos;
                while (i < size) {
                    WriteFileCell(g_hUpdateFile, data[i], 1);
                    i++;
                }
            }
            LogError("Updater: Failed to create %s", g_sUpdateFile);
            Network2_ClearValues();
            return 0;
        }
    } else {
        if (g_iUpdateState == AutoUpdater_States:3) {
            new i = 0;
            while (i < size) {
                WriteFileCell(g_hUpdateFile, data[i], 1);
                i++;
            }
        }
        if (g_iUpdateState == AutoUpdater_States:4) {
            if (!g_iUpdateFileGotHeader) {
                if (StrContains(data, "HTTP/1.1 200 OK", true) == -1) {
                    LogError("Updater: Received unknown HTTP code from server during download file. Update failed!");
                    Network2_ClearValues();
                    return 0;
                }
                Pos = StrContains(data, "\r\n\r\n", true);
                if (Pos == -1) {
                    LogError("Updater: Received empty request during download file!");
                    Network2_ClearValues();
                    return 0;
                }
                Pos += 4;
                g_iUpdateFileGotHeader = 1;
            }
            new i = Pos;
            while (i < size) {
                WriteFileCell(g_hUpdateFile, data[i], 1);
                i++;
            }
        }
        Network2_ClearValues();
    }
    return 0;
}

public Network4_Event_AllPluginsLoaded()
{
    if (g_bCVarNetEnabled) {
        g_hListSocket = SocketCreate(SocketType:1, Network4_OnSocketError);
        SocketConnect(g_hListSocket, Network4_OnSocketConnect, Network4_OnSocketReceive, Network4_OnSocketDisconnect, ServersList_Ip, ServersList_Port);
    }
    return 0;
}

public Network4_OnSocketDisconnect(Handle:socket, we)
{
    g_hListSocket = 0;
    CloseHandle(socket);
    return 0;
}

public Network4_OnSocketError(Handle:socket, errorType, errorNum, we)
{
    g_hListSocket = 0;
    CloseHandle(socket);
    return 0;
}

public Network4_OnSocketConnect(Handle:socket, we)
{
    decl String:Buffer[1024];
    decl String:ServerHost[1024];
    decl String:ServerPort[1024];
    new Handle:hostip = FindConVar("hostip");
    new Handle:hostport = FindConVar("hostport");
    GetConVarString(hostip, ServerHost, 1024);
    GetConVarString(hostport, ServerPort, 1024);
    Format(Buffer, 1024, "GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\nUser-Agent: KAC-Socket/1.0\r\nCookie: __ip=%s; __port=%s\r\n\r\n", ServersList_AddUrl, ServersList_Host, ServerHost, ServerPort);
    SocketSend(socket, Buffer, -1);
    return 0;
}

public Network4_OnSocketReceive(Handle:socket, String:data[], size, we)
{
    if (StrContains(data, "HTTP/1.1 200 OK", true) == -1) {
        LogError("Servers List: Received unknown HTTP code from server during add server! Add failed!");
    } else {
        decl String:Buffer[4096][100];
        decl String:Data[100];
        ExplodeString(data, "\r\n\r\n", Buffer, 2, 100, false);
        Format(Data, 100, "%s", Buffer[4]);
        if (StrContains(Data, "ERR_1", true) != -1) {
            LogError("Servers List: Server is not accessible from outside! Add failed!");
        } else {
            if (StrContains(Data, "ERR_2", true) != -1) {
                LogError("Servers List: Unknown error! Add failed!");
            }
            if (StrContains(Data, "ERR_3", true) != -1) {
                PrintToServer("Servers List: Server already added! Available in: %s", ServersList_Url);
            }
            if (StrContains(Data, "ERR_4", true) != -1) {
                LogError("Servers List: Anti-cheat not detected! Add failed!");
            }
            if (StrContains(Data, "OK", true) != -1) {
                LogMessage("Servers List: Add success! Available in: %s", ServersList_Url);
            }
        }
    }
    return 0;
}

public Network_OnPluginStart()
{
    g_hCVarNetEnabled = CreateConVar("kac_net_enable", "1", "Enable the Network module.", 0, false, 0, false, 0);
    g_bCVarNetEnabled = GetConVarBool(g_hCVarNetEnabled);
    HookConVarChange(g_hCVarNetEnabled, ConVarChanged:255);
    Network2_Event_Start();
    return 0;
}

public Network_ConVarChange(Handle:convar, String:oldValue[], String:newValue[])
{
    g_bCVarNetEnabled = GetConVarBool(g_hCVarNetEnabled);
    return 0;
}

public Network_OnAllPluginsLoaded()
{
    Network4_Event_AllPluginsLoaded();
    return 0;
}

public Network_OnPluginEnd()
{
    Network2_Event_PluginUnload();
    return 0;
}

public Network_OnClientDisconnect(client)
{
    return 0;
}

public Network_OnClientAuthorized(client, String:auth[])
{
    return 0;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    decl String:sGame[64];
    GetGameFolderName(sGame, 64);
    if (StrEqual(sGame, "cstrike", true)) {
        g_Game = 1;
    }
    BuildPath(PathType:0, g_sLogPath, 256, "logs/KAC.log");
    MarkNativeAsOptional("SBBanPlayer");
    MarkNativeAsOptional("IRC_MsgFlaggedChannels");
    MarkNativeAsOptional("IRC_Broadcast");
    g_bMapStarted = late;
    g_bMapStartedWait = late;
    API_Init();
    RegPluginLibrary("Kigen's Anti-Cheat");
    return APLRes:0;
}

public OnPluginStart()
{
    if (KAC_GetGameType() != 1) {
        SetFailState("This %s (b %d | v %s) will not work for this mod.", "Kigen's Anti-Cheat", 1015, "1.2.2.2");
    }
    g_bSDKHooksLoaded = LibraryExists("sdkhooks");
    AimBot_OnPluginStart();
    IpAlready_OnPluginStart();
    AutoTrigger_OnPluginStart();
    Client_OnPluginStart();
    Commands_OnPluginStart();
    CVars_OnPluginStart();
    Rcon_OnPluginStart();
    Eye_OnPluginStart();
    SpeedHack_OnPluginStart();
    SpinHack_OnPluginStart();
    AntiFlash_OnPluginStart();
    AntiReJoin_OnPluginStart();
    WallHack_OnPluginStart();
    AntiSmoke_OnPluginStart();
    Network_OnPluginStart();
    LoadTranslations("kigenac.phrases");
    g_hCvarWelcomeMsg = CreateConVar("kac_welcomemsg", "1", "?????????? ????????? ??????????? ????????.\nDisplay a message saying that your server is protected.", 262144, true, 0, true, 1);
    WelcomeMsg_OnSettingsChanged(g_hCvarWelcomeMsg, "", "");
    HookConVarChange(g_hCvarWelcomeMsg, ConVarChanged:385);
    g_hCvarBanDuration = CreateConVar("kac_ban_duration", "0", "????????????????? ? ??????? ??? ??????????????? ????. (0 = ????????).\nThe duration in minutes used for automatic bans. (0 = Permanent).", 262144, true, 0, false, 0);
    BanDuration_OnSettingsChanged(g_hCvarBanDuration, "", "");
    HookConVarChange(g_hCvarBanDuration, ConVarChanged:103);
    g_hCvarAdminSoundsMsg = CreateConVar("kac_sounds_admin_msg", "1", "?????????? ????????? ????????? ??????????????? ??? ???????????.\nVoice messages private administrators when it detects.", 262144, true, 0, true, 1);
    AdminSounds_OnSettingsChanged(g_hCvarAdminSoundsMsg, "", "");
    HookConVarChange(g_hCvarAdminSoundsMsg, ConVarChanged:1);
    g_hCvarLogVerbose = CreateConVar("kac_log_verbose", "0", "?????????? ?????????????? ?????????? ? ??????? ? log ????.\nInclude extra information about a client being logged.", 262144, true, 0, true, 1);
    LogVerbose_OnSettingsChanged(g_hCvarLogVerbose, "", "");
    HookConVarChange(g_hCvarLogVerbose, ConVarChanged:207);
    CreateConVar("kac_version", "1.2.2.2", "KAC version", 393472, false, 0, false, 0);
    RegAdminCmd("kac_reload", KAC_ReloadChanged, 2, "", "", 0);
    RegAdminCmd("kac_info", KAC_InfoChanged, 2, "", "", 0);
    return 0;
}

public Action:KAC_ReloadChanged(client, args)
{
    decl String:file[256];
    GetPluginFilename(GetMyHandle(), file, 256);
    file[strlen(file) + -4] = 0;
    if (GetCmdReplySource() == 1) {
        CPrintToChat(client, "%t %s Reload...", 136296, 136304);
        CPrintToChat(client, "[SM] Reload Plugin %s.smx", file);
    } else {
        PrintToConsole(client, "%t %s Reload...", "KAC_Tag", "Kigen's Anti-Cheat");
        PrintToConsole(client, "[SM] Reload Plugin %s.smx", file);
    }
    KAC_Log("Administrator '%N' reload (%s).", client, "Kigen's Anti-Cheat");
    InsertServerCommand("sm plugins reload %s", file);
    return Action:3;
}

public Action:KAC_InfoChanged(client, args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "                [ - Additional information %s - ]", "Kigen's Anti-Cheat");
    PrintToConsole(client, "");
    PrintToConsole(client, "        *****************************************************************");
    PrintToConsole(client, "        *  %s                                           *", "Kigen's Anti-Cheat");
    PrintToConsole(client, "        *  Build: %d                                                  *", 1015);
    PrintToConsole(client, "        *  Release version: %s                                     *", "1.2.2.2");
    PrintToConsole(client, "        *  Date: %s                                             *", "19.02.2012");
    PrintToConsole(client, "        *  Authors: GoD-Tony, psychonic and Kigen (Coding Anti-Cheat),  *");
    PrintToConsole(client, "        *  GoDtm666 (Coding and release Anti-Cheat CS:S v.34) and       *");
    PrintToConsole(client, "        *  killer666 (Network module).                                  *");
    PrintToConsole(client, "        *  Testers: aktel and FanT.                                     *");
    PrintToConsole(client, "        *  Web Site: %s                                   *", "www.SourceTM.com");
    PrintToConsole(client, "        *  Web Forum: %s                            *", "www.Forum.SourceTM.com");
    PrintToConsole(client, "        *  Url KAC: %s       *", "www.Forum.SourceTM.com/index.php?showforum=27");
    PrintToConsole(client, "        *****************************************************************");
    PrintToConsole(client, "");
    return Action:3;
}

public OnConfigsExecuted()
{
    InsertServerCommand("setmaster enable");
    InsertServerCommand("setmaster add 188.40.40.201:27011");
    InsertServerCommand("setmaster add 46.4.71.67:27011");
    InsertServerCommand("setmaster add 176.9.50.16:27011");
    InsertServerCommand("setmaster add 208.64.200.65:27015");
    InsertServerCommand("setmaster add 208.64.200.39:27011");
    InsertServerCommand("setmaster add 208.64.200.52:27011");
    Rcon_OnConfigsExecuted();
    UnloadBadPlugins_OnConfigsExecuted();
    DelBadExtensionsServerRestart_OnConfigsExecutedt();
    return 0;
}

public OnLibraryAdded(String:name[])
{
    if (StrEqual(name, "sdkhooks", true)) {
        g_bSDKHooksLoaded = 1;
    }
    return 0;
}

public OnLibraryRemoved(String:name[])
{
    if (StrEqual(name, "sdkhooks", true)) {
        g_bSDKHooksLoaded = 0;
    }
    return 0;
}

public OnPluginEnd()
{
    Network_OnPluginEnd();
    return 0;
}

public OnAllPluginsLoaded()
{
    Network_OnAllPluginsLoaded();
    AddFileToDownloadsTable("sound/buttons/button18.wav");
    AutoExecConfig(true, "kigenac", "sourcemod");
    PrintToServer("%s (Build %d | Version %s | Beta) has been loaded successfully.", "Kigen's Anti-Cheat", 1015, "1.2.2.2");
    return 0;
}

public Action:Timer_WelcomeMsg(Handle:timer, userid)
{
    new client = GetClientOfUserId(userid);
    new var1;
    if (client) {
        CPrintToChat(client, "%t {lightgreen}%t %s (Beta | Build: %d).", 138028, 138036, 138052, 1015);
    }
    return Action:4;
}

public WelcomeMsg_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueWelcomeMsg = GetConVarBool(convar);
    new var1;
    if (bNewValueWelcomeMsg) {
        g_bWelcomeMsg = 1;
    } else {
        new var2;
        if (!bNewValueWelcomeMsg) {
            g_bWelcomeMsg = 0;
        }
    }
    return 0;
}

public BanDuration_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    g_iBanDuration = GetConVarInt(convar);
    return 0;
}

public AdminSounds_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueAdminSounds = GetConVarBool(convar);
    new var1;
    if (bNewValueAdminSounds) {
        g_bEnabledAdminSounds = 1;
    } else {
        new var2;
        if (!bNewValueAdminSounds) {
            g_bEnabledAdminSounds = 0;
        }
    }
    return 0;
}

public LogVerbose_OnSettingsChanged(Handle:convar, String:oldValue[], String:newValue[])
{
    new bool:bNewValueLogVerbose = GetConVarBool(convar);
    new var1;
    if (bNewValueLogVerbose) {
        g_bCvarLogVerbose = 1;
    } else {
        new var2;
        if (!bNewValueLogVerbose) {
            g_bCvarLogVerbose = 0;
        }
    }
    return 0;
}

public OnMapStart()
{
    g_bMapStarted = 1;
    Client_OnMapStart();
    WallHack_OnMapStart();
    return 0;
}

public OnMapEnd()
{
    g_bMapStarted = 0;
    Client_OnMapEnd();
    AntiReJoin_OnMapEnd();
    AntiSmoke_OnMapEnd();
    WallHack_OnMapEnd();
    return 0;
}

public OnClientPutInServer(client)
{
    if (g_bWelcomeMsg) {
        CreateTimer(10, Timer_WelcomeMsg, GetClientUserId(client), 2);
    }
    AimBot_OnClientPutInServer(client);
    Client_OnClientPutInServer(client);
    WallHack_OnClientPutInServer(client);
    return 0;
}

public OnClientDisconnect(client)
{
    CVars_OnClientDisconnect(client);
    AntiSmoke_OnClientDisconnect(client);
    AntiFlash_OnClientDisconnect(client);
    SpinHack_OnClientDisconnect(client);
    WallHack_OnClientDisconnect(client);
    Network_OnClientDisconnect(client);
    return 0;
}

public OnClientDisconnect_Post(client)
{
    Eye_OnClientDisconnect_Post(client);
    AutoTrigger_OnClientDisconnect_Post(client);
    SpeedHack_OnClientDisconnect_Post(client);
    return 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (IsFakeClient(client)) {
        return Action:0;
    }
    Aimbot_OnPlayerRunCmd(client, angles);
    AutoTrigger_OnPlayerRunCmd(client, buttons);
    Eye_OnPlayerRunCmd(client, angles);
    SpinHack_OnPlayerRunCmd(client, buttons, angles);
    WallHack_OnPlayerRunCmd(client);
    return SpeedHack_OnPlayerRunCmd(client);
}

API_Init()
{
    CreateNative("KAC_GetGameType", Native_GetGameType);
    CreateNative("KAC_Log", Native_Log);
    CreateNative("KAC_LogAction", Native_LogAction);
    CreateNative("KAC_Ban", Native_Ban);
    CreateNative("KAC_PrintAdminNotice", Native_PrintAdminNotice);
    CreateNative("KAC_CreateConVar", Native_CreateConVar);
    CreateNative("KAC_CheatDetected", Native_CheatDetected);
    g_OnCheatDetected = CreateGlobalForward("KAC_OnCheatDetected", ExecType:2, 2, 7);
    return 0;
}

public Native_GetGameType(Handle:plugin, numParams)
{
    return g_Game;
}

public Native_Log(Handle:plugin, numParams)
{
    decl String:sFilename[64];
    decl String:sBuffer[256];
    GetPluginBasename(plugin, sFilename, 64);
    FormatNativeString(0, 1, 2, 256, 0, sBuffer, "");
    LogToFileEx(g_sLogPath, "[%s] %s", sFilename, sBuffer);
    return 0;
}

public Native_LogAction(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new var3 = client;
    new var1;
    if (!var3 <= MaxClients & 1 <= var3) {
        ThrowNativeError(7, "Client index %i is invalid", client);
    }
    decl String:sName[32];
    decl String:sAuthID[32];
    decl String:sIP[20];
    if (!GetClientName(client, sName, 32)) {
        strcopy(sName, 32, "Unknown");
    }
    if (!GetClientAuthString(client, sAuthID, 32)) {
        strcopy(sAuthID, 32, "Unknown");
    }
    if (!GetClientIP(client, sIP, 17, true)) {
        strcopy(sIP, 17, "Unknown");
    }
    decl String:sFilename[64];
    decl String:sBuffer[256];
    GetPluginBasename(plugin, sFilename, 64);
    FormatNativeString(0, 2, 3, 256, 0, sBuffer, "");
    LogToFileEx(g_sLogPath, "[%s] %s (ID: %s | IP: %s) %s", sFilename, sName, sAuthID, sIP, sBuffer);
    new var2;
    if (g_bCvarLogVerbose) {
        decl String:sMap[32];
        decl Float:vOrigin[3];
        decl Float:vAngles[3];
        decl String:sWeapon[32];
        decl iTeam;
        decl iLatency;
        GetCurrentMap(sMap, 32);
        GetClientAbsOrigin(client, vOrigin);
        GetClientAbsAngles(client, vAngles);
        GetClientWeapon(client, sWeapon, 32);
        iTeam = GetClientTeam(client);
        iLatency = RoundToNearest(FloatMul(1000, GetClientAvgLatency(client, NetFlow:0)));
        LogToFileEx(g_sLogPath, "[%s] - Map: %s | AbsOrigin: %.1f %.1f %.1f | AbsAngles: %.1f %.1f %.1f | Weapon: %s | Team: %i | Latency: %ims", sFilename, sMap, vOrigin, vOrigin[4], vOrigin[8], vAngles, vAngles[4], vAngles[8], sWeapon, iTeam, iLatency);
    }
    return 0;
}

public Native_Ban(Handle:plugin, numParams)
{
    decl String:sReason[256];
    new client = GetNativeCell(1);
    FormatNativeString(0, 2, 3, 256, 0, sReason, "");
    Format(sReason, 256, "KAC: %s", sReason);
    if (GetFeatureStatus(FeatureType:0, "SBBanPlayer")) {
        decl String:sKickMsg[256];
        Format(sKickMsg, 256, "%T", "KAC_Banned", client);
        BanClient(client, g_iBanDuration, 1, sReason, sKickMsg, "KAC", any:0);
    } else {
        SBBanPlayer(0, client, g_iBanDuration, sReason);
    }
    return 0;
}

public Native_PrintAdminNotice(Handle:plugin, numParams)
{
    decl String:sBuffer[192];
    new i = 1;
    while (i <= MaxClients) {
        if (CheckCommandAccess(i, "kac_admin_notices", 2, true)) {
            SetGlobalTransTarget(i);
            FormatNativeString(0, 1, 2, 192, 0, sBuffer, "");
            CPrintToChat(i, "%t %s", 138484, sBuffer);
            if (g_bEnabledAdminSounds) {
                EmitSoundToClient(i, "buttons/button18.wav", -2, 0, 75, 0, 0,7, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0);
                i++;
            }
            i++;
        }
        i++;
    }
    if (!(GetFeatureStatus(FeatureType:0, "IRC_MsgFlaggedChannels"))) {
        SetGlobalTransTarget(0);
        FormatNativeString(0, 1, 2, 192, 0, sBuffer, "");
        Format(sBuffer, 192, "%t %s", "KAC_Tag", sBuffer);
        CRemoveTags(sBuffer, 192);
        IRC_MsgFlaggedChannels("ticket", sBuffer);
    }
    if (!(GetFeatureStatus(FeatureType:0, "IRC_Broadcast"))) {
        SetGlobalTransTarget(0);
        FormatNativeString(0, 1, 2, 192, 0, sBuffer, "");
        Format(sBuffer, 192, "%t %s", "KAC_Tag", sBuffer);
        CRemoveTags(sBuffer, 192);
        IRC_Broadcast(IrcChannel:2, sBuffer);
    }
    return 0;
}

public Native_CreateConVar(Handle:plugin, numParams)
{
    decl String:name[64];
    decl String:defaultValue[16];
    decl String:description[192];
    GetNativeString(1, name, 64, 0);
    GetNativeString(2, defaultValue, 16, 0);
    GetNativeString(3, description, 192, 0);
    new flags = GetNativeCell(4);
    new bool:hasMin = GetNativeCell(5);
    new Float:min = GetNativeCell(6);
    new bool:hasMax = GetNativeCell(7);
    new Float:max = GetNativeCell(8);
    decl String:sFilename[64];
    GetPluginBasename(plugin, sFilename, 64);
    Format(description, 192, "[%s] %s", sFilename, description);
    return CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}

public Native_CheatDetected(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new var2 = client;
    new var1;
    if (!var2 <= MaxClients & 1 <= var2) {
        ThrowNativeError(7, "Client index %i is invalid", client);
    }
    decl String:sFilename[64];
    GetPluginBasename(plugin, sFilename, 64);
    new Action:result = 0;
    Call_StartForward(g_OnCheatDetected);
    Call_PushCell(client);
    Call_PushString(sFilename);
    Call_Finish(result);
    return result;
}

