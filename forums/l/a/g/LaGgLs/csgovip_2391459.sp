#include <sourcemod> 
#include <sdktools> 
#include <clientprefs> 
#include <scp> 
#include <morecolors> 

#define PLUGIN_AUTHOR "Arkarr" 
#define PLUGIN_VERSION "1.00" 
#define PLUGIN_TAG "{pink}[Silence]{default}" 

Handle ClientCookie_GagStatus; 
bool clientGaged[MAXPLAYERS+1]; 
bool timed[MAXPLAYERS+1]; 

public Plugin myinfo =  
{ 
    name = "[ANY] Cookie Gag", 
    author = PLUGIN_AUTHOR, 
    description = "Gag players and remember about their gag status.", 
    version = PLUGIN_VERSION, 
    url = "http://www.sourcemode.net" 
}; 

public void OnPluginStart() 
{ 
    RegConsoleCmd("sm_silence", CMD_Silence, "Gag a client using cookies to remember there status.", ADMFLAG_CHAT); 
    RegConsoleCmd("sm_unsilence", CMD_Unsilence, "Gag a client using cookies to remember there status.", ADMFLAG_CHAT); 
     
    ClientCookie_GagStatus = RegClientCookie("sm_cookiegag_client_status", "The status of the gag.", CookieAccess_Private); 
     
    for (new i = MaxClients; i > 0; --i) 
    { 
        if (!AreClientCookiesCached(i)) 
        { 
            continue; 
        } 
         
        OnClientCookiesCached(i); 
       } 
    LoadTranslations("common.phrases"); 
} 

public void OnClientDisconnect(client) 
{ 
    if(clientGaged[client] && !timed[client]) 
        SetClientCookie(client, ClientCookie_GagStatus, "GAGED"); 
    else 
        SetClientCookie(client, ClientCookie_GagStatus, "UNGAGED"); 
} 

public void OnClientCookiesCached(client) 
{ 
    char statusValue[8]; 
    GetClientCookie(client, ClientCookie_GagStatus, statusValue, sizeof(statusValue)); 
     
    if(StrEqual(statusValue, "GAGED")) 
    { 
        clientGaged[client] = true; 
        SetClientListeningFlags(client, VOICE_MUTED); 
    } 
    else 
    { 
        clientGaged[client] = false; 
        SetClientListeningFlags(client, VOICE_NORMAL); 
    } 
}  
    
public Action OnChatMessage(&author, Handle:recipients, String:name[], String:message[]) 
{ 
    if(clientGaged[author]) 
        return Plugin_Stop; 
         
    return Plugin_Continue; 
} 

public Action CMD_Silence(client, args) 
{ 
    char length[10]; 
    char strTarget[20]; 
    float time = 0.0; 
     
    if(args == 0) 
    { 
        ReplyToCommand(client, "Usage : sm_silence [TARGET] <time>"); 
         
        return Plugin_Handled; 
    } 

    GetCmdArg(1, strTarget, sizeof(strTarget)); 
    int target = FindTarget(client, strTarget, true); 
     
    if(args >= 2) 
    { 
        GetCmdArg(2, length, sizeof(length)); 
        time = StringToFloat(length); 
    } 
     
    if(target != -1) 
    { 
        clientGaged[target] = true; 
        SetClientListeningFlags(target, VOICE_MUTED); 
         
        if(time != 0.0) 
        { 
            CPrintToChatAll("%s %N has been silenced for %.0f minute(s) sucessfully !", PLUGIN_TAG, target, time); 
            time *= 60; 
            timed[target] = true; 
            CreateTimer(time, TMR_UngagClient, target); 
        } 
        else 
        { 
            CPrintToChatAll("%s %N has been silenced sucessfully !", PLUGIN_TAG, target); 
        } 
    } 
         
    return Plugin_Handled; 
} 

public Action CMD_Unsilence(client, args) 
{ 
    char strTarget[20]; 
     
    if(args == 0) 
    { 
        CPrintToChat(client, "%s Usage : sm_unsilence [TARGET] <time>", PLUGIN_TAG); 
         
        return Plugin_Handled; 
    } 

    GetCmdArg(1, strTarget, sizeof(strTarget)); 
    int target = FindTarget(client, strTarget, true); 
     
    if(target != -1) 
    { 
        clientGaged[target] = false; 
        SetClientListeningFlags(target, VOICE_NORMAL); 
        CPrintToChatAll("%s %N has been unsilenced sucessfully !", PLUGIN_TAG, target); 
    } 
         
    return Plugin_Handled; 
} 
     
public Action TMR_UngagClient(Handle tmr, any client) 
{ 
    clientGaged[client] = false; 
    timed[client] = false; 
    SetClientListeningFlags(client, VOICE_NORMAL); 
     
    return Plugin_Continue; 
}