#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <autoexecconfig>
#include <liquidHelpers>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_BONEMERGE_FASTCULL       (1 << 7)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)
#define HIDEHUD_ALL                 (1 << 2)
#define HIDEHUD_CROSSHAIR           (1 << 8)
#define CVAR_FLAGS			FCVAR_PROTECTED

ConVar g_cvHidePlayers;

TopMenu hTopMenu;

ConVar g_cvFlagEmotesMenu;
ConVar g_cvFlagDancesMenu;
ConVar g_cvCooldown;
ConVar g_cvSpeed;
ConVar g_cvEmotesSounds;
ConVar g_cvHideWeapons;
ConVar g_cvTeleportBack;

int g_iEmoteEnt[MAXPLAYERS+1];
int g_iEmoteSoundEnt[MAXPLAYERS+1];

int g_EmotesTarget[MAXPLAYERS+1];

char g_sEmoteSound[MAXPLAYERS+1][PLATFORM_MAX_PATH];

bool g_bClientDancing[MAXPLAYERS+1];


Handle CooldownTimers[MAXPLAYERS+1];
bool g_bEmoteCooldown[MAXPLAYERS+1];

int g_iWeaponHandEnt[MAXPLAYERS+1];

Handle g_EmoteForward;
Handle g_EmoteForward_Pre;
bool g_bHooked[MAXPLAYERS + 1];

float g_fLastAngles[MAXPLAYERS+1][3];
float g_fLastPosition[MAXPLAYERS+1][3];

public Plugin myinfo =
{
  name = "[L4D2] Fortnite Emotes & Dances",
  author = "Kodua, Franc1sco franug, TheBO$$, Aleexxx, Foxhound, nearly civilized, Ferks-FK",
  description = "Animations from Fortnite in CS:GO/L4D2. New emotes ported by nearly civilized",
  version = "1.8.2",
  url = "https://forums.alliedmods.net/showthread.php?t=318981"
};

public void OnPluginStart()
{	
  LoadTranslations("common.phrases");
  LoadTranslations("fnemotes_near.phrases");
  
  RegConsoleCmd("sm_rdance", Command_Random_Emote, "[SM] Emote aleatório");
  RegConsoleCmd("sm_emotes", Command_Menu);
  RegConsoleCmd("sm_emote", Command_Menu);
  RegConsoleCmd("sm_dances", Command_Menu);
  RegConsoleCmd("sm_dance", Command_Menu);
  RegAdminCmd("sm_setemotes", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
  RegAdminCmd("sm_setemote", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
  RegAdminCmd("sm_setdances", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
  RegAdminCmd("sm_setdance", Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");

  RegConsoleCmd("sm_doemote", Command_Do_Emotes, "[SM] Usage: sm_doemote [Emote ID]");
  RegConsoleCmd("sm_dodance", Command_Do_Emotes, "[SM] Usage: sm_dodance [Emote ID]");
  RegAdminCmd("sm_danceall", Command_Force_Emote, ADMFLAG_GENERIC, "Forces all players to dance");

  HookEvent("player_death", 	Event_PlayerDeath, 	EventHookMode_Pre);
  HookEvent("player_hurt", 	Event_PlayerHurt, 	EventHookMode_Pre);
  HookEvent("player_bot_replace", Event_BotReplacePlayer, EventHookMode_Pre);
  HookEvent("player_team", 	Event_PlayerTeam, 	EventHookMode_Pre);
  HookEvent("round_start",  Event_Start);
  HookEvent("round_end", Event_RoundEnd);
  
  /**
    Convars
  **/
  
  AutoExecConfig_SetFile("fortnite_emotes_nearlycivilized");

  g_cvEmotesSounds = AutoExecConfig_CreateConVar("sm_emotes_sounds", "1", "Enable/Disable sounds for emotes.", _, true, 0.0, true, 1.0);
  g_cvCooldown = AutoExecConfig_CreateConVar("sm_emotes_cooldown", "1.0", "Cooldown for emotes in seconds. -1 or 0 = no cooldown.");
  g_cvFlagEmotesMenu = AutoExecConfig_CreateConVar("sm_emotes_admin_flag_menu", "", "admin flag for emotes (empty for all players)");
  g_cvFlagDancesMenu = AutoExecConfig_CreateConVar("sm_dances_admin_flag_menu", "", "admin flag for dances (empty for all players)");
  g_cvHideWeapons = AutoExecConfig_CreateConVar("sm_emotes_hide_weapons", "1", "Hide weapons when dancing", _, true, 0.0, true, 1.0);
  g_cvHidePlayers = AutoExecConfig_CreateConVar("sm_emotes_hide_enemies", "0", "Hide enemy players when dancing", _, true, 0.0, true, 1.0);
  g_cvTeleportBack = AutoExecConfig_CreateConVar("sm_emotes_teleportonend", "1", "Teleport back to the exact position when he started to dance. (Some maps need this for teleport triggers)", _, true, 0.0, true, 1.0);
  g_cvSpeed = CreateConVar("sm_emotes_speed", "0.84", "Sets the playback speed of the animation. default (1.0)", CVAR_FLAGS);
  
  AutoExecConfig_ExecuteFile();
  
  AutoExecConfig_CleanFile();
  
  /**
    End Convars
  **/

  TopMenu topmenu;
  if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
  {
    OnAdminMenuReady(topmenu);
  }	
  
  g_EmoteForward = CreateGlobalForward("fnemotes_OnEmote", ET_Ignore, Param_Cell);
  g_EmoteForward_Pre = CreateGlobalForward("fnemotes_OnEmote_Pre", ET_Event, Param_Cell);
}

public void OnPluginEnd()
{
  for (int i = 1; i <= MaxClients; i++) {
    if (IsValidClient(i) && g_bClientDancing[i]) {
      StopEmote(i);
    }
  }
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  RegPluginLibrary("fnemotes");
  CreateNative("fnemotes_IsClientEmoting", Native_IsClientEmoting);
  return APLRes_Success;
}

int Native_IsClientEmoting(Handle plugin, int numParams)
{
  return g_bClientDancing[GetNativeCell(1)];
}

public void OnMapStart()
{
  AddFileToDownloadsTable("models/player/kodua/fnemotes_nearlycivilized.mdl");
  AddFileToDownloadsTable("models/player/kodua/fnemotes_nearlycivilized.vvd");
  AddFileToDownloadsTable("models/player/kodua/fnemotes_nearlycivilized.dx90.vtx");

  // edit
  // add the sound file routes here
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/ninja_dance_01.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/dance_soldier_03.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/hip_hop_good_vibes_mix_01_loop.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_zippy_a.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_electroshuffle_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_aerobics_01.mp3"); 
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_bendy.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_bandofthefort_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_boogiedown.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_capoeira.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_flapper_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_chicken_foley_01.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/bananacry.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_music_boneless.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_shoot_v7.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_swipeit.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_disco.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_worm_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_takethel.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_breakdance_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_dance_pump.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_ridethepony_music_01.mp3"); 
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_facepalm_foley_01.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_onthehook_02.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_floss_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_flippnsexy.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_fresh_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_groove_jam_a.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/br_emote_shred_guitar_mix_03_loop.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_heelclick.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/s5_hiphop_breakin_132bmp_loop.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_hotstuff.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_hula_01.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_infinidab.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_intensity.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_irish_jig_foley_music_loop.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_koreaneagle.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_kpop_01.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_laugh_01.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_livinglarge_a.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_luchador.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_hillbilly_shuffle.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_samba_new_b.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_makeitrain_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_poplock.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_poprock_01.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_robot_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_salute_foley_01.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_snap1.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_stagebow.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_dino_complete.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_founders_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_twist.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_warehouse.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/wiggle_music_loop.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_yeet.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/youre_awesome_emote_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_lankylegs_loop_02.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/eastern_bloc_musc_setup_d.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_bandofthefort_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_hot_music.mp3");

  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/smooth_moves.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/california_girls.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/thanos_twerk.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/psychic.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_vivid.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/deflated_emote_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_art_giant.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_autumn_tea.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_comrade.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_downward.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_griddles_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_hotpink.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_jumpingjoy.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_just_home_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_macaroon_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_nevergonna.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_tour_bus.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/pumpkin_dance.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/air_guitar_emote.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/distraction.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_blaster.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/headbanger_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/hitchhiker_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/showstopper_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/sprinkler_music.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/gmod_select.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/pollo_dance.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/toastbust.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/lebronjame.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/cant_c_me.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/rollie_rollie.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/leave_the_door.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/unforgettable.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/scenariooo.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/dropit.mp3");

  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/bananacry.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/blowkiss.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/clapping.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/fishing.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/flexing.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/gogogo.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/iheartyou.mp3");
  AddFileToDownloadsTable("sound/kodua/fortnite_emotes/jubilation.mp3");
    

  // this dont touch
  PrecacheModel("models/player/kodua/fnemotes_nearlycivilized.mdl", true);

  // edit
  // add mp3 files without sound/
  // add wav files with */
  PrecacheSound("kodua/fortnite_emotes/ninja_dance_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/dance_soldier_03.mp3");
  PrecacheSound("kodua/fortnite_emotes/hip_hop_good_vibes_mix_01_loop.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_zippy_a.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_electroshuffle_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_aerobics_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_music_emotes_bendy.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_bandofthefort_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_boogiedown.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_capoeira.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_flapper_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_chicken_foley_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/bananacry.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_music_boneless.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emotes_music_shoot_v7.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emotes_music_swipeit.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_disco.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_worm_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_music_emotes_takethel.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_breakdance_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_dance_pump.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_ridethepony_music_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_facepalm_foley_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emotes_onthehook_02.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_floss_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_flippnsexy.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_fresh_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_groove_jam_a.mp3");
  PrecacheSound("kodua/fortnite_emotes/br_emote_shred_guitar_mix_03_loop.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_heelclick.mp3");
  PrecacheSound("kodua/fortnite_emotes/s5_hiphop_breakin_132bmp_loop.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_hotstuff.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_hula_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_infinidab.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_intensity.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_irish_jig_foley_music_loop.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_music_emotes_koreaneagle.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_kpop_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_laugh_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_livinglarge_a.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_luchador.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_hillbilly_shuffle.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_samba_new_b.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_makeitrain_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_poplock.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_poprock_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_robot_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_salute_foley_01.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_snap1.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_stagebow.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_dino_complete.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_founders_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emotes_music_twist.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_warehouse.mp3");
  PrecacheSound("kodua/fortnite_emotes/wiggle_music_loop.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_yeet.mp3");
  PrecacheSound("kodua/fortnite_emotes/youre_awesome_emote_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emotes_lankylegs_loop_02.mp3");
  PrecacheSound("kodua/fortnite_emotes/eastern_bloc_musc_setup_d.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_bandofthefort_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/athena_emote_hot_music.mp3");
  
  PrecacheSound("kodua/fortnite_emotes/smooth_moves.mp3");
  PrecacheSound("kodua/fortnite_emotes/california_girls.mp3");
  PrecacheSound("kodua/fortnite_emotes/thanos_twerk.mp3");
  PrecacheSound("kodua/fortnite_emotes/psychic.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_vivid.mp3");
  PrecacheSound("kodua/fortnite_emotes/deflated_emote_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_art_giant.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_autumn_tea.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_comrade.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_downward.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_griddles_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_hotpink.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_jumpingjoy.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_just_home_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_macaroon_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_nevergonna.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_tour_bus.mp3");
  PrecacheSound("kodua/fortnite_emotes/pumpkin_dance.mp3");
  PrecacheSound("kodua/fortnite_emotes/air_guitar_emote.mp3");
  PrecacheSound("kodua/fortnite_emotes/distraction.mp3");
  PrecacheSound("kodua/fortnite_emotes/emote_blaster.mp3");
  PrecacheSound("kodua/fortnite_emotes/headbanger_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/hitchhiker_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/itsgotime_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/kneeslapper_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/showstopper_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/sprinkler_music.mp3");
  PrecacheSound("kodua/fortnite_emotes/gmod_select.mp3");
  PrecacheSound("kodua/fortnite_emotes/pollo_dance.mp3");
  PrecacheSound("kodua/fortnite_emotes/toastbust.mp3");
  PrecacheSound("kodua/fortnite_emotes/lebronjame.mp3");
  PrecacheSound("kodua/fortnite_emotes/cant_c_me.mp3");
  PrecacheSound("kodua/fortnite_emotes/rollie_rollie.mp3");
  PrecacheSound("kodua/fortnite_emotes/leave_the_door.mp3");
  PrecacheSound("kodua/fortnite_emotes/unforgettable.mp3");
  PrecacheSound("kodua/fortnite_emotes/scenariooo.mp3");
  PrecacheSound("kodua/fortnite_emotes/dropit.mp3");

  PrecacheSound("kodua/fortnite_emotes/bananacry.mp3");
  PrecacheSound("kodua/fortnite_emotes/blowkiss.mp3");
  PrecacheSound("kodua/fortnite_emotes/clapping.mp3");
  PrecacheSound("kodua/fortnite_emotes/fishing.mp3");
  PrecacheSound("kodua/fortnite_emotes/flexing.mp3");
  PrecacheSound("kodua/fortnite_emotes/gogogo.mp3");
  PrecacheSound("kodua/fortnite_emotes/iheartyou.mp3");
  PrecacheSound("kodua/fortnite_emotes/jubilation.mp3");
}


public void OnClientPutInServer(int client)
{
  if (IsValidClient(client))
  {	
    ResetCam(client);
    TerminateEmote(client);
    g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;

    if (CooldownTimers[client] != null)
    {
      KillTimer(CooldownTimers[client]);
    }
  }
}

public void OnClientDisconnect(int client)
{
  if (IsValidClient(client))
  {
    ResetCam(client);
    TerminateEmote(client);

    if (CooldownTimers[client] != null)
    {
      KillTimer(CooldownTimers[client]);
      CooldownTimers[client] = null;
      g_bEmoteCooldown[client] = false;
    }
  }
  g_bHooked[client] = false;
}

void Event_BotReplacePlayer(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));
    StopEmote(player);
    StopEmote(bot);

    SetEntityMoveType(player, MOVETYPE_WALK);

    bool isHanging = GetEntProp(bot, Prop_Send, "m_isHangingFromLedge") == 1;
    
    if (!isHanging) {
        SetEntityMoveType(bot, MOVETYPE_WALK);
    }
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
  int victim = GetClientOfUserId(event.GetInt("userid"));
  if (IsValidClient(victim) && L4D_GetClientTeam(victim) == L4DTeam_Survivor) {
      StopEmote(victim);
  }
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
  int client = GetClientOfUserId(event.GetInt("userid"));
  
  if (IsValidClient(client))
  {
    ResetCam(client);
    StopEmote(client);
  }
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
  int client = GetClientOfUserId(event.GetInt("userid"));
  StopEmote(client);
}

void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
  for (int i = 1; i <= MaxClients; i++) {
    if (IsValidClient(i, false) && g_bClientDancing[i]) {
      ResetCam(i);
      StopEmote(i);
      WeaponUnblock(i);
      g_bClientDancing[i] = false;
    }
  }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
  for (int i = 0; i <= MaxClients; i++)
  {
    if (!IsValidClient(i))
        continue;

    if (IsFakeClient(i) && OnInfectedTeam(i))
        CreateTimer(1.0, BotTaunt, i, TIMER_FLAG_NO_MAPCHANGE);
  }
}

public Action BotTaunt(Handle timer, int client)
{
  if (!IsValidClient(client))
      return Plugin_Continue;

  RandomDance(client);
  return Plugin_Continue;
}

public Action Command_Menu(int client, int args)
{
  if (!IsValidClient(client))
    return Plugin_Handled;
  
  Menu_Dance(client);

  return Plugin_Handled;
}

Action CreateEmote(int client, const char[] anim1, const char[] anim2, const char[] soundName)
{
  if (!IsValidClient(client))
    return Plugin_Handled;
  
  if(g_EmoteForward_Pre != null)
  {
    Action res = Plugin_Continue;
    Call_StartForward(g_EmoteForward_Pre);
    Call_PushCell(client);
    Call_Finish(res);

    if (res != Plugin_Continue)
    {
      return Plugin_Handled;
    }
  }
  
  if (!IsPlayerAlive(client) || bIsPlayerIncapped(client))
  {
    CReplyToCommand(client, "%t", "MUST_BE_ALIVE");
    return Plugin_Handled;
  }

  if (!(GetEntityFlags(client) & FL_ONGROUND))
  {
    CReplyToCommand(client, "%t", "STAY_ON_GROUND");
    return Plugin_Handled;
  }
  
  if (CooldownTimers[client])
  {
    CReplyToCommand(client, "%t", "COOLDOWN_EMOTES");
    return Plugin_Handled;
  }

  if (StrEqual(anim1, ""))
  {
    CReplyToCommand(client, "%t", "AMIN_1_INVALID");
    return Plugin_Handled;
  }

  if (g_iEmoteEnt[client])
    StopEmote(client);

  if (GetEntityMoveType(client) == MOVETYPE_NONE)
  {
    CReplyToCommand(client, "%t", "CANNOT_USE_NOW");
    return Plugin_Handled;
  }

  int EmoteEnt = CreateEntityByName("prop_dynamic");
  if (IsValidEntity(EmoteEnt))
  {
    SetEntityMoveType(client, MOVETYPE_NONE);
    WeaponBlock(client);

    float vec[3], ang[3];
    GetClientAbsOrigin(client, vec);
    GetClientAbsAngles(client, ang);
    
    g_fLastPosition[client] = vec;
    g_fLastAngles[client] = ang;

    char emoteEntName[16];
    FormatEx(emoteEntName, sizeof(emoteEntName), "emoteEnt%i", GetRandomInt(1000000, 9999999));
    
    DispatchKeyValue(EmoteEnt, "targetname", emoteEntName);
    DispatchKeyValue(EmoteEnt, "model", "models/player/kodua/fnemotes_nearlycivilized.mdl");
    DispatchKeyValue(EmoteEnt, "solid", "0");
    DispatchKeyValue(EmoteEnt, "rendermode", "10");

    ActivateEntity(EmoteEnt);
    DispatchSpawn(EmoteEnt);

    TeleportEntity(EmoteEnt, vec, ang, NULL_VECTOR);
    
    SetVariantString(emoteEntName);
    AcceptEntityInput(client, "SetParent", client, client, 0);

    g_iEmoteEnt[client] = EntIndexToEntRef(EmoteEnt);

    SetEntProp(client, Prop_Send, "m_fEffects", EF_BONEMERGE | EF_NOSHADOW | EF_NORECEIVESHADOW | EF_BONEMERGE_FASTCULL | EF_PARENT_ANIMATES);

    //Sound

    if (g_cvEmotesSounds.BoolValue && !StrEqual(soundName, ""))
    {
      int EmoteSoundEnt = CreateEntityByName("info_target");
      if (IsValidEntity(EmoteSoundEnt))
      {
        char soundEntName[16];
        FormatEx(soundEntName, sizeof(soundEntName), "soundEnt%i", GetRandomInt(1000000, 9999999));

        DispatchKeyValue(EmoteSoundEnt, "targetname", soundEntName);

        DispatchSpawn(EmoteSoundEnt);

        vec[2] += 72.0;
        TeleportEntity(EmoteSoundEnt, vec, NULL_VECTOR, NULL_VECTOR);

        SetVariantString(emoteEntName);
        AcceptEntityInput(EmoteSoundEnt, "SetParent");

        g_iEmoteSoundEnt[client] = EntIndexToEntRef(EmoteSoundEnt);

        //Formatting sound path

        char soundNameBuffer[64];

        if (StrEqual(soundName, "ninja_dance_01") || StrEqual(soundName, "dance_soldier_03"))
        {
          int randomSound = GetRandomInt(0, 1);
          if(randomSound)
          {
            soundNameBuffer = "ninja_dance_01";
          } else
          {
            soundNameBuffer = "dance_soldier_03";
          }
        } else
        {
          FormatEx(soundNameBuffer, sizeof(soundNameBuffer), "%s", soundName);
        }

        FormatEx(g_sEmoteSound[client], PLATFORM_MAX_PATH, "kodua/fortnite_emotes/%s.mp3", soundNameBuffer);

        EmitSoundToAll(g_sEmoteSound[client], client, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
      }
    }
    else
    {
      g_sEmoteSound[client] = "";
    }

    if (StrEqual(anim2, "none", false))
    {
      HookSingleEntityOutput(EmoteEnt, "OnAnimationDone", EndAnimation, true);
    }
    else
    {
      SetVariantString(anim2);
      AcceptEntityInput(EmoteEnt, "SetDefaultAnimation", -1, -1, 0);
    }

    SetVariantString(anim1);
    AcceptEntityInput(EmoteEnt, "SetAnimation", -1, -1, 0);

    SetCam(client);

    if(g_cvSpeed.FloatValue!=1.0) SetEntPropFloat(EmoteEnt, Prop_Send, "m_flPlaybackRate", g_cvSpeed.FloatValue);

    g_bClientDancing[client] = true;
    
    if(g_cvHidePlayers.BoolValue)
    {
      for(int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client) && !g_bHooked[i])
        {
          SDKHook(i, SDKHook_SetTransmit, SetTransmit);
          g_bHooked[i] = true;
        }
    }

    if (g_cvCooldown.FloatValue > 0.0)
    {
      CooldownTimers[client] = CreateTimer(g_cvCooldown.FloatValue, ResetCooldown, client);
    }
    
    if(g_EmoteForward != null)
    {
      Call_StartForward(g_EmoteForward);
      Call_PushCell(client);
      Call_Finish();
    }
  }
  
  return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
  if (IsNonElevatorMap())
  {
    if (g_bClientDancing[client] && !(GetEntityFlags(client) & FL_ONGROUND))
    {
      StopEmote(client);
    }
  }
  else
  {
    {
    if (g_bClientDancing[client] && !(GetEntityFlags(client) & FL_ONGROUND))
    {
      StopEmote(client);
    }
  }
  }

  static int iAllowedButtons = IN_BACK | IN_FORWARD | IN_MOVELEFT | IN_MOVERIGHT | IN_WALK | IN_SPEED | IN_SCORE;

  if (iButtons == 0)
    return Plugin_Continue;

  if (g_iEmoteEnt[client] == 0)
    return Plugin_Continue;

  if ((iButtons & iAllowedButtons) && !(iButtons &~ iAllowedButtons)) 
    return Plugin_Continue;

  StopEmote(client);

  return Plugin_Continue;
}

void EndAnimation(const char[] output, int caller, int activator, float delay) 
{
  if (caller > 0)
  {
    activator = GetEmoteActivator(EntIndexToEntRef(caller));
    StopEmote(activator);
  }
}

int GetEmoteActivator(int iEntRefDancer)
{
  if (iEntRefDancer == INVALID_ENT_REFERENCE)
    return 0;
  
  for (int i = 1; i <= MaxClients; i++) 
  {
    if (g_iEmoteEnt[i] == iEntRefDancer) 
    {
      return i;
    }
  }
  return 0;
}

void StopEmote(int client)
{
  if (!g_iEmoteEnt[client])
    return;

  int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
  if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
  {
    char emoteEntName[50];
    GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
    SetVariantString(emoteEntName);
    AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
    DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
    AcceptEntityInput(iEmoteEnt, "FireUser1");
    
    if(g_cvTeleportBack.BoolValue)
      TeleportEntity(client, g_fLastPosition[client], g_fLastAngles[client], NULL_VECTOR);
    
    ResetCam(client);
    WeaponUnblock(client);
    SetEntityMoveType(client, MOVETYPE_WALK);
    g_iEmoteEnt[client] = 0;
    g_bClientDancing[client] = false;
  } else
  {
    g_iEmoteEnt[client] = 0;
    g_bClientDancing[client] = false;
  }

  if (g_iEmoteSoundEnt[client])
  {
    int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);

    if (!StrEqual(g_sEmoteSound[client], "") && iEmoteSoundEnt && iEmoteSoundEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteSoundEnt))
    {
      StopSound(client, SNDCHAN_AUTO, g_sEmoteSound[client]);
      AcceptEntityInput(iEmoteSoundEnt, "Kill");
      g_iEmoteSoundEnt[client] = 0;
    }
    else
    {
      g_iEmoteSoundEnt[client] = 0;
    }
  }
}

void TerminateEmote(int client)
{
  if (!g_iEmoteEnt[client])
    return;

  int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
  if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
  {
    char emoteEntName[50];
    GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
    SetVariantString(emoteEntName);
    AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
    DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
    AcceptEntityInput(iEmoteEnt, "FireUser1");

    g_iEmoteEnt[client] = 0;
    g_bClientDancing[client] = false;
  } else
  {
    g_iEmoteEnt[client] = 0;
    g_bClientDancing[client] = false;
  }

  if (g_iEmoteSoundEnt[client])
  {
    int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);

    if (!StrEqual(g_sEmoteSound[client], "") && iEmoteSoundEnt && iEmoteSoundEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteSoundEnt))
    {
      StopSound(client, SNDCHAN_AUTO, g_sEmoteSound[client]);
      AcceptEntityInput(iEmoteSoundEnt, "Kill");
      g_iEmoteSoundEnt[client] = 0;
    }
    else
    {
      g_iEmoteSoundEnt[client] = 0;
    }
  }
}

void WeaponBlock(int client)
{
  SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUseSwitch);
  SDKHook(client, SDKHook_WeaponSwitch, WeaponCanUseSwitch);
  
  if(g_cvHideWeapons.BoolValue)
    SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
    
  int iEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
  if(iEnt != -1)
  {
    g_iWeaponHandEnt[client] = EntIndexToEntRef(iEnt);
    
    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
  }
}

void WeaponUnblock(int client)
{
  SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUseSwitch);
  SDKUnhook(client, SDKHook_WeaponSwitch, WeaponCanUseSwitch);
  
  //Even if are not activated, there will be no errors
  SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
  
  if(GetEmotePeople() == 0)
  {
    for(int i = 1; i <= MaxClients; i++)
      if (IsClientInGame(i) && g_bHooked[i])
      {
        SDKUnhook(i, SDKHook_SetTransmit, SetTransmit);
        g_bHooked[i] = false;
      }
  }
  
  if(IsPlayerAlive(client) && g_iWeaponHandEnt[client] != INVALID_ENT_REFERENCE)
  {
    int iEnt = EntRefToEntIndex(g_iWeaponHandEnt[client]);
    if(iEnt != INVALID_ENT_REFERENCE)
    {
      SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iEnt);
    }
  }
  
  g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;
}

Action WeaponCanUseSwitch(int client, int weapon)
{
  return Plugin_Stop;
}

void OnPostThinkPost(int client)
{
  SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}

public Action SetTransmit(int entity, int client) 
{ 
  if(g_bClientDancing[client] && IsPlayerAlive(client) && GetClientTeam(client) != GetClientTeam(entity)) return Plugin_Handled;
  
  return Plugin_Continue; 
} 

void SetCam(int client)
{
  SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
  SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_CROSSHAIR);
}

void ResetCam(int client)
{
  SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
  SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDEHUD_CROSSHAIR);
}

Action ResetCooldown(Handle timer, any client)
{
  CooldownTimers[client] = null;

  return Plugin_Continue;
}

Action Menu_Dance(int client)
{
  Menu menu = new Menu(MenuHandler1);

  char title[65];
  Format(title, sizeof(title), "%T:", "TITLE_MAIM_MENU", client);
  menu.SetTitle(title);	

  AddTranslatedMenuItem(menu, "", "RANDOM_EMOTE", client);
  AddTranslatedMenuItem(menu, "", "RANDOM_DANCE", client);
  AddTranslatedMenuItem(menu, "", "EMOTES_LIST", client);
  AddTranslatedMenuItem(menu, "", "DANCES_LIST", client);
  
  menu.ExitButton = true;
  menu.ExitBackButton = false;
  menu.Display(client, MENU_TIME_FOREVER);
 
  return Plugin_Handled;
}

void MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
  switch (action)
  {		
    case MenuAction_Select:
    {
      int client = param1;
      
      switch (param2)
      {
        case 0: 
        {
          RandomEmote(client);
          Menu_Dance(client);
        }
        case 1: 
        {
          RandomDance(client);
          Menu_Dance(client);
        }			
        case 2: EmotesMenu(client);
        case 3: DancesMenu(client);
      }
    }
    case MenuAction_End:
    {
      delete menu;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////
//Emotes Menu
////////////////////////////////////////////////////////////////////////////////////////////

Action EmotesMenu(int client)
{
  char sBuffer[32];
  g_cvFlagEmotesMenu.GetString(sBuffer, sizeof(sBuffer));

  if (!CheckAdminFlags(client, ReadFlagString(sBuffer)))
  {
    CPrintToChat(client, "%t", "NO_EMOTES_ACCESS_FLAG");
    return Plugin_Handled;
  }
  Menu menu = new Menu(MenuHandlerEmotes);
  
  char title[65];
  Format(title, sizeof(title), "%T:", "TITLE_EMOTES_MENU", client);
  menu.SetTitle(title);	

  AddTranslatedMenuItem(menu, "1", "Emote_Fonzie_Pistol", client);
  AddTranslatedMenuItem(menu, "2", "Emote_Bring_It_On", client);
  AddTranslatedMenuItem(menu, "3", "Emote_ThumbsDown", client);
  AddTranslatedMenuItem(menu, "4", "Emote_ThumbsUp", client);
  AddTranslatedMenuItem(menu, "5", "Emote_Celebration_Loop", client);
  AddTranslatedMenuItem(menu, "6", "Emote_BlowKiss", client);
  AddTranslatedMenuItem(menu, "7", "Emote_Calculated", client);
  AddTranslatedMenuItem(menu, "8", "Emote_Confused", client);	
  AddTranslatedMenuItem(menu, "9", "Emote_Chug", client);
  AddTranslatedMenuItem(menu, "10", "Emote_Cry", client);
  AddTranslatedMenuItem(menu, "11", "Emote_DustingOffHands", client);
  AddTranslatedMenuItem(menu, "12", "Emote_DustOffShoulders", client);	
  AddTranslatedMenuItem(menu, "13", "Emote_Facepalm", client);
  AddTranslatedMenuItem(menu, "14", "Emote_Fishing", client);
  AddTranslatedMenuItem(menu, "15", "Emote_Flex", client);
  AddTranslatedMenuItem(menu, "16", "Emote_golfclap", client);	
  AddTranslatedMenuItem(menu, "17", "Emote_HandSignals", client);
  AddTranslatedMenuItem(menu, "18", "Emote_HeelClick", client);
  AddTranslatedMenuItem(menu, "19", "Emote_Hotstuff", client);
  AddTranslatedMenuItem(menu, "20", "Emote_IBreakYou", client);	
  AddTranslatedMenuItem(menu, "21", "Emote_IHeartYou", client);
  AddTranslatedMenuItem(menu, "22", "Emote_Kung-Fu_Salute", client);
  AddTranslatedMenuItem(menu, "23", "Emote_Laugh", client);
  AddTranslatedMenuItem(menu, "24", "Emote_Luchador", client);	
  AddTranslatedMenuItem(menu, "25", "Emote_Make_It_Rain", client);
  AddTranslatedMenuItem(menu, "26", "Emote_NotToday", client);
  AddTranslatedMenuItem(menu, "27", "Emote_RockPaperScissor_Paper", client);
  AddTranslatedMenuItem(menu, "28", "Emote_RockPaperScissor_Rock", client);	
  AddTranslatedMenuItem(menu, "29", "Emote_RockPaperScissor_Scissor", client);
  AddTranslatedMenuItem(menu, "30", "Emote_Salt", client);
  AddTranslatedMenuItem(menu, "31", "Emote_Salute", client);
  AddTranslatedMenuItem(menu, "32", "Emote_Snap", client);
  AddTranslatedMenuItem(menu, "33", "Emote_StageBow", client);
  AddTranslatedMenuItem(menu, "34", "Emote_Wave2", client);
  AddTranslatedMenuItem(menu, "35", "Emote_Yeet", client);
  AddTranslatedMenuItem(menu, "36", "Emote_Cena", client);
  AddTranslatedMenuItem(menu, "37", "Emote_Lebron", client);

  menu.ExitButton = true;
  menu.ExitBackButton = true;
  menu.Display(client, MENU_TIME_FOREVER);
 
  return Plugin_Handled;
}

void MenuHandlerEmotes(Menu menu, MenuAction action, int client, int param2)
{
  switch (action)
  {		
    case MenuAction_Select:
    {
      char info[16];
      if(menu.GetItem(param2, info, sizeof(info)))
      {
        int iParam2 = StringToInt(info);

        switch (iParam2)
        {
          case 1:
          CreateEmote(client, "Emote_Fonzie_Pistol", "none", "");
          case 2:
          CreateEmote(client, "Emote_Bring_It_On", "none", "");
          case 3:
          CreateEmote(client, "Emote_ThumbsDown", "none", "");
          case 4:
          CreateEmote(client, "Emote_ThumbsUp", "none", "");
          case 5:
          CreateEmote(client, "Emote_Celebration_Loop", "", "jubilation");
          case 6:
          CreateEmote(client, "Emote_BlowKiss", "none", "blowkiss");
          case 7:
          CreateEmote(client, "Emote_Calculated", "none", "");
          case 8:
          CreateEmote(client, "Emote_Confused", "none", "");
          case 9:
          CreateEmote(client, "Emote_Chug", "none", "gogogo");
          case 10:
          CreateEmote(client, "Emote_Cry", "none", "bananacry");
          case 11:
          CreateEmote(client, "Emote_DustingOffHands", "none", "");
          case 12:
          CreateEmote(client, "Emote_DustOffShoulders", "none", "athena_emote_hot_music");
          case 13:
          CreateEmote(client, "Emote_Facepalm", "none", "athena_emote_facepalm_foley_01");
          case 14:
          CreateEmote(client, "Emote_Fishing", "none", "fishing");
          case 15:
          CreateEmote(client, "Emote_Flex", "none", "flexing");
          case 16:
          CreateEmote(client, "Emote_golfclap", "none", "clapping");
          case 17:
          CreateEmote(client, "Emote_HandSignals", "none", "");
          case 18:
          CreateEmote(client, "Emote_HeelClick", "none", "emote_heelclick");
          case 19:
          CreateEmote(client, "Emote_Hotstuff", "none", "emote_hotstuff"); 
          case 20:
          CreateEmote(client, "Emote_IBreakYou", "none", "");  
          case 21:
          CreateEmote(client, "Emote_IHeartYou", "none", "iheartyou");
          case 22:
          CreateEmote(client, "Emote_Kung-Fu_Salute", "none", "");
          case 23:
          CreateEmote(client, "Emote_Laugh", "Emote_Laugh_CT", "emote_laugh_01");    
          case 24:
          CreateEmote(client, "Emote_Luchador", "none", "emote_luchador");
          case 25:
          CreateEmote(client, "Emote_Make_It_Rain", "none", "athena_emote_makeitrain_music");
          case 26:
          CreateEmote(client, "Emote_NotToday", "none", ""); 
          case 27:
          CreateEmote(client, "Emote_RockPaperScissor_Paper", "none", "");
          case 28:
          CreateEmote(client, "Emote_RockPaperScissor_Rock", "none", "");
          case 29:
          CreateEmote(client, "Emote_RockPaperScissor_Scissor", "none", "");
          case 30:
          CreateEmote(client, "Emote_Salt", "none", "");
          case 31:
          CreateEmote(client, "Emote_Salute", "none", "athena_emote_salute_foley_01");
          case 32:
          CreateEmote(client, "Emote_Snap", "none", "emote_snap1");
          case 33:
          CreateEmote(client, "Emote_StageBow", "none", "emote_stagebow");   
          case 34:
          CreateEmote(client, "Emote_Wave2", "none", "");
          case 35:
          CreateEmote(client, "Emote_Yeet", "none", "emote_yeet");
          case 36:
          CreateEmote(client, "Emote_Cena", "none", "cant_c_me");
          case 37:
          CreateEmote(client, "Emote_Lebron", "none", "lebronjame");
          
        }
      }
      menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
    }
    case MenuAction_Cancel:
    {
      if(param2 == MenuCancel_ExitBack)
      {
        Menu_Dance(client);
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////
//Dances Menu
////////////////////////////////////////////////////////////////////////////////////////////

Action DancesMenu(int client)
{
  char sBuffer[32];
  g_cvFlagDancesMenu.GetString(sBuffer, sizeof(sBuffer));

  if (!CheckAdminFlags(client, ReadFlagString(sBuffer)))
  {
    CPrintToChat(client, "%t", "NO_DANCES_ACCESS_FLAG");
    return Plugin_Handled;
  }
  Menu menu = new Menu(MenuHandlerDances);
  
  char title[65];
  Format(title, sizeof(title), "%T:", "TITLE_DANCES_MENU", client);
  menu.SetTitle(title);	
  
  AddTranslatedMenuItem(menu, "1", "DanceMoves", client);
  AddTranslatedMenuItem(menu, "2", "Emote_Mask_Off_Intro", client);
  AddTranslatedMenuItem(menu, "3", "Emote_Zippy_Dance", client);
  AddTranslatedMenuItem(menu, "4", "ElectroShuffle", client);
  AddTranslatedMenuItem(menu, "5", "Emote_AerobicChamp", client);
  AddTranslatedMenuItem(menu, "6", "Emote_Bendy", client);
  AddTranslatedMenuItem(menu, "7", "Emote_BandOfTheFort", client);
  AddTranslatedMenuItem(menu, "8", "Emote_Boogie_Down_Intro", client);	
  AddTranslatedMenuItem(menu, "9", "Emote_Capoeira", client);
  AddTranslatedMenuItem(menu, "10", "Emote_Charleston", client);
  AddTranslatedMenuItem(menu, "11", "Emote_Chicken", client);
  AddTranslatedMenuItem(menu, "12", "Emote_Dance_NoBones", client);	
  AddTranslatedMenuItem(menu, "13", "Emote_Dance_Shoot", client);
  AddTranslatedMenuItem(menu, "14", "Emote_Dance_SwipeIt", client);
  AddTranslatedMenuItem(menu, "15", "Emote_Dance_Disco_T3", client);
  AddTranslatedMenuItem(menu, "16", "Emote_DG_Disco", client);	
  AddTranslatedMenuItem(menu, "17", "Emote_Dance_Worm", client);
  AddTranslatedMenuItem(menu, "18", "Emote_Dance_Loser", client);
  AddTranslatedMenuItem(menu, "19", "Emote_Dance_Breakdance", client);
  AddTranslatedMenuItem(menu, "20", "Emote_Dance_Pump", client);	
  AddTranslatedMenuItem(menu, "21", "Emote_Dance_RideThePony", client);
  AddTranslatedMenuItem(menu, "22", "Emote_Dab", client);
  AddTranslatedMenuItem(menu, "23", "Emote_EasternBloc_Start", client);
  AddTranslatedMenuItem(menu, "24", "Emote_FancyFeet", client);	
  AddTranslatedMenuItem(menu, "25", "Emote_FlossDance", client);
  AddTranslatedMenuItem(menu, "26", "Emote_FlippnSexy", client);
  AddTranslatedMenuItem(menu, "27", "Emote_Fresh", client);
  AddTranslatedMenuItem(menu, "28", "Emote_GrooveJam", client);	
  AddTranslatedMenuItem(menu, "29", "Emote_guitar", client);
  AddTranslatedMenuItem(menu, "30", "Emote_Hillbilly_Shuffle_Intro", client);
  AddTranslatedMenuItem(menu, "31", "Emote_Hiphop_01", client);
  AddTranslatedMenuItem(menu, "32", "Emote_Hula_Start", client);	
  AddTranslatedMenuItem(menu, "33", "Emote_InfiniDab_Intro", client);
  AddTranslatedMenuItem(menu, "34", "Emote_Intensity_Start", client);
  AddTranslatedMenuItem(menu, "35", "Emote_IrishJig_Start", client);
  AddTranslatedMenuItem(menu, "36", "Emote_KoreanEagle", client);	
  AddTranslatedMenuItem(menu, "37", "Emote_Kpop_02", client);
  AddTranslatedMenuItem(menu, "38", "Emote_LivingLarge", client);
  AddTranslatedMenuItem(menu, "39", "Emote_Maracas", client);
  AddTranslatedMenuItem(menu, "40", "Emote_PopLock", client);
  AddTranslatedMenuItem(menu, "41", "Emote_PopRock", client);
  AddTranslatedMenuItem(menu, "42", "Emote_RobotDance", client);
  AddTranslatedMenuItem(menu, "43", "Emote_T-Rex", client);	
  AddTranslatedMenuItem(menu, "44", "Emote_TechnoZombie", client);
  AddTranslatedMenuItem(menu, "45", "Emote_Twist", client);
  AddTranslatedMenuItem(menu, "46", "Emote_WarehouseDance_Start", client);
  AddTranslatedMenuItem(menu, "47", "Emote_Wiggle", client);
  AddTranslatedMenuItem(menu, "48", "Emote_Youre_Awesome", client);
  AddTranslatedMenuItem(menu, "49", "Emote_Smooth_Moves", client);
  AddTranslatedMenuItem(menu, "50", "Emote_Friday13", client);
  AddTranslatedMenuItem(menu, "51", "Emote_Thanos_Twerk", client);
  AddTranslatedMenuItem(menu, "52", "Emote_Gangnam_Style", client);
  AddTranslatedMenuItem(menu, "53", "Emote_InDaGhetto", client);
  AddTranslatedMenuItem(menu, "54", "Emote_BlindingLights", client);	
  AddTranslatedMenuItem(menu, "55", "Emote_Griddy", client);	
  AddTranslatedMenuItem(menu, "56", "Emote_ILikeToMoveIt", client);	
  AddTranslatedMenuItem(menu, "57", "Emote_Macarena", client);	
  AddTranslatedMenuItem(menu, "58", "Emote_NeverGonna", client);	
  AddTranslatedMenuItem(menu, "59", "Emote_NinjaStyle", client);	
  AddTranslatedMenuItem(menu, "60", "Emote_PumpkinDance", client);	
  AddTranslatedMenuItem(menu, "61", "Emote_PumpUpTheJam", client);	
  AddTranslatedMenuItem(menu, "62", "Emote_Renegade", client);	
  AddTranslatedMenuItem(menu, "63", "Emote_RushinAround", client);	
  AddTranslatedMenuItem(menu, "64", "Emote_SaySo", client);	
  AddTranslatedMenuItem(menu, "65", "Emote_Stuck", client);	
  AddTranslatedMenuItem(menu, "66", "Emote_ToosieSlide", client);
  AddTranslatedMenuItem(menu, "67", "Emote_AirShredder", client);
  AddTranslatedMenuItem(menu, "68", "Emote_Crossbounce", client);
  AddTranslatedMenuItem(menu, "69", "Emote_DistractionDance", client);
  AddTranslatedMenuItem(menu, "70", "Emote_Headbanger", client);
  AddTranslatedMenuItem(menu, "71", "Emote_HitchHiker", client);
  AddTranslatedMenuItem(menu, "72", "Emote_ItsGoTime", client);
  AddTranslatedMenuItem(menu, "73", "Emote_KneeSlapper", client);
  AddTranslatedMenuItem(menu, "74", "Emote_Showstopper", client);
  AddTranslatedMenuItem(menu, "75", "Emote_Sprinkler", client);
  AddTranslatedMenuItem(menu, "76", "Emote_Gmod", client);
  AddTranslatedMenuItem(menu, "77", "Emote_ChickenDance", client);
  AddTranslatedMenuItem(menu, "78", "Emote_Ghostbusters", client);
  AddTranslatedMenuItem(menu, "79", "Emote_Martian", client);
  AddTranslatedMenuItem(menu, "80", "Emote_RememberMe_Intro", client);
  AddTranslatedMenuItem(menu, "81", "Emote_Rollie", client);
  AddTranslatedMenuItem(menu, "82", "Emote_Scenario", client);
  AddTranslatedMenuItem(menu, "83", "Emote_Tpose", client);
  AddTranslatedMenuItem(menu, "84", "Emote_SmoothDrive", client);

  menu.ExitButton = true;
  menu.ExitBackButton = true;
  menu.Display(client, MENU_TIME_FOREVER);
 
  return Plugin_Handled;
}

void MenuHandlerDances(Menu menu, MenuAction action, int client, int param2)
{
  switch (action)
  {		
    case MenuAction_Select:
    {
      char info[16];
      if(menu.GetItem(param2, info, sizeof(info)))
      {
        int iParam2 = StringToInt(info);

        switch (iParam2)
        {
          case 1:
          CreateEmote(client, "DanceMoves", "none", "ninja_dance_01");
          case 2:
          CreateEmote(client, "Emote_Mask_Off_Intro", "Emote_Mask_Off_Loop", "hip_hop_good_vibes_mix_01_loop");         
          case 3:
          CreateEmote(client, "Emote_Zippy_Dance", "none", "emote_zippy_a");
          case 4:
          CreateEmote(client, "ElectroShuffle", "none", "athena_emote_electroshuffle_music");
          case 5:
          CreateEmote(client, "Emote_AerobicChamp", "none", "emote_aerobics_01");
          case 6:
          CreateEmote(client, "Emote_Bendy", "none", "athena_music_emotes_bendy");
          case 7:
          CreateEmote(client, "Emote_BandOfTheFort", "none", "athena_emote_bandofthefort_music"); 
          case 8:
          CreateEmote(client, "Emote_Boogie_Down_Intro", "Emote_Boogie_Down", "emote_boogiedown");  
          case 9:
          CreateEmote(client, "Emote_Capoeira", "none", "emote_capoeira");
          case 10:
          CreateEmote(client, "Emote_Charleston", "none", "athena_emote_flapper_music");
          case 11:
          CreateEmote(client, "Emote_Chicken", "none", "athena_emote_chicken_foley_01");
          case 12:
          CreateEmote(client, "Emote_Dance_NoBones", "none", "athena_emote_music_boneless");
          case 13:
          CreateEmote(client, "Emote_Dance_Shoot", "none", "athena_emotes_music_shoot_v7");
          case 14:
          CreateEmote(client, "Emote_Dance_SwipeIt", "none", "athena_emotes_music_swipeit");
          case 15:
          CreateEmote(client, "Emote_Dance_Disco_T3", "none", "athena_emote_disco");
          case 16:
          CreateEmote(client, "Emote_DG_Disco", "none", "athena_emote_disco");          
          case 17:
          CreateEmote(client, "Emote_Dance_Worm", "none", "athena_emote_worm_music");
          case 18:
          CreateEmote(client, "Emote_Dance_Loser", "Emote_Dance_Loser_CT", "athena_music_emotes_takethel");
          case 19:
          CreateEmote(client, "Emote_Dance_Breakdance", "none", "athena_emote_breakdance_music");
          case 20:
          CreateEmote(client, "Emote_Dance_Pump", "none", "emote_groove_jam_a");
          case 21:
          CreateEmote(client, "Emote_Dance_RideThePony", "none", "athena_emote_ridethepony_music_01");
          case 22:
          CreateEmote(client, "Emote_Dab", "none", "");
          case 23:
          CreateEmote(client, "Emote_EasternBloc_Start", "Emote_EasternBloc", "eastern_bloc_musc_setup_d");
          case 24:
          CreateEmote(client, "Emote_FancyFeet", "Emote_FancyFeet_CT", "athena_emotes_lankylegs_loop_02"); 
          case 25:
          CreateEmote(client, "Emote_FlossDance", "none", "athena_emote_floss_music");
          case 26:
          CreateEmote(client, "Emote_FlippnSexy", "none", "emote_flippnSexy");
          case 27:
          CreateEmote(client, "Emote_Fresh", "none", "athena_emote_fresh_music");
          case 28:
          CreateEmote(client, "Emote_GrooveJam", "none", "emote_groove_jam_a"); 
          case 29:
          CreateEmote(client, "Emote_guitar", "none", "br_emote_shred_guitar_mix_03_loop"); 
          case 30:
          CreateEmote(client, "Emote_Hillbilly_Shuffle_Intro", "Emote_Hillbilly_Shuffle", "emote_hillbilly_shuffle"); 
          case 31:
          CreateEmote(client, "Emote_Hiphop_01", "Emote_Hip_Hop", "s5_hiphop_breakin_132bmp_loop"); 
          case 32:
          CreateEmote(client, "Emote_Hula_Start", "Emote_Hula", "emote_hula_01");
          case 33:
          CreateEmote(client, "Emote_InfiniDab_Intro", "Emote_InfiniDab_Loop", "athena_emote_infinidab"); 
          case 34:
          CreateEmote(client, "Emote_Intensity_Start", "Emote_Intensity_Loop", "emote_intensity");
          case 35:
          CreateEmote(client, "Emote_IrishJig_Start", "Emote_IrishJig", "emote_irish_jig_foley_music_loop");
          case 36:
          CreateEmote(client, "Emote_KoreanEagle", "none", "athena_music_emotes_koreaneagle");
          case 37:
          CreateEmote(client, "Emote_Kpop_02", "none", "emote_kpop_01");  
          case 38:
          CreateEmote(client, "Emote_LivingLarge", "none", "emote_livinglarge_a");  
          case 39:
          CreateEmote(client, "Emote_Maracas", "none", "emote_samba_new_b");
          case 40:
          CreateEmote(client, "Emote_PopLock", "none", "athena_emote_poplock");
          case 41:
          CreateEmote(client, "Emote_PopRock", "none", "emote_poprock_01");   
          case 42:
          CreateEmote(client, "Emote_RobotDance", "none", "athena_emote_robot_music");  
          case 43:
          CreateEmote(client, "Emote_T-Rex", "none", "emote_dino_complete");
          case 44:
          CreateEmote(client, "Emote_TechnoZombie", "none", "athena_emote_founders_music");   
          case 45:
          CreateEmote(client, "Emote_Twist", "none", "athena_emotes_music_twist");
          case 46:
          CreateEmote(client, "Emote_WarehouseDance_Start", "Emote_WarehouseDance_Loop", "emote_warehouse");
          case 47:
          CreateEmote(client, "Emote_Wiggle", "none", "wiggle_music_loop");
          case 48:
          CreateEmote(client, "Emote_Youre_Awesome", "none", "youre_awesome_emote_music");
          case 49:
          CreateEmote(client, "Emote_Smooth_Moves", "none", "smooth_moves");
          case 50:
          CreateEmote(client, "Emote_Friday13", "none", "california_girls");
          case 51:
          CreateEmote(client, "Emote_Thanos_Twerk", "none", "thanos_twerk");    
          case 52:
          CreateEmote(client, "Emote_Gangnam_Style", "none", "psychic");    
          case 53:
          CreateEmote(client, "Emote_InDaGhetto", "none", "emote_vivid"); 
          case 54:
          CreateEmote(client, "Emote_BlindingLights", "none", "emote_autumn_tea");
          case 55:
          CreateEmote(client, "Emote_Griddy", "none", "emote_griddles_music");
          case 56:
          CreateEmote(client, "Emote_ILikeToMoveIt", "none", "emote_jumpingjoy");
          case 57:
          CreateEmote(client, "Emote_Macarena", "none", "emote_macaroon_music");
          case 58:
          CreateEmote(client, "Emote_NeverGonna", "none", "emote_nevergonna");
          case 59:
          CreateEmote(client, "Emote_NinjaStyle", "none", "emote_tour_bus");
          case 60:
          CreateEmote(client, "Emote_PumpkinDance", "none", "pumpkin_dance");
          case 61:
          CreateEmote(client, "Emote_PumpUpTheJam", "none", "deflated_emote_music");
          case 62:
          CreateEmote(client, "Emote_Renegade", "none", "emote_just_home_music");
          case 63:
          CreateEmote(client, "Emote_RushinAround", "none", "emote_comrade");
          case 64:
          CreateEmote(client, "Emote_SaySo", "none", "emote_hotpink");
          case 65:
          CreateEmote(client, "Emote_Stuck", "none", "emote_downward");
          case 66:
          CreateEmote(client, "Emote_ToosieSlide", "none", "emote_art_giant");
          case 67:
          CreateEmote(client, "Emote_AirShredder", "none", "air_guitar_emote");
          case 68:
          CreateEmote(client, "Emote_Crossbounce", "none", "emote_blaster");
          case 69:
          CreateEmote(client, "Emote_DistractionDance", "none", "distraction");
          case 70:
          CreateEmote(client, "Emote_Headbanger", "none", "headbanger_music");
          case 71:
          CreateEmote(client, "Emote_HitchHiker", "none", "hitchhiker_music");
          case 72:
          CreateEmote(client, "Emote_ItsGoTime", "none", "itsgotime_music");
          case 73:
          CreateEmote(client, "Emote_KneeSlapper", "none", "kneeslapper_music");
          case 74:
          CreateEmote(client, "Emote_Showstopper", "none", "showstopper_music");
          case 75:
          CreateEmote(client, "Emote_Sprinkler", "none", "sprinkler_music");
          case 76:
          CreateEmote(client, "Emote_Gmod", "none", "gmod_select");
          case 77:
          CreateEmote(client, "Emote_ChickenDance", "none", "pollo_dance");
          case 78:
          CreateEmote(client, "Emote_Ghostbusters", "none", "toastbust");
          case 79:
          CreateEmote(client, "Emote_Martian", "none", "leave_the_door");
          case 80:
          CreateEmote(client, "Emote_RememberMe_Intro", "Emote_RememberMe_Loop", "unforgettable");
          case 81:
          CreateEmote(client, "Emote_Rollie", "none", "rollie_rollie");
          case 82:
          CreateEmote(client, "Emote_Scenario", "none", "scenariooo");
          case 83:
          CreateEmote(client, "Emote_Tpose", "none", "");
          case 84:
          CreateEmote(client, "Emote_SmoothDrive", "none", "dropit");
        }
      }
      menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
    }
    case MenuAction_Cancel:
    {
      if(param2 == MenuCancel_ExitBack)
      {
        Menu_Dance(client);
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////
//Random
////////////////////////////////////////////////////////////////////////////////////////////

Action RandomEmote(int i)
{
  char sBuffer[32];
  g_cvFlagEmotesMenu.GetString(sBuffer, sizeof(sBuffer));

  if (!CheckAdminFlags(i, ReadFlagString(sBuffer)))
  {
    CPrintToChat(i, "%t", "NO_EMOTES_ACCESS_FLAG");
    return Plugin_Handled;
  }
  
  int number = GetRandomInt(1, 37);
  
  switch (number)
  {
    case 1:
    CreateEmote(i, "Emote_Fonzie_Pistol", "none", "");
    case 2:
    CreateEmote(i, "Emote_Bring_It_On", "none", "");
    case 3:
    CreateEmote(i, "Emote_ThumbsDown", "none", "");
    case 4:
    CreateEmote(i, "Emote_ThumbsUp", "none", "");
    case 5:
    CreateEmote(i, "Emote_Celebration_Loop", "", "jubilation");
    case 6:
    CreateEmote(i, "Emote_BlowKiss", "none", "blowkiss");
    case 7:
    CreateEmote(i, "Emote_Calculated", "none", "");
    case 8:
    CreateEmote(i, "Emote_Confused", "none", "");
    case 9:
    CreateEmote(i, "Emote_Chug", "none", "gogogo");
    case 10:
    CreateEmote(i, "Emote_Cry", "none", "bananacry");
    case 11:
    CreateEmote(i, "Emote_DustingOffHands", "none", "");
    case 12:
    CreateEmote(i, "Emote_DustOffShoulders", "none", "athena_emote_hot_music");
    case 13:
    CreateEmote(i, "Emote_Facepalm", "none", "athena_emote_facepalm_foley_01");
    case 14:
    CreateEmote(i, "Emote_Fishing", "none", "fishing");
    case 15:
    CreateEmote(i, "Emote_Flex", "none", "flexing");
    case 16:
    CreateEmote(i, "Emote_golfclap", "none", "clapping");
    case 17:
    CreateEmote(i, "Emote_HandSignals", "none", "");
    case 18:
    CreateEmote(i, "Emote_HeelClick", "none", "emote_heelclick");
    case 19:
    CreateEmote(i, "Emote_Hotstuff", "none", "emote_hotstuff");  
    case 20:
    CreateEmote(i, "Emote_IBreakYou", "none", ""); 
    case 21:
    CreateEmote(i, "Emote_IHeartYou", "none", "iheartyou");
    case 22:
    CreateEmote(i, "Emote_Kung-Fu_Salute", "none", "");
    case 23:
    CreateEmote(i, "Emote_Laugh", "Emote_Laugh_CT", "emote_laugh_01");   
    case 24:
    CreateEmote(i, "Emote_Luchador", "none", "emote_luchador");
    case 25:
    CreateEmote(i, "Emote_Make_It_Rain", "none", "athena_emote_makeitrain_music");
    case 26:
    CreateEmote(i, "Emote_NotToday", "none", "");  
    case 27:
    CreateEmote(i, "Emote_RockPaperScissor_Paper", "none", "");
    case 28:
    CreateEmote(i, "Emote_RockPaperScissor_Rock", "none", "");
    case 29:
    CreateEmote(i, "Emote_RockPaperScissor_Scissor", "none", "");
    case 30:
    CreateEmote(i, "Emote_Salt", "none", "");
    case 31:
    CreateEmote(i, "Emote_Salute", "none", "athena_emote_salute_foley_01");
    case 32:
    CreateEmote(i, "Emote_Snap", "none", "emote_snap1");
    case 33:
    CreateEmote(i, "Emote_StageBow", "none", "emote_stagebow");    
    case 34:
    CreateEmote(i, "Emote_Wave2", "none", "");
    case 35:
    CreateEmote(i, "Emote_Yeet", "none", "emote_yeet");
    case 36:
    CreateEmote(i, "Emote_Cena", "none", "cant_c_me");
    case 37:
    CreateEmote(i, "Emote_Lebron", "none", "lebronjame");
  }
  return Plugin_Handled;
}

Action RandomDance(int i)
{
  char sBuffer[32];
  g_cvFlagDancesMenu.GetString(sBuffer, sizeof(sBuffer));

  if (!CheckAdminFlags(i, ReadFlagString(sBuffer)))
  {
    CPrintToChat(i, "%t", "NO_DANCES_ACCESS_FLAG");
    return Plugin_Handled;
  }
  int number = GetRandomInt(1, 84);
  
  switch (number)
  {
            case 1:
            CreateEmote(i, "DanceMoves", "none", "ninja_dance_01");
            case 2:
            CreateEmote(i, "Emote_Mask_Off_Intro", "Emote_Mask_Off_Loop", "hip_hop_good_vibes_mix_01_loop");            
            case 3:
            CreateEmote(i, "Emote_Zippy_Dance", "none", "emote_zippy_a");
            case 4:
            CreateEmote(i, "ElectroShuffle", "none", "athena_emote_electroshuffle_music");
            case 5:
            CreateEmote(i, "Emote_AerobicChamp", "none", "emote_aerobics_01");
            case 6:
            CreateEmote(i, "Emote_Bendy", "none", "athena_music_emotes_bendy");
            case 7:
            CreateEmote(i, "Emote_BandOfTheFort", "none", "athena_emote_bandofthefort_music");  
            case 8:
            CreateEmote(i, "Emote_Boogie_Down_Intro", "Emote_Boogie_Down", "emote_boogiedown"); 
            case 9:
            CreateEmote(i, "Emote_Capoeira", "none", "emote_capoeira");
            case 10:
            CreateEmote(i, "Emote_Charleston", "none", "athena_emote_flapper_music");
            case 11:
            CreateEmote(i, "Emote_Chicken", "none", "athena_emote_chicken_foley_01");
            case 12:
            CreateEmote(i, "Emote_Dance_NoBones", "none", "athena_emote_music_boneless");
            case 13:
            CreateEmote(i, "Emote_Dance_Shoot", "none", "athena_emotes_music_shoot_v7");
            case 14:
            CreateEmote(i, "Emote_Dance_SwipeIt", "none", "athena_emotes_music_swipeit");
            case 15:
            CreateEmote(i, "Emote_Dance_Disco_T3", "none", "athena_emote_disco");
            case 16:
            CreateEmote(i, "Emote_DG_Disco", "none", "athena_emote_disco");           
            case 17:
            CreateEmote(i, "Emote_Dance_Worm", "none", "athena_emote_worm_music");
            case 18:
            CreateEmote(i, "Emote_Dance_Loser", "Emote_Dance_Loser_CT", "athena_music_emotes_takethel");
            case 19:
            CreateEmote(i, "Emote_Dance_Breakdance", "none", "athena_emote_breakdance_music");
            case 20:
            CreateEmote(i, "Emote_Dance_Pump", "none", "emote_groove_jam_a");
            case 21:
            CreateEmote(i, "Emote_Dance_RideThePony", "none", "athena_emote_ridethepony_music_01");
            case 22:
            CreateEmote(i, "Emote_Dab", "none", "");
            case 23:
            CreateEmote(i, "Emote_EasternBloc_Start", "Emote_EasternBloc", "eastern_bloc_musc_setup_d");
            case 24:
            CreateEmote(i, "Emote_FancyFeet", "Emote_FancyFeet_CT", "athena_emotes_lankylegs_loop_02"); 
            case 25:
            CreateEmote(i, "Emote_FlossDance", "none", "athena_emote_floss_music");
            case 26:
            CreateEmote(i, "Emote_FlippnSexy", "none", "emote_flippnsexy");
            case 27:
            CreateEmote(i, "Emote_Fresh", "none", "athena_emote_fresh_music");
            case 28:
            CreateEmote(i, "Emote_GrooveJam", "none", "emote_groove_jam_a");  
            case 29:
            CreateEmote(i, "Emote_guitar", "none", "br_emote_shred_guitar_mix_03_loop");  
            case 30:
            CreateEmote(i, "Emote_Hillbilly_Shuffle_Intro", "Emote_Hillbilly_Shuffle", "emote_hillbilly_shuffle"); 
            case 31:
            CreateEmote(i, "Emote_Hiphop_01", "Emote_Hip_Hop", "s5_hiphop_breakin_132bmp_loop");  
            case 32:
            CreateEmote(i, "Emote_Hula_Start", "Emote_Hula", "emote_hula_01");
            case 33:
            CreateEmote(i, "Emote_InfiniDab_Intro", "Emote_InfiniDab_Loop", "athena_emote_infinidab");  
            case 34:
            CreateEmote(i, "Emote_Intensity_Start", "Emote_Intensity_Loop", "emote_intensity");
            case 35:
            CreateEmote(i, "Emote_IrishJig_Start", "Emote_IrishJig", "emote_irish_jig_foley_music_loop");
            case 36:
            CreateEmote(i, "Emote_KoreanEagle", "none", "athena_music_emotes_koreaneagle");
            case 37:
            CreateEmote(i, "Emote_Kpop_02", "none", "emote_kpop_01"); 
            case 38:
            CreateEmote(i, "Emote_LivingLarge", "none", "emote_livinglarge_a"); 
            case 39:
            CreateEmote(i, "Emote_Maracas", "none", "emote_samba_new_b");
            case 40:
            CreateEmote(i, "Emote_PopLock", "none", "athena_emote_poplock");
            case 41:
            CreateEmote(i, "Emote_PopRock", "none", "emote_poprock_01");    
            case 42:
            CreateEmote(i, "Emote_RobotDance", "none", "athena_emote_robot_music"); 
            case 43:
            CreateEmote(i, "Emote_T-Rex", "none", "emote_dino_complete");
            case 44:
            CreateEmote(i, "Emote_TechnoZombie", "none", "athena_emote_founders_music");    
            case 45:
            CreateEmote(i, "Emote_Twist", "none", "athena_emotes_music_twist");
            case 46:
            CreateEmote(i, "Emote_WarehouseDance_Start", "Emote_WarehouseDance_Loop", "emote_warehouse");
            case 47:
            CreateEmote(i, "Emote_Wiggle", "none", "wiggle_music_loop");
            case 48:
            CreateEmote(i, "Emote_Youre_Awesome", "none", "youre_awesome_emote_music");
            case 49:
            CreateEmote(i, "Emote_Smooth_Moves", "none", "smooth_moves");
            case 50:
            CreateEmote(i, "Emote_Friday13", "none", "california_girls");
            case 51:
            CreateEmote(i, "Emote_Thanos_Twerk", "none", "thanos_twerk");   
            case 52:
            CreateEmote(i, "Emote_Gangnam_Style", "none", "psychic");   
            case 53:
            CreateEmote(i, "Emote_InDaGhetto", "none", "emote_vivid");
            case 54:
            CreateEmote(i, "Emote_BlindingLights", "none", "emote_autumn_tea");
            case 55:
            CreateEmote(i, "Emote_Griddy", "none", "emote_griddles_music");
            case 56:
            CreateEmote(i, "Emote_ILikeToMoveIt", "none", "emote_jumpingjoy");
            case 57:
            CreateEmote(i, "Emote_Macarena", "none", "emote_macaroon_music");
            case 58:
            CreateEmote(i, "Emote_NeverGonna", "none", "emote_nevergonna");
            case 59:
            CreateEmote(i, "Emote_NinjaStyle", "none", "emote_tour_bus");
            case 60:
            CreateEmote(i, "Emote_PumpkinDance", "none", "pumpkin_dance");
            case 61:
            CreateEmote(i, "Emote_PumpUpTheJam", "none", "deflated_emote_music");
            case 62:
            CreateEmote(i, "Emote_Renegade", "none", "emote_just_home_music");
            case 63:
            CreateEmote(i, "Emote_RushinAround", "none", "emote_comrade");
            case 64:
            CreateEmote(i, "Emote_SaySo", "none", "emote_hotpink");
            case 65:
            CreateEmote(i, "Emote_Stuck", "none", "emote_downward");
            case 66:
            CreateEmote(i, "Emote_ToosieSlide", "none", "emote_art_giant");
            case 67:
            CreateEmote(i, "Emote_AirShredder", "none", "air_guitar_emote");
            case 68:
            CreateEmote(i, "Emote_Crossbounce", "none", "emote_blaster");
            case 69:
            CreateEmote(i, "Emote_DistractionDance", "none", "distraction");
            case 70:
            CreateEmote(i, "Emote_Headbanger", "none", "headbanger_music");
            case 71:
            CreateEmote(i, "Emote_HitchHiker", "none", "hitchhiker_music");
            case 72:
            CreateEmote(i, "Emote_ItsGoTime", "none", "itsgotime_music");
            case 73:
            CreateEmote(i, "Emote_KneeSlapper", "none", "kneeslapper_music");
            case 74:
            CreateEmote(i, "Emote_Showstopper", "none", "showstopper_music");
            case 75:
            CreateEmote(i, "Emote_Sprinkler", "none", "sprinkler_music");
            case 76:
            CreateEmote(i, "Emote_Gmod", "none", "gmod_select");
            case 77:
            CreateEmote(i, "Emote_ChickenDance", "none", "pollo_dance");
            case 78:
            CreateEmote(i, "Emote_Ghostbusters", "none", "toastbust");
            case 79:
            CreateEmote(i, "Emote_Martian", "none", "leave_the_door");
            case 80:
            CreateEmote(i, "Emote_RememberMe_Intro", "Emote_RememberMe_Loop", "unforgettable");
            case 81:
            CreateEmote(i, "Emote_Rollie", "none", "rollie_rollie");
            case 82:
            CreateEmote(i, "Emote_Scenario", "none", "scenariooo");
            case 83:
            CreateEmote(i, "Emote_Tpose", "none", "");
            case 84:
            CreateEmote(i, "Emote_SmoothDrive", "none", "dropit");
  }
  return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////////////////
//Admin Command sm_setemote and sm_doemote/sm_dodance
////////////////////////////////////////////////////////////////////////////////////////////

Action Command_Admin_Emotes(int client, int args)
{
  if (args < 1)
  {
    CReplyToCommand(client, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
    return Plugin_Handled;
  }
  
  char arg[65];
  GetCmdArg(1, arg, sizeof(arg));
  
  int amount=1;
  if (args > 1)
  {
    char arg2[3];
    GetCmdArg(2, arg2, sizeof(arg2));
    if (StringToIntEx(arg2, amount) < 1 || StringToIntEx(arg2, amount) > 86)
    {
      CReplyToCommand(client, "%t", "INVALID_EMOTE_ID");
      return Plugin_Handled;
    }
  }
  
  char target_name[MAX_TARGET_LENGTH];
  int target_list[MAXPLAYERS], target_count;
  bool tn_is_ml;
  
  if ((target_count = ProcessTargetString(
      arg,
      client,
      target_list,
      MAXPLAYERS,
      COMMAND_FILTER_ALIVE,
      target_name,
      sizeof(target_name),
      tn_is_ml)) <= 0)
  {
    ReplyToTargetError(client, target_count);
    return Plugin_Handled;
  }
  
  
  for (int i = 0; i < target_count; i++)
  {
    PerformEmote(client, target_list[i], amount);
  }	
  
  return Plugin_Handled;
}

public Action Command_Force_Emote(int client, int args)
{
  for(int i = 0; i <= MaxClients; i++)
  {
    if (!IsValidClient(i))
      continue;
    RandomDance(i);
  }
  return Plugin_Handled;
}

public Action Command_Do_Emotes(int client, int args) //sm_doemote/sm_dodance
{
  if (args < 1)
  {
    CReplyToCommand(client, "[SM] Usage: sm_dodance [Emote ID]");
    CReplyToCommand(client, "[SM] Usage: sm_doemote [Emote ID]");
    return Plugin_Handled;
  }
  
  int amount=1;
  if (args > 0)
  {
    char arg1[4];
    GetCmdArg(1, arg1, sizeof(arg1));
    if (StringToIntEx(arg1, amount) < 1 || StringToIntEx(arg1, amount) > 133)
    {
      CReplyToCommand(client, "%t", "INVALID_EMOTE_ID");
      return Plugin_Handled;
    }
  }
  
  PerformEmote(client, client, amount);
  
  return Plugin_Handled;
}
public Action Command_Random_Emote(int client, int args) //sm_rdance
{
  PerformEmote(client, client, GetRandomInt(37,120));

  return Plugin_Handled;
}

void PerformEmote(int client, int target, int amount)
{
  switch (amount)
  {
          case 1:
          CreateEmote(target, "Emote_Fonzie_Pistol", "none", "");
          case 2:
          CreateEmote(target, "Emote_Bring_It_On", "none", "");
          case 3:
          CreateEmote(target, "Emote_ThumbsDown", "none", "");
          case 4:
          CreateEmote(target, "Emote_ThumbsUp", "none", "");
          case 5:
          CreateEmote(target, "Emote_Celebration_Loop", "", "jubilation");
          case 6:          
		  CreateEmote(target, "Emote_BlowKiss", "none", "blowkiss");
		  case 7:
          CreateEmote(target, "Emote_Calculated", "none", "");
          case 8:
          CreateEmote(target, "Emote_Confused", "none", "");
          case 9:
          CreateEmote(target, "Emote_Chug", "none", "gogogo");
          case 10:
          CreateEmote(target, "Emote_Cry", "none", "bananacry");
          case 11:
          CreateEmote(target, "Emote_DustingOffHands", "none", "");
          case 12:
          CreateEmote(target, "Emote_DustOffShoulders", "none", "athena_emote_hot_music");
          case 13:
          CreateEmote(target, "Emote_Facepalm", "none", "athena_emote_facepalm_foley_01");
          case 14:
          CreateEmote(target, "Emote_Fishing", "none", "fishing");
          case 15:
          CreateEmote(target, "Emote_Flex", "none", "flexing");
          case 16:
          CreateEmote(target, "Emote_golfclap", "none", "clapping");
          case 17:
          CreateEmote(target, "Emote_HandSignals", "none", "");
          case 18:
          CreateEmote(target, "Emote_HeelClick", "none", "emote_heelclick");
          case 19:
          CreateEmote(target, "Emote_Hotstuff", "none", "emote_hotstuff"); 
          case 20:
          CreateEmote(target, "Emote_IBreakYou", "none", "");  
          case 21:
          CreateEmote(target, "Emote_IHeartYou", "none", "iheartyou");
          case 22:
          CreateEmote(target, "Emote_Kung-Fu_Salute", "none", "");
          case 23:
          CreateEmote(target, "Emote_Laugh", "Emote_Laugh_CT", "emote_laugh_01");    
          case 24:
          CreateEmote(target, "Emote_Luchador", "none", "emote_luchador");
          case 25:
          CreateEmote(target, "Emote_Make_It_Rain", "none", "athena_emote_makeitrain_music");
          case 26:
          CreateEmote(target, "Emote_NotToday", "none", ""); 
          case 27:
          CreateEmote(target, "Emote_RockPaperScissor_Paper", "none", "");
          case 28:
          CreateEmote(target, "Emote_RockPaperScissor_Rock", "none", "");
          case 29:
          CreateEmote(target, "Emote_RockPaperScissor_Scissor", "none", "");
          case 30:
          CreateEmote(target, "Emote_Salt", "none", "");
          case 31:
          CreateEmote(target, "Emote_Salute", "none", "athena_emote_salute_foley_01");
          case 32:
          CreateEmote(target, "Emote_SmoothDrive", "none", "dropit"); //
          case 33:
          CreateEmote(target, "Emote_Snap", "none", "emote_snap1");
          case 34:
          CreateEmote(target, "Emote_StageBow", "none", "emote_stagebow");     
          case 35:
          CreateEmote(target, "Emote_Wave2", "none", "");
          case 36:
          CreateEmote(target, "Emote_Yeet", "none", "emote_yeet"); 
          case 37:
          CreateEmote(target, "DanceMoves", "none", "ninja_dance_01");
          case 38:
          CreateEmote(target, "Emote_Mask_Off_Intro", "Emote_Mask_Off_Loop", "hip_hop_good_vibes_mix_01_loop");           
          case 39:
          CreateEmote(target, "Emote_Zippy_Dance", "none", "emote_zippy_a");
          case 40:
          CreateEmote(target, "ElectroShuffle", "none", "athena_emote_electroshuffle_music");
          case 41:
          CreateEmote(target, "Emote_AerobicChamp", "none", "emote_aerobics_01");
          case 42:
          CreateEmote(target, "Emote_Bendy", "none", "athena_music_emotes_bendy");
          case 43:
          CreateEmote(target, "Emote_BandOfTheFort", "none", "athena_emote_bandofthefort_music"); 
          case 44:
          CreateEmote(target, "Emote_Boogie_Down_Intro", "Emote_Boogie_Down", "emote_boogiedown");  
          case 45:
          CreateEmote(target, "Emote_Capoeira", "none", "emote_capoeira");
          case 46:
          CreateEmote(target, "Emote_Charleston", "none", "athena_emote_flapper_music");
          case 47:
          CreateEmote(target, "Emote_Chicken", "none", "athena_emote_chicken_foley_01");
          case 48:
          CreateEmote(target, "Emote_Dance_NoBones", "none", "athena_emote_music_boneless");
          case 49:
          CreateEmote(target, "Emote_Dance_Shoot", "none", "athena_emotes_music_shoot_v7");
          case 50:
          CreateEmote(target, "Emote_Dance_SwipeIt", "none", "athena_emotes_music_swipeit");
          case 51:
          CreateEmote(target, "Emote_Dance_Disco_T3", "none", "athena_emote_disco");
          case 52:
          CreateEmote(target, "Emote_DG_Disco", "none", "athena_emote_disco");          
          case 53:
          CreateEmote(target, "Emote_Dance_Worm", "none", "athena_emote_worm_music");
          case 54:
          CreateEmote(target, "Emote_Dance_Loser", "Emote_Dance_Loser_CT", "athena_music_emotes_takethel");
          case 55:
          CreateEmote(target, "Emote_Dance_Breakdance", "none", "athena_emote_breakdance_music");
          case 56:
          CreateEmote(target, "Emote_Dance_Pump", "none", "emote_groove_jam_a");
          case 57:
          CreateEmote(target, "Emote_Dance_RideThePony", "none", "athena_emote_ridethepony_music_01");
          case 58:
          CreateEmote(target, "Emote_Dab", "none", "");
          case 59:
          CreateEmote(target, "Emote_EasternBloc_Start", "Emote_EasternBloc", "eastern_bloc_musc_setup_d");
          case 60:
          CreateEmote(target, "Emote_FancyFeet", "Emote_FancyFeet_CT", "athena_emotes_lankylegs_loop_02"); 
          case 61:
          CreateEmote(target, "Emote_FlossDance", "none", "athena_emote_floss_music");
          case 62:
          CreateEmote(target, "Emote_FlippnSexy", "none", "emote_flippnsexy");
          case 63:
          CreateEmote(target, "Emote_Fresh", "none", "athena_emote_fresh_music");
          case 64:
          CreateEmote(target, "Emote_GrooveJam", "none", "emote_groove_jam_a"); 
          case 65:
          CreateEmote(target, "Emote_guitar", "none", "br_emote_shred_guitar_mix_03_loop"); 
          case 66:
          CreateEmote(target, "Emote_Hillbilly_Shuffle_Intro", "Emote_Hillbilly_Shuffle", "emote_hillbilly_shuffle"); 
          case 67:
          CreateEmote(target, "Emote_Hiphop_01", "Emote_Hip_Hop", "s5_hiphop_breakin_132bmp_loop"); 
          case 68:
          CreateEmote(target, "Emote_Hula_Start", "Emote_Hula", "emote_hula_01");
          case 69:
          CreateEmote(target, "Emote_InfiniDab_Intro", "Emote_InfiniDab_Loop", "athena_emote_infinidab"); 
          case 70:
          CreateEmote(target, "Emote_Intensity_Start", "Emote_Intensity_Loop", "emote_intensity");
          case 71:
          CreateEmote(target, "Emote_IrishJig_Start", "Emote_IrishJig", "emote_irish_jig_foley_music_loop");
          case 72:
          CreateEmote(target, "Emote_KoreanEagle", "none", "athena_music_emotes_koreaneagle");
          case 73:
          CreateEmote(target, "Emote_Kpop_02", "none", "emote_kpop_01");  
          case 74:
          CreateEmote(target, "Emote_LivingLarge", "none", "emote_livinglarge_a");  
          case 75:
          CreateEmote(target, "Emote_Maracas", "none", "emote_samba_new_b");
          case 76:
          CreateEmote(target, "Emote_PopLock", "none", "athena_emote_poplock");
          case 77:
          CreateEmote(target, "Emote_PopRock", "none", "emote_poprock_01");   
          case 78:
          CreateEmote(target, "Emote_RobotDance", "none", "athena_emote_robot_music");  
          case 79:
          CreateEmote(target, "Emote_T-Rex", "none", "emote_dino_complete");
          case 80:
          CreateEmote(target, "Emote_TechnoZombie", "none", "athena_emote_founders_music");   
          case 81:
          CreateEmote(target, "Emote_Twist", "none", "athena_emotes_music_twist");
          case 82:
          CreateEmote(target, "Emote_WarehouseDance_Start", "Emote_WarehouseDance_Loop", "emote_warehouse");
          case 83:
          CreateEmote(target, "Emote_Wiggle", "none", "wiggle_music_loop");
          case 84:
          CreateEmote(target, "Emote_Youre_Awesome", "none", "youre_awesome_emote_music");
          case 85:
          CreateEmote(target, "Emote_Smooth_Moves", "none", "smooth_moves");
          case 86:
          CreateEmote(target, "Emote_Friday13", "none", "california_girls");
          case 87:
          CreateEmote(target, "Emote_Thanos_Twerk", "none", "thanos_twerk");   
          case 88:
          CreateEmote(target, "Emote_Gangnam_Style", "none", "psychic");   
          case 89:
          CreateEmote(target, "Emote_InDaGhetto", "none", "emote_vivid");
          case 90:
          CreateEmote(target, "Emote_BlindingLights", "none", "emote_autumn_tea");
          case 91:
          CreateEmote(target, "Emote_Griddy", "none", "emote_griddles_music");
          case 92:
          CreateEmote(target, "Emote_ILikeToMoveIt", "none", "emote_jumpingjoy");
          case 93:
          CreateEmote(target, "Emote_Macarena", "none", "emote_macaroon_music");
          case 94:
          CreateEmote(target, "Emote_NeverGonna", "none", "emote_nevergonna");
          case 95:
          CreateEmote(target, "Emote_NinjaStyle", "none", "emote_tour_bus");
          case 96:
          CreateEmote(target, "Emote_PumpkinDance", "none", "pumpkin_dance");
          case 97:
          CreateEmote(target, "Emote_PumpUpTheJam", "none", "deflated_emote_music");
          case 98:
          CreateEmote(target, "Emote_Renegade", "none", "emote_just_home_music");
          case 99:
          CreateEmote(target, "Emote_RushinAround", "none", "emote_comrade");
          case 100:
          CreateEmote(target, "Emote_SaySo", "none", "emote_hotpink");
          case 101:
          CreateEmote(target, "Emote_Stuck", "none", "emote_downward");
          case 102:
          CreateEmote(target, "Emote_ToosieSlide", "none", "emote_art_giant");
          case 103:
          CreateEmote(target, "Emote_AirShredder", "none", "air_guitar_emote");
          case 104:
          CreateEmote(target, "Emote_Crossbounce", "none", "emote_blaster");
          case 105:
          CreateEmote(target, "Emote_DistractionDance", "none", "distraction");
          case 106:
          CreateEmote(target, "Emote_Headbanger", "none", "headbanger_music");
          case 107:
          CreateEmote(target, "Emote_HitchHiker", "none", "hitchhiker_music");
          case 108:
          CreateEmote(target, "Emote_ItsGoTime", "none", "itsgotime_music");
          case 109:
          CreateEmote(target, "Emote_KneeSlapper", "none", "kneeslapper_music");
          case 110:
          CreateEmote(target, "Emote_Showstopper", "none", "showstopper_music");
          case 111:
          CreateEmote(target, "Emote_Sprinkler", "none", "sprinkler_music");
          case 112:
          CreateEmote(target, "Emote_Gmod", "none", "gmod_select");
          case 113:
          CreateEmote(target, "Emote_Cena", "none", "cant_c_me");
          case 114:
          CreateEmote(target, "Emote_Lebron", "none", "lebronjame");
          case 115:
          CreateEmote(target, "Emote_ChickenDance", "none", "pollo_dance");
          case 116:
          CreateEmote(target, "Emote_Ghostbusters", "none", "toastbust");
          case 117:
          CreateEmote(target, "Emote_Martian", "none", "leave_the_door");
          case 118:
          CreateEmote(target, "Emote_RememberMe_Intro", "Emote_RememberMe_Loop", "unforgettable");
          case 119:
          CreateEmote(target, "Emote_Rollie", "none", "rollie_rollie");
          case 120:
          CreateEmote(target, "Emote_Scenario", "none", "scenariooo");
          case 121:
          CreateEmote(target, "Emote_Tpose", "none", "");
          default:
          CPrintToChat(client, "%t", "INVALID_EMOTE_ID");
  }
}

public void OnAdminMenuReady(Handle aTopMenu)
{
  TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

  /* Block us from being called twice */
  if (topmenu == hTopMenu)
  {
    return;
  }
  
  /* Save the Handle */
  hTopMenu = topmenu;
  
  /* Find the "Player Commands" category */
  TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

  if (player_commands != INVALID_TOPMENUOBJECT)
  {
    hTopMenu.AddItem("sm_setemotes", AdminMenu_Emotes, player_commands, "sm_setemotes", ADMFLAG_SLAY);
  }
}

void AdminMenu_Emotes(TopMenu topmenu, 
            TopMenuAction action,
            TopMenuObject object_id,
            int param,
            char[] buffer,
            int maxlength)
{
  if (action == TopMenuAction_DisplayOption)
  {
    Format(buffer, maxlength, "%T", "EMOTE_PLAYER", param);
  }
  else if (action == TopMenuAction_SelectOption)
  {
    DisplayEmotePlayersMenu(param);
  }
}

void DisplayEmotePlayersMenu(int client)
{
  Menu menu = new Menu(MenuHandler_EmotePlayers);
  
  char title[65];
  Format(title, sizeof(title), "%T:", "EMOTE_PLAYER", client);
  menu.SetTitle(title);
  menu.ExitBackButton = true;
  
  AddTargetsToMenu(menu, client, true, true);
  
  menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_EmotePlayers(Menu menu, MenuAction action, int param1, int param2)
{
  if (action == MenuAction_End)
  {
    delete menu;
  }
  else if (action == MenuAction_Cancel)
  {
    if (param2 == MenuCancel_ExitBack && hTopMenu)
    {
      hTopMenu.Display(param1, TopMenuPosition_LastCategory);
    }
  }
  else if (action == MenuAction_Select)
  {
    char info[32];
    int userid, target;
    
    menu.GetItem(param2, info, sizeof(info));
    userid = StringToInt(info);

    if ((target = GetClientOfUserId(userid)) == 0)
    {
      CPrintToChat(param1, "[SM] %t", "Player no longer available");
    }
    else if (!CanUserTarget(param1, target))
    {
      CPrintToChat(param1, "[SM] %t", "Unable to target");
    }
    else
    {
      g_EmotesTarget[param1] = userid;
      DisplayEmotesAmountMenu(param1);
      return;	// Return, because we went to a new menu and don't want the re-draw to occur.
    }
    
    /* Re-draw the menu if they're still valid */
    if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
    {
      DisplayEmotePlayersMenu(param1);
    }
  }
  
  return;
}

void DisplayEmotesAmountMenu(int client)
{
  Menu menu = new Menu(MenuHandler_EmotesAmount);
  
  char title[65];
  Format(title, sizeof(title), "%T: %N", "SELECT_EMOTE", client, GetClientOfUserId(g_EmotesTarget[client]));
  menu.SetTitle(title);
  menu.ExitBackButton = true;

  AddTranslatedMenuItem(menu, "1", "Emote_Fonzie_Pistol", client);
  AddTranslatedMenuItem(menu, "2", "Emote_Bring_It_On", client);
  AddTranslatedMenuItem(menu, "3", "Emote_ThumbsDown", client);
  AddTranslatedMenuItem(menu, "4", "Emote_ThumbsUp", client);
  AddTranslatedMenuItem(menu, "5", "Emote_Celebration_Loop", client);
  AddTranslatedMenuItem(menu, "6", "Emote_BlowKiss", client);
  AddTranslatedMenuItem(menu, "7", "Emote_Calculated", client);
  AddTranslatedMenuItem(menu, "8", "Emote_Confused", client);	
  AddTranslatedMenuItem(menu, "9", "Emote_Chug", client);
  AddTranslatedMenuItem(menu, "10", "Emote_Cry", client);
  AddTranslatedMenuItem(menu, "11", "Emote_DustingOffHands", client);
  AddTranslatedMenuItem(menu, "12", "Emote_DustOffShoulders", client);	
  AddTranslatedMenuItem(menu, "13", "Emote_Facepalm", client);
  AddTranslatedMenuItem(menu, "14", "Emote_Fishing", client);
  AddTranslatedMenuItem(menu, "15", "Emote_Flex", client);
  AddTranslatedMenuItem(menu, "16", "Emote_golfclap", client);	
  AddTranslatedMenuItem(menu, "17", "Emote_HandSignals", client);
  AddTranslatedMenuItem(menu, "18", "Emote_HeelClick", client);
  AddTranslatedMenuItem(menu, "19", "Emote_Hotstuff", client);
  AddTranslatedMenuItem(menu, "20", "Emote_IBreakYou", client);	
  AddTranslatedMenuItem(menu, "21", "Emote_IHeartYou", client);
  AddTranslatedMenuItem(menu, "22", "Emote_Kung-Fu_Salute", client);
  AddTranslatedMenuItem(menu, "23", "Emote_Laugh", client);
  AddTranslatedMenuItem(menu, "24", "Emote_Luchador", client);	
  AddTranslatedMenuItem(menu, "25", "Emote_Make_It_Rain", client);
  AddTranslatedMenuItem(menu, "26", "Emote_NotToday", client);
  AddTranslatedMenuItem(menu, "27", "Emote_RockPaperScissor_Paper", client);
  AddTranslatedMenuItem(menu, "28", "Emote_RockPaperScissor_Rock", client);	
  AddTranslatedMenuItem(menu, "29", "Emote_RockPaperScissor_Scissor", client);
  AddTranslatedMenuItem(menu, "30", "Emote_Salt", client);
  AddTranslatedMenuItem(menu, "31", "Emote_Salute", client);
  AddTranslatedMenuItem(menu, "32", "Emote_SmoothDrive", client);	
  AddTranslatedMenuItem(menu, "33", "Emote_Snap", client);
  AddTranslatedMenuItem(menu, "34", "Emote_StageBow", client);	
  AddTranslatedMenuItem(menu, "35", "Emote_Wave2", client);
  AddTranslatedMenuItem(menu, "36", "Emote_Yeet", client);
  AddTranslatedMenuItem(menu, "37", "DanceMoves", client);
  AddTranslatedMenuItem(menu, "38", "Emote_Mask_Off_Intro", client);
  AddTranslatedMenuItem(menu, "39", "Emote_Zippy_Dance", client);
  AddTranslatedMenuItem(menu, "40", "ElectroShuffle", client);
  AddTranslatedMenuItem(menu, "41", "Emote_AerobicChamp", client);
  AddTranslatedMenuItem(menu, "42", "Emote_Bendy", client);
  AddTranslatedMenuItem(menu, "43", "Emote_BandOfTheFort", client);
  AddTranslatedMenuItem(menu, "44", "Emote_Boogie_Down_Intro", client);	
  AddTranslatedMenuItem(menu, "45", "Emote_Capoeira", client);
  AddTranslatedMenuItem(menu, "46", "Emote_Charleston", client);
  AddTranslatedMenuItem(menu, "47", "Emote_Chicken", client);
  AddTranslatedMenuItem(menu, "48", "Emote_Dance_NoBones", client);	
  AddTranslatedMenuItem(menu, "49", "Emote_Dance_Shoot", client);
  AddTranslatedMenuItem(menu, "50", "Emote_Dance_SwipeIt", client);
  AddTranslatedMenuItem(menu, "51", "Emote_Dance_Disco_T3", client);
  AddTranslatedMenuItem(menu, "52", "Emote_DG_Disco", client);	
  AddTranslatedMenuItem(menu, "53", "Emote_Dance_Worm", client);
  AddTranslatedMenuItem(menu, "54", "Emote_Dance_Loser", client);
  AddTranslatedMenuItem(menu, "55", "Emote_Dance_Breakdance", client);
  AddTranslatedMenuItem(menu, "56", "Emote_Dance_Pump", client);	
  AddTranslatedMenuItem(menu, "57", "Emote_Dance_RideThePony", client);
  AddTranslatedMenuItem(menu, "58", "Emote_Dab", client);
  AddTranslatedMenuItem(menu, "59", "Emote_EasternBloc_Start", client);
  AddTranslatedMenuItem(menu, "60", "Emote_FancyFeet", client);	
  AddTranslatedMenuItem(menu, "61", "Emote_FlossDance", client);
  AddTranslatedMenuItem(menu, "62", "Emote_FlippnSexy", client);
  AddTranslatedMenuItem(menu, "63", "Emote_Fresh", client);
  AddTranslatedMenuItem(menu, "64", "Emote_GrooveJam", client);	
  AddTranslatedMenuItem(menu, "65", "Emote_guitar", client);
  AddTranslatedMenuItem(menu, "66", "Emote_Hillbilly_Shuffle_Intro", client);
  AddTranslatedMenuItem(menu, "67", "Emote_Hiphop_01", client);
  AddTranslatedMenuItem(menu, "68", "Emote_Hula_Start", client);	
  AddTranslatedMenuItem(menu, "69", "Emote_InfiniDab_Intro", client);
  AddTranslatedMenuItem(menu, "70", "Emote_Intensity_Start", client);
  AddTranslatedMenuItem(menu, "71", "Emote_IrishJig_Start", client);
  AddTranslatedMenuItem(menu, "72", "Emote_KoreanEagle", client);	
  AddTranslatedMenuItem(menu, "73", "Emote_Kpop_02", client);
  AddTranslatedMenuItem(menu, "74", "Emote_LivingLarge", client);
  AddTranslatedMenuItem(menu, "75", "Emote_Maracas", client);
  AddTranslatedMenuItem(menu, "76", "Emote_PopLock", client);
  AddTranslatedMenuItem(menu, "77", "Emote_PopRock", client);
  AddTranslatedMenuItem(menu, "78", "Emote_RobotDance", client);
  AddTranslatedMenuItem(menu, "79", "Emote_T-Rex", client);	
  AddTranslatedMenuItem(menu, "80", "Emote_TechnoZombie", client);
  AddTranslatedMenuItem(menu, "81", "Emote_Twist", client);
  AddTranslatedMenuItem(menu, "82", "Emote_WarehouseDance_Start", client);
  AddTranslatedMenuItem(menu, "83", "Emote_Wiggle", client);
  AddTranslatedMenuItem(menu, "84", "Emote_Youre_Awesome", client);
  AddTranslatedMenuItem(menu, "85", "Emote_Smooth_Moves", client);
  AddTranslatedMenuItem(menu, "86", "Emote_Friday13", client);
  AddTranslatedMenuItem(menu, "87", "Emote_Thanos_Twerk", client);	
  AddTranslatedMenuItem(menu, "88", "Emote_Gangnam_Style", client);	
  AddTranslatedMenuItem(menu, "89", "Emote_InDaGhetto", client);
  AddTranslatedMenuItem(menu, "90", "Emote_BlindingLights", client);
  AddTranslatedMenuItem(menu, "91", "Emote_Griddy", client);
  AddTranslatedMenuItem(menu, "92", "Emote_ILikeToMoveIt", client);
  AddTranslatedMenuItem(menu, "93", "Emote_Macarena", client);
  AddTranslatedMenuItem(menu, "94", "Emote_NeverGonna", client);
  AddTranslatedMenuItem(menu, "95", "Emote_NinjaStyle", client);
  AddTranslatedMenuItem(menu, "96", "Emote_PumpkinDance", client);
  AddTranslatedMenuItem(menu, "97", "Emote_PumpUpTheJam", client);
  AddTranslatedMenuItem(menu, "98", "Emote_Renegade", client);
  AddTranslatedMenuItem(menu, "99", "Emote_RushinAround", client);
  AddTranslatedMenuItem(menu, "100", "Emote_SaySo", client);
  AddTranslatedMenuItem(menu, "101", "Emote_Stuck", client);
  AddTranslatedMenuItem(menu, "102", "Emote_ToosieSlide", client);
  AddTranslatedMenuItem(menu, "103", "Emote_AirShredder", client);
  AddTranslatedMenuItem(menu, "104", "Emote_Crossbounce", client);
  AddTranslatedMenuItem(menu, "105", "Emote_DistractionDance", client);
  AddTranslatedMenuItem(menu, "106", "Emote_Headbanger", client);
  AddTranslatedMenuItem(menu, "107", "Emote_HitchHiker", client);
  AddTranslatedMenuItem(menu, "108", "Emote_ItsGoTime", client);
  AddTranslatedMenuItem(menu, "109", "Emote_KneeSlapper", client);
  AddTranslatedMenuItem(menu, "110", "Emote_Showstopper", client);
  AddTranslatedMenuItem(menu, "111", "Emote_Sprinkler", client);
  AddTranslatedMenuItem(menu, "112", "Emote_Gmod", client);
  AddTranslatedMenuItem(menu, "113", "Emote_Cena", client);
  AddTranslatedMenuItem(menu, "114", "Emote_Lebron", client);	
  AddTranslatedMenuItem(menu, "115", "Emote_ChickenDance", client);	
  AddTranslatedMenuItem(menu, "116", "Emote_Ghostbusters", client);	
  AddTranslatedMenuItem(menu, "117", "Emote_Martian", client);	
  AddTranslatedMenuItem(menu, "118", "Emote_RememberMe_Intro", client);	
  AddTranslatedMenuItem(menu, "119", "Emote_Rollie", client);	
  AddTranslatedMenuItem(menu, "120", "Emote_Scenario", client);	
  AddTranslatedMenuItem(menu, "121", "Emote_Tpose", client);						
  
  menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_EmotesAmount(Menu menu, MenuAction action, int param1, int param2)
{
  if (action == MenuAction_End)
  {
    delete menu;
  }
  else if (action == MenuAction_Cancel)
  {
    if (param2 == MenuCancel_ExitBack && hTopMenu)
    {
      hTopMenu.Display(param1, TopMenuPosition_LastCategory);
    }
  }
  else if (action == MenuAction_Select)
  {
    char info[32];
    int amount;
    int target;
    
    menu.GetItem(param2, info, sizeof(info));
    amount = StringToInt(info);

    if ((target = GetClientOfUserId(g_EmotesTarget[param1])) == 0)
    {
      CPrintToChat(param1, "[SM] %t", "Player no longer available");
    }
    else if (!CanUserTarget(param1, target))
    {
      CPrintToChat(param1, "[SM] %t", "Unable to target");
    }
    else
    {
      char name[MAX_NAME_LENGTH];
      GetClientName(target, name, sizeof(name));
      
      PerformEmote(param1, target, amount);
    }
    
    /* Re-draw the menu if they're still valid */
    if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
    {
      DisplayEmotePlayersMenu(param1);
    }
  }
}

public void OnEntityCreated(int entity, const char[] classname)
{
  if(StrEqual(classname, "trigger_multiple"))
  {
      SDKHook(entity, SDKHook_StartTouch, OnTrigger);
      SDKHook(entity, SDKHook_EndTouch, OnTrigger);
      SDKHook(entity, SDKHook_Touch, OnTrigger);
  }
  else if(StrEqual(classname, "trigger_hurt"))
  {
      SDKHook(entity, SDKHook_StartTouch, OnTrigger);
      SDKHook(entity, SDKHook_EndTouch, OnTrigger);
      SDKHook(entity, SDKHook_Touch, OnTrigger);
  }
  else if(StrEqual(classname, "trigger_push"))
  {
      SDKHook(entity, SDKHook_StartTouch, OnTrigger);
      SDKHook(entity, SDKHook_EndTouch, OnTrigger);
      SDKHook(entity, SDKHook_Touch, OnTrigger);
  }
}

public Action OnTrigger(int entity, int other)
{
  if (IsNonElevatorMap())
  {
    if (0 < other <= MaxClients)
    {
      StopEmote(other);
    }
  }
  else
  {
    if (0 < other <= MaxClients)
    {
      StopEmote(other);
    }
  }

  return Plugin_Continue;
}

stock bool IsNonElevatorMap()
{
	char MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	if (StrContains(MapName, "c1m2", true) > -1 || 
	StrContains(MapName, "c1m3", true) > -1 || 
	StrContains(MapName, "c2m1", true) > -1 || 
	StrContains(MapName, "c2m2", true) > -1 || 
	StrContains(MapName, "c2m3", true) > -1 || 
	StrContains(MapName, "c2m4", true) > -1 || 
	StrContains(MapName, "c2m5", true) > -1 || 
	StrContains(MapName, "c3m2", true) > -1 || 
	StrContains(MapName, "c3m3", true) > -1 || 
	StrContains(MapName, "c3m4", true) > -1 || 
	StrContains(MapName, "c4m1", true) > -1 || 
	StrContains(MapName, "c4m4", true) > -1 || 
	StrContains(MapName, "c4m5", true) > -1 || 
	StrContains(MapName, "c5m1", true) > -1 || 
    StrContains(MapName, "c5m2", true) > -1 || 
    StrContains(MapName, "c5m3", true) > -1 || 
    StrContains(MapName, "c5m4", true) > -1 || 
    StrContains(MapName, "c5m5", true) > -1 || 
    StrContains(MapName, "c6m1", true) > -1 || 
    StrContains(MapName, "c6m2", true) > -1 || 
    StrContains(MapName, "c7m1", true) > -1 || 
    StrContains(MapName, "c7m2", true) > -1 || 
    StrContains(MapName, "c7m3", true) > -1 || 
    StrContains(MapName, "c8m1", true) > -1 || 
    StrContains(MapName, "c8m2", true) > -1 || 
    StrContains(MapName, "c8m3", true) > -1 || 
    StrContains(MapName, "c8m5", true) > -1 || 
    StrContains(MapName, "c9m1", true) > -1 || 
    StrContains(MapName, "c9m2", true) > -1 || 
    StrContains(MapName, "c10m1", true) > -1 || 
    StrContains(MapName, "c10m2", true) > -1 || 
    StrContains(MapName, "c10m3", true) > -1 || 
    StrContains(MapName, "c10m4", true) > -1 || 
    StrContains(MapName, "c10m5", true) > -1 || 
    StrContains(MapName, "c11m1", true) > -1 || 
    StrContains(MapName, "c11m2", true) > -1 || 
    StrContains(MapName, "c11m3", true) > -1 || 
    StrContains(MapName, "c11m4", true) > -1 || 
    StrContains(MapName, "c11m5", true) > -1 || 
    StrContains(MapName, "c12m1", true) > -1 || 
    StrContains(MapName, "c12m2", true) > -1 || 
    StrContains(MapName, "c12m3", true) > -1 || 
    StrContains(MapName, "c12m4", true) > -1 || 
    StrContains(MapName, "c12m5", true) > -1 || 
    StrContains(MapName, "c13m1", true) > -1 || 
    StrContains(MapName, "c13m2", true) > -1 || 
    StrContains(MapName, "c13m3", true) > -1 || 
    StrContains(MapName, "c13m4", true) > -1 || 
    StrContains(MapName, "c14m1", true) > -1 || 
	StrContains(MapName, "c14m2", true) > -1) return true;
	return false;
}

void AddTranslatedMenuItem(Menu menu, const char[] opt, const char[] phrase, int client)
{
  char buffer[128];
  Format(buffer, sizeof(buffer), "%T", phrase, client);
  menu.AddItem(opt, buffer);
}


bool CheckAdminFlags(int client, int iFlag)
{
  int iUserFlags = GetUserFlagBits(client);
  return (iUserFlags & ADMFLAG_ROOT || (iUserFlags & iFlag) == iFlag);
}

int GetEmotePeople()
{
  int count;
  for(int i = 1; i <= MaxClients; i++) {
    if (IsClientInGame(i) && g_bClientDancing[i]) {
      count++;
    }
  }
  return count;
}

/**
* Metodo para verificar si el jugador esta vivo
* @param int client
* @return bool
*/
stock bool bIsPlayerIncapped(int client) {
  return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}