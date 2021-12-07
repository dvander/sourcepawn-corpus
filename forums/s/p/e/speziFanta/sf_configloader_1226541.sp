#pragma semicolon 1

public Plugin:myinfo =
{
    name = "ETF2L Config Loader",
    author = "spezi|Fanta",
    description = "Loads server configs according to map name.",
    version = "0.0.0.2",
    url = "http://www.schlachtfestchen.de/"
};

public OnPluginStart()
{
    OnConfigsExecuted();
}

public OnConfigsExecuted()
{
    decl String:mapname[32];
    GetCurrentMap(mapname, sizeof(mapname));

    if (strncmp(mapname, "cp_", 3, false) == 0)
        ServerCommand("exec cp_config.cfg");

    if (strncmp(mapname, "pl_", 3, false) == 0)
        ServerCommand("exec pl_config.cfg");
}
