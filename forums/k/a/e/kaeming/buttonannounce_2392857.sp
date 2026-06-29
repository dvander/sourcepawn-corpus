#include <sourcemod>
#include <sdktools>
#include <colors>
#define SFL_BLAH 1<<10 // 1024
 
public Plugin:myinfo = 
{
  name = "Button Notficiation",
  author = "KaeMing",
  description = "Button Announcements",
  version = "0.9"
};
public OnPluginStart()
{
    HookEntityOutput( "func_button", "OnPressed", pressed)
}
public pressed(const String:output[], caller, attacker, Float:Any)
{
  decl String:user[MAX_NAME_LENGTH];
  decl String:entity[1024];
  GetEntPropString(caller, Prop_Data, "m_iName", entity, sizeof(entity));
  GetClientName(attacker,user, sizeof(user));
  new flags = GetEntProp(caller, Prop_Data, "m_spawnflags");  
  if (flags & SFL_BLAH)
  {
    CPrintToChatAll("[{green}SM{default}] {green}%s{default} pressed a button that has spawn flag BLAH.", user);
  }
  else if (!(flags & SFL_BLAH))
  {
    CPrintToChatAll("[{green}SM{default}] {green}%s{default} pressed a button that does not have spawn flag BLAH.", user);
  }
}  