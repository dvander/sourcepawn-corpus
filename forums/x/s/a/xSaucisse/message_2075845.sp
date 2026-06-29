new UserMsg:g_textmsg;

public OnPluginStart()
{
    g_textmsg = GetUserMessageId("TextMsg");
    HookUserMessage(g_textmsg, UserMessageHook, true);
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    decl String:message[256];
    BfReadString(bf, message, sizeof(message));
    if (StrContains(message, "teammate_attack") != -1)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}  