#include <sourcemod>
#include <sdktools>
#pragma newdecls required
#pragma semicolon 1

int pressedE[MAXPLAYERS+1];
float lastPressed[MAXPLAYERS+1];
bool blocked[MAXPLAYERS+1];

public Plugin myinfo = 
{
    name = "DoorSpam Block",
    author = "Rodipm & Krim - fix by Niko",
    description = "Prevents clients from spamming E (use)",
    version = "1.1",
    url = "https://forums.alliedmods.net/showthread.php?t=170214"
}

public void OnPluginStart()
{
    HookEvent("round_start", roundStart);
}

public Action roundStart(Handle event, const char[] Name, bool dontBroadcast)
{
    int max = GetMaxEntities();
    for(int i = 1; i <= max; i++)
    {
        if(IsValidEdict(i))
        {
            char name[90];
            GetEdictClassname(i, name, sizeof(name));
            
            if(StrContains(name, "door_rotating") != -1)
            {
                HookSingleEntityOutput(i, "OnOpen", Open);
            }
        }
    }
}

public void Open(const char[] output, int door, int client, float delay)
{
    if (!(client < MAXPLAYERS+1 && IsValidClient(client)))
        return;
        
    if(!pressedE[client])
    {
        pressedE[client] = 1;
        lastPressed[client] = GetGameTime();
    }
    else if(pressedE[client] >= 1)
    {
        if(lastPressed[client] >= GetGameTime()-3)
        {
            pressedE[client]++;
            
            if(pressedE[client] == 5)
            {
                blocked[client] = true;
                CreateTimer(5.0, Allow, client);
                PrintToChat(client,"\x04[DoorBlock \x01By.:RpM\x04]\x03 You can't use \"E\" for 5 seconds!"); 
            }
        }
        else
        {
            pressedE[client] = 1;
        }
    }
}

public Action Allow(Handle Timer, any client)
{
    blocked[client] = false;
    PrintToChat(client,"\x04[DoorBlock \x01By.:RpM\x04]\x03 You can use \"E\" again!"); 
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if(blocked[client])
    {
        buttons &= ~IN_USE;
    }
}

stock bool IsValidClient(int client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client))
    {
        return false; 
    }
    return IsClientInGame(client); 
}