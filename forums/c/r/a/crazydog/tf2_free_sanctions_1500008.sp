/*


[b][size=4]Description[/size][/b]

This plugin allows server admins to place various sanctions on F2P players. The currently available options are:
[list]
[*]Renamer
[list]
[*]Add tags to the beginning/end of Freebers' names.
[*]Optional automatic name truncation.
[*]Name change handling
[*]Option to only change name in chat
[/list]
[*]Gag/Muter
[list]
[*]Gag all Freebers (no chat)
[*]Mute all Freebers (no voicecomm)
[/list]
[*]Taunt Blocking - Freebers cannot taunt
[*]Hat blocking - Freebers cannot wear hats
[*]Spray blocking - Freebers cannot spray
[*]Force Freebers to a random team and class on join (they are free to change afterwards).
[*]Send a chat message to all Freebers, not premium players.
[*]Kicking of all Freebers
[/list]


[size=3][b]Commands[/b][/size]

[b]sm_frbr_say MESSAGE[/b] - Send MESSAGE to all Freebers in the server.


[size=3][b]CVars[/b][/size]

[i]sm_frbr_rename_enable[/i] - Enable (1) or Disable renaming Freebers
[i]sm_frbr_ftag[/i] - Name Tag for Free users
[i]sm_frbr_position[/i] - Position of Name Tag (0=front 1=back)
[i]sm_frbr_truncate[/i] - Truncate client names for tag to fit
[i]sm_frbr_rename_chatonly[/i] - Only add Name Tag to chat messages.

[i]sm_frbr_gag_enable[/i] - Enable (1) or Disable (0) gagging of Freebers.
[i]sm_frbr_mute_enable[/i] - Enable (1) or Disable (0) muting of Freebers.

[i]sm_frbr_tauntblock_enable[/i] - Allow (0) or disallow (1) taunting by Freebers.

[i]sm_frbr_strip_enable[/i] - Set to 1 to strip hats from Freebers.

[i]sm_frbr_kick_enable[/i] - Set to 1 to kick all Freebers upon connection.

[i]sm_frbr_sprayblock_enable[/i] - Allow (0) or disallow (1) sprays by Freebers.

[i]sm_frbr_forceteam_enable[/i] - If set to 1, force Freebers to join a team as soon as they connect.
[i]sm_frbr_forceclass_enable[/i] - If set to 1, force Freebers to pick a class as soon as they connect.


[size=3][b]Requisites[/b][/size]

[url=https://forums.alliedmods.net/showthread.php?t=129763]SteamTools[/url]


[size=3][b]Installation[/b][/size]

Place tf2_free_sanctions.smx in addons/sourcemod/plugins
Place mechatheslag_global.txt in addons/sourcemod/gamedata


[size=3][b]ToDo[/b][/size]

-Restrict Freebers to only stock weapons.
-??? Post below!


[size=3]Changelog[/size]
[code]
1.0 (6/29/2011)
 - Fixed name change handling
1.0 (6/28/2011)
 - Initial Release
[/code]

[size=4]Thanks[/size]
Thanks to the following plugins and their authors:
[url=http://forums.alliedmods.net/showthread.php?t=160049]Free2BeKicked by asherkin[/url]
[url=http://forums.alliedmods.net/showthread.php?t=160553] 2Free2Spray by DarthNinja[/url]
basecomm by AlliedModders LLC
[url=http://forums.alliedmods.net/showthread.php?p=1365058]No Hats by Mecha The Slag[/url]


*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <colors>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "1.1"

//new Handle:g_hSdkRemoveWearable;

#define INDEX_RAZORBACK             57
#define INDEX_GUNBOATS              133
#define INDEX_NOISEMAKER_CRAZY      286
#define INDEX_NOISEMAKER_BANSHEE    284
#define INDEX_NOISEMAKER_WITCH      283
#define INDEX_NOISEMAKER_WEREWOLF   282
#define INDEX_NOISEMAKER_GREMLIN    281
#define INDEX_NOISEMAKER_CAT        280
#define INDEX_DUEL                  241
#define INDEX_GIFT_BIG              234
#define INDEX_GIFT_SMALL            233
#define INDEX_DANGERSHIELD          231

#define INDEX_TOTAL                 12

/*new g_iIgnore[INDEX_TOTAL] = {
INDEX_RAZORBACK,
INDEX_GUNBOATS,
INDEX_NOISEMAKER_CRAZY,
INDEX_NOISEMAKER_BANSHEE,
INDEX_NOISEMAKER_WITCH,
INDEX_NOISEMAKER_WEREWOLF,
INDEX_NOISEMAKER_GREMLIN,
INDEX_NOISEMAKER_CAT,
INDEX_DUEL,
INDEX_GIFT_BIG,
INDEX_GIFT_SMALL,
INDEX_DANGERSHIELD
};*/

new Handle:g_Cvar_Alltalk = INVALID_HANDLE;	
new bool:nameChanged[MAXPLAYERS+1] = false;

public Plugin:myinfo = {
    name        = "Freeber Sanctions",
    author      = "Crazydog",
    description = "Adds various sanctions to Free TF2 Players",
    version     = PLUGIN_VERSION,
    url         = "http://theelders.net/"
};

public OnPluginStart()
{
    //Version CVAR
    CreateConVar("sm_frbr_version", PLUGIN_VERSION, "FreePremiumRenamer Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    //Freeber renaming CVARS --- DONE --- TESTED
    CreateConVar("sm_frbr_rename_enable", "0", "Enable freeber renaming", _, true, 0.0, true, 1.0);
    CreateConVar("sm_frbr_ftag", "[F]", "Name Tag for Free users");
    //CreateConVar("sm_frbr_ptag", "[P]", "Name Tag for Premium users");
    CreateConVar("sm_frbr_position", "1", "Where should the tag be? 0=front 1=back", _, true, 0.0, true, 1.0);
    CreateConVar("sm_frbr_truncate", "0", "Truncate a client's name if it is too long with the tag", _, true, 0.0, true, 1.0);
    CreateConVar("sm_frbr_rename_chatonly", "0", "Only rename freebers in chat", _, true, 0.0, true, 1.0);
    
    //Chat/Voice blocking for Freebers CVARS --- DONE --- TESTED
    CreateConVar("sm_frbr_gag_enable", "0", "Enable freeber gagging", _, true, 0.0, true, 1.0);
    CreateConVar("sm_frbr_mute_enable", "0", "Enable freeber muting", _, true, 0.0, true, 1.0);
    
    //Taunt Blocking --- DONE --- TESTED
    CreateConVar("sm_frbr_tauntblock_enable", "0", "Enable freeber taunt blocking", _, true, 0.0, true, 1.0);
    
    //Hat blocking --- NOT DONE --- NOT TESTED
    //CreateConVar("sm_frbr_strip_enable", "0", "Enable stripping of hats from freebers", _, true, 0.0, true, 1.0);
    
    //Non-stock weapon blocking --- NOT DONE --- NOT TESTED
    //CreateConVar("sm_frbr_stripweapon_enable", "0", "Enable stripping of non-stock weapons from freebers", _, true, 0.0, true, 1.0);
    
    //Freeber kicking --- DONE --- TESTED
    CreateConVar("sm_frbr_kick_enable", "0", "Simply kicks all freebers", _, true, 0.0, true, 1.0);
    
    //Spray blocking --- DONE --- TESTED
    CreateConVar("sm_frbr_sprayblock_enable", "0", "Prevent freebers from being able to spray", _, true, 0.0, true, 1.0);
    
    //Random team + class --- DONE --- NOT TESTED
    CreateConVar("sm_frbr_forceteam_enable", "0", "Force freebers to a team on connection", _, true, 0.0, true, 1.0);
    CreateConVar("sm_frbr_forceclass_enable", "0", "Force freebers to a random class on join", _, true, 0.0, true, 1.0);
    
    //Admin command to send message to freebers --- DONE --- TESTED
    RegAdminCmd("sm_frbr_say", Command_TalkToFreebers, ADMFLAG_CHAT, "Send a chat message to all freebers");
    
    
    //Hook for name changes
    HookEvent("player_changename", Event_ChangeName, EventHookMode_Pre);
    
    //Registers for gagging/muting
    g_Cvar_Alltalk = FindConVar("sv_alltalk");
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_TeamSay);
    HookConVarChange(g_Cvar_Alltalk, ConVarChange_Alltalk);
    HookEvent("player_spawn", Event_PlayerSpawnOrDie, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerSpawnOrDie, EventHookMode_Post);
    
    //Register for taunt blocking --- DONE --- NOT TESTED
    RegConsoleCmd("taunt", TauntAction);
    
    //TempEntHook for spray blocking
    AddTempEntHook("Player Decal", OnClientSpray);
    
    //Hooks for removing hats
    //HookEvent("post_inventory_application", EventRemoveHats);
    //HookEvent("player_spawn", EventRemoveHats);
    
    //SetupSDK();
    
    AutoExecConfig(true, "plugin.freebersanction");
}


//Handles renaming and kicking
public OnClientPostAdminCheck(client){
    SetClientListeningFlags(client, VOICE_NORMAL);
    nameChanged[client] = false;
    if(IsFreeber(client)){
        //Do we kick freebers? If not, do we rename them?
        if(GetConVarInt(FindConVar("sm_frbr_kick_enable")) == 1){
            KickClient(client, "You need a Premium TF2 account to play on this server");
        }else{
            if(GetConVarInt(FindConVar("sm_frbr_rename_enable")) == 1 && GetConVarInt(FindConVar("sm_frbr_rename_chatonly")) == 0) RenameFreeber(client, "");
            if(GetConVarInt(FindConVar("sm_frbr_mute_enable")) == 1 && IsFreeber(client)) SetClientListeningFlags(client, VOICE_MUTED);
        }
    }
}

//Handles automatic team + class selection
public OnClientPutInServer(client){
    if(GetConVarInt(FindConVar("sm_frbr_forceteam_enable")) == 1){
        new random = GetRandomInt(2, 3);
        ChangeClientTeam(client, random);
    }
    if(GetConVarInt(FindConVar("sm_frbr_forceclass_enable")) == 1){
        new TFClassType:random = TFClassType:GetRandomInt(1, 9);
        TF2_SetPlayerClass(client, random);
    }
}

//Handle player renaming
public Action:Event_ChangeName(Handle:event, const String:name[], bool:dontBroadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsFreeber(client)){
        if (nameChanged[client]){
            nameChanged[client] = false;
            return Plugin_Handled;
        }
        new String:newName[MAX_NAME_LENGTH];
        GetEventString(event, "newname", newName, sizeof(newName));
        if(GetConVarInt(FindConVar("sm_frbr_rename_enable")) == 1 && GetConVarInt(FindConVar("sm_frbr_rename_chatonly")) == 0){
            new Handle:pack;
            CreateDataTimer(15.0, Timer_Rename, pack, TIMER_FLAG_NO_MAPCHANGE);
            WritePackString(pack, newName);
            WritePackCell(pack, client);
            //RenameFreeber(client, newName);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

//Handle chat - either gag or add tag, or say normally.
public Action:Command_Say(client, args){
    if (client)
    {
        if(IsFreeber(client)){
            if (GetConVarInt(FindConVar("sm_frbr_gag_enable")) == 1) return Plugin_Handled;
            new String:name[MAX_NAME_LENGTH];
            GetClientName(client, name, sizeof(name));
            new team = GetClientTeam(client);
            if (GetConVarInt(FindConVar("sm_frbr_rename_chatonly")) == 1){
                new String:chat[192];
                GetCmdArgString(chat, sizeof(chat));
                new String:ftag[32];
                new tagPos = GetConVarInt(FindConVar("sm_frbr_position"));
                GetConVarString(FindConVar("sm_frbr_ftag"), ftag, sizeof(ftag));
                Format(chat, strlen(chat)-1, "%s", chat[1]);
                if(IsPlayerAlive(client)){
                    if(tagPos == 1){
                        CPrintToChatAllEx(client, "{teamcolor}%s %s{default} :  %s", name, ftag, chat);
                    }else{
                        CPrintToChatAllEx(client, "{teamcolor}%s %s{default} :  %s", ftag, name, chat);
                    }
                }else{
                    if(team == 0 || team == 1){
                            for (new i = 1; i <= MaxClients; i++){
                                if(IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i)){
                                    if(tagPos == 1){
                                        CPrintToChatEx(i, client, "{default}*SPEC* {teamcolor}%s %s{default} :  %s", name, ftag, chat);
                                    }else{
                                        CPrintToChatEx(i, client, "{default}*SPEC* {teamcolor}%s %s{default} :  %s", ftag, name, chat);
                                    }
                                }
                            }
                    }else{
                        for (new i = 1; i <= MaxClients; i++){
                            if(IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i)){
                                if(tagPos == 1){
                                    CPrintToChatEx(i, client, "{default}*DEAD* {teamcolor}%s %s{default} :  %s", name, ftag, chat);
                                }else{
                                    CPrintToChatEx(i, client, "{default}*DEAD* {teamcolor}%s %s{default} :  %s", ftag, name, chat);
                                }
                            }
                        }
                    }
                }
                return Plugin_Handled;
            }
        }
    }
    
    return Plugin_Continue;
}

//Handle team chat - either gag or add tag or say normally.
public Action:Command_TeamSay(client, args){
    if (client)
    {
        if(IsFreeber(client)){
            if (GetConVarInt(FindConVar("sm_frbr_gag_enable")) == 1) return Plugin_Handled;
            new String:name[MAX_NAME_LENGTH];
            GetClientName(client, name, sizeof(name));
            new team = GetClientTeam(client);
            if (GetConVarInt(FindConVar("sm_frbr_rename_chatonly")) == 1){
                new String:chat[192];
                GetCmdArgString(chat, sizeof(chat));
                new String:ftag[32];
                GetConVarString(FindConVar("sm_frbr_ftag"), ftag, sizeof(ftag));
                new tagPos = GetConVarInt(FindConVar("sm_frbr_position"));
                Format(chat, strlen(chat)-1, "%s", chat[1]);
                if(IsPlayerAlive(client)){
                    for (new i = 1; i <= MaxClients; i++){
                        if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team){
                            if(tagPos == 1){
                                CPrintToChatEx(i, client,  "{default}(TEAM) {teamcolor}%s %s{default} :  %s", name, ftag, chat);
                            }else{
                                CPrintToChatEx(i, client,  "{default}(TEAM) {teamcolor}%s %s{default} :  %s", ftag, name, chat);	
                            }
                        }
                    }
                }else{
                    if(team == 0 || team == 1){
                        for (new i = 1; i <= MaxClients; i++){
                            if(IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i)){
                                if(tagPos == 1){
                                    CPrintToChatEx(i, client, "{default}(Spectator) {teamcolor}%s %s{default} :  %s", name, ftag, chat);
                                }else{
                                    CPrintToChatEx(i, client, "{default}(Spectator) {teamcolor}%s %s{default} :  %s", ftag, name, chat);
                                }
                            }
                        }
                    }else{
                        for (new i = 1; i <= MaxClients; i++){
                            if(IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && GetClientTeam(i) == team){
                                if(tagPos == 1){
                                    CPrintToChatEx(i, client, "{default}*DEAD*(TEAM) {teamcolor}%s %s{default} :  %s", name, ftag, chat);
                                }else{
                                    CPrintToChatEx(i, client, "{default}*DEAD*(TEAM) {teamcolor}%s %s{default} :  %s", ftag, name, chat);
                                }
                            }
                        }
                    }
                }
                return Plugin_Handled;
            }
        }
    }
    
    return Plugin_Continue;
}

//Send a message to all free clients
public Action:Command_TalkToFreebers(client, args){
    new String:name[MAX_NAME_LENGTH];
    new String:chat[192];
    GetCmdArgString(chat, sizeof(chat));
    GetClientName(client, name, sizeof(name));
    for (new i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && !IsFakeClient(i) && IsFreeber(i)){
            PrintToChat(i, "\x04[FreeChat]\x03 %s\x01 :  %s", name, chat);
        }
    }
}

//Handler to block taunting
public Action:TauntAction(client, args){
    if(GetConVarInt(FindConVar("sm_frbr_tauntblock_enable")) == 1){
        if(IsFreeber(client)){
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

//Block sprays for clients
public Action:OnClientSpray(const String:te_name[], const clients[], client_count, Float:delay){
    new client = TE_ReadNum("m_nPlayer");
    if(GetConVarInt(FindConVar("sm_frbr_sprayblock_enable")) == 1){
        if(client && IsClientInGame(client))
        {		
            if (!IsClientAuthorized(client) || IsFakeClient(client)) return Plugin_Handled;
            if (IsFreeber(client)) return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

//Keep freebers muted when various actions occur

    //Alltalk change
public ConVarChange_Alltalk(Handle:convar, const String:oldValue[], const String:newValue[]){
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))	continue;
        
        if (GetConVarInt(FindConVar("sm_frbr_mute_enable")) && IsFreeber(i)) SetClientListeningFlags(i, VOICE_MUTED);
    }
}

    //Respawn + Death
public Event_PlayerSpawnOrDie(Handle:event, const String:name[], bool:dontBroadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client) return;	
    if (GetConVarInt(FindConVar("sm_frbr_mute_enable")) && IsFreeber(client)) SetClientListeningFlags(client, VOICE_MUTED);
}

//Check if they're a freeber. I check always instead of on connection, as freeber
//status could change while they're in the server (buying something from the store, etc.)
public bool:IsFreeber(client){
    new String:steamID[256];
    GetClientAuthString(client, steamID, sizeof(steamID));
    if(strcmp(steamID, "STEAM_0:0:1654401") == 0){
        return true;
    }
    /*if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459)){
        return true;
    }*/
    return false;
}

//Hat remover - Thanks Mecha "http://forums.alliedmods.net/showthread.php?p=1365058"
/*public EventRemoveHats(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));    
    if(GetConVarInt(FindConVar("sm_frbr_strip_enable")) == 1 && IsFreeber(client)){
        RemoveHeadgear(client);
        CreateTimer(0.1, TimerRemoveHeadgear, client);
    }
}

public Action:TimerRemoveHeadgear(Handle:hTimer, any:iClient) {
    RemoveHeadgear(iClient);
}

RemoveHeadgear(iClient) {
    if(!IsClientInGame(iClient) || IsFakeClient(iClient)) return;
    
    new iEntity = -1;
    while ((iEntity = FindEntityByClassname(iEntity, "tf_wearable_item")) != -1) {
        if (IsItemEntity(iEntity)) {
            new iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
            if (iOwner == iClient) {
                    RemoveItemEntity(iClient, iEntity);
            }
        }
    } 
}

stock RemoveItemEntity(iClient, iEntity) {
    if (IsItemEntity(iEntity)) {
        if (GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient) {
            SDKCall(g_hSdkRemoveWearable, iClient, iEntity);
        }
        RemoveEdict(iEntity);
    }
}

stock SetupSDK() {
    new Handle:hGameConf = LoadGameConfigFile("mechatheslag_global");
    if (hGameConf != INVALID_HANDLE) {        
        // Remove Wearable
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual,"RemoveWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkRemoveWearable = EndPrepSDKCall();
        
        CloseHandle(hGameConf);
    } else {
        SetFailState("Couldn't load SDK functions.");
    }
}

stock bool:IsItemEntity(iEntity) {
    if (iEntity > 0) {
        if (IsValidEdict(iEntity)) {
            decl String:strClassname[32];
            GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
            if (StrEqual(strClassname, "tf_wearable_item", false)) {
                new iIndex = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
                
                for (new iLoop = 0; iLoop < sizeof(g_iIgnore); iLoop++) {
                    if (g_iIgnore[iLoop] == iIndex) return false;
                }
                
                return true;
            }
        }
    }
    return false;
}*/

public RenameFreeber(client, String:changedName[31]){
    if (IsFreeber(client)){
        //Should we rename the client
        if(GetConVarInt(FindConVar("sm_frbr_rename_enable")) == 1){
            new String:name[MAX_NAME_LENGTH], String:newName[MAX_NAME_LENGTH], String:ftag[31];//, String:ptag[31];
            
            //Get the client's name and the tags
            if(strcmp(changedName, "") == 0){
                GetClientName(client, name, sizeof(name));
            }else{
                name = changedName;
            }
            GetConVarString(FindConVar("sm_frbr_ftag"), ftag, sizeof(ftag));
            //GetConVarString(FindConVar("sm_fpr_ptag"), ptag, sizeof(ptag));
                
                
            new position = GetConVarInt(FindConVar("sm_frbr_position"));
            //Truncate the client's name if sm_frbr_truncate = 1
            if(GetConVarInt(FindConVar("sm_frbr_truncate")) == 1){
                if(strlen(name) + strlen(ftag) > 31){
                    if(position == 1){
                        strcopy(name, 31-(strlen(ftag)), name);
                    }else{
                        strcopy(name, 30-(strlen(ftag)), name);
                    }
                }
            }
                        
            //Position the tag properly
            if(position == 1){
                Format(newName, sizeof(newName), "%s %s", name, ftag);
            }else{
                Format(newName, sizeof(newName), "%s %s", ftag, name);
            }
            LogError("setting client info");
            SetClientInfo(client, "name", newName);
            LogError("Set client info");
            nameChanged[client] = true;
            /*else{
                if(position == 1){
                    Format(newName, sizeof(newName), "%s %s", name, ptag);
                }else{
                    Format(newName, sizeof(newName), "%s %s", ptag, name);
                }
            }*/
        }
    }	
}

public Action:Timer_Rename(Handle:timer, Handle:pack)
{
	new String:newname[MAX_NAME_LENGTH];
	ResetPack(pack);
	ReadPackString(pack, newname, sizeof(newname));
	new client = (ReadPackCell(pack));
	
	if (client != 0)
	{
		RenameFreeber(client, newname);
	}
		
	return Plugin_Stop;
}