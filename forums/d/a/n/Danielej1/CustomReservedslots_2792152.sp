#include <sourcemod>
#include <PTaH>

#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0

#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))

#define MAX_SERVER_SLOTS 12

public Plugin myinfo = 
{
    name = "CustomReservedslots",
    author = "Trum",
    description = "Allow VIP & Admins to join full servers, kick normal players to let a free slot for VIP",
    version = "1.0",
    url = ""
}

public void OnClientPostAdminCheck(int client)
{
    int iPlayers = 0;

    LoopValidClients(i)
        iPlayers++;
    
    if(iPlayers >= MAX_SERVER_SLOTS)
    {
        if(!IsValidClient(client))
            return;

        if(!CheckCommandAccess(client, "", ADMFLAG_CUSTOM1, true) && !CheckCommandAccess(client, "", ADMFLAG_BAN, true))
        {
            CreateTimer(0.1, OnTimedKickForReject, GetClientUserId(client));
        }
        else if(CheckCommandAccess(client, "", ADMFLAG_CUSTOM1, true))
        {
            int time = 0x7fffffff;
            int lastConnectedClient;

            for(int i = 1; i <= MaxClients; i++)
            {
                if(IsValidClient(i) && !CheckCommandAccess(i, "", ADMFLAG_CUSTOM1, true) && !CheckCommandAccess(i, "", ADMFLAG_BAN, true))
                {
                    if(time > GetClientTime(i))
                    {
                        time = GetClientTime(i);

                        lastConnectedClient = i;
                    }
                }
            }

            if(!CheckCommandAccess(client, "", ADMFLAG_BAN, true))
                KickClient(lastConnectedClient, "Zostales Wyrzucony Z Powodu Zarezerwowanego Slota Dla VIP'a\n\nKup Vipa Aby Miec Dostep do Pelnego Serwera!\n\nDiscord: https://discord.gg/ZXtphTeY7Z");
        }
    }
}

public Action OnTimedKickForReject(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;

    KickClient(client, "%s", "Ten Serwer Jest Pelny.\n\nKup Vipa Aby Miec Dostep do Pelnego Serwera!\n\nDiscord: https://discord.gg/ZXtphTeY7Z");

    return Plugin_Handled;
}

public bool IsValidClient(int client)
{
    return ((0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client));
} 