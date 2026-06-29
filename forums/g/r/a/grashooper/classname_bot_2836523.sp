#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Bot Class Names",
    author = "grashooper",
    description = "Sets bot names to their respective classes",
    version = "1.0",
    url = "none"
}

ConVar cvar_prefix;      // Prefix for bot names
ConVar cvar_suffix;      // Suffix for bot names
ConVar cvar_enabled;     // Enable/disable the plugin
ConVar cvar_capitalize;  // Capitalize first letter of class name

native void Ins_GetPlayerClass(int client, char[] class, int maxlen);

public void OnPluginStart()
{
    // Create configuration convars
    cvar_prefix = CreateConVar("bot_class_names_prefix", "BOT ", "Prefix for bot names");
    cvar_suffix = CreateConVar("bot_class_names_suffix", "", "Suffix for bot names");
    cvar_enabled = CreateConVar("bot_class_names_enabled", "1", "Enable bot class renaming", 0, true, 0.0, true, 1.0);
    cvar_capitalize = CreateConVar("bot_class_names_capitalize", "1", "Capitalize first letter of class name", 0, true, 0.0, true, 1.0);

    // Hook the squad pick event to rename bots
    HookEvent("player_pick_squad", Event_PlayerPickSquad_Post, EventHookMode_Post);
}

// Event callback after squad selection
public Action Event_PlayerPickSquad_Post(Event event, const char[] event_name, bool dont_broadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    // Only process valid bot clients
    if (client < 1 || !IsClientInGame(client) || !IsFakeClient(client))
    {
        return Plugin_Continue;
    }
    
    RenameBot(client);
    return Plugin_Continue;
}

// Renames a bot based on its class
void RenameBot(const int client)
{
    if (!cvar_enabled.BoolValue)
    {
        return;
    }

    char prefix[32];
    char suffix[32];
    char className[32];
    char new_name[32];

    // Get configuration values
    cvar_prefix.GetString(prefix, sizeof(prefix));
    cvar_suffix.GetString(suffix, sizeof(suffix));
    Ins_GetPlayerClass(client, className, sizeof(className));

    // Format class name capitalization
    if (cvar_capitalize.BoolValue)
    {
        UpperCaseFirstLetter(className);
    }

    // Construct and set new bot name
    Format(new_name, sizeof(new_name), "%s%s%s", prefix, className, suffix);
    SetClientInfo(client, "name", new_name);
}

// Capitalizes first character of a string
void UpperCaseFirstLetter(char[] str)
{
    if (str[0] != '\0')
    {
        str[0] = CharToUpper(str[0]);
    }
}