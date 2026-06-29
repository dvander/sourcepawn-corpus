  #include <sourcemod>
  #include <sdktools>
  
  public Plugin:myinfo = {
    name = "Limit medpacks",
    author = "Joshua Coffey",
    description = "Limit the amount of medpacks that can be used.",
    version = "1.0.0.0",
    url = "http://www.sourcemod.net/"
  }

new meddiesused = 0;
new Handle:med = INVALID_HANDLE;
  public OnPluginStart() {
        HookEvent("heal_begin",meddie);
        HookEvent("round_freeze_end",roundend);
                HookEvent("heal_success",meddiesuccess);
  }
  
    public meddie(Handle:event, const String:name[], bool:dontBroadcast)
  {
  
 med = CreateConVar("sm_medpack_limit", "8", "The amount of medpacks each team is allowed to use.", FCVAR_NOTIFY|FCVAR_PLUGIN)
     new user_id = GetEventInt(event, "userid")
     new medlimit = GetConVarInt(med)
     new user = GetClientOfUserId(user_id)
     
     if(meddiesused >= medlimit){
     
     new first_aid_kit = GetPlayerWeaponSlot(user, 3); 
     
     RemovePlayerItem(user, first_aid_kit);
     PrintToChatAll("Maximum medpacks used!");
     }}
     
         public meddiesuccess(Handle:event, const String:name[], bool:dontBroadcast)
  {
     meddiesused +=1;
     }
              public roundend(Handle:event, const String:name[], bool:dontBroadcast)
  {
     meddiesused = 0;
     }