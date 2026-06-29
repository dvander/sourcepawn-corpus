#include <sdktools>
#include <clientprefs>
#include <WeaponAttachmentAPI>
#pragma semicolon 1

#define PLUGIN_VERSION              "1.2.0"
public Plugin myinfo = 
{
	name = "WA Weapon Lasers",
	author = "Mitchell",
	description = "A Simple plugin that shows lasers out of player's guns.",
	version = PLUGIN_VERSION,
	url = "http://mtch.tech"
};

//int sprLaserBeam = -1;
int Sprite1;
int Sprite2;

ConVar hLaser;
ConVar hLaserClr;
ConVar hLaserClrT;
ConVar hLaserClrCT;
ConVar hLaserWidth;
ConVar hLaserEndWidth;
ConVar hLaserRndrAmt;
ConVar hLaserView;
ConVar hLaserTime;
bool bLaser = true;
int iLaserColorType = 0;
int iLaserColor[4] = {12, 255, 12, 255};
int iLaserColorT[4] = {255, 12, 12, 255};
int iLaserColorCT[4] = {12, 12, 255, 255};
float fLaserWidth = 2.0;
float fLaserEndWidth = 2.0;
int iLaserRndrAmt = 200;
int iLaserView = 0;
float fLaserTime = 0.1;

//Client Prefs
Handle cDisableLasers;

int plyArray[2][MAXPLAYERS+1];
int plyArrayCnt[2];
bool plyDisable[MAXPLAYERS+1] = {false, ...};

int aaa[MAXPLAYERS+1];

public OnPluginStart() {
	hLaser = CreateConVar("sm_walt", "1", "Enable/Disable this plugin",  0);
	hLaserClr = CreateConVar("sm_walt_color", "0", "Hex color of laserbeam (#RGBA); 0 = Team colored; 1 = Random",  0);
	hLaserClrT = CreateConVar("sm_walt_color_t", "FF0C0C", "Hex color of t laserbeam (#RGBA)",  0);
	hLaserClrCT = CreateConVar("sm_walt_color_ct", "0C0CFF", "Hex color of ct laserbeam (#RGBA)",  0);
	hLaserWidth = CreateConVar("sm_walt_width", "2.0", "Width of the laser beam",  0);
	hLaserEndWidth = CreateConVar("sm_walt_endwidth", "2.0", "End Width of the laser beam",  0);
	hLaserRndrAmt = CreateConVar("sm_walt_renderamt", "200", "Render amount of the laser beam",  0);
	hLaserView = CreateConVar("sm_walt_view", "0", "Who can see the beam; 0 = All, 1 = User-only, 2 = Enemies, 3 = Teammates",  0);
	hLaserTime = CreateConVar("sm_walt_time", "0.1", "Life time of the laser",  0);
	HookConVarChange(hLaser, OnConVarChange);
	HookConVarChange(hLaserClr, OnConVarChange);
	HookConVarChange(hLaserClrT, OnConVarChange);
	HookConVarChange(hLaserClrCT, OnConVarChange);
	HookConVarChange(hLaserWidth, OnConVarChange);
	HookConVarChange(hLaserEndWidth, OnConVarChange);
	HookConVarChange(hLaserRndrAmt, OnConVarChange);
	HookConVarChange(hLaserView, OnConVarChange);
	HookConVarChange(hLaserTime, OnConVarChange);
	AutoExecConfig(true, "WeaponLasers");

	CreateConVar("sm_wa_weapon_lasers_version", PLUGIN_VERSION, "WA Laser Tag Version", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Client Prefs:
	cDisableLasers = RegClientCookie("walt_disablelasers", "Disable Weapon Lasers", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, "Weapon Lasers");
	for(int i=1; i < MAXPLAYERS; i++) 
	{
		if(IsSurvivor(i) && IsClientInGame(i) && AreClientCookiesCached(i)) 
		{
			OnClientCookiesCached(i);
		}
	}
	RegConsoleCmd("sm_lasers_all", Command_Lasers);
	RegConsoleCmd("sm_laserson", Command_Lasers2);
	RegConsoleCmd("sm_my978lasersoff", Command_Lasers3);

	HookEvent("bullet_impact", Event_Impact, EventHookMode_Pre);
	HookEvent("player_team", Event_Recalc);
	HookEvent("round_freeze_end", Event_Recalc);

	calcPlayerArrays();
}

public OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue){
	if(convar == hLaserClr || convar == hLaserClrT || convar == hLaserClrCT) {
		if(strlen(newValue) == 6 || strlen(newValue) == 7 || strlen(newValue) == 1) {
			char tempString[18];
			strcopy(tempString, sizeof(tempString), newValue);
			ReplaceString(tempString, sizeof(tempString), "#", "");
			int tempInt = StringToInt(tempString, 16);
			int color[4] = {12,255,12,255};
			color[0] = ((tempInt >> 16) & 0xFF);
			color[1] = ((tempInt >> 8)  & 0xFF);
			color[2] = ((tempInt >> 0)  & 0xFF);
			if(convar == hLaserClr) {
				iLaserColor = color;
			} else if(convar == hLaserClrT) {
				iLaserColorT = color;
			} else if(convar == hLaserClrCT) {
				iLaserColorCT = color;
			}
		}
	} else if(convar == hLaserWidth) {
		fLaserWidth = StringToFloat(newValue);
	} else if(convar == hLaserEndWidth) {
		fLaserEndWidth = StringToFloat(newValue);
	} else if(convar == hLaserRndrAmt) {
		iLaserRndrAmt = StringToInt(newValue);
	} else if(convar == hLaserView) {
		iLaserView = StringToInt(newValue);
		calcPlayerArrays();
	} else if(convar == hLaserTime) {
		fLaserTime = StringToFloat(newValue);
	} else if(convar == hLaser) {
		bLaser = StringToInt(newValue) != 0;
	}
}

public OnMapStart() 
{
	//sprLaserBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	Sprite1 = PrecacheModel("materials/sprites/laserbeam.vmt");    
	Sprite2 = PrecacheModel("materials/sprites/glow.vmt");	
}

public OnClientDisconnect(client)
{
	if (aaa[client] == 1)
	{
		aaa[client] = 0;
	}
}

public Action Event_Impact(Event event, const char[] name, bool dontBroadcast) 
{
	if(!bLaser) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (aaa[client] != 1) return Plugin_Continue;
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && iLaserRndrAmt >= 0) {
		DataPack dp = new DataPack(); 
		CreateDataTimer(0.0, Timer_ShowBeam, dp, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		dp.WriteCell(GetClientUserId(client));
		dp.WriteFloat(GetEventFloat(event, "x"));
		dp.WriteFloat(GetEventFloat(event, "y"));
		dp.WriteFloat(GetEventFloat(event, "z"));
	}
	return Plugin_Continue;
}
	
public Action Timer_ShowBeam(Handle timer, Handle dp) 
{	
	ResetPack(dp);
	int client = GetClientOfUserId(ReadPackCell(dp));

	if (aaa[client] != 1
	|| IsFakeClient(client)
	|| GetClientTeam(client) != 2
	|| !IsValidClient(client)
	|| !IsPlayerAlive(client))
		return Plugin_Stop;

	float epos[3];
	epos[0] = ReadPackFloat(dp);
	epos[1] = ReadPackFloat(dp);
	epos[2] = ReadPackFloat(dp);
	float apos[3];
	int knife = GetPlayerWeaponSlot(client, 1);
	int activeWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if(knife == activeWeapon 
	|| !WA_GetAttachmentPos(client, "muzzle_flash", apos))
	{
		return Plugin_Stop;
	}
	int color[4] = {12,12,12,255};
	GetClientColor(client, color);
	TE_SetupBeamPoints(epos, apos, Sprite1, Sprite2, 0, 0, fLaserTime, fLaserEndWidth, fLaserWidth, 10, 0.0, color, 0);
	if(iLaserView == 0) 
	{
		//Putting this one first because it's the default value, and commonly used.
		TE_Send(plyArray[0], plyArrayCnt[0]);
	} else if(iLaserView == 3) 
	{
		int t = GetClientTeam(client)-2;
		if(t >= 0) {
			TE_Send(plyArray[t], plyArrayCnt[t]);
		}
	} else if(iLaserView == 2) {
		int t = GetClientTeam(client)-2;
		if(t == 0) {
			TE_Send(plyArray[1], plyArrayCnt[1]);
		} else {
			TE_Send(plyArray[0], plyArrayCnt[0]);
		}
	} else if(iLaserView == 1) {
		TE_SendToClient(client);
	}
	return Plugin_Stop;
}

public GetClientColor(int client, int color[4]) {
	if(iLaserColorType == 0) {
		int team = GetClientTeam(client);
		if(team == 2) {
			color = iLaserColorT;
		} else if(team == 3) {
			color = iLaserColorCT;
		} else {
			color[1] = 200;
		}
	} else if(iLaserColorType == 1) {
		color[0] = GetRandomInt(12,200);
		color[1] = GetRandomInt(12,200);
		color[2] = GetRandomInt(12,200);
	} else {
		color = iLaserColor;
	}
	color[3] = iLaserRndrAmt;
}

public Action Event_Recalc(Event event, const char[] name, bool dontBroadcast) {
	calcPlayerArrays();
}

public calcPlayerArrayTeam(int t) {
	if(iLaserView == 0) calcPlayerArrays();
	if(iLaserView < 2 && t >= 0) return;
	plyArrayCnt[t] = 0;
	for(int i=1; i < MAXPLAYERS; i++) {
		if(IsClientInGame(i) && !plyDisable[i]) {
			plyArray[t][plyArrayCnt[t]++] = i;
		}
	}
}

public calcPlayerArrays() {
	if(iLaserView == 1) return;
	plyArrayCnt[0] = 0;
	plyArrayCnt[1] = 0;
	int t = 0;
	for(int i=1; i < MAXPLAYERS; i++) {
		if(IsSurvivor(i) && IsClientInGame(i) && !plyDisable[i]) {
			if(iLaserView > 1) t = GetClientTeam(i)-2;
			if(t >= 0) {
				plyArray[t][plyArrayCnt[t]++] = i;
			}
		}
	}
}

public Action Command_Lasers(int client, int args) {
	if(client > 0){
		DisplaySettingsMenu(client);
	}
	return Plugin_Handled;
}

public Action Command_Lasers2(int client, int args)
{
	aaa[client] = 1;
	plyDisable[client] = false;
	SetClientCookie(client, cDisableLasers, "0");
	PrintToChat(client, "開啟雷射功能");
}

public Action Command_Lasers3(int client, int args)
{
	aaa[client] = 0;
	PrintToChat(client, "關閉雷射功能");
}

//Client Prefs
public OnClientCookiesCached(int client) {
	char tempString[8];
	GetClientCookie(client, cDisableLasers, tempString, sizeof(tempString));
	plyDisable[client] = StringToInt(tempString) != 0;
}

public PrefMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen){
	if(action == CookieMenuAction_SelectOption) {
		DisplaySettingsMenu(client);
	}
}

public DisplaySettingsMenu(int client) 
{
	Handle prefMenu = CreateMenu(PrefMenuHandler, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(prefMenu, "Weapon Lasers: ");
	AddMenuItem(prefMenu, plyDisable[client] ? "enable" : "disable", plyDisable[client] ? "Enable Lasers" : "Disable Lasers");
	DisplayMenu(prefMenu, client, MENU_TIME_FOREVER);
}

public PrefMenuHandler(Handle menu, MenuAction action, int client, int item){
	if(action == MenuAction_Select) 
	{
		char tempString[8];
		GetMenuItem(menu, item, tempString, sizeof(tempString));
		if(StrEqual(tempString, "disable")) 
		{
			plyDisable[client] = true;
			PrintToChat(client, "[SM] Weapon Lasers disabled.");
			SetClientCookie(client, cDisableLasers, "1");
		} 
		else if(StrEqual(tempString, "enable")) 
		{
			plyDisable[client] = false;
			PrintToChat(client, "[SM] Weapon Lasers enabled.");
			SetClientCookie(client, cDisableLasers, "0");
		}
		calcPlayerArrayTeam(GetClientTeam(client)-2);
		DisplaySettingsMenu(client);
	} 
	else if(action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
}

stock bool:IsSurvivor(client) 
{
	if (IsValidClient(client)) 
	{
		if (GetClientTeam(client) == 2) 
		{
			return true;
		}
	}
	return false;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}