#pragma semicolon 1
#pragma newdecls optional

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//#define DEBUG

#define PLUGIN_NAME			  "[L4D2] Infected Hud Health Bar"
#define PLUGIN_AUTHOR		  "z"
#define PLUGIN_DESCRIPTION	  "Show HP bar of special infected with instructor hint hud"
#define PLUGIN_VERSION		  "1.2.0"
#define PLUGIN_URL			  "https://forums.alliedmods.net/showthread.php?t=321565"
#define CFG_FILENAME		  "l4d2_infected_hudhpbar"
#define CFG_HPBARINFECTED 	  "data/l4d2_infected_hudhpbar_config.cfg"

#define RGB_BLACK 	 {0,0,0}
#define RGB_RED 	 {255,0,0}
#define RGB_YELLOW	 {255,255,0}
#define RGB_ORANGE	 {255,165,0}
#define RGB_GREEN	 {0,128,0}
#define RGB_LIME 	 {0,255,0}
#define RGB_CYAN	 {0,255,255}
#define RGB_BLUE 	 {255,0,0}
#define RGB_MAGENTA  {255,0,255}
#define RGB_WHITE 	 {255,255,255}

#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define ZC_WITCH 7 
#define ZC_TANK 8

char g_sSIName[9][]=
{
	""
	,"Smoker"
	,"Boomer"
	,"Hunter"
	,"Spitter"
	,"Jockey"
	,"Charger"
	,"Witch"
	,"Tank"
}; 

ConVar cvarActivated, cvarSize, cvarRange, cvarShowTime, cvarSIClass[9], cvarTextHealth, cvarTextDamage, cvarTextDead, cvarColorFull, cvarColorHalf, cvarColorCritic;
bool g_bActivated; bool g_bShowInfected[9]; int g_iSize; float g_fRange; float g_fShowTime; char g_sTextHealth[16] = "▬"; char g_sTextDamage[16] = "-"; char g_sTextDead[64] = "+"; int g_iColorFull[3]; int g_iColorHalf[3]; int g_iColorCritic[3];

char g_sSITextHP[9][16], g_sSITextDmg[9][16]/*, g_sSITextIcon[9][16]*/;
int g_iSIHPBarSize[9], g_iSIHPBarColorCritic[9][3], g_iSIHPBarColorHalf[9][3], g_iSIHPBarColorFull[9][3], g_iHudTarget[2048 + 1];

public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	cvarActivated             = CreateConVar("l4d2_infected_hudhpbar_activated", "1", "0:Disable , 1:Enable Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarSIClass[ZC_SMOKER]    = CreateConVar("l4d2_infected_hudhpbar_on_smoker", "0", "0:Disable, 1:Enable Show Hud HP Bar for Smoker");
	cvarSIClass[ZC_BOOMER]    = CreateConVar("l4d2_infected_hudhpbar_on_boomer", "0", "0:Disable, 1:Enable Show Hud HP Bar for Boomer");
	cvarSIClass[ZC_HUNTER]    = CreateConVar("l4d2_infected_hudhpbar_on_hunter", "0", "0:Disable, 1:Enable Show Hud HP Bar for Hunter");
	cvarSIClass[ZC_SPITTER]   = CreateConVar("l4d2_infected_hudhpbar_on_spitter", "0", "0:Disable, 1:Enable Show Hud HP Bar for Spitter");
	cvarSIClass[ZC_JOCKEY]    = CreateConVar("l4d2_infected_hudhpbar_on_jockey", "0", "0:Disable, 1:Enable Show Hud HP Bar for Jockey");
	cvarSIClass[ZC_CHARGER]   = CreateConVar("l4d2_infected_hudhpbar_on_charger", "0", "0:Disable, 1:Enable Show Hud HP Bar for Charger");
	cvarSIClass[ZC_WITCH]     = CreateConVar("l4d2_infected_hudhpbar_on_witch", "1", "0:Disable, 1:Enable Show Hud HP Bar for Witch");
	cvarSIClass[ZC_TANK]      = CreateConVar("l4d2_infected_hudhpbar_on_tank", "1", "0:Disable, 1:Enable Show Hud HP Bar for Tank");
	cvarSize                  = CreateConVar("l4d2_infected_hudhpbar_size", "10", "Set width size for health bar", FCVAR_NONE, true, 2.0, true, 100.0);
	cvarRange                 = CreateConVar("l4d2_infected_hudhpbar_range", "750.0", "Set range Instuctor Hint (0 = infinite range)", FCVAR_NONE, true, 0.0, true, 750.0);
	cvarShowTime              = CreateConVar("l4d2_infected_hudhpbar_showtime", "3.0", "Set time out in seconds HP Bar (0 = no time out)", FCVAR_NONE, true, 0.0);
	cvarTextHealth            = CreateConVar("l4d2_infected_hudhpbar_texthp", "-", "Set text for health point");
	cvarTextDamage            = CreateConVar("l4d2_infected_hudhpbar_textdmg", " ", "Set text for damage point");
	cvarTextDead              = CreateConVar("l4d2_infected_hudhpbar_textdead", "", "Set text for dead hint (\"\" = no dead hint)");
	cvarColorFull             = CreateConVar("l4d2_infected_hudhpbar_colorfull", "0,255,0", "Set RGB color for full HP");
	cvarColorHalf             = CreateConVar("l4d2_infected_hudhpbar_colorhalf", "255,255,0", "Set RGB color for half HP");
	cvarColorCritic           = CreateConVar("l4d2_infected_hudhpbar_colorcritic", "255,0,0", "Set RGB color for critic HP");
	AutoExecConfig(true, CFG_FILENAME);
	
	cvarActivated.AddChangeHook(CvarChanged_Activated);
	cvarSIClass[ZC_SMOKER].AddChangeHook(CvarsChanged); 
	cvarSIClass[ZC_BOOMER].AddChangeHook(CvarsChanged); 
	cvarSIClass[ZC_HUNTER].AddChangeHook(CvarsChanged); 
	cvarSIClass[ZC_SPITTER].AddChangeHook(CvarsChanged);
	cvarSIClass[ZC_JOCKEY].AddChangeHook(CvarsChanged); 
	cvarSIClass[ZC_CHARGER].AddChangeHook(CvarsChanged);
	cvarSIClass[ZC_WITCH].AddChangeHook(CvarsChanged);
	cvarSIClass[ZC_TANK].AddChangeHook(CvarsChanged);
	cvarRange.AddChangeHook(CvarsChanged);
	cvarShowTime.AddChangeHook(CvarsChanged);
	cvarSize.AddChangeHook(CvarsChanged);
	cvarTextHealth.AddChangeHook(CvarsChanged);  
	cvarTextDamage.AddChangeHook(CvarsChanged);
	cvarTextDead.AddChangeHook(CvarsChanged);  
	cvarColorFull.AddChangeHook(CvarsChanged);
	cvarColorHalf.AddChangeHook(CvarsChanged);  
	cvarColorCritic.AddChangeHook(CvarsChanged);  
	
	EnablePlugin();
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void EnablePlugin(){
	g_bActivated = cvarActivated.BoolValue;
	if(g_bActivated){
		HookEvents();
		LoadHPBarInfected();
	}
	GetCvars();
}

void HookEvents(){
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("infected_death", Event_InfectedDeath);
}

void UnHookEvents(){
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_incapacitated", Event_PlayerIncapped);
	UnhookEvent("player_hurt", Event_PlayerHurt);
	UnhookEvent("infected_hurt", Event_InfectedHurt);
	UnhookEvent("infected_death", Event_InfectedDeath);
}

public void CvarChanged_Activated(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bActivated = convar.BoolValue;
	if (g_bActivated && (strcmp(oldValue, "0") == 0))
		EnablePlugin();
	else if (!g_bActivated && (strcmp(oldValue, "1") == 0))
		UnHookEvents();
}	

public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars(){
	g_bShowInfected[ZC_SMOKER]  = cvarSIClass[ZC_SMOKER].BoolValue;
	g_bShowInfected[ZC_BOOMER]  = cvarSIClass[ZC_BOOMER].BoolValue;
	g_bShowInfected[ZC_HUNTER]  = cvarSIClass[ZC_HUNTER].BoolValue;
	g_bShowInfected[ZC_SPITTER] = cvarSIClass[ZC_SPITTER].BoolValue;
	g_bShowInfected[ZC_JOCKEY]  = cvarSIClass[ZC_JOCKEY].BoolValue;
	g_bShowInfected[ZC_CHARGER] = cvarSIClass[ZC_CHARGER].BoolValue;
	g_bShowInfected[ZC_WITCH] = cvarSIClass[ZC_WITCH].BoolValue;
	g_bShowInfected[ZC_TANK]    = cvarSIClass[ZC_TANK].BoolValue;
	g_iSize = cvarSize.IntValue;
	g_fRange = cvarRange.FloatValue;
	g_fShowTime = cvarShowTime.FloatValue;
	cvarTextHealth.GetString(g_sTextHealth, sizeof(g_sTextHealth));
	cvarTextDamage.GetString(g_sTextDamage, sizeof(g_sTextDamage));
	cvarTextDead.GetString(g_sTextDead, sizeof(g_sTextDead));
	char sTemp[16];
	cvarColorFull.GetString(sTemp, sizeof(sTemp));
	g_iColorFull = StringRGBToIntRGB(sTemp);
	cvarColorHalf.GetString(sTemp, sizeof(sTemp));
	g_iColorHalf = StringRGBToIntRGB(sTemp);
	cvarColorCritic.GetString(sTemp, sizeof(sTemp));
	g_iColorCritic = StringRGBToIntRGB(sTemp);
}

void LoadHPBarInfected(){
	//get config file
	char sPath[PLATFORM_MAX_PATH], sTemp[16];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CFG_HPBARINFECTED);

	//create config file
	KeyValues hFile = new KeyValues("HPBarInfected");
	if(!FileExists(sPath))
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
		
		for( int i=1; i <= ZC_TANK; i++ ){
			if(hFile.JumpToKey(g_sSIName[i], true))
			{
				hFile.SetNum("barsize", 10);
				hFile.SetString("texthp", "▬");
				hFile.SetString("textdmg", "-");
				//hFile.SetString("texticon", " ");
				hFile.SetString("colorcritic", "255, 0, 0");
				hFile.SetString("colorhalf", "255, 255, 0");
				hFile.SetString("colorfull", "0, 255, 0");
				hFile.Rewind();
			}
		}
		hFile.ExportToFile(sPath);
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CFG_HPBARINFECTED);
	}
	// load config
	if( hFile.ImportFromFile(sPath) )
	{
		for( int i=1; i <= ZC_TANK; i++ ){
			if(hFile.JumpToKey(g_sSIName[i], true)){
				g_iSIHPBarSize[i] = hFile.GetNum("barsize", 0);
				hFile.GetString("texthp", g_sSITextHP[i], sizeof(g_sSITextHP), "");
				hFile.GetString("textdmg", g_sSITextDmg[i], sizeof(g_sSITextDmg), "");
				//hFile.GetString("texticon", g_sSITextIcon[i], sizeof(g_sSITextIcon), "");
				hFile.GetString("colorcritic", sTemp, sizeof(sTemp), "");
				g_iSIHPBarColorCritic[i] = strlen(sTemp) == 0 ? {-1, -1, -1} : StringRGBToIntRGB(sTemp);
				hFile.GetString("colorhalf", sTemp, sizeof(sTemp), "");
				g_iSIHPBarColorHalf[i] = strlen(sTemp) == 0 ? {-1, -1, -1} : StringRGBToIntRGB(sTemp);
				hFile.GetString("colorfull", sTemp, sizeof(sTemp), "");
				g_iSIHPBarColorFull[i] = strlen(sTemp) == 0 ? {-1, -1, -1} : StringRGBToIntRGB(sTemp);
				hFile.Rewind();
			}
		}
	}
	delete hFile;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidInfected(client)){
		SettingDeadHint(client);
	}
}

public void Event_PlayerIncapped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidInfected(client) && IsPlayerAlive(client) && IsPlayerIncapped(client)){
		SettingDeadHint(client);
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidInfected(client) && IsPlayerAlive(client) && !IsPlayerIncapped(client))
	{
		SettingHudHPBar(client);
	}
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{	
	int entity = event.GetInt("entityid");
	if (IsWitch(entity)){
		SettingHudHPBar(entity);
	}
}

public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("infected_id");
	if (IsWitch(entity)){
		SettingDeadHint(entity);
	}
}

void SettingHudHPBar(int target){
	
	int class;
	if(IsWitch(target)){
		class = ZC_WITCH;
	}else{
		class = GetEntProp(target, Prop_Send, "m_zombieClass");
	}
	
	if(!g_bShowInfected[class]){
		return;
	}
	
	static char texthpbar[128];
	texthpbar = "";
	int hp = GetEntProp(target, Prop_Data, "m_iHealth");	
	int hpmax = GetMaxHealth(target);
	float hpp = (float(hp) / float(hpmax)) * 100.0;
	int color[3];
	g_iColorFull = g_iSIHPBarColorFull[class][0] == -1 ? g_iColorFull : g_iSIHPBarColorFull[class];
	g_iColorHalf = g_iSIHPBarColorHalf[class][0] == -1 ? g_iColorHalf : g_iSIHPBarColorHalf[class];
	g_iColorCritic = g_iSIHPBarColorCritic[class][0] == -1 ? g_iColorCritic : g_iSIHPBarColorCritic[class];
	color=GetColorHP(hpp, g_iColorFull, g_iColorHalf, g_iColorCritic);
	
	GetProgressBarText(RoundFloat(hpp), (!g_iSIHPBarSize[class] ? g_iSize : g_iSIHPBarSize[class]), (strlen(g_sSITextHP[class]) == 0 ? g_sTextHealth: g_sSITextHP[class]), (strlen(g_sSITextDmg[class]) == 0 ? g_sTextDamage: g_sSITextDmg[class]), texthpbar);
	int hint_target = EntRefToEntIndex(g_iHudTarget[target]);
	if(IsValidEnt(hint_target)){
		int hint = GetEntPropEnt(hint_target, Prop_Data, "m_hMoveChild");
		if(IsValidEnt(hint)){
			AcceptEntityInput(hint, "EndHint");
			DispatchKeyValue(hint, "hint_caption", texthpbar);
			DispatchKeyValueFormat(hint, "hint_color", "%i %i %i", color[0], color[1], color[2]);
			AcceptEntityInput(hint, "ShowHint");
		}
	}else{
		hint_target = CreateHPBarHint(target, g_fShowTime, g_fRange, color, texthpbar);
		g_iHudTarget[target] = EntIndexToEntRef(hint_target); 
	}
}

void SettingDeadHint(int target){
	int hint_target = EntRefToEntIndex(g_iHudTarget[target]);
	if(strlen(g_sTextDead) == 0){
		if(IsValidEnt(hint_target))
			RemoveEntity(hint_target);
		return;
	}
		
	int color[3] = RGB_WHITE;
	if(IsValidEnt(hint_target)){
		int hint = GetEntPropEnt(hint_target, Prop_Data, "m_hMoveChild");
		if(IsValidEnt(hint)){
			AcceptEntityInput(hint, "EndHint");
			DispatchKeyValue(hint, "hint_caption", g_sTextDead);
			DispatchKeyValueFormat(hint, "hint_color", "%i %i %i", color[0], color[1], color[2]);
			AcceptEntityInput(hint, "ShowHint");
		}
	}else{
		hint_target = CreateHPBarHint(target, 1.0, g_fRange, color, g_sTextDead);
		g_iHudTarget[target] = EntIndexToEntRef(hint_target);
	}
}

int CreateHPBarHint(int target, float duration, float range, int color[3], char[] text, char[] icon =""){
	float pos[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", pos);
	pos[2]+=80.0;
	int hint_target = CreateHudTarget(target, pos);
	if(IsValidEnt(hint_target)){
		DisplayInstructorHint(hint_target, duration, 0.0, range, true, false, icon, icon, "", false, color, text);
	}
	return hint_target;
}

int GetMaxHealth(int client){
	int hpmax = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	int hp = GetEntProp(client, Prop_Data, "m_iHealth");		
	if(hp > 0 && hp > hpmax){
		SetEntProp(client, Prop_Data, "m_iMaxHealth",hp);
	}
	return hpmax;
}

void GetProgressBarText(int percent, int sizebar, const char[] texthp, const char[] textdmg, char[] textbar){
	int barpercent = RoundFloat(float(sizebar) * float(percent) / 100.0) ;
	int size=1;
	for(int i=1; i <= sizebar; i++){
		if(i <= barpercent)
			StrCat(textbar, size+=strlen(texthp), texthp);
		else
			StrCat(textbar, size+=strlen(textdmg), textdmg);
	}
}

int[] GetColorHP(float percent, int rgbfull[3] = RGB_GREEN, int rgbhalf[3] = RGB_YELLOW, int rgbcritic[3] = RGB_RED){
	int color_hp[3] = {255, 255, 255};
	if(percent > 50){
		color_hp = GetGradientColorRGB(rgbfull, rgbhalf, 50.0, (percent -50.0));
	}else{
		color_hp = GetGradientColorRGB(rgbhalf, rgbcritic, 50.0, percent);
	}
	return color_hp;
}

stock int[] GetGradientColorRGB(int color_start[3], int color_end[3], float step_max, float step){
	int color_rgb[3],rgb_lower[3];
	float rgb_factor[3],rgb_percent[3];
	
	for(int i=0; i<3; i++){
		rgb_factor[i]  = float(color_start[i] - color_end[i]) / step_max;
		rgb_percent[i] = rgb_factor[i] > 0 ? step : step_max - step;
		rgb_lower[i]   = color_start[i] > color_end[i] ? color_end[i] : color_start[i];
		color_rgb[i]   = RoundFloat( FloatAbs(rgb_factor[i]) * rgb_percent[i] ) + rgb_lower[i];
	}
	return color_rgb;
}

//https://forums.alliedmods.net/showpost.php?p=2670680&postcount=14
int CreateHudTarget(int entity, float pos[3] = NULL_VECTOR)
{
	if(IsNullVector(pos))
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	
	int ent = CreateEntityByName("info_target_instructor_hint");
	if(ent > 0){
		char name[32];
		FormatEx(name, sizeof(name), "hudtarget%d", ent);
		DispatchKeyValue(ent, "targetname", name);
		DispatchKeyValueVector(ent, "origin", pos);
		DispatchSpawn(ent);
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", entity, ent);
	}
	return ent;
}
//https://forums.alliedmods.net/showthread.php?t=302535
stock void DisplayInstructorHint(int target, float fTime, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char[] sText){
	int entity =  CreateEntityByName("env_instructor_hint");
	static char sBuffer[32];
	
	float vPos[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
	DispatchKeyValueVector(entity, "origin", vPos);
	// Target
	GetEntPropString(target, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));
	if(strlen(sBuffer) == 0){
		FormatEx(sBuffer, sizeof(sBuffer), "targethint%d", target);
		DispatchKeyValue(target, "targetname", sBuffer);
	}
	DispatchKeyValue(entity, "hint_target", sBuffer);
	
	// Fix for showing all clients
	DispatchKeyValue(entity, "hint_name", sBuffer);
	DispatchKeyValue(entity, "hint_replace_key", sBuffer);
	
	// Static
	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);
	DispatchKeyValue(entity, "hint_static", sBuffer);
	
	// Timeout
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fTime));
	DispatchKeyValue(entity, "hint_timeout", sBuffer);
	
	// Height
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));
	DispatchKeyValue(entity, "hint_icon_offset", sBuffer);
	
	// Range
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));
	DispatchKeyValue(entity, "hint_range", sBuffer);
	
	// Show off screen
	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);
	DispatchKeyValue(entity, "hint_nooffscreen", sBuffer);
	
	// Icons
	DispatchKeyValue(entity, "hint_icon_onscreen", sIconOnScreen);
	DispatchKeyValue(entity, "hint_icon_offscreen", sIconOffScreen);
	
	// Command binding
	DispatchKeyValue(entity, "hint_binding", sCmd);
	
	// Show text behind walls
	FormatEx(sBuffer, sizeof(sBuffer), "%d", bShowTextAlways);
	DispatchKeyValue(entity, "hint_forcecaption", sBuffer);
	
	// Text color
	FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
	DispatchKeyValue(entity, "hint_color", sBuffer);
	//Text
	//ReplaceString(sText, sizeof(sText), "\n", " ");
	DispatchKeyValue(entity, "hint_caption", sText);
	DispatchKeyValue(entity, "hint_activator_caption", sText);
	
	// Other Options
	DispatchKeyValue(entity, "hint_flags", "0");
	DispatchKeyValue(entity, "hint_display_limit", "0");
	DispatchKeyValue(entity, "hint_suppress_rest", "1");// no show in face
	DispatchKeyValue(entity, "hint_auto_start", "1");
	DispatchKeyValue(entity, "hint_allow_nodraw_target", "true");
	/*
	0: Multiple
    1: Single Open (Prevents new hints from opening.)
    2: Fixed Replace (Ends other hints when a new one is shown.)
    3: Single Active (Hides other hints when a new one is shown.)
	*/
	DispatchKeyValue(entity, "hint_instance_type", "2");//2

	DispatchSpawn(entity);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target, entity);
	AcceptEntityInput(entity, "ShowHint");

}
//https://forums.alliedmods.net/showthread.php?t=129135
stock void KillEntity(int entity, float seconds){
	char addoutput[64];
    Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1",seconds);
    SetVariantString(addoutput);
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser1");
}

stock int[] StringRGBToIntRGB(const char[] str_rgb) {
	int colorRGB[3];
	char str_color[16][3];
	char color_string[16];
	strcopy(color_string, sizeof(color_string), str_rgb);
	TrimString(color_string);
	ExplodeString(color_string, ",", str_color, sizeof(str_color[]), sizeof(str_color));
	colorRGB[0] = StringToInt(str_color[0]);
	colorRGB[1] = StringToInt(str_color[1]);
	colorRGB[2] = StringToInt(str_color[2]);
	
	return colorRGB;
}
//https://forums.alliedmods.net/showthread.php?t=249891
stock void DispatchKeyValueFormat( entity, const char[] keyName, const char[] format, any ...){
	char value[256];
	VFormat( value, sizeof( value ), format, 4 );
	DispatchKeyValue( entity, keyName, value );
}

stock bool IsWitch(int entity){
	if (IsValidEnt(entity)){
		char classname[16];
		GetEntityClassname(entity, classname, sizeof(classname));
		return (strcmp(classname, "witch") == 0);
	}
	return false;
}	

stock bool IsPlayerHanding(int client){
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1);
}

stock bool IsPlayerIncapped(int client){
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

stock bool IsValidSpect(int client){ 
	return (IsValidClient(client) && GetClientTeam(client) == 1 );
}

stock bool IsValidSurvivor(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 2 );
}

stock bool IsValidInfected(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 3 );
}

stock bool IsValidClient(int client){
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsValidEnt(int entity){
	return (entity > MaxClients && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}