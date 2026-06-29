#define PLUGIN_VERSION		"1.0"

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

forward Action OnTimedHordesTrigger(float &timeHordesPast, float timeHordesCap, int &iHordeType);
forward Action OnTimedHordesContinuing(float &timeHordesPast, float timeHordesCap);

// native void TH_SetHordesTime(float timeHordesPast);
// native int TH_GetHordesTime();
// native bool TH_TriggerHordes(); 

public void OnMapStart() {
	GameRules_SetProp("m_bChallengeModeActive", 1);
}

#define HUD_FLAG_NONE                 0     // no flag
#define HUD_FLAG_PRESTR               1     // do you want a string/value pair to start(pre) with the string (default is PRE)
#define HUD_FLAG_POSTSTR              2     // do you want a string/value pair to end(post) with the string
#define HUD_FLAG_BEEP                 4     // Makes a countdown timer blink
#define HUD_FLAG_BLINK                8     // do you want this field to be blinking
#define HUD_FLAG_AS_TIME              16    // ?
#define HUD_FLAG_COUNTDOWN_WARN       32    // auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG                 64    // dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER        128   // by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT           256   // Left justify this text
#define HUD_FLAG_ALIGN_CENTER         512   // Center justify this text
#define HUD_FLAG_ALIGN_RIGHT          768   // Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS       1024  // only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED        2048  // only show to the special infected team
#define HUD_FLAG_TEAM_MASK            3072  // ?
#define HUD_FLAG_UNKNOWN1             4096  // ?
#define HUD_FLAG_TEXT                 8192  // ?
#define HUD_FLAG_NOTVISIBLE           16384 // if you want to keep the slot data but keep it from displaying

static const char anims[][] = {
	"⣾","⣽","⣻","⢿","⡿","⣟","⣯","⣷"
	// "⠁", "⠂","⠄","⡀","⢀","⠠","⠐","⠈"
}

#define ALERT_WARN		10
#define HORDE_COOLDOWN	10

float timeLastTrigger;

public Action OnTimedHordesContinuing(float &timeHordesPast, float timeHordesCap) {

	static char buffer[512];

	int flag_hud = HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT;

	if (GetEngineTime() - timeLastTrigger < HORDE_COOLDOWN) {
		timeHordesPast = 0.0;
		flag_hud |= HUD_FLAG_BLINK;
	}

	if (timeHordesCap - timeHordesPast <= ALERT_WARN)
		flag_hud |= HUD_FLAG_BLINK;

	GameRules_SetProp("m_iScriptedHUDFlags",  flag_hud, _, 0);
	GameRules_SetPropFloat("m_fScriptedHUDPosX",  0.0199, 0);
	GameRules_SetPropFloat("m_fScriptedHUDPosY",  0.0149, 0);
	GameRules_SetPropFloat("m_fScriptedHUDWidth", 1.5000, 0);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", 0.0260, 0);


	float percent = timeHordesPast / timeHordesCap * 100;

	if (percent > 100.0)
		percent = 100.0;

	if (percent < 0)
		percent = 0.0;

	FormatEx(buffer, sizeof(buffer), "[ %s ] %.f%", anims[RoundToFloor(timeHordesPast) % sizeof(anims)], percent);
	GameRules_SetPropString("m_szScriptedHUDStringSet", buffer);

	return Plugin_Continue;
}

public Action OnTimedHordesTrigger(float &timeHordesPast, float timeHordesCap, int &iHordeType) {
	timeLastTrigger = GetEngineTime();
	return Plugin_Continue;
}
