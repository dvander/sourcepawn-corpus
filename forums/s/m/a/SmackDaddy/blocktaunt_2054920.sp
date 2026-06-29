public OnPluginStart()
{
    AddCommandListener(DoTaunt, "taunt");
    AddCommandListener(DoTaunt, "+taunt");
    //AddCommandListener(DoTaunt, "use_action_slot_item_server");
    //AddCommandListener(DoTaunt, "+use_action_slot_item_server");
}

public Action:DoTaunt(client, const String:command[], argc)
{
    return Plugin_Handled;
}  