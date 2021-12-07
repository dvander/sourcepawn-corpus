#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <clientprefs>
#include <csgocolors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2.0"
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

public OnPluginStart() {
	LoadTranslations("common.phrases");
	LoadTranslations("music.phrases");

	g_cookieMusic = RegClientCookie("Music_choice", "", CookieAccess_Private);

	HookEvent("player_disconnect", Event_Disc);
	RegAdminCmd("sm_music", Music, ADMFLAG_BAN,"Set Music in Game.");

	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
}

public OnMapStart() {
	CreateTimer(0.1, Timer_CheckMusic, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientCookiesCached(client) {
	new String:value[16];
	GetClientCookie(client, g_cookieMusic, value, sizeof(value));
	if(strlen(value) > 0) Music_choice[client] = StringToInt(value);
}

public OnClientPostAdminCheck(client) {
	CreateTimer(15.0, Timer_WelcomeMessage, GetClientUserId(client));
}

public Action:Timer_WelcomeMessage(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client)) {
		CPrintToChat(client, "%t", "Welcome Message");
	}
}

public OnClientPutInServer(client) {
	if(!IsFakeClient(client)) {
		EquipMusic(client);
	}
}

//In case you are wondering why on Event Disconnect, because it only fires when the player really leaves.
public Action:Event_Disc(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client) {
		Music_choice[client] = 1;
	}
}

public Action:Music(client, args) {
	if(IsClientInGame(client)) {
		decl String:formatedString[32];
		new Handle:menu = CreateMenu(MusicHandler);
		SetMenuTitle(menu, "%t", "Music Menu Title");
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu Default");
		AddMenuItem(menu, "1", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu Assault");
		AddMenuItem(menu, "3", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu Sharpened");
		AddMenuItem(menu, "4", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu Insurgency");
		AddMenuItem(menu, "5", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu ADB");
		AddMenuItem(menu, "6", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu HighNoon");
		AddMenuItem(menu, "7", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu HeadDemolition");
		AddMenuItem(menu, "8", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu DesertFire");
		AddMenuItem(menu, "9", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu LNDE");
		AddMenuItem(menu, "10", formatedString);
		Format(formatedString, sizeof(formatedString), "%t", "Music Menu Metal");
		AddMenuItem(menu, "11", formatedString);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
	return Plugin_Handled;
}

public MusicHandler(Handle:menu, MenuAction:action, client, itemNum) {
	switch(action) {
		case MenuAction_Select: {
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
				case 10:CPrintToChat(client, " %t","Choose LNDE");
				case 11:CPrintToChat(client, " %t","Choose Metal");
				default: CPrintToChat(client, " %t","Choose Default");
			}
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

EquipMusic(client) {
	if (Music_choice[client] < 0 || Music_choice[client] > 11 || Music_choice[client] == 2)
		Music_choice[client] = 1;
	SetEntProp(client, Prop_Send, "m_unMusicID", Music_choice[client]);
}

SetMusic(client, index=1) {
	Music_choice[client] = index;
	EquipMusic(client);
	decl String:strID[2];
	IntToString(index, strID, sizeof(strID));
	SetClientCookie(client, g_cookieMusic, strID);
}

public Action:Timer_CheckMusic(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++) {
		if(Music_choice[i] != 1) {
			if(IsClientInGame(i)) {
				SetEntProp(i, Prop_Send, "m_unMusicID",Music_choice[i]);
			}
		}
	}
}