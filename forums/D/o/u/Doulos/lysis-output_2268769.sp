public PlVers:__version =
{
    version = 5,
    filevers = "1.4.1-dev",
    date = "02/04/2012",
    time = "18:11:17"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
    name = "Core",
    file = "core",
    autoload = 0,
    required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
    name = "SDKTools",
    file = "sdktools.ext",
    autoload = 1,
    required = 1,
};
public Plugin:myinfo =
{
    name = "GIVE",
    description = "",
    author = "",
    version = "",
    url = ""
};
new String:commands[6][32] =
{
    "sm_ak",
    "sm_m4",
    "sm_au",
    "sm_sg",
    "sm_ga",
    "sm_fa"
};
new String:weapons[6][0];
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
    while (i <= MaxClients)
    {
        if (IsClientInGame(i))
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, 192, format, 2);
            PrintToChat(i, "%s", buffer);
            i++;
        }
        i++;
    }
    return 0;
}

public OnPluginStart()
{
    new i;
    while (i < 6)
    {
        RegConsoleCmd(commands[i], give, "", 0);
        i++;
    }
    HookEvent("round_start", rs, EventHookMode:1);
    return 0;
}

public Action:rs(Handle:event, String:name[], bool:broadcast)
{
    decl String:msg[192];
    msg[0] = MissingTAG:0;
    strcopy(msg, 192, "Say");
    new i;
    while (i < 5)
    {
        Format(msg, 192, "%s%s%s%s", msg, " !", commands[i][0], ",");
        i++;
    }
    Format(msg, 192, "%s%s%s%s", msg, " or !", commands[5][0], " for weapons.");
    PrintToChatAll(msg);
    return Action:0;
}

public Action:give(client, args)
{
    new var1;
    if (!IsClientInGame(client) || !IsPlayerAlive(client) || !GetEntProp(client, PropType:0, "m_bInBuyZone", 4, 0))
    {
        return Action:3;
    }
    decl String:cmd[64];
    GetCmdArg(0, cmd, 64);
    new found;
    new weapon = -1;
    while (!found && weapon < 6)
    {
        found = StrEqual(cmd, commands[weapon], true);
    }
    if (found)
    {
        new old = GetPlayerWeaponSlot(client, 0);
        if (old != -1)
        {
            RemovePlayerItem(client, old);
            RemoveEdict(old);
        }
        GivePlayerItem(client, weapons[weapon], 0);
    }
    return Action:3;
}