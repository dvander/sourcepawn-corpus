#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <basecomm>
#include <sdktools_sound>
#include <multicolors>

#define DATA_FILE       "chat_responses.txt"
#define MAX_LINE_LENGTH 256
#define MAX_RESPONSES   32

/* -------------------- ConVars -------------------- */
ConVar g_cvDelay;
ConVar g_cvSoundEnable;
ConVar g_cvSoundFile;

/* -------------------- Cache de respostas --------- */
char g_responseKeywords[MAX_RESPONSES][128];
int g_responseMatchMode[MAX_RESPONSES];
ArrayList g_responseLines[MAX_RESPONSES];
int g_responseCount = 0;

/* -------------------- Info ----------------------- */
public Plugin myinfo =
{
    name        = "Chat Responses",
    description = "Mostra respostas configuráveis no chat; toca som opcional para o autor.",
    author      = "Ribas",
    version     = "1.6",
    url         = "https://hl2dm.com.br"
};

/* -------------------- Start ---------------------- */
public void OnPluginStart()
{
    /* ConVars */
    g_cvDelay       = CreateConVar("sm_responses_delay",      "0.2", "Delay (s) before displaying the response.", FCVAR_NOTIFY);
    g_cvSoundEnable = CreateConVar("sm_responses_sound",      "1",   "0 = no sound, 1 = play sound.",           FCVAR_NOTIFY);
    g_cvSoundFile   = CreateConVar("sm_responses_sound_file", "buttons/button15.wav", "Sound file path.",    FCVAR_NOTIFY);

    AutoExecConfig(true, "sm_responses");

    /* Precache inicial do som */
    char sFile[PLATFORM_MAX_PATH];
    g_cvSoundFile.GetString(sFile, sizeof(sFile));
    PrecacheSound(sFile, true);
    HookConVarChange(g_cvSoundFile, OnSoundFileChanged);

    /* Carrega respostas na inicialização */
    LoadAllResponses();

    /* Comando para recarregar respostas */
    RegAdminCmd("sm_responses_reload", Command_ReloadResponses, ADMFLAG_CONFIG, "Reloads chat responses configuration");

    /* Evento POST → resposta sai abaixo do chat do jogador */
    HookEvent("player_say", Event_PlayerSay_Post, EventHookMode_Post);
}

/* Atualiza som se mudar pelo console */
public void OnSoundFileChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    PrecacheSound(newValue, true);
}

/* -------------------- Comando reload ------------- */
public Action Command_ReloadResponses(int client, int args)
{
    LoadAllResponses();
    ReplyToCommand(client, "[ChatResp] Responses reloaded! Total: %d", g_responseCount);
    return Plugin_Handled;
}

/* -------------------- Evento chat ---------------- */
public void Event_PlayerSay_Post(Event e, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(e.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client) || BaseComm_IsClientGagged(client))
        return;

    char text[MAX_LINE_LENGTH];
    e.GetString("text", text, sizeof(text));
    TrimString(text);

    /* Busca resposta no cache (operação rápida) */
    int responseIndex = FindResponse(text);
    if (responseIndex == -1)
        return;

    float d = g_cvDelay.FloatValue;
    if (d > 0.0)
    {
        /* Empacota client + índice da resposta no DataPack */
        DataPack pack = new DataPack();
        pack.WriteCell(client);
        pack.WriteCell(responseIndex);
        pack.Reset();
        CreateTimer(d, Timer_PrintResponse, pack, TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        PrintResponseFromCache(client, responseIndex);
    }
}

/* -------------------- Timer ---------------------- */
public Action Timer_PrintResponse(Handle t, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int client = pack.ReadCell();
    int responseIndex = pack.ReadCell();
    delete pack;

    PrintResponseFromCache(client, responseIndex);
    return Plugin_Stop;
}

/* -------------------- Print + som ---------------- */
void PrintResponseFromCache(int client, int responseIndex)
{
    if (responseIndex < 0 || responseIndex >= g_responseCount)
        return;

    /* Som só para quem digitou */
    if (g_cvSoundEnable.BoolValue && IsClientInGame(client))
    {
        char wav[PLATFORM_MAX_PATH];
        g_cvSoundFile.GetString(wav, sizeof(wav));
        EmitSoundToClient(client, wav);
    }

    /* Imprime todas as linhas da resposta do cache */
    ArrayList lines = g_responseLines[responseIndex];
    for (int i = 0; i < lines.Length; i++)
    {
        char line[MAX_LINE_LENGTH];
        lines.GetString(i, line, sizeof(line));
        CPrintToChatAll(line);
    }
}

/* -------------------- Busca rápida --------------- */
int FindResponse(const char[] chat)
{
    /* Loop otimizado pelo cache - sem I/O, só comparações em memória */
    for (int i = 0; i < g_responseCount; i++)
    {
        char keywords[128];
        strcopy(keywords, sizeof(keywords), g_responseKeywords[i]);
        int mode = g_responseMatchMode[i];
        bool match = false;

        /* Verifica se há vírgula na string */
        if (StrContains(keywords, ",") != -1)
        {
            /* Múltiplas palavras */
            char keywordList[8][32];
            int numKeywords = ExplodeString(keywords, ",", keywordList, sizeof(keywordList), sizeof(keywordList[]));
            
            for (int k = 0; k < numKeywords && !match; k++)
            {
                TrimString(keywordList[k]);
                
                if (strlen(keywordList[k]) == 0)
                    continue;
                    
                match = (mode == 1)
                        ? StrEqual(chat, keywordList[k], false)
                        : (StrContains(chat, keywordList[k], false) != -1);
            }
        }
        else
        {
            /* Palavra única */
            match = (mode == 1)
                    ? StrEqual(chat, keywords, false)
                    : (StrContains(chat, keywords, false) != -1);
        }

        if (match)
            return i;
    }

    return -1; // Não encontrou
}

/* -------------------- Carregador inicial ---------- */
void LoadAllResponses()
{
    /* Limpa cache anterior */
    for (int i = 0; i < g_responseCount; i++)
    {
        if (g_responseLines[i] != null)
            delete g_responseLines[i];
    }
    g_responseCount = 0;

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/%s", DATA_FILE);

    KeyValues root = CreateKeyValues("ChatResponses");
    if (!FileToKeyValues(root, path))
    {
        LogError("[ChatResp] Failed to read %s", path);
        CloseHandle(root);
        return;
    }

    if (KvGotoFirstSubKey(root))
    {
        do
        {
            if (g_responseCount >= MAX_RESPONSES)
            {
                LogError("[ChatResp] Maximum of %d responses reached!", MAX_RESPONSES);
                break;
            }

            /* Lê dados da seção */
            char keywords[128];
            KvGetSectionName(root, keywords, sizeof(keywords));
            TrimString(keywords);
            
            int mode = KvGetNum(root, "match", 0);

            /* Cria ArrayList para as linhas */
            ArrayList lines = new ArrayList(MAX_LINE_LENGTH);

            /* Lê seção "text" */
            if (KvJumpToKey(root, "text"))
            {
                if (KvGotoFirstSubKey(root, false))
                {
                    do
                    {
                        char lineValue[MAX_LINE_LENGTH];
                        KvGetString(root, NULL_STRING, lineValue, sizeof(lineValue));
                        
                        if (strlen(lineValue) > 0)
                            lines.PushString(lineValue);
                    }
                    while (KvGotoNextKey(root, false));
                }
                KvGoBack(root); // Volta para "text"
                KvGoBack(root); // Volta para a seção principal
            }

            /* Armazena no cache apenas se tem linhas */
            if (lines.Length > 0)
            {
                strcopy(g_responseKeywords[g_responseCount], sizeof(g_responseKeywords[]), keywords);
                g_responseMatchMode[g_responseCount] = mode;
                g_responseLines[g_responseCount] = lines;
                g_responseCount++;
            }
            else
            {
                delete lines;
            }
        }
        while (KvGotoNextKey(root));
    }

    CloseHandle(root);
    LogMessage("[ChatResp] Loaded %d responses in cache", g_responseCount);
}

/* -------------------- Cleanup -------------------- */
public void OnPluginEnd()
{
    for (int i = 0; i < g_responseCount; i++)
    {
        if (g_responseLines[i] != null)
            delete g_responseLines[i];
    }
}