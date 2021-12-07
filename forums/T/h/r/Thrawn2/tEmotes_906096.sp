#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.0.1"
#define MAX_LENGTH 255
#define MAX_OBJECTS 127
#define MAX_PLAYERS 31
#define EF_NOSHADOW             (1 << 4)
#define EF_NORECEIVESHADOW      (1 << 6)

new Handle:g_hCvarEnable;
new Handle:g_hCvarInterval;

new g_EmoteIcon[MAX_PLAYERS+1] = {-1, ...};
new g_EmoteCount = 0;
new String:g_EmoteCode[MAX_OBJECTS][MAX_LENGTH];
new String:g_EmoteModel[MAX_OBJECTS][MAX_LENGTH];


public Plugin:myinfo =
{
    name = "tEmotes",
    author = "Thrawn",
    description = "A emote plugin.",
    version = VERSION,
    url = "http://aaa.wallbash.com"
};

public OnPluginStart()
{
    g_hCvarEnable = CreateConVar("sm_temotes_enable", "1", "Enable/Disable tEmotes", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarInterval = CreateConVar("sm_temotes_duration", "4.0", "Time (in seconds) an emote is visible", FCVAR_PLUGIN, true, 0.0);

    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);

    AutoExecConfig(true, "plugin.tEmotes");
    ParseEmoteList();
}

public OnClientDisconnect(Client)
{
    RemoveEmoteIcon(Client);
}

public Action:Command_Say(client, args)
{
    if (!g_hCvarEnable || !client)
    {
        return Plugin_Continue;
    }

    decl String:text[192];
    if (!GetCmdArgString(text, sizeof(text)))
    {
        return Plugin_Continue;
    }

    new startidx = 0;
    if(text[strlen(text)-1] == '"')
    {
        text[strlen(text)-1] = '\0';
        startidx = 1;
    }

    for (new i=0; i<g_EmoteCount; i++)
    {
        if (strcmp(text[startidx], g_EmoteCode[i], false) == 0)
        {
            CreateEmoteIcon(client, i);
        }
    }

    return Plugin_Continue;
}

EmoteDownload(String:path[],String:tmpModel[],String:extension[])
{
    new String:tmpString[255];
    Format(tmpString, MAX_LENGTH, "%s%s%s", path, tmpModel, extension);
    AddFileToDownloadsTable(tmpString);
}

ParseEmoteList()
{
    g_EmoteCount = 0;

    if (GetConVarBool(g_hCvarEnable))
    {
        new Handle:hKV = CreateKeyValues("tEmotes");

        new String:file[128];
        BuildPath(Path_SM, file, sizeof(file), "configs/tEmotes.cfg");
        FileToKeyValues(hKV, file);

        if (!KvGotoFirstSubKey(hKV)) { LogMessage("Error_CantOpenEmoteList"); return; }

        do
        {
            new String:tmpModel[255];
            KvGetSectionName(hKV, tmpModel, sizeof(tmpModel));
            KvGetString(hKV, "code", g_EmoteCode[g_EmoteCount], MAX_LENGTH);

            Format(g_EmoteModel[g_EmoteCount], MAX_LENGTH, "%s%s%s", "models/extras/", tmpModel, "/info_speech.mdl");

            PrecacheModel(g_EmoteModel[g_EmoteCount], true);

            EmoteDownload("models/extras/", tmpModel, "/info_speech.mdl");
            EmoteDownload("models/extras/", tmpModel, "/info_speech.dx80.vtx");
            EmoteDownload("models/extras/", tmpModel, "/info_speech.dx90.vtx");
            EmoteDownload("models/extras/", tmpModel, "/info_speech.phy");
            EmoteDownload("models/extras/", tmpModel, "/info_speech.sw.vtx");
            EmoteDownload("models/extras/", tmpModel, "/info_speech.vvd");
            EmoteDownload("models/extras/", tmpModel, "/info_speech.xbox.vtx");

            EmoteDownload("materials/models/extras/", tmpModel, "/speech_info.vmt");
            EmoteDownload("materials/models/extras/", tmpModel, "/speech_info.vtf");

            g_EmoteCount++;
        }
        while (KvGotoNextKey(hKV));

        CloseHandle(hKV);
    }
}


stock CreateEmoteIcon(any:client,emoteNo)
{
    RemoveEmoteIcon(client);

    g_EmoteIcon[client] = CreateEntityByName("prop_dynamic");

    if (IsValidEdict(g_EmoteIcon[client]))
    {
        new String:tName[32];

        GetClientName(client, tName, sizeof(tName));
        DispatchKeyValue(g_EmoteIcon[client], "targetname", "emote_icon");
        DispatchKeyValue(g_EmoteIcon[client], "parentname", tName);
        SetEntityModel(g_EmoteIcon[client], g_EmoteModel[emoteNo]);
        SetEntProp(g_EmoteIcon[client], Prop_Send, "m_fEffects",    EF_NOSHADOW|EF_NORECEIVESHADOW);
        DispatchSpawn(g_EmoteIcon[client]);

        SetVariantString("!activator");
        AcceptEntityInput(g_EmoteIcon[client], "SetParent", client, client, 0);

        ActivateEntity(g_EmoteIcon[client]);

        new Float:pos[3];
        pos[0] = 0.0;
        pos[1] = 0.0;
        pos[2] = 96.0;

        new Float:ang[3];

        TeleportEntity(g_EmoteIcon[client], pos, ang, NULL_VECTOR);
        CreateTimer(GetConVarFloat(g_hCvarInterval), Timer_RemoveEmote, client);
    }
}

public Action:Timer_RemoveEmote(Handle:timer, any:data)
{
    RemoveEmoteIcon(data);
}

stock RemoveEmoteIcon(any:client)
{
    if(g_EmoteIcon[client] != -1 && IsValidEdict(g_EmoteIcon[client]))
    {
        RemoveEdict(g_EmoteIcon[client]);
    }

    g_EmoteIcon[client] = -1;
}