#include <sourcemod>   
#include <socket>   

new Handle:hSockets[MAXPLAYERS + 1];  
new Handle:hDataPack[MAXPLAYERS + 1];  

#define PLUGIN_VERSION "5.0"

public Plugin:myinfo =  {  
    name = "Community Server Bans (CSB)",   
    author = "Vortéx!",   
    description = "Bu sunucusu CSB ile birlikte çalışmaktadır!",   
    version = PLUGIN_VERSION,   
    url = "http://csb.sourceturk.net/"  
};  

public OnPluginStart()
{
	CreateConVar("sm_csb_version", PLUGIN_VERSION, "Community Server Bans Version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY);
}

public OnSocketConnected(Handle:socket, any:hPack)  
{  
    decl String:requestStr[100], String:sSteamID[32];  
    ResetPack(hPack);  
    ReadPackString(hPack, sSteamID, 32);  
    Format(requestStr, sizeof(requestStr), "GET /kontrol.php?id=%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", sSteamID, "csb.sourceturk.net");  
    SocketSend(socket, requestStr);  
}  

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hPack)  
{  
    TrimString(receiveData);  
    if (StrContains(receiveData, "temiz", false) == -1)  
    {  
        decl String:sSteamID[32];  
        ResetPack(hPack);  
        ReadPackString(hPack, sSteamID, 32);  
        new client = GetClientFromSteamID(sSteamID);  
        if(client != -1)  
        { 
            KickClientEx(client, "Hile kullandığınız için CSB tarafından yasaklandınız. Daha fazla bilgi için csb.sourceturk.net adresini ziyaret edin");  
        } 
    }  
}  

public OnClientPostAdminCheck(client)  
{  
    decl String:charauth[32];  
    GetClientAuthId(client, AuthId_Steam2, charauth, sizeof(charauth));  
      
    hDataPack[client] = CreateDataPack();  
    WritePackString(hDataPack[client], charauth);  
      
    hSockets[client] = SocketCreate(SOCKET_TCP, OnSocketError);  
    SocketConnect(hSockets[client], OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "csb.sourceturk.net", 80);  
    SocketSetArg(hSockets[client], hDataPack[client]);  
}  

public OnSocketDisconnected(Handle:socket, any:hPack)  
{  
    CloseHandle(hPack);  
    CloseHandle(socket);  
}  

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hPack)  
{  
    LogError("Oyuncu CSB sistemine baglanti kuramadi, bu onemli bir hata degildir. Sorun yoktur. Hata tipi: %d - Hata no: %d)", errorType, errorNum);  
    CloseHandle(hPack);  
    CloseHandle(socket);  
}  

public OnConfigsExecuted()  
{  
    TagsCheck("csb");  
}  

TagsCheck(const String:tag[])  
{  
    new Handle:hTags = FindConVar("sv_tags");  
      
    decl String:tags[255];  
    GetConVarString(hTags, tags, sizeof(tags));  
      
    if (StrContains(tags, tag, false) == -1)  
    {  
        decl String:newTags[255];  
        Format(newTags, sizeof(newTags), "%s,%s", tag, tags);  
        SetConVarString(hTags, newTags);  
    }  
      
    CloseHandle(hTags);  
}   

public GetClientFromSteamID(const String:sSteamID[])  
{  
    for (new i = 1; i <= MaxClients; i++)  
    {  
        if (IsClientInGame(i) && !IsFakeClient(i))  
        {  
            decl String:sID[32];  
            GetClientAuthId(i, AuthId_Steam2, sID, sizeof(sID));  
            if (StrEqual(sID, sSteamID, false))  
                return i;  
        }  
    }  
    return -1;  
}
