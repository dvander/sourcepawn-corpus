#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "2.3.0"

public Plugin:myinfo = 
{
    name = "Triggers",
    author = "theY4Kman",
    description = "Advanced commandlist.txt functionality",
    version = PLUGIN_VERSION,
    url = "http://y4kstudios.com/sourcemod/"
};

enum TriggersFlag
{
    trg_None        = 0,
    trg_Rcon        = 1,
    trg_Client      = 1<<1,
    trg_Fake        = 1<<2,
    trg_Say         = 1<<3,
    trg_NoDisplayPlayerMessage = 1<<4,
    trg_NoVariables = 1<<5,
};

new Handle:g_hTriggers;
new g_iRconFlags;

new Handle:g_hHostname;
new Handle:g_hIp;

public OnPluginStart()
{
    // Create our trie
    g_hTriggers = CreateTrie();
    
    // Try opening commandlist.txt first, otherwise use commandlist.cfg
    ReloadTriggers(0, 0);
    
    RegConsoleCmd("say", Trigger);
    RegConsoleCmd("say_team", Trigger);
  
    RegAdminCmd("triggers_reload", ReloadTriggers, ADMFLAG_CONFIG, "Reloads the commandlist", "", FCVAR_PLUGIN);
    CreateConVar("triggers_version", PLUGIN_VERSION, "The version of Triggers installed", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_SPONLY);
    
    new Handle:hRconFlags = CreateConVar("triggers_rcon", "rz");
    if(hRconFlags == INVALID_HANDLE)
        hRconFlags = FindConVar("triggers_rcon");
    
    g_hHostname = FindConVar("hostname");
    g_hIp = FindConVar("ip");
    
    HookConVarChange(hRconFlags, RconFlagsChange);
    
    decl String:sRconFlags[32];
    GetConVarString(hRconFlags, sRconFlags, sizeof(sRconFlags));
    g_iRconFlags = ReadFlagString(sRconFlags);
}

public OnPluginEnd()
{
    CloseHandle(g_hHostname);
    CloseHandle(g_hIp);
    CloseHandle(g_hTriggers);
}

public RconFlagsChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    g_iRconFlags = ReadFlagString(newValue);
}

// Parses a commandlist file
bool:ParseCommandlist(const String:file[] = "commandlist.txt")
{
    decl String:sBuffer[256];
    BuildPath( Path_SM, sBuffer, sizeof(sBuffer), "/configs/%s", file );
    
    new Handle:hConf = OpenFile( sBuffer, "r" );
    
    if( hConf == INVALID_HANDLE )
        return false;
    
    ClearTrie( g_hTriggers );
    
    decl String:sCmd[128]; // Buffer for command
    decl iTemp, iTemp2, iSize; // Integer to store locations of spaces and size of buffer
    new TriggersFlag:iFlags, iRconFlags; // Variables to store flags
    new bool:iRconFlagsSet;
    decl Handle:hDp; // Handle to datapack
    
    while(ReadFileLine(hConf, sBuffer, sizeof(sBuffer))) {
        if( (sBuffer[0] == '/' && sBuffer[1] == '/') || (iTemp = StrContains(sBuffer, " ")) == -1 )
            continue;
        
        // Gotta add the '+ 1' in to account for the NULL
        strcopy(sCmd, iTemp + 1, sBuffer);
        strcopy(sBuffer, sizeof(sBuffer), sBuffer[iTemp+1]);
        
        iTemp2 = StrContains( sBuffer, " " );
        
        // Reset RCON flags
        iRconFlags = 0;
        iRconFlagsSet = false;
        iFlags = StringToFlags( sBuffer, iTemp2, iRconFlags, iRconFlagsSet );
        
        // Remove the newline
        iSize = strlen(sBuffer);
        if(sBuffer[iSize-1] == '\n')
            sBuffer[iSize-1] = '\0';
        
        hDp = CreateDataPack();
        
        WritePackCell( hDp, _:iFlags ); // Flags, duh
        
        /* Cell indicating that RCON flags have been set */
        WritePackCell( hDp, iRconFlagsSet);
        if(iRconFlagsSet)
        {
            WritePackCell( hDp, _:iRconFlags );
        }
        
        WritePackString( hDp, sBuffer[iTemp2+1] ); // Replaced string
        
        SetTrieValue( g_hTriggers, sCmd, hDp );
    }
    
    CloseHandle(hConf);
    
    return true;
}

// Command Trigger
public Action:Trigger(client, args)
{
    decl String:sCmd[256], String:sReplace[256], Handle:hDp;
    new iSindex;
    new TriggersFlag:iFlags; // Flags for the trigger
    new iRconFlags; // RCON flags for the trigger
    
    // Get the command
    if( args >= 2 )
        GetCmdArg(1, sCmd, sizeof(sCmd));
    else {
        GetCmdArgString(sCmd, sizeof(sCmd));
        
        if(StrContains(sCmd, " ") != -1)
            sCmd[StrContains(sCmd, " ")] = '\0';
        
        if(sCmd[0] == '"' && sCmd[strlen(sCmd)-1] == '"')
        {
            iSindex = 1;
            sCmd[strlen(sCmd)-1] = '\0';
        }
    }
    
    StrToLower(sCmd[iSindex]);
    
    if( !(GetTrieValue(g_hTriggers, sCmd[iSindex], hDp) ) || ( hDp == INVALID_HANDLE ) )
        return Plugin_Continue;
    
    iSindex = strlen(sCmd[iSindex]);
    
    // Reuse sCmd to hold the arguments
    GetCmdArgString(sCmd, sizeof(sCmd));
    
    if( sCmd[0] == '"' && sCmd[strlen(sCmd)-1] == '"' )
    {
        sCmd[strlen(sCmd)-1] = '\0';
        strcopy(sCmd, sizeof(sCmd), sCmd[iSindex+1]);
    }
    
    SetPackPosition( hDp, 0 );
    iFlags = TriggersFlag:ReadPackCell( hDp );
    new iRconFlagsSet = ReadPackCell( hDp );
    
    if(iRconFlagsSet)
    {
        iRconFlags = ReadPackCell( hDp );
    }
    else
    {
        iRconFlags = g_iRconFlags;
    }
    
    ReadPackString( hDp, sReplace, sizeof(sReplace) );
    
    // Preprocessing
    if( !(iFlags & trg_NoVariables) )
    {
        decl String:sBuffer[128];
        new iTemp = 0, iSize = strlen(sReplace), iSize2 = 0;
        
        /* Variables:
         * %i - IP of server
         * %s - Steam ID of player
         * %h - Hostname of server
         * %n - Player's name
         * 
         * They are parsed in that order
         */
        
        // When setting iTemp, we leap ahead to whatever iTemp holds (the last format variable found),
        // and the length of the string that replaced the format variable.
        for(; iTemp < iSize; iTemp++)
        {
            if(sReplace[iTemp] != '%')
                continue;
            
            if(iTemp && sReplace[iTemp-1] == '\\')
            {
                strcopy(sReplace[iTemp-1], sizeof(sReplace), sReplace[iTemp]);
                continue;
            }
            
            switch( sReplace[iTemp+1] )
            {
                /* Server IP */
                case 'i':{
                    GetConVarString(g_hIp, sBuffer, sizeof(sBuffer));
                    
                    ReplaceStringEx(sReplace[iTemp], sizeof(sReplace) - iTemp, "%i", sBuffer);
                }
                
                /* Player Steam ID */
                case 's':{
                    GetClientAuthString(client, sBuffer, sizeof(sBuffer));
                    
                    ReplaceStringEx(sReplace[iTemp], sizeof(sReplace) - iTemp, "%s", sBuffer);
                }
                
                /* Server hostname */
                case 'h':{
                    GetConVarString(g_hHostname, sBuffer, sizeof(sBuffer));
                    
                    ReplaceStringEx(sReplace[iTemp], sizeof(sReplace) - iTemp, "%h", sBuffer);
                }
                
                /* Player name */
                case 'n':{
                    GetClientName(client, sBuffer, sizeof(sBuffer));
                    
                    ReplaceStringEx(sReplace[iTemp], sizeof(sReplace) - iTemp, "%n", sBuffer);
                }
                
                /* User ID */
                case 'u':{
                    IntToString(GetClientUserId(client), sBuffer, sizeof(sBuffer));
                    
                    ReplaceStringEx(sReplace[iTemp], sizeof(sReplace) - iTemp, "%u", sBuffer);
                }
                
                /* Custom ConVar */
                case 'c':{
                    /* We add 2 to iTemp because this switch is for iTemp+1 */
                    if(sReplace[iTemp+2] != '{')
                    {
                        break;
                    }
                    
                    decl iFoundEnd;
                    if((iFoundEnd = FindCharInString(sReplace[iTemp+2], '}')) == -1
                        || iFoundEnd <= 1)
                    {
                        break;
                    }
                    
                    /* Length of ConVar name + %c{ + } + NULL
                     * Will be used when replacing stuff in trigger string
                     */
                    new iSizeOfConvar = iFoundEnd+3+1+1;
                    decl String:sConvar[iSizeOfConvar];
                    
                    /* If we copy the string to the fourth position, we can insert
                     * the chars needed to replace without any calls to Format.
                     */
                    strcopy(sConvar[3], iSizeOfConvar-5, sReplace[iTemp+3]);
                    
                    PrintToChatAll("Convar tag: %s", sConvar[3]);
                    new Handle:hConvar = FindConVar(sConvar[3]);
                    
                    if(hConvar == INVALID_HANDLE)
                    {
                        break;
                    }
                    
                    GetConVarString(hConvar, sBuffer, sizeof(sBuffer));
                    
                    /* Replacement format! */
                    sConvar[0] = '%';
                    sConvar[1] = 'c';
                    sConvar[2] = '{';
                    sConvar[iSizeOfConvar-3] = '}';
                    sConvar[iSizeOfConvar-2] = '\0';
                    
                    /* The intricacies of replacing strings are far too detailed
                     * to write my own implementation for this one purpose. It's
                     * better to use more memory (remember, it's only a few damn bytes)
                     * than to write it slower and less bug-tested in Pawn.
                     */
                    ReplaceStringEx(sReplace[iTemp], sizeof(sReplace) - iTemp, sConvar, sBuffer);
                }
                
                default:
                    continue;
            }
            
            iSize2 = strlen(sBuffer);
            iTemp += iSize2-1;
            iSize += iSize2;
        }
    }
    
    // Output
    if( (iFlags & trg_Rcon) && ( iRconFlags == 0 || GetUserFlagBits(client) & iRconFlags ) )
    {
        ServerCommand("%s %s", sReplace, sCmd);
    }
    
    if( (iFlags & trg_Client) )
    {
        ClientCommand(client, "%s %s", sReplace, sCmd);
    }
    
    if( (iFlags & trg_Fake) )
    {
        if( (iFlags & trg_NoDisplayPlayerMessage) )
        {
            FakeClientCommand(client, "%s %s", sReplace, sCmd);
            return Plugin_Handled;
        }
        
        FakeClientCommandEx(client, "%s %s", sReplace, sCmd);
    }
    
    if( (iFlags & trg_Say) )
    {
        if( (iFlags & trg_NoDisplayPlayerMessage) )
        {
            FakeClientCommand(client, "say %s %s", sReplace, sCmd);
            return Plugin_Handled;
        }
        
        FakeClientCommandEx(client, "say %s %s", sReplace, sCmd);
    }
    
    return (iFlags & trg_NoDisplayPlayerMessage) ? Plugin_Handled : Plugin_Continue;
}

public Action:ReloadTriggers(client, args)
{
    new bool:success = false;
    if(args >= 1)
    {
        decl String:file[PLATFORM_MAX_PATH];
        GetCmdArgString(file, sizeof(file));
        
        success = ParseCommandlist(file);
        if(!success)
        {
            ReplyToCommand(client, "Configuration from '%s' failed", file);
            return Plugin_Handled;
        }
    }
    else if( !ParseCommandlist() )
    {
        success = ParseCommandlist("commandlist.cfg");
    }
    
    if(success)
        ReplyToCommand(client, "Configuration loading failed");
    else
        ReplyToCommand(client, "Successfully loaded configuration!");
    
    return Plugin_Handled;
}

TriggersFlag:StringToFlags( const String:sFlags[]="", maxlength=-1, &iRconFlags=0, &iRconFlagsSet=false )
{
    new TriggersFlag:iFlags = trg_None;
    new iStrSize = (maxlength > -1) ? maxlength : strlen(sFlags);
    
    new i;
    for(i = 0; i < iStrSize; ++i)
    {
        switch(sFlags[i])
        {
            /* A command to be processed as an Rcon command */
            case 'R': iFlags |= trg_Rcon;
            
            /* A command to be processed as a client command */
            case 'C': iFlags |= trg_Client;
            
            /* A command to be processed as a fake client command */
            case 'F': iFlags |= trg_Fake;
            
            /* A command to be processed as a fake client command, prepended by "say" */
            case 'S': iFlags |= trg_Say;
            
            /* No variables will be processed in the command */
            case 'v': iFlags |= trg_NoVariables;
            
            /* The message that was said by the player will not be broadcasted */
            case 'd': iFlags |= trg_NoDisplayPlayerMessage;
            
            /* Flags necessary to run this trigger */
            case 'f':
            {
                iRconFlagsSet = true;
                
                if(sFlags[i+1] != '{')
                {
                    break;
                }
                
                i++;
                decl iFoundEnd;
                if((iFoundEnd = FindCharInString(sFlags[i], '}')) == -1
                    || iFoundEnd <= 1)
                {
                    break;
                }
                
                decl String:sRconFlags[iFoundEnd+1];
                strcopy(sRconFlags, iFoundEnd, sFlags[i+1]);
                iRconFlags |= ReadFlagString(sRconFlags);
                
                i += iFoundEnd;
            }
        }
    }
    
    return iFlags;
}

StrToLower( String:string[] )
{
    new size = strlen(string);
    
    for(new i=0; i < size; i++)
        string[i] = CharToLower(string[i]);
}
