#include <sourcemod>
#include <sdktools>
#include <string>
#include <sdkhooks>

#define VERSION "1.001"

#define MAXSPAWNPOINT       512
#define MAXALIASES          128
#define MAXSCRIPTS          64
#define MAXINPUT            128
#define MAXCMDLEN           1024
#define MAXCMDBUF           6656 // Playing it safe and keeping this lower. In testing, I was able to get at least 7611 before overflowing.

#define CLEAN_PLUG_END      1
#define CLEAN_MAP_START     2
#define CLEAN_ROUND_START   4
#define CLEAN_AUTO_LOAD     8
#define CLEAN_MAN_LOAD      16
#define CLEAN_KILL          4
#define CLEAN_RESET         3

#define LOAD_PLUG_START     1
#define LOAD_MAP_START      2
#define LOAD_ROUND_START    4
#define LOAD_ROUND_START_B  8

#define SAVE_PLUG_END       1
#define SAVE_MAP_START      2
#define SAVE_ROUND_START    4
#define SAVE_CLEANUP        8
#define SAVE_EDIT           16
#define SAVE_REMOVE         32
#define SAVE_BACKUP         64

#define HOOK_NOHOOK         0
#define HOOK_DEACTIVE       1
#define HOOK_TOUCH          2
#define HOOK_HURT           4
#define HOOK_STATIC         8
#define HOOK_CONSTANT       16
#define HOOK_KILL           32

#define FULLSPECTRUM        -1

#define ILLEGAL_NAME        "@, "

/* * * * * * * * * * * * * * * *\
\*                             */
/*          CHANGELOG          *\
\*                             */
/*           v1.001            *\
\*                             */
/*       Fixed bug with        *\
\* sm_mrw_cfg_load causing the */
/*  server command buffer to   *\
\*          overflow.          */
/*                             *\
\* * * * * * * * * * * * * * * */

public Plugin:myinfo =
{
    name = "Map Rewards",
    author = "NIGathan",
    description = "Setup custom rewards or pickups around the map. Or gmod, whatever.. I don't even know anymore.",
    version = VERSION,
    url = "http://sandvich.justca.me/"
};

// Returns the index in source where search is found or -1 if not found.
// If pos is set, characters in source before pos will be ignored.
stock StrFind(const String:source[], const String:search[], pos = 0)
{
    new srcLen = strlen(source);
    new schLen = strlen(search);
    if (pos >= srcLen)
        return -1;
    new i, j;
    new bool:match = false;
    for (i = pos;((i < srcLen) && (!match));i++)
    {
        for (j = 0;j < schLen;j++)
            if (source[i+j] != search[j])
                break;
        if (j == schLen)
        {
            match = true;
            break;
        }
    }
    if (match)
        return i;
    return -1;
}

// Searches source for the first occurance of any character within search.
// If pos is set, characters in source before pos will be ignored.
// Returns the index in source of the first match or -1 if none were found.
stock StrFindFirstOf(const String:source[], const String:search[], pos = 0)
{
    new srcLen = strlen(source);
    new schLen = strlen(search);
    for (;pos < srcLen;pos++)
        for (new i = 0;i < schLen;i++)
            if (source[pos] == search[i])
                return pos;
    return -1;
}

// Removes every occurance of any character from search found in source
//  starting at pos.
// Returns the number of characters removed.
stock StrRemoveAllOf(String:source[], const String:search[], pos = 0)
{
    new removals = 0;
    new srcLen = strlen(source);
    new schLen = strlen(search);
    decl h, i, start, end;
    for (;pos < srcLen;pos++)
    {
        for (h = 0;h < schLen;h++)
        {
            if (source[pos] == search[h])
            {
                for (start = pos+1, end = srcLen-start, i = 0;i < end;i++)
                    source[pos+i] = source[start+i];
                srcLen--;
                removals++;
            }
        }
    }
    if (removals)
        source[srcLen] = '\0';
    return removals;
}

// Erases len characters from str starting at pos.
// If len is -1 all characters starting at pos are erased.
// Returns the number of characters erased.
// Doesn't actually erase any characters, simply shifts the remaining down
//   and inserts the null terminator.
stock StrErase(String:str[], pos, len = -1)
{
    new strLen = strlen(str);
    if ((len == 0) || (pos > strLen)) // Nothing to erase.
        return 0;
    if ((len < 0) || ((strLen-pos) < len))
    {
        str[pos] = '\0';
        return strLen-pos;
    }
    for (new start = pos+len, end = strLen-start, i = 0;i < end;i++)
        str[pos+i] = str[start+i];
    str[strLen-len] = '\0';
    return len;
}

// Test if a string is (or begins with) a digit.
// Returns the position in str at the last character in the sequence of
//   leading digits or -1 if str does not begin with a digit.
//  StrIsDigit("42\0") will return 1
//  StrIsDigit("-5foo\0") will return 1
//  StrIsDigit("null5\0") will return -1
//  StrIsDigit("-null5\0") will return -1
//  StrIsDigit("1\0") will return 0
// Undefined behaviour if the string is not null terminated.
stock StrIsDigit(const String:str[])
{
    new strLen = strlen(str);
    if (strLen == 0)
        return -1;
    new pos = 0;
    new bool:neg = false;
    if (str[0] == '-')
    {
        pos++;
        neg = true;
    }
    new num;
    for (;pos < strLen;pos++)
    {
        num = str[pos]-48;
        if ((num < 0) || (num > 9))
        {
            pos--;
            break;
        }
    }
    if ((neg) && ((pos == 0) || (strLen < 2)))
        return -1;
    else
        return pos;
}

// Swaps the contents of str0 and str1
// If one string is larger than the other, then UB may occur.
stock StrSwap(String:str0[], String:str1[])
{
    decl String:temp[1];
    decl size[2];
    size[0] = strlen(str0)+1;
    size[1] = strlen(str1)+1;
    if (size[1] > size[0])
        size[0] = size[1];
    for (new i = 0;i <= size[0];i++)
    {
        temp[0] = str0[i];
        str0[i] = str1[i];
        str1[i] = temp[0];
    }
}

stock SayText2(author_index , const String:message[] ) 
{
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE)
    {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

stock SayText2One( client_index , author_index , const String:message[] ) 
{
    new Handle:buffer = StartMessageOne("SayText2", client_index);
    if (buffer != INVALID_HANDLE)
    {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

stock RespondToCommand(client, const String:msg[], any:...)
{
    decl String:fmsg[250];
    VFormat(fmsg,250,msg,3);
    if (client != 0)
        ReplyToCommand(client,fmsg);
    else
        PrintToServer(fmsg);
}

stock CRespondToCommand(client, const String:msg[], any:...)
{
    decl String:fmsg[250];
    VFormat(fmsg,250,msg,3);
    if (client != 0)
    {
        Format(fmsg,250,"%s",fmsg);
        SayText2One(client,client,fmsg);
    }
    else
    {
        StrRemoveAllOf(fmsg,"");
        PrintToServer(fmsg);
    }
}

stock CPrintToServer(const String:msg[], any:...)
{
    decl String:fmsg[MAXCMDLEN];
    VFormat(fmsg,MAXCMDLEN,msg,2);
    StrRemoveAllOf(fmsg,"");
    PrintToServer(fmsg);
}

stock orFlag(&flags, flag)
{
    if (64 < flag < 91) // if uppercase
        flag += 32;     //    convert to lowercase
    switch (flag)
    {
        case 'a':   flags |= ADMFLAG_RESERVATION;
		case 'b':   flags |= ADMFLAG_GENERIC;
		case 'c':   flags |= ADMFLAG_KICK;
		case 'd':   flags |= ADMFLAG_BAN;
		case 'e':   flags |= ADMFLAG_UNBAN;
		case 'f':   flags |= ADMFLAG_SLAY;
		case 'g':   flags |= ADMFLAG_CHANGEMAP;
		case 'h':   flags |= ADMFLAG_CONVARS;
		case 'i':   flags |= ADMFLAG_CONFIG;
		case 'j':   flags |= ADMFLAG_CHAT;
		case 'k':   flags |= ADMFLAG_VOTE;
		case 'l':   flags |= ADMFLAG_PASSWORD;
		case 'm':   flags |= ADMFLAG_RCON;
		case 'n':   flags |= ADMFLAG_CHEATS;
		case 'o':   flags |= ADMFLAG_CUSTOM1;
		case 'p':   flags |= ADMFLAG_CUSTOM2;
		case 'q':   flags |= ADMFLAG_CUSTOM3;
		case 'r':   flags |= ADMFLAG_CUSTOM4;
		case 's':   flags |= ADMFLAG_CUSTOM5;
		case 't':   flags |= ADMFLAG_CUSTOM6;
		case 'z':   flags |= ADMFLAG_ROOT;
    } // any other characters are ignored
}

stock bool:handleClientAccess(client, any:flags)
{
    if (client > 0)
    {
        new flagBits = GetUserFlagBits(client);
        if (((flagBits & ADMFLAG_ROOT) == 0) && ((flagBits & flags) != flags))
        {
            ReplyToCommand(client,"[SM] You do not have access to this command.");
            return false;
        }
    }
    return true;
}

// Thanks to GottZ for this: https://sm.alliedmods.net/api/index.php?fastload=show&id=398&
stock GetRealClientCount(bool:inGameOnly = true)
{
    new clients = 0;
    for (new i = 1; i <= GetMaxClients(); i++)
    {
        if (((inGameOnly) ? IsClientInGame(i) : IsClientConnected(i)) && !IsFakeClient(i))
        {
            clients++;
        }
    }
    return clients;
}

// Borrowed from pumpkin.sp by linux_lover aka pheadxdll: https://forums.alliedmods.net/showthread.php?p=976177
// From pheadxdll: "Credits to Spaz & Arg for the positioning code. Taken from FuncommandsX."
// Slightly modified to remove globals.
stock bool:SetTeleportEndPoint(client, Float:pos[3])
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		pos[0] = vStart[0] + (vBuffer[0]*Distance);
		pos[1] = vStart[1] + (vBuffer[1]*Distance);
		pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

new Handle:c_enable = INVALID_HANDLE;
new Handle:c_respawnTime = INVALID_HANDLE;
new Handle:c_cleanUp = INVALID_HANDLE;
new Handle:c_autoLoad = INVALID_HANDLE;
new Handle:c_autoSave = INVALID_HANDLE;
new Handle:c_basicFlag = INVALID_HANDLE;
new Handle:c_createFlag = INVALID_HANDLE;
new Handle:c_extendedFlag = INVALID_HANDLE;

new Float:defSpawnCoords[MAXSPAWNPOINT][3];
new Float:defSpawnAngles[MAXSPAWNPOINT][3];
new spawnEnts[MAXSPAWNPOINT] = { -1, ... };
new String:rCommand[MAXSPAWNPOINT][2][MAXCMDLEN];
new String:model[MAXSPAWNPOINT][MAXINPUT];
new String:aliases[MAXALIASES][5][MAXINPUT];
new String:scripts[MAXSCRIPTS][2][MAXINPUT];
new String:script[MAXSPAWNPOINT][2][MAXINPUT];
new String:entType[MAXSPAWNPOINT][64];
new Float:respawnTime[MAXSPAWNPOINT] = { -1.0, ... };
new respawnMethod[MAXSPAWNPOINT];// = { -1, ... };
new String:entName[MAXSPAWNPOINT][32];
new Float:entSpin[MAXSPAWNPOINT][3];
new Float:entSpinInt[MAXSPAWNPOINT];
new Float:entSpinAngles[MAXSPAWNPOINT][3];
new Handle:entTimers[MAXSPAWNPOINT] = { INVALID_HANDLE, ... };
new rewardKiller[MAXSPAWNPOINT];
new Float:entHealth[MAXSPAWNPOINT];
new Float:entDamage[MAXSPAWNPOINT];
new bool:unEvaluate[MAXSPAWNPOINT];
new entOverlay[MAXSPAWNPOINT] = { FULLSPECTRUM, ... };
new aliasCount = 0;
new scriptCount = 0;
new newestReward = -1;

new g_enable;
new Float:g_respawnTime;
new g_cleanUp;
new g_autoLoad;
new g_autoSave;
new g_basicFlag = ADMFLAG_CONFIG;
new g_createFlag = ADMFLAG_RCON;
new g_extendedFlag = ADMFLAG_RCON;

stock bool:isValidReward(id)
{
    if ((-1 < id < MAXSPAWNPOINT) && (strlen(entType[id]) > 0))
        return true;
    return false;
}

getNewestReward()
{
    if (!isValidReward(newestReward))
        for (newestReward = MAXSPAWNPOINT-1;newestReward > -1;newestReward--)
            if (isValidReward(newestReward))
                break;
    return newestReward;
}

resetAliases()
{
    for (new i = 0;i < MAXALIASES;i++)
    {
        strcopy(aliases[i][0],MAXINPUT,"");
        strcopy(aliases[i][1],MAXINPUT,"");
        strcopy(aliases[i][2],MAXINPUT,"");
        strcopy(aliases[i][3],MAXINPUT,"");
    }
    aliasCount = 0;
}

loadAliases()
{
    resetAliases();
    if (DirExists("cfg/maprewards") == false)
        CreateDirectory("cfg/maprewards",511);
    new i = 0;
    if (FileSize("cfg/maprewards/aliases.cfg") > 4)
    {
        new Handle:iFile = OpenFile("cfg/maprewards/aliases.cfg","r");
        decl String:buffer[1024];
        while (ReadFileLine(iFile,buffer,1024))
        {
            TrimString(buffer);
            if (strcmp(buffer,"") == 0)
                continue;
            if (ExplodeString(buffer,"@",aliases[i],5,MAXINPUT,true) > 1)
                i++;
            if (i >= MAXALIASES)
                break;
        }
        CloseHandle(iFile);
    }
    return i;
}

writeAliases()
{
    if (DirExists("cfg/maprewards") == false)
        CreateDirectory("cfg/maprewards",511);
    if (FileExists("cfg/maprewards/aliases.cfg"))
    {
        DeleteFile("cfg/maprewards/aliases.cfg.bak");
        RenameFile("cfg/maprewards/aliases.cfg.bak","cfg/maprewards/aliases.cfg");
    }
    new Handle:oFile = OpenFile("cfg/maprewards/aliases.cfg","w");
    for (new i = 0;i < aliasCount;i++)
        WriteFileLine(oFile,"%s@%s@%s@%s@%s",aliases[i][0],aliases[i][1],aliases[i][2],aliases[i][3],aliases[i][4]);
    CloseHandle(oFile);
    return FileExists("cfg/maprewards/aliases.cfg");
}

resetScripts()
{
    for (new i = 0;i < MAXSCRIPTS;i++)
    {
        strcopy(scripts[i][0],MAXINPUT,"");
        strcopy(scripts[i][1],MAXINPUT,"");
    }
    scriptCount = 0;
}

loadScripts()
{
    resetScripts();
    if (DirExists("cfg/maprewards") == false)
        CreateDirectory("cfg/maprewards",511);
    new i = 0;
    if (FileSize("cfg/maprewards/scripts.cfg") > 4)
    {
        new Handle:iFile = OpenFile("cfg/maprewards/scripts.cfg","r");
        decl String:buffer[MAXINPUT];
        while (ReadFileLine(iFile,buffer,MAXINPUT))
        {
            TrimString(buffer);
            if (strcmp(buffer,"") == 0)
                continue;
            if (ExplodeString(buffer," ",scripts[i],2,MAXINPUT,true) > 1)
                i++;
            if (i >= MAXALIASES)
                break;
        }
        CloseHandle(iFile);
    }
    return i;
}

writeScripts()
{
    if (DirExists("cfg/maprewards") == false)
        CreateDirectory("cfg/maprewards",511);
    if (FileExists("cfg/maprewards/scripts.cfg"))
    {
        DeleteFile("cfg/maprewards/scripts.cfg.bak");
        RenameFile("cfg/maprewards/scripts.cfg.bak","cfg/maprewards/scripts.cfg");
    }
    new Handle:oFile = OpenFile("cfg/maprewards/scripts.cfg","w");
    for (new i = 0;i < scriptCount;i++)
        WriteFileLine(oFile,"%s %s",scripts[i][0],scripts[i][1]);
    CloseHandle(oFile);
    return FileExists("cfg/maprewards/scripts.cfg");
}

stock buildRewardCmd(index, String:cmdC[], cmdSize, bool:relative = false, const Float:originC[3] = { 0.0, 0.0, 0.0 })
{
    decl Float:coordsC[3];
    coordsC = defSpawnCoords[index];
    if (relative)
    {
        for (new i = 0;i < 3;i++)
            coordsC[i] -= originC[i];
        Format(cmdC,cmdSize,"sm_mrw_add -c ~%f ~%f ~%f",coordsC[0],coordsC[1],coordsC[2]);
    }
    else
        Format(cmdC,cmdSize,"sm_mrw_add -c %f %f %f",coordsC[0],coordsC[1],coordsC[2]);
    if ((defSpawnAngles[index][0] != 0.0) || (defSpawnAngles[index][1] != 0.0) || (defSpawnAngles[index][2] != 0.0))
        Format(cmdC,cmdSize,"%s -r %f %f %f",cmdC,defSpawnAngles[index][0],defSpawnAngles[index][1],defSpawnAngles[index][2]);
    if (strcmp(entType[index],"prop_physics_override") != 0)
        Format(cmdC,cmdSize,"%s -e %s",cmdC,entType[index]);
    if (strlen(model[index]) > 0)
        Format(cmdC,cmdSize,"%s -m %s",cmdC,model[index]);
    if (((index > 0) && (StringToInt(entName[index]) != index)) || ((index == 0) && (strcmp(entName[index],"0") != 0)))
        Format(cmdC,cmdSize,"%s -n %s",cmdC,entName[index]);
    if (strlen(script[index][0]) > 0)
        Format(cmdC,cmdSize,"%s -s %s",cmdC,script[index][0]);
    if (strlen(script[index][1]) > 0)
        Format(cmdC,cmdSize,"%s -p %s",cmdC,script[index][1]);
    if (entSpinInt[index] > 0.0)
        Format(cmdC,cmdSize,"%s -T %.2f %.2f %.2f %.1f",cmdC,entSpin[index][0],entSpin[index][1],entSpin[index][2],entSpinInt[index]);
    if (unEvaluate[index])
        Format(cmdC,cmdSize,"%s -U",cmdC);
    if (entOverlay[index] != FULLSPECTRUM)
        Format(cmdC,cmdSize,"%s -L %d",cmdC,entOverlay[index]);
    if (respawnMethod[index] != HOOK_NOHOOK)
    {
        Format(cmdC,cmdSize,"%s -d %i",cmdC,(respawnMethod[index] & ~HOOK_DEACTIVE));
        if (respawnTime[index] >= 0.0)
            Format(cmdC,cmdSize,"%s -t %.2f",cmdC,respawnTime[index]);
        if (entHealth[index] > 0.0)
            Format(cmdC,cmdSize,"%s -A %.2f",cmdC,entHealth[index]);
        if ((strlen(rCommand[index][0]) > 0) && (strcmp(rCommand[index][0],"null") != 0))
        {
            Format(cmdC,cmdSize,"%s \"%s\"",cmdC,rCommand[index][0]);
            if (strlen(rCommand[index][1]) > 0)
                Format(cmdC,cmdSize,"%s\nsm_mrw_modify -1 -X \"%s\"",cmdC,rCommand[index][1]);
        }
        else if (strlen(rCommand[index][1]) > 0)
            Format(cmdC,cmdSize,"%s -X \"%s\"",cmdC,rCommand[index][1]);
    }
}

killReward(index)
{
    new ent = spawnEnts[index];
    if (ent > -1)
    {
        spawnEnts[index] = -1;
        if (entTimers[index] != INVALID_HANDLE)
        {
            KillTimer(entTimers[index]);
            entTimers[index] = INVALID_HANDLE;
        }
        if (IsValidEntity(ent))
        {
            decl String:temp[32];
            GetEntPropString(ent, Prop_Data, "m_iName", temp, 32);
            if (strcmp(entName[index],temp) == 0)
                AcceptEntityInput(ent, "Kill");
            /*else
            {
                decl String:className[35];
                GetEdictClassname(ent,className,35);
                PrintToServer("[SM] Error: Reward #%d,%s (%d,%s) m_iName == %s, expected '%s'",index,entType[index],ent,className,temp,entName[index]);
            }*/
        }
    }
}

killRewards()
{
    for (new i = 0; i < MAXSPAWNPOINT; i++)
    {
        killReward(i);
    }
}

resetReward(index)
{
    spawnEnts[index] = -1;
    defSpawnCoords[index][0] = defSpawnCoords[index][1] = defSpawnCoords[index][2] = 0.0;
    defSpawnAngles[index][0] = defSpawnAngles[index][1] = defSpawnAngles[index][2] = 0.0;
    rCommand[index][0] = "";
    rCommand[index][1] = "";
    model[index] = "";
    script[index][0] = "";
    script[index][1] = "";
    entType[index] = "";
    respawnMethod[index] = HOOK_NOHOOK;
    respawnTime[index] = -1.0;
    entName[index] = "";
    entSpin[index][0] = entSpin[index][1] = entSpin[index][2] = entSpinInt[index] = 0.0;
    if (entTimers[index] != INVALID_HANDLE)
    {
        KillTimer(entTimers[index]);
        entTimers[index] = INVALID_HANDLE;
    }
    rewardKiller[index] = 0;
    entHealth[index] = 0.0;
    entDamage[index] = 0.0;
    unEvaluate[index] = false;
    entOverlay[index] = FULLSPECTRUM;
}

resetRewards()
{
    for (new i = 0;i < MAXSPAWNPOINT;i++)
        resetReward(i);
}

removeReward(index)
{
    killReward(index);
    resetReward(index);
}

removeRewards()
{
    for (new i = 0;i < MAXSPAWNPOINT;i++)
        removeReward(i);
}

stock bool:cleanUp(event, bool:didSave = false)
{
    if (g_cleanUp & event)
    {
        if (!didSave)
            autoSave(SAVE_CLEANUP);
        removeRewards();
        return true;
    }
    if (event & CLEAN_KILL)
        killRewards();
    if (event & CLEAN_RESET)
    {
        if (!didSave)
            autoSave(SAVE_CLEANUP);
        resetRewards();
        return true;
    }
    return false;
}

autoLoad(event, bool:didCleanUp)
{
    if (g_autoLoad & event)
    {
        if (!didCleanUp)
            cleanUp(CLEAN_AUTO_LOAD);
        if (g_autoLoad & (event & LOAD_PLUG_START|LOAD_ROUND_START_B))
        {
            if (FileExists("cfg/maprewards/server.cfg"))
                ServerCommand("exec maprewards/server");
        }
        if (g_autoLoad & (event & (LOAD_MAP_START|LOAD_ROUND_START)))
        {
            new String:mapName[32];
            new String:mapFile[47] = "maprewards/";
            new String:mapCheck[51] = "cfg/";
            GetCurrentMap(mapName,32);
            StrCat(mapFile,46,mapName);
            StrCat(mapCheck,51,mapFile);
            StrCat(mapCheck,51,".cfg");
            if (FileExists(mapCheck))
            {
                ServerCommand("exec %s",mapFile);
            }
        }
    }
}

getActiveCount()
{
    new r = 0;
    for (new i = 0;i < MAXSPAWNPOINT;i++)
        if (strlen(entType[i]) > 0)
            r++;
    return r;
}

stock bool:autoSave(event, bool:force = false)
{
    if (g_autoSave & event)
    { // we keep these two statements separate so we can return true if we were supposed to save, regardless if we actually did.
        if ((force) || (getActiveCount() > 0))
        {
            decl String:mapFile[MAXINPUT];
            decl String:backupFile[MAXINPUT];
            GetCurrentMap(mapFile,MAXINPUT);
            if (strlen(mapFile) > 0)
            {
                Format(backupFile,MAXINPUT,"cfg/maprewards/backup/%s.cfg.%d",mapFile,GetTime());
                Format(mapFile,MAXINPUT,"cfg/maprewards/%s.cfg",mapFile);
                if ((g_autoSave & SAVE_BACKUP) && (FileExists(mapFile)))
                {
                    if (DirExists("cfg/maprewards/backup") == false)
                        CreateDirectory("cfg/maprewards/backup",511);
                    RenameFile(backupFile,mapFile);
                    PrintToServer("[SM] Backed up old maprewards cfg file to '%s'.",backupFile);
                }
                new Handle:oFile = OpenFile(mapFile,"w");
                for (new i = 0;i < MAXSPAWNPOINT;i++)
                {
                    if (isValidReward(i))
                    {
                        decl String:cmdC[MAXCMDLEN];
                        buildRewardCmd(i,cmdC,MAXCMDLEN);
                        WriteFileLine(oFile,cmdC);
                    }
                }
                CloseHandle(oFile);
                PrintToServer("[SM] Saved maprewards cfg file to '%s'.",mapFile);
            }
        }
        return true;
    }
    return false;
}

spawnRewards()
{
    if (g_enable)
    {
        for (new i = 0; i < MAXSPAWNPOINT; i++)
        {
            spawnReward(i);
        }
    }
}

newEnt()
{
    new i;
    for (i = 0;i < MAXSPAWNPOINT;i++)
    {   // Find the first unused index entry.
        if (!strlen(entType[i]))
            break;
    }
    return i;
}

triggerReward(index, client, inflictor = -1)
{
    decl String:cmdD[MAXCMDLEN];
    strcopy(cmdD,MAXCMDLEN,rCommand[index][0]);
    if ((inflictor > -1) && (strlen(rCommand[index][1]) > 0))
        strcopy(cmdD,MAXCMDLEN,rCommand[index][1]);
    if ((strlen(cmdD) > 0) && (strcmp(cmdD,"null") != 0))
    {
        decl String:cmdC[MAXCMDLEN];
        decl String:target[8];
        Format(target,8,"#%i",GetClientUserId(client));
        strcopy(cmdC,MAXCMDLEN,cmdD);
        ReplaceString(cmdC,MAXCMDLEN,"#player",target);
        ReplaceString(cmdC,MAXCMDLEN,"#reward",entName[index]);
        if (inflictor > -1)
        {
            decl String:flict[8];
            IntToString(inflictor,flict,8);
            ReplaceString(cmdC,MAXCMDLEN,"#inflictor",flict);
        }
        ServerCommand(cmdC);
    }
}

stock evaluateRewardAliases(const &any:r, bool:skip[4] = { false, ... })
{
    for (new i = 0;((i < scriptCount) && ((!skip[2]) || (!skip[3])));i++)
    {
        if ((!skip[2]) && (strcmp(script[r][0],scripts[i][0]) == 0))
        {
            strcopy(script[r][0],MAXINPUT,scripts[i][1]);
            skip[2] = true;
        }
        if ((!skip[3]) && (strcmp(script[r][1],scripts[i][0]) == 0))
        {
            strcopy(script[r][1],MAXINPUT,scripts[i][1]);
            skip[3] = true;
        }
    }
    skip[0] = ((skip[0]) || (strcmp(model[r],"null") == 0) || (strcmp(model[r],"0") == 0));
    skip[1] = ((skip[1]) || (strcmp(entType[r],"null") == 0) || (strcmp(entType[r],"0") == 0));
    skip[2] = ((skip[2]) || (strlen(script[r][0])));
    skip[3] = ((skip[3]) || (strlen(script[r][1])));
    decl bool:isModel;
    decl String:tempModel[MAXINPUT];
    decl String:tempEntType[64];
    new bool:writeTemp[2];
    for (new i = 0;((i < aliasCount) && ((!skip[0]) || (!skip[1])));i++)
    {
        if (((isModel = ((!skip[0]) && (strcmp(model[r],aliases[i][0]) == 0)))) || ((!skip[1]) && (strcmp(entType[r],aliases[i][0]) == 0)))
        {
            if ((!skip[0]) && ((isModel) || (strlen(aliases[i][1]) > 0)))
            {
                strcopy(tempModel,MAXINPUT,aliases[i][1]);
                writeTemp[0] = true;
                if (isModel)
                    skip[0] = true;
            }
            if ((!skip[1]) && ((!isModel) || (strlen(aliases[i][2]) > 0)))
            {
                strcopy(tempEntType,64,aliases[i][2]);
                writeTemp[1] = true;
                if (!isModel)
                    skip[1] = true;
            }
            if ((!skip[2]) && (strlen(aliases[i][3]) > 0))
            {
                strcopy(script[r][0],MAXINPUT,aliases[i][3]);
                skip[2] = true;
            }
            if ((!skip[3]) && (strlen(aliases[i][4]) > 0))
            {
                strcopy(script[r][1],MAXINPUT,aliases[i][4]);
                skip[3] = true;
            }
        }
    }
    if (writeTemp[0])
        strcopy(model[r],MAXINPUT,tempModel);
    if (writeTemp[1])
        strcopy(entType[r],64,tempEntType);
}

spawnReward(index)
{
    if ((strlen(entType[index]) == 0) || (GetRealClientCount() < 1))
        return;
    
    entDamage[index] = 0.0;
    
    if (respawnMethod[index] & HOOK_DEACTIVE)
    {
        //respawnMethod[index] &= ~HOOK_DEACTIVE;
        if (IsValidEntity(spawnEnts[index]))
        {
            decl String:temp[32];
            GetEntPropString(spawnEnts[index], Prop_Data, "m_iName", temp, 32);
            if (strcmp(entName[index],temp) == 0)
            {
                respawnMethod[index] &= ~HOOK_DEACTIVE;
                if (respawnMethod[index] & HOOK_TOUCH)
                    SDKHook(spawnEnts[index], SDKHook_StartTouch, mapRewardPickUp);
                if (respawnMethod[index] & HOOK_HURT)
                    SDKHook(spawnEnts[index], SDKHook_OnTakeDamage, mapRewardTakeDamage);
                return;
            } // Don't return here incase the reward does not match so it can be made from scratch
        }
        else if (!(respawnMethod[index] & HOOK_STATIC))
        {
            if (respawnTime[index] < 0.0)
                CreateTimer(g_respawnTime, timerRespawnReward, index);
            else if (respawnTime[index] > 0.0)
                CreateTimer(respawnTime[index], timerRespawnReward, index);
            return;
        }
    }
    
    killReward(index);
    
    decl String:tempModel[MAXINPUT];
    decl String:tempEntType[64];
    decl String:tempScript[2][MAXINPUT];
    strcopy(tempModel,MAXINPUT,model[index]);
    strcopy(tempEntType,64,entType[index]);
    strcopy(tempScript[0],MAXINPUT,script[index][0]);
    strcopy(tempScript[1],MAXINPUT,script[index][1]);
    if (unEvaluate[index])
    {
        evaluateRewardAliases(index);
        StrSwap(tempModel,model[index]);
        StrSwap(tempEntType,entType[index]);
        StrSwap(tempScript[0],script[index][0]);
        StrSwap(tempScript[1],script[index][1]);
    }
    if (strcmp(tempModel,"null") == 0)
        strcopy(tempModel,MAXINPUT,"");
    if (strcmp(tempEntType,"null") == 0)
        strcopy(tempEntType,64,"");
    if (strcmp(tempScript[0],"null") == 0)
        strcopy(tempScript[0],MAXINPUT,"");
    if (strcmp(tempScript[1],"null") == 0)
        strcopy(tempScript[1],MAXINPUT,"");
    if (strlen(tempEntType) < 1)
        strcopy(tempEntType,64,"prop_physics_override");
    
    new entReward = CreateEntityByName(tempEntType);
    
    if (IsValidEntity(entReward))
    {
        SetEntPropString(entReward, Prop_Data, "m_iName", entName[index]);
        if (strlen(tempModel) > 0)
            DispatchKeyValue(entReward, "model", tempModel);
        new spawned = 0;
        if (strlen(tempScript[0]) > 0)
        {
            if (StrContains(tempScript[0],"?") != -1)
            {
                new String:strMain[2][MAXINPUT];
                new String:strCurrent[MAXINPUT];
                new String:strKeys[2][MAXINPUT];
                new String:strType[16];
                new String:strTemp[MAXINPUT];
                ExplodeString(tempScript[0],"?",strMain,2,MAXINPUT,true);
                Format(strMain[1],MAXINPUT,"%s&",strMain[1]);
                if (strcmp(strMain[0],"null") != 0)
                    DispatchKeyValue(entReward, "overridescript", strMain[0]);
                //PrintToServer("[SM] Debug0: %s | %s",strMain[0],strMain[1]);
                while (SplitString(strMain[1],"&",strCurrent,MAXINPUT) > -1)
                {
                    //PrintToServer("[SM] Debug1: %s",strCurrent);
                    if (StrContains(strCurrent,",") == -1)
                    {
                        if (!spawned)
                        {
                            DispatchSpawn(entReward);
                            spawned = 1;
                        }
                        AcceptEntityInput(entReward,strCurrent);
                    }
                    else
                    {
                        ExplodeString(strCurrent,",",strKeys,2,MAXINPUT,true);
                        //PrintToServer("[SM] Debug2: %s | %s",strKeys[0],strKeys[1]);
                        SplitString(strKeys[1],"=",strType,16);
                        Format(strType,16,"%s=",strType);
                        ReplaceStringEx(strKeys[1],MAXINPUT,strType,"",-1,0);
                        //PrintToServer("[SM] Debug3: %s | %s",strType,strKeys[1]);
                        if ((strcmp(strType,"float=") == 0) || (strcmp(strType,"int=") == 0))
                            DispatchKeyValueFloat(entReward,strKeys[0],StringToFloat(strKeys[1]));
                        else if (strcmp(strType,"string=") == 0)
                            DispatchKeyValue(entReward,strKeys[0],strKeys[1]);
                        else
                            DispatchKeyValue(entReward,strKeys[0],strKeys[1]);
                    }
                    Format(strTemp,MAXINPUT,"%s&",strCurrent);
                    ReplaceStringEx(strMain[1],MAXINPUT,strTemp,"",-1,0);
                    ReplaceStringEx(strMain[1],MAXINPUT,strCurrent,"",-1,0);
                    //PrintToServer("[SM] Debug4: %s",strMain[1]);
                }
            }
            else
                DispatchKeyValue(entReward, "overridescript", tempScript[0]);
        }
        if (strlen(tempScript[1]) > 0)
        {
            //[prop_type:]key,[type=]value&[prop_type:]key,[type=]value
            decl String:strMain[MAXINPUT];
            decl String:strCurrent[MAXINPUT];
            decl String:strKeys[2][MAXINPUT];
            decl String:strType[16];
            decl String:strTemp[MAXINPUT];
            strcopy(strMain,MAXINPUT,tempScript[1]);
            StrCat(strMain,MAXINPUT,"&");
            new PropType:propType;
            while (SplitString(strMain,"&",strCurrent,MAXINPUT) > -1)
            {
                if (StrContains(strCurrent,",") > -1)
                {
                    propType = Prop_Data;
                    if ((strlen(strCurrent) > 2) && (strCurrent[1] == ':'))
                    {
                        if (strCurrent[0] == '1')
                            propType = Prop_Send;
                        StrErase(strCurrent,0,2);
                    }
                    if (!spawned)
                    {
                        DispatchSpawn(entReward);
                        spawned = 1;
                    }
                    ExplodeString(strCurrent,",",strKeys,2,MAXINPUT,true);
                    SplitString(strKeys[1],"=",strType,16);
                    StrCat(strType,16,"=");
                    ReplaceStringEx(strKeys[1],MAXINPUT,strType,"",-1,0);
                    if (strcmp(strType,"float=") == 0)
                        SetEntPropFloat(entReward, propType, strKeys[0], StringToFloat(strKeys[1]));
                    else if (strcmp(strType,"int=") == 0)
                        SetEntProp(entReward, propType, strKeys[0], StringToInt(strKeys[1]));
                    else if (strcmp(strType,"bool=") == 0)
                        SetEntProp(entReward, propType, strKeys[0], StringToInt(strKeys[1]), 1);
                    else if (strcmp(strType,"vec=") == 0)
                    {
                        new Float:vec[3];
                        decl String:strVec[3][16];
                        ExplodeString(strKeys[1],",",strVec,3,16,true);
                        for (new i = 0;i < 3;i++)
                            vec[i] = StringToFloat(strVec[i]);
                        SetEntPropVector(entReward, propType, strKeys[0], vec);
                    }
                    else if (strcmp(strType,"ent=") == 0)
                        SetEntPropEnt(entReward, propType, strKeys[0], StringToInt(strKeys[1]));
                    else
                        SetEntPropString(entReward, propType, strKeys[0], strKeys[1]);
                }
                strcopy(strTemp,MAXINPUT,strCurrent);
                StrCat(strTemp,MAXINPUT,"&");
                ReplaceStringEx(strMain,MAXINPUT,strTemp,"",-1,0);
                ReplaceStringEx(strMain,MAXINPUT,strCurrent,"",-1,0);
            }
        }
        if (!spawned)
            DispatchSpawn(entReward);
        if (entOverlay[index] != FULLSPECTRUM)
        {
            decl colors[4];
            colors[0] = (entOverlay[index] & 0x000000FF);
            colors[1] = (entOverlay[index] & 0x0000FF00) >> 8;
            colors[2] = (entOverlay[index] & 0x00FF0000) >> 16;
            colors[3] = (entOverlay[index] & 0xFF000000) >> 24;
            for (new i = 0;i < 4;i++)
                if (colors[i] < 0)
                    colors[i] = (colors[i] % 256) + 256;
            SetEntityRenderMode(entReward,RENDER_GLOW);
            SetEntityRenderColor(entReward,colors[0],colors[1],colors[2],colors[3]);
            //SetEntityRenderFx(entReward,RENDERFX_GLOWSHELL); // maybe we can play with this later
            //PrintToChatAll("[debug] %d = %d,%d,%d,%d",entOverlay[index],colors[0],colors[1],colors[2],colors[3]);
        }
        TeleportEntity(entReward, defSpawnCoords[index], defSpawnAngles[index], NULL_VECTOR);
        if (respawnMethod[index] & HOOK_DEACTIVE)
        {
            if (respawnTime[index] < 0.0)
                CreateTimer(g_respawnTime, timerRespawnReward, index);
            else if (respawnTime[index] > 0.0)
                CreateTimer(respawnTime[index], timerRespawnReward, index);
        }
        else
        {
            if (respawnMethod[index] & HOOK_TOUCH)
                SDKHook(entReward, SDKHook_StartTouch, mapRewardPickUp);
            if (respawnMethod[index] & HOOK_HURT)
                SDKHook(entReward, SDKHook_OnTakeDamage, mapRewardTakeDamage);
        }
        if (entSpinInt[index] > 0.0)
        {
            entSpinAngles[index] = defSpawnAngles[index];
            entTimers[index] = CreateTimer(entSpinInt[index], timerSpinEnt, index, TIMER_REPEAT);
        }
        spawnEnts[index] = entReward;
    }
    else
    {
        PrintToChatAll("[SM] maprewards: Error, unable to spawn reward #%i",index);
        PrintToServer("[SM] maprewards: Error, unable to spawn reward #%i",index);
    }
}

stock getRewardID(const String:name[], any:client = 0, any:ignore = -1, bool:resolve = true)
{
    new id = -1;
    if ((resolve) && (client > 0) && ((strcmp(name,"@n") == 0) || (strcmp(name,"@aim") == 0)))
    {
        new Float:distance[2];
        new Float:dCoords[2][3];
        if (strlen(name) == 2)
            GetClientAbsOrigin(client,dCoords[0]);
        else
            SetTeleportEndPoint(client,dCoords[0]);
        new bool:initialized;
        for (new i = 0;i < MAXSPAWNPOINT;i++)
        {
            if ((ignore == i) || (strlen(entType[i]) < 1))
                continue;
            if (spawnEnts[i] > -1)
                GetEntPropVector(spawnEnts[i],Prop_Data,"m_vecOrigin",dCoords[1]);
            else
                dCoords[1] = defSpawnCoords[i];
            distance[0] = GetVectorDistance(dCoords[0],dCoords[1]);
            if ((!initialized) || (distance[0] < distance[1]))
            {
                initialized = true;
                distance[1] = distance[0];
                id = i;
            }
        }
    }
    else if ((resolve) && (strcmp(name,"-1") == 0))
        id = getNewestReward();
    else if (StrIsDigit(name) > -1)
        id = StringToInt(name);
    else if (resolve)
    {
        for (new i = 0;i < MAXSPAWNPOINT;i++)
        {
            if (strcmp(entName[i],name) == 0)
            {
                id = i;
                break;
            }
        }
    }
    return id;
}

stock getRewardRange(const String:rewards[], any:range[2], any:client = 0, bool:resolve = true)
{
    range = { -1, -1 };
    new blen;
    new dots;
    decl String:temp[32];
    blen = strlen(rewards);
    switch ((dots = StrFind(rewards,"..")))
    {
        case -1:
        {
            range[0] = range[1] = getRewardID(rewards,client,resolve);
        }
        case 0:
        {
            if (blen > 2)
            {
                range[0] = 0;
                strcopy(temp,32,rewards);
                StrErase(temp,0,2);
                if (StrIsDigit(temp) > -1)
                {
                    range[0] = 0;
                    range[1] = StringToInt(temp);
                }
                else
                    range[0] = range[1] = getRewardID(rewards,client,resolve);
            }
        }
        default:
        {
            if (StrIsDigit(rewards) > -1)
            {
                range[0] = StringToInt(rewards);
                if ((dots += 2) < blen)
                {
                    strcopy(temp,32,rewards);
                    StrErase(temp,0,dots);
                    if (StrIsDigit(temp) > -1)
                        range[1] = StringToInt(temp);
                    else
                        range[0] = range[1] = getRewardID(rewards,client,resolve);
                }
                else
                    range[1] = MAXSPAWNPOINT-1;
            }
        }
    }
    if (range[0] > -1)
    {
        if (range[1] >= MAXSPAWNPOINT)
            range[1] = MAXSPAWNPOINT-1;
        return 0;
    }
    return 1;
}

stock getRewardList(const String:rewards[], bool:list[MAXSPAWNPOINT], any:client = 0)
{
    decl String:str[MAXINPUT];
    strcopy(str,MAXINPUT,rewards);
    decl String:current[32];
    decl range[2];
    decl bool:negate;
    decl len;
    StrCat(str,MAXINPUT,",");
    while (SplitString(str,",",current,32) > -1)
    {
        if (current[0] == '!')
        {
            negate = true;
            StrErase(current,0,1);
        }
        else
            negate = false;
        if (!getRewardRange(current,range,client))
        {
            for (new i = range[0];i <= range[1];i++)
            {
                if (isValidReward(i))
                {
                    if (negate)
                        list[i] = false;
                    else
                        list[i] = true;
                }
            }
        }
        len = strlen(current);
        if (strlen(str) > len)
            len++;
        StrErase(str,0,len);
    }
    new ret = 0;
    for (new i = 0;i < MAXSPAWNPOINT;i++)
        if (list[i])
            ret++;
    return ret;
}

RespondWriteUsage(client)
{
    CRespondToCommand(client,"[SM] Usage: sm_mrw_cfg_save [OPTIONS ...] <file.cfg>");
    CRespondToCommand(client,"[SM]    file.cfg is the cfg file to save to. It will be stored within cfg/maprewards/.");
    CRespondToCommand(client,"[SM]    OPTIONS:");
    CRespondToCommand(client,"[SM]       -E <reward_id|name>");
    CRespondToCommand(client,"[SM]          Exclude reward_id from the cfg.");
    CRespondToCommand(client,"[SM]          Allows a range: #..#, ..#, or #..");
    CRespondToCommand(client,"[SM]          Ranges do not accept reward names, only their ID numbers.");
    CRespondToCommand(client,"[SM]          Multiple -E switches are accepted.");
    CRespondToCommand(client,"[SM]       -o <X Y Z>");
    CRespondToCommand(client,"[SM]          Set the origin coordinates. Only used if the -R switch is also set.");
    CRespondToCommand(client,"[SM]          The origin will default to your location (or 0,0,0 for the server) unless this option is present.");
    CRespondToCommand(client,"[SM]          Relative coordinates can be used to offset from your current coordinates.");
    CRespondToCommand(client,"[SM]       -O <#userid|name>");
    CRespondToCommand(client,"[SM]          Set the origin coordinates to a player's location.");
    CRespondToCommand(client,"[SM]          May be used in conjunction with -o to offset from a player as long as -O is provided first.");
    CRespondToCommand(client,"[SM]       -D <#reward_id|name>");
    CRespondToCommand(client,"[SM]          Set the origin coordinates to a reward's location.");
    CRespondToCommand(client,"[SM]       -R");
    CRespondToCommand(client,"[SM]          Save the rewards with coordinates relative to the origin.");
    CRespondToCommand(client,"[SM]          If this switch is not present, the -o, -O, and -D switches will be ignored.");
    CRespondToCommand(client,"[SM]       -f");
    CRespondToCommand(client,"[SM]          Force the saving of the file, even if a file with the same name already exists.");
}

RespondLoadUsage(client)
{
    CRespondToCommand(client,"[SM] Usage: sm_mrw_cfg_load [OPTIONS ...] <file.cfg>");
    CRespondToCommand(client,"[SM]    file.cfg is the name of a previously saved cfg file stored within cfg/maprewards/.");
    CRespondToCommand(client,"[SM]    OPTIONS:");
    CRespondToCommand(client,"[SM]       -E <reward_id>");
    CRespondToCommand(client,"[SM]          Exclude reward_id from being loaded.");
    CRespondToCommand(client,"[SM]          Allows a range: #..#, ..#, or #..");
    CRespondToCommand(client,"[SM]          reward_id can only be numbers that correspond to the reward in the order they appear in the CFG, starting with 0.");
    CRespondToCommand(client,"[SM]          Multiple -E switches are accepted.");
    CRespondToCommand(client,"[SM]       -o <X Y Z>");
    CRespondToCommand(client,"[SM]          Set the origin coordinates. Only used for rewards in the cfg that were saved with relative coordinates.");
    CRespondToCommand(client,"[SM]          The origin will default to your location (or 0,0,0 for the server) unless this option is present.");
    CRespondToCommand(client,"[SM]          Relative coordinates can be used to offset from your current coordinates.");
    CRespondToCommand(client,"[SM]       -O <#userid|name>");
    CRespondToCommand(client,"[SM]          Set the origin coordinates to a player's location.");
    CRespondToCommand(client,"[SM]          May be used in conjunction with -o to offset from a player as long as -O is provided first.");
    CRespondToCommand(client,"[SM]       -D <#reward_id|name>");
    CRespondToCommand(client,"[SM]          Set the origin coordinates to a reward's location.");
    CRespondToCommand(client,"[SM]       -N   Not relative. Does not set the origin coordinates, useful for cfg's that have dangerously long commands.");
}

stock RespondAddUsage(client)
{
    CRespondToCommand(client, "[SM] Usage: sm_mrw_add [OPTIONS ...] [command ...]");
    CRespondToCommand(client, "[SM]    At least model or entity_type is required.");
    CRespondToCommand(client, "[SM]       If entity_type is prop_physics_override, both are required.");
    CRespondToCommand(client, "[SM]    command is a full command to run when a player touches the reward.");
    CRespondToCommand(client, "[SM]       If present, #player will be replaced with the target string of the client who activated the reward.");
    CRespondToCommand(client, "[SM]    OPTIONS:");
    CRespondToCommand(client, "[SM]       -h   Display this help text.");
    CRespondToCommand(client, "[SM]       -A <health>");
    CRespondToCommand(client, "[SM]          Set an internal health amount for the reward.");
    CRespondToCommand(client, "[SM]          Only used when respawn_method is kill{deafult} to kill the reward after it takes this much damage.");
    CRespondToCommand(client, "[SM]       -b <#reward_id|name>");
    CRespondToCommand(client, "[SM]          Uses the provided reward as a base to copy data from.");
    CRespondToCommand(client, "[SM]          This switch should appear before anything else as it overwrites all the data.");
    CRespondToCommand(client, "[SM]          The origin coordinates will be set to this reward unless the origin is set.");
    CRespondToCommand(client, "[SM]       -c <X Y Z>");
    CRespondToCommand(client, "[SM]          Coordinates to spawn the entity at, can be relative to origin using ~'s.");
    CRespondToCommand(client, "[SM]          If not provided, origin will be used.");
    CRespondToCommand(client, "[SM]       -d <respawn_method>");
    CRespondToCommand(client, "[SM]          Must be one of the following:");
    CRespondToCommand(client, "[SM]          pickup: When a player touches it, it will disappear until the respawn time is up.");
    CRespondToCommand(client, "[SM]          static: The reward will stay, but will be inactive until the respawn time is up.");
    CRespondToCommand(client, "[SM]          constant: The reward will stay and never deactivate.");
    CRespondToCommand(client, "[SM]          hurt: The reward will trigger when a player hurts it.");
    CRespondToCommand(client, "[SM]          kill: The reward will trigger when a player kills it.");
    CRespondToCommand(client, "[SM]          notouch: The reward will not trigger when a player touches it. Can be used after other settings to remove the touch event.");
    CRespondToCommand(client, "[SM]          nohook or nopickup: Default. Just an entity, nothing special about it.");
    CRespondToCommand(client, "[SM]       -e <entity_type>");
    CRespondToCommand(client, "[SM]          The type of entity you wish to create. If not provided, prop_physics_override is used.");
    CRespondToCommand(client, "[SM]          You may use model aliases defined with sm_mrw_model_add.");
    CRespondToCommand(client, "[SM]       -l <R G B A>");
    CRespondToCommand(client, "[SM]          Set the color overlay.");
    CRespondToCommand(client, "[SM]       -L <integer_color>");
    CRespondToCommand(client, "[SM]          Set the color overlay. integer_color is an RGBA value in integer representation.");
    CRespondToCommand(client, "[SM]       -m <model>");
    CRespondToCommand(client, "[SM]          The path to the model file you wish to use.");
    CRespondToCommand(client, "[SM]          You may use model aliases defined with sm_mrw_model_add.");
    CRespondToCommand(client, "[SM]       -n <name>");
    CRespondToCommand(client, "[SM]          Allows you to define a name for the entity, which can be later used when referring to this reward.");
    CRespondToCommand(client, "[SM]          If not defined, the name will default to its corresponding ID number.");
    CRespondToCommand(client, "[SM]       -o <X Y Z>");
    CRespondToCommand(client, "[SM]          Origin coordinates. If not provided client's location will be used.");
    CRespondToCommand(client, "[SM]       -O <#userid|name>");
    CRespondToCommand(client, "[SM]          Set the origin coordinates to a player's location.");
    CRespondToCommand(client, "[SM]       -D <#reward_id|name>");
    CRespondToCommand(client, "[SM]          Set the origin coordinates to a reward's location.");
    CRespondToCommand(client, "[SM]       -p <entity_property_script>");
    CRespondToCommand(client, "[SM]          Allows you to define a series of entity properties using this format:");
    CRespondToCommand(client, "[SM]             [prop_type:]key,[type=]value");
    CRespondToCommand(client, "[SM]             prop_type must be 0 for Prop_Data (default) or 1 for Prop_Send.");
    CRespondToCommand(client, "[SM]             type may be one of the following: int float string ent or vec.");
    CRespondToCommand(client, "[SM]                For vec, value must be a series of 3 floats seperated by commas.");
    CRespondToCommand(client, "[SM]             Multiple key,value pairs can be seperated by &'s.");
    CRespondToCommand(client, "[SM]             Please do not set m_iName here. Use the -n switch to set a name.");
    CRespondToCommand(client, "[SM]          You may use script aliases defined with sm_mrw_script_add.");
    CreateTimer(0.05, delayedAddUsage, client);
}

public Action:delayedAddUsage(Handle:Timer, any:client)
{
    CRespondToCommand(client, "[SM]       -r <RX RY RZ>");
    CRespondToCommand(client, "[SM]          Rotations for the entity. Cannot be relative.");
    CRespondToCommand(client, "[SM]       -s <script>");
    CRespondToCommand(client, "[SM]          A series of variables dispatched to the entity as an overridescript or individual keys to trigger.");
    CRespondToCommand(client, "[SM]          A value of null will erase the script defined by a provided model alias.");
    CRespondToCommand(client, "[SM]          Format:");
    CRespondToCommand(client, "[SM]             overridescript?key[,[type=]value]");
    CRespondToCommand(client, "[SM]             type may be one of the following: int float or string.");
    CRespondToCommand(client, "[SM]             Multiple key[,value]'s can be seperated on the right side of the ? by &'s.");
    CRespondToCommand(client, "[SM]          You may use script aliases defined with sm_mrw_script_add.");
    CRespondToCommand(client, "[SM]       -t <respawn_time>");
    CRespondToCommand(client, "[SM]             The fractional seconds until the reward respawns.");
    CRespondToCommand(client, "[SM]             A value of 0 will never respawn.");
    CRespondToCommand(client, "[SM]             A value of -1 will use the value of sm_mrw_respawn_time.");
    CRespondToCommand(client, "[SM]       -T <SX SY SZ interval>");
    CRespondToCommand(client, "[SM]          Set the reward to rotate every interval.");
    CRespondToCommand(client, "[SM]          interval is in fractional seconds.");
    CRespondToCommand(client, "[SM]       -U   model, script, and entity_property aliases will not be evaluated until spawn time.");
    CRespondToCommand(client, "[SM]       -u   Unsets the -U switch, causing all aliases to be evaluated now.");
    CRespondToCommand(client, "[SM]       -X   Sets the command for when the reward is killed to command.");
    CRespondToCommand(client, "[SM]               To set both pickup and kill commands requires an extra call to sm_mrw_modify.");
    CRespondToCommand(client, "[SM]               If respawn_method is set to kill and -X is not present, command will be used for both pickup and kill.");
    CRespondToCommand(client, "[SM]       -P   Sets respawn_method to pickup.");
    CRespondToCommand(client, "[SM]       -S   Sets respawn_method to static.");
    CRespondToCommand(client, "[SM]       -C   Sets respawn_method to constant.");
    CRespondToCommand(client, "[SM]       -H   Adds hurt to the current respawn_method.");
    CRespondToCommand(client, "[SM]       -K   Adds kill to the current respawn_method.");
    CRespondToCommand(client, "[SM]       -N   Removes touch events from the current respawn_method.");
    CRespondToCommand(client, "[SM]       -R   Automatically release the reward from the plugin imediately after spawning it.");
    return Plugin_Stop;
}

RespondModifyUsage(client)
{
    CRespondToCommand(client, "[SM] Usage: sm_mrw_modify <#reward_id|name> [OPTIONS ...] [command ...]");
    CRespondToCommand(client, "[SM]    OPTIONS is exactly the same as sm_mrw_add with the following exceptions:");
    CRespondToCommand(client, "[SM]       -o - Origin coordinates default to the reward's if not specified.");
    CRespondToCommand(client, "[SM]       -r - Rotation angles can now be relative.");
    CRespondToCommand(client, "[SM]       -h - No help switch, because it breaks the flow of this command.");
    CRespondToCommand(client, "[SM]    Use sm_mrw_add -h for a detailed paragraph about the OPTIONS.");
    CRespondToCommand(client, "[SM]    If any combination of options that result in a conflict are used, an error explaining why that specific option could not be set will be displayed. Other options will still be applied.");
    CRespondToCommand(client, "[SM]    If any multi-argument options are missing arguments, the command will stop where the error occured. This might cause undefined behaviour, and you will need to manually sm_mrw_respawn the reward.");
}

RespondTriggerUsage(client)
{
    CRespondToCommand(client,"[SM] Usage: sm_mrw_trigger <#reward_id|name> [OPTIONS ...] [#userid|name]");
    CRespondToCommand(client,"[SM]    OPTIONS:");
    CRespondToCommand(client,"[SM]       -R   Do not kill and respawn the reward.");
    CRespondToCommand(client,"[SM]       -t <respawn_time>");
    CRespondToCommand(client,"[SM]          Temporarily override the reward's respawn_time setting.");
    CRespondToCommand(client,"[SM]       -X   Treat the trigger as a hurt or kill event.");
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    CreateConVar("sm_mrw_version", VERSION, "Map Rewards Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    c_enable = CreateConVar("sm_mrw_enable", "1.0", "0 = disabled. 1 = enabled", 0, true, 0.0, true, 1.0);
    c_respawnTime = CreateConVar("sm_mrw_respawn_time", "5.0", "Default seconds until a reward will respawn.", 0, true, 0.0);
    c_cleanUp = CreateConVar("sm_mrw_cleanup", "8", "When to release and kill all rewards. OR desired values together. 0: never, 1: plugin end, 2: map start, 4: round start, 8: on auto load, 16: on manual load", 0, true, 0.0, true, 31.0);
    c_autoLoad = CreateConVar("sm_mrw_autoload", "2", "When to auto load map or server cfg saves. OR desired values together. 0: never, 1: map start (maprewards/server.cfg), 2: map start (maprewards/<map>.cfg), 4: round start (maprewards/<map>.cfg), 8: round start (maprewards/server.cfg)", 0, true, 0.0, true, 7.0);
    c_autoSave = CreateConVar("sm_mrw_autosave", "0", "When to auto save map cfg. OR desired values together. 0: never 1: plugin end, 2: map start (basically map end; internal data is still intact until cleanup), 4: round start (basically round end), 8: on clean up, 16: on every edit/addition that's not from the server, 32: on remove, 64: always backup first", 0, true, 0.0, true, 127.0);
    c_basicFlag = CreateConVar("sm_mrw_flag_basic", "i", "Admin flag required for basic mrw commands.", 0);
    c_createFlag = CreateConVar("sm_mrw_flag_create", "m", "Admin flag required for creating or modifying rewards.", 0);
    c_extendedFlag = CreateConVar("sm_mrw_flag_extended", "m", "Admin flag required for all sm_mrw_cfg_* commands except for load and list.", 0);

    RegConsoleCmd("sm_mrw_info", infoSpawnPoint, "Displays info about a specific reward spawn point.");
    RegConsoleCmd("sm_mrw_add", addSpawnPoint, "Sets a spawn point on the map for a reward.");
    RegConsoleCmd("sm_mrw_modify", modifySpawnPoint, "Modify a reward spawn point.");
    RegConsoleCmd("sm_mrw_remove", removeSpawnPoint, "Removes a reward on the map (starting with 0, not 1).");
    RegConsoleCmd("sm_mrw_removeall", removeSpawnPoints, "Removes all rewards on the map.");
    RegConsoleCmd("sm_mrw_model_reload", reloadAlias, "Reloads 'cfg/maprewards/aliases.cfg'.");
    RegConsoleCmd("sm_mrw_model_add", addAlias, "Adds a model alias. Does not save.");
    RegConsoleCmd("sm_mrw_model_save", saveAlias, "Saves the current model aliases to 'cfg/maprewards/aliases.cfg'.");
    RegConsoleCmd("sm_mrw_model_list", listAlias, "Lists all current model aliases.");
    RegConsoleCmd("sm_mrw_script_reload", reloadScript, "Reloads 'cfg/maprewards/scripts.cfg'.");
    RegConsoleCmd("sm_mrw_script_add", addScript, "Adds a script alias. Does not save.");
    RegConsoleCmd("sm_mrw_script_save", saveScript, "Saves the current scripts to 'cfg/maprewards/scripts.cfg'.");
    RegConsoleCmd("sm_mrw_script_list", listScript, "Lists all current scripts.");
    RegConsoleCmd("sm_mrw_cfg_save", writeCFG, "Saves current reward spawn points to a cfg file for later reuse.");
    RegConsoleCmd("sm_mrw_cfg_load", loadCFG, "Loads a saved maprewards cfg file.");
    RegConsoleCmd("sm_mrw_cfg_list", listSavedCFG, "Lists all saved maprewards cfg files.");
    RegConsoleCmd("sm_mrw_cfg_delete", deleteSavedCFG, "Deletes a saved maprewards cfg file.");
    RegConsoleCmd("sm_mrw_cfg_purge", purgeSavedCFG, "Deletes all auto-save backup maprewards cfg files.");
    RegConsoleCmd("sm_mrw_tp", tpPlayer, "Teleports you to the provided reward.");
    RegConsoleCmd("sm_mrw_kill", killEntity, "Kills an entity by its edict ID. To be used with entities after releasing them.");
    RegConsoleCmd("sm_mrw_respawn", manuallyRespawnReward, "Respawn or reactivate a reward early.");
    RegConsoleCmd("sm_mrw_trigger", mapRewardTrigger, "Triggers a reward remotely.");
    RegAdminCmd("sm_exec2", exec2CFG, ADMFLAG_SLAY, "Executes a cfg file provided as the second argument. Accepts a first argument, but is ignored unless the third argument is '0'. If the third argument is anything else, it will be used instead of the player's name. Any additional arguments will be used instead of the default message.");
    RegAdminCmd("sm_teleplus", teleportCmd, ADMFLAG_SLAY, "Teleport a player to a set of coordinates with optional rotation and velocity. Relative coords, angles, and velocity are allowed.");
    
    HookEvent("teamplay_round_start", OnRoundStart);//, EventHookMode_PostNoCopy);

    HookConVarChange(c_enable, cvarEnableChange);
    HookConVarChange(c_respawnTime, cvarChange);
    HookConVarChange(c_cleanUp, cvarCleanChange);
    HookConVarChange(c_autoLoad, cvarLoadChange);
    HookConVarChange(c_autoSave, cvarSaveChange);
    HookConVarChange(c_basicFlag, cvarBasicFlagChange);
    HookConVarChange(c_createFlag, cvarCreateFlagChange);
    HookConVarChange(c_extendedFlag, cvarExtendedFlagChange);
    
    aliasCount = loadAliases();
    scriptCount = loadScripts();
}

public cvarEnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_enable = StringToInt(newValue);
    if ((StringToInt(oldValue)) && (!g_enable))
        killRewards();
    else if ((!StringToInt(oldValue)) && (g_enable))
        spawnRewards();
}

public cvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_respawnTime = StringToFloat(newValue);
}

public cvarCleanChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_cleanUp = StringToInt(newValue);
}

public cvarLoadChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_autoLoad = StringToInt(newValue);
}

public cvarSaveChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_autoSave = StringToInt(newValue);
}

public cvarBasicFlagChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_basicFlag = 0;
    for (new i = 0, j = strlen(newValue);i < j;i++)
        orFlag(g_basicFlag,newValue[i]);
}

public cvarCreateFlagChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_createFlag = 0;
    for (new i = 0, j = strlen(newValue);i < j;i++)
        orFlag(g_createFlag,newValue[i]);
}

public cvarExtendedFlagChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_extendedFlag = 0;
    for (new i = 0, j = strlen(newValue);i < j;i++)
        orFlag(g_extendedFlag,newValue[i]);
}

public OnPluginEnd()
{
    cleanUp(CLEAN_PLUG_END,autoSave(SAVE_PLUG_END));
}

public OnMapStart()
{   // Get cvar values.
    g_enable = GetConVarInt(c_enable);
    g_respawnTime = GetConVarFloat(c_respawnTime);
    g_cleanUp = GetConVarInt(c_cleanUp);
    g_autoLoad = GetConVarInt(c_autoLoad);
    g_autoSave = GetConVarInt(c_autoSave);
    
    autoLoad(LOAD_MAP_START|LOAD_PLUG_START,cleanUp(CLEAN_MAP_START,autoSave(SAVE_MAP_START)));
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    //CreateTimer(5.0, timerRespawnReward, -1);
    autoLoad(LOAD_ROUND_START|LOAD_ROUND_START_B,cleanUp(CLEAN_ROUND_START,autoSave(SAVE_ROUND_START)));
    spawnRewards();
}

public Action:teleportCmd(client, args)
{
    decl String:targetp[65];
    new Float:coordsC[3][3];
    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS];
    decl bool:tn_is_ml;
    new target_count = 0;
    new neededArgs = args;
    new nextArg = 2;
    if (args > 1)
    {
        GetCmdArg(1,targetp,65); // Thanks to C++ std::regex I'm superstitious about grabbing things out of order...
        decl String:temp[MAX_TARGET_LENGTH];
        GetCmdArg(2,temp,MAX_TARGET_LENGTH);     // Otherwise, this would be the only GetCmdArg call in this block
        if (strcmp(temp,"@aim") == 0)
        {
            if ((client == 0) || (!IsClientInGame(client)))
            {
                RespondToCommand(client,"[SM] Error: You must be in game to use \"@aim\" coordinates.");
                return Plugin_Handled;
            }
            SetTeleportEndPoint(client,coordsC[0]);
            neededArgs += 2;
            nextArg++;
        }
        else if ((args == 2) || (args == 5) || (args == 8))
        {
            if ((target_count = ProcessTargetString(temp,client,target_list,1,COMMAND_FILTER_ALIVE,target_name,MAX_TARGET_LENGTH,tn_is_ml)) < 1)
            {
                ReplyToTargetError(client,target_count);
                return Plugin_Handled;
            }
            GetClientAbsOrigin(target_list[0],coordsC[0]);
            neededArgs += 2;
            nextArg++;
        }
    }
    if ((neededArgs != 4) && (neededArgs != 7) && (neededArgs != 10))
    {
        RespondToCommand(client,"[SM] Usage: sm_teleplus <#userid|name> <X Y Z> [RX RY RZ] [VX VY VZ]");
        return Plugin_Handled;
    }
    target_count = 0;
    if ((target_count = ProcessTargetString(targetp,client,target_list,MAXPLAYERS,COMMAND_FILTER_ALIVE,target_name,MAX_TARGET_LENGTH,tn_is_ml)) < 1)
    {
        ReplyToTargetError(client,target_count);
        return Plugin_Handled;
    }
    new Float:coordsO[3][3];
    new bool:relative[3][3];
    for (new h = nextArg-2;nextArg <= args;h++)
    {
        for (new i = 0;i < 3;i++)
        {
            GetCmdArg(nextArg++,targetp,16);
            if (targetp[0] == '~')
            {
                relative[h][i] = true;
                if (strlen(targetp) > 1)
                {
                    StrErase(targetp,0,1);
                    coordsC[h][i] += StringToFloat(targetp);
                }
            }
            else
                coordsC[h][i] = StringToFloat(targetp);
        }
    }
    for (new i = 0;i < target_count;i++)
    {
        GetClientAbsOrigin(target_list[i],coordsO[0]);
        GetClientEyeAngles(target_list[i],coordsO[1]);
        GetEntPropVector(target_list[i],Prop_Data,"m_vecVelocity",coordsO[2]);
        for (new h = 0;h < 3;h++)
            for (new o = 0;o < 3;o++)
                if (relative[h][o])
                    coordsC[h][o] += coordsO[h][o];
        TeleportEntity(target_list[i], coordsC[0], coordsC[1], coordsC[2]);
    }
    return Plugin_Handled;
}

public Action:exec2CFG(client, args)
{
    if (args > 2)
    {
        decl String:targetp[65];
        decl String:target_name[MAX_TARGET_LENGTH];
        decl target_list[MAXPLAYERS];
        decl bool:tn_is_ml;
        GetCmdArg(1,targetp,65);
        decl String:opt_name[MAX_TARGET_LENGTH];
        GetCmdArg(3,opt_name,MAX_TARGET_LENGTH);
        new String:msg[250];
        if (args > 3)
        {
            decl String:buffer[250];
            for (new i = 4; i <= args; i++)
            {
                GetCmdArg(i,buffer,250);
                StrCat(msg,250,buffer);
                StrCat(msg,250," ");
            }
        }
        else
        {
            msg = "has earned a reward!";
        }
        if (strcmp(opt_name,"0") == 0)
        {
            if (ProcessTargetString(targetp,client,target_list,MAXPLAYERS,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml) <= 0)
                target_name = "Everyone";
        }
        else
            target_name = opt_name;
        Format(msg,250,"%c%s%c %s",0x04,target_name,0x01,msg);
        SayText2(client,msg);
        //CPrintToChatAll("%c%s%c %s",0x04,target_name,0x01,msg);
        CPrintToServer("%s %s",target_name,msg);
    }
    if (args > 1)
    {
        decl String:cfg[MAXINPUT];
        GetCmdArg(2,cfg,MAXINPUT);
        ServerCommand("exec %s",cfg);
    }
    return Plugin_Handled;
}

public Action:listSavedCFG(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    decl String:dir[128];
    new bool:topdir = true;
    dir = "cfg/maprewards/";
    if (args > 0)
    {
        decl String:buffer[112];
        GetCmdArg(1,buffer,112);
        while ((buffer[0] == '/') || (buffer[0] == '\\'))
            StrErase(buffer,0);
        if (StrFind(buffer,"..") > -1)
        {
            RespondToCommand(client,"[SM] Error: Illegal path.");
            return Plugin_Handled;
        }
        StrCat(dir,128,buffer);
        topdir = false;
    }
    new Handle:cfgs = OpenDirectory(dir);
    if (cfgs == INVALID_HANDLE)
    {
        RespondToCommand(client,"[SM] No saved CFG files found in '%s'.",dir);
        RespondToCommand(client,"[SM] Usage: sm_mrw_cfg_list [directory] - directory starts in 'cfg/maprewards/'.");
        return Plugin_Handled;
    }
    decl String:filename[128];
    decl FileType:filetype;
    new total = 0;
    while (ReadDirEntry(cfgs,filename,128,filetype))
    {
        if ((filetype != FileType_File) || (strcmp(filename,".") == 0) || (strcmp(filename,"..") == 0) || ((topdir) && ((strcmp(filename,"scripts.cfg") == 0) || (strcmp(filename,"aliases.cfg") == 0))))
            continue;
        RespondToCommand(client,"[SM] [%d] '%s'",++total,filename);
    }
    RespondToCommand(client,"[SM] Found %d saves in '%s'.",total,dir);
    return Plugin_Handled;
}

public Action:deleteSavedCFG(client, args)
{
    if (!handleClientAccess(client,g_extendedFlag))
        return Plugin_Handled;
    decl String:filename[128];
    filename = "cfg/maprewards/";
    if (args < 1)
    {
        RespondToCommand(client,"[SM] Usage: sm_mrw_cfg_delete <cfg_file> - Path starts in 'cfg/maprewards/'.");
        return Plugin_Handled;
    }
    decl String:buffer[112];
    GetCmdArg(1,buffer,112);
    while ((buffer[0] == '/') || (buffer[0] == '\\'))
        StrErase(buffer,0);
    if (StrFind(buffer,"..") > -1)
    {
        RespondToCommand(client,"[SM] Error: Illegal path.");
        return Plugin_Handled;
    }
    StrCat(filename,128,buffer);
    if (!FileExists(filename))
    {
        RespondToCommand(client,"[SM] Error: '%s' file does not exist.",filename);
        return Plugin_Handled;
    }
    if (DeleteFile(filename))
        RespondToCommand(client,"[SM] Deleted '%s'.",filename);
    else
        RespondToCommand(client,"[SM] Error: Cannot delete file '%s'.",filename);
    return Plugin_Handled;
}

public Action:purgeSavedCFG(client, args)
{
    if (!handleClientAccess(client,g_extendedFlag))
        return Plugin_Handled;
    if (DirExists("cfg/maprewards/backup"))
    {
        if (RemoveDir("cfg/maprewards/backup"))
            RespondToCommand(client,"[SM] Successfully purged all backup maprewards cfg files.");
        else
            RespondToCommand(client,"[SM] Error: Unable to delete 'cfg/maprewards/backup/'.");
    }
    else
        RespondToCommand(client,"[SM] No backups to purge.");
    return Plugin_Handled;
}

public Action:tpPlayer(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (args < 1)
    {
        RespondToCommand(client,"[SM] Usage: sm_mrw_tp <#id|name> [#userid|name] [X Y Z] [RX RY RZ] [VX VY VZ]");
        return Plugin_Handled;
    }
    decl String:target[32];
    decl String:target_name[MAX_NAME_LENGTH];
    decl target_list[MAXPLAYERS];
    decl target_count;
    decl bool:tn_is_ml;
    GetCmdArg(1,target,32);
    new tempID = getRewardID(target,client);
    if (!isValidReward(tempID))
    {
        RespondToCommand(client, "[SM] Error: Unknown reward '%s'",target);
        return Plugin_Handled;
    }
    new Float:rCoords[4][3];
    if (IsValidEntity(spawnEnts[tempID]))
    {
        GetEntPropVector(spawnEnts[tempID],Prop_Data,"m_vecOrigin",rCoords[0]);
        GetEntPropVector(spawnEnts[tempID],Prop_Data,"m_angRotation",rCoords[1]);
    }
    else
    {
        rCoords[0] = defSpawnCoords[tempID];
        rCoords[1] = defSpawnAngles[tempID];
    }
    new bool:relativeV[4];
    new nextArg = 2;
    switch (args)
    {
        case 1, 4, 7, 10:
        {
            target_list[0] = client;
            target_count = 1;
        }
        case 2, 5, 8, 11:
        {
            GetCmdArg(nextArg++,target,32);        
            if ((target_count = ProcessTargetString(
                    target,
                    client,
                    target_list,
                    MAXPLAYERS,
                    COMMAND_FILTER_ALIVE,
                    target_name,
                    sizeof(target_name),
                    tn_is_ml)) <= 0)
            {
                ReplyToTargetError(client, target_count);
                return Plugin_Handled;
            }
        }
        default:
        {
            RespondToCommand(client,"[SM] Usage: sm_mrw_tp <#id|name> [#userid|name] [X Y Z] [RX RY RZ] [VX VY VZ]");
            return Plugin_Handled;
        }
    }
    decl String:temp[16];
    for (new h = 0;nextArg <= args;h++)
    {
        for (new i = 0;i < 3;i++)
        {
            GetCmdArg(nextArg++,temp,16);
            if (temp[0] == '~')
            {
                if (h == 2)
                    relativeV[3] = relativeV[i] = true;
                if (strlen(temp) > 1)
                {
                    StrErase(temp,0,1);
                    rCoords[h][i] += StringToFloat(temp);
                }
            }
            else
                rCoords[h][i] = StringToFloat(temp);
        }
    }
    rCoords[3] = rCoords[2];
    for (new i = 0;i < target_count;i++)
    {
        if (relativeV[3])
        {
            GetEntPropVector(target_list[i],Prop_Data,"m_vecVelocity",rCoords[3]);
            for (new h = 0;h < 3;h++)
                if (relativeV[h])
                    rCoords[3][h] += rCoords[2][h];
        }
        TeleportEntity(target_list[i], rCoords[0], rCoords[1], rCoords[3]);
    }
    return Plugin_Handled;
}

public Action:infoSpawnPoint(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (args < 1)
    {
        RespondToCommand(client,"[SM] Usage: sm_mrw_info <#id|name>");
        return Plugin_Handled;
    }
    decl String:buffer[32];
    GetCmdArg(1,buffer,32);
    new tempID = getRewardID(buffer,client);
    if (!isValidReward(tempID))
    {
        RespondToCommand(client, "[SM] Unknown reward '%s'",buffer);
        return Plugin_Handled;
    }
    decl String:cmdC[MAXCMDLEN];
    buildRewardCmd(tempID,cmdC,MAXCMDLEN);
    Format(buffer,32,"\nsm_mrw_modify %d ",tempID);
    ReplaceStringEx(cmdC,MAXCMDLEN,"\nsm_mrw_modify -1 ",buffer);
    CRespondToCommand(client,"[SM] Info on #%d(%d): X=%.1f Y=%.1f Z=%.1f RX=%.1f RY=%.1f RZ=%.1f",tempID,spawnEnts[tempID],defSpawnCoords[tempID][0],defSpawnCoords[tempID][1],defSpawnCoords[tempID][2],defSpawnAngles[tempID][0],defSpawnAngles[tempID][1],defSpawnAngles[tempID][2]);
    if (((tempID > 0) && (StringToInt(entName[tempID]) != tempID)) || ((tempID == 0) && (strcmp(entName[tempID],"0") != 0)))
        CRespondToCommand(client,"[SM] Name: %s",entName[tempID]);
    if (unEvaluate[tempID])
        CRespondToCommand(client,"[SM] Aliases will be evaluated at spawn time.");
    if (strcmp(entType[tempID],"prop_physics_override") != 0)
        CRespondToCommand(client,"[SM] Entity Class: %s",entType[tempID]);
    if (strlen(model[tempID]) > 0)
        CRespondToCommand(client,"[SM] Model: %s",model[tempID]);
    CRespondToCommand(client,"[SM] Spawn scripts: [%s] [%s]",script[tempID][0],script[tempID][1]);
    if (entSpinInt[tempID] > 0.0)
        CRespondToCommand(client,"[SM] Rotate [%.1f %.1f %.1f] every %.1f seconds.",entSpin[tempID][0],entSpin[tempID][1],entSpin[tempID][2],entSpinInt[tempID]);
    if (entOverlay[tempID] != FULLSPECTRUM)
    {
        decl colors[4];
        colors[0] = (entOverlay[tempID] & 0x000000FF);
        colors[1] = (entOverlay[tempID] & 0x0000FF00) >> 8;
        colors[2] = (entOverlay[tempID] & 0x00FF0000) >> 16;
        colors[3] = (entOverlay[tempID] & 0xFF000000) >> 24;
        for (new i = 0;i < 4;i++)
            if (colors[i] < 0)
                colors[i] = (colors[i] % 256) + 256;
        CRespondToCommand(client,"[SM] Glow Color: %d (%d,%d,%d,%d)",entOverlay[tempID],colors[0],colors[1],colors[2],colors[3]);
    }
    new String:respawnStr[42];
    if (respawnMethod[tempID] & HOOK_TOUCH)
        StrCat(respawnStr,42," touch");
    if (respawnMethod[tempID] & HOOK_HURT)
        StrCat(respawnStr,42," hurt");
    if (respawnMethod[tempID] & HOOK_KILL)
        StrCat(respawnStr,42," kill");
    if (respawnMethod[tempID] & HOOK_STATIC)
        StrCat(respawnStr,42," static");
    if (respawnMethod[tempID] & HOOK_CONSTANT)
        StrCat(respawnStr,42," constant");
    if (respawnMethod[tempID] & HOOK_DEACTIVE)
        StrCat(respawnStr,42," inactive");
    if (strlen(respawnStr) < 1)
        respawnStr = " nohook";
    StrErase(respawnStr,0,1);
    CRespondToCommand(client,"[SM] Respawn Method: %d (%s).",respawnMethod[tempID],respawnStr);
    if (entHealth[tempID] > 0.0)
        CRespondToCommand(client,"[SM] Health: %.2f",entHealth[tempID]);
    if (strlen(rCommand[tempID][0]) > 0)
        CRespondToCommand(client,"[SM] Touch Command: %s",rCommand[tempID][0]);
    if (strlen(rCommand[tempID][1]) > 0)
        CRespondToCommand(client,"[SM] Kill Command: %s",rCommand[tempID][1]);
    RespondToCommand(client,"[SM] %s",cmdC);
    return Plugin_Handled;
}

public Action:listAlias(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    for (new i = 0;i < aliasCount;i++)
        CRespondToCommand(client,"[SM] #%d: '%s' = '%s' (%s) : '%s' : '%s'",i,aliases[i][0],aliases[i][1],aliases[i][2],aliases[i][3],aliases[i][4]);
    return Plugin_Handled;
}

public Action:reloadAlias(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    aliasCount = loadAliases();
    RespondToCommand(client,"[SM] Successfully loaded %d aliases.",aliasCount);
    return Plugin_Handled;
}

public Action:addAlias(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (args < 2)
    {
        RespondToCommand(client, "[SM] Usage: sm_mrw_model_add <name> <model> [entity_type] [overridescript] [entity_properties]");
        return Plugin_Handled;
    }
    decl String:buffer[MAXINPUT];
    GetCmdArg(1, buffer, MAXINPUT);
    strcopy(aliases[aliasCount][0],MAXINPUT,buffer);
    new marg = args;
    if (marg > 5)
        marg = 5;
    for (new i = 2;i <= marg;i++)
    {
        GetCmdArg(i, buffer, sizeof(buffer));
        if ((strcmp(buffer,"0") != 0) && (strcmp(buffer,"null") != 0))
            strcopy(aliases[aliasCount][i-1],MAXINPUT,buffer);
    }
    CRespondToCommand(client, "[SM] Added alias #%d '%s' as '%s' (%s). Override: '%s' EntProp: '%s'.",aliasCount,aliases[aliasCount][0],aliases[aliasCount][1],aliases[aliasCount][2],aliases[aliasCount][3],aliases[aliasCount][4]);
    aliasCount++;
    return Plugin_Handled;
}

public Action:saveAlias(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (writeAliases())
        RespondToCommand(client, "[SM] Successfully saved 'cfg/maprewards/aliases.cfg' file.");
    else
        RespondToCommand(client, "[SM] Some kind of error has occurred trying to save 'cfg/maprewards/aliases.cfg' file.");
    return Plugin_Handled;
}

public Action:listScript(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    for (new i = 0;i < scriptCount;i++)
        CRespondToCommand(client,"[SM] #%d: '%s' = '%s'",i,scripts[i][0],scripts[i][1]);
    return Plugin_Handled;
}

public Action:reloadScript(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    scriptCount = loadScripts();
    RespondToCommand(client,"[SM] Successfully loaded %d scripts.",scriptCount);
    return Plugin_Handled;
}

public Action:addScript(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (args < 2)
    {
        RespondToCommand(client, "[SM] Usage: sm_mrw_script_add <name> <script>");
        return Plugin_Handled;
    }
    decl String:buffer[MAXINPUT];
    GetCmdArg(1, buffer, sizeof(buffer));
    strcopy(scripts[scriptCount][0],MAXINPUT,buffer);
    GetCmdArg(2, buffer, sizeof(buffer));
    strcopy(scripts[scriptCount][1],MAXINPUT,buffer);
    CRespondToCommand(client, "[SM] Added script #%d '%s' as '%s'.",scriptCount,scripts[scriptCount][0],scripts[scriptCount][1]);
    scriptCount++;
    return Plugin_Handled;
}

public Action:saveScript(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (writeScripts())
        RespondToCommand(client, "[SM] Successfully saved 'cfg/maprewards/scripts.cfg' file.");
    else
        RespondToCommand(client, "[SM] Some kind of error has occurred trying to save 'cfg/maprewards/scripts.cfg' file.");
    return Plugin_Handled;
}

public Action:writeCFG(client, args)
{
    if (!handleClientAccess(client,g_extendedFlag))
        return Plugin_Handled;
    if (args < 1)
    {
        RespondWriteUsage(client);
        return Plugin_Handled;
    }
    decl String:buffer[MAXINPUT];
    new nextArg = 1;
    new bool:lastArg = false;
    new bool:rewards[MAXSPAWNPOINT] = { true, ... };
    new bool:relative = false;
    new bool:force = false;
    new Float:originC[3];
    if ((client > 0) && (IsClientInGame(client)))
        GetClientAbsOrigin(client,originC);
    new bool:err = false;
    for (;nextArg <= args;nextArg++)
    {
        if (nextArg == args)
            lastArg = true;
        GetCmdArg(nextArg,buffer,MAXINPUT);
        if (buffer[0] == '-')
        {
            if (buffer[1] == '-')
            {
                nextArg++;
                break;
            }
            switch (buffer[1])
            {
                case 'R': // Relative
                {
                    relative = true;
                }
                case 'E': // Exclude reward #
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        decl range[2];
                        if (!getRewardRange(buffer,range,client))
                            for (new i = range[0];i <= range[1];i++)
                                rewards[i] = false;
                    }
                }
                case 'o': // Origin
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(nextArg+1,buffer,MAXINPUT);
                        if (strcmp(buffer,"@aim") == 0)
                        {
                            nextArg++;
                            if ((client > 0) && (IsClientInGame(client)))
                                SetTeleportEndPoint(client,originC);
                        }
                        else if ((args-nextArg) < 3)
                            err = true;
                        else
                        {
                            for (new i = 0;i < 3;i++)
                            {
                                GetCmdArg(++nextArg,buffer,17);
                                if (buffer[0] == '~')
                                {
                                    if (strlen(buffer) > 1)
                                    {
                                        StrErase(buffer,0,1);
                                        originC[i] += StringToFloat(buffer);
                                    }
                                }
                                else
                                    originC[i] = StringToFloat(buffer);
                            }
                        }
                    }
                }
                case 'O': // Set origin to anOther player
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        decl String:target_name[MAX_NAME_LENGTH];
                        decl target_list[1];
                        decl target_count;
                        decl bool:tn_is_ml;
                        if ((target_count = ProcessTargetString(buffer,client,target_list,1,0,target_name,MAX_NAME_LENGTH,tn_is_ml)) <= 0)
                        {
                            ReplyToTargetError(client, target_count);
                            return Plugin_Handled;
                        }
                        GetClientAbsOrigin(target_list[0],originC);
                    }
                }
                case 'D': // set origin to another rewarD
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new base = getRewardID(buffer,client);
                        if (base < 0)
                        {
                            RespondToCommand(client, "[SM] Error: Unknown reward '%s'",buffer);
                            return Plugin_Handled;
                        }
                        originC = defSpawnCoords[base];
                    }
                }
                case 'f': // Force, overwrite existing files
                {
                    force = true;
                }
                default:
                {
                    RespondToCommand(client,"[SM] Ignoring unknown switch: %s",buffer);
                }
            }
        }
        else
            break;
        if (err)
            break;
    }
    if ((err) || (nextArg > args))
    {
        RespondWriteUsage(client);
        return Plugin_Handled;
    }
    GetCmdArg(nextArg, buffer, MAXINPUT);
    while ((buffer[0] == '/') || (buffer[0] == '\\'))
        StrErase(buffer,0);
    if (StrFind(buffer,"..") > -1)
    {
        RespondToCommand(client,"[SM] Error: Illegal path.");
        return Plugin_Handled;
    }
    if ((strcmp(buffer,"aliases.cfg") == 0) || (strcmp(buffer,"scripts.cfg") == 0))
    {
        RespondToCommand(client,"[SM] Error: Unable to overwrite system file.");
        return Plugin_Handled;
    }
    Format(buffer,MAXINPUT,"cfg/maprewards/%s",buffer);
    if (DirExists("cfg/maprewards") == false)
        CreateDirectory("cfg/maprewards",511);
    if (FileExists(buffer))
    {
        if (force)
        {
            RespondToCommand(client,"[SM] File exists . . . Overwriting . . .");
            DeleteFile(buffer);
        }
        else
        {
            CRespondToCommand(client,"[SM] File exists . . . Use -f to overwrite.");
            return Plugin_Handled;
        }
    }
    
    new Handle:oFile = OpenFile(buffer,"w");
    new lines = 0;
    for (new i = 0;i < MAXSPAWNPOINT;i++)
    {
        if ((rewards[i]) && (isValidReward(i)))
        {
            decl String:cmdC[MAXCMDLEN];
            buildRewardCmd(i,cmdC,MAXCMDLEN,relative,originC);
            WriteFileLine(oFile,cmdC);
            lines++;
        }
    }
    CloseHandle(oFile);
    if (FileExists(buffer))
        RespondToCommand(client,"[SM] Successfully wrote %d rewards to file '%s'.",lines,buffer);
    else
        RespondToCommand(client,"[SM] Some error has occurred. The file was not saved.");
    return Plugin_Handled;
}

public Action:loadCFG(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (args < 1)
    {
        RespondLoadUsage(client);
        return Plugin_Handled;
    }
    decl String:buffer[MAXINPUT];
    new Float:originC[3];
    if ((client > 0) && (IsClientInGame(client)))
        GetClientAbsOrigin(client,originC);
    new bool:err = false;
    new nextArg = 1;
    new bool:lastArg = false;
    new bool:rewards[MAXSPAWNPOINT] = { true, ... };
    new bool:notRelative = false;
    for (;nextArg <= args;nextArg++)
    {
        if (nextArg == args)
            lastArg = true;
        GetCmdArg(nextArg,buffer,MAXINPUT);
        if (buffer[0] == '-')
        {
            if (buffer[1] == '-')
            {
                nextArg++;
                break;
            }
            switch (buffer[1])
            {
                case 'E': // Except ID
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        decl range[2];
                        if (!getRewardRange(buffer,range,0,false))
                            for (new i = range[0];i <= range[1];i++)
                                rewards[i] = false;
                    }
                }
                case 'o': // Origin
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(nextArg+1,buffer,MAXINPUT);
                        if (strcmp(buffer,"@aim") == 0)
                        {
                            nextArg++;
                            if ((client > 0) && (IsClientInGame(client)))
                                SetTeleportEndPoint(client,originC);
                        }
                        else if ((args-nextArg) < 3)
                            err = true;
                        else
                        {
                            for (new i = 0;i < 3;i++)
                            {
                                GetCmdArg(++nextArg,buffer,17);
                                if (buffer[0] == '~')
                                {
                                    if (strlen(buffer) > 1)
                                    {
                                        StrErase(buffer,0,1);
                                        originC[i] += StringToFloat(buffer);
                                    }
                                }
                                else
                                    originC[i] = StringToFloat(buffer);
                            }
                        }
                    }
                }
                case 'O': // set origin to anOther player
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        decl String:target_name[MAX_NAME_LENGTH];
                        decl target_list[1];
                        decl target_count;
                        decl bool:tn_is_ml;
                        if ((target_count = ProcessTargetString(buffer,client,target_list,1,0,target_name,MAX_NAME_LENGTH,tn_is_ml)) <= 0)
                        {
                            ReplyToTargetError(client, target_count);
                            return Plugin_Handled;
                        }
                        GetClientAbsOrigin(target_list[0],originC);
                    }
                }
                case 'D': // set origin to another rewarD
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new base = getRewardID(buffer,client);
                        if (base < 0)
                        {
                            RespondToCommand(client, "[SM] Error: Unknown reward '%s'",buffer);
                            return Plugin_Handled;
                        }
                        originC = defSpawnCoords[base];
                    }
                }
                case 'N': // Not relative
                {
                    notRelative = true;
                }
                default:
                {
                    RespondToCommand(client,"[SM] Ignoring unknown switch: %s",buffer);
                }
            }
        }
        else
            break;
        if (err)
            break;
    }
    if ((err) || (nextArg > args))
    {
        RespondLoadUsage(client);
        return Plugin_Handled;
    }
    GetCmdArg(nextArg, buffer, MAXINPUT);
    while ((buffer[0] == '/') || (buffer[0] == '\\'))
        StrErase(buffer,0);
    if (StrFind(buffer,"..") > -1)
    {
        RespondToCommand(client,"[SM] Error: Illegal path.");
        return Plugin_Handled;
    }
    if ((strcmp(buffer,"aliases.cfg") == 0) || (strcmp(buffer,"scripts.cfg") == 0))
    {
        RespondToCommand(client,"[SM] Error: Unable to load system file.");
        return Plugin_Handled;
    }
    Format(buffer,MAXINPUT,"cfg/maprewards/%s",buffer);
    if (!FileExists(buffer))
    {
        CRespondToCommand(client,"[SM] Error: File %s does not exist.",buffer);
        return Plugin_Handled;
    }
    cleanUp(CLEAN_MAN_LOAD);
    new Handle:iFile = OpenFile(buffer,"r");
    decl String:fBuf[MAXCMDLEN];
    new lines, skipped, entries, cBufSize = 50;
    decl String:rep[MAXINPUT];
    if (!notRelative)
        Format(rep,MAXINPUT,"sm_mrw_add -o %f %f %f ",originC[0],originC[1],originC[2]);
    new Handle:cBuf = CreateArray(MAXCMDLEN,cBufSize);
    while (ReadFileLine(iFile,fBuf,MAXCMDLEN))
    {
        TrimString(fBuf);
        if (strlen(fBuf) == 0)
            continue;
        if (entries >= cBufSize)
            ResizeArray(cBuf,(cBufSize = 50*(entries/50+1)));
        if (StrFind(fBuf,"sm_mrw_add ") == 0)
        {
            if (rewards[lines++])
            {
                if (!notRelative)
                    ReplaceStringEx(fBuf,MAXCMDLEN,"sm_mrw_add ",rep);
                //PrintToServer("#%d... %s",lines-1,fBuf);
                //ServerCommand(fBuf);
                entries = PushArrayString(cBuf,fBuf)+1;
            }
            else
                skipped++;
        }
        else if (StrFind(fBuf,"sm_mrw_modify -1") == 0)
        {
            if (rewards[lines])
                //ServerCommand(fBuf);
                entries = PushArrayString(cBuf,fBuf)+1;
        }
        else
            //ServerCommand(fBuf);
            entries = PushArrayString(cBuf,fBuf)+1;
    }
    CloseHandle(iFile);
    if (entries > 0)
    {
        new i = 0;
        for (new bSize = 1;i < entries;i++)
        {
            GetArrayString(cBuf,i,fBuf,MAXCMDLEN);
            bSize += strlen(fBuf)+2;
            if (bSize < MAXCMDBUF)
                ServerCommand(fBuf);
            else
            {
                Format(fBuf,MAXCMDLEN,"%d,%d",i,entries);
                SetArrayString(cBuf,0,fBuf);
                CreateTimer(0.0,sendCommandBuffer,cBuf,TIMER_REPEAT);
                break;
            }
        }
        if (i >= entries)
        {
            ResizeArray(cBuf,0);
            CloseHandle(cBuf);
        }
    }
    if (lines > 0)
        CRespondToCommand(client,"[SM] Successfully spawned %d rewards.",lines-skipped);
    else
        CRespondToCommand(client,"[SM] Warning: No rewards found in file %s. CFG was executed.",buffer);
    return Plugin_Handled;
}

public Action:killEntity(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (args < 1)
    {
        RespondToCommand(client, "[SM] Usage: sm_mrw_kill <#entity_id>");
        return Plugin_Handled;
    }
    decl String:buffer[16];
    GetCmdArg(1,buffer,16);
    new entID = StringToInt(buffer);
    if (entID < 1)
    {
        RespondToCommand(client,"[SM] Error: Cannot kill entity '%d'.",entID);
        return Plugin_Handled;
    }
    for (new i = 0; i < MAXSPAWNPOINT; i++)
    {
        if (spawnEnts[i] == entID)
        {
            RespondToCommand(client,"[SM] Error: Entity is still loaded as ID #%d. Use sm_mrw_remove or sm_mrw_release the entity first.",i);
            return Plugin_Handled;
        }
    }
    if (IsValidEntity(entID))
        AcceptEntityInput(entID, "Kill");
    else
        RespondToCommand(client,"[SM] Error: Invalid entity.");
    return Plugin_Handled;
}

public Action:addSpawnPoint(client, args)
{
    if (!handleClientAccess(client,g_createFlag))
        return Plugin_Handled;
    if (args < 1)
    {
        CRespondToCommand(client, "[SM] Usage: sm_mrw_add [OPTIONS ...] [command ...]");
        CRespondToCommand(client, "[SM]   Use sm_mrw_add -h to see the full help. Note: It's long, may want to run it from console.");
        return Plugin_Handled;
    }
    new spawnPoints = newEnt();
    if (spawnPoints >= MAXSPAWNPOINT)
    {
        CRespondToCommand(client, "[SM] No more room for rewards! :( Use sm_mrw_removeall to reset.");
        return Plugin_Handled;
    }
    
    entType[spawnPoints] = "prop_physics_override";
    IntToString(spawnPoints,entName[spawnPoints],32);
    
    decl String:buffer[MAXINPUT];
    new nextArg = 1;
    new bool:lastArg = false;
    new bool:err = false;
    new bool:release = false;
    new whichCommand = 0;
    
    if ((client > 0) && (IsClientInGame(client)))
        GetClientAbsOrigin(client,defSpawnCoords[spawnPoints]);
    new String:strCoords[3][16];
    
    for (;nextArg <= args;nextArg++)
    {
        if (nextArg == args)
            lastArg = true;
        GetCmdArg(nextArg,buffer,MAXINPUT);
        if (buffer[0] == '-')
        {
            if (buffer[1] == '-')
            {
                nextArg++;
                break;
            }
            switch (buffer[1])
            {
                //Unused:                   aBEfFgGiIjJkMqQvVwWxyYzZ
                //Used by another command:    Ef
                case 'u': // evalUate aliases now
                {
                    if (unEvaluate[spawnPoints])
                        evaluateRewardAliases(spawnPoints);
                    unEvaluate[spawnPoints] = false;
                }
                case 'U': // don't evalUate aliases until spawn time
                {
                    unEvaluate[spawnPoints] = true;
                }
                case 'P': // Shortcut for -d pickup
                {
                    //respawnMethod[spawnPoints] &= ~HOOK_STATIC;
                    //respawnMethod[spawnPoints] &= ~HOOK_CONSTANT;
                    respawnMethod[spawnPoints] |= HOOK_TOUCH;
                }
                case 'S': // Shortcut for -d static
                {
                    respawnMethod[spawnPoints] &= ~HOOK_CONSTANT;
                    respawnMethod[spawnPoints] |= HOOK_STATIC;//|HOOK_TOUCH;
                }
                case 'C': // Shortcut for -d constant
                {
                    respawnMethod[spawnPoints] &= ~HOOK_STATIC;
                    respawnMethod[spawnPoints] |= HOOK_CONSTANT;//|HOOK_TOUCH;
                }
                case 'H': // Shortcut for -d hurt
                {
                    respawnMethod[spawnPoints] |= HOOK_HURT;
                }
                case 'K': // Shortcut for -d kill
                {
                    respawnMethod[spawnPoints] |= HOOK_HURT|HOOK_KILL;
                }
                case 'N': // Shortcut for -d notouch
                {
                    respawnMethod[spawnPoints] &= ~HOOK_TOUCH;
                }
                case 'A': // heAlth
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        if (StrIsDigit(buffer) == -1)
                            err = true;
                        else
                            entHealth[spawnPoints] = StringToFloat(buffer);
                    }
                }
                case 'b': // Base
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new base = getRewardID(buffer,client,spawnPoints);
                        if ((base == spawnPoints) || (!isValidReward(base)))
                        {
                            resetReward(spawnPoints);
                            RespondToCommand(client, "[SM] Error: Unknown reward '%s'",buffer);
                            return Plugin_Handled;
                        }
                        unEvaluate[spawnPoints] = unEvaluate[base];
                        defSpawnCoords[spawnPoints] = defSpawnCoords[base];
                        defSpawnAngles[spawnPoints] = defSpawnAngles[base];
                        respawnMethod[spawnPoints] = respawnMethod[base];
                        model[spawnPoints] = model[base];
                        entType[spawnPoints] = entType[base];
                        rCommand[spawnPoints][0] = rCommand[base][0];
                        rCommand[spawnPoints][1] = rCommand[base][1];
                        script[spawnPoints][0] = script[base][0];
                        script[spawnPoints][1] = script[base][1]
                        respawnTime[spawnPoints] = respawnTime[base];
                        entSpin[spawnPoints] = entSpin[base];
                        entSpinInt[spawnPoints] = entSpinInt[base];
                        entOverlay[spawnPoints] = entOverlay[base];
                    }
                }
                case 'c': // Coords
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(nextArg+1,buffer,MAXINPUT);
                        if (strcmp(buffer,"@aim") == 0)
                        {
                            nextArg++;
                            if ((client > 0) && (IsClientInGame(client)))
                                SetTeleportEndPoint(client,defSpawnCoords[spawnPoints]);
                        }
                        else if ((args-nextArg) < 3)
                            err = true;
                        else
                        {
                            for (new i = 0;i < 3;i++)
                                GetCmdArg(++nextArg,strCoords[i],16);
                        }
                    }
                }
                case 'd': // respawn methoD
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        if (strcmp(buffer,"pickup") == 0)
                            respawnMethod[spawnPoints] = HOOK_TOUCH;
                        else if (strcmp(buffer,"static") == 0)
                            respawnMethod[spawnPoints] = HOOK_STATIC|HOOK_TOUCH;
                        else if ((strcmp(buffer,"nohook") == 0) || (strcmp(buffer,"nopickup") == 0))
                            respawnMethod[spawnPoints] = HOOK_NOHOOK;
                        else if (strcmp(buffer,"constant") == 0)
                            respawnMethod[spawnPoints] = HOOK_CONSTANT|HOOK_TOUCH;
                        else if (strcmp(buffer,"hurt") == 0)
                            respawnMethod[spawnPoints] |= HOOK_HURT;
                        else if (strcmp(buffer,"kill") == 0)
                            respawnMethod[spawnPoints] = HOOK_HURT|HOOK_KILL;
                        else if (strcmp(buffer,"notouch") == 0)
                            respawnMethod[spawnPoints] &= ~HOOK_TOUCH;
                        else
                            respawnMethod[spawnPoints] = StringToInt(buffer);
                    }
                }
                case 'e': // Entity type
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        if (!unEvaluate[spawnPoints])
                        {
                            decl bool:resolve[3];
                            resolve[0] = ((strcmp(model[spawnPoints],"null") != 0) && (strcmp(model[spawnPoints],"0") != 0));
                            resolve[1] = ((strcmp(script[spawnPoints][0],"null") != 0) && (strcmp(script[spawnPoints][0],"0") != 0));
                            resolve[2] = ((strcmp(script[spawnPoints][1],"null") != 0) && (strcmp(script[spawnPoints][1],"0") != 0));
                            for (new i = 0;i < aliasCount;i++)
                            {
                                if (strcmp(buffer,aliases[i][0]) == 0)
                                {
                                    strcopy(buffer,MAXINPUT,aliases[i][2]);
                                    if ((resolve[0]) && (strlen(aliases[i][1]) > 0))
                                        strcopy(model[spawnPoints],MAXINPUT,aliases[i][1]);
                                    if ((resolve[1]) && (strlen(aliases[i][3]) > 0))
                                        strcopy(script[spawnPoints][0],MAXINPUT,aliases[i][3]);
                                    if ((resolve[2]) && (strlen(aliases[i][4]) > 0))
                                        strcopy(script[spawnPoints][1],MAXINPUT,aliases[i][4]);
                                    break;
                                }
                            }
                        }
                        strcopy(entType[spawnPoints],64,buffer);
                    }
                }
                case 'h': // Help
                {
                    resetReward(spawnPoints);
                    RespondAddUsage(client);
                    return Plugin_Handled;
                }
                case 'l': // color overLay, r g b a
                {
                    if ((args-nextArg) < 4)
                        err = true;
                    else
                    {
                        decl colors[4];
                        for (new i = 0;i < 4;i++)
                        {
                            GetCmdArg(++nextArg,buffer,4);
                            colors[i] = StringToInt(buffer);
                        }
                        entOverlay[spawnPoints] = (colors[0] | (colors[1]<<8) | (colors[2]<<16) | (colors[3]<<24));
                    }
                }
                case 'L': // color overLay, integer color bit
                {
                    if (lastArg)
                        err = true;
                    GetCmdArg(++nextArg,buffer,16);
                    entOverlay[spawnPoints] = StringToInt(buffer);
                }
                case 'm': // Model
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        if (!unEvaluate[spawnPoints])
                        {
                            decl bool:resolve[3];
                            resolve[0] = ((strcmp(entType[spawnPoints],"null") != 0) && (strcmp(entType[spawnPoints],"0") != 0));
                            resolve[1] = ((strcmp(script[spawnPoints][0],"null") != 0) && (strcmp(script[spawnPoints][0],"0") != 0));
                            resolve[2] = ((strcmp(script[spawnPoints][1],"null") != 0) && (strcmp(script[spawnPoints][1],"0") != 0));
                            for (new i = 0;i < aliasCount;i++)
                            {
                                if (strcmp(buffer,aliases[i][0]) == 0)
                                {
                                    strcopy(buffer,MAXINPUT,aliases[i][1]);
                                    if ((resolve[0]) && (strlen(aliases[i][2]) > 0))
                                        strcopy(entType[spawnPoints],MAXINPUT,aliases[i][2]);
                                    if ((resolve[1]) && (strlen(aliases[i][2]) > 0))
                                        strcopy(script[spawnPoints][0],MAXINPUT,aliases[i][3]);
                                    if ((resolve[2]) && (strlen(aliases[i][4]) > 0))
                                        strcopy(script[spawnPoints][1],MAXINPUT,aliases[i][4]);
                                    break;
                                }
                            }
                        }
                        strcopy(model[spawnPoints],MAXINPUT,buffer);
                    }
                }
                case 'n': // Name
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,32);
                        if ((StrIsDigit(buffer) > -1) || (StrFind(buffer,"..") > -1) || (StrFindFirstOf(buffer,ILLEGAL_NAME,0) > -1))
                        {
                            CRespondToCommand(client, "[SM] Error: Reward names may not begin with a number, contain '..', or any of the following characters: '%s'.",ILLEGAL_NAME);
                            resetReward(spawnPoints);
                            return Plugin_Handled;
                        }
                        new dupe = getRewardID(buffer);
                        if (dupe > -1)
                        {
                            RespondToCommand(client, "[SM] Error: Reward #%d already exists with the same name!",dupe);
                            resetReward(spawnPoints);
                            return Plugin_Handled;
                        }
                        strcopy(entName[spawnPoints],32,buffer);
                    }
                }
                case 'o': // Origin coords
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(nextArg+1,buffer,MAXINPUT);
                        if (strcmp(buffer,"@aim") == 0)
                        {
                            nextArg++;
                            if ((client > 0) && (IsClientInGame(client)))
                                SetTeleportEndPoint(client,defSpawnCoords[spawnPoints]);
                        }
                        else if ((args-nextArg) < 3)
                            err = true;
                        else
                        {
                            for (new i = 0;i < 3;i++)
                            {
                                GetCmdArg(++nextArg,buffer,17);
                                if (buffer[0] == '~')
                                {
                                    if (strlen(buffer) > 1)
                                    {
                                        StrErase(buffer,0,1);
                                        defSpawnCoords[spawnPoints][i] += StringToFloat(buffer);
                                    }
                                }
                                else
                                    defSpawnCoords[spawnPoints][i] = StringToFloat(buffer);
                            }
                        }
                    }
                }
                case 'O': // set origin to anOther player
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        decl String:target_name[MAX_NAME_LENGTH];
                        decl target_list[1];
                        decl target_count;
                        decl bool:tn_is_ml;
                        if ((target_count = ProcessTargetString(buffer,client,target_list,1,0,target_name,MAX_NAME_LENGTH,tn_is_ml)) <= 0)
                        {
                            resetReward(spawnPoints);
                            ReplyToTargetError(client, target_count);
                            return Plugin_Handled;
                        }
                        GetClientAbsOrigin(target_list[0],defSpawnCoords[spawnPoints]);
                    }
                }
                case 'D': // set origin to another rewarD
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new base = getRewardID(buffer);
                        if (!isValidReward(base))
                        {
                            resetReward(spawnPoints);
                            RespondToCommand(client, "[SM] Error: Unknown reward '%s'",buffer);
                            return Plugin_Handled;
                        }
                        defSpawnCoords[spawnPoints] = defSpawnCoords[base];
                    }
                }
                case 'p': // entProp values
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        if (!unEvaluate[spawnPoints])
                        {
                            for (new i = 0;i < scriptCount;i++)
                            {
                                if (strcmp(buffer,scripts[i][0]) == 0)
                                {
                                    strcopy(buffer,MAXINPUT,scripts[i][1]);
                                    break;
                                }
                            }
                        }
                        strcopy(script[spawnPoints][1],MAXINPUT,buffer);
                    }
                }
                case 'r': // Rotation angles
                {
                    if ((args-nextArg) < 3)
                        err = true;
                    else
                    {
                        for (new i = 0;i < 3;i++)
                        {
                            GetCmdArg(++nextArg,buffer,MAXINPUT);
                            defSpawnAngles[spawnPoints][i] = StringToFloat(buffer);
                        }
                    }
                }
                case 's': // Script
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        if (!unEvaluate[spawnPoints])
                        {
                            for (new i = 0;i < scriptCount;i++)
                            {
                                if (strcmp(buffer,scripts[i][0]) == 0)
                                {
                                    strcopy(buffer,MAXINPUT,scripts[i][1]);
                                    break;
                                }
                            }
                        }
                        strcopy(script[spawnPoints][0],MAXINPUT,buffer);
                    }
                }
                case 't': // respawn Time
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        respawnTime[spawnPoints] = StringToFloat(buffer);
                    }
                }
                case 'R': // Release after spawning
                {
                    release = true;
                }
                case 'T': // make the reward Turn every interval (Spin)
                {
                    if ((args-nextArg) < 4)
                        err = true;
                    else
                    {
                        for (new i = 0;i < 3;i++)
                        {
                            GetCmdArg(++nextArg,buffer,MAXINPUT);
                            entSpin[spawnPoints][i] = StringToFloat(buffer);
                        }
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        entSpinInt[spawnPoints] = StringToFloat(buffer);
                    }
                }
                case 'X': // make command set the kill command
                {
                    whichCommand = 1;
                }
                default:
                {
                    CRespondToCommand(client,"[SM] Ignoring unknown switch: %s",buffer);
                }
            }
        }
        else
            break;
        if (err)
            break;
    }
    if (!unEvaluate[spawnPoints])
    {
        if ((strcmp(model[spawnPoints],"null") == 0) || (strcmp(model[spawnPoints],"0") == 0))
            model[spawnPoints] = "";
        if ((strcmp(entType[spawnPoints],"null") == 0) || (strcmp(entType[spawnPoints],"0") == 0))
            entType[spawnPoints] = "prop_physics_override";
        if ((strcmp(script[spawnPoints][0],"null") == 0) || (strcmp(script[spawnPoints][0],"0") == 0))
            script[spawnPoints][0] = "";
        if ((strcmp(script[spawnPoints][1],"null") == 0) || (strcmp(script[spawnPoints][1],"0") == 0))
            script[spawnPoints][1] = "";
    }
    if ((err) || ((strcmp(entType[spawnPoints],"prop_physics_override") == 0) && (strlen(model[spawnPoints]) < 1)))
    {
        resetReward(spawnPoints);
        CRespondToCommand(client, "[SM] Usage: sm_mrw_add [OPTIONS ...] [command ...]");
        CRespondToCommand(client, "[SM]   Use sm_mrw_add -h to see the full help. Note: It's long, may want to run it from console.");
        return Plugin_Handled;
    }
    if (strlen(strCoords[0]) > 0)
    {
        for (new i = 0;i < 3;i++)
        {
            if (strCoords[i][0] == '~')
            {
                if (strlen(strCoords[i]) > 1)
                {
                    StrErase(strCoords[i],0,1);
                    defSpawnCoords[spawnPoints][i] += StringToFloat(strCoords[i]);
                }
            }
            else
                defSpawnCoords[spawnPoints][i] = StringToFloat(strCoords[i]);
        }
    }
    if (nextArg <= args)
    {
        GetCmdArg(nextArg++,rCommand[spawnPoints][whichCommand],MAXCMDLEN);
        decl String:cBuf[MAXCMDLEN];
        for (;nextArg <= args;nextArg++)
        {
            GetCmdArg(nextArg,cBuf,MAXCMDLEN);
            Format(rCommand[spawnPoints][whichCommand],MAXCMDLEN,"%s %s",rCommand[spawnPoints][whichCommand],cBuf);
        }
    }
    if (g_enable)
    {
        spawnReward(spawnPoints);
        if (release)
        {
            CRespondToCommand(client, "[SM] Added reward and released entity #%d",spawnEnts[spawnPoints]);
            resetReward(spawnPoints);
        }
        else
            CRespondToCommand(client, "[SM] Added reward spawn point #%d",spawnPoints);
    }
    else
        CRespondToCommand(client, "[SM] Added reward spawn point #%d",spawnPoints);
    newestReward = spawnPoints;
    if (client != 0)
        autoSave(SAVE_EDIT,true);
    return Plugin_Handled;
}

public Action:modifySpawnPoint(client, args)
{
    if (!handleClientAccess(client,g_createFlag))
        return Plugin_Handled;
    if (args < 2)
    {
        RespondModifyUsage(client);
        return Plugin_Handled;
    }
    decl String:buffer[MAXINPUT];
    GetCmdArg(1,buffer,MAXINPUT);
    new bool:list[MAXSPAWNPOINT];
    decl count;
    if (!(count = getRewardList(buffer,list,client)))
    {
        RespondToCommand(client, "[SM] Error: Found no rewards matching '%s'",buffer);
        return Plugin_Handled;
    }
    for (new r = 0;r < MAXSPAWNPOINT;r++)
        if (list[r])
            killReward(r);
    
    new nextArg = 2;
    new bool:lastArg = false;
    new bool:err = false;
    new bool:release = false;
    new whichCommand = 0;
    new bool:single = (count == 1);
    decl rewardID;
    for (new i = 0;i < MAXSPAWNPOINT;i++)
    {
        if (list[i])
        {
            rewardID = i;
            break;
        }
    }
    
    new String:newEntType[64];
    new String:newModel[MAXINPUT];
    new lastAlias = 0;
    new bool:skipScript;
    new bool:skipProp;
    
    new String:strCoords[3][16];
    
    for (;nextArg <= args;nextArg++)
    {
        if (nextArg == args)
            lastArg = true;
        GetCmdArg(nextArg,buffer,MAXINPUT);
        if (buffer[0] == '-')
        {
            if (buffer[1] == '-')
            {
                nextArg++;
                break;
            }
            switch (buffer[1])
            {
                case 'u': // evalUate aliases now
                {
                    new bool:skip[4];
                    for (new r = 0;r < MAXSPAWNPOINT;r++)
                    {
                        if (list[r])
                        {
                            if (unEvaluate[r])
                            {
                                skip[0] = (strlen(newModel) != 0);
                                skip[1] = (strlen(newEntType) != 0);
                                skip[2] = skip[3] = false;
                                evaluateRewardAliases(r,skip);
                            }
                            unEvaluate[r] = false;
                        }
                    }
                }
                case 'U': // don't evalUate aliases until spawn time
                {
                    for (new r = 0;r < MAXSPAWNPOINT;r++)
                        if (list[r])
                            unEvaluate[r] = true;
                }
                case 'P': // Shortcut for -d pickup
                {
                    //respawnMethod[spawnPoints] &= ~HOOK_STATIC;
                    //respawnMethod[spawnPoints] &= ~HOOK_CONSTANT;
                    for (new r = 0;r < MAXSPAWNPOINT;r++)
                        if (list[r])
                            respawnMethod[r] |= HOOK_TOUCH;
                }
                case 'S': // Shortcut for -d static
                {
                    for (new r = 0;r < MAXSPAWNPOINT;r++)
                    {
                        if (list[r])
                        {
                            respawnMethod[r] &= ~HOOK_CONSTANT;
                            respawnMethod[r] |= HOOK_STATIC;
                        }
                    }
                }
                case 'C': // Shortcut for -d constant
                {
                    for (new r = 0;r < MAXSPAWNPOINT;r++)
                    {
                        if (list[r])
                        {
                            respawnMethod[r] &= ~HOOK_STATIC;
                            respawnMethod[r] |= HOOK_CONSTANT;
                        }
                    }
                }
                case 'H': // Shortcut for -d hurt
                {
                    for (new r = 0;r < MAXSPAWNPOINT;r++)
                        if (list[r])
                            respawnMethod[r] |= HOOK_HURT;
                }
                case 'K': // Shortcut for -d kill
                {
                    for (new r = 0;r < MAXSPAWNPOINT;r++)
                        if (list[r])
                            respawnMethod[r] |= HOOK_HURT|HOOK_KILL;
                }
                case 'N': // Shortcut for -d notouch
                {
                    for (new r = 0;r < MAXSPAWNPOINT;r++)
                        if (list[r])
                            respawnMethod[r] &= ~HOOK_TOUCH;
                }
                case 'A': // heAlth
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new Float:h = StringToFloat(buffer);
                        if (StrIsDigit(buffer) == -1)
                            err = true;
                        else for (new r = 0;r < MAXSPAWNPOINT;r++)
                            if (list[r])
                                entHealth[r] = h;
                    }
                }
                case 'b':
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new base = getRewardID(buffer,client);
                        if (!isValidReward(base))
                        {
                            //resetReward(spawnPoints);// not sure why this was here... I don't think we need to completely remove the reward because of this
                            RespondToCommand(client, "[SM] Error: Unknown reward '%s'",buffer);
                            return Plugin_Handled;
                        }
                        for (new spawnPoints = 0;spawnPoints < MAXSPAWNPOINT;spawnPoints++)
                        {
                            if (list[spawnPoints])
                            {
                                defSpawnCoords[spawnPoints] = defSpawnCoords[base];
                                defSpawnAngles[spawnPoints] = defSpawnAngles[base];
                                respawnMethod[spawnPoints] = respawnMethod[base];
                                model[spawnPoints] = model[base];
                                entType[spawnPoints] = entType[base];
                                rCommand[spawnPoints][0] = rCommand[base][0];
                                rCommand[spawnPoints][1] = rCommand[base][1];
                                script[spawnPoints][0] = script[base][0];
                                script[spawnPoints][1] = script[base][1]
                                respawnTime[spawnPoints] = respawnTime[base];
                                entSpin[spawnPoints] = entSpin[base];
                                entSpinInt[spawnPoints] = entSpinInt[base];
                                entOverlay[spawnPoints] = entOverlay[base];
                            }
                        }
                    }
                }
                case 'c': // Coords
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(nextArg+1,buffer,MAXINPUT);
                        if (strcmp(buffer,"@aim") == 0)
                        {
                            nextArg++;
                            if ((client > 0) && (IsClientInGame(client)))
                            {
                                new Float:c[3];
                                SetTeleportEndPoint(client,c);
                                for (new r = 0;r < MAXSPAWNPOINT;r++)
                                    if (list[r])
                                        defSpawnCoords[r] = c;
                            }
                        }
                        else if ((args-nextArg) < 3)
                            err = true;
                        else for (new i = 0;i < 3;i++)
                            GetCmdArg(++nextArg,strCoords[i],16);
                    }
                }
                case 'd': // respawn methoD
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new bits = HOOK_NOHOOK;
                        if (strcmp(buffer,"pickup") == 0)
                            bits = HOOK_TOUCH;
                        else if (strcmp(buffer,"static") == 0)
                            bits = HOOK_STATIC|HOOK_TOUCH;
                        else if ((strcmp(buffer,"nohook") == 0) || (strcmp(buffer,"nopickup") == 0))
                            bits = HOOK_NOHOOK;
                        else if (strcmp(buffer,"constant") == 0)
                            bits = HOOK_CONSTANT|HOOK_TOUCH;
                        else if (strcmp(buffer,"hurt") == 0)
                            bits |= HOOK_HURT;
                        else if (strcmp(buffer,"kill") == 0)
                            bits = HOOK_HURT|HOOK_KILL;
                        else if (strcmp(buffer,"notouch") == 0)
                            bits = -1;
                        else
                            bits = StringToInt(buffer);
                        for (new spawnPoints = 0;spawnPoints < MAXSPAWNPOINT;spawnPoints++)
                        {
                            if (list[spawnPoints])
                            {
                                if (bits == -1)
                                    respawnMethod[spawnPoints] &= ~HOOK_TOUCH;
                                else
                                    respawnMethod[spawnPoints] = bits;
                            }
                        }
                    }
                }
                case 'e': // Entity type
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,newEntType,64);
                        lastAlias = 1;
                        //skipScript = skipProp = false;
                    }
                }
                case 'l': // color overLay, r g b a
                {
                    if ((args-nextArg) < 4)
                        err = true;
                    else
                    {
                        decl colors[5];
                        for (new i = 0;i < 4;i++)
                        {
                            GetCmdArg(++nextArg,buffer,4);
                            colors[i] = StringToInt(buffer);
                        }
                        colors[4] = (colors[0] | (colors[1]<<8) | (colors[2]<<16) | (colors[3]<<24));
                        for (new spawnPoints = 0;spawnPoints < MAXSPAWNPOINT;spawnPoints++)
                            if (list[spawnPoints])
                                entOverlay[spawnPoints] = colors[4];
                    }
                }
                case 'L': // color overLay, integer color bit
                {
                    if (lastArg)
                        err = true;
                    GetCmdArg(++nextArg,buffer,16);
                    new c = StringToInt(buffer);
                    for (new spawnPoints = 0;spawnPoints < MAXSPAWNPOINT;spawnPoints++)
                        if (list[spawnPoints])
                            entOverlay[spawnPoints] = c;
                }
                case 'm': // Model
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,newModel,MAXINPUT);
                        lastAlias = 2;
                        //skipScript = skipProp = false;
                    }
                }
                case 'n': // Name
                {
                    if (lastArg)
                        err = true;
                    else if (single)
                    {
                        new spawnPoints = rewardID;
                        GetCmdArg(++nextArg,buffer,32);
                        if ((StrIsDigit(buffer) > -1) || (StrFind(buffer,"..") > -1) || (StrFindFirstOf(buffer,ILLEGAL_NAME,0) > -1))
                            CRespondToCommand(client, "[SM] Error: Reward names may not begin with a number, contain '..', or any of the following characters: '%s'. Name not changed from '%s'.",ILLEGAL_NAME,entName[spawnPoints]);
                        else
                        {
                            new dupe = getRewardID(buffer);
                            if (dupe > -1)
                                RespondToCommand(client, "[SM] Error: Reward #%d already exists with the same name! Name not changed from '%s'.",dupe,entName[spawnPoints]);
                            else
                                strcopy(entName[spawnPoints],32,buffer);
                        }
                    }
                    else
                    {
                        nextArg++;
                        CRespondToCommand(client,"Error: Skipping -%c switch. Unable to apply to multiple targets at once.",buffer[1]);
                    }
                }
                case 'o': // Origin coords
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(nextArg+1,buffer,MAXINPUT);
                        if (strcmp(buffer,"@aim") == 0)
                        {
                            nextArg++;
                            if ((client > 0) && (IsClientInGame(client)))
                            {
                                new Float:c[3];
                                SetTeleportEndPoint(client,c);
                                for (new r = 0;r < MAXSPAWNPOINT;r++)
                                    if (list[r])
                                        defSpawnCoords[r] = c;
                            }
                        }
                        else if ((args-nextArg) < 3)
                            err = true;
                        else
                        {
                            new Float:c[3];
                            new bool:rel[3];
                            for (new i = 0;i < 3;i++)
                            {
                                GetCmdArg(++nextArg,buffer,17);
                                if (buffer[0] == '~')
                                {
                                    rel[i] = true;
                                    if (strlen(buffer) > 1)
                                    {
                                        StrErase(buffer,0,1);
                                        c[i] = StringToFloat(buffer);
                                    }
                                }
                                else
                                    c[i] = StringToFloat(buffer);
                            }
                            for (new r = 0;r < MAXSPAWNPOINT;r++)
                            {
                                if (list[r])
                                {
                                    for (new i = 0;i < 3;i++)
                                    {
                                        if (rel[i])
                                            defSpawnCoords[r][i] += c[i];
                                        else
                                            defSpawnCoords[r][i] = c[i];
                                    }
                                }
                            }
                        }
                    }
                }
                case 'O': // set origin to anOther player
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        decl String:target_name[MAX_NAME_LENGTH];
                        decl target_list[1];
                        decl bool:tn_is_ml;
                        if (ProcessTargetString(buffer,client,target_list,1,0,target_name,MAX_NAME_LENGTH,tn_is_ml) <= 0)
                            RespondToCommand(client, "[SM] Error: No target found, not changing origin.");
                        else
                        {
                            new Float:c[3];
                            GetClientAbsOrigin(target_list[0],c);
                            for (new r = 0;r < MAXSPAWNPOINT;r++)
                                if (list[r])
                                    defSpawnCoords[r] = c;
                        }
                    }
                }
                case 'D': // set origin to another rewarD
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new base = getRewardID(buffer,client);
                        if (!isValidReward(base))
                            RespondToCommand(client, "[SM] Error: Unknown reward '%s', not changing origin.",buffer);
                        else for (new r = 0;r < MAXSPAWNPOINT;r++)
                            if (list[r])
                                defSpawnCoords[r] = defSpawnCoords[base];
                    }
                }
                case 'p': // entProp values
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new bool:found = false;
                        for (new r = 0;r < MAXSPAWNPOINT;r++)
                        {
                            if (list[r])
                            {
                                if (!unEvaluate[r])
                                {
                                    for (new i = 0;i < scriptCount;i++)
                                    {
                                        if (strcmp(buffer,scripts[i][0]) == 0)
                                        {
                                            strcopy(script[r][1],MAXINPUT,scripts[i][1]);
                                            found = true;
                                            break;
                                        }
                                    }
                                }
                                if (!found)
                                    strcopy(script[r][1],MAXINPUT,buffer);
                            }
                        }
                        if (lastAlias)
                            skipProp = true;
                    }
                }
                case 'r': // Rotation angles
                {
                    if ((args-nextArg) < 3)
                        err = true;
                    else
                    {
                        new Float:c[3];
                        new bool:rel[3];
                        for (new i = 0;i < 3;i++)
                        {
                            GetCmdArg(++nextArg,buffer,MAXINPUT);
                            if (buffer[0] == '~')
                            {
                                rel[i] = true;
                                if (strlen(buffer) > 1)
                                {
                                    StrErase(buffer,0,1);
                                    c[i] = StringToFloat(buffer);
                                }
                            }
                            else
                                c[i] = StringToFloat(buffer);
                        }
                        for (new r = 0;r < MAXSPAWNPOINT;r++)
                        {
                            if (list[r])
                            {
                                for (new i = 0;i < 3;i++)
                                {
                                    if (rel[i])
                                        defSpawnAngles[r][i] += c[i];
                                    else
                                        defSpawnAngles[r][i] = c[i];
                                }
                            }
                        }
                    }
                }
                case 's': // Script
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new bool:found = false;
                        for (new r = 0;r < MAXSPAWNPOINT;r++)
                        {
                            if (list[r])
                            {
                                if (!unEvaluate[r])
                                {
                                    for (new i = 0;i < scriptCount;i++)
                                    {
                                        if (strcmp(buffer,scripts[i][0]) == 0)
                                        {
                                            strcopy(script[r][0],MAXINPUT,scripts[i][1]);
                                            found = true;
                                            break;
                                        }
                                    }
                                }
                                if (!found)
                                    strcopy(script[r][0],MAXINPUT,buffer);
                            }
                        }
                        if (lastAlias)
                            skipScript = true;
                    }
                }
                case 't': // respawn Time
                {
                    if (lastArg)
                        err = true;
                    else
                    {
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        new Float:t = StringToFloat(buffer);
                        for (new r = 0;r < MAXSPAWNPOINT;r++)
                            if (list[r])
                                respawnTime[r] = t;
                    }
                }
                case 'R': // Release after spawning
                {
                    release = true;
                }
                case 'T': // make the reward Turn every interval (spin)
                {
                    if ((args-nextArg) < 4)
                        err = true;
                    else
                    {
                        new Float:s[3], Float:si;
                        for (new i = 0;i < 3;i++)
                        {
                            GetCmdArg(++nextArg,buffer,MAXINPUT);
                            s[i] = StringToFloat(buffer);
                        }
                        GetCmdArg(++nextArg,buffer,MAXINPUT);
                        si = StringToFloat(buffer);
                        for (new r = 0;r < MAXSPAWNPOINT;r++)
                        {
                            if (list[r])
                            {
                                entSpin[r] = s;
                                entSpinInt[r] = si;
                            }
                        }
                    }
                }
                case 'X': // make command set the kill command
                {
                    whichCommand = 1;
                }
                default:
                {
                    CRespondToCommand(client,"[SM] Ignoring unknown switch: %s",buffer);
                }
            }
        }
        else
            break;
        if (err)
            break;
    }
    if (err)
    {
        if (single)
        {
            CRespondToCommand(client, "[SM] Error modifying reward #%d. Some data may have been changed, some was not. This likely resulted in undefined behaviour.",rewardID);
            CRespondToCommand(client, "[SM]  You will need to manually run sm_mrw_respawn %d before the reward will be active again.",rewardID);
        }
        else
        {
            CRespondToCommand(client, "[SM] Error modifying rewards. Some data may have been changed, some was not. This likely resulted in undefined behaviour.");
            CRespondToCommand(client, "[SM]  You will need to manually sm_mrw_respawn the rewards before they will be active again.");
        }
        return Plugin_Handled;
    }
    new Float:c[3];
    new bool:rel[3];
    decl String:comm[MAXCMDLEN];
    decl String:cBuf[MAXCMDLEN];
    new bool:updateCoords;
    new bool:updateCommand;
    new bool:updateModel;
    new bool:updateEntType;
    new modelAlias = -1;
    new entAlias = -1;
    new String:testModel[MAXINPUT];
    new String:testEntType[64];
    if (strlen(newModel) > 0)
    {
        for (new i = 0;i < aliasCount;i++)
        {
            if (strcmp(newModel,aliases[i][0]) == 0)
            {
                modelAlias = i;
                break;
            }
        }
        updateModel = true;
    }
    if (strlen(newEntType) > 0)
    {
        for (new i = 0;i < aliasCount;i++)
        {
            if (strcmp(newEntType,aliases[i][0]) == 0)
            {
                entAlias = i;
                break;
            }
        }
        updateEntType = true;
    }
    if (strlen(strCoords[0]) > 0)
    {
        for (new i = 0;i < 3;i++)
        {
            if (strCoords[i][0] == '~')
            {
                rel[i] = true;
                if (strlen(strCoords[i]) > 1)
                {
                    StrErase(strCoords[i],0,1);
                    c[i] = StringToFloat(strCoords[i]);
                }
            }
            else
                c[i] = StringToFloat(strCoords[i]);
        }
        updateCoords = true;
    }
    if (nextArg <= args)
    {
        GetCmdArg(nextArg++,comm,MAXCMDLEN);
        for (;nextArg <= args;nextArg++)
        {
            GetCmdArg(nextArg,cBuf,MAXCMDLEN);
            Format(comm,MAXCMDLEN,"%s %s",comm,cBuf);
        }
        updateCommand = true;
    }
    for (new r = 0;r < MAXSPAWNPOINT;r++)
    {
        if (list[r])
        {
            if (updateCoords)
            {
                for (new i = 0;i < 3;i++)
                {
                    if (rel[i])
                        defSpawnCoords[r][i] += c[i];
                    else
                        defSpawnCoords[r][i] = c[i];
                }
            }
            if (updateCommand)
                strcopy(rCommand[r][whichCommand],MAXCMDLEN,comm);
            else if (whichCommand)
                strcopy(rCommand[r][1],MAXCMDLEN,"");
            if ((updateModel) || (updateEntType))
            {
                if (unEvaluate[r])
                {
                    if (updateEntType)
                        strcopy(entType[r],64,newEntType);
                    if (updateModel)
                        strcopy(model[r],MAXINPUT,newModel);
                }
                else // this code is so bad, but it seemingly works really well, so I'm afraid to touch it...
                {
                    if ((updateModel) && (updateEntType))
                    {
                        if (lastAlias == 2)
                        {
                            if (entAlias > -1)
                            {
                                strcopy(testEntType,64,aliases[entAlias][2]);
                                if ((strlen(aliases[entAlias][1]) > 0) && (strcmp(newModel,"null") != 0) && (strcmp(newModel,"0") != 0))
                                    strcopy(testModel,MAXINPUT,aliases[entAlias][1]);
                                if ((!skipScript) && (strlen(aliases[entAlias][2]) > 0) && (strcmp(script[r][0],"null") != 0))
                                    strcopy(script[r][0],MAXINPUT,aliases[entAlias][3]);
                                if ((!skipProp) && (strlen(aliases[entAlias][4]) > 0) && (strcmp(script[r][1],"null") != 0) && (strcmp(script[r][1],"0") != 0))
                                    strcopy(script[r][1],MAXINPUT,aliases[entAlias][4]);
                            }
                            else
                                strcopy(testEntType,64,newEntType);
                            if (modelAlias > -1)
                            {
                                strcopy(testModel,MAXINPUT,aliases[modelAlias][1]);
                                if ((strlen(aliases[modelAlias][2]) > 0) && (strcmp(newEntType,"null") != 0) && (strcmp(newEntType,"0") != 0))
                                    strcopy(testEntType,64,aliases[modelAlias][2]);
                                if ((!skipScript) && (strlen(aliases[modelAlias][2]) > 0) && (strcmp(script[r][0],"null") != 0))
                                    strcopy(script[r][0],MAXINPUT,aliases[modelAlias][3]);
                                if ((!skipProp) && (strlen(aliases[modelAlias][4]) > 0) && (strcmp(script[r][1],"null") != 0) && (strcmp(script[r][1],"0") != 0))
                                    strcopy(script[r][1],MAXINPUT,aliases[modelAlias][4]);
                            }
                            else
                                strcopy(testModel,MAXINPUT,newModel);
                        }
                        else
                        {
                            if (modelAlias > -1)
                            {
                                strcopy(testModel,MAXINPUT,aliases[modelAlias][1]);
                                if ((strlen(aliases[modelAlias][2]) > 0) && (strcmp(newEntType,"null") != 0) && (strcmp(newEntType,"0") != 0))
                                    strcopy(testEntType,64,aliases[modelAlias][2]);
                                if ((!skipScript) && (strlen(aliases[modelAlias][2]) > 0) && (strcmp(script[r][0],"null") != 0))
                                    strcopy(script[r][0],MAXINPUT,aliases[modelAlias][3]);
                                if ((!skipProp) && (strlen(aliases[modelAlias][4]) > 0) && (strcmp(script[r][1],"null") != 0) && (strcmp(script[r][1],"0") != 0))
                                    strcopy(script[r][1],MAXINPUT,aliases[modelAlias][4]);
                            }
                            else
                                strcopy(testModel,MAXINPUT,newModel);
                            if (entAlias > -1)
                            {
                                strcopy(testEntType,64,aliases[entAlias][2]);
                                if ((strlen(aliases[entAlias][1]) > 0) && (strcmp(newModel,"null") != 0) && (strcmp(newModel,"0") != 0))
                                    strcopy(testModel,MAXINPUT,aliases[entAlias][1]);
                                if ((!skipScript) && (strlen(aliases[entAlias][2]) > 0) && (strcmp(script[r][0],"null") != 0))
                                    strcopy(script[r][0],MAXINPUT,aliases[entAlias][3]);
                                if ((!skipProp) && (strlen(aliases[entAlias][4]) > 0) && (strcmp(script[r][1],"null") != 0) && (strcmp(script[r][1],"0") != 0))
                                    strcopy(script[r][1],MAXINPUT,aliases[entAlias][4]);
                            }
                            else
                                strcopy(testEntType,64,newEntType);
                        }
                    }
                    else if (updateModel)
                    {
                        if (modelAlias > -1)
                        {
                            strcopy(testModel,MAXINPUT,aliases[modelAlias][1]);
                            if ((strlen(aliases[modelAlias][2]) > 0) && (strcmp(entType[r],"null") != 0) && (strcmp(entType[r],"0") != 0))
                                strcopy(testEntType,MAXINPUT,aliases[modelAlias][2]);
                            if ((!skipScript) && (strlen(aliases[modelAlias][2]) > 0) && (strcmp(script[r][0],"null") != 0))
                                strcopy(script[r][0],MAXINPUT,aliases[modelAlias][3]);
                            if ((!skipProp) && (strlen(aliases[modelAlias][4]) > 0) && (strcmp(script[r][1],"null") != 0) && (strcmp(script[r][1],"0") != 0))
                                strcopy(script[r][1],MAXINPUT,aliases[modelAlias][4]);
                        }
                        else
                            strcopy(testModel,MAXINPUT,newModel);
                    }
                    else if (updateEntType)
                    {
                        if (entAlias > -1)
                        {
                            strcopy(testEntType,MAXINPUT,aliases[entAlias][2]);
                            if ((strlen(aliases[entAlias][1]) > 0) && (strcmp(model[r],"null") != 0) && (strcmp(model[r],"0") != 0))
                                strcopy(testModel,MAXINPUT,aliases[entAlias][1]);
                            if ((!skipScript) && (strlen(aliases[entAlias][2]) > 0) && (strcmp(script[r][0],"null") != 0))
                                strcopy(script[r][0],MAXINPUT,aliases[entAlias][3]);
                            if ((!skipProp) && (strlen(aliases[entAlias][4]) > 0) && (strcmp(script[r][1],"null") != 0) && (strcmp(script[r][1],"0") != 0))
                                strcopy(script[r][1],MAXINPUT,aliases[entAlias][4]);
                        }
                        else
                            strcopy(testEntType,64,newEntType);
                    }
                    if ((!updateModel) && (strlen(testModel) < 1))
                        strcopy(testModel,MAXINPUT,model[r]);
                    if ((!updateEntType) && (strlen(testEntType) < 1))
                        strcopy(testEntType,64,entType[r]);
                    if ((strcmp(testModel,"null") == 0) || (strcmp(testModel,"0") == 0))
                        testModel = "";
                    if ((strcmp(testEntType,"null") == 0) || (strcmp(testEntType,"0") == 0))
                        testEntType = "prop_physics_override";
                    if ((strcmp(testEntType,"prop_physics_override") == 0) && (strlen(testModel) < 1))
                            RespondToCommand(client, "[SM] Error: Missing model for reward '#%d', not changing entity_type nor model.",r);
                    else
                    {
                        strcopy(model[r],MAXINPUT,testModel);
                        strcopy(entType[r],64,testEntType);
                    }
                }
            }
            if ((strcmp(script[r][0],"null") == 0) || (strcmp(script[r][0],"0") == 0))
                script[r][0] = "";
            if ((strcmp(script[r][1],"null") == 0) || (strcmp(script[r][1],"0") == 0))
                script[r][1] = "";
            if (g_enable)
            {
                spawnReward(r);
                if (release)
                {
                    CRespondToCommand(client, "[SM] Modified reward and released entity #%d",spawnEnts[r]);
                    resetReward(r);
                }
                else
                    CRespondToCommand(client, "[SM] Modified reward spawn point #%d",r);
            }
        }
    }
    if (client != 0)
        autoSave(SAVE_EDIT,true);
    return Plugin_Handled;
}

public Action:removeSpawnPoint(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (args < 1)
    {
        RespondToCommand(client, "[SM] Usage: sm_mrw_remove <#id|name>");
        return Plugin_Handled;
    }
    decl String:buffer[32];
    new bool:save = false;
    decl range[2];
    for (new i = 1;i <= args;i++)
    {
        GetCmdArg(i,buffer,32);
        if (getRewardRange(buffer,range,client))
            RespondToCommand(client, "[SM] Unknown reward '%s'",buffer);
        else
        {
            for (new j = range[0];j <= range[1];j++)
                removeReward(j);
            if (range[0] == range[1])
                RespondToCommand(client, "[SM] Removed reward #%d.",range[0]);
            else
                RespondToCommand(client, "[SM] Removed rewards #%d through #%d.",range[0],range[1]);
            save = true;
        }
    }
    if ((client > 0) && (save))
        autoSave(SAVE_REMOVE,true);
    return Plugin_Handled;
}

public Action:removeSpawnPoints(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    removeRewards();
    if (client != 0)
        autoSave(SAVE_REMOVE,true);
    RespondToCommand(client, "[SM] Removed all rewards");
    return Plugin_Handled;
}

public Action:manuallyRespawnReward(client, args)
{
    if (!handleClientAccess(client,g_basicFlag))
        return Plugin_Handled;
    if (args < 1)
    {
        RespondToCommand(client, "[SM] Usage: sm_mrw_respawn <#id|name>");
        return Plugin_Handled;
    }
    decl String:buffer[32];
    decl range[2];
    for (new i = 1;i <= args;i++)
    {
        GetCmdArg(i,buffer,32);
        if (getRewardRange(buffer,range,client))
            RespondToCommand(client, "[SM] Unknown reward '%s'",buffer);
        else
        {
            for (new j = range[0];j <= range[1];j++)
            {
                killReward(j);
                respawnMethod[j] &= ~HOOK_DEACTIVE;
                spawnReward(j);
            }
            if (range[0] == range[1])
                RespondToCommand(client, "[SM] Respawned reward #%d.",range[0]);
            else
                RespondToCommand(client, "[SM] Respawned rewards #%d through #%d.",range[0],range[1]);
        }
    }
    return Plugin_Handled;
}

public Action:mapRewardTrigger(client, args)
{
    if (handleClientAccess(client,g_basicFlag))
    {
        if (args < 1)
            RespondTriggerUsage(client);
        else
        {
            decl String:buffer[MAXINPUT];
            new bool:list[MAXSPAWNPOINT];
            GetCmdArg(1,buffer,MAXINPUT);
            if (!getRewardList(buffer,list,client))
                RespondToCommand(client, "[SM] Error: Found no rewards matching '%s'",buffer);
            else
            {
                new nextArg = 2;
                new bool:lastArg = false;
                new bool:err = false;
                new inflictor = -1;
                new bool:despawn = true;
                decl String:target_name[MAX_NAME_LENGTH];
                decl target_list[1];
                target_list[0] = client;
                decl Float:rTime;
                new bool:newTime = false;
                for (;nextArg <= args;nextArg++)
                {
                    if (nextArg == args)
                        lastArg = true;
                    GetCmdArg(nextArg,buffer,MAXINPUT);
                    if (buffer[0] == '-')
                    {
                        if (buffer[1] == '-')
                        {
                            nextArg++;
                            break;
                        }
                        switch (buffer[1])
                        {
                            case 'X': // Hurt command
                            {
                                inflictor = client;
                            }
                            case 'R': // Ignore the respawn_method of the reward
                            {
                                despawn = false;
                            }
                            case 't': // Custom respawn time
                            {
                                if (lastArg)
                                    err = true;
                                else
                                {
                                    GetCmdArg(++nextArg,buffer,MAXINPUT);
                                    rTime = StringToFloat(buffer);
                                    newTime = true;
                                }
                            }
                            default:
                            {
                                CRespondToCommand(client,"[SM] Ignoring unknown switch: %s",buffer);
                            }
                        }
                    }
                    else
                    {
                        GetCmdArg(nextArg,buffer,MAXINPUT);
                        decl bool:tn_is_ml;
                        if (ProcessTargetString(buffer,client,target_list,1,0,target_name,MAX_NAME_LENGTH,tn_is_ml) <= 0)
                        {
                            ReplyToTargetError(client,0);
                            return Plugin_Handled;
                        }
                        if (inflictor > -1)
                            inflictor = target_list[0];
                        break;
                    }
                    if (err)
                        break;
                }
                if (err)
                    RespondTriggerUsage(client);
                else for (new r = 0;r < MAXSPAWNPOINT;r++)
                {
                    if (list[r])
                    {
                        triggerReward(r,target_list[0],inflictor);
                        if ((despawn) && (spawnEnts[r] > -1))
                        {
                            if (respawnMethod[r] & HOOK_STATIC)
                            {
                                if (respawnMethod[r] & HOOK_TOUCH)
                                    SDKUnhook(spawnEnts[r], SDKHook_StartTouch, mapRewardPickUp);
                                respawnMethod[r] |= HOOK_DEACTIVE;
                            }
                            if (!(respawnMethod[r] & HOOK_CONSTANT))
                            {
                                if (!(respawnMethod[r] & HOOK_STATIC))
                                    killReward(r);
                                if (!newTime)
                                    rTime = respawnTime[r];
                                if (rTime < 0.0)
                                    CreateTimer(g_respawnTime,timerRespawnReward,r);
                                else if (rTime > 0.0)
                                    CreateTimer(rTime,timerRespawnReward,r);
                            }
                        }
                        CRespondToCommand(client,"[SM] Triggered reward #%d",r);
                    }
                }
            }
        }
    }
    return Plugin_Handled;
}

public Action:mapRewardPickUp(ent, client)
{
    if ((g_enable) && (client > 0) && (client <= MaxClients) && (IsClientInGame(client)))
    {
        for (new i = 0; i < MAXSPAWNPOINT; i++)
        {
            if (spawnEnts[i] == ent)
            {
                triggerReward(i,client);
                if (respawnMethod[i] & HOOK_STATIC)
                {
                    SDKUnhook(spawnEnts[i], SDKHook_StartTouch, mapRewardPickUp);
                    respawnMethod[i] |= HOOK_DEACTIVE;
                }
                if (!(respawnMethod[i] & HOOK_CONSTANT))
                {
                    if (!(respawnMethod[i] & HOOK_STATIC))
                        killReward(i);
                    if (respawnTime[i] < 0.0)
                        CreateTimer(g_respawnTime, timerRespawnReward, i);
                    else if (respawnTime[i] > 0.0)
                        CreateTimer(respawnTime[i], timerRespawnReward, i);
                }
                break;
            }
        }
    }
}

public Action:mapRewardTakeDamage(ent, &client, &inflictor, &Float:damage, &damageType)
{
    if ((g_enable) && (client > 0) && (client <= MaxClients) && (IsClientInGame(client)))
    {
        new index = -1;
        for (new i = 0; i < MAXSPAWNPOINT; i++)
            if (spawnEnts[i] == ent) index = i;
        if (index > -1)
        {
            if ((!(respawnMethod[index] & HOOK_KILL)) || (respawnMethod[index] & HOOK_CONSTANT))
                triggerReward(index,client,inflictor);
            if (respawnMethod[index] & (HOOK_CONSTANT|HOOK_DEACTIVE))
            {
                damage = 0.0;
                return Plugin_Changed;
            }
            if (respawnMethod[index] & HOOK_KILL)
            {
                rewardKiller[index] = client;
                entDamage[index] += damage;
                CreateTimer(0.001, rewardTakeDamagePost, index);
            }
            else
            {
                if (respawnMethod[index] & HOOK_STATIC)
                {
                    respawnMethod[index] |= HOOK_DEACTIVE;
                    if (respawnMethod[index] & HOOK_TOUCH)
                        SDKUnhook(spawnEnts[index], SDKHook_StartTouch, mapRewardPickUp);
                }
                else
                    killReward(index);
                if (respawnTime[index] < 0.0)
                    CreateTimer(g_respawnTime, timerRespawnReward, index);
                else if (respawnTime[index] > 0.0)
                    CreateTimer(respawnTime[index], timerRespawnReward, index);
            }
        }
    }
    return Plugin_Continue;
}

// Only trigger if the reward was killed
public Action:rewardTakeDamagePost(Handle:Timer, any:index)
{
    if ((entHealth[index]) && (entHealth[index]-entDamage[index] <= 0.0))
        killReward(index);
    if (!IsValidEntity(spawnEnts[index]))
    {
        triggerReward(index,rewardKiller[index],rewardKiller[index]);
        respawnMethod[index] &= ~HOOK_DEACTIVE;
        if (respawnTime[index] < 0.0)
            CreateTimer(g_respawnTime, timerRespawnReward, index);
        else if (respawnTime[index] > 0.0)
            CreateTimer(respawnTime[index], timerRespawnReward, index);
    }
    return Plugin_Stop;
}

//mass,0.1,inertia,1000.0?modelscale,float=2.0&DisableMotion

//proper format:    overridescript?key,type=value&key,type=value&...&input&input&...

/*
sm_maprewards_add_here gift null null?DisableMotion&modelscale,float:2.0
[SM] Debug0: null | DisableMotion&modelscale,float&
[SM] Debug1: DisableMotion
[SM] Debug2: DisableMotion | 
[SM] Debug3: : | 
[SM] Debug4: modelscale,float&
[SM] Debug1: modelscale,float
[SM] Debug2: modelscale | float
[SM] Debug3: :: | float
[SM] Debug4: 

NIGathan: !maprewards_add_here gift null null?DisableMotion&modelscale,float=2.0
[SM] Debug0: null | DisableMotion&modelscale,float=2.0&
[SM] Debug1: DisableMotion
[SM] Debug2: DisableMotion |
[SM] Debug3: = |
[SM] Debug4: modelscale,float=2.0&
[SM] Debug1: modelscale,float=2.0
[SM] Debug2: modelscale | float=2.0
[SM] Debug3: float= | 2.0
[SM] Debug4:

*/

public Action:timerRespawnReward(Handle:Timer, any:index)
{
    if (g_enable)
    {
        if (index == -1)
            spawnRewards();
        else
        {
            respawnMethod[index] &= ~HOOK_DEACTIVE;
            spawnReward(index);
        }
    }
    return Plugin_Stop;
}

public Action:timerSpinEnt(Handle:Timer, any:index)
{
    if (g_enable)
    {
        if ((index < 0) || (spawnEnts[index] < 0) || (!IsValidEntity(spawnEnts[index])))
        {
            entTimers[index] = INVALID_HANDLE;
            return Plugin_Stop;
        }
        for (new i = 0;i < 3;i++)
        {
            entSpinAngles[index][i] += entSpin[index][i];
            if (entSpinAngles[index][i] > 360.0)
                entSpinAngles[index][i] -= 360.0;
            if (entSpinAngles[index][i] < -360.0)
                entSpinAngles[index][i] += 360.0;
        }
        TeleportEntity(spawnEnts[index],NULL_VECTOR,entSpinAngles[index],NULL_VECTOR);
        return Plugin_Continue;
    }
    return Plugin_Stop;
}

public Action:sendCommandBuffer(Handle:Timer, Handle:buffer)
{
    decl String:buf[MAXCMDLEN];
    new i = 0, bSize = 1;
    decl size;
    GetArrayString(buffer,0,buf,MAXCMDLEN);
    if (StrIsDigit(buf) > -1)
    {
        decl String:indexes[2][16];
        ExplodeString(buf,",",indexes,2,16);
        i = StringToInt(indexes[0]);
        size = StringToInt(indexes[1]);
    }
    else
        size = GetArraySize(buffer);
    for (;i < size;i++)
    {
        GetArrayString(buffer,i,buf,MAXCMDLEN);
        bSize += strlen(buf)+2;
        if (bSize < MAXCMDBUF)
            ServerCommand(buf);
        else
        {
            Format(buf,MAXCMDLEN,"%d,%d",i,size);
            SetArrayString(buffer,0,buf);
            return Plugin_Continue;
        }
    }
    if (i >= size)
    {
        ResizeArray(buffer,0);
        CloseHandle(buffer);
    }
    return Plugin_Stop;
}

