#include <sourcemod>

public void OnPluginStart()
{
    RegConsoleCmd("sm_tlist", Command_Callback);
}

public Action Command_Callback(int client, int args)
{
    Menu menu = new Menu(Menu_Handler);
    menu.SetTitle("Users with flag T:");
    char name[32];
    int count;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && CheckCommandAccess(i, "sm_admin", ADMFLAG_CUSTOM6))
        {
            GetClientName(i, name, sizeof(name));
            menu.AddItem("", name, ITEMDRAW_DISABLED);
            count++;
        }
    }

    if (!count)
        menu.AddItem("", "No users found with flag T!", ITEMDRAW_DISABLED);

    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
        delete menu;

    return 0;
}