#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

int g_iToxicCount[MAXPLAYERS + 1];
bool g_bPunishmentComplete[MAXPLAYERS + 1];
bool g_bAdminImmune[MAXPLAYERS + 1];
int g_iFriendlyFireCount[MAXPLAYERS + 1];
float g_fLastFreezeTime = 0.0;
bool g_bFriendlyFireEnabled = true;

char g_sToxicWords[][] = {
    "nigger", "nigga", "nig nog", "nignogs",
    "faggot", "fagot", "fags", "faggots",
    "chink", "gook", "spic", "kike", "beaner",
    "tranny", "trannies",
    "kys", "kill yourself", "killyourself",
    "hang yourself", "jump off a", "end yourself",
    "drink bleach", "neck yourself",
    "die in a fire", "go die",
    "kill urself", "end urself",
    "slit your wrists", "overdose on",
    "should kill yourself", "do the world a favor and die",
    "hope you get run over", "hope you get hit by",
    "nobody wants you", "nobody likes you",
    "do everyone a favor",
    "the world is better without you",
    "retard", "retarded", "retards",
    "autistic fuck", "autist",
    "braindead fuck", "braindamaged",
    "waste of life", "waste of space",
    "dogshit player", "dog shit player",
    "shit player", "shitty player",
    "fuck you", "fuckyou", "fk you", "fuk you",
    "screw you", "go fuck yourself",
    "eat shit", "eatshit",
    "suck my", "suck a dick",
    "motherfucker", "son of a bitch",
    "fuck off", "piss off",
    "go fuck",
    "you're a whore", "youre a whore",
    "you're a slut", "youre a slut",
    "you're a bitch", "youre a bitch", "ur a bitch",
    "shut the fuck up", "stfu",
    "you're trash", "youre trash", "ur trash", "you are trash",
    "you're garbage", "youre garbage", "ur garbage", "you are garbage",
    "uninstall life", "uninstall the game",
    "delete the game", "quit the game",
    "you suck", "u suck", "you blow",
    "you're useless", "youre useless", "ur useless", "you are useless",
    "you're worthless", "youre worthless", "ur worthless", "you are worthless",
    "you're pathetic", "youre pathetic", "ur pathetic",
    "you're a joke", "youre a joke",
    "you're the worst", "youre the worst",
    "go back to your cave",
    "ur mom gay", "your mom gay", "your mom is gay",
    "get cancer", "hope you die", "i hope you die",
    "wish you were dead", "hope you get hit",
    "hope you crash",
    "cripple", "spaz", "spastic",
    "downy", "downie", "mongoloid",
    "feminazi",
    "gay ass", "gayboy", "gay boi",
    "piece of shit", "pieceofshit",
    "dumb fuck", "dumbfuck",
    "fucking idiot", "fucking moron",
    "stupid fuck", "stupid ass",
    "useless fuck", "useless piece",
    "asshole", "assholes", "dickhead",
    "dumbass", "dumb ass",
    "brain dead", "braindead",
    "piece of garbage",
    "waste of oxygen",
    "dumb piece",
    "subhuman",
    "braindead monkey", "ape player",
    "monkey brain",
    "lobotomy patient",
    "room temperature iq",
    "team killer", "teamkiller", "tk noob",
    "griefer", "griefing", "trolling you",
    "im griefing", "i am griefing",
    "gonna grief", "going to grief",
    "trash player", "garbage player",
    "ez noob", "ezpz", "2ez",
    "noob team", "bot player",
    "uninstall", "delete game",
    "cancer team", "aids team",
    "braindead team",
    "noob", "noobs",
    "scrub", "scrubs", "bad player",
    "trash team", "get rekt", "rekt",
    "git gud", "get good",
    "you got rekt", "ur so bad",
    "absolute trash", "absolute garbage",
    "totally useless",
    "biggest noob", "worst player",
    "learn to play",
    "stay trash", "stay bad",
    "bot gameplay", "playing like a bot",
    "l4d1 player",
    "couldn't hit a",
    "are you even trying",
    "do you even know how to play",
    "worst team ever",
    "useless team",
    "full of noobs",
    "carried by",
    "dragging us down",
    "you're holding us back",
    "why are you even here",
    "you ruined the run",
    "because of you",
    "thanks for nothing",
    "do something useful",
    "stop feeding",
    "stop dying",
    "why did you do that",
    "nice job idiot",
    "great job moron",
    "way to go genius",
    "congrats you killed us",
    "you got us killed",
    "your fault",
    "blame the noob",
    "this team is garbage",
    "this team is trash",
    "impossible with this team",
    "can't win with these noobs",
    "stuck with noobs",
    "playing with bots would be better",
    "bots are better than you",
    "asdfjkl", "fdjskal",
    "ffffffuuu", "fuuuuuck",
    "puta", "puto", "hijo de puta", "hdp",
    "maricon", "marica", "joto",
    "pendejo", "pendeja", "idiota",
    "mierda", "cagada", "basura",
    "chinga tu madre", "vete a la mierda",
    "cabron", "cabrona", "pinche",
    "culero", "mamaguevo", "malparido",
    "gonorrea", "hijueputa", "mamaverga",
    "verga", "maldito", "estupido",
    "imbecil", "tonto", "pendejada",
    "come mierda", "chupapija", "boludo",
    "pelotudo", "mogolico", "tarado",
    "gil", "boluda", "concha tu madre",
    "eres un pendejo", "eres una puta",
    "vete a la chingada", "jodete",
    "maldita sea", "culpa tuya",
    "eres un estupido", "eres un idiota",
    "mamada", "mamadas",
    "coge mierda", "peda",
    "putito", "cabroncito",
    "eres un inutil", "eres una inutil",
    "no sirves", "no sirves para nada",
    "eres un noob", "eres una noob",
    "equipo de mierda", "equipo de basura",
    "vales nada", "no vales nada",
    "dejame jugar", "sale de la forma",
    "por tu culpa", "por culpa de ti",
    "te mato", "te voy a matar",
    "eres horrible", "juegas horrible",
    "juegas como un noob",
    "eres un bot", "juegas como un bot",
    "eres basura", "eres mierda",
    "eres un estupido jugador",
    "peor equipo",
    "imposible jugar con ustedes",
    "que hacemos contigo",
    "porque eres tan malo",
    "porque eres tan mala",
    "gracias por nada",
    "haz algo util",
    "deja de morir",
    "nos mataste",
    "perdemos por ti",
    "eres un huevon", "huevon",
    "idiota de mierda",
    "eres un estupido de mierda",
    "re idiota", "re estupido",
    "maldita sea la vida",
    "weón", "weon",
    "chucho", "chuchos",
    "eres un chucho",
    "no vales mierda",
    "eres un inutil de mierda",
    "te vale mierda",
    "eres un pendejo de mierda",
    "jugas como un idiota",
    "eres un mion", "mion",
    "eres un cagado", "cagado",
    "equipo de huevones",
    "lleno de huevones",
    "jugas como un cagado",
    "que te pase mierda",
    "eres un imbecil de mierda",
    "блядь", "блять", "пиздец",
    "хуй", "хуи", "хуями",
    "мудак", "мудки", "долбоёб", "долбоеб",
    "ёбаный", "ебаный", "ёбть", "ебть",
    "сука", "суки",
    "говно", "говнюк",
    "тварь", "твари",
    "идиот", "идиоты",
    "дурак", "дураки",
    "лох", "лохи",
    "нуб", "нубы",
    "ты нуб", "ты идиот", "ты дурак",
    "что ты делаешь",
    "играешь как нуб",
    "играешь как дурак",
    "играешь как говно",
    "ты мудак",
    "вы все нубы",
    "ты пиздец",
    "ты не умеешь играть",
    "не умеешь играть",
    "из-за тебя проиграли",
    "из-за тебя умерли",
    "ты провалил",
    "уходи",
    "ты бесполезен",
    "ты ничего не умеешь",
    "самый слабый игрок",
    "худший игрок",
    "слабаки",
    "команда нубов",
    "команда дураков",
    "как же слабо",
    "ты так и не научишься",
    "удали игру",
    "ты тормоз",
    "тормозы",
    "дай мне играть",
    "не мешай играть",
    "из-за тебя",
    "твоя вина",
    "ты виноват"
};

public Plugin myinfo = 
{
    name = "NMT",
    author = "Atom1c",
    description = "Makes toxic players RQ",
    version = "1.2"
};

public void OnPluginStart()
{
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");
    RegConsoleCmd("unlockadmin", Command_UnlockAdmin);
    RegConsoleCmd("disable_ff", Command_DisableFF);
    RegConsoleCmd("freeze", Command_Freeze);
    RegConsoleCmd("randomflick", Command_RandomFlick);
    RegConsoleCmd("no_meds", Command_NoMeds);
    HookEvent("player_hurt", Event_PlayerHurt);
}

public void OnClientConnected(int client)
{
    g_iToxicCount[client] = 0;
    g_bPunishmentComplete[client] = false;
    g_bAdminImmune[client] = true;
    g_iFriendlyFireCount[client] = 0;
}

public void OnClientDisconnect(int client)
{
    g_iToxicCount[client] = 0;
    g_bPunishmentComplete[client] = false;
    g_bAdminImmune[client] = true;
    g_iFriendlyFireCount[client] = 0;
}

bool IsHostOrConsole(int client)
{
    if (client == 0)
        return true;
    if (IsDedicatedServer())
        return false;
    return (client == 1);
}

public Action Command_UnlockAdmin(int client, int args)
{
    if (!IsHostOrConsole(client))
        return Plugin_Handled;
    
    if (args < 1)
    {
        PrintToServer("[WARNS] Usage: unlockadmin <1/0>  (1 = disable immunity, 0 = enable immunity)");
        PrintToServer("[WARNS] Current host immunity: %s", g_bAdminImmune[1] ? "ENABLED" : "DISABLED");
        return Plugin_Handled;
    }
    
    char arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    int value = StringToInt(arg);
    
    if (value == 1)
    {
        g_bAdminImmune[1] = false;
        PrintToServer("[WARNS] Host immunity DISABLED. Host can now be punished by strikes system.");
    }
    else if (value == 0)
    {
        g_bAdminImmune[1] = true;
        PrintToServer("[WARNS] Host immunity ENABLED.");
    }
    else
    {
        PrintToServer("[WARNS] Invalid value. Use 1 or 0.");
    }
    
    return Plugin_Handled;
}

public Action Command_DisableFF(int client, int args)
{
    if (!IsHostOrConsole(client))
        return Plugin_Handled;
    
    if (args < 1)
    {
        PrintToServer("[WARNS] Usage: disable_ff <1/0>  (1 = disable FF system, 0 = enable FF system)");
        PrintToServer("[WARNS] Current FF system: %s", g_bFriendlyFireEnabled ? "ENABLED" : "DISABLED");
        return Plugin_Handled;
    }
    
    char arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    int value = StringToInt(arg);
    
    if (value == 1)
    {
        g_bFriendlyFireEnabled = false;
        PrintToServer("[WARNS] Friendly Fire system DISABLED.");
    }
    else if (value == 0)
    {
        g_bFriendlyFireEnabled = true;
        PrintToServer("[WARNS] Friendly Fire system ENABLED.");
    }
    else
    {
        PrintToServer("[WARNS] Invalid value. Use 1 or 0.");
    }
    
    return Plugin_Handled;
}

public Action Command_Freeze(int client, int args)
{
    if (!IsHostOrConsole(client))
        return Plugin_Handled;
    
    float currentTime = GetGameTime();
    float timeSinceLastFreeze = currentTime - g_fLastFreezeTime;
    
    if (timeSinceLastFreeze < 10.0)
    {
        float remaining = 10.0 - timeSinceLastFreeze;
        PrintToServer("[WARNS] Freeze on cooldown. Wait %.1f more seconds.", remaining);
        return Plugin_Handled;
    }
    
    if (args < 1)
    {
        PrintToServer("[WARNS] Usage: freeze <character name>");
        return Plugin_Handled;
    }
    
    char targetName[64];
    GetCmdArgString(targetName, sizeof(targetName));
    StripQuotes(targetName);
    
    int target = FindTargetByCharacter(targetName);
    if (target == -1)
    {
        PrintToServer("[WARNS] Player not found. Use: nick, rochelle, coach, ellis, bill, zoey, francis, louis");
        return Plugin_Handled;
    }
    
    FreezePlayer(target, 5.0);
    g_fLastFreezeTime = currentTime;
    
    char victimName[64];
    GetClientName(target, victimName, sizeof(victimName));
    PrintToServer("[WARNS] Froze %s for 5 seconds. Cooldown: 10 seconds.", victimName);
    
    return Plugin_Handled;
}

public Action Command_RandomFlick(int client, int args)
{
    if (!IsHostOrConsole(client))
        return Plugin_Handled;
    
    if (args < 1)
    {
        PrintToServer("[WARNS] Usage: randomflick <character name>");
        return Plugin_Handled;
    }
    
    char targetName[64];
    GetCmdArgString(targetName, sizeof(targetName));
    StripQuotes(targetName);
    
    int target = FindTargetByCharacter(targetName);
    if (target == -1)
    {
        PrintToServer("[WARNS] Player not found. Use: nick, rochelle, coach, ellis, bill, zoey, francis, louis");
        return Plugin_Handled;
    }
    
    float newAngles[3];
    newAngles[0] = GetRandomFloat(-89.0, 89.0);
    newAngles[1] = GetRandomFloat(0.0, 360.0);
    newAngles[2] = 0.0;
    
    TeleportEntity(target, NULL_VECTOR, newAngles, NULL_VECTOR);
    
    char victimName[64];
    GetClientName(target, victimName, sizeof(victimName));
    PrintToServer("[WARNS] Flicked %s -> pitch %.1f, yaw %.1f", victimName, newAngles[0], newAngles[1]);
    
    return Plugin_Handled;
}

public Action Command_NoMeds(int client, int args)
{
    if (!IsHostOrConsole(client))
        return Plugin_Handled;
    
    if (args < 1)
    {
        PrintToServer("[WARNS] Usage: no_meds <character name>");
        return Plugin_Handled;
    }
    
    char targetName[64];
    GetCmdArgString(targetName, sizeof(targetName));
    StripQuotes(targetName);
    
    int target = FindTargetByCharacter(targetName);
    if (target == -1)
    {
        PrintToServer("[WARNS] Player not found. Use: nick, rochelle, coach, ellis, bill, zoey, francis, louis");
        return Plugin_Handled;
    }
    
    RemoveAllMeds(target);
    
    char victimName[64];
    GetClientName(target, victimName, sizeof(victimName));
    PrintToServer("[WARNS] Removed meds from %s", victimName);
    
    return Plugin_Handled;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bFriendlyFireEnabled)
        return;
    
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    if (!IsValidClient(attacker) || !IsValidClient(victim))
        return;
    
    if (attacker == victim)
        return;
    
    if (IsFakeClient(victim))
        return;
    
    if (GetClientTeam(attacker) != 2 || GetClientTeam(victim) != 2)
        return;
    
    if (IsHostOrConsole(attacker))
        return;
    
    g_iFriendlyFireCount[attacker]++;
    
    if (g_iFriendlyFireCount[attacker] >= 25)
    {
        char attackerName[64];
        GetClientName(attacker, attackerName, sizeof(attackerName));
        PrintToServer("[WARNS] %s kicked for 25+ friendly fire hits", attackerName);
        KickClient(attacker, "Excessive friendly fire");
    }
}

public Action Command_Say(int client, const char[] command, int argc)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    
    if (client == 1 && g_bAdminImmune[1])
        return Plugin_Continue;
    
    if (g_bPunishmentComplete[client])
        return Plugin_Continue;
    
    char text[256];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);
    
    char lowerText[256];
    strcopy(lowerText, sizeof(lowerText), text);
    for (int i = 0; i < strlen(lowerText); i++)
        lowerText[i] = CharToLower(lowerText[i]);
    
    bool isToxic = false;
    for (int i = 0; i < sizeof(g_sToxicWords); i++)
    {
        if (StrContains(lowerText, g_sToxicWords[i]) != -1)
        {
            isToxic = true;
            break;
        }
    }
    
    if (isToxic)
    {
        g_iToxicCount[client]++;
        
        char playerName[64];
        GetClientName(client, playerName, sizeof(playerName));
        
        switch(g_iToxicCount[client])
        {
            case 1:
            {
                NotifyHost(playerName, 1, "Warning (No Action)");
            }
            case 2:
            {
                DealSilentDamage(client, 10);
                NotifyHost(playerName, 2, "-10 HP");
            }
            case 3:
            {
                DealSilentDamage(client, 15);
                RemoveMedkit(client);
                NotifyHost(playerName, 3, "-15 HP + Medkit Removed");
            }
            case 4:
            {
                DealSilentDamage(client, 25);
                NotifyHost(playerName, 4, "-25 HP");
            }
            case 5:
            {
                RemoveAmmo(client, 60);
                FreezePlayer(client, 3.0);
                g_bPunishmentComplete[client] = true;
                NotifyHost(playerName, 5, "-60% Ammo + Frozen 3s");
            }
        }
    }
    
    return Plugin_Continue;
}

void NotifyHost(const char[] playerName, int strike, const char[] action)
{
    PrintToServer("[WARNS] %s - Strike %d - %s", playerName, strike, action);
}

int FindTargetByCharacter(const char[] characterName)
{
    char lowerTarget[64];
    strcopy(lowerTarget, sizeof(lowerTarget), characterName);
    for (int i = 0; i < strlen(lowerTarget); i++)
        lowerTarget[i] = CharToLower(lowerTarget[i]);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || GetClientTeam(i) != 2)
            continue;
        
        if (!IsPlayerAlive(i))
            continue;
        
        char model[128];
        GetClientModel(i, model, sizeof(model));
        
        if (StrContains(model, "gambler", false) != -1 && StrContains(lowerTarget, "nick", false) != -1)
            return i;
        else if (StrContains(model, "producer", false) != -1 && StrContains(lowerTarget, "rochelle", false) != -1)
            return i;
        else if (StrContains(model, "coach", false) != -1 && StrContains(lowerTarget, "coach", false) != -1)
            return i;
        else if (StrContains(model, "mechanic", false) != -1 && StrContains(lowerTarget, "ellis", false) != -1)
            return i;
        else if (StrContains(model, "namvet", false) != -1 && StrContains(lowerTarget, "bill", false) != -1)
            return i;
        else if (StrContains(model, "teenangst", false) != -1 && StrContains(lowerTarget, "zoey", false) != -1)
            return i;
        else if (StrContains(model, "biker", false) != -1 && StrContains(lowerTarget, "francis", false) != -1)
            return i;
        else if (StrContains(model, "manager", false) != -1 && StrContains(lowerTarget, "louis", false) != -1)
            return i;
    }
    
    return -1;
}

void RemoveAllMeds(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;
    
    int medSlot = GetPlayerWeaponSlot(client, 3);
    if (medSlot != -1)
    {
        RemovePlayerItem(client, medSlot);
        AcceptEntityInput(medSlot, "Kill");
    }
    
    int pillSlot = GetPlayerWeaponSlot(client, 4);
    if (pillSlot != -1)
    {
        RemovePlayerItem(client, pillSlot);
        AcceptEntityInput(pillSlot, "Kill");
    }
}

void RemoveAmmo(int client, int percentage)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;
    
    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon != -1)
    {
        int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
        if (ammoType != -1)
        {
            int currentReserve = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
            int removeAmount = RoundToFloor(currentReserve * (percentage / 100.0));
            int newReserve = currentReserve - removeAmount;
            if (newReserve < 0) newReserve = 0;
            SetEntProp(client, Prop_Send, "m_iAmmo", newReserve, _, ammoType);
        }
    }
}

void FreezePlayer(int client, float duration)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;
    
    SetEntityMoveType(client, MOVETYPE_NONE);
    
    DataPack pack;
    CreateDataTimer(duration, Timer_UnfreezePlayer, pack);
    pack.WriteCell(GetClientUserId(client));
}

public Action Timer_UnfreezePlayer(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int client = GetClientOfUserId(userid);
    
    if (IsValidClient(client) && IsPlayerAlive(client))
        SetEntityMoveType(client, MOVETYPE_WALK);
    
    return Plugin_Stop;
}

void RemoveMedkit(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;
    
    int medkitSlot = GetPlayerWeaponSlot(client, 3);
    if (medkitSlot != -1)
    {
        char className[64];
        GetEdictClassname(medkitSlot, className, sizeof(className));
        if (StrEqual(className, "weapon_first_aid_kit"))
        {
            RemovePlayerItem(client, medkitSlot);
            AcceptEntityInput(medkitSlot, "Kill");
        }
    }
}

void DealSilentDamage(int client, int damage)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;
    
    int currentHealth = GetClientHealth(client);
    int newHealth = currentHealth - damage;
    
    if (newHealth <= 0)
        ForcePlayerSuicide(client);
    else
        SetEntityHealth(client, newHealth);
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}
