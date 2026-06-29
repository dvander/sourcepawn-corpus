#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Playertime",
	author = "Waky",
	description = "Shows up a menu with the connected time of all player",
	version = "0.1",
	url = "www.area-community.net"
}

public OnPluginStart(){
	RegConsoleCmd("sm_timeplayers",Command_Time,"Open the PlayerTime Menu");
}
public Action:Command_Time(client,args){
	if(IsClientValid(client)){
		showMenu(client);
	}
	return Plugin_Handled;
}
public void showMenu(client){
	if(IsClientValid(client)){
		char buffer[128];
		Handle menu = CreateMenu(MenuHandler);
		SetMenuTitle(menu,"Connection Time:");
		
		for(int i = 1; i <= MAXPLAYERS+1; i++){
			if(IsClientValid(i)){
				Format(buffer,sizeof(buffer),"%N - %s",i,toString(GetClientTime(i)));
				AddMenuItem(menu,"",buffer);
			}
		}
		SetMenuExitButton(menu,true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
public MenuHandler(Handle:menu, MenuAction:action, client, para){
}
char toString(float time){
	char timebuffer[32];
	Format(timebuffer,sizeof(timebuffer),"00h:00m:00s");
	if(time >= 3600.0){
		float temp = 0.0;
		temp = time/3600.0;
		char tb[24];
		char buf[16];
		FloatToString(temp,tb,sizeof(tb));
		int val = StringToInt(tb);
		time -= val*3600.0;
		Format(buf,sizeof(buf),"%.0fh",temp);
		ReplaceString(timebuffer,sizeof(timebuffer),"00h",buf,true);
	}
	if(time < 3600.0 && time >= 60.0){
		float temp = 0.0;
		temp = time/60.0;
		char tb[24];
		char buf[16];
		FloatToString(temp,tb,sizeof(tb));
		int val = StringToInt(tb);
		time -= val*60.0;
		Format(buf,sizeof(buf),"%.0fm",temp);
		ReplaceString(timebuffer,sizeof(timebuffer),"00m",buf,true);
	}
	if(time < 60.0){
		char buf[16];
		Format(buf,sizeof(buf),"%.0fs",time);
		ReplaceString(timebuffer,sizeof(timebuffer),"00s",buf,true);
	}
	return timebuffer;
}
//-------------------------------------------------------------------
stock bool:IsClientValid(client){
	if(client > 0 && client <= MaxClients && IsClientInGame(client)){
		return true;
	}
	return false;
}