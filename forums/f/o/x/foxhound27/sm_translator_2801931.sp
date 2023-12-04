#include <sourcemod>
#include <ripext>
#include <regex>

#define CVAR_FLAGS          FCVAR_NOTIFY

ConVar Display_Type;
int Mode;

public Plugin myinfo = {
  name = "SM Translator",
  author = "FOXHOUND",
  description = "Translator for the people",
  version = "1.0"
}


char g_LangCodes[][] =
{
    "ar",    // Arabic
    "de",    // German
    "en",    // English
    "es",    // Spanish
    "fr",    // French
    "it",    // Italian
    "ja",    // Japanese
    "ko",    // Korean
    "nl",    // Dutch
    "pl",    // Polish
    "pt",    // Portuguese
    "ru",    // Russian
    "sv",    // Swedish
    "bg",    // Bulgarian
    "tl",    // Tagalog
    "tr",    // Turkish
}


public void OnPluginStart() {

    Display_Type = CreateConVar("sm_translator_display", "1", "0 = Console, 1 = Chat", CVAR_FLAGS);

    Mode = Display_Type.IntValue;

    HookConVarChange(Display_Type, Display_Type_Changed);

    for (int i = 0; i < sizeof(g_LangCodes); i++) {
        for (int j = 0; j < sizeof(g_LangCodes); j++) {
            if (i == j) continue;

            char langCode[5];
            Format(langCode, sizeof(langCode), "%s%s", g_LangCodes[i], g_LangCodes[j]);

            RegConsoleCmd(langCode, Cmd_Translate, "SM rokz");

        }
    }
}

void Display_Type_Changed(Handle hVariable, const char[] strOldValue, const char[] strNewValue) {
    Mode = StringToInt(strNewValue);

}


Action Cmd_Translate(int client, int args) {
    char cmd[5],arg[255],primaryLang[3],subLang[3];
    GetCmdArg(0, cmd, sizeof(cmd));

    GetCmdArgString(arg, sizeof(arg));

    Format(primaryLang, sizeof(primaryLang), "%c%c", cmd[0], cmd[1]);
    Format(subLang, sizeof(subLang), "%c%c", cmd[2], cmd[3]);

    Translate(client, primaryLang,subLang,arg);

    return Plugin_Handled;
}

void Translate(int client, const char[] from, const char[] to, char[] input){

    char api[1024];
    StripQuotes(input);
    ReplaceString(input, 255, "\x20", "%20", false);
    
    Format(api, sizeof(api), "\x68\x74\x74\x70\x3a\x2f\x2f\x74\x72\x61\x6e\x73\x6c\x61\x74\x65\x2e\x67\x6f\x6f\x67\x6c\x65\x61\x70\x69\x73\x2e\x63\x6f\x6d\x2f\x74\x72\x61\x6e\x73\x6c\x61\x74\x65\x5f\x61\x2f\x73\x69\x6e\x67\x6c\x65\x3f\x63\x6c\x69\x65\x6e\x74\x3d\x67\x74\x78\x26\x73\x6c\x3d\x25\x73\x26\x74\x6c\x3d\x25\x73\x26\x64\x74\x3d\x74\x26\x71\x3d\x25\x73", from, to, input);
    

    char txtPath[PLATFORM_MAX_PATH],cpath[PLATFORM_MAX_PATH];
    Format(cpath, sizeof(cpath), "data/sm_translator_%d.txt", client);
    BuildPath(Path_SM, txtPath, sizeof(txtPath), cpath);

    HTTPRequest request = new HTTPRequest(api);
    request.DownloadFile(txtPath, ProcessString, client);

}


void ProcessString(HTTPStatus status, any client) {
    if (status != HTTPStatus_OK) {
        // Download failed
        return;
    }

    //PrintToServer("OK");

    char textPath[PLATFORM_MAX_PATH],cpath[PLATFORM_MAX_PATH];

    Format(cpath, sizeof(cpath), "data/sm_translator_%d.txt", client);
    BuildPath(Path_SM, textPath, sizeof(textPath), cpath);
    

    File file = OpenFile(textPath, "r");
    if (!file) {
        LogError("Could not open file");
        delete file;
        return;
    }

    char response[1024];

    file.ReadString(response, sizeof(response));

    delete file;

    Regex regex = new Regex("\"([^\"]*)\"");
    RegexError err;

    if (regex.Match(response) > 0) {
        char output[256];
        regex.GetSubString(1, output, sizeof(output));
        Mode && client!=0 ? PrintToChat(client, ">> %s", output):PrintToConsole(client, ">> %s", output);
    } else if (err != REGEX_ERROR_NONE) {
        PrintToServer("Regex error: %d", err);
    } else {
        PrintToServer("No match found");
    }
}