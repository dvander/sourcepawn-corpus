/* TODO:
 * - Better cooldown system, differentiate between graceful cancels and rejections
 * - Group up all "Do X for medical" functions into a struct
 * - Restore old progress bar in case of overlap
*/

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define MAXPLAYERS_NMRIH 9

public Plugin myinfo = {
	name		= "[NMRiH] Team Healing",
	author		= "Dysphie",
	description	= "Allow use of first aid kits and bandages on teammates",
	version		= "1.0.3_fix"
}

ConVar
	medkitTime,
	bandageTime,
	useDistance,
	healCooldown,
	thinkInterval,
	medkitAmt,
	bandageAmt;

enum HealRequestResult
{
	Heal_Refuse,
	Heal_BadCond,
	Heal_Accept
}

enum struct SoundMap
{
	ArrayList keys;
	ArrayList sounds;

	void Init()
	{
		this.keys = new ArrayList();
		this.sounds = new ArrayList(32);
	}

	void Set(int key, const char[] sound)
	{
		this.keys.Push(key);
		this.sounds.PushString(sound);
	}
}

SoundMap sfx[2];
int healer[MAXPLAYERS_NMRIH+1] = {-1, ...};

enum MedicalSequence
{
	MedicalSequence_Run = 3,
	MedicalSequence_Idle = 4,
	MedicalSequence_WalkIdle = 7
}

enum VoiceCommand
{
	VoiceCommand_Stay = 4,
	VoiceCommand_ThankYou = 5
}

enum Medical
{
	Medical_None = -1,
	Medical_FirstAidKit,
	Medical_Bandages
}

enum struct HealingUse
{
	int client;
	int target;
	float startTime;
	float duration;
	float canTryHealTime;
	// float startAngles[3];
	Handle think;
	int sndCursor; // Sfx
	Medical medical;

	bool IsActive()
	{
		return this.startTime != -1.0;
	}

	void Start(int target, Medical medical)
	{
		this.duration = GetMedicalDuration(medical);
		if (this.duration == -1)
			return;

		this.target = target;
		this.medical = medical;
		this.startTime = GetGameTime();
		healer[target] = this.client;

		// GetClientAbsAngles(this.client, this.startAngles);

		FreezePlayer(this.client);
		FreezePlayer(this.target);

		// TODO: Group these into a single UserMsg?
		ShowProgressBar(this.client, this.duration);
		ShowProgressBar(target, this.duration);

		// TODO: Some voice lines don't really fit here
		TryVoiceCommand(this.client, VoiceCommand_Stay);

		// EnterThirdPerson(this.client, this.target);
		// EnterThirdPerson(this.target, this.client);

		// Use outsider func because CreateTimer won't let us call our own methods
		this.think = CreateTimer(thinkInterval.FloatValue, _ThinkHelper, this.client, TIMER_REPEAT);
	}

	void UseThink()
	{
		if (!IsPlayerAlive(this.client) || !IsPlayerAlive(this.target))
		{
			this.Stop();
			return;
		}
/*
		// Player rotated too much
		float angles[3];
		GetClientAbsAngles(this.client, angles);
		if (GetDifferenceBetweenAngles(angles, this.startAngles) > 90.0)
		{
			this.Stop();
			return;
		}
*/
		if (!(GetClientButtons(this.client) & IN_USE))
		{
			this.Stop();
			return;
		}

		Medical medical = GetActiveMedical(this.client);
		if (medical != this.medical)
		{
			this.Stop();
			return;
		}

		if (!CanPlayerReceiveMedical(this.target, this.medical))
		{
			this.Stop();
			return;
		}

		// Show hud text
		PrintCenterText(this.target, "%t", "Being Healed", this.client);
		PrintCenterText(this.client, "%t", "Healing", this.target);

		float curTime = GetGameTime();

		// Play sounds
		char sound[32];
		float elapsedPct = (curTime - this.startTime) / this.duration * 100;

		int max = sfx[this.medical].keys.Length;
		for (; this.sndCursor < max; this.sndCursor++)
		{
			int playAtPct = sfx[this.medical].keys.Get(this.sndCursor);

			// Bail if we've exhausted the sounds to play this frame
			if (elapsedPct < playAtPct)
				break;

			sfx[this.medical].sounds.GetString(this.sndCursor, sound, sizeof(sound));
			EmitMedicalSound(this.client, sound);
		}

		// Check target distance more leniently in case either player slid a bit
		// Currently healee could walk away using suicide double-tap glitch

		float clientPos[3];
		float targetPos[3];

		GetClientAbsOrigin(this.client, clientPos);
		GetClientAbsOrigin(this.target, targetPos);

		if (GetVectorDistance(clientPos, targetPos) > useDistance.FloatValue + 50.0)
		{
			this.Stop();
			return;
		}

		if (curTime >= this.startTime + this.duration)
		{
			this.Succeed();
			return;
		}
	}

	void Succeed()
	{
		DoFunctionForMedical(this.medical, this.target);

		// A little courtesy goes a long way!
		TryVoiceCommand(this.target, VoiceCommand_ThankYou);

		// Active weapon should always be our medical
		// TODO: Maybe iterate m_hMyWeapons instead for safety?
		int item = GetEntPropEnt(this.client, Prop_Send, "m_hActiveWeapon");
		if (item != -1)
		{
			SDKHooks_DropWeapon(this.client, item);
			RemoveEntity(item);
		}

		this.Stop();
	}

	void Stop(bool success = false)
	{
		if (!this.IsActive())
			return;

		healer[this.target] = -1;
		if(this.think) delete this.think;

		// Stop
		PrintCenterText(this.client, "");
		PrintCenterText(this.client, "");

		UnfreezePlayer(this.client);
		UnfreezePlayer(this.target);

		// If we didn't make it the whole way we need to
		// cancel the progress bars
		if (!success)
		{
			HideProgressBar(this.client);
			HideProgressBar(this.target);
		}

		// ExitThirdPerson(this.client);
		// ExitThirdPerson(this.target);

		this.canTryHealTime = GetGameTime() + healCooldown.FloatValue;

		this.Reset();
	}

	void Init(int client)
	{
		this.client = client;
		this.canTryHealTime = -1.0;
		this.Reset();
	}

	void Reset()
	{
		this.target = -1;
		this.startTime = -1.0;
		this.duration = -1.0;
		this.medical = Medical_None;
		this.sndCursor = 0;
	}

}

HealingUse healing[MAXPLAYERS_NMRIH+1];

public Action _ThinkHelper(Handle timer, int index)
{
	if (!healing[index].IsActive())
	{
		healing[index].think = null;
		return Plugin_Stop;
	}

	healing[index].UseThink();

	return Plugin_Continue;
}

Cookie healCookie;

public void OnPluginStart()
{
	LoadTranslations("team-healing.phrases");

	healCookie = RegClientCookie("disable_team_heal", "Disable team healing", CookieAccess_Public);
	healCookie.SetPrefabMenu(CookieMenu_YesNo_Int, "Disable team healing");

	medkitTime = CreateConVar("sm_team_heal_first_aid_time", "8.1",
					"Seconds it takes for the first aid kit to heal a teammate");
	bandageTime = CreateConVar("sm_team_heal_bandage_time", "2.8",
					"Seconds it takes for bandages to heal a teammate");
	healCooldown = CreateConVar("sm_team_heal_cooldown", "5.0",
					"Cooldown period after a failed team heal attempt");
	useDistance = CreateConVar("sm_team_heal_max_use_distance", "50.0",
					"Maximum use range for medical items");
	thinkInterval = CreateConVar("sm_team_heal_think_interval", "0.1",
					"How often the healing progress thinks. Don't touch this unless you know what you're doing");

	medkitAmt = FindConVar("sv_first_aid_heal_amt");
	bandageAmt = FindConVar("sv_bandage_heal_amt");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientConnected(i);

	SoundMap medkitSnd;
	medkitSnd.Init();
	medkitSnd.Set(0, "Medkit.Open");
	medkitSnd.Set(8, "MedPills.Draw");
	medkitSnd.Set(13, "MedPills.Open");
	medkitSnd.Set(17, "MedPills.Shake");
	medkitSnd.Set(19, "MedPills.Shake");
	medkitSnd.Set(30, "Medkit.Shuffle");
	medkitSnd.Set(39, "Stitch.Prepare");
	medkitSnd.Set(46, "Stitch.Flesh");
	medkitSnd.Set(49, "Weapon_db.GenericFoley");
	medkitSnd.Set(52, "Stitch.Flesh");
	medkitSnd.Set(55, "Stitch.Flesh");
	medkitSnd.Set(58, "Medkit.Shuffle");
	medkitSnd.Set(66, "Scissors.Snip");
	medkitSnd.Set(67, "Scissors.Snip");
	medkitSnd.Set(75, "Scissors.Snip");
	medkitSnd.Set(78, "Weapon_db.GenericFoley");
	medkitSnd.Set(79, "Medkit.Shuffle");
	medkitSnd.Set(84, "Weapon_db.GenericFoley");
	medkitSnd.Set(90, "Weapon_db.GenericFoley");
	medkitSnd.Set(94, "Tape.unravel");

	SoundMap bandageSnd;
	bandageSnd.Init();
	bandageSnd.Set(0, "Weapon_db.GenericFoley");
	bandageSnd.Set(41, "Bandage.Unravel1");
	bandageSnd.Set(55, "Bandage.Unravel2");
	bandageSnd.Set(80, "Bandage.Apply");

	sfx[Medical_FirstAidKit] = medkitSnd;
	sfx[Medical_Bandages] = bandageSnd;
}

void EmitMedicalSound(int client, const char[] game_sound)
{
	int entity;
	char sound_name[128];
	int channel = SNDCHAN_AUTO;
	int sound_level = SNDLEVEL_NORMAL;
	float volume = SNDVOL_NORMAL;
	int pitch = SNDPITCH_NORMAL;
	GetGameSoundParams(game_sound, channel, sound_level, volume, pitch, sound_name, sizeof(sound_name), entity);

	// Play sound.
	EmitSoundToAll(sound_name, client, channel, sound_level, SND_CHANGEVOL | SND_CHANGEPITCH, volume, pitch);
}

public void OnClientConnected(int client)
{
	healing[client].Init(client);
	healer[client] = -1;
}

public void OnClientDisconnect(int client)
{
	if (healing[client].IsActive())
		healing[client].Stop();
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3],
	const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (buttons & IN_DUCK && healer[client] != -1)
		healing[healer[client]].Stop();

	// Can't start heal if we are already healing
	if (healing[client].IsActive())
		return;

	// Not holding use
	if (!(GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_USE))
		return;

	// Not holding a medical item / medical not ready
	Medical medical = GetActiveMedical(client);
	if (medical == Medical_None)
		return;

	// Not aiming at another player / player out of reach
	int target = GetClientUseTarget(client);
	if (target == -1)
		return;

	// TODO: Zombies are too close
	// Do this so target has time to break free if they wish

	// Target doesn't need/want medical
	HealRequestResult canHeal = CanPlayerReceiveMedical(target, medical);
	if (canHeal != Heal_Accept)
	{
		if (canHeal == Heal_Refuse)
			PrintCenterText(client, "%t", "Can't Heal Clientprefs");

		return;
	}

	// Someone rejected our heal and we are on cooldown

	float canHealIn = healing[client].canTryHealTime - GetGameTime();
	if (canHealIn > 0)
	{
		PrintCenterText(client, "%t", "Can't Heal Cooldown", RoundToCeil(canHealIn));
		return;
	}

	// Okay we can heal
	healing[client].Start(target, medical);
}

int GetClientUseTarget(int client)
{
	float hullAng[3];
	GetClientEyeAngles(client, hullAng);

	float hullStart[3];
	GetClientEyePosition(client, hullStart);

	float hullEnd[3];
	ForwardVector(hullStart, hullAng, useDistance.FloatValue, hullEnd);

	static const float mins[3] = {-20.0, -20.0, -20.0}, maxs[3] = {20.0, 20.0, 20.0};
	TR_TraceHullFilter(hullStart, hullEnd, mins, maxs, MASK_PLAYERSOLID, TR_OtherPlayers, client);

	int entity = TR_GetEntityIndex();
	return entity > 0 ? entity : -1;
}

bool TR_OtherPlayers(int entity, int mask, int client)
{
	return entity != client && entity <= MaxClients;
}

void ForwardVector(const float vPos[3], const float vAng[3], float fDistance, float vReturn[3])
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}
/*
float GetDifferenceBetweenAngles(float fA[3], float fB[3])
{
	float fFwdA[3];
	GetAngleVectors(fA, fFwdA, NULL_VECTOR, NULL_VECTOR);

	float fFwdB[3];
	GetAngleVectors(fB, fFwdB, NULL_VECTOR, NULL_VECTOR);

	return RadToDeg(ArcCosine(fFwdA[0] * fFwdB[0] + fFwdA[1] * fFwdB[1] + fFwdA[2] * fFwdB[2]));
}
*/
Medical GetActiveMedical(int client)
{
	int curWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (curWeapon == -1)
		return Medical_None;

	char classname[64];
	GetEntityClassname(curWeapon, classname, sizeof(classname));

	Medical medical = GetMedicalDefinition(curWeapon);
	if (medical != Medical_None)
	{
		MedicalSequence sequence = view_as<MedicalSequence>(GetEntProp(curWeapon, Prop_Send, "m_nSequence"));
		if (sequence == MedicalSequence_Idle || sequence == MedicalSequence_WalkIdle || sequence == MedicalSequence_Run)
			return medical;
	}

	return Medical_None;
}

HealRequestResult CanPlayerReceiveMedical(int client, Medical medical)
{
	if (AreClientCookiesCached(client))
	{
		char c[2];
		healCookie.Get(client, c, sizeof(c));
		if (c[0] == '1')
			return Heal_Refuse;
	}

	if (!TestPreCondForMedical(client, medical))
		return Heal_BadCond;

	return Heal_Accept;
}

stock bool IsPlayerHurt(int client)
{
	return GetClientHealth(client) < GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

stock bool IsPlayerBleeding(int client)
{
	return !!GetEntProp(client, Prop_Send, "_bleedingOut");
}

stock void ShowProgressBar(int client, float duration, float prefill = 0.0)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("ProgressBarShow", client));
	bf.WriteFloat(duration);
	bf.WriteFloat(prefill);
	EndMessage();
}

stock void HideProgressBar(int client)
{
	StartMessageOne("ProgressBarHide", client);
	EndMessage();
}

stock void FreezePlayer(int client)
{
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") | 128);
}

stock void UnfreezePlayer(int client)
{
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") & ~128);
}

void TryVoiceCommand(int client, VoiceCommand voice)
{
	static float lastVoiceTime[MAXPLAYERS_NMRIH+1];

	static ConVar hVoiceCooldown;
	if (!hVoiceCooldown)
		hVoiceCooldown = FindConVar("sv_voice_cooldown");

	float curTime = GetGameTime();
	if (curTime - hVoiceCooldown.FloatValue < lastVoiceTime[client])
		return;

	lastVoiceTime[client] = curTime;
	float origin[3];
	GetClientAbsOrigin(client, origin);

	TE_Start("TEVoiceCommand");
	TE_WriteNum("_playerIndex", client);
	TE_WriteNum("_voiceCommand", view_as<int>(voice));
	TE_SendToAllInRange(origin, RangeType_Audibility);
}

bool TestPreCondForMedical(int& target, Medical& medical)
{
	switch (medical)
	{
		case Medical_Bandages:
			return IsPlayerBleeding(target);

		case Medical_FirstAidKit:
			return IsPlayerHurt(target);

		default:
			return false;
	}
}

void DoFunctionForMedical(Medical& medical, int& target)
{
	if(medical == Medical_None)
		return;

	SetEntProp(target, Prop_Send, "_bleedingOut", 0);

	int newHealth = GetClientHealth(target);
	if(medical == Medical_Bandages)
		newHealth += bandageAmt.IntValue;
	else newHealth += medkitAmt.IntValue;
	int maxHealth = GetEntProp(target, Prop_Data, "m_iMaxHealth");
	if(newHealth > maxHealth) newHealth = maxHealth;

	SetEntityHealth(target, newHealth);
}

Medical GetMedicalDefinition(int item)
{
	char classname[32];
	GetEntityClassname(item, classname, sizeof(classname));

	if (!strcmp(classname, "item_first_aid"))
		return Medical_FirstAidKit;

	if (!strcmp(classname, "item_bandages"))
		return Medical_Bandages;

	return Medical_None;
}

float GetMedicalDuration(Medical& medical)
{
	switch (medical)
	{
		case Medical_Bandages:
			return bandageTime.FloatValue;

		case Medical_FirstAidKit:
			return medkitTime.FloatValue;

		default:
			return -1.0;
	}
}