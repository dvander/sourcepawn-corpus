#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#pragma newdecls required

#define PLUGIN_VERSION "1.2"

#define SND_CELEB "misc/happy_birthday.wav"
#define SND_EPIC "player/mannpower_invulnerable.wav"

public Plugin myinfo = 
{  
 name        = "[TF2] Unusual Celebration",
 author      = "Las Aves",
 description = "Whenever someone unboxes an unusual, celebration effects pop up (and more).",
 version     = PLUGIN_VERSION,
 url         = ""
};

ConVar enabled;
ConVar buff;
ConVar buffTime;
ConVar centerMsg;

public void OnPluginStart()
{
 AutoExecConfig(false);
	
 enabled = CreateConVar("sm_unuceleb", "1");
 buff = CreateConVar("sm_unuceleb_buff", "1", "Should the team of the unboxer get buffed?");
 buffTime = CreateConVar("sm_unuceleb_bufftime", "15.0", "How long should the celebration buff last?", 0, true, 1.0);
 centerMsg = CreateConVar("sm_unuceleb_centermsg", "1", "Should a centered message appear on celebrations?");
 
 HookEvent("item_found", Hook_ItemFound);
 
 //RegAdminCmd("sm_unucelebtest", Command_UnuCelebTest, ADMFLAG_SLAY);
}

public void OnMapStart()
{
 PrecacheSound(SND_CELEB);
 PrecacheSound(SND_EPIC);
}

/*
Action Command_UnuCelebTest(int client, int numArgs)
{
 if (IsValidClient(client))
 {
  Event event = CreateEvent("item_found");
  event.SetInt("player", client);
  event.SetInt("isunusual", 1);
  event.SetInt("method", 4);
  event.Fire();
 }
	
 return Plugin_Handled;
}*/
 
Action Hook_ItemFound(Event event, const char[] name, bool dontBroadcast)
{
 if (!GetConVarBool(enabled) || !IsUnusualUnbox(event)) {return Plugin_Continue;}
	
 int client = GetEventInt(event, "player");
 
 if (GetConVarBool(centerMsg))
 {
  PrintCenterTextAll("%N just unboxed an unusual! Congratulations!", client);
 }
 
 EmitSoundToAll(SND_EPIC, client, SNDCHAN_STATIC);
 EmitSoundToAll(SND_CELEB, client, SNDCHAN_STATIC);
 CreateTimer(5.0, RemoveParticle, EmitParticle(client, "bday_confetti"));
 if (GetConVarBool(buff))
 {  
  for (int i = 1; i < (MaxClients + 1); i++)
  {
   if (IsValidClient(i) && GetClientTeam(i) == GetClientTeam(client))
   {
    BuffClient(i, GetConVarFloat(buffTime), client);
   }
  }
 }
	
 return Plugin_Continue;
}

bool IsUnusualUnbox(Event event)
{
 if (GetEventBool(event, "isfake"))
 {
  return false;
 }
 else if (GetEventInt(event, "isunusual") <= 0)
 {
  return false;
 }
 else if (GetEventInt(event, "method") != 4)
 {
  return false;
 }
 return true;
}

int EmitParticle(int client, const char[] pName)
{
 float clPos[3];
 GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", clPos);
 
 int ent = CreateEntityByName("info_particle_system");
 SetEntPropVector(ent, Prop_Send, "m_vecOrigin", clPos);
 SetEntPropEnt(ent, Prop_Data, "m_pParent", client);//Just in case
 SetEntProp(ent, Prop_Send, "m_hControlPointEnts", client);//Seems to work.
 DispatchKeyValue(ent, "effect_name", pName);
 DispatchSpawn(ent);
 ActivateEntity(ent);
 AcceptEntityInput(ent, "Start");
 
 return EntIndexToEntRef(ent);
}

void BuffClient(int client, float time, int inflictor)
{
 TF2_AddCondition(client, TFCond_CritCanteen, time, inflictor);
 TF2_AddCondition(client, TFCond_UberchargedCanteen, time, inflictor);
}

Action RemoveParticle(Handle timer, int entRef)
{
 int ent = EntRefToEntIndex(entRef);
 
 if (IsValidEntity(ent))
 {
  AcceptEntityInput(ent, "Kill");
 }
 
 return Plugin_Continue;
}

bool IsValidClient(int ent)
{
 if (ent <= 0 || ent > MaxClients)
 {
  return false;
 }
 else if (!IsClientInGame(ent))
 {
  return false;
 }
 else if (IsClientReplay(ent) || IsClientSourceTV(ent))
 {
  return false;
 }
 return true;
}