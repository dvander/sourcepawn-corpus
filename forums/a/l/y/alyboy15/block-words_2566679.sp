#include <sourcemod>
#include <csgocolors>

#define tag "BAD WORD"

char g_sBlockedWords[][200] = {"kround", "alied", "indungi", "laleagane", "hardware", "1tap", "redfear", "evict", "mevid", "alphacs", "word10", "word11", "word11", "word12", "gg ez"};

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {

    if(client < 1 || client > MaxClients)
        return Plugin_Continue;
        
    if (!IsClientInGame(client))
        return Plugin_Continue;
        
    for(int i = 0; i < sizeof(g_sBlockedWords[]); i++) {
    
        if(StrContains(sArgs, g_sBlockedWords[i]) != -1) {
        
            CPrintToChat(client, "{default}[{orange} %s {default}]The word {green}%s {default}is {red}blocked{default}!", tag, g_sBlockedWords[i]);
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;

}