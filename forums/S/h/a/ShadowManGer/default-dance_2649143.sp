#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2attributes>
#include <tf2items>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"
#define TAUNT_LAUGH 463
#define danceMusic "tf2_fdd/music.wav"

Handle hPlayTaunt = INVALID_HANDLE;
Handle danceTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle botsEnabled = INVALID_HANDLE;

//Classes models
#define scoutModel "models/tf2_fdd/scout.mdl"
#define soldierModel "models/tf2_fdd/soldier.mdl"
#define pyroModel "models/tf2_fdd/pyro.mdl"
#define demoModel "models/tf2_fdd/demo.mdl"
#define heavyModel "models/tf2_fdd/heavy.mdl"
#define engieModel "models/tf2_fdd/engineer.mdl"
#define medicModel "models/tf2_fdd/medic.mdl"
#define sniperModel "models/tf2_fdd/sniper.mdl"
#define spyModel "models/tf2_fdd/spy.mdl"

bool dancing[MAXPLAYERS+1];
bool taunting[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "[TF2] Default Dance",
    author = "ShadowMarioBR",
    description = "Dance Fortnite's most known emote, now in Team Fortress 2!",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2622494"
};

public void OnPluginStart()
{
    Handle conf = LoadGameConfigFile("tf2.tauntem");
    if (conf == INVALID_HANDLE)
    {
        SetFailState("Unable to load gamedata/tf2.tauntem.txt. Good luck figuring that out.");
        return;
    }
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    hPlayTaunt = EndPrepSDKCall();
    if (hPlayTaunt == INVALID_HANDLE)
    {
        SetFailState("Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Wait patiently for a fix.");
        CloseHandle(conf);
        return;
    }
    CloseHandle(conf);

    // Create ConVar and ConsoleCmd
    CreateConVar("sm_defaultdance_version", PLUGIN_VERSION, "Version of TF2 Default Dance.", FCVAR_REPLICATED | FCVAR_NOTIFY);
    botsEnabled = CreateConVar("sm_defaultdance_bots", "5", "Chance in percent for the Bots dance after killing, 0 for disable.", _, true, 0.0, true, 100.0);
    RegConsoleCmd("sm_defaultdance", DefaultDance, "Does the dance.", FCVAR_GAMEDLL);

    // Hooks
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("player_changeclass", OnChangeClass, EventHookMode_Post);
    AddNormalSoundHook(SoundCallback);
}

public void OnMapStart()
{
    // Models and Sounds Download Table
    AddFileToDownloadsTable("sound/tf2_fdd/music.wav");
    AddFileToDownloadsTable("models/tf2_fdd/scout.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/scout.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/scout.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/scout.phy");
    AddFileToDownloadsTable("models/tf2_fdd/scout.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/scout.vvd");
    AddFileToDownloadsTable("models/tf2_fdd/soldier.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/soldier.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/soldier.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/soldier.phy");
    AddFileToDownloadsTable("models/tf2_fdd/soldier.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/soldier.vvd");
    AddFileToDownloadsTable("models/tf2_fdd/pyro.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/pyro.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/pyro.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/pyro.phy");
    AddFileToDownloadsTable("models/tf2_fdd/pyro.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/pyro.vvd");
    AddFileToDownloadsTable("models/tf2_fdd/demo.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/demo.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/demo.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/demo.phy");
    AddFileToDownloadsTable("models/tf2_fdd/demo.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/demo.vvd");
    AddFileToDownloadsTable("models/tf2_fdd/heavy.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/heavy.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/heavy.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/heavy.phy");
    AddFileToDownloadsTable("models/tf2_fdd/heavy.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/heavy.vvd");
    AddFileToDownloadsTable("models/tf2_fdd/engineer.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/engineer.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/engineer.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/engineer.phy");
    AddFileToDownloadsTable("models/tf2_fdd/engineer.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/engineer.vvd");
    AddFileToDownloadsTable("models/tf2_fdd/medic.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/medic.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/medic.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/medic.phy");
    AddFileToDownloadsTable("models/tf2_fdd/medic.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/medic.vvd");
    AddFileToDownloadsTable("models/tf2_fdd/sniper.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/sniper.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/sniper.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/sniper.phy");
    AddFileToDownloadsTable("models/tf2_fdd/sniper.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/sniper.vvd");
    AddFileToDownloadsTable("models/tf2_fdd/spy.dx80.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/spy.dx90.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/spy.mdl");
    AddFileToDownloadsTable("models/tf2_fdd/spy.phy");
    AddFileToDownloadsTable("models/tf2_fdd/spy.sw.vtx");
    AddFileToDownloadsTable("models/tf2_fdd/spy.vvd");

    // Model Precaching
    PrecacheSound(danceMusic, true);
    PrecacheModel(scoutModel, true);
    PrecacheModel(soldierModel, true);
    PrecacheModel(pyroModel, true);
    PrecacheModel(demoModel, true);
    PrecacheModel(heavyModel, true);
    PrecacheModel(engieModel, true);
    PrecacheModel(medicModel, true);
    PrecacheModel(sniperModel, true);
    PrecacheModel(spyModel, true);
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    if(client > 0 && client <= MaxClients && dancing[client] && IsValidEntity(client))
    {
        dancing[client] = false;
        if(danceTimer[client] != INVALID_HANDLE)
        {
            KillTimer(danceTimer[client]);
            danceTimer[client] = INVALID_HANDLE;

            StopSound(client, SNDCHAN_AUTO, danceMusic);
            TF2Attrib_SetByDefIndex(client, 201, 1.0);
        }
    }
    if(attacker > 0 && !taunting[attacker] && attacker != client && IsValidEntity(attacker) && IsPlayerAlive(attacker))
    {
        if(IsFakeClient(attacker))
        {
            int randomint = GetRandomInt(1, 100);
            if(randomint <= GetConVarInt(botsEnabled))
            {
                FakeClientCommandEx(attacker, "say /defaultdance");
            }
        }
    }
    return Plugin_Continue;
}

public Action OnChangeClass(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(client > 0 && client <= MaxClients && dancing[client] && IsValidEntity(client))
    {
        dancing[client] = false;
        if(danceTimer[client] != INVALID_HANDLE)
        {
            KillTimer(danceTimer[client]);
            danceTimer[client] = INVALID_HANDLE;

            StopSound(client, SNDCHAN_AUTO, danceMusic);
            TF2Attrib_SetByDefIndex(client, 201, 1.0);
        }
    }
}

public Action SoundCallback(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, char &flags)
{
    if (entity > -1 && entity <= MaxClients)
    {
        if(dancing[entity] && StrContains(sample, "_Laugh", false) != -1)
        {
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

public Action DefaultDance(int client, int args)
{
    float position[3];
    if(client > 0 && client <= MaxClients && !taunting[client] && IsPlayerAlive(client) && IsValidEntity(client) && GetEntityFlags(client) & FL_ONGROUND)
    {
        if (danceTimer[client] != INVALID_HANDLE)
        {
            return Plugin_Handled;
        }

        new TFClassType:class = TF2_GetPlayerClass(client);
        if(class == TFClass_Scout)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.67);
            SetVariantString(scoutModel);
        }
        if(class == TFClass_Soldier)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.67);
            SetVariantString(soldierModel);
        }
        if(class == TFClass_Pyro)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.67);
            SetVariantString(pyroModel);
        }
        if(class == TFClass_DemoMan)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.71);
            SetVariantString(demoModel);
        }
        if(class == TFClass_Heavy)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.67);
            SetVariantString(heavyModel);
        }
        if(class == TFClass_Engineer)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.47);
            SetVariantString(engieModel);
        }
        if(class == TFClass_Medic)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.67);
            SetVariantString(medicModel);
        }
        if(class == TFClass_Sniper)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.47);
            SetVariantString(sniperModel);
        }
        if(class == TFClass_Spy)
        {
            TF2Attrib_SetByDefIndex(client, 201, 0.89);
            SetVariantString(spyModel);
        }
        AcceptEntityInput(client, "SetCustomModel");
        SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
        SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
        int ent = MakeCEIVEnt(client, TAUNT_LAUGH);
        Address pEconItemView = GetEntityAddress(ent) + view_as<Address>(FindSendPropInfo("CTFWearable", "m_Item"));
        if (!IsValidAddress(pEconItemView))
        {
            ReplyToCommand(client, "[SM] Couldn't find CEconItemView for taunt");
            return Plugin_Handled;
        }
        SDKCall(hPlayTaunt, client, pEconItemView);

        AcceptEntityInput(ent, "Kill");

        EmitSoundToAll(danceMusic, client, _, _, _, _, _, client, position);
        dancing[client] = true;
        danceTimer[client] = CreateTimer(7.4, Timer_DanceStop, client, TIMER_REPEAT);
    }
    return Plugin_Handled;
}

public Action Timer_DanceStop(Handle timer, int client) //Taken from FF2 default_abilities
{
    if(IsValidEntity(client))
    {
        if(danceTimer[client] != INVALID_HANDLE)
        {
            SetVariantString("");
            AcceptEntityInput(client, "SetCustomModel");
            SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
            TF2Attrib_SetByDefIndex(client, 201, 1.0);
            dancing[client] = false;
            KillTimer(danceTimer[client]);
            danceTimer[client] = INVALID_HANDLE;
        }
        else
        {
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

stock int MakeCEIVEnt(int client, int itemdef, int particle=0)
{
    static Handle hItem;
    if (hItem == INVALID_HANDLE)
    {
        hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
        TF2Items_SetClassname(hItem, "tf_wearable_vm");
        TF2Items_SetQuality(hItem, 6);
        TF2Items_SetLevel(hItem, 1);
    }
    TF2Items_SetItemIndex(hItem, itemdef);
    return TF2Items_GiveNamedItem(client, hItem);
}

stock bool IsValidAddress(Address pAddress)
{
    return (pAddress != Address_Null && (pAddress & view_as<Address>(0x7FFFFFFF)) >= view_as<Address>(0x00000000));
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
    if(condition == TFCond_Taunting) taunting[client]=true;
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
    if(client > 0 && condition == TFCond_Taunting && IsValidEntity(client))
    {
        taunting[client] = false;
        if(danceTimer[client] != INVALID_HANDLE)
        {
            SetVariantString("");
            AcceptEntityInput(client, "SetCustomModel");
            SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
            TF2Attrib_SetByDefIndex(client, 201, 1.0);
            dancing[client] = false;
            KillTimer(danceTimer[client]);
            danceTimer[client] = INVALID_HANDLE;
        }
    }
}