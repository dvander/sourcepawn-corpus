#include <sourcemod>
#include <keyvalues>

#pragma semicolon 1

public Plugin:myinfo = {
	name = "UserRestrict",
	author = "theY4Kman",
	description = "Restrict a player from using a certain weapon.",
	version = "1.1.0",
	url = "http://y4kstudios.com/unhinged/sourcemod/"
};

new Handle:restfile;
new String:path[PLATFORM_MAX_PATH];
new myWeps;
new acWeps;
new laWeps;
new String:curRest[6];

stock IsStringNumeric(const String:str[]){
  for(new i=0;i<strlen(str);i++){
    if(str[i] == '\0' || IsCharNumeric(str[i])) continue;
    else return false;
  }
  return true;
}

public OnPluginStart(){
  BuildPath(Path_SM,path,sizeof(path),"configs/userrestrict.cfg");
  
  restfile = CreateKeyValues("userrestrict");
  FileToKeyValues(restfile,path);
  KvGotoFirstSubKey(restfile);
  
  myWeps = FindSendPropOffs("CBasePlayer","m_hMyWeapons");
  acWeps = FindSendPropOffs("CBasePlayer","m_hActiveWeapon");
  laWeps = FindSendPropOffs("CBasePlayer","m_hLastWeapon");
  
  HookEvent("item_pickup",IdentifyItem,EventHookMode_Pre);
  RegConsoleCmd("user_restrict",RestrictMenu,"The console command to execute UserRestrict functions",FCVAR_PLUGIN);
  RegConsoleCmd("user_unrestrict",UnrestrictMenu,"The console command to execute UserUnRestrict functions",FCVAR_PLUGIN);
  CreateConVar("user_restrict_version","1.1.0","The version of UserRestrict running.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  
  PrintToServer("[UserRestrict] Loaded");
  PrintToServer("[UserRestrict] By theY4Kman");
}

public OnPluginEnd(){
  CloseHandle(restfile);
}

public RestrictWepHandler(Handle:menu, MenuAction:action, param1, param2){
  if(action == MenuAction_Select){
    new String:wep[16];
    new bool:found = GetMenuItem(menu,param2,wep,sizeof(wep));
    
    if(found && strlen(curRest)){
      if(IsStringNumeric(curRest) && curRest[0] != '#') ClientCommand(param1,"user_restrict %d %s",GetClientUserId(StringToInt(curRest)),wep);
      else ClientCommand(param1,"user_restrict %s %s",curRest,wep);
      curRest = "\0";
    }
  }
  
  if(action == MenuAction_End){
    CloseHandle(menu);
  }
}

public RestrictHandler(Handle:menu, MenuAction:action, param1, param2){
  if(action == MenuAction_Select){
    new String:info[6];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
    
    if(found){
      curRest = info;
  		
  		new Handle:weps = CreateMenu(RestrictWepHandler);
  		SetMenuTitle(weps,"Which weapon?");
  		
			AddMenuItem(weps,"ak47","AK47");
			AddMenuItem(weps,"aug","Bullpup");
			AddMenuItem(weps,"awp","AWP");
			AddMenuItem(weps,"deagle","Deagle");
			AddMenuItem(weps,"elite","Dual Elites");
			AddMenuItem(weps,"famas","Famas");
			AddMenuItem(weps,"fiveseven","FiveSeven");
			AddMenuItem(weps,"flashbang","Flashbang");
			AddMenuItem(weps,"g3sg1","G3/SG-1");
			AddMenuItem(weps,"galil","Galil");
			AddMenuItem(weps,"glock","Glock");
			AddMenuItem(weps,"hegrenade","HE Grenade");
			AddMenuItem(weps,"m249","Para M249");
			AddMenuItem(weps,"m3","M3");
			AddMenuItem(weps,"m4a1","M4A1");
			AddMenuItem(weps,"mac10","Mac-10");
			AddMenuItem(weps,"mp5navy","MP5");
			AddMenuItem(weps,"p228","P228");
			AddMenuItem(weps,"p90","P90");
			AddMenuItem(weps,"scout","Scout");
			AddMenuItem(weps,"sg550","SG550");
			AddMenuItem(weps,"sg552","SG552");
			AddMenuItem(weps,"smokegrenade","Smoke Grenade");
			AddMenuItem(weps,"tmp","TMP");
			AddMenuItem(weps,"ump45","UMP45");
			AddMenuItem(weps,"usp","USP");
			AddMenuItem(weps,"xm1014","XM1014");
			
			SetMenuExitButton(weps,true);
			DisplayMenu(weps,param1,MENU_TIME_FOREVER);
  	}
  }
  
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
}

public Action:RestrictMenu(player,args){
  if(GetUserAdmin(player)){
    if(!args){
    	new Handle:menu = CreateMenu(RestrictHandler);
    	SetMenuTitle(menu, "Which player?");
    	
    	new String:playerName[64];
    	new String:playerIndex[6];
    	for(new a=1;a<GetMaxClients();a++){
        if(IsClientInGame(a)){
          IntToString(a,playerIndex,sizeof(playerIndex));
          GetClientName(a,playerName,sizeof(playerName));
          AddMenuItem(menu,playerIndex,playerName);
        }
      }
      AddMenuItem(menu,"#t","Terrorists");
      AddMenuItem(menu,"#ct","CTs");
      AddMenuItem(menu,"#bot","Bots");
      AddMenuItem(menu,"#all","Everyone");
    	SetMenuExitButton(menu,true);
    	DisplayMenu(menu, player, MENU_TIME_FOREVER);
  	} else if(args < 2){
      PrintToConsole(player,"Usage:\n\tuser_restrict <userid> <weapon>\nExample:\n\tsm_userrestrict 3 ak47");
      return Plugin_Handled;
    } else {
      new userid;
      new user;
      new String:userids[6];
      new String:weapon[64];
      GetCmdArg(1,userids,sizeof(userids));
      GetCmdArg(2,weapon,sizeof(weapon));
      
      if(IsStringNumeric(userids)) userid = StringToInt(userids);
      else if(strncmp(userids,"#",1)){
        PrintToConsole(player,"Usage:\n\tuser_restrict <userid> <weapon>\nExample:\n\tsm_userrestrict 3 ak47");
        return Plugin_Handled;
      }
      
      if(user = GetClientOfUserId(userid) || !strncmp(userids,"#",1)){
        new String:steam[32];
        new String:name[64];
        new String:linkverb[4];
        if(user && strncmp(userids,"#",1)){
          GetClientAuthString(user,steam,sizeof(steam));
          GetClientName(user,name,sizeof(name));
          linkverb = "is";
        } else {
          linkverb = "are";
          switch(userids[1]){
            case 't'://#t
              name = "the terrorists";
            case 'c'://#ct
              name = "the CTs";
            case 'b'://#bot
              name = "the bots";
            case 'a':{//#all
              name = "everyone";
              linkverb = "is";
            }
          }
          steam = userids;
        }
        
        if(!KvGetNum(restfile,weapon)){
      		KvRewind(restfile);
      		KvJumpToKey(restfile,steam,true);
          KvSetNum(restfile,weapon,1);
          KvRewind(restfile);
          KvJumpToKey(restfile,"UserRestrictions");
          KeyValuesToFile(restfile,path);
          KvGotoFirstSubKey(restfile);
          
          PrintToChat(player,"%cYou have restricted %c%s%c from using the %c%s.",0x03,name,0x04,0x03,0x04,weapon);
        } else if(KvGetNum(restfile,weapon) == 1){
          PrintToChat(player,"%c%s%c %s already restricted from using the %c%s%c.",0x04,name,0x03,linkverb,0x04,weapon,0x03);
        }
        return Plugin_Handled;
      } else {
        PrintToChat(player,"%cThat player (User ID %c%d%c) is not in game!",0x03,0x04,0x03,userid,0x03);
        return Plugin_Handled;
      }
    }
  } else if(!player){
    PrintToServer("[UserRestrict] You cannot use the UserRestrict menu from the server");
  } else {
    PrintToChat(player,"%cYou are not authorized to use UserRestrict!",0x03);
  }
	return Plugin_Handled;
}

public UnrestrictWepHandler(Handle:menu, MenuAction:action, param1, param2){
  if(action == MenuAction_Select){
    new String:mi[96];
    new bool:found = GetMenuItem(menu,param2,mi,sizeof(mi));
    if(found){
      new String:arr[64][2];
      ExplodeString(mi,"-",arr,2,64);
      ClientCommand(param1,"user_unrestrict %s %s",arr[0],arr[1]);
    }
  }
  
  if(action == MenuAction_End){
    CloseHandle(menu);
  }
}

public UnrestrictHandler(Handle:menu, MenuAction:action, param1, param2){
  if(action == MenuAction_Select){
    new String:steam[32];
    new bool:found = GetMenuItem(menu, param2, steam, sizeof(steam));
    
    if(found){
      KvRewind(restfile);
      if(KvJumpToKey(restfile,steam)){
        //KvGotoFirstSubKey(restfile,false);
        new Handle:weps = CreateMenu(UnrestrictWepHandler);
        SetMenuTitle(weps,"Which weapon?");
        
        new String:mi[96];
        new String:wep[64];
        while(KvGotoNextKey(restfile,false)){
            KvGetSectionName(restfile,wep,sizeof(wep));
            Format(mi,sizeof(mi),"%s-%s",steam,wep);
            AddMenuItem(weps,mi,wep);
        }
        if(strlen(mi) > 0){
          Format(mi,sizeof(mi),"%s-all",steam);
          AddMenuItem(weps,mi,"All");
          SetMenuExitButton(weps,true);
          DisplayMenu(weps,param1,MENU_TIME_FOREVER);
        } else {
          CloseHandle(weps);
          PrintToChat(param1,"%c%s%c has no restrictions!",0x04,0x03,steam);
        }
      } else {
        PrintToChat(param1,"%cCould not find %c%s%c in the restrictions file",0x03,0x04,steam,0x03);
      }
    }
  }
  
  if(action == MenuAction_End){
    CloseHandle(menu);
  }
}

public Action:UnrestrictMenu(player,args){
  if(GetUserAdmin(player)){
    /*if(!args){
      new Handle:menu = CreateMenu(UnrestrictHandler);
      SetMenuTitle(menu,"Which Steam ID?");
      
      new String:steam[32];
      KvRewind(restfile);
      KvGotoFirstSubKey(restfile);
      while(KvGotoNextKey(restfile)){
        KvGetSectionName(restfile,steam,sizeof(steam));
        AddMenuItem(menu,steam,steam);
      }
      SetMenuExitButton(menu,true);
      DisplayMenu(menu,player,MENU_TIME_FOREVER);
    } else*/ if(args != 2) {
      PrintToConsole(player,"Usage:\n\tsm_userunrestrict <Steam ID> <weapon>\nExample:\n\tsm_userunrestrict STEAM_0:1:10553940 ak47");
    } else {
      new String:steam[32];
      new String:weapon[64];
      GetCmdArg(1,steam,sizeof(steam));
      GetCmdArg(2,weapon,sizeof(weapon));
      
      KvRewind(restfile);
      if(KvJumpToKey(restfile,steam)){
        if(!strncmp(weapon,"all",3)){
          KvDeleteThis(restfile);
          PrintToChat(player,"%cYou have successfully removed %c%s%c from the restrictions file",0x03,0x04,steam,0x03);
        } else {
          KvDeleteKey(restfile,weapon);
          PrintToChat(player,"Y%cou have successfully unrestricted the %c%s%c from %c%s",0x03,0x04,weapon,0x03,0x04,steam);
        }
        KvJumpToKey(restfile,"UserRestrictions");
        KeyValuesToFile(restfile,path);
        KvGotoFirstSubKey(restfile);
      } else {
        PrintToChat(player,"%cCould not find %c%s%c in the restrictions file",0x03,0x04,steam,0x03);
      }
    }
  }
  return Plugin_Handled;
}

public RestrictWeapon(player,String:weapon[]){
  new activeWep;
  new lastWep;
  new String:clsname[64];
  new String:weapon_[64];
  new String:last[64];
  
  Format(weapon_,sizeof(weapon_),"weapon_%s",weapon);
  for (new i=0; i < (32*4); i+=4){
    activeWep = GetEntDataEnt(player,myWeps+i);
    
    if(activeWep != 0){
      GetEdictClassname(activeWep,clsname,sizeof(clsname));
      if(strcmp(clsname,weapon_,false) == 0){
        lastWep = GetEntDataEnt(player,laWeps);
        GetEdictClassname(lastWep,last,sizeof(last));
        FakeClientCommand(player,"use %s",last);
        
        SetEntDataEnt(player,laWeps,activeWep);
        SetEntDataEnt(player,myWeps+i,lastWep);
        SetEntDataEnt(player,acWeps,lastWep);
        
        PrintToChat(player,"%cYou are not allowed to use the %c%s%c!",0x03,0x04,weapon,0x03);
      }
    }
  }
}

public Action:IdentifyItem(Handle:event,const String:name[],bool:dontBroadcast){
  new String:weapon[32];
  new playerId = GetEventInt(event, "userid");
  new player = GetClientOfUserId(playerId);
  new String:steam[32];
  
  GetClientAuthString(player,steam,sizeof(steam));
  GetEventString(event, "item", weapon, sizeof(weapon));
  
  KvRewind(restfile);
  if(KvJumpToKey(restfile,steam) && KvGetNum(restfile,weapon)){
    RestrictWeapon(player,weapon);
  }
  
  KvRewind(restfile);
  if(GetClientTeam(player) == 2 && KvJumpToKey(restfile,"#t") && KvGetNum(restfile,weapon)){
    RestrictWeapon(player,weapon);
  }
  
  KvRewind(restfile);
  if(GetClientTeam(player) == 3 && KvJumpToKey(restfile,"#ct") && KvGetNum(restfile,weapon)){
    RestrictWeapon(player,weapon);
  }
  
  KvRewind(restfile);
  if(!strncmp(steam,"BOT",3) && KvJumpToKey(restfile,"#bot") && KvGetNum(restfile,weapon)){
    RestrictWeapon(player,weapon);
  }
  
  KvRewind(restfile);
  if(KvJumpToKey(restfile,"#all") && KvGetNum(restfile,weapon)){
    RestrictWeapon(player,weapon);
  }
  return Plugin_Continue;
}
