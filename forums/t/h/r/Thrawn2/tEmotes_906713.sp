#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.0.4"
#define MAX_LENGTH 255
#define MAX_OBJECTS 127
#define MAX_PLAYERS 31
#define EF_NOSHADOW             (1 << 4)
#define EF_NORECEIVESHADOW      (1 << 6)

#define TEAM_RED 2
#define TEAM_BLUE 3

new Handle:g_hCvarEnable;
new Handle:g_hCvarInterval;

new g_EmoteIcon[MAX_PLAYERS+1] = {-1, ...};
new Handle:g_EmoteTimer[MAX_PLAYERS+1] = {INVALID_HANDLE, ...};

new bool:g_bEnabled = false;

new g_EmoteCount = 0;
new String:g_EmoteCode[MAX_OBJECTS][MAX_LENGTH];
new String:g_EmoteModel[MAX_OBJECTS][MAX_LENGTH];


public Plugin:myinfo =
{
    name = "tEmotes",
    author = "Thrawn",
    description = "An emote plugin.",
    version = VERSION,
    url = "http://aaa.wallbash.com"
};

public OnPluginStart()
{
    g_hCvarEnable = CreateConVar("sm_temotes_enable", "1", "Enable/Disable tEmotes", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarInterval = CreateConVar("sm_temotes_duration", "4.0", "Time (in seconds) an emote is visible", FCVAR_PLUGIN, true, 0.0);
    CreateConVar("sm_temotes_version", VERSION, "tEmotes version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    RegAdminCmd("sm_temotes_list", Command_List, ADMFLAG_BAN);
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);	

    AutoExecConfig(true, "plugin.tEmotes");              
    
    HookConVarChange(g_hCvarEnable, Cvar_enabled);
}

public OnMapStart()
{   
	ParseEmoteList(); 
}

public OnClientDisconnect(Client)
{
    RemoveEmoteIcon(Client);
}

public OnConfigsExecuted() {            
	g_bEnabled = GetConVarBool(g_hCvarEnable);
}

public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnable);
	
	if(g_bEnabled) {
		//##FIXME Precache all emoticons if enabled
		ParseEmoteList(); 
	} else {
		//##FIXME Remove current emoticons if disabled
	}
}

public Action:Command_List(client, args)
{
    if (!g_bEnabled || !client)
        return Plugin_Continue;
    
    for (new i=0; i<g_EmoteCount; i++)
        ReplyToCommand(client, "%i: %s", i+1, g_EmoteCode[i]);
    
    return Plugin_Continue; 
}

public precacheModels() {
    for (new i=0; i<g_EmoteCount; i++)
    {
        LogMessage("[tEmotes], Precached model: %s", g_EmoteModel[i]);
        PrecacheModel(g_EmoteModel[i], true);
    }
}

public Action:Command_Say(client, args)
{
    if (!g_bEnabled || !client)
        return Plugin_Continue;

    if(!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
        return Plugin_Continue;

    decl String:text[192];
    if (!GetCmdArgString(text, sizeof(text)))
        return Plugin_Continue;

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
	LogMessage("Parsing emote list");
	g_EmoteCount = 0;
	
	new String:file[128];
	BuildPath(Path_SM, file, sizeof(file), "configs/tEmotes.cfg");
	
	if(FileExists(file)) {
		new Handle:hKV = CreateKeyValues("tEmotes");
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
		
		LogMessage("Found %i emoticons", g_EmoteCount);
	} else {
		LogMessage("There is no configs/tEmotes.cfg file. Plugin is disabled.");
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

        SetVariantString("idle");
        AcceptEntityInput(g_EmoteIcon[client], "SetAnimation", client, client, 0);

        ActivateEntity(g_EmoteIcon[client]);

        new Float:pos[3];
        pos[0] = 0.0;
        pos[1] = 0.0;
        pos[2] = 96.0;

        new Float:ang[3];

        TeleportEntity(g_EmoteIcon[client], pos, ang, NULL_VECTOR);
        g_EmoteTimer[client] = CreateTimer(GetConVarFloat(g_hCvarInterval), Timer_RemoveEmote, client);
    }
}

public Action:Timer_RemoveEmote(Handle:timer, any:client)
{
    g_EmoteTimer[client] = INVALID_HANDLE;
    RemoveEmoteIcon(client);    
}

stock RemoveEmoteIcon(any:client)
{
    if (g_EmoteTimer[client] != INVALID_HANDLE)
        CloseHandle(g_EmoteTimer[client]);

    if(g_EmoteIcon[client] != -1 && IsValidEdict(g_EmoteIcon[client]))
    {
        RemoveEdict(g_EmoteIcon[client]);
    }

    g_EmoteIcon[client] = -1;
}