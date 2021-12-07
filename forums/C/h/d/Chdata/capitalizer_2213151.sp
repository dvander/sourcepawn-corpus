/*
    Automagically capitalizes the first word of players' messages.
    By: Chdata
*/

#pragma semicolon 1
#include <sourcemod>
#include <scp>

#define PLUGIN_VERSION "0x06"

public Plugin:myinfo = {
    name = "Capitalizer",
    author = "Chdata",
    description = "Capitalizes the first word of any sentence.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

static Handle:g_cvLowerCaseOther;

public OnPluginStart()
{
    CreateConVar("cv_capitalizer_version", PLUGIN_VERSION, "Capitalizer Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);
    g_cvLowerCaseOther = CreateConVar(
        "cv_capitalizer_lower", "0",
        "0 = PEOPLE CAN TYPE IN FULL CAPS | 1 = Automagically lowercase other letters",
        FCVAR_NOTIFY,
        true, 0.0, true, 1.0
    );
    AutoExecConfig(true, "ch.capitalizer");
}

public Action:OnChatMessage(&iAuthor, Handle:hRecipients, String:szName[], String:szMessage[])
{
    CapitalizeAll(szMessage, _, GetConVarBool(g_cvLowerCaseOther));
    return Plugin_Changed;
}

/*
    Capitalizes the first word in a string, and the next letter after each punctuation.
    And lowercases everything else if the bool is set true.
*/
stock CapitalizeAll(String:szText[], bool:bCapitalIs = true, bool:bLowerCaseOther = false)
{
    new iLen = strlen(szText);
    new i = 0; while(IsCharSpace(szText[i])){i++;}
    szText[i] = CharToUpper(szText[i]);
    for (++i; i < iLen; i++) //  && szText[i] != '\0'
    {
        if (IsCharPunc(szText[i]) && i+1 < iLen && IsCharSpace(szText[i+1]))
        {
            i++; while(IsCharSpace(szText[i])){i++;}
            szText[i] = CharToUpper(szText[i]);
            continue;
        }
        else if (bCapitalIs && (szText[i] == 'i' || szText[i] == 'I')) // (i-1 == -1 || i+1 == iLen) || 
        {
            if ((IsCharSpace(szText[i-1]) && (i+1 == iLen || IsCharByI(szText[i+1]) || (i+2 < iLen && szText[i+1] == ''' && IsCharAlpha(szText[i+2])))))
            {
                szText[i] = CharToUpper(szText[i]);
                continue;
            }
        }

        if (bLowerCaseOther)
        {
            szText[i] = CharToLower(szText[i]);
        }
    }
}

stock bool:IsCharPunc(chr)
{
    switch(chr)
    {
        case '.', '?', '!':
        {
            return true;
        }
    }
    return false;
}

stock bool:IsCharByI(chr)
{
    return IsCharPunc(chr) || IsCharSpace(chr);
}

/*
    Capitalizes the first word in a string
*/
stock Capitalize(String:szText[])
{
    new i = 0; while(IsCharSpace(szText[i])){i++;}
    szText[i] = CharToUpper(szText[i]);
}
