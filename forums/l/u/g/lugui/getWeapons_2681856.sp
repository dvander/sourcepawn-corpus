#include <tf2_stocks>

public Plugin myinfo = {
    name = "Get Weapons",
    author = "lugui",
    description = "Displays data about the player current weapons",
    version = "1.0.0",
};

#define WEAPONS_SLOTS_MAX 10

public OnPluginStart() {

    RegConsoleCmd("sm_getweapons", Command_weapons, "List targets's weapons data");
}


public Action Command_weapons(client, args) {

    if(args == 0) {
        for (int wSlot = 0; wSlot <= WEAPONS_SLOTS_MAX; wSlot++) {
            int weapEnt = GetPlayerWeaponSlot(client, wSlot);
            if(weapEnt > -1) {
                char classname[256];
                int iItemDefinitionIndex = GetEntProp(weapEnt, Prop_Send, "m_iItemDefinitionIndex");
                GetEntityClassname(weapEnt, classname, sizeof(classname));
                PrintToChat(client, "Item Definition Index: %d    Classname: %s", iItemDefinitionIndex, classname);
            }
        }
    } else {
        char arg1[32];
        GetCmdArg(1, arg1, sizeof(arg1));

        char target_name[MAX_TARGET_LENGTH];
        int target_list[MAXPLAYERS], target_count;
        bool tn_is_ml;
        if((target_count = ProcessTargetString(
                arg1,
                client,
                target_list,
                MAXPLAYERS,
                COMMAND_TARGET_NONE,
                target_name,
                sizeof(target_name),
                tn_is_ml)) <= 0) {
            ReplyToTargetError(client, target_count);
            return Plugin_Handled;
        }
        for (int i = 0; i < target_count; i++) {
            for (int wSlot = 0; wSlot <= WEAPONS_SLOTS_MAX; wSlot++) {
                int weapEnt = GetPlayerWeaponSlot(target_list[i], wSlot);
                if(weapEnt > -1) {
                    char classname[256];
                    int iItemDefinitionIndex = GetEntProp(weapEnt, Prop_Send, "m_iItemDefinitionIndex");
                    GetEntityClassname(weapEnt, classname, sizeof(classname));
                    PrintToChat(client, "%N: Item Definition Index : %d    Classname: %s", target_list[i], iItemDefinitionIndex, classname);
                }
            }
        }
    }
    return Plugin_Handled;
}