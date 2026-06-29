#define PLUGIN_VERSION		"1.1"

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
// #include <noro>

forward Action OnTimedHordesTrigger(float &timeHordesPast, float timeHordesCap, int &iHordeType);
forward Action OnTimedHordesContinuing(float &timeHordesPast, float timeHordesCap);

// native void TH_SetHordesTime(float timeHordesPast);
// native int TH_GetHordesTime();
// native bool TH_TriggerHordes(); 

public void OnMapStart() {
	CreateTimer(1.0, DirectorTimerCheck, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	L4D2_ExecVScriptCode("g_ModeScript");
	GameRules_SetProp("m_bChallengeModeActive", 1);
}

#define HUD_FLAG_NONE					0	 // no flag
#define HUD_FLAG_PRESTR					1	 // do you want a string/value pair to start(pre) with the string (default is PRE)
#define HUD_FLAG_POSTSTR				2	 // do you want a string/value pair to end(post) with the string
#define HUD_FLAG_BEEP					4	 // Makes a countdown timer blink
#define HUD_FLAG_BLINK					8	 // do you want this field to be blinking
#define HUD_FLAG_AS_TIME				16	// ?
#define HUD_FLAG_COUNTDOWN_WARN			32	// auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG					64	// dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER			128   // by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT				256   // Left justify this text
#define HUD_FLAG_ALIGN_CENTER			512   // Center justify this text
#define HUD_FLAG_ALIGN_RIGHT			768   // Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS			1024  // only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED			2048  // only show to the special infected team
#define HUD_FLAG_TEAM_MASK				3072  // ?
#define HUD_FLAG_UNKNOWN1				4096  // ?
#define HUD_FLAG_TEXT					8192  // ?
#define HUD_FLAG_NOTVISIBLE				16384 // if you want to keep the slot data but keep it from displaying

static const char anims[][] = {
	"⣾","⣽","⣻","⢿","⡿","⣟","⣯","⣷"
}
static const char anims_dot[][] = {
	"⠁", "⠂","⠄","⡀","⢀","⠠","⠐","⠈"
}

#define ALERT_WARN		10
#define HORDE_COOLDOWN	10

float timeLastTrigger;
float directorLastTrigger;
float timeTHLastContinued;
char sBuffer[512];


Action DirectorTimerCheck(Handle timer) {

	float time = GetEngineTime();

	if (time - timeTHLastContinued > 10)
		ScriptedHUDAddFlags(HUD_FLAG_NOTVISIBLE, 0)

	if (!L4D2_CTimerHasStarted(L4D2CT_MobSpawnTimer)) {
		ScriptedHUDAddFlags(HUD_FLAG_NOTVISIBLE, 1)
		return Plugin_Continue;
	}

	float director_past = L4D2_CTimerGetElapsedTime(L4D2CT_MobSpawnTimer), 
		  director_cap = L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer);

	float percent = director_past / director_cap * 100;

	if (percent > 100.0)
		percent = 100.0;

	if (percent < 0)
		percent = 0.0;

	FormatEx(sBuffer, sizeof(sBuffer), "[ %s ] %.f%", anims_dot[RoundToFloor(director_past) % sizeof(anims)], percent);

	int flag_hud = HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT;

	if (time - directorLastTrigger < HORDE_COOLDOWN)
		flag_hud |= HUD_FLAG_BLINK;

	if (director_cap - director_past <= ALERT_WARN)
		flag_hud |= HUD_FLAG_BLINK;

	ScriptedHUDSetParams(1, sBuffer, flag_hud, 0.0, 0.03);

	return Plugin_Continue;
}

public Action OnTimedHordesContinuing(float &timeHordesPast, float timeHordesCap) {

	float time = GetEngineTime();
	timeTHLastContinued = time;

	int flag_hud = HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT;

	if (time - timeLastTrigger < HORDE_COOLDOWN) {
		timeHordesPast = 0.0;
		flag_hud |= HUD_FLAG_BLINK;
	}

	if (timeHordesCap - timeHordesPast <= ALERT_WARN)
		flag_hud |= HUD_FLAG_BLINK;

	float percent = timeHordesPast / timeHordesCap * 100;

	if (percent > 100.0)
		percent = 100.0;

	if (percent < 0)
		percent = 0.0;

	FormatEx(sBuffer, sizeof(sBuffer), "[ %s ] %.f%", anims[RoundToFloor(timeHordesPast) % sizeof(anims)], percent);
	
	ScriptedHUDSetParams(0, sBuffer, flag_hud, 0.0, 0.0);
	return Plugin_Continue;
}

public Action OnTimedHordesTrigger(float &timeHordesPast, float timeHordesCap, int &iHordeType) {
	timeLastTrigger = GetEngineTime();
	
	// ↓ 5% chance tank every horde trigger 
	/*if (0.05 > GetURandomFloat()) {
		iHordeType = 3; //tank
		return Plugin_Changed;
	}*/

	return Plugin_Continue;
}

public Action L4D_OnSpawnMob(int &amount) {
	directorLastTrigger = GetEngineTime();
	return Plugin_Continue;
}

stock void ScriptedHUDSetParams(int element = 0, const char[] text = "", int flags = 0, float posX = 0.0, float posY = 0.0, float width = 1.0, float height = 0.026) {
	ScriptedHUDSetPosition(posX, posY, element);
	ScriptedHUDSetSize(width, height, element);
	ScriptedHUDSetText(text, element);
	ScriptedHUDSetFlags(flags, element);
}

stock void ScriptedHUDSetPosition(float posX, float posY, int element) {
	GameRules_SetPropFloat("m_fScriptedHUDPosX", posX, element);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", posY, element);
}

stock void ScriptedHUDSetSize(float width, float height, int element) {
	GameRules_SetPropFloat("m_fScriptedHUDWidth", width, element);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", height, element);
}

stock void ScriptedHUDSetText(const char[] text, int element) {
	GameRules_SetPropString("m_szScriptedHUDStringSet", text, _, element);
}

stock void ScriptedHUDSetFlags(int flags, int element) {
	GameRules_SetProp("m_iScriptedHUDFlags", flags, _, element);
}

stock int ScriptedHUDGetFlags(int element) {
	return GameRules_GetProp("m_iScriptedHUDFlags", _, element);
}

stock void ScriptedHUDAddFlags(int flags, int element) {
	ScriptedHUDSetFlags(ScriptedHUDGetFlags(element) | flags, element);
}

stock void ScriptedHUDRemoveFlags(int flags, int element) {
	ScriptedHUDSetFlags(ScriptedHUDGetFlags(element) & ~flags, element);
}

stock void ScriptedHUDSetEnabled(bool enable) {
    GameRules_SetProp("m_bChallengeModeActive", view_as<int>(enable));
}