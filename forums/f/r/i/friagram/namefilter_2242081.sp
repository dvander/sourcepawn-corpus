#include <sdktools>
#include <regex>

#define PLUGIN_VERSION "1.0.0"

#define CONFIG_FILE "configs/namefilter.txt"

new Handle:gh_goodNames = INVALID_HANDLE;
new Handle:gh_bannedExpressions = INVALID_HANDLE;
new Handle:gh_RegExReplace = INVALID_HANDLE;
new String:g_filterchar[2] = "*";

public Plugin:myinfo =
{
    name = "Name Filter",
    author = "Friagram",
    description = "Filters Names",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/poniponiponi"
}

public OnPluginStart()
{
    RegAdminCmd("sm_reloadnames", Command_ReloadConfig, ADMFLAG_RCON);

    gh_goodNames = CreateArray(ByteCountToCells(MAX_NAME_LENGTH));
    gh_bannedExpressions = CreateArray();
}

public Action:Command_ReloadConfig(client, args)
{
    InitiateConfig();
    ReplyToCommand(client, "Reloaded: %s (%d ban expressions) (%d names)", CONFIG_FILE, GetArraySize(gh_bannedExpressions), GetArraySize(gh_goodNames));
    return Plugin_Handled;
}
public OnMapStart()
{
    InitiateConfig();
    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i))
        {
            FindCharsInName(i);
        }
    }
}

InitiateConfig()
{
    new Handle:Kv = CreateKeyValues("filters");

    decl String:filepath[256];
    BuildPath(Path_SM, filepath, sizeof(filepath), CONFIG_FILE);

    if (!FileToKeyValues(Kv, filepath))
    {
        CloseHandle(Kv);
        SetFailState("Cannot find file \"%s\"!", filepath);
    }
    else
    {
        decl String:buffer[256];
        new String:sError[256], RegexError:iError;
        decl Handle:regex;
        decl String:item[4];

        KvGetString(Kv, "censor", g_filterchar, 2, "*");
        KvGetString(Kv, "filter", buffer, 256);

        if(gh_RegExReplace != INVALID_HANDLE)
        {
            CloseHandle(gh_RegExReplace);
        }
        
        gh_RegExReplace = CompileRegex(buffer, PCRE_CASELESS|PCRE_UTF8, sError, sizeof(sError), iError);
        if (iError != REGEX_ERROR_NONE)
        {
            CloseHandle(Kv);
            SetFailState(sError);
        }

        new size = GetArraySize(gh_bannedExpressions);
        for (new i=0; i < size; i++)
        {
            CloseHandle(GetArrayCell(gh_bannedExpressions, i));
        }
        ClearArray(gh_bannedExpressions);
        if(KvJumpToKey(Kv, "banned"))
        {
            for(new i=1;; i++)
            {
                IntToString(i, item, 4);
                KvGetString(Kv, item, buffer, 256);
                if(buffer[0] == '\0')
                {
                    break;
                }
                regex = CompileRegex(buffer, PCRE_CASELESS, sError, sizeof(sError), iError);            // i'm not checking for utf8 here, it's mostly for bad words
                if (iError != REGEX_ERROR_NONE)
                {
                    LogError("Error parsing banned filter: %s", sError);
                }
                else
                {
                    PushArrayCell(gh_bannedExpressions, regex);
                }
            }
            KvGoBack(Kv);
        }

        ClearArray(gh_goodNames);
        if(KvJumpToKey(Kv, "names"))
        {
            for(new i=1;; i++)
            {
                IntToString(i, item, 4);
                KvGetString(Kv, item, buffer, MAX_NAME_LENGTH);
                if(buffer[0] == '\0')
                {
                    break;
                }
                TerminateNameUTF8(buffer);
                PushArrayString(gh_goodNames, buffer);
            }
            KvGoBack(Kv);
        }
        if(!GetArraySize(gh_goodNames))
        {
            LogError("Warning, you have no replacement names available");
            PushArrayString(gh_goodNames, "Bad_Name");
        }

        CloseHandle(Kv);
    }
}
FindCharsInName(client)
{
    decl String:buffer[256];
    decl String:match[MAX_NAME_LENGTH];
    decl banned;
    new bool:change;
    new String:sError[256], RegexError:iError;
    
    GetClientName(client, buffer, MAX_NAME_LENGTH);

    new filter = MatchRegex(gh_RegExReplace, buffer, iError);
    if (iError != REGEX_ERROR_NONE)
    {
        LogError(sError);
    }
    else if(filter > 0)
    {
        for(new i; i<filter; i++)
        {
            GetRegexSubString(gh_RegExReplace, i, match, MAX_NAME_LENGTH);
            ReplaceString(buffer, 256, match, g_filterchar);
            change = true;
        }
    }

    new size = GetArraySize(gh_bannedExpressions);
    for(new i; i<size; i++)                                                                                             // check if the now censored name has banned expressions
    {
        banned = MatchRegex(GetArrayCell(gh_bannedExpressions, i), buffer, iError);
        if (iError != REGEX_ERROR_NONE)
        {
            LogError(sError);
        }
        else if(banned > 0)                                                   // it does
        {
            GetArrayString(gh_goodNames, GetRandomInt(0, GetArraySize(gh_goodNames)), match, MAX_NAME_LENGTH);       // select random namefilter
            CS_SetClientName(client, match);
            return;
        }
    }

    if(change)
    {
        if(strlen(buffer) < 2)
        {
            GetArrayString(gh_goodNames, GetRandomInt(0, GetArraySize(gh_goodNames)-1), match, MAX_NAME_LENGTH);      // give them a random name if too many characters got eliminated
            CS_SetClientName(client, match);
            return;
        }

        strcopy(match, MAX_NAME_LENGTH, buffer);
        TerminateNameUTF8(match);
        CS_SetClientName(client, match);
    }
}

public OnClientPutInServer(client)
{
    if(!IsFakeClient(client))
    {
        FindCharsInName(client);
    }
}

public OnClientSettingsChanged(client)
{
    if(IsClientInGame(client) && !IsFakeClient(client))
    {
        FindCharsInName(client);
    }
}

stock TerminateNameUTF8(String:name[])                // ensures that utf8 names are properly terminated
{ 
    new len = strlen(name); 
     
    for (new i = 0; i < len; i++) 
    { 
        new bytes = IsCharMB(name[i]); 
         
        if (bytes > 1) 
        { 
            if (len - i < bytes) 
            { 
                name[i] = '\0'; 
                return; 
            } 
             
            i += bytes - 1; 
        } 
    } 
}  

stock CS_SetClientName(client, const String:name[])     // Mitchell
{
    decl String:oldname[MAX_NAME_LENGTH];
    GetClientName(client, oldname, MAX_NAME_LENGTH);

    LogMessage("Renaming %L - from (%s) to (%s)", client, oldname, name);

    SetClientInfo(client, "name", name);
    SetEntPropString(client, Prop_Data, "m_szNetname", name);

    new Handle:event = CreateEvent("player_changename");
    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(client));
        SetEventString(event, "oldname", oldname);
        SetEventString(event, "newname", name);
        FireEvent(event);
    }
}