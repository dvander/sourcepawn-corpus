//# vim: set filetype=cpp :

/*
 * license = "https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html#SEC1",
 */

#pragma semicolon 1
#define PLUGIN_NAME "MedicineKick"
#define PLUGIN_VERSION "0.0.4"

public Plugin myinfo= {
    name = PLUGIN_NAME,
    author = "Victor \"NgBUCKWANGS\" Gonzalez",
    description = "Prescribe Kickers 100mg of KickYourOwnAss.",
    version = PLUGIN_VERSION,
    url = "https://gitlab.com/vbgunz/MedicineKick"
}

public OnPluginStart() {
    AddCommandListener(KickIntercept, "callvote");
}

public Action KickIntercept(int client, const char[] cmd, int args) {
    static char issue[5];
    static char sTarget[4];
    static int target;

    GetCmdArg(1, issue, sizeof(issue));

    if (issue[0] == 'k' && StrEqual(issue, "kick")) {
        GetCmdArg(2, sTarget, sizeof(sTarget));
        target = GetClientOfUserId(StringToInt(sTarget));

        if (client > 0 && target > 0) {
            if (!CanUserTarget(client, target) && CanUserTarget(target, client)) {
                LogMessage("%N voted to kick %N and was reversed", client, target);
                FakeClientCommand(target, "callvote kick %d", GetClientUserId(client));
                PrintHintText(client, "THE ONLY WINNING MOVE IS NOT TO PLAY");
                return Plugin_Handled;
            }
        }
    }

    return Plugin_Continue;
}
