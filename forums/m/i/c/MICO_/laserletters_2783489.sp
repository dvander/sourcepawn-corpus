#include <sourcemod>
#include <sdktools>

#define MAX_COLOURS 8

/* Con Vars */

new Handle:hMaxPerTime = INVALID_HANDLE;
new Handle:hMaxInterval = INVALID_HANDLE;
new Handle:hDrawDelay = INVALID_HANDLE;
new Handle:hCanUseWhileDead = INVALID_HANDLE;
new Handle:hAdminFlags = INVALID_HANDLE;

/* Cached Con Var Values */
new bool:bCanUseWhileDead = true;
new iMaxPerTime = 64;
new iMaxInterval = 180;
new iAdminFlags = ADMFLAG_CHANGEMAP|ADMFLAG_ROOT|ADMFLAG_CUSTOM2;
new Float:fDrawDelay = 0.05;

new iColours[MAX_COLOURS][4] = {{255, 0, 0, 255},           // Red
                                {255, 150, 0, 255},         // Orange
                                {255, 255, 0, 255},         // Yellow
                                {0, 255, 0, 255},           // Green
                                {0, 0, 255, 255},           // Dark Blue
                                {255, 0, 255, 255},         // Purple
                                {0, 255, 255, 255},         // Light Blue
                                {255, 255, 255, 255}}       // White
new Handle:hLetters;
new Handle:hLettersLeft;

new iSprite = -1;

new String:sLetterPath[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
    name = "Laser Letters",
    author = "bonbon",
    description = "Laser Letters",
    version = "1.0.0",
    url = "http://forums.alliedmods.net"
};


/* ----- Events ----- */


public OnPluginStart()
{
    BuildPath(Path_SM,
              sLetterPath, PLATFORM_MAX_PATH, "data/letters.txt");

    if (!FileExists(sLetterPath))
    {
        SetFailState("No location data file \"./data/letters.txt\"");
    }

    hLetters = CreateKeyValues("letters");
    FileToKeyValues(hLetters, sLetterPath);

    hLettersLeft = CreateTrie();

    hMaxPerTime = CreateConVar("ll_max_letters_per_time", "64",
                                "The maximum amount of letters an admin can use per time interval");

    hMaxInterval = CreateConVar("ll_max_letters_interval", "180",
                                "The time interval for the max letters an admin can use");

    hDrawDelay = CreateConVar("ll_draw_delay", "0.05",
                              "How long to delay drawing each consecutive letter");

    hCanUseWhileDead = CreateConVar("ll_can_use_while_dead", "1",
                                    "Wether or not players can use laser letters while dead");

    hAdminFlags = CreateConVar("ll_required_flags", "gzp",
                               "What flag is required to use laser letters. No separator, leave blank for everyone");

    HookConVarChange(hMaxPerTime, OnConVarChanged);
    HookConVarChange(hMaxInterval, OnConVarChanged);
    HookConVarChange(hDrawDelay, OnConVarChanged);
    HookConVarChange(hCanUseWhileDead, OnConVarChanged);
    HookConVarChange(hAdminFlags, OnConVarChanged);

    RegConsoleCmd("sm_ll", Command_DrawText,
                  "Creates laser letters above a players head");

    AutoExecConfig(true);
}

public OnMapStart()
{
    iSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnConVarChanged(Handle:CVar, const String:sOld[], const String:sNew[])
{
    if (CVar == hMaxPerTime)
        iMaxPerTime = GetConVarInt(hMaxPerTime);

    else if (CVar == hMaxInterval)
        iMaxInterval = GetConVarInt(hMaxInterval);

    else if (CVar == hDrawDelay)
        fDrawDelay = GetConVarFloat(hDrawDelay);

    else if (CVar == hCanUseWhileDead)
        bCanUseWhileDead = GetConVarBool(CVar);

    else if (CVar == hAdminFlags)
        iAdminFlags = ReadFlagString(sNew);
}


/* ----- Commands ----- */


public Action:Command_DrawText(client, args)
{
    if (!client)
    {
        ReplyToCommand(client, "You must be in game to use this command");
        return Plugin_Handled;
    }

    if (iAdminFlags && !(GetUserFlagBits(client) & iAdminFlags))
    {
        PrintToChat(client,
                    "\x03[Laser Letters]: \x01You are not authorized to use this command");
        return Plugin_Handled;
    }

    if (args < 1)
        return Plugin_Handled;

    if (!bCanUseWhileDead &&
        (!IsPlayerAlive(client) || GetClientTeam(client) <= 1))
    {
        PrintToChat(client,
                    "\x03[Laser Letters]: \x01You must be alive to use this command");
        return Plugin_Handled;
    }

    decl String:text[255];
    GetCmdArgString(text, sizeof(text));

    decl Float:origin[3];
    decl Float:angles[3];

    GetClientEyePosition(client, origin);
    GetClientEyeAngles(client, angles);

    new Float:delay;
    new new_lines;
    new this_time;
    new temp_letters;

    angles[1] -= 90.0;
    origin[2] += 20.0;

    new Float:xAdd = 25.0 * Cosine(DegToRad(angles[1]));
    new Float:yAdd = 25.0 * Sine(DegToRad(angles[1]));

    ReplaceString(text, sizeof(text), "\\n", "\n");

    decl String:steamid[32];
    GetClientAuthString(client, steamid, sizeof(steamid));

    if (!GetTrieValue(hLettersLeft, steamid, temp_letters))
        SetTrieValue(hLettersLeft, steamid, 0);

    new max = GetMaxPerTime(client);

    for (new i = 0; i < strlen(text); i++)
    {
        if (temp_letters >= max)
        {
            PrintToChat(client,
                        "\x03[Laser Letters]: \x01You can only use \x04%d\x01 letters every \x04%02d:%02d",
                        max, iMaxInterval / 60, iMaxInterval % 60);
            break;
        }

        if (text[i] == '\n')
        {
            GetClientEyePosition(client, origin);
            origin[2] -= -20.0 + (33.3 * ++new_lines);

            continue;
        }

        new Float:data[7];
        new Handle:hData = CreateArray(8);
        
        data[0] = origin[0];
        data[1] = origin[1];
        data[2] = origin[2];
        data[3] = angles[0];
        data[4] = angles[1];
        data[5] = angles[2];
        data[6] = float(text[i]);

        PushArrayArray(hData, data);
        CreateTimer(delay, Timer_DrawLetter, hData);

        origin[0] += xAdd;
        origin[1] += yAdd;

        if (text[i] != ' ')
        {
            delay += fDrawDelay;

            this_time++;
            temp_letters++;
        }

        
        if (text[i] == 'o' || text[i] == 'O' ||
            text[i] == 'q' || text[i] == 'Q' ||
            text[i] == '@')
        {
            origin[0] += xAdd * 0.5;
            origin[1] += yAdd * 0.5;
        }
    }

    new Handle:hData = CreateDataPack();
    SetTrieValue(hLettersLeft, steamid, temp_letters);

    WritePackString(hData, steamid)
    WritePackCell(hData, this_time);
    WritePackCell(hData, GetClientUserId(client));

    PrintToChat(client,
                "\x03[Laser Letters]: \x01You have \x04%d\x01 letters left",
                max - temp_letters);

    PrintToChat(client,
                "\x03[Laser Letters]: \x01You will be allowed to use \x04%d\x01 more in \x04%02d:%02d",
                this_time, iMaxInterval / 60, iMaxInterval % 60);

    CreateTimer(float(iMaxInterval), SubtractLetters, hData, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Handled;
}


/* ----- Functions ----- */

GetMaxPerTime(client)
{
    return (GetUserFlagBits(client) & ADMFLAG_ROOT) ? iMaxPerTime * 5 : iMaxPerTime;
}

public Action:Timer_DrawLetter(Handle:timer, any:hData)
{
    decl Float:data[7];
    GetArrayArray(hData, 0, data);

    decl Float:origin[3];
    decl Float:angles[3];

    origin[0] = data[0];
    origin[1] = data[1];
    origin[2] = data[2];

    angles[0] = data[3];
    angles[1] = data[4];
    angles[2] = data[5];

    new iLetter = RoundToNearest(data[6]);
    decl String:letter[2];

    Format(letter, sizeof(letter), "%c", iLetter);
    DrawLetter(letter, origin, angles);

    CloseHandle(hData);
}

stock DrawLetter(const String:letter[], Float:origin[3], Float:angles[3])
{
    new i;

    decl String:key[8];
    decl String:coords[64];
    decl String:points[6][8];
    decl Float:tempOrigin[3];
    decl Float:tempEnd[3];

    KvRewind(hLetters);

    /* Letter might not be supported */
    if (!KvJumpToKey(hLetters, letter))
    {
        new letter_ascii = letter[0];

        decl String:chr[12];
        Format(chr, sizeof(chr), "chr(%d)", letter_ascii);

        KvRewind(hLetters);
        if (!KvJumpToKey(hLetters, chr))
            return;
    }

    new Float:xMultiply = Cosine(DegToRad(angles[1]));
    new Float:yMultiply = Sine(DegToRad(angles[1]));

    new Float:x;
    new Float:xe;
    new Float:distance;

    new tempColour[4];
    tempColour = iColours[GetRandomInt(0, MAX_COLOURS - 1)];

    do
    {
        IntToString(++i, key, sizeof(key));
        KvGetString(hLetters,
                    key, coords, sizeof(coords), "no more");

        if (StrEqual("no more", coords))
            return;

        ExplodeString(coords, " ", points, 6, 8);

        x = StringToFloat(points[0]);
        xe = StringToFloat(points[3]);

        distance = xe - x;

        tempOrigin[0] = origin[0] + x * xMultiply;
        tempOrigin[1] = origin[1] + x * yMultiply;
        tempOrigin[2] = origin[2] + StringToFloat(points[2])

        tempEnd[0] = origin[0] + (x + distance) * xMultiply;
        tempEnd[1] = origin[1] + (x + distance) * yMultiply;
        tempEnd[2] = origin[2] + StringToFloat(points[5]);

        TE_SetupBeamPoints(tempOrigin, tempEnd, iSprite,
                           0, 0, 0, 20.0, 2.0, 2.0, 0, 0.0,
                           tempColour, 0);
        TE_SendToAll();

    } while (!StrEqual("no more", coords));
}

public Action:SubtractLetters(Handle:timer, any:hData)
{
    ResetPack(hData);

    decl String:steamid[32];
    ReadPackString(hData, steamid, sizeof(steamid));

    new subtract = ReadPackCell(hData);
    new client = GetClientOfUserId(ReadPackCell(hData));
    new letters;

    CloseHandle(hData);

    /* Should never happen... but just in case */
    if (!GetTrieValue(hLettersLeft, steamid, letters))
        return;

    if (client)
        PrintToChat(client,
                    "\x03[Laser Letters]: \x01You can now use \x04%d\x01 more letters (\x04%d\x01 total)",
                    subtract, GetMaxPerTime(client) - (letters - subtract));

    if (letters - subtract < 1)
        RemoveFromTrie(hLettersLeft, steamid);

    else
        SetTrieValue(hLettersLeft, steamid, letters - subtract);
}
