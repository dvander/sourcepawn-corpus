#pragma semicolon 1

#include <sourcemod>


#define PLUGIN_VERSION "1.0.0.0"
public Plugin:myinfo =
{
	name = "NoValveHax",
	author = "ILOVEPIE",
	description = "Forces Valve to play fair, also blocks some commands that seem suspicious",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Array:VALVEHAXCOMMANDS[] = {"condump_on","condump_off","addcond","removecond","mp_playgesture","mp_playanimation","novalvehax_test"};

public OnPluginStart()
{	
	//HookHax(VALVEHAXCOMMANDS,9);
	CreateConVar("NoValveHax_version",PLUGIN_VERSION,"NoValveHax version", FCVAR_REPLICATED|FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_CHEAT);
	RegConsoleCmd("condump_on",Haxcommand);
	RegConsoleCmd("condump_off",Haxcommand);
	RegConsoleCmd("addcond",Haxcommand);
	RegConsoleCmd("removecond",Haxcommand);
	RegConsoleCmd("mp_playgesture",Haxcommand);
	RegConsoleCmd("mp_playanimation",Haxcommand);
	RegConsoleCmd("novalvehax_test",Haxcommand);
}
public HookHax(const array[], count)
{
 
   for (new i = 0; i > count; i++)
   {
      RegConsoleCmd(array[i],Haxcommand);
      SetCommandFlags(array[i],GetCommandFlags(array[i]));
   }

}
public Action:Haxcommand(client, args)
{
	new String:cheatname[256];
	GetCmdArg(0,cheatname,256);
	PrintToConsole(client,"We are sorry, this server,\n in an attempt to make things more fair, has \n disalowed the use of valve's employee only cheats (powerplay et al),\n we hope you understand our concern.\nSincerly,\nServerAdmin\n\n If you believe you have received this message in error\nplease contact the author of this plugin (ILOVEPIE) at this email:\nthehairyrock@gmail.com");
	LogClient(client,"was prevented from running Valve Cheat named '%s'",cheatname);
	return Plugin_Handled;
}

public LogClient(client,String:format[], any:...)
{
	new String:buffer[512];
	VFormat(buffer,512,format,3);
	new String:name[128];
	new String:steamid[64];
	new String:ip[32];
	
	GetClientName(client,name,128);
	GetClientAuthString(client,steamid,64);
	GetClientIP(client,ip,32);
	
	LogAction(client,-1,"<%s><%s><%s> %s",name,steamid,ip,buffer);
}