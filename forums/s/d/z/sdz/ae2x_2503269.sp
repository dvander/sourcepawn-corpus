public void OnPluginStart()
{
    RegConsoleCmd("sm_retry", Command_Retry);
}
 
public Action:Command_Retry(client, args)
{
    new Handle:hMenu = CreateMenu(retryMenu)

    AddMenuItem(hMenu, "1", "Yes");
    AddMenuItem(hMenu, "2", "No");

    SetMenuTitle(hMenu, "Are you sure you want to retry?");
    SetMenuPagination(hMenu, 2);
    DisplayMenu(hMenu, client, 30);
    return Plugin_Handled;
}

public retryMenu(Handle:hMenu, MenuAction:action, client, selection)
{
    decl String:buffer[32];
    GetMenuItem(hMenu, selection, buffer, sizeof(buffer));

    new ans = StringToInt(buffer);

    if (action == MenuAction_Select)
    {
        switch(ans)
        {
            case 1:
            {
                ClientCommand(client, "retry");
                return 1;
            }

            case 2:
            {
                CloseHandle(hMenu);
                return 0;
            }

            default:
            {
                CloseHandle(hMenu);
                return 0;
            }
        }
    }
    else if(action == MenuAction_End)
    {
        CloseHandle(hMenu);
        return 0;
    }
    return 0;
}  