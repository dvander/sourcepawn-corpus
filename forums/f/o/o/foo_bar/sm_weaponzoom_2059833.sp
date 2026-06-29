/*
 * sm_weaponzoom.sp: Weapon Zoom for HL2:DM and others (untested)
 * Thrown together by [foo] bar <foobarhl@gmail.com> | http://steamcommunity.com/id/foo-bar/ 
 *
 * Based on zoom.sp by Nargis.   Considerably tweaked by [foo] bar
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */


#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define VERSION "1.6c"

#define MAX_WEAPONS	10		// maximum weapons you can apply the zoom to.  

#define DFL_SOUND_ZOOMOUT "weapons/sniper/sniper_zoomout.wav"
#define DFL_SOUND_ZOOMIN "weapons/sniper/sniper_zoomin.wav"
#define DFL_SOUND_MINPLAY	30	// don't play ICU sound more than this many seconds to a player, from an individual attacker

#define DFL_ZOOM_MAX	4
#define DFL_ZOOM_INC	8
#define DFL_ZOOM_START	40

#define DFL_HELPFILE_URL "http://halflife.sixofour.tk/pluginhelp/sm_weaponzoom.html"

//	#define UNFAIR				// define UNFAIR if you want unfairness.  

enum EClientSetting
{
	bool:cfg_enabled,		// enable/disable
	bool:cfg_concmdonly,		// accept console command only (disable attack2)
	bool:cfg_icuvictim,		// hear icu sound if i'm zoomed in on
	cfg_maxzoom,			// player's maximum zoom (within bounds of sm_weaponzoom_maxzoom)
#if defined UNFAIR
	bool:cfg_icuattacker,		// emit icu sound if i zoom in on 
#endif
};



new Handle:cVarversion = INVALID_HANDLE;
new Handle:cVarWeapons = INVALID_HANDLE;
new Handle:cVarZoomoutSound = INVALID_HANDLE;
new Handle:cVarZoominSound = INVALID_HANDLE;
new Handle:cVarZoomMaxZoom = INVALID_HANDLE;
new Handle:cVarZoomIncrement = INVALID_HANDLE;
new Handle:cVarZoomStart = INVALID_HANDLE;
new Handle:cVarSoundICU = INVALID_HANDLE;
new Handle:cVarSoundICUMin = INVALID_HANDLE;
new Handle:cVarConsoleAllZoom = INVALID_HANDLE;
new Handle:cVarHelpUrl = INVALID_HANDLE;

#define COOKIE_ENABLED		"SMWZOOM-Enabled"
#define COOKIE_CONONLY		"SMHZOOM-ConCmdOnly"
#define COOKIE_ICU_VICPREF 	"SMWZOOM-ICU-VicPref"
#define COOKIE_ICU_ATTEMIT	"SMWZOOM-ICU-AttPref"
#define COOKIE_MAXZOOM		"SMWZOOM-MaxZoom"

new Handle:g_cookieEnable = INVALID_HANDLE;
new Handle:g_cookieConCmdOnly = INVALID_HANDLE;
new Handle:g_cookieICUVictim = INVALID_HANDLE;
new Handle:g_cookieMaxZoom = INVALID_HANDLE;
#if defined UNFAIR
new Handle:g_cookieICUAttacker = INVALID_HANDLE;
#endif

new bool:KeyBuffer[MAXPLAYERS+1];
new ZoomOn[MAXPLAYERS+1];
new currentWeapon[MAXPLAYERS+1];
new playerSettings[MAXPLAYERS+1][EClientSetting];

new zoomLevels[10];

new maxZoom = DFL_ZOOM_MAX;
new zoomIncrement = DFL_ZOOM_INC;
new zoomZoomStart = DFL_ZOOM_START;
new bool:consoleAllZoom = true;

new String:soundZoomout[255];
new String:soundZoomin[255];
new String:soundICU[255];
new soundICUMin = DFL_SOUND_MINPLAY;

new lastPlaySound[MAXPLAYERS+1][MAXPLAYERS+1];
new String:weapons[MAX_WEAPONS][20];

new String:helpFileUrl[255] = DFL_HELPFILE_URL;

#define MAX_ZOOM(%0)	( (playerSettings[%0][cfg_maxzoom] && playerSettings[%0][cfg_maxzoom] <= maxZoom) ? playerSettings[%0][cfg_maxzoom] : maxZoom)

public Plugin:myinfo = {
	name = "sm_weaponzoom",
	author = "[foo] bar",
	description = "[foo] bar's Weapon Zoom",
	version = VERSION,
	url = "http://github.com/foobarhl/sm_weaponzoom"
};

public OnPluginStart()
{
	cVarversion = CreateConVar("sm_weaponzoom_version", VERSION, "sm_weaponzoom version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(cVarversion, VERSION);

	cVarWeapons = CreateConVar("sm_weaponzoom_weapons", "weapon_357", "Weapons to put zoom on (attack2)");	

	cVarConsoleAllZoom = CreateConVar("sm_weaponzoom_cmdallzoom", "1", "Allow weaponzoom_in and weaponzoom_out on all weapons.  0 limits to weapons specified in sm_weapon_commands");
	HookConVarChange(cVarConsoleAllZoom, CvarChangedReloadConfig);

	cVarZoomoutSound = CreateConVar("sm_weaponzoom_zoomoutsound", DFL_SOUND_ZOOMOUT, "Sound to play when zooming out");
	cVarZoominSound = CreateConVar("sm_weaponzoom_zoominsound", DFL_SOUND_ZOOMIN, "Sound to play when zooming in");

	cVarZoomMaxZoom = CreateConVarInt("sm_weaponzoom_zoommax", DFL_ZOOM_MAX, "Maximum zoom");
	HookConVarChange(cVarZoomMaxZoom, CvarChangedReloadConfig);

	cVarZoomIncrement = CreateConVarInt("sm_weapon_zoomincrement", DFL_ZOOM_INC, "Zoom increment");
	HookConVarChange(cVarZoomIncrement, CvarChangedReloadConfig);

	cVarZoomStart = CreateConVarInt("sm_weapon_zoomstart", DFL_ZOOM_START, "Zoom Start");
	HookConVarChange(cVarZoomStart, CvarChangedReloadConfig);

	cVarSoundICU = CreateConVar("sm_weapon_icusound", "", "Sound to play to a target player when someone zooms in on them");
	HookConVarChange(cVarSoundICU, CvarChangedReloadConfig);

	cVarSoundICUMin = CreateConVarInt("sm_weapon_icusound_mintime", DFL_SOUND_MINPLAY, "Don't play ICU sound more than this many seconds to a player, from an individual attacker");	
	HookConVarChange(cVarSoundICUMin, CvarChangedReloadConfig);

	cVarHelpUrl = CreateConVar("sm_weaponzoom_helpurl", DFL_HELPFILE_URL, "Web Address of help file.  Set to nothing to disable help");
	HookConVarChange(cVarHelpUrl, CvarChangedReloadConfig);

	LoadTranslations("sm_weaponzoom.phrases");

	AutoExecConfig(true);
	
	HookEvent("player_spawn", Event_Spawn);
	RegAdminCmd("wepzoom", TestZoom, ADMFLAG_ROOT, "Test weapon zoom");	// admin debug command. root only

	AddCommandListener(Command_ZoomIn, "weaponzoom_in");
	AddCommandListener(Command_ZoomOut, "weaponzoom_out");
	AddCommandListener(Command_UnZoom, "weaponzoom_unzoom");

	AddCommandListener(DisableZoomFromToggleZoom, "toggle_zoom");	// doesn't seem to work (or work well on laggy servers)
	
	g_cookieEnable = RegClientCookie(COOKIE_ENABLED, "WeaponZoom: Enabled", CookieAccess_Private);
	g_cookieConCmdOnly = RegClientCookie(COOKIE_CONONLY, "WeaponZoom: Console commands only (disable attack2)", CookieAccess_Private);
	g_cookieICUVictim = RegClientCookie(COOKIE_ICU_VICPREF, "WeaponZoom: Hear ICU sound from players zooming in on you", CookieAccess_Private);
	g_cookieMaxZoom = RegClientCookie(COOKIE_MAXZOOM, "WeaponZoom: Set maximum zoom (within configured bounds)", CookieAccess_Private);
#if defined UNFAIR
	g_cookieICUAttacker = RegClientCookie(COOKIE_ICU_ATTEMIT, "WeaponZoom: Emit ICU sound to zoomed in on player", CookieAccess_Private);
#endif

	SetCookieMenuItem(PrefMenu, 0, "Weapon Zoom Settings");
	RegConsoleCmd("sm_weaponzoom", Command_ShowWeaponZoomMenu, "Show the weaponzoom menu");

}

public OnPluginEnd()
{
	RemoveCommandListener(Command_ZoomIn, "weaponzoom_in");
	RemoveCommandListener(Command_ZoomOut, "weaponzoom_out");
	RemoveCommandListener(Command_UnZoom, "weaponzoom_unzoom");

	RemoveCommandListener(DisableZoomFromToggleZoom, "toggle_zoom");
}

public OnConfigsExecuted()
{
	decl String:buffer[200];

	GetConVarString(cVarWeapons, buffer, sizeof(buffer));
	ExplodeString(buffer, " ", weapons, sizeof(weapons), sizeof(weapons[]));

	maxZoom = GetConVarInt(cVarZoomMaxZoom);
	if(maxZoom > sizeof(zoomLevels)){
		SetFailState("sm_weaponinfo only supports %d zoom levels, you have maxZoom levels set to %d", sizeof(zoomLevels), maxZoom);
	}
	GetConVarString(cVarZoomoutSound, soundZoomout, sizeof(soundZoomout));
	GetConVarString(cVarZoominSound, soundZoomin, sizeof(soundZoomin));
	zoomIncrement = GetConVarInt(cVarZoomIncrement);
	zoomZoomStart = GetConVarInt(cVarZoomStart);
	consoleAllZoom = GetConVarBool(cVarConsoleAllZoom);
	for(new i=0; i<sizeof(zoomLevels); i++){
		zoomLevels[i]=0;
	}
	for(new i=1; i <=  maxZoom; i++) {
		zoomLevels[i] = zoomZoomStart-(i*zoomIncrement);
		if(zoomLevels[i] <= 0 || zoomLevels[i] >= 90 ) {
			zoomLevels[i] = 0;
			break;
		}
	}

	MyAddSoundToDownloadsTable(soundZoomout);
	MyAddSoundToDownloadsTable(soundZoomin);

	GetConVarString(cVarSoundICU, soundICU, sizeof(soundICU));
	if(soundICU[0]!='\0'){
		MyAddSoundToDownloadsTable(soundICU);
	}

	soundICUMin = GetConVarInt(cVarSoundICUMin);
	
	GetConVarString(cVarHelpUrl, helpFileUrl, sizeof(helpFileUrl));

	for(new i=1; i<=MaxClients; i++){
		if(IsClientConnected(i)){
			LoadClientSettings(i);
		}
	}

}

public CvarChangedReloadConfig(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for(new i=0; i<sizeof(weapons);i++){
		weapons[i][0] = '\0';
	}
	OnConfigsExecuted();
}

public OnClientCookiesCached(client)
{
	if(!IsClientInGame(client))
		return;
	
	if(IsClientSourceTV(client))
		return;
	
	LoadClientSettings(client);
}

public OnClientPutInServer(client)
{
	LoadClientSettings(client);
}

public OnClientPostAdminCheck(client)
{
	LoadClientSettings(client);
}


public Event_Spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	SetEntProp(Client,    Prop_Send, "m_bDrawViewmodel",  1);
	SetEntProp(Client,    Prop_Send, "m_iFOV", 90);
	ZoomOn[Client] = 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float: angles[3], &weapon)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		if(playerSettings[client][cfg_enabled] == false)
			return Plugin_Continue;

		if(playerSettings[client][cfg_concmdonly] == true)	// player doesn't want attack2
			return Plugin_Continue;

	        new iActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

		if(buttons & IN_ATTACK2)
		{
			if(!KeyBuffer[client])
			{
				new String:WeaponNamed[64];
				GetClientWeapon(client, WeaponNamed, sizeof(WeaponNamed)); 
				for(new i=0; i<sizeof(weapons);i++){
					if(weapons[i][0]=='\0'){
						return Plugin_Continue;
					}
					new zl;
					if(StrEqual(WeaponNamed,weapons[i])){
						if(buttons & IN_WALK ) {
							zl = ZoomOn[client] - 1;
						} else {
							zl = ZoomOn[client] + 1;
						}

						if(zl <= 0 || zl > MAX_ZOOM(client) || zoomLevels[zl] == 0 ) {
							UnZoom(client);
						} else {
							DoZoom(client, zl);
							currentWeapon[client] = iActiveWeapon;
						}

					}
				}
			}
		} else {
			if(currentWeapon[client] != 0 && currentWeapon[client] != iActiveWeapon) {	// reset zoom if they switched weapons
				UnZoom(client);
			}

			if(ZoomOn[client] ) {
				if(buttons & IN_ZOOM) {
					UnZoom(client);
				}
			}

			KeyBuffer[client] = false;
		}
	}
	return Plugin_Continue;
}

DoZoom(client, zl)
{
	KeyBuffer[client] = true;

	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", zoomLevels[zl]);

	if( zl > ZoomOn[client])
		EmitSoundToAll(soundZoomin, client);
	else 
		EmitSoundToAll(soundZoomout, client);

	ZoomOn[client] = zl; 

	if(soundICU[0]!='\0' ) {	// be evil

#if defined UNFAIR
		if(  playerSettings[client][cfg_icuattacker] == false ){
			return;
		}
#endif
		new Float:clientloc[3], Float:clientang[3];
		GetClientEyePosition(client, clientloc);
		GetClientEyeAngles(client, clientang);	

		new Handle:data = CreateDataPack();
		WritePackCell(data, client);
		TR_TraceRayFilter(clientloc, clientang, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, data);
		TR_DidHit(INVALID_HANDLE);
		CloseHandle(data);
	}
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	ResetPack(data);

	new client = ReadPackCell(data);

	if(entity==client ){
		return false;
	}

	decl String:class[25];
//	new Float:origin[3];

	GetEntityClassname(entity, class, sizeof(class));
	if(StrEqual(class, "player")){
		if(GetTime() - lastPlaySound[entity][client] >= soundICUMin) {
//			new Float:myloc[3];
//			GetClientEyePosition(client, myloc);

			if(playerSettings[entity][cfg_icuvictim]==true){
				EmitSoundToClient(entity, soundICU, SOUND_FROM_PLAYER);//, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, origin, myloc);
				lastPlaySound[entity][client]=GetTime();
			}
		}
	}

	return true;
}



UnZoom(client)
{

	KeyBuffer[client] = true;
	currentWeapon[client] = 0;

	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	if(ZoomOn[client] > 0) {
		EmitSoundToAll(soundZoomout, client);
	}
	
	ZoomOn[client] = 0;
}

public Action:TestZoom(client, args)
{
	decl String:foo[10];
	new bar;

	GetCmdArg(1, foo, sizeof(foo));
	bar = StringToInt(foo);
	DoZoom(client, bar);
}

public Action:DisableZoomFromToggleZoom(client, const String:command[], argc)
{
	UnZoom(client);
}


MyAddSoundToDownloadsTable(const String:name[])
{
	decl String:sndFile[255];
	Format(sndFile, sizeof(sndFile), "sound/%s", name);
	AddFileToDownloadsTable(sndFile);
	PrecacheSound(name,true);

}


public Action:Command_ZoomIn(client, const String:command[], argc)
{

        new iActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new zl;

	if(playerSettings[client][cfg_enabled] == false)
		return Plugin_Handled;

	if(consoleAllZoom==false) {
		if(IsWeaponAllowedCommandZoom(client) == false)
			return Plugin_Handled;
	}

	zl = ZoomOn[client] + 1;
	if(zl <= 0 || zl > MAX_ZOOM(client) || zoomLevels[zl]==0){
		return Plugin_Handled;		// Don't auto unzoom when using mouse wheel.
	} else {
		DoZoom(client, zl);
		currentWeapon[client] = iActiveWeapon;
	}	

	return Plugin_Handled;
}


public Action:Command_ZoomOut(client, const String:command[], argc)
{
        new iActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new zl;

	if(playerSettings[client][cfg_enabled] == false)
		return Plugin_Handled;

	if(consoleAllZoom==false) {
		if(IsWeaponAllowedCommandZoom(client) == false)
			return Plugin_Handled;
	}

	zl = ZoomOn[client] - 1;

	if(zl <= 0 || zl > MAX_ZOOM(zl) || zoomLevels[zl] == 0 ) {
		UnZoom(client);		
	} else {
		DoZoom(client, zl);
		currentWeapon[client] = iActiveWeapon;
	}

	return Plugin_Handled;
}

public Action:Command_UnZoom(client, const String:command[], argc)
{
	UnZoom(client);
	return Plugin_Handled;
}

bool:IsWeaponAllowedCommandZoom(client)
{
	decl String:clientWeapon[20];
	GetClientWeapon(client, clientWeapon, sizeof(clientWeapon));
	for(new i=0; i< sizeof(weapons); i++){
		if(weapons[i][0]=='\0'){
			return false;
		}
		if(StrEqual(weapons[i], clientWeapon))
			return true;
	}
	return false;
}



/************** CLIENT PREFS *****************/

bool:loadCookieOrDefBool(client, Handle:cookie, bool:defaultValue)		// From damagesound.sp by Berni et al
{
	new String:buffer[64];
	GetClientCookie(client, cookie, buffer, sizeof(buffer));
	
	if(!StrEqual(buffer, "")){
		
		return bool:StringToInt(buffer);
	}
	else {
		
		return defaultValue;
	}
}

/*
Float:loadCookieOrDefFloat(client, Handle:cookie, Float:defaultValue)		// From damagesound.sp by Berni et al
{
	new String:buffer[64];
	
	GetClientCookie(client, cookie, buffer, sizeof(buffer));
	
	if(!StrEqual(buffer, "")){
		
		return StringToFloat(buffer);
	}
	else {
		
		return defaultValue;
	}
}
*/

loadCookieOrDefInt(client, Handle:cookie, defaultValue)
{
	new String:buffer[64];
	
	GetClientCookie(client, cookie, buffer, sizeof(buffer));
	
	if(!StrEqual(buffer, "")){
		return StringToInt(buffer);
	}
	else {
		
		return defaultValue;
	}
}


LoadClientSettings(client)
{
	playerSettings[client][cfg_enabled] = loadCookieOrDefBool(client, g_cookieEnable, true);		// players have it on by default
	playerSettings[client][cfg_concmdonly] = loadCookieOrDefBool(client, g_cookieConCmdOnly, false);	// attack2 works by default
	playerSettings[client][cfg_icuvictim] = loadCookieOrDefBool(client, g_cookieICUVictim, true);		// players hear the icu sound by default
	playerSettings[client][cfg_maxzoom] = loadCookieOrDefInt(client, g_cookieMaxZoom, MAX_ZOOM(client))
#if defined UNFAIR
	playerSettings[client][cfg_icuattacker] = loadCookieOrDefBool(client, g_cookieICUAttacker, true);	// player doesn't want to emit icu sound
#endif
}

/***** Menu stuff ******/
public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen){
	
	if (action == CookieMenuAction_SelectOption) {
		ShowWeaponZoomMenu(client);
	}
}

public Action:Command_ShowWeaponZoomMenu(client, args)
{
	ShowWeaponZoomMenu(client);
	return Plugin_Handled;
}

ShowWeaponZoomMenu(client)
{
	new String:buffer[32];
	new String:value[14];

	new Handle:menu = CreateMenu(HandleWeaponZoomMenu);
	SetMenuTitle(menu, "Weapon Zoom");

	BoolToString(value, sizeof(value), playerSettings[client][cfg_enabled], client);
	Format(buffer, sizeof(buffer), "%T: %s", "Enabled", client, value);
	AddMenuItem(menu, COOKIE_ENABLED, buffer);

	
	IntToString(MAX_ZOOM(client), value, sizeof(value));
	Format(buffer, sizeof(buffer), "%T: %sx", "Maximum Zoom", client, value);
	AddMenuItem(menu, COOKIE_MAXZOOM, buffer);

	BoolToString(value, sizeof(value), playerSettings[client][cfg_concmdonly], client);
	Format(buffer, sizeof(buffer), "%T: %s", "Not on attack2", client, value);
	AddMenuItem(menu, COOKIE_CONONLY, buffer);
	
	BoolToString(value, sizeof(value), playerSettings[client][cfg_icuvictim], client);
	Format(buffer, sizeof(buffer), "%T: %s", "Hear ICU sound", client, value);
	AddMenuItem(menu,COOKIE_ICU_VICPREF, buffer);

#if defined UNFAIR
	BoolToString(value, sizeof(value), playerSettings[client][cfg_icuattacker], client);
	Format(buffer, sizeof(buffer), "%T: %s", "Emit ICU sound", client, value);
	AddMenuItem(menu, COOKIE_ICU_ATTEMIT, buffer);
#endif

	if(helpFileUrl[0]!='\0'){
		Format(buffer, sizeof(buffer), "%T", "Show Help", client, value);
		AddMenuItem(menu, "SMW-Help", buffer);
	}

 	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 90);
	
}

public HandleWeaponZoomMenu(Handle:menu, MenuAction:action, client, param)
{
	if(action == MenuAction_Select) {
		decl String:info[32];
		decl String:savedValue[8];
	
		GetMenuItem(menu, param, info, sizeof(info));
		if(StrEqual(info, COOKIE_ENABLED)){

			playerSettings[client][cfg_enabled] = !playerSettings[client][cfg_enabled];
			IntToString(playerSettings[client][cfg_enabled], savedValue, sizeof(savedValue));
			SetClientCookie(client, g_cookieEnable, savedValue);

			if(playerSettings[client][cfg_enabled] && ZoomOn[client]){
				UnZoom(client);
			}

		} else if(StrEqual(info, COOKIE_CONONLY)){

			playerSettings[client][cfg_concmdonly] = !playerSettings[client][cfg_concmdonly];
			IntToString(playerSettings[client][cfg_concmdonly], savedValue, sizeof(savedValue));
			SetClientCookie(client, g_cookieConCmdOnly, savedValue);

		} else if(StrEqual(info,COOKIE_ICU_VICPREF)){

			playerSettings[client][cfg_icuvictim] = !playerSettings[client][cfg_icuvictim];
			IntToString(playerSettings[client][cfg_icuvictim], savedValue, sizeof(savedValue));
			SetClientCookie(client, g_cookieICUVictim, savedValue);

		} else if(StrEqual(info, COOKIE_ICU_ATTEMIT)){
#if defined UNFAIR
			playerSettings[client][cfg_icuattacker] = !playerSettings[client][cfg_icuattacker];
			IntToString(playerSettings[client][cfg_icuattacker], savedValue, sizeof(savedValue));
			SetClientCookie(client, g_cookieICUAttacker, savedValue);
#endif
		} else if(StrEqual(info, "SMW-Help")){
			CancelClientMenu(client);
			new String:motdTitle[50];
			Format(motdTitle, sizeof(motdTitle), "%T", "Weapon Zoom Help", client);
	
			if(helpFileUrl[0]!='\0'){
				ShowMOTDPanel(client, motdTitle, helpFileUrl, MOTDPANEL_TYPE_URL);
			} else {
				ShowMOTDPanel(client, motdTitle, "The Server Operator has disabled in-game help for this plugin", MOTDPANEL_TYPE_TEXT);
			}
		} else if(StrEqual(info, COOKIE_MAXZOOM)){
			ShowMaxZoomSubMenu(client);
		}

	} else if(action == MenuAction_End){
		CloseHandle(menu);
	}
}

ShowMaxZoomSubMenu(client)
{
	new String:buffer[32];
	new String:value[4];	
	
	new Handle:menu = CreateMenu(HandleMaxZoomSubMenu);
	
	SetMenuTitle(menu, "Maximum Weapon Zoom");

	for(new i=1; i <= maxZoom; i++) {
		if(i == MAX_ZOOM(client)){ 
			Format(buffer, sizeof(buffer), "%dx (*)", i);
		} else {
			Format(buffer, sizeof(buffer), "%dx", i);
		}
		Format(value, sizeof(value), "%d", i);
		AddMenuItem(menu, value, buffer);
	}
	
 	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 90);

}

public HandleMaxZoomSubMenu(Handle:menu, MenuAction:action, client, param)
{
	if(action == MenuAction_Select){
		decl String:info[32];
		decl String:savedValue[8];
		new newZoom=0;

		GetMenuItem(menu, param, info, sizeof(info));
		newZoom = StringToInt(info);

		if(newZoom < 0 || newZoom > maxZoom){
			PrintToChat(client, "Sorry Dave, I can't let you do that. Maximum zoom is %d", maxZoom);
		} else {
			playerSettings[client][cfg_maxzoom] = newZoom;
			Format(savedValue, sizeof(savedValue), "%d", newZoom);
			SetClientCookie(client, g_cookieMaxZoom, savedValue);
		}
		
	} else if(action == MenuAction_End){
		CloseHandle(menu);
	}

}


BoolToString(String:str[],maxlen,bool:value, client)
{
	if(value){
		Format(str, maxlen, "%T", "On", client);
	} else {
		Format(str, maxlen, "%T", "Off", client);
	}
}

Handle:CreateConVarInt(const String:cvar[], dfl, const String:desc[], flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	new String:buffer[10];
	Format(buffer, sizeof(buffer), "%d", dfl);
	return(CreateConVar(cvar, buffer, desc, flags, hasMin, min, hasMax, max));
}


