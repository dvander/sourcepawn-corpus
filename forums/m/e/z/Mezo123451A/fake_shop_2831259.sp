#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.1"

ConVar g_hVersion;
Handle g_hTimer = null;

public Plugin myinfo = 
{
    name = "L4D2 Shop System",
    author = "Mezo123451A",
    description = "Advanced Shop System for L4D2",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_shop", Command_Shop);
    RegConsoleCmd("sm_buy", Command_Shop);    // Added new command
    RegConsoleCmd("sm_store", Command_Shop);  // Added new command
    g_hVersion = CreateConVar("l4d2_shop_version", PLUGIN_VERSION, "Shop System Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    AutoExecConfig(true, "l4d2_shop");
    CreateTimer(GetRandomFloat(60.0, 120.0), Timer_Advertisement, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_Shop(int client, int args)
{
    if(client == 0) return Plugin_Handled;
    
    Menu menu = new Menu(ShopMenuHandler);
    menu.SetTitle("L4D2 Shop System\nCredits: %d\n \nLoading shop data...", GetRandomInt(100, 999));
    
    menu.AddItem("weapons", "Loading items...");
    menu.AddItem("upgrades", "Please wait...");
    menu.AddItem("perks", "Connecting to store...");
    menu.AddItem("skins", "Checking balance...");
    
    menu.Display(client, 3);
    CreateTimer(3.1, Timer_TrollMessage, GetClientUserId(client));
    
    return Plugin_Handled;
}

public Action Timer_TrollMessage(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if(client == 0) return Plugin_Stop;
    
    PrintToChat(client, "\x04[Shop]\x01 Get trolled! There's no shop here! Stop asking for shops");
    
    return Plugin_Stop;
}

public int ShopMenuHandler(Menu menu, MenuAction action, int action_param1, int action_param2)
{
    if(action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

public Action Timer_Advertisement(Handle timer)
{
    PrintToChatAll("\x04[Shop]\x01 Type \x05!shop\x01, \x05!buy\x01, or \x05!store\x01 to access the in-game store! Current offers: \x04%d%%\x01 OFF!", GetRandomInt(10, 50));
    
    g_hTimer = CreateTimer(GetRandomFloat(60.0, 120.0), Timer_Advertisement, _, TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Continue;
}

public void OnMapStart()
{
    if(g_hTimer != null)
    {
        KillTimer(g_hTimer);
        g_hTimer = CreateTimer(GetRandomFloat(60.0, 120.0), Timer_Advertisement, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}