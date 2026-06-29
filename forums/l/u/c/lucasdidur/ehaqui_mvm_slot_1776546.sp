#pragma semicolon 1

#include <sourcemod>
#include <connect>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#define PLUGIN_VERSION "0.2"

new Handle:hKickType;

enum KickType
{
    Kick_HighestPing,
    Kick_HighestTime,
    Kick_Random,    
};

public Plugin:myinfo = 
{
    name        = "[Eh Aqui] MvM Slot Manager",
    author      = "Lucas Didur",
    description = "Gerencia os Slots do Servidor, e limita a no max 6 conectado",
    version     = PLUGIN_VERSION,
    url         = "http://ehaqui.com"
}

public OnPluginStart()
{
    CreateConVar("eh_mvm_version", PLUGIN_VERSION, "Eh Aqui] MvM Slot Manager version", FCVAR_NOTIFY|FCVAR_PLUGIN);
    hKickType = CreateConVar("eh_mvm_kicktype", "1", "How to select a client to kick (if appropriate)", 0, true, 0.0, true, 2.0);
    
    RegAdminCmd("eh_playercount", PlayerCount, ADMFLAG_GENERIC); 
    RegAdminCmd("playercount", PlayerCount, ADMFLAG_GENERIC); 
}

public Action:PlayerCount(client, Args)
{    
    PrintToChat(client, "%d", getPlayersCount());
    
    return Plugin_Handled;
}


public bool:OnClientPreConnectEx(const String:name[], String:password[255], const String:ip[], const String:steamID[], String:rejectReason[255])
{   
    if (getPlayersCount() < 6)
    {
        return true;
    }
    
    new AdminId:id = FindAdminByIdentity(AUTHMETHOD_STEAM, steamID);
    if (GetAdminFlag(id, Admin_Reservation))
    {
        new target = SelectKickClient();             
        if (target)
            CreateTimer(0.1, OnTimedKick, target);
        return true;
    }
    else
    {
        strcopy(rejectReason, 255, "MVM Server is full.");
        return false;
    }
}

public Action:OnTimedKick(Handle:timer, any:client)
{    
    if (!client || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }
    
    KickClient(client, "Dropped to due to slot reservation");
    return Plugin_Handled;
}


stock SelectKickClient()
{
    new KickType:type = KickType:GetConVarInt(hKickType);
    
    new Float:highestValue;
    new highestValueId;
    
    new Float:highestSpecValue;
    new highestSpecValueId;
    
    new bool:specFound;
    
    new Float:value;
    

    if(type == Kick_Random)
    {
        highestValueId = GetRandomPlayer();
        
        new flags = GetUserFlagBits(highestValueId);
        if(flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)
            highestValueId = GetRandomPlayer();
    }
    else
    {
        for (new i=1; i<=MaxClients; i++)
        {    
            if (!IsClientConnected(i))
            {
                continue;
            }
            
            new flags = GetUserFlagBits(i);
            if (IsFakeClient(i) || flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)
            {
                continue;
            }
            
            value = 0.0;
                
            if (IsClientInGame(i))
            {
                if (type == Kick_HighestPing)
                {
                    value = GetClientAvgLatency(i, NetFlow_Outgoing);
                }
                else if (type == Kick_HighestTime)
                {
                    value = GetClientTime(i);
                }
                else
                {
                    value = GetRandomFloat(0.0, 100.0);
                }

                if (IsClientObserver(i))
                {            
                    specFound = true;
                    
                    if (value > highestSpecValue)
                    {
                        highestSpecValue = value;
                        highestSpecValueId = i;
                    }
                }
            }
            
            if (value >= highestValue)
            {
                highestValue = value;
                highestValueId = i;
            }
        }
        
        if (specFound)
        {
            return highestSpecValueId;
        }
    }
    
    return highestValueId;
}

stock GetRandomPlayer() 
{
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}  

stock getPlayersCount(bool:bInGameOnly=false, bool:bCountBots=false, bool:bCountReplay=false, bool:bCountSourceTV=false) {
    new iCount;
    for (new i = 1; i <= MaxClients; i++) 
    {
        if (IsClientConnected(i)) 
        {
            if (!bInGameOnly || bInGameOnly && IsClientInGame(i)) 
            {
                if (IsFakeClient(i)) 
                {
                    new bool:bIsReplay = IsClientReplay(i), bool:bIsSourceTV = IsClientSourceTV(i);
                    if (bIsReplay && bCountReplay || bIsSourceTV && bCountSourceTV) 
                    {
                        iCount++;
                    } 
                    else if (bCountBots) 
                    {
                        if (bIsReplay || bIsSourceTV) 
                        {
                            continue;
                        }
                        
                        iCount++;
                    }
                } else {
                    iCount++;
                }
            }
        }
    }
    
    return iCount;
}  





