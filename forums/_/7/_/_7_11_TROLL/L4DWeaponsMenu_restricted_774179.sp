/*
[L4D]TankBuster Weapons Menu Restricted Quota
Modified from [L4D]TankBuster Weapons Menu
Original Author: {7~11} TROLL
Modifications: base64 adminlouie{at}gmail{dot}com
GNU General Public License version 3
*/
#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "2.0.0"
new Handle:g_max_give[11];
new max_give[11]; //array for storing initial quota of each item
new give_quota0[MAXPLAYERS+1]; //quota left (each player) for item 1
new give_quota1[MAXPLAYERS+1]; //quota left (each player) for item 2
new give_quota2[MAXPLAYERS+1]; //quota left (each player) for item 3
new give_quota3[MAXPLAYERS+1]; //quota left (each player) for item 4
new give_quota4[MAXPLAYERS+1]; //quota left (each player) for item 5
new give_quota5[MAXPLAYERS+1]; //quota left (each player) for item 6
new give_quota6[MAXPLAYERS+1]; //quota left (each player) for item 7
new give_quota7[MAXPLAYERS+1]; //quota left (each player) for item 8
new give_quota8[MAXPLAYERS+1]; //quota left (each player) for item 9
new give_quota9[MAXPLAYERS+1]; //quota left (each player) for item 10
new give_quota10[MAXPLAYERS+1]; //quota left (each player) for item 111

public Plugin:myinfo = 
{
    name = "[L4D]TankBuster Weapons Menu",
    author = "{7~11} TROLL, base64",
    description = "Allows Clients To Get Weapons From The Weapon Menu with quota restrictions every round",
    version = PLUGIN_VERSION,
    url = "www.SimpleSourceModz.com, http://smptt.poheart.com"
}

public OnPluginStart()
{
    //Creates a console command
    RegConsoleCmd("tankbuster", TankBusterMenu);
    
    //Quota cvars for each player
    g_max_give[0] = CreateConVar("sm_pumpshotgun_quota", "-1", "Quota given to each player for obtaining pumpshotgun in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[1] = CreateConVar("sm_smg_quota", "-1", "Quota given to each player for obtaining smg in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[2] = CreateConVar("sm_rifle_quota", "-1", "Quota given to each player for obtaining rifle in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[3] = CreateConVar("sm_hunting_rifle_quota", "-1", "Quota given to each player for obtaining hunting_rifle in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[4]= CreateConVar("sm_autoshotgun_quota", "-1", "Quota given to each player for obtaining autoshotgun in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[5] = CreateConVar("sm_pistol_quota", "-1", "Quota given to each player for obtaining pistol in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[6] = CreateConVar("sm_pipe_bomb_quota", "-1", "Quota given to each player for obtaining pipe_bomb in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[7] = CreateConVar("sm_molotov_quota", "-1", "Quota given to each player for obtaining molotov in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[8] = CreateConVar("sm_ammo_quota", "-1", "Quota given to each player for obtaining ammo in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[9] = CreateConVar("sm_pain_pills_quota", "-1", "Quota given to each player for obtaining pain_pills in each round (-1 = unlimited, 0 = disabled)");
    g_max_give[10] = CreateConVar("sm_first_aid_kit_quota", "-1", "Quota given to each player for obtaining first_aid_kit in each round (-1 = unlimited, 0 = disabled)");
    
    //Execute or create cfg
    AutoExecConfig(true, "L4DWeaponsMenu_restricted");
    
    //Hook event
    HookEvent("round_start", Event_round_start);
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{ 
    //Get max clients on server
    new maxclients = GetMaxClients();

    //Get inital quotas from cvars
    max_give[0] = GetConVarInt(g_max_give[0]);
    max_give[1] = GetConVarInt(g_max_give[1]);
    max_give[2] = GetConVarInt(g_max_give[2]);
    max_give[3] = GetConVarInt(g_max_give[3]);
    max_give[4] = GetConVarInt(g_max_give[4]);
    max_give[5] = GetConVarInt(g_max_give[5]);
    max_give[6] = GetConVarInt(g_max_give[6]);
    max_give[7] = GetConVarInt(g_max_give[7]);
    max_give[8] = GetConVarInt(g_max_give[8]);
    max_give[9] = GetConVarInt(g_max_give[9]);
    max_give[10] = GetConVarInt(g_max_give[10]);
    
    //Sets inital quotas for every player
    for (new client = 1; client <= maxclients; client++)
    {
        give_quota0[client] = max_give[0];
        give_quota1[client] = max_give[1];
        give_quota2[client] = max_give[2];
        give_quota3[client] = max_give[3];
        give_quota4[client] = max_give[4];
        give_quota5[client] = max_give[5];
        give_quota6[client] = max_give[6];
        give_quota7[client] = max_give[7];
        give_quota8[client] = max_give[8];
        give_quota9[client] = max_give[9];
        give_quota10[client] = max_give[10];
    }
}

public OnClientPutInServer(client)
{
    //Get inital quotas from cvars
    max_give[0] = GetConVarInt(g_max_give[0]);
    max_give[1] = GetConVarInt(g_max_give[1]);
    max_give[2] = GetConVarInt(g_max_give[2]);
    max_give[3] = GetConVarInt(g_max_give[3]);
    max_give[4] = GetConVarInt(g_max_give[4]);
    max_give[5] = GetConVarInt(g_max_give[5]);
    max_give[6] = GetConVarInt(g_max_give[6]);
    max_give[7] = GetConVarInt(g_max_give[7]);
    max_give[8] = GetConVarInt(g_max_give[8]);
    max_give[9] = GetConVarInt(g_max_give[9]);
    max_give[10] = GetConVarInt(g_max_give[10]);
    
    //Sets inital quotas for the player just joined   
    give_quota0[client] = max_give[0];
    give_quota1[client] = max_give[1];
    give_quota2[client] = max_give[2];
    give_quota3[client] = max_give[3];
    give_quota4[client] = max_give[4];
    give_quota5[client] = max_give[5];
    give_quota6[client] = max_give[6];
    give_quota7[client] = max_give[7];
    give_quota8[client] = max_give[8];
    give_quota9[client] = max_give[9];
    give_quota10[client] = max_give[10];
}

public Action:TankBusterMenu(client,args)
{
    //Callout menu
    TankBuster(client);
    
    return Plugin_Handled;
}

public Action:TankBuster(clientId) {
    //Create menu
    new Handle:menu = CreateMenu(TankBusterMenuHandler);
    SetMenuTitle(menu, "TankBuster Weapons Menu");
    AddMenuItem(menu, "option1", "Shotgun");
    AddMenuItem(menu, "option2", "SMG");
    AddMenuItem(menu, "option3", "Rifle");
    AddMenuItem(menu, "option4", "Hunting Rifle");
    AddMenuItem(menu, "option5", "Auto Shotgun");
    AddMenuItem(menu, "option6", "Pistol");
    AddMenuItem(menu, "option7", "Pipe Bomb");
    AddMenuItem(menu, "option8", "Molotov");
    AddMenuItem(menu, "option9", "Ammo");
    AddMenuItem(menu, "option10", "Pain Pills");
    AddMenuItem(menu, "option11", "First Aid Kit");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public TankBusterMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    //Strip the CHEAT flag off of the "give" command
    new flags = GetCommandFlags("give");
    SetCommandFlags("give", flags & ~FCVAR_CHEAT);
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //shotgun
            {
                if ( give_quota0[client] > 0 || give_quota0[client] < 0) {
                    //Give the player a shotgun
                    FakeClientCommand(client, "give pumpshotgun");
                    //Decrease remaining quota of that player by 1
                    give_quota0[client]--;
                    //Notify remaining quota
                    if (give_quota0[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Shotgun until next round",give_quota0[client]);
                    }
                    else if (give_quota0[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Shotguns until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain a Shotgun");
                }
            }
            case 1: //smg
            {
                if ( give_quota1[client] > 0 || give_quota1[client] < 0) {
                    //Give the player a smg
                    FakeClientCommand(client, "give smg");
                    //Decrease remaining quota of that player by 1
                    give_quota1[client]--;
                    //Notify remaining quota
                    if (give_quota1[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a SMG until next round",give_quota1[client]);
                    }
                    else if (give_quota1[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore SMGs until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain a SMG");
                }
            }
            case 2: //rifle
            {
                if ( give_quota2[client] > 0 || give_quota2[client] < 0) {
                    //Give the player a rifle
                    FakeClientCommand(client, "give rifle");
                    //Decrease remaining quota of that player by 1
                    give_quota2[client]--;
                    //Notify remaining quota
                    if (give_quota2[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Rifle until next round",give_quota2[client]);
                    }
                    else if (give_quota2[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Rifles until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain a Rifle");
                }
            }
            case 3: //hunting rifle
            {
                if ( give_quota3[client] > 0 || give_quota3[client] < 0) {
                    //Give the player a hunting rifle
                    FakeClientCommand(client, "give hunting_rifle");
                    //Decrease remaining quota of that player by 1
                    give_quota3[client]--;
                    //Notify remaining quota
                    if (give_quota3[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Hunting Rifle until next round",give_quota3[client]);
                    }
                    else if (give_quota3[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Hunting Rifles until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain a Hunting Rifle");
                }
            }
            case 4: //auto shotgun
            {
                if ( give_quota4[client] > 0 || give_quota4[client] < 0) {
                    //Give the player a autoshotgun
                    FakeClientCommand(client, "give autoshotgun");
                    //Decrease remaining quota of that player by 1
                    give_quota4[client]--;
                    //Notify remaining quota
                    if (give_quota4[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an Auto Shotgun until next round",give_quota4[client]);
                    }
                    else if (give_quota4[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Auto Shotguns until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain an Auto Shotgun");
                }
            }
            case 5: //pistol
            {
                if ( give_quota5[client] > 0 || give_quota5[client] < 0) {
                    //Give the player a pistol
                    FakeClientCommand(client, "give pistol");
                    //Decrease remaining quota of that player by 1
                    give_quota5[client]--;
                    //Notify remaining quota
                    if (give_quota5[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Pistol until next round",give_quota5[client]);
                    }
                    else if (give_quota5[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Pistols until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain a Pistol");
                }
            }
            case 6: //pipe_bomb
            {
                if ( give_quota6[client] > 0 || give_quota6[client] < 0) {
                    //Give the player a pipe_bomb
                    FakeClientCommand(client, "give pipe_bomb");
                    //Decrease remaining quota of that player by 1
                    give_quota6[client]--;
                    //Notify remaining quota
                    if (give_quota6[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Pipe Bomb until next round",give_quota6[client]);
                    }
                    else if (give_quota6[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Pipe Bombs until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain a Pipe Bomb");
                }
            }
            case 7: //hunting molotov
            {
                if ( give_quota7[client] > 0 || give_quota7[client] < 0) {
                    //Give the player a molotov
                    FakeClientCommand(client, "give molotov");
                    //Decrease remaining quota of that player by 1
                    give_quota7[client]--;
                    //Notify remaining quota
                    if (give_quota7[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Molotov until next round",give_quota7[client]);
                    }
                    else if (give_quota7[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Molotovs until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain a Molotov");
                }
            }
            case 8: //ammo
            {
                if ( give_quota8[client] > 0 || give_quota8[client] < 0) {
                    //Give the player ammo
                    FakeClientCommand(client, "give ammo");
                    //Decrease remaining quota of that player by 1
                    give_quota8[client]--;
                    //Notify remaining quota
                    if (give_quota8[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain Ammo until next round",give_quota8[client]);
                    }
                    else if (give_quota8[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Ammo until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain Ammo");
                }
            }
            case 9: //pain_pills
            {
                if ( give_quota9[client] > 0 || give_quota9[client] < 0) {
                    //Give the player pain pills
                    FakeClientCommand(client, "give pain_pills");
                    //Decrease remaining quota of that player by 1
                    give_quota9[client]--;
                    //Notify remaining quota
                    if (give_quota9[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain Pain Pills until next round",give_quota9[client]);
                    }
                    else if (give_quota9[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Pain Pills until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain Pain Pills");
                }
            }
            case 10: //first_aid_kit
            {
                if ( give_quota10[client] > 0 || give_quota10[client] < 0) {
                    //Give the player a first aid kit
                    FakeClientCommand(client, "give first_aid_kit");
                    //Decrease remaining quota of that player by 1
                    give_quota10[client]--;
                    //Notify remaining quota
                    if (give_quota10[client] > 0) {
                        PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a First Aid Kit until next round",give_quota10[client]);
                    }
                    else if (give_quota10[client] == 0){
                        PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore First Aid Kits until next round");
                    }
                }
                else {
                    //No more quota left
                    PrintToChat(client, "\x04[SM] \x01You cannot obtain a First Aid Kit");
                }
            }
        }
    }

    //Add the CHEAT flag back to "give" command
    SetCommandFlags("give", flags|FCVAR_CHEAT);
}