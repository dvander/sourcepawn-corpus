#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.2.2"
#define SOUND_CHALLENGE "buttons/bell_normal.wav"     // Clear bell sound for challenge
#define SOUND_ACCEPT   "buttons/button3.wav"         // Positive click for accept
#define SOUND_DECLINE  "buttons/button2.wav"         // Negative click for decline
#define SOUND_WIN      "level/gnomeftw.wav"          // Fun victory sound
#define SOUND_LOSE     "buttons/button10.wav"        // Deep tone for loss
#define SOUND_TIE      "buttons/blip1.wav"           // Neutral beep for tie

char g_sWinMessages[][] = {
    "absolutely destroyed",
    "completely demolished",
    "utterly humiliated",
    "totally owned",
    "schooled",
    "showed who's boss to",
    "triumphantly defeated",
    "laughed in the face of",
    "made quick work of",
    "proved their superiority to"
};

char g_sLoseMessages[][] = {
    "Better luck next time!",
    "Practice makes perfect!",
    "Don't quit your day job!",
    "Maybe try Tic-tac-toe instead?",
    "That was... unfortunate.",
    "Ouch, that's gotta hurt!",
    "Did you even try?",
    "At least you participated!",
    "There's always next time!",
    "Even a Tank would have played better!"
};

enum struct RPSGame {
    int challenger;
    int opponent;
    int challengerChoice;
    int opponentChoice;
    bool isActive;
    Handle timer;
}

RPSGame g_RPSGame;

// ConVars
ConVar g_cvTimeToAccept;
ConVar g_cvTimeToChoice;
ConVar g_cvVersion;

Handle g_hAdvertTimer = null;

public Plugin myinfo = {
    name = "L4D2 Rock Paper Scissors",
    author = "Mezo123451A",
    description = "Safe Room RPS Mini-game",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart() {
    // Commands
    RegConsoleCmd("sm_rps", Command_RPS, "Start RPS game");
    RegConsoleCmd("sm_accept", Command_Accept, "Accept RPS challenge");
    RegConsoleCmd("sm_decline", Command_Decline, "Decline RPS challenge");
    RegConsoleCmd("sm_rock", Command_Rock, "Choose Rock");
    RegConsoleCmd("sm_paper", Command_Paper, "Choose Paper");
    RegConsoleCmd("sm_scissors", Command_Scissors, "Choose Scissors");
    
    // ConVars
    g_cvTimeToAccept = CreateConVar("l4d2_rps_accept_time", "15.0", "Time in seconds to accept challenge");
    g_cvTimeToChoice = CreateConVar("l4d2_rps_choice_time", "15.0", "Time in seconds to make choice");
    g_cvVersion = CreateConVar("l4d2_rps_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
    
    // Create config file
    AutoExecConfig(true, "l4d2_rps");
    
    ResetGame();
}

public void OnMapStart() {
    // Precache sounds with error checking
    if (!PrecacheSound(SOUND_CHALLENGE, true)) LogError("Failed to precache sound: %s", SOUND_CHALLENGE);
    if (!PrecacheSound(SOUND_ACCEPT, true)) LogError("Failed to precache sound: %s", SOUND_ACCEPT);
    if (!PrecacheSound(SOUND_DECLINE, true)) LogError("Failed to precache sound: %s", SOUND_DECLINE);
    if (!PrecacheSound(SOUND_WIN, true)) LogError("Failed to precache sound: %s", SOUND_WIN);
    if (!PrecacheSound(SOUND_LOSE, true)) LogError("Failed to precache sound: %s", SOUND_LOSE);
    if (!PrecacheSound(SOUND_TIE, true)) LogError("Failed to precache sound: %s", SOUND_TIE);
    
    // Start advertisement timer
    if (g_hAdvertTimer != null) {
        KillTimer(g_hAdvertTimer);
        g_hAdvertTimer = null;
    }
    CreateNextAdvertisement();
}

void ResetGame() {
    g_RPSGame.challenger = 0;
    g_RPSGame.opponent = 0;
    g_RPSGame.challengerChoice = 0;
    g_RPSGame.opponentChoice = 0;
    g_RPSGame.isActive = false;
    
    if (g_RPSGame.timer != null) {
        KillTimer(g_RPSGame.timer);
        g_RPSGame.timer = null;
    }
}

public Action Command_RPS(int client, int args) {
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
        ReplyToCommand(client, "[RPS] You must be alive to play!");
        return Plugin_Handled;
    }
    
    if (g_RPSGame.isActive) {
        ReplyToCommand(client, "[RPS] A game is already in progress!");
        return Plugin_Handled;
    }
    
    if (args < 1) {
        ShowPlayerList(client);
        return Plugin_Handled;
    }
    
    char targetName[32];
    GetCmdArg(1, targetName, sizeof(targetName));
    
    int target = FindTarget(client, targetName, true, false);
    if (target == -1) return Plugin_Handled;
    
    StartChallenge(client, target);
    return Plugin_Handled;
}

void ShowPlayerList(int client) {
    Menu menu = new Menu(MenuHandler_PlayerSelect);
    menu.SetTitle("Select a player to challenge:");
    
    char name[MAX_NAME_LENGTH];
    char userid[8];
    bool playersFound = false;
    
    for (int i = 1; i <= MaxClients; i++) {
        // Check if client is:
        // 1. Not the command user
        // 2. In game
        // 3. Not a bot
        // 4. On survivor team
        if (i != client && 
            IsClientInGame(i) && 
            !IsFakeClient(i) && 
            GetClientTeam(i) == 2) {
            
            GetClientName(i, name, sizeof(name));
            IntToString(GetClientUserId(i), userid, sizeof(userid));
            menu.AddItem(userid, name);
            playersFound = true;
        }
    }
    
    if (!playersFound) {
        PrintToChat(client, "\x04[RPS]\x01 No players available to challenge!");
        delete menu;
        return;
    }
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PlayerSelect(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char userid[8];
            menu.GetItem(param2, userid, sizeof(userid));
            
            int target = GetClientOfUserId(StringToInt(userid));
            if (target == 0) {
                PrintToChat(param1, "\x04[RPS]\x01 Selected player is no longer available!");
                return 0;
            }
            
            StartChallenge(param1, target);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
    return 0;
}

void StartChallenge(int challenger, int opponent) {
    g_RPSGame.challenger = challenger;
    g_RPSGame.opponent = opponent;
    g_RPSGame.isActive = true;
    
    // Only notify challenger that they sent the challenge
    PrintToChat(challenger, "\x04[RPS]\x01 Challenge sent to \x05%N\x01!", opponent);
    
    // Only notify opponent about the challenge and instructions
    PrintToChat(opponent, "\x04[RPS]\x01 \x05%N\x01 has challenged you to Rock Paper Scissors!", challenger);
    PrintToChat(opponent, "\x04[RPS]\x01 Type \x05!accept\x01 to play or \x05!decline\x01 to refuse");
    
    // Only play challenge sound for the person being challenged
    PlaySound(opponent, SOUND_CHALLENGE);
    
    g_RPSGame.timer = CreateTimer(g_cvTimeToAccept.FloatValue, Timer_ChallengeTimeout);
}

public Action Timer_ChallengeTimeout(Handle timer) {
    if (g_RPSGame.isActive && g_RPSGame.challengerChoice == 0 && g_RPSGame.opponentChoice == 0) {
        PrintToChatAll("[RPS] Challenge timed out!");
        PlaySound(g_RPSGame.challenger, SOUND_DECLINE);
        PlaySound(g_RPSGame.opponent, SOUND_DECLINE);
        ResetGame();
    }
    return Plugin_Stop;
}

public Action Command_Accept(int client, int args) {
    if (!g_RPSGame.isActive || client != g_RPSGame.opponent) return Plugin_Handled;
    
    PrintToChatAll("[RPS] Game starting!");
    
    // Play accept sound for both players
    PlaySound(g_RPSGame.challenger, SOUND_ACCEPT);
    PlaySound(g_RPSGame.opponent, SOUND_ACCEPT);
    
    // Show menus to both players
    ShowChoiceMenu(g_RPSGame.challenger);
    ShowChoiceMenu(g_RPSGame.opponent);
    
    g_RPSGame.timer = CreateTimer(g_cvTimeToChoice.FloatValue, Timer_ChoiceTimeout);
    
    return Plugin_Handled;
}

public Action Command_Decline(int client, int args) {
    if (!g_RPSGame.isActive || client != g_RPSGame.opponent) return Plugin_Handled;
    
    PrintToChatAll("[RPS] %N declined the challenge!", client);
    
    // Play decline sound for both players
    PlaySound(g_RPSGame.challenger, SOUND_DECLINE);
    PlaySound(g_RPSGame.opponent, SOUND_DECLINE);
    
    ResetGame();
    return Plugin_Handled;
}

public Action Command_Rock(int client, int args) {
    return MakeChoice(client, 1);
}

public Action Command_Paper(int client, int args) {
    return MakeChoice(client, 2);
}

public Action Command_Scissors(int client, int args) {
    return MakeChoice(client, 3);
}

Action MakeChoice(int client, int choice) {
    if (!g_RPSGame.isActive) return Plugin_Handled;
    
    char choiceName[32];
    switch (choice) {
        case 1: choiceName = "Rock";
        case 2: choiceName = "Paper";
        case 3: choiceName = "Scissors";
    }
    
    // Store the choice and notify the player
    if (client == g_RPSGame.challenger) {
        g_RPSGame.challengerChoice = choice;
        PrintToChat(client, "\x04[RPS]\x01 You chose: \x05%s\x01", choiceName);
    } else if (client == g_RPSGame.opponent) {
        g_RPSGame.opponentChoice = choice;
        PrintToChat(client, "\x04[RPS]\x01 You chose: \x05%s\x01", choiceName);
    } else {
        return Plugin_Handled;
    }
    
    // Check if both players have made their choices
    if (g_RPSGame.challengerChoice != 0 && g_RPSGame.opponentChoice != 0) {
        DetermineWinner();
    }
    
    return Plugin_Handled;
}

void DetermineWinner() {
    // Get choice names for both players
    char challengerChoice[32], opponentChoice[32];
    switch (g_RPSGame.challengerChoice) {
        case 1: challengerChoice = "Rock";
        case 2: challengerChoice = "Paper";
        case 3: challengerChoice = "Scissors";
    }
    switch (g_RPSGame.opponentChoice) {
        case 1: opponentChoice = "Rock";
        case 2: opponentChoice = "Paper";
        case 3: opponentChoice = "Scissors";
    }
    
    // Announce both choices to all players
    PrintToChatAll("\x04[RPS]\x01 \x05%N\x01 chose \x04%s\x01 and \x05%N\x01 chose \x04%s\x01!", 
        g_RPSGame.challenger, challengerChoice,
        g_RPSGame.opponent, opponentChoice);
    
    int winner = 0;
    int loser = 0;
    
    if (g_RPSGame.challengerChoice == g_RPSGame.opponentChoice) {
        PrintToChatAll("\x04[RPS]\x01 It's a tie! Both players chose the same move!");
        PlaySound(g_RPSGame.challenger, SOUND_TIE);
        PlaySound(g_RPSGame.opponent, SOUND_TIE);
    } 
    else if ((g_RPSGame.challengerChoice == 1 && g_RPSGame.opponentChoice == 3) || 
             (g_RPSGame.challengerChoice == 2 && g_RPSGame.opponentChoice == 1) || 
             (g_RPSGame.challengerChoice == 3 && g_RPSGame.opponentChoice == 2)) {
        winner = g_RPSGame.challenger;
        loser = g_RPSGame.opponent;
    } 
    else {
        winner = g_RPSGame.opponent;
        loser = g_RPSGame.challenger;
    }
    
    if (winner && loser) {
        int winIndex = GetRandomInt(0, sizeof(g_sWinMessages) - 1);
        int loseIndex = GetRandomInt(0, sizeof(g_sLoseMessages) - 1);
        
        PrintToChatAll("\x04[RPS]\x01 \x05%N\x01 %s \x05%N\x01!", 
            winner, 
            g_sWinMessages[winIndex], 
            loser);
        PrintToChat(loser, "\x04[RPS]\x01 %s", g_sLoseMessages[loseIndex]);
        
        PlaySound(winner, SOUND_WIN);
        PlaySound(loser, SOUND_LOSE);
    }
    
    ResetGame();
}

public Action Timer_ChoiceTimeout(Handle timer) {
    if (g_RPSGame.isActive) {
        PrintToChatAll("[RPS] Time's up! Game cancelled!");
        PlaySound(g_RPSGame.challenger, SOUND_DECLINE);
        PlaySound(g_RPSGame.opponent, SOUND_DECLINE);
        ResetGame();
    }
    return Plugin_Stop;
}

public Action Timer_Advertisement(Handle timer) {
    g_hAdvertTimer = null;
    
    // Only show advertisement if no game is in progress
    if (!g_RPSGame.isActive) {
        PrintToChatAll("\x04[RPS]\x01 Type \x05!rps\x01 to challenge someone to Rock Paper Scissors!");
    }
    
    // Create next advertisement timer
    float nextAd = GetRandomFloat(60.0, 120.0);
    g_hAdvertTimer = CreateTimer(nextAd, Timer_Advertisement);
    
    return Plugin_Stop;
}

public Action Timer_ChallengeReminder(Handle timer, any userid) {
    int client = GetClientOfUserId(userid);
    
    if (client && g_RPSGame.isActive && client == g_RPSGame.opponent) {
        PrintToChat(client, "\x04[RPS]\x01 Type \x05!accept\x01 to play or \x05!decline\x01 to refuse");
    }
    
    return Plugin_Stop;
}

void ShowChoiceMenu(int client) {
    Menu menu = new Menu(MenuHandler_RPSChoice);
    menu.SetTitle("Choose your move:");
    
    menu.AddItem("1", "Rock");
    menu.AddItem("2", "Paper");
    menu.AddItem("3", "Scissors");
    
    menu.ExitButton = false;
    menu.Display(client, 10); // Display for 10 seconds
}

public int MenuHandler_RPSChoice(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char choice[2];
            menu.GetItem(param2, choice, sizeof(choice));
            
            // Convert choice to number and process it
            MakeChoice(param1, StringToInt(choice));
        }
        case MenuAction_End: {
            delete menu;
        }
        case MenuAction_Cancel: {
            if (param2 == MenuCancel_Timeout) {
                PrintToChat(param1, "\x04[RPS]\x01 You took too long to choose!");
                if (g_RPSGame.isActive) {
                    ResetGame();
                }
            }
        }
    }
    return 0;
}

void PlaySound(int client, const char[] sound) {
    if (IsValidClient(client)) {
        ClientCommand(client, "play *%s", sound);
    }
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

public void OnMapEnd() {
    if (g_hAdvertTimer != null) {
        KillTimer(g_hAdvertTimer);
        g_hAdvertTimer = null;
    }
}

void CreateNextAdvertisement() {
    // Random time between 60 and 120 seconds
    float nextAd = GetRandomFloat(60.0, 120.0);
    g_hAdvertTimer = CreateTimer(nextAd, Timer_Advertisement);
}