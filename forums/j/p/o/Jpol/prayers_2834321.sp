#include <sourcemod>

public Plugin myinfo = {
    name = "Bless This Mess",
    author = "SourceGod",
    description = "In the Omnissiah's infinite wisdom, this plugin automatically offers praise and fixes all your server issues with a divine touch. Blessed be the Machine God, for he is the ultimate source of all stability!",
    version = "1.0",
    url = "https://forums.alliedmods.net/showthread.php?p=2834321#post2834321"
};

public void OnPluginStart()
{
    static const char messages[][] = {
        "Blessed be the Omnissiah!",
        "From the weakness of the mind, Omnissiah save us",
        "From the lies of the Antipath, circuit preserve us",
        "From the rage of the Beast, iron protect us",
        "From the temptations of the Flesh, silica cleanse us",
        "From the ravages of the Destroyer, anima shield us",
        "Toll the Great Bell Once! Pull the Lever forward to engage the Piston and Pump",
        "Toll the Great Bell Twice! With push of Button fire the Engine And spark Turbine into life",
        "Toll the Great Bell Thrice! Sing Praise to the God of All Machines",
        "Bless us, O Spirit of the Machine, for we do the labors of your Emperor"
    };

    int randomIndex = GetRandomInt(0, sizeof(messages) - 1);
    PrintToServer("%s", messages[randomIndex]);
}

public void OnPluginEnd()
{
    static const char endMessages[][] = {
        "Blessed be the Omnissiah!",
        "From the weakness of the mind, Omnissiah save us",
        "From the lies of the Antipath, circuit preserve us",
        "From the rage of the Beast, iron protect us",
        "From the temptations of the Flesh, silica cleanse us",
        "From the ravages of the Destroyer, anima shield us",
        "Toll the Great Bell Once! Pull the Lever forward to engage the Piston and Pump",
        "Toll the Great Bell Twice! With push of Button fire the Engine And spark Turbine into life",
        "Toll the Great Bell Thrice! Sing Praise to the God of All Machines",
        "Bless us, O Spirit of the Machine, for we do the labors of your Emperor"
    };

    int randomIndex = GetRandomInt(0, sizeof(endMessages) - 1);
    PrintToServer("%s", endMessages[randomIndex]);
}