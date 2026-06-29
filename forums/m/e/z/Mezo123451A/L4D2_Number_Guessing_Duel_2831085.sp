#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1.1"
#define SOUND_CHALLENGE "buttons/bell_normal.wav"
#define SOUND_ACCEPT    "buttons/button3.wav"
#define SOUND_DECLINE   "buttons/button2.wav"
#define SOUND_WIN       "level/gnomeftw.wav"
#define SOUND_HINT      "buttons/blip1.wav"
#define SOUND_LOSE     "buttons/button10.wav"        // Deep tone for loss
#define SOUND_TIE      "buttons/blip1.wav"           // Neutral beep for tie

enum struct GuessGame {
    int challenger;
    int opponent;
    int targetNumber;
    int currentTurn;
    int lastGuess;
    bool isActive;
    Handle timer;
    int challengerChoice;
    int opponentChoice;
    int guessCount; // Add guessCount to track total guesses for EndGameDueToMaxGuesses
}

GuessGame g_GuessGame;

public Plugin myinfo = {
    name = "L4D2 Number Guessing Duel",
    author = "Mezo123451A",
    description = "Safe Room Number Guessing Mini-game",
    version = PLUGIN_VERSION,
    url = ""
};

// ConVars
ConVar g_cvTimeToAccept;
ConVar g_cvTimePerTurn;
ConVar g_cvVersion;

public void OnPluginStart() {
    // Commands
    RegConsoleCmd("sm_guess", Command_StartGuess, "Start Number Guessing game");
    RegConsoleCmd("sm_accept", Command_Accept, "Accept challenge");
    RegConsoleCmd("sm_decline", Command_Decline, "Decline challenge");
    
    // Register commands for numbers 1-100
    char command[8];
    for (int i = 1; i <= 100; i++) {
        Format(command, sizeof(command), "sm_%d", i);
        RegConsoleCmd(command, Command_NumberGuess, "Make a guess");
    }
    
    // ConVars
    g_cvTimeToAccept = CreateConVar("l4d2_guess_accept_time", "15.0", "Time in seconds to accept challenge");
    g_cvTimePerTurn = CreateConVar("l4d2_guess_turn_time", "15.0", "Time in seconds to make choice");
    g_cvVersion = CreateConVar("l4d2_guess_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
    
    // Create config file
    AutoExecConfig(true, "l4d2_guess");
    
    ResetGame();
}

public Action Command_StartGuess(int client, int args) {
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
        ReplyToCommand(client, "[GUESS] You must be alive to play!");
        return Plugin_Handled;
    }
    
    if (g_GuessGame.isActive) {
        ReplyToCommand(client, "[GUESS] A game is already in progress!");
        return Plugin_Handled;
    }
    
    if (args < 1) {
        ShowPlayerList(client);
        return Plugin_Handled;
    }
    
    return Plugin_Handled;
}

void ShowPlayerList(int client) {
    Menu menu = new Menu(MenuHandler_PlayerSelect);
    menu.SetTitle("Select a player to challenge:");
    
    char name[MAX_NAME_LENGTH];
    char userid[8];
    bool playersFound = false;
    
    for (int i = 1; i <= MaxClients; i++) {
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
        PrintToChat(client, "\x04[GUESS]\x01 No players available to challenge!");
        delete menu;
        return;
    }
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public Action Command_NumberGuess(int client, int args) {
    if (!g_GuessGame.isActive || (client != g_GuessGame.challenger && client != g_GuessGame.opponent)) {
        return Plugin_Handled;
    }
    
    // Check if it's player's turn
    if ((g_GuessGame.currentTurn == 1 && client != g_GuessGame.challenger) || 
        (g_GuessGame.currentTurn == 2 && client != g_GuessGame.opponent)) {
        PrintToChat(client, "\x04[GUESS]\x01 It's not your turn!");
        return Plugin_Handled;
    }
    
    // Get the number from the command name
    char command[8];
    GetCmdArg(0, command, sizeof(command));
    ReplaceString(command, sizeof(command), "sm_", "");
    int guess = StringToInt(command);
    
    ProcessGuess(client, guess);
    return Plugin_Handled;
}

void ProcessGuess(int client, int guess) {
    // Store the guess for the appropriate player
    if (client == g_GuessGame.challenger) {
        g_GuessGame.challengerChoice = guess;
    } else {
        g_GuessGame.opponentChoice = guess;
    }
    
    // Only show the number to the player who guessed
    PrintToChat(client, "\x04[GUESS]\x01 You guessed: \x04%d\x01!", guess);
    
    // Show to others that a guess was made, but not the number
    for (int i = 1; i <= MaxClients; i++) {
        if (i != client && IsClientInGame(i)) {
            PrintToChat(i, "\x04[GUESS]\x01 \x05%N\x01 made their guess!", client);
        }
    }
    
    // If both players have guessed, determine the winner
    if ((g_GuessGame.challenger == client && g_GuessGame.opponentChoice != 0) || 
        (g_GuessGame.opponent == client && g_GuessGame.challengerChoice != 0)) {
        DetermineWinner();
        return;
    }
    
    // Switch turns and start new timer
    g_GuessGame.currentTurn = (g_GuessGame.currentTurn == 1) ? 2 : 1;
    int nextPlayer = (g_GuessGame.currentTurn == 1) ? g_GuessGame.challenger : g_GuessGame.opponent;
    
    // Kill existing timer if any
    if (g_GuessGame.timer != null) {
        KillTimer(g_GuessGame.timer);
    }
    
    // Create new turn timer
    g_GuessGame.timer = CreateTimer(g_cvTimePerTurn.FloatValue, Timer_TurnTimeout);
    
    PrintToChat(nextPlayer, "\x04[GUESS]\x01 It's your turn! Type \x05!<number>\x01 to make your guess!");
}

void DetermineWinner() {
    int challengerDiff = Abs(g_GuessGame.targetNumber - g_GuessGame.challengerChoice);
    int opponentDiff = Abs(g_GuessGame.targetNumber - g_GuessGame.opponentChoice);
    
    // Announce the target number and both guesses
    PrintToChatAll("\x04[GUESS]\x01 The number was \x04%d\x01!", g_GuessGame.targetNumber);
    PrintToChatAll("\x04[GUESS]\x01 \x05%N\x01 guessed \x04%d\x01 (off by %d)", 
        g_GuessGame.challenger, g_GuessGame.challengerChoice, challengerDiff);
    PrintToChatAll("\x04[GUESS]\x01 \x05%N\x01 guessed \x04%d\x01 (off by %d)", 
        g_GuessGame.opponent, g_GuessGame.opponentChoice, opponentDiff);
    
    // Determine winner
    if (challengerDiff == opponentDiff) {
        PrintToChatAll("\x04[GUESS]\x01 It's a tie! Both players were equally close!");
        PlaySound(g_GuessGame.challenger, SOUND_TIE);
        PlaySound(g_GuessGame.opponent, SOUND_TIE);
    } else if (challengerDiff < opponentDiff) {
        PrintToChatAll("\x04[GUESS]\x01 \x05%N\x01 wins by being closer!", g_GuessGame.challenger);
        PlaySound(g_GuessGame.challenger, SOUND_WIN);
        PlaySound(g_GuessGame.opponent, SOUND_LOSE);
    } else {
        PrintToChatAll("\x04[GUESS]\x01 \x05%N\x01 wins by being closer!", g_GuessGame.opponent);
        PlaySound(g_GuessGame.opponent, SOUND_WIN);
        PlaySound(g_GuessGame.challenger, SOUND_LOSE);
    }
    
    ResetGame();
}

void StartChallenge(int challenger, int opponent) {
    g_GuessGame.challenger = challenger;
    g_GuessGame.opponent = opponent;
    g_GuessGame.isActive = true;
    
    PrintToChat(challenger, "\x04[GUESS]\x01 Challenge sent to \x05%N\x01!", opponent);
    PrintToChat(opponent, "\x04[GUESS]\x01 \x05%N\x01 has challenged you to a Number Guessing game!", challenger);
    PrintToChat(opponent, "\x04[GUESS]\x01 Type \x05!accept\x01 to play or \x05!decline\x01 to refuse");
    
    PlaySound(opponent, SOUND_CHALLENGE);
    
    // Create challenge timeout timer
    g_GuessGame.timer = CreateTimer(g_cvTimeToAccept.FloatValue, Timer_ChallengeTimeout);
}

void StartGame(int challenger, int opponent) {
    g_GuessGame.challenger = challenger;
    g_GuessGame.opponent = opponent;
    g_GuessGame.targetNumber = GetRandomInt(1, 100);
    g_GuessGame.currentTurn = 1; // Challenger goes first
    g_GuessGame.isActive = true;
    g_GuessGame.challengerChoice = 0;
    g_GuessGame.opponentChoice = 0;
    
    // Add timer for turn timeout
    if (g_GuessGame.timer != null) {
        KillTimer(g_GuessGame.timer);
    }
    g_GuessGame.timer = CreateTimer(g_cvTimePerTurn.FloatValue, Timer_TurnTimeout);
    
    PrintToChatAll("\x04[GUESS]\x01 Game starting! \x05%N\x01 vs \x05%N\x01!", 
        challenger, opponent);
    PrintToChatAll("\x04[GUESS]\x01 I'm thinking of a number between \x051\x01 and \x05100\x01!");
    PrintToChat(challenger, "\x04[GUESS]\x01 You go first! Type \x05!<number>\x01");
}

public Action Timer_TurnTimeout(Handle timer) {
    if (!g_GuessGame.isActive) return Plugin_Stop;
    
    int currentPlayer = (g_GuessGame.currentTurn == 1) ? g_GuessGame.challenger : g_GuessGame.opponent;
    PrintToChatAll("\x04[GUESS]\x01 \x05%N\x01 took too long to guess! Game Over!", currentPlayer);
    
    // Play decline sound for both players
    PlaySound(g_GuessGame.challenger, SOUND_DECLINE);
    PlaySound(g_GuessGame.opponent, SOUND_DECLINE);
    
    // End the game instead of switching turns
    ResetGame();
    
    return Plugin_Stop;
}

int Abs(int value) {
    return (value < 0) ? -value : value;
}

void ResetGame() {
    g_GuessGame.challenger = 0;
    g_GuessGame.opponent = 0;
    g_GuessGame.targetNumber = 0;
    g_GuessGame.currentTurn = 0;
    g_GuessGame.lastGuess = 0;
    g_GuessGame.isActive = false;
    g_GuessGame.challengerChoice = 0;
    g_GuessGame.opponentChoice = 0;
    
    if (g_GuessGame.timer != null) {
        KillTimer(g_GuessGame.timer);
        g_GuessGame.timer = null;
    }
}

public Action Command_Accept(int client, int args) {
    if (!g_GuessGame.isActive || client != g_GuessGame.opponent) return Plugin_Handled;
    
    // Kill existing timer
    if (g_GuessGame.timer != null) {
        KillTimer(g_GuessGame.timer);
        g_GuessGame.timer = null;
    }
    
    StartGame(g_GuessGame.challenger, g_GuessGame.opponent);
    PlaySound(g_GuessGame.challenger, SOUND_ACCEPT);
    PlaySound(g_GuessGame.opponent, SOUND_ACCEPT);
    
    return Plugin_Handled;
}

public Action Command_Decline(int client, int args) {
    if (!g_GuessGame.isActive || client != g_GuessGame.opponent) return Plugin_Handled;
    
    PrintToChatAll("\x04[GUESS]\x01 %N declined the challenge!", client);
    PlaySound(g_GuessGame.challenger, SOUND_DECLINE);
    PlaySound(g_GuessGame.opponent, SOUND_DECLINE);
    
    ResetGame();
    return Plugin_Handled;
}

public int MenuHandler_PlayerSelect(Menu menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char userid[8];
            menu.GetItem(param2, userid, sizeof(userid));
            
            int target = GetClientOfUserId(StringToInt(userid));
            if (target == 0) {
                PrintToChat(param1, "\x04[GUESS]\x01 Selected player is no longer available!");
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

void PlaySound(int client, const char[] sound) {
    if (IsValidClient(client)) {
        ClientCommand(client, "play *%s", sound);
    }
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

// Advertisement system
Handle g_hAdvertTimer = null;

public void OnMapStart() {
    // Precache sounds with error checking
    if (!PrecacheSound(SOUND_CHALLENGE, true)) LogError("Failed to precache sound: %s", SOUND_CHALLENGE);
    if (!PrecacheSound(SOUND_ACCEPT, true)) LogError("Failed to precache sound: %s", SOUND_ACCEPT);
    if (!PrecacheSound(SOUND_DECLINE, true)) LogError("Failed to precache sound: %s", SOUND_DECLINE);
    if (!PrecacheSound(SOUND_WIN, true)) LogError("Failed to precache sound: %s", SOUND_WIN);
    if (!PrecacheSound(SOUND_LOSE, true)) LogError("Failed to precache sound: %s", SOUND_LOSE);
    if (!PrecacheSound(SOUND_TIE, true)) LogError("Failed to precache sound: %s", SOUND_TIE);
    
    // Start advertisement timer
    CreateNextAdvertisement();
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

public Action Timer_Advertisement(Handle timer) {
    g_hAdvertTimer = null;
    
    // Only show advertisement if no game is in progress
    if (!g_GuessGame.isActive) {
        PrintToChatAll("\x04[GUESS]\x01 Type \x05!guess\x01 to challenge someone to a Number Guessing Duel! Guess the number between 1-100!");
    }
    
    // Create next advertisement timer
    CreateNextAdvertisement();
    
    return Plugin_Stop;
}

public Action Timer_ChallengeTimeout(Handle timer) {
    if (!g_GuessGame.isActive) return Plugin_Stop;
    
    PrintToChatAll("\x04[GUESS]\x01 Challenge timed out!");
    PlaySound(g_GuessGame.challenger, SOUND_DECLINE);
    PlaySound(g_GuessGame.opponent, SOUND_DECLINE);
    ResetGame();
    
    return Plugin_Stop;
}
