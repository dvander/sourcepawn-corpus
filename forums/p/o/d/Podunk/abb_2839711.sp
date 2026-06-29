#pragma semicolon 1

#define ABB_PLUGIN    "[TF2] Alternative Bot Balance"
#define ABB_VERSION   "0.0.2"
#define ABB_AUTHOR    "Podunk" //with credit to grok
#define ABB_DESC      "Alternative control over the number of bots with team-specific balancing"

#include <sourcemod>
#include <adminmenu>

ConVar g_abb_extra_slack;
ConVar g_abb_reaction_time;
ConVar g_abb_min_usedslots;
ConVar g_abb_add_red_command;
ConVar g_abb_add_blue_command;
ConVar g_abb_remove_command;
ConVar g_abb_min_open_slots;
ConVar g_abb_red_multiplier;
ConVar g_abb_blue_threshold;
ConVar g_abb_blue_bot_target;
ConVar g_abb_red_class;
ConVar g_abb_blue_class;

public Plugin myinfo =
{
    name = ABB_PLUGIN,
    author = ABB_AUTHOR,
    description = ABB_DESC,
    version = ABB_VERSION,
    url = "none"
};

public void OnPluginStart()
{
    g_abb_extra_slack = CreateConVar("abb_extra_slack", "3",
        "If the (# of red bots) > (target red bots + abb_extra_slack), ABB will start kicking red bots " ...
        "(1 per cycle). This setting allows the server population to come down gradually.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    g_abb_reaction_time = CreateConVar("abb_reaction_time", "60.0",
        "Time in seconds between every check and balance cycle. " ...
        "If ABB does need to add/remove bots, it will add/remove 1 bot per cycle.",
        FCVAR_NOTIFY, true, 0.0);

    g_abb_min_usedslots = CreateConVar("abb_min_usedslots", "4",
        "Minimum (human+bots) slots used on the server. ABB will add red bots if there's " ...
        "less than the minimum total slots taken - until the min is reached.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    g_abb_add_red_command = CreateConVar("abb_add_red_command", "tf_bot_add 1 red %s",
        "Server command template to add a bot to red team, with %s for class.",
        FCVAR_NOTIFY);

    g_abb_add_blue_command = CreateConVar("abb_add_blue_command", "tf_bot_add 1 blue %s",
        "Server command template to add a bot to blue team, with %s for class.",
        FCVAR_NOTIFY);

    g_abb_remove_command = CreateConVar("abb_remove_command", "tf_bot_kick",
        "Command to kick a bot (used as a base; bot name is handled internally). " ...
        "The default works for TF2 Nextbots.",
        FCVAR_NOTIFY);

    g_abb_min_open_slots = CreateConVar("abb_min_open_slots", "1",
        "The minimum open slots on the server. ABB will kick a bot if more open slots are needed " ...
        "and there is a bot to kick. Prevents humans from being unable to connect due to full server.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    g_abb_red_multiplier = CreateConVar("abb_red_multiplier", "4.0",
        "Multiplier for red bots: target_red_bots = multiplier * total_humans. " ...
        "Keeps red team stocked based on total human players.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    g_abb_blue_threshold = CreateConVar("abb_blue_threshold", "4",
        "If blue humans >= this threshold, remove blue bots; else maintain abb_blue_bot_target blue bots.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    g_abb_blue_bot_target = CreateConVar("abb_blue_bot_target", "1",
        "Number of blue bots to maintain when blue humans < threshold.",
        FCVAR_NOTIFY, true, 0.0, true, 10.0);

    g_abb_red_class = CreateConVar("abb_red_class", "engineer",
        "Class for red bots: 'random' or class name (scout, soldier, pyro, demoman, heavyweapons, engineer, medic, sniper, spy).",
        FCVAR_NOTIFY);

    g_abb_blue_class = CreateConVar("abb_blue_class", "random",
        "Class for blue bots: 'random' or class name (scout, soldier, pyro, demoman, heavyweapons, engineer, medic, sniper, spy).",
        FCVAR_NOTIFY);

    RegAdminCmd("sm_abb", Command_ABBMenu, ADMFLAG_GENERIC, "Open ABB settings menu");

    // Start the first timer (non-repeating)
    CreateTimer(GetConVarFloat(g_abb_reaction_time), Timer_Tick);
}

public Action Command_ABBMenu(int client, int args)
{
    if (!client || !IsClientInGame(client)) return Plugin_Handled;

    Menu menu = new Menu(MenuHandler_ABB);
    menu.SetTitle("Alternative Bot Balance Settings");

    char adjustables[7][32] = {
        "abb_red_multiplier",
        "abb_blue_threshold",
        "abb_blue_bot_target",
        "abb_reaction_time",
        "abb_min_usedslots",
        "abb_extra_slack",
        "abb_min_open_slots"
    };

    for (int i = 0; i < sizeof(adjustables); i++)
    {
        char cvarname[32];
        strcopy(cvarname, sizeof(cvarname), adjustables[i]);
        ConVar cv = FindConVar(cvarname);
        if (cv == null) continue;

        char disp[64], val[32];
        cv.GetString(val, sizeof(val));

        if (!IsIntCvar(cvarname))
        {
            float fv = StringToFloat(val);
            Format(disp, sizeof(disp), "%s: %.1f", cvarname[4], fv);
        }
        else
        {
            Format(disp, sizeof(disp), "%s: %s", cvarname[4], val);
        }

        menu.AddItem(cvarname, disp);
    }

    // Class settings
    char redc[32], reddisp[64];
    GetConVarString(g_abb_red_class, redc, sizeof(redc));
    GetClassDisplay(redc, reddisp, sizeof(reddisp));
    Format(reddisp, sizeof(reddisp), "Red Team Class: %s", reddisp);
    menu.AddItem("redclass", reddisp);

    char bluec[32], bluedisp[64];
    GetConVarString(g_abb_blue_class, bluec, sizeof(bluec));
    GetClassDisplay(bluec, bluedisp, sizeof(bluedisp));
    Format(bluedisp, sizeof(bluedisp), "Blue Team Class: %s", bluedisp);
    menu.AddItem("blueclass", bluedisp);

    menu.AddItem("exit", "Exit");
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int MenuHandler_ABB(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        if (StrEqual(info, "exit"))
        {
            return 0;
        }
        else if (StrEqual(info, "redclass"))
        {
            RedClassMenu(client);
        }
        else if (StrEqual(info, "blueclass"))
        {
            BlueClassMenu(client);
        }
        else
        {
            AdjustMenu(info, client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void RedClassMenu(int client)
{
    Menu menu = new Menu(RedClassHandler);
    char title[128], cur[32], curdisp[32];
    GetConVarString(g_abb_red_class, cur, sizeof(cur));
    GetClassDisplay(cur, curdisp, sizeof(curdisp));
    Format(title, sizeof(title), "Red Team Class Settings\nCurrent: %s", curdisp);
    menu.SetTitle(title);

    menu.AddItem("random", "Set to Random");
    menu.AddItem("specific", "Set to Specific Class");
    menu.AddItem("back", "Back");

    menu.Display(client, MENU_TIME_FOREVER);
}

public int RedClassHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        if (StrEqual(info, "back"))
        {
            Command_ABBMenu(client, 0);
        }
        else if (StrEqual(info, "random"))
        {
            SetConVarString(g_abb_red_class, "random");
            RedClassMenu(client);
        }
        else if (StrEqual(info, "specific"))
        {
            SpecificRedClassMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void SpecificRedClassMenu(int client)
{
    Menu menu = new Menu(SpecificRedHandler);
    char title[128], cur[32], curdisp[32];
    GetConVarString(g_abb_red_class, cur, sizeof(cur));
    GetClassDisplay(cur, curdisp, sizeof(curdisp));
    Format(title, sizeof(title), "Red Team Specific Class\nCurrent: %s", curdisp);
    menu.SetTitle(title);

    char classNames[9][32] = {"scout", "soldier", "pyro", "demoman", "heavyweapons", "engineer", "medic", "sniper", "spy"};
    char displayNames[9][32] = {"Scout", "Soldier", "Pyro", "Demoman", "Heavy", "Engineer", "Medic", "Sniper", "Spy"};

    for (int j = 0; j < 9; j++)
    {
        menu.AddItem(classNames[j], displayNames[j]);
    }

    menu.AddItem("back", "Back to Class Settings");
    menu.Display(client, MENU_TIME_FOREVER);
}

public int SpecificRedHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        if (StrEqual(info, "back"))
        {
            RedClassMenu(client);
        }
        else
        {
            SetConVarString(g_abb_red_class, info);
            SpecificRedClassMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void BlueClassMenu(int client)
{
    Menu menu = new Menu(BlueClassHandler);
    char title[128], cur[32], curdisp[32];
    GetConVarString(g_abb_blue_class, cur, sizeof(cur));
    GetClassDisplay(cur, curdisp, sizeof(curdisp));
    Format(title, sizeof(title), "Blue Team Class Settings\nCurrent: %s", curdisp);
    menu.SetTitle(title);

    menu.AddItem("random", "Set to Random");
    menu.AddItem("specific", "Set to Specific Class");
    menu.AddItem("back", "Back");

    menu.Display(client, MENU_TIME_FOREVER);
}

public int BlueClassHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        if (StrEqual(info, "back"))
        {
            Command_ABBMenu(client, 0);
        }
        else if (StrEqual(info, "random"))
        {
            SetConVarString(g_abb_blue_class, "random");
            BlueClassMenu(client);
        }
        else if (StrEqual(info, "specific"))
        {
            SpecificBlueClassMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void SpecificBlueClassMenu(int client)
{
    Menu menu = new Menu(SpecificBlueHandler);
    char title[128], cur[32], curdisp[32];
    GetConVarString(g_abb_blue_class, cur, sizeof(cur));
    GetClassDisplay(cur, curdisp, sizeof(curdisp));
    Format(title, sizeof(title), "Blue Team Specific Class\nCurrent: %s", curdisp);
    menu.SetTitle(title);

    char classNames[9][32] = {"scout", "soldier", "pyro", "demoman", "heavyweapons", "engineer", "medic", "sniper", "spy"};
    char displayNames[9][32] = {"Scout", "Soldier", "Pyro", "Demoman", "Heavy", "Engineer", "Medic", "Sniper", "Spy"};

    for (int j = 0; j < 9; j++)
    {
        menu.AddItem(classNames[j], displayNames[j]);
    }

    menu.AddItem("back", "Back to Class Settings");
    menu.Display(client, MENU_TIME_FOREVER);
}

public int SpecificBlueHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        if (StrEqual(info, "back"))
        {
            BlueClassMenu(client);
        }
        else
        {
            SetConVarString(g_abb_blue_class, info);
            SpecificBlueClassMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

stock void GetClassDisplay(const char[] class, char[] buffer, int size)
{
    if (StrEqual(class, "random", false))
    {
        strcopy(buffer, size, "Random");
    }
    else if (StrEqual(class, "scout", false))
    {
        strcopy(buffer, size, "Scout");
    }
    else if (StrEqual(class, "soldier", false))
    {
        strcopy(buffer, size, "Soldier");
    }
    else if (StrEqual(class, "pyro", false))
    {
        strcopy(buffer, size, "Pyro");
    }
    else if (StrEqual(class, "demoman", false))
    {
        strcopy(buffer, size, "Demoman");
    }
    else if (StrEqual(class, "heavyweapons", false))
    {
        strcopy(buffer, size, "Heavy");
    }
    else if (StrEqual(class, "engineer", false))
    {
        strcopy(buffer, size, "Engineer");
    }
    else if (StrEqual(class, "medic", false))
    {
        strcopy(buffer, size, "Medic");
    }
    else if (StrEqual(class, "sniper", false))
    {
        strcopy(buffer, size, "Sniper");
    }
    else if (StrEqual(class, "spy", false))
    {
        strcopy(buffer, size, "Spy");
    }
    else
    {
        strcopy(buffer, size, class);
    }
}

void AdjustMenu(const char[] cvarname, int client)
{
    ConVar cv = FindConVar(cvarname);
    if (cv == null) return;

    Menu menu = new Menu(Handler_Adjust);
    char title[128];
    Format(title, sizeof(title), "Adjust %s\nCurrent: ", cvarname);
    char valstr[32];
    cv.GetString(valstr, sizeof(valstr));
    StrCat(title, sizeof(title), valstr);
    menu.SetTitle(title);

    char infobuf[64];

    Format(infobuf, sizeof(infobuf), "step10_%s", cvarname);
    menu.AddItem(infobuf, "+10");

    Format(infobuf, sizeof(infobuf), "step-10_%s", cvarname);
    menu.AddItem(infobuf, "-10");

    Format(infobuf, sizeof(infobuf), "step1_%s", cvarname);
    menu.AddItem(infobuf, "+1");

    Format(infobuf, sizeof(infobuf), "step-1_%s", cvarname);
    menu.AddItem(infobuf, "-1");

    if (!IsIntCvar(cvarname))
    {
        Format(infobuf, sizeof(infobuf), "step0.1_%s", cvarname);
        menu.AddItem(infobuf, "+0.1");

        Format(infobuf, sizeof(infobuf), "step-0.1_%s", cvarname);
        menu.AddItem(infobuf, "-0.1");
    }

    menu.AddItem("back", "Back");
    menu.Display(client, 30);
}

public int Handler_Adjust(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[64];
        menu.GetItem(param2, info, sizeof(info));
        if (StrEqual(info, "back"))
        {
            Command_ABBMenu(client, 0);
            delete menu;
            return 0;
        }

        int pos = FindCharInString(info, '_');
        if (pos == -1) return 0;

        // Copy the step part (before '_')
        char step_part[32];
        char temp = info[pos];
        info[pos] = '\0';
        strcopy(step_part, sizeof(step_part), info);
        info[pos] = temp;

        char numstr[16];
        strcopy(numstr, sizeof(numstr), step_part[4]);

        float step = StringToFloat(numstr);

        // Copy the cvarname (after '_')
        char cvarname[32];
        strcopy(cvarname, sizeof(cvarname), info[pos + 1]);

        ConVar cv = FindConVar(cvarname);
        if (cv == null) return 0;

        char currstr[32];
        cv.GetString(currstr, sizeof(currstr));
        float curr = StringToFloat(currstr);
        float newv = curr + step;

        char newstr[32];
        if (IsIntCvar(cvarname))
        {
            int newi = RoundToNearest(newv);
            newi = (newi < 0) ? 0 : newi;
            IntToString(newi, newstr, sizeof(newstr));
        }
        else
        {
            Format(newstr, sizeof(newstr), "%.1f", newv);
        }

        SetConVarString(cv, newstr);
        AdjustMenu(cvarname, client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

bool IsIntCvar(const char[] name)
{
    if (StrEqual(name, "abb_red_multiplier") || StrEqual(name, "abb_reaction_time")) return false;
    return true;
}

public Action Timer_Tick(Handle timer)
{
    int maxPlayers = MaxClients;
    float reactionTime = GetConVarFloat(g_abb_reaction_time);
    int minUsedSlots = GetConVarInt(g_abb_min_usedslots);
    int extraSlack = GetConVarInt(g_abb_extra_slack);
    int minOpenSlots = GetConVarInt(g_abb_min_open_slots);
    int blueThreshold = GetConVarInt(g_abb_blue_threshold);
    int blueBotTarget = GetConVarInt(g_abb_blue_bot_target);
    float redMultiplier = GetConVarFloat(g_abb_red_multiplier);

    int redHumans = 0, blueHumans = 0, redBots = 0, blueBots = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            int team = GetClientTeam(i);
            if (team == 2)
            {
                if (IsFakeClient(i))
                    redBots++;
                else
                    redHumans++;
            }
            else if (team == 3)
            {
                if (IsFakeClient(i))
                    blueBots++;
                else
                    blueHumans++;
            }
        }
    }

    int totalHumans = redHumans + blueHumans;
    int totalBots = redBots + blueBots;
    int totalPlayers = totalHumans + totalBots;

    // If no human players are connected and on a team, skip bot management
    if (totalHumans == 0)
    {
        CreateTimer(reactionTime, Timer_Tick);
        return Plugin_Continue;
    }

    int targetBlueBots = (blueHumans < blueThreshold) ? blueBotTarget : 0;

    // Handle blue team exception (gradual via cycle)
    if (blueBots > targetBlueBots)
    {
        KickBlueBot();
    }
    else if (blueBots < targetBlueBots && totalPlayers < maxPlayers - minOpenSlots)
    {
        AddBlueBot();
    }

    // Kick for min open slots (prefer red)
    if (totalPlayers > maxPlayers - minOpenSlots && (redBots + blueBots > 0))
    {
        if (redBots > 0)
        {
            KickRedBot();
        }
        else if (blueBots > targetBlueBots)
        {
            KickBlueBot();
        }
    }
    // Add for min used slots
    else if (totalPlayers < minUsedSlots && totalPlayers < maxPlayers - minOpenSlots)
    {
        AddRedBot();
    }
    // Balance red team
    else
    {
        int targetRedBots = RoundToNearest(redMultiplier * totalHumans);
        if (redBots < targetRedBots && totalPlayers < maxPlayers - minOpenSlots)
        {
            AddRedBot();
        }
        else if (redBots > targetRedBots + extraSlack && totalPlayers > minUsedSlots)
        {
            KickRedBot();
        }
    }

    // Schedule next tick
    CreateTimer(reactionTime, Timer_Tick);

    return Plugin_Continue;
}

void AddRedBot()
{
    char basecmd[64], selectedClass[32];
    GetConVarString(g_abb_add_red_command, basecmd, sizeof(basecmd));

    char class[32];
    GetConVarString(g_abb_red_class, class, sizeof(class));
    if (StrEqual(class, "random", false))
    {
        char classNames[9][32] = {"scout", "soldier", "pyro", "demoman", "heavyweapons", "engineer", "medic", "sniper", "spy"};
        strcopy(selectedClass, sizeof(selectedClass), classNames[GetRandomInt(0, 8)]);
    }
    else
    {
        strcopy(selectedClass, sizeof(selectedClass), class);
    }

    char cmd[128];
    Format(cmd, sizeof(cmd), basecmd, selectedClass);
    LogAction(0, -1, "[ABB]: Executing add red command: %s", cmd);
    ServerCommand("%s", cmd);
}

void AddBlueBot()
{
    char basecmd[64], selectedClass[32];
    GetConVarString(g_abb_add_blue_command, basecmd, sizeof(basecmd));

    char class[32];
    GetConVarString(g_abb_blue_class, class, sizeof(class));
    if (StrEqual(class, "random", false))
    {
        char classNames[9][32] = {"scout", "soldier", "pyro", "demoman", "heavyweapons", "engineer", "medic", "sniper", "spy"};
        strcopy(selectedClass, sizeof(selectedClass), classNames[GetRandomInt(0, 8)]);
    }
    else
    {
        strcopy(selectedClass, sizeof(selectedClass), class);
    }

    char cmd[128];
    Format(cmd, sizeof(cmd), basecmd, selectedClass);
    LogAction(0, -1, "[ABB]: Executing add blue command: %s", cmd);
    ServerCommand("%s", cmd);
}

void KickRedBot()
{
    int bot = GetRandomRedBot();
    if (bot <= 0) return;

    char botName[64];
    GetClientName(bot, botName, sizeof(botName));
    char cmd[128], basecmd[64];
    GetConVarString(g_abb_remove_command, basecmd, sizeof(basecmd));
    Format(cmd, sizeof(cmd), "%s \"%s\"", basecmd, botName);
    LogAction(0, bot, "[ABB]: Executing kick red command: %s", cmd);
    ServerCommand("%s", cmd);
}

void KickBlueBot()
{
    int bot = GetRandomBlueBot();
    if (bot <= 0) return;

    char botName[64];
    GetClientName(bot, botName, sizeof(botName));
    char cmd[128], basecmd[64];
    GetConVarString(g_abb_remove_command, basecmd, sizeof(basecmd));
    Format(cmd, sizeof(cmd), "%s \"%s\"", basecmd, botName);
    LogAction(0, bot, "[ABB]: Executing kick blue command: %s", cmd);
    ServerCommand("%s", cmd);
}

int GetRandomRedBot()
{
    int[] bots = new int[MaxClients];
    int botCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
        {
            bots[botCount++] = i;
        }
    }

    if (botCount == 0) return 0;
    return bots[GetRandomInt(0, botCount - 1)];
}

int GetRandomBlueBot()
{
    int[] bots = new int[MaxClients];
    int botCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3)
        {
            bots[botCount++] = i;
        }
    }

    if (botCount == 0) return 0;
    return bots[GetRandomInt(0, botCount - 1)];
}