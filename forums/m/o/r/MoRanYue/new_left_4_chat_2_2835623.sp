#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <regex>
#include <ripext>
#include <left4dhooks>
#include <nl4c2>

#define PLUGIN_VERSION "1.2.1"

#define MAX_PROMPT_LENGTH 8192
#define MAX_RESPONSE_LENGTH 8192 // Equals to maximum tokens
#define MAX_CHAT_CONTENT_LENGTH 80
#define SYSTEM_PROMPT_FILE_NAME "l4c2_system_prompt.txt"
#define MESSAGE_PROMPT_FILE_NAME "l4c2_message_prompt.txt"
#define DEFAULT_SYSTEM_PROMPT "You are a general-purpose AI assistant answering questions in a Left 4 Dead 2 (L4D2) game chat.\nHere are some things you have to obey:\n1. Just answer questions directly and helpfully like a normal assistant would.\n2. Always answer in user's language.\n3. Do not use Markdown and Emoji, L4D2 chatbox does not support that. Special symbols are free to use.\n4. You can use text \"{default}\"\"{green}\"\"{olive}\"\"{lightgreen}\"\"{red}\"\"{blue}\" to set its following characters' colors, but remember that 2 of ({blue}, {red}, {lightgreen}) can not be used together, if you have already used \"{lightgreen}\", DO NOT use \"{red}\" and \"{blue}\"; if you have already used \"{red}\", both of \"{lightgreen}\" and \"{blue}\" CAN NOT be used. For example: \"{default}AAA{green}BBB{default}CCC\", AAA and CCC are white but BBB is green.\n5. Do not always stress that you are an assistant.\n6. \"Flow distance\" indicates survivors' progress on current map.\n7. Players' message follows format \"{Player name} (S: {Steam account ID})(C: {Character})(F: {Flow}/{Max flow} {Flow percent}): {Message}\", curly braces will not be included. So that you could better recognize different players.\nRealtime information:\nServer name: {server_name}\nGamemode: {gamemode}\nMap: {map_name}\nPlayers: {player_number}/{max_player_number}\nFlow distance: {flow}/{max_flow} {flow_percent}%"
#define DEFAULT_MESSAGE_PROMPT "{player_name} (S: {player_steam_id})(C: {player_character})(F: {flow}/{max_flow} {flow_percent}%): {content}"
#define DEBUG true

// ConVars
ConVar api_host;
ConVar api_endpoint;
ConVar api_type;
ConVar model;
ConVar api_key;
ConVar max_tokens;
ConVar cooldown;

ConVar hostname;

// Info message printing has been removed,
// You can should use plugin Advertisement to notice your players.

char system_prompt[MAX_PROMPT_LENGTH];
char message_prompt[MAX_PROMPT_LENGTH];
float last_request_time;
JSONArray history;

public Plugin myinfo = {
    name = "New Left 4 Chat 2",
    author = "Mezo123451A, MoRanYue",
    description = "Chat with AI in Left 4 Dead 2.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=350718"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int error_len) {
    EngineVersion engine_version = GetEngineVersion();
    if (engine_version != Engine_Left4Dead2) {
        strcopy(error, error_len, "This plugin only supports Left 4 Dead 2");
        return APLRes_SilentFailure;
    }

    MarkNativeAsOptional("InfoEditor_GetString");

    CreateNative("Nl4c2RequestAi", NativeRequestAi);
    CreateNative("Nl4c2RequestAiEx", NativeRequestAiEx);
    CreateNative("Nl4c2BuildCommonMessage", NativeBuildCommonMessage);
    CreateNative("Nl4c2BuildToolMessage", NativeBuildToolMessage);
    CreateNative("Nl4c2FormatSystemPrompt", NativeFormatSystemPrompt);
    CreateNative("Nl4c2FormatMessagePrompt", NativeFormatMessagePrompt);
    RegPluginLibrary("nl4c2");

    return APLRes_Success;
}

public void OnPluginStart() {
    api_host = CreateConVar("l4c2_api_host", "api.deepseek.com", "LLM API host (OpenAI or OpenAI-compatible API), without http:// or https://");
    api_endpoint = CreateConVar("l4c2_api_endpoint", "/chat/completions", "LLM API endpoint");
    api_type = CreateConVar("l4c2_api_type", "0", "LLM API type. It depends on your provider, most are OpenAI. 0 = OpenAI, 1 = Google Gemini", _, true, 0.0, true, 1.0);
    model = CreateConVar("l4c2_model", "deepseek-chat", "LLM model");
    api_key = CreateConVar("l4c2_api_key", NULL_STRING, "LLM API key", FCVAR_PROTECTED);
    max_tokens = CreateConVar("l4c2_max_tokens", "256", "Maximum tokens for AI response", _, true, 1.0, true, float(MAX_RESPONSE_LENGTH));
    cooldown = CreateConVar("l4c2_cooldown", "5.0", "Cooldown between AI requests (in seconds)", _, true, 0.0);
    CreateConVar("l4c2_version", PLUGIN_VERSION, "New Left 4 Chat 2 version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "l4c2");
    LoadTranslations("l4c2.phrases.txt");

    hostname = FindConVar("hostname");

    api_type.AddChangeHook(OnApiTypeChange);

    RegConsoleCmd("sm_ai", PlayerRequestAi, "Request AI for a response");
    RegConsoleCmd("sm_llm", PlayerRequestAi, "Request AI for a response");
    RegConsoleCmd("sm_clean_history", CleanHistory, "Start a new conversation");

    RegAdminCmd("sm_reload_system_prompt", ReloadSystemPrompt, ADMFLAG_SLAY, "Reload system prompt from the file");

    history = new JSONArray();
    history.PushNull();
    LoadSystemPrompt();

    last_request_time = GetGameTime();
}

public void OnMapStart() {
    last_request_time = GetGameTime();
}

public void OnMapEnd() {
    last_request_time = 0.0;
}

public void OnApiTypeChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (!StrEqual(oldValue, newValue)) {
        history.Clear();
        JSONObject system_prompt_obj = BuildCommonMessage(RoleSystem, system_prompt, "Left 4 Dead 2");
        history.Push(system_prompt_obj);
        delete system_prompt_obj;
    }
}

AiApi GetApiType() {
    return view_as<AiApi>(api_type.IntValue);
}

int GetPlayerNumber() {
    int player_number = 0;
    for (int i = 1; i < MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            player_number++;
        }
    }
    return player_number;
}

public Action CleanHistory(int client, int args) {
    if (client != 0 && IsFakeClient(client)) {
        return Plugin_Handled;
    }

    history.Clear();
    JSONObject system_prompt_obj = BuildCommonMessage(RoleSystem, system_prompt, "Left 4 Dead 2");
    history.Push(system_prompt_obj);
    delete system_prompt_obj;

    CPrintToChatAll("%t", "History cleaned");

    return Plugin_Handled;
}

public Action ReloadSystemPrompt(int client, int args) {
    if (client != 0 && IsFakeClient(client)) {
        return Plugin_Handled;
    }

    if (CheckCommandAccess(client, "sm_reload_system_prompt", ADMFLAG_ROOT)) {
        char info[64];
        switch (LoadSystemPrompt()) {
            case 0: {
                info = "Prompts reloaded successfully";
            }
            case 1: {
                info = "System prompt reloading failed";
            }
            case 2: {
                info = "Message prompt reloading failed";
            }
            default: {
                info = "Prompts reloading failed";
            }
        }
        CShowActivity2(client, NULL_STRING, "%t", info);
        return Plugin_Handled;
    }
    CShowActivity2(client, NULL_STRING, "%t", "Permission denied");
    return Plugin_Handled;
}

int LoadSystemPrompt() {
    char system_prompt_path[128];
    char message_prompt_path[128];
    BuildPath(Path_SM, system_prompt_path, sizeof(system_prompt_path), "configs/%s", SYSTEM_PROMPT_FILE_NAME);
    BuildPath(Path_SM, message_prompt_path, sizeof(message_prompt_path), "configs/%s", MESSAGE_PROMPT_FILE_NAME);
    if (!ReadStringInFileIfExistsOrWriteString(system_prompt_path, DEFAULT_SYSTEM_PROMPT, system_prompt, sizeof(system_prompt))) {
        return 1;
    }
    if (!ReadStringInFileIfExistsOrWriteString(message_prompt_path, DEFAULT_MESSAGE_PROMPT, message_prompt, sizeof(message_prompt))) {
        return 2;
    }

    JSONObject system_prompt_obj = BuildCommonMessage(RoleSystem, system_prompt, "Left 4 Dead 2");
    history.Set(0, system_prompt_obj);
    delete system_prompt_obj;

    if (DEBUG) {
        PrintToServer("system_prompt =\n%s", system_prompt);
        PrintToServer("message_prompt =\n%s", message_prompt);
    }

    return 0;
}

int ReadStringInFileIfExistsOrWriteString(const char[] path, const char[] default_content, char[] buf, int max_len) {
    bool file_exists = FileExists(path, false, NULL_STRING);
    File file = OpenFile(path, "a+", false, NULL_STRING);
    if (!file) {
        return 0;
    }

    int ret;
    if (file_exists) {
        ret = file.ReadString(buf, max_len, -1);
    }
    else {
        ret = file.WriteString(default_content, true);
        strcopy(buf, max_len, default_content);
    }
    file.Close();
    return ret;
}

public Action PlayerRequestAi(int client, int args) {
    if (client != 0 && IsFakeClient(client)) {
        return Plugin_Handled;
    }
    
    // Check cooldown
    float current_time = GetGameTime();
    if (current_time - last_request_time < cooldown.FloatValue) {
        float remaining_cooldown = cooldown.FloatValue - (current_time - last_request_time);
        CPrintToChat(client, "%t", "Cooldown", remaining_cooldown);
        return Plugin_Handled;
    }
    last_request_time = current_time;

    char key[64];
    api_key.GetString(key, sizeof(key));
    if (strlen(key) == 0) {
        CPrintToChat(client, "%t", "API key is not set");
        return Plugin_Handled;
    }
    
    // Get the prompt
    char content[MAX_PROMPT_LENGTH];
    GetCmdArgString(content, sizeof(content));
    TrimString(content);
    if (strlen(content) == 0) {
        CPrintToChat(client, "%t", "RequestAi command usage");
        return Plugin_Handled;
    }

    CPrintToChat(client, "%t", "Requesting");

    char formatted_system_prompt[MAX_PROMPT_LENGTH];
    strcopy(formatted_system_prompt, sizeof(formatted_system_prompt), system_prompt);
    FormatSystemPrompt(formatted_system_prompt, sizeof(formatted_system_prompt));

    JSONObject system_prompt_obj = BuildCommonMessage(RoleSystem, formatted_system_prompt, "Left 4 Dead 2");
    history.Set(0, system_prompt_obj);
    delete system_prompt_obj;

    char player_name[MAX_NAME_LENGTH];
    GetClientName(client, player_name, sizeof(player_name));

    char model_name[32];
    model.GetString(model_name, sizeof(model_name));

    char prompt[MAX_PROMPT_LENGTH];
    strcopy(prompt, sizeof(prompt), message_prompt);
    FormatMessagePrompt(prompt, sizeof(prompt), client, content);

    JSONObject prompt_obj = BuildCommonMessage(RoleUser, prompt, player_name);
    history.Push(prompt_obj);
    delete prompt_obj;

    RequestAi(key, model_name, history, OnPlayerAiRequestComplete);
    
    return Plugin_Handled;
}
public void OnPlayerAiRequestComplete(const char[] response, const char[] model_name, AiStatus status) {
    switch (status) {
        case AiStatusSuccess: {
            JSONObject response_obj = BuildCommonMessage(RoleAssistant, response, model_name);
            history.Push(response_obj);
            delete response_obj;

            SendSplitResponse(response);
        }
        case AiStatusRequestFailed: {
            CPrintToChatAll("%t", "Failed to create a request");
        }
        case AiStatusResponseIsTooLong: {
            CPrintToChatAll("%t", "Response is too long");
        }
        case AiStatusResponseTriggeredContentFilter: {
            CPrintToChatAll("%t", "Response triggered content filter");
        }
        case AiStatusServiceProviderWentWrong: {
            CPrintToChatAll("%t", "Response does not generate");
        }
        case AiStatusUnknown: {
            CPrintToChatAll("%t", "Response met unknown error");
        }
        case AiStatusInvalidKey: {
            CPrintToChatAll("%t", "API key is not set");
        }
        case AiStatusEmptyMessageArray: {}
        default: {
            CPrintToChatAll("%t", "Response met unknown error");
        }
    }
}

public any NativeRequestAi(Handle plugin, int numParams) {
    char custom_system_prompt[MAX_PROMPT_LENGTH];
    char user_prompt[MAX_PROMPT_LENGTH];
    GetNativeString(1, custom_system_prompt, sizeof(custom_system_prompt));
    GetNativeString(2, user_prompt, sizeof(user_prompt));
    Function callback = GetNativeFunction(3);

    char key[64];
    api_key.GetString(key, sizeof(key));
    if (strlen(key) == 0) {
        Call_StartFunction(INVALID_HANDLE, callback);
        Call_PushString(NULL_STRING);
        Call_PushString(NULL_STRING);
        Call_PushCell(AiStatusInvalidKey);
        Call_Finish();
    }

    char model_name[32];
    model.GetString(model_name, sizeof(model_name));

    JSONObject custom_system_prompt_obj = BuildCommonMessage(RoleSystem, custom_system_prompt);
    JSONObject user_prompt_obj = BuildCommonMessage(RoleUser, user_prompt);

    JSONArray messages = new JSONArray();
    messages.Push(custom_system_prompt_obj);
    messages.Push(user_prompt_obj);

    RequestAi(key, model_name, messages, callback);

    delete custom_system_prompt_obj;
    delete user_prompt_obj;
    delete messages;
}
public any NativeRequestAiEx(Handle plugin, int numParams) {
    JSONArray messages = view_as<JSONArray>(GetNativeCell(1));
    // I don't know...
    // Why I can not use view_as<AiResponseCallback>()?
    Function callback = GetNativeFunction(2);
    
    char key[64];
    api_key.GetString(key, sizeof(key));
    if (strlen(key) == 0) {
        Call_StartFunction(INVALID_HANDLE, callback);
        Call_PushString(NULL_STRING);
        Call_PushString(NULL_STRING);
        Call_PushCell(AiStatusInvalidKey);
        Call_Finish();
    }

    char model_name[32];
    model.GetString(model_name, sizeof(model_name));

    RequestAi(key, model_name, messages, callback);
}
public any NativeBuildCommonMessage(Handle plugin, int numParams) {
    Role role = view_as<Role>(GetNativeCell(1));
    char content[MAX_PROMPT_LENGTH];
    GetNativeString(2, content, sizeof(content));
    char name[MAX_NAME_LENGTH];
    GetNativeString(3, name, sizeof(name));

    return BuildCommonMessage(role, content, name);
}
public any NativeBuildToolMessage(Handle plugin, int numParams) {
    char content[MAX_PROMPT_LENGTH];
    GetNativeString(1, content, sizeof(content));
    char tool_call_id[MAX_NAME_LENGTH];
    GetNativeString(2, tool_call_id, sizeof(tool_call_id));

    return BuildToolMessage(content, tool_call_id);
}
public any NativeFormatSystemPrompt(Handle plugin, int numParams) {
    char buf[MAX_PROMPT_LENGTH];
    GetNativeString(1, buf, sizeof(buf));
    int max_len = GetNativeCell(2);

    return FormatSystemPrompt(buf, max_len);
}
public any NativeFormatMessagePrompt(Handle plugin, int numParams) {
    char buf[MAX_PROMPT_LENGTH];
    GetNativeString(1, buf, sizeof(buf));
    int max_len = GetNativeCell(2);
    int client = GetNativeCell(3);
    char content[MAX_PROMPT_LENGTH];
    GetNativeString(4, content, sizeof(content));

    return FormatMessagePrompt(buf, max_len, client, content);
}

JSONObject BuildCommonMessage(Role role, const char[] content, const char[] name = NULL_STRING) {
    JSONObject message = new JSONObject();
    switch (GetApiType()) {
        case AiApiOpenAi: {
            char role_str[16];
            switch (role) {
                case RoleUser: {
                    role_str = "user";
                }
                case RoleAssistant: {
                    role_str = "assistant";
                }
                case RoleSystem: {
                    role_str = "system";
                }
                default: {
                    role_str = "user";
                }
            }
            message.SetString("role", role_str);
            message.SetString("name", name);
            message.SetString("content", content);
        }
        case AiApiGoogleGemini: {
            char role_str[16];
            switch (role) {
                case RoleUser: {
                    role_str = "user";
                }
                case RoleAssistant: {
                    role_str = "model";
                }
                case RoleSystem: {
                    role_str = "";
                }
                default: {
                    role_str = "user";
                }
            }
            if (!StrEqual(role_str, NULL_STRING)) {
                message.SetString("role", role_str);
            }

            JSONArray parts = new JSONArray();
            
            JSONObject part = new JSONObject();
            part.SetString("text", content);

            parts.Push(part);
            delete part;

            message.Set("parts", parts);
            delete parts;
        }
    }
    return message;
}
JSONObject BuildToolMessage(const char[] content, const char[] tool_call_id) {
    JSONObject message = new JSONObject();
    switch (GetApiType()) {
        case AiApiOpenAi: {
            message.SetString("role", "tool");
            message.SetString("tool_call_id", tool_call_id);
            message.SetString("content", content);
        }
        case AiApiGoogleGemini: {
            ThrowError("Google Gemini's Tool message is not supported yet");
        }
    }
    return message;
}

void FormatSystemPrompt(char[] buf, int max_len) {
    char server_name[MAX_NAME_LENGTH];
    char gamemode_name[16];
    char map_name[MAX_NAME_LENGTH];
    char player_number[4];
    char max_player_number[4];
    char flow[16];
    char max_flow[16];
    char flow_percent[6];
    hostname.GetString(server_name, sizeof(server_name));
    int gamemode = L4D_GetGameModeType();
    switch (gamemode) {
        case 1: {
            gamemode_name = "Coop (Campaign)";
        }
        case 2: {
            gamemode_name = "Survival";
        }
        case 4: {
            gamemode_name = "Versus";
        }
        case 8: {
            gamemode_name = "Scavenge";
        }
        default: {
            gamemode_name = "Unknown";
        }
    }
    GetCurrentMap(map_name, sizeof(map_name));
    IntToString(GetPlayerNumber(), player_number, sizeof(player_number));
    IntToString(GetMaxHumanPlayers(), max_player_number, sizeof(max_player_number));
    float flow_distance = L4D2Direct_GetFlowDistance(L4D_GetHighestFlowSurvivor());
    float max_flow_distance = L4D2Direct_GetMapMaxFlowDistance();
    FloatToString(flow_distance, flow, sizeof(flow));
    FloatToString(max_flow_distance, max_flow, sizeof(max_flow));
    FloatToString((flow_distance / max_flow_distance) * 100, flow_percent, sizeof(flow_percent));

    ReplaceString(buf, max_len, "{server_name}", server_name, false);
    ReplaceString(buf, max_len, "{gamemode}", gamemode_name, false);
    ReplaceString(buf, max_len, "{map_name}", map_name, false);
    ReplaceString(buf, max_len, "{flow}", flow, false);
    ReplaceString(buf, max_len, "{max_flow}", max_flow, false);
    ReplaceString(buf, max_len, "{flow_percent}", flow_percent, false);
    ReplaceString(buf, max_len, "{player_number}", player_number, false);
    ReplaceString(buf, max_len, "{max_player_number}", max_player_number, false);
}
void FormatMessagePrompt(char[] buf, int max_len, int client, const char[] content) {
    char player_name[MAX_NAME_LENGTH];
    char player_character[16];
    char player_steam_id[20];
    char flow[16];
    char max_flow[16];
    char flow_percent[6];
    L4D2ZombieClassType zombie_class_type = L4D2_GetPlayerZombieClass(client);
    if (IsPlayerAlive(client)) {
        switch (zombie_class_type) {
            case L4D2ZombieClass_Smoker: {
                player_character = "Smoker";
            }
            case L4D2ZombieClass_Boomer: {
                player_character = "Boomer";
            }
            case L4D2ZombieClass_Hunter: {
                player_character = "Hunter";
            }
            case L4D2ZombieClass_Spitter: {
                player_character = "Spitter";
            }
            case L4D2ZombieClass_Jockey: {
                player_character = "Jockey";
            }
            case L4D2ZombieClass_Charger: {
                player_character = "Charger";
            }
            case L4D2ZombieClass_Tank: {
                player_character = "Tank";
            }
            case L4D2ZombieClass_NotInfected: {
                player_character = "Survivor";
            }
            default: {
                player_character = "Unknown";
            }
        }
    }
    else {
        player_character = "(Dead)";
    }
    GetClientName(client, player_name, sizeof(player_name));
    IntToString(GetSteamAccountID(client), player_steam_id, sizeof(player_steam_id));
    float flow_distance = L4D2Direct_GetFlowDistance(client);
    float max_flow_distance = L4D2Direct_GetMapMaxFlowDistance();
    FloatToString(flow_distance, flow, sizeof(flow));
    FloatToString(max_flow_distance, max_flow, sizeof(max_flow));
    FloatToString((flow_distance / max_flow_distance) * 100, flow_percent, sizeof(flow_percent));

    ReplaceString(buf, max_len, "{player_name}", player_name, false);
    ReplaceString(buf, max_len, "{player_character}", player_character, false);
    ReplaceString(buf, max_len, "{player_steam_id}", player_steam_id, false);
    ReplaceString(buf, max_len, "{flow}", flow, false);
    ReplaceString(buf, max_len, "{max_flow}", max_flow, false);
    ReplaceString(buf, max_len, "{flow_percent}", flow_percent, false);
    ReplaceString(buf, max_len, "{content}", content, false);
}

void RequestAi(const char[] key, const char[] model_name, JSONArray messages, Function callback) {
    if (sizeof(messages) == 0) {
        Call_StartFunction(INVALID_HANDLE, callback);
        Call_PushString(NULL_STRING);
        Call_PushString(model_name);
        Call_PushCell(AiStatusEmptyMessageArray);
        Call_Finish();
        return;
    }

    JSONObject req_data = new JSONObject();
    switch (GetApiType()) {
        case AiApiOpenAi: {
            req_data.SetString("model", model_name);
            req_data.SetFloat("temperature", 0.7);
            req_data.SetInt("max_tokens", max_tokens.IntValue);
            req_data.Set("messages", messages);
        }
        case AiApiGoogleGemini: {
            if (DEBUG) {
                for (int i = 0; i < sizeof(messages); i++) {
                    char message_str[1024];
                    view_as<JSONObject>(messages.Get(i)).ToString(message_str, sizeof(message_str));
                    PrintToServer("messages[%i] =\n%s", i, message_str);
                }
            }

            JSONObject generation_config = new JSONObject();
            generation_config.SetFloat("temperature", 0.7);
            generation_config.SetInt("maxOutputTokens", max_tokens.IntValue);
            req_data.Set("generationConfig", generation_config);
            delete generation_config;

            JSONObject system_instruction = view_as<JSONObject>(messages.Get(0));
            req_data.Set("systemInstruction", system_instruction);
            messages.Remove(0);
            delete system_instruction;

            req_data.Set("contents", messages);
        }
    }

    // Create URL with API key
    char host[128];
    char endpoint[128];
    api_host.GetString(host, sizeof(host));
    api_endpoint.GetString(endpoint, sizeof(endpoint));
    if (GetApiType() == AiApiGoogleGemini) {
        ReplaceString(endpoint, sizeof(endpoint), "{model}", model_name, false);
    }

    char url[256];
    Format(url, sizeof(url), "https://%s%s", host, endpoint);
    if (DEBUG) {
        char req_data_str[1024];
        req_data.ToString(req_data_str, sizeof(req_data_str));
        PrintToServer("url = %s", url);
        PrintToServer("req_data = \n%s", req_data_str);
    }

    // Pack callback function into a private forward
    PrivateForward callback_forward = CreateForward(ET_Single, Param_String, Param_String, Param_Cell);
    callback_forward.AddFunction(INVALID_HANDLE, callback);

    HTTPRequest req = new HTTPRequest(url);
    req.SetHeader("Content-Type", "application/json");
    switch (GetApiType()) {
        case AiApiOpenAi: {
            req.SetHeader("Authorization", "Bearer %s", key);
        }
        case AiApiGoogleGemini: {
            req.AppendQueryParam("key", key);
        }
    }
    req.SetHeader("User-Agent", "Left4Chat2/%s", PLUGIN_VERSION);
    req.Post(req_data, OnRequestComplete, callback_forward);

    // It seems that we have to release memory manually
    delete req_data;
}
public void OnRequestComplete(HTTPResponse res, PrivateForward callback_forward) {
    if (DEBUG) {
        PrintToServer("res.Status = %d", res.Status);
    }
    if (res.Status != HTTPStatus_OK) {
        Call_StartForward(callback_forward);
        Call_PushString(NULL_STRING);
        Call_PushString(NULL_STRING);
        Call_PushCell(AiStatusRequestFailed);
        Call_Finish();
        return;
    }

    JSONObject data = view_as<JSONObject>(res.Data);
    if (DEBUG) {
        char res_data_str[1024];
        data.ToString(res_data_str, sizeof(res_data_str));
        PrintToServer("res_data = \n%s", res_data_str);
    }

    switch (GetApiType()) {
        case AiApiOpenAi: {
            // Prompt and response will never be too long, we just get first message.
            char model_name[32];
            data.GetString("model", model_name, sizeof(model_name));
            JSONArray messages = view_as<JSONArray>(data.Get("choices"));
            JSONObject message = view_as<JSONObject>(messages.Get(0));
            
            char finish_reason[32];
            message.GetString("finish_reason", finish_reason, sizeof(finish_reason));

            JSONObject actual_message = view_as<JSONObject>(message.Get("message"));
            char response[MAX_RESPONSE_LENGTH];
            actual_message.GetString("content", response, sizeof(response));
            delete actual_message;

            if (DEBUG) {
                PrintToServer("finish_reason = %s", finish_reason);
                PrintToServer("response =\n%s", response);
            }

            Call_StartForward(callback_forward);
            Call_PushString(response);
            Call_PushString(model_name);
            if (StrEqual(finish_reason, "stop")) {
                Call_PushCell(AiStatusSuccess);
            }
            else if (StrEqual(finish_reason, "length")) {
                Call_PushCell(AiStatusResponseIsTooLong);
            }
            else if (StrEqual(finish_reason, "content_filter")) {
                Call_PushCell(AiStatusResponseTriggeredContentFilter);
            }
            else if (StrEqual(finish_reason, "insufficient_system_resource")) {
                Call_PushCell(AiStatusServiceProviderWentWrong);
            }
            else {
                Call_PushCell(AiStatusUnknown);
            }
            Call_Finish();

            delete message;
            delete messages;
        }
        case AiApiGoogleGemini: {
            char model_name[32];
            data.GetString("modelVersion", model_name, sizeof(model_name));
            JSONArray messages = view_as<JSONArray>(data.Get("candidates"));
            JSONObject message = view_as<JSONObject>(messages.Get(0));

            char finish_reason[32];
            message.GetString("finishReason", finish_reason, sizeof(finish_reason));

            JSONObject actual_message = view_as<JSONObject>(message.Get("content"));
            JSONArray parts = view_as<JSONArray>(actual_message.Get("parts"));
            JSONObject part = view_as<JSONObject>(parts.Get(0));
            char response[MAX_RESPONSE_LENGTH];
            part.GetString("text", response, sizeof(response));
            delete actual_message;
            delete parts;
            delete part;

            if (DEBUG) {
                PrintToServer("finish_reason = %s", finish_reason);
                PrintToServer("response =\n%s", response);
            }

            Call_StartForward(callback_forward);
            Call_PushString(response);
            Call_PushString(model_name);
            if (
                StrEqual(finish_reason, "STOP") ||
                StrEqual(finish_reason, "RECITATION")
            ) {
                Call_PushCell(AiStatusSuccess);
            }
            else if (StrEqual(finish_reason, "MAX_TOKENS")) {
                Call_PushCell(AiStatusResponseIsTooLong);
            }
            else if (
                StrEqual(finish_reason, "SAFETY") ||
                StrEqual(finish_reason, "IMAGE_SAFETY") ||
                StrEqual(finish_reason, "BLOCKLIST") ||
                StrEqual(finish_reason, "PROHIBITED_CONTENT") ||
                StrEqual(finish_reason, "SPIT") ||
                StrEqual(finish_reason, "MALFORMED_FUNCTION_CALL")
            ) {
                Call_PushCell(AiStatusResponseTriggeredContentFilter);
            }
            else if (StrEqual(finish_reason, "LANGUAGE")) {
                Call_PushCell(AiStatusServiceProviderWentWrong);
            }
            else {
                Call_PushCell(AiStatusUnknown);
            }
            Call_Finish();

            delete message;
            delete messages;
        }
    }

    delete data;
    
    callback_forward.RemoveAllFunctions(INVALID_HANDLE);
    delete callback_forward;
}

void SendSplitResponse(const char[] response) {
    int response_length = strlen(response);
    char model_name[32];
    model.GetString(model_name, sizeof(model_name));
    if (response_length <= MAX_CHAT_CONTENT_LENGTH) {
        CPrintToChatAll("%t", "Respond", model_name, response);
        return;
    }

    int max_length = MAX_CHAT_CONTENT_LENGTH - 1;
    int current_index = 0;
    bool is_first_part = true;
    while (current_index < response_length) {
        // char color_definition[16] = "";
        int end_index = FindSafeSplitPosition(response, response_length, current_index, max_length);
        // Process too many bytes in one character.
        if (end_index <= current_index) {
            end_index = current_index + response_length;
            if (end_index >= response_length) {
                end_index = response_length - 1;
            }
        }

        char part[MAX_CHAT_CONTENT_LENGTH];
        strcopy(part, end_index - current_index + 1, response[current_index]);
        if (is_first_part) {
            CPrintToChatAll("%t", "Respond", model_name, part);
        }
        else {
            CPrintToChatAll("%t", "Respond part", part);
        }

        current_index = end_index;
        is_first_part = false;
    }
}

// We have to consider about multi-byte characters.
int FindSafeSplitPosition(const char[] str, int len, int start_index, int max_bytes) {
    int current_index = start_index;
    int total_bytes = 0;
    int color_definition_start_index = -1;
    while (current_index < len && total_bytes < max_bytes) {
        char ch = str[current_index];
        if (ch == '{') {
            color_definition_start_index = current_index;
        }
        else if (ch == '}' && color_definition_start_index != -1) {
            // strcopy(color_definition, current_index - color_definition_start_index + 2, str[color_definition_start_index]);
            color_definition_start_index = -1;
        }
        int bytes = GetUtf8CharBytes(str[current_index]);
        if (total_bytes + bytes > max_bytes) {
            break;
        }
        total_bytes += bytes;
        current_index += bytes;
    }
    if (color_definition_start_index != -1) {
        return color_definition_start_index;
    }
    return current_index;
}

int GetUtf8CharBytes(int c) {
    if (c <= 0x7F) {
        return 1;
    }
    if ((c & 0xE0) == 0xC0) {
        return 2;
    }
    else if ((c & 0xF0) == 0xE0) {
        return 3;
    }
    else if ((c & 0xF8) == 0xF0) {
        return 4;
    }
    return 1;
}