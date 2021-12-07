#pragma semicolon 1
#include <sourcemod>

float g_fConnectiontime[MAXPLAYERS+1] = 0.0;
float g_fSortArray[MAXPLAYERS+1] = 0.0;
int g_iClientArray[MAXPLAYERS+1] = 0;

public Plugin:myinfo = {
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
		sortArray();
		Handle menu = CreateMenu(MenuHandler);
		SetMenuTitle(menu,"Connection Time:");
		
		for(int i = 0; i < getElementCount(); i++){
			Format(buffer,sizeof(buffer),"%N - %s",g_iClientArray[i],toString(g_fSortArray[i]));
			AddMenuItem(menu,"",buffer);
		}
		SetMenuExitButton(menu,true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
public MenuHandler(Handle:menu, MenuAction:action, client, para){
}
//-------------------------------------------------------------------
stock bool:IsClientValid(client){
	if(client > 0 && client <= MaxClients && IsClientInGame(client)){
		return true;
	}
	return false;
}

char toString(float time){
	char timebuffer[32];
	Format(timebuffer,sizeof(timebuffer),"00h:00m:00s");
	if(time >= 3600.0){
		float temp = 0.0;
		temp = time/3600.0;
		char buf[16];
		int val = floatToInt(temp);
		time -= val*3600.0;
		Format(buf,sizeof(buf),"%.0fh",temp);
		ReplaceString(timebuffer,sizeof(timebuffer),"00h",buf,true);
	}
	if(time < 3600.0 && time >= 60.0){
		float temp = 0.0;
		temp = time/60.0;
		char buf[16];
		int val = floatToInt(temp);
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
stock int floatToInt(float val){
	char tb[64];
	FloatToString(val,tb,sizeof(tb));
	return StringToInt(tb);
}
stock float intToFloat(val){
	char tb[64];
	IntToString(val,tb,sizeof(tb));
	return StringToFloat(tb);
}
public void sortArray(){
	float last = 0.0;
	float cur;
	int accclient = 0;
	int oldclient = 0;
	getConnectionTimes();
	for(int i = getElementCount(); i >= 0; i--){
		cur = g_fConnectiontime[i];
		accclient = g_iClientArray[i];
		if(cur < last){
			g_fSortArray[i+1] = cur;
			g_fSortArray[i] = last;
			g_iClientArray[i] = oldclient;
			g_iClientArray[i+1] = accclient;
		}
		else{
			g_fSortArray[i] = cur;
			g_iClientArray[i] = accclient;
		}
		last = cur;
	}
}
public void getConnectionTimes(){
	for(int i = 1; i <= MAXPLAYERS; i++){
		if(IsClientValid(i)){
			g_fConnectiontime[i-1] = GetClientTime(i);
			g_iClientArray[i-1] = i;
		}
	}
}
public int getElementCount(){
	int res = 0;
	for(int i = 0; i <= MAXPLAYERS; i++){
		if(g_fConnectiontime[i] != 0.0) res++;
	}
	return res;
}