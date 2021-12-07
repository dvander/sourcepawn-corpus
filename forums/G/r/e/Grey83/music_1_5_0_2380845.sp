#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <clientprefs>
#include <csgocolors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5.0"
#define PLUGIN_NAME "[CS:GO] Music Kits [Menu]"
#define UPDATE_URL ""

new Music_choice[MAXPLAYERS+1] = {1,...};
new Handle:g_cookieMusic;

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = "iEx",
    description = "Allow to choose any music kit",
    version = PLUGIN_VERSION,
    url = "http://www.redstar-servers.com/",
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("music.phrases");

    g_cookieMusic = RegClientCookie("Music_choice", "", CookieAccess_Private);

    HookEvent("player_spawn", Event_Player_Spawn, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_Disc);
    RegConsoleCmd("sm_music", Music, "Set Music in Game.");

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
        {
            OnClientCookiesCached(i);
        }
    }
}

public OnClientCookiesCached(client)
{
    new String:value[16];
    GetClientCookie(client, g_cookieMusic, value, sizeof(value));
    if(strlen(value) > 0) Music_choice[client] = StringToInt(value);

    if (!(0 < client <= MaxClients)) return;
    if (!IsClientInGame(client)) return;
    if( IsFakeClient(client) ) return;
    if(Music_choice[client] != 1)
    {
        EquipMusic(client);
    }
}

public OnClientPostAdminCheck(client)
{
    CreateTimer(15.0, Timer_WelcomeMessage, client);
}

public Action:Timer_WelcomeMessage(Handle:timer, any:client)
{
	if (!(0 < client <= MaxClients)) return;
	if ( !IsClientInGame(client) ) return;
	if( IsFakeClient(client) ) return;
	CPrintToChat(client, "%t", "Welcome Message");
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!(0 < client <= MaxClients)) return;
	if ( !IsClientInGame(client) ) return;
	if( IsFakeClient(client) ) return;
	if(Music_choice[client] != 1)
    {
        EquipMusic(client);
    }
}

public Action:Event_Disc(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(client)
    {
        Music_choice[client] = 1;
    }
}

public Action:Music(client, args)
{
	if ( IsClientInGame(client) )
	{
        decl String: Default[32];
        decl String: Assault[32];
        decl String: Sharpened[32];
        decl String: Insurgency[32];
        decl String: AD8[32];
        decl String: HighNoon[32];
        decl String: HeadDemolition[32];
        decl String: DesertFire[32];
        decl String: LNOE[32];
        decl String: Metal[32];
        decl String: Midnight[32];
        decl String: IsoRhythm[32];
        decl String: ForNoMankind[32];
        decl String: HotlineMiami[32];
        decl String: TotalDomination[32];
        decl String: TheTalosPrincipal[32];


        Format(Default, sizeof(Default), "%t", "Music Menu Default");
        Format(Assault, sizeof(Assault), "%t", "Music Menu Assault");
        Format(Sharpened, sizeof(Sharpened), "%t", "Music Menu Sharpened");
        Format(Insurgency, sizeof(Insurgency), "%t", "Music Menu Insurgency");
        Format(AD8, sizeof(AD8), "%t", "Music Menu AD8");
        Format(HighNoon, sizeof(HighNoon), "%t", "Music Menu HighNoon");
        Format(HeadDemolition, sizeof(HeadDemolition), "%t", "Music Menu HeadDemolition");
        Format(DesertFire, sizeof(DesertFire), "%t", "Music Menu DesertFire");
        Format(LNOE, sizeof(LNOE), "%t", "Music Menu LNOE");
        Format(Metal, sizeof(Metal), "%t", "Music Menu Metal");
        Format(Midnight, sizeof(Midnight), "%t", "Music Menu Midnight");
        Format(IsoRhythm, sizeof(IsoRhythm), "%t", "Music Menu IsoRhythm");
        Format(ForNoMankind, sizeof(ForNoMankind), "%t", "Music Menu ForNoMankind");
        Format(HotlineMiami, sizeof(HotlineMiami), "%t", "Music Menu HotlineMiami");
        Format(TotalDomination, sizeof(TotalDomination), "%t", "Music Menu TotalDomination");
        Format(TheTalosPrincipal, sizeof(TheTalosPrincipal), "%t", "Music Menu TheTalosPrincipal");

        new Handle:menu = CreateMenu(MusicHandler);
        SetMenuTitle(menu, "%t", "Music Menu Title");
        AddMenuItem(menu, "1", Default);
        AddMenuItem(menu, "3", Assault);
        AddMenuItem(menu, "4", Sharpened);
        AddMenuItem(menu, "5", Insurgency);
        AddMenuItem(menu, "6", AD8);
        AddMenuItem(menu, "7", HighNoon);
        AddMenuItem(menu, "8", HeadDemolition);
        AddMenuItem(menu, "9", DesertFire);
        AddMenuItem(menu, "10", LNOE);
        AddMenuItem(menu, "11", Metal);
        AddMenuItem(menu, "12", Midnight);
        AddMenuItem(menu, "13", IsoRhythm);
        AddMenuItem(menu, "14", ForNoMankind);
        AddMenuItem(menu, "15", HotlineMiami);
        AddMenuItem(menu, "16", TotalDomination);
        AddMenuItem(menu, "17", TheTalosPrincipal);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, 20);
	}
	return Plugin_Handled;
}

public MusicHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            new String:info[4];
            GetMenuItem(menu, itemNum, info, sizeof(info));
            SetMusic(client, StringToInt(info));
            switch(Music_choice[client])
            {
                case 3:CPrintToChat(client, " %t","Choose Assault");
                case 4:CPrintToChat(client, " %t","Choose Sharpened");
                case 5:CPrintToChat(client, " %t","Choose Insurgency");
                case 6:CPrintToChat(client, " %t","Choose AD8");
                case 7:CPrintToChat(client, " %t","Choose HighNoon");
                case 8:CPrintToChat(client, " %t","Choose HeadDemolition");
                case 9:CPrintToChat(client, " %t","Choose DesertFire");
                case 10:CPrintToChat(client, " %t","Choose LNOE");
                case 11:CPrintToChat(client, " %t","Choose Metal");
                case 12:CPrintToChat(client, " %t","Choose Midnight");
                case 13:CPrintToChat(client, " %t","Choose IsoRhythm");
                case 14:CPrintToChat(client, " %t","Choose ForNoMankind");
                case 15:CPrintToChat(client, " %t","Choose HotlineMiami");
                case 16:CPrintToChat(client, " %t","Choose TotalDomination");
                case 17:CPrintToChat(client, " %t","Choose TheTalosPrincipal");
                default: CPrintToChat(client, " %t","Choose Default");
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}

EquipMusic(client)
{
    if (Music_choice[client] < 0 || Music_choice[client] > 17 || Music_choice[client] == 2)
        Music_choice[client] = 1;
    if( !GetEntProp(client, Prop_Send, "m_unMusicID") ) return;
    SetEntProp(client, Prop_Send, "m_unMusicID", Music_choice[client]);
}

SetMusic(client, index=1)
{
    Music_choice[client] = index;
    EquipMusic(client);
    decl String:strID[4];
    IntToString(index, strID, sizeof(strID));
    SetClientCookie(client, g_cookieMusic, strID);
}