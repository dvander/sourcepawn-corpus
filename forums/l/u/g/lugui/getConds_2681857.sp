#include <tf2_stocks>

public Plugin myinfo = {
    name = "Get Weapons",
    author = "lugui",
    description = "Displays data about the player current conds",
    version = "1.0.0",
};

#define WEAPONS_SLOTS_MAX 10

public OnPluginStart() {

    RegConsoleCmd("sm_getconds", Command_cond, "List targets's conds");
}

public Action Command_cond(client, args) {

    if(args == 0) {
        bool found = false;
        for (int i = 0; i < 128; i++) {
            if(TF2_IsPlayerInCondition(client, view_as < TFCond > (i))) {
                found = true;
                PrintToChat(client, "On condition %032b %d", i, i);
            }
        }
        if(!found) {
            PrintToChat(client, "No conditions");
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
            bool found = false;
            for (int j = 0; j < 128; j++) {
                if(TF2_IsPlayerInCondition(target_list[i], view_as < TFCond > (j))) {
                    found = true;
                    PrintToChat(client, "On condition %032b %d", j, j);
                }
            }
            if(!found) {
                PrintToChat(target_list[i], "No conditions");
            }
        }
    }
    return Plugin_Handled;
}