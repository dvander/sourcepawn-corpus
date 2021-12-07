#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0.0"

//////////////////////////// PLUGIN INFO ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////// 

public Plugin:myinfo = 
{
    name        = "Funrounds",
    author      = "haN",
    description = "Ability to trigger funrounds",
    version     = PL_VERSION
    url         = "www.sourcemod.net"
};

//////////////////////////// GLOBAL VARIABLES ////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

new g_CurrentRound = 0;
new g_NextRound = 0;

new const String:Rounds[][] = {"Knife Round", "1HP Knife Round", "Pistol Round", "Shotgun Round", "1HP Flashbang Round", "1HP MachineGun Round", "Scout Round", "TMP/MAC10 Round", "1000HP Round", "HE Grenades Round"};

//////////////////////////// MAIN FUNCTIONS ////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

public OnPluginStart()
{
    RegAdminCmd("sm_funrounds", funCommand, ADMFLAG_GENERIC);
    HookEvent("round_end", EventRoundEnd);
    HookEvent("round_start", EventRoundStart);
    HookEvent("flashbang_detonate", EventFlashbangDetonate);
    HookEvent("hegrenade_detonate", EventHegrenadeDetonate);
    HookEvent("player_blind", EventPlayerBlind);
    HookEvent("player_spawn", EventPlayerSpawn);
}

public Action:funCommand(client, args)
{
    SendAdminPanel(client);
}

//////////////////////////// EVENTS ////////////////////////////////////
//////////////////////////////////////////////////////////////////////// 

public EventRoundStart(Handle:event, const String:name[], bool dontBroadcast)
{   
    switch (g_CurrentRound)
    {
        case 1: ServerCommand("sm_restrict all");
                PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x02Knife Round !!!");
        
        case 2: ServerCommand("sm_restrict all");
                PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x021HP Knife Round !!!");
        
        case 3: ServerCommand("sm_restrict all");
                PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x02Pistols Round !!!");
        
        case 4: ServerCommand("sm_restrict all");
                ServerCommand("sm_unresctrict weapon_m3");
                PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x02Shotgun Round !!!");
                
        case 5: ServerCommand("sm_restrict all");
                ServerCommand("sm_unrestrict weapon_flashbang");
                PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x02Flashbang Round !!!");
                
        case 6: ServerCommand("sm_restrict all");
                ServerCommand("sm_unresctrict weapon_m249");
                PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x02Machine Gun Round !!!");
                
        case 7: ServerCommand("sm_restrict all");
                ServerCommand("sm_unrestrict weapon_scout");
                PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x02Scout Round !!!");
                
        case 8: ServerCommand("sm_restrict all");
                ServerCommand("sm_unrestrict weapon_tmp");
                ServerCommand("sm_unrestrict weapon_mac10");
                PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x02TMP/MAC10 Round !!!");
        
        case 9: break;
        
        case 10: ServerCommand("sm_restrict all");
                 ServerCommand("sm_unrestrict weapon_hegrenade");
                 PrintChatToAll("\x04[Funrounds] \x01 Funround Starting : \x02HE GRENADE Round !!!");       
    }
    
}

public EventRoundEnd(Handle:event, const String:name[], bool dontBroadcast)
{
    g_CurrentRound = g_NextRound;
    g_NextRound = 0;
}

public EventFlashbangDetonate(Handle:event, const String:name[], bool dontBroadcast)
{
    if (g_CurrentRound == 5)
    {
        new String:userid = GetEventString(event, "userid");
        new client = GetClientOfUserId(userid);
        GivePlayerItem(client, "weapon_flashbang");
    }
    
}

public EventHegrenadeDetonate(Handle:event, const String:name[], bool dontBroadcast)
{
    if (g_CurrentRound == 10)
    {
        new String:userid = GetEventString(event, "userid");
        new client = GetClientOfUserId(userid);
        GivePlayerItem(client, "weapon_hegrenade");
    }
}

public EventPlayerBlind(Handle:event, const String:name[], bool dontBroadcast)
{
    if (g_Current == 5)
    {
        new String:userid = GetEventString(event, "userid");
        new client = GetClientOfUserId(userid);
        SetEntProp(client, Prop_Send, "m_flFlashDuration", 0);
    }
}

public EventPlayerSpawn(Handle:event, const String:name[], bool dontBroadcast)
{
    new String:userid = GetEventString(event, "userid");
    new client = GetClientOfUserId(userid);
    
    switch (g_CurrentRound)
    {
        case 1: break;
        
        case 2: SetEntityHealth(client, 1);
        
        case 3: break;
        
        case 4: GivePlayerItem(client, "weapon_m3");
                
        case 5: GivePlayerItem(client, "weapon_flashbang");
                
        case 6: GivePlayerItem(client, "weapon_m249");
                
        case 7: GivePlayerItem(client, "weapon_scout");
                
        case 8: break;
        
        case 9: SetEntHealth(client, 1000);
        
        case 10: GivePlayerItem(client, "weapon_hegrenade");  
    } 
}

//////////////////////////// MENUS / HANDLERS ////////////////////////////////////
//////////////////////////////////////////////////////////////////////// 

private SendAdminPanel(client)
{
    new Handle:panel = CreatePanel();
    SetPanelTitle(panel, "Funrounds Menu\n");
    
    for (int i = 0; i < 10; i++)
    {
        SetPanelCurrentKey(panel, i+1);
        DrawPanelItem(panel, Rounds[i]);    
    }
    
    SetPanelCurrentKey(panel, 0);
    DrawPanelItem(panel, "\nExit");
    
    SentPanelToClient(panel, client, funMenuHandler, 20);
    
    CloseHandle(panel); 
    
}

public funMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        switch(param2)
        {
            for (int i = 1; i <= 11; i++)
            {
                case i: g_NextRound = i;
            }
        }
    }
}