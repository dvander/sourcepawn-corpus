#define PLUGIN_VERSION		"1.1"
#define PLUGIN_NAME			"shouts_jockey"
#define PLUGIN_NAME_FULL	"[L4D2] Random Animal Shouts for Jockey"
#define PLUGIN_DESCRIPTION	"replace jockey idle voice to cricket, frog, gulls, dog, bird"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2792847"

/*
 *	v1.0 just released; 15-November-2022
 *	v1.0.1 change to more effective sounds matches way, fix a little bit ConVar description; 16-November-2022
 *	v1.1 update animal list, more dog / gulls / cricket / frog / bird; 19-November-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define ZOMBIECLASS_JOCKEY 5

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsJockey(%1) (IsClient(%1) && GetClientTeam(%1) == 3 && GetEntProp(%1, Prop_Send, "m_zombieClass") == ZOMBIECLASS_JOCKEY)

char SOUNDS_ANIMAL[][] = {
	"player/pz/voice/attack/zombiedog_attack1.wav",
	"player/pz/voice/attack/zombiedog_attack2.wav",
	"player/pz/voice/attack/zombiedog_attack3.wav",
	"ambient/random_amb_sfx/rur_random_dogbig01.wav",
	"ambient/random_amb_sfx/rur_random_dogbig02.wav",
	"ambient/random_amb_sfx/rur_random_dogbig03.wav",
	"ambient/random_amb_sfx/rur_random_dogbig04.wav",
	"ambient/random_amb_sfx/rur_random_dogsmall01.wav",
	"ambient/random_amb_sfx/rur_random_coyote01.wav",
	"ambient/random_amb_sfx/rur_random_coyote02.wav",
	"ambient/random_amb_sfx/rur_random_coyote03.wav",
	"ambient/random_amb_sfx/rur_random_coyote04.wav",
	"ambient/random_amb_sfx/rur_random_insect01.wav",
	"ambient/random_amb_sfx/rur_random_insect02.wav",
	"ambient/random_amb_sfx/rur_randomscreechowl01.wav",
	"ambient/random_amb_sfx/rur_randomscreechowl02.wav",
	"ambient/random_amb_sfx/rur_randomscreechowl03.wav",
	"ambient/random_animals/frog_groups/by_frog_01.wav",
	"ambient/random_animals/frog_groups/by_frog_02.wav",
	"ambient/random_animals/frog_groups/by_frog_03.wav",
	"ambient/random_animals/frog_groups/by_frog_04.wav",
	"ambient/random_animals/frog_groups/by_frog_05.wav",
	"ambient/random_animals/frog_groups/by_frog_06.wav",
	"ambient/random_animals/frog_groups/by_frog_07.wav",
	"ambient/random_animals/frog_groups/by_frog_08.wav",
	"ambient/random_animals/frog_groups/by_frog_long_01.wav",
	"ambient/random_animals/frog_groups/by_frog_long_02.wav",
	"ambient/random_animals/frog_groups/by_frog_long_03.wav",
	"ambient/random_animals/frog_groups/frog_long_01.wav",
	"ambient/random_animals/frog_groups/frog_long_02.wav",
	"ambient/random_animals/frog_groups/frog_long_03.wav",
	"ambient/random_animals/frog_groups/small_frog_01a.wav",
	"ambient/random_animals/frog_groups/small_frog_01b.wav",
	"ambient/random_animals/frog_groups/small_frog_01c.wav",
	"ambient/random_animals/frog_groups/small_frog_02a.wav",
	"ambient/random_animals/frog_groups/small_frog_02b.wav",
	"ambient/random_animals/frog_groups/small_frog_03a.wav",
	"ambient/random_animals/frog_groups/small_frog_03b.wav",
	"ambient/random_animals/frog_groups/small_frog_04a.wav",
	"ambient/random_animals/frog_groups/small_frog_04b.wav",
	"ambient/random_animals/frog_groups/small_frog_04c.wav",
	"ambient/random_animals/frog_groups/small_frog_04d.wav",
	"ambient/random_animals/single_bird_01.wav",
	"ambient/random_animals/single_bird_02.wav",
	"ambient/random_animals/single_bird_03.wav",
	"ambient/random_animals/single_bird_04.wav",
	"ambient/random_animals/single_bird_05.wav",
	"ambient/random_animals/single_bird_06.wav",
	"ambient/random_animals/single_bird_07.wav",
	"ambient/random_animals/single_bird_08.wav",
	"ambient/random_amb_sounds/rand_gulls_01.wav",
	"ambient/random_amb_sounds/rand_gulls_02.wav",
	"ambient/random_amb_sounds/rand_gulls_03.wav",
	"ambient/random_amb_sounds/rand_gulls_04.wav",
	"ambient/random_amb_sounds/rand_gulls_05.wav", //gulls has water fx, not good
	"ambient/random_amb_sfx/rur5b_seagull01.wav",
	"ambient/random_amb_sfx/rur5b_seagull02.wav",
	"ambient/random_amb_sfx/rur5b_seagull03.wav",
	"ambient/random_amb_sfx/rur5b_seagull04.wav",
	"ambient/random_amb_sfx/rur5b_seagull05.wav",
	"ambient/random_amb_sfx/rur5b_seagull06.wav",
	"ambient/spacial_loops/frogs_spatial_loop01.wav",
	"ambient/animal/crow_1.wav",
	"ambient/animal/crow_2.wav",
	"ambient/levels/caves/cave_crickets_loop1.wav",
	"ambient/random_amb_sfx/cricket_double.wav",
	"ambient/random_amb_sfx/cricket_single.wav",
	"ambient/random_amb_sfx/forest_bird01.wav",
	"ambient/random_amb_sfx/forest_bird01b.wav",
	"ambient/random_amb_sfx/forest_bird02.wav",
	"ambient/random_amb_sfx/forest_bird02b.wav",
	"ambient/random_amb_sfx/forest_bird03.wav",
	"ambient/random_amb_sfx/frog_01.wav",
	"ambient/random_amb_sfx/frog_02.wav",
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cChance;		float flChance;

public void OnPluginStart() {

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cChance =		CreateConVar(PLUGIN_NAME ... "_chance", "1.0",		"chance to make random voice [0.0 - 1.0]", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);

	cChance.AddChangeHook(OnConVarChanged);

	AddNormalSoundHook(OnSoundEmitted);

	ApplyCvars();
}

public void OnMapStart() {
	for (int i = 0; i < sizeof(SOUNDS_ANIMAL); i++)
		PrecacheSound(SOUNDS_ANIMAL[i]);
}

void ApplyCvars() {
	flChance = cChance.FloatValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

Action OnSoundEmitted(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
	  char soundEntry[PLATFORM_MAX_PATH], int &seed) {

	if (IsJockey(entity) && numClients > 0 && flChance > GetURandomFloat()) {

		if (strncmp(sample, "player/jockey/voice/idle/", 24) == 0 || strncmp(sample, "player/jockey/voice/alert/", 26) == 0) {

			int index_random = RoundToFloor( GetURandomFloat() * sizeof(SOUNDS_ANIMAL) );

			strcopy(sample, PLATFORM_MAX_PATH, SOUNDS_ANIMAL[index_random]);

			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}