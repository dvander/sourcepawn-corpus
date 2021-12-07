new PlVers:__version = 5;
new Float:NULL_VECTOR[3];
new String:NULL_STRING[1];
new Extension:__ext_core = 64;
new MaxClients;
new bool:g_bLoadTimer;
public Plugin:myinfo =
{
    name = "MAPO - test",
    description = "Protect your admins!",
    author = "MEDVED",
    version = "1.0.0.0",
    url = "medveds.ru"
};
public __ext_core_SetNTVOptional()
{
    MarkNativeAsOptional("GetFeatureStatus");
    MarkNativeAsOptional("RequireFeature");
    MarkNativeAsOptional("AddCommandListener");
    MarkNativeAsOptional("RemoveCommandListener");
    VerifyCoreVersion();
    return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
    return strcmp(str1, str2, caseSensitive) == 0;
}

PrintToChatAll(String:format[])
{
    decl String:buffer[192];
    new i = 1;
    while (i <= MaxClients) {
        if (IsClientInGame(i)) {
            SetGlobalTransTarget(i);
            VFormat(buffer, 192, format, 2);
            PrintToChat(i, "%s", buffer);
            i++;
        }
        i++;
    }
    return 0;
}

public OnClientPostAdminCheck(client)
{
    new AdminId:id = GetUserAdmin(client);
    if (id != AdminId:-1) {
        QueryClientConVar(client, "xbox_throttlespoof", ConVarQueryFinished:1, client);
    }
    return 0;
}

public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, String:cvarName1[], String:cvarValue1[])
{
    if (StrEqual("123", cvarValue1, false)) {
        PrintToConsole(client, "[medveds.ru]: ?????????????");
    } else {
        KickClient(client, "[medveds.ru]: ?? ?????????????");
    }
    return 0;
}

public OnConfigsExecuted()
{
    if (!g_bLoadTimer) {
        CreateTimer(60, TimerCount, any:0, 1);
        g_bLoadTimer = 1;
    }
    return 0;
}

public Action:TimerCount(Handle:timer)
{
    PrintToChatAll("?? ???? ??????? ??????????? ???????? ?????? ??????? ?????? MAPO");
    PrintToChatAll("??????????? ?????? ?????? ?????? ????? ?? 199 ?. ????? - gorinilja");
    PrintToChatAll("????? ?????? - ???? ?????. MEDVED'S. medveds.ru");
    return Action:0;
}

