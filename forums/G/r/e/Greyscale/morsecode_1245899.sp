/*
 * ============================================================================
 *
 *  Morse Code
 *
 *  File:          morsecode.sp
 *  Type:          Base
 *  Description:   Lets players use morse code with their flashlights.
 *
 *  Copyright (C) 2009-2010  Greyscale
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

/**
 * TODO:
 * block console from using command
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
    name = "Morse Code",
    author = "Greyscale",
    description = "Lets players use morse code with their flashlights.",
    version = PLUGIN_VERSION,
    url = ""
};

/**
 * The server's index.
 */
#define SERVER_INDEX 0

/**
 * Cvar handles.
 */
new Handle:g_hCvarWPM;
//new Handle:g_hCvarLight;
//new Handle:g_hCvarSound;
new Handle:g_hCvarInterpret;
new Handle:g_hCvarRadius;

/**
 * Converts the value in mcode_radius into game units.
 */
#define CVAR_RADIUS GetConVarFloat(g_hCvarRadius) * 52.493

/**
 * SDKCall handles.
 */
new Handle:g_hGameConfig;
new Handle:g_hFlashlightIsOn;
new Handle:g_hFlashlightTurnOn;
new Handle:g_hFlashlightTurnOff;

/**
 * Greatest ascii code in supported morse code characters.
 */
#define ASCII_UPPER 220

new const String:g_strMorseCodeChars[] = "abcdefghijklmnopqrstuvwxyz1234567890.,?'!/()&:;=+-_\"$@адияжэ";
new const String:g_strMorseCodes[ASCII_UPPER + 1][8];

/**
 * Words per minute.
 * More info: http://en.wikipedia.org/wiki/Morse_code
 * WPM = 12 means an element time of 0.1s.
 * Dit is 1 element
 * Dah is 3 elements.  
 */
#define MORSE_WPM GetConVarInt(g_hCvarWPM)

/**
 * The most recent script created by the client.
 */
new String:g_strScript[MAXPLAYERS + 1][64][8];

/**
 * Tracks where a client is currently in the script.
 */
new g_iCurScriptIndex[MAXPLAYERS + 1];
new g_iCurScriptChar[MAXPLAYERS + 1];

/**
 * A more readable way to reference the client's current spot in the script.
 */
#define SCRIPT_CURCHAR(%1) g_strScript[%1][g_iCurScriptIndex[%1]][g_iCurScriptChar[%1]]

/**
 * Timer that's handling a client's current morse code transmission.
 */
new Handle:g_hTimerMorseCode[MAXPLAYERS + 1];

/**
 * Array to store morse code interpretations from other clients.
 */
new String:g_strInterpreted[MAXPLAYERS + 1][MAXPLAYERS + 1][64];

MorseCode_Init()
{
    // If . is represented as binary 0
    // and - is represented as binary 1
    // The first value is the base-10 forms of the morse code-to-binary numbers.
    // The second value is how many bits to read.  Otherwise a (01) and t (1) are equivalents.
    strcopy(g_strMorseCodes['a'], sizeof(g_strMorseCodes[]), ".-");      // 1
    strcopy(g_strMorseCodes['b'], sizeof(g_strMorseCodes[]), "-...");    // 8
    strcopy(g_strMorseCodes['c'], sizeof(g_strMorseCodes[]), "-.-.");    // 10
    strcopy(g_strMorseCodes['d'], sizeof(g_strMorseCodes[]), "-..");     // 4
    strcopy(g_strMorseCodes['e'], sizeof(g_strMorseCodes[]), ".");       // 0
    strcopy(g_strMorseCodes['f'], sizeof(g_strMorseCodes[]), "..-.");    // 2
    strcopy(g_strMorseCodes['g'], sizeof(g_strMorseCodes[]), "--.");     // 6
    strcopy(g_strMorseCodes['h'], sizeof(g_strMorseCodes[]), "....");    // 0
    strcopy(g_strMorseCodes['i'], sizeof(g_strMorseCodes[]), "..");      // 0
    strcopy(g_strMorseCodes['j'], sizeof(g_strMorseCodes[]), ".---");    // 7
    strcopy(g_strMorseCodes['k'], sizeof(g_strMorseCodes[]), "-.-");     // 5
    strcopy(g_strMorseCodes['l'], sizeof(g_strMorseCodes[]), ".-..");    // 4
    strcopy(g_strMorseCodes['m'], sizeof(g_strMorseCodes[]), "--");      // 3
    strcopy(g_strMorseCodes['n'], sizeof(g_strMorseCodes[]), "-.");      // 2
    strcopy(g_strMorseCodes['o'], sizeof(g_strMorseCodes[]), "---");     // 7
    strcopy(g_strMorseCodes['p'], sizeof(g_strMorseCodes[]), ".--.");    // 6
    strcopy(g_strMorseCodes['q'], sizeof(g_strMorseCodes[]), "--.-");    // 13
    strcopy(g_strMorseCodes['r'], sizeof(g_strMorseCodes[]), ".-.");     // 2
    strcopy(g_strMorseCodes['s'], sizeof(g_strMorseCodes[]), "...");     // 0
    strcopy(g_strMorseCodes['t'], sizeof(g_strMorseCodes[]), "-");       // 1
    strcopy(g_strMorseCodes['u'], sizeof(g_strMorseCodes[]), "..-");     // 1
    strcopy(g_strMorseCodes['v'], sizeof(g_strMorseCodes[]), "...-");    // 1
    strcopy(g_strMorseCodes['w'], sizeof(g_strMorseCodes[]), ".--");     // 3
    strcopy(g_strMorseCodes['x'], sizeof(g_strMorseCodes[]), "-..-");    // 9
    strcopy(g_strMorseCodes['y'], sizeof(g_strMorseCodes[]), "-.--");    // 11
    strcopy(g_strMorseCodes['z'], sizeof(g_strMorseCodes[]), "--..");    // 12
    strcopy(g_strMorseCodes['1'], sizeof(g_strMorseCodes[]), ".----");   // 15
    strcopy(g_strMorseCodes['2'], sizeof(g_strMorseCodes[]), "..---");   // 7
    strcopy(g_strMorseCodes['3'], sizeof(g_strMorseCodes[]), "...--");   // 3
    strcopy(g_strMorseCodes['4'], sizeof(g_strMorseCodes[]), "....-");   // 1
    strcopy(g_strMorseCodes['5'], sizeof(g_strMorseCodes[]), ".....");   // 0
    strcopy(g_strMorseCodes['6'], sizeof(g_strMorseCodes[]), "-....");   // 16
    strcopy(g_strMorseCodes['7'], sizeof(g_strMorseCodes[]), "--...");   // 24
    strcopy(g_strMorseCodes['8'], sizeof(g_strMorseCodes[]), "---..");   // 28
    strcopy(g_strMorseCodes['9'], sizeof(g_strMorseCodes[]), "----.");   // 30
    strcopy(g_strMorseCodes['0'], sizeof(g_strMorseCodes[]), "-----");   // 31
    strcopy(g_strMorseCodes['.'], sizeof(g_strMorseCodes[]), ".-.-.-");  // 21
    strcopy(g_strMorseCodes[','], sizeof(g_strMorseCodes[]), "--..--");  // 51
    strcopy(g_strMorseCodes['?'], sizeof(g_strMorseCodes[]), "..--..");  // 12
    strcopy(g_strMorseCodes['\''], sizeof(g_strMorseCodes[]), ".----."); // 30
    strcopy(g_strMorseCodes['!'], sizeof(g_strMorseCodes[]), "-.-.--");  // 43
    strcopy(g_strMorseCodes['/'], sizeof(g_strMorseCodes[]), "-..-.");   // 18
    strcopy(g_strMorseCodes['('], sizeof(g_strMorseCodes[]), "-.--.");   // 22
    strcopy(g_strMorseCodes[')'], sizeof(g_strMorseCodes[]), "-.--.-");  // 45
    strcopy(g_strMorseCodes['&'], sizeof(g_strMorseCodes[]), ".-....");  // 8
    strcopy(g_strMorseCodes[':'], sizeof(g_strMorseCodes[]), "---...");  // 56
    strcopy(g_strMorseCodes[';'], sizeof(g_strMorseCodes[]), "-.-.-.");  // 42
    strcopy(g_strMorseCodes['='], sizeof(g_strMorseCodes[]), "-...-");   // 17
    strcopy(g_strMorseCodes['+'], sizeof(g_strMorseCodes[]), ".-.-.");   // 10
    strcopy(g_strMorseCodes['-'], sizeof(g_strMorseCodes[]), "-....-");  // 33
    strcopy(g_strMorseCodes['_'], sizeof(g_strMorseCodes[]), "..--.-");  // 13
    strcopy(g_strMorseCodes['\"'], sizeof(g_strMorseCodes[]), ".-..-."); // 18
    strcopy(g_strMorseCodes['$'], sizeof(g_strMorseCodes[]), "...-..-"); // 9
    strcopy(g_strMorseCodes['@'], sizeof(g_strMorseCodes[]), ".--.-.");  // 26
    strcopy(g_strMorseCodes['а'], sizeof(g_strMorseCodes[]), ".--.-");   // 13
    strcopy(g_strMorseCodes['д'], sizeof(g_strMorseCodes[]), ".-.-");    // 5
    strcopy(g_strMorseCodes['и'], sizeof(g_strMorseCodes[]), "..-..");   // 4
    strcopy(g_strMorseCodes['я'], sizeof(g_strMorseCodes[]), "--.--");   // 27
    strcopy(g_strMorseCodes['ж'], sizeof(g_strMorseCodes[]), "---.");    // 14
    strcopy(g_strMorseCodes['э'], sizeof(g_strMorseCodes[]), "..--");    // 3
}

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
    MorseCode_Init();
    //MorseCode_PrintChars();
    
    // Create cvars.
    g_hCvarWPM =        CreateConVar("mcode_wpm", "10", "Words per minute.  1.2/WPM = length of one short (dit).  Multiply by 3 for  a long. (dah)");
    //g_hCvarLight =      CreateConVar("mcode_light", "1", "Flashlight will be used to send morse code visually.");
    //g_hCvarSound =      CreateConVar("mcode_sound", "0", "Beeping sound will be used to send morse code auditorily.");
    g_hCvarInterpret =  CreateConVar("mcode_interpret", "1", "The plugin will interpret morse code when in range of a transmitting player.");
    g_hCvarRadius =     CreateConVar("mcode_radius", "15", "The distance, in meters, in which players will be able to interpret morse code being transmitted.");
    
    AutoExecConfig();
    
    // Load translations
    LoadTranslations("common.phrases");
    
    // Hook events.
    HookEvent("player_death", Event_PlayerDeath);
    
    // Create public cvar.
    CreateConVar("gs_morsecode_version", PLUGIN_VERSION, "[MorseCode] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    // Create commands.
    RegConsoleCmd("sm_morse", Command_Morse, "Converts text entered into morse code for other players to see/hear.  Usage: sm_morsecode <text>");
    
    // Create admin commands.
    RegAdminCmd("sm_forcecode", Command_ForceCode, ADMFLAG_GENERIC, "Forces a client to transmit morse code.  Usage: sm_forcecode <client> <text>");
    
    // Load game config file.
    g_hGameConfig = LoadGameConfigFile("plugin.morsecode");
    if (g_hGameConfig == INVALID_HANDLE)
    {
        SetFailState("Can't load game config file (plugin.morsecode.txt) from the \"gamedata\" directory.");
    }
    
    // Prep the flashlight SDKCalls.
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "FlashlightIsOn");
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    g_hFlashlightIsOn = EndPrepSDKCall();
    if (g_hFlashlightIsOn == INVALID_HANDLE)
    {
        SetFailState("Game function \"CCSPlayer::FlashlightIsOn\" was not found.");
    }
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "FlashlightTurnOn");
    g_hFlashlightTurnOn = EndPrepSDKCall();
    if (g_hFlashlightTurnOn == INVALID_HANDLE)
    {
        SetFailState("Game function \"CCSPlayer::FlashlightTurnOn\" was not found.");
    }
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "FlashlightTurnOff");
    g_hFlashlightTurnOff = EndPrepSDKCall();
    if (g_hFlashlightTurnOff == INVALID_HANDLE)
    {
        SetFailState("Game function \"CCSPlayer::FlashlightTurnOff\" was not found.");
    }
}

/**
 * Client has joined the server.
 * 
 * @param client    The client index.
 */
public OnClientPutInServer(client)
{
    g_hTimerMorseCode[client] = INVALID_HANDLE;
}

/**
 * Client is disconnecting from the server.
 * 
 * @param client    The client index.
 */
public OnClientDisconnect(client)
{
    // Stop transmitting morse code.
    Util_CloseHandle(g_hTimerMorseCode[client]);
}

// **********************************************
//                    Events
// **********************************************

/**
 * Client has been killed.
 *
 * @param event			Handle to event. This could be INVALID_HANDLE if every plugin hooking 
 *						this event has set the hook mode EventHookMode_PostNoCopy.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // Stop transmission.
    MorseCode_EndScript(victim);
}

// **********************************************
//               Command Callbacks
// **********************************************

/**
 * Called when a generic console command is invoked.
 *
 * @param client		Index of the client, or 0 from the server.
 * @param args			Number of arguments that were in the argument string.
 * 
 * @return				An Action value.  Not handling the command
 *						means that Source will report it as "not found."
 */
public Action:Command_Morse(client, argc)
{
    // Get message.
    decl String:message[64];
    GetCmdArgString(message, sizeof(message));
    
    // Clear old script.
    for (new charindex = 0; charindex < sizeof(g_strScript[]); charindex++)
    {
        g_strScript[client][charindex][0] = '\0';
    }
    
    MorseCode_BuildScript(message, g_strScript[client]);
    MorseCode_BeginScript(client);
    
    return Plugin_Handled;
}

/**
 * Called when a generic console command is invoked.
 *
 * @param client		Index of the client, or 0 from the server.
 * @param args			Number of arguments that were in the argument string.
 * 
 * @return				An Action value.  Not handling the command
 *						means that Source will report it as "not found."
 */
public Action:Command_ForceCode(client, argc)
{
    // If not enough arguments given, then stop.
    if (argc < 2)
    {
        ReplyToCommand(client, "[SM] Syntax: sm_forcecode <client> <text>");
        return Plugin_Handled;
    }
    
    decl String:target[MAX_NAME_LENGTH], String:targetname[MAX_NAME_LENGTH];
    new targets[MAXPLAYERS], bool:tn_is_ml, result;
    
    // Get targetname.
    GetCmdArg(1, target, sizeof(target));
    
    // Find a target.
    result = ProcessTargetString(target, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetname, sizeof(targetname), tn_is_ml);
        
    // Check if there was a problem finding a client.
    if (result <= 0)
    {
        ReplyToTargetError(client, result);
        return Plugin_Handled;
    }
    
    // Get message.
    decl String:message[64];
    GetCmdArg(2, message, sizeof(message));
    
    for (new tindex = 0; tindex < result; tindex++)
    {
        // Clear old script.
        for (new charindex = 0; charindex < sizeof(g_strScript[]); charindex++)
        {
            g_strScript[targets[tindex]][charindex][0] = '\0';
        }
        
        MorseCode_BuildScript(message, g_strScript[targets[tindex]]);
        MorseCode_BeginScript(targets[tindex]);
    }
    
    return Plugin_Handled;
}

// **********************************************
//               Morse Code API
// **********************************************

/**
 * Takes a string and builds a script of morse code.
 * Each element of the array is its own character.
 * Will skip unsupported morse code characters. 
 * 
 * @param message   The message to build morse code script for.  Maximum of 64 characters.
 * @param script    The morse code script.  Each element contains morse code.  Ex: script[5] = "...-"
 * 
 * @return          Number of characters in the script.
 */
MorseCode_BuildScript(const String:message[], String:script[64][8])
{
    new index;
    new lchr;
    new length = strlen(message);
    for (new chr = 0; chr < length; chr++)
    {
        // Morse code is case insensitive.
        lchr = CharToLower(message[chr]);
        
        // Check if the character is either greater than the greatest supported ascii code or if there is nothing defined for this character.
        if (lchr > ASCII_UPPER || g_strMorseCodes[lchr][0] == '\0')
            continue;
        
        strcopy(script[index++], sizeof(script[]), g_strMorseCodes[lchr]);
    }
    
    return index;
}

/**
 * Begin transmission of morse code.
 * 
 * @param client    The client index.
 */
MorseCode_BeginScript(client)
{
    // Start from beginning.
    g_iCurScriptIndex[client] = 0;
    g_iCurScriptChar[client] = 0;
    
    g_hTimerMorseCode[client] = CreateTimer(MorseCode_GetElementTime(), Timer_Transmit, client, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * End transmission of morse code.
 * 
 * @param client    The client index.
 */
MorseCode_EndScript(client)
{
    // Clear script.
    for (new scriptindex = 0; scriptindex < sizeof(g_strScript[]); scriptindex++)
    {
        g_strScript[client][scriptindex][0] = '\0';
    }
    
    // Reset current place in script.
    g_iCurScriptIndex[client] = 0;
    g_iCurScriptChar[client] = 0;
    
    Util_CloseHandle(g_hTimerMorseCode[client]);
    
    // Forward as event that this client just finished a transmission.
    Interpreter_OnTransmissionEnded(client);
}

/**
 * Called when the timer interval has elapsed.
 * 
 * @param timer     Handle to the timer object.
 * @param client    The client transmitting morse code.
 * 
 * @return          Plugin_Stop to stop a repeating timer, any other value for default behavior.
 */
public Action:Timer_Transmit(Handle:timer, any:client)
{
    // Check if script is finished.
    if (SCRIPT_CURCHAR(client) != '.' && SCRIPT_CURCHAR(client) != '-')
    {
        // Forward as an event that this client just finished transmitting a character.
        Interpreter_OnTransmittedChar(client);
        
        g_iCurScriptIndex[client]++;
        g_iCurScriptChar[client] = 0;
        if (SCRIPT_CURCHAR(client) != '.' && SCRIPT_CURCHAR(client) != '-')
        {
            g_hTimerMorseCode[client] = INVALID_HANDLE;
            MorseCode_EndScript(client);
            return;
        }
    }
    
    new cur_char = SCRIPT_CURCHAR(client);
    new Float:hold_time;
    if (cur_char == '.')
    {
        MorseCode_Dit(client);
        hold_time = MorseCode_GetElementTime();
    }
    else if (cur_char == '-')
    {
        MorseCode_Dah(client);
        hold_time = MorseCode_GetElementTime() * 3.0;
    }
    
    g_iCurScriptChar[client]++;
    g_hTimerMorseCode[client] = CreateTimer(hold_time + MorseCode_GetElementTime(), Timer_Transmit, client, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Produces a morse code "dit" (short)
 * 
 * @param client    The client index.
 */
MorseCode_Dit(client)
{
    new Float:dit_time = MorseCode_GetElementTime();
    
    MorseCode_FlashlightTurnOn(client);
    CreateTimer(dit_time, Timer_Dit, client);
}

public Action:Timer_Dit(Handle:timer, any:client)
{
    if (IsClientInGame(client))
    {
        MorseCode_FlashlightTurnOff(client);
    }
}

/**
 * Produces a morse code "dah" (long)
 * 
 * @param client    The client index.
 */
MorseCode_Dah(client)
{
    new Float:dah_time = MorseCode_GetElementTime() * 3.0;
    
    MorseCode_FlashlightTurnOn(client);
    CreateTimer(dah_time, Timer_Dah, client);
}

public Action:Timer_Dah(Handle:timer, any:client)
{
    if (IsClientInGame(client))
    {
        MorseCode_FlashlightTurnOff(client);
    }
}

/**
 * Returns the element time.
 * dit = 1 element on, 1 element off
 * dah = 3 elements on, 1 element off
 * Return value is cached. 
 */
Float:MorseCode_GetElementTime()
{
    return 1.2 / float(MORSE_WPM);
}

/**
 * Finds the char associated with the morse code string.
 * 
 * @param morsecode The string of morse code to find char for.
 * 
 * @return          The char that matches the morse code given, -1 if morse code string is invalid.
 */
MorseCode_Interpret(const String:morsecode[])
{
    for (new cindex = 0; cindex < sizeof(g_strMorseCodes); cindex++)
    {
        if (StrEqual(morsecode, g_strMorseCodes[cindex]))
            return cindex;
    }
    
    return -1;
}

/**
 * Print interpreted morse code from one client to another that appears the same as in the specified game.
 * 
 * @param sender    The sender of the message.
 * @param receiver  The receiver of the sender's message.
 * @param text      The text to send to the receiver from the sender.
 */
stock MorseCode_PrintGameMessage(sender, receiver, const String:text[])
{
    decl String:sendername[64];
    GetClientName(sender, sendername, sizeof(sendername));
    
    new Handle:hSayText2 = StartMessageOne("SayText2", receiver);
        
    BfWriteByte(hSayText2, sender);
    BfWriteByte(hSayText2, true);
    BfWriteString(hSayText2, "\x01%s1 \x03%s2 \x01:  %s3");
    BfWriteString(hSayText2, "(Morse Code)");
    BfWriteString(hSayText2, sendername);
    BfWriteString(hSayText2, text);
    
    EndMessage();
}

/**
 * Prints all supported characters and ascii codes for each.
 */
stock MorseCode_PrintChars()
{
    for (new char = 0; char < sizeof(g_strMorseCodeChars); char++)
    {
        new chr = g_strMorseCodeChars[char];
        PrintToServer("%c %d", g_strMorseCodeChars[char], chr);
    }
}

// **********************************************
//                 Interpreter
// **********************************************

/**
 * Add a character to the current list of interpreted characters for this client.
 * 
 * @param client    The client transmitting.
 * @param target    The client interpreting.
 * @param chr       The character to add.
 */
Interpreter_AddInterpretedChar(client, target, chr)
{
    // Add a character to the end, and set the next character to null terminator.
    // If we don't then we'll overwrite \0 and uncover garbage.
    new length = strlen(g_strInterpreted[target][client]);
    g_strInterpreted[target][client][length] = chr;
    g_strInterpreted[target][client][length + 1] = 0;
}

/**
 * Display interpreted characters to client.
 * 
 * @param client    The client to print interpreted characters to.
 */
Interpreter_Display(client)
{
    new String:hinttext[128] = "Interpreter:";
    new startindex;
    decl String:truncated[16];
    for (new transmitter = 0; transmitter < sizeof(g_strInterpreted[]); transmitter++)
    {
        // Haven't interpreted any morse code from this client.
        if (g_strInterpreted[client][transmitter][0] == 0)
            continue;
        
        startindex = strlen(g_strInterpreted[client][transmitter]) - sizeof(truncated);
        if (startindex < 0)
            startindex = 0;
        strcopy(truncated, sizeof(truncated), g_strInterpreted[client][transmitter][startindex]);
        
        if (startindex == 0)
        {
            Format(hinttext, sizeof(hinttext), "%s\n%N: %s", hinttext, transmitter, truncated);
        }
        else
        {
            Format(hinttext, sizeof(hinttext), "%s\n%N: ...%s", hinttext, transmitter, truncated);
        }
    }
    
    PrintHintText(client, hinttext);
    StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
}

/**
 * A client just transmitted a char via morse code.
 * 
 * @param client    The client transmitting the char.
 */
Interpreter_OnTransmittedChar(client)
{
    if (!GetConVarBool(g_hCvarInterpret))
        return;
    
    new Float:vecClientLoc[3];
    GetClientAbsOrigin(client, vecClientLoc);
    
    new Float:vecTargetLoc[3];
    for (new target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;
        
        if (client == target)
            continue;
        
        if (!IsPlayerAlive(target))
            continue;
        
        GetClientAbsOrigin(target, vecTargetLoc);
        if (GetVectorDistance(vecClientLoc, vecTargetLoc) <= CVAR_RADIUS)
        {
            Interpreter_AddInterpretedChar(client, target, MorseCode_Interpret(g_strScript[client][g_iCurScriptIndex[client]]));
            Interpreter_Display(target);
        }
    }
}

/**
 * A client just finished transmitting a char via morse code.
 * 
 * @param client    The client that finished transmitting.
 */
Interpreter_OnTransmissionEnded(client)
{
    if (!GetConVarBool(g_hCvarInterpret))
        return;
    
    // Print interpreted characters to chat.
    for (new target = 1; target <= MaxClients; target++)
    {
        if (IsClientInGame(target) && IsPlayerAlive(target))
        {
            if (g_strInterpreted[target][client][0] != 0)
            {
                MorseCode_PrintGameMessage(client, target, g_strInterpreted[target][client]);
            }
        }
        
        // Clear interpeted text.
        strcopy(g_strInterpreted[target][client], sizeof(g_strInterpreted[][]), "");
    }
}

// **********************************************
//                 SDKCalls
// **********************************************

/**
 * Check if the client's flashlight is turned on. (CS:S)
 * 
 * @param client    The client index.
 * 
 * @return          True if the light is on, false if off.
 */
stock bool:MorseCode_FlashlightIsOn(client)
{
    return bool:SDKCall(g_hFlashlightIsOn, client);
}

/**
 * Force a client's flashlight on. (CS:S)
 * 
 * @param client    The client index.
 */
stock MorseCode_FlashlightTurnOn(client)
{
    SDKCall(g_hFlashlightTurnOn, client);
}

/**
 * Force a client's flashlight off. (CS:S)
 * 
 * @param client    The client index.
 */
stock MorseCode_FlashlightTurnOff(client)
{
    SDKCall(g_hFlashlightTurnOff, client);
}

// **********************************************
//                 Utilities
// **********************************************

/**
 * Closes a handle and sets it to invalid handle.
 * 
 * @param handle    The handle to close.
 */
stock Util_CloseHandle(&Handle:handle)
{
    if (handle != INVALID_HANDLE)
    {
        CloseHandle(handle);
        handle = INVALID_HANDLE;
    }
}
