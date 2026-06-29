#include <sourcemod>

#define VERSION "1.1"

new tag;

new Handle:g_Health;

public OnPluginStart()
{
 HookEvent("player_spawn", EPS);
 AddCommandListener(Say, "say");
 
 CreateConVar("sm_benefits_version", VERSION, "Benefits Verion", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
 g_Health = CreateConVar("sm_benefits_health", "120", "amount of hp at spawn");
 
 AutoExecConfig(true, "sm_benefits");
}

public Action:EPS(Handle:event, const String:name[], bool:dontBroadcast)
{
 new client = GetClientOfUserId(GetEventInt(event, "userid"));
 if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
 {
  SetEntProp(client, Prop_Data, "m_iHealth", GetConVarInt(g_Health));
  return Plugin_Handled;
 }
 else
 {
  return Plugin_Handled;
 }
}
public Action:Say(client, const String:command[], args)
{
 if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
 {
  tag = client;
  if(tag == client)
  {
   decl String:Text[250];
   GetCmdArg(1, Text, sizeof(Text));
   
   if(Text[0] == '/')
   {
    return Plugin_Handled;
   }
   
   {
    PrintToChatAll("\x07FFFFFF[Admin]\x07000000 %N \x01 %s", client, Text);
	return Plugin_Handled;
   }
  }
  return Plugin_Handled;
 }
 else
 {
  return Plugin_Handled;
 }
}