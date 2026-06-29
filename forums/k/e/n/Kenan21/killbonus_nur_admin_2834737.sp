public Plugin myinfo = {
    name = "Kill Bonus HP",
    author = "Created by FeritGang",
    description = "Gibt Admin Spieler Bonus-HP für Kills",
    version = "1.0",
    url = "http://5.189.131.115/cstrike"
}

public OnPluginStart() {
    HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast) {
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int max_health = 100;
    if (IsValidClient(attacker) && IsAdmin(attacker)) {
        int current_health = GetClientHealth(attacker);
        int bonus_health = 30;
        int new_health = current_health + bonus_health;
        if (new_health > max_health) {
            new_health = max_health;
        }
        SetEntityHealth(attacker, new_health);
        PrintToChat(attacker, "Du hast %d HP Bonus erhalten!", bonus_health);
    }
    return Plugin_Continue;
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

bool IsAdmin(int client) {
    // Hier wird der Pfad zur admins_simple.ini berücksichtigt
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/admins_simple.ini");

    AdminId admin_id = GetUserAdmin(client);
    if (admin_id == INVALID_ADMIN_ID) {
        return false;
    }
    return true;
}
