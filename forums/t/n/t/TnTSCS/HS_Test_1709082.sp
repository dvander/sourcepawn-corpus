#include <sourcemod>
#include <sdktools>
#include "sdkhooks"
#include "stocklib"
#pragma semicolon 1
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "NEF.K.Guren._. <CrystalReleased> + Alexei Volkoff + ? ? + ?? + ????"
#define QU1 "smnc_headshot/An_Reaction_Kill_Headshot_01.mp3"
#define QU2 "smnc_headshot/An_Reaction_Kill_Headshot_02.mp3"
#define QU3 "smnc_headshot/An_Reaction_Kill_Headshot_03.mp3"
#define MAX_SOUND 3
new Handle:g_cvarHeadshotWeaponList = INVALID_HANDLE;
new hitgroupsave[MAXPLAYERS + 1];
public Plugin:myinfo = 
{
 name = "HeadShot Random Sound",
 author = PLUGIN_AUTHOR,
 description = "BOOM! HEADSHOT!",
 version = PLUGIN_VERSION,
 url = "http://cssccp.x-y.net/"
};
public OnPluginStart()
{
 HookEvent("player_death", Event_PlayerDeath);
 CreateConVar("sm_headshot_random_sound", PLUGIN_VERSION, "HeadShot Random Sound", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
 g_cvarHeadshotWeaponList = CreateConVar("HeadshotWeaponList",
      "tf_weapon_sniperrifle;tf_weapon_revolver;tf_weapon_sniperrifle_decap",
      "HeadshotWeaponList... ;");
 AutoExecConfig();
}
public OnMapStart() 
{
 PrecacheSound( "smnc_headshot/An_Reaction_Kill_Headshot_01.mp3", true);
 PrecacheSound( "smnc_headshot/An_Reaction_Kill_Headshot_02.mp3", true);
 PrecacheSound( "smnc_headshot/An_Reaction_Kill_Headshot_03.mp3", true);
 AddFileToDownloadsTable("sound/smnc_headshot/An_Reaction_Kill_Headshot_01.mp3");
 AddFileToDownloadsTable("sound/smnc_headshot/An_Reaction_Kill_Headshot_02.mp3");
 AddFileToDownloadsTable("sound/smnc_headshot/An_Reaction_Kill_Headshot_03.mp3");
}
public OnClientPutInServer(Client)
{
 SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamageHook);
}
public Action:Event_PlayerDeath( Handle:event, const String:name[], bool:Broadcast )
{
 new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
 new Attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
 if( Victim == Attacker )
 {
  return Plugin_Handled;
 }
 if(hitgroupsave[Attacker] == 1)
 {
  new quake;
  quake = GetRandomInt(0, 3);
  if(quake == 0)
  {
   EmitSoundToAll(QU1);
  }
  else if(quake == 1)
  {
   EmitSoundToAll(QU2);
  }
  else if(quake == 2)
  {
   EmitSoundToAll(QU3);
  }
  new String:Name[32];
  GetClientName(Attacker, Name, 32);
  new String:Name2[32];
  GetClientName(Victim, Name2, 32);
  PrintCenterTextAll("%s -> %s HEADSHOT!", Name, Name2); 
 }
 return Plugin_Continue;
}
public Action:OnTakeDamageHook(Client, &attacker, &inflictor, &Float:damage, &damagetype)
{
 if (Client == 0 || attacker == 0)
 {
  return Plugin_Handled;
 }
 new String:weapon[64];
 GetClientWeapon(attacker, weapon, sizeof(weapon));
 decl String:weapon2[32];
 GetEdictClassname(inflictor, weapon2, 32);
 if(!StrEqual(weapon2, "player"))
 {
  return Plugin_Continue;
 }
 else
 {
  if(IsHeadshotWeapon(weapon))
  {
   if(damagetype & DMG_ACID)
    hitgroupsave[attacker] = 1;
   else
    hitgroupsave[attacker] = 0;
  }
  else
   hitgroupsave[attacker] = 0;
 }
 return Plugin_Continue;
}
bool:IsHeadshotWeapon(const String:weaponname[]){
 decl String:convarstring[256];
 GetConVarString(g_cvarHeadshotWeaponList, convarstring, 256);
 
 if(StrContains(convarstring, weaponname, false) != -1){
  
  return true;
  
 }
 return false;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg949\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/