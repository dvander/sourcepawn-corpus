/*
* Gives those donators the recognition they deserve :)
*
* Changelog:
*
* v0.3 - release
* v0.4 - Enable/ disable in donator > sprite menu/ proper error without interface
* v0.05 - Expanded to support multiple sprites/ fixed SetParent error
* v0.06 - Fixed minor errors
*
*/

#include <sourcemod>
#include <sdktools>
#include <donator>
#include <clientprefs>

#pragma semicolon 1

#define PLUGIN_VERSION "0.6"

//Increase this number to add more sprites below
#define TOTAL_SPRITE_FILES 2



new const String:szSpriteNames[TOTAL_SPRITE_FILES][] =
{
"Money Sign",
"Money Sign / Cloud"
};

//NOTE: Path to the filename ONLY (vtf/vmt added in plugin)
new const String:szSpriteFiles[TOTAL_SPRITE_FILES][] =
{
"materials/custom/$",
"materials/custom/donator"
};

enum _:tColors
{
tColor_Black,
tColor_White,
tColor_Orange,
tColor_Yellow,
tColor_Green,
tColor_Blue,
tColor_Red,
tColor_Lime,
tColor_Aqua,
tColor_Grey,
tColor_Purple,
tColor_Max
}

new const String:szColorValues[tColor_Max][] =
{
"0 0 0", "255 255 255", "255 102 0",
"255 255 0", "0 128 0", "0 0 255",
"255 0 0", "0 255 0", "0 255 255",
"128 128 128", "128 0 128"
};

new const String:szColorNames[tColor_Max][] =
{
"Black", "White", "Orange",
"Yellow", "Green", "Blue",
"Red", "Lime", "Aqua",
"Grey", "Purple"
};

new g_iEntList[MAXPLAYERS + 1];
new g_bIsDonator[MAXPLAYERS + 1];
new bool:g_bRoundEnded;
new Handle:g_hHudSync = INVALID_HANDLE;
new Handle:g_hTagColorCookie = INVALID_HANDLE;
new Handle:g_hSpriteShowCookie = INVALID_HANDLE;

new g_iTagColor[MAXPLAYERS + 1][4];
new g_iShowSprite[MAXPLAYERS + 1];
new g_vVelocityOffset;
new String:g_szSpriteOverride[MAXPLAYERS + 1][128];

public Plugin:myinfo =
{
name = "Donator Recognition",
author = "Nut",
description = "Give donators the recognition they deserve.",
version = PLUGIN_VERSION,
url = "http://www.lolsup.com/tf2"
}

public OnPluginStart()
{
CreateConVar("basicdonator_recog_v", PLUGIN_VERSION, "Donator Recognition Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

HookEventEx("teamplay_round_start", hook_Start, EventHookMode_PostNoCopy);
HookEventEx("arena_round_start", hook_Start, EventHookMode_PostNoCopy);
HookEventEx("teamplay_round_win", hook_Win, EventHookMode_PostNoCopy);
HookEventEx("arena_win_panel", hook_Win, EventHookMode_PostNoCopy);
HookEventEx("player_death", event_player_death, EventHookMode_Post);

g_hHudSync = CreateHudSynchronizer();
g_hTagColorCookie = RegClientCookie("donator_tagcolor", "Chat color for donators.", CookieAccess_Private);
g_hSpriteShowCookie = RegClientCookie("donator_spriteshow", "Which donator sprite to show.", CookieAccess_Private);

AddCommandListener(SayCallback, "donator_tag");
AddCommandListener(SayCallback, "donator_tagcolor");

g_vVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}

public OnAllPluginsLoaded()
{
if(!LibraryExists("donator.core")) SetFailState("Unabled to find plugin: Basic Donator Interface");
Donator_RegisterMenuItem("Set Donator Tag", ChangeTagCallback);
Donator_RegisterMenuItem("Change Tag Color", ChangeTagColorCallback);
Donator_RegisterMenuItem("Change Sprite", SpriteControlCallback);
}

public OnMapStart()
{
decl String:szBuffer[128];
for (new i = 0; i < TOTAL_SPRITE_FILES; i++)
{
FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", szSpriteFiles[i]);
PrecacheGeneric(szBuffer, true);
AddFileToDownloadsTable(szBuffer);
FormatEx(szBuffer, sizeof(szBuffer), "%s.vtf", szSpriteFiles[i]);
PrecacheGeneric(szBuffer, true);
AddFileToDownloadsTable(szBuffer);
}
}

public OnPostDonatorCheck(iClient)
{
if (!IsPlayerDonator(iClient)) return;

g_bIsDonator[iClient] = true;
g_iShowSprite[iClient] = 1;
g_iTagColor[iClient] = {255, 255, 255, 255};

new String:szBuffer[256];
if (AreClientCookiesCached(iClient))
{
GetClientCookie(iClient, g_hTagColorCookie, szBuffer, sizeof(szBuffer));
if (strlen(szBuffer) > 0)
{
decl String:szTemp[3][16];
ExplodeString(szBuffer, " ", szTemp, 3, sizeof(szTemp[]));
g_iTagColor[iClient][0] = StringToInt(szTemp[0]);
g_iTagColor[iClient][1] = StringToInt(szTemp[1]);
g_iTagColor[iClient][2] = StringToInt(szTemp[2]);
}

GetClientCookie(iClient, g_hSpriteShowCookie, szBuffer, sizeof(szBuffer));
if (strlen(szBuffer) > 0)
g_iShowSprite[iClient] = StringToInt(szBuffer);
}

GetDonatorMessage(iClient, szBuffer, sizeof(szBuffer));
ShowDonatorMessage(iClient, szBuffer);
}

public OnClientDisconnect(iClient)
g_bIsDonator[iClient] = false;

public Action:SayCallback(iClient, const String:command[], argc)
{
if(!iClient) return Plugin_Continue;
if (!g_bIsDonator[iClient]) return Plugin_Continue;

decl String:szArg[255];
GetCmdArgString(szArg, sizeof(szArg));

StripQuotes(szArg);
TrimString(szArg);

if (StrEqual(command, "donator_tag", true))
{
decl String:szTemp[256];
if (strlen(szArg) < 1)
{
GetDonatorMessage(iClient, szTemp, sizeof(szTemp));
ReplyToCommand(iClient, "[SM] Your current tag is: %s", szTemp);
}
else
{
PrintToChat(iClient, "\x01[SM] You have sucessfully changed your tag to: \x04%s\x01", szArg);
SetDonatorMessage(iClient, szArg);
}
}
else if (StrEqual(command, "donator_tagcolor", true))
{
decl String:szTemp[3][16];
if (strlen(szArg) < 1)
{
GetClientCookie(iClient, g_hTagColorCookie, szTemp[0], sizeof(szTemp[]));
ReplyToCommand(iClient, "[SM] Your current tag color is: %s", szTemp[0]);
}
else
{
ExplodeString(szArg, " ", szTemp, 3, sizeof(szTemp[]));
ReplyToCommand(iClient, "[SM] You have sucessfully changed your color to %s", szArg);
SetClientCookie(iClient, g_hTagColorCookie, szArg);
}
}
return Plugin_Handled;
}

public ShowDonatorMessage(iClient, String:message[])
{
SetHudTextParamsEx(-1.0, 0.22, 4.0, g_iTagColor[iClient], {0, 0, 0, 255}, 1, 5.0, 0.15, 0.15);
for(new i = 1; i <= MaxClients; i++)
if(IsClientInGame(i) && !IsFakeClient(i))
ShowSyncHudText(i, g_hHudSync, message);
}

public hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
for(new i = 1; i <= MaxClients; i++)
{
if (!IsClientInGame(i)) continue;
if (!g_bIsDonator[i]) continue;
KillSprite(i);
}
g_bRoundEnded = false;
}

public hook_Win(Handle:event, const String:name[], bool:dontBroadcast)
{
decl String:szBuffer[128];
for(new i = 1; i <= MaxClients; i++)
{
if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientObserver(i)) continue;
if (!g_bIsDonator[i]) continue;

if (g_iShowSprite[i] > 0)
{
if (strlen(g_szSpriteOverride[i]) > 1)
FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", g_szSpriteOverride[i]);
else
{
if (g_iShowSprite[i] > TOTAL_SPRITE_FILES) g_iShowSprite[i] = TOTAL_SPRITE_FILES - 1;
FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", szSpriteFiles[g_iShowSprite[i]-1]);
}
CreateSprite(i, szBuffer, 25.0);
}
}
g_bRoundEnded = true;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
if(!g_bRoundEnded) return Plugin_Continue;
KillSprite(GetClientOfUserId(GetEventInt(event, "userid")));
return Plugin_Continue;
}

public DonatorMenu:ChangeTagCallback(iClient) Panel_ChangeTag(iClient);
public DonatorMenu:ChangeTagColorCallback(iClient) Panel_ChangeTagColor(iClient);
public DonatorMenu:SpriteControlCallback(iClient) Panel_SpriteControl(iClient);

public Action:Panel_ChangeTag(iClient)
{
new Handle:panel = CreatePanel();
SetPanelTitle(panel, "Donator: Change Tag:");

new String:szBuffer[256];
GetDonatorMessage(iClient, szBuffer, sizeof(szBuffer));
DrawPanelItem(panel, "Your current donator tag is:", ITEMDRAW_DEFAULT);
DrawPanelItem(panel, szBuffer, ITEMDRAW_RAWLINE);
DrawPanelItem(panel, "space", ITEMDRAW_SPACER);
DrawPanelItem(panel, "Type the following in the console to change your tag:", ITEMDRAW_CONTROL);
DrawPanelItem(panel, "donator_tag \"YOUR TAG GOES HERE\"", ITEMDRAW_RAWLINE);

SendPanelToClient(panel, iClient, PanelHandlerBlank, 20);
CloseHandle(panel);
}

public Action:Panel_ChangeTagColor(iClient)
{
new Handle:menu = CreateMenu(TagColorMenuSelected);
SetMenuTitle(menu,"Donator: Change Tag Color:");

decl String:szBuffer[256];
FormatEx(szBuffer, sizeof(szBuffer), "%i %i %i", g_iTagColor[iClient][0], g_iTagColor[iClient][1], g_iTagColor[iClient][2]);

decl String:szItem[4];
for (new i = 0; i < tColor_Max; i++)
{
FormatEx(szItem, sizeof(szItem), "%i", i);
if (StrEqual(szBuffer, szColorValues[i]))
AddMenuItem(menu, szItem, szColorNames[i], ITEMDRAW_DISABLED);
else
AddMenuItem(menu, szItem, szColorNames[i], ITEMDRAW_DEFAULT);
}
DisplayMenu(menu, iClient, 20);
}

public Action:Panel_SpriteControl(iClient)
{
new Handle:menu = CreateMenu(SpriteControlSelected);
SetMenuTitle(menu,"Donator: Sprite Control:");

if (g_iShowSprite[iClient] > 0)
AddMenuItem(menu, "0", "Disable Sprite", ITEMDRAW_DEFAULT);
else
AddMenuItem(menu, "0", "Disable Sprite", ITEMDRAW_DISABLED);

decl String:szItem[4];
for (new i = 0; i < TOTAL_SPRITE_FILES; i++)
{
FormatEx(szItem, sizeof(szItem), "%i", i+1); //need to offset the menu items by one since we added the enable / disable outside of the loop
if (g_iShowSprite[iClient]-1 != i)
AddMenuItem(menu, szItem, szSpriteNames[i], ITEMDRAW_DEFAULT);
else
AddMenuItem(menu, szItem, szSpriteNames[i], ITEMDRAW_DISABLED);
}
DisplayMenu(menu, iClient, 20);
}

public TagColorMenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
decl String:tmp[32], iSelected;
GetMenuItem(menu, param2, tmp, sizeof(tmp));
iSelected = StringToInt(tmp);

switch (action)
{
case MenuAction_Select:
{
decl String:szTmp[3][16], iColor[4];

ExplodeString(szColorValues[iSelected], " ", szTmp, 3, sizeof(szTmp[]));
iColor[0] = StringToInt(szTmp[0]);
iColor[1] = StringToInt(szTmp[1]);
iColor[2] = StringToInt(szTmp[2]);
iColor[3] = 255;

g_iTagColor[param1] = iColor;

SetHudTextParamsEx(-1.0, 0.22, 4.0, iColor, {0, 0, 0, 255}, 1, 5.0, 0.15, 0.15);
ShowSyncHudText(param1, g_hHudSync, "This is your new tag color.");
SetClientCookie(param1, g_hTagColorCookie, szColorValues[iSelected]);
}
case MenuAction_End: CloseHandle(menu);
}
}

public SpriteControlSelected(Handle:menu, MenuAction:action, param1, param2)
{
decl String:tmp[32], iSelected;
GetMenuItem(menu, param2, tmp, sizeof(tmp));
iSelected = StringToInt(tmp);

switch (action)
{
case MenuAction_Select:
{
g_iShowSprite[param1] = iSelected;
decl String:szSelected[2];
Format(szSelected, sizeof(szSelected), "%i", iSelected);
SetClientCookie(param1, g_hSpriteShowCookie, szSelected);
}
case MenuAction_End: CloseHandle(menu);
}
}

public PanelHandlerBlank(Handle:menu, MenuAction:action, iClient, param2) {}

//--------------------------------------------------------------------------------------------------

stock CreateSprite(iClient, String:sprite[], Float:offset)
{
new String:szTemp[64], Float:vOrigin[3];
Format(szTemp, sizeof(szTemp), "client%i", iClient);
DispatchKeyValue(iClient, "targetname", szTemp);

GetClientAbsOrigin(iClient, vOrigin);
vOrigin[2] += offset;

new ent = CreateEntityByName("env_sprite_oriented");
if (ent)
{
DispatchKeyValue(ent, "model", sprite);
DispatchKeyValue(ent, "classname", "env_sprite_oriented");
DispatchKeyValue(ent, "spawnflags", "1");
DispatchKeyValue(ent, "scale", "0.1");
DispatchKeyValue(ent, "rendermode", "1");
DispatchKeyValue(ent, "rendercolor", "255 255 255");
DispatchKeyValue(ent, "targetname", "donator_spr");
DispatchKeyValue(ent, "parentname", szTemp);
DispatchSpawn(ent);

TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);

g_iEntList[iClient] = ent;
}
}

stock KillSprite(iClient)
{
if (g_iEntList[iClient] > 0 && IsValidEntity(g_iEntList[iClient]))
{
AcceptEntityInput(g_iEntList[iClient], "kill");
g_iEntList[iClient] = 0;
}
}

public OnGameFrame()
{
if (!g_bRoundEnded) return;
decl ent, Float:vOrigin[3], Float:vVelocity[3];

for(new i = 1; i <= MaxClients; i++)
{
if (!IsClientInGame(i)) continue;
if ((ent = g_iEntList[i]) > 0)
{
if (!IsValidEntity(ent))
g_iEntList[i] = 0;
else
if ((ent = EntRefToEntIndex(ent)) > 0)
{
GetClientEyePosition(i, vOrigin);
vOrigin[2] += 25.0;
GetEntDataVector(i, g_vVelocityOffset, vVelocity);
TeleportEntity(ent, vOrigin, NULL_VECTOR, vVelocity);
}
}
}
}

/*
* Natives
*/
public Native_OverrideSprite(Handle:plugin, params)
{
new String:szSteamId[64], String:szSprite[128], iClient = GetNativeCell(1);

GetClientAuthString(iClient, szSteamId, sizeof(szSteamId));
GetNativeString(2, szSprite, sizeof(szSprite));

strcopy(g_szSpriteOverride[iClient], sizeof(g_szSpriteOverride[]), szSprite);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
RegPluginLibrary("donator.recognition.tf2");
CreateNative("SetClientSprite", Native_OverrideSprite);
return APLRes_Success;
}