#include <sourcemod>
#include <SteamWorks>
#include <regex>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.3"
#define MAX_MESSAGE_LENGTH 1024
#define MAX_RESPONSE_LENGTH 2048
#define MAX_CHAT_LENGTH 128  // Maximum length for a single chat message in Source Engine

// Gemini API settings
#define GEMINI_API_HOST "generativelanguage.googleapis.com"
#define GEMINI_API_ENDPOINT "/v1/models/gemini-2.0-flash-lite:generateContent"

// HTTP Status Codes
#define HTTP_STATUS_OK 200
#define HTTP_STATUS_BAD_REQUEST 400
#define HTTP_STATUS_UNAUTHORIZED 401
#define HTTP_STATUS_FORBIDDEN 403
#define HTTP_STATUS_NOT_FOUND 404
#define HTTP_STATUS_TOO_MANY_REQUESTS 429

// ConVars
ConVar g_cvGeminiAPIKey;
ConVar g_cvChatPrefix;
ConVar g_cvMaxTokens;
ConVar g_cvCooldown;
ConVar g_cvSystemPrompt;
ConVar g_cvInfoMessages;    // Whether to show info messages
ConVar g_cvInfoInterval;    // Interval between info messages
ConVar g_cvVersion;         // Plugin version ConVar
ConVar g_cvMessageDelay;    // Delay between sequential chat messages
ConVar g_cvLowImpactMode;   // Enable low impact mode for better performance

// User data
float g_flLastCommandTime[MAXPLAYERS + 1];

// Timer handle for info messages
Handle g_hInfoTimer = null;

// Info messages about the plugin
char g_szInfoMessages[][] = {
    "This server is running the Left 4 Chat 2 plugin! Use !ai <question> to ask anything.",
    "Want to chat with an AI? Type !ai followed by your question.",
    "Did you know you can use !ai to ask questions and get instant answers?",
    "Need information or help? Ask AI using !ai <your question>.",
    "Have a question? Type !ai <question> to get an answer from AI.",
    "The Left 4 Chat 2 plugin lets you talk to an AI. Try !ai <question> to get started!",
    "Ask AI anything using !ai <question> - it's like having an encyclopedia in the game!",
    "Need gameplay tips? Ask with !ai tips for <game mode>",
    "There's a 5 second cooldown between AI questions to prevent spam."
};

public Plugin myinfo = {
    name = "Left 4 Chat 2",
    author = "Mezo123451A",
    description = "Chat with AI in Left 4 Dead 2",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart() {
    // Create ConVars
    g_cvGeminiAPIKey = CreateConVar("left4chat2_api_key", "", "Gemini API Key", FCVAR_PROTECTED);
    g_cvChatPrefix = CreateConVar("left4chat2_prefix", "[AI]", "Chat prefix for AI responses");
    g_cvMaxTokens = CreateConVar("left4chat2_max_tokens", "256", "Maximum tokens for AI response");
    g_cvCooldown = CreateConVar("left4chat2_cooldown", "5.0", "Cooldown between AI requests (in seconds)");
    g_cvSystemPrompt = CreateConVar("left4chat2_system_prompt", "IMPORTANT: You are a general-purpose AI assistant answering questions in a game chat. DO NOT role-play as if you're in a zombie apocalypse. DO NOT pretend to be a survivor. DO NOT use phrases like 'stay sharp' or 'watch out'. Just answer questions directly and helpfully like a normal AI assistant would.", "System prompt for the AI");
    g_cvInfoMessages = CreateConVar("left4chat2_info_messages", "1", "Whether to show periodic info messages about the plugin (1 = enable, 0 = disable)");
    g_cvInfoInterval = CreateConVar("left4chat2_info_interval", "90.0", "Average interval in seconds between info messages (range will be 0.67x to 1.33x this value)");
    g_cvVersion = CreateConVar("left4chat2_version", PLUGIN_VERSION, "Left 4 Chat 2 plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_cvMessageDelay = CreateConVar("left4chat2_message_delay", "0.3", "Delay between sequential chat messages (lower = faster but may cause stutter, higher = slower but smoother)", _, true, 0.1, true, 1.0);
    g_cvLowImpactMode = CreateConVar("left4chat2_low_impact_mode", "0", "Enable low-impact mode to reduce network overhead and ping (1 = enable, 0 = disable)", _, true, 0.0, true, 1.0);
    
    // Register commands
    RegConsoleCmd("sm_ai", Command_AskAI, "Ask AI a question");
    
    // Admin command to set API key in-game
    RegConsoleCmd("sm_setapikey", Command_SetAPIKey, "Set the Gemini API key");
    
    // Register additional plugin commands
    RegisterPluginCommands();
    
    // Hook ConVar changes
    HookConVarChange(g_cvInfoMessages, OnInfoMessagesChanged);
    
    // Create config
    AutoExecConfig(true, "left4chat2");
    
    // Start info message timer if enabled
    if (g_cvInfoMessages.BoolValue) {
        StartInfoMessageTimer();
    }
}

public void OnInfoMessagesChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    // Start or stop info message timer based on new setting
    bool enabled = StringToInt(newValue) == 1;
    
    if (enabled && g_hInfoTimer == null) {
        StartInfoMessageTimer();
    } else if (!enabled && g_hInfoTimer != null) {
        StopInfoMessageTimer();
    }
}

public void OnMapStart() {
    // Restart the info message timer when a map starts
    if (g_cvInfoMessages.BoolValue) {
        StartInfoMessageTimer();
    }
    
    // Reset cooldowns for all players on map change
    ResetAllCooldowns();
}

public void OnMapEnd() {
    // Stop the timer when the map ends
    StopInfoMessageTimer();
}

void StartInfoMessageTimer() {
    // Stop existing timer if any
    StopInfoMessageTimer();
    
    // Calculate a random delay for the first message
    float baseInterval = g_cvInfoInterval.FloatValue;
    float randomDelay = GetRandomFloat(baseInterval * 0.67, baseInterval * 1.33);
    
    // Start the timer
    g_hInfoTimer = CreateTimer(randomDelay, Timer_ShowInfoMessage, _, TIMER_FLAG_NO_MAPCHANGE);
}

void StopInfoMessageTimer() {
    if (g_hInfoTimer != null) {
        KillTimer(g_hInfoTimer);
        g_hInfoTimer = null;
    }
}

public Action Timer_ShowInfoMessage(Handle timer, any data) {
    // Reset timer handle
    g_hInfoTimer = null;
    
    // Only show message if there are players on the server
    if (GetClientCount(true) > 0) {
        // Select a random message
        int messageIndex = GetRandomInt(0, sizeof(g_szInfoMessages) - 1);
        
        // Get chat prefix
        char prefix[32];
        g_cvChatPrefix.GetString(prefix, sizeof(prefix));
        
        // Display the message to all players
        PrintToChatAll("\x01%s \x03Info: \x05%s", prefix, g_szInfoMessages[messageIndex]);
    }
    
    // Schedule the next message
    float baseInterval = g_cvInfoInterval.FloatValue;
    float randomDelay = GetRandomFloat(baseInterval * 0.67, baseInterval * 1.33);
    g_hInfoTimer = CreateTimer(randomDelay, Timer_ShowInfoMessage, _, TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Continue;
}

public Action Command_SetAPIKey(int client, int args) {
    // Allow console to set API key
    if (client == 0) {
        if (args < 1) {
            PrintToServer("Usage: sm_setapikey <api_key>");
            return Plugin_Handled;
        }
        
        char apiKey[64];
        GetCmdArg(1, apiKey, sizeof(apiKey));
        
        // Validate API key format (basic check for AIzaSy prefix)
        if (strncmp(apiKey, "AIzaSy", 6) != 0 || strlen(apiKey) < 30) {
            PrintToServer("Error: Invalid API key format. Google API keys typically start with 'AIzaSy' and are at least 30 characters long.");
            return Plugin_Handled;
        }
        
        g_cvGeminiAPIKey.SetString(apiKey);
        PrintToServer("API key has been set.");
        return Plugin_Handled;
    }
    
    // Only allow the local listen server host (or admins with ADMFLAG_ROOT) to set the API key
    if (!CheckCommandAccess(client, "sm_setapikey", ADMFLAG_ROOT) && !IsClientRootAdmin(client)) {
        PrintToChat(client, "\x01You don't have permission to use this command.");
        return Plugin_Handled;
    }
    
    if (args < 1) {
        PrintToChat(client, "\x01Usage: !setapikey <api_key>");
        return Plugin_Handled;
    }
    
    char apiKey[64];
    GetCmdArg(1, apiKey, sizeof(apiKey));
    
    // Validate API key format (basic check for AIzaSy prefix)
    if (strncmp(apiKey, "AIzaSy", 6) != 0 || strlen(apiKey) < 30) {
        PrintToChat(client, "\x01Error: Invalid API key format. Google API keys typically start with 'AIzaSy' and are at least 30 characters long.");
        return Plugin_Handled;
    }
    
    g_cvGeminiAPIKey.SetString(apiKey);
    PrintToChat(client, "\x01API key has been set successfully.");
    
    return Plugin_Handled;
}

public Action Command_AskAI(int client, int args) {
    // Check if player is valid
    if (client <= 0 || !IsClientInGame(client)) {
        return Plugin_Handled;
    }
    
    // Check cooldown
    float currentTime = GetGameTime();
    if (currentTime - g_flLastCommandTime[client] < g_cvCooldown.FloatValue) {
        float remainingCooldown = g_cvCooldown.FloatValue - (currentTime - g_flLastCommandTime[client]);
        PrintToChat(client, "\x01Please wait \x04%.1f\x01 seconds before asking another question.", remainingCooldown);
        return Plugin_Handled;
    }
    
    // Check if API key is set
    char apiKey[64];
    g_cvGeminiAPIKey.GetString(apiKey, sizeof(apiKey));
    if (strlen(apiKey) == 0) {
        PrintToChat(client, "\x01Gemini API key is not configured. Set it with !setapikey <your_api_key>");
        return Plugin_Handled;
    }
    
    // Get the message
    char message[MAX_MESSAGE_LENGTH];
    GetCmdArgString(message, sizeof(message));
    TrimString(message);
    
    if (strlen(message) == 0) {
        PrintToChat(client, "\x01Usage: !ai <message>");
        return Plugin_Handled;
    }
    
    // Update last command time and send request to Gemini
    g_flLastCommandTime[client] = currentTime;
    
    // Notify user
    PrintToChat(client, "\x01 Asking AI...");
    
    // Get player name
    char playerName[MAX_NAME_LENGTH];
    GetPlayerName(playerName, sizeof(playerName), client);
    
    // Build JSON in separate pieces using the correct API format for Gemini 2.0
    char requestData[MAX_MESSAGE_LENGTH * 2];
    
    // Get system prompt
    char systemPrompt[256];
    g_cvSystemPrompt.GetString(systemPrompt, sizeof(systemPrompt));
    
    // We need to escape any quotes or backslashes in the system prompt
    char escapedSystemPrompt[512];
    strcopy(escapedSystemPrompt, sizeof(escapedSystemPrompt), systemPrompt);
    ReplaceString(escapedSystemPrompt, sizeof(escapedSystemPrompt), "\\", "\\\\");
    ReplaceString(escapedSystemPrompt, sizeof(escapedSystemPrompt), "\"", "\\\"");
    
    // Simplified request format for Gemini 2.0 - as minimal as possible
    strcopy(requestData, sizeof(requestData), "{");
    StrCat(requestData, sizeof(requestData), "\"contents\": [{");
    StrCat(requestData, sizeof(requestData), "\"parts\": [{");
    StrCat(requestData, sizeof(requestData), "\"text\": \"");
    
    // Add a stronger instruction to force normal AI behavior
    StrCat(requestData, sizeof(requestData), "INSTRUCTIONS FOR AI: ");
    StrCat(requestData, sizeof(requestData), escapedSystemPrompt);
    StrCat(requestData, sizeof(requestData), "\\n\\n");
    StrCat(requestData, sizeof(requestData), "USER QUESTION: ");
    StrCat(requestData, sizeof(requestData), message);
    StrCat(requestData, sizeof(requestData), "\\n\\n");
    StrCat(requestData, sizeof(requestData), "IMPORTANT FORMATTING REQUIREMENTS: Do NOT use Markdown formatting like **bold** or __underline__. Use simple text formatting with standard punctuation. When using bullet points, leave a space after the asterisk. When creating lists, make sure there's a full space between items. Use clear section headers with a colon followed by a space, like 'Tips: ' or 'Note: '. Avoid cramming too much information into a single point.\\n\\n");
    StrCat(requestData, sizeof(requestData), "REMEMBER: Answer normally as a helpful AI assistant without any role-playing or zombie apocalypse references.");
    StrCat(requestData, sizeof(requestData), "\"");
    
    // Close JSON
    StrCat(requestData, sizeof(requestData), "}]");
    StrCat(requestData, sizeof(requestData), "}],");
    StrCat(requestData, sizeof(requestData), "\"generationConfig\": {");
    StrCat(requestData, sizeof(requestData), "\"temperature\": 0.7,");
    StrCat(requestData, sizeof(requestData), "\"maxOutputTokens\": ");
    
    // Add max tokens
    char maxTokensStr[16];
    IntToString(g_cvMaxTokens.IntValue, maxTokensStr, sizeof(maxTokensStr));
    StrCat(requestData, sizeof(requestData), maxTokensStr);
    
    // Close JSON
    StrCat(requestData, sizeof(requestData), "}");
    StrCat(requestData, sizeof(requestData), "}");
    
    // Create URL with API key
    char url[256];
    Format(url, sizeof(url), "https://%s%s?key=%s", GEMINI_API_HOST, GEMINI_API_ENDPOINT, apiKey);
    
    // Debug - Print URL and request data to console
    PrintToServer("URL: %s", url);
    PrintToServer("Request Data: %s", requestData);
    
    // Make HTTP request using SteamWorks
    Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, url);
    if (request == INVALID_HANDLE) {
        PrintToChat(client, "\x01Error creating HTTP request.");
        return Plugin_Handled;
    }
    
    SteamWorks_SetHTTPRequestRawPostBody(request, "application/json", requestData, strlen(requestData));
    SteamWorks_SetHTTPRequestHeaderValue(request, "Content-Type", "application/json");
    SteamWorks_SetHTTPCallbacks(request, OnGeminiHTTPComplete);
    SteamWorks_SetHTTPRequestContextValue(request, client);
    SteamWorks_SendHTTPRequest(request);
    
    return Plugin_Handled;
}

public void OnGeminiHTTPComplete(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, any data) {
    // Get client from request data
    int client = data;
    
    // Check if client is still valid
    if (client <= 0 || !IsClientInGame(client)) {
        delete request;
        return;
    }
    
    // Check for errors
    if (failure || !requestSuccessful) {
        PrintToChat(client, "\x01 Error connecting to AI.");
        delete request;
        return;
    }
    
    // Get response data regardless of status code
    int bodySize;
    SteamWorks_GetHTTPResponseBodySize(request, bodySize);
    
    char[] response = new char[bodySize + 1];
    SteamWorks_GetHTTPResponseBodyData(request, response, bodySize);
    response[bodySize] = '\0';
    
    // Debug - Print response info to server console
    PrintToServer("HTTP Status Code: %d", view_as<int>(statusCode));
    PrintToServer("Response size: %d bytes", bodySize);
    PrintToServer("Full response: %s", response);
    
    if (statusCode == k_EHTTPStatusCode200OK) {
        // Parse JSON response to extract the text
        char aiResponse[MAX_RESPONSE_LENGTH];
        if (!ParseGeminiResponse(response, aiResponse, sizeof(aiResponse))) {
            PrintToServer("Parsing failed - Could not extract text from response");
            PrintToChat(client, "\x01 Failed to parse response from AI.");
            
            // Try sending a very simple message if parsing fails
            char prefix[32];
            g_cvChatPrefix.GetString(prefix, sizeof(prefix));
            PrintToChat(client, "\x01%s \x05%s", prefix, "Sorry, I couldn't process that request properly.");
            
            delete request;
            return;
        }
        
        // Get chat prefix
        char prefix[32];
        g_cvChatPrefix.GetString(prefix, sizeof(prefix));
        
        // Split long responses into multiple chat messages - pass the client ID
        SendSplitChatResponse(prefix, aiResponse, client);
        
        // Clean up
        delete request;
    } else {
        // Log the error response to server console
        PrintToServer("Error response (HTTP %d): %s", statusCode, response);
        
        // Check for common API errors - Use int values instead of enum
        int statusCodeInt = view_as<int>(statusCode);
        if (statusCodeInt == HTTP_STATUS_BAD_REQUEST) {
            PrintToChat(client, "\x01 Error: Bad request. The API request format might be incorrect.");
        } else if (statusCodeInt == HTTP_STATUS_UNAUTHORIZED) {
            PrintToChat(client, "\x01 Error: API key is invalid or expired. Please set a new API key with !setapikey");
            // Reset stored API key since it's invalid
            g_cvGeminiAPIKey.SetString("");
        } else if (statusCodeInt == HTTP_STATUS_FORBIDDEN) {
            PrintToChat(client, "\x01 Error: API key doesn't have permission to access this resource.");
        } else if (statusCodeInt == HTTP_STATUS_NOT_FOUND) {
            PrintToChat(client, "\x01 Error: API endpoint not found. The plugin might need to be updated.");
        } else if (statusCodeInt == HTTP_STATUS_TOO_MANY_REQUESTS) {
            PrintToChat(client, "\x01 Error: Rate limit exceeded. Please try again later.");
        } else {
            PrintToChat(client, "\x01 Error from AI (HTTP %d)", statusCodeInt);
        }
        
        delete request;
    }
}

bool ParseGeminiResponse(const char[] jsonResponse, char[] output, int maxlen) {
    // Try Gemini 2.0 response format with simple approach
    PrintToServer("Attempting to parse response");
    
    // Specifically look for the exact pattern in the Gemini 2.0 response format
    char exactPattern[] = "\"text\": \"";
    int textPos = StrContains(jsonResponse, exactPattern);
    
    if (textPos != -1) {
        // Found the text pattern
        textPos += strlen(exactPattern);
        PrintToServer("Found exact text pattern at position %d", textPos);
    } else {
        // Try alternative patterns with various whitespace combinations
        char alternativePatterns[][] = {
            "\"text\":\"",
            "text\": \"", 
            "text\":\"",
            "\"parts\":[{\"text\":\"",
            "\"parts\": [{\"text\": \""
        };
        
        for (int i = 0; i < sizeof(alternativePatterns); i++) {
            textPos = StrContains(jsonResponse, alternativePatterns[i]);
            if (textPos != -1) {
                textPos += strlen(alternativePatterns[i]);
                PrintToServer("Found alternative pattern '%s' at position %d", alternativePatterns[i], textPos);
                break;
            }
        }
    }
    
    // If we still can't find it, try a more general approach by going through the response section by section
    if (textPos == -1) {
        PrintToServer("Standard patterns not found, trying section-by-section search");
        
        // Find candidates array
        int candidatesPos = StrContains(jsonResponse, "\"candidates\"");
        if (candidatesPos != -1) {
            PrintToServer("Found candidates at position %d", candidatesPos);
            
            // Find content object within candidates
            int contentPos = StrContains(jsonResponse[candidatesPos], "\"content\"");
            if (contentPos != -1) {
                contentPos += candidatesPos;  // Adjust position relative to full string
                PrintToServer("Found content at position %d", contentPos);
                
                // Find parts array within content
                int partsPos = StrContains(jsonResponse[contentPos], "\"parts\"");
                if (partsPos != -1) {
                    partsPos += contentPos;  // Adjust position relative to full string
                    PrintToServer("Found parts at position %d", partsPos);
                    
                    // Find text within parts
                    int textKeyPos = StrContains(jsonResponse[partsPos], "\"text\"");
                    if (textKeyPos != -1) {
                        textKeyPos += partsPos;  // Adjust position relative to full string
                        PrintToServer("Found text key at position %d", textKeyPos);
                        
                        // Look for the colon and opening quote
                        for (int i = textKeyPos + 6; i < strlen(jsonResponse) - 1; i++) {
                            if (jsonResponse[i] == ':') {
                                // Find the next quote after the colon
                                for (int j = i + 1; j < strlen(jsonResponse); j++) {
                                    if (jsonResponse[j] == '"') {
                                        textPos = j + 1;  // Position after the quote
                                        PrintToServer("Found text position at %d", textPos);
                                        break;
                                    }
                                }
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    // If still no success, give up
    if (textPos == -1) {
        PrintToServer("Could not find text content in the response after all attempts");
        return false;
    }
    
    // Now extract the text until the closing quote
    bool foundEscape = false;
    char textBuffer[MAX_RESPONSE_LENGTH * 2]; // Use a larger buffer for initial extraction
    int textBufferPos = 0;
    
    // First, extract the complete text into a larger buffer
    for (int i = textPos; i < strlen(jsonResponse); i++) {
        if (foundEscape) {
            if (jsonResponse[i] == 'n') {
                textBuffer[textBufferPos++] = ' '; // Replace newlines with spaces
            } else if (jsonResponse[i] == '\\' || jsonResponse[i] == '"') {
                textBuffer[textBufferPos++] = jsonResponse[i];
            } else {
                textBuffer[textBufferPos++] = jsonResponse[i];
            }
            foundEscape = false;
            continue;
        }
        
        if (jsonResponse[i] == '\\') {
            foundEscape = true;
            continue;
        }
        
        if (jsonResponse[i] == '"' && !foundEscape) {
            break; // End of quoted text
        }
        
        textBuffer[textBufferPos++] = jsonResponse[i];
    }
    
    textBuffer[textBufferPos] = '\0';
    PrintToServer("Full extracted text: %s", textBuffer);
    
    // Now copy to the output, ensuring we don't exceed maxlen
    int copyLen = textBufferPos < maxlen - 1 ? textBufferPos : maxlen - 1;
    for (int i = 0; i < copyLen; i++) {
        output[i] = textBuffer[i];
    }
    output[copyLen] = '\0';
    
    // Verify we got something useful
    if (strlen(output) == 0) {
        PrintToServer("No content could be extracted from the response");
        return false;
    }
    
    PrintToServer("Successfully extracted text: %s", output);
    return true;
}

// Check if client is the listen server host
bool IsClientRootAdmin(int client) {
    // Check if client is valid
    if (!IsClientInGame(client)) {
        return false;
    }
    
    // Check if client is the server host
    return (GetUserFlagBits(client) & ADMFLAG_ROOT) != 0 || 
           (IsClientInGame(client) && IsFakeClient(GetClientOfUserId(0)) && GetUserAdmin(client) != INVALID_ADMIN_ID);
}

void GetPlayerName(char[] buffer, int maxlen, int client) {
    GetClientName(client, buffer, maxlen);
    
    // Escape quotes in name to prevent JSON syntax errors
    ReplaceString(buffer, maxlen, "\"", "\\\"");
    
    // Also escape backslashes
    ReplaceString(buffer, maxlen, "\\", "\\\\");
}

// Function to reset cooldowns for all players
void ResetAllCooldowns() {
    for (int i = 1; i <= MaxClients; i++) {
        g_flLastCommandTime[i] = 0.0; // Reset to 0 to allow immediate use after map change
    }
    PrintToServer("[Left 4 Chat 2] All player cooldowns have been reset.");
}

// Update the SendSplitChatResponse function to better handle text splitting
void SendSplitChatResponse(const char[] prefix, const char[] response, int client = 0) {
    int responseLength = strlen(response);
    PrintToServer("Splitting response of length %d into multiple chat messages", responseLength);
    
    // Always output the full response to server console
    PrintToServer("Full response from AI: %s", response);
    
    // Check if low impact mode is enabled - if yes, limit response length
    bool lowImpactMode = g_cvLowImpactMode.BoolValue;
    int maxResponseSize = lowImpactMode ? 512 : MAX_RESPONSE_LENGTH;
    
    // If in low impact mode and the response is too long, truncate it
    char truncatedResponse[MAX_RESPONSE_LENGTH];
    if (lowImpactMode && responseLength > maxResponseSize) {
        strcopy(truncatedResponse, maxResponseSize - 3, response);
        StrCat(truncatedResponse, sizeof(truncatedResponse), "...");
        
        // Use the truncated response instead
        responseLength = strlen(truncatedResponse);
        
        // Log that we're truncating for performance
        PrintToServer("Low impact mode: Truncating response to %d characters to reduce network overhead", maxResponseSize);
        
        if (client > 0 && IsClientInGame(client)) {
            PrintToChat(client, "\x01%s \x03Note: \x05Response was truncated for performance. Enable full responses with !ai_lowimpact 0", prefix);
        }
    } else {
        // Use the full response
        strcopy(truncatedResponse, sizeof(truncatedResponse), response);
    }
    
    // If the response is short enough, send it as a single message
    if (responseLength <= MAX_CHAT_LENGTH) {
        if (client > 0 && IsClientInGame(client)) {
            PrintToChat(client, "\x01%s \x05%s", prefix, truncatedResponse);
        } else {
            PrintToChatAll("\x01%s \x05%s", prefix, truncatedResponse);
        }
        return;
    }
    
    // Pre-process the response to properly format bullet points
    // This step adds special markers to make bullet point detection easier during splitting
    char processedResponse[MAX_RESPONSE_LENGTH];
    strcopy(processedResponse, sizeof(processedResponse), truncatedResponse);
    
    // Mark bullet points with a special sequence so we can detect them for proper splitting
    ReplaceString(processedResponse, sizeof(processedResponse), "* ", "###BULLET###");
    ReplaceString(processedResponse, sizeof(processedResponse), "- ", "###BULLET###");
    ReplaceString(processedResponse, sizeof(processedResponse), "• ", "###BULLET###");
    
    // For longer responses, split into multiple messages
    char buffer[MAX_CHAT_LENGTH + 1];
    int startPos = 0;
    
    // Create DataPack to store message parts for sequential sending
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteString(prefix);
    
    // Count total parts and store them
    int partCount = 0;
    ArrayList messageParts = new ArrayList(ByteCountToCells(MAX_CHAT_LENGTH + 1));
    
    // In low impact mode, limit the number of message parts to reduce network traffic
    int maxParts = lowImpactMode ? 5 : 20;
    
    while (startPos < responseLength && partCount < maxParts) {
        int endPos = startPos;
        int charsToTake = MAX_CHAT_LENGTH - 10; // Leave some room for prefix
        
        // If we're right at a bullet point or very close to one, start there
        int nextBulletPos = StrContains(processedResponse[startPos], "###BULLET###");
        if (nextBulletPos >= 0 && nextBulletPos < 5) { // If bullet point is at the start or very near
            // Start exactly at the bullet point
            startPos += nextBulletPos;
        }
        
        // Look ahead for the next bullet point to avoid splitting right before it
        nextBulletPos = StrContains(processedResponse[startPos], "###BULLET###");
        
        // Don't split in the middle of a word if possible
        if (startPos + charsToTake < responseLength) {
            int splitPos = startPos + charsToTake;
            
            // If there's a bullet point before our max length, try to break there
            if (nextBulletPos > 0 && nextBulletPos < charsToTake) {
                // Break right before the next bullet point for clean separation
                endPos = startPos + nextBulletPos;
            } else {
                // Try to find a space to break at
                int spacePos = splitPos;
                
                // Look backwards for a space
                while (spacePos > startPos && processedResponse[spacePos] != ' ') {
                    spacePos--;
                }
                
                // If we found a space, break there
                if (processedResponse[spacePos] == ' ') {
                    endPos = spacePos;
                } else {
                    // No space found, just break at the maximum length
                    endPos = splitPos;
                }
            }
        } else {
            // We're near the end, just take the rest
            endPos = responseLength;
        }
        
        // Copy this part of the message
        int copyLength = endPos - startPos;
        strcopy(buffer, copyLength + 1, processedResponse[startPos]);
        buffer[copyLength] = '\0';
        
        // Restore bullet point markers back to normal format
        ReplaceString(buffer, sizeof(buffer), "###BULLET###", "* ");
        
        // Store this part
        messageParts.PushString(buffer);
        partCount++;
        
        // Move to the next part
        startPos = endPos;
        if (startPos < responseLength && processedResponse[startPos] == ' ') {
            startPos++; // Skip the space
        }
    }
    
    // If we reached the max parts limit and there's more text, add an ellipsis
    if (startPos < responseLength && partCount >= maxParts) {
        PrintToServer("Low impact mode: Response was too long, limited to %d message parts", maxParts);
        char ellipsis[MAX_CHAT_LENGTH];
        Format(ellipsis, sizeof(ellipsis), "... (response truncated, %d%% shown)", RoundFloat((float(startPos) / float(responseLength)) * 100.0));
        messageParts.PushString(ellipsis);
        partCount++;
    }
    
    // Store total parts and the message parts array
    pack.WriteCell(partCount);
    pack.WriteCell(messageParts);
    pack.WriteCell(0); // Current part index
    
    // Start sending messages with timer
    CreateTimer(0.1, Timer_SendNextMessagePart, pack);
}

public Action Timer_SendNextMessagePart(Handle timer, any data) {
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    
    int client = pack.ReadCell();
    char prefix[32];
    pack.ReadString(prefix, sizeof(prefix));
    int totalParts = pack.ReadCell();
    ArrayList messageParts = view_as<ArrayList>(pack.ReadCell());
    int currentPart = pack.ReadCell();
    
    // Check if we're done
    if (currentPart >= totalParts) {
        delete messageParts;
        delete pack;
        return Plugin_Stop;
    }
    
    // Get current message part
    char buffer[MAX_CHAT_LENGTH + 1];
    messageParts.GetString(currentPart, buffer, sizeof(buffer));
    
    // Improve formatting for better readability
    char formattedBuffer[MAX_CHAT_LENGTH + 1];
    FormatChatMessage(buffer, formattedBuffer, sizeof(formattedBuffer), currentPart);
    
    // Send message to client or everyone
    if (client > 0 && IsClientInGame(client)) {
        if (currentPart == 0) {
            PrintToChat(client, "\x01%s \x05%s", prefix, formattedBuffer);
        } else {
            PrintToChat(client, "\x01\x05%s", formattedBuffer);
        }
    } else {
        if (currentPart == 0) {
            PrintToChatAll("\x01%s \x05%s", prefix, formattedBuffer);
        } else {
            PrintToChatAll("\x01\x05%s", formattedBuffer);
        }
    }
    
    // Update current part
    currentPart++;
    
    // Repack and schedule next message
    pack.Reset();
    pack.WriteCell(client);
    pack.WriteString(prefix);
    pack.WriteCell(totalParts);
    pack.WriteCell(messageParts);
    pack.WriteCell(currentPart);
    
    // Schedule next message with delay from ConVar
    float messageDelay = g_cvMessageDelay.FloatValue;
    CreateTimer(messageDelay, Timer_SendNextMessagePart, pack);
    
    return Plugin_Continue;
}

// Update the formatting function to ensure text flows properly to the right
void FormatChatMessage(const char[] input, char[] output, int maxlen, int partIndex) {
    // Start with a clean copy
    strcopy(output, maxlen, input);
    
    // Step 1: Pre-process the text to fix common spacing issues
    // First, strip all markdown and formatting that might cause issues
    ReplaceString(output, maxlen, "**", ""); // Remove bold markers
    ReplaceString(output, maxlen, "__", ""); // Remove underline markers
    ReplaceString(output, maxlen, "*•", "•"); // Fix malformed bullet points
    ReplaceString(output, maxlen, "*:", ": "); // Fix malformed colons after headers
    
    // Step 2: Format bullet points with proper alignment - always at the beginning
    bool hasBulletPoint = false;
    
    // Check if there are bullet points at the start of this message part
    if (StrContains(output, "* ") == 0 || StrContains(output, "- ") == 0 || StrContains(output, "• ") == 0) {
        hasBulletPoint = true;
    }
    
    // Format bullet points while ensuring they stay at the left edge
    ReplaceString(output, maxlen, "* ", "\x03• \x05");
    ReplaceString(output, maxlen, "- ", "\x03• \x05");
    ReplaceString(output, maxlen, "• ", "\x03• \x05");
    
    // Fix runaway words by inserting spaces between lowercase-uppercase transitions
    char processedText[MAX_CHAT_LENGTH * 2];
    int inputLen = strlen(output);
    int processedPos = 0;
    
    for (int i = 0; i < inputLen - 1; i++) {
        // Add the current character
        processedText[processedPos++] = output[i];
        
        // Check for lowercase followed by uppercase (potential missing space)
        if (i < inputLen - 1 && IsCharLower(output[i]) && IsCharUpper(output[i+1])) {
            // Insert a space
            processedText[processedPos++] = ' ';
        }
        
        // Add space after period if followed by a letter
        if (i < inputLen - 1 && output[i] == '.' && IsCharAlpha(output[i+1])) {
            processedText[processedPos++] = ' ';
        }
    }
    
    // Add the last character if there is one
    if (inputLen > 0) {
        processedText[processedPos++] = output[inputLen - 1];
    }
    
    processedText[processedPos] = '\0';
    strcopy(output, maxlen, processedText);
    
    // Step 3: Fix section headers and make them stand out
    // Special case for common section headers
    ReplaceString(output, maxlen, "Tips:", "\x04Tips:\x05 ");
    ReplaceString(output, maxlen, "Note:", "\x04Note:\x05 ");
    ReplaceString(output, maxlen, "Remember:", "\x04Remember:\x05 ");
    ReplaceString(output, maxlen, "Important:", "\x04Important:\x05 ");
    
    // Find all instances of text followed by colon
    char sectionPattern[64] = "([A-Za-z ]+):(\\s*)";
    Regex sectionRegex = new Regex(sectionPattern);
    
    char sectionBuffer[MAX_CHAT_LENGTH * 2];
    strcopy(sectionBuffer, sizeof(sectionBuffer), output);
    int offset = 0;
    
    while (sectionRegex.Match(sectionBuffer[offset]) > 0) {
        char fullMatch[64];
        char sectionName[64];
        sectionRegex.GetSubString(0, fullMatch, sizeof(fullMatch));
        sectionRegex.GetSubString(1, sectionName, sizeof(sectionName));
        
        // Create a highlighted version
        char replacement[128];
        Format(replacement, sizeof(replacement), "\x04%s:\x05 ", sectionName);
        
        // Find and replace in the main string
        int matchPos = StrContains(sectionBuffer[offset], fullMatch);
        if (matchPos != -1) {
            char before[MAX_CHAT_LENGTH];
            char after[MAX_CHAT_LENGTH];
            
            int absPos = offset + matchPos;
            strcopy(before, absPos + 1, sectionBuffer);
            strcopy(after, sizeof(after), sectionBuffer[absPos + strlen(fullMatch)]);
            
            Format(sectionBuffer, sizeof(sectionBuffer), "%s%s%s", before, replacement, after);
            
            // Update offset
            offset = absPos + strlen(replacement);
        } else {
            break;
        }
    }
    delete sectionRegex;
    strcopy(output, maxlen, sectionBuffer);
    
    // Step 4: Format numbered lists 
    // Highlight numbers at the start of sentences for numbered lists
    char numberPattern[64] = "([0-9]+\\.\\s)";
    Regex numberRegex = new Regex(numberPattern);
    
    char numberBuffer[MAX_CHAT_LENGTH * 2];
    strcopy(numberBuffer, sizeof(numberBuffer), output);
    offset = 0;
    
    while (numberRegex.Match(numberBuffer[offset]) > 0) {
        char numMatch[16];
        numberRegex.GetSubString(0, numMatch, sizeof(numMatch));
        
        // Create a highlighted version
        char replacement[32];
        Format(replacement, sizeof(replacement), "\x04%s\x05", numMatch);
        
        // Find and replace
        int matchPos = StrContains(numberBuffer[offset], numMatch);
        if (matchPos != -1) {
            char before[MAX_CHAT_LENGTH];
            char after[MAX_CHAT_LENGTH];
            
            int absPos = offset + matchPos;
            strcopy(before, absPos + 1, numberBuffer);
            strcopy(after, sizeof(after), numberBuffer[absPos + strlen(numMatch)]);
            
            Format(numberBuffer, sizeof(numberBuffer), "%s%s%s", before, replacement, after);
            
            // Update offset
            offset = absPos + strlen(replacement);
        } else {
            break;
        }
    }
    delete numberRegex;
    strcopy(output, maxlen, numberBuffer);
    
    // Step 5: For continuation parts that aren't bullet points, add slight indentation
    // Only indent if this isn't a bullet-point part and isn't the first part
    if (partIndex > 0 && !hasBulletPoint) {
        // Add slight indentation for regular continuation text
        char paddedOutput[MAX_CHAT_LENGTH];
        Format(paddedOutput, sizeof(paddedOutput), "  %s", output);
        strcopy(output, maxlen, paddedOutput);
    }
    
    // Step 6: Final cleanup
    // Fix doubled bullets
    ReplaceString(output, maxlen, "\x03•\x05\x03•", "\x03•"); 
    
    // Fix spaces before punctuation
    ReplaceString(output, maxlen, " ,", ",");
    ReplaceString(output, maxlen, " .", ".");
    
    // Ensure bullet points have consistent coloring
    ReplaceString(output, maxlen, "• ", "\x03• \x05");
    
    // Remove double spaces - keep this last so we don't create more double spaces
    while (StrContains(output, "  ") != -1) {
        ReplaceString(output, maxlen, "  ", " ");
    }
}

// Add a command to toggle low impact mode during gameplay
public Action Command_ToggleLowImpact(int client, int args) {
    // Check if player is valid
    if (client <= 0 || !IsClientInGame(client)) {
        return Plugin_Handled;
    }
    
    // Toggle low impact mode if no arguments
    if (args < 1) {
        bool currentValue = g_cvLowImpactMode.BoolValue;
        g_cvLowImpactMode.SetBool(!currentValue);
        
        PrintToChat(client, "\x01Left 4 Chat 2: Low impact mode %s", !currentValue ? "enabled" : "disabled");
        return Plugin_Handled;
    }
    
    // Get argument
    char arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    int value = StringToInt(arg);
    
    // Set low impact mode
    g_cvLowImpactMode.SetInt(value ? 1 : 0);
    
    PrintToChat(client, "\x01Left 4 Chat 2: Low impact mode %s", value ? "enabled" : "disabled");
    return Plugin_Handled;
}

// Add function to register the low impact toggle command
void RegisterPluginCommands() {
    RegConsoleCmd("sm_ai_lowimpact", Command_ToggleLowImpact, "Toggle low-impact mode for AI responses to reduce ping");
}